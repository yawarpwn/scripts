#!/bin/bash

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
  if ! command -v zsh >/dev/null 2>&1; then
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

function install_neovim() {
  if ! command -v nvim >/dev/null; then
    local temp_dir=$(mktemp -d)
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"

    curl -L -o "$temp_dir/nvim-linux64.tar.gz" "$url"

    if [ $? -eq 0 ]; then
      echo "Descarga completada: $temp_dir/nvim-linux64.tar.gz"

      # Eliminar el directorio de instalación si ya existe
      if [ -d /opt/nvim ]; then
        echo "Eliminando el directorio existente /opt/nvim..."
        sudo rm -rf /opt/nvim
      fi

      # Descomprimir el archivo en /opt
      echo "Descomprimiendo el archivo..."
      sudo tar -C /opt -xzf "$temp_dir/nvim-linux64.tar.gz"

      echo "Neovim instalado en /opt/nvim."
    else
      echo "Error en la descarga."
    fi

    sudo ln -s /opt/nvim-linux64/bin/nvim /usr/bin/nvim

    rmdir "$temp_dir" # Borrar el directorio temporal
  else
    show_success "Neovim ya está instalado"
  fi

  copy_config_file "/home/johneyder/dot/config/nvim" "/home/johneyder/.config/nvim"
}

function install_fnm {
  if ! command -v fnm >/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash
  else
    show_success "Fnm ya está instalado"
  fi

  if ! command -v node >/dev/null; then
    fnm install --lts
  else
    show_success "Node.js ya está instalado"
  fi
}
function install_debian_deps {
  local debian_deps="$DIR/packages/debian.list"
  show_header "Verificando dependencias"

  while read -r package; do
    if ! dpkg -l | grep -qw "${package}"; then
      show_info "${package@Q} es necesario para este script"
      sudo apt install -y "$package"
      show_success "${package@Q} ya está instalado."
    else
      show_success "${package@Q} ya está instalado."
    fi
  done <"${debian_deps}"
}

function install_lazygit {
  if ! command -v lazygit >/dev/null; then
    local tempdir="$(mktemp -d)"

    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    curl -Lo "${tempdir}/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

    pushd "${tempdir}" >/dev/null || exit

    tar xf lazygit.tar.gz lazygit

    sudo install lazygit /usr/local/bin

    popd >/dev/null || exit

    rm -rf "${tempdir}"
  else
    show_success "LazyGit ya está instalado."
  fi
}

# Función principal para instalar componentes en Debian WSL
function install_wsl() {
  install_debian_deps  # Instalar dependencias necesarias
  install_fnm          # Instalar fnm y Node.js
  install_neovim       # Instalar Neovim
  set_zsh_shell_debian # Configurar Zsh como shell
  install_lazygit      # Instalar LazyGit
  # Copiar archivo de configuración de Bash
  copy_config_file "${bashrc}" "${HOME}/.bashrc"
}

install_wsl # Llamar a la función principal para iniciar la instalación
