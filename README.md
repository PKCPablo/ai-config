# ai-config

OpenCode configuration and multi-agent orchestration system for AI-assisted development. Installed via symlinks into target projects.

## Overview

ai-config provides a sophisticated multi-agent development workflow built for OpenCode and Kimi K2.5. It includes four specialized agents and a staged delivery system for complex development tasks.

## Quick Start

```powershell
# 1. Clone the repository
git clone https://github.com/PKCPablo/ai-config.git
cd ai-config

# 2. Configure environment (one-time setup)
.\install\setup-environment.ps1

# 3. Install in your project
.\install\install.ps1 --repo "C:\path\to\project"
```

## What Gets Linked

When you install ai-config in a project, these symlinks are created:

| In Your Project | Points To |
|-----------------|-----------|
| `<your-project>/opencode.jsonc` | `ai-config/opencode.jsonc` |
| `<your-project>/.opencode/agents/` | `ai-config/.opencode/agents/` |
| `<your-project>/.opencode/commands/` | `ai-config/.opencode/commands/` |
| `<your-project>/.opencode/skills/` | `ai-config/.opencode/skills/` |
| `<your-project>/AGENTS.md` | `ai-config/templates/AGENTS.md` |

## Multi-Agent System

### Available Agents

| Agent | Mode | Description |
|-------|------|-------------|
| **planner** | Primary | Orchestrates complex tasks by coordinating other agents |
| **research** | Subagent | Investigates requirements and searches the codebase |
| **code** | Subagent | Implements features and writes code |
| **test** | Subagent | Creates and runs tests to verify functionality |

### Agent Workflow

```
User Request → Planner → @research → @code → @test → Results
```

1. **Research Phase**: Planner invokes `@research` to gather information
2. **Code Phase**: Planner invokes `@code` to implement the feature
3. **Test Phase**: Planner invokes `@test` to verify implementation
4. **Synthesis**: Planner compiles results for the user

## OpenCode Commands

After installation, these commands become available:

| Command | Description |
|---------|-------------|
| `@plan` | Start a progressive-disclosure planning conversation |
| `@onboard-repo` | Onboard an existing repository |
| `@implement-phase` | Execute the next approved implementation phase |
| `@review-phase` | Review the current phase and decide on next steps |
| `@close` | Complete the current task and update documentation |

## Staged Delivery Workflow

The default conservative workflow ensures quality:

1. **Onboard** unfamiliar repositories through `research`
2. **Plan** with clarifying questions and acceptance criteria
3. **Implement** one approved phase through `code`
4. **Pause** after each atomic stage for manual validation
5. **Review** completed phase with git evidence
6. **Test** only when useful
7. **Update** docs and memory at close

### Example Usage

Simply work on complex tasks in a project with ai-config installed:

```
User: Implement JWT authentication for the API

Planner: Starting research phase...
  → @research: "Investigate current auth patterns and JWT libraries"

Research: Found Spring Security setup. Recommend using jjwt library.

Planner: Research complete. Starting implementation...
  → @code: "Implement JWT auth with jjwt"

Code: Created JwtUtil.java, JwtFilter.java, AuthController.java
      Build successful.

Planner: Implementation complete. Starting testing...
  → @test: "Create unit and integration tests"

Test: Created JwtUtilTest.java, AuthControllerTest.java
      All tests passing (8/8)

Planner: ✅ Task complete. Summary:
  - JWT authentication implemented
  - 3 new files created
  - 8 tests created and passing
```

## AI Memory System

Projects using ai-config maintain durable memory under `docs/ai/`:

| Document | Purpose |
|----------|---------|
| `README.md` | Index of AI memory documents |
| `architecture.md` | Architecture, boundaries, and invariants |
| `decisions/` | Architecture Decision Records (ADRs) |
| `plans/` | Approved implementation plans |
| `logs/` | Monthly change summaries |

## Installation Scripts

Located in the `install/` directory:

| Script | Purpose |
|--------|---------|
| `install.ps1` | Install ai-config into a target project |
| `uninstall.ps1` | Remove ai-config from a project |
| `update.ps1` | Verify integrity and update all projects |
| `setup-environment.ps1` | Configure environment variables |

### install.ps1 Options

```powershell
.\install\install.ps1 --repo PATH      # Target project (default: current dir)
.\install\install.ps1 --dry-run        # Preview only
.\install\install.ps1 --force          # Refresh existing symlinks
```

**Behavior:**
- **Empty path**: Creates symlink ✓
- **Symlink exists**: Skipped (use `--force` to refresh) ⚠
- **Regular file exists**: Reported as CONFLICT, not touched ✗
- **Error occurs**: Interactive prompt (Retry/Skip/Abort) ❓

### Managing Multiple Projects

```powershell
# Update and verify all registered projects
.\install\update.ps1

# Preview only
.\install\update.ps1 --dry-run

# Auto-repair without prompting
.\install\update.ps1 --yes
```

## Configuration

### Environment Variables

Configure once per machine via `setup-environment.ps1`:

- `KIMI_API_KEY` - Your API key
- `KIMI_BASE_URL` - Base URL for Kimi API
- `KIMI_API_VERSION` - API version

### OpenCode Configuration

The `opencode.jsonc` file configures:
- **Provider**: Kimi 2.5 via Azure
- **Model**: kimi25/Kimi-K2.5
- **Default Agent**: planner
- **MCP**: IntelliJ integration

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for creating symlinks)
- Git (for update functionality)

## Uninstall

```powershell
# Preview
.\install\uninstall.ps1 --repo "C:\path\to\project" --dry-run

# Remove
.\install\uninstall.ps1 --repo "C:\path\to\project"
```

**Note:** Only removes symlinks, never touches regular files.

## License

MIT
