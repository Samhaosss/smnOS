/*************************************************************************
    > File Name: sys.c
    > Author: sam 
    > Created Time: 2018年08月02日 星期四 20时12分53秒
 ************************************************************************/
#include<sche.h>	//just need the fptr type 
extern unsigned long NR_CALL;

extern int write_char();
extern int  do_reserve();
fptr system_call_table[]={
	do_reserve,
	write_char };


