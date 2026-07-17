# DockerNodeBun — Versionado canónico

> Documento **canónico** del esquema de versionado a partir de la propuesta
> [`x00065`](https://github.com/CartagoGit/logistics-app/blob/main/docs/mcp-vertex/proposals/ready/x00065-upgrade-runtime-to-node-26-with-aligned-nodebun-image.md)
> del repo `logistics-app` (2026-07-17).
>
> Este archivo es la **fuente de verdad** sobre cómo se versionan y publican
> las imágenes de `cartagodocker/nodebun`. Cualquier consumidor que use
> `FROM cartagodocker/nodebun:<tag>` debe entender este esquema.

---

## Esquema vigente

```
v{N}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
```

Donde:

- **`N`** es un **contador entero** (1, 2, 3, …) que se incrementa cada vez
  que se re-publica la imagen con la **misma** combinación de node y bun.
  **No es semver. No es CalVer.** Es un contador de re-publicaciones para
  una matriz de runtimes fija.
- **`n{x.y.z}`** y **`b{x.y.z}`** son siempre tres segmentos
  (MAJOR.MINOR.PATCH). Nunca se acortan, porque el patch importa:
  CVEs de V8 en Node y fixes del loader TS en bun justifican el patch.
- El separador `_` (underscore) se eligió por **compatibilidad con el
  OCI Distribution Spec** que DockerHub y la mayoría de registries aplican
  a los tags (regex `[a-z0-9][a-z0-9._-]{0,127}`). El `+` (estilo
  Debian/PEP 440) es más familiar pero DockerHub lo rechaza con
  `invalid reference format`. El `_` se parsea correctamente en todas
  las herramientas que importan (Bash, regex, `sort`, `git tag -l`).

### Ejemplos

| Tag | Significado |
|---|---|
| `v1_n22.12.0_b1.1.42` | Estado actual de la imagen legacy (no se publica con este canon) |
| `v1_n26.3.1_b1.3.14` | **Próximo tag** (S2 de x00065) — primera publicación con Node 26 + bun 1.3.14 |
| `v2_n26.3.1_b1.3.14` | Rebuild futuro de la misma matriz (p. ej. fix en `scripts/`) |
| `v1_n28.0.0_b1.5.0` | Cuando salga Node 28 LTS — contador reinicia a `v1` |
| `v1_n26.3.1_b1.4.0` | Bump de bun a 1.4.0 — contador reinicia a `v1` |

### Por qué este esquema

1. **El `v` no es semver.** No hay `v1.2.0` con tres niveles. El `v` cuenta
   cuántas veces has publicado **esta** combinación de runtimes. Como node
   y bun casi nunca cambian a la vez, `v` casi siempre será `v1`, y eso está
   bien: significa que la imagen está en su primera publicación para esa
   matriz.
2. **El runtime siempre es 3 segmentos.** No se acorta a `n26` o `b1.3`
   porque el patch importa:
   - Node 26.3.0 → 26.3.1 suele traer fixes de V8 (CVEs, optimizaciones JIT).
   - Bun 1.3.0 → 1.3.14 trae fixes acumulados del loader TS y tooling (`bun upgrade`, resolver, installer) relevantes para este repo.
3. **Self-describing**: el tag codifica exactamente qué runtime arranca.
   No hay que abrir el Dockerfile para saber qué hay dentro.
4. **Orden lexicográfico = orden cronológico** dentro de cada matriz.
5. **Grepable**:
   ```bash
   git tag -l "v*_n26.3.1_b1.3.14*"  # todas las re-publicaciones de esa matriz
   git tag -l "v*_n26*"             # todas las imágenes de Node 26.x
   ```
6. **Sin colisión con semver**: el `v` aquí es un contador de un solo
   dígito natural (1, 2, 3, …), nada que ver con `v1.2.0` tradicional.

---

## Política de tags legacy

Los tags `v.1.0.0` … `v.1.1.2` existentes **NO se reescriben**:

- Siguen disponibles en DockerHub con Node 22 + bun 1.1.42.
- Siguen siendo consumidos por runners legacy (no breaking).
- No se publican más tags con el esquema viejo a partir de este documento.

> ⚠️ Nota: los tags legacy usan `v.MAJOR.MINOR.PATCH` (con punto) mientras
> que el nuevo canon usa `v{N}` (sin punto, un solo dígito). Es deliberado
> para que sea trivial distinguir visualmente un tag viejo de uno nuevo.

---

## Política de bump

- **Cambio de cualquier dígito de node o bun** → `v1_...` (el contador
  reinicia porque cambia la matriz de runtimes).
- **Rebuild de la misma matriz** (fix en `scripts/`, bump de imagen base,
   limpieza de caché, etc.) → `v2_...`, `v3_...`, etc. **Sin tocar runtime**.
- **Cambio de major de node o bun** → `v1_...` con la nueva matriz.
- El consumidor puede fijar la matriz exacta (`v1_n26.3.1_b1.3.14`)
  o seguir el head con un major+runtime pinned (no recomendado en CI).

---

## Política de publicación

Cada vez que se publique un tag nuevo, se hace en este orden:

1. **Build & push a DockerHub**:
   ```bash
   docker build -t cartagodocker/nodebun:<TAG> -f ./Dockerfile .
   docker push cartagodocker/nodebun:<TAG>
   ```
2. **Tag git local + push**:
   ```bash
   git tag <TAG>
   git push origin <TAG>
   ```
3. **Actualizar `README.md`** (tabla de versiones) y este `VERSIONING.md`
   si la política cambia.

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

| Antes | Ahora | Por qué |
|---|---|---|
| `v.1.1.2` (semver) | `v1_n22.12.0_b1.1.42` (canon nuevo) | Self-describing, no opaco |
| `v` con tres niveles | `v{N}` con un dígito | Contador, no semver |
| `Bun.js 1.1.42` en README | `v1_n..._b1.1.42` en tag | Fuente de verdad única |
| Imágenes con `latest` | Imágenes con matriz exacta | Builds reproducibles |

---

## Historial de decisiones

| Fecha | Decisión | Origen |
|---|---|---|
| 2026-07-17 | Adopción del canon `v{N}_n{node}_b{bun}` (separador `_` por OCI) | `x00065` S2 |
| 2026-07-17 | Política de no-rewrite de tags legacy | `x00065` |
| 2026-07-17 | Sin tags `latest`/`stable` | `x00065` |
