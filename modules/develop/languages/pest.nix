{
    flake.modules.homeManager."develop/languages/pest" = { pkgs, ... }: {
        home.packages = with pkgs; [ pest-ide-tools ];

        programs.helix = {
            languages = {
                language = [
                    {
                        name = "pest";
                        language-servers = [ "pest-language-server" ];
                    }
                ];

                language-server.pest-language-server = {
                    name = "pest-language-server";
                    cmd = [ "pest-language-server" ];
                };
            };
        };
    };
}
