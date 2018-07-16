if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [[ "$1" != "" ]]; then
    WIFINAME=$1    
else
    echo "Please provide wifi name as the first parameter"
    exit
fi

echo "Provideed WIFI name is $WIFINAME"

echo 'Initializing linux device'
echo 'Creating access point/hot spot mode for wlan1...'
sudo apt-get install dnsmasq
echo "Checking if config is there since before"
if [ -f /etc/dnsmasq.d/access_point.conf ] ; then
 echo "Removing earlier file.."
 rm -f /etc/dnsmasq.d/access_point.conf
 echo "Done"
fi
echo "Creating hotspot configuration..."
echo "#If you want dnsmasq to listen for DHCP and DNS requests only on" >> /etc/dnsmasq.d/access_point.conf
echo "#specified interfaces (and the loopback) give the name of the" >> /etc/dnsmasq.d/access_point.conf
echo "#interface (eg eth0) here." >> /etc/dnsmasq.d/access_point.conf
echo "#Repeat the line for more than one interface." >> /etc/dnsmasq.d/access_point.conf
echo "interface=wlan1" >> /etc/dnsmasq.d/access_point.conf
echo "#Or you can specify which interface not to listen on" >> /etc/dnsmasq.d/access_point.conf
echo "except-interface=wlan0" >> /etc/dnsmasq.d/access_point.conf

echo "#Uncomment this to enable the integrated DHCP server, you need" >> /etc/dnsmasq.d/access_point.conf
echo "#to supply the range of addresses available for lease and optionally" >> /etc/dnsmasq.d/access_point.conf
echo "#a lease time. If you have more than one network, you will need to" >> /etc/dnsmasq.d/access_point.conf
echo "#repeat this for each network on which you want to supply DHCP service." >> /etc/dnsmasq.d/access_point.conf
echo "dhcp-range=172.20.0.100,172.20.0.250,1h" >> /etc/dnsmasq.d/access_point.conf
echo "Done"

echo "Setting up the network interfaces..."
echo "# interfaces(5) file used by ifup(8) and ifdown(8)" > /etc/network/interfaces
echo "# Include files from /etc/network/interfaces.d:" >> /etc/network/interfaces
echo "source-directory /etc/network/interfaces.d" >> /etc/network/interfaces
echo "auto wlan1" >> /etc/network/interfaces
echo "iface wlan1 inet static" >> /etc/network/interfaces
echo "  address 172.20.0.1" >> /etc/network/interfaces
echo "  netmask 255.255.255.0" >> /etc/network/interfaces
echo "Done"
echo "Testing gateway settings..."
sudo ifup wlan1
ip addr show wlan1
/etc/init.d/dnsmasq restart
if [ $? -ne 0 ]; then
  echo "The testing failed, please review the message above and take action and rerun the script"
  exit
fi
echo "Testing done"
echo "Checking if there is a service running"
if [ -f /etc/hostapd.conf ] ; then
 echo "Yes, turn it of..."
 sudo systemctl stop hostapd-systemd
 echo "Done"
fi

echo "Starting to configure access point settings"
cat > /etc/hostapd.conf << EOL
interface=wlan1
driver=nl80211
ssid=$WIFINAME
channel=1
ctrl_interface=/var/run/hostapd
EOL

echo "Done"
echo "Registering hostapd as a service..."
cat > /lib/systemd/system/hostapd-systemd.service << EOL
[Unit]
Description=hostapd service
Wants=network-manager.service
After=network-manager.service
Wants=module-init-tools.service
After=module-init-tools.service
ConditionPathExists=/etc/hostapd.conf

[Service]
ExecStart=/usr/sbin/hostapd /etc/hostapd.conf

[Install]
WantedBy=multi-user.target
EOL

sudo update-rc.d hostapd disable
sudo systemctl daemon-reload
sudo systemctl enable hostapd-systemd

echo "Done"

echo "Starting access point"
sudo systemctl start hostapd-systemd
systemctl status hostapd-systemd

echo "Access point started"

