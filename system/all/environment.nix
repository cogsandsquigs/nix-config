{pkgs, ...}: {
    environment = {
        shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
            pkgs.nushell
        ];
    };

    programs.fish.enable = true;
    programs.zsh.enable = true;
    programs.bash.enable = true;
}
