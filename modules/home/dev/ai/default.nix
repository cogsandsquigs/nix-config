{
    lib,
    tools,
    config,
    pkgs,
    ...
}:
{
    options.my.user.dev.ai.enable =
        tools.opt.mkRiding config.my.user.dev.enable "AI tooling / coding agents (for work)";

    config = lib.mkIf config.my.user.dev.ai.enable {

        home.packages = with pkgs; [
            # AI stuffs (work *blech*)
            claude-code
            claude-monitor

            # Token reducer
            rtk
        ];

        programs.claude-code = {
            enable = true;
            context = ./context.md;
            skills = ./skills;
        };
    };
}
