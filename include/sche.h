#ifndef _SCHE_H
#define _SCHE_H

//#define  TASK_NM 26
#define TASK_RUNNING 0
#define TASK_INTERRUPTIBLE 1
#define TASK_UNINTERRUPTIBLE 2
#define TASK_ZOMBIE 3
#define TASK_STOPPED 4
struct i387_struct
{
	long cwd;			// 控制字(Control word)。
	long swd;			// 状态字(Status word)。
	long twd;			// 标记字(Tag word)。
	long fip;			// 协处理器代码指针。
	long fcs;			// 协处理器代码段寄存器。
	long foo;
	long fos;
	long st_space[20];		/* 8*10 bytes for each FP-reg = 80 bytes */
};

struct tss_struct {
	long	back_link;	/* 16 high bits zero */
	long	esp0;
	long	ss0;		/* 16 high bits zero */
	long	esp1;
	long	ss1;		/* 16 high bits zero */
	long	esp2;
	long	ss2;		/* 16 high bits zero */
	long	cr3;
	long	eip;
	long	eflags;
	long	eax,ecx,edx,ebx;
	long	esp;
	long	ebp;
	long	esi;
	long	edi;
	long	es;		/* 16 high bits zero */
	long	cs;		/* 16 high bits zero */
	long	ss;		/* 16 high bits zero */
	long	ds;		/* 16 high bits zero */
	long	fs;		/* 16 high bits zero */
	long	gs;		/* 16 high bits zero */
	long	ldt;		/* 16 high bits zero */
	long	trace_bitmap;	/* bits: trace 0, bitmap 16-31 */	
//	struct i387_struct i387; 
};


typedef struct gdtldtidt_struct {
	short a;
	short b;
	short c;
	short d;
} des_table[256];
extern des_table idt;


struct task_struct{
	unsigned long pid;
	unsigned long state;
	//used for schedule
	unsigned long counter;
	unsigned long pri;
	//no signal here
    struct gdtldtidt_struct ldt[3];
	struct tss_struct tss;
};
extern void com_task(void);
extern char user_stack[2][4096];

#define TASK0	\
{	0,0,15,15,	\
	{ {0,0,0,0},\
	  {0x03ff,0x0000,0xfa00,0x00c0},\
	  {0x03ff,0x0000,0xf200,0x00c0}	},	\
	{	0, &task0, 0x10,			\				
		0,0,0,0,0,	\
		&com_task,0x200,0,0,0,0,	\
		&(user_stack[0][4096-1]),0,0,0,	\
		0x17,0x0f,0x17,0x17,0x17,0x17,	\
		_LDT(0),	0x8000000	\
	}}

#define TASK1 	\
{	0,0,15,15,	\
	{ {0,0,0,0},\
	  {0x07ff,0x0000,0xfa00,0x00c0},\
	  {0x07ff,0x0000,0xf200,0x00c0}	},	\
	{	0, &task1, 0x10,			\				
		0,0,0,0,0,	\
		&com_task,0x200,0,0,0,0,	\
		&user_stack[1][4096-1],0,0,0,	\
		0x17,0x0f,0x17,0x17,0x17,0x17,	\
		_LDT(1),	0x8000000	\
	}	\
}

#define FIRST_LDT 4
#define FIRST_TSS 5

//第n个ldt的选择子
#define _LDT(n)	( (((unsigned long)n)<<4)+ (FIRST_LDT<<3)) 
#define _TSS(n) ( ( ((unsigned long)n)<<4 )+(FIRST_TSS<<3))

#define ltr(n) __asm__("ltr %%ax\n\t"::"a" (_TSS(n)))
#define lldt(n) __asm__("lldt %%ax\n\t"::"a" (_LDT(n)))

#define switch_to(n) {\
struct {long a,b;} __tmp; \
__asm__("cmpl %%ecx,current\n\t" \
	"je 1f\n\t" \
	"movw %%dx,%1\n\t" \
	"xchgl %%ecx,current\n\t" \
	"ljmp *%0\n\t" \
	"1:" \
	::"m" (*&__tmp.a),"m" (*&__tmp.b), \
	"d" (_TSS(n)),"c" ((long) tasks[n])); \
}





typedef int (*fptr)();

#endif 
