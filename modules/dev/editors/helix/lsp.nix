{
    home =
        { lib, config, ... }:

        let

            # Translate lang toolchains -> Helix language config. Every fallback rule (which servers serve
            # a language, which formatter it ends up with, where a cmd list splits) is already applied in
            # modules/dev/langs.nix -- this file only reshapes the result into helix's schema.
            toolchains = config.my.user.dev.langs.resolved;

            toLsp =
                lsp:
                lib.nameValuePair lsp.name (
                    {
                        inherit (lsp) command;
                    }
                    // lib.optionalAttrs (lsp.args != [ ]) { inherit (lsp) args; }
                    // lib.optionalAttrs (lsp.config != { }) { inherit (lsp) config; }
                );

            toLang =
                t: langName: def:
                let
                    lsps = def.servers;
                in
                {
                    name = langName;
                }
                //
                    # NOTE: need 2 be in parens since these are the "actual" language options, which we
                    # modify w/ editor-specific config
                    (
                        {
                            auto-format = true;
                            indent = {
                                tab-width = 4;
                                unit = "    ";
                            };
                        }
                        # NOTE: Must come AFTER -- the `//` operator updates the prev (above) attrset with
                        # the next (below) one. Defaults to `{ }`, so no presence test is needed.
                        // t.editor-specific.helix
                    )
                // lib.optionalAttrs (lsps != [ ]) {
                    language-servers =
                        let
                            hasFlags = builtins.any (l: l.only-features != [ ] || l.except-features != [ ]) lsps;
                            toEntry =
                                l:
                                if !hasFlags then
                                    l.name
                                else
                                    {
                                        inherit (l) name;
                                    }
                                    // lib.optionalAttrs (l.only-features != [ ]) { inherit (l) only-features; }
                                    // lib.optionalAttrs (l.except-features != [ ]) { inherit (l) except-features; };
                        in
                        map toEntry lsps;
                }
                // lib.optionalAttrs (def.formatter != null) { inherit (def) formatter; }
                // lib.optionalAttrs (def.roots != [ ]) { inherit (def) roots; };

            specLsps = lib.listToAttrs (lib.concatMap (t: map toLsp t.lsp) toolchains);
            specLangs = lib.concatMap (t: lib.mapAttrsToList (toLang t) t.languages) toolchains;

        in
        {

            config = lib.mkIf config.my.user.dev.editors.helix.enable {
                programs.helix = {
                    languages = {
                        language-server = specLsps;
                        language = specLangs;
                    };
                };
            };
        };
}
