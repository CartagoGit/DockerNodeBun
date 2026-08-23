# /etc/profile.d/nodebun.sh
# Login bash/sh (`su -`, `bash -l`, `sh -l`) drop Docker ENV.
# Re-export the image contract so bun/fnm/node keep working.
# Sourced by /etc/profile; also sourced from /etc/bash.bashrc
# for interactive non-login bash.

export BUN_HOME="${BUN_HOME:-/usr/share/bun}"
export BUN_INSTALL="${BUN_INSTALL:-${BUN_HOME}}"
export FNM_HOME="${FNM_HOME:-/usr/share/fnm}"
export FNM_DIR="${FNM_DIR:-${FNM_HOME}/store}"
export FNM_BIN="${FNM_BIN:-${FNM_HOME}/bin}"
export IS_INTO_CONTAINER="${IS_INTO_CONTAINER:-true}"
# Login shells (`su -`) drop Docker ENV. The image RUN rewrites the
# empty :- defaults below to this build's ARG (matrix Node + X.Y.Z).
export NODE_DEFAULT_VERSION="${NODE_DEFAULT_VERSION:-}"
export NODEBUN_IMAGE_VERSION="${NODEBUN_IMAGE_VERSION:-}"

# PATH is not re-exported on purpose. node / npm / npx / bun / fnm live
# in /usr/local/bin, which Ubuntu login PATH already keeps. Docker ENV
# PATH is dropped by `su -` / `bash -l`; those binaries still resolve.

# Optional: docker run -e SUDO_PASSWORD=... → require that password.
# No-op when unset. Safe to source on every shell (flag in /run).
if [ -x /usr/local/bin/apply-sudo-password-on-boot.sh ]; then
  /usr/local/bin/apply-sudo-password-on-boot.sh || true
fi
