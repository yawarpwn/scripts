# source utils
DIR "$0"
. "$DIR/functions.sh"
. "$DIR/utils.sh"

# Globals
GTKTHEME="Adwaita-dark"
ICONTHEME="Breeze-Dark"
FONT="Roboto"

function install_theme_deps_gtk {
  local npmrc="${DIR}/dotfiles/npmrc"
  local themes="${DIR}/packages/themes.list"

  show_header "Installing theme dependencies."
  check_installed "${themes}"
  show_success "Theme dependencies installed."

  if ! [ -f "${npmrc}" ]; then
    show_info "Installing npmrc."
    cp -f "${npmrc}" "${HOME}/.npmrc"
  fi
}

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

function install_openbox() {
  local openbox_list="$DIR/packages/openbox.list"

  show_header "Installing Openbox dependencies"
  check_installed "${openbox_list}"
  show_success "installed opebox dependices"

  if ! test ${DESKTOP_SESSION+x}; then
    export DESKTOP_SESSION="openbox"
  fi

  install_fonts
  install_theme_deps_gtk
  set_dark_gtk
  install_ligthdm
  set_lightdm_theme

  show_success "openbox installed successfuly"
}
