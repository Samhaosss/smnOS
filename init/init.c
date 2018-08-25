/*************************************************************************
    > File Name: init.c
    > Author: sam

    > Mail: sunhaoyl@outlook.com
    > Created Time: 2018年07月26日 星期四 21时58分17秒
 ************************************************************************/
#include<sys.h>
#include<sche.h>





//这里需要设置GDT IDT

void default_pro(void);
void timer_interrupt(void);
void sys_interrupt(void);
void com_task(void);
/*
void idt_init(void){
	int i=0;
	for(;i<256;i++)
		_set_trap_gate(i, &default_pro);
	_set_trap_gate(8,&timer_interrupt);
	_set_sys_gate(0x80, &sys_interrupt);
}
*/
//void gdt_init(void){
//	int i=0;
//	for(;i<8;i++){
//	//	_set_tss_desc(&(tss_dis[i]), &(empty_tss[i]));
//		tss_dis[i].a = 0x68;
//		tss_dis[i].b =(short)(&empty_tss[i]);
//		tss_dis[i].c = 0xe900;
//		tss_dis[i].d = 0;
//
//		empty_tss[i].esp0 = (long)(&(KSTACK[i+1]))+511;
//		empty_tss[i].ss0=0x10;
//		empty_tss[i].eip= (long)(&(com_task));
//		empty_tss[i].eflags=0x200;
//		empty_tss[i].esp= (long)(&(USTACK[i+1])) + 511;
//		empty_tss[i].cs= 0x0f;
//		empty_tss[i].ds=empty_tss[i].ss=empty_tss[i].fs=empty_tss[i].gs=empty_tss[i].es=0x17;
//		empty_tss[i].ldt= 0x20;
//		empty_tss[i].trace_bitmap=0x8000000;
//	}
//}

void init(void){

	trap_init();
	sche_init();
	sti();
	kmode_to_umode();
	com_task();
}


>>>>>>> exp
