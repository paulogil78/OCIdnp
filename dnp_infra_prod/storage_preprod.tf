resource "oci_core_volume" "test_wl_volumes" {
    for_each = {
        data=50
        mw=50    
    }
    availability_domain = local.phx_ad2
    compartment_id = var.preprod_compartment
    display_name = "testwl-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [oci_core_instance.wls_preprod]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "testwls_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_test[0].id
    volume_id = oci_core_volume.test_wl_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.227"  //ttweblogic_private_ip_address
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

resource "oci_core_volume_attachment" "testwls_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_test[0].id
    volume_id = oci_core_volume.test_wl_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.227"  //ttweblogic_private_ip_address
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

/* Preprod Weblogic */
resource "oci_core_volume" "preprod_wl_volumes" {
    for_each = {
        data=50
        mw=50    
    }
    availability_domain = local.phx_ad3
    compartment_id = var.preprod_compartment
    display_name = "wl-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [oci_core_instance.wls_preprod]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "wls_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_preprod[0].id
    volume_id = oci_core_volume.preprod_wl_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable
    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.157"  //ppweblogic_private_ip_address
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

resource "oci_core_volume_attachment" "wls_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_preprod[0].id
    volume_id = oci_core_volume.preprod_wl_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.157"  //ppweblogic_private_ip_address
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

/* PREPROD OAS*/
resource "oci_core_volume" "preprod_oas_volumes" {
    for_each = {
        data = 60
        mw = 50
        logs = 50    
    }
    availability_domain = local.phx_ad3
    compartment_id = var.preprod_compartment
    display_name = "oas-${each.key}-block-0"
    defined_tags = {
        "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
        "DNP-Tags.Department"  = "${var.tag_department_TI}"
    }
    size_in_gbs = each.value
    depends_on = [oci_core_instance.wls_preprod]

    lifecycle {
        ignore_changes = [defined_tags, freeform_tags]
    }
}

resource "oci_core_volume_attachment" "oas_attachment1" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.oas_preprod[0].id
    volume_id = oci_core_volume.preprod_oas_volumes["data"].id
    
    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.146"  //ppoas_private_ip_address
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

resource "oci_core_volume_attachment" "oas_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.oas_preprod[0].id
    volume_id = oci_core_volume.preprod_oas_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.146"  //ppoas_private_ip_address
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
resource "oci_core_volume_attachment" "oas_attachment3" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.oas_preprod[0].id
    volume_id = oci_core_volume.preprod_oas_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable

    connection {
        type = "ssh"
        user = "opc"
        host = "10.10.251.146"  //ppoas_private_ip_address
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

/*

*/