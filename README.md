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
