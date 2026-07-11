# Allows for using/developing FUSE filesystems on MacOS
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.fuse.enable = tools.opt.mkDisabled "FUSE filesystem support (macfuse-stubs)";

    config = lib.mkIf config.my.sys.fuse.enable {
        environment.systemPackages = with pkgs; [
            macfuse-stubs
            pkg-config
        ];
    };
}
