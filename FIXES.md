# DockerNodeBun — tracker de bugs (`FIXES.md`)

Documento **vivo**. Se borra cuando no queden bugs.

| | |
|---|---|
| Árbol | `ARG VERSION=2.0.0` + cambios unreleased |
| Base del árbol | **`FROM cartagodocker/zsh:v2.0.0`** — **no revertir** |
| Orden | Publicar **zsh v2.0.0 a Hub** → smoke → construir/publicar NodeBun |
| Hub NodeBun hoy | `v2.0.0_n22…` / `n26…` sobre **zsh v1.0.5** (`ENTRYPOINT ["zsh"]`) — tag viejo, inmutable |
| Hub zsh hoy | `v1.0.5` — un `docker build` de este árbol espera a que exista **`v2.0.0`** |

Leyenda: `[ ]` abierto · `[x]` hecho en el árbol · `[–]` no se hará.

---

## Decisión (no revertir el pin)

1. Subir **zsh v2.0.0** a Hub. **No se retaggea 1.0.5.**
2. **Después** subir NodeBun, que pinnea `cartagodocker/zsh:v2.0.0`.

Hasta el paso 1, **no** construir esta imagen contra Hub. No hay
fallback sudo: el `RUN` exige `sudo-password` + `container-nopasswd` +
`dockerzsh` de esa base.

---

## Commits recientes

`main` publicado es Hub NodeBun 2.0.0 sobre zsh **1.0.5**. Working tree =
**`FROM cartagodocker/zsh:v2.0.0`**. Eso es la siguiente publicación.

| Commit | Qué | Residuo |
|---|---|---|
| `f9b45cf` | Pin `latest` → `v1.0.2`; sudo | CHANGELOG dice que se quitó `fnm use`; el Dockerfile **sigue** usándolo (RUN + zshrc). |
| `e676c3f` | zsh `v1.0.2` → `v1.0.5` | Tag Hub 2.0.0 hereda `ENTRYPOINT zsh`. |
| `bc766fa` | Wrapper propaga `$?`; `bun --version \|\| warn` | #N6: build verde con bun roto. |
| `f025a67` | Logs wrapper → stderr | #N5: una línea en **cada** `bun`. |
| `ce2b68f` | Detecta `-G` / `--global=` | `-gx` cuenta como global. Raro. |
| `1baf41d` | FNM store global + PATH node + sudo opt-in | Tag Hub 2.0.0. sudo `nodebun*` en esa imagen. |
| `3b39991` + `ba0aa37` | Manifesto; drop breakpoints | `.dockerignore` mencionaba `tag-breakpoint.sh` (ya limpio). |
| Working tree | `FROM cartagodocker/zsh:v2.0.0` | **Correcto.** No construir hasta Hub zsh 2.0.0. |

---

## Contrato (árbol + zsh 2.0.0)

1. `node` / `npm` / `npx` / `fnm` / `bun` en `/usr/local/bin` para cualquier uid y shell.
2. Store fnm `FNM_DIR=/usr/share/fnm/store` (`777`).
3. Matriz horneada en **build**.
4. sudo NOPASSWD `ALL` **heredado de zsh** (`container-nopasswd`). Sin copia `nodebun*` en este repo.
5. Helpers: `in-bash`, `in-sh`, `only-in-container`, `skip-if-container`, `dockernodebun` (exige `dockerzsh`).
6. `docker run img node` funciona **con zsh 2.0.0** (sin ENTRYPOINT). El tag Hub NodeBun ya publicado (zsh 1.0.5) **sigue** necesitando `--entrypoint`.

---

## Progreso

| # | Ítem | Pri | Estado |
|---|---|---|---|
| N1 | Hub NodeBun 2.0.0 hereda `ENTRYPOINT zsh` | crítica | [ ] **cierre:** publicar zsh **v2.0.0** y luego este árbol. Tag viejo: `--entrypoint /bin/sh`. |
| N2 | Compose `command: ["tail","-f","/dev/null"]` lo traga zsh (tag Hub viejo) | crítica | [ ] mismo que N1 |
| N3 | Pin / docs | crítica | [x] árbol = `FROM cartagodocker/zsh:v2.0.0` |
| N4 | `COPY scripts/` entero pisaba sudo de zsh | alta | [x] COPY solo helpers NodeBun |
| N5 | `bun_wrapper` shebang / log cada run | media | [x] bash shebang documentado; silent salvo `BUN_WRAPPER_DEBUG=1` |
| N6 | `bun --version \|\| warn` no falla el build | media | [x] `test -x` + `bun --version` sin `\|\|` |
| N7 | `VERSIONING.md` ejemplos `1.0.1` / semver al revés | docs | [x] alineado a 2.0.x |
| N8 | CHANGELOG “fnm use removed” vs código | docs | [x] se deja `fnm use` (RUN + zshrc); CHANGELOG corregido |
| N9 | `.dockerignore` `tag-breakpoint.sh` | baja | [x] |
| N10 | `dockernodebun` llama `dockerzsh` | media | [x] requerido (build `test -x dockerzsh`) |
| N11 | `nodebun-profile.sh` no re-exporta `PATH` | baja | [x] deliberado: bins en `/usr/local/bin` |
| N12 | Nombres sudo `nodebun*` vs `container*` | alta | [x] este repo ya no tiene scripts sudo |
| N13 | Dos copias de scripts sudo | higiene | [x] borrados |
| N14 | README CLI / `dockerzsh` | docs | [x] herencia zsh 2.0.0 |
| N15 | `in-bash` / `in-sh` `--login` | ok | [x] |
| N16 | Matrices README vs `matrices.yml` | ok | [x] |
| N17 | Workflow pin SHA + manifesto | ok | [x] |
| N18 | `chmod -R 777` FNM/BUN | contrato | [x] deliberado |

---

## Análisis

### N1 / N2 — Hub 2.0.0 (zsh 1.0.5)

```text
docker run --rm cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14 node --version
# zsh: can't open input file: node
```

NodeBun pisa `SHELL` a sh (los `RUN` van). **No** pisa `ENTRYPOINT`.
Cierre: este árbol sobre **zsh 2.0.0** (CMD, sin ENTRYPOINT).

Workaround del tag **ya publicado** (zsh 1.0.5):

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 -c 'node --version'
```

### N5 / N6 / N8 / N10 / N11 / N13 — cerrados en el árbol

- Wrapper: bash shebang (nombre `.zsh` histórico); silent salvo `BUN_WRAPPER_DEBUG=1`.
- Build: `test -x bun_avx2` / `bun_baseline` + `bun --version` (falla si bun no arranca).
- `fnm use` se queda (RUN + zshrc). CHANGELOG 2.0.0 ya no dice que se quitó.
- `dockerzsh` es obligatorio (`test -x` en el Dockerfile).
- PATH de login: no se reexporta; bins en `/usr/local/bin`.
- Scripts sudo de este repo **borrados**.

---

## Qué no es un bug

- `ls` → eza solo en zsh interactivo con TTY.
- Iconos = fuente del **host** (Nerd Font / emoji).
- `fnm use 20` no cambia la matriz del siguiente shell.

---

## Checklist para borrar este archivo

- [ ] zsh **v2.0.0** en Hub y NodeBun publicado encima (N1/N2)

---

## Diario

| Fecha | Qué |
|---|---|
| 2026-08-23 | Tag Hub `v2.0.0` sobre zsh 1.0.5 (`1baf41d`). |
| 2026-08-23 | Confirmado ENTRYPOINT en esa imagen. |
| 2026-08-23 | Árbol: **`FROM cartagodocker/zsh:v2.0.0`**. Sin fallback sudo. Orden: Hub zsh 2.0.0 primero. |
