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
    source_id   = var.instance_image_linux_ocid //local.linux7image
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
    source_id   = var.instance_image_linux_ocid //local.linux7image
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
    source_id   = var.instance_image_linux_ocid //local.linux7image
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