AS = as
LDFLAG= -T boot.ld
source := $(wildcard *.s)
obj := $(patsubst %.s,%.o,$(source))
exe := $(patsubst %.o,%,$(obj) )


all:Image


Image: $(exe)
	dd if=boot of=Image bs=512 count=1 
	dd if=setup of=Image bs=512 count=4 seek=1 
	dd if=image of=Image bs=512 seek=5
#	ld --oformat binary -N -e BOOT -Ttext 0x7c00 -o boot boot.o

$(exe): % : %.o
	ld -T boot.ld $< -o $@
	objcopy -O binary -j .text $@

$(obj): %.o : %.s 
	$(AS) --32 -o $@ $<


run: Image 
	@qemu -boot a -fda Image 
clean:
	@-rm  *.o $(exe)
