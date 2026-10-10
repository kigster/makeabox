# Running makeabox on Google Cloud Run

The `Dockerfile` builds an image that runs makeabox on Cloud Run, or on any host that runs containers. Puma serves HTTP on `$PORT` (8080). Cloud Run supplies HTTPS, HTTP/2 and the public address, so there is no nginx in the image.

## What the container needs from outside

### Secrets: set at run time only

| Variable | Needed | What happens without it |
|---|---|---|
| `SECRET_KEY_BASE` | yes | The app refuses to start. |
| `REDIS_URL` | for the download counter | The header shows dashes and downloads are not counted. Everything else works. |
| `NEW_RELIC_LICENSE_KEY` | only with `NEW_RELIC_AGENT_ENABLED=true` | New Relic stays off. |

Never pass these as `--build-arg`: build arguments stay readable in the image's history. Keep them in Secret Manager and hand them to the service with `--set-secrets`.

### Settings: baked in with defaults, change with `--set-env-vars`

| Variable | Default | Meaning |
|---|---|---|
| `PORT` | `8080` | Set by Cloud Run itself. |
| `WEB_CONCURRENCY` | `2` | Puma processes. One per vCPU is a good start. |
| `RAILS_MIN_THREADS` / `RAILS_MAX_THREADS` | `2` / `4` | Threads per process. Also the Redis pool size. |
| `RAILS_LOG_TO_STDOUT` | `1` | Logs to stdout, for Cloud Logging. Also tells Puma it is in a container. |
| `MAKEABOX_LOG_LEVEL` | `info` | `debug`, `info`, `warn` or `error`. |
| `DISABLE_LOG_COLORS` | `1` | No terminal colours in the logs. |
| `ASSET_HOST` | empty | Empty serves `/assets` from the container. Set to a CDN to use one. |
| `MEMCACHED_HOST` / `MEMCACHED_PORT` | empty / `11211` | Empty caches in memory, in each process. |
| `X_SENDFILE_HEADER` | empty | Only for a proxy that sends files for Rails, such as nginx. |
| `NEW_RELIC_AGENT_ENABLED` | `false` | Turns on the New Relic agent. |
| `NEW_RELIC_APP_NAME` | `makeabox` | The app's name in New Relic. |
| `NEW_RELIC_LOG` | `stdout` | Where the agent logs. |

Each one can also be changed at build time: `docker build --build-arg WEB_CONCURRENCY=4 …`.

## Try it locally

```bash
docker build --platform linux/amd64 -t makeabox .
docker run --rm -p 8080:8080 \
  -e SECRET_KEY_BASE="$(bin/rails secret)" \
  -e REDIS_URL=redis://host.docker.internal:6379/0 \
  makeabox
open http://localhost:8080
curl -s localhost:8080/up        # 200 once the app has booted
```

## Deploy

One-time setup: a repository for the image, and the secret.

```bash
PROJECT=your-project REGION=us-west1
gcloud artifacts repositories create makeabox --repository-format=docker --location=$REGION
bin/rails secret | tr -d '\n' | gcloud secrets create makeabox-secret-key-base --data-file=-
# Optional: the counter's Redis, for example Memorystore or a hosted Redis
printf %s 'redis://:password@10.0.0.3:6379/0' | gcloud secrets create makeabox-redis-url --data-file=-
```

Each release: build, push, deploy.

```bash
IMAGE=$REGION-docker.pkg.dev/$PROJECT/makeabox/makeabox:$(git rev-parse --short HEAD)
docker build --platform linux/amd64 -t $IMAGE .
docker push $IMAGE

gcloud run deploy makeabox \
  --image $IMAGE --region $REGION --allow-unauthenticated \
  --cpu 2 --memory 1Gi --concurrency 8 --timeout 60 \
  --set-secrets SECRET_KEY_BASE=makeabox-secret-key-base:latest,REDIS_URL=makeabox-redis-url:latest \
  --set-env-vars WEB_CONCURRENCY=2,RAILS_MAX_THREADS=4
```

- **`--concurrency`** is processes × threads, here 2 × 4 = 8. Cloud Run sends no more requests than that to one instance at a time.
- **`--timeout 60`**: every box draws in under a second, and the app gives up on a drawing after 20 seconds.
- **The Generate dialog** streams its progress as server-sent events. Cloud Run passes a streamed response through as it is written, so it needs no proxy settings.
- **Memorystore** has only a private address. Give the service a route to it: `--network default --subnet default --vpc-egress private-ranges-only`.
- **Your domain**: map it with `gcloud beta run domain-mappings create`, or put a load balancer in front.
