# OPNSENSE Remote Management - Hetzner Cloud

Setting up an opnsense Firewall in Hetzner requires manual actions like ISO mounting, Interface Assignment, SSH configuration and Firewall Rules adjustments.  

If you actually don't want to leave your terminal at all and avoid to access opnsense through the console and WebGUI Interface to smash some Buttons to make opnsense further accessible - you found the right place.

## Requirements

- packer
- htpasswd
- jq

#### optional

- terraform

## Install

Clone this Repo and follow Instructions.

## Setup

- Only enable WAN Interface
- Change Root default password
- Add administrative user
- Add SSH-Access only to administrative user
- SSH Access for administrative user with sudo enabled
- Enable access to WebGUI from WAN

So we will end up with an Instance which can accessed by the administrative user via SSH and HTTPS on the Public IP.
Root can access via the WebGUI and Console Interface but is not permitted for SSH.

The whole process takes about 15 minutes to build a freebsd image, bootstrap into opensense and build an image out of it to finally create a running remote opnsense Instance - the process will speed up if you don't need to create the freebsd image.

### Build opnsense Image

Export the needed secrets to make it work:

    export HCLOUD_TOKEN=<HCLOUD_TOKEN>
    export OPNSENSE_USER=<name of the opnsense management user>
    export OPNSENSE_USER_PASSWORD=<SECRET>
    export OPNSENSE_ROOT_PASSWORD=<SECRET>

You can also edit the secret.env file with the "-c" parameter the script picks up the content of the file.

    bash hetzner_setup.sh

Or with a proper configured secret.env file:

    bash hetzner_setup.sh -c

The default working directory is the home directory and the script will setup a SSH-Key Pair under $HOME/.ssh.

You can skip the SSH-Key creation with the "-s" parameter but to make the setup script work out of the box you have to copy a valid SSH-Key into the working directory.

    bash hetzner_setup.sh -s

Thats it, now you can create a new Server from the opnsense image and access opnsense via the WebGUI or SSH.

Its recommended to reboot the server once after creation, due to an CARP Bug.

### Create Server 

An easy way to directly create a server from the recently build image is using terraform:

Export the HCLOUD_TOKEN as well as the OPNSENSE_USER and OPNSENSE_USER_PASSWORD in terraform format and then initialize and run terraform

    export TF_VAR_HCLOUD_TOKEN=<HCLOUD_TOKEN>
    export TF_VAR_SSH_KEY=<OPNSENSE_USER>
    export TF_VAR_OPNSENSE_USER_PASSWORD=<SECRET>

    ssh-add $WORKDIR/.ssh/$OPNSENSE_USER
    cd terraform/opnsense && terraform init && terraform apply -auto-approve && cd -

### Further Management

To manage opnsense further I highly reccommend the great ansible role by naturalis https://github.com/naturalis/ansible-opnsense

It basically parses the config.xml properly and reloads it on the instance.

#### Advanced Setup Example

An advanced setup with an ansible dependency can be found here:

https://github.com/ThorstenHeck/opnsense_advanced


## Docker Setup

If you are annoyed of the dependencies you can build and run a docker image:

Prepare the secret.env file, build and run the image then run the setup script:

Build Docker image:

    cd opnsense
    docker build -t opnsense .

Run Docker image:

    docker run --rm \
            -e HCLOUD_TOKEN=$HCLOUD_TOKEN \
            -e OPNSENSE_USER=opn_admin \
            -e OPNSENSE_USER_PASSWORD=opn_password \
            -e OPNSENSE_ROOT_PASSWORD=root_password \
            opnsense
