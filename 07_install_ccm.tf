data "template_file" "ccm_secret" {
    count = length(var.server_topology)
    template = file("templates/packet_ccm/ccm_secret.yaml")
    vars = {
        auth_token = var.auth_token
        project_id = packet_project.new_project.id
    }
}

data "template_file" "ccm_deployment" {
    count = length(var.server_topology)
    template = file("templates/packet_ccm/ccm_deployment.yaml")
}

resource "null_resource" "install_ccm"{
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
        inline = ["mkdir -p /root/bootstrap/packet_ccm/"]
    }

    provisioner "file" {
        content = element(data.template_file.ccm_secret.*.rendered, count.index)
        destination = "/root/bootstrap/packet_ccm/ccm_secret.yaml"
    }

    provisioner "file" {
        content = element(data.template_file.ccm_deployment.*.rendered, count.index)
        destination = "/root/bootstrap/packet_ccm/ccm_deployment.yaml"
    }

    provisioner "remote-exec" {
        inline = ["kubectl apply -f /root/bootstrap/packet_ccm/"]
    }
}
