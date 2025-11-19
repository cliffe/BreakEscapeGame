#!/bin/bash
# Compile all .ink files in scenarios/ink to JSON
# Usage: ./scripts/compile-ink.sh

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths
INK_DIR="$PROJECT_ROOT/scenarios/ink"
INKLECATE="$PROJECT_ROOT/bin/inklecate"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if inklecate exists
if [ ! -f "$INKLECATE" ]; then
    echo -e "${RED}Error: inklecate not found at $INKLECATE${NC}"
    exit 1
fi

# Check if ink directory exists
if [ ! -d "$INK_DIR" ]; then
    echo -e "${RED}Error: Ink directory not found at $INK_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Compiling ink files in $INK_DIR${NC}"
echo "----------------------------------------"

# Counter for compiled files
compiled=0
failed=0

# Iterate through all .ink files
for ink_file in "$INK_DIR"/*.ink; do
    # Check if any .ink files exist
    [ -e "$ink_file" ] || continue

    # Get the filename without path
    filename=$(basename "$ink_file")

    # Get output JSON filename
    json_file="${ink_file%.ink}.json"

    echo -e "${YELLOW}Compiling: $filename${NC}"

    # Compile the ink file
    if "$INKLECATE" -o "$json_file" "$ink_file"; then
        echo -e "${GREEN}✓ Success: $filename -> $(basename "$json_file")${NC}"
        ((compiled++))
    else
        echo -e "${RED}✗ Failed: $filename${NC}"
        ((failed++))
    fi

    echo ""
done

# Summary
echo "----------------------------------------"
echo -e "${GREEN}Compilation complete!${NC}"
echo "  Compiled: $compiled files"
if [ $failed -gt 0 ]; then
    echo -e "  ${RED}Failed: $failed files${NC}"
else
    echo "  Failed: 0 files"
fi
