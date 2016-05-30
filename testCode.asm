
_testCode:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:

char* m1[COUNT];

volatile int
main(int argc, char *argv[])
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 20             	sub    $0x20,%esp

int i,j;

//creating 'COUNT' pages
for (i = 0; i < COUNT ; ++i)
   9:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  10:	00 
  11:	eb 47                	jmp    5a <main+0x5a>
{
m1[i] = sbrk(PGSIZE);
  13:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
  1a:	e8 8e 03 00 00       	call   3ad <sbrk>
  1f:	8b 54 24 1c          	mov    0x1c(%esp),%edx
  23:	89 04 95 40 0b 00 00 	mov    %eax,0xb40(,%edx,4)
printf(1, "allocated page #%d at address: %x\n", i, m1[i]);
  2a:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  2e:	8b 04 85 40 0b 00 00 	mov    0xb40(,%eax,4),%eax
  35:	89 44 24 0c          	mov    %eax,0xc(%esp)
  39:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  3d:	89 44 24 08          	mov    %eax,0x8(%esp)
  41:	c7 44 24 04 74 08 00 	movl   $0x874,0x4(%esp)
  48:	00 
  49:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  50:	e8 50 04 00 00       	call   4a5 <printf>
{

int i,j;

//creating 'COUNT' pages
for (i = 0; i < COUNT ; ++i)
  55:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  5a:	83 7c 24 1c 13       	cmpl   $0x13,0x1c(%esp)
  5f:	7e b2                	jle    13 <main+0x13>
m1[i] = sbrk(PGSIZE);
printf(1, "allocated page #%d at address: %x\n", i, m1[i]);
}

//using all pages
for ( i = 0; i < COUNT; ++i)
  61:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  68:	00 
  69:	eb 32                	jmp    9d <main+0x9d>
{
for ( j = 0; j < PGSIZE; ++j)
  6b:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
  72:	00 
  73:	eb 19                	jmp    8e <main+0x8e>
{
m1[i][j] = 1;
  75:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  79:	8b 14 85 40 0b 00 00 	mov    0xb40(,%eax,4),%edx
  80:	8b 44 24 18          	mov    0x18(%esp),%eax
  84:	01 d0                	add    %edx,%eax
  86:	c6 00 01             	movb   $0x1,(%eax)
}

//using all pages
for ( i = 0; i < COUNT; ++i)
{
for ( j = 0; j < PGSIZE; ++j)
  89:	83 44 24 18 01       	addl   $0x1,0x18(%esp)
  8e:	81 7c 24 18 ff 0f 00 	cmpl   $0xfff,0x18(%esp)
  95:	00 
  96:	7e dd                	jle    75 <main+0x75>
m1[i] = sbrk(PGSIZE);
printf(1, "allocated page #%d at address: %x\n", i, m1[i]);
}

//using all pages
for ( i = 0; i < COUNT; ++i)
  98:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  9d:	83 7c 24 1c 13       	cmpl   $0x13,0x1c(%esp)
  a2:	7e c7                	jle    6b <main+0x6b>
for ( j = 0; j < PGSIZE; ++j)
{
m1[i][j] = 1;
}
}
printf(1,"Finished Successfuly!!!\n");
  a4:	c7 44 24 04 97 08 00 	movl   $0x897,0x4(%esp)
  ab:	00 
  ac:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  b3:	e8 ed 03 00 00       	call   4a5 <printf>
exit();
  b8:	e8 68 02 00 00       	call   325 <exit>

000000bd <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  bd:	55                   	push   %ebp
  be:	89 e5                	mov    %esp,%ebp
  c0:	57                   	push   %edi
  c1:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  c5:	8b 55 10             	mov    0x10(%ebp),%edx
  c8:	8b 45 0c             	mov    0xc(%ebp),%eax
  cb:	89 cb                	mov    %ecx,%ebx
  cd:	89 df                	mov    %ebx,%edi
  cf:	89 d1                	mov    %edx,%ecx
  d1:	fc                   	cld    
  d2:	f3 aa                	rep stos %al,%es:(%edi)
  d4:	89 ca                	mov    %ecx,%edx
  d6:	89 fb                	mov    %edi,%ebx
  d8:	89 5d 08             	mov    %ebx,0x8(%ebp)
  db:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  de:	5b                   	pop    %ebx
  df:	5f                   	pop    %edi
  e0:	5d                   	pop    %ebp
  e1:	c3                   	ret    

000000e2 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  e2:	55                   	push   %ebp
  e3:	89 e5                	mov    %esp,%ebp
  e5:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  e8:	8b 45 08             	mov    0x8(%ebp),%eax
  eb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  ee:	90                   	nop
  ef:	8b 45 08             	mov    0x8(%ebp),%eax
  f2:	8d 50 01             	lea    0x1(%eax),%edx
  f5:	89 55 08             	mov    %edx,0x8(%ebp)
  f8:	8b 55 0c             	mov    0xc(%ebp),%edx
  fb:	8d 4a 01             	lea    0x1(%edx),%ecx
  fe:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 101:	0f b6 12             	movzbl (%edx),%edx
 104:	88 10                	mov    %dl,(%eax)
 106:	0f b6 00             	movzbl (%eax),%eax
 109:	84 c0                	test   %al,%al
 10b:	75 e2                	jne    ef <strcpy+0xd>
    ;
  return os;
 10d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 110:	c9                   	leave  
 111:	c3                   	ret    

00000112 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 112:	55                   	push   %ebp
 113:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 115:	eb 08                	jmp    11f <strcmp+0xd>
    p++, q++;
 117:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 11b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 11f:	8b 45 08             	mov    0x8(%ebp),%eax
 122:	0f b6 00             	movzbl (%eax),%eax
 125:	84 c0                	test   %al,%al
 127:	74 10                	je     139 <strcmp+0x27>
 129:	8b 45 08             	mov    0x8(%ebp),%eax
 12c:	0f b6 10             	movzbl (%eax),%edx
 12f:	8b 45 0c             	mov    0xc(%ebp),%eax
 132:	0f b6 00             	movzbl (%eax),%eax
 135:	38 c2                	cmp    %al,%dl
 137:	74 de                	je     117 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 139:	8b 45 08             	mov    0x8(%ebp),%eax
 13c:	0f b6 00             	movzbl (%eax),%eax
 13f:	0f b6 d0             	movzbl %al,%edx
 142:	8b 45 0c             	mov    0xc(%ebp),%eax
 145:	0f b6 00             	movzbl (%eax),%eax
 148:	0f b6 c0             	movzbl %al,%eax
 14b:	29 c2                	sub    %eax,%edx
 14d:	89 d0                	mov    %edx,%eax
}
 14f:	5d                   	pop    %ebp
 150:	c3                   	ret    

00000151 <strlen>:

uint
strlen(char *s)
{
 151:	55                   	push   %ebp
 152:	89 e5                	mov    %esp,%ebp
 154:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 157:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 15e:	eb 04                	jmp    164 <strlen+0x13>
 160:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 164:	8b 55 fc             	mov    -0x4(%ebp),%edx
 167:	8b 45 08             	mov    0x8(%ebp),%eax
 16a:	01 d0                	add    %edx,%eax
 16c:	0f b6 00             	movzbl (%eax),%eax
 16f:	84 c0                	test   %al,%al
 171:	75 ed                	jne    160 <strlen+0xf>
    ;
  return n;
 173:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 176:	c9                   	leave  
 177:	c3                   	ret    

00000178 <memset>:

void*
memset(void *dst, int c, uint n)
{
 178:	55                   	push   %ebp
 179:	89 e5                	mov    %esp,%ebp
 17b:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 17e:	8b 45 10             	mov    0x10(%ebp),%eax
 181:	89 44 24 08          	mov    %eax,0x8(%esp)
 185:	8b 45 0c             	mov    0xc(%ebp),%eax
 188:	89 44 24 04          	mov    %eax,0x4(%esp)
 18c:	8b 45 08             	mov    0x8(%ebp),%eax
 18f:	89 04 24             	mov    %eax,(%esp)
 192:	e8 26 ff ff ff       	call   bd <stosb>
  return dst;
 197:	8b 45 08             	mov    0x8(%ebp),%eax
}
 19a:	c9                   	leave  
 19b:	c3                   	ret    

0000019c <strchr>:

char*
strchr(const char *s, char c)
{
 19c:	55                   	push   %ebp
 19d:	89 e5                	mov    %esp,%ebp
 19f:	83 ec 04             	sub    $0x4,%esp
 1a2:	8b 45 0c             	mov    0xc(%ebp),%eax
 1a5:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 1a8:	eb 14                	jmp    1be <strchr+0x22>
    if(*s == c)
 1aa:	8b 45 08             	mov    0x8(%ebp),%eax
 1ad:	0f b6 00             	movzbl (%eax),%eax
 1b0:	3a 45 fc             	cmp    -0x4(%ebp),%al
 1b3:	75 05                	jne    1ba <strchr+0x1e>
      return (char*)s;
 1b5:	8b 45 08             	mov    0x8(%ebp),%eax
 1b8:	eb 13                	jmp    1cd <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 1ba:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 1be:	8b 45 08             	mov    0x8(%ebp),%eax
 1c1:	0f b6 00             	movzbl (%eax),%eax
 1c4:	84 c0                	test   %al,%al
 1c6:	75 e2                	jne    1aa <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 1c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
 1cd:	c9                   	leave  
 1ce:	c3                   	ret    

000001cf <gets>:

char*
gets(char *buf, int max)
{
 1cf:	55                   	push   %ebp
 1d0:	89 e5                	mov    %esp,%ebp
 1d2:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 1dc:	eb 4c                	jmp    22a <gets+0x5b>
    cc = read(0, &c, 1);
 1de:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 1e5:	00 
 1e6:	8d 45 ef             	lea    -0x11(%ebp),%eax
 1e9:	89 44 24 04          	mov    %eax,0x4(%esp)
 1ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 1f4:	e8 44 01 00 00       	call   33d <read>
 1f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 1fc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 200:	7f 02                	jg     204 <gets+0x35>
      break;
 202:	eb 31                	jmp    235 <gets+0x66>
    buf[i++] = c;
 204:	8b 45 f4             	mov    -0xc(%ebp),%eax
 207:	8d 50 01             	lea    0x1(%eax),%edx
 20a:	89 55 f4             	mov    %edx,-0xc(%ebp)
 20d:	89 c2                	mov    %eax,%edx
 20f:	8b 45 08             	mov    0x8(%ebp),%eax
 212:	01 c2                	add    %eax,%edx
 214:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 218:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 21a:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 21e:	3c 0a                	cmp    $0xa,%al
 220:	74 13                	je     235 <gets+0x66>
 222:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 226:	3c 0d                	cmp    $0xd,%al
 228:	74 0b                	je     235 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 22a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 22d:	83 c0 01             	add    $0x1,%eax
 230:	3b 45 0c             	cmp    0xc(%ebp),%eax
 233:	7c a9                	jl     1de <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 235:	8b 55 f4             	mov    -0xc(%ebp),%edx
 238:	8b 45 08             	mov    0x8(%ebp),%eax
 23b:	01 d0                	add    %edx,%eax
 23d:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 240:	8b 45 08             	mov    0x8(%ebp),%eax
}
 243:	c9                   	leave  
 244:	c3                   	ret    

00000245 <stat>:

int
stat(char *n, struct stat *st)
{
 245:	55                   	push   %ebp
 246:	89 e5                	mov    %esp,%ebp
 248:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 24b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 252:	00 
 253:	8b 45 08             	mov    0x8(%ebp),%eax
 256:	89 04 24             	mov    %eax,(%esp)
 259:	e8 07 01 00 00       	call   365 <open>
 25e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 261:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 265:	79 07                	jns    26e <stat+0x29>
    return -1;
 267:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 26c:	eb 23                	jmp    291 <stat+0x4c>
  r = fstat(fd, st);
 26e:	8b 45 0c             	mov    0xc(%ebp),%eax
 271:	89 44 24 04          	mov    %eax,0x4(%esp)
 275:	8b 45 f4             	mov    -0xc(%ebp),%eax
 278:	89 04 24             	mov    %eax,(%esp)
 27b:	e8 fd 00 00 00       	call   37d <fstat>
 280:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 283:	8b 45 f4             	mov    -0xc(%ebp),%eax
 286:	89 04 24             	mov    %eax,(%esp)
 289:	e8 bf 00 00 00       	call   34d <close>
  return r;
 28e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 291:	c9                   	leave  
 292:	c3                   	ret    

00000293 <atoi>:

int
atoi(const char *s)
{
 293:	55                   	push   %ebp
 294:	89 e5                	mov    %esp,%ebp
 296:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 299:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 2a0:	eb 25                	jmp    2c7 <atoi+0x34>
    n = n*10 + *s++ - '0';
 2a2:	8b 55 fc             	mov    -0x4(%ebp),%edx
 2a5:	89 d0                	mov    %edx,%eax
 2a7:	c1 e0 02             	shl    $0x2,%eax
 2aa:	01 d0                	add    %edx,%eax
 2ac:	01 c0                	add    %eax,%eax
 2ae:	89 c1                	mov    %eax,%ecx
 2b0:	8b 45 08             	mov    0x8(%ebp),%eax
 2b3:	8d 50 01             	lea    0x1(%eax),%edx
 2b6:	89 55 08             	mov    %edx,0x8(%ebp)
 2b9:	0f b6 00             	movzbl (%eax),%eax
 2bc:	0f be c0             	movsbl %al,%eax
 2bf:	01 c8                	add    %ecx,%eax
 2c1:	83 e8 30             	sub    $0x30,%eax
 2c4:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2c7:	8b 45 08             	mov    0x8(%ebp),%eax
 2ca:	0f b6 00             	movzbl (%eax),%eax
 2cd:	3c 2f                	cmp    $0x2f,%al
 2cf:	7e 0a                	jle    2db <atoi+0x48>
 2d1:	8b 45 08             	mov    0x8(%ebp),%eax
 2d4:	0f b6 00             	movzbl (%eax),%eax
 2d7:	3c 39                	cmp    $0x39,%al
 2d9:	7e c7                	jle    2a2 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 2db:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 2de:	c9                   	leave  
 2df:	c3                   	ret    

000002e0 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 2e0:	55                   	push   %ebp
 2e1:	89 e5                	mov    %esp,%ebp
 2e3:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 2e6:	8b 45 08             	mov    0x8(%ebp),%eax
 2e9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 2ec:	8b 45 0c             	mov    0xc(%ebp),%eax
 2ef:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 2f2:	eb 17                	jmp    30b <memmove+0x2b>
    *dst++ = *src++;
 2f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 2f7:	8d 50 01             	lea    0x1(%eax),%edx
 2fa:	89 55 fc             	mov    %edx,-0x4(%ebp)
 2fd:	8b 55 f8             	mov    -0x8(%ebp),%edx
 300:	8d 4a 01             	lea    0x1(%edx),%ecx
 303:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 306:	0f b6 12             	movzbl (%edx),%edx
 309:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 30b:	8b 45 10             	mov    0x10(%ebp),%eax
 30e:	8d 50 ff             	lea    -0x1(%eax),%edx
 311:	89 55 10             	mov    %edx,0x10(%ebp)
 314:	85 c0                	test   %eax,%eax
 316:	7f dc                	jg     2f4 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 318:	8b 45 08             	mov    0x8(%ebp),%eax
}
 31b:	c9                   	leave  
 31c:	c3                   	ret    

0000031d <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 31d:	b8 01 00 00 00       	mov    $0x1,%eax
 322:	cd 40                	int    $0x40
 324:	c3                   	ret    

00000325 <exit>:
SYSCALL(exit)
 325:	b8 02 00 00 00       	mov    $0x2,%eax
 32a:	cd 40                	int    $0x40
 32c:	c3                   	ret    

0000032d <wait>:
SYSCALL(wait)
 32d:	b8 03 00 00 00       	mov    $0x3,%eax
 332:	cd 40                	int    $0x40
 334:	c3                   	ret    

00000335 <pipe>:
SYSCALL(pipe)
 335:	b8 04 00 00 00       	mov    $0x4,%eax
 33a:	cd 40                	int    $0x40
 33c:	c3                   	ret    

0000033d <read>:
SYSCALL(read)
 33d:	b8 05 00 00 00       	mov    $0x5,%eax
 342:	cd 40                	int    $0x40
 344:	c3                   	ret    

00000345 <write>:
SYSCALL(write)
 345:	b8 10 00 00 00       	mov    $0x10,%eax
 34a:	cd 40                	int    $0x40
 34c:	c3                   	ret    

0000034d <close>:
SYSCALL(close)
 34d:	b8 15 00 00 00       	mov    $0x15,%eax
 352:	cd 40                	int    $0x40
 354:	c3                   	ret    

00000355 <kill>:
SYSCALL(kill)
 355:	b8 06 00 00 00       	mov    $0x6,%eax
 35a:	cd 40                	int    $0x40
 35c:	c3                   	ret    

0000035d <exec>:
SYSCALL(exec)
 35d:	b8 07 00 00 00       	mov    $0x7,%eax
 362:	cd 40                	int    $0x40
 364:	c3                   	ret    

00000365 <open>:
SYSCALL(open)
 365:	b8 0f 00 00 00       	mov    $0xf,%eax
 36a:	cd 40                	int    $0x40
 36c:	c3                   	ret    

0000036d <mknod>:
SYSCALL(mknod)
 36d:	b8 11 00 00 00       	mov    $0x11,%eax
 372:	cd 40                	int    $0x40
 374:	c3                   	ret    

00000375 <unlink>:
SYSCALL(unlink)
 375:	b8 12 00 00 00       	mov    $0x12,%eax
 37a:	cd 40                	int    $0x40
 37c:	c3                   	ret    

0000037d <fstat>:
SYSCALL(fstat)
 37d:	b8 08 00 00 00       	mov    $0x8,%eax
 382:	cd 40                	int    $0x40
 384:	c3                   	ret    

00000385 <link>:
SYSCALL(link)
 385:	b8 13 00 00 00       	mov    $0x13,%eax
 38a:	cd 40                	int    $0x40
 38c:	c3                   	ret    

0000038d <mkdir>:
SYSCALL(mkdir)
 38d:	b8 14 00 00 00       	mov    $0x14,%eax
 392:	cd 40                	int    $0x40
 394:	c3                   	ret    

00000395 <chdir>:
SYSCALL(chdir)
 395:	b8 09 00 00 00       	mov    $0x9,%eax
 39a:	cd 40                	int    $0x40
 39c:	c3                   	ret    

0000039d <dup>:
SYSCALL(dup)
 39d:	b8 0a 00 00 00       	mov    $0xa,%eax
 3a2:	cd 40                	int    $0x40
 3a4:	c3                   	ret    

000003a5 <getpid>:
SYSCALL(getpid)
 3a5:	b8 0b 00 00 00       	mov    $0xb,%eax
 3aa:	cd 40                	int    $0x40
 3ac:	c3                   	ret    

000003ad <sbrk>:
SYSCALL(sbrk)
 3ad:	b8 0c 00 00 00       	mov    $0xc,%eax
 3b2:	cd 40                	int    $0x40
 3b4:	c3                   	ret    

000003b5 <sleep>:
SYSCALL(sleep)
 3b5:	b8 0d 00 00 00       	mov    $0xd,%eax
 3ba:	cd 40                	int    $0x40
 3bc:	c3                   	ret    

000003bd <uptime>:
 3bd:	b8 0e 00 00 00       	mov    $0xe,%eax
 3c2:	cd 40                	int    $0x40
 3c4:	c3                   	ret    

000003c5 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 3c5:	55                   	push   %ebp
 3c6:	89 e5                	mov    %esp,%ebp
 3c8:	83 ec 18             	sub    $0x18,%esp
 3cb:	8b 45 0c             	mov    0xc(%ebp),%eax
 3ce:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 3d1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 3d8:	00 
 3d9:	8d 45 f4             	lea    -0xc(%ebp),%eax
 3dc:	89 44 24 04          	mov    %eax,0x4(%esp)
 3e0:	8b 45 08             	mov    0x8(%ebp),%eax
 3e3:	89 04 24             	mov    %eax,(%esp)
 3e6:	e8 5a ff ff ff       	call   345 <write>
}
 3eb:	c9                   	leave  
 3ec:	c3                   	ret    

000003ed <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ed:	55                   	push   %ebp
 3ee:	89 e5                	mov    %esp,%ebp
 3f0:	56                   	push   %esi
 3f1:	53                   	push   %ebx
 3f2:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 3f5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 3fc:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 400:	74 17                	je     419 <printint+0x2c>
 402:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 406:	79 11                	jns    419 <printint+0x2c>
    neg = 1;
 408:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 40f:	8b 45 0c             	mov    0xc(%ebp),%eax
 412:	f7 d8                	neg    %eax
 414:	89 45 ec             	mov    %eax,-0x14(%ebp)
 417:	eb 06                	jmp    41f <printint+0x32>
  } else {
    x = xx;
 419:	8b 45 0c             	mov    0xc(%ebp),%eax
 41c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 41f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 426:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 429:	8d 41 01             	lea    0x1(%ecx),%eax
 42c:	89 45 f4             	mov    %eax,-0xc(%ebp)
 42f:	8b 5d 10             	mov    0x10(%ebp),%ebx
 432:	8b 45 ec             	mov    -0x14(%ebp),%eax
 435:	ba 00 00 00 00       	mov    $0x0,%edx
 43a:	f7 f3                	div    %ebx
 43c:	89 d0                	mov    %edx,%eax
 43e:	0f b6 80 fc 0a 00 00 	movzbl 0xafc(%eax),%eax
 445:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 449:	8b 75 10             	mov    0x10(%ebp),%esi
 44c:	8b 45 ec             	mov    -0x14(%ebp),%eax
 44f:	ba 00 00 00 00       	mov    $0x0,%edx
 454:	f7 f6                	div    %esi
 456:	89 45 ec             	mov    %eax,-0x14(%ebp)
 459:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 45d:	75 c7                	jne    426 <printint+0x39>
  if(neg)
 45f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 463:	74 10                	je     475 <printint+0x88>
    buf[i++] = '-';
 465:	8b 45 f4             	mov    -0xc(%ebp),%eax
 468:	8d 50 01             	lea    0x1(%eax),%edx
 46b:	89 55 f4             	mov    %edx,-0xc(%ebp)
 46e:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 473:	eb 1f                	jmp    494 <printint+0xa7>
 475:	eb 1d                	jmp    494 <printint+0xa7>
    putc(fd, buf[i]);
 477:	8d 55 dc             	lea    -0x24(%ebp),%edx
 47a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 47d:	01 d0                	add    %edx,%eax
 47f:	0f b6 00             	movzbl (%eax),%eax
 482:	0f be c0             	movsbl %al,%eax
 485:	89 44 24 04          	mov    %eax,0x4(%esp)
 489:	8b 45 08             	mov    0x8(%ebp),%eax
 48c:	89 04 24             	mov    %eax,(%esp)
 48f:	e8 31 ff ff ff       	call   3c5 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 494:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 498:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 49c:	79 d9                	jns    477 <printint+0x8a>
    putc(fd, buf[i]);
}
 49e:	83 c4 30             	add    $0x30,%esp
 4a1:	5b                   	pop    %ebx
 4a2:	5e                   	pop    %esi
 4a3:	5d                   	pop    %ebp
 4a4:	c3                   	ret    

000004a5 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 4a5:	55                   	push   %ebp
 4a6:	89 e5                	mov    %esp,%ebp
 4a8:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 4ab:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 4b2:	8d 45 0c             	lea    0xc(%ebp),%eax
 4b5:	83 c0 04             	add    $0x4,%eax
 4b8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 4bb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 4c2:	e9 7c 01 00 00       	jmp    643 <printf+0x19e>
    c = fmt[i] & 0xff;
 4c7:	8b 55 0c             	mov    0xc(%ebp),%edx
 4ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
 4cd:	01 d0                	add    %edx,%eax
 4cf:	0f b6 00             	movzbl (%eax),%eax
 4d2:	0f be c0             	movsbl %al,%eax
 4d5:	25 ff 00 00 00       	and    $0xff,%eax
 4da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 4dd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4e1:	75 2c                	jne    50f <printf+0x6a>
      if(c == '%'){
 4e3:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 4e7:	75 0c                	jne    4f5 <printf+0x50>
        state = '%';
 4e9:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 4f0:	e9 4a 01 00 00       	jmp    63f <printf+0x19a>
      } else {
        putc(fd, c);
 4f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 4f8:	0f be c0             	movsbl %al,%eax
 4fb:	89 44 24 04          	mov    %eax,0x4(%esp)
 4ff:	8b 45 08             	mov    0x8(%ebp),%eax
 502:	89 04 24             	mov    %eax,(%esp)
 505:	e8 bb fe ff ff       	call   3c5 <putc>
 50a:	e9 30 01 00 00       	jmp    63f <printf+0x19a>
      }
    } else if(state == '%'){
 50f:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 513:	0f 85 26 01 00 00    	jne    63f <printf+0x19a>
      if(c == 'd'){
 519:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 51d:	75 2d                	jne    54c <printf+0xa7>
        printint(fd, *ap, 10, 1);
 51f:	8b 45 e8             	mov    -0x18(%ebp),%eax
 522:	8b 00                	mov    (%eax),%eax
 524:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 52b:	00 
 52c:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 533:	00 
 534:	89 44 24 04          	mov    %eax,0x4(%esp)
 538:	8b 45 08             	mov    0x8(%ebp),%eax
 53b:	89 04 24             	mov    %eax,(%esp)
 53e:	e8 aa fe ff ff       	call   3ed <printint>
        ap++;
 543:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 547:	e9 ec 00 00 00       	jmp    638 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 54c:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 550:	74 06                	je     558 <printf+0xb3>
 552:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 556:	75 2d                	jne    585 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 558:	8b 45 e8             	mov    -0x18(%ebp),%eax
 55b:	8b 00                	mov    (%eax),%eax
 55d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 564:	00 
 565:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 56c:	00 
 56d:	89 44 24 04          	mov    %eax,0x4(%esp)
 571:	8b 45 08             	mov    0x8(%ebp),%eax
 574:	89 04 24             	mov    %eax,(%esp)
 577:	e8 71 fe ff ff       	call   3ed <printint>
        ap++;
 57c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 580:	e9 b3 00 00 00       	jmp    638 <printf+0x193>
      } else if(c == 's'){
 585:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 589:	75 45                	jne    5d0 <printf+0x12b>
        s = (char*)*ap;
 58b:	8b 45 e8             	mov    -0x18(%ebp),%eax
 58e:	8b 00                	mov    (%eax),%eax
 590:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 593:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 597:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 59b:	75 09                	jne    5a6 <printf+0x101>
          s = "(null)";
 59d:	c7 45 f4 b0 08 00 00 	movl   $0x8b0,-0xc(%ebp)
        while(*s != 0){
 5a4:	eb 1e                	jmp    5c4 <printf+0x11f>
 5a6:	eb 1c                	jmp    5c4 <printf+0x11f>
          putc(fd, *s);
 5a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5ab:	0f b6 00             	movzbl (%eax),%eax
 5ae:	0f be c0             	movsbl %al,%eax
 5b1:	89 44 24 04          	mov    %eax,0x4(%esp)
 5b5:	8b 45 08             	mov    0x8(%ebp),%eax
 5b8:	89 04 24             	mov    %eax,(%esp)
 5bb:	e8 05 fe ff ff       	call   3c5 <putc>
          s++;
 5c0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5c7:	0f b6 00             	movzbl (%eax),%eax
 5ca:	84 c0                	test   %al,%al
 5cc:	75 da                	jne    5a8 <printf+0x103>
 5ce:	eb 68                	jmp    638 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5d0:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 5d4:	75 1d                	jne    5f3 <printf+0x14e>
        putc(fd, *ap);
 5d6:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5d9:	8b 00                	mov    (%eax),%eax
 5db:	0f be c0             	movsbl %al,%eax
 5de:	89 44 24 04          	mov    %eax,0x4(%esp)
 5e2:	8b 45 08             	mov    0x8(%ebp),%eax
 5e5:	89 04 24             	mov    %eax,(%esp)
 5e8:	e8 d8 fd ff ff       	call   3c5 <putc>
        ap++;
 5ed:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5f1:	eb 45                	jmp    638 <printf+0x193>
      } else if(c == '%'){
 5f3:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 5f7:	75 17                	jne    610 <printf+0x16b>
        putc(fd, c);
 5f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5fc:	0f be c0             	movsbl %al,%eax
 5ff:	89 44 24 04          	mov    %eax,0x4(%esp)
 603:	8b 45 08             	mov    0x8(%ebp),%eax
 606:	89 04 24             	mov    %eax,(%esp)
 609:	e8 b7 fd ff ff       	call   3c5 <putc>
 60e:	eb 28                	jmp    638 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 610:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 617:	00 
 618:	8b 45 08             	mov    0x8(%ebp),%eax
 61b:	89 04 24             	mov    %eax,(%esp)
 61e:	e8 a2 fd ff ff       	call   3c5 <putc>
        putc(fd, c);
 623:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 626:	0f be c0             	movsbl %al,%eax
 629:	89 44 24 04          	mov    %eax,0x4(%esp)
 62d:	8b 45 08             	mov    0x8(%ebp),%eax
 630:	89 04 24             	mov    %eax,(%esp)
 633:	e8 8d fd ff ff       	call   3c5 <putc>
      }
      state = 0;
 638:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 63f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 643:	8b 55 0c             	mov    0xc(%ebp),%edx
 646:	8b 45 f0             	mov    -0x10(%ebp),%eax
 649:	01 d0                	add    %edx,%eax
 64b:	0f b6 00             	movzbl (%eax),%eax
 64e:	84 c0                	test   %al,%al
 650:	0f 85 71 fe ff ff    	jne    4c7 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 656:	c9                   	leave  
 657:	c3                   	ret    

00000658 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 658:	55                   	push   %ebp
 659:	89 e5                	mov    %esp,%ebp
 65b:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 65e:	8b 45 08             	mov    0x8(%ebp),%eax
 661:	83 e8 08             	sub    $0x8,%eax
 664:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 667:	a1 28 0b 00 00       	mov    0xb28,%eax
 66c:	89 45 fc             	mov    %eax,-0x4(%ebp)
 66f:	eb 24                	jmp    695 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 671:	8b 45 fc             	mov    -0x4(%ebp),%eax
 674:	8b 00                	mov    (%eax),%eax
 676:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 679:	77 12                	ja     68d <free+0x35>
 67b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 67e:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 681:	77 24                	ja     6a7 <free+0x4f>
 683:	8b 45 fc             	mov    -0x4(%ebp),%eax
 686:	8b 00                	mov    (%eax),%eax
 688:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 68b:	77 1a                	ja     6a7 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 68d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 690:	8b 00                	mov    (%eax),%eax
 692:	89 45 fc             	mov    %eax,-0x4(%ebp)
 695:	8b 45 f8             	mov    -0x8(%ebp),%eax
 698:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 69b:	76 d4                	jbe    671 <free+0x19>
 69d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a0:	8b 00                	mov    (%eax),%eax
 6a2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6a5:	76 ca                	jbe    671 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 6a7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6aa:	8b 40 04             	mov    0x4(%eax),%eax
 6ad:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 6b4:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6b7:	01 c2                	add    %eax,%edx
 6b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6bc:	8b 00                	mov    (%eax),%eax
 6be:	39 c2                	cmp    %eax,%edx
 6c0:	75 24                	jne    6e6 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 6c2:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6c5:	8b 50 04             	mov    0x4(%eax),%edx
 6c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6cb:	8b 00                	mov    (%eax),%eax
 6cd:	8b 40 04             	mov    0x4(%eax),%eax
 6d0:	01 c2                	add    %eax,%edx
 6d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6d5:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 6d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6db:	8b 00                	mov    (%eax),%eax
 6dd:	8b 10                	mov    (%eax),%edx
 6df:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6e2:	89 10                	mov    %edx,(%eax)
 6e4:	eb 0a                	jmp    6f0 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 6e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6e9:	8b 10                	mov    (%eax),%edx
 6eb:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6ee:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 6f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6f3:	8b 40 04             	mov    0x4(%eax),%eax
 6f6:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 6fd:	8b 45 fc             	mov    -0x4(%ebp),%eax
 700:	01 d0                	add    %edx,%eax
 702:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 705:	75 20                	jne    727 <free+0xcf>
    p->s.size += bp->s.size;
 707:	8b 45 fc             	mov    -0x4(%ebp),%eax
 70a:	8b 50 04             	mov    0x4(%eax),%edx
 70d:	8b 45 f8             	mov    -0x8(%ebp),%eax
 710:	8b 40 04             	mov    0x4(%eax),%eax
 713:	01 c2                	add    %eax,%edx
 715:	8b 45 fc             	mov    -0x4(%ebp),%eax
 718:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 71b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 71e:	8b 10                	mov    (%eax),%edx
 720:	8b 45 fc             	mov    -0x4(%ebp),%eax
 723:	89 10                	mov    %edx,(%eax)
 725:	eb 08                	jmp    72f <free+0xd7>
  } else
    p->s.ptr = bp;
 727:	8b 45 fc             	mov    -0x4(%ebp),%eax
 72a:	8b 55 f8             	mov    -0x8(%ebp),%edx
 72d:	89 10                	mov    %edx,(%eax)
  freep = p;
 72f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 732:	a3 28 0b 00 00       	mov    %eax,0xb28
}
 737:	c9                   	leave  
 738:	c3                   	ret    

00000739 <morecore>:

static Header*
morecore(uint nu)
{
 739:	55                   	push   %ebp
 73a:	89 e5                	mov    %esp,%ebp
 73c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 73f:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 746:	77 07                	ja     74f <morecore+0x16>
    nu = 4096;
 748:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 74f:	8b 45 08             	mov    0x8(%ebp),%eax
 752:	c1 e0 03             	shl    $0x3,%eax
 755:	89 04 24             	mov    %eax,(%esp)
 758:	e8 50 fc ff ff       	call   3ad <sbrk>
 75d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 760:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 764:	75 07                	jne    76d <morecore+0x34>
    return 0;
 766:	b8 00 00 00 00       	mov    $0x0,%eax
 76b:	eb 22                	jmp    78f <morecore+0x56>
  hp = (Header*)p;
 76d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 770:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 773:	8b 45 f0             	mov    -0x10(%ebp),%eax
 776:	8b 55 08             	mov    0x8(%ebp),%edx
 779:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 77c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 77f:	83 c0 08             	add    $0x8,%eax
 782:	89 04 24             	mov    %eax,(%esp)
 785:	e8 ce fe ff ff       	call   658 <free>
  return freep;
 78a:	a1 28 0b 00 00       	mov    0xb28,%eax
}
 78f:	c9                   	leave  
 790:	c3                   	ret    

00000791 <malloc>:

void*
malloc(uint nbytes)
{
 791:	55                   	push   %ebp
 792:	89 e5                	mov    %esp,%ebp
 794:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 797:	8b 45 08             	mov    0x8(%ebp),%eax
 79a:	83 c0 07             	add    $0x7,%eax
 79d:	c1 e8 03             	shr    $0x3,%eax
 7a0:	83 c0 01             	add    $0x1,%eax
 7a3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 7a6:	a1 28 0b 00 00       	mov    0xb28,%eax
 7ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7ae:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 7b2:	75 23                	jne    7d7 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 7b4:	c7 45 f0 20 0b 00 00 	movl   $0xb20,-0x10(%ebp)
 7bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7be:	a3 28 0b 00 00       	mov    %eax,0xb28
 7c3:	a1 28 0b 00 00       	mov    0xb28,%eax
 7c8:	a3 20 0b 00 00       	mov    %eax,0xb20
    base.s.size = 0;
 7cd:	c7 05 24 0b 00 00 00 	movl   $0x0,0xb24
 7d4:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7da:	8b 00                	mov    (%eax),%eax
 7dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 7df:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7e2:	8b 40 04             	mov    0x4(%eax),%eax
 7e5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 7e8:	72 4d                	jb     837 <malloc+0xa6>
      if(p->s.size == nunits)
 7ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7ed:	8b 40 04             	mov    0x4(%eax),%eax
 7f0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 7f3:	75 0c                	jne    801 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 7f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7f8:	8b 10                	mov    (%eax),%edx
 7fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7fd:	89 10                	mov    %edx,(%eax)
 7ff:	eb 26                	jmp    827 <malloc+0x96>
      else {
        p->s.size -= nunits;
 801:	8b 45 f4             	mov    -0xc(%ebp),%eax
 804:	8b 40 04             	mov    0x4(%eax),%eax
 807:	2b 45 ec             	sub    -0x14(%ebp),%eax
 80a:	89 c2                	mov    %eax,%edx
 80c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 80f:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 812:	8b 45 f4             	mov    -0xc(%ebp),%eax
 815:	8b 40 04             	mov    0x4(%eax),%eax
 818:	c1 e0 03             	shl    $0x3,%eax
 81b:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 81e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 821:	8b 55 ec             	mov    -0x14(%ebp),%edx
 824:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 827:	8b 45 f0             	mov    -0x10(%ebp),%eax
 82a:	a3 28 0b 00 00       	mov    %eax,0xb28
      return (void*)(p + 1);
 82f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 832:	83 c0 08             	add    $0x8,%eax
 835:	eb 38                	jmp    86f <malloc+0xde>
    }
    if(p == freep)
 837:	a1 28 0b 00 00       	mov    0xb28,%eax
 83c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 83f:	75 1b                	jne    85c <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 841:	8b 45 ec             	mov    -0x14(%ebp),%eax
 844:	89 04 24             	mov    %eax,(%esp)
 847:	e8 ed fe ff ff       	call   739 <morecore>
 84c:	89 45 f4             	mov    %eax,-0xc(%ebp)
 84f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 853:	75 07                	jne    85c <malloc+0xcb>
        return 0;
 855:	b8 00 00 00 00       	mov    $0x0,%eax
 85a:	eb 13                	jmp    86f <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 85c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 85f:	89 45 f0             	mov    %eax,-0x10(%ebp)
 862:	8b 45 f4             	mov    -0xc(%ebp),%eax
 865:	8b 00                	mov    (%eax),%eax
 867:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 86a:	e9 70 ff ff ff       	jmp    7df <malloc+0x4e>
}
 86f:	c9                   	leave  
 870:	c3                   	ret    
