#!/bin/bash
#/home/xue/Desktop/Nasm/6保护模式加载内核
nasm mbr.s -I include/ -o bin/mbr.o && \ 
dd if=bin/mbr.o of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=1 conv=notrunc

nasm loader.s -I include/ -o bin/loader.o && \ 
dd if=bin/loader.o of=/home/xue/Desktop/bochs/hd60M.img seek=2 bs=512 count=4 conv=notrunc

gcc-8 -m32 -c c/main.c -o c/main.o  && /home/xue/Desktop/binutils-2.26/build/bin/ld c/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o bin/kernel.bin \
&& dd if=bin/kernel.bin of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=200 seek=9 conv=notrunc
