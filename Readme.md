# RL Lab virtual machine source code

This repository contains the RL (Networking 101) Lab VM generation scripts.
The process is automated using `qemu` and Packer (check the requirements below).

Requirements:
 - a modern Linux system;
 - basic build tools (make);
 - [Hashicorp's Packer](https://packer.io/);
 - [qemu+kvm](https://qemu.org/);

## Preparation

First, update submodules:
```sh
git submodule init
git submodule update
```

Download and save a [Ubuntu 22.04 Live Server
install](https://ubuntu.com/download/server) iso image.

Copy `config.sample.mk` as `config.local.mk` and edit it to point to the downloaded
Ubuntu Server `.iso` on your disk. You might also want to change `BUILD_DIR`
somewhere with 10GB free space and/or a faster drive (SSD recommended :P).

You might also want to ensure that packer and qemu are properly installed and
configured.

## Building the VM

The following Makefile goals are available (the build process is usually in this
order):

- `base`: builds a base Ubuntu LTS install (required for the VM image);
- `labvm`: builds the Lab VM with all required scripts and config;
- `cloudvm`: builds (from `labvm` VM) the cloud VM, cleaned up and ready
  for cloud usage (e.g., AWS, OpenStack).
- `labvm_edit`: easily edit an already build Lab VM (uses the previous
  image as backing snapshot);
- `labvm_commit`: commits the edited VM back to its backing base;
- `[*]_clean`: removes the generated image(s);
- `ssh`: SSH-es into a running Packer VM;

If packer complains about the output file existing, you must either manually
delete the generated VM from inside `BUILD_DIR`, or set the `DELETE=1` makefile
variable (but be careful):
```sh
make DELETE=1 labvm
# labvm_edit does this automatically:
make labvm
```

If you want to keep the install scripts at the end of the provisioning phase,
set the `DEBUG` variable. Also check out `PAUSE` (it pauses packer,
letting you inspect the VM inside qemu):
```sh
make PAUSE=1 DEBUG=1 labvm_edit
```

## TODO

Still TODO: image conversion and project generation for VMWare / VirtualBox
/ LibVirt XML / etc?.

