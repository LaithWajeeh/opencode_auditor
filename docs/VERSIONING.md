# Versioning

This repo follows **Semantic Versioning 2.0.0**: `vMAJOR.MINOR.PATCH`.

## Bump Rules

| Bump | What triggers it | Example |
|------|------------------|---------|
| MAJOR | Breaking change to workflow, vault structure, install method, or AGENTS.md directives | v1.0.0 → v2.0.0 |
| MINOR | New features, optional tools, non-breaking doc additions, new skills | v0.5.0 → v0.6.0 |
| PATCH | Bug fixes, doc corrections, gitignore tweaks, non-functional refinements | v0.5.0 → v0.5.1 |

## Pre-1.0 Convention

During initial development, major stays at `0`: `v0.MINOR.PATCH`.
- MINOR = new features, tools, workflow additions, breaking changes
- PATCH = fixes, doc corrections, non-functional changes

## What Does NOT Get a Tag

- Plan files or plan archives (internal workflow only)
- Renames, file moves, archive-only commits
- Single-doc edits without functional changes

## Bootstrap URL

Pin the bootstrap URL to the latest stable tag:

```text
curl -fsSL https://raw.githubusercontent.com/CascadeSTEAM/opencode_auditor/v0.9.0/bootstrap.sh | bash
```

Replace `v0.9.0` with the latest tag from the [releases page](https://github.com/CascadeSTEAM/opencode_auditor/releases).

## v1.0.0 Release Criteria

- bootstrap.sh tested on Ubuntu, Fedora, and macOS
- Install flow works: clone → install → opencode
- All SOC2 docs finalized
- At least one full audit cycle completed

## Changelog

Git tags serve as the changelog. Each tag message describes the changes since the previous tag. Run `git log --oneline v0.1.0..v0.6.0` to review.
