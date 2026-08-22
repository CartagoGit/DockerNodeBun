# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Wrapper exit code propagation**: `scripts/bun_wrapper.zsh` now propagates
  `bun_original`'s exit code via `exit "${bun_original_exit:-0}"`. Previously the
  wrapper returned 0 unconditionally, which broke `set -e` in CI pipelines and
  caused jobs to be marked as successful even when bun failed (compounded by
  stale artifacts in `build/`).
- **Wrapper global-install detection**: detection now covers `bun add -g`,
  `bun add --global`, `bun a -g`, `bun a --global` (in addition to the legacy
  `bun install -g`). Previously `chmod -R 777 /usr/share/bun` only ran on the
  exact `i`/`install` subcommand, leaving modern installs with restrictive
  permissions on the share folder.
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

### Changed
- **`.dockerignore` populated**: previously empty, now excludes `.git`, `.github`,
  `.vscode`, `*.md`, `LICENSE` and other non-essential files from the build
  context.

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
