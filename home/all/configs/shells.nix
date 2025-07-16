# The shell configuration I use!
{ pkgs, lib, ... }:
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
        JAVA_HOME = "$(dirname $(dirname $(readlink -f $(which java))))"; # Add java home
    };

    # Maps every variable in `variables` to a string for a specific shell.
    # @param `f`: A function `f :: String -> Any -> String` that takes the variable name,
    # then value, then returns a string that loads the variable in a specific shell the
    # user wants.
    # @returns the string of all variables to be loaded in a shell.
    variablesToString =
        f: (concatMapStrings (s: s + "\n") (mapAttrsToList f variables));

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
            # set -gx EDITOR ${editor} # Set default editor to nvim
            # set -gx JAVA_HOME $(dirname $(dirname $(readlink -f $(which java)))) # Add java home
            fish_add_path $HOME/.cargo/bin # Add cargo bin to path
            fish_add_path ${pkgs.llvmPackages_20.clang-tools}/bin # Add clang tools to path
            ${
                # Force to be apple native CC.
                # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
                # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
                if stdenv.isDarwin then
                    "" # "export PATH=\"/usr/bin:$PATH\""
                else
                    ""
            }

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

    programs.nushell = {
        enable = true;
        # NOTE: We do this so that we can use the nushell `ls`, since it outputs
        # nushell-native structures/datatypes.
        shellAliases = removeAttrs aliases [ "ls" ];

        settings = {
            completions.external.enable = true; # Enable external completions
            use_kitty_protocol = true; # Since we use Kitty, set kitty protocol
            buffer_editor = editor; # Set the editor
            show_banner = false; # Disable nushell banner/welcome message
        };

        envFile.text = ''
            $env.EDITOR = "${editor}" # Set default editor to nvim
            $env.JAVA_HOME = (dirname (dirname (readlink -f ...(which java | get path)))) # Add java home
            ${
                # Force to be apple native CC.
                # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
                # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
                if stdenv.isDarwin then
                    "" # "export PATH=\"/usr/bin:$PATH\""
                else
                    ""
            }

            # Set PATH variables
            $env.PATH = $env.PATH | prepend ($env.HOME)/.cargo/bin # Add cargo bin to path
            $env.PATH = $env.PATH | prepend ${pkgs.llvmPackages_20.clang-tools}/bin # Add clang tools to path
            $env.PATH = $env.PATH | prepend ($env.HOME)/local/bin # Add local bin to path
            $env.PATH = $env.PATH | prepend ($env.HOME)/.nix-profile/bin # Add nix profile bin to path
            $env.PATH = $env.PATH | prepend /nix/var/nix/profiles/default/bin # Add nix binaries to path
            $env.PATH = $env.PATH | prepend /etc/profiles/per-user/($env.USER)/bin # Add nix user binaries to path
            $env.PATH = $env.PATH | prepend /run/current-system/sw/bin # Add nix current system binaries to path

            # Set transient prompt
            # NOTE: the `^` at the beginning of the command tells Nushell to run
            # the command, and use the output as the value.
            $env.TRANSIENT_PROMPT_COMMAND = ^starship module character
        '';

        # Configuration. i.e., we set the theme here!
        configFile.text =
            let
                catppuccin-nushell = pkgs.fetchFromGitHub {
                    owner = "catppuccin";
                    repo = "nushell";
                    rev = "10a429db05e74787b12766652dc2f5478da43b6f";
                    hash = "sha256-7XfoWsrMRGefc3ygxixUqAOfkg2ssj7o60Gi74S2lXw=";
                };
            in
            ''
                # Source the theme.
                source ${catppuccin-nushell}/themes/catppuccin_mocha.nu
            '';
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
            export EDITOR=${editor} # Set default editor to nvim
            export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) # Add java home
            export PATH="$HOME/.cargo/bin:$PATH" # Add cargo bin to path
            ${
                # Force to be apple native CC.
                # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
                # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
                if stdenv.isDarwin then
                    "" # "export PATH=\"/usr/bin:$PATH\""
                else
                    ""
            }
        '';

        shellAliases = aliases;
    };
}
