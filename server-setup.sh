#!/bin/bash

VERSION="1.16.5"
PROXY_URL="https://papermc.io/api/v1/waterfall/${VERSION}/latest/download"
PAPER_URL="https://papermc.io/api/v1/paper/${VERSION}/latest/download"
SERVER_PATH=/srv/mc
PROXY_PATH=/srv/proxy
SERVER_NAMES=()
START_FILE=start.sh

# all the thing you have to download from github

RAW_START="https://raw.githubusercontent.com/Lordva/minecraft-server-installer/master/start.sh"
PROXY_SERVICE_RAW="https://raw.githubusercontent.com/Lordva/minecraft-server-installer/master/bungeecord.service"
SERVICE_RAW="https://raw.githubusercontent.com/Lordva/minecraft-server-installer/master/mcserver%40.service"

PORT=25565 # default port of a minecraft server, do not change
START_TIME=$(date +"%T") # script startup time
DEFAULT_DIR=$(pwd) 
EULA_ACCEPTED=false # you can set it to true and skip the eula part of the script

# Eula accept function

eula(){
	if [ $EULA_ACCEPTED = true ]; then
		return 0
	fi
        read -r -p "Do you accept the eula ? [yes/no]: " key
                case $key in
                        y ) return 0 ;;
                        Y ) return 0 ;;
                        yes ) return 0 ;;
                        YES ) return 0 ;;
                        Yes ) return 0 ;;
                        * ) return 1 ;;
                esac           
}

function java_install(){
	if java -version >/dev/null 
	then
		echo -e "[$(date +"%T") LOG] Java is installed"
	else
		echo -e "[$(date +"%T") LOG] Java is not installed"
		apt-get install openjdk-11-jre-headless -y
	fi
}

usage(){
    cat <<EOF
usage: ${0##*/} [options]

    Options:
        -c <number of servers> <server names>   Create a server or a list of servers linked with bungeecord
        -d <server name>                        Delete a server (delete service and directory)
        -u <server path>                        Update a server
        -h                                      print help message
EOF
}

# looking for the firt argument ( -c or -h )  

if [ "$1" = "-c" ]; then 
	# checking for root permission
	if [ "$EUID" -ne 0 ]; then
		echo -e "-------------------------------------------------"
		echo -e "[ERROR] you need to be root to run this script  |"
		echo -e "-------------------------------------------------"
		echo -e "Retry with sudo, if you dont have permission please contact your server administrator"
		exit
	fi
	java_install #check for java install

	# checking if every server has a name and adding it to the SERVER_NAMES array
	if (( "$#" == "$2 + 2" )); then
		for ((i = 0 ; i+3 <= $# ; i++)); do
			n=$(($i + 3))
			SERVER_NAMES[$i]+=${!n}
		done
		echo -e "[$(date +"%T") LOG] you are creating those servers: ${SERVER_NAMES[*]}"
		# creation of the server folders
		for i in ${SERVER_NAMES[@]}; do
			echo -e "[$(date +"%T") LOG] creating folder ${SERVER_PATH:?}/$i"
			mkdir -p ${SERVER_PATH:?}"/"$i
			if [ ! -d ${SERVER_PATH:?}"/"$i ]; then
				echo -e "[ERROR] The creation of ${SERVER_PATH:?}/$i has failed !"
				exit
			else
				echo -e "[$(date +"%T") LOG] created ${SERVER_PATH:?}/$i"
				# Downloading paper if it is not alredy
				if [ ! -e "paperclip.jar" ]; then
					echo -e "[$(date +"%T") LOG] Downloading the latest version of PaperMC"
					wget $PAPER_URL -O paperclip.jar >/dev/null 2>&1
					RESULT=$?
					if [ $RESULT != 0 ]; then
						echo -e "------------------------------------------------------------"
						echo -e "[ERROR] failed to download the latest stable build of paper|"
						echo -e "------------------------------------------------------------"
						echo -e "cleaning the mess before stoping the script"
						rmdir ${SERVER_PATH:?}"/"$i
						exit
					else
						echo -e "[$(date +"%T") LOG] Successfully downloaded the latest Paper build !"
					fi
				fi
				
				# copying paper to the designated folder
				cp paperclip.jar ${SERVER_PATH:?}"/$i/server.jar"
				
				# Downloading the start.sh script if it hasen't alredy
				if [ -e $START_FILE ]; then
					echo -e "[$(date +"%T") LOG] $START_FILE exist"
				else
					echo -e "[$(date +"%T") LOG] $START_FILE doesn't exist, downloading it from GitHub..."
					wget $RAW_START >/dev/null
					chmod +x $START_FILE
					if [ ! -x $START_FILE ]; then
						echo -e "-------------------------------------------------"
						echo -e "[ERROR] Download has failed / is not executable |"
						echo -e "-------------------------------------------------"
						rm -rf ${SERVER_PATH:?}"/"$i
						exit
					else
						echo -e "[Successfully downloaded/chmod the start.sh script from GitHub]"
					fi
				fi
				# copying start.sh to the designated folder
				cp $START_FILE ${SERVER_PATH:?}"/"$i
				echo -e "[$(date +"%T") LOG] running the server to generate eula.txt"
				
				# going into the directory & running start.sh to generate files

				cd ${SERVER_PATH:?}"/"$i
				sh $START_FILE 2>&1 >/dev/null
				RESULT=$?
				if [ $RESULT != 0 ]; then
					echo -e "---------------------------------------------"
					echo -e "[ERROR] $START_FILE could not be executed...|"
					echo -e "---------------------------------------------"
					echo -e "cleaning the mess before exit"
					rm -rf ${SERVER_PATH:?}"/"$i
					exit
				fi
				
				# checking if eula.txt was generated by paper
				if [ ! -e "eula.txt" ]; then
					echo -e "---------------------------"
					echo -e "[ERROR] eula.txt not found|"
					echo -e "---------------------------"
					echo -e "cleaning the mess before leaving"
					rm -rf ${SERVER_PATH:?}"/"$i
					exit
				else
					echo -e "[$(date +"%T") LOG] eula.txt was successfully generated"
					echo -e "[$(date +"%T") LOG] setting eula.txt to True..."
					eula # calling the eula function
					RESULT=$?
				fi
				# checking for the eula return value
				if [ $RESULT != 0 ]; then
					echo -e "-----------------------------"
					echo -e "[error] eula wasn't accepted|"
					echo -e "-----------------------------"
					echo -e "cleaning mess before leaving"
					rm -rf ${SERVER_PATH:?}"/"$i & exit
				else
					EULA_ACCEPTED=true #setting to True so you don't have to accept eula for every server
					sed -i -e 's/false/true/g' eula.txt # making the actual change
        				RESULT=$?
        				if [ $RESULT != 0 ]; then
                				echo -e "--------------------------------------"
                				echo -e "[ERROR] eula could not be set to true|"
                				echo -e "--------------------------------------"
                				echo -e "cleaning the mess before leaving"
                				rm -rf ${SERVER_PATH:?}"/"$i & exit
        				else
                				echo -e "[$(date +"%T") LOG] eula.txt has been successfully set to True"
        				fi

					echo -e "[$(date +"%T") LOG] Restarting server to complete the install"
					# checking if screen is installed
					if ls /etc/screenrc >/dev/null ;  then
						echo -e "[$(date +"%T") LOG] Screen alredy installed"
					else
						
						echo -e "[$(date +"%T") LOG] Installing screen"

						#checking in your using apt or yum
						if apt -h 2>&1 >/dev/null != 0 ; then
							apt install screen -y >/dev/null 2>/dev/null
						else
							yum install screen -y 2&1 >/dev/null # could be not working, haven't tested
						fi
					fi
					echo -e "[$(date +"%T") LOG] starting screen session"

					# starting the screen for 15s then killing it
					screen -DmS mc-$i ./start.sh &
					sleep 15
					screen -p 0 -S mc-$i -X eval 'stuff "stop"\015'
					echo -e "[$(date +"%T") LOG] Server is fully installed"
				fi
				# Checking if the number of server to install is greater than 2 and therefore Bungeecord is needed
				if [ $2 -lt 2 ]; then
					echo -e "[INFO] Only one server, no need for a proxy"
				else

					echo -e "[$(date +"%T") LOG] $2 Server installed, configuring $i for proxy"
					sed -i -e 's/bungeecord: false/bungeecord: true/g' spigot.yml # setting Bungeecord to true in spigot.yml
					RESULT=$?
                                        if [ $RESULT != 0 ]; then
                                                echo -e "--------------------------------------"
                                                echo -e "[ERROR] bungeecord be set to true|"
                                                echo -e "--------------------------------------"
                                                echo -e "cleaning the mess before leaving"
                                                rm -rf ${SERVER_PATH:?}"/"$i & exit
                                        else
                                                echo -e "[$(date +"%T") LOG] bungeecord has been successfully set to True"
                                        fi
						
					sed -i -e 's/online-mode=true/online-mode=false/g' server.properties # setting online-mode to false in server.properties
					RESULT=$?
                                        if [ $RESULT != 0 ]; then
                                                echo -e "--------------------------------------"
                                                echo -e "[ERROR] online mode could not be set to false|"
                                                echo -e "--------------------------------------"
                                                echo -e "cleaning the mess before leaving"
                                                rm -rf ${SERVER_PATH:?}"/"$i & exit
                                        else
                                                echo -e "[$(date +"%T") LOG] online mode has been successfully set to false"
                                        fi

					echo -e "setting port used by server (default is incremented from 25565)"
					PORT=$((PORT+1)) # adding 1 from the default port (default port will be used by Bungeecord)
					sed -i -e "s/server-port=25565/server-port=$PORT/g" server.properties # making the actual change
					
					RESULT=$?
					if [ $RESULT != 0 ]; then
						echo -e "-----------------------------------------"
						echo -e "[ERROR] could not change the server port|"
						echo -e "-----------------------------------------"
						rm -rf ${SERVER_PATH:?}"/"$i & exit
					else
						echo -e "[$(date +"%T") LOG] the server port has been changed to $PORT"
					fi

					echo -e "[$(date +"%T") LOG] Server $2 has been configured for proxy"
				fi
			fi
			
		done
		
		# Begining of the Bungeecord install

		if [ $2 -gt 1 ]; then
			cd $DEFAULT_DIR
			PROXY_NEED=True
			echo ""
			echo ""
			echo -e "[$(date +"%T") LOG] Begining proxy install"

			echo -e "[$(date +"%T") LOG] creating folder ${SERVER_PATH:?}"
                        mkdir -p ${PROXY_PATH:?} # creating a proxy folder
                        if [ ! -d ${PROXY_PATH:?} ]; then
                                echo -e "[ERROR] The creation of ${PROXY_PATH:?} has failed !"
                                exit
                        else
                                echo -e "[$(date +"%T") LOG] created ${PROXY_PATH:?}"
				
				# Downloading Waterfall if it isen't alredy
                                if [ ! -e "Waterfall.jar" ]; then
                                        echo -e "[$(date +"%T") LOG] Downloading the latest version of Waterfall"
                                        wget $PROXY_URL >/dev/null 2>&1
                                        RESULT=$?
                                        if [ $RESULT != 0 ]; then
                                                echo -e "----------------------------------------------------------------"
                                                echo -e "[ERROR] failed to download the latest stable build of Waterfall|"
                                                echo -e "----------------------------------------------------------------"
                                                echo -e "cleaning the mess before stoping the script"
                                                rmdir ${PROXY_PATH:?}
                                                exit
                                        else
                                                echo -e "[$(date +"%T") LOG] Successfully downloaded the latest Waterfall build !"
                                        fi
				else
					echo -e "[$(date +"%T") LOG] Waterfall is already downloaded"
				fi
				# Coping Waterfall to proxy folder
				cp Waterfall.jar ${PROXY_PATH:?}"/proxy.jar"
				
				# Coping start.sh file to the destination folder

				cp $START_FILE ${PROXY_PATH:?}
				echo -e "[$(date +"%T") LOG] Configuring proxy for startup"
				
				cd ${PROXY_PATH:?}
				
				# Changing server.jar to proxy.jar in the start.sh script
				sed -i -e 's/server.jar/proxy.jar/g' $START_FILE
				RESULT=$?
                                if [ $RESULT != 0 ]; then
                                        echo -e "------------------------------------------"
                                        echo -e "[ERROR] could not edit start.sh for proxy|"
                                        echo -e "------------------------------------------"
                                        rm -rf ${SERVER_PATH:?}"/"$i & exit
                                else
                                        echo -e "[$(date +"%T") LOG] proxy ready for startup !"
				fi
				
				screen -DmS bungeecord ./start.sh & # starting screen session than stoping it after 30s to generate config
				sleep 30
				screen -p 0 -S bungeecord -X eval 'stuff "end"\015'
				echo -e "[$(date +"%T") LOG] Starting to edit config.yml"
				
				# Making all the changes needed to the config.yml file

				# the "gateway" server is replace from lobby to the first server
				sed -i -e "s/lobby:/${SERVER_NAMES}:/g" config.yml
				sed -i -e "s/lobby/${SERVER_NAMES}/g" config.yml
				sed -i -e "s/address: localhost:25565/address: localhost:25566/g" config.yml
				sed -i -e "s/ip_forward: false/ip_forward: true/g" config.yml
				sed -i -e "s/force_default_server: false/force_default_server: true/g" config.yml
				sed -i -e "s/host: 0.0.0.0:25577/host: 0.0.0.0:25565/g" config.yml
				
				# Asking for the server's MOTD
				read -r -p "Enter the serveur MOTD: " MOTD
				sed -i -e "s/motd: '&1Just another Waterfall - Forced Host/motd: '$MOTD'/g" config.yml
				port=25566
				# adding the others servers to the config
				for x in ${SERVER_NAMES[@]:1} ; do
					port=$(($port + 1))

					sed -i "24 a \ \ $x:" config.yml
					sed -i "25 a \ \ \ \ motd: '$MOTD'" config.yml
					sed -i "26 a \ \ \ \ address: localhost:$port" config.yml
					sed -i "27 a \ \ \ \ restricted: true" config.yml
				done
				echo -e "[$(date +"%T") LOG] Proxy setup complete !"
			fi
		fi

		# Service config
		cd $DEFAULT_DIR
		echo -e "[$(date +"%T") LOG] Service setup startup..."

		# Downloading the service file
		if [ ! -e mcserver@.service ]; then
			echo -e "[$(date +"%T") LOG] Could not find mcserver@.service, downloading it form GitHub"
			if wget $SERVICE_RAW ; then
				echo -e "[$(date +"%T") LOG] Successfully downloaded mcserver@.service"
			else
				echo -e "--------------------------------"
				echo -e "[ERROR] could not download file|"
				echo -e "--------------------------------"
				exit 1
			fi
		fi

		# copying service file to destination
		if cp mcserver@.service /etc/systemd/system/ ; then
			echo -e "[$(date +"%T") LOG] Successfully moved mcserver@.service to location"
		else
			echo -e "----------------------------"
                        echo -e "[ERROR] could not move file|"
                        echo -e "----------------------------"
                        exit 1
		fi
		
		# bungeecord service config
		if [[ $PROXY_NEED = "True" ]]; then
			if [ ! -e bungeecord.service ]; then
                        	echo -e "[$(date +"%T") LOG] Could not find bungeecord.service, downloading it form GitHub"
                        	if wget $PROXY_SERVICE_RAW ; then
                                	echo -e "[$(date +"%T") LOG] Successfully downloaded bungeecord.service"
                        	else
                                	echo -e "------------------------------------"
                                	echo -e "[ERROR] could not download the file|"
                                	echo -e "------------------------------------"
                                	exit 1
                        	fi
                	fi      
                	if cp bungeecord.service /etc/systemd/system/ ; then #copying service to destination
                        	echo -e "[$(date +"%T") LOG] Successfully moved bungeecord.service to location"
                	else
                        	echo -e "----------------------------"
                        	echo -e "[ERROR] could not move file|"
                        	echo -e "----------------------------"
                       		exit 1
                	fi
		fi

		# Starting everything (might not work depending on your ram, default ram in start.sh files is 2G per server, I strongly recomender lowering it)
		systemctl daemon-reload 
		echo -e "[$(date +"%T") LOG] Starting server(s)..."
		if [[ $PROXY_NEED = "True" ]]; then 
			systemctl start bungeecord 
		fi
		for i in ${SERVER_NAMES[@]}; do 
			systemctl start mcserver@$i 
		done
		echo -e "[$(date +"%T") LOG] Script ended at $(date +"%T") \n If you've encontered any unexpected beheviour please report in at https://github.com/Lordva/minecraft-server-installer/"
		exit 0


	else
		echo -e -e "[ERROR] you must give a name to each servers"
	fi
elif [ "$1" = "-d" ]; then
	echo -e "this feature has yet to be implemented"
elif [ "$1" = "-u" ]; then
	echo -e "this feature has yet to be implemented"

elif [[ -z $1 || $1 = @(-help|--help) ]]; then
    usage
    exit
fi

