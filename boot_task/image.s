.code32
#进入32位模式
#将显存段移入gs寄存器
#循环打印26个字母 从而证明setup程序的设置有效

print:
	sub  %eax, %eax 
	mov  $0x18, %bx 
	mov  %bx, %gs
	mov  $65, %al
	mov  $0, %ebx
	mov  $26,%cx
loop:
	movb %al, %gs:(%ebx)
	add  $2, %ebx
	add  $1, %al
	sub  $1,%cx
	jne  loop	
	
#打印结束 暂时死循环在此
halt: 
	jmp halt

#下面是未完成的部分
idt:
.fill 256, 8, 0

idt_48:
	.word 256*8-1
	.long idt

setup_idt:
	

default_pro:
	push %ds
	pushl %eax 
	mov $0x10, %eax #让ds指向数据段
	mov %ax, %ds
	movl $67, %eax 
	call print 
	pop %eax 
	pop %ds
	iret 
sys_pro:
	push %ds
	pushl %edx 
	pushl %ecx
	pushl %ebx 
	pushl %eax 
	mov $0x10, %edx 
	mov %dx, %ds #al 传递打印字符串
	call print 
	pop %eax 
	pop %ebx 
	pop %ecx 
	pop %edx 
	pop %ds 
	iret 


