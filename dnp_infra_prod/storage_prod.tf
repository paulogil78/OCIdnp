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
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
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
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
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
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
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
    }
}

resource "null_resource" "OASOracleHomeMountFileSystem" {
    for_each = {
        oas1 = "10.10.252.67"
        oas2 = "10.10.252.71"
    }
    depends_on = [ oci_core_instance.bastion_prod, module.oas_servers, oci_file_storage_export.oas_oracle_home_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value //"10.10.252.67" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo /bin/su -c \"yum install -y -q nfs-utils\"",
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/product/fmw/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/oas_oracle_home /u01/app/oracle/product/fmw/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/product/fmw/\""
        ]
    }
  
}

resource "null_resource" "OASDomainMountFileSystem" {
    for_each = {
        oas1 = "10.10.252.67"
        oas2 = "10.10.252.71"
    }

    depends_on = [ oci_core_instance.bastion_prod, module.oas_servers, oci_file_storage_export.oas_oracle_home_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value //"10.10.252.67" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo /bin/su -c \"yum install -y -q nfs-utils\"",
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/admin/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/oas_domain /u01/app/oracle/admin/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/admin/\""
        ]
    }
  
}