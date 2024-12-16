#ifndef __KERN_MM_COW_H__
#define __KERN_MM_COW_H__

#include <defs.h>
#include <mmu.h>
#include <vmm.h>

int handle_cow_fault(struct mm_struct *mm, uintptr_t addr);

#endif /* !__KERN_MM_COW_H__ */
