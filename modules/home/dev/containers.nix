{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.user.dev.containers.enable =
        tools.mkRiding config.my.user.dev.enable "docker + compose (colima/lima on macOS)";

    config = lib.mkIf config.my.user.dev.containers.enable {
        home.packages =
            with pkgs;
            [
                docker
                docker-compose
            ]
            ++ (
                # Container utilities (ez docker on macos)
                if pkgs.stdenv.isDarwin then
                    with pkgs;
                    [
                        colima
                        lima
                        lima-additional-guestagents
                    ]
                else
                    [ ]
            );
    };
}
