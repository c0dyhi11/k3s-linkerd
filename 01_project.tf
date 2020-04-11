provider "packet" {
    auth_token = var.auth_token
}

resource "random_string" "bgp_password" {
    length = 18
    upper = true
    min_upper = 1 
    lower = true
    min_lower = 1 
    number = true
    min_numeric = 1 
    special = false
}

resource "packet_project" "new_project" {
    name = var.project_name
    organization_id = var.organization_id
    bgp_config {
        deployment_type = "local"
        asn = var.bgp_asn
        md5 = random_string.bgp_password.result
   }
}

resource "tls_private_key" "ssh_key_pair" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "packet_ssh_key" "ssh_pub_key" {
    name = var.project_name
    public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}
