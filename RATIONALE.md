# Project 2 Rationale: Base Image and Service Split

## Base image and multi-stage build

The Dockerfile uses `node:24` in the build stage because the project’s build script runs with Node/npm. That stage installs dependencies with `npm ci` and creates the static `build/` output. The final stage uses `nginx:alpine`, which is suited to serving the resulting static HTML. The final image copies only `/app/build` from the build stage, so Node.js, npm, and build-stage files are not copied into the runtime image. Docker’s documentation describes this pattern as a way to keep build tools and intermediate artifacts out of the final image [1].

The `Dockerfile.single` file is included only to make the T02 comparison reproducible. It keeps the Node base image and installs `http-server` to serve the built files. Run the following commands and record your own image-size output before submission:

```bash
docker build -f Dockerfile.single -t demo:single .
docker build -t demo:multi .
docker images | grep demo
```

**Measured image sizes on my machine:**  
- Multi-stage (`demo:multi`): **replace with your measured size**
- Single-stage (`demo:single`): **replace with your measured size**
- Approximate ratio (single-stage size divided by multi-stage size): **calculate from your measured sizes**

The course T02 guide reports example measurements of 92.7 MB for the multi-stage image and 1.63 GB for the single-stage image, but also notes that image sizes vary with Docker versions and base-image updates. Those are reference figures, not measurements from this machine. Replace the placeholders above with the output you actually observe. A smaller final image reduces the amount of build-time software shipped and the amount of image data that must be stored or transferred [1].

## Why `web` and `cache` are separate services

The Compose file defines `web` as the static nginx website and `cache` as `redis:7-alpine`. Redis is a separate service rather than being installed inside the web container because Compose is intended to describe services and their dependencies separately. This keeps the web server and cache independently identifiable and replaceable. The `web` service uses `depends_on` with `condition: service_healthy`; the Redis healthcheck runs `redis-cli ping`. Compose waits for a dependency marked `service_healthy` to pass its healthcheck before starting the dependent service [2].

This reflects the course’s service-model framing: a container provides control over how services are packaged and connected, while using a public Redis image means the project composes a pre-built dependency instead of implementing and maintaining a cache itself. This demonstration does not yet read or write Redis from the web page, so stopping `cache` does not break the static page. The dependency configuration controls startup order; it does not create a runtime connection automatically.

## References

1. Docker, “Multi-stage builds,” https://docs.docker.com/build/building/multi-stage/
2. Docker, “Control startup and shutdown order in Compose,” https://docs.docker.com/compose/how-tos/startup-order/
3. AWS, “Introduction to testing with sam local invoke,” https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/using-sam-cli-local-invoke.html
