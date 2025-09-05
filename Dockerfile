FROM kalilinux/kali-rolling

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/host-scripts:$PATH"

# Update system and install systemd
RUN apt-get update && \
    apt-get install -y systemd systemd-sysv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update apt and install Kali metapackages
RUN apt-get update && \
    apt-get install -y \
        kali-tools-web \
        kali-tools-fuzzing \
        kali-tools-information-gathering \
        metasploit-framework \
        postgresql \
        openssh-server \
        vim \
        nano \
        curl \
        wget \
        git \
        python3 \
        python3-pip \
        netcat-traditional \
        socat \
        tmux \
        screen \
        htop \
        tree \
        jq \
        zsh \
        seclists \
        && apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Configure SSH (since we're forwarding port 22)
RUN mkdir -p /var/run/sshd && \
    echo 'root:kali' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Configure zsh as default shell
RUN chsh -s /usr/bin/zsh root

# Install oh-my-zsh for better zsh experience
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ===== OH-MY-ZSH CUSTOMIZATIONS =====

# Install additional oh-my-zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins/zsh-completions

# Install powerlevel10k theme (popular theme)
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k

# Create custom .zshrc with your preferred settings
RUN cat > /root/.zshrc << 'EOF'
# Path to your oh-my-zsh installation
export ZSH="/root/.oh-my-zsh"

# Theme selection (options: robbyrussell, agnoster, powerlevel10k/powerlevel10k)
ZSH_THEME="agnoster"
# ZSH_THEME="powerlevel10k/powerlevel10k"  # Uncomment for powerlevel10k

# Plugins to load
plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    docker
    python
    pip
    nmap
    history-substring-search
)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# ===== CUSTOM ALIASES =====
# Pentesting shortcuts
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias nse='ls /usr/share/nmap/scripts/ | grep'
alias wordlists='ls /usr/share/seclists/'
alias weblist='ls /usr/share/seclists/Discovery/Web-Content/'
alias passlist='ls /usr/share/seclists/Passwords/'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Network and pentesting aliases
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'
alias listening='netstat -tulanp | grep LISTEN'
alias tcpdump='tcpdump -i any'

# Metasploit shortcuts
alias msfconsole='msfconsole -q'
alias msfvenom='msfvenom'

# Docker shortcuts
alias dc='docker'
alias dps='docker ps'
alias dexec='docker exec -it'

# Git shortcuts (if using git in containers)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# ===== CUSTOM FUNCTIONS =====
# Quick HTTP server
function serve() {
    local port=${1:-8000}
    python3 -m http.server $port
}

# Quick nmap scan
function quickscan() {
    if [ $# -eq 0 ]; then
        echo "Usage: quickscan <target>"
        return 1
    fi
    nmap -sS -sV -O --top-ports 1000 $1
}

# Directory enumeration shortcut
function dirb_common() {
    if [ $# -eq 0 ]; then
        echo "Usage: dirb_common <url>"
        return 1
    fi
    gobuster dir -u $1 -w /usr/share/seclists/Discovery/Web-Content/common.txt
}

# Password attack shortcut
function hydra_ssh() {
    if [ $# -lt 2 ]; then
        echo "Usage: hydra_ssh <target> <username> [wordlist]"
        return 1
    fi
    local wordlist=${3:-/usr/share/seclists/Passwords/Common-Credentials/10-million-password-list-top-1000.txt}
    hydra -l $2 -P $wordlist ssh://$1
}

# ===== ENVIRONMENT VARIABLES =====
export PATH="/host-scripts:$PATH"
export EDITOR="vim"
export BROWSER="firefox"

# History settings
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ===== PROMPT CUSTOMIZATION =====
# If not using powerlevel10k, customize the prompt
if [[ "$ZSH_THEME" != "powerlevel10k/powerlevel10k" ]]; then
    # Add timestamp to prompt
    PROMPT='%{$fg[cyan]%}[%D{%H:%M:%S}] '$PROMPT
fi

# Welcome message
echo "🔥 Kali Container Ready - Happy Hacking! 🔥"
echo "📁 Wordlists: /usr/share/seclists/"
echo "🛠️  Custom scripts: /host-scripts/"
echo "🔗 VPN configs: /ovpn-configs/"
EOF

# ===== OPTIONAL: POWERLEVEL10K CONFIGURATION =====
# Uncomment the next section if you want to use powerlevel10k with pre-configured settings
# RUN cat > /root/.p10k.zsh << 'EOF'
# # Powerlevel10k configuration - minimal setup
# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
# 
# # Powerlevel10k settings
# typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
# typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)
# typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
# EOF

# Set proper permissions
RUN chown root:root /root/.zshrc

# Enable services
RUN systemctl enable postgresql && \
    systemctl enable ssh

# Create directories for mounted content
RUN mkdir -p /ovpn-configs /host-scripts

# Add host-scripts to PATH permanently
RUN echo 'export PATH="/host-scripts:$PATH"' >> /root/.bashrc && \
    echo 'export PATH="/host-scripts:$PATH"' >> /etc/bash.bashrc && \
    echo 'export PATH="/host-scripts:$PATH"' >> /root/.zshrc

# Clean up systemd for container use
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f || true

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* || true

# Create a startup script to initialize services
RUN cat > /startup.sh << 'EOF'
#!/bin/bash
# Wait for systemd to be ready
sleep 2

# Start PostgreSQL if not running
if ! systemctl is-active postgresql >/dev/null 2>&1; then
    systemctl start postgresql
fi

# Initialize metasploit database if needed
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw msf; then
    msfdb init
fi

# Start SSH if not running
if ! systemctl is-active ssh >/dev/null 2>&1; then
    systemctl start ssh
fi

echo "=== Kali Container Ready ==="
echo "SSH: Available on forwarded port -> 22 (container)"
echo "Metasploit: Database initialized and ready"
echo "VPN configs: Available in /ovpn-configs"
echo "Custom scripts: Available in /host-scripts (added to PATH)"
echo "================================"
EOF

RUN chmod +x /startup.sh

# Create a systemd service to run our startup script
RUN cat > /etc/systemd/system/container-init.service << 'EOF'
[Unit]
Description=Container Initialization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

RUN systemctl enable container-init.service

# Set working directory
WORKDIR /root

# Expose ports (documentation only - actual mapping done in docker run)
EXPOSE 22 4444 8080 80 443

# Configure systemd as init
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/lib/systemd/systemd"]
