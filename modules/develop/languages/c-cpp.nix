{
    flake.modules.homeManager."develop/languages/c-cpp" = { pkgs, ... }: {
        home.packages = with pkgs; [
            # bear # TODO: fails rn
            compiledb
            cmake
            llvmPackages_21.clang
            llvmPackages_21.clang-unwrapped.python # git-clang-format and other tools
            llvmPackages_21.clang-tools
            pkg-config

            libc
            libcxx
        ];

        # Set up editor
        programs.helix = {
            languages = {
                language = [
                    {
                        name = "c";
                        auto-format = true;
                        formatter = {
                            command = "clang-format";
                        };
                    }
                    {
                        name = "cpp";
                        auto-format = true;
                        formatter = {
                            command = "clang-format";
                        };
                    }
                ];

                language-servers.clangd = {
                    command = "clangd";
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
