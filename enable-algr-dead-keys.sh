# steps for enable AltGr with dead keys
sudo pacman -S xorg-setxkbmap

# setxkbmap -layout us,us_intl -variant altgr-intl, -option grp:alt_shift_toggle

# temporal change
setxkbmap -layout us -variant altgr-intl

# Create or edit the Xorg configuration file:
sudo touch /etc/X11/xorg.conf.d/00-keyboard.conf

#  Section "InputClass"
#     Identifier "system-keyboard"
#     MatchIsKeyboard "on"
#     Option "XkbLayout" "us"
#     Option "XkbVariant" "altgr-intl"
# EndSection

# You can also use localectl to set the layout system-wide:
sudo localectl set-x11-keymap us pc105 altgr-intl
