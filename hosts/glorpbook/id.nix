# Host identity for glorpbook (the MacBook) — HOST-ONLY (no user identity; that lives in
# users/<name>/). A plain attrset read by lib.mkDarwin (as the `hostId` specialArg) and by flake.nix
# (for the darwinConfigurations attr name). `users` lists the user units placed on this host;
# `primaryUser` is the one that owns host-level singletons (system.primaryUser, the Homebrew prefix).
{
  hostName = "glorpbook";
  system = "aarch64-darwin";
  users = [ "cogs" ];
  primaryUser = "cogs";
}
