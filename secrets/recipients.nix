# agenix recipients — PUBLIC age keys, one per IDENTITY (a user on a specific machine, "<user>@<host>").
# Safe to commit; only the matching PRIVATE key (/etc/nix/age/<user> on that machine, gitignored) can
# decrypt. The computed rules in ./secrets.nix pick a secret's recipients from its folder: an identity
# folder ("cogs@home-desktop/…") encrypts to that one key; a bare-user folder ("cogs/…") encrypts to
# ALL of that user's machine keys.
#
# BOOTSTRAP a new identity (once per user, ON that machine):
#   age-keygen -o /etc/nix/age/<user>     # writes the private key; prints "Public key: age1…"
#   age-keygen -y /etc/nix/age/<user>     # reprint the public key any time
# then add the printed `age1…` here as "<user>@<host>" and `agenix -r` to re-key user-wide secrets.
{
    "cogs@macbook" = "age10s8vwdz6da00g7l2vgepz5wmxh47aznwudj5vyja6xnd7qtlc45qws5sm5";

    # Not yet bootstrapped — generate on the owning machine and uncomment (see BOOTSTRAP above).
    # A secret placed for one of these identities fails eval until its key is filled in — the
    # intended "go bootstrap this" signal.
    #   "cogs@home-desktop"   = "age1…";   # personal NixOS tower
    #   "ipratt@work-desktop" = "age1…";   # work box (standalone HM)
}
