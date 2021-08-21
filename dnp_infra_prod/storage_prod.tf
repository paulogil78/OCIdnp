/*OAS*/
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

/*resource "oci_file_storage_file_system" "oas_oracle_home" {
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
}*/
/*
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
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/product/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/oas_oracle_home /u01/app/oracle/product/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/product/\""
        ]
    }
  
}*/

resource "oci_file_storage_file_system" "oas_data" {
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


resource "oci_file_storage_export" "oas_data_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.oas_data.id
    path = "/bidataoas59" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source
        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
}

resource "null_resource" "OASDataMountFileSystem" {
    for_each = {
        oas1 = "10.10.252.67"
        oas2 = "10.10.252.71"
    }

    depends_on = [ oci_core_instance.bastion_prod, module.oas_servers, oci_file_storage_export.oas_data_export]

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
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/bidataoas59/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/bidataoas59 /u01/app/oracle/bidataoas59/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/bidataoas59/\""
        ]
    }
  
}

resource "oci_core_volume" "prod_oas1_volumes" {
    for_each = {
        domain = 50
        mw   = 50
        logs = 50    
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "oas1-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oas_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oas1_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[0].id
    volume_id = oci_core_volume.prod_oas1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.67"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "oas1_mw_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[0].id
    volume_id = oci_core_volume.prod_oas1_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.67"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/product/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/product/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/product/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "oas1_domain_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[0].id
    volume_id = oci_core_volume.prod_oas1_volumes["domain"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.67"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume" "prod_oas2_volumes" {
    for_each = {
        domain = 50
        mw   = 50
        logs = 50    
    }
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment
    display_name = "oas2-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oas_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oas2_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[1].id
    volume_id = oci_core_volume.prod_oas2_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.71"  //oas2_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oas2__mw_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[1].id
    volume_id = oci_core_volume.prod_oas2_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.71"  //oas2_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/product/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/product/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/product/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oas2__domain_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oas_servers.instance[1].id
    volume_id = oci_core_volume.prod_oas2_volumes["domain"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.71"  //oas2_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

/*OID*/
resource "oci_core_volume" "prod_oid_volumes" {
    for_each = {
        data = 50
        mw = 50
        logs = 50    
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "oid-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oid_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "oid_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[0].id
    volume_id = oci_core_volume.prod_oid_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.83"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oid_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[0].id
    volume_id = oci_core_volume.prod_oid_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.83"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/product/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/product/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/product/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oid_attachment3" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[0].id
    volume_id = oci_core_volume.prod_oid_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.83"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume" "prod_oid2_volumes" {
    for_each = {
        data = 50
        mw = 50
        logs = 50    
    }
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment
    display_name = "oid2-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oid_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "oid2_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[1].id
    volume_id = oci_core_volume.prod_oid2_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.84"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oid2_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[1].id
    volume_id = oci_core_volume.prod_oid2_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.84"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/product/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/product/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/product/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "oid2_attachment3" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oid_servers.instance[1].id
    volume_id = oci_core_volume.prod_oid2_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.84"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}


/************************************************ODI*********************************************************************/
resource "oci_core_volume" "prod_odi_volumes" {
    for_each = {
        data = 50
        mw = 50
        logs = 50    
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "odi-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.odi_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "odi_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.odi_servers.instance[0].id
    volume_id = oci_core_volume.prod_odi_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.110"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}


resource "oci_core_volume_attachment" "odi_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.odi_servers.instance[0].id
    volume_id = oci_core_volume.prod_odi_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.110"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/product/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/product/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/product/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "odi_attachment3" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.odi_servers.instance[0].id
    volume_id = oci_core_volume.prod_odi_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.110"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

/* PROD WEBLOGIC*/

/* File Storage (doamin, product, soporte1) */
resource "oci_file_storage_file_system" "wls_oracle_home" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "WLS Oracle Home FS"//var.file_system_display_name
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
}

resource "oci_file_storage_export" "wls_oracle_home_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.wls_oracle_home.id
    path = "/wls_oracle_home" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source

        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
}
resource "null_resource" "WLSOracleHomeMountFileSystem" {
    for_each = {
        wls1 = "10.10.252.120"
        wls2 = "10.10.252.79"
        wls3 = "10.10.252.77"
    }
    depends_on = [ oci_core_instance.bastion_prod, module.weblogic_servers, oci_file_storage_export.wls_oracle_home_export]

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
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/product/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/wls_oracle_home /u01/app/oracle/product/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/product/\""
        ]
    }
  
}

/*
resource "oci_file_storage_file_system" "wls_domain" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "WLS Domain FS"//var.file_system_display_name
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
}*/

/*
resource "oci_file_storage_export" "wls_domain_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.wls_domain.id
    path = "/wls_domain" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source
        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
}*/
/*
resource "null_resource" "WLSDomainMountFileSystem" {
    for_each = {
        wls1 = "10.10.252.120"
        wls2 = "10.10.252.79"
        wls3 = "10.10.252.77"
    }

    depends_on = [ oci_core_instance.bastion_prod, module.weblogic_servers, oci_file_storage_export.wls_domain_export]

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
  
}*/
/* Block volumes (logs) */
resource "oci_core_volume" "prod_wls1_volumes" {
    for_each = {
        data = 50
        logs = 50    
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "wls-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.weblogic_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "wls1_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[0].id
    volume_id = oci_core_volume.prod_wls1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.120"  //wls1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume_attachment" "wls1_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[0].id
    volume_id = oci_core_volume.prod_wls1_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.120"  //wls1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume" "prod_wls2_volumes" {
    for_each = {
        data = 50
        logs = 50    
    }
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment
    display_name = "wls-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.weblogic_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "wls2_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[1].id
    volume_id = oci_core_volume.prod_wls2_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.79"  //wls2_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "wls2_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[1].id
    volume_id = oci_core_volume.prod_wls2_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.79"  //wls2_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume" "prod_wls3_volumes" {
    for_each = {
        data = 50
        logs = 50    
    }
    availability_domain = local.phx_ad3
    compartment_id = var.prod_compartment
    display_name = "wls-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.weblogic_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "wls3_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[2].id
    volume_id = oci_core_volume.prod_wls3_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.77"  //wls3_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "wls3_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.weblogic_servers.instance[2].id
    volume_id = oci_core_volume.prod_wls3_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.77"  //wls3_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

/************WINDOWS STORAGE**************/
resource "oci_core_volume" "prod_win_volumes" {
    for_each = {
        videos = 600
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "win-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.win_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "win_videos_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.win_servers.instance[0].id
    volume_id = oci_core_volume.prod_win_volumes["videos"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

}
resource "oci_file_storage_file_system" "wls_soporte1_fs" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "Soporte1FS"//var.file_system_display_name
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
}

/* Soporte1 FS */
resource "oci_file_storage_export" "wls_soporte1_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.wls_soporte1_fs.id
    path = "/soporte1" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source

        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
    lifecycle {
        ignore_changes = [
        export_options
        ]
    }
}
resource "null_resource" "WLSSoporte1MountFileSystem" {
    for_each = {
        wls1 = "10.10.252.120"
        wls2 = "10.10.252.79"
        wls3 = "10.10.252.77"
        oas1 = "10.10.252.67"
        oas2 = "10.10.252.71"
    }
    depends_on = [ oci_core_instance.bastion_prod, module.weblogic_servers, oci_file_storage_export.wls_soporte1_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value //"10.10.252.67" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
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
            "sudo /bin/su -c \"mkdir -p /soporte1/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/soporte1 /soporte1/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /soporte1/\""
        ]
    }
  
}

resource "null_resource" "WLSPreprodSoporte1MountFileSystem" {
    for_each = {
        wls_preprod = "10.10.251.157"
        wls_test = "10.10.251.227"
    }
    depends_on = [ oci_core_instance.bastion_prod, oci_core_instance.wls_preprod,oci_core_instance.wls_test, oci_file_storage_export.wls_soporte1_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value 
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
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
            "sudo /bin/su -c \"mkdir -p /soporte1/\"",
            "sudo /bin/su -c \"echo '10.10.252.113:/soporte1 /soporte1/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /soporte1/\""
        ]
    }
  
}

/* OAM */
resource "oci_core_volume" "prod_oam1_volumes" {
    for_each = {
        data = 50
        logs = 50    
    }
    availability_domain = local.phx_ad1
    compartment_id = var.prod_compartment
    display_name = "oam1-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oam_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oam1_logs_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oam_servers.instance[0].id
    volume_id = oci_core_volume.prod_oam1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.78"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "oam1_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oam_servers.instance[0].id
    volume_id = oci_core_volume.prod_oam1_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.78"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

resource "oci_core_volume" "prod_oam2_volumes" {
    for_each = {
        data = 50
        logs = 50    
    }
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment
    display_name = "oam2-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [module.oam_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oam2_logs_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oam_servers.instance[1].id
    volume_id = oci_core_volume.prod_oam2_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.123"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/logs/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/logs/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/logs/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}
resource "oci_core_volume_attachment" "oam2_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = module.oam_servers.instance[1].id
    volume_id = oci_core_volume.prod_oam2_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.252.123"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "158.101.8.194" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/ssh-privatekey-bastion.key")}"
    }
    
    # register and connect the iSCSI block volume
    provisioner "remote-exec" {
        inline = [
        "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l",
        ]
    }

    # initialize partition and file system
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
        "if [ $HAS_PARTITION -eq 0 ] ; then",
        "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
        "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
        "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
        "fi",
        ]
    }
    # mount the partition
    provisioner "remote-exec" {
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "sudo mkdir -p /u01/app/oracle/admin/",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "echo 'UUID='$${UUID}' /u01/app/oracle/admin/ xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
        "sudo mount -a",
        ]
    }

    # unmount and disconnect on destroy
    provisioner "remote-exec" {
        when       = destroy
        on_failure = continue
        inline = [
        "set -x",
        "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
        "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
        "sudo umount /u01/app/oracle/admin/",
        "if [[ $UUID ]] ; then",
        "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
        "fi",
        "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
        "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}",
        ]
    }
}

/* OAM PRODUCT FS */
resource "oci_file_storage_file_system" "oam_product" {
    #Required
    availability_domain = local.phx_ad2
    compartment_id = var.prod_compartment

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_prod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "OAM Product FS" //var.file_system_display_name
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
}

resource "oci_file_storage_export" "oam_product_fs_export" {
    #Required
    export_set_id = oci_file_storage_export_set.prod_export_set.id
    file_system_id = oci_file_storage_file_system.oam_product.id
    path = "/oam_oracle_home" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_prod_subnet_CN01//var.export_export_options_source

        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
}
resource "null_resource" "OAMPRODUCTMountFileSystem" {
    for_each = {
        oam1 = "10.10.252.78"
        oam2 = "10.10.252.123"
    }
    depends_on = [ oci_core_instance.bastion_prod, module.oam_servers, oci_file_storage_export.oam_product_fs_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value //"10.10.252.67" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
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
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/product/\"",
            "sudo /bin/su -c \"echo 'prodmt.cn01.proddnp.oraclevcn.com:/oam_oracle_home /u01/app/oracle/product/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/product/\""
        ]
    }
  
}