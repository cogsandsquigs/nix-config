# Base shells + a couple of system-wide packages needed on every machine.
{ pkgs, ... }: {
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
}
