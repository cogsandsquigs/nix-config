# The nixpkgs `overlays` list, in one place. A function of `inputs`, and `_`-prefixed to stay out of the
# registry, for the same reason ./_nixpkgs-config.nix is: its second reader is outside the module system.
# tools/default.nix instantiates `pkgs` directly for a standalone home-manager host, so an overlay applied
# only in modules/os/nixpkgs.nix would silently not exist there.
inputs: [
    # balenaEtcher, from a flake rather than nixpkgs (no nixpkgs package). Its own overlay, not a
    # hand-written one over `packages.<system>`, so the attribute name and its build stay upstream's call.
    # Linux only upstream; overlay attributes are lazy, so a darwin host that never asks for it never
    # evaluates the missing output.
    inputs.balena-etcher.overlays.default
]
