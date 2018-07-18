AS = as
all:boot 

boot : boot.o boot.ld
#	ld --oformat binary -N -e BOOT -Ttext 0x7c00 -o boot boot.o
	ld -T boot.ld   boot.o -o boot #使用链接脚本进行链接
	objcopy -O binary -j .text boot
	@-rm *.o
.s.o:
	@echo $<
	as --32 -o $*.o $<
run:
	@qemu -boot a -fda boot 
clean:
	@-rm boot boot.o
