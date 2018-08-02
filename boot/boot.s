
.code16
.global BOOT

#SEG:OFFSET 
#这里很重要，x86开始处于实模式，
.equ SYSSIZE, 0X3000
.equ SETUPLEN, 4
.equ BOOTSEG, 0X7c0 
.equ SETUPSEG, 0X9020
.equ OFFSET, 0X0000
.equ SEG, 0x9000
.equ IMAGESEG, 0X1000
.equ ENDSEG, IMAGESEG+ SYSSIZE

.text
#成功加载boot后boot会打印输出
#随后 boot将自己转移至0x90000 并跳转
#接着boot将setup加载入内存0x90200 并跳转
#setup 成功加载后 会打印输出
#如果成功 会有三次打印

# 1)清除流水线缓存
# 2) cs:0x7c00 ip:0000
ljmp $BOOTSEG, $SELFMOV

SELFMOV:
	#这里将自己移动到0x9000:0000
	#使用重复移动指令 从DS:SI 移动到 ES:DI			
	mov $BOOTSEG, %ax
	mov %ax, %ds
	sub %si, %si

	mov $SEG, %ax 
	mov %ax, %es
	sub %di, %di
	#boot只有512 每次移动word因此设置c为256x
	mov $256, %cx
	rep movsd

	ljmp $SEG,$AFTERMOV 

AFTERMOV:
    mov	%cs, %ax		#将ds，es，ss都设置成移动后代码所在的段处(0x9000)
	mov	%ax, %ds
	mov	%ax, %es
# put stack at 0x9ff00.
	mov	%ax, %ss
	mov	$0xFF00, %sp
	call print 
load_setup:
	#选择磁头 扇区
	mov $0x0000, %dx
	mov $0x0002, %cx	#扇区从1开始，柱面、盘片从0开始
	
	#设置load的物理地址，这里还在实模式
	mov $SETUPSEG, %ax
	mov %ax, %es
	mov $OFFSET, %bx
	
	mov $0x02, %ah
	mov $4, %al  #读取扇区数
	int $0x13
	
	jnc load_sys
dies:	jmp dies


load_sys:

    mov	$0x00, %dl
	mov	$0x0800, %ax		# AH=8 is get drive parameters
	int	$0x13
	mov	$0x00, %ch
	#seg cs
	mov	%cx, %cs:sectors+0	# %cs means sectors is in %cs
	mov	$SEG, %ax
	mov	%ax, %es

    mov	$IMAGESEG, %ax
	mov	%ax, %es		# segment of 0x010000
	call	read_it
	call	kill_motor

#load_sys:
/*	mov $0x0000, %dx
	mov $0x0006, %cx
	mov $IMAGESEG, %ax
	mov %ax, %es 
	mov $0x0, %bx 
	mov $0x02, %ah
	mov $64, %al
	int $0x13
	jnc load_ok
*/
//die_sys:jmp die_sys

#ljmp实现段间跳转
#jmp
load_ok:
	#设置数据段
	ljmp $SETUPSEG, $OFFSET
	#长跳转到demo程序


sread:	.word 1+ SETUPLEN	# sectors read of current track
head:	.word 0			# current head
track:	.word 0			# current track

read_it:
	mov	%es, %ax
	test	$0x0fff, %ax
die:	jne 	die			# es must be at 64kB boundary
	xor 	%bx, %bx		# bx is starting address within segment
rp_read:
	mov 	%es, %ax
 	cmp 	$ENDSEG, %ax		# have we loaded all yet?
	jb	ok1_read
	ret
ok1_read:
	#seg cs
	mov	%cs:sectors+0, %ax
	sub	sread, %ax
	mov	%ax, %cx
	shl	$9, %cx
	add	%bx, %cx
	jnc 	ok2_read
	je 	ok2_read
	xor 	%ax, %ax
	sub 	%bx, %ax
	shr 	$9, %ax
ok2_read:
	call 	read_track
	mov 	%ax, %cx
	add 	sread, %ax
	#seg cs
	cmp 	%cs:sectors+0, %ax
	jne 	ok3_read
	mov 	$1, %ax
	sub 	head, %ax
	jne 	ok4_read
	incw    track
ok4_read:
	mov	%ax, head
	xor	%ax, %ax
ok3_read:
	mov	%ax, sread
	shl	$9, %cx
	add	%cx, %bx
	jnc	rp_read
	mov	%es, %ax
	add	$0x1000, %ax
	mov	%ax, %es
	xor	%bx, %bx
	jmp	rp_read

read_track:
	push	%ax
	push	%bx
	push	%cx
	push	%dx
	mov	track, %dx
	mov	sread, %cx
	inc	%cx
	mov	%dl, %ch
	mov	head, %dx
	mov	%dl, %dh
	mov	$0, %dl
	and	$0x0100, %dx
	mov	$2, %ah
	int	$0x13
	jc	bad_rt
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	ret
bad_rt:	mov	$0, %ax
	mov	$0, %dx
	int	$0x13
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	jmp	read_track

	
print:
	mov $0x03, %ah
	int $0x10

	#指定字符串地址
	mov $0, %ah
	mov $BOOTSEG, %ax
	mov %ax, %es
	mov $string, %bp
	#设定输出模式，调用功能号
	mov $0x1301, %ax 
	mov $0x0007, %bx
	mov $11, %cx
	int $0x10
	ret 

string:
	.ascii "hello 80x86"


.org 510 
.word 0xAA55
