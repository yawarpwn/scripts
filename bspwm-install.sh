#!/bin/bash

DIR="$(dirname "$0")"

function main_run() {
  local packages=(rofi polybar)
  local bspwm_files="${DIR}/bspwm"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  echo "copy config file"
  cp -r "${bspwm_files}" "${HOME}/.config/"

}

main_run
