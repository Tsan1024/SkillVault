# SkillVault

A personal collection of curated agent skills for **Codex** and **Claude Code**. Install directly from GitHub — no cloning required.

## Included Skills

| Source | Skills | Catalog |
|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | 20 skills — engineering, misc, personal, productivity | [docs/skills/mattpocock.md](docs/skills/mattpocock.md) |
| [obra/superpowers](https://github.com/obra/superpowers) | 14 skills — structured development workflows | [docs/skills/superpowers.md](docs/skills/superpowers.md) |
| [larksuite/cli](https://github.com/larksuite/cli) | 26 skills — full Feishu API surface (submodule) | [docs/skills/lark.md](docs/skills/lark.md) |

## Included Tools

| Tool | Description |
|---|---|
| [gastownhall/beads](https://github.com/gastownhall/beads) | Durable issue tracker for agents — the task system this repo itself uses (submodule) |

## How to Install

### Quick install (recommended)

Use the bundled install script — works for both Codex and Claude Code:

```bash
curl -sL https://raw.githubusercontent.com/Tsan1024/SkillVault/dev/scripts/install.sh | bash -s -- diagnose tdd brainstorming
```

The script auto-detects your agent and places skills in the right directory.

Force a specific agent:

```bash
curl -sL https://raw.githubusercontent.com/Tsan1024/SkillVault/dev/scripts/install.sh | bash -s -- --codex diagnose
curl -sL https://raw.githubusercontent.com/Tsan1024/SkillVault/dev/scripts/install.sh | bash -s -- --claude diagnose
```

### Ask your agent

Both Codex and Claude Code can install skills natively. Just say:

> Install the diagnose skill from Tsan1024/SkillVault

### Lark (Feishu) skills

```bash
install-skill-from-github.py \
  --repo larksuite/cli \
  --path skills/lark-calendar \
  --path skills/lark-doc
```

Restart your agent after installing to pick up new skills.

## Keeping Skills Up to Date

```bash
# Check for upstream updates (dry-run)
./scripts/sync.sh

# Pull all upstream changes into skills/
./scripts/sync.sh --pull

# Submodules
git submodule update --remote vendors/larksuite-cli
git submodule update --remote vendors/beads
```

The sync script compares pinned commits in [sources.yaml](sources.yaml) against upstream HEAD.

## Repo Structure

```
SkillVault/
  skills/                # Flat skill directories (34 skills)
  docs/skills/           # Per-source skill catalogs
  sources.yaml           # Upstream source index (repo, commit, sync date)
  scripts/
    install.sh           # One-liner install for Codex & Claude Code
    sync.sh              # Check & pull upstream updates
  vendors/
    larksuite-cli/       # Git submodule → larksuite/cli
    beads/               # Git submodule → gastownhall/beads
```
