#!/bin/bash

# find myself and start from a known location
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

DESTDIR="${SCRIPT_DIR}/../etc"
mkdir -p ${DESTDIR}
cd $DESTDIR

if [ -f ec2user ] || [ -f ec2user.pem ] || [ -f ec2user.pub ] ; then
    echo "ec2user key files exist, aborting"
    exit 11
fi

ssh-keygen -t rsa -b 2048 -f ec2user -q -N ""
mv ec2user ec2user.pem
chmod 0400 ec2user.pem ec2user.pub
cp ec2user.pem ../ansible
