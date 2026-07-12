{ pkgs, ... }: {
  lang = [ "kotlin" ];

  pkgs = with pkgs; [
    kotlin
    # kotlin-native # Native runtime — fails on macOS
    kotlin-language-server # Alpha LSP

    # NOTE: May be subsumed by the LSP eventually.
    detekt # Static analysis
    ktlint # Linting
    ktfmt # Formatting
  ];

  lsp = [
    {
      name = "kotlin-language-server";
      cmd = [ "kotlin-language-server" ];
    }
  ];
}
