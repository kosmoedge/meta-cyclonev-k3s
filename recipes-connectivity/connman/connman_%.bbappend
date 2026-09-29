# Stop ConnMan from managing k3s/CNI interfaces (see files/main.conf)

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://main.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/connman
    install -m 0644 ${WORKDIR}/main.conf ${D}${sysconfdir}/connman/main.conf
}

FILES:${PN} += "${sysconfdir}/connman/main.conf"
CONFFILES:${PN} += "${sysconfdir}/connman/main.conf"
