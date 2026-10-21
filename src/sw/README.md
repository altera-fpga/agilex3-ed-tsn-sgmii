# Yocto Project layer with Agilex™ 3 LTH - SGMII XCVR  1×1G TSN / Multi-rate Ethernet PHY System Example Design (TSN Config-3)

This directory contains a Yocto Project layer with the [Agilex™ 3 LTH - SGMII XCVR System Example](https://github.com/altera-fpga/agilex3-ed-tsn-sgmii.git). 
HPS + Multi-rate Ethernet PHY system example for SM TSN Config-3: one 1 GbE Ethernet datapath from the HPS EMAC through Multi-rate Ethernet PHY IP (Direct mode, GMII-8) to an external MGBASE-T PHY on the A3CW Rev-B TSN daughterboard (MxL86211).

## Meta Layers

* meta-intel-fpga - SoCFPGA BSP Core Layer
* meta-intel-fpga-refdes - SoCFPGA GSRD Customization Layer
* meta-altera-tsn-sgmii - SoCFPGA Customization Layer for Agilex™ 3 LTH - SGMII XCVR 1x1G TSN CONFIG-3 Solution (QUARTUS 26.1 - KERNEL 6.18.2)

Dependencies
* poky - Core Layer from Yocto Project
* meta-openembedded - Additional features (python, networking tools, etc) for GSRD

## Supported Targets:  

|    Board                                               |   OPN             |    Image                |
| ------------------------------------------------------ | ----------------- | ----------------------- | 
| Agilex™ 3 FPGA and SoC C-Series Development Kit        | DK-A3W135BM16AEA  |   gsrd [ qspi + emmc ]  |
| ------------------------------------------------------ | ----------------- | ----------------------- |


## SM TSN Config-3 GSRD Setup
1. Clone the repository.
`$ git clone https://github.com/altera-fpga/agilex3-ed-tsn-sgmii.git`
`$ cd applications.fpga.system-example-designs.agilex3-ed-tsn-config3`
`$ git checkout rel/26.1`
`$ cd src/sw`


3. Source the script to set component versions (Linux, U-Boot, ATF, Machine, Image):

|    Target                  |              Command                            |
| -------------------------- | ----------------------------------------------- |
| Agilex3                    |   `$ . agilex3-gsrd-build.sh`                   |
| -------------------------- | ----------------------------------------------- |


3. Run the build_setup to setup build environment
`$ build_setup`


4. OPTIONAL:  CUSTOM GHRD:

              a. Add custom GHRD design in the below path:
                   $WORKSPACE/src/sw/meta-altera-tsn-sgmii/recipes-bsp/ghrd/files/
                   NOTE: Update/Replace the GHRD rbf file with the same naming convention given below
                            For Agilex3:-
                                          agilex3_gsrd_ghrd.core.rbf
                                          agilex3_gsrd_ghrd.hps.rbf

              b. Update SRC_URL in the below recipe:
                    $WORKSPACE/src/sw/meta-altera-tsn-sgmii/recipes-bsp/ghrd/hw-ref-design.bbappend
                    Note: Update the SRC_URL using the example below
                           Include the required file with sha256sum
                        Example:-

			For Agilex3:-
			SRC_URI:agilex3 += "\
					file://agilex3_gsrd_ghrd.core.rbf;name=agilex3_gsrd_core \
					"
			SRC_URI[agilex3_gsrd_core.sha256sum] += "xxxxxx"


6. Perform Yocto bitbake to generate binaries
`$ bitbake_image`


7. Package binaries into build folder
`$ package`
