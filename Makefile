
LDFLAGS	+= -Ttext 0 -e startup_32
CFLAGS	+= $(RAMDISK) -Iinclude
CPP	+= -Iinclude

ARCHIVES=kernel/kernel.o 

all:Image
.c.s:
	@$(CC) $(CFLAGS) -S -o $*.s $<
.s.o:
	@$(AS)  -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<


Image:boot/boot boot/setup system
	$(OBJCOPY)  -O binary -R .note -R .comment system kernel
	dd if=boot/boot bs=512 count=1 of=IMAGE
	dd if=boot/setup bs=512 seek=1 count=4 of=IMAGE
	dd if=kernel bs=512 seek=5 count=2880 of=IMAGE

system:kernel/kernel.o init/init.o boot/image.o
	$(LD) $(LDFALGS) kernel/kernel.o init/init.o boot/image.o -o system 


kernel/kernel.o:
	make -C kernel
boot/image.o:boot/image.s
	make image.o -C boot/
boot/setup: boot/setup.s
	make setup -C boot
boot/boot: boot/boot.s
	make boot -C boot

init/main.o: init/main.c 

run: Image 
	@qemu -boot a -fda Image 

