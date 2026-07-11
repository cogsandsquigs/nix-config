# agenix recipients — PUBLIC age keys, keyed by scope path (mirrors the secrets/ layout and the
# config layers). Safe to commit; only the matching PRIVATE keys (/etc/nix/age/<owner>, gitignored)
# can decrypt. The computed rules in ./secrets.nix look a secret up by its owning directory
# ("users/<name>" or "hosts/<name>") and encrypt it to that scope's key here.
#
# BOOTSTRAP a new scope (one-time, on the machine that owns it):
#   age-keygen -o /etc/nix/age/<owner>     # writes the private key; prints "Public key: age1…"
#   age-keygen -y /etc/nix/age/<owner>     # re-print the public key any time
# then add the printed `age1…` here under its scope path and re-key existing secrets if needed
# (`agenix -r`).
{
    # users/ — home-scope secrets, encrypted to a per-user key.
    "users/cogs" = "age10s8vwdz6da00g7l2vgepz5wmxh47aznwudj5vyja6xnd7qtlc45qws5sm5";

    # Not yet bootstrapped — generate on the owning machine and uncomment (see BOOTSTRAP above).
    # A secret placed under one of these scopes will fail eval until its key is filled in, which is
    # the intended "go bootstrap this" signal.
    #   "users/ipratt"       = "age1…";   # work box (standalone HM); run age-keygen there
    #   "hosts/home-desktop" = "age1…";   # personal NixOS tower system key
    #   "hosts/work-desktop" = "age1…";   # (only if the work box ever needs a *system* secret)
}
