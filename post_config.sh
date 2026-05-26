#!/bin/bash

set -e

if ! command -v whiptail &> /dev/null; then
	echo "Whiptail is not installed, impossible to show post installation steps."
	echo "Please run \"sudo apt install whiptail -y\" then logout and login again"
	exit 1
fi

whiptail --msgbox "Thanks for mining with us!\nLet's do the last steps to configure your datum box." 0 0

PASSWORD="todo"

while [ "$PASSWORD" != "$PASSWORD2" ]
do	
	PASSWORD=$(whiptail --nocancel --inputbox "For security reasons you must change the password of this server.\nPlease enter your new password:" 0 0 3>&1 1>&2 2>&3)
	PASSWORD2=$(whiptail --nocancel --inputbox "Please enter the password again:" 0 0 3>&1 1>&2 2>&3)
	
	if [ "$PASSWORD" != "$PASSWORD2" ]; then
		NEWT_COLORS="root=white,red" whiptail --msgbox "Both password didn't match, please try again." 0 0
	fi
	
	if [ "$PASSWORD" = "" ]; then
		NEWT_COLORS="root=white,red" whiptail --msgbox "Password must not be empty" 0 0
		PASSWORD="todo"
	fi
done

if echo "leo:$PASSWORD" | chpasswd; then
	NEWT_COLORS="root=white,green" whiptail --msgbox "Password sucessfully changed!" 0 0
else
	NEWT_COLORS="root=white,red" whiptail --msgbox "Failed to change password." 0 0
fi

unset PASSWORD PASSWORD2

whiptail --msgbox "We will now proceed to the Bitcoin node and DATUM Gateway configuration." 0 0

if ! dpkg-reconfigure -plow bitcoin-knots datum-gateway; then
	NEWT_COLORS="root=white,red" whiptail --msgbox "Failed to reconfigure Bitcoin Knots and/or DATUM Gateway" 0 0
fi

whiptail --msgbox "Your datum box is now configured!" 0 0

if [ -f /home/box/need_config ]; then
	rm /home/box/need_config
fi