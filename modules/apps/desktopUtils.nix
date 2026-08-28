# Personal GUI applications, that come as utilities.
#
# Unlike in `desktopApps.nix`, `desktopUtils.nix` are utilities -- the equivalent of `tree`, `jq`,
# or `cat` but for desktop. e.g.: `caffeine` for MacOS
{

    home =
        {
            tools,
            lib,
            config,
            ...
        }:
        {
            options.my.user.apps.desktopUtils.enable =
                tools.opt.mkEnabled "GUI apps via Homebrew that are utilities.";

            config = lib.mkIf config.my.user.apps.desktopUtils.enable {
                # TODO: ...
            };
        };

    darwin =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.apps.desktopUtils.enable = tools.opt.mkFollowsUsers config [
                "apps"
                "desktopUtils"
            ] "GUI apps via Homebrew that are utilities.";

            config = lib.mkIf config.my.sys.apps.desktopUtils.enable {
                homebrew = {
                    casks = [
                        "caffeine" # Keeps MacOS awake
                    ];

                    masApps = {
                        Amphetamine = 937984704;
                    };
                };
            };
        };
}
