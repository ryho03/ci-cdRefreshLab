# Outputlab_instance_1's private IP
output "lab_vm_private_ip" {
  value = oci_core_instance.lab["lab-target"].private_ip
}
# Output lab_instance_2_ans's public IP
output "lab_vm_ans_public_ip" {
  value = oci_core_instance.lab["lab-control"].public_ip
}
# TODO: Find the right image
#  output "debug_images" {
#  value = [for img in slice(data.oci_core_images.ubuntu.images, 0, 5) :
#    "${img.operating_system} | ${img.operating_system_version} | ${img.display_name}"]
#  }