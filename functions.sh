DIR="$(dirname "$0")"
##
# Source the utils
##
. "$DIR"/utils.sh

function set_zsh_shell {
  local zshrc="${DIR}/dotfiles/.zshrc"
  local p10krc="${DIR}/dotfiles/.p10k.zsh"

  if ! command -v zsh >/dev/null 2>&1; then
    show_warning "Zsh not installed. Skipping."
    return
  fi

  if ! grep -q "zsh" <(getent passwd "$(whoami)"); then
    show_info "Changing login shell to Zsh. Provide your password."
    chsh -s /bin/zsh
  else
    show_info "Default shell already set to Zsh."
  fi

  mkdir -p "${HOME}/.local/share/zsh/site-functions"

  copy_config_file "${zshrc}" "${HOME}/.zshrc"
  copy_config_file "${p10krc}" "${HOME}/.p10k.zsh"
}

function install_zsh {
  local zsh_list="${DIR}/packages/zsh.list"

  show_header "Installing Zsh."
  check_installed "${zsh_list}"
  show_success "Zsh installed."

  if [ ! -d "$HOME/powerlevel10k"]; then
    show_info "Installing powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    show_success "powerlevel10k installed successfull"
  else
    show_info "powerlevel10k already installed"
  fi

  set_zsh_shell
}

function install_lazyvim {
  if [ $EUID -ne 0 ]; then
    local lazyvim="${DIR}/packages/lazyvim.list"
    local lazygit="${DIR}/configs/lazygit.yml"
    local nvimspell="${HOME}/.config/nvim/spell"

    show_info "Installing LazyVim dependencies."
    check_installed "${lazyvim}"
    show_success "LazyVim dependencies installed."

    copy_config_file "${lazygit}" "${HOME}/.config/lazygit/config.yml"

    show_info "Installing LazyVim configuration files for Neovim."
    if [ -d "${HOME}/.config/nvim" ]; then
      if [ -d "${HOME}/.config/nvim/.git" ] &&
        git -C "${HOME}/.config/nvim" remote show origin -n |
        grep -q "LazyVim/starter"; then
        show_info "LazyVim config already installed."
        git -C "${HOME}/.config/nvim" pull
        show_success "Existing LazyVim updated."
      else
        show_info "Backing up existing Neovim config directory."
        mv -v "${HOME}/.config/nvim" "${HOME}/.config/nvim_$(date +%Y%m%d-%k%M%S)"
        git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"

        show_success "LazyVim installed."
      fi
    else
      git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
      show_success "LazyVim installed."
    fi

    show_info "Install local wordlist."
    mkdir -p "${nvimspell}"
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone --depth 1 \
      https://github.com/sudorook/wordlist.vim.git "${tmpdir}"
    pushd "${tmpdir}" >/dev/null || exit
    ./build
    if [ -f "${nvimspell}/en.utf-8.add" ]; then
      show_info "Wordlist already exists in ${nvimspell@Q}. Appending."
      ./append
    else
      ./install
    fi
    popd >/dev/null || exit
    rm -rf "${tmpdir}"
    show_success "Wordlist installed in ${nvimspell@Q}."
  else
    show_warning "Don't do this as root. Skipping..."
  fi
}

function install_network {
  local networking="$DIR/packages/network.list"
  local nmconf="/etc/NetworkManager/NetworkManager.conf"
  local nmrandomconf="/etc/NetworkManager/conf.d/randomize_mac_address.conf"

  show_header "setting up networking."
  show_success "Networking aplications installed."
  check_installed "${networking}"

  show_info "Setting up MAC address randomization in Network Manager."
  if ! find "${nmconf}" /etc/NetworkManager/conf.d/ -type f -exec grep -q "mac-address=random" {} +; then
    sudo tee -a "${nmrandomconf}" >/dev/null <<EOF
[connection-mac-randomization]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
  fi

  show_info "Enabling NetworkManager service."
  sudo systemctl enable --now NetworkManager

  show_info "Disabling SSH root login and forcing SSH v2."
  sudo sed -i \
    -e "/^#PermitRootLogin prohibit-password$/a PermitRootLogin no" \
    -e "/^#Port 22$/i Protocol 2" \
    /etc/ssh/sshd_config

}

function install_bluetooth {
  #Install deps
  pacman -S --needed --noconfirm bluez bluez-utils blueman
  sudo systemctl start bluetooth.service
  sudo systemctl enable bluetooth.service
}

function install_fonts {
  local font_list="$DIR/packages/fonts.list"
  show_header "Installing fonts."
  check_installed "${font_list}"
  show_success "Fonts installed."

  show_info "Setting nerd font config."
  if ! [ -d /etc/fonts/conf.d ]; then
    show_warning "'/etc/fonts/conf.d' for fontconfig is missing. Skipping."
  elif ! [ -e /etc/fonts/conf.d/10-nerd-font-symbols.conf ]; then
    sudo ln -s \
      /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf \
      /etc/fonts/conf.d/
  fi
}

function install_rust {
  show_info "Installing rust stable toolchain."
  rustup default stable

  show_info "Building local cache of cargo crates."
  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone --depth 1 https://github.com/sudorook/crate_dl.git "${tmpdir}"
  pushd "${tmpdir}" >/dev/null || exit
  cargo fetch
  popd >/dev/null || exit
  rm -rf "${tmpdir}"
}

function install_printer() {
  local printer_list="$DIR"/packages/printer.list
  show_header "Installing CPUS and printer firmware."
  check_installed "${printer_list}"
  show_success "Printing applications installed."
  sudo systemctl enable --now cups

}

function install_essential() {
  local essential_list="$DIR/packages/essential.list"
  show_header "Installing essential packages."
  check_installed "${essential_list}"
  show_success "Essential packages installed."
}

function install_deps() {
  local dev_list="$DIR/packages/dev.list"
  show_header "Installing dependencies."
  check_installed "${dev_list}"

  install_rust

  # Install Bun
  if ! command -v bun >/dev/null; then
    curl -fsSL https://bun.sh/install | sh
  else
    show_success "bun already installed"
  fi

  #Install Fnm
  if ! command -v fnm >/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | sh
  else
    show_success "fnm already installed"
  fi

  show_success "deps dependencies installed."
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

function install_bun() {
  show_header "Installing bun"

  # Install Bun
  if ! command -v bun >/dev/null; then
    curl -fsSL https://bun.sh/install | sh
    show_success "Bun installed successfull"
  else
    show_success "bun already installed"
  fi

}

function install_aur_deps() {
  local aur_deps_list="$DIR/packages/aur-deps.list"
  show_header "Installing AUR dependencies."
  check_aur_installed "${aur_deps_list}"
  show_success "AUR dependencies installed."
}

function install_laptop {
  local laptop_list="${DIR}/packages/laptop.list"

  show_header "Installing laptop utilities."
  check_installed "${laptop_list}"
  show_success "Laptop utilities installed."

  # Enable tlp on laptops.
  show_info "Enabling and starting tlp systemd units."
  sudo systemctl enable tlp.service
  sudo systemctl start tlp.service
  show_success "tlp enabled."
}

function set_plymouth_theme {
  local theme="${1:-default}"
  if command -v plymouth-set-default-theme >/dev/null; then
    case "${theme}" in
    Back)
      return
      ;;
    default)
      sudo plymouth-set-default-theme -r -R
      ;;
    breeze-text)
      show_warning "WARNING: ${theme@Q} not working as of 03/07/2024."
      ;;
    *)
      sudo plymouth-set-default-theme -R "${theme}"
      ;;
    esac
  else
    show_warning "'plymouth-set-default-theme' executable not found. Skipping."
  fi
}

function select_plymouth_theme {
  if command -v plymouth-set-default-theme >/dev/null; then
    show_info "Select Plymouth theme:"
    local choice
    local choices
    mapfile -t choices < <(plymouth-set-default-theme -l)
    select choice in Back default "${choices[@]}"; do
      set_plymouth_theme "${choice}"
      break
    done
  else
    show_warning "'plymouth-set-default-theme' executable not found. Skipping."
  fi
}

function install_plymouth {
  local plymouth="${DIR}/packages/plymouth.list"
  local mkinitcpioconf="/etc/mkinitcpio.conf"
  local grubconf="/etc/default/grub"

  show_header "Installing Plymouth splash screen."
  check_aur_installed "${plymouth}"
  show_success "Plymouth installed."

  show_info "Enabling Plymouth in mkinitcpio.conf."
  if ! grep -q "^HOOKS=(.*plymouth.*)$" "${mkinitcpioconf}"; then
    # Insert the Plymouth hook after kernel mode setting.
    sudo sed -i '/^HOOKS=/s/ kms / kms plymouth /' "${mkinitcpioconf}"
    sudo mkinitcpio -P
  fi

  if [ -f "${grubconf}" ] && ! sudo grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=.*splash" "${grubconf}"; then
    show_info "Updating GRUB defaults for splash screen."
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ splash"/g' "${grubconf}"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi

  if [ "$(sudo bootctl is-installed)" = yes ]; then
    show_info "Updating Gummiboot entries for Plymouth splash screen."
    local efidir
    local conf
    efidir="$(bootctl -p)"
    while read -r conf; do
      if ! grep -q "^options.*splash" "${conf}"; then
        sudo sed -i "/^options/s/$/ splash/" "${conf}"
      fi
    done < <(sudo find "${efidir}"/loader/entries/ -name "*.conf")
  fi

  select_plymouth_theme
}

function install_developer_deps {
  local dev_list="${DIR}/packages/dev.list"
  local bashrc="${DIR}/dotfiles/.bashrc"
  show_header "Installing developer dependencies."
  check_installed "${dev_list}"
  install_fnm
  install_node
  install_bun
  copy_config_file "${bashrc}" "${HOME}/.bashrc"
  install_zsh
  install_lazyvim
  show_success "Developer dependencies installed."
}
