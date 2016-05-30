#include "param.h"
#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "fcntl.h"
#include "syscall.h"
#include "traps.h"
#include "memlayout.h"

#define PGSIZE 4096
#define NUM_OF_PAGES 20

char* array[NUM_OF_PAGES];

int
main(int argc, char *argv[])
{

int i,j;

for (i = 0; i < NUM_OF_PAGES ; ++i)
{
array[i] = sbrk(PGSIZE);
printf(1, "allocateing page #%d at address: %x\n", i, array[i]);
}

//using all pages to cause page faults
for ( i = 0; i < NUM_OF_PAGES; ++i)
{
for ( j = 0; j < PGSIZE; ++j)
{
array[i][j] = 1;
}
}
printf(1,"Finished Successfuly!!!\n");
exit();
return 0;
}