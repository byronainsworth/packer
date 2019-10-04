# packer

Packer confinguration to build a Red Hat Enterprise Linux 7.6 VM, configured for upload to Azure.
Output of build.sh is a .raw disk image containing a configured VM.  
VM is configured with 2048MB of swap, via waagent.

## Main files:

  `./build.sh`
  
  Main script to run build process.
  
 
  `./source/variables/secrets.pass`
  
  Contains RHEL subscription user-name & passowrd in format:
  
      `USERNAME=myusername`
      
      `PASSWORD=mypassword`
      
      `POOLID= 'pool ID from Red Hat subscription'`  

  POOLID currently unused.
      
      
      
  `./source/scripts/register.sh`
  
  Contains post-installation VM configuration steps


## To use in Azure:
   1.  Check alignment of .raw file, using ./align.sh
   2.  Correct if necessary with `qemu-img resize -f raw...`    
   3.  Convert to .vhd format:   E.g. `qemu-img convert -f raw -o subformat=fixed,force_size -O vpc file.raw file.vhd`
   4.  Upload to Azure with: `az storage blob upload...`
   5.  Create Azure image with:  `az image create...`
   6.  Create Azure VM from image
   
More details:  https://access.redhat.com/articles/uploading-rhel-image-to-azure


   
## Prerequisites:
   1.  Hashicorp packer: https://www.packer.io/
   2.  qemu
   3.  Azure account & CLI client
   4.  RHEL installation ISO.   Current configuration has only been tested with RHEL 7.6
   5.  RHEL subscription.
