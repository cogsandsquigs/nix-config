# agenix secret management (nixos).
{
    inputs,
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    # The agenix module is imported unconditionally (imports can't be option-gated, and it's inert
    # until a secret is declared). The toggle only governs whether the `agenix` CLI is installed.
    # Defaults true — never accidentally lose secret tooling.
    imports = [ inputs.agenix.nixosModules.default ];

    options.my.sys.secrets.enable =
        tools.opt.mkEnabled "agenix secret management (installs the agenix CLI)";

    config = lib.mkIf config.my.sys.secrets.enable {
        environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
