#!/bin/bash
# xkb-data reinstall in the guest, then a brand-new user logged in by LightDM autologin
cd /tmp; wget -q http://10.0.2.2:8000/xkbup.sh http://10.0.2.2:8000/st.sh; bash xkbup.sh m
sudo useradd -m -s /bin/bash newbe; echo 'newbe:belgie' | sudo chpasswd; echo 'newbe ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newbe >/dev/null
sudo sed -i 's/^autologin-user=.*/autologin-user=newbe/' /etc/lightdm/lightdm.conf; grep -h autologin-user= /etc/lightdm/lightdm.conf > /tmp/m-lightdm.txt
wget -q --post-file=/tmp/m-lightdm.txt http://10.0.2.2:8001/m-lightdm.txt -O /dev/null
sudo systemctl restart lightdm
