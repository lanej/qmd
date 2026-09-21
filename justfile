# qmd — local dev/service tasks
# Mirrors the launchd pattern in ~/src/bigquery/justfile

# Default recipe - show available commands
default:
    @just --list

# Render the plist template and load the MCP HTTP daemon as a per-user LaunchAgent
launchd-install port="8181":
    @if [ "$(uname -s)" = "Darwin" ]; then \
        BIN_PATH="$(command -v qmd)"; \
        if [ -z "$BIN_PATH" ]; then \
            echo "⚠ qmd not found on PATH — install it globally first"; \
            exit 1; \
        fi; \
        LOG_DIR="$HOME/Library/Logs/qmd-mcp"; \
        mkdir -p "$LOG_DIR"; \
        mkdir -p "$HOME/Library/LaunchAgents"; \
        PLIST_PATH="$HOME/Library/LaunchAgents/com.easypost.qmd-mcp.plist"; \
        sed -e "s#__QMD_BIN_PATH__#$BIN_PATH#g" -e "s#__PATH__#$PATH#g" -e "s#__PORT__#{{port}}#g" -e "s#__LOG_DIR__#$LOG_DIR#g" -e "s#__HOME_DIR__#$HOME#g" \
            launchd/com.easypost.qmd-mcp.plist.template \
            | awk '/<!--/ { incomment=1 } incomment { if (/-->/) incomment=0; next } { print }' \
            > "$PLIST_PATH"; \
        echo "✓ Wrote $PLIST_PATH"; \
        launchctl bootout "gui/$(id -u)/com.easypost.qmd-mcp" >/dev/null 2>&1 || true; \
        launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"; \
        echo "✓ Loaded com.easypost.qmd-mcp (launchd), listening on localhost:{{port}}"; \
    else \
        echo "ℹ launchd-install is macOS only — skipping (non-Darwin)"; \
    fi

# Unload the MCP HTTP daemon LaunchAgent and remove its plist
launchd-uninstall:
    @if [ "$(uname -s)" = "Darwin" ]; then \
        launchctl bootout "gui/$(id -u)/com.easypost.qmd-mcp" >/dev/null 2>&1 || true; \
        rm -f "$HOME/Library/LaunchAgents/com.easypost.qmd-mcp.plist"; \
        echo "✓ Uninstalled com.easypost.qmd-mcp"; \
    else \
        echo "ℹ launchd-uninstall is macOS only — skipping (non-Darwin)"; \
    fi

# Restart the MCP HTTP daemon in place (one command instead of a PID hunt)
launchd-restart:
    @if [ "$(uname -s)" = "Darwin" ]; then \
        launchctl kickstart -k "gui/$(id -u)/com.easypost.qmd-mcp"; \
        echo "✓ Restarted com.easypost.qmd-mcp"; \
    else \
        echo "ℹ launchd-restart is macOS only — skipping (non-Darwin)"; \
    fi

# Show launchd's status for the MCP HTTP daemon
launchd-status:
    @if [ "$(uname -s)" = "Darwin" ]; then \
        launchctl print "gui/$(id -u)/com.easypost.qmd-mcp"; \
    else \
        echo "ℹ launchd-status is macOS only — skipping (non-Darwin)"; \
    fi
