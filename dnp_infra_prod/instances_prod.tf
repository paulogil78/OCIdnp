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
    source_id   = var.instance_image_linux_ocid //local.linux7image
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

/*Weblogig servers*/
module "weblogic_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_wl
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_linux_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_weblogic
  input_end			      = var.front_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}

/*OAS servers*/
module "oas_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_oas
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_linux_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_oas
  input_end			      = var.back_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}

/*Windows servers*/
module "win_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_win
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_win_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_win
  input_end			      = var.front_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}

/*ODI servers*/
module "odi_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_odi
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_linux_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_odi
  input_end			      = var.back_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}

/*OID servers*/
module "oid_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_oid
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_linux_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_oid
  input_end			      = var.back_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}
/*OAS servers*/
module "oam_servers" {
  source              = "./compute_module"
  input_num_instances = var.num_instances_oam
  input_compartment   = var.prod_compartment
  input_image         = var.instance_image_linux_ocid
  input_shape			    = var.instance_shape
  input_subnet		    = module.subnet_Prod-CN01.subnet_id
  input_display		    = var.display_oam
  input_end			      = var.back_end
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_prod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
}