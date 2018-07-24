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



#现在尝试在setup中 添加0号init任务，用于创建26和任务
#每个任务 有自己的LDT TDD KSTACK USTACK , 利用分段，进行任务之间的隔离
#26个任务会分别输出A～Z

.equ LTACH, 11930
.equ SCRNSEG, 0X18
.equ KCSEG, 0X08
.equ KDSEG, 0X10
.equ TSS0, 0X28 
.equ LDT0, 0X20 
.equ TSS1, 0x30
.equ LDT1, 0X38
.equ LOWRNG, 0x1f
.text 
setup:
	mov $0x10, %ax
	mov %ax, %ds
#	lss KSTACK , %esp
#栈与数据段在同一段
	mov %ax, %ss
	movl $KSTACK, %esp  

	call setLdt
	call setGdt
#设置段表后，刷新段寄存器
	movl $0x10, %eax 
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	movl $KSTACK, %esp  

#设置8253芯片，改变计数器发起中断频率
	movb $0x36, %al		#设置通道0工作在方式3、二进制计数
	movl $0x43, %edx	#8253控制寄存器写端口
	outb %al, %dx
	movl $LTACH, %eax
	movl $0x40, %edx 
	outb %al, %dx		# 设置通道0 频率为100HZ
	movb %ah, %al
	out %al, %dx 

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
	lea idt(,%ecx,8), %esi 
	movl %eax, (%esi)
	movl %edx, 4(%esi)

#需要debug gdt更新存在问题
init_task:
	#创建25组 TSS及其描述符 分配堆栈
	lea tss_dis, %esi #set tss discriptor  
	lea empty_tss, %edi #set tss 
	movl KSTACK, %edx
	sub $512, %edx
	movl %edx, KSTACK 
	movl USTACK, %edx
	sub $512, %edx
	mov %edx, USTACK 

	mov $25, %cx
do_init:
	mov $0x00680000, %edx 
	mov %di, %dx
	movl %edx, (%esi)
	add $4, %esi 
	movl $0xe9000000, %edx 
	mov %edx, (%esi)
	add $4, %esi 

	movl KSTACK, %edx
	movl %ecx, (%edx)

	movl %edx, 4(%edi)
	sub $512, %edx
	movl %edx, KSTACK 
	movl $0x10, %edx
	movl %edx, 8(%edi)
	movl $task, %edx
	movl %edx, 32(%edi)
	movl $0x200, %edx
	movl %edx,36(%edi)
	movl USTACK, %edx 
	movl %edx, 56(%edi)
	sub  $512, %edx
	movl %edx, USTACK 
	movl $0x17, %edx 
	movl %edx, 72(%edi)
	movl $0x0f, %edx
	movl %edx, 76(%edi)
	mov $0x17, %edx 
	mov %edx, 80(%edi)
	mov %edx, 84(%edi) 
	mov %edx, 88(%edi) 
	movl %edx,92(%edi)
	mov	$LDT0, %edx 
	mov %edx, 96(%edi)
	mov $0x8000000,%edx
	mov %edx,100(%edi) 
	add $104, %edi
	dec %ecx
	jne do_init  

back_user_mode:
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
	pushl $USTACK 
	pushfl 
	pushl $0x0f
	pushl $task
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
	movl $67, %eax
	call write_char 
	popl %eax 
	pop %ds
	iret 
.align 2 
#任务切换代码 方式与linux 0.11基本相似
selector:
	.long TSS0 
#这里还未更新
timer_interrupt:
	push %ds
	pushl %eax 
	#pushl %ebx 
	pushl %ebx 
	movl $0x10, %eax 
	mov %ax, %ds
	movb $0x20, %al		#允许其他硬件中断
	outb %al, $0x20

	mov $64, %eax 
	call write_char 
	mov current, %ebx 
	cmpl %eax, %ebx
	jne next 
	mov $0, %ebx 
	mov %ebx, current 
	ljmp $0x28, $0
	jmp back
next:
	mov $1,%ebx
	mov %ebx,current 
	ljmp $0x30, $0
back:
	popl %ebx
	popl %eax 
	pop %ds 
#	mov current,%ebx 
#	mov $25, %eax
#	cmpl %eax, %ebx  
#	jne next
#	mov $0, %ebx 
#next :
#	mov %ebx, %eax
#	add $1, %ebx
#	mov %ebx, current 
#	sub $1, %eax 
/*	shl $3, %eax 
	addl $TSS0, %eax
	
	ljmp $0x30, $0
	popl %ebx 
	popl %eax 
	pop %ds
*/	
	iret 

#.align 2 
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

current :
	.long 0
screem_location:
	.long 0

#.align 2
idt_48:
	.word 256*8-1
	.long idt

gdt_48:
	.word (end_gdt-gdt)-1
	.long gdt 


.align 2 
idt : .fill 256, 8, 0
#对于代码段，段描述符指明了其：界限-粒度、基址、存在、D（默认操作数）、特权、类型（读、执行、一致/非一致）
#对于数据段，段描述副指明了其：界限-粒度、基址、存在、B（堆栈指针SP/ESP，上界）、特权、类型（读、写、拓展方向）

gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a00000007ff
	.quad 0x00c09200000007ff
	.quad 0x00c0f20b80000002
	.word 0x40, ldt0, 0xe200, 0x0
	.word 0x68, TASKS_TSS, 0xe900, 0x0
	.word 0x68, TASKS_TSS, 0xe900, 0x0
tss_dis:.fill 25, 8, 0
end_gdt:

TASKS_TSS:
	.long 0 #back link
	.long KSTACK, 0x10 #esp0, ss0
	.long 0, 0, 0, 0, 0 #esp1, ss1, esp2, ss2 cr3
	.long 0, 0, 0, 0, 0 #eip efalg eax ecx edx 
	.long 0, 0, 0, 0, 0 #ebx esp ebp esi edi 
	.long 0, 0, 0, 0, 0, 0 #es cs ss ds fs gs 
	.long LDT0, 0x8000000 #ldt bitmap
empty_tss:
	.fill 25*104, 1, 0
.align 2 
ldt0:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff  #对应选择符:0x0f
	.quad 0x00c0f200000003ff 
#每个任务一个内核栈
.fill 26*128*4, 1, 0
KSTACK:
	.long KSTACK 

.fill 26*128*4, 1,  0
USTACK:
	.long USTACK 
	
#所有的任务共享此代码
task:
	movl $0x17, %eax 
	mov %ax, %ds  #指向局部数据段
	mov $65, %al
#	int $0x80
	call write_char 
	movl $0xfff, %ecx
1:  loop 1b 
	jmp task


