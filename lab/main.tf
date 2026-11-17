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

# Locals
locals {
  e2Micro_shapes = "VM.Standard.E2.1.Micro"
  flex_shapes    = "VM.Standard.A1.Flex"
}

# ---- Lookups ----
## Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
# Ubuntu Linux image
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_id
  shape                    = "VM.Standard.E2.1.Micro"
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "26.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "flex_ubuntu" {
  compartment_id           = var.compartment_id
  shape                    = "VM.Standard.A1.Flex"
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "26.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ---- Network ----
# VCN
resource "oci_core_vcn" "lab_vcn" {
  dns_label      = "labvcn"
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_id
  display_name   = "Lab VCN"
}

# Internet Gateway
resource "oci_core_internet_gateway" "lab_igw" {
  compartment_id = var.compartment_id
  display_name   = "Lab IGW"
  vcn_id         = oci_core_vcn.lab_vcn.id
}

# Route Table (internet traffic -> gateway)
resource "oci_core_route_table" "lab_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "Lab Route Table"
  route_rules {
    network_entity_id = oci_core_internet_gateway.lab_igw.id
    destination       = "0.0.0.0/0"
  }
}
# Security List (allow SSH in)
resource "oci_core_network_security_group" "lab_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "Lab NSG"
}

resource "oci_core_network_security_group" "lab_nsg_ansible" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "Lab NSG Ansible"
}

resource "oci_core_security_list" "lab_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "Lab Security List"
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.my_ip
    description = "Allow SSH from my home IP"
    tcp_options {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lab_nsg_rule" {
  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  description               = "Allow SSH from my home IP"
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.my_ip
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lab_nsg_rule_egress" {
  network_security_group_id = oci_core_network_security_group.lab_nsg.id
  description               = "Allow all outbound traffic"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}

resource "oci_core_network_security_group_security_rule" "lab_nsg_ans_rule" {
  network_security_group_id = oci_core_network_security_group.lab_nsg_ansible.id
  description               = "Allow SSH from lab_instance_2_ans"
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "${oci_core_instance.lab_instance_2_ans.private_ip}/32"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

# Subnet (public)
resource "oci_core_subnet" "lab_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.lab_vcn.id
  display_name      = "Lab Subnet"
  cidr_block        = "10.1.1.0/24"
  route_table_id    = oci_core_route_table.lab_rt.id
  security_list_ids = [oci_core_security_list.lab_sl.id]
  dns_label         = "labsubnet"
}
# ---- Compute ----
# VM code
resource "oci_core_instance" "lab_instance_1" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "Lab Instance 1"
  create_vnic_details {
    subnet_id        = oci_core_subnet.lab_subnet.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.lab_nsg.id, oci_core_network_security_group.lab_nsg_ansible.id]
    display_name     = "Lab Instance 1 VNIC"
    hostname_label   = "lab-vm1"
  }
  shape = local.e2Micro_shapes
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
}

resource "oci_core_instance" "lab_instance_2_ans" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "Lab Instance 2"
  create_vnic_details {
    subnet_id        = oci_core_subnet.lab_subnet.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.lab_nsg.id]
    display_name     = "Lab Instance 2 ANS VNIC"
    hostname_label   = "lab-vm2-ans"
  }
  shape = local.flex_shapes
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.flex_ubuntu.images[0].id
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
}