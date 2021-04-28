
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
	cprintf("leaving test_backtrace %d\n", x);
}
*/
void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 60 79 11 f0       	mov    $0xf0117960,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 0f 39 00 00       	call   f0103977 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("444544 decimal is %o octal!\n", 444544);
f010006d:	c7 44 24 04 80 c8 06 	movl   $0x6c880,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 3e 10 f0 	movl   $0xf0103e20,(%esp)
f010007c:	e8 8a 2d 00 00       	call   f0102e0b <cprintf>

	// Test stack backtrace function (lab1)
//	test_backtrace(5);

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 8d 12 00 00       	call   f0101313 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 7d 07 00 00       	call   f010080f <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 64 79 11 f0 00 	cmpl   $0x0,0xf0117964
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 64 79 11 f0    	mov    %esi,0xf0117964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 3d 3e 10 f0 	movl   $0xf0103e3d,(%esp)
f01000c8:	e8 3e 2d 00 00       	call   f0102e0b <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ff 2c 00 00       	call   f0102dd8 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 2e 46 10 f0 	movl   $0xf010462e,(%esp)
f01000e0:	e8 26 2d 00 00       	call   f0102e0b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 1e 07 00 00       	call   f010080f <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 55 3e 10 f0 	movl   $0xf0103e55,(%esp)
f0100112:	e8 f4 2c 00 00       	call   f0102e0b <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 b2 2c 00 00       	call   f0102dd8 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 2e 46 10 f0 	movl   $0xf010462e,(%esp)
f010012d:	e8 d9 2c 00 00       	call   f0102e0b <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01001cb:	c3                   	ret    
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 c0 3f 10 f0 	movzbl -0xfefc040(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 c0 3f 10 f0 	movzbl -0xfefc040(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a c0 3e 10 f0 	movzbl -0xfefc140(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300
	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d a0 3e 10 f0 	mov    -0xfefc160(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
	return c;
f010027b:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 6f 3e 10 f0 	movl   $0xf0103e6f,(%esp)
f0100291:	e8 75 2b 00 00       	call   f0102e0b <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 86 35 00 00       	call   f01039c4 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 7b 3e 10 f0 	movl   $0xf0103e7b,(%esp)
f01005f4:	e8 12 28 00 00       	call   f0102e0b <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 c0 40 10 	movl   $0xf01040c0,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 de 40 10 	movl   $0xf01040de,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 e3 40 10 f0 	movl   $0xf01040e3,(%esp)
f010064d:	e8 b9 27 00 00       	call   f0102e0b <cprintf>
f0100652:	c7 44 24 08 9c 41 10 	movl   $0xf010419c,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 ec 40 10 	movl   $0xf01040ec,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 e3 40 10 f0 	movl   $0xf01040e3,(%esp)
f0100669:	e8 9d 27 00 00       	call   f0102e0b <cprintf>
f010066e:	c7 44 24 08 f5 40 10 	movl   $0xf01040f5,0x8(%esp)
f0100675:	f0 
f0100676:	c7 44 24 04 fe 40 10 	movl   $0xf01040fe,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 e3 40 10 f0 	movl   $0xf01040e3,(%esp)
f0100685:	e8 81 27 00 00       	call   f0102e0b <cprintf>
	return 0;
}
f010068a:	b8 00 00 00 00       	mov    $0x0,%eax
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	c7 04 24 08 41 10 f0 	movl   $0xf0104108,(%esp)
f010069e:	e8 68 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006aa:	00 
f01006ab:	c7 04 24 c4 41 10 f0 	movl   $0xf01041c4,(%esp)
f01006b2:	e8 54 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 ec 41 10 f0 	movl   $0xf01041ec,(%esp)
f01006ce:	e8 38 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d3:	c7 44 24 08 07 3e 10 	movl   $0x103e07,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 07 3e 10 	movl   $0xf0103e07,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 10 42 10 f0 	movl   $0xf0104210,(%esp)
f01006ea:	e8 1c 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 34 42 10 f0 	movl   $0xf0104234,(%esp)
f0100706:	e8 00 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070b:	c7 44 24 08 60 79 11 	movl   $0x117960,0x8(%esp)
f0100712:	00 
f0100713:	c7 44 24 04 60 79 11 	movl   $0xf0117960,0x4(%esp)
f010071a:	f0 
f010071b:	c7 04 24 58 42 10 f0 	movl   $0xf0104258,(%esp)
f0100722:	e8 e4 26 00 00       	call   f0102e0b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 5f 7d 11 f0       	mov    $0xf0117d5f,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100731:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100736:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073c:	85 c0                	test   %eax,%eax
f010073e:	0f 48 c2             	cmovs  %edx,%eax
f0100741:	c1 f8 0a             	sar    $0xa,%eax
f0100744:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100748:	c7 04 24 7c 42 10 f0 	movl   $0xf010427c,(%esp)
f010074f:	e8 b7 26 00 00       	call   f0102e0b <cprintf>
	return 0;
}
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	57                   	push   %edi
f010075f:	56                   	push   %esi
f0100760:	53                   	push   %ebx
f0100761:	83 ec 4c             	sub    $0x4c,%esp
	// LAB 1: Your code here.
    // HINT 1: use read_ebp().
    // HINT 2: print the current ebp on the first line (not current_ebp[0])
	
	uint32_t* ebp = (uint32_t*) read_ebp();
f0100764:	89 ee                	mov    %ebp,%esi
  	cprintf("Stack backtrace:\n");
f0100766:	c7 04 24 21 41 10 f0 	movl   $0xf0104121,(%esp)
f010076d:	e8 99 26 00 00       	call   f0102e0b <cprintf>
  	while (ebp != 0) {
f0100772:	e9 83 00 00 00       	jmp    f01007fa <mon_backtrace+0x9f>
    	uint32_t eip = ebp[1];
f0100777:	8b 7e 04             	mov    0x4(%esi),%edi
    	cprintf("ebp %x  eip %x  args", ebp, eip);
f010077a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010077e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100782:	c7 04 24 33 41 10 f0 	movl   $0xf0104133,(%esp)
f0100789:	e8 7d 26 00 00       	call   f0102e0b <cprintf>
    	int i;
    	for (i = 2; i <= 6; ++i)
f010078e:	bb 02 00 00 00       	mov    $0x2,%ebx
      		cprintf(" %08.x", ebp[i]);
f0100793:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100796:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079a:	c7 04 24 48 41 10 f0 	movl   $0xf0104148,(%esp)
f01007a1:	e8 65 26 00 00       	call   f0102e0b <cprintf>
    	for (i = 2; i <= 6; ++i)
f01007a6:	83 c3 01             	add    $0x1,%ebx
f01007a9:	83 fb 07             	cmp    $0x7,%ebx
f01007ac:	75 e5                	jne    f0100793 <mon_backtrace+0x38>
    	cprintf("\n");
f01007ae:	c7 04 24 2e 46 10 f0 	movl   $0xf010462e,(%esp)
f01007b5:	e8 51 26 00 00       	call   f0102e0b <cprintf>
    	struct Eipdebuginfo info;
    	debuginfo_eip(eip, &info);
f01007ba:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c1:	89 3c 24             	mov    %edi,(%esp)
f01007c4:	e8 39 27 00 00       	call   f0102f02 <debuginfo_eip>
    	cprintf("\t%s:%d: %.*s+%d\n", 
f01007c9:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007cc:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01007d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007d3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007d7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ec:	c7 04 24 4f 41 10 f0 	movl   $0xf010414f,(%esp)
f01007f3:	e8 13 26 00 00       	call   f0102e0b <cprintf>
      				info.eip_file, info.eip_line,
      				info.eip_fn_namelen, info.eip_fn_name,
      				eip-info.eip_fn_addr);
//         kern/monitor.c:143: monitor+106
    	ebp = (uint32_t*) *ebp;
f01007f8:	8b 36                	mov    (%esi),%esi
  	while (ebp != 0) {
f01007fa:	85 f6                	test   %esi,%esi
f01007fc:	0f 85 75 ff ff ff    	jne    f0100777 <mon_backtrace+0x1c>
  }
	
	return 0;
}
f0100802:	b8 00 00 00 00       	mov    $0x0,%eax
f0100807:	83 c4 4c             	add    $0x4c,%esp
f010080a:	5b                   	pop    %ebx
f010080b:	5e                   	pop    %esi
f010080c:	5f                   	pop    %edi
f010080d:	5d                   	pop    %ebp
f010080e:	c3                   	ret    

f010080f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010080f:	55                   	push   %ebp
f0100810:	89 e5                	mov    %esp,%ebp
f0100812:	57                   	push   %edi
f0100813:	56                   	push   %esi
f0100814:	53                   	push   %ebx
f0100815:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100818:	c7 04 24 a8 42 10 f0 	movl   $0xf01042a8,(%esp)
f010081f:	e8 e7 25 00 00       	call   f0102e0b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100824:	c7 04 24 cc 42 10 f0 	movl   $0xf01042cc,(%esp)
f010082b:	e8 db 25 00 00       	call   f0102e0b <cprintf>


	while (1) {
		buf = readline("K> ");
f0100830:	c7 04 24 60 41 10 f0 	movl   $0xf0104160,(%esp)
f0100837:	e8 e4 2e 00 00       	call   f0103720 <readline>
f010083c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010083e:	85 c0                	test   %eax,%eax
f0100840:	74 ee                	je     f0100830 <monitor+0x21>
	argv[argc] = 0;
f0100842:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100849:	be 00 00 00 00       	mov    $0x0,%esi
f010084e:	eb 0a                	jmp    f010085a <monitor+0x4b>
			*buf++ = 0;
f0100850:	c6 03 00             	movb   $0x0,(%ebx)
f0100853:	89 f7                	mov    %esi,%edi
f0100855:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100858:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f010085a:	0f b6 03             	movzbl (%ebx),%eax
f010085d:	84 c0                	test   %al,%al
f010085f:	74 63                	je     f01008c4 <monitor+0xb5>
f0100861:	0f be c0             	movsbl %al,%eax
f0100864:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100868:	c7 04 24 64 41 10 f0 	movl   $0xf0104164,(%esp)
f010086f:	e8 c6 30 00 00       	call   f010393a <strchr>
f0100874:	85 c0                	test   %eax,%eax
f0100876:	75 d8                	jne    f0100850 <monitor+0x41>
		if (*buf == 0)
f0100878:	80 3b 00             	cmpb   $0x0,(%ebx)
f010087b:	74 47                	je     f01008c4 <monitor+0xb5>
		if (argc == MAXARGS-1) {
f010087d:	83 fe 0f             	cmp    $0xf,%esi
f0100880:	75 16                	jne    f0100898 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100882:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100889:	00 
f010088a:	c7 04 24 69 41 10 f0 	movl   $0xf0104169,(%esp)
f0100891:	e8 75 25 00 00       	call   f0102e0b <cprintf>
f0100896:	eb 98                	jmp    f0100830 <monitor+0x21>
		argv[argc++] = buf;
f0100898:	8d 7e 01             	lea    0x1(%esi),%edi
f010089b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010089f:	eb 03                	jmp    f01008a4 <monitor+0x95>
			buf++;
f01008a1:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a4:	0f b6 03             	movzbl (%ebx),%eax
f01008a7:	84 c0                	test   %al,%al
f01008a9:	74 ad                	je     f0100858 <monitor+0x49>
f01008ab:	0f be c0             	movsbl %al,%eax
f01008ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b2:	c7 04 24 64 41 10 f0 	movl   $0xf0104164,(%esp)
f01008b9:	e8 7c 30 00 00       	call   f010393a <strchr>
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	74 df                	je     f01008a1 <monitor+0x92>
f01008c2:	eb 94                	jmp    f0100858 <monitor+0x49>
	argv[argc] = 0;
f01008c4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008cb:	00 
	if (argc == 0)
f01008cc:	85 f6                	test   %esi,%esi
f01008ce:	0f 84 5c ff ff ff    	je     f0100830 <monitor+0x21>
f01008d4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008d9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f01008dc:	8b 04 85 00 43 10 f0 	mov    -0xfefbd00(,%eax,4),%eax
f01008e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ea:	89 04 24             	mov    %eax,(%esp)
f01008ed:	e8 ea 2f 00 00       	call   f01038dc <strcmp>
f01008f2:	85 c0                	test   %eax,%eax
f01008f4:	75 24                	jne    f010091a <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008f6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f9:	8b 55 08             	mov    0x8(%ebp),%edx
f01008fc:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100900:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100903:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100907:	89 34 24             	mov    %esi,(%esp)
f010090a:	ff 14 85 08 43 10 f0 	call   *-0xfefbcf8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100911:	85 c0                	test   %eax,%eax
f0100913:	78 25                	js     f010093a <monitor+0x12b>
f0100915:	e9 16 ff ff ff       	jmp    f0100830 <monitor+0x21>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010091a:	83 c3 01             	add    $0x1,%ebx
f010091d:	83 fb 03             	cmp    $0x3,%ebx
f0100920:	75 b7                	jne    f01008d9 <monitor+0xca>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100922:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100925:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100929:	c7 04 24 86 41 10 f0 	movl   $0xf0104186,(%esp)
f0100930:	e8 d6 24 00 00       	call   f0102e0b <cprintf>
f0100935:	e9 f6 fe ff ff       	jmp    f0100830 <monitor+0x21>
				break;
	}
}
f010093a:	83 c4 5c             	add    $0x5c,%esp
f010093d:	5b                   	pop    %ebx
f010093e:	5e                   	pop    %esi
f010093f:	5f                   	pop    %edi
f0100940:	5d                   	pop    %ebp
f0100941:	c3                   	ret    
f0100942:	66 90                	xchg   %ax,%ax
f0100944:	66 90                	xchg   %ax,%ax
f0100946:	66 90                	xchg   %ax,%ax
f0100948:	66 90                	xchg   %ax,%ax
f010094a:	66 90                	xchg   %ax,%ax
f010094c:	66 90                	xchg   %ax,%ax
f010094e:	66 90                	xchg   %ax,%ax

f0100950 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	56                   	push   %esi
f0100954:	53                   	push   %ebx
f0100955:	83 ec 10             	sub    $0x10,%esp
f0100958:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010095a:	89 04 24             	mov    %eax,(%esp)
f010095d:	e8 39 24 00 00       	call   f0102d9b <mc146818_read>
f0100962:	89 c6                	mov    %eax,%esi
f0100964:	83 c3 01             	add    $0x1,%ebx
f0100967:	89 1c 24             	mov    %ebx,(%esp)
f010096a:	e8 2c 24 00 00       	call   f0102d9b <mc146818_read>
f010096f:	c1 e0 08             	shl    $0x8,%eax
f0100972:	09 f0                	or     %esi,%eax
}
f0100974:	83 c4 10             	add    $0x10,%esp
f0100977:	5b                   	pop    %ebx
f0100978:	5e                   	pop    %esi
f0100979:	5d                   	pop    %ebp
f010097a:	c3                   	ret    

f010097b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010097b:	55                   	push   %ebp
f010097c:	89 e5                	mov    %esp,%ebp
f010097e:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100981:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100988:	75 11                	jne    f010099b <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010098a:	ba 5f 89 11 f0       	mov    $0xf011895f,%edx
f010098f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100995:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010099b:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
    nextfree = ROUNDUP((char *) nextfree + n, PGSIZE);
f01009a1:	8d 8c 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%ecx
f01009a8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01009ae:	89 0d 38 75 11 f0    	mov    %ecx,0xf0117538

    if (n == 0) {
f01009b4:	85 c0                	test   %eax,%eax
f01009b6:	75 28                	jne    f01009e0 <boot_alloc+0x65>
        assert(result == nextfree);
f01009b8:	39 ca                	cmp    %ecx,%edx
f01009ba:	74 24                	je     f01009e0 <boot_alloc+0x65>
f01009bc:	c7 44 24 0c 24 43 10 	movl   $0xf0104324,0xc(%esp)
f01009c3:	f0 
f01009c4:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01009cb:	f0 
f01009cc:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f01009d3:	00 
f01009d4:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01009db:	e8 b4 f6 ff ff       	call   f0100094 <_panic>
    }

    assert ((uint32_t) nextfree % PGSIZE == 0);
f01009e0:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
f01009e6:	85 c9                	test   %ecx,%ecx
f01009e8:	74 24                	je     f0100a0e <boot_alloc+0x93>
f01009ea:	c7 44 24 0c 60 46 10 	movl   $0xf0104660,0xc(%esp)
f01009f1:	f0 
f01009f2:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01009f9:	f0 
f01009fa:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
f0100a01:	00 
f0100a02:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100a09:	e8 86 f6 ff ff       	call   f0100094 <_panic>
    //cprintf("boot_alloc: allocate %d bytes starting at address %p %p\n", n, 
     //       PADDR(result), result);
   // cprintf("boot_alloc: nextfree is now %p %p\n", PADDR(nextfree), nextfree);
	return result;

}
f0100a0e:	89 d0                	mov    %edx,%eax
f0100a10:	c9                   	leave  
f0100a11:	c3                   	ret    

f0100a12 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a12:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100a18:	c1 f8 03             	sar    $0x3,%eax
f0100a1b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100a1e:	89 c2                	mov    %eax,%edx
f0100a20:	c1 ea 0c             	shr    $0xc,%edx
f0100a23:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100a29:	72 26                	jb     f0100a51 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a2b:	55                   	push   %ebp
f0100a2c:	89 e5                	mov    %esp,%ebp
f0100a2e:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a31:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a35:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0100a3c:	f0 
f0100a3d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a44:	00 
f0100a45:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0100a4c:	e8 43 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a51:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100a56:	c3                   	ret    

f0100a57 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a57:	89 d1                	mov    %edx,%ecx
f0100a59:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a5c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a5f:	a8 01                	test   $0x1,%al
f0100a61:	74 5d                	je     f0100ac0 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100a68:	89 c1                	mov    %eax,%ecx
f0100a6a:	c1 e9 0c             	shr    $0xc,%ecx
f0100a6d:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0100a73:	72 26                	jb     f0100a9b <check_va2pa+0x44>
{
f0100a75:	55                   	push   %ebp
f0100a76:	89 e5                	mov    %esp,%ebp
f0100a78:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a7b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a7f:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0100a86:	f0 
f0100a87:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0100a8e:	00 
f0100a8f:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100a96:	e8 f9 f5 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a9b:	c1 ea 0c             	shr    $0xc,%edx
f0100a9e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aa4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aab:	89 c2                	mov    %eax,%edx
f0100aad:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ab0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab5:	85 d2                	test   %edx,%edx
f0100ab7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100abc:	0f 44 c2             	cmove  %edx,%eax
f0100abf:	c3                   	ret    
		return ~0;
f0100ac0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100ac5:	c3                   	ret    

f0100ac6 <check_page_free_list>:
{
f0100ac6:	55                   	push   %ebp
f0100ac7:	89 e5                	mov    %esp,%ebp
f0100ac9:	57                   	push   %edi
f0100aca:	56                   	push   %esi
f0100acb:	53                   	push   %ebx
f0100acc:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100acf:	84 c0                	test   %al,%al
f0100ad1:	0f 85 15 03 00 00    	jne    f0100dec <check_page_free_list+0x326>
f0100ad7:	e9 22 03 00 00       	jmp    f0100dfe <check_page_free_list+0x338>
		panic("'page_free_list' is a null pointer!");
f0100adc:	c7 44 24 08 a8 46 10 	movl   $0xf01046a8,0x8(%esp)
f0100ae3:	f0 
f0100ae4:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0100aeb:	00 
f0100aec:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100af3:	e8 9c f5 ff ff       	call   f0100094 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100af8:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100afb:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100afe:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b01:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100b04:	89 c2                	mov    %eax,%edx
f0100b06:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b0c:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b12:	0f 95 c2             	setne  %dl
f0100b15:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b18:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b1c:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b1e:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b22:	8b 00                	mov    (%eax),%eax
f0100b24:	85 c0                	test   %eax,%eax
f0100b26:	75 dc                	jne    f0100b04 <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100b28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b2b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b34:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b37:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b39:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b3c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b41:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b46:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b4c:	eb 63                	jmp    f0100bb1 <check_page_free_list+0xeb>
f0100b4e:	89 d8                	mov    %ebx,%eax
f0100b50:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100b56:	c1 f8 03             	sar    $0x3,%eax
f0100b59:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b5c:	89 c2                	mov    %eax,%edx
f0100b5e:	c1 ea 16             	shr    $0x16,%edx
f0100b61:	39 f2                	cmp    %esi,%edx
f0100b63:	73 4a                	jae    f0100baf <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100b65:	89 c2                	mov    %eax,%edx
f0100b67:	c1 ea 0c             	shr    $0xc,%edx
f0100b6a:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100b70:	72 20                	jb     f0100b92 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b72:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b76:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0100b7d:	f0 
f0100b7e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b85:	00 
f0100b86:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0100b8d:	e8 02 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b92:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b99:	00 
f0100b9a:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100ba1:	00 
	return (void *)(pa + KERNBASE);
f0100ba2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ba7:	89 04 24             	mov    %eax,(%esp)
f0100baa:	e8 c8 2d 00 00       	call   f0103977 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100baf:	8b 1b                	mov    (%ebx),%ebx
f0100bb1:	85 db                	test   %ebx,%ebx
f0100bb3:	75 99                	jne    f0100b4e <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100bb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bba:	e8 bc fd ff ff       	call   f010097b <boot_alloc>
f0100bbf:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bc2:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		assert(pp >= pages);
f0100bc8:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
		assert(pp < pages + npages);
f0100bce:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0100bd3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bd6:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bd9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bdc:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bdf:	bf 00 00 00 00       	mov    $0x0,%edi
f0100be4:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be7:	e9 97 01 00 00       	jmp    f0100d83 <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100bec:	39 ca                	cmp    %ecx,%edx
f0100bee:	73 24                	jae    f0100c14 <check_page_free_list+0x14e>
f0100bf0:	c7 44 24 0c 66 43 10 	movl   $0xf0104366,0xc(%esp)
f0100bf7:	f0 
f0100bf8:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100bff:	f0 
f0100c00:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f0100c07:	00 
f0100c08:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100c0f:	e8 80 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100c14:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c17:	72 24                	jb     f0100c3d <check_page_free_list+0x177>
f0100c19:	c7 44 24 0c 72 43 10 	movl   $0xf0104372,0xc(%esp)
f0100c20:	f0 
f0100c21:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f0100c30:	00 
f0100c31:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100c38:	e8 57 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c3d:	89 d0                	mov    %edx,%eax
f0100c3f:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c42:	a8 07                	test   $0x7,%al
f0100c44:	74 24                	je     f0100c6a <check_page_free_list+0x1a4>
f0100c46:	c7 44 24 0c cc 46 10 	movl   $0xf01046cc,0xc(%esp)
f0100c4d:	f0 
f0100c4e:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100c55:	f0 
f0100c56:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0100c5d:	00 
f0100c5e:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100c65:	e8 2a f4 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0100c6a:	c1 f8 03             	sar    $0x3,%eax
f0100c6d:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100c70:	85 c0                	test   %eax,%eax
f0100c72:	75 24                	jne    f0100c98 <check_page_free_list+0x1d2>
f0100c74:	c7 44 24 0c 86 43 10 	movl   $0xf0104386,0xc(%esp)
f0100c7b:	f0 
f0100c7c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100c83:	f0 
f0100c84:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f0100c8b:	00 
f0100c8c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100c93:	e8 fc f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c98:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c9d:	75 24                	jne    f0100cc3 <check_page_free_list+0x1fd>
f0100c9f:	c7 44 24 0c 97 43 10 	movl   $0xf0104397,0xc(%esp)
f0100ca6:	f0 
f0100ca7:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100cae:	f0 
f0100caf:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0100cb6:	00 
f0100cb7:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100cbe:	e8 d1 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cc3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cc8:	75 24                	jne    f0100cee <check_page_free_list+0x228>
f0100cca:	c7 44 24 0c 00 47 10 	movl   $0xf0104700,0xc(%esp)
f0100cd1:	f0 
f0100cd2:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100cd9:	f0 
f0100cda:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0100ce1:	00 
f0100ce2:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100ce9:	e8 a6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cee:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cf3:	75 24                	jne    f0100d19 <check_page_free_list+0x253>
f0100cf5:	c7 44 24 0c b0 43 10 	movl   $0xf01043b0,0xc(%esp)
f0100cfc:	f0 
f0100cfd:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100d04:	f0 
f0100d05:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f0100d0c:	00 
f0100d0d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100d14:	e8 7b f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d19:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d1e:	76 58                	jbe    f0100d78 <check_page_free_list+0x2b2>
	if (PGNUM(pa) >= npages)
f0100d20:	89 c3                	mov    %eax,%ebx
f0100d22:	c1 eb 0c             	shr    $0xc,%ebx
f0100d25:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d28:	77 20                	ja     f0100d4a <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d2a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d2e:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0100d35:	f0 
f0100d36:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d3d:	00 
f0100d3e:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0100d45:	e8 4a f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d4a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d4f:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d52:	76 2a                	jbe    f0100d7e <check_page_free_list+0x2b8>
f0100d54:	c7 44 24 0c 24 47 10 	movl   $0xf0104724,0xc(%esp)
f0100d5b:	f0 
f0100d5c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100d63:	f0 
f0100d64:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f0100d6b:	00 
f0100d6c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100d73:	e8 1c f3 ff ff       	call   f0100094 <_panic>
			++nfree_basemem;
f0100d78:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d7c:	eb 03                	jmp    f0100d81 <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100d7e:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d81:	8b 12                	mov    (%edx),%edx
f0100d83:	85 d2                	test   %edx,%edx
f0100d85:	0f 85 61 fe ff ff    	jne    f0100bec <check_page_free_list+0x126>
f0100d8b:	8b 5d cc             	mov    -0x34(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100d8e:	85 db                	test   %ebx,%ebx
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x2f0>
f0100d92:	c7 44 24 0c ca 43 10 	movl   $0xf01043ca,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100db1:	e8 de f2 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100db6:	85 ff                	test   %edi,%edi
f0100db8:	7f 24                	jg     f0100dde <check_page_free_list+0x318>
f0100dba:	c7 44 24 0c dc 43 10 	movl   $0xf01043dc,0xc(%esp)
f0100dc1:	f0 
f0100dc2:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100dc9:	f0 
f0100dca:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0100dd1:	00 
f0100dd2:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100dd9:	e8 b6 f2 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0100dde:	c7 04 24 6c 47 10 f0 	movl   $0xf010476c,(%esp)
f0100de5:	e8 21 20 00 00       	call   f0102e0b <cprintf>
f0100dea:	eb 29                	jmp    f0100e15 <check_page_free_list+0x34f>
	if (!page_free_list)
f0100dec:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100df1:	85 c0                	test   %eax,%eax
f0100df3:	0f 85 ff fc ff ff    	jne    f0100af8 <check_page_free_list+0x32>
f0100df9:	e9 de fc ff ff       	jmp    f0100adc <check_page_free_list+0x16>
f0100dfe:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100e05:	0f 84 d1 fc ff ff    	je     f0100adc <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e0b:	be 00 04 00 00       	mov    $0x400,%esi
f0100e10:	e9 31 fd ff ff       	jmp    f0100b46 <check_page_free_list+0x80>
}
f0100e15:	83 c4 4c             	add    $0x4c,%esp
f0100e18:	5b                   	pop    %ebx
f0100e19:	5e                   	pop    %esi
f0100e1a:	5f                   	pop    %edi
f0100e1b:	5d                   	pop    %ebp
f0100e1c:	c3                   	ret    

f0100e1d <page_init>:
{
f0100e1d:	55                   	push   %ebp
f0100e1e:	89 e5                	mov    %esp,%ebp
f0100e20:	57                   	push   %edi
f0100e21:	56                   	push   %esi
f0100e22:	53                   	push   %ebx
f0100e23:	83 ec 4c             	sub    $0x4c,%esp
	uint32_t first_free_page = (uint32_t) PADDR(boot_alloc(0));
f0100e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2b:	e8 4b fb ff ff       	call   f010097b <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100e30:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e35:	77 20                	ja     f0100e57 <page_init+0x3a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e37:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e3b:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f0100e42:	f0 
f0100e43:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
f0100e4a:	00 
f0100e4b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100e52:	e8 3d f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e57:	05 00 00 00 10       	add    $0x10000000,%eax
    page_free_list = NULL;
f0100e5c:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0100e63:	00 00 00 
    assert (first_free_page % PGSIZE == 0);
f0100e66:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0100e6b:	74 24                	je     f0100e91 <page_init+0x74>
f0100e6d:	c7 44 24 0c ed 43 10 	movl   $0xf01043ed,0xc(%esp)
f0100e74:	f0 
f0100e75:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100e7c:	f0 
f0100e7d:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
f0100e84:	00 
f0100e85:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100e8c:	e8 03 f2 ff ff       	call   f0100094 <_panic>
    assert (first_free_page > EXTPHYSMEM);
f0100e91:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e96:	77 24                	ja     f0100ebc <page_init+0x9f>
f0100e98:	c7 44 24 0c 0b 44 10 	movl   $0xf010440b,0xc(%esp)
f0100e9f:	f0 
f0100ea0:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0100ea7:	f0 
f0100ea8:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
f0100eaf:	00 
f0100eb0:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0100eb7:	e8 d8 f1 ff ff       	call   f0100094 <_panic>
    uint32_t zones[] = {0, 1, npages_basemem, first_free_page / PGSIZE, npages};  
f0100ebc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100ec3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
f0100eca:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0100ed0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100ed3:	c1 e8 0c             	shr    $0xc,%eax
f0100ed6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ed9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0100ede:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ee1:	8b 0d 3c 75 11 f0    	mov    0xf011753c,%ecx
f0100ee7:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0100eea:	89 45 c0             	mov    %eax,-0x40(%ebp)
    bool free = false; // we consider [zone[0]; zones[1]( to be in use
f0100eed:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ef2:	89 f8                	mov    %edi,%eax
f0100ef4:	89 cf                	mov    %ecx,%edi
f0100ef6:	89 c1                	mov    %eax,%ecx
        uint16_t ref = free?0:1; // dummy reference count for used pages
f0100ef8:	89 c8                	mov    %ecx,%eax
f0100efa:	83 f0 01             	xor    $0x1,%eax
f0100efd:	88 45 c6             	mov    %al,-0x3a(%ebp)
f0100f00:	0f b6 f0             	movzbl %al,%esi
        for (i = zones[zi]; i < zones[zi + 1]; i++) {
f0100f03:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100f06:	8b 10                	mov    (%eax),%edx
f0100f08:	8b 58 04             	mov    0x4(%eax),%ebx
f0100f0b:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100f12:	88 4d c7             	mov    %cl,-0x39(%ebp)
f0100f15:	eb 22                	jmp    f0100f39 <page_init+0x11c>
            pages[i].pp_ref = ref; 
f0100f17:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
f0100f1d:	66 89 74 01 04       	mov    %si,0x4(%ecx,%eax,1)
            if (free) {
f0100f22:	80 7d c7 00          	cmpb   $0x0,-0x39(%ebp)
f0100f26:	74 0b                	je     f0100f33 <page_init+0x116>
            pages[i].pp_link = page_free_list;  // unset for used pages
f0100f28:	89 3c 01             	mov    %edi,(%ecx,%eax,1)
                page_free_list = &pages[i];
f0100f2b:	89 c7                	mov    %eax,%edi
f0100f2d:	03 3d 70 79 11 f0    	add    0xf0117970,%edi
        for (i = zones[zi]; i < zones[zi + 1]; i++) {
f0100f33:	83 c2 01             	add    $0x1,%edx
f0100f36:	83 c0 08             	add    $0x8,%eax
f0100f39:	39 da                	cmp    %ebx,%edx
f0100f3b:	72 da                	jb     f0100f17 <page_init+0xfa>
f0100f3d:	83 45 c0 04          	addl   $0x4,-0x40(%ebp)
    for (zi = 0; zi < sizeof(zones)/4 - 1; zi++) {
f0100f41:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100f44:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0100f47:	74 06                	je     f0100f4f <page_init+0x132>
        free =  1 - free;
f0100f49:	0f b6 4d c6          	movzbl -0x3a(%ebp),%ecx
f0100f4d:	eb a9                	jmp    f0100ef8 <page_init+0xdb>
f0100f4f:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c
}
f0100f55:	83 c4 4c             	add    $0x4c,%esp
f0100f58:	5b                   	pop    %ebx
f0100f59:	5e                   	pop    %esi
f0100f5a:	5f                   	pop    %edi
f0100f5b:	5d                   	pop    %ebp
f0100f5c:	c3                   	ret    

f0100f5d <page_alloc>:
{
f0100f5d:	55                   	push   %ebp
f0100f5e:	89 e5                	mov    %esp,%ebp
f0100f60:	53                   	push   %ebx
f0100f61:	83 ec 14             	sub    $0x14,%esp
    if (page_free_list == NULL) {
f0100f64:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100f6a:	85 db                	test   %ebx,%ebx
f0100f6c:	74 69                	je     f0100fd7 <page_alloc+0x7a>
    page_free_list = page_free_list->pp_link;
f0100f6e:	8b 03                	mov    (%ebx),%eax
f0100f70:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	return new_page;
f0100f75:	89 d8                	mov    %ebx,%eax
    if (alloc_flags & ALLOC_ZERO) {
f0100f77:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f7b:	74 5f                	je     f0100fdc <page_alloc+0x7f>
	return (pp - pages) << PGSHIFT;
f0100f7d:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100f83:	c1 f8 03             	sar    $0x3,%eax
f0100f86:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100f89:	89 c2                	mov    %eax,%edx
f0100f8b:	c1 ea 0c             	shr    $0xc,%edx
f0100f8e:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100f94:	72 20                	jb     f0100fb6 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f96:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f9a:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0100fa1:	f0 
f0100fa2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100fa9:	00 
f0100faa:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0100fb1:	e8 de f0 ff ff       	call   f0100094 <_panic>
        memset((void*)page2kva(new_page), 0, PGSIZE);
f0100fb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fbd:	00 
f0100fbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100fc5:	00 
	return (void *)(pa + KERNBASE);
f0100fc6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fcb:	89 04 24             	mov    %eax,(%esp)
f0100fce:	e8 a4 29 00 00       	call   f0103977 <memset>
	return new_page;
f0100fd3:	89 d8                	mov    %ebx,%eax
f0100fd5:	eb 05                	jmp    f0100fdc <page_alloc+0x7f>
        return NULL;
f0100fd7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fdc:	83 c4 14             	add    $0x14,%esp
f0100fdf:	5b                   	pop    %ebx
f0100fe0:	5d                   	pop    %ebp
f0100fe1:	c3                   	ret    

f0100fe2 <page_free>:
{
f0100fe2:	55                   	push   %ebp
f0100fe3:	89 e5                	mov    %esp,%ebp
f0100fe5:	8b 45 08             	mov    0x8(%ebp),%eax
	struct PageInfo *old_pfl = page_free_list;
f0100fe8:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
    page_free_list = pp;
f0100fee:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    pp->pp_link = old_pfl;
f0100ff3:	89 10                	mov    %edx,(%eax)
}
f0100ff5:	5d                   	pop    %ebp
f0100ff6:	c3                   	ret    

f0100ff7 <page_decref>:
{
f0100ff7:	55                   	push   %ebp
f0100ff8:	89 e5                	mov    %esp,%ebp
f0100ffa:	83 ec 04             	sub    $0x4,%esp
f0100ffd:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101000:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101004:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101007:	66 89 50 04          	mov    %dx,0x4(%eax)
f010100b:	66 85 d2             	test   %dx,%dx
f010100e:	75 08                	jne    f0101018 <page_decref+0x21>
		page_free(pp);
f0101010:	89 04 24             	mov    %eax,(%esp)
f0101013:	e8 ca ff ff ff       	call   f0100fe2 <page_free>
}
f0101018:	c9                   	leave  
f0101019:	c3                   	ret    

f010101a <pgdir_walk>:
{
f010101a:	55                   	push   %ebp
f010101b:	89 e5                	mov    %esp,%ebp
f010101d:	56                   	push   %esi
f010101e:	53                   	push   %ebx
f010101f:	83 ec 10             	sub    $0x10,%esp
f0101022:	8b 45 0c             	mov    0xc(%ebp),%eax
    uintptr_t ptx = PTX(va);
f0101025:	89 c3                	mov    %eax,%ebx
f0101027:	c1 eb 0c             	shr    $0xc,%ebx
f010102a:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
    uintptr_t pdx = PDX(va);
f0101030:	c1 e8 16             	shr    $0x16,%eax
    pte_t entry = pgdir[pdx];
f0101033:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f010103a:	03 75 08             	add    0x8(%ebp),%esi
f010103d:	8b 16                	mov    (%esi),%edx
    if (entry & PTE_P) {
f010103f:	f6 c2 01             	test   $0x1,%dl
f0101042:	74 3c                	je     f0101080 <pgdir_walk+0x66>
        pgtbl = KADDR(PTE_ADDR(entry));
f0101044:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f010104a:	89 d0                	mov    %edx,%eax
f010104c:	c1 e8 0c             	shr    $0xc,%eax
f010104f:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f0101055:	72 20                	jb     f0101077 <pgdir_walk+0x5d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101057:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010105b:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0101062:	f0 
f0101063:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
f010106a:	00 
f010106b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101072:	e8 1d f0 ff ff       	call   f0100094 <_panic>
        res = pgtbl + ptx;
f0101077:	8d 84 9a 00 00 00 f0 	lea    -0x10000000(%edx,%ebx,4),%eax
f010107e:	eb 72                	jmp    f01010f2 <pgdir_walk+0xd8>
        res = NULL;
f0101080:	b8 00 00 00 00       	mov    $0x0,%eax
    } else if (create) {
f0101085:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101089:	74 67                	je     f01010f2 <pgdir_walk+0xd8>
        new_page = page_alloc(ALLOC_ZERO);
f010108b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101092:	e8 c6 fe ff ff       	call   f0100f5d <page_alloc>
        if (!new_page) {
f0101097:	85 c0                	test   %eax,%eax
f0101099:	74 52                	je     f01010ed <pgdir_walk+0xd3>
        new_page->pp_ref = 1;
f010109b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010a1:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01010a7:	c1 f8 03             	sar    $0x3,%eax
f01010aa:	c1 e0 0c             	shl    $0xc,%eax
        pgdir[pdx] = ppa | 0xfff; //PTE_P ; 
f01010ad:	89 c2                	mov    %eax,%edx
f01010af:	81 ca ff 0f 00 00    	or     $0xfff,%edx
f01010b5:	89 16                	mov    %edx,(%esi)
	if (PGNUM(pa) >= npages)
f01010b7:	89 c2                	mov    %eax,%edx
f01010b9:	c1 ea 0c             	shr    $0xc,%edx
f01010bc:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01010c2:	72 20                	jb     f01010e4 <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010c8:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f01010cf:	f0 
f01010d0:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
f01010d7:	00 
f01010d8:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01010df:	e8 b0 ef ff ff       	call   f0100094 <_panic>
        res = pgtbl + ptx;
f01010e4:	8d 84 98 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,4),%eax
f01010eb:	eb 05                	jmp    f01010f2 <pgdir_walk+0xd8>
            return NULL;
f01010ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010f2:	83 c4 10             	add    $0x10,%esp
f01010f5:	5b                   	pop    %ebx
f01010f6:	5e                   	pop    %esi
f01010f7:	5d                   	pop    %ebp
f01010f8:	c3                   	ret    

f01010f9 <boot_map_region>:
{
f01010f9:	55                   	push   %ebp
f01010fa:	89 e5                	mov    %esp,%ebp
f01010fc:	57                   	push   %edi
f01010fd:	56                   	push   %esi
f01010fe:	53                   	push   %ebx
f01010ff:	83 ec 2c             	sub    $0x2c,%esp
f0101102:	89 45 e0             	mov    %eax,-0x20(%ebp)
    uintptr_t cur_va = va;
f0101105:	89 d3                	mov    %edx,%ebx
f0101107:	8b 7d 08             	mov    0x8(%ebp),%edi
f010110a:	29 d7                	sub    %edx,%edi
    while (cur_va < va + size) {
f010110c:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
f010110f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101112:	eb 27                	jmp    f010113b <boot_map_region+0x42>
        pte_t *p = pgdir_walk(pgdir, (void *) cur_va, true); 
f0101114:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010111b:	00 
f010111c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101120:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101123:	89 04 24             	mov    %eax,(%esp)
f0101126:	e8 ef fe ff ff       	call   f010101a <pgdir_walk>
        *p = pa | perm | PTE_P; 
f010112b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010112e:	83 ca 01             	or     $0x1,%edx
f0101131:	09 d6                	or     %edx,%esi
f0101133:	89 30                	mov    %esi,(%eax)
        cur_va += PGSIZE;
f0101135:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010113b:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
    while (cur_va < va + size) {
f010113e:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101141:	72 d1                	jb     f0101114 <boot_map_region+0x1b>
}
f0101143:	83 c4 2c             	add    $0x2c,%esp
f0101146:	5b                   	pop    %ebx
f0101147:	5e                   	pop    %esi
f0101148:	5f                   	pop    %edi
f0101149:	5d                   	pop    %ebp
f010114a:	c3                   	ret    

f010114b <page_lookup>:
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	53                   	push   %ebx
f010114f:	83 ec 14             	sub    $0x14,%esp
f0101152:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, false);
f0101155:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010115c:	00 
f010115d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101160:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101164:	8b 45 08             	mov    0x8(%ebp),%eax
f0101167:	89 04 24             	mov    %eax,(%esp)
f010116a:	e8 ab fe ff ff       	call   f010101a <pgdir_walk>
    if (!pte) {
f010116f:	85 c0                	test   %eax,%eax
f0101171:	74 3f                	je     f01011b2 <page_lookup+0x67>
    if (!(*pte & PTE_P)) {
f0101173:	f6 00 01             	testb  $0x1,(%eax)
f0101176:	74 41                	je     f01011b9 <page_lookup+0x6e>
    if (pte_store) {
f0101178:	85 db                	test   %ebx,%ebx
f010117a:	74 02                	je     f010117e <page_lookup+0x33>
        *pte_store = pte;
f010117c:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010117e:	8b 00                	mov    (%eax),%eax
	if (PGNUM(pa) >= npages)
f0101180:	c1 e8 0c             	shr    $0xc,%eax
f0101183:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f0101189:	72 1c                	jb     f01011a7 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f010118b:	c7 44 24 08 b4 47 10 	movl   $0xf01047b4,0x8(%esp)
f0101192:	f0 
f0101193:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010119a:	00 
f010119b:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f01011a2:	e8 ed ee ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01011a7:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
f01011ad:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01011b0:	eb 0c                	jmp    f01011be <page_lookup+0x73>
        return NULL;
f01011b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b7:	eb 05                	jmp    f01011be <page_lookup+0x73>
        return NULL;
f01011b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01011be:	83 c4 14             	add    $0x14,%esp
f01011c1:	5b                   	pop    %ebx
f01011c2:	5d                   	pop    %ebp
f01011c3:	c3                   	ret    

f01011c4 <page_remove>:
{
f01011c4:	55                   	push   %ebp
f01011c5:	89 e5                	mov    %esp,%ebp
f01011c7:	53                   	push   %ebx
f01011c8:	83 ec 24             	sub    $0x24,%esp
f01011cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    struct PageInfo *p = page_lookup(pgdir, va, &pte_store); 
f01011ce:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011d1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011d5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011dc:	89 04 24             	mov    %eax,(%esp)
f01011df:	e8 67 ff ff ff       	call   f010114b <page_lookup>
    if (!p) { 
f01011e4:	85 c0                	test   %eax,%eax
f01011e6:	74 4d                	je     f0101235 <page_remove+0x71>
    *pte_store = 0; 
f01011e8:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011eb:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011f1:	0f 01 3b             	invlpg (%ebx)
    assert(p->pp_ref > 0);
f01011f4:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f01011f8:	66 85 d2             	test   %dx,%dx
f01011fb:	75 24                	jne    f0101221 <page_remove+0x5d>
f01011fd:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f0101204:	f0 
f0101205:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010120c:	f0 
f010120d:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f0101214:	00 
f0101215:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010121c:	e8 73 ee ff ff       	call   f0100094 <_panic>
    p->pp_ref--;
f0101221:	83 ea 01             	sub    $0x1,%edx
f0101224:	66 89 50 04          	mov    %dx,0x4(%eax)
    if (!p->pp_ref) {
f0101228:	66 85 d2             	test   %dx,%dx
f010122b:	75 08                	jne    f0101235 <page_remove+0x71>
       page_free(p); 
f010122d:	89 04 24             	mov    %eax,(%esp)
f0101230:	e8 ad fd ff ff       	call   f0100fe2 <page_free>
}
f0101235:	83 c4 24             	add    $0x24,%esp
f0101238:	5b                   	pop    %ebx
f0101239:	5d                   	pop    %ebp
f010123a:	c3                   	ret    

f010123b <page_insert>:
{
f010123b:	55                   	push   %ebp
f010123c:	89 e5                	mov    %esp,%ebp
f010123e:	57                   	push   %edi
f010123f:	56                   	push   %esi
f0101240:	53                   	push   %ebx
f0101241:	83 ec 1c             	sub    $0x1c,%esp
f0101244:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101247:	8b 7d 10             	mov    0x10(%ebp),%edi
	cprintf ("%p\n", va);
f010124a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010124e:	c7 04 24 36 44 10 f0 	movl   $0xf0104436,(%esp)
f0101255:	e8 b1 1b 00 00       	call   f0102e0b <cprintf>
	pte_t *pte = pgdir_walk(pgdir, va, true);
f010125a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101261:	00 
f0101262:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101266:	8b 45 08             	mov    0x8(%ebp),%eax
f0101269:	89 04 24             	mov    %eax,(%esp)
f010126c:	e8 a9 fd ff ff       	call   f010101a <pgdir_walk>
f0101271:	89 c6                	mov    %eax,%esi
    if (!pte) {
f0101273:	85 c0                	test   %eax,%eax
f0101275:	0f 84 8b 00 00 00    	je     f0101306 <page_insert+0xcb>
    if (*pte & PTE_P) {
f010127b:	8b 00                	mov    (%eax),%eax
f010127d:	a8 01                	test   $0x1,%al
f010127f:	74 37                	je     f01012b8 <page_insert+0x7d>
        if (page2pa(pp) == PTE_ADDR(*pte)) {
f0101281:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return (pp - pages) << PGSHIFT;
f0101286:	89 da                	mov    %ebx,%edx
f0101288:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f010128e:	c1 fa 03             	sar    $0x3,%edx
f0101291:	c1 e2 0c             	shl    $0xc,%edx
f0101294:	39 d0                	cmp    %edx,%eax
f0101296:	75 11                	jne    f01012a9 <page_insert+0x6e>
           *pte = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
f0101298:	8b 55 14             	mov    0x14(%ebp),%edx
f010129b:	83 ca 01             	or     $0x1,%edx
f010129e:	09 d0                	or     %edx,%eax
f01012a0:	89 06                	mov    %eax,(%esi)
           return 0;
f01012a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01012a7:	eb 62                	jmp    f010130b <page_insert+0xd0>
        page_remove(pgdir, va);
f01012a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b0:	89 04 24             	mov    %eax,(%esp)
f01012b3:	e8 0c ff ff ff       	call   f01011c4 <page_remove>
f01012b8:	89 d8                	mov    %ebx,%eax
f01012ba:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01012c0:	c1 f8 03             	sar    $0x3,%eax
f01012c3:	c1 e0 0c             	shl    $0xc,%eax
    cprintf("in page_insert: 1: %p, 2: with addr: %p\n", page2pa(pp), PTE_ADDR(page2pa(pp)));
f01012c6:	89 c2                	mov    %eax,%edx
f01012c8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01012ce:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d6:	c7 04 24 d4 47 10 f0 	movl   $0xf01047d4,(%esp)
f01012dd:	e8 29 1b 00 00       	call   f0102e0b <cprintf>
    *pte = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
f01012e2:	8b 55 14             	mov    0x14(%ebp),%edx
f01012e5:	83 ca 01             	or     $0x1,%edx
f01012e8:	89 d8                	mov    %ebx,%eax
f01012ea:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01012f0:	c1 f8 03             	sar    $0x3,%eax
f01012f3:	c1 e0 0c             	shl    $0xc,%eax
f01012f6:	09 d0                	or     %edx,%eax
f01012f8:	89 06                	mov    %eax,(%esi)
    pp->pp_ref++; 
f01012fa:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01012ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0101304:	eb 05                	jmp    f010130b <page_insert+0xd0>
        return -E_NO_MEM;
f0101306:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f010130b:	83 c4 1c             	add    $0x1c,%esp
f010130e:	5b                   	pop    %ebx
f010130f:	5e                   	pop    %esi
f0101310:	5f                   	pop    %edi
f0101311:	5d                   	pop    %ebp
f0101312:	c3                   	ret    

f0101313 <mem_init>:
{
f0101313:	55                   	push   %ebp
f0101314:	89 e5                	mov    %esp,%ebp
f0101316:	57                   	push   %edi
f0101317:	56                   	push   %esi
f0101318:	53                   	push   %ebx
f0101319:	83 ec 4c             	sub    $0x4c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010131c:	b8 15 00 00 00       	mov    $0x15,%eax
f0101321:	e8 2a f6 ff ff       	call   f0100950 <nvram_read>
f0101326:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101328:	b8 17 00 00 00       	mov    $0x17,%eax
f010132d:	e8 1e f6 ff ff       	call   f0100950 <nvram_read>
f0101332:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101334:	b8 34 00 00 00       	mov    $0x34,%eax
f0101339:	e8 12 f6 ff ff       	call   f0100950 <nvram_read>
f010133e:	c1 e0 06             	shl    $0x6,%eax
f0101341:	89 c2                	mov    %eax,%edx
		totalmem = 16 * 1024 + ext16mem;
f0101343:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	if (ext16mem)
f0101349:	85 d2                	test   %edx,%edx
f010134b:	75 0b                	jne    f0101358 <mem_init+0x45>
		totalmem = 1 * 1024 + extmem;
f010134d:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101353:	85 f6                	test   %esi,%esi
f0101355:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101358:	89 c2                	mov    %eax,%edx
f010135a:	c1 ea 02             	shr    $0x2,%edx
f010135d:	89 15 68 79 11 f0    	mov    %edx,0xf0117968
	npages_basemem = basemem / (PGSIZE / 1024);
f0101363:	89 da                	mov    %ebx,%edx
f0101365:	c1 ea 02             	shr    $0x2,%edx
f0101368:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010136e:	89 c2                	mov    %eax,%edx
f0101370:	29 da                	sub    %ebx,%edx
f0101372:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101376:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010137a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010137e:	c7 04 24 00 48 10 f0 	movl   $0xf0104800,(%esp)
f0101385:	e8 81 1a 00 00       	call   f0102e0b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010138a:	b8 00 10 00 00       	mov    $0x1000,%eax
f010138f:	e8 e7 f5 ff ff       	call   f010097b <boot_alloc>
f0101394:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(kern_pgdir, 0, PGSIZE);
f0101399:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01013a0:	00 
f01013a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013a8:	00 
f01013a9:	89 04 24             	mov    %eax,(%esp)
f01013ac:	e8 c6 25 00 00       	call   f0103977 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013b1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	if ((uint32_t)kva < KERNBASE)
f01013b6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013bb:	77 20                	ja     f01013dd <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013c1:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f01013c8:	f0 
f01013c9:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
f01013d0:	00 
f01013d1:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01013d8:	e8 b7 ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01013dd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013e3:	83 ca 05             	or     $0x5,%edx
f01013e6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("**************npages: %d\n", npages);
f01013ec:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01013f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013f5:	c7 04 24 3a 44 10 f0 	movl   $0xf010443a,(%esp)
f01013fc:	e8 0a 1a 00 00       	call   f0102e0b <cprintf>
	 pages = boot_alloc(sizeof(struct PageInfo) * npages);
f0101401:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101406:	c1 e0 03             	shl    $0x3,%eax
f0101409:	e8 6d f5 ff ff       	call   f010097b <boot_alloc>
f010140e:	a3 70 79 11 f0       	mov    %eax,0xf0117970
	page_init();
f0101413:	e8 05 fa ff ff       	call   f0100e1d <page_init>
	check_page_free_list(1);
f0101418:	b8 01 00 00 00       	mov    $0x1,%eax
f010141d:	e8 a4 f6 ff ff       	call   f0100ac6 <check_page_free_list>
	if (!pages)
f0101422:	83 3d 70 79 11 f0 00 	cmpl   $0x0,0xf0117970
f0101429:	75 1c                	jne    f0101447 <mem_init+0x134>
		panic("'pages' is a null pointer!");
f010142b:	c7 44 24 08 54 44 10 	movl   $0xf0104454,0x8(%esp)
f0101432:	f0 
f0101433:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f010143a:	00 
f010143b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101442:	e8 4d ec ff ff       	call   f0100094 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101447:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010144c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101451:	eb 05                	jmp    f0101458 <mem_init+0x145>
		++nfree;
f0101453:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101456:	8b 00                	mov    (%eax),%eax
f0101458:	85 c0                	test   %eax,%eax
f010145a:	75 f7                	jne    f0101453 <mem_init+0x140>
	assert((pp0 = page_alloc(0)));
f010145c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101463:	e8 f5 fa ff ff       	call   f0100f5d <page_alloc>
f0101468:	89 c7                	mov    %eax,%edi
f010146a:	85 c0                	test   %eax,%eax
f010146c:	75 24                	jne    f0101492 <mem_init+0x17f>
f010146e:	c7 44 24 0c 6f 44 10 	movl   $0xf010446f,0xc(%esp)
f0101475:	f0 
f0101476:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010147d:	f0 
f010147e:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101485:	00 
f0101486:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010148d:	e8 02 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101492:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101499:	e8 bf fa ff ff       	call   f0100f5d <page_alloc>
f010149e:	89 c6                	mov    %eax,%esi
f01014a0:	85 c0                	test   %eax,%eax
f01014a2:	75 24                	jne    f01014c8 <mem_init+0x1b5>
f01014a4:	c7 44 24 0c 85 44 10 	movl   $0xf0104485,0xc(%esp)
f01014ab:	f0 
f01014ac:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01014bb:	00 
f01014bc:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01014c3:	e8 cc eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01014c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014cf:	e8 89 fa ff ff       	call   f0100f5d <page_alloc>
f01014d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	75 24                	jne    f01014ff <mem_init+0x1ec>
f01014db:	c7 44 24 0c 9b 44 10 	movl   $0xf010449b,0xc(%esp)
f01014e2:	f0 
f01014e3:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01014f2:	00 
f01014f3:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01014fa:	e8 95 eb ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f01014ff:	39 f7                	cmp    %esi,%edi
f0101501:	75 24                	jne    f0101527 <mem_init+0x214>
f0101503:	c7 44 24 0c b1 44 10 	movl   $0xf01044b1,0xc(%esp)
f010150a:	f0 
f010150b:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101512:	f0 
f0101513:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f010151a:	00 
f010151b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101522:	e8 6d eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101527:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010152a:	39 c6                	cmp    %eax,%esi
f010152c:	74 04                	je     f0101532 <mem_init+0x21f>
f010152e:	39 c7                	cmp    %eax,%edi
f0101530:	75 24                	jne    f0101556 <mem_init+0x243>
f0101532:	c7 44 24 0c 3c 48 10 	movl   $0xf010483c,0xc(%esp)
f0101539:	f0 
f010153a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101541:	f0 
f0101542:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f0101549:	00 
f010154a:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101551:	e8 3e eb ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0101556:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010155c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101561:	c1 e0 0c             	shl    $0xc,%eax
f0101564:	89 f9                	mov    %edi,%ecx
f0101566:	29 d1                	sub    %edx,%ecx
f0101568:	c1 f9 03             	sar    $0x3,%ecx
f010156b:	c1 e1 0c             	shl    $0xc,%ecx
f010156e:	39 c1                	cmp    %eax,%ecx
f0101570:	72 24                	jb     f0101596 <mem_init+0x283>
f0101572:	c7 44 24 0c c3 44 10 	movl   $0xf01044c3,0xc(%esp)
f0101579:	f0 
f010157a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101581:	f0 
f0101582:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101589:	00 
f010158a:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101591:	e8 fe ea ff ff       	call   f0100094 <_panic>
f0101596:	89 f1                	mov    %esi,%ecx
f0101598:	29 d1                	sub    %edx,%ecx
f010159a:	c1 f9 03             	sar    $0x3,%ecx
f010159d:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01015a0:	39 c8                	cmp    %ecx,%eax
f01015a2:	77 24                	ja     f01015c8 <mem_init+0x2b5>
f01015a4:	c7 44 24 0c e0 44 10 	movl   $0xf01044e0,0xc(%esp)
f01015ab:	f0 
f01015ac:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f01015bb:	00 
f01015bc:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01015c3:	e8 cc ea ff ff       	call   f0100094 <_panic>
f01015c8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015cb:	29 d1                	sub    %edx,%ecx
f01015cd:	89 ca                	mov    %ecx,%edx
f01015cf:	c1 fa 03             	sar    $0x3,%edx
f01015d2:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01015d5:	39 d0                	cmp    %edx,%eax
f01015d7:	77 24                	ja     f01015fd <mem_init+0x2ea>
f01015d9:	c7 44 24 0c fd 44 10 	movl   $0xf01044fd,0xc(%esp)
f01015e0:	f0 
f01015e1:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01015e8:	f0 
f01015e9:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
f01015f0:	00 
f01015f1:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01015f8:	e8 97 ea ff ff       	call   f0100094 <_panic>
	fl = page_free_list;
f01015fd:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101602:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101605:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010160c:	00 00 00 
	assert(!page_alloc(0));
f010160f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101616:	e8 42 f9 ff ff       	call   f0100f5d <page_alloc>
f010161b:	85 c0                	test   %eax,%eax
f010161d:	74 24                	je     f0101643 <mem_init+0x330>
f010161f:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f0101626:	f0 
f0101627:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010162e:	f0 
f010162f:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0101636:	00 
f0101637:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010163e:	e8 51 ea ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0101643:	89 3c 24             	mov    %edi,(%esp)
f0101646:	e8 97 f9 ff ff       	call   f0100fe2 <page_free>
	page_free(pp1);
f010164b:	89 34 24             	mov    %esi,(%esp)
f010164e:	e8 8f f9 ff ff       	call   f0100fe2 <page_free>
	page_free(pp2);
f0101653:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101656:	89 04 24             	mov    %eax,(%esp)
f0101659:	e8 84 f9 ff ff       	call   f0100fe2 <page_free>
	assert((pp0 = page_alloc(0)));
f010165e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101665:	e8 f3 f8 ff ff       	call   f0100f5d <page_alloc>
f010166a:	89 c6                	mov    %eax,%esi
f010166c:	85 c0                	test   %eax,%eax
f010166e:	75 24                	jne    f0101694 <mem_init+0x381>
f0101670:	c7 44 24 0c 6f 44 10 	movl   $0xf010446f,0xc(%esp)
f0101677:	f0 
f0101678:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010167f:	f0 
f0101680:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f0101687:	00 
f0101688:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010168f:	e8 00 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101694:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010169b:	e8 bd f8 ff ff       	call   f0100f5d <page_alloc>
f01016a0:	89 c7                	mov    %eax,%edi
f01016a2:	85 c0                	test   %eax,%eax
f01016a4:	75 24                	jne    f01016ca <mem_init+0x3b7>
f01016a6:	c7 44 24 0c 85 44 10 	movl   $0xf0104485,0xc(%esp)
f01016ad:	f0 
f01016ae:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01016b5:	f0 
f01016b6:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f01016bd:	00 
f01016be:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01016c5:	e8 ca e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01016ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d1:	e8 87 f8 ff ff       	call   f0100f5d <page_alloc>
f01016d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016d9:	85 c0                	test   %eax,%eax
f01016db:	75 24                	jne    f0101701 <mem_init+0x3ee>
f01016dd:	c7 44 24 0c 9b 44 10 	movl   $0xf010449b,0xc(%esp)
f01016e4:	f0 
f01016e5:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01016ec:	f0 
f01016ed:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01016f4:	00 
f01016f5:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01016fc:	e8 93 e9 ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f0101701:	39 fe                	cmp    %edi,%esi
f0101703:	75 24                	jne    f0101729 <mem_init+0x416>
f0101705:	c7 44 24 0c b1 44 10 	movl   $0xf01044b1,0xc(%esp)
f010170c:	f0 
f010170d:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101714:	f0 
f0101715:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f010171c:	00 
f010171d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101724:	e8 6b e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101729:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010172c:	39 c7                	cmp    %eax,%edi
f010172e:	74 04                	je     f0101734 <mem_init+0x421>
f0101730:	39 c6                	cmp    %eax,%esi
f0101732:	75 24                	jne    f0101758 <mem_init+0x445>
f0101734:	c7 44 24 0c 3c 48 10 	movl   $0xf010483c,0xc(%esp)
f010173b:	f0 
f010173c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101743:	f0 
f0101744:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f010174b:	00 
f010174c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101753:	e8 3c e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101758:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010175f:	e8 f9 f7 ff ff       	call   f0100f5d <page_alloc>
f0101764:	85 c0                	test   %eax,%eax
f0101766:	74 24                	je     f010178c <mem_init+0x479>
f0101768:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f010176f:	f0 
f0101770:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101777:	f0 
f0101778:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f010177f:	00 
f0101780:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101787:	e8 08 e9 ff ff       	call   f0100094 <_panic>
f010178c:	89 f0                	mov    %esi,%eax
f010178e:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101794:	c1 f8 03             	sar    $0x3,%eax
f0101797:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010179a:	89 c2                	mov    %eax,%edx
f010179c:	c1 ea 0c             	shr    $0xc,%edx
f010179f:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01017a5:	72 20                	jb     f01017c7 <mem_init+0x4b4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017ab:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f01017b2:	f0 
f01017b3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017ba:	00 
f01017bb:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f01017c2:	e8 cd e8 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f01017c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01017ce:	00 
f01017cf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01017d6:	00 
	return (void *)(pa + KERNBASE);
f01017d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017dc:	89 04 24             	mov    %eax,(%esp)
f01017df:	e8 93 21 00 00       	call   f0103977 <memset>
	page_free(pp0);
f01017e4:	89 34 24             	mov    %esi,(%esp)
f01017e7:	e8 f6 f7 ff ff       	call   f0100fe2 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017f3:	e8 65 f7 ff ff       	call   f0100f5d <page_alloc>
f01017f8:	85 c0                	test   %eax,%eax
f01017fa:	75 24                	jne    f0101820 <mem_init+0x50d>
f01017fc:	c7 44 24 0c 29 45 10 	movl   $0xf0104529,0xc(%esp)
f0101803:	f0 
f0101804:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010180b:	f0 
f010180c:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0101813:	00 
f0101814:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010181b:	e8 74 e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101820:	39 c6                	cmp    %eax,%esi
f0101822:	74 24                	je     f0101848 <mem_init+0x535>
f0101824:	c7 44 24 0c 47 45 10 	movl   $0xf0104547,0xc(%esp)
f010182b:	f0 
f010182c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101833:	f0 
f0101834:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f010183b:	00 
f010183c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101843:	e8 4c e8 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0101848:	89 f0                	mov    %esi,%eax
f010184a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101850:	c1 f8 03             	sar    $0x3,%eax
f0101853:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101856:	89 c2                	mov    %eax,%edx
f0101858:	c1 ea 0c             	shr    $0xc,%edx
f010185b:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0101861:	72 20                	jb     f0101883 <mem_init+0x570>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101863:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101867:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f010186e:	f0 
f010186f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101876:	00 
f0101877:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f010187e:	e8 11 e8 ff ff       	call   f0100094 <_panic>
f0101883:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101889:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
		assert(c[i] == 0);
f010188f:	80 38 00             	cmpb   $0x0,(%eax)
f0101892:	74 24                	je     f01018b8 <mem_init+0x5a5>
f0101894:	c7 44 24 0c 57 45 10 	movl   $0xf0104557,0xc(%esp)
f010189b:	f0 
f010189c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01018a3:	f0 
f01018a4:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01018ab:	00 
f01018ac:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01018b3:	e8 dc e7 ff ff       	call   f0100094 <_panic>
f01018b8:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01018bb:	39 d0                	cmp    %edx,%eax
f01018bd:	75 d0                	jne    f010188f <mem_init+0x57c>
	page_free_list = fl;
f01018bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018c2:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	page_free(pp0);
f01018c7:	89 34 24             	mov    %esi,(%esp)
f01018ca:	e8 13 f7 ff ff       	call   f0100fe2 <page_free>
	page_free(pp1);
f01018cf:	89 3c 24             	mov    %edi,(%esp)
f01018d2:	e8 0b f7 ff ff       	call   f0100fe2 <page_free>
	page_free(pp2);
f01018d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018da:	89 04 24             	mov    %eax,(%esp)
f01018dd:	e8 00 f7 ff ff       	call   f0100fe2 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018e2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01018e7:	eb 05                	jmp    f01018ee <mem_init+0x5db>
		--nfree;
f01018e9:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018ec:	8b 00                	mov    (%eax),%eax
f01018ee:	85 c0                	test   %eax,%eax
f01018f0:	75 f7                	jne    f01018e9 <mem_init+0x5d6>
	assert(nfree == 0);
f01018f2:	85 db                	test   %ebx,%ebx
f01018f4:	74 24                	je     f010191a <mem_init+0x607>
f01018f6:	c7 44 24 0c 61 45 10 	movl   $0xf0104561,0xc(%esp)
f01018fd:	f0 
f01018fe:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101905:	f0 
f0101906:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f010190d:	00 
f010190e:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101915:	e8 7a e7 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f010191a:	c7 04 24 5c 48 10 f0 	movl   $0xf010485c,(%esp)
f0101921:	e8 e5 14 00 00       	call   f0102e0b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101926:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010192d:	e8 2b f6 ff ff       	call   f0100f5d <page_alloc>
f0101932:	89 c6                	mov    %eax,%esi
f0101934:	85 c0                	test   %eax,%eax
f0101936:	75 24                	jne    f010195c <mem_init+0x649>
f0101938:	c7 44 24 0c 6f 44 10 	movl   $0xf010446f,0xc(%esp)
f010193f:	f0 
f0101940:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101947:	f0 
f0101948:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f010194f:	00 
f0101950:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101957:	e8 38 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010195c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101963:	e8 f5 f5 ff ff       	call   f0100f5d <page_alloc>
f0101968:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010196b:	85 c0                	test   %eax,%eax
f010196d:	75 24                	jne    f0101993 <mem_init+0x680>
f010196f:	c7 44 24 0c 85 44 10 	movl   $0xf0104485,0xc(%esp)
f0101976:	f0 
f0101977:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010197e:	f0 
f010197f:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101986:	00 
f0101987:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010198e:	e8 01 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101993:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010199a:	e8 be f5 ff ff       	call   f0100f5d <page_alloc>
f010199f:	89 c3                	mov    %eax,%ebx
f01019a1:	85 c0                	test   %eax,%eax
f01019a3:	75 24                	jne    f01019c9 <mem_init+0x6b6>
f01019a5:	c7 44 24 0c 9b 44 10 	movl   $0xf010449b,0xc(%esp)
f01019ac:	f0 
f01019ad:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01019b4:	f0 
f01019b5:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f01019bc:	00 
f01019bd:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01019c4:	e8 cb e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019c9:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01019cc:	75 24                	jne    f01019f2 <mem_init+0x6df>
f01019ce:	c7 44 24 0c b1 44 10 	movl   $0xf01044b1,0xc(%esp)
f01019d5:	f0 
f01019d6:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01019dd:	f0 
f01019de:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f01019e5:	00 
f01019e6:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01019ed:	e8 a2 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019f2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019f5:	74 04                	je     f01019fb <mem_init+0x6e8>
f01019f7:	39 c6                	cmp    %eax,%esi
f01019f9:	75 24                	jne    f0101a1f <mem_init+0x70c>
f01019fb:	c7 44 24 0c 3c 48 10 	movl   $0xf010483c,0xc(%esp)
f0101a02:	f0 
f0101a03:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101a0a:	f0 
f0101a0b:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101a12:	00 
f0101a13:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101a1a:	e8 75 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a1f:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101a24:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a27:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101a2e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a31:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a38:	e8 20 f5 ff ff       	call   f0100f5d <page_alloc>
f0101a3d:	85 c0                	test   %eax,%eax
f0101a3f:	74 24                	je     f0101a65 <mem_init+0x752>
f0101a41:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f0101a48:	f0 
f0101a49:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101a50:	f0 
f0101a51:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101a58:	00 
f0101a59:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101a60:	e8 2f e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a65:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a68:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a73:	00 
f0101a74:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a79:	89 04 24             	mov    %eax,(%esp)
f0101a7c:	e8 ca f6 ff ff       	call   f010114b <page_lookup>
f0101a81:	85 c0                	test   %eax,%eax
f0101a83:	74 24                	je     f0101aa9 <mem_init+0x796>
f0101a85:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0101a8c:	f0 
f0101a8d:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101a94:	f0 
f0101a95:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101a9c:	00 
f0101a9d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101aa4:	e8 eb e5 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101aa9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ab0:	00 
f0101ab1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ab8:	00 
f0101ab9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101abc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ac0:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101ac5:	89 04 24             	mov    %eax,(%esp)
f0101ac8:	e8 6e f7 ff ff       	call   f010123b <page_insert>
f0101acd:	85 c0                	test   %eax,%eax
f0101acf:	78 24                	js     f0101af5 <mem_init+0x7e2>
f0101ad1:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f0101ad8:	f0 
f0101ad9:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101ae0:	f0 
f0101ae1:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101ae8:	00 
f0101ae9:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101af0:	e8 9f e5 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101af5:	89 34 24             	mov    %esi,(%esp)
f0101af8:	e8 e5 f4 ff ff       	call   f0100fe2 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101afd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b04:	00 
f0101b05:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b0c:	00 
f0101b0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b14:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101b19:	89 04 24             	mov    %eax,(%esp)
f0101b1c:	e8 1a f7 ff ff       	call   f010123b <page_insert>
f0101b21:	85 c0                	test   %eax,%eax
f0101b23:	74 24                	je     f0101b49 <mem_init+0x836>
f0101b25:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f0101b2c:	f0 
f0101b2d:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101b34:	f0 
f0101b35:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101b3c:	00 
f0101b3d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101b44:	e8 4b e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b49:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
	return (pp - pages) << PGSHIFT;
f0101b4f:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f0101b54:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b57:	8b 17                	mov    (%edi),%edx
f0101b59:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b5f:	89 f1                	mov    %esi,%ecx
f0101b61:	29 c1                	sub    %eax,%ecx
f0101b63:	89 c8                	mov    %ecx,%eax
f0101b65:	c1 f8 03             	sar    $0x3,%eax
f0101b68:	c1 e0 0c             	shl    $0xc,%eax
f0101b6b:	39 c2                	cmp    %eax,%edx
f0101b6d:	74 24                	je     f0101b93 <mem_init+0x880>
f0101b6f:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f0101b76:	f0 
f0101b77:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101b7e:	f0 
f0101b7f:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101b86:	00 
f0101b87:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101b8e:	e8 01 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b93:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b98:	89 f8                	mov    %edi,%eax
f0101b9a:	e8 b8 ee ff ff       	call   f0100a57 <check_va2pa>
f0101b9f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ba2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ba5:	c1 fa 03             	sar    $0x3,%edx
f0101ba8:	c1 e2 0c             	shl    $0xc,%edx
f0101bab:	39 d0                	cmp    %edx,%eax
f0101bad:	74 24                	je     f0101bd3 <mem_init+0x8c0>
f0101baf:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f0101bb6:	f0 
f0101bb7:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101bbe:	f0 
f0101bbf:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101bc6:	00 
f0101bc7:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101bce:	e8 c1 e4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101bd3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bd6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bdb:	74 24                	je     f0101c01 <mem_init+0x8ee>
f0101bdd:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0101be4:	f0 
f0101be5:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101bec:	f0 
f0101bed:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101bf4:	00 
f0101bf5:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101bfc:	e8 93 e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101c01:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c06:	74 24                	je     f0101c2c <mem_init+0x919>
f0101c08:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0101c0f:	f0 
f0101c10:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101c17:	f0 
f0101c18:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101c1f:	00 
f0101c20:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101c27:	e8 68 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c2c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c33:	00 
f0101c34:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c3b:	00 
f0101c3c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c40:	89 3c 24             	mov    %edi,(%esp)
f0101c43:	e8 f3 f5 ff ff       	call   f010123b <page_insert>
f0101c48:	85 c0                	test   %eax,%eax
f0101c4a:	74 24                	je     f0101c70 <mem_init+0x95d>
f0101c4c:	c7 44 24 0c 6c 49 10 	movl   $0xf010496c,0xc(%esp)
f0101c53:	f0 
f0101c54:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101c5b:	f0 
f0101c5c:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101c63:	00 
f0101c64:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101c6b:	e8 24 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c75:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101c7a:	e8 d8 ed ff ff       	call   f0100a57 <check_va2pa>
f0101c7f:	89 da                	mov    %ebx,%edx
f0101c81:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101c87:	c1 fa 03             	sar    $0x3,%edx
f0101c8a:	c1 e2 0c             	shl    $0xc,%edx
f0101c8d:	39 d0                	cmp    %edx,%eax
f0101c8f:	74 24                	je     f0101cb5 <mem_init+0x9a2>
f0101c91:	c7 44 24 0c a8 49 10 	movl   $0xf01049a8,0xc(%esp)
f0101c98:	f0 
f0101c99:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101ca0:	f0 
f0101ca1:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101ca8:	00 
f0101ca9:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101cb0:	e8 df e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cb5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cba:	74 24                	je     f0101ce0 <mem_init+0x9cd>
f0101cbc:	c7 44 24 0c 8e 45 10 	movl   $0xf010458e,0xc(%esp)
f0101cc3:	f0 
f0101cc4:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101cd3:	00 
f0101cd4:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101cdb:	e8 b4 e3 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ce0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ce7:	e8 71 f2 ff ff       	call   f0100f5d <page_alloc>
f0101cec:	85 c0                	test   %eax,%eax
f0101cee:	74 24                	je     f0101d14 <mem_init+0xa01>
f0101cf0:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f0101cf7:	f0 
f0101cf8:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101cff:	f0 
f0101d00:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101d07:	00 
f0101d08:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101d0f:	e8 80 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d14:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d1b:	00 
f0101d1c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d23:	00 
f0101d24:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d28:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101d2d:	89 04 24             	mov    %eax,(%esp)
f0101d30:	e8 06 f5 ff ff       	call   f010123b <page_insert>
f0101d35:	85 c0                	test   %eax,%eax
f0101d37:	74 24                	je     f0101d5d <mem_init+0xa4a>
f0101d39:	c7 44 24 0c 6c 49 10 	movl   $0xf010496c,0xc(%esp)
f0101d40:	f0 
f0101d41:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101d48:	f0 
f0101d49:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101d50:	00 
f0101d51:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101d58:	e8 37 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d5d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d62:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101d67:	e8 eb ec ff ff       	call   f0100a57 <check_va2pa>
f0101d6c:	89 da                	mov    %ebx,%edx
f0101d6e:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101d74:	c1 fa 03             	sar    $0x3,%edx
f0101d77:	c1 e2 0c             	shl    $0xc,%edx
f0101d7a:	39 d0                	cmp    %edx,%eax
f0101d7c:	74 24                	je     f0101da2 <mem_init+0xa8f>
f0101d7e:	c7 44 24 0c a8 49 10 	movl   $0xf01049a8,0xc(%esp)
f0101d85:	f0 
f0101d86:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101d8d:	f0 
f0101d8e:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101d95:	00 
f0101d96:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101d9d:	e8 f2 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101da2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101da7:	74 24                	je     f0101dcd <mem_init+0xaba>
f0101da9:	c7 44 24 0c 8e 45 10 	movl   $0xf010458e,0xc(%esp)
f0101db0:	f0 
f0101db1:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101dc0:	00 
f0101dc1:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101dc8:	e8 c7 e2 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101dcd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101dd4:	e8 84 f1 ff ff       	call   f0100f5d <page_alloc>
f0101dd9:	85 c0                	test   %eax,%eax
f0101ddb:	74 24                	je     f0101e01 <mem_init+0xaee>
f0101ddd:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f0101de4:	f0 
f0101de5:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101dec:	f0 
f0101ded:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101df4:	00 
f0101df5:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101dfc:	e8 93 e2 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e01:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101e07:	8b 02                	mov    (%edx),%eax
f0101e09:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101e0e:	89 c1                	mov    %eax,%ecx
f0101e10:	c1 e9 0c             	shr    $0xc,%ecx
f0101e13:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0101e19:	72 20                	jb     f0101e3b <mem_init+0xb28>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e1f:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0101e26:	f0 
f0101e27:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101e2e:	00 
f0101e2f:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101e36:	e8 59 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101e3b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e40:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e43:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e4a:	00 
f0101e4b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e52:	00 
f0101e53:	89 14 24             	mov    %edx,(%esp)
f0101e56:	e8 bf f1 ff ff       	call   f010101a <pgdir_walk>
f0101e5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101e5e:	8d 57 04             	lea    0x4(%edi),%edx
f0101e61:	39 d0                	cmp    %edx,%eax
f0101e63:	74 24                	je     f0101e89 <mem_init+0xb76>
f0101e65:	c7 44 24 0c d8 49 10 	movl   $0xf01049d8,0xc(%esp)
f0101e6c:	f0 
f0101e6d:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101e74:	f0 
f0101e75:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0101e7c:	00 
f0101e7d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101e84:	e8 0b e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e89:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e90:	00 
f0101e91:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e98:	00 
f0101e99:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e9d:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101ea2:	89 04 24             	mov    %eax,(%esp)
f0101ea5:	e8 91 f3 ff ff       	call   f010123b <page_insert>
f0101eaa:	85 c0                	test   %eax,%eax
f0101eac:	74 24                	je     f0101ed2 <mem_init+0xbbf>
f0101eae:	c7 44 24 0c 18 4a 10 	movl   $0xf0104a18,0xc(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101ebd:	f0 
f0101ebe:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101ec5:	00 
f0101ec6:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101ecd:	e8 c2 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ed2:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101ed8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101edd:	89 f8                	mov    %edi,%eax
f0101edf:	e8 73 eb ff ff       	call   f0100a57 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101ee4:	89 da                	mov    %ebx,%edx
f0101ee6:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101eec:	c1 fa 03             	sar    $0x3,%edx
f0101eef:	c1 e2 0c             	shl    $0xc,%edx
f0101ef2:	39 d0                	cmp    %edx,%eax
f0101ef4:	74 24                	je     f0101f1a <mem_init+0xc07>
f0101ef6:	c7 44 24 0c a8 49 10 	movl   $0xf01049a8,0xc(%esp)
f0101efd:	f0 
f0101efe:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101f05:	f0 
f0101f06:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101f0d:	00 
f0101f0e:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101f15:	e8 7a e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f1a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f1f:	74 24                	je     f0101f45 <mem_init+0xc32>
f0101f21:	c7 44 24 0c 8e 45 10 	movl   $0xf010458e,0xc(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101f30:	f0 
f0101f31:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101f38:	00 
f0101f39:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101f40:	e8 4f e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f45:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f4c:	00 
f0101f4d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f54:	00 
f0101f55:	89 3c 24             	mov    %edi,(%esp)
f0101f58:	e8 bd f0 ff ff       	call   f010101a <pgdir_walk>
f0101f5d:	f6 00 04             	testb  $0x4,(%eax)
f0101f60:	75 24                	jne    f0101f86 <mem_init+0xc73>
f0101f62:	c7 44 24 0c 58 4a 10 	movl   $0xf0104a58,0xc(%esp)
f0101f69:	f0 
f0101f6a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101f71:	f0 
f0101f72:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101f79:	00 
f0101f7a:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101f81:	e8 0e e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f86:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101f8b:	f6 00 04             	testb  $0x4,(%eax)
f0101f8e:	75 24                	jne    f0101fb4 <mem_init+0xca1>
f0101f90:	c7 44 24 0c 9f 45 10 	movl   $0xf010459f,0xc(%esp)
f0101f97:	f0 
f0101f98:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101f9f:	f0 
f0101fa0:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0101fa7:	00 
f0101fa8:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101faf:	e8 e0 e0 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101fb4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fbb:	00 
f0101fbc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fc3:	00 
f0101fc4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fc8:	89 04 24             	mov    %eax,(%esp)
f0101fcb:	e8 6b f2 ff ff       	call   f010123b <page_insert>
f0101fd0:	85 c0                	test   %eax,%eax
f0101fd2:	74 24                	je     f0101ff8 <mem_init+0xce5>
f0101fd4:	c7 44 24 0c 6c 49 10 	movl   $0xf010496c,0xc(%esp)
f0101fdb:	f0 
f0101fdc:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101feb:	00 
f0101fec:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0101ff3:	e8 9c e0 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ff8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fff:	00 
f0102000:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102007:	00 
f0102008:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010200d:	89 04 24             	mov    %eax,(%esp)
f0102010:	e8 05 f0 ff ff       	call   f010101a <pgdir_walk>
f0102015:	f6 00 02             	testb  $0x2,(%eax)
f0102018:	75 24                	jne    f010203e <mem_init+0xd2b>
f010201a:	c7 44 24 0c 8c 4a 10 	movl   $0xf0104a8c,0xc(%esp)
f0102021:	f0 
f0102022:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102029:	f0 
f010202a:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102031:	00 
f0102032:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102039:	e8 56 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010203e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102045:	00 
f0102046:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010204d:	00 
f010204e:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102053:	89 04 24             	mov    %eax,(%esp)
f0102056:	e8 bf ef ff ff       	call   f010101a <pgdir_walk>
f010205b:	f6 00 04             	testb  $0x4,(%eax)
f010205e:	74 24                	je     f0102084 <mem_init+0xd71>
f0102060:	c7 44 24 0c c0 4a 10 	movl   $0xf0104ac0,0xc(%esp)
f0102067:	f0 
f0102068:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010206f:	f0 
f0102070:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102077:	00 
f0102078:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010207f:	e8 10 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102084:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010208b:	00 
f010208c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102093:	00 
f0102094:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102098:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010209d:	89 04 24             	mov    %eax,(%esp)
f01020a0:	e8 96 f1 ff ff       	call   f010123b <page_insert>
f01020a5:	85 c0                	test   %eax,%eax
f01020a7:	78 24                	js     f01020cd <mem_init+0xdba>
f01020a9:	c7 44 24 0c f8 4a 10 	movl   $0xf0104af8,0xc(%esp)
f01020b0:	f0 
f01020b1:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01020b8:	f0 
f01020b9:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01020c0:	00 
f01020c1:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01020c8:	e8 c7 df ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01020cd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020d4:	00 
f01020d5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020dc:	00 
f01020dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01020e4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01020e9:	89 04 24             	mov    %eax,(%esp)
f01020ec:	e8 4a f1 ff ff       	call   f010123b <page_insert>
f01020f1:	85 c0                	test   %eax,%eax
f01020f3:	74 24                	je     f0102119 <mem_init+0xe06>
f01020f5:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f01020fc:	f0 
f01020fd:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102104:	f0 
f0102105:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010210c:	00 
f010210d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102114:	e8 7b df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102119:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102120:	00 
f0102121:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102128:	00 
f0102129:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010212e:	89 04 24             	mov    %eax,(%esp)
f0102131:	e8 e4 ee ff ff       	call   f010101a <pgdir_walk>
f0102136:	f6 00 04             	testb  $0x4,(%eax)
f0102139:	74 24                	je     f010215f <mem_init+0xe4c>
f010213b:	c7 44 24 0c c0 4a 10 	movl   $0xf0104ac0,0xc(%esp)
f0102142:	f0 
f0102143:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010214a:	f0 
f010214b:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102152:	00 
f0102153:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010215a:	e8 35 df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010215f:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0102165:	ba 00 00 00 00       	mov    $0x0,%edx
f010216a:	89 f8                	mov    %edi,%eax
f010216c:	e8 e6 e8 ff ff       	call   f0100a57 <check_va2pa>
f0102171:	89 c1                	mov    %eax,%ecx
f0102173:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102176:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102179:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010217f:	c1 f8 03             	sar    $0x3,%eax
f0102182:	c1 e0 0c             	shl    $0xc,%eax
f0102185:	39 c1                	cmp    %eax,%ecx
f0102187:	74 24                	je     f01021ad <mem_init+0xe9a>
f0102189:	c7 44 24 0c 6c 4b 10 	movl   $0xf0104b6c,0xc(%esp)
f0102190:	f0 
f0102191:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102198:	f0 
f0102199:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01021a0:	00 
f01021a1:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01021a8:	e8 e7 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021ad:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021b2:	89 f8                	mov    %edi,%eax
f01021b4:	e8 9e e8 ff ff       	call   f0100a57 <check_va2pa>
f01021b9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01021bc:	74 24                	je     f01021e2 <mem_init+0xecf>
f01021be:	c7 44 24 0c 98 4b 10 	movl   $0xf0104b98,0xc(%esp)
f01021c5:	f0 
f01021c6:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01021cd:	f0 
f01021ce:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01021d5:	00 
f01021d6:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01021dd:	e8 b2 de ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01021e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e5:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f01021ea:	74 24                	je     f0102210 <mem_init+0xefd>
f01021ec:	c7 44 24 0c b5 45 10 	movl   $0xf01045b5,0xc(%esp)
f01021f3:	f0 
f01021f4:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01021fb:	f0 
f01021fc:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102203:	00 
f0102204:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010220b:	e8 84 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102210:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102215:	74 24                	je     f010223b <mem_init+0xf28>
f0102217:	c7 44 24 0c c6 45 10 	movl   $0xf01045c6,0xc(%esp)
f010221e:	f0 
f010221f:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102226:	f0 
f0102227:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f010222e:	00 
f010222f:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102236:	e8 59 de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010223b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102242:	e8 16 ed ff ff       	call   f0100f5d <page_alloc>
f0102247:	85 c0                	test   %eax,%eax
f0102249:	74 04                	je     f010224f <mem_init+0xf3c>
f010224b:	39 c3                	cmp    %eax,%ebx
f010224d:	74 24                	je     f0102273 <mem_init+0xf60>
f010224f:	c7 44 24 0c c8 4b 10 	movl   $0xf0104bc8,0xc(%esp)
f0102256:	f0 
f0102257:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010225e:	f0 
f010225f:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102266:	00 
f0102267:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010226e:	e8 21 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102273:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010227a:	00 
f010227b:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102280:	89 04 24             	mov    %eax,(%esp)
f0102283:	e8 3c ef ff ff       	call   f01011c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102288:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f010228e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102293:	89 f8                	mov    %edi,%eax
f0102295:	e8 bd e7 ff ff       	call   f0100a57 <check_va2pa>
f010229a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010229d:	74 24                	je     f01022c3 <mem_init+0xfb0>
f010229f:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f01022a6:	f0 
f01022a7:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01022ae:	f0 
f01022af:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f01022b6:	00 
f01022b7:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01022be:	e8 d1 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022c8:	89 f8                	mov    %edi,%eax
f01022ca:	e8 88 e7 ff ff       	call   f0100a57 <check_va2pa>
f01022cf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01022d2:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01022d8:	c1 fa 03             	sar    $0x3,%edx
f01022db:	c1 e2 0c             	shl    $0xc,%edx
f01022de:	39 d0                	cmp    %edx,%eax
f01022e0:	74 24                	je     f0102306 <mem_init+0xff3>
f01022e2:	c7 44 24 0c 98 4b 10 	movl   $0xf0104b98,0xc(%esp)
f01022e9:	f0 
f01022ea:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01022f1:	f0 
f01022f2:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f01022f9:	00 
f01022fa:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102301:	e8 8e dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102306:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102309:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010230e:	74 24                	je     f0102334 <mem_init+0x1021>
f0102310:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0102317:	f0 
f0102318:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010231f:	f0 
f0102320:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102327:	00 
f0102328:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010232f:	e8 60 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102334:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102339:	74 24                	je     f010235f <mem_init+0x104c>
f010233b:	c7 44 24 0c c6 45 10 	movl   $0xf01045c6,0xc(%esp)
f0102342:	f0 
f0102343:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010234a:	f0 
f010234b:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0102352:	00 
f0102353:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010235a:	e8 35 dd ff ff       	call   f0100094 <_panic>
	// assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
	// assert(pp1->pp_ref);
	// assert(pp1->pp_link == NULL);

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010235f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102366:	00 
f0102367:	89 3c 24             	mov    %edi,(%esp)
f010236a:	e8 55 ee ff ff       	call   f01011c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010236f:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0102375:	ba 00 00 00 00       	mov    $0x0,%edx
f010237a:	89 f8                	mov    %edi,%eax
f010237c:	e8 d6 e6 ff ff       	call   f0100a57 <check_va2pa>
f0102381:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102384:	74 24                	je     f01023aa <mem_init+0x1097>
f0102386:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f010238d:	f0 
f010238e:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102395:	f0 
f0102396:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f010239d:	00 
f010239e:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01023a5:	e8 ea dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01023aa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023af:	89 f8                	mov    %edi,%eax
f01023b1:	e8 a1 e6 ff ff       	call   f0100a57 <check_va2pa>
f01023b6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023b9:	74 24                	je     f01023df <mem_init+0x10cc>
f01023bb:	c7 44 24 0c 10 4c 10 	movl   $0xf0104c10,0xc(%esp)
f01023c2:	f0 
f01023c3:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01023ca:	f0 
f01023cb:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01023d2:	00 
f01023d3:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01023da:	e8 b5 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01023df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023e2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01023e7:	74 24                	je     f010240d <mem_init+0x10fa>
f01023e9:	c7 44 24 0c d7 45 10 	movl   $0xf01045d7,0xc(%esp)
f01023f0:	f0 
f01023f1:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01023f8:	f0 
f01023f9:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102400:	00 
f0102401:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102408:	e8 87 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010240d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102412:	74 24                	je     f0102438 <mem_init+0x1125>
f0102414:	c7 44 24 0c c6 45 10 	movl   $0xf01045c6,0xc(%esp)
f010241b:	f0 
f010241c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102423:	f0 
f0102424:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f010242b:	00 
f010242c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102433:	e8 5c dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102438:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010243f:	e8 19 eb ff ff       	call   f0100f5d <page_alloc>
f0102444:	85 c0                	test   %eax,%eax
f0102446:	74 05                	je     f010244d <mem_init+0x113a>
f0102448:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010244b:	74 24                	je     f0102471 <mem_init+0x115e>
f010244d:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0102454:	f0 
f0102455:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010245c:	f0 
f010245d:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102464:	00 
f0102465:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010246c:	e8 23 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102471:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102478:	e8 e0 ea ff ff       	call   f0100f5d <page_alloc>
f010247d:	85 c0                	test   %eax,%eax
f010247f:	74 24                	je     f01024a5 <mem_init+0x1192>
f0102481:	c7 44 24 0c 1a 45 10 	movl   $0xf010451a,0xc(%esp)
f0102488:	f0 
f0102489:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102490:	f0 
f0102491:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102498:	00 
f0102499:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01024a0:	e8 ef db ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01024a5:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01024aa:	8b 08                	mov    (%eax),%ecx
f01024ac:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024b2:	89 f2                	mov    %esi,%edx
f01024b4:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01024ba:	c1 fa 03             	sar    $0x3,%edx
f01024bd:	c1 e2 0c             	shl    $0xc,%edx
f01024c0:	39 d1                	cmp    %edx,%ecx
f01024c2:	74 24                	je     f01024e8 <mem_init+0x11d5>
f01024c4:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f01024cb:	f0 
f01024cc:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01024d3:	f0 
f01024d4:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01024db:	00 
f01024dc:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01024e3:	e8 ac db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01024e8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024ee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01024f3:	74 24                	je     f0102519 <mem_init+0x1206>
f01024f5:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f01024fc:	f0 
f01024fd:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102504:	f0 
f0102505:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010250c:	00 
f010250d:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102514:	e8 7b db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102519:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010251f:	89 34 24             	mov    %esi,(%esp)
f0102522:	e8 bb ea ff ff       	call   f0100fe2 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102527:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010252e:	00 
f010252f:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102536:	00 
f0102537:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010253c:	89 04 24             	mov    %eax,(%esp)
f010253f:	e8 d6 ea ff ff       	call   f010101a <pgdir_walk>
f0102544:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102547:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010254a:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0102550:	8b 7a 04             	mov    0x4(%edx),%edi
f0102553:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f0102559:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f010255f:	89 f8                	mov    %edi,%eax
f0102561:	c1 e8 0c             	shr    $0xc,%eax
f0102564:	39 c8                	cmp    %ecx,%eax
f0102566:	72 20                	jb     f0102588 <mem_init+0x1275>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102568:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010256c:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0102573:	f0 
f0102574:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f010257b:	00 
f010257c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102583:	e8 0c db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102588:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010258e:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102591:	74 24                	je     f01025b7 <mem_init+0x12a4>
f0102593:	c7 44 24 0c e8 45 10 	movl   $0xf01045e8,0xc(%esp)
f010259a:	f0 
f010259b:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01025a2:	f0 
f01025a3:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f01025aa:	00 
f01025ab:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01025b2:	e8 dd da ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01025b7:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01025be:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
	return (pp - pages) << PGSHIFT;
f01025c4:	89 f0                	mov    %esi,%eax
f01025c6:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01025cc:	c1 f8 03             	sar    $0x3,%eax
f01025cf:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01025d2:	89 c2                	mov    %eax,%edx
f01025d4:	c1 ea 0c             	shr    $0xc,%edx
f01025d7:	39 d1                	cmp    %edx,%ecx
f01025d9:	77 20                	ja     f01025fb <mem_init+0x12e8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025df:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f01025e6:	f0 
f01025e7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025ee:	00 
f01025ef:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f01025f6:	e8 99 da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102602:	00 
f0102603:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010260a:	00 
	return (void *)(pa + KERNBASE);
f010260b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102610:	89 04 24             	mov    %eax,(%esp)
f0102613:	e8 5f 13 00 00       	call   f0103977 <memset>
	page_free(pp0);
f0102618:	89 34 24             	mov    %esi,(%esp)
f010261b:	e8 c2 e9 ff ff       	call   f0100fe2 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102620:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102627:	00 
f0102628:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010262f:	00 
f0102630:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102635:	89 04 24             	mov    %eax,(%esp)
f0102638:	e8 dd e9 ff ff       	call   f010101a <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010263d:	89 f2                	mov    %esi,%edx
f010263f:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0102645:	c1 fa 03             	sar    $0x3,%edx
f0102648:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010264b:	89 d0                	mov    %edx,%eax
f010264d:	c1 e8 0c             	shr    $0xc,%eax
f0102650:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f0102656:	72 20                	jb     f0102678 <mem_init+0x1365>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102658:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010265c:	c7 44 24 08 84 46 10 	movl   $0xf0104684,0x8(%esp)
f0102663:	f0 
f0102664:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010266b:	00 
f010266c:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0102673:	e8 1c da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102678:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010267e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102681:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102687:	f6 00 01             	testb  $0x1,(%eax)
f010268a:	74 24                	je     f01026b0 <mem_init+0x139d>
f010268c:	c7 44 24 0c 00 46 10 	movl   $0xf0104600,0xc(%esp)
f0102693:	f0 
f0102694:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010269b:	f0 
f010269c:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01026a3:	00 
f01026a4:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01026ab:	e8 e4 d9 ff ff       	call   f0100094 <_panic>
f01026b0:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01026b3:	39 d0                	cmp    %edx,%eax
f01026b5:	75 d0                	jne    f0102687 <mem_init+0x1374>
	kern_pgdir[0] = 0;
f01026b7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01026bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026c2:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01026c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01026cb:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01026d0:	89 34 24             	mov    %esi,(%esp)
f01026d3:	e8 0a e9 ff ff       	call   f0100fe2 <page_free>
	page_free(pp1);
f01026d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026db:	89 04 24             	mov    %eax,(%esp)
f01026de:	e8 ff e8 ff ff       	call   f0100fe2 <page_free>
	page_free(pp2);
f01026e3:	89 1c 24             	mov    %ebx,(%esp)
f01026e6:	e8 f7 e8 ff ff       	call   f0100fe2 <page_free>

	cprintf("check_page() succeeded!\n");
f01026eb:	c7 04 24 17 46 10 f0 	movl   $0xf0104617,(%esp)
f01026f2:	e8 14 07 00 00       	call   f0102e0b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo) * npages, 
f01026f7:	a1 70 79 11 f0       	mov    0xf0117970,%eax
	if ((uint32_t)kva < KERNBASE)
f01026fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102701:	77 20                	ja     f0102723 <mem_init+0x1410>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102703:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102707:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f010270e:	f0 
f010270f:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
f0102716:	00 
f0102717:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010271e:	e8 71 d9 ff ff       	call   f0100094 <_panic>
f0102723:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102729:	c1 e1 03             	shl    $0x3,%ecx
f010272c:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102733:	00 
	return (physaddr_t)kva - KERNBASE;
f0102734:	05 00 00 00 10       	add    $0x10000000,%eax
f0102739:	89 04 24             	mov    %eax,(%esp)
f010273c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102741:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102746:	e8 ae e9 ff ff       	call   f01010f9 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010274b:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f0102750:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102756:	77 20                	ja     f0102778 <mem_init+0x1465>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102758:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010275c:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f0102763:	f0 
f0102764:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f010276b:	00 
f010276c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102773:	e8 1c d9 ff ff       	call   f0100094 <_panic>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, 
f0102778:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010277f:	00 
f0102780:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102787:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010278c:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102791:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102796:	e8 5e e9 ff ff       	call   f01010f9 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, (~KERNBASE) - PGSIZE, 0, PTE_W | PTE_P);
f010279b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01027a2:	00 
f01027a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027aa:	b9 ff ef ff 0f       	mov    $0xfffefff,%ecx
f01027af:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027b4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01027b9:	e8 3b e9 ff ff       	call   f01010f9 <boot_map_region>
	pgdir = kern_pgdir;
f01027be:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027c4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01027c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027cc:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01027d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027db:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f01027e0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01027e3:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01027e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01027eb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01027ee:	be 00 00 00 00       	mov    $0x0,%esi
f01027f3:	eb 6d                	jmp    f0102862 <mem_init+0x154f>
f01027f5:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027fb:	89 f8                	mov    %edi,%eax
f01027fd:	e8 55 e2 ff ff       	call   f0100a57 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102802:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102809:	77 23                	ja     f010282e <mem_init+0x151b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010280b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010280e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102812:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f0102819:	f0 
f010281a:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0102821:	00 
f0102822:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102829:	e8 66 d8 ff ff       	call   f0100094 <_panic>
f010282e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102831:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102834:	39 c2                	cmp    %eax,%edx
f0102836:	74 24                	je     f010285c <mem_init+0x1549>
f0102838:	c7 44 24 0c 5c 4c 10 	movl   $0xf0104c5c,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f010285c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102862:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102865:	77 8e                	ja     f01027f5 <mem_init+0x14e2>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102867:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010286a:	c1 e0 0c             	shl    $0xc,%eax
f010286d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102870:	be 00 00 00 00       	mov    $0x0,%esi
f0102875:	eb 3b                	jmp    f01028b2 <mem_init+0x159f>
f0102877:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010287d:	89 f8                	mov    %edi,%eax
f010287f:	e8 d3 e1 ff ff       	call   f0100a57 <check_va2pa>
f0102884:	39 c6                	cmp    %eax,%esi
f0102886:	74 24                	je     f01028ac <mem_init+0x1599>
f0102888:	c7 44 24 0c 90 4c 10 	movl   $0xf0104c90,0xc(%esp)
f010288f:	f0 
f0102890:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102897:	f0 
f0102898:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f010289f:	00 
f01028a0:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01028a7:	e8 e8 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028ac:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028b2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01028b5:	72 c0                	jb     f0102877 <mem_init+0x1564>
f01028b7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01028bc:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028c2:	89 f2                	mov    %esi,%edx
f01028c4:	89 f8                	mov    %edi,%eax
f01028c6:	e8 8c e1 ff ff       	call   f0100a57 <check_va2pa>
f01028cb:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f01028ce:	39 d0                	cmp    %edx,%eax
f01028d0:	74 24                	je     f01028f6 <mem_init+0x15e3>
f01028d2:	c7 44 24 0c b8 4c 10 	movl   $0xf0104cb8,0xc(%esp)
f01028d9:	f0 
f01028da:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01028e1:	f0 
f01028e2:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f01028e9:	00 
f01028ea:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01028f1:	e8 9e d7 ff ff       	call   f0100094 <_panic>
f01028f6:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028fc:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102902:	75 be                	jne    f01028c2 <mem_init+0x15af>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102904:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102909:	89 f8                	mov    %edi,%eax
f010290b:	e8 47 e1 ff ff       	call   f0100a57 <check_va2pa>
f0102910:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102913:	75 0a                	jne    f010291f <mem_init+0x160c>
f0102915:	b8 00 00 00 00       	mov    $0x0,%eax
f010291a:	e9 f0 00 00 00       	jmp    f0102a0f <mem_init+0x16fc>
f010291f:	c7 44 24 0c 00 4d 10 	movl   $0xf0104d00,0xc(%esp)
f0102926:	f0 
f0102927:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f010292e:	f0 
f010292f:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0102936:	00 
f0102937:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f010293e:	e8 51 d7 ff ff       	call   f0100094 <_panic>
		switch (i) {
f0102943:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102948:	72 3c                	jb     f0102986 <mem_init+0x1673>
f010294a:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010294f:	76 07                	jbe    f0102958 <mem_init+0x1645>
f0102951:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102956:	75 2e                	jne    f0102986 <mem_init+0x1673>
			assert(pgdir[i] & PTE_P);
f0102958:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010295c:	0f 85 aa 00 00 00    	jne    f0102a0c <mem_init+0x16f9>
f0102962:	c7 44 24 0c 30 46 10 	movl   $0xf0104630,0xc(%esp)
f0102969:	f0 
f010296a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102971:	f0 
f0102972:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0102979:	00 
f010297a:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102981:	e8 0e d7 ff ff       	call   f0100094 <_panic>
			if (i >= PDX(KERNBASE)) {
f0102986:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010298b:	76 55                	jbe    f01029e2 <mem_init+0x16cf>
				assert(pgdir[i] & PTE_P);
f010298d:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102990:	f6 c2 01             	test   $0x1,%dl
f0102993:	75 24                	jne    f01029b9 <mem_init+0x16a6>
f0102995:	c7 44 24 0c 30 46 10 	movl   $0xf0104630,0xc(%esp)
f010299c:	f0 
f010299d:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01029a4:	f0 
f01029a5:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f01029ac:	00 
f01029ad:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01029b4:	e8 db d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01029b9:	f6 c2 02             	test   $0x2,%dl
f01029bc:	75 4e                	jne    f0102a0c <mem_init+0x16f9>
f01029be:	c7 44 24 0c 41 46 10 	movl   $0xf0104641,0xc(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f01029d5:	00 
f01029d6:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f01029dd:	e8 b2 d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] == 0);
f01029e2:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029e6:	74 24                	je     f0102a0c <mem_init+0x16f9>
f01029e8:	c7 44 24 0c 52 46 10 	movl   $0xf0104652,0xc(%esp)
f01029ef:	f0 
f01029f0:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f01029f7:	f0 
f01029f8:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f01029ff:	00 
f0102a00:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102a07:	e8 88 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a0c:	83 c0 01             	add    $0x1,%eax
f0102a0f:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a14:	0f 85 29 ff ff ff    	jne    f0102943 <mem_init+0x1630>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a1a:	c7 04 24 30 4d 10 f0 	movl   $0xf0104d30,(%esp)
f0102a21:	e8 e5 03 00 00       	call   f0102e0b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a26:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102a2b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a30:	77 20                	ja     f0102a52 <mem_init+0x173f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a32:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a36:	c7 44 24 08 90 47 10 	movl   $0xf0104790,0x8(%esp)
f0102a3d:	f0 
f0102a3e:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0102a45:	00 
f0102a46:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102a4d:	e8 42 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a52:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a57:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102a5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5f:	e8 62 e0 ff ff       	call   f0100ac6 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a64:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a67:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a6a:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a6f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a72:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a79:	e8 df e4 ff ff       	call   f0100f5d <page_alloc>
f0102a7e:	89 c3                	mov    %eax,%ebx
f0102a80:	85 c0                	test   %eax,%eax
f0102a82:	75 24                	jne    f0102aa8 <mem_init+0x1795>
f0102a84:	c7 44 24 0c 6f 44 10 	movl   $0xf010446f,0xc(%esp)
f0102a8b:	f0 
f0102a8c:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102a93:	f0 
f0102a94:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102a9b:	00 
f0102a9c:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102aa3:	e8 ec d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102aa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aaf:	e8 a9 e4 ff ff       	call   f0100f5d <page_alloc>
f0102ab4:	89 c7                	mov    %eax,%edi
f0102ab6:	85 c0                	test   %eax,%eax
f0102ab8:	75 24                	jne    f0102ade <mem_init+0x17cb>
f0102aba:	c7 44 24 0c 85 44 10 	movl   $0xf0104485,0xc(%esp)
f0102ac1:	f0 
f0102ac2:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102ac9:	f0 
f0102aca:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0102ad1:	00 
f0102ad2:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102ad9:	e8 b6 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ade:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ae5:	e8 73 e4 ff ff       	call   f0100f5d <page_alloc>
f0102aea:	89 c6                	mov    %eax,%esi
f0102aec:	85 c0                	test   %eax,%eax
f0102aee:	75 24                	jne    f0102b14 <mem_init+0x1801>
f0102af0:	c7 44 24 0c 9b 44 10 	movl   $0xf010449b,0xc(%esp)
f0102af7:	f0 
f0102af8:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102aff:	f0 
f0102b00:	c7 44 24 04 bc 03 00 	movl   $0x3bc,0x4(%esp)
f0102b07:	00 
f0102b08:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102b0f:	e8 80 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102b14:	89 1c 24             	mov    %ebx,(%esp)
f0102b17:	e8 c6 e4 ff ff       	call   f0100fe2 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b1c:	89 f8                	mov    %edi,%eax
f0102b1e:	e8 ef de ff ff       	call   f0100a12 <page2kva>
f0102b23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b2a:	00 
f0102b2b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b32:	00 
f0102b33:	89 04 24             	mov    %eax,(%esp)
f0102b36:	e8 3c 0e 00 00       	call   f0103977 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b3b:	89 f0                	mov    %esi,%eax
f0102b3d:	e8 d0 de ff ff       	call   f0100a12 <page2kva>
f0102b42:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b49:	00 
f0102b4a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b51:	00 
f0102b52:	89 04 24             	mov    %eax,(%esp)
f0102b55:	e8 1d 0e 00 00       	call   f0103977 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b61:	00 
f0102b62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b69:	00 
f0102b6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b6e:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102b73:	89 04 24             	mov    %eax,(%esp)
f0102b76:	e8 c0 e6 ff ff       	call   f010123b <page_insert>
	assert(pp1->pp_ref == 1);
f0102b7b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b80:	74 24                	je     f0102ba6 <mem_init+0x1893>
f0102b82:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0102b89:	f0 
f0102b8a:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102b91:	f0 
f0102b92:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0102b99:	00 
f0102b9a:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102ba1:	e8 ee d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ba6:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bad:	01 01 01 
f0102bb0:	74 24                	je     f0102bd6 <mem_init+0x18c3>
f0102bb2:	c7 44 24 0c 50 4d 10 	movl   $0xf0104d50,0xc(%esp)
f0102bb9:	f0 
f0102bba:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102bc1:	f0 
f0102bc2:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f0102bc9:	00 
f0102bca:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102bd1:	e8 be d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bd6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bdd:	00 
f0102bde:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102be5:	00 
f0102be6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102bea:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102bef:	89 04 24             	mov    %eax,(%esp)
f0102bf2:	e8 44 e6 ff ff       	call   f010123b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bf7:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bfe:	02 02 02 
f0102c01:	74 24                	je     f0102c27 <mem_init+0x1914>
f0102c03:	c7 44 24 0c 74 4d 10 	movl   $0xf0104d74,0xc(%esp)
f0102c0a:	f0 
f0102c0b:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102c12:	f0 
f0102c13:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f0102c1a:	00 
f0102c1b:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102c22:	e8 6d d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102c27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c2c:	74 24                	je     f0102c52 <mem_init+0x193f>
f0102c2e:	c7 44 24 0c 8e 45 10 	movl   $0xf010458e,0xc(%esp)
f0102c35:	f0 
f0102c36:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102c3d:	f0 
f0102c3e:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f0102c45:	00 
f0102c46:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102c4d:	e8 42 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102c52:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c57:	74 24                	je     f0102c7d <mem_init+0x196a>
f0102c59:	c7 44 24 0c d7 45 10 	movl   $0xf01045d7,0xc(%esp)
f0102c60:	f0 
f0102c61:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102c68:	f0 
f0102c69:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0102c70:	00 
f0102c71:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102c78:	e8 17 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c7d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c84:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c87:	89 f0                	mov    %esi,%eax
f0102c89:	e8 84 dd ff ff       	call   f0100a12 <page2kva>
f0102c8e:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102c94:	74 24                	je     f0102cba <mem_init+0x19a7>
f0102c96:	c7 44 24 0c 98 4d 10 	movl   $0xf0104d98,0xc(%esp)
f0102c9d:	f0 
f0102c9e:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102cad:	00 
f0102cae:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102cb5:	e8 da d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cba:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102cc1:	00 
f0102cc2:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102cc7:	89 04 24             	mov    %eax,(%esp)
f0102cca:	e8 f5 e4 ff ff       	call   f01011c4 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ccf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102cd4:	74 24                	je     f0102cfa <mem_init+0x19e7>
f0102cd6:	c7 44 24 0c c6 45 10 	movl   $0xf01045c6,0xc(%esp)
f0102cdd:	f0 
f0102cde:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102ce5:	f0 
f0102ce6:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0102ced:	00 
f0102cee:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102cf5:	e8 9a d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cfa:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102cff:	8b 08                	mov    (%eax),%ecx
f0102d01:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102d07:	89 da                	mov    %ebx,%edx
f0102d09:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0102d0f:	c1 fa 03             	sar    $0x3,%edx
f0102d12:	c1 e2 0c             	shl    $0xc,%edx
f0102d15:	39 d1                	cmp    %edx,%ecx
f0102d17:	74 24                	je     f0102d3d <mem_init+0x1a2a>
f0102d19:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f0102d20:	f0 
f0102d21:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102d28:	f0 
f0102d29:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102d30:	00 
f0102d31:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102d38:	e8 57 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102d3d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d43:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d48:	74 24                	je     f0102d6e <mem_init+0x1a5b>
f0102d4a:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0102d51:	f0 
f0102d52:	c7 44 24 08 37 43 10 	movl   $0xf0104337,0x8(%esp)
f0102d59:	f0 
f0102d5a:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f0102d61:	00 
f0102d62:	c7 04 24 4c 43 10 f0 	movl   $0xf010434c,(%esp)
f0102d69:	e8 26 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d6e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d74:	89 1c 24             	mov    %ebx,(%esp)
f0102d77:	e8 66 e2 ff ff       	call   f0100fe2 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d7c:	c7 04 24 c4 4d 10 f0 	movl   $0xf0104dc4,(%esp)
f0102d83:	e8 83 00 00 00       	call   f0102e0b <cprintf>
}
f0102d88:	83 c4 4c             	add    $0x4c,%esp
f0102d8b:	5b                   	pop    %ebx
f0102d8c:	5e                   	pop    %esi
f0102d8d:	5f                   	pop    %edi
f0102d8e:	5d                   	pop    %ebp
f0102d8f:	c3                   	ret    

f0102d90 <tlb_invalidate>:
{
f0102d90:	55                   	push   %ebp
f0102d91:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d93:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d96:	0f 01 38             	invlpg (%eax)
}
f0102d99:	5d                   	pop    %ebp
f0102d9a:	c3                   	ret    

f0102d9b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d9b:	55                   	push   %ebp
f0102d9c:	89 e5                	mov    %esp,%ebp
f0102d9e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102da2:	ba 70 00 00 00       	mov    $0x70,%edx
f0102da7:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102da8:	b2 71                	mov    $0x71,%dl
f0102daa:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102dab:	0f b6 c0             	movzbl %al,%eax
}
f0102dae:	5d                   	pop    %ebp
f0102daf:	c3                   	ret    

f0102db0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102db0:	55                   	push   %ebp
f0102db1:	89 e5                	mov    %esp,%ebp
f0102db3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102db7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dbc:	ee                   	out    %al,(%dx)
f0102dbd:	b2 71                	mov    $0x71,%dl
f0102dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dc2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102dc3:	5d                   	pop    %ebp
f0102dc4:	c3                   	ret    

f0102dc5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102dc5:	55                   	push   %ebp
f0102dc6:	89 e5                	mov    %esp,%ebp
f0102dc8:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102dcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dce:	89 04 24             	mov    %eax,(%esp)
f0102dd1:	e8 2b d8 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102dd6:	c9                   	leave  
f0102dd7:	c3                   	ret    

f0102dd8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102dd8:	55                   	push   %ebp
f0102dd9:	89 e5                	mov    %esp,%ebp
f0102ddb:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102dde:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102de5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102de8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dec:	8b 45 08             	mov    0x8(%ebp),%eax
f0102def:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102df3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102df6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dfa:	c7 04 24 c5 2d 10 f0 	movl   $0xf0102dc5,(%esp)
f0102e01:	e8 b8 04 00 00       	call   f01032be <vprintfmt>
	return cnt;
}
f0102e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e09:	c9                   	leave  
f0102e0a:	c3                   	ret    

f0102e0b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e0b:	55                   	push   %ebp
f0102e0c:	89 e5                	mov    %esp,%ebp
f0102e0e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e11:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e18:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e1b:	89 04 24             	mov    %eax,(%esp)
f0102e1e:	e8 b5 ff ff ff       	call   f0102dd8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e23:	c9                   	leave  
f0102e24:	c3                   	ret    

f0102e25 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e25:	55                   	push   %ebp
f0102e26:	89 e5                	mov    %esp,%ebp
f0102e28:	57                   	push   %edi
f0102e29:	56                   	push   %esi
f0102e2a:	53                   	push   %ebx
f0102e2b:	83 ec 10             	sub    $0x10,%esp
f0102e2e:	89 c6                	mov    %eax,%esi
f0102e30:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102e33:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102e36:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e39:	8b 1a                	mov    (%edx),%ebx
f0102e3b:	8b 01                	mov    (%ecx),%eax
f0102e3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102e47:	eb 77                	jmp    f0102ec0 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102e49:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e4c:	01 d8                	add    %ebx,%eax
f0102e4e:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102e53:	99                   	cltd   
f0102e54:	f7 f9                	idiv   %ecx
f0102e56:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e58:	eb 01                	jmp    f0102e5b <stab_binsearch+0x36>
			m--;
f0102e5a:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0102e5b:	39 d9                	cmp    %ebx,%ecx
f0102e5d:	7c 1d                	jl     f0102e7c <stab_binsearch+0x57>
f0102e5f:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e62:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e67:	39 fa                	cmp    %edi,%edx
f0102e69:	75 ef                	jne    f0102e5a <stab_binsearch+0x35>
f0102e6b:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e6e:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e71:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102e75:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e78:	73 18                	jae    f0102e92 <stab_binsearch+0x6d>
f0102e7a:	eb 05                	jmp    f0102e81 <stab_binsearch+0x5c>
			l = true_m + 1;
f0102e7c:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102e7f:	eb 3f                	jmp    f0102ec0 <stab_binsearch+0x9b>
			*region_left = m;
f0102e81:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e84:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102e86:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0102e89:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e90:	eb 2e                	jmp    f0102ec0 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0102e92:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e95:	73 15                	jae    f0102eac <stab_binsearch+0x87>
			*region_right = m - 1;
f0102e97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e9a:	48                   	dec    %eax
f0102e9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e9e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ea1:	89 01                	mov    %eax,(%ecx)
		any_matches = 1;
f0102ea3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102eaa:	eb 14                	jmp    f0102ec0 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102eac:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102eaf:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102eb2:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102eb4:	ff 45 0c             	incl   0xc(%ebp)
f0102eb7:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0102eb9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0102ec0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102ec3:	7e 84                	jle    f0102e49 <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0102ec5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102ec9:	75 0d                	jne    f0102ed8 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102ecb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102ece:	8b 00                	mov    (%eax),%eax
f0102ed0:	48                   	dec    %eax
f0102ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ed4:	89 07                	mov    %eax,(%edi)
f0102ed6:	eb 22                	jmp    f0102efa <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ed8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102edb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102edd:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102ee0:	8b 0b                	mov    (%ebx),%ecx
		for (l = *region_right;
f0102ee2:	eb 01                	jmp    f0102ee5 <stab_binsearch+0xc0>
		     l--)
f0102ee4:	48                   	dec    %eax
		for (l = *region_right;
f0102ee5:	39 c1                	cmp    %eax,%ecx
f0102ee7:	7d 0c                	jge    f0102ef5 <stab_binsearch+0xd0>
f0102ee9:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102eec:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ef1:	39 fa                	cmp    %edi,%edx
f0102ef3:	75 ef                	jne    f0102ee4 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0102ef5:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102ef8:	89 07                	mov    %eax,(%edi)
	}
}
f0102efa:	83 c4 10             	add    $0x10,%esp
f0102efd:	5b                   	pop    %ebx
f0102efe:	5e                   	pop    %esi
f0102eff:	5f                   	pop    %edi
f0102f00:	5d                   	pop    %ebp
f0102f01:	c3                   	ret    

f0102f02 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f02:	55                   	push   %ebp
f0102f03:	89 e5                	mov    %esp,%ebp
f0102f05:	57                   	push   %edi
f0102f06:	56                   	push   %esi
f0102f07:	53                   	push   %ebx
f0102f08:	83 ec 3c             	sub    $0x3c,%esp
f0102f0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f0e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102f11:	c7 03 f0 4d 10 f0    	movl   $0xf0104df0,(%ebx)
	info->eip_line = 0;
f0102f17:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102f1e:	c7 43 08 f0 4d 10 f0 	movl   $0xf0104df0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f25:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f2c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f2f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f36:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f3c:	76 12                	jbe    f0102f50 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f3e:	b8 0e cc 10 f0       	mov    $0xf010cc0e,%eax
f0102f43:	3d d9 ad 10 f0       	cmp    $0xf010add9,%eax
f0102f48:	0f 86 cd 01 00 00    	jbe    f010311b <debuginfo_eip+0x219>
f0102f4e:	eb 1c                	jmp    f0102f6c <debuginfo_eip+0x6a>
  	        panic("User address");
f0102f50:	c7 44 24 08 fa 4d 10 	movl   $0xf0104dfa,0x8(%esp)
f0102f57:	f0 
f0102f58:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f5f:	00 
f0102f60:	c7 04 24 07 4e 10 f0 	movl   $0xf0104e07,(%esp)
f0102f67:	e8 28 d1 ff ff       	call   f0100094 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f6c:	80 3d 0d cc 10 f0 00 	cmpb   $0x0,0xf010cc0d
f0102f73:	0f 85 a9 01 00 00    	jne    f0103122 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f79:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f80:	b8 d8 ad 10 f0       	mov    $0xf010add8,%eax
f0102f85:	2d 24 50 10 f0       	sub    $0xf0105024,%eax
f0102f8a:	c1 f8 02             	sar    $0x2,%eax
f0102f8d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f93:	83 e8 01             	sub    $0x1,%eax
f0102f96:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f99:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f9d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102fa4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102fa7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102faa:	b8 24 50 10 f0       	mov    $0xf0105024,%eax
f0102faf:	e8 71 fe ff ff       	call   f0102e25 <stab_binsearch>
	if (lfile == 0)
f0102fb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fb7:	85 c0                	test   %eax,%eax
f0102fb9:	0f 84 6a 01 00 00    	je     f0103129 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102fbf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fc5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102fc8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fcc:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102fd3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102fd6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102fd9:	b8 24 50 10 f0       	mov    $0xf0105024,%eax
f0102fde:	e8 42 fe ff ff       	call   f0102e25 <stab_binsearch>

	if (lfun <= rfun) {
f0102fe3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fe6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fe9:	39 d0                	cmp    %edx,%eax
f0102feb:	7f 3d                	jg     f010302a <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fed:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102ff0:	8d b9 24 50 10 f0    	lea    -0xfefafdc(%ecx),%edi
f0102ff6:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102ff9:	8b 89 24 50 10 f0    	mov    -0xfefafdc(%ecx),%ecx
f0102fff:	bf 0e cc 10 f0       	mov    $0xf010cc0e,%edi
f0103004:	81 ef d9 ad 10 f0    	sub    $0xf010add9,%edi
f010300a:	39 f9                	cmp    %edi,%ecx
f010300c:	73 09                	jae    f0103017 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010300e:	81 c1 d9 ad 10 f0    	add    $0xf010add9,%ecx
f0103014:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103017:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010301a:	8b 4f 08             	mov    0x8(%edi),%ecx
f010301d:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103020:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103022:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103025:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103028:	eb 0f                	jmp    f0103039 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010302a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010302d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103030:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103033:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103036:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103039:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103040:	00 
f0103041:	8b 43 08             	mov    0x8(%ebx),%eax
f0103044:	89 04 24             	mov    %eax,(%esp)
f0103047:	e8 0f 09 00 00       	call   f010395b <strfind>
f010304c:	2b 43 08             	sub    0x8(%ebx),%eax
f010304f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103052:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103056:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010305d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103060:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103063:	b8 24 50 10 f0       	mov    $0xf0105024,%eax
f0103068:	e8 b8 fd ff ff       	call   f0102e25 <stab_binsearch>
	if (lline <= rline){
f010306d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103070:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103073:	0f 8f b7 00 00 00    	jg     f0103130 <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0103079:	6b c0 0c             	imul   $0xc,%eax,%eax
f010307c:	0f b7 80 2a 50 10 f0 	movzwl -0xfefafd6(%eax),%eax
f0103083:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103086:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103089:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010308c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010308f:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103092:	81 c2 24 50 10 f0    	add    $0xf0105024,%edx
f0103098:	eb 06                	jmp    f01030a0 <debuginfo_eip+0x19e>
f010309a:	83 e8 01             	sub    $0x1,%eax
f010309d:	83 ea 0c             	sub    $0xc,%edx
f01030a0:	89 c6                	mov    %eax,%esi
f01030a2:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f01030a5:	7f 33                	jg     f01030da <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01030a7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01030ab:	80 f9 84             	cmp    $0x84,%cl
f01030ae:	74 0b                	je     f01030bb <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01030b0:	80 f9 64             	cmp    $0x64,%cl
f01030b3:	75 e5                	jne    f010309a <debuginfo_eip+0x198>
f01030b5:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01030b9:	74 df                	je     f010309a <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01030bb:	6b f6 0c             	imul   $0xc,%esi,%esi
f01030be:	8b 86 24 50 10 f0    	mov    -0xfefafdc(%esi),%eax
f01030c4:	ba 0e cc 10 f0       	mov    $0xf010cc0e,%edx
f01030c9:	81 ea d9 ad 10 f0    	sub    $0xf010add9,%edx
f01030cf:	39 d0                	cmp    %edx,%eax
f01030d1:	73 07                	jae    f01030da <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01030d3:	05 d9 ad 10 f0       	add    $0xf010add9,%eax
f01030d8:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030da:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030dd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030e0:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01030e5:	39 ca                	cmp    %ecx,%edx
f01030e7:	7d 53                	jge    f010313c <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f01030e9:	8d 42 01             	lea    0x1(%edx),%eax
f01030ec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030ef:	89 c2                	mov    %eax,%edx
f01030f1:	6b c0 0c             	imul   $0xc,%eax,%eax
f01030f4:	05 24 50 10 f0       	add    $0xf0105024,%eax
f01030f9:	89 ce                	mov    %ecx,%esi
f01030fb:	eb 04                	jmp    f0103101 <debuginfo_eip+0x1ff>
			info->eip_fn_narg++;
f01030fd:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0103101:	39 d6                	cmp    %edx,%esi
f0103103:	7e 32                	jle    f0103137 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103105:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103109:	83 c2 01             	add    $0x1,%edx
f010310c:	83 c0 0c             	add    $0xc,%eax
f010310f:	80 f9 a0             	cmp    $0xa0,%cl
f0103112:	74 e9                	je     f01030fd <debuginfo_eip+0x1fb>
	return 0;
f0103114:	b8 00 00 00 00       	mov    $0x0,%eax
f0103119:	eb 21                	jmp    f010313c <debuginfo_eip+0x23a>
		return -1;
f010311b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103120:	eb 1a                	jmp    f010313c <debuginfo_eip+0x23a>
f0103122:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103127:	eb 13                	jmp    f010313c <debuginfo_eip+0x23a>
		return -1;
f0103129:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010312e:	eb 0c                	jmp    f010313c <debuginfo_eip+0x23a>
		return -1;
f0103130:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103135:	eb 05                	jmp    f010313c <debuginfo_eip+0x23a>
	return 0;
f0103137:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010313c:	83 c4 3c             	add    $0x3c,%esp
f010313f:	5b                   	pop    %ebx
f0103140:	5e                   	pop    %esi
f0103141:	5f                   	pop    %edi
f0103142:	5d                   	pop    %ebp
f0103143:	c3                   	ret    
f0103144:	66 90                	xchg   %ax,%ax
f0103146:	66 90                	xchg   %ax,%ax
f0103148:	66 90                	xchg   %ax,%ax
f010314a:	66 90                	xchg   %ax,%ax
f010314c:	66 90                	xchg   %ax,%ax
f010314e:	66 90                	xchg   %ax,%ax

f0103150 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103150:	55                   	push   %ebp
f0103151:	89 e5                	mov    %esp,%ebp
f0103153:	57                   	push   %edi
f0103154:	56                   	push   %esi
f0103155:	53                   	push   %ebx
f0103156:	83 ec 3c             	sub    $0x3c,%esp
f0103159:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010315c:	89 d7                	mov    %edx,%edi
f010315e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103161:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103164:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103167:	89 c3                	mov    %eax,%ebx
f0103169:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010316c:	8b 45 10             	mov    0x10(%ebp),%eax
f010316f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103172:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103177:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010317a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010317d:	39 d9                	cmp    %ebx,%ecx
f010317f:	72 05                	jb     f0103186 <printnum+0x36>
f0103181:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103184:	77 69                	ja     f01031ef <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103186:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103189:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010318d:	83 ee 01             	sub    $0x1,%esi
f0103190:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103194:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103198:	8b 44 24 08          	mov    0x8(%esp),%eax
f010319c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01031a0:	89 c3                	mov    %eax,%ebx
f01031a2:	89 d6                	mov    %edx,%esi
f01031a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01031a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01031aa:	89 54 24 08          	mov    %edx,0x8(%esp)
f01031ae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01031b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031b5:	89 04 24             	mov    %eax,(%esp)
f01031b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031bf:	e8 bc 09 00 00       	call   f0103b80 <__udivdi3>
f01031c4:	89 d9                	mov    %ebx,%ecx
f01031c6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01031ca:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01031ce:	89 04 24             	mov    %eax,(%esp)
f01031d1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01031d5:	89 fa                	mov    %edi,%edx
f01031d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031da:	e8 71 ff ff ff       	call   f0103150 <printnum>
f01031df:	eb 1b                	jmp    f01031fc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01031e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031e5:	8b 45 18             	mov    0x18(%ebp),%eax
f01031e8:	89 04 24             	mov    %eax,(%esp)
f01031eb:	ff d3                	call   *%ebx
f01031ed:	eb 03                	jmp    f01031f2 <printnum+0xa2>
f01031ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f01031f2:	83 ee 01             	sub    $0x1,%esi
f01031f5:	85 f6                	test   %esi,%esi
f01031f7:	7f e8                	jg     f01031e1 <printnum+0x91>
f01031f9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031fc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103200:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103204:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103207:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010320a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010320e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103212:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103215:	89 04 24             	mov    %eax,(%esp)
f0103218:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010321b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010321f:	e8 8c 0a 00 00       	call   f0103cb0 <__umoddi3>
f0103224:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103228:	0f be 80 15 4e 10 f0 	movsbl -0xfefb1eb(%eax),%eax
f010322f:	89 04 24             	mov    %eax,(%esp)
f0103232:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103235:	ff d0                	call   *%eax
}
f0103237:	83 c4 3c             	add    $0x3c,%esp
f010323a:	5b                   	pop    %ebx
f010323b:	5e                   	pop    %esi
f010323c:	5f                   	pop    %edi
f010323d:	5d                   	pop    %ebp
f010323e:	c3                   	ret    

f010323f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010323f:	55                   	push   %ebp
f0103240:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103242:	83 fa 01             	cmp    $0x1,%edx
f0103245:	7e 0e                	jle    f0103255 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103247:	8b 10                	mov    (%eax),%edx
f0103249:	8d 4a 08             	lea    0x8(%edx),%ecx
f010324c:	89 08                	mov    %ecx,(%eax)
f010324e:	8b 02                	mov    (%edx),%eax
f0103250:	8b 52 04             	mov    0x4(%edx),%edx
f0103253:	eb 22                	jmp    f0103277 <getuint+0x38>
	else if (lflag)
f0103255:	85 d2                	test   %edx,%edx
f0103257:	74 10                	je     f0103269 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103259:	8b 10                	mov    (%eax),%edx
f010325b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010325e:	89 08                	mov    %ecx,(%eax)
f0103260:	8b 02                	mov    (%edx),%eax
f0103262:	ba 00 00 00 00       	mov    $0x0,%edx
f0103267:	eb 0e                	jmp    f0103277 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103269:	8b 10                	mov    (%eax),%edx
f010326b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010326e:	89 08                	mov    %ecx,(%eax)
f0103270:	8b 02                	mov    (%edx),%eax
f0103272:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103277:	5d                   	pop    %ebp
f0103278:	c3                   	ret    

f0103279 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103279:	55                   	push   %ebp
f010327a:	89 e5                	mov    %esp,%ebp
f010327c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010327f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103283:	8b 10                	mov    (%eax),%edx
f0103285:	3b 50 04             	cmp    0x4(%eax),%edx
f0103288:	73 0a                	jae    f0103294 <sprintputch+0x1b>
		*b->buf++ = ch;
f010328a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010328d:	89 08                	mov    %ecx,(%eax)
f010328f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103292:	88 02                	mov    %al,(%edx)
}
f0103294:	5d                   	pop    %ebp
f0103295:	c3                   	ret    

f0103296 <printfmt>:
{
f0103296:	55                   	push   %ebp
f0103297:	89 e5                	mov    %esp,%ebp
f0103299:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f010329c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010329f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032a3:	8b 45 10             	mov    0x10(%ebp),%eax
f01032a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b4:	89 04 24             	mov    %eax,(%esp)
f01032b7:	e8 02 00 00 00       	call   f01032be <vprintfmt>
}
f01032bc:	c9                   	leave  
f01032bd:	c3                   	ret    

f01032be <vprintfmt>:
{
f01032be:	55                   	push   %ebp
f01032bf:	89 e5                	mov    %esp,%ebp
f01032c1:	57                   	push   %edi
f01032c2:	56                   	push   %esi
f01032c3:	53                   	push   %ebx
f01032c4:	83 ec 3c             	sub    $0x3c,%esp
f01032c7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01032ca:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01032cd:	eb 14                	jmp    f01032e3 <vprintfmt+0x25>
			if (ch == '\0')
f01032cf:	85 c0                	test   %eax,%eax
f01032d1:	0f 84 b3 03 00 00    	je     f010368a <vprintfmt+0x3cc>
			putch(ch, putdat);
f01032d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032db:	89 04 24             	mov    %eax,(%esp)
f01032de:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01032e1:	89 f3                	mov    %esi,%ebx
f01032e3:	8d 73 01             	lea    0x1(%ebx),%esi
f01032e6:	0f b6 03             	movzbl (%ebx),%eax
f01032e9:	83 f8 25             	cmp    $0x25,%eax
f01032ec:	75 e1                	jne    f01032cf <vprintfmt+0x11>
f01032ee:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01032f2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032f9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103300:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103307:	ba 00 00 00 00       	mov    $0x0,%edx
f010330c:	eb 1d                	jmp    f010332b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f010330e:	89 de                	mov    %ebx,%esi
			padc = '-';
f0103310:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103314:	eb 15                	jmp    f010332b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0103316:	89 de                	mov    %ebx,%esi
			padc = '0';
f0103318:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010331c:	eb 0d                	jmp    f010332b <vprintfmt+0x6d>
				width = precision, precision = -1;
f010331e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103321:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103324:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010332b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010332e:	0f b6 0e             	movzbl (%esi),%ecx
f0103331:	0f b6 c1             	movzbl %cl,%eax
f0103334:	83 e9 23             	sub    $0x23,%ecx
f0103337:	80 f9 55             	cmp    $0x55,%cl
f010333a:	0f 87 2a 03 00 00    	ja     f010366a <vprintfmt+0x3ac>
f0103340:	0f b6 c9             	movzbl %cl,%ecx
f0103343:	ff 24 8d a0 4e 10 f0 	jmp    *-0xfefb160(,%ecx,4)
f010334a:	89 de                	mov    %ebx,%esi
f010334c:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f0103351:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103354:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103358:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010335b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010335e:	83 fb 09             	cmp    $0x9,%ebx
f0103361:	77 36                	ja     f0103399 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0103363:	83 c6 01             	add    $0x1,%esi
			}
f0103366:	eb e9                	jmp    f0103351 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0103368:	8b 45 14             	mov    0x14(%ebp),%eax
f010336b:	8d 48 04             	lea    0x4(%eax),%ecx
f010336e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103371:	8b 00                	mov    (%eax),%eax
f0103373:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103376:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0103378:	eb 22                	jmp    f010339c <vprintfmt+0xde>
f010337a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010337d:	85 c9                	test   %ecx,%ecx
f010337f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103384:	0f 49 c1             	cmovns %ecx,%eax
f0103387:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010338a:	89 de                	mov    %ebx,%esi
f010338c:	eb 9d                	jmp    f010332b <vprintfmt+0x6d>
f010338e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0103390:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103397:	eb 92                	jmp    f010332b <vprintfmt+0x6d>
f0103399:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f010339c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01033a0:	79 89                	jns    f010332b <vprintfmt+0x6d>
f01033a2:	e9 77 ff ff ff       	jmp    f010331e <vprintfmt+0x60>
			lflag++;
f01033a7:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01033aa:	89 de                	mov    %ebx,%esi
			goto reswitch;
f01033ac:	e9 7a ff ff ff       	jmp    f010332b <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f01033b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01033b4:	8d 50 04             	lea    0x4(%eax),%edx
f01033b7:	89 55 14             	mov    %edx,0x14(%ebp)
f01033ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033be:	8b 00                	mov    (%eax),%eax
f01033c0:	89 04 24             	mov    %eax,(%esp)
f01033c3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01033c6:	e9 18 ff ff ff       	jmp    f01032e3 <vprintfmt+0x25>
			err = va_arg(ap, int);
f01033cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ce:	8d 50 04             	lea    0x4(%eax),%edx
f01033d1:	89 55 14             	mov    %edx,0x14(%ebp)
f01033d4:	8b 00                	mov    (%eax),%eax
f01033d6:	99                   	cltd   
f01033d7:	31 d0                	xor    %edx,%eax
f01033d9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033db:	83 f8 06             	cmp    $0x6,%eax
f01033de:	7f 0b                	jg     f01033eb <vprintfmt+0x12d>
f01033e0:	8b 14 85 f8 4f 10 f0 	mov    -0xfefb008(,%eax,4),%edx
f01033e7:	85 d2                	test   %edx,%edx
f01033e9:	75 20                	jne    f010340b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01033eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033ef:	c7 44 24 08 2d 4e 10 	movl   $0xf0104e2d,0x8(%esp)
f01033f6:	f0 
f01033f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033fe:	89 04 24             	mov    %eax,(%esp)
f0103401:	e8 90 fe ff ff       	call   f0103296 <printfmt>
f0103406:	e9 d8 fe ff ff       	jmp    f01032e3 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f010340b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010340f:	c7 44 24 08 49 43 10 	movl   $0xf0104349,0x8(%esp)
f0103416:	f0 
f0103417:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010341b:	8b 45 08             	mov    0x8(%ebp),%eax
f010341e:	89 04 24             	mov    %eax,(%esp)
f0103421:	e8 70 fe ff ff       	call   f0103296 <printfmt>
f0103426:	e9 b8 fe ff ff       	jmp    f01032e3 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f010342b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010342e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103431:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0103434:	8b 45 14             	mov    0x14(%ebp),%eax
f0103437:	8d 50 04             	lea    0x4(%eax),%edx
f010343a:	89 55 14             	mov    %edx,0x14(%ebp)
f010343d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010343f:	85 f6                	test   %esi,%esi
f0103441:	b8 26 4e 10 f0       	mov    $0xf0104e26,%eax
f0103446:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103449:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010344d:	0f 84 97 00 00 00    	je     f01034ea <vprintfmt+0x22c>
f0103453:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103457:	0f 8e 9b 00 00 00    	jle    f01034f8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010345d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103461:	89 34 24             	mov    %esi,(%esp)
f0103464:	e8 9f 03 00 00       	call   f0103808 <strnlen>
f0103469:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010346c:	29 c2                	sub    %eax,%edx
f010346e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103471:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103475:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103478:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010347b:	8b 75 08             	mov    0x8(%ebp),%esi
f010347e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103481:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0103483:	eb 0f                	jmp    f0103494 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103485:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103489:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010348c:	89 04 24             	mov    %eax,(%esp)
f010348f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103491:	83 eb 01             	sub    $0x1,%ebx
f0103494:	85 db                	test   %ebx,%ebx
f0103496:	7f ed                	jg     f0103485 <vprintfmt+0x1c7>
f0103498:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010349b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010349e:	85 d2                	test   %edx,%edx
f01034a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01034a5:	0f 49 c2             	cmovns %edx,%eax
f01034a8:	29 c2                	sub    %eax,%edx
f01034aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034ad:	89 d7                	mov    %edx,%edi
f01034af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034b2:	eb 50                	jmp    f0103504 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f01034b4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01034b8:	74 1e                	je     f01034d8 <vprintfmt+0x21a>
f01034ba:	0f be d2             	movsbl %dl,%edx
f01034bd:	83 ea 20             	sub    $0x20,%edx
f01034c0:	83 fa 5e             	cmp    $0x5e,%edx
f01034c3:	76 13                	jbe    f01034d8 <vprintfmt+0x21a>
					putch('?', putdat);
f01034c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034cc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01034d3:	ff 55 08             	call   *0x8(%ebp)
f01034d6:	eb 0d                	jmp    f01034e5 <vprintfmt+0x227>
					putch(ch, putdat);
f01034d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034db:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034df:	89 04 24             	mov    %eax,(%esp)
f01034e2:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034e5:	83 ef 01             	sub    $0x1,%edi
f01034e8:	eb 1a                	jmp    f0103504 <vprintfmt+0x246>
f01034ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034ed:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034f0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034f6:	eb 0c                	jmp    f0103504 <vprintfmt+0x246>
f01034f8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034fb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103501:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103504:	83 c6 01             	add    $0x1,%esi
f0103507:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010350b:	0f be c2             	movsbl %dl,%eax
f010350e:	85 c0                	test   %eax,%eax
f0103510:	74 27                	je     f0103539 <vprintfmt+0x27b>
f0103512:	85 db                	test   %ebx,%ebx
f0103514:	78 9e                	js     f01034b4 <vprintfmt+0x1f6>
f0103516:	83 eb 01             	sub    $0x1,%ebx
f0103519:	79 99                	jns    f01034b4 <vprintfmt+0x1f6>
f010351b:	89 f8                	mov    %edi,%eax
f010351d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103520:	8b 75 08             	mov    0x8(%ebp),%esi
f0103523:	89 c3                	mov    %eax,%ebx
f0103525:	eb 1a                	jmp    f0103541 <vprintfmt+0x283>
				putch(' ', putdat);
f0103527:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010352b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103532:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103534:	83 eb 01             	sub    $0x1,%ebx
f0103537:	eb 08                	jmp    f0103541 <vprintfmt+0x283>
f0103539:	89 fb                	mov    %edi,%ebx
f010353b:	8b 75 08             	mov    0x8(%ebp),%esi
f010353e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103541:	85 db                	test   %ebx,%ebx
f0103543:	7f e2                	jg     f0103527 <vprintfmt+0x269>
f0103545:	89 75 08             	mov    %esi,0x8(%ebp)
f0103548:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010354b:	e9 93 fd ff ff       	jmp    f01032e3 <vprintfmt+0x25>
	if (lflag >= 2)
f0103550:	83 fa 01             	cmp    $0x1,%edx
f0103553:	7e 16                	jle    f010356b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103555:	8b 45 14             	mov    0x14(%ebp),%eax
f0103558:	8d 50 08             	lea    0x8(%eax),%edx
f010355b:	89 55 14             	mov    %edx,0x14(%ebp)
f010355e:	8b 50 04             	mov    0x4(%eax),%edx
f0103561:	8b 00                	mov    (%eax),%eax
f0103563:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103566:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103569:	eb 32                	jmp    f010359d <vprintfmt+0x2df>
	else if (lflag)
f010356b:	85 d2                	test   %edx,%edx
f010356d:	74 18                	je     f0103587 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010356f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103572:	8d 50 04             	lea    0x4(%eax),%edx
f0103575:	89 55 14             	mov    %edx,0x14(%ebp)
f0103578:	8b 30                	mov    (%eax),%esi
f010357a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010357d:	89 f0                	mov    %esi,%eax
f010357f:	c1 f8 1f             	sar    $0x1f,%eax
f0103582:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103585:	eb 16                	jmp    f010359d <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0103587:	8b 45 14             	mov    0x14(%ebp),%eax
f010358a:	8d 50 04             	lea    0x4(%eax),%edx
f010358d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103590:	8b 30                	mov    (%eax),%esi
f0103592:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103595:	89 f0                	mov    %esi,%eax
f0103597:	c1 f8 1f             	sar    $0x1f,%eax
f010359a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f010359d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f01035a3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f01035a8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01035ac:	0f 89 80 00 00 00    	jns    f0103632 <vprintfmt+0x374>
				putch('-', putdat);
f01035b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035b6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01035bd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01035c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035c3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035c6:	f7 d8                	neg    %eax
f01035c8:	83 d2 00             	adc    $0x0,%edx
f01035cb:	f7 da                	neg    %edx
			base = 10;
f01035cd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01035d2:	eb 5e                	jmp    f0103632 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01035d4:	8d 45 14             	lea    0x14(%ebp),%eax
f01035d7:	e8 63 fc ff ff       	call   f010323f <getuint>
			base = 10;
f01035dc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01035e1:	eb 4f                	jmp    f0103632 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01035e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01035e6:	e8 54 fc ff ff       	call   f010323f <getuint>
			base = 8;
f01035eb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01035f0:	eb 40                	jmp    f0103632 <vprintfmt+0x374>
			putch('0', putdat);
f01035f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035f6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01035fd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103600:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103604:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010360b:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f010360e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103611:	8d 50 04             	lea    0x4(%eax),%edx
f0103614:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f0103617:	8b 00                	mov    (%eax),%eax
f0103619:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f010361e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103623:	eb 0d                	jmp    f0103632 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0103625:	8d 45 14             	lea    0x14(%ebp),%eax
f0103628:	e8 12 fc ff ff       	call   f010323f <getuint>
			base = 16;
f010362d:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0103632:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103636:	89 74 24 10          	mov    %esi,0x10(%esp)
f010363a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010363d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103641:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103645:	89 04 24             	mov    %eax,(%esp)
f0103648:	89 54 24 04          	mov    %edx,0x4(%esp)
f010364c:	89 fa                	mov    %edi,%edx
f010364e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103651:	e8 fa fa ff ff       	call   f0103150 <printnum>
			break;
f0103656:	e9 88 fc ff ff       	jmp    f01032e3 <vprintfmt+0x25>
			putch(ch, putdat);
f010365b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010365f:	89 04 24             	mov    %eax,(%esp)
f0103662:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103665:	e9 79 fc ff ff       	jmp    f01032e3 <vprintfmt+0x25>
			putch('%', putdat);
f010366a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010366e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103675:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103678:	89 f3                	mov    %esi,%ebx
f010367a:	eb 03                	jmp    f010367f <vprintfmt+0x3c1>
f010367c:	83 eb 01             	sub    $0x1,%ebx
f010367f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103683:	75 f7                	jne    f010367c <vprintfmt+0x3be>
f0103685:	e9 59 fc ff ff       	jmp    f01032e3 <vprintfmt+0x25>
}
f010368a:	83 c4 3c             	add    $0x3c,%esp
f010368d:	5b                   	pop    %ebx
f010368e:	5e                   	pop    %esi
f010368f:	5f                   	pop    %edi
f0103690:	5d                   	pop    %ebp
f0103691:	c3                   	ret    

f0103692 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103692:	55                   	push   %ebp
f0103693:	89 e5                	mov    %esp,%ebp
f0103695:	83 ec 28             	sub    $0x28,%esp
f0103698:	8b 45 08             	mov    0x8(%ebp),%eax
f010369b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010369e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01036a1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01036a5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01036a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01036af:	85 c0                	test   %eax,%eax
f01036b1:	74 30                	je     f01036e3 <vsnprintf+0x51>
f01036b3:	85 d2                	test   %edx,%edx
f01036b5:	7e 2c                	jle    f01036e3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01036b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036be:	8b 45 10             	mov    0x10(%ebp),%eax
f01036c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036c5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01036c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036cc:	c7 04 24 79 32 10 f0 	movl   $0xf0103279,(%esp)
f01036d3:	e8 e6 fb ff ff       	call   f01032be <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01036d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01036db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01036de:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036e1:	eb 05                	jmp    f01036e8 <vsnprintf+0x56>
		return -E_INVAL;
f01036e3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01036e8:	c9                   	leave  
f01036e9:	c3                   	ret    

f01036ea <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01036ea:	55                   	push   %ebp
f01036eb:	89 e5                	mov    %esp,%ebp
f01036ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01036f0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01036f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01036fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103701:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103705:	8b 45 08             	mov    0x8(%ebp),%eax
f0103708:	89 04 24             	mov    %eax,(%esp)
f010370b:	e8 82 ff ff ff       	call   f0103692 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103710:	c9                   	leave  
f0103711:	c3                   	ret    
f0103712:	66 90                	xchg   %ax,%ax
f0103714:	66 90                	xchg   %ax,%ax
f0103716:	66 90                	xchg   %ax,%ax
f0103718:	66 90                	xchg   %ax,%ax
f010371a:	66 90                	xchg   %ax,%ax
f010371c:	66 90                	xchg   %ax,%ax
f010371e:	66 90                	xchg   %ax,%ax

f0103720 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103720:	55                   	push   %ebp
f0103721:	89 e5                	mov    %esp,%ebp
f0103723:	57                   	push   %edi
f0103724:	56                   	push   %esi
f0103725:	53                   	push   %ebx
f0103726:	83 ec 1c             	sub    $0x1c,%esp
f0103729:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010372c:	85 c0                	test   %eax,%eax
f010372e:	74 10                	je     f0103740 <readline+0x20>
		cprintf("%s", prompt);
f0103730:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103734:	c7 04 24 49 43 10 f0 	movl   $0xf0104349,(%esp)
f010373b:	e8 cb f6 ff ff       	call   f0102e0b <cprintf>

	i = 0;
	echoing = iscons(0);
f0103740:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103747:	e8 d6 ce ff ff       	call   f0100622 <iscons>
f010374c:	89 c7                	mov    %eax,%edi
	i = 0;
f010374e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0103753:	e8 b9 ce ff ff       	call   f0100611 <getchar>
f0103758:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010375a:	85 c0                	test   %eax,%eax
f010375c:	79 17                	jns    f0103775 <readline+0x55>
			cprintf("read error: %e\n", c);
f010375e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103762:	c7 04 24 14 50 10 f0 	movl   $0xf0105014,(%esp)
f0103769:	e8 9d f6 ff ff       	call   f0102e0b <cprintf>
			return NULL;
f010376e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103773:	eb 6d                	jmp    f01037e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103775:	83 f8 7f             	cmp    $0x7f,%eax
f0103778:	74 05                	je     f010377f <readline+0x5f>
f010377a:	83 f8 08             	cmp    $0x8,%eax
f010377d:	75 19                	jne    f0103798 <readline+0x78>
f010377f:	85 f6                	test   %esi,%esi
f0103781:	7e 15                	jle    f0103798 <readline+0x78>
			if (echoing)
f0103783:	85 ff                	test   %edi,%edi
f0103785:	74 0c                	je     f0103793 <readline+0x73>
				cputchar('\b');
f0103787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010378e:	e8 6e ce ff ff       	call   f0100601 <cputchar>
			i--;
f0103793:	83 ee 01             	sub    $0x1,%esi
f0103796:	eb bb                	jmp    f0103753 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103798:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010379e:	7f 1c                	jg     f01037bc <readline+0x9c>
f01037a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01037a3:	7e 17                	jle    f01037bc <readline+0x9c>
			if (echoing)
f01037a5:	85 ff                	test   %edi,%edi
f01037a7:	74 08                	je     f01037b1 <readline+0x91>
				cputchar(c);
f01037a9:	89 1c 24             	mov    %ebx,(%esp)
f01037ac:	e8 50 ce ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f01037b1:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01037b7:	8d 76 01             	lea    0x1(%esi),%esi
f01037ba:	eb 97                	jmp    f0103753 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01037bc:	83 fb 0d             	cmp    $0xd,%ebx
f01037bf:	74 05                	je     f01037c6 <readline+0xa6>
f01037c1:	83 fb 0a             	cmp    $0xa,%ebx
f01037c4:	75 8d                	jne    f0103753 <readline+0x33>
			if (echoing)
f01037c6:	85 ff                	test   %edi,%edi
f01037c8:	74 0c                	je     f01037d6 <readline+0xb6>
				cputchar('\n');
f01037ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01037d1:	e8 2b ce ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f01037d6:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01037dd:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01037e2:	83 c4 1c             	add    $0x1c,%esp
f01037e5:	5b                   	pop    %ebx
f01037e6:	5e                   	pop    %esi
f01037e7:	5f                   	pop    %edi
f01037e8:	5d                   	pop    %ebp
f01037e9:	c3                   	ret    
f01037ea:	66 90                	xchg   %ax,%ax
f01037ec:	66 90                	xchg   %ax,%ax
f01037ee:	66 90                	xchg   %ax,%ax

f01037f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01037f0:	55                   	push   %ebp
f01037f1:	89 e5                	mov    %esp,%ebp
f01037f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01037f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037fb:	eb 03                	jmp    f0103800 <strlen+0x10>
		n++;
f01037fd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103800:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103804:	75 f7                	jne    f01037fd <strlen+0xd>
	return n;
}
f0103806:	5d                   	pop    %ebp
f0103807:	c3                   	ret    

f0103808 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103808:	55                   	push   %ebp
f0103809:	89 e5                	mov    %esp,%ebp
f010380b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010380e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103811:	b8 00 00 00 00       	mov    $0x0,%eax
f0103816:	eb 03                	jmp    f010381b <strnlen+0x13>
		n++;
f0103818:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010381b:	39 d0                	cmp    %edx,%eax
f010381d:	74 06                	je     f0103825 <strnlen+0x1d>
f010381f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103823:	75 f3                	jne    f0103818 <strnlen+0x10>
	return n;
}
f0103825:	5d                   	pop    %ebp
f0103826:	c3                   	ret    

f0103827 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103827:	55                   	push   %ebp
f0103828:	89 e5                	mov    %esp,%ebp
f010382a:	53                   	push   %ebx
f010382b:	8b 45 08             	mov    0x8(%ebp),%eax
f010382e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103831:	89 c2                	mov    %eax,%edx
f0103833:	83 c2 01             	add    $0x1,%edx
f0103836:	83 c1 01             	add    $0x1,%ecx
f0103839:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010383d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103840:	84 db                	test   %bl,%bl
f0103842:	75 ef                	jne    f0103833 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103844:	5b                   	pop    %ebx
f0103845:	5d                   	pop    %ebp
f0103846:	c3                   	ret    

f0103847 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103847:	55                   	push   %ebp
f0103848:	89 e5                	mov    %esp,%ebp
f010384a:	53                   	push   %ebx
f010384b:	83 ec 08             	sub    $0x8,%esp
f010384e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103851:	89 1c 24             	mov    %ebx,(%esp)
f0103854:	e8 97 ff ff ff       	call   f01037f0 <strlen>
	strcpy(dst + len, src);
f0103859:	8b 55 0c             	mov    0xc(%ebp),%edx
f010385c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103860:	01 d8                	add    %ebx,%eax
f0103862:	89 04 24             	mov    %eax,(%esp)
f0103865:	e8 bd ff ff ff       	call   f0103827 <strcpy>
	return dst;
}
f010386a:	89 d8                	mov    %ebx,%eax
f010386c:	83 c4 08             	add    $0x8,%esp
f010386f:	5b                   	pop    %ebx
f0103870:	5d                   	pop    %ebp
f0103871:	c3                   	ret    

f0103872 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103872:	55                   	push   %ebp
f0103873:	89 e5                	mov    %esp,%ebp
f0103875:	56                   	push   %esi
f0103876:	53                   	push   %ebx
f0103877:	8b 75 08             	mov    0x8(%ebp),%esi
f010387a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010387d:	89 f3                	mov    %esi,%ebx
f010387f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103882:	89 f2                	mov    %esi,%edx
f0103884:	eb 0f                	jmp    f0103895 <strncpy+0x23>
		*dst++ = *src;
f0103886:	83 c2 01             	add    $0x1,%edx
f0103889:	0f b6 01             	movzbl (%ecx),%eax
f010388c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010388f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103892:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103895:	39 da                	cmp    %ebx,%edx
f0103897:	75 ed                	jne    f0103886 <strncpy+0x14>
	}
	return ret;
}
f0103899:	89 f0                	mov    %esi,%eax
f010389b:	5b                   	pop    %ebx
f010389c:	5e                   	pop    %esi
f010389d:	5d                   	pop    %ebp
f010389e:	c3                   	ret    

f010389f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010389f:	55                   	push   %ebp
f01038a0:	89 e5                	mov    %esp,%ebp
f01038a2:	56                   	push   %esi
f01038a3:	53                   	push   %ebx
f01038a4:	8b 75 08             	mov    0x8(%ebp),%esi
f01038a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01038ad:	89 f0                	mov    %esi,%eax
f01038af:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01038b3:	85 c9                	test   %ecx,%ecx
f01038b5:	75 0b                	jne    f01038c2 <strlcpy+0x23>
f01038b7:	eb 1d                	jmp    f01038d6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01038b9:	83 c0 01             	add    $0x1,%eax
f01038bc:	83 c2 01             	add    $0x1,%edx
f01038bf:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01038c2:	39 d8                	cmp    %ebx,%eax
f01038c4:	74 0b                	je     f01038d1 <strlcpy+0x32>
f01038c6:	0f b6 0a             	movzbl (%edx),%ecx
f01038c9:	84 c9                	test   %cl,%cl
f01038cb:	75 ec                	jne    f01038b9 <strlcpy+0x1a>
f01038cd:	89 c2                	mov    %eax,%edx
f01038cf:	eb 02                	jmp    f01038d3 <strlcpy+0x34>
f01038d1:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f01038d3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01038d6:	29 f0                	sub    %esi,%eax
}
f01038d8:	5b                   	pop    %ebx
f01038d9:	5e                   	pop    %esi
f01038da:	5d                   	pop    %ebp
f01038db:	c3                   	ret    

f01038dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01038dc:	55                   	push   %ebp
f01038dd:	89 e5                	mov    %esp,%ebp
f01038df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01038e5:	eb 06                	jmp    f01038ed <strcmp+0x11>
		p++, q++;
f01038e7:	83 c1 01             	add    $0x1,%ecx
f01038ea:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01038ed:	0f b6 01             	movzbl (%ecx),%eax
f01038f0:	84 c0                	test   %al,%al
f01038f2:	74 04                	je     f01038f8 <strcmp+0x1c>
f01038f4:	3a 02                	cmp    (%edx),%al
f01038f6:	74 ef                	je     f01038e7 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01038f8:	0f b6 c0             	movzbl %al,%eax
f01038fb:	0f b6 12             	movzbl (%edx),%edx
f01038fe:	29 d0                	sub    %edx,%eax
}
f0103900:	5d                   	pop    %ebp
f0103901:	c3                   	ret    

f0103902 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103902:	55                   	push   %ebp
f0103903:	89 e5                	mov    %esp,%ebp
f0103905:	53                   	push   %ebx
f0103906:	8b 45 08             	mov    0x8(%ebp),%eax
f0103909:	8b 55 0c             	mov    0xc(%ebp),%edx
f010390c:	89 c3                	mov    %eax,%ebx
f010390e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103911:	eb 06                	jmp    f0103919 <strncmp+0x17>
		n--, p++, q++;
f0103913:	83 c0 01             	add    $0x1,%eax
f0103916:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103919:	39 d8                	cmp    %ebx,%eax
f010391b:	74 15                	je     f0103932 <strncmp+0x30>
f010391d:	0f b6 08             	movzbl (%eax),%ecx
f0103920:	84 c9                	test   %cl,%cl
f0103922:	74 04                	je     f0103928 <strncmp+0x26>
f0103924:	3a 0a                	cmp    (%edx),%cl
f0103926:	74 eb                	je     f0103913 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103928:	0f b6 00             	movzbl (%eax),%eax
f010392b:	0f b6 12             	movzbl (%edx),%edx
f010392e:	29 d0                	sub    %edx,%eax
f0103930:	eb 05                	jmp    f0103937 <strncmp+0x35>
		return 0;
f0103932:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103937:	5b                   	pop    %ebx
f0103938:	5d                   	pop    %ebp
f0103939:	c3                   	ret    

f010393a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010393a:	55                   	push   %ebp
f010393b:	89 e5                	mov    %esp,%ebp
f010393d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103940:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103944:	eb 07                	jmp    f010394d <strchr+0x13>
		if (*s == c)
f0103946:	38 ca                	cmp    %cl,%dl
f0103948:	74 0f                	je     f0103959 <strchr+0x1f>
	for (; *s; s++)
f010394a:	83 c0 01             	add    $0x1,%eax
f010394d:	0f b6 10             	movzbl (%eax),%edx
f0103950:	84 d2                	test   %dl,%dl
f0103952:	75 f2                	jne    f0103946 <strchr+0xc>
			return (char *) s;
	return 0;
f0103954:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103959:	5d                   	pop    %ebp
f010395a:	c3                   	ret    

f010395b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010395b:	55                   	push   %ebp
f010395c:	89 e5                	mov    %esp,%ebp
f010395e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103961:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103965:	eb 07                	jmp    f010396e <strfind+0x13>
		if (*s == c)
f0103967:	38 ca                	cmp    %cl,%dl
f0103969:	74 0a                	je     f0103975 <strfind+0x1a>
	for (; *s; s++)
f010396b:	83 c0 01             	add    $0x1,%eax
f010396e:	0f b6 10             	movzbl (%eax),%edx
f0103971:	84 d2                	test   %dl,%dl
f0103973:	75 f2                	jne    f0103967 <strfind+0xc>
			break;
	return (char *) s;
}
f0103975:	5d                   	pop    %ebp
f0103976:	c3                   	ret    

f0103977 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103977:	55                   	push   %ebp
f0103978:	89 e5                	mov    %esp,%ebp
f010397a:	57                   	push   %edi
f010397b:	56                   	push   %esi
f010397c:	53                   	push   %ebx
f010397d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103980:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103983:	85 c9                	test   %ecx,%ecx
f0103985:	74 36                	je     f01039bd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103987:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010398d:	75 28                	jne    f01039b7 <memset+0x40>
f010398f:	f6 c1 03             	test   $0x3,%cl
f0103992:	75 23                	jne    f01039b7 <memset+0x40>
		c &= 0xFF;
f0103994:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103998:	89 d3                	mov    %edx,%ebx
f010399a:	c1 e3 08             	shl    $0x8,%ebx
f010399d:	89 d6                	mov    %edx,%esi
f010399f:	c1 e6 18             	shl    $0x18,%esi
f01039a2:	89 d0                	mov    %edx,%eax
f01039a4:	c1 e0 10             	shl    $0x10,%eax
f01039a7:	09 f0                	or     %esi,%eax
f01039a9:	09 c2                	or     %eax,%edx
f01039ab:	89 d0                	mov    %edx,%eax
f01039ad:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01039af:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01039b2:	fc                   	cld    
f01039b3:	f3 ab                	rep stos %eax,%es:(%edi)
f01039b5:	eb 06                	jmp    f01039bd <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01039b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039ba:	fc                   	cld    
f01039bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01039bd:	89 f8                	mov    %edi,%eax
f01039bf:	5b                   	pop    %ebx
f01039c0:	5e                   	pop    %esi
f01039c1:	5f                   	pop    %edi
f01039c2:	5d                   	pop    %ebp
f01039c3:	c3                   	ret    

f01039c4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039c4:	55                   	push   %ebp
f01039c5:	89 e5                	mov    %esp,%ebp
f01039c7:	57                   	push   %edi
f01039c8:	56                   	push   %esi
f01039c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039d2:	39 c6                	cmp    %eax,%esi
f01039d4:	73 35                	jae    f0103a0b <memmove+0x47>
f01039d6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039d9:	39 d0                	cmp    %edx,%eax
f01039db:	73 2e                	jae    f0103a0b <memmove+0x47>
		s += n;
		d += n;
f01039dd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01039e0:	89 d6                	mov    %edx,%esi
f01039e2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039e4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039ea:	75 13                	jne    f01039ff <memmove+0x3b>
f01039ec:	f6 c1 03             	test   $0x3,%cl
f01039ef:	75 0e                	jne    f01039ff <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039f1:	83 ef 04             	sub    $0x4,%edi
f01039f4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039f7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01039fa:	fd                   	std    
f01039fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039fd:	eb 09                	jmp    f0103a08 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039ff:	83 ef 01             	sub    $0x1,%edi
f0103a02:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103a05:	fd                   	std    
f0103a06:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103a08:	fc                   	cld    
f0103a09:	eb 1d                	jmp    f0103a28 <memmove+0x64>
f0103a0b:	89 f2                	mov    %esi,%edx
f0103a0d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a0f:	f6 c2 03             	test   $0x3,%dl
f0103a12:	75 0f                	jne    f0103a23 <memmove+0x5f>
f0103a14:	f6 c1 03             	test   $0x3,%cl
f0103a17:	75 0a                	jne    f0103a23 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103a19:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103a1c:	89 c7                	mov    %eax,%edi
f0103a1e:	fc                   	cld    
f0103a1f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a21:	eb 05                	jmp    f0103a28 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f0103a23:	89 c7                	mov    %eax,%edi
f0103a25:	fc                   	cld    
f0103a26:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a28:	5e                   	pop    %esi
f0103a29:	5f                   	pop    %edi
f0103a2a:	5d                   	pop    %ebp
f0103a2b:	c3                   	ret    

f0103a2c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103a2c:	55                   	push   %ebp
f0103a2d:	89 e5                	mov    %esp,%ebp
f0103a2f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a32:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a39:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a40:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a43:	89 04 24             	mov    %eax,(%esp)
f0103a46:	e8 79 ff ff ff       	call   f01039c4 <memmove>
}
f0103a4b:	c9                   	leave  
f0103a4c:	c3                   	ret    

f0103a4d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a4d:	55                   	push   %ebp
f0103a4e:	89 e5                	mov    %esp,%ebp
f0103a50:	56                   	push   %esi
f0103a51:	53                   	push   %ebx
f0103a52:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a58:	89 d6                	mov    %edx,%esi
f0103a5a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a5d:	eb 1a                	jmp    f0103a79 <memcmp+0x2c>
		if (*s1 != *s2)
f0103a5f:	0f b6 02             	movzbl (%edx),%eax
f0103a62:	0f b6 19             	movzbl (%ecx),%ebx
f0103a65:	38 d8                	cmp    %bl,%al
f0103a67:	74 0a                	je     f0103a73 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103a69:	0f b6 c0             	movzbl %al,%eax
f0103a6c:	0f b6 db             	movzbl %bl,%ebx
f0103a6f:	29 d8                	sub    %ebx,%eax
f0103a71:	eb 0f                	jmp    f0103a82 <memcmp+0x35>
		s1++, s2++;
f0103a73:	83 c2 01             	add    $0x1,%edx
f0103a76:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0103a79:	39 f2                	cmp    %esi,%edx
f0103a7b:	75 e2                	jne    f0103a5f <memcmp+0x12>
	}

	return 0;
f0103a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a82:	5b                   	pop    %ebx
f0103a83:	5e                   	pop    %esi
f0103a84:	5d                   	pop    %ebp
f0103a85:	c3                   	ret    

f0103a86 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a86:	55                   	push   %ebp
f0103a87:	89 e5                	mov    %esp,%ebp
f0103a89:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a8f:	89 c2                	mov    %eax,%edx
f0103a91:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a94:	eb 07                	jmp    f0103a9d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a96:	38 08                	cmp    %cl,(%eax)
f0103a98:	74 07                	je     f0103aa1 <memfind+0x1b>
	for (; s < ends; s++)
f0103a9a:	83 c0 01             	add    $0x1,%eax
f0103a9d:	39 d0                	cmp    %edx,%eax
f0103a9f:	72 f5                	jb     f0103a96 <memfind+0x10>
			break;
	return (void *) s;
}
f0103aa1:	5d                   	pop    %ebp
f0103aa2:	c3                   	ret    

f0103aa3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103aa3:	55                   	push   %ebp
f0103aa4:	89 e5                	mov    %esp,%ebp
f0103aa6:	57                   	push   %edi
f0103aa7:	56                   	push   %esi
f0103aa8:	53                   	push   %ebx
f0103aa9:	8b 55 08             	mov    0x8(%ebp),%edx
f0103aac:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103aaf:	eb 03                	jmp    f0103ab4 <strtol+0x11>
		s++;
f0103ab1:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103ab4:	0f b6 0a             	movzbl (%edx),%ecx
f0103ab7:	80 f9 09             	cmp    $0x9,%cl
f0103aba:	74 f5                	je     f0103ab1 <strtol+0xe>
f0103abc:	80 f9 20             	cmp    $0x20,%cl
f0103abf:	74 f0                	je     f0103ab1 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103ac1:	80 f9 2b             	cmp    $0x2b,%cl
f0103ac4:	75 0a                	jne    f0103ad0 <strtol+0x2d>
		s++;
f0103ac6:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103ac9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ace:	eb 11                	jmp    f0103ae1 <strtol+0x3e>
f0103ad0:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0103ad5:	80 f9 2d             	cmp    $0x2d,%cl
f0103ad8:	75 07                	jne    f0103ae1 <strtol+0x3e>
		s++, neg = 1;
f0103ada:	8d 52 01             	lea    0x1(%edx),%edx
f0103add:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ae1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103ae6:	75 15                	jne    f0103afd <strtol+0x5a>
f0103ae8:	80 3a 30             	cmpb   $0x30,(%edx)
f0103aeb:	75 10                	jne    f0103afd <strtol+0x5a>
f0103aed:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103af1:	75 0a                	jne    f0103afd <strtol+0x5a>
		s += 2, base = 16;
f0103af3:	83 c2 02             	add    $0x2,%edx
f0103af6:	b8 10 00 00 00       	mov    $0x10,%eax
f0103afb:	eb 10                	jmp    f0103b0d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103afd:	85 c0                	test   %eax,%eax
f0103aff:	75 0c                	jne    f0103b0d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b01:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f0103b03:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b06:	75 05                	jne    f0103b0d <strtol+0x6a>
		s++, base = 8;
f0103b08:	83 c2 01             	add    $0x1,%edx
f0103b0b:	b0 08                	mov    $0x8,%al
		base = 10;
f0103b0d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b12:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b15:	0f b6 0a             	movzbl (%edx),%ecx
f0103b18:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103b1b:	89 f0                	mov    %esi,%eax
f0103b1d:	3c 09                	cmp    $0x9,%al
f0103b1f:	77 08                	ja     f0103b29 <strtol+0x86>
			dig = *s - '0';
f0103b21:	0f be c9             	movsbl %cl,%ecx
f0103b24:	83 e9 30             	sub    $0x30,%ecx
f0103b27:	eb 20                	jmp    f0103b49 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103b29:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103b2c:	89 f0                	mov    %esi,%eax
f0103b2e:	3c 19                	cmp    $0x19,%al
f0103b30:	77 08                	ja     f0103b3a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103b32:	0f be c9             	movsbl %cl,%ecx
f0103b35:	83 e9 57             	sub    $0x57,%ecx
f0103b38:	eb 0f                	jmp    f0103b49 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103b3a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103b3d:	89 f0                	mov    %esi,%eax
f0103b3f:	3c 19                	cmp    $0x19,%al
f0103b41:	77 16                	ja     f0103b59 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103b43:	0f be c9             	movsbl %cl,%ecx
f0103b46:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b49:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103b4c:	7d 0f                	jge    f0103b5d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103b4e:	83 c2 01             	add    $0x1,%edx
f0103b51:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103b55:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103b57:	eb bc                	jmp    f0103b15 <strtol+0x72>
f0103b59:	89 d8                	mov    %ebx,%eax
f0103b5b:	eb 02                	jmp    f0103b5f <strtol+0xbc>
f0103b5d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103b5f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b63:	74 05                	je     f0103b6a <strtol+0xc7>
		*endptr = (char *) s;
f0103b65:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b68:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103b6a:	f7 d8                	neg    %eax
f0103b6c:	85 ff                	test   %edi,%edi
f0103b6e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103b71:	5b                   	pop    %ebx
f0103b72:	5e                   	pop    %esi
f0103b73:	5f                   	pop    %edi
f0103b74:	5d                   	pop    %ebp
f0103b75:	c3                   	ret    
f0103b76:	66 90                	xchg   %ax,%ax
f0103b78:	66 90                	xchg   %ax,%ax
f0103b7a:	66 90                	xchg   %ax,%ax
f0103b7c:	66 90                	xchg   %ax,%ax
f0103b7e:	66 90                	xchg   %ax,%ax

f0103b80 <__udivdi3>:
f0103b80:	55                   	push   %ebp
f0103b81:	57                   	push   %edi
f0103b82:	56                   	push   %esi
f0103b83:	83 ec 0c             	sub    $0xc,%esp
f0103b86:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b8a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103b8e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103b92:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b96:	85 c0                	test   %eax,%eax
f0103b98:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b9c:	89 ea                	mov    %ebp,%edx
f0103b9e:	89 0c 24             	mov    %ecx,(%esp)
f0103ba1:	75 2d                	jne    f0103bd0 <__udivdi3+0x50>
f0103ba3:	39 e9                	cmp    %ebp,%ecx
f0103ba5:	77 61                	ja     f0103c08 <__udivdi3+0x88>
f0103ba7:	85 c9                	test   %ecx,%ecx
f0103ba9:	89 ce                	mov    %ecx,%esi
f0103bab:	75 0b                	jne    f0103bb8 <__udivdi3+0x38>
f0103bad:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bb2:	31 d2                	xor    %edx,%edx
f0103bb4:	f7 f1                	div    %ecx
f0103bb6:	89 c6                	mov    %eax,%esi
f0103bb8:	31 d2                	xor    %edx,%edx
f0103bba:	89 e8                	mov    %ebp,%eax
f0103bbc:	f7 f6                	div    %esi
f0103bbe:	89 c5                	mov    %eax,%ebp
f0103bc0:	89 f8                	mov    %edi,%eax
f0103bc2:	f7 f6                	div    %esi
f0103bc4:	89 ea                	mov    %ebp,%edx
f0103bc6:	83 c4 0c             	add    $0xc,%esp
f0103bc9:	5e                   	pop    %esi
f0103bca:	5f                   	pop    %edi
f0103bcb:	5d                   	pop    %ebp
f0103bcc:	c3                   	ret    
f0103bcd:	8d 76 00             	lea    0x0(%esi),%esi
f0103bd0:	39 e8                	cmp    %ebp,%eax
f0103bd2:	77 24                	ja     f0103bf8 <__udivdi3+0x78>
f0103bd4:	0f bd e8             	bsr    %eax,%ebp
f0103bd7:	83 f5 1f             	xor    $0x1f,%ebp
f0103bda:	75 3c                	jne    f0103c18 <__udivdi3+0x98>
f0103bdc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103be0:	39 34 24             	cmp    %esi,(%esp)
f0103be3:	0f 86 9f 00 00 00    	jbe    f0103c88 <__udivdi3+0x108>
f0103be9:	39 d0                	cmp    %edx,%eax
f0103beb:	0f 82 97 00 00 00    	jb     f0103c88 <__udivdi3+0x108>
f0103bf1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103bf8:	31 d2                	xor    %edx,%edx
f0103bfa:	31 c0                	xor    %eax,%eax
f0103bfc:	83 c4 0c             	add    $0xc,%esp
f0103bff:	5e                   	pop    %esi
f0103c00:	5f                   	pop    %edi
f0103c01:	5d                   	pop    %ebp
f0103c02:	c3                   	ret    
f0103c03:	90                   	nop
f0103c04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c08:	89 f8                	mov    %edi,%eax
f0103c0a:	f7 f1                	div    %ecx
f0103c0c:	31 d2                	xor    %edx,%edx
f0103c0e:	83 c4 0c             	add    $0xc,%esp
f0103c11:	5e                   	pop    %esi
f0103c12:	5f                   	pop    %edi
f0103c13:	5d                   	pop    %ebp
f0103c14:	c3                   	ret    
f0103c15:	8d 76 00             	lea    0x0(%esi),%esi
f0103c18:	89 e9                	mov    %ebp,%ecx
f0103c1a:	8b 3c 24             	mov    (%esp),%edi
f0103c1d:	d3 e0                	shl    %cl,%eax
f0103c1f:	89 c6                	mov    %eax,%esi
f0103c21:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c26:	29 e8                	sub    %ebp,%eax
f0103c28:	89 c1                	mov    %eax,%ecx
f0103c2a:	d3 ef                	shr    %cl,%edi
f0103c2c:	89 e9                	mov    %ebp,%ecx
f0103c2e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103c32:	8b 3c 24             	mov    (%esp),%edi
f0103c35:	09 74 24 08          	or     %esi,0x8(%esp)
f0103c39:	89 d6                	mov    %edx,%esi
f0103c3b:	d3 e7                	shl    %cl,%edi
f0103c3d:	89 c1                	mov    %eax,%ecx
f0103c3f:	89 3c 24             	mov    %edi,(%esp)
f0103c42:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c46:	d3 ee                	shr    %cl,%esi
f0103c48:	89 e9                	mov    %ebp,%ecx
f0103c4a:	d3 e2                	shl    %cl,%edx
f0103c4c:	89 c1                	mov    %eax,%ecx
f0103c4e:	d3 ef                	shr    %cl,%edi
f0103c50:	09 d7                	or     %edx,%edi
f0103c52:	89 f2                	mov    %esi,%edx
f0103c54:	89 f8                	mov    %edi,%eax
f0103c56:	f7 74 24 08          	divl   0x8(%esp)
f0103c5a:	89 d6                	mov    %edx,%esi
f0103c5c:	89 c7                	mov    %eax,%edi
f0103c5e:	f7 24 24             	mull   (%esp)
f0103c61:	39 d6                	cmp    %edx,%esi
f0103c63:	89 14 24             	mov    %edx,(%esp)
f0103c66:	72 30                	jb     f0103c98 <__udivdi3+0x118>
f0103c68:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c6c:	89 e9                	mov    %ebp,%ecx
f0103c6e:	d3 e2                	shl    %cl,%edx
f0103c70:	39 c2                	cmp    %eax,%edx
f0103c72:	73 05                	jae    f0103c79 <__udivdi3+0xf9>
f0103c74:	3b 34 24             	cmp    (%esp),%esi
f0103c77:	74 1f                	je     f0103c98 <__udivdi3+0x118>
f0103c79:	89 f8                	mov    %edi,%eax
f0103c7b:	31 d2                	xor    %edx,%edx
f0103c7d:	e9 7a ff ff ff       	jmp    f0103bfc <__udivdi3+0x7c>
f0103c82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c88:	31 d2                	xor    %edx,%edx
f0103c8a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c8f:	e9 68 ff ff ff       	jmp    f0103bfc <__udivdi3+0x7c>
f0103c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c98:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103c9b:	31 d2                	xor    %edx,%edx
f0103c9d:	83 c4 0c             	add    $0xc,%esp
f0103ca0:	5e                   	pop    %esi
f0103ca1:	5f                   	pop    %edi
f0103ca2:	5d                   	pop    %ebp
f0103ca3:	c3                   	ret    
f0103ca4:	66 90                	xchg   %ax,%ax
f0103ca6:	66 90                	xchg   %ax,%ax
f0103ca8:	66 90                	xchg   %ax,%ax
f0103caa:	66 90                	xchg   %ax,%ax
f0103cac:	66 90                	xchg   %ax,%ax
f0103cae:	66 90                	xchg   %ax,%ax

f0103cb0 <__umoddi3>:
f0103cb0:	55                   	push   %ebp
f0103cb1:	57                   	push   %edi
f0103cb2:	56                   	push   %esi
f0103cb3:	83 ec 14             	sub    $0x14,%esp
f0103cb6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103cba:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103cbe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103cc2:	89 c7                	mov    %eax,%edi
f0103cc4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103ccc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103cd0:	89 34 24             	mov    %esi,(%esp)
f0103cd3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cd7:	85 c0                	test   %eax,%eax
f0103cd9:	89 c2                	mov    %eax,%edx
f0103cdb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103cdf:	75 17                	jne    f0103cf8 <__umoddi3+0x48>
f0103ce1:	39 fe                	cmp    %edi,%esi
f0103ce3:	76 4b                	jbe    f0103d30 <__umoddi3+0x80>
f0103ce5:	89 c8                	mov    %ecx,%eax
f0103ce7:	89 fa                	mov    %edi,%edx
f0103ce9:	f7 f6                	div    %esi
f0103ceb:	89 d0                	mov    %edx,%eax
f0103ced:	31 d2                	xor    %edx,%edx
f0103cef:	83 c4 14             	add    $0x14,%esp
f0103cf2:	5e                   	pop    %esi
f0103cf3:	5f                   	pop    %edi
f0103cf4:	5d                   	pop    %ebp
f0103cf5:	c3                   	ret    
f0103cf6:	66 90                	xchg   %ax,%ax
f0103cf8:	39 f8                	cmp    %edi,%eax
f0103cfa:	77 54                	ja     f0103d50 <__umoddi3+0xa0>
f0103cfc:	0f bd e8             	bsr    %eax,%ebp
f0103cff:	83 f5 1f             	xor    $0x1f,%ebp
f0103d02:	75 5c                	jne    f0103d60 <__umoddi3+0xb0>
f0103d04:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103d08:	39 3c 24             	cmp    %edi,(%esp)
f0103d0b:	0f 87 e7 00 00 00    	ja     f0103df8 <__umoddi3+0x148>
f0103d11:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103d15:	29 f1                	sub    %esi,%ecx
f0103d17:	19 c7                	sbb    %eax,%edi
f0103d19:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d1d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d21:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d25:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103d29:	83 c4 14             	add    $0x14,%esp
f0103d2c:	5e                   	pop    %esi
f0103d2d:	5f                   	pop    %edi
f0103d2e:	5d                   	pop    %ebp
f0103d2f:	c3                   	ret    
f0103d30:	85 f6                	test   %esi,%esi
f0103d32:	89 f5                	mov    %esi,%ebp
f0103d34:	75 0b                	jne    f0103d41 <__umoddi3+0x91>
f0103d36:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d3b:	31 d2                	xor    %edx,%edx
f0103d3d:	f7 f6                	div    %esi
f0103d3f:	89 c5                	mov    %eax,%ebp
f0103d41:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d45:	31 d2                	xor    %edx,%edx
f0103d47:	f7 f5                	div    %ebp
f0103d49:	89 c8                	mov    %ecx,%eax
f0103d4b:	f7 f5                	div    %ebp
f0103d4d:	eb 9c                	jmp    f0103ceb <__umoddi3+0x3b>
f0103d4f:	90                   	nop
f0103d50:	89 c8                	mov    %ecx,%eax
f0103d52:	89 fa                	mov    %edi,%edx
f0103d54:	83 c4 14             	add    $0x14,%esp
f0103d57:	5e                   	pop    %esi
f0103d58:	5f                   	pop    %edi
f0103d59:	5d                   	pop    %ebp
f0103d5a:	c3                   	ret    
f0103d5b:	90                   	nop
f0103d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d60:	8b 04 24             	mov    (%esp),%eax
f0103d63:	be 20 00 00 00       	mov    $0x20,%esi
f0103d68:	89 e9                	mov    %ebp,%ecx
f0103d6a:	29 ee                	sub    %ebp,%esi
f0103d6c:	d3 e2                	shl    %cl,%edx
f0103d6e:	89 f1                	mov    %esi,%ecx
f0103d70:	d3 e8                	shr    %cl,%eax
f0103d72:	89 e9                	mov    %ebp,%ecx
f0103d74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d78:	8b 04 24             	mov    (%esp),%eax
f0103d7b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103d7f:	89 fa                	mov    %edi,%edx
f0103d81:	d3 e0                	shl    %cl,%eax
f0103d83:	89 f1                	mov    %esi,%ecx
f0103d85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d89:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103d8d:	d3 ea                	shr    %cl,%edx
f0103d8f:	89 e9                	mov    %ebp,%ecx
f0103d91:	d3 e7                	shl    %cl,%edi
f0103d93:	89 f1                	mov    %esi,%ecx
f0103d95:	d3 e8                	shr    %cl,%eax
f0103d97:	89 e9                	mov    %ebp,%ecx
f0103d99:	09 f8                	or     %edi,%eax
f0103d9b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103d9f:	f7 74 24 04          	divl   0x4(%esp)
f0103da3:	d3 e7                	shl    %cl,%edi
f0103da5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103da9:	89 d7                	mov    %edx,%edi
f0103dab:	f7 64 24 08          	mull   0x8(%esp)
f0103daf:	39 d7                	cmp    %edx,%edi
f0103db1:	89 c1                	mov    %eax,%ecx
f0103db3:	89 14 24             	mov    %edx,(%esp)
f0103db6:	72 2c                	jb     f0103de4 <__umoddi3+0x134>
f0103db8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103dbc:	72 22                	jb     f0103de0 <__umoddi3+0x130>
f0103dbe:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103dc2:	29 c8                	sub    %ecx,%eax
f0103dc4:	19 d7                	sbb    %edx,%edi
f0103dc6:	89 e9                	mov    %ebp,%ecx
f0103dc8:	89 fa                	mov    %edi,%edx
f0103dca:	d3 e8                	shr    %cl,%eax
f0103dcc:	89 f1                	mov    %esi,%ecx
f0103dce:	d3 e2                	shl    %cl,%edx
f0103dd0:	89 e9                	mov    %ebp,%ecx
f0103dd2:	d3 ef                	shr    %cl,%edi
f0103dd4:	09 d0                	or     %edx,%eax
f0103dd6:	89 fa                	mov    %edi,%edx
f0103dd8:	83 c4 14             	add    $0x14,%esp
f0103ddb:	5e                   	pop    %esi
f0103ddc:	5f                   	pop    %edi
f0103ddd:	5d                   	pop    %ebp
f0103dde:	c3                   	ret    
f0103ddf:	90                   	nop
f0103de0:	39 d7                	cmp    %edx,%edi
f0103de2:	75 da                	jne    f0103dbe <__umoddi3+0x10e>
f0103de4:	8b 14 24             	mov    (%esp),%edx
f0103de7:	89 c1                	mov    %eax,%ecx
f0103de9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103ded:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103df1:	eb cb                	jmp    f0103dbe <__umoddi3+0x10e>
f0103df3:	90                   	nop
f0103df4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103df8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103dfc:	0f 82 0f ff ff ff    	jb     f0103d11 <__umoddi3+0x61>
f0103e02:	e9 1a ff ff ff       	jmp    f0103d21 <__umoddi3+0x71>
