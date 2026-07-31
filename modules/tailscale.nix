# Tailscale, via the Homebrew cask.
#
# Its own feature rather than part of a "vpn" grouping. Tailscale is a mesh network for reaching one's
# own machines, so it has a different lifetime from the OpenVPN profiles that used to sit beside it --
# those were abandoned and removed, and bundling the two meant deleting one deleted the other.
#
# darwin only for now. NixOS has `services.tailscale.enable`; add a `nixos` half (renaming this to
# tailscale.nix and keying it by class) when the personal Linux box exists.
{
    darwin =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            _class = "darwin";

            options.my.sys.tailscale.enable = tools.opt.mkDisabled "Tailscale (Homebrew cask)";

            config = lib.mkIf config.my.sys.tailscale.enable { homebrew.casks = [ "tailscale-app" ]; };
        };
}
