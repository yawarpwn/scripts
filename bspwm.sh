#Instalar dependencias
sudo pacman -S bspwm sxhkd

#Configurar bspwm y sxhkd
mkdir -p ~/.config/bspwm ~/.config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/

chmod +x ~/.config/bspwm/bspwmrc

#Configurar LightDM para seleccionar sesiones
sudo nano /usr/share/xsessions/bspwm.desktop

# [Desktop Entry]
# Name=BSPWM
# Comment=Binary Space Partitioning Window Manager
# Exec=bspwm
# Type=XSession
