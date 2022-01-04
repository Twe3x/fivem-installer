#!/bin/bash

curl --version
if [[ $? == 127  ]]; then  apt -y install curl; fi

source <(curl -s https://raw.githubusercontent.com/GermanJag/BashSelect.sh/main/BashSelect.sh)

export OPTIONS=("install FiveM" "install FiveM AND MySQl/MariaDB + PHPMyAdmin" "update FiveM" "install just MySQL/MariaDB and PHPMyAdmin" "do nothing")

bashSelect

case $? in
     0 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh);;
     1 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh) phpma;;
     2 )
        bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/update.sh);;
     3 )
        bash <(curl -s https://raw.githubusercontent.com/GermanJag/PHPMyAdminInstaller/main/install.sh);;
     4 )
        exit 0
esac
