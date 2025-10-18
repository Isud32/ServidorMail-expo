# ServidorMail-expo
Create folder maildata<br>
Install docker and docker-compose<br>

Dependencies:
- ShowMail-Log.sh: mpv, chafa, inotify-tools<br>
<br>
Install:
- git, tmux, vim, openssh, wget<br>
----<br>
# Run docker
systemctl start docker<br>
systemctl enable docker<br>
sudo docker-compose build<br>
sudo docker-compose up (use flag -d for fg)<br>
# Run script
python -m venv venv <br>
source venv/bin/activate<br>
pip install -r requirements.txt<br>
chmod +x ShowMail-Log-V2.sh<br>
./ShowMail-Log-V2.sh<br>

# Router
cambiar el rango de DHCP, y poner ip fija en el server que este detras de nuestro nuevo rango.<br>
usar la funcion del router para bindear una ip local a un dominio , o usar bind9<br>

# En caso de querer x11
sudo apt install xorg x11-xserver-utils xwallpaper alacritty xrandr<br>
.xinitrc: <br>
xrandr --output "monitor" --mode "resolution"<br>
xwallpaper --zoom Imgs/wallpapers/LegacyWall.jpg &<br>
xset s off -dpms<br> 
(at the end allways)<br>
exec dwm<br>
dowload dwm from my dotfiles.<br>

# expo 2025
Ultima exposicion :'/<br>
 o7 <br>
/| <br>
/ \ <br>
