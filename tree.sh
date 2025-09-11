#!/bin/bash

# Directory Tree Script
# Displays directory structure in ASCII tree format

set -e

# Default values
SHOW_FILES=false
SHOW_DIRS_ONLY=false
MAX_DEPTH=999
TARGET_DIR="."

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] [DIRECTORY] [DEPTH]"
    echo ""
    echo "Display directory tree in ASCII format"
    echo ""
    echo "Arguments:"
    echo "  DIRECTORY    Directory path to display (default: current directory)"
    echo "  DEPTH        Maximum depth to traverse (default: unlimited)"
    echo ""
    echo "Options:"
    echo "  -f           Show both directories and files"
    echo "  -d           Show directories only with file counts"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/dir 3 -f    # Show files and dirs, max depth 3"
    echo "  $0 . 2 -d               # Show dirs only with file counts, depth 2"
    echo "  $0 /home/user -f        # Show all files and dirs in /home/user"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--files)
            SHOW_FILES=true
            shift
            ;;
        -d|--dirs-only)
            SHOW_DIRS_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option $1"
            usage
            ;;
        *)
            if [[ -d "$1" ]]; then
                TARGET_DIR="$1"
            elif [[ "$1" =~ ^[0-9]+$ ]]; then
                MAX_DEPTH="$1"
            else
                echo "Error: '$1' is not a valid directory or depth number"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Convert to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

# Function to count files in a directory
count_files() {
    local dir="$1"
    local count=0
    
    if [[ -d "$dir" ]]; then
        # Check if we have read permission
        if [[ ! -r "$dir" ]]; then
            echo "?"
            return
        fi
        
        # Count files using glob expansion
        shopt -s dotglob
        for item in "$dir"/*; do
            if [[ -f "$item" ]]; then
                ((count++))
            fi
        done
        shopt -u dotglob
    fi
    
    echo "$count"
}

# Function to generate tree structure
generate_tree() {
    local current_dir="$1"
    local prefix="$2"
    local depth="$3"
    local is_last="$4"
    
    # Check depth limit
    if [[ $depth -gt $MAX_DEPTH ]]; then
        return
    fi
    
    # Get directory name
    local dir_name=$(basename "$current_dir")
    if [[ "$current_dir" == "$TARGET_DIR" ]]; then
        dir_name="."
    fi
    
    # Print current directory
    if [[ $depth -eq 0 ]]; then
        echo "$dir_name"
    else
        local connector="├── "
        if [[ "$is_last" == "true" ]]; then
            connector="└── "
        fi
        
        if [[ "$SHOW_DIRS_ONLY" == "true" ]]; then
            local file_count=$(count_files "$current_dir")
            echo "${prefix}${connector}${dir_name}/ ($file_count files)"
        else
            echo "${prefix}${connector}${dir_name}/"
        fi
    fi
    
    # Don't traverse deeper if we've hit max depth
    if [[ $depth -ge $MAX_DEPTH ]]; then
        return
    fi
    
    # Prepare new prefix for children
    local new_prefix="$prefix"
    if [[ $depth -gt 0 ]]; then
        if [[ "$is_last" == "true" ]]; then
            new_prefix="${prefix}    "
        else
            new_prefix="${prefix}│   "
        fi
    fi
    
    # Get and sort directory contents
    local dirs=()
    local files=()
    
    if [[ -d "$current_dir" ]]; then
        # Check if we have read permission on the directory for listing contents
        local has_read_permission=true
        if [[ ! -r "$current_dir" ]]; then
            has_read_permission=false
        fi
        
        # Only try to list contents if we have read permission
        if [[ "$has_read_permission" == "true" ]]; then
            # Use a simpler approach to avoid find issues
            # Enable dotglob to include hidden files
            shopt -s dotglob
            for item in "$current_dir"/*; do
                # Check if glob expansion failed (no matches)
                if [[ ! -e "$item" ]]; then
                    continue
                fi
                
                local item_name=$(basename "$item")
                # Skip current and parent directory entries
                if [[ "$item_name" == "." || "$item_name" == ".." ]]; then
                    continue
                fi
                
                # Include all files and directories (including hidden ones)
                if [[ -d "$item" ]]; then
                    dirs+=("$item")
                elif [[ -f "$item" && "$SHOW_FILES" == "true" ]]; then
                    files+=("$item")
                fi
            done
            # Reset dotglob setting
            shopt -u dotglob
        fi
    fi
    
    # Sort arrays alphabetically
    IFS=$'\n' dirs=($(sort <<<"${dirs[*]}"))
    IFS=$'\n' files=($(sort <<<"${files[*]}"))
    
    # Calculate total items to display
    local total_items=$((${#dirs[@]} + ${#files[@]}))
    local current_item=0
    
    # Display directories first
    for dir in "${dirs[@]}"; do
        ((current_item++))
        local is_last_item="false"
        if [[ $current_item -eq $total_items ]]; then
            is_last_item="true"
        fi
        
        # Check if we can read the directory before recursing
        if [[ ! -r "$dir" ]]; then
            # Directory exists but no read permission
            local dir_name=$(basename "$dir")
            local connector="├── "
            if [[ "$is_last_item" == "true" ]]; then
                connector="└── "
            fi
            
            if [[ "$SHOW_DIRS_ONLY" == "true" ]]; then
                echo "${new_prefix}${connector}${dir_name}/ [Permission Denied]"
            else
                echo "${new_prefix}${connector}${dir_name}/ [Permission Denied]"
            fi
        else
            generate_tree "$dir" "$new_prefix" $((depth + 1)) "$is_last_item"
        fi
    done
    
    # Display files if requested
    if [[ "$SHOW_FILES" == "true" ]]; then
        for file in "${files[@]}"; do
            ((current_item++))
            local file_name=$(basename "$file")
            local connector="├── "
            if [[ $current_item -eq $total_items ]]; then
                connector="└── "
            fi
            echo "${new_prefix}${connector}${file_name}"
        done
    fi
}

# Validate flags
if [[ "$SHOW_FILES" == "true" && "$SHOW_DIRS_ONLY" == "true" ]]; then
    echo "Error: Cannot use both -f and -d flags simultaneously"
    exit 1
fi

# Set default behavior if no flags specified
if [[ "$SHOW_FILES" == "false" && "$SHOW_DIRS_ONLY" == "false" ]]; then
    SHOW_DIRS_ONLY=true
fi

# Generate and display the tree
generate_tree "$TARGET_DIR" "" 0 "false"