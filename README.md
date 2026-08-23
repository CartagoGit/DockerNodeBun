# 🟢 cartagodocker/nodebun

**Node**, **npm**, **bun**, and **fnm** on top of
[`cartagodocker/zsh`](https://hub.docker.com/r/cartagodocker/zsh)
(Ubuntu **24.04 LTS** + zsh + Oh My Zsh + Powerlevel10k).

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

---

## 📦 What's in the image

| | Piece | Notes |
|---|---|---|
| 🐧 | OS | Ubuntu 24.04 LTS — from [`cartagodocker/zsh`](https://hub.docker.com/r/cartagodocker/zsh) |
| 📌 | zsh pin | **`cartagodocker/zsh:v1.0.6`** (publish zsh first, then this image) |
| 🐚 | Interactive shell | zsh + Oh My Zsh + Powerlevel10k — `CMD zsh`, **no ENTRYPOINT** (zsh ≥ 1.0.6) |
| 🟢 | Node / npm / bun / fnm | Installed at **build**; on `PATH` for every uid and every shell |
| 🧰 | Small CLI | Inherited from zsh (`dockerzsh --help`): eza, bat, fd, rg, jq, nano, unzip, … |
| 📖 | Catalogue | `dockernodebun --help` — runs `dockerzsh` then lists NodeBun extras |
| 🔐 | sudo | Inherited from zsh (NOPASSWD + `sudo-password`). Not reinstalled here |
| 🌐 | Network | git, curl, **`ca-certificates`** from zsh (not reinstalled here) |

This Dockerfile **does not overwrite** zsh’s `sudo-password` / `sudo-nopasswd` when the base already has them. Fallback lives in `/usr/local/share/nodebun-sudo-fallback/` and is copied to `PATH` only if the base has no `sudo-password`.

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

`X.Y.Z` counts repo corrections (Dockerfile, wrapper, docs) and is published on **all** active matrices in parallel.

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

zsh extras (prompt, `ls` → eza, `bat`) load from `~/.zshrc` and need a **TTY**.

### 🖥️ Interactive prompt (eza, bat, p10k)

```bash
docker run --rm -it cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
```

eza / bat / p10k work here. `node`, `npm`, `bun` work in every shell.

### 🧊 Keep-alive (Compose)

```yaml
services:
  dev:
    image: cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
    command: ["tail", "-f", "/dev/null"]
    user: "1000:1000"
    working_dir: /work
    volumes:
      - .:/work
```

That process is **`tail`, not zsh**. No prompt, no eza aliases. The container stays up so you can attach:

```bash
docker compose exec dev zsh          # prompt + eza + bat + p10k
docker compose exec dev bash         # bash; node/npm/bun still on PATH
docker compose exec dev bun install
```

```bash
docker run --rm cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 node --version
```

Publish **zsh v1.0.6 to Hub first**. Building this image against Hub `zsh:v1.0.5` still inherits `ENTRYPOINT ["zsh"]` (`can't open input file: node`). After zsh 1.0.6 is on Hub, that command works without `--entrypoint`.

---

## 🔐 sudo

Passwordless by default for every uid, including Compose `user: 1000:1000` (rule is `ALL`, not `%sudo`). `node` / `npm` / `bun` do not need it.

```bash
docker run --rm -it -e SUDO_PASSWORD=secret cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
# inside:
sudo -n id
sudo-password              # prompt
sudo-nopasswd              # back to NOPASSWD
```

---

## 🌍 Environment

| Variable | Meaning |
|---|---|
| `NODE_DEFAULT_VERSION` | Matrix Node |
| `FNM_HOME` / `FNM_DIR` / `FNM_BIN` | `/usr/share/fnm`, store, bin |
| `BUN_HOME` / `BUN_INSTALL` | `/usr/share/bun` |
| `IS_INTO_CONTAINER` | `true` |
| `VERSION` | Repo `X.Y.Z` (`docker inspect` / `--build-arg VERSION`) |

Login shells (`su -`, `bash -l`) drop Docker `ENV`. `/etc/profile.d/nodebun.sh` re-exports the same variables.

`FNM_DIR` is `777` (same idea as bun): any uid can `fnm install` / `fnm use`. Homes and `/etc/skel` get `~/.local/share/fnm` → that store.

```bash
fnm install 20.19.0
fnm use 20.19.0    # this shell only; a new shell is back on the matrix
```

---

## 🧩 Helpers (optional)

Most people never type these. `bash pepe.sh` is enough. They exist so the **same** Makefile can run on the host and inside the container.

| Command | What it does |
|---|---|
| `in-bash` / `in-bash pepe.sh` | `bash --login` (loads `profile.d`). When a snippet is not zsh-safe. |
| `in-sh` | POSIX `sh -l` |
| `only-in-container bun test` | Runs **only inside** the container |
| `skip-if-container adb start-server` | Runs **only on the host** |

They detect `/.dockerenv` or `IS_INTO_CONTAINER=true`.

---

## 🎨 Fonts and icons

Same contract as [cartagodocker/zsh](https://hub.docker.com/r/cartagodocker/zsh):

| | What | Needs on the host |
|---|---|---|
| 🔷 | Powerlevel10k / eza icons | A [Nerd Font](https://www.nerdfonts.com/font-downloads) |
| 🐳 | Prompt whale | An **emoji** font (Segoe / Apple / Noto). Some Linux terminals have none. |

```json
"terminal.integrated.fontFamily": "'Cascadia Code NF', 'CaskaydiaCove Nerd Font', Consolas, monospace"
```

---

## 🧱 Child image

```dockerfile
FROM cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install
```

Keep `SHELL ["/bin/sh", "-c"]` (this Dockerfile already sets it; zsh v1.0.5 defaults to `zsh -c`).
Child images that need `docker run image node` should set `ENTRYPOINT []` themselves, or wait for a NodeBun that pins zsh ≥ 1.0.6.

---
if you override it (zsh 1.0.6 already sets it)

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

- `X` major — incompatible (drop a runtime, change of base family)
- `Y` minor — compatible features (new matrix)
- `Z` patch — bugfixes

Full policy: [VERSIONING.md](./VERSIONING.md). History: [CHANGELOG.md](./CHANGELOG.md).
