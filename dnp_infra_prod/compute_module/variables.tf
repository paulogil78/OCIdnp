variable "input_num_instances" {}
variable "input_compartment" {}
variable "input_image" {}
variable "input_shape" {}
variable "input_subnet" {}
variable "input_display" {}
variable "input_end" {}

variable "compute_availability_domain_list" {
  type        = list(any)
  description = "Defines the availability domain where OCI artifact will be created. This is a numeric value greater than 0"
  default     = ["gVYf:PHX-AD-1", "gVYf:PHX-AD-2", "gVYf:PHX-AD-3"]
}

variable "primary_vnic_display_name" {
  description = "Defines the Primary VNIC Display Name"
  default     = "primaryvnic"
}

variable "assign_public_ip_flag" {
  description = "Defines either machine will have or not a Public IP assigned. All Pvt networks this variable must be false"
  default     = false
}


variable "ssh_private_key" {
  description = "Private key to log into machine"
  default     = "C:\\Users\\carorodr\\Documents\\ase\\cloud\\terraform\\customers\\dnp\\SSH-DNP\\dnp_key"
}

variable "ssh_public_key" {
  description = "Defines SSH Public Key to be used in order to remotely connect to compute instance"
  type        = string
  default     = "../keys/dnp_cn_key.pub"
}

variable "defined_tags" {
  description = "Defined tags for every instance"
  type        = map
}

