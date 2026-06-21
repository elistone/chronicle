# Git Workflow

Claude must never perform Git operations unless explicitly instructed by the user.

This includes:

* Creating branches
* Switching branches
* Committing
* Amending commits
* Rebasing
* Merging
* Tagging
* Pushing to remotes

Instead:

1. Make the requested code changes.
2. Summarise what changed.
3. Explain why the change was made.
4. Suggest a commit message if appropriate.
5. Wait for user approval before any Git operation.

The user remains responsible for all Git decisions.

Prefer small logical units of work.

A commit should generally represent:

* One feature
* One bug fix
* One investigation spike
* One refactor

Avoid large multi-purpose commits.

---

# Branching

Do not create, switch, merge, or delete branches unless explicitly instructed by the user.

When work would benefit from a dedicated branch:

* Suggest a branch name.
* Explain why a branch may be useful.
* Allow the user to decide.

Examples:

Investigation spikes:

* spike/active-application-detection
* spike/idle-detection
* spike/window-title-detection

Features:

* feature/activity-tracking
* feature/timeline-view
* feature/jira-integration

Branch creation is always a user decision.

---

# ADR Creation

Create ADRs only when:

* A significant architectural or technical decision has been made.
* The decision has been validated through implementation or investigation.
* The decision is expected to influence future development.

Do not create ADRs for:

* Speculative future designs
* Unvalidated assumptions
* Potential future architecture
* Features that have not yet been investigated

Before creating a new ADR:

1. Explain why an ADR may be appropriate.
2. Summarise the decision being documented.
3. Wait for user approval.

ADRs should document decisions that have already been made, not decisions that might be made later.

ADRs should generally contain:

* Context
* Decision
* Consequences

Keep ADRs concise and focused.

---

# Investigation Spikes

Investigation spikes are used to validate assumptions and learn about platform capabilities.

The goal of a spike is discovery, not production architecture.

For spikes:

* Prefer simple implementations.
* Avoid introducing abstractions.
* Avoid introducing dependencies.
* Avoid introducing persistence unless required.
* Focus on learning and documenting findings.

A successful spike should produce:

* A validated assumption
* Limitations discovered
* Permission requirements identified
* Recommended next steps

Document discoveries before moving to implementation work.

# Architecture Philosophy

Prefer concrete implementations over abstractions.

Do not introduce:

* Factories
* Coordinators
* Dependency injection containers
* Plugin systems
* Generic frameworks
* Service locators

unless there is a demonstrated need.

Start simple.

Introduce abstractions only when multiple real use cases require them.

Chronicle is currently in an exploration and validation phase.

Optimise for clarity and learning rather than future flexibility.

