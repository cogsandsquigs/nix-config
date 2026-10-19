# Shell configuration
let
    os-shared = { pkgs, ... }: {
        environment.shells = [
            pkgs.fish
            pkgs.zsh
            pkgs.bash
        ];

        programs = {
            fish.enable = true;
            zsh.enable = true;
            bash.enable = true;
        };
    };
in
{
    flake.modules = {
        nixos.shell = os-shared;
        darwin.shell = os-shared;

        homeManager.shell =
            {
                pkgs,
                lib,
                config,
                ...
            }:
            let
                inherit (lib.strings) concatMapStrings;
                inherit (lib.attrsets) mapAttrsToList;

                # Where this repo is checked out. Machine-local overrides live in ${flakeDir}/.env.
                # TODO: adjust to your real checkout path.
                flakeDir = "${config.home.homeDirectory}/nix-config";

                aliases = {
                    # `ls`, `ll`, `la`, `lt`, `lla` come from programs.eza, which carries the flags.
                    # Defining `ls` here would override the whole set with one entry.
                    du = "dust";
                    cat = "bat"; # Better cat via `bat`
                    cd = "z"; # Better cd via `zoxide`
                    nv = "nvim";
                    lg = "lazygit";
                    neofetch = "fastfetch"; # Neofetch via fastfetch
                    nxm = "${pkgs.python3}/bin/python3 ${flakeDir}/lib/scripts/nxm.py";
                };

                variables = {
                    EDITOR = "hx";

                    # Nix-provided java by default. To prefer a locally-installed JDK, set JAVA_HOME in
                    # ${flakeDir}/.env -- the .env loader below overrides this.
                    JAVA_HOME = "$(dirname $(dirname $(readlink -f $(command -v java))))";

                    # NOTE: Necessary for (some) rust compilation things/libs
                    LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libiconvReal ];

                    # Stop Zoxide from complaining sometimes
                    _ZO_DOCTOR = "0";
                }
                // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
                    ANDROID_HOME = "$HOME/Library/Android/sdk";
                    NDK_HOME = "$HOME/Library/Android/sdk/ndk/29.0.13846066";
                };

                binPaths = [
                    "$JAVA_HOME/bin" # Put before nix installs, so we prefer java-home java over other javas
                    "$HOME/.cargo/bin"
                    "${pkgs.llvmPackages_21.clang-tools}/bin"
                    "$HOME/.local/bin"
                    "$HOME/.nix-profile/bin"
                    "$HOME/miniconda3/condabin" # Conda binaries
                    "/nix/var/nix/profiles/default/bin"
                    "/run/current-system/sw/bin"
                ];

                # Each takes the shell's own way of setting one variable (`f :: name -> value -> String`)
                # or adding one path entry (`f :: path -> String`), and returns the whole block.
                variablesToString = f: concatMapStrings (s: s + "\n") (mapAttrsToList f variables);
                pathsToString = f: concatMapStrings (s: f s + "\n") binPaths;

                # Machine-local overrides: read ${flakeDir}/.env (KEY=VALUE, untracked) at shell startup
                # and let it override anything `variables` set. Loaded AFTER variables but BEFORE paths,
                # so an overridden JAVA_HOME still feeds "$JAVA_HOME/bin" in binPaths. Missing file is a
                # no-op. One canonical parser: bash sources the file directly, fish reuses it via `bass`.
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

                # Shared by bash and zsh.
                posixInit = ''
                    ${variablesToString (name: val: "export ${name}=\"${val}\"")}
                    ${envFileLoaderPosix}
                    ${pathsToString (path: "export PATH=${path}:$PATH")}
                '';
            in
            {
                # Fisher is not really supported thru home-manager, so link the theme via xdg.
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

                programs = {
                    fish = {
                        enable = true;
                        generateCompletions = true;

                        # `bass` lets fish run a bash command and import its env changes -- used by the
                        # .env loader so fish parses ${flakeDir}/.env through bash.
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

                            # `choose` rather than `save`: `save` forces a prompt, and `choose` is enough
                            # even though it is not "permanent".
                            fish_config theme choose "Catppuccin Mocha"

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

                        # Like shellInit, but runs last. Enables the starship prompt character for
                        # transient prompts on fish. See:
                        # https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
                        shellInitLast = ''
                            function starship_transient_prompt_func
                                starship module character
                            end
                        '';
                    };

                    bash = {
                        enable = true;
                        shellAliases = aliases;
                        initExtra = posixInit;
                    };

                    zsh = {
                        enable = true;
                        enableCompletion = true;
                        autosuggestion.enable = true;
                        syntaxHighlighting.enable = true;
                        history.size = 10000;
                        autocd = true;
                        shellAliases = aliases;
                        envExtra = posixInit;

                        initContent = ''
                            # Source the nix environment. A multi-user (daemon) install exposes this at
                            # /etc/profile.d/nix.sh; a single-user install under the user profile.
                            # Guarded so a missing file never errors on shell startup.
                            for __nix_sh in /etc/profile.d/nix.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
                                [ -e "$__nix_sh" ] && source "$__nix_sh" && break
                            done
                        '';
                    };

                    starship = {
                        enable = true;
                        enableFishIntegration = true;
                        enableZshIntegration = true;
                        enableBashIntegration = true;
                        enableTransience = true;

                        # TODO: try https://starship.rs/presets/catppuccin-powerline
                        settings = {
                            add_newline = false;
                            command_timeout = 750; # Millis to wait for a command before timing out.

                            # NOTE: $package should come after all language symbols as it displays the
                            # package manager + version for the current language.
                            # NOTE: `''` in front of `${...}` escapes nix string interpolation. See:
                            # https://nix.dev/manual/nix/2.25/language/string-interpolation
                            #
                            # Only what is named here renders: a module left out of `format` is inert
                            # however it is configured, so nothing below configures one that is missing.
                            format = ''
                                [╭─](bright-black) $os$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$c$cpp$rust$julia$nodejs$bun$python$go$java$kotlin$scala$package$conda$direnv$mise$fill $cmd_duration''${custom.zellij}
                                [╰─](bright-black) $character
                            '';

                            # The prompt used for incomplete statements, i.e. `rm \` or a newline.
                            continuation_prompt = "[∙](bright-black)";

                            character = {
                                format = "$symbol ";
                                success_symbol = "[⏵](bold green)";
                                error_symbol = "[⏵](bold red)";
                                vimcmd_symbol = "[⏴](bold green)";
                                vimcmd_replace_one_symbol = "[⏴](bold purple)";
                                vimcmd_replace_symbol = "[⏴](bold purple)";
                                vimcmd_visual_symbol = "[⏴](bold yellow)";
                            };

                            directory = {
                                format = "[$path]($style)[$read_only]($read_only_style) ";
                                style = "bold bright-cyan";

                                truncation_symbol = "…/";
                                read_only = " ";
                                home_symbol = "~";
                            };

                            direnv = {
                                disabled = false;
                                format = "[$symbol$allowed$loaded]($style) ";
                                symbol = "direnv ";
                                allowed_msg = "✓";
                                not_allowed_msg = "-";
                                denied_msg = "✗";
                                loaded_msg = "";
                                unloaded_msg = " (!)";
                            };

                            # `$health` is mise's only state -- no allowed/loaded pair as direnv has.
                            mise = {
                                disabled = false; # NOTE: unlike direnv, upstream ships this disabled.
                                format = "[$symbol$health]($style) ";
                                symbol = "mise ";
                                healthy_symbol = "✓";
                                unhealthy_symbol = "✗";
                            };

                            conda = {
                                disabled = false;
                                symbol = "🅒  ";
                            };

                            cmd_duration = {
                                disabled = false;
                                min_time = 500; # millis
                                format = "took [$duration](bold yellow) in ";
                                style = "bold yellow";
                            };

                            # Filler btwn prompts
                            fill = {
                                symbol = "·";
                                style = "bright-black";
                            };

                            os = {
                                format = "[$symbol]($style)";
                                style = "bold white";
                                disabled = false;

                                # NOTE: These require nerd fonts. Need trailing spaces since `format` has
                                # none, and glyph widths differ per symbol.
                                symbols = {
                                    Macos = " ";
                                    Ubuntu = " ";
                                };
                            };

                            # SSH visibility comes from `ssh_symbol`, which `$hostname` renders.
                            hostname = {
                                format = "[$hostname$ssh_symbol]($style) in ";
                                style = "bold green";
                                ssh_only = false;
                                ssh_symbol = " 🛰️ "; # Leading space: room between it and hostname.
                                disabled = false;
                            };

                            username = {
                                style_root = "bold red";
                                style_user = "bold yellow";
                                detect_env_vars = [ ];
                                format = "[$user]($style)@";
                                show_always = true;
                                disabled = false;
                            };

                            ##########################
                            # LANGUAGES AND PACKAGES #
                            ##########################

                            c = {
                                symbol = " ";
                                detect_extensions = [
                                    "c"
                                    "h"
                                ];
                                detect_files = [
                                    ".clang-tidy"
                                    ".clangd"
                                    "compile_commands.json"
                                ];
                            };

                            cpp = {
                                symbol = " ";
                                detect_extensions = [
                                    "cpp"
                                    "hpp"
                                    "cxx"
                                    "hxx"
                                ];
                                detect_files = [
                                    ".clang-tidy"
                                    ".clangd"
                                    "compile_commands.json"
                                ];
                            };

                            ###################
                            # CUSTOM COMMANDS #
                            ###################

                            custom.zellij = {
                                # NOTE: `\\` outputs the string `\(...\)`, which Starship then interpolates.
                                format = "[Zellij \\($output\\)]($style) ";
                                style = "green bold";
                                description = "Shows the current Zellij session you are in";
                                # NOTE: `$__ZELLIJ_DONT_SHOW_STATUS` is set by layout(s) that show zellij status.
                                when = "test $ZELLIJ && test ! $__ZELLIJ_DONT_SHOW_STATUS";
                                command = "echo $ZELLIJ_SESSION_NAME";
                                disabled = false;
                            };
                        };
                    };
                };
            };
    };
}
