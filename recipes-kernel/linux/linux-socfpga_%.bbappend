# Append kernel configurations for k3s support on Cyclone V
# Adds cgroups, namespaces, networking, and container runtime requirements

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add kernel configuration fragment for k3s requirements
# kernel-yocto class automatically merges .cfg files from SRC_URI
SRC_URI:append = " file://fragment.cfg"
