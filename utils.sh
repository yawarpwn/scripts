#
# Fancy color output
#

show_error() {
  local red=$'\033[0;91m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${red}${*:2}${nc}" 1>&2
  else
    echo -e "${red}${*}${nc}" 1>&2
  fi
}
export -f show_error

show_info() {
  local green=$'\033[0;92m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${green}${*:2}${nc}"
  else
    echo -e "${green}${*}${nc}"
  fi
}
export -f show_info

show_warning() {
  local yellow=$'\033[0;93m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${yellow}${*:2}${nc}"
  else
    echo -e "${yellow}${*}${nc}"
  fi
}
export -f show_warning

show_question() {
  local blue=$'\033[0;94m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${blue}${*:2}${nc}"
  else
    echo -e "${blue}${*}${nc}"
  fi
}
export -f show_question

ask_question() {
  local blue=$'\033[0;94m'
  local nc=$'\033[0m'
  local var
  read -r -p "${blue}$*${nc} " var
  echo "${var}"
}
export -f ask_question

ask_secret() {
  local blue=$'\033[0;94m'
  local nc=$'\033[0m'
  local var
  stty -echo echonl
  read -r -p "${blue}$*${nc} " var
  stty echo -echonl
  echo "${var}"
}
export -f ask_secret

show_success() {
  local purple=$'\033[0;95m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${purple}${*:2}${nc}"
  else
    echo -e "${purple}${*}${nc}"
  fi
}
export -f show_success

show_header() {
  local cyan=$'\033[0;96m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${cyan}${*:2}${nc}"
  else
    echo -e "${cyan}${*}${nc}"
  fi
}
export -f show_header

show_listitem() {
  local white=$'\033[0;97m'
  local nc=$'\033[0m'
  if [[ "${1:--e}" =~ ^(-e|-n)$ ]]; then
    echo "${1:--e}" "${white}${*:2}${nc}"
  else
    echo -e "${white}${*}${nc}"
  fi
}
export -f show_listitem

##
# Utility functions
##

function check_user {
  if [ ${EUID} -eq 0 ]; then
    show_error "Do not run this script as root. Exiting."
    exit 1
  fi
}

function check_root {
  if [ ${EUID} -eq 0 ]; then
    show_info "I am root."
  else
    show_error "I need to be root."
    exit 1
  fi
}

function check_installed {
  local metacount
  local installcount
  local package
  local to_install=()
  while read -r package; do
    [ -z "${package}" ] && continue

    metacount=$(pacman -Ss "${package}" |
      grep -c "(.*${package}.*)" || true)
    installcount=$(pacman -Qs "${package}" |
      grep -c "^local.*(.*${package}.*)$" || true)

    # Check if package is installed.
    if pacman -Qi "${package}" >/dev/null 2>&1; then
      show_listitem "${package@Q} package already installed. Skipping."

    # pacman -Qi won't work with meta packages, so check if all meta package
    # members are installed instead.
    elif [[ (${installcount} -eq ${metacount}) && ! (${installcount} -eq 0) ]]; then
      show_listitem "${package@Q} meta-package already installed. Skipping."

    # Runs if package is not installed or all members of meta-package are not
    # installed.
    else
      to_install+=("${package}")
    fi
  done <"${1}"
  if [[ -v to_install ]]; then
    sudo pacman -S --ask 4 --noconfirm "${to_install[@]}"
  fi
}

function check_aur_installed {
  local pkgbuilddir="${HOME}/.pkgbuild"
  local aurprefix="https://aur.archlinux.org"
  local curdir
  local metacount
  local installcount
  local package
  curdir="$(pwd)"

  mkdir -p "${pkgbuilddir}"
  while read -r package; do
    [ -z "${package}" ] && continue

    metacount=$(pacman -Ss "${package}" |
      grep -c "(.*${package}.*)" || true)
    installcount=$(pacman -Qs "${package}" |
      grep -c "^local.*(.*${package}.*)$" || true)

    # Check if package is installed.
    if pacman -Qi "${package}" >/dev/null 2>&1; then
      show_listitem "${package@Q} package already installed. Skipping."

    # Runs if package is not installed or all members of meta-package are not
    # installed.
    else
      show_listitem "Installing ${package@Q}."
      if ! [ -d "${pkgbuilddir}/${package}" ]; then
        git clone "${aurprefix}/${package}" "${pkgbuilddir}/${package}"
      else
        git -C "${pkgbuilddir}/${package}" clean -xdf
        git -C "${pkgbuilddir}/${package}" reset --hard
        git -C "${pkgbuilddir}/${package}" pull origin master
      fi
      cd "${pkgbuilddir}/${package}" || exit
      makepkg --noconfirm -si
      git clean -xdf
    fi
  done <"${1}"
  cd "${curdir}" || exit
}

function check_sync_repos {
  local last_update

  # Check the pacman log to see if synchronized within the past hour. If so,
  # return.
  if [ -f /var/log/pacman.log ]; then
    last_update="$(grep -a "synchronizing package lists$" /var/log/pacman.log |
      tail -n 1 |
      sed -n "s/\[\(.*\)\] \[PACMAN\] .*/\1/p")"
    if [ -n "${last_update}" ]; then
      if [ "$(date --date="${last_update}" +%s)" -gt \
        "$(date --date="1 hour ago" +%s)" ]; then
        return
      fi
    fi
  fi

  sync_repos
}

function sync_repos {
  show_header "Synchronizing repos."
  if [ ${EUID} -eq 0 ]; then
    pacman -Sy
  else
    sudo pacman -Sy
  fi
}

function install_packages {
  pacman --noconfirm -S \
    base-devel \
    bash-completion \
    cryptsetup \
    curl \
    fzf \
    git \
    iwd \
    linux \
    linux-firmware \
    linux-headers \
    lsb-release \
    lvm2 \
    man-db \
    man-pages \
    networkmanager \
    pacman-contrib \
    rsync
  systemctl enable NetworkManager
}

function check_install_commands {
  local install_cmds=(
    arch-chroot
    cryptsetup
    findmnt
    fzf
    genfstab
    lvcreate
    mount
    pacstrap
    partprobe
    pvcreate
    sed
    sgdisk
    umount
    vgcreate
  )
  local c
  for c in "${install_cmds[@]}"; do
    if ! command -v "${c}" >/dev/null 2>&1; then
      return 1
    fi
  done
}

function install_post_dependencies {
  local deps="${DIR}/packages/deps.list"
  show_header "Checking post-installation dependencies."
  local package
  while read -r package; do
    if ! pacman -Qi "${package}" >/dev/null 2>&1; then
      show_info "${package@Q} is needed for this script."
      sudo pacman -S --noconfirm "${package}"
      show_success "${package@Q} now installed."
    else
      show_success "${package@Q} is already installed."
    fi
  done <"${deps}"
}

function install_dependencies {
  local install="${DIR}/packages/install.list"
  show_header "Checking installation dependencies."

  local state=true
  local exe
  while read -r exe; do
    if ! command -v "${exe}" >/dev/null; then
      state=false
    fi
  done <"${install}"
  if "${state}"; then return; fi

  pacman -Sy --noconfirm archlinux-keyring

  local package
  while read -r package; do
    if ! pacman -Qi "${package}" >/dev/null 2>&1; then
      show_info "${package@Q} is needed for this script."
      pacman -S --noconfirm "${package}"
      show_success "${package@Q} now installed."
    else
      show_success "${package@Q} is already installed."
    fi
  done <"${install}"
}

function check_network {
  show_header "Checking network connection."

  if ! command -v curl >/dev/null 2>&1; then
    show_error "curl not installed. Exiting."
    exit 1
  fi

  if curl -Is --retry 5 --retry-connrefused https://archlinux.org >/dev/null; then
    show_success "Network is working."
  else
    show_error "Cannot start network connection."
    exit 1
  fi
}

function set_config_key_value {
  local file="${1}"
  local key="${2}"
  local value="${3}"

  if [ -f "${file}" ]; then
    if grep -q "^${key}" "${file}"; then
      sed -i "s,^${key}=.*,${key}=${value},g" "${file}"
    else
      echo "${key}=${value}" >>"${file}"
    fi
  else
    show_warning "${file@Q} does not exist. Creating new."
    mkdir -p "$(dirname "${file}")"
    echo "${key}=${value}" >"${file}"
  fi
}

function copy_config_file {
  local source="${1}"
  local dest="${2}"

  if ! [ -e "${source}" ]; then
    show_error "${source@Q} not found. Exiting."
    exit 1
  fi

  show_info "Copying ${source@Q} to ${dest@Q}."
  if [ -e "${dest}" ]; then
    if ! cmp -s "${source}" "${dest}"; then
      show_info "Backing up existing ${dest@Q}."
      mv -v "${dest}" "${dest}_$(date +%Y%m%d-%k%M%S).bak"
      cp -ri "${source}" "${dest}"
    else
      show_info "${dest} already set."
    fi
  else
    mkdir -p "$(dirname "${dest}")"
    cp -ri "${source}" "${dest}"
  fi
}

function _get_kwrite_config {
  if command -v kwriteconfig6 >/dev/null; then
    echo kwriteconfig6
    return
  elif command -v kwriteconfig5 >/dev/null; then
    echo kwriteconfig5
    return
  else
    show_warning "No kwriteconfig executable found." >&2
    return 1
  fi
}

function _get_qdbus {
  if command -v qdbus6 >/dev/null; then
    echo qdbus6
    return
  elif command -v qdbus >/dev/null; then
    echo qdbus
    return
  else
    show_warning "No qdbus executable found." >&2
    return 1
  fi
}
