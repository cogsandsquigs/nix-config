{
    flake.modules.homeManager."develop/languages/nix" = { pkgs, ... }: {
        home.packages = with pkgs; [
            nixfmt # Official/default formatter (per-file, used by the editor)
            treefmt # Whole-tree formatter (alt) -- driven by ./treefmt.toml; also what `nix fmt` runs
            nixd # Official community Nix LSP
            nil # Nix LSP, live fallback -- see the note on `lsp` below
            statix # Nix linter -- the `lint` gate's checker, surfaced live through efm-langserver below
            efm-langserver
        ];

        programs.helix = {
            languages = {
                language = [
                    {
                        name = "nix";
                        auto-format = true;
                        formatter = {
                            command = "nixfmt";
                            args = [
                                "--width=100"
                                "--indent=4"
                                "--quiet"
                                "--strict"
                                "-"
                            ];
                        };
                        language-servers = [
                            "nixd"
                            "nil"
                        ];
                    }
                ];

                language-server = {
                    nixd = {
                        cmd = [ "nixd" ];
                    };

                    nil = {
                        cmd = [
                            "nil"
                            "--stdio"
                        ];
                        config.nil.flake.autoArchive = true;
                    };
                };
            };
        };
    };
}
