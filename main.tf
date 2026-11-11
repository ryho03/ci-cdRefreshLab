terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "9.12.1"
    }
  }
}

provider "oci" {
  # Configuration options
}

# ---- Lookups ----
# TODO: find an availability domain
# TODO: find an Oracle Linux image

# ---- Network ----
# TODO: VCN
# TODO: internet gateway
# TODO: route table  (internet traffic -> gateway)
# TODO: security list (allow SSH in)
# TODO: subnet (public)

# ---- Compute ----
# TODO: the VM