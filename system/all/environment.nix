{pkgs, ...}: {
    environment = {
        shells = [
            pkgs.zsh
            pkgs.fish
            pkgs.bash
            pkgs.nushell
        ];
    };

    # Enable these shells
    programs.zsh.enable = true;
    programs.fish.enable = true;
}
