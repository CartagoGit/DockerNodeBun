# DockerNodeBun — Versionado canónico

> Documento **canónico** del esquema de versionado a partir de la propuesta
> [`x00065`](https://github.com/CartagoGit/logistics-app/blob/main/docs/mcp-vertex/proposals/ready/x00065-upgrade-runtime-to-node-26-with-aligned-nodebun-image.md)
> del repo `logistics-app` (2026-07-17).
>
> Este archivo es la **fuente de verdad** sobre cómo se versionan y publican
> las imágenes de `cartagodocker/nodebun`. Cualquier consumidor que use
> `FROM cartagodocker/nodebun:<tag>` debe entender este esquema.

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
    Es decir, `v1.0.1_n22.21.1_b1.3.14` y `v1.0.1_n26.3.1_b1.3.14`
    tienen exactamente las mismas correcciones aplicadas al repo.
- **`n{x.y.z}`** y **`b{x.y.z}`** son siempre tres segmentos
  (MAJOR.MINOR.PATCH). Nunca se acortan, porque el patch importa:
  CVEs de V8 en Node y fixes del loader TS en bun justifican el patch.
- **Matrices paralelas**: el repo puede mantener varias matrices
  activas a la vez (ej. `n22.21.1_b1.3.14` para LTS consumers y
  `n26.3.1_b1.3.14` como matriz canónica futura). Cada matriz tiene
  su propia rama git y se publica con el mismo contador `X.Y.Z`.
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

- `v1.0.1_n22.21.1_b1.3.14` y `v1.0.1_n26.3.1_b1.3.14` tienen
  **exactamente las mismas correcciones aplicadas al repo** pero
  distintos runtimes.
- `v1.0.1_n22.21.1_b1.3.14` y `v1.0.2_n22.21.1_b1.3.14` tienen el
  mismo runtime pero distintas correcciones del wrapper/Dockerfile.
- `v1.0.1_n26.3.1_b1.3.14` y `v1.0.2_n22.21.1_b1.3.14` difieren
  en ambos ejes — son imágenes completamente distintas.

### Ejemplos

| Tag | Significado |
|---|---|
| `v1.0.1_n22.21.1_b1.3.14` | Primer release del repo, matriz Node 22 LTS |
| `v1.0.1_n26.3.1_b1.3.14` | Mismo release, matriz Node 26 |
| `v1.0.2_n22.21.1_b1.3.14` | Bugfix del wrapper, matriz Node 22 |
| `v1.0.2_n26.3.1_b1.3.14` | Mismo bugfix del wrapper, matriz Node 26 |
| `v1.1.0_n22.21.1_b1.3.14` | Feature nuevo (ej. nuevo binario en PATH), matriz Node 22 |
| `v2.0.0_n22.21.1_b1.3.14` | Cambio incompatible (ej. drop de Node 18 si se anade), matriz Node 22 |
| `v1.0.1_n28.0.0_b1.5.0` | Cuando salga Node 28 + bun 1.5 — X.Y.Z se mantiene en `v1.0.1` |
| `v1.0.1_n26.3.1_b1.4.0` | Bump de bun a 1.4 — X.Y.Z se mantiene en `v1.0.1` |

### Comandos utiles

```bash
git tag -l "v*_n22.21.1*"             # todas las imagenes con matriz node 22
git tag -l "v*_n26.3.1*"             # todas las imagenes con matriz node 26
git tag -l "v1.0.1_*"                # todas las imagenes con mismas correcciones v1.0.1
git tag -l "v1.*_n22*"               # correcciones v1.x sobre node 22 (cualquier minor/patch)
```

### Ejemplos

| Tag | Significado |
|---|---|
| `v1_n22.12.0_b1.1.42` | Estado legacy (no se publica con el nuevo canon, ver "Tags legacy" abajo) |
| `v1.0.1_n22.21.1_b1.3.14` | Canon vigente: correcciones v1.0.1 + matriz Node 22 |

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
> - Esquema 3: `v1.0.1_n26.3.1_b1.3.14` (3 niveles despues de `v`)

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
  mismo `X.Y.Z`, sufijo `n` cambia. Ej: `v1.0.1_n22.21.1_b1.3.14` →
  `v1.0.1_n22.21.2_b1.3.14`.
- Cambio solo de correcciones (ej. wrapper bugfix) → `Z` sube,
  sufijo `n..._b...` igual. Ej: `v1.0.1_n22.21.1_b1.3.14` →
  `v1.0.2_n22.21.1_b1.3.14`.
- Cambio de runtime Y de correcciones → ambos suben.
- Cambio de major de node o bun → `X` se mantiene en `1`, sufijo cambia.
  Ej: `v1.0.1_n22.21.1_b1.3.14` → `v1.0.1_n28.0.0_b1.5.0`.

### Política para consumidores

- Fijar la tripleta exacta: `v1.0.1_n22.21.1_b1.3.14`.
- Wildcard por matriz: `v*_n22.21.1_b1.3.14` (cualquier correccion).
- Wildcard por correccion: `v1.0.1_*` (cualquier matriz).
- Wildcard total: `v*` (no recomendado, todo cambia).

---

## Política de publicación

### Single source of truth de X.Y.Z

`X.Y.Z` se declara como `ARG VERSION` en el `Dockerfile`:

```dockerfile
ARG VERSION=1.0.1
```

Y se exporta como `ENV VERSION=${VERSION}` para que `docker inspect`
lo muestre. **Ese ARG es la única fuente de verdad** del contador de
correcciones del repo. VERSIONING.md y CHANGELOG.md documentan la
historia pero no la definen.

### Workflow de release (automatizado por GH Actions)

El workflow `.github/workflows/docker-hub-update.yml`:

1. Se dispara al pushear un tag `v*` o manualmente con input `tag_name`.
2. Parsea el tag para extraer `X.Y.Z` con `sed`:
   ```bash
   VERSION=$(echo "$VERSION_TAG" | sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
   ```
3. Construye con `--build-arg VERSION="$VERSION"`.
4. Pushea con el tag completo como IMAGE_TAG.

### Release manual (mismo flujo, sin GH Actions)

Cada vez que se publique un tag nuevo, se hace en este orden:

1. **Editar el ARG VERSION del Dockerfile**:
   ```bash
   # Cambiar:
   ARG VERSION=1.0.1
   # A:
   ARG VERSION=1.0.2
   ```
2. **Commitear el bump + taggear en todas las matrices que apliquen**:
   ```bash
   git add Dockerfile
   git commit -m "chore: bump VERSION to 1.0.1"
   # Para cada rama activa, merge main + tag con la misma X.Y.Z:
   git checkout n22.21.1_b1.3.14
   git merge --no-ff main -m "Merge main into n22.21.1_b1.3.14"
   git tag v1.0.1_n22.21.1_b1.3.14
   git push origin n22.21.1_b1.3.14 --tags
   git checkout n26.3.1_b1.3.14
   # ... mismo flujo ...
   ```
3. **Actualizar `README.md`** y este `VERSIONING.md` si la política cambia.

> No se publica **nunca** `latest` ni `stable` desde este repo: cada
> consumidor debe fijar su tag exacto para tener builds reproducibles.

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

El consumidor canónico de este repo es
[`logistics-app/tools/docker/Dockerfile`](https://github.com/CartagoGit/logistics-app).
La migración se trackea en la propuesta
[`x00065`](https://github.com/CartagoGit/logistics-app/blob/main/docs/mcp-vertex/proposals/ready/x00065-upgrade-runtime-to-node-26-with-aligned-nodebun-image.md),
slice **S3**.

---

## Cambios incompatibles respecto al esquema anterior

| Antes (esquema 2) | Ahora (esquema 3) | Por qué |
|---|---|---|
| `v4_n26.3.1_b1.3.14` (contador N) | `v1.0.1_n26.3.1_b1.3.14` (semver ligero X.Y.Z) | Separa "correcciones del repo" de "publicación de la misma matriz" |
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
