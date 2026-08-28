let
    conf = _: {
        environment.enableAllTerminfo = true;
        services.openssh.enable = true;
    };

in
{
    nixos = inputs: (conf inputs); # // { services.openssh.settings.PasswordAuthentication = false; };
    darwin = inputs: (conf inputs); # // { services.openssh.extraConfig = "PasswordAuthentication no"; };
}
