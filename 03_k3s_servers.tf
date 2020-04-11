resource "packet_device" "k3s_master_nodes" {
    depends_on = [
        packet_ssh_key.ssh_pub_key
    ]
    count = length(var.server_topology)
    hostname = format("k8s-%s-master", element(var.server_topology.*.cluster_name, count.index))
    plan = element(var.server_topology.*.plan, count.index)
    facilities = [element(var.server_topology.*.facilty, count.index)]
    operating_system = var.operating_system
    billing_cycle = var.billing_cycle
    project_id = packet_project.new_project.id
    tags = [
        format("k8s-cluster-%s", element(var.server_topology.*.cluster_name, count.index))
    ]
}

resource "random_string" "random" {
    count = length(var.server_topology)
    length = 8
    special = false
    upper = false
    lower = true
    number = false
}

resource "packet_device" "k3s_worker_nodes" {
    depends_on = [
        packet_ssh_key.ssh_pub_key
    ]
    count = length(var.server_topology)
    hostname = format("k8s-%s-%s-%s", element(var.server_topology.*.cluster_name, count.index), var.node_pool_name, element(random_string.random.*.result, count.index))
    plan = element(var.server_topology.*.plan, count.index)
    facilities = [element(var.server_topology.*.facilty, count.index)]
    operating_system = var.operating_system
    billing_cycle = var.billing_cycle
    project_id = packet_project.new_project.id
    tags = [
        format("k8s-cluster-%s", element(var.server_topology.*.cluster_name, count.index)), 
        format("k8s-nodepool-%s", var.node_pool_name)
    ]
}
