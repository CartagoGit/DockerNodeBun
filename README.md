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

## Current runtime matrix

The repository currently ships **two parallel runtime matrices**, each
maintained on its own branch:

| Branch | Node | Bun | npm | fnm | Status |
|---|---|---|---|---|---|
| `n26.3.1_b1.3.14` | `26.3.1` | `1.3.14` | `12.0.1` | `1.39.0` | Canonical matrix (futuro lx-app slice S3) |
| `n22.21.1_b1.3.14` | `22.21.1` | `1.3.14` | `10.9.4` | `1.38.1` | LTS consumers (e.g. `logistics-app`) |

Both branches share the same wrapper fixes (exit code propagation,
global-install detection, stderr logging). To consume either, pin the
corresponding tag (e.g. `v1.0.0_n22.21.1_b1.3.14` or `v1.0.0_n26.3.1_b1.3.14`).

See [VERSIONING.md](./VERSIONING.md) for the tag-naming policy and
how to add a new matrix.

## Tagging model

The canonical tag format is:

```text
v{N}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Examples:

- `v1.0.0_n26.3.1_b1.3.14`
- `v1.0.0_n28.0.0_b1.5.0`

Meaning:

- `N` is a republish counter for the same runtime matrix.
- If Node or Bun changes, the counter resets to `v1`.
- If the runtime matrix stays the same but the image is republished
    (workflow fix, packaging fix, container-contract fix, etc.), the counter
    increases to `v2`, `v3`, and so on.

For the full policy, see [VERSIONING.md](./VERSIONING.md).

## Published image contract

Images are published with exact tags only.

- We publish exact tags like `v1.0.0_n26.3.1_b1.3.14`.
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
    --build-arg VERSION=1.0.0 \
    -t cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14 \
    -f ./Dockerfile ./
```

`docker inspect cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14 | grep VERSION`
muestra `VERSION=1.0.0` como fuente de verdad de las correcciones
del repo aplicadas a esa imagen.

### Verify the runtime matrix locally

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14 \
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
docker run --rm -it cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14
```

### Run the image as a non-root user

```bash
docker run --rm -it --user 1000:1000 cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14
```

### Use it as a base image

```dockerfile
FROM cartagodocker/nodebun:v1.0.0_n26.3.1_b1.3.14

RUN eval $(fnm env) \
        && fnm use ${NODE_DEFAULT_VERSION} \
        && node --version \
        && npm --version \
        && bun --version
```

## Publishing workflow

Publishing is split into two separate workflows.

### 1. Image publication

Workflow: [`.github/workflows/docker-hub-update.yml`](./.github/workflows/docker-hub-update.yml)

- Trigger: push of a git tag matching `v*`
- Behavior: builds and pushes only the exact tag that was pushed
- Behavior: does not create or update `latest`

### 2. Docker Hub description sync

Workflow: [`.github/workflows/update-dockerhub-description.yml`](./.github/workflows/update-dockerhub-description.yml)

- Trigger: push to `main` when `README.md` changes
- Behavior: updates the Docker Hub long description from this README

This is why the README must always describe the real image contract. Docker Hub
mirrors it directly.

## Recommended release sequence

El flujo normal es taggear → el workflow publica. Pero si quieres
probar en local antes:

```bash
# Reemplaza X.Y.Z por la version de correcciones que quieras
# (debe coincidir con ARG VERSION del Dockerfile) y la matriz por
# la rama activa. El tag final sigue el formato v{X.Y.Z}_n..._b...
#
# Ejemplo: v1.0.0 (correcciones) + n26.3.1_b1.3.14 (matriz).
PLACEHOLDER_TAG=v1.0.0_n26.3.1_b1.3.14
VERSION=1.0.0

# 1. Build con --build-arg VERSION para que la imagen lo exponga
docker build \
    --build-arg VERSION="$VERSION" \
    -t "cartagodocker/nodebun:$PLACEHOLDER_TAG" \
    -f ./Dockerfile ./

# 2. Smoke-test: verify the four runtimes are wired correctly
docker run --rm --entrypoint /bin/sh \
    "cartagodocker/nodebun:$PLACEHOLDER_TAG" \
    -lc 'eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION} >/dev/null 2>&1 \
        && node --version && npm --version && bun --version && fnm --version'

# 3. Tag and push (el workflow publica en DockerHub)
git tag "$PLACEHOLDER_TAG"
git push origin "$PLACEHOLDER_TAG"
```

## Versioning

El contador `X.Y.Z` se declara como `ARG VERSION` en el Dockerfile.
Ver [VERSIONING.md](./VERSIONING.md) para la política completa:

- `X` (major): cambios incompatibles (drop de runtime, cambio de base).
- `Y` (minor): features compatibles (nuevas matrices, nuevas flags).
- `Z` (patch): bugfixes puros.

El workflow parsea `X.Y.Z` del tag (`sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/'`)
y lo pasa como `--build-arg VERSION` al build. Para bumpear: editar el
`ARG VERSION` en el Dockerfile, mergear en todas las ramas activas,
tagear con el mismo `X.Y.Z`.

## Legacy tags

Legacy semver-like tags such as `v.1.1.2` remain available for historical
consumers, but they are no longer the canonical contract for this image.

## Canonical consumer

The canonical consumer in this workspace family is:

- `logistics-app/tools/docker/Dockerfile`

That consumer must always be updated to the exact `nodebun` tag that matches the
runtime matrix it expects.
