.code32 
#这里将编写两个任务轮流执行的demo 
#在实模式下的段表和中断表设置不足
#因此首先设置段表:
#	0	| 0 0 0 0 |
#	1	| 00c0 9a00 0000 07ff |  --临时内核代码段	
#	2	| 00c0 9200 0000 07ff |	 --临时内核数据段
#	3	| 00c0 920b 8000 0002 |  --显存段
#	4	|        tss0		  |  --任务0tss
#	5	|		 ldt0		  |  --任务0ldt
#	6	|		 tss1		  |  --任务1tss
#	7	|		 ldt1		  |	 --任务1ldt

#接着设置中断表
# 除 0x08、0x80中断为时钟和系统中断给予处理程序
# 其他所有中断使用默认处理程序

#最终程序内存布局如下:
#		| USER_STK1	|
#		| TASK1CODE |
#		| TASK0CODE	|
#		|___________|
#		|	KRN_STK	|
#		|   TSS1	|
#		|	LDT1	|
#		|___________|
#		|	KRNSTK0	| --------->内核态堆栈
#		|	TSS0	|
#		|	LDT0	|
#		|___________|
#		| INITSTACK	|  -------->初始堆栈，后用于任务0用户态堆栈
#		|___________|
#		|	 GDT	|
#		|___________|
#		|	 IDT	|
#		|___________|		^
#		|			|		|
# 0x0000|	setup	|		|
#		|___________|		|


.equ LTACH, 11930
.equ SCRNSEG, 0X18
.equ KCSEG, 0X08
.equ KDSEG, 0X10
.equ TSS0, 0X20
.equ LDT0, 0X28
.equ TSS1, 0x30
.equ LDT1, 0X38

.text 

setup:
	lss init_stack, %esp

	call setGdt
	call setLdt
#设置段表后，刷新段寄存器
	mov $KDSEG, %eax 
	mov %eax, %ds
	mov %eax, %es
	mov %eax,%fs
	mov %eax, %gs
	lss init_stack, %esp
#设置8253芯片，改变计数器发起中断频率
	movb $0x36, %al		#设置通道0工作在方式3、二进制计数
	movl $0x43, %edx	#8253控制寄存器写端口
	outb %al, %dx
	movl $LTACH, %eax
	movl $0x40, %edx 
	outb %al, %dx		# 设置通道0 频率为100HZ
	movb %ah, %al
	out %al, %dx 

	die: jmp die
#接下来设置指定中断处理程序:0x80 0x08
	#0x08 timmer_interrupt 
	movl $0x00080000, %eax #设置中断门  高位为内核代码段选择符
	movw $timer_interrupt, %ax #中断处理程序地址
	movw $0x8E00, %dx		#中断类型为14：可屏蔽、ring0使用
	movl $0x08, %ecx		#8号中断
	lea idt(,%ecx,8), %esi  #IDT描述符8号地址放入esi,用于设置
	movl %eax, (%esi)
	movl %edx, 4(%esi)
	#0x80 sys_interrupt
	movw $sys_interrupt, %ax
	movw $0xef00, %dx
	movl $0x80, %ecx
	lea idt(,%ecx,8), %edi 
	movl %eax, (%esi)
	movl %edx, 4(%esi)

#	接下来设置任务0的内核堆栈，模拟中断返回、
	pushfl		#复位标志寄存器 嵌套任务标志
	andl $0xffffbfff, (%esp)
	popfl

	movl $TSS0, %eax
	ltr %ax
	movl $LDT0, %eax 
	lldt %ax
	movl $0, current #保存0到current 变量
	sti

#	| 0x17	|	---> ss	
#	| init_s|	---> esp
#	| eflags|	---> eflags
#	| $0x0f	|	---> cs
#	| $ts0	|	---> EIP

	pushl $0x17
	pushl $init_stack 
	pushfl 
	pushl $0x0f
	pushl $task0
	iret 
setGdt:
	lgdt gdt_48
	ret
setLdt:
	lea default, %edx
	movl $0x00080000, %eax 
	movw %dx, %ax
	movw $0x8e00, %dx
	lea idt, %edi 
	mov $256, %ecx
do_set_idt:
	movl %eax, (%edi)
	movl %edx, 4(%edi)
	addl $8, %edi
	dec %ecx
	jne do_set_idt
	lidt idt_48
	ret 
write_char:
	push %gs
	pushl %ebx
	mov $SCRNSEG, %ebx 
	mov  %bx, %gs
	movl screem_location, %ebx
	shl $1, %ebx 
	movb %al, %gs:(%ebx)
	shr $1, %ebx 
	incl %ebx 
	cmpl $2000, %ebx 
	jb 1f
	movl $0, %ebx
1:
	movl %ebx, screem_location 
	popl %ebx 
	pop %gs
	ret 
.align 2 
default:
	push %ds
	pushl %eax
	movl $0x10, %eax 
	mov %ax, %ds
	mov $67, %ax
	call write_char 
	popl %eax 
	pop %ds
	iret 
.align 2 
#任务切换代码 方式与linux 0.11基本相似
timer_interrupt:
	push %ds
	pushl %eax 
	movl $0x10, %eax 
	mov %ax, %ds
	movb $0x20, %al		#允许其他硬件中断
	outb %al, $0x20
	movl $1, %eax		#判断当前是那个任务
	cmpl %eax, current 
	je 1f
	movl %eax, current
	ljmp $TSS1, $0
	jmp 2f
1:
	movl $0, current
	ljmp $TSS0, $0
2:
	popl %eax 
	pop %ds
	iret 

.align 2 
sys_interrupt:
	push %ds
	pushl %edx
	pushl %ecx 
	pushl %ebx 
	pushl %eax 
	movl $0x10, %edx
	mov %dx, %ds
	call write_char
	popl %eax 
	popl %ebx
	popl %ecx 
	popl %edx 
	pop %ds
	iret 


#----------------------------------

current :
	.long 0
screem_location:
	.long 0

.align 2
idt_48:
	.word 256*8-1
	.long idt

gdt_48:
	.word (end_gdt-gdt)-1
	.long gdt 


.align 2 
idt : .fill 256, 8, 0

gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a00000007ff
	.quad 0x00c09200000007ff
	.quad 0x00c0920b80000002
	.word 0x68, tss0, 0xe900, 0x0
	.word 0x40, ldt0, 0xe200, 0x0
	.word 0x68, tss1, 0xe900, 0x0
	.word 0x40, ldt1, 0xe200, 0x0
end_gdt:

.fill 128, 4, 0

init_stack:
	.long init_stack
	.word 0x10
.align 2 
ldt0:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff  #对应选择符:0x0f
	.quad 0x00c0f200000003ff	
tss0:
	.long 0 #back link
	.long krn_stk0, 0x10 #esp0, ss0
	.long 0, 0, 0, 0, 0 #esp1, ss1, esp2, ss2 cr3
	.long 0, 0, 0, 0, 0 #eip efalg eax ecx edx 
	.long 0, 0, 0, 0, 0 #ebx esp ebp esi edi 
	.long 0, 0, 0, 0, 0, 0 #es cs ss ds fs gs 
	.long LDT0, 0x8000000 #ldt bitmap
	
.fill 128,4,0
krn_stk0:

.align 2 
ldt1:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff  #对应选择符:0x0f
	.quad 0x00c0f200000003ff	
tss1:
	.long 0 #back link
	.long krn_stk1, 0x10 #esp0, ss0
	.long 0, 0, 0, 0, 0 #esp1, ss1, esp2, ss2 cr3
	.long task1, 0x200 #eip eflags
	.long 0, 0, 0, 0 # eax ecx edx  ebx
	.long usr_stk1, 0, 0, 0 # esp ebp esi edi 
	.long 0x17, 0x0f, 0x17,0x17, 0x17, 0x17 #es cs ss ds fs gs 
	.long LDT1, 0x8000000 #ldt bitmap
	
.fill 128,4,0
krn_stk1:

task0:
	movl $0x17, %eax 
	mov %ax, %ds  #指向局部数据段
	mov $65, %al
	int $0x80
	movl $0xfff, %eax
1:  loop 1b 
	jmp task0

task1 :
#	movl $0x17, %eax 
#	mov %ax, %ds  #指向局部数据段
	mov $66, %al
	int $0x80
	movl $0xfff, %eax
1:  loop 1b 
	jmp task1
	
	.fill 128,4,0
usr_stk1:























































	

