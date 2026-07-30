{ pkgs, ... }: {
    lang = [ "bash" ];

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

    file-types.bash = [
        "bash"
        "sh"
    ];

    extensions = {
        ".sh" = "shellscript";
        ".bash" = "shellscript";
    };

    fmt = [
        "shfmt"
        "--indent=4"
        "--binary-next-line"
        "--case-indent"
        "--space-redirects"
        "-"
    ];
}
