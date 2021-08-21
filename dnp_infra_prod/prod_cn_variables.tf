variable "num_instances_wl" {
  description = "Amount of instances to create"
  default     = 3
}

variable "num_instances_oas" {
  description = "Amount of OAS instances to create"
  default     = 2
}

variable "num_instances_oam" {
  description = "Amount of OAM instances to create"
  default     = 2
}

variable "num_instances_win" {
  description = "Amount of OAS instances to create"
  default     = 2
}

variable "num_instances_odi" {
  description = "Amount of ODI instances to create"
  default     = 1
}

variable "num_instances_oid" {
  description = "Amount of OID instances to create"
  default     = 2
}

variable "availability_domain" {
  description = "Amount of availabilitydomain"
  default     = 3
}

variable "compute_instance_compartment_name" {
  description = "Defines the compartment name where the infrastructure will be created"
  default     = "PROD"
}
/*
variable "tenancy_ocid" {
  description = "OCID of tenancy"
  default     = "ocid1.tenancy.oc1..aaaaaaaabuuix4xolxdmgjdiz32kvhx43d3wfjwvsjkde6njiqas6uryk3la"
}

variable "user_ocid" {
  description = "User OCID in tenancy. Currently hardcoded to user denny.alquinta@oracle.com"
  default     = "ocid1.user.oc1..aaaaaaaavi4xysrrcguoficyryexdxxjw3hqz33t3r5wivpnxbleepk277jq"
}

variable "fingerprint" {
  description = "API Key Fingerprint for user_ocid derived from public API Key imported in OCI User config"
  default     = "f4:7f:82:3d:40:4e:36:d5:82:a4:19:1c:af:7c:22:a7"
}

variable "private_key_path" {
  description = "Private Key Absolute path location where terraform is executed"
  default     = "C:\\Users\\carorodr\\Documents\\ase\\cloud\\terraform\\OCI_Keys\\oci_api_key.pem"
}

variable "region" {
  description = "Target region where artifacts are going to be created"
  default     = "us-phoenix-1"
}*/

variable "instance_shape" {
  description = "Defines the shape to be used on compute creation"
  default     = "VM.Standard2.2"
}

variable "subnet" {
  description = "ID of subnet"
  default     = "ocid1.subnet.oc1.phx.aaaaaaaa5zfdqztytt46tersavfol5uqzafhohyfd4zbomheqjc7dzua6fqq"
}

variable "instance_image_linux_ocid" {
  description = "Defines the OCID for the OS image to be used on artifact creation. Extract OCID from: https://docs.cloud.oracle.com/iaas/images/ or designated custom image OCID created by packer"
  default     = "ocid1.image.oc1.phx.aaaaaaaanj7qmui2ux5hbiwtbtkzajuvvhuzo2y7755stim22ue6msqwv2ja"
}

variable "instance_image_linux_ocid_bastion"{
  description = "Defines the OCID for the OS image to be used on artifact creation. Extract OCID from: https://docs.cloud.oracle.com/iaas/images/ or designated custom image OCID created by packer"
  default     = "ocid1.image.oc1.phx.aaaaaaaanj7qmui2ux5hbiwtbtkzajuvvhuzo2y7755stim22ue6msqwv2ja"
}

variable "instance_image_win_ocid" {
  description = "Defines the OCID for the OS image to be used on artifact creation. Extract OCID from: https://docs.cloud.oracle.com/iaas/images/ or designated custom image OCID created by packer"
  default     = "ocid1.image.oc1.phx.aaaaaaaafn7ehm7tffoypsohi3bn7m2cig7kwcibysycnf5cqzt62fqil2oq"
}

variable "display_weblogic" {
  description = "Defines the vm name"
  default     = "PDWLS0"
}

variable "display_oas" {
  description = "Defines the vm name"
  default     = "PDOAS0"
}

variable "display_oam" {
  description = "Defines the vm name"
  default     = "PDOAM0"
}

variable "display_win" {
  description = "Defines the vm name"
  default     = "PDIIS0"
}

variable "display_odi" {
  description = "Defines the vm name"
  default     = "PDODI0"
}

variable "display_oid" {
  description = "Defines the vm name"
  default     = "PDOID0"
}

variable "front_end" {
  description = "Type of vm"
  default     = "FE"
}

variable "back_end" {
  description = "Type of vm"
  default     = "BE"
}

