# OPNSENSE Remote Management - Hetzner Cloud

Setting up an opnsense Firewall in Hetzner requires manual actions like ISO mounting, Interface Assignment, SSH configuration and Firewall Rules adjustments.  

If you actually don't want to leave your terminal at all and avoid to access opnsense through the console and WebGUI Interface to smash some Buttons to make opnsense further accessible - you found the right place.

## Requirements

hcloud cli
packer
htpasswd
jq

## Setup

- Only enable WAN Interface
- Change Root default password
- Add administrative user
- Add SSH-Access only to administrative user
- SSH Access for administrative user with sudo enabled
- Enable access to WebGUI from WAN

So we will end up with an Instance which can accessed by the administrative user via SSH and HTTPS on the Public IP.
Root can access via the WebGUI and Console Interface but is not permitted for SSH.

### 

Generate the SSH-Key for the administrative user:

    dd

Set up your hcloud cli use the right context and setup

Name of administraive user = manager
Password of administrative user = securepassword
Password of root = securepassword

