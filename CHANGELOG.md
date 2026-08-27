# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **`bunx` on PATH.** Official bun is one binary; `bunx` is a
  symlink and bun switches on `argv0`. The image only shipped `bun`
  plus an interactive zsh alias `bunx="bun x"`, so bash/sh/scripts/CI
  got `command not found`. A symlink alone is not enough: the wrapper
  calls `bun_original`, which execs `bun_avx2`/`bun_baseline` under
  those names, so `argv0` never stays `bunx`. The wrapper now rewrites
  `bunx pkg` → `bun x pkg`. `/usr/local/bin/bunx` is a symlink to the
  same wrapper. The zsh alias is gone.

### Changed
- Interactive bash/sh inherit zsh `ls` → eza (and zoxide; bash fzf
  keys) from the parent image. No NodeBun change; rebuild on a zsh
  that includes `/usr/share/zsh-image/interactive.sh`.
- README wording tightened (inventory unchanged). Utilities tables
  are **name → docs URL**. Workflow fails before PATCH if
  `wc -m README.md` is over 25000. A `main` push that does not
  change `README.md` does not run the Hub description job.

## [2.0.0] - 2026-08-23

Pin **`FROM cartagodocker/zsh:v2.0.0`**. CMD without ENTRYPOINT.
No sudo fallbacks. Local smoke ~695 MB (Node 26 matrix).

### Added
- GitHub Release on tag push (`docker-hub-update.yml`). If a Release
  for that tag already exists, it is deleted and recreated. Hub is
  unchanged: existing Hub tags are skipped (delete them on Hub to
  republish the image).
- **`in-bash` / `in-sh`**: helpers en `/usr/local/bin` para lanzar
  bash o POSIX sh (con login env) desde zsh cuando un snippet no es
  zsh-safe (`set -o pipefail`, `[[ ]]`, `case` POSIX, etc.).
- **`skip-if-container` / `only-in-container`**: predicados para no
  correr (o solo correr) un comando si estamos dentro de nodebun.
  Detectan `/.dockerenv` o `IS_INTO_CONTAINER=true`.
- **`/etc/profile.d/nodebun.sh`**: re-exporta `BUN_*` / `FNM_*` /
  `NODE_DEFAULT_VERSION` / `NODEBUN_IMAGE_VERSION` / `IS_INTO_CONTAINER`.
  Sourced from bash.bashrc **and** `/etc/zsh/zprofile` (Ubuntu zsh
  login does not source `/etc/profile`). The script is matrix-agnostic.
  Per-image Node / X.Y.Z are `/usr/share/nodebun/build.env` (written
  at build from ARG). Login shells that dropped Docker ENV read it;
  an already-set ENV (or a child overwrite) wins.
- **`sudo` NOPASSWD por defecto** (`ALL ALL=(ALL:ALL) NOPASSWD:ALL`).
  Compose `user: 1000:1000` no carga grupos suplementarios (`sudo`);
  la regla tiene que ser ALL, no `%sudo`. El limite es no escribir
  `sudo` si no hace falta.
- **Contraseña de sudo opt-in en runtime** (no se hornea en la imagen):
  - al levantar: `docker run -e SUDO_PASSWORD=secret …`
  - dentro: `sudo-password` (prompt o arg) / `sudo-nopasswd` para volver.

### Fixed
- **Node visible para cualquier uid**. `v2.0.0` instalaba Node en
  `/root/.local/share/fnm` y el `.zshrc` global hacia
  `eval $(fnm env); fnm use ${NODE_DEFAULT_VERSION}`. Compose con
  `user: 1000:1000` arrancaba zsh interactivo y fnm pedia
  instalar 22.21.1 porque el store de ubuntu estaba vacio.
  Contrato (sigue `2.0.0`, se republica el tag):
  - `FNM_DIR=/usr/share/fnm/store` (store global, no per-home).
  - `node`/`npm`/`npx`/`fnm`/`bun` en `/usr/local/bin`.
  - Store `777` (como bun): cualquier uid puede `fnm install` / `fnm use`.
  - Symlink `~/.local/share/fnm` + `/etc/skel` para usuarios nuevos.
  - `.zshrc`: `fnm env --shell zsh` + `fnm use ${NODE_DEFAULT_VERSION}`
    (version del tag, ya instalada). Sin `--install-if-missing`.
  - `SHELL ["/bin/sh", "-c"]` en el Dockerfile: la base zsh usaba
    `SHELL ["zsh", "-c"]` y el RUN de instalacion se cortaba en
    `fnm env --use-on-cd=false` (fnm 1.38.1 no acepta valor). Docker
    marcaba el layer OK y la imagen salia sin node/bun en PATH.
  - Wrapper de bun: fallback `BUN_HOME=/usr/share/bun` para `su -`.
- **`fnm env` / `fnm use` as uid 1000.** Build `mkdir ~/.local/share`
  as root left `/home/ubuntu/.local` root-owned and created no
  `~/.local/state`. fnm could not write
  `~/.local/state/fnm_multishells`. The image now creates
  `~/.local/state` and `chown`s `~/.local` to the home owner
  (`/etc/skel` stays root so `useradd -m` copies it).
  `/usr/local/bin/node` still works without `fnm use`.
- **Login zsh (`su -`).** Ubuntu `/etc/zsh/zprofile` does not source
  `/etc/profile.d`. `su - ubuntu` (zsh, often non-interactive) skipped
  `.zshrc` and dropped Docker ENV, so `fnm use` had no `fnm env` and
  `NODE_DEFAULT_VERSION` was empty. zprofile now sources `nodebun.sh`,
  which runs `fnm env --shell bash` and, if ENV was dropped, fills
  Node / X.Y.Z from `/usr/share/nodebun/build.env` (this image's ARG).
- CHANGELOG must not say a redundant `fnm use` was removed: it stays
  in the Dockerfile RUN (npm global) **and** in `.zshrc`.

### Changed
- **Tag scheme migrated to `v{X.Y.Z}_n..._b...`** (esquema 3, vigente desde
  2026-08-22). `X.Y.Z` es un semver ligero de las **correcciones del repo**
  (Dockerfile, wrapper, workflows, docs), separado de la **matriz de
  runtime** `n..._b...`. Esto permite saber si dos imágenes comparten
  correcciones solo mirando el tag, sin importar la matriz.
- **Tag trigger + manifesto model**: el workflow publica N imágenes a
  partir de UN SOLO tag `v{X.Y.Z}` en `main`, leyendo
  `.github/matrices.yml` como única fuente de verdad sobre qué matrices
  existen y qué versiones usan. Esto elimina la dependencia de ramas
  paralelas (`n22.21.1_b1.3.14`, `n26.3.1_b1.3.14`) como fuente de
  runtime — esas ramas se conservan por compatibilidad pero el workflow
  ya no las lee. Añadir/quitar una matriz es un commit al manifiesto, sin
  tocar el workflow.
- **`ARG VERSION=1.0.1` added to Dockerfile** as single source of truth
  para `X.Y.Z`. Se inyecta como `--build-arg VERSION=X.Y.Z` desde
  `.github/workflows/docker-hub-update.yml` (que parsea el tag con
  bash regex), y se exporta como `ENV VERSION=${VERSION}` para que
  `docker inspect` muestre la versión de correcciones aplicada.
- **Bump inicial `X.Y.Z` = `2.0.0`**: el salto a `2.0.0` (major)
  refleja la rotura del modelo de publicacion: trigger tag + manifesto
  + eliminacion de ramas de matriz. La "rotura" se registra en el
  bump X.Y.Z, no en un tag paralelo.
- **Base `cartagodocker/zsh:v2.0.0`.** Hereda unzip, ca-certificates, sudo,
  SSH client, daily CLI extras, `dockerzsh` y `CMD` sin ENTRYPOINT.
  NodeBun **no** reinstala unzip ni certs (`libatomic1` sí: lo necesita bun).
  No añade Docker CLI ni un segundo kit de shell. Exige esa base
  (build falla si faltan `sudo-password` / `container-nopasswd` / `dockerzsh`).
- **Sin fallback sudo.** `COPY` solo helpers NodeBun
  (`bun_wrapper`, `in-bash`, `in-sh`, `only-in-container`,
  `skip-if-container`, `nodebun-profile.sh`, `dockernodebun`).
  Scripts `sudo-*` de este repo **borrados**.
- **zshrc:** no se duplica `apply-sudo-password-on-boot.sh` si la
  base ya lo puso en `/usr/share/globally/.zshrc`.
- **`dockernodebun --help`:** prints `dockerzsh --help` then extras.
  `--version | -v` is image identity. Tool versions:
  `dockernodebun --list --version | -l -v`, `runtimes -v`, `node -v`
  (headings discovered, not hardcoded). Catalogue `runtimes`:
  `node`/`npm`/`npx`/`bun`/`fnm` only (`bunx` is a zsh alias;
  `corepack` is not on this matrix).
- **`bun_wrapper`:** silent unless `BUN_WRAPPER_DEBUG=1`. Shebang is
  bash (historical `.zsh` filename).
- **Build `bun --version`:** fails the image if bun does not start
  (`test -x bun_avx2` / `bun_baseline` then `bun --version` without `|| warn`).
- **`NODEBUN_IMAGE_VERSION`:** same idea as zsh `ZSH_IMAGE_VERSION`. A
  child `FROM nodebun` that sets `VERSION` does not make
  `dockernodebun --version` lie.
- README lists **every** extra CLI: inherited zsh utilities (link to
  the parent Utilities section) plus NodeBun runtimes with docs links.
  Own helpers have usage examples here (not Ubuntu man pages).

### Added
- **`.github/matrices.yml`**: manifesto canónico de las matrices activas
  (status: active) y deprecadas (status: deprecated). Es la única
  fuente de verdad sobre qué imágenes publica el workflow. Añadir o
  quitar una matriz es un commit a este archivo, sin tocar código.

### Removed
- **Job `breakpoint-reminder`** eliminado del workflow
  `docker-hub-update.yml`. Era un job CI que emitia un `::notice::`
  cuando se publicaba un tag trigger `v{X.Y.Z}` sin su
  `breakpoint_v{X.Y.Z}` correspondiente. Anadia complejidad sin valor
  real.
- **Sistema de breakpoints completo**: el script
  `scripts/tag-breakpoint.sh`, la seccion de "Breakpoints" en
  VERSIONING.md y README.md, y la nocion de tags `breakpoint_v{X.Y.Z}`
  han sido eliminados. La "rotura estructural" ahora se registra
  directamente en el bump X.Y.Z (con `X` cuando hay cambio
  incompatible). Mas simple, menos ceremonias, la rotura es visible
  en el propio tag.

### Changed (post-audit)
- **Bump base image `cartagodocker/zsh:v1.0.2` -> `v1.0.5`**
  (first NodeBun 2.0.0 Hub tags). This tree pins **zsh v2.0.0**.

### Fixed
- **Wrapper exit code propagation**: `scripts/bun_wrapper.zsh` now propagates
  `bun_original`'s exit code via `exit "${bun_original_exit:-0}"`. Previously the
  wrapper returned 0 unconditionally, which broke `set -e` in CI pipelines and
  caused jobs to be marked as successful even when bun failed (compounded by
  stale artifacts in `build/`).
- **Wrapper global-install detection**: detection now covers `bun add -g`,
  `bun add --global`, `bun a -g`, `bun a --global`, `-G`, `--global=true`,
  `--global=false` (in addition to the legacy `bun install -g`). Previously
  `chmod -R 777 /usr/share/bun` only ran on the exact `i`/`install`
  subcommand, leaving modern installs with restrictive permissions on the
  share folder.
- **Wrapper logs to stderr**: `Running bun_wrapper.sh ...` and
  `Giving permissions ...` messages moved from stdout to stderr. Previously
  they contaminated the output of any caller that piped or parsed
  `bun ...` stdout, breaking CI log filters and downstream parsers.
- **Dockerfile `bun --version` no longer aborts build** *(later
  reverted in this same 2.0.0 tree: a broken bun must fail the image)*:
  the first Hub 2.0.0 tags used `|| echo "[warn] ..."`.
- **Dockerfile base image pinned**: `FROM cartagodocker/zsh:latest` changed
  to `FROM cartagodocker/zsh:v1.0.2` for reproducible builds.
- **`fnm use` stays.** `fnm default` plus `fnm use ${NODE_DEFAULT_VERSION}`
  in the RUN (npm global) and in `.zshrc` (interactive zsh). An older
  changelog line that said this was a no-op was wrong.

### Changed (infra)
- **`.dockerignore` populated**: previously empty, now excludes `.git`, `.github`,
  `.vscode`, `*.md`, `LICENSE` and other non-essential files from the build
  context.
- **`.gitignore` populated**: previously empty, now excludes `.DS_Store`,
  `.swp`, `*.bak`, `*.log`, etc.
- **GH Actions pinned to SHA** (supply-chain security): checkout,
  setup-buildx, login-action ahora referencian SHA inmutables
  en lugar de tags movibles.
- **GH Actions upgraded**: `docker/setup-buildx-action@v3` ->
  `v4.3.0`, `docker/login-action@v3` -> `v4.6.0`.
- **Workflow dispatch**: `docker-hub-update.yml` ahora acepta un input
  `tag_name` para builds manuales, y valida que el tag matchee el
  nuevo esquema `v{X.Y.Z}_n..._b...`.- **Workflow rewrite (model "tag trigger + manifesto")**:
  `docker-hub-update.yml` reescrito para leer `.github/matrices.yml`
  y construir N imágenes a partir de un único tag `v{X.Y.Z}` en
  `main`. Mantiene compatibilidad con tags matrix manuales
  (`v{X.Y.Z}_n..._b...`) para re-publicar una sola imagen.
  Idempotente: tags ya existentes en DockerHub se skipean sin re-build.- **Workflow JSON serialization**: `update-dockerhub-description.yml`
  ahora construye el payload con `jq --rawfile` + `--data-binary` en
  vez de embeber el JSON inline con `-d` (mas robusto ante
  caracteres especiales en el README).

## [1.1.2] - 2025-11-12

### Fixed
- Fixed global package installation path by setting `BUN_INSTALL` environment variable
- Bun 1.3.2 now installs global packages in `/usr/share/bun/bin` (matching v.1.0.6 behavior) instead of `/root/.bun/bin`
- Global binaries (like `tsc`, `quasar`, etc.) are now accessible from any user as expected

## [1.1.1] - 2025-11-11

### Fixed
- Fixed file permissions (755 → 777) for Bun binaries and directories to ensure compatibility with CI/CD runners (like GitLab CI)
- Restored permission scheme matching v.1.0.7 for backwards compatibility

## [1.1.0] - 2025-11-11

### Changed
- Updated Bun.js from version 1.1.42 to 1.3.2 (latest)
- Implemented automatic CPU architecture detection for optimal Bun binary selection

### Added
- Dual Bun binary system: AVX2-optimized version and baseline version
- Smart wrapper (`bun_selector.sh`) that automatically detects CPU capabilities at runtime
- Support for systems without AVX/AVX2 instructions (baseline version)
- Automatic performance optimization on modern CPUs with AVX2 support

### Fixed
- Resolved compatibility issues with runners that don't support AVX/AVX2 instructions
- Image now works seamlessly across different CPU architectures

## [1.0.7] - 2025-01-02

### Fixed
- Fixed potential future issue when cleaning cache and temporary folders if directory doesn't exist

## [1.0.0 - 1.0.6] - Previous versions

### Initial Features
- Bun.js 1.1.42
- Fast Node Manager (fnm) 1.38.1
- Node.js 22 LTS
- npm 10.9.0
- Based on cartagodocker/zsh image
- Ubuntu 24.04 base
