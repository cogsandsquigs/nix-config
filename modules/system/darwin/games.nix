# NOTE: currently nix-darwin can't manage steam, so we just use homebrew to install it for now.
{
    lib,
    config,
    tools,
    pkgs,
    ...
}:
{
    options.my.sys.games.enable =
        tools.opt.mkDisabled "games (Steam, Olympus, Porting Kit via Homebrew)";

    config = lib.mkIf config.my.sys.games.enable {
        environment.systemPackages = with pkgs; [
            # ALl 3 below required for heroic winetricks for some reason?
            p7zip-rar
            zenity
            cabextract
        ];

        homebrew = {
            casks = [
                "steam"
                "olympus" # Celeste mod loader # NOTE: for some reason not supported on nix aarch-64
                "porting-kit" # Windows -> Mac games
                # "aaf2tbz/tap/metalsharp" # Windows -> Mac games (via Game Porting ToolKit)
                "heroic" # Windows -> Mac games
            ];
        };
    };
}
