{ pkgs, ... }: {
  lang = [ "docker-compose" ];

  pkgs = with pkgs; [ docker-compose-language-service ];

  fmt = [
    "prettierd"
    "%{buffer_name}"
  ];
}
