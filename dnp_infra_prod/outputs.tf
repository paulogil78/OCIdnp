output "shape" {
  value = distinct(data.oci_core_shapes.free_tier_shapes.shapes[*].name)[0]
}
output "image" {
  value = data.oci_core_images.linux7_images.images[0].id
}
output "vault_key" {
  value = data.oci_kms_key.test_key.id
}
output "Windows_Images"{
  value = local.windowsImage
}