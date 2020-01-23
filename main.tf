variable vsphere_user {}
variable vsphere_password {}
variable vsphere_server {}
variable vsphere_datacenter {}
variable vsphere_dvs {}
variable net_1_name {}
variable net_2_name {}
variable net_1_vlan {}
variable net_2_vlan {}
variable aci_private_key {}
variable aci_cert_name {}
variable apic_url {}
variable aci_user {}
variable bd_name {}
variable vrf_name {}
variable tenant_name {}
variable bd_subnet {}
variable anp_name {}
variable apic_vds_name {}
variable vmm_provider {
  default = "uni/vmmp-VMware"
}
variable net_1_port_id {}
variable net_2_port_id {}
variable vsphere_cluster {}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

provider "aci" {
  username    = var.aci_user
  private_key = var.aci_private_key
  cert_name   = var.aci_cert_name
  url         = var.apic_url
  insecure    = true
}

data "vsphere_datacenter" "uktme-01" {
  name = var.vsphere_datacenter
}

data "vsphere_distributed_virtual_switch" "legacy-VDS" {
  name          = var.vsphere_dvs
  datacenter_id = data.vsphere_datacenter.uktme-01.id
}

resource "aci_tenant" "terraform_ten" {
  name = var.tenant_name
}

resource "aci_vrf" "vrf1" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = var.vrf_name
}

resource "aci_bridge_domain" "bd1" {
  tenant_dn          = aci_tenant.terraform_ten.id
  relation_fv_rs_ctx = aci_vrf.vrf1.name
  name               = var.bd_name
}

resource "aci_application_profile" "my_app" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = var.anp_name
}

data "aci_vmm_domain" "apic_vds" {
  name                = var.apic_vds_name
  provider_profile_dn = var.vmm_provider
}

resource "aci_application_epg" "net_1" {
  application_profile_dn  = aci_application_profile.my_app.id
  name                    = var.net_1_name
  relation_fv_rs_bd       = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att  = [data.aci_vmm_domain.apic_vds.id]
  pref_gr_memb            = "include"
  relation_fv_rs_path_att = ["topology/pod-1/paths-101/pathep-[${var.net_1_port_id}]"]
}

resource "aci_application_epg" "net_2" {
  application_profile_dn  = aci_application_profile.my_app.id
  name                    = var.net_2_name
  relation_fv_rs_bd       = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att  = [data.aci_vmm_domain.apic_vds.id]
  pref_gr_memb            = "include"
  relation_fv_rs_path_att = ["topology/pod-1/paths-101/pathep-[${var.net_2_port_id}]"]
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.uktme-01.id
}

resource "vsphere_virtual_machine" "vmus-1" {
  name             = "vmus-1"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  guest_id         = "ubuntu64Guest"
  network_interface {
    network_id = data.vsphere_network.vmm_net_1.id
  }
}

resource "vsphere_virtual_machine" "vmus-2" {
  name             = "vmus-2"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  guest_id         = "ubuntu64Guest"
  network_interface {
    network_id = data.vsphere_network.vmm_net_2.id
  }
}

data "vsphere_network" "vmm_net_1" {
  name          = "${format("%v|%v|%v", aci_tenant.terraform_ten.name, aci_application_profile.my_app.name, aci_application_epg.net_1.name)}"
  datacenter_id = data.vsphere_datacenter.uktme-01.id
}

data "vsphere_network" "vmm_net_2" {
  name          = "${format("%v|%v|%v", aci_tenant.terraform_ten.name, aci_application_profile.my_app.name, aci_application_epg.net_2.name)}"
  datacenter_id = data.vsphere_datacenter.uktme-01.id
}

resource "aci_subnet" "bd1_subnet" {
  bridge_domain_dn = aci_bridge_domain.bd1.id
  ip               = var.bd_subnet
}