include ./Makefile.header

LDFLAGS	+= -Ttext 0 -e setup 
CFLAGS	+= -Iinclude
CPP	+= -Iinclude

ARCHIVES=kernel/kernel.o 

all:Image
.c.s:
	@$(CC) $(CFLAGS) -S -o $*.s $<
.s.o:
	@$(AS)  -o $*.o $<
.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

KERNELIMAGE=sysimage 

Image:boot/boot boot/setup system
	$(OBJCOPY)  -O binary -R .note -R .comment system $(KERNELIMAGE)
	dd if=boot/boot bs=512 count=1 of=Image
	dd if=boot/setup bs=512 seek=1 count=4 of=Image
	dd if=sysimage bs=512 seek=5 count=2880 of=Image

system:kernel/kernel.o init/init.o boot/image.o
	$(LD) $(LDFLAGS)   boot/image.o init/init.o kernel/kernel.o -o system


kernel/kernel.o:
	make kernel.o -C kernel/
boot/image.o:boot/image.s
	make image.o -C boot/
boot/setup: boot/setup.s
	make setup -C boot
boot/boot: boot/boot.s
	make boot -C boot

init/init.o: init/init.c

run: Image 
	@qemu -boot a -fda Image 
clean:
	@make clean -C boot/ 
	@make clean -C kernel/ 
	@rm init/init.o 
	@rm $(KERNELIMAGE)
	@rm system

