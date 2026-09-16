let
    conf = _: {
        # environment.enableAllTerminfo = true; # NOTE: Installs pkgs, so pretty heavy if enabled
        services.openssh.enable = true;
    };

in
{
    nixos = inputs: (conf inputs) // { services.openssh.settings.PasswordAuthentication = false; };
    darwin = inputs: (conf inputs) // { services.openssh.extraConfig = "PasswordAuthentication no"; };
}
