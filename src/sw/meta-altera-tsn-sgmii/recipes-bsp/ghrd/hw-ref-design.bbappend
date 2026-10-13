SUMMARY = "Intel SoCFPGA Development Kit Linux Kernel layer for TSN Config-3(TSN SGMII) Example Designs"
DESCRIPTION = "Linux Kernel addons for TSN Config-3(TSN SGMII) Example Designs on Intel SoCFPGA Development Kits"
SECTION = "bsp"

LICENSE = "MIT & GPL-2.0-only"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

ARM64_GHRD_HPS_RBF = "ghrd.hps.rbf"
ARM64_GHRD_CORE_RBF = "ghrd.core.rbf"

SRC_URI:agilex3 = "\
			file://agilex3_gsrd_${ARM64_GHRD_CORE_RBF};name=agilex3_gsrd_core \
			file://agilex3_gsrd_${ARM64_GHRD_HPS_RBF};name=agilex3_gsrd_hps \
			"

SRC_URI[agilex3_gsrd_core.sha256sum] = "27347acadb55e589adefa3d43aa61148eb8f14402b1c8cd3fe1ebf7f4aa1d9f9"
SRC_URI[agilex3_gsrd_hps.sha256sum] = "ad0b142a8b8cf5f7f7fb7100e9bbe18ae70fa28f240ccb7d31d78028c5587466"

do_install() {
	if [ "${MACHINE}" = "agilex3" ]; then
                install -D -m 0644 ${WORKDIR}/${MACHINE}_${IMAGE_TYPE}_${ARM64_GHRD_CORE_RBF} ${D}/boot/${ARM64_GHRD_CORE_RBF}
	fi
}

do_deploy() {
        if [ "${MACHINE}" = "agilex3" ]; then
                install -D -m 0644 ${WORKDIR}/${MACHINE}_${IMAGE_TYPE}_${ARM64_GHRD_CORE_RBF} ${DEPLOYDIR}/${MACHINE}_${IMAGE_TYPE}_ghrd/${ARM64_GHRD_CORE_RBF}
                install -D -m 0644 ${WORKDIR}/${MACHINE}_${IMAGE_TYPE}_${ARM64_GHRD_HPS_RBF} ${DEPLOYDIR}/${MACHINE}_${IMAGE_TYPE}_ghrd/${ARM64_GHRD_HPS_RBF}
        fi

}

