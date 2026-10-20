{
    flake.modules.homeManager."develop/languages/julia" =
        { pkgs, lib, ... }:
        let
            julia = pkgs.julia-bin;

            # Necessary for installing Julia Jupyter notebook kernel
            kernelJson = builtins.toJSON {
                display_name = "Julia";
                language = "julia";
                argv = [
                    "${julia}/bin/julia"
                    "-i"
                    "--color=yes"
                    "--project=@."
                    "-e"
                    "import IJulia; IJulia.run_kernel()"
                    "{connection_file}"
                ];
            };
        in
        {
            home.packages = [ julia ];

            # Install julia jupyter kernel for darwin...
            home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
                "Library/Jupyter/kernels/julia/kernel.json".text = kernelJson;
            };

            # Install julia jupyter kernel for nixos...
            xdg.dataFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
                "jupyter/kernels/julia/kernel.json".text = kernelJson;
            };

            # Set up editor
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
