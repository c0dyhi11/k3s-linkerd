data "template_file" "setup_bgp_script" {
    count = length(var.server_topology)
    template = file("templates/scripts/setup_bgp.sh")
    vars = {
        worker_node_ip = element(packet_device.k3s_worker_nodes.*.access_public_ipv4, count.index)
        global_ip = packet_reserved_ip_block.global_ip.address
        global_netmask = packet_reserved_ip_block.global_ip.netmask
        global_cidr = packet_reserved_ip_block.global_ip.cidr
        bgp_password = random_string.bgp_password.result
        bgp_asn = var.bgp_asn
        auth_token = var.auth_token
    }
}

resource "null_resource" "setup_bgp"{
    depends_on = [
        null_resource.install_k3s
    ]
    count = length(var.server_topology)
    
    connection {
        type = "ssh"
        user = "root"
        private_key = file(var.ssh_key_path)
        host = element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)
    }

    provisioner "remote-exec" {
        inline = ["mkdir -p /root/bootstrap/scripts/"]
    }
    
    provisioner "file" {
        content = element(data.template_file.setup_bgp_script.*.rendered, count.index)
        destination = "/root/bootstrap/scripts/setup_bgp.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /root/bootstrap/scripts/setup_bgp.sh"]
    }
}
