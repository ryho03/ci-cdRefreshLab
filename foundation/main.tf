terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "9.12.1"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
}

# Resource - compartment
resource "oci_identity_compartment" "lab_compartment" {
    name = "lab_compartment"
    description = "Compartment for lab resources"
    compartment_id = var.tenancy_ocid
    enable_delete = true
    }