# Global K3s Deployment on Packet Baremetal
This repo contains [Terraform](http://terraform.io) scripts to deploy [K3s](http://k3s.io) and [LinkerD](http://linkerd.io) on [Packet](http://packet.com) baremetal servers spanning the globe. By default five seperate k3s clusters (1x Master and 1x Worker) will be deployed using [Packet's t1.small.x86 & x1.small.x86](https://www.packet.com/cloud/servers) bare metal servers (only cheap as $0.07/hr). This also reserves a single global IPv4 address to be used as a BGP anycast endpoint so anyone connecting to that IP address will be directed to the closest cluster to them. We then add LinkerD to interconnect these clusters, as well as Packet's CCM and Autoscaler to allow these clusters to adapt to swell and contract to the load they are under. 

## Getting Started
You will need to first clone this repo, second ensure you have [Terraform](http://terraform.io) installed, third make sure you have [LinkerD's cli](https://github.com/linkerd/linkerd2/releases/) installed, lastly you will need a [Packet Account](https://app.packet.net/signup) (Use promo code ***cody*** for $30 in free cloud credits.)

You will now need to create a terraform.tfvars file that looks something like this:
```
auth_token="FExVfiQafmhLu3HWHHwh3WZD5drjw45z"
organization_id="ecd6e867-e5fb-3e0b-b90e-090a055437ee"
```
You can also override any variable from the 00_vars.tf file by specifying that variable in the terraform.tfvars file.

Once all this is done. All you have to do now is run ***terraform init && terraform apply --auto-approve*** from the root of this git repo. And your clusters will be created and wired together!

# About some of the tech... 

## LinkerD
LinkerD been chosen as a way to allow pods from each cluster to communicate with each other over an encrypted channel. Setting up LinkerD requires some pre-work such as generating certificates from a root ca and distributing them to each cluster. We've simplified this by generating a local CA based on OpenSSL.

## Cluster Autoscaler
Packet has developed a [Kubernetes Autoscaler](https://www.packet.com/resources/guides/kubernetes-cluster-autoscaler-on-packet/) that allows you to automatically add and subtract hardware whenever this is resource contention. This is installed automatically in this cluster and is regulated by the ***min_nodes*** & ***max_nodes*** variables for each cluster.

## Cloud Control Manager (CCM)
Packet has developed their [Kubernetes CCM](https://www.packet.com/resources/guides/kubernetes-ccm-for-packet/) which allows the cluster to know more information about the underlying nodes. This is a must have with the Cluster Autoscaler in so that when the Autoscaler removes a node, that node can bed deleted from Kubernetes gracefully.

## BGP Anycast
Packet allows you to utilize BGP ECMP in order to load balance traffic to your servers. And with [Packet Global IPs](https://www.packet.com/cloud/network/) you can load balance traffic across the globe as well.
 
