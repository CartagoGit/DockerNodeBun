# DockerNodeBun

## DockerHub

https://hub.docker.com/repository/docker/cartagodocker/nodebun/general

## Description

Image for charging bun, fnm, node, npm and zsh.

> This dockerfile use Ubuntu 24.04

> This dockerfile use [```cartagodocker/zsh```](https://hub.docker.com/repository/docker/cartagodocker/zsh/general) image as base.


## Environments

- NODE_DEFAULT_VERSION=22
- FNM_HOME=/usr/share/fnm
- BUN_HOME=/usr/share/bun

You can use this envs to set the default node version and the fnm home in inherited images.

For example:

```Dockerfile
RUN eval $(fnm env) && fnm use ${NODE_DEFAULT_VERSION}
```

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

Just add the next line in the Dockerfile to base the other image on this one.

````Dockerfile 
FROM cartagodocker/nodebun:latest
````

## For specific inner scripts:

Look the cartagodocker/zsh image documentation in the next link:

https://hub.docker.com/repository/docker/cartagodocker/zsh/general

