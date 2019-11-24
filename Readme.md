# RL Lab virtual machine source code

This repository contains the RL Lab VM generation scripts.
The process is automated using `qemu` and Packer (check the requirements below).

Requirements:
 - a modern Linux system with [packer](https://packer.io/), [qemu+kvm](https://qemu.org/);
 - basic build tools (make);
 - `python3` and `python3-yaml`;

## Preparation

Download and save a [Ubuntu 18.04 Server alternative
install](http://cdimage.ubuntu.com/releases/18.04.3/release/) .iso image.
WARNING: **DO NOT** use the `live-server` ISO (it doesn't work for unattended
install purposes)!

Copy `local.sample.mk` as `local.mk` and edit it to point to the downloaded
Ubuntu Server `.iso` on your disk. You might also want to change `TMP_DIR` somewhere
with 10GB free space and/or a faster drive (SSD recommended :P).

You might also want to ensure that packer and qemu are properly installed and
configured.

## Building the VM

The following Makefile goals are available (the build process is usually in this
order):

- `base`: builds a base Ubuntu 18.04 install (required for the VM image);
- `rl_scripts`: builds the Lab VM with all required scripts and config;
- `rl_scripts_edit`: easily edit an already build Lab VM (uses the previous
  image as backing snapshot);
- `rl_scripts_commit`: commits the edited VM back to its base;
- `rl_cloud`: builds (from `rl_scripts` VM) the cloud VM, cleaned up and ready
  for cloud usage (e.g., AWS, OpenStack).
- `rl_cloud_test`: starts up a test VM using the previously generated cloud
  image.
- `rl_ssh`: SSH-es into a running Packer VM (use with the `_edit` target
  to test it);

If packer complains about the output file existing, you must either manually
delete the generated VM from inside `TMP_DIR`, or set the `DELETE=1` makefile
variable (but be careful):
```sh
make DELETE=1 rl_scripts_edit
```

If you want to keep the install scripts at the end of the provisioning phase,
set the `DEBUG` variable:
```sh
make DEBUG=1 rl_scripts_edit
```

## TODO

Still TODO: image conversion and project generation for VMWare / VirtualBox
/ LibVirt / etc?.

