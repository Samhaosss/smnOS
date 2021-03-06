/*************************************************************************
    > File Name: trap.c
    > Author: sam
    > Created Time: 2018年08月02日 星期四 18时00分35秒
 ************************************************************************/

#include<sys.h>
#include<sche.h>
#include<io.h>

extern void time_interrupt(void);
extern void hd_intr_no_error(void);
extern void hd_intr_error(void);
extern void system_call(void);
extern void reserve(void);

//这里应该实现中断处理过程，但因为缺少


void trap_init(void){
	int i=0;
	for(;i<17;i++)
		_set_trap_gate(i,&hd_intr_no_error); //目未使用error code
	for(i=17;i<48;i++)
		_set_trap_gate(i,&reserve);
	for(i=48;i<256;i++)
		_set_trap_gate(i,&reserve);
	_set_intr_gate(0x8,&reserve);
	//outb(inb_p(0x21)&~0x01,0x21);
	_set_sys_gate(0x80,&system_call);
//	_set_sys_gate(0x80,&system_call);
//	_set_trap_gate(0x20,&reserve);
	//outb_p(inb_p(0x21)&0xfb,0x21);
	//outb(inb_p(0xA1)&0xdf,0xA1);
}




