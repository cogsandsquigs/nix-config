# Set of utilities for generating and managing configurations.
#
# NOTE: This is separate from `opt`. `opt` makes options on configuration, while `conf` manages
# configurations as a whole.
{ lib, system }:

{
  # system is baked in at tools construction time (see tools/default.nix mkTools).
  eachOs = nixConf: darwinConf: if lib.strings.hasSuffix "darwin" system then darwinConf else nixConf;
}
