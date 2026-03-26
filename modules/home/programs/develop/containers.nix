{ ... }:
{
    flake.modules.homeManager.containers =
        { pkgs, ... }:
        {
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
                            #colima
                            #lima
                            #lima-additional-guestagents
                        ]
                    else
                        [ ]
                );
        };
}
