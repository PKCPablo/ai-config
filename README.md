# ai-config

Configuration files and settings for AI tools and agents. Installed via symlinks into target projects.

## Installation

```powershell
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
```

### Setup Environment (First Time)

Configure your API keys before installing in projects:

```powershell
.\install\setup-environment.ps1
```

This will set environment variables permanently (`KIMI_API_KEY`, `KIMI_BASE_URL`, `KIMI_API_VERSION`).

### Quick Start

```powershell
# Preview changes
.\install\install.ps1 --repo "C:\path\to\project" --dry-run

# Install (requires Administrator privileges)
.\install\install.ps1 --repo "C:\path\to\project"
```

## What Gets Linked

| Target | Links To |
|--------|----------|
| `opencode.jsonc` | `ai-config/opencode.jsonc` |
| `.opencode/agents/` | `ai-config/.opencode/agents/` |
| `.opencode/commands/` | `ai-config/.opencode/commands/` |
| `.opencode/skills/` | `ai-config/.opencode/skills/` |
| `AGENTS.md` | `ai-config/templates/AGENTS.md` |

## install.ps1 Options

```powershell
.\install\install.ps1 --repo PATH      # Target project (default: current dir)
.\install\install.ps1 --dry-run        # Preview only
.\install\install.ps1 --force          # Refresh existing symlinks (verifies they are symlinks first)
```

### Behavior

- **If path is empty**: Creates symlink ✓
- **If symlink exists**: Skipped (use `--force` to refresh) ⚠
- **If file exists**: Reported as CONFLICT, not touched ✗
- **If error occurs**: Interactive prompt (Retry/Skip/Abort) ❓

**Note:** `--force` will only refresh actual symlinks. If a regular file exists, it will report a conflict.

## Managing Multiple Projects

When you install ai-config, the project is automatically registered in `installed-projects.md` (local file, not versioned).

### Update and Verify All Projects

```powershell
# Pull latest ai-config, verify integrity, and repair issues
.\install\update.ps1

# Only verify integrity (skip git pull)
.\install\update.ps1 --skip-pull

# Preview only (no changes)
.\install\update.ps1 --dry-run

# Auto-repair without prompting
.\install\update.ps1 --yes
```

The updater will:
1. Check all registered projects for missing or invalid symlinks
2. Report any issues found
3. Ask for confirmation before repairing (unless `--yes` is used)
4. Remove projects from the list if their directories no longer exist (with confirmation)

## Uninstall

```powershell
# Preview
.\install\uninstall.ps1 --repo "C:\path\to\project" --dry-run

# Remove
.\install\uninstall.ps1 --repo "C:\path\to\project"
```

**Note:** Only removes symlinks, never touches regular files.

## Install Scripts

All installation and management scripts are located in the `install/` directory:

| Script | Purpose |
|--------|---------|
| `install.ps1` | Install ai-config into a target project (interactive error handling, verifies symlinks with --force) |
| `uninstall.ps1` | Remove ai-config from a project |
| `update.ps1` | Verify integrity of all projects, repair issues, and update from git |
| `setup-environment.ps1` | Configure environment variables (run once per machine) |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for creating symlinks)
- Git (for update functionality)

## License

MIT
