#!/bin/bash

killservice () {
for pid in $(ps aux | grep vpnservice.sh | grep -v grep | awk -F ' ' '{print $2}');do kill -9 $pid; wait $pid 2>/dev/null;done
}

refresh () {
    killOVPN
    clear
    logo
    echo ""
    echo "Refreshing VPN config files, please wait..."
    touch $vpn_path/refresh
    while [ -f $vpn_path/refresh ];do
        sleep 2
    done
}

stopVPN () {
    touch $vpn_path/stop
}

killOVPN () {
 echo "Killing OVPN..."
        for i in {1..4}; do killall openvpn;done
        if [ -f currentvpn.txt ];then rm currentvpn.txt;fi
}


logo () {
echo "#####################################"
echo "######## VPN ROTATOR v.$version_number  #########"
echo "#####################################"
}

menu () {
echo ""
if [ -f $vpn_path/currentvpn.txt ];then
    echo "Currently connected to: $(cat currentvpn.txt)"
        echo "Connection established on $(date)"
else
    echo "** Not currently connected to the VPN **"
fi
echo ""
echo "1) Check VPN connection status"
echo "2) Start VPN in new country"
echo "3) Start VPN with new provider"
echo "4) Rotate VPN"
echo "5) Refresh VPN .ovpn files"
echo "6) VPN profiles management"
echo "7) Stop VPN (no internet connection)"
echo "8) Quit VPN Rotator"
echo ""
echo -n "Enter your choice and press [ENTER]: "
}

vpnprofilemanagement () {
clear
logo
echo ""
if [ -f $vpn_path/currentvpn.txt ];then
    echo "Currently connected to: $(cat currentvpn.txt)"
else
    echo "** Not currently connected to the VPN **"
fi
echo ""
echo "1) Create a new VPN profile"
echo "2) Edit existing VPN profile(s)"
echo "3) Delete existing VPN profile(s)"
echo "0) Back to main menu"
echo ""
echo ""
echo -n "Enter your choice and press [ENTER]: "
read choice

if [ $choice -eq 1 ];then setup_profiles;fi
if [ $choice -eq 2 ];then edit_profiles;fi
if [ $choice -eq 3 ];then delete_profiles;fi
if [ $choice -eq 0 ];then 
    clear
    logo
    menu
fi
}

countryselection () {
clear
logo
echo "List of available countries (and nb of servers):"
array_index=0
number=1
for i in $(ls -d $vpn_path/ovpn_files/Country_*);do
    nbovpn=$(ls $i | wc -l)
        echo "$number) $i ($nbovpn)" | sed 's@'"$vpn_path"'\/ovpn_files\/Country_@@g'
        providers[$array_index]=$(echo $i | sed 's@'"$vpn_path"'\/ovpn_files\/@@g')
        number=$(($number + 1))
        array_index=$(($array_index + 1))
done
echo "0) Back to main menu"
echo ""
echo -n "Enter your choice and press [ENTER]: "
read countrynumber

if [ $countrynumber -ne 0 ];then
    # Selected country
    providersindex=$(($countrynumber -1))
    provider=${providers[$providersindex]}
    countryname=$(echo $provider | sed 's/Country_//g')
    # Check that the folder is not empty
    if [ $(ls $vpn_path/ovpn_files/$provider | wc -l) -eq 0 ];then 
        clear
        echo "No VPN profiles in this folder!"
        sleep 2
        countrynumber=0
    else
        while [ -f $vpn_path/custom ];do
            clear
            echo "VPN currently busy, please wait..."
            sleep 2
        done
        echo $provider > $vpn_path/providers.txt
        touch $vpn_path/custom
        if [ -f $vpn_path/stop ];then rm $vpn_path/stop;fi
    fi
fi
}

providerselection () {
clear
logo
echo "List of available providers (and nb of servers):"
array_index=0
number=1
for i in $(ls -d $vpn_path/ovpn_files/* | grep -v "Country_");do
    nbovpn=$(ls $i | wc -l)
    echo "$number) $(echo $i | xargs -n 1 basename) ($nbovpn)"
    providers[$array_index]=$(echo $i | xargs -n 1 basename)
        number=$(($number + 1))
        array_index=$(($array_index + 1))
done
echo "0) Back to main menu"
echo ""
echo -n "Enter your choice and press [ENTER]: "
read providernumber

if [ $providernumber -ne 0 ];then
    # Selected provider
    providersindex=$(($providernumber -1))
    provider=${providers[$providersindex]}
    providername=$(echo $provider)
        while [ -f $vpn_path/custom ];do
            clear
            echo "VPN currently busy, please wait..."
            sleep 2
        done
    echo $provider > $vpn_path/providers.txt
    touch $vpn_path/custom
    if [ -f $vpn_path/stop ];then rm $vpn_path/stop;fi 
fi
}

status () {
if [ -f $vpn_path/currentvpn.txt ];then
    errors=$(tail -1 vpn.log | egrep -c '(Sequence Completed)')
    waittime=0
    while [ $errors -eq 0 ];do
        clear
        echo "Waiting for connection ($waittime/30)..."
        tail -5 $vpn_path/vpn.log
        sleep 2
        errors=$(tail -1 vpn.log | egrep -c '(Sequence Completed)')
        waittime=$((waittime +1))
        if [ $waittime -eq 30 ];then
            rm $vpn_path/currentvpn.txt
            rm $vpn_path/custom
            stopVPN
            break
        fi 
    done
    tail -5 $vpn_path/vpn.log
    sleep 5
else
    echo "No connection to report yet, please try again in a few seconds..."
    sleep 2
fi
}

setup_profiles () {
clear
logo
echo "Please enter the VPN provider's name (avoid spaces), followed by [ENTER]:"
echo "(Example: HMA)"
read vpn_name
echo "Please enter the URL to OVPN files (zip), followed by [ENTER]:"
echo "(Example: https://vpn.hidemyass.com/vpn-config/vpn-configs.zip)"
read vpn_configs_url
echo "Please enter the username you use for this VPN account, followed by [ENTER]:"
read vpn_username
echo "Please enter the password you use for this VPN account, followed by [ENTER]:"
read vpn_password
echo ""
read -p "Is the above information correct? [Y/N]:" -n 1 -r
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    if [ ! -d $vpn_path/vpn_profiles ];then mkdir $vpn_path/vpn_profiles/;fi
    echo "vpn_name=$vpn_name" > $vpn_path/vpn_profiles/$vpn_name.txt
    echo "vpn_configs_url=$vpn_configs_url" >> $vpn_path/vpn_profiles/$vpn_name.txt
    echo "vpn_username=$vpn_username" >> $vpn_path/vpn_profiles/$vpn_name.txt
    echo "vpn_password=$vpn_password" >> $vpn_path/vpn_profiles/$vpn_name.txt
    echo ""
    echo "Profile created successfully!"
    sleep 2
fi
echo ""
read -p "Would you like to create another profile? [Y/N]:" -n 1 -r
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    setup_profiles
fi

refresh
}

edit_profiles () {
clear
logo
echo "List of existing VPN profiles:"
number=1
for i in $(ls -d $vpn_path/vpn_profiles/*);do
    nbprofiles=$(ls $i | wc -l)
        echo "$number) $i" | sed 's@'"$vpn_path"'\/vpn_profiles\/@@g' | sed 's/.txt//g'
        number=$(($number + 1))
done
echo "0) Back to main menu"
echo ""
echo -n "Choose the one you wish to edit and press [ENTER]: "
read profilenumber
if [ $profilenumber -eq 0 ];then 
    clear
    logo
    menu
else
    nano $(ls -d $vpn_path/vpn_profiles/* | sed -n $profilenumber\p)
    refresh
fi
}

delete_profiles () {
clear
logo
echo "List of existing VPN profiles:"
number=1
for i in $(ls -d $vpn_path/vpn_profiles/*);do
    nbprofiles=$(ls $i | wc -l)
        echo "$number) $i" | sed 's@'"$vpn_path"'\/vpn_profiles\/@@g' | sed 's/.txt//g'
        number=$(($number + 1))
done
echo "0) Back to main menu"
echo ""
echo -n "Choose the one you wish to delete and press [ENTER]: "
read profilenumber
if [ $profilenumber -eq 0 ];then 
    clear
    logo
    menu
else
    read -p "Are you sure you want to delete the $(ls -d $vpn_path/vpn_profiles/* | sed -n $profilenumber\p) profile? [Y/N]:" -n 1 -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]
    then
        rm $(ls -d $vpn_path/vpn_profiles/* | sed -n $profilenumber\p)
        refresh
    fi
fi
}

choice_actions () {
if [ $choice -eq 1 ];then
    clear
    logo
    status
fi

if [ $choice -eq 2 ];then
        countryselection
        if [ $countrynumber -eq 0 ];then
            clear
        else
            clear
            logo
            echo "Starting VPN in $countryname..."
            sleep 15
            status
        fi
    fi

        if [ $choice -eq 3 ];then
                providerselection
        if [ $providernumber -eq 0 ];then
            clear
        else
                    clear
                    logo
                    echo "Starting VPN with $providername..."
                    sleep 15
                    status
        fi
        fi

    if [ $choice -eq 4 ];then
            touch $vpn_path/rotate
        clear
        logo
        echo "Rotating within $(cat providers.txt | sed 's/Country_//g')..."
        sleep 15
        status
    fi

    if [ $choice -eq 5 ];then
        clear
        logo
        refresh
        sleep 2
    fi

    if [ $choice -eq 6 ];then
        vpnprofilemanagement
    fi

    if [ $choice -eq 7 ];then
        clear
        logo
        echo "Stopping VPN..."
        stopVPN
        sleep 10
    fi

    if [ $choice -eq 8 ];then
        clear
        logo
        echo "Quitting VPN rotator..."
        stopVPN
        sleep 10
        killservice
        clear
        if [ -f $vpn_path/stop ];then rm $vpn_path/stop;fi
        exit
    fi

}

####################################

####################################

# Kill any previously running vpnservice
killservice

# VPN Rotation version number
version_number=2.1

# Adjust time
timedatectl set-ntp false
timedatectl set-ntp true

# Assign current VPN directory based on where script runs from
vpn_path=$(pwd)

# Check for VPN profiles and go through initial setup if needed
if [ ! "$(ls -A $vpn_path/vpn_profiles)" ]; then
    mkdir $vpn_path/vpn_profiles
    setup_profiles
fi

# Clean up
if [ -f $vpn_path/currentvpn.txt ];then rm $vpn_path/currentvpn.txt;fi
clear

# Start vpn service
bash $vpn_path/vpnservice.sh &>/dev/null &

# Download latest VPN configs
refresh

# Menu and infinite loop
while :
do
    clear
    logo
    menu
    read choice
    choice_actions
done
