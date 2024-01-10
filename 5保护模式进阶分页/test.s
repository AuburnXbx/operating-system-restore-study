[bits 32]
;初始化页目录空间
setup_page:
    mov ecx,4096
    mov esi, 0
    .clean_page_dir:
        mov byte [PAGE_DIR_TABLE_POS+esi], 0
        inc esi
        loop .clean_page_dir
    ;创建页目录项PDE
    .create_pde:
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x1000 ;此时eax为为第一个页表的位置和属性值0000000000_0100000001_000000000111b
        mov ebx, eax    ;为.create_pte做准备，ebx为基址
        or eax, PG_US_1 | PG_RW_1 | PG_P_1
        mov [PAGE_DIR_TABLE_POS + 0x0], eax ;页目录表第1个页目录项
                                            ;指向第1页表,该页表占4KB，物理地址=0x101*4K---即第257页(从1算起)
        mov [PAGE_DIR_TABLE_POS + 0xc00], eax   ;页目录表第769个页目录项,也指向第1页表。
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

    ;创建页表项PTE
    ;一个页表容量大小为4MB，我们目前只用得上第一个1MB空间，所以只为这1MB空间分配物理页
    ;即分配256个PTE
    mov ecx, 256
    mov esi, 0
    mov edx, PG_US_1 | PG_RW_1 | PG_P_1
    .create_pte:
        mov [ebx+esi*4], edx
        add edx, 0x1000   ;在低端1MB中，虚拟地址等同于物理地址0x1000=4096
        inc esi
        loop .create_pte
    
    ;创建内核其他的PDE
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


    call setup_page    ;创建页目录表的函数,我们的页目录表必须放在1M开始的位置，所以必须在开启保护模式后运行
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

    mov byte [gs:160], 'V'  ;视频段段基址已经被更新,用字符v表示virtual addr
