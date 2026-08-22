#!/bin/sh
# Passwordless sudo for every login user. New users (useradd/adduser)
# join group sudo. Optional password is NOT baked at build: set it at
# runtime with SUDO_PASSWORD or `sudo-password`.
set -eu

printf '%s\n' \
  'Defaults !requiretty' \
  'Defaults lecture=never' \
  'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/bun/bin:/usr/share/fnm/bin"' \
  'ALL ALL=(ALL:ALL) NOPASSWD:ALL' \
  > /etc/sudoers.d/nodebun
chmod 0440 /etc/sudoers.d/nodebun
visudo -cf /etc/sudoers.d/nodebun

if [ -f /etc/adduser.conf ]; then
  sed -i 's/^#*EXTRA_GROUPS=.*/EXTRA_GROUPS="sudo"/; s/^#*ADD_EXTRA_GROUPS=.*/ADD_EXTRA_GROUPS=1/' /etc/adduser.conf
fi

if [ -x /usr/sbin/useradd ] && [ ! -e /usr/sbin/useradd.real ]; then
  mv /usr/sbin/useradd /usr/sbin/useradd.real
fi

cat > /usr/local/sbin/useradd <<'WRAP'
#!/bin/sh
real=/usr/sbin/useradd.real
"$real" "$@"
st=$?
[ "$st" -eq 0 ] || exit "$st"
user=
for a in "$@"; do
  case "$a" in
    -*) ;;
    *) user=$a ;;
  esac
done
if [ -n "$user" ] && id "$user" >/dev/null 2>&1; then
  usermod -aG sudo "$user" 2>/dev/null || true
  if [ -f /etc/sudoers.d/nodebun-password ] && [ -f /etc/nodebun-sudo-password ]; then
    pw=$(cat /etc/nodebun-sudo-password)
    printf '%s\n' "${user}:${pw}" | chpasswd
  fi
fi
exit 0
WRAP
chmod 0755 /usr/local/sbin/useradd
ln -sfn /usr/local/sbin/useradd /usr/sbin/useradd

awk -F: '$3>=0 && $3<65534 && $7 !~ /(nologin|false)/ {print $1}' /etc/passwd \
  | while read -r u; do
      usermod -aG sudo "$u" 2>/dev/null || true
    done
