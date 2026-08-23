# Agent rules — cartagodocker/nodebun

## xAI / Grok HTTP 400 (this multi-root workspace)

Same trap as DockerZsh: xAI 400 `lone leading surrogate in hex escape` from the **whale emoji** 🐳 or JSON `\u` hex of UTF-16 surrogate halves in the chat payload. Not a NodeBun bug.

If it happens: **stop**, new chat, no retries, no glyph in tool args, no surrogate `\u` hex in grep. Read `AGENTS.md` in DockerZsh for the full rule.

Grep ASCII only (`os_icon`, `🐳`). Do not dump huge files into tool results.

## Remaining work (nodebun)

Tracker: `FIXES.md` — **No planned fixes.**

Pin **`FROM cartagodocker/zsh:v2.0.0`** — do not revert. Do not retag
Hub zsh `v1.0.5`. Hub zsh **v2.0.0 is published**. Local smoke on
`nodebun-local:dev` closed N1/N2 (no ENTRYPOINT) and the uid-1000
`fnm env` home (`~/.local/state` + chown).
