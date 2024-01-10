section .data
str: 
    db "asm_print say hello world!", 0xa, 0
; 0xa是换行符号，0是字符串结束符对应ASII码中\0

str_len equ $-str

section .text
extern c_print
global _start
_start:
    ; 调用c代码中的c_print函数
    push str
    call c_print
    add esp, 4 ;回收栈空间

    ; 退出程序
    mov eax, 1 ;第1号功能是exit Linux的系统调用
    int 0x80

global asm_print
asm_print:
    push ebp
    mov ebp, esp
    mov eax, 4     ;第4号功能是write Linux的系统调用
    mov ebx, 1
    mov ecx, [ebp+8]
    mov edx, [ebp+12]
    int 0x80
    pop ebp
    ret
