# ==============================================================================
# ORACLE FOUNDRY - ONE-CLICK DEPLOYMENT
# ==============================================================================
# This Terraform template is designed for Oracle Resource Manager
# Users click "Deploy to Oracle Cloud" button and everything happens automatically
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}

# ==============================================================================
# Variables (user will be prompted for these in OCI Console)
# ==============================================================================

variable "tenancy_ocid" {
  description = "Oracle Cloud Tenancy ID (auto-filled)"
}

variable "compartment_ocid" {
  description = "Compartment to deploy resources"
}

variable "region" {
  description = "Oracle Cloud region (US Ashburn for arm availability)"
  default = "us-east4"
}

variable "ssh_public_key" {
  description = "Your SSH public key (for emergency access only, not required for daily use)"
  type        = string
}

variable "instance_shape" {
  description = "Instance shape (4 OCPU ARM is Always Free)"
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (4 is maximum for Always Free)"
  default     = 4
}

variable "instance_memory_in_gbs" {
  description = "RAM in GB (24GB is maximum for Always Free)"
  default     = 24
}

variable "boot_volume_size_in_gbs" {
  description = "Boot disk size (up to 200GB free)"
  default     = 100
}

# ==============================================================================
# Data Sources
# ==============================================================================

# Get the latest Ubuntu 24.04 ARM image
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# ==============================================================================
# Network Resources
# ==============================================================================

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "foundry_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "foundry-vcn"
  dns_label      = "foundry"
}

# Internet Gateway
resource "oci_core_internet_gateway" "foundry_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-internet-gateway"
  enabled        = true
}

# Route Table
resource "oci_core_route_table" "foundry_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.foundry_ig.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Security List (Firewall Rules)
resource "oci_core_security_list" "foundry_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-security-list"

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH (port 22)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (port 80)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS (port 443)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Dokploy Dashboard (port 3000)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 3000
      max = 3000
    }
  }

  # FastCORS Proxy (port 8080)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  # ICMP (ping)
  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
  }
}

# Subnet
resource "oci_core_subnet" "foundry_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.foundry_vcn.id
  display_name      = "foundry-subnet"
  dns_label         = "foundrysubnet"
  route_table_id    = oci_core_route_table.foundry_rt.id
  security_list_ids = [oci_core_security_list.foundry_sl.id]
}

# ==============================================================================
# Cloud-Init Script (Installs Everything Automatically)
# ==============================================================================

locals {
  cloud_init = <<-EOT
#!/bin/bash
set -e

# Wait for cloud-init to complete (prevents race conditions)
cloud-init status --wait

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# Download and run the Oracle Foundry bootstrap script
curl -sSL https://raw.githubusercontent.com/shapefuture/oracle-foundry/main/oracle-foundry-bootstrap.sh -o /tmp/foundry-bootstrap.sh
chmod +x /tmp/foundry-bootstrap.sh

# Run the bootstrap (this installs Dokploy, Podman, FastCORS, etc.)
bash /tmp/foundry-bootstrap.sh 2>&1 | tee /var/log/foundry-bootstrap.log

# Mark completion
echo "FOUNDRY_SETUP_COMPLETE" > /tmp/foundry-ready
EOT
}

# ==============================================================================
# Compute Instance (The Server)
# ==============================================================================

resource "oci_core_instance" "foundry_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "oracle-foundry"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.foundry_subnet.id
    display_name     = "foundry-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }

  # Add timeout for creation (ARM capacity can be limited)
  timeouts {
    create = "60m"
  }
}

# ==============================================================================
# Outputs (Displayed to User After Deployment)
# ==============================================================================

output "foundry_public_ip" {
  description = "Public IP address of your Oracle Foundry"
  value       = oci_core_instance.foundry_instance.public_ip
}

output "dokploy_dashboard" {
  description = "Dokploy Dashboard URL (wait 8-10 minutes after creation)"
  value       = "http://${oci_core_instance.foundry_instance.public_ip}:3000"
}

output "fastcors_proxy" {
  description = "FastCORS Proxy URL"
  value       = "http://${oci_core_instance.foundry_instance.public_ip}:8080"
}

output "instance_ocid" {
  description = "Instance OCID (for reference)"
  value       = oci_core_instance.foundry_instance.id
}

output "setup_instructions" {
  description = "What to do next"
  value       = <<-EOT

  🎉 YOUR ORACLE FOUNDRY IS DEPLOYING! 🎉

  ⏱️  Setup Time: 8-10 minutes (the script is running automatically in the cloud)

  📍 Your Server IP: ${oci_core_instance.foundry_instance.public_ip}

  🌐 Access Your Services (after 10 minutes):

     Dokploy Dashboard: http://${oci_core_instance.foundry_instance.public_ip}:3000
     FastCORS Proxy:    http://${oci_core_instance.foundry_instance.public_ip}:8080

  📝 Next Steps:

  1. Wait 8-10 minutes for automatic setup to complete
  2. Open the Dokploy Dashboard URL above
  3. Create your admin account (first time only)
  4. Start deploying apps from GitHub!

  💡 No SSH or terminal needed - everything is ready to use via the web browser!

  EOT
}
