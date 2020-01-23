variable vsphere_user {}
variable vsphere_password {}
variable vsphere_server {}
variable vsphere_datacenter {}
variable vsphere_dvs {}
variable net_1_name {}
variable net_1_vlan {}
variable net_2_name {}
variable net_2_vlan {}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "uktme-01" {
}

resource "vsphere_distributed_virtual_switch" "legacy-VDS" {
  name          = var.vsphere_dvs
  datacenter_id = data.vsphere_datacenter.uktme-01.id
}

resource "vsphere_distributed_port_group" "net_1" {
  name                            = var.net_1_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.legacy-VDS.id
  vlan_id                         = var.net_1_vlan
}

resource "vsphere_distributed_port_group" "net_2" {
  name                            = var.net_2_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.legacy-VDS.id
  vlan_id                         = var.net_2_vlan

}