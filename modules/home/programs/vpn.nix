{
    flake.modules.homeManager.vpn = { pkgs, ... }: {
        home.packages = with pkgs; [ openvpn ];
    };

    flake.modules.darwin.vpn = {
        homebrew = {
            casks = [
                "tailscale-app"
                "openvpn-connect"
            ];
        };
    };

    flake.modules.nixos.vpn = { };
}
