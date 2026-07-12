{ pkgs, ... }: {
  lang = [ "python" ];

  pkgs = with pkgs; [
    python3
    uv # Project manager
    ty # LSP, typechecker
    ruff # Formatter, linter
  ];

  lsp = [
    {
      name = "ty";
      cmd = [
        "ty"
        "server"
      ];
    }
    {
      name = "ruff";
      cmd = [
        "ruff"
        "server"
      ];
    }
  ];

  # See: https://stackoverflow.com/questions/77876253/sort-imports-alphabetically-with-ruff
  # And: https://github.com/helix-editor/helix/discussions/7749
  fmt = [
    "bash"
    "-c"
    "ruff check --select I --fix - | ruff format -"
  ];
}
