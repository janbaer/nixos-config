#!/usr/bin/env bash

file=$1
w=$2
h=$3
x=$4
y=$5

bat_preview() {
  bat --color=always --theme=base16 "$1"
}

image_preview() {
  chafa --view-size 80x25 "$1"
}

case "$file" in
  *.tar*) tar tf "$file";;
  *.zip) unzip -l "$file";;
  *.rar) unrar l "$file";;
  *.7z) 7z l "$file";;
  *.pdf) pdftotext "$file" -;;
  *.jpg|*.jpeg|*.png|*.bmp) image_preview "$file";;
  *) bat_preview "$file";;
esac
