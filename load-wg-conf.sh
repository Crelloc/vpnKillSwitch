#!/bin/bash

error() {
	echo "synopsis: $0 [wg config name] [persistent after boot (optional): [y|n]]"
        echo "example 1: $0 wg0 y"
        echo "example 2: $0 wg0.conf n"
        echo "example 2a: $0 wg0"
        exit 1;
}

if [ "$EUID" -ne 0 ]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

if [ ! -z "$3" ]; then
        echo "too many arguements"
	error
fi


if [ -z "$1" ] || [[ ! -z "$2" && ( "$2" != [yY] && "$2" != [yY][eE][sS] && "$2" != [nN] && "$2" != [nN][oO] ) ]]; then
	error
fi

if [[ "$1" == *.conf ]]; then
	if [ ! -f "/etc/wireguard/$1" ]; then
        	echo "/etc/wireguard/$1 does not exist"
        	exit 1
	fi
else
	if [ ! -f "/etc/wireguard/$1.conf" ]; then
                echo "/etc/wireguard/$1.conf does not exist"
                exit 1
        fi
fi

if [[ ! -z "$2" ]]; then
	if [[ "$2" == [yY] || "$2" == [yY][eE][sS] ]]; then
		ENV_PERSIST=y
	elif [[ "$2" == [nN] || "$2" == [nN][oO]  ]]; then
		ENV_PERSIST=n
	fi
else
	ENV_PERSIST=n
fi

filenameExt=$(basename -- "$1")
filename="${filenameExt%.*}"
logfile=vks.log

for fpath in /etc/wireguard/*.conf; do
	wg-quick down $fpath >> $logfile 2>&1
	fExt=$(basename -- $fpath)
	fName="${fExt%.*}"
	if [[ $ENV_PERSIST == 'y' ]]; then

		echo "
       	 	systemctl disable wg-quick@$fName:
		--------------------------------------------------------------------
		" >> $logfile 2>&1
		systemctl stop "wg-quick@$fName" >> $logfile 2>&1
		systemctl disable "wg-quick@$fName" >> $logfile 2>&1
        systemctl daemon-reload
		systemctl reset-failed
	fi
done


if [[ $ENV_PERSIST == 'y' ]]; then

	echo "
	systemctl enable wg-quick@$filename:
	--------------------------------------------------------------------
	" >> $logfile 2>&1
	systemctl enable "wg-quick@$filename" >> $logfile 2>&1
	systemctl daemon-reload 
	systemctl start "wg-quick@$filename" >> $logfile 2>&1

	# Update vpnKillSwitch service environment variable
	sed -i "/tunnel=/c\tunnel=\"$filename\"" /etc/vpnKillSwitch/env
	echo "
	systemctl environment variables:
	--------------------------------------------------------------------
	" >> $logfile 2>&1
	systemctl show-environment >> $logfile 2>&1

	systemctl reload vpnKillSwitch.service >> $logfile 2>&1
	/sbin/iptables -nL >> $logfile 2>&1
else
	echo "
	wg-quick up "/etc/wireguard/$filename.conf"
	--------------------------------------------------------------------
	" >> $logfile 2>&1
	wg-quick up "/etc/wireguard/$filename.conf" >> $logfile 2>&1
	echo "
	non persistant firewall
	--------------------------------------------------------------------
	" >> $logfile 2>&1

	export tunnel="$filename"
	bash /etc/vpnKillSwitch/firewall-reload.sh >> $logfile 2>&1
fi

#show active vpn clients
wg show interfaces

