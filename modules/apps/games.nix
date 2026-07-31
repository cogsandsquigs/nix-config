# Games, on every class that has any.
#
# The three halves install different things because the platforms do: nixpkgs has the launchers on all
# of them, NixOS has Steam natively, and nix-darwin cannot manage Steam at all so macOS goes through
# Homebrew casks.
#
# No shared `options` block: the home half owns `my.user.apps.games` and the system halves own
# `my.sys.apps.games`, so a shared block would declare each scope's option on classes that cannot read it.
let
    # Both system halves declare the same option, so they describe it identically. Declared twice with
    # two descriptions, the class you happened to evaluate decided the documentation.
    sysEnable =
        config: tools:
        tools.opt.mkFollowsUsers config [
            "apps"
            "games"
        ] "games at the system level (Steam natively on NixOS, Homebrew casks on macOS)";
in
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.apps.games.enable =
                tools.opt.mkDisabled "games (Minecraft via Prism, KSP via CKAN, ...)";

            config = lib.mkIf config.my.user.apps.games.enable {
                home.packages = with pkgs; [
                    # Minecraft
                    prismlauncher # NOTE: wrapped ver. has issue w/ extra-cmake-modules not supporting macos

                    # Mod manager/launcher for KSP
                    ckan

                    # Celeste mod loader
                    #olympus # NOTE: for some reason not supported on nix aarch64-darwin (?)
                ];
            };
        };

    nixos =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.apps.games.enable = sysEnable config tools;

            config = lib.mkIf config.my.sys.apps.games.enable {
                programs.steam = {
                    enable = true;
                };
            };
        };

    darwin =
        {
            lib,
            config,
            tools,
            pkgs,
            ...
        }:
        {
            options.my.sys.apps.games.enable = sysEnable config tools;

            config = lib.mkIf config.my.sys.apps.games.enable {
                environment.systemPackages = [ pkgs.p7zip ]; # required for heroic winetricks for some reason?

                homebrew = {
                    # All 2 below required for heroic winetricks for some reason?
                    brews = [
                        "zenity"
                        "cabextract"
                    ];

                    casks = [
                        "steam"
                        "olympus" # Celeste mod loader # NOTE: for some reason not supported on nix aarch-64
                        "porting-kit" # Windows -> Mac games
                        # "aaf2tbz/tap/metalsharp" # Windows -> Mac games (via Game Porting ToolKit)
                        "heroic" # Windows -> Mac games
                    ];
                };
            };
        };
}
