# Development environments and languages tools (formatters, LSPs, etc.)
#
# `dev` is a GROUP: this file declares the master `my.user.dev.enable` (core, on today); each sub
# (ide/direnv/containers/langs/editors) owns its own leaf that defaults to the master's value
# (`tools.opt.mkRiding`), so flipping the master flips the whole group, but any sub can be carved out.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    imports = [
        ./ide.nix
        ./direnv.nix
        ./containers.nix
        ./ldap.nix

        ./editor
        ./langs
        ./ai
    ];

    options.my.user.dev.enable = tools.opt.mkEnabled "dev toolchain (editors, langs, containers, …)";

    config = lib.mkIf config.my.user.dev.enable {
        home.packages = with pkgs; [
            # Benchmarking
            hyperfine

            # API querying/development
            postman
        ];
    };
}
