/*TEST INSTANCES*/
resource "oci_core_instance" "wls_test" {
  count = 1
  #Required
  availability_domain = local.phx_ad2
  compartment_id      = var.preprod_compartment
  shape               = var.available_shapes[0]

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_Test-CN01.subnet_id
    assign_public_ip = "false"
  }
  display_name = "TTWLS01FE"

  source_details {
    #Required
    source_id   = local.linux7image
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}

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
}
resource "oci_core_volume_attachment" "testwls_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_test[0].id
    volume_id = oci_core_volume.test_wl_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable
}

resource "oci_core_instance" "windows_test" {
  count = 1
  #Required
  availability_domain = local.phx_ad2
  compartment_id      = var.preprod_compartment
  shape               = var.available_shapes[0]

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_Test-CN01.subnet_id
    assign_public_ip = "false"
  }
  display_name = "TTIIS01FE"

  source_details {
    #Required
    source_id   = local.windowsImage
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}

/*PREPROD INSTANCES*/

resource "oci_core_instance" "wls_preprod" {
  count = 1
  #Required
  availability_domain = local.phx_ad3
  compartment_id      = var.preprod_compartment
  shape               = var.available_shapes[1]

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_PreProd-CN01.subnet_id
    assign_public_ip = "false"
  }
  display_name = "PPWLS01FE"

  source_details {
    #Required
    source_id   = local.linux7image
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}

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
}
resource "oci_core_volume_attachment" "wls_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.wls_preprod[0].id
    volume_id = oci_core_volume.preprod_wl_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable
}

/* OAS PREPROD*/

resource "oci_core_instance" "oas_preprod" {
  count = 1
  #Required
  availability_domain = local.phx_ad3
  compartment_id      = var.preprod_compartment
  shape               = var.available_shapes[1]

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_PreProd-CN01.subnet_id
    assign_public_ip = "false"
  }
  display_name = "PPOAS01BE"

  source_details {
    #Required
    source_id   = local.linux7image
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}

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
}
resource "oci_core_volume_attachment" "oas_attachment2" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.oas_preprod[0].id
    volume_id = oci_core_volume.preprod_oas_volumes["mw"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable
}
resource "oci_core_volume_attachment" "oas_attachment3" {
    #Required
    attachment_type = "iscsi"//var.volume_attachment_attachment_type
    instance_id = oci_core_instance.oas_preprod[0].id
    volume_id = oci_core_volume.preprod_oas_volumes["logs"].id

    #Optional
    is_shareable = "true"//var.volume_attachment_is_shareable
}

resource "oci_core_instance" "windows_preprod" {
  count = 1
  #Required
  availability_domain = local.phx_ad3
  compartment_id      = var.preprod_compartment
  shape               = var.available_shapes[1]

  create_vnic_details {
    #Optional
    subnet_id = module.subnet_PreProd-CN01.subnet_id
    assign_public_ip = "false"
  }
  display_name = "PPIIS01FE"

  source_details {
    #Required
    source_id   = local.windowsImage
    source_type = "image"
  }

  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [
      defined_tags, freeform_tags, create_vnic_details
    ]
    create_before_destroy = true
  }

  metadata = {
    "ssh_authorized_keys" = "${file("../keys/dnp_cn_key.pub")}"
  }
}