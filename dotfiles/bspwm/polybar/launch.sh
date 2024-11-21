#!/bin/bash

DIR="$HOME/.config/bspwm/polybar"
SFILE="$DIR/system.ini"
RFILE="$DIR/.system"

## Get system variable values for various modules
get_values() {
  CARD=$(light -L | grep 'backlight' | head -n1 | cut -d'/' -f3)
  BATTERY=$(upower -i $(upower -e | grep 'BAT') | grep 'native-path' | cut -d':' -f2 | tr -d '[:blank:]')
  ADAPTER=$(upower -i $(upower -e | grep 'AC') | grep 'native-path' | cut -d':' -f2 | tr -d '[:blank:]')
  INTERFACE=$(ip link | awk '/state UP/ {print $2}' | tr -d :)
}

## Write values to `system.ini` file
set_values() {
  if [[ "$ADAPTER" ]]; then
    sed -i -e "s/sys_adapter = .*/sys_adapter = $ADAPTER/g" ${SFILE}
  fi
  if [[ "$BATTERY" ]]; then
    sed -i -e "s/sys_battery = .*/sys_battery = $BATTERY/g" ${SFILE}
  fi
  if [[ "$CARD" ]]; then
    sed -i -e "s/sys_graphics_card = .*/sys_graphics_card = $CARD/g" ${SFILE}
  fi
  if [[ "$INTERFACE" ]]; then
    sed -i -e "s/sys_network_interface = .*/sys_network_interface = $INTERFACE/g" ${SFILE}
  fi
}

launch_bar() {
  # Terminate already running bar instances
  killall -q polybar

  # # Wait until the processes have been shut down
  # while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
  #
  # # Launch the bar
  # for mon in $(polybar --list-monitors | cut -d":" -f1); do
  #   MONITOR=$mon polybar -q main -c "$HOME"/.config/polybar/config.ini &
  # done
  polybar -c "$HOME/.config/bspwm/polybar/config.ini" &
}

# Execute functions
if [[ ! -f "$RFILE" ]]; then
  get_values
  echo "Battery:$BATTERY Adapter:$ADAPTER Card:$CARD Interface:$INTERFACE"
  set_values
  touch ${RFILE}
fi

launch_bar
