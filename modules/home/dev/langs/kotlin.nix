{ pkgs, ... }:
{
    home.packages = with pkgs; [
        kotlin
        # kotlin-native # Native runtime for Kotlin (since its JVM) NOTE; Fails on MacOS?
        kotlin-language-server # (Currently) Alpha language-server for Kotlin

        # NOTE: These packages may be subsumed/replaced by the LSP, as these are unofficial.
        detekt # Static code analysis
        ktlint # Linting
        ktfmt # Formatting
    ];
}
