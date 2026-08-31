#!/usr/bin/env bash
# ui.sh - shared gum UI + log routing. Source from install scripts.
set -u

# Public:
#   UI_VERBOSE=1 - stream command output (still tee'd to log)
#   UI_LOG       - log file path (default /tmp/...)

UI_LOG="${UI_LOG:-/tmp/arch-install-$(date +%Y%m%d-%H%M%S).log}"
mkdir -p "$(dirname "$UI_LOG")"
: > "$UI_LOG"

command -v gum >/dev/null 2>&1 || {
    echo "gum not found in PATH; install gum first." >&2
    exit 1
}

box() {
    gum style \
        --border rounded \
        --border-foreground 4 \
        --padding "1 3" \
        --width 64 \
        "$@"
}

heading() {
    gum style --bold --foreground 4 "$1"
}

step() {
    gum style --bold --foreground 4 -- "==> $*"
}

step_ok() {
    gum style --foreground 2 "    ok"
}

step_fail() {
    gum style --foreground 1 "    fail (log: $UI_LOG)"
}

run() {
    local name="$1"; shift
    step "$name"
    if [[ "${UI_VERBOSE:-0}" == "1" ]]; then
        if "$@" 2>&1 | tee -a "$UI_LOG"; then
            step_ok
        else
            step_fail; return 1
        fi
    else
        local tmp rc=0
        tmp=$(mktemp)
        gum spin --spinner dot --title "$name" -- "$@" >"$tmp" 2>&1 || rc=$?
        cat "$tmp" >> "$UI_LOG"; rm -f "$tmp"
        if [[ $rc -eq 0 ]]; then
            step_ok
        else
            step_fail; return "$rc"
        fi
    fi
}

confirm() {
    gum confirm "$1"
}

prompt() {
    local var="$1" label="$2" default="${3-}"
    local value placeholder=""
    [[ -n "$default" ]] && placeholder=" (default: $default)"
    while true; do
        value=$(gum input --prompt "$label$placeholder > " --value "$default")
        [[ -z "$value" && -n "$default" ]] && value="$default"
        if [[ -n "$value" ]]; then
            printf -v "$var" '%s' "$value"
            return
        fi
        gum style --foreground 1 "value cannot be empty"
    done
}

prompt_secret() {
    local var="$1" label="$2"
    local value check
    while true; do
        value=$(gum input --password --prompt "$label > ")
        [[ -n "$value" ]] || { gum style --foreground 1 "value cannot be empty"; continue; }
        check=$(gum input --password --prompt "confirm $label > ")
        if [[ "$value" == "$check" ]]; then
            printf -v "$var" '%s' "$value"
            return
        fi
        gum style --foreground 1 "passwords did not match"
    done
}
