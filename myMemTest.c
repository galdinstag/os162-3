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
#define NUM_OF_PAGES 24

char* array[NUM_OF_PAGES];

int
main(int argc, char *argv[])
{

	int i,j,k;
	int pid;

	for (i = 0; i < NUM_OF_PAGES ; ++i)
	{
		array[i] = sbrk(PGSIZE);
		printf(1, "allocateing page #%d at address: %x\n", i, array[i]);
	}
	printf(1,"forking\n");
	pid = fork();
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
		for ( i = 0; i < 10; ++i)
		{
			for ( j = 0; j < PGSIZE; ++j)
			{
				array[i][j] = 0;
			}
		}
	}
	if(pid != 0){//mother
		wait();
	}

	printf(1,"Finished Successfuly!!!\n");
	exit();
	return 0;
}