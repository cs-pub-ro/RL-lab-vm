# RL Lab virtual machine source code

This repository contains the RL Lab VM generation scripts.
The process is automated using `qemu` and Packer (check the requirements below).

Requirements:
 - a modern Linux system with [packer](https://packer.io/), [qemu+kvm](https://qemu.org/);
 - basic build tools (make);
 - `python3` and `python3-yaml`;

## Preparation

Download and save a [Ubuntu 18.04 Server alternative
install](http://cdimage.ubuntu.com/releases/18.04.5/release/) .iso image.
WARNING: **DO NOT** use the `live-server` ISO (it doesn't work for unattended
install purposes)!

Copy `local.sample.mk` as `local.mk` and edit it to point to the downloaded
Ubuntu Server `.iso` on your disk. You might also want to change `TMP_DIR`
somewhere with 10GB free space and/or a faster drive (SSD recommended :P).

You might also want to ensure that packer and qemu are properly installed and
configured.

## Building the VM

The following Makefile goals are available (the build process is usually in this
order):

- `base`: builds a base Ubuntu 18.04 install (required for the VM image);
- `labvm`: builds the Lab VM with all required scripts and config;
- `labvm_edit`: easily edit an already build Lab VM (uses the previous
  image as backing snapshot);
- `labvm_commit`: commits the edited VM back to its `labvm` base;
- `cloudvm`: builds (from `labvm` VM) the cloud VM, cleaned up and ready
  for cloud usage (e.g., AWS, OpenStack).
- `ssh`: SSH-es into a running Packer VM;

If packer complains about the output file existing, you must either manually
delete the generated VM from inside `TMP_DIR`, or set the `DELETE=1` makefile
variable (but be careful):
```sh
make DELETE=1 labvm_edit
```

If you want to keep the install scripts at the end of the provisioning phase,
set the `DEBUG` variable. Also check out `PAUSE` (it pauses packer,
letting you inspect the VM inside qemu):
```sh
make PAUSE=1 DEBUG=1 labvm_edit
```

## TODO

Still TODO: image conversion and project generation for VMWare / VirtualBox
/ LibVirt / etc?.

