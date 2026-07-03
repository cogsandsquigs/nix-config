{
  flake.modules.homeManager.base = { pkgs, ... }: {
    home.packages = with pkgs; [ openvpn ];
  };

  flake.modules.darwin.base = {
    homebrew = {
      casks = [
        "tailscale-app"
        "openvpn-connect"
      ];
    };
  };

  flake.modules.nixos.base = { };
}
