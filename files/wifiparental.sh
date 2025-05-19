#!/bin/sh
. /lib/functions.sh;
SELFSCRIPT=$0

get_ifaces(){
    config_load 'wireless';
    config_foreach echo 'wifi-iface'
}

list_ssids(){
    ifaces="$(get_ifaces)"
    for iface in $ifaces
    do
        echo "$(uci -q get wireless."${iface}".device) $(uci -q get wireless."${iface}".ssid)"
    done
}

set_ssid_ability(){
    
	local device="$1"
	local ssid="$2"
	local ability="$3"

    ifaces="$(get_ifaces)"
    for iface in $ifaces
    do
        local iface_ssid="$(uci -q get wireless."${iface}".ssid)"
        local iface_device="$(uci -q get wireless."${iface}".device)"

        if [ "$ability" == "ALLON" ]; then 
                echo "wifi-iface:$iface ifacssid:$iface_ssid ENABLED"
                uci set wireless.${iface}.disabled=0
                uci commit wireless && wifi
        elif [ "$ability" == "ALLOFF" ]; then 
                echo "wifi-iface:$iface ifacssid:$iface_ssid DISABLED"
                uci set wireless.${iface}.disabled=1
                uci commit wireless && wifi        
        elif [ $iface_ssid == $ssid ] && [ $iface_device == $device ]; then			
            if [ $ability == 0 ]; then 
                echo "wifi-iface:$iface ifacssid:$iface_ssid DISABLED"
                uci set wireless.${iface}.disabled=1
                uci commit wireless && wifi
            elif [ $ability == 1 ]; then 
                echo "wifi-iface:$iface ifacssid:$iface_ssid ENABLED"
                uci set wireless.${iface}.disabled=0
                uci commit wireless && wifi
            fi
        fi
    done
    
}

cron_restart(){
    /etc/init.d/cron restart > /dev/null
}

cron_add_line(){
    (crontab -l ; echo "$1") | sort | uniq | crontab -
    cron_restart
}

cron_del_line(){
    crontab -l | grep -v "$1" |  sort | uniq | crontab -
    cron_restart
}

cron_clear_selfscript_lines(){
    cron_del_line "${SELFSCRIPT}"
}

cron_create_entry(){
    local DoW="$1"
    local ON_HH="$2"
    local ON_MM="$3"
    local OFF_HH="$4"
    local OFF_MM="$5"
    local device="$6"
	local ssid="$7"

    local on_entry=""${ON_MM}" "${ON_HH}" * * "${DoW}" "${SELFSCRIPT}" set_ssid_ability "${device}" "${ssid}" 1"
    local off_entry=""${OFF_MM}" "${OFF_HH}" * * "${DoW}" "${SELFSCRIPT}" set_ssid_ability "${device}" "${ssid}" 0"

    cron_add_line "$on_entry"
    cron_add_line "$off_entry"
}

"$@"
