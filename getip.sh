NETWORK_INTERFACES=$(ls /sys/class/net)

DNS_ADDRESS=$(nmcli device show ${NETNAME}|grep "IP4\.DNS\[1\]"|awk '{print $2}')
echo "DNS ADDRESS:${DNS_ADDRESS}"

# Get exported IP Adreess
[ ! -z "$(echo ${NETWORK_INTERFACES} | grep "wlo1")" ] && NETNAME="wlo1"
[ ! -z "$(echo ${NETWORK_INTERFACES} | grep "eno1")" ] && NETNAME="eno1"
IP_ADDRESS=$(ifconfig ${NETNAME}|grep "inet "|awk -F: '{print $1}'|awk '{print $2}')
[ $# -gt 0 ]&&IP_ADDRESS=$1
echo "IP ADDRESS:${IP_ADDRESS}"
