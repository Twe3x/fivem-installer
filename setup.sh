#!/bin/bash

red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"

if [ "$EUID" -ne 0 ]; then
	echo -e "${red}Please run as root";
	exit 1
fi

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

dir=/home/FiveM

update_artifacts=false
non_interactive=false
artifacts_version=0
kill_txAdmin=0
delete_dir=0
txadmin_deployment=0
install_phpmyadmin=0
crontab_autostart=0
pma_options=()

function selectVersion(){

    readarray -t VERSIONS <<< $(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | egrep -m 3 -o '[0-9].*/fx.tar.xz')

    latest_recommended=$(echo "${VERSIONS[0]}" | cut -d'-' -f1)
    latest=$(echo "${VERSIONS[2]}" | cut -d'-' -f1)

    if [[ "${artifacts_version}" == "0" ]]; then
        if [[ "${non_interactive}" == "false" ]]; then
            status "Select a runtime version"
            export OPTIONS=("latest version -> $latest" "latest recommended version -> $latest_recommended" "choose custom version" "do nothing")

            bashSelect

            case $? in
                0 )
                    artifacts_version="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[2]}"
                    ;;
                1 )
                    artifacts_version="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[0]}"
                    ;;
                2 )
                    clear
                    read -p "Enter the download link: " artifacts_version
                    ;;
                3 )
                    exit 0
            esac

            return
        else
            artifacts_version="latest"
        fi
    fi
    if [[ "${artifacts_version}" == "latest" ]]; then
        artifacts_version="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[2]}"
    fi
}

function examServData() {

  runCommand "mkdir -p $dir/server-data"

  runCommand "git clone -q https://github.com/citizenfx/cfx-server-data.git $dir/server-data" "The server data is being downloaded"

  status "Creating example server.cfg"

  cat << EOF > $dir/server-data/server.cfg
# Only change the IP if you're using a server with multiple network interfaces, otherwise change the port only.
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# These resources will start by default.
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap
ensure rconlog

# This allows players to use scripthook-based plugins such as the legacy Lambda Menu.
# Set this to 1 to allow scripthook. Do note that this does _not_ guarantee players won't be able to use external plugins.
sv_scriptHookAllowed 0

# Uncomment this and set a password to enable RCON. Make sure to change the password - it should look like set rcon_password "YOURPASSWORD"
#set rcon_password ""

# A comma-separated list of tags for your server.
# For example:
# - sets tags "drifting, cars, racing"
# Or:
# - sets tags "roleplay, military, tanks"
sets tags "default"

# A valid locale identifier for your server's primary language.
# For example "en-US", "fr-CA", "nl-NL", "de-DE", "en-GB", "pt-BR"
sets locale "root-AQ" 
# please DO replace root-AQ on the line ABOVE with a real language! :)

# Set an optional server info and connecting banner image url.
# Size doesn't matter, any banner sized image will be fine.
#sets banner_detail "https://url.to/image.png"
#sets banner_connecting "https://url.to/image.png"

# Set your server's hostname. This is not usually shown anywhere in listings.
sv_hostname "FXServer, but unconfigured"

# Set your server's Project Name
sets sv_projectName "My FXServer Project"

# Set your server's Project Description
sets sv_projectDesc "Default FXServer requiring configuration"

# Set Game Build (https://docs.fivem.net/docs/server-manual/server-commands/#sv_enforcegamebuild-build)
#sv_enforceGameBuild 2802

# Nested configs!
#exec server_internal.cfg

# Loading a server icon (96x96 PNG file)
#load_server_icon myLogo.png

# convars which can be used in scripts
set temp_convar "hey world!"

# Remove the `#` from the below line if you want your server to be listed as 'private' in the server browser.
# Do not edit it if you *do not* want your server listed as 'private'.
# Check the following url for more detailed information about this:
# https://docs.fivem.net/docs/server-manual/server-commands/#sv_master1-newvalue
#sv_master1 ""

# Add system admins
add_ace group.admin command allow # allow all commands
add_ace group.admin command.quit deny # but don't allow quit
add_principal identifier.fivem:1 group.admin # add the admin to the group

# enable OneSync (required for server-side state awareness)
set onesync on

# Server player slot limit (see https://fivem.net/server-hosting for limits)
sv_maxclients 48

# Steam Web API key, if you want to use Steam authentication (https://steamcommunity.com/dev/apikey)
# -> replace "" with the key
set steam_webApiKey ""

# License key for your server (https://portal.cfx.re)
sv_licenseKey changeme
EOF

}

function checkPort(){
    lsof -i :40120
    if [[ $( echo $? ) == 0 ]]; then
        if [[ "${non_interactive}" == "false" ]]; then
            if [[ "${kill_txAdmin}" == "0" ]]; then
                status "It looks like there already is something running on the default TxAdmin port. Can we stop/kill it?" "/"
                export OPTIONS=("Kill PID on port 40120" "Exit the script")
                bashSelect

                case $? in
                    0 )
                        kill_txAdmin="true"
                        ;;
                    1 )
                        exit 0
                        ;;
                esac
            fi
        fi
        if [[ "${kill_txAdmin}" == "true" ]]; then
            status "killing PID on 40120"
            runCommand "apt -y install psmisc"
            runCommand "fuser -4 40120/tcp -k"
            return
        fi

        echo -e "${red}Error:${reset} It looks like there already is something running on the default TxAdmin port."
        exit 1
    fi
}

function checkDir(){
    if [[ -e $dir ]]; then
        if [[ "${non_interactive}" == "false" ]]; then
            if [[ "${delete_dir}" == "0" ]]; then
                status "It looks like there already is a $dir directory. Can we remove it?" "/"
                export OPTIONS=("Remove everything in $dir" "Exit the script ")
                bashSelect
                case $? in
                    0 )
                    delete_dir="true"
                    ;;
                    1 )
                    exit 0
                    ;;
                esac
            fi
        fi
        if [[ "${delete_dir}" == "true" ]]; then
            status "Deleting $dir"
            runCommand "rm -r $dir"
            return
        fi

        echo -e "${red}Error:${reset} It looks like there already is a $dir directory."
        exit 1
    fi
}


function selectDeployment(){
    if [[ "${txadmin_deployment}" == "0" ]]; then
        txadmin_deployment="true"

        if [[ "${non_interactive}" == "false" ]]; then
            status "Select deployment type"
            export OPTIONS=("Install template via TxAdmin" "Use the cfx-server-data" "do nothing")
            bashSelect

            case $? in
                0 )
                    txadmin_deployment="true"
                    ;;
                1 )
                    txadmin_deployment="false"
                    ;;
                2 )
                    exit 0
            esac
        fi
    fi
    if [[ "${txadmin_deployment}" == "false" ]]; then
        examServData
    fi
}

function createCrontab(){
    if [[ "${crontab_autostart}" == "0" ]]; then
        crontab_autostart="false"

        if [[ "${non_interactive}" == "false" ]]; then
            status "Create crontab to autostart txadmin (recommended)"
            export OPTIONS=("yes" "no")
            bashSelect

            if [[ $? == 0 ]]; then
                crontab_autostart="true"
            fi
        fi
    fi
    if [[ "${crontab_autostart}" == "true" ]]; then
        status "Create crontab entry"
        runCommand "echo \"@reboot          root    /bin/bash /home/FiveM/start.sh\" > /etc/cron.d/fivem"
    fi
}

function installPma(){
    if [[ "${non_interactive}" == "false" ]]; then
        if [[ "${install_phpmyadmin}" == "0" ]]; then
            status "Install MariaDB/MySQL and phpmyadmin"

            export OPTIONS=("yes" "no")

            bashSelect

            case $? in
                0 )
                    install_phpmyadmin="true"
                    ;;
                1 )
                    install_phpmyadmin="false"
                    ;;
            esac
        fi
    fi
    if [[ "${install_phpmyadmin}" == "true" ]]; then
        runCommand "bash <(curl -s https://raw.githubusercontent.com/JulianGransee/PHPMyAdminInstaller/main/install.sh) -s ${pma_options[*]}"
    fi
}

function install(){
    runCommand "apt update -y" "updating"
    runCommand "apt install -y wget git curl dos2unix net-tools sed screen xz-utils lsof" "installing necessary packages"

    checkPort
    checkDir
    selectDeployment
    selectVersion
    createCrontab
    installPma


    runCommand "mkdir -p $dir/server" "Create directories for the FiveM server"
    runCommand "cd $dir/server/"


    runCommand "wget $artifacts_version" "FxServer is getting downloaded"

    runCommand "tar xf fx.tar.xz" "unpacking FxServer archive"
    runCommand "rm fx.tar.xz"

    status "Creating start, stop and access script"
    cat << EOF > $dir/start.sh
#!/bin/bash
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"
port=\$(lsof -Pi :40120 -sTCP:LISTEN -t)
if [ -z "\$port" ]; then
    screen -dmS fivem sh $dir/server/run.sh
    echo -e "\n\${green}TxAdmin was started!\${reset}"
else
    echo -e "\n\${red}The default \${reset}\${bold}TxAdmin\${reset}\${red} is already in use -> Is a \${reset}\${bold}FiveM Server\${reset}\${red} already started?\${reset}"
fi
EOF
    runCommand "chmod +x $dir/start.sh"

    runCommand "echo \"screen -xS fivem\" > $dir/attach.sh"
    runCommand "chmod +x $dir/attach.sh"

    runCommand "echo \"screen -XS fivem quit\" > $dir/stop.sh"
    runCommand "chmod +x $dir/stop.sh"


    port=$(lsof -Pi :40120 -sTCP:LISTEN -t)

    if [[ -z "$port" ]]; then

        if [[ -e '/tmp/fivem.log' ]]; then
        rm /tmp/fivem.log
        fi
        screen -L -Logfile /tmp/fivem.log -dmS fivem $dir/server/run.sh

        sleep 2

        line_counter=0
        while true; do
        while read -r line; do
            echo $line
            if [[ "$line" == *"able to access"* ]]; then
            break 2
            fi
        done < /tmp/fivem.log
        sleep 1
        done

        cat -v /tmp/fivem.log > /tmp/fivem.log.tmp

        while read -r line; do
        echo $line_counter
        if [[ "$line" == *"PIN"*  ]]; then
            let "line_counter += 2"
            break 2
        fi
        let "line_counter += 1"
        done < /tmp/fivem.log.tmp

        pin_line=$( head -n $line_counter /tmp/fivem.log | tail -n +$line_counter )
        echo $line_counter
        echo $pin_line > /tmp/fivem.log.tmp
        pin=$( cat -v /tmp/fivem.log.tmp | sed --regexp-extended --expression='s/\^\[\[([0-9][0-9][a-z])|([0-9][a-z])|(\^\[\[)|(\[.*\])|(M-bM-\^TM-\^C)|(\^M)//g' )
        pin=$( echo $pin | sed --regexp-extend --expression='s/[\ ]//g' )

        echo $pin
        rm /tmp/fivem.log.tmp
        clear

        echo -e "\n${green}${bold}TxAdmin${reset}${green} was started successfully${reset}"
        txadmin="http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):40120"
        echo -e "\n\n${red}${uline}Commands just usable via SSH\n"
        echo -e "${red}To ${reset}${blue}start${reset}${red} TxAdmin run -> ${reset}${bold}sh $dir/start.sh${reset} ${red}!\n"
        echo -e "${red}To ${reset}${blue}stop${reset}${red} TxAdmin run -> ${reset}${bold}sh $dir/stop.sh${reset} ${red}!\n"
        echo -e "${red}To see the ${reset}${blue}\"Live Console\"${reset}${red} run -> ${reset}${bold}sh $dir/attach.sh${reset} ${red}!\n"

        echo -e "\n${green}TxAdmin Webinterface: ${reset}${blue}${txadmin}\n"

        echo -e "${green}Pin: ${reset}${blue}${pin:(-4)}${reset}${green} (use it in the next 5 minutes!)"

        echo -e "\n${green}Server-Data Path: ${reset}${blue}$dir/server-data${reset}"

        if [[ "$install_phpmyadmin" == "true" ]]; then
            echo
            echo "MariaDB and PHPMyAdmin data:"
            runCommand "cat /root/.mariadbPhpma"
            runCommand "rm /root/.mariadbPhpma"
            rootPasswordMariaDB=$( cat /root/.mariadbRoot )
            rm /root/.mariadbRoot
            fivempasswd=$( pwgen 32 1 );
            mariadb -u root -p$rootPasswordMariaDB -e "CREATE DATABASE fivem;"
            mariadb -u root -p$rootPasswordMariaDB -e "GRANT ALL PRIVILEGES ON fivem.* TO 'fivem'@'localhost' IDENTIFIED BY '${fivempasswd}';"
            echo "
FiveM MySQL-Data
    User: fivem
    Password: ${fivempasswd}
    Database name: fivem
    FiveM MySQL Connection-String:
        set mysql_connection_string \"server=127.0.0.1;database=fivem;userid=fivem;password=${fivempasswd}\""
        runCommand "cat /root/.PHPma"
        fi

        sleep 1

    else
        echo -e "\n${red}The default ${reset}${bold}TxAdmin${reset}${red} port is already in use -> Is a ${reset}${bold}FiveM Server${reset}${red} already running?${reset}"
    fi
}

function update() {
    selectVersion

    if [[ "${non_interactive}" == "false" ]]; then
        status "Select the alpine directory"
        readarray -t directories <<<$(find / -name "alpine")
        export OPTIONS=(${directories[*]})

        bashSelect

        dir=${directories[$?]}/..
    else
        if [[ "$update_artifacts" == false ]]; then
            echo -e "${red}Error:${reset} Directory must be specified in non-interactive mode using --update <path>."
            exit 1
        fi
        dir=$update_artifacts
    fi

    checkPort

    runCommand "rm -rf $dir/alpine" "${red}Deleting alpine"
    runCommand "rm -f $dir/run.sh" "${red}Deleting run.sh"
    runCommand "wget --directory-prefix=$dir $artifacts_version" "Downloading fx.tar.xz"
    echo "${green}Success"
    runCommand "tar xf $dir/fx.tar.xz -C $dir" "Unpacking fx.tar.xz"
    echo "${green}Success"
    runCommand "rm -r $dir/fx.tar.xz" "${red}Deleting fx.tar.xz"
    clear
    echo "${green}Update success"
    exit 0
}

function main(){
    curl --version
    if [[ $? == 127  ]]; then  apt update -y && apt -y install curl; fi
    clear 

    if [[ "${non_interactive}" == "false" ]]; then
        source <(curl -s https://raw.githubusercontent.com/JulianGransee/BashSelect.sh/main/BashSelect.sh)
        
        if [[ "${update_artifacts}" == "false" ]]; then
            export OPTIONS=("install FiveM" "update FiveM" "do nothing")
            bashSelect

            case $? in
                0 )
                    install;;
                1 )
                    update;;
                2 )
                    exit 0
            esac
        fi
        exit 0
    fi
    
    if [[ "${update_artifacts}" == "false" ]]; then
        install
    else
        update
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo -e "${bold}Usage: bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/setup.sh) [OPTIONS]${reset}"
            echo "Options:"
            echo "  -h, --help                      Display this help message."
            echo "      --non-interactive           Skip all interactive prompts by providing all required inputs as options."
            echo "                                  If --phpmyadmin is included, you must also choose between --simple or --security."
            echo "                                      When using --security, you must provide both --db_user and --db_password."
            echo "  -v, --version <URL|latest>      Choose a artifacts version."
            echo "                                  Default: latest"
            echo "  -u, --update <path>             Update the artifacts version and specify the directory."
            echo "                                  Use -v or --version to specify the version or it will use the latest version."
            echo "      --no-txadmin                Disable txAdmin deployment and use cfx-server-data."
            echo "  -c, --crontab                   Enable or disable crontab autostart."
            echo "      --kill-port                 Forcefully stop any process running on the TxAdmin port (40120)."
            echo "      --delete-dir                Forcefully delete the /home/FiveM directory if it exists."
            echo ""
            echo "PHPMyAdminInstaller Options:"
            echo "  -p, --phpmyadmin                Enable or disable phpMyAdmin installation."
            echo "      --db_user <name>            Specify a database user."
            echo "      --db_password <password>    Set a custom password for the database."
            echo "      --generate_password         Automatically generate a secure password for the database."
            echo "      --reset_password            Reset the database password if one already exists."
            echo "      --remove_db                 Remove MySQL/MariaDB and reinstall it."
            echo "      --remove_pma                Remove phpMyAdmin and reinstall it if it already exists."
            exit 0
            ;;
        --non-interactive)
            non_interactive=true
            pma_options+=("--non-interactive")
            shift
            ;;
        -v|--version)
            artifacts_version="$2"
            shift 2
            ;;
        -u|--update)
            update_artifacts="$artifacts_version"
            shift 2
            ;;
        --no-txadmin)
            txadmin_deployment=false
            shift
            ;;
        -p|--phpmyadmin)
            install_phpmyadmin=true
            shift
            ;;
        -c|--crontab)
            crontab_autostart=true
            shift
            ;;
        --kill-port)
            kill_txAdmin=true
            shift
            ;;
        --delete-dir)
            delete_dir=true
            shift
            ;;

        # PHPMyAdmin installer Options:
        --security)
            pma_options+=("--security")
            shift
            ;;
        --simple)
            pma_options+=("--simple")
            shift
            ;;
        --db_user)
            pma_options+=("--db_user $2")
            shift 2
            ;;
        --db_password)
            pma_options+=("--db_password $2")
            shift 2
            ;;
        --generate_password)
            pma_options+=("--generate_password")
            shift
            ;;
        --reset_password)
            pma_options+=("--reset_password")
            shift
            ;;
        --remove_db)
            pma_options+=("--remove_db")
            shift
            ;;
        --remove_pma)
            pma_options+=("--remove_pma")
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "${non_interactive}" == "true" && "${install_phpmyadmin}" == "true" ]]; then
    errors=()

    if ! printf "%s\n" "${pma_options[@]}" | grep -q -- "--security" && 
       ! printf "%s\n" "${pma_options[@]}" | grep -q -- "--simple"; then
        errors+=("${red}Error:${reset} With --non-interactive, either --security or --simple must be set.")
    fi

    if printf "%s\n" "${pma_options[@]}" | grep -q -- "--security"; then
        if ! printf "%s\n" "${pma_options[@]}" | grep -q -- "--db_user"; then
            errors+=("${red}Error:${reset} With --non-interactive and --security, --db_user <user> must be set.")
        fi

        if ! printf "%s\n" "${pma_options[@]}" | grep -q -- "--db_password" && 
           ! printf "%s\n" "${pma_options[@]}" | grep -q -- "--generate_password"; then
            errors+=("${red}Error:${reset} With --non-interactive and --security, either --db_password <password> or --generate_password must be set.")
        fi
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        for error in "${errors[@]}"; do
            echo -e "$error"
        done
        exit 1
    fi
fi

main
