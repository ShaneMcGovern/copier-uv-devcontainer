# uv-devcontainer

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Validate](https://github.com/ShaneMcGovern/copier-uv-devcontainer/actions/workflows/validate.yml/badge.svg)](https://github.com/ShaneMcGovern/copier-uv-devcontainer/actions/workflows/validate.yml)
[![Template](https://github.com/ShaneMcGovern/copier-uv-devcontainer/actions/workflows/template.yml/badge.svg)](https://github.com/ShaneMcGovern/copier-uv-devcontainer/actions/workflows/template.yml)
[![Copier](https://img.shields.io/badge/copier-template-blue.svg)](https://github.com/copier-org/copier)
[![uv](https://img.shields.io/badge/uv-package%20manager-green.svg)](https://github.com/astral-sh/uv)

A [Copier](https://github.com/copier-org/copier) template for Python projects
developed inside a dev container. It generates the parts that are tedious to
assemble and easy to get subtly wrong. You get a reproducible container, a
locked `uv` environment, a pre-commit gate that runs identically on your
machine and in CI, and releases driven by commit messages.

## Features

- **Reproducible dependencies** with
  [uv](https://github.com/astral-sh/uv) - every generated project ships a
  committed lockfile
- **Pre-configured tooling**: pytest with coverage, ruff linting and formatting,
  mypy in strict mode
- **One quality gate** shared by the developer and CI, so nothing passes locally
  and fails on push
- **GitHub Actions CI/CD** with automated testing and optional semantic releases
- **Zero host setup** - Docker Compose dev container, non-root user, persistent
  caches

## Installation

**Prerequisites**: [uv](https://docs.astral.sh/uv/getting-started/installation/)
for `uvx`, and [Docker](https://docs.docker.com/get-docker/) to run the project
you generate. The template itself needs no Python on the host.

> The GitHub repository is `copier-uv-devcontainer`; the template it holds is
> `uv-devcontainer`. That is why the URLs below name the former. Sibling
> templates for other stacks will each get their own repository, since Copier's
> guidance is one template per repository.

`--trust` is **required** in every command here, because this template uses
`_tasks`. Without it Copier refuses outright. It prints "Template uses
potentially unsafe feature: tasks", exits 4, and leaves no destination
directory at all.

### Option 1: Latest Release (Recommended)

Copier resolves a git template to its newest **tag**, sorted by PEP 440, not to
the default branch:

```bash
# Generate from the newest tagged release
uvx copier copy --trust gh:ShaneMcGovern/copier-uv-devcontainer my-new-project
```

### Option 2: Current `main`

Untagged work on `main` is invisible to the default resolution. Testing an
unreleased template change needs an explicit ref:

```bash
# Generate from the branch tip instead of the newest tag
uvx copier copy --trust --vcs-ref=HEAD gh:ShaneMcGovern/copier-uv-devcontainer my-new-project
```

## Quick Start

Once a project is generated:

```bash
cd my-new-project

# Start the container, or open the folder in VS Code
# and click "Reopen in Container"
docker compose -f .devcontainer/compose.yaml up -d --build

# Open a shell inside it
docker compose -f .devcontainer/compose.yaml exec app bash

# Then, inside the container
uv run pytest
uv run python -m main
# Output: Hello from <project_slug>!
```

The container syncs the environment and installs the git hooks on start, so
there is no separate setup step.

That first sync is also what writes `uv.lock`. Generation deliberately does
not. Building the lock on the host would require the host to obtain the exact
interpreter `.python-version` pins. Some hosts cannot (say uv's automatic
Python downloads are turned off), so a task that locked during generation
would fail, and Copier would delete the whole destination and report an error
naming neither uv nor the cause. The container already contains that
interpreter, so locking there cannot fail that way.

So in practice, **start the container before your first push.** Both
generated workflows install with `uv sync --frozen`, so CI needs the lock
committed.

## Questions

Defaults are shown at the prompt and defined in
[`copier.yml`](copier.yml). The table below shows where each answer lands,
which the prompt does not tell you.

| Variable | Where it lands |
| --- | --- |
| `project_name` | The `README` title |
| `project_slug` | `pyproject` `name`, the compose project, and the greeting |
| `project_description` | `pyproject` `description`, and the line under the `README` badges |
| `author_name`, `author_email` | `pyproject` authors, LICENSE, and the container's git identity: they render the working `.devcontainer/.env`. The committed `.devcontainer/.env.example` is a static file and keeps its placeholders, for anyone else who clones the project |
| `github_owner` | The `README` badge URLs, `CODEOWNERS`, and `[project.urls]` |
| `github_repo` | Deliberately separate from the slug. It joins `github_owner` in the badge URLs and `[project.urls]`, and this very repo is a case where the two differ |
| `license` | `pyproject` `license`, the `README` badge, and `LICENSE` |
| `copyright_year` | `LICENSE` and the `README` footer |
| `python_version` | **Select**, not free text: the offered versions live in [`python-versions.yml`](python-versions.yml), and editing that file is the whole maintenance story. Sets `.python-version`, the image tag, and `requires-python` (`3.12.14` gives `>=3.12`). An unlisted value is refused rather than failing later |
| `use_semantic_release` | `release.yml`, `CHANGELOG.md`, PSR config |

A generated project starts at version `0.0.0`. Its first `fix:` release becomes
`0.0.1` and its first `feat:` becomes `0.1.0`. Starting at `0.1.0` instead
would make that first release move *backwards*.

## Updating a Generated Project

Copier records the answers and the template commit in `.copier-answers.yml`, so
later template improvements can be pulled in:

```bash
# Re-ask each question, prior answer as the default
uvx copier update --trust

# Reuse every prior answer, no prompts
uvx copier update --trust --defaults
```

**Commit your work first**: Copier refuses to update a dirty tree. It then
re-applies the template at its newest tag and merges with your changes.

`update` moves to the newest **tag**, so an untagged template change is
invisible to it.

`uvx` fetches whatever Copier version is current. Pin it (`uvx copier@9.17.2`)
if you want the update to be reproducible.

Some template releases restructure a generated project in ways `update` cannot
merge on its own. When one does, [docs/UPGRADING.md](docs/UPGRADING.md) records
what changed and the order to step through.

## Documentation

- **[Copier Documentation](https://copier.readthedocs.io/)** - Template
  generation and update reference
- **[uv Documentation](https://docs.astral.sh/uv/)** - Package manager and
  lockfile reference
- **[python-semantic-release](https://python-semantic-release.readthedocs.io/)** -
  Release automation reference
- **[Conventional Commits](https://www.conventionalcommits.org/)** - Commit
  message specification

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for container setup, how the template is
put together, and which pins move by hand.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

Copyright Shane McGovern
