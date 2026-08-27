# /etc/profile.d/nodebun.sh
# Login bash/sh (`su -`, `bash -l`, `sh -l`) drop Docker ENV.
# Re-export the image contract so bun/fnm/node keep working.
# Sourced by /etc/profile, /etc/bash.bashrc, and /etc/zsh/zprofile
# (Ubuntu login zsh does not source /etc/profile).
#
# This file is the same in every matrix. Per-image Node / X.Y.Z live in
# /usr/share/nodebun/build.env (written at docker build from ARG).

export BUN_HOME="${BUN_HOME:-/usr/share/bun}"
export BUN_INSTALL="${BUN_INSTALL:-${BUN_HOME}}"
export FNM_HOME="${FNM_HOME:-/usr/share/fnm}"
export FNM_DIR="${FNM_DIR:-${FNM_HOME}/store}"
export FNM_BIN="${FNM_BIN:-${FNM_HOME}/bin}"
export IS_INTO_CONTAINER="${IS_INTO_CONTAINER:-true}"

# Login dropped Docker ENV → fill from this image's build. If ENV is
# already set (normal docker run, or a child that overwrote it), keep it.
if [ -r /usr/share/nodebun/build.env ]; then
  # shellcheck disable=SC1091
  . /usr/share/nodebun/build.env
fi
export NODE_DEFAULT_VERSION="${NODE_DEFAULT_VERSION:-${NODEBUN_BUILD_NODE:-}}"
export NODEBUN_IMAGE_VERSION="${NODEBUN_IMAGE_VERSION:-${NODEBUN_BUILD_VERSION:-}}"
unset NODEBUN_BUILD_NODE NODEBUN_BUILD_VERSION

# PATH is not re-exported on purpose. node / npm / npx / bun / bunx / fnm
# live in /usr/local/bin, which Ubuntu login PATH already keeps. Docker
# ENV PATH is dropped by `su -` / `bash -l`; those binaries still resolve.

# Login zsh (`su -`) skips .zshrc when non-interactive, so the zshrc
# `fnm env` never runs. bash-syntax eval is POSIX and zsh-safe.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)" || true
fi

# Optional: docker run -e SUDO_PASSWORD=... → require that password.
# No-op when unset. Safe to source on every shell (flag in /run).
if [ -x /usr/local/bin/apply-sudo-password-on-boot.sh ]; then
  /usr/local/bin/apply-sudo-password-on-boot.sh || true
fi
