@echo off
nasm .\mbr.s -o .\mbr.o
dd if=.\mbr.o of=D:\000-espath\100-Developer\Bochs2.6.8\hd60M.img bs=512 count=1 conv=notrunc
bochsdbg -f D:\000-espath\100-Developer\Bochs2.6.8\bochsrc.disk
echo cls