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
| 📂 | Listing / pager | Inherited: `eza`, `bat`, `fd`, `rg`, `nnn`, `ncdu`/`duf` |
| 🧰 | Daily CLI | Inherited from zsh (`dockerzsh --help`). **Not** reinstalled here |
| 📖 | Catalogue | `dockernodebun --help` — zsh catalogue, then NodeBun extras (see [Catalogue CLI](#catalogue-cli-dockernodebun)) |
| 🌐 | Network | Inherited: `curl`, `wget`, `git`, **`openssh-client`** (no sshd), **`ca-certificates`** |
| 🔐 | sudo | Inherited (NOPASSWD + `sudo-password`). Not overwritten when the base already has it |
| 🌍 | Locale | Inherited: `LANG=C.UTF-8` · `LC_ALL=C.UTF-8` |
| 🧱 | Build `SHELL` | `["/bin/sh", "-c"]` — same as zsh |

There is **no** `openssh-server`. There is **no** `ENTRYPOINT`: the process you pass to `docker run` / Compose `command:` is what runs (`node --version` works on zsh 2.0.0).

**Not in this image** (same rule as zsh): `gcc`/`g++`, `python3`, `neovim`, `git-lfs`, `rclone`, `locales`, `man-db`, `nmap`, **no sshd**, **no Docker** (`dockerd` / `docker` CLI). NodeBun does **not** add a second CLI kit. It only adds runtimes: `fnm`, one Node (matrix), `npm`, **two** bun binaries (AVX2 + baseline), `libatomic1`. Put compilers — or a Docker client — in a **further** child. Drive this container with `docker` on the **host**.

sudo / `dockerzsh` / `add_text_to_*` come from **`cartagodocker/zsh:v2.0.0`**. This image does not reinstall them and has no fallback for older zsh tags.

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
| **Whole tag** (Hub 2.0.0 on zsh 1.0.5, Node 22) | **~642 MB** | Hub layers (not listed for every matrix) |

Two bun builds are on purpose: `/usr/local/bin/bun` is a **bash** wrapper (`bun_wrapper.zsh` — historical `.zsh` name, `#!/bin/bash` shebang) that picks AVX2 vs baseline from `/proc/cpuinfo`. That **doubles** bun on disk. The wrapper is silent unless `BUN_WRAPPER_DEBUG=1`. One Node version is baked (`fnm install` of the matrix); extra `fnm install` at runtime grows `FNM_DIR`.

After zsh 2.0.0 is on Hub, expect NodeBun disk ≈ zsh 2.0.0 + ~350–450 MB (Node + two bun + fnm), around **~600–700 MB** uncompressed — same ballpark as Hub NodeBun 2.0.0 (~642 MB), plus the zsh CLI extras.

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

Node / bun / npm / fnm are **baked at `docker build`**. `docker run` does not download them. They live on `PATH` (`/usr/local/bin`) for **any** uid and **any** shell.

| Tool | At build | At start |
|---|---|---|
| Node | `fnm install` → `FNM_DIR=/usr/share/fnm/store` | `/usr/local/bin/node` |
| npm | `npm install -g npm@…` | `/usr/local/bin/npm` |
| bun | AVX2 + baseline zips; wrapper reads `/proc/cpuinfo` | `/usr/local/bin/bun` |
| fnm | release zip | `/usr/local/bin/fnm` |

zsh extras (prompt, `ls` → eza, `bat`) load from `~/.zshrc` and need a **TTY**. `node` / `npm` / `bun` do not.

### 🖥️ Interactive prompt (eza, bat, p10k)

Needs a **TTY** (`-it` or `exec -it`).

```bash
docker run --rm -it cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
docker exec -it <container> zsh
```

`ls` → eza with icons/colors. `bat` works. Powerlevel10k draws the prompt. `node`, `npm`, `bun` work in every shell. Inside zsh you can still `bash`, `sh`, `exit`.

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

Inherited from zsh. Global files (`/usr/share/globally/.zshrc`) are `644` root:root. uid `1000` cannot overwrite them directly — that is intentional. Use `sudo` or `add_text_to_zshrc` (it escalates with NOPASSWD). `node` / `npm` / `bun` do not need sudo.

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

Without a Nerd Font you get boxes on powerline / `ls` icons. That is not an image bug.

---

## 🧩 Scripts for child images

### From zsh (inherited)

`add_text_to_zshrc`, `add_text_to_p10k`, `share_config_globally` — same CLI as [zsh](https://github.com/CartagoGit/DockerZsh#scripts-for-child-images). They write `/usr/share/globally/...` and `sudo` if needed. Full text: `dockerzsh --helpers` or `dockernodebun --zsh-helpers`.

### NodeBun only

Most people never type these. `bash pepe.sh` is enough. They exist so the **same** Makefile can run on the host and inside the container.

| Command | What it does |
|---|---|
| `in-bash` / `in-bash pepe.sh` | `bash --login` (loads `profile.d`). When a snippet is not zsh-safe. |
| `in-sh` | POSIX `sh -l` |
| `only-in-container bun test` | Runs **only inside** the container |
| `skip-if-container adb start-server` | Runs **only on the host** |

They detect `/.dockerenv` or `IS_INTO_CONTAINER=true`. Full text: `dockernodebun --helpers`.

---

## 🔑 SSH (client only — no sshd)

Inherited from zsh. Bind-mount host `~/.ssh` and type `ssh` / `git`. Root or any uid — one volume is enough. **Git author is not the SSH key:** bind `~/.gitconfig` too (or set `GIT_AUTHOR_NAME` + `GIT_AUTHOR_EMAIL`). Full contract (`known_hosts`, wrappers, missing keys): [zsh README — SSH](https://github.com/CartagoGit/DockerZsh#ssh-client-only--no-sshd).

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

`${USER}` is the **host** name. Docker needs an **absolute** target (`/${USER}/.ssh`), not `${USER}/.ssh`. This is not SSH-into-the-container. Attach from the host: `docker exec -it … zsh`.

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

Login shells (`su -`, `bash -l`) drop Docker `ENV`. `/etc/profile.d/nodebun.sh` re-exports the NodeBun variables (zsh already ships UTF-8 via `zsh-image.sh`).

`FNM_DIR` is `777` (same idea as bun): any uid can `fnm install` / `fnm use`. Homes and `/etc/skel` get `~/.local/share/fnm` → that store.

```bash
fnm install 20.19.0
fnm use 20.19.0    # this shell only; a new shell is back on the matrix
```

---

## 📖 Catalogue CLI (`dockernodebun`)

Inside a running container this image ships **`dockernodebun`**: the zsh catalogue first (`dockerzsh --help`), then NodeBun extras. It is not the host `docker` CLI.

```bash
docker run --rm cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 dockernodebun --help
docker compose exec app dockernodebun --help
```

The full dump is long on purpose. Filter by **section**. NodeBun ids stay here; zsh ids are forwarded to `dockerzsh`.

```bash
dockernodebun --sections | -s    # zsh ids + NodeBun ids
dockernodebun --runtimes         # node / npm / bun / fnm
dockernodebun --helpers          # in-bash, only-in-container, …
dockernodebun --zsh-helpers      # add_text_to_zshrc, sudo-password, … (zsh)
dockernodebun --env              # NODE_DEFAULT_VERSION, FNM_DIR, …
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
| `runtimes` | this image | `node` / `npm` / `npx` / `corepack` / `bun` / `fnm` |
| `helpers` | this image | `in-bash`, `in-sh`, `only-in-container`, `skip-if-container` |
| `env` | this image | `NODE_DEFAULT_VERSION`, `FNM_*`, `BUN_*`, `IS_INTO_CONTAINER` |
| `shells`, `listing`, `network`, … | zsh base | Same ids as [`dockerzsh --sections`](https://github.com/CartagoGit/DockerZsh#catalogue-cli-dockerzsh) |
| `zsh-helpers` | zsh base | zsh image helpers (`dockerzsh --helpers`) |

`--helpers` on **this** CLI is NodeBun. zsh’s `add_text_to_zshrc` / `sudo-password` are `dockernodebun --zsh-helpers` or `dockerzsh --helpers`. Unknown ids exit `2`.

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
| Git tag `v{X.Y.Z}` | One Hub tag per **active** matrix — [docker-hub-update.yml](./.github/workflows/docker-hub-update.yml) |
| Git tag `v{X.Y.Z}_n…_b…` | That matrix only. No `latest`. Idempotent. |
| Push to `main` that changes `README.md` | Docker Hub long description — [update-dockerhub-description.yml](./.github/workflows/update-dockerhub-description.yml) |

```bash
git tag v2.0.1
git push origin main v2.0.1
```

See [CHANGELOG.md](./CHANGELOG.md) and [VERSIONING.md](./VERSIONING.md).
