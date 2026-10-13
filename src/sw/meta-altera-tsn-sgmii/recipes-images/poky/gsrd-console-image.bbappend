# Agilex 5 GSRD machine configs install packagegroup-tsn-essential into
# gsrd-console-image, and that package group pulls in tsn-ref-sw, which
# is what creates /home/root/tsn. agilex3-gsrd.conf has no equivalent
# line, so the example-design layer adds it for this image only.
IMAGE_INSTALL:append:agilex3 = " packagegroup-tsn-essential"
