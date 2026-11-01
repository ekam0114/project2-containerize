# Rationale: base image and service choices

## Base image: why `nginx:alpine` for the final stage

The build stage uses `node:24` because compiling needs the full toolchain (Node, npm,
build dependencies). The output of `npm run build` is just static files, so the final stage
needs only something that serves files. nginx is a purpose-built static web server, and
copying `/app/build` into `/usr/share/nginx/html` is all the configuration required.
Docker's multi-stage documentation describes exactly this pattern: keep build tools in
earlier stages and copy only the needed artifacts into the final one [1].

I chose the `alpine` variant over the default Debian-based tag because the nginx official
image documentation presents the Alpine variants as the choice when final image size is the
primary concern, since they are built on the much smaller Alpine Linux base [2]. A smaller
image pulls faster, costs less to store and transfer, and contains less installed software
that could carry vulnerabilities. The trade-off, per the same documentation, is that Alpine
uses musl libc instead of glibc, which can matter for software that needs glibc. A static
site served by nginx has no such dependency, so the trade-off costs nothing here.

**Measured result** (from my own `docker images | grep demo`, same app built both ways):

| Image | Dockerfile | Disk usage | Content size |
|---|---|---|---|
| `demo:multi`  | `Dockerfile` (multi-stage, nginx:alpine final) | 93.6 MB | 26.3 MB |
| `demo:single` | `Dockerfile.single` (node:24, no second stage) | 1.65 GB | 413 MB |

The multi-stage build saved roughly 1.56 GB of disk usage (about 17.6x smaller). The
difference is the Node.js toolchain, npm cache and build-time dependencies, which the
single-stage image keeps shipping even though it never rebuilds after build time. "Disk
usage" counts all layers including the shared base image; "content size" counts the bytes
unique to the image itself.

## Service split: why `cache` is separate from `web`

`cache` is its own service running the public `redis:7-alpine` image rather than being
installed inside `web`, for these reasons:

- **One process, one concern per container.** The `web` image contains only nginx and the
  built files. Putting Redis in it would mean a process manager, a bigger image, and
  rebuilding the web image to change the cache version.
- **Independent lifecycle.** Each service can be updated, restarted or scaled separately.
  Compose gives `cache` its own healthcheck (`redis-cli ping`), and `web` waits for it with
  `depends_on: condition: service_healthy`, so startup is ordered by readiness rather than
  by when a process merely started [3].
- **Reuse of a maintained image.** I am not writing or patching a cache; I am composing
  one in from the Redis official image [4].

In Week 3's service-model terms, a container sits between IaaS and PaaS because it lets me
decide piece by piece what I manage and what I accept as a pre-built dependency. I manage
the web image (my Dockerfile, my content) and accept `redis:7-alpine` as an off-the-shelf
component whose internals I do not operate. The split makes that line explicit in the
repository.

Note: `depends_on` here only controls start order. `web` does not call `cache` at runtime,
so stopping `cache` does not affect `web`'s responses. The dependency is a startup
guarantee, not a runtime coupling.

## Sources

1. Docker Docs, "Multi-stage builds": https://docs.docker.com/build/building/multi-stage/
2. Docker Hub, nginx official image, "Image Variants" section: https://hub.docker.com/_/nginx
3. Docker Docs, "Control startup and shutdown order in Compose": https://docs.docker.com/compose/how-tos/startup-order/
4. Docker Hub, redis official image: https://hub.docker.com/_/redis
