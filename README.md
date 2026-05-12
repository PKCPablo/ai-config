# ai-config

Configuration files and settings for AI tools and agents.

## Description

This repository contains configuration files, prompts, and settings for various AI tools and workflows. It can be installed into other projects using symbolic links (symlinks), allowing you to maintain a single source of truth for your AI configurations across multiple projects.

**Conservative by design**: The installer never overwrites existing files. It only creates symlinks where nothing exists, and skips everything else.

## Repository Structure

```
ai-config/
├── .opencode/
│   ├── agents/          # AI agent definitions
│   ├── commands/        # Custom commands
│   └── skills/          # Skill definitions
├── templates/
│   └── AGENTS.md        # Template for project-specific agent configuration
├── opencode.jsonc       # OpenCode configuration file
├── install.ps1          # Windows installation script
├── install.sh           # Linux/Mac installation script
├── uninstall.ps1        # Windows uninstallation script
└── uninstall.sh         # Linux/Mac uninstallation script
```

## Installation

### Prerequisites

- **Windows**: PowerShell with Administrator privileges
- **Linux/Mac**: Bash shell

### Quick Start

```bash
# Clone the repository
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config

# Preview what will be installed (dry-run)
./install.sh --repo /path/to/your/project --dry-run

# Install
./install.sh --repo /path/to/your/project
```

### Windows

```powershell
# Preview what will be installed (dry-run)
.\install.ps1 --repo "C:\path\to\your\project" --dry-run

# Install
.\install.ps1 --repo "C:\path\to\your\project"

# Or install in the current directory
.\install.ps1
```

### Linux/Mac

```bash
# Preview what will be installed (dry-run)
./install.sh --repo /path/to/your/project --dry-run

# Install
./install.sh --repo /path/to/your/project

# Or install in the current directory
./install.sh
```

## Command Options

### Install Script

```bash
./install.sh [OPTIONS]

OPTIONS:
    -r, --repo PATH         Target repository path (default: current directory)
    -c, --config PATH       Path to ai-config repository (default: script directory)
    -d, --dry-run           Show what would be done without making changes
    -f, --force             Force refresh of existing symlinks
    -h, --help              Show help message
```

### Examples

```bash
# Dry-run to preview changes
./install.sh --repo ../my-project --dry-run

# Normal install (skips existing files)
./install.sh --repo ../my-project

# Force refresh existing symlinks
./install.sh --repo ../my-project --force
```

## What Gets Installed

The installer creates the following symbolic links in your target project:

| Target Project | Links To |
|---------------|----------|
| `opencode.jsonc` | `ai-config/opencode.jsonc` |
| `.opencode/agents/` | `ai-config/.opencode/agents/` |
| `.opencode/commands/` | `ai-config/.opencode/commands/` |
| `.opencode/skills/` | `ai-config/.opencode/skills/` |
| `AGENTS.md` | `ai-config/templates/AGENTS.md` |

## Behavior

### Conservative by Default

The installer follows these rules:

1. **If nothing exists**: Creates the symlink ✓
2. **If a symlink already exists**: Skips (use `--force` to refresh) ⚠
3. **If a real file exists**: Reports as CONFLICT and skips ✗

### Why This Approach?

- **Safety**: Never accidentally overwrite your work
- **Transparency**: You know exactly what happened
- **Control**: You decide when to replace existing files
- **Reversible**: Easy to undo with `--dry-run` preview

## Resolving Conflicts

If the installer reports conflicts:

```
✗ CONFLICT - File exists: AGENTS.md
ℹ   Remove or rename the existing file manually, then re-run
```

Options:
1. **Rename your file**: `mv AGENTS.md AGENTS.md.local`
2. **Remove your file**: `rm AGENTS.md` (if you don't need it)
3. **Merge manually**: Compare and merge the files yourself

Then re-run the installer.

## Uninstallation

To remove ai-config from a project:

### Windows
```powershell
# Preview
.\uninstall.ps1 --repo "C:\path\to\your\project" --dry-run

# Remove
.\uninstall.ps1 --repo "C:\path\to\your\project"
```

### Linux/Mac
```bash
# Preview
./uninstall.sh --repo /path/to/your/project --dry-run

# Remove
./uninstall.sh --repo /path/to/your/project
```

## Customization

After installation, you can customize:

1. **AGENTS.md**: Edit the `templates/AGENTS.md` file in this repository and all linked projects will see the changes
2. **opencode.jsonc**: Modify the main configuration file
3. **Add agents/skills**: Place new files in `.opencode/agents/` or `.opencode/skills/`

## Updating

To update configurations across all projects:

1. Make changes to files in this repository
2. Commit and push the changes
3. All linked projects will automatically use the updated configurations

```bash
git add .
git commit -m "Update AI configurations"
git push
```

If you need to refresh symlinks in a project (e.g., after pulling updates):

```bash
./install.sh --repo /path/to/project --force
```

## Troubleshooting

### "Access Denied" on Windows
Run PowerShell as Administrator (right-click → "Run as Administrator")

### Symlinks already exist but point to wrong location
Use `--force` to refresh them:
```bash
./install.sh --repo /path/to/project --force
```

### Changes not reflected
Make sure the ai-config repository is up to date:
```bash
git pull
```

## Benefits

- **Single Source of Truth**: Update configurations in one place, all projects get the changes
- **Version Control**: Track changes to your AI configurations
- **Easy Setup**: One command to set up AI tools in any project
- **Conservative**: Never overwrites existing files
- **Transparent**: `--dry-run` shows exactly what will happen

## License

MIT
