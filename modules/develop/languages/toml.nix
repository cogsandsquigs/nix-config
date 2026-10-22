{
    flake.modules.homeManager."develop/languages/toml" = { pkgs, ... }: {
        home.packages = with pkgs; [ taplo ];

        programs.helix = {
            languages = {
                language = [
                    {
                        name = "toml";
                        auto-format = true;
                        language-server = [ "taplo" ];
                        formatter = {
                            command = "taplo";
                            args = [
                                "fmt"
                                "-o=align_entries=true"
                                "-o=align-comments"
                                "-o=allowed_blank_lines=1"
                                "-o=indent_entries=true"
                                "-o=indent_tables=true"
                                "-o=indent_string=    "
                                "-o=reorder_arrays=false"
                                "-o=reorder_keys=true"
                                "-"
                            ];
                        };
                    }
                ];

                language-server.taplo = {
                    cmd = [
                        "taplo"
                        "lsp"
                        "stdio"
                    ];
                };
            };
        };
    };
}
