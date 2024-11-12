#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

extern list_entry_t pra_list_head;

static int
_lru_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);
    list_add((list_entry_t*) mm->sm_priv, entry);
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);

    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}

static void
print_page_info(struct Page *page) {
    if (page) {
        cprintf("Virtual Address: 0x%x\n", page->pra_vaddr);
    }
}

static void
display_mm_list() {
    list_entry_t *header = &pra_list_head, *current = header;
    while ((current = list_next(current)) != header) {
        struct Page* page_node = le2page(current, pra_page_link);
        print_page_info(page_node);
    }
}

static void
set_page_non_readable(struct mm_struct *mm, struct Page *page) {
    pte_t* page_table_entry = get_pte(mm->pgdir, page->pra_vaddr, 0);
    *page_table_entry &= ~PTE_R;
}

static int
restrict_all_pages(struct mm_struct *mm) {
    list_entry_t *header = (list_entry_t*) mm->sm_priv;
    list_entry_t *current = list_prev(header);

    while (current != header) {
        struct Page* page_node = le2page(current, pra_page_link);
        set_page_non_readable(mm, page_node);
        current = list_prev(current);
    }
    return 0;
}

static list_entry_t*
find_and_move_page(list_entry_t *header, struct Page *target_page) {
    list_entry_t *current = list_prev(header);

    while (current != header) {
        struct Page *existing_page = le2page(current, pra_page_link);
        if (existing_page == target_page) {
            return current;
        }
        current = list_prev(current);
    }
    return NULL;
}

int lru_handle_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("Handling page fault at virtual address: 0x%x\n", addr);

    if (swap_init_ok) {
        restrict_all_pages(mm);
    }

    pte_t* page_table_entry = get_pte(mm->pgdir, addr, 0);
    *page_table_entry |= PTE_R;

    if (!swap_init_ok) {
        return 0;
    }

    struct Page* fault_page = pte2page(*page_table_entry);
    list_entry_t *header = (list_entry_t*) mm->sm_priv;

    list_entry_t *victim_entry = find_and_move_page(header, fault_page);
    if (victim_entry) {
        list_del(victim_entry);
        list_add(header, victim_entry);
    }
    return 0;
}

static int
_lru_check_swap(void) {
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    display_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    display_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    display_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    display_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    display_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    display_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    display_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    display_mm_list();
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    display_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    display_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    display_mm_list();
    return 0;
}

static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ 
    return 0; 
}

struct swap_manager swap_manager_lru = {
    .name            = "lru swap manager",
    .init            = &_lru_init,
    .init_mm         = &_lru_init_mm,
    .tick_event      = &_lru_tick_event,
    .map_swappable   = &_lru_map_swappable,
    .set_unswappable = &_lru_set_unswappable,
    .swap_out_victim = &_lru_swap_out_victim,
    .check_swap      = &_lru_check_swap,
};