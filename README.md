### Motivation
I have wireguard vpn servers in multiple locations and i needed
to dynamically load my firewall every time i change vpn connection for
my host machine.

To keep my connection location and browsing secure, I implemented a [vpn kill switch](https://www.pcmag.com/explainers/what-is-a-vpn-kill-switch-and-how-does-it-work).

This code:
    - installs firewall and configures it to start at boot.
    - installs software to change vpn configuration with the option to set vpn to persistent (start at boot).

### Prereqs:
- Install wireguard (wg) server and generate your client config files
    - Configure wg server: https://github.com/Nyr/wireguard-install
- Download your client config files and move them to /etc/wireguard directory
    - Install wg client on Linux: https://www.makeuseof.com/how-to-install-wireguard-vpn-client/

### Download code
```bash
git clone https://github.com/Crelloc/vpnKillSwitch.git && cd vpnKillSwitch
```

### Setup
1. edit the [env](/vpnKillSwitch/env) to set your default wg client config name (without the .conf extension).

if not set then default name would be tun0.

```bash
tunnel="default_client_name"
```

2. [edit firewall configuration](/vpnKillSwitch/vpn-kill-switch.sh)

### Install vpn kill switch firewall in linux
```
# Make scripts executable
chmod +x *.sh

# Set correct file permissions
chmod 0644 systemd/vpnKillSwitch.service
chmod 744 vpnKillSwitch/*.sh
chmod 700 vpnKillSwitch/env

# Enable and start wg vpn firewall at boot
sudo cp systemd/vpnKillSwitch.service /etc/systemd/system
sudo cp -R vpnKillSwitch /etc/
sudo systemctl daemon-reload
sudo systemctl enable vpnKillSwitch.service
sudo systemctl start vpnKillSwitch.service

# If you want to disable ipv6, uncomment commands below:
# echo 'net.ipv6.conf.all.disable_ipv6=1' | sudo tee -a /etc/sysctl.conf
# echo 'net.ipv6.conf.default.disable_ipv6=1' | sudo tee -a /etc/sysctl.conf
# echo 'net.ipv6.conf.lo.disable_ipv6=1' | sudo tee -a /etc/sysctl.conf
# sudo sysctl -p
```

### Load wireguard configuration
synopsis: sudo ./load-wg-conf.sh [wg config name] [persistent after boot (optional): [y|n]]

example 1: 
```bash
sudo ./load-wg-conf.sh wg0 y
```

example 2:
```bash
sudo ./load-wg-conf.sh wg0.conf n
```

example 2a:
```bash
# persistent automatically set to no
sudo ./load-wg-conf.sh wg0
```
### Stop vpnKillSwitch service
```bash
# temporarily stop the vpn firewall (open ports / disable firewall) - however will restart at bootup
sudo systemctl stop vpnKillSwitch.service
```

### Disable vpnKillSwitch service
```bash
# Disable firewall so it won't start at boot up
sudo systemctl stop vpnKillSwitch.service
```
