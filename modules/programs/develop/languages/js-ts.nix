{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                nodejs
                bun

                typescript-language-server # JS/TS langserv
                prettierd
            ];
        };
}
