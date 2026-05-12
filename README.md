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
.\install.ps1 --repo "C:\path\to\project" --dry-run

# Install
.\install.ps1 --repo "C:\path\to\project"
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
.\install.ps1 --repo PATH      # Target project (default: current dir)
.\install.ps1 --dry-run        # Preview only
.\install.ps1 --force          # Refresh existing symlinks
```

## Behavior

- **If path is empty**: Creates symlink ✓
- **If symlink exists**: Skipped (use `--force` to refresh) ⚠
- **If file exists**: Reported as CONFLICT, not touched ✗

## Managing Multiple Projects

When you install ai-config, the project is automatically registered in `installed-projects.md` (local file, not versioned).

### List installed projects

```powershell
.\list.ps1
```

### Update all projects

```powershell
# Pull latest ai-config and refresh all projects
.\update.ps1

# Preview what would be updated
.\update.ps1 --dry-run
```

If a project no longer exists, the updater will ask if you want to:
- **[E]** Eliminar from the list
- **[D]** Detener the script
- **[S]** Saltar (keep in list)

## Uninstall

```powershell
# Preview
.\uninstall.ps1 --repo "C:\path\to\project" --dry-run

# Remove
.\uninstall.ps1 --repo "C:\path\to\project"
```

## License

MIT
