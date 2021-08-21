/* VCNs Definition */
resource "oci_core_vcn" "services_vcn" {
  cidr_block     = var.cidr_vcn_services
  compartment_id = var.services_compartment
  display_name   = var.display_name_vcn_services
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
  dns_label = var.dnslabel_vcn_services
}
/* SERV Subnets Definition*/
module "subnet_Serv-Bastion" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_services_subnet_bastion
  input_compartment        = var.services_compartment
  input_vcn                = oci_core_vcn.services_vcn.id
  input_display_name       = var.display_name_vcn_services_subnet_bastion
  input_prohibit_public_ip = false
  input_dns_label          = var.dnslabel_vcn_services_subnet_bastion
  input_ad                 = null
  input_security_list      = oci_core_security_list.ServSecList1.id
  input_dhcp_id            = oci_core_dhcp_options.serv_dhcp_options.id
  input_route_table_id     = oci_core_route_table.services_vcn_rt.id
  input_environment_tag    = var.tag_environment_prod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}
module "subnet_Serv-Public1" {
  source                   = "./subnet_module"
  input_cidr               = var.cidr_vcn_services_subnet_public1
  input_compartment        = var.services_compartment
  input_vcn                = oci_core_vcn.services_vcn.id
  input_display_name       = var.display_name_vcn_services_subnet_public1
  input_prohibit_public_ip = false
  input_dns_label          = var.dnslabel_vcn_services_subnet_public1
  input_ad                 = null
  input_security_list      = oci_core_security_list.ServSecList2.id
  input_dhcp_id            = oci_core_dhcp_options.serv_dhcp_options.id
  input_route_table_id     = oci_core_route_table.services_vcn_rt.id
  input_environment_tag    = var.tag_environment_prod
  input_department_tag     = var.tag_department_TI
  providers = {
    oci.prov = oci.PROD
  }
}

/*Services VCN Security List*/
resource "oci_core_security_list" "ServSecList1" {
  compartment_id = var.services_compartment
  display_name   = "SL-Services-Bastion"
  vcn_id         = oci_core_vcn.services_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  ingress_security_rules {
    protocol = 6                    // TCP
    source   = var.cidr_vcn_preprod //PREPROD VNC
  }
  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 22
  }
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 80
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 443
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, ingress_security_rules, egress_security_rules
    ]
  }
}
resource "oci_core_security_list" "ServSecList2" {
  compartment_id = var.services_compartment
  display_name   = "SL-Services-Public1"
  vcn_id         = oci_core_vcn.services_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  ingress_security_rules {
    protocol = 6                    // TCP
    source   = var.cidr_vcn_preprod //PREPROD VNC
  }
  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 22
  }
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 80
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = 6           // tcp
    source   = "0.0.0.0/0" //All traffic Port 443
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, ingress_security_rules, egress_security_rules
    ]
  }
}


/*Services DHCP Options*/
resource "oci_core_dhcp_options" "serv_dhcp_options" {
  compartment_id = var.services_compartment
  vcn_id         = oci_core_vcn.services_vcn.id
  display_name   = "DHCP-Serv-PHX"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type                = "SearchDomain"
    search_domain_names = ["servicesDNP.oraclevcn.com"]
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "GTI"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}

/* Services Internet Gateway */
resource "oci_core_internet_gateway" "internet-gateway" {
  compartment_id = var.services_compartment
  display_name   = "IG-Serv-PHX"
  vcn_id         = oci_core_vcn.services_vcn.id
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

/* Services DRG */
resource "oci_core_drg" "services_drg" {
  compartment_id = var.services_compartment
  display_name   = "DRG-Serv-PHX"
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
resource "oci_core_drg_attachment" "services_drg_attachment" {
  drg_id = oci_core_drg.services_drg.id
  vcn_id = oci_core_vcn.services_vcn.id
}

/* Local Peering Gateway */
/* TO PREPROD */
resource "oci_core_local_peering_gateway" "services_local_peering_gateway" {
  #Required
  compartment_id = var.services_compartment
  vcn_id         = oci_core_vcn.services_vcn.id

  #Optional
  display_name = "LPG_SERV_TO_PREPROD"
  peer_id      = oci_core_local_peering_gateway.preprod_local_peering_gateway.id

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

/* TO PRODUCTION */
resource "oci_core_local_peering_gateway" "services_local_peering_gateway2" {
  #Required
  compartment_id = var.services_compartment
  vcn_id         = oci_core_vcn.services_vcn.id

  #Optional
  display_name = "LPG_SERV_TO_PROD"
  peer_id      = oci_core_local_peering_gateway.prod_local_peering_gateway.id

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

/* ROUTE TABLE for VCN */
resource "oci_core_route_table" "services_vcn_rt" {
  compartment_id = var.services_compartment
  vcn_id         = oci_core_vcn.services_vcn.id
  display_name   = "RT-Serv-PHX"
  route_rules {
    destination       = var.cidr_vcn_prod // PROD VCN CIDR
    network_entity_id = oci_core_local_peering_gateway.services_local_peering_gateway2.id
  }
  route_rules {
    destination       = var.cidr_vcn_preprod //PREPROD VCN CIDR
    network_entity_id = oci_core_local_peering_gateway.services_local_peering_gateway.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet-gateway.id
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

/*LOAD BALANCER*/
resource "oci_load_balancer_load_balancer" "prod_load_balancer" {
    #Required
    compartment_id = var.services_compartment
    display_name = "DNP-LoadBalancer"
    shape = "400Mbps"
    subnet_ids = [module.subnet_Serv-Public1.subnet_id]

    #Optional
    defined_tags = {
      "DNP-Tags.Environment" = "${var.tag_environment_prod}"
      "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    ip_mode = "IPV4"
    is_private = "false"
    //network_security_group_ids = var.load_balancer_network_security_group_ids
    lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
}