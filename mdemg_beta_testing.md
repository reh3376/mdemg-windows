# MDEMG Windows Beta Testing Guide

**Version under test:** v0.2.10
**Date:** _______________
**Tester:** _______________
**Machine specs:** _______________
**Windows version:** _______________
**Docker Desktop version:** _______________

---

## Results Summary

| Tier | Section | Tests | Pass | Fail | Skip | Notes |
|------|---------|-------|------|------|------|-------|
| 1 | Installation & Core | 9 | | | | |
| 2 | Ingestion | 8 | | | | |
| 3 | CMS & RSIC | 10 | | | | |
| 4 | Backup & Maintenance | 5 | | | | |
| 5 | Advanced | 7 | | | | |
| **Total** | | **39** | | | | |

---

## Prerequisites

Before starting, confirm the following are installed and running:

| Requirement | Minimum Version | How to Install |
|-------------|-----------------|----------------|
| **Windows** | 10 or 11 (build 19041+) | — |
| **PowerShell** | 7.0+ | `winget install Microsoft.PowerShell` |
| **Docker Desktop** | latest, running | `winget install Docker.DockerDesktop` |
| **Internet access** | — | Required for installation and GitHub API |

**Optional (some tests require these):**

| Requirement | Purpose | How to Install |
|-------------|---------|----------------|
| OpenAI API key | Embedding-powered recall, consolidation | [platform.openai.com](https://platform.openai.com) |
| Ollama | Local-only alternative to OpenAI | [ollama.com](https://ollama.com) |
| Git for Windows | Git hooks, incremental ingest | `winget install Git.Git` |

### Set Up Test Project

```powershell
mkdir C:\Projects\mdemg-test
cd C:\Projects\mdemg-test
git init
# Create a sample file for ingestion tests
@"
package main

import "fmt"

func main() {
    fmt.Println("Hello from MDEMG beta test")
}
"@ | Set-Content main.go
git add . && git commit -m "initial commit"
```

---

## Tier 1: Installation & Core (~30 min)

### T1.1: Installation

Choose **one** method. Only one needs to pass.

**Method A — PowerShell installer (recommended for first-time):**

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
irm https://raw.githubusercontent.com/reh3376/mdemg-windows/main/Install-MDEMG.ps1 | iex
```

**Method B — Scoop:**

```powershell
scoop bucket add mdemg https://github.com/reh3376/mdemg-windows
scoop install mdemg
```

**Method C — Manual:**

```powershell
$tag = (Invoke-RestMethod https://api.github.com/repos/reh3376/mdemg/releases/latest).tag_name
$version = $tag.TrimStart("v")
$zipName = "mdemg_${version}_windows_amd64.zip"
Invoke-WebRequest "https://github.com/reh3376/mdemg/releases/download/$tag/$zipName" -OutFile $zipName
Expand-Archive $zipName -DestinationPath "$HOME\mdemg"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$HOME\mdemg", "User")
$env:PATH += ";$HOME\mdemg"
```

**Expected:** Installer completes without errors. `mdemg.exe` is on PATH.

- [ ] **PASS** — installation completed, `mdemg.exe` accessible from terminal
- [ ] **Method used:** A / B / C

---

### T1.2: Verify Binary

```powershell
mdemg version
```

**Expected output:**

```
mdemg v0.2.x
  commit:  <short-hash>
  built:   <date>
  go:      go1.24.x
  os/arch: windows/amd64
```

- [ ] **PASS** — version displayed with `windows/amd64`

---

### T1.3: Initialize Project

```powershell
cd C:\Projects\mdemg-test
mdemg init --defaults
```

**Expected:** Creates `.mdemg/config.yaml` and `.mdemgignore` in the current directory.

```powershell
# Verify files exist
Test-Path .mdemg\config.yaml
Test-Path .mdemgignore
```

- [ ] **PASS** — both files exist and contain valid content

---

### T1.4: Neo4j Container Lifecycle

```powershell
# Start Neo4j
mdemg db start

# Check status
mdemg db status

# Stop Neo4j
mdemg db stop

# Restart Neo4j
mdemg db start
```

**Expected:** Each command succeeds. `mdemg db status` shows the container as `running` with port info.

```powershell
# Verify container is running
docker ps --filter "name=mdemg-neo4j" --format "{{.Status}}"
```

- [ ] **PASS** — container starts, status shows running, stops cleanly, restarts

---

### T1.5: Database Migrations

```powershell
mdemg db migrate
```

**Expected:** Migrations apply without errors. Output shows "applied N migrations" or "already up to date."

- [ ] **PASS** — migrations complete successfully

---

### T1.6: Server Start

**Try daemon mode first:**

```powershell
mdemg start --auto-migrate
```

> **Note:** Daemon mode now compiles on Windows with platform-specific process management, but may not behave identically to Unix. If it doesn't start correctly, use the foreground fallback below.

**Fallback — foreground mode (open a second PowerShell window):**

```powershell
mdemg serve --auto-migrate
```

Leave this window running. Continue tests in the original window.

**Record which method worked:**

- [ ] **PASS (daemon)** — `mdemg start` worked
- [ ] **PASS (foreground)** — `mdemg serve` worked (daemon failed)
- [ ] **FAIL** — neither method started the server

---

### T1.7: Health Checks

```powershell
# Health check
Invoke-RestMethod http://localhost:9999/healthz

# Readiness check
Invoke-RestMethod http://localhost:9999/readyz
```

**Expected:** Both return `{"status":"ok"}` (or similar JSON with healthy status).

- [ ] **PASS** — both endpoints respond with OK status

---

### T1.8: Configuration Display & Validation

```powershell
mdemg config show
mdemg config validate
```

**Expected:** `config show` displays effective configuration with source annotations (yaml/env/default). `config validate` probes Neo4j connectivity and reports results.

- [ ] **PASS** — config show displays settings, validate confirms Neo4j reachable

---

### T1.9: Embedding Provider Check

```powershell
mdemg embeddings check
```

**Expected (with OpenAI key configured):** Reports embedding provider, model, and dimension count (3072 for text-embedding-3-large).

**Expected (without key):** Reports "no embedding provider configured" or similar warning. This is acceptable — skip to Tier 2.

- [ ] **PASS** — embedding check runs and reports status
- [ ] **SKIP** — no embedding provider configured (note in results)

---

## Tier 2: Ingestion (~20 min)

### T2.1: Codebase Ingestion (CLI)

```powershell
mdemg ingest --path . --space-id beta-test
```

**Expected:** Ingests files from the test project. Output shows files processed, observations created.

- [ ] **PASS** — ingest completes, shows file count and observations

---

### T2.2: Single Observation (API)

```powershell
$body = @{
    space_id   = "beta-test"
    session_id = "beta-session"
    content    = "This is a test observation from Windows beta testing"
    obs_type   = "learning"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/observe `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns JSON with `node_id` and `status` fields.

- [ ] **PASS** — observation created, node_id returned

---

### T2.3: Batch Ingest (API)

```powershell
$body = @{
    space_id = "beta-test"
    nodes = @(
        @{ content = "Windows batch test item 1"; metadata = @{ source = "beta-test" } }
        @{ content = "Windows batch test item 2"; metadata = @{ source = "beta-test" } }
    )
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri http://localhost:9999/v1/memory/ingest `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns JSON with count of ingested nodes.

- [ ] **PASS** — batch ingest returns success with node count

---

### T2.4: Incremental Ingest

```powershell
# Modify test file
Add-Content main.go "`n// Updated for incremental test"
git add . && git commit -m "incremental test change"

# Incremental ingest
mdemg ingest --path . --space-id beta-test --incremental --since HEAD~1
```

**Expected:** Only the modified file is re-ingested.

- [ ] **PASS** — incremental ingest processes only changed files

---

### T2.5: Git Hooks

> **Requires:** Git for Windows (includes Git Bash, needed to run hook scripts)

```powershell
# Install hooks
mdemg hooks install --space-id beta-test

# Verify
mdemg hooks list

# Make a commit — hook should trigger auto-ingest
Add-Content main.go "`n// Hook trigger test"
git add . && git commit -m "hook test"
```

**Expected:** `hooks list` shows post-commit hook installed. After commit, hook triggers background ingest (check server logs for ingest activity).

> **Known limitation:** Git hooks generate `#!/bin/bash` scripts. They require Git Bash (bundled with Git for Windows). If Git was installed without Git Bash, hooks will not execute.

- [ ] **PASS** — hooks install, list shows installed, commit triggers ingest
- [ ] **SKIP** — Git not installed

---

### T2.6: File Watcher

Open a **second PowerShell window:**

```powershell
cd C:\Projects\mdemg-test
mdemg watch --path . --space-id beta-test
```

In the **original window**, create a new file:

```powershell
"// New file for watcher test" | Set-Content watcher_test.go
```

**Expected:** The watcher window shows the new file was detected and ingested.

Press `Ctrl+C` in the watcher window when done.

- [ ] **PASS** — watcher detects file creation and ingests it

---

### T2.7: Web Scraper

> **Skip** if no target URL is available for scraping.

```powershell
$body = @{
    space_id  = "beta-test"
    url       = "https://example.com"
    max_pages = 1
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/scraper/jobs `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns a job ID. Check status with `GET /v1/scraper/jobs/{job_id}`.

- [ ] **PASS** — scraper job created
- [ ] **SKIP** — no URL configured

---

### T2.8: Linear Integration

> **Skip** if no `LINEAR_API_KEY` is configured.

```powershell
Invoke-RestMethod http://localhost:9999/v1/linear/issues?space_id=beta-test
```

**Expected:** Returns issues list or empty array.

- [ ] **PASS** — Linear endpoint responds
- [ ] **SKIP** — no LINEAR_API_KEY configured

---

## Tier 3: CMS & RSIC (~20 min)

### T3.1: Observe (Multiple Types)

```powershell
# Decision observation
$body = @{
    space_id   = "beta-test"
    session_id = "beta-session"
    content    = "Decided to use PowerShell 7 for all testing"
    obs_type   = "decision"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/observe `
    -Method POST -ContentType "application/json" -Body $body

# Error observation
$body = @{
    space_id   = "beta-test"
    session_id = "beta-session"
    content    = "Build failed: missing dependency xyz"
    obs_type   = "error"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/observe `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Both return JSON with `node_id`.

- [ ] **PASS** — multiple obs_types accepted (decision, error)

---

### T3.2: Resume Session

```powershell
$body = @{
    space_id        = "beta-test"
    session_id      = "beta-session"
    max_observations = 10
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/resume `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns previously observed content from the session.

- [ ] **PASS** — resume returns prior observations

---

### T3.3: Recall (Semantic Query)

> **Requires:** Embedding provider configured (OpenAI or Ollama)

```powershell
$body = @{
    space_id = "beta-test"
    query    = "What decisions were made during testing?"
    top_k    = 5
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/recall `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns relevant observations ranked by semantic similarity.

- [ ] **PASS** — recall returns relevant results
- [ ] **SKIP** — no embedding provider (degraded mode)

---

### T3.4: Correct

```powershell
$body = @{
    space_id   = "beta-test"
    session_id = "beta-session"
    content    = "Correction: dependency xyz is actually version 2.0"
    obs_type   = "correction"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/conversation/correct `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns JSON confirming the correction was recorded.

- [ ] **PASS** — correction accepted and stored

---

### T3.5: Consolidation

```powershell
$body = @{
    space_id = "beta-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/memory/consolidate `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns consolidation results (hidden nodes created, edges formed). Without an LLM key, concept naming may be degraded but consolidation still runs.

- [ ] **PASS** — consolidation completes

---

### T3.6: Session Health

```powershell
Invoke-RestMethod http://localhost:9999/v1/conversation/session/health?space_id=beta-test`&session_id=beta-session
```

**Expected:** Returns health metrics for the session (observation count, freshness, etc.).

- [ ] **PASS** — session health returned with metrics

---

### T3.7: RSIC Assess

```powershell
$body = @{
    space_id = "beta-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/self-improve/assess `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns assessment with scores and recommendations.

- [ ] **PASS** — assessment returned

---

### T3.8: RSIC Cycle (Dry Run)

```powershell
$body = @{
    space_id = "beta-test"
    dry_run  = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/self-improve/cycle `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns what the self-improvement cycle *would* do, without making changes.

- [ ] **PASS** — dry run cycle returns plan

---

### T3.9: RSIC Health

```powershell
Invoke-RestMethod http://localhost:9999/v1/self-improve/health?space_id=beta-test
```

**Expected:** Returns RSIC health metrics.

- [ ] **PASS** — RSIC health returned

---

### T3.10: Learning Freeze / Unfreeze

```powershell
# Freeze
$body = @{
    space_id  = "beta-test"
    reason    = "beta testing"
    frozen_by = "tester"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/learning/freeze `
    -Method POST -ContentType "application/json" -Body $body

# Check status
Invoke-RestMethod http://localhost:9999/v1/learning/status?space_id=beta-test

# Unfreeze
$body = @{
    space_id = "beta-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/learning/unfreeze `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Freeze returns confirmation, status shows frozen=true, unfreeze returns confirmation.

- [ ] **PASS** — freeze/status/unfreeze cycle completes

---

## Tier 4: Backup & Maintenance (~10 min)

### T4.1: Backup Trigger

```powershell
$body = @{
    space_id = "beta-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/backup/trigger `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns backup job ID or confirmation.

- [ ] **PASS** — backup triggered

---

### T4.2: Backup List

```powershell
Invoke-RestMethod http://localhost:9999/v1/backup/list?space_id=beta-test
```

**Expected:** Returns list of backups (may include the one just created).

- [ ] **PASS** — backup list returned

---

### T4.3: Decay (Dry Run)

```powershell
mdemg decay --space-id beta-test --dry-run
```

**Expected:** Shows what edges would be decayed without making changes.

- [ ] **PASS** — decay dry run shows results

---

### T4.4: Prune (Dry Run)

```powershell
mdemg prune --space-id beta-test --dry-run
```

**Expected:** Shows what edges/nodes would be pruned without making changes.

- [ ] **PASS** — prune dry run shows results

---

### T4.5: Space List

```powershell
mdemg space list
```

**Expected:** Lists all spaces including `beta-test`.

- [ ] **PASS** — space list shows beta-test

---

## Tier 5: Advanced (~15 min)

### T5.1: Secrets (Windows Credential Manager)

```powershell
# Store a test secret
mdemg config set-secret TEST_BETA_KEY "beta-test-value-12345"

# Retrieve it
mdemg config get-secret TEST_BETA_KEY

# List all secrets
mdemg config list-secrets
```

**Expected:** Secret is stored in Windows Credential Manager, retrieved correctly, and listed.

- [ ] **PASS** — set/get/list secrets works via Windows Credential Manager

---

### T5.2: Memory Retrieval

```powershell
$body = @{
    space_id = "beta-test"
    query    = "beta testing"
    top_k    = 5
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:9999/v1/memory/retrieve `
    -Method POST -ContentType "application/json" -Body $body
```

**Expected:** Returns retrieved memory nodes.

- [ ] **PASS** — memory retrieval returns results
- [ ] **SKIP** — no embedding provider

---

### T5.3: Demo

```powershell
mdemg demo
```

**Expected:** Interactive demo runs, shows MDEMG capabilities. Follow on-screen prompts.

- [ ] **PASS** — demo runs to completion

---

### T5.4: Extract Symbols

```powershell
mdemg extract-symbols --path .
```

**Expected:** Extracts code symbols (functions, types, etc.) from files in the directory.

- [ ] **PASS** — symbols extracted and listed

---

### T5.5: Consolidation (CLI)

```powershell
mdemg consolidate --space-id beta-test --dry-run
```

**Expected:** Shows consolidation plan without executing.

- [ ] **PASS** — consolidation dry run shows plan

---

### T5.6: MCP Server

```powershell
mdemg mcp
```

**Expected:** MCP server starts and listens for JSON-RPC input on stdin. Press `Ctrl+C` to exit.

- [ ] **PASS** — MCP server starts, responds to Ctrl+C

---

### T5.7: Upgrade Check

```powershell
mdemg upgrade --dry-run
```

> **Known limitation:** `mdemg upgrade` looks for `.tar.gz` archives but Windows releases use `.zip`. The upgrade will report "no release binary found for windows/amd64" until this is fixed. Document the exact error message.

**Expected:** Reports current version and latest version. May fail to find Windows binary.

- [ ] **PASS** — upgrade check runs (even if no binary found)
- [ ] **EXPECTED FAIL** — reports `.tar.gz` not found for windows/amd64

**Error message received:** _______________

---

## Cleanup / Teardown

Run these steps to restore the machine to pre-test state:

```powershell
# 1. Stop the server
# If using daemon mode:
mdemg stop
# If using foreground mode: press Ctrl+C in the server window

# 2. Uninstall git hooks
cd C:\Projects\mdemg-test
mdemg hooks uninstall

# 3. Stop and remove Neo4j container
mdemg db stop --remove

# 4. Remove Docker volume
docker volume ls -q --filter name=mdemg | ForEach-Object { docker volume rm $_ }

# 5. Remove test project
cd C:\
Remove-Item C:\Projects\mdemg-test -Recurse -Force

# 6. Remove MDEMG config (optional — only if uninstalling entirely)
# Remove-Item "$HOME\.mdemg" -Recurse -Force

# 7. Clean up test secret
mdemg config set-secret TEST_BETA_KEY ""
```

---

## Known Windows Limitations

### 1. Daemon Mode (`mdemg start/stop/restart`)

**Issue:** Daemon mode compiles on Windows but uses platform-specific process management (tasklist for process checks, `CREATE_NEW_PROCESS_GROUP` for detach). It may not behave identically to Unix daemon mode. Test carefully — if it doesn't work, use the foreground fallback.

**Workaround:** Use `mdemg serve --auto-migrate` in a foreground PowerShell window instead. For unattended operation, create a Windows Task Scheduler entry:

```powershell
$action = New-ScheduledTaskAction -Execute "mdemg.exe" -Argument "serve --auto-migrate"
$trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "MDEMG Server" -Action $action -Trigger $trigger
```

### 2. Git Hooks Require Git Bash

**Issue:** `mdemg hooks install` generates `#!/bin/bash` shell scripts. These require Git Bash, which is bundled with Git for Windows.

**Workaround:** Ensure Git for Windows is installed with the "Git Bash" component (default). If hooks do not fire, verify `bash.exe` is on PATH:

```powershell
Get-Command bash -ErrorAction SilentlyContinue
```

### 3. `mdemg upgrade` — Archive Format Mismatch

**Issue:** The upgrade command constructs a `.tar.gz` archive filename (`mdemg_{version}_{os}_{arch}.tar.gz`) but Windows releases are packaged as `.zip`. The upgrade will fail with "no release binary found for windows/amd64."

**Workaround:** Use the PowerShell installer to upgrade:

```powershell
.\Install-MDEMG.ps1 -Upgrade
# Or with Scoop:
scoop update mdemg
```

### 4. Features Requiring an LLM API Key

The following features return degraded or empty results without an OpenAI or Ollama embedding provider configured:

- `recall` — semantic search returns no results
- `consolidation` — concept naming uses fallback (generic names)
- `SME consult` — consulting service unavailable
- `meta-learn` — cross-space generalization unavailable

**Workaround:** Set an OpenAI key in `.env` or via Credential Manager:

```powershell
mdemg config set-secret OPENAI_API_KEY sk-...
# Or in .env:
# OPENAI_API_KEY=sk-...
```

### 5. Web Scraper / Linear Integration

**Issue:** These features require separate API key configuration and external service access.

**Workaround:** Configure in `.env` or via `mdemg config set-secret`:

```powershell
# Linear
mdemg config set-secret LINEAR_API_KEY lin_api_...

# Scraper works with public URLs, no key needed
```

---

## Feedback & Issue Reporting

### Filing Issues

File issues at: **https://github.com/reh3376/mdemg/issues**

**Title format:** `[Windows Beta] <brief description>`

**Labels:** Add `windows` and `beta-testing`

### Include in Every Report

```
**Environment:**
- Windows version: (e.g., Windows 11 23H2, build 22631)
- MDEMG version: (output of `mdemg version`)
- Docker Desktop version: (output of `docker --version`)
- PowerShell version: (output of `$PSVersionTable.PSVersion`)
- Installation method: (Installer / Scoop / Manual)

**Steps to Reproduce:**
1. <exact command>
2. <exact command>

**Expected Result:**
<what should have happened>

**Actual Result:**
<what actually happened — paste full output>

**Server Log (if applicable):**
<output of: Get-Content "$HOME\.mdemg\logs\mdemg.log" -Tail 50>
```

### Severity Guide

| Severity | Meaning | Example |
|----------|---------|---------|
| **Critical** | Cannot install or start | Binary won't run, server crashes on start |
| **High** | Core feature broken | Ingest fails, observations not stored |
| **Medium** | Feature degraded | Hooks don't fire, config show incomplete |
| **Low** | Cosmetic or edge case | Wrong path separator in output, minor formatting |

---

## End of Testing

After completing all tiers, fill in the Results Summary table at the top of this document and submit it along with any issues filed.

Thank you for beta testing MDEMG on Windows!
