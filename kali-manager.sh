#!/bin/bash

# Kali Container Manager
# Helps manage baseline images and containers

set -e

BASELINE_IMAGE="kali-baseline"

show_help() {
    echo "Kali Container Manager"
    echo ""
    echo "WORKFLOW:"
    echo "  1. Create baseline (slow, done once): ./create-baseline.sh"
    echo "  2. Quick deploy containers (fast):     ./quick-deploy.sh <n> <port>"
    echo ""
    echo "COMMANDS:"
    echo "  ./kali-manager.sh status              - Show baseline and container status"
    echo "  ./kali-manager.sh list                - List all containers"
    echo "  ./kali-manager.sh ports               - Show port usage"
    echo "  ./kali-manager.sh clean-containers    - Remove stopped containers"
    echo "  ./kali-manager.sh clean-baseline      - Remove baseline image"
    echo "  ./kali-manager.sh clean-old-baselines - Remove old baseline images (keep latest)"
    echo ""
    echo "EXAMPLES:"
    echo "  ./create-baseline.sh                  - Build baseline (takes time)"
    echo "  ./quick-deploy.sh kali-htb 4444       - Quick container on port 4444"
    echo "  ./quick-deploy.sh kali-thm 5555       - Another container on port 5555"
}

show_status() {
    echo "=== Baseline Image Status ==="
    if docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}" | grep -q "^kali-baseline:latest"; then
        echo "✅ Baseline image exists:"
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}" | grep "^kali-baseline"
    else
        echo "❌ No baseline image found. Run: ./create-baseline.sh"
    fi
    
    echo ""
    echo "=== Container Status ==="
    KALI_CONTAINERS=$(docker ps -a --filter "ancestor=$BASELINE_IMAGE" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 || true)
    if [ -z "$KALI_CONTAINERS" ]; then
        echo "No containers created from baseline yet."
    else
        echo "Container    Status      Ports"
        echo "─────────────────────────────────────────"
        echo "$KALI_CONTAINERS"
    fi
}

list_containers() {
    echo "=== All Kali Containers ==="
    docker ps -a --filter "ancestor=$BASELINE_IMAGE" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}"
}

show_ports() {
    echo "=== Docker Port Usage ==="
    echo "Container     Ports"
    echo "────────────────────────────────"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E ":[0-9]+->" | sed 's/0.0.0.0://g' || echo "No ports in use"
}

clean_containers() {
    echo "=== Cleaning Stopped Containers ==="
    STOPPED=$(docker ps -a --filter "ancestor=$BASELINE_IMAGE" --filter "status=exited" --format "{{.Names}}" || true)
    if [ -z "$STOPPED" ]; then
        echo "No stopped containers to clean"
    else
        echo "Removing stopped containers:"
        echo "$STOPPED"
        echo "$STOPPED" | xargs docker rm
        echo "✅ Cleanup complete"
    fi
}

clean_baseline() {
    echo "=== Removing Baseline Image ==="
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^kali-baseline"; then
        read -p "This will remove the baseline image. Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^kali-baseline") || true
            echo "✅ Baseline image removed"
        else
            echo "Cancelled"
        fi
    else
        echo "No baseline image to remove"
    fi
}

clean_old_baselines() {
    echo "=== Removing Old Baseline Images ==="
    
    # Get all kali-baseline images except the latest
    OLD_BASELINES=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | grep "^kali-baseline" | grep -v ":latest" | awk '{print $1":"$2}' || true)
    
    if [ -z "$OLD_BASELINES" ]; then
        echo "No old baseline images to clean"
        return
    fi
    
    echo "Found old baseline images:"
    echo "$OLD_BASELINES"
    echo ""
    
    read -p "Remove these old baseline images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$OLD_BASELINES" | xargs -r docker rmi || true
        echo "✅ Old baseline images removed"
    else
        echo "Cancelled"
    fi
}

# Main script logic
case "${1:-status}" in
    "status")
        show_status
        ;;
    "list")
        list_containers
        ;;
    "ports")
        show_ports
        ;;
    "clean-containers")
        clean_containers
        ;;
    "clean-baseline")
        clean_baseline
        ;;
    "clean-old-baselines")
        clean_old_baselines
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
