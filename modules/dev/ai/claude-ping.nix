# A cheap Claude request on a weekday schedule, to pin the phase of the rolling 5h usage window.
#
# A window opens on the first message AFTER a reset, never on its own, so the boundaries sit wherever
# the first ping puts them: 05:30 puts them at 10:30 and 15:30, three windows across a 09:00-17:00 day
# instead of two. The later pings are a minute PAST the boundary because one landing at 10:29:59 spends
# quota in the window it meant to replace and opens nothing. Worth ~10% on a heavy day and nothing at
# nominal demand, so: opt-in, and a hedge rather than a throughput win.
{
    home =
        {
            lib,
            tools,
            config,
            pkgs,
            ...
        }:
        let
            cfg = config.my.user.dev.ai.claude-ping;

            claude-ping = pkgs.writeShellScript "claude-ping" ''
                # Open a Claude 5h usage window with minimal spend.
                set -u

                # coreutils for mkdir/timeout; CLAUDE because claude is not on a plain-npm path.
                export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
                export CLAUDE=${lib.getExe pkgs.claude-code}

                export DISABLE_AUTOUPDATER=1
                export DISABLE_TELEMETRY=1
                export DISABLE_ERROR_REPORTING=1
                export DISABLE_COST_WARNINGS=1
                export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1

                # Empty cwd: no repo scan, no project CLAUDE.md, no .mcp.json pickup.
                mkdir -p /tmp/claude-ping && cd /tmp/claude-ping || exit 1

                # --system-prompt REPLACES the default prompt (multi-KB of tool and environment
                # preamble), --tools "" drops the tool definitions, and --strict-mcp-config over an
                # empty --mcp-config skips every MCP server spawn -- and that must be a whole config,
                # not '{}': a bare object fails schema validation on the missing mcpServers key. NOT
                # --bare, which reads neither the OAuth token nor the keychain and so cannot touch the
                # window this exists to open.
                timeout 60 "$CLAUDE" -p 'k' \
                    --model haiku \
                    --system-prompt 'Reply with exactly one character: k' \
                    --tools "" \
                    --mcp-config '{"mcpServers":{}}' --strict-mcp-config \
                    --max-turns 1 \
                    --output-format text
            '';
        in
        {
            options.my.user.dev.ai.claude-ping.enable =
                tools.opt.mkDisabled "Scheduled ping that pins the phase of Claude's 5h usage window";

            config = lib.mkIf cfg.enable {
                assertions = [
                    {
                        assertion = config.my.user.dev.ai.enable;
                        message = "my.user.dev.ai.claude-ping.enable requires my.user.dev.ai.enable";
                    }
                    {
                        assertion = pkgs.stdenv.isLinux;
                        message = "my.user.dev.ai.claude-ping.enable is Linux-only (systemd user units)";
                    }
                ];

                systemd.user.services.claude-ping = {
                    Unit.Description = "Open a Claude 5h usage window";

                    Service = {
                        Type = "oneshot";
                        ExecStart = claude-ping;
                        SyslogIdentifier = "claude-ping";
                    };
                };

                systemd.user.timers.claude-ping = {
                    Unit.Description = "Claude usage-window boundaries";

                    Timer = {
                        OnCalendar = [
                            "Mon..Fri *-*-* 05:30:00"
                            "Mon..Fri *-*-* 10:31:00"
                            "Mon..Fri *-*-* 15:32:00"
                        ];

                        # 1s against a 1min default: lateness compounds across the three boundaries.
                        AccuracySec = "1s";

                        # `Persistent` stays at its default false. True fires the missed 05:30 on wake
                        # at, say, 09:15, pinning the phase there and putting the third window wholly
                        # past 17:00 -- a known miss beats a silently wrong phase.
                    };

                    Install.WantedBy = [ "timers.target" ];
                };
            };
        };
}
