#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
	whiptail --msgbox "This script must be run with sudo." 0 0
	exit 1
fi

MENU="initial"
while [ "$MENU" != "7." ]
do
MENU=$(whiptail --nocancel --title "DATUM box menu" --menu "" 0 0 0 "1." "Show number of stratum workers" \
																	"2." "Show DATUM Gateway logs" \
																	"3." "Show Bitcoin Knots logs" \
																	"4." "Check bitcoind template endpoint" \
																	"5." "Reconfigure Bitcoin Knots" \
																	"6." "Reconfigure DATUM Gateway" \
																	"7." "Quit" 3>&1 1>&2 2>&3)

case $MENU in
	1.)
		if curl -sf -o /dev/null 127.0.0.1:7152; then
			NUMBER=$(curl -s 127.0.0.1:7152 | grep -A1 "Total Work Subscriptions" | tail -n 1 | sed 's/[^0-9]*//g')
			whiptail --msgbox "Number of connected clients: $NUMBER" 0 0
		else
			NEWT_COLORS="root=white,red" whiptail --msgbox "Failed to connect to the DATUM Gateway API.\nPlease consult the logs of the gateway." 0 0
		fi
	;;
	
	2.)
		journalctl -f -u datum-gateway
	;;
	
	3.)
		journalctl -f -u bitcoin-knots
	;;
	
	4.)
		if [ -f /var/lib/bitcoin/.cookie ]; then
			if [ $(curl --user $(sudo -u bitcoin cat /var/lib/bitcoin/.cookie) --data-binary '{"jsonrpc": "1.0", "id": "curltest", "method": "getblocktemplate", "params": [{"rules": ["segwit"]}]}' -H 'content-type: text/plain;' -s http://127.0.0.1:8332/ | jq '.result | has("version")') = "true" ]; then
				NEWT_COLORS="root=white,green" whiptail --msgbox "bitcoind is serving block template, good!" 0 0
			elif [ $(curl --user $(sudo -u bitcoin cat /var/lib/bitcoin/.cookie) --data-binary '{"jsonrpc": "1.0", "id": "curltest", "method": "getblocktemplate", "params": [{"rules": ["segwit"]}]}' -H 'content-type: text/plain;' -s http://127.0.0.1:8332/ | jq '.error.code') = "-10" ]; then
				NEWT_COLORS="root=white,#FFA500" whiptail --msgbox "bitcoind is still still downloading the Bitcoin blockchain.\nbitcoind will start making block template once done." 0 0
			else
				NEWT_COLORS="root=white,red" whiptail --msgbox "bitcoind isn't serving block template, please check the Bitcoin Knots logs for more information." 0 0
			fi
		else
			NEWT_COLORS="root=white,red" whiptail --msgbox "No cookie file detected, are you sure bitcoind is running?" 0 0
		fi
	;;
	
	5.)
		dpkg-reconfigure bitcoin-knots
	;;
	
	6.)
		dpkg-reconfigure datum-gateway
	;;
esac
done