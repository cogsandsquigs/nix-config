# The shared home-manager CORE, imported by every machine — personal or work. This is the
# "develop + as-needed" baseline: shell, terminal, CLI utils, and the full dev toolchain, but
# NO games or personal GUI apps. Those live in ./personal.nix, which layers on top of this.
#
# OS-specific differences are handled inline with `lib.optionals pkgs.stdenv.isDarwin` etc.
{ ... }: {
    imports = [
        ./base.nix
        ./git.nix
        ./ssh.nix
        ./terminal.nix

        ./shell
        ./utils
        ./dev
    ];
}
