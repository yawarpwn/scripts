#!/bin/bash

DIR="$(dirname "$0")"
##
# Source the utils
##
. "$DIR"/utils.sh
. "$DIR"/functions.sh

function main() {
  echo "Installing dependencies..."
  check_installed "${DIR}/packages/essential.list"
  install_fonts
  install_aur_deps
}

Check permissions and network. before
check_root
check_network

main
