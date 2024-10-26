
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	43660613          	addi	a2,a2,1078 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	13b010ef          	jal	ra,ffffffffc0201984 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	94650513          	addi	a0,a0,-1722 # ffffffffc0201998 <etext+0x2>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	248010ef          	jal	ra,ffffffffc02012ae <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	408010ef          	jal	ra,ffffffffc02014ae <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	3d2010ef          	jal	ra,ffffffffc02014ae <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00002517          	auipc	a0,0x2
ffffffffc0200140:	87c50513          	addi	a0,a0,-1924 # ffffffffc02019b8 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	88650513          	addi	a0,a0,-1914 # ffffffffc02019d8 <etext+0x42>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	83858593          	addi	a1,a1,-1992 # ffffffffc0201996 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	89250513          	addi	a0,a0,-1902 # ffffffffc02019f8 <etext+0x62>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <free_area>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0201a18 <etext+0x82>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	2ea58593          	addi	a1,a1,746 # ffffffffc0206470 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0201a38 <etext+0xa2>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	6d558593          	addi	a1,a1,1749 # ffffffffc020686f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0201a58 <etext+0xc2>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00002617          	auipc	a2,0x2
ffffffffc02001ce:	8be60613          	addi	a2,a2,-1858 # ffffffffc0201a88 <etext+0xf2>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0201aa0 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00002617          	auipc	a2,0x2
ffffffffc02001ea:	8d260613          	addi	a2,a2,-1838 # ffffffffc0201ab8 <etext+0x122>
ffffffffc02001ee:	00002597          	auipc	a1,0x2
ffffffffc02001f2:	8ea58593          	addi	a1,a1,-1814 # ffffffffc0201ad8 <etext+0x142>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201ae0 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00002617          	auipc	a2,0x2
ffffffffc0200208:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0201af0 <etext+0x15a>
ffffffffc020020c:	00002597          	auipc	a1,0x2
ffffffffc0200210:	90c58593          	addi	a1,a1,-1780 # ffffffffc0201b18 <etext+0x182>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0201ae0 <etext+0x14a>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00002617          	auipc	a2,0x2
ffffffffc0200224:	90860613          	addi	a2,a2,-1784 # ffffffffc0201b28 <etext+0x192>
ffffffffc0200228:	00002597          	auipc	a1,0x2
ffffffffc020022c:	92058593          	addi	a1,a1,-1760 # ffffffffc0201b48 <etext+0x1b2>
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	8b050513          	addi	a0,a0,-1872 # ffffffffc0201ae0 <etext+0x14a>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0201b58 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	8f450513          	addi	a0,a0,-1804 # ffffffffc0201b80 <etext+0x1ea>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00002c17          	auipc	s8,0x2
ffffffffc02002a6:	94ec0c13          	addi	s8,s8,-1714 # ffffffffc0201bf0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00002917          	auipc	s2,0x2
ffffffffc02002ae:	8fe90913          	addi	s2,s2,-1794 # ffffffffc0201ba8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00002497          	auipc	s1,0x2
ffffffffc02002b6:	8fe48493          	addi	s1,s1,-1794 # ffffffffc0201bb0 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00002b17          	auipc	s6,0x2
ffffffffc02002c0:	8fcb0b13          	addi	s6,s6,-1796 # ffffffffc0201bb8 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002c4:	00002a17          	auipc	s4,0x2
ffffffffc02002c8:	814a0a13          	addi	s4,s4,-2028 # ffffffffc0201ad8 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	560010ef          	jal	ra,ffffffffc0201830 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002d17          	auipc	s10,0x2
ffffffffc02002ea:	90ad0d13          	addi	s10,s10,-1782 # ffffffffc0201bf0 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	65c010ef          	jal	ra,ffffffffc0201950 <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	648010ef          	jal	ra,ffffffffc0201950 <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	628010ef          	jal	ra,ffffffffc020196e <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	5ea010ef          	jal	ra,ffffffffc020196e <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	83a50513          	addi	a0,a0,-1990 # ffffffffc0201bd8 <etext+0x242>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	07c30313          	addi	t1,t1,124 # ffffffffc0206428 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00002517          	auipc	a0,0x2
ffffffffc02003de:	85e50513          	addi	a0,a0,-1954 # ffffffffc0201c38 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	69050513          	addi	a0,a0,1680 # ffffffffc0201a80 <etext+0xea>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	4de010ef          	jal	ra,ffffffffc02018fe <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0007b523          	sd	zero,10(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	82a50513          	addi	a0,a0,-2006 # ffffffffc0201c58 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	4b80106f          	j	ffffffffc02018fe <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	zext.b	a0,a0
ffffffffc0200450:	4940106f          	j	ffffffffc02018e4 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	4c40106f          	j	ffffffffc0201918 <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	2e478793          	addi	a5,a5,740 # ffffffffc020074c <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00001517          	auipc	a0,0x1
ffffffffc0200482:	7fa50513          	addi	a0,a0,2042 # ffffffffc0201c78 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	80250513          	addi	a0,a0,-2046 # ffffffffc0201c90 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	80c50513          	addi	a0,a0,-2036 # ffffffffc0201ca8 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	81650513          	addi	a0,a0,-2026 # ffffffffc0201cc0 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	82050513          	addi	a0,a0,-2016 # ffffffffc0201cd8 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	82a50513          	addi	a0,a0,-2006 # ffffffffc0201cf0 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	83450513          	addi	a0,a0,-1996 # ffffffffc0201d08 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	83e50513          	addi	a0,a0,-1986 # ffffffffc0201d20 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	84850513          	addi	a0,a0,-1976 # ffffffffc0201d38 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	85250513          	addi	a0,a0,-1966 # ffffffffc0201d50 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	85c50513          	addi	a0,a0,-1956 # ffffffffc0201d68 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	86650513          	addi	a0,a0,-1946 # ffffffffc0201d80 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	87050513          	addi	a0,a0,-1936 # ffffffffc0201d98 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	87a50513          	addi	a0,a0,-1926 # ffffffffc0201db0 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	88450513          	addi	a0,a0,-1916 # ffffffffc0201dc8 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	88e50513          	addi	a0,a0,-1906 # ffffffffc0201de0 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	89850513          	addi	a0,a0,-1896 # ffffffffc0201df8 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	8a250513          	addi	a0,a0,-1886 # ffffffffc0201e10 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0201e28 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	8b650513          	addi	a0,a0,-1866 # ffffffffc0201e40 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	8c050513          	addi	a0,a0,-1856 # ffffffffc0201e58 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0201e70 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	8d450513          	addi	a0,a0,-1836 # ffffffffc0201e88 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	8de50513          	addi	a0,a0,-1826 # ffffffffc0201ea0 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	8e850513          	addi	a0,a0,-1816 # ffffffffc0201eb8 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	8f250513          	addi	a0,a0,-1806 # ffffffffc0201ed0 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	8fc50513          	addi	a0,a0,-1796 # ffffffffc0201ee8 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	90650513          	addi	a0,a0,-1786 # ffffffffc0201f00 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	91050513          	addi	a0,a0,-1776 # ffffffffc0201f18 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	91a50513          	addi	a0,a0,-1766 # ffffffffc0201f30 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	92450513          	addi	a0,a0,-1756 # ffffffffc0201f48 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	92a50513          	addi	a0,a0,-1750 # ffffffffc0201f60 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0201f78 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	92e50513          	addi	a0,a0,-1746 # ffffffffc0201f90 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	93650513          	addi	a0,a0,-1738 # ffffffffc0201fa8 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	93e50513          	addi	a0,a0,-1730 # ffffffffc0201fc0 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	94250513          	addi	a0,a0,-1726 # ffffffffc0201fd8 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	a0870713          	addi	a4,a4,-1528 # ffffffffc02020b8 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202050 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	96450513          	addi	a0,a0,-1692 # ffffffffc0202030 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	91a50513          	addi	a0,a0,-1766 # ffffffffc0201ff0 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	99050513          	addi	a0,a0,-1648 # ffffffffc0202070 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	d3e68693          	addi	a3,a3,-706 # ffffffffc0206430 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00002517          	auipc	a0,0x2
ffffffffc0200714:	98850513          	addi	a0,a0,-1656 # ffffffffc0202098 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0202010 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	95c50513          	addi	a0,a0,-1700 # ffffffffc0202088 <commands+0x498>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
ffffffffc020073c:	0007c763          	bltz	a5,ffffffffc020074a <trap+0x12>
    switch (tf->cause) {
ffffffffc0200740:	472d                	li	a4,11
ffffffffc0200742:	00f76363          	bltu	a4,a5,ffffffffc0200748 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200746:	8082                	ret
            print_trapframe(tf);
ffffffffc0200748:	bded                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc020074a:	bfa1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f89ff0ef          	jal	ra,ffffffffc0200738 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200802:	00006797          	auipc	a5,0x6
ffffffffc0200806:	80e78793          	addi	a5,a5,-2034 # ffffffffc0206010 <free_area>
ffffffffc020080a:	e79c                	sd	a5,8(a5)
ffffffffc020080c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020080e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <best_fit_nr_free_pages>:


static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200814:	00006517          	auipc	a0,0x6
ffffffffc0200818:	80c56503          	lwu	a0,-2036(a0) # ffffffffc0206020 <free_area+0x10>
ffffffffc020081c:	8082                	ret

ffffffffc020081e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020081e:	c14d                	beqz	a0,ffffffffc02008c0 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200820:	00005617          	auipc	a2,0x5
ffffffffc0200824:	7f060613          	addi	a2,a2,2032 # ffffffffc0206010 <free_area>
ffffffffc0200828:	01062803          	lw	a6,16(a2)
ffffffffc020082c:	86aa                	mv	a3,a0
ffffffffc020082e:	02081793          	slli	a5,a6,0x20
ffffffffc0200832:	9381                	srli	a5,a5,0x20
ffffffffc0200834:	08a7e463          	bltu	a5,a0,ffffffffc02008bc <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200838:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;  // 设置个超级大值，方便后面找最小值
ffffffffc020083a:	0018059b          	addiw	a1,a6,1
ffffffffc020083e:	1582                	slli	a1,a1,0x20
ffffffffc0200840:	9181                	srli	a1,a1,0x20
    struct Page *best_page = NULL;
ffffffffc0200842:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200844:	06c78b63          	beq	a5,a2,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200848:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020084c:	00d76763          	bltu	a4,a3,ffffffffc020085a <best_fit_alloc_pages+0x3c>
ffffffffc0200850:	00b77563          	bgeu	a4,a1,ffffffffc020085a <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200854:	fe878513          	addi	a0,a5,-24
ffffffffc0200858:	85ba                	mv	a1,a4
ffffffffc020085a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020085c:	fec796e3          	bne	a5,a2,ffffffffc0200848 <best_fit_alloc_pages+0x2a>
    if (best_page != NULL) {
ffffffffc0200860:	cd29                	beqz	a0,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200862:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200864:	6d18                	ld	a4,24(a0)
        if (best_page->property > n) {
ffffffffc0200866:	490c                	lw	a1,16(a0)
            p->property = best_page->property - n;  // 剩下的块儿大小
ffffffffc0200868:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020086c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020086e:	e398                	sd	a4,0(a5)
        if (best_page->property > n) {
ffffffffc0200870:	02059793          	slli	a5,a1,0x20
ffffffffc0200874:	9381                	srli	a5,a5,0x20
ffffffffc0200876:	02f6f863          	bgeu	a3,a5,ffffffffc02008a6 <best_fit_alloc_pages+0x88>
            struct Page *p = best_page + n;
ffffffffc020087a:	00269793          	slli	a5,a3,0x2
ffffffffc020087e:	97b6                	add	a5,a5,a3
ffffffffc0200880:	078e                	slli	a5,a5,0x3
ffffffffc0200882:	97aa                	add	a5,a5,a0
            p->property = best_page->property - n;  // 剩下的块儿大小
ffffffffc0200884:	411585bb          	subw	a1,a1,a7
ffffffffc0200888:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020088a:	4689                	li	a3,2
ffffffffc020088c:	00878593          	addi	a1,a5,8
ffffffffc0200890:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200894:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));        // 插回链表
ffffffffc0200896:	01878593          	addi	a1,a5,24
        nr_free -= n;          // 更新总空闲数
ffffffffc020089a:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc020089e:	e28c                	sd	a1,0(a3)
ffffffffc02008a0:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008a2:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02008a4:	ef98                	sd	a4,24(a5)
ffffffffc02008a6:	4118083b          	subw	a6,a6,a7
ffffffffc02008aa:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008ae:	57f5                	li	a5,-3
ffffffffc02008b0:	00850713          	addi	a4,a0,8
ffffffffc02008b4:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc02008b8:	8082                	ret
}
ffffffffc02008ba:	8082                	ret
        return NULL;
ffffffffc02008bc:	4501                	li	a0,0
ffffffffc02008be:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02008c0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008c2:	00002697          	auipc	a3,0x2
ffffffffc02008c6:	82668693          	addi	a3,a3,-2010 # ffffffffc02020e8 <commands+0x4f8>
ffffffffc02008ca:	00002617          	auipc	a2,0x2
ffffffffc02008ce:	82660613          	addi	a2,a2,-2010 # ffffffffc02020f0 <commands+0x500>
ffffffffc02008d2:	06e00593          	li	a1,110
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	83250513          	addi	a0,a0,-1998 # ffffffffc0202108 <commands+0x518>
best_fit_alloc_pages(size_t n) {
ffffffffc02008de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e0:	acdff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02008e4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008e4:	715d                	addi	sp,sp,-80
ffffffffc02008e6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008e8:	00005417          	auipc	s0,0x5
ffffffffc02008ec:	72840413          	addi	s0,s0,1832 # ffffffffc0206010 <free_area>
ffffffffc02008f0:	641c                	ld	a5,8(s0)
ffffffffc02008f2:	e486                	sd	ra,72(sp)
ffffffffc02008f4:	fc26                	sd	s1,56(sp)
ffffffffc02008f6:	f84a                	sd	s2,48(sp)
ffffffffc02008f8:	f44e                	sd	s3,40(sp)
ffffffffc02008fa:	f052                	sd	s4,32(sp)
ffffffffc02008fc:	ec56                	sd	s5,24(sp)
ffffffffc02008fe:	e85a                	sd	s6,16(sp)
ffffffffc0200900:	e45e                	sd	s7,8(sp)
ffffffffc0200902:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200904:	26878b63          	beq	a5,s0,ffffffffc0200b7a <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200908:	4481                	li	s1,0
ffffffffc020090a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020090c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200910:	8b09                	andi	a4,a4,2
ffffffffc0200912:	26070863          	beqz	a4,ffffffffc0200b82 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200916:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091a:	679c                	ld	a5,8(a5)
ffffffffc020091c:	2905                	addiw	s2,s2,1
ffffffffc020091e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200920:	fe8796e3          	bne	a5,s0,ffffffffc020090c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200924:	89a6                	mv	s3,s1
ffffffffc0200926:	14f000ef          	jal	ra,ffffffffc0201274 <nr_free_pages>
ffffffffc020092a:	33351c63          	bne	a0,s3,ffffffffc0200c62 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020092e:	4505                	li	a0,1
ffffffffc0200930:	0c7000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200934:	8a2a                	mv	s4,a0
ffffffffc0200936:	36050663          	beqz	a0,ffffffffc0200ca2 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020093a:	4505                	li	a0,1
ffffffffc020093c:	0bb000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200940:	89aa                	mv	s3,a0
ffffffffc0200942:	34050063          	beqz	a0,ffffffffc0200c82 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200946:	4505                	li	a0,1
ffffffffc0200948:	0af000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc020094c:	8aaa                	mv	s5,a0
ffffffffc020094e:	2c050a63          	beqz	a0,ffffffffc0200c22 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200952:	253a0863          	beq	s4,s3,ffffffffc0200ba2 <best_fit_check+0x2be>
ffffffffc0200956:	24aa0663          	beq	s4,a0,ffffffffc0200ba2 <best_fit_check+0x2be>
ffffffffc020095a:	24a98463          	beq	s3,a0,ffffffffc0200ba2 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020095e:	000a2783          	lw	a5,0(s4)
ffffffffc0200962:	26079063          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
ffffffffc0200966:	0009a783          	lw	a5,0(s3)
ffffffffc020096a:	24079c63          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
ffffffffc020096e:	411c                	lw	a5,0(a0)
ffffffffc0200970:	24079963          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200974:	00006797          	auipc	a5,0x6
ffffffffc0200978:	acc7b783          	ld	a5,-1332(a5) # ffffffffc0206440 <pages>
ffffffffc020097c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200980:	870d                	srai	a4,a4,0x3
ffffffffc0200982:	00002597          	auipc	a1,0x2
ffffffffc0200986:	e565b583          	ld	a1,-426(a1) # ffffffffc02027d8 <error_string+0x38>
ffffffffc020098a:	02b70733          	mul	a4,a4,a1
ffffffffc020098e:	00002617          	auipc	a2,0x2
ffffffffc0200992:	e5263603          	ld	a2,-430(a2) # ffffffffc02027e0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200996:	00006697          	auipc	a3,0x6
ffffffffc020099a:	aa26b683          	ld	a3,-1374(a3) # ffffffffc0206438 <npage>
ffffffffc020099e:	06b2                	slli	a3,a3,0xc
ffffffffc02009a0:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009a2:	0732                	slli	a4,a4,0xc
ffffffffc02009a4:	22d77f63          	bgeu	a4,a3,ffffffffc0200be2 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009a8:	40f98733          	sub	a4,s3,a5
ffffffffc02009ac:	870d                	srai	a4,a4,0x3
ffffffffc02009ae:	02b70733          	mul	a4,a4,a1
ffffffffc02009b2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009b4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009b6:	3ed77663          	bgeu	a4,a3,ffffffffc0200da2 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009ba:	40f507b3          	sub	a5,a0,a5
ffffffffc02009be:	878d                	srai	a5,a5,0x3
ffffffffc02009c0:	02b787b3          	mul	a5,a5,a1
ffffffffc02009c4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009c6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02009c8:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200d82 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc02009cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009ce:	00043c03          	ld	s8,0(s0)
ffffffffc02009d2:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02009d6:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02009da:	e400                	sd	s0,8(s0)
ffffffffc02009dc:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02009de:	00005797          	auipc	a5,0x5
ffffffffc02009e2:	6407a123          	sw	zero,1602(a5) # ffffffffc0206020 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009e6:	011000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc02009ea:	36051c63          	bnez	a0,ffffffffc0200d62 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc02009ee:	4585                	li	a1,1
ffffffffc02009f0:	8552                	mv	a0,s4
ffffffffc02009f2:	043000ef          	jal	ra,ffffffffc0201234 <free_pages>
    free_page(p1);
ffffffffc02009f6:	4585                	li	a1,1
ffffffffc02009f8:	854e                	mv	a0,s3
ffffffffc02009fa:	03b000ef          	jal	ra,ffffffffc0201234 <free_pages>
    free_page(p2);
ffffffffc02009fe:	4585                	li	a1,1
ffffffffc0200a00:	8556                	mv	a0,s5
ffffffffc0200a02:	033000ef          	jal	ra,ffffffffc0201234 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a06:	4818                	lw	a4,16(s0)
ffffffffc0200a08:	478d                	li	a5,3
ffffffffc0200a0a:	32f71c63          	bne	a4,a5,ffffffffc0200d42 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a0e:	4505                	li	a0,1
ffffffffc0200a10:	7e6000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a14:	89aa                	mv	s3,a0
ffffffffc0200a16:	30050663          	beqz	a0,ffffffffc0200d22 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a1a:	4505                	li	a0,1
ffffffffc0200a1c:	7da000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a20:	8aaa                	mv	s5,a0
ffffffffc0200a22:	2e050063          	beqz	a0,ffffffffc0200d02 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a26:	4505                	li	a0,1
ffffffffc0200a28:	7ce000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a2c:	8a2a                	mv	s4,a0
ffffffffc0200a2e:	2a050a63          	beqz	a0,ffffffffc0200ce2 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200a32:	4505                	li	a0,1
ffffffffc0200a34:	7c2000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a38:	28051563          	bnez	a0,ffffffffc0200cc2 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200a3c:	4585                	li	a1,1
ffffffffc0200a3e:	854e                	mv	a0,s3
ffffffffc0200a40:	7f4000ef          	jal	ra,ffffffffc0201234 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a44:	641c                	ld	a5,8(s0)
ffffffffc0200a46:	1a878e63          	beq	a5,s0,ffffffffc0200c02 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200a4a:	4505                	li	a0,1
ffffffffc0200a4c:	7aa000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a50:	52a99963          	bne	s3,a0,ffffffffc0200f82 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200a54:	4505                	li	a0,1
ffffffffc0200a56:	7a0000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a5a:	50051463          	bnez	a0,ffffffffc0200f62 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200a5e:	481c                	lw	a5,16(s0)
ffffffffc0200a60:	4e079163          	bnez	a5,ffffffffc0200f42 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200a64:	854e                	mv	a0,s3
ffffffffc0200a66:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a68:	01843023          	sd	s8,0(s0)
ffffffffc0200a6c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a70:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a74:	7c0000ef          	jal	ra,ffffffffc0201234 <free_pages>
    free_page(p1);
ffffffffc0200a78:	4585                	li	a1,1
ffffffffc0200a7a:	8556                	mv	a0,s5
ffffffffc0200a7c:	7b8000ef          	jal	ra,ffffffffc0201234 <free_pages>
    free_page(p2);
ffffffffc0200a80:	4585                	li	a1,1
ffffffffc0200a82:	8552                	mv	a0,s4
ffffffffc0200a84:	7b0000ef          	jal	ra,ffffffffc0201234 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a88:	4515                	li	a0,5
ffffffffc0200a8a:	76c000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200a8e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a90:	48050963          	beqz	a0,ffffffffc0200f22 <best_fit_check+0x63e>
ffffffffc0200a94:	651c                	ld	a5,8(a0)
ffffffffc0200a96:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200a98:	8b85                	andi	a5,a5,1
ffffffffc0200a9a:	46079463          	bnez	a5,ffffffffc0200f02 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a9e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200aa0:	00043a83          	ld	s5,0(s0)
ffffffffc0200aa4:	00843a03          	ld	s4,8(s0)
ffffffffc0200aa8:	e000                	sd	s0,0(s0)
ffffffffc0200aaa:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200aac:	74a000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200ab0:	42051963          	bnez	a0,ffffffffc0200ee2 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200ab4:	4589                	li	a1,2
ffffffffc0200ab6:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200aba:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200abe:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200ac2:	00005797          	auipc	a5,0x5
ffffffffc0200ac6:	5407af23          	sw	zero,1374(a5) # ffffffffc0206020 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200aca:	76a000ef          	jal	ra,ffffffffc0201234 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200ace:	8562                	mv	a0,s8
ffffffffc0200ad0:	4585                	li	a1,1
ffffffffc0200ad2:	762000ef          	jal	ra,ffffffffc0201234 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ad6:	4511                	li	a0,4
ffffffffc0200ad8:	71e000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200adc:	3e051363          	bnez	a0,ffffffffc0200ec2 <best_fit_check+0x5de>
ffffffffc0200ae0:	0309b783          	ld	a5,48(s3)
ffffffffc0200ae4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200ae6:	8b85                	andi	a5,a5,1
ffffffffc0200ae8:	3a078d63          	beqz	a5,ffffffffc0200ea2 <best_fit_check+0x5be>
ffffffffc0200aec:	0389a703          	lw	a4,56(s3)
ffffffffc0200af0:	4789                	li	a5,2
ffffffffc0200af2:	3af71863          	bne	a4,a5,ffffffffc0200ea2 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200af6:	4505                	li	a0,1
ffffffffc0200af8:	6fe000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200afc:	8baa                	mv	s7,a0
ffffffffc0200afe:	38050263          	beqz	a0,ffffffffc0200e82 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b02:	4509                	li	a0,2
ffffffffc0200b04:	6f2000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200b08:	34050d63          	beqz	a0,ffffffffc0200e62 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200b0c:	337c1b63          	bne	s8,s7,ffffffffc0200e42 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b10:	854e                	mv	a0,s3
ffffffffc0200b12:	4595                	li	a1,5
ffffffffc0200b14:	720000ef          	jal	ra,ffffffffc0201234 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b18:	4515                	li	a0,5
ffffffffc0200b1a:	6dc000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200b1e:	89aa                	mv	s3,a0
ffffffffc0200b20:	30050163          	beqz	a0,ffffffffc0200e22 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	4505                	li	a0,1
ffffffffc0200b26:	6d0000ef          	jal	ra,ffffffffc02011f6 <alloc_pages>
ffffffffc0200b2a:	2c051c63          	bnez	a0,ffffffffc0200e02 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b2e:	481c                	lw	a5,16(s0)
ffffffffc0200b30:	2a079963          	bnez	a5,ffffffffc0200de2 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b34:	4595                	li	a1,5
ffffffffc0200b36:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b38:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200b3c:	01543023          	sd	s5,0(s0)
ffffffffc0200b40:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200b44:	6f0000ef          	jal	ra,ffffffffc0201234 <free_pages>
    return listelm->next;
ffffffffc0200b48:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b4a:	00878963          	beq	a5,s0,ffffffffc0200b5c <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b4e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b52:	679c                	ld	a5,8(a5)
ffffffffc0200b54:	397d                	addiw	s2,s2,-1
ffffffffc0200b56:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b58:	fe879be3          	bne	a5,s0,ffffffffc0200b4e <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200b5c:	26091363          	bnez	s2,ffffffffc0200dc2 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200b60:	e0ed                	bnez	s1,ffffffffc0200c42 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b62:	60a6                	ld	ra,72(sp)
ffffffffc0200b64:	6406                	ld	s0,64(sp)
ffffffffc0200b66:	74e2                	ld	s1,56(sp)
ffffffffc0200b68:	7942                	ld	s2,48(sp)
ffffffffc0200b6a:	79a2                	ld	s3,40(sp)
ffffffffc0200b6c:	7a02                	ld	s4,32(sp)
ffffffffc0200b6e:	6ae2                	ld	s5,24(sp)
ffffffffc0200b70:	6b42                	ld	s6,16(sp)
ffffffffc0200b72:	6ba2                	ld	s7,8(sp)
ffffffffc0200b74:	6c02                	ld	s8,0(sp)
ffffffffc0200b76:	6161                	addi	sp,sp,80
ffffffffc0200b78:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b7a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b7c:	4481                	li	s1,0
ffffffffc0200b7e:	4901                	li	s2,0
ffffffffc0200b80:	b35d                	j	ffffffffc0200926 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b82:	00001697          	auipc	a3,0x1
ffffffffc0200b86:	59e68693          	addi	a3,a3,1438 # ffffffffc0202120 <commands+0x530>
ffffffffc0200b8a:	00001617          	auipc	a2,0x1
ffffffffc0200b8e:	56660613          	addi	a2,a2,1382 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200b92:	11d00593          	li	a1,285
ffffffffc0200b96:	00001517          	auipc	a0,0x1
ffffffffc0200b9a:	57250513          	addi	a0,a0,1394 # ffffffffc0202108 <commands+0x518>
ffffffffc0200b9e:	80fff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ba2:	00001697          	auipc	a3,0x1
ffffffffc0200ba6:	60e68693          	addi	a3,a3,1550 # ffffffffc02021b0 <commands+0x5c0>
ffffffffc0200baa:	00001617          	auipc	a2,0x1
ffffffffc0200bae:	54660613          	addi	a2,a2,1350 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200bb2:	0e900593          	li	a1,233
ffffffffc0200bb6:	00001517          	auipc	a0,0x1
ffffffffc0200bba:	55250513          	addi	a0,a0,1362 # ffffffffc0202108 <commands+0x518>
ffffffffc0200bbe:	feeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bc2:	00001697          	auipc	a3,0x1
ffffffffc0200bc6:	61668693          	addi	a3,a3,1558 # ffffffffc02021d8 <commands+0x5e8>
ffffffffc0200bca:	00001617          	auipc	a2,0x1
ffffffffc0200bce:	52660613          	addi	a2,a2,1318 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200bd2:	0ea00593          	li	a1,234
ffffffffc0200bd6:	00001517          	auipc	a0,0x1
ffffffffc0200bda:	53250513          	addi	a0,a0,1330 # ffffffffc0202108 <commands+0x518>
ffffffffc0200bde:	fceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200be2:	00001697          	auipc	a3,0x1
ffffffffc0200be6:	63668693          	addi	a3,a3,1590 # ffffffffc0202218 <commands+0x628>
ffffffffc0200bea:	00001617          	auipc	a2,0x1
ffffffffc0200bee:	50660613          	addi	a2,a2,1286 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200bf2:	0ec00593          	li	a1,236
ffffffffc0200bf6:	00001517          	auipc	a0,0x1
ffffffffc0200bfa:	51250513          	addi	a0,a0,1298 # ffffffffc0202108 <commands+0x518>
ffffffffc0200bfe:	faeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c02:	00001697          	auipc	a3,0x1
ffffffffc0200c06:	69e68693          	addi	a3,a3,1694 # ffffffffc02022a0 <commands+0x6b0>
ffffffffc0200c0a:	00001617          	auipc	a2,0x1
ffffffffc0200c0e:	4e660613          	addi	a2,a2,1254 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200c12:	10500593          	li	a1,261
ffffffffc0200c16:	00001517          	auipc	a0,0x1
ffffffffc0200c1a:	4f250513          	addi	a0,a0,1266 # ffffffffc0202108 <commands+0x518>
ffffffffc0200c1e:	f8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c22:	00001697          	auipc	a3,0x1
ffffffffc0200c26:	56e68693          	addi	a3,a3,1390 # ffffffffc0202190 <commands+0x5a0>
ffffffffc0200c2a:	00001617          	auipc	a2,0x1
ffffffffc0200c2e:	4c660613          	addi	a2,a2,1222 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200c32:	0e700593          	li	a1,231
ffffffffc0200c36:	00001517          	auipc	a0,0x1
ffffffffc0200c3a:	4d250513          	addi	a0,a0,1234 # ffffffffc0202108 <commands+0x518>
ffffffffc0200c3e:	f6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0200c42:	00001697          	auipc	a3,0x1
ffffffffc0200c46:	78e68693          	addi	a3,a3,1934 # ffffffffc02023d0 <commands+0x7e0>
ffffffffc0200c4a:	00001617          	auipc	a2,0x1
ffffffffc0200c4e:	4a660613          	addi	a2,a2,1190 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200c52:	15f00593          	li	a1,351
ffffffffc0200c56:	00001517          	auipc	a0,0x1
ffffffffc0200c5a:	4b250513          	addi	a0,a0,1202 # ffffffffc0202108 <commands+0x518>
ffffffffc0200c5e:	f4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c62:	00001697          	auipc	a3,0x1
ffffffffc0200c66:	4ce68693          	addi	a3,a3,1230 # ffffffffc0202130 <commands+0x540>
ffffffffc0200c6a:	00001617          	auipc	a2,0x1
ffffffffc0200c6e:	48660613          	addi	a2,a2,1158 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200c72:	12000593          	li	a1,288
ffffffffc0200c76:	00001517          	auipc	a0,0x1
ffffffffc0200c7a:	49250513          	addi	a0,a0,1170 # ffffffffc0202108 <commands+0x518>
ffffffffc0200c7e:	f2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c82:	00001697          	auipc	a3,0x1
ffffffffc0200c86:	4ee68693          	addi	a3,a3,1262 # ffffffffc0202170 <commands+0x580>
ffffffffc0200c8a:	00001617          	auipc	a2,0x1
ffffffffc0200c8e:	46660613          	addi	a2,a2,1126 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200c92:	0e600593          	li	a1,230
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	47250513          	addi	a0,a0,1138 # ffffffffc0202108 <commands+0x518>
ffffffffc0200c9e:	f0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ca2:	00001697          	auipc	a3,0x1
ffffffffc0200ca6:	4ae68693          	addi	a3,a3,1198 # ffffffffc0202150 <commands+0x560>
ffffffffc0200caa:	00001617          	auipc	a2,0x1
ffffffffc0200cae:	44660613          	addi	a2,a2,1094 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200cb2:	0e500593          	li	a1,229
ffffffffc0200cb6:	00001517          	auipc	a0,0x1
ffffffffc0200cba:	45250513          	addi	a0,a0,1106 # ffffffffc0202108 <commands+0x518>
ffffffffc0200cbe:	eeeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cc2:	00001697          	auipc	a3,0x1
ffffffffc0200cc6:	5b668693          	addi	a3,a3,1462 # ffffffffc0202278 <commands+0x688>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	42660613          	addi	a2,a2,1062 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200cd2:	10200593          	li	a1,258
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	43250513          	addi	a0,a0,1074 # ffffffffc0202108 <commands+0x518>
ffffffffc0200cde:	eceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	4ae68693          	addi	a3,a3,1198 # ffffffffc0202190 <commands+0x5a0>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	40660613          	addi	a2,a2,1030 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200cf2:	10000593          	li	a1,256
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	41250513          	addi	a0,a0,1042 # ffffffffc0202108 <commands+0x518>
ffffffffc0200cfe:	eaeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d02:	00001697          	auipc	a3,0x1
ffffffffc0200d06:	46e68693          	addi	a3,a3,1134 # ffffffffc0202170 <commands+0x580>
ffffffffc0200d0a:	00001617          	auipc	a2,0x1
ffffffffc0200d0e:	3e660613          	addi	a2,a2,998 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200d12:	0ff00593          	li	a1,255
ffffffffc0200d16:	00001517          	auipc	a0,0x1
ffffffffc0200d1a:	3f250513          	addi	a0,a0,1010 # ffffffffc0202108 <commands+0x518>
ffffffffc0200d1e:	e8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d22:	00001697          	auipc	a3,0x1
ffffffffc0200d26:	42e68693          	addi	a3,a3,1070 # ffffffffc0202150 <commands+0x560>
ffffffffc0200d2a:	00001617          	auipc	a2,0x1
ffffffffc0200d2e:	3c660613          	addi	a2,a2,966 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200d32:	0fe00593          	li	a1,254
ffffffffc0200d36:	00001517          	auipc	a0,0x1
ffffffffc0200d3a:	3d250513          	addi	a0,a0,978 # ffffffffc0202108 <commands+0x518>
ffffffffc0200d3e:	e6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200d42:	00001697          	auipc	a3,0x1
ffffffffc0200d46:	54e68693          	addi	a3,a3,1358 # ffffffffc0202290 <commands+0x6a0>
ffffffffc0200d4a:	00001617          	auipc	a2,0x1
ffffffffc0200d4e:	3a660613          	addi	a2,a2,934 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200d52:	0fc00593          	li	a1,252
ffffffffc0200d56:	00001517          	auipc	a0,0x1
ffffffffc0200d5a:	3b250513          	addi	a0,a0,946 # ffffffffc0202108 <commands+0x518>
ffffffffc0200d5e:	e4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d62:	00001697          	auipc	a3,0x1
ffffffffc0200d66:	51668693          	addi	a3,a3,1302 # ffffffffc0202278 <commands+0x688>
ffffffffc0200d6a:	00001617          	auipc	a2,0x1
ffffffffc0200d6e:	38660613          	addi	a2,a2,902 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200d72:	0f700593          	li	a1,247
ffffffffc0200d76:	00001517          	auipc	a0,0x1
ffffffffc0200d7a:	39250513          	addi	a0,a0,914 # ffffffffc0202108 <commands+0x518>
ffffffffc0200d7e:	e2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d82:	00001697          	auipc	a3,0x1
ffffffffc0200d86:	4d668693          	addi	a3,a3,1238 # ffffffffc0202258 <commands+0x668>
ffffffffc0200d8a:	00001617          	auipc	a2,0x1
ffffffffc0200d8e:	36660613          	addi	a2,a2,870 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200d92:	0ee00593          	li	a1,238
ffffffffc0200d96:	00001517          	auipc	a0,0x1
ffffffffc0200d9a:	37250513          	addi	a0,a0,882 # ffffffffc0202108 <commands+0x518>
ffffffffc0200d9e:	e0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200da2:	00001697          	auipc	a3,0x1
ffffffffc0200da6:	49668693          	addi	a3,a3,1174 # ffffffffc0202238 <commands+0x648>
ffffffffc0200daa:	00001617          	auipc	a2,0x1
ffffffffc0200dae:	34660613          	addi	a2,a2,838 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200db2:	0ed00593          	li	a1,237
ffffffffc0200db6:	00001517          	auipc	a0,0x1
ffffffffc0200dba:	35250513          	addi	a0,a0,850 # ffffffffc0202108 <commands+0x518>
ffffffffc0200dbe:	deeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200dc2:	00001697          	auipc	a3,0x1
ffffffffc0200dc6:	5fe68693          	addi	a3,a3,1534 # ffffffffc02023c0 <commands+0x7d0>
ffffffffc0200dca:	00001617          	auipc	a2,0x1
ffffffffc0200dce:	32660613          	addi	a2,a2,806 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200dd2:	15e00593          	li	a1,350
ffffffffc0200dd6:	00001517          	auipc	a0,0x1
ffffffffc0200dda:	33250513          	addi	a0,a0,818 # ffffffffc0202108 <commands+0x518>
ffffffffc0200dde:	dceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200de2:	00001697          	auipc	a3,0x1
ffffffffc0200de6:	4f668693          	addi	a3,a3,1270 # ffffffffc02022d8 <commands+0x6e8>
ffffffffc0200dea:	00001617          	auipc	a2,0x1
ffffffffc0200dee:	30660613          	addi	a2,a2,774 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200df2:	15300593          	li	a1,339
ffffffffc0200df6:	00001517          	auipc	a0,0x1
ffffffffc0200dfa:	31250513          	addi	a0,a0,786 # ffffffffc0202108 <commands+0x518>
ffffffffc0200dfe:	daeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e02:	00001697          	auipc	a3,0x1
ffffffffc0200e06:	47668693          	addi	a3,a3,1142 # ffffffffc0202278 <commands+0x688>
ffffffffc0200e0a:	00001617          	auipc	a2,0x1
ffffffffc0200e0e:	2e660613          	addi	a2,a2,742 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200e12:	14d00593          	li	a1,333
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	2f250513          	addi	a0,a0,754 # ffffffffc0202108 <commands+0x518>
ffffffffc0200e1e:	d8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e22:	00001697          	auipc	a3,0x1
ffffffffc0200e26:	57e68693          	addi	a3,a3,1406 # ffffffffc02023a0 <commands+0x7b0>
ffffffffc0200e2a:	00001617          	auipc	a2,0x1
ffffffffc0200e2e:	2c660613          	addi	a2,a2,710 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200e32:	14c00593          	li	a1,332
ffffffffc0200e36:	00001517          	auipc	a0,0x1
ffffffffc0200e3a:	2d250513          	addi	a0,a0,722 # ffffffffc0202108 <commands+0x518>
ffffffffc0200e3e:	d6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e42:	00001697          	auipc	a3,0x1
ffffffffc0200e46:	54e68693          	addi	a3,a3,1358 # ffffffffc0202390 <commands+0x7a0>
ffffffffc0200e4a:	00001617          	auipc	a2,0x1
ffffffffc0200e4e:	2a660613          	addi	a2,a2,678 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200e52:	14400593          	li	a1,324
ffffffffc0200e56:	00001517          	auipc	a0,0x1
ffffffffc0200e5a:	2b250513          	addi	a0,a0,690 # ffffffffc0202108 <commands+0x518>
ffffffffc0200e5e:	d4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e62:	00001697          	auipc	a3,0x1
ffffffffc0200e66:	51668693          	addi	a3,a3,1302 # ffffffffc0202378 <commands+0x788>
ffffffffc0200e6a:	00001617          	auipc	a2,0x1
ffffffffc0200e6e:	28660613          	addi	a2,a2,646 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200e72:	14300593          	li	a1,323
ffffffffc0200e76:	00001517          	auipc	a0,0x1
ffffffffc0200e7a:	29250513          	addi	a0,a0,658 # ffffffffc0202108 <commands+0x518>
ffffffffc0200e7e:	d2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e82:	00001697          	auipc	a3,0x1
ffffffffc0200e86:	4d668693          	addi	a3,a3,1238 # ffffffffc0202358 <commands+0x768>
ffffffffc0200e8a:	00001617          	auipc	a2,0x1
ffffffffc0200e8e:	26660613          	addi	a2,a2,614 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200e92:	14200593          	li	a1,322
ffffffffc0200e96:	00001517          	auipc	a0,0x1
ffffffffc0200e9a:	27250513          	addi	a0,a0,626 # ffffffffc0202108 <commands+0x518>
ffffffffc0200e9e:	d0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200ea2:	00001697          	auipc	a3,0x1
ffffffffc0200ea6:	48668693          	addi	a3,a3,1158 # ffffffffc0202328 <commands+0x738>
ffffffffc0200eaa:	00001617          	auipc	a2,0x1
ffffffffc0200eae:	24660613          	addi	a2,a2,582 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200eb2:	14000593          	li	a1,320
ffffffffc0200eb6:	00001517          	auipc	a0,0x1
ffffffffc0200eba:	25250513          	addi	a0,a0,594 # ffffffffc0202108 <commands+0x518>
ffffffffc0200ebe:	ceeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ec2:	00001697          	auipc	a3,0x1
ffffffffc0200ec6:	44e68693          	addi	a3,a3,1102 # ffffffffc0202310 <commands+0x720>
ffffffffc0200eca:	00001617          	auipc	a2,0x1
ffffffffc0200ece:	22660613          	addi	a2,a2,550 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200ed2:	13f00593          	li	a1,319
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	23250513          	addi	a0,a0,562 # ffffffffc0202108 <commands+0x518>
ffffffffc0200ede:	cceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ee2:	00001697          	auipc	a3,0x1
ffffffffc0200ee6:	39668693          	addi	a3,a3,918 # ffffffffc0202278 <commands+0x688>
ffffffffc0200eea:	00001617          	auipc	a2,0x1
ffffffffc0200eee:	20660613          	addi	a2,a2,518 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200ef2:	13300593          	li	a1,307
ffffffffc0200ef6:	00001517          	auipc	a0,0x1
ffffffffc0200efa:	21250513          	addi	a0,a0,530 # ffffffffc0202108 <commands+0x518>
ffffffffc0200efe:	caeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f02:	00001697          	auipc	a3,0x1
ffffffffc0200f06:	3f668693          	addi	a3,a3,1014 # ffffffffc02022f8 <commands+0x708>
ffffffffc0200f0a:	00001617          	auipc	a2,0x1
ffffffffc0200f0e:	1e660613          	addi	a2,a2,486 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200f12:	12a00593          	li	a1,298
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	1f250513          	addi	a0,a0,498 # ffffffffc0202108 <commands+0x518>
ffffffffc0200f1e:	c8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200f22:	00001697          	auipc	a3,0x1
ffffffffc0200f26:	3c668693          	addi	a3,a3,966 # ffffffffc02022e8 <commands+0x6f8>
ffffffffc0200f2a:	00001617          	auipc	a2,0x1
ffffffffc0200f2e:	1c660613          	addi	a2,a2,454 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200f32:	12900593          	li	a1,297
ffffffffc0200f36:	00001517          	auipc	a0,0x1
ffffffffc0200f3a:	1d250513          	addi	a0,a0,466 # ffffffffc0202108 <commands+0x518>
ffffffffc0200f3e:	c6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200f42:	00001697          	auipc	a3,0x1
ffffffffc0200f46:	39668693          	addi	a3,a3,918 # ffffffffc02022d8 <commands+0x6e8>
ffffffffc0200f4a:	00001617          	auipc	a2,0x1
ffffffffc0200f4e:	1a660613          	addi	a2,a2,422 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200f52:	10b00593          	li	a1,267
ffffffffc0200f56:	00001517          	auipc	a0,0x1
ffffffffc0200f5a:	1b250513          	addi	a0,a0,434 # ffffffffc0202108 <commands+0x518>
ffffffffc0200f5e:	c4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f62:	00001697          	auipc	a3,0x1
ffffffffc0200f66:	31668693          	addi	a3,a3,790 # ffffffffc0202278 <commands+0x688>
ffffffffc0200f6a:	00001617          	auipc	a2,0x1
ffffffffc0200f6e:	18660613          	addi	a2,a2,390 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200f72:	10900593          	li	a1,265
ffffffffc0200f76:	00001517          	auipc	a0,0x1
ffffffffc0200f7a:	19250513          	addi	a0,a0,402 # ffffffffc0202108 <commands+0x518>
ffffffffc0200f7e:	c2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f82:	00001697          	auipc	a3,0x1
ffffffffc0200f86:	33668693          	addi	a3,a3,822 # ffffffffc02022b8 <commands+0x6c8>
ffffffffc0200f8a:	00001617          	auipc	a2,0x1
ffffffffc0200f8e:	16660613          	addi	a2,a2,358 # ffffffffc02020f0 <commands+0x500>
ffffffffc0200f92:	10800593          	li	a1,264
ffffffffc0200f96:	00001517          	auipc	a0,0x1
ffffffffc0200f9a:	17250513          	addi	a0,a0,370 # ffffffffc0202108 <commands+0x518>
ffffffffc0200f9e:	c0eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200fa2 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200fa2:	1141                	addi	sp,sp,-16
ffffffffc0200fa4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fa6:	14058a63          	beqz	a1,ffffffffc02010fa <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0200faa:	00259693          	slli	a3,a1,0x2
ffffffffc0200fae:	96ae                	add	a3,a3,a1
ffffffffc0200fb0:	068e                	slli	a3,a3,0x3
ffffffffc0200fb2:	96aa                	add	a3,a3,a0
ffffffffc0200fb4:	87aa                	mv	a5,a0
ffffffffc0200fb6:	02d50263          	beq	a0,a3,ffffffffc0200fda <best_fit_free_pages+0x38>
ffffffffc0200fba:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fbc:	8b05                	andi	a4,a4,1
ffffffffc0200fbe:	10071e63          	bnez	a4,ffffffffc02010da <best_fit_free_pages+0x138>
ffffffffc0200fc2:	6798                	ld	a4,8(a5)
ffffffffc0200fc4:	8b09                	andi	a4,a4,2
ffffffffc0200fc6:	10071a63          	bnez	a4,ffffffffc02010da <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0200fca:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200fce:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fd2:	02878793          	addi	a5,a5,40
ffffffffc0200fd6:	fed792e3          	bne	a5,a3,ffffffffc0200fba <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0200fda:	2581                	sext.w	a1,a1
ffffffffc0200fdc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);       // 这块儿可用了
ffffffffc0200fde:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200fe2:	4789                	li	a5,2
ffffffffc0200fe4:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;                // 空闲块增加
ffffffffc0200fe8:	00005697          	auipc	a3,0x5
ffffffffc0200fec:	02868693          	addi	a3,a3,40 # ffffffffc0206010 <free_area>
ffffffffc0200ff0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0200ff2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200ff4:	01850613          	addi	a2,a0,24
    nr_free += n;                // 空闲块增加
ffffffffc0200ff8:	9db9                	addw	a1,a1,a4
ffffffffc0200ffa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200ffc:	0ad78863          	beq	a5,a3,ffffffffc02010ac <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201000:	fe878713          	addi	a4,a5,-24
ffffffffc0201004:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201008:	4581                	li	a1,0
            if (base < page) {
ffffffffc020100a:	00e56a63          	bltu	a0,a4,ffffffffc020101e <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020100e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201010:	06d70263          	beq	a4,a3,ffffffffc0201074 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201014:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201016:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020101a:	fee57ae3          	bgeu	a0,a4,ffffffffc020100e <best_fit_free_pages+0x6c>
ffffffffc020101e:	c199                	beqz	a1,ffffffffc0201024 <best_fit_free_pages+0x82>
ffffffffc0201020:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201024:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201026:	e390                	sd	a2,0(a5)
ffffffffc0201028:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020102a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020102c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020102e:	02d70063          	beq	a4,a3,ffffffffc020104e <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201032:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201036:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020103a:	02081613          	slli	a2,a6,0x20
ffffffffc020103e:	9201                	srli	a2,a2,0x20
ffffffffc0201040:	00261793          	slli	a5,a2,0x2
ffffffffc0201044:	97b2                	add	a5,a5,a2
ffffffffc0201046:	078e                	slli	a5,a5,0x3
ffffffffc0201048:	97ae                	add	a5,a5,a1
ffffffffc020104a:	02f50f63          	beq	a0,a5,ffffffffc0201088 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc020104e:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201050:	00d70f63          	beq	a4,a3,ffffffffc020106e <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201054:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201056:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020105a:	02059613          	slli	a2,a1,0x20
ffffffffc020105e:	9201                	srli	a2,a2,0x20
ffffffffc0201060:	00261793          	slli	a5,a2,0x2
ffffffffc0201064:	97b2                	add	a5,a5,a2
ffffffffc0201066:	078e                	slli	a5,a5,0x3
ffffffffc0201068:	97aa                	add	a5,a5,a0
ffffffffc020106a:	04f68863          	beq	a3,a5,ffffffffc02010ba <best_fit_free_pages+0x118>
}
ffffffffc020106e:	60a2                	ld	ra,8(sp)
ffffffffc0201070:	0141                	addi	sp,sp,16
ffffffffc0201072:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201074:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201076:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201078:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020107a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020107c:	02d70563          	beq	a4,a3,ffffffffc02010a6 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201080:	8832                	mv	a6,a2
ffffffffc0201082:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201084:	87ba                	mv	a5,a4
ffffffffc0201086:	bf41                	j	ffffffffc0201016 <best_fit_free_pages+0x74>
            p->property += base->property;  // 更新前一个块的大小
ffffffffc0201088:	491c                	lw	a5,16(a0)
ffffffffc020108a:	0107883b          	addw	a6,a5,a6
ffffffffc020108e:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201092:	57f5                	li	a5,-3
ffffffffc0201094:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201098:	6d10                	ld	a2,24(a0)
ffffffffc020109a:	711c                	ld	a5,32(a0)
            base = p;                       // 指针指向合并后的块
ffffffffc020109c:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020109e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02010a0:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02010a2:	e390                	sd	a2,0(a5)
ffffffffc02010a4:	b775                	j	ffffffffc0201050 <best_fit_free_pages+0xae>
ffffffffc02010a6:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02010a8:	873e                	mv	a4,a5
ffffffffc02010aa:	b761                	j	ffffffffc0201032 <best_fit_free_pages+0x90>
}
ffffffffc02010ac:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02010ae:	e390                	sd	a2,0(a5)
ffffffffc02010b0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010b2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010b4:	ed1c                	sd	a5,24(a0)
ffffffffc02010b6:	0141                	addi	sp,sp,16
ffffffffc02010b8:	8082                	ret
            base->property += p->property;
ffffffffc02010ba:	ff872783          	lw	a5,-8(a4)
ffffffffc02010be:	ff070693          	addi	a3,a4,-16
ffffffffc02010c2:	9dbd                	addw	a1,a1,a5
ffffffffc02010c4:	c90c                	sw	a1,16(a0)
ffffffffc02010c6:	57f5                	li	a5,-3
ffffffffc02010c8:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010cc:	6314                	ld	a3,0(a4)
ffffffffc02010ce:	671c                	ld	a5,8(a4)
}
ffffffffc02010d0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02010d2:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02010d4:	e394                	sd	a3,0(a5)
ffffffffc02010d6:	0141                	addi	sp,sp,16
ffffffffc02010d8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010da:	00001697          	auipc	a3,0x1
ffffffffc02010de:	30668693          	addi	a3,a3,774 # ffffffffc02023e0 <commands+0x7f0>
ffffffffc02010e2:	00001617          	auipc	a2,0x1
ffffffffc02010e6:	00e60613          	addi	a2,a2,14 # ffffffffc02020f0 <commands+0x500>
ffffffffc02010ea:	0a100593          	li	a1,161
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	01a50513          	addi	a0,a0,26 # ffffffffc0202108 <commands+0x518>
ffffffffc02010f6:	ab6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02010fa:	00001697          	auipc	a3,0x1
ffffffffc02010fe:	fee68693          	addi	a3,a3,-18 # ffffffffc02020e8 <commands+0x4f8>
ffffffffc0201102:	00001617          	auipc	a2,0x1
ffffffffc0201106:	fee60613          	addi	a2,a2,-18 # ffffffffc02020f0 <commands+0x500>
ffffffffc020110a:	09e00593          	li	a1,158
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	ffa50513          	addi	a0,a0,-6 # ffffffffc0202108 <commands+0x518>
ffffffffc0201116:	a96ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020111a <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020111a:	1141                	addi	sp,sp,-16
ffffffffc020111c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020111e:	cdc5                	beqz	a1,ffffffffc02011d6 <best_fit_init_memmap+0xbc>
    for (; p != base + n; p ++) {
ffffffffc0201120:	00259693          	slli	a3,a1,0x2
ffffffffc0201124:	96ae                	add	a3,a3,a1
ffffffffc0201126:	068e                	slli	a3,a3,0x3
ffffffffc0201128:	96aa                	add	a3,a3,a0
ffffffffc020112a:	87aa                	mv	a5,a0
ffffffffc020112c:	00d50f63          	beq	a0,a3,ffffffffc020114a <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201130:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201132:	8b05                	andi	a4,a4,1
ffffffffc0201134:	c349                	beqz	a4,ffffffffc02011b6 <best_fit_init_memmap+0x9c>
        p->flags = p->property = 0;
ffffffffc0201136:	0007a823          	sw	zero,16(a5)
ffffffffc020113a:	0007b423          	sd	zero,8(a5)
ffffffffc020113e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201142:	02878793          	addi	a5,a5,40
ffffffffc0201146:	fed795e3          	bne	a5,a3,ffffffffc0201130 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc020114a:	2581                	sext.w	a1,a1
ffffffffc020114c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020114e:	4789                	li	a5,2
ffffffffc0201150:	00850713          	addi	a4,a0,8
ffffffffc0201154:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201158:	00005697          	auipc	a3,0x5
ffffffffc020115c:	eb868693          	addi	a3,a3,-328 # ffffffffc0206010 <free_area>
ffffffffc0201160:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201162:	669c                	ld	a5,8(a3)
ffffffffc0201164:	9db9                	addw	a1,a1,a4
ffffffffc0201166:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201168:	00d79763          	bne	a5,a3,ffffffffc0201176 <best_fit_init_memmap+0x5c>
ffffffffc020116c:	a01d                	j	ffffffffc0201192 <best_fit_init_memmap+0x78>
    return listelm->next;
ffffffffc020116e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) { // 2、到结尾了
ffffffffc0201170:	02d70a63          	beq	a4,a3,ffffffffc02011a4 <best_fit_init_memmap+0x8a>
ffffffffc0201174:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201176:	fe878713          	addi	a4,a5,-24
            if (base < page) {                // 1、找到第一个大于base的页
ffffffffc020117a:	fee57ae3          	bgeu	a0,a4,ffffffffc020116e <best_fit_init_memmap+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020117e:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link)); // 插入到它前面
ffffffffc0201180:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0201184:	e394                	sd	a3,0(a5)
}
ffffffffc0201186:	60a2                	ld	ra,8(sp)
ffffffffc0201188:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020118a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020118c:	ed18                	sd	a4,24(a0)
ffffffffc020118e:	0141                	addi	sp,sp,16
ffffffffc0201190:	8082                	ret
ffffffffc0201192:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201194:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201198:	e398                	sd	a4,0(a5)
ffffffffc020119a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020119c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020119e:	ed1c                	sd	a5,24(a0)
}
ffffffffc02011a0:	0141                	addi	sp,sp,16
ffffffffc02011a2:	8082                	ret
ffffffffc02011a4:	60a2                	ld	ra,8(sp)
                list_add(le, &(base->page_link));    // 插到链表尾部
ffffffffc02011a6:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02011aa:	e798                	sd	a4,8(a5)
ffffffffc02011ac:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc02011ae:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc02011b0:	ed1c                	sd	a5,24(a0)
}
ffffffffc02011b2:	0141                	addi	sp,sp,16
ffffffffc02011b4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02011b6:	00001697          	auipc	a3,0x1
ffffffffc02011ba:	25268693          	addi	a3,a3,594 # ffffffffc0202408 <commands+0x818>
ffffffffc02011be:	00001617          	auipc	a2,0x1
ffffffffc02011c2:	f3260613          	addi	a2,a2,-206 # ffffffffc02020f0 <commands+0x500>
ffffffffc02011c6:	04b00593          	li	a1,75
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	f3e50513          	addi	a0,a0,-194 # ffffffffc0202108 <commands+0x518>
ffffffffc02011d2:	9daff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011d6:	00001697          	auipc	a3,0x1
ffffffffc02011da:	f1268693          	addi	a3,a3,-238 # ffffffffc02020e8 <commands+0x4f8>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	f1260613          	addi	a2,a2,-238 # ffffffffc02020f0 <commands+0x500>
ffffffffc02011e6:	04700593          	li	a1,71
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	f1e50513          	addi	a0,a0,-226 # ffffffffc0202108 <commands+0x518>
ffffffffc02011f2:	9baff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011f6 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011f6:	100027f3          	csrr	a5,sstatus
ffffffffc02011fa:	8b89                	andi	a5,a5,2
ffffffffc02011fc:	e799                	bnez	a5,ffffffffc020120a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02011fe:	00005797          	auipc	a5,0x5
ffffffffc0201202:	24a7b783          	ld	a5,586(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201206:	6f9c                	ld	a5,24(a5)
ffffffffc0201208:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020120a:	1141                	addi	sp,sp,-16
ffffffffc020120c:	e406                	sd	ra,8(sp)
ffffffffc020120e:	e022                	sd	s0,0(sp)
ffffffffc0201210:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201212:	a4cff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201216:	00005797          	auipc	a5,0x5
ffffffffc020121a:	2327b783          	ld	a5,562(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc020121e:	6f9c                	ld	a5,24(a5)
ffffffffc0201220:	8522                	mv	a0,s0
ffffffffc0201222:	9782                	jalr	a5
ffffffffc0201224:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201226:	a32ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020122a:	60a2                	ld	ra,8(sp)
ffffffffc020122c:	8522                	mv	a0,s0
ffffffffc020122e:	6402                	ld	s0,0(sp)
ffffffffc0201230:	0141                	addi	sp,sp,16
ffffffffc0201232:	8082                	ret

ffffffffc0201234 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201234:	100027f3          	csrr	a5,sstatus
ffffffffc0201238:	8b89                	andi	a5,a5,2
ffffffffc020123a:	e799                	bnez	a5,ffffffffc0201248 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020123c:	00005797          	auipc	a5,0x5
ffffffffc0201240:	20c7b783          	ld	a5,524(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201244:	739c                	ld	a5,32(a5)
ffffffffc0201246:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201248:	1101                	addi	sp,sp,-32
ffffffffc020124a:	ec06                	sd	ra,24(sp)
ffffffffc020124c:	e822                	sd	s0,16(sp)
ffffffffc020124e:	e426                	sd	s1,8(sp)
ffffffffc0201250:	842a                	mv	s0,a0
ffffffffc0201252:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201254:	a0aff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201258:	00005797          	auipc	a5,0x5
ffffffffc020125c:	1f07b783          	ld	a5,496(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201260:	739c                	ld	a5,32(a5)
ffffffffc0201262:	85a6                	mv	a1,s1
ffffffffc0201264:	8522                	mv	a0,s0
ffffffffc0201266:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201268:	6442                	ld	s0,16(sp)
ffffffffc020126a:	60e2                	ld	ra,24(sp)
ffffffffc020126c:	64a2                	ld	s1,8(sp)
ffffffffc020126e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201270:	9e8ff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc0201274 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201274:	100027f3          	csrr	a5,sstatus
ffffffffc0201278:	8b89                	andi	a5,a5,2
ffffffffc020127a:	e799                	bnez	a5,ffffffffc0201288 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020127c:	00005797          	auipc	a5,0x5
ffffffffc0201280:	1cc7b783          	ld	a5,460(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc0201284:	779c                	ld	a5,40(a5)
ffffffffc0201286:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201288:	1141                	addi	sp,sp,-16
ffffffffc020128a:	e406                	sd	ra,8(sp)
ffffffffc020128c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020128e:	9d0ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201292:	00005797          	auipc	a5,0x5
ffffffffc0201296:	1b67b783          	ld	a5,438(a5) # ffffffffc0206448 <pmm_manager>
ffffffffc020129a:	779c                	ld	a5,40(a5)
ffffffffc020129c:	9782                	jalr	a5
ffffffffc020129e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02012a0:	9b8ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02012a4:	60a2                	ld	ra,8(sp)
ffffffffc02012a6:	8522                	mv	a0,s0
ffffffffc02012a8:	6402                	ld	s0,0(sp)
ffffffffc02012aa:	0141                	addi	sp,sp,16
ffffffffc02012ac:	8082                	ret

ffffffffc02012ae <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012ae:	00001797          	auipc	a5,0x1
ffffffffc02012b2:	18278793          	addi	a5,a5,386 # ffffffffc0202430 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012b6:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02012b8:	1101                	addi	sp,sp,-32
ffffffffc02012ba:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012bc:	00001517          	auipc	a0,0x1
ffffffffc02012c0:	1ac50513          	addi	a0,a0,428 # ffffffffc0202468 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012c4:	00005497          	auipc	s1,0x5
ffffffffc02012c8:	18448493          	addi	s1,s1,388 # ffffffffc0206448 <pmm_manager>
void pmm_init(void) {
ffffffffc02012cc:	ec06                	sd	ra,24(sp)
ffffffffc02012ce:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012d0:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012d2:	de1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc02012d6:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012d8:	00005417          	auipc	s0,0x5
ffffffffc02012dc:	18840413          	addi	s0,s0,392 # ffffffffc0206460 <va_pa_offset>
    pmm_manager->init();
ffffffffc02012e0:	679c                	ld	a5,8(a5)
ffffffffc02012e2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012e4:	57f5                	li	a5,-3
ffffffffc02012e6:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02012e8:	00001517          	auipc	a0,0x1
ffffffffc02012ec:	19850513          	addi	a0,a0,408 # ffffffffc0202480 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012f0:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc02012f2:	dc1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02012f6:	46c5                	li	a3,17
ffffffffc02012f8:	06ee                	slli	a3,a3,0x1b
ffffffffc02012fa:	40100613          	li	a2,1025
ffffffffc02012fe:	16fd                	addi	a3,a3,-1
ffffffffc0201300:	07e005b7          	lui	a1,0x7e00
ffffffffc0201304:	0656                	slli	a2,a2,0x15
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	19250513          	addi	a0,a0,402 # ffffffffc0202498 <best_fit_pmm_manager+0x68>
ffffffffc020130e:	da5fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201312:	777d                	lui	a4,0xfffff
ffffffffc0201314:	00006797          	auipc	a5,0x6
ffffffffc0201318:	15b78793          	addi	a5,a5,347 # ffffffffc020746f <end+0xfff>
ffffffffc020131c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020131e:	00005517          	auipc	a0,0x5
ffffffffc0201322:	11a50513          	addi	a0,a0,282 # ffffffffc0206438 <npage>
ffffffffc0201326:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020132a:	00005597          	auipc	a1,0x5
ffffffffc020132e:	11658593          	addi	a1,a1,278 # ffffffffc0206440 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201332:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201334:	e19c                	sd	a5,0(a1)
ffffffffc0201336:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201338:	4701                	li	a4,0
ffffffffc020133a:	4885                	li	a7,1
ffffffffc020133c:	fff80837          	lui	a6,0xfff80
ffffffffc0201340:	a011                	j	ffffffffc0201344 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201342:	619c                	ld	a5,0(a1)
ffffffffc0201344:	97b6                	add	a5,a5,a3
ffffffffc0201346:	07a1                	addi	a5,a5,8
ffffffffc0201348:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020134c:	611c                	ld	a5,0(a0)
ffffffffc020134e:	0705                	addi	a4,a4,1
ffffffffc0201350:	02868693          	addi	a3,a3,40
ffffffffc0201354:	01078633          	add	a2,a5,a6
ffffffffc0201358:	fec765e3          	bltu	a4,a2,ffffffffc0201342 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020135c:	6190                	ld	a2,0(a1)
ffffffffc020135e:	00279713          	slli	a4,a5,0x2
ffffffffc0201362:	973e                	add	a4,a4,a5
ffffffffc0201364:	fec006b7          	lui	a3,0xfec00
ffffffffc0201368:	070e                	slli	a4,a4,0x3
ffffffffc020136a:	96b2                	add	a3,a3,a2
ffffffffc020136c:	96ba                	add	a3,a3,a4
ffffffffc020136e:	c0200737          	lui	a4,0xc0200
ffffffffc0201372:	08e6ef63          	bltu	a3,a4,ffffffffc0201410 <pmm_init+0x162>
ffffffffc0201376:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc0201378:	45c5                	li	a1,17
ffffffffc020137a:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020137c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020137e:	04b6e863          	bltu	a3,a1,ffffffffc02013ce <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201382:	609c                	ld	a5,0(s1)
ffffffffc0201384:	7b9c                	ld	a5,48(a5)
ffffffffc0201386:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201388:	00001517          	auipc	a0,0x1
ffffffffc020138c:	1a850513          	addi	a0,a0,424 # ffffffffc0202530 <best_fit_pmm_manager+0x100>
ffffffffc0201390:	d23fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201394:	00004597          	auipc	a1,0x4
ffffffffc0201398:	c6c58593          	addi	a1,a1,-916 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020139c:	00005797          	auipc	a5,0x5
ffffffffc02013a0:	0ab7be23          	sd	a1,188(a5) # ffffffffc0206458 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013a4:	c02007b7          	lui	a5,0xc0200
ffffffffc02013a8:	08f5e063          	bltu	a1,a5,ffffffffc0201428 <pmm_init+0x17a>
ffffffffc02013ac:	6010                	ld	a2,0(s0)
}
ffffffffc02013ae:	6442                	ld	s0,16(sp)
ffffffffc02013b0:	60e2                	ld	ra,24(sp)
ffffffffc02013b2:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02013b4:	40c58633          	sub	a2,a1,a2
ffffffffc02013b8:	00005797          	auipc	a5,0x5
ffffffffc02013bc:	08c7bc23          	sd	a2,152(a5) # ffffffffc0206450 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013c0:	00001517          	auipc	a0,0x1
ffffffffc02013c4:	19050513          	addi	a0,a0,400 # ffffffffc0202550 <best_fit_pmm_manager+0x120>
}
ffffffffc02013c8:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013ca:	ce9fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02013ce:	6705                	lui	a4,0x1
ffffffffc02013d0:	177d                	addi	a4,a4,-1
ffffffffc02013d2:	96ba                	add	a3,a3,a4
ffffffffc02013d4:	777d                	lui	a4,0xfffff
ffffffffc02013d6:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02013d8:	00c6d513          	srli	a0,a3,0xc
ffffffffc02013dc:	00f57e63          	bgeu	a0,a5,ffffffffc02013f8 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc02013e0:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02013e2:	982a                	add	a6,a6,a0
ffffffffc02013e4:	00281513          	slli	a0,a6,0x2
ffffffffc02013e8:	9542                	add	a0,a0,a6
ffffffffc02013ea:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02013ec:	8d95                	sub	a1,a1,a3
ffffffffc02013ee:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02013f0:	81b1                	srli	a1,a1,0xc
ffffffffc02013f2:	9532                	add	a0,a0,a2
ffffffffc02013f4:	9782                	jalr	a5
}
ffffffffc02013f6:	b771                	j	ffffffffc0201382 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	10860613          	addi	a2,a2,264 # ffffffffc0202500 <best_fit_pmm_manager+0xd0>
ffffffffc0201400:	06b00593          	li	a1,107
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	11c50513          	addi	a0,a0,284 # ffffffffc0202520 <best_fit_pmm_manager+0xf0>
ffffffffc020140c:	fa1fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201410:	00001617          	auipc	a2,0x1
ffffffffc0201414:	0b860613          	addi	a2,a2,184 # ffffffffc02024c8 <best_fit_pmm_manager+0x98>
ffffffffc0201418:	06e00593          	li	a1,110
ffffffffc020141c:	00001517          	auipc	a0,0x1
ffffffffc0201420:	0d450513          	addi	a0,a0,212 # ffffffffc02024f0 <best_fit_pmm_manager+0xc0>
ffffffffc0201424:	f89fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201428:	86ae                	mv	a3,a1
ffffffffc020142a:	00001617          	auipc	a2,0x1
ffffffffc020142e:	09e60613          	addi	a2,a2,158 # ffffffffc02024c8 <best_fit_pmm_manager+0x98>
ffffffffc0201432:	08900593          	li	a1,137
ffffffffc0201436:	00001517          	auipc	a0,0x1
ffffffffc020143a:	0ba50513          	addi	a0,a0,186 # ffffffffc02024f0 <best_fit_pmm_manager+0xc0>
ffffffffc020143e:	f6ffe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201442 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201442:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201446:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201448:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020144c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020144e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201452:	f022                	sd	s0,32(sp)
ffffffffc0201454:	ec26                	sd	s1,24(sp)
ffffffffc0201456:	e84a                	sd	s2,16(sp)
ffffffffc0201458:	f406                	sd	ra,40(sp)
ffffffffc020145a:	e44e                	sd	s3,8(sp)
ffffffffc020145c:	84aa                	mv	s1,a0
ffffffffc020145e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201460:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201464:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201466:	03067e63          	bgeu	a2,a6,ffffffffc02014a2 <printnum+0x60>
ffffffffc020146a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020146c:	00805763          	blez	s0,ffffffffc020147a <printnum+0x38>
ffffffffc0201470:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201472:	85ca                	mv	a1,s2
ffffffffc0201474:	854e                	mv	a0,s3
ffffffffc0201476:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201478:	fc65                	bnez	s0,ffffffffc0201470 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020147a:	1a02                	slli	s4,s4,0x20
ffffffffc020147c:	00001797          	auipc	a5,0x1
ffffffffc0201480:	11478793          	addi	a5,a5,276 # ffffffffc0202590 <best_fit_pmm_manager+0x160>
ffffffffc0201484:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201488:	9a3e                	add	s4,s4,a5
}
ffffffffc020148a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020148c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201490:	70a2                	ld	ra,40(sp)
ffffffffc0201492:	69a2                	ld	s3,8(sp)
ffffffffc0201494:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201496:	85ca                	mv	a1,s2
ffffffffc0201498:	87a6                	mv	a5,s1
}
ffffffffc020149a:	6942                	ld	s2,16(sp)
ffffffffc020149c:	64e2                	ld	s1,24(sp)
ffffffffc020149e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014a0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02014a2:	03065633          	divu	a2,a2,a6
ffffffffc02014a6:	8722                	mv	a4,s0
ffffffffc02014a8:	f9bff0ef          	jal	ra,ffffffffc0201442 <printnum>
ffffffffc02014ac:	b7f9                	j	ffffffffc020147a <printnum+0x38>

ffffffffc02014ae <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02014ae:	7119                	addi	sp,sp,-128
ffffffffc02014b0:	f4a6                	sd	s1,104(sp)
ffffffffc02014b2:	f0ca                	sd	s2,96(sp)
ffffffffc02014b4:	ecce                	sd	s3,88(sp)
ffffffffc02014b6:	e8d2                	sd	s4,80(sp)
ffffffffc02014b8:	e4d6                	sd	s5,72(sp)
ffffffffc02014ba:	e0da                	sd	s6,64(sp)
ffffffffc02014bc:	fc5e                	sd	s7,56(sp)
ffffffffc02014be:	f06a                	sd	s10,32(sp)
ffffffffc02014c0:	fc86                	sd	ra,120(sp)
ffffffffc02014c2:	f8a2                	sd	s0,112(sp)
ffffffffc02014c4:	f862                	sd	s8,48(sp)
ffffffffc02014c6:	f466                	sd	s9,40(sp)
ffffffffc02014c8:	ec6e                	sd	s11,24(sp)
ffffffffc02014ca:	892a                	mv	s2,a0
ffffffffc02014cc:	84ae                	mv	s1,a1
ffffffffc02014ce:	8d32                	mv	s10,a2
ffffffffc02014d0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014d2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02014d6:	5b7d                	li	s6,-1
ffffffffc02014d8:	00001a97          	auipc	s5,0x1
ffffffffc02014dc:	0eca8a93          	addi	s5,s5,236 # ffffffffc02025c4 <best_fit_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014e0:	00001b97          	auipc	s7,0x1
ffffffffc02014e4:	2c0b8b93          	addi	s7,s7,704 # ffffffffc02027a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014e8:	000d4503          	lbu	a0,0(s10)
ffffffffc02014ec:	001d0413          	addi	s0,s10,1
ffffffffc02014f0:	01350a63          	beq	a0,s3,ffffffffc0201504 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02014f4:	c121                	beqz	a0,ffffffffc0201534 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02014f6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014f8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02014fa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014fc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201500:	ff351ae3          	bne	a0,s3,ffffffffc02014f4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201504:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201508:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020150c:	4c81                	li	s9,0
ffffffffc020150e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201510:	5c7d                	li	s8,-1
ffffffffc0201512:	5dfd                	li	s11,-1
ffffffffc0201514:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201518:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020151a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020151e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201522:	00140d13          	addi	s10,s0,1
ffffffffc0201526:	04b56263          	bltu	a0,a1,ffffffffc020156a <vprintfmt+0xbc>
ffffffffc020152a:	058a                	slli	a1,a1,0x2
ffffffffc020152c:	95d6                	add	a1,a1,s5
ffffffffc020152e:	4194                	lw	a3,0(a1)
ffffffffc0201530:	96d6                	add	a3,a3,s5
ffffffffc0201532:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201534:	70e6                	ld	ra,120(sp)
ffffffffc0201536:	7446                	ld	s0,112(sp)
ffffffffc0201538:	74a6                	ld	s1,104(sp)
ffffffffc020153a:	7906                	ld	s2,96(sp)
ffffffffc020153c:	69e6                	ld	s3,88(sp)
ffffffffc020153e:	6a46                	ld	s4,80(sp)
ffffffffc0201540:	6aa6                	ld	s5,72(sp)
ffffffffc0201542:	6b06                	ld	s6,64(sp)
ffffffffc0201544:	7be2                	ld	s7,56(sp)
ffffffffc0201546:	7c42                	ld	s8,48(sp)
ffffffffc0201548:	7ca2                	ld	s9,40(sp)
ffffffffc020154a:	7d02                	ld	s10,32(sp)
ffffffffc020154c:	6de2                	ld	s11,24(sp)
ffffffffc020154e:	6109                	addi	sp,sp,128
ffffffffc0201550:	8082                	ret
            padc = '0';
ffffffffc0201552:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201554:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201558:	846a                	mv	s0,s10
ffffffffc020155a:	00140d13          	addi	s10,s0,1
ffffffffc020155e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201562:	0ff5f593          	zext.b	a1,a1
ffffffffc0201566:	fcb572e3          	bgeu	a0,a1,ffffffffc020152a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020156a:	85a6                	mv	a1,s1
ffffffffc020156c:	02500513          	li	a0,37
ffffffffc0201570:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201572:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201576:	8d22                	mv	s10,s0
ffffffffc0201578:	f73788e3          	beq	a5,s3,ffffffffc02014e8 <vprintfmt+0x3a>
ffffffffc020157c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201580:	1d7d                	addi	s10,s10,-1
ffffffffc0201582:	ff379de3          	bne	a5,s3,ffffffffc020157c <vprintfmt+0xce>
ffffffffc0201586:	b78d                	j	ffffffffc02014e8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201588:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020158c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201590:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201592:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201596:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020159a:	02d86463          	bltu	a6,a3,ffffffffc02015c2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020159e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02015a2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02015a6:	0186873b          	addw	a4,a3,s8
ffffffffc02015aa:	0017171b          	slliw	a4,a4,0x1
ffffffffc02015ae:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02015b0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02015b4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02015b6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02015ba:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02015be:	fed870e3          	bgeu	a6,a3,ffffffffc020159e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02015c2:	f40ddce3          	bgez	s11,ffffffffc020151a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02015c6:	8de2                	mv	s11,s8
ffffffffc02015c8:	5c7d                	li	s8,-1
ffffffffc02015ca:	bf81                	j	ffffffffc020151a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02015cc:	fffdc693          	not	a3,s11
ffffffffc02015d0:	96fd                	srai	a3,a3,0x3f
ffffffffc02015d2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015d6:	00144603          	lbu	a2,1(s0)
ffffffffc02015da:	2d81                	sext.w	s11,s11
ffffffffc02015dc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02015de:	bf35                	j	ffffffffc020151a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02015e0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015e4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02015e8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015ea:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02015ec:	bfd9                	j	ffffffffc02015c2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02015ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015f0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02015f4:	01174463          	blt	a4,a7,ffffffffc02015fc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02015f8:	1a088e63          	beqz	a7,ffffffffc02017b4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02015fc:	000a3603          	ld	a2,0(s4)
ffffffffc0201600:	46c1                	li	a3,16
ffffffffc0201602:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201604:	2781                	sext.w	a5,a5
ffffffffc0201606:	876e                	mv	a4,s11
ffffffffc0201608:	85a6                	mv	a1,s1
ffffffffc020160a:	854a                	mv	a0,s2
ffffffffc020160c:	e37ff0ef          	jal	ra,ffffffffc0201442 <printnum>
            break;
ffffffffc0201610:	bde1                	j	ffffffffc02014e8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201612:	000a2503          	lw	a0,0(s4)
ffffffffc0201616:	85a6                	mv	a1,s1
ffffffffc0201618:	0a21                	addi	s4,s4,8
ffffffffc020161a:	9902                	jalr	s2
            break;
ffffffffc020161c:	b5f1                	j	ffffffffc02014e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020161e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201620:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201624:	01174463          	blt	a4,a7,ffffffffc020162c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201628:	18088163          	beqz	a7,ffffffffc02017aa <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020162c:	000a3603          	ld	a2,0(s4)
ffffffffc0201630:	46a9                	li	a3,10
ffffffffc0201632:	8a2e                	mv	s4,a1
ffffffffc0201634:	bfc1                	j	ffffffffc0201604 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201636:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020163a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020163c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020163e:	bdf1                	j	ffffffffc020151a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201640:	85a6                	mv	a1,s1
ffffffffc0201642:	02500513          	li	a0,37
ffffffffc0201646:	9902                	jalr	s2
            break;
ffffffffc0201648:	b545                	j	ffffffffc02014e8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020164a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020164e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201650:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201652:	b5e1                	j	ffffffffc020151a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201654:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201656:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020165a:	01174463          	blt	a4,a7,ffffffffc0201662 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020165e:	14088163          	beqz	a7,ffffffffc02017a0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201662:	000a3603          	ld	a2,0(s4)
ffffffffc0201666:	46a1                	li	a3,8
ffffffffc0201668:	8a2e                	mv	s4,a1
ffffffffc020166a:	bf69                	j	ffffffffc0201604 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020166c:	03000513          	li	a0,48
ffffffffc0201670:	85a6                	mv	a1,s1
ffffffffc0201672:	e03e                	sd	a5,0(sp)
ffffffffc0201674:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201676:	85a6                	mv	a1,s1
ffffffffc0201678:	07800513          	li	a0,120
ffffffffc020167c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020167e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201680:	6782                	ld	a5,0(sp)
ffffffffc0201682:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201684:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201688:	bfb5                	j	ffffffffc0201604 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020168a:	000a3403          	ld	s0,0(s4)
ffffffffc020168e:	008a0713          	addi	a4,s4,8
ffffffffc0201692:	e03a                	sd	a4,0(sp)
ffffffffc0201694:	14040263          	beqz	s0,ffffffffc02017d8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201698:	0fb05763          	blez	s11,ffffffffc0201786 <vprintfmt+0x2d8>
ffffffffc020169c:	02d00693          	li	a3,45
ffffffffc02016a0:	0cd79163          	bne	a5,a3,ffffffffc0201762 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016a4:	00044783          	lbu	a5,0(s0)
ffffffffc02016a8:	0007851b          	sext.w	a0,a5
ffffffffc02016ac:	cf85                	beqz	a5,ffffffffc02016e4 <vprintfmt+0x236>
ffffffffc02016ae:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016b2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016b6:	000c4563          	bltz	s8,ffffffffc02016c0 <vprintfmt+0x212>
ffffffffc02016ba:	3c7d                	addiw	s8,s8,-1
ffffffffc02016bc:	036c0263          	beq	s8,s6,ffffffffc02016e0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02016c0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016c2:	0e0c8e63          	beqz	s9,ffffffffc02017be <vprintfmt+0x310>
ffffffffc02016c6:	3781                	addiw	a5,a5,-32
ffffffffc02016c8:	0ef47b63          	bgeu	s0,a5,ffffffffc02017be <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02016cc:	03f00513          	li	a0,63
ffffffffc02016d0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016d2:	000a4783          	lbu	a5,0(s4)
ffffffffc02016d6:	3dfd                	addiw	s11,s11,-1
ffffffffc02016d8:	0a05                	addi	s4,s4,1
ffffffffc02016da:	0007851b          	sext.w	a0,a5
ffffffffc02016de:	ffe1                	bnez	a5,ffffffffc02016b6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02016e0:	01b05963          	blez	s11,ffffffffc02016f2 <vprintfmt+0x244>
ffffffffc02016e4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02016e6:	85a6                	mv	a1,s1
ffffffffc02016e8:	02000513          	li	a0,32
ffffffffc02016ec:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02016ee:	fe0d9be3          	bnez	s11,ffffffffc02016e4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02016f2:	6a02                	ld	s4,0(sp)
ffffffffc02016f4:	bbd5                	j	ffffffffc02014e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02016f6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016f8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02016fc:	01174463          	blt	a4,a7,ffffffffc0201704 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201700:	08088d63          	beqz	a7,ffffffffc020179a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201704:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201708:	0a044d63          	bltz	s0,ffffffffc02017c2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020170c:	8622                	mv	a2,s0
ffffffffc020170e:	8a66                	mv	s4,s9
ffffffffc0201710:	46a9                	li	a3,10
ffffffffc0201712:	bdcd                	j	ffffffffc0201604 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201714:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201718:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020171a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020171c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201720:	8fb5                	xor	a5,a5,a3
ffffffffc0201722:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201726:	02d74163          	blt	a4,a3,ffffffffc0201748 <vprintfmt+0x29a>
ffffffffc020172a:	00369793          	slli	a5,a3,0x3
ffffffffc020172e:	97de                	add	a5,a5,s7
ffffffffc0201730:	639c                	ld	a5,0(a5)
ffffffffc0201732:	cb99                	beqz	a5,ffffffffc0201748 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201734:	86be                	mv	a3,a5
ffffffffc0201736:	00001617          	auipc	a2,0x1
ffffffffc020173a:	e8a60613          	addi	a2,a2,-374 # ffffffffc02025c0 <best_fit_pmm_manager+0x190>
ffffffffc020173e:	85a6                	mv	a1,s1
ffffffffc0201740:	854a                	mv	a0,s2
ffffffffc0201742:	0ce000ef          	jal	ra,ffffffffc0201810 <printfmt>
ffffffffc0201746:	b34d                	j	ffffffffc02014e8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201748:	00001617          	auipc	a2,0x1
ffffffffc020174c:	e6860613          	addi	a2,a2,-408 # ffffffffc02025b0 <best_fit_pmm_manager+0x180>
ffffffffc0201750:	85a6                	mv	a1,s1
ffffffffc0201752:	854a                	mv	a0,s2
ffffffffc0201754:	0bc000ef          	jal	ra,ffffffffc0201810 <printfmt>
ffffffffc0201758:	bb41                	j	ffffffffc02014e8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020175a:	00001417          	auipc	s0,0x1
ffffffffc020175e:	e4e40413          	addi	s0,s0,-434 # ffffffffc02025a8 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201762:	85e2                	mv	a1,s8
ffffffffc0201764:	8522                	mv	a0,s0
ffffffffc0201766:	e43e                	sd	a5,8(sp)
ffffffffc0201768:	1cc000ef          	jal	ra,ffffffffc0201934 <strnlen>
ffffffffc020176c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201770:	01b05b63          	blez	s11,ffffffffc0201786 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201774:	67a2                	ld	a5,8(sp)
ffffffffc0201776:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020177a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020177c:	85a6                	mv	a1,s1
ffffffffc020177e:	8552                	mv	a0,s4
ffffffffc0201780:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201782:	fe0d9ce3          	bnez	s11,ffffffffc020177a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201786:	00044783          	lbu	a5,0(s0)
ffffffffc020178a:	00140a13          	addi	s4,s0,1
ffffffffc020178e:	0007851b          	sext.w	a0,a5
ffffffffc0201792:	d3a5                	beqz	a5,ffffffffc02016f2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201794:	05e00413          	li	s0,94
ffffffffc0201798:	bf39                	j	ffffffffc02016b6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020179a:	000a2403          	lw	s0,0(s4)
ffffffffc020179e:	b7ad                	j	ffffffffc0201708 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02017a0:	000a6603          	lwu	a2,0(s4)
ffffffffc02017a4:	46a1                	li	a3,8
ffffffffc02017a6:	8a2e                	mv	s4,a1
ffffffffc02017a8:	bdb1                	j	ffffffffc0201604 <vprintfmt+0x156>
ffffffffc02017aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02017ae:	46a9                	li	a3,10
ffffffffc02017b0:	8a2e                	mv	s4,a1
ffffffffc02017b2:	bd89                	j	ffffffffc0201604 <vprintfmt+0x156>
ffffffffc02017b4:	000a6603          	lwu	a2,0(s4)
ffffffffc02017b8:	46c1                	li	a3,16
ffffffffc02017ba:	8a2e                	mv	s4,a1
ffffffffc02017bc:	b5a1                	j	ffffffffc0201604 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02017be:	9902                	jalr	s2
ffffffffc02017c0:	bf09                	j	ffffffffc02016d2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02017c2:	85a6                	mv	a1,s1
ffffffffc02017c4:	02d00513          	li	a0,45
ffffffffc02017c8:	e03e                	sd	a5,0(sp)
ffffffffc02017ca:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02017cc:	6782                	ld	a5,0(sp)
ffffffffc02017ce:	8a66                	mv	s4,s9
ffffffffc02017d0:	40800633          	neg	a2,s0
ffffffffc02017d4:	46a9                	li	a3,10
ffffffffc02017d6:	b53d                	j	ffffffffc0201604 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02017d8:	03b05163          	blez	s11,ffffffffc02017fa <vprintfmt+0x34c>
ffffffffc02017dc:	02d00693          	li	a3,45
ffffffffc02017e0:	f6d79de3          	bne	a5,a3,ffffffffc020175a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02017e4:	00001417          	auipc	s0,0x1
ffffffffc02017e8:	dc440413          	addi	s0,s0,-572 # ffffffffc02025a8 <best_fit_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017ec:	02800793          	li	a5,40
ffffffffc02017f0:	02800513          	li	a0,40
ffffffffc02017f4:	00140a13          	addi	s4,s0,1
ffffffffc02017f8:	bd6d                	j	ffffffffc02016b2 <vprintfmt+0x204>
ffffffffc02017fa:	00001a17          	auipc	s4,0x1
ffffffffc02017fe:	dafa0a13          	addi	s4,s4,-593 # ffffffffc02025a9 <best_fit_pmm_manager+0x179>
ffffffffc0201802:	02800513          	li	a0,40
ffffffffc0201806:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020180a:	05e00413          	li	s0,94
ffffffffc020180e:	b565                	j	ffffffffc02016b6 <vprintfmt+0x208>

ffffffffc0201810 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201810:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201812:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201816:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201818:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020181a:	ec06                	sd	ra,24(sp)
ffffffffc020181c:	f83a                	sd	a4,48(sp)
ffffffffc020181e:	fc3e                	sd	a5,56(sp)
ffffffffc0201820:	e0c2                	sd	a6,64(sp)
ffffffffc0201822:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201824:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201826:	c89ff0ef          	jal	ra,ffffffffc02014ae <vprintfmt>
}
ffffffffc020182a:	60e2                	ld	ra,24(sp)
ffffffffc020182c:	6161                	addi	sp,sp,80
ffffffffc020182e:	8082                	ret

ffffffffc0201830 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201830:	715d                	addi	sp,sp,-80
ffffffffc0201832:	e486                	sd	ra,72(sp)
ffffffffc0201834:	e0a6                	sd	s1,64(sp)
ffffffffc0201836:	fc4a                	sd	s2,56(sp)
ffffffffc0201838:	f84e                	sd	s3,48(sp)
ffffffffc020183a:	f452                	sd	s4,40(sp)
ffffffffc020183c:	f056                	sd	s5,32(sp)
ffffffffc020183e:	ec5a                	sd	s6,24(sp)
ffffffffc0201840:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201842:	c901                	beqz	a0,ffffffffc0201852 <readline+0x22>
ffffffffc0201844:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201846:	00001517          	auipc	a0,0x1
ffffffffc020184a:	d7a50513          	addi	a0,a0,-646 # ffffffffc02025c0 <best_fit_pmm_manager+0x190>
ffffffffc020184e:	865fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201852:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201854:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201856:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201858:	4aa9                	li	s5,10
ffffffffc020185a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020185c:	00004b97          	auipc	s7,0x4
ffffffffc0201860:	7ccb8b93          	addi	s7,s7,1996 # ffffffffc0206028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201864:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201868:	8c3fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020186c:	00054a63          	bltz	a0,ffffffffc0201880 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201870:	00a95a63          	bge	s2,a0,ffffffffc0201884 <readline+0x54>
ffffffffc0201874:	029a5263          	bge	s4,s1,ffffffffc0201898 <readline+0x68>
        c = getchar();
ffffffffc0201878:	8b3fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020187c:	fe055ae3          	bgez	a0,ffffffffc0201870 <readline+0x40>
            return NULL;
ffffffffc0201880:	4501                	li	a0,0
ffffffffc0201882:	a091                	j	ffffffffc02018c6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201884:	03351463          	bne	a0,s3,ffffffffc02018ac <readline+0x7c>
ffffffffc0201888:	e8a9                	bnez	s1,ffffffffc02018da <readline+0xaa>
        c = getchar();
ffffffffc020188a:	8a1fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020188e:	fe0549e3          	bltz	a0,ffffffffc0201880 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201892:	fea959e3          	bge	s2,a0,ffffffffc0201884 <readline+0x54>
ffffffffc0201896:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201898:	e42a                	sd	a0,8(sp)
ffffffffc020189a:	84ffe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc020189e:	6522                	ld	a0,8(sp)
ffffffffc02018a0:	009b87b3          	add	a5,s7,s1
ffffffffc02018a4:	2485                	addiw	s1,s1,1
ffffffffc02018a6:	00a78023          	sb	a0,0(a5)
ffffffffc02018aa:	bf7d                	j	ffffffffc0201868 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02018ac:	01550463          	beq	a0,s5,ffffffffc02018b4 <readline+0x84>
ffffffffc02018b0:	fb651ce3          	bne	a0,s6,ffffffffc0201868 <readline+0x38>
            cputchar(c);
ffffffffc02018b4:	835fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02018b8:	00004517          	auipc	a0,0x4
ffffffffc02018bc:	77050513          	addi	a0,a0,1904 # ffffffffc0206028 <buf>
ffffffffc02018c0:	94aa                	add	s1,s1,a0
ffffffffc02018c2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02018c6:	60a6                	ld	ra,72(sp)
ffffffffc02018c8:	6486                	ld	s1,64(sp)
ffffffffc02018ca:	7962                	ld	s2,56(sp)
ffffffffc02018cc:	79c2                	ld	s3,48(sp)
ffffffffc02018ce:	7a22                	ld	s4,40(sp)
ffffffffc02018d0:	7a82                	ld	s5,32(sp)
ffffffffc02018d2:	6b62                	ld	s6,24(sp)
ffffffffc02018d4:	6bc2                	ld	s7,16(sp)
ffffffffc02018d6:	6161                	addi	sp,sp,80
ffffffffc02018d8:	8082                	ret
            cputchar(c);
ffffffffc02018da:	4521                	li	a0,8
ffffffffc02018dc:	80dfe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02018e0:	34fd                	addiw	s1,s1,-1
ffffffffc02018e2:	b759                	j	ffffffffc0201868 <readline+0x38>

ffffffffc02018e4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02018e4:	4781                	li	a5,0
ffffffffc02018e6:	00004717          	auipc	a4,0x4
ffffffffc02018ea:	72273703          	ld	a4,1826(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02018ee:	88ba                	mv	a7,a4
ffffffffc02018f0:	852a                	mv	a0,a0
ffffffffc02018f2:	85be                	mv	a1,a5
ffffffffc02018f4:	863e                	mv	a2,a5
ffffffffc02018f6:	00000073          	ecall
ffffffffc02018fa:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02018fc:	8082                	ret

ffffffffc02018fe <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02018fe:	4781                	li	a5,0
ffffffffc0201900:	00005717          	auipc	a4,0x5
ffffffffc0201904:	b6873703          	ld	a4,-1176(a4) # ffffffffc0206468 <SBI_SET_TIMER>
ffffffffc0201908:	88ba                	mv	a7,a4
ffffffffc020190a:	852a                	mv	a0,a0
ffffffffc020190c:	85be                	mv	a1,a5
ffffffffc020190e:	863e                	mv	a2,a5
ffffffffc0201910:	00000073          	ecall
ffffffffc0201914:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201916:	8082                	ret

ffffffffc0201918 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201918:	4501                	li	a0,0
ffffffffc020191a:	00004797          	auipc	a5,0x4
ffffffffc020191e:	6e67b783          	ld	a5,1766(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201922:	88be                	mv	a7,a5
ffffffffc0201924:	852a                	mv	a0,a0
ffffffffc0201926:	85aa                	mv	a1,a0
ffffffffc0201928:	862a                	mv	a2,a0
ffffffffc020192a:	00000073          	ecall
ffffffffc020192e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201930:	2501                	sext.w	a0,a0
ffffffffc0201932:	8082                	ret

ffffffffc0201934 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201934:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201936:	e589                	bnez	a1,ffffffffc0201940 <strnlen+0xc>
ffffffffc0201938:	a811                	j	ffffffffc020194c <strnlen+0x18>
        cnt ++;
ffffffffc020193a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020193c:	00f58863          	beq	a1,a5,ffffffffc020194c <strnlen+0x18>
ffffffffc0201940:	00f50733          	add	a4,a0,a5
ffffffffc0201944:	00074703          	lbu	a4,0(a4)
ffffffffc0201948:	fb6d                	bnez	a4,ffffffffc020193a <strnlen+0x6>
ffffffffc020194a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020194c:	852e                	mv	a0,a1
ffffffffc020194e:	8082                	ret

ffffffffc0201950 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201950:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201954:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201958:	cb89                	beqz	a5,ffffffffc020196a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020195a:	0505                	addi	a0,a0,1
ffffffffc020195c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020195e:	fee789e3          	beq	a5,a4,ffffffffc0201950 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201962:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201966:	9d19                	subw	a0,a0,a4
ffffffffc0201968:	8082                	ret
ffffffffc020196a:	4501                	li	a0,0
ffffffffc020196c:	bfed                	j	ffffffffc0201966 <strcmp+0x16>

ffffffffc020196e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020196e:	00054783          	lbu	a5,0(a0)
ffffffffc0201972:	c799                	beqz	a5,ffffffffc0201980 <strchr+0x12>
        if (*s == c) {
ffffffffc0201974:	00f58763          	beq	a1,a5,ffffffffc0201982 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201978:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020197c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020197e:	fbfd                	bnez	a5,ffffffffc0201974 <strchr+0x6>
    }
    return NULL;
ffffffffc0201980:	4501                	li	a0,0
}
ffffffffc0201982:	8082                	ret

ffffffffc0201984 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201984:	ca01                	beqz	a2,ffffffffc0201994 <memset+0x10>
ffffffffc0201986:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201988:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020198a:	0785                	addi	a5,a5,1
ffffffffc020198c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201990:	fec79de3          	bne	a5,a2,ffffffffc020198a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201994:	8082                	ret
