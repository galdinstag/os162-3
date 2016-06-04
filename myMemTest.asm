
_myMemTest:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:

char* array[NUM_OF_PAGES];

int
main(int argc, char *argv[])
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 20             	sub    $0x20,%esp

	int i,j,k;
	int pid;

	for (i = 0; i < NUM_OF_PAGES ; ++i)
   9:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  10:	00 
  11:	eb 47                	jmp    5a <main+0x5a>
	{
		array[i] = sbrk(PGSIZE);
  13:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
  1a:	e8 0d 04 00 00       	call   42c <sbrk>
  1f:	8b 54 24 1c          	mov    0x1c(%esp),%edx
  23:	89 04 95 00 0c 00 00 	mov    %eax,0xc00(,%edx,4)
		printf(1, "allocateing page #%d at address: %x\n", i, array[i]);
  2a:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  2e:	8b 04 85 00 0c 00 00 	mov    0xc00(,%eax,4),%eax
  35:	89 44 24 0c          	mov    %eax,0xc(%esp)
  39:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  3d:	89 44 24 08          	mov    %eax,0x8(%esp)
  41:	c7 44 24 04 f0 08 00 	movl   $0x8f0,0x4(%esp)
  48:	00 
  49:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  50:	e8 cf 04 00 00       	call   524 <printf>
{

	int i,j,k;
	int pid;

	for (i = 0; i < NUM_OF_PAGES ; ++i)
  55:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  5a:	83 7c 24 1c 17       	cmpl   $0x17,0x1c(%esp)
  5f:	7e b2                	jle    13 <main+0x13>
	{
		array[i] = sbrk(PGSIZE);
		printf(1, "allocateing page #%d at address: %x\n", i, array[i]);
	}
	printf(1,"forking\n");
  61:	c7 44 24 04 15 09 00 	movl   $0x915,0x4(%esp)
  68:	00 
  69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  70:	e8 af 04 00 00       	call   524 <printf>
	pid = fork();
  75:	e8 22 03 00 00       	call   39c <fork>
  7a:	89 44 24 10          	mov    %eax,0x10(%esp)
	printf(1,"forking son\n");
  7e:	c7 44 24 04 1e 09 00 	movl   $0x91e,0x4(%esp)
  85:	00 
  86:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  8d:	e8 92 04 00 00       	call   524 <printf>
	if(pid == 0)
  92:	83 7c 24 10 00       	cmpl   $0x0,0x10(%esp)
  97:	75 09                	jne    a2 <main+0xa2>
		pid = fork();
  99:	e8 fe 02 00 00       	call   39c <fork>
  9e:	89 44 24 10          	mov    %eax,0x10(%esp)
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
  a2:	8b 44 24 10          	mov    0x10(%esp),%eax
  a6:	89 44 24 08          	mov    %eax,0x8(%esp)
  aa:	c7 44 24 04 2c 09 00 	movl   $0x92c,0x4(%esp)
  b1:	00 
  b2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  b9:	e8 66 04 00 00       	call   524 <printf>
	for(k = 0; k < 3; k++){
  be:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  c5:	00 
  c6:	eb 48                	jmp    110 <main+0x110>
		for ( i = 0; i < 10; ++i)
  c8:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  cf:	00 
  d0:	eb 32                	jmp    104 <main+0x104>
		{
			for ( j = 0; j < PGSIZE; ++j)
  d2:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  d9:	00 
  da:	eb 19                	jmp    f5 <main+0xf5>
			{
				array[i][j] = 0;
  dc:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  e0:	8b 14 85 00 0c 00 00 	mov    0xc00(,%eax,4),%edx
  e7:	8b 44 24 18          	mov    0x18(%esp),%eax
  eb:	01 d0                	add    %edx,%eax
  ed:	c6 00 00             	movb   $0x0,(%eax)
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
		for ( i = 0; i < 10; ++i)
		{
			for ( j = 0; j < PGSIZE; ++j)
  f0:	83 44 24 18 01       	addl   $0x1,0x18(%esp)
  f5:	81 7c 24 18 ff 0f 00 	cmpl   $0xfff,0x18(%esp)
  fc:	00 
  fd:	7e dd                	jle    dc <main+0xdc>
	if(pid == 0)
		pid = fork();
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
		for ( i = 0; i < 10; ++i)
  ff:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
 104:	83 7c 24 1c 09       	cmpl   $0x9,0x1c(%esp)
 109:	7e c7                	jle    d2 <main+0xd2>
	printf(1,"forking son\n");
	if(pid == 0)
		pid = fork();
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
 10b:	83 44 24 14 01       	addl   $0x1,0x14(%esp)
 110:	83 7c 24 14 02       	cmpl   $0x2,0x14(%esp)
 115:	7e b1                	jle    c8 <main+0xc8>
			{
				array[i][j] = 0;
			}
		}
	}
	if(pid != 0){//mother
 117:	83 7c 24 10 00       	cmpl   $0x0,0x10(%esp)
 11c:	74 05                	je     123 <main+0x123>
		wait();
 11e:	e8 89 02 00 00       	call   3ac <wait>
	}
	printf(1,"Finished Successfuly!!!\n");
 123:	c7 44 24 04 52 09 00 	movl   $0x952,0x4(%esp)
 12a:	00 
 12b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 132:	e8 ed 03 00 00       	call   524 <printf>
	exit();
 137:	e8 68 02 00 00       	call   3a4 <exit>

0000013c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 13c:	55                   	push   %ebp
 13d:	89 e5                	mov    %esp,%ebp
 13f:	57                   	push   %edi
 140:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 141:	8b 4d 08             	mov    0x8(%ebp),%ecx
 144:	8b 55 10             	mov    0x10(%ebp),%edx
 147:	8b 45 0c             	mov    0xc(%ebp),%eax
 14a:	89 cb                	mov    %ecx,%ebx
 14c:	89 df                	mov    %ebx,%edi
 14e:	89 d1                	mov    %edx,%ecx
 150:	fc                   	cld    
 151:	f3 aa                	rep stos %al,%es:(%edi)
 153:	89 ca                	mov    %ecx,%edx
 155:	89 fb                	mov    %edi,%ebx
 157:	89 5d 08             	mov    %ebx,0x8(%ebp)
 15a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 15d:	5b                   	pop    %ebx
 15e:	5f                   	pop    %edi
 15f:	5d                   	pop    %ebp
 160:	c3                   	ret    

00000161 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 161:	55                   	push   %ebp
 162:	89 e5                	mov    %esp,%ebp
 164:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 167:	8b 45 08             	mov    0x8(%ebp),%eax
 16a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 16d:	90                   	nop
 16e:	8b 45 08             	mov    0x8(%ebp),%eax
 171:	8d 50 01             	lea    0x1(%eax),%edx
 174:	89 55 08             	mov    %edx,0x8(%ebp)
 177:	8b 55 0c             	mov    0xc(%ebp),%edx
 17a:	8d 4a 01             	lea    0x1(%edx),%ecx
 17d:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 180:	0f b6 12             	movzbl (%edx),%edx
 183:	88 10                	mov    %dl,(%eax)
 185:	0f b6 00             	movzbl (%eax),%eax
 188:	84 c0                	test   %al,%al
 18a:	75 e2                	jne    16e <strcpy+0xd>
    ;
  return os;
 18c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 18f:	c9                   	leave  
 190:	c3                   	ret    

00000191 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 191:	55                   	push   %ebp
 192:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 194:	eb 08                	jmp    19e <strcmp+0xd>
    p++, q++;
 196:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 19a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 19e:	8b 45 08             	mov    0x8(%ebp),%eax
 1a1:	0f b6 00             	movzbl (%eax),%eax
 1a4:	84 c0                	test   %al,%al
 1a6:	74 10                	je     1b8 <strcmp+0x27>
 1a8:	8b 45 08             	mov    0x8(%ebp),%eax
 1ab:	0f b6 10             	movzbl (%eax),%edx
 1ae:	8b 45 0c             	mov    0xc(%ebp),%eax
 1b1:	0f b6 00             	movzbl (%eax),%eax
 1b4:	38 c2                	cmp    %al,%dl
 1b6:	74 de                	je     196 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 1b8:	8b 45 08             	mov    0x8(%ebp),%eax
 1bb:	0f b6 00             	movzbl (%eax),%eax
 1be:	0f b6 d0             	movzbl %al,%edx
 1c1:	8b 45 0c             	mov    0xc(%ebp),%eax
 1c4:	0f b6 00             	movzbl (%eax),%eax
 1c7:	0f b6 c0             	movzbl %al,%eax
 1ca:	29 c2                	sub    %eax,%edx
 1cc:	89 d0                	mov    %edx,%eax
}
 1ce:	5d                   	pop    %ebp
 1cf:	c3                   	ret    

000001d0 <strlen>:

uint
strlen(char *s)
{
 1d0:	55                   	push   %ebp
 1d1:	89 e5                	mov    %esp,%ebp
 1d3:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 1d6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 1dd:	eb 04                	jmp    1e3 <strlen+0x13>
 1df:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 1e3:	8b 55 fc             	mov    -0x4(%ebp),%edx
 1e6:	8b 45 08             	mov    0x8(%ebp),%eax
 1e9:	01 d0                	add    %edx,%eax
 1eb:	0f b6 00             	movzbl (%eax),%eax
 1ee:	84 c0                	test   %al,%al
 1f0:	75 ed                	jne    1df <strlen+0xf>
    ;
  return n;
 1f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1f5:	c9                   	leave  
 1f6:	c3                   	ret    

000001f7 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1f7:	55                   	push   %ebp
 1f8:	89 e5                	mov    %esp,%ebp
 1fa:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 1fd:	8b 45 10             	mov    0x10(%ebp),%eax
 200:	89 44 24 08          	mov    %eax,0x8(%esp)
 204:	8b 45 0c             	mov    0xc(%ebp),%eax
 207:	89 44 24 04          	mov    %eax,0x4(%esp)
 20b:	8b 45 08             	mov    0x8(%ebp),%eax
 20e:	89 04 24             	mov    %eax,(%esp)
 211:	e8 26 ff ff ff       	call   13c <stosb>
  return dst;
 216:	8b 45 08             	mov    0x8(%ebp),%eax
}
 219:	c9                   	leave  
 21a:	c3                   	ret    

0000021b <strchr>:

char*
strchr(const char *s, char c)
{
 21b:	55                   	push   %ebp
 21c:	89 e5                	mov    %esp,%ebp
 21e:	83 ec 04             	sub    $0x4,%esp
 221:	8b 45 0c             	mov    0xc(%ebp),%eax
 224:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 227:	eb 14                	jmp    23d <strchr+0x22>
    if(*s == c)
 229:	8b 45 08             	mov    0x8(%ebp),%eax
 22c:	0f b6 00             	movzbl (%eax),%eax
 22f:	3a 45 fc             	cmp    -0x4(%ebp),%al
 232:	75 05                	jne    239 <strchr+0x1e>
      return (char*)s;
 234:	8b 45 08             	mov    0x8(%ebp),%eax
 237:	eb 13                	jmp    24c <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 239:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 23d:	8b 45 08             	mov    0x8(%ebp),%eax
 240:	0f b6 00             	movzbl (%eax),%eax
 243:	84 c0                	test   %al,%al
 245:	75 e2                	jne    229 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 247:	b8 00 00 00 00       	mov    $0x0,%eax
}
 24c:	c9                   	leave  
 24d:	c3                   	ret    

0000024e <gets>:

char*
gets(char *buf, int max)
{
 24e:	55                   	push   %ebp
 24f:	89 e5                	mov    %esp,%ebp
 251:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 254:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 25b:	eb 4c                	jmp    2a9 <gets+0x5b>
    cc = read(0, &c, 1);
 25d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 264:	00 
 265:	8d 45 ef             	lea    -0x11(%ebp),%eax
 268:	89 44 24 04          	mov    %eax,0x4(%esp)
 26c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 273:	e8 44 01 00 00       	call   3bc <read>
 278:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 27b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 27f:	7f 02                	jg     283 <gets+0x35>
      break;
 281:	eb 31                	jmp    2b4 <gets+0x66>
    buf[i++] = c;
 283:	8b 45 f4             	mov    -0xc(%ebp),%eax
 286:	8d 50 01             	lea    0x1(%eax),%edx
 289:	89 55 f4             	mov    %edx,-0xc(%ebp)
 28c:	89 c2                	mov    %eax,%edx
 28e:	8b 45 08             	mov    0x8(%ebp),%eax
 291:	01 c2                	add    %eax,%edx
 293:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 297:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 299:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 29d:	3c 0a                	cmp    $0xa,%al
 29f:	74 13                	je     2b4 <gets+0x66>
 2a1:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2a5:	3c 0d                	cmp    $0xd,%al
 2a7:	74 0b                	je     2b4 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2ac:	83 c0 01             	add    $0x1,%eax
 2af:	3b 45 0c             	cmp    0xc(%ebp),%eax
 2b2:	7c a9                	jl     25d <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 2b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
 2b7:	8b 45 08             	mov    0x8(%ebp),%eax
 2ba:	01 d0                	add    %edx,%eax
 2bc:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 2bf:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2c2:	c9                   	leave  
 2c3:	c3                   	ret    

000002c4 <stat>:

int
stat(char *n, struct stat *st)
{
 2c4:	55                   	push   %ebp
 2c5:	89 e5                	mov    %esp,%ebp
 2c7:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 2d1:	00 
 2d2:	8b 45 08             	mov    0x8(%ebp),%eax
 2d5:	89 04 24             	mov    %eax,(%esp)
 2d8:	e8 07 01 00 00       	call   3e4 <open>
 2dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 2e0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 2e4:	79 07                	jns    2ed <stat+0x29>
    return -1;
 2e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 2eb:	eb 23                	jmp    310 <stat+0x4c>
  r = fstat(fd, st);
 2ed:	8b 45 0c             	mov    0xc(%ebp),%eax
 2f0:	89 44 24 04          	mov    %eax,0x4(%esp)
 2f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2f7:	89 04 24             	mov    %eax,(%esp)
 2fa:	e8 fd 00 00 00       	call   3fc <fstat>
 2ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 302:	8b 45 f4             	mov    -0xc(%ebp),%eax
 305:	89 04 24             	mov    %eax,(%esp)
 308:	e8 bf 00 00 00       	call   3cc <close>
  return r;
 30d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 310:	c9                   	leave  
 311:	c3                   	ret    

00000312 <atoi>:

int
atoi(const char *s)
{
 312:	55                   	push   %ebp
 313:	89 e5                	mov    %esp,%ebp
 315:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 318:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 31f:	eb 25                	jmp    346 <atoi+0x34>
    n = n*10 + *s++ - '0';
 321:	8b 55 fc             	mov    -0x4(%ebp),%edx
 324:	89 d0                	mov    %edx,%eax
 326:	c1 e0 02             	shl    $0x2,%eax
 329:	01 d0                	add    %edx,%eax
 32b:	01 c0                	add    %eax,%eax
 32d:	89 c1                	mov    %eax,%ecx
 32f:	8b 45 08             	mov    0x8(%ebp),%eax
 332:	8d 50 01             	lea    0x1(%eax),%edx
 335:	89 55 08             	mov    %edx,0x8(%ebp)
 338:	0f b6 00             	movzbl (%eax),%eax
 33b:	0f be c0             	movsbl %al,%eax
 33e:	01 c8                	add    %ecx,%eax
 340:	83 e8 30             	sub    $0x30,%eax
 343:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 346:	8b 45 08             	mov    0x8(%ebp),%eax
 349:	0f b6 00             	movzbl (%eax),%eax
 34c:	3c 2f                	cmp    $0x2f,%al
 34e:	7e 0a                	jle    35a <atoi+0x48>
 350:	8b 45 08             	mov    0x8(%ebp),%eax
 353:	0f b6 00             	movzbl (%eax),%eax
 356:	3c 39                	cmp    $0x39,%al
 358:	7e c7                	jle    321 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 35a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 35d:	c9                   	leave  
 35e:	c3                   	ret    

0000035f <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 35f:	55                   	push   %ebp
 360:	89 e5                	mov    %esp,%ebp
 362:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 365:	8b 45 08             	mov    0x8(%ebp),%eax
 368:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 36b:	8b 45 0c             	mov    0xc(%ebp),%eax
 36e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 371:	eb 17                	jmp    38a <memmove+0x2b>
    *dst++ = *src++;
 373:	8b 45 fc             	mov    -0x4(%ebp),%eax
 376:	8d 50 01             	lea    0x1(%eax),%edx
 379:	89 55 fc             	mov    %edx,-0x4(%ebp)
 37c:	8b 55 f8             	mov    -0x8(%ebp),%edx
 37f:	8d 4a 01             	lea    0x1(%edx),%ecx
 382:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 385:	0f b6 12             	movzbl (%edx),%edx
 388:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 38a:	8b 45 10             	mov    0x10(%ebp),%eax
 38d:	8d 50 ff             	lea    -0x1(%eax),%edx
 390:	89 55 10             	mov    %edx,0x10(%ebp)
 393:	85 c0                	test   %eax,%eax
 395:	7f dc                	jg     373 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 397:	8b 45 08             	mov    0x8(%ebp),%eax
}
 39a:	c9                   	leave  
 39b:	c3                   	ret    

0000039c <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 39c:	b8 01 00 00 00       	mov    $0x1,%eax
 3a1:	cd 40                	int    $0x40
 3a3:	c3                   	ret    

000003a4 <exit>:
SYSCALL(exit)
 3a4:	b8 02 00 00 00       	mov    $0x2,%eax
 3a9:	cd 40                	int    $0x40
 3ab:	c3                   	ret    

000003ac <wait>:
SYSCALL(wait)
 3ac:	b8 03 00 00 00       	mov    $0x3,%eax
 3b1:	cd 40                	int    $0x40
 3b3:	c3                   	ret    

000003b4 <pipe>:
SYSCALL(pipe)
 3b4:	b8 04 00 00 00       	mov    $0x4,%eax
 3b9:	cd 40                	int    $0x40
 3bb:	c3                   	ret    

000003bc <read>:
SYSCALL(read)
 3bc:	b8 05 00 00 00       	mov    $0x5,%eax
 3c1:	cd 40                	int    $0x40
 3c3:	c3                   	ret    

000003c4 <write>:
SYSCALL(write)
 3c4:	b8 10 00 00 00       	mov    $0x10,%eax
 3c9:	cd 40                	int    $0x40
 3cb:	c3                   	ret    

000003cc <close>:
SYSCALL(close)
 3cc:	b8 15 00 00 00       	mov    $0x15,%eax
 3d1:	cd 40                	int    $0x40
 3d3:	c3                   	ret    

000003d4 <kill>:
SYSCALL(kill)
 3d4:	b8 06 00 00 00       	mov    $0x6,%eax
 3d9:	cd 40                	int    $0x40
 3db:	c3                   	ret    

000003dc <exec>:
SYSCALL(exec)
 3dc:	b8 07 00 00 00       	mov    $0x7,%eax
 3e1:	cd 40                	int    $0x40
 3e3:	c3                   	ret    

000003e4 <open>:
SYSCALL(open)
 3e4:	b8 0f 00 00 00       	mov    $0xf,%eax
 3e9:	cd 40                	int    $0x40
 3eb:	c3                   	ret    

000003ec <mknod>:
SYSCALL(mknod)
 3ec:	b8 11 00 00 00       	mov    $0x11,%eax
 3f1:	cd 40                	int    $0x40
 3f3:	c3                   	ret    

000003f4 <unlink>:
SYSCALL(unlink)
 3f4:	b8 12 00 00 00       	mov    $0x12,%eax
 3f9:	cd 40                	int    $0x40
 3fb:	c3                   	ret    

000003fc <fstat>:
SYSCALL(fstat)
 3fc:	b8 08 00 00 00       	mov    $0x8,%eax
 401:	cd 40                	int    $0x40
 403:	c3                   	ret    

00000404 <link>:
SYSCALL(link)
 404:	b8 13 00 00 00       	mov    $0x13,%eax
 409:	cd 40                	int    $0x40
 40b:	c3                   	ret    

0000040c <mkdir>:
SYSCALL(mkdir)
 40c:	b8 14 00 00 00       	mov    $0x14,%eax
 411:	cd 40                	int    $0x40
 413:	c3                   	ret    

00000414 <chdir>:
SYSCALL(chdir)
 414:	b8 09 00 00 00       	mov    $0x9,%eax
 419:	cd 40                	int    $0x40
 41b:	c3                   	ret    

0000041c <dup>:
SYSCALL(dup)
 41c:	b8 0a 00 00 00       	mov    $0xa,%eax
 421:	cd 40                	int    $0x40
 423:	c3                   	ret    

00000424 <getpid>:
SYSCALL(getpid)
 424:	b8 0b 00 00 00       	mov    $0xb,%eax
 429:	cd 40                	int    $0x40
 42b:	c3                   	ret    

0000042c <sbrk>:
SYSCALL(sbrk)
 42c:	b8 0c 00 00 00       	mov    $0xc,%eax
 431:	cd 40                	int    $0x40
 433:	c3                   	ret    

00000434 <sleep>:
SYSCALL(sleep)
 434:	b8 0d 00 00 00       	mov    $0xd,%eax
 439:	cd 40                	int    $0x40
 43b:	c3                   	ret    

0000043c <uptime>:
 43c:	b8 0e 00 00 00       	mov    $0xe,%eax
 441:	cd 40                	int    $0x40
 443:	c3                   	ret    

00000444 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 444:	55                   	push   %ebp
 445:	89 e5                	mov    %esp,%ebp
 447:	83 ec 18             	sub    $0x18,%esp
 44a:	8b 45 0c             	mov    0xc(%ebp),%eax
 44d:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 450:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 457:	00 
 458:	8d 45 f4             	lea    -0xc(%ebp),%eax
 45b:	89 44 24 04          	mov    %eax,0x4(%esp)
 45f:	8b 45 08             	mov    0x8(%ebp),%eax
 462:	89 04 24             	mov    %eax,(%esp)
 465:	e8 5a ff ff ff       	call   3c4 <write>
}
 46a:	c9                   	leave  
 46b:	c3                   	ret    

0000046c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 46c:	55                   	push   %ebp
 46d:	89 e5                	mov    %esp,%ebp
 46f:	56                   	push   %esi
 470:	53                   	push   %ebx
 471:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 474:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 47b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 47f:	74 17                	je     498 <printint+0x2c>
 481:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 485:	79 11                	jns    498 <printint+0x2c>
    neg = 1;
 487:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 48e:	8b 45 0c             	mov    0xc(%ebp),%eax
 491:	f7 d8                	neg    %eax
 493:	89 45 ec             	mov    %eax,-0x14(%ebp)
 496:	eb 06                	jmp    49e <printint+0x32>
  } else {
    x = xx;
 498:	8b 45 0c             	mov    0xc(%ebp),%eax
 49b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 49e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 4a5:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 4a8:	8d 41 01             	lea    0x1(%ecx),%eax
 4ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
 4ae:	8b 5d 10             	mov    0x10(%ebp),%ebx
 4b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4b4:	ba 00 00 00 00       	mov    $0x0,%edx
 4b9:	f7 f3                	div    %ebx
 4bb:	89 d0                	mov    %edx,%eax
 4bd:	0f b6 80 b8 0b 00 00 	movzbl 0xbb8(%eax),%eax
 4c4:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 4c8:	8b 75 10             	mov    0x10(%ebp),%esi
 4cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4ce:	ba 00 00 00 00       	mov    $0x0,%edx
 4d3:	f7 f6                	div    %esi
 4d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4d8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4dc:	75 c7                	jne    4a5 <printint+0x39>
  if(neg)
 4de:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 4e2:	74 10                	je     4f4 <printint+0x88>
    buf[i++] = '-';
 4e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4e7:	8d 50 01             	lea    0x1(%eax),%edx
 4ea:	89 55 f4             	mov    %edx,-0xc(%ebp)
 4ed:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 4f2:	eb 1f                	jmp    513 <printint+0xa7>
 4f4:	eb 1d                	jmp    513 <printint+0xa7>
    putc(fd, buf[i]);
 4f6:	8d 55 dc             	lea    -0x24(%ebp),%edx
 4f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4fc:	01 d0                	add    %edx,%eax
 4fe:	0f b6 00             	movzbl (%eax),%eax
 501:	0f be c0             	movsbl %al,%eax
 504:	89 44 24 04          	mov    %eax,0x4(%esp)
 508:	8b 45 08             	mov    0x8(%ebp),%eax
 50b:	89 04 24             	mov    %eax,(%esp)
 50e:	e8 31 ff ff ff       	call   444 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 513:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 517:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 51b:	79 d9                	jns    4f6 <printint+0x8a>
    putc(fd, buf[i]);
}
 51d:	83 c4 30             	add    $0x30,%esp
 520:	5b                   	pop    %ebx
 521:	5e                   	pop    %esi
 522:	5d                   	pop    %ebp
 523:	c3                   	ret    

00000524 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 524:	55                   	push   %ebp
 525:	89 e5                	mov    %esp,%ebp
 527:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 52a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 531:	8d 45 0c             	lea    0xc(%ebp),%eax
 534:	83 c0 04             	add    $0x4,%eax
 537:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 53a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 541:	e9 7c 01 00 00       	jmp    6c2 <printf+0x19e>
    c = fmt[i] & 0xff;
 546:	8b 55 0c             	mov    0xc(%ebp),%edx
 549:	8b 45 f0             	mov    -0x10(%ebp),%eax
 54c:	01 d0                	add    %edx,%eax
 54e:	0f b6 00             	movzbl (%eax),%eax
 551:	0f be c0             	movsbl %al,%eax
 554:	25 ff 00 00 00       	and    $0xff,%eax
 559:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 55c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 560:	75 2c                	jne    58e <printf+0x6a>
      if(c == '%'){
 562:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 566:	75 0c                	jne    574 <printf+0x50>
        state = '%';
 568:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 56f:	e9 4a 01 00 00       	jmp    6be <printf+0x19a>
      } else {
        putc(fd, c);
 574:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 577:	0f be c0             	movsbl %al,%eax
 57a:	89 44 24 04          	mov    %eax,0x4(%esp)
 57e:	8b 45 08             	mov    0x8(%ebp),%eax
 581:	89 04 24             	mov    %eax,(%esp)
 584:	e8 bb fe ff ff       	call   444 <putc>
 589:	e9 30 01 00 00       	jmp    6be <printf+0x19a>
      }
    } else if(state == '%'){
 58e:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 592:	0f 85 26 01 00 00    	jne    6be <printf+0x19a>
      if(c == 'd'){
 598:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 59c:	75 2d                	jne    5cb <printf+0xa7>
        printint(fd, *ap, 10, 1);
 59e:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5a1:	8b 00                	mov    (%eax),%eax
 5a3:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 5aa:	00 
 5ab:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 5b2:	00 
 5b3:	89 44 24 04          	mov    %eax,0x4(%esp)
 5b7:	8b 45 08             	mov    0x8(%ebp),%eax
 5ba:	89 04 24             	mov    %eax,(%esp)
 5bd:	e8 aa fe ff ff       	call   46c <printint>
        ap++;
 5c2:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5c6:	e9 ec 00 00 00       	jmp    6b7 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 5cb:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 5cf:	74 06                	je     5d7 <printf+0xb3>
 5d1:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 5d5:	75 2d                	jne    604 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 5d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5da:	8b 00                	mov    (%eax),%eax
 5dc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 5e3:	00 
 5e4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 5eb:	00 
 5ec:	89 44 24 04          	mov    %eax,0x4(%esp)
 5f0:	8b 45 08             	mov    0x8(%ebp),%eax
 5f3:	89 04 24             	mov    %eax,(%esp)
 5f6:	e8 71 fe ff ff       	call   46c <printint>
        ap++;
 5fb:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5ff:	e9 b3 00 00 00       	jmp    6b7 <printf+0x193>
      } else if(c == 's'){
 604:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 608:	75 45                	jne    64f <printf+0x12b>
        s = (char*)*ap;
 60a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 60d:	8b 00                	mov    (%eax),%eax
 60f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 612:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 616:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 61a:	75 09                	jne    625 <printf+0x101>
          s = "(null)";
 61c:	c7 45 f4 6b 09 00 00 	movl   $0x96b,-0xc(%ebp)
        while(*s != 0){
 623:	eb 1e                	jmp    643 <printf+0x11f>
 625:	eb 1c                	jmp    643 <printf+0x11f>
          putc(fd, *s);
 627:	8b 45 f4             	mov    -0xc(%ebp),%eax
 62a:	0f b6 00             	movzbl (%eax),%eax
 62d:	0f be c0             	movsbl %al,%eax
 630:	89 44 24 04          	mov    %eax,0x4(%esp)
 634:	8b 45 08             	mov    0x8(%ebp),%eax
 637:	89 04 24             	mov    %eax,(%esp)
 63a:	e8 05 fe ff ff       	call   444 <putc>
          s++;
 63f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 643:	8b 45 f4             	mov    -0xc(%ebp),%eax
 646:	0f b6 00             	movzbl (%eax),%eax
 649:	84 c0                	test   %al,%al
 64b:	75 da                	jne    627 <printf+0x103>
 64d:	eb 68                	jmp    6b7 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 64f:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 653:	75 1d                	jne    672 <printf+0x14e>
        putc(fd, *ap);
 655:	8b 45 e8             	mov    -0x18(%ebp),%eax
 658:	8b 00                	mov    (%eax),%eax
 65a:	0f be c0             	movsbl %al,%eax
 65d:	89 44 24 04          	mov    %eax,0x4(%esp)
 661:	8b 45 08             	mov    0x8(%ebp),%eax
 664:	89 04 24             	mov    %eax,(%esp)
 667:	e8 d8 fd ff ff       	call   444 <putc>
        ap++;
 66c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 670:	eb 45                	jmp    6b7 <printf+0x193>
      } else if(c == '%'){
 672:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 676:	75 17                	jne    68f <printf+0x16b>
        putc(fd, c);
 678:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 67b:	0f be c0             	movsbl %al,%eax
 67e:	89 44 24 04          	mov    %eax,0x4(%esp)
 682:	8b 45 08             	mov    0x8(%ebp),%eax
 685:	89 04 24             	mov    %eax,(%esp)
 688:	e8 b7 fd ff ff       	call   444 <putc>
 68d:	eb 28                	jmp    6b7 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 68f:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 696:	00 
 697:	8b 45 08             	mov    0x8(%ebp),%eax
 69a:	89 04 24             	mov    %eax,(%esp)
 69d:	e8 a2 fd ff ff       	call   444 <putc>
        putc(fd, c);
 6a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 6a5:	0f be c0             	movsbl %al,%eax
 6a8:	89 44 24 04          	mov    %eax,0x4(%esp)
 6ac:	8b 45 08             	mov    0x8(%ebp),%eax
 6af:	89 04 24             	mov    %eax,(%esp)
 6b2:	e8 8d fd ff ff       	call   444 <putc>
      }
      state = 0;
 6b7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 6be:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 6c2:	8b 55 0c             	mov    0xc(%ebp),%edx
 6c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6c8:	01 d0                	add    %edx,%eax
 6ca:	0f b6 00             	movzbl (%eax),%eax
 6cd:	84 c0                	test   %al,%al
 6cf:	0f 85 71 fe ff ff    	jne    546 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 6d5:	c9                   	leave  
 6d6:	c3                   	ret    

000006d7 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6d7:	55                   	push   %ebp
 6d8:	89 e5                	mov    %esp,%ebp
 6da:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6dd:	8b 45 08             	mov    0x8(%ebp),%eax
 6e0:	83 e8 08             	sub    $0x8,%eax
 6e3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e6:	a1 e8 0b 00 00       	mov    0xbe8,%eax
 6eb:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6ee:	eb 24                	jmp    714 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6f3:	8b 00                	mov    (%eax),%eax
 6f5:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6f8:	77 12                	ja     70c <free+0x35>
 6fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6fd:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 700:	77 24                	ja     726 <free+0x4f>
 702:	8b 45 fc             	mov    -0x4(%ebp),%eax
 705:	8b 00                	mov    (%eax),%eax
 707:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 70a:	77 1a                	ja     726 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 70f:	8b 00                	mov    (%eax),%eax
 711:	89 45 fc             	mov    %eax,-0x4(%ebp)
 714:	8b 45 f8             	mov    -0x8(%ebp),%eax
 717:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 71a:	76 d4                	jbe    6f0 <free+0x19>
 71c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 71f:	8b 00                	mov    (%eax),%eax
 721:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 724:	76 ca                	jbe    6f0 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 726:	8b 45 f8             	mov    -0x8(%ebp),%eax
 729:	8b 40 04             	mov    0x4(%eax),%eax
 72c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 733:	8b 45 f8             	mov    -0x8(%ebp),%eax
 736:	01 c2                	add    %eax,%edx
 738:	8b 45 fc             	mov    -0x4(%ebp),%eax
 73b:	8b 00                	mov    (%eax),%eax
 73d:	39 c2                	cmp    %eax,%edx
 73f:	75 24                	jne    765 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 741:	8b 45 f8             	mov    -0x8(%ebp),%eax
 744:	8b 50 04             	mov    0x4(%eax),%edx
 747:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74a:	8b 00                	mov    (%eax),%eax
 74c:	8b 40 04             	mov    0x4(%eax),%eax
 74f:	01 c2                	add    %eax,%edx
 751:	8b 45 f8             	mov    -0x8(%ebp),%eax
 754:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 757:	8b 45 fc             	mov    -0x4(%ebp),%eax
 75a:	8b 00                	mov    (%eax),%eax
 75c:	8b 10                	mov    (%eax),%edx
 75e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 761:	89 10                	mov    %edx,(%eax)
 763:	eb 0a                	jmp    76f <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 765:	8b 45 fc             	mov    -0x4(%ebp),%eax
 768:	8b 10                	mov    (%eax),%edx
 76a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 76d:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 76f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 772:	8b 40 04             	mov    0x4(%eax),%eax
 775:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 77c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 77f:	01 d0                	add    %edx,%eax
 781:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 784:	75 20                	jne    7a6 <free+0xcf>
    p->s.size += bp->s.size;
 786:	8b 45 fc             	mov    -0x4(%ebp),%eax
 789:	8b 50 04             	mov    0x4(%eax),%edx
 78c:	8b 45 f8             	mov    -0x8(%ebp),%eax
 78f:	8b 40 04             	mov    0x4(%eax),%eax
 792:	01 c2                	add    %eax,%edx
 794:	8b 45 fc             	mov    -0x4(%ebp),%eax
 797:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 79a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 79d:	8b 10                	mov    (%eax),%edx
 79f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7a2:	89 10                	mov    %edx,(%eax)
 7a4:	eb 08                	jmp    7ae <free+0xd7>
  } else
    p->s.ptr = bp;
 7a6:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7a9:	8b 55 f8             	mov    -0x8(%ebp),%edx
 7ac:	89 10                	mov    %edx,(%eax)
  freep = p;
 7ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7b1:	a3 e8 0b 00 00       	mov    %eax,0xbe8
}
 7b6:	c9                   	leave  
 7b7:	c3                   	ret    

000007b8 <morecore>:

static Header*
morecore(uint nu)
{
 7b8:	55                   	push   %ebp
 7b9:	89 e5                	mov    %esp,%ebp
 7bb:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 7be:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 7c5:	77 07                	ja     7ce <morecore+0x16>
    nu = 4096;
 7c7:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 7ce:	8b 45 08             	mov    0x8(%ebp),%eax
 7d1:	c1 e0 03             	shl    $0x3,%eax
 7d4:	89 04 24             	mov    %eax,(%esp)
 7d7:	e8 50 fc ff ff       	call   42c <sbrk>
 7dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 7df:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 7e3:	75 07                	jne    7ec <morecore+0x34>
    return 0;
 7e5:	b8 00 00 00 00       	mov    $0x0,%eax
 7ea:	eb 22                	jmp    80e <morecore+0x56>
  hp = (Header*)p;
 7ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 7f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7f5:	8b 55 08             	mov    0x8(%ebp),%edx
 7f8:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 7fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7fe:	83 c0 08             	add    $0x8,%eax
 801:	89 04 24             	mov    %eax,(%esp)
 804:	e8 ce fe ff ff       	call   6d7 <free>
  return freep;
 809:	a1 e8 0b 00 00       	mov    0xbe8,%eax
}
 80e:	c9                   	leave  
 80f:	c3                   	ret    

00000810 <malloc>:

void*
malloc(uint nbytes)
{
 810:	55                   	push   %ebp
 811:	89 e5                	mov    %esp,%ebp
 813:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 816:	8b 45 08             	mov    0x8(%ebp),%eax
 819:	83 c0 07             	add    $0x7,%eax
 81c:	c1 e8 03             	shr    $0x3,%eax
 81f:	83 c0 01             	add    $0x1,%eax
 822:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 825:	a1 e8 0b 00 00       	mov    0xbe8,%eax
 82a:	89 45 f0             	mov    %eax,-0x10(%ebp)
 82d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 831:	75 23                	jne    856 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 833:	c7 45 f0 e0 0b 00 00 	movl   $0xbe0,-0x10(%ebp)
 83a:	8b 45 f0             	mov    -0x10(%ebp),%eax
 83d:	a3 e8 0b 00 00       	mov    %eax,0xbe8
 842:	a1 e8 0b 00 00       	mov    0xbe8,%eax
 847:	a3 e0 0b 00 00       	mov    %eax,0xbe0
    base.s.size = 0;
 84c:	c7 05 e4 0b 00 00 00 	movl   $0x0,0xbe4
 853:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 856:	8b 45 f0             	mov    -0x10(%ebp),%eax
 859:	8b 00                	mov    (%eax),%eax
 85b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 85e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 861:	8b 40 04             	mov    0x4(%eax),%eax
 864:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 867:	72 4d                	jb     8b6 <malloc+0xa6>
      if(p->s.size == nunits)
 869:	8b 45 f4             	mov    -0xc(%ebp),%eax
 86c:	8b 40 04             	mov    0x4(%eax),%eax
 86f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 872:	75 0c                	jne    880 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 874:	8b 45 f4             	mov    -0xc(%ebp),%eax
 877:	8b 10                	mov    (%eax),%edx
 879:	8b 45 f0             	mov    -0x10(%ebp),%eax
 87c:	89 10                	mov    %edx,(%eax)
 87e:	eb 26                	jmp    8a6 <malloc+0x96>
      else {
        p->s.size -= nunits;
 880:	8b 45 f4             	mov    -0xc(%ebp),%eax
 883:	8b 40 04             	mov    0x4(%eax),%eax
 886:	2b 45 ec             	sub    -0x14(%ebp),%eax
 889:	89 c2                	mov    %eax,%edx
 88b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 88e:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 891:	8b 45 f4             	mov    -0xc(%ebp),%eax
 894:	8b 40 04             	mov    0x4(%eax),%eax
 897:	c1 e0 03             	shl    $0x3,%eax
 89a:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 89d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8a0:	8b 55 ec             	mov    -0x14(%ebp),%edx
 8a3:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 8a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8a9:	a3 e8 0b 00 00       	mov    %eax,0xbe8
      return (void*)(p + 1);
 8ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8b1:	83 c0 08             	add    $0x8,%eax
 8b4:	eb 38                	jmp    8ee <malloc+0xde>
    }
    if(p == freep)
 8b6:	a1 e8 0b 00 00       	mov    0xbe8,%eax
 8bb:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 8be:	75 1b                	jne    8db <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 8c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
 8c3:	89 04 24             	mov    %eax,(%esp)
 8c6:	e8 ed fe ff ff       	call   7b8 <morecore>
 8cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
 8ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 8d2:	75 07                	jne    8db <malloc+0xcb>
        return 0;
 8d4:	b8 00 00 00 00       	mov    $0x0,%eax
 8d9:	eb 13                	jmp    8ee <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8db:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8de:	89 45 f0             	mov    %eax,-0x10(%ebp)
 8e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8e4:	8b 00                	mov    (%eax),%eax
 8e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 8e9:	e9 70 ff ff ff       	jmp    85e <malloc+0x4e>
}
 8ee:	c9                   	leave  
 8ef:	c3                   	ret    
