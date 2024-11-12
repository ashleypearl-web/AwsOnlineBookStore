#!/bin/bash

# find myself and start from a known location
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

zip ../ansible/inventory.zip inventory_s.service pyconfig.json inventory.py static/*
