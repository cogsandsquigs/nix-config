{pkgs, ...}: {
    home.packages = with pkgs; [
        kitty # Terminal
    ];
}
