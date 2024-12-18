<h1><center>lab5实验报告</center></h1>

## 练习0：填写已有实验

本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行lab5的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。

### lab3改进`/kern/vmm.c`：

+ `do_pgfault`函数中原(1)/(2)要求：
  ```c
   swap_in(mm,addr,&page);
   page_insert(mm->pgdir,page,addr,perm);
  ```
+ 修改后：
  ```c
    //(1）According to the mm AND addr, try
    //to load the content of right disk page
    //into the memory which page managed.
    if (swap_in(mm, addr, &page) != 0) {
        cprintf("swap_in in do_pgfault failed\n");
        goto failed;
    }
    //(2) According to the mm,
    //addr AND page, setup the
    //map of phy addr <--->
    //logical addr
    if (page_insert(mm->pgdir, page, addr, perm) != 0) {
        cprintf("page_insert in do_pgfault failed\n");
        goto failed;
    }
  ```

### lab4改进`/kern/proc.c`：
+ `alloc_proc`函数中lab5新增初始化：
  ```c
  proc->wait_state = 0;
  proc->cptr = NULL; // Child Pointer 表示当前进程的子进程
  proc->optr = NULL; // Older Sibling Pointer 表示当前进程的上一个兄弟进程
  proc->yptr = NULL; // Younger Sibling Pointer 表示当前进程的下一个兄弟进程

  ```
+ `do_fork`函数修改为：
  ```c
   if((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    proc->parent = current;
    assert(current->wait_state == 0);
    if(setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    if(copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    // if(cow_copy_mm(proc) != 0) {
    //     goto bad_fork_cleanup_kstack;
    // }
    copy_thread(proc, stack, tf);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);
    wakeup_proc(proc);
    ret = proc->pid;

  ```


## 练习1: 加载应用程序并执行（需要编码）
`do_execv`函数调用`load_icode`（位于`kern/process/proc.c`中）来加载并解析一个处于内存中的`ELF`执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量`trapframe`中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的`trapframe`内容。

+ 请在实验报告中简要说明你的设计实现过程。
+ 请简要描述这个用户态进程被ucore选择占用CPU执行（`RUNNING`态）到具体执行应用程序第一条指令的整个经过。

+ 设计实现该过程：
  ```c
    tf->gpr.sp = USTACKTOP; //将 trapframe 结构体中的 sp（栈指针）寄存器设置为 USTACKTOP
    tf->epc = elf->e_entry; //将 trapframe 中的 epc（程序计数器）寄存器设置为 ELF 文件的入口地址
    // sstatus &= ~SSTATUS_SPP; 
    // sstatus &= SSTATUS_SPIE;
    // tf->status = sstatus;
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); //设置了 trapframe 中的 status 寄存器，具体地，它对 sstatus 寄存器应用了一个掩码操作，去除了 SSTATUS_SPP 和 SSTATUS_SPIE 标志

  ```
 + 设置栈指针（sp）： tf->gpr.sp = USTACKTOP; 指定了用户栈的顶部。
 + 设置程序计数器（epc）： tf->epc = elf->e_entry; 指定了程序执行的入口点，即 ELF 文件中的入口地址。
 + 设置状态寄存器（status）： tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); 确保进程从用户模式执行，并且不响应中断和异常。

+ 执行`RUNNING`态到具体执行应用程序第一条指令
   进程从被调度占用 CPU 执行到开始执行应用程序的第一条指令的整个过程包括：

 + 进程创建与初始化：包括分配内存、加载程序文件、设置 trapframe 和栈空间。
 + 进程进入 RUNNABLE 状态：进程准备好执行并可以被调度器选择。
 + 调度器选择进程并切换到 RUNNING 状态：通过 schedule 函数，调度器选择进程并执行上下文切换。
 + 恢复 trapframe：调度到进程时，恢复进程的寄存器状态，特别是程序计数器（epc）指向入口地址。
 + 进入用户态并执行应用程序：进程从用户程序的入口地址开始执行，完成从内核模式到用户模式的切换，开始执行用户程序的第一条指令。



## 练习2: 父进程复制自己的内存空间给子进程（需要编码）
创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于`kern/mm/pmm.c`中）实现的，请补充`copy_range`的实现，确保能够正确执行。

+请在实验报告中简要说明你的设计实现过程。

`Copy-on-write`（简称COW）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。

+ 补充`copy_range`
  ```c
    void *src_kvaddr = page2kva(page);
    void *dst_kvaddr = page2kva(npage);
    memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
    ret = page_insert(to, npage, start, perm);
  ```
为了确保 copy_range 函数能够正确地将父进程的内存内容复制到子进程，我们需要复制父进程（即源进程）的虚拟内存地址空间中的指定范围到子进程的内存空间。这一过程需要在页单位上进行，确保页表正确映射，并复制内存内容

+ 设计实现过程

1. 遍历父进程的页表
使用 `get_pte` 获取父进程页表中指定虚拟地址的页表项（PTE）。如果该地址没有对应的页表项，跳过该地址，继续处理下一个地址。确保从 `start` 到 `end` 范围内的所有页都被处理。

2. 复制父进程的页面内容到子进程
如果父进程的页表项有效（即 `PTE_V` 被设置），我们需要为子进程分配新的物理页面。然后，通过 `memcpy` 将父进程的物理页面内容复制到新分配的物理页面。

3. 在子进程的页表中建立映射
为子进程分配新的页表项，并将新分配的物理页面映射到子进程的虚拟地址空间中。



## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
请在实验报告中简要说明你对 `fork/exec/wait/exit`函数的分析。并回答如下问题：

请分析`fork/exec/wait/exit`的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
执行：`make grade`。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-1.0.1）

### 1. `fork` 系统调用

+ 用户态操作：进程调用 `fork()`。
+ 内核态操作：
  - 为子进程分配 `proc_struct` 和内核栈。
  - 复制父进程的内存（通过 `copy_mm`）。
  - 设置子进程的 `trapframe` 和上下文。
  - 将子进程状态设置为 `PROC_RUNNABLE`，加入调度队列。
- 返回用户态：父进程返回子进程的 PID，子进程返回 0。

+ 交替执行：
  - 用户态：`fork()` 进入内核态。
  - 内核态：创建子进程，设置内存，恢复上下文。
  - 用户态：父子进程继续各自执行。

### 2. `exec` 系统调用

- 用户态操作：进程调用 `exec()`，传递新程序的路径。
- 内核态操作：
  - 清理当前进程内存。
  - 调用 `load_icode()` 加载新程序，设置内存、栈、程序计数器（`epc`）。
  - 返回用户态，执行新程序。
- 返回用户态：程序从新加载的地址空间开始执行。

+ 交替执行：
  - 用户态：调用 `exec()`。
  - 内核态：加载新程序，设置 `trapframe`。
  - 用户态：新程序开始执行。

### 3. `wait` 系统调用

- 用户态操作：进程调用 `wait()` 等待子进程结束。
- 内核态操作：
  - 如果子进程处于 `PROC_ZOMBIE`，则清理进程。
  - 更新父进程的状态。
- 返回用户态：`wait()` 返回，父进程继续执行。

+ 交替执行：
  - 用户态：调用 `wait()`。
  - 内核态：等待子进程结束，清理资源。
  - 用户态：返回，继续执行。


### 4. `exit` 系统调用

- 用户态操作：进程调用 `exit()`，退出当前进程。
- 内核态操作：
  - 清理进程的内存资源。
  - 设置进程为 `PROC_ZOMBIE`，唤醒父进程。
  - 调用 `schedule()` 切换到其他进程。
- 返回用户态：进程终止，资源释放。

+ 交替执行：
- 用户态：调用 `exit()`。
- 内核态：清理资源，调度其他进程。
- 用户态：进程结束，控制权交给调度器。


### 5. 用户态进程执行状态生命周期图

```
  PROC_UNINIT -> PROC_RUNNABLE -> PROC_RUNNING -> PROC_ZOMBIE -> (Exit)
          ^                             |
          |                             v
     (Fork/Exec)                 (Wait/Exit)
```

- **`PROC_UNINIT`**: 进程未初始化，调用 `fork` 后进入。
- **`PROC_RUNNABLE`**: 进程准备好运行，等待调度。
- **`PROC_RUNNING`**: 进程执行中，用户程序执行。
- **`PROC_ZOMBIE`**: 进程已结束，等待父进程回收。

#### 变换事件：
- `fork()`：从 `PROC_UNINIT` 到 `PROC_RUNNABLE`。
- `exec()`：替换当前进程，设置新程序的状态。
- `wait()`：等待子进程结束，进入 `PROC_SLEEPING`。
- `exit()`：从 `PROC_RUNNING` 到 `PROC_ZOMBIE`。

![make grade](https://github.com/nkucss/os/blob/main/lab5/make_grade.png?raw=true "make grade")

## 扩展练习 Challenge
实现 `Copy on Write` （COW）机制

+ 给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过`page fault`异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

+ 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

**源码详见cow.c函数**

### 实现报告：Copy on Write (COW) 机制

#### 1. 设计与实现过程

COW（Copy on Write）机制用于优化内存管理，尤其在进程间共享内存时减少不必要的内存复制。其基本思想是当多个进程共享同一块内存页时，只有在其中一个进程修改该内存页时才会进行复制。具体到 `ucore` 操作系统中，父子进程在创建时共享内存，但在修改时会触发页错误，内核通过复制内存页来保证每个进程的内存独立性。

##### 1.1 COW机制的核心操作

1. 内存页共享与复制
   - 初始状态下，父子进程共享同一页内存。
   - 当其中一个进程尝试修改该页面时，操作系统通过页错误（page fault）触发 COW 机制，复制该页面，使得修改后的页面仅对当前进程可见。

2. 页面复制
   - 如果多个进程共享同一页面，当其中一个进程尝试写入时，会触发页错误。此时，内核会分配一个新的页面，将原页面的内容复制到新页面，并将进程的页面映射更新为新页面。

##### 1.2 关键函数

1. `handle_cow_fault`
   - 该函数处理 COW 页面故障，检测到写入操作时，会复制内存页面并更新页表。

   ```c
   int handle_cow_fault(struct mm_struct* mm, uintptr_t addr) {
       // 查找内存区段，并判断当前页是否是共享页
       struct vma_struct* vma = find_vma(mm, addr);
       if (!vma || vma->vm_start > addr) return -E_INVAL;

       pte_t* ptep = get_pte(mm->pgdir, addr, 0);
       if (!ptep) return -E_NO_MEM;

       struct Page* page = pte2page(*ptep);
       if (page_ref(page) > 1) {
           // 如果页面被多个进程共享，进行页面复制
           struct Page* new_page = alloc_page();
           if (!new_page) return -E_NO_MEM;
           memcpy(page2kva(new_page), page2kva(page), PGSIZE);
           page_ref_dec(page);
           return page_insert(mm->pgdir, new_page, addr, PTE_U | PTE_W | PTE_V);
       } else {
           // 只有一个进程持有该页，直接设置为可写
           *ptep |= PTE_W;
           tlb_invalidate(mm->pgdir, addr);
       }
       return 0;
   }
   ```

2. `cow_copy_mm`
   - 该函数用于在 `fork` 过程中，复制父进程的内存映射信息，并为子进程创建 COW 页。

   ```c
   int cow_copy_mm(struct proc_struct* proc) {
       struct mm_struct* mm, * oldmm = current->mm;
       if (!oldmm) return 0;

       int ret = 0;
       if ((mm = mm_create()) == NULL) goto bad_mm;
       if (setup_pgdir(mm) != 0) goto bad_pgdir_cleanup_mm;

       lock_mm(oldmm);
       ret = cow_copy_mmap(mm, oldmm);
       unlock_mm(oldmm);

       if (ret != 0) goto bad_dup_cleanup_mmap;
       mm_count_inc(mm);
       proc->mm = mm;
       proc->cr3 = PADDR(mm->pgdir);
       return 0;
   }
   ```

3. `cow_pgfault`
   - 该函数用于处理进程在执行时遇到的 COW 页面故障，复制页面并更新页表。

   ```c
   int cow_pgfault(struct mm_struct* mm, uint_t error_code, uintptr_t addr) {
       cprintf("COW page fault at 0x%x\n", addr);
       pte_t* ptep = get_pte(mm->pgdir, addr, 0);
       uint32_t perm = (*ptep & PTE_USER) | PTE_W;
       struct Page* page = pte2page(*ptep);
       struct Page* npage = alloc_page();
       assert(page != NULL);
       assert(npage != NULL);
       memcpy(page2kva(npage), page2kva(page), PGSIZE);
       uintptr_t start = ROUNDDOWN(addr, PGSIZE);
       *ptep = 0;
       return page_insert(mm->pgdir, npage, start, perm);
   }
   ```

##### 1.3 COW机制的状态转换

COW机制通过以下几种状态转换来管理内存页：

1. 共享内存（Copy on Write）
   - 当父进程和子进程共享同一内存页时，这些页面处于只读模式，多个进程共享同一物理页。
   - 页面映射的权限为只读，且不允许写入。

2. 页面故障触发复制
   - 当一个进程尝试写入一个共享的页面时，会触发页错误（page fault）。此时，内核通过 COW 机制将该页复制到新的物理页面，并更新该进程的页表，使得该进程拥有自己的独立副本。

3. 页面修改后的独立存在
   - 复制完成后，修改后的页面只对当前进程可见，其他进程继续共享原页面。

### 2. 测试用例

以下是 COW 机制的测试用例，用于验证 COW 是否正确工作：

```c
void test_cow() {
    int pid = fork();
    if (pid == 0) {
        // 子进程修改共享内存
        printf("Child: Writing to shared page\n");
        shared_var[0] = 42;
        exit(0);
    } else {
        // 父进程检查共享内存是否被修改
        printf("Parent: Reading shared page\n");
        printf("Shared variable: %d\n", shared_var[0]);
        wait(NULL);
    }
}
```

测试步骤：
1. 父进程创建子进程并共享内存。
2. 子进程修改共享内存，父进程读取并验证是否被修改。
3. 验证父子进程内存的独立性，检查子进程对内存的修改是否影响父进程。

### 3.  总结与实现区别

#### 3.1 COW与传统内存分配的区别

传统的内存分配方式中，父子进程在 `fork` 后会复制整个地址空间，即使有些内存内容是没有被修改的。而 COW 机制通过延迟复制，只有在需要写入时才进行复制，从而减少了不必要的内存复制，提高了系统的效率。

#### 3.2 加载方式

在 `ucore` 中，用户程序的加载过程与常见操作系统类似：通过 `execve` 系统调用将 ELF 格式的程序加载到内存。

#### 3.3 区别
不同之处在于，`fork` 系统调用创建的子进程在初始时会共享父进程的内存，只有在修改内存时才会通过 COW 机制触发页复制。

