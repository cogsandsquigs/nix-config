{pkgs, ...}: {
    environment = {
        shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
            pkgs.nushell
        ];
    };

    programs.zsh.enable = true;
    programs.fish.enable = true;
}
