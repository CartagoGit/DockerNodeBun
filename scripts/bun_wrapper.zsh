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

$BUN_HOME/bin/bun_original "$@"

# Just users with root permissions or sudoers can give permissions to the bun share folder
if [[ "$IS_ROOT_PRIV" == true ]]; then
    for arg in "$@"; do
        if [[ "$arg" == -* && "$arg" != --* && "$arg" == *g* ]] || [[ "$arg" == "--global" ]]; then
            GLOBAL=true
        fi
        if [[ "$arg" == "i" || "$arg" == "install" ]]; then
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