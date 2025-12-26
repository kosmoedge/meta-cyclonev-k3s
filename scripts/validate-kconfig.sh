#!/bin/bash
# Validates Linux kernel Kconfig fragment files
# Usage: validate-kconfig.sh <config-file>
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

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

CONFIG_FILE="$1"

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
else
    echo "OK: $CONFIG_FILE is valid"
    exit 0
fi

