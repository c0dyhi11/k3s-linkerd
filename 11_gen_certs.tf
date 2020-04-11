
locals {
    root_dir = "${abspath(path.module)}/root_ca"
    scripts_dir = "${abspath(path.module)}/root_ca/scripts"
}

data "template_file" "root_ca_openssl_config" {
    template = file("templates/openssl/ca.cnf")
    vars = {
        ROOT_DIR = local.root_dir
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        EMAIL = var.email
    }
}

data "template_file" "gen_ca" {
    template = file("templates/scripts/gen_ca.sh")
    vars = {
        ROOT_DIR = local.root_dir
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        DOMAIN = var.domain
    }
}

data "template_file" "gen_intermediate" {
    template = file("templates/scripts/gen_intermediate.sh")
    vars = {
        ROOT_DIR = local.root_dir
        COUNTRY = var.country
        STATE = var.state
        CITY = var.city
        ORG = var.org
        UNIT = var.unit
        DOMAIN = var.domain
    }
}

resource "local_file" "root_ca_openssl_config" {
    content = data.template_file.root_ca_openssl_config.rendered
    filename = "${local.root_dir}/openssl.cnf"
    file_permission = "0644"
}

resource "local_file" "gen_ca" {
    content = data.template_file.gen_ca.rendered
    filename = "${local.scripts_dir}/gen_ca.sh"
    file_permission = "0755"
}

resource "local_file" "gen_intermediate" {
    content = data.template_file.gen_intermediate.rendered
    filename = "${local.scripts_dir}/gen_intermediate.sh"
    file_permission = "0755"
}

resource "null_resource" "gen_ca"{
    depends_on = [local_file.gen_ca]
    provisioner "local-exec" {
        command = <<-EOC
            bash ${local.scripts_dir}/gen_ca.sh
        EOC
    }
}

resource "null_resource" "gen_intermediates"{
    count = length(var.server_topology)
    depends_on = [null_resource.gen_ca]
    provisioner "local-exec" {
        command = <<-EOC
            sleep ${count.index}
            bash ${local.scripts_dir}/gen_intermediate.sh '${element(var.server_topology.*.cluster_name, count.index)}'
        EOC
    }
    provisioner "local-exec" {
        when = destroy
        command = <<-EOD
            rm -rf ${local.root_dir}
        EOD
    }
}
