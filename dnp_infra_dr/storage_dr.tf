/*OAS*/
resource "oci_file_storage_mount_target" "dr_mount_target" {
    #Required
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    subnet_id = var.subnet

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    display_name = "dr_mt"//var.mount_target_display_name
    hostname_label = "drmt"//var.mount_target_hostname_label
    lifecycle {
        ignore_changes = [
        defined_tags, freeform_tags
        ]
    }
}
resource "oci_file_storage_export_set" "dr_export_set" {
    #Required
    mount_target_id = oci_file_storage_mount_target.dr_mount_target.id
    #Optional
    display_name = "DRExportSet"//var.export_set_name
}

resource "oci_file_storage_file_system" "oas_data" {
    #Required
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
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
    export_set_id = oci_file_storage_export_set.dr_export_set.id
    file_system_id = oci_file_storage_file_system.oas_data.id
    path = "/bidataoas59" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_dr_subnet_CN01//var.export_export_options_source
        #Optional
        access = "READ_WRITE"//var.export_export_options_access
        identity_squash = "NONE"
    }
}

resource "null_resource" "OASDataMountFileSystem" {
    depends_on = [ oci_core_instance.bastion_prod, module.CreateInstances, oci_file_storage_export.oas_data_export]

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.120" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo /bin/su -c \"yum install -y -q nfs-utils\"",
            "sudo /bin/su -c \"mkdir -p /u01/app/oracle/bidataoas59/\"",
            "sudo /bin/su -c \"echo 'drmt.cn01.drdnp.oraclevcn.com:/bidataoas59 /u01/app/oracle/bidataoas59/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /u01/app/oracle/bidataoas59/\""
        ]
    }
  
}


resource "oci_core_volume" "dr_oas1_volumes" {
    for_each = {
        domain = 50
        mw   = 50
        logs = 50    
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "oas1-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.CreateInstances.instanceinfo]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oas1_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycs5xd2celdx7gwvjka5naqn5ukxhyiila5ymvo4jptzja" //oas1
    volume_id = oci_core_volume.dr_oas1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.120"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycs5xd2celdx7gwvjka5naqn5ukxhyiila5ymvo4jptzja"
    volume_id = oci_core_volume.dr_oas1_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.120"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycs5xd2celdx7gwvjka5naqn5ukxhyiila5ymvo4jptzja"
    volume_id = oci_core_volume.dr_oas1_volumes["domain"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.120"  //oas1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

resource "oci_core_volume" "dr_oid_volumes" {
    for_each = {
        data = 50
        mw = 50
        logs = 50    
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "oid-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.oid_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "oid_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc5qntduc2gpvlykrfd64utc3dy72m6tohg5izlukcpm2q"
    volume_id = oci_core_volume.dr_oid_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.73"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc5qntduc2gpvlykrfd64utc3dy72m6tohg5izlukcpm2q"
    volume_id = oci_core_volume.dr_oid_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.73"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc5qntduc2gpvlykrfd64utc3dy72m6tohg5izlukcpm2q"
    volume_id = oci_core_volume.dr_oid_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.73"  //oid_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

resource "oci_core_volume" "dr_odi_volumes" {
    for_each = {
        data = 50
        mw = 50
        logs = 50    
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "odi-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.odi_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "odi_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc65urtmjavsweglll45zogxczyr52dztiwfxik6zuh2fa"
    volume_id = oci_core_volume.dr_odi_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.88"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc65urtmjavsweglll45zogxczyr52dztiwfxik6zuh2fa"
    volume_id = oci_core_volume.dr_odi_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.88"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc65urtmjavsweglll45zogxczyr52dztiwfxik6zuh2fa"
    volume_id = oci_core_volume.dr_odi_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.88"  //odi_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

/* File Storage (domain, product, soporte1) */

/* Block volumes (logs) */

resource "oci_core_volume" "dr_wls1_volumes" {
    for_each = {
        data = 50
        logs = 50
        mw = 50    
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "wls-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.weblogic_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "wls1_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoychfwxdvdbsfxftfg6ctzaa5tgst7yteyfcrvqw52u3w4a"
    volume_id = oci_core_volume.dr_wls1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.67"  //wls1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoychfwxdvdbsfxftfg6ctzaa5tgst7yteyfcrvqw52u3w4a"
    volume_id = oci_core_volume.dr_wls1_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.67"  //wls1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

resource "oci_core_volume_attachment" "wls1_mw_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoychfwxdvdbsfxftfg6ctzaa5tgst7yteyfcrvqw52u3w4a"
    volume_id = oci_core_volume.dr_wls1_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.67"  //wls1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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


/************WINDOWS STORAGE**************/

resource "oci_core_volume" "dr_win_volumes" {
    for_each = {
        videos = 600
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "win-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.win_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "win_videos_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycmtuvdgejy3xjyh3riw56avzysiijke6uzpkt4lgc5iiq"
    volume_id = oci_core_volume.dr_win_volumes["videos"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

}

resource "oci_file_storage_file_system" "wls_soporte1_fs" {
    #Required
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name

    #Optional
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
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
    export_set_id = oci_file_storage_export_set.dr_export_set.id
    file_system_id = oci_file_storage_file_system.wls_soporte1_fs.id
    path = "/soporte1" //var.export_path

    #Optional
    export_options {
        #Required
        source = var.cidr_vcn_dr_subnet_CN01//var.export_export_options_source

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
        wls1 = "10.10.253.67"
        oas1 = "10.10.253.120"
    }
    depends_on = [ oci_core_instance.bastion_prod, oci_file_storage_export.wls_soporte1_export]

    connection {
        type = "ssh"
        user = "opc"
        host = each.value //"10.10.252.67" //oas_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh4.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo /bin/su -c \"yum install -y -q nfs-utils\"",
            "sudo /bin/su -c \"mkdir -p /soporte1/\"",
            "sudo /bin/su -c \"echo 'drmt.cn01.drdnp.oraclevcn.com:/soporte1 /soporte1/ nfs rsize=8192,wsize=8192,timeo=14,intr 0  0' >> /etc/fstab\"",
            "sudo /bin/su -c \"mount /soporte1/\""
        ]
    }
  
}

/* OAM */

resource "oci_core_volume" "dr_oam1_volumes" {
    for_each = {
        data = 50
        logs = 50
        mw = 50
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "oam1-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.oam_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "oam1_logs_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycjypqnrdqwxg3puy3bcp4eflod67nmpbltefxbldgqgcq"
    volume_id = oci_core_volume.dr_oam1_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.92"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycjypqnrdqwxg3puy3bcp4eflod67nmpbltefxbldgqgcq"
    volume_id = oci_core_volume.dr_oam1_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.92"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

resource "oci_core_volume_attachment" "oam1_mw_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoycjypqnrdqwxg3puy3bcp4eflod67nmpbltefxbldgqgcq"
    volume_id = oci_core_volume.dr_oam1_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.92"  //oam1_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

/* OHS */

resource "oci_core_volume" "dr_ohs_volumes" {
    for_each = {
        data = 50
        logs = 50
        mw = 50
    }
    availability_domain = data.oci_identity_availability_domain.ad.name
    compartment_id = var.compute_instance_compartment_name
    display_name = "ohs-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_dr}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    //depends_on = [module.oam_servers.instance]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}
resource "oci_core_volume_attachment" "ohs_logs_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc7pj6xewcmy3rsbtxggb5sngf7wrmibyq2jziisncuatq"
    volume_id = oci_core_volume.dr_ohs_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.227"  //ohs_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh1.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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
resource "oci_core_volume_attachment" "ohs_data_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc7pj6xewcmy3rsbtxggb5sngf7wrmibyq2jziisncuatq"
    volume_id = oci_core_volume.dr_ohs_volumes["data"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.227"  //ohs_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh2.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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

resource "oci_core_volume_attachment" "ohs_mw_attachment" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = "ocid1.instance.oc1.iad.anuwcljr756lyoyc7pj6xewcmy3rsbtxggb5sngf7wrmibyq2jziisncuatq"
    volume_id = oci_core_volume.dr_ohs_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.253.227"  //ohs_private_ip_address
        private_key = "${file("../keys/dnp_cn_key")}" //file("../keys/dnp_cn_key.pub")
        script_path = "/home/opc/myssh3.sh"
        agent = false
        timeout = "10m"
        bastion_host = "132.145.134.187" //bastion public ip 
        //bastion_port = "22"
        bastion_user = "opc"
        bastion_private_key = "${file("../keys/dnp_cn_key")}"
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