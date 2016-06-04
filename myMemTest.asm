
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
  1a:	e8 e9 03 00 00       	call   408 <sbrk>
  1f:	8b 54 24 1c          	mov    0x1c(%esp),%edx
  23:	89 04 95 c0 0b 00 00 	mov    %eax,0xbc0(,%edx,4)
		printf(1, "allocateing page #%d at address: %x\n", i, array[i]);
  2a:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  2e:	8b 04 85 c0 0b 00 00 	mov    0xbc0(,%eax,4),%eax
  35:	89 44 24 0c          	mov    %eax,0xc(%esp)
  39:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  3d:	89 44 24 08          	mov    %eax,0x8(%esp)
  41:	c7 44 24 04 cc 08 00 	movl   $0x8cc,0x4(%esp)
  48:	00 
  49:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  50:	e8 ab 04 00 00       	call   500 <printf>
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
  61:	c7 44 24 04 f1 08 00 	movl   $0x8f1,0x4(%esp)
  68:	00 
  69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  70:	e8 8b 04 00 00       	call   500 <printf>
	pid = fork();
  75:	e8 fe 02 00 00       	call   378 <fork>
  7a:	89 44 24 10          	mov    %eax,0x10(%esp)
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
  7e:	8b 44 24 10          	mov    0x10(%esp),%eax
  82:	89 44 24 08          	mov    %eax,0x8(%esp)
  86:	c7 44 24 04 fc 08 00 	movl   $0x8fc,0x4(%esp)
  8d:	00 
  8e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  95:	e8 66 04 00 00       	call   500 <printf>
	for(k = 0; k < 3; k++){
  9a:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
  a1:	00 
  a2:	eb 48                	jmp    ec <main+0xec>
		for ( i = 0; i < 10; ++i)
  a4:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  ab:	00 
  ac:	eb 32                	jmp    e0 <main+0xe0>
		{
			for ( j = 0; j < PGSIZE; ++j)
  ae:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  b5:	00 
  b6:	eb 19                	jmp    d1 <main+0xd1>
			{
				array[i][j] = 0;
  b8:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  bc:	8b 14 85 c0 0b 00 00 	mov    0xbc0(,%eax,4),%edx
  c3:	8b 44 24 18          	mov    0x18(%esp),%eax
  c7:	01 d0                	add    %edx,%eax
  c9:	c6 00 00             	movb   $0x0,(%eax)
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
		for ( i = 0; i < 10; ++i)
		{
			for ( j = 0; j < PGSIZE; ++j)
  cc:	83 44 24 18 01       	addl   $0x1,0x18(%esp)
  d1:	81 7c 24 18 ff 0f 00 	cmpl   $0xfff,0x18(%esp)
  d8:	00 
  d9:	7e dd                	jle    b8 <main+0xb8>
	printf(1,"forking\n");
	pid = fork();
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
		for ( i = 0; i < 10; ++i)
  db:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  e0:	83 7c 24 1c 09       	cmpl   $0x9,0x1c(%esp)
  e5:	7e c7                	jle    ae <main+0xae>
	}
	printf(1,"forking\n");
	pid = fork();
//using all pages to cause page faults
	printf(1,"pid %d starting writing to all pages\n",pid);
	for(k = 0; k < 3; k++){
  e7:	83 44 24 14 01       	addl   $0x1,0x14(%esp)
  ec:	83 7c 24 14 02       	cmpl   $0x2,0x14(%esp)
  f1:	7e b1                	jle    a4 <main+0xa4>
			{
				array[i][j] = 0;
			}
		}
	}
	if(pid != 0){//mother
  f3:	83 7c 24 10 00       	cmpl   $0x0,0x10(%esp)
  f8:	74 05                	je     ff <main+0xff>
		wait();
  fa:	e8 89 02 00 00       	call   388 <wait>
	}

	printf(1,"Finished Successfuly!!!\n");
  ff:	c7 44 24 04 22 09 00 	movl   $0x922,0x4(%esp)
 106:	00 
 107:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 10e:	e8 ed 03 00 00       	call   500 <printf>
	exit();
 113:	e8 68 02 00 00       	call   380 <exit>

00000118 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 118:	55                   	push   %ebp
 119:	89 e5                	mov    %esp,%ebp
 11b:	57                   	push   %edi
 11c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 11d:	8b 4d 08             	mov    0x8(%ebp),%ecx
 120:	8b 55 10             	mov    0x10(%ebp),%edx
 123:	8b 45 0c             	mov    0xc(%ebp),%eax
 126:	89 cb                	mov    %ecx,%ebx
 128:	89 df                	mov    %ebx,%edi
 12a:	89 d1                	mov    %edx,%ecx
 12c:	fc                   	cld    
 12d:	f3 aa                	rep stos %al,%es:(%edi)
 12f:	89 ca                	mov    %ecx,%edx
 131:	89 fb                	mov    %edi,%ebx
 133:	89 5d 08             	mov    %ebx,0x8(%ebp)
 136:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 139:	5b                   	pop    %ebx
 13a:	5f                   	pop    %edi
 13b:	5d                   	pop    %ebp
 13c:	c3                   	ret    

0000013d <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 13d:	55                   	push   %ebp
 13e:	89 e5                	mov    %esp,%ebp
 140:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 143:	8b 45 08             	mov    0x8(%ebp),%eax
 146:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 149:	90                   	nop
 14a:	8b 45 08             	mov    0x8(%ebp),%eax
 14d:	8d 50 01             	lea    0x1(%eax),%edx
 150:	89 55 08             	mov    %edx,0x8(%ebp)
 153:	8b 55 0c             	mov    0xc(%ebp),%edx
 156:	8d 4a 01             	lea    0x1(%edx),%ecx
 159:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 15c:	0f b6 12             	movzbl (%edx),%edx
 15f:	88 10                	mov    %dl,(%eax)
 161:	0f b6 00             	movzbl (%eax),%eax
 164:	84 c0                	test   %al,%al
 166:	75 e2                	jne    14a <strcpy+0xd>
    ;
  return os;
 168:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 16b:	c9                   	leave  
 16c:	c3                   	ret    

0000016d <strcmp>:

int
strcmp(const char *p, const char *q)
{
 16d:	55                   	push   %ebp
 16e:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 170:	eb 08                	jmp    17a <strcmp+0xd>
    p++, q++;
 172:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 176:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 17a:	8b 45 08             	mov    0x8(%ebp),%eax
 17d:	0f b6 00             	movzbl (%eax),%eax
 180:	84 c0                	test   %al,%al
 182:	74 10                	je     194 <strcmp+0x27>
 184:	8b 45 08             	mov    0x8(%ebp),%eax
 187:	0f b6 10             	movzbl (%eax),%edx
 18a:	8b 45 0c             	mov    0xc(%ebp),%eax
 18d:	0f b6 00             	movzbl (%eax),%eax
 190:	38 c2                	cmp    %al,%dl
 192:	74 de                	je     172 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 194:	8b 45 08             	mov    0x8(%ebp),%eax
 197:	0f b6 00             	movzbl (%eax),%eax
 19a:	0f b6 d0             	movzbl %al,%edx
 19d:	8b 45 0c             	mov    0xc(%ebp),%eax
 1a0:	0f b6 00             	movzbl (%eax),%eax
 1a3:	0f b6 c0             	movzbl %al,%eax
 1a6:	29 c2                	sub    %eax,%edx
 1a8:	89 d0                	mov    %edx,%eax
}
 1aa:	5d                   	pop    %ebp
 1ab:	c3                   	ret    

000001ac <strlen>:

uint
strlen(char *s)
{
 1ac:	55                   	push   %ebp
 1ad:	89 e5                	mov    %esp,%ebp
 1af:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 1b2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 1b9:	eb 04                	jmp    1bf <strlen+0x13>
 1bb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 1bf:	8b 55 fc             	mov    -0x4(%ebp),%edx
 1c2:	8b 45 08             	mov    0x8(%ebp),%eax
 1c5:	01 d0                	add    %edx,%eax
 1c7:	0f b6 00             	movzbl (%eax),%eax
 1ca:	84 c0                	test   %al,%al
 1cc:	75 ed                	jne    1bb <strlen+0xf>
    ;
  return n;
 1ce:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1d1:	c9                   	leave  
 1d2:	c3                   	ret    

000001d3 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1d3:	55                   	push   %ebp
 1d4:	89 e5                	mov    %esp,%ebp
 1d6:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 1d9:	8b 45 10             	mov    0x10(%ebp),%eax
 1dc:	89 44 24 08          	mov    %eax,0x8(%esp)
 1e0:	8b 45 0c             	mov    0xc(%ebp),%eax
 1e3:	89 44 24 04          	mov    %eax,0x4(%esp)
 1e7:	8b 45 08             	mov    0x8(%ebp),%eax
 1ea:	89 04 24             	mov    %eax,(%esp)
 1ed:	e8 26 ff ff ff       	call   118 <stosb>
  return dst;
 1f2:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1f5:	c9                   	leave  
 1f6:	c3                   	ret    

000001f7 <strchr>:

char*
strchr(const char *s, char c)
{
 1f7:	55                   	push   %ebp
 1f8:	89 e5                	mov    %esp,%ebp
 1fa:	83 ec 04             	sub    $0x4,%esp
 1fd:	8b 45 0c             	mov    0xc(%ebp),%eax
 200:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 203:	eb 14                	jmp    219 <strchr+0x22>
    if(*s == c)
 205:	8b 45 08             	mov    0x8(%ebp),%eax
 208:	0f b6 00             	movzbl (%eax),%eax
 20b:	3a 45 fc             	cmp    -0x4(%ebp),%al
 20e:	75 05                	jne    215 <strchr+0x1e>
      return (char*)s;
 210:	8b 45 08             	mov    0x8(%ebp),%eax
 213:	eb 13                	jmp    228 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 215:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 219:	8b 45 08             	mov    0x8(%ebp),%eax
 21c:	0f b6 00             	movzbl (%eax),%eax
 21f:	84 c0                	test   %al,%al
 221:	75 e2                	jne    205 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 223:	b8 00 00 00 00       	mov    $0x0,%eax
}
 228:	c9                   	leave  
 229:	c3                   	ret    

0000022a <gets>:

char*
gets(char *buf, int max)
{
 22a:	55                   	push   %ebp
 22b:	89 e5                	mov    %esp,%ebp
 22d:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 230:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 237:	eb 4c                	jmp    285 <gets+0x5b>
    cc = read(0, &c, 1);
 239:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 240:	00 
 241:	8d 45 ef             	lea    -0x11(%ebp),%eax
 244:	89 44 24 04          	mov    %eax,0x4(%esp)
 248:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 24f:	e8 44 01 00 00       	call   398 <read>
 254:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 257:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 25b:	7f 02                	jg     25f <gets+0x35>
      break;
 25d:	eb 31                	jmp    290 <gets+0x66>
    buf[i++] = c;
 25f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 262:	8d 50 01             	lea    0x1(%eax),%edx
 265:	89 55 f4             	mov    %edx,-0xc(%ebp)
 268:	89 c2                	mov    %eax,%edx
 26a:	8b 45 08             	mov    0x8(%ebp),%eax
 26d:	01 c2                	add    %eax,%edx
 26f:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 273:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 275:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 279:	3c 0a                	cmp    $0xa,%al
 27b:	74 13                	je     290 <gets+0x66>
 27d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 281:	3c 0d                	cmp    $0xd,%al
 283:	74 0b                	je     290 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 285:	8b 45 f4             	mov    -0xc(%ebp),%eax
 288:	83 c0 01             	add    $0x1,%eax
 28b:	3b 45 0c             	cmp    0xc(%ebp),%eax
 28e:	7c a9                	jl     239 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 290:	8b 55 f4             	mov    -0xc(%ebp),%edx
 293:	8b 45 08             	mov    0x8(%ebp),%eax
 296:	01 d0                	add    %edx,%eax
 298:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 29b:	8b 45 08             	mov    0x8(%ebp),%eax
}
 29e:	c9                   	leave  
 29f:	c3                   	ret    

000002a0 <stat>:

int
stat(char *n, struct stat *st)
{
 2a0:	55                   	push   %ebp
 2a1:	89 e5                	mov    %esp,%ebp
 2a3:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2a6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 2ad:	00 
 2ae:	8b 45 08             	mov    0x8(%ebp),%eax
 2b1:	89 04 24             	mov    %eax,(%esp)
 2b4:	e8 07 01 00 00       	call   3c0 <open>
 2b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 2bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 2c0:	79 07                	jns    2c9 <stat+0x29>
    return -1;
 2c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 2c7:	eb 23                	jmp    2ec <stat+0x4c>
  r = fstat(fd, st);
 2c9:	8b 45 0c             	mov    0xc(%ebp),%eax
 2cc:	89 44 24 04          	mov    %eax,0x4(%esp)
 2d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2d3:	89 04 24             	mov    %eax,(%esp)
 2d6:	e8 fd 00 00 00       	call   3d8 <fstat>
 2db:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 2de:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2e1:	89 04 24             	mov    %eax,(%esp)
 2e4:	e8 bf 00 00 00       	call   3a8 <close>
  return r;
 2e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 2ec:	c9                   	leave  
 2ed:	c3                   	ret    

000002ee <atoi>:

int
atoi(const char *s)
{
 2ee:	55                   	push   %ebp
 2ef:	89 e5                	mov    %esp,%ebp
 2f1:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 2f4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 2fb:	eb 25                	jmp    322 <atoi+0x34>
    n = n*10 + *s++ - '0';
 2fd:	8b 55 fc             	mov    -0x4(%ebp),%edx
 300:	89 d0                	mov    %edx,%eax
 302:	c1 e0 02             	shl    $0x2,%eax
 305:	01 d0                	add    %edx,%eax
 307:	01 c0                	add    %eax,%eax
 309:	89 c1                	mov    %eax,%ecx
 30b:	8b 45 08             	mov    0x8(%ebp),%eax
 30e:	8d 50 01             	lea    0x1(%eax),%edx
 311:	89 55 08             	mov    %edx,0x8(%ebp)
 314:	0f b6 00             	movzbl (%eax),%eax
 317:	0f be c0             	movsbl %al,%eax
 31a:	01 c8                	add    %ecx,%eax
 31c:	83 e8 30             	sub    $0x30,%eax
 31f:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 322:	8b 45 08             	mov    0x8(%ebp),%eax
 325:	0f b6 00             	movzbl (%eax),%eax
 328:	3c 2f                	cmp    $0x2f,%al
 32a:	7e 0a                	jle    336 <atoi+0x48>
 32c:	8b 45 08             	mov    0x8(%ebp),%eax
 32f:	0f b6 00             	movzbl (%eax),%eax
 332:	3c 39                	cmp    $0x39,%al
 334:	7e c7                	jle    2fd <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 336:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 339:	c9                   	leave  
 33a:	c3                   	ret    

0000033b <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 33b:	55                   	push   %ebp
 33c:	89 e5                	mov    %esp,%ebp
 33e:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 341:	8b 45 08             	mov    0x8(%ebp),%eax
 344:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 347:	8b 45 0c             	mov    0xc(%ebp),%eax
 34a:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 34d:	eb 17                	jmp    366 <memmove+0x2b>
    *dst++ = *src++;
 34f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 352:	8d 50 01             	lea    0x1(%eax),%edx
 355:	89 55 fc             	mov    %edx,-0x4(%ebp)
 358:	8b 55 f8             	mov    -0x8(%ebp),%edx
 35b:	8d 4a 01             	lea    0x1(%edx),%ecx
 35e:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 361:	0f b6 12             	movzbl (%edx),%edx
 364:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 366:	8b 45 10             	mov    0x10(%ebp),%eax
 369:	8d 50 ff             	lea    -0x1(%eax),%edx
 36c:	89 55 10             	mov    %edx,0x10(%ebp)
 36f:	85 c0                	test   %eax,%eax
 371:	7f dc                	jg     34f <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 373:	8b 45 08             	mov    0x8(%ebp),%eax
}
 376:	c9                   	leave  
 377:	c3                   	ret    

00000378 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 378:	b8 01 00 00 00       	mov    $0x1,%eax
 37d:	cd 40                	int    $0x40
 37f:	c3                   	ret    

00000380 <exit>:
SYSCALL(exit)
 380:	b8 02 00 00 00       	mov    $0x2,%eax
 385:	cd 40                	int    $0x40
 387:	c3                   	ret    

00000388 <wait>:
SYSCALL(wait)
 388:	b8 03 00 00 00       	mov    $0x3,%eax
 38d:	cd 40                	int    $0x40
 38f:	c3                   	ret    

00000390 <pipe>:
SYSCALL(pipe)
 390:	b8 04 00 00 00       	mov    $0x4,%eax
 395:	cd 40                	int    $0x40
 397:	c3                   	ret    

00000398 <read>:
SYSCALL(read)
 398:	b8 05 00 00 00       	mov    $0x5,%eax
 39d:	cd 40                	int    $0x40
 39f:	c3                   	ret    

000003a0 <write>:
SYSCALL(write)
 3a0:	b8 10 00 00 00       	mov    $0x10,%eax
 3a5:	cd 40                	int    $0x40
 3a7:	c3                   	ret    

000003a8 <close>:
SYSCALL(close)
 3a8:	b8 15 00 00 00       	mov    $0x15,%eax
 3ad:	cd 40                	int    $0x40
 3af:	c3                   	ret    

000003b0 <kill>:
SYSCALL(kill)
 3b0:	b8 06 00 00 00       	mov    $0x6,%eax
 3b5:	cd 40                	int    $0x40
 3b7:	c3                   	ret    

000003b8 <exec>:
SYSCALL(exec)
 3b8:	b8 07 00 00 00       	mov    $0x7,%eax
 3bd:	cd 40                	int    $0x40
 3bf:	c3                   	ret    

000003c0 <open>:
SYSCALL(open)
 3c0:	b8 0f 00 00 00       	mov    $0xf,%eax
 3c5:	cd 40                	int    $0x40
 3c7:	c3                   	ret    

000003c8 <mknod>:
SYSCALL(mknod)
 3c8:	b8 11 00 00 00       	mov    $0x11,%eax
 3cd:	cd 40                	int    $0x40
 3cf:	c3                   	ret    

000003d0 <unlink>:
SYSCALL(unlink)
 3d0:	b8 12 00 00 00       	mov    $0x12,%eax
 3d5:	cd 40                	int    $0x40
 3d7:	c3                   	ret    

000003d8 <fstat>:
SYSCALL(fstat)
 3d8:	b8 08 00 00 00       	mov    $0x8,%eax
 3dd:	cd 40                	int    $0x40
 3df:	c3                   	ret    

000003e0 <link>:
SYSCALL(link)
 3e0:	b8 13 00 00 00       	mov    $0x13,%eax
 3e5:	cd 40                	int    $0x40
 3e7:	c3                   	ret    

000003e8 <mkdir>:
SYSCALL(mkdir)
 3e8:	b8 14 00 00 00       	mov    $0x14,%eax
 3ed:	cd 40                	int    $0x40
 3ef:	c3                   	ret    

000003f0 <chdir>:
SYSCALL(chdir)
 3f0:	b8 09 00 00 00       	mov    $0x9,%eax
 3f5:	cd 40                	int    $0x40
 3f7:	c3                   	ret    

000003f8 <dup>:
SYSCALL(dup)
 3f8:	b8 0a 00 00 00       	mov    $0xa,%eax
 3fd:	cd 40                	int    $0x40
 3ff:	c3                   	ret    

00000400 <getpid>:
SYSCALL(getpid)
 400:	b8 0b 00 00 00       	mov    $0xb,%eax
 405:	cd 40                	int    $0x40
 407:	c3                   	ret    

00000408 <sbrk>:
SYSCALL(sbrk)
 408:	b8 0c 00 00 00       	mov    $0xc,%eax
 40d:	cd 40                	int    $0x40
 40f:	c3                   	ret    

00000410 <sleep>:
SYSCALL(sleep)
 410:	b8 0d 00 00 00       	mov    $0xd,%eax
 415:	cd 40                	int    $0x40
 417:	c3                   	ret    

00000418 <uptime>:
 418:	b8 0e 00 00 00       	mov    $0xe,%eax
 41d:	cd 40                	int    $0x40
 41f:	c3                   	ret    

00000420 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 420:	55                   	push   %ebp
 421:	89 e5                	mov    %esp,%ebp
 423:	83 ec 18             	sub    $0x18,%esp
 426:	8b 45 0c             	mov    0xc(%ebp),%eax
 429:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 42c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 433:	00 
 434:	8d 45 f4             	lea    -0xc(%ebp),%eax
 437:	89 44 24 04          	mov    %eax,0x4(%esp)
 43b:	8b 45 08             	mov    0x8(%ebp),%eax
 43e:	89 04 24             	mov    %eax,(%esp)
 441:	e8 5a ff ff ff       	call   3a0 <write>
}
 446:	c9                   	leave  
 447:	c3                   	ret    

00000448 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 448:	55                   	push   %ebp
 449:	89 e5                	mov    %esp,%ebp
 44b:	56                   	push   %esi
 44c:	53                   	push   %ebx
 44d:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 450:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 457:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 45b:	74 17                	je     474 <printint+0x2c>
 45d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 461:	79 11                	jns    474 <printint+0x2c>
    neg = 1;
 463:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 46a:	8b 45 0c             	mov    0xc(%ebp),%eax
 46d:	f7 d8                	neg    %eax
 46f:	89 45 ec             	mov    %eax,-0x14(%ebp)
 472:	eb 06                	jmp    47a <printint+0x32>
  } else {
    x = xx;
 474:	8b 45 0c             	mov    0xc(%ebp),%eax
 477:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 47a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 481:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 484:	8d 41 01             	lea    0x1(%ecx),%eax
 487:	89 45 f4             	mov    %eax,-0xc(%ebp)
 48a:	8b 5d 10             	mov    0x10(%ebp),%ebx
 48d:	8b 45 ec             	mov    -0x14(%ebp),%eax
 490:	ba 00 00 00 00       	mov    $0x0,%edx
 495:	f7 f3                	div    %ebx
 497:	89 d0                	mov    %edx,%eax
 499:	0f b6 80 88 0b 00 00 	movzbl 0xb88(%eax),%eax
 4a0:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 4a4:	8b 75 10             	mov    0x10(%ebp),%esi
 4a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4aa:	ba 00 00 00 00       	mov    $0x0,%edx
 4af:	f7 f6                	div    %esi
 4b1:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4b4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4b8:	75 c7                	jne    481 <printint+0x39>
  if(neg)
 4ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 4be:	74 10                	je     4d0 <printint+0x88>
    buf[i++] = '-';
 4c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4c3:	8d 50 01             	lea    0x1(%eax),%edx
 4c6:	89 55 f4             	mov    %edx,-0xc(%ebp)
 4c9:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 4ce:	eb 1f                	jmp    4ef <printint+0xa7>
 4d0:	eb 1d                	jmp    4ef <printint+0xa7>
    putc(fd, buf[i]);
 4d2:	8d 55 dc             	lea    -0x24(%ebp),%edx
 4d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4d8:	01 d0                	add    %edx,%eax
 4da:	0f b6 00             	movzbl (%eax),%eax
 4dd:	0f be c0             	movsbl %al,%eax
 4e0:	89 44 24 04          	mov    %eax,0x4(%esp)
 4e4:	8b 45 08             	mov    0x8(%ebp),%eax
 4e7:	89 04 24             	mov    %eax,(%esp)
 4ea:	e8 31 ff ff ff       	call   420 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 4ef:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 4f3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4f7:	79 d9                	jns    4d2 <printint+0x8a>
    putc(fd, buf[i]);
}
 4f9:	83 c4 30             	add    $0x30,%esp
 4fc:	5b                   	pop    %ebx
 4fd:	5e                   	pop    %esi
 4fe:	5d                   	pop    %ebp
 4ff:	c3                   	ret    

00000500 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 500:	55                   	push   %ebp
 501:	89 e5                	mov    %esp,%ebp
 503:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 506:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 50d:	8d 45 0c             	lea    0xc(%ebp),%eax
 510:	83 c0 04             	add    $0x4,%eax
 513:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 516:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 51d:	e9 7c 01 00 00       	jmp    69e <printf+0x19e>
    c = fmt[i] & 0xff;
 522:	8b 55 0c             	mov    0xc(%ebp),%edx
 525:	8b 45 f0             	mov    -0x10(%ebp),%eax
 528:	01 d0                	add    %edx,%eax
 52a:	0f b6 00             	movzbl (%eax),%eax
 52d:	0f be c0             	movsbl %al,%eax
 530:	25 ff 00 00 00       	and    $0xff,%eax
 535:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 538:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 53c:	75 2c                	jne    56a <printf+0x6a>
      if(c == '%'){
 53e:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 542:	75 0c                	jne    550 <printf+0x50>
        state = '%';
 544:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 54b:	e9 4a 01 00 00       	jmp    69a <printf+0x19a>
      } else {
        putc(fd, c);
 550:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 553:	0f be c0             	movsbl %al,%eax
 556:	89 44 24 04          	mov    %eax,0x4(%esp)
 55a:	8b 45 08             	mov    0x8(%ebp),%eax
 55d:	89 04 24             	mov    %eax,(%esp)
 560:	e8 bb fe ff ff       	call   420 <putc>
 565:	e9 30 01 00 00       	jmp    69a <printf+0x19a>
      }
    } else if(state == '%'){
 56a:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 56e:	0f 85 26 01 00 00    	jne    69a <printf+0x19a>
      if(c == 'd'){
 574:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 578:	75 2d                	jne    5a7 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 57a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 57d:	8b 00                	mov    (%eax),%eax
 57f:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 586:	00 
 587:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 58e:	00 
 58f:	89 44 24 04          	mov    %eax,0x4(%esp)
 593:	8b 45 08             	mov    0x8(%ebp),%eax
 596:	89 04 24             	mov    %eax,(%esp)
 599:	e8 aa fe ff ff       	call   448 <printint>
        ap++;
 59e:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5a2:	e9 ec 00 00 00       	jmp    693 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 5a7:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 5ab:	74 06                	je     5b3 <printf+0xb3>
 5ad:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 5b1:	75 2d                	jne    5e0 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 5b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5b6:	8b 00                	mov    (%eax),%eax
 5b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 5bf:	00 
 5c0:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 5c7:	00 
 5c8:	89 44 24 04          	mov    %eax,0x4(%esp)
 5cc:	8b 45 08             	mov    0x8(%ebp),%eax
 5cf:	89 04 24             	mov    %eax,(%esp)
 5d2:	e8 71 fe ff ff       	call   448 <printint>
        ap++;
 5d7:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5db:	e9 b3 00 00 00       	jmp    693 <printf+0x193>
      } else if(c == 's'){
 5e0:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 5e4:	75 45                	jne    62b <printf+0x12b>
        s = (char*)*ap;
 5e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5e9:	8b 00                	mov    (%eax),%eax
 5eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 5ee:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 5f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 5f6:	75 09                	jne    601 <printf+0x101>
          s = "(null)";
 5f8:	c7 45 f4 3b 09 00 00 	movl   $0x93b,-0xc(%ebp)
        while(*s != 0){
 5ff:	eb 1e                	jmp    61f <printf+0x11f>
 601:	eb 1c                	jmp    61f <printf+0x11f>
          putc(fd, *s);
 603:	8b 45 f4             	mov    -0xc(%ebp),%eax
 606:	0f b6 00             	movzbl (%eax),%eax
 609:	0f be c0             	movsbl %al,%eax
 60c:	89 44 24 04          	mov    %eax,0x4(%esp)
 610:	8b 45 08             	mov    0x8(%ebp),%eax
 613:	89 04 24             	mov    %eax,(%esp)
 616:	e8 05 fe ff ff       	call   420 <putc>
          s++;
 61b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 61f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 622:	0f b6 00             	movzbl (%eax),%eax
 625:	84 c0                	test   %al,%al
 627:	75 da                	jne    603 <printf+0x103>
 629:	eb 68                	jmp    693 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 62b:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 62f:	75 1d                	jne    64e <printf+0x14e>
        putc(fd, *ap);
 631:	8b 45 e8             	mov    -0x18(%ebp),%eax
 634:	8b 00                	mov    (%eax),%eax
 636:	0f be c0             	movsbl %al,%eax
 639:	89 44 24 04          	mov    %eax,0x4(%esp)
 63d:	8b 45 08             	mov    0x8(%ebp),%eax
 640:	89 04 24             	mov    %eax,(%esp)
 643:	e8 d8 fd ff ff       	call   420 <putc>
        ap++;
 648:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 64c:	eb 45                	jmp    693 <printf+0x193>
      } else if(c == '%'){
 64e:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 652:	75 17                	jne    66b <printf+0x16b>
        putc(fd, c);
 654:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 657:	0f be c0             	movsbl %al,%eax
 65a:	89 44 24 04          	mov    %eax,0x4(%esp)
 65e:	8b 45 08             	mov    0x8(%ebp),%eax
 661:	89 04 24             	mov    %eax,(%esp)
 664:	e8 b7 fd ff ff       	call   420 <putc>
 669:	eb 28                	jmp    693 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 66b:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 672:	00 
 673:	8b 45 08             	mov    0x8(%ebp),%eax
 676:	89 04 24             	mov    %eax,(%esp)
 679:	e8 a2 fd ff ff       	call   420 <putc>
        putc(fd, c);
 67e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 681:	0f be c0             	movsbl %al,%eax
 684:	89 44 24 04          	mov    %eax,0x4(%esp)
 688:	8b 45 08             	mov    0x8(%ebp),%eax
 68b:	89 04 24             	mov    %eax,(%esp)
 68e:	e8 8d fd ff ff       	call   420 <putc>
      }
      state = 0;
 693:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 69a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 69e:	8b 55 0c             	mov    0xc(%ebp),%edx
 6a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6a4:	01 d0                	add    %edx,%eax
 6a6:	0f b6 00             	movzbl (%eax),%eax
 6a9:	84 c0                	test   %al,%al
 6ab:	0f 85 71 fe ff ff    	jne    522 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 6b1:	c9                   	leave  
 6b2:	c3                   	ret    

000006b3 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b3:	55                   	push   %ebp
 6b4:	89 e5                	mov    %esp,%ebp
 6b6:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b9:	8b 45 08             	mov    0x8(%ebp),%eax
 6bc:	83 e8 08             	sub    $0x8,%eax
 6bf:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6c2:	a1 a8 0b 00 00       	mov    0xba8,%eax
 6c7:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6ca:	eb 24                	jmp    6f0 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6cf:	8b 00                	mov    (%eax),%eax
 6d1:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6d4:	77 12                	ja     6e8 <free+0x35>
 6d6:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6d9:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6dc:	77 24                	ja     702 <free+0x4f>
 6de:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6e1:	8b 00                	mov    (%eax),%eax
 6e3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6e6:	77 1a                	ja     702 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6eb:	8b 00                	mov    (%eax),%eax
 6ed:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6f3:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6f6:	76 d4                	jbe    6cc <free+0x19>
 6f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6fb:	8b 00                	mov    (%eax),%eax
 6fd:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 700:	76 ca                	jbe    6cc <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 702:	8b 45 f8             	mov    -0x8(%ebp),%eax
 705:	8b 40 04             	mov    0x4(%eax),%eax
 708:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 70f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 712:	01 c2                	add    %eax,%edx
 714:	8b 45 fc             	mov    -0x4(%ebp),%eax
 717:	8b 00                	mov    (%eax),%eax
 719:	39 c2                	cmp    %eax,%edx
 71b:	75 24                	jne    741 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 71d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 720:	8b 50 04             	mov    0x4(%eax),%edx
 723:	8b 45 fc             	mov    -0x4(%ebp),%eax
 726:	8b 00                	mov    (%eax),%eax
 728:	8b 40 04             	mov    0x4(%eax),%eax
 72b:	01 c2                	add    %eax,%edx
 72d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 730:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 733:	8b 45 fc             	mov    -0x4(%ebp),%eax
 736:	8b 00                	mov    (%eax),%eax
 738:	8b 10                	mov    (%eax),%edx
 73a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 73d:	89 10                	mov    %edx,(%eax)
 73f:	eb 0a                	jmp    74b <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 741:	8b 45 fc             	mov    -0x4(%ebp),%eax
 744:	8b 10                	mov    (%eax),%edx
 746:	8b 45 f8             	mov    -0x8(%ebp),%eax
 749:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 74b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74e:	8b 40 04             	mov    0x4(%eax),%eax
 751:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 758:	8b 45 fc             	mov    -0x4(%ebp),%eax
 75b:	01 d0                	add    %edx,%eax
 75d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 760:	75 20                	jne    782 <free+0xcf>
    p->s.size += bp->s.size;
 762:	8b 45 fc             	mov    -0x4(%ebp),%eax
 765:	8b 50 04             	mov    0x4(%eax),%edx
 768:	8b 45 f8             	mov    -0x8(%ebp),%eax
 76b:	8b 40 04             	mov    0x4(%eax),%eax
 76e:	01 c2                	add    %eax,%edx
 770:	8b 45 fc             	mov    -0x4(%ebp),%eax
 773:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 776:	8b 45 f8             	mov    -0x8(%ebp),%eax
 779:	8b 10                	mov    (%eax),%edx
 77b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 77e:	89 10                	mov    %edx,(%eax)
 780:	eb 08                	jmp    78a <free+0xd7>
  } else
    p->s.ptr = bp;
 782:	8b 45 fc             	mov    -0x4(%ebp),%eax
 785:	8b 55 f8             	mov    -0x8(%ebp),%edx
 788:	89 10                	mov    %edx,(%eax)
  freep = p;
 78a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 78d:	a3 a8 0b 00 00       	mov    %eax,0xba8
}
 792:	c9                   	leave  
 793:	c3                   	ret    

00000794 <morecore>:

static Header*
morecore(uint nu)
{
 794:	55                   	push   %ebp
 795:	89 e5                	mov    %esp,%ebp
 797:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 79a:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 7a1:	77 07                	ja     7aa <morecore+0x16>
    nu = 4096;
 7a3:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 7aa:	8b 45 08             	mov    0x8(%ebp),%eax
 7ad:	c1 e0 03             	shl    $0x3,%eax
 7b0:	89 04 24             	mov    %eax,(%esp)
 7b3:	e8 50 fc ff ff       	call   408 <sbrk>
 7b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 7bb:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 7bf:	75 07                	jne    7c8 <morecore+0x34>
    return 0;
 7c1:	b8 00 00 00 00       	mov    $0x0,%eax
 7c6:	eb 22                	jmp    7ea <morecore+0x56>
  hp = (Header*)p;
 7c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 7ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7d1:	8b 55 08             	mov    0x8(%ebp),%edx
 7d4:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 7d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7da:	83 c0 08             	add    $0x8,%eax
 7dd:	89 04 24             	mov    %eax,(%esp)
 7e0:	e8 ce fe ff ff       	call   6b3 <free>
  return freep;
 7e5:	a1 a8 0b 00 00       	mov    0xba8,%eax
}
 7ea:	c9                   	leave  
 7eb:	c3                   	ret    

000007ec <malloc>:

void*
malloc(uint nbytes)
{
 7ec:	55                   	push   %ebp
 7ed:	89 e5                	mov    %esp,%ebp
 7ef:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7f2:	8b 45 08             	mov    0x8(%ebp),%eax
 7f5:	83 c0 07             	add    $0x7,%eax
 7f8:	c1 e8 03             	shr    $0x3,%eax
 7fb:	83 c0 01             	add    $0x1,%eax
 7fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 801:	a1 a8 0b 00 00       	mov    0xba8,%eax
 806:	89 45 f0             	mov    %eax,-0x10(%ebp)
 809:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 80d:	75 23                	jne    832 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 80f:	c7 45 f0 a0 0b 00 00 	movl   $0xba0,-0x10(%ebp)
 816:	8b 45 f0             	mov    -0x10(%ebp),%eax
 819:	a3 a8 0b 00 00       	mov    %eax,0xba8
 81e:	a1 a8 0b 00 00       	mov    0xba8,%eax
 823:	a3 a0 0b 00 00       	mov    %eax,0xba0
    base.s.size = 0;
 828:	c7 05 a4 0b 00 00 00 	movl   $0x0,0xba4
 82f:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 832:	8b 45 f0             	mov    -0x10(%ebp),%eax
 835:	8b 00                	mov    (%eax),%eax
 837:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 83a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 83d:	8b 40 04             	mov    0x4(%eax),%eax
 840:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 843:	72 4d                	jb     892 <malloc+0xa6>
      if(p->s.size == nunits)
 845:	8b 45 f4             	mov    -0xc(%ebp),%eax
 848:	8b 40 04             	mov    0x4(%eax),%eax
 84b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 84e:	75 0c                	jne    85c <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 850:	8b 45 f4             	mov    -0xc(%ebp),%eax
 853:	8b 10                	mov    (%eax),%edx
 855:	8b 45 f0             	mov    -0x10(%ebp),%eax
 858:	89 10                	mov    %edx,(%eax)
 85a:	eb 26                	jmp    882 <malloc+0x96>
      else {
        p->s.size -= nunits;
 85c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 85f:	8b 40 04             	mov    0x4(%eax),%eax
 862:	2b 45 ec             	sub    -0x14(%ebp),%eax
 865:	89 c2                	mov    %eax,%edx
 867:	8b 45 f4             	mov    -0xc(%ebp),%eax
 86a:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 86d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 870:	8b 40 04             	mov    0x4(%eax),%eax
 873:	c1 e0 03             	shl    $0x3,%eax
 876:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 879:	8b 45 f4             	mov    -0xc(%ebp),%eax
 87c:	8b 55 ec             	mov    -0x14(%ebp),%edx
 87f:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 882:	8b 45 f0             	mov    -0x10(%ebp),%eax
 885:	a3 a8 0b 00 00       	mov    %eax,0xba8
      return (void*)(p + 1);
 88a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 88d:	83 c0 08             	add    $0x8,%eax
 890:	eb 38                	jmp    8ca <malloc+0xde>
    }
    if(p == freep)
 892:	a1 a8 0b 00 00       	mov    0xba8,%eax
 897:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 89a:	75 1b                	jne    8b7 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 89c:	8b 45 ec             	mov    -0x14(%ebp),%eax
 89f:	89 04 24             	mov    %eax,(%esp)
 8a2:	e8 ed fe ff ff       	call   794 <morecore>
 8a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
 8aa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 8ae:	75 07                	jne    8b7 <malloc+0xcb>
        return 0;
 8b0:	b8 00 00 00 00       	mov    $0x0,%eax
 8b5:	eb 13                	jmp    8ca <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
 8bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8c0:	8b 00                	mov    (%eax),%eax
 8c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 8c5:	e9 70 ff ff ff       	jmp    83a <malloc+0x4e>
}
 8ca:	c9                   	leave  
 8cb:	c3                   	ret    
