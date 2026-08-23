# DockerNodeBun — tracker de bugs (`FIXES.md`)

Documento **vivo**. Se borra cuando no queden bugs. Complementa
`VERSIONING.md` / `CHANGELOG.md` (historia) y el README (contrato).

| | |
|---|---|
| Esta versión (árbol) | **2.0.0** (`ARG VERSION=2.0.0`) — Hub ya tiene el tag 2.0.0 sobre zsh 1.0.5 |
| Base del árbol | **`FROM cartagodocker/zsh:v1.0.6`** — no revertir a 1.0.5 |
| Orden | Publicar **zsh v1.0.6 a Hub**, smoke, **después** construir/publicar NodeBun |
| Hub zsh hoy | `v1.0.5` — un `docker build` de NodeBun **ahora** falla o hereda ENTRYPOINT hasta que 1.0.6 exista |

Leyenda: `[ ]` abierto · `[x]` hecho · `[–]` no se hará en **esta** versión.

---

## Decisión de producto (no tocarla aquí)

zsh 1.0.6 arregla ENTRYPOINT, certs, sudo, `SHELL sh`, CLI extras.
**NodeBun 2.0.0 se queda en 1.0.5.** Motivo: no mezclar “correcciones de
NodeBun” con “nueva base”. El fallback sudo/certs de este Dockerfile
existe **porque** la base es 1.0.5.

Consecuencia aceptada: esta imagen **hereda** `ENTRYPOINT ["zsh"]`.

---

## Commits recientes (qué arreglaron / qué dejaron a medias)

`main` ya tiene `v2.0.0` (`1baf41d`). Working tree = cambios **no
commiteados** encima (COPY selectivo, docs, pin que llegó a `zsh:v1.0.6`
por error y se revirtió).

| Commit | Qué | Riesgo residual |
|---|---|---|
| `f9b45cf` pin base + sudo + “drop redundant fnm use” | `FROM latest` → `v1.0.2`; instala sudo | CHANGELOG dice que se **quitó** `fnm use`; el Dockerfile **sigue** usándolo en el RUN y en zshrc (el de zshrc es útil). Docs mienten. |
| `e676c3f` bump zsh `v1.0.2` → `v1.0.5` | Base publicada actual | Hereda ENTRYPOINT zsh. No es regresión de NodeBun: es la base. |
| `bc766fa` wrapper exit code + `bun --version \|\| warn` | Propaga `$?` del bun real | El `\|\| echo warn` **traga** un bun roto en build (#N6). |
| `f025a67` logs wrapper → stderr | Deja de romper pipes | Sigue imprimiendo `Running bun_wrapper.sh…` en **cada** invocación (#N5). |
| `ce2b68f` detecta `-G` / `--global=` | chmod 777 en install global | `-gx` (short cluster con `g`) cuenta como global. Raro. |
| `1baf41d` FNM store global + PATH node + sudo opt-in | Arregla uid 1000 sin Node | Base sigue 1.0.5. sudo = scripts `nodebun*` (nombres distintos a zsh 1.0.6 `container-*`). |
| `3b39991` + `ba0aa37` manifesto + drop breakpoints | Workflow lee `matrices.yml` | `.dockerignore` aún menciona `scripts/tag-breakpoint.sh` (archivo borrado). |
| `d509f44` / `3fc96ed` “pre-release hardening, no outstanding bugs” | Docs de cierre | Quedaban bugs de ENTRYPOINT / certs de la **base**. El cierre era de NodeBun, no de zsh. |
| Working tree (COPY selectivo) | No pisa `sudo-password` de una base **nueva** | Correcto para 1.0.6 **futuro**. En 1.0.5 el `if` falla (no hay binario) y se instala el fallback. Bien. Un `FROM zsh:v1.0.6` **sin** existir en Hub rompía el build — revertido. |

---

## Contrato 2.0.0 + zsh 1.0.5

1. `node` / `npm` / `npx` / `fnm` / `bun` en `/usr/local/bin` para **cualquier uid y shell**.
2. Store fnm global `FNM_DIR=/usr/share/fnm/store` (`777`).
3. Matriz horneada en **build**, no en `docker run`.
4. sudo NOPASSWD `ALL` vía **fallback NodeBun** (`/etc/sudoers.d/nodebun`).
5. Helpers: `in-bash`, `in-sh`, `only-in-container`, `skip-if-container`, `dockernodebun`.
6. **No** se promete `docker run img node` sin `--entrypoint` (ENTRYPOINT heredado).

---

## Progreso

| # | Ítem | Pri | Estado |
|---|---|---|---|
| N1 | **ENTRYPOINT zsh heredado** — `docker run img node --version` falla | crítica | [ ] **aceptado** en 2.0.0 (base 1.0.5). Workaround: `--entrypoint /bin/sh`. Cierre real: otro NodeBun con zsh ≥ 1.0.6 + `ENTRYPOINT []` por defensa. |
| N2 | Compose `command: ["tail","-f","/dev/null"]` lo traga zsh | crítica | [ ] mismo que N1 |
| N3 | Docs decían `FROM zsh:v1.0.6` / “no ENTRYPOINT” | crítica | [x] pin y README vueltos a 1.0.5 + workaround |
| N4 | `COPY scripts/` entero pisaba sudo de un zsh nuevo | alta | [x] COPY selectivo + fallback dir (en 1.0.5 el fallback **sí** se instala) |
| N5 | `bun_wrapper.zsh` es **bash**; log en cada run | media | [ ] shebang `#!/bin/bash`, mensaje `Running bun_wrapper.sh script with parameters: …` a stderr siempre. Ruido CI. |
| N6 | `bun --version \|\| echo warn` no falla el build | media | [ ] zip/AVX2 mal extraído → imagen verde |
| N7 | `VERSIONING.md` ejemplos `ARG VERSION=1.0.1` / bugfix `v1.0.2` **después** de `v2.0.0` | docs | [x] ejemplos alineados a 2.0.x |
| N8 | CHANGELOG “fnm use removed” vs Dockerfile que lo usa | docs | [ ] el RUN y el zshrc siguen con `fnm use` (zshrc: deliberado) |
| N9 | `.dockerignore` menciona `tag-breakpoint.sh` | baja | [ ] archivo ya no existe |
| N10 | `dockernodebun --help` llama `dockerzsh` (no está en zsh 1.0.5) | media | [ ] hay fallback de texto; el catálogo zsh **no** aparece. No es crash. |
| N11 | `nodebun-profile.sh` no re-exporta `PATH` | baja | [ ] login `su -` pierde `/usr/share/bun/bin` y `/usr/share/fnm/bin`. Los bins están también en `/usr/local/bin` (symlink) → suele valer. `BUN_HOME` sí se re-exporta (wrapper). |
| N12 | Fallback sudo nombres `nodebun*` vs zsh 1.0.6 `container*` | alta **si** se pinnea 1.0.6 sin el `if` | [x] el `if` comprueba `sudo-password` + `container-nopasswd` **o** `nodebun`. En 1.0.5 entra al else. |
| N13 | `enable-sudo-users.sh` / `sudo-password` en NodeBun vs Zsh | higiene | [ ] dos copias. En 1.0.5 **hace falta** la de NodeBun. Borrar del repo solo tras pin 1.0.6. |
| N14 | README “Small CLI from zsh (fd, rg, dockerzsh)” | docs | [x] aclarado: 1.0.5 no los trae |
| N15 | `in-bash` / `in-sh` con `--login` | ok | [x] cargan `profile.d/nodebun.sh` |
| N16 | Matrices README vs `matrices.yml` | ok | [x] n22.21.1 / n26.3.1 |
| N17 | Workflow NodeBun pin SHA + manifesto | ok | [x] (a diferencia de zsh) |
| N18 | `chmod -R 777` FNM_DIR / BUN_HOME | contrato | [x] deliberado (cualquier uid instala). Superficie: cualquier uid escribe el store. |

---

## Análisis de abiertos

### N1 / N2 — ENTRYPOINT (el que se siente como “está roto”)

**Repro (imagen local `cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14`):**

```text
docker run --rm cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14 node --version
# zsh: can't open input file: node

docker inspect … Entrypoint=["zsh"] Cmd=null Shell=["/bin/sh","-c"]
```

NodeBun **sí** pisa `SHELL` a sh (los `RUN` del Dockerfile funcionan).
**No** pisa `ENTRYPOINT`. Docker concatena ENTRYPOINT+CMD/args → `zsh node --version`.

`--entrypoint /bin/sh` → `v22.21.1`. Interactivo `-it` (sin args) entra a zsh y va bien.

**Por qué no se “arregla” en 2.0.0:** anular ENTRYPOINT aquí (`ENTRYPOINT []` + `CMD zsh`) **cambiaría el contrato** de un tag ya publicado / de esta línea 2.0.0-sobre-1.0.5. El cierre limpio es pinnear zsh 1.0.6 (CMD, sin ENTRYPOINT) **y** poner `ENTRYPOINT []` por defensa. Eso es otro `X.Y.Z` de NodeBun.

**Workaround estable:**

```bash
docker run --rm --entrypoint /bin/sh cartagodocker/nodebun:v2.0.0_n26.3.1_b1.3.14 -c 'node --version'
# Compose: entrypoint: ["/bin/sh", "-c"]  command: ["tail -f /dev/null"]
# o esperar un NodeBun que pinnee zsh 1.0.6
```

### N5 — wrapper ruidoso / nombre mentiroso

`scripts/bun_wrapper.zsh` → `#!/bin/bash`. El nombre `.zsh` viene del
Dockerfile de zsh (renombra `*.zsh` al copiar). Aquí se COPY con el
nombre original y se `ln -s` a `bun`. Funciona. Cada `bun …` escribe
una línea a stderr. En CI con `bun test` ensucia logs.

Arreglo (cuando se toque): shebang `#!/bin/sh` o `#!/usr/bin/env bash`,
log solo con `BUN_WRAPPER_DEBUG=1`, o silencio por defecto.

### N6 — sanity bun no-op

`bun --version || echo "[warn]…"` se añadió para no abortar por un
fallo transitorio. También oculta un `bun_original` mal linkeado.
Mejor: fallar el build, o comprobar `[ -x bun_avx2 ] && [ -x bun_baseline ]`
sin ejecutar el wrapper (el wrapper en build corre como root y chmod 777).

### N8 — CHANGELOG vs código

En `[2.0.0] Fixed` se dice que se quitó un `fnm use` redundante. El
Dockerfile hace `fnm default` **y** `fnm use` en el RUN (hace falta
para que `npm install -g` vea esa versión) **y** otra vez en zshrc
(`fnm use ${NODE_DEFAULT_VERSION}`). El de zshrc no es redundante:
`fnm env` solo pone el default si la sesión lo evalúa; el `use`
explícito evita un `.nvmrc` montado… espera, sin `--use-on-cd` el
`.nvmrc` no salta. El `use` en zshrc fuerza la matriz aunque el
usuario tuviera otra default en el store. Dejarlo; corregir el
CHANGELOG cuando se toque docs.

### N10 — `dockernodebun` sin `dockerzsh`

En 1.0.5 no existe `/usr/local/bin/dockerzsh`. El script imprime
“zsh catalogue not found; old zsh base?” y sigue con extras NodeBun.
Correcto para esta versión. En un NodeBun-sobre-1.0.6 desaparece el
aviso.

### N11 — PATH en login

`/etc/profile.d/nodebun.sh` re-exporta homes, no `PATH=`. Ubuntu login
ya tiene `/usr/local/bin`. Symlinks `node`/`bun`/`fnm` viven ahí.
Solo se pierde el dir “real” de bun/fnm si alguien invoca
`/usr/share/bun/bin/bun_original` a mano. Prioridad baja.

---

## Qué **no** es un bug (TTY / fuentes)

- `ls` → eza **solo** en zsh interactivo con TTY. `command: tail` no es zsh.
- Iconos p10k/eza = Nerd Font **del host**. 🐳 = fuente emoji del host.
- `fnm use 20` no cambia la matriz del **siguiente** shell (contrato).

---

## Checklist antes de borrar este archivo

- [ ] N1/N2 cerrados (zsh ≥ 1.0.6 **y** `ENTRYPOINT []` en NodeBun) **o** decisión explícita de no soportar `docker run img node`
- [ ] N5 silencio por defecto
- [ ] N6 build falla si bun no arranca
- [ ] N8 CHANGELOG vs `fnm use`
- [ ] N9 `.dockerignore`
- [ ] N10 `dockerzsh` presente **o** docs sin prometirlo
- [ ] N13 una sola familia de scripts sudo (cuando la base ya los traiga)

Hasta entonces: este archivo se queda.

---

## Diario

| Fecha | Qué |
|---|---|
| 2026-08-23 | Tag `v2.0.0` + FNM global + sudo fallback (`1baf41d`). Base zsh 1.0.5. |
| 2026-08-23 | Confirmado: `docker run nodebun:v2.0.0_n22… node --version` → `can't open input file`. |
| 2026-08-23 | Working tree: COPY selectivo; **pin se mantiene en zsh v1.0.5**; zsh 1.0.6 es el otro repo. Este FIXES creado. |
