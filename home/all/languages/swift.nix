{ pkgs, ... }:
{
    home.packages = with pkgs; [
        swift # Swift compiler/tools
        sourcekit-lsp # LSP for swift (and C ig... they weird abt it...)
        swift-format # Formatter (duh!)
    ];
}
