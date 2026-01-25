#!/bin/bash
# Validates Linux kernel Kconfig fragment files
# Usage: validate-kconfig.sh <config-file> [--min-configs N]
#
# Valid line formats:
#   CONFIG_OPTION=y
#   CONFIG_OPTION=m
#   CONFIG_OPTION=n
#   CONFIG_OPTION=<number>
#   CONFIG_OPTION="string"
#   # CONFIG_OPTION is not set
#   # comment
#   (empty line)
#
# Options:
#   --min-configs N   Fail if fewer than N CONFIG options are found (default: 3)
#   --check-bitbake   Run bitbake validation checks (requires Yocto environment)

set -euo pipefail

MIN_CONFIGS=3
CHECK_BITBAKE=0
CONFIG_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --min-configs)
            MIN_CONFIGS="$2"
            shift 2
            ;;
        --check-bitbake)
            CHECK_BITBAKE=1
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            CONFIG_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$CONFIG_FILE" ]]; then
    echo "Usage: $0 <config-file> [--min-configs N] [--check-bitbake]"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: File not found: $CONFIG_FILE"
    exit 1
fi

# Valid patterns for Kconfig lines
VALID_PATTERNS=(
    # CONFIG_OPTION=y|m|n
    '^CONFIG_[A-Za-z0-9_]+=[ymn]$'
    # CONFIG_OPTION=<number>
    '^CONFIG_[A-Za-z0-9_]+=[0-9]+$'
    # CONFIG_OPTION=<hex>
    '^CONFIG_[A-Za-z0-9_]+=0x[0-9A-Fa-f]+$'
    # CONFIG_OPTION="string"
    '^CONFIG_[A-Za-z0-9_]+="[^"]*"$'
    # # CONFIG_OPTION is not set
    '^# CONFIG_[A-Za-z0-9_]+ is not set$'
    # Empty line
    '^$'
    # Comment line (starts with #, but not "# CONFIG_")
    '^#([^C]|C[^O]|CO[^N]|CON[^F]|CONF[^I]|CONFI[^G]|CONFIG[^_]).*$'
    # Pure comment with just #
    '^#$'
)

ERRORS=0
LINE_NUM=0

while IFS= read -r line || [[ -n "$line" ]]; do
    LINE_NUM=$((LINE_NUM + 1))
    
    # Check if line matches any valid pattern
    VALID=0
    for pattern in "${VALID_PATTERNS[@]}"; do
        if [[ "$line" =~ $pattern ]]; then
            VALID=1
            break
        fi
    done
    
    if [[ $VALID -eq 0 ]]; then
        echo "Error at line $LINE_NUM: $line"
        ERRORS=$((ERRORS + 1))
    fi
done < "$CONFIG_FILE"

if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo "Found $ERRORS invalid line(s) in $CONFIG_FILE"
    exit 1
fi

# Count CONFIG options
CONFIG_COUNT=$(grep -c "^CONFIG_" "$CONFIG_FILE" || echo 0)
echo ""
echo "=== Config Count Check ==="
echo "Found $CONFIG_COUNT CONFIG options in $CONFIG_FILE"

if [[ $CONFIG_COUNT -le $MIN_CONFIGS ]]; then
    echo "ERROR: Found $CONFIG_COUNT configs, expected more than $MIN_CONFIGS"
    echo "This will result in too few kernel modules being built."
    exit 1
fi

echo "OK: $CONFIG_COUNT configs found (minimum required: >$MIN_CONFIGS)"

# Bitbake validation (optional)
if [[ $CHECK_BITBAKE -eq 1 ]]; then
    echo ""
    echo "=== Bitbake Validation ==="
    
    if ! command -v bitbake-layers &> /dev/null; then
        echo "ERROR: bitbake-layers not found. Source oe-init-build-env first."
        exit 1
    fi
    
    echo "Checking layer bbappends..."
    APPENDS=$(bitbake-layers show-appends 2>/dev/null | grep -c "linux-socfpga" || echo 0)
    echo "Found $APPENDS linux-socfpga bbappends"
    
    if [[ $APPENDS -eq 0 ]]; then
        echo "ERROR: No bbappends found for linux-socfpga kernel"
        exit 1
    fi
    
    echo ""
    echo "Checking KERNEL_CONFIG_FRAGMENTS..."
    FRAGMENTS_VAR=$(bitbake -e virtual/kernel 2>/dev/null | grep "^KERNEL_CONFIG_FRAGMENTS=" || echo "")
    
    if [[ -z "$FRAGMENTS_VAR" ]]; then
        echo "ERROR: KERNEL_CONFIG_FRAGMENTS is not set in kernel recipe"
        exit 1
    fi
    
    echo "$FRAGMENTS_VAR"
    
    if ! echo "$FRAGMENTS_VAR" | grep -q "fragment.cfg"; then
        echo "ERROR: fragment.cfg not found in KERNEL_CONFIG_FRAGMENTS"
        exit 1
    fi
    
    echo ""
    echo "Running kernel_configcheck..."
    bitbake virtual/kernel -c kernel_configcheck 2>&1 | tail -20
fi

echo ""
echo "=== Validation PASSED ==="
exit 0

