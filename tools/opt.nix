# Our own helpers, exposed to every module as the `tools` specialArg (wired in lib/default.nix).
# Kept OUT of `lib` on purpose: home-manager owns its modules' `lib` (rebuilt as pkgs.lib + its own
# `lib.hm.*`), so injecting our helpers via `lib` either clobbers `lib.hm` or is ignored. A dedicated
# `tools` arg composes cleanly and reads uniformly in system + home modules.
#
# Grouped by what a helper DOES:
#   tools.opt.*      -- option & module-authoring helpers (constructors + assertions).
#   tools.secrets.*  -- sops secret wiring (register a secret + read its decrypted path).
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
    # -- tools.opt -- option & module-authoring helpers --------------------------------------------
    ## enable-style toggles
    mkEnabled = mkBoolOpt true; # core feature: on unless explicitly disabled
    mkDisabled = mkBoolOpt false; # optional feature: opt-in
    mkRiding = mkBoolOpt; # sub-feature: default follows its parent group's value

    ## A SYSTEM feature whose default is "some user on this host wants the matching home feature".
    ##
    ## A machine needs Steam at the system level only because a user on it plays games, so saying that
    ## twice -- once in the host, once in the user unit -- is bookkeeping the host should not have to
    ## do. Usage, from a nixos or darwin half:
    ##
    ##   options.my.sys.apps.games.enable =
    ##       tools.opt.mkFollowsUsers config [ "apps" "games" ] "Steam ...";
    ##
    ## This works only because home-manager runs as a submodule of the system evaluation, so the system
    ## can read the home config. It is one-directional on purpose: a home feature must never read
    ## `my.sys.*` back, or the two evaluations would deadlock.
    ##
    ## `path` is the option path under `my.user` as a LIST, because a name misses once the feature moves
    ## into a namespace folder and a missed lookup is a silent `false` -- it uninstalls rather than
    ## errors.
    mkFollowsUsers =
        config: path: description:
        lib.mkOption {
            inherit description;
            type = t.bool;
            default = lib.any (
                user:
                lib.attrByPath (
                    [
                        "my"
                        "user"
                    ]
                    ++ path
                    ++ [ "enable" ]
                ) false user
            ) (lib.attrValues (config.home-manager.users or { }));
            defaultText = lib.literalMD "true when any user on this host sets `my.user.${lib.concatStringsSep "." path}.enable`";
        };

    ## typed value options (for the "only what varies" settings)
    mkStr =
        default: description:
        lib.mkOption {
            inherit default description;
            type = t.str;
        };
    ## for a value that is only ever meaningful non-empty (creds, hosts). A type, not an assertion:
    ## the error names the offending option instead of surfacing at the end of the build.
    mkNonEmptyStr =
        default: description:
        lib.mkOption {
            inherit default description;
            type = t.nonEmptyStr;
        };
    ## the agnostic secret path-hole a feature exposes (e.g.
    ## `git.signingKeyFile = tools.opt.mkSecretPath "..."`). It's an option constructor, so it lives
    ## here; the unit fills it via the secret-wiring helpers below.
    mkSecretPath =
        description:
        lib.mkOption {
            inherit description;
            type = t.nullOr t.str;
            default = null;
        };

    ## safety: express "feature A requires feature B" as an assertions entry. Usage:
    ##   config.assertions = [ (tools.opt.requires { when = cfg.enable; needs = otherCfg.enable;
    ##                                                message = "A needs B"; }) ];
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
