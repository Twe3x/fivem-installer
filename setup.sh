#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

curl --version
if [[ $? == 127  ]]; then  apt -y install curl; fi

clear

status(){
  clear
  echo -e $green$@'...'$reset
  sleep 1
}

source <(curl -s https://raw.githubusercontent.com/JulianGransee/BashSelect.sh/main/BashSelect.sh)

export OPTIONS=("install FiveM" "update FiveM" "do nothing") #"install MySQl/MariaDB + PHPMyAdmin"

bashSelect

case $? in
     0 )
        install=true;;
     1 )
        install=false;;
     2 )
        exit 0
esac

# Runtime Version 
status "Select a runtime version"
readarray -t VERSIONS <<< $(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | egrep -m 3 -o '[0-9].*/fx.tar.xz')

latest_recommended=$(echo "${VERSIONS[0]}" | cut -c 1-4)
latest=$(echo "${VERSIONS[2]}" | cut -c 1-4)

export OPTIONS=("latest recommended version -> $latest_recommended" "latest version -> $latest" "choose custom version" "do nothing")

bashSelect

case $? in
     0 )
        runtime_link="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[0]}";;
     1 )
        runtime_link="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[2]}";;
     2 )
        clear
        read -p "Enter the download link: " runtime_link
        ;;
     3 )
        exit 0
esac

if [[ $install == true ]]; then
  bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/install.sh) $runtime_link
else
  bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/update.sh) $runtime_link
fi
