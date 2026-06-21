# Chronicle

Chronicle is a privacy-first macOS application that automatically records work activity, helping developers understand where their time went and generate accurate work logs.

Unlike traditional time trackers, Chronicle focuses on building a searchable timeline of the workday. It records activity locally, helps correlate work with projects and tickets, and can optionally generate summaries and timesheets.

## Goals

* Record work activity automatically
* Build a searchable timeline of the workday
* Help developers create accurate timesheets
* Integrate with tools such as Jira
* Keep all data local by default
* Support optional AI-powered summaries and insights

## Non-Goals

Chronicle is not intended to be:

* Employee surveillance software
* Screenshot monitoring software
* Keystroke logging software
* Mouse activity tracking software
* A cloud-first SaaS platform
* A productivity scoring system

## Principles

### Local First

Chronicle stores data locally on the user's machine by default.

### Privacy First

User activity data should never leave the machine unless the user explicitly configures an integration or AI provider.

### Developer Focused

Chronicle is designed primarily for software developers and technical professionals.

### AI Optional

AI should enhance the user experience, not be required for core functionality.

The application must remain fully functional without AI services.

## Planned Features

### Activity Tracking

* Active application tracking
* Window title tracking
* Idle detection
* Workday duration tracking

### Timeline

* Searchable activity timeline
* Daily activity view
* Weekly activity summaries

### Developer Context

* Git repository detection
* Git branch detection
* Ticket reference detection

### Jira Integration

* Ticket correlation
* Worklog generation
* Time submission assistance

### AI Enhancements

* Daily work summaries
* Weekly summaries
* Activity categorisation
* Natural language search

## Roadmap

### v0.1

* Active application tracking
* Idle detection
* Persist activity data locally
* Timeline view

### v0.2

* Window title tracking
* Git repository detection
* Git branch detection

### v0.3

* Jira integration
* Worklog generation

### v0.4

* Optional AI summaries

## Status

Chronicle is currently in early development.

The initial focus is validating activity tracking on macOS and establishing a solid local-first architecture before adding integrations and AI features.

## Architecture Decisions

Significant architectural decisions are documented in the `Docs/ADR` directory.

## License

MIT

