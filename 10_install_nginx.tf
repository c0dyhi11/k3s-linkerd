data "template_file" "nginx_ingress_values" {
    count = length(var.server_topology)
    template = file("templates/nginx/nginx_ingress_values.yaml")
}

resource "null_resource" "install_nginx"{
    depends_on = [
        null_resource.install_helm
    ]
    count = length(var.server_topology)
    
    connection {
        type = "ssh"
        user = "root"
        private_key = file(var.ssh_key_path)
        host = element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)
    }

    provisioner "remote-exec" {
        inline = ["mkdir -p /root/bootstrap/nginx/"]
    }

    provisioner "file" {
        content = element(data.template_file.nginx_ingress_values.*.rendered, count.index)
        destination = "/root/bootstrap/nginx/nginx_ingress_values.yaml"
    }

    provisioner "remote-exec" {
        inline = [
            "kubectl create namespace ingress-nginx",
            "helm install ingress-nginx stable/nginx-ingress --namespace ingress-nginx -f /root/bootstrap/nginx/nginx_ingress_values.yaml"
        ]
    }
}
