# 1. Symlink the publish-html skill

Status: accepted

## Context

The publish-html skill must be available in every project, but `pub` and the skill's source live in this repository.

## Decision

The skill is symlinked from this repository (the PM links `skills/publish-html` into `~/.agents/skills/publish-html`) rather than copied.

## Consequences

One source of truth: edits here reach every project, and copies cannot drift. The symlink breaks if this repository moves.
