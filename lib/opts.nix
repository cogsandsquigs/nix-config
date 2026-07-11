# Our own helpers, exposed to every module as the `tools` specialArg (wired in lib/default.nix).
# Kept OUT of `lib` on purpose: home-manager owns its modules' `lib` (rebuilt as pkgs.lib + its own
# `lib.hm.*`), so injecting our helpers via `lib` either clobbers `lib.hm` or is ignored. A dedicated
# `tools` arg composes cleanly and reads uniformly in system + home modules.
#
# Grouped by what a helper DOES:
#   tools.opt.*      — option & module-authoring helpers (constructors + assertions).
#   (top-level)      — agenix secret wiring. NOTE: this group's shape is still being finalized;
#                      it will move under `tools.secrets.*` in a follow-up commit.
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

    # Path to an encrypted secret, from its name. A secret's name is its path under `secrets/`
    # WITHOUT the `.age` suffix (e.g. "users/cogs/gpg" → secrets/users/cogs/gpg.age). `../secrets`
    # resolves relative to THIS file (lib/), i.e. the repo-root `secrets/` dir, regardless of caller.
    secretFile = name: ../secrets + "/${name}.age";

    # Build an `age.secrets` fragment: { "<name>" = { file = <name>.age; } // attrs; }. In `let` so
    # userSecret/sysSecret below can build on it (sibling attrs can't reference each other).
    mkSecret = name: attrs: {
        ${name} = {
            file = secretFile name;
        }
        // attrs;
    };
in
{
    # ── tools.opt — option & module-authoring helpers ────────────────────────────────────────────
    opt = {
        ## enable-style toggles
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

        ## typed value options (for the "only what varies" settings)
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

        ## the agnostic secret path-hole a feature exposes (e.g.
        ## `git.signingKeyFile = tools.opt.mkSecretPath "…"`). It's an option constructor, so it lives
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
    };

    # ── secret wiring (agenix) ────────────────────────────────────────────────────────────────────
    # NOTE: shape still being finalized — these move under `tools.secrets.*` (with a location/name
    # model) in the next commit. Left top-level and unchanged for now; nothing in-config uses them
    # yet. A feature stays secret-AGNOSTIC (it only exposes `opt.mkSecretPath`); the user/host unit
    # declares the real secret here and feeds its decrypted `.path` into that hole.
    inherit mkSecret;
    userSecret = owner: name: mkSecret "users/${owner}/${name}" { };
    sysSecret =
        host: name: opts:
        mkSecret "hosts/${host}/${name}" ({ mode = "0400"; } // opts);
}
