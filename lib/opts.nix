# Option constructors + safety helpers, exposed to every module as the `tools` specialArg (wired in
# lib/default.nix). Kept OUT of `lib` on purpose: home-manager owns its modules' `lib` (rebuilt as
# pkgs.lib + its own `lib.hm.*`), so injecting our helpers via `lib` either clobbers `lib.hm` or is
# ignored. A dedicated `tools` arg composes cleanly. Keeps feature modules terse and uniform: a
# feature declares its own `enable` leaf next to the code it guards, using these.
{ lib }:
let
    t = lib.types;

    # A boolean option with an explicit default. The `example` is the opposite of the default, so
    # `nix eval`/docs show the meaningful flip.
    mkBoolOpt =
        default: description:
        lib.mkOption {
            inherit default description;
            type = t.bool;
            example = !default;
        };
in
{
    ## enable-style toggles ------------------------------------------------------------------------
    mkEnabled = mkBoolOpt true; # core feature: on unless explicitly disabled
    mkDisabled = mkBoolOpt false; # optional feature: opt-in
    mkRiding = parent: mkBoolOpt parent; # sub-feature: default follows its parent group's value
    mkRequired =
        # no default → eval errors if a host/user forgets to choose. Reserve for features where a
        # forgotten value would be a *silent* bug (most core fails loudly, so rarely needed).
        description:
        lib.mkOption {
            inherit description;
            type = t.bool;
        };

    ## typed value options (for the "only what varies" settings) ----------------------------------
    mkStr =
        default: description:
        lib.mkOption {
            inherit default description;
            type = t.str;
        };
    mkNullStr =
        description:
        lib.mkOption {
            inherit description;
            type = t.nullOr t.str;
            default = null;
        };
    mkEnum =
        values: default: description:
        lib.mkOption {
            inherit default description;
            type = t.enum values;
        };

    ## safety --------------------------------------------------------------------------------------
    # Express "feature A requires feature B" as an assertions entry. Usage in a module:
    #   config.assertions = [ (tools.requires { when = cfg.enable; needs = otherCfg.enable;
    #                                            message = "A needs B"; }) ];
    requires =
        {
            when,
            needs,
            message,
        }:
        {
            assertion = (!when) || needs;
            inherit message;
        };
}
