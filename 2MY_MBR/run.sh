/home/xue/Desktop/Nasm/MY_MBR
dd if=/home/xue/Desktop/Nasm/MY_MBR/bin/mbr.o \
of=/home/xue/Desktop/bochs/hd60M.img \
bs=512 count=1 conv=notrunc

dd if=/home/xue/Desktop/Nasm/MY_MBR/bin/loader.o \
of=/home/xue/Desktop/bochs/hd60M.img \
seek=2 \
bs=512 count=1 conv=notrunc