FROM cartagodocker/zsh:latest
USER root

# Versions
ARG NODE_DEFAULT_VERSION=22
ARG BUN_VERSION=1.1.42
ARG FNM_VERSION=1.38.1

ARG SHARE_HOME=/usr/share

ARG BUN_HOME=${SHARE_HOME}/bun
ARG FNM_HOME=${SHARE_HOME}/fnm

ARG FNM_BIN=${FNM_HOME}/bin
ARG BUN_BIN=${BUN_HOME}/bin

ARG BUN_URL=https://bun.sh/install
ARG FNM_URL=https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${BUN_BIN}:${FNM_BIN}:${PATH} \
    NODE_DEFAULT_VERSION=${NODE_DEFAULT_VERSION} \
    FNM_BIN=${FNM_BIN} \
    BUN_HOME=${BUN_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip ca-certificates \
    # Install fnm
    && curl -fsSL ${FNM_URL} -o /tmp/fnm.zip \
    && mkdir -p ${FNM_BIN} \
    && unzip /tmp/fnm.zip -d ${FNM_BIN} \
    && chmod +x ${FNM_BIN}/fnm \
    && fnm completions --shell zsh > ${FNM_BIN}/_fnm \
    && fnm install ${NODE_DEFAULT_VERSION} \
    && fnm default ${NODE_DEFAULT_VERSION} \
    # Move fnm to the desired location and create a symbolic link to the cache folder
    && share_config_globally .local/share/fnm --to fnm \
    # Install bun
    && curl -fsSL ${BUN_URL} | bash -s bun-v${BUN_VERSION} \
    # Move bun to the desired location and create a symbolic link to the cache folder
    && share_config_globally .bun --to bun \
    # Clean run
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Add to .zshrc the configuration for fnm and bun
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asign autocomplete for fnm' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"
