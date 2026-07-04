{ pkgs, ... }:

# System is macos (darwin)!
if pkgs.stdenv.isDarwin then
    # macOS-specific GPG agent config: mac-native pinentry, plus a wake-time restart.
    # Only imported on Darwin, and self-gates as belt-and-braces.
    let
        # After the Mac sleeps, the agent serving ~/.gnupg/S.gpg-agent (which gpg
        # auto-starts — the launchd socket-activated one is unused/broken here) can
        # wedge while still alive, so launchd never restarts it and git signing
        # fails. Killing it makes gpg respawn a fresh one; --launch primes it.
        gpgWakeScript = pkgs.writeShellScript "gpg-agent-wake" ''
            ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
            ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent || true
        '';
    in
    {
        home.packages = [ pkgs.sleepwatcher ];

        # Mac-native pinentry (also installed system-wide as pinentry_mac). Without
        # this, gpg-agent.conf has no `pinentry-program` line and GUI passphrase
        # prompts fail. pinentry_mac.meta.mainProgram = "pinentry-mac", so the
        # program name is resolved automatically.
        services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

        # Restart gpg-agent on wake via sleepwatcher (IOKit power notifications) —
        # the reliable way to hook "on wake" on macOS (plain launchd agents have no
        # wake trigger). This automates the manual `gpgconf --kill gpg-agent` fix.
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
    }
# System is linux (nixos)!
else
    # Linux/NixOS-specific GPG agent config. Stub for the (currently placeholder)
    # nixos host — only imported on Linux (see ./gpg.nix), and self-gates too.
    #
    # On Linux, home-manager runs gpg-agent as a systemd user service, so the
    # macOS wake workaround does not apply. This just picks a pinentry; a headless
    # default is used, and a GUI host can override with e.g. pkgs.pinentry-gnome3.
    { pkgs, ... }: { services.gpg-agent.pinentry.package = pkgs.pinentry-curses; }
