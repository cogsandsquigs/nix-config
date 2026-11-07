{
    flake.modules.homeManager."apps/pdfs" = { };

    flake.modules.darwin."apps/pdfs" = {
        homebrew.casks = [ "adobe-acrobat-reader" ];
    };
}
