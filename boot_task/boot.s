
.code16
.global BOOT

#SEG:OFFSET 
#这里很重要，x86开始处于实模式，
.equ BOOTSEG, 0X7c0 
.equ SETUPSEG, 0X9020
.equ OFFSET, 0X0000
.equ SEG, 0x9000
.equ IMAGESEG, 0X1000

.text 

#随着开发，boot需要被修改的地方有:
#1) load_sys部分
#2) 设备信息、根分区

/*
*目前 boot的基本功能只有加载setup和system
*/

# 1)清除流水线缓存
# 2) cs:0x7c00 ip:0000
ljmp $BOOTSEG, $SELFMOV


SELFMOV:
	#这里将自己移动到0x9000:0000
	#使用重复移动指令 从DS:SI 移动到 ES:DI			
	mov $BOOTSEG, %ax
	mov %ax, %ds
	sub %si, %si

	mov $SEG, %ax 
	mov %ax, %es
	sub %di, %di
	#boot只有512 每次移动word因此设置c为256x
	mov $256, %cx
	rep movsd

	ljmp $SEG,$AFTERMOV 

AFTERMOV:
	call print 
load_setup:
	#选择磁头 扇区
	mov $0x0000, %dx
	mov $0x0002, %cx	#扇区从1开始，柱面、盘片从0开始
	
	#设置load的物理地址，这里还在实模式
	mov $SETUPSEG, %ax
	mov %ax, %es
	mov $OFFSET, %bx
	
	mov $0x02, %ah
	mov $4, %al  #读取扇区数
	int $0x13
	
	jnc load_sys
die:	jmp die 
#这里先使用尽量简单的办法，使用bios中断读取
#随着内核变大这里需要修改
load_sys:
	mov $0x0000, %dx
	mov $0x0006, %cx
	mov $IMAGESEG, %ax
	mov %ax, %es 
	mov $0x0, %bx 
	mov $0x02, %ah
	mov $4, %al
	int $0x13
	jnc load_ok

die_sys:jmp die_sys

#linux0.11还存储了根分区信息，这里处于初级开发阶段，无需考虑 更多



#ljmp实现段间跳转
#jmp
load_ok:
	#设置数据段
	mov $SETUPSEG, %ax
	mov %ax, %ds
	#长跳转到demo程序
	ljmp $SETUPSEG, $OFFSET

	
	
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
	.ascii "___loading!"


.org 510 
.word 0xAA55
