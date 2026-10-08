#!/bin/bash
set -euo pipefail

cd /app

# The bind-mounted repo is owned by the host user, not by `developer`. The
# guard matters because --add appends a duplicate on every start. .git needs
# its own entry because git checks that exact path when a tool clones from in
# here, as `copier update` does.
for d in /app /app/.git; do
  if ! git config --global --get-all safe.directory 2>/dev/null | grep -qx "${d}"; then
    git config --global --add safe.directory "${d}"
  fi
done

if [ -n "${GIT_AUTHOR_NAME:-}" ] && [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
  git config --global user.name "${GIT_AUTHOR_NAME}"
  git config --global user.email "${GIT_AUTHOR_EMAIL}"
else
  echo "GIT_AUTHOR_NAME and GIT_AUTHOR_EMAIL not set; skipping git identity config"
  echo "Set them in .devcontainer/.env, or run git config --global user.name/user.email"
fi

if [ -f pyproject.toml ]; then
  # A Windows bind mount can present uv.lock as read-only, so sync it with
  # --frozen when it isn't writable. Keep the `! -f` arm. `[ -w uv.lock ]` is
  # also false when the file is absent, so a fresh clone would take the
  # --frozen path and fail on a missing lockfile.
  if [ ! -f uv.lock ] || [ -w uv.lock ]; then
    sync_cmd=(uv sync --all-groups)
  else
    echo "uv.lock is read-only; syncing with --frozen (the lock will not be updated)"
    sync_cmd=(uv sync --frozen --all-groups)
  fi

  # Don't make this fatal. Under `set -e` a transient failure here would kill
  # the container and leave no way to shell in and diagnose it.
  if ! "${sync_cmd[@]}"; then
    echo "WARNING: uv sync failed. The container is still running so you can"
    echo "         attach and re-run 'uv sync --all-groups' once the cause is fixed."
  fi
else
  echo "pyproject.toml not found; skipping uv sync"
fi

# Here rather than in a devcontainer postCreateCommand, so `docker compose up`
# alone produces a complete environment. The guards cover what
# postCreateCommand gave for free.
if [ -d .git ] && [ -f .pre-commit-config.yaml ]; then
  if ! uv run --frozen pre-commit install --install-hooks; then
    echo "WARNING: pre-commit install failed; git hooks are NOT active."
    echo "         Re-run 'uv run pre-commit install --install-hooks' once fixed."
  fi
else
  echo "No .git or no .pre-commit-config.yaml; skipping pre-commit install"
fi

exec sleep infinity
