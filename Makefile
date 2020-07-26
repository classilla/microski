RM ?= rm
CC ?= gcc

# probably overkill, but hey
CFLAGS ?= -m64 -mpowerpc64 -mcpu=power8 -mabi=elfv2

all: be_payload.elf le_payload.elf

le_payload.elf: le_hello.o ld.script
	$(CC) $(CFLAGS) -mlittle-endian \
		-T ld.script -ffreestanding -nostdlib \
		-Ttext=0x8000000020010000 \
		-o $@ le_hello.o

le_hello.o: hello_kernel.S Makefile
	$(CC) $(CFLAGS) -mlittle-endian -c -o $@ hello_kernel.S

be_payload.elf: be_hello.o ld.script
	$(CC) $(CFLAGS) -mbig-endian \
		-T ld.script -ffreestanding -nostdlib \
		-Ttext=0x8000000020010000 \
		-o $@ be_hello.o

be_hello.o: hello_kernel.S Makefile
	$(CC) $(CFLAGS) -mbig-endian -c -o $@ hello_kernel.S

clean:
	$(RM) -f *.o *.elf

