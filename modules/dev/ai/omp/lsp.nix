# Language servers for OMP, translated from the same `langs/` toolchains helix reads.
#
# OMP reads a per-user `~/.omp/agent/lsp.json` -- the highest-precedence user source and one
# home-manager can write declaratively. Unlike Claude, one extension can bind many servers (nixd + nil
# alongside an efm linter), so every server is imported rather than just the primary, and the
# `only-features = [ "diagnostics" ]` split becomes `isLinter`, which keeps linters out of
# type-intelligence work.
{
    home =
        {
            lib,
            tools,
            config,
            options,
            ...
        }:
        let
            cfg = config.my.user.dev.ai.omp.lsp;

            # Already resolved in modules/dev/langs.nix. This file only reshapes it into OMP's schema.
            toolchains = config.my.user.dev.langs.resolved;

            # One entry per (language, server) pair OMP can reach. Routing is by file extension or exact
            # filename, so a language with no extensions (go.mod, docker-compose) has nothing to bind.
            refs = lib.concatMap (
                t:
                lib.concatMap (
                    name:
                    let
                        def = t.languages.${name};
                        keys = def.extensions;
                    in
                    if def.servers == [ ] || keys == [ ] then
                        [ ]
                    else
                        map (srv: {
                            inherit (srv)
                                name
                                command
                                args
                                config
                                ;
                            linter = srv.only-features == [ "diagnostics" ];
                            inherit keys;
                            inherit (def) roots;
                        }) def.servers
                ) (lib.attrNames t.languages)
            ) toolchains;

            toServer =
                name:
                let
                    mine = lib.filter (r: r.name == name) refs;
                    first = lib.head mine;
                in
                lib.nameValuePair name (
                    {
                        command = first.command;
                        fileTypes = lib.unique (lib.concatMap (r: r.keys) mine);
                        # OMP hands every server the agent's cwd as its workspace root, so `[ "." ]`
                        # marks any launch directory eligible; a language's own `roots`, once set,
                        # narrows that to real project markers.
                        rootMarkers =
                            let
                                roots = lib.unique (lib.concatMap (r: r.roots) mine);
                            in
                            if roots == [ ] then [ "." ] else roots;
                    }
                    // lib.optionalAttrs (first.args != [ ]) { args = first.args; }
                    // lib.optionalAttrs first.linter { isLinter = true; }
                    # Servers disagree on which channel carries settings (rust-analyzer reads
                    # initializationOptions, gopls answers workspace/configuration, jdtls only the
                    # latter), so mirror helix and send `config` down both; OMP names them `initOptions`
                    # and `settings`.
                    // lib.optionalAttrs (first.config != { }) {
                        initOptions = first.config;
                        settings = first.config;
                    }
                );
        in
        {
            options.my.user.dev.ai.omp.lsp.enable = tools.opt.mkRiding (
                config.my.user.dev.ai.omp.enable && config.my.user.dev.langs.enable
            ) "language servers for OMP, from the langs/ toolchains";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.omp.lsp.enable;
                        dependency = options.my.user.dev.ai.omp.enable;
                    })
                ];

                # OMP only reads its LSP list (unlike config.yml, which it rewrites at runtime), so a
                # store symlink here is safe.
                home.file.".omp/agent/lsp.json".text = builtins.toJSON {
                    servers = lib.listToAttrs (map toServer (lib.unique (map (r: r.name) refs)));
                };
            };
        };
}
