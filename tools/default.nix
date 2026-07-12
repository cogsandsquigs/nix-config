# Composition helpers. These are the *only* places that know how a host is assembled:
# every host picks one system class (darwin or nixos) and inherits the shared home config
# via `modules/home-manager.nix`.

{ inputs }:
let
  inherit (inputs) nixpkgs nix-darwin home-manager;

  # Our own option/safety helpers (see lib/opts.nix), passed to every module as the `tools`
  # specialArg — on all three host classes, system and home alike.
  #
  # Why a dedicated `tools` arg and NOT `lib.my.*`: home-manager owns its modules' `lib` and pins
  # it via specialArgs, rebuilding it as `pkgs.lib` + its own `lib.hm.*`. Injecting our helpers by
  # overriding `lib` either clobbers `lib.hm` (home-manager breaks) or is silently ignored (HM's
  # `lib` outranks a `_module.args.lib` override). A separate arg sidesteps that entirely and reads
  # uniformly in both system and home modules: `tools.mkEnabled`.
  #
  # The one route that *could* yield `lib.my.*` is a nixpkgs lib-overlay (make `pkgs.lib` carry
  # `.my` so home-manager extends THAT with hm → my + hm both present). We did NOT take it: overlaying
  # `lib` is discouraged upstream (nixpkgs internals capture the pre-overlay lib, so you get two lib
  # instances) and it needs asymmetric wiring — an overlay for the home side plus `specialArgs.lib`
  # for the system side. `tools` is one mechanism, robust and uniform. (The overlay is worth a spike
  # someday just to gauge its fragility — see the migration plan.)
  # Per-host tools: opt/secrets are system-agnostic; conf is baked with the host's system so
  # `tools.conf.eachOs` needs no system argument at the call site.
  mkTools = system: {
    opt = import ./opt.nix { lib = nixpkgs.lib; };
    secrets = import ./secrets.nix;
    conf = import ./conf.nix {
      lib = nixpkgs.lib;
      inherit system;
    };
  };

  idOf = host: import (host + "/id.nix");

  specialArgsFor =
    host:
    let
      id = idOf host;
    in
    {
      inherit inputs;
      tools = mkTools id.system;
      hostId = id;
    };
in
{
  # Map a function over every system we care about (used for per-system outputs such as
  # `formatter`). Replaces flake-parts' `perSystem`.
  forAllSystems =
    f:
    nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] (
      system: f nixpkgs.legacyPackages.${system}
    );

  # Build a nix-darwin system. `host` is a path to the host module (e.g. ./hosts/glorpbook),
  # which owns the machine's identity (hostPlatform, host-only tweaks) via its id.nix.
  mkDarwin =
    host:
    nix-darwin.lib.darwinSystem {
      specialArgs = specialArgsFor host;
      modules = [
        ../modules/system/darwin
        host
      ];
    };

  # Build a NixOS system. Same contract as `mkDarwin`.
  mkNixos =
    host:
    nixpkgs.lib.nixosSystem {
      specialArgs = specialArgsFor host;
      modules = [
        ../modules/system/nixos
        host
      ];
    };

  # Build a STANDALONE home-manager configuration — for a machine where Nix is installed
  # per-user and there is no NixOS/nix-darwin system layer (e.g. the work desktop on Ubuntu).
  # `host` is a path to the host module (e.g. ./hosts/work-desktop); its id.nix supplies the
  # platform (`system`) and the single user unit to apply. The user's home.nix — not this
  # builder — owns the feature set, so a standalone box is just "this user, no system layer".
  #
  # Unlike the system hosts (which get nixpkgs config via useGlobalPkgs), a standalone config
  # owns its own `pkgs`, so allowUnfree/qt are set here to match modules/system/common/nixpkgs.
  mkHome =
    { host }:
    let
      id = idOf host;
      user = builtins.head id.users;
    in
    home-manager.lib.homeManagerConfiguration (
      let
        pkgs = import nixpkgs {
          inherit (id) system;
          config = {
            allowUnfree = true;
            qt.enable = true;
          };
        };
      in
      {
        pkgs = pkgs;
        extraSpecialArgs = specialArgsFor host;
        modules = [
          (../users + "/${user}/home.nix")
          { home.username = user; }
          host
        ];
      }
    );
}
