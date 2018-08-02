/*************************************************************************
    > File Name: init.c
    > Author: sam
    > Created Time: 2018年08月01日 星期三 22时42分30秒
 ************************************************************************/
//#include<>


extern void idt_init(void);
extern void task_init(void);

void main(void){
	idt_init();
	task_init();
}
