# Base image: cartagodocker/zsh — Ubuntu 24.04 + zsh. Pinneada a un
# tag concreto (no `latest`) para garantizar builds reproducibles.
# Consultar https://hub.docker.com/r/cartagodocker/zsh/tags para tags
# disponibles. Esta version de NodeBun pinnea
# cartagodocker/zsh:v2.0.0. zsh 2.0.0 aporta unzip, ca-certificates,
# sudo, dockerzsh y CMD sin ENTRYPOINT: NodeBun no los reinstala.
FROM cartagodocker/zsh:v2.0.0
USER root
# zsh 2.0.0 already uses SHELL ["/bin/sh", "-c"]. Keep it explicit
# so RUN with quotes / $(...) is POSIX.
SHELL ["/bin/sh", "-c"]

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
ARG VERSION=2.0.0
ARG NODE_DEFAULT_VERSION=26.3.1
ARG BUN_VERSION=1.3.14
ARG FNM_VERSION=1.39.0
ARG NPM_VERSION=12.0.1

ARG SHARE_HOME=/usr/share
ARG BIN_HOME=/usr/local/bin

ARG BUN_HOME=${SHARE_HOME}/bun
ARG FNM_HOME=${SHARE_HOME}/fnm
# Store de versiones Node (no el binario). Vive junto a FNM_HOME para
# que todos los uid vean las mismas instalaciones. 777 a proposito:
# cualquier usuario del contenedor puede `fnm install` / `fnm use`
# (mismo contrato que BUN_HOME). El default de la imagen no depende
# de eso: node/npm/npx estan en /usr/local/bin.
ARG FNM_DIR=${FNM_HOME}/store
ARG NODE_BIN=${BIN_HOME}

ARG FNM_BIN=${FNM_HOME}/bin
ARG BUN_BIN=${BUN_HOME}/bin

ARG BUN_DOWNLOAD_URL_AVX2=https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip
ARG BUN_DOWNLOAD_URL_BASELINE=https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64-baseline.zip
ARG FNM_URL=https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip

# Solo lo que NodeBun aporta. sudo / add_text_to_* / dockerzsh vienen
# de cartagodocker/zsh:v2.0.0. No copiar scripts sudo de este repo
# (no hay: esta imagen exige esa base).
COPY scripts/bun_wrapper.zsh \
     scripts/in-bash \
     scripts/in-sh \
     scripts/only-in-container \
     scripts/skip-if-container \
     scripts/nodebun-profile.sh \
     scripts/dockernodebun \
     ${BIN_HOME}/

# Bloque ENV multilínea. Los comentarios van FUERA del bloque (antes
# de ENV) para máxima portabilidad de parsers Docker: las líneas
# dentro de un bloque de continuación con `\` que empiecen por `#`
# pueden ser ignoradas por parsers viejos, dejando el bloque roto.
# VERSION es single source of truth para el contador de correcciones
# del repo (esquema v{X.Y.Z}). Se inyecta via --build-arg VERSION=X.Y.Z
# desde el workflow. Tambien expuesto en ENV para que 'docker inspect'
# lo muestre sin parsear tags.
# NODEBUN_IMAGE_VERSION = this image. A child FROM nodebun that sets
# its own VERSION must not make dockernodebun --version lie (same idea
# as ZSH_IMAGE_VERSION on cartagodocker/zsh).
ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${NODE_BIN}:${BUN_BIN}:${FNM_BIN}:${PATH} \
    VERSION=${VERSION} \
    NODEBUN_IMAGE_VERSION=${VERSION} \
    NODE_DEFAULT_VERSION=${NODE_DEFAULT_VERSION} \
    FNM_BIN=${FNM_BIN} \
    FNM_DIR=${FNM_DIR} \
    FNM_HOME=${FNM_HOME} \
    BUN_HOME=${BUN_HOME} \
    BUN_INSTALL=${BUN_HOME} \
    IS_INTO_CONTAINER=true

# Comentarios FUERA del bloque RUN (un `#` a mitad de `\` trunca el
# instruction en parsers Docker/BuildKit). Contrato:
#   1. FNM_DIR global -> fnm install no escribe en /root/.local.
#   2. node/npm/npx en /usr/local/bin -> cualquier uid/shell, sin fnm use.
#   3. symlink ~/.local/share/fnm + /etc/skel -> usuarios nuevos.
#      También ~/.local/state (fnm multishells) y chown de ~/.local al
#      dueño del home: mkdir como root dejaba uid 1000 sin escribir.
#   4. store 777 (como bun): cualquier uid puede instalar/cambiar Node.
#   5. unzip + ca-certificates + sudo: los trae cartagodocker/zsh:v2.0.0.
#      No reinstalar. Esta imagen no arranca sobre zsh 1.0.5.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    && test -x ${BIN_HOME}/sudo-password \
    && test -f /etc/sudoers.d/container-nopasswd \
    && test -x ${BIN_HOME}/dockerzsh \
    && curl -fsSL ${FNM_URL} -o /tmp/fnm.zip \
    && mkdir -p ${FNM_BIN} ${FNM_DIR} \
    && unzip /tmp/fnm.zip -d ${FNM_BIN} \
    && chmod +x ${FNM_BIN}/fnm \
    && fnm completions --shell zsh > ${FNM_BIN}/_fnm \
    && fnm install ${NODE_DEFAULT_VERSION} \
    && fnm default ${NODE_DEFAULT_VERSION} \
    && eval "$(fnm env --shell bash)" \
    && fnm use ${NODE_DEFAULT_VERSION} \
    && npm install -g npm@${NPM_VERSION} \
    && node --version \
    && npm --version \
    && NODE_INSTALLATION="${FNM_DIR}/node-versions/v${NODE_DEFAULT_VERSION}/installation" \
    && test -x "${NODE_INSTALLATION}/bin/node" \
    && ln -sfn "${NODE_INSTALLATION}/bin/node" ${NODE_BIN}/node \
    && ln -sfn "${NODE_INSTALLATION}/bin/npm"  ${NODE_BIN}/npm \
    && ln -sfn "${NODE_INSTALLATION}/bin/npx"  ${NODE_BIN}/npx \
    && if [ -x "${NODE_INSTALLATION}/bin/corepack" ]; then ln -sfn "${NODE_INSTALLATION}/bin/corepack" ${NODE_BIN}/corepack; fi \
    && ln -sfn ${FNM_BIN}/fnm ${NODE_BIN}/fnm \
    && chmod -R 777 ${FNM_HOME} \
    && for dir in /home/* /root /etc/skel; do \
         if [ -d "$dir" ]; then \
           mkdir -p "$dir/.local/share" "$dir/.local/state"; \
           rm -rf "$dir/.local/share/fnm"; \
           ln -sfn "${FNM_DIR}" "$dir/.local/share/fnm"; \
           if [ "$dir" != /etc/skel ]; then \
             chown -R "$(stat -c '%u:%g' "$dir")" "$dir/.local"; \
           fi; \
         fi; \
       done \
    && mkdir -p ${BUN_HOME}/bin \
    && curl -fsSL ${BUN_DOWNLOAD_URL_AVX2} -o /tmp/bun-avx2.zip \
    && unzip /tmp/bun-avx2.zip -d /tmp/bun-avx2 \
    && mv /tmp/bun-avx2/bun-linux-*/bun ${BUN_BIN}/bun_avx2 \
    && chmod +x ${BUN_BIN}/bun_avx2 \
    && curl -fsSL ${BUN_DOWNLOAD_URL_BASELINE} -o /tmp/bun-baseline.zip \
    && unzip /tmp/bun-baseline.zip -d /tmp/bun-baseline \
    && mv /tmp/bun-baseline/bun-linux-*-baseline/bun ${BUN_BIN}/bun_baseline \
    && chmod +x ${BUN_BIN}/bun_baseline \
    && printf '%s\n' '#!/bin/sh' 'if grep -q "avx2" /proc/cpuinfo 2>/dev/null; then' "  exec ${BUN_BIN}/bun_avx2 \"\$@\"" 'else' "  exec ${BUN_BIN}/bun_baseline \"\$@\"" 'fi' > ${BUN_BIN}/bun_original \
    && chmod +x ${BUN_BIN}/bun_original \
    && chmod +x ${BIN_HOME}/bun_wrapper.zsh \
    && ln -s ${BIN_HOME}/bun_wrapper.zsh ${BUN_BIN}/bun \
    && ln -sfn ${BUN_BIN}/bun ${NODE_BIN}/bun \
    && chmod +x ${BIN_HOME}/in-bash ${BIN_HOME}/in-sh ${BIN_HOME}/skip-if-container ${BIN_HOME}/only-in-container \
    && chmod +x ${BIN_HOME}/bun_wrapper.zsh ${BIN_HOME}/dockernodebun \
    && install -m 0644 ${BIN_HOME}/nodebun-profile.sh /etc/profile.d/nodebun.sh \
    && if [ -f /etc/bash.bashrc ]; then printf '\n# nodebun login/non-login bash\n. /etc/profile.d/nodebun.sh\n' >> /etc/bash.bashrc; fi \
    && chmod -R 777 ${BUN_HOME} \
    && test -x ${BUN_BIN}/bun_avx2 \
    && test -x ${BUN_BIN}/bun_baseline \
    && bun --version \
    && apt-get clean \
    && (rm -rf /var/lib/apt/lists/* /tmp/* || true)

# zshrc: setup oficial de fnm (https://github.com/Schniz/fnm#shell-setup).
# `fnm env` por sesion; `fnm default` ya apunta a la matriz, asi que
# el eval activa esa version. `fnm use` explicito por si acaso.
# Sin --use-on-cd: un .nvmrc del repo montado no debe saltar de matriz.
# Sin --use-on-cd=false: fnm 1.38.1 no acepta valor (rompe el eval).
# sh/bash no-interactivo usa /usr/local/bin/node (mismo default).
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Autocomplete + official fnm shell setup (matrix Node is the default)' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval "$(fnm env --shell zsh)"' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )" \
    && if ! grep -q apply-sudo-password-on-boot /usr/share/globally/.zshrc 2>/dev/null; then \
         add_text_to_zshrc '[ -x /usr/local/bin/apply-sudo-password-on-boot.sh ] && /usr/local/bin/apply-sudo-password-on-boot.sh || true'; \
       fi

# USER del Dockerfile se queda en root. Consumidores no-root
# (compose: user: 1000:1000) lo pisan. Node/fnm no
# dependen del HOME: FNM_DIR es global y node esta en /usr/local/bin.
