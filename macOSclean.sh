#!/bin/bash
#https://github.com/TarikvdBerg/MacOSSetupScript
set -e

ask() {
    # https://gist.github.com/davejamesmiller/1965569
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}



#Change current user(admin account) password
echo -e "You're logged into $USER \n"

if ask "Do you want change the password?"; then
	changePassword=yes
else
	changePassword=no
fi

if [ "$changePassword" = "yes" ]; then
	echo -e "Enter the new password"
	read newPasswordAdmin
	sudo dscl . -passwd /Users/$USER "$newPasswordAdmin"
	echo -e "Password for $USER succefully changed\n"
fi

if ask "Do you want add a Wifi network?"; then
	addWifi=yes
else
	addWifi=no
fi

if [ "$addWifi" = "yes" ]; then
	#Connecting to wifi
	while [ "$connectWifiDone" != "no" ]; do
		echo -e "Add a wifi network\n"

		while [ "$confirmWifi" != "yes" ]; do

			echo -e "Enter the wifi SSID"
			read wifiSSID
			echo -e "Enter the wifi password"
			read wifiPass
			echo -e "\n The following hardware adapters are availble on this device:\n"
			networksetup -listallhardwareports
			echo -e "\n Please enter the correct one:"
			read wifiAdapter
      			echo -e "\nYou've entered:\nSSID: $wifiSSID\nPassword: $wifiPass\nWiFi-adapter:$wifiAdapter:\n"
			if ask "Is this correct?" Y; then
				confirmWifi=yes
			else
				confirmWifi=no
			fi
		done
		sudo networksetup -setairportnetwork en0 "$wifiSSID" "$wifiPass"
		echo -e "Wifi succesfully changed\n"

		if ask "Do you want to add antother WiFi network?" N; then
			connectWifiDone=yes
		else
			connectWifiDone=no
		fi
		confirmWifi=no
	done

fi

#print a list of all account on the system
        echo -e "\nList of current user accounts on this system:"
        dscl . list /Users | grep -v '^_'
if ask "Do you want delete an account of this device?"; then
	deleteAccount=yes
else
	deleteAccount=no
fi

if [ "$deleteAccount" = "yes" ]; then
	#Start account deletion proccess loop
	while [ "$confirmDelDone" != "no" ]; do

	        #print a list of all account on the system
		echo -e "\nList of current user accounts on this system:"
		dscl . list /Users | grep -v '^_'

		#Type the name of the account that you want to delete and confirm
		while [ "$confirmAccount" != "yes" ];  do
			echo -e "\nEnter the name of the account you want to delete and press enter:\n"
			read name

			if ask "You want to delete $name" Y; then
	  		    confirmAccount=yes
			else
			    confirmAccount=no
			fi
		done

		#Deletion proccess
		echo -e "\n$name will be deleted now\n"
		sudo dscl localhost delete /Local/Default/Users/$name
		sudo rm -rf /Users/$name
		echo -e "The account has been deleted\n"
	#Check if account deletion is complete or if more need to be deleted

		echo -e "\nList of left over accounts:"
		dscl . list /Users | grep -v '^_'

		if ask "Do you want to delete another account?" N; then
			confirmDelDone=yes
		else
			confirmDelDone=no
		fi
		confirmAccount=no
	done
fi
#Start account creation
if ask "Do you want to create an account on this device?"; then
	createAccount=yes
else
	createAccount=no
fi

if [ "$createAccount" = "yes" ]; then
	echo -e "\nPlease enter the following information to create an account:\n"

	#Gather user information to create the account

	while [ "$confirmAccountInfo" != "yes" ]; do

		echo -e "\nWhat is the users real name?"
		read fullName

		echo -e "\nWhat should be the account name?"
		read accountName

		echo -e "\nWhat should be $accountName ID"
		read accountID

		echo -e "\nWhat should be the password?"
		read password

		echo -e "\nThe account name will be: $accountName"
		echo -e "The Users name will be: $fullName"
		echo -e "The account ID will be: $accountID"
		echo -e "The password will be set to: $password"

		if ask "Is this information correct?" Y; then
			confirmAccountInfo=yes
		else
			confirmAccountInfo=no
		fi
	done

	sudo dscl . -create /Users/$accountName
	sudo dscl . -create /Users/$accountName UserShell /bin/bash
	sudo dscl . -create /Users/$accountName RealName "$fullName"
	sudo dscl . -create /Users/$accountName UniqueID "$accountID"
	sudo dscl . -create /Users/$accountName PrimaryGroupID 20
	sudo dscl . -create /Users/$accountName NFSHomeDirectory /Users/$fullName
	sudo dscl . -passwd /Users/$accountName "$password"

	sudo dscl . -append /Groups/admin GroupMembership $accountName


	echo -e "$accountName has been succesfully created"
	echo -e "You need to reboot the pc for these changes to take effect\n"

fi

if ask "Do you want to change the names on this device?"; then
	changeName=yes
else
	changeName=no
fi

if [ "$changeName" = "yes" ]; then
	#Start changing names

	while [ "$confirmDeviceName" != "yes" ]; do
		echo -e "What do you want to set as Host name on this device?"
		read hostName

		if ask "Is $hostName the correct name?" Y; then
			confirmDeviceName=yes
		else
			confirmDeviceName=no
		fi
	done

	sudo scutil --set ComputerName "$hostName"
	sudo scutil --set LocalHostName "$hostName"
	sudo scutil --set HostName "$hostName"
	sudo dscacheutil -flushcache
	echo -e "Device name has succesfully been set to $hostName\n"
fi
if ask "Do you want to install updates?"; then
	installUpdates=yes
else
	installUpdates=no
fi

if [ "$installUpdates" = "yes" ]; then
echo -e "Updates will now be installed\n"
sudo softwareupdate -i -a
fi

if ask "Do you want to reboot?"; then
	wantReboot=yes
else
	wantReboot=no
fi

if [ "$wantReboot" = "yes" ]; then
	sudo reboot
fi
