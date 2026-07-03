# VPN clients (installed via Homebrew casks on macOS).
{ ... }:
{
    homebrew = {
        casks = [
            "tailscale-app"
            "openvpn-connect"
        ];
    };
}
