                                                        ;-------------------------------------------------------------------------------
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
    call mem_cpy
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
        mov edi, [ebp + 8]  ;目标虚拟地址即---p_vaddr值（ebx+8）
        mov esi, [ebp + 12] ;源地址即---文件基地址+p_offset值（ebx+4+KERNEL_BASE_ADDR）
        mov ecx, [ebp + 16]
        rep movsb   ;movsb指令用于把字节从ds:si 搬到es:di
                    ;rep是repeat的意思，rep movsb 就是多次搬运。
                    ;搬运前先把字符串的长度存在cx寄存器中，然后重复的次数就是cx寄存器所存数据的值。
        pop ecx
        pop ebp
        ret
