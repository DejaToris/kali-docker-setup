#!/bin/bash

# Web scanning script using dirb and nikto
# Usage: ./web-scan.sh <target_name>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_name>"
    echo "Example: $0 webserver1"
    echo ""
    echo "Available targets:"
    if [[ -n "$TARGETS" ]]; then
        for target in $TARGETS; do
            echo "  $target"
        done
    else
        echo "  No targets configured. Use set-target.sh to configure targets."
    fi
    exit 1
fi

TARGET_NAME=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Get target variables
TARGET_IP_VAR="${TARGET_NAME}_IP"
TARGET_HOSTNAME_VAR="${TARGET_NAME}_HOSTNAME"
TARGET_PORT_VAR="${TARGET_NAME}_PORT"

TARGET_IP=${!TARGET_IP_VAR}
TARGET_HOSTNAME=${!TARGET_HOSTNAME_VAR}
TARGET_PORT=${!TARGET_PORT_VAR}

# Determine what to scan
if [[ -n "$TARGET_HOSTNAME" ]]; then
    SCAN_TARGET="$TARGET_HOSTNAME"
elif [[ -n "$TARGET_IP" ]]; then
    SCAN_TARGET="$TARGET_IP"
else
    echo "Error: No IP or hostname configured for target '$1'"
    echo "Use set-target.sh to configure this target first."
    exit 1
fi

# Set default port if not specified
if [[ -z "$TARGET_PORT" ]]; then
    TARGET_PORT="80"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="web-scan-${1}-${TIMESTAMP}.txt"

echo "Starting web scan for target: $1"
echo "Scanning: $SCAN_TARGET:$TARGET_PORT"
echo "Output will be saved to: $OUTPUT_FILE"
echo "=================================================="

# Create output file with header
cat > "$OUTPUT_FILE" << EOF
Web Security Scan Report
Target Name: $1
Target Host: $SCAN_TARGET:$TARGET_PORT
Timestamp: $(date)
================================================

EOF

# Function to append section separator
append_section() {
    echo "" >> "$OUTPUT_FILE"
    echo "================================================" >> "$OUTPUT_FILE"
    echo "$1" >> "$OUTPUT_FILE"
    echo "================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Run dirb scan
echo "Running dirb scan..."
append_section "DIRB DIRECTORY SCAN"
if command -v dirb >/dev/null 2>&1; then
    dirb "http://$SCAN_TARGET:$TARGET_PORT" >> "$OUTPUT_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Dirb scan completed"
    else
        echo "⚠ Dirb scan encountered issues (check output file)"
    fi
else
    echo "dirb: command not found" >> "$OUTPUT_FILE"
    echo "⚠ dirb not installed or not in PATH"
fi

# Run nikto scan
echo "Running nikto scan..."
append_section "NIKTO VULNERABILITY SCAN"
if command -v nikto >/dev/null 2>&1; then
    nikto -h "$SCAN_TARGET" -p "$TARGET_PORT" >> "$OUTPUT_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Nikto scan completed"
    else
        echo "⚠ Nikto scan encountered issues (check output file)"
    fi
else
    echo "nikto: command not found" >> "$OUTPUT_FILE"
    echo "⚠ nikto not installed or not in PATH"
fi

# Add completion timestamp
append_section "SCAN COMPLETED"
echo "Scan completed at: $(date)" >> "$OUTPUT_FILE"

echo "=================================================="
echo "Web scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "File size: $(wc -c < "$OUTPUT_FILE") bytes"