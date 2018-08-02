include ../Makefile.header

LDFLAGS+= -r

CFLAGS +=-I../include
CPP +=-I../.include

.c.s:
	@$(CC) $(CFLAGS) \
	-S -o $*.s $<
.s.o:
	@$(AS) -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) \

OBJS = sched.o system_call.o traps.o asm.o sys.o

kernel.o : $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

dep:
	@sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	@(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	@cp tmp_make Makefile

### Dependencies:
