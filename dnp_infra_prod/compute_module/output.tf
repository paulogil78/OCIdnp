
/* output.tf 
Purpose: The following script defines the output for Compute located on private network*/

output "server_display_name" {
  description = "Compute Display Name"
  value       = oci_core_instance.Compute.*.display_name
}

output "instance_private_ip" {
  description = "Compute Private IP"
  value       = oci_core_instance.Compute.*.private_ip
}

output "instance" {
  description = "Compute Generated"
  value       = oci_core_instance.Compute
}
