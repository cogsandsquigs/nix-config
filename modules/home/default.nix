# The complete home-manager configuration for cogs, shared across every host. OS-specific
# differences are handled inline with `lib.optionals pkgs.stdenv.isDarwin` etc.
{ ... }:
{
    imports = [
        ./base.nix
        ./git.nix
        ./ssh.nix
        ./games.nix
        ./terminal.nix

        ./shell
        ./utils
        ./desktop-apps
        ./dev
    ];
}
