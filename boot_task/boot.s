
.code16
.global BOOT

#SEG:OFFSET 
#这里很重要，x86开始处于实模式，
.equ BOOTSEG, 0X7c0 

.text 

# 1)清除流水线缓存
# 2) cs:0x7c00 ip:0000
ljmp $BOOTSEG, $BOOT

BOOT:
	#获得行与列
	mov $0x03, %ah
	int $0x10

	#指定字符串地址
	mov $BOOTSEG, %ax
	mov %ax, %es
	mov $string, %bp
	#设定输出模式，调用功能号
	mov $0x1301, %ax 
	mov $0x0007, %bx
	mov $11, %cx
	int $0x10
loop:
	jmp loop
	

	
	

string:
	.ascii "hello 80x86"


.org 510 
.word 0xAA55
