/*************************************************************************
    > File Name: sche.c
    > Author: sam
    > Created Time: 2018年08月02日 星期四 21时06分16秒
 ************************************************************************/
#include<sche.h>
#define NR_TASK 2

//这里是汇编设置的数据，gdt中有系统用的四个描述符
//tss为空 ldt0以后可能会用到
extern des_table gdt[12];
//extern struct tss_struct TASKS_TSS[8];
//extern des_table ldt0[3];

//将每个任务的task_struct与内核栈放在一起
union task_union{
	struct task_struct task;
	char stack[4096];
};

//这一部分的核心数据为 两个任务的task_struct和内核栈的union,两个用户堆栈，以及一个长指针

union task_union task0={TASK0,};
union task_union task1={TASK1,};

struct task_struct *tasks[NR_TASK]={&task0.task,$task1.task,};
struct task_struct* current=task[0];

char user_stack[2][4096];

//这里用作堆栈相关寄存器的加载，任务0的用户栈和内核初始化期间使用的临时堆栈
struct {
	long *a;
	short b;
} start_stack = { &user_stack[0][4096-1], 0x10 };

#define LDTDIS 0
#define TSSDIS 1

static inline void set_gdt (short addr,short n, short type){
	gdt[n].a=0x0;
	gdt[n].c=addr;
	if(type==LDTDIS){
		gdt[n].d=0x40;
		gdt[n].b=0xe900;
	}
	else if (type ==TSSDIS){
		gdt[n].d=0x68;
		gdt[n].b=0xe200;
	}
}

void schedule(void){
	int next=-1;
	int c=0;
	int index=NR_TASK;
	struct task_struct **p;
	while(1){
		index=NR_TASK;
		c=0;
		for(p=&tasks[NR_TASK-1];p>=&tasks[0];p--){
			if(*p){
				if((*p)->state==TASK_RUNNING&&(*p)->counter>c){
					next=index;
					c=(*p)->counter;
				}
			}
			index--;
		}
		if(c)break;
		for(p=&tasks[NR_TASK-1];p>=&tasks[0];p--){
				if(*p){
					(*p)->counter=((*p)->count>>2)+(*p)->pri;
				}
		}
	}
	switch_to(next);
}

//这里需要将两个任务加入gdt
//设置中断控制器 注：改为在image.s中设置中断控制模式
void sche_init(){
	set_gdt(tasks[0]->ldt, 4, LDTDIS);
	set_gdt(&tasks[0]->tss, 5, TSSDIS);
	set_gdt(tasks[1]->ldt, 6, LDTDIS);
	set_gdt(&tasks[1]->tss,7,TSSDIS);
	ltr(4);
	lldt(4);


}
