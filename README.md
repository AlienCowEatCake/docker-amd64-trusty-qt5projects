# docker-amd64-trusty-qt5projects
Dockerfile for Ubuntu 14.04 build environment for Qt 5.x projects

## Build

```bash
docker build --platform linux/amd64 -t aliencoweatcake/amd64-trusty-qt5projects:qt5.15.15 .
docker build --platform linux/arm64 -t aliencoweatcake/arm64-trusty-qt5projects:qt5.15.15 .
docker build --platform linux/i386 -t aliencoweatcake/i386-trusty-qt5projects:qt5.15.15 .
```

## Docker Hub

* https://hub.docker.com/r/aliencoweatcake/amd64-trusty-qt5projects
* https://hub.docker.com/r/aliencoweatcake/arm64-trusty-qt5projects
* https://hub.docker.com/r/aliencoweatcake/i386-trusty-qt5projects
