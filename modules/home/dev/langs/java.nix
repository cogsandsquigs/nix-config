{ pkgs, ... }: {
    lang = [ "java" ];

    pkgs = with pkgs; [
        jdk # Project toolchain. NOT the LSP's JVM — jdtls hardcodes its own bundled JDK 21.
        gradle
        kotlin

        jdt-language-server
        google-java-format
    ];

    lsp = [
        {
            name = "jdtls";
            # nixpkgs' `jdtls` wrapper resolves the equinox launcher, platform config dir and JVM
            # itself, so bare is correct. WART: `-data` defaults to a hash of *basename(cwd)*, so
            # two checkouts with the same directory name share one workspace index. Unfixable from
            # here (helix can't expand the project root into args) — wrap it if that bites.
            cmd = [ "jdtls" ];

            # Nested, not dotted like gopls': jdtls' MapFlattener splits its `java.*` keys and
            # walks submaps, so a literal "java.format.enabled" attr never resolves.
            config.java = {
                # Default "interactive" waits on a reload command no client here can send.
                configuration.updateBuildConfiguration = "automatic";

                format.enabled = false; # `fmt` below owns formatting
                signatureHelp.enabled = true;
                inlayHints.parameterNames.enabled = "all";
                maven.downloadSources = true;
                eclipse.downloadSources = true;
            };
        }
    ];

    fmt = [
        "google-java-format"
        "--aosp" # 4-space / 100-col, matching treefmt and the helix indent
        "-"
    ];

    # Helix's builtin list omits settings.gradle*, rooting a multi-module build at a subproject.
    roots.java = [
        "pom.xml"
        "build.gradle"
        "build.gradle.kts"
        "settings.gradle"
        "settings.gradle.kts"
    ];
}
