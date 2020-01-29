variable vsphere_user {}
variable vsphere_password {}
variable vsphere_server {}
variable vsphere_datacenter {}
variable net_1_name {}
variable net_2_name {}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

resource "vsphere_distributed_port_group" "net_1" {
}

resource "vsphere_distributed_port_group" "net_2" {
}