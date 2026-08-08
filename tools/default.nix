# Composition helpers. This is the ONLY place that knows how a host is assembled.
#
# A host declares its class in `hosts/<name>/id.nix` (see tools/fleet.nix), so the builder for it is
# chosen from data rather than named by hand: `flake.nix` never mentions a machine. Adding a host is
# `hosts/<name>/{id.nix,default.nix}` and nothing else.
#
# Exposes:
#   fleet, registry, root              -- the typed fleet, the feature registry, the flake root
#   forAllSystems                      -- map over every platform the fleet uses (per-system outputs)
#   {nixos,darwin,home}Configurations  -- one entry per host of that class
#   vmPackages                         -- `<host>-vm` for every NixOS host on one platform
{ inputs, root }:
let
    inherit (inputs) nixpkgs nix-darwin home-manager;
    inherit (nixpkgs) lib;

    fleet = import ./fleet.nix { inherit lib root; };

    registry = import ./registry.nix {
        inherit lib root tools;
        importTree = inputs.import-tree;
    };

    # Our own option/safety helpers, handed to every module as the `tools` specialArg, on all three
    # classes.
    #
    # A dedicated arg and NOT `lib.my.*`: home-manager pins its modules' `lib` via specialArgs, rebuilt
    # as `pkgs.lib` + its own `lib.hm.*`. Injecting through `lib` either clobbers `lib.hm` or is ignored
    # (HM's `lib` outranks a `_module.args.lib` override). The only route that would work is a nixpkgs
    # lib-overlay, which is discouraged upstream (nixpkgs internals capture the pre-overlay lib, so you
    # get two instances) and needs asymmetric wiring -- an overlay for home plus `specialArgs.lib` for
    # system.
    tools = {
        opt = import ./opt.nix { inherit lib; };
        secrets = import ./secrets.nix;
    };

    # The module-argument contract, in one place, for all three builders. `moduleArgs` carries the set
    # itself so the home-manager sub-evaluation can be handed exactly these args (see
    # modules/os/home-manager.nix) rather than a hand-copied list that drifts -- which it did: `isHomeOnly`
    # once reached the top-level evaluation but never the sub-eval.
    argsFor =
        host:
        let
            args = {
                inherit
                    inputs
                    registry
                    host
                    tools
                    ;
            };
        in
        args // { moduleArgs = args; };

    # Bare paths, NOT `{ imports = [ path ]; }`: a wrapper adds an import level, and `imports` are
    # collected after their parent, which reorders every merged string option the host contributes to. On
    # glorpbook that put `system.activationScripts.postActivation` behind home-manager's, so
    # `activateSettings -u` ran after home-manager activation instead of before. The host file declares
    # its own `_class` instead, which costs no ordering.
    hostDir = host: root + "/hosts/${host.name}";

    mkNixos =
        host:
        lib.nixosSystem {
            specialArgs = argsFor host;
            modules = lib.attrValues registry.nixos ++ [ (hostDir host) ];
        };

    mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
            specialArgs = argsFor host;
            modules = lib.attrValues registry.darwin ++ [ (hostDir host) ];
        };

    # A STANDALONE home-manager configuration: per-user Nix, no system layer (the work desktop on Ubuntu).
    # The user's home.nix owns the feature set, not this builder.
    #
    # System hosts get their nixpkgs config and overlays through useGlobalPkgs; a standalone config owns
    # its own `pkgs`, so it reads the same shared files modules/os/nixpkgs.nix does.
    mkHome =
        host:
        home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
                inherit (host) system;
                config = import (root + "/modules/_nixpkgs-config.nix");
                overlays = import (root + "/modules/_overlays.nix") inputs;
            };

            extraSpecialArgs = argsFor host;

            modules = lib.attrValues registry.homeManager ++ [
                { home.username = host.primaryUser; }
                (root + "/users/${host.primaryUser}/home.nix")
                (hostDir host)
            ];
        };

    ofClass = class: lib.filterAttrs (_: h: h.class == class) fleet.hosts;

    # Hoisted out of the output set because `vmPackages` reads it back.
    nixosConfigurations = lib.mapAttrs (_: mkNixos) (ofClass "nixos");
in
{
    inherit
        fleet
        registry
        root
        nixosConfigurations
        ;

    # Map a function over every platform the fleet actually uses (per-system outputs such as the
    # formatter and the checks). Replaces flake-parts' `perSystem`.
    forAllSystems =
        f:
        lib.genAttrs (lib.unique (lib.mapAttrsToList (_: h: h.system) fleet.hosts)) (
            system: f nixpkgs.legacyPackages.${system}
        );

    darwinConfigurations = lib.mapAttrs (_: mkDarwin) (ofClass "darwin");

    # Keyed "<user>@<host>" -- scripts/nxm discovers the standalone target from this name.
    homeConfigurations = lib.mapAttrs' (
        name: host: lib.nameValuePair "${host.primaryUser}@${name}" (mkHome host)
    ) (ofClass "home");

    # Every NixOS host as a bootable QEMU VM -- `system.build.vm`, the same thing `nixos-rebuild
    # build-vm` produces, given a name.
    #
    # Filtered by platform: a VM has to be built by the machine it targets, so asking the Mac for an
    # `x86_64-linux` one finds no attribute rather than a build error.
    #
    # `meta` never enters a derivation, so pinning `mainProgram` moves no store path; it is what lets
    # `nix run` find the run script inside the output.
    vmPackages =
        system:
        lib.mapAttrs' (
            name: cfg:
            lib.nameValuePair "${name}-vm" (
                cfg.config.system.build.vm.overrideAttrs (old: {
                    meta = (old.meta or { }) // {
                        mainProgram = "run-${name}-vm";
                    };
                })
            )
        ) (lib.filterAttrs (name: _: fleet.hosts.${name}.system == system) nixosConfigurations);
}
