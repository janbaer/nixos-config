#!/usr/bin/env bash

NUMBER=${1:-5}

sudo mount /mnt/xxx

cd /mnt/xxx || exit 1

tombOpen "XXX${NUMBER}"
