# VPN clients (installed via Homebrew casks on macOS).
{
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.vpn.enable = tools.opt.mkDisabled "VPN clients (Tailscale, OpenVPN Connect)";

    config = lib.mkIf config.my.sys.vpn.enable (
        tools.conf.eachOs
            # NixOS config
            { }

            # Darwin config
            {
                homebrew = {
                    casks = [
                        "tailscale-app"
                        "openvpn-connect"
                    ];
                };
            }
    );
}
