# NOTE: As of Aug 23 2025, this is only tested with DVD ISO from Rocky

variable "proxmox_url" {
	type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "ssh_username" {
	type = string
}

variable "ssh_password" {
	type = string
	sensitive = true
}

variable "template_name" {
    type = string
}

variable "iso" {
    type = string
}

variable "iso_checksum" {
    type = string
}


packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "rocky" {
	proxmox_url = var.proxmox_url
	insecure_skip_tls_verify = true
	username = var.proxmox_username
	password = var.proxmox_password
	node = "pmx"
	task_timeout = "10m"
	vm_id = 9005
	memory = 2048
    cpu_type = "x86-64-v2-AES"
	cores = 1
	qemu_agent = true
	
	ssh_username = var.ssh_username
	ssh_password = var.ssh_password
	ssh_timeout = "10m"

	cloud_init = true
	cloud_init_storage_pool = "local-lvm"

	template_name = var.template_name

	http_directory = "http"

	boot_iso {
	  # Had to use ide disk. dracut was failing to find the ISO. Suspected reason: no drivers for virtio scsi in initramfs in Rocky installer
	  type = "ide"
	  iso_file = var.iso
	  iso_checksum = var.iso_checksum
	  iso_storage_pool = "local"
	  unmount = true
	}

	boot_wait = "10s"
    boot_command = [
     "<up>",
     "<wait1>",
     "<tab>",
	 "<wait1>",
	 "<bs><bs><bs><bs><bs><bs>",
     " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
	 " inst.text",
	 "<wait1>",
     "<enter><enter>",
 	]	

	network_adapters {
		model = "virtio"
		bridge = "vmbr0"
	}

	disks {
		# Used ide disk b/c failing with scsi. Installer could not find /sda when using scsi. Suspected reason similar to boot disk, missing drivers
		type = "ide"
		disk_size = "8G"
		storage_pool = "local-lvm"
	}
}

build {
  sources = [
    "source.proxmox-iso.rocky"
  ]
}
