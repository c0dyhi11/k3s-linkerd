#!/bin/bash
WORKER_NODE_IP='${worker_node_ip}'
GLOBAL_IP='${global_ip}'
GLOBAL_NETMASK='${global_netmask}'
GLOBAL_CIDR='${global_cidr}'
BGP_PASSWORD='${bgp_password}'
BGP_ASN='${bgp_asn}'

ssh root@$WORKER_NODE_IP <<-SSH
    apt-get update -y
    apt-get install bird -y
    cat <<-EOS >> /etc/network/interfaces

auto lo:0
iface lo:0 inet static
    address $GLOBAL_IP
    netmask $GLOBAL_NETMASK
EOS

    mv /etc/bird/bird.conf /etc/bird/bird.conf.old
    cat <<-EOF >> /etc/bird/bird.conf
filter packet_bgp {
    if net = $GLOBAL_IP/$GLOBAL_CIDR then accept;
}
router id __PRIVATE_IPV4_ADDRESS__;
protocol direct {
    interface "lo";
}
protocol kernel {
    scan time 10;
    persist;
    import all;
    export all;
}
protocol device {
    scan time 10;
}
protocol bgp {
    export filter packet_bgp;
    local as $BGP_ASN;
    neighbor __GATEWAY_IP__ as 65530;
    password "$BGP_PASSWORD"; 
}
EOF
SSH
ssh root@$WORKER_NODE_IP <<-'SSH'
    HOST_ID=`curl https://metadata.packet.net/2009-04-04/meta-data/instance-id`
    AUTH_TOKEN='${auth_token}'
    curl -X POST -H "X-Auth-Token: $AUTH_TOKEN" https://api.packet.net/devices/$HOST_ID/bgp/sessions?address_family=ipv4
    IP_ADDRESS=`ip -4 a show dev bond0 | grep 'inet 10'| awk '{print $2}' | awk -F'/' '{print $1}'`
    GATEWAY=`ip route | grep $IP_ADDRESS | awk -F'/' '{print $1}'`
    sed -i "s/__PRIVATE_IPV4_ADDRESS__/$IP_ADDRESS/g" /etc/bird/bird.conf
    sed -i "s/__GATEWAY_IP__/$GATEWAY/g" /etc/bird/bird.conf
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    ifup lo:0
    systemctl restart bird
SSH
