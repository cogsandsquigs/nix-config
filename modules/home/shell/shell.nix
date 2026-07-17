# The shell configuration I use!
{
    pkgs,
    config,
    lib,
    tools,
    ...
}:
let
    inherit (lib.strings) concatMapStrings;
    inherit (lib.attrsets) mapAttrsToList;

    # Where this flake lives on the host (default /etc/nix; the standalone work box overrides
    # this to ~/.config/nix). The shell aliases (rebuild/upgrade/…) point here — the only reader
    # of flakeDir, so its option is declared below rather than in a central options file.
    flakeDir = config.my.user.flakeDir;

    aliases = {
        ls = "eza --icons";
        du = "dust";
        cat = "bat"; # Better cat via `bat`
        cd = "z"; # Better cd via `zoxide`
        nv = "nvim";
        lg = "lazygit";
        neofetch = "fastfetch"; # Neofetch via fastfetch
        nxm = "${flakeDir}/scripts/nxm.py";
        # rebuild = "${flakeDir}/scripts/nxm.py rebuild";
        # upgrade = "${flakeDir}/scripts/nxm.py upgrade";
        # cleanup = "${flakeDir}/scripts/nxm.py clean";
        # editnix = "${flakeDir}/scripts/nxm.py edit";
        rebuild = ''bash -c "echo -e '\033[31mThis command is outdated. Please use `nxm rebuild | r` instead!\033[0m'"'';
        upgrade = ''bash -c "echo -e '\033[31mThis command is outdated. Please use `nxm upgrade | u` instead!\033[0m'"'';
        cleanup = ''bash -c "echo -e '\033[31mThis command is outdated. Please use `nxm cleanup | c` instead!\033[0m'"'';
        editnix = ''bash -c "echo -e '\033[31mThis command is outdated. Please use `nxm edit | e` instead!\033[0m'"'';
    };

    editor = "hx";

    variables = {
        EDITOR = editor;
        # Nix-provided java by default. To prefer a locally-installed JDK (e.g. the Arctic Lake work
        # box), set JAVA_HOME in ${flakeDir}/.env — the .env loader below overrides this.
        JAVA_HOME = "$(dirname $(dirname $(readlink -f $(command -v java))))";

        # NOTE: Necessary for (some) rust compilation things/libs
        LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libiconvReal ];
    }
    // (
        if pkgs.stdenv.isDarwin then
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
        "/nix/var/nix/profiles/default/bin"
        "/etc/profiles/per-user/${config.home.username}/bin"
        "/run/current-system/sw/bin"
    ];

    # Maps every variable in `variables` to a string for a specific shell.
    # @param `f`: A function `f :: String -> Any -> String` that takes the variable name,
    # then value, then returns a string that loads the variable in a specific shell the
    # user wants.
    # @returns the string of all variables to be loaded in a shell.
    variablesToString = f: (concatMapStrings (s: s + "\n") (mapAttrsToList f variables));

    # Maps every path entry in `binPaths` to a string for a specific shell
    # @param `f`: A function `f :: String -> String` that takes the path entry, then returns
    # a command to add it to the path.
    # @returns a string of commands to add things to path.
    pathsToString = f: (concatMapStrings (s: (f s) + "\n") binPaths);

    # Machine-local overrides: read ${flakeDir}/.env (KEY=VALUE, untracked) at shell startup and
    # let it override anything `variables` set. Loaded AFTER variables but BEFORE paths, so an
    # overridden JAVA_HOME still feeds "$JAVA_HOME/bin" in binPaths. Missing file is a no-op.
    # One canonical parser: bash sources the file directly; fish reuses it via `bass`.
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
    options.my.user.flakeDir = tools.opt.mkStr "/etc/nix" "Absolute path to this flake's checkout on the host.";

    config = lib.mkIf config.my.user.shell.enable {
        home.packages = with pkgs; [
            fish
            zsh
        ];

        programs.fish = {
            enable = true;
            generateCompletions = true;

            # `bass` lets fish run a bash command and import its env changes — used by the .env
            # loader so fish parses ${flakeDir}/.env through bash rather than a hand-rolled parser.
            plugins = [
                {
                    name = "bass";
                    src = pkgs.fishPlugins.bass.src;
                }
            ];

            shellAliases = aliases;

            interactiveShellInit = ''
                set fish_greeting # Disable fish greeting
                fish_config theme choose "Catppuccin Mocha" # Set theme. We use `choose` since using
                                                            # `save` forces a prompt, which is annoying,
                                                            # even though `choose` doesn't make it
                                                            # "permanent".
            '';

            shellInit = ''
                ${variablesToString (name: val: "set -gx ${name} ${val}")}
                ${envFileLoaderFish}
                ${pathsToString (path: "fish_add_path ${path}")}
            '';

            # NOTE: Since Fisher isn't really supported thru Home-manager, we use
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
                # /etc/profile.d/nix.sh; a single-user install exposes it under the user profile.
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
}
