#######################
##  Variables.tf 
##
#######################

variable "instances_variables" {}

variable "ohs_variables" {}

variable "num_instances_oid" {
  description = "Amount of instances to create"
  default     = 1
}

variable "compute_instance_compartment_name" {
  description = "Defines the compartment name where the infrastructure will be created"
  default     = "ocid1.compartment.oc1..aaaaaaaaivlloczgwwhdvbdnxwy5s7jfe7ekrweaglno33xd4l2bkpklf3qq"
}

variable "tenancy_ocid" {
  description = "OCID of tenancy"
  default     = "ocid1.tenancy.oc1..aaaaaaaabuuix4xolxdmgjdiz32kvhx43d3wfjwvsjkde6njiqas6uryk3la"
}

variable "user_ocid" {
  description = "User OCID in tenancy. Currently hardcoded to user denny.alquinta@oracle.com"
  default     = "ocid1.user.oc1..aaaaaaaav4kypoh4qr5hblwji7lmmfkmq5fc2zo2wfi2h2rx7jqc5dfgjfwq"
}

variable "fingerprint" {
  description = "API Key Fingerprint for user_ocid derived from public API Key imported in OCI User config"
  default     = "36:8f:dd:50:dc:43:25:d9:e9:e6:d0:ef:af:84:3c:d2"
}

variable "private_key_path" {
  description = "Private Key Absolute path location where terraform is executed"
  default     = "../keys/api_key.pem"
}

variable "region" {
  description = "Target region where artifacts are going to be created"
  default     = "us-ashburn-1"
}

variable "instance_shape" {
  description = "Defines the shape to be used on compute creation"
  default     = "VM.Standard2.2"
}

variable "subnet" {
  description = "ID of subnet"
  default     = "ocid1.subnet.oc1.iad.aaaaaaaam2rqmfip2kion6nmbispvw6i5b3sb7w62ggoqk3hippg6ekkivmq"
}
variable "db_subnet" {
  description = "ID of database subnet "
  default     = "ocid1.subnet.oc1.iad.aaaaaaaaprmrx4ejrerlvi6tw7awlaltcimzs4plgijvk26mxxowwnd2lbua"
}
variable "primary_vnic_display_name" {
  description = "Defines the Primary VNIC Display Name"
  default     = "primaryvnic"
}

variable "assign_public_ip_flag" {
  description = "Defines either machine will have or not a Public IP assigned. All Pvt networks this variable must be false"
  default     = false
}

variable "ssh_private_key" {
  description = "Private key to log into machine"
  default     = "../keys/dnp_cn_key"
}

variable "ssh_public_key" {
  description = "Defines SSH Public Key to be used in order to remotely connect to compute instance"
  type        = string
  default     = "../keys/dnp_cn_key.pub"
}

variable "tag_environment_dr" {
  description = "Defines metadata value for environment tag"
  type        = string
  default     = "DR"
}

variable "tag_department_TI" {
  description = "Defines metadata value for environment tag"
  type        = string
  default     = "GTI"
}

variable "dr_databases" {
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

variable "image_instance_linux" {}
variable "public_subnet" {}

variable "cidr_vcn_dr_subnet_CN01" {}