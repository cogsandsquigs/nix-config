{ pkgs, ... }: {
  lang = [ "bash" ];

  pkgs = with pkgs; [
    bash-language-server
    shfmt
    shellcheck
  ];

  file-types.bash = [
    "bash"
    "sh"
  ];

  fmt = [
    "shfmt"
    "--indent=4"
    "--binary-next-line"
    "--case-indent"
    "--space-redirects"
    "-"
  ];
}
