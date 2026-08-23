# DockerNodeBun — tracker

**No planned code fixes.**

Working tree pins **`FROM cartagodocker/zsh:v2.0.0`** (on Hub).
Local smoke on `nodebun-local:dev` (~695 MB, Node 26) passed: no
ENTRYPOINT, `docker run img node --version`, uid 1000 PATH, sudo
NOPASSWD + `SUDO_PASSWORD`, NodeBun helpers **and** inherited zsh
helpers (`add_text_to_*`, `share_config_globally`, git/ssh wrappers
with `/$USER/.ssh` + `/$USER/.gitconfig` bind), daily CLI from zsh,
silent bun wrapper, `fnm env`/`fnm use` (`~/.local/state` + chown),
login zsh `su -` via `/etc/zsh/zprofile` sourcing `nodebun.sh`
(`build.env` = this image's ARG), catalogue `dockernodebun`.
Do not retag Hub zsh `v1.0.5`.

**Publish (ops, not a tree bug):** git tag `v2.0.0` is not on the
repo yet. Hub has no `v2.0.0_n22…` / `n26…` (404). Hub still has
legacy `v1_n26…` and `v.1.x`. Push `v2.0.0` from `main` when you
want Hub + GitHub Release. New builds do not need `--entrypoint`.
