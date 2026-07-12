{ pkgs, ... }: {
  lang = [ "yaml" ];

  pkgs = with pkgs; [
    yaml-language-server
    prettierd
  ];

  lsp = [
    {
      name = "yaml-language-server";
      cmd = [
        "yaml-language-server"
        "--stdio"
      ];
    }
  ];

  fmt = [
    "prettierd"
    "%{buffer_name}"
  ];
}
