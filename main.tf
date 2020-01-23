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

resource "vsphere_distributed_port_group" "net_1" {
  name                            = var.net_1_name
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.legacy-VDS.id
}

resource "vsphere_distributed_port_group" "net_2" {
  name                            = var.net_2_name
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.legacy-VDS.id
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

resource "aci_subnet" "bd1_subnet" {
  bridge_domain_dn = aci_bridge_domain.bd1.id
  ip               = var.bd_subnet
}

resource "aci_application_profile" "app1" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = var.anp_name
}

data "aci_vmm_domain" "apic_vds" {
  name                = var.apic_vds_name
  provider_profile_dn = var.vmm_provider
}

resource "aci_application_epg" "epg1" {
  application_profile_dn = aci_application_profile.app1.id
  name                   = var.net_1_name
  relation_fv_rs_bd      = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att = [data.aci_vmm_domain.apic_vds.id]
  pref_gr_memb           = "include"
}

resource "aci_application_epg" "epg2" {
  application_profile_dn = aci_application_profile.app1.id
  name                   = var.net_2_name
  relation_fv_rs_bd      = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att = [data.aci_vmm_domain.apic_vds.id]
  pref_gr_memb           = "include"
}

