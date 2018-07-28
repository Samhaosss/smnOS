#ifndef _SCHE_H
#define _SCHE_H
#define  TASK_NM 26
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
typedef struct stack{
	long d[128];
} stack_sp[8];
#endif 
