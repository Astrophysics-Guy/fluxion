#!/bin/bash

VIGW=$WIAccessPoint
VIAP=$WIAccessPoint

#APServiceAuthenticationMethods=("hash")
#APServiceAuthenticationMethodsInfo=("(handshake, recommended)")

# HostAPD sets the virtual interface mode
# to master, which is supported by dhcpd.
VIAPAddress=$VIGWAddress

VIAPRouteDelay=5

APServiceConfPath="$DUMP_PATH/APService.conf"

function ap_stop() {
	killall hostapd &> $FLUXIONOutputDevice

	local FLUXIONAPService=$(ps a | grep -e "FLUXION AP Service" | awk '{print $1'})
	if [ "$FLUXIONAPService" ]; then
		kill $FLUXIONAPService &> $FLUXIONOutputDevice
	fi
}

function ap_reset() {
	ap_stop

	# Reset MAC address to original.
	ifconfig $VIAP down
    sleep 0.4
    
	macchanger -p $VIAP &> $FLUXIONOutputDevice
    sleep 0.4

    ifconfig $VIAP up
    sleep 0.4
}

function ap_route() {
	echo "No custom routes for hostapd" > $FLUXIONOutputDevice
}

function ap_prep() {
	ap_stop

	# Prepare the hostapd config file.
	echo "\
interface=$VIAP
driver=nl80211
ssid=$APTargetSSID
channel=$APTargetChannel\
" > $APServiceConfPath

	# Spoof virtual interface MAC address.
	ifconfig $VIAP down
    sleep 0.4
    
	macchanger --mac=$APRogueMAC $VIAP &> $FLUXIONOutputDevice
    sleep 0.4

    ifconfig $VIAP up
    sleep 0.4
}

function ap_start() {
	xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FFFFFF" -title "FLUXION AP Service [hostapd]" -e hostapd $APServiceConfPath &
	sleep $VIAPRouteDelay; ap_route
}

# FLUXSCRIPT END
