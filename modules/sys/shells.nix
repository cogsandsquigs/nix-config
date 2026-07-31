# Base shells plus the couple of system-wide packages every machine needs.
#
# Identical on both system classes, so the body is written once and each class points at it.
let
    shells = { pkgs, ... }: {
        environment = {
            shells = [
                pkgs.zsh
                pkgs.fish
                pkgs.bash
            ];

            systemPackages = with pkgs; [
                nh # Nix helper. See: https://github.com/nix-community/nh
                util-linux # System utils for Linux and MacOS (?)
            ];
        };

        programs.fish.enable = true;
        programs.zsh.enable = true;
        programs.bash.enable = true;
        # programs.nushell.enable = true;
    };
in
{
    nixos = shells;
    darwin = shells;
}
