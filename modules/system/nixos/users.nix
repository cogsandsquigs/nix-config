# System-level user account for cogs (home-manager config lives under modules/home).
{ pkgs, ... }: {
    users.users.cogs = {
        description = "cogs";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
    };
}
