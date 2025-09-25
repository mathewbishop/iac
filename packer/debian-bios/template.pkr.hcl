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
  description = "ID you would like to set for the completed VM template"
}

variable "node" {
  type = string
  description = "The proxmox node name"
}

variable "template_name" {
  type = string
  description = "The name you would like to set for the completed VM template"
}

variable "disk_storage_pool" {
  type = string
  description = "This storage pool will be used for the VM disk, the cloud init drive, and the efi"
} 

variable "iso_file" {
  type = string
  description = "Full location of the iso file. Example: local:iso/debian-12.11.10-amd64-netinst.iso"
}

variable "iso_checksum" {
  type = string
}

variable "iso_storage_pool" {
  type = string
  description = "Storage pool for the ISO file, usually 'local'"
}

variable "preseed_file" {
  type = string
  description = "Name of the preseed file you want to use from the http/ directory"
}


packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "debian" {
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
	cloud_init_storage_pool = var.disk_storage_pool

	template_name = var.template_name

	http_directory = "http"

	boot_iso {
	  type = "ide"
    iso_file = var.iso_file
	  iso_checksum = var.iso_checksum
	  iso_storage_pool = var.iso_storage_pool
	  unmount = true
	}

	boot_wait = "15s"
  boot_command = [
  	  "<esc>",
  	  "<wait>",
	    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed_file}",
	    "<enter>"
 	]	

	network_adapters {
		model = "virtio"
		bridge = "vmbr0"
	}

	disks {
		type = "scsi"
		disk_size = "16G"
		storage_pool = var.disk_storage_pool
	}

}

build {
  sources = [
    "source.proxmox-iso.debian"
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
