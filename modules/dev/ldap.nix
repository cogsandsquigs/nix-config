{
    home =
        {
            pkgs,
            tools,
            lib,
            config,
            ...
        }:
        {

            options.my.user.dev.ldap.enable = tools.opt.mkDisabled "LDAP Tools";

            config = lib.mkIf config.my.user.dev.ldap.enable {
                # Linux only: apache-directory-studio has no darwin build in nixpkgs.
                home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.apache-directory-studio ];
            };

        };
}
