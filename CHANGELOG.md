# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.8] - 2025-11-11

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
