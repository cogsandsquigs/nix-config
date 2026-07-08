# Composition helpers. These are the *only* places that know how a host is assembled:
# every host picks one system class (darwin or nixos) and inherits the shared home config
# via `modules/home-manager.nix`.

{ inputs }:
let
    inherit (inputs) nixpkgs nix-darwin home-manager;
in
{
    # Map a function over every system we care about (used for per-system outputs such as
    # `formatter`). Replaces flake-parts' `perSystem`.
    forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] (
            system: f nixpkgs.legacyPackages.${system}
        );

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

    # Build a STANDALONE home-manager configuration — for a machine where Nix is installed
    # per-user and there is no NixOS/nix-darwin system layer (e.g. the work desktop on Ubuntu).
    # `host` is a path to the host module (e.g. ./hosts/work-desktop), which sets home.username
    # and any `my.*` overrides. `system` defaults to x86_64-linux.
    #
    # Unlike the system hosts (which get nixpkgs config via useGlobalPkgs), a standalone config
    # owns its own `pkgs`, so allowUnfree/qt are set here to match modules/system/common/nixpkgs.
    mkHome =
        {
            host,
            system ? "x86_64-linux",
        }:
        home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
                inherit system;
                config = {
                    allowUnfree = true;
                    qt.enable = true;
                };
            };
            extraSpecialArgs = { inherit inputs; };
            modules = [
                ../modules/home
                host
            ];
        };
}
