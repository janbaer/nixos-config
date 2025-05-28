#!/bin/sh

NUMBER=${1:-4}

USER=jan
XXX_PWD=$(gopass /home/veracrypt/XXX)

if [ ! -f /mnt/xxx/XXX1.tc ]; then
  echo "Seems that your NAS server is not reachable..."
  exit 1
fi

if [ ! -d /mnt/xxx1 ]; then
  echo "We need to create the mount directories first..."
  for ((i = 1; i <= 5; i++)); do
    sudo mkdir /mnt/xxx$i
    sudo chown ${USER}:users /mnt/xxx$i
    sudo chmod 700 /mnt/xxx$i
  done
fi

veracrypt --password "${XXX_PWD}" --protect-hidden no       \
  --pim 0 --slot "${NUMBER}" --keyfiles ""                  \
  --mount "/mnt/xxx/XXX${NUMBER}.tc" "/mnt/xxx${NUMBER}" 
