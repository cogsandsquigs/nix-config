# Allows for using/developing FUSE filesystems on MacOS
{
    darwin =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.os.darwin.fuse.enable =
                tools.opt.mkDisabled "FUSE filesystem support (macfuse-stubs)";

            config = lib.mkIf config.my.sys.os.darwin.fuse.enable {
                environment.systemPackages = with pkgs; [
                    macfuse-stubs
                    pkg-config
                ];
            };
        };
}
