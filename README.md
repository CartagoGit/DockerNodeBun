# DockerNodeBun

`cartagodocker/nodebun` is the Beateam base image for Node/Bun development containers.
It reflects how our containers are actually used in real projects:

- `zsh` as the default interactive shell and entrypoint
- `fnm` to activate the selected Node runtime inside the container
- `bun` as the default package manager and TypeScript script runner
- explicit, reproducible image tags for each runtime matrix

This image is consumed directly by internal containers such as the `logistics-app`
build runner.

## Repository and registry

- GitHub: https://github.com/CartagoGit/DockerNodeBun
- Docker Hub: https://hub.docker.com/repository/docker/cartagodocker/nodebun/general

## Base image

- Base image: `cartagodocker/zsh:v1.0.5` (pinned for reproducibility)
- OS family: Ubuntu 24.04
- The zsh image provides `zsh`. Our `Dockerfile` adds `sudo`,
  `ca-certificates`, bun, fnm, node, and npm on top.

## Current runtime matrices

The repository publishes images for the following runtime matrices,
defined in [`.github/matrices.yml`](./.github/matrices.yml):

| Matrix | Node | Bun | npm | fnm | Status | Use case |
|---|---|---|---|---|---|---|
| `n22.21.1_b1.3.14` | `22.21.1` | `1.3.14` | `10.9.4` | `1.38.1` | active | LTS consumers (e.g. `logistics-app`) |
| `n26.3.1_b1.3.14` | `26.3.1` | `1.3.14` | `12.0.1` | `1.39.0` | active | Canonical matrix (future lx-app slice S3) |

All active matrices share the same wrapper fixes (exit code propagation,
global-install detection, stderr logging) because the workflow builds
them from the same `Dockerfile` at the same git tag. To consume a
specific matrix, pin its exact tag (e.g.
`v2.0.0_n22.21.1_b1.3.14` or `v2.0.0_n26.3.1_b1.3.14`).

See [VERSIONING.md](./VERSIONING.md) for the tag-naming policy and
how to add a new matrix.

## Tagging model

The canonical tag format is:

```text
v{X.Y.Z}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Examples:

- `v2.0.0_n26.3.1_b1.3.14`
- `v2.0.0_n28.0.0_b1.5.0`

Meaning:

- `X.Y.Z` is a semver-light counter of repo corrections (Dockerfile,
  wrapper, workflows, docs). Published in parallel across all matrices.
- `n..._b...` is the runtime matrix (node + bun versions).

To publish a new set of images, push a single `v{X.Y.Z}` trigger tag in
`main`. The workflow reads `.github/matrices.yml` and builds + pushes
one image per active matrix. To publish a single matrix (e.g. to
re-push after a transient failure), push `v{X.Y.Z}_{matrix-name}`
directly.

For the full policy, see [VERSIONING.md](./VERSIONING.md).

## Published image contract

Images are published with exact tags only.

- We publish exact tags like `v2.0.0_n26.3.1_b1.3.14`.
- We do not publish `latest`.
- We do not publish `stable`.

That is intentional. Consumers must pin the exact runtime matrix they require.

## Environment variables exposed by the image

- `NODE_DEFAULT_VERSION` — matrix Node (e.g. `22.21.1` / `26.3.1`)
- `FNM_HOME=/usr/share/fnm`
- `FNM_DIR=/usr/share/fnm/store`
- `FNM_BIN=/usr/share/fnm/bin`
- `BUN_HOME=/usr/share/bun`
- `BUN_INSTALL=/usr/share/bun`
- `IS_INTO_CONTAINER=true`

Login shells (`su -`, `bash -l`) drop Docker `ENV`. `/etc/profile.d/nodebun.sh`
re-exports the same variables. The bun wrapper also falls back to
`BUN_HOME=/usr/share/bun` if the env is empty.

## How the image works

### Node, npm, bun, fnm — baked at build, not at start

The matrix (`node` / `bun` / `fnm` / `npm` from `.github/matrices.yml`) is
**installed during `docker build`**. `docker run` / `docker exec` do not
download anything.

| Tool | Installed at build | Activated at start |
|---|---|---|
| Node | `fnm install ${NODE_DEFAULT_VERSION}` into `FNM_DIR` | `/usr/local/bin/node` (any shell). zsh also `eval "$(fnm env --shell zsh)"` + `fnm use ${NODE_DEFAULT_VERSION}` |
| npm | `npm install -g npm@${NPM_VERSION}` on that Node | `/usr/local/bin/npm` |
| bun | AVX2 + baseline zips into `/usr/share/bun` | `/usr/local/bin/bun` (wrapper) |
| fnm | release binary into `/usr/share/fnm/bin` | `/usr/local/bin/fnm`; zsh loads `fnm env` |

`fnm default` + `fnm env` follow the [official fnm shell setup](https://github.com/Schniz/fnm#shell-setup).
`fnm env` must run **per shell** (it dies with the process). The Dockerfile
`eval` during `RUN` only exists so `npm i -g` works at build time.

### Any uid, any shell, new users

- Store: `FNM_DIR=/usr/share/fnm/store` (`777`, same as bun). Any uid can
  `fnm install` / `fnm use`.
- Homes + `/etc/skel`: `~/.local/share/fnm` → that store. `useradd -m`
  inherits it.
- `sudo` **without a password by default** (`ALL ALL=(ALL:ALL) NOPASSWD:ALL`).
  Compose `user: 1000:1000` drops supplementary groups, so `%sudo` is
  not enough. Optional password is **not** baked into the image.
- PATH fallback: `/usr/local/bin/{node,npm,npx,fnm,bun}` so `sh`/`bash`
  without `.zshrc` still work (CI, compose `command:`, `docker exec -u 1000`).
- Switching versions is opt-in **for that session**:

```bash
fnm install 20.19.0
fnm use 20.19.0   # this shell only; a new shell is back on the matrix
```

### POSIX helpers (zsh is the default shell)

From an interactive zsh, run a bash/sh snippet that is not zsh-safe:

```bash
in-bash                         # interactive bash with login env
in-bash -c 'set -o pipefail; …' # bash-only
in-sh -c 'case $1 in … esac'    # POSIX sh
```

Skip (or require) a command depending on whether we are inside the
container (`/.dockerenv` or `IS_INTO_CONTAINER=true`):

```bash
skip-if-container adb start-server   # no-op inside; runs on the host
only-in-container bun run test       # only inside
only-in-container && echo in-docker  # predicate, exit 0/1
```

### sudo

Passwordless by default for **every** uid (including compose
`user: 1000:1000`). `node`/`npm`/`bun` do not need it. The boundary is
whether you type `sudo`. Optional password is runtime-only.

Opt-in password **at start** (not in the image):

```bash
docker run --rm -it -e SUDO_PASSWORD=secret cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14
```

Or **inside** the container:

```bash
sudo -n id                 # default: no password
sudo-password              # prompt; afterwards sudo asks for it
sudo-password 'secret'     # same, from arg (visible in ps)
sudo sudo-nopasswd         # back to NOPASSWD (needs the password)
```

### Bun runtime

Bun lives in `/usr/share/bun`. Two binaries (AVX2 + baseline); the wrapper
picks one from `/proc/cpuinfo`. Global installs (`bun add -g`) chmod 777
the share folder when run as root/sudoer.

### npm

`npm` is pinned after the matrix Node is activated, so the container
runtime stays deterministic even when Node's bundled npm changes.

## Typical usage

### Build the image locally

```bash
# X.Y.Z (correcciones del repo) viene del ARG VERSION del Dockerfile.
# Lo puedes override por CLI sin editar el Dockerfile:
docker build \
    --build-arg VERSION=1.0.1 \
    -t cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./
```

`docker inspect cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 | grep VERSION`
muestra `VERSION=1.0.1` como fuente de verdad de las correcciones
del repo aplicadas a esa imagen.

### Verify the runtime matrix locally

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -lc 'node --version && npm --version && bun --version && fnm --version'
docker run --rm --user 1000:1000 --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -lc 'node --version && npm --version && bun --version && fnm list'
```

Expected output:

- `v26.3.1`
- `12.0.1`
- `1.3.14`
- `fnm 1.39.0`

### Start an interactive container

```bash
docker run --rm -it cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
```

### Run the image as a non-root user

```bash
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14
```

### Use it as a base image

```dockerfile
FROM cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14

RUN node --version \
        && npm --version \
        && bun --version
```

## Structural milestones

Major repo changes (contract breaks, big refactors, new architectures) are recorded in
the **`X` (major) of the semver-light `X.Y.Z` counter**, not in a parallel tag. A bump
of the major digit (e.g. `1.x.x` → `2.0.0`) is the visible signal that the repo's
internals changed in a non-backward-compatible way.

To find historical major changes:

```bash
git tag -l 'v[2-9]*.0.0'             # all releases with a major bump
cat CHANGELOG.md                     # human description of what changed
```

## Publishing workflow

Publishing is split into two separate workflows.

### 1. Image publication

Workflow: [`.github/workflows/docker-hub-update.yml`](./.github/workflows/docker-hub-update.yml)

- Trigger: push of a git tag matching `v*` (or `workflow_dispatch` with a `tag_name` input)
- Behavior on `v{X.Y.Z}` (trigger tag): reads [`.github/matrices.yml`](./.github/matrices.yml) and
  builds + pushes one image per active matrix, each tagged as `v{X.Y.Z}_{matrix-name}`.
- Behavior on `v{X.Y.Z}_n..._b...` (matrix tag): builds + pushes only that specific image.
- Behavior: does not create or update `latest`.
- Idempotent: existing DockerHub tags are detected and skipped (no-op).

The matrix list is the **single source of truth** — adding/removing a matrix is a commit to
`.github/matrices.yml`, no code changes required.

### 2. Docker Hub description sync

Workflow: [`.github/workflows/update-dockerhub-description.yml`](./.github/workflows/update-dockerhub-description.yml)

- Trigger: push to `main` when `README.md` changes
- Behavior: updates the Docker Hub long description from this README

This is why the README must always describe the real image contract. Docker Hub
mirrors it directly.

## Recommended release sequence

El flujo normal es taggear → el workflow publica automáticamente.
NO hay que mergear ramas manualmente: el manifesto `.github/matrices.yml`
es la única fuente de verdad de qué imágenes se publican.

### Opción A: tag trigger (recomendada, publica todas las matrices)

```bash
# 1. Bump del VERSION en el Dockerfile (X.Y.Z)
#    Editar: ARG VERSION=1.0.1  ->  ARG VERSION=1.0.2
# 2. Commitear el bump en main
git commit -am "chore: bump VERSION to 1.0.2"
# 3. Tag trigger (sin sufijo de matriz)
git tag v1.0.2
git push origin main v1.0.2
# 4. El workflow lee .github/matrices.yml y publica N imágenes:
#    v1.0.2_n22.21.1_b1.3.14
#    v1.0.2_n26.3.1_b1.3.14
#    (una por cada matriz con status: active)
```

### Opción B: tag matrix (re-publicar una sola matriz)

Útil si quieres re-pushear una imagen específica tras un fallo
transitorio, o si quieres saltarte el manifesto del:

```bash
git tag v1.0.2_n26.3.1_b1.3.14
git push origin v1.0.2_n26.3.1_b1.3.14
# Solo publica v1.0.2_n26.3.1_b1.3.14 (el resto del manifesto
# NO se publica).
```

### Smoke-test local antes de taggear

```bash
# X.Y.Z (correcciones del repo) viene del ARG VERSION del Dockerfile.
# Lo puedes override por CLI sin editar el Dockerfile:
docker build \
    --build-arg VERSION=1.0.1 \
    -t cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./

# Verify the four runtimes are wired correctly (no fnm activation needed)
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -lc 'node --version && npm --version && bun --version && fnm --version'
docker run --rm --user 1000:1000 --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 \
    -lc 'node --version && npm --version && bun --version && fnm list'
```

## Versioning

El contador `X.Y.Z` se declara como `ARG VERSION` en el Dockerfile y es
**single source of truth** del contador de correcciones del repo.
Ver [VERSIONING.md](./VERSIONING.md) para la política completa:

- `X` (major): cambios incompatibles (drop de runtime, cambio de base).
- `Y` (minor): features compatibles (nuevas matrices, nuevas flags).
- `Z` (patch): bugfixes puros.

El workflow parsea `X.Y.Z` del tag con bash regex
(`^v([0-9]+\.[0-9]+\.[0-9]+)_`) y lo pasa como `--build-arg VERSION`
al build. Para bumpear:

1. Editar el `ARG VERSION` en el Dockerfile.
2. Commitear en `main`.
3. Pushear el tag trigger `v{X.Y.Z}` — el workflow publica N imágenes.

No hay ramas de matriz que mantener — el workflow lee las versiones de
runtime de `.github/matrices.yml`. Añadir/quitar una matriz es un commit
al manifiesto, sin tocar código.

## Legacy tags

Legacy semver-like tags such as `v.1.1.2` remain available for historical
consumers, but they are no longer the canonical contract for this image.

## Canonical consumer

The canonical consumer in this workspace family is:

- `logistics-app/tools/docker/Dockerfile`

That consumer must always be updated to the exact `nodebun` tag that matches the
runtime matrix it expects.
