AS = as --32 -r
#LDFLAG= -T boot.ld
LDFLAG= -m  elf_i386 -Ttext 0 -e setup 
source := $(wildcard *.s)
obj := $(patsubst %.s,%.o,$(source))
exe := $(patsubst %.o,%,$(obj) )
CFLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer #-fstrength-reduce

all:Image


Image: setup boot  init
	dd if=boot of=Image bs=512 count=1 
	dd if=setup of=Image bs=512 count=4 seek=1 
	dd if=init of=Image bs=512 seek=5
#	ld --oformat binary -N -e BOOT -Ttext 0x7c00 -o boot boot.o

#$(exe): % : %.o
#	ld -T boot.ld $< -o $@
#	objcopy -O binary -j .text $@

#$(obj): %.o : %.s 
#	echo $(obj)
#	$(AS) --32 -o $@ $<
boot: boot.s
	$(AS)  -o boot.o boot.s
	ld -T boot.ld boot.o -o boot
	objcopy -O binary -j .text boot 

setup: setup.s
	$(AS)  -o setup.o setup.s
	ld -T boot.ld setup.o -o setup
	objcopy -O binary -j .text setup 

init.o : init.s
	$(AS)  -o  init.o init.s
init.s:init.c
	$(CC) $(CFLAGS) -S -o init.s init.c	

image.o : image.s
	$(AS)  -o image.o image.s


init: init.o image.o
	ld  $(LDFLAG)   image.o init.o -o init
	objcopy -O binary -j .text init


run: Image 
	@qemu -boot a -fda Image 
clean:
	@-rm  *.o $(exe)
