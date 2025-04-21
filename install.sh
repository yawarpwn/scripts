#!/bin/bash

DIR="$(dirname "$0")"
##
# Source the utils
##
. "$DIR"/utils.sh
. "$DIR"/functions.sh
. "$DIR"/openbox.sh
. "$DIR"/bspwm.sh

function main() {
  show_question "Select an option:"
  show_info "Main (Hit ENTER to see options again.)"
  local options=(
    "Quit"
    "Install Bspwm"
    "Install Openbox"
    "Install Dev Dependencies"
    "Printer"
    "Plymouth"
  )

  select option in "${options[@]}"; do
    case "${option}" in
    "Quit")
      show_success "I hope this was as fun for you as it was for me."
      break
      ;;
    "Install Bspwm")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_bspwm
      fi

      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Install Openbox")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_openbox
      fi
      show_info "Main (Hit ENTER to see options again.)"
      ;;

    "Install Dev Dependencies")
      install_developer_deps
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

    "Plymouth")
      local response
      response=$(ask_question "Are you sure? (y/N)")
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        install_plymouth
      fi

      show_info "Main (Hit ENTER to see options again.)"
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
