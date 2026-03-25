let
    username = "cogs";
in
{
    flake.modules.nixos.${username} = {
        users.users.${username} = {
            isNormalUser = true;
            extraGroups = [
                "wheel"
                "sudo"
            ];
        };
    };

    flake.modules.darwin.${username} = {
        system.primaryUser = username; # note that configuring a user is different on MacOS than on NixOS.
        users.users."${username}".home = "/Users/${username}";
        homebrew.user = username;

        # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
        activationScripts.postActivation.text = ''
            # activateSettings -u will reload the settings from the database and apply them to the current session,
            # so we do not need to logout and login again to make the changes take effect.
            # We do `sudo -u ${username}` to run the command as the user
            sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';
    };

    flake.modules.homeManager.${username} =
        { pkgs, lib, ... }:
        {
            home.username = lib.mkDefault username;
            home.homeDirectory = lib.mkDefault (
                if pkgs.stdenvNoCC.isDarwin then "/Users/${username}" else "/home/${username}"
            );
            home.stateVersion = lib.mkDefault "25.05";
        };
}
