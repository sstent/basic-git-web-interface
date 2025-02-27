FROM python:3.10-slim-bullseye as builder

WORKDIR /app

COPY requirements.txt requirements.txt

RUN python -m venv .venv

# also allow for DOCKER_BUILDKIT=1 to be used
RUN --mount=type=cache,target=/root/.cache ./.venv/bin/pip install -r requirements.txt

FROM python:3.10-alpine3.15

WORKDIR /app
EXPOSE 8000
ENV REPOS_PATH=/data/repos
ENV WORKERS=1

RUN apk add --no-cache git

COPY --from=builder /app/.venv .venv

COPY git_web git_web

CMD ./.venv/bin/hypercorn 'git_web.main:create_app()' --bind '0.0.0.0:8000' --workers "$WORKERS"

HEALTHCHECK --interval=1m --start-period=30s \
    CMD ./.venv/bin/python -m web_health_checker 'http://127.0.0.1:8000/is-healthy'
