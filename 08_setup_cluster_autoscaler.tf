data "template_file" "cluster_autoscaler_secret" {
    count = length(var.server_topology)
    template = file("templates/packet_cluster_autoscaler/cluster_autoscaler_secret.yaml")
    vars = {
        auth_token = base64encode(var.auth_token)
        project_id = packet_project.new_project.id
        master_ip = element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)
        api_port = 6443
        facility = element(var.server_topology.*.facilty, count.index)
        operating_system = var.operating_system
        plan = element(var.server_topology.*.plan, count.index)
        billing_cycle = var.billing_cycle
        
    }
}

data "template_file" "cluster_autoscaler_deployment" {
    count = length(var.server_topology)
    template = file("templates/packet_cluster_autoscaler/cluster_autoscaler_deployment.yaml")
    vars = {
        autoscaler_image_version = var.autoscaler_image_version
        cluster_name = element(var.server_topology.*.cluster_name, count.index)
        min_nodes = element(var.server_topology.*.min_nodes, count.index)
        max_nodes = element(var.server_topology.*.max_nodes, count.index)
        pool_name = var.node_pool_name
    }
}

data "template_file" "cluster_autoscaler_svcaccount" {
    count = length(var.server_topology)
    template = file("templates/packet_cluster_autoscaler/cluster_autoscaler_svcaccount.yaml")
}

data "template_file" "setup_cluster_autoscaler" {
    count = length(var.server_topology)
    template = file("templates/packet_cluster_autoscaler/setup_cluster_autoscaler.sh")
    vars = {
        master_ip = element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)
        api_port = 6443
        k3s_version = var.k3s_version
        global_ip = packet_reserved_ip_block.global_ip.address
        global_netmask = packet_reserved_ip_block.global_ip.netmask
        global_cidr = packet_reserved_ip_block.global_ip.cidr
        bgp_password = random_string.bgp_password.result
        bgp_asn = var.bgp_asn
        auth_token = var.auth_token
    }
}

resource "null_resource" "setup_cluster_autoscaler"{
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
        inline = ["mkdir -p /root/bootstrap/packet_cluster_autoscaler/"]
    }

    provisioner "file" {
        content = element(data.template_file.cluster_autoscaler_deployment.*.rendered, count.index)
        destination = "/root/bootstrap/packet_cluster_autoscaler/cluster_autoscaler_deployment.yaml"
    }

    provisioner "file" {
        content = element(data.template_file.cluster_autoscaler_secret.*.rendered, count.index)
        destination = "/root/bootstrap/packet_cluster_autoscaler/cluster_autoscaler_secret.yaml"
    }

    provisioner "file" {
        content = element(data.template_file.cluster_autoscaler_svcaccount.*.rendered, count.index)
        destination = "/root/bootstrap/packet_cluster_autoscaler/cluster_autoscaler_svcaccount.yaml"
    }

    provisioner "file" {
        content = element(data.template_file.setup_cluster_autoscaler.*.rendered, count.index)
        destination = "/root/bootstrap/setup_cluster_autoscaler.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "bash /root/bootstrap/setup_cluster_autoscaler.sh",
            "kubectl apply -f /root/bootstrap/packet_cluster_autoscaler/"
        ]
    }
}
