#ifndef _SYS_H
#define _SYS_H
#define lidt() __asm__ ( "lidt idt_48\n\t"::)
#define lgdt() __asm__ ("lgdt gdt_48\n\t"::)
#define sti() __asm__ ("sti\n\r"::)
#define cli() __asm__ ("cli\n\r"::)
/*
 * movl $0x28, %%eax\n\t"	\
		"ltr %ax\n\t "	\
		"movl $0x20, %%eax\n\t"	\
		"lldt %%ax\n\t"	\
		"sti\n\t"	\
 * */
#define kmode_to_umode ()	\
	__asm__ (  "sti \n\t"	\
		"movl %%esp, %%eax\n\t" \
		"pushl $0x17 \n\t"	\
		"pushl %%eax \n\t"	\
		"pushfl\n\t"	\
		"pushl $0x0f\n\t"	\
		"pushl $1f\n\t"	\
		"iret\n\t"	\
		"1:\tmovl $0x17, %%eax \n\t"	\
		"movw %%ax, %%ds\n\t"	\
		"movw %%ax, %%es\n\t"	\
		"movw %%ax, %%fs\n\t"	\
		"movw %%ax, %%gs\n\s"	\
		:::"ax"	)

#define _set_gate(gate_add, type, dpl, add)	\
	__asm__("movw %%dx, %%ax\n\t"	\
			"movw %0, %%dx \n\t"	\
			"movl %%eax, %1\n\t"	\
			"movl %%edx, %2\n\t"	\
			:	\
			: "i" ( (short) (0x8000+(dpl<<13)+ (type<<8) )),	\
			  "o" ( *( (char*)(gate_add)) ),		\
			  "o" ( *( 4 + (char*)(gate_add) ) ),	\
			  "d" ( (char*)(add) ), "a" (0x00080000)	)

#define _set_trap_gate( n, add )\
	_set_gate(&idt[n], 14, 0, add)
#define _set_sys_gate( n, add )	\
	_set_gate(&idt[n],15, 3, add)

#define _set_seg_des( gate_add, type, dpl, base, limit ) {\
	*(gate_add) = ((base)&0xff000000 ) |	\
	( ( (base)&0x00ff0000 ) >> 16 ) |	\
	( (limit)&0xf0000 )	|	\
	( (dpl)<< 13 ) |	\
	( 0x00408000) |	\
	( (type) << 8) ;	\
	*((gate_add)+1) = ( ( (base) & 0x0000ffff) << 16 ) |	\
	( (limit)& 0x0ffff );}


#define _set_tssldt_desc(n,addr,type) \
	__asm__ ("movw $104,%1\n\t" \
	"movw %%ax,%2\n\t" \
	"rorl $16,%%eax\n\t" \
	"movb %%al,%3\n\t" \
	"movb $0x89,%4\n\t" \
	"movb $0x00,%5\n\t" \
	"movb %%ah,%6\n\t" \
	"rorl $16,%%eax" \
	::"a" (addr), "m" (*(n)), "m" (*(n + 2)), "m" (*(n + 4)), \
	 "m" (*(n + 5)), "m" (*(n + 6)), "m" (*(n + 7)) )

#define _set_tss_desc(n,addr) _set_tssldt_desc(((char *) (n)),((unsigned long )(addr)),(char)0x89)



extern long LDT0;


#endif 
