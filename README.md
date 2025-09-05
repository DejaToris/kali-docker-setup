# Kali Custom Container Usage Guide

## Quick Start

### Method 1: Quick Deploy (Recommended)
```bash
# First, create the baseline image (only needed once)
./create-baseline.sh

# Then quickly deploy containers
./quick-deploy.sh <container_name> <port>
./quick-deploy.sh kali-htb 4444
```

### Method 2: Using Docker Compose
```bash
# Start the container
docker-compose up -d

# Access the container
docker-compose exec custom-kali /bin/bash
```

### Method 3: Manual Docker Commands
```bash
# Build the image
docker build -t custom-kali .

# Run the container
docker run -d \
    --name custom-kali \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v ~/kali-docker-shares/ovpn-configs:/ovpn-configs:ro \
    -v ~/kali-docker-shares/scripts:/host-scripts:rw \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    -p 4444:22 \
    -p 8080:8080 \
    custom-kali
```

## Project Scripts

This project provides three main scripts for managing Kali containers:

### create-baseline.sh
Creates a baseline Docker image with all Kali packages installed. This is a one-time setup that takes significant time but enables fast container creation later.

```bash
./create-baseline.sh
```

### quick-deploy.sh
Quickly creates new containers from the baseline image. Much faster than building from scratch.

```bash
./quick-deploy.sh <container_name> <port>
./quick-deploy.sh kali-htb 4444
./quick-deploy.sh kali-thm 5555
```

### kali-manager.sh
Helps manage baseline images and containers with various utility commands:

```bash
./kali-manager.sh status              # Show baseline and container status
./kali-manager.sh list                # List all containers
./kali-manager.sh ports               # Show port usage
./kali-manager.sh clean-containers    # Remove stopped containers
./kali-manager.sh clean-baseline      # Remove baseline image
./kali-manager.sh clean-old-baselines # Remove old baseline images (keep latest)
```

## Host Directory Setup

The scripts automatically create these directories:

```bash
~/kali-docker-shares/ovpn-configs  # For VPN configuration files
~/kali-docker-shares/scripts       # For custom scripts
```

### VPN Configurations
- Place your `.ovpn` files in `~/kali-docker-shares/ovpn-configs/`
- They'll be available in `/ovpn-configs/` inside the container
- Example: `openvpn /ovpn-configs/htb-lab.ovpn`

### Custom Scripts
- Place executable scripts in `~/kali-docker-shares/scripts/`
- They'll be automatically added to PATH inside the container
- Example: Create `~/kali-docker-shares/scripts/my-enum.sh` and it'll be available as `my-enum.sh` from anywhere in the container

## Container Access

### SSH Access
```bash
ssh root@localhost -p <port>
# Password: kali
# Replace <port> with the port you specified when creating the container
```

### Direct Docker Access
```bash
docker exec -it custom-kali /bin/bash
```

## Installed Tools

### Metapackages Included:
- **kali-tools-web**: Web application testing tools
- **kali-tools-fuzzing**: Fuzzing tools for vulnerability discovery
- **kali-tools-information-gathering**: Reconnaissance and info gathering tools

### Key Tools Available:
- Metasploit Framework (with working database)
- Nmap and related tools
- Web testing tools (Burp Suite, dirb, nikto, etc.)
- Fuzzing tools (wfuzz, ffuf, etc.)
- Information gathering tools (theHarvester, recon-ng, etc.)

## Services

The container automatically starts:
- **PostgreSQL**: For Metasploit database
- **SSH**: For remote access (port specified during container creation)
- **Metasploit Database**: Pre-initialized and ready

## Port Mappings

| Host Port | Container Port | Purpose |
|-----------|----------------|---------|
| Variable | 22 | SSH access (specified when creating container) |
| 8080 | 8080 | Web services (docker-compose only) |
| 9001 | 9001 | Additional services (docker-compose only) |

**Note**: When using `quick-deploy.sh`, only the SSH port is mapped and you specify it as an argument. The docker-compose method maps additional fixed ports.

## Common Commands

### Metasploit
```bash
# Start Metasploit (database already configured)
msfconsole

# Check database status
msfdb status
```

### VPN Connection
```bash
# Connect to HTB/THM/etc
openvpn /ovpn-configs/your-config.ovpn
```

### Using SecLists
```bash
# SecLists are installed at /usr/share/seclists/
ls /usr/share/seclists/

# Common wordlists
/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
/usr/share/seclists/Passwords/Common-Credentials/10-million-password-list-top-1000.txt
/usr/share/seclists/Usernames/Names/names.txt

# Example usage with gobuster
gobuster dir -u http://target.com -w /usr/share/seclists/Discovery/Web-Content/common.txt

# Example usage with hydra
hydra -L /usr/share/seclists/Usernames/top-usernames-shortlist.txt \
      -P /usr/share/seclists/Passwords/Common-Credentials/top-passwords-shortlist.txt \
      ssh://target.com
```

### Zsh Features
```bash
# Oh-My-Zsh is pre-configured with useful features:
# - Auto-completion
# - Syntax highlighting
# - Git integration
# - Plugin support

# Switch back to bash if needed
bash

# Return to zsh
zsh
```

### Container Management
```bash
# Stop container
docker stop custom-kali

# Start container
docker start custom-kali

# Restart container
docker restart custom-kali

# View logs
docker logs custom-kali

# Remove container
docker rm custom-kali

# Rebuild image
docker build -t custom-kali . --no-cache
```

## Customization

### Adding More Tools
Edit the Dockerfile and add packages to the `apt-get install` command:
```dockerfile
RUN apt-get install -y \
    your-additional-tool \
    another-tool
```

### Changing Host Directories
Modify the volume mounts in:
- `quick-deploy.sh` (update `HOST_OVPN_DIR` and `HOST_SCRIPTS_DIR`)
- `docker-compose.yml` (update the volumes section)

### Adding More Ports
Add port mappings in the docker run command or docker-compose.yml:
```bash
-p HOST_PORT:CONTAINER_PORT
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs <container-name>

# Verify systemd is working
docker exec -it <container-name> systemctl status
```

### Metasploit Database Issues
```bash
# Reinitialize database
docker exec -it <container-name> msfdb reinit
```

### SSH Connection Refused
```bash
# Check if SSH is running
docker exec -it <container-name> systemctl status ssh

# Restart SSH
docker exec -it <container-name> systemctl restart ssh
```

### Permission Issues with Scripts
```bash
# Make scripts executable
chmod +x ~/kali-docker-shares/scripts/your-script.sh
```

## Workflow

The typical workflow for using this project:

1. **One-time setup**: Run `./create-baseline.sh` to build the baseline image with all tools
2. **Deploy containers**: Use `./quick-deploy.sh <name> <port>` to quickly create containers
3. **Manage containers**: Use `./kali-manager.sh` to check status, clean up, etc.
4. **Reuse baseline**: The baseline image can be reused to create multiple containers quickly

## Security Notes

- The container runs with `--privileged` for systemd functionality
- Root password is set to "kali" for SSH access
- Only use in trusted/isolated environments
- Consider changing the SSH password for production use
- Port conflicts are automatically detected to prevent accidental exposure

## Advanced Usage

### Multiple Baselines
Create specialized baselines by modifying the Dockerfile:
```bash
# Create a web-focused baseline
# Edit Dockerfile to add more web tools, then:
./create-baseline.sh
docker tag kali-baseline:latest kali-web-baseline:latest

# Create containers from specific baseline using manual docker commands
docker run -d --name web-container kali-web-baseline:latest
```

### Custom Tool Integration
```bash
# Add your tools to the scripts directory
echo '#!/bin/bash\nnmap -sS -O $1' > ~/kali-docker-shares/scripts/quick-scan
chmod +x ~/kali-docker-shares/scripts/quick-scan

# Now available in all containers as: quick-scan <target>
```

## Available Scripts Summary

| Script | Purpose | Usage |
|--------|---------|-------|
| `create-baseline.sh` | Build baseline image with all tools (slow, one-time) | `./create-baseline.sh` |
| `quick-deploy.sh` | Create containers quickly from baseline | `./quick-deploy.sh <name> <port>` |
| `kali-manager.sh` | Manage containers and baseline images | `./kali-manager.sh [status\|list\|ports\|clean-containers\|clean-baseline\|clean-old-baselines]` |
