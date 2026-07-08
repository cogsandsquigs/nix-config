# System-level user account for the host's primary user (home-manager config lives under
# modules/home). The username comes from the host's id.nix via the `hostId` specialArg.
{ pkgs, hostId, ... }: {
    users.users.${hostId.userName} = {
        description = hostId.userName;
        shell = pkgs.fish;
    };
}
