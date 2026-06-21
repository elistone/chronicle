# CLAUDE.md

## Project Overview

Chronicle is a privacy-first, local-first macOS application for developers.

Chronicle automatically records work activity, builds a searchable timeline of the workday, and helps generate accurate work logs and timesheets.

Chronicle is designed primarily for software developers and technical professionals.

## Core Principles

### Local First

Chronicle stores data locally on the user's machine by default.

The application must function without any cloud services.

### Privacy First

User activity data is private.

Activity data must never be transmitted externally unless the user explicitly configures an integration or AI provider.

### AI Optional

AI is an enhancement, not a requirement.

All core functionality must work without AI.

AI should summarise and enrich existing data, not generate or replace it.

### Developer Focused

Chronicle is built primarily for software developers.

Features that support development workflows are preferred over generic productivity features.

## Non-Goals

Chronicle is not:

* Employee surveillance software
* Screenshot monitoring software
* Keystroke logging software
* Mouse activity tracking software
* Productivity scoring software
* A cloud-first SaaS platform

When in doubt, favour privacy and simplicity.

## Technology Stack

### Application

* Swift
* SwiftUI

### Persistence

* SQLite

### Testing

* Swift Testing

### AI (Future)

* Ollama
* OpenAI (optional)
* Anthropic (optional)

## Development Workflow

Follow Test Driven Development whenever practical.

For new functionality:

1. Create or update tests.
2. Verify tests fail.
3. Implement the minimum code required.
4. Verify tests pass.
5. Refactor if necessary.

Avoid implementing large features without tests.

## Architecture

Prefer feature-based organisation.

Example:

Features/

* ActivityTracking/
* Timeline/
* Dashboard/
* Jira/
* AI/

Shared code belongs in:

* Models/
* Services/
* Database/

Avoid creating large utility folders.

## Dependencies

Prefer Apple frameworks and standard libraries first.

Before introducing a new dependency:

* Confirm it solves a meaningful problem.
* Consider maintenance implications.
* Minimise dependency count.

Avoid dependencies that introduce cloud requirements.

## Data Storage

SQLite is the source of truth.

Do not introduce server-side storage.

Do not introduce cloud synchronisation without explicit discussion and approval.

## User Experience

Chronicle should feel lightweight and unobtrusive.

Prioritise:

* Simplicity
* Performance
* Low resource usage
* Clear visualisations

Avoid unnecessary complexity.

## Security

Use least-privilege access wherever possible.

Only request macOS permissions when required.

Explain permission requirements clearly to users.

## Definition of Done

A task is complete only when:

* Code builds successfully
* Tests pass
* No new warnings are introduced
* Existing architecture is respected
* Documentation is updated if required

## Current Focus

The current goal is validating local activity tracking on macOS.

Prioritise:

1. Active application detection
2. Idle detection
3. Local storage
4. Timeline visualisation

Do not prematurely optimise or implement future roadmap features.

## Instructions for AI Contributors

Before making significant changes:

1. Read README.md
2. Read CLAUDE.md
3. Understand the current roadmap and project goals

When proposing solutions:

* Prefer simple approaches
* Prefer local-first approaches
* Prefer privacy-preserving approaches
* Explain trade-offs when introducing complexity

If a proposed change conflicts with these principles, raise the concern before implementing it.

