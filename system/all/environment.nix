{ pkgs, username, ... }:
{
    environment = {
        shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
        ];

        systemPackages = with pkgs; [
            util-linux # System utils for Linux and MacOS (?)
        ];

    };

    users.users.${username} = {
        shell = pkgs.fish;
        description = username;
    };

    programs.fish.enable = true;
    programs.zsh.enable = true;
    programs.bash.enable = true;
    # programs.nushell.enable = true;
}
