# ai-config

Configuration files and settings for AI tools and agents. Installed via symlinks into target projects.

## Installation

```bash
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
```

### Quick Start

```bash
# Preview changes
./install.sh --repo /path/to/project --dry-run

# Install
./install.sh --repo /path/to/project
```

**Windows:**
```powershell
.\install.ps1 --repo "C:\path\to\project" --dry-run
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

```bash
./install.sh --repo PATH      # Target project (default: current dir)
./install.sh --dry-run        # Preview only
./install.sh --force          # Refresh existing symlinks
./install.sh --config PATH    # Path to ai-config repo
```

## Behavior

- **If path is empty**: Creates symlink ✓
- **If symlink exists**: Skipped (use `--force` to refresh) ⚠
- **If file exists**: Reported as CONFLICT, not touched ✗

## Uninstall

```bash
./uninstall.sh --repo /path/to/project --dry-run
./uninstall.sh --repo /path/to/project
```

## License

MIT
