# TODO: compartment ID
variable "tenancy_ocid" {
    type = string
    description = "OCID of the OCI tenancy (root compartment)"
}
variable "compartment_id" {
    type = string
    description = "OCID of the OCI lab compartment"
}
# TODO: path to your SSH public key
variable "ssh_public_key_path" {
    type = string
    description = "Path to your SSH public key"
}

# TODO: my home IP address
variable "my_ip" {
    type = string
    description = "My home IP address (for SSH access)"
}