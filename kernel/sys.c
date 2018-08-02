/*************************************************************************
    > File Name: sys.c
    > Author: sam 
    > Created Time: 2018年08月02日 星期四 20时12分53秒
 ************************************************************************/
#include<sche.h>	//just need the fptr type 
extern unsigned long NR_CALL;

extern int write_char();

fptr system_call_table[]={
	write_char,
	write_char };


