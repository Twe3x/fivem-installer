#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

curl --version
if [[ $? == 127  ]]; then  apt -y install curl; fi

clear
echo apt update...
sleep 1
sudo apt update -y
clear
echo apt upgrade...
sleep 1
sudo apt upgrade -y
clear
echo installing git...
sleep 2
sudo apt install git screen xz-utils -y

clear


readarray -t VERSIONS <<< $(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | egrep -m 3 -o '[0-9].*/fx.tar.xz')
runtime_link="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[2]}"

source <(curl -s https://raw.githubusercontent.com/GermanJag/BashSelect.sh/main/BashSelect.sh)

export OPTIONS=("install FiveM" "install FiveM AND MySQl/MariaDB + PHPMyAdmin" "update FiveM" "install just MySQL/MariaDB and PHPMyAdmin" "do nothing")

bashSelect

case $? in
     0 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh) runtime_link;;
     1 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh) runtime_link phpma;;
     2 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/update.sh) runtime_link;;
     3 )
        bash <(curl -s https://raw.githubusercontent.com/GermanJag/PHPMyAdminInstaller/main/install.sh);;
     4 )
        exit 0
esac
