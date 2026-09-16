{ pkgs, ... }: {
    pkgs = with pkgs; [
        scala-next # Latest stable; `scala` is the LTS version
        bloop # Build server
        metals # LSP -- also provides formatting via scalafmt; no explicit fmt needed
        scalafix # Linter
        scalafmt # Formatter (invoked by metals)
    ];

    lsp = [
        {
            name = "metals";
            cmd = [ "metals" ];
        }
    ];

    # fmt = null -- metals formats via scalafmt; options go in .scalafmt.conf (HOCON)

    languages.scala.extensions = [
        ".scala"
        ".sbt"
        ".sc"
    ];
}
