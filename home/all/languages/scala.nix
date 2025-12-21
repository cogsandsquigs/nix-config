{ pkgs, ... }:
{
    home.packages = with pkgs; [
        scala-next
        scala
        metals # LSP
        bloop # Build server and CLI
    ];
}
