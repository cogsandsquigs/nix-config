{ pkgs, ... }:
{

  home.packages = with pkgs; [
    alejandra # UN-official formatter (stable, opinionated!)
    nixfmt-rfc-style # Official (!) formatter (but unstable, so proceed with caution!) NOTE: when stabilized, use `nixfmt`
    nil # Nix LSP
    # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
  ];
}
