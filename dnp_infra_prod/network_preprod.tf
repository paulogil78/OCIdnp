/* VCNs Definition */
resource "oci_core_vcn" "preprod_vcn" {
  cidr_block     = var.cidr_vcn_preprod
  compartment_id = var.preprod_compartment
  display_name   = var.display_name_vcn_preprod
  is_ipv6enabled = var.vcn_is_ipv6enabled
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  dns_label = var.dnslabel_vcn_preprod
}

/* PREPROD Subnets Definition*/
module "subnet_PreProd-CN01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_preprod_subnet_CN01
  input_compartment        = var.preprod_compartment
  input_vcn                = oci_core_vcn.preprod_vcn.id
  input_display_name       = var.display_name_vcn_preprod_subnet_CN01
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_preprod_subnet_CN01
  input_ad                 = data.oci_identity_availability_domain.AD3.name
  input_security_list      = oci_core_security_list.PreprodSecList1.id
  input_dhcp_id            = oci_core_dhcp_options.preprod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.preprod_vcn_rt.id
  input_environment_tag    = var.tag_environment_preprod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}
module "subnet_PreProd-DB01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_preprod_subnet_DB01
  input_compartment        = var.preprod_compartment
  input_vcn                = oci_core_vcn.preprod_vcn.id
  input_display_name       = var.display_name_vcn_preprod_subnet_DB01
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_preprod_subnet_DB01
  input_ad                 = data.oci_identity_availability_domain.AD3.name
  input_security_list      = oci_core_security_list.PreprodSecList2.id
  input_dhcp_id            = oci_core_dhcp_options.preprod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.preprod_vcn_rt.id
  input_environment_tag    = var.tag_environment_preprod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}
module "subnet_Test-CN01" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_preprod_subnet_CN01_test
  input_compartment        = var.preprod_compartment
  input_vcn                = oci_core_vcn.preprod_vcn.id
  input_display_name       = var.display_name_vcn_preprod_subnet_CN01_test
  input_prohibit_public_ip = true
  input_dns_label          = var.dnslabel_vcn_preprod_subnet_CN01_test
  input_ad                 = data.oci_identity_availability_domain.AD2.name
  input_security_list      = oci_core_security_list.PreprodSecList3.id
  input_dhcp_id            = oci_core_dhcp_options.preprod_dhcp_options.id
  input_route_table_id     = oci_core_route_table.preprod_vcn_rt.id
  input_environment_tag    = var.tag_environment_preprod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}

/*PREPROD VCN Security List*/
resource "oci_core_security_list" "PreprodSecList1" {
  compartment_id = var.preprod_compartment
  display_name   = "SL-PreProd-CN01"
  vcn_id         = oci_core_vcn.preprod_vcn.id

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
    protocol = 6                    // TCP
    source   = var.cidr_vcn_preprod //CIDR VCN PREPROD 
  }

  dynamic "ingress_security_rules" {
    for_each = toset(var.preprod_ports.cn_subnet_ports)
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
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}
resource "oci_core_security_list" "PreprodSecList2" {
  compartment_id = var.preprod_compartment
  display_name   = "SL-PreProd-DB01"
  vcn_id         = oci_core_vcn.preprod_vcn.id
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
    protocol = 6                    // TCP
    source   = var.cidr_vcn_preprod // PREPROD VCN CIDR
  }
  dynamic "ingress_security_rules" {
    for_each = toset(var.preprod_ports.db_subnet_ports)
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
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}
resource "oci_core_security_list" "PreprodSecList3" {
  compartment_id = var.preprod_compartment
  display_name   = "SL-Test-CN01"
  vcn_id         = oci_core_vcn.preprod_vcn.id
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
    protocol = 6                    // TCP
    source   = var.cidr_vcn_preprod // PREPROD VCN CIDR
  }

  dynamic "ingress_security_rules" {
    for_each = toset(var.preprod_ports.test_subnet_ports)
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
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}
/*PREPROD Service Gateway */
resource "oci_core_service_gateway" "preprod_service_gateway" {
  compartment_id = var.preprod_compartment
  vcn_id         = oci_core_vcn.preprod_vcn.id
  display_name   = "SG-PREPROD-PHX"
  services {
    service_id = local.object_storage_id
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/*PREPROD NAT Gateway*/
resource "oci_core_nat_gateway" "preprod_nat_gateway" {
  compartment_id = var.preprod_compartment
  vcn_id         = oci_core_vcn.preprod_vcn.id
  display_name   = "NG-PREPROD-PHX"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/*PREPROD DHCP Options*/
resource "oci_core_dhcp_options" "preprod_dhcp_options" {
  compartment_id = var.preprod_compartment
  vcn_id         = oci_core_vcn.preprod_vcn.id
  display_name   = "DHCP-PREPROD-PHX"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type                = "SearchDomain"
    search_domain_names = ["preprodDNP.oraclevcn.com"]
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/* Local Peering Gateway */
resource "oci_core_local_peering_gateway" "preprod_local_peering_gateway" {
  #Required
  compartment_id = var.preprod_compartment
  vcn_id         = oci_core_vcn.preprod_vcn.id

  #Optional
  display_name = "LPG-PREPROD-TO-SERVICE"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/* ROUTE TABLE for VCN */
resource "oci_core_route_table" "preprod_vcn_rt" {
  compartment_id = var.preprod_compartment
  vcn_id         = oci_core_vcn.preprod_vcn.id
  display_name   = "RT-PREPROD-PHX"
  route_rules {
    destination       = var.cidr_vcn_services // SERVICES VCN CIDR
    network_entity_id = oci_core_local_peering_gateway.preprod_local_peering_gateway.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.preprod_nat_gateway.id
  }
  route_rules {
    destination       = local.object_storage_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.preprod_service_gateway.id
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}