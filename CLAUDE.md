# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`lt` is a single-file bash CLI for the LiteTracker API (Pivotal Tracker v5 compatible). Installed to `/usr/local/bin/lt`. Config lives in `~/.lt/api_token`.

## Architecture

**`lt`** — the entire CLI in one bash script. Structure (top to bottom):
1. Constants (`VERSION`, `BASE_URL`, `CONFIG_DIR`, `TOKEN_FILE`)
2. Helpers (`die`, `check_deps`, `load_token`, `api_get/post/put`)
3. Subcommand functions (`cmd_auth`, `cmd_projects`, `cmd_stories`, etc.)
4. Router (`main()` with nested `case` for `story` sub-actions)

**`install.sh`** — downloads `lt` from GitHub raw and places in `/usr/local/bin`.

## Key Details

- API base URL: `https://app.litetracker.com/services/v5`
- Auth header: `X-TrackerToken`
- JSON built safely with `jq -n --arg` (never string interpolation)
- Table output: `jq -r @tsv | column -ts $'\t'`
- Dependencies: bash, curl, jq

## Testing

No test framework. Test manually:
```bash
./lt help
./lt version
./lt projects          # requires auth
./lt stories <id>      # requires auth + valid project
```

## API Reference

LiteTracker REST API v5 docs: https://help.litetracker.com/api/rest/v5.html
