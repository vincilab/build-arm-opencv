#!/bin/bash
#
# This script will build opencv on AWS. It MUST be an "a1" (arm64) instance in the
# US East (Ohio) region. It should have about 100GB of space on its volume, and
# you must have an ssh key in your ssh-agent that will allow you to get on the
# instance as the "ec2-user" user.
set -e

DIR=$(realpath $(dirname $0))

function usage {
	echo "$0 go <aws host ip>"
	exit 1
}

# This might be setup as an EXIT trap to unmount stuff.
function unmount_stuff {
	sudo umount /mnt

	if [ -n "$chroot_dir" ]; then
	    sudo umount $chroot_dir/proc
	    sudo umount $chroot_dir/sys
	    sudo umount $chroot_dir/dev
	    sudo umount $chroot_dir/run
	fi
}

aws_user=ec2-user

command=$1

# If they passed the "go" command, then just copy this file up to the remote host and
# run it there with "go_aws"
if [ "$command" == "go" ]; then
	aws_host=$2
	[ "$aws_host" == "" ] && usage
	scp $0 $aws_user@$aws_host:
	scp $(dirname $0)/build_opencv.sh $aws_user@$aws_host:
	ssh $aws_user@$aws_host ./$(basename $0) go_aws
	
	echo "Succeeded! You can copy the .deb files from $aws_user@$aws_host:compiled_debs"
	echo "Remember to terminate your AWS instance when you're done!"
	exit 0
fi

# If we fall through to here, then we should be running on the AWS host.
if [ "$command" == "go_aws" ]; then
	echo "Downloading the Jetson image"	
	curl -Ls -w %{url_effective} http://developer.nvidia.com/embedded/dlc/jetson-nano-dev-kit-sd-card-image > image.zip

	echo "Unpacking the Jetson image"	
	unzip image.zip

	# Mount the image and copy everything out of it.
	echo "Mounting the Jetson image and copying it to local folders"
	trap unmount_stuff EXIT
	sudo mount -o loop,offset=12582912 jetson-nano-sd-r32.1-2019-03-18.img /mnt
	
	# Get rid of any previous rootfs-nano directory.
	[ -e "rootfs-nano" ] && sudo rm -rf rootfs-nano
	mkdir rootfs-nano

	pushd rootfs-nano
		sudo cp /mnt/* . -rapf
		sudo mv etc/resolv.conf etc/resolv.conf.old
		sudo cp /etc/resolv.conf etc
		
		# Copy the build_opencv.sh script into the chroot.
		sudo cp $DIR/build_opencv.sh root/

		chroot_dir=$(pwd)
	popd

	# Mount the opencv environment, and make sure we'll unmount it on exit.
    sudo mount -t proc /proc $chroot_dir/proc
    sudo mount -t sysfs /sys $chroot_dir/sys
    sudo mount -o bind /dev $chroot_dir/dev
    sudo mount -o bind /run $chroot_dir/run

	# Now run the build_opencv script in the chroot
    echo "Running build_opencv.sh in the chroot"
    sudo chroot $chroot_dir /bin/bash -c "cd /root && ./build_opencv.sh"
	
    # Copy the debs over.
    echo "Copying compiled debs..."
    mkdir /home/$aws_user/compiled_debs
    sudo /bin/bash -c "cp $chroot_dir/root/opencv/release/*.deb /home/$aws_user/compiled_debs"
    sudo chown $aws_user /home/$aws_user/compiled_debs/*.deb

	echo "go_aws succeeded!"
	exit 0
fi

usage

