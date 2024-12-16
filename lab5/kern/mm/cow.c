#include <cow.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

// handle_cow_fault - handle the copy-on-write fault
int handle_cow_fault(struct mm_struct* mm, uintptr_t addr) {
    int ret = -E_NO_MEM;
    struct vma_struct* vma = find_vma(mm, addr);
    if (vma == NULL || vma->vm_start > addr) {
        return -E_INVAL;
    }

    pte_t* ptep = get_pte(mm->pgdir, addr, 0);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }

    if (!(*ptep & PTE_V) || !(*ptep & PTE_U)) {
        return -E_INVAL;
    }

    struct Page* page = pte2page(*ptep);
    if (page_ref(page) > 1) {
        struct Page* new_page = alloc_page();
        if (new_page == NULL) {
            return -E_NO_MEM;
        }

        void* src_kvaddr = page2kva(page);
        void* dst_kvaddr = page2kva(new_page);
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);

        page_ref_dec(page);
        ret = page_insert(mm->pgdir, new_page, addr, PTE_U | PTE_W | PTE_V);
        if (ret != 0) {
            free_page(new_page);
            return ret;
        }
    }
    else {
        *ptep |= PTE_W;
        tlb_invalidate(mm->pgdir, addr);
        ret = 0;
    }

    return ret;
}

static int
setup_pgdir(struct mm_struct* mm) {
    struct Page* page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t* pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

static void
put_pgdir(struct mm_struct* mm) {
    free_page(kva2page(mm->pgdir));
}

int
cow_copy_mm(struct proc_struct* proc) {
    struct mm_struct* mm, * oldmm = current->mm;

    /* current is a kernel thread */
    if (oldmm == NULL) {
        return 0;
    }
    int ret = 0;
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    lock_mm(oldmm);
    {
        ret = cow_copy_mmap(mm, oldmm);
    }
    unlock_mm(oldmm);

    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    mm_count_inc(mm);
    proc->mm = mm;
    proc->cr3 = PADDR(mm->pgdir);
    return 0;
bad_dup_cleanup_mmap:
    exit_mmap(mm);
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    return ret;
}

int
cow_copy_mmap(struct mm_struct* to, struct mm_struct* from) {
    assert(to != NULL && from != NULL);
    list_entry_t* list = &(from->mmap_list), * le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct* vma, * nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }
        insert_vma_struct(to, nvma);
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0;
}

int cow_copy_range(pde_t* to, pde_t* from, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    do {
        pte_t* ptep = get_pte(from, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep & PTE_V) {
            *ptep &= ~PTE_W;
            uint32_t perm = (*ptep & PTE_USER & ~PTE_W);
            struct Page* page = pte2page(*ptep);
            assert(page != NULL);
            int ret = 0;
            ret = page_insert(to, page, start, perm);
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}

int
cow_pgfault(struct mm_struct* mm, uint_t error_code, uintptr_t addr) {
    cprintf("COW page fault at 0x%x\n", addr);
    int ret = 0;
    pte_t* ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
    struct Page* page = pte2page(*ptep);
    struct Page* npage = alloc_page();
    assert(page != NULL);
    assert(npage != NULL);
    uintptr_t* src = page2kva(page);
    uintptr_t* dst = page2kva(npage);
    memcpy(dst, src, PGSIZE);
    uintptr_t start = ROUNDDOWN(addr, PGSIZE);
    *ptep = 0;
    ret = page_insert(mm->pgdir, npage, start, perm);
    ptep = get_pte(mm->pgdir, addr, 0);
    return ret;
}
