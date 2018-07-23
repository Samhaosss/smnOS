
.code16 

#这里保存光标位置
#
#
.text

.equ INITSET,0X9000		#存储光标，会覆盖boot程序
.equ SETUPSEG, 0X9020
.equ OFFSET, 0x0000
.equ LEN,10


	
_start:
	#save cursor position 
	mov $INITSET, %ax
	mov %ax, %ds
	mov $0x03, %ah
	xor %bh, %bh
	int $10
	mov %dx, %ds:0

#存储扩展内存大小
#0x15中断 0x88服务
	mov $0x88, %ah
	int $0x15
	mov %ax,%ds:2

#存储 输出模式
	mov $0x12, %ah
	mov $0x10, %bl
	int $0x10
	mov %ax, %ds:8
	mov %bx, %ds:10
	mov %cx, %ds:12
#获取硬盘参数表
	mov $0x0000,%ax
	mov %ax, %ds
	lds %ds:4*0x41, %si
	mov $INITSET, %ax  
	mov %ax, %es 
	mov $0x80, %di
	mov $0x10, %cx 
	rep movsb 

	mov $0x0000,%ax
	mov %ax, %ds
	lds %ds:4*0x46, %si
	mov $INITSET, %ax  
	mov %ax, %es 
	mov $0x90, %di
	mov $0x10, %cx 
	rep movsb 

#检测第二块硬盘是否存在
#若不存在则将以后硬盘信息清空
	mov $0x1500, %ax
	mov $0x81, %dl
	int $0x13
	jc no_disk1
	cmp $3, %ah
	je is_disk1

no_disk1:

	mov $INITSET,%ax
	mov %ax, %es 
	mov $0x90, %di 
	mov $0x10, %cx
	mov $0x00, %ax
	rep stosb

run:
	call print 

is_disk1:
	#准备进入 保护模式
	cli
	#move sys image into to 0x0000:0000
	mov $0x1000, %ax
	mov %ax, %ds 
	mov $0x0000, %ax
	mov %ax, %es
	sub %bx, %bx
	sub %di, %di 
	mov $0x1000, %cx 
	rep movsw 
/*
do_move:
#接下来将内核从0x1000:0000移动到0x0000:0000
#rep movsw 将ds:si -> es:di
	
	mov %ax, %es
	add $0x1000, %ax
	cmp $0x9000, %ax
	jz end_move
	mov %ax, %ds
	sub %di, %di
	sub %si, %si
	mov $0x8000,%cx
	rep movsw
	jmp do_move*/

end_move:
	mov $SETUPSEG,%ax
	mov %ax, %ds
	lgdt gdt_48
	lidt idt_48

a20:
	in $0x92, %al 
	or $0x02, %al 
	out %al, $0x92

#start protect mode 
	mov %cr0, %eax
	bts $0, %eax 
	mov %eax, %cr0 

#seg selector
	.equ sel_cs0, 0x0008
	ljmp $sel_cs0, $0
	mov $0x10,%ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

IDT:
	


gdt_48:
	.word 0x7ff
	.word 512+gdt, 0x9

gdt:
	.word 0, 0, 0, 0
	#code seg 
#	.quad 0x00c09a00000007ff
	.word 0x07ff		#limit 
	.word 0x0000		#base 
	.word 0x9a00		# 1001 1010 0000 0000
	.word 0x00c0		# 0000 0000 1100 0000
	#data set 
#	.quad 0x00c09200000007ff
	.word 0x07ff		#limit 
	.word 0x0000		#base 
	.word 0x9200
	.word 0x00c0 
#global descriptor table 

idt_48:
	.word 0
	.word 0, 0 
idt:
	


print:
	mov $0x03, %ah
	int $0x10

	#指定字符串地址
	mov $0, %ah
	mov $SETUPSEG, %ax
	mov %ax, %es
	mov $msg, %bp
	#设定输出模式，调用功能号
	mov $0x1301, %ax 
	mov $0x0007, %bx
	mov $LEN, %cx
	int $0x10
	ret 


msg:
	.string "load ok!!!"
