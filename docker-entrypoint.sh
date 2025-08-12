#!/bin/bash
# Docker entrypoint of the docker image of the slurm and openssh docker container 
#
# Copyright (C) 2025  Manuel G. Marciani
# BSC-CNS - Earth Sciences

# Slurm's cgroup v2 plugin setup, since we are ignoring Systemd by passing
# the flag IgnoreSystemd=yes in the cgroup.conf file 
# it needs to be in the entrypoint, otherwise docker will throw and error
# on read only file system. We need to have the run's --privileged flag 
# so it works.
mkdir -p /sys/fs/cgroup/system.slice

/usr/bin/mysqld_safe &
# manu: TODO uncrappyfy this 
sleep 5
/usr/sbin/sshd & 
/usr/sbin/slurmdbd & 
# manu: TODO uncrappyfy this 
sleep 5
/usr/sbin/slurmd -N slurmctld & 
/usr/sbin/slurmctld -D

