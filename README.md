# Gloo Edge

Demo showing

## Run Doc site

```shell
docker run --rm --name=gloo-edge-eks-demo-site -p 7070:8080 ghcr.io/kameshsampath/gloo-edge-demo-site
```

The documentation site is now accessible via [localhost:7070](http://localhost:7070)

## Build and Run Local site

```shell
docker run -it --rm -p 8000:8000 -v "$(pwd):/usr/src/app" ghcr.io/kameshsampath/mkdocs-builder
```

You can now access site via [localhost:8000](http://localhost:8000/gloo-edge-eks-a-demo)
