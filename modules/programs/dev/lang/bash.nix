{ ... }: {
    flake.modules.homeManager.dev.lang = { pkgs, ... }: {
        home.packages = with pkgs; [
            bash-language-server
            shfmt # Shell formatter
            shellcheck # Linter, req. for shfmt
        ];
    };
}
