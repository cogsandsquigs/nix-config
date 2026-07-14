# gpg-agent OS-specific tweaks. Imported from ./default.nix, so gated by `my.user.utils.enable`
# alongside the rest of gpg (./gpg.nix enables the agent itself). Self-gates on OS: the macOS branch
# adds mac-native pinentry; the Linux branch just picks a pinentry.
{
    pkgs,
    lib,
    config,
    ...
}:
let
    inherit (pkgs.stdenv) isDarwin;
    enabled = config.my.user.utils.enable;
in
{
    # mkMerge of per-OS mkIf (NOT a raw `if pkgs… then …`): keeps the config structure static so it
    # doesn't force `pkgs` — which, in standalone home-manager, depends on `config` (config.nixpkgs)
    # and would otherwise cause infinite recursion. launchd.agents is darwin-only, so it must only
    # ever be defined on darwin.
    config = lib.mkMerge [
        (lib.mkIf (enabled && isDarwin) {
            # Mac-native pinentry (also installed system-wide as pinentry_mac). Without this,
            # gpg-agent.conf has no `pinentry-program` line and GUI passphrase prompts fail.
            # pinentry_mac.meta.mainProgram = "pinentry-mac", so the program name resolves
            # automatically.
            services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

            # home-manager defaults grabKeyboardAndMouse to true, which writes `grab` into
            # gpg-agent.conf. On macOS, `grab` causes pinentry-mac to call a window-server grab
            # API on startup; after wake from sleep the window server is unsettled and this call
            # fails, making pinentry-mac exit immediately ("No pinentry"). Disabling grab lets
            # pinentry-mac retrieve the passphrase from the macOS Keychain silently — no dialog,
            # no window-server interaction needed.
            services.gpg-agent.grabKeyboardAndMouse = false;

            # Cache the passphrase for up to 8 hours (default is 600s / 10 min). Combined with
            # Keychain-backed passphrase retrieval, this means pinentry is essentially never
            # called after the first successful unlock post-reboot.
            services.gpg-agent.defaultCacheTtl = 28800;
            services.gpg-agent.maxCacheTtl = 86400;
        })

        # Linux/NixOS: home-manager runs gpg-agent as a systemd user service, so the macOS
        # workarounds do not apply. Just pick a pinentry — a headless default; a GUI host can
        # override with e.g. pkgs.pinentry-gnome3.
        (lib.mkIf (enabled && !isDarwin) { services.gpg-agent.pinentry.package = pkgs.pinentry-curses; })
    ];
}
