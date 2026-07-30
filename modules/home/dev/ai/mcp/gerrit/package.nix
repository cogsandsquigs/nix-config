# GerritCodeReview/gerrit-mcp-server as a stdio launcher. Wired up by ./default.nix.
#
# Source tree, not a wheel: no console script, and `main.py` imports siblings as `gerrit_mcp_server.*`
# — hence PYTHONPATH at the repo root. Declared `uvicorn`/`websockets` deps are dead. Shells out to
# `curl` per request.
{
    lib,
    applyPatches,
    fetchFromGitHub,
    writeShellApplication,
    python3,
    curl,
    jq,
    coreutils,
}:
let
    src = applyPatches {
        src = fetchFromGitHub {
            owner = "GerritCodeReview";
            repo = "gerrit-mcp-server";
            rev = "430aa3589bfb784f63912875016fc81b56bfb8f5";
            hash = "sha256-Zc5nbgYBwWfQ//wAh4L5Y/7K0c3EM4C0QpSzwDAuJzM=";
        };

        # --replace-fail: an unmatched pattern would build fine, then fail at the first tool call.
        #
        # 1. Upstream logs every curl call to <repo root>/server.log — read-only store, so every tool
        #    call dies with EROFS. Honour $GERRIT_MCP_LOG instead.
        # 2. `curl --user user:token` leaks the token to world-readable /proc/<pid>/cmdline and, via
        #    that log, to disk. Read it from a 0600 netrc: no argv, no log.
        postPatch = ''
            substituteInPlace gerrit_mcp_server/main.py \
                --replace-fail \
                    'LOG_FILE_PATH = SERVER_ROOT_PATH / "server.log"' \
                    'LOG_FILE_PATH = Path(os.environ.get("GERRIT_MCP_LOG", str(SERVER_ROOT_PATH / "server.log")))'

            substituteInPlace gerrit_mcp_server/gerrit_auth.py \
                --replace-fail \
                    'return ["curl", "--user", f"{username}:{auth_token}", "-L"]' \
                    'return ["curl", "--netrc-file", os.environ["GERRIT_MCP_NETRC"], "-L"]'
        '';
    };

    python = python3.withPackages (ps: [ ps.mcp ]);
in
writeShellApplication {
    name = "gerrit-mcp";

    runtimeInputs = [
        python
        curl # the server shells out to curl for every Gerrit request
        jq # builds the config JSON: escapes a password containing " or \
        coreutils
    ];

    meta = {
        description = "Gerrit MCP server (stdio) with credentials taken from the environment";
        homepage = "https://gerrit.googlesource.com/gerrit-mcp-server/";
        license = lib.licenses.asl20;
    };

    # Claude Code expands the `${GERRIT_*}` refs in its MCP config before spawning us (see
    # ../default.nix). Upstream wants a JSON config file, so translate at launch — nothing in the
    # store.
    text = ''
        for var in GERRIT_HOST GERRIT_USERNAME GERRIT_PASSWORD; do
            if [ -z "''${!var:-}" ]; then
                echo "gerrit-mcp: $var is unset or empty. Set it in your .env, then restart the client" >&2
                echo "gerrit-mcp: (a client launched outside a shell never sourced .env — that is the usual cause)" >&2
                exit 1
            fi
        done

        # Upstream builds "https://<external_url>/a/..." itself, so it wants a bare host.
        host="''${GERRIT_HOST#http://}"
        host="''${host#https://}"
        host="''${host%/}"

        # Both files hold credentials: private dir, 0600, tmpfs where available (cleared at logout).
        # Written via mv so a concurrent client can't read a half-written file.
        runtime_dir="''${XDG_RUNTIME_DIR:-$(mktemp -d)}/gerrit-mcp"
        mkdir -p "$runtime_dir"
        chmod 700 "$runtime_dir"
        umask 077

        config="$runtime_dir/config.json"
        netrc="$runtime_dir/netrc"
        url="https://$host"

        # auth_token is a placeholder — upstream requires the field, but the patched path reads the
        # real token from the netrc below.
        jq -n --arg url "$url" --arg host "$host" --arg user "$GERRIT_USERNAME" '{
            default_gerrit_base_url: $url,
            gerrit_hosts: [
                {
                    name: $host,
                    external_url: $url,
                    authentication: {
                        type: "http_basic",
                        username: $user,
                        auth_token: "unused-see-GERRIT_MCP_NETRC"
                    }
                }
            ]
        }' >"$config.tmp"
        mv -f "$config.tmp" "$config"

        printf 'machine %s login %s password %s\n' "$host" "$GERRIT_USERNAME" "$GERRIT_PASSWORD" >"$netrc.tmp"
        mv -f "$netrc.tmp" "$netrc"

        log_file="''${XDG_STATE_HOME:-$HOME/.local/state}/gerrit-mcp/server.log"
        mkdir -p "$(dirname "$log_file")"

        export GERRIT_CONFIG_PATH="$config"
        export GERRIT_MCP_NETRC="$netrc"
        export GERRIT_MCP_LOG="$log_file"
        export PYTHONPATH=${src}

        exec python ${src}/gerrit_mcp_server/main.py stdio
    '';
}
