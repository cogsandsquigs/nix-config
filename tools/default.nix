# Composition helpers. This is the ONLY place that knows how a host is assembled.
#
# A host declares its class in `hosts/<name>/id.nix` (see tools/fleet.nix), so the builder for it is
# chosen from data rather than named by hand: `flake.nix` never mentions a machine. Adding a host is
# `hosts/<name>/{id.nix,default.nix}` and nothing else.
#
# Exposes:
#   fleet, root                        -- the typed fleet, and the flake root (checks derive paths)
#   forAllSystems                      -- map over every platform the fleet uses (per-system outputs)
#   {nixos,darwin,home}Configurations  -- one entry per host of that class
{ inputs, root }:
let
    inherit (inputs) nixpkgs nix-darwin home-manager;
    lib = nixpkgs.lib;

    fleet = import ./fleet.nix { inherit lib root; };

    # Our own option/safety helpers, handed to every module as the `tools` specialArg -- on all three
    # host classes, system and home alike.
    #
    # Why a dedicated `tools` arg and NOT `lib.my.*`: home-manager owns its modules' `lib` and pins it
    # via specialArgs, rebuilding it as `pkgs.lib` + its own `lib.hm.*`. Injecting our helpers by
    # overriding `lib` either clobbers `lib.hm` (home-manager breaks) or is silently ignored (HM's
    # `lib` outranks a `_module.args.lib` override). A separate arg sidesteps that entirely and reads
    # uniformly in both system and home modules: `tools.mkEnabled`.
    #
    # The one route that COULD yield `lib.my.*` is a nixpkgs lib-overlay (make `pkgs.lib` carry `.my`
    # so home-manager extends THAT). We did not take it: overlaying `lib` is discouraged upstream
    # (nixpkgs internals capture the pre-overlay lib, so you get two lib instances) and it needs
    # asymmetric wiring -- an overlay for the home side plus `specialArgs.lib` for the system side.
    # Per-host, because `tools.conf.eachOs` bakes in the host's platform so the call site needs no
    # system argument. `opt` and `secrets` are platform-agnostic. (Step 4 of the migration removes
    # `conf` along with its only callers, at which point this stops needing the host.)
    mkTools = system: {
        opt = import ./opt.nix { inherit lib; };
        secrets = import ./secrets.nix;
        conf = import ./conf.nix { inherit lib system; };
    };

    # The complete module-argument contract, in one place, for all three builders.
    #
    # `moduleArgs` carries the set itself, so the home-manager sub-evaluation can be handed exactly
    # these args (see modules/home-manager.nix) instead of a hand-copied list that drifts out of step.
    # That drift was a real bug: `isHomeOnly` reached the top-level evaluation but never the sub-eval.
    argsFor =
        host:
        let
            args = {
                inherit inputs fleet host;
                tools = mkTools host.system;
            };
        in
        args // { moduleArgs = args; };

    # Host modules go into the list as bare paths, NOT wrapped in `{ imports = [ path ]; }`. A wrapper
    # would add an import level, and `imports` are collected after their parent, which reorders every
    # merged string option the host contributes to. On glorpbook that moved the
    # `system.activationScripts.postActivation` fragment behind home-manager's, so `activateSettings
    # -u` ran after home-manager activation instead of before. The host file declares its own `_class`
    # instead, which costs no ordering and still rejects the file if it is ever imported elsewhere.
    hostDir = host: root + "/hosts/${host.name}";

    mkNixos =
        host:
        lib.nixosSystem {
            specialArgs = argsFor host;
            modules = [
                (root + "/modules/system/nixos")
                (hostDir host)
            ];
        };

    mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
            specialArgs = argsFor host;
            modules = [
                (root + "/modules/system/darwin")
                (hostDir host)
            ];
        };

    # A STANDALONE home-manager configuration -- a machine where Nix is installed per-user and there
    # is no NixOS/nix-darwin system layer (the work desktop on Ubuntu). The user's home.nix, not this
    # builder, owns the feature set, so a standalone box is just "this user, no system layer".
    #
    # Unlike the system hosts (which get nixpkgs config via useGlobalPkgs) a standalone config owns
    # its own `pkgs`, so allowUnfree/qt are set here to match modules/system/common/nixpkgs.nix.
    mkHome =
        host:
        home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
                inherit (host) system;
                config = {
                    allowUnfree = true;
                    qt.enable = true;
                };
            };

            extraSpecialArgs = argsFor host;

            modules = [
                { home.username = host.primaryUser; }
                (root + "/users/${host.primaryUser}/home.nix")
                (hostDir host)
            ];
        };

    ofClass = class: lib.filterAttrs (_: h: h.class == class) fleet.hosts;
in
{
    inherit fleet root;

    # Map a function over every platform the fleet actually uses (per-system outputs such as the
    # formatter and the checks). Replaces flake-parts' `perSystem`.
    forAllSystems =
        f:
        lib.genAttrs (lib.unique (lib.mapAttrsToList (_: h: h.system) fleet.hosts)) (
            system: f nixpkgs.legacyPackages.${system}
        );

    nixosConfigurations = lib.mapAttrs (_: mkNixos) (ofClass "nixos");
    darwinConfigurations = lib.mapAttrs (_: mkDarwin) (ofClass "darwin");

    # Keyed "<user>@<host>" -- scripts/nxm discovers the standalone target from this name.
    homeConfigurations = lib.mapAttrs' (
        name: host: lib.nameValuePair "${host.primaryUser}@${name}" (mkHome host)
    ) (ofClass "home");
}
