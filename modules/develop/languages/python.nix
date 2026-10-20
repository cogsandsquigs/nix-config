{
    flake.modules.homeManager."develop/languages/python" = { pkgs, ... }: {
        home.packages =
            with pkgs;
            [
                uv
                ty
                ruff

                (lib.hiPrio python3)

                jupyter # Notebooks, focused on python but there can be more
            ]
            ++ (with pkgs.python314Packages; [
                ipykernel # Jupyter kernel for python

                # Common packages used with python/jupyter
                matplotlib
                scikit-learn
                numpy
                pandas
            ]);

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
