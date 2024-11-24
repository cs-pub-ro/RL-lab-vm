packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "labvm"
  vm_pause = 0
  vm_debug = 0
  vm_noinstall = 0
  rl_authorized_keys = ""
  qemu_unmap = false
  qemu_ssh_forward = 20022
  disk_size = 8192
  source_image = "./path/to/ubuntu-22-base.qcow2"
  source_checksum = "none"
  use_backing_file = true
  output_directory = "/tmp/packer-out"
  ssh_username = "student"
  ssh_password = "student"
}

locals {
  install_dir = "/home/student/install"
  envs = [
    "VM_DEBUG=${var.vm_debug}",
    "VM_NOINSTALL=${var.vm_noinstall}",
    "INSTALL_DIR=${local.install_dir}",
    "RL_AUTHORIZED_KEYS=${basename(var.rl_authorized_keys)}"
  ]
  sudo = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
}

source "qemu" "labvm" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Virtual Hardware Specs
  memory         = 2048
  cpus           = 2
  disk_size      = var.disk_size
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
  sources = ["sources.qemu.labvm"]

  provisioner "shell" {
    inline = [
      "rm -rf $INSTALL_DIR && mkdir -p $INSTALL_DIR/thirdparty ",
      "chown student:student $INSTALL_DIR -R"
    ]
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "file" {
    sources = concat(
      ["scripts/", "../thirdparty"],
      (var.rl_authorized_keys == "" ? [] : ["${var.rl_authorized_keys}"]),
    )
    destination = "${local.install_dir}/"
  }

  provisioner "shell" {
    inline = [
      "[ ! -f $INSTALL_DIR/install-base.sh ] || bash $INSTALL_DIR/install-base.sh"
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }

  provisioner "shell" {
    inline = [
      "chmod +x $INSTALL_DIR/install.sh && $INSTALL_DIR/install.sh"
    ]
    execute_command = local.sudo
    environment_vars = local.envs
  }

  # optionally, when PAUSE=1, keep the qemu VM open!
  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

