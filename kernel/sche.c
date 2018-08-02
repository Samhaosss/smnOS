/*************************************************************************
    > File Name: sche.c
    > Author: sam
    > Created Time: 2018年08月01日 星期三 22时45分13秒
 ************************************************************************/
#include<sche.h>
#include<signal.h>

#define TR 2
#define SIG(n) (1<<(n-1))
#define BLOCKABLE	(~((SIG(SIGKILL))|(SIG(SIGSTOP))) )

#define FIRST_TASK tasks[0]
//实现多个内核任务的切换


void task1(void);
void task2(void);

union task_union {
	struct task_struct task;
	char stack[4096];
};

static union task_union test_task[2];
long user_stack[2][4096];
task_struct *tasks[TR];
struct task_struct * current= tasks[0];

void schedule(void){
	int i,count;
	int next=0;
	struct task_struct **p;
//check signal
	for (p=& tasks[TR-1];p>&FIRST_TASK;p--){
		if(*p){
			if( ((*p)->sigmap &(~(BLOCKABLE&(*p)->block ))) && (*p)->state == INTERRUPTIBLE )
				(*p)->state=TASK_RUNNING;
		}
	}
//find next task to run ,if every task has no count,then re distribute count 
	while(1){
		next=-1;
		i=TR;
		count=-1;
		while(--i+1){
			if(tasks[i] && tasks[i]->state== TASK_RUNNING && tasks[i]->count>count){
				next=i;
				count=tasks[i]->count;
			}
		}
		if(next+1)break;
		for(p=&tasks[TR-1];p>FIRST_TASK;p--){
			if(*p)
			(*p)->count=(*p)->pri<<2;
		}
	}

	switch_to(next)

}
/*
 *  task data model
 *	tasks|	p1 |----->task_struct|	...	|
 *		 |	p2 |				 |	tss	|	->>>	|	info...	|
 *													|   esp0	| ---> &(tasks[0]+4096)
 *													|   esp3	| ---> &(user_stack[0]+4096)
 *													|   eip		| ---> &task0
 * */

void task_init(void){
	//setuo task0 and task1
}


