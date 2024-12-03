<h1><center>lab4实验报告</center></h1>

## 练习1：分配并初始化一个进程控制块（需要编码）
`alloc_proc`函数（位于`kern/process/proc.c`中）负责分配并返回一个新的`struct proc_struct`结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

+ 【提示】在`alloc_proc`函数的实现中，需要初始化的`proc_struct`结构中的成员变量至少包括：`state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name`。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

+ 请说明`proc_struct`中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是什么？（提示通过看代码和编程调试可以判断出来）

### 代码实现
除手册中提及的必须设置特殊值的变量和指针外，其他都设置为该指针/变量的空值

```c
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        // 初始化各个字段
        proc->state = PROC_UNINIT;   // 进程的初始状态是未初始化
        proc->pid = -1;              // 进程的初始pid为-1
        proc->runs = 0;              // 初始运行次数为0
        proc->kstack = 0;            // 内核栈的初始值是0，后续在setup_kstack中分配
        proc->need_resched = 0;      // 初始时不需要重新调度
        proc->parent = NULL;         // 父进程指针为NULL
        proc->mm = NULL;             // 进程的内存管理结构初始化为NULL
        memset(&proc->context, 0, sizeof(proc->context)); // 进程上下文初始化为0
        proc->tf = NULL;             // 当前进程的trapframe初始化为NULL
        proc->cr3 = boot_cr3;               // 使用内核页目录的基址为boot_cr3
        proc->flags = 0;             // 初始标志位为0
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 进程名称初始化为空字符串
    }
    return proc;
}
```


### 成员变量含义和在本实验中的作用
+ `struct context context`
`context` 是一个结构体，它保存了与进程执行相关的 CPU 寄存器状态。
上下文切换是操作系统中多任务调度的核心部分，操作系统会在不同的进程间进行切换，以便多个进程可以共享 CPU 资源。因此`context`用于进程上下文切换时保存当前进程的状态，以便在之后恢复该进程时，能够恢复到切换前的状态。`context`包含了所有 CPU 寄存器的内容，进程切换时需要被保存和恢复。通常，`context` 结构体会包含程序计数器（PC）、栈指针（SP）等寄存器，这些都是恢复进程执行所必需的。

在本实验中，`context` 主要用于：

- **保存进程的寄存器状态**：在上下文切换时，当前进程的寄存器状态会被保存下来。
- **恢复进程的寄存器状态**：当调度器恢复一个进程时，会根据 `context` 中保存的寄存器值恢复 CPU 状态，从而继续执行该进程。

+ `struct trapframe *tf`
`trapframe` 主要用于保存中断/异常处理时的寄存器状态，尤其是在进程发生上下文切换时。此处`tf` 是一个指向 `trapframe` 结构体的指针。它保存了在进入中断处理程序或系统调用时的所有寄存器值，包括程序计数器（pc）、栈指针（sp）、以及其他与异常处理相关的信息。

在进入内核态处理系统调用或中断时，系统会将当前寄存器的状态保存在 `trapframe` 中，以便在处理中断或返回用户态时恢复寄存器。

在本实验中，`tf` 的作用包括：

- **保存中断/系统调用的寄存器状态**：当进程从用户态进入内核态处理系统调用或中断时，操作系统会将当前进程的寄存器保存在 tf 中。
- **恢复进程状态**：在完成系统调用或中断后，操作系统会根据 `tf` 中保存的寄存器状态恢复进程，确保进程能够从中断前的状态继续执行。


## 练习2：为新创建的内核线程分配资源（需要编码）
创建一个内核线程需要分配和设置好很多资源。`kernel_thread`函数通过调用`do_fork`函数完成具体内核线程的创建工作。`do_kernel`函数会调用`alloc_proc`函数来分配并初始化一个进程控制块，但`alloc_proc`只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过`do_fork`实际创建新的内核线程。`do_fork`的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是`stack`和`trapframe`。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在`kern/process/proc.c`中的`do_fork`函数中的处理过程。它的大致执行步骤包括：

+ 调用`alloc_proc`，首先获得一块用户信息块。
+ 为进程分配一个内核栈。
+ 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
+ 复制原进程上下文到新进程
+ 将新进程添加到进程列表
+ 唤醒新进程
+ 返回新进程号
+ 请在实验报告中简要说明你的设计实现过程。

请回答如下问题：

+ 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

### 代码实现
```c
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;

    //Start here

    // 分配 proc_struct
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    // 设置内核栈
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    // 复制或共享地址空间
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    // 复制线程上下文
    copy_thread(proc, stack, tf);
    // 获取唯一的 pid
    proc->pid = get_pid();
    // 插入哈希表和进程列表
    hash_proc(proc);
    list_add(&proc_list, &proc->list_link);
    nr_process++;
    // 唤醒新进程
    wakeup_proc(proc);
    // 返回子进程的 pid
    ret = proc->pid;

    //End here

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```
我们编写的代码的实现流程：
+ 分配新进程的资源：通过 `alloc_proc` 和 `setup_kstack` 分别分配进程控制块和内核栈。
+ 复制内存管理信息和线程上下文：根据 `clone_flags` 复制或共享内存管理信息，然后通过 `copy_thread` 复制当前进程的线程上下文。
+ 管理进程：新进程加入到进程哈希表和进程链表中，更新进程数，并通过 `wakeup_proc` 唤醒新进程，使其变为可运行状态。
+ 错误处理：如果在任何一步出错，确保清理已经分配的资源，避免内存泄漏。

### ucore做到了给每个新fork的线程一个唯一的id

+ 分析和理由：

从我们编写的函数中我们确实发现：uCore 使用 `get_pid` 函数为每个新线程分配唯一的 `PID`：
get_pid函数对上一个进程的ID进行递增，通过链表proc_list和最大值 MAX_PID的限制，防止与之前的ID冲突，以及超过最大值就归1.
所以实现了唯一的分配。




## 练习3：编写proc_run 函数（需要编码）
`proc_run`用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

+ 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
+ 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
+ 切换当前进程为要运行的进程。
+ 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
+ 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
+ 允许中断。
请回答如下问题：

+ 在本实验的执行过程中，创建且运行了几个内核线程？
完成代码编写后，编译并运行代码：`make qemu`

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。


### 代码实现
```c
// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // 关闭中断
        bool intr_flag;
        local_intr_save(intr_flag);
        // 切换到新进程的页表
        lcr3(proc->cr3);
        // 保存当前进程的上下文
        struct proc_struct *prev = current;
        current = proc;
        // 进行上下文切换
        switch_to(&(prev->context), &(proc->context));
        // 恢复中断
        local_intr_restore(intr_flag);
    }
}
```
proc_run 函数实现了以下关键操作：
+ 检查目标进程：只有当目标进程不是当前进程时，才执行切换。
+ 禁用中断：切换进程时禁用中断，保证操作的原子性。
+ 切换页表：切换到目标进程的页表，确保目标进程访问自己的内存空间。
+ 上下文切换：保存当前进程的上下文并恢复目标进程的上下文，实现进程的切换。
+ 恢复中断：恢复中断状态，确保新进程能够正常响应中断。

在这段代码中，proc 是目标进程，current 是当前进程，prev 是保存当前进程的指针，intr_flag 是保存中断状态的变量，proc->cr3 是目标进程的页表基地址，prev->context 和 proc->context 是保存当前进程和目标进程上下文信息的数据结构。这些变量在上下文切换过程中，配合进程调度确保了正确的进程切换和状态恢复。


### 在本实验的执行过程中，创建且运行了2个内核线程
+ 第0个内核线程`idleproc`
+ 第1个内核线程`initproc`

### make qemu 与make grade:
![make qemu](https://github.com/nkucss/os/blob/main/lab4/make_qemu.png?raw=true "make qemu")
![make grade](https://github.com/nkucss/os/blob/main/lab4/make_grade.png?raw=true "make grade")

## 扩展练习 Challenge：
+ 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag)`;是如何实现开关中断的？

1. local_intr_save(intr_flag);(关)
local_intr_save(intr_flag) 是一个宏或函数（具体实现依赖于操作系统的底层架构）。它的作用是：
保存当前的中断状态：将当前 CPU 中断是否启用的信息保存到 intr_flag 变量中。这通常是通过读取 CPU 状态寄存器来实现的，具体来说，保存的是中断标志位的值。
禁用中断：在保存当前中断状态后，local_intr_save 会设置 CPU 的中断标志，禁用中断，防止中断在进程切换过程中发生。禁用中断通常通过清除 CPU 中的中断使能位来实现。

2. lcr3(proc->cr3);
这行代码将当前进程的页表（通过 proc->cr3 存储的页表基址）加载到 CPU 中，切换到目标进程的地址空间。
这步操作和中断的禁用直接无关，但它会影响接下来的内存访问，因此必须保证这时中断已经禁用，以避免在页表切换时发生中断。

3. struct proc_struct *prev = current;
这一行将当前进程的指针保存到 prev 中，保存当前进程上下文。后续将使用 prev 进行上下文切换。

4. current = proc;
这行代码将当前进程更新为目标进程（proc）。接下来的上下文切换将从当前进程切换到目标进程。

5. switch_to(&(prev->context), &(proc->context));
这一行实现了真正的上下文切换，即将当前进程的上下文保存到 prev->context，并将目标进程的上下文恢复到 proc->context。上下文切换后，执行权交给目标进程。

6. local_intr_restore(intr_flag);(开)
这一语句恢复了之前保存的中断状态。


## 关键知识点


+ `kstack`：每个线程都有一个内核栈，运行程序使用的栈

  + 切换进程时，需要根据 `kstack `的值正确的设置好` tss`，以便发生中断使用正确的栈
  + 内核栈位于内核地址空间，并且是不共享的
  + 在内存栈里为中断帧分配空间

+ `idleproc`是第0个要创建的线程，表示空闲线程，空闲进程是一个特殊的进程，它的主要目的是在系统没有其他任务需要执行时，占用 CPU 时间，同时便于进程调度的统一化
  `kern_init` 函数调用了` proc.c::proc_init `函数，`proc_init `函数启动了创建内核线程的步骤，在这里面有创建`idleproc`的过程：

  + 初始化进程控制块链表
  + 调用` alloc_proc `函数来通过 `kmalloc `函数获得` proc_struct` 结构的一块内存块，对进程控制块进行初步初始化
  + 进行进一步初始化，其中`idleproc->need_resched = 1`，因为这个线程是一个空闲线程，所以不执行他，调用 schedule 函数要求调度器切换其他进程执行


+ `do_fork`的功能：

  + 分配线程控制块
  + 分配并初始化内核栈
  + 根据` clone_flags `决定是复制还是共享内存管理系统
  + 设置中断帧和上下文
  + 讲进程加入线程
  + 将新建的进程设为就绪态
  + 将返回值设为线程 id

+ 调度过程：

  + 设置当前内核线程 `current->need_resched` 为 0
  + 在` proc_list `队列中查找下一个处于“就绪”态的线程或进程
  + 找到后，调用` proc_run `函数，将指定的进程切换到 CPU 上运行，使用 switch_to 进行上下文切换

