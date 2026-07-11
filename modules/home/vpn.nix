{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
let
    cfg = config.my.user.vpn;
in
{
    options.my.user.vpn = {
        enable = tools.opt.mkDisabled "OpenVPN CLI + profile management";
        # Keyed by profile identifier (used as the .ovpn filename). Submodule so fields can grow
        # without changing call sites. `name` is the display name in the VPN client UI (not yet
        # wired on all platforms — declared now so call sites don't change when it is).
        profiles = lib.mkOption {
            type = lib.types.attrsOf (
                lib.types.submodule {
                    options = {
                        name = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = null;
                            description = "Display name shown in the VPN client. Defaults to the profile key if null.";
                        };
                        path = lib.mkOption {
                            type = lib.types.str;
                            description = "Path to the decrypted .ovpn file (e.g. from tools.secrets.path).";
                        };
                    };
                }
            );
            default = { };
            description = "VPN profiles to install. Attr key = profile identifier / filename.";
        };
    };

    config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.openvpn ];

        # Fail the build if any declared profile has an empty path — catches mis-wired secrets
        # before activation rather than silently installing nothing.
        assertions = lib.mapAttrsToList (key: profile: {
            assertion = profile.path != "";
            message = "my.user.vpn.profiles.${key}.path must not be empty";
        }) cfg.profiles;

        # On Darwin: copy each profile into OpenVPN Connect's watched dir; the app picks them up
        # on next launch. Fails loudly if the decrypted file isn't readable (agenix didn't run,
        # secret missing, etc.). On NixOS: no-op until NetworkManager wiring is added.
        # agenix is async on macOS (LaunchAgent) and sync on Linux (agenixInstall dag step).
        # The two platforms therefore need different dag deps and different profile destinations.
        home.activation.installOvpnProfiles = lib.mkIf (cfg.profiles != { }) (
            tools.conf.eachOs
                # Linux: agenixInstall is a synchronous dag step — file is ready when we run.
                (lib.hm.dag.entryAfter [ "writeBoundary" "agenixInstall" ] (
                    lib.concatStringsSep "\n" (lib.mapAttrsToList (profileKey: profileCfg: ''
                        _ovpn_path="${profileCfg.path}"
                        if [ ! -r "$_ovpn_path" ]; then
                            echo "vpn: profile '${profileKey}' not readable at $_ovpn_path" >&2
                            exit 1
                        fi
                        _dest="$HOME/.config/openvpn"
                        mkdir -p "$_dest"
                        $DRY_RUN_CMD cp "$_ovpn_path" "$_dest/${profileKey}.ovpn"
                        $DRY_RUN_CMD chmod 600 "$_dest/${profileKey}.ovpn"
                    '') cfg.profiles)
                ))
                # macOS: agenix decrypts via LaunchAgent (async) — setupLaunchAgents loads the
                # new script, then we poll up to 15 s for the file to appear before failing.
                (lib.hm.dag.entryAfter [ "writeBoundary" "setupLaunchAgents" ] (
                    lib.concatStringsSep "\n" (lib.mapAttrsToList (profileKey: profileCfg: ''
                        profiles="$HOME/Library/Application Support/OpenVPN Connect/profiles"
                        mkdir -p "$profiles"
                        _ovpn_path="${profileCfg.path}"
                        _wait=15
                        while [ "$_wait" -gt 0 ] && [ ! -r "$_ovpn_path" ]; do
                            sleep 1
                            _wait=$(( _wait - 1 ))
                        done
                        if [ ! -r "$_ovpn_path" ]; then
                            echo "vpn: profile '${profileKey}' not readable at $_ovpn_path after 15s" >&2
                            exit 1
                        fi
                        $DRY_RUN_CMD cp "$_ovpn_path" "$profiles/${profileKey}.ovpn"
                        $DRY_RUN_CMD chmod 600 "$profiles/${profileKey}.ovpn"
                    '') cfg.profiles)
                ))
        );
    };
}
