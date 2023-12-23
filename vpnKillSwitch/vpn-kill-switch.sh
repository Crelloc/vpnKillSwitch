#!/bin/bash
#
# iptables example configuration script


wdevice=wlx98fc11c3fe80
ldevice=eno1
tunnel=${tunnel:-tun0}

# Drop ICMP echo-request messages sent to broadcast or multicast addresses
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# Drop source routed packets
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
 
# Enable TCP SYN cookie protection from SYN floods
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
 
# Don't accept ICMP redirect messages
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
 
# Don't send ICMP redirect messages
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
 
# Enable source address spoofing protection
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
 
# Log packets with impossible source addresses
echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
 
# Flush all chains
/sbin/iptables --flush
 
# Allow unlimited traffic on the loopback interface
/sbin/iptables -A INPUT -i lo -j ACCEPT
 
# Set default policies
/sbin/iptables --policy INPUT DROP
/sbin/iptables --policy OUTPUT DROP
/sbin/iptables --policy FORWARD DROP

# If you are running a server on port N, and have enabled forwarding in your VPN account, you must allow inbound traffic on the VPN. You may also want to limit access to a particular IP address (a.b.c.d). There can be multiple rules, one for each permitted port and source address.
#/sbin/iptables -A INPUT -i $tunnel -s a.b.c.d –dport N -j ACCEPT


# You may need to allow traffic from local DHCP servers. If using Wi-Fi, use “wlan0” instead of “eth0”. This isn’t needed if your router provides persistent leases.
/sbin/iptables -A INPUT -i $wdevice -s 255.255.255.255 -j ACCEPT

# Previously initiated and accepted exchanges bypass rule checking
/sbin/iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Ratelimit SSH for attack protection
/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 22 -m state --state NEW -m recent --set
/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 22 -m state --state NEW -j ACCEPT
 
# Allow certain ports to be accessible from the outside
#/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 25565 -m state --state NEW -j ACCEPT  #Minecraft
#/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 8123 -m state --state NEW -j ACCEPT   #Dynmap plugin
#/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 993 -m state --state NEW -j ACCEPT   #Thunderbird
#/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 465 -s smtp.gmail.com -j ACCEPT   #Thunderbird - gmail

# Other rules for future use if needed.  Uncomment to activate
/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 80 -m state --state NEW -j ACCEPT    # http
/sbin/iptables -A INPUT -i $wdevice -p tcp --dport 443 -m state --state NEW -j ACCEPT   # https

# UDP packet rule.  This is just a random udp packet rule as an example only
# /sbin/iptables -A INPUT -i $wdevice -p udp --dport 5021 -m state --state NEW -j ACCEPT

# Allow pinging of your server
/sbin/iptables -A INPUT -i $wdevice -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

  
# Drop all other traffic
/sbin/iptables -A INPUT -j DROP

# Your device isn’t a router, so don’t allow forwarding. In any case, you’d also need to allow that using sysctl.
# Allow docker network bridge
/sbin/iptables -A FORWARD -i docker0 -o $wdevice -j ACCEPT
/sbin/iptables -A FORWARD -j DROP

# Some local processes need to talk to other ones.
/sbin/iptables -A OUTPUT -o lo -j ACCEPT

## Not a router: Can be used to setup raspberry pi wifi  
#/sbin/iptables -t nat -A POSTROUTING -o $tunnel -j MASQUERADE
#/sbin/iptables -A FORWARD -i $tunnel -o $wdevice -m state --state RELATED,ESTABLISHED -j ACCEPT
#/sbin/iptables -A FORWARD -i $wdevice -o $tunnel -j ACCEPT
##

/sbin/iptables -A OUTPUT -o $tunnel -m comment --comment "vpn" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p icmp -m comment --comment "icmp" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -d 192.168.1.0/24 -m comment --comment "wan out" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p udp -m udp --dport 1194 -m comment --comment "openvpn" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p udp -m udp --dport 1195 -m comment --comment "openvpn" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p udp -m udp --dport 51820 -m comment --comment "wireguard: $tunnel" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p tcp -m tcp --sport 22 -m comment --comment "ssh" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p udp -m udp --dport 123 -m comment --comment "ntp" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p udp -m udp --dport 53 -m comment --comment "dns" -j ACCEPT
/sbin/iptables -A OUTPUT -o $wdevice -p tcp -m tcp --dport 53 -m comment --comment "dns" -j ACCEPT

# Allow outgoing traffic to local DHCP servers. If using Wi-Fi, use “wlan0” instead of “eth0”. This isn’t needed if your router provides persistent leases.
/sbin/iptables -A OUTPUT -o $wdevice -d 255.255.255.255 -j ACCEPT


# Then you allow related/established traffic, and drop everything else, without acknowledgement to peers.
/sbin/iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A OUTPUT -j DROP

# Drop all ipv6 traffic
/sbin/ip6tables -A OUTPUT -j DROP
/sbin/ip6tables -A INPUT -j DROP
/sbin/ip6tables -A FORWARD -j DROP

# print the activated rules to the console when script is completed
/sbin/iptables -nL
