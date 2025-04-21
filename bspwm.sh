#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/functions.sh"
. "$DIR/utils.sh"

# Globals
GTKTHEME="Adwaita-dark"
ICONTHEME="Papirus-Dark"
FONT="Roboto"

function set_dark_gtk {
  local gtksettings="${HOME}/.config/gtk-3.0/settings.ini"
  local isgtkdark

  show_header "Setting global dark theme for gtk applications."
  mkdir -p "$(dirname "${gtksettings}")"
  if [ -f "${gtksettings}" ]; then
    if grep -q ^gtk-application-prefer-dark-theme= "${gtksettings}"; then
      isgtkdark=$(sed -n 's/^gtk-application-prefer-dark-theme\s*=\s*\(.*\)\s*/\1/p' "${gtksettings}")
      if test "${isgtkdark}"; then
        show_info "Desktop is already set to use dark GTK variants."
      else
        sed -i "s/^gtk-application-prefer-dark-theme=${isgtkdark}$/gtk-application-prefer-dark-theme=1/g" "${gtksettings}"
      fi
    else
      if grep -q "^\[Settings\]" "${gtksettings}"; then
        sed -i "/^\[Settings\]/a gtk-application-prefer-dark-theme=1" "${gtksettings}"
      else
        cat >>"${gtksettings}" <<EOF

[Settings]
gtk-application-prefer-dark-theme=1
EOF
      fi
    fi
  else
    cat >"${gtksettings}" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
EOF
  fi
}

function set_lightdm_theme {
  local lightdmgtkconf="/etc/lightdm/lightdm-gtk-greeter.conf"
  if pacman -Qi lightdm-gtk-greeter >/dev/null 2>&1; then
    show_header "Setting LightDM login GTK theme to ${GTKTHEME@Q}."
    sudo sed -i "s/^#theme-name=$/theme-name=/g" ${lightdmgtkconf}
    sudo sed -i "s/^theme-name=.*/theme-name=${GTKTHEME}/g" ${lightdmgtkconf}
    sudo sed -i "s/^#icon-theme-name=$/icon-theme-name=/g" ${lightdmgtkconf}
    sudo sed -i "s/^icon-theme-name=.*$/icon-theme-name=${ICONTHEME}/g" ${lightdmgtkconf}
    if [[ "${FONT}" == "Noto" ]]; then
      if pacman -Qi noto-fonts >/dev/null 2>&1; then
        sudo sed -i "s/^#font-name=$/font-name=/g" ${lightdmgtkconf}
        sudo sed -i "s/^font-name=.*/font-name=Noto Sans/g" ${lightdmgtkconf}
      fi
    elif [[ "${FONT}" == "Roboto" ]]; then
      if pacman -Qi ttf-roboto >/dev/null 2>&1; then
        sudo sed -i "s/^#font-name=$/font-name=/g" ${lightdmgtkconf}
        sudo sed -i "s/^font-name=.*/font-name=Roboto/g" ${lightdmgtkconf}
      fi
    fi
    sudo sed -i "s/^#xft-hintstyle=$/xft-hintstyle=/g" ${lightdmgtkconf}
    sudo sed -i "s/^xft-hintstyle=.*$/xft-hintstyle=slight/g" ${lightdmgtkconf}
  else
    show_warning "LightDM GTK greeter not installed. Skipping."
  fi
}

function install_ligthdm() {
  local lightdmconf="/etc/lightdm/lightdm.conf"

  show_info "Setting up LightDM greeter."
  sudo sed -i \
    "s/^#greeter-hide-users=false/greeter-hide-users=false/g" \
    "${lightdmconf}"
  sudo sed -i \
    "s/^#greeter-session=.*/greeter-session=lightdm-gtk-greeter/g" \
    "${lightdmconf}"

  if [ -f /etc/systemd/system/display-manager.service ]; then
    if [[ "$(systemctl is-active lightdm)" = inactive ]]; then
      local display_manager
      display_manager="$(readlink -f /etc/systemd/system/display-manager.service)"
      display_manager="${display_manager##*/}"
      show_warning "Display manager already set to ${display_manager@Q}. Skipping LightDM."
    fi
  else
    sudo systemctl enable lightdm.service
  fi
}

function set_theme() {
  local fehbg_conf="${DIR}/dotfiles/.fehbg"
  local wallpaper="${DIR}/dotfiles/wallpaper.jpg"
  local avatar="${DIR}/dotfiles/avatar.png"
  local lightdm_gtk_conf="${DIR}/dotfiles/lightdm-gtk-greeter.conf"
  local lightdmconf="/etc/lightdm/lightdm-gtk-greeter.conf"

  sudo mkdir -p /usr/share/backgrounds/
  sudo mkdir -p /usr/share/avatars/

  sudo cp -f "${wallpaper}" /usr/share/backgrounds/
  sudo cp -f "${avatar}" /usr/share/avatars/

  show_info "Setting up LightDM greeter."

  if [ -f /etc/systemd/system/display-manager.service ]; then
    if [[ "$(systemctl is-active lightdm)" = inactive ]]; then
      local display_manager
      display_manager="$(readlink -f /etc/systemd/system/display-manager.service)"
      display_manager="${display_manager##*/}"
      show_warning "Display manager already set to ${display_manager@Q}. Skipping LightDM."
    fi
  else
    sudo systemctl enable lightdm.service
  fi

  copy_config_file "${fehbg_conf}" "${HOME}/.fehbg"
  sudo cp -f "${lightdm_gtk_conf}" "${lightdmconf}"
}

function set_keyboard() {
  local sypaptics_conf="${DIR}/dotfiles/70-synaptics.conf"
  local keyboard_conf="${DIR}/dotfiles/00-keyboard.conf"

  sudo pacman -S xorg-setxkbmap

  # setxkbmap -layout us -variant altgr-intl, -option grp:win_space_toggle

  show_header "Setting Keyboard"
  sudo cp -f "${sypaptics_conf}" "/etc/X11/xorg.conf.d/70-synaptics.conf"
  sudo cp -f "${keyboard_conf}" "/etc/X11/xorg.conf.d/00-keyboard.conf"

}

function install_bspwm_deps() {
  show_header "Installing necesaries dependencies"
  local basis_deps="$DIR/packages/basis.list"
  check_installed "${basis_deps}"
  pacman -S --needed --noconfirm bspwm sxhkd
  show_success "installed openbox dependices"
}

function set_config_files() {
  local bspwm_conf="$DIR/dotfiles/bspwm"

  if ! test ${DESKTOP_SESSION+x}; then
    export DESKTOP_SESSION="bspwm"
  fi

  show_info "Coping config file"
  cp -r "${bspwm_conf}" "${HOME}/.config/"
  copy_files "${DIR}/dotfiles/.bashrc" "${HOME}/"

  show_success "openbox installed successfuly"
}

function install_bspwm() {
  install_bspwm_deps
  install_aur_deps
  install_fonts
  install_bluetooth
  set_theme
  set_keyboard
  set_config_files
  install_ligthdm
  set_dark_gtk
}
