.code32 

.global hd_intr_no_error, hd_intr_error 

#随后可能会添加相应的中断处理
hd_intr_no_error:
	pushl $die 

no_error_code:
	xchagl %eax, (%esp)
	pushl %ebx
	pushl %ecx 
	pushl %edx
	pushl %edi
	pushl %esi 
	pushl %ebp
	push %ds
	push %es
	push %fs
	push %gs 
	pushl $0	;error code 
	lea 44(%esp), %edx
	pushl %edx 
	movl $0x10, %edx 
	mov %dx, %ds
	mov %dx, %es
	mov %dx, %fs 
	call *%eax
	addl $8, %esp
	push %gs 
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	iret 

die:
	jmp die 

reserve:
	pushl $do_reserve;
	jmp no_error_code 

do_reserve:
	ret 

hd_intr_error:
	pushl $write_char 
error_code:
	xchgl %eax,4(%esp)		# error code <-> %eax
	xchgl %ebx,(%esp)		# &function <-> %ebx
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %esi
	pushl %ebp
	push %ds
	push %es
	push %fs
	push %gs 
	pushl %eax			# error code
	lea 44(%esp),%eax		# offset
	pushl %eax
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov $68, %dl 
	call *%ebx
	addl $8,%esp
	pop %gs 
	pop %fs
	pop %es
	pop %ds
	popl %ebp
	popl %esi
	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	iret

