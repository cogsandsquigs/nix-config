# nvm -- Node Version Manager, for a project that pins a node version imperatively. Sits beside the
# nixpkgs `nodejs` that `dev.langs` installs rather than replacing it.
#
# The tool is declarative, its payload is not: nvm.sh comes from the store, pinned below, while the node
# versions it manages stay under $NVM_DIR in $HOME. Sourcing it from a read-only store path works because
# it never reads its own location and writes only under $NVM_DIR, which it creates itself.
#
# Opt-in rather than riding `dev`: nvm downloads prebuilt glibc binaries from nodejs.org, so it is only
# sound where the host has an FHS loader -- a distro Linux or macOS, and NixOS only behind nix-ld.
#
# `--no-use` in all three shells. In bash and zsh it makes startup free (measured 0.00s against 0.14s for
# a full source) and leaves PATH alone, so `node` stays nixpkgs' until `nvm use` says otherwise. In the
# fish wrapper it is load-bearing: without it every call re-applies the `default` alias and clobbers an
# earlier `nvm use`.
#
# fish has no nvm support, so `nvm` there is a function running the real thing through `bass`. Same
# reasoning as the .env loader in modules/shell/env.nix -- one bash implementation, not a fish-shaped
# second one.
{
    home =
        {
            pkgs,
            lib,
            config,
            options,
            tools,
            ...
        }:
        let
            cfg = config.my.user.dev.nvm;

            nvm = pkgs.fetchFromGitHub {
                owner = "nvm-sh";
                repo = "nvm";
                rev = "v0.40.6";
                hash = "sha256-60diMTawrIlyB29GrYcRuv5RBawGxpW82FHYWmHQgbg=";
            };

            dir = "$HOME/${cfg.dir}";

            # One string for both shells: nvm's bash_completion guards on ZSH_VERSION itself.
            posixInit = ''
                export NVM_DIR="${dir}"
                . ${nvm}/nvm.sh --no-use
                . ${nvm}/bash_completion
            '';
        in
        {
            options.my.user.dev.nvm = {
                enable = tools.opt.mkDisabled ''
                    Whether to wire nvm into fish, bash and zsh. The node builds it downloads are
                    prebuilt FHS binaries, so this belongs to a host with a distro loader, not to
                    every machine that wants the dev toolchain.
                '';

                dir = tools.opt.mkStr ".nvm" ''
                    $NVM_DIR, relative to the home directory. Holds the installed node versions, the
                    alias table and nvm's download cache -- the imperative half of this feature. nvm
                    creates it on the first install, so nothing here has to.
                '';
            };

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.nvm.enable;
                        dependency = options.my.user.shell.enable;
                        because = "the fish `nvm` function runs through `bass`, which that feature installs";
                    })
                ];

                warnings = lib.optional (pkgs.stdenv.hostPlatform.isLinux && !config.targets.genericLinux.enable) ''
                    my.user.dev.nvm.enable is set on a Linux host that does not set
                    targets.genericLinux.enable, which reads as NixOS. The node builds nvm downloads
                    need an FHS loader; without programs.nix-ld they install and then fail to execute.
                '';

                # `dev.nvm` sorts before `shell.env`, which prepends the nix profile paths right here.
                programs.bash.initExtra = lib.mkAfter posixInit;
                programs.zsh.initContent = lib.mkAfter posixInit;

                programs.fish = {
                    shellInit = ''set -gx NVM_DIR "${dir}"'';

                    functions.nvm = {
                        description = "Node Version Manager, run through bass";
                        body = "bass source ${nvm}/nvm.sh --no-use ';' nvm $argv";
                    };
                };
            };
        };
}
