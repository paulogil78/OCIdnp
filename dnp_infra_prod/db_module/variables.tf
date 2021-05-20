/*variable "input_cidr" {}
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

*/
variable "input_availability_domain" {}
variable "input_compartment_id" {}
variable "input_subnet_id" {}
variable "input_ssh_public_keys" {
    type = list(string)
}
variable "database_config" {
    description = "database configuration"
    type = object({
                database_edition = string
                db_home_database_admin_password = string
                db_home_database_db_name = string
                db_home_database_db_workload = string
                db_home_database_character_set = string
                db_home_database_ncharacter_set = string
                db_home_database_pdb_name = string
                db_home_database_auto_backup_enabled = string
                db_home_database_auto_backup_window = string
                db_home_database_recovery_window_in_days = number
                db_home_database_defined_tags = map(string)
                db_home_db_version = string
                db_home_defined_tags = map(string)
                db_home_display_name = string 
                db_system_options_storage_management = string
                disk_redundancy = string
                shape = string
                display_name = string
                hostname = string
                data_storage_size_in_gb = string
                license_model = string
                node_count = number
                source = string
                defined_tags = map(string)
                time_zone = string
            })
}