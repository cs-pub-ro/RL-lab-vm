packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.6"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "rl-lab-vm"
  vm_pause = 0
  vm_debug = 0
  vm_noinstall = 0
  qemu_unmap = false
  qemu_ssh_forward = 20022
  source_image = "./path/to/ubuntu-22-base.qcow2"
  source_checksum = "none"
  use_backing_file = true
  output_directory = "/tmp/packer-out"
  ssh_username = "student"
  ssh_password = "student"
}

source "qemu" "rl-lab-vm" {
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
  disk_discard   = (var.qemu_unmap ? "unmap" : "")
  disk_detect_zeroes = (var.qemu_unmap ? "unmap" : "")
  // skip_compaction = true
  
  // ISO & Output details
  iso_url           = var.source_image
  iso_checksum      = var.source_checksum
  disk_image        = var.use_backing_file
  use_backing_file  = var.use_backing_file
  output_directory  = var.output_directory

  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_timeout       = "30m"
  host_port_min     = var.qemu_ssh_forward
  host_port_max     = var.qemu_ssh_forward

  shutdown_command  = "sudo /sbin/shutdown -h now"
}

build {
  sources = ["sources.qemu.rl-lab-vm"]

  provisioner "shell" {
    inline = [
      "rm -rf /home/student/install",
      "mkdir -p /home/student/install /home/student/install/thirdparty",
      "chown student:student /home/student/install -R"
    ]
    execute_command = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
    environment_vars = [
      "VM_DEBUG=${var.vm_debug}"
    ]
  }
  provisioner "file" {
    source = "scripts/"
    destination = "/home/student/install"
  }
  provisioner "file" {
    source = "../thirdparty/"
    destination = "/home/student/install/thirdparty"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /home/student/install/install-pre.sh",
      "/home/student/install/install-pre.sh"
    ]
    expect_disconnect = true
    execute_command = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
    environment_vars = [
      "VM_DEBUG=${var.vm_debug}",
      "VM_NOINSTALL=${var.vm_noinstall}"
    ]
  }

  provisioner "shell" {
    inline = [
      "chmod +x /home/student/install/install.sh",
      "/home/student/install/install.sh"
    ]
    execute_command = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
    environment_vars = [
      "VM_DEBUG=${var.vm_debug}",
      "VM_NOINSTALL=${var.vm_noinstall}"
    ]
  }

  # optionally, when PAUSE=1, keep the qemu VM open!
  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

