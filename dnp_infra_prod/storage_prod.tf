resource "oci_file_storage_mount_target" "prod_mount_target" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment
    subnet_id = module.subnet_Prod-CN01.subnet_id

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "prod_mt"//var.mount_target_display_name
    hostname_label = "prodmt"//var.mount_target_hostname_label
    //ip_address = var.mount_target_ip_address
    //nsg_ids = var.mount_target_nsg_ids
}
resource "oci_file_storage_export_set" "prod_export_set" {
    #Required
    mount_target_id = oci_file_storage_mount_target.prod_mount_target.id
    #Optional
    display_name = "ProdExportSet"//var.export_set_name
}

resource "oci_file_storage_file_system" "oas_oracle_home" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "OAS Oracle Home FS"//var.file_system_display_name
    //kms_key_id = oci_kms_key.test_key.id
    //source_snapshot_id = oci_file_storage_snapshot.test_snapshot.id
}

resource "oci_file_storage_export" "oas_oracle_home_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.oas_oracle_home.id
    path = "/oas_oracle_home" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source

        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        //anonymous_gid = var.export_export_options_anonymous_gid
        //anonymous_uid = var.export_export_options_anonymous_uid
        //identity_squash = var.export_export_options_identity_squash
        //require_privileged_source_port = var.export_export_options_require_privileged_source_port
    }
}

resource "oci_file_storage_file_system" "oas_domain" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "OAS Domain FS"//var.file_system_display_name
    //kms_key_id = oci_kms_key.test_key.id
    //source_snapshot_id = oci_file_storage_snapshot.test_snapshot.id
}

resource "oci_file_storage_export" "oas_domain_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.oas_domain.id
    path = "/oas_domain" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source

        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        //anonymous_gid = var.export_export_options_anonymous_gid
        //anonymous_uid = var.export_export_options_anonymous_uid
        //identity_squash = var.export_export_options_identity_squash
        //require_privileged_source_port = var.export_export_options_require_privileged_source_port
    }
}

resource "null_resource" "OASOracleHomeMountFileSystem" {
    depends_on = [
      //instancia oas, bastion host, storage_export
    ]

    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "opc"
            host = "" //oas_private_ip_address
            private_key = file(var.private_key_oci)
            script_path = "/home/opc/myssh.sh"
            agent = false
            timeout = "10m"
            bastion_host = "" //bastion public ip 
            bastion_port = "22"
            bastion_user = "opc"
            bastion_private_key = file(var.private_key_oci)
        }
        inline = [
            "sudo /bin/su -c \"yum install -y -q nfs-utils\"",
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/fmw/product/\"",
            "sudo /bin/su -c \"echo '10.0.1.25:/oas_oracle_home /u01/app/oracle/fmw/product/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /oas_oracle_home\""
        ]
    }
  
}