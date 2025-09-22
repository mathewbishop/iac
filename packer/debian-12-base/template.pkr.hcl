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

variable "vm_id" {
  type = number
}

variable "node" {
  type = string
}

variable "storage_pool_name" {
  type = string
} 


packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian-12" {
	proxmox_url = var.proxmox_url
	insecure_skip_tls_verify = true
	username = var.proxmox_username
	password = var.proxmox_password
	node = var.node
	task_timeout = "10m"
	vm_id = var.vm_id
	memory = 2048
	cores = 1
	qemu_agent = true
	
	ssh_username = var.ssh_username
	ssh_password = var.ssh_password
	ssh_timeout = "10m"

	cloud_init = true
	cloud_init_storage_pool = var.storage_pool_name

	template_name = "debian12-base"

	http_directory = "http"

	boot_iso {
	  type = "scsi"
    iso_file = "local:iso/debian-12.11.0-amd64-netinst.iso"
	  iso_checksum = "sha256:30ca12a15cae6a1033e03ad59eb7f66a6d5a258dcf27acd115c2bd42d22640e8"
	  iso_storage_pool = "local"
	  unmount = true
	}

	boot_wait = "15s"
    boot_command = [
  	  "<esc>",
  	  "<wait>",
	  "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
	  "<enter>"
 	]	

	network_adapters {
		model = "virtio"
		bridge = "vmbr0"
	}

	disks {
		type = "scsi"
		disk_size = "16G"
		storage_pool = var.storage_pool_name
	}
}

build {
  sources = [
    "source.proxmox-iso.debian-12"
  ]

  provisioner "file" {
	source = "files/bashrc"
	destination = "/home/debian/rootbashrc"
  }

  provisioner "shell" {
	inline = [
		"sudo DEBIAN_FRONTEND=noninteractive apt-get update",
		"sudo DEBIAN_FRONTEND=noninteractive apt-get install -y cloud-init vim",
		"sudo rm /root/.bashrc",
		"sudo mv /home/debian/rootbashrc /root/",
		"sudo mv /root/rootbashrc /root/.bashrc"
	]
  }
}
