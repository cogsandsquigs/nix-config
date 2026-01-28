{ pkgs, ... }:
{
    home.packages = with pkgs; [
        scala-next # Latest (stable!) version, `scala` is the LTS version
        scala-cli # CLI for scala
        bloop # Buildserver
        metals # LSP
        scalafix # Linter
        scalafmt # Formatter
    ];
}
