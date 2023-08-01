#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

runtime_link=$1

status(){
  clear
  echo -e $green$@'...'$reset
  sleep 1
}

runCommand(){
    COMMAND=$1

    if [[ ! -z "$2" ]]; then
      status $2
    fi

    eval $COMMAND;
    BASH_CODE=$?
    if [ $BASH_CODE -ne 0 ]; then
      echo -e "${red}An error occurred:${reset} ${white}${COMMAND}${reset}${red} returned${reset} ${white}${BASH_CODE}${reset}"
      exit ${BASH_CODE}
    fi
}

source <(curl -s https://raw.githubusercontent.com/GermanJag/BashSelect.sh/main/BashSelect.sh)
clear


status "Select the alpine directory"
readarray -t directorys <<<$(find / -name "alpine")
export OPTIONS=(${directorys[*]})

bashSelect

dir=${directorys[$?]}/..


lsof -i :40120
if [[ $( echo $? ) == 0 ]]; then

  status "It looks like there is something running on the default TxAdmin port. Can we stop/kill it?" "/"
  export OPTIONS=("Kill PID on port 40120" "Exit the script")
  bashSelect
  case $? in
    0 )
      status "killing PID on 40120"
      runCommand "apt -y install psmisc"
	  runCommand "fuser -4 40120/tcp -k"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

echo "${red}Deleting ${nc}alpine"
sleep 1
rm -rf $dir/alpine
clear

echo "${red}Deleting ${nc}run.sh"
sleep 1
rm -f $dir/run.sh
clear

echo "Downloading ${yellow}fx.tar.xz${nc}"
wget --directory-prefix=$dir $1
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

echo "${green}update success${nc}"
