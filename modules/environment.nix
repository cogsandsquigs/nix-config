{pkgs, ...}: {
    environment = {
        shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
            pkgs.nushell
        ];
    };
}
