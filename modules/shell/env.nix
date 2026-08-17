# The shell configuration I use!
{
    home =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        let
            inherit (lib.strings) concatMapStrings;
            inherit (lib.attrsets) mapAttrsToList;

            # Declared by the `shell` feature that owns this directory -- see ./default.nix.
            flakeDir = config.my.user.shell.flakeDir;

            aliases = {
                # `ls`, `ll`, `la`, `lt`, `lla` come from programs.eza (modules/cli/utils/default.nix),
                # which carries the flags. Defining `ls` here would override the whole set with one entry.
                du = "dust";
                cat = "bat"; # Better cat via `bat`
                cd = "z"; # Better cd via `zoxide`
                nv = "nvim";
                lg = "lazygit";
                neofetch = "fastfetch"; # Neofetch via fastfetch
                # Named interpreter, not the shebang's `env python3`: a devshell on $PATH otherwise
                # decides which python runs the script. Still points at the working tree, so editing
                # the script takes effect without a rebuild.
                nxm = "${pkgs.python3}/bin/python3 ${flakeDir}/scripts/nxm.py";
            };

            editor = "hx";

            variables = {
                EDITOR = editor;
                # Nix-provided java by default. To prefer a locally-installed JDK (e.g. the Arctic Lake work
                # box), set JAVA_HOME in ${flakeDir}/.env -- the .env loader below overrides this.
                JAVA_HOME = "$(dirname $(dirname $(readlink -f $(command -v java))))";

                # NOTE: Necessary for (some) rust compilation things/libs
                LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libiconvReal ];

                # Stop Zoxide from complaining sometimes
                _ZO_DOCTOR = "0";
            }
            // (
                if pkgs.stdenv.hostPlatform.isDarwin then
                    {
                        ANDROID_HOME = "$HOME/Library/Android/sdk";
                        NDK_HOME = "$HOME/Library/Android/sdk/ndk/29.0.13846066";
                    }
                else
                    { }
            );

            binPaths = [
                "$JAVA_HOME/bin" # Put before nix installs, so we prefer java-home java over other javas
                "$HOME/.cargo/bin"
                "${pkgs.llvmPackages_21.clang-tools}/bin"
                "$HOME/.local/bin"
                "$HOME/.nix-profile/bin"
                "$HOME/miniconda3/condabin" # Conda binaries
                "/nix/var/nix/profiles/default/bin"
                "/etc/profiles/per-user/${config.home.username}/bin"
                "/run/current-system/sw/bin"
            ];

            # Each takes the shell's own way of setting one variable (`f :: name -> value -> String`)
            # or adding one path entry (`f :: path -> String`), and returns the whole block.
            variablesToString = f: (concatMapStrings (s: s + "\n") (mapAttrsToList f variables));
            pathsToString = f: (concatMapStrings (s: (f s) + "\n") binPaths);

            # Machine-local overrides: read ${flakeDir}/.env (KEY=VALUE, untracked) at shell startup and
            # let it override anything `variables` set. Loaded AFTER variables but BEFORE paths, so an
            # overridden JAVA_HOME still feeds "$JAVA_HOME/bin" in binPaths. Missing file is a no-op.
            # One canonical parser: bash sources the file directly. fish reuses it via `bass`.
            envFileLoaderPosix = ''
                if [ -f "${flakeDir}/.env" ]; then
                    set -a
                    . "${flakeDir}/.env"
                    set +a
                fi
            '';
            envFileLoaderFish = ''
                if test -f "${flakeDir}/.env"
                    bass set -a \; source "${flakeDir}/.env" \; set +a
                end
            '';
        in
        {
            config = lib.mkIf config.my.user.shell.enable {
                programs.fish = {
                    enable = true;
                    generateCompletions = true;

                    # `bass` lets fish run a bash command and import its env changes -- used by the .env
                    # loader so fish parses ${flakeDir}/.env through bash rather than a hand-rolled parser.
                    plugins = [
                        {
                            name = "bass";
                            src = pkgs.fishPlugins.bass.src;
                        }
                        {
                            name = "fishbang";
                            src = pkgs.fishPlugins.fishbang.src;
                        }
                    ];

                    shellAliases = aliases;

                    interactiveShellInit = ''
                        set fish_greeting # Disable fish greeting
                        fish_config theme choose "Catppuccin Mocha" # Set theme. We use `choose` since using
                                                                    # `save` forces a prompt, which is annoying,
                                                                    # even though `choose` does not make it
                                                                    # "permanent".

                        # Source miniconda if it exists
                        if test -f $HOME/miniconda3/etc/fish/conf.d/conda.fish
                            source $HOME/miniconda3/etc/fish/conf.d/conda.fish
                        end
                    '';

                    shellInit = ''
                        ${variablesToString (name: val: "set -gx ${name} ${val}")}
                        ${envFileLoaderFish}
                        ${pathsToString (path: "fish_add_path ${path}")}
                    '';

                    # NOTE: Since Fisher is not really supported thru Home-manager, we use
                    # xdg to link the theme. See below
                };

                # NOTE: Still part of fish config!
                xdg.configFile =
                    let
                        catppuccin-fish = pkgs.fetchFromGitHub {
                            owner = "catppuccin";
                            repo = "fish";
                            rev = "a3b9eb5eaf2171ba1359fe98f20d226c016568cf";
                            hash = "sha256-shQxlyoauXJACoZWtRUbRMxmm10R8vOigXwjxBhG8ng=";
                        };
                    in
                    {
                        "fish/themes/Catppuccin Mocha.theme".source = "${catppuccin-fish}/themes/Catppuccin Mocha.theme";
                    };

                programs.bash = {
                    enable = true;

                    shellAliases = aliases;

                    initExtra = ''
                        ${variablesToString (name: val: "export ${name}=\"${val}\"")}
                        ${envFileLoaderPosix}
                        ${pathsToString (path: "export PATH=${path}:$PATH")}
                    '';
                };

                programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    autosuggestion.enable = true;
                    syntaxHighlighting.enable = true;
                    history.size = 10000;
                    autocd = true;

                    initContent = ''
                        # Source the nix environment. A multi-user (daemon) install exposes this at
                        # /etc/profile.d/nix.sh. A single-user install exposes it under the user profile.
                        # Guarded so a missing file never errors on shell startup, and works for both.
                        for __nix_sh in /etc/profile.d/nix.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
                            [ -e "$__nix_sh" ] && source "$__nix_sh" && break
                        done
                    '';

                    envExtra = ''
                        ${variablesToString (name: val: "export ${name}=\"${val}\"")}
                        ${envFileLoaderPosix}
                        ${pathsToString (path: "export PATH=${path}:$PATH")}
                    '';

                    shellAliases = aliases;
                };
            };
        };
}
