# sops-nix secret management for the HOME (per-user) scope.
#
# Pulls in the sops-nix home-manager module and points it at this user's age key. Inert until a user
# unit declares a secret with `tools.secrets.declare` and feeds its `tools.secrets.path` into a
# feature's `tools.opt.mkSecretPath` hole (see the helpers in tools/opt.nix).
#
# The sops-nix module is imported unconditionally (imports can't be option-gated, and it's inert
# without secrets) — mirroring the system-side `modules/system/{darwin,nixos}/secrets.nix`.
{
    inputs,
    pkgs,
    lib,
    config,
    ...
}:
{
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    # Private age key per user, at a fixed path (this machine's key for this user — distinct per
    # machine, never copied). Gitignored, never committed. Bootstrap once, on this machine:
    # `age-keygen -o /etc/nix/age/<user>`, then add its public key to secrets/.sops.yaml as
    # "<user>@<host>".
    sops.age.keyFile = "/etc/nix/age/${config.home.username}";

    # On darwin sops-nix's activation does its own early `launchctl bootout` (unload) then `bootstrap`
    # (load) of its launchd-agent plist — but home-manager only installs that plist later, in
    # `setupLaunchAgents`. So on the FIRST activation the plist isn't in place yet and bootstrap dies
    # with "Bootstrap failed: 5: Input/output error" (launchctl's generic error for a missing plist
    # path). Install the plist up front so sops-nix's bootstrap finds it; setupLaunchAgents re-installs
    # it later, harmlessly.
    #
    # NOTE: the "Boot-out failed: 3: No such process" line printed just before is NOT this bug — that's
    # the bootout finding no agent loaded yet (normal whenever nothing is loaded: first run, or post-
    # reboot pre-login). sops-nix ignores it on purpose; only the bootstrap failure aborts activation.
    home.activation.sopsNixInstallAgent = lib.mkIf pkgs.stdenv.isDarwin (
        lib.hm.dag.entryBefore [ "sops-nix" ] ''
            $DRY_RUN_CMD install -Dm444 -T \
                "$newGenPath/LaunchAgents/org.nix-community.home.sops-nix.plist" \
                "$HOME/Library/LaunchAgents/org.nix-community.home.sops-nix.plist"
        ''
    );
}
