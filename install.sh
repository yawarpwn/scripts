#!/bin/bash

DIR="$(dirname "$0")"
##
# Source the utils
##
. "$DIR"/utils.sh
. "$DIR"/functions.sh
. "$DIR"/openbox.sh

function main() {
  show_question "Select an option:"
  show_info "Main (Hit ENTER to see options again.)"
  local options=(
    "Quit"
    "Essential"
    "Dev"
    "Aur"
    "Printer"
    "Fonts"
    "Network"
    "Plymouth"
    "Install Zsh"
    "Openbox")

  select option in "${options[@]}"; do
    case "${option}" in
    "Quit")
      show_success "I hope this was as fun for you as it was for me."
      break
      ;;
    "Essential")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_essential
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;
    "Dev")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_deps
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;
    "Aur")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_aur_deps
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Fonts")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_fonts
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;
    "Printer")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_printer
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Network")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_network
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Plymouth")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_plymouth
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Install Zsh")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_zsh
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Openbox")
      install_openbox
      ;;
    *)
      show_warning "Invalid option."
      ;;
    esac
  done

}

# Check permissions and network. before
# check_root
# check_network

main
