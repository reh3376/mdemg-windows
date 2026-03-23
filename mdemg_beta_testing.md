# MDEMG Windows Beta Testing Guide

**Version under test:** v0.2.15
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
| 2 | Ingestion | 9 | | | | |
| 3 | CMS & RSIC | 10 | | | | |
| 4 | Backup & Maintenance | 5 | | | | |
| 5 | Advanced | 9 | | | | |
| **Total** | | **42** | | | | |

---

## Prerequisites

Complete each section below in order before starting the tests. Do not assume anything is pre-installed — verify each item.

### Step 1: Verify Windows Version

MDEMG requires Windows 10 version 21H2 or later, or Windows 11. Docker Desktop (required for Neo4j) needs WSL 2 support which is only available on these versions.

```powershell
# Check your Windows version
[System.Environment]::OSVersion.Version
# Must be 10.0.19044 or higher

# Check build number
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
# Must be 21H2 or later
```

- [ ] Windows version verified: _______________

### Step 2: Enable Hardware Virtualization

Docker Desktop requires hardware virtualization (Intel VT-x or AMD-V) enabled in your BIOS/UEFI firmware. This is often disabled by default on new machines.

```powershell
# Check if virtualization is enabled
(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
# Must return True
```

If `False`, restart your machine, enter BIOS/UEFI settings (usually F2, F10, F12, or DEL during boot), find the virtualization option (may be labeled "Intel Virtualization Technology", "VT-x", "AMD-V", or "SVM Mode"), enable it, and save/restart.

- [ ] Hardware virtualization enabled

### Step 3: Enable WSL 2

Docker Desktop for Windows requires WSL 2 (Windows Subsystem for Linux version 2). This requires enabling two Windows features.

```powershell
# Run PowerShell as Administrator for this step
# Option A — single command (requires restart):
wsl --install

# Option B — if wsl command is not found, enable features manually:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Then restart your machine

# After restart, verify WSL 2 is available:
wsl --status
```

> **Note:** `wsl --install` also installs a default Linux distribution (Ubuntu). This is fine — Docker Desktop uses WSL 2 as its backend but does not require a Linux distribution for MDEMG.

- [ ] WSL 2 enabled and working

### Step 4: Install PowerShell 7+

Windows ships with **PowerShell 5.1** ("Windows PowerShell"), which is NOT the same as **PowerShell 7+** ("PowerShell"). The MDEMG installer script requires PowerShell 7.0 or later and will not run on PowerShell 5.1.

```powershell
# Check if PowerShell 7+ is already installed
pwsh --version
# If this returns "PowerShell 7.x.x", skip to the next step

# Install PowerShell 7 — choose one method:

# Method A — winget (if available; ships with Windows 11, may need App Installer on Windows 10):
winget install Microsoft.PowerShell

# Method B — MSI installer (works on any Windows version):
# Download from: https://github.com/PowerShell/PowerShell/releases/latest
# Choose the "PowerShell-7.x.x-win-x64.msi" file, run the installer

# Method C — Microsoft Store:
# Search for "PowerShell" in the Microsoft Store app and install it
```

After installation, close your current terminal and open **PowerShell 7** (not "Windows PowerShell"):
- Search for "pwsh" or "PowerShell 7" in the Start menu
- Or run `pwsh` from any terminal

```powershell
# Verify you are in PowerShell 7+
$PSVersionTable.PSVersion
# Major must be 7 or higher
```

- [ ] PowerShell 7+ installed, version: _______________

### Step 5: Set Execution Policy

PowerShell's default execution policy on Windows client machines is `Restricted`, which blocks all scripts. You must change this to allow running the MDEMG installer and PowerShell wrapper scripts.

```powershell
# Check current policy
Get-ExecutionPolicy -Scope CurrentUser

# If it says "Restricted" or "AllSigned", change it:
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# Verify
Get-ExecutionPolicy -Scope CurrentUser
# Must say "RemoteSigned" or "Unrestricted"
```

- [ ] Execution policy set to RemoteSigned or Unrestricted

### Step 6: Install Docker Desktop

Docker Desktop runs the Neo4j database container. MDEMG cannot function without it.

```powershell
# Check if Docker is already installed and running
docker --version
docker info   # This must succeed — if it errors, Docker Desktop is not running

# Install Docker Desktop — choose one method:

# Method A — winget:
winget install Docker.DockerDesktop

# Method B — direct download:
# Download from: https://www.docker.com/products/docker-desktop/
# Run the installer, follow prompts
# IMPORTANT: Select "Use WSL 2 instead of Hyper-V" when prompted
```

After installation:
1. Launch Docker Desktop from the Start menu
2. Wait for Docker Desktop to finish starting (system tray icon stops animating)
3. Accept the license agreement if prompted

```powershell
# Verify Docker is running
docker info
# Should show "Server: Docker Desktop" and WSL 2 backend info

docker run --rm hello-world
# Should print "Hello from Docker!"
```

> **Note:** Docker Desktop must be running whenever you use MDEMG. It does not auto-start by default — you may want to enable "Start Docker Desktop when you sign in" in Docker Desktop Settings > General.

- [ ] Docker Desktop installed and running, version: _______________

### Step 7: Internet Access

The machine must have internet access to:
- Download the MDEMG binary from GitHub releases
- Pull the Neo4j Docker image (`neo4j:5`, ~500MB) on first `mdemg db start`
- (Optional) Connect to the OpenAI API for embeddings

```powershell
# Verify connectivity to GitHub
Invoke-RestMethod https://api.github.com/repos/reh3376/mdemg/releases/latest | Select-Object -Property tag_name
```

- [ ] Internet access confirmed

### Optional Prerequisites

These are not required for basic testing but are needed for specific test tiers.

#### OpenAI API Key (Tier 2-3: recall, consolidation, memory retrieval)

Required for embedding-powered features: semantic recall, consolidation concept naming, memory retrieval, and SME consulting. Without a key, these features run in degraded mode (stub embeddings or no results).

1. Sign up at [platform.openai.com](https://platform.openai.com)
2. Create an API key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
3. Save the key — you'll configure it during `mdemg init` or set it in a `.env` file

- [ ] OpenAI API key obtained (or will skip embedding tests)

#### Ollama (Alternative to OpenAI)

Local-only alternative to OpenAI for embeddings. No API key or internet required after initial download.

1. Download from [ollama.com/download/windows](https://ollama.com/download/windows)
2. Run the installer
3. Pull an embedding model: `ollama pull nomic-embed-text`

- [ ] Ollama installed (or using OpenAI, or will skip embedding tests)

#### Git for Windows (Tier 2: hooks, incremental ingest, test project setup)

Required for git hooks, incremental ingest (`--since`), and setting up the test project. The MDEMG git hook script uses `#!/bin/bash` and requires Git Bash (bundled with Git for Windows by default).

```powershell
# Check if Git is already installed
git --version

# Install Git — choose one method:

# Method A — winget:
winget install Git.Git

# Method B — direct download:
# Download from: https://gitforwindows.org/
# Run the installer
# IMPORTANT: Keep "Git Bash" selected (default) — MDEMG hooks require it
```

After installation, close and reopen your PowerShell window so `git` is on PATH.

```powershell
# Verify
git --version
# Verify Git Bash is available (required for MDEMG hooks)
Get-Command bash -ErrorAction SilentlyContinue
```

- [ ] Git installed, version: _______________
- [ ] Git Bash available (bash.exe on PATH)
- [ ] **SKIP** — will skip git-dependent tests (T2.4, T2.5)

#### Scoop Package Manager (Installation Method B only)

Only needed if you plan to install MDEMG via Scoop. Not required for Method A (PowerShell installer) or Method C (manual).

```powershell
# Check if Scoop is installed
scoop --version

# Install Scoop (requires PowerShell 5+ and .NET Framework 4.5+):
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
Invoke-RestMethod get.scoop.sh | Invoke-Expression
```

- [ ] Scoop installed (or using a different installation method)

### Set Up Test Project

> **Requires:** Git for Windows (from optional prerequisites above). If Git is not installed, you can still test most features — just create the test directory and file manually without the git commands.

**With Git installed:**

```powershell
mkdir C:\Projects\mdemg-test
cd C:\Projects\mdemg-test
git init
git config user.email "tester@example.com"
git config user.name "Beta Tester"
# Create a sample file for ingestion tests
@"
package main

import "fmt"

func main() {
    fmt.Println("Hello from MDEMG beta test")
}
"@ | Set-Content main.go
git add .
git commit -m "initial commit"
```

**Without Git (manual alternative):**

```powershell
mkdir C:\Projects\mdemg-test
cd C:\Projects\mdemg-test
@"
package main

import "fmt"

func main() {
    fmt.Println("Hello from MDEMG beta test")
}
"@ | Set-Content main.go
```

> **Note:** Without Git, you will need to skip tests T2.4 (incremental ingest), T2.5 (hooks), and T1.3's init may not detect a git repo.

- [ ] Test project directory created at `C:\Projects\mdemg-test`

### Prerequisites Checklist Summary

| # | Requirement | Status | Comments |
|---|-------------|--------|----------|
| 1 | Windows 10 21H2+ or Windows 11 | | Required for WSL 2 and Docker Desktop. Verify: `winver` → Build 19044+ |
| 2 | Hardware virtualization enabled | | Docker Desktop requires VT-x/AMD-V. Verify: Task Manager → Performance → CPU → "Virtualization: Enabled" |
| 3 | WSL 2 enabled | | Docker Desktop backend on Windows. Verify: `wsl --status` shows "Default Version: 2" |
| 4 | PowerShell 7+ installed | | Installer script uses `#Requires -Version 7.0`. Verify: `$PSVersionTable.PSVersion.Major` ≥ 7 |
| 5 | Execution policy: RemoteSigned | | Allows running downloaded scripts (installer, hooks). Verify: `Get-ExecutionPolicy` returns `RemoteSigned` |
| 6 | Docker Desktop installed and running | | Neo4j runs as a Docker container. Verify: `docker info` succeeds without errors |
| 7 | Internet access confirmed | | Needed to download release binary and Docker images. Verify: `Test-Connection github.com -Count 1` |
| — | *OpenAI API key (optional)* | | Enables LLM summaries, recall re-ranking, consolidation naming. Without it, those features return degraded results. Verify: `$env:OPENAI_API_KEY` is set |
| — | *Ollama (optional)* | | Local LLM alternative to OpenAI — no API key needed. Verify: `ollama list` shows available models |
| — | *Git for Windows + Git Bash (optional)* | | Required for incremental ingest, git hooks, and commit-triggered ingestion. Verify: `git --version` in PowerShell |
| — | *Scoop (optional, Method B only)* | | Package manager for easy install/update/uninstall. Verify: `scoop --version` |
| — | Test project created | | Isolated directory for beta testing. Verify: `Test-Path C:\Projects\mdemg-test` returns `True` |

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
mdemg init
```

**Expected:** Interactive wizard prompts for Space ID, Neo4j URI, embedding provider, and OpenAI API key. Creates `.mdemg/config.yaml`, `.mdemgignore`, and `.env` in the current directory.

> **Important:** Do NOT use `--defaults` here. The interactive wizard lets you enter your OpenAI API key, which is required for embedding and LLM features in subsequent tests. If you skip this, `mdemg start` will fail on embedding checks.

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

### T2.9: Speed Presets

**T2.9.1: Fast Preset Dry-Run**
```powershell
mdemg ingest --path . --speed fast --dry-run
```
Expected: Workers=8, batch=250, LLM summaries disabled, symbol extraction disabled.

**T2.9.2: Thorough Preset Dry-Run**
```powershell
mdemg ingest --path . --speed thorough --dry-run
```
Expected: Workers=8, batch=200, LLM summaries enabled, batch=20, symbols enabled.

**T2.9.3: Flag Override**
```powershell
mdemg ingest --path . --speed fast --llm-summary=true --dry-run
```
Expected: Fast settings BUT LLM summaries still enabled (flag override takes precedence).

**T2.9.4: Combined Presets**
```powershell
mdemg ingest --path . --speed fast --preset ml_cuda --dry-run
```
Expected: Speed preset (workers, batch, LLM) + exclusion preset (ml_cuda dirs/patterns) both applied.

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

**Expected:** Reports current version and latest available version, then downloads and installs the latest release from GitHub.

- [ ] **PASS** — upgrade check runs and reports version information
- [ ] **FAIL** — upgrade fails (note error message below)

**Error message received (if failed):** _______________

---

### T5.8: Teardown Dry Run

```powershell
cd C:\Projects\mdemg-test
mdemg teardown --dry-run
```

**Expected:** Lists all artifacts that would be removed (server, Docker container/volume, hooks, MCP configs, `.mdemg\` directory) without making any changes.

- [ ] **PASS** — dry run lists artifacts without making changes

---

### T5.9: Teardown Execute

> **Warning:** This removes all MDEMG artifacts for the test project. Run this test LAST — it replaces the manual cleanup steps below.

```powershell
cd C:\Projects\mdemg-test
mdemg teardown --yes
```

**Expected:** Server stops, Docker container/volume removed, hooks uninstalled, MCP configs cleaned, `.mdemg\` backed up and removed. Output shows each phase completing.

```powershell
# Verify cleanup
if (Test-Path .mdemg) { "FAIL: .mdemg still exists" } else { "OK: .mdemg removed" }
```

- [ ] **PASS** — teardown completes, all artifacts removed, backup created

---

## Cleanup / Teardown

### Recommended: Use `mdemg teardown` (if T5.9 was not run)

```powershell
cd C:\Projects\mdemg-test
mdemg teardown --yes
```

This single command handles steps 1-6 below automatically: stops the server, removes Docker container/volume, uninstalls hooks, cleans MCP/IDE configs, backs up and removes `.mdemg\`.

### Manual cleanup (fallback)

If `mdemg teardown` is not available or failed:

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

# 5. Remove MDEMG config (optional — only if uninstalling entirely)
# Remove-Item "$HOME\.mdemg" -Recurse -Force

# 6. Clean up test secret
mdemg config set-secret TEST_BETA_KEY ""
```

### Final cleanup (all methods)

```powershell
# Remove test project
cd C:\
Remove-Item C:\Projects\mdemg-test -Recurse -Force
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

### 3. `mdemg upgrade` — Self-Update

`mdemg upgrade` downloads and installs the latest release directly from GitHub. If the upgrade fails, use the PowerShell installer as a fallback:

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
