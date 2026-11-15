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

# ---- Lookups ----
## Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# TODO: find an Oracle Linux image

# ---- Network ----
# TODO: VCN
resource "oci_core_vcn" "lab_vcn" {
  dns_label = "labvcn"
  cidr_block = "10.1.0.0/16"
  compartment_id = var.compartment_id
  display_name = "Lab VCN"
}

# TODO: internet gateway
resource "oci_core_internet_gateway" "lab_igw"{
  compartment_id = var.compartment_id
  display_name = "Lab IGW"
  vcn_id = oci_core_vcn.lab_vcn.id
}

# TODO: route table  (internet traffic -> gateway)
# TODO: security list (allow SSH in)
# TODO: subnet (public)

# ---- Compute ----
# TODO: the VM