### Download code
```bash
git clone https://github.com/Crelloc/vpnKillSwitch.git
```

### install vpn kill switch firewall in linux
synopsis: ./configure

### load wireguard configuration
synopsis: ./load-wg-conf.sh [wg config name] [persistent after boot (optional): [y|n]]
example 1: ./load-wg-conf.sh wg0 y
example 2: ./load-wg-conf.sh wg0.conf n
example 2a: ./load-wg-conf.sh wg0

### Note:
-edit ./configure script if you want to disable ipv6
-make sure to edit firewall file (vpnKillSwitch/vpn-kill-switch.sh) for you specific network devices
