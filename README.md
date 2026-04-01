# lt - LiteTracker CLI

A command-line tool for interacting with the [LiteTracker](https://app.litetracker.com) API. Manage projects, stories, labels, and comments from your terminal.

## Install

**One-liner:**

```bash
curl -fsSL https://raw.githubusercontent.com/MelianLabs/litetracker-cli/main/install.sh | bash
```

**Manual:**

```bash
git clone https://github.com/MelianLabs/litetracker-cli.git
sudo cp litetracker-cli/lt /usr/local/bin/lt
```

**Dependencies:** bash, curl, [jq](https://jqlang.github.io/jq/)

```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
```

## Setup

1. Get your API token from [https://app.litetracker.com/edit](https://app.litetracker.com/edit)
2. Run:

```bash
lt auth
```

Your token is saved to `~/.lt/api_token`.

## Usage

### Projects

```bash
# List all projects
lt projects
```

### Current User

```bash
# Show your user details, accounts, and project memberships
lt me
```

### Stories

```bash
# List stories in a project
lt stories <project_id>

# Show story details
lt story show <project_id> <story_id>

# Create a story
lt story create <project_id> --name "Build login page" --type feature --estimate 3 --label "frontend"

# Create a story with description
lt story create <project_id> --name "Fix bug" --type bug --description "Steps to reproduce..."

# Update a story
lt story update <project_id> <story_id> --state "started" --estimate 3 --owner-ids 42,55

# Add a label to a story
lt story label <project_id> <story_id> --label "urgent"

# List comments on a story
lt story comments <project_id> <story_id>

# Add a comment to a story
lt story comment <project_id> <story_id> --text "Working on this now"
```

### Schema

Inspect any API endpoint to see its HTTP method, path, parameters, request body, and response shape:

```bash
# List all available endpoints
lt schema

# Show details for a specific endpoint
lt schema stories.create
lt schema stories.comments.list
```

This is particularly useful for **AI agents and LLM-based tools** that need to discover which operations are available and how to call them. An agent can run `lt schema` to enumerate endpoints, then `lt schema <endpoint>` to get the full parameter and response specification as structured JSON — no docs lookup required.

### Other

```bash
lt help       # Show help
lt version    # Show version
```

## Examples

```bash
# List your projects and pick one
lt projects

# See what stories are in the project
lt stories 123456

# Create a bug report
lt story create 123456 --name "Fix login redirect" --type bug --description "Login redirects to 404"

# Add a label
lt story label 123456 789012 --label "merged-into-main"

# Leave a note
lt story comment 123456 789012 --text "Root cause found - session cookie not set"
```

## Story Types

**Types:** `feature`, `bug`, `chore`

## AI Agent Integration

`lt` is designed to be used by AI coding agents (Claude Code, Cursor, Copilot, etc.) as a tool for managing project tasks. Agents can:

1. **Discover available operations** — run `lt schema` to list all endpoints
2. **Inspect any endpoint** — run `lt schema stories.create` to get structured JSON describing the method, path, required/optional parameters, request body shape, and response fields
3. **Execute commands** — call `lt` subcommands directly to list projects, read stories and comments, create stories, add labels, etc.

The schema output is machine-readable JSON, so agents can parse it to understand exactly which fields to pass and what to expect back — without needing access to external documentation.

**Example prompt in Claude Code:**

```
Look at story 123456 in project abc123, explain the issue in detail, and propose a fix.
```

The agent will use `lt schema` to discover available operations, then run `lt story show` and `lt story comments` to pull the story details and discussion, and use that context to explain the problem and suggest a solution grounded in the actual conversation.

## Uninstall

```bash
sudo rm /usr/local/bin/lt
rm -rf ~/.lt
```

## API Reference

[LiteTracker REST API v5 Documentation](https://help.litetracker.com/api/rest/v5.html)
