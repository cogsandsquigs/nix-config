# Language configurations for the editor.
# NOTE: This is the Nix equivalent to helix's `languages.toml` file
# Remaining entries (c, cpp, docker-compose, pest, scala) pending migration to langs/*.nix specs.
{ lib, config, ... }: {
    config = lib.mkIf config.my.user.dev.editors.helix.enable {
        programs.helix.languages.language = [
            {
                name = "c";
                auto-format = true;
                indent = {
                    tab-width = 4;
                    unit = "    ";
                };
            }
            {
                name = "cpp";
                auto-format = true;
                indent = {
                    tab-width = 4;
                    unit = "    ";
                };
            }
            {
                name = "docker-compose";
                auto-format = true;
                indent = {
                    tab-width = 4;
                    unit = "    ";
                };
                formatter = {
                    command = "prettierd";
                    args = [ "%{buffer_name}" ];
                };
            }
            {
                name = "pest";
                auto-format = true;
                indent = {
                    tab-width = 4;
                    unit = "    ";
                };
                # NOTE: No need to configure, pest-language-server is default
                # NOTE: LSP comes with formatter, no need for formatter!
                language-servers = [ "pest-language-server" ];
            }
            {
                name = "scala";
                auto-format = true;
                # NOTE: The default language server is `metals`, which automatically formats
                # code as well --- no need to specify a formatter. It is faster than calling
                # `scalafmt` from the command-line as well. Any formatting options are specified
                # in a `.scalafmt.conf` file (HOCOL syntax) --- so no need to pass cmd-line
                # options for it unless wanting to configure LSP itself.
            }
        ];
    };
}
