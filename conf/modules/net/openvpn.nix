{ tools, ... }: {
    options.my.sys.net.openvpn.enable = tools.opt.mkDisabled "OpenVPN";

    darwin = { lib, config, ... }: {
        config = lib.mkIf config.my.sys.net.openvpn.enable { homebrew.casks = [ "openvpn-connect" ]; };
    };

    nixos =
        {
            lib,
            config,
            pkgs,
            ...
        }:
        {
            config = lib.mkIf config.my.sys.net.openvpn.enable {
                environment.systemPackages = [ pkgs.openvpn ];
            };
        };
}
