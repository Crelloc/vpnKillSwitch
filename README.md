### Motivation
I have multiple vpn servers in multiple locations and i needed
to dynamically load my firewall when i change my wireguard
configuration to use a vpn location.

To keep my connection location and browsing secure, I implemented a [vpn kill switch](https://www.pcmag.com/explainers/what-is-a-vpn-kill-switch-and-how-does-it-work).


### Prereqs:
- Install wireguard (wg) server and generate your client config files
    - Configure wg server: https://github.com/Nyr/wireguard-install
- Download your client config files and move them to /etc/wireguard directory
    - Install wg client on Linux: https://www.makeuseof.com/how-to-install-wireguard-vpn-client/

### Download code
```bash
git clone https://github.com/Crelloc/vpnKillSwitch.git
```

### install vpn kill switch firewall in linux
synopsis:
```
sudo ./configure 
```

### load wireguard configuration
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
sudo ./load-wg-conf.sh wg0
```
