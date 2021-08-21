#########################
##   servers.tf 
##
#########################

variable "inst_ad" {}         
variable "inst_compartment" {}
variable "inst_shape" {}      
variable "inst_subnet" {}     
variable "inst_vnic_name" {}
variable "inst_public_ip" {}
variable "inst_private_key" {}
variable "inst_public_key" {} 
variable "inst_variables" { type = map(any) }  
variable "tag_environment_dr"{}
variable "tag_department_TI"{}


resource "oci_core_instance" "Compute" {
  for_each            = var.inst_variables
  availability_domain = var.inst_ad
  compartment_id      = var.inst_compartment
  display_name        = each.value.name_instance
  shape              = var.inst_shape

  create_vnic_details {
    subnet_id        = var.inst_subnet
    display_name     = var.inst_vnic_name
    assign_public_ip = var.inst_public_ip
    hostname_label   = lower(each.value.name_instance)
  }

  source_details {
    source_type = "image"
    source_id   = each.value.oci_i 
  }

  connection {
    type 		= "ssh"
    host        = self.private_ip
    user        = "opc"
    private_key = file(var.inst_private_key)
  }

  metadata = {
    ssh_authorized_keys = file(var.inst_public_key)
  }

  timeouts {
    create = "15m"
  }

  defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }
}
