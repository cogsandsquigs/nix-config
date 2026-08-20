# The nixpkgs `overlays` list. Two readers, like ./_nixpkgs-config.nix. modules/os/nixpkgs.nix
# covers the system hosts. tools/default.nix covers the standalone home-manager host, which builds
# `pkgs` outside the module system and would otherwise get no overlays at all.
inputs: [
    inputs.balena-etcher.overlays.default # balenaEtcher, linux only. No nixpkgs package.
    inputs.omp-bin-overlay.overlays.default # OMP overlay bin.
]
