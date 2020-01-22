#!/bin/bash

terraform import vsphere_distributed_virtual_switch.legacy-VDS /uktme-01/network/legacy-VDS
terraform import vsphere_distributed_port_group.net_1 /uktme-01/network/net_1
terraform import vsphere_distributed_port_group.net_2 /uktme-01/network/net_2