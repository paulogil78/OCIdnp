##################
##   main.tf 
##
##################

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
terraform {
  backend "http" {
    address       = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/gHWOmz-95ccP2cQq1SFrBc9c7hm97tD0TC3ZSee8X7LYQG0wA2shTmg4-CkZyBK4/n/axyqnsuaghzx/b/bucket-terraform-state-repo/o/terraform_dr.tfstate"
    update_method = "PUT"
  }
}

module "CreateInstances" {
  source             = "./modules"
  inst_ad            = data.oci_identity_availability_domain.ad.name
  inst_compartment   = var.compute_instance_compartment_name
  inst_shape         = var.instance_shape
  inst_subnet        = var.subnet
  inst_vnic_name     = var.primary_vnic_display_name
  inst_public_ip     = var.assign_public_ip_flag
  inst_private_key   = var.ssh_private_key
  inst_public_key    = var.ssh_public_key
  inst_variables     = var.instances_variables
  tag_environment_dr = var.tag_environment_dr
  tag_department_TI  = var.tag_department_TI
}

/* OHS Instance*/

module "OHSInstance" {
  source             = "./modules"
  inst_ad            = data.oci_identity_availability_domain.ad.name
  inst_compartment   = var.compute_instance_compartment_name
  inst_shape         = var.instance_shape
  inst_subnet        = var.public_subnet
  inst_vnic_name     = var.primary_vnic_display_name
  inst_public_ip     = "true"
  inst_private_key   = var.ssh_private_key
  inst_public_key    = var.ssh_public_key
  inst_variables     = var.ohs_variables
  tag_environment_dr = var.tag_environment_dr
  tag_department_TI  = var.tag_department_TI
}

/* DR Bastion */
/* BASTION HOST */
data "oci_core_shapes" "bastion_shape" {
  compartment_id = var.tenancy_ocid
  filter {
    name   = "name"
    values = ["VM.Standard2.1"]
  }
}
resource "oci_core_instance" "bastion_prod" {
  count = 1
  #Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compute_instance_compartment_name
  shape               = distinct(data.oci_core_shapes.bastion_shape.shapes[*].name)[0]

  create_vnic_details {
    #Optional
    subnet_id = var.public_subnet
  }
  display_name = "DRBastionHost"

  source_details {
    #Required
    source_id   = var.image_instance_linux //local.linux7image
    source_type = "image"
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

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}

/* Databases*/

module "database_wls_dr" {
  source                    = "./db_module"
  database_config           = var.dr_databases.dr_wls_metadata_db
  input_compartment_id      = var.compute_instance_compartment_name
  input_availability_domain = data.oci_identity_availability_domain.ad.name
  input_subnet_id           = var.db_subnet
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
}

module "database_oid_dr" {
  source                    = "./db_module"
  database_config           = var.dr_databases.dr_oid_product
  input_compartment_id      = var.compute_instance_compartment_name
  input_availability_domain = data.oci_identity_availability_domain.ad.name
  input_subnet_id           = var.db_subnet
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
}

module "database_odi_dr" {
  source                    = "./db_module"
  database_config           = var.dr_databases.dr_odi_product
  input_compartment_id      = var.compute_instance_compartment_name
  input_availability_domain = data.oci_identity_availability_domain.ad.name
  input_subnet_id           = var.db_subnet
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
}

module "database_oas_dr" {
  source                    = "./db_module"
  database_config           = var.dr_databases.dr_oas_product
  input_compartment_id      = var.compute_instance_compartment_name
  input_availability_domain = data.oci_identity_availability_domain.ad.name
  input_subnet_id           = var.db_subnet
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
}





