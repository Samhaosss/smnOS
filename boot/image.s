.code32 
#这里将编写二十六任务轮流执行

#在实模式下的段表和中断表设置不足
#因此首先设置段表:
#	0	| 0 0 0 0			  |
#	1	| 00c0 9a00 0000 07ff |  --临时内核代码段	
#	2	| 00c0 9200 0000 07ff |	 --临时内核数据段
#	3	| 00c0 920b 8000 0002 |  --显存段
#	4	|        ldt0		  |  --所有任务共享一个ldt
#	5	|		 tss0		  |  --任务0tss
#	6	|		 tss1		  |  --任务1tss
#	7	|		 tss*...	  |	 --任务*ldt

#接着设置中断表
# 除 0x08、0x80中断为时钟和系统中断给予处理程序
# 其他所有中断使用默认处理程序

#最终程序内存布局如下:
#		| USER_STK1	|
#		| TASK1CODE |
#		| TASK0CODE	|
#		|___________|
#		|	TASK	|
#		|___________|
#		|	USTACK	|
#		|___________|
#		|	KSTACK	| --------->内核态堆栈
#		|___________|
#		|	LDT0	|
#		|___________|
#		|    TSS	|  -------->初始堆栈，后用于任务0用户态堆栈
#		|___________|
#		|	 GDT	|
#		|___________|
#		|	 IDT	|
#		|___________|		^
#		|	kernel	|		|
# 0x0000|	setup	|		|
#		|___________|		|

#本次的改动主要是 将gdt、idt设置代码用c实现，这样读起来比较舒服
#但是因为硬盘加载还是使用bios调用，因此减少了任务数量以减少整个程序的大小

#即将完成内核的中断处理和任务调度部分
#使用少数几个任务进行测试
#
#中断和系统调用将不会一次性完成，首先将完成框架，具体处理过程将在进一步的完善中完成
#
#本内核仍然未开启分页 仅仅在分段下 进行分时调度任务


.equ LTACH, 11930
.equ SCRNSEG, 0X18
.equ KCSEG, 0X08
.equ KDSEG, 0X10
.equ TSS0, 0X28 
.equ LDT0, 0X20 
.equ TSS1, 0x30
.equ LDT1, 0X38
.global setup, com_task, empty_tss, idt, gdt

#本程序的任务很简单，只是将未完成的GDT IDT地址加载，在检查A20，随即跳转c代码执行
#这里定义了很多数据，包括：GDT、idt、ldt0（共享）、TSS

.text 
setup:
	mov $0x10, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs 
#栈与数据段在同一段
	lss start_stack,%esp 
#	mov %ax, %ss 
#	movl $KSTACK+511, %esp  
	lidt idt_48 
	lgdt gdt_48 

#设置段表后，刷新段寄存器
	movl $0x10, %eax 
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	lss start_stack,%esp 
	xorl %eax, %eax 
1:
	incl %eax
	movl %eax, 0x000000
	cmpl %eax, 0x100000
	je 1b
#设置8253芯片，改变计数器发起中断频率
	movb $0x36, %al		#设置通道0工作在方式3、二进制计数
	movl $0x43, %edx	#8253控制寄存器写端口
	outb %al, %dx
	movl $LTACH, %eax
	movl $0x40, %edx 
	outb %al, %dx		# 设置通道0 频率为100HZ
	movb %ah, %al
	out %al, %dx 

to_c_code:
	pushl $0
	pushl $0
	pushl $0
	pushl $sys_die
	pushl $init
sys_die:
	jmp sys_die 

/*#设置8253芯片，改变计数器发起中断频率
	movb $0x36, %al		#设置通道0工作在方式3、二进制计数
	movl $0x43, %edx	#8253控制寄存器写端口
	outb %al, %dx
	movl $LTACH, %eax
	movl $0x40, %edx 
	outb %al, %dx		# 设置通道0 频率为100HZ
	movb %ah, %al
	out %al, %dx 
*/
#这里即将增加更多的set操作 内核的部分将用c语言完成

.align 8 
back_user_mode: 
#	接下来设置任务0的内核堆栈，模拟中断返回、
	pushfl 
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
	pushl $USTACK+511
	pushfl
	pushl $0x0f
	pushl $com_task
	iret

//这一部分将有更完善的中断、系统调用完成
#任务切换代码 方式与linux 0.11基本相似

.align 2
idt_48:
	.word 256*8-1
	.long idt
gdt_48:
	.word (end_gdt-gdt)-1
	.long gdt 
.align 2 
idt: .fill 256, 8, 0
#对于代码段，段描述符指明了其：界限-粒度、基址、存在、D（默认操作数）、特权、类型（读、执行、一致/非一致）
#对于数据段，段描述副指明了其：界限-粒度、基址、存在、B（堆栈指针SP/ESP，上界）、特权、类型（读、写、拓展方向）
gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a00000007ff
	.quad 0x00c09200000007ff
	.quad 0x00c0920b80000002
#	.word 0x40, ldt0, 0xe200, 0x0
#	.word 0x68, TASKS_TSS, 0xe900, 0x0
tss_dis:.fill 8, 8, 0
end_gdt:
.global empty_tss, tss_dis,idt
/*TASKS_TSS:
	.long 0 #back link
	.long KSTACK+512, 0x10 #esp0, ss0
	.long 0, 0, 0, 0, 0 #esp1, ss1, esp2, ss2 cr3
	.long 0, 0, 0, 0, 0 #eip efalg eax ecx edx 
	.long 0, 0, 0, 0, 0 #ebx esp ebp esi edi 
	.long 0, 0, 0, 0, 0, 0 #es cs ss ds fs gs 
	.long LDT0, 0x8000000 #ldt bitmap
empty_tss:
	.fill 8*104, 1, 0
	*/
//.align 2
/*ldt0:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff  #对应选择符:0x0f
	.quad 0x00c0f200000003ff 
*/
/*.global KSTACK, USTACK
#每个任务一个内核栈
KSTACK:
.fill 9*128*4, 1, 0
#KSTACK:
#	.long KSTACK
USTACK:
.fill 9*128*4, 1,  0
	*/
#所有的任务共享此代码
com_task:
	movl $0x17, %eax 
	mov %ax, %ds  #指向局部数据段
	mov %ax, %ss
	mov %ax, %es

	int $0x80
#	这里循环设置大一些便于查看调度结果 
	movl $0xFFFfff, %ecx
1:  loop 1b 
	jmp com_task


