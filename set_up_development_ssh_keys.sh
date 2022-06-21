#!/bin/bash

#clear out any current ssh keys
rm .ssh/*
rm sftp/ssh/ssh_host*
rm ssh_host*


#generate the host ssh keys for the sftp service
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null


#move the keys into the sftp/ssh directory so they can be picked up
#by docker-compose bind mounts for the sftp service
mv ssh_host_ed25519_key sftp/ssh/
mv ssh_host_rsa_key sftp/ssh/
#this seems to be necessary
mv ssh_host_rsa_key.pub .ssh/known_hosts

#remove the unnecessary files
rm ssh_host*

#generate actual host login keys
ssh-keygen -t rsa -b 4096 -f ssh_client_rsa_key < /dev/null

mv ssh_client_rsa_key.pub sftp/ssh/
mv ssh_client_rsa_key sftp/ssh/
