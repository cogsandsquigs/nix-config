{pkgs, ...}: {
    home.stateVersion = "25.05";

    imports = [
        ./all/default.nix
        #  ./darwin/default.nix
    ];
}
