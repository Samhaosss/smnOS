include ../Makefile.header

LDFLAGS += -Ttext 0

source := $(wildcard *.s)
obj := $(patsubst %.s,%.o,$(source))
exe := $(patsubst %.o,%,$(obj) )
#CFLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer #-fstrength-reduce

all:boot setup
boot:boot.s
	@$(AS) -o boot.o boot.s
	@$(LD) $(LDFLAGS) -o boot boot.o
	@$(OBJCOPY) -R .pdr -R .comment -R .note -S -O binary boot

setup:setup.s
	@$(AS) -o setup.o setup.s
	@$(LD) $(LDFLAGS) -o setup setup.o
	@$(OBJCOPY) -R .pdr -R .comment -R .note -S -O binary setup

image.o:image.s
	@$(AS) -o image.o image.s


#Image: setup boot  init
#	dd if=boot of=Image bs=512 count=1 
#	dd if=setup of=Image bs=512 count=4 seek=1 
#	dd if=init of=Image bs=512 seek=5
#	ld --oformat binary -N -e BOOT -Ttext 0x7c00 -o boot boot.o

#$(exe): % : %.o
#	ld -T boot.ld $< -o $@
#	objcopy -O binary -j .text $@



#run: Image 
#	@qemu -boot a -fda Image 
clean:
	-@rm  $(obj) $(exe)
