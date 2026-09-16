# The system half of the shell group: the shells themselves, registered with the OS.
#
# Unconditional, unlike the rest of this directory. `my.user.shell.enable` is a home-manager option
# (see ./default.nix) and a system evaluation cannot read it, so this half cannot be gated on the flag
# the other half uses.
#
# Identical on both system classes, so the body is written once and each class points at it.
let
    shells = { pkgs, ... }: {
        environment.shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
        ];

        programs.fish.enable = true;
        programs.zsh.enable = true;
        programs.bash.enable = true;
    };
in
{
    nixos = shells;
    darwin = shells;
}
