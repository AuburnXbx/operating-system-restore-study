;1、loader.s相关
LOADER_START_SECTION equ 0x2
LOADER_BASE_ADDR equ 0x600


;2、gdt属性
;2.1、段描述符高32位，前4字节
;2.1.1、段描述符第23位G：1代表段界限单位为4kB；0代表段界限单位为1B
DESC_G_4KB equ 1000_0000_0000_0000_0000_0000b
DESC_G_1B equ 0000_0000_0000_0000_0000_0000b

;2.1.2、段描述符22位D/B:代码段D位：1代表有效地址、操作数是32位，使用eip；0代表16位使用ip
;              栈段B位：1代表使用esp，操作数大小32位；0代表使用sp，操作数大小16位
DESC_DB_1 equ 100_0000_0000_0000_0000_0000b
DESC_DB_0 equ 000_0000_0000_0000_0000_0000b

;2.1.3、段描述符第21位L：1代表代码段是64位；0代表是32位
DESC_L_64 equ 10_0000_0000_0000_0000_0000b 
DESC_L_32 equ 00_0000_0000_0000_0000_0000b

;2.1.4、段描述符第20位AVL：保留暂无意义
DESC_AVL equ 0_0000_0000_0000_0000_0000b

;2.1.5、段描述符第19~16位段界限高四位：这里因为使用保护模式，所以段界限设定全为1，代表段内偏移最大4GB
DESC_LIMIT_HIGH4 equ 1111_0000_0000_0000_0000b

;2.1.6、段描述符第15位P：1代表段存在内存中；0代表不在，cpu进行检查，如果为0则抛出异常
DESC_P equ 1000_0000_0000_0000b

;2.1.7、段描述符14~13位DPL：代表权级别，数字越小级别越高，os级别为0，应用程序为3
DESC_DPL0 equ 000_0000_0000_0000b
DESC_DPL1 equ 010_0000_0000_0000b
DESC_DPL2 equ 100_0000_0000_0000b
DESC_DPL3 equ 110_0000_0000_0000b

;2.1.8、段描述符第12位S：1代表该内存段是非系统段；0代表该内存段是系统段，配合type使用
DESC_S_1 equ 1_0000_0000_0000b
DESC_S_0 equ 0_0000_0000_0000b

;2.1.9、段描述符第11~8位：用于指定内存段的具体类型
;代码段：由于具体类型太多了，这里指定未访问只执行代码段即---X=1,C=0,R=0,A=0
DESC_CODE_TYPE equ 1000_0000_0000b
;数据段：同代码段一样，这里只指定未访问不可执行向上拓展可读写数据段---X=0,e=0,W=1,A=0
DESC_DATA_TYPE equ 0010_0000_0000b

;2.2、段描述符低32位：段基址低16位和段界限低16位的设定比较灵活和简单，这里就不写了放在了loader.s中


;3、选择子属性16位寄存器（cs、ss、ds、es等）
;第0~1位：表示请求特权级
RPL0 equ 00b
RPL1 equ 01b
RPL2 equ 10b
RPL3 equ 11b
;第2位：1代表选择子在LDT中；0代表在GDT中
TI_GDT equ 000b
TI_LDT equ 100b


;4、段描述高4字节使用
;代码段描述符高4字节
DESC_CODE_HIGH4 equ (0x00 << 24) + DESC_G_4KB + DESC_DB_1 + \
                    DESC_L_32 + DESC_AVL + DESC_LIMIT_HIGH4 + \
                    DESC_P + DESC_DPL0 + DESC_S_1 + \
                    DESC_CODE_TYPE + 0x00
;数据段描述符高4字节
DESC_DATA_HIGH4 equ (0x00 << 24) + DESC_G_4KB + DESC_DB_1 + \
                    DESC_L_32 + DESC_AVL + DESC_LIMIT_HIGH4 + \
                    DESC_P + DESC_DPL0 + DESC_S_1 + \
                    DESC_DATA_TYPE + 0x00
;显存段描述符
DESC_VIDEO_HIGH4 equ (0x00 << 24) + DESC_G_4KB + DESC_DB_1 + \
                    DESC_L_32 + DESC_AVL + (0x00<<20) + \
                    DESC_P + DESC_DPL0 + DESC_S_1 + \
                    DESC_DATA_TYPE + 0x0b


;5、分页相关
;5.1、页目录物理地址
PAGE_DIR_TABLE_POS equ 0x10_0000 ;保护模式下低端1MB空间第一字节
;5.2、页目录项/页表项属性
;5.2.1、第0位P：1代表该页存在物理内存中；0代表不在
PG_P_1 equ 1b
PG_P_0 equ 0b
;5.2.2、第1位RW：1代表可读写；0代表只可读
PG_RW_1 equ 10b
PG_RW_0 equ 00b
;5.2.3、第2位US：1代表任何特权级都可以访问该页；0代表特权级3不能访问，012可以
PG_US_1 equ 100b
PG_US_0 equ 000b
;5.2.4、第3位PWT：1代表该页不仅是普通内存，还是高速缓存与PDT相关；0代表为普通内存
PG_PWT_0 equ 0000b
;5.2.5、第4位PDT：1代表该页启动高速缓存；0代表禁止该页缓存
PG_PDT_0 equ 0_0000b
;5.2.6、第5位A:1代表该页被cpu访问过了，0代表没有
PG_A equ 00_0000b
;5.2.7、第6位D：意为脏页，当cpu对某一页进行写操作时将该位置为1
PG_D equ 000_0000b
;5.2.8、第7位PAT：页属性表位，比较复杂，这里置为0即可
PG_PAT equ 0000_0000b
;5.2.9、第8位G：1代表该页为全局页，可以一直在TLB高速缓存中保存；0代表时非全局页
PG_G_1 equ 1_0000_0000b
PG_G_0 equ 0_0000_0000b
;5.2.10、第9~11位AVL：os可用位，这里暂时略过
PG_AVL equ 0000_0000_0000b

;6、内核加载相关
KERNEL_START_SECTOR equ 9 ;内核的可执行文件放在硬盘中的第9扇区，从0开始编号
KERNEL_BIN_BASE_ADDR equ 0x70000 ;可执行文件的内存装载地址
PT_NULL equ 0
KERNEL_ENTRY_POINT equ 0x1500 ;内核映像程序入口虚拟地址