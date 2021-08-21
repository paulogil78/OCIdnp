######################
##    datasources.tf 
##
#######################

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

/*locals {
 // availability_dom_id    = lookup(data.oci_identity_availability_domain.ad.availability_domain[0], "name") 
  availability_dom_id    = data.oci_identity_availability_domain.ad.name   
}
*/