include ../Makefile.header
OBJS = asm.o sche.o syscall.o sys.o trap.o

LDFLAGS += -r

CFLAGS += -I../include
CPP += -I../include

.c.s:
	@$(CC) $(CFLAGS) \
	-S -o $*.s $<
.s.o:
	@$(AS) -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<
#	$(AS)  -o $*.o $*.s


kernel.o : $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

dep:
	@sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	@(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	@cp tmp_make Makefile
clean:
	-@rm $(OBJS) kernel.o

### Dependencies:
sche.s sche.o: sche.c ../include/sche.h
sys.s sys.o: sys.c ../include/sche.h
trap.s trap.o: trap.c ../include/sys.h ../include/sche.h
