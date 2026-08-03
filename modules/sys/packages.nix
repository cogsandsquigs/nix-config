# The couple of system-wide packages every machine needs, whatever else it runs.
#
# Identical on both system classes, so the body is written once and each class points at it.
let
    packages = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
            nh # Nix helper. See: https://github.com/nix-community/nh
            util-linux # System utils for Linux and MacOS (?)
        ];
    };
in
{
    nixos = packages;
    darwin = packages;
}
