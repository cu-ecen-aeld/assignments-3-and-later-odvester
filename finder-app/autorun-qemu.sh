#!/bin/sh
cd $(dirname $0)
echo "Running test script"
./finder-test.sh
rc=$?
if [ ${rc} -eq 0 ]; then
    echo "Completed with success!!"
else
    echo "Completed with failure, failed with rc=${rc}"
fi
echo "finder-app execution complete, dropping to terminal"
QEMU_CMDLINE="-M virt -kernel ${OUTDIR}/Image -initrd ${OUTDIR}/initramfs.cpio.gz -append 'root=/dev/vda1 console=ttyS0,115200 console=tty debug'"
/bin/sh
