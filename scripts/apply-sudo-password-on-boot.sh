#!/bin/sh
# If SUDO_PASSWORD is set when the container starts, require that
# password for sudo. Sourced from profile.d / zshrc. Works as uid 1000
# because the image starts with NOPASSWD and sudo-password escalates.
set -eu
flag=/run/nodebun-sudo-password-applied
if [ -f "$flag" ]; then
  exit 0
fi
if [ -z "${SUDO_PASSWORD:-}" ]; then
  exit 0
fi
if command -v sudo-password >/dev/null 2>&1; then
  sudo-password "$SUDO_PASSWORD"
fi
