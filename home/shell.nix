# The shell configuration I use!
{pkgs, ...}: let
    inherit (pkgs) stdenv;
in {
    programs.fish = {
        enable = true;
        generateCompletions = true;

        shellAliases = {
            ls = "eza --icons";
            du = "dust";
            cat = "bat"; # Better cat via `bat`
            cd = "z"; # Better cd via `zoxide`
            nv = "nvim";
            upgrade = "python3 /etc/nix/scripts/run.py upgrade";
            rebuild = "python3 /etc/nix/scripts/run.py rebuild";
            cleanup = "python3 /etc/nix/scripts/run.py cleanup";
        };

        interactiveShellInit = ''
            set fish_greeting # Disable fish greeting
        '';

        shellInit = ''
            set -gx EDITOR nvim # Set default editor to nvim
            set -gx JAVA_HOME $(dirname $(dirname $(readlink -f $(which java)))) # Add java home
            fish_add_path $HOME/.cargo/bin # export PATH="$HOME/.cargo/bin:$PATH" # Add cargo bin to path
            ${
                # Force to be apple native CC.
                # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
                # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
                if stdenv.isDarwin
                then "" # "export PATH=\"/usr/bin:$PATH\""
                else ""
            }
        '';

        # Like shellInit, but runs last.
        # HACK: This is really jank and technically inits starship twice, but it works.
        # TODO: Make this faster/less jank?
        shellInitLast = ''
            function starship_transient_prompt_func
                starship module character
            end
            starship init fish | source
            enable_transience
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
            source ~/.p10k.zsh # Source powerlevel10k theme
        '';

        envExtra = ''
            export EDITOR=nvim # Set default editor to nvim
            export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) # Add java home
            export PATH="$HOME/.cargo/bin:$PATH" # Add cargo bin to path
            ${
                # Force to be apple native CC.
                # NOTE: Needed because otherwise cc from installed clang/nix will override and cause issues on
                # darwin systems, e.x. Rust compilation of external C libraries (e.x. libiconv).
                if stdenv.isDarwin
                then "" # "export PATH=\"/usr/bin:$PATH\""
                else ""
            }
        '';

        plugins = [
            {
                name = "powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
            }
        ];

        shellAliases = {
            ls = "eza --icons";
            du = "dust";
            cat = "bat"; # Better cat via `bat`
            cd = "z"; # Better cd via `zoxide`
            nv = "nvim";
            upgrade = "python3 /etc/nix/scripts/run.py upgrade";
            rebuild = "python3 /etc/nix/scripts/run.py rebuild";
            cleanup = "python3 /etc/nix/scripts/run.py cleanup";
        };

        oh-my-zsh = {
            enable = true;
            theme = "robbyrussell";
            plugins = ["git"];
        };
    };
}
