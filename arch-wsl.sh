#!/bin/bash

function display_error() {
  echo "Error: $1"
  exit 1
}

DIR="$(dirname "$0")"

source "$DIR"/utils.sh
source "$DIR"/functions.sh

function set_zsh_shell_debian {
  show_header "Configurando Zsh como shell"
  local zshrc="${DIR}/../.zshrc"
  local p10krc="${DIR}/../.p10k.zsh"

  mkdir -p "${HOME}/.local/share/zsh/site-functions"

  # Instalar powerlevel10k si no está instalado
  if [ ! -d "$HOME"/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  else
    show_success "powerlevel10k ya está instalado"
  fi

  # Verificar si Zsh está instalado
  if ! command -v zsh &>/dev/null; then
    show_warning "Zsh no está instalado. Saltando."
    return
  fi

  # Cambiar el shell de inicio de sesión a Zsh si no está configurado
  if ! grep -q "zsh" <(getent passwd "$(whoami)"); then
    show_info "Cambiando el shell de inicio de sesión a Zsh. Proporciona tu contraseña."
    chsh -s /bin/zsh
  else
    show_info "El shell predeterminado ya está configurado a Zsh."
  fi

  # Copiar archivos de configuración
  copy_config_file "${zshrc}" "${HOME}/.zshrc"
  copy_config_file "${p10krc}" "${HOME}/.p10k.zsh"
}

function install_fnm {

  if [ -f "$HOME/.fnm/fnm" ]; then
    show_info "fnm is already installed"
    return
  fi

  local INSTALL_DIR="$HOME/.fnm"
  local FILENAME="fnm-linux"
  local URL="https://github.com/Schniz/fnm/releases/latest/download/$FILENAME.zip"
  local DOWNLOAD_DIR=$(mktemp -d)

  show_header "Installing fnm"
  mkdir -p "$INSTALL_DIR" &>/dev/null
  if ! curl --progress-bar --fail -L "$URL" -o "$DOWNLOAD_DIR/$FILENAME.zip"; then
    show_warning "Download failed.  Check that the release/filename are correct."
    exit 1
  fi

  unzip -q "$DOWNLOAD_DIR/$FILENAME.zip" -d "$DOWNLOAD_DIR"

  if [ -f "$DOWNLOAD_DIR/fnm" ]; then
    mv "$DOWNLOAD_DIR/fnm" "$INSTALL_DIR/fnm"
  else
    mv "$DOWNLOAD_DIR/$FILENAME/fnm" "$INSTALL_DIR/fnm"
  fi

  chmod u+x "$INSTALL_DIR/fnm"
  show_success "Fnm installed successfull"
}

function install_node {
  if ! command -v node &>/dev/null; then
    show_header "Installing nodejs lts"
    "$HOME/.fnm/fnm" install --lts
    show_success "Nodejs installed successfull"
  else
    show_info "Nodejs Lts is alredy installed"
  fi
}

function set_lazyvim {
  show_header "setting lazyvim"

  if [ -d ~/.config/nvim ]; then

    # required
    # mv ~/.config/nvim{,.bak}
    mv -v "$HOME/.config/nvim" "$HOME/.config/nvim.bak_$(date +%Y%m%d-%k%M%S).bak"
    # optional but recommended
    #mv ~/.local/share/nvim{,.bak}
    #mv ~/.local/state/nvim{,.bak}
    #mv ~/.cache/nvim{,.bak}
  fi
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
}

function install_wslu() {
  if ! command -v wslview; then

    local tempdir
    tempdir="$(mktemp -d)"
    pushd "${tempdir}" >/dev/null || exit
    wget https://pkg.wslutiliti.es/public.key
    pacman-key --add public.key
    sudo pacman-key --lsign-key 2D4C887EB08424F157151C493DD50AA7E055D853
    echo -e "\n[wslutilities]\nServer = https://pkg.wslutiliti.es/arch/" | sudo tee -a /etc/pacman.conf >/dev/null
    popd >/dev/null || exit
    sudo pacman -Sy
  else
    show_success "wslu already installed"
  fi
}

function install_deps {
  # local debian_deps="$DIR/packages/debian.list"
  show_header "Verificando dependencias"
  sudo pacman -S --noconfirm --needed \
    curl \
    wget \
    unzip \
    tar \
    neovim \
    lazygit \
    fd \
    ripgrep \
    zsh \
    wl-clipboard \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    zoxide \
    eza \
    openssh
}

# Función principal para instalar componentes en Debian WSL
function install_wsl() {
  #install_wslu
  install_deps # Instalar dependencias necesarias
  install_fnm  # Instalar fnm y Node.js
  install_node
  set_zsh_shell_debian # Configurar Zsh como shell
  # Copiar archivo de configuración de Bash
  copy_config_file "${bashrc}" "${HOME}/.bashrc"
  set_lazyvim
}

install_wsl # Llamar a la función principal para iniciar la instalación
