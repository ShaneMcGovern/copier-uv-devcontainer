# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:0.12.23 AS uv

FROM python:3.14.7-slim-bookworm

LABEL org.opencontainers.image.title="uv-devcontainer-repo" \
      org.opencontainers.image.description="Dev container for the uv-devcontainer template repository"

# markdownlint-cli runs on pre-commit's bundled Node, which needs libatomic1;
# the slim image omits it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git libatomic1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    VIRTUAL_ENV=/workspace/.venv \
    PATH=/workspace/.venv/bin:$PATH

RUN printf 'export VIRTUAL_ENV=/workspace/.venv\nexport PATH="/workspace/.venv/bin:${PATH}"\n' \
    > /etc/profile.d/10-venv.sh

# UID/GID are build args so a Linux contributor whose host uid is not 1000 can
# match it and keep the bind-mounted workspace writable.
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} developer \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash developer

WORKDIR /workspace

COPY --chown=root:root --chmod=755 .devcontainer/entrypoint.sh /entrypoint.sh

RUN mkdir -p /workspace/.venv \
        "/home/developer/.cache/uv" \
        "/home/developer/.cache/pre-commit" \
    && chown -R developer:developer /workspace "/home/developer/.cache"

USER developer

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
