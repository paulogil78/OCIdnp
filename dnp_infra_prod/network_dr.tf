resource "oci_core_vcn" "dr_vcn" {
  cidr_block     = var.cidr_vcn_dr
  compartment_id = var.prod_compartment
  display_name   = var.display_name_vcn_dr
  is_ipv6enabled = var.vcn_is_ipv6enabled
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  dns_label = var.dnslabel_vcn_dr
  provider  = oci.DR
}

/* DR Subnets Definition*/
resource "oci_core_subnet" "subnet_DR-DB01" {
  #Required
  cidr_block     = var.cidr_vcn_dr_subnet_DB01
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  #Optional
  display_name               = var.display_name_vcn_dr_subnet_DB01
  dns_label                  = var.dnslabel_vcn_dr_subnet_DB01
  security_list_ids          = [oci_core_security_list.DRSecList1.id]
  prohibit_public_ip_on_vnic = true
  dhcp_options_id            = oci_core_dhcp_options.dr_dhcp_options.id
  route_table_id             = oci_core_route_table.dr_vcn_rt.id
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}

resource "oci_core_subnet" "subnet_DR-CN01" {
  #Required
  cidr_block     = var.cidr_vcn_dr_subnet_CN01
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  #Optional
  display_name               = var.display_name_vcn_dr_subnet_CN01
  dns_label                  = var.dnslabel_vcn_dr_subnet_CN01
  security_list_ids          = [oci_core_security_list.DRSecList2.id]
  prohibit_public_ip_on_vnic = true
  dhcp_options_id            = oci_core_dhcp_options.dr_dhcp_options.id
  route_table_id             = oci_core_route_table.dr_vcn_rt.id
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}

resource "oci_core_subnet" "subnet_DR-WT01" {
  #Required
  cidr_block     = var.cidr_vcn_dr_subnet_WT01
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  #Optional
  display_name               = var.display_name_vcn_dr_subnet_WT01
  dns_label                  = var.dnslabel_vcn_dr_subnet_WT01
  security_list_ids          = [oci_core_security_list.DRSecList3.id]
  prohibit_public_ip_on_vnic = true
  dhcp_options_id            = oci_core_dhcp_options.dr_dhcp_options.id
  route_table_id             = oci_core_route_table.dr_vcn_rt.id
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}
resource "oci_core_subnet" "subnet_DR-Public" {
  #Required
  cidr_block     = var.cidr_vcn_dr_subnet_Public
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  #Optional
  display_name               = var.display_name_vcn_dr_subnet_Public
  dns_label                  = var.dnslabel_vcn_dr_subnet_Public
  security_list_ids          = [oci_core_security_list.DRSecList4.id]
  prohibit_public_ip_on_vnic = false
  dhcp_options_id            = oci_core_dhcp_options.dr_dhcp_options.id
  route_table_id             = oci_core_route_table.dr_vcn_rt.id
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}

/*DR VCN Security List*/
resource "oci_core_security_list" "DRSecList1" {
  compartment_id = var.prod_compartment
  display_name   = "SL-DR-DB01"
  vcn_id         = oci_core_vcn.dr_vcn.id
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
    protocol = 6               // TCP
    source   = var.cidr_vcn_dr //PROD VNC
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
  provider = oci.DR
}
resource "oci_core_security_list" "DRSecList2" {
  compartment_id = var.prod_compartment
  display_name   = "SL-DR-CN01"
  vcn_id         = oci_core_vcn.dr_vcn.id
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
    protocol = 6               // TCP
    source   = var.cidr_vcn_dr //DR VNC
  }
  ingress_security_rules {
    protocol = 6                 // TCP
    source   = var.cidr_vcn_prod //PROD VNC
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
  provider = oci.DR
}
resource "oci_core_security_list" "DRSecList3" {
  compartment_id = var.prod_compartment
  display_name   = "SL-DR-WT01"
  vcn_id         = oci_core_vcn.dr_vcn.id
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
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
  provider = oci.DR
}

resource "oci_core_security_list" "DRSecList4" {
  compartment_id = var.prod_compartment
  display_name   = "SL-DR-Public"
  vcn_id         = oci_core_vcn.dr_vcn.id
  egress_security_rules {
    protocol    = 1 // ICMP
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    protocol    = 6 // TCP
    destination = "0.0.0.0/0"
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
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, egress_security_rules, ingress_security_rules
    ]
  }
  provider = oci.DR
}

/*DR DHCP Options*/
resource "oci_core_dhcp_options" "dr_dhcp_options" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  display_name   = "DHCP-DR-ASH"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  options {
    type                = "SearchDomain"
    search_domain_names = ["drDNP.oraclevcn.com"]
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}

/* DR Service Gateway */
resource "oci_core_service_gateway" "dr_service_gateway" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  display_name   = "SG-DR-ASH"
  services {
    service_id = local.ash_object_storage_id
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
  provider = oci.DR
}

/* DR NAT Gateway */
resource "oci_core_nat_gateway" "dr_nat_gateway" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  display_name   = "NG-DR-ASH"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}
/* PROD DRG - For Remote Peering with DR Environment*/
resource "oci_core_drg" "dr_drg" {
  compartment_id = var.prod_compartment
  display_name   = "DRG-DR-ASH"
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}
resource "oci_core_drg_attachment" "dr_drg_attachment" {
  drg_id   = oci_core_drg.dr_drg.id
  vcn_id   = oci_core_vcn.dr_vcn.id
  provider = oci.DR
}
resource "oci_core_remote_peering_connection" "dr_remote_peering_connection" {
  #Required
  compartment_id = var.prod_compartment
  drg_id         = oci_core_drg.dr_drg.id

  #Optional
  display_name     = var.remote_peering_connection_display_name_dr
  peer_region_name = var.region
  provider         = oci.DR
}

/* ROUTE TABLE for VCN */
resource "oci_core_route_table" "dr_vcn_rt" {
  compartment_id = var.prod_compartment
  vcn_id         = oci_core_vcn.dr_vcn.id
  display_name   = "RT-DR-ASH"
  route_rules {
    destination       = var.cidr_vcn_prod
    network_entity_id = oci_core_drg.dr_drg.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet-gateway-dr.id
  }
  route_rules {
    destination       = local.ash_object_storage_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.dr_service_gateway.id
  }
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}

/* Services Internet Gateway */
resource "oci_core_internet_gateway" "internet-gateway-dr" {
  compartment_id = var.prod_compartment
  display_name   = "IG-Serv-ASH"
  vcn_id         = oci_core_vcn.dr_vcn.id
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_dr}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
  }
  provider = oci.DR
}