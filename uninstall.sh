#!/usr/bin/env bash
#
# AI-Config Uninstaller Script
# Removes symbolic links created by install.sh
#

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
REPO_PATH=""
DRY_RUN=false

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Uninstall ai-config from a target project.

OPTIONS:
    -r, --repo PATH         Target repository path (default: current directory)
    -d, --dry-run           Show what would be done without making changes
    -h, --help              Show this help message
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO_PATH="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
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
info() { echo -e "${CYAN}ℹ${NC} $1"; }
dryrun() { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

# Determine repo path
if [[ -z "$REPO_PATH" ]]; then
    REPO_PATH="$(pwd)"
else
    REPO_PATH="$(cd "$REPO_PATH" && pwd)"
fi

echo ""
echo "=== AI-Config Uninstaller ==="
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

echo "Target repo: $REPO_PATH"
echo ""

# Links to remove
links=(
    "opencode.jsonc"
    ".opencode/agents"
    ".opencode/commands"
    ".opencode/skills"
    "AGENTS.md"
)

# Track results
declare -a removed=()
declare -a not_found=()
declare -a skipped=()

for link in "${links[@]}"; do
    target_path="$REPO_PATH/$link"

    if [[ -L "$target_path" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            dryrun "Would remove symlink: $link"
            removed+=("$link")
        else
            rm "$target_path"
            success "Removed symlink: $link"
            removed+=("$link")
        fi
    elif [[ -e "$target_path" ]]; then
        warning "Not a symlink (skipping): $link"
        skipped+=("$link")
    else
        not_found+=("$link")
    fi
done

# Clean up empty .opencode directory if it exists
openCodePath="$REPO_PATH/.opencode"
if [[ -d "$openCodePath" ]] && [[ -z "$(ls -A "$openCodePath" 2>/dev/null)" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        dryrun "Would remove empty directory: .opencode"
    else
        rmdir "$openCodePath"
        success "Removed empty directory: .opencode"
    fi
fi

echo ""
echo "=== Uninstallation Summary ==="
echo ""

if [[ ${#removed[@]} -gt 0 ]]; then
    success "Removed: ${#removed[@]} symlinks"
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
    warning "Skipped: ${#skipped[@]} non-symlinks"
fi
if [[ ${#not_found[@]} -gt 0 ]]; then
    info "Not found: ${#not_found[@]} links"
fi

echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}This was a dry run. No changes were made.${NC}"
else
    echo "ai-config has been uninstalled from this project."
fi

echo ""
