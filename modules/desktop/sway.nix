# Sway, and the Wayland session around it.
#
# The system half owns the compositor and the seat. It is short because `programs.sway.enable`
# already pulls in polkit, xwayland, dconf, the wlr + gtk portals, and `services.graphical-desktop`
# -- which is itself where `hardware.graphics`, pipewire (with pulse and alsa), the default fonts
# and the xdg autostart/mime/icon stack come from. What is left is the portal switch, realtime
# scheduling, and a way to log in.
#
# The home half owns `~/.config/sway/config` and nothing else. `package = null` leaves the binary to
# the system wrapper, which is the one carrying the session commands and the seat privileges; a
# second sway installed here would shadow it. That is also why the home half asserts a NixOS host --
# on a standalone home-manager box there is no system half, so this would write a config for a
# compositor nobody installed.
{
    nixos =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.desktop.sway.enable = tools.opt.mkFollowsUsers config [
                "desktop"
                "sway"
            ] "the Wayland session sway runs in (greetd login, portals, realtime scheduling)";

            config = lib.mkIf config.my.sys.desktop.sway.enable {
                programs.sway = {
                    enable = true;
                    wrapperFeatures.gtk = true;
                };

                # `programs.sway` fills in wlr, the gtk portal and the per-interface routing between
                # them, but not the switch that turns the portal service on.
                xdg.portal.enable = true;

                # pipewire arrives with `services.graphical-desktop`; the realtime scheduling it
                # wants does not.
                security.rtkit.enable = true;

                # `--cmd sway` resolves against systemPackages, where `programs.sway` puts the
                # wrapper.
                services.greetd = {
                    enable = true;
                    settings.default_session = {
                        command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd sway";
                        user = "greeter";
                    };
                };
            };
        };

    home =
        {
            pkgs,
            lib,
            config,
            host,
            tools,
            ...
        }:
        let
            cfg = config.my.user.desktop.sway;
        in
        {
            options.my.user.desktop.sway.enable =
                tools.opt.mkDisabled "sway, configured for this user (ghostty, fuzzel, Mod4)";

            config = lib.mkIf cfg.enable {
                assertions = [
                    {
                        assertion = host.class == "nixos";
                        message = "my.user.desktop.sway.enable needs a NixOS host: `package = null` leaves the sway binary to my.sys.desktop.sway, which only a system class declares";
                    }
                    {
                        assertion = config.my.user.cli.terminal.enable;
                        message = "my.user.desktop.sway.enable requires my.user.cli.terminal.enable (ghostty is what Mod+Return opens)";
                    }
                ];

                home.packages = [ pkgs.fuzzel ];

                wayland.windowManager.sway = {
                    enable = true;

                    # Setting this null also turns `checkConfig` off, which is correct: there is no
                    # binary here to validate the config against.
                    package = null;

                    # `programs.sway.xwayland` already provides it.
                    xwayland = false;

                    config = {
                        modifier = "Mod4";
                        terminal = "ghostty";
                        menu = "fuzzel";
                    };
                };
            };
        };
}
