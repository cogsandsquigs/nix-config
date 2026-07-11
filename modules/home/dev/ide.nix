{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.user.dev.ide.enable = tools.mkRiding config.my.user.dev.enable "JetBrains IDEA";

    config = lib.mkIf config.my.user.dev.ide.enable {
        home.packages = with pkgs; [ jetbrains.idea ];
    };
}
