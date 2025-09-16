#!/bin/bash

# Script d'installation des utilitaires de base pour le développement
# Auteur: hmzoo
# Date: $(date +%Y-%m-%d)

# Variables
LOG_FILE="/var/log/install_base.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Ce script doit être exécuté avec les droits root (sudo)"
    exit 1
fi

log "[INFO] Début de l'installation des utilitaires de base"

# Mise à jour du système
log "[INFO] Mise à jour des paquets système..."
apt update && apt upgrade -y

# Installation des utilitaires de base
log "[INFO] Installation des outils de développement de base..."

# Outils système essentiels
apt install -y \
    curl \
    wget \
    unzip \
    zip \
    tar \
    gzip \
    tree \
    htop \
    screen \
    tmux \
    nano \
    vim \
    neovim \
    less \
    grep \
    awk \
    sed \
    jq \
    net-tools \
    iputils-ping \
    telnet \
    openssh-client \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release

# Git et outils de versioning
log "[INFO] Installation de Git..."
apt install -y git git-lfs

# Outils de compilation et développement
log "[INFO] Installation des outils de compilation..."
apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev



# Configuration de Git (global)
log "[INFO] Configuration de base de Git..."
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "vim"

# Configuration de Vim
log "[INFO] Configuration de Vim..."
cat > /home/hmj/.vimrc << 'EOF'
" Configuration Vim de base
set number
set relativenumber
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set hlsearch
set incsearch
set ignorecase
set smartcase
set wrap
set linebreak
set showmatch
set wildmenu
set laststatus=2
set ruler
set showcmd
set mouse=a

" Couleurs
syntax on
set background=dark

" Raccourcis clavier
nnoremap <C-n> :set number!<CR>
nnoremap <C-h> :nohlsearch<CR>
EOF

chown hmj:hmj /home/hmj/.vimrc

# Configuration de Bash (amélioration du prompt)
log "[INFO] Configuration du prompt Bash..."
cat >> /home/hmj/.bashrc << 'EOF'

# Prompt personnalisé avec Git
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]\$(parse_git_branch)\[\033[00m\]\$ "

# Alias utiles
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias gst='git status'
alias glog='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gaa='git add .'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'

# Historique
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Variables d'environnement
export EDITOR=vim
export VISUAL=vim
EOF

# Installation d'outils Python utiles
log "[INFO] Installation d'outils Python..."
pip3 install --upgrade pip
pip3 install virtualenv pipenv black flake8 pylint pytest requests

# Nettoyage
log "[INFO] Nettoyage..."
apt autoremove -y
apt autoclean

log "[INFO] Installation terminée avec succès!"
log "[INFO] Redémarrage recommandé pour finaliser l'installation de Docker"

echo ""
echo "=================================="
echo "Installation terminée !"
echo "=================================="
echo ""
echo "Outils installés :"
echo "- Utilitaires système : curl, wget, vim, git, htop, tree, etc."
echo "- Outils de développement : gcc, make, cmake, python3"
echo "- Configuration Vim et Bash améliorée"
echo ""
echo "Actions recommandées :"
echo "1. Configurer Git avec vos informations :"
echo "   git config --global user.name 'Votre Nom'"
echo "   git config --global user.email 'votre@email.com'"
echo ""
echo "2. Installer Docker et Node.js séparément :"
echo "   sudo ./vmconfig/install_docker.sh"
echo "   sudo ./vmconfig/install_node.sh"
echo ""
echo "3. Vérifier les installations :"
echo "   git --version"
echo "   python3 --version"
echo ""
echo "Log d'installation disponible : $LOG_FILE"