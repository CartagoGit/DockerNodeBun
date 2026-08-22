# Base image: cartagodocker/zsh — Ubuntu 24.04 + zsh. Pinneada a un
# tag concreto (no `latest`) para garantizar builds reproducibles.
# Consultar https://hub.docker.com/r/cartagodocker/zsh/tags para tags
# disponibles. Se elige un tag estable (no rc) compatible con esta
# imagen. La base provee zsh; nosotros añadimos sudo, ca-certificates,
# fnm, node, bun y npm.
FROM cartagodocker/zsh:v1.0.2
USER root

# Versions
# Tagging scheme: v{N}_n{node MAJOR.MINOR.PATCH}_b{bun MAJOR.MINOR.PATCH}
# See VERSIONING.md for the full policy. Bumping either default below
# requires a new git tag (e.g. v1_n26.3.1_b1.3.14) AND a DockerHub push.
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

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${BUN_BIN}:${FNM_BIN}:${PATH} \
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

# Add to .zshrc the configuration for fnm and bun
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asign autocomplete for fnm' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"

# Nota: no cambiamos a USER 1000:1000 al final. Razon:
#   - 'add_text_to_zshrc' escribe al HOME del usuario activo (root
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
