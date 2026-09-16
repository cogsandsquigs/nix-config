# mattpocock/skills, read by both harnesses and so pinned here rather than under either one.
#
# A fetcher rather than a flake input, so `nix flake update` cannot move third-party agent
# instructions underneath us -- bumping this is a deliberate edit of `rev`, then the hash the build
# reports.
#
# The two consumers want different things from the same fetch. Claude Code takes the repo as a plugin
# and reads `.claude-plugin/plugin.json`, which lists exactly the promoted skills. pi has no manifest
# and discovers every directory holding a SKILL.md, recursively -- pointed at the repo it would also
# load `in-progress/`, `misc/` and `deprecated/`, which upstream keeps out of the plugin on purpose.
# So `promoted` names the two buckets instead. Reading the manifest would track upstream's own
# promotion decisions, but `readFile` on a fetched derivation is import-from-derivation: every
# evaluation, `nix flake check` included, would have to fetch this repo before it could finish.
{ pkgs, ... }:
let
    src = pkgs.fetchFromGitHub {
        owner = "mattpocock";
        repo = "skills";
        rev = "8b78b531ab965735c5dc74f6f7a219e1e37326df";
        hash = "sha256-jsXcMkhu15MxR0zXnLLJeni0q0Aew2UxUSojl6zmOvg=";
    };

    # pi discovers root .md files as skills and warns when they lack a description
    # frontmatter. The bucket README.md files trigger these spurious warnings. Filter
    # them out by building a copy that only contains the subdirectory skills.
    cleaned =
        name:
        pkgs.runCommandLocal "mattpocock-${name}" { } ''
            mkdir -p "$out"
            for d in "${src}/skills/${name}"/*/; do
                ln -sn "$d" "$out/$(basename "$d")"
            done
        '';
in
{
    inherit src;
    promoted = [
        (cleaned "engineering")
        (cleaned "productivity")
    ];
}
