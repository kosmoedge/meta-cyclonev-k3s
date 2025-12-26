# Append cgroup mount entries to /etc/fstab for k3s support
# Required for container runtime cgroup management

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Add cgroup2 entry to /etc/fstab (unified cgroup hierarchy)
    echo 'cgroup2 /sys/fs/cgroup cgroup2 rw,nosuid,nodev,noexec,relatime 0 0' >> ${D}${sysconfdir}/fstab
    # Add cgroup v1 entry for legacy support
    echo 'cgroup /sys/fs/cgroup cgroup defaults 0 0' >> ${D}${sysconfdir}/fstab
}

