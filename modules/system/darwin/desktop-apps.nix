# Desktop apps that install more reliably via Homebrew than nixpkgs on macOS.
{ ... }: {
    homebrew = {
        casks = [
            "whatsapp" # Updated more freq. than whatsapp-for-mac nix
            "firefox"
            #"google-drive" # Google drive GUI client
        ];
    };
}
