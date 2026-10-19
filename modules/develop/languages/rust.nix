{
    flake.modules.homeManager."develop/languages/rust" = { pkgs, ... }: {
        home.packages = with pkgs; [
            rustup

            # rustup ships a `rust-analyzer` shim that dispatches to a component it does not
            # install, so higher priority than the shim to win collision.
            (lib.hiPrio rust-analyzer)

            cargo-watch
            cargo-workspaces
            cargo-license
            trunk
        ];

        # Configuring helix for this language
        programs.helix = {
            languages = {
                language = [
                    {
                        name = "rust";
                        auto-format = true;
                        formatter = {
                            command = "rustfmt";
                        };
                        language-servers = [ "rust-analyzer" ];
                    }
                ];

                language-server.rust-analyzer = {
                    cmd = [ "rust-analyzer" ];
                    config.rust-analyzer = {
                        check.command = "clippy";
                        procMacro.enable = true;
                        cargo.buildScripts.enable = true;
                    };

                };
            };
        };
    };

}
