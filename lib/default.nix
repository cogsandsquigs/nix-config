# Composition helpers. These are the *only* places that know how a host is assembled:
# every host picks one system class (darwin or nixos) and inherits the shared home config
# via `modules/home-manager.nix`.

{ inputs }:
let
    inherit (inputs) nixpkgs nix-darwin;
in
{
    # Map a function over every system we care about (used for per-system outputs such as
    # `formatter`). Replaces flake-parts' `perSystem`.
    forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
            "aarch64-darwin"
            "x86_64-darwin"
            "x86_64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});

    # Build a nix-darwin system. `host` is a path to the host module (e.g. ./hosts/macbook),
    # which owns the machine's identity (hostPlatform, hostname, host-only tweaks).
    mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
            specialArgs = { inherit inputs; };
            modules = [
                ../modules/system/darwin
                host
            ];
        };

    # Build a NixOS system. Same contract as `mkDarwin`.
    mkNixos =
        host:
        nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [
                ../modules/system/nixos
                host
            ];
        };
}
