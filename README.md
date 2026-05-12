# ai-config

Configuration files and settings for AI tools and agents.

## Description

This repository contains configuration files, prompts, and settings for various AI tools and workflows. It can be installed into other projects using symbolic links (symlinks), allowing you to maintain a single source of truth for your AI configurations across multiple projects.

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

### Windows

1. Clone this repository:
```powershell
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
```

2. Run the installer from an elevated (Administrator) PowerShell:
```powershell
.\install.ps1 -TargetPath "C:\path\to\your\project"
```

Or to install in the current directory:
```powershell
.\install.ps1
```

### Linux/Mac

1. Clone this repository:
```bash
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
```

2. Run the installer:
```bash
chmod +x install.sh
./install.sh -t /path/to/your/project
```

Or to install in the current directory:
```bash
./install.sh
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

## Benefits

- **Single Source of Truth**: Update configurations in one place, all projects get the changes
- **Version Control**: Track changes to your AI configurations
- **Easy Setup**: One command to set up AI tools in any project
- **Backup Protection**: Existing files are automatically backed up before creating symlinks

## Uninstallation

To remove ai-config from a project:

### Windows
```powershell
.\uninstall.ps1 -TargetPath "C:\path\to\your\project"
```

### Linux/Mac
```bash
./uninstall.sh -t /path/to/your/project
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

## Troubleshooting

### "Access Denied" on Windows
Run PowerShell as Administrator (right-click → "Run as Administrator")

### Symlinks already exist
The installer will automatically remove existing symlinks and back up any regular files before creating new symlinks.

### Changes not reflected
Make sure the ai-config repository is up to date:
```bash
git pull
```

## License

MIT
