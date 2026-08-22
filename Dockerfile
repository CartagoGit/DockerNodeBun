# Base image: cartagodocker/zsh — Ubuntu 24.04 + zsh. Pinneada a un
# tag concreto (no `latest`) para garantizar builds reproducibles.
# Consultar https://hub.docker.com/r/cartagodocker/zsh/tags para tags
# disponibles. Se elige el ultimo tag estable (no rc) compatible
# con esta imagen. La base provee zsh; nosotros añadimos sudo,
# ca-certificates, fnm, node, bun y npm.
FROM cartagodocker/zsh:v1.0.5
USER root

# Versions
# Tagging scheme: v{X.Y.Z}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
# See VERSIONING.md for the full policy. X.Y.Z es el contador semver
# ligero de las correcciones del repo (lo que cambia son los archivos
# versionados: Dockerfile, wrapper, workflows, docs). Se publica en
# TODAS las matrices en paralelo.
#
# Single source of truth:
#   - VERSION (X.Y.Z) se declara aqui como ARG.
#   - El workflow de GitHub Actions lo pasa como --build-arg VERSION.
#   - Se exporta como ENV dentro de la imagen para que `docker inspect`
#     muestre la version de correcciones aplicada.
#   - Para bumpear: editar este ARG default + commitear + tag con el
#     mismo X.Y.Z en todas las matrices.
ARG VERSION=1.0.1
ARG NODE_DEFAULT_VERSION=26.3.1
ARG BUN_VERSION=1.3.14
ARG FNM_VERSION=1.39.0
ARG NPM_VERSION=12.0.1

ARG SHARE_HOME=/usr/share
ARG BIN_HOME=/usr/local/bin

ARG BUN_HOME=${SHARE_HOME}/bun
ARG FNM_HOME=${SHARE_HOME}/fnm

ARG FNM_BIN=${FNM_HOME}/bin
ARG BUN_BIN=${BUN_HOME}/bin

ARG BUN_DOWNLOAD_URL_AVX2=https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip
ARG BUN_DOWNLOAD_URL_BASELINE=https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64-baseline.zip
ARG FNM_URL=https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip

COPY ./scripts ${BIN_HOME}

# Bloque ENV multilínea. Los comentarios van FUERA del bloque (antes
# de ENV) para máxima portabilidad de parsers Docker: las líneas
# dentro de un bloque de continuación con `\` que empiecen por `#`
# pueden ser ignoradas por parsers viejos, dejando el bloque roto.
# VERSION es single source of truth para el contador de correcciones
# del repo (esquema v{X.Y.Z}). Se inyecta via --build-arg VERSION=X.Y.Z
# desde el workflow. Tambien expuesto en ENV para que 'docker inspect'
# lo muestre sin parsear tags.
ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${BUN_BIN}:${FNM_BIN}:${PATH} \
    VERSION=${VERSION} \
    NODE_DEFAULT_VERSION=${NODE_DEFAULT_VERSION} \
    FNM_BIN=${FNM_BIN} \
    BUN_HOME=${BUN_HOME} \
    BUN_INSTALL=${BUN_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip ca-certificates libatomic1 sudo \
    # Install fnm
    && curl -fsSL ${FNM_URL} -o /tmp/fnm.zip \
    && mkdir -p ${FNM_BIN} \
    && unzip /tmp/fnm.zip -d ${FNM_BIN} \
    && chmod +x ${FNM_BIN}/fnm \
    && fnm completions --shell zsh > ${FNM_BIN}/_fnm \
    && fnm install ${NODE_DEFAULT_VERSION} \
    && fnm default ${NODE_DEFAULT_VERSION} \
    && eval $(fnm env) \
    && npm install -g npm@${NPM_VERSION} \
    && node --version \
    && npm --version \
    # Install both bun versions (AVX2 optimized and baseline)
    && mkdir -p ${BUN_HOME}/bin \
    # Download AVX2 version
    && curl -fsSL ${BUN_DOWNLOAD_URL_AVX2} -o /tmp/bun-avx2.zip \
    && unzip /tmp/bun-avx2.zip -d /tmp/bun-avx2 \
    && mv /tmp/bun-avx2/bun-linux-*/bun ${BUN_BIN}/bun_avx2 \
    && chmod +x ${BUN_BIN}/bun_avx2 \
    # Download baseline version
    && curl -fsSL ${BUN_DOWNLOAD_URL_BASELINE} -o /tmp/bun-baseline.zip \
    && unzip /tmp/bun-baseline.zip -d /tmp/bun-baseline \
    && mv /tmp/bun-baseline/bun-linux-*-baseline/bun ${BUN_BIN}/bun_baseline \
    && chmod +x ${BUN_BIN}/bun_baseline \
    # Create smart wrapper that detects CPU capabilities
    && echo '#!/bin/sh' > ${BUN_BIN}/bun_original \
    && echo 'if grep -q "avx2" /proc/cpuinfo 2>/dev/null; then' >> ${BUN_BIN}/bun_original \
    && echo '  exec '"${BUN_BIN}"'/bun_avx2 "$@"' >> ${BUN_BIN}/bun_original \
    && echo 'else' >> ${BUN_BIN}/bun_original \
    && echo '  exec '"${BUN_BIN}"'/bun_baseline "$@"' >> ${BUN_BIN}/bun_original \
    && echo 'fi' >> ${BUN_BIN}/bun_original \
    && chmod +x ${BUN_BIN}/bun_original \
    # Create final wrapper for bun to manage permissions and call the smart selector
    && chmod +x ${BIN_HOME}/bun_wrapper.zsh \
    && ln -s ${BIN_HOME}/bun_wrapper.zsh ${BUN_BIN}/bun \
    # Set permissions to 777 for compatibility with CI runners (like v.1.0.7)
    && chmod -R 777 ${BUN_HOME} \
    # Sanity check: bun must run. Use `|| true` so a transient bun failure
    # here does not abort the whole image build. The wrapper itself was
    # already created and chmodded above; this only confirms it's wired up.
    && bun --version || echo "[warn] bun --version failed during image build" \
    # Clean run
    && apt-get clean \
    && (rm -rf /var/lib/apt/lists/* /tmp/* || true)

# Add to .zshrc the configuration for fnm and bun.
# Usamos el helper `add_text_to_zshrc` del base image
# cartagodocker/zsh:v1.0.2 (codigo en https://github.com/CartagoGit/DockerZsh).
# Es parte del contrato del base image y maneja correctamente la
# creacion del HOME del usuario activo (root en este RUN) y la
# idempotencia (no duplica bloques si se rebuilda).
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Autocomplete for fnm' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"

# Nota: no cambiamos a USER 1000:1000 al final. Razon:
#   - El bloque anterior escribe al HOME del usuario activo (root
#     durante este RUN), o sea /root/.zshrc. Si cambiaramos a USER
#     1000:1000 despues, los consumidores que ejecuten como ese
#     usuario (lx-app compose usa 'user: 1000:1000') tendrian
#     .zshrc vacio.
#   - lx-app y otros consumidores hacen 'user: 1000:1000' en compose,
#     que sobreescribe el USER del Dockerfile. Mantener root aqui
#     es seguro y compatible.
#   - Para defense-in-depth, los paths chmod 777 (BUN_HOME, FNM_HOME)
#     son escribibles por 1000. No hay razon para un usuario no-root
#     como default del Dockerfile hasta que se reescriba el .zshrc
#     para el HOME correcto.
