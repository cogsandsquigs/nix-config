# Allows for using/developing FUSE filesystems on MacOS

{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        macfuse-stubs
        pkg-config
    ];
}
