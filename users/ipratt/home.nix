# The `ipratt` user's home-manager config — the WORK unit: imports the full home library but leaves
# the optional flags (games/desktop-apps) off, so it gets core only (shell, terminal, CLI utils,
# full dev toolchain). Work git identity with signing off (no personal GPG key on the work box; to
# sign later import a work key and set signingKey + signByDefault). Self-contained wherever placed.
{ ... }: {
  imports = [ ../../modules/home ];

  my.user.flakeDir = "/etc/nix";

  my.user.git = {
    email = "ian.pratt@arcticlake.com";
    signingKey = null;
    signByDefault = false;
  };
}
