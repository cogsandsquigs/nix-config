{ ... }:
{
    flake.modules.homeManager.browser =
        { pkgs, ... }:
        {
            # home.packages = with pkgs; [ librewolf ];

            programs.librewolf = {
                enable = true;
                # package = pkgs.librewolf;
                languagePacks = [ "en-US" ];
            };
        };
}
