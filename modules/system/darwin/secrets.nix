# agenix secret management (darwin).
{ inputs, pkgs, ... }: {
    imports = [ inputs.agenix.darwinModules.default ];
    environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
