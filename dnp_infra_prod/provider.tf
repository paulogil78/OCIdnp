provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region

}
provider "oci" {
  region = var.region
  alias  = "PROD"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region_dr
  alias            = "DR"
}

terraform {
  backend "http" {
    address       = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/D0ZGLik2XyjLxlL4cNj2afe3OwbPhr6UeXbyZS8k54dOr9DnTFioXC8LFhby8fsU/n/axyqnsuaghzx/b/bucket-terraform-state-repo/o/terraform.tfstate"
    update_method = "PUT"
  }
}
