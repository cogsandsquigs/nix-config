{ pkgs, ... }: {
    lang = [ "pest" ];

    pkgs = with pkgs; [ pest-ide-tools ];

    # pest-language-server is auto-registered by pest-ide-tools;
    # explicit entry needed so helix wires it to the pest language.
    lsp = [{ name = "pest-language-server"; cmd = [ "pest-language-server" ]; }];

    # fmt = null — LSP provides formatting
}
