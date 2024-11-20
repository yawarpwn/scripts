#!/bin/bash

gtk_greeter_conf="/etc/lightdm/lightdm-gtk-greeter.conf"

sudo sed -i \
  "s/^#theme-name=.*/theme-name=Adwaita-dark/g" \
  "${gtk_greeter_conf}"
sudo sed -i \
  "s/^#icon-theme-name=.*/icon-theme-name=Papirus-Dark/g" \
  "${gtk_greeter_conf}"
sudo sed -i \
  "s/^#\s*default-user-image =.*/default-user-image = \/usr\/share\/avatars\/joker-avatar.png/g" \
  "${gtk_greeter_conf}"
sudo sed -i \
  "s/^#\s*background =.*/background = \/usr\/share\/backgrounds\/wallpaper.jpg/g" \
  "${gtk_greeter_conf}"
