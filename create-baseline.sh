#!/bin/bash

# Kali Baseline Creation Script
# This script builds a baseline image with all packages installed

set -e

BASELINE_IMAGE="kali-baseline"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TAGGED_IMAGE="kali-baseline:$TIMESTAMP"

echo "=== Kali Baseline Creation ==="
echo "This will build a baseline image with all Kali packages."
echo "This takes time but only needs to be done occasionally."
echo ""

# Check if baseline already exists
if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^kali-baseline:latest$"; then
    echo "⚠️  Existing baseline found."
    read -p "Do you want to rebuild the baseline? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled. Use quick-deploy.sh to create containers from existing baseline."
        exit 0
    fi
fi

echo "Building baseline image (this will take a while)..."
echo "Started at: $(date)"

# Build the image with timestamp
docker build -t "$TAGGED_IMAGE" .

# Tag as latest
docker tag "$TAGGED_IMAGE" "$BASELINE_IMAGE:latest"

echo ""
echo "✅ Baseline image created successfully!"
echo "📦 Image: $BASELINE_IMAGE:latest"
echo "🏷️  Tagged as: $TAGGED_IMAGE"
echo "📅 Created: $(date)"
echo ""
echo "Now you can use quick-deploy.sh to quickly create containers!"
echo ""
echo "=== Usage ==="
echo "Quick deploy: ./quick-deploy.sh <container_name> <port>"
echo "Example: ./quick-deploy.sh kalifornia 4444"
