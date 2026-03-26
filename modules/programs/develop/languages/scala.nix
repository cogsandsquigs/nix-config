{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                scala-next # Latest (stable!) version, `scala` is the LTS version
                bloop # Buildserver
                metals # LSP
                scalafix # Linter
                scalafmt # Formatter
            ];
        };
}
