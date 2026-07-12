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

    # Linux: copy each profile into ~/.config/openvpn (plain openvpn reads from there).
    # macOS: OpenVPN Connect has no programmatic import interface — profiles must be imported
    # once by hand through the app UI. The agenix secret is still decrypted and available at
    # its runtime path (tools.secrets.path); nothing to do here.
    home.activation.installOvpnProfiles = lib.mkIf (cfg.profiles != { }) (
      tools.conf.eachOs (lib.hm.dag.entryAfter [ "writeBoundary" "setupLaunchAgents" "agenixInstall" ] (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (profileKey: profileCfg: ''
            _ovpn_path="${profileCfg.path}"
            if [ ! -r "$_ovpn_path" ]; then
                echo "vpn: profile '${profileKey}' not readable at $_ovpn_path" >&2
                exit 1
            fi
            _dest="$HOME/.config/openvpn"
            mkdir -p "$_dest"
            $DRY_RUN_CMD cp "$_ovpn_path" "$_dest/${profileKey}.ovpn"
            $DRY_RUN_CMD chmod 600 "$_dest/${profileKey}.ovpn"
          '') cfg.profiles
        )
      )) ""
    );
  };
}
