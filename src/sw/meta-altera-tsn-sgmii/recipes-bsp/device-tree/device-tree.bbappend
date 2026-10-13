SUMMARY = "Intel SoCFPGA Development Kit Linux Kernel layer for TSN Config-3(TSN SGMII) Example Designs"
DESCRIPTION = "Linux Kernel addons for TSN Config-3(TSN SGMII) Example Designs on Intel SoCFPGA Development Kits"
SECTION = "bsp"

LICENSE = "MIT & GPL-2.0-only"

do_configure:append() {
        # TSN CONFIG-3: device-tree MACHINE is ${MACHINE} and IMAGE_TYPE is ${IMAGE_TYPE}

	if [ "${MACHINE}" = "agilex3" ]; then
		# GSRD DTB Generation
		cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex3_socdk_tsn_cfg3.dts ${WORKDIR}/socfpga_agilex3_socdk_tsn_cfg3.dts
	fi
}

