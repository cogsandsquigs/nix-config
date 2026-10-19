{
    flake.modules.homeManager."apps/browsers" = { };

    flake.modules.darwin."apps/browsers" = {
        homebrew.casks = [ "firefox" ];
    };
}
