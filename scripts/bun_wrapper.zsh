#!/bin/bash
#
# PATH name is bun_wrapper.zsh (COPY from this repo). ${BUN_BIN}/bun
# and ${BUN_BIN}/bunx are symlinks to it. The shebang is bash on purpose:
#   - [[ ]], ${arg%%=*}, and the flag loop are bash, not POSIX sh / zsh.
#   - zsh would parse this file differently. Do not change the shebang
#     without rewriting the body. The .zsh suffix is historical.
#
# What this wrapper does (then runs bun_original):
#   1. bun_original picks AVX2 vs baseline from /proc/cpuinfo.
#   2. After `bun install -g` / `bun add -g` as root/sudo, chmod 777
#      on $BUN_HOME so other uids can use global bins.
#   3. Exit code is bun_original's (safe with set -e).
#   4. bunx: official bun is one binary; bunx is a symlink and bun
#      switches on argv0. bun_original execs bun_avx2/bun_baseline
#      under those names, so argv0 "bunx" cannot survive. If $0 is
#      bunx, prepend the `x` subcommand (`bunx pkg` → `bun x pkg`).
#
# Output:
#   - bun's stdout is untouched.
#   - Wrapper chatter goes to STDERR only.
#   - Default: silent. `BUN_WRAPPER_DEBUG=1 bun …` prints one line
#     with the args (and the chmod line still prints when it runs).

GLOBAL=false
INSTALL=false
IS_ROOT_PRIV=false
if [[ $(id -u) -eq 0 ]]; then
    IS_ROOT_PRIV=true
elif command -v sudo &>/dev/null && sudo -n true &>/dev/null; then
    IS_ROOT_PRIV=true
fi

# Official bunx is argv0. We cannot pass that through bun_original.
if [[ "${0##*/}" == bunx ]]; then
    set -- x "$@"
fi

if [[ "${BUN_WRAPPER_DEBUG:-}" == 1 ]]; then
    echo "bun_wrapper: $*" >&2
fi

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
