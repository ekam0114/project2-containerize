# Project 2: Containerize and Run Locally

This repository contains the T02 multi-stage Dockerfile, the T03 Compose stack, and the T04 local AWS SAM function scaffold. All required runtime checks are local; no AWS account is needed.

## Requirements

- Docker Engine and Docker Compose v2 (`docker compose`)
- Node.js/npm locally only if regenerating the lockfile or running the comparison build directly
- AWS SAM CLI and Docker for the local function invocation
- Run the commands below in Ubuntu/WSL or a Linux terminal, as specified in the course labs

## Repository contents

- `Dockerfile` — two-stage build: Node.js build stage, then `nginx:alpine` runtime stage
- `Dockerfile.single` — T02 comparison build; not used by Compose
- `compose.yaml` — `web` and `cache` services, with Redis healthcheck and startup dependency
- `local-fn/` — AWS SAM Hello World function, invocable locally
- `.gitignore` and `.dockerignore` — keep generated files and the local function out of the web image

## 1. Check the required files and stages

From the repository root:

```bash
ls -a
grep -c "^FROM" Dockerfile
docker compose config --services
```

The `grep` command should print `2`. Compose should list `cache` and `web`.

## 2. Build and compare image sizes (T02)

Run from the repository root:

```bash
docker build -f Dockerfile.single -t demo:single .
docker build -t demo:multi .
docker images | grep demo
```

Record the actual sizes shown on your own machine in `RATIONALE.md`. Image sizes vary with Docker versions and updated base-image layers. The single-stage comparison image is only for the experiment; Compose builds the multi-stage `Dockerfile`.

Optional cleanup after recording the numbers:

```bash
docker rmi demo:single demo:multi
```

## 3. Build and start both Compose services

```bash
docker compose config --services
docker compose up -d --build
docker compose ps
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
docker compose exec cache redis-cli ping
docker compose logs web
docker compose exec web sh -c 'nginx -v'
docker inspect $(docker compose ps -q web) --format '{{.State.Status}} started={{.State.StartedAt}} restarts={{.RestartCount}}'
```

Expected checks:
- Compose lists both `cache` and `web`.
- `cache` eventually reports `healthy`.
- The HTTP status check prints `200`.
- Redis responds `PONG`.
- The web container reports `running`.

The web service is a static nginx site and does not currently make runtime requests to Redis. `depends_on` plus `service_healthy` ensures Redis is healthy before web starts; it does not create an application-level cache integration.

## 4. Exercise the dependency-stop check (T05)

```bash
docker compose stop cache
docker compose ps
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
docker compose down
```

The static web page should continue to return `200` even when Redis is stopped, because the page does not use Redis at runtime. This is an intentional observation in the lab. Run `docker compose up -d` again if you want to continue testing before cleaning up.

## 5. Invoke the function locally (T04/T06)

From the repository root:

```bash
cd local-fn
sam --version
sam local invoke HelloWorldFunction
sam local invoke HelloWorldFunction -e events/event.json
cd ..
```

The output should contain a response with `statusCode` 200. The first invocation may need to download the public Lambda runtime container image. No AWS account or credentials are required for this local invocation.

Optional HTTP endpoint demonstration:

```bash
cd local-fn
sam local start-api
```

In a second terminal, run:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/hello
```

Stop `sam local start-api` with Ctrl+C.

## 6. Clean shutdown

```bash
docker compose down
```

## 7. Fresh-clone verification before submission

Commit the files, push the repository to the hosting service required by your instructor, and clone it into a new directory. From that fresh clone, run:

```bash
grep -c "^FROM" Dockerfile
docker compose config --services
docker compose up -d --build
docker compose ps
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
docker compose down
cd local-fn
sam local invoke HelloWorldFunction
cd ..
```

Do not submit until you have run these checks on your own machine. Update the README if the commands or port you actually use differ.

## Git setup (if this folder is not already a repository)

```bash
git init
git add .
git commit -m "Project 2: containerize and run locally"
```

Configure your own Git name/email first if Git asks for an author identity. Then create a remote repository and push it, or follow the submission format your instructor specifies.
