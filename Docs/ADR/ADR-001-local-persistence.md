# ADR-001: Local Persistence

Status: Accepted

## Context

Chronicle is a local-first application.

The application needs to persist activity data locally to support timelines, reporting, and future integrations.

## Decision

Chronicle will store activity data locally on the user's machine.

SQLite will be used as the initial persistence technology.

## Consequences

* No server infrastructure is required.
* Data remains under user control.
* Future storage implementations may be considered if requirements change.

The local-first principle is more important than the specific storage technology.

