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

