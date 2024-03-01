%include "boot.inc"
SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

;1、以下代码全是，设置显示形参调用中断，用于窗口显示
    mov ax,0x0600
    mov bx,0x0700  
    mov cx,0x0000
    mov dx,0x184f    
    int 0x10

    mov ax,0x0300    
    mov bx,0x0000    
    int 0x10

    mov ax,0x0000
    mov es,ax
    mov ax,message
    mov bp,ax
    mov ax,0x1301
    mov bx,0x0007    ;设置字体属性，02是黑底绿字，07是黑底白字
    mov cx,14
    int 0x10    ;使用中断完成显示功能

;2、加载磁盘中的loader程序
    mov eax,LOADER_START_SECTION    ;loader程序在硬盘中的地址
    mov bx, LOADER_BASE_ADDR    ;loader程序的装载地址，也就是loader在内存中的位置
    mov cx,4    ;需要读取的扇区数量，0代表读取从指定开始的256个扇区
    call rd_disk_m_16

;4、转移执行loader程序
    jmp LOADER_BASE_ADDR + 0x300

;3、磁盘读取函数
rd_disk_m_16:
    ;备份eax和cx
    mov esi,eax
    mov di,cx
    ;读写磁盘
    ;3.1、设置要读取的扇区数
    mov dx,0x1f2
    mov al,cl
    out dx,al
    mov eax,esi
    ;3.2、设置LBA硬盘读取地址
    mov dx,0x1f3
    out dx,al
    
    mov dx,0x1f4
    mov cl,8
    shr eax,cl
    out dx,al

    mov dx,0x1f5
    shr eax,cl
    out dx,al

    mov dx,0x1f6
    shr eax,cl
    and al,0x0f ;设置deviced低6位，即LBA地址的24-27位
    or al,0xe0  ;设置deviced,4-7位为1110，表示采用LBA模式
    out dx,al
    ;3.3、向comand写入读命令
    mov dx,0x1f7
    mov al,0x20
    out dx,al
    ;3.5、检查硬盘状态
    .check_ready:
        nop
        in al,dx
        and al,0x88
        cmp al,0x08 ;如第7位为1，表示硬盘正忙；如第3位为1，表示硬盘已经就绪
        jnz .check_ready
    ;3.6、硬盘数据读取到指定内存
    mov ax,di
    mov dx,256
    mul dx
    mov cx,ax   ;设置循环读取次数，di：只读一个扇区(512字节)，每次循环读取一个字(2字节)，总共需要读取256次
    mov dx,0x1f0
    .read_loader:
        in ax,dx
        mov [bx],ax
        add bx,2    ;后移一个字
        loop .read_loader
    ret
    
    message db "1 MBR Started."
    times 510-($-$$) db 0
    db 0x55,0xaa
