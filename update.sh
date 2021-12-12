#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"


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

dir=/home/FiveM/FXServer/server

if [ -e /home/FiveM/ ]
then
    echo "${red}Deleting ${nc}alpine"
    sleep 1
    rm -rf $dir/alpine
	clear

    echo "${red}Deleting ${nc}run.sh"
    sleep 1
    rm -rf $dir/run.sh
	clear

    echo "Downloading ${yellow}fx.tar.xz${nc}"
	string=`wget -qO- https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | egrep -m 3 -o "............................................./*\/fx.tar.xz"`
	newstring=$( echo $string | cut -c113- )
	wget --directory-prefix=$dir https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$newstring
	echo "${green}Success${nc}"

	sleep 1
	clear

	echo "Unpacking ${yellow}fx.tar.xz${nc}"
	tar xf $dir/fx.tar.xz -C $dir

	echo "${green}Success${nc}"
	sleep 1

	clear
	
	rm -r $dir/fx.tar.xz
	echo "${red}Deleting ${nc}fx.tar.xz"

	sleep 1
	clear
else
    printf "${red} ERROR: The directory /home/FiveM/ does not exist (Please install txAdmin)"
fi