# DockerNodeBun — tracker

**No planned fixes.**

Working tree pins **`FROM cartagodocker/zsh:v2.0.0`** (on Hub).
Local smoke on `nodebun-local:dev` (~695 MB) passed: no ENTRYPOINT,
`docker run img node --version`, Compose-style `tail`, uid 1000 PATH,
sudo NOPASSWD + `SUDO_PASSWORD`, NodeBun helpers **and** inherited
zsh helpers (`add_text_to_*`, `share_config_globally`, git/ssh
wrappers with `/$USER/.ssh` + `/$USER/.gitconfig` bind), daily CLI
from zsh, silent bun wrapper, `fnm env`/`fnm use`
(`~/.local/state` + chown), catalogue `dockernodebun`. Do not retag
Hub zsh `v1.0.5`.

Hub NodeBun `v2.0.0_n22…` / `n26…` on zsh 1.0.5 is immutable
(`ENTRYPOINT zsh`). New builds do not need `--entrypoint`.
