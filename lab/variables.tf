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