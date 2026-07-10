# gpg-agent OS-specific tweaks. Imported from ./default.nix, so gated by `my.user.utils.enable`
# alongside the rest of gpg (./gpg.nix enables the agent itself). Self-gates on OS: the macOS branch
# adds mac-native pinentry + a wake-time agent restart; the Linux branch just picks a pinentry.
{
    pkgs,
    lib,
    config,
    ...
}:
let
    inherit (pkgs.stdenv) isDarwin;
    enabled = config.my.user.utils.enable;

    # After the Mac sleeps, the agent serving ~/.gnupg/S.gpg-agent (which gpg auto-starts — the
    # launchd socket-activated one is unused/broken here) can wedge while still alive, so launchd
    # never restarts it and git signing fails. Killing it makes gpg respawn a fresh one; --launch
    # primes it.
    gpgWakeScript = pkgs.writeShellScript "gpg-agent-wake" ''
        ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
        ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent || true
    '';
in
{
    # mkMerge of per-OS mkIf (NOT a raw `if pkgs… then …`): keeps the config structure static so it
    # doesn't force `pkgs` — which, in standalone home-manager, depends on `config` (config.nixpkgs)
    # and would otherwise cause infinite recursion. launchd.agents is darwin-only, so it must only
    # ever be defined on darwin.
    config = lib.mkMerge [
        (lib.mkIf (enabled && isDarwin) {
            home.packages = [ pkgs.sleepwatcher ];

            # Mac-native pinentry (also installed system-wide as pinentry_mac). Without this,
            # gpg-agent.conf has no `pinentry-program` line and GUI passphrase prompts fail.
            # pinentry_mac.meta.mainProgram = "pinentry-mac", so the program name resolves
            # automatically.
            services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

            # Restart gpg-agent on wake via sleepwatcher (IOKit power notifications) — the reliable
            # way to hook "on wake" on macOS (plain launchd agents have no wake trigger). This
            # automates the manual `gpgconf --kill gpg-agent` fix.
            launchd.agents.gpg-agent-wake = {
                enable = true;
                config = {
                    ProgramArguments = [
                        "${pkgs.sleepwatcher}/bin/sleepwatcher"
                        "-w"
                        "${gpgWakeScript}" # -w = run script on wake
                    ];
                    RunAtLoad = true;
                    KeepAlive = true;
                    ProcessType = "Background";
                };
            };
        })

        # Linux/NixOS: home-manager runs gpg-agent as a systemd user service, so the macOS wake
        # workaround does not apply. Just pick a pinentry — a headless default; a GUI host can
        # override with e.g. pkgs.pinentry-gnome3.
        (lib.mkIf (enabled && !isDarwin) { services.gpg-agent.pinentry.package = pkgs.pinentry-curses; })
    ];
}
