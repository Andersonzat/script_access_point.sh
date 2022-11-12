#!/bin/sh -e

apt-get update
apt install hostapd
systemctl unmask hostapd
systemctl enable hostapd
apt install dnsmasq

echo "interface wlan1" | tee -a /etc/dhcpcd.conf
echo "    static ip_address=192.168.10.1/24" | tee -a /etc/dhcpcd.conf
echo "    nohook wpa_supplicant" | tee -a /etc/dhcpcd.conf

sed -i.bak '18a\sudo hostapd /etc/hostapd/hostapd.conf & iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local
sed -i.bak 's|^\# DAEMON_CONF=.*|\DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
sed -i.bak 's|^\# DAEMON_CONF=.*|\DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/init.d/hostapd

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "interface=wlan1" | tee -a /etc/dnsmasq.conf
echo "dhcp-range=192.168.10.2,192.168.10.20,255.255.255.0,24h" | tee -a /etc/dnsmasq.conf
echo "domain=wlan" | tee -a /etc/dnsmasq.conf
echo "address=/gw.wlan/192.168.10.1" | tee -a /etc/dnsmasq.conf

rfkill unblock wlan

touch /etc/hostapd/hostapd.conf
echo "country_code=CA" | tee -a /etc/hostapd/hostapd.conf
echo "interface=wlan1" | tee -a /etc/hostapd/hostapd.conf
echo "ssid=ZAT_TOR" | tee -a /etc/hostapd/hostapd.conf
echo "hw_mode=g" | tee -a /etc/hostapd/hostapd.conf
echo "channel=7" | tee -a /etc/hostapd/hostapd.conf
echo "macaddr_acl=0" | tee -a /etc/hostapd/hostapd.conf
echo "auth_algs=1" | tee -a /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0" | tee -a /etc/hostapd/hostapd.conf
echo "wpa=2" | tee -a /etc/hostapd/hostapd.conf
echo "wpa_passphrase=Internet" | tee -a /etc/hostapd/hostapd.conf
echo "wpa_key_mgmt=WPA-PSK" | tee -a /etc/hostapd/hostapd.conf
echo "wpa_pairwise=TKIP" | tee -a /etc/hostapd/hostapd.conf
echo "rsn_pairwise=CCMP" | tee -a /etc/hostapd/hostapd.conf
echo "192.168.10.1    neozat.com" | tee -a /etc/hosts

DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent
echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.d/routed-ap.conf
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

systemctl start hostapd
systemctl restart dnsmasq

reboot
