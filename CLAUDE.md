# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`lt` is a single-file bash CLI for the LiteTracker API (Pivotal Tracker v5 compatible). Installed to `/usr/local/bin/lt`. Config lives in `~/.lt/api_token`.

## Architecture

**`lt`** — the entire CLI in one bash script. Structure (top to bottom):
1. Constants (`VERSION`, `BASE_URL`, `CONFIG_DIR`, `TOKEN_FILE`, `CACHE_DIR`, `CACHE_DB`)
2. Helpers (`die`, `check_deps`, `check_cache_deps`, `load_token`, `api_get/post/put`)
3. Cache helpers (`cache_schema_sql` — embedded DDL heredoc — , `cache_init`, `cache_db`, `cache_upsert_project`, `cache_sync_page`, `cache_sync_descriptions`, `cache_sync_comments`, `cache_sync_members`, `sql_lit`)
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
- **Stories pagination:** API caps `/projects/{id}/stories` at 50 rows per response. Use `offset` + `limit` query params to page. The `--all` flag auto-pages until a short page returns.
- **Server-side filtering (`?filter=<clause>`):** discovered empirically — the docs don't mention it. The endpoint accepts a Pivotal-style filter DSL but honors **only one clause per request**; any multi-clause expression (space-, plus-, comma-, pipe-, or `OR`-separated) silently returns `[]`. Working clauses: `state:<x>`, `-state:<x>` (negation), `type:<feature|bug|chore|release>`, `label:<name>`. Silently ignored: `owner:`, `owner_id:`, bare `?state=`, bare `?current_state=`. Because of the single-clause limit, the CLI emulates multi-criteria filtering by picking the most-selective clause server-side and layering the rest client-side (in `resolve_filters`).
- **`ACTIVE_STATES`:** the canonical "in-flight" list — `unstarted planned started finished delivered rejected` (everything that isn't `accepted` and isn't `unscheduled` icebox). `--active` on `lt stories` and `lt cache sync` expands into one server-side sweep per state in this list. `--active` is opt-in (not the default), because the LT filtered endpoint 504s on large/legacy projects (e.g. project 254) — every `filter=` clause times out at 30s on those, while unfiltered pagination keeps working.
- **`STORIES_PAGE_SIZE`:** default 1000, override via `LT_STORIES_PAGE_SIZE`. The "max 50 per page" the CLI used to assume is fiction — empirically `limit=10000` works for unfiltered queries. A high page size means a small (or filter-friendly) project syncs in one round-trip; pagination falls back to multiple round-trips only when the project actually exceeds the page size.
- **Members/users (`lt members`, `lt cache members`, `--with-members`):** `GET /projects/{id}/memberships` returns `[{id, project_id, role, person: {id, name, email, initials, username}}]`. `lt members <pid>` lists them live. In the cache they split across two tables: `people` (global — keyed by person id, since one user belongs to many projects and stories reference them by `owner_id` == person id) and `memberships` (per-project join carrying `role`). `lt cache sync --with-members` fetches one cheap request per project and replaces that project's membership rows wholesale (so people who left are dropped; `people` rows are kept). `lt cache sync --members-only` skips the story sweep entirely (members refresh only — no sync_log row, `last_synced_at` left untouched since it tracks story syncs); it can't be combined with story-sync flags. `lt cache members <pid>` lists one project's members + roles; `lt cache members` (no id) lists every distinct cached user with a project count. `lt cache stats` shows a MEMBERS column. FK `ON DELETE CASCADE` does NOT fire on the per-connection `cache_db` (foreign_keys pragma is only set during `cache_init`), so `cmd_cache_clear` deletes `memberships` rows explicitly.
- **Local cache (`lt cache ...`):** SQLite mirror at `~/.lt/cache/litetracker.db`. Schema is embedded inside the script as the `cache_schema_sql()` heredoc and re-run idempotently on every sync (`CREATE TABLE IF NOT EXISTS`). Diff key for incremental sync is `stories.updated_at`. Each page of /stories is loaded into a temp table via `readfile()` + `json_each()` and reconciled in one transaction — never one `sqlite3` invocation per story. Comments + descriptions are opt-in (`--with-comments`, `--with-descriptions`) and only re-fetched for stories whose `updated_at` advanced. Default `lt cache sync` is unfiltered pagination; pass `--active`/`--state`/`--label`/`--filter` to use the server-side filter DSL when the project supports it.
- **`LT_DEBUG=1`:** logs every API call to stderr with URL, HTTP status, latency, response size, and array length. Also emits sweep boundaries. Use when diagnosing slow syncs or filter-endpoint hangs.

## Testing

No test framework. Test manually:
```bash
./lt help
./lt version
./lt projects          # requires auth
./lt stories <id>      # requires auth + valid project
```

- **Cache write-through:** `lt story show/create/update` call `cache_writethrough_story`, which runs the fetched JSON through `cache_sync_page` — so any single-story API read/write self-heals that story's cache row (state, owners, labels, description). Prefer these over raw `curl` when you want the cache to stay fresh.
- **`lt cache reconcile <pid> <id>... | <pid> [filters]`** — targeted "poor man's sync": pull specific stories (by id, fetched in parallel via `LT_RECONCILE_JOBS`, default 8; each `api_get` in a subshell so a 404 skips that id instead of aborting) or a filtered set (`--state/--exclude-state/--type/--label/--filter/--active`, reusing `resolve_filters`/`fetch_stories_list`), then write them through in ONE `cache_sync_page` transaction. Unlike `cache sync`, it **force-refreshes** every reconciled story via `force_refresh_ids` (nulls the cached `updated_at` so the diff treats them as changed) — necessary because LT does NOT bump `updated_at` on owner-only edits, so a plain sync would leave stale owners/labels. Modes are mutually exclusive (ids XOR filters). **Filter mode 504s on large/legacy projects (254)** like every `filter=` clause; there, derive candidate ids from the cache and reconcile BY ID (which uses per-story GETs that don't 504). By-id is the workhorse for 254.

- **Resumable unfiltered sync (`sync_progress` table):** `lt cache sync` applies stories one page at a time and upserts a `sync_progress` row (`next_offset`, `pages_done`, `status`, `last_error`) after every page. This replaced the old fetch-all path that accumulated the entire result set via repeated `jq -s add` and then one giant `readfile()`→`json_each` — which OOM'd/segfaulted on large projects (254, ~19k stories). On start, an unfiltered sync auto-resumes from the saved `next_offset` if a prior `in_progress`/`failed` checkpoint exists (unless `--full`, which clears it); on a page that fails after the retry budget it records `status=failed` + keeps the offset, exits non-zero, and a re-run continues from there. Only unfiltered pagination is resumable (filtered/active sweeps are single-request). `cmd_cache_clear` deletes `sync_progress` rows explicitly (like `memberships`); `lt cache stats` surfaces interrupted syncs.
- **`cache_db` neutralizes `~/.sqliterc`:** it runs `sqlite3 -init /dev/null -batch -noheader -list -bail`. Without `-init /dev/null` a user rc with `.headers on` / `.mode column` (or a `.load` extension) pollutes single-value reads with header/separator lines and breaks parsing (`${x%%|*}` grabs the header). Heredoc SQL that needs another mode sets its own `.mode`/`.headers`, which override the flags.

## API Reference

LiteTracker REST API v5 docs: https://help.litetracker.com/api/rest/v5.html
