#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

curl --version
if [[ $? == 127  ]]; then  apt -y install curl; fi

clear

source <(curl -s https://raw.githubusercontent.com/GermanJag/BashSelect.sh/main/BashSelect.sh)

export OPTIONS=("install FiveM" "install FiveM AND MySQl/MariaDB + PHPMyAdmin" "install just MySQL/MariaDB and PHPMyAdmin" "do nothing")

bashSelect

case $? in
     0 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh);;
     1 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh) phpma;;
     2 )
        bash <(curl -s https://raw.githubusercontent.com/GermanJag/PHPMyAdminInstaller/main/install.sh);;
     3 )
        exit 0
esac
