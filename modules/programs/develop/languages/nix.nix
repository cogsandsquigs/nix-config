{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                nixfmt # Official/default formatter
                nixd # Unofficial-official community Nix LSP
                nil # Nix LSP, backup (essentially) as it's kinda worse
            ];
        };
}
