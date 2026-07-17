# DockerNodeBun

## Github

https://github.com/CartagoGit/DockerNodeBun

## DockerHub

https://hub.docker.com/repository/docker/cartagodocker/nodebun/general

## Description

Image for charging bun, fnm, node, npm and zsh.

> This dockerfile use Ubuntu 24.04

> This dockerfile use [`cartagodocker/zsh`](https://hub.docker.com/repository/docker/cartagodocker/zsh/general) image as base.

## Versioning

> **Canónico a partir de 2026-07-17.**
> Ver [VERSIONING.md](./VERSIONING.md) para la política completa.
>
> Esquema de tag: `v{N}+n{node MAJOR.MINOR.PATCH}+b{bun MAJOR.MINOR.PATCH}`
> donde `N` es un contador entero de re-publicaciones para la misma matriz
> de runtimes.

## Specifications:


- Zsh (base: `cartagodocker/zsh:latest`)
- Bun.js 1.3.2 (with automatic AVX2/baseline detection)
- Fast Node Manager 1.38.1
- Npm 10.9.0

### Imágenes publicadas

| Tag | Node | Bun | Notas |
|---|---|---|---|
| `v1+n26.3.1+b1.3.2` | 26.3.1 | 1.3.2 | próximo release (S2 de x00065) |

### Imagen legacy (no se publica más con este canon)

- Bun.js 1.1.42
- Node 22 lts
- Tag legacy: `v.1.1.2` (sigue disponible en DockerHub, no se reescribe)

## Environments

- NODE_DEFAULT_VERSION=26.3.1
- FNM_HOME=/usr/share/fnm
- BUN_HOME=/usr/share/bun
- BUN_INSTALL=/usr/share/bun

You can use this envs to set the default node version and the fnm home in inherited images.

For example:

```Dockerfile
RUN eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION}
```

Or if you want change the default node version in the inherited image:

```Dockerfile
FROM cartagodocker/nodebun:latest
ENV NODE_DEFAULT_VERSION=14
```

---

# Usage

## Create Image

````bash
docker build -t nodebun-image -f ./Dockerfile ./
````

## Create debug-container

````bash
docker run --rm -it --name nodebun-container nodebun-image
````

## Create debug-container for user 1000:1000

````bash
docker run --rm -it --name nodebun-container --user 1000:1000 nodebun-image
````

## Upload docker image to dockerhub

With github actions in repository it will be update automaticatlly in DockerHub with the tag of branches.

## To use in other docker images

> ⚠️ **No se publica `latest`.** Cada consumidor debe fijar la matriz
> exacta de runtimes. Ver [VERSIONING.md](./VERSIONING.md).

Just add the next line in the Dockerfile to base the other image on this one.

````Dockerfile 
FROM cartagodocker/nodebun:v1+n26.3.1+b1.3.2
````

---

# For use node in inherited images:

You can use the next line in the Dockerfile to use the default node version:

```Dockerfile
FROM cartagodocker/nodebun:latest
RUN eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION}  \
    && npm --version && node --version
```

> Important: It is necessary to use `eval $(fnm env)` to assign path to node and npm for the user. And it is necessary to use `fnm use` to set the node version.

Fast node manager works with multishell, it means that you can use different node versions in different shell sessions.

For that if you want use a new RUN, eval $(fnm env) must be called to assign node and npm to the $PATH fo the user.

I added an automatic load node for the user in the entrypoint of the .zshrc file. But it necessary understand that if we call a new RUN in Dockerfile the $PATH will be reset, and we must call `eval $(fnm env)` to assign the path to node and npm again.

> Important install dependencies globally with bun, and give permissions to the user you want to use it.

If you install a dependency with fnm like -> `npm install -g @ionic/cli`, it will be installed just for this shell session. If you want to use it in other shell session, you must install again. Then, I recommend to use bun to install global dependencies to share between shell and user sessions.

---

# For specific inner scripts:

Look the cartagodocker/zsh image documentation in the next link:

[`cartagodocker/zsh`](https://hub.docker.com/repository/docker/cartagodocker/zsh/general)
