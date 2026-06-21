# CLAUDE.md

## Before Making Changes

Always read:

1. README.md
2. CLAUDE.md
3. Relevant ADRs in Docs/ADR

Architectural decisions documented in ADRs take precedence over assumptions.

If a proposed change conflicts with an ADR, raise the concern before implementing.

## Project Overview

Chronicle is a privacy-first, local-first macOS application for developers.

Chronicle automatically records work activity, builds a searchable timeline of the workday, and helps generate accurate work logs and timesheets.

## Core Principles

### Local First

Chronicle stores data locally on the user's machine by default.

The application must function without cloud services.

### Privacy First

User activity data is private.

Activity data must never be transmitted externally unless explicitly configured by the user.

### AI Optional

AI is an enhancement, not a requirement.

All core functionality must work without AI.

AI should enrich existing data rather than create or replace it.

### Developer Focused

Chronicle is built primarily for software developers and technical professionals.

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

### Testing

* Swift Testing

### Persistence

Persistence technology is defined by ADRs.

Current persistence decisions should not be changed without reviewing existing ADRs.

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

Avoid large generic utility folders.

## Dependencies

Prefer Apple frameworks and standard libraries first.

Before introducing a new dependency:

* Confirm it solves a meaningful problem.
* Consider maintenance implications.
* Minimise dependency count.

Avoid dependencies that introduce cloud requirements.

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
* Relevant documentation is updated if required

## Current Focus

The current goal is validating local activity tracking on macOS.

Prioritise:

1. Active application detection
2. Idle detection
3. Local activity persistence
4. Timeline visualisation

Do not prematurely optimise or implement future roadmap features.

## Instructions for AI Contributors

Before implementing a feature:

* Understand the current roadmap stage.
* Read relevant ADRs.
* Prefer simple solutions.
* Prefer local-first solutions.
* Prefer privacy-preserving solutions.
* Explain trade-offs when introducing complexity.

When uncertain, choose the simplest solution that satisfies the requirement.

