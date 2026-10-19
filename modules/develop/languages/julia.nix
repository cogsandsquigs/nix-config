{
    flake.modules.homeManager."develop/languages/julia" = { pkgs, ... }: {
        home.packages = with pkgs; [ julia-bin ];

        programs.helix = {
            languages = {
                language = [
                    {
                        name = "julia";
                        auto-format = true;

                        # TODO: formatter...
                        # see: https://github.com/JuliaEditorSupport/JuliaFormatter.jl

                        language-servers = [ "julia" ];
                    }
                ];

                language-servers.julia = {
                    command = "julia";
                    timeout = 60;
                    args = [
                        "-e"
                        "using LanguageServer; runserver();"
                    ];
                };
            };
        };
    };
}
