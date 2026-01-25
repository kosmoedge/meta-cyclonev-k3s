# Append kernel configurations for k3s support on Cyclone V
# Adds cgroups, namespaces, networking, and container runtime requirements

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add kernel configuration fragment for k3s requirements
SRC_URI += "file://fragment.cfg"

