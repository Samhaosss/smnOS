.code32
/*
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
*/
.text 
.global gdt, idt, pg_dri,tmp_floppy_area
pg_dir:
start:
#这里重新这支GDT IDT
	movl $0x10, %eax
	mov %ax, %ds
	lss stack_start,%esp
	call setup_idt
	call setup_gdt

	movl $0x10, %eax 
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs 
	lss stack_start, %esp  #此堆栈用于setup的临时堆栈，用于任务0的用户堆栈
#check a20 gate 
	xorl %eax, %eax 
1:
	incl %eax 
	movl %eax, 0x000000
	cmp %eax,  0x100000
	je 1b 
#检查数学协处理器
	movl %cr0, %eax 
	andl $0x80000011, %eax 
	orl $2, %eax 
	movl %eax, %cr0
	call check_x87
	jmp after_page_table 


check_x87:
	#之后补充
	ret 

setup_idt:
	#接下来构造默认的中断描述符
	lea default, %edx 
	movl $0x00080000, %eax 
	mov %dx, %ax
	mov $0x8e00, %dx
	
	lea idt, %edi 
	movl $256, %ecx 
do_set:
	movl %eax, (%edi)
	movl %edx, 4(%edi)
	addl $8, %edi
	dec %ecx 
	jne do_set 
	lidt idt_48
	ret 

setup_gdt:
	lgdt gdt_48
	ret 
#接下来填充4个页表，以上代码会被填充作唯一俄页目录
.org 0x1000
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000

tmp_floppy_area:
.fill 1024, 1, 0

#默认中断处理程序需要放在页表后否则会被覆盖
default_msg:
 .asciz "Bad interrupt\n\r"
.align 2 
default:
	pushl %eax 
	pushl %ecx
	pushl %edx 
	push %ds
	push %es
	push %fs
	movl $0x10, %eax 
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	pushl $default_msg  #由内核专用print
	call printk 
	pop %fs
	pop %es 
	pop %ds 
	popl %edx 
	popl %ecx 
	popl %eax 
	iret 

#经过set 后 以上部分 全用作内核将来会用到的数据，无用的代码被填充
after_page_table :
	#接下来开启分页，设置页目录、页表，向堆栈push argc argv 返回地址
	pushl $0
	pushl $0
	pushl $0
	pushl $die 
	pushl $main #下面会用此地址进入c程序
	jmp setup_paging
die:
	jmp die			#如果main返回了则die 

setup_paging:
	movl $1024*5, %ecx
#先设置页目录
	xorl %eax, %eax 
	xorl %edi, %edi 
	cld;rep;stosl
	movl $pg0+7, pg_dir
	movl $pg1+7, pg_dir+4
	movl $pg2+7, pg_dir+8
	movl $pg3+7, pg_dir+12 
#接下来设置 页表，从高地址到低地址
	movl $pg3+4092, %edi	
	movl $0xfff007, %eax 
	std
1:
	stosl
	subl $0x1000, %eax 
	jge 1b
	cld
	xorl %eax, %eax 
	movl %eax, %cr3  #page dir add
	movl %cr0, %eax 
	orl $0x80000000, %eax 
	movl %eax, %cr0 
	ret  #开始执行c代码 main 



.align 2
.word 0
idt_48 :
	.word 258*8-1
	.long idt 
.align 2
.word 0 
gdt_48:
	.word 256*8-1
	.long gdt 
.align 8 
idt:
.fill 256, 8, 0

gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a0000000fff
	.quad 0x00c0920000000fff
	.quad 0x0000000000000000
empty_gdt:
	.fill 252, 8, 0
