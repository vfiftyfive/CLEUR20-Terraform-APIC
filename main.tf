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
variable bd_subnet {}
variable vmm_domain {}

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
  vlan_id                         = var.net_1_vlan
}

resource "vsphere_distributed_port_group" "net_2" {
  name                            = var.net_2_name
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.legacy-VDS.id
  vlan_id                         = var.net_2_vlan
}

resource "aci_tenant" "terraform_ten" {
  name = "terraform_ten"
}

resource "aci_vrf" "vrf1" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = "vrf1"
}

resource "aci_bridge_domain" "bd1" {
  tenant_dn          = aci_tenant.terraform_ten.id
  relation_fv_rs_ctx = aci_vrf.vrf1.name
  name               = "bd1"
}

resource "aci_subnet" "bd1_subnet" {
  bridge_domain_dn = aci_bridge_domain.bd1.id
  ip               = var.bd_subnet
}

resource "aci_application_profile" "app1" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = "app1"
}

resource "aci_application_epg" "epg1" {
  application_profile_dn = aci_application_profile.app1.id
  name                   = var.net_1_name
  relation_fv_rs_bd      = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att = [var.vmm_domain]
  relation_fv_rs_cons    = [aci_contract.contract_epg1_epg2.name]
}

resource "aci_application_epg" "epg2" {
  application_profile_dn = aci_application_profile.app1.id
  name                   = var.net_2_name
  relation_fv_rs_bd      = aci_bridge_domain.bd1.name
  relation_fv_rs_dom_att = [var.vmm_domain]
  relation_fv_rs_prov    = [aci_contract.contract_epg1_epg2.name]
}

resource "aci_contract" "contract_epg1_epg2" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = "Web"
}

resource "aci_contract_subject" "Web_subject1" {
  contract_dn                  = aci_contract.contract_epg1_epg2.id
  name                         = "Subject"
  relation_vz_rs_subj_filt_att = [aci_filter.allow_https.name]
}

resource "aci_filter" "allow_https" {
  tenant_dn = aci_tenant.terraform_ten.id
  name      = "allow_https"
}

resource "aci_filter_entry" "https" {
  name        = "https"
  filter_dn   = aci_filter.allow_https.id
  ether_t     = "ip"
  prot        = "tcp"
  d_from_port = "https"
  d_to_port   = "https"
  stateful    = "yes"
}