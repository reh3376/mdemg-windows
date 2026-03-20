# MDEMG — Windows Installation Guide

> Windows equivalent of: `brew tap reh3376/mdemg && brew install mdemg`

## Prerequisites

| Requirement | Version | Install |
|-------------|---------|---------|
| **PowerShell** | 7.0+ | `winget install Microsoft.PowerShell` |
| **Docker Desktop** | latest | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) or `winget install Docker.DockerDesktop` |
| **Neo4j** | 5.11+ | Managed automatically via `mdemg db start` (pulls `neo4j:5` Docker image) |
| **OpenAI API key** | — | [platform.openai.com](https://platform.openai.com) — or use [Ollama](https://ollama.com) for local-only. **Note:** If using Ollama, the embedding model must produce 3072-dimensional vectors to match the vector index. `nomic-embed-text` produces 768 dimensions and will not work. Use `mxbai-embed-large` (1024-dim) or configure a compatible model that matches your index. |
| **Git** (optional) | latest | `winget install Git.Git` — needed for git hooks and incremental ingest |

---

## Installation

### Option A — Standalone installer (no package manager needed)

Open **PowerShell 7** and run:

```powershell
irm https://raw.githubusercontent.com/reh3376/mdemg-windows/main/Install-MDEMG.ps1 | iex
```

This will:
- Check prerequisites (Docker, Python, Git)
- Download the MDEMG CLI binary from GitHub releases
- Add `mdemg` to your user PATH
- Set up tab-completion in your PowerShell profile

### Option B — Scoop (recommended if you use Scoop)

```powershell
scoop bucket add mdemg https://github.com/reh3376/mdemg-windows
scoop install mdemg
```

### Option C — Manual

```powershell
# Download latest release
$tag = (Invoke-RestMethod https://api.github.com/repos/reh3376/mdemg/releases/latest).tag_name
Invoke-WebRequest "https://github.com/reh3376/mdemg/releases/download/$tag/mdemg_$($tag.TrimStart('v'))_windows_amd64.zip" -OutFile mdemg.zip
Expand-Archive mdemg.zip -DestinationPath "$HOME\mdemg"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$HOME\mdemg", "User")

# Verify
mdemg version
```

---

## Quick Start

### Option A: One command

```powershell
$env:OPENAI_API_KEY = "sk-..."
mdemg init --quick
```

Creates config, starts Neo4j, starts the server, applies migrations, and confirms readiness.

### Option B: Step by step

```powershell
mdemg init                    # Interactive wizard
mdemg db start                # Start Neo4j container
mdemg start --auto-migrate    # Start server (background daemon)
mdemg status                  # Verify everything is running
mdemg ingest --path .         # Ingest your codebase
```

> **Note:** If `mdemg start` does not work as expected on your system, use `mdemg serve --auto-migrate` in a separate PowerShell window to run the server in the foreground instead.

---

## Commands

| Command | Description |
|---------|-------------|
| `mdemg init` | Interactive setup wizard (`--defaults` / `--quick`) |
| `mdemg version` | Print version, platform, build info |
| `mdemg start` | Start server in background (daemon mode) |
| `mdemg stop` | Stop the running server |
| `mdemg restart` | Restart the server |
| `mdemg status` | Show server, database, and embedding status |
| `mdemg serve` | Run server in foreground (recommended for Windows) |
| `mdemg db start` | Start Neo4j container |
| `mdemg db stop` | Stop Neo4j container (`--remove` to delete) |
| `mdemg db status` | Show container and schema status |
| `mdemg db migrate` | Apply pending schema migrations |
| `mdemg db shell` | Open interactive cypher-shell |
| `mdemg db backup` | Trigger or list backups |
| `mdemg ingest --path .` | Ingest a codebase into the knowledge graph |
| `mdemg watch --path .` | Watch a directory and auto-ingest on changes |
| `mdemg extract-symbols` | Extract code symbols from a codebase |
| `mdemg consolidate` | Run hidden layer clustering |
| `mdemg decay` | Apply temporal decay to learning edges |
| `mdemg prune` | Prune weak edges, tombstone orphans |
| `mdemg embeddings check` | Verify embedding provider connectivity |
| `mdemg config show` | Display effective configuration |
| `mdemg config validate` | Validate config and probe connectivity |
| `mdemg config set-secret K V` | Store secret in Windows Credential Manager |
| `mdemg config get-secret K` | Retrieve a secret from Windows Credential Manager |
| `mdemg config list-secrets` | List known secrets and their keychain status |
| `mdemg hooks install` | Install git post-commit hook |
| `mdemg mcp` | Run MCP server for IDE integration |
| `mdemg sidecar` | Sidecar lifecycle management (up, down, attach, detach) |
| `mdemg plugin` | Manage MDEMG plugins |
| `mdemg space` | Manage spaces (list, export, import, copy, delete, rename, info) |
| `mdemg demo` | Run interactive demo |
| `mdemg menubar` | Manage menu bar companion app (macOS only) |
| `mdemg upgrade` | Self-update to latest release |
| `mdemg teardown` | Remove all MDEMG artifacts (`--dry-run`, `--export`, `--keep-data`, `--full`) |

For complete flag details, see the [CLI Reference](https://github.com/reh3376/mdemg/blob/main/docs/user/cli-reference.md).

---

## Documentation

| Guide | What it covers |
|-------|---------------|
| [CLI Reference](https://github.com/reh3376/mdemg/blob/main/docs/user/cli-reference.md) | All commands, flags, defaults, examples, environment variables |
| [API Reference](https://github.com/reh3376/mdemg/blob/main/docs/user/api-reference.md) | Every HTTP endpoint with request/response shapes and curl examples |
| [CMS & RSIC Guide](https://github.com/reh3376/mdemg/blob/main/docs/user/cms-rsic-guide.md) | Conversation memory, observation types, surprise scoring, self-improvement |
| [Ingestion Guide](https://github.com/reh3376/mdemg/blob/main/docs/user/ingestion-guide.md) | All 8 ingestion methods — codebase, scraper, Linear, webhooks, file watcher, API |

All documentation includes cross-platform examples (bash, PowerShell) with platform-specific subsections.

---

## Configuration

Priority chain (lowest to highest):

```
defaults → %USERPROFILE%\.mdemg\config.yaml → Credential Manager → .env → environment variables → CLI flags
```

### Secrets

Use `.env` in your project root (gitignored) or Windows Credential Manager:

```powershell
# .env file (recommended for development)
OPENAI_API_KEY=sk-...
NEO4J_PASS=your-password

# Or Windows Credential Manager (for production / shared machines)
mdemg config set-secret OPENAI_API_KEY sk-...
```

### View effective config

```powershell
mdemg config show
mdemg config validate
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `mdemg` not found after install | Restart terminal; or run `$env:PATH += ";$HOME\mdemg"` |
| Docker not running | Start Docker Desktop from the taskbar |
| Neo4j port conflict | `mdemg db start --port 7688` |
| Missing OpenAI key | Add `OPENAI_API_KEY=sk-...` to `.env` |
| Neo4j won't start | `docker logs mdemg-neo4j-<folder-name>` |
| Server won't start | `Get-Content "$HOME\.mdemg\logs\mdemg.log"` |
| Embedding check fails | `mdemg embeddings check` — verify key and model in config |
| Script execution policy | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

---

## Upgrading

```powershell
# Option A — PowerShell installer (recommended)
.\Install-MDEMG.ps1 -Upgrade

# Option B — Scoop
scoop update mdemg

# Option C — mdemg self-update
mdemg upgrade

# After upgrading, apply any new migrations
mdemg start --auto-migrate
```

> **Note:** `mdemg upgrade` downloads and installs the latest release directly from GitHub.

## Uninstall

### Quick Teardown (recommended)

```powershell
# Remove all instance artifacts (stops server, cleans hooks, IDE configs, etc.)
mdemg teardown --yes

# Then remove the binary and PATH entry
.\Install-MDEMG.ps1 -Uninstall
```

### Full System Removal

```powershell
# Remove everything including binary, plugins, completions
mdemg teardown --full --yes

# Or step by step:
mdemg teardown --yes                    # Instance artifacts
mdemg db stop --remove                  # Remove Neo4j container
docker volume ls -q --filter name=mdemg | ForEach-Object { docker volume rm $_ }
.\Install-MDEMG.ps1 -Uninstall         # Binary and PATH
Remove-Item "$HOME\.mdemg" -Recurse -Force   # Config and data
```

> **Note:** `mdemg teardown` creates a backup of `.mdemg/` before removal. Use `--export` to also export CMS data, or `--keep-data` to preserve the Neo4j volume.
> Use `mdemg teardown --dry-run` to preview what would be removed without executing.

---

## macOS equivalent reference

| macOS (Homebrew) | Windows (PowerShell) |
|------------------|---------------------|
| `brew tap reh3376/mdemg` | `scoop bucket add mdemg ...` or `.\Install-MDEMG.ps1` |
| `brew install mdemg` | `scoop install mdemg` or `.\Install-MDEMG.ps1` |
| `brew upgrade mdemg` | `mdemg upgrade` or `scoop update mdemg` |
| `brew uninstall mdemg` | `.\Install-MDEMG.ps1 -Uninstall` or `scoop uninstall mdemg` |
| `~/.mdemg/config.yaml` | `%USERPROFILE%\.mdemg\config.yaml` |
| keychain secrets | Windows Credential Manager via `mdemg config set-secret` |

---

## Links

- [Source Code (MDEMG)](https://github.com/reh3376/mdemg)
- [macOS Homebrew tap](https://github.com/reh3376/homebrew-mdemg)
- [Windows Beta Testing Guide](mdemg_beta_testing.md)
- [Issues](https://github.com/reh3376/mdemg/issues)
