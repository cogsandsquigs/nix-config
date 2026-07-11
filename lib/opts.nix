# Our own helpers, exposed to every module as the `tools` specialArg (wired in lib/default.nix).
# Kept OUT of `lib` on purpose: home-manager owns its modules' `lib` (rebuilt as pkgs.lib + its own
# `lib.hm.*`), so injecting our helpers via `lib` either clobbers `lib.hm` or is ignored. A dedicated
# `tools` arg composes cleanly and reads uniformly in system + home modules.
#
# Grouped by what a helper DOES:
#   tools.opt.*      — option & module-authoring helpers (constructors + assertions).
#   tools.secrets.*  — agenix secret wiring (register a secret + read its decrypted path).
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

    # A secret is addressed by (location, name): `location` is its audience folder under `secrets/`
    # (an identity "<user>@<host>", or a bare "<user>" for that user on all machines); `name` is the
    # leaf. Together they form the file `secrets/<location>/<name>.age` and the `age.secrets` key
    # "<location>/<name>". `../secrets` resolves relative to THIS file (lib/) — the repo-root
    # `secrets/` — regardless of caller.
    secretFile = location: name: ../secrets + "/${location}/${name}.age";

    # Build an `age.secrets` fragment. In `let` so the `secrets.*` set below can reuse it.
    mkSecret = location: name: attrs: {
        "${location}/${name}" = {
            file = secretFile location name;
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

    # ── tools.secrets — agenix wiring (register + consume) ───────────────────────────────────────
    # A feature stays secret-AGNOSTIC: it only exposes an `opt.mkSecretPath` hole. The user/host unit
    # does the two agenix steps: `declare` registers the secret (so agenix decrypts it at activation),
    # `path` reads back where the plaintext lands — which it feeds into the feature's hole. Scope is
    # carried by `location`, not by a function name: an identity "<user>@<host>" is that machine only;
    # a bare "<user>" is that user on all their machines (see secrets/secrets.nix for how each folder
    # resolves to recipients).
    secrets = {
        # register with agenix:  age.secrets = tools.secrets.declare "cogs@glorpbook" "gpg";
        declare = location: name: mkSecret location name { };
        # same, with extra agenix attrs (owner/mode) for system secrets in /run/agenix
        inherit mkSecret;
        # read the decrypted runtime path:  tools.secrets.path config "cogs@glorpbook" "gpg"
        path =
            config: location: name:
            config.age.secrets."${location}/${name}".path;
    };
}
