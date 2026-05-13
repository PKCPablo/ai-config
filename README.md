# ai-config

OpenCode configuration and multi-agent orchestration system for AI-assisted development.

**Purpose:** Provides a structured workflow for the planner agent to coordinate research, code, and test subagents when working on complex development tasks.

---

## For Human Users: Quick Start

```powershell
# 1. Clone and setup
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config
.\install\setup-environment.ps1

# 2. Install in your project
.\install\install.ps1 -Repo "C:\path\to\project"
```

After installation, start working naturally. The planner agent will orchestrate the multi-agent workflow automatically.

---

## System Architecture

### Multi-Agent Workflow

```
User Request → Planner (me) → @research → @code → @test → Results
```

| Agent | Role | When Invoked |
|-------|------|--------------|
| **planner** | Primary orchestrator | Always active - I handle this |
| **research** | Investigates codebase | On unfamiliar repos or complex requirements |
| **code** | Implements features | After plan approval, one phase at a time |
| **test** | Verifies implementation | After code phase completion |

### Staged Delivery Process

1. **Research Phase** - Gather information about existing code
2. **Planning Phase** - Create phased plan with acceptance criteria
3. **Implementation Phase** - Execute one approved phase via @code
4. **Validation Pause** - Stop for manual verification after each atomic stage
5. **Review Phase** - Review with git evidence, decide next steps
6. **Test Phase** - Invoke @test only when meaningful regression risk exists
7. **Documentation Phase** - Update docs/ai memory at task close

---

## Project Structure

```
ai-config/
├── .opencode/
│   ├── agents/          # Agent definitions
│   │   ├── planner.json
│   │   ├── research.json
│   │   ├── code.json
│   │   └── test.json
│   ├── commands/        # OpenCode slash commands
│   │   ├── plan.md
│   │   ├── onboard-repo.md
│   │   ├── implement-phase.md
│   │   ├── review-phase.md
│   │   └── close.md
│   ├── skills/          # Reusable skill definitions
│   ├── package.json     # Dependencies (copied on install)
│   └── .gitignore
├── install/
│   ├── install.ps1      # Install ai-config in target project
│   ├── uninstall.ps1    # Remove ai-config from project
│   ├── update.ps1       # Update and verify all installations
│   └── setup-environment.ps1
├── templates/
│   └── AGENTS.md        # Template for project agent guide
├── docs/ai/             # AI memory (created in target projects)
│   ├── README.md        # Index of memory documents
│   ├── architecture.md  # System boundaries
│   ├── decisions/       # ADRs
│   ├── plans/           # Approved implementation plans
│   └── logs/            # Monthly summaries
├── opencode.jsonc       # OpenCode configuration
└── installed-projects.md # Registry of installations
```

---

## Installation System

### What Gets Linked to Target Projects

| Symlink in Project | Source in ai-config |
|-------------------|---------------------|
| `opencode.jsonc` | `ai-config/opencode.jsonc` |
| `.opencode/agents/` | `ai-config/.opencode/agents/` |
| `.opencode/commands/` | `ai-config/.opencode/commands/` |
| `.opencode/skills/` | `ai-config/.opencode/skills/` |
| `AGENTS.md` | `ai-config/templates/AGENTS.md` |

### Installation Scripts Reference

#### install.ps1
```powershell
.\install\install.ps1 -Repo "C:\path\to\project"    # Install
.\install\install.ps1 -Repo "C:\path" -DryRun      # Preview
.\install\install.ps1 -Repo "C:\path" -Force       # Refresh symlinks
```

**What it does:**
1. Creates 5 symlinks
2. Copies package.json/.gitignore to .opencode/
3. Runs `bun install`
4. Registers in `installed-projects.md`

#### update.ps1
```powershell
.\install\update.ps1              # Update repo + verify all projects
.\install\update.ps1 -DryRun      # Preview only
.\install\update.ps1 -SkipPull    # Skip git pull
.\install\update.ps1 -Yes         # Auto-repair without prompt
```

**What it does:**
1. Performs `git pull` (unless -SkipPull)
2. Reads `installed-projects.md`
3. Verifies all symlinks
4. Reports/repairs issues
5. Cleans up deleted projects

#### uninstall.ps1
```powershell
.\install\uninstall.ps1 -Repo "C:\path\to\project" -DryRun   # Preview
.\install\uninstall.ps1 -Repo "C:\path\to\project"          # Execute
```

**What it removes:**
- All 5 symlinks
- Entire `.opencode/` directory
- Entry from `installed-projects.md`

### Requirements

- **Administrator privileges** (required for symlink creation)
- PowerShell 5.1 or 7+
- Git
- bun (optional, for dependency management)

---

## AI Memory System (docs/ai)

Target projects maintain durable memory here:

| File | Purpose | When Updated |
|------|---------|--------------|
| `README.md` | Index of AI documents | When structure changes |
| `architecture.md` | System boundaries, invariants | When architecture changes |
| `decisions/` | ADRs - Architecture Decision Records | When making significant decisions |
| `plans/` | Approved implementation plans | Before implementation |
| `logs/` | Monthly change summaries | At month close |

**Planner Note:** Always check `docs/ai/` when starting work on a project. Load context in order:
1. `README.md` (index)
2. `architecture.md` (boundaries)
3. `plans/` (active work)
4. `decisions/` (constraints)
5. `logs/` (historical context)

---

## Configuration

### OpenCode Settings (opencode.jsonc)

- **Provider:** Kimi 2.5 via Azure
- **Model:** kimi25/Kimi-K2.5
- **Default Agent:** planner
- **MCP:** IntelliJ integration

### Environment Variables (set via setup-environment.ps1)

- `KIMI_API_KEY` - API authentication
- `KIMI_BASE_URL` - Kimi API endpoint
- `KIMI_API_VERSION` - API version

---

## Project Registry

`installed-projects.md` tracks all installations:

```markdown
# Proyectos con ai-config instalado

| Proyecto | Ruta |
|----------|------|
| my-project | C:\projects\my-project |
```

Used by `update.ps1` to maintain all linked projects.

---

## License

MIT
