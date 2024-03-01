E:\SoftwareWorkplace\project\Assembly\Nasm\保护模式进阶分页
D:\Development\Bochs2.6.8

dd if=E:\SoftwareWorkplace\project\Assembly\Nasm\保护模式进阶分页\bin\mbr.o of=D:\Development\Bochs2.6.8\hd60M.img bs=512 count=1 conv=notrunc

dd if=E:\SoftwareWorkplace\project\Assembly\Nasm\保护模式进阶分页\bin/loader.o of=D:\Development\Bochs2.6.8\hd60M.img seek=2 bs=512 count=4 conv=notrunc