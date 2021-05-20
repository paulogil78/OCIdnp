resource "oci_kms_vault" "preprod_vault" {
  #Required
  compartment_id = var.preprod_compartment
  display_name   = var.preprod_vault_display_name
  vault_type     = var.vault_type

  #Optional
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_kms_key" "preprod_key" {
  #Required
  compartment_id = var.preprod_compartment
  display_name   = "PreprodWebLogicOCIKey"
  key_shape {
    #Required
    algorithm = "AES"
    length    = "32"
  }
  management_endpoint = oci_kms_vault.preprod_vault.management_endpoint

  #Optional
  defined_tags = {
    "DNP-Tags.Environment" = "${var.tag_environment_preprod}"
    "DNP-Tags.Department"  = "${var.tag_department_TI}"
  }
  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
  protection_mode = "SOFTWARE"
}

data "oci_kms_key" "test_key" {
  #Required
  key_id              = oci_kms_key.preprod_key.id
  management_endpoint = oci_kms_vault.preprod_vault.management_endpoint
}

/*resource "oci_kms_encrypted_data" "preprod_weblogic_admin_secret" {
    #Required
    crypto_endpoint = oci_kms_vault.preprod_vault.management_endpoint
    key_id = oci_kms_key.preprod_key.id
    plaintext = var.preprod_admin_secret
}*/