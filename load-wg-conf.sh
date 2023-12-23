#!/bin/bash

read -p "Enter path to wireguard conf: " path
if [ ! -f "$path" ]; then
	echo "file: $path doesn't exist"
	exit 1
fi

filenameExt=$(basename -- $path)
filename="${filenameExt%.*}"
ENV_PERSIST=${ENV_PERSIST:-n}

for fpath in /etc/wireguard/*.conf; do
	wg-quick down $fpath
	fExt=$(basename -- $fpath)
	fName="${fExt%.*}"
	if [[ $ENV_PERSIST == 'y' ]]; then

		echo "
       	 	systemctl disable wg-quick@$fName:
		--------------------------------------------------------------------
		"
		systemctl stop "wg-quick@$fName"
		systemctl disable "wg-quick@$fName"
	#	systemctl status "wg-quick@$fName" | head -7
	#	rm -i "/etc/systemd/system/wg-quick@$fName*"
        	systemctl daemon-reload
		systemctl reset-failed
	fi
done

if [[ $ENV_PERSIST == 'y' ]]; then
	echo "
	systemctl enable wg-quick@$filename:
	--------------------------------------------------------------------
	"
	systemctl enable "wg-quick@$filename"
	systemctl daemon-reload
	systemctl start "wg-quick@$filename"
	#echo "
	#systemctl status wg-quick@$filename:
	#--------------------------------------------------------------------
	#"
	#systemctl status "wg-quick@$filename" | head -7
else
	wg-quick up "$path"
fi

if [[ $ENV_PERSIST == 'y' ]]; then

	systemctl set-environment tunnel="$filename"
	echo "
	systemctl environment variables:
	--------------------------------------------------------------------
	"
	systemctl show-environment

	systemctl stop vpnKillSwitch.service
	systemctl start vpnKillSwitch.service
	systemctl unset-environment tunnel
	#echo "
	#systemctl status vpnKillSwitch.service:
	#"
	#systemctl status vpnKillSwitch.service | head -7
	/sbin/iptables -nL
else
	echo "
	non persistant firewall
	--------------------------------------------------------------------
	"
	tunnel="$filename"
	exec /etc/vpnKillSwitch/firewall-reload.sh
fi

