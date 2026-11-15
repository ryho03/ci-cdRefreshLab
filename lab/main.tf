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
resource "oci_core_route_table" "lab_rt" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.lab_vcn.id
  display_name = "Lab Route Table"
  route_rules {
    network_entity_id = oci_core_internet_gateway.lab_igw.id
    destination = "0.0.0.0/0"
  }
}
# TODO: security list (allow SSH in)
resource "oci_core_network_security_group" "lab_nsg" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.lab_vcn.id
  display_name = "Lab NSG"
}

resource "oci_core_security_list" "lab_sl" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.lab_vcn.id
  display_name = "Lab Security List"
  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }
  ingress_security_rules {
    protocol = "6" # TCP
    source = "149.13.200.0/32"
    description = "Allow SSH from my home IP"
    tcp_options {
      max = 22
      min = 22
    }
  }  
}

resource "oci_core_network_security_group_security_rule" "lab_nsg_rule" {
  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  description = "Allow SSH from my home IP"
  direction = "INGRESS"
  protocol = "6" # TCP
  source = "149.13.200.0/32"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lab_nsg_rule_egress" {
  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  description = "Allow all outbound traffic"
  direction = "EGRESS"
  protocol = "all"
  destination = "0.0.0.0/0"
}
# TODO: subnet (public)
resource "oci_core_subnet" "lab_subnet" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.lab_vcn.id
  display_name = "Lab Subnet"
  cidr_block = "10.1.1.0/24"
  route_table_id = oci_core_route_table.lab_rt.id
  security_list_ids = [oci_core_security_list.lab_sl.id]
}
# ---- Compute ----
# TODO: the VM