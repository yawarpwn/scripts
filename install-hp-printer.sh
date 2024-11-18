# sudo pacman -S cups
# sudo systemctl enable --now cups
# sudo pacman -S hplip
# sudo pacman -S python-pyqt5
# sudo hp-setup -i
# https://ftp.hp.com/pub/softlib/software13/printers/CLP150/uld-hp_V1.00.39.12_00.15.tar.gz
# system-config-printer

hp_driver_url="https://ftp.hp.com/pub/softlib/software13/printers/CLP150/uld-hp_V1.00.39.12_00.15.tar.gz"

file_name=$(basename "$hp_driver_url")

install_dir="$HOME/Downloads/hp_drivers/"

file_path="$install_dir/$file_name"

mkdir -p "$install_dir"

# Descargar el archivo
echo "Downloading $file_name"
if ! curl -o "$file_path" $hp_driver_url; then
  echo "Error downloading $file_name"
  exit 1
fi

# Extrar el archivo
echo "Extrayendo $file_name en $install_dir"
if ! tar -xzf "$file_path" -C "$install_dir"; then
  echo "Error extracting $file_name"
  #Eliminar el archivo descargado
  rm "$file_path"
  exit 1
fi

#entrar a la carpeta uld
uld_dir="$install_dir/uld"
cd "$uld_dir"

#Dar permiso de ejecucion
chmod +x install.sh

# Ejecutar el instaldor
sudo ./install.sh

exit 0
