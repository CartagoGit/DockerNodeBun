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

- Base image: `cartagodocker/zsh:v1.0.2` (pinned for reproducibility)
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
`v1.0.1_n22.21.1_b1.3.14` or `v1.0.1_n26.3.1_b1.3.14`).

See [VERSIONING.md](./VERSIONING.md) for the tag-naming policy and
how to add a new matrix.

## Tagging model

The canonical tag format is:

```text
v{X.Y.Z}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Examples:

- `v1.0.1_n26.3.1_b1.3.14`
- `v1.0.1_n28.0.0_b1.5.0`

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

- We publish exact tags like `v1.0.1_n26.3.1_b1.3.14`.
- We do not publish `latest`.
- We do not publish `stable`.

That is intentional. Consumers must pin the exact runtime matrix they require.

## Environment variables exposed by the image

- `NODE_DEFAULT_VERSION=26.3.1`
- `FNM_HOME=/usr/share/fnm`
- `BUN_HOME=/usr/share/bun`
- `BUN_INSTALL=/usr/share/bun`

## How the image works

### Node activation

Node is installed through `fnm` and activated with:

```bash
eval $(fnm env)
fnm use ${NODE_DEFAULT_VERSION}
```

This must be done in any Docker `RUN` step where `node` or `npm` is needed,
because `fnm` wires them into `PATH` at shell runtime.

### Bun runtime

Bun is installed in `/usr/share/bun`.

The image ships two Bun binaries:

- an AVX2-optimized x64 binary
- a baseline x64 binary

The wrapper selects the correct one at runtime depending on CPU capabilities.

### npm

`npm` is pinned explicitly after the selected Node runtime is activated.
That keeps the container runtime deterministic even when Node bundles change.

## Typical usage

### Build the image locally

```bash
# X.Y.Z (correcciones del repo) viene del ARG VERSION del Dockerfile.
# Lo puedes override por CLI sin editar el Dockerfile:
docker build \
    --build-arg VERSION=1.0.1 \
    -t cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./
```

`docker inspect cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14 | grep VERSION`
muestra `VERSION=1.0.1` como fuente de verdad de las correcciones
del repo aplicadas a esa imagen.

### Verify the runtime matrix locally

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14 \
    -lc 'eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION} >/dev/null 2>&1 \
        && node --version && npm --version && bun --version && fnm --version'
```

Expected output:

- `v26.3.1`
- `12.0.1`
- `1.3.14`
- `fnm 1.39.0`

### Start an interactive container

```bash
docker run --rm -it cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14
```

### Run the image as a non-root user

```bash
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14
```

### Use it as a base image

```dockerfile
FROM cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14

RUN eval $(fnm env) \
        && fnm use ${NODE_DEFAULT_VERSION} \
        && node --version \
        && npm --version \
        && bun --version
```

## Structural breakpoints (repo milestones)

A **breakpoint** is a structural marker on the repo itself, not on DockerHub. It tags a
specific commit that represents a **structural break** of how the repo works (a major
refactor, a contract change, a new architecture) — orthogonal to the runtime/runtime
versioning.

Breakpoints are pure **git tags** with the format:

```text
breakpoint_v{X.Y.Z}
```

They always point to the **same commit** as `v{X.Y.Z}` — the VERSION embedded in the
tag tells you which release introduced that structural break.

### Why breakpoints exist

In 10 years, when someone asks "how did the publishing model change over time?", they can:

```bash
git log --oneline --tags='breakpoint_*' --topo-order
```

and see every structural break in chronological order, with the VERSION at the time and
the commit message explaining what changed.

### How to create a breakpoint

When you tag a release `v1.0.1` that you consider a structural break:

```bash
scripts/tag-breakpoint.sh 1.0.1 "New publishing model: tag trigger + manifesto"
git push origin v1.0.1 breakpoint_v1.0.1
```

The script refuses to create a duplicate breakpoint tag (you'd have to delete and
re-create if the version changes after the fact).

The CI workflow does not auto-create breakpoints and does not remind you to do so.
The decision is fully human — when you tag a structural break, you decide whether
it deserves a breakpoint tag.

### Listing breakpoints

```bash
git tag -l 'breakpoint_*'           # all breakpoint tags, newest first
git log --oneline breakpoint_v1.0.1  # see the structural commit
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
    -t cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./

# Verify the four runtimes are wired correctly
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v1.0.1_n26.3.1_b1.3.14 \
    -lc 'eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION} >/dev/null 2>&1 \
        && node --version && npm --version && bun --version && fnm --version'
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
