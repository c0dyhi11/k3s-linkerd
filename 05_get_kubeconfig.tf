resource "null_resource" "copy_kubeconfigs"{
    depends_on = [
        null_resource.install_k3s
    ]
    count = length(var.server_topology)
    provisioner "local-exec" {
        command = <<-EOC
            mkdir -p ./kubeconfigs; 
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)}:/etc/rancher/k3s/k3s.yaml ./kubeconfigs/${element(var.server_topology.*.cluster_name, count.index)}
            sed -i 's/127.0.0.1/${element(packet_device.k3s_master_nodes.*.access_public_ipv4, count.index)}/g' kubeconfigs/${element(var.server_topology.*.cluster_name, count.index)}
        EOC
    }
    provisioner "local-exec" {
        when = destroy
        command = <<-EOD
            rm -rf ./kubeconfigs
        EOD
    }
}
