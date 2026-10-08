# Contributing

How to work on this template. For how to *use* it, see [README.md](README.md).

## Setup

```bash
cp .devcontainer/.env.example .devcontainer/.env   # set your git identity
docker compose -f .devcontainer/compose.yaml up -d --build
docker compose -f .devcontainer/compose.yaml exec app bash
```

This repository has its own small dev container (`copier`, `pre-commit`,
`git`), separate from the much larger one under `template/` that ships to
generated projects. Commit from inside it: the git hooks call `uv run`.

```text
copier.yml           questions, _exclude, _tasks
python-versions.yml  the interpreters the python_version question offers
template/            what gets generated
.github/workflows/   template.yml (generate and test), validate.yml, release.yml
docs/                the upgrade guide
.devcontainer/       this repo's own container, not the one that ships
```

## How the template is put together

Four rules shape it. Each one prevents a mistake that is easy to make and
expensive to undo.

**A file gets a `.jinja` suffix only if it genuinely must vary.** An unsuffixed
file keeps its real name and stays a real file of its type. That means
`pre-commit autoupdate -c template/.pre-commit-config.yaml` works on it, and an
editor reads `template/.devcontainer/entrypoint.sh` as shell. A suffix also
drags the file through Jinja, which makes every brace in it a hazard.

**Standard Jinja delimiters, `{{ }}` and `{% %}`.** Copier's docs call the
bracket delimiters available through `_envops` the Copier 5 style. The
collision with GitHub Actions' `${{ }}` that would otherwise argue for them
does not exist here: Copier renders a file only if its name ends in `.jinja`,
and the workflow files have no variables, so they take no suffix and are copied
byte for byte.

**A conditional file gets a templated `_exclude` entry, never a conditional
filename.** A conditional name needs its suffix outside the condition
(`{% if x %}f.yml{% endif %}.jinja`), which forces the file through Jinja and
breaks its `${{ }}`.

**Never a Jinja `{% if %}` block inside a `.py` template.** It renders as a
stray blank line, which ruff's import sorter rejects. Exclude the whole file in
`_exclude` instead. No `.py` file is conditional today; the rule is for the
next one.

## Comments

A bad comment is worse than no comment. The usual failure is a comment that
drifts from the code it describes, or a second copy of a rationale that drifts
from the first.

The test for keeping one: **would a competent maintainer plausibly change this
line if the comment were gone?** If yes, keep it, in one to three lines. If no,
the comment is documentation wearing a `#`, and it belongs in a document.

| | |
| --- | --- |
| **Keep** | Warnings whose absence invites a "simplification" that breaks something: the `! -f` arm in both entrypoints, the `[$]{{` character class, the list form of compose's `environment:`, `test -x` rather than `-d` in the healthcheck, "do not re-add `ca-certificates`". Unidiomatic code. Links to an external source. |
| **Delete** | Anything that restates the code, or an adjacent `name:` or `LABEL`. Design history: the git log and `CHANGELOG.md` are the record, and a file that narrates its own past is wrong the first time someone forgets to update it. Rationale already written in prose that ships in the same tree. |
| **Move** | Rationale a maintainer needs but a reader of that line does not. Template-authoring rationale comes here; anything a generated project's maintainer needs goes to `template/CONTRIBUTING.md.jinja`. |

Prefer deleting to moving: most of it is already recorded somewhere. Whichever
file ends up holding a rationale holds it alone.

Directives are not comments. Leave `# syntax=docker/dockerfile:1` on line 1,
`# shellcheck disable=`, Copier's `NEVER EDIT MANUALLY` header and the `{#- -#}`
block in `.env.jinja` alone. So are `.env.example` and `.env.jinja`, which are
instructions to whoever edits them rather than internal rationale.

**Inside a `.jinja` file, choose the comment syntax by audience.** A `#`
comment renders into the generated project, so it must read correctly to
someone who has never seen this template, with no Copier vocabulary and nothing
about a filter that rendering has already consumed. Rationale meant for whoever
edits the template goes in a `{# ... #}` Jinja comment, which never reaches a
generated project. Close it `-#}` so it does not leave a blank line behind.

## Testing a change

`.github/workflows/template.yml` generates a project and runs *its* test suite
and *its* full gate, across three combinations: defaults, releases off, and the
oldest interpreter `python-versions.yml` offers. That workflow is the only
thing checking template content: every type-based hook in this repo's own gate
excludes `^template/`, so none of them reads a file under it. Locally:

```bash
uv run copier copy --defaults --trust --vcs-ref=HEAD "$PWD" /tmp/generated
cd /tmp/generated && git add -A   # the git init task already made the repo
uv sync --all-groups && uv run pytest && uv run pre-commit run --all-files
```

Two details that will otherwise cost you time:

- **`--vcs-ref=HEAD`**: without it Copier tests the last tag rather than your
  working commit.
- **`"$PWD"`, not `.`**: Copier clones the template through git. A `.` source
  makes git report the path as `/workspace/./.git`, which doesn't match the
  `safe.directory` exemption the container sets. It fails with "dubious
  ownership".

## Keeping pins current

| What | How |
| --- | --- |
| This repo's `copier`, `pre-commit` and `python-semantic-release` | Dependabot, weekly (`uv` ecosystem) |
| This repo's GitHub Actions | Dependabot, weekly (`github-actions` ecosystem) |
| This repo's `.devcontainer/Dockerfile` base images | Dependabot, monthly (`docker` ecosystem) |
| A generated project's dependencies, actions, images | Dependabot, in that project |
| `template/`'s GitHub Actions | **Driven by the root.** `validate.yml` asserts they match the root's pins, so Dependabot's root PR turns red until `template/` is updated in it |
| This repo's own `.pre-commit-config.yaml` revs | **Manual** |
| `uv`, pinned in both Dockerfiles and both `uv-pre-commit` revs | **Driven by the root.** `validate.yml` asserts all four agree, so a Dependabot bump to the root Dockerfile reddens until the other three follow |
| `python-versions.yml` | **Manual**; bump the `oldest-python` leg in `template.yml` with it |
| `template/` pre-commit revs, base image, uv | **Manual** |
| `template/`'s `python-semantic-release` pin in `release.yml` | **Manual** |

Everything marked manual is manual for a few reasons: Dependabot has no
pre-commit ecosystem at all, it cannot parse `Dockerfile.jinja`, it cannot
read a version out of a `run:` string such as the generated `release.yml`'s
`uvx --from`, and it does not know what `python-versions.yml` is.

`template/`'s actions are the one case with a way out, because those files are
not `.jinja` and pin the same actions the root does. Even so, Dependabot's
`github-actions` ecosystem cannot reach them: it requires `directory: "/"` and
reads only `/.github/workflows`. So `validate.yml` compares the two trees
instead and fails on drift.

Update the manual ones by hand and let `template.yml` prove the template still
generates.
