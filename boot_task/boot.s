
.code16
.global BOOT

#SEG:OFFSET 
#这里很重要，x86开始处于实模式，

.equ BOOTSEG, 0X7c0 
.equ DEMOSEG, 0X1000
.equ OFFSET, 0X0000
.equ BIOS, 0x9000
.text 

# 1)清除流水线缓存
# 2) cs:0x7c00 ip:0000
ljmp $BOOTSEG, $BOOT

BOOT:
	call print 
load_sys:
	#选择磁头 扇区
	mov $0x0000, %dx
	mov $0x0002, %cx	#扇区从1开始，柱面、盘片从0开始
	
	#设置load的物理地址，这里还在实模式
	mov $DEMOSEG, %ax
	mov %ax, %es
	mov $OFFSET, %bx
	
	mov $0x02, %ah
	mov $4, %al  #读取扇区数
	int $0x13
	
	jnc load_ok
die:	jmp die 

#ljmp实现段间跳转
#jmp
load_ok:
	#设置数据段
	mov $DEMOSEG, %ax
	mov %ax, %ds
	#长跳转到demo程序
	ljmp $DEMOSEG, $OFFSET

	
	
print:
	mov $0x03, %ah
	int $0x10

	#指定字符串地址
	mov $0, %ah
	mov $BOOTSEG, %ax
	mov %ax, %es
	mov $string, %bp
	#设定输出模式，调用功能号
	mov $0x1301, %ax 
	mov $0x0007, %bx
	mov $11, %cx
	int $0x10
	ret 


string:
	.ascii "hello 80x86"


.org 510 
.word 0xAA55
