#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/functions.sh"
. "$DIR/utils.sh"

function install_bspwm() {
  local bspwm_list="${DIR}/packages/bspwm.list"
  check_installed "${bspwm_list}"
}
