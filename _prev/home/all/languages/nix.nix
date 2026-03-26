{ pkgs, ... }:
{

    home.packages = with pkgs; [
        nixfmt # Official/default formatter
        nixd # Unofficial-official community Nix LSP
        nil # Nix LSP, backup (essentially) as it's kinda worse
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
    ];
}
