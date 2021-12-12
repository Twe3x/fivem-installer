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
	printf "${red} ERROR: The directory /home/FiveM/ already exists"
else
	echo "${yellow}Creating needed directories${nc}"
	
	mkdir /home/FiveM/
	echo "/home/FiveM/ created ${green}successfully${nc}"

	mkdir /home/FiveM/FXServer/
	echo "/home/FiveM/FXServer/ created ${green}successfully${nc}"

	echo "Cloning ${yellow}https://github.com/citizenfx/cfx-server-data.git${nc}"
	sleep 1
	clear
	git clone https://github.com/citizenfx/cfx-server-data.git $dir
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
	

	echo "Creating ${yellow}start.sh${nc}"
	echo screen -S fivem bash $dir/run.sh >$dir/start.sh; chmod +x $dir/start.sh
	
	sleep 1
	clear

	read -rsn1 -p"Press any key to ${green}continue${nc}";echo
	sh $dir/start.sh
fi
