let
    conf = _: {
        environment.enableAllTerminfo = true;
        services.openssh.enable = true;
    };

in
{
    nixos = conf // {
        services.openssh.settings.PasswordAuthentication = false;
    };

    darwin = conf // {
        services.openssh.extraConfig = "PasswordAuthentication no";
    };
}
