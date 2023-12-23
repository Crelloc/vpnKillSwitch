#!/bin/bash

error() {
	echo "synopsis: $0 [wg config name] [persistent after boot (optional): [y|n]]"
        echo "example 1: $0 wg0 y"
        echo "example 2: $0 wg0.conf n"
        echo "example 2a: $0 wg0"
        exit 1;
}

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
else
	wg-quick up "$path" >> $logfile 2>&1
fi

if [[ $ENV_PERSIST == 'y' ]]; then

	systemctl set-environment tunnel="$filename"
	echo "
	systemctl environment variables:
	--------------------------------------------------------------------
	" >> $logfile 2>&1
	systemctl show-environment >> $logfile 2>&1

	systemctl stop vpnKillSwitch.service >> $logfile 2>&1
	systemctl start vpnKillSwitch.service >> $logfile 2>&1
	systemctl unset-environment tunnel
	/sbin/iptables -nL >> $logfile 2>&1
else
	echo "
	non persistant firewall
	--------------------------------------------------------------------
	" >> $logfile 2>&1

	tunnel="$filename"
	exec /etc/vpnKillSwitch/firewall-reload.sh >> $logfile 2>&1
fi

