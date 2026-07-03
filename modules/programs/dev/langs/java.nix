{ ... }: {
    flake.modules.homeManager.dev.langs = { pkgs, ... }: {
        home.packages = with pkgs; [
            jdk
            gradle
            kotlin
        ];
    };
}
