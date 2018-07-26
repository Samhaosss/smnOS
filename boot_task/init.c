/*************************************************************************
    > File Name: init.c
    > Author: sam
    > Mail: sunhaoyl@outlook.com
    > Created Time: 2018年07月26日 星期四 21时58分17秒
 ************************************************************************/
#include"../include/sys.h"
#include"../include/sche.h"


//这里需要设置GDT IDT


void ldt_init(void){
	int i=0;
	for(;i<256;i++)
		_set_trap_gate(i, &default_pro);
	_set_trap_gate(7,&timer_interrupt);
	_set_trap_gate(0x80-1, &sys_interrupt);
}

void gdttss_init(void){
	int i=0;
	for(;i<TASK_NM-1;i++){
		set_tss_desc(&(tss_dis[i]), &(empty_tss[i]));
		empty_tss[i].esp0= &(KSTACK[i+1]);
		empty_tss[i].ss0=0x10;
		empty_tss[i].eip=&(com_task);
		empty_tss[i].eflags=0x200;
		empty_tss[i].esp=&(USTACK[i+1]);
		empty_tss[i].cs= 0x0f;
		empty_tss[i].ds=empty_tss[i].ss=empty_tss[i].fs=empty_tss[i].gs=empty_tss[i].es=0x17;
		empty_tss[i].ldt= LDT0;
		empty_tss[i].trace_bitmap=0x8000000;
	}
}

void main(){
	ldt_init();
	gdttss_init();
}


