/* VCNs Definition */
resource "oci_core_vcn" "prod_vcn" {
  cidr_block     = var.cidr_vcn_prod
  compartment_id = var.prod_compartment
  display_name   = var.display_name_vcn_prod
  is_ipv6enabled = var.vcn_is_ipv6enabled
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  dns_label = var.dnslabel_vcn_prod
}

/* PROD Subnets Definition*/
module "subnet_Prod-DB01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_prod_subnet_DB01
  input_compartment        = var.prod_compartment
  input_vcn                = oci_core_vcn.prod_vcn.id
  input_display_name       = var.display_name_vcn_prod_subnet_DB01
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_prod_subnet_DB01
  input_ad                 = null
  input_security_list      = oci_core_security_list.ProdSecList1.id
  input_dhcp_id            = oci_core_dhcp_options.prod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.prod_vcn_rt.id
  input_environment_tag    = var.tag_environment_prod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}
module "subnet_Prod-CN01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_prod_subnet_CN01
  input_compartment        = var.prod_compartment
  input_vcn                = oci_core_vcn.prod_vcn.id
  input_display_name       = var.display_name_vcn_prod_subnet_CN01
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_prod_subnet_CN01
  input_ad                 = null
  input_security_list      = oci_core_security_list.ProdSecList2.id
  input_dhcp_id            = oci_core_dhcp_options.prod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.prod_vcn_rt.id
  input_environment_tag    = var.tag_environment_prod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}
module "subnet_Prod-WT01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_prod_subnet_WT01
  input_compartment        = var.prod_compartment
  input_vcn                = oci_core_vcn.prod_vcn.id
  input_display_name       = var.display_name_vcn_prod_subnet_WT01
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_prod_subnet_WT01
  input_ad                 = null
  input_security_list      = oci_core_security_list.ProdSecList3.id
  input_dhcp_id            = oci_core_dhcp_options.prod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.prod_vcn_rt.id
  input_environment_tag    = var.tag_environment_prod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}

/*PROD VCN Security List*/
resource "oci_core_security_list" "ProdSecList1" {
  compartment_id = var.prod_compartment
  display_name   = "SL-Prod-DB01"
  vcn_id         = oci_core_vcn.prod_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 1 // ICMP
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  dynamic "ingress_security_rules" {
    for_each = toset(var.prod_ports.db_subnet_ports)
    content {
      source   = var.cidr_vcn_services
      protocol = 6 // tcp
      tcp_options {
        max = ingress_security_rules.value
        min = ingress_security_rules.value
      }
    }
  }
  /*dynamic "ingress_security_rules" {
    for_each = toset(var.onpremise_cidrs)
    content {
      source   = ingress_security_rules.value
      protocol = 6 // tcp
      tcp_options {
        max = 1521
        min = 1521
      }
    }
  }*/
  dynamic "ingress_security_rules" {
    for_each = toset(var.onpremise_cidrs)
    content {
      source   = ingress_security_rules.value
      protocol = 6 // tcp
      tcp_options {
        max = 22
        min = 22
      }
    }
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
}
resource "oci_core_security_list" "ProdSecList2" {
  compartment_id = var.prod_compartment
  display_name   = "SL-Prod-CN01"
  vcn_id         = oci_core_vcn.prod_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 1 // ICMP
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  dynamic "ingress_security_rules" {
    for_each = toset(var.prod_ports.cn_subnet_ports)
    content {
      source   = var.cidr_vcn_services
      protocol = 6 // tcp
      tcp_options {
        max = ingress_security_rules.value
        min = ingress_security_rules.value
      }
    }
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
}
resource "oci_core_security_list" "ProdSecList3" {
  compartment_id = var.prod_compartment
  display_name   = "SL-Prod-WT01"
  vcn_id         = oci_core_vcn.prod_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 1 // ICMP
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  dynamic "ingress_security_rules" {
    for_each = toset(var.prod_ports.wt_subnet_ports)
    content {
      source   = var.cidr_vcn_services
      protocol = 6 // tcp
      tcp_options {
        max = ingress_security_rules.value
        min = ingress_security_rules.value
      }
    }
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
}
/*PROD Service Gateway */
resource "oci_core_service_gateway" "prod_service_gateway" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.prod_vcn.id
  display_name   = "SG-Prod-PHX"
  services {
    service_id = local.object_storage_id
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/*PROD NAT Gateway*/
resource "oci_core_nat_gateway" "prod_nat_gateway" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.prod_vcn.id
  display_name   = "NG-Prod-PHX"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/*PROD DHCP Options*/
resource "oci_core_dhcp_options" "prod_dhcp_options" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.prod_vcn.id
  display_name   = "DHCP-Prod-PHX"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type                = "SearchDomain"
    search_domain_names = ["prodDNP.oraclevcn.com"]
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/* Local Peering Gateway */
resource "oci_core_local_peering_gateway" "prod_local_peering_gateway" {
  #Required
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.prod_vcn.id

  #Optional
  display_name = "LPG-PROD-TO-SERVICE"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/* PROD DRG - For Remote Peering with DR Environment*/
resource "oci_core_drg" "prod_drg" {
  compartment_id = var.prod_compartment
  display_name   = "DRG-Prod-PHX"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}
resource "oci_core_drg_attachment" "prod_drg_attachment" {
  drg_id = oci_core_drg.prod_drg.id
  vcn_id = oci_core_vcn.prod_vcn.id
}

resource "oci_core_remote_peering_connection" "prod_remote_peering_connection" {
  #Required
  compartment_id = var.prod_compartment
  drg_id         = oci_core_drg.prod_drg.id

  #Optional
  display_name     = var.remote_peering_connection_display_name_prod
  peer_id          = oci_core_remote_peering_connection.dr_remote_peering_connection.id
  peer_region_name = var.region_dr
}

/* ROUTE TABLE for VCN */
resource "oci_core_route_table" "prod_vcn_rt" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.prod_vcn.id
  display_name   = "RT-Prod-PHX"
  route_rules {
    destination       = var.cidr_vcn_services // SERVICES VCN CIDR
    network_entity_id = oci_core_local_peering_gateway.prod_local_peering_gateway.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.prod_nat_gateway.id
  }
  route_rules {
    destination       = local.object_storage_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.prod_service_gateway.id
  }
  route_rules {
    destination       = var.cidr_vcn_dr
    network_entity_id = oci_core_drg.prod_drg.id
  }
  dynamic "route_rules"{
    for_each = toset(var.onpremise_cidrs)
    content {
      destination       = route_rules.value // ONPREMISES CIDRs
      network_entity_id = oci_core_local_peering_gateway.prod_local_peering_gateway.id
    }
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, route_rules
    ]
  }
}