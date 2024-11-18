function install_openbox {
  local cinnamon="${DIR}/packages/cinnamon.list"
  local lightdmconf="/etc/lightdm/lightdm.conf"
  local gammastepini="${DIR}/configs/gammastep.ini"
  local xdgdefaultconf="/etc/xdg/user-dirs.defaults"

  show_header "Setting up cinnamon desktop environment."
  check_installed "${cinnamon}"
  show_success "Cinnamon installed."

  if ! test ${DESKTOP_SESSION+x}; then
    export DESKTOP_SESSION="cinnamon"
  fi

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

  # Get latitude and longitude using GeoClue2 for Gammastep.
  show_info "Setting Gammastep config."
  if [ -e /usr/lib/geoclue-2.0/demos/where-am-i ]; then
    mkdir -p "${HOME}/.config/gammastep"
    local tmp
    local lat
    local lon
    if tmp="$(/usr/lib/geoclue-2.0/demos/where-am-i -t 10 -a 4)"; then
      lat="$(echo "${tmp}" | sed -n "s/.*Latitude: \+\([-0-9\.]\+\)°\?.*/\1/p")"
      lon="$(echo "${tmp}" | sed -n "s/.*Longitude: \+\([-0-9\.]\+\)°\?.*/\1/p")"
      sed -e "s,^lat=.*,lat=${lat},g" -e "s,^lon=.*,lon=${lon},g" \
        "${gammastepini}" >"${HOME}/.config/gammastep/config.ini"
    else
      show_warning "Parsing latitude/longitude failed. Defaulting to NYC."
      cp "${gammastepini}" "${HOME}/.config/gammastep/config.ini"
    fi
  else
    show_warning "Geoclue 'where-am-i' demo not found. Defaulting to NYC."
    cp "${gammastepini}" "${HOME}/.config/gammastep/config.ini"
  fi

  show_info "Setting kitty as default terminal."
  gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'

  show_info "Creating Projects/ and Sync/ and setting gvfs icon metadata."
  mkdir -p "${HOME}/Projects"
  mkdir -p "${HOME}/Sync"
  gio set "${HOME}/Projects/" -t string metadata::custom-icon-name folder-development
  gio set "${HOME}/Sync/" -t string metadata::custom-icon-name folder-cloud

  show_info "Disabling Templates/ and Public/ directories."
  sudo sed -i "s/^TEMPLATES/#TEMPLATES/g" "${xdgdefaultconf}"
  sudo sed -i "s/^PUBLICSHARE/#PUBLICSHARE/g" "${xdgdefaultconf}"
  [ -d "${HOME}/Templates" ] && rmdir --ignore-fail-on-non-empty "${HOME}/Templates"
  [ -d "${HOME}/Public" ] && rmdir --ignore-fail-on-non-empty "${HOME}/Public"
  xdg-user-dirs-update
}

function set_bash_shell {
  local bashrc="${DIR}/dotfiles/bashrc"
  local bashprofile="${DIR}/dotfiles/bash_profile"

  if ! command -v bash >/dev/null 2>&1; then
    show_warning "bash not installed. Skipping."
    return
  fi

  if ! grep -q "bash" <(getent passwd "$(whoami)"); then
    show_info "Changing login shell to Bash. Provide your password."
    chsh -s /bin/bash
  else
    show_info "Default shell already set to bash."
  fi

  copy_config_file "${bashprofile}" "${HOME}/.bash_profile"
  copy_config_file "${bashrc}" "${HOME}/.bashrc"
}

function disable_pulseaudio_suspend {
  local pulseconfig="/etc/pulse/default.pa"
  show_header "Disabling suspend on PulseAudio when sinks/sources idle."
  if [ -f ${pulseconfig} ]; then
    sudo sed -i "s/^load-module module-suspend-on-idle$/#load-module module-suspend-on-idle/g" ${pulseconfig}
  else
    show_warning "PulseAudio config file missing. Skipping."
  fi
}

function select_gtk_theme {
  show_question "Select a GTK theme:"

  local options=(
    "Back"
    "Adwaita"
    "Adwaita-dark"
    "Arc"
    "Arc-Darker"
    "Arc-Dark"
    "Arc-Lighter"
    "Adapta"
    "Adapta-Eta"
    "Adapta-Nokto"
    "Adapta-Nokto-Eta"
    "Materia"
    "Materia-compact"
    "Materia-dark"
    "Materia-dark-compact"
    "Materia-light"
    "Materia-light-compact"
    "Plata"
    "Plata-Compact"
    "Plata-Lumine"
    "Plata-Lumine-Compact"
    "Plata-Noir"
    "Plata-Noir-Compact")
  local option
  select option in "${options[@]}"; do
    case "${option}" in
    "Back")
      return
      ;;
    "Adwaita")
      if [ -d /usr/share/themes/Adwaita ]; then
        GTKTHEME="Adwaita"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Adwaita-dark")
      if [ -d /usr/share/themes/Adwaita-dark ]; then
        GTKTHEME="Adwaita-dark"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Arc")
      if [ -d /usr/share/themes/Arc ] ||
        [ -d /usr/local/share/themes/Arc ] ||
        [ -d "${HOME}/.local/share/themes/Arc" ] ||
        [ -d "${HOME}/.themes/Arc" ]; then
        GTKTHEME="Arc"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Arc-Darker")
      if [ -d /usr/share/themes/Arc-Darker ] ||
        [ -d /usr/local/share/themes/Arc-Darker ] ||
        [ -d "${HOME}/.local/share/themes/Arc-Darker" ] ||
        [ -d "${HOME}/.themes/Arc-Darker" ]; then
        GTKTHEME="Arc-Darker"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Arc-Dark")
      if [ -d /usr/share/themes/Arc-Dark ] ||
        [ -d /usr/local/share/themes/Arc-Dark ] ||
        [ -d "${HOME}/.local/share/themes/Arc-Dark" ] ||
        [ -d "${HOME}/.themes/Arc-Dark" ]; then
        GTKTHEME="Arc-Dark"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Arc-Lighter")
      if [ -d /usr/share/themes/Arc-Lighter ] ||
        [ -d /usr/local/share/themes/Arc-Lighter ] ||
        [ -d "${HOME}/.local/share/themes/Arc-Lighter" ] ||
        [ -d "${HOME}/.themes/Arc-Lighter" ]; then
        GTKTHEME="Arc-Lighter"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Adapta")
      if [ -d /usr/share/themes/Adapta ] ||
        [ -d /usr/local/share/themes/Adapta ] ||
        [ -d "${HOME}/.local/share/themes/Adapta" ] ||
        [ -d "${HOME}/.themes/Adapta" ]; then
        GTKTHEME="Adapta"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Adapta-Eta")
      if [ -d /usr/share/themes/Adapta-Eta ] ||
        [ -d /usr/local/share/themes/Adapta-Eta ] ||
        [ -d "${HOME}/.local/share/themes/Adapta-Eta" ] ||
        [ -d "${HOME}/.themes/Adapta-Eta" ]; then
        GTKTHEME="Adapta-Eta"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Adapta-Nokto")
      if [ -d /usr/share/themes/Adapta-Nokto ] ||
        [ -d /usr/local/share/themes/Adapta-Nokto ] ||
        [ -d "${HOME}/.local/share/themes/Adapta-Nokto" ] ||
        [ -d "${HOME}/.themes/Adapta-Nokto" ]; then
        GTKTHEME="Adapta-Nokto"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Adapta-Nokto-Eta")
      if [ -d /usr/share/themes/Adapta-Nokto-Eta ] ||
        [ -d /usr/local/share/themes/Adapta-Nokto-Eta ] ||
        [ -d "${HOME}/.local/share/themes/Adapta-Nokto-Eta" ] ||
        [ -d "${HOME}/.themes/Adapta-Nokto-Eta" ]; then
        GTKTHEME="Adapta-Nokto-Eta"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia")
      if [ -d /usr/share/themes/Materia ] ||
        [ -d /usr/local/share/themes/Materia ] ||
        [ -d "${HOME}/.local/share/themes/Materia" ] ||
        [ -d "${HOME}/.themes/Materia" ]; then
        GTKTHEME="Materia"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia-compact")
      if [ -d /usr/share/themes/Materia-compact ] ||
        [ -d /usr/local/share/themes/Materia-compact ] ||
        [ -d "${HOME}/.local/share/themes/Materia-compact" ] ||
        [ -d "${HOME}/.themes/Materia-compact" ]; then
        GTKTHEME="Materia-compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia-light")
      if [ -d /usr/share/themes/Materia-light ] ||
        [ -d /usr/local/share/themes/Materia-light ] ||
        [ -d "${HOME}/.local/share/themes/Materia-light" ] ||
        [ -d "${HOME}/.themes/Materia-light" ]; then
        GTKTHEME="Materia-light"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia-light-compact")
      if [ -d /usr/share/themes/Materia-light-compact ] ||
        [ -d /usr/local/share/themes/Materia-light-compact ] ||
        [ -d "${HOME}/.local/share/themes/Materia-light-compact" ] ||
        [ -d "${HOME}/.themes/Materia-light-compact" ]; then
        GTKTHEME="Materia-light-compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia-dark")
      if [ -d /usr/share/themes/Materia-dark ] ||
        [ -d /usr/local/share/themes/Materia-dark ] ||
        [ -d "${HOME}/.local/share/themes/Materia-dark" ] ||
        [ -d "${HOME}/.themes/Materia-dark" ]; then
        GTKTHEME="Materia-dark"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Materia-dark-compact")
      if [ -d /usr/share/themes/Materia-dark-compact ] ||
        [ -d /usr/local/share/themes/Materia-dark-compact ] ||
        [ -d "${HOME}/.local/share/themes/Materia-dark-compact" ] ||
        [ -d "${HOME}/.themes/Materia-dark-compact" ]; then
        GTKTHEME="Materia-dark-compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata")
      if [ -d /usr/share/themes/Plata ] ||
        [ -d /usr/local/share/themes/Plata ] ||
        [ -d "${HOME}/.local/share/themes/Plata" ] ||
        [ -d "${HOME}/.themes/Plata" ]; then
        GTKTHEME="Plata"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata-Compact")
      if [ -d /usr/share/themes/Plata-Compact ] ||
        [ -d /usr/local/share/themes/Plata-Compact ] ||
        [ -d "${HOME}/.local/share/themes/Plata-Compact" ] ||
        [ -d "${HOME}/.themes/Plata-Compact" ]; then
        GTKTHEME="Plata-Compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata-Lumine")
      if [ -d /usr/share/themes/Plata-Lumine ] ||
        [ -d /usr/local/share/themes/Plata-Lumine ] ||
        [ -d "${HOME}/.local/share/themes/Plata-Lumine" ] ||
        [ -d "${HOME}/.themes/Plata-Lumine" ]; then
        GTKTHEME="Plata-Lumine"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata-Lumine-Compact")
      if [ -d /usr/share/themes/Plata-Lumine-Compact ] ||
        [ -d /usr/local/share/themes/Plata-Lumine-Compact ] ||
        [ -d "${HOME}/.local/share/themes/Plata-Lumine-Compact" ] ||
        [ -d "${HOME}/.themes/Plata-Lumine-Compact" ]; then
        GTKTHEME="Plata-Lumine-Compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata-Noir")
      if [ -d /usr/share/themes/Plata-Noir ] ||
        [ -d /usr/local/share/themes/Plata-Noir ] ||
        [ -d "${HOME}/.local/share/themes/Plata-Noir" ] ||
        [ -d "${HOME}/.themes/Plata-Noir" ]; then
        GTKTHEME="Plata-Noir"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    "Plata-Noir-Compact")
      if [ -d /usr/share/themes/Plata-Noir-Compact ] ||
        [ -d /usr/local/share/themes/Plata-Noir-Compact ] ||
        [ -d "${HOME}/.local/share/themes/Plata-Noir-Compact" ] ||
        [ -d "${HOME}/.themes/Plata-Noir-Compact" ]; then
        GTKTHEME="Plata-Noir-Compact"
        break
      else
        show_warning "${option@Q} theme is not installed."
      fi
      ;;
    *)
      show_warning "Invalid option ${option@Q}."
      ;;
    esac
  done

  set_gtk_theme
  set_lightdm_theme
  set_gdm_theme
}

function select_icon_theme {
  show_question "Select an icon theme:"

  local options=(
    "Back"
    "Adwaita"
    "Breeze"
    "Breeze-Dark"
    "Papirus"
    "ePapirus"
    "ePapirus-Dark"
    "Papirus-Light"
    "Papirus-Dark"
    "Papirus-Adapta"
    "Papirus-Adapta-Nokto")
  local option
  select option in "${options[@]}"; do
    case "${option}" in
    "Back")
      return
      ;;
    "Adwaita")
      if [ -d /usr/share/icons/Adwaita ]; then
        ICONTHEME="Adwaita"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Breeze")
      if [ -d /usr/share/icons/breeze ]; then
        ICONTHEME="breeze"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Breeze-Dark")
      if [ -d /usr/share/icons/breeze-dark ]; then
        ICONTHEME="breeze-dark"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Papirus")
      if [ -d /usr/share/icons/Papirus ] ||
        [ -d /usr/local/share/icons/Papirus ] ||
        [ -d "${HOME}/.local/share/icons/Papirus" ] ||
        [ -d "${HOME}/.icons/Papirus" ]; then
        ICONTHEME="Papirus"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "ePapirus")
      if [ -d /usr/share/icons/ePapirus ] ||
        [ -d /usr/local/share/icons/ePapirus ] ||
        [ -d "${HOME}/.local/share/icons/ePapirus" ] ||
        [ -d "${HOME}/.icons/ePapirus" ]; then
        ICONTHEME="ePapirus"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "ePapirus-Dark")
      if [ -d /usr/share/icons/ePapirus-Dark ] ||
        [ -d /usr/local/share/icons/ePapirus-Dark ] ||
        [ -d "${HOME}/.local/share/icons/ePapirus-Dark" ] ||
        [ -d "${HOME}/.icons/ePapirus-Dark" ]; then
        ICONTHEME="ePapirus-Dark"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Papirus-Light")
      if [ -d /usr/share/icons/Papirus-Light ] ||
        [ -d /usr/local/share/icons/Papirus-Light ] ||
        [ -d "${HOME}/.local/share/icons/Papirus-Light" ] ||
        [ -d "${HOME}/.icons/Papirus-Light" ]; then
        ICONTHEME="Papirus-Light"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Papirus-Dark")
      if [ -d /usr/share/icons/Papirus-Dark ] ||
        [ -d /usr/local/share/icons/Papirus-Dark ] ||
        [ -d "${HOME}/.local/share/icons/Papirus-Dark" ] ||
        [ -d "${HOME}/.icons/Papirus-Dark" ]; then
        ICONTHEME="Papirus-Dark"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Papirus-Adapta")
      if [ -d /usr/share/icons/Papirus-Adapta ] ||
        [ -d /usr/local/share/icons/Papirus-Adapta ] ||
        [ -d "${HOME}/.local/share/icons/Papirus-Adapta" ] ||
        [ -d "${HOME}/.icons/Papirus-Adapta" ]; then
        ICONTHEME="Papirus-Adapta"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    "Papirus-Adapta-Nokto")
      if [ -d /usr/share/icons/Papirus-Adapta-Nokto ] ||
        [ -d /usr/local/share/icons/Papirus-Adapta-Nokto ] ||
        [ -d "${HOME}/.local/share/icons/Papirus-Adapta-Nokto" ] ||
        [ -d "${HOME}/.icons/Papirus-Adapta-Nokto" ]; then
        ICONTHEME="Papirus-Adapta-Nokto"
        break
      else
        show_warning "${option@Q} icons are not installed."
      fi
      ;;
    *)
      show_warning "Invalid option ${option@Q}."
      ;;
    esac
  done

  set_icon_theme
  set_lightdm_theme
}

function set_gdm_theme {
  local gtkthemedir
  if pacman -Qi gdm >/dev/null 2>&1; then
    if [[ -d "/usr/local/share/themes/${GTKTHEME}" ]]; then
      gtkthemedir="/usr/local/share/themes/${GTKTHEME}"
    elif [[ -d "${HOME}/.local/share/themes/${GTKTHEME}" ]]; then
      gtkthemedir="${HOME}/.local/share/themes/${GTKTHEME}"
    elif [[ -d "${HOME}/.themes/${GTKTHEME}" ]]; then
      gtkthemedir="${HOME}/.themes/${GTKTHEME}"
    elif [[ -d "/usr/share/themes/${GTKTHEME}" ]]; then
      gtkthemedir="/usr/share/themes/${GTKTHEME}"
    else
      show_warning "GTK theme ${GTKTHEME@Q} not found. Skipping."
      return
    fi
    show_header "Setting GDM login theme to ${GTKTHEME@Q}."
    sudo cp -r "/usr/share/gnome-shell" "/usr/share/gnome-shell-$(date +%Y%m%d-%H%M%S)"
    if [[ "${GTKTHEME}" =~ ^Adapta ]] || [[ "${GTKTHEME}" =~ ^Plata ]]; then
      sudo cp -rf \
        "${gtkthemedir}"/gnome-shell/* \
        /usr/share/gnome-shell/
      sudo cp -f \
        "${gtkthemedir}"/gnome-shell/extensions/window-list/classic.css \
        /usr/share/gnome-shell/extensions/window-list@gnome-shell-extensions.gcampax.github.com/
      sudo cp -f \
        "${gtkthemedir}"/gnome-shell/extensions/window-list/stylesheet.css \
        /usr/share/gnome-shell/extensions/window-list@gnome-shell-extensions.gcampax.github.com/
    elif [[ "${GTKTHEME}" =~ ^Materia ]]; then
      sudo glib-compile-resources \
        --target="/usr/share/gnome-shell/gnome-shell-theme.gresource" \
        --sourcedir="${gtkthemedir}/gnome-shell" \
        "${gtkthemedir}/gnome-shell/gnome-shell-theme.gresource.xml"
    elif [[ "${GTKTHEME}" =~ ^Arc ]]; then
      if [[ "${GTKTHEME}" =~ Dark ]]; then
        if [ -f "${gtkthemedir}/gnome-shell/gnome-shell-theme-dark.gresource" ]; then
          sudo cp -f "${gtkthemedir}/gnome-shell/gnome-shell-theme-dark.gresource" \
            "/usr/share/gnome-shell/gnome-shell-theme.gresource"
        fi
      else
        if [ -f "${gtkthemedir}/gnome-shell/gnome-shell-theme.gresource" ]; then
          sudo cp -f "${gtkthemedir}/gnome-shell/gnome-shell-theme.gresource" \
            "/usr/share/gnome-shell/gnome-shell-theme.gresource"
        fi
      fi
    elif [[ "${GTKTHEME}" =~ ^Adwaita ]]; then
      show_info "Reinstalling GNOME-shell to reset theme files."
      sudo pacman -S --noconfirm gnome-shell gnome-shell-extensions
    else
      show_warning "${GTKTHEME@Q} theme for GDM is unsupported."
    fi
  else
    show_warning "GDM is not installed. Skipping."
  fi
}

function set_sddm_theme {
  local sddmconf="/etc/sddm.conf.d/kde_settings.conf"
  local sddmtheme
  if [[ "${PLASMATHEME}" =~ ^breeze ]]; then
    sddmtheme=breeze
  else
    sddmtheme=${PLASMATHEME}
  fi
  if pacman -Qi sddm >/dev/null 2>&1; then
    if [ -d "/usr/share/sddm/themes/${sddmtheme}" ]; then
      show_header "Setting SDDM login theme to ${sddmtheme@Q}."
      local kwconfig
      if kwconfig="$(_get_kwrite_config)"; then
        sudo "${kwconfig}" --file "${sddmconf}" --group Theme --key Current "${sddmtheme}"
        if [[ "${sddmtheme}" = breeze ]]; then
          sudo "${kwconfig}" --file "${sddmconf}" --group Theme --key CursorTheme "breeze_cursors"
        fi
        case "${FONT}" in
        Noto)
          if pacman -Qi noto-fonts >/dev/null 2>&1; then
            sudo "${kwconfig}" --file "${sddmconf}" --group Theme --key Font "Noto Sans,10,-1,5,50,0,0,0,0,0"
          fi
          ;;
        Roboto)
          if pacman -Qi ttf-roboto >/dev/null 2>&1; then
            sudo "${kwconfig}" --file "${sddmconf}" --group Theme --key Font "Roboto,10,-1,5,50,0,0,0,0,0"
          fi
          ;;
        *) ;;
        esac
      fi
    else
      show_warning "SDDM theme for ${PLASMATHEME@Q} not found. Skipping."
    fi
  else
    show_warning "SDDM not installed. Skipping."
  fi
}

function set_gtk_theme {
  if pacman -Qi cinnamon >/dev/null 2>&1; then
    show_info "Setting Cinnamon GTK theme to ${GTKTHEME@Q}."
    gsettings set org.cinnamon.desktop.interface gtk-theme "'${GTKTHEME}'"
    if [[ "${GTKTHEME}" =~ -Eta$ ]]; then
      gsettings set org.cinnamon.theme name "'${GTKTHEME%-*}'"
      gsettings set org.cinnamon.desktop.wm.preferences theme "'${GTKTHEME}'"
    elif [[ "${GTKTHEME}" =~ -Compact$ ]]; then
      gsettings set org.cinnamon.theme name "'${GTKTHEME%-*}'"
      gsettings set org.cinnamon.desktop.wm.preferences theme "'${GTKTHEME}'"
    elif [[ "${GTKTHEME}" =~ -Darker$ ]]; then
      gsettings set org.cinnamon.theme name "'${GTKTHEME%er}'"
    else
      gsettings set org.cinnamon.theme name "'${GTKTHEME}'"
    fi
  fi

  if pacman -Qi gnome-shell >/dev/null 2>&1; then
    show_info "Setting GNOME GTK theme to ${GTKTHEME@Q}."
    gsettings set org.gnome.desktop.wm.preferences theme "'${GTKTHEME}'"
    if [[ "${GTKTHEME,,}" =~ dark ]]; then
      gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
    else
      gsettings set org.gnome.desktop.interface color-scheme "'default'"
    fi
    gsettings set org.gnome.desktop.interface gtk-theme "'${GTKTHEME}'"
    gnome-extensions enable "user-theme@gnome-shell-extensions.gcampax.github.com" || true
    gsettings set org.gnome.shell.extensions.user-theme name "'${GTKTHEME}'"
  fi

  if pacman -Qi plasma-desktop >/dev/null 2>&1; then
    show_info "Setting Plasma GTK theme to ${GTKTHEME@Q}."
    local qdb
    if qdb="$(_get_qdbus)"; then
      if "${qdb}" org.kde.KWin >/dev/null; then
        "${qdb}" org.kde.KWin /KWin reconfigure
      fi
    fi
  fi

  set_config_key_value "${HOME}/.xprofile" "export GTK_THEME" "${GTKTHEME}"
  set_config_key_value \
    "${HOME}/.config/environment.d/envvars.conf" "GTK_THEME" "${GTKTHEME}"
}
