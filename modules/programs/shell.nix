# The shell configuration I use!

{ inputs, lib, ... }:
let
    inherit (lib.strings) concatMapStrings;
    inherit (lib.attrsets) mapAttrsToList;

    aliases = {
        ls = "eza --icons";
        du = "dust";
        cat = "bat"; # Better cat via `bat`
        cd = "z"; # Better cd via `zoxide`
        nv = "nvim";
        lg = "lazygit";
        neofetch = "fastfetch"; # Neofetch via fastfetch
        editnix = "/etc/nix/scripts/editnix.sh";
        upgrade = "/etc/nix/scripts/upgrade.sh";
        rebuild = "/etc/nix/scripts/rebuild.sh";
        cleanup = "/etc/nix/scripts/cleanup.sh";
    };

    variables = pkgs: {
        EDITOR = editor;
        JAVA_HOME = "$(dirname $(dirname $(readlink -f $(which java))))"; # Add java home

        # NOTE: Necessary for (some) rust compilation things/libs
        LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libiconvReal ];
    };

    binPaths =
        { pkgs, config }:
        [
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
    variablesToString = f: variables: (concatMapStrings (s: s + "\n") (mapAttrsToList f variables));

    # Maps every path entry in `path` to a string for a specific shell
    # @param `f`: A function `f :: String -> String` that takes the path entry, then returns
    # a command to add it to the path.
    # @returns a string of commands to add things to path.
    pathsToString = f: paths: (concatMapStrings (s: (f s) + "\n") paths);

    editor = "hx";
in
{

    flake.modules.homeManager.shell =
        { pkgs, config, ... }:
        {
            imports = with inputs.self.modules.homeManager; [ starship ];

            home.packages = with pkgs; [
                fish
                zsh
            ];

            programs.fish = {
                enable = true;
                generateCompletions = true;

                shellAliases = aliases;

                interactiveShellInit = ''
                    set fish_greeting # Disable fish greeting
                    fish_config theme choose "Catppuccin Mocha" # Set theme. We use `choose` since using
                                                                # `save` forces a prompt, which is annoying,
                                                                # even though `choose` doesn't make it
                                                                # "permanent".
                '';

                shellInit = ''
                    ${variablesToString (name: val: "set -gx ${name} ${val}") (variables pkgs)}
                    ${pathsToString (path: "fish_add_path ${path}") (binPaths {
                        pkgs = pkgs;
                        config = config;
                    })}
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

            programs.zsh = {
                enable = true;
                enableCompletion = true;
                autosuggestion.enable = true;
                syntaxHighlighting.enable = true;
                history.size = 10000;
                autocd = true;

                initContent = ''
                    source /etc/profile.d/nix.sh # Source nix environment variables
                '';

                envExtra = ''
                    ${variablesToString (name: val: "export ${name}=\"${val}\"") (variables pkgs)}
                    ${pathsToString (path: "export PATH=${path}:$PATH") (binPaths {
                        pkgs = pkgs;
                        config = config;
                    })}
                '';

                shellAliases = aliases;
            };
        };
}
