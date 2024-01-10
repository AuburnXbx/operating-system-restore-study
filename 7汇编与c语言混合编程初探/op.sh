#!/bin/bash
gcc -m32 -c c/C_with_S.c -o bin/C_with_S1.o
nasm -f elf32 C_with_S.s -o bin/C_with_S2.o
/home/xue/Desktop/binutils-2.26/build/bin/ld bin/C_with_S1.o  bin/C_with_S2.o -m elf_i386 -o bin/c_with_s.bin