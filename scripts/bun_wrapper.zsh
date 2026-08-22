#!/bin/bash
#
# Wrapper instalado en /usr/local/bin/bun_wrapper.zsh (Dockerfile COPY)
# y enlazado desde ${BUN_BIN}/bun.
#
# Reglas de output:
#   - Todo lo que imprima este wrapper va a STDERR, NO stdout.
#     Razon: muchos callers (CI, scripts) hacen 'bun ... | head -5' o
#     redirigen stdout a parsers. Si el wrapper contamina stdout con
#     'Running bun_wrapper.sh...', los parsers se rompen.
#   - El output real de bun_original se mantiene en stdout intacto.
#
# Reglas de exit code:
#   - Se propaga el exit code de bun_original via 'exit ${bun_original_exit}'.
#     Antes el wrapper retornaba 0 siempre, lo que rompia 'set -e' en
#     scripts CI: 'set -e; bun --silent run script' fallaba silenciosamente.
#     Ver commit f025a67 (logs a stderr) y bc766fa (exit code).

GLOBAL=false
INSTALL=false
IS_ROOT_PRIV=false
if [[ $(id -u) -eq 0 ]]; then
    IS_ROOT_PRIV=true
elif command -v sudo &>/dev/null && sudo -n true &>/dev/null; then
    IS_ROOT_PRIV=true
fi

echo "Running bun_wrapper.sh script with parameters: $@" >&2

BUN_HOME="${BUN_HOME:-/usr/share/bun}"
"$BUN_HOME/bin/bun_original" "$@"
bun_original_exit=$?

# Only root/sudoers get to relax permissions on the share folder.
if [[ "$IS_ROOT_PRIV" == true ]]; then
    # Install-class subcommand check. The subcommand must be the FIRST
    # argument to count (bun's positional CLI is subcommand-first).
    # Detecting 'i'/'install'/'add'/'a' as INSTALL anywhere in args
    # causes false positives with `bun run i` or `bun add -g some-pkg i`
    # where 'i' is just a script name / package name.
    if [[ $# -gt 0 ]]; then
        case "$1" in
            i|install|a|add) INSTALL=true ;;
        esac
    fi
    for arg in "$@"; do
        # Split on '=' first so '--global=true' is treated as the long
        # flag, not as a flag whose value happens to be '=true'.
        flag_part="${arg%%=*}"
        # Global flag: -g/-G short, --global long, --global=value,
        # or any short flag containing g/G (e.g. -gx, legacy compat).
        if [[ "$flag_part" == "-g" ]] || [[ "$flag_part" == "-G" ]] || \
           [[ "$flag_part" == "--global" ]] || \
           [[ "$flag_part" == -* && "$flag_part" != --* && "$flag_part" == *[gG]* ]]; then
            GLOBAL=true
        fi
    done

    if [[ "$GLOBAL" == true && "$INSTALL" == true ]]; then
        echo "Giving permissions to the bun share folder (${BUN_HOME})" >&2
        chmod -R 777 ${BUN_HOME}
    fi
fi

exit "${bun_original_exit:-0}"
