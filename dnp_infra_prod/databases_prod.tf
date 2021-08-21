module "database_sgr" {
  source                    = "./db_module"
  database_config           = var.prod_databases.sgr_db
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad1
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_stgdr" {
  source                    = "./db_module"
  database_config           = var.prod_databases.stgdr_db
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad1
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_dwhdr" {
  source                    = "./db_module"
  database_config           = var.prod_databases.dwhdr_db
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad1
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_wls_metadata" {
  source                    = "./db_module"
  database_config           = var.prod_databases.wls_metadata_db
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad2
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_oid" {
  source                    = "./db_module"
  database_config           = var.prod_databases.oid_product
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad1
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_odi" {
  source                    = "./db_module"
  database_config           = var.prod_databases.odi_product
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad2
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

module "database_oas" {
  source                    = "./db_module"
  database_config           = var.prod_databases.oas_product
  input_compartment_id      = var.prod_compartment
  input_availability_domain = local.phx_ad2
  input_subnet_id           = module.subnet_Prod-DB01.subnet_id
  input_ssh_public_keys     = ["${file("../keys/ssh-database-key.key.pub")}"]
  providers = {
    oci.prov = oci.PROD
  }
}

