terraform {
  required_providers {
    oci = {
      configuration_aliases = [oci.prov]
    }   
  }
}

variable "input_cidr" {}
variable "input_compartment" {}
variable "input_vcn" {}
variable "input_security_list" {}
variable "input_display_name" {}
variable "input_prohibit_public_ip" {}
variable "input_dns_label" {}
variable "input_ad" {}
variable "input_dhcp_id" {}
variable "input_route_table_id" {}
variable "input_environment_tag" {}
variable "input_department_tag" {}

resource "oci_core_subnet" "subnet" {
    #Required
    cidr_block = var.input_cidr
    compartment_id = var.input_compartment
    vcn_id = var.input_vcn
    #Optional
    display_name = var.input_display_name
    dns_label = var.input_dns_label
    security_list_ids = [var.input_security_list]
    prohibit_public_ip_on_vnic = var.input_prohibit_public_ip
    availability_domain = var.input_ad
    dhcp_options_id = var.input_dhcp_id
    route_table_id = var.input_route_table_id
    defined_tags = {
      "DNP-Tags.Environment" = "${var.input_environment_tag}"
      "DNP-Tags.Department"  = "${var.input_department_tag}"
    }
    lifecycle {
      ignore_changes = [
        defined_tags, freeform_tags
      ]
    }
}

output "subnet_id" {
  value = oci_core_subnet.subnet.id
}