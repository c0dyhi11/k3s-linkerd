data "template_file" "helm_install_script" {
    count = length(var.server_topology)
    template = file("templates/scripts/install_helm.sh")
    vars = {
        helm_version = var.helm_version
    }
}

resource "null_resource" "install_helm"{
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
        content = element(data.template_file.helm_install_script.*.rendered, count.index)
        destination = "/root/bootstrap/scripts/install_helm.sh"
    }

    provisioner "remote-exec" {
        inline = ["bash /root/bootstrap/scripts/install_helm.sh"]
    }
}
