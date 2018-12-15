#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c provel-stretch-v4.14

debian_stretch_console="debian-9.6-provel-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

beaglebone_console="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

bb_blank_flasher_console="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

omap3_beagle_xm="--dtb omap3-beagle-xm --hostname BeagleBoard"
omap5_uevm="--dtb omap5-uevm --hostname omap5-uevm"
am57xx_beagle_x15="--dtb am57xx-beagle-x15 --hostname BeagleBoard-X15"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
        fi
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        else
                tar xf \${base_rootfs}.tar
        fi
}

archive_img () {
        #prevent xz warning for 'Cannot set the file group: Operation not permitted'
        sudo chown \${UID}:\${GROUPS} \${wfile}.img
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}


###console images: (also single partition)
base_rootfs="${debian_stretch_console}" ; blend="console" ; extract_base_rootfs

options="--img-4gb BBB-\${base_rootfs} ${beaglebone_console}" ; generate_img

###archive *.tar
base_rootfs="${debian_stretch_console}" ; blend="console" ; archive_base_rootfs

blend="console"
wfile="BBB-${debian_stretch_console}-4gb" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
