#!/bin/bash

echo "Setup Hetzner Environment"

if [[ -z "${HCLOUD_TOKEN}" ]]
then
  echo "HCLOUD_TOKEN not found - please export it as an environment variable"
  exit 1  
fi

echo "Set Working Directory"
read WORKDIR

mkdir -p $WORKDIR/.ssh

echo "Enter name of the aministrative opnsense user"
read OPNSENSE_USER

echo "Create SSH-Key Pair"
ssh-keygen -t ed25519 -f $WORKDIR/.ssh/$OPNSENSE_USER -C $OPNSENSE_USER -q -N ''

SSH_PUB=$(cat $WORKDIR/.ssh/$OPNSENSE_USER.pub)

cat <<EOF > $WORKDIR/data.json
{"labels":{},"name":"$OPNSENSE_USER","public_key":"$SSH_PUB"}
EOF
DATA=$WORKDIR/data.json

echo "Check if SSH-Key exists by name in Hetzner"

SSH_LIST=$(curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" 'https://api.hetzner.cloud/v1/ssh_keys' | jq .meta.pagination.total_entries)
if [ "$SSH_LIST" -eq "0" ]
then
curl -s -X POST -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" -d @$DATA 'https://api.hetzner.cloud/v1/ssh_keys' >  /dev/null 2>& 1
else
SSH_KEY_ID=$(curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" 'https://api.hetzner.cloud/v1/ssh_keys' | jq --arg USER $OPNSENSE_USER '.[][] | select(.name==$USER) | .id')
    if [ -z "$SSH_KEY_ID" ]
    then
    curl -s -X POST -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" -d @$DATA 'https://api.hetzner.cloud/v1/ssh_keys' >  /dev/null 2>& 1
    else
    echo "SSH-Key duplicate - name already exists - better clean it up manually"
    exit 1
    fi
fi

rm $DATA

echo "CHECK OPNSENSE USER PASSWORD"

if [[ -z "${OPNSENSE_USER_PASSWORD}" ]]
then
  echo "OPNSENSE_USER_PASSWORD not found - please export it as an environment variable"
  exit 1  
fi

echo "CHECK OPNSENSE ROOT PASSWORD"

if [[ -z "${OPNSENSE_ROOT_PASSWORD}" ]]
then
  echo "OPNSENSE_ROOT_PASSWORD not found - please export it as an environment variable"
  exit 1  
fi

OPNSENSE_ROOT_HASH=$(htpasswd -bnBC 10 "" $OPNSENSE_ROOT_PASSWORD | tr -d ':\n')
OPNSENSE_USER_HASH=$(htpasswd -bnBC 10 "" $OPNSENSE_USER_PASSWORD | tr -d ':\n')

cp config.template.xml packer/opnsense/config.xml

OPNSENSE_SSH_PUB=$(cat $WORKDIR/.ssh/$OPNSENSE_USER.pub | base64 -w 0)
OPNSENSE_SSH_PRIV=$(realpath "$WORKDIR/.ssh/$OPNSENSE_USER")

sed -i 's|OPNSENSE_USER\b|'"$OPNSENSE_USER"'|g' packer/opnsense/config.xml
sed -i 's|OPNSENSE_ROOT_HASH\b|'"$OPNSENSE_ROOT_HASH"'|g' packer/opnsense/config.xml
sed -i 's|OPNSENSE_USER_HASH\b|'"$OPNSENSE_USER_HASH"'|g' packer/opnsense/config.xml
sed -i 's|OPNSENSE_SSH_PUB\b|'"$OPNSENSE_SSH_PUB"'|g' packer/opnsense/config.xml

echo "Configuration file supplied with password hashes and public SSH Key"

cat <<EOF > $WORKDIR/packer_env.sh
export OPNSENSE_SSH_PRIV=$OPNSENSE_SSH_PRIV
export OPNSENSE_USER=$OPNSENSE_USER
EOF

source  $WORKDIR/packer_env.sh

rm  $WORKDIR/packer_env.sh

echo "run packer to build a freebsd image"

packer build -only=hcloud.freebsd packer/freebsd.pkr.hcl

echo "run packer to bootstrap opnsense from the previously created freebsd image"

packer build -only=hcloud.opnsense packer/freebsd.pkr.hcl