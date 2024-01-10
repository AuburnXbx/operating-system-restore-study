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

;4、初始化指针和内存空间
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
ards_buf times 244 db 0   ;人工对齐total_mem_bytes4字节+gdt_ptr6字节+ards_buf244字节+ards_nr2,共256字节
ards_nr dw 0		      ;用于记录ards结构体数量

;加载器程序入口
loader_start:

    ;1、检查内存
    call check_memory

    ;2、打开保护模式
    ;2.1、打开A20
    in al, 0x92
    or al, 0000_0010b
    out 0x92,al
    ;2.2、加载GDT
    lgdt [gdt_ptr]
    ;3.3、cr0置为1
    mov eax, cr0
    or eax,0x0000_0001
    mov cr0, eax

    ;4、进入保护模式
    jmp dword SELECTOR_CODE:p_mode_start   ;刷新流水线，同时初始化cs

;检查内存函数
check_memory:
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
    ret

;进入保护模式函数
[bits 32]
p_mode_start:
    ;1、初始化保护模式下的段寄存器(段选择子！)
    mov eax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

    ;测试代码，进入保护模式成功会在显示器上打印字母P
    mov byte [gs:160], 'P'

    ;2、加载内核文件可执行文件到0x70000处
    mov eax, KERNEL_START_SECTOR
    mov ebx, KERNEL_BIN_BASE_ADDR
    mov ecx, 200
    call rd_disk_m_32

    ;3、初始化分页
    call setup_page
    ;启用分页，并更新在分页下段描述符中的段基址！
    ;以下两句是将gdt描述符中视频段描述符中的段基址+0xc0000000
    mov ebx, [gdt_ptr + 2]     ;ebx中存着GDT_BASE
    or dword [ebx + 0x18 + 4], 0xc0000000    ;视频段是第3个段描述符,每个描述符是8字节,故0x18 = 24，然后+4，是取出了视频段段描述符的高4字节。然后or操作，段基址最高位+c                                      
    add dword [gdt_ptr + 2], 0xc0000000      ;将gdt的基址加上0xc0000000使其成为内核所在的高地址
    add esp, 0xc0000000              ; 将栈指针同样映射到内核地址
    mov eax, PAGE_DIR_TABLE_POS      ; 把页目录地址赋给cr3
    mov cr3, eax                                                  
    mov eax, cr0             ; 打开cr0的pg位(第31位)
    or eax, 0x80000000  
    mov cr0, eax                                                
    lgdt [gdt_ptr]    ;在开启分页后,用gdt新的地址重新加载

    ;测试启动分页机制下，显存的工作是否正常，gs为显示段选择子
    mov byte [gs:170], 'V'  ;视频段段基址已经被更新,用字符v表示virtual addr

    ;3、跳转执行内核映像
    call kernel_init
    mov esp, 0xc009f000
    jmp KERNEL_ENTRY_POINT

;初始化页空间函数
setup_page:
    mov ecx,4096
    mov esi, 0
    ;1、初始化页目录空间
    .clean_page_dir:
        mov byte [PAGE_DIR_TABLE_POS+esi], 0
        inc esi
        loop .clean_page_dir
    ;2、创建页目录项PDE
    .create_pde:
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x1000 ;此时eax代表的pde值0000000000_0100000001_000000000111b
        mov ebx, eax    ;为.create_pte做准备，ebx为基址
        or eax, PG_US_1 | PG_RW_1 | PG_P_1
        mov [PAGE_DIR_TABLE_POS + 0x0], eax ;页目录表第1个页目录项
                                            ;指向第1页表所在的物理页,物理地址=0x101*4K---即第257页(从1算起)
        mov [PAGE_DIR_TABLE_POS + 0xc00], eax   ;页目录表第769个页目录项,也指向第1页表所在内存的物理页。
                                                ;首先，页目录表一共有1024个PDE,操作系统使用第769（从1算起）PDE，
                                                ;到第1023个PDE，共使用这255个PDE对应操作系统占用的高1GB内存空间。
                                                ;(实际上第1024号PDE留给了页目录所在物理页本身---即第256页)
                                                ;其次，这里操作系统使用的是虚拟上的高1GB内存，而实际上
                                                ;这1GB对应着的是物理上的低地址1GB空间，所以第768和第1个PDE
                                                ;都指向了第一个页表---即物理上第一张页表中存放着操作系统的部分内核代码。
                                                ;又因为我们的内核代码量很小，所以第一张页表除去实模式下占用的1MB空间和页目录
                                                ;占用的4kB大小，余下的空间足够装下我们所有的代码
        sub eax, 0x1000
        mov [PAGE_DIR_TABLE_POS + 4092], eax    ;页目录表最后一项1023号项指向自己——为的是将来动态操作页表做准备。

    ;3、创建页表项PTE
    ;一个页表容量大小为4MB，我们目前只用得上第一个1MB空间，所以只为这1MB空间分配物理页
    ;即分配256个PTE
    mov ecx, 256
    mov esi, 0
    mov edx, PG_US_1 | PG_RW_1 | PG_P_1
    .create_pte:
        mov [ebx+esi*4], edx
        add edx, 0x1000   ;页数+1
        inc esi
        loop .create_pte
    
    ;4、创建内核其他的PDE
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000
    or eax, PG_US_1 | PG_RW_1 | PG_P_1
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254
    mov esi, 769
    .create_kernel_pde:
        mov [ebx+esi*4], eax
        inc esi
        add eax,0x1000
        loop .create_kernel_pde
    ret

;磁盘读取函数,相比于rd_disk_m_16，运行在保护模式下，在.read_loader中把bx改为了ebx
rd_disk_m_32:
    ;备份eax和cx
    mov esi,eax
    mov di,cx
    ;读写磁盘
    ;1、设置要读取的扇区数
    mov dx,0x1f2
    mov al,cl
    out dx,al
    mov eax,esi
    ;2、设置LBA硬盘读取地址
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
    ;3、向comand写入读命令
    mov dx,0x1f7
    mov al,0x20
    out dx,al
    ;4、检查硬盘状态
    .check_ready:
        nop
        in al,dx
        and al,0x88
        cmp al,0x08 ;如第7位为1，表示硬盘正忙；如第3位为1，表示硬盘已经就绪
        jnz .check_ready
    ;5、硬盘数据读取到指定内存
    mov ax,di
    mov dx,256
    mul dx
    mov cx,ax   ;设置循环读取次数，di：只读一个扇区(512字节)，每次循环读取一个字(2字节)，总共需要读取256次
    mov dx,0x1f0
    .read_loader:
        in ax,dx
        mov [ebx],ax
        add ebx,2    ;后移一个字
        loop .read_loader
    ret

;内核映像初始化函数
kernel_init:
    ;初始化要用到的寄存器
    xor eax, eax
    xor ebx, ebx    ;记录程序头地址
    xor ecx, ecx    ;记录程序头地址表中的条目：program header数量---即e_phnum
    xor edx, edx    ;记录program header的大小，即e_phentsize

    mov dx, [KERNEL_BIN_BASE_ADDR + 42]
    ;获取第一个program header在文件中的偏移
    mov ebx, [KERNEL_BIN_BASE_ADDR + 28]
    add ebx, KERNEL_BIN_BASE_ADDR

    mov cx, [KERNEL_BIN_BASE_ADDR + 44]
    ;判断程序段类型
    .each_segment:
        cmp byte [ebx + 0], PT_NULL
        je .PTNULL
        
    push dword [ebx + 16]
    mov eax, [ebx + 4]
    add eax, KERNEL_BIN_BASE_ADDR
    push eax
    mov eax, [ebx + 8]
    push dword [ebx + 8]
    call .mem_cpy
    nop
    add esp, 12

    ;读取下一个program header
    .PTNULL:
        add ebx, edx
        loop .each_segment
        ret
    ;复制程序段到指定虚拟空间
    .mem_cpy:
        nop
        cld
        push ebp
        mov ebp, esp
        push ecx

        mov edi, [ebp + 8] ;目标虚拟地址即---p_vaddr值（ebx+8）
        mov esi, [ebp + 12] ;源地址即---文件基地址+p_offset值（ebx+4+KERNEL_BASE_ADDR）
        mov ecx, [ebp + 16]
        rep movsb   ;movsb指令用于把字节从ds:si 搬到es:di
                    ;rep是repeat的意思，rep movsb 就是多次搬运。
                    ;搬运前先把字符串的长度存在cx寄存器中，然后重复的次数就是cx寄存器所存数据的值。
        pop ecx
        pop ebp
        ret
    
