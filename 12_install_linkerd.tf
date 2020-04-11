resource "null_resource" "install_linkerd"{
    depends_on = [
        null_resource.copy_kubeconfigs,
        null_resource.gen_intermediates
    ]
    count = length(var.server_topology)
    provisioner "local-exec" {
        command = <<-EOC
            linkerd install --kubeconfig kubeconfigs/${element(var.server_topology.*.cluster_name, count.index)} \
                --identity-trust-anchors-file ${local.root_dir}/ca.cert.pem \
                --identity-issuer-certificate-file ${local.root_dir}/intermediate/cert/${element(var.server_topology.*.cluster_name, count.index)}.cert.pem \
                --identity-issuer-key-file ${local.root_dir}/intermediate/key/${element(var.server_topology.*.cluster_name, count.index)}.key.pem \
                --identity-trust-domain ${element(var.server_topology.*.cluster_name, count.index)}.${var.domain} \
                --cluster-domain ${element(var.server_topology.*.cluster_name, count.index)}.${var.domain} \
                | kubectl --kubeconfig kubeconfigs/${element(var.server_topology.*.cluster_name, count.index)} apply -f -
        EOC
    }
}
