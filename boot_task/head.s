
.code16 

.equ DEMOSEG, 0X1000
.equ OFFSET, 0
.equ LEN,10

run:
	call print

loop_forever:
	jmp loop_forever
	
print:
	mov $0x03, %ah
	int $0x10

	#指定字符串地址
	mov $0, %ah
	mov $DEMOSEG, %ax
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
