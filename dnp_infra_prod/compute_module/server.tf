resource "oci_core_instance" "Compute" {
  count               = var.input_num_instances
  availability_domain = var.compute_availability_domain_list[count.index % length(var.compute_availability_domain_list)]
  compartment_id      = var.input_compartment
  display_name        = format("%s%d%s", var.input_display, count.index + 1, var.input_end)  
  shape               = var.input_shape

  create_vnic_details {
    subnet_id        = var.input_subnet
    display_name     = var.primary_vnic_display_name
    assign_public_ip = var.assign_public_ip_flag
    hostname_label   = format("%s%d%s", lower(var.input_display), count.index + 1, lower(var.input_end))  
  }

  source_details {
    source_type = "image"
    source_id   = var.input_image
  }

  connection {
    type 		= "ssh"
    host        = self.private_ip
    user        = "opc"
    private_key = (filevar.ssh_private_key)
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }

  timeouts {
    create = "15m"
  }
  defined_tags = var.defined_tags
  
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

}

