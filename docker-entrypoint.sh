#!/bin/bash
# Docker entrypoint of the docker image of the slurm and openssh docker container 
#
# Copyright (C) 2025  Manuel G. Marciani
# BSC-CNS - Earth Sciences

dbus-daemon --config-file=/usr/share/dbus-1/session.conf --print-address --fork
sleep 1
/usr/bin/mysqld_safe &
# TODO uncrappyfy this 
sleep 1
/usr/sbin/sshd & 
/usr/sbin/slurmdbd & 
sleep 1
/usr/sbin/slurmd -N slurmctld & 
/usr/sbin/slurmctld -D

