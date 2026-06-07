# SkillVault

A personal collection of curated agent skills for **Codex** and **Claude Code**. Install directly from GitHub — no cloning required.

## Included Skills

| Source | Skills | Catalog |
|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | 20 skills — engineering, misc, personal, productivity | [docs/skills/mattpocock.md](docs/skills/mattpocock.md) |
| [obra/superpowers](https://github.com/obra/superpowers) | 14 skills — structured development workflows | [docs/skills/superpowers.md](docs/skills/superpowers.md) |
| [larksuite/cli](https://github.com/larksuite/cli) | 26 skills — full Feishu API surface (submodule) | [docs/skills/lark.md](docs/skills/lark.md) |

## How to Install

### Codex

Ask the agent:

> Install the diagnose skill from Tsan1024/SkillVault

Or via script:

```bash
install-skill-from-github.py --repo Tsan1024/SkillVault --path skills/diagnose
```

### Claude Code

Ask the agent:

> Install the diagnose skill from Tsan1024/SkillVault into my skills

Claude Code pulls the `SKILL.md` and supporting files from GitHub and places them in `~/.claude/skills/` automatically.

### Lark (Feishu) skills

Install from upstream:

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

# Lark submodule
git submodule update --remote vendors/larksuite-cli
```

The sync script compares pinned commits in [sources.yaml](sources.yaml) against upstream HEAD.

## Repo Structure

```
SkillVault/
  skills/                # Flat skill directories (34 skills)
  docs/skills/           # Per-source skill catalogs
  sources.yaml           # Upstream source index (repo, commit, sync date)
  scripts/sync.sh        # Check & pull upstream updates
  vendors/
    larksuite-cli/       # Git submodule → larksuite/cli
```
