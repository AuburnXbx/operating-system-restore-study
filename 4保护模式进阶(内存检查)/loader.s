%include "boot.inc"
SECTION loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

;1、GDT段描述符表（共512字节）
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

;3、total_mem_bytes用于保存内存容量
total_mem_bytes dd 0	;以字节为单位
                        ;当前偏移loader.bin文件头0x200字节,loader.bin的加载地址是0x600,
                        ;故total_mem_bytes内存中的地址是0x800.将来在内核中咱们会引用此地址	

;4、初始化段描述符指针和内存空间
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
ards_buf times 244 db 0   ;人工对齐total_mem_bytes4字节+gdt_ptr6字节+ards_buf244字节+ards_nr2,共256字节
ards_nr dw 0		      ;用于记录ards结构体数量

;程序入口
loader_start:
    ;-------  int 15h eax = 0000E820h ,edx = 534D4150h ('SMAP') 获取内存布局  -------
    xor ebx, ebx		   ;第一次调用时，ebx值要为0
    mov edx, 0x534d4150	   ;edx只赋值一次，循环体中不会改变
    mov di, ards_buf	   ;ards结构缓冲区
    .e820_mem_get_loop:	   ;循环获取每个ARDS内存范围描述结构
        mov eax, 0x0000e820	   ;执行int 0x15后,eax值变为0x534d4150,所以每次执行int前都要更新为子功能号。
        mov ecx, 20		       ;ARDS地址范围描述符结构大小是20字节
        int 0x15
        add di, cx		       ;使di增加20字节指向缓冲区中新的ARDS结构位置
        inc word [ards_nr]	   ;记录ARDS数量
        cmp ebx, 0		       ;若ebx为0且cf不为1,这说明ards全部返回，当前已是最后一个
        jnz .e820_mem_get_loop

                            ;在所有ards结构中，找出(base_add_low + length_low)的最大值，即内存的容量。
    mov cx, [ards_nr]	    ;遍历每一个ARDS结构体,循环次数是ARDS的数量
    mov ebx, ards_buf 
    xor edx, edx		    ;edx为最大的内存容量,在此先清0
    .find_max_mem_area:	        ;无须判断type是否为1,最大的内存块一定是可被使用
        mov eax, [ebx]	        ;base_add_low
        add eax, [ebx+8]	    ;length_low
        add ebx, 20		        ;指向缓冲区中下一个ARDS结构
        cmp edx, eax		    ;冒泡排序，找出最大,edx寄存器始终是最大的内存容量
        jge .next_ards
        mov edx, eax		    ;edx为总内存大小
    .next_ards:
        loop .find_max_mem_area
    mov [total_mem_bytes], edx	   ;将内存换为byte单位后存入total_mem_bytes处。


