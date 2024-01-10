%include "boot.inc"
SECTION loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

;1、GDT段描述符表
;第一个表项
GDT_BASE:   dd 0x0000_0000
            dd 0x0000_0000
;第二个表项
CODE_DESC:  dd 0x0000_ffff
            dd DESC_CODE_HIGH4
;第三个表项
DATA_STACK_DESC:    dd 0x0000_ffff
                    dd DESC_DATA_HIGH4
;第四个表项
VIDEO_DESC: dd 0x8000_0007 ;limit=(0xbffff-0xb800)/4k=0x7
            dd DESC_VIDEO_HIGH4
GDT_SIZE equ $-GDT_BASE
GDT_LIMIT equ GDT_SIZE-1
times 60 dq 0 ;此处预留了60个段描述符表项空间


;2、构建段选择子
SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

;3、初始化GDT指针和显存数据
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
msg db '2 LOADER Started in real.'

;程序入口
loader_start:
    ;4、打印字符串：INT 0x10 功能号:0x13
    mov sp, LOADER_BASE_ADDR
    mov bp, msg
    mov cx, 25
    mov ax, 0x1301
    mov bx, 0x001f
    mov dx, 0x1800
    int 0x10

    ;5、准备进入保护模式
    ;5.1、打开A20
    in al, 0x92
    or al, 0000_0010b
    out 0x92,al

    ;5.2、加载GDT
    lgdt [gdt_ptr]

    ;5.3、cr0置为1
    mov eax, cr0
    or eax,0x0000_0001
    mov cr0, eax
    
    jmp dword SELECTOR_CODE:p_mode_start   ;刷新流水线

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    mov byte [gs:170], 'P'
    jmp $
