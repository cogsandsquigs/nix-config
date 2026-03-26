# Expands the `base` system to desktop configurations

{ inputs, ... }:
{
    flake.modules.darwin.desktop =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.darwin; [ base ];

            environment.systemPackages = with pkgs; [
                pinentry_mac # EZ pinentry for GPG
                appcleaner # For cleaning up rogue `.app`s
            ];
        };
}
