# The nixpkgs `config` attribute, in one place. Plain data, and `_`-prefixed to stay out of the registry,
# because its second reader is outside the module system: tools/default.nix instantiates `pkgs` directly
# for a standalone home-manager host. Kept in two places, that host could disagree with the system hosts
# about allowUnfree.
{
    allowUnfree = true;
    qt.enable = true;
}
