#! /bin/bash

# set PACKER_LOG=0 to turn off.  Details: https://www.packer.io/docs/other/debugging.html
export PACKER_LOG=1
export PACKER_LOG_PATH=~/packer/build_packer.log
rm -rf ./output_images/rhel76
~/bin/packer build ./source/templates/template.json 

echo Run align.sh to check .raw file before converting to .vhd
