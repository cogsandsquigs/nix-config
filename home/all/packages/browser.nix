{ pkgs, ... }:
{
    home.packages = with pkgs; [
        librewolf
        # NOTE: Why `firefox-unwrapped` and not `firefox`?
        # See: https://github.com/NixOS/nixpkgs/issues/366581
        # NOTE: Why no use? B/c not preserving firefox config thru reinstalls.
        # So use homebrew to install on mac
        # firefox-unwrapped
    ];
}
