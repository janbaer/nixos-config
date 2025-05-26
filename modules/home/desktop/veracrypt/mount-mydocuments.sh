#!/usr/bin/env bash

MOUNT_NAME="MyDocuments"
PASSWD="$(gopass show /home/veracrypt/${MOUNT_NAME})"
NUMBER=1

veracrypt --password "${PASSWD}" --protect-hidden no  \
  --pim 0 --slot "${NUMBER}" --keyfiles ""         \
  --mount $HOME/Secure/${MOUNT_NAME}.tc $HOME/Secure/${MOUNT_NAME}
