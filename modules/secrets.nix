# sops-nix secret management.
#
# All decryption is home-scope: the per-user home-manager module does it, and each machine has its own
# age key that is never copied. The two system halves therefore only install the `sops` CLI, and
# neither imports `sops-nix.{nixos,darwin}Modules.sops`. Add the system module to a half only when a
# genuinely root-owned secret appears.
let
    # Both system classes install the same one thing, so they say so once.
    cli =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.secrets.enable =
                tools.opt.mkEnabled "sops secret management (installs the sops CLI)";

            config = lib.mkIf config.my.sys.secrets.enable { environment.systemPackages = [ pkgs.sops ]; };
        };
in
{
    nixos = cli;
    darwin = cli;

    home =
        {
            inputs,
            pkgs,
            lib,
            config,
            ...
        }:
        {
            # Imports cannot be option-gated, and the module is inert without a declared secret.
            imports = [ inputs.sops-nix.homeManagerModules.sops ];

            # Private age key per user, at a fixed path (this machine's key for this user -- distinct
            # per machine, never copied). Gitignored, never committed. Bootstrap once, on this machine:
            # `age-keygen -o /etc/nix/age/<user>`, then add its public key to secrets/.sops.yaml as
            # "<user>@<host>".
            sops.age.keyFile = "/etc/nix/age/${config.home.username}";

            # On darwin sops-nix's activation boots out then bootstraps its own launchd plist, but
            # home-manager installs that plist later, in `setupLaunchAgents`. On a FIRST activation the
            # bootstrap therefore dies with "Bootstrap failed: 5: Input/output error" (launchctl's error
            # for a missing plist). Installing it up front fixes that. setupLaunchAgents re-installs it
            # later, harmlessly.
            #
            # The "Boot-out failed: 3: No such process" line just before is NOT this bug -- that is the
            # bootout finding no agent loaded, normal on a first run or post-reboot, and ignored upstream.
            home.activation.sopsNixInstallAgent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
                lib.hm.dag.entryBefore [ "sops-nix" ] ''
                    $DRY_RUN_CMD install -Dm444 -T \
                        "$newGenPath/LaunchAgents/org.nix-community.home.sops-nix.plist" \
                        "$HOME/Library/LaunchAgents/org.nix-community.home.sops-nix.plist"
                ''
            );
        };
}
