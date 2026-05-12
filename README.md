# ai-config

Configuration files and settings for AI tools and agents. Installed via symlinks into target projects.

## Installation

```powershell
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
```

### Quick Start

```powershell
# Preview changes
.\install\install.ps1 --repo "C:\path\to\project" --dry-run

# Install
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

## Options

```powershell
.\install\install.ps1 --repo PATH      # Target project (default: current dir)
.\install\install.ps1 --dry-run        # Preview only
.\install\install.ps1 --force          # Refresh existing symlinks
```

## Behavior

- **If path is empty**: Creates symlink ✓
- **If symlink exists**: Skipped (use `--force` to refresh) ⚠
- **If file exists**: Reported as CONFLICT, not touched ✗

## Managing Multiple Projects

When you install ai-config, the project is automatically registered in `installed-projects.md` (local file, not versioned).

### Setup Environment (First Time)

Configure your API keys and global OpenCode settings:

```powershell
.\install\setup-environment.ps1
```

This will:
- Set environment variables (`KIMI_API_KEY`, `KIMI_BASE_URL`, `KIMI_API_VERSION`)
- Create a symlink to `opencode.jsonc` in your user config directory

### List installed projects

```powershell
.\install\list.ps1
```

### Update all projects

```powershell
# Pull latest ai-config and refresh all projects
.\install\update.ps1

# Preview what would be updated
.\install\update.ps1 --dry-run
```

If a project no longer exists, the updater will ask if you want to:
- **[E]** Eliminar from the list
- **[D]** Detener the script
- **[S]** Saltar (keep in list)

## Uninstall

```powershell
# Preview
.\install\uninstall.ps1 --repo "C:\path\to\project" --dry-run

# Remove
.\install\uninstall.ps1 --repo "C:\path\to\project"
```

## License

MIT

## Install Scripts

All installation and management scripts are located in the `install/` directory:

| Script | Purpose |
|--------|---------|
| `install.ps1` | Install ai-config into a target project |
| `uninstall.ps1` | Remove ai-config from a project |
| `update.ps1` | Update ai-config and refresh all registered projects |
| `list.ps1` | List all projects with ai-config installed |
| `setup-environment.ps1` | Configure environment variables and global settings |
