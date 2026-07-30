{ pkgs, ... }: {
    pkgs = with pkgs; [
        bash-language-server
        shfmt
        shellcheck
    ];

    lsp = [
        {
            name = "bash-language-server";
            cmd = [
                "bash-language-server"
                "start" # Not --stdio; the subcommand is what helix's builtin passes
            ];
        }
    ];

    fmt = [
        "shfmt"
        "--indent=4"
        "--binary-next-line"
        "--case-indent"
        "--space-redirects"
        "-"
    ];

    languages.bash.extensions = [
        ".sh"
        ".bash"
        ".ash"
        ".dash"
        ".ksh"
        ".mksh"
        ".zsh"
        ".zshenv"
        ".zlogin"
        ".zlogout"
        ".zprofile"
        ".zshrc"
        ".eclass"
        ".ebuild"
        ".bazelrc"
        ".Renviron"
        ".zsh-theme"
        ".cshrc"
        ".tcshrc"
        ".bashrc_Apple_Terminal"
        ".zshrc_Apple_Terminal"
    ];
}
