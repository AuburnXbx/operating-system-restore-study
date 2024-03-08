#!/bin/bash
echo "bochs模拟器 启动开始========"
nasm mbr.s -o mbr.o 

dd if=mbr.o of=/home/xue/Desktop/bochs/hd60M.img bs=512 count=1 conv=notrunc
/home/xue/Desktop/bochs/bin/bochsdbg -f /home/xue/Desktop/bochs/bochsrc.disk 
echo "bochs模拟器 运行结束========"