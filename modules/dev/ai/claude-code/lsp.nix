# Language servers for Claude Code, translated from the same `langs/` toolchains helix reads.
#
# home-manager turns `lspServers` into a `.lsp.json` inside a generated plugin and passes it to the
# `claude` wrapper with `--plugin-dir` -- the same path the MCP servers already take, so nothing here
# needs enabling by hand.
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
            cfg = config.my.user.dev.ai.claude-code.lsp;

            # Already resolved in modules/dev/langs.nix: which servers serve a language, and where each
            # command splits. This file only reshapes that into Claude's schema.
            toolchains = config.my.user.dev.langs.resolved;

            startupTimeout = 30000;
            maxRestarts = 3;

            bindings = lib.concatMap (
                t:
                lib.concatMap (
                    name:
                    let
                        def = t.languages.${name};
                        # Claude binds one server per extension: the first registered wins and the rest
                        # never start. `servers` is ordered primary-first, so its head is the one worth
                        # declaring.
                        inherit (def) servers;
                        # Extensions only, and whole filenames are not an option, measured not assumed: a
                        # dotless key (go.mod) rejects the entire .lsp.json and every server in it, while a
                        # dot-led one (.bashrc) is accepted but never matches, since Claude reads an empty
                        # file type off a name with no second dot.
                        keys = def.extensions;
                    in
                    lib.optional (servers != [ ] && keys != [ ]) {
                        server = lib.head servers;
                        inherit (def) id;
                        inherit keys;
                    }
                ) (lib.attrNames t.languages)
            ) toolchains;

            toServer =
                name:
                let
                    mine = lib.filter (b: b.server.name == name) bindings;
                    srv = (lib.head mine).server;
                in
                lib.nameValuePair name (
                    {
                        inherit (srv) command;
                        extensionToLanguage = lib.listToAttrs (
                            lib.concatMap (b: map (k: lib.nameValuePair k b.id) b.keys) mine
                        );
                        inherit startupTimeout maxRestarts;
                    }
                    // lib.optionalAttrs (srv.args != [ ]) { inherit (srv) args; }
                    # Servers disagree on which channel carries settings: rust-analyzer reads
                    # initializationOptions, gopls answers workspace/configuration, jdtls only the latter.
                    # Sending both matches what helix does with one `config`.
                    // lib.optionalAttrs (srv.config != { }) {
                        initializationOptions = srv.config;
                        settings = srv.config;
                    }
                );

            servers = lib.listToAttrs (map toServer (lib.unique (map (b: b.server.name) bindings)));

            # extension/filename -> the distinct "<server> as <id>" claims on it. More than one is a real
            # conflict. The same claim twice is not, since helix lists some names as both a type and a glob.
            claims = lib.foldl' (
                acc: b:
                lib.foldl' (
                    a: k: a // { ${k} = lib.unique ((a.${k} or [ ]) ++ [ "${b.server.name} as ${b.id}" ]); }
                ) acc b.keys
            ) { } bindings;

            conflicts = lib.filterAttrs (_: claimants: lib.length claimants > 1) claims;
        in
        {
            options.my.user.dev.ai.claude-code.lsp.enable = tools.opt.mkRiding (
                config.my.user.dev.ai.claude-code.enable && config.my.user.dev.langs.enable
            ) "language servers for Claude Code, from the langs/ toolchains";

            config = lib.mkIf cfg.enable {
                assertions = [
                    {
                        assertion = conflicts == { };
                        message =
                            "Claude binds one server per extension, so these would silently drop a claimant: "
                            + lib.concatStringsSep "; " (
                                lib.mapAttrsToList (k: c: "${k} claimed by ${lib.concatStringsSep " and " c}") conflicts
                            );
                    }
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.claude-code.lsp.enable;
                        dependency = options.my.user.dev.ai.claude-code.enable;
                    })
                ];

                programs.claude-code.lspServers = servers;
            };
        };
}
