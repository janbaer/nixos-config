PWD="$(gopass show /home/veracrypt/XXX-KG)"
NUMBER=3

veracrypt --password "${PWD}" --protect-hidden no  \
  --pim 0 --slot "${NUMBER}" --keyfiles ""         \
  --mount ~/Secure/XXX-KG.tc $HOME/Secure/XXX-KG
