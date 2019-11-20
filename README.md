# Intro

Building an arm64 version of anything takes a long time on the Jetson Nano. OpenCV is bad, and Tensorflow is even worse.

Using QEMU inside a chroot environment on a PC is one way around this, but it's very slow.

A better approach is to use an AWS arm64 instance to build things inside of. You get the speed (16 cores, lots of RAM, large SSD), and the build environment and product are the same as on a Jetson Nano.

The general strategy is to create an "a1" instance on AWS (only available in the US-East Ohio region), mount the Jetson Nano dev kit image into a chroot environment, and then build from inside of there.

# Usage

./build_opencv_on_aws.sh go <ip address of your AWS instance>

* You must have passwordless ssh access to the server. It assumes that the username is "ec2-user". Change that in the script if that's not the case.
* When the process is complete, the build products will be in ~/compiled_debs on the server.


