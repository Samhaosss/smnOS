/*************************************************************************
    > File Name: sche.h
    > Author: sam
    > Created Time: 2018年08月01日 星期三 22时47分13秒
 ************************************************************************/
#ifndef _SCHE_H
#define _SCHE_H
#include<signal.h>
#include<head.h>

struct i387_struct {
	long	cwd;
	long	swd;
	long	twd;
	long	fip;
	long	fcs;
	long	foo;
	long	fos;
	long	st_space[20];	/* 8*10 bytes for each FP-reg = 80 bytes */
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
	struct i387_struct i387;
};

struct task_struct{
	long state;
	long pri;
	long count;
	unsigned long sigmap;
	struct sigaction sigaction[32];
	unsigned long block;
	int exit_code;
	/*mem info data
	 *...
	 * */
	long pid,father, pgrp, session, leader;
	unsigned long uid, euid, suid;
	unsigned long gid, egid, sgid;
	long alarm;
	/*
	 * time_use info 
	 * */
	unsigned short used_math;
	//int tty;
	/*
	 *fs
	 * */
	struct desc_struct ldt[3];
	struct tss_struct tss;
};

#define _TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
#define _LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))

#define switch_to(n) {	\
	struct {long a,b;} tmp;	\
	__asm__( "cmpl %%eax,current \n\t"	\
			"je 1f \n\t"	\
			"movw %%dx, %1 \n\t"	\
			"xchgl %%eax, current\n\t"	\
			"ljmp *%0 \n\r"	\
			"1:"	\
			::"m" (*&tmp.a),"m" (*&TMp.b),\
			"d" (_TSS(n)), "c" ((long)tasks[n]) );	\
}

#endif 

