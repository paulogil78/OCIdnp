terraform {
  required_providers {
    oci = {
      configuration_aliases = [oci.prov]
    }   
  }
}

resource "oci_database_db_system" "database" {
    #Required
    availability_domain = var.input_availability_domain
    compartment_id = var.input_compartment_id
    subnet_id = var.input_subnet_id
    ssh_public_keys = var.input_ssh_public_keys
    
    database_edition = var.database_config.database_edition
    db_home {
        #Required
        database {
            #Required
            admin_password = var.database_config.db_home_database_admin_password
            db_name = var.database_config.db_home_database_db_name
            db_workload = var.database_config.db_home_database_db_workload
            character_set = var.database_config.db_home_database_character_set
            ncharacter_set = var.database_config.db_home_database_ncharacter_set
            pdb_name = var.database_config.db_home_database_pdb_name
            
            db_backup_config {

                #Optional
                auto_backup_enabled = var.database_config.db_home_database_auto_backup_enabled
                auto_backup_window = var.database_config.db_home_database_auto_backup_window
                recovery_window_in_days = var.database_config.db_home_database_recovery_window_in_days
                
                /*
                backup_destination_details {

                    #Optional
                    id = var.db_system_db_home_database_db_backup_config_backup_destination_details_id
                    type = var.db_system_db_home_database_db_backup_config_backup_destination_details_type
                }*/
            }
            defined_tags = var.database_config.db_home_database_defined_tags

            //db_domain = var.db_system_db_home_database_db_domain
            #Optional
            //backup_id = oci_database_backup.test_backup.id
            //backup_tde_password = var.db_system_db_home_database_backup_tde_password
            //database_id = oci_database_database.test_database.id
            //database_software_image_id = oci_database_database_software_image.test_database_software_image.id
            //freeform_tags = var.db_system_db_home_database_freeform_tags
            //tde_wallet_password = ""//var.db_system_db_home_database_tde_wallet_password
            //time_stamp_for_point_in_time_recovery = var.db_system_db_home_database_time_stamp_for_point_in_time_recovery
        }

        #Optional
        db_version = var.database_config.db_home_db_version
        defined_tags = var.database_config.db_home_defined_tags
        display_name = var.database_config.db_home_display_name
        //database_software_image_id = oci_database_database_software_image.test_database_software_image.id
        //freeform_tags = var.db_system_db_home_freeform_tags
    }

    db_system_options {
        #Optional
        storage_management = var.database_config.db_system_options_storage_management
    }
    
    disk_redundancy = var.database_config.disk_redundancy
    shape = var.database_config.shape
    display_name = var.database_config.display_name
    hostname = var.database_config.hostname
    data_storage_size_in_gb = var.database_config.data_storage_size_in_gb
    license_model = var.database_config.license_model
    node_count = var.database_config.node_count
    source = var.database_config.source
    defined_tags = var.database_config.defined_tags
    time_zone = var.database_config.time_zone
    //nsg_ids = var.db_system_nsg_ids
    
    lifecycle {
      ignore_changes = [
        defined_tags, freeform_tags, db_home
      ]
    }
    #Optional
    //backup_network_nsg_ids = var.db_system_backup_network_nsg_ids
    //backup_subnet_id = oci_core_subnet.test_subnet.id
    //cluster_name = var.db_system_cluster_name
    //cpu_core_count = var.db_system_cpu_core_count
    //data_storage_percentage = var.db_system_data_storage_percentage
    //domain = var.db_system_domain
    //fault_domains = var.db_system_fault_domains
    //kms_key_id = oci_kms_key.test_key.id
    //kms_key_version_id = oci_kms_key_version.test_key_version.id
    /*
    maintenance_window_details {

        #Optional
        days_of_week {

            #Optional
            name = var.db_system_maintenance_window_details_days_of_week_name
        }
        hours_of_day = var.db_system_maintenance_window_details_hours_of_day
        lead_time_in_weeks = var.db_system_maintenance_window_details_lead_time_in_weeks
        months {

            #Optional
            name = var.db_system_maintenance_window_details_months_name
        }
        preference = var.db_system_maintenance_window_details_preference
        weeks_of_month = var.db_system_maintenance_window_details_weeks_of_month
    }*/
    //private_ip = var.db_system_private_ip
    //source_db_system_id = oci_database_db_system.test_db_system.id
    //sparse_diskgroup = var.db_system_sparse_diskgroup
}