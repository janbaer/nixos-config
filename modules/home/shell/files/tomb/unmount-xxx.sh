#!/usr/bin/env bash

NUMBER=${1}

if [ -z "${NUMBER}" ]; then
  # close all tombs
  tomb close
else
  tomb close "XXX${NUMBER}"
fi


sudo umount /mnt/xxx
