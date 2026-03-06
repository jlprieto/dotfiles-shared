# dotfiles-shared

Shared, generic dotfiles used by both my work and personal environments.

This repo is the public, safe-to-share base layer. It contains only generic shell, editor, and tool configuration that is useful in both contexts. It must never contain company-specific settings, personal-only project settings, secrets, tokens, API keys, internal endpoints, or machine-specific paths.

## Purpose

This repo exists so that:
- generic setup is defined once and reused everywhere
- work and personal dotfiles stay somewhat in sync without merging their private details
- AI tools can safely help maintain shared configuration without risking secret leakage or mixing work-specific behavior into personal environments

## Design

This repo is the source of truth for shared configuration.

Other dotfiles repos import this repo into a `shared/` directory and layer their own repo-specific configuration on top. Shared changes are authored here first and then synced into overlay repos.

Current intended structure:

```text
shell/
  aliases.sh
editors/
  vscode/
scripts/
docs/
install.sh
README.md
