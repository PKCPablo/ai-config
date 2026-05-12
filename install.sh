#!/usr/bin/env bash
#
# AI-Config Installer Script
# Creates symbolic links from a target project to the ai-config repository
#

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
TARGET_PATH="."
AI_CONFIG_PATH=""

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install ai-config into a target project using symlinks.

OPTIONS:
    -t, --target PATH       Target project path (default: current directory)
    -c, --config PATH       Path to ai-config repository (default: script directory)
    -h, --help              Show this help message

EXAMPLES:
    ./install.sh -t /path/to/my-project
    ./install.sh --target ./my-project --config /path/to/ai-config
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_PATH="$2"
            shift 2
            ;;
        -c|--config)
            AI_CONFIG_PATH="$2"
            shift 2
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

# Determine ai-config path
if [[ -z "$AI_CONFIG_PATH" ]]; then
    AI_CONFIG_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Resolve absolute paths
TARGET_PATH="$(cd "$TARGET_PATH" && pwd)"
AI_CONFIG_PATH="$(cd "$AI_CONFIG_PATH" && pwd)"

echo ""
echo "=== AI-Config Installer ==="
echo ""
echo "ai-config path: $AI_CONFIG_PATH"
echo "Target path:    $TARGET_PATH"
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

# Create symlinks
declare -a links=(
    "opencode.jsonc:opencode.jsonc:file"
    ".opencode/agents:.opencode/agents:dir"
    ".opencode/commands:.opencode/commands:dir"
    ".opencode/skills:.opencode/skills:dir"
    "templates/AGENTS.md:AGENTS.md:file"
)

success_count=0
warning_count=0

for link in "${links[@]}"; do
    IFS=':' read -r source target type <<< "$link"
    source_path="$AI_CONFIG_PATH/$source"
    target_path="$TARGET_PATH/$target"

    # Ensure parent directory exists
    parent_dir=$(dirname "$target_path")
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
        success "Created directory: $parent_dir"
    fi

    # Remove existing file/directory if it exists
    if [[ -e "$target_path" ]] || [[ -L "$target_path" ]]; then
        if [[ -L "$target_path" ]]; then
            rm "$target_path"
            warning "Removed existing symlink: $target"
        else
            backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
            mv "$target_path" "$backup_path"
            warning "Backed up existing file: $target -> $backup_path"
        fi
    fi

    # Create the symlink
    if ln -s "$source_path" "$target_path"; then
        success "Created symlink: $target -> $source"
        ((success_count++))
    else
        error "Failed to create symlink: $target"
    fi
done

echo ""
echo "=== Installation Summary ==="
echo ""
success "Successfully created $success_count/${#links[@]} symlinks"
if [[ $warning_count -gt 0 ]]; then
    warning "$warning_count warnings"
fi
echo ""
echo "Your project is now linked to ai-config!"
echo "Any changes in ai-config will be reflected in this project."
echo ""
