# Append kernel configurations and DT fixes for k3s + FPGA support on Cyclone V

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://fragment.cfg \
    file://fix-fpga-bridges.dtsi \
"

do_configure:append() {
    # Merge kernel config fragment (k3s + FPGA modules)
    if [ -f "${WORKDIR}/fragment.cfg" ] && [ -f "${B}/.config" ]; then
        if [ -f "${S}/scripts/kconfig/merge_config.sh" ]; then
            ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${WORKDIR}/fragment.cfg
        else
            cat ${WORKDIR}/fragment.cfg >> ${B}/.config
        fi
    fi

    # Inject FPGA bridge fix into the Cyclone V device tree.
    # The upstream DTS has all bridges disabled and base_fpga_region
    # has no fpga-bridges property, which causes crashes during
    # runtime FPGA programming via DT overlay.
    if [ -f "${WORKDIR}/fix-fpga-bridges.dtsi" ]; then
        DTS_DIR="${S}/arch/${ARCH}/boot/dts"
        SOCDK_DTS="${DTS_DIR}/socfpga_cyclone5_socdk.dts"
        if [ -f "${SOCDK_DTS}" ]; then
            cp "${WORKDIR}/fix-fpga-bridges.dtsi" "${DTS_DIR}/"
            if ! grep -q 'fix-fpga-bridges.dtsi' "${SOCDK_DTS}"; then
                sed -i '/#include "socfpga_cyclone5.dtsi"/a #include "fix-fpga-bridges.dtsi"' "${SOCDK_DTS}"
                bbnote "Injected fix-fpga-bridges.dtsi into socfpga_cyclone5_socdk.dts"
            fi
        else
            bbwarn "socfpga_cyclone5_socdk.dts not found at ${SOCDK_DTS}"
        fi
    fi
}
