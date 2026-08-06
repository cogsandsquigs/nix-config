# gpg-agent OS-specific tweaks. Gated by `my.user.cli.utils.enable` (./default.nix)
# alongside the rest of gpg (./gpg.nix enables the agent itself). Self-gates on OS: the macOS branch
# adds mac-native pinentry; the Linux branch just picks a pinentry.
{
    home =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            inherit (pkgs.stdenv) isDarwin;
            enabled = config.my.user.cli.utils.enable;
        in
        {
            # mkMerge of per-OS mkIf, NOT `if pkgs.stdenv.isDarwin then`: this keeps the config structure
            # static, so it never forces `pkgs` -- which in standalone home-manager depends on `config`
            # (config.nixpkgs) and would recurse infinitely.
            config = lib.mkMerge [
                (lib.mkIf (enabled && isDarwin) {
                    # Without this, gpg-agent.conf has no `pinentry-program` line and GUI passphrase
                    # prompts fail. `meta.mainProgram` resolves the binary name.
                    services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

                    # home-manager defaults this true, which writes `grab` into gpg-agent.conf. On macOS
                    # `grab` makes pinentry-mac call a window-server grab API at startup; after wake from
                    # sleep that call fails and pinentry-mac exits immediately ("No pinentry"). Off, it
                    # reads the passphrase from the Keychain silently, with no window-server interaction.
                    services.gpg-agent.grabKeyboardAndMouse = false;

                    # 8 hours, against a 600s default. With Keychain-backed retrieval, pinentry is then
                    # essentially never called after the first unlock post-reboot.
                    services.gpg-agent.defaultCacheTtl = 28800;
                    services.gpg-agent.maxCacheTtl = 86400;
                })

                # Linux: gpg-agent runs as a systemd user service, so none of the above applies. A
                # headless pinentry; a GUI host can override with e.g. pkgs.pinentry-gnome3.
                (lib.mkIf (enabled && !isDarwin) { services.gpg-agent.pinentry.package = pkgs.pinentry-curses; })
            ];
        };
}
