# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- **Bump base image `cartagodocker/zsh:v1.0.2` -> `v1.0.5`**.
  v1.0.5 es la ultima estable del repo cartagodocker/zsh (publicada
  2025-01-02). Trae mejoras del zsh image base sin tocar nuestro
  Dockerfile (mismo Ubuntu 24.04, mismo helper `add_text_to_zshrc`
  que seguimos usando). Mantenerse al dia con la base image es
  importante: ademas de mejoras del zsh, incorpora parches de
  seguridad del OS.

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
- **Dockerfile `bun --version` no longer aborts build**: the sanity check
  uses `|| echo "[warn] ..."` so a transient bun failure does not block the
  image build. The wrapper was already created and chmodded above; this only
  confirms the wiring is intact.
- **Dockerfile base image pinned**: `FROM cartagodocker/zsh:latest` changed
  to `FROM cartagodocker/zsh:v1.0.2` for reproducible builds.
- **Dockerfile redundant `fnm use` removed**: `fnm default ${NODE_DEFAULT_VERSION}`
  already establishes the default; the following `fnm use` was a no-op.

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
