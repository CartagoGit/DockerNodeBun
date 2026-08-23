# Agent rules — cartagodocker/nodebun

## xAI / Grok HTTP 400 (this multi-root workspace)

Same trap as DockerZsh: xAI 400 `lone leading surrogate in hex escape` from the **whale emoji** 🐳 or JSON `\u` hex of UTF-16 surrogate halves in the chat payload. Not a NodeBun bug.

If it happens: **stop**, new chat, no retries, no glyph in tool args, no surrogate `\u` hex in grep. Read `AGENTS.md` in DockerZsh for the full rule.

Grep ASCII only (`os_icon`, `🐳`). Do not dump huge files into tool results.

## Docker Hub long description (`README.md`)

Hub `full_description` max is **~25 000 characters** (`wc -m README.md`).
Over that, `Update Docker Hub Description` authenticates, then `PATCH`
returns **HTTP 400** (`curl: (22)`). Hub keeps the last description that
**succeeded**. Same trap as DockerZsh (zsh README already blew the cap).

Workflow: `.github/workflows/update-dockerhub-description.yml`

- Runs on `push` to **`main`** only if **`README.md`** or this
  workflow file changed (`paths:`). A push that only touches
  `scripts/` / Dockerfile / tags does **not** run it. Tag workflows
  are image publish, not the Hub README.
- Also `workflow_dispatch`.
- Fail **before** PATCH if `wc -m README.md` is over 25000.

When editing `README.md`: keep every fact (matrices, runtimes, helpers,
pins). **Summarize** wording; do not delete inventory. Recheck `wc -m`.
Do not dump the whole README into a tool result.

Utilities tables are **two columns**: name → docs URL. Do not paste
upstream descriptions. Image caveats stay in the intro. Inherited
CLIs: link the zsh README Utilities. Our helpers link to Scripts /
catalogue sections.

## Remaining work (nodebun)

Tracker: `FIXES.md` — **No planned fixes.**

Pin **`FROM cartagodocker/zsh:v2.0.0`** — do not revert. Do not retag
Hub zsh `v1.0.5`. Hub zsh **v2.0.0 is published**. Local smoke on
`nodebun-local:dev` closed N1/N2 (no ENTRYPOINT) and the uid-1000
`fnm env` home (`~/.local/state` + chown).
