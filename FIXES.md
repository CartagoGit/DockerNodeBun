# DockerNodeBun — tracker

**No planned fixes.**

Working tree pins **`FROM cartagodocker/zsh:v2.0.0`**. Do not revert.
Do not retag Hub zsh `v1.0.5`.

N1/N2 (inherited `ENTRYPOINT zsh`) are closed on that base. N5, N6,
N8, N10, N11, N13 are done in this tree (silent bun wrapper, bun
`--version` fails the build, `fnm use` stays, `dockerzsh` required,
PATH via `/usr/local/bin`, sudo scripts deleted).

---

## Historical notes (Hub tags already published)

Hub NodeBun `v2.0.0_n22…` / `n26…` was built on **zsh v1.0.5**
(`ENTRYPOINT ["zsh"]`). Those tags are immutable. New builds use
zsh 2.0.0 (CMD, no ENTRYPOINT). Workaround on the old tags:

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 -c 'node --version'
```
