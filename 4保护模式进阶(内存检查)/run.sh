/home/xue/Desktop/Nasm/保护模式进阶
dd if=/home/xue/Desktop/Nasm/保护模式进阶/bin/mbr.o \
of=/home/xue/Desktop/bochs/hd60M.img \
bs=512 count=1 conv=notrunc

dd if=/home/xue/Desktop/Nasm/保护模式进阶/bin/loader.o \
of=/home/xue/Desktop/bochs/hd60M.img \
seek=2 \
bs=512 count=4 conv=notrunc