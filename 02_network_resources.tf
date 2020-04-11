resource "packet_reserved_ip_block" "global_ip" {
    project_id = packet_project.new_project.id
    type = "global_ipv4"
    quantity = 1
}
