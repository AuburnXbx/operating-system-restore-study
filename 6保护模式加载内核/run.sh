#!/bin/bash
echo 
nasm mbr.s -I include/ -o bin/mbr.o && \ 
dd if=bin/mbr.o of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=1 conv=notrunc

nasm loader.s -I include/ -o bin/loader.o && \ 
dd if=bin/loader.o of=/home/xue/Desktop/bochs/hd60M.img seek=2 bs=512 count=4 conv=notrunc

/home/xue/Desktop/gcc6.3.0/bin/gcc -m32 -c c/main.c -o c/main.o  && /home/xue/Desktop/binutils/bin/ld c/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o bin/kernel.bin \
&& dd if=bin/kernel.bin of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc
/home/xue/Desktop/bochs/bin/bochsdbg -f /home/xue/Desktop/bochs/bochsrc.disk
echo "========bochs模拟器 运行结束========"
echo 