data "template_file" "k3s_install_script" {
    count = length(var.server_topology)
    template = file("templates/scripts/install_k3s.sh")
    vars = {
        pod_cidr = cidrsubnet(var.private_ip_cidr, 5, 31 - count.index)
        service_cidr = cidrsubnet(var.private_ip_cidr, 5, count.index)
        cluster_name = element(var.server_topology.*.cluster_name, count.index)
        k3s_version = var.k3s_version
        master_node_ip = element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)
        worker_node_ip = element(packet_device.k3s_worker_nodes.*.access_public_ipv4, count.index)
        ssh_private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
        domain = var.domain
    }
}

resource "null_resource" "install_k3s"{
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
        content = element(data.template_file.k3s_install_script.*.rendered, count.index)
        destination = "/root/bootstrap/scripts/install_k3s.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /root/bootstrap/scripts/install_k3s.sh"]
    }
}
