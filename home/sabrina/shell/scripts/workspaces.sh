#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CACHING & MIGRATION
# -----------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "workspaces"

# ============================================================================
# 0. SINGLE INSTANCE GUARD
# TopBar re-creations can spawn two listeners that race on the same JSON.
# flock is atomic, so it closes the startup race of the pgrep-only check.
# ============================================================================
exec 9> "$QS_RUN_WORKSPACES/workspaces.lock"
flock -n 9 || exit 0

# ============================================================================
# 1. ZOMBIE PREVENTION
# Kills any older instances of this script. When Quickshell reloads,
# it can leave the old listener pipelines running in the background infinitely.
# The anchored pattern (script path at the END of the cmdline) ensures the
# process that launched us (zsh -c wrapper, setsid, etc.) is never matched.
# ============================================================================
for pid in $(pgrep -f "workspaces\.sh$"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

# Cleanly kill immediate children (like niri msg) when the script exits normally
cleanup() {
    pkill -P $$ 2>/dev/null
}
trap cleanup EXIT SIGTERM SIGINT

# --- Special Cleanup for Network/Bluetooth ---
# The network toggle starts a background bluetooth scan that must be killed explicitly.
BT_PID_FILE="$QS_RUN_WORKSPACES/bt_scan_pid"

if [ -f "$BT_PID_FILE" ]; then
    kill $(cat "$BT_PID_FILE") 2>/dev/null
    rm -f "$BT_PID_FILE"
fi

# Ensure bluetooth scan is explicitly turned off (timeout prevents deadlocks on fresh installs)
(timeout 2 bluetoothctl scan off > /dev/null 2>&1) &
# ---------------------------------------------

# Configuration: Parse from settings.json dynamically, fallback to 8
SETTINGS_FILE="$HOME/.config/hypr/settings.json"
SEQ_END=$(jq -r '.workspaceCount // 8' "$SETTINGS_FILE" 2>/dev/null)
# Double check it is a valid integer to prevent jq errors later
if ! [[ "$SEQ_END" =~ ^[0-9]+$ ]]; then
    SEQ_END=8
fi

print_workspaces() {
    # Two direct niri queries (no hyprctl shim: python startup per event was
    # the workspace-switch lag). niri's workspace JSON has no windows field,
    # so join the windows list by workspace_id. Workspace "numbers" live in
    # the name field, falling back to the opaque id for unnamed leftovers.
    spaces=$(timeout 2 niri msg -j workspaces 2>/dev/null)
    [ -z "$spaces" ] && return
    wins=$(timeout 2 niri msg -j windows 2>/dev/null)
    [ -z "$wins" ] && wins="[]"

    # Generate the JSON and write it in place: a direct write keeps the same
    # inode, so TopBar's inotifywait on the file keeps firing. (mv would
    # replace the inode and freeze the indicator until the shell reloads.)
    echo "$spaces" | jq --unbuffered --argjson wins "$wins" --arg end "$SEQ_END" -c '
        ($wins | group_by(.workspace_id) | map({key: (.[0].workspace_id|tostring), value: .}) | from_entries) as $byws |
        (map({ key: (if ((.name // "") | test("^[0-9]+$")) then .name else (.id|tostring) end), value: . }) | from_entries) as $s |
        (($s | to_entries[] | select(.value.is_active) | .key) // "") as $a |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            ($s[($i|tostring)]) as $w |
            ($byws[($w.id // -1 | tostring)] // []) as $wl |
            # Determine state: active -> occupied -> empty
            (if ($i|tostring) == $a then "active"
             elif ($wl | length) > 0 then "occupied"
             else "empty" end) as $state |

            # Get the title of the last focused window on the workspace
            (if ($wl | length) > 0 then
                 ($wl | sort_by(.focus_timestamp.secs, .focus_timestamp.nanos) | last | .title)
             else "Empty" end) as $win |

            {
                id: $i,
                state: $state,
                tooltip: $win
            }
        )
    ' > "$QS_RUN_WORKSPACES/workspaces.json"
}

# Print initial state
print_workspaces

# ============================================================================
# 2. THE EVENT DEBOUNCER
# Listen to niri's event stream wrapped in an infinite loop.
# hyprctl workspaces/activeworkspace go through the hyprctl->niri shim.
# ============================================================================
while true; do
    niri msg -j event-stream 2>/dev/null | while read -r line; do
        case "$line" in
            *WorkspaceActivated*|*WorkspacesChanged*|*WindowsChanged*)

                # -> THE FIX <-
                # Hyprland emits HUNDREDS of events a second when you move/resize windows.
                # This reads and discards all subsequent events arriving within a 50ms window.
                # It bundles the storm into a single UI update, completely preventing CPU clogging!
                while read -t 0.05 -r extra_line; do
                    continue
                done

                print_workspaces
                ;;
        esac
    done
    sleep 1
done
