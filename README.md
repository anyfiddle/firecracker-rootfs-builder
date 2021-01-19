# Firecracker RootFS builder

Container to build custom RootFS drives for booting Firecracker microVMs.

### Build Firecracker RootFS from existing docker container

If `<DOCKER_IMAGE_NAME>` is the docker image in registry, this will pull the image and convert it into a RootFS ext4 drive

```sh
docker run \
    -v {pwd}/output:/output \
    anyfiddle/firecracker-rootfs-builder <DOCKER_IMAGE_NAME>

```

The `image.ext4` will be created in `./output` folder which can be used as the root drive for starting Firecracker VMs

### Build Firecracker RootFS from tar files

TBD
