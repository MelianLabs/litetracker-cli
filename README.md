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

# Add a label to a story
lt story label <project_id> <story_id> --label "urgent"

# Add a comment to a story
lt story comment <project_id> <story_id> --text "Working on this now"
```

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

## Uninstall

```bash
sudo rm /usr/local/bin/lt
rm -rf ~/.lt
```

## API Reference

[LiteTracker REST API v5 Documentation](https://help.litetracker.com/api/rest/v5.html)
