.code32
.global  system_call,time_interrupt,write_char

.equ NR_CALL,2

bad_syscall:
	mov $-1, %eax 
	iret 

system_call:
	cmpl $NR_CALL-1, %eax 
	ja bad_syscall 
	push %ds
	push %es
	push %fs
	push %gs
	#参数传递顺序
	pushl %edx
	pushl %ecx
	pushl %ebx
	movl $0x10, %ebx
	mov %bx, %ds
	mov %bx, %es
	#用户态数据段
	movl $0x17, %edx
	mov %dx, %fs

	call *system_call_table(,%eax,4)
	#目前并不准备加入信号处理，否则系统调用返回时应该检查当前进程信号位图
ret_from_system_call:
	popl %ebx
	popl %ecx
	popl %edx 
	pop %gs
	pop %fs
	pop %Es
	pop %ds
	iret 
	
.equ SCRNSEG,0x18
screem_location:
	.long 0
.align 2 
write_char:

	movl $SCRNSEG, %ebx
	mov %bx, %gs
	movl screem_location, %eax
	shl $1, %eax
	movl 4(%esp), %ebx
	movb %bx, %gs:(%eax)
	shr $1, %eax
	incl %eax 
	cmpl $2000, %eax 
	jb 1f
	movl $0, %eax 
1:
	mov %eax, screem_location
	movl $1, %eax
	ret 


time_interrupt:
	push %ds
	push %es
	push %fs
	push %gs
	pushl %edx 
	pushl %ecx
	pushl %ebx
	pushl %eax 
	movl $0x10, %eax 
	mov %ax, %ds
	mov %ax, %es
	mov $0x17, %ax
	mov %ax, %fs
	movb $0x20, %al
	outb %ax, $0x20
	call schedule
	popl %eax 
	jmp ret_from_system_call 


	

