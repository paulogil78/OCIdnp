data "oci_identity_availability_domains" "test_ADs" {
  #Required
  compartment_id = var.tenancy_ocid
}
data "oci_identity_availability_domain" "AD1" {
  #Required
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}
data "oci_identity_availability_domain" "AD2" {
  #Required
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}
data "oci_identity_availability_domain" "AD3" {
  #Required
  compartment_id = var.tenancy_ocid
  ad_number      = 3
}
variable "ad_ashburn_list" {
  default = ["gVYf:US-ASHBURN-AD-1", "gVYf:US-ASHBURN-AD-2", "gVYf:US-ASHBURN-AD-3"]
}

data "oci_core_services" "objectStorage_service" {
  filter {
    name   = "name"
    values = [".*Object.*Storage"]
    regex  = true
  }
}
data "oci_core_services" "ash_objectStorage_service" {
  filter {
    name   = "name"
    values = [".*Object.*Storage"]
    regex  = true
  }
  provider = oci.DR
}
data "oci_core_shapes" "free_tier_shapes" {
  compartment_id = var.tenancy_ocid
  filter {
    name   = "name"
    values = ["VM.Standard.E2.1.Micro"]
  }
}

data "oci_core_images" "linux7_images_ash" {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaivlloczgwwhdvbdnxwy5s7jfe7ekrweaglno33xd4l2bkpklf3qq"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
  operating_system = "Oracle Linux"
  operating_system_version = "7.9"
  /*display_name = "Oracle-Linux-7.9-2021.04.09-0"*/
}
locals {
  linux7image_ash = data.oci_core_images.linux7_images_ash.images[0].id
}
data "oci_core_images" "linux7_images" {
  compartment_id = var.tenancy_ocid
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
  operating_system = "Oracle Linux"
  operating_system_version = "7.9"
  /*display_name = "Oracle-Linux-7.9-2021.04.09-0"*/
}
locals {
  linux7image = data.oci_core_images.linux7_images.images[0].id
}
data "oci_core_images" "windows_image" {
  compartment_id = var.tenancy_ocid
  operating_system = "Windows"
  filter {
    name = "display_name"
    values = ["Windows-Server-2019-Standard-Edition-VM-Gen2-2021.04.13-0"]
  }
}
locals {
  windowsImage = data.oci_core_images.windows_image.images[0].id
}

locals {
  free_tier_shape = distinct(data.oci_core_shapes.free_tier_shapes.shapes[*].name)[0]
}
locals {
  object_storage_cidr = data.oci_core_services.objectStorage_service.services[0].cidr_block
}
locals {
  object_storage_id = data.oci_core_services.objectStorage_service.services[0].id
}
locals {
  phx_ad1 = data.oci_identity_availability_domain.AD1.name
}
locals {
  phx_ad2 = data.oci_identity_availability_domain.AD2.name
}
locals {
  phx_ad3 = data.oci_identity_availability_domain.AD3.name
}
locals {
  ash_ad1 = var.ad_ashburn_list[0]
}
locals {
  ash_ad2 = var.ad_ashburn_list[1]
}
locals {
  ash_ad3 = var.ad_ashburn_list[2]
}
locals {
  ash_object_storage_cidr = data.oci_core_services.ash_objectStorage_service.services[0].cidr_block
}
locals {
  ash_object_storage_id = data.oci_core_services.ash_objectStorage_service.services[0].id
}