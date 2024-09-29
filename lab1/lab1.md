<h1><center>lab1实验报告</center></h1>

# 一、实验目的

操作系统是计算机系统的监管者，必须能对计算机系统状态的突发变化做出反应，这些系统状态可能是程序执行出现异常，或者是突发的外设请求。当计算机系统遇到突发情况时，不得不停止当前的正常工作，应急响应一下，这是需要操作系统来接管，并跳转到对应处理函数进行处理，处理结束后再回到原来的地方继续执行指令。这个过程就是中断处理过程。

# 二、实验内容

## 练习1：阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

1. `la sp,bootstacktop`：
`sp`是堆栈指针寄存器,`bootstacktop`是指向`bootstack`(引导堆栈)堆栈顶部的，我们把堆栈顶地址加载到sp中，是为了让CPU定位堆栈，从而进行访问、调用、存储等等。

2. `tail kern_init`：
`tail`是“尾调用优化”的跳转指令，相当于无条件跳转，直接跳转到kern_init函数的地址，进行内核初始化，并结束了上面kern_entry的进程，不再返回到这个函数。

## 练习2：请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。


完善代码：

```c
clock_set_next_event();
ticks++;
if(ticks == TICK_NUM)//已定义TICK_NUM为100
{
    print_ticks();
    ticks = 0;
    num++;
}
if(num == 10)
{
    sbi_shutdown();
}
```

+ 代码逻辑：
先调用 clock_set_next_event 函数，设置下次的中断时间。接着将 ticks 加 1，直到 ticks 等于 100 时，调用 print_ticks 打印 "100 ticks"，并将 ticks 重置为 0，然后将 num 加 1。直到 num 达到 10，则调用 sbi_shutdown 函数执行关机操作。

## 扩展练习1：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

1. 处理中断异常流程：

   + CPU检测到异常/中断后，会跳转到内核的异常处理程序，进入寄存器`stvec`中的异常向量`__alltraps`(`trapentry.S`)
   + 进入`__alltraps`，`SAVE_ALL`保存所有寄存器到当前内核栈，然后执行`mov a0,sp`将堆栈指针`sp`的值保存到`a0`中
   + 跳转到`trap`函数，调用`trap_dispatch`函数，根据异常类型进行处理，分别跳转到对应的处理函数`interrupt_handler`或`expection_handler`处根据`cause`的值执行相应的处理程序
   + `RESTORE_ALL`恢复保存的所有寄存器

2. `mov a0,sp`的目的：

   堆栈指针 `sp` 保存了上下文信息。把`sp`的值传递给 `a0`，为了方便后续的`trap`函数获取异常时的状态

3. 寄存器保存的位置：
   
   由结构体`trapframe`和`pushregs`中的定义顺序决定，这些寄存器作为函数`trap`的参数。

4. 需要保存所有的寄存器。

   为了防止数据丢失以及便于恢复原始状态。保存所有的寄存器能够防止所有寄存器的值被修改。
   （不过不严重的中断，可以只保存有可能被修改的寄存器）

## 扩展练习2：在trapentry.S中汇编代码 `csrw sscratch, sp`；`csrrw s0, sscratch, x0`实现了什么操作，目的是什么？`save all`里面保存了`stval scause`这些csr，而在`restore all`里面却不还原它们？那这样store的意义何在呢？

1. + `csrw sscratch, sp`：把堆栈指针寄存器`sp`的值赋值给监督寄存器`sscratch`
   + `csrrw s0, sscratch, x0`：将`sscratch`赋值给`s0`，然后把`sscratch`的值改为0

从 sscratch 中读取之前存储的堆栈sp 值，并将其加载到寄存器 s0 中，同时将常量 x0（0） 写入 sscratch。因为为了之后能继续使用堆栈信息，所以将保存的 sp 值恢复到一般寄存器s0。



2. + `stval`是引发异常的地址或数据
   + `scause`是异常的原因

在`save all`中保存，是为了处理异常时恢复上下文。处理异常时，内核或异常处理代码会根据 scause 的值（异常原因）选择不同的恢复机制（0：异常/1：终中断），根据stval 提供的精确的地址或数据，定位异常所在的位置。这些有助于恢复上下文。

但是如果处理完了异常，这些寄存器的数据值已经使用过了，不再需要了，所以就不需要恢复了。

## 扩展练习3：编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”

编程完善：

1.kern/trap/trap.c

```c
case CAUSE_ILLEGAL_INSTRUCTION:
     // 非法指令异常处理
     /* LAB1 CHALLENGE3   YOUR CODE :  */
    /*(1)输出指令异常类型（ Illegal instruction）
     *(2)输出异常指令地址
     *(3)更新 tf->epc寄存器
    */
    cprintf("Exception type:Illegal instruction\n");
    cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
    tf->epc += 4;  // 跳过当前的4字节非法指令
    break;

case CAUSE_BREAKPOINT:
    //断点异常处理
    /* LAB1 CHALLLENGE3   YOUR CODE :  */
    /*(1)输出指令异常类型（ breakpoint）
     *(2)输出异常指令地址
     *(3)更新 tf->epc寄存器
    */
    cprintf("Exception type: breakpoint\n");
    cprintf("ebreak caught at 0x%08x\n", tf->epc);
    tf->epc += 2;  // 跳过2字节断点指令
    break;
```

2.kern/init/init.c:

`kern_init`函数--`intr_enable();`添加：

```c
asm("mret");
asm("ebreak");
```

运行结果：

```shell
Special kernel symbols:
  entry  0x000000008020000a (virtual)
  etext  0x0000000080200a28 (virtual)
  edata  0x0000000080204010 (virtual)
  end    0x0000000080204028 (virtual)
Kernel executable memory footprint: 17KB
++ setup timer interrupts
sbi_emulate_csr_read: hartid0: invalid csr_num=0x302
Exception type:Illegal instruction 
 Illegal instruction caught at 0x8020004e
Exception type:breakpoint 
 ebreak caught at 0x80200052
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks

```


## 运行结果

+ 输入命令`make grade`：

![成绩：100/100](https://github.com/nkucss/os/blob/main/lab1/1.png?raw=true)
