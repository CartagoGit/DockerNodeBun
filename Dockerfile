FROM cartagodocker/zsh:latest
USER root

# Versions
ARG NODE_DEFAULT_VERSION=22
ARG BUN_VERSION=1.3.2
ARG FNM_VERSION=1.38.1

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
    # Move bun to the desired location and create a symbolic link to the cache folder
    && share_config_globally .bun --to bun \
    # Clean run
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* || true

# Add to .zshrc the configuration for fnm and bun
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asign autocomplete for fnm' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"
