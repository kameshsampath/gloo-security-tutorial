# Gloo Edge Security Tutorial

 [![Gloo Edge v1.8.7](https://img.shields.io/badge/Gloo%20Edge-v1.8.7-blue)](https://docs.solo.io/gloo-edge/latest)
 [![cert-manager v1.5](https://img.shields.io/badge/cert--manager-v1.5-blue)](https://cert-manager.io)
 [![smallstep v0.16.1](https://img.shields.io/badge/smallstep-v0.16.1-red)](https://smallstep.com)

The Gloo Edge security tutorial walking through various Gloo Edge security concepts with practical exercises.

Check out [HTML documentation](https://kameshsampath.github.io/gloo-security-tutorial) to get started.

> :warning: The tutorial is under active development, expect a lot of changes.

## Run Doc site

```shell
docker run --rm --name=gloo-security-tutorial-site -p 7070:8080 ghcr.io/kameshsampath/gloo-security-tutorial-site
```

The documentation site is now accessible via [localhost:7070](http://localhost:7070)

## Build and Run Local site

```shell
docker run -it --rm -p 8000:8000 -v "$(pwd):/usr/src/app" ghcr.io/kameshsampath/mkdocs-builder
```

You can now access site via [localhost:8000](http://localhost:8000/)
