FROM cartagodocker/zsh:latest

USER root

# In version 24.04 of Ubuntu, the user with 1000:1000 is already created with ubuntu name.
ARG CONTAINER_USER=ubuntu
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_HOME=/home/${CONTAINER_USER}

# Versions
ARG NODE_DEFAULT_VERSION=22
ARG BUN_VERSION=1.1.42
ARG FNM_VERSION=1.38.1

ARG TEMPLATE_HOME=/etc/skel
ARG BUN_HOME=/usr/local/bun
ARG FNM_HOME=/usr/local/fnm

ARG FNM_BIN=/usr/local/fnm/bin
ARG BUN_BIN=${BUN_HOME}/bin

ARG BUN_CACHE_FOLDER=/.bun
ARG FNM_CACHE_FOLDER=/.local/share/fnm

ARG BUN_URL=https://bun.sh/install
# ARG FNM_URL=https://fnm.vercel.app/install
ARG FNM_URL=https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${BUN_BIN}:${FNM_BIN}:${PATH} \
    NODE_DEFAULT_VERSION=${NODE_DEFAULT_VERSION} \
    FNM_BIN=${FNM_BIN} \
    BUN_HOME=${BUN_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git ssh ca-certificates \
    # Install fnm
    && curl -fsSL ${FNM_URL} -o /tmp/fnm.zip \
    && mkdir -p ${FNM_BIN} \
    && unzip /tmp/fnm.zip -d ${FNM_BIN} \
    && chmod +x ${FNM_BIN}/fnm \
    && fnm completions --shell zsh > ${FNM_BIN}/_fnm \
    && fnm install ${NODE_DEFAULT_VERSION} \
    && fnm default ${NODE_DEFAULT_VERSION} \
    # Move fnm to the desired location and create a symbolic link to the cache folder
    && mv /root${FNM_CACHE_FOLDER}/* ${FNM_HOME} \
    && rm -rf /root${FNM_CACHE_FOLDER} \
    && mkdir -p ${TEMPLATE_HOME}/.local/share \
    && ln -s ${FNM_HOME} ${TEMPLATE_HOME}${FNM_CACHE_FOLDER} \
    && chmod -R 777 ${FNM_HOME} \ 
    # Install bun
    && curl -fsSL ${BUN_URL} | bash -s bun-v${BUN_VERSION} \
    # Move bun to the desired location and create a symbolic link to the cache folder
    && mkdir -p ${BUN_HOME} \
    && mv /root${BUN_CACHE_FOLDER}/* ${BUN_HOME} \
    && rm -rf /root${BUN_CACHE_FOLDER} \
    && ln -s ${BUN_HOME} ${TEMPLATE_HOME}${BUN_CACHE_FOLDER} \
    && chmod -R 777 ${BUN_HOME} \
    # Apply configuration to existing users' home directories
    # Ensure the root user also gets the configuration
    && for dir in /home/* /root; do \
            if [ -d "$dir" ]; then \
                mkdir -p "$dir/.local/share"; \
                ln -s ${FNM_HOME} $dir${FNM_CACHE_FOLDER}; \
                ln -s ${BUN_HOME} $dir${BUN_CACHE_FOLDER}; \
                rm -rf $dir/.cache; \
                chown -R $(basename $dir):$(basename $dir) $dir; \
            fi; \
        done \
    # Clean run
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Add to .zshrc the configuration for fnm and bun
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asign autocomplete for fnm' \
    'fpath=(${FNM_BIN} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"
