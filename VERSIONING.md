# DockerNodeBun — Versionado canónico

> Fuente de verdad de cómo se versionan y publican las imágenes
> `cartagodocker/nodebun`. Cualquier `FROM cartagodocker/nodebun:<tag>`
> debe seguir este esquema.

---

## Esquema vigente (a partir de 2026-08-22)

```
v{X.Y.Z}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Donde:

- **`X.Y.Z`** es un **contador semver ligero de las correcciones del repo**
  (lo que cambia son los archivos versionados: Dockerfile, wrapper,
  workflows, docs). NO es un contador de "republish de la misma matriz".
  - `X` (major) se incrementa cuando hay un cambio incompatible:
    nueva base image, drop de versiones de runtime legacy, cambios
    estructurales en el wrapper, etc.
  - `Y` (minor) se incrementa cuando se añaden features o se
    amplían contratos (soporte para nuevas flags, nuevas matrices
    en paralelo, nuevos binarios en PATH).
  - `Z` (patch) se incrementa cuando hay bugfixes puros del wrapper,
    del Dockerfile o de los workflows.
  - Este contador **se publica en TODAS las matrices en paralelo**.
    Es decir, `v2.0.0_n22.21.1_b1.3.14` y `v2.0.0_n26.3.1_b1.3.14`
    tienen exactamente las mismas correcciones aplicadas al repo.
- **`n{x.y.z}`** y **`b{x.y.z}`** son siempre tres segmentos
  (MAJOR.MINOR.PATCH). Nunca se acortan, porque el patch importa:
  CVEs de V8 en Node y fixes del loader TS en bun justifican el patch.
- **Matrices paralelas**: el repo puede mantener varias matrices
  activas a la vez (ej. `n22.21.1_b1.3.14` para LTS consumers y
  `n26.3.1_b1.3.14` como matriz canónica futura). Se publican con el
  mismo contador `X.Y.Z`. La fuente de runtime es
  `.github/matrices.yml`, no una rama git por matriz.
- El separador `_` (underscore) se eligió por **compatibilidad con el
  OCI Distribution Spec** que DockerHub y la mayoría de registries aplican
  a los tags (regex `[a-z0-9][a-z0-9._-]{0,127}`). El `+` (estilo
  Debian/PEP 440) es más familiar pero DockerHub lo rechaza con
  `invalid reference format`. El `_` se parsea correctamente en todas
  las herramientas que importan (Bash, regex, `sort`, `git tag -l`).
- Cada segmento respeta exactamente 3 niveles:
  - `v` no es semver: el esquema anterior usaba `v{N}` con un dígito,
    este usa `v{X.Y.Z}` con tres.

### Por qué este esquema

El esquema anterior (`v{N}_n..._b...`) confundía dos dimensiones:

1. **Cambios en los archivos del repo** (wrapper, Dockerfile, docs)
2. **Cambios en el runtime** (node, bun, fnm)

Un cambio solo en (1) — por ejemplo un bugfix del wrapper que no
toca nada del runtime — producía `v{N+1}` para CADA matriz. Eso
impedía saber si dos imágenes tenían las mismas correcciones
comparando solo el tag.

El nuevo esquema separa las dos dimensiones:

- `v2.0.0_n22.21.1_b1.3.14` y `v2.0.0_n26.3.1_b1.3.14` tienen
  **exactamente las mismas correcciones aplicadas al repo** pero
  distintos runtimes.
- `v2.0.0_n22.21.1_b1.3.14` y `v2.0.1_n22.21.1_b1.3.14` tienen el
  mismo runtime pero distintas correcciones del wrapper/Dockerfile.
- `v2.0.0_n26.3.1_b1.3.14` y `v2.0.1_n22.21.1_b1.3.14` difieren
  en ambos ejes — son imágenes completamente distintas.

### Ejemplos

| Tag | Significado |
|---|---|
| `v2.0.0_n22.21.1_b1.3.14` | Release 2.0.0, matriz Node 22 LTS |
| `v2.0.0_n26.3.1_b1.3.14` | Mismo release, matriz Node 26 |
| `v2.0.1_n22.21.1_b1.3.14` | Bugfix del wrapper, matriz Node 22 |
| `v2.0.1_n26.3.1_b1.3.14` | Mismo bugfix, matriz Node 26 |
| `v2.1.0_n22.21.1_b1.3.14` | Feature compatible (ej. nuevo binario en PATH) |
| `v3.0.0_n22.21.1_b1.3.14` | Cambio incompatible (ej. drop de runtime / otra base) |
| `v2.0.0_n28.0.0_b1.5.0` | Nuevo runtime; X.Y.Z se mantiene si el repo no cambia |
| `v2.0.0_n26.3.1_b1.4.0` | Bump de bun; X.Y.Z se mantiene si el repo no cambia |

### Comandos utiles

```bash
git tag -l "v*_n22.21.1*"             # todas las imagenes con matriz node 22
git tag -l "v*_n26.3.1*"             # todas las imagenes con matriz node 26
git tag -l "v2.0.0_*"                # todas las imagenes con mismas correcciones v2.0.0
git tag -l "v1.*_n22*"               # correcciones v1.x sobre node 22 (cualquier minor/patch)
```

### Ejemplos

| Tag | Significado |
|---|---|
| `v1_n22.12.0_b1.1.42` | Estado legacy (no se publica con el nuevo canon, ver "Tags legacy" abajo) |
| `v2.0.0_n22.21.1_b1.3.14` | Canon vigente: correcciones v2.0.0 + matriz Node 22 |

### Por qué el v{X.Y.Z} es semver ligero (no contador de "republish")

- **El runtime siempre es 3 segmentos.** No se acorta a `n26` o `b1.3`
  porque el patch importa:
  - Node 26.3.0 → 26.3.1 suele traer fixes de V8 (CVEs, optimizaciones JIT).
  - Bun 1.3.0 → 1.3.14 trae fixes acumulados del loader TS y tooling
    (`bun upgrade`, resolver, installer) relevantes para este repo.
- **Self-describing**: el tag codifica exactamente qué correcciones del
  repo y qué runtime hay dentro. No hay que abrir el Dockerfile para
  saber qué hay dentro.
- **Orden lexicográfico = orden cronológico** dentro de la tripleta
  (vX.Y.Z, n..., b...).
- **Grepable**: ver la sección "Comandos utiles" arriba.
- **Las dos dimensiones son independientes**: bumpear el wrapper no
  afecta a la elección del runtime, y viceversa.

---

## Política de tags legacy

Hay **tres** esquemas históricos en uso:

### Esquema 1 (legacy muy viejo, 2024-12 → 2025-11)

Tags `v.1.0.0` … `v.1.1.2` (con punto, semver-like):

- Siguen disponibles en DockerHub con Node 22 + bun 1.1.42.
- Siguen siendo consumidos por runners legacy (no breaking).
- **NO** se reescriben. **NO** se publican más tags con este esquema.

### Esquema 2 (intermedio, 2026-07 → 2026-08, ya descontinuado)

Tags `v{N}_n..._b...` (contador `N` de un dígito, ej. `v1_n26.3.1_b1.3.14`):

- Publicados por error: `v1_n26.3.1_b1.3.14`, `v2_n26.3.1_b1.3.14`,
  `v3_n26.3.1_b1.3.14`, `v4_n26.3.1_b1.3.14`, `v5_n26.3.1_b1.3.14`,
  `v1_n22.21.1_b1.3.14`, `v2_n22.21.1_b1.3.14`, `v3_n22.21.1_b1.3.14`,
  `v4_n22.21.1_b1.3.14`.
- **Problema**: `N` mezclaba "correcciones del repo" con "republish de
  la misma matriz", así que no se podía saber si dos imágenes tenían
  las mismas correcciones solo mirando el tag.
- **NO** se reescriben (ya hay consumidores apuntando). **NO** se
  publican más con este esquema.

### Esquema 3 (vigente desde 2026-08-22)

Tags `v{X.Y.Z}_n..._b...` (semver ligero, este documento).

> ⚠️ Distincion visual:
> - Esquema 1: `v.1.1.2` (con punto, 3 niveles)
> - Esquema 2: `v4_n26.3.1_b1.3.14` (1 nivel despues de `v`)
> - Esquema 3: `v2.0.0_n26.3.1_b1.3.14` (3 niveles despues de `v`)

---

## Política de bump

El bump tiene **dos dimensiones independientes**:

### Dimensión 1: correcciones del repo (X.Y.Z)

Bumpear cuando hay cambios en archivos versionados del repo
(Dockerfile, wrapper, workflows, docs, .dockerignore, etc.):

- **X (major)**: cambios incompatibles. Ejemplos:
  - Drop de versiones legacy de node/bun/fnm.
  - Cambio de base image (de `cartagodocker/zsh` a otra).
  - Cambio de contrato del wrapper que rompe consumidores.
  - Reestructuración de tags o workflows.
- **Y (minor)**: features nuevas compatibles. Ejemplos:
  - Soporte para nuevas matrices en paralelo.
  - Nuevos binarios en PATH por defecto.
  - Nuevas flags del wrapper soportadas.
- **Z (patch)**: bugfixes puros. Ejemplos:
  - Wrapper propaga exit code correctamente (commit bc766fa).
  - Wrapper envia logs a stderr (commit f025a67).
  - Wrapper detecta -G / --global=true (commit ce2b68f).
  - Workflow JSON serialization seguro (commit 26e9d09).
  - Dockerfile sudo install + base pinned (commit f9b45cf).
  - Actions pineadas a SHA (commit 58b97d9).

### Dimensión 2: runtime (n..._b...)

Bumpear cuando cambia node, bun, fnm o npm:

- **Cualquier dígito** de node, bun, fnm o npm cambia → el sufijo
  `n{node}_b{bun}` refleja los nuevos valores.
- El contador `X.Y.Z` **NO** se incrementa automáticamente por
  cambiar el runtime — depende de si la bumpada de runtime trae
  consigo correcciones al repo (no, normalmente) o solo refleja
  una nueva imagen base (tampoco).

### Reglas combinadas

- Cambio solo de runtime (ej. node 22.21.1 → 22.21.2, fix de V8) →
  mismo `X.Y.Z`, sufijo `n` cambia. Ej: `v2.0.0_n22.21.1_b1.3.14` →
  `v2.0.0_n22.21.2_b1.3.14`.
- Cambio solo de correcciones (ej. wrapper bugfix) → `Z` sube,
  sufijo `n..._b...` igual. Ej: `v2.0.0_n22.21.1_b1.3.14` →
  `v1.0.2_n22.21.1_b1.3.14`.
- Cambio de runtime Y de correcciones → ambos suben.
- Cambio de major de node o bun → `X` se mantiene si el contrato del
  repo no cambia. Ej: `v2.0.0_n22.21.1_b1.3.14` → `v2.0.0_n28.0.0_b1.5.0`.

### Política para consumidores

- Fijar la tripleta exacta: `v2.0.0_n22.21.1_b1.3.14`.
- Wildcard por matriz: `v*_n22.21.1_b1.3.14` (cualquier correccion).
- Wildcard por correccion: `v2.0.0_*` (cualquier matriz).
- Wildcard total: `v*` (no recomendado, todo cambia).

---

## Política de publicación

### Single source of truth de X.Y.Z

`X.Y.Z` se declara como `ARG VERSION` en el `Dockerfile`:

```dockerfile
ARG VERSION=2.0.0
```

Y se exporta como `ENV VERSION=${VERSION}` para que `docker inspect`
lo muestre. **Ese ARG es la única fuente de verdad** del contador de
correcciones del repo. VERSIONING.md y CHANGELOG.md documentan la
historia pero no la definen.

### Workflow de release (automatizado por GH Actions)

El workflow `.github/workflows/docker-hub-update.yml` lee
**`.github/matrices.yml`** como única fuente de verdad sobre qué
imágenes se publican.

El workflow distingue dos tipos de tag:

1. **Tag trigger** — `v{X.Y.Z}` (sin sufijo de matriz). Al pushearlo,
   el workflow itera el manifiesto y construye/pushea una imagen por
   cada matriz con `status: active`. Cada imagen se etiqueta con
   `v{X.Y.Z}_{nombre-matriz}`.

2. **Tag matrix** — `v{X.Y.Z}_n..._b...` (con sufijo de matriz). Al
   pushearlo, el workflow construye SOLO esa imagen. Útil para
   re-publicar una matriz específica (ej. tag mal pusheado, fallo
   de un build previo, hotfix de runtime).

Cómo funciona internamente:

```
git tag v2.0.0 && git push origin v2.0.0
  ↓
workflow dispara
  ↓
parsea VERSION_TAG → VERSION=2.0.0, TRIGGER_TAG=v2.0.0, MATRIX_NAME=<none>
  ↓
lee .github/matrices.yml → para cada status:active:
  nombre=n22.21.1_b1.3.14, node=22.21.1, bun=1.3.14, fnm=1.38.1, npm=10.9.4
  nombre=n26.3.1_b1.3.14, node=26.3.1,  bun=1.3.14, fnm=1.39.0, npm=12.0.1
  ↓
para cada entrada del plan:
  ¿tag ya existe en DockerHub? → skip (no-op; bórralo en Hub para republicar)
  docker build --build-arg VERSION=2.0.0 \
               --build-arg NODE_DEFAULT_VERSION=22.21.1 \
               --build-arg BUN_VERSION=1.3.14 \
               --build-arg FNM_VERSION=1.38.1 \
               --build-arg NPM_VERSION=10.9.4 \
               -t cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14 .
  docker push cartagodocker/nodebun:v2.0.0_n22.21.1_b1.3.14
gh release create v2.0.0  (si ya existía, se borra y se recrea)
```

Hub es **idempotente**: si vuelves a pushear el mismo tag, los tags
que ya existen en DockerHub se skipean sin re-build. El **GitHub
Release** sí se recrea (debug: borrar el git tag, arreglar, volver a
subir la misma versión). Para republicar la imagen, borra el tag en
Hub tú.

### El manifesto `.github/matrices.yml`

Es la **única fuente de verdad** sobre qué matrices existen y qué
versiones usan. No mantener ramas paralelas como `n22.21.1_b1.3.14`
para esto (las ramas históricas se conservan por compatibilidad pero
el workflow ya no las lee).

Cómo añadir una nueva matriz:

1. Editar `.github/matrices.yml` y añadir la entrada con `status: active`.
2. Commitear en `main`.
3. Pushear el siguiente tag `v{X.Y.Z}` → la nueva matriz se construye.

Cómo discontinuar una matriz:

1. Cambiar `status: active` → `status: deprecated` en `.github/matrices.yml`.
2. Un tag trigger `v{X.Y.Z}` **omite** las deprecated (`::notice::`).
   Para publicar una deprecated una vez más, pushea el tag matrix
   `v{X.Y.Z}_n…_b…` de esa entrada.
3. Cuando sepas que nadie la consume, eliminarla del manifiesto.

Cómo eliminar una matriz:

1. Quitar la entrada de `.github/matrices.yml`.
2. Commitear en `main`. Los tags ya publicados siguen disponibles en
   DockerHub (este repo no borra imágenes).

### Release manual (mismo flujo, sin GH Actions)

Si necesitas construir imágenes localmente (sin tag trigger):

1. **Editar el `ARG VERSION` del Dockerfile**:
   ```bash
   # Cambiar:
   ARG VERSION=2.0.0
   # A:
   ARG VERSION=2.0.1
   ```
2. **Pushear el tag trigger**:
   ```bash
   git add Dockerfile
   git commit -m "chore: bump VERSION to 2.0.1"
   git tag v2.0.1
   git push origin main v2.0.1
   # El workflow construye las N imágenes en paralelo.
   ```

3. **Actualizar `README.md`** y este `VERSIONING.md` si la política
   cambia.

> No se publica **nunca** `latest` ni `stable` desde este repo: cada
> consumidor debe fijar su tag exacto para tener builds reproducibles.

---

## Cómo marcar roturas estructurales

Las roturas del repo (cambios de contrato, refactors mayores,
nuevas arquitecturas) se registran **en el `X.Y.Z` mismo**, no en
un tag paralelo. Si una versión representa una rotura real, se
bumpea la `X` (major) o se documenta explicitamente en el
CHANGELOG.md como `### Changed` con nota "BREAKING" o similar.

La antigua idea de tags `breakpoint_v{X.Y.Z}` fue rechazada porque:

- Duplicaba información que ya está en el CHANGELOG.
- Anadia complejidad operacional (un tag mas por cada rotura).
- El `X.Y.Z` ya codifica la magnitud del cambio (major/minor/patch).

Para consultar roturas historicas en el futuro:

```bash
# Releases con bump major (cambios incompatibles):
git tag -l 'v[2-9]*.0.0'

# O leer el CHANGELOG.md directamente.
```

---

## Migración de consumidores

Los consumidores que actualmente hacen:

```dockerfile
FROM cartagodocker/nodebun:v.1.1.2
```

deben migrar a:

```dockerfile
FROM cartagodocker/nodebun:v1_n<SU-NODE>_b<SU-BUN>
```

Los consumidores deben pinnear el tag exacto de la matriz que necesitan
(`v{X.Y.Z}_n…_b…`), no `latest`.

---

## Cambios incompatibles respecto al esquema anterior

| Antes (esquema 2) | Ahora (esquema 3) | Por qué |
|---|---|---|
| `v4_n26.3.1_b1.3.14` (contador N) | `v2.0.0_n26.3.1_b1.3.14` (semver ligero X.Y.Z) | Separa "correcciones del repo" de "publicación de la misma matriz" |
| `N` mezclaba dos dimensiones | `X.Y.Z` = correcciones, `n..._b...` = runtime | Se puede saber si dos imágenes tienen las mismas correcciones mirando el tag |
| `v{N}` un solo dígito | `v{X.Y.Z}` tres dígitos (semver) | Más expresivo, escala mejor con el tiempo |

No hay cambios incompatibles respecto al **esquema 1** (`v.1.1.2`) ni al
**tag-naming** (sigue siendo `v*_n*_b*`). Lo que cambia es solo el
significado del segmento `v*`: pasó de "contador de republish" a
"semver ligero de correcciones".

---

## Historial de decisiones

| Fecha | Decisión | Origen |
|---|---|---|
| 2026-07-17 | Adopción del canon `v{N}_n{node}_b{bun}` (separador `_` por OCI) | `x00065` S2 |
| 2026-07-17 | Política de no-rewrite de tags legacy | `x00065` |
| 2026-07-17 | Sin tags `latest`/`stable` | `x00065` |
| 2026-08-22 | Adopción del canon `v{X.Y.Z}_n{node}_b{bun}` (semver ligero) | Discusión con mantenedor: contador `N` mezclaba dos dimensiones |
| 2026-08-22 | `X.Y.Z` se publica en paralelo en todas las matrices | Permite comparar correcciones entre imágenes de distintos runtimes |
| 2026-08-22 | Modelo "tag trigger + manifesto" (`.github/matrices.yml`) | El workflow itera el manifesto y publica una imagen por matriz activa. Elimina la dependencia de ramas paralelas como fuente de runtime. |
| 2026-08-22 | `X.Y.Z` inicial = `2.0.0` (major) | El salto a `2.0.0` marca la rotura mayor del modelo de publicacion: trigger tag + manifesto + eliminacion de ramas de matriz. La "rotura" se registra en el bump X.Y.Z, no en un tag paralelo. |
