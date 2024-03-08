#!/bin/bash
echo 
echo "========bochs模拟器 启动开始========"
nasm mbr.s -I include -o bin/mbr.o 
nasm loader.s -I include -o bin/loader.o

dd if=bin/mbr.o of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=1 conv=notrunc
dd if=bin/loader.o of=/home/xue/Desktop/bochs/hd60M.img seek=2 bs=512 count=4 conv=notrunc
/home/xue/Desktop/bochs/bin/bochsdbg -f /home/xue/Desktop/bochs/bochsrc.disk
echo "========bochs模拟器 运行结束========"
echo 