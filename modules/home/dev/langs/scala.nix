{ pkgs, ... }: {
    lang = [ "scala" ];

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

    extensions = {
        ".scala" = "scala";
        ".sbt" = "scala";
        ".sc" = "scala";
    };

    # fmt = null -- metals formats via scalafmt; options go in .scalafmt.conf (HOCON)
}
