# VS Code — install only, no settings (deliberate: the work box wants the app, but its config is
# managed elsewhere / left to the GUI). Opt-in via `my.user.dev.editors.vscode.enable` (declared in
# ./default.nix). Off everywhere by default.
{
    pkgs,
    lib,
    config,
    ...
}:
{
    config = lib.mkIf config.my.user.dev.editors.vscode.enable {
        home.packages = with pkgs; [ vscode ];

        programs.vscode = {
            enable = true;
        };
    };
}
