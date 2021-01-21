#!/bin/bash

rootFsMount=/tmp/rootfs
outputFolder=/output

sourceContainerImageName=${1}
outputImageFilename=${2:-image.ext4}
imageFile=${outputFolder}/${outputImageFilename}


function prepareOutputFolder() {
    mkdir -p ${outputFolder}
    rm -rf ${imageFile}
}

function createEmptyImage() {
    echo "Creating rootfs image as ${imageFile}"

    # Truncate the image file to desired size
    truncate -s 5G ${imageFile}

    # Make image file
    mkfs.ext4 ${imageFile}
}

function mountImage() {
    #Create temp mount directory
    rm -rf ${rootFsMount}
    mkdir ${rootFsMount}

    # Mount the image as a loop device (Virtual drive kind of)
    echo "Mounting rootfs image to ${rootFsMount}"
    mount -o loop ${imageFile} ${rootFsMount}

}

function unmountImage() {
    umount ${rootFsMount}
}

function createRootFsWithScript() {
    echo "Downloading ubuntu root filesystem using debootstrap"
    debootstrap --include openssh-server,vim,nano,curl,cloud-init,netplan focal ${rootFsMount} http://archive.ubuntu.com/ubuntu/
}

function createRootFsFromContainer() {
    containerImage=$1
    echo "Building rootfs from docker image: ${containerImage}"
    containerId=$(docker create ${containerImage})
    docker export ${containerId} > rootfs.tar
    tar -C ${rootFsMount} -xf rootfs.tar
}

function runOnRootFs() {
    prepareScript=$1

    echo "Change to mounted rootfs using chroot"
    mount -t proc /proc ${rootFsMount}/proc/
    mount -t sysfs /sys ${rootFsMount}/sys/
    mount -o bind /dev ${rootFsMount}/dev/

    # Execute prepare server
    echo "Customizing image with prepare.sh"
    chroot ${rootFsMount} /bin/sh ${prepareScript}
    rm ${rootFsMount}${prepareScript}

    echo "Unmounting"
    umount ${rootFsMount}/dev
    umount ${rootFsMount}/proc
    umount ${rootFsMount}/sys
}

function checkImageFilesystem() {
    # Check image image file system
    e2fsck -y -f ${imageFile}
}

function getMinimumFilesizeForImage() {
    # Get minimum size of the image
    resize2fs -P ${imageFile}
}

function resizeImageToMinimumSize() {
    resize2fs -M ${imageFile} 
}

prepareOutputFolder
createEmptyImage
mountImage
createRootFsFromContainer ${sourceContainerImageName}
runOnRootFs /prepare.sh
unmountImage
resizeImageToMinimumSize
checkImageFilesystem