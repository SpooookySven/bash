#!/bin/bash
# dependency: sudo apt-get install --reinstall network-manager network-manager-gnome network-manager-openvpn network-manager-openvpn-gnome aws-cli jq

vpn_name=$1
store_path="/home/sven/certs"
client_cert="$store_path/sven.herrmann.tld.crt"
client_key="$store_path/sven.herrmann.tld.key" 

endpoint_id=$(aws ec2 describe-client-vpn-endpoints --filters "Name=tag:Name,Values=$vpn_name" --query 'ClientVpnEndpoints[*].ClientVpnEndpointId' --output=text)

aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id $endpoint_id --output text > $store_path/$vpn_name.ovpn

nmcli connection delete $vpn_name
nmcli connection import type openvpn file $store_path/$vpn_name.ovpn
nmcli connection modify $vpn_name +vpn.data cert=$client_cert
nmcli connection modify $vpn_name +vpn.data key=$client_key
nmcli connection modify $vpn_name +vpn.data cert-pass-flags=0

nmcli con up id $vpn_name

exit 0
