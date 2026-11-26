{
    flake.modules.homeManager."apps/documents" = { };

    flake.modules.darwin."apps/documents" = {
        homebrew.casks = [ "adobe-acrobat-reader" ];

        homebrew.masApps = {
            "Pages: Create Documents" = 361309726;
        };
    };
}
