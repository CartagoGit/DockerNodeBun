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
ARG BUN_HOME=${TEMPLATE_HOME}/.bun/bin
ARG FNM_HOME=/usr/local/fnm

ARG BUN_URL=https://bun.sh/install
# ARG FNM_URL=https://fnm.vercel.app/install
ARG FNM_URL=https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=${FNM_HOME}:${PATH} \
    NODE_DEFAULT_VERSION=${NODE_DEFAULT_VERSION} \
    FNM_HOME=${FNM_HOME} 

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git ssh ca-certificates \
    # Install fnm
    && curl -fsSL ${FNM_URL} -o /tmp/fnm.zip \
    && unzip /tmp/fnm.zip -d ${FNM_HOME} \
    && chmod +x ${FNM_HOME}/fnm \
    && fnm completions --shell zsh > ${FNM_HOME}/_fnm \
    && fnm install ${NODE_DEFAULT_VERSION} \
    && fnm default ${NODE_DEFAULT_VERSION} \
    && eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION} \
    && mkdir -p ${TEMPLATE_HOME}/.local/share \
    && cp -r /root/.local/share/fnm ${TEMPLATE_HOME}/.local/share/fnm \
    && chmod -R 755 ${FNM_HOME} \
    # Install bun
    && curl -fsSL ${BUN_URL} | bash -s bun-v${BUN_VERSION} \
    && mv /root/.bun/bin/bun /usr/local/bin/ \
    && chmod a+x /usr/local/bin/bun \
    # Apply configuration to existing users' home directories
    # Ensure the root user also gets the configuration
    && for dir in /home/* /root; do \
            if [ -d "$dir" ]; then \
                mkdir -p "$dir/.local/share"; \
                cp -rf ${TEMPLATE_HOME}/.local/share/fnm $dir/.local/share/fnm; \
                chown -R $(basename $dir):$(basename $dir) $dir; \
            fi; \
        done \
    # Clean run
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache


# Add to .zshrc the configuration for fnm and bun
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asign autocomplete for fnm' \
    'fpath=(${FNM_HOME} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_DEFAULT_VERSION}' \
    'alias bunx="bun x"' \
    )"
