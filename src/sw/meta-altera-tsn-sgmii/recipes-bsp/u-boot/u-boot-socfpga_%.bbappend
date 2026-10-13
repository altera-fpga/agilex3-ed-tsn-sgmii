# Apply the SM TSN Config-3 U-Boot changes on top of the GSRD U-Boot.
#
# Moves the Si5332 OUT9 156.25 MHz setup into misc_init_r() so the board no
# longer has to be driven by hand from the U-Boot prompt before booting Linux.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:agilex3 = " \
            file://0001-UBoot-TSN-CFG3-Configure-Si5332-OUT9-to-156.25MHz.patch \
          "

