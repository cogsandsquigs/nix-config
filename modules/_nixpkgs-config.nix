# The nixpkgs `config` attribute, in one place.
#
# Not a module -- the leading underscore keeps it out of the registry. It has to be plain data because
# its second reader is outside the module system: a standalone home-manager host has no system layer, so
# tools/default.nix instantiates that host's `pkgs` directly and needs the same values. When these lived
# in two places, the standalone box could quietly disagree with the system hosts about allowUnfree.
{
    allowUnfree = true;
    qt.enable = true;
}
