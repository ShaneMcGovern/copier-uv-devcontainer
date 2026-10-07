#!/bin/bash
set -euo pipefail

cd /workspace

# The bind-mounted repo belongs to the host user, so mark it safe. Check first
# because --add appends a duplicate on every start; .git needs its own entry
# alongside the worktree.
for d in /workspace /workspace/.git; do
  if ! git config --global --get-all safe.directory 2>/dev/null | grep -qx "${d}"; then
    git config --global --add safe.directory "${d}"
  fi
done

if [ -n "${GIT_AUTHOR_NAME:-}" ] && [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
  git config --global user.name "${GIT_AUTHOR_NAME}"
  git config --global user.email "${GIT_AUTHOR_EMAIL}"
fi

if [ -f pyproject.toml ]; then
  # A Windows bind mount can present uv.lock as read-only; fall back to
  # --frozen then. The `! -f` arm keeps a fresh clone with no lockfile on the
  # normal path, since `[ -w uv.lock ]` is also false when the file is absent.
  if [ ! -f uv.lock ] || [ -w uv.lock ]; then
    sync_cmd=(uv sync --all-groups)
  else
    echo "uv.lock is read-only; syncing with --frozen (the lock will not be updated)"
    sync_cmd=(uv sync --frozen --all-groups)
  fi

  if ! "${sync_cmd[@]}"; then
    echo "WARNING: uv sync failed; container still up so you can attach and retry."
  fi
fi

if [ -d .git ] && [ -f .pre-commit-config.yaml ]; then
  uv run --frozen pre-commit install --install-hooks \
    || echo "WARNING: pre-commit install failed; hooks are NOT active."
fi

exec sleep infinity
