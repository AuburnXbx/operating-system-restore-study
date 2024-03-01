nasm mbr.s -I include -o bin\mbr.o 
nasm loader.s -I include -o bin\loader.o

dd if=bin\mbr.o of=D:\000-espath\100-Developer\Bochs2.6.8\hd60M.img bs=512 count=1 conv=notrunc
dd if=bin\loader.o of=D:\000-espath\100-Developer\Bochs2.6.8\hd60M.img seek=2 bs=512 count=4 conv=notrunc
bochsdbg -f D:\000-espath\100-Developer\Bochs2.6.8\bochsrc.disk
echo cls