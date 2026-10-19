{
    flake.modules.homeManager."apps/obsidian" = { pkgs, ... }: { home.packages = [ pkgs.obsidian ]; };
}
