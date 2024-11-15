<h1><center>lab3实验报告</center></h1>

## 练习一:理解基于FIFO的页面替换算法（思考题）

描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

### 目标与背景

本实验的目标是深入理解操作系统中的页面换入和换出机制，特别是在虚拟内存管理中的 `swap_in` 和 `swap_out` 函数的实现。页面的换入和换出在内存不足时非常重要，通过合理的管理可以提高内存使用效率，避免系统崩溃。

+ `swap_in`：用于将页面从磁盘加载到内存中。其基本流程包括：

  - 首先调用 `alloc_page` 函数为页面分配内存。如果没有足够的内存，系统将调用 `swap_out` 将当前内存中的某些页面换出。
  - 通过 `get_pte` 获取或构建页表项。页表项记录了虚拟地址到物理地址的映射关系。
  - 调用 `swapfs_read` 将页面数据从磁盘加载到内存中。

+ `swap_out`：用于将当前内存中的页面换出到磁盘。其流程如下：

  - `sm->swap_out_victim`被调用，找到需要被换出的页面。
  - 使用`get_pte` 获取页表项，并检查页面是否需要写回磁盘。如果页面被修改过，调用 `swapfs_write` 将页面写回磁盘。
  - 使用 `tlb_invalidate` 刷新 TLB 缓存。

### 关键函数分析：

+ `swap_in`：用于换入页面。首先调用`pmm.c`中的`alloc_page`，申请一块连续的内存空间，然后调用`get_pte`找到或者构建对应的页表项，最后调用`swapfs_read`将数据从磁盘写入内存。

+ `alloc_page`：用于申请页面。通过调用`pmm_manager->alloc_pages`申请一块连继续的内存空间，在这个过程中，如果申请页面失败，那么说明需要换出页面，则调用`swap_out`换出页面，之后再次进行申请。

+ `assert(result!=NULL)`：判断获得的页面是否为`NULL`，只有页面不为`NULL`才能继续。

+ `swap_out`：用于换出页面。首先需要循环调用`sm->swap_out_victim`，对应于`swap_fifo`中的`_fifo_swap_out_victim`。然后调用`get_pte`获取对应的页表项，将该页面写入磁盘，如果写入成功，释放该页面；如果写入失败，调用`_fifo_map_swappable`更新FIFO队列。最后刷新TLB。

+ `free_page`：用于释放页面。通过调用`pmm_manager->free_pages`释放页面。

+ `assert((*ptep & PTE_V) != 0);`：用于判断获得的页表项是否合法。由于这里需要交换出去页面，所以获得的页表项必须是合法的。

+ `swapfs_write`：用于将页面写入磁盘。在这里由于需要换出页面，而页面内容如果被修改过那么就与磁盘中的不一致，所以需要将其重新写回磁盘。

+ `tlb_invalidate`：用于刷新TLB。通过调用`flush_tlb`刷新TLB。

+ `get_pte`：用于获得页表项。

+ `swapfs_read`：用于从磁盘读入数据。

+ `_fifo_swap_out_victim`：用于获得需要换出的页面。查找队尾的页面，作为需要释放的页面。

+ `_fifo_map_swappable`：将最近使用的页面添加到队头。在`swap_out`中调用是用于将队尾的页面移动到队头，防止下一次换出失败。


`swap_in` 和 `swap_out` 的主要区别在于数据的流向：`swap_in` 是从磁盘到内存，而 `swap_out` 是从内存到磁盘。
通过 `swap_fifo` 管理 FIFO 页面队列，优化页面替换算法。

当需要换入页面时，需要调用`swap.c`文件中的`swap_in`。

该页面移动到了链表的末尾时，在下一次有页面换入的时候需要被换出。当需要换出页面时，需要调用`swap.c`文件中的`swap_out`。

## 练习二:深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
 - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

+ **如此相似的原因**：两者都旨在获取虚拟地址对应的页表项，并在需要时创建新的page以及页表项。第一段代码用于从`GiGa Page`中查找`PDX1`的地址，如果查得的地址不合法则为该页表项分配内存空间；第二段代码用于从`MeGa Page`中查找`PDX0`的地址，如果查得的地址不合法则为该页表项分配内存空间。两次查找的逻辑相同，不同的只有查找的基地址与页表偏移量所在位数。而三种页表管理机制只是虚拟页表的地址长度或页表的级数不同，规定好偏移量即可按照同一规则找出对应的页表项。

+ **这种合并好**。

通过合并页表项查找和页表创建过程，减少了重复的代码和函数调用，使得系统更加高效。优化后的代码简化了页表项的处理流程，也减少了内存访问次数。

## 练习三:给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
 - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？


+ **设计与实现过程**：

  - `swap_in(mm, addr, &page)`：根据页表地址和虚拟地址，将磁盘中的数据加载到内存中，并返回物理页。
  - `page_insert(mm->pgdir, page, addr, perm)`：将虚拟地址与物理页面映射起来。
  - `swap_map_swappable(mm, addr, page, 0)`：将页面标记为可交换页面。


+ **潜在用处**：页目录项和页表项中的合法位可以用来判断该页面是否存在，还有一些其他的权限位，比如可读可写，可以用于CLOCK算法或LRU算法。修改位可以决定在换出页面时是否需要写回磁盘。

+ **页访问异常**：trap--> trap_dispatch-->pgfault_handler-->do_pgfault

  简单来说：当发生缺页异常时，trap 函数将触发 pgfault_handler，并通过 do_pgfault 处理缺页错误。如果缺页处理成功，系统将继续执行。

  + 首先保存当前异常原因，根据`stvec`的地址跳转到中断处理程序，即`trap.c`文件中的`trap`函数。
  + 接着跳转到`exception_handler`中的`CAUSE_LOAD_ACCESS`处理缺页异常。
  + 然后跳转到`pgfault_handler`，再到`do_pgfault`具体处理缺页异常。
  + 如果处理成功，则返回到发生异常处继续执行。
  + 否则输出`unhandled page fault`。

 FIFO算法的make qemu 和 make grade 如下：

![make qemu](https://github.com/nkucss/os/blob/main/lab3/F_1.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/F_2.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/F_3.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/F_4.png?raw=true "make qemu")


+ **与页表项的对应关系**：

  页表项映射到物理地址，进而找到对应的 `Page` 结构体。通过页表项中的物理地址信息，可以查找对应的物理页面，实现页面替换。

  如果页表项映射到了物理地址，那么这个地址对应的就是`Page`中的一项。`Page` 结构体数组的每一项代表一个物理页面，并且可以通过页表项间接关联。页表项存储物理地址信息，这可以用来索引到对应的 `Page` 结构体，从而允许操作系统管理和跟踪物理内存的使用。

## 练习四:补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

- **设计实现过程**：

  + 初始化需要初始化链表、当前节点指针和`mm`的成员`sm_priv`指针：

    ```c
    list_init(&pra_list_head);
    curr_ptr = &pra_list_head;
    mm->sm_priv = &pra_list_head;
    ```

  + 设置页面可交换，表示当前页面正要被使用，需要将其添加到链表尾部并设置`visited`：

    ```c
    list_add_before((list_entry_t*) mm->sm_priv,entry);
    page->visited = 1;
    ```

  + 遍历链表，如果下一个指针是`head`，则将其指向为下一个指针。如果依然是`head`，说明该链表为空，返回`NULL`，否则构造页面，判断是否最近被使用过，如果没有则重置`visited`，直到找到一个`visited = 0`的页面为止。

    ```c
    curr_ptr = list_next(curr_ptr);
    if(curr_ptr == head) {
        curr_ptr = list_next(curr_ptr);
        if(curr_ptr == head) {
            *ptr_page = NULL;
            break;
        }
    }
    struct Page* page = le2page(curr_ptr, pra_page_link);
    if(!page->visited) {
        *ptr_page = page;
        list_del(curr_ptr);
        cprintf("curr_ptr %p\n",curr_ptr);
        //curr_ptr = head;
        break;
    } else {
        page->visited = 0;
    }
    ```

- **不同：**

  + Clock算法：每次添加新页面时会将页面添加到链表尾部。每次换出页面时都会遍历查找最近没有使用的页面。

  + FIFO算法：将链表看成队列，每次添加新页面会将页面添加到链表头部（队列尾部）。每次换出页面时不管队头的页面最近是否访问，均将其换出。

  Clock算法的make qemu 和 make grade 如下：

![make qemu](https://github.com/nkucss/os/blob/main/lab3/Clock_1.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/Clock_2.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/Clock_3.png?raw=true "make qemu")

![make grade](https://github.com/nkucss/os/blob/main/lab3/grade.png?raw=true "make grade")

## 练习五:阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

#优势与劣势：

+ **大页的优势**：

  - 较少的内存访问次数，能映射更多的连续内存。
  - 减少 TLB 缺失，简化操作系统页表管理。

+ **大页的劣势**：

  - 页表项需要连续，占用较多内存。
  - 使用大页可能导致内部碎片，浪费内存。
  - 不适用于内存较小的系统。
  - 需要经常维护

## 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

### 设计思路

在LRU（最少最近使用）页面交换算法中，新加入的页面或刚访问过的页面会被插入到链表的头部。这样，当需要进行页面替换时，只需移除链表尾部的页面。

为了追踪访问过的页面，可以将所有页面的权限初始设置为不可读。当某个页面被访问时，会触发缺页异常。此时，系统将会把所有页面的页表项权限设置为不可读，随后将访问的页面移至链表头部，并将该页面的权限设置为可读。

### 代码实现

在`do_pgfault`中添加如下代码：

```c
pte_t* temp = NULL;
temp = get_pte(mm->pgdir, addr, 0);
if(temp != NULL && (*temp & (PTE_V | PTE_R))) {
    return lru_pgfault(mm, error_code, addr);
}
```

在为`perm`设置完权限之后，移除读权限：

```c
perm &= ~PTE_R;
```

`lru`的异常处理部分：

```c
int lru_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("lru page fault at 0x%x\n", addr);
    // 设置所有页面不可读
    if(swap_init_ok) 
        unable_page_read(mm);
    // 将需要获得的页面设置为可读
    pte_t* ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
    *ptep |= PTE_R;
    if(!swap_init_ok) 
        return 0;
    struct Page* page = pte2page(*ptep);
    // 将该页放在链表头部
    list_entry_t *head=(list_entry_t*) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head)
    {
        struct Page* curr = le2page(le, pra_page_link);
        if(page == curr) {
            
            list_del(le);
            list_add(head, le);
            break;
        }
    }
    return 0;
}
```

设置所有页面不可读，原理是遍历链表，转换为`page`，根据`pra_vaddr`获得页表项，设置不可读：

```c
static int
unable_page_read(struct mm_struct *mm) {
    list_entry_t *head=(list_entry_t*) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        pte_t* ptep = NULL;
        ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        *ptep &= ~PTE_R;
    }
    return 0;
}
```

其余部分与`FIFO`算法差异不大，罗列如下：

```c
static int
_lru_init_mm(struct mm_struct *mm)
{     

    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    list_add((list_entry_t*) mm->sm_priv,entry);
    return 0;
}
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```

### 测试

设计额外的测试如下：

```c
static void
print_mm_list() {
    cprintf("--------begin----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: %x\n", page->pra_vaddr);
    }
    cprintf("---------end-----------\n");
}
static int
_lru_check_swap(void) {
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    return 0;
}
```

与测试有关的测试结果如下：

![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_1.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_2.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_3.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_4.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_5.png?raw=true "make qemu")
![make qemu](https://github.com/nkucss/os/blob/main/lab3/LRU_6.png?raw=true "make qemu")

可以看到每次访问页面时都会产生缺页异常，将该页面添加到链表头部，需要移除页面时都从链表尾部删除页面。

## 知识点补充

+ 虚拟内存管理
  + 虚拟内存是程序访问的地址，不一定与物理地址一一对应。通过页表项限定访问空间，实现内存访问保护。
  + 按需分页：不常用数据放入磁盘，按需加载。
  + 页面映射：page_insert 和 page_remove 用于建立或删除虚拟到物理内存的映射。

+ 实验初始化流程

init 为总控函数，执行以下初始化：
  + 物理内存管理：pmm_init
  + 中断/异常处理：pic_init, idi_init
  + 虚拟内存管理：vmm_init
  + 页面置换和磁盘初始化：swap_init

+ 硬盘模拟
  + QEMU模拟器不支持模拟硬盘，通过将内存一小块作为硬盘实现页面换入换出。

+ 程序段
  + text：可读、可执行、不可写。
  + rodata：只读、不可写、不可执行。
  + data：可读、可写（初始化数据）。
  + bss：可读、可写（零初始化数据）。

+ 页面置换算法
  + FIFO：先进先出，适用于顺序访问，但可能出现Belady 现象。
  + LRU：最近未使用。
  + Clock：环形链表与访问位组合，淘汰未访问的页。
  + 改进的时钟算法：增加引用位和修改位，提高效率。
