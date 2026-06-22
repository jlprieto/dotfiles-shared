# dotfiles-shared

Draft README for the public shared repo that will hold the generic base used by both work and personal dotfiles.

This shared layer must contain only safe, generic, reusable configuration. It is the source of truth for anything that should behave the same in both environments.

## Design

The shared repo is the baseline layer. Overlay repos import it and then add their own environment-specific behavior on top.

Intended structure:

```text
.
├── install.sh
├── shell/
│   └── aliases.sh
├── editors/
│   └── vscode/
│       └── settings.json
├── scripts/
├── docs/
└── README.md
```

Overlay repos should consume this content under a `shared/` directory and provide thin root wrappers that load shared first, then overlay-specific configuration.

## Principles

- Shared means safe, generic, and useful in both work and personal contexts.
- Nothing sensitive or private is ever committed here.
- Nothing employer-specific or project-specific belongs here.
- Shared config should be reusable without knowing about one project, one employer, or one machine.

## What Belongs Here

Examples:

- Generic shell aliases
- Generic git aliases
- Generic VS Code user settings
- Shared install/bootstrap behavior
- Reusable shell/editor/tool configuration
- Documentation for the shared/overlay model

Concrete examples:

- `ll`, `la`, `l`, `..`, `...`
- `gs`, `ga`, `gc`, `gp`, `gl`, `gco`, `gst`
- indentation settings
- line numbers
- font sizes
- Vim bindings
- shell wiring that makes the root alias loader work

## What Must Never Be Added

- API keys, access tokens, passwords, secrets, `.env` files
- Internal endpoints
- Company-specific values
- Work-only or personal-only scripts
- Project-specific aliases
- Repo-specific `tasks.json` or `launch.json`
- Machine-specific paths that are not broadly reusable

If something differs by machine, account, employer, or project, it does not belong here.

## Secret Handling

Secrets are never committed.

If a shared script needs configuration:

- it should be stored in ignored file such as `.env`
- IMPORTANT: DO NOT READ / INSPECT THE CONTENT OF .env files
- document the required variable names
- keep only placeholder values in examples
- never place real values in shell scripts, JSON, or Markdown

If a change would require storing a secret in this repo, that change is wrong and should be redesigned.

## Classification Rule

Before adding anything, ask:

1. Is it useful in both work and personal environments?
2. Is it safe to expose publicly?
3. Is it generic rather than tied to one project?

If any answer is no, it does not belong in `dotfiles-shared`.

## Script Rules

Shared scripts should:

- be generic and reusable
- avoid work-specific or personal-project-specific assumptions
- document required env vars
- fail clearly when required input is missing
- avoid hard-coded secrets and private paths

If a script starts depending on one project or one employer, move it out of the shared repo and into an overlay.

## Alias Rules

Shared aliases should:

- be generic
- not depend on a specific repo
- not depend on internal tools
- not call overlay-only scripts
- remain stable across environments

If an alias depends on a project path, service account, or internal workflow, it belongs in an overlay repo.

## Editor Configuration Rules

Shared editor configuration should include only safe defaults:

- formatting preferences
- line numbers
- font sizes
- theme/editor behavior
- Vim integration
- generic suggestion behavior

Do not put repo-specific launch or task configuration in the shared repo.

## Integration Model

Overlay repos should expose stable root entrypoints:

- `install.sh`
- `aliases.sh`

Those wrappers should:

- load shared config first
- then load overlay-specific config

That order is intentional: shared provides the baseline and overlays customize it.

## ai-brain Skills (global exposure)

`scripts/install-ai-brain-skills.sh` symlinks every skill directory under
`$AI_BRAIN_ROOT/.claude/skills/` into `~/.claude/skills/`, so the private ai-brain vault's skills
(`/capture`, `/query`, `/task`, …) are invocable from any directory. The vault is the single source
of truth — no skill logic is copied into this repo. The installer is idempotent and only ever removes
symlinks that point back into the vault (real directories — e.g. an overlay's work-only skills like
`whats-next` — are never touched).

It runs automatically from each overlay's `install.sh`. To run it by hand:

```bash
AI_BRAIN_ROOT="$HOME/workspaces/ai-brain" bash shared/scripts/install-ai-brain-skills.sh
```

### Add / rename / remove a skill

The slash-command name comes from the skill's `name:` frontmatter (and folder name), not from
dotfiles. So the lifecycle is always **edit the vault, then re-run the installer**:

1. **Add** → create `$AI_BRAIN_ROOT/.claude/skills/<name>/SKILL.md` in the vault, then re-run the
   installer.
2. **Rename** → change the skill's `name:` frontmatter **and** its folder name in the vault, then
   re-run the installer. The old symlink is pruned and the new one created automatically.
3. **Remove** → delete the skill's folder in the vault, then re-run the installer (the stale symlink
   is pruned).

Re-run on **each machine**: the vault itself syncs via git, but the `~/.claude/skills/` symlinks are
per-machine. (Opening a new shell also re-runs it, since the overlay `install.sh` calls it.) No
dotfiles change is needed for a rename.

## VS Code config

`scripts/install-vscode-config.sh` applies the shared editor config to the live VS Code user dir:
- **`editors/vscode/keybindings.json`** → symlinked (fully generic).
- **`editors/vscode/settings.json`** → the generic baseline, **merged** (via `jq`) with this machine's
  `overlay/editors/vscode/settings.local.json` (machine keys win) and written to the live `settings.json`.
  The live file is **generated** — put machine/extension/account-specific settings in the overlay's
  `settings.local.json`, not the live file (it's overwritten on each run; a timestamped backup is made).

Run from an overlay install, or by hand. Targets stable VS Code by default; for Insiders/another install,
pass `VSCODE_USER_DIR`:
```bash
bash shared/scripts/install-vscode-config.sh
VSCODE_USER_DIR="$HOME/Library/Application Support/Code - Insiders/User" bash shared/scripts/install-vscode-config.sh
```
> ⚠️ Before first run on a machine with rich existing settings, copy that machine's non-generic keys into
> its `overlay/editors/vscode/settings.local.json` — otherwise the merge replaces the live file with only
> the generic base (the timestamped backup still has the originals).

## Guidance for AI Tools

When changing the shared repo:

- preserve the public-safe boundary
- never add secrets or real credentials
- never add work-only or personal-only behavior
- prefer generic naming and reusable behavior
- if uncertain, do not add it here
- never inspect .env files

Default decision rule:

- shared + safe + generic -> add here
- specific + private + contextual -> add to an overlay repo
- secret or machine-local -> keep it in ignored local config
