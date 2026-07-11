# The shared home-manager library — the FULL feature set, imported by every user unit. Selection
# is purely via `my.user.<feature>.enable` flags: core features default on, optional ones
# (games, desktop-apps) default off and are inert until a unit opts in. No import-bundle split.
#
# OS-specific differences are handled inline with `lib.optionals pkgs.stdenv.isDarwin` etc.
{ ... }: {
    imports = [
        ./base.nix
        ./secrets.nix
        ./git.nix
        ./ssh.nix
        ./terminal.nix

        ./shell
        ./utils
        ./dev

        ./games.nix
        ./desktop-apps
    ];
}
