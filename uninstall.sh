#!/usr/bin/env bash
#
# AI-Config Uninstaller Script
# Removes symbolic links created by install.sh
#

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
TARGET_PATH="."

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Uninstall ai-config from a target project.

OPTIONS:
    -t, --target PATH       Target project path (default: current directory)
    -h, --help              Show this help message
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_PATH="$2"
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

# Resolve absolute path
TARGET_PATH="$(cd "$TARGET_PATH" && pwd)"

echo ""
echo "=== AI-Config Uninstaller ==="
echo ""
echo "Target path: $TARGET_PATH"
echo ""

# Links to remove
links=(
    "opencode.jsonc"
    ".opencode/agents"
    ".opencode/commands"
    ".opencode/skills"
    "AGENTS.md"
)

success_count=0
not_found_count=0

for link in "${links[@]}"; do
    target_path="$TARGET_PATH/$link"

    if [[ -L "$target_path" ]]; then
        rm "$target_path"
        success "Removed symlink: $link"
        ((success_count++))
    elif [[ -e "$target_path" ]]; then
        warning "Not a symlink (skipping): $link"
    else
        ((not_found_count++))
    fi
done

# Clean up empty .opencode directory if it exists
openCodePath="$TARGET_PATH/.opencode"
if [[ -d "$openCodePath" ]] && [[ -z "$(ls -A "$openCodePath" 2>/dev/null)" ]]; then
    rmdir "$openCodePath"
    success "Removed empty directory: .opencode"
fi

echo ""
echo "=== Uninstallation Summary ==="
echo ""
success "Removed $success_count symlinks"
if [[ $not_found_count -gt 0 ]]; then
    warning "$not_found_count links not found"
fi
echo ""
echo "ai-config has been uninstalled from this project."
echo ""
