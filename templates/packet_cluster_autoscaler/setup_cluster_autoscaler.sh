#!/bin/bash
MASTER_IP='${master_ip}'
API_PORT='${api_port}'
K3S_VER='${k3s_version}'
GLOBAL_IP='${global_ip}'
GLOBAL_NETMASK='${global_netmask}'
GLOBAL_CIDR='${global_cidr}'
BGP_PASSWORD='${bgp_password}'
BGP_ASN='${bgp_asn}'

TOKEN=`cat /var/lib/rancher/k3s/server/node-token`
URL="https://$MASTER_IP:$API_PORT"
K3S_SCRIPT=$(cat <<-EOF
#!/bin/bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VER K3S_URL=$URL K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent --kubelet-arg cloud-provider=external" sh -
apt-get update -y
apt-get install bird -y
cat <<-EOA >> /etc/network/interfaces

auto lo:0
iface lo:0 inet static
    address $GLOBAL_IP
    netmask $GLOBAL_NETMASK
EOA

mv /etc/bird/bird.conf /etc/bird/bird.conf.old
cat <<-EOB >> /etc/bird/bird.conf
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
EOB
EOF
)
K3S_SCRIPT="$K3S_SCRIPT$(cat <<-'EOC'

HOST_ID=`curl https://metadata.packet.net/2009-04-04/meta-data/instance-id`
AUTH_TOKEN='${auth_token}'
curl -X POST -H \"X-Auth-Token: $AUTH_TOKEN\" https://api.packet.net/devices/$HOST_ID/bgp/sessions?address_family=ipv4
IP_ADDRESS=`ip -4 a show dev bond0 | grep 'inet 10'| awk '{print $2}' | awk -F'/' '{print $1}'`
GATEWAY=`ip route | grep $IP_ADDRESS | awk -F'/' '{print $1}'`
sed -i \"s/__PRIVATE_IPV4_ADDRESS__/$IP_ADDRESS/g\" /etc/bird/bird.conf
sed -i \"s/__GATEWAY_IP__/$GATEWAY/g\" /etc/bird/bird.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
ifup lo:0
systemctl restart bird
EOC
)"
USER_DATA=$(printf "$K3S_SCRIPT" | base64 -w 0)
sed -i "s/__USER_DATA__/$USER_DATA/g" /root/bootstrap/packet_cluster_autoscaler/cluster_autoscaler_secret.yaml
