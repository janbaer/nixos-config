#!/usr/bin/env bash

MOUNT_NAME="MyNotes"
PASSWD="$(gopass show /home/veracrypt/${MOUNT_NAME})"
NUMBER=2

veracrypt --password "${PASSWD}" --protect-hidden no  \
  --pim 0 --slot "${NUMBER}" --keyfiles ""         \
  --mount $HOME/Secure/${MOUNT_NAME}.tc $HOME/Secure/${MOUNT_NAME}
