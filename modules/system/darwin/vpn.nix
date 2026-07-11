# VPN clients (installed via Homebrew casks on macOS).
{
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.vpn.enable = tools.mkDisabled "VPN clients (Tailscale, OpenVPN Connect)";

    config = lib.mkIf config.my.sys.vpn.enable {
        homebrew = {
            casks = [
                "tailscale-app"
                "openvpn-connect"
            ];
        };
    };
}
