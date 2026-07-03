# Extra system packages for a darwin desktop.
{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        pinentry_mac # EZ pinentry for GPG
        appcleaner # For cleaning up rogue `.app`s
    ];
}
