variable "auth_token" {
    description = "Packet API Key"
}

variable "organization_id" {
    description = "Packet Organization ID"
}

variable "project_name" {
    description = "The name you want to give to your new Packet Project"
    default = "k3s-linkerd"
}

variable "operating_system" {
    description = "The Operating system of the node (Only Ubuntu 16.04 has been tested)"
    default = "ubuntu_18_04"
}

variable "billing_cycle" {
    description = "How the node will be billed (Not usually changed)"
    default = "hourly"
}

# TODO: Generate unique SSH Key for this terraform run
variable "ssh_key_path" {
    description = "Path to the private key you login to Packet servers with"
    default = "~/.ssh/id_rsa"
}

variable "k3s_version" {
    description = "The GitHub release version of k3s to install"
    default = "v1.17.4+k3s1"
}

variable "helm_version" {
    description = "The GitHub release version of helm to install"
    default = "v3.1.2"
}

variable "private_ip_cidr" {
    description = "This private IP CIDR will be subneted to give unique space to pods and services"
    default = "172.16.0.0/12"
}

variable "bgp_asn" {
    description = "BGP ASN to peer with Packet"
    default = 65000
}

variable "node_pool_name" {
    description = "Node Pool name for Kubernetes cluster autoscaler"
    default = "pool0"
}

variable "autoscaler_image_version" {
    description = "The version of the autoscaler docker image to use"
    default = "v1.17.0"
}

variable "server_topology" {
    description = "What do you want your server topology to look like?"
    default =   [
        {
            "cluster_name": "us-west-1",
            "facilty": "sjc1",
            "plan": "t1.small.x86",
            "min_nodes": 1,
            "max_nodes": 5
        },
        {
            "cluster_name": "us-central-1",
            "facilty": "dfw2",
            "plan": "x1.small.x86",
            "min_nodes": 1,
            "max_nodes": 5
        },
        {
            "cluster_name": "us-east-1",
            "facilty": "ewr1",
            "plan": "t1.small.x86",
            "min_nodes": 1,
            "max_nodes": 5
        },
        {
            "cluster_name": "eu-west-1",
            "facilty": "ams1",
            "plan": "t1.small.x86",
            "min_nodes": 1,
            "max_nodes": 5
        },
        {
            "cluster_name": "ap-east-1",
            "facilty": "nrt1",
            "plan": "t1.small.x86",
            "min_nodes": 1,
            "max_nodes": 5
        }
    ]
}

variable "country" { 
    description = "OpenSSL Cert Req Country"
    default = "US"
}
variable "state" {
    description = "OpenSSL Cert Req State"
    default = "Texas"
}
variable "city" {
    description = "OpenSSL Cert Req City"
    default = "Austin"
}
variable "org" {
    description = "OpenSSL Cert Req Organization"
    default = "Initech"
}
variable "unit" {
    description = "OpenSSL Cert Req Organizational Unit"
    default = "Technology"
}
variable "domain" {
    description = "OpenSSL Cert Req Domain"
    default = "initech.local"
}
variable "email" {
    description = "OpenSSL Cert Req Contact Email"
    default = "peter@initech.local"
}
