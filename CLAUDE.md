# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`lt` is a single-file bash CLI for the LiteTracker API (Pivotal Tracker v5 compatible). Installed to `/usr/local/bin/lt`. Config lives in `~/.lt/api_token`.

## Architecture

**`lt`** — the entire CLI in one bash script. Structure (top to bottom):
1. Constants (`VERSION`, `BASE_URL`, `CONFIG_DIR`, `TOKEN_FILE`, `CACHE_DIR`, `CACHE_DB`)
2. Helpers (`die`, `check_deps`, `check_cache_deps`, `load_token`, `api_get/post/put`)
3. Cache helpers (`cache_schema_sql` — embedded DDL heredoc — , `cache_init`, `cache_db`, `cache_upsert_project`, `cache_sync_page`, `cache_sync_descriptions`, `cache_sync_comments`, `sql_lit`)
4. Subcommand functions (`cmd_auth`, `cmd_projects`, `cmd_stories`, `cmd_cache_*`, etc.)
5. Router (`main()` with nested `case` for `story` and `cache` sub-actions)

**`install.sh`** — downloads `lt` from GitHub raw and places in `/usr/local/bin`.

## Key Details

- API base URL: `https://app.litetracker.com/services/v5`
- Auth header: `X-TrackerToken`
- JSON built safely with `jq -n --arg` (never string interpolation)
- `api_get` retries 5xx and curl/network failures with exponential backoff (1s, 2s, 4s, 8s, 16s — 5 attempts; tunable via `LT_API_MAX_ATTEMPTS`). 4xx fails fast. `api_post`/`api_put` deliberately do NOT retry — writes are not guaranteed idempotent.
- Table output: `jq -r @tsv | column -ts $'\t'`
- Dependencies: bash, curl, jq, and `sqlite3` (only for `lt cache` commands; gated by `check_cache_deps`)
- **Stories pagination:** API caps `/projects/{id}/stories` at 50 rows per response. Use `offset` + `limit` query params to page. The server ignores `state=` — filtering by state is implemented client-side in `cmd_stories` via `jq`. The `--all` flag auto-pages until a short page returns.
- **Local cache (`lt cache ...`):** SQLite mirror at `~/.lt/cache/litetracker.db`. Schema is embedded inside the script as the `cache_schema_sql()` heredoc and re-run idempotently on every sync (`CREATE TABLE IF NOT EXISTS`). Diff key for incremental sync is `stories.updated_at`. Each page of /stories is loaded into a temp table via `readfile()` + `json_each()` and reconciled in one transaction — never one `sqlite3` invocation per story. Comments + descriptions are opt-in (`--with-comments`, `--with-descriptions`) and only re-fetched for stories whose `updated_at` advanced.

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
