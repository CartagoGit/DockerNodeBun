#!/bin/bash
# Output -> /usr/local/bin/bun_wrapper.sh

GLOBAL=false
INSTALL=false
IS_ROOT_PRIV=false
# Check if the user has root permissions or is a sudoer
if [[ $(id -u) -eq 0 ]]; then
    IS_ROOT_PRIV=true
elif command -v sudo &>/dev/null && sudo -v &>/dev/null; then
    IS_ROOT_PRIV=true
fi

echo "Running bun_wrapper.sh script with parameters: $@"

# Propagate the exit code from bun_original so callers can rely on `set -e`
# and CI pipelines correctly detect failed builds (job marked failed when
# bun fails). Previously the wrapper swallowed $?, making any bun failure
# look like a 0 exit, which broke `set -e` in CI scripts and caused
# "job succeeded without artifact" bugs.
$BUN_HOME/bin/bun_original "$@"
bun_original_exit=$?

# Just users with root permissions or sudoers can give permissions to the bun share folder
if [[ "$IS_ROOT_PRIV" == true ]]; then
    for arg in "$@"; do
        # Detect global-install intent. Both old (-g) and modern (--global)
        # forms must match. Previously the condition required the flag to
        # NOT start with `--`, so `bun add --global pkg` slipped through
        # and left /usr/share/bun with restrictive perms.
        if [[ "$arg" == "-g" ]] || [[ "$arg" == "--global" ]] || \
           [[ "$arg" == -* && "$arg" != --* && "$arg" == *g* ]]; then
            GLOBAL=true
        fi
        # Detect install-class subcommands. `install`, `i`, `add`, `a`
        # are all valid (bun accepts short aliases). Previously only
        # `i` and `install` were detected, so `bun add -g pkg` and
        # `bun a --global pkg` were missed.
        if [[ "$arg" == "i" ]] || [[ "$arg" == "install" ]] || \
           [[ "$arg" == "a" ]] || [[ "$arg" == "add" ]]; then
            INSTALL=true
        fi
    done

    # Verify if it is bun, global and install
    if [[ "$GLOBAL" == true && "$INSTALL" == true ]]; then
        # If it is a global installation, we give permissions to the bun share folder
        echo "Giving permissions to the bun share folder (${BUN_HOME})"
        chmod -R 777 ${BUN_HOME}
    fi
fi

# Exit with bun_original's code so callers (set -e, CI steps) see the
# real status. Without this the wrapper always returns 0.
exit "${bun_original_exit:-0}"