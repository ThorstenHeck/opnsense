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

Or edit the secret.env file and execute:

    source secret.env

If all environment vars are set up properly run:

    bash hetzner_setup.sh

it will ask you to enter a working directory and use this to setup a SSH-Key Pair in given directory under $WORKDIR/.ssh 

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

github


## Docker Setup

If you are annoyed of the dependencies you can build and run a docker image:

Prepare the secret.env file to match

Build Docker image:

    docker build . -t opnsense

Run Docker image:

    docker run -it opnsense

Inside the image populate the environment variables

    source secret.env

and then run the shell script

    bash hetzner_setup.sh -d/home/hetzner -t true -o false

if you want to keep your ssh-keys copy it from the container to your machine

    docker cp containerid:/.ssh/$OPNSENSE_USER ~/.ssh/opnsense
    docker cp containerid:/.ssh/$OPNSENSE_USER.pub ~/.ssh/opnsense.pub