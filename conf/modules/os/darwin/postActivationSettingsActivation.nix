{
    darwin =
        { host, ... }:
        let
            inherit (host) primaryUser;
        in
        {
            # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
            system.activationScripts = {
                postActivation.text = ''
                    # activateSettings -u will reload the settings from the database and apply them
                    # to the current session, so we do not need to logout and login again to make
                    # the changes take effect. We do `sudo -u ${primaryUser}` to run the command as
                    # the user.
                    sudo -u ${primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
                '';
            };
        };
}
