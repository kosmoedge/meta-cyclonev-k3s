# meta-cyclonev-k3s

A Yocto/OpenEmbedded layer that provides kernel and system configurations required to run k3s on Intel Cyclone V SoC FPGA development kits. Built on top of the Intel GSRD (Kirkstone branch).

## Description

**meta-cyclonev-k3s** extends the Intel Cyclone V Golden System Reference Design (GSRD) with support for k3s, a lightweight Kubernetes distribution optimized for edge and IoT deployments. It provides the necessary kernel configurations (cgroups, namespaces, networking, iptables/IPVS) and system modifications to enable container orchestration on resource-constrained FPGA-based SoC hardware.

## Dependencies

This layer depends on:

| Layer | URI |
|-------|-----|
| openembedded-core | https://git.openembedded.org/openembedded-core |
| meta-intel-fpga | https://git.yoctoproject.org/meta-intel-fpga |

## Compatibility

- **Yocto Release:** Kirkstone (4.0)
- **Target Machine:** cyclone5

## Layer Contents

### Kernel Configuration (`recipes-kernel/linux/`)

Adds a kernel configuration fragment (`fragment.cfg`) that enables:

- **Cgroups:** Memory, CPU, PID, device, freezer controllers
- **Namespaces:** User namespaces, PID namespaces
- **Networking:** Bridge, VETH, VXLAN, netfilter, iptables, IPVS
- **Filesystems:** OverlayFS, ext4 ACL/security
- **Crypto:** Required cryptographic modules for secure communication

### System Configuration (`recipes-core/base-files/`)

Modifies `/etc/fstab` to mount cgroup filesystems at boot:

- `cgroup2` (unified hierarchy)
- `cgroup` (legacy v1 support)

## Usage

### Adding the Layer

```bash
cd /path/to/your/build
bitbake-layers add-layer /path/to/meta-cyclonev-k3s
```

### Building

After adding the layer, build your image as usual:

```bash
bitbake gsrd-console-image
```

### Recommended `local.conf` Additions

For full k3s support, add the following to your `local.conf`:

```bash
CORE_IMAGE_EXTRA_INSTALL += "packagegroup-k3s-host packagegroup-k3s-node kernel-modules openssh ca-certificates"
IMAGE_ROOTFS_EXTRA_SPACE = "2097152"
DISTRO_FEATURES:append = " seccomp security virtualization k3s"
```

## License

This layer is provided under the MIT License. See [COPYING.MIT](COPYING.MIT) for details.

## Maintainers

- Nikos Fotiadis

