# Agent rules — cartagodocker/nodebun

## xAI / Grok HTTP 400 (this multi-root workspace)

Same trap as DockerZsh: xAI 400 `lone leading surrogate in hex escape` from the **whale emoji** 🐳 or JSON `\u` hex of UTF-16 surrogate halves in the chat payload. Not a NodeBun bug.

If it happens: **stop**, new chat, no retries, no glyph in tool args, no surrogate `\u` hex in grep. Read `AGENTS.md` in DockerZsh for the full rule.

Grep ASCII only (`os_icon`, `🐳`). Do not dump huge files into tool results.

## Remaining work (nodebun)

Tracker: `FIXES.md` — **No planned fixes** in the tree.

Pin **`FROM cartagodocker/zsh:v2.0.0`** — do not revert. Do not retag
Hub zsh `v1.0.5`. N1/N2 (ENTRYPOINT) are closed on that base.

N5 (wrapper silent + bash shebang documented), N6 (`bun --version` fails the build), N8 (`fnm use` stays; CHANGELOG corrected), N10 (`dockerzsh` required), N11 (PATH not re-exported — `/usr/local/bin` is enough), N13 (sudo fallback scripts deleted) are done in this tree.
