#!/bin/bash

# Kali Quick Deploy Script
# This script quickly creates containers from the baseline image

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <container_name> <local_port>"
    echo "Example: $0 kali-htb 4444"
    echo ""
    echo "This script creates containers from the baseline image."
    echo "If no baseline exists, run create-baseline.sh first."
    exit 1
fi

CONTAINER_NAME="$1"
LOCAL_PORT="$2"

# Configuration
HOST_OVPN_DIR="$HOME/kali-docker-shares/ovpn-configs"
HOST_SCRIPTS_DIR="$HOME/kali-docker-shares/scripts"
BASELINE_IMAGE="kali-baseline:latest"

echo "=== Kali Quick Deploy ==="

# Check if baseline image exists
if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^kali-baseline:latest$"; then
    echo "❌ No baseline image found!"
    echo "You need to create a baseline first:"
    echo "  ./create-baseline.sh"
    exit 1
fi

# Validate port number
if ! [[ "$LOCAL_PORT" =~ ^[0-9]+$ ]] || [ "$LOCAL_PORT" -lt 1 ] || [ "$LOCAL_PORT" -gt 65535 ]; then
    echo "❌ Invalid port number: $LOCAL_PORT"
    echo "Port must be between 1 and 65535"
    exit 1
fi

# Check if port is already in use by Docker
echo "Checking port availability..."
DOCKER_PORTS=$(docker ps --format "table {{.Ports}}" | grep -E ":${LOCAL_PORT}->" || true)
if [ ! -z "$DOCKER_PORTS" ]; then
    echo "❌ Port $LOCAL_PORT is already in use by Docker:"
    echo "$DOCKER_PORTS"
    echo ""
    echo "Choose a different port or stop the conflicting container."
    exit 1
fi

# Check if port is in use by system (optional additional check)
if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $LOCAL_PORT appears to be in use by another process."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 1
        fi
    fi
fi

echo "✅ Port $LOCAL_PORT is available"

# Create host directories if they don't exist
echo "Setting up host directories..."
mkdir -p "$HOST_OVPN_DIR"
mkdir -p "$HOST_SCRIPTS_DIR"

# Check if container already exists and is running
if docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '$CONTAINER_NAME' is already running."
    echo "Access it with: docker exec -it $CONTAINER_NAME zsh"
    echo "Or SSH with: ssh root@localhost -p $LOCAL_PORT (password: kali)"
    echo "Or use a different container name."
    exit 1
fi

# Check if container exists but is stopped
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠️  Container '$CONTAINER_NAME' already exists but is stopped."
    echo "Starting existing container..."
    docker start "$CONTAINER_NAME"
    
    # Wait for container to be ready
    echo "Waiting for container to initialize..."
    sleep 5
    
    echo "✅ Container started successfully!"
    echo ""
    echo "=== Connection Info ==="
    echo "SSH into container: ssh root@localhost -p $LOCAL_PORT (password: kali)"
    echo "Direct access: docker exec -it $CONTAINER_NAME zsh"
    exit 0
fi

# Create new container from baseline
echo "Creating new container from baseline..."
echo "Container: $CONTAINER_NAME"
echo "Port: $LOCAL_PORT -> 22"

docker run -d \
    --name "$CONTAINER_NAME" \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v "$HOST_OVPN_DIR:/ovpn-configs:ro" \
    -v "$HOST_SCRIPTS_DIR:/host-scripts:rw" \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    -p "$LOCAL_PORT:22" \
    "$BASELINE_IMAGE"

# Wait for container to be ready
echo "Waiting for container to initialize..."
sleep 8

# Check if container is running
if docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ Container created successfully!"
    echo ""
    echo "=== Connection Info ==="
    echo "SSH into container: ssh root@localhost -p $LOCAL_PORT (password: kali)"
    echo "Direct access: docker exec -it $CONTAINER_NAME zsh"
    echo ""
    echo "=== Directory Mappings ==="
    echo "Host VPN configs ($HOST_OVPN_DIR) → Container (/ovpn-configs)"
    echo "Host scripts ($HOST_SCRIPTS_DIR) → Container (/host-scripts) [Added to PATH]"
    echo ""
    echo "=== Quick Start ==="
    echo "docker exec -it $CONTAINER_NAME zsh"
else
    echo "❌ Container failed to start. Check logs:"
    echo "docker logs $CONTAINER_NAME"
    exit 1
fi
