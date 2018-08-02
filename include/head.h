/*************************************************************************
    > File Name: sys.h
    > Author: sam
    > Created Time: 2018年08月01日 星期三 23时07分53秒
 ************************************************************************/
#ifndef _HEAD_H
#define _HEAD_H

struct desc_struct{
	unsigned long a,b;
} desc_table[256];

extern unsigned long pd_dir[1024]
extern desc_table idt, gdt;

#endif 

