# Desktop apps that install more reliably via Homebrew than nixpkgs on macOS.
{
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.desktopApps.enable =
        tools.opt.mkDisabled "GUI apps via Homebrew (WhatsApp, Firefox)";

    config = lib.mkIf config.my.sys.desktopApps.enable {
        homebrew = {
            casks = [
                "whatsapp" # Updated more freq. than whatsapp-for-mac nix
                "firefox"
                "ungoogled-chromium"
                #"google-drive" # Google drive GUI client
            ];
        };
    };
}
