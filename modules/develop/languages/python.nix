{
    flake.modules.homeManager."develop/languages/python" = { pkgs, ... }: {
        home.packages = with pkgs; [
            python3
            uv
            ty
            ruff
        ];

        programs.helix = {
            languages = {
                language = [
                    {
                        name = "python";
                        auto-format = true;

                        formatter = {
                            command = "bash";
                            args = [
                                "-c"
                                "ruff check --select I --fix - | ruff format -"
                            ];
                        };

                        language-servers = [
                            "ty"
                            "ruff"
                        ];
                    }
                ];

                language-server.ty = {
                    command = "ty";
                    args = [ "server" ];
                };

                language-server.ruff = {
                    command = "ruff";
                    args = [ "server" ];
                };
            };
        };
    };
}
