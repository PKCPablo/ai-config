#!/usr/bin/env bash
#
# AI-Config Installer Script
# Creates symbolic links from a target project to the ai-config repository
# Conservative approach: never overwrites existing files by default
#

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
REPO_PATH=""
AI_CONFIG_PATH=""
DRY_RUN=false
FORCE=false

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install ai-config into a target project using symlinks.
Conservative by default - will not overwrite existing files.

OPTIONS:
    -r, --repo PATH         Target repository path (default: current directory)
    -c, --config PATH       Path to ai-config repository (default: script directory)
    -d, --dry-run           Show what would be done without making changes
    -f, --force             Force refresh of existing symlinks
    -h, --help              Show this help message

EXAMPLES:
    ./install.sh --repo /path/to/my-project --dry-run
    ./install.sh --repo /path/to/my-project
    ./install.sh --repo /path/to/my-project --force
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO_PATH="$2"
            shift 2
            ;;
        -c|--config)
            AI_CONFIG_PATH="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Helper functions
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }
dryrun() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

# Determine ai-config path
if [[ -z "$AI_CONFIG_PATH" ]]; then
    AI_CONFIG_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
AI_CONFIG_PATH="$(cd "$AI_CONFIG_PATH" && pwd)"

# Determine repo path
if [[ -z "$REPO_PATH" ]]; then
    REPO_PATH="$(pwd)"
else
    REPO_PATH="$(cd "$REPO_PATH" && pwd)"
fi

echo ""
echo "=== AI-Config Installer ==="
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

echo "ai-config path: $AI_CONFIG_PATH"
echo "Target repo:    $REPO_PATH"
echo ""

# Verify ai-config structure exists
required_paths=(
    "opencode.jsonc"
    ".opencode/agents"
    ".opencode/commands"
    ".opencode/skills"
    "templates/AGENTS.md"
)

valid_config=true
for req in "${required_paths[@]}"; do
    if [[ ! -e "$AI_CONFIG_PATH/$req" ]]; then
        error "Missing required path: $req"
        valid_config=false
    fi
done

if [[ "$valid_config" == false ]]; then
    error "Invalid ai-config repository structure"
    exit 1
fi

# Define symlinks to create
declare -a links=(
    "opencode.jsonc:opencode.jsonc:file"
    ".opencode/agents:.opencode/agents:dir"
    ".opencode/commands:.opencode/commands:dir"
    ".opencode/skills:.opencode/skills:dir"
    "templates/AGENTS.md:AGENTS.md:file"
)

# Track results
declare -a created=()
declare -a skipped=()
declare -a refreshed=()
declare -a conflicts=()
declare -a errors=()

for link in "${links[@]}"; do
    IFS=':' read -r source target type <<< "$link"
    source_path="$AI_CONFIG_PATH/$source"
    target_path="$REPO_PATH/$target"

    # Ensure parent directory exists (always safe to create empty dirs)
    parent_dir=$(dirname "$target_path")
    if [[ ! -d "$parent_dir" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            dryrun "Would create directory: $parent_dir"
        else
            mkdir -p "$parent_dir"
            info "Created directory: $parent_dir"
        fi
    fi

    # Check what exists at target path
    if [[ -e "$target_path" ]] || [[ -L "$target_path" ]]; then
        if [[ -L "$target_path" ]]; then
            # It's a symlink
            if [[ "$FORCE" == true ]]; then
                # Refresh the symlink
                if [[ "$DRY_RUN" == true ]]; then
                    dryrun "Would refresh symlink: $target"
                    refreshed+=("$target")
                else
                    if rm "$target_path" && ln -s "$source_path" "$target_path"; then
                        success "Refreshed symlink: $target -> $source"
                        refreshed+=("$target")
                    else
                        error "Failed to refresh symlink: $target"
                        errors+=("$target")
                    fi
                fi
            else
                # Skip existing symlink
                warning "Skipped existing symlink (use --force to refresh): $target"
                skipped+=("$target")
            fi
        else
            # It's a real file/directory - CONFLICT (never touch these)
            error "CONFLICT - File exists: $target"
            info "  Remove or rename the existing file manually, then re-run"
            conflicts+=("$target")
        fi
    else
        # Nothing exists, safe to create
        if [[ "$DRY_RUN" == true ]]; then
            dryrun "Would create symlink: $target -> $source"
            created+=("$target")
        else
            if ln -s "$source_path" "$target_path"; then
                success "Created symlink: $target -> $source"
                created+=("$target")
            else
                error "Failed to create symlink: $target"
                errors+=("$target")
            fi
        fi
    fi
done

# Summary
echo ""
echo "=== Installation Summary ==="
echo ""

if [[ ${#created[@]} -gt 0 ]]; then
    success "Created: ${#created[@]} symlinks"
fi
if [[ ${#refreshed[@]} -gt 0 ]]; then
    success "Refreshed: ${#refreshed[@]} symlinks"
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
    warning "Skipped: ${#skipped[@]} existing symlinks"
fi
if [[ ${#conflicts[@]} -gt 0 ]]; then
    error "Conflicts: ${#conflicts[@]} files exist (not modified)"
fi
if [[ ${#errors[@]} -gt 0 ]]; then
    error "Errors: ${#errors[@]} failed"
fi

echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}This was a dry run. No changes were made.${NC}"
    echo "Run without --dry-run to apply changes."
elif [[ ${#conflicts[@]} -eq 0 && ${#errors[@]} -eq 0 ]]; then
    success "Installation complete!"
    echo "Your project is now linked to ai-config."
else
    warning "Installation completed with issues."
    echo "Review the conflicts above and re-run after resolving them."
fi

echo ""
