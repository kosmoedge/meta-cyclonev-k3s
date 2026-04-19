# Append kernel configurations for k3s support on Cyclone V
# Adds cgroups, namespaces, networking, and container runtime requirements

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add kernel configuration fragment for k3s requirements
SRC_URI:append = " file://fragment.cfg"

# Explicitly merge the fragment into kernel .config
# Required because linux-socfpga does not use kernel-yocto class
do_configure:append() {
    if [ -f "${WORKDIR}/fragment.cfg" ] && [ -f "${B}/.config" ]; then
        if [ -f "${S}/scripts/kconfig/merge_config.sh" ]; then
            ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${WORKDIR}/fragment.cfg
        else
            cat ${WORKDIR}/fragment.cfg >> ${B}/.config
        fi
    fi
}
