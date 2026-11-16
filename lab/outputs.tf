# TODO: the VM's public IP

# TODO: Find the right image
#  output "debug_images" {
#  value = [for img in slice(data.oci_core_images.ubuntu.images, 0, 5) :
#    "${img.operating_system} | ${img.operating_system_version} | ${img.display_name}"]
#  }