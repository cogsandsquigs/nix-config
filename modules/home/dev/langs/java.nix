{ pkgs, ... }: {
    lang = [ "java" ];

    pkgs = with pkgs; [
        jdk # Project toolchain only; jdtls hardcodes its own bundled JDK, ignoring JAVA_HOME
        gradle
        kotlin

        jdt-language-server
        google-java-format
    ];

    lsp = [
        {
            name = "jdtls";
            # The nixpkgs wrapper resolves the equinox launcher, platform config dir and JVM, so
            # bare is correct. WART: `-data` defaults to a hash of *basename(cwd)*, so two
            # checkouts sharing a directory name share one workspace index.
            cmd = [ "jdtls" ];

            # Nested, not dotted like gopls': jdtls walks submaps to resolve its `java.*` keys.
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

    extensions.".java" = "java";

    fmt = [
        "google-java-format"
        "--aosp" # 4-space / 100-col, matching treefmt and the helix indent
        "-"
    ];

    # Adds settings.gradle*, absent from helix's builtin, which roots a multi-module build wrong.
    roots.java = [
        "pom.xml"
        "build.gradle"
        "build.gradle.kts"
        "settings.gradle"
        "settings.gradle.kts"
    ];
}
