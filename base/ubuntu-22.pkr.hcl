packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.6"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "ubuntu-22-base"
  vm_pause = 0
  vm_debug = 0
  source_image = "http://cdimage.ubuntu.com/releases/22.04.1/release/ubuntu-22.04.1-live-server-arm64.iso"
  source_checksum = "none"
  output_directory = "/tmp/packer-out"
  boot_wait = "5s"
  ssh_username = "student"
  ssh_password = "student"
}

source "qemu" "ubuntu-22-base" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Virtual Hardware Specs
  memory         = 1024
  cpus           = 2
  disk_size      = 8000
  disk_interface = "virtio"
  net_device     = "virtio-net"
  // disk usage optimizations (unmap zeroes as free space)
  disk_discard   = "unmap"
  disk_detect_zeroes = "unmap"
  // skip_compaction = true
  
  // ISO & Output details
  iso_url           = var.source_image
  iso_checksum      = var.source_checksum
  output_directory  = var.output_directory
  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_timeout       = "30m"

  http_directory    = "http"
  boot_wait = var.boot_wait
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

build {
  sources = ["sources.qemu.ubuntu-22-base"]

  provisioner "shell" {
    scripts = [
      "scripts/00-base.sh",
      "scripts/90-cleanup.sh",
    ]
    execute_command = "{{.Vars}} sudo -E -S bash -ex '{{.Path}}'"
    environment_vars = [
      "VM_DEBUG=${var.vm_debug}"
    ]
  }

  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

