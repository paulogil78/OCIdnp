variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "region_dr" {}
variable "services_compartment" {}
variable "prod_compartment" {}
variable "preprod_compartment" {}
variable "vcn_is_ipv6enabled" {}

/*networking variables*/
variable "cidr_vcn_preprod" {}
variable "cidr_vcn_preprod_subnet_CN01" {}
variable "cidr_vcn_preprod_subnet_DB01" {}
variable "cidr_vcn_preprod_subnet_CN01_test" {}
variable "display_name_vcn_preprod" {}
variable "display_name_vcn_preprod_subnet_CN01" {}
variable "display_name_vcn_preprod_subnet_DB01" {}
variable "display_name_vcn_preprod_subnet_CN01_test" {}
variable "dnslabel_vcn_preprod" {}
variable "dnslabel_vcn_preprod_subnet_CN01" {}
variable "dnslabel_vcn_preprod_subnet_DB01" {}
variable "dnslabel_vcn_preprod_subnet_CN01_test" {}

variable "cidr_vcn_prod" {}
variable "cidr_vcn_prod_subnet_CN01" {}
variable "cidr_vcn_prod_subnet_DB01" {}
variable "cidr_vcn_prod_subnet_WT01" {}
variable "display_name_vcn_prod" {}
variable "display_name_vcn_prod_subnet_CN01" {}
variable "display_name_vcn_prod_subnet_DB01" {}
variable "display_name_vcn_prod_subnet_WT01" {}
variable "dnslabel_vcn_prod" {}
variable "dnslabel_vcn_prod_subnet_CN01" {}
variable "dnslabel_vcn_prod_subnet_DB01" {}
variable "dnslabel_vcn_prod_subnet_WT01" {}

variable "cidr_vcn_services" {}
variable "cidr_vcn_services_subnet_bastion" {}
variable "cidr_vcn_services_subnet_public1" {}
variable "display_name_vcn_services" {}
variable "display_name_vcn_services_subnet_bastion" {}
variable "display_name_vcn_services_subnet_public1" {}
variable "dnslabel_vcn_services" {}
variable "dnslabel_vcn_services_subnet_bastion" {}
variable "dnslabel_vcn_services_subnet_public1" {}

variable "cidr_vcn_dr" {}
variable "display_name_vcn_dr" {}
variable "dnslabel_vcn_dr" {}

variable "cidr_vcn_dr_subnet_CN01" {}
variable "cidr_vcn_dr_subnet_DB01" {}
variable "cidr_vcn_dr_subnet_WT01" {}
variable "cidr_vcn_dr_subnet_Public" {}
variable "display_name_vcn_dr_subnet_CN01" {}
variable "display_name_vcn_dr_subnet_DB01" {}
variable "display_name_vcn_dr_subnet_WT01" {}
variable "display_name_vcn_dr_subnet_Public" {}
variable "dnslabel_vcn_dr_subnet_CN01" {}
variable "dnslabel_vcn_dr_subnet_DB01" {}
variable "dnslabel_vcn_dr_subnet_WT01" {}
variable "dnslabel_vcn_dr_subnet_Public" {}

variable "tag_environment_dr" {}
variable "tag_environment_prod" {}
variable "tag_environment_preprod" {}
variable "tag_department_TI" {}

variable "remote_peering_connection_display_name_dr" {}
variable "remote_peering_connection_display_name_prod" {}

variable "preprod_vault_display_name" {}
variable "vault_type" {}
variable "preprod_admin_secret" {}
variable "preprod_secret_ocid" {}

variable "preprod_ports" {
  description = "list of ingress ports per preprod subnet"
  type = object({
    test_subnet_ports = list(number)
    db_subnet_ports   = list(number)
    cn_subnet_ports   = list(number)
  })
}
variable "prod_ports" {
  description = "list of ingress ports per prod subnet"
  type = object({
    wt_subnet_ports = list(number)
    db_subnet_ports = list(number)
    cn_subnet_ports = list(number)
  })
}

variable "default_preprod_tags" {
  type = map(any)
}

variable "preprod_databases" {
  description = "list of preprod database configurations"
  type = map(
    object({
      database_edition                         = string
      db_home_database_admin_password          = string
      db_home_database_db_name                 = string
      db_home_database_db_workload             = string
      db_home_database_character_set           = string
      db_home_database_ncharacter_set          = string
      db_home_database_pdb_name                = string
      db_home_database_auto_backup_enabled     = string
      db_home_database_auto_backup_window      = string
      db_home_database_recovery_window_in_days = number
      db_home_database_defined_tags            = map(string)
      db_home_db_version                       = string
      db_home_defined_tags                     = map(string)
      db_home_display_name                     = string
      db_system_options_storage_management     = string
      disk_redundancy                          = string
      shape                                    = string
      display_name                             = string
      hostname                                 = string
      data_storage_size_in_gb                  = string
      license_model                            = string
      node_count                               = number
      source                                   = string
      defined_tags                             = map(string)
      time_zone                                = string
    })
  )
}

variable "prod_databases" {
  description = "list of prod database configurations"
  type = map(
    object({
      database_edition                         = string
      db_home_database_admin_password          = string
      db_home_database_db_name                 = string
      db_home_database_db_workload             = string
      db_home_database_character_set           = string
      db_home_database_ncharacter_set          = string
      db_home_database_pdb_name                = string
      db_home_database_auto_backup_enabled     = string
      db_home_database_auto_backup_window      = string
      db_home_database_recovery_window_in_days = number
      db_home_database_defined_tags            = map(string)
      db_home_db_version                       = string
      db_home_defined_tags                     = map(string)
      db_home_display_name                     = string
      db_system_options_storage_management     = string
      disk_redundancy                          = string
      shape                                    = string
      display_name                             = string
      hostname                                 = string
      data_storage_size_in_gb                  = string
      license_model                            = string
      node_count                               = number
      source                                   = string
      defined_tags                             = map(string)
      time_zone                                = string
    })
  )
}

variable "onpremise_cidrs" {
  description = "list of all onpremise CIDRs"
  type = list(string)
}
variable "db_exports_fs_display_name" {}

variable "available_shapes" {
  description = "list of all available shape for compute instances"
  type = list(string)
}
/*variable "preprod_ports" {
    description = "list of ingress ports per preprod subnet"
    type = map(
            object({
                test_subnet_ports = list(number)
                db_subnet_ports = list(number)
                cn_subnet_ports = list(number)
            })
        )
}*/