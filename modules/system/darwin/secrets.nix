# sops-nix secret management (darwin).
#
# Only installs the `sops` CLI. There is no `imports = [ sops-nix.darwinModules.sops ]` because every
# secret here is home-scope — the per-user home-manager module (modules/home/secrets.nix) does all the
# decryption. Add the system module here only if you ever declare a SYSTEM-scope secret (root-owned).
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

    config = lib.mkIf config.my.sys.secrets.enable {
        environment.systemPackages = [ pkgs.sops ];
    };
}
