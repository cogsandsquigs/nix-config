# Apps relating to music, creating it, etc.
{

    home =
        {
            tools,
            lib,
            config,
            ...
        }:
        {
            options.my.user.apps.music.enable = tools.opt.mkEnabled "Apps that make / produce music.";

            config = lib.mkIf config.my.user.apps.music.enable {
                # TODO: ...
            };
        };
}
