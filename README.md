# 🟢 cartagodocker/nodebun

**Node**, **npm**, **bun**, and **fnm** on top of
[`cartagodocker/zsh`](https://hub.docker.com/r/cartagodocker/zsh)
(Ubuntu **24.04 LTS** + zsh + Oh My Zsh + Powerlevel10k).

Same layout as the [zsh README](https://github.com/CartagoGit/DockerZsh#readme).
This page only expands what NodeBun **adds**. Shell, sudo, SSH, fonts, and
the daily CLI are inherited — details live there.

| | |
|---|---|
| 📦 GitHub | https://github.com/CartagoGit/DockerNodeBun |
| 🐋 Docker Hub | https://hub.docker.com/r/cartagodocker/nodebun |
| 📝 Changelog | [CHANGELOG.md](./CHANGELOG.md) |
| 🏷️ Versioning | [VERSIONING.md](./VERSIONING.md) |

Tags are **exact**. There is no `latest` / `stable`. Pin the matrix you need.

```dockerfile
FROM cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
```

> Pin **`cartagodocker/zsh:v2.0.0`**. There is no `latest`.

---

## 📦 What's in the image

| | Piece | Notes |
|---|---|---|
| 🐧 | OS | Ubuntu 24.04 LTS — from [`cartagodocker/zsh`](https://hub.docker.com/r/cartagodocker/zsh) |
| 📌 | zsh pin | **`cartagodocker/zsh:v2.0.0`** |
| 🐚 | Interactive shell | zsh + Oh My Zsh + Powerlevel10k — `CMD ["/usr/bin/zsh"]`, **no ENTRYPOINT** (zsh 2.0.0) |
| 💻 | Other shells | `bash` and `sh` (dash) — inherited |
| 🟢 | Node / npm / bun / fnm | Installed at **build**; on `PATH` for every uid and every shell |
| 📂 | Listing / pager | Inherited from zsh — full list in [Utilities](#utilities) |
| 🧰 | Daily CLI | Inherited from zsh (not reinstalled). Full inventory: [Utilities](#utilities) |
| 📖 | Catalogue | `dockernodebun --help` — zsh catalogue, then NodeBun extras (see [Catalogue CLI](#catalogue-cli-dockernodebun)) |
| 🌐 | Network | Inherited: `curl`, `wget`, `git`, **`openssh-client`** (no sshd), **`ca-certificates`** |
| 🔐 | sudo | Inherited (NOPASSWD + `sudo-password`). Not overwritten when the base already has it |
| 🌍 | Locale | Inherited: `LANG=C.UTF-8` · `LC_ALL=C.UTF-8` |
| 🧱 | Build `SHELL` | `["/bin/sh", "-c"]` — same as zsh |

No `openssh-server`, no `ENTRYPOINT`: `docker run` / Compose `command:` is the process (`node --version` works on zsh 2.0.0).

**Not in this image** (same as zsh): `gcc`/`g++`, `python3`, `neovim`, `git-lfs`, `rclone`, `locales`, `man-db`, `nmap`, **no sshd**, **no Docker**. NodeBun does **not** add a second CLI kit — only runtimes: `fnm`, one Node (matrix), `npm`, **two** bun binaries (AVX2 + baseline), `libatomic1`. Compilers / Docker client go in a **further** child. Drive this container with host `docker`.

sudo / `dockerzsh` / `add_text_to_*` come from **`cartagodocker/zsh:v2.0.0`**. Not reinstalled; no fallback for older zsh tags.

---

## 🧰 Utilities

**From zsh (not reinstalled):** [zsh README — Utilities](https://github.com/CartagoGit/DockerZsh#utilities) (name → docs). Same aliases (`ls`→`eza` in interactive zsh/bash/sh). In-container: `dockerzsh --help` or `dockernodebun --listing`.

**This image adds** the tables below. Usage: [Scripts for child images](#scripts-for-child-images). zsh helpers: [zsh README — Scripts](https://github.com/CartagoGit/DockerZsh#scripts-for-child-images) or `dockernodebun --zsh-helpers`.

### Runtimes (NodeBun)

On `PATH` (`/usr/local/bin`) for every uid and every shell. `libatomic1` is for bun. `/usr/local/bin/bun` is a bash wrapper (AVX2 vs baseline from `/proc/cpuinfo`; chatter if `BUN_WRAPPER_DEBUG=1`). Interactive zsh: `bunx` → `bun x`. `fnm use` is this shell only (`FNM_DIR=/usr/share/fnm/store`, 777).

| Tool | Docs |
|---|---|
| `node` | [Node.js](https://nodejs.org/docs/latest/api/) |
| `npm` / `npx` | [npm](https://docs.npmjs.com/cli) · [npx](https://docs.npmjs.com/cli/commands/npx) |
| `bun` | [bun](https://bun.sh/docs) |
| `fnm` | [fnm](https://github.com/Schniz/fnm) |

### NodeBun helpers (ours)

| Command | Docs |
|---|---|
| `in-bash` | [Scripts](#scripts-for-child-images) |
| `in-sh` | [Scripts](#scripts-for-child-images) |
| `only-in-container` | [Scripts](#scripts-for-child-images) |
| `skip-if-container` | [Scripts](#scripts-for-child-images) |
| `dockernodebun` | [Catalogue](#catalogue-cli-dockernodebun) |

---

## 📏 Image size

`docker images` is uncompressed. Hub pull is gzip layers (smaller). On top of `cartagodocker/zsh:v2.0.0`.

| | Uncompressed (disk / `docker images`) | Compressed (Hub pull / download) |
|---|---|---|
| zsh v2.0.0 (parent tree) | ~240–260 MB | ~110–125 MB |
| Node official linux-x64 (`26.3.1` / `22.21.1`) | ~**90–120 MB** unpacked | ~32 MB / ~29 MB `.tar.xz` |
| bun AVX2 zip + baseline zip | ~**2 × 90–110 MB** unpacked | ~34 MB + ~34 MB zips |
| fnm | ~8 MB | ~3 MB zip |
| `libatomic1` | ~0.04 MB | tiny |
| **Whole tag** (local 2.0.0 on Hub zsh 2.0.0, Node 26) | **~695 MB** | Hub layers (not listed for every matrix) |

Two bun builds on purpose: `/usr/local/bin/bun` is a **bash** wrapper (`bun_wrapper.zsh` — historical `.zsh` name, `#!/bin/bash`) that picks AVX2 vs baseline from `/proc/cpuinfo`. That **doubles** bun on disk. Silent unless `BUN_WRAPPER_DEBUG=1`. One Node is baked (`fnm install` of the matrix); extra `fnm install` at runtime grows `FNM_DIR`.

Disk ≈ zsh 2.0.0 + Node + two bun + fnm: local smoke **~695 MB** uncompressed (Node 26). Hub NodeBun 2.0.0 on zsh 1.0.5 was ~642 MB.

---

## 🏷️ Runtime matrices

Defined in [`.github/matrices.yml`](./.github/matrices.yml):

| Matrix | Node | Bun | npm | fnm | Status |
|---|---|---|---|---|---|
| `n22.21.1_b1.3.14` | `22.21.1` | `1.3.14` | `10.9.4` | `1.38.1` | ✅ Node 22 LTS |
| `n26.3.1_b1.3.14` | `26.3.1` | `1.3.14` | `12.0.1` | `1.39.0` | ✅ Node 26 current |

```text
v{X.Y.Z}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Examples: `v2.0.0_n22.21.1_b1.3.14`, `v2.0.0_n26.3.1_b1.3.14`.

`X.Y.Z` counts repo corrections (Dockerfile, wrapper, docs) and is published on **all** active matrices in parallel. Full policy: [VERSIONING.md](./VERSIONING.md).

---

## ▶️ How to run it

Two different jobs. Mix them up and it looks like “eza is broken”.

Node / bun / npm / fnm are **baked at `docker build`**. `docker run` does not download them. On `PATH` (`/usr/local/bin`) for **any** uid and **any** shell.

| Tool | At build | At start |
|---|---|---|
| Node | `fnm install` → `FNM_DIR=/usr/share/fnm/store` | `/usr/local/bin/node` |
| npm | `npm install -g npm@…` | `/usr/local/bin/npm` |
| bun | AVX2 + baseline zips; wrapper reads `/proc/cpuinfo` | `/usr/local/bin/bun` |
| fnm | release zip | `/usr/local/bin/fnm` |

zsh extras (p10k) load from `~/.zshrc` and need a **TTY**. Interactive bash/sh also get `ls`→eza. `node` / `npm` / `bun` do not need a TTY.

### 🖥️ Interactive prompt (eza, bat, p10k)

Needs a **TTY** (`-it` or `exec -it`).

```bash
# Hub: IMG=cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
IMG=nodebun-local:dev
docker run --rm -it --user 1000:1000 -w /home/ubuntu \
  -v "$HOME/.ssh:/$USER/.ssh:ro" \
  -v "$HOME/.gitconfig:/$USER/.gitconfig:ro" \
  "$IMG"
docker run --rm -it "$IMG"   # root, no bind
```

`ls`→eza. `bat` works. p10k draws the prompt. `node`/`npm`/`bun` work in every shell. Inside zsh: `bash`, `sh`, `exit`. Interactive bash/sh alias `ls`→eza; no p10k.

### 🧊 Keep-alive (Compose)

The container stays up **without** a shell. Typical:

```yaml
services:
  app:
    image: cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
    command: ["tail", "-f", "/dev/null"]
    user: "1000:1000"
    working_dir: /work
    volumes:
      - .:/work
```

That process is **`tail`, not zsh**, and **not a TTY**. No prompt, no eza aliases, no p10k. Attach when you want the shell:

```bash
docker compose exec app zsh          # prompt + eza + bat + p10k
docker compose exec app bash         # bash; node/npm/bun still on PATH
docker compose exec app bun install
```

```bash
docker run --rm cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 node --version
```

`docker run --rm image bash` and `docker run --rm image node --version` work because there is no ENTRYPOINT swallowing the command (`cartagodocker/zsh:v2.0.0`).

---

## 🔐 sudo

Inherited from zsh. Global files (`/usr/share/globally/.zshrc`) are `644` root:root — uid `1000` cannot overwrite them. Use `sudo` or `add_text_to_zshrc` (NOPASSWD). `node`/`npm`/`bun` do not need sudo.

```bash
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
# inside:
sudo -n id                 # default: no password
sudo-password              # prompt; afterwards sudo asks for it
sudo-password 'secret'     # from arg (visible in ps)
sudo-nopasswd              # back to NOPASSWD
```

Password at start (not baked into the image):

```bash
docker run --rm -it -e SUDO_PASSWORD=secret cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
```

Compose `user: "1000:1000"` drops extra groups, so the sudoers rule is `ALL`, not `%sudo`.

---

## 🎨 Fonts and icons

Same contract as [cartagodocker/zsh](https://hub.docker.com/r/cartagodocker/zsh). The **container only emits Unicode**. The **host terminal** draws glyphs.

| | What | Needs on the host |
|---|---|---|
| 🔷 | Powerlevel10k separators, git icons, eza file icons | A [Nerd Font](https://www.nerdfonts.com/font-downloads) (CaskaydiaCove / Cascadia Code NF) |
| 🐳 | Prompt whale (`os_icon`) | An **emoji** font — Segoe UI Emoji (Windows), Apple Color Emoji (macOS), Noto Color Emoji (many Linux desktops). Some Linux terminals have none → tofu. Same Unicode everywhere; the font is local. |

VS Code:

```json
"terminal.integrated.fontFamily": "'Cascadia Code NF', 'CaskaydiaCove Nerd Font', Consolas, monospace"
```

Without a Nerd Font you get boxes on powerline / `ls` icons — not an image bug.

---

## 🧩 Scripts for child images

### From zsh (inherited)

`add_text_to_zshrc`, `add_text_to_p10k`, `share_config_globally`, `sudo-password`, `sudo-nopasswd` — same CLI as [zsh](https://github.com/CartagoGit/DockerZsh#scripts-for-child-images). Write `/usr/share/globally/...`; `sudo` if needed. Full text: `dockerzsh --helpers` or `dockernodebun --zsh-helpers`.

### NodeBun only

Most people never type these (`bash pepe.sh` is enough). Same Makefile on host and in-container. Detect `/.dockerenv` or `IS_INTO_CONTAINER=true`.

#### `in-bash`

`bash --login` so `/etc/profile.d/nodebun.sh` loads (`BUN_*` / `FNM_*`). For snippets that are not zsh-safe (`set -o pipefail`, `[[ ]]`, bash arrays). No args: interactive bash.

```bash
in-bash
in-bash -c 'set -o pipefail; npm test | tee log'
in-bash script.sh
```

#### `in-sh`

POSIX `sh -l` (dash + login env). Same idea as `in-bash` for portable snippets.

```bash
in-sh
in-sh -c 'case $1 in *.sh) echo posix ;; esac'
in-sh script.sh
```

#### `only-in-container`

Run CMD **only inside** this container. No args: exit `0` inside, `1` outside (predicate). Outside with a command: error, exit `1`.

```bash
only-in-container                  # 0 inside, 1 on the host
only-in-container bun run test     # skip on the host
```

#### `skip-if-container`

No-op inside (exit `0`); run CMD on the **host**. For host-only tools (`adb`, `docker`, `osascript`). No args on the host: error.

```bash
skip-if-container adb start-server
```

Catalogue dump of these four: `dockernodebun --helpers`.

---

## 🔑 SSH (client only — no sshd)

Inherited from zsh. Bind host `~/.ssh` and type `ssh` / `git`. Root or any uid — one volume. **Git author is not the SSH key:** bind `~/.gitconfig` (or `GIT_AUTHOR_NAME` + `GIT_AUTHOR_EMAIL`). Full contract: [zsh README — SSH](https://github.com/CartagoGit/DockerZsh#ssh-client-only--no-sshd).

```yaml
services:
  app:
    image: cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
    volumes:
      - ~/.ssh:/${USER}/.ssh:ro
      - ~/.gitconfig:/${USER}/.gitconfig:ro
```

```bash
docker run --rm -it \
  -v "$HOME/.ssh:/$USER/.ssh:ro" \
  -v "$HOME/.gitconfig:/$USER/.gitconfig:ro" \
  cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
# inside: ssh git@github.com
#         git commit   # author = host user.name, not ubuntu@id
```

`${USER}` is the **host** name. Docker needs an **absolute** target (`/${USER}/.ssh`), not `${USER}/.ssh`. Not SSH-into-the-container — attach with `docker exec -it … zsh`.

---

## 🌍 Environment

| Variable | Meaning |
|---|---|
| `NODE_DEFAULT_VERSION` | Matrix Node |
| `FNM_HOME` / `FNM_DIR` / `FNM_BIN` | `/usr/share/fnm`, store, bin |
| `BUN_HOME` / `BUN_INSTALL` | `/usr/share/bun` |
| `IS_INTO_CONTAINER` | `true` |
| `VERSION` | Convenience `X.Y.Z`. A child `FROM nodebun` that sets its own `VERSION` overwrites this. |
| `NODEBUN_IMAGE_VERSION` | This NodeBun tag. `dockernodebun --version` uses it, not `VERSION`. |
| `ZSH_IMAGE_VERSION` | Parent zsh tag (`cartagodocker/zsh`). `dockerzsh --version` uses it. |
| `LANG` / `LC_ALL` | Inherited `C.UTF-8` |

Login shells (`su -`, `bash -l`) drop Docker `ENV`. `/etc/profile.d/nodebun.sh` re-exports NodeBun vars (also from `/etc/zsh/zprofile` — Ubuntu login zsh does not source `/etc/profile`). Same script on every matrix. This image’s Node / X.Y.Z live in `/usr/share/nodebun/build.env` (from ARG at build) and fill only when ENV is unset. Interactive zsh still runs `fnm env` from `.zshrc`.

`FNM_DIR` is `777` (same as bun): any uid can `fnm install` / `fnm use`. Homes and `/etc/skel` get `~/.local/share/fnm` → that store, plus `~/.local/state` (fnm multishells) owned by that user so `fnm env` works as uid 1000.

```bash
fnm install 20.19.0
fnm use 20.19.0    # this shell only; a new shell is back on the matrix
```

---

## 📖 Catalogue CLI (`dockernodebun`)

Inside a running container **`dockernodebun`** is the zsh catalogue first (`dockerzsh --help`), then NodeBun extras. Not the host `docker` CLI.

```bash
docker run --rm cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 dockernodebun --help
docker compose exec app dockernodebun --help
```

The full dump is long on purpose. Filter by **section**. NodeBun ids stay here; zsh ids go to `dockerzsh`.

```bash
dockernodebun --sections | -s    # zsh ids + NodeBun ids
dockernodebun --runtimes         # node / npm / bun / fnm
dockernodebun --helpers          # in-bash, in-sh, only-in-container, skip-if-container
dockernodebun --zsh-helpers      # add_text_to_zshrc, add_text_to_p10k, share_config_globally, sudo-password, sudo-nopasswd, git-from-host (zsh)
dockernodebun --env              # NODE_DEFAULT_VERSION, FNM_DIR, BUN_*, IS_INTO_CONTAINER
dockernodebun --shells           # zsh section (forwards)
dockernodebun shells env         # mix zsh + NodeBun sections
dockernodebun --version | -v     # image identity (NODEBUN_IMAGE_VERSION)
dockernodebun --list | -l        # tool names (this image + zsh)
dockernodebun --list --version | -l -v
dockernodebun runtimes --version | runtimes -v
dockernodebun node --version | node -v
```

| Id | Where | Section |
|---|---|---|
| `nodebun` | this image | Intro (PATH at build, no ENTRYPOINT, TTY vs keep-alive) |
| `runtimes` | this image | `node`, `npm`, `npx`, `bun`, `fnm` |
| `helpers` | this image | `in-bash`, `in-sh`, `only-in-container`, `skip-if-container` |
| `env` | this image | `NODE_DEFAULT_VERSION`, `FNM_*`, `BUN_*`, `IS_INTO_CONTAINER` |
| `shells`, `listing`, `edit`, `archives`, `network`, `system`, `extras`, `helpers`, `fonts` | zsh base | Same ids as [`dockerzsh --sections`](https://github.com/CartagoGit/DockerZsh#catalogue-cli-dockerzsh) — full tool list in [zsh README — Utilities](https://github.com/CartagoGit/DockerZsh#utilities) |
| `zsh-helpers` | zsh base | `add_text_to_zshrc`, `add_text_to_p10k`, `share_config_globally`, `sudo-password`, `sudo-nopasswd`, `git-from-host`, `dockerzsh` |

`--helpers` on **this** CLI is NodeBun. zsh helpers: `dockernodebun --zsh-helpers` or `dockerzsh --helpers`. Unknown ids exit `2`.

---

## 🧱 Child image

```dockerfile
FROM cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install
```

Keep `SHELL ["/bin/sh", "-c"]` if you override it (`cartagodocker/zsh:v2.0.0` already sets it).

---

## 🚀 Build and publish

```bash
docker build \
    --build-arg VERSION=2.0.0 \
    --build-arg NODE_DEFAULT_VERSION=26.3.1 \
    --build-arg BUN_VERSION=1.3.14 \
    --build-arg FNM_VERSION=1.39.0 \
    --build-arg NPM_VERSION=12.0.1 \
    -t cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./
```

The GitHub workflow fills those from `.github/matrices.yml`.

GitHub Actions (secrets `DOCKERHUB_USERNAME`, `DOCKERHUB_PASSWORD`; variable `DOCKERHUB_REPO`):

| Trigger | What happens |
|---|---|
| Git tag `v{X.Y.Z}` | One Hub tag per **active** matrix if new (skip existing) + GitHub Release for `v{X.Y.Z}` (replaced if it exists) — [docker-hub-update.yml](./.github/workflows/docker-hub-update.yml) |
| Git tag `v{X.Y.Z}_n…_b…` | That matrix only. Skip Hub if the tag exists. GitHub Release for that matrix tag (replaced if it exists; not latest). No Hub `:latest`. |
| Push to `main` that changes `README.md` | Hub long description (`full_description` ≤ ~25 000 chars) — [update-dockerhub-description.yml](./.github/workflows/update-dockerhub-description.yml) |

```bash
git tag v2.0.1
git push origin main v2.0.1
```

See [CHANGELOG.md](./CHANGELOG.md) and [VERSIONING.md](./VERSIONING.md).
