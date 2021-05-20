/* BASTION HOST */
resource "oci_core_instance" "bastion_prod" {
  count = 1
  #Required
  availability_domain = local.phx_ad3
  compartment_id      = var.services_compartment
  shape               = local.free_tier_shape

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_Serv-Bastion.subnet_id
  }
  display_name = "BastionHost"

  source_details {
    #Required
    source_id   = local.linux7image
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/ssh-key-bastion.pub")}"
  }
}

/* TEST HOST */
/*resource "oci_core_instance" "test_prod" {
    count = 1
    #Required
    availability_domain = local.phx_ad3
    compartment_id = var.preprod_compartment
    shape = local.free_tier_shape

    create_vnic_details {
        #Optional
        subnet_id = module.subnet_Prod-CN01.subnet_id   
        assign_public_ip = "false"
    }
    display_name = "TestHost"
    
    source_details {
        #Required
        source_id = local.linux7image
        source_type = "image"
    }

    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
        create_before_destroy = false
    }

    metadata = {
      "ssh_authorized_keys" = "${file("../keys/ssh-key-bastion.pub")}"
    }
}
*/
/* TEST HOST DR*/
