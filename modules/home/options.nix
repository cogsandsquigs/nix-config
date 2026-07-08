# Custom options for this config, under the `my.*` namespace. These are the knobs a host flips
# to differ from the shared defaults without editing the shared modules — keeping per-host
# tweaks in one obvious place (see hosts/work-desktop for a worked example).
{ lib, ... }:
let
    inherit (lib) mkOption types;
in
{
    options.my = {
        # Absolute path to this flake's working tree on the host. The shell aliases
        # (rebuild/upgrade/…) point here. Personal system hosts keep the repo at /etc/nix;
        # the standalone work box keeps it at ~/.config/nix.
        flakeDir = mkOption {
            type = types.str;
            default = "/etc/nix";
            example = "/home/ipratt/.config/nix";
            description = "Absolute path to this flake's checkout on the host.";
        };

        # Git identity + signing. Broken out so a host can override just these (e.g. a work
        # box using a work email, with signing off until a work key is imported) without
        # touching the shared modules/home/git.nix.
        git = {
            userName = mkOption {
                type = types.str;
                default = "Ian Pratt";
                description = "Value for git user.name.";
            };
            email = mkOption {
                type = types.str;
                default = "ianjdpratt@gmail.com";
                description = "Value for git user.email.";
            };
            signingKey = mkOption {
                type = types.nullOr types.str;
                default = "E0DB58169CA551AA!";
                description = "GPG signing key id (null to leave unset).";
            };
            signByDefault = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to GPG-sign every commit by default.";
            };
        };
    };
}
