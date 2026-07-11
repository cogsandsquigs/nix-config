# agenix secret management for the HOME (per-user) scope.
#
# Pulls in the agenix home-manager module and points it at this user's age identity. Inert until a
# user unit declares a secret with `tools.secrets.declare` and feeds its `tools.secrets.path` into a
# feature's `tools.opt.mkSecretPath` hole (see the helpers in lib/opts.nix).
#
# The agenix module is imported unconditionally (imports can't be option-gated, and it's inert
# without secrets) — mirroring the system-side `modules/system/<class>/secrets.nix`.
{ inputs, config, ... }: {
    imports = [ inputs.agenix.homeManagerModules.default ];

    # Private age identity per user, at a fixed path (this machine's key for this user — distinct per
    # machine, never copied). Gitignored, never committed. Bootstrap once, on this machine:
    # `age-keygen -o /etc/nix/age/<user>`, then add its public key to secrets/recipients.nix as
    # "<user>@<host>".
    age.identityPaths = [ "/etc/nix/age/${config.home.username}" ];
}
