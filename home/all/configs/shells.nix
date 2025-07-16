# The shell configuration I use!
{
    pkgs,
    lib,
    username,
    ...
}:
let
    inherit (pkgs) stdenv;
    inherit (lib.strings) concatMapStrings;
    inherit (lib.attrsets) mapAttrsToList;

    aliases = {
        ls = "eza --icons";
        du = "dust";
        cat = "bat"; # Better cat via `bat`
        cd = "z"; # Better cd via `zoxide`
        nv = "nvim";
        neofetch = "fastfetch"; # Neofetch via fastfetch
        editnix = "sh /etc/nix/scripts/editnix.sh";
        upgrade = "python3 /etc/nix/scripts/sysutil/run.py upgrade";
        rebuild = "python3 /etc/nix/scripts/sysutil/run.py rebuild";
        cleanup = "python3 /etc/nix/scripts/sysutil/run.py cleanup";
    };

    variables = {
        EDITOR = editor;
        LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.llvmPackages_20.clang
            pkgs.libiconvReal
        ];

        JAVA_HOME = "$(dirname $(dirname $(readlink -f $(which java))))"; # Add java home
    };

    binPaths = [
        "/rawr"
        "$HOME/.cargo/bin"
        "${pkgs.llvmPackages_20.clang-tools}/bin"
        "$HOME/.local/bin"
        "$HOME/.nix-profile/bin"
        "/nix/var/nix/profiles/default/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/run/current-system/sw/bin"

        # Force to be apple native CC.
        # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
        # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
        (
            if stdenv.isDarwin then
                "" # "export PATH=\"/usr/bin:$PATH\""
            else
                ""
        )

    ];

    libPaths = [ ];

    # Maps every variable in `variables` to a string for a specific shell.
    # @param `f`: A function `f :: String -> Any -> String` that takes the variable name,
    # then value, then returns a string that loads the variable in a specific shell the
    # user wants.
    # @returns the string of all variables to be loaded in a shell.
    variablesToString =
        f: (concatMapStrings (s: s + "\n") (mapAttrsToList f variables));

    # Maps every path entry in `path` to a string for a specific shell
    # @param `f`: A function `f :: String -> String` that takes the path entry, then returns
    # a command to add it to the path.
    # @returns a string of commands to add things to path.
    pathsToString = f: paths: (concatMapStrings (s: (f s) + "\n") paths);

    editor = "hx";
in
{
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
            ${variablesToString (name: val: "set -gx ${name} ${val}")}
            ${pathsToString (path: "fish_add_path ${path}") binPaths}
        '';

        # Like shellInit, but runs last.
        # NOTE: This enables the starship prompt character for transient prompts.
        # See: https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
        shellInitLast = ''
            function starship_transient_prompt_func
                starship module character
            end
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
            "fish/themes/Catppuccin Mocha.theme".source =
                "${catppuccin-fish}/themes/Catppuccin Mocha.theme";
        };

    programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        history.size = 10000;
        autocd = true;

        # Enable powerlevel10k theme
        initExtra = ''
            source /etc/profile.d/nix.sh # Source nix environment variables
        '';

        envExtra = ''
            ${variablesToString (name: val: "export ${name}=\"${val}\"")}
            ${pathsToString (path: "export PATH=${path}:$PATH") binPaths}
        '';

        shellAliases = aliases;
    };
}
