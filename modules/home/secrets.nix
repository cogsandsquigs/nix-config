# agenix secret management for the HOME (per-user) scope.
#
# Scaffolding only (Stage C0): pulls in the agenix home-manager module and points it at this user's
# age identity. No secrets are declared yet — the module is inert until a user unit sets
# `age.secrets.<name>`. Each user unit wires its own secrets with `tools.userSecret` and hands the
# decrypted path to a feature's `tools.opt.mkSecretPath` hole (see the secrets helpers in lib/opts.nix).
#
# The agenix module is imported unconditionally (imports can't be option-gated, and it's inert
# without secrets) — mirroring the system-side `modules/system/<class>/secrets.nix`.
{ inputs, config, ... }: {
    imports = [ inputs.agenix.homeManagerModules.default ];

    # Private age identities live at a fixed, known path per owner — same on every host, gitignored
    # (never committed). Bootstrap once per user: `age-keygen -o /etc/nix/age/<user>`, then add the
    # printed public key to secrets/recipients.nix (Stage C1).
    age.identityPaths = [ "/etc/nix/age/${config.home.username}" ];
}
