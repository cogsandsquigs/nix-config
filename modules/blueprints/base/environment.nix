{ ... }:

let
    base-attrs = pkgs: {
        environment = {
            shells = [
                pkgs.zsh
                pkgs.fish
                pkgs.bash
            ];

            systemPackages = with pkgs; [
                nh # Nix helper. See: https://github.com/nix-community/nh
                util-linux # System utils for Linux and MacOS (?)
            ];

        };

        programs.fish.enable = true;
        programs.zsh.enable = true;
        programs.bash.enable = true;
        # programs.nushell.enable = true;
    };
in
{
    flake.modules.darwin.base = { pkgs, ... }: base-attrs pkgs;
    flake.modules.nixos.base = { pkgs, ... }: base-attrs pkgs;
}
