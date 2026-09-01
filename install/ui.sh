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

# True only when gum works AND stdout is a real terminal — animations and
# colour only render there. Under pipes/redirects/non-interactive runs we
# fall back to plain text instead of emitting ANSI garbage.
gum_tty() { command -v gum >/dev/null 2>&1 && [[ -t 1 ]]; }

# Grey "current substage" line (e.g. "installing packages"). Plain when the
# terminal can't render it.
substage() {
    if gum_tty; then
        gum style --faint -- "... $*"
    else
        printf '... %s\n' "$*"
    fi
}

step_fail() {
    gum style --foreground 1 "    fail (log: $UI_LOG)"
}

run() {
    local name="$1"; shift
    step "$name"
    # No fancy spinner when running into a non-terminal or when verbose:
    # just run it and stream straight to the log + screen.
    if [[ "${UI_VERBOSE:-0}" == "1" ]] || ! gum_tty; then
        "$@" 2>&1 | tee -a "$UI_LOG"
        local rc=${PIPESTATUS[0]}
        (( rc == 0 )) && step_ok || { step_fail; return "$rc"; }
        return 0
    fi
    local tmp rc=0
    tmp=$(mktemp)
    gum spin --spinner dot --title "$name" -- "$@" >"$tmp" 2>&1 || rc=$?
    cat "$tmp" >> "$UI_LOG"; rm -f "$tmp"
    (( rc == 0 )) && step_ok || { step_fail; return "$rc"; }
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
