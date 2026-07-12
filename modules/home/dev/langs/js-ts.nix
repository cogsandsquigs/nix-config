{ pkgs, ... }: {
  lang = [
    "javascript"
    "typescript"
    "svelte"
  ];

  pkgs = with pkgs; [
    nodejs
    bun
    typescript-language-server
    vscode-langservers-extracted
    prettierd
  ];

  lsp = [
    {
      name = "typescript-language-server";
      cmd = [
        "typescript-language-server"
        "--stdio"
      ];
    }
    {
      name = "vscode-eslint-language-server";
      cmd = [
        "vscode-eslint-language-server"
        "--stdio"
      ];
    }
  ];

  fmt = [
    "prettierd"
    "%{buffer_name}"
  ];
}
