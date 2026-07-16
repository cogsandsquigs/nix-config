{
    pkgs,
    tools,
    lib,
    config,
    ...
}:
{

    options.my.user.dev.ldap.enable = tools.opt.mkRiding config.my.user.dev.enable "JetBrains IDEA";

    config = lib.mkIf config.my.user.dev.ldap.enable {
        home.packages = (
            if
                # Restriction necessary since apache-directory-studio only works on linux (for nix builds) :/
                pkgs.stdenv.isLinux
            then
                with pkgs; [ apache-apache-directory-studio ]
            else
                [ ]
        );
    };

}
