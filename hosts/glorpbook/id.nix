# Host identity for glorpbook (the MacBook) -- HOST-ONLY; user identity lives in users/<name>/.
#
# Checked against the schema in tools/fleet.nix, so an unknown user, a platform that contradicts
# `class`, or a `primaryUser` outside `users` is a type error here rather than a surprise later. The
# hostname is this directory's name, and cannot be set.
#
# `primaryUser` is omitted: it defaults to the first entry of `users`, which is all this single-user
# host needs. It exists because some host-level singletons take exactly one user (nix-darwin's
# system.primaryUser, the Homebrew prefix owner).
{
    class = "darwin";
    system = "aarch64-darwin";
    users = [ "cogs" ];
}
