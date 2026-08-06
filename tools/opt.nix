# Our own helpers, exposed to every module as the `tools` specialArg (wired in tools/default.nix, which
# records why they are not in `lib`).
#
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

    ## A SYSTEM feature whose default is "some user on this host wants the matching home feature", so a
    ## host need not repeat what its user unit already says. From a nixos or darwin half:
    ##
    ##   options.my.sys.apps.games.enable =
    ##       tools.opt.mkFollowsUsers config [ "apps" "games" ] "Steam ...";
    ##
    ## Works only because home-manager runs as a submodule of the system evaluation. One-directional on
    ## purpose: a home feature reading `my.sys.*` back would deadlock the two evaluations.
    ##
    ## `path` is a LIST, not a name: a name misses once the feature moves into a namespace folder, and a
    ## missed lookup defaults to `false`, which uninstalls rather than errors.
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
    ## the secret path-hole a feature exposes (e.g. `git.signingKeyFile = tools.opt.mkSecretPath "..."`);
    ## a unit fills it with `tools.secrets.path`.
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
