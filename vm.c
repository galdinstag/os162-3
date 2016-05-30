#include "param.h"
#include "types.h"
#include "defs.h"
#include "x86.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "elf.h"

extern char data[];  // defined by kernel.ld
pde_t *kpgdir;  // for use in scheduler()
struct segdesc gdt[NSEGS];
int findNextOpenPage(char *a);
void swapOut();


// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
  struct cpu *c;

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);

  lgdt(c->gdt, sizeof(c->gdt));
  loadgs(SEG_KCPU << 3);
  
  // Initialize cpu-local storage.
  cpu = c;
  proc = 0;
}

// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
  if(*pde & PTE_P){
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
      return 0;
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// There is one page table per process, plus one that's used when
// a CPU is not running any process (kpgdir). The kernel uses the
// current process's page table during system calls and interrupts;
// page protection bits prevent user code from using the kernel's
// mappings.
// 
// setupkvm() and exec() set up every page table like this:
//
//   0..KERNBASE: user memory (text+data+stack+heap), mapped to
//                phys memory allocated by the kernel
//   KERNBASE..KERNBASE+EXTMEM: mapped to 0..EXTMEM (for I/O space)
//   KERNBASE+EXTMEM..data: mapped to EXTMEM..V2P(data)
//                for the kernel's instructions and r/o data
//   data..KERNBASE+PHYSTOP: mapped to V2P(data)..PHYSTOP, 
//                                  rw data + free physical memory
//   0xfe000000..0: mapped direct (devices such as ioapic)
//
// The kernel allocates physical memory for its heap and for user memory
// between V2P(end) and the end of physical memory (PHYSTOP)
// (directly addressable from end..P2V(PHYSTOP)).

// This table defines the kernel's mappings, which are present in
// every process's page table.
static struct kmap {
  void *virt;
  uint phys_start;
  uint phys_end;
  int perm;
} kmap[] = {
 { (void*)KERNBASE, 0,             EXTMEM,    PTE_W}, // I/O space
 { (void*)KERNLINK, V2P(KERNLINK), V2P(data), 0},     // kern text+rodata
 { (void*)data,     V2P(data),     PHYSTOP,   PTE_W}, // kern data+memory
 { (void*)DEVSPACE, DEVSPACE,      0,         PTE_W}, // more devices
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
  }

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
    kpgdir = setupkvm();
    switchkvm();
  }

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
  lcr3(v2p(kpgdir));   // switch to the kernel page table
}

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
  pushcli();
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
  cpu->gdt[SEG_TSS].s = 0;
  cpu->ts.ss0 = SEG_KDATA << 3;
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
  ltr(SEG_TSS << 3);
  if(p->pgdir == 0)
    panic("switchuvm: no pgdir");
  lcr3(v2p(p->pgdir));  // switch to new address space
  popcli();
}

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
  char *mem;
  
  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
  memmove(mem, init, sz);
}

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
}

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      cprintf("allocuvm out of memory\n");
      deallocuvm(pgdir, newsz, oldsz, proc);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
          swapOut();
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
      }
      proc->pagesMetaData[i].va = (char *)a;
      proc->pagesMetaData[i].isPhysical = 1;
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
            }
            proc->pagesMetaData[i].va = (char *) -1;
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a += (NPTENTRIES - 1) * PGSIZE;
    else if((*pte & PTE_P) != 0){
      if((*pte & PTE_PG) == 0){//in memory, do kfree
        pa = PTE_ADDR(*pte);
        if(pa == 0)
          panic("kfree");
        char *v = p2v(pa);
        kfree(v);
        *pte = 0;
      }
      else{//on swap file, just elapse pte
        *pte = 0;
        cprintf("dealloc pa:%x",PTE_ADDR(*pte));
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
    }
  }
  return newsz;
}

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);

}

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  if(pte == 0)
    panic("clearpteu");
  *pte &= ~PTE_U;
}

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
  // int k;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,proc->pagesMetaData[k].va);
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
    // if(*pte & PTE_PG)
    //   *pte &= ~PTE_PG;
    np->pagesMetaData[j].va = (char *) i;
    np->pagesMetaData[j].isPhysical = 1;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
    np->pagesMetaData[j].va = (char *) -1;
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;

  bad:
  freevm(d,0);
  return 0;
}

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
  if((*pte & PTE_P) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  return (char*)p2v(PTE_ADDR(*pte));
}

// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
    va0 = (uint)PGROUNDDOWN(va);
    pa0 = uva2ka(pgdir, (char*)va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
}

//PAGEBREAK!
// Blank page.
//PAGEBREAK!
// Blank page.
//PAGEBREAK!
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
}

int
existOnDisc(uint faultingPage){
  cprintf("faulting page: %x\n",faultingPage);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  for(i = 0; i < 30; i++){
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
}

void
fixPage(uint faultingPage){
  int i;
  char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
  if(mem == 0){
    panic("no room, go away");
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
        if(readFromSwapFile(proc,buf,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
          panic("nothing read");
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1)  //need to swap out
          swapOut();
        proc->pagesMetaData[i].isPhysical = 1;
        proc->pagesMetaData[i].lru = 0x80;  //TODO here?
        proc->pagesMetaData[i].fileOffset = -1;
        break;
      }
    }
  }    
    memmove(mem,buf,PGSIZE);
    *pte &= ~PTE_PG;  //turn off flag
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
    memmove(buf,0,PGSIZE);
  }

//swap out a page from proc.
  void swapOut(){
    int j;
    int offset;
    char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    int index = -1;
    int min = proc->numOfPages+3;
    char minNFU = 0x80;


    switch(SCHEDFLAG){
      case 1: //NONE
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
            min = proc->pagesMetaData[j].count;
            index = j;
            cprintf("currently i'm choosing %x has count %d\n",proc->pagesMetaData[index],proc->pagesMetaData[index].count);
          }
        }
        break;

      case 3:  //SCFIFO //turn bit off and move to be newest
        while(1){ //untill a good page to swap out is found
        min = proc->numOfPages+3;
        for(j=3; j<30; j++){  //find the oldest page
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
            min = proc->pagesMetaData[j].count;
            index = j;
          }
        }
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
        if (*pte & PTE_A){  //the access flag is on. turn off and give a new counter
            *pte &= !PTE_A; //turn off
            proc->pagesMetaData[index].count = proc->numOfPages;  
            proc->numOfPages++; //TODO: SEMAPHOR!???
          }
        else{//it is a good one
          break;
        }
      }
      break;

      case 4:  //NFU
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru <= minNFU){
            minNFU = proc->pagesMetaData[j].lru;
            index = j;
          }
        }
        break;
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
      //cprintf("choose to swap out %x\n",proc->pagesMetaData[index].va);
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
      //cprintf("after offset\n");
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
      //cprintf("after walkpgdir\n");
      if(!(*pte & PTE_PG)){
        *pte |= PTE_PG; //turn on    
      }
      //cprintf("after setting PG\n");
      proc->pagesMetaData[index].fileOffset = offset;
      proc->pagesMetaData[index].isPhysical = 0;
      proc->pagesMetaData[index].count = proc->numOfPages;
      proc->numOfPages++;
      memmove(buf,proc->pagesMetaData[index].va,PGSIZE);
      //cprintf("after memmove\n");
      writeToSwapFile(proc,buf,offset,PGSIZE);
      //cprintf("after write\n");
      pa = PTE_ADDR(*pte);
      cprintf("after pa\n");
      if(pa == 0)
        panic("kfree swapOut");
      kfree((char *)p2v(pa)); 
      cprintf("after kfree\n");
      *pte = 0 | PTE_W | PTE_U | PTE_PG;
      cprintf("after pte\n");
    }
  }

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=0){ //only if on RAM
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
        if(!(*pte & PTE_A)){
          *pte &= !PTE_A; //turn off bit 
      }
    }
  }

void
clearAllPages(struct proc *p){
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
    if(p->pagesMetaData[i].va != (char *) -1){
      pte = walkpgdir(p->pgdir,proc->pagesMetaData[i].va,0);
      if(!pte){

      }
      else if((*pte & PTE_P) != 0){
        pa = PTE_ADDR(*pte);
        if(pa == 0){
          cprintf("already free\n");
        }
        else{
          cprintf("clearing\n");
          char *v = p2v(pa);
          kfree(v);
          *pte = 0;
          cprintf("finished\n");
        }
      }
    }
  }
}
