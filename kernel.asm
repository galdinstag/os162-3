
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 c0 10 00       	mov    $0x10c000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 60 e6 10 80       	mov    $0x8010e660,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 91 3e 10 80       	mov    $0x80103e91,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 8c 9a 10 	movl   $0x80109a8c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 42 57 00 00       	call   80105790 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 25 11 80 64 	movl   $0x80112564,0x80112570
80100055:	25 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 25 11 80 64 	movl   $0x80112564,0x80112574
8010005f:	25 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 e6 10 80 	movl   $0x8010e694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 25 11 80    	mov    0x80112574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 25 11 80 	movl   $0x80112564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 25 11 80       	mov    0x80112574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 25 11 80       	mov    %eax,0x80112574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 25 11 80 	cmpl   $0x80112564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801000bd:	e8 ef 56 00 00       	call   801057b1 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 25 11 80       	mov    0x80112574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->blockno == blockno){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100104:	e8 0a 57 00 00       	call   80105813 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 45 53 00 00       	call   80105469 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 25 11 80 	cmpl   $0x80112564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 25 11 80       	mov    0x80112570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010017c:	e8 92 56 00 00       	call   80105813 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 25 11 80 	cmpl   $0x80112564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 93 9a 10 80 	movl   $0x80109a93,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID)) {
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 de 2c 00 00       	call   80102eb6 <iderw>
  }
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 a4 9a 10 80 	movl   $0x80109aa4,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 a1 2c 00 00       	call   80102eb6 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 ab 9a 10 80 	movl   $0x80109aab,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 70 55 00 00       	call   801057b1 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 25 11 80    	mov    0x80112574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 25 11 80 	movl   $0x80112564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 25 11 80       	mov    0x80112574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 25 11 80       	mov    %eax,0x80112574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 a3 52 00 00       	call   80105545 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 65 55 00 00       	call   80105813 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 b0 10 80 	movzbl -0x7fef4ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 dc 03 00 00       	call   8010076b <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 d5 10 80       	mov    0x8010d5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
801003bb:	e8 f1 53 00 00       	call   801057b1 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 b2 9a 10 80 	movl   $0x80109ab2,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 75 03 00 00       	call   8010076b <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec bb 9a 10 80 	movl   $0x80109abb,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 9f 02 00 00       	call   8010076b <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 83 02 00 00       	call   8010076b <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 75 02 00 00       	call   8010076b <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 6a 02 00 00       	call   8010076b <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100533:	e8 db 52 00 00       	call   80105813 <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 d5 10 80 00 	movl   $0x0,0x8010d5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 c2 9a 10 80 	movl   $0x80109ac2,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 d1 9a 10 80 	movl   $0x80109ad1,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 ce 52 00 00       	call   80105862 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 d3 9a 10 80 	movl   $0x80109ad3,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 d5 10 80 01 	movl   $0x1,0x8010d5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 b0 10 80    	mov    0x8010b000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)

  if(pos < 0 || pos > 25*80)
8010068a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010068e:	78 09                	js     80100699 <cgaputc+0xcf>
80100690:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
80100697:	7e 0c                	jle    801006a5 <cgaputc+0xdb>
    panic("pos under/overflow");
80100699:	c7 04 24 d7 9a 10 80 	movl   $0x80109ad7,(%esp)
801006a0:	e8 95 fe ff ff       	call   8010053a <panic>
  
  if((pos/80) >= 24){  // Scroll up.
801006a5:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801006ac:	7e 53                	jle    80100701 <cgaputc+0x137>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801006ae:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801006b3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006b9:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801006be:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006c5:	00 
801006c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801006ca:	89 04 24             	mov    %eax,(%esp)
801006cd:	e8 02 54 00 00       	call   80105ad4 <memmove>
    pos -= 80;
801006d2:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006d6:	b8 80 07 00 00       	mov    $0x780,%eax
801006db:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006de:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006e1:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801006e6:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006e9:	01 c9                	add    %ecx,%ecx
801006eb:	01 c8                	add    %ecx,%eax
801006ed:	89 54 24 08          	mov    %edx,0x8(%esp)
801006f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006f8:	00 
801006f9:	89 04 24             	mov    %eax,(%esp)
801006fc:	e8 04 53 00 00       	call   80105a05 <memset>
  }
  
  outb(CRTPORT, 14);
80100701:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
80100708:	00 
80100709:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100710:	e8 b8 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
80100715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100718:	c1 f8 08             	sar    $0x8,%eax
8010071b:	0f b6 c0             	movzbl %al,%eax
8010071e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100722:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100729:	e8 9f fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
8010072e:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100735:	00 
80100736:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010073d:	e8 8b fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100742:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100745:	0f b6 c0             	movzbl %al,%eax
80100748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010074c:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100753:	e8 75 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
80100758:	a1 00 b0 10 80       	mov    0x8010b000,%eax
8010075d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100760:	01 d2                	add    %edx,%edx
80100762:	01 d0                	add    %edx,%eax
80100764:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
80100769:	c9                   	leave  
8010076a:	c3                   	ret    

8010076b <consputc>:

void
consputc(int c)
{
8010076b:	55                   	push   %ebp
8010076c:	89 e5                	mov    %esp,%ebp
8010076e:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100771:	a1 a0 d5 10 80       	mov    0x8010d5a0,%eax
80100776:	85 c0                	test   %eax,%eax
80100778:	74 07                	je     80100781 <consputc+0x16>
    cli();
8010077a:	e8 6c fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
8010077f:	eb fe                	jmp    8010077f <consputc+0x14>
  }

  if(c == BACKSPACE){
80100781:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100788:	75 26                	jne    801007b0 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010078a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100791:	e8 be 6c 00 00       	call   80107454 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 b2 6c 00 00       	call   80107454 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 a6 6c 00 00       	call   80107454 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 99 6c 00 00       	call   80107454 <uartputc>
  cgaputc(c);
801007bb:	8b 45 08             	mov    0x8(%ebp),%eax
801007be:	89 04 24             	mov    %eax,(%esp)
801007c1:	e8 04 fe ff ff       	call   801005ca <cgaputc>
}
801007c6:	c9                   	leave  
801007c7:	c3                   	ret    

801007c8 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007c8:	55                   	push   %ebp
801007c9:	89 e5                	mov    %esp,%ebp
801007cb:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
801007ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
801007d5:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
801007dc:	e8 d0 4f 00 00       	call   801057b1 <acquire>
  while((c = getc()) >= 0){
801007e1:	e9 39 01 00 00       	jmp    8010091f <consoleintr+0x157>
    switch(c){
801007e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801007e9:	83 f8 10             	cmp    $0x10,%eax
801007ec:	74 1e                	je     8010080c <consoleintr+0x44>
801007ee:	83 f8 10             	cmp    $0x10,%eax
801007f1:	7f 0a                	jg     801007fd <consoleintr+0x35>
801007f3:	83 f8 08             	cmp    $0x8,%eax
801007f6:	74 66                	je     8010085e <consoleintr+0x96>
801007f8:	e9 93 00 00 00       	jmp    80100890 <consoleintr+0xc8>
801007fd:	83 f8 15             	cmp    $0x15,%eax
80100800:	74 31                	je     80100833 <consoleintr+0x6b>
80100802:	83 f8 7f             	cmp    $0x7f,%eax
80100805:	74 57                	je     8010085e <consoleintr+0x96>
80100807:	e9 84 00 00 00       	jmp    80100890 <consoleintr+0xc8>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
8010080c:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100813:	e9 07 01 00 00       	jmp    8010091f <consoleintr+0x157>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100818:	a1 08 28 11 80       	mov    0x80112808,%eax
8010081d:	83 e8 01             	sub    $0x1,%eax
80100820:	a3 08 28 11 80       	mov    %eax,0x80112808
        consputc(BACKSPACE);
80100825:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010082c:	e8 3a ff ff ff       	call   8010076b <consputc>
80100831:	eb 01                	jmp    80100834 <consoleintr+0x6c>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100833:	90                   	nop
80100834:	8b 15 08 28 11 80    	mov    0x80112808,%edx
8010083a:	a1 04 28 11 80       	mov    0x80112804,%eax
8010083f:	39 c2                	cmp    %eax,%edx
80100841:	74 16                	je     80100859 <consoleintr+0x91>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100843:	a1 08 28 11 80       	mov    0x80112808,%eax
80100848:	83 e8 01             	sub    $0x1,%eax
8010084b:	83 e0 7f             	and    $0x7f,%eax
8010084e:	0f b6 80 80 27 11 80 	movzbl -0x7feed880(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100855:	3c 0a                	cmp    $0xa,%al
80100857:	75 bf                	jne    80100818 <consoleintr+0x50>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100859:	e9 c1 00 00 00       	jmp    8010091f <consoleintr+0x157>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010085e:	8b 15 08 28 11 80    	mov    0x80112808,%edx
80100864:	a1 04 28 11 80       	mov    0x80112804,%eax
80100869:	39 c2                	cmp    %eax,%edx
8010086b:	74 1e                	je     8010088b <consoleintr+0xc3>
        input.e--;
8010086d:	a1 08 28 11 80       	mov    0x80112808,%eax
80100872:	83 e8 01             	sub    $0x1,%eax
80100875:	a3 08 28 11 80       	mov    %eax,0x80112808
        consputc(BACKSPACE);
8010087a:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100881:	e8 e5 fe ff ff       	call   8010076b <consputc>
      }
      break;
80100886:	e9 94 00 00 00       	jmp    8010091f <consoleintr+0x157>
8010088b:	e9 8f 00 00 00       	jmp    8010091f <consoleintr+0x157>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100890:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100894:	0f 84 84 00 00 00    	je     8010091e <consoleintr+0x156>
8010089a:	8b 15 08 28 11 80    	mov    0x80112808,%edx
801008a0:	a1 00 28 11 80       	mov    0x80112800,%eax
801008a5:	29 c2                	sub    %eax,%edx
801008a7:	89 d0                	mov    %edx,%eax
801008a9:	83 f8 7f             	cmp    $0x7f,%eax
801008ac:	77 70                	ja     8010091e <consoleintr+0x156>
        c = (c == '\r') ? '\n' : c;
801008ae:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801008b2:	74 05                	je     801008b9 <consoleintr+0xf1>
801008b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008b7:	eb 05                	jmp    801008be <consoleintr+0xf6>
801008b9:	b8 0a 00 00 00       	mov    $0xa,%eax
801008be:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008c1:	a1 08 28 11 80       	mov    0x80112808,%eax
801008c6:	8d 50 01             	lea    0x1(%eax),%edx
801008c9:	89 15 08 28 11 80    	mov    %edx,0x80112808
801008cf:	83 e0 7f             	and    $0x7f,%eax
801008d2:	89 c2                	mov    %eax,%edx
801008d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008d7:	88 82 80 27 11 80    	mov    %al,-0x7feed880(%edx)
        consputc(c);
801008dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801008e0:	89 04 24             	mov    %eax,(%esp)
801008e3:	e8 83 fe ff ff       	call   8010076b <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008e8:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801008ec:	74 18                	je     80100906 <consoleintr+0x13e>
801008ee:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801008f2:	74 12                	je     80100906 <consoleintr+0x13e>
801008f4:	a1 08 28 11 80       	mov    0x80112808,%eax
801008f9:	8b 15 00 28 11 80    	mov    0x80112800,%edx
801008ff:	83 ea 80             	sub    $0xffffff80,%edx
80100902:	39 d0                	cmp    %edx,%eax
80100904:	75 18                	jne    8010091e <consoleintr+0x156>
          input.w = input.e;
80100906:	a1 08 28 11 80       	mov    0x80112808,%eax
8010090b:	a3 04 28 11 80       	mov    %eax,0x80112804
          wakeup(&input.r);
80100910:	c7 04 24 00 28 11 80 	movl   $0x80112800,(%esp)
80100917:	e8 29 4c 00 00       	call   80105545 <wakeup>
        }
      }
      break;
8010091c:	eb 00                	jmp    8010091e <consoleintr+0x156>
8010091e:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
8010091f:	8b 45 08             	mov    0x8(%ebp),%eax
80100922:	ff d0                	call   *%eax
80100924:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100927:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010092b:	0f 89 b5 fe ff ff    	jns    801007e6 <consoleintr+0x1e>
        }
      }
      break;
    }
  }
  release(&cons.lock);
80100931:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100938:	e8 d6 4e 00 00       	call   80105813 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 a3 4c 00 00       	call   801055eb <procdump>
  }
}
80100948:	c9                   	leave  
80100949:	c3                   	ret    

8010094a <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010094a:	55                   	push   %ebp
8010094b:	89 e5                	mov    %esp,%ebp
8010094d:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100950:	8b 45 08             	mov    0x8(%ebp),%eax
80100953:	89 04 24             	mov    %eax,(%esp)
80100956:	e8 03 12 00 00       	call   80101b5e <iunlock>
  target = n;
8010095b:	8b 45 10             	mov    0x10(%ebp),%eax
8010095e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100961:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100968:	e8 44 4e 00 00       	call   801057b1 <acquire>
  while(n > 0){
8010096d:	e9 aa 00 00 00       	jmp    80100a1c <consoleread+0xd2>
    while(input.r == input.w){
80100972:	eb 42                	jmp    801009b6 <consoleread+0x6c>
      if(proc->killed){
80100974:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010097a:	8b 40 24             	mov    0x24(%eax),%eax
8010097d:	85 c0                	test   %eax,%eax
8010097f:	74 21                	je     801009a2 <consoleread+0x58>
        release(&cons.lock);
80100981:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100988:	e8 86 4e 00 00       	call   80105813 <release>
        ilock(ip);
8010098d:	8b 45 08             	mov    0x8(%ebp),%eax
80100990:	89 04 24             	mov    %eax,(%esp)
80100993:	e8 72 10 00 00       	call   80101a0a <ilock>
        return -1;
80100998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010099d:	e9 a5 00 00 00       	jmp    80100a47 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
801009a2:	c7 44 24 04 c0 d5 10 	movl   $0x8010d5c0,0x4(%esp)
801009a9:	80 
801009aa:	c7 04 24 00 28 11 80 	movl   $0x80112800,(%esp)
801009b1:	e8 b3 4a 00 00       	call   80105469 <sleep>

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
801009b6:	8b 15 00 28 11 80    	mov    0x80112800,%edx
801009bc:	a1 04 28 11 80       	mov    0x80112804,%eax
801009c1:	39 c2                	cmp    %eax,%edx
801009c3:	74 af                	je     80100974 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009c5:	a1 00 28 11 80       	mov    0x80112800,%eax
801009ca:	8d 50 01             	lea    0x1(%eax),%edx
801009cd:	89 15 00 28 11 80    	mov    %edx,0x80112800
801009d3:	83 e0 7f             	and    $0x7f,%eax
801009d6:	0f b6 80 80 27 11 80 	movzbl -0x7feed880(%eax),%eax
801009dd:	0f be c0             	movsbl %al,%eax
801009e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009e3:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009e7:	75 19                	jne    80100a02 <consoleread+0xb8>
      if(n < target){
801009e9:	8b 45 10             	mov    0x10(%ebp),%eax
801009ec:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009ef:	73 0f                	jae    80100a00 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009f1:	a1 00 28 11 80       	mov    0x80112800,%eax
801009f6:	83 e8 01             	sub    $0x1,%eax
801009f9:	a3 00 28 11 80       	mov    %eax,0x80112800
      }
      break;
801009fe:	eb 26                	jmp    80100a26 <consoleread+0xdc>
80100a00:	eb 24                	jmp    80100a26 <consoleread+0xdc>
    }
    *dst++ = c;
80100a02:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a05:	8d 50 01             	lea    0x1(%eax),%edx
80100a08:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a0b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a0e:	88 10                	mov    %dl,(%eax)
    --n;
80100a10:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a14:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a18:	75 02                	jne    80100a1c <consoleread+0xd2>
      break;
80100a1a:	eb 0a                	jmp    80100a26 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100a1c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100a20:	0f 8f 4c ff ff ff    	jg     80100972 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&cons.lock);
80100a26:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100a2d:	e8 e1 4d 00 00       	call   80105813 <release>
  ilock(ip);
80100a32:	8b 45 08             	mov    0x8(%ebp),%eax
80100a35:	89 04 24             	mov    %eax,(%esp)
80100a38:	e8 cd 0f 00 00       	call   80101a0a <ilock>

  return target - n;
80100a3d:	8b 45 10             	mov    0x10(%ebp),%eax
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	29 c2                	sub    %eax,%edx
80100a45:	89 d0                	mov    %edx,%eax
}
80100a47:	c9                   	leave  
80100a48:	c3                   	ret    

80100a49 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a49:	55                   	push   %ebp
80100a4a:	89 e5                	mov    %esp,%ebp
80100a4c:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80100a52:	89 04 24             	mov    %eax,(%esp)
80100a55:	e8 04 11 00 00       	call   80101b5e <iunlock>
  acquire(&cons.lock);
80100a5a:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100a61:	e8 4b 4d 00 00       	call   801057b1 <acquire>
  for(i = 0; i < n; i++)
80100a66:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a6d:	eb 1d                	jmp    80100a8c <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a72:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a75:	01 d0                	add    %edx,%eax
80100a77:	0f b6 00             	movzbl (%eax),%eax
80100a7a:	0f be c0             	movsbl %al,%eax
80100a7d:	0f b6 c0             	movzbl %al,%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 e3 fc ff ff       	call   8010076b <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a88:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a8f:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a92:	7c db                	jl     80100a6f <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a94:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100a9b:	e8 73 4d 00 00       	call   80105813 <release>
  ilock(ip);
80100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
80100aa3:	89 04 24             	mov    %eax,(%esp)
80100aa6:	e8 5f 0f 00 00       	call   80101a0a <ilock>

  return n;
80100aab:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100aae:	c9                   	leave  
80100aaf:	c3                   	ret    

80100ab0 <consoleinit>:

void
consoleinit(void)
{
80100ab0:	55                   	push   %ebp
80100ab1:	89 e5                	mov    %esp,%ebp
80100ab3:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100ab6:	c7 44 24 04 ea 9a 10 	movl   $0x80109aea,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 c6 4c 00 00       	call   80105790 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aca:	c7 05 cc 31 11 80 49 	movl   $0x80100a49,0x801131cc
80100ad1:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ad4:	c7 05 c8 31 11 80 4a 	movl   $0x8010094a,0x801131c8
80100adb:	09 10 80 
  cons.locking = 1;
80100ade:	c7 05 f4 d5 10 80 01 	movl   $0x1,0x8010d5f4
80100ae5:	00 00 00 

  picenable(IRQ_KBD);
80100ae8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100aef:	e8 35 3a 00 00       	call   80104529 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 6a 25 00 00       	call   80103072 <ioapicenable>
}
80100b08:	c9                   	leave  
80100b09:	c3                   	ret    

80100b0a <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b0a:	55                   	push   %ebp
80100b0b:	89 e5                	mov    %esp,%ebp
80100b0d:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100b13:	e8 72 30 00 00       	call   80103b8a <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 98 1a 00 00       	call   801025bb <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 dd 30 00 00       	call   80103c0e <end_op>
    return -1;
80100b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b36:	e9 1e 05 00 00       	jmp    80101059 <exec+0x54f>
  }
  ilock(ip);
80100b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b3e:	89 04 24             	mov    %eax,(%esp)
80100b41:	e8 c4 0e 00 00       	call   80101a0a <ilock>
  pgdir = 0;
80100b46:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b4d:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b54:	00 
80100b55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b5c:	00 
80100b5d:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100b63:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b67:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b6a:	89 04 24             	mov    %eax,(%esp)
80100b6d:	e8 ab 13 00 00       	call   80101f1d <readi>
80100b72:	83 f8 33             	cmp    $0x33,%eax
80100b75:	77 05                	ja     80100b7c <exec+0x72>
    goto bad;
80100b77:	e9 a9 04 00 00       	jmp    80101025 <exec+0x51b>
  if(elf.magic != ELF_MAGIC)
80100b7c:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100b82:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b87:	74 05                	je     80100b8e <exec+0x84>
    goto bad;
80100b89:	e9 97 04 00 00       	jmp    80101025 <exec+0x51b>
  if((pgdir = setupkvm()) == 0)
80100b8e:	e8 12 7a 00 00       	call   801085a5 <setupkvm>
80100b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b96:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b9a:	75 05                	jne    80100ba1 <exec+0x97>
    goto bad;
80100b9c:	e9 84 04 00 00       	jmp    80101025 <exec+0x51b>

  // Load program into memory.
  sz = 0;
80100ba1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  proc->numOfPages = 0;
80100ba8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100bae:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80100bb5:	00 00 00 
  int j;
  for(j = 0; j < 30; j++){
80100bb8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
80100bbf:	e9 a6 00 00 00       	jmp    80100c6a <exec+0x160>
    proc->pagesMetaData[j].va = (char *) -1;
80100bc4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bcb:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bce:	89 d0                	mov    %edx,%eax
80100bd0:	c1 e0 02             	shl    $0x2,%eax
80100bd3:	01 d0                	add    %edx,%eax
80100bd5:	c1 e0 02             	shl    $0x2,%eax
80100bd8:	01 c8                	add    %ecx,%eax
80100bda:	05 90 00 00 00       	add    $0x90,%eax
80100bdf:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    proc->pagesMetaData[j].isPhysical = 0;
80100be5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bec:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bef:	89 d0                	mov    %edx,%eax
80100bf1:	c1 e0 02             	shl    $0x2,%eax
80100bf4:	01 d0                	add    %edx,%eax
80100bf6:	c1 e0 02             	shl    $0x2,%eax
80100bf9:	01 c8                	add    %ecx,%eax
80100bfb:	05 94 00 00 00       	add    $0x94,%eax
80100c00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    proc->pagesMetaData[j].fileOffset = -1;
80100c06:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c0d:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c10:	89 d0                	mov    %edx,%eax
80100c12:	c1 e0 02             	shl    $0x2,%eax
80100c15:	01 d0                	add    %edx,%eax
80100c17:	c1 e0 02             	shl    $0x2,%eax
80100c1a:	01 c8                	add    %ecx,%eax
80100c1c:	05 98 00 00 00       	add    $0x98,%eax
80100c21:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    proc->pagesMetaData[j].count = 0;
80100c27:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c2e:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c31:	89 d0                	mov    %edx,%eax
80100c33:	c1 e0 02             	shl    $0x2,%eax
80100c36:	01 d0                	add    %edx,%eax
80100c38:	c1 e0 02             	shl    $0x2,%eax
80100c3b:	01 c8                	add    %ecx,%eax
80100c3d:	05 9c 00 00 00       	add    $0x9c,%eax
80100c42:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    proc->pagesMetaData[j].lru = 0x80;
80100c48:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c4f:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c52:	89 d0                	mov    %edx,%eax
80100c54:	c1 e0 02             	shl    $0x2,%eax
80100c57:	01 d0                	add    %edx,%eax
80100c59:	c1 e0 02             	shl    $0x2,%eax
80100c5c:	01 c8                	add    %ecx,%eax
80100c5e:	05 a0 00 00 00       	add    $0xa0,%eax
80100c63:	c6 00 80             	movb   $0x80,(%eax)

  // Load program into memory.
  sz = 0;
  proc->numOfPages = 0;
  int j;
  for(j = 0; j < 30; j++){
80100c66:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
80100c6a:	83 7d d0 1d          	cmpl   $0x1d,-0x30(%ebp)
80100c6e:	0f 8e 50 ff ff ff    	jle    80100bc4 <exec+0xba>
    proc->pagesMetaData[j].isPhysical = 0;
    proc->pagesMetaData[j].fileOffset = -1;
    proc->pagesMetaData[j].count = 0;
    proc->pagesMetaData[j].lru = 0x80;
  }
  proc->memoryPagesCounter = 0;
80100c74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c7a:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80100c81:	00 00 00 
  proc->swapedPagesCounter = 0;
80100c84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c8a:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80100c91:	00 00 00 
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c94:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c9b:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100ca1:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100ca4:	e9 d5 00 00 00       	jmp    80100d7e <exec+0x274>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ca9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100cac:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100cb3:	00 
80100cb4:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cb8:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100cbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cc5:	89 04 24             	mov    %eax,(%esp)
80100cc8:	e8 50 12 00 00       	call   80101f1d <readi>
80100ccd:	83 f8 20             	cmp    $0x20,%eax
80100cd0:	74 05                	je     80100cd7 <exec+0x1cd>
      goto bad;
80100cd2:	e9 4e 03 00 00       	jmp    80101025 <exec+0x51b>
    if(ph.type != ELF_PROG_LOAD)
80100cd7:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100cdd:	83 f8 01             	cmp    $0x1,%eax
80100ce0:	74 05                	je     80100ce7 <exec+0x1dd>
      continue;
80100ce2:	e9 8a 00 00 00       	jmp    80100d71 <exec+0x267>
    if(ph.memsz < ph.filesz)
80100ce7:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100ced:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100cf3:	39 c2                	cmp    %eax,%edx
80100cf5:	73 05                	jae    80100cfc <exec+0x1f2>
      goto bad;
80100cf7:	e9 29 03 00 00       	jmp    80101025 <exec+0x51b>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
80100cfc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100d02:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d08:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100d0e:	01 ca                	add    %ecx,%edx
80100d10:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100d14:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d18:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d22:	89 04 24             	mov    %eax,(%esp)
80100d25:	e8 49 7c 00 00       	call   80108973 <allocuvm>
80100d2a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d2d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d31:	75 05                	jne    80100d38 <exec+0x22e>
      goto bad;
80100d33:	e9 ed 02 00 00       	jmp    80101025 <exec+0x51b>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100d38:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100d3e:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100d44:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100d4a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100d4e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d52:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100d55:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d59:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d5d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d60:	89 04 24             	mov    %eax,(%esp)
80100d63:	e8 20 7b 00 00       	call   80108888 <loaduvm>
80100d68:	85 c0                	test   %eax,%eax
80100d6a:	79 05                	jns    80100d71 <exec+0x267>
      goto bad;
80100d6c:	e9 b4 02 00 00       	jmp    80101025 <exec+0x51b>
    proc->pagesMetaData[j].count = 0;
    proc->pagesMetaData[j].lru = 0x80;
  }
  proc->memoryPagesCounter = 0;
  proc->swapedPagesCounter = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d71:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d75:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d78:	83 c0 20             	add    $0x20,%eax
80100d7b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d7e:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d85:	0f b7 c0             	movzwl %ax,%eax
80100d88:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d8b:	0f 8f 18 ff ff ff    	jg     80100ca9 <exec+0x19f>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d91:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d94:	89 04 24             	mov    %eax,(%esp)
80100d97:	e8 f8 0e 00 00       	call   80101c94 <iunlockput>
  end_op();
80100d9c:	e8 6d 2e 00 00       	call   80103c0e <end_op>
  ip = 0;
80100da1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100da8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dab:	05 ff 0f 00 00       	add    $0xfff,%eax
80100db0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100db5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE,proc)) == 0)
80100db8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100dbe:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100dc1:	81 c2 00 20 00 00    	add    $0x2000,%edx
80100dc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100dcb:	89 54 24 08          	mov    %edx,0x8(%esp)
80100dcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100dd6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100dd9:	89 04 24             	mov    %eax,(%esp)
80100ddc:	e8 92 7b 00 00       	call   80108973 <allocuvm>
80100de1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100de4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100de8:	75 05                	jne    80100def <exec+0x2e5>
    goto bad;
80100dea:	e9 36 02 00 00       	jmp    80101025 <exec+0x51b>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100def:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100df2:	2d 00 20 00 00       	sub    $0x2000,%eax
80100df7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100dfb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100dfe:	89 04 24             	mov    %eax,(%esp)
80100e01:	e8 60 80 00 00       	call   80108e66 <clearpteu>
  sp = sz;
80100e06:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e09:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e0c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100e13:	e9 9a 00 00 00       	jmp    80100eb2 <exec+0x3a8>
    if(argc >= MAXARG)
80100e18:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100e1c:	76 05                	jbe    80100e23 <exec+0x319>
      goto bad;
80100e1e:	e9 02 02 00 00       	jmp    80101025 <exec+0x51b>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100e23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e26:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e30:	01 d0                	add    %edx,%eax
80100e32:	8b 00                	mov    (%eax),%eax
80100e34:	89 04 24             	mov    %eax,(%esp)
80100e37:	e8 33 4e 00 00       	call   80105c6f <strlen>
80100e3c:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100e3f:	29 c2                	sub    %eax,%edx
80100e41:	89 d0                	mov    %edx,%eax
80100e43:	83 e8 01             	sub    $0x1,%eax
80100e46:	83 e0 fc             	and    $0xfffffffc,%eax
80100e49:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100e4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e4f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e56:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e59:	01 d0                	add    %edx,%eax
80100e5b:	8b 00                	mov    (%eax),%eax
80100e5d:	89 04 24             	mov    %eax,(%esp)
80100e60:	e8 0a 4e 00 00       	call   80105c6f <strlen>
80100e65:	83 c0 01             	add    $0x1,%eax
80100e68:	89 c2                	mov    %eax,%edx
80100e6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e6d:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100e74:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e77:	01 c8                	add    %ecx,%eax
80100e79:	8b 00                	mov    (%eax),%eax
80100e7b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100e7f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e83:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e86:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e8d:	89 04 24             	mov    %eax,(%esp)
80100e90:	e8 a9 83 00 00       	call   8010923e <copyout>
80100e95:	85 c0                	test   %eax,%eax
80100e97:	79 05                	jns    80100e9e <exec+0x394>
      goto bad;
80100e99:	e9 87 01 00 00       	jmp    80101025 <exec+0x51b>
    ustack[3+argc] = sp;
80100e9e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ea1:	8d 50 03             	lea    0x3(%eax),%edx
80100ea4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea7:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100eae:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100eb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eb5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ebc:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ebf:	01 d0                	add    %edx,%eax
80100ec1:	8b 00                	mov    (%eax),%eax
80100ec3:	85 c0                	test   %eax,%eax
80100ec5:	0f 85 4d ff ff ff    	jne    80100e18 <exec+0x30e>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100ecb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ece:	83 c0 03             	add    $0x3,%eax
80100ed1:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100ed8:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100edc:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100ee3:	ff ff ff 
  ustack[1] = argc;
80100ee6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ee9:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100eef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ef2:	83 c0 01             	add    $0x1,%eax
80100ef5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100efc:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100eff:	29 d0                	sub    %edx,%eax
80100f01:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100f07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f0a:	83 c0 04             	add    $0x4,%eax
80100f0d:	c1 e0 02             	shl    $0x2,%eax
80100f10:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100f13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f16:	83 c0 04             	add    $0x4,%eax
80100f19:	c1 e0 02             	shl    $0x2,%eax
80100f1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100f20:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100f26:	89 44 24 08          	mov    %eax,0x8(%esp)
80100f2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100f2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f34:	89 04 24             	mov    %eax,(%esp)
80100f37:	e8 02 83 00 00       	call   8010923e <copyout>
80100f3c:	85 c0                	test   %eax,%eax
80100f3e:	79 05                	jns    80100f45 <exec+0x43b>
    goto bad;
80100f40:	e9 e0 00 00 00       	jmp    80101025 <exec+0x51b>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f45:	8b 45 08             	mov    0x8(%ebp),%eax
80100f48:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f4e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100f51:	eb 17                	jmp    80100f6a <exec+0x460>
    if(*s == '/')
80100f53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f56:	0f b6 00             	movzbl (%eax),%eax
80100f59:	3c 2f                	cmp    $0x2f,%al
80100f5b:	75 09                	jne    80100f66 <exec+0x45c>
      last = s+1;
80100f5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f60:	83 c0 01             	add    $0x1,%eax
80100f63:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f66:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f6d:	0f b6 00             	movzbl (%eax),%eax
80100f70:	84 c0                	test   %al,%al
80100f72:	75 df                	jne    80100f53 <exec+0x449>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f7a:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f7d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f84:	00 
80100f85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100f88:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f8c:	89 14 24             	mov    %edx,(%esp)
80100f8f:	e8 91 4c 00 00       	call   80105c25 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f9a:	8b 40 04             	mov    0x4(%eax),%eax
80100f9d:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100fa0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fa6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100fa9:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100fac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fb2:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100fb5:	89 10                	mov    %edx,(%eax)
  //change proc->pagesMetaData according to the new exec
  if(!isInit()){
80100fb7:	e8 85 8a 00 00       	call   80109a41 <isInit>
80100fbc:	85 c0                	test   %eax,%eax
80100fbe:	75 1c                	jne    80100fdc <exec+0x4d2>
    removeSwapFile(proc);
80100fc0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fc6:	89 04 24             	mov    %eax,(%esp)
80100fc9:	e8 f2 16 00 00       	call   801026c0 <removeSwapFile>
    createSwapFile(proc);
80100fce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fd4:	89 04 24             	mov    %eax,(%esp)
80100fd7:	e8 f0 18 00 00       	call   801028cc <createSwapFile>
  //END NEW
  }
  proc->tf->eip = elf.entry;  // main
80100fdc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fe2:	8b 40 18             	mov    0x18(%eax),%eax
80100fe5:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100feb:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100fee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ff4:	8b 40 18             	mov    0x18(%eax),%eax
80100ff7:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ffa:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ffd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101003:	89 04 24             	mov    %eax,(%esp)
80101006:	e8 8b 76 00 00       	call   80108696 <switchuvm>
  freevm(oldpgdir,0);
8010100b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101012:	00 
80101013:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101016:	89 04 24             	mov    %eax,(%esp)
80101019:	e8 a4 7d 00 00       	call   80108dc2 <freevm>
  return 0;
8010101e:	b8 00 00 00 00       	mov    $0x0,%eax
80101023:	eb 34                	jmp    80101059 <exec+0x54f>

 bad:
  if(pgdir)
80101025:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101029:	74 13                	je     8010103e <exec+0x534>
    freevm(pgdir,0);
8010102b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101032:	00 
80101033:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101036:	89 04 24             	mov    %eax,(%esp)
80101039:	e8 84 7d 00 00       	call   80108dc2 <freevm>
  if(ip){
8010103e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101042:	74 10                	je     80101054 <exec+0x54a>
    iunlockput(ip);
80101044:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101047:	89 04 24             	mov    %eax,(%esp)
8010104a:	e8 45 0c 00 00       	call   80101c94 <iunlockput>
    end_op();
8010104f:	e8 ba 2b 00 00       	call   80103c0e <end_op>
  }
  return -1;
80101054:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101059:	c9                   	leave  
8010105a:	c3                   	ret    

8010105b <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
8010105b:	55                   	push   %ebp
8010105c:	89 e5                	mov    %esp,%ebp
8010105e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80101061:	c7 44 24 04 f2 9a 10 	movl   $0x80109af2,0x4(%esp)
80101068:	80 
80101069:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101070:	e8 1b 47 00 00       	call   80105790 <initlock>
}
80101075:	c9                   	leave  
80101076:	c3                   	ret    

80101077 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101077:	55                   	push   %ebp
80101078:	89 e5                	mov    %esp,%ebp
8010107a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010107d:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101084:	e8 28 47 00 00       	call   801057b1 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101089:	c7 45 f4 54 28 11 80 	movl   $0x80112854,-0xc(%ebp)
80101090:	eb 29                	jmp    801010bb <filealloc+0x44>
    if(f->ref == 0){
80101092:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101095:	8b 40 04             	mov    0x4(%eax),%eax
80101098:	85 c0                	test   %eax,%eax
8010109a:	75 1b                	jne    801010b7 <filealloc+0x40>
      f->ref = 1;
8010109c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010109f:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
801010a6:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010ad:	e8 61 47 00 00       	call   80105813 <release>
      return f;
801010b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010b5:	eb 1e                	jmp    801010d5 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801010b7:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
801010bb:	81 7d f4 b4 31 11 80 	cmpl   $0x801131b4,-0xc(%ebp)
801010c2:	72 ce                	jb     80101092 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
801010c4:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010cb:	e8 43 47 00 00       	call   80105813 <release>
  return 0;
801010d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801010d5:	c9                   	leave  
801010d6:	c3                   	ret    

801010d7 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
801010d7:	55                   	push   %ebp
801010d8:	89 e5                	mov    %esp,%ebp
801010da:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
801010dd:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010e4:	e8 c8 46 00 00       	call   801057b1 <acquire>
  if(f->ref < 1)
801010e9:	8b 45 08             	mov    0x8(%ebp),%eax
801010ec:	8b 40 04             	mov    0x4(%eax),%eax
801010ef:	85 c0                	test   %eax,%eax
801010f1:	7f 0c                	jg     801010ff <filedup+0x28>
    panic("filedup");
801010f3:	c7 04 24 f9 9a 10 80 	movl   $0x80109af9,(%esp)
801010fa:	e8 3b f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101102:	8b 40 04             	mov    0x4(%eax),%eax
80101105:	8d 50 01             	lea    0x1(%eax),%edx
80101108:	8b 45 08             	mov    0x8(%ebp),%eax
8010110b:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010110e:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101115:	e8 f9 46 00 00       	call   80105813 <release>
  return f;
8010111a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010111d:	c9                   	leave  
8010111e:	c3                   	ret    

8010111f <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010111f:	55                   	push   %ebp
80101120:	89 e5                	mov    %esp,%ebp
80101122:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101125:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010112c:	e8 80 46 00 00       	call   801057b1 <acquire>
  if(f->ref < 1)
80101131:	8b 45 08             	mov    0x8(%ebp),%eax
80101134:	8b 40 04             	mov    0x4(%eax),%eax
80101137:	85 c0                	test   %eax,%eax
80101139:	7f 0c                	jg     80101147 <fileclose+0x28>
    panic("fileclose");
8010113b:	c7 04 24 01 9b 10 80 	movl   $0x80109b01,(%esp)
80101142:	e8 f3 f3 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80101147:	8b 45 08             	mov    0x8(%ebp),%eax
8010114a:	8b 40 04             	mov    0x4(%eax),%eax
8010114d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101150:	8b 45 08             	mov    0x8(%ebp),%eax
80101153:	89 50 04             	mov    %edx,0x4(%eax)
80101156:	8b 45 08             	mov    0x8(%ebp),%eax
80101159:	8b 40 04             	mov    0x4(%eax),%eax
8010115c:	85 c0                	test   %eax,%eax
8010115e:	7e 11                	jle    80101171 <fileclose+0x52>
    release(&ftable.lock);
80101160:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101167:	e8 a7 46 00 00       	call   80105813 <release>
8010116c:	e9 82 00 00 00       	jmp    801011f3 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101171:	8b 45 08             	mov    0x8(%ebp),%eax
80101174:	8b 10                	mov    (%eax),%edx
80101176:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101179:	8b 50 04             	mov    0x4(%eax),%edx
8010117c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010117f:	8b 50 08             	mov    0x8(%eax),%edx
80101182:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101185:	8b 50 0c             	mov    0xc(%eax),%edx
80101188:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010118b:	8b 50 10             	mov    0x10(%eax),%edx
8010118e:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101191:	8b 40 14             	mov    0x14(%eax),%eax
80101194:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101197:	8b 45 08             	mov    0x8(%ebp),%eax
8010119a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801011a1:	8b 45 08             	mov    0x8(%ebp),%eax
801011a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
801011aa:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801011b1:	e8 5d 46 00 00       	call   80105813 <release>
  
  if(ff.type == FD_PIPE)
801011b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011b9:	83 f8 01             	cmp    $0x1,%eax
801011bc:	75 18                	jne    801011d6 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801011be:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801011c2:	0f be d0             	movsbl %al,%edx
801011c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801011c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801011cc:	89 04 24             	mov    %eax,(%esp)
801011cf:	e8 05 36 00 00       	call   801047d9 <pipeclose>
801011d4:	eb 1d                	jmp    801011f3 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801011d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011d9:	83 f8 02             	cmp    $0x2,%eax
801011dc:	75 15                	jne    801011f3 <fileclose+0xd4>
    begin_op();
801011de:	e8 a7 29 00 00       	call   80103b8a <begin_op>
    iput(ff.ip);
801011e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801011e6:	89 04 24             	mov    %eax,(%esp)
801011e9:	e8 d5 09 00 00       	call   80101bc3 <iput>
    end_op();
801011ee:	e8 1b 2a 00 00       	call   80103c0e <end_op>
  }
}
801011f3:	c9                   	leave  
801011f4:	c3                   	ret    

801011f5 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801011f5:	55                   	push   %ebp
801011f6:	89 e5                	mov    %esp,%ebp
801011f8:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011fb:	8b 45 08             	mov    0x8(%ebp),%eax
801011fe:	8b 00                	mov    (%eax),%eax
80101200:	83 f8 02             	cmp    $0x2,%eax
80101203:	75 38                	jne    8010123d <filestat+0x48>
    ilock(f->ip);
80101205:	8b 45 08             	mov    0x8(%ebp),%eax
80101208:	8b 40 10             	mov    0x10(%eax),%eax
8010120b:	89 04 24             	mov    %eax,(%esp)
8010120e:	e8 f7 07 00 00       	call   80101a0a <ilock>
    stati(f->ip, st);
80101213:	8b 45 08             	mov    0x8(%ebp),%eax
80101216:	8b 40 10             	mov    0x10(%eax),%eax
80101219:	8b 55 0c             	mov    0xc(%ebp),%edx
8010121c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101220:	89 04 24             	mov    %eax,(%esp)
80101223:	e8 b0 0c 00 00       	call   80101ed8 <stati>
    iunlock(f->ip);
80101228:	8b 45 08             	mov    0x8(%ebp),%eax
8010122b:	8b 40 10             	mov    0x10(%eax),%eax
8010122e:	89 04 24             	mov    %eax,(%esp)
80101231:	e8 28 09 00 00       	call   80101b5e <iunlock>
    return 0;
80101236:	b8 00 00 00 00       	mov    $0x0,%eax
8010123b:	eb 05                	jmp    80101242 <filestat+0x4d>
  }
  return -1;
8010123d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101242:	c9                   	leave  
80101243:	c3                   	ret    

80101244 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101244:	55                   	push   %ebp
80101245:	89 e5                	mov    %esp,%ebp
80101247:	83 ec 28             	sub    $0x28,%esp
  int r;
  if(f->readable == 0)
8010124a:	8b 45 08             	mov    0x8(%ebp),%eax
8010124d:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101251:	84 c0                	test   %al,%al
80101253:	75 0a                	jne    8010125f <fileread+0x1b>
    return -1;
80101255:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010125a:	e9 9f 00 00 00       	jmp    801012fe <fileread+0xba>
  if(f->type == FD_PIPE)
8010125f:	8b 45 08             	mov    0x8(%ebp),%eax
80101262:	8b 00                	mov    (%eax),%eax
80101264:	83 f8 01             	cmp    $0x1,%eax
80101267:	75 1e                	jne    80101287 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101269:	8b 45 08             	mov    0x8(%ebp),%eax
8010126c:	8b 40 0c             	mov    0xc(%eax),%eax
8010126f:	8b 55 10             	mov    0x10(%ebp),%edx
80101272:	89 54 24 08          	mov    %edx,0x8(%esp)
80101276:	8b 55 0c             	mov    0xc(%ebp),%edx
80101279:	89 54 24 04          	mov    %edx,0x4(%esp)
8010127d:	89 04 24             	mov    %eax,(%esp)
80101280:	e8 d5 36 00 00       	call   8010495a <piperead>
80101285:	eb 77                	jmp    801012fe <fileread+0xba>
  if(f->type == FD_INODE){
80101287:	8b 45 08             	mov    0x8(%ebp),%eax
8010128a:	8b 00                	mov    (%eax),%eax
8010128c:	83 f8 02             	cmp    $0x2,%eax
8010128f:	75 61                	jne    801012f2 <fileread+0xae>
    ilock(f->ip);
80101291:	8b 45 08             	mov    0x8(%ebp),%eax
80101294:	8b 40 10             	mov    0x10(%eax),%eax
80101297:	89 04 24             	mov    %eax,(%esp)
8010129a:	e8 6b 07 00 00       	call   80101a0a <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010129f:	8b 4d 10             	mov    0x10(%ebp),%ecx
801012a2:	8b 45 08             	mov    0x8(%ebp),%eax
801012a5:	8b 50 14             	mov    0x14(%eax),%edx
801012a8:	8b 45 08             	mov    0x8(%ebp),%eax
801012ab:	8b 40 10             	mov    0x10(%eax),%eax
801012ae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801012b2:	89 54 24 08          	mov    %edx,0x8(%esp)
801012b6:	8b 55 0c             	mov    0xc(%ebp),%edx
801012b9:	89 54 24 04          	mov    %edx,0x4(%esp)
801012bd:	89 04 24             	mov    %eax,(%esp)
801012c0:	e8 58 0c 00 00       	call   80101f1d <readi>
801012c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801012c8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801012cc:	7e 11                	jle    801012df <fileread+0x9b>
      f->off += r;
801012ce:	8b 45 08             	mov    0x8(%ebp),%eax
801012d1:	8b 50 14             	mov    0x14(%eax),%edx
801012d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012d7:	01 c2                	add    %eax,%edx
801012d9:	8b 45 08             	mov    0x8(%ebp),%eax
801012dc:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801012df:	8b 45 08             	mov    0x8(%ebp),%eax
801012e2:	8b 40 10             	mov    0x10(%eax),%eax
801012e5:	89 04 24             	mov    %eax,(%esp)
801012e8:	e8 71 08 00 00       	call   80101b5e <iunlock>
    return r;
801012ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012f0:	eb 0c                	jmp    801012fe <fileread+0xba>
  }
  panic("fileread");
801012f2:	c7 04 24 0b 9b 10 80 	movl   $0x80109b0b,(%esp)
801012f9:	e8 3c f2 ff ff       	call   8010053a <panic>
}
801012fe:	c9                   	leave  
801012ff:	c3                   	ret    

80101300 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80101300:	55                   	push   %ebp
80101301:	89 e5                	mov    %esp,%ebp
80101303:	53                   	push   %ebx
80101304:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101307:	8b 45 08             	mov    0x8(%ebp),%eax
8010130a:	0f b6 40 09          	movzbl 0x9(%eax),%eax
8010130e:	84 c0                	test   %al,%al
80101310:	75 0a                	jne    8010131c <filewrite+0x1c>
    return -1;
80101312:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101317:	e9 20 01 00 00       	jmp    8010143c <filewrite+0x13c>
  if(f->type == FD_PIPE)
8010131c:	8b 45 08             	mov    0x8(%ebp),%eax
8010131f:	8b 00                	mov    (%eax),%eax
80101321:	83 f8 01             	cmp    $0x1,%eax
80101324:	75 21                	jne    80101347 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101326:	8b 45 08             	mov    0x8(%ebp),%eax
80101329:	8b 40 0c             	mov    0xc(%eax),%eax
8010132c:	8b 55 10             	mov    0x10(%ebp),%edx
8010132f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101333:	8b 55 0c             	mov    0xc(%ebp),%edx
80101336:	89 54 24 04          	mov    %edx,0x4(%esp)
8010133a:	89 04 24             	mov    %eax,(%esp)
8010133d:	e8 29 35 00 00       	call   8010486b <pipewrite>
80101342:	e9 f5 00 00 00       	jmp    8010143c <filewrite+0x13c>
  if(f->type == FD_INODE){
80101347:	8b 45 08             	mov    0x8(%ebp),%eax
8010134a:	8b 00                	mov    (%eax),%eax
8010134c:	83 f8 02             	cmp    $0x2,%eax
8010134f:	0f 85 db 00 00 00    	jne    80101430 <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101355:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010135c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101363:	e9 a8 00 00 00       	jmp    80101410 <filewrite+0x110>
      int n1 = n - i;
80101368:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136b:	8b 55 10             	mov    0x10(%ebp),%edx
8010136e:	29 c2                	sub    %eax,%edx
80101370:	89 d0                	mov    %edx,%eax
80101372:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101375:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101378:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010137b:	7e 06                	jle    80101383 <filewrite+0x83>
        n1 = max;
8010137d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101380:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101383:	e8 02 28 00 00       	call   80103b8a <begin_op>
      ilock(f->ip);
80101388:	8b 45 08             	mov    0x8(%ebp),%eax
8010138b:	8b 40 10             	mov    0x10(%eax),%eax
8010138e:	89 04 24             	mov    %eax,(%esp)
80101391:	e8 74 06 00 00       	call   80101a0a <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0){
80101396:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101399:	8b 45 08             	mov    0x8(%ebp),%eax
8010139c:	8b 50 14             	mov    0x14(%eax),%edx
8010139f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
801013a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801013a5:	01 c3                	add    %eax,%ebx
801013a7:	8b 45 08             	mov    0x8(%ebp),%eax
801013aa:	8b 40 10             	mov    0x10(%eax),%eax
801013ad:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801013b1:	89 54 24 08          	mov    %edx,0x8(%esp)
801013b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
801013b9:	89 04 24             	mov    %eax,(%esp)
801013bc:	e8 c0 0c 00 00       	call   80102081 <writei>
801013c1:	89 45 e8             	mov    %eax,-0x18(%ebp)
801013c4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013c8:	7e 11                	jle    801013db <filewrite+0xdb>
        f->off += r;
801013ca:	8b 45 08             	mov    0x8(%ebp),%eax
801013cd:	8b 50 14             	mov    0x14(%eax),%edx
801013d0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013d3:	01 c2                	add    %eax,%edx
801013d5:	8b 45 08             	mov    0x8(%ebp),%eax
801013d8:	89 50 14             	mov    %edx,0x14(%eax)
      }
      iunlock(f->ip);
801013db:	8b 45 08             	mov    0x8(%ebp),%eax
801013de:	8b 40 10             	mov    0x10(%eax),%eax
801013e1:	89 04 24             	mov    %eax,(%esp)
801013e4:	e8 75 07 00 00       	call   80101b5e <iunlock>
      end_op();
801013e9:	e8 20 28 00 00       	call   80103c0e <end_op>

      if(r < 0)
801013ee:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013f2:	79 02                	jns    801013f6 <filewrite+0xf6>
        break;
801013f4:	eb 26                	jmp    8010141c <filewrite+0x11c>
      if(r != n1)
801013f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013f9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013fc:	74 0c                	je     8010140a <filewrite+0x10a>
        panic("short filewrite");
801013fe:	c7 04 24 14 9b 10 80 	movl   $0x80109b14,(%esp)
80101405:	e8 30 f1 ff ff       	call   8010053a <panic>
      i += r;
8010140a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010140d:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
80101410:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101413:	3b 45 10             	cmp    0x10(%ebp),%eax
80101416:	0f 8c 4c ff ff ff    	jl     80101368 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
8010141c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010141f:	3b 45 10             	cmp    0x10(%ebp),%eax
80101422:	75 05                	jne    80101429 <filewrite+0x129>
80101424:	8b 45 10             	mov    0x10(%ebp),%eax
80101427:	eb 05                	jmp    8010142e <filewrite+0x12e>
80101429:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010142e:	eb 0c                	jmp    8010143c <filewrite+0x13c>
  }
  panic("filewrite");
80101430:	c7 04 24 24 9b 10 80 	movl   $0x80109b24,(%esp)
80101437:	e8 fe f0 ff ff       	call   8010053a <panic>
}
8010143c:	83 c4 24             	add    $0x24,%esp
8010143f:	5b                   	pop    %ebx
80101440:	5d                   	pop    %ebp
80101441:	c3                   	ret    

80101442 <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101442:	55                   	push   %ebp
80101443:	89 e5                	mov    %esp,%ebp
80101445:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101448:	8b 45 08             	mov    0x8(%ebp),%eax
8010144b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101452:	00 
80101453:	89 04 24             	mov    %eax,(%esp)
80101456:	e8 4b ed ff ff       	call   801001a6 <bread>
8010145b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010145e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101461:	83 c0 18             	add    $0x18,%eax
80101464:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
8010146b:	00 
8010146c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101470:	8b 45 0c             	mov    0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 59 46 00 00       	call   80105ad4 <memmove>
  brelse(bp);
8010147b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010147e:	89 04 24             	mov    %eax,(%esp)
80101481:	e8 91 ed ff ff       	call   80100217 <brelse>
}
80101486:	c9                   	leave  
80101487:	c3                   	ret    

80101488 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101488:	55                   	push   %ebp
80101489:	89 e5                	mov    %esp,%ebp
8010148b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010148e:	8b 55 0c             	mov    0xc(%ebp),%edx
80101491:	8b 45 08             	mov    0x8(%ebp),%eax
80101494:	89 54 24 04          	mov    %edx,0x4(%esp)
80101498:	89 04 24             	mov    %eax,(%esp)
8010149b:	e8 06 ed ff ff       	call   801001a6 <bread>
801014a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801014a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014a6:	83 c0 18             	add    $0x18,%eax
801014a9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801014b0:	00 
801014b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801014b8:	00 
801014b9:	89 04 24             	mov    %eax,(%esp)
801014bc:	e8 44 45 00 00       	call   80105a05 <memset>
  log_write(bp);
801014c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014c4:	89 04 24             	mov    %eax,(%esp)
801014c7:	e8 c9 28 00 00       	call   80103d95 <log_write>
  brelse(bp);
801014cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014cf:	89 04 24             	mov    %eax,(%esp)
801014d2:	e8 40 ed ff ff       	call   80100217 <brelse>
}
801014d7:	c9                   	leave  
801014d8:	c3                   	ret    

801014d9 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801014d9:	55                   	push   %ebp
801014da:	89 e5                	mov    %esp,%ebp
801014dc:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801014df:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801014e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014ed:	e9 07 01 00 00       	jmp    801015f9 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
801014f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014f5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014fb:	85 c0                	test   %eax,%eax
801014fd:	0f 48 c2             	cmovs  %edx,%eax
80101500:	c1 f8 0c             	sar    $0xc,%eax
80101503:	89 c2                	mov    %eax,%edx
80101505:	a1 38 32 11 80       	mov    0x80113238,%eax
8010150a:	01 d0                	add    %edx,%eax
8010150c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101510:	8b 45 08             	mov    0x8(%ebp),%eax
80101513:	89 04 24             	mov    %eax,(%esp)
80101516:	e8 8b ec ff ff       	call   801001a6 <bread>
8010151b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010151e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101525:	e9 9d 00 00 00       	jmp    801015c7 <balloc+0xee>
      m = 1 << (bi % 8);
8010152a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010152d:	99                   	cltd   
8010152e:	c1 ea 1d             	shr    $0x1d,%edx
80101531:	01 d0                	add    %edx,%eax
80101533:	83 e0 07             	and    $0x7,%eax
80101536:	29 d0                	sub    %edx,%eax
80101538:	ba 01 00 00 00       	mov    $0x1,%edx
8010153d:	89 c1                	mov    %eax,%ecx
8010153f:	d3 e2                	shl    %cl,%edx
80101541:	89 d0                	mov    %edx,%eax
80101543:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101546:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101549:	8d 50 07             	lea    0x7(%eax),%edx
8010154c:	85 c0                	test   %eax,%eax
8010154e:	0f 48 c2             	cmovs  %edx,%eax
80101551:	c1 f8 03             	sar    $0x3,%eax
80101554:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101557:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010155c:	0f b6 c0             	movzbl %al,%eax
8010155f:	23 45 e8             	and    -0x18(%ebp),%eax
80101562:	85 c0                	test   %eax,%eax
80101564:	75 5d                	jne    801015c3 <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	8d 50 07             	lea    0x7(%eax),%edx
8010156c:	85 c0                	test   %eax,%eax
8010156e:	0f 48 c2             	cmovs  %edx,%eax
80101571:	c1 f8 03             	sar    $0x3,%eax
80101574:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101577:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010157c:	89 d1                	mov    %edx,%ecx
8010157e:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101581:	09 ca                	or     %ecx,%edx
80101583:	89 d1                	mov    %edx,%ecx
80101585:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101588:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010158c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010158f:	89 04 24             	mov    %eax,(%esp)
80101592:	e8 fe 27 00 00       	call   80103d95 <log_write>
        brelse(bp);
80101597:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 75 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801015a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015a8:	01 c2                	add    %eax,%edx
801015aa:	8b 45 08             	mov    0x8(%ebp),%eax
801015ad:	89 54 24 04          	mov    %edx,0x4(%esp)
801015b1:	89 04 24             	mov    %eax,(%esp)
801015b4:	e8 cf fe ff ff       	call   80101488 <bzero>
        return b + bi;
801015b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015bf:	01 d0                	add    %edx,%eax
801015c1:	eb 52                	jmp    80101615 <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801015c3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801015c7:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801015ce:	7f 17                	jg     801015e7 <balloc+0x10e>
801015d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015d6:	01 d0                	add    %edx,%eax
801015d8:	89 c2                	mov    %eax,%edx
801015da:	a1 20 32 11 80       	mov    0x80113220,%eax
801015df:	39 c2                	cmp    %eax,%edx
801015e1:	0f 82 43 ff ff ff    	jb     8010152a <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801015e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015ea:	89 04 24             	mov    %eax,(%esp)
801015ed:	e8 25 ec ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
801015f2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015fc:	a1 20 32 11 80       	mov    0x80113220,%eax
80101601:	39 c2                	cmp    %eax,%edx
80101603:	0f 82 e9 fe ff ff    	jb     801014f2 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101609:	c7 04 24 30 9b 10 80 	movl   $0x80109b30,(%esp)
80101610:	e8 25 ef ff ff       	call   8010053a <panic>
}
80101615:	c9                   	leave  
80101616:	c3                   	ret    

80101617 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101617:	55                   	push   %ebp
80101618:	89 e5                	mov    %esp,%ebp
8010161a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
8010161d:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
80101624:	80 
80101625:	8b 45 08             	mov    0x8(%ebp),%eax
80101628:	89 04 24             	mov    %eax,(%esp)
8010162b:	e8 12 fe ff ff       	call   80101442 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101630:	8b 45 0c             	mov    0xc(%ebp),%eax
80101633:	c1 e8 0c             	shr    $0xc,%eax
80101636:	89 c2                	mov    %eax,%edx
80101638:	a1 38 32 11 80       	mov    0x80113238,%eax
8010163d:	01 c2                	add    %eax,%edx
8010163f:	8b 45 08             	mov    0x8(%ebp),%eax
80101642:	89 54 24 04          	mov    %edx,0x4(%esp)
80101646:	89 04 24             	mov    %eax,(%esp)
80101649:	e8 58 eb ff ff       	call   801001a6 <bread>
8010164e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101651:	8b 45 0c             	mov    0xc(%ebp),%eax
80101654:	25 ff 0f 00 00       	and    $0xfff,%eax
80101659:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010165c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165f:	99                   	cltd   
80101660:	c1 ea 1d             	shr    $0x1d,%edx
80101663:	01 d0                	add    %edx,%eax
80101665:	83 e0 07             	and    $0x7,%eax
80101668:	29 d0                	sub    %edx,%eax
8010166a:	ba 01 00 00 00       	mov    $0x1,%edx
8010166f:	89 c1                	mov    %eax,%ecx
80101671:	d3 e2                	shl    %cl,%edx
80101673:	89 d0                	mov    %edx,%eax
80101675:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101678:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167b:	8d 50 07             	lea    0x7(%eax),%edx
8010167e:	85 c0                	test   %eax,%eax
80101680:	0f 48 c2             	cmovs  %edx,%eax
80101683:	c1 f8 03             	sar    $0x3,%eax
80101686:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101689:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010168e:	0f b6 c0             	movzbl %al,%eax
80101691:	23 45 ec             	and    -0x14(%ebp),%eax
80101694:	85 c0                	test   %eax,%eax
80101696:	75 0c                	jne    801016a4 <bfree+0x8d>
    panic("freeing free block");
80101698:	c7 04 24 46 9b 10 80 	movl   $0x80109b46,(%esp)
8010169f:	e8 96 ee ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
801016a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016a7:	8d 50 07             	lea    0x7(%eax),%edx
801016aa:	85 c0                	test   %eax,%eax
801016ac:	0f 48 c2             	cmovs  %edx,%eax
801016af:	c1 f8 03             	sar    $0x3,%eax
801016b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016b5:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801016ba:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801016bd:	f7 d1                	not    %ecx
801016bf:	21 ca                	and    %ecx,%edx
801016c1:	89 d1                	mov    %edx,%ecx
801016c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016c6:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801016ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016cd:	89 04 24             	mov    %eax,(%esp)
801016d0:	e8 c0 26 00 00       	call   80103d95 <log_write>
  brelse(bp);
801016d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016d8:	89 04 24             	mov    %eax,(%esp)
801016db:	e8 37 eb ff ff       	call   80100217 <brelse>
}
801016e0:	c9                   	leave  
801016e1:	c3                   	ret    

801016e2 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
801016e2:	55                   	push   %ebp
801016e3:	89 e5                	mov    %esp,%ebp
801016e5:	57                   	push   %edi
801016e6:	56                   	push   %esi
801016e7:	53                   	push   %ebx
801016e8:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
801016eb:	c7 44 24 04 59 9b 10 	movl   $0x80109b59,0x4(%esp)
801016f2:	80 
801016f3:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801016fa:	e8 91 40 00 00       	call   80105790 <initlock>
  readsb(dev, &sb);
801016ff:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
80101706:	80 
80101707:	8b 45 08             	mov    0x8(%ebp),%eax
8010170a:	89 04 24             	mov    %eax,(%esp)
8010170d:	e8 30 fd ff ff       	call   80101442 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
80101712:	a1 38 32 11 80       	mov    0x80113238,%eax
80101717:	8b 3d 34 32 11 80    	mov    0x80113234,%edi
8010171d:	8b 35 30 32 11 80    	mov    0x80113230,%esi
80101723:	8b 1d 2c 32 11 80    	mov    0x8011322c,%ebx
80101729:	8b 0d 28 32 11 80    	mov    0x80113228,%ecx
8010172f:	8b 15 24 32 11 80    	mov    0x80113224,%edx
80101735:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101738:	8b 15 20 32 11 80    	mov    0x80113220,%edx
8010173e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101742:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101746:	89 74 24 14          	mov    %esi,0x14(%esp)
8010174a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010174e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101752:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101755:	89 44 24 08          	mov    %eax,0x8(%esp)
80101759:	89 d0                	mov    %edx,%eax
8010175b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010175f:	c7 04 24 60 9b 10 80 	movl   $0x80109b60,(%esp)
80101766:	e8 35 ec ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
8010176b:	83 c4 3c             	add    $0x3c,%esp
8010176e:	5b                   	pop    %ebx
8010176f:	5e                   	pop    %esi
80101770:	5f                   	pop    %edi
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	83 ec 28             	sub    $0x28,%esp
80101779:	8b 45 0c             	mov    0xc(%ebp),%eax
8010177c:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101780:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101787:	e9 9e 00 00 00       	jmp    8010182a <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
8010178c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010178f:	c1 e8 03             	shr    $0x3,%eax
80101792:	89 c2                	mov    %eax,%edx
80101794:	a1 34 32 11 80       	mov    0x80113234,%eax
80101799:	01 d0                	add    %edx,%eax
8010179b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010179f:	8b 45 08             	mov    0x8(%ebp),%eax
801017a2:	89 04 24             	mov    %eax,(%esp)
801017a5:	e8 fc e9 ff ff       	call   801001a6 <bread>
801017aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801017ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017b0:	8d 50 18             	lea    0x18(%eax),%edx
801017b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b6:	83 e0 07             	and    $0x7,%eax
801017b9:	c1 e0 06             	shl    $0x6,%eax
801017bc:	01 d0                	add    %edx,%eax
801017be:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801017c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017c4:	0f b7 00             	movzwl (%eax),%eax
801017c7:	66 85 c0             	test   %ax,%ax
801017ca:	75 4f                	jne    8010181b <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
801017cc:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801017d3:	00 
801017d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801017db:	00 
801017dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017df:	89 04 24             	mov    %eax,(%esp)
801017e2:	e8 1e 42 00 00       	call   80105a05 <memset>
      dip->type = type;
801017e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ea:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017ee:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f4:	89 04 24             	mov    %eax,(%esp)
801017f7:	e8 99 25 00 00       	call   80103d95 <log_write>
      brelse(bp);
801017fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ff:	89 04 24             	mov    %eax,(%esp)
80101802:	e8 10 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010180e:	8b 45 08             	mov    0x8(%ebp),%eax
80101811:	89 04 24             	mov    %eax,(%esp)
80101814:	e8 ed 00 00 00       	call   80101906 <iget>
80101819:	eb 2b                	jmp    80101846 <ialloc+0xd3>
    }
    brelse(bp);
8010181b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010181e:	89 04 24             	mov    %eax,(%esp)
80101821:	e8 f1 e9 ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101826:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010182a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010182d:	a1 28 32 11 80       	mov    0x80113228,%eax
80101832:	39 c2                	cmp    %eax,%edx
80101834:	0f 82 52 ff ff ff    	jb     8010178c <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010183a:	c7 04 24 b3 9b 10 80 	movl   $0x80109bb3,(%esp)
80101841:	e8 f4 ec ff ff       	call   8010053a <panic>
}
80101846:	c9                   	leave  
80101847:	c3                   	ret    

80101848 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101848:	55                   	push   %ebp
80101849:	89 e5                	mov    %esp,%ebp
8010184b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010184e:	8b 45 08             	mov    0x8(%ebp),%eax
80101851:	8b 40 04             	mov    0x4(%eax),%eax
80101854:	c1 e8 03             	shr    $0x3,%eax
80101857:	89 c2                	mov    %eax,%edx
80101859:	a1 34 32 11 80       	mov    0x80113234,%eax
8010185e:	01 c2                	add    %eax,%edx
80101860:	8b 45 08             	mov    0x8(%ebp),%eax
80101863:	8b 00                	mov    (%eax),%eax
80101865:	89 54 24 04          	mov    %edx,0x4(%esp)
80101869:	89 04 24             	mov    %eax,(%esp)
8010186c:	e8 35 e9 ff ff       	call   801001a6 <bread>
80101871:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101877:	8d 50 18             	lea    0x18(%eax),%edx
8010187a:	8b 45 08             	mov    0x8(%ebp),%eax
8010187d:	8b 40 04             	mov    0x4(%eax),%eax
80101880:	83 e0 07             	and    $0x7,%eax
80101883:	c1 e0 06             	shl    $0x6,%eax
80101886:	01 d0                	add    %edx,%eax
80101888:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010188b:	8b 45 08             	mov    0x8(%ebp),%eax
8010188e:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101892:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101895:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101898:	8b 45 08             	mov    0x8(%ebp),%eax
8010189b:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010189f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018a2:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801018a6:	8b 45 08             	mov    0x8(%ebp),%eax
801018a9:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801018ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b0:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801018b4:	8b 45 08             	mov    0x8(%ebp),%eax
801018b7:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801018bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018be:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801018c2:	8b 45 08             	mov    0x8(%ebp),%eax
801018c5:	8b 50 18             	mov    0x18(%eax),%edx
801018c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018cb:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801018ce:	8b 45 08             	mov    0x8(%ebp),%eax
801018d1:	8d 50 1c             	lea    0x1c(%eax),%edx
801018d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018d7:	83 c0 0c             	add    $0xc,%eax
801018da:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801018e1:	00 
801018e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801018e6:	89 04 24             	mov    %eax,(%esp)
801018e9:	e8 e6 41 00 00       	call   80105ad4 <memmove>
  log_write(bp);
801018ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f1:	89 04 24             	mov    %eax,(%esp)
801018f4:	e8 9c 24 00 00       	call   80103d95 <log_write>
  brelse(bp);
801018f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fc:	89 04 24             	mov    %eax,(%esp)
801018ff:	e8 13 e9 ff ff       	call   80100217 <brelse>
}
80101904:	c9                   	leave  
80101905:	c3                   	ret    

80101906 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101906:	55                   	push   %ebp
80101907:	89 e5                	mov    %esp,%ebp
80101909:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010190c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101913:	e8 99 3e 00 00       	call   801057b1 <acquire>

  // Is the inode already cached?
  empty = 0;
80101918:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010191f:	c7 45 f4 74 32 11 80 	movl   $0x80113274,-0xc(%ebp)
80101926:	eb 59                	jmp    80101981 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010192b:	8b 40 08             	mov    0x8(%eax),%eax
8010192e:	85 c0                	test   %eax,%eax
80101930:	7e 35                	jle    80101967 <iget+0x61>
80101932:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101935:	8b 00                	mov    (%eax),%eax
80101937:	3b 45 08             	cmp    0x8(%ebp),%eax
8010193a:	75 2b                	jne    80101967 <iget+0x61>
8010193c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193f:	8b 40 04             	mov    0x4(%eax),%eax
80101942:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101945:	75 20                	jne    80101967 <iget+0x61>
      ip->ref++;
80101947:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010194a:	8b 40 08             	mov    0x8(%eax),%eax
8010194d:	8d 50 01             	lea    0x1(%eax),%edx
80101950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101953:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101956:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010195d:	e8 b1 3e 00 00       	call   80105813 <release>
      return ip;
80101962:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101965:	eb 6f                	jmp    801019d6 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101967:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010196b:	75 10                	jne    8010197d <iget+0x77>
8010196d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101970:	8b 40 08             	mov    0x8(%eax),%eax
80101973:	85 c0                	test   %eax,%eax
80101975:	75 06                	jne    8010197d <iget+0x77>
      empty = ip;
80101977:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010197a:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010197d:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101981:	81 7d f4 14 42 11 80 	cmpl   $0x80114214,-0xc(%ebp)
80101988:	72 9e                	jb     80101928 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010198a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010198e:	75 0c                	jne    8010199c <iget+0x96>
    panic("iget: no inodes");
80101990:	c7 04 24 c5 9b 10 80 	movl   $0x80109bc5,(%esp)
80101997:	e8 9e eb ff ff       	call   8010053a <panic>

  ip = empty;
8010199c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010199f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801019a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a5:	8b 55 08             	mov    0x8(%ebp),%edx
801019a8:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801019aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801019b0:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801019b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b6:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801019bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801019c7:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019ce:	e8 40 3e 00 00       	call   80105813 <release>

  return ip;
801019d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801019d6:	c9                   	leave  
801019d7:	c3                   	ret    

801019d8 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801019d8:	55                   	push   %ebp
801019d9:	89 e5                	mov    %esp,%ebp
801019db:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801019de:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019e5:	e8 c7 3d 00 00       	call   801057b1 <acquire>
  ip->ref++;
801019ea:	8b 45 08             	mov    0x8(%ebp),%eax
801019ed:	8b 40 08             	mov    0x8(%eax),%eax
801019f0:	8d 50 01             	lea    0x1(%eax),%edx
801019f3:	8b 45 08             	mov    0x8(%ebp),%eax
801019f6:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019f9:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a00:	e8 0e 3e 00 00       	call   80105813 <release>
  return ip;
80101a05:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101a08:	c9                   	leave  
80101a09:	c3                   	ret    

80101a0a <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101a0a:	55                   	push   %ebp
80101a0b:	89 e5                	mov    %esp,%ebp
80101a0d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101a10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a14:	74 0a                	je     80101a20 <ilock+0x16>
80101a16:	8b 45 08             	mov    0x8(%ebp),%eax
80101a19:	8b 40 08             	mov    0x8(%eax),%eax
80101a1c:	85 c0                	test   %eax,%eax
80101a1e:	7f 0c                	jg     80101a2c <ilock+0x22>
    panic("ilock");
80101a20:	c7 04 24 d5 9b 10 80 	movl   $0x80109bd5,(%esp)
80101a27:	e8 0e eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a2c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a33:	e8 79 3d 00 00       	call   801057b1 <acquire>
  while(ip->flags & I_BUSY)
80101a38:	eb 13                	jmp    80101a4d <ilock+0x43>
    sleep(ip, &icache.lock);
80101a3a:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
80101a41:	80 
80101a42:	8b 45 08             	mov    0x8(%ebp),%eax
80101a45:	89 04 24             	mov    %eax,(%esp)
80101a48:	e8 1c 3a 00 00       	call   80105469 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a50:	8b 40 0c             	mov    0xc(%eax),%eax
80101a53:	83 e0 01             	and    $0x1,%eax
80101a56:	85 c0                	test   %eax,%eax
80101a58:	75 e0                	jne    80101a3a <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101a5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5d:	8b 40 0c             	mov    0xc(%eax),%eax
80101a60:	83 c8 01             	or     $0x1,%eax
80101a63:	89 c2                	mov    %eax,%edx
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101a6b:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a72:	e8 9c 3d 00 00       	call   80105813 <release>

  if(!(ip->flags & I_VALID)){
80101a77:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7a:	8b 40 0c             	mov    0xc(%eax),%eax
80101a7d:	83 e0 02             	and    $0x2,%eax
80101a80:	85 c0                	test   %eax,%eax
80101a82:	0f 85 d4 00 00 00    	jne    80101b5c <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a88:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8b:	8b 40 04             	mov    0x4(%eax),%eax
80101a8e:	c1 e8 03             	shr    $0x3,%eax
80101a91:	89 c2                	mov    %eax,%edx
80101a93:	a1 34 32 11 80       	mov    0x80113234,%eax
80101a98:	01 c2                	add    %eax,%edx
80101a9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9d:	8b 00                	mov    (%eax),%eax
80101a9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101aa3:	89 04 24             	mov    %eax,(%esp)
80101aa6:	e8 fb e6 ff ff       	call   801001a6 <bread>
80101aab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101aae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ab1:	8d 50 18             	lea    0x18(%eax),%edx
80101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab7:	8b 40 04             	mov    0x4(%eax),%eax
80101aba:	83 e0 07             	and    $0x7,%eax
80101abd:	c1 e0 06             	shl    $0x6,%eax
80101ac0:	01 d0                	add    %edx,%eax
80101ac2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ac8:	0f b7 10             	movzwl (%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ad5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101ad9:	8b 45 08             	mov    0x8(%ebp),%eax
80101adc:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ae3:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101ae7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aea:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101aee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101af1:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101af5:	8b 45 08             	mov    0x8(%ebp),%eax
80101af8:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101afc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aff:	8b 50 08             	mov    0x8(%eax),%edx
80101b02:	8b 45 08             	mov    0x8(%ebp),%eax
80101b05:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101b08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b0b:	8d 50 0c             	lea    0xc(%eax),%edx
80101b0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b11:	83 c0 1c             	add    $0x1c,%eax
80101b14:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101b1b:	00 
80101b1c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b20:	89 04 24             	mov    %eax,(%esp)
80101b23:	e8 ac 3f 00 00       	call   80105ad4 <memmove>
    brelse(bp);
80101b28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b2b:	89 04 24             	mov    %eax,(%esp)
80101b2e:	e8 e4 e6 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101b33:	8b 45 08             	mov    0x8(%ebp),%eax
80101b36:	8b 40 0c             	mov    0xc(%eax),%eax
80101b39:	83 c8 02             	or     $0x2,%eax
80101b3c:	89 c2                	mov    %eax,%edx
80101b3e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b41:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101b44:	8b 45 08             	mov    0x8(%ebp),%eax
80101b47:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101b4b:	66 85 c0             	test   %ax,%ax
80101b4e:	75 0c                	jne    80101b5c <ilock+0x152>
      panic("ilock: no type");
80101b50:	c7 04 24 db 9b 10 80 	movl   $0x80109bdb,(%esp)
80101b57:	e8 de e9 ff ff       	call   8010053a <panic>
  }
}
80101b5c:	c9                   	leave  
80101b5d:	c3                   	ret    

80101b5e <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b5e:	55                   	push   %ebp
80101b5f:	89 e5                	mov    %esp,%ebp
80101b61:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101b64:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b68:	74 17                	je     80101b81 <iunlock+0x23>
80101b6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6d:	8b 40 0c             	mov    0xc(%eax),%eax
80101b70:	83 e0 01             	and    $0x1,%eax
80101b73:	85 c0                	test   %eax,%eax
80101b75:	74 0a                	je     80101b81 <iunlock+0x23>
80101b77:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7a:	8b 40 08             	mov    0x8(%eax),%eax
80101b7d:	85 c0                	test   %eax,%eax
80101b7f:	7f 0c                	jg     80101b8d <iunlock+0x2f>
    panic("iunlock");
80101b81:	c7 04 24 ea 9b 10 80 	movl   $0x80109bea,(%esp)
80101b88:	e8 ad e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b8d:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b94:	e8 18 3c 00 00       	call   801057b1 <acquire>
  ip->flags &= ~I_BUSY;
80101b99:	8b 45 08             	mov    0x8(%ebp),%eax
80101b9c:	8b 40 0c             	mov    0xc(%eax),%eax
80101b9f:	83 e0 fe             	and    $0xfffffffe,%eax
80101ba2:	89 c2                	mov    %eax,%edx
80101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba7:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101baa:	8b 45 08             	mov    0x8(%ebp),%eax
80101bad:	89 04 24             	mov    %eax,(%esp)
80101bb0:	e8 90 39 00 00       	call   80105545 <wakeup>
  release(&icache.lock);
80101bb5:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101bbc:	e8 52 3c 00 00       	call   80105813 <release>
}
80101bc1:	c9                   	leave  
80101bc2:	c3                   	ret    

80101bc3 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101bc3:	55                   	push   %ebp
80101bc4:	89 e5                	mov    %esp,%ebp
80101bc6:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101bc9:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101bd0:	e8 dc 3b 00 00       	call   801057b1 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101bd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd8:	8b 40 08             	mov    0x8(%eax),%eax
80101bdb:	83 f8 01             	cmp    $0x1,%eax
80101bde:	0f 85 93 00 00 00    	jne    80101c77 <iput+0xb4>
80101be4:	8b 45 08             	mov    0x8(%ebp),%eax
80101be7:	8b 40 0c             	mov    0xc(%eax),%eax
80101bea:	83 e0 02             	and    $0x2,%eax
80101bed:	85 c0                	test   %eax,%eax
80101bef:	0f 84 82 00 00 00    	je     80101c77 <iput+0xb4>
80101bf5:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101bfc:	66 85 c0             	test   %ax,%ax
80101bff:	75 76                	jne    80101c77 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101c01:	8b 45 08             	mov    0x8(%ebp),%eax
80101c04:	8b 40 0c             	mov    0xc(%eax),%eax
80101c07:	83 e0 01             	and    $0x1,%eax
80101c0a:	85 c0                	test   %eax,%eax
80101c0c:	74 0c                	je     80101c1a <iput+0x57>
      panic("iput busy");
80101c0e:	c7 04 24 f2 9b 10 80 	movl   $0x80109bf2,(%esp)
80101c15:	e8 20 e9 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101c1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1d:	8b 40 0c             	mov    0xc(%eax),%eax
80101c20:	83 c8 01             	or     $0x1,%eax
80101c23:	89 c2                	mov    %eax,%edx
80101c25:	8b 45 08             	mov    0x8(%ebp),%eax
80101c28:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101c2b:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c32:	e8 dc 3b 00 00       	call   80105813 <release>
    itrunc(ip);
80101c37:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3a:	89 04 24             	mov    %eax,(%esp)
80101c3d:	e8 7d 01 00 00       	call   80101dbf <itrunc>
    ip->type = 0;
80101c42:	8b 45 08             	mov    0x8(%ebp),%eax
80101c45:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101c4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4e:	89 04 24             	mov    %eax,(%esp)
80101c51:	e8 f2 fb ff ff       	call   80101848 <iupdate>
    acquire(&icache.lock);
80101c56:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c5d:	e8 4f 3b 00 00       	call   801057b1 <acquire>
    ip->flags = 0;
80101c62:	8b 45 08             	mov    0x8(%ebp),%eax
80101c65:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6f:	89 04 24             	mov    %eax,(%esp)
80101c72:	e8 ce 38 00 00       	call   80105545 <wakeup>
  }
  ip->ref--;
80101c77:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7a:	8b 40 08             	mov    0x8(%eax),%eax
80101c7d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c80:	8b 45 08             	mov    0x8(%ebp),%eax
80101c83:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c86:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c8d:	e8 81 3b 00 00       	call   80105813 <release>
}
80101c92:	c9                   	leave  
80101c93:	c3                   	ret    

80101c94 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c94:	55                   	push   %ebp
80101c95:	89 e5                	mov    %esp,%ebp
80101c97:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9d:	89 04 24             	mov    %eax,(%esp)
80101ca0:	e8 b9 fe ff ff       	call   80101b5e <iunlock>
  iput(ip);
80101ca5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca8:	89 04 24             	mov    %eax,(%esp)
80101cab:	e8 13 ff ff ff       	call   80101bc3 <iput>
}
80101cb0:	c9                   	leave  
80101cb1:	c3                   	ret    

80101cb2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101cb2:	55                   	push   %ebp
80101cb3:	89 e5                	mov    %esp,%ebp
80101cb5:	53                   	push   %ebx
80101cb6:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101cb9:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101cbd:	77 3e                	ja     80101cfd <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc2:	8b 55 0c             	mov    0xc(%ebp),%edx
80101cc5:	83 c2 04             	add    $0x4,%edx
80101cc8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101ccc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ccf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cd3:	75 20                	jne    80101cf5 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101cd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd8:	8b 00                	mov    (%eax),%eax
80101cda:	89 04 24             	mov    %eax,(%esp)
80101cdd:	e8 f7 f7 ff ff       	call   801014d9 <balloc>
80101ce2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ceb:	8d 4a 04             	lea    0x4(%edx),%ecx
80101cee:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cf1:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101cf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cf8:	e9 bc 00 00 00       	jmp    80101db9 <bmap+0x107>
  }
  bn -= NDIRECT;
80101cfd:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101d01:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101d05:	0f 87 a2 00 00 00    	ja     80101dad <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101d0b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d11:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d14:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d18:	75 19                	jne    80101d33 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1d:	8b 00                	mov    (%eax),%eax
80101d1f:	89 04 24             	mov    %eax,(%esp)
80101d22:	e8 b2 f7 ff ff       	call   801014d9 <balloc>
80101d27:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d30:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101d33:	8b 45 08             	mov    0x8(%ebp),%eax
80101d36:	8b 00                	mov    (%eax),%eax
80101d38:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d3f:	89 04 24             	mov    %eax,(%esp)
80101d42:	e8 5f e4 ff ff       	call   801001a6 <bread>
80101d47:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101d4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d4d:	83 c0 18             	add    $0x18,%eax
80101d50:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d53:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d56:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d60:	01 d0                	add    %edx,%eax
80101d62:	8b 00                	mov    (%eax),%eax
80101d64:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d6b:	75 30                	jne    80101d9d <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101d6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d70:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d77:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d7a:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d80:	8b 00                	mov    (%eax),%eax
80101d82:	89 04 24             	mov    %eax,(%esp)
80101d85:	e8 4f f7 ff ff       	call   801014d9 <balloc>
80101d8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d90:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d95:	89 04 24             	mov    %eax,(%esp)
80101d98:	e8 f8 1f 00 00       	call   80103d95 <log_write>
    }
    brelse(bp);
80101d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da0:	89 04 24             	mov    %eax,(%esp)
80101da3:	e8 6f e4 ff ff       	call   80100217 <brelse>
    return addr;
80101da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dab:	eb 0c                	jmp    80101db9 <bmap+0x107>
  }

  panic("bmap: out of range");
80101dad:	c7 04 24 fc 9b 10 80 	movl   $0x80109bfc,(%esp)
80101db4:	e8 81 e7 ff ff       	call   8010053a <panic>
}
80101db9:	83 c4 24             	add    $0x24,%esp
80101dbc:	5b                   	pop    %ebx
80101dbd:	5d                   	pop    %ebp
80101dbe:	c3                   	ret    

80101dbf <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101dbf:	55                   	push   %ebp
80101dc0:	89 e5                	mov    %esp,%ebp
80101dc2:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101dc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101dcc:	eb 44                	jmp    80101e12 <itrunc+0x53>
    if(ip->addrs[i]){
80101dce:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dd4:	83 c2 04             	add    $0x4,%edx
80101dd7:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101ddb:	85 c0                	test   %eax,%eax
80101ddd:	74 2f                	je     80101e0e <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80101de2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101de5:	83 c2 04             	add    $0x4,%edx
80101de8:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101dec:	8b 45 08             	mov    0x8(%ebp),%eax
80101def:	8b 00                	mov    (%eax),%eax
80101df1:	89 54 24 04          	mov    %edx,0x4(%esp)
80101df5:	89 04 24             	mov    %eax,(%esp)
80101df8:	e8 1a f8 ff ff       	call   80101617 <bfree>
      ip->addrs[i] = 0;
80101dfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101e00:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101e03:	83 c2 04             	add    $0x4,%edx
80101e06:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101e0d:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101e0e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e12:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101e16:	7e b6                	jle    80101dce <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101e18:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1b:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e1e:	85 c0                	test   %eax,%eax
80101e20:	0f 84 9b 00 00 00    	je     80101ec1 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	8b 50 4c             	mov    0x4c(%eax),%edx
80101e2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2f:	8b 00                	mov    (%eax),%eax
80101e31:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e35:	89 04 24             	mov    %eax,(%esp)
80101e38:	e8 69 e3 ff ff       	call   801001a6 <bread>
80101e3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e40:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e43:	83 c0 18             	add    $0x18,%eax
80101e46:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e49:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e50:	eb 3b                	jmp    80101e8d <itrunc+0xce>
      if(a[j])
80101e52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e55:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e5c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e5f:	01 d0                	add    %edx,%eax
80101e61:	8b 00                	mov    (%eax),%eax
80101e63:	85 c0                	test   %eax,%eax
80101e65:	74 22                	je     80101e89 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101e67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e6a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e71:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e74:	01 d0                	add    %edx,%eax
80101e76:	8b 10                	mov    (%eax),%edx
80101e78:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7b:	8b 00                	mov    (%eax),%eax
80101e7d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e81:	89 04 24             	mov    %eax,(%esp)
80101e84:	e8 8e f7 ff ff       	call   80101617 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e89:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e90:	83 f8 7f             	cmp    $0x7f,%eax
80101e93:	76 bd                	jbe    80101e52 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e98:	89 04 24             	mov    %eax,(%esp)
80101e9b:	e8 77 e3 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ea6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea9:	8b 00                	mov    (%eax),%eax
80101eab:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eaf:	89 04 24             	mov    %eax,(%esp)
80101eb2:	e8 60 f7 ff ff       	call   80101617 <bfree>
    ip->addrs[NDIRECT] = 0;
80101eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eba:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec4:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ece:	89 04 24             	mov    %eax,(%esp)
80101ed1:	e8 72 f9 ff ff       	call   80101848 <iupdate>
}
80101ed6:	c9                   	leave  
80101ed7:	c3                   	ret    

80101ed8 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101ed8:	55                   	push   %ebp
80101ed9:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101edb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ede:	8b 00                	mov    (%eax),%eax
80101ee0:	89 c2                	mov    %eax,%edx
80101ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee5:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101ee8:	8b 45 08             	mov    0x8(%ebp),%eax
80101eeb:	8b 50 04             	mov    0x4(%eax),%edx
80101eee:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ef1:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ef4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef7:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101efb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101efe:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101f01:	8b 45 08             	mov    0x8(%ebp),%eax
80101f04:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101f08:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f0b:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101f0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f12:	8b 50 18             	mov    0x18(%eax),%edx
80101f15:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f18:	89 50 10             	mov    %edx,0x10(%eax)
}
80101f1b:	5d                   	pop    %ebp
80101f1c:	c3                   	ret    

80101f1d <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101f1d:	55                   	push   %ebp
80101f1e:	89 e5                	mov    %esp,%ebp
80101f20:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f23:	8b 45 08             	mov    0x8(%ebp),%eax
80101f26:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f2a:	66 83 f8 03          	cmp    $0x3,%ax
80101f2e:	75 60                	jne    80101f90 <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f30:	8b 45 08             	mov    0x8(%ebp),%eax
80101f33:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f37:	66 85 c0             	test   %ax,%ax
80101f3a:	78 20                	js     80101f5c <readi+0x3f>
80101f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f43:	66 83 f8 09          	cmp    $0x9,%ax
80101f47:	7f 13                	jg     80101f5c <readi+0x3f>
80101f49:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f50:	98                   	cwtl   
80101f51:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f58:	85 c0                	test   %eax,%eax
80101f5a:	75 0a                	jne    80101f66 <readi+0x49>
      return -1;
80101f5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f61:	e9 19 01 00 00       	jmp    8010207f <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101f66:	8b 45 08             	mov    0x8(%ebp),%eax
80101f69:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f6d:	98                   	cwtl   
80101f6e:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f75:	8b 55 14             	mov    0x14(%ebp),%edx
80101f78:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f7c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f7f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f83:	8b 55 08             	mov    0x8(%ebp),%edx
80101f86:	89 14 24             	mov    %edx,(%esp)
80101f89:	ff d0                	call   *%eax
80101f8b:	e9 ef 00 00 00       	jmp    8010207f <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101f90:	8b 45 08             	mov    0x8(%ebp),%eax
80101f93:	8b 40 18             	mov    0x18(%eax),%eax
80101f96:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f99:	72 0d                	jb     80101fa8 <readi+0x8b>
80101f9b:	8b 45 14             	mov    0x14(%ebp),%eax
80101f9e:	8b 55 10             	mov    0x10(%ebp),%edx
80101fa1:	01 d0                	add    %edx,%eax
80101fa3:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fa6:	73 0a                	jae    80101fb2 <readi+0x95>
    return -1;
80101fa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fad:	e9 cd 00 00 00       	jmp    8010207f <readi+0x162>
  if(off + n > ip->size)
80101fb2:	8b 45 14             	mov    0x14(%ebp),%eax
80101fb5:	8b 55 10             	mov    0x10(%ebp),%edx
80101fb8:	01 c2                	add    %eax,%edx
80101fba:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbd:	8b 40 18             	mov    0x18(%eax),%eax
80101fc0:	39 c2                	cmp    %eax,%edx
80101fc2:	76 0c                	jbe    80101fd0 <readi+0xb3>
    n = ip->size - off;
80101fc4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc7:	8b 40 18             	mov    0x18(%eax),%eax
80101fca:	2b 45 10             	sub    0x10(%ebp),%eax
80101fcd:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fd0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fd7:	e9 94 00 00 00       	jmp    80102070 <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fdc:	8b 45 10             	mov    0x10(%ebp),%eax
80101fdf:	c1 e8 09             	shr    $0x9,%eax
80101fe2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe9:	89 04 24             	mov    %eax,(%esp)
80101fec:	e8 c1 fc ff ff       	call   80101cb2 <bmap>
80101ff1:	8b 55 08             	mov    0x8(%ebp),%edx
80101ff4:	8b 12                	mov    (%edx),%edx
80101ff6:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ffa:	89 14 24             	mov    %edx,(%esp)
80101ffd:	e8 a4 e1 ff ff       	call   801001a6 <bread>
80102002:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102005:	8b 45 10             	mov    0x10(%ebp),%eax
80102008:	25 ff 01 00 00       	and    $0x1ff,%eax
8010200d:	89 c2                	mov    %eax,%edx
8010200f:	b8 00 02 00 00       	mov    $0x200,%eax
80102014:	29 d0                	sub    %edx,%eax
80102016:	89 c2                	mov    %eax,%edx
80102018:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010201b:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010201e:	29 c1                	sub    %eax,%ecx
80102020:	89 c8                	mov    %ecx,%eax
80102022:	39 c2                	cmp    %eax,%edx
80102024:	0f 46 c2             	cmovbe %edx,%eax
80102027:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
8010202a:	8b 45 10             	mov    0x10(%ebp),%eax
8010202d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102032:	8d 50 10             	lea    0x10(%eax),%edx
80102035:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102038:	01 d0                	add    %edx,%eax
8010203a:	8d 50 08             	lea    0x8(%eax),%edx
8010203d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102040:	89 44 24 08          	mov    %eax,0x8(%esp)
80102044:	89 54 24 04          	mov    %edx,0x4(%esp)
80102048:	8b 45 0c             	mov    0xc(%ebp),%eax
8010204b:	89 04 24             	mov    %eax,(%esp)
8010204e:	e8 81 3a 00 00       	call   80105ad4 <memmove>
    brelse(bp);
80102053:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102056:	89 04 24             	mov    %eax,(%esp)
80102059:	e8 b9 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010205e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102061:	01 45 f4             	add    %eax,-0xc(%ebp)
80102064:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102067:	01 45 10             	add    %eax,0x10(%ebp)
8010206a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010206d:	01 45 0c             	add    %eax,0xc(%ebp)
80102070:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102073:	3b 45 14             	cmp    0x14(%ebp),%eax
80102076:	0f 82 60 ff ff ff    	jb     80101fdc <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010207c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010207f:	c9                   	leave  
80102080:	c3                   	ret    

80102081 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102081:	55                   	push   %ebp
80102082:	89 e5                	mov    %esp,%ebp
80102084:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102087:	8b 45 08             	mov    0x8(%ebp),%eax
8010208a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010208e:	66 83 f8 03          	cmp    $0x3,%ax
80102092:	75 60                	jne    801020f4 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102094:	8b 45 08             	mov    0x8(%ebp),%eax
80102097:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010209b:	66 85 c0             	test   %ax,%ax
8010209e:	78 20                	js     801020c0 <writei+0x3f>
801020a0:	8b 45 08             	mov    0x8(%ebp),%eax
801020a3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020a7:	66 83 f8 09          	cmp    $0x9,%ax
801020ab:	7f 13                	jg     801020c0 <writei+0x3f>
801020ad:	8b 45 08             	mov    0x8(%ebp),%eax
801020b0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020b4:	98                   	cwtl   
801020b5:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
801020bc:	85 c0                	test   %eax,%eax
801020be:	75 0a                	jne    801020ca <writei+0x49>
      return -1;
801020c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020c5:	e9 44 01 00 00       	jmp    8010220e <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
801020ca:	8b 45 08             	mov    0x8(%ebp),%eax
801020cd:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020d1:	98                   	cwtl   
801020d2:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
801020d9:	8b 55 14             	mov    0x14(%ebp),%edx
801020dc:	89 54 24 08          	mov    %edx,0x8(%esp)
801020e0:	8b 55 0c             	mov    0xc(%ebp),%edx
801020e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801020e7:	8b 55 08             	mov    0x8(%ebp),%edx
801020ea:	89 14 24             	mov    %edx,(%esp)
801020ed:	ff d0                	call   *%eax
801020ef:	e9 1a 01 00 00       	jmp    8010220e <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801020f4:	8b 45 08             	mov    0x8(%ebp),%eax
801020f7:	8b 40 18             	mov    0x18(%eax),%eax
801020fa:	3b 45 10             	cmp    0x10(%ebp),%eax
801020fd:	72 0d                	jb     8010210c <writei+0x8b>
801020ff:	8b 45 14             	mov    0x14(%ebp),%eax
80102102:	8b 55 10             	mov    0x10(%ebp),%edx
80102105:	01 d0                	add    %edx,%eax
80102107:	3b 45 10             	cmp    0x10(%ebp),%eax
8010210a:	73 0a                	jae    80102116 <writei+0x95>
    return -1;
8010210c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102111:	e9 f8 00 00 00       	jmp    8010220e <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80102116:	8b 45 14             	mov    0x14(%ebp),%eax
80102119:	8b 55 10             	mov    0x10(%ebp),%edx
8010211c:	01 d0                	add    %edx,%eax
8010211e:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102123:	76 0a                	jbe    8010212f <writei+0xae>
    return -1;
80102125:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010212a:	e9 df 00 00 00       	jmp    8010220e <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010212f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102136:	e9 9f 00 00 00       	jmp    801021da <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010213b:	8b 45 10             	mov    0x10(%ebp),%eax
8010213e:	c1 e8 09             	shr    $0x9,%eax
80102141:	89 44 24 04          	mov    %eax,0x4(%esp)
80102145:	8b 45 08             	mov    0x8(%ebp),%eax
80102148:	89 04 24             	mov    %eax,(%esp)
8010214b:	e8 62 fb ff ff       	call   80101cb2 <bmap>
80102150:	8b 55 08             	mov    0x8(%ebp),%edx
80102153:	8b 12                	mov    (%edx),%edx
80102155:	89 44 24 04          	mov    %eax,0x4(%esp)
80102159:	89 14 24             	mov    %edx,(%esp)
8010215c:	e8 45 e0 ff ff       	call   801001a6 <bread>
80102161:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102164:	8b 45 10             	mov    0x10(%ebp),%eax
80102167:	25 ff 01 00 00       	and    $0x1ff,%eax
8010216c:	89 c2                	mov    %eax,%edx
8010216e:	b8 00 02 00 00       	mov    $0x200,%eax
80102173:	29 d0                	sub    %edx,%eax
80102175:	89 c2                	mov    %eax,%edx
80102177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010217a:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010217d:	29 c1                	sub    %eax,%ecx
8010217f:	89 c8                	mov    %ecx,%eax
80102181:	39 c2                	cmp    %eax,%edx
80102183:	0f 46 c2             	cmovbe %edx,%eax
80102186:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102189:	8b 45 10             	mov    0x10(%ebp),%eax
8010218c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102191:	8d 50 10             	lea    0x10(%eax),%edx
80102194:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102197:	01 d0                	add    %edx,%eax
80102199:	8d 50 08             	lea    0x8(%eax),%edx
8010219c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010219f:	89 44 24 08          	mov    %eax,0x8(%esp)
801021a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801021a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021aa:	89 14 24             	mov    %edx,(%esp)
801021ad:	e8 22 39 00 00       	call   80105ad4 <memmove>
    log_write(bp);
801021b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b5:	89 04 24             	mov    %eax,(%esp)
801021b8:	e8 d8 1b 00 00       	call   80103d95 <log_write>
    brelse(bp);
801021bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c0:	89 04 24             	mov    %eax,(%esp)
801021c3:	e8 4f e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801021c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021cb:	01 45 f4             	add    %eax,-0xc(%ebp)
801021ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d1:	01 45 10             	add    %eax,0x10(%ebp)
801021d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d7:	01 45 0c             	add    %eax,0xc(%ebp)
801021da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021dd:	3b 45 14             	cmp    0x14(%ebp),%eax
801021e0:	0f 82 55 ff ff ff    	jb     8010213b <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801021e6:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021ea:	74 1f                	je     8010220b <writei+0x18a>
801021ec:	8b 45 08             	mov    0x8(%ebp),%eax
801021ef:	8b 40 18             	mov    0x18(%eax),%eax
801021f2:	3b 45 10             	cmp    0x10(%ebp),%eax
801021f5:	73 14                	jae    8010220b <writei+0x18a>
    ip->size = off;
801021f7:	8b 45 08             	mov    0x8(%ebp),%eax
801021fa:	8b 55 10             	mov    0x10(%ebp),%edx
801021fd:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102200:	8b 45 08             	mov    0x8(%ebp),%eax
80102203:	89 04 24             	mov    %eax,(%esp)
80102206:	e8 3d f6 ff ff       	call   80101848 <iupdate>
  }
  return n;
8010220b:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010220e:	c9                   	leave  
8010220f:	c3                   	ret    

80102210 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102210:	55                   	push   %ebp
80102211:	89 e5                	mov    %esp,%ebp
80102213:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102216:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010221d:	00 
8010221e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102221:	89 44 24 04          	mov    %eax,0x4(%esp)
80102225:	8b 45 08             	mov    0x8(%ebp),%eax
80102228:	89 04 24             	mov    %eax,(%esp)
8010222b:	e8 47 39 00 00       	call   80105b77 <strncmp>
}
80102230:	c9                   	leave  
80102231:	c3                   	ret    

80102232 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102232:	55                   	push   %ebp
80102233:	89 e5                	mov    %esp,%ebp
80102235:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102238:	8b 45 08             	mov    0x8(%ebp),%eax
8010223b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010223f:	66 83 f8 01          	cmp    $0x1,%ax
80102243:	74 0c                	je     80102251 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102245:	c7 04 24 0f 9c 10 80 	movl   $0x80109c0f,(%esp)
8010224c:	e8 e9 e2 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102251:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102258:	e9 88 00 00 00       	jmp    801022e5 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010225d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102264:	00 
80102265:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102268:	89 44 24 08          	mov    %eax,0x8(%esp)
8010226c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010226f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102273:	8b 45 08             	mov    0x8(%ebp),%eax
80102276:	89 04 24             	mov    %eax,(%esp)
80102279:	e8 9f fc ff ff       	call   80101f1d <readi>
8010227e:	83 f8 10             	cmp    $0x10,%eax
80102281:	74 0c                	je     8010228f <dirlookup+0x5d>
      panic("dirlink read");
80102283:	c7 04 24 21 9c 10 80 	movl   $0x80109c21,(%esp)
8010228a:	e8 ab e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010228f:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102293:	66 85 c0             	test   %ax,%ax
80102296:	75 02                	jne    8010229a <dirlookup+0x68>
      continue;
80102298:	eb 47                	jmp    801022e1 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
8010229a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010229d:	83 c0 02             	add    $0x2,%eax
801022a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022a7:	89 04 24             	mov    %eax,(%esp)
801022aa:	e8 61 ff ff ff       	call   80102210 <namecmp>
801022af:	85 c0                	test   %eax,%eax
801022b1:	75 2e                	jne    801022e1 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801022b3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801022b7:	74 08                	je     801022c1 <dirlookup+0x8f>
        *poff = off;
801022b9:	8b 45 10             	mov    0x10(%ebp),%eax
801022bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022bf:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801022c1:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022c5:	0f b7 c0             	movzwl %ax,%eax
801022c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801022cb:	8b 45 08             	mov    0x8(%ebp),%eax
801022ce:	8b 00                	mov    (%eax),%eax
801022d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801022d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801022d7:	89 04 24             	mov    %eax,(%esp)
801022da:	e8 27 f6 ff ff       	call   80101906 <iget>
801022df:	eb 18                	jmp    801022f9 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801022e1:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022e5:	8b 45 08             	mov    0x8(%ebp),%eax
801022e8:	8b 40 18             	mov    0x18(%eax),%eax
801022eb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022ee:	0f 87 69 ff ff ff    	ja     8010225d <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801022f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022f9:	c9                   	leave  
801022fa:	c3                   	ret    

801022fb <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022fb:	55                   	push   %ebp
801022fc:	89 e5                	mov    %esp,%ebp
801022fe:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102301:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102308:	00 
80102309:	8b 45 0c             	mov    0xc(%ebp),%eax
8010230c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102310:	8b 45 08             	mov    0x8(%ebp),%eax
80102313:	89 04 24             	mov    %eax,(%esp)
80102316:	e8 17 ff ff ff       	call   80102232 <dirlookup>
8010231b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010231e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102322:	74 15                	je     80102339 <dirlink+0x3e>
    iput(ip);
80102324:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102327:	89 04 24             	mov    %eax,(%esp)
8010232a:	e8 94 f8 ff ff       	call   80101bc3 <iput>
    return -1;
8010232f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102334:	e9 b7 00 00 00       	jmp    801023f0 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102339:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102340:	eb 46                	jmp    80102388 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102345:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010234c:	00 
8010234d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102351:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102354:	89 44 24 04          	mov    %eax,0x4(%esp)
80102358:	8b 45 08             	mov    0x8(%ebp),%eax
8010235b:	89 04 24             	mov    %eax,(%esp)
8010235e:	e8 ba fb ff ff       	call   80101f1d <readi>
80102363:	83 f8 10             	cmp    $0x10,%eax
80102366:	74 0c                	je     80102374 <dirlink+0x79>
      panic("dirlink read");
80102368:	c7 04 24 21 9c 10 80 	movl   $0x80109c21,(%esp)
8010236f:	e8 c6 e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102374:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102378:	66 85 c0             	test   %ax,%ax
8010237b:	75 02                	jne    8010237f <dirlink+0x84>
      break;
8010237d:	eb 16                	jmp    80102395 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010237f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102382:	83 c0 10             	add    $0x10,%eax
80102385:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102388:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010238b:	8b 45 08             	mov    0x8(%ebp),%eax
8010238e:	8b 40 18             	mov    0x18(%eax),%eax
80102391:	39 c2                	cmp    %eax,%edx
80102393:	72 ad                	jb     80102342 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102395:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010239c:	00 
8010239d:	8b 45 0c             	mov    0xc(%ebp),%eax
801023a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801023a4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023a7:	83 c0 02             	add    $0x2,%eax
801023aa:	89 04 24             	mov    %eax,(%esp)
801023ad:	e8 1b 38 00 00       	call   80105bcd <strncpy>
  de.inum = inum;
801023b2:	8b 45 10             	mov    0x10(%ebp),%eax
801023b5:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023bc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023c3:	00 
801023c4:	89 44 24 08          	mov    %eax,0x8(%esp)
801023c8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801023cf:	8b 45 08             	mov    0x8(%ebp),%eax
801023d2:	89 04 24             	mov    %eax,(%esp)
801023d5:	e8 a7 fc ff ff       	call   80102081 <writei>
801023da:	83 f8 10             	cmp    $0x10,%eax
801023dd:	74 0c                	je     801023eb <dirlink+0xf0>
    panic("dirlink");
801023df:	c7 04 24 2e 9c 10 80 	movl   $0x80109c2e,(%esp)
801023e6:	e8 4f e1 ff ff       	call   8010053a <panic>
  
  return 0;
801023eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801023f0:	c9                   	leave  
801023f1:	c3                   	ret    

801023f2 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801023f2:	55                   	push   %ebp
801023f3:	89 e5                	mov    %esp,%ebp
801023f5:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801023f8:	eb 04                	jmp    801023fe <skipelem+0xc>
    path++;
801023fa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801023fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102401:	0f b6 00             	movzbl (%eax),%eax
80102404:	3c 2f                	cmp    $0x2f,%al
80102406:	74 f2                	je     801023fa <skipelem+0x8>
    path++;
  if(*path == 0)
80102408:	8b 45 08             	mov    0x8(%ebp),%eax
8010240b:	0f b6 00             	movzbl (%eax),%eax
8010240e:	84 c0                	test   %al,%al
80102410:	75 0a                	jne    8010241c <skipelem+0x2a>
    return 0;
80102412:	b8 00 00 00 00       	mov    $0x0,%eax
80102417:	e9 86 00 00 00       	jmp    801024a2 <skipelem+0xb0>
  s = path;
8010241c:	8b 45 08             	mov    0x8(%ebp),%eax
8010241f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102422:	eb 04                	jmp    80102428 <skipelem+0x36>
    path++;
80102424:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102428:	8b 45 08             	mov    0x8(%ebp),%eax
8010242b:	0f b6 00             	movzbl (%eax),%eax
8010242e:	3c 2f                	cmp    $0x2f,%al
80102430:	74 0a                	je     8010243c <skipelem+0x4a>
80102432:	8b 45 08             	mov    0x8(%ebp),%eax
80102435:	0f b6 00             	movzbl (%eax),%eax
80102438:	84 c0                	test   %al,%al
8010243a:	75 e8                	jne    80102424 <skipelem+0x32>
    path++;
  len = path - s;
8010243c:	8b 55 08             	mov    0x8(%ebp),%edx
8010243f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102442:	29 c2                	sub    %eax,%edx
80102444:	89 d0                	mov    %edx,%eax
80102446:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102449:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010244d:	7e 1c                	jle    8010246b <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010244f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102456:	00 
80102457:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010245a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010245e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102461:	89 04 24             	mov    %eax,(%esp)
80102464:	e8 6b 36 00 00       	call   80105ad4 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102469:	eb 2a                	jmp    80102495 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010246b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010246e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102475:	89 44 24 04          	mov    %eax,0x4(%esp)
80102479:	8b 45 0c             	mov    0xc(%ebp),%eax
8010247c:	89 04 24             	mov    %eax,(%esp)
8010247f:	e8 50 36 00 00       	call   80105ad4 <memmove>
    name[len] = 0;
80102484:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102487:	8b 45 0c             	mov    0xc(%ebp),%eax
8010248a:	01 d0                	add    %edx,%eax
8010248c:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010248f:	eb 04                	jmp    80102495 <skipelem+0xa3>
    path++;
80102491:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102495:	8b 45 08             	mov    0x8(%ebp),%eax
80102498:	0f b6 00             	movzbl (%eax),%eax
8010249b:	3c 2f                	cmp    $0x2f,%al
8010249d:	74 f2                	je     80102491 <skipelem+0x9f>
    path++;
  return path;
8010249f:	8b 45 08             	mov    0x8(%ebp),%eax
}
801024a2:	c9                   	leave  
801024a3:	c3                   	ret    

801024a4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801024a4:	55                   	push   %ebp
801024a5:	89 e5                	mov    %esp,%ebp
801024a7:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801024aa:	8b 45 08             	mov    0x8(%ebp),%eax
801024ad:	0f b6 00             	movzbl (%eax),%eax
801024b0:	3c 2f                	cmp    $0x2f,%al
801024b2:	75 1c                	jne    801024d0 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801024b4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024bb:	00 
801024bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024c3:	e8 3e f4 ff ff       	call   80101906 <iget>
801024c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024cb:	e9 af 00 00 00       	jmp    8010257f <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024d6:	8b 40 68             	mov    0x68(%eax),%eax
801024d9:	89 04 24             	mov    %eax,(%esp)
801024dc:	e8 f7 f4 ff ff       	call   801019d8 <idup>
801024e1:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801024e4:	e9 96 00 00 00       	jmp    8010257f <namex+0xdb>
    ilock(ip);
801024e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ec:	89 04 24             	mov    %eax,(%esp)
801024ef:	e8 16 f5 ff ff       	call   80101a0a <ilock>
    if(ip->type != T_DIR){
801024f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024f7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801024fb:	66 83 f8 01          	cmp    $0x1,%ax
801024ff:	74 15                	je     80102516 <namex+0x72>
      iunlockput(ip);
80102501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102504:	89 04 24             	mov    %eax,(%esp)
80102507:	e8 88 f7 ff ff       	call   80101c94 <iunlockput>
      return 0;
8010250c:	b8 00 00 00 00       	mov    $0x0,%eax
80102511:	e9 a3 00 00 00       	jmp    801025b9 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102516:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010251a:	74 1d                	je     80102539 <namex+0x95>
8010251c:	8b 45 08             	mov    0x8(%ebp),%eax
8010251f:	0f b6 00             	movzbl (%eax),%eax
80102522:	84 c0                	test   %al,%al
80102524:	75 13                	jne    80102539 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102529:	89 04 24             	mov    %eax,(%esp)
8010252c:	e8 2d f6 ff ff       	call   80101b5e <iunlock>
      return ip;
80102531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102534:	e9 80 00 00 00       	jmp    801025b9 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102539:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102540:	00 
80102541:	8b 45 10             	mov    0x10(%ebp),%eax
80102544:	89 44 24 04          	mov    %eax,0x4(%esp)
80102548:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010254b:	89 04 24             	mov    %eax,(%esp)
8010254e:	e8 df fc ff ff       	call   80102232 <dirlookup>
80102553:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102556:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010255a:	75 12                	jne    8010256e <namex+0xca>
      iunlockput(ip);
8010255c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010255f:	89 04 24             	mov    %eax,(%esp)
80102562:	e8 2d f7 ff ff       	call   80101c94 <iunlockput>
      return 0;
80102567:	b8 00 00 00 00       	mov    $0x0,%eax
8010256c:	eb 4b                	jmp    801025b9 <namex+0x115>
    }
    iunlockput(ip);
8010256e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102571:	89 04 24             	mov    %eax,(%esp)
80102574:	e8 1b f7 ff ff       	call   80101c94 <iunlockput>
    ip = next;
80102579:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010257c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010257f:	8b 45 10             	mov    0x10(%ebp),%eax
80102582:	89 44 24 04          	mov    %eax,0x4(%esp)
80102586:	8b 45 08             	mov    0x8(%ebp),%eax
80102589:	89 04 24             	mov    %eax,(%esp)
8010258c:	e8 61 fe ff ff       	call   801023f2 <skipelem>
80102591:	89 45 08             	mov    %eax,0x8(%ebp)
80102594:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102598:	0f 85 4b ff ff ff    	jne    801024e9 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010259e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025a2:	74 12                	je     801025b6 <namex+0x112>
    iput(ip);
801025a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a7:	89 04 24             	mov    %eax,(%esp)
801025aa:	e8 14 f6 ff ff       	call   80101bc3 <iput>
    return 0;
801025af:	b8 00 00 00 00       	mov    $0x0,%eax
801025b4:	eb 03                	jmp    801025b9 <namex+0x115>
  }
  return ip;
801025b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801025b9:	c9                   	leave  
801025ba:	c3                   	ret    

801025bb <namei>:

struct inode*
namei(char *path)
{
801025bb:	55                   	push   %ebp
801025bc:	89 e5                	mov    %esp,%ebp
801025be:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801025c1:	8d 45 ea             	lea    -0x16(%ebp),%eax
801025c4:	89 44 24 08          	mov    %eax,0x8(%esp)
801025c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025cf:	00 
801025d0:	8b 45 08             	mov    0x8(%ebp),%eax
801025d3:	89 04 24             	mov    %eax,(%esp)
801025d6:	e8 c9 fe ff ff       	call   801024a4 <namex>
}
801025db:	c9                   	leave  
801025dc:	c3                   	ret    

801025dd <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801025dd:	55                   	push   %ebp
801025de:	89 e5                	mov    %esp,%ebp
801025e0:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801025e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801025e6:	89 44 24 08          	mov    %eax,0x8(%esp)
801025ea:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801025f1:	00 
801025f2:	8b 45 08             	mov    0x8(%ebp),%eax
801025f5:	89 04 24             	mov    %eax,(%esp)
801025f8:	e8 a7 fe ff ff       	call   801024a4 <namex>
}
801025fd:	c9                   	leave  
801025fe:	c3                   	ret    

801025ff <itoa>:

#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
801025ff:	55                   	push   %ebp
80102600:	89 e5                	mov    %esp,%ebp
80102602:	83 ec 20             	sub    $0x20,%esp
    char const digit[] = "0123456789";
80102605:	c7 45 ed 30 31 32 33 	movl   $0x33323130,-0x13(%ebp)
8010260c:	c7 45 f1 34 35 36 37 	movl   $0x37363534,-0xf(%ebp)
80102613:	66 c7 45 f5 38 39    	movw   $0x3938,-0xb(%ebp)
80102619:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
    char* p = b;
8010261d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102620:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if(i<0){
80102623:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102627:	79 0f                	jns    80102638 <itoa+0x39>
        *p++ = '-';
80102629:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010262c:	8d 50 01             	lea    0x1(%eax),%edx
8010262f:	89 55 fc             	mov    %edx,-0x4(%ebp)
80102632:	c6 00 2d             	movb   $0x2d,(%eax)
        i *= -1;
80102635:	f7 5d 08             	negl   0x8(%ebp)
    }
    int shifter = i;
80102638:	8b 45 08             	mov    0x8(%ebp),%eax
8010263b:	89 45 f8             	mov    %eax,-0x8(%ebp)
    do{ //Move to where representation ends
        ++p;
8010263e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
        shifter = shifter/10;
80102642:	8b 4d f8             	mov    -0x8(%ebp),%ecx
80102645:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010264a:	89 c8                	mov    %ecx,%eax
8010264c:	f7 ea                	imul   %edx
8010264e:	c1 fa 02             	sar    $0x2,%edx
80102651:	89 c8                	mov    %ecx,%eax
80102653:	c1 f8 1f             	sar    $0x1f,%eax
80102656:	29 c2                	sub    %eax,%edx
80102658:	89 d0                	mov    %edx,%eax
8010265a:	89 45 f8             	mov    %eax,-0x8(%ebp)
    }while(shifter);
8010265d:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
80102661:	75 db                	jne    8010263e <itoa+0x3f>
    *p = '\0';
80102663:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102666:	c6 00 00             	movb   $0x0,(%eax)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
80102669:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010266d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102670:	ba 67 66 66 66       	mov    $0x66666667,%edx
80102675:	89 c8                	mov    %ecx,%eax
80102677:	f7 ea                	imul   %edx
80102679:	c1 fa 02             	sar    $0x2,%edx
8010267c:	89 c8                	mov    %ecx,%eax
8010267e:	c1 f8 1f             	sar    $0x1f,%eax
80102681:	29 c2                	sub    %eax,%edx
80102683:	89 d0                	mov    %edx,%eax
80102685:	c1 e0 02             	shl    $0x2,%eax
80102688:	01 d0                	add    %edx,%eax
8010268a:	01 c0                	add    %eax,%eax
8010268c:	29 c1                	sub    %eax,%ecx
8010268e:	89 ca                	mov    %ecx,%edx
80102690:	0f b6 54 15 ed       	movzbl -0x13(%ebp,%edx,1),%edx
80102695:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102698:	88 10                	mov    %dl,(%eax)
        i = i/10;
8010269a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010269d:	ba 67 66 66 66       	mov    $0x66666667,%edx
801026a2:	89 c8                	mov    %ecx,%eax
801026a4:	f7 ea                	imul   %edx
801026a6:	c1 fa 02             	sar    $0x2,%edx
801026a9:	89 c8                	mov    %ecx,%eax
801026ab:	c1 f8 1f             	sar    $0x1f,%eax
801026ae:	29 c2                	sub    %eax,%edx
801026b0:	89 d0                	mov    %edx,%eax
801026b2:	89 45 08             	mov    %eax,0x8(%ebp)
    }while(i);
801026b5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026b9:	75 ae                	jne    80102669 <itoa+0x6a>
    return b;
801026bb:	8b 45 0c             	mov    0xc(%ebp),%eax
}
801026be:	c9                   	leave  
801026bf:	c3                   	ret    

801026c0 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
801026c0:	55                   	push   %ebp
801026c1:	89 e5                	mov    %esp,%ebp
801026c3:	83 ec 58             	sub    $0x58,%esp
	//path of proccess
	char path[DIGITS];
	memmove(path,"/.swap", 6);
801026c6:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
801026cd:	00 
801026ce:	c7 44 24 04 36 9c 10 	movl   $0x80109c36,0x4(%esp)
801026d5:	80 
801026d6:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801026d9:	89 04 24             	mov    %eax,(%esp)
801026dc:	e8 f3 33 00 00       	call   80105ad4 <memmove>
	itoa(p->pid, path+ 6);
801026e1:	8b 45 08             	mov    0x8(%ebp),%eax
801026e4:	8b 40 10             	mov    0x10(%eax),%eax
801026e7:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801026ea:	83 c2 06             	add    $0x6,%edx
801026ed:	89 54 24 04          	mov    %edx,0x4(%esp)
801026f1:	89 04 24             	mov    %eax,(%esp)
801026f4:	e8 06 ff ff ff       	call   801025ff <itoa>

	struct inode *ip, *dp;
	struct dirent de;
	char name[DIRSIZ];
	uint off;
  if(0 == p->swapFile){
801026f9:	8b 45 08             	mov    0x8(%ebp),%eax
801026fc:	8b 40 7c             	mov    0x7c(%eax),%eax
801026ff:	85 c0                	test   %eax,%eax
80102701:	75 0a                	jne    8010270d <removeSwapFile+0x4d>
    return -1;
80102703:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102708:	e9 bd 01 00 00       	jmp    801028ca <removeSwapFile+0x20a>
  }
  fileclose(p->swapFile);
8010270d:	8b 45 08             	mov    0x8(%ebp),%eax
80102710:	8b 40 7c             	mov    0x7c(%eax),%eax
80102713:	89 04 24             	mov    %eax,(%esp)
80102716:	e8 04 ea ff ff       	call   8010111f <fileclose>

	begin_op();
8010271b:	e8 6a 14 00 00       	call   80103b8a <begin_op>
	if((dp = nameiparent(path, name)) == 0)
80102720:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102723:	89 44 24 04          	mov    %eax,0x4(%esp)
80102727:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010272a:	89 04 24             	mov    %eax,(%esp)
8010272d:	e8 ab fe ff ff       	call   801025dd <nameiparent>
80102732:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102735:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102739:	75 0f                	jne    8010274a <removeSwapFile+0x8a>
	{
		end_op();
8010273b:	e8 ce 14 00 00       	call   80103c0e <end_op>
		return -1;
80102740:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102745:	e9 80 01 00 00       	jmp    801028ca <removeSwapFile+0x20a>
	}

	ilock(dp);
8010274a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010274d:	89 04 24             	mov    %eax,(%esp)
80102750:	e8 b5 f2 ff ff       	call   80101a0a <ilock>

	  // Cannot unlink "." or "..".
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80102755:	c7 44 24 04 3d 9c 10 	movl   $0x80109c3d,0x4(%esp)
8010275c:	80 
8010275d:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102760:	89 04 24             	mov    %eax,(%esp)
80102763:	e8 a8 fa ff ff       	call   80102210 <namecmp>
80102768:	85 c0                	test   %eax,%eax
8010276a:	0f 84 45 01 00 00    	je     801028b5 <removeSwapFile+0x1f5>
80102770:	c7 44 24 04 3f 9c 10 	movl   $0x80109c3f,0x4(%esp)
80102777:	80 
80102778:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010277b:	89 04 24             	mov    %eax,(%esp)
8010277e:	e8 8d fa ff ff       	call   80102210 <namecmp>
80102783:	85 c0                	test   %eax,%eax
80102785:	0f 84 2a 01 00 00    	je     801028b5 <removeSwapFile+0x1f5>
	   goto bad;

	if((ip = dirlookup(dp, name, &off)) == 0)
8010278b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010278e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102792:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102795:	89 44 24 04          	mov    %eax,0x4(%esp)
80102799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010279c:	89 04 24             	mov    %eax,(%esp)
8010279f:	e8 8e fa ff ff       	call   80102232 <dirlookup>
801027a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801027a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801027ab:	75 05                	jne    801027b2 <removeSwapFile+0xf2>
		goto bad;
801027ad:	e9 03 01 00 00       	jmp    801028b5 <removeSwapFile+0x1f5>
	ilock(ip);
801027b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027b5:	89 04 24             	mov    %eax,(%esp)
801027b8:	e8 4d f2 ff ff       	call   80101a0a <ilock>

	if(ip->nlink < 1)
801027bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027c0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801027c4:	66 85 c0             	test   %ax,%ax
801027c7:	7f 0c                	jg     801027d5 <removeSwapFile+0x115>
		panic("unlink: nlink < 1");
801027c9:	c7 04 24 42 9c 10 80 	movl   $0x80109c42,(%esp)
801027d0:	e8 65 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
801027d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027d8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027dc:	66 83 f8 01          	cmp    $0x1,%ax
801027e0:	75 1f                	jne    80102801 <removeSwapFile+0x141>
801027e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027e5:	89 04 24             	mov    %eax,(%esp)
801027e8:	e8 f2 3a 00 00       	call   801062df <isdirempty>
801027ed:	85 c0                	test   %eax,%eax
801027ef:	75 10                	jne    80102801 <removeSwapFile+0x141>
		iunlockput(ip);
801027f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027f4:	89 04 24             	mov    %eax,(%esp)
801027f7:	e8 98 f4 ff ff       	call   80101c94 <iunlockput>
		goto bad;
801027fc:	e9 b4 00 00 00       	jmp    801028b5 <removeSwapFile+0x1f5>
	}

	memset(&de, 0, sizeof(de));
80102801:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80102808:	00 
80102809:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102810:	00 
80102811:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80102814:	89 04 24             	mov    %eax,(%esp)
80102817:	e8 e9 31 00 00       	call   80105a05 <memset>
	if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010281c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010281f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102826:	00 
80102827:	89 44 24 08          	mov    %eax,0x8(%esp)
8010282b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010282e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102835:	89 04 24             	mov    %eax,(%esp)
80102838:	e8 44 f8 ff ff       	call   80102081 <writei>
8010283d:	83 f8 10             	cmp    $0x10,%eax
80102840:	74 0c                	je     8010284e <removeSwapFile+0x18e>
		panic("unlink: writei");
80102842:	c7 04 24 54 9c 10 80 	movl   $0x80109c54,(%esp)
80102849:	e8 ec dc ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR){
8010284e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102851:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102855:	66 83 f8 01          	cmp    $0x1,%ax
80102859:	75 1c                	jne    80102877 <removeSwapFile+0x1b7>
		dp->nlink--;
8010285b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102862:	8d 50 ff             	lea    -0x1(%eax),%edx
80102865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102868:	66 89 50 16          	mov    %dx,0x16(%eax)
		iupdate(dp);
8010286c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010286f:	89 04 24             	mov    %eax,(%esp)
80102872:	e8 d1 ef ff ff       	call   80101848 <iupdate>
	}
	iunlockput(dp);
80102877:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010287a:	89 04 24             	mov    %eax,(%esp)
8010287d:	e8 12 f4 ff ff       	call   80101c94 <iunlockput>

	ip->nlink--;
80102882:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102885:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102889:	8d 50 ff             	lea    -0x1(%eax),%edx
8010288c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010288f:	66 89 50 16          	mov    %dx,0x16(%eax)
	iupdate(ip);
80102893:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102896:	89 04 24             	mov    %eax,(%esp)
80102899:	e8 aa ef ff ff       	call   80101848 <iupdate>
	iunlockput(ip);
8010289e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801028a1:	89 04 24             	mov    %eax,(%esp)
801028a4:	e8 eb f3 ff ff       	call   80101c94 <iunlockput>

	end_op();
801028a9:	e8 60 13 00 00       	call   80103c0e <end_op>

	return 0;
801028ae:	b8 00 00 00 00       	mov    $0x0,%eax
801028b3:	eb 15                	jmp    801028ca <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
801028b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028b8:	89 04 24             	mov    %eax,(%esp)
801028bb:	e8 d4 f3 ff ff       	call   80101c94 <iunlockput>
		end_op();
801028c0:	e8 49 13 00 00       	call   80103c0e <end_op>
		return -1;
801028c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

}
801028ca:	c9                   	leave  
801028cb:	c3                   	ret    

801028cc <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
801028cc:	55                   	push   %ebp
801028cd:	89 e5                	mov    %esp,%ebp
801028cf:	83 ec 38             	sub    $0x38,%esp

	char path[DIGITS];
	memmove(path,"/.swap", 6);
801028d2:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
801028d9:	00 
801028da:	c7 44 24 04 36 9c 10 	movl   $0x80109c36,0x4(%esp)
801028e1:	80 
801028e2:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028e5:	89 04 24             	mov    %eax,(%esp)
801028e8:	e8 e7 31 00 00       	call   80105ad4 <memmove>
	itoa(p->pid, path+ 6);
801028ed:	8b 45 08             	mov    0x8(%ebp),%eax
801028f0:	8b 40 10             	mov    0x10(%eax),%eax
801028f3:	8d 55 e6             	lea    -0x1a(%ebp),%edx
801028f6:	83 c2 06             	add    $0x6,%edx
801028f9:	89 54 24 04          	mov    %edx,0x4(%esp)
801028fd:	89 04 24             	mov    %eax,(%esp)
80102900:	e8 fa fc ff ff       	call   801025ff <itoa>

    begin_op();
80102905:	e8 80 12 00 00       	call   80103b8a <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
8010290a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80102911:	00 
80102912:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102919:	00 
8010291a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80102921:	00 
80102922:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102925:	89 04 24             	mov    %eax,(%esp)
80102928:	e8 f8 3b 00 00       	call   80106525 <create>
8010292d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	iunlock(in);
80102930:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102933:	89 04 24             	mov    %eax,(%esp)
80102936:	e8 23 f2 ff ff       	call   80101b5e <iunlock>

	p->swapFile = filealloc();
8010293b:	e8 37 e7 ff ff       	call   80101077 <filealloc>
80102940:	8b 55 08             	mov    0x8(%ebp),%edx
80102943:	89 42 7c             	mov    %eax,0x7c(%edx)
	if (p->swapFile == 0)
80102946:	8b 45 08             	mov    0x8(%ebp),%eax
80102949:	8b 40 7c             	mov    0x7c(%eax),%eax
8010294c:	85 c0                	test   %eax,%eax
8010294e:	75 0c                	jne    8010295c <createSwapFile+0x90>
		panic("no slot for files on /store");
80102950:	c7 04 24 63 9c 10 80 	movl   $0x80109c63,(%esp)
80102957:	e8 de db ff ff       	call   8010053a <panic>

	p->swapFile->ip = in;
8010295c:	8b 45 08             	mov    0x8(%ebp),%eax
8010295f:	8b 40 7c             	mov    0x7c(%eax),%eax
80102962:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102965:	89 50 10             	mov    %edx,0x10(%eax)
	p->swapFile->type = FD_INODE;
80102968:	8b 45 08             	mov    0x8(%ebp),%eax
8010296b:	8b 40 7c             	mov    0x7c(%eax),%eax
8010296e:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
	p->swapFile->off = 0;
80102974:	8b 45 08             	mov    0x8(%ebp),%eax
80102977:	8b 40 7c             	mov    0x7c(%eax),%eax
8010297a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
	p->swapFile->readable = O_WRONLY;
80102981:	8b 45 08             	mov    0x8(%ebp),%eax
80102984:	8b 40 7c             	mov    0x7c(%eax),%eax
80102987:	c6 40 08 01          	movb   $0x1,0x8(%eax)
	p->swapFile->writable = O_RDWR;
8010298b:	8b 45 08             	mov    0x8(%ebp),%eax
8010298e:	8b 40 7c             	mov    0x7c(%eax),%eax
80102991:	c6 40 09 02          	movb   $0x2,0x9(%eax)
    end_op();
80102995:	e8 74 12 00 00       	call   80103c0e <end_op>

    return 0;
8010299a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010299f:	c9                   	leave  
801029a0:	c3                   	ret    

801029a1 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
801029a1:	55                   	push   %ebp
801029a2:	89 e5                	mov    %esp,%ebp
801029a4:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
801029a7:	8b 45 08             	mov    0x8(%ebp),%eax
801029aa:	8b 40 7c             	mov    0x7c(%eax),%eax
801029ad:	8b 55 10             	mov    0x10(%ebp),%edx
801029b0:	89 50 14             	mov    %edx,0x14(%eax)

	return filewrite(p->swapFile, buffer, size);
801029b3:	8b 55 14             	mov    0x14(%ebp),%edx
801029b6:	8b 45 08             	mov    0x8(%ebp),%eax
801029b9:	8b 40 7c             	mov    0x7c(%eax),%eax
801029bc:	89 54 24 08          	mov    %edx,0x8(%esp)
801029c0:	8b 55 0c             	mov    0xc(%ebp),%edx
801029c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801029c7:	89 04 24             	mov    %eax,(%esp)
801029ca:	e8 31 e9 ff ff       	call   80101300 <filewrite>

}
801029cf:	c9                   	leave  
801029d0:	c3                   	ret    

801029d1 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
801029d1:	55                   	push   %ebp
801029d2:	89 e5                	mov    %esp,%ebp
801029d4:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
801029d7:	8b 45 08             	mov    0x8(%ebp),%eax
801029da:	8b 40 7c             	mov    0x7c(%eax),%eax
801029dd:	8b 55 10             	mov    0x10(%ebp),%edx
801029e0:	89 50 14             	mov    %edx,0x14(%eax)

	return fileread(p->swapFile, buffer,  size);
801029e3:	8b 55 14             	mov    0x14(%ebp),%edx
801029e6:	8b 45 08             	mov    0x8(%ebp),%eax
801029e9:	8b 40 7c             	mov    0x7c(%eax),%eax
801029ec:	89 54 24 08          	mov    %edx,0x8(%esp)
801029f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801029f3:	89 54 24 04          	mov    %edx,0x4(%esp)
801029f7:	89 04 24             	mov    %eax,(%esp)
801029fa:	e8 45 e8 ff ff       	call   80101244 <fileread>
}
801029ff:	c9                   	leave  
80102a00:	c3                   	ret    

80102a01 <copySwapFile>:

void
copySwapFile(struct proc *from, struct proc *to){
80102a01:	55                   	push   %ebp
80102a02:	89 e5                	mov    %esp,%ebp
80102a04:	53                   	push   %ebx
80102a05:	81 ec 24 08 00 00    	sub    $0x824,%esp
  char buf[2048];
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 2048){
80102a0b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a12:	eb 4f                	jmp    80102a63 <copySwapFile+0x62>
    readFromSwapFile(from,buf,i,2048);
80102a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a17:	c7 44 24 0c 00 08 00 	movl   $0x800,0xc(%esp)
80102a1e:	00 
80102a1f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a23:	8d 85 f0 f7 ff ff    	lea    -0x810(%ebp),%eax
80102a29:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a2d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a30:	89 04 24             	mov    %eax,(%esp)
80102a33:	e8 99 ff ff ff       	call   801029d1 <readFromSwapFile>
    writeToSwapFile(to,buf,i,2048);
80102a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a3b:	c7 44 24 0c 00 08 00 	movl   $0x800,0xc(%esp)
80102a42:	00 
80102a43:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a47:	8d 85 f0 f7 ff ff    	lea    -0x810(%ebp),%eax
80102a4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a51:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a54:	89 04 24             	mov    %eax,(%esp)
80102a57:	e8 45 ff ff ff       	call   801029a1 <writeToSwapFile>

void
copySwapFile(struct proc *from, struct proc *to){
  char buf[2048];
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 2048){
80102a5c:	81 45 f4 00 08 00 00 	addl   $0x800,-0xc(%ebp)
80102a63:	81 7d f4 ff df 00 00 	cmpl   $0xdfff,-0xc(%ebp)
80102a6a:	7e a8                	jle    80102a14 <copySwapFile+0x13>
    readFromSwapFile(from,buf,i,2048);
    writeToSwapFile(to,buf,i,2048);
  }
  for(j = 0; j < 30; j++){
80102a6c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102a73:	e9 9d 00 00 00       	jmp    80102b15 <copySwapFile+0x114>
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
80102a78:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a7b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102a7e:	89 d0                	mov    %edx,%eax
80102a80:	c1 e0 02             	shl    $0x2,%eax
80102a83:	01 d0                	add    %edx,%eax
80102a85:	c1 e0 02             	shl    $0x2,%eax
80102a88:	01 c8                	add    %ecx,%eax
80102a8a:	05 98 00 00 00       	add    $0x98,%eax
80102a8f:	8b 00                	mov    (%eax),%eax
80102a91:	83 f8 ff             	cmp    $0xffffffff,%eax
80102a94:	74 7b                	je     80102b11 <copySwapFile+0x110>
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102a96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a9d:	eb 6c                	jmp    80102b0b <copySwapFile+0x10a>
            if(to->pagesMetaData[i].va == from->pagesMetaData[j].va){//thats the one!
80102a9f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102aa2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102aa5:	89 d0                	mov    %edx,%eax
80102aa7:	c1 e0 02             	shl    $0x2,%eax
80102aaa:	01 d0                	add    %edx,%eax
80102aac:	c1 e0 02             	shl    $0x2,%eax
80102aaf:	01 c8                	add    %ecx,%eax
80102ab1:	05 90 00 00 00       	add    $0x90,%eax
80102ab6:	8b 08                	mov    (%eax),%ecx
80102ab8:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102abb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102abe:	89 d0                	mov    %edx,%eax
80102ac0:	c1 e0 02             	shl    $0x2,%eax
80102ac3:	01 d0                	add    %edx,%eax
80102ac5:	c1 e0 02             	shl    $0x2,%eax
80102ac8:	01 d8                	add    %ebx,%eax
80102aca:	05 90 00 00 00       	add    $0x90,%eax
80102acf:	8b 00                	mov    (%eax),%eax
80102ad1:	39 c1                	cmp    %eax,%ecx
80102ad3:	75 32                	jne    80102b07 <copySwapFile+0x106>
              to->pagesMetaData[i].fileOffset = from->pagesMetaData[j].fileOffset;
80102ad5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102ad8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102adb:	89 d0                	mov    %edx,%eax
80102add:	c1 e0 02             	shl    $0x2,%eax
80102ae0:	01 d0                	add    %edx,%eax
80102ae2:	c1 e0 02             	shl    $0x2,%eax
80102ae5:	01 c8                	add    %ecx,%eax
80102ae7:	05 98 00 00 00       	add    $0x98,%eax
80102aec:	8b 08                	mov    (%eax),%ecx
80102aee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80102af1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102af4:	89 d0                	mov    %edx,%eax
80102af6:	c1 e0 02             	shl    $0x2,%eax
80102af9:	01 d0                	add    %edx,%eax
80102afb:	c1 e0 02             	shl    $0x2,%eax
80102afe:	01 d8                	add    %ebx,%eax
80102b00:	05 98 00 00 00       	add    $0x98,%eax
80102b05:	89 08                	mov    %ecx,(%eax)
    writeToSwapFile(to,buf,i,2048);
  }
  for(j = 0; j < 30; j++){
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102b07:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b0b:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80102b0f:	7e 8e                	jle    80102a9f <copySwapFile+0x9e>
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 2048){
    readFromSwapFile(from,buf,i,2048);
    writeToSwapFile(to,buf,i,2048);
  }
  for(j = 0; j < 30; j++){
80102b11:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b15:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80102b19:	0f 8e 59 ff ff ff    	jle    80102a78 <copySwapFile+0x77>
              to->pagesMetaData[i].fileOffset = from->pagesMetaData[j].fileOffset;
            }
          }
        }
      }
80102b1f:	81 c4 24 08 00 00    	add    $0x824,%esp
80102b25:	5b                   	pop    %ebx
80102b26:	5d                   	pop    %ebp
80102b27:	c3                   	ret    

80102b28 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b28:	55                   	push   %ebp
80102b29:	89 e5                	mov    %esp,%ebp
80102b2b:	83 ec 14             	sub    $0x14,%esp
80102b2e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b31:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b35:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b39:	89 c2                	mov    %eax,%edx
80102b3b:	ec                   	in     (%dx),%al
80102b3c:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b3f:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b43:	c9                   	leave  
80102b44:	c3                   	ret    

80102b45 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102b45:	55                   	push   %ebp
80102b46:	89 e5                	mov    %esp,%ebp
80102b48:	57                   	push   %edi
80102b49:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102b4a:	8b 55 08             	mov    0x8(%ebp),%edx
80102b4d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b50:	8b 45 10             	mov    0x10(%ebp),%eax
80102b53:	89 cb                	mov    %ecx,%ebx
80102b55:	89 df                	mov    %ebx,%edi
80102b57:	89 c1                	mov    %eax,%ecx
80102b59:	fc                   	cld    
80102b5a:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b5c:	89 c8                	mov    %ecx,%eax
80102b5e:	89 fb                	mov    %edi,%ebx
80102b60:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b63:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b66:	5b                   	pop    %ebx
80102b67:	5f                   	pop    %edi
80102b68:	5d                   	pop    %ebp
80102b69:	c3                   	ret    

80102b6a <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b6a:	55                   	push   %ebp
80102b6b:	89 e5                	mov    %esp,%ebp
80102b6d:	83 ec 08             	sub    $0x8,%esp
80102b70:	8b 55 08             	mov    0x8(%ebp),%edx
80102b73:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b76:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102b7a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b7d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b81:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b85:	ee                   	out    %al,(%dx)
}
80102b86:	c9                   	leave  
80102b87:	c3                   	ret    

80102b88 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b88:	55                   	push   %ebp
80102b89:	89 e5                	mov    %esp,%ebp
80102b8b:	56                   	push   %esi
80102b8c:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b8d:	8b 55 08             	mov    0x8(%ebp),%edx
80102b90:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b93:	8b 45 10             	mov    0x10(%ebp),%eax
80102b96:	89 cb                	mov    %ecx,%ebx
80102b98:	89 de                	mov    %ebx,%esi
80102b9a:	89 c1                	mov    %eax,%ecx
80102b9c:	fc                   	cld    
80102b9d:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102b9f:	89 c8                	mov    %ecx,%eax
80102ba1:	89 f3                	mov    %esi,%ebx
80102ba3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102ba6:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102ba9:	5b                   	pop    %ebx
80102baa:	5e                   	pop    %esi
80102bab:	5d                   	pop    %ebp
80102bac:	c3                   	ret    

80102bad <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102bad:	55                   	push   %ebp
80102bae:	89 e5                	mov    %esp,%ebp
80102bb0:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102bb3:	90                   	nop
80102bb4:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102bbb:	e8 68 ff ff ff       	call   80102b28 <inb>
80102bc0:	0f b6 c0             	movzbl %al,%eax
80102bc3:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102bc6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bc9:	25 c0 00 00 00       	and    $0xc0,%eax
80102bce:	83 f8 40             	cmp    $0x40,%eax
80102bd1:	75 e1                	jne    80102bb4 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102bd3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102bd7:	74 11                	je     80102bea <idewait+0x3d>
80102bd9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bdc:	83 e0 21             	and    $0x21,%eax
80102bdf:	85 c0                	test   %eax,%eax
80102be1:	74 07                	je     80102bea <idewait+0x3d>
    return -1;
80102be3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102be8:	eb 05                	jmp    80102bef <idewait+0x42>
  return 0;
80102bea:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bef:	c9                   	leave  
80102bf0:	c3                   	ret    

80102bf1 <ideinit>:

void
ideinit(void)
{
80102bf1:	55                   	push   %ebp
80102bf2:	89 e5                	mov    %esp,%ebp
80102bf4:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102bf7:	c7 44 24 04 7f 9c 10 	movl   $0x80109c7f,0x4(%esp)
80102bfe:	80 
80102bff:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c06:	e8 85 2b 00 00       	call   80105790 <initlock>
  picenable(IRQ_IDE);
80102c0b:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c12:	e8 12 19 00 00       	call   80104529 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102c17:	a1 40 49 11 80       	mov    0x80114940,%eax
80102c1c:	83 e8 01             	sub    $0x1,%eax
80102c1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c23:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c2a:	e8 43 04 00 00       	call   80103072 <ioapicenable>
  idewait(0);
80102c2f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c36:	e8 72 ff ff ff       	call   80102bad <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102c3b:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102c42:	00 
80102c43:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c4a:	e8 1b ff ff ff       	call   80102b6a <outb>
  for(i=0; i<1000; i++){
80102c4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c56:	eb 20                	jmp    80102c78 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c58:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c5f:	e8 c4 fe ff ff       	call   80102b28 <inb>
80102c64:	84 c0                	test   %al,%al
80102c66:	74 0c                	je     80102c74 <ideinit+0x83>
      havedisk1 = 1;
80102c68:	c7 05 38 d6 10 80 01 	movl   $0x1,0x8010d638
80102c6f:	00 00 00 
      break;
80102c72:	eb 0d                	jmp    80102c81 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102c74:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c78:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c7f:	7e d7                	jle    80102c58 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c81:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c88:	00 
80102c89:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c90:	e8 d5 fe ff ff       	call   80102b6a <outb>
}
80102c95:	c9                   	leave  
80102c96:	c3                   	ret    

80102c97 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102c97:	55                   	push   %ebp
80102c98:	89 e5                	mov    %esp,%ebp
80102c9a:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102c9d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102ca1:	75 0c                	jne    80102caf <idestart+0x18>
    panic("idestart");
80102ca3:	c7 04 24 83 9c 10 80 	movl   $0x80109c83,(%esp)
80102caa:	e8 8b d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102caf:	8b 45 08             	mov    0x8(%ebp),%eax
80102cb2:	8b 40 08             	mov    0x8(%eax),%eax
80102cb5:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102cba:	76 0c                	jbe    80102cc8 <idestart+0x31>
    panic("incorrect blockno");
80102cbc:	c7 04 24 8c 9c 10 80 	movl   $0x80109c8c,(%esp)
80102cc3:	e8 72 d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102cc8:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102ccf:	8b 45 08             	mov    0x8(%ebp),%eax
80102cd2:	8b 50 08             	mov    0x8(%eax),%edx
80102cd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd8:	0f af c2             	imul   %edx,%eax
80102cdb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102cde:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102ce2:	7e 0c                	jle    80102cf0 <idestart+0x59>
80102ce4:	c7 04 24 83 9c 10 80 	movl   $0x80109c83,(%esp)
80102ceb:	e8 4a d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102cf0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102cf7:	e8 b1 fe ff ff       	call   80102bad <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102cfc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102d03:	00 
80102d04:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102d0b:	e8 5a fe ff ff       	call   80102b6a <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102d10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d13:	0f b6 c0             	movzbl %al,%eax
80102d16:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d1a:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102d21:	e8 44 fe ff ff       	call   80102b6a <outb>
  outb(0x1f3, sector & 0xff);
80102d26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d29:	0f b6 c0             	movzbl %al,%eax
80102d2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d30:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102d37:	e8 2e fe ff ff       	call   80102b6a <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102d3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d3f:	c1 f8 08             	sar    $0x8,%eax
80102d42:	0f b6 c0             	movzbl %al,%eax
80102d45:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d49:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102d50:	e8 15 fe ff ff       	call   80102b6a <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d58:	c1 f8 10             	sar    $0x10,%eax
80102d5b:	0f b6 c0             	movzbl %al,%eax
80102d5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d62:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102d69:	e8 fc fd ff ff       	call   80102b6a <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d71:	8b 40 04             	mov    0x4(%eax),%eax
80102d74:	83 e0 01             	and    $0x1,%eax
80102d77:	c1 e0 04             	shl    $0x4,%eax
80102d7a:	89 c2                	mov    %eax,%edx
80102d7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d7f:	c1 f8 18             	sar    $0x18,%eax
80102d82:	83 e0 0f             	and    $0xf,%eax
80102d85:	09 d0                	or     %edx,%eax
80102d87:	83 c8 e0             	or     $0xffffffe0,%eax
80102d8a:	0f b6 c0             	movzbl %al,%eax
80102d8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d91:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102d98:	e8 cd fd ff ff       	call   80102b6a <outb>
  if(b->flags & B_DIRTY){
80102d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80102da0:	8b 00                	mov    (%eax),%eax
80102da2:	83 e0 04             	and    $0x4,%eax
80102da5:	85 c0                	test   %eax,%eax
80102da7:	74 34                	je     80102ddd <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102da9:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102db0:	00 
80102db1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102db8:	e8 ad fd ff ff       	call   80102b6a <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102dbd:	8b 45 08             	mov    0x8(%ebp),%eax
80102dc0:	83 c0 18             	add    $0x18,%eax
80102dc3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102dca:	00 
80102dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dcf:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102dd6:	e8 ad fd ff ff       	call   80102b88 <outsl>
80102ddb:	eb 14                	jmp    80102df1 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102ddd:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102de4:	00 
80102de5:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102dec:	e8 79 fd ff ff       	call   80102b6a <outb>
  }
}
80102df1:	c9                   	leave  
80102df2:	c3                   	ret    

80102df3 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102df3:	55                   	push   %ebp
80102df4:	89 e5                	mov    %esp,%ebp
80102df6:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102df9:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e00:	e8 ac 29 00 00       	call   801057b1 <acquire>
  if((b = idequeue) == 0){
80102e05:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e0d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e11:	75 11                	jne    80102e24 <ideintr+0x31>
    release(&idelock);
80102e13:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e1a:	e8 f4 29 00 00       	call   80105813 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102e1f:	e9 90 00 00 00       	jmp    80102eb4 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102e24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e27:	8b 40 14             	mov    0x14(%eax),%eax
80102e2a:	a3 34 d6 10 80       	mov    %eax,0x8010d634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e32:	8b 00                	mov    (%eax),%eax
80102e34:	83 e0 04             	and    $0x4,%eax
80102e37:	85 c0                	test   %eax,%eax
80102e39:	75 2e                	jne    80102e69 <ideintr+0x76>
80102e3b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e42:	e8 66 fd ff ff       	call   80102bad <idewait>
80102e47:	85 c0                	test   %eax,%eax
80102e49:	78 1e                	js     80102e69 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102e4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e4e:	83 c0 18             	add    $0x18,%eax
80102e51:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e58:	00 
80102e59:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e5d:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e64:	e8 dc fc ff ff       	call   80102b45 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e6c:	8b 00                	mov    (%eax),%eax
80102e6e:	83 c8 02             	or     $0x2,%eax
80102e71:	89 c2                	mov    %eax,%edx
80102e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e76:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102e78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e7b:	8b 00                	mov    (%eax),%eax
80102e7d:	83 e0 fb             	and    $0xfffffffb,%eax
80102e80:	89 c2                	mov    %eax,%edx
80102e82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e85:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e8a:	89 04 24             	mov    %eax,(%esp)
80102e8d:	e8 b3 26 00 00       	call   80105545 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102e92:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e97:	85 c0                	test   %eax,%eax
80102e99:	74 0d                	je     80102ea8 <ideintr+0xb5>
    idestart(idequeue);
80102e9b:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ea0:	89 04 24             	mov    %eax,(%esp)
80102ea3:	e8 ef fd ff ff       	call   80102c97 <idestart>

  release(&idelock);
80102ea8:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102eaf:	e8 5f 29 00 00       	call   80105813 <release>
}
80102eb4:	c9                   	leave  
80102eb5:	c3                   	ret    

80102eb6 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102eb6:	55                   	push   %ebp
80102eb7:	89 e5                	mov    %esp,%ebp
80102eb9:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102ebc:	8b 45 08             	mov    0x8(%ebp),%eax
80102ebf:	8b 00                	mov    (%eax),%eax
80102ec1:	83 e0 01             	and    $0x1,%eax
80102ec4:	85 c0                	test   %eax,%eax
80102ec6:	75 0c                	jne    80102ed4 <iderw+0x1e>
    panic("iderw: buf not busy");
80102ec8:	c7 04 24 9e 9c 10 80 	movl   $0x80109c9e,(%esp)
80102ecf:	e8 66 d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102ed4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ed7:	8b 00                	mov    (%eax),%eax
80102ed9:	83 e0 06             	and    $0x6,%eax
80102edc:	83 f8 02             	cmp    $0x2,%eax
80102edf:	75 0c                	jne    80102eed <iderw+0x37>
    panic("iderw: nothing to do");
80102ee1:	c7 04 24 b2 9c 10 80 	movl   $0x80109cb2,(%esp)
80102ee8:	e8 4d d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102eed:	8b 45 08             	mov    0x8(%ebp),%eax
80102ef0:	8b 40 04             	mov    0x4(%eax),%eax
80102ef3:	85 c0                	test   %eax,%eax
80102ef5:	74 15                	je     80102f0c <iderw+0x56>
80102ef7:	a1 38 d6 10 80       	mov    0x8010d638,%eax
80102efc:	85 c0                	test   %eax,%eax
80102efe:	75 0c                	jne    80102f0c <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102f00:	c7 04 24 c7 9c 10 80 	movl   $0x80109cc7,(%esp)
80102f07:	e8 2e d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f0c:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f13:	e8 99 28 00 00       	call   801057b1 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102f18:	8b 45 08             	mov    0x8(%ebp),%eax
80102f1b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102f22:	c7 45 f4 34 d6 10 80 	movl   $0x8010d634,-0xc(%ebp)
80102f29:	eb 0b                	jmp    80102f36 <iderw+0x80>
80102f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f2e:	8b 00                	mov    (%eax),%eax
80102f30:	83 c0 14             	add    $0x14,%eax
80102f33:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102f36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f39:	8b 00                	mov    (%eax),%eax
80102f3b:	85 c0                	test   %eax,%eax
80102f3d:	75 ec                	jne    80102f2b <iderw+0x75>
    ;
  *pp = b;
80102f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f42:	8b 55 08             	mov    0x8(%ebp),%edx
80102f45:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102f47:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f4c:	3b 45 08             	cmp    0x8(%ebp),%eax
80102f4f:	75 0d                	jne    80102f5e <iderw+0xa8>
    idestart(b);
80102f51:	8b 45 08             	mov    0x8(%ebp),%eax
80102f54:	89 04 24             	mov    %eax,(%esp)
80102f57:	e8 3b fd ff ff       	call   80102c97 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f5c:	eb 15                	jmp    80102f73 <iderw+0xbd>
80102f5e:	eb 13                	jmp    80102f73 <iderw+0xbd>
    sleep(b, &idelock);
80102f60:	c7 44 24 04 00 d6 10 	movl   $0x8010d600,0x4(%esp)
80102f67:	80 
80102f68:	8b 45 08             	mov    0x8(%ebp),%eax
80102f6b:	89 04 24             	mov    %eax,(%esp)
80102f6e:	e8 f6 24 00 00       	call   80105469 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f73:	8b 45 08             	mov    0x8(%ebp),%eax
80102f76:	8b 00                	mov    (%eax),%eax
80102f78:	83 e0 06             	and    $0x6,%eax
80102f7b:	83 f8 02             	cmp    $0x2,%eax
80102f7e:	75 e0                	jne    80102f60 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102f80:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f87:	e8 87 28 00 00       	call   80105813 <release>
}
80102f8c:	c9                   	leave  
80102f8d:	c3                   	ret    

80102f8e <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f8e:	55                   	push   %ebp
80102f8f:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f91:	a1 14 42 11 80       	mov    0x80114214,%eax
80102f96:	8b 55 08             	mov    0x8(%ebp),%edx
80102f99:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102f9b:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fa0:	8b 40 10             	mov    0x10(%eax),%eax
}
80102fa3:	5d                   	pop    %ebp
80102fa4:	c3                   	ret    

80102fa5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102fa5:	55                   	push   %ebp
80102fa6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fa8:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fad:	8b 55 08             	mov    0x8(%ebp),%edx
80102fb0:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102fb2:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fb7:	8b 55 0c             	mov    0xc(%ebp),%edx
80102fba:	89 50 10             	mov    %edx,0x10(%eax)
}
80102fbd:	5d                   	pop    %ebp
80102fbe:	c3                   	ret    

80102fbf <ioapicinit>:

void
ioapicinit(void)
{
80102fbf:	55                   	push   %ebp
80102fc0:	89 e5                	mov    %esp,%ebp
80102fc2:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102fc5:	a1 44 43 11 80       	mov    0x80114344,%eax
80102fca:	85 c0                	test   %eax,%eax
80102fcc:	75 05                	jne    80102fd3 <ioapicinit+0x14>
    return;
80102fce:	e9 9d 00 00 00       	jmp    80103070 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102fd3:	c7 05 14 42 11 80 00 	movl   $0xfec00000,0x80114214
80102fda:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102fdd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fe4:	e8 a5 ff ff ff       	call   80102f8e <ioapicread>
80102fe9:	c1 e8 10             	shr    $0x10,%eax
80102fec:	25 ff 00 00 00       	and    $0xff,%eax
80102ff1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102ff4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102ffb:	e8 8e ff ff ff       	call   80102f8e <ioapicread>
80103000:	c1 e8 18             	shr    $0x18,%eax
80103003:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103006:	0f b6 05 40 43 11 80 	movzbl 0x80114340,%eax
8010300d:	0f b6 c0             	movzbl %al,%eax
80103010:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103013:	74 0c                	je     80103021 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103015:	c7 04 24 e8 9c 10 80 	movl   $0x80109ce8,(%esp)
8010301c:	e8 7f d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103021:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103028:	eb 3e                	jmp    80103068 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010302a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010302d:	83 c0 20             	add    $0x20,%eax
80103030:	0d 00 00 01 00       	or     $0x10000,%eax
80103035:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103038:	83 c2 08             	add    $0x8,%edx
8010303b:	01 d2                	add    %edx,%edx
8010303d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103041:	89 14 24             	mov    %edx,(%esp)
80103044:	e8 5c ff ff ff       	call   80102fa5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103049:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010304c:	83 c0 08             	add    $0x8,%eax
8010304f:	01 c0                	add    %eax,%eax
80103051:	83 c0 01             	add    $0x1,%eax
80103054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010305b:	00 
8010305c:	89 04 24             	mov    %eax,(%esp)
8010305f:	e8 41 ff ff ff       	call   80102fa5 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103064:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103068:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010306b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010306e:	7e ba                	jle    8010302a <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103070:	c9                   	leave  
80103071:	c3                   	ret    

80103072 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103072:	55                   	push   %ebp
80103073:	89 e5                	mov    %esp,%ebp
80103075:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103078:	a1 44 43 11 80       	mov    0x80114344,%eax
8010307d:	85 c0                	test   %eax,%eax
8010307f:	75 02                	jne    80103083 <ioapicenable+0x11>
    return;
80103081:	eb 37                	jmp    801030ba <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103083:	8b 45 08             	mov    0x8(%ebp),%eax
80103086:	83 c0 20             	add    $0x20,%eax
80103089:	8b 55 08             	mov    0x8(%ebp),%edx
8010308c:	83 c2 08             	add    $0x8,%edx
8010308f:	01 d2                	add    %edx,%edx
80103091:	89 44 24 04          	mov    %eax,0x4(%esp)
80103095:	89 14 24             	mov    %edx,(%esp)
80103098:	e8 08 ff ff ff       	call   80102fa5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
8010309d:	8b 45 0c             	mov    0xc(%ebp),%eax
801030a0:	c1 e0 18             	shl    $0x18,%eax
801030a3:	8b 55 08             	mov    0x8(%ebp),%edx
801030a6:	83 c2 08             	add    $0x8,%edx
801030a9:	01 d2                	add    %edx,%edx
801030ab:	83 c2 01             	add    $0x1,%edx
801030ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801030b2:	89 14 24             	mov    %edx,(%esp)
801030b5:	e8 eb fe ff ff       	call   80102fa5 <ioapicwrite>
}
801030ba:	c9                   	leave  
801030bb:	c3                   	ret    

801030bc <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801030bc:	55                   	push   %ebp
801030bd:	89 e5                	mov    %esp,%ebp
801030bf:	8b 45 08             	mov    0x8(%ebp),%eax
801030c2:	05 00 00 00 80       	add    $0x80000000,%eax
801030c7:	5d                   	pop    %ebp
801030c8:	c3                   	ret    

801030c9 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801030c9:	55                   	push   %ebp
801030ca:	89 e5                	mov    %esp,%ebp
801030cc:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801030cf:	c7 44 24 04 1a 9d 10 	movl   $0x80109d1a,0x4(%esp)
801030d6:	80 
801030d7:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801030de:	e8 ad 26 00 00       	call   80105790 <initlock>
  kmem.use_lock = 0;
801030e3:	c7 05 54 42 11 80 00 	movl   $0x0,0x80114254
801030ea:	00 00 00 
  freerange(vstart, vend);
801030ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801030f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801030f4:	8b 45 08             	mov    0x8(%ebp),%eax
801030f7:	89 04 24             	mov    %eax,(%esp)
801030fa:	e8 26 00 00 00       	call   80103125 <freerange>
}
801030ff:	c9                   	leave  
80103100:	c3                   	ret    

80103101 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103101:	55                   	push   %ebp
80103102:	89 e5                	mov    %esp,%ebp
80103104:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103107:	8b 45 0c             	mov    0xc(%ebp),%eax
8010310a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310e:	8b 45 08             	mov    0x8(%ebp),%eax
80103111:	89 04 24             	mov    %eax,(%esp)
80103114:	e8 0c 00 00 00       	call   80103125 <freerange>
  kmem.use_lock = 1;
80103119:	c7 05 54 42 11 80 01 	movl   $0x1,0x80114254
80103120:	00 00 00 
}
80103123:	c9                   	leave  
80103124:	c3                   	ret    

80103125 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103125:	55                   	push   %ebp
80103126:	89 e5                	mov    %esp,%ebp
80103128:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
8010312b:	8b 45 08             	mov    0x8(%ebp),%eax
8010312e:	05 ff 0f 00 00       	add    $0xfff,%eax
80103133:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103138:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010313b:	eb 12                	jmp    8010314f <freerange+0x2a>
    kfree(p);
8010313d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103140:	89 04 24             	mov    %eax,(%esp)
80103143:	e8 16 00 00 00       	call   8010315e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103148:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010314f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103152:	05 00 10 00 00       	add    $0x1000,%eax
80103157:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010315a:	76 e1                	jbe    8010313d <freerange+0x18>
    kfree(p);
}
8010315c:	c9                   	leave  
8010315d:	c3                   	ret    

8010315e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
8010315e:	55                   	push   %ebp
8010315f:	89 e5                	mov    %esp,%ebp
80103161:	83 ec 28             	sub    $0x28,%esp
  // if(getPid()){
  //   cprintf("%x\n",v);
  // }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
80103164:	8b 45 08             	mov    0x8(%ebp),%eax
80103167:	25 ff 0f 00 00       	and    $0xfff,%eax
8010316c:	85 c0                	test   %eax,%eax
8010316e:	75 1b                	jne    8010318b <kfree+0x2d>
80103170:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
80103177:	72 12                	jb     8010318b <kfree+0x2d>
80103179:	8b 45 08             	mov    0x8(%ebp),%eax
8010317c:	89 04 24             	mov    %eax,(%esp)
8010317f:	e8 38 ff ff ff       	call   801030bc <v2p>
80103184:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103189:	76 50                	jbe    801031db <kfree+0x7d>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
8010318b:	8b 45 08             	mov    0x8(%ebp),%eax
8010318e:	89 04 24             	mov    %eax,(%esp)
80103191:	e8 26 ff ff ff       	call   801030bc <v2p>
80103196:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010319b:	0f 97 c0             	seta   %al
8010319e:	0f b6 d0             	movzbl %al,%edx
801031a1:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
801031a8:	0f 92 c0             	setb   %al
801031ab:	0f b6 c0             	movzbl %al,%eax
801031ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
801031b1:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
801031b7:	89 54 24 0c          	mov    %edx,0xc(%esp)
801031bb:	89 44 24 08          	mov    %eax,0x8(%esp)
801031bf:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801031c3:	c7 04 24 1f 9d 10 80 	movl   $0x80109d1f,(%esp)
801031ca:	e8 d1 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031cf:	c7 04 24 36 9d 10 80 	movl   $0x80109d36,(%esp)
801031d6:	e8 5f d3 ff ff       	call   8010053a <panic>
  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  // if(getPid()){
  //   cprintf("after memset\n");
  // }
  if(kmem.use_lock)
801031db:	a1 54 42 11 80       	mov    0x80114254,%eax
801031e0:	85 c0                	test   %eax,%eax
801031e2:	74 0c                	je     801031f0 <kfree+0x92>
    acquire(&kmem.lock);
801031e4:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801031eb:	e8 c1 25 00 00       	call   801057b1 <acquire>
  r = (struct run*)v;
801031f0:	8b 45 08             	mov    0x8(%ebp),%eax
801031f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
801031f6:	8b 15 58 42 11 80    	mov    0x80114258,%edx
801031fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ff:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103201:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103204:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103209:	a1 54 42 11 80       	mov    0x80114254,%eax
8010320e:	85 c0                	test   %eax,%eax
80103210:	74 0c                	je     8010321e <kfree+0xc0>
    release(&kmem.lock);
80103212:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103219:	e8 f5 25 00 00       	call   80105813 <release>
}
8010321e:	c9                   	leave  
8010321f:	c3                   	ret    

80103220 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103220:	55                   	push   %ebp
80103221:	89 e5                	mov    %esp,%ebp
80103223:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103226:	a1 54 42 11 80       	mov    0x80114254,%eax
8010322b:	85 c0                	test   %eax,%eax
8010322d:	74 0c                	je     8010323b <kalloc+0x1b>
    acquire(&kmem.lock);
8010322f:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103236:	e8 76 25 00 00       	call   801057b1 <acquire>
  r = kmem.freelist;
8010323b:	a1 58 42 11 80       	mov    0x80114258,%eax
80103240:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103243:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103247:	74 0a                	je     80103253 <kalloc+0x33>
    kmem.freelist = r->next;
80103249:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010324c:	8b 00                	mov    (%eax),%eax
8010324e:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103253:	a1 54 42 11 80       	mov    0x80114254,%eax
80103258:	85 c0                	test   %eax,%eax
8010325a:	74 0c                	je     80103268 <kalloc+0x48>
    release(&kmem.lock);
8010325c:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103263:	e8 ab 25 00 00       	call   80105813 <release>
  return (char*)r;
80103268:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010326b:	c9                   	leave  
8010326c:	c3                   	ret    

8010326d <countPages>:

int
countPages(){
8010326d:	55                   	push   %ebp
8010326e:	89 e5                	mov    %esp,%ebp
80103270:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
80103273:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
8010327a:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103281:	e8 2b 25 00 00       	call   801057b1 <acquire>
  r = kmem.freelist;
80103286:	a1 58 42 11 80       	mov    0x80114258,%eax
8010328b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
8010328e:	eb 0c                	jmp    8010329c <countPages+0x2f>
    result++;
80103290:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
80103294:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103297:	8b 00                	mov    (%eax),%eax
80103299:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
8010329c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032a0:	75 ee                	jne    80103290 <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032a2:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032a9:	e8 65 25 00 00       	call   80105813 <release>
  return result;
801032ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b1:	c9                   	leave  
801032b2:	c3                   	ret    

801032b3 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032b3:	55                   	push   %ebp
801032b4:	89 e5                	mov    %esp,%ebp
801032b6:	83 ec 14             	sub    $0x14,%esp
801032b9:	8b 45 08             	mov    0x8(%ebp),%eax
801032bc:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032c0:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032c4:	89 c2                	mov    %eax,%edx
801032c6:	ec                   	in     (%dx),%al
801032c7:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801032ca:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801032ce:	c9                   	leave  
801032cf:	c3                   	ret    

801032d0 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801032d0:	55                   	push   %ebp
801032d1:	89 e5                	mov    %esp,%ebp
801032d3:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801032d6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801032dd:	e8 d1 ff ff ff       	call   801032b3 <inb>
801032e2:	0f b6 c0             	movzbl %al,%eax
801032e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801032e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032eb:	83 e0 01             	and    $0x1,%eax
801032ee:	85 c0                	test   %eax,%eax
801032f0:	75 0a                	jne    801032fc <kbdgetc+0x2c>
    return -1;
801032f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801032f7:	e9 25 01 00 00       	jmp    80103421 <kbdgetc+0x151>
  data = inb(KBDATAP);
801032fc:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103303:	e8 ab ff ff ff       	call   801032b3 <inb>
80103308:	0f b6 c0             	movzbl %al,%eax
8010330b:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
8010330e:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103315:	75 17                	jne    8010332e <kbdgetc+0x5e>
    shift |= E0ESC;
80103317:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010331c:	83 c8 40             	or     $0x40,%eax
8010331f:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103324:	b8 00 00 00 00       	mov    $0x0,%eax
80103329:	e9 f3 00 00 00       	jmp    80103421 <kbdgetc+0x151>
  } else if(data & 0x80){
8010332e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103331:	25 80 00 00 00       	and    $0x80,%eax
80103336:	85 c0                	test   %eax,%eax
80103338:	74 45                	je     8010337f <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010333a:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010333f:	83 e0 40             	and    $0x40,%eax
80103342:	85 c0                	test   %eax,%eax
80103344:	75 08                	jne    8010334e <kbdgetc+0x7e>
80103346:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103349:	83 e0 7f             	and    $0x7f,%eax
8010334c:	eb 03                	jmp    80103351 <kbdgetc+0x81>
8010334e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103351:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103354:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103357:	05 20 b0 10 80       	add    $0x8010b020,%eax
8010335c:	0f b6 00             	movzbl (%eax),%eax
8010335f:	83 c8 40             	or     $0x40,%eax
80103362:	0f b6 c0             	movzbl %al,%eax
80103365:	f7 d0                	not    %eax
80103367:	89 c2                	mov    %eax,%edx
80103369:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010336e:	21 d0                	and    %edx,%eax
80103370:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103375:	b8 00 00 00 00       	mov    $0x0,%eax
8010337a:	e9 a2 00 00 00       	jmp    80103421 <kbdgetc+0x151>
  } else if(shift & E0ESC){
8010337f:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103384:	83 e0 40             	and    $0x40,%eax
80103387:	85 c0                	test   %eax,%eax
80103389:	74 14                	je     8010339f <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010338b:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103392:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103397:	83 e0 bf             	and    $0xffffffbf,%eax
8010339a:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
8010339f:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033a2:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033a7:	0f b6 00             	movzbl (%eax),%eax
801033aa:	0f b6 d0             	movzbl %al,%edx
801033ad:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033b2:	09 d0                	or     %edx,%eax
801033b4:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033bc:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033c1:	0f b6 00             	movzbl (%eax),%eax
801033c4:	0f b6 d0             	movzbl %al,%edx
801033c7:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033cc:	31 d0                	xor    %edx,%eax
801033ce:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
801033d3:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033d8:	83 e0 03             	and    $0x3,%eax
801033db:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
801033e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033e5:	01 d0                	add    %edx,%eax
801033e7:	0f b6 00             	movzbl (%eax),%eax
801033ea:	0f b6 c0             	movzbl %al,%eax
801033ed:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
801033f0:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033f5:	83 e0 08             	and    $0x8,%eax
801033f8:	85 c0                	test   %eax,%eax
801033fa:	74 22                	je     8010341e <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
801033fc:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103400:	76 0c                	jbe    8010340e <kbdgetc+0x13e>
80103402:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103406:	77 06                	ja     8010340e <kbdgetc+0x13e>
      c += 'A' - 'a';
80103408:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
8010340c:	eb 10                	jmp    8010341e <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
8010340e:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103412:	76 0a                	jbe    8010341e <kbdgetc+0x14e>
80103414:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103418:	77 04                	ja     8010341e <kbdgetc+0x14e>
      c += 'a' - 'A';
8010341a:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
8010341e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103421:	c9                   	leave  
80103422:	c3                   	ret    

80103423 <kbdintr>:

void
kbdintr(void)
{
80103423:	55                   	push   %ebp
80103424:	89 e5                	mov    %esp,%ebp
80103426:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103429:	c7 04 24 d0 32 10 80 	movl   $0x801032d0,(%esp)
80103430:	e8 93 d3 ff ff       	call   801007c8 <consoleintr>
}
80103435:	c9                   	leave  
80103436:	c3                   	ret    

80103437 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103437:	55                   	push   %ebp
80103438:	89 e5                	mov    %esp,%ebp
8010343a:	83 ec 14             	sub    $0x14,%esp
8010343d:	8b 45 08             	mov    0x8(%ebp),%eax
80103440:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103444:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103448:	89 c2                	mov    %eax,%edx
8010344a:	ec                   	in     (%dx),%al
8010344b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010344e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103452:	c9                   	leave  
80103453:	c3                   	ret    

80103454 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103454:	55                   	push   %ebp
80103455:	89 e5                	mov    %esp,%ebp
80103457:	83 ec 08             	sub    $0x8,%esp
8010345a:	8b 55 08             	mov    0x8(%ebp),%edx
8010345d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103460:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103464:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103467:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010346b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010346f:	ee                   	out    %al,(%dx)
}
80103470:	c9                   	leave  
80103471:	c3                   	ret    

80103472 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103472:	55                   	push   %ebp
80103473:	89 e5                	mov    %esp,%ebp
80103475:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103478:	9c                   	pushf  
80103479:	58                   	pop    %eax
8010347a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010347d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103480:	c9                   	leave  
80103481:	c3                   	ret    

80103482 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103482:	55                   	push   %ebp
80103483:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103485:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010348a:	8b 55 08             	mov    0x8(%ebp),%edx
8010348d:	c1 e2 02             	shl    $0x2,%edx
80103490:	01 c2                	add    %eax,%edx
80103492:	8b 45 0c             	mov    0xc(%ebp),%eax
80103495:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103497:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010349c:	83 c0 20             	add    $0x20,%eax
8010349f:	8b 00                	mov    (%eax),%eax
}
801034a1:	5d                   	pop    %ebp
801034a2:	c3                   	ret    

801034a3 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034a3:	55                   	push   %ebp
801034a4:	89 e5                	mov    %esp,%ebp
801034a6:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034a9:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034ae:	85 c0                	test   %eax,%eax
801034b0:	75 05                	jne    801034b7 <lapicinit+0x14>
    return;
801034b2:	e9 43 01 00 00       	jmp    801035fa <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034b7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034be:	00 
801034bf:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034c6:	e8 b7 ff ff ff       	call   80103482 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801034cb:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801034d2:	00 
801034d3:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801034da:	e8 a3 ff ff ff       	call   80103482 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801034df:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801034e6:	00 
801034e7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801034ee:	e8 8f ff ff ff       	call   80103482 <lapicw>
  lapicw(TICR, 10000000); 
801034f3:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
801034fa:	00 
801034fb:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103502:	e8 7b ff ff ff       	call   80103482 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103507:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010350e:	00 
8010350f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103516:	e8 67 ff ff ff       	call   80103482 <lapicw>
  lapicw(LINT1, MASKED);
8010351b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103522:	00 
80103523:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010352a:	e8 53 ff ff ff       	call   80103482 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010352f:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103534:	83 c0 30             	add    $0x30,%eax
80103537:	8b 00                	mov    (%eax),%eax
80103539:	c1 e8 10             	shr    $0x10,%eax
8010353c:	0f b6 c0             	movzbl %al,%eax
8010353f:	83 f8 03             	cmp    $0x3,%eax
80103542:	76 14                	jbe    80103558 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103544:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010354b:	00 
8010354c:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103553:	e8 2a ff ff ff       	call   80103482 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103558:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
8010355f:	00 
80103560:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103567:	e8 16 ff ff ff       	call   80103482 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010356c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103573:	00 
80103574:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010357b:	e8 02 ff ff ff       	call   80103482 <lapicw>
  lapicw(ESR, 0);
80103580:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103587:	00 
80103588:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010358f:	e8 ee fe ff ff       	call   80103482 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103594:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010359b:	00 
8010359c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035a3:	e8 da fe ff ff       	call   80103482 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035af:	00 
801035b0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035b7:	e8 c6 fe ff ff       	call   80103482 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035bc:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035c3:	00 
801035c4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801035cb:	e8 b2 fe ff ff       	call   80103482 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801035d0:	90                   	nop
801035d1:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801035d6:	05 00 03 00 00       	add    $0x300,%eax
801035db:	8b 00                	mov    (%eax),%eax
801035dd:	25 00 10 00 00       	and    $0x1000,%eax
801035e2:	85 c0                	test   %eax,%eax
801035e4:	75 eb                	jne    801035d1 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801035e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035ed:	00 
801035ee:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801035f5:	e8 88 fe ff ff       	call   80103482 <lapicw>
}
801035fa:	c9                   	leave  
801035fb:	c3                   	ret    

801035fc <cpunum>:

int
cpunum(void)
{
801035fc:	55                   	push   %ebp
801035fd:	89 e5                	mov    %esp,%ebp
801035ff:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103602:	e8 6b fe ff ff       	call   80103472 <readeflags>
80103607:	25 00 02 00 00       	and    $0x200,%eax
8010360c:	85 c0                	test   %eax,%eax
8010360e:	74 25                	je     80103635 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103610:	a1 40 d6 10 80       	mov    0x8010d640,%eax
80103615:	8d 50 01             	lea    0x1(%eax),%edx
80103618:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
8010361e:	85 c0                	test   %eax,%eax
80103620:	75 13                	jne    80103635 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103622:	8b 45 04             	mov    0x4(%ebp),%eax
80103625:	89 44 24 04          	mov    %eax,0x4(%esp)
80103629:	c7 04 24 44 9d 10 80 	movl   $0x80109d44,(%esp)
80103630:	e8 6b cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103635:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010363a:	85 c0                	test   %eax,%eax
8010363c:	74 0f                	je     8010364d <cpunum+0x51>
    return lapic[ID]>>24;
8010363e:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103643:	83 c0 20             	add    $0x20,%eax
80103646:	8b 00                	mov    (%eax),%eax
80103648:	c1 e8 18             	shr    $0x18,%eax
8010364b:	eb 05                	jmp    80103652 <cpunum+0x56>
  return 0;
8010364d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103652:	c9                   	leave  
80103653:	c3                   	ret    

80103654 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103654:	55                   	push   %ebp
80103655:	89 e5                	mov    %esp,%ebp
80103657:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010365a:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010365f:	85 c0                	test   %eax,%eax
80103661:	74 14                	je     80103677 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103663:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010366a:	00 
8010366b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103672:	e8 0b fe ff ff       	call   80103482 <lapicw>
}
80103677:	c9                   	leave  
80103678:	c3                   	ret    

80103679 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103679:	55                   	push   %ebp
8010367a:	89 e5                	mov    %esp,%ebp
}
8010367c:	5d                   	pop    %ebp
8010367d:	c3                   	ret    

8010367e <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010367e:	55                   	push   %ebp
8010367f:	89 e5                	mov    %esp,%ebp
80103681:	83 ec 1c             	sub    $0x1c,%esp
80103684:	8b 45 08             	mov    0x8(%ebp),%eax
80103687:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010368a:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103691:	00 
80103692:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103699:	e8 b6 fd ff ff       	call   80103454 <outb>
  outb(CMOS_PORT+1, 0x0A);
8010369e:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036a5:	00 
801036a6:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036ad:	e8 a2 fd ff ff       	call   80103454 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036b2:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036b9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036bc:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036c1:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036c4:	8d 50 02             	lea    0x2(%eax),%edx
801036c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801036ca:	c1 e8 04             	shr    $0x4,%eax
801036cd:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801036d0:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801036d4:	c1 e0 18             	shl    $0x18,%eax
801036d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801036db:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801036e2:	e8 9b fd ff ff       	call   80103482 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801036e7:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801036ee:	00 
801036ef:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801036f6:	e8 87 fd ff ff       	call   80103482 <lapicw>
  microdelay(200);
801036fb:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103702:	e8 72 ff ff ff       	call   80103679 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103707:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010370e:	00 
8010370f:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103716:	e8 67 fd ff ff       	call   80103482 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010371b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103722:	e8 52 ff ff ff       	call   80103679 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103727:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010372e:	eb 40                	jmp    80103770 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103730:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103734:	c1 e0 18             	shl    $0x18,%eax
80103737:	89 44 24 04          	mov    %eax,0x4(%esp)
8010373b:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103742:	e8 3b fd ff ff       	call   80103482 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103747:	8b 45 0c             	mov    0xc(%ebp),%eax
8010374a:	c1 e8 0c             	shr    $0xc,%eax
8010374d:	80 cc 06             	or     $0x6,%ah
80103750:	89 44 24 04          	mov    %eax,0x4(%esp)
80103754:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010375b:	e8 22 fd ff ff       	call   80103482 <lapicw>
    microdelay(200);
80103760:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103767:	e8 0d ff ff ff       	call   80103679 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010376c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103770:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103774:	7e ba                	jle    80103730 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103776:	c9                   	leave  
80103777:	c3                   	ret    

80103778 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103778:	55                   	push   %ebp
80103779:	89 e5                	mov    %esp,%ebp
8010377b:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010377e:	8b 45 08             	mov    0x8(%ebp),%eax
80103781:	0f b6 c0             	movzbl %al,%eax
80103784:	89 44 24 04          	mov    %eax,0x4(%esp)
80103788:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010378f:	e8 c0 fc ff ff       	call   80103454 <outb>
  microdelay(200);
80103794:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010379b:	e8 d9 fe ff ff       	call   80103679 <microdelay>

  return inb(CMOS_RETURN);
801037a0:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037a7:	e8 8b fc ff ff       	call   80103437 <inb>
801037ac:	0f b6 c0             	movzbl %al,%eax
}
801037af:	c9                   	leave  
801037b0:	c3                   	ret    

801037b1 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037b1:	55                   	push   %ebp
801037b2:	89 e5                	mov    %esp,%ebp
801037b4:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037be:	e8 b5 ff ff ff       	call   80103778 <cmos_read>
801037c3:	8b 55 08             	mov    0x8(%ebp),%edx
801037c6:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801037c8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801037cf:	e8 a4 ff ff ff       	call   80103778 <cmos_read>
801037d4:	8b 55 08             	mov    0x8(%ebp),%edx
801037d7:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801037da:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801037e1:	e8 92 ff ff ff       	call   80103778 <cmos_read>
801037e6:	8b 55 08             	mov    0x8(%ebp),%edx
801037e9:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801037ec:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801037f3:	e8 80 ff ff ff       	call   80103778 <cmos_read>
801037f8:	8b 55 08             	mov    0x8(%ebp),%edx
801037fb:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801037fe:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103805:	e8 6e ff ff ff       	call   80103778 <cmos_read>
8010380a:	8b 55 08             	mov    0x8(%ebp),%edx
8010380d:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103810:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103817:	e8 5c ff ff ff       	call   80103778 <cmos_read>
8010381c:	8b 55 08             	mov    0x8(%ebp),%edx
8010381f:	89 42 14             	mov    %eax,0x14(%edx)
}
80103822:	c9                   	leave  
80103823:	c3                   	ret    

80103824 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103824:	55                   	push   %ebp
80103825:	89 e5                	mov    %esp,%ebp
80103827:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010382a:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103831:	e8 42 ff ff ff       	call   80103778 <cmos_read>
80103836:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383c:	83 e0 04             	and    $0x4,%eax
8010383f:	85 c0                	test   %eax,%eax
80103841:	0f 94 c0             	sete   %al
80103844:	0f b6 c0             	movzbl %al,%eax
80103847:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
8010384a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010384d:	89 04 24             	mov    %eax,(%esp)
80103850:	e8 5c ff ff ff       	call   801037b1 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103855:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010385c:	e8 17 ff ff ff       	call   80103778 <cmos_read>
80103861:	25 80 00 00 00       	and    $0x80,%eax
80103866:	85 c0                	test   %eax,%eax
80103868:	74 02                	je     8010386c <cmostime+0x48>
        continue;
8010386a:	eb 36                	jmp    801038a2 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010386c:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010386f:	89 04 24             	mov    %eax,(%esp)
80103872:	e8 3a ff ff ff       	call   801037b1 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103877:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010387e:	00 
8010387f:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103882:	89 44 24 04          	mov    %eax,0x4(%esp)
80103886:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103889:	89 04 24             	mov    %eax,(%esp)
8010388c:	e8 eb 21 00 00       	call   80105a7c <memcmp>
80103891:	85 c0                	test   %eax,%eax
80103893:	75 0d                	jne    801038a2 <cmostime+0x7e>
      break;
80103895:	90                   	nop
  }

  // convert
  if (bcd) {
80103896:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010389a:	0f 84 ac 00 00 00    	je     8010394c <cmostime+0x128>
801038a0:	eb 02                	jmp    801038a4 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038a2:	eb a6                	jmp    8010384a <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038a7:	c1 e8 04             	shr    $0x4,%eax
801038aa:	89 c2                	mov    %eax,%edx
801038ac:	89 d0                	mov    %edx,%eax
801038ae:	c1 e0 02             	shl    $0x2,%eax
801038b1:	01 d0                	add    %edx,%eax
801038b3:	01 c0                	add    %eax,%eax
801038b5:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038b8:	83 e2 0f             	and    $0xf,%edx
801038bb:	01 d0                	add    %edx,%eax
801038bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038c3:	c1 e8 04             	shr    $0x4,%eax
801038c6:	89 c2                	mov    %eax,%edx
801038c8:	89 d0                	mov    %edx,%eax
801038ca:	c1 e0 02             	shl    $0x2,%eax
801038cd:	01 d0                	add    %edx,%eax
801038cf:	01 c0                	add    %eax,%eax
801038d1:	8b 55 dc             	mov    -0x24(%ebp),%edx
801038d4:	83 e2 0f             	and    $0xf,%edx
801038d7:	01 d0                	add    %edx,%eax
801038d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801038dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801038df:	c1 e8 04             	shr    $0x4,%eax
801038e2:	89 c2                	mov    %eax,%edx
801038e4:	89 d0                	mov    %edx,%eax
801038e6:	c1 e0 02             	shl    $0x2,%eax
801038e9:	01 d0                	add    %edx,%eax
801038eb:	01 c0                	add    %eax,%eax
801038ed:	8b 55 e0             	mov    -0x20(%ebp),%edx
801038f0:	83 e2 0f             	and    $0xf,%edx
801038f3:	01 d0                	add    %edx,%eax
801038f5:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801038f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801038fb:	c1 e8 04             	shr    $0x4,%eax
801038fe:	89 c2                	mov    %eax,%edx
80103900:	89 d0                	mov    %edx,%eax
80103902:	c1 e0 02             	shl    $0x2,%eax
80103905:	01 d0                	add    %edx,%eax
80103907:	01 c0                	add    %eax,%eax
80103909:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010390c:	83 e2 0f             	and    $0xf,%edx
8010390f:	01 d0                	add    %edx,%eax
80103911:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103914:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103917:	c1 e8 04             	shr    $0x4,%eax
8010391a:	89 c2                	mov    %eax,%edx
8010391c:	89 d0                	mov    %edx,%eax
8010391e:	c1 e0 02             	shl    $0x2,%eax
80103921:	01 d0                	add    %edx,%eax
80103923:	01 c0                	add    %eax,%eax
80103925:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103928:	83 e2 0f             	and    $0xf,%edx
8010392b:	01 d0                	add    %edx,%eax
8010392d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103930:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103933:	c1 e8 04             	shr    $0x4,%eax
80103936:	89 c2                	mov    %eax,%edx
80103938:	89 d0                	mov    %edx,%eax
8010393a:	c1 e0 02             	shl    $0x2,%eax
8010393d:	01 d0                	add    %edx,%eax
8010393f:	01 c0                	add    %eax,%eax
80103941:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103944:	83 e2 0f             	and    $0xf,%edx
80103947:	01 d0                	add    %edx,%eax
80103949:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010394c:	8b 45 08             	mov    0x8(%ebp),%eax
8010394f:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103952:	89 10                	mov    %edx,(%eax)
80103954:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103957:	89 50 04             	mov    %edx,0x4(%eax)
8010395a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010395d:	89 50 08             	mov    %edx,0x8(%eax)
80103960:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103963:	89 50 0c             	mov    %edx,0xc(%eax)
80103966:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103969:	89 50 10             	mov    %edx,0x10(%eax)
8010396c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010396f:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103972:	8b 45 08             	mov    0x8(%ebp),%eax
80103975:	8b 40 14             	mov    0x14(%eax),%eax
80103978:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010397e:	8b 45 08             	mov    0x8(%ebp),%eax
80103981:	89 50 14             	mov    %edx,0x14(%eax)
}
80103984:	c9                   	leave  
80103985:	c3                   	ret    

80103986 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103986:	55                   	push   %ebp
80103987:	89 e5                	mov    %esp,%ebp
80103989:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010398c:	c7 44 24 04 70 9d 10 	movl   $0x80109d70,0x4(%esp)
80103993:	80 
80103994:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
8010399b:	e8 f0 1d 00 00       	call   80105790 <initlock>
  readsb(dev, &sb);
801039a0:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801039a7:	8b 45 08             	mov    0x8(%ebp),%eax
801039aa:	89 04 24             	mov    %eax,(%esp)
801039ad:	e8 90 da ff ff       	call   80101442 <readsb>
  log.start = sb.logstart;
801039b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039b5:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039ba:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039bd:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039c2:	8b 45 08             	mov    0x8(%ebp),%eax
801039c5:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
801039ca:	e8 9a 01 00 00       	call   80103b69 <recover_from_log>
}
801039cf:	c9                   	leave  
801039d0:	c3                   	ret    

801039d1 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801039d1:	55                   	push   %ebp
801039d2:	89 e5                	mov    %esp,%ebp
801039d4:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801039d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039de:	e9 8c 00 00 00       	jmp    80103a6f <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801039e3:	8b 15 94 42 11 80    	mov    0x80114294,%edx
801039e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ec:	01 d0                	add    %edx,%eax
801039ee:	83 c0 01             	add    $0x1,%eax
801039f1:	89 c2                	mov    %eax,%edx
801039f3:	a1 a4 42 11 80       	mov    0x801142a4,%eax
801039f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801039fc:	89 04 24             	mov    %eax,(%esp)
801039ff:	e8 a2 c7 ff ff       	call   801001a6 <bread>
80103a04:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a0a:	83 c0 10             	add    $0x10,%eax
80103a0d:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a14:	89 c2                	mov    %eax,%edx
80103a16:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a1b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a1f:	89 04 24             	mov    %eax,(%esp)
80103a22:	e8 7f c7 ff ff       	call   801001a6 <bread>
80103a27:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a2d:	8d 50 18             	lea    0x18(%eax),%edx
80103a30:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a33:	83 c0 18             	add    $0x18,%eax
80103a36:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a3d:	00 
80103a3e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a42:	89 04 24             	mov    %eax,(%esp)
80103a45:	e8 8a 20 00 00       	call   80105ad4 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a4d:	89 04 24             	mov    %eax,(%esp)
80103a50:	e8 88 c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a58:	89 04 24             	mov    %eax,(%esp)
80103a5b:	e8 b7 c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a60:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a63:	89 04 24             	mov    %eax,(%esp)
80103a66:	e8 ac c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a6b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a6f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103a74:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a77:	0f 8f 66 ff ff ff    	jg     801039e3 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103a7d:	c9                   	leave  
80103a7e:	c3                   	ret    

80103a7f <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103a7f:	55                   	push   %ebp
80103a80:	89 e5                	mov    %esp,%ebp
80103a82:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103a85:	a1 94 42 11 80       	mov    0x80114294,%eax
80103a8a:	89 c2                	mov    %eax,%edx
80103a8c:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a91:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a95:	89 04 24             	mov    %eax,(%esp)
80103a98:	e8 09 c7 ff ff       	call   801001a6 <bread>
80103a9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103aa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa3:	83 c0 18             	add    $0x18,%eax
80103aa6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103aa9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aac:	8b 00                	mov    (%eax),%eax
80103aae:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103ab3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103aba:	eb 1b                	jmp    80103ad7 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103abc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103abf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ac2:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103ac6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ac9:	83 c2 10             	add    $0x10,%edx
80103acc:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103ad3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ad7:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103adc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103adf:	7f db                	jg     80103abc <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103ae1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ae4:	89 04 24             	mov    %eax,(%esp)
80103ae7:	e8 2b c7 ff ff       	call   80100217 <brelse>
}
80103aec:	c9                   	leave  
80103aed:	c3                   	ret    

80103aee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103aee:	55                   	push   %ebp
80103aef:	89 e5                	mov    %esp,%ebp
80103af1:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103af4:	a1 94 42 11 80       	mov    0x80114294,%eax
80103af9:	89 c2                	mov    %eax,%edx
80103afb:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b00:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b04:	89 04 24             	mov    %eax,(%esp)
80103b07:	e8 9a c6 ff ff       	call   801001a6 <bread>
80103b0c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b12:	83 c0 18             	add    $0x18,%eax
80103b15:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b18:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b21:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b2a:	eb 1b                	jmp    80103b47 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b2f:	83 c0 10             	add    $0x10,%eax
80103b32:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b3f:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b47:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b4c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b4f:	7f db                	jg     80103b2c <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b54:	89 04 24             	mov    %eax,(%esp)
80103b57:	e8 81 c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b5f:	89 04 24             	mov    %eax,(%esp)
80103b62:	e8 b0 c6 ff ff       	call   80100217 <brelse>
}
80103b67:	c9                   	leave  
80103b68:	c3                   	ret    

80103b69 <recover_from_log>:

static void
recover_from_log(void)
{
80103b69:	55                   	push   %ebp
80103b6a:	89 e5                	mov    %esp,%ebp
80103b6c:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103b6f:	e8 0b ff ff ff       	call   80103a7f <read_head>
  install_trans(); // if committed, copy from log to disk
80103b74:	e8 58 fe ff ff       	call   801039d1 <install_trans>
  log.lh.n = 0;
80103b79:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103b80:	00 00 00 
  write_head(); // clear the log
80103b83:	e8 66 ff ff ff       	call   80103aee <write_head>
}
80103b88:	c9                   	leave  
80103b89:	c3                   	ret    

80103b8a <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103b8a:	55                   	push   %ebp
80103b8b:	89 e5                	mov    %esp,%ebp
80103b8d:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103b90:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103b97:	e8 15 1c 00 00       	call   801057b1 <acquire>
  while(1){
    if(log.committing){
80103b9c:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103ba1:	85 c0                	test   %eax,%eax
80103ba3:	74 16                	je     80103bbb <begin_op+0x31>
      sleep(&log, &log.lock);
80103ba5:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bac:	80 
80103bad:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bb4:	e8 b0 18 00 00       	call   80105469 <sleep>
80103bb9:	eb 4f                	jmp    80103c0a <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103bbb:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103bc1:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bc6:	8d 50 01             	lea    0x1(%eax),%edx
80103bc9:	89 d0                	mov    %edx,%eax
80103bcb:	c1 e0 02             	shl    $0x2,%eax
80103bce:	01 d0                	add    %edx,%eax
80103bd0:	01 c0                	add    %eax,%eax
80103bd2:	01 c8                	add    %ecx,%eax
80103bd4:	83 f8 1e             	cmp    $0x1e,%eax
80103bd7:	7e 16                	jle    80103bef <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103bd9:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103be0:	80 
80103be1:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103be8:	e8 7c 18 00 00       	call   80105469 <sleep>
80103bed:	eb 1b                	jmp    80103c0a <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103bef:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bf4:	83 c0 01             	add    $0x1,%eax
80103bf7:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103bfc:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c03:	e8 0b 1c 00 00       	call   80105813 <release>
      break;
80103c08:	eb 02                	jmp    80103c0c <begin_op+0x82>
    }
  }
80103c0a:	eb 90                	jmp    80103b9c <begin_op+0x12>
}
80103c0c:	c9                   	leave  
80103c0d:	c3                   	ret    

80103c0e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c0e:	55                   	push   %ebp
80103c0f:	89 e5                	mov    %esp,%ebp
80103c11:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c14:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c1b:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c22:	e8 8a 1b 00 00       	call   801057b1 <acquire>
  log.outstanding -= 1;
80103c27:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c2c:	83 e8 01             	sub    $0x1,%eax
80103c2f:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c34:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c39:	85 c0                	test   %eax,%eax
80103c3b:	74 0c                	je     80103c49 <end_op+0x3b>
    panic("log.committing");
80103c3d:	c7 04 24 74 9d 10 80 	movl   $0x80109d74,(%esp)
80103c44:	e8 f1 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c49:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c4e:	85 c0                	test   %eax,%eax
80103c50:	75 13                	jne    80103c65 <end_op+0x57>
    do_commit = 1;
80103c52:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c59:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c60:	00 00 00 
80103c63:	eb 0c                	jmp    80103c71 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c65:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c6c:	e8 d4 18 00 00       	call   80105545 <wakeup>
  }
  release(&log.lock);
80103c71:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c78:	e8 96 1b 00 00       	call   80105813 <release>

  if(do_commit){
80103c7d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c81:	74 33                	je     80103cb6 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103c83:	e8 de 00 00 00       	call   80103d66 <commit>
    acquire(&log.lock);
80103c88:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c8f:	e8 1d 1b 00 00       	call   801057b1 <acquire>
    log.committing = 0;
80103c94:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103c9b:	00 00 00 
    wakeup(&log);
80103c9e:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ca5:	e8 9b 18 00 00       	call   80105545 <wakeup>
    release(&log.lock);
80103caa:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cb1:	e8 5d 1b 00 00       	call   80105813 <release>
  }
}
80103cb6:	c9                   	leave  
80103cb7:	c3                   	ret    

80103cb8 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103cb8:	55                   	push   %ebp
80103cb9:	89 e5                	mov    %esp,%ebp
80103cbb:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103cbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103cc5:	e9 8c 00 00 00       	jmp    80103d56 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103cca:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cd3:	01 d0                	add    %edx,%eax
80103cd5:	83 c0 01             	add    $0x1,%eax
80103cd8:	89 c2                	mov    %eax,%edx
80103cda:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103cdf:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ce3:	89 04 24             	mov    %eax,(%esp)
80103ce6:	e8 bb c4 ff ff       	call   801001a6 <bread>
80103ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103cee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf1:	83 c0 10             	add    $0x10,%eax
80103cf4:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103cfb:	89 c2                	mov    %eax,%edx
80103cfd:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d02:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d06:	89 04 24             	mov    %eax,(%esp)
80103d09:	e8 98 c4 ff ff       	call   801001a6 <bread>
80103d0e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d11:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d14:	8d 50 18             	lea    0x18(%eax),%edx
80103d17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d1a:	83 c0 18             	add    $0x18,%eax
80103d1d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d24:	00 
80103d25:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d29:	89 04 24             	mov    %eax,(%esp)
80103d2c:	e8 a3 1d 00 00       	call   80105ad4 <memmove>
    bwrite(to);  // write the log
80103d31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d34:	89 04 24             	mov    %eax,(%esp)
80103d37:	e8 a1 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d3c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d3f:	89 04 24             	mov    %eax,(%esp)
80103d42:	e8 d0 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d4a:	89 04 24             	mov    %eax,(%esp)
80103d4d:	e8 c5 c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d52:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d56:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d5b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d5e:	0f 8f 66 ff ff ff    	jg     80103cca <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d64:	c9                   	leave  
80103d65:	c3                   	ret    

80103d66 <commit>:

static void
commit()
{
80103d66:	55                   	push   %ebp
80103d67:	89 e5                	mov    %esp,%ebp
80103d69:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103d6c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d71:	85 c0                	test   %eax,%eax
80103d73:	7e 1e                	jle    80103d93 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103d75:	e8 3e ff ff ff       	call   80103cb8 <write_log>
    write_head();    // Write header to disk -- the real commit
80103d7a:	e8 6f fd ff ff       	call   80103aee <write_head>
    install_trans(); // Now install writes to home locations
80103d7f:	e8 4d fc ff ff       	call   801039d1 <install_trans>
    log.lh.n = 0; 
80103d84:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103d8b:	00 00 00 
    write_head();    // Erase the transaction from the log
80103d8e:	e8 5b fd ff ff       	call   80103aee <write_head>
  }
}
80103d93:	c9                   	leave  
80103d94:	c3                   	ret    

80103d95 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103d95:	55                   	push   %ebp
80103d96:	89 e5                	mov    %esp,%ebp
80103d98:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103d9b:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103da0:	83 f8 1d             	cmp    $0x1d,%eax
80103da3:	7f 12                	jg     80103db7 <log_write+0x22>
80103da5:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103daa:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103db0:	83 ea 01             	sub    $0x1,%edx
80103db3:	39 d0                	cmp    %edx,%eax
80103db5:	7c 0c                	jl     80103dc3 <log_write+0x2e>
    panic("too big a transaction");
80103db7:	c7 04 24 83 9d 10 80 	movl   $0x80109d83,(%esp)
80103dbe:	e8 77 c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103dc3:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103dc8:	85 c0                	test   %eax,%eax
80103dca:	7f 0c                	jg     80103dd8 <log_write+0x43>
    panic("log_write outside of trans");
80103dcc:	c7 04 24 99 9d 10 80 	movl   $0x80109d99,(%esp)
80103dd3:	e8 62 c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103dd8:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ddf:	e8 cd 19 00 00       	call   801057b1 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103de4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103deb:	eb 1f                	jmp    80103e0c <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df0:	83 c0 10             	add    $0x10,%eax
80103df3:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103dfa:	89 c2                	mov    %eax,%edx
80103dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80103dff:	8b 40 08             	mov    0x8(%eax),%eax
80103e02:	39 c2                	cmp    %eax,%edx
80103e04:	75 02                	jne    80103e08 <log_write+0x73>
      break;
80103e06:	eb 0e                	jmp    80103e16 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e08:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e0c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e11:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e14:	7f d7                	jg     80103ded <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e16:	8b 45 08             	mov    0x8(%ebp),%eax
80103e19:	8b 40 08             	mov    0x8(%eax),%eax
80103e1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e1f:	83 c2 10             	add    $0x10,%edx
80103e22:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e29:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e2e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e31:	75 0d                	jne    80103e40 <log_write+0xab>
    log.lh.n++;
80103e33:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e38:	83 c0 01             	add    $0x1,%eax
80103e3b:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e40:	8b 45 08             	mov    0x8(%ebp),%eax
80103e43:	8b 00                	mov    (%eax),%eax
80103e45:	83 c8 04             	or     $0x4,%eax
80103e48:	89 c2                	mov    %eax,%edx
80103e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4d:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e4f:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e56:	e8 b8 19 00 00       	call   80105813 <release>
}
80103e5b:	c9                   	leave  
80103e5c:	c3                   	ret    

80103e5d <v2p>:
80103e5d:	55                   	push   %ebp
80103e5e:	89 e5                	mov    %esp,%ebp
80103e60:	8b 45 08             	mov    0x8(%ebp),%eax
80103e63:	05 00 00 00 80       	add    $0x80000000,%eax
80103e68:	5d                   	pop    %ebp
80103e69:	c3                   	ret    

80103e6a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e6a:	55                   	push   %ebp
80103e6b:	89 e5                	mov    %esp,%ebp
80103e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e70:	05 00 00 00 80       	add    $0x80000000,%eax
80103e75:	5d                   	pop    %ebp
80103e76:	c3                   	ret    

80103e77 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103e77:	55                   	push   %ebp
80103e78:	89 e5                	mov    %esp,%ebp
80103e7a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103e7d:	8b 55 08             	mov    0x8(%ebp),%edx
80103e80:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e83:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e86:	f0 87 02             	lock xchg %eax,(%edx)
80103e89:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103e8c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103e8f:	c9                   	leave  
80103e90:	c3                   	ret    

80103e91 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103e91:	55                   	push   %ebp
80103e92:	89 e5                	mov    %esp,%ebp
80103e94:	83 e4 f0             	and    $0xfffffff0,%esp
80103e97:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103e9a:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103ea1:	80 
80103ea2:	c7 04 24 5c 0d 12 80 	movl   $0x80120d5c,(%esp)
80103ea9:	e8 1b f2 ff ff       	call   801030c9 <kinit1>
  kvmalloc();      // kernel page table
80103eae:	e8 af 47 00 00       	call   80108662 <kvmalloc>
  mpinit();        // collect info about this machine
80103eb3:	e8 41 04 00 00       	call   801042f9 <mpinit>
  lapicinit();
80103eb8:	e8 e6 f5 ff ff       	call   801034a3 <lapicinit>
  seginit();       // set up segments
80103ebd:	e8 33 41 00 00       	call   80107ff5 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103ec2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ec8:	0f b6 00             	movzbl (%eax),%eax
80103ecb:	0f b6 c0             	movzbl %al,%eax
80103ece:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ed2:	c7 04 24 b4 9d 10 80 	movl   $0x80109db4,(%esp)
80103ed9:	e8 c2 c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103ede:	e8 74 06 00 00       	call   80104557 <picinit>
  ioapicinit();    // another interrupt controller
80103ee3:	e8 d7 f0 ff ff       	call   80102fbf <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ee8:	e8 c3 cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103eed:	e8 52 34 00 00       	call   80107344 <uartinit>
  pinit();         // process table
80103ef2:	e8 6a 0b 00 00       	call   80104a61 <pinit>
  tvinit();        // trap vectors
80103ef7:	e8 62 2f 00 00       	call   80106e5e <tvinit>
  binit();         // buffer cache
80103efc:	e8 33 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f01:	e8 55 d1 ff ff       	call   8010105b <fileinit>
  ideinit();       // disk
80103f06:	e8 e6 ec ff ff       	call   80102bf1 <ideinit>
  if(!ismp)
80103f0b:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f10:	85 c0                	test   %eax,%eax
80103f12:	75 05                	jne    80103f19 <main+0x88>
    timerinit();   // uniprocessor timer
80103f14:	e8 90 2e 00 00       	call   80106da9 <timerinit>
  startothers();   // start other processors
80103f19:	e8 7f 00 00 00       	call   80103f9d <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f1e:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f25:	8e 
80103f26:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f2d:	e8 cf f1 ff ff       	call   80103101 <kinit2>
  userinit();      // first user process
80103f32:	e8 48 0c 00 00       	call   80104b7f <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f37:	e8 1a 00 00 00       	call   80103f56 <mpmain>

80103f3c <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f3c:	55                   	push   %ebp
80103f3d:	89 e5                	mov    %esp,%ebp
80103f3f:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f42:	e8 32 47 00 00       	call   80108679 <switchkvm>
  seginit();
80103f47:	e8 a9 40 00 00       	call   80107ff5 <seginit>
  lapicinit();
80103f4c:	e8 52 f5 ff ff       	call   801034a3 <lapicinit>
  mpmain();
80103f51:	e8 00 00 00 00       	call   80103f56 <mpmain>

80103f56 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f56:	55                   	push   %ebp
80103f57:	89 e5                	mov    %esp,%ebp
80103f59:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f5c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f62:	0f b6 00             	movzbl (%eax),%eax
80103f65:	0f b6 c0             	movzbl %al,%eax
80103f68:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f6c:	c7 04 24 cb 9d 10 80 	movl   $0x80109dcb,(%esp)
80103f73:	e8 28 c4 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103f78:	e8 55 30 00 00       	call   80106fd2 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103f7d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f83:	05 a8 00 00 00       	add    $0xa8,%eax
80103f88:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103f8f:	00 
80103f90:	89 04 24             	mov    %eax,(%esp)
80103f93:	e8 df fe ff ff       	call   80103e77 <xchg>
  scheduler();     // start running processes
80103f98:	e8 0e 13 00 00       	call   801052ab <scheduler>

80103f9d <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103f9d:	55                   	push   %ebp
80103f9e:	89 e5                	mov    %esp,%ebp
80103fa0:	53                   	push   %ebx
80103fa1:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fa4:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fab:	e8 ba fe ff ff       	call   80103e6a <p2v>
80103fb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fb3:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fb8:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fbc:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103fc3:	80 
80103fc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fc7:	89 04 24             	mov    %eax,(%esp)
80103fca:	e8 05 1b 00 00       	call   80105ad4 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103fcf:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80103fd6:	e9 85 00 00 00       	jmp    80104060 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103fdb:	e8 1c f6 ff ff       	call   801035fc <cpunum>
80103fe0:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103fe6:	05 60 43 11 80       	add    $0x80114360,%eax
80103feb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103fee:	75 02                	jne    80103ff2 <startothers+0x55>
      continue;
80103ff0:	eb 67                	jmp    80104059 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103ff2:	e8 29 f2 ff ff       	call   80103220 <kalloc>
80103ff7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103ffa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ffd:	83 e8 04             	sub    $0x4,%eax
80104000:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104003:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104009:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010400b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010400e:	83 e8 08             	sub    $0x8,%eax
80104011:	c7 00 3c 3f 10 80    	movl   $0x80103f3c,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104017:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010401a:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010401d:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
80104024:	e8 34 fe ff ff       	call   80103e5d <v2p>
80104029:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010402b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010402e:	89 04 24             	mov    %eax,(%esp)
80104031:	e8 27 fe ff ff       	call   80103e5d <v2p>
80104036:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104039:	0f b6 12             	movzbl (%edx),%edx
8010403c:	0f b6 d2             	movzbl %dl,%edx
8010403f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104043:	89 14 24             	mov    %edx,(%esp)
80104046:	e8 33 f6 ff ff       	call   8010367e <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010404b:	90                   	nop
8010404c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010404f:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104055:	85 c0                	test   %eax,%eax
80104057:	74 f3                	je     8010404c <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104059:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104060:	a1 40 49 11 80       	mov    0x80114940,%eax
80104065:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010406b:	05 60 43 11 80       	add    $0x80114360,%eax
80104070:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104073:	0f 87 62 ff ff ff    	ja     80103fdb <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104079:	83 c4 24             	add    $0x24,%esp
8010407c:	5b                   	pop    %ebx
8010407d:	5d                   	pop    %ebp
8010407e:	c3                   	ret    

8010407f <p2v>:
8010407f:	55                   	push   %ebp
80104080:	89 e5                	mov    %esp,%ebp
80104082:	8b 45 08             	mov    0x8(%ebp),%eax
80104085:	05 00 00 00 80       	add    $0x80000000,%eax
8010408a:	5d                   	pop    %ebp
8010408b:	c3                   	ret    

8010408c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010408c:	55                   	push   %ebp
8010408d:	89 e5                	mov    %esp,%ebp
8010408f:	83 ec 14             	sub    $0x14,%esp
80104092:	8b 45 08             	mov    0x8(%ebp),%eax
80104095:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80104099:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010409d:	89 c2                	mov    %eax,%edx
8010409f:	ec                   	in     (%dx),%al
801040a0:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040a3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040a7:	c9                   	leave  
801040a8:	c3                   	ret    

801040a9 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040a9:	55                   	push   %ebp
801040aa:	89 e5                	mov    %esp,%ebp
801040ac:	83 ec 08             	sub    $0x8,%esp
801040af:	8b 55 08             	mov    0x8(%ebp),%edx
801040b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801040b5:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040b9:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040bc:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040c0:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040c4:	ee                   	out    %al,(%dx)
}
801040c5:	c9                   	leave  
801040c6:	c3                   	ret    

801040c7 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040c7:	55                   	push   %ebp
801040c8:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040ca:	a1 44 d6 10 80       	mov    0x8010d644,%eax
801040cf:	89 c2                	mov    %eax,%edx
801040d1:	b8 60 43 11 80       	mov    $0x80114360,%eax
801040d6:	29 c2                	sub    %eax,%edx
801040d8:	89 d0                	mov    %edx,%eax
801040da:	c1 f8 02             	sar    $0x2,%eax
801040dd:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801040e3:	5d                   	pop    %ebp
801040e4:	c3                   	ret    

801040e5 <sum>:

static uchar
sum(uchar *addr, int len)
{
801040e5:	55                   	push   %ebp
801040e6:	89 e5                	mov    %esp,%ebp
801040e8:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801040eb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801040f2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801040f9:	eb 15                	jmp    80104110 <sum+0x2b>
    sum += addr[i];
801040fb:	8b 55 fc             	mov    -0x4(%ebp),%edx
801040fe:	8b 45 08             	mov    0x8(%ebp),%eax
80104101:	01 d0                	add    %edx,%eax
80104103:	0f b6 00             	movzbl (%eax),%eax
80104106:	0f b6 c0             	movzbl %al,%eax
80104109:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010410c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104110:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104113:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104116:	7c e3                	jl     801040fb <sum+0x16>
    sum += addr[i];
  return sum;
80104118:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010411b:	c9                   	leave  
8010411c:	c3                   	ret    

8010411d <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010411d:	55                   	push   %ebp
8010411e:	89 e5                	mov    %esp,%ebp
80104120:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104123:	8b 45 08             	mov    0x8(%ebp),%eax
80104126:	89 04 24             	mov    %eax,(%esp)
80104129:	e8 51 ff ff ff       	call   8010407f <p2v>
8010412e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104131:	8b 55 0c             	mov    0xc(%ebp),%edx
80104134:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104137:	01 d0                	add    %edx,%eax
80104139:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010413c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010413f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104142:	eb 3f                	jmp    80104183 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104144:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010414b:	00 
8010414c:	c7 44 24 04 dc 9d 10 	movl   $0x80109ddc,0x4(%esp)
80104153:	80 
80104154:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104157:	89 04 24             	mov    %eax,(%esp)
8010415a:	e8 1d 19 00 00       	call   80105a7c <memcmp>
8010415f:	85 c0                	test   %eax,%eax
80104161:	75 1c                	jne    8010417f <mpsearch1+0x62>
80104163:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010416a:	00 
8010416b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416e:	89 04 24             	mov    %eax,(%esp)
80104171:	e8 6f ff ff ff       	call   801040e5 <sum>
80104176:	84 c0                	test   %al,%al
80104178:	75 05                	jne    8010417f <mpsearch1+0x62>
      return (struct mp*)p;
8010417a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417d:	eb 11                	jmp    80104190 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010417f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104186:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104189:	72 b9                	jb     80104144 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010418b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104190:	c9                   	leave  
80104191:	c3                   	ret    

80104192 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80104192:	55                   	push   %ebp
80104193:	89 e5                	mov    %esp,%ebp
80104195:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80104198:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010419f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a2:	83 c0 0f             	add    $0xf,%eax
801041a5:	0f b6 00             	movzbl (%eax),%eax
801041a8:	0f b6 c0             	movzbl %al,%eax
801041ab:	c1 e0 08             	shl    $0x8,%eax
801041ae:	89 c2                	mov    %eax,%edx
801041b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b3:	83 c0 0e             	add    $0xe,%eax
801041b6:	0f b6 00             	movzbl (%eax),%eax
801041b9:	0f b6 c0             	movzbl %al,%eax
801041bc:	09 d0                	or     %edx,%eax
801041be:	c1 e0 04             	shl    $0x4,%eax
801041c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041c4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041c8:	74 21                	je     801041eb <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041ca:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041d1:	00 
801041d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041d5:	89 04 24             	mov    %eax,(%esp)
801041d8:	e8 40 ff ff ff       	call   8010411d <mpsearch1>
801041dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
801041e0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801041e4:	74 50                	je     80104236 <mpsearch+0xa4>
      return mp;
801041e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041e9:	eb 5f                	jmp    8010424a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801041eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ee:	83 c0 14             	add    $0x14,%eax
801041f1:	0f b6 00             	movzbl (%eax),%eax
801041f4:	0f b6 c0             	movzbl %al,%eax
801041f7:	c1 e0 08             	shl    $0x8,%eax
801041fa:	89 c2                	mov    %eax,%edx
801041fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ff:	83 c0 13             	add    $0x13,%eax
80104202:	0f b6 00             	movzbl (%eax),%eax
80104205:	0f b6 c0             	movzbl %al,%eax
80104208:	09 d0                	or     %edx,%eax
8010420a:	c1 e0 0a             	shl    $0xa,%eax
8010420d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104210:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104213:	2d 00 04 00 00       	sub    $0x400,%eax
80104218:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010421f:	00 
80104220:	89 04 24             	mov    %eax,(%esp)
80104223:	e8 f5 fe ff ff       	call   8010411d <mpsearch1>
80104228:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010422b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010422f:	74 05                	je     80104236 <mpsearch+0xa4>
      return mp;
80104231:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104234:	eb 14                	jmp    8010424a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104236:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010423d:	00 
8010423e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104245:	e8 d3 fe ff ff       	call   8010411d <mpsearch1>
}
8010424a:	c9                   	leave  
8010424b:	c3                   	ret    

8010424c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010424c:	55                   	push   %ebp
8010424d:	89 e5                	mov    %esp,%ebp
8010424f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104252:	e8 3b ff ff ff       	call   80104192 <mpsearch>
80104257:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010425a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010425e:	74 0a                	je     8010426a <mpconfig+0x1e>
80104260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104263:	8b 40 04             	mov    0x4(%eax),%eax
80104266:	85 c0                	test   %eax,%eax
80104268:	75 0a                	jne    80104274 <mpconfig+0x28>
    return 0;
8010426a:	b8 00 00 00 00       	mov    $0x0,%eax
8010426f:	e9 83 00 00 00       	jmp    801042f7 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104274:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104277:	8b 40 04             	mov    0x4(%eax),%eax
8010427a:	89 04 24             	mov    %eax,(%esp)
8010427d:	e8 fd fd ff ff       	call   8010407f <p2v>
80104282:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104285:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010428c:	00 
8010428d:	c7 44 24 04 e1 9d 10 	movl   $0x80109de1,0x4(%esp)
80104294:	80 
80104295:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104298:	89 04 24             	mov    %eax,(%esp)
8010429b:	e8 dc 17 00 00       	call   80105a7c <memcmp>
801042a0:	85 c0                	test   %eax,%eax
801042a2:	74 07                	je     801042ab <mpconfig+0x5f>
    return 0;
801042a4:	b8 00 00 00 00       	mov    $0x0,%eax
801042a9:	eb 4c                	jmp    801042f7 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042ae:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042b2:	3c 01                	cmp    $0x1,%al
801042b4:	74 12                	je     801042c8 <mpconfig+0x7c>
801042b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042b9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042bd:	3c 04                	cmp    $0x4,%al
801042bf:	74 07                	je     801042c8 <mpconfig+0x7c>
    return 0;
801042c1:	b8 00 00 00 00       	mov    $0x0,%eax
801042c6:	eb 2f                	jmp    801042f7 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042cb:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042cf:	0f b7 c0             	movzwl %ax,%eax
801042d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801042d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d9:	89 04 24             	mov    %eax,(%esp)
801042dc:	e8 04 fe ff ff       	call   801040e5 <sum>
801042e1:	84 c0                	test   %al,%al
801042e3:	74 07                	je     801042ec <mpconfig+0xa0>
    return 0;
801042e5:	b8 00 00 00 00       	mov    $0x0,%eax
801042ea:	eb 0b                	jmp    801042f7 <mpconfig+0xab>
  *pmp = mp;
801042ec:	8b 45 08             	mov    0x8(%ebp),%eax
801042ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042f2:	89 10                	mov    %edx,(%eax)
  return conf;
801042f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801042f7:	c9                   	leave  
801042f8:	c3                   	ret    

801042f9 <mpinit>:

void
mpinit(void)
{
801042f9:	55                   	push   %ebp
801042fa:	89 e5                	mov    %esp,%ebp
801042fc:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801042ff:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
80104306:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104309:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010430c:	89 04 24             	mov    %eax,(%esp)
8010430f:	e8 38 ff ff ff       	call   8010424c <mpconfig>
80104314:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104317:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010431b:	75 05                	jne    80104322 <mpinit+0x29>
    return;
8010431d:	e9 9c 01 00 00       	jmp    801044be <mpinit+0x1c5>
  ismp = 1;
80104322:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
80104329:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010432c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010432f:	8b 40 24             	mov    0x24(%eax),%eax
80104332:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104337:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010433a:	83 c0 2c             	add    $0x2c,%eax
8010433d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104340:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104343:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104347:	0f b7 d0             	movzwl %ax,%edx
8010434a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434d:	01 d0                	add    %edx,%eax
8010434f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104352:	e9 f4 00 00 00       	jmp    8010444b <mpinit+0x152>
    switch(*p){
80104357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435a:	0f b6 00             	movzbl (%eax),%eax
8010435d:	0f b6 c0             	movzbl %al,%eax
80104360:	83 f8 04             	cmp    $0x4,%eax
80104363:	0f 87 bf 00 00 00    	ja     80104428 <mpinit+0x12f>
80104369:	8b 04 85 24 9e 10 80 	mov    -0x7fef61dc(,%eax,4),%eax
80104370:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104372:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104375:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104378:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010437b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010437f:	0f b6 d0             	movzbl %al,%edx
80104382:	a1 40 49 11 80       	mov    0x80114940,%eax
80104387:	39 c2                	cmp    %eax,%edx
80104389:	74 2d                	je     801043b8 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010438b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010438e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104392:	0f b6 d0             	movzbl %al,%edx
80104395:	a1 40 49 11 80       	mov    0x80114940,%eax
8010439a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010439e:	89 44 24 04          	mov    %eax,0x4(%esp)
801043a2:	c7 04 24 e6 9d 10 80 	movl   $0x80109de6,(%esp)
801043a9:	e8 f2 bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043ae:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043b5:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043b8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043bb:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043bf:	0f b6 c0             	movzbl %al,%eax
801043c2:	83 e0 02             	and    $0x2,%eax
801043c5:	85 c0                	test   %eax,%eax
801043c7:	74 15                	je     801043de <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801043c9:	a1 40 49 11 80       	mov    0x80114940,%eax
801043ce:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801043d4:	05 60 43 11 80       	add    $0x80114360,%eax
801043d9:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
801043de:	8b 15 40 49 11 80    	mov    0x80114940,%edx
801043e4:	a1 40 49 11 80       	mov    0x80114940,%eax
801043e9:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801043ef:	81 c2 60 43 11 80    	add    $0x80114360,%edx
801043f5:	88 02                	mov    %al,(%edx)
      ncpu++;
801043f7:	a1 40 49 11 80       	mov    0x80114940,%eax
801043fc:	83 c0 01             	add    $0x1,%eax
801043ff:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
80104404:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104408:	eb 41                	jmp    8010444b <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010440a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010440d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104410:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104413:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104417:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
8010441c:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104420:	eb 29                	jmp    8010444b <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104422:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104426:	eb 23                	jmp    8010444b <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442b:	0f b6 00             	movzbl (%eax),%eax
8010442e:	0f b6 c0             	movzbl %al,%eax
80104431:	89 44 24 04          	mov    %eax,0x4(%esp)
80104435:	c7 04 24 04 9e 10 80 	movl   $0x80109e04,(%esp)
8010443c:	e8 5f bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104441:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104448:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010444b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104451:	0f 82 00 ff ff ff    	jb     80104357 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104457:	a1 44 43 11 80       	mov    0x80114344,%eax
8010445c:	85 c0                	test   %eax,%eax
8010445e:	75 1d                	jne    8010447d <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104460:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
80104467:	00 00 00 
    lapic = 0;
8010446a:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
80104471:	00 00 00 
    ioapicid = 0;
80104474:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
8010447b:	eb 41                	jmp    801044be <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010447d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104480:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104484:	84 c0                	test   %al,%al
80104486:	74 36                	je     801044be <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104488:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
8010448f:	00 
80104490:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104497:	e8 0d fc ff ff       	call   801040a9 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010449c:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044a3:	e8 e4 fb ff ff       	call   8010408c <inb>
801044a8:	83 c8 01             	or     $0x1,%eax
801044ab:	0f b6 c0             	movzbl %al,%eax
801044ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801044b2:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044b9:	e8 eb fb ff ff       	call   801040a9 <outb>
  }
}
801044be:	c9                   	leave  
801044bf:	c3                   	ret    

801044c0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044c0:	55                   	push   %ebp
801044c1:	89 e5                	mov    %esp,%ebp
801044c3:	83 ec 08             	sub    $0x8,%esp
801044c6:	8b 55 08             	mov    0x8(%ebp),%edx
801044c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801044cc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044d0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044d3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801044d7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801044db:	ee                   	out    %al,(%dx)
}
801044dc:	c9                   	leave  
801044dd:	c3                   	ret    

801044de <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801044de:	55                   	push   %ebp
801044df:	89 e5                	mov    %esp,%ebp
801044e1:	83 ec 0c             	sub    $0xc,%esp
801044e4:	8b 45 08             	mov    0x8(%ebp),%eax
801044e7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801044eb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801044ef:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
801044f5:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801044f9:	0f b6 c0             	movzbl %al,%eax
801044fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104500:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104507:	e8 b4 ff ff ff       	call   801044c0 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010450c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104510:	66 c1 e8 08          	shr    $0x8,%ax
80104514:	0f b6 c0             	movzbl %al,%eax
80104517:	89 44 24 04          	mov    %eax,0x4(%esp)
8010451b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104522:	e8 99 ff ff ff       	call   801044c0 <outb>
}
80104527:	c9                   	leave  
80104528:	c3                   	ret    

80104529 <picenable>:

void
picenable(int irq)
{
80104529:	55                   	push   %ebp
8010452a:	89 e5                	mov    %esp,%ebp
8010452c:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
8010452f:	8b 45 08             	mov    0x8(%ebp),%eax
80104532:	ba 01 00 00 00       	mov    $0x1,%edx
80104537:	89 c1                	mov    %eax,%ecx
80104539:	d3 e2                	shl    %cl,%edx
8010453b:	89 d0                	mov    %edx,%eax
8010453d:	f7 d0                	not    %eax
8010453f:	89 c2                	mov    %eax,%edx
80104541:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104548:	21 d0                	and    %edx,%eax
8010454a:	0f b7 c0             	movzwl %ax,%eax
8010454d:	89 04 24             	mov    %eax,(%esp)
80104550:	e8 89 ff ff ff       	call   801044de <picsetmask>
}
80104555:	c9                   	leave  
80104556:	c3                   	ret    

80104557 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104557:	55                   	push   %ebp
80104558:	89 e5                	mov    %esp,%ebp
8010455a:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
8010455d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104564:	00 
80104565:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010456c:	e8 4f ff ff ff       	call   801044c0 <outb>
  outb(IO_PIC2+1, 0xFF);
80104571:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104578:	00 
80104579:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104580:	e8 3b ff ff ff       	call   801044c0 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104585:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010458c:	00 
8010458d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104594:	e8 27 ff ff ff       	call   801044c0 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104599:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045a0:	00 
801045a1:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045a8:	e8 13 ff ff ff       	call   801044c0 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045ad:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045b4:	00 
801045b5:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045bc:	e8 ff fe ff ff       	call   801044c0 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045c1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045c8:	00 
801045c9:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045d0:	e8 eb fe ff ff       	call   801044c0 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801045d5:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045dc:	00 
801045dd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801045e4:	e8 d7 fe ff ff       	call   801044c0 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801045e9:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
801045f0:	00 
801045f1:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045f8:	e8 c3 fe ff ff       	call   801044c0 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
801045fd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104604:	00 
80104605:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010460c:	e8 af fe ff ff       	call   801044c0 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104611:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104618:	00 
80104619:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104620:	e8 9b fe ff ff       	call   801044c0 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104625:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010462c:	00 
8010462d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104634:	e8 87 fe ff ff       	call   801044c0 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104639:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104640:	00 
80104641:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104648:	e8 73 fe ff ff       	call   801044c0 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
8010464d:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104654:	00 
80104655:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010465c:	e8 5f fe ff ff       	call   801044c0 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104661:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104668:	00 
80104669:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104670:	e8 4b fe ff ff       	call   801044c0 <outb>

  if(irqmask != 0xFFFF)
80104675:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
8010467c:	66 83 f8 ff          	cmp    $0xffff,%ax
80104680:	74 12                	je     80104694 <picinit+0x13d>
    picsetmask(irqmask);
80104682:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104689:	0f b7 c0             	movzwl %ax,%eax
8010468c:	89 04 24             	mov    %eax,(%esp)
8010468f:	e8 4a fe ff ff       	call   801044de <picsetmask>
}
80104694:	c9                   	leave  
80104695:	c3                   	ret    

80104696 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104696:	55                   	push   %ebp
80104697:	89 e5                	mov    %esp,%ebp
80104699:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010469c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801046a6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801046af:	8b 10                	mov    (%eax),%edx
801046b1:	8b 45 08             	mov    0x8(%ebp),%eax
801046b4:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046b6:	e8 bc c9 ff ff       	call   80101077 <filealloc>
801046bb:	8b 55 08             	mov    0x8(%ebp),%edx
801046be:	89 02                	mov    %eax,(%edx)
801046c0:	8b 45 08             	mov    0x8(%ebp),%eax
801046c3:	8b 00                	mov    (%eax),%eax
801046c5:	85 c0                	test   %eax,%eax
801046c7:	0f 84 c8 00 00 00    	je     80104795 <pipealloc+0xff>
801046cd:	e8 a5 c9 ff ff       	call   80101077 <filealloc>
801046d2:	8b 55 0c             	mov    0xc(%ebp),%edx
801046d5:	89 02                	mov    %eax,(%edx)
801046d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801046da:	8b 00                	mov    (%eax),%eax
801046dc:	85 c0                	test   %eax,%eax
801046de:	0f 84 b1 00 00 00    	je     80104795 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801046e4:	e8 37 eb ff ff       	call   80103220 <kalloc>
801046e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046f0:	75 05                	jne    801046f7 <pipealloc+0x61>
    goto bad;
801046f2:	e9 9e 00 00 00       	jmp    80104795 <pipealloc+0xff>
  p->readopen = 1;
801046f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046fa:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104701:	00 00 00 
  p->writeopen = 1;
80104704:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104707:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010470e:	00 00 00 
  p->nwrite = 0;
80104711:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104714:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010471b:	00 00 00 
  p->nread = 0;
8010471e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104721:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104728:	00 00 00 
  initlock(&p->lock, "pipe");
8010472b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010472e:	c7 44 24 04 38 9e 10 	movl   $0x80109e38,0x4(%esp)
80104735:	80 
80104736:	89 04 24             	mov    %eax,(%esp)
80104739:	e8 52 10 00 00       	call   80105790 <initlock>
  (*f0)->type = FD_PIPE;
8010473e:	8b 45 08             	mov    0x8(%ebp),%eax
80104741:	8b 00                	mov    (%eax),%eax
80104743:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104749:	8b 45 08             	mov    0x8(%ebp),%eax
8010474c:	8b 00                	mov    (%eax),%eax
8010474e:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104752:	8b 45 08             	mov    0x8(%ebp),%eax
80104755:	8b 00                	mov    (%eax),%eax
80104757:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010475b:	8b 45 08             	mov    0x8(%ebp),%eax
8010475e:	8b 00                	mov    (%eax),%eax
80104760:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104763:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104766:	8b 45 0c             	mov    0xc(%ebp),%eax
80104769:	8b 00                	mov    (%eax),%eax
8010476b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104771:	8b 45 0c             	mov    0xc(%ebp),%eax
80104774:	8b 00                	mov    (%eax),%eax
80104776:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010477a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010477d:	8b 00                	mov    (%eax),%eax
8010477f:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104783:	8b 45 0c             	mov    0xc(%ebp),%eax
80104786:	8b 00                	mov    (%eax),%eax
80104788:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010478b:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010478e:	b8 00 00 00 00       	mov    $0x0,%eax
80104793:	eb 42                	jmp    801047d7 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104795:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104799:	74 0b                	je     801047a6 <pipealloc+0x110>
    kfree((char*)p);
8010479b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010479e:	89 04 24             	mov    %eax,(%esp)
801047a1:	e8 b8 e9 ff ff       	call   8010315e <kfree>
  if(*f0)
801047a6:	8b 45 08             	mov    0x8(%ebp),%eax
801047a9:	8b 00                	mov    (%eax),%eax
801047ab:	85 c0                	test   %eax,%eax
801047ad:	74 0d                	je     801047bc <pipealloc+0x126>
    fileclose(*f0);
801047af:	8b 45 08             	mov    0x8(%ebp),%eax
801047b2:	8b 00                	mov    (%eax),%eax
801047b4:	89 04 24             	mov    %eax,(%esp)
801047b7:	e8 63 c9 ff ff       	call   8010111f <fileclose>
  if(*f1)
801047bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801047bf:	8b 00                	mov    (%eax),%eax
801047c1:	85 c0                	test   %eax,%eax
801047c3:	74 0d                	je     801047d2 <pipealloc+0x13c>
    fileclose(*f1);
801047c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801047c8:	8b 00                	mov    (%eax),%eax
801047ca:	89 04 24             	mov    %eax,(%esp)
801047cd:	e8 4d c9 ff ff       	call   8010111f <fileclose>
  return -1;
801047d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801047d7:	c9                   	leave  
801047d8:	c3                   	ret    

801047d9 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801047d9:	55                   	push   %ebp
801047da:	89 e5                	mov    %esp,%ebp
801047dc:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801047df:	8b 45 08             	mov    0x8(%ebp),%eax
801047e2:	89 04 24             	mov    %eax,(%esp)
801047e5:	e8 c7 0f 00 00       	call   801057b1 <acquire>
  if(writable){
801047ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801047ee:	74 1f                	je     8010480f <pipeclose+0x36>
    p->writeopen = 0;
801047f0:	8b 45 08             	mov    0x8(%ebp),%eax
801047f3:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801047fa:	00 00 00 
    wakeup(&p->nread);
801047fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104800:	05 34 02 00 00       	add    $0x234,%eax
80104805:	89 04 24             	mov    %eax,(%esp)
80104808:	e8 38 0d 00 00       	call   80105545 <wakeup>
8010480d:	eb 1d                	jmp    8010482c <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010480f:	8b 45 08             	mov    0x8(%ebp),%eax
80104812:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104819:	00 00 00 
    wakeup(&p->nwrite);
8010481c:	8b 45 08             	mov    0x8(%ebp),%eax
8010481f:	05 38 02 00 00       	add    $0x238,%eax
80104824:	89 04 24             	mov    %eax,(%esp)
80104827:	e8 19 0d 00 00       	call   80105545 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010482c:	8b 45 08             	mov    0x8(%ebp),%eax
8010482f:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104835:	85 c0                	test   %eax,%eax
80104837:	75 25                	jne    8010485e <pipeclose+0x85>
80104839:	8b 45 08             	mov    0x8(%ebp),%eax
8010483c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104842:	85 c0                	test   %eax,%eax
80104844:	75 18                	jne    8010485e <pipeclose+0x85>
    release(&p->lock);
80104846:	8b 45 08             	mov    0x8(%ebp),%eax
80104849:	89 04 24             	mov    %eax,(%esp)
8010484c:	e8 c2 0f 00 00       	call   80105813 <release>
    kfree((char*)p);
80104851:	8b 45 08             	mov    0x8(%ebp),%eax
80104854:	89 04 24             	mov    %eax,(%esp)
80104857:	e8 02 e9 ff ff       	call   8010315e <kfree>
8010485c:	eb 0b                	jmp    80104869 <pipeclose+0x90>
  } else
    release(&p->lock);
8010485e:	8b 45 08             	mov    0x8(%ebp),%eax
80104861:	89 04 24             	mov    %eax,(%esp)
80104864:	e8 aa 0f 00 00       	call   80105813 <release>
}
80104869:	c9                   	leave  
8010486a:	c3                   	ret    

8010486b <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010486b:	55                   	push   %ebp
8010486c:	89 e5                	mov    %esp,%ebp
8010486e:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104871:	8b 45 08             	mov    0x8(%ebp),%eax
80104874:	89 04 24             	mov    %eax,(%esp)
80104877:	e8 35 0f 00 00       	call   801057b1 <acquire>
  for(i = 0; i < n; i++){
8010487c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104883:	e9 a6 00 00 00       	jmp    8010492e <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104888:	eb 57                	jmp    801048e1 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
8010488a:	8b 45 08             	mov    0x8(%ebp),%eax
8010488d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104893:	85 c0                	test   %eax,%eax
80104895:	74 0d                	je     801048a4 <pipewrite+0x39>
80104897:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010489d:	8b 40 24             	mov    0x24(%eax),%eax
801048a0:	85 c0                	test   %eax,%eax
801048a2:	74 15                	je     801048b9 <pipewrite+0x4e>
        release(&p->lock);
801048a4:	8b 45 08             	mov    0x8(%ebp),%eax
801048a7:	89 04 24             	mov    %eax,(%esp)
801048aa:	e8 64 0f 00 00       	call   80105813 <release>
        return -1;
801048af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048b4:	e9 9f 00 00 00       	jmp    80104958 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048b9:	8b 45 08             	mov    0x8(%ebp),%eax
801048bc:	05 34 02 00 00       	add    $0x234,%eax
801048c1:	89 04 24             	mov    %eax,(%esp)
801048c4:	e8 7c 0c 00 00       	call   80105545 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048c9:	8b 45 08             	mov    0x8(%ebp),%eax
801048cc:	8b 55 08             	mov    0x8(%ebp),%edx
801048cf:	81 c2 38 02 00 00    	add    $0x238,%edx
801048d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801048d9:	89 14 24             	mov    %edx,(%esp)
801048dc:	e8 88 0b 00 00       	call   80105469 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048e1:	8b 45 08             	mov    0x8(%ebp),%eax
801048e4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801048ea:	8b 45 08             	mov    0x8(%ebp),%eax
801048ed:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801048f3:	05 00 02 00 00       	add    $0x200,%eax
801048f8:	39 c2                	cmp    %eax,%edx
801048fa:	74 8e                	je     8010488a <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801048fc:	8b 45 08             	mov    0x8(%ebp),%eax
801048ff:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104905:	8d 48 01             	lea    0x1(%eax),%ecx
80104908:	8b 55 08             	mov    0x8(%ebp),%edx
8010490b:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104911:	25 ff 01 00 00       	and    $0x1ff,%eax
80104916:	89 c1                	mov    %eax,%ecx
80104918:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010491b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010491e:	01 d0                	add    %edx,%eax
80104920:	0f b6 10             	movzbl (%eax),%edx
80104923:	8b 45 08             	mov    0x8(%ebp),%eax
80104926:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010492a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010492e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104931:	3b 45 10             	cmp    0x10(%ebp),%eax
80104934:	0f 8c 4e ff ff ff    	jl     80104888 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010493a:	8b 45 08             	mov    0x8(%ebp),%eax
8010493d:	05 34 02 00 00       	add    $0x234,%eax
80104942:	89 04 24             	mov    %eax,(%esp)
80104945:	e8 fb 0b 00 00       	call   80105545 <wakeup>
  release(&p->lock);
8010494a:	8b 45 08             	mov    0x8(%ebp),%eax
8010494d:	89 04 24             	mov    %eax,(%esp)
80104950:	e8 be 0e 00 00       	call   80105813 <release>
  return n;
80104955:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104958:	c9                   	leave  
80104959:	c3                   	ret    

8010495a <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010495a:	55                   	push   %ebp
8010495b:	89 e5                	mov    %esp,%ebp
8010495d:	53                   	push   %ebx
8010495e:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104961:	8b 45 08             	mov    0x8(%ebp),%eax
80104964:	89 04 24             	mov    %eax,(%esp)
80104967:	e8 45 0e 00 00       	call   801057b1 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010496c:	eb 3a                	jmp    801049a8 <piperead+0x4e>
    if(proc->killed){
8010496e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104974:	8b 40 24             	mov    0x24(%eax),%eax
80104977:	85 c0                	test   %eax,%eax
80104979:	74 15                	je     80104990 <piperead+0x36>
      release(&p->lock);
8010497b:	8b 45 08             	mov    0x8(%ebp),%eax
8010497e:	89 04 24             	mov    %eax,(%esp)
80104981:	e8 8d 0e 00 00       	call   80105813 <release>
      return -1;
80104986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010498b:	e9 b5 00 00 00       	jmp    80104a45 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104990:	8b 45 08             	mov    0x8(%ebp),%eax
80104993:	8b 55 08             	mov    0x8(%ebp),%edx
80104996:	81 c2 34 02 00 00    	add    $0x234,%edx
8010499c:	89 44 24 04          	mov    %eax,0x4(%esp)
801049a0:	89 14 24             	mov    %edx,(%esp)
801049a3:	e8 c1 0a 00 00       	call   80105469 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049a8:	8b 45 08             	mov    0x8(%ebp),%eax
801049ab:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049b1:	8b 45 08             	mov    0x8(%ebp),%eax
801049b4:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049ba:	39 c2                	cmp    %eax,%edx
801049bc:	75 0d                	jne    801049cb <piperead+0x71>
801049be:	8b 45 08             	mov    0x8(%ebp),%eax
801049c1:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049c7:	85 c0                	test   %eax,%eax
801049c9:	75 a3                	jne    8010496e <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049cb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049d2:	eb 4b                	jmp    80104a1f <piperead+0xc5>
    if(p->nread == p->nwrite)
801049d4:	8b 45 08             	mov    0x8(%ebp),%eax
801049d7:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049dd:	8b 45 08             	mov    0x8(%ebp),%eax
801049e0:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049e6:	39 c2                	cmp    %eax,%edx
801049e8:	75 02                	jne    801049ec <piperead+0x92>
      break;
801049ea:	eb 3b                	jmp    80104a27 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801049ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801049f2:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801049f5:	8b 45 08             	mov    0x8(%ebp),%eax
801049f8:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801049fe:	8d 48 01             	lea    0x1(%eax),%ecx
80104a01:	8b 55 08             	mov    0x8(%ebp),%edx
80104a04:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a0a:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a0f:	89 c2                	mov    %eax,%edx
80104a11:	8b 45 08             	mov    0x8(%ebp),%eax
80104a14:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a19:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a1b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a22:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a25:	7c ad                	jl     801049d4 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a27:	8b 45 08             	mov    0x8(%ebp),%eax
80104a2a:	05 38 02 00 00       	add    $0x238,%eax
80104a2f:	89 04 24             	mov    %eax,(%esp)
80104a32:	e8 0e 0b 00 00       	call   80105545 <wakeup>
  release(&p->lock);
80104a37:	8b 45 08             	mov    0x8(%ebp),%eax
80104a3a:	89 04 24             	mov    %eax,(%esp)
80104a3d:	e8 d1 0d 00 00       	call   80105813 <release>
  return i;
80104a42:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a45:	83 c4 24             	add    $0x24,%esp
80104a48:	5b                   	pop    %ebx
80104a49:	5d                   	pop    %ebp
80104a4a:	c3                   	ret    

80104a4b <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a4b:	55                   	push   %ebp
80104a4c:	89 e5                	mov    %esp,%ebp
80104a4e:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a51:	9c                   	pushf  
80104a52:	58                   	pop    %eax
80104a53:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a56:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a59:	c9                   	leave  
80104a5a:	c3                   	ret    

80104a5b <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a5b:	55                   	push   %ebp
80104a5c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a5e:	fb                   	sti    
}
80104a5f:	5d                   	pop    %ebp
80104a60:	c3                   	ret    

80104a61 <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a61:	55                   	push   %ebp
80104a62:	89 e5                	mov    %esp,%ebp
80104a64:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a67:	c7 44 24 04 3d 9e 10 	movl   $0x80109e3d,0x4(%esp)
80104a6e:	80 
80104a6f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a76:	e8 15 0d 00 00       	call   80105790 <initlock>
}
80104a7b:	c9                   	leave  
80104a7c:	c3                   	ret    

80104a7d <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104a7d:	55                   	push   %ebp
80104a7e:	89 e5                	mov    %esp,%ebp
80104a80:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104a83:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a8a:	e8 22 0d 00 00       	call   801057b1 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a8f:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104a96:	eb 53                	jmp    80104aeb <allocproc+0x6e>
    if(p->state == UNUSED)
80104a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a9b:	8b 40 0c             	mov    0xc(%eax),%eax
80104a9e:	85 c0                	test   %eax,%eax
80104aa0:	75 42                	jne    80104ae4 <allocproc+0x67>
      goto found;
80104aa2:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa6:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104aad:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104ab2:	8d 50 01             	lea    0x1(%eax),%edx
80104ab5:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104abb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104abe:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104ac1:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104ac8:	e8 46 0d 00 00       	call   80105813 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104acd:	e8 4e e7 ff ff       	call   80103220 <kalloc>
80104ad2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ad5:	89 42 08             	mov    %eax,0x8(%edx)
80104ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104adb:	8b 40 08             	mov    0x8(%eax),%eax
80104ade:	85 c0                	test   %eax,%eax
80104ae0:	75 36                	jne    80104b18 <allocproc+0x9b>
80104ae2:	eb 23                	jmp    80104b07 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ae4:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80104aeb:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80104af2:	72 a4                	jb     80104a98 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104af4:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104afb:	e8 13 0d 00 00       	call   80105813 <release>
    return 0;
80104b00:	b8 00 00 00 00       	mov    $0x0,%eax
80104b05:	eb 76                	jmp    80104b7d <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b0a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b11:	b8 00 00 00 00       	mov    $0x0,%eax
80104b16:	eb 65                	jmp    80104b7d <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b1b:	8b 40 08             	mov    0x8(%eax),%eax
80104b1e:	05 00 10 00 00       	add    $0x1000,%eax
80104b23:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b26:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b30:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b33:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b37:	ba 19 6e 10 80       	mov    $0x80106e19,%edx
80104b3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b3f:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b41:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b48:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b4b:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b51:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b54:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b5b:	00 
80104b5c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b63:	00 
80104b64:	89 04 24             	mov    %eax,(%esp)
80104b67:	e8 99 0e 00 00       	call   80105a05 <memset>
    p->context->eip = (uint)forkret;
80104b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b72:	ba 2a 54 10 80       	mov    $0x8010542a,%edx
80104b77:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104b7d:	c9                   	leave  
80104b7e:	c3                   	ret    

80104b7f <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104b7f:	55                   	push   %ebp
80104b80:	89 e5                	mov    %esp,%ebp
80104b82:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104b85:	e8 f3 fe ff ff       	call   80104a7d <allocproc>
80104b8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104b8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b90:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104b97:	00 00 00 
    p->swapedPagesCounter = 0;
80104b9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b9d:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104ba4:	00 00 00 
    p->pageFaultCounter = 0;
80104ba7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104baa:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bb1:	00 00 00 
    p->swappedOutCounter = 0;
80104bb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bb7:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104bbe:	00 00 00 
    p->numOfPages = 0;
80104bc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc4:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104bcb:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104bce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104bd5:	e9 92 00 00 00       	jmp    80104c6c <userinit+0xed>
   	  p->pagesMetaData[i].count = 0;
80104bda:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104bdd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104be0:	89 d0                	mov    %edx,%eax
80104be2:	c1 e0 02             	shl    $0x2,%eax
80104be5:	01 d0                	add    %edx,%eax
80104be7:	c1 e0 02             	shl    $0x2,%eax
80104bea:	01 c8                	add    %ecx,%eax
80104bec:	05 9c 00 00 00       	add    $0x9c,%eax
80104bf1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104bf7:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104bfa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bfd:	89 d0                	mov    %edx,%eax
80104bff:	c1 e0 02             	shl    $0x2,%eax
80104c02:	01 d0                	add    %edx,%eax
80104c04:	c1 e0 02             	shl    $0x2,%eax
80104c07:	01 c8                	add    %ecx,%eax
80104c09:	05 90 00 00 00       	add    $0x90,%eax
80104c0e:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c14:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c1a:	89 d0                	mov    %edx,%eax
80104c1c:	c1 e0 02             	shl    $0x2,%eax
80104c1f:	01 d0                	add    %edx,%eax
80104c21:	c1 e0 02             	shl    $0x2,%eax
80104c24:	01 c8                	add    %ecx,%eax
80104c26:	05 94 00 00 00       	add    $0x94,%eax
80104c2b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c31:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c34:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c37:	89 d0                	mov    %edx,%eax
80104c39:	c1 e0 02             	shl    $0x2,%eax
80104c3c:	01 d0                	add    %edx,%eax
80104c3e:	c1 e0 02             	shl    $0x2,%eax
80104c41:	01 c8                	add    %ecx,%eax
80104c43:	05 98 00 00 00       	add    $0x98,%eax
80104c48:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c4e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c54:	89 d0                	mov    %edx,%eax
80104c56:	c1 e0 02             	shl    $0x2,%eax
80104c59:	01 d0                	add    %edx,%eax
80104c5b:	c1 e0 02             	shl    $0x2,%eax
80104c5e:	01 c8                	add    %ecx,%eax
80104c60:	05 a0 00 00 00       	add    $0xa0,%eax
80104c65:	c6 00 80             	movb   $0x80,(%eax)
    p->pageFaultCounter = 0;
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c68:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c6c:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104c70:	0f 8e 64 ff ff ff    	jle    80104bda <userinit+0x5b>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104c76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c79:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104c7e:	e8 22 39 00 00       	call   801085a5 <setupkvm>
80104c83:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c86:	89 42 04             	mov    %eax,0x4(%edx)
80104c89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c8c:	8b 40 04             	mov    0x4(%eax),%eax
80104c8f:	85 c0                	test   %eax,%eax
80104c91:	75 0c                	jne    80104c9f <userinit+0x120>
      panic("userinit: out of memory?");
80104c93:	c7 04 24 44 9e 10 80 	movl   $0x80109e44,(%esp)
80104c9a:	e8 9b b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104c9f:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104ca4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ca7:	8b 40 04             	mov    0x4(%eax),%eax
80104caa:	89 54 24 08          	mov    %edx,0x8(%esp)
80104cae:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104cb5:	80 
80104cb6:	89 04 24             	mov    %eax,(%esp)
80104cb9:	e8 3f 3b 00 00       	call   801087fd <inituvm>
    p->sz = PGSIZE;
80104cbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cc1:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104cc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cca:	8b 40 18             	mov    0x18(%eax),%eax
80104ccd:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104cd4:	00 
80104cd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cdc:	00 
80104cdd:	89 04 24             	mov    %eax,(%esp)
80104ce0:	e8 20 0d 00 00       	call   80105a05 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104ce5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce8:	8b 40 18             	mov    0x18(%eax),%eax
80104ceb:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104cf1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf4:	8b 40 18             	mov    0x18(%eax),%eax
80104cf7:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104cfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d00:	8b 40 18             	mov    0x18(%eax),%eax
80104d03:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d06:	8b 52 18             	mov    0x18(%edx),%edx
80104d09:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d0d:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d14:	8b 40 18             	mov    0x18(%eax),%eax
80104d17:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d1a:	8b 52 18             	mov    0x18(%edx),%edx
80104d1d:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d21:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d28:	8b 40 18             	mov    0x18(%eax),%eax
80104d2b:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d35:	8b 40 18             	mov    0x18(%eax),%eax
80104d38:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d42:	8b 40 18             	mov    0x18(%eax),%eax
80104d45:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d4f:	83 c0 6c             	add    $0x6c,%eax
80104d52:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d59:	00 
80104d5a:	c7 44 24 04 5d 9e 10 	movl   $0x80109e5d,0x4(%esp)
80104d61:	80 
80104d62:	89 04 24             	mov    %eax,(%esp)
80104d65:	e8 bb 0e 00 00       	call   80105c25 <safestrcpy>
  p->cwd = namei("/");
80104d6a:	c7 04 24 66 9e 10 80 	movl   $0x80109e66,(%esp)
80104d71:	e8 45 d8 ff ff       	call   801025bb <namei>
80104d76:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d79:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104d7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d7f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104d86:	e8 e2 e4 ff ff       	call   8010326d <countPages>
80104d8b:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104d90:	a1 60 49 11 80       	mov    0x80114960,%eax
80104d95:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d99:	c7 04 24 68 9e 10 80 	movl   $0x80109e68,(%esp)
80104da0:	e8 fb b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104da5:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104dac:	00 00 00 
}
80104daf:	c9                   	leave  
80104db0:	c3                   	ret    

80104db1 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104db1:	55                   	push   %ebp
80104db2:	89 e5                	mov    %esp,%ebp
80104db4:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104db7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dbd:	8b 00                	mov    (%eax),%eax
80104dbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104dc2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104dc6:	7e 3f                	jle    80104e07 <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104dc8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dcf:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104dd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dd5:	01 c1                	add    %eax,%ecx
80104dd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ddd:	8b 40 04             	mov    0x4(%eax),%eax
80104de0:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104de4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104de8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104deb:	89 54 24 04          	mov    %edx,0x4(%esp)
80104def:	89 04 24             	mov    %eax,(%esp)
80104df2:	e8 7c 3b 00 00       	call   80108973 <allocuvm>
80104df7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104dfa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104dfe:	75 4c                	jne    80104e4c <growproc+0x9b>
      return -1;
80104e00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e05:	eb 63                	jmp    80104e6a <growproc+0xb9>
  } else if(n < 0){
80104e07:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e0b:	79 3f                	jns    80104e4c <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e0d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e14:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e1a:	01 c1                	add    %eax,%ecx
80104e1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e22:	8b 40 04             	mov    0x4(%eax),%eax
80104e25:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e29:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e30:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e34:	89 04 24             	mov    %eax,(%esp)
80104e37:	e8 82 3d 00 00       	call   80108bbe <deallocuvm>
80104e3c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e3f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e43:	75 07                	jne    80104e4c <growproc+0x9b>
      return -1;
80104e45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e4a:	eb 1e                	jmp    80104e6a <growproc+0xb9>
  }
  proc->sz = sz;
80104e4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e52:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e55:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e57:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e5d:	89 04 24             	mov    %eax,(%esp)
80104e60:	e8 31 38 00 00       	call   80108696 <switchuvm>
  return 0;
80104e65:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e6a:	c9                   	leave  
80104e6b:	c3                   	ret    

80104e6c <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e6c:	55                   	push   %ebp
80104e6d:	89 e5                	mov    %esp,%ebp
80104e6f:	57                   	push   %edi
80104e70:	56                   	push   %esi
80104e71:	53                   	push   %ebx
80104e72:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e75:	e8 03 fc ff ff       	call   80104a7d <allocproc>
80104e7a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104e7d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104e81:	75 0a                	jne    80104e8d <fork+0x21>
    return -1;
80104e83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e88:	e9 ca 01 00 00       	jmp    80105057 <fork+0x1eb>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104e8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e93:	8b 10                	mov    (%eax),%edx
80104e95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e9b:	8b 40 04             	mov    0x4(%eax),%eax
80104e9e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104ea1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ea5:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ea9:	89 04 24             	mov    %eax,(%esp)
80104eac:	e8 fb 3f 00 00       	call   80108eac <copyuvm>
80104eb1:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104eb4:	89 42 04             	mov    %eax,0x4(%edx)
80104eb7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eba:	8b 40 04             	mov    0x4(%eax),%eax
80104ebd:	85 c0                	test   %eax,%eax
80104ebf:	75 2c                	jne    80104eed <fork+0x81>
    kfree(np->kstack);
80104ec1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ec4:	8b 40 08             	mov    0x8(%eax),%eax
80104ec7:	89 04 24             	mov    %eax,(%esp)
80104eca:	e8 8f e2 ff ff       	call   8010315e <kfree>
    np->kstack = 0;
80104ecf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ed2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104ed9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104edc:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104ee3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ee8:	e9 6a 01 00 00       	jmp    80105057 <fork+0x1eb>
  }
  np->sz = proc->sz;
80104eed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef3:	8b 10                	mov    (%eax),%edx
80104ef5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef8:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104efa:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f01:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f04:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f0a:	8b 50 18             	mov    0x18(%eax),%edx
80104f0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f13:	8b 40 18             	mov    0x18(%eax),%eax
80104f16:	89 c3                	mov    %eax,%ebx
80104f18:	b8 13 00 00 00       	mov    $0x13,%eax
80104f1d:	89 d7                	mov    %edx,%edi
80104f1f:	89 de                	mov    %ebx,%esi
80104f21:	89 c1                	mov    %eax,%ecx
80104f23:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f25:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f28:	8b 40 18             	mov    0x18(%eax),%eax
80104f2b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f32:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f39:	eb 3d                	jmp    80104f78 <fork+0x10c>
    if(proc->ofile[i])
80104f3b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f41:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f44:	83 c2 08             	add    $0x8,%edx
80104f47:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f4b:	85 c0                	test   %eax,%eax
80104f4d:	74 25                	je     80104f74 <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f55:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f58:	83 c2 08             	add    $0x8,%edx
80104f5b:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f5f:	89 04 24             	mov    %eax,(%esp)
80104f62:	e8 70 c1 ff ff       	call   801010d7 <filedup>
80104f67:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f6a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f6d:	83 c1 08             	add    $0x8,%ecx
80104f70:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f74:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f78:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f7c:	7e bd                	jle    80104f3b <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104f7e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f84:	8b 40 68             	mov    0x68(%eax),%eax
80104f87:	89 04 24             	mov    %eax,(%esp)
80104f8a:	e8 49 ca ff ff       	call   801019d8 <idup>
80104f8f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f92:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104f95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f9b:	8d 50 6c             	lea    0x6c(%eax),%edx
80104f9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fa1:	83 c0 6c             	add    $0x6c,%eax
80104fa4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fab:	00 
80104fac:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fb0:	89 04 24             	mov    %eax,(%esp)
80104fb3:	e8 6d 0c 00 00       	call   80105c25 <safestrcpy>

    pid = np->pid;
80104fb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fbb:	8b 40 10             	mov    0x10(%eax),%eax
80104fbe:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->memoryPagesCounter = proc->memoryPagesCounter;
80104fc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fc7:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104fcd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd0:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    np->swapedPagesCounter = proc->swapedPagesCounter;
80104fd6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fdc:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80104fe2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fe5:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
    np->pageFaultCounter = 0;
80104feb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fee:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104ff5:	00 00 00 
    np->swappedOutCounter = 0;
80104ff8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ffb:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80105002:	00 00 00 
    createSwapFile(np);
80105005:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105008:	89 04 24             	mov    %eax,(%esp)
8010500b:	e8 bc d8 ff ff       	call   801028cc <createSwapFile>
    if(proc->swapFile)
80105010:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105016:	8b 40 7c             	mov    0x7c(%eax),%eax
80105019:	85 c0                	test   %eax,%eax
8010501b:	74 15                	je     80105032 <fork+0x1c6>
      copySwapFile(proc,np);
8010501d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105023:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105026:	89 54 24 04          	mov    %edx,0x4(%esp)
8010502a:	89 04 24             	mov    %eax,(%esp)
8010502d:	e8 cf d9 ff ff       	call   80102a01 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
80105032:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105039:	e8 73 07 00 00       	call   801057b1 <acquire>
    np->state = RUNNABLE;
8010503e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105041:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
80105048:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010504f:	e8 bf 07 00 00       	call   80105813 <release>

    return pid;
80105054:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
80105057:	83 c4 2c             	add    $0x2c,%esp
8010505a:	5b                   	pop    %ebx
8010505b:	5e                   	pop    %esi
8010505c:	5f                   	pop    %edi
8010505d:	5d                   	pop    %ebp
8010505e:	c3                   	ret    

8010505f <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
8010505f:	55                   	push   %ebp
80105060:	89 e5                	mov    %esp,%ebp
80105062:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int fd;
    if(VERBOSE_PRINT == 1)
      procdump();
    if(proc == initproc)
80105065:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010506c:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105071:	39 c2                	cmp    %eax,%edx
80105073:	75 0c                	jne    80105081 <exit+0x22>
      panic("init exiting");
80105075:	c7 04 24 86 9e 10 80 	movl   $0x80109e86,(%esp)
8010507c:	e8 b9 b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
80105081:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105088:	eb 44                	jmp    801050ce <exit+0x6f>
      if(proc->ofile[fd]){
8010508a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105090:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105093:	83 c2 08             	add    $0x8,%edx
80105096:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010509a:	85 c0                	test   %eax,%eax
8010509c:	74 2c                	je     801050ca <exit+0x6b>
        fileclose(proc->ofile[fd]);
8010509e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050a4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050a7:	83 c2 08             	add    $0x8,%edx
801050aa:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050ae:	89 04 24             	mov    %eax,(%esp)
801050b1:	e8 69 c0 ff ff       	call   8010111f <fileclose>
        proc->ofile[fd] = 0;
801050b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050bc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050bf:	83 c2 08             	add    $0x8,%edx
801050c2:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801050c9:	00 
      procdump();
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050ca:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050ce:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801050d2:	7e b6                	jle    8010508a <exit+0x2b>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
801050d4:	e8 b1 ea ff ff       	call   80103b8a <begin_op>
    iput(proc->cwd);
801050d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050df:	8b 40 68             	mov    0x68(%eax),%eax
801050e2:	89 04 24             	mov    %eax,(%esp)
801050e5:	e8 d9 ca ff ff       	call   80101bc3 <iput>
    end_op();
801050ea:	e8 1f eb ff ff       	call   80103c0e <end_op>
    proc->cwd = 0;
801050ef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f5:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
801050fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105102:	89 04 24             	mov    %eax,(%esp)
80105105:	e8 b6 d5 ff ff       	call   801026c0 <removeSwapFile>
    acquire(&ptable.lock);
8010510a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105111:	e8 9b 06 00 00       	call   801057b1 <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
80105116:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010511c:	8b 40 14             	mov    0x14(%eax),%eax
8010511f:	89 04 24             	mov    %eax,(%esp)
80105122:	e8 dd 03 00 00       	call   80105504 <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105127:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
8010512e:	eb 3b                	jmp    8010516b <exit+0x10c>
      if(p->parent == proc){
80105130:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105133:	8b 50 14             	mov    0x14(%eax),%edx
80105136:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010513c:	39 c2                	cmp    %eax,%edx
8010513e:	75 24                	jne    80105164 <exit+0x105>
        p->parent = initproc;
80105140:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
80105146:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105149:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
8010514c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010514f:	8b 40 0c             	mov    0xc(%eax),%eax
80105152:	83 f8 05             	cmp    $0x5,%eax
80105155:	75 0d                	jne    80105164 <exit+0x105>
          wakeup1(initproc);
80105157:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
8010515c:	89 04 24             	mov    %eax,(%esp)
8010515f:	e8 a0 03 00 00       	call   80105504 <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105164:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
8010516b:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105172:	72 bc                	jb     80105130 <exit+0xd1>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
80105174:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010517a:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
80105181:	e8 c0 01 00 00       	call   80105346 <sched>
    panic("zombie exit");
80105186:	c7 04 24 93 9e 10 80 	movl   $0x80109e93,(%esp)
8010518d:	e8 a8 b3 ff ff       	call   8010053a <panic>

80105192 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
80105192:	55                   	push   %ebp
80105193:	89 e5                	mov    %esp,%ebp
80105195:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
80105198:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010519f:	e8 0d 06 00 00       	call   801057b1 <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
801051a4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051ab:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801051b2:	e9 a4 00 00 00       	jmp    8010525b <wait+0xc9>
        if(p->parent != proc)
801051b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ba:	8b 50 14             	mov    0x14(%eax),%edx
801051bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c3:	39 c2                	cmp    %eax,%edx
801051c5:	74 05                	je     801051cc <wait+0x3a>
          continue;
801051c7:	e9 88 00 00 00       	jmp    80105254 <wait+0xc2>
        havekids = 1;
801051cc:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
801051d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d6:	8b 40 0c             	mov    0xc(%eax),%eax
801051d9:	83 f8 05             	cmp    $0x5,%eax
801051dc:	75 76                	jne    80105254 <wait+0xc2>
        // Found one.
          pid = p->pid;
801051de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051e1:	8b 40 10             	mov    0x10(%eax),%eax
801051e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801051e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ea:	8b 40 08             	mov    0x8(%eax),%eax
801051ed:	89 04 24             	mov    %eax,(%esp)
801051f0:	e8 69 df ff ff       	call   8010315e <kfree>
          p->kstack = 0;
801051f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
801051ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105202:	8b 40 04             	mov    0x4(%eax),%eax
80105205:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105208:	89 54 24 04          	mov    %edx,0x4(%esp)
8010520c:	89 04 24             	mov    %eax,(%esp)
8010520f:	e8 ae 3b 00 00       	call   80108dc2 <freevm>
          p->state = UNUSED;
80105214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105217:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
8010521e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105221:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
80105228:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010522b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
80105232:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105235:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105239:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010523c:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
80105243:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010524a:	e8 c4 05 00 00       	call   80105813 <release>
          return pid;
8010524f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105252:	eb 55                	jmp    801052a9 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105254:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
8010525b:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105262:	0f 82 4f ff ff ff    	jb     801051b7 <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
80105268:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010526c:	74 0d                	je     8010527b <wait+0xe9>
8010526e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105274:	8b 40 24             	mov    0x24(%eax),%eax
80105277:	85 c0                	test   %eax,%eax
80105279:	74 13                	je     8010528e <wait+0xfc>
        release(&ptable.lock);
8010527b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105282:	e8 8c 05 00 00       	call   80105813 <release>
        return -1;
80105287:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010528c:	eb 1b                	jmp    801052a9 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010528e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105294:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
8010529b:	80 
8010529c:	89 04 24             	mov    %eax,(%esp)
8010529f:	e8 c5 01 00 00       	call   80105469 <sleep>
  }
801052a4:	e9 fb fe ff ff       	jmp    801051a4 <wait+0x12>
}
801052a9:	c9                   	leave  
801052aa:	c3                   	ret    

801052ab <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801052ab:	55                   	push   %ebp
801052ac:	89 e5                	mov    %esp,%ebp
801052ae:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801052b1:	e8 a5 f7 ff ff       	call   80104a5b <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801052b6:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052bd:	e8 ef 04 00 00       	call   801057b1 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052c2:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801052c9:	eb 61                	jmp    8010532c <scheduler+0x81>
      if(p->state != RUNNABLE)
801052cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ce:	8b 40 0c             	mov    0xc(%eax),%eax
801052d1:	83 f8 03             	cmp    $0x3,%eax
801052d4:	74 02                	je     801052d8 <scheduler+0x2d>
        continue;
801052d6:	eb 4d                	jmp    80105325 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052db:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e4:	89 04 24             	mov    %eax,(%esp)
801052e7:	e8 aa 33 00 00       	call   80108696 <switchuvm>
      p->state = RUNNING;
801052ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ef:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052fc:	8b 40 1c             	mov    0x1c(%eax),%eax
801052ff:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105306:	83 c2 04             	add    $0x4,%edx
80105309:	89 44 24 04          	mov    %eax,0x4(%esp)
8010530d:	89 14 24             	mov    %edx,(%esp)
80105310:	e8 81 09 00 00       	call   80105c96 <swtch>
      switchkvm();
80105315:	e8 5f 33 00 00       	call   80108679 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
8010531a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105321:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105325:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
8010532c:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105333:	72 96                	jb     801052cb <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105335:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010533c:	e8 d2 04 00 00       	call   80105813 <release>

  }
80105341:	e9 6b ff ff ff       	jmp    801052b1 <scheduler+0x6>

80105346 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105346:	55                   	push   %ebp
80105347:	89 e5                	mov    %esp,%ebp
80105349:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010534c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105353:	e8 83 05 00 00       	call   801058db <holding>
80105358:	85 c0                	test   %eax,%eax
8010535a:	75 0c                	jne    80105368 <sched+0x22>
    panic("sched ptable.lock");
8010535c:	c7 04 24 9f 9e 10 80 	movl   $0x80109e9f,(%esp)
80105363:	e8 d2 b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105368:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010536e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105374:	83 f8 01             	cmp    $0x1,%eax
80105377:	74 0c                	je     80105385 <sched+0x3f>
    panic("sched locks");
80105379:	c7 04 24 b1 9e 10 80 	movl   $0x80109eb1,(%esp)
80105380:	e8 b5 b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80105385:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538b:	8b 40 0c             	mov    0xc(%eax),%eax
8010538e:	83 f8 04             	cmp    $0x4,%eax
80105391:	75 0c                	jne    8010539f <sched+0x59>
    panic("sched running");
80105393:	c7 04 24 bd 9e 10 80 	movl   $0x80109ebd,(%esp)
8010539a:	e8 9b b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
8010539f:	e8 a7 f6 ff ff       	call   80104a4b <readeflags>
801053a4:	25 00 02 00 00       	and    $0x200,%eax
801053a9:	85 c0                	test   %eax,%eax
801053ab:	74 0c                	je     801053b9 <sched+0x73>
    panic("sched interruptible");
801053ad:	c7 04 24 cb 9e 10 80 	movl   $0x80109ecb,(%esp)
801053b4:	e8 81 b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801053b9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053bf:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053c8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053ce:	8b 40 04             	mov    0x4(%eax),%eax
801053d1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053d8:	83 c2 1c             	add    $0x1c,%edx
801053db:	89 44 24 04          	mov    %eax,0x4(%esp)
801053df:	89 14 24             	mov    %edx,(%esp)
801053e2:	e8 af 08 00 00       	call   80105c96 <swtch>
  cpu->intena = intena;
801053e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053f0:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053f6:	c9                   	leave  
801053f7:	c3                   	ret    

801053f8 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053f8:	55                   	push   %ebp
801053f9:	89 e5                	mov    %esp,%ebp
801053fb:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801053fe:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105405:	e8 a7 03 00 00       	call   801057b1 <acquire>
  proc->state = RUNNABLE;
8010540a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105410:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105417:	e8 2a ff ff ff       	call   80105346 <sched>
  release(&ptable.lock);
8010541c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105423:	e8 eb 03 00 00       	call   80105813 <release>
}
80105428:	c9                   	leave  
80105429:	c3                   	ret    

8010542a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
8010542a:	55                   	push   %ebp
8010542b:	89 e5                	mov    %esp,%ebp
8010542d:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105430:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105437:	e8 d7 03 00 00       	call   80105813 <release>

  if (first) {
8010543c:	a1 08 d0 10 80       	mov    0x8010d008,%eax
80105441:	85 c0                	test   %eax,%eax
80105443:	74 22                	je     80105467 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105445:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
8010544c:	00 00 00 
    iinit(ROOTDEV);
8010544f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105456:	e8 87 c2 ff ff       	call   801016e2 <iinit>
    initlog(ROOTDEV);
8010545b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105462:	e8 1f e5 ff ff       	call   80103986 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105467:	c9                   	leave  
80105468:	c3                   	ret    

80105469 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105469:	55                   	push   %ebp
8010546a:	89 e5                	mov    %esp,%ebp
8010546c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010546f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105475:	85 c0                	test   %eax,%eax
80105477:	75 0c                	jne    80105485 <sleep+0x1c>
    panic("sleep");
80105479:	c7 04 24 df 9e 10 80 	movl   $0x80109edf,(%esp)
80105480:	e8 b5 b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
80105485:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105489:	75 0c                	jne    80105497 <sleep+0x2e>
    panic("sleep without lk");
8010548b:	c7 04 24 e5 9e 10 80 	movl   $0x80109ee5,(%esp)
80105492:	e8 a3 b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105497:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
8010549e:	74 17                	je     801054b7 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801054a0:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054a7:	e8 05 03 00 00       	call   801057b1 <acquire>
    release(lk);
801054ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801054af:	89 04 24             	mov    %eax,(%esp)
801054b2:	e8 5c 03 00 00       	call   80105813 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801054b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bd:	8b 55 08             	mov    0x8(%ebp),%edx
801054c0:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c9:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054d0:	e8 71 fe ff ff       	call   80105346 <sched>

  // Tidy up.
  proc->chan = 0;
801054d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054db:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054e2:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054e9:	74 17                	je     80105502 <sleep+0x99>
    release(&ptable.lock);
801054eb:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054f2:	e8 1c 03 00 00       	call   80105813 <release>
    acquire(lk);
801054f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801054fa:	89 04 24             	mov    %eax,(%esp)
801054fd:	e8 af 02 00 00       	call   801057b1 <acquire>
  }
}
80105502:	c9                   	leave  
80105503:	c3                   	ret    

80105504 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105504:	55                   	push   %ebp
80105505:	89 e5                	mov    %esp,%ebp
80105507:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010550a:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
80105511:	eb 27                	jmp    8010553a <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80105513:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105516:	8b 40 0c             	mov    0xc(%eax),%eax
80105519:	83 f8 02             	cmp    $0x2,%eax
8010551c:	75 15                	jne    80105533 <wakeup1+0x2f>
8010551e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105521:	8b 40 20             	mov    0x20(%eax),%eax
80105524:	3b 45 08             	cmp    0x8(%ebp),%eax
80105527:	75 0a                	jne    80105533 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105529:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010552c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105533:	81 45 fc ec 02 00 00 	addl   $0x2ec,-0x4(%ebp)
8010553a:	81 7d fc b4 04 12 80 	cmpl   $0x801204b4,-0x4(%ebp)
80105541:	72 d0                	jb     80105513 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
80105543:	c9                   	leave  
80105544:	c3                   	ret    

80105545 <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
80105545:	55                   	push   %ebp
80105546:	89 e5                	mov    %esp,%ebp
80105548:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
8010554b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105552:	e8 5a 02 00 00       	call   801057b1 <acquire>
    wakeup1(chan);
80105557:	8b 45 08             	mov    0x8(%ebp),%eax
8010555a:	89 04 24             	mov    %eax,(%esp)
8010555d:	e8 a2 ff ff ff       	call   80105504 <wakeup1>
    release(&ptable.lock);
80105562:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105569:	e8 a5 02 00 00       	call   80105813 <release>
  }
8010556e:	c9                   	leave  
8010556f:	c3                   	ret    

80105570 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
80105570:	55                   	push   %ebp
80105571:	89 e5                	mov    %esp,%ebp
80105573:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
80105576:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010557d:	e8 2f 02 00 00       	call   801057b1 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105582:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105589:	eb 44                	jmp    801055cf <kill+0x5f>
      if(p->pid == pid){
8010558b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558e:	8b 40 10             	mov    0x10(%eax),%eax
80105591:	3b 45 08             	cmp    0x8(%ebp),%eax
80105594:	75 32                	jne    801055c8 <kill+0x58>
        p->killed = 1;
80105596:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105599:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
801055a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a3:	8b 40 0c             	mov    0xc(%eax),%eax
801055a6:	83 f8 02             	cmp    $0x2,%eax
801055a9:	75 0a                	jne    801055b5 <kill+0x45>
          p->state = RUNNABLE;
801055ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ae:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
801055b5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055bc:	e8 52 02 00 00       	call   80105813 <release>
        return 0;
801055c1:	b8 00 00 00 00       	mov    $0x0,%eax
801055c6:	eb 21                	jmp    801055e9 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055c8:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
801055cf:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
801055d6:	72 b3                	jb     8010558b <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801055d8:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055df:	e8 2f 02 00 00       	call   80105813 <release>
    return -1;
801055e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801055e9:	c9                   	leave  
801055ea:	c3                   	ret    

801055eb <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801055eb:	55                   	push   %ebp
801055ec:	89 e5                	mov    %esp,%ebp
801055ee:	57                   	push   %edi
801055ef:	56                   	push   %esi
801055f0:	53                   	push   %ebx
801055f1:	83 ec 6c             	sub    $0x6c,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055f4:	c7 45 e0 b4 49 11 80 	movl   $0x801149b4,-0x20(%ebp)
801055fb:	e9 24 01 00 00       	jmp    80105724 <procdump+0x139>
      if(p->state == UNUSED)
80105600:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105603:	8b 40 0c             	mov    0xc(%eax),%eax
80105606:	85 c0                	test   %eax,%eax
80105608:	75 05                	jne    8010560f <procdump+0x24>
        continue;
8010560a:	e9 0e 01 00 00       	jmp    8010571d <procdump+0x132>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010560f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105612:	8b 40 0c             	mov    0xc(%eax),%eax
80105615:	83 f8 05             	cmp    $0x5,%eax
80105618:	77 23                	ja     8010563d <procdump+0x52>
8010561a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010561d:	8b 40 0c             	mov    0xc(%eax),%eax
80105620:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105627:	85 c0                	test   %eax,%eax
80105629:	74 12                	je     8010563d <procdump+0x52>
        state = states[p->state];
8010562b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010562e:	8b 40 0c             	mov    0xc(%eax),%eax
80105631:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105638:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010563b:	eb 07                	jmp    80105644 <procdump+0x59>
      else
        state = "???";
8010563d:	c7 45 dc f6 9e 10 80 	movl   $0x80109ef6,-0x24(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
80105644:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105647:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
8010564d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105650:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
80105656:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105659:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
8010565f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105662:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
80105668:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010566b:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80105671:	01 c6                	add    %eax,%esi
80105673:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105676:	8b 40 10             	mov    0x10(%eax),%eax
80105679:	89 5c 24 18          	mov    %ebx,0x18(%esp)
8010567d:	89 4c 24 14          	mov    %ecx,0x14(%esp)
80105681:	89 54 24 10          	mov    %edx,0x10(%esp)
80105685:	89 74 24 0c          	mov    %esi,0xc(%esp)
80105689:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010568c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105690:	89 44 24 04          	mov    %eax,0x4(%esp)
80105694:	c7 04 24 fa 9e 10 80 	movl   $0x80109efa,(%esp)
8010569b:	e8 00 ad ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
801056a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056a3:	83 c0 6c             	add    $0x6c,%eax
801056a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801056aa:	c7 04 24 0d 9f 10 80 	movl   $0x80109f0d,(%esp)
801056b1:	e8 ea ac ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
801056b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056b9:	8b 40 0c             	mov    0xc(%eax),%eax
801056bc:	83 f8 02             	cmp    $0x2,%eax
801056bf:	75 50                	jne    80105711 <procdump+0x126>
        getcallerpcs((uint*)p->context->ebp+2, pc);
801056c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056c4:	8b 40 1c             	mov    0x1c(%eax),%eax
801056c7:	8b 40 0c             	mov    0xc(%eax),%eax
801056ca:	83 c0 08             	add    $0x8,%eax
801056cd:	8d 55 b4             	lea    -0x4c(%ebp),%edx
801056d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801056d4:	89 04 24             	mov    %eax,(%esp)
801056d7:	e8 86 01 00 00       	call   80105862 <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801056dc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801056e3:	eb 1b                	jmp    80105700 <procdump+0x115>
          cprintf(" %p", pc[i]);
801056e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801056e8:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
801056ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801056f0:	c7 04 24 10 9f 10 80 	movl   $0x80109f10,(%esp)
801056f7:	e8 a4 ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
801056fc:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80105700:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
80105704:	7f 0b                	jg     80105711 <procdump+0x126>
80105706:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105709:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
8010570d:	85 c0                	test   %eax,%eax
8010570f:	75 d4                	jne    801056e5 <procdump+0xfa>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
80105711:	c7 04 24 14 9f 10 80 	movl   $0x80109f14,(%esp)
80105718:	e8 83 ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010571d:	81 45 e0 ec 02 00 00 	addl   $0x2ec,-0x20(%ebp)
80105724:	81 7d e0 b4 04 12 80 	cmpl   $0x801204b4,-0x20(%ebp)
8010572b:	0f 82 cf fe ff ff    	jb     80105600 <procdump+0x15>
        for(i=0; i<10 && pc[i] != 0; i++)
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    cprintf("%d free pages in the system\n",countPages()*100/numOfInitializedPages);
80105731:	e8 37 db ff ff       	call   8010326d <countPages>
80105736:	6b c0 64             	imul   $0x64,%eax,%eax
80105739:	8b 3d 60 49 11 80    	mov    0x80114960,%edi
8010573f:	99                   	cltd   
80105740:	f7 ff                	idiv   %edi
80105742:	89 44 24 04          	mov    %eax,0x4(%esp)
80105746:	c7 04 24 16 9f 10 80 	movl   $0x80109f16,(%esp)
8010574d:	e8 4e ac ff ff       	call   801003a0 <cprintf>
80105752:	83 c4 6c             	add    $0x6c,%esp
80105755:	5b                   	pop    %ebx
80105756:	5e                   	pop    %esi
80105757:	5f                   	pop    %edi
80105758:	5d                   	pop    %ebp
80105759:	c3                   	ret    

8010575a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010575a:	55                   	push   %ebp
8010575b:	89 e5                	mov    %esp,%ebp
8010575d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105760:	9c                   	pushf  
80105761:	58                   	pop    %eax
80105762:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105765:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105768:	c9                   	leave  
80105769:	c3                   	ret    

8010576a <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010576a:	55                   	push   %ebp
8010576b:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010576d:	fa                   	cli    
}
8010576e:	5d                   	pop    %ebp
8010576f:	c3                   	ret    

80105770 <sti>:

static inline void
sti(void)
{
80105770:	55                   	push   %ebp
80105771:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105773:	fb                   	sti    
}
80105774:	5d                   	pop    %ebp
80105775:	c3                   	ret    

80105776 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105776:	55                   	push   %ebp
80105777:	89 e5                	mov    %esp,%ebp
80105779:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010577c:	8b 55 08             	mov    0x8(%ebp),%edx
8010577f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105782:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105785:	f0 87 02             	lock xchg %eax,(%edx)
80105788:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010578b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010578e:	c9                   	leave  
8010578f:	c3                   	ret    

80105790 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105790:	55                   	push   %ebp
80105791:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105793:	8b 45 08             	mov    0x8(%ebp),%eax
80105796:	8b 55 0c             	mov    0xc(%ebp),%edx
80105799:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010579c:	8b 45 08             	mov    0x8(%ebp),%eax
8010579f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801057a5:	8b 45 08             	mov    0x8(%ebp),%eax
801057a8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801057af:	5d                   	pop    %ebp
801057b0:	c3                   	ret    

801057b1 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801057b1:	55                   	push   %ebp
801057b2:	89 e5                	mov    %esp,%ebp
801057b4:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801057b7:	e8 49 01 00 00       	call   80105905 <pushcli>
  if(holding(lk))
801057bc:	8b 45 08             	mov    0x8(%ebp),%eax
801057bf:	89 04 24             	mov    %eax,(%esp)
801057c2:	e8 14 01 00 00       	call   801058db <holding>
801057c7:	85 c0                	test   %eax,%eax
801057c9:	74 0c                	je     801057d7 <acquire+0x26>
    panic("acquire");
801057cb:	c7 04 24 5d 9f 10 80 	movl   $0x80109f5d,(%esp)
801057d2:	e8 63 ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801057d7:	90                   	nop
801057d8:	8b 45 08             	mov    0x8(%ebp),%eax
801057db:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801057e2:	00 
801057e3:	89 04 24             	mov    %eax,(%esp)
801057e6:	e8 8b ff ff ff       	call   80105776 <xchg>
801057eb:	85 c0                	test   %eax,%eax
801057ed:	75 e9                	jne    801057d8 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801057ef:	8b 45 08             	mov    0x8(%ebp),%eax
801057f2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801057f9:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801057fc:	8b 45 08             	mov    0x8(%ebp),%eax
801057ff:	83 c0 0c             	add    $0xc,%eax
80105802:	89 44 24 04          	mov    %eax,0x4(%esp)
80105806:	8d 45 08             	lea    0x8(%ebp),%eax
80105809:	89 04 24             	mov    %eax,(%esp)
8010580c:	e8 51 00 00 00       	call   80105862 <getcallerpcs>
}
80105811:	c9                   	leave  
80105812:	c3                   	ret    

80105813 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105813:	55                   	push   %ebp
80105814:	89 e5                	mov    %esp,%ebp
80105816:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105819:	8b 45 08             	mov    0x8(%ebp),%eax
8010581c:	89 04 24             	mov    %eax,(%esp)
8010581f:	e8 b7 00 00 00       	call   801058db <holding>
80105824:	85 c0                	test   %eax,%eax
80105826:	75 0c                	jne    80105834 <release+0x21>
    panic("release");
80105828:	c7 04 24 65 9f 10 80 	movl   $0x80109f65,(%esp)
8010582f:	e8 06 ad ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105834:	8b 45 08             	mov    0x8(%ebp),%eax
80105837:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010583e:	8b 45 08             	mov    0x8(%ebp),%eax
80105841:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105848:	8b 45 08             	mov    0x8(%ebp),%eax
8010584b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105852:	00 
80105853:	89 04 24             	mov    %eax,(%esp)
80105856:	e8 1b ff ff ff       	call   80105776 <xchg>

  popcli();
8010585b:	e8 e9 00 00 00       	call   80105949 <popcli>
}
80105860:	c9                   	leave  
80105861:	c3                   	ret    

80105862 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105862:	55                   	push   %ebp
80105863:	89 e5                	mov    %esp,%ebp
80105865:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105868:	8b 45 08             	mov    0x8(%ebp),%eax
8010586b:	83 e8 08             	sub    $0x8,%eax
8010586e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105871:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105878:	eb 38                	jmp    801058b2 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010587a:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010587e:	74 38                	je     801058b8 <getcallerpcs+0x56>
80105880:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105887:	76 2f                	jbe    801058b8 <getcallerpcs+0x56>
80105889:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010588d:	74 29                	je     801058b8 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010588f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105892:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105899:	8b 45 0c             	mov    0xc(%ebp),%eax
8010589c:	01 c2                	add    %eax,%edx
8010589e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058a1:	8b 40 04             	mov    0x4(%eax),%eax
801058a4:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801058a6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058a9:	8b 00                	mov    (%eax),%eax
801058ab:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801058ae:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058b2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058b6:	7e c2                	jle    8010587a <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058b8:	eb 19                	jmp    801058d3 <getcallerpcs+0x71>
    pcs[i] = 0;
801058ba:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058bd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801058c7:	01 d0                	add    %edx,%eax
801058c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058cf:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058d3:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058d7:	7e e1                	jle    801058ba <getcallerpcs+0x58>
    pcs[i] = 0;
}
801058d9:	c9                   	leave  
801058da:	c3                   	ret    

801058db <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801058db:	55                   	push   %ebp
801058dc:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801058de:	8b 45 08             	mov    0x8(%ebp),%eax
801058e1:	8b 00                	mov    (%eax),%eax
801058e3:	85 c0                	test   %eax,%eax
801058e5:	74 17                	je     801058fe <holding+0x23>
801058e7:	8b 45 08             	mov    0x8(%ebp),%eax
801058ea:	8b 50 08             	mov    0x8(%eax),%edx
801058ed:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058f3:	39 c2                	cmp    %eax,%edx
801058f5:	75 07                	jne    801058fe <holding+0x23>
801058f7:	b8 01 00 00 00       	mov    $0x1,%eax
801058fc:	eb 05                	jmp    80105903 <holding+0x28>
801058fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105903:	5d                   	pop    %ebp
80105904:	c3                   	ret    

80105905 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105905:	55                   	push   %ebp
80105906:	89 e5                	mov    %esp,%ebp
80105908:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010590b:	e8 4a fe ff ff       	call   8010575a <readeflags>
80105910:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105913:	e8 52 fe ff ff       	call   8010576a <cli>
  if(cpu->ncli++ == 0)
80105918:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010591f:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105925:	8d 48 01             	lea    0x1(%eax),%ecx
80105928:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
8010592e:	85 c0                	test   %eax,%eax
80105930:	75 15                	jne    80105947 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105932:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105938:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010593b:	81 e2 00 02 00 00    	and    $0x200,%edx
80105941:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105947:	c9                   	leave  
80105948:	c3                   	ret    

80105949 <popcli>:

void
popcli(void)
{
80105949:	55                   	push   %ebp
8010594a:	89 e5                	mov    %esp,%ebp
8010594c:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010594f:	e8 06 fe ff ff       	call   8010575a <readeflags>
80105954:	25 00 02 00 00       	and    $0x200,%eax
80105959:	85 c0                	test   %eax,%eax
8010595b:	74 0c                	je     80105969 <popcli+0x20>
    panic("popcli - interruptible");
8010595d:	c7 04 24 6d 9f 10 80 	movl   $0x80109f6d,(%esp)
80105964:	e8 d1 ab ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105969:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010596f:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105975:	83 ea 01             	sub    $0x1,%edx
80105978:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010597e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105984:	85 c0                	test   %eax,%eax
80105986:	79 0c                	jns    80105994 <popcli+0x4b>
    panic("popcli");
80105988:	c7 04 24 84 9f 10 80 	movl   $0x80109f84,(%esp)
8010598f:	e8 a6 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105994:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010599a:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059a0:	85 c0                	test   %eax,%eax
801059a2:	75 15                	jne    801059b9 <popcli+0x70>
801059a4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059aa:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801059b0:	85 c0                	test   %eax,%eax
801059b2:	74 05                	je     801059b9 <popcli+0x70>
    sti();
801059b4:	e8 b7 fd ff ff       	call   80105770 <sti>
}
801059b9:	c9                   	leave  
801059ba:	c3                   	ret    

801059bb <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801059bb:	55                   	push   %ebp
801059bc:	89 e5                	mov    %esp,%ebp
801059be:	57                   	push   %edi
801059bf:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801059c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059c3:	8b 55 10             	mov    0x10(%ebp),%edx
801059c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801059c9:	89 cb                	mov    %ecx,%ebx
801059cb:	89 df                	mov    %ebx,%edi
801059cd:	89 d1                	mov    %edx,%ecx
801059cf:	fc                   	cld    
801059d0:	f3 aa                	rep stos %al,%es:(%edi)
801059d2:	89 ca                	mov    %ecx,%edx
801059d4:	89 fb                	mov    %edi,%ebx
801059d6:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059d9:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059dc:	5b                   	pop    %ebx
801059dd:	5f                   	pop    %edi
801059de:	5d                   	pop    %ebp
801059df:	c3                   	ret    

801059e0 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801059e0:	55                   	push   %ebp
801059e1:	89 e5                	mov    %esp,%ebp
801059e3:	57                   	push   %edi
801059e4:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801059e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059e8:	8b 55 10             	mov    0x10(%ebp),%edx
801059eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ee:	89 cb                	mov    %ecx,%ebx
801059f0:	89 df                	mov    %ebx,%edi
801059f2:	89 d1                	mov    %edx,%ecx
801059f4:	fc                   	cld    
801059f5:	f3 ab                	rep stos %eax,%es:(%edi)
801059f7:	89 ca                	mov    %ecx,%edx
801059f9:	89 fb                	mov    %edi,%ebx
801059fb:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059fe:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105a01:	5b                   	pop    %ebx
80105a02:	5f                   	pop    %edi
80105a03:	5d                   	pop    %ebp
80105a04:	c3                   	ret    

80105a05 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105a05:	55                   	push   %ebp
80105a06:	89 e5                	mov    %esp,%ebp
80105a08:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105a0b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a0e:	83 e0 03             	and    $0x3,%eax
80105a11:	85 c0                	test   %eax,%eax
80105a13:	75 49                	jne    80105a5e <memset+0x59>
80105a15:	8b 45 10             	mov    0x10(%ebp),%eax
80105a18:	83 e0 03             	and    $0x3,%eax
80105a1b:	85 c0                	test   %eax,%eax
80105a1d:	75 3f                	jne    80105a5e <memset+0x59>
    c &= 0xFF;
80105a1f:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105a26:	8b 45 10             	mov    0x10(%ebp),%eax
80105a29:	c1 e8 02             	shr    $0x2,%eax
80105a2c:	89 c2                	mov    %eax,%edx
80105a2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a31:	c1 e0 18             	shl    $0x18,%eax
80105a34:	89 c1                	mov    %eax,%ecx
80105a36:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a39:	c1 e0 10             	shl    $0x10,%eax
80105a3c:	09 c1                	or     %eax,%ecx
80105a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a41:	c1 e0 08             	shl    $0x8,%eax
80105a44:	09 c8                	or     %ecx,%eax
80105a46:	0b 45 0c             	or     0xc(%ebp),%eax
80105a49:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a51:	8b 45 08             	mov    0x8(%ebp),%eax
80105a54:	89 04 24             	mov    %eax,(%esp)
80105a57:	e8 84 ff ff ff       	call   801059e0 <stosl>
80105a5c:	eb 19                	jmp    80105a77 <memset+0x72>
  } else
    stosb(dst, c, n);
80105a5e:	8b 45 10             	mov    0x10(%ebp),%eax
80105a61:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a65:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a68:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a6c:	8b 45 08             	mov    0x8(%ebp),%eax
80105a6f:	89 04 24             	mov    %eax,(%esp)
80105a72:	e8 44 ff ff ff       	call   801059bb <stosb>
  return dst;
80105a77:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a7a:	c9                   	leave  
80105a7b:	c3                   	ret    

80105a7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a7c:	55                   	push   %ebp
80105a7d:	89 e5                	mov    %esp,%ebp
80105a7f:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a82:	8b 45 08             	mov    0x8(%ebp),%eax
80105a85:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a88:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a8b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a8e:	eb 30                	jmp    80105ac0 <memcmp+0x44>
    if(*s1 != *s2)
80105a90:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a93:	0f b6 10             	movzbl (%eax),%edx
80105a96:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a99:	0f b6 00             	movzbl (%eax),%eax
80105a9c:	38 c2                	cmp    %al,%dl
80105a9e:	74 18                	je     80105ab8 <memcmp+0x3c>
      return *s1 - *s2;
80105aa0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa3:	0f b6 00             	movzbl (%eax),%eax
80105aa6:	0f b6 d0             	movzbl %al,%edx
80105aa9:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105aac:	0f b6 00             	movzbl (%eax),%eax
80105aaf:	0f b6 c0             	movzbl %al,%eax
80105ab2:	29 c2                	sub    %eax,%edx
80105ab4:	89 d0                	mov    %edx,%eax
80105ab6:	eb 1a                	jmp    80105ad2 <memcmp+0x56>
    s1++, s2++;
80105ab8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105abc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105ac0:	8b 45 10             	mov    0x10(%ebp),%eax
80105ac3:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ac6:	89 55 10             	mov    %edx,0x10(%ebp)
80105ac9:	85 c0                	test   %eax,%eax
80105acb:	75 c3                	jne    80105a90 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105acd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ad2:	c9                   	leave  
80105ad3:	c3                   	ret    

80105ad4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105ad4:	55                   	push   %ebp
80105ad5:	89 e5                	mov    %esp,%ebp
80105ad7:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105ada:	8b 45 0c             	mov    0xc(%ebp),%eax
80105add:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105ae6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ae9:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105aec:	73 3d                	jae    80105b2b <memmove+0x57>
80105aee:	8b 45 10             	mov    0x10(%ebp),%eax
80105af1:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105af4:	01 d0                	add    %edx,%eax
80105af6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105af9:	76 30                	jbe    80105b2b <memmove+0x57>
    s += n;
80105afb:	8b 45 10             	mov    0x10(%ebp),%eax
80105afe:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105b01:	8b 45 10             	mov    0x10(%ebp),%eax
80105b04:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105b07:	eb 13                	jmp    80105b1c <memmove+0x48>
      *--d = *--s;
80105b09:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105b0d:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105b11:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b14:	0f b6 10             	movzbl (%eax),%edx
80105b17:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b1a:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105b1c:	8b 45 10             	mov    0x10(%ebp),%eax
80105b1f:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b22:	89 55 10             	mov    %edx,0x10(%ebp)
80105b25:	85 c0                	test   %eax,%eax
80105b27:	75 e0                	jne    80105b09 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105b29:	eb 26                	jmp    80105b51 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b2b:	eb 17                	jmp    80105b44 <memmove+0x70>
      *d++ = *s++;
80105b2d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b30:	8d 50 01             	lea    0x1(%eax),%edx
80105b33:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105b36:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b39:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b3c:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105b3f:	0f b6 12             	movzbl (%edx),%edx
80105b42:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b44:	8b 45 10             	mov    0x10(%ebp),%eax
80105b47:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b4a:	89 55 10             	mov    %edx,0x10(%ebp)
80105b4d:	85 c0                	test   %eax,%eax
80105b4f:	75 dc                	jne    80105b2d <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b51:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b54:	c9                   	leave  
80105b55:	c3                   	ret    

80105b56 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b56:	55                   	push   %ebp
80105b57:	89 e5                	mov    %esp,%ebp
80105b59:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b5c:	8b 45 10             	mov    0x10(%ebp),%eax
80105b5f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b63:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b66:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b6a:	8b 45 08             	mov    0x8(%ebp),%eax
80105b6d:	89 04 24             	mov    %eax,(%esp)
80105b70:	e8 5f ff ff ff       	call   80105ad4 <memmove>
}
80105b75:	c9                   	leave  
80105b76:	c3                   	ret    

80105b77 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b77:	55                   	push   %ebp
80105b78:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b7a:	eb 0c                	jmp    80105b88 <strncmp+0x11>
    n--, p++, q++;
80105b7c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b80:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b84:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b88:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b8c:	74 1a                	je     80105ba8 <strncmp+0x31>
80105b8e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b91:	0f b6 00             	movzbl (%eax),%eax
80105b94:	84 c0                	test   %al,%al
80105b96:	74 10                	je     80105ba8 <strncmp+0x31>
80105b98:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9b:	0f b6 10             	movzbl (%eax),%edx
80105b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ba1:	0f b6 00             	movzbl (%eax),%eax
80105ba4:	38 c2                	cmp    %al,%dl
80105ba6:	74 d4                	je     80105b7c <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105ba8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bac:	75 07                	jne    80105bb5 <strncmp+0x3e>
    return 0;
80105bae:	b8 00 00 00 00       	mov    $0x0,%eax
80105bb3:	eb 16                	jmp    80105bcb <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105bb5:	8b 45 08             	mov    0x8(%ebp),%eax
80105bb8:	0f b6 00             	movzbl (%eax),%eax
80105bbb:	0f b6 d0             	movzbl %al,%edx
80105bbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bc1:	0f b6 00             	movzbl (%eax),%eax
80105bc4:	0f b6 c0             	movzbl %al,%eax
80105bc7:	29 c2                	sub    %eax,%edx
80105bc9:	89 d0                	mov    %edx,%eax
}
80105bcb:	5d                   	pop    %ebp
80105bcc:	c3                   	ret    

80105bcd <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105bcd:	55                   	push   %ebp
80105bce:	89 e5                	mov    %esp,%ebp
80105bd0:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105bd3:	8b 45 08             	mov    0x8(%ebp),%eax
80105bd6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105bd9:	90                   	nop
80105bda:	8b 45 10             	mov    0x10(%ebp),%eax
80105bdd:	8d 50 ff             	lea    -0x1(%eax),%edx
80105be0:	89 55 10             	mov    %edx,0x10(%ebp)
80105be3:	85 c0                	test   %eax,%eax
80105be5:	7e 1e                	jle    80105c05 <strncpy+0x38>
80105be7:	8b 45 08             	mov    0x8(%ebp),%eax
80105bea:	8d 50 01             	lea    0x1(%eax),%edx
80105bed:	89 55 08             	mov    %edx,0x8(%ebp)
80105bf0:	8b 55 0c             	mov    0xc(%ebp),%edx
80105bf3:	8d 4a 01             	lea    0x1(%edx),%ecx
80105bf6:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105bf9:	0f b6 12             	movzbl (%edx),%edx
80105bfc:	88 10                	mov    %dl,(%eax)
80105bfe:	0f b6 00             	movzbl (%eax),%eax
80105c01:	84 c0                	test   %al,%al
80105c03:	75 d5                	jne    80105bda <strncpy+0xd>
    ;
  while(n-- > 0)
80105c05:	eb 0c                	jmp    80105c13 <strncpy+0x46>
    *s++ = 0;
80105c07:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0a:	8d 50 01             	lea    0x1(%eax),%edx
80105c0d:	89 55 08             	mov    %edx,0x8(%ebp)
80105c10:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105c13:	8b 45 10             	mov    0x10(%ebp),%eax
80105c16:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c19:	89 55 10             	mov    %edx,0x10(%ebp)
80105c1c:	85 c0                	test   %eax,%eax
80105c1e:	7f e7                	jg     80105c07 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105c20:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c23:	c9                   	leave  
80105c24:	c3                   	ret    

80105c25 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105c25:	55                   	push   %ebp
80105c26:	89 e5                	mov    %esp,%ebp
80105c28:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c2b:	8b 45 08             	mov    0x8(%ebp),%eax
80105c2e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105c31:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c35:	7f 05                	jg     80105c3c <safestrcpy+0x17>
    return os;
80105c37:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c3a:	eb 31                	jmp    80105c6d <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105c3c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c40:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c44:	7e 1e                	jle    80105c64 <safestrcpy+0x3f>
80105c46:	8b 45 08             	mov    0x8(%ebp),%eax
80105c49:	8d 50 01             	lea    0x1(%eax),%edx
80105c4c:	89 55 08             	mov    %edx,0x8(%ebp)
80105c4f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c52:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c55:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c58:	0f b6 12             	movzbl (%edx),%edx
80105c5b:	88 10                	mov    %dl,(%eax)
80105c5d:	0f b6 00             	movzbl (%eax),%eax
80105c60:	84 c0                	test   %al,%al
80105c62:	75 d8                	jne    80105c3c <safestrcpy+0x17>
    ;
  *s = 0;
80105c64:	8b 45 08             	mov    0x8(%ebp),%eax
80105c67:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c6a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c6d:	c9                   	leave  
80105c6e:	c3                   	ret    

80105c6f <strlen>:

int
strlen(const char *s)
{
80105c6f:	55                   	push   %ebp
80105c70:	89 e5                	mov    %esp,%ebp
80105c72:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c75:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c7c:	eb 04                	jmp    80105c82 <strlen+0x13>
80105c7e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c82:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c85:	8b 45 08             	mov    0x8(%ebp),%eax
80105c88:	01 d0                	add    %edx,%eax
80105c8a:	0f b6 00             	movzbl (%eax),%eax
80105c8d:	84 c0                	test   %al,%al
80105c8f:	75 ed                	jne    80105c7e <strlen+0xf>
    ;
  return n;
80105c91:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c94:	c9                   	leave  
80105c95:	c3                   	ret    

80105c96 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c96:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c9a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105c9e:	55                   	push   %ebp
  pushl %ebx
80105c9f:	53                   	push   %ebx
  pushl %esi
80105ca0:	56                   	push   %esi
  pushl %edi
80105ca1:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105ca2:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105ca4:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105ca6:	5f                   	pop    %edi
  popl %esi
80105ca7:	5e                   	pop    %esi
  popl %ebx
80105ca8:	5b                   	pop    %ebx
  popl %ebp
80105ca9:	5d                   	pop    %ebp
  ret
80105caa:	c3                   	ret    

80105cab <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105cab:	55                   	push   %ebp
80105cac:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105cae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cb4:	8b 00                	mov    (%eax),%eax
80105cb6:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cb9:	76 12                	jbe    80105ccd <fetchint+0x22>
80105cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80105cbe:	8d 50 04             	lea    0x4(%eax),%edx
80105cc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cc7:	8b 00                	mov    (%eax),%eax
80105cc9:	39 c2                	cmp    %eax,%edx
80105ccb:	76 07                	jbe    80105cd4 <fetchint+0x29>
    return -1;
80105ccd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cd2:	eb 0f                	jmp    80105ce3 <fetchint+0x38>
  *ip = *(int*)(addr);
80105cd4:	8b 45 08             	mov    0x8(%ebp),%eax
80105cd7:	8b 10                	mov    (%eax),%edx
80105cd9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cdc:	89 10                	mov    %edx,(%eax)
  return 0;
80105cde:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ce3:	5d                   	pop    %ebp
80105ce4:	c3                   	ret    

80105ce5 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105ce5:	55                   	push   %ebp
80105ce6:	89 e5                	mov    %esp,%ebp
80105ce8:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105ceb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf1:	8b 00                	mov    (%eax),%eax
80105cf3:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cf6:	77 07                	ja     80105cff <fetchstr+0x1a>
    return -1;
80105cf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cfd:	eb 46                	jmp    80105d45 <fetchstr+0x60>
  *pp = (char*)addr;
80105cff:	8b 55 08             	mov    0x8(%ebp),%edx
80105d02:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d05:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105d07:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d0d:	8b 00                	mov    (%eax),%eax
80105d0f:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105d12:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d15:	8b 00                	mov    (%eax),%eax
80105d17:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105d1a:	eb 1c                	jmp    80105d38 <fetchstr+0x53>
    if(*s == 0)
80105d1c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d1f:	0f b6 00             	movzbl (%eax),%eax
80105d22:	84 c0                	test   %al,%al
80105d24:	75 0e                	jne    80105d34 <fetchstr+0x4f>
      return s - *pp;
80105d26:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d29:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d2c:	8b 00                	mov    (%eax),%eax
80105d2e:	29 c2                	sub    %eax,%edx
80105d30:	89 d0                	mov    %edx,%eax
80105d32:	eb 11                	jmp    80105d45 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105d34:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d38:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d3b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d3e:	72 dc                	jb     80105d1c <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105d40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d45:	c9                   	leave  
80105d46:	c3                   	ret    

80105d47 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d47:	55                   	push   %ebp
80105d48:	89 e5                	mov    %esp,%ebp
80105d4a:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d4d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d53:	8b 40 18             	mov    0x18(%eax),%eax
80105d56:	8b 50 44             	mov    0x44(%eax),%edx
80105d59:	8b 45 08             	mov    0x8(%ebp),%eax
80105d5c:	c1 e0 02             	shl    $0x2,%eax
80105d5f:	01 d0                	add    %edx,%eax
80105d61:	8d 50 04             	lea    0x4(%eax),%edx
80105d64:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d67:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d6b:	89 14 24             	mov    %edx,(%esp)
80105d6e:	e8 38 ff ff ff       	call   80105cab <fetchint>
}
80105d73:	c9                   	leave  
80105d74:	c3                   	ret    

80105d75 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d75:	55                   	push   %ebp
80105d76:	89 e5                	mov    %esp,%ebp
80105d78:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d7b:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d82:	8b 45 08             	mov    0x8(%ebp),%eax
80105d85:	89 04 24             	mov    %eax,(%esp)
80105d88:	e8 ba ff ff ff       	call   80105d47 <argint>
80105d8d:	85 c0                	test   %eax,%eax
80105d8f:	79 07                	jns    80105d98 <argptr+0x23>
    return -1;
80105d91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d96:	eb 3d                	jmp    80105dd5 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d98:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d9b:	89 c2                	mov    %eax,%edx
80105d9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105da3:	8b 00                	mov    (%eax),%eax
80105da5:	39 c2                	cmp    %eax,%edx
80105da7:	73 16                	jae    80105dbf <argptr+0x4a>
80105da9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dac:	89 c2                	mov    %eax,%edx
80105dae:	8b 45 10             	mov    0x10(%ebp),%eax
80105db1:	01 c2                	add    %eax,%edx
80105db3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105db9:	8b 00                	mov    (%eax),%eax
80105dbb:	39 c2                	cmp    %eax,%edx
80105dbd:	76 07                	jbe    80105dc6 <argptr+0x51>
    return -1;
80105dbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dc4:	eb 0f                	jmp    80105dd5 <argptr+0x60>
  *pp = (char*)i;
80105dc6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dc9:	89 c2                	mov    %eax,%edx
80105dcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dce:	89 10                	mov    %edx,(%eax)
  return 0;
80105dd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dd5:	c9                   	leave  
80105dd6:	c3                   	ret    

80105dd7 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105dd7:	55                   	push   %ebp
80105dd8:	89 e5                	mov    %esp,%ebp
80105dda:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105ddd:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105de0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de4:	8b 45 08             	mov    0x8(%ebp),%eax
80105de7:	89 04 24             	mov    %eax,(%esp)
80105dea:	e8 58 ff ff ff       	call   80105d47 <argint>
80105def:	85 c0                	test   %eax,%eax
80105df1:	79 07                	jns    80105dfa <argstr+0x23>
    return -1;
80105df3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105df8:	eb 12                	jmp    80105e0c <argstr+0x35>
  return fetchstr(addr, pp);
80105dfa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dfd:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e00:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e04:	89 04 24             	mov    %eax,(%esp)
80105e07:	e8 d9 fe ff ff       	call   80105ce5 <fetchstr>
}
80105e0c:	c9                   	leave  
80105e0d:	c3                   	ret    

80105e0e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105e0e:	55                   	push   %ebp
80105e0f:	89 e5                	mov    %esp,%ebp
80105e11:	53                   	push   %ebx
80105e12:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105e15:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e1b:	8b 40 18             	mov    0x18(%eax),%eax
80105e1e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e21:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105e24:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e28:	7e 30                	jle    80105e5a <syscall+0x4c>
80105e2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e2d:	83 f8 15             	cmp    $0x15,%eax
80105e30:	77 28                	ja     80105e5a <syscall+0x4c>
80105e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e35:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e3c:	85 c0                	test   %eax,%eax
80105e3e:	74 1a                	je     80105e5a <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105e40:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e46:	8b 58 18             	mov    0x18(%eax),%ebx
80105e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e4c:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e53:	ff d0                	call   *%eax
80105e55:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e58:	eb 3d                	jmp    80105e97 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e60:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e63:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e69:	8b 40 10             	mov    0x10(%eax),%eax
80105e6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e6f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e77:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e7b:	c7 04 24 8b 9f 10 80 	movl   $0x80109f8b,(%esp)
80105e82:	e8 19 a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e8d:	8b 40 18             	mov    0x18(%eax),%eax
80105e90:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e97:	83 c4 24             	add    $0x24,%esp
80105e9a:	5b                   	pop    %ebx
80105e9b:	5d                   	pop    %ebp
80105e9c:	c3                   	ret    

80105e9d <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105e9d:	55                   	push   %ebp
80105e9e:	89 e5                	mov    %esp,%ebp
80105ea0:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105ea3:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ea6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80105ead:	89 04 24             	mov    %eax,(%esp)
80105eb0:	e8 92 fe ff ff       	call   80105d47 <argint>
80105eb5:	85 c0                	test   %eax,%eax
80105eb7:	79 07                	jns    80105ec0 <argfd+0x23>
    return -1;
80105eb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ebe:	eb 50                	jmp    80105f10 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105ec0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec3:	85 c0                	test   %eax,%eax
80105ec5:	78 21                	js     80105ee8 <argfd+0x4b>
80105ec7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eca:	83 f8 0f             	cmp    $0xf,%eax
80105ecd:	7f 19                	jg     80105ee8 <argfd+0x4b>
80105ecf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ed5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ed8:	83 c2 08             	add    $0x8,%edx
80105edb:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105edf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ee2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ee6:	75 07                	jne    80105eef <argfd+0x52>
    return -1;
80105ee8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eed:	eb 21                	jmp    80105f10 <argfd+0x73>
  if(pfd)
80105eef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105ef3:	74 08                	je     80105efd <argfd+0x60>
    *pfd = fd;
80105ef5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ef8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105efb:	89 10                	mov    %edx,(%eax)
  if(pf)
80105efd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f01:	74 08                	je     80105f0b <argfd+0x6e>
    *pf = f;
80105f03:	8b 45 10             	mov    0x10(%ebp),%eax
80105f06:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f09:	89 10                	mov    %edx,(%eax)
  return 0;
80105f0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f10:	c9                   	leave  
80105f11:	c3                   	ret    

80105f12 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105f12:	55                   	push   %ebp
80105f13:	89 e5                	mov    %esp,%ebp
80105f15:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f18:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f1f:	eb 30                	jmp    80105f51 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f27:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f2a:	83 c2 08             	add    $0x8,%edx
80105f2d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f31:	85 c0                	test   %eax,%eax
80105f33:	75 18                	jne    80105f4d <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f3b:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f3e:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f41:	8b 55 08             	mov    0x8(%ebp),%edx
80105f44:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f48:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f4b:	eb 0f                	jmp    80105f5c <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f4d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f51:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f55:	7e ca                	jle    80105f21 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f5c:	c9                   	leave  
80105f5d:	c3                   	ret    

80105f5e <sys_dup>:

int
sys_dup(void)
{
80105f5e:	55                   	push   %ebp
80105f5f:	89 e5                	mov    %esp,%ebp
80105f61:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f64:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f67:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f6b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f72:	00 
80105f73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f7a:	e8 1e ff ff ff       	call   80105e9d <argfd>
80105f7f:	85 c0                	test   %eax,%eax
80105f81:	79 07                	jns    80105f8a <sys_dup+0x2c>
    return -1;
80105f83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f88:	eb 29                	jmp    80105fb3 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f8d:	89 04 24             	mov    %eax,(%esp)
80105f90:	e8 7d ff ff ff       	call   80105f12 <fdalloc>
80105f95:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f98:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f9c:	79 07                	jns    80105fa5 <sys_dup+0x47>
    return -1;
80105f9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa3:	eb 0e                	jmp    80105fb3 <sys_dup+0x55>
  filedup(f);
80105fa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa8:	89 04 24             	mov    %eax,(%esp)
80105fab:	e8 27 b1 ff ff       	call   801010d7 <filedup>
  return fd;
80105fb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105fb3:	c9                   	leave  
80105fb4:	c3                   	ret    

80105fb5 <sys_read>:

int
sys_read(void)
{
80105fb5:	55                   	push   %ebp
80105fb6:	89 e5                	mov    %esp,%ebp
80105fb8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fbb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fbe:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fc2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fc9:	00 
80105fca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fd1:	e8 c7 fe ff ff       	call   80105e9d <argfd>
80105fd6:	85 c0                	test   %eax,%eax
80105fd8:	78 35                	js     8010600f <sys_read+0x5a>
80105fda:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fdd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105fe8:	e8 5a fd ff ff       	call   80105d47 <argint>
80105fed:	85 c0                	test   %eax,%eax
80105fef:	78 1e                	js     8010600f <sys_read+0x5a>
80105ff1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff4:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ff8:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ffb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106006:	e8 6a fd ff ff       	call   80105d75 <argptr>
8010600b:	85 c0                	test   %eax,%eax
8010600d:	79 07                	jns    80106016 <sys_read+0x61>
    return -1;
8010600f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106014:	eb 19                	jmp    8010602f <sys_read+0x7a>
  return fileread(f, p, n);
80106016:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106019:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010601c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010601f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106023:	89 54 24 04          	mov    %edx,0x4(%esp)
80106027:	89 04 24             	mov    %eax,(%esp)
8010602a:	e8 15 b2 ff ff       	call   80101244 <fileread>
}
8010602f:	c9                   	leave  
80106030:	c3                   	ret    

80106031 <sys_write>:

int
sys_write(void)
{
80106031:	55                   	push   %ebp
80106032:	89 e5                	mov    %esp,%ebp
80106034:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106037:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010603a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010603e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106045:	00 
80106046:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010604d:	e8 4b fe ff ff       	call   80105e9d <argfd>
80106052:	85 c0                	test   %eax,%eax
80106054:	78 35                	js     8010608b <sys_write+0x5a>
80106056:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106059:	89 44 24 04          	mov    %eax,0x4(%esp)
8010605d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106064:	e8 de fc ff ff       	call   80105d47 <argint>
80106069:	85 c0                	test   %eax,%eax
8010606b:	78 1e                	js     8010608b <sys_write+0x5a>
8010606d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106070:	89 44 24 08          	mov    %eax,0x8(%esp)
80106074:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106077:	89 44 24 04          	mov    %eax,0x4(%esp)
8010607b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106082:	e8 ee fc ff ff       	call   80105d75 <argptr>
80106087:	85 c0                	test   %eax,%eax
80106089:	79 07                	jns    80106092 <sys_write+0x61>
    return -1;
8010608b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106090:	eb 19                	jmp    801060ab <sys_write+0x7a>
  return filewrite(f, p, n);
80106092:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106095:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010609b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010609f:	89 54 24 04          	mov    %edx,0x4(%esp)
801060a3:	89 04 24             	mov    %eax,(%esp)
801060a6:	e8 55 b2 ff ff       	call   80101300 <filewrite>
}
801060ab:	c9                   	leave  
801060ac:	c3                   	ret    

801060ad <sys_close>:

int
sys_close(void)
{
801060ad:	55                   	push   %ebp
801060ae:	89 e5                	mov    %esp,%ebp
801060b0:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801060b3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060b6:	89 44 24 08          	mov    %eax,0x8(%esp)
801060ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060c8:	e8 d0 fd ff ff       	call   80105e9d <argfd>
801060cd:	85 c0                	test   %eax,%eax
801060cf:	79 07                	jns    801060d8 <sys_close+0x2b>
    return -1;
801060d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060d6:	eb 24                	jmp    801060fc <sys_close+0x4f>
  proc->ofile[fd] = 0;
801060d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060e1:	83 c2 08             	add    $0x8,%edx
801060e4:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060eb:	00 
  fileclose(f);
801060ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ef:	89 04 24             	mov    %eax,(%esp)
801060f2:	e8 28 b0 ff ff       	call   8010111f <fileclose>
  return 0;
801060f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060fc:	c9                   	leave  
801060fd:	c3                   	ret    

801060fe <sys_fstat>:

int
sys_fstat(void)
{
801060fe:	55                   	push   %ebp
801060ff:	89 e5                	mov    %esp,%ebp
80106101:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106104:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106107:	89 44 24 08          	mov    %eax,0x8(%esp)
8010610b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106112:	00 
80106113:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010611a:	e8 7e fd ff ff       	call   80105e9d <argfd>
8010611f:	85 c0                	test   %eax,%eax
80106121:	78 1f                	js     80106142 <sys_fstat+0x44>
80106123:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010612a:	00 
8010612b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010612e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106132:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106139:	e8 37 fc ff ff       	call   80105d75 <argptr>
8010613e:	85 c0                	test   %eax,%eax
80106140:	79 07                	jns    80106149 <sys_fstat+0x4b>
    return -1;
80106142:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106147:	eb 12                	jmp    8010615b <sys_fstat+0x5d>
  return filestat(f, st);
80106149:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010614c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010614f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106153:	89 04 24             	mov    %eax,(%esp)
80106156:	e8 9a b0 ff ff       	call   801011f5 <filestat>
}
8010615b:	c9                   	leave  
8010615c:	c3                   	ret    

8010615d <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010615d:	55                   	push   %ebp
8010615e:	89 e5                	mov    %esp,%ebp
80106160:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106163:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106166:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106171:	e8 61 fc ff ff       	call   80105dd7 <argstr>
80106176:	85 c0                	test   %eax,%eax
80106178:	78 17                	js     80106191 <sys_link+0x34>
8010617a:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010617d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106181:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106188:	e8 4a fc ff ff       	call   80105dd7 <argstr>
8010618d:	85 c0                	test   %eax,%eax
8010618f:	79 0a                	jns    8010619b <sys_link+0x3e>
    return -1;
80106191:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106196:	e9 42 01 00 00       	jmp    801062dd <sys_link+0x180>

  begin_op();
8010619b:	e8 ea d9 ff ff       	call   80103b8a <begin_op>
  if((ip = namei(old)) == 0){
801061a0:	8b 45 d8             	mov    -0x28(%ebp),%eax
801061a3:	89 04 24             	mov    %eax,(%esp)
801061a6:	e8 10 c4 ff ff       	call   801025bb <namei>
801061ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061b2:	75 0f                	jne    801061c3 <sys_link+0x66>
    end_op();
801061b4:	e8 55 da ff ff       	call   80103c0e <end_op>
    return -1;
801061b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061be:	e9 1a 01 00 00       	jmp    801062dd <sys_link+0x180>
  }

  ilock(ip);
801061c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c6:	89 04 24             	mov    %eax,(%esp)
801061c9:	e8 3c b8 ff ff       	call   80101a0a <ilock>
  if(ip->type == T_DIR){
801061ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061d5:	66 83 f8 01          	cmp    $0x1,%ax
801061d9:	75 1a                	jne    801061f5 <sys_link+0x98>
    iunlockput(ip);
801061db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061de:	89 04 24             	mov    %eax,(%esp)
801061e1:	e8 ae ba ff ff       	call   80101c94 <iunlockput>
    end_op();
801061e6:	e8 23 da ff ff       	call   80103c0e <end_op>
    return -1;
801061eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061f0:	e9 e8 00 00 00       	jmp    801062dd <sys_link+0x180>
  }

  ip->nlink++;
801061f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061f8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061fc:	8d 50 01             	lea    0x1(%eax),%edx
801061ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106202:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106209:	89 04 24             	mov    %eax,(%esp)
8010620c:	e8 37 b6 ff ff       	call   80101848 <iupdate>
  iunlock(ip);
80106211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106214:	89 04 24             	mov    %eax,(%esp)
80106217:	e8 42 b9 ff ff       	call   80101b5e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010621c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010621f:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106222:	89 54 24 04          	mov    %edx,0x4(%esp)
80106226:	89 04 24             	mov    %eax,(%esp)
80106229:	e8 af c3 ff ff       	call   801025dd <nameiparent>
8010622e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106231:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106235:	75 02                	jne    80106239 <sys_link+0xdc>
    goto bad;
80106237:	eb 68                	jmp    801062a1 <sys_link+0x144>
  ilock(dp);
80106239:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010623c:	89 04 24             	mov    %eax,(%esp)
8010623f:	e8 c6 b7 ff ff       	call   80101a0a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106247:	8b 10                	mov    (%eax),%edx
80106249:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010624c:	8b 00                	mov    (%eax),%eax
8010624e:	39 c2                	cmp    %eax,%edx
80106250:	75 20                	jne    80106272 <sys_link+0x115>
80106252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106255:	8b 40 04             	mov    0x4(%eax),%eax
80106258:	89 44 24 08          	mov    %eax,0x8(%esp)
8010625c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010625f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106263:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106266:	89 04 24             	mov    %eax,(%esp)
80106269:	e8 8d c0 ff ff       	call   801022fb <dirlink>
8010626e:	85 c0                	test   %eax,%eax
80106270:	79 0d                	jns    8010627f <sys_link+0x122>
    iunlockput(dp);
80106272:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106275:	89 04 24             	mov    %eax,(%esp)
80106278:	e8 17 ba ff ff       	call   80101c94 <iunlockput>
    goto bad;
8010627d:	eb 22                	jmp    801062a1 <sys_link+0x144>
  }
  iunlockput(dp);
8010627f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106282:	89 04 24             	mov    %eax,(%esp)
80106285:	e8 0a ba ff ff       	call   80101c94 <iunlockput>
  iput(ip);
8010628a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010628d:	89 04 24             	mov    %eax,(%esp)
80106290:	e8 2e b9 ff ff       	call   80101bc3 <iput>

  end_op();
80106295:	e8 74 d9 ff ff       	call   80103c0e <end_op>

  return 0;
8010629a:	b8 00 00 00 00       	mov    $0x0,%eax
8010629f:	eb 3c                	jmp    801062dd <sys_link+0x180>

bad:
  ilock(ip);
801062a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a4:	89 04 24             	mov    %eax,(%esp)
801062a7:	e8 5e b7 ff ff       	call   80101a0a <ilock>
  ip->nlink--;
801062ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062af:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062b3:	8d 50 ff             	lea    -0x1(%eax),%edx
801062b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b9:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c0:	89 04 24             	mov    %eax,(%esp)
801062c3:	e8 80 b5 ff ff       	call   80101848 <iupdate>
  iunlockput(ip);
801062c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062cb:	89 04 24             	mov    %eax,(%esp)
801062ce:	e8 c1 b9 ff ff       	call   80101c94 <iunlockput>
  end_op();
801062d3:	e8 36 d9 ff ff       	call   80103c0e <end_op>
  return -1;
801062d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062dd:	c9                   	leave  
801062de:	c3                   	ret    

801062df <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
801062df:	55                   	push   %ebp
801062e0:	89 e5                	mov    %esp,%ebp
801062e2:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062e5:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062ec:	eb 4b                	jmp    80106339 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801062f8:	00 
801062f9:	89 44 24 08          	mov    %eax,0x8(%esp)
801062fd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106300:	89 44 24 04          	mov    %eax,0x4(%esp)
80106304:	8b 45 08             	mov    0x8(%ebp),%eax
80106307:	89 04 24             	mov    %eax,(%esp)
8010630a:	e8 0e bc ff ff       	call   80101f1d <readi>
8010630f:	83 f8 10             	cmp    $0x10,%eax
80106312:	74 0c                	je     80106320 <isdirempty+0x41>
      panic("isdirempty: readi");
80106314:	c7 04 24 a7 9f 10 80 	movl   $0x80109fa7,(%esp)
8010631b:	e8 1a a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106320:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106324:	66 85 c0             	test   %ax,%ax
80106327:	74 07                	je     80106330 <isdirempty+0x51>
      return 0;
80106329:	b8 00 00 00 00       	mov    $0x0,%eax
8010632e:	eb 1b                	jmp    8010634b <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106333:	83 c0 10             	add    $0x10,%eax
80106336:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106339:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010633c:	8b 45 08             	mov    0x8(%ebp),%eax
8010633f:	8b 40 18             	mov    0x18(%eax),%eax
80106342:	39 c2                	cmp    %eax,%edx
80106344:	72 a8                	jb     801062ee <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106346:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010634b:	c9                   	leave  
8010634c:	c3                   	ret    

8010634d <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010634d:	55                   	push   %ebp
8010634e:	89 e5                	mov    %esp,%ebp
80106350:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106353:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106356:	89 44 24 04          	mov    %eax,0x4(%esp)
8010635a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106361:	e8 71 fa ff ff       	call   80105dd7 <argstr>
80106366:	85 c0                	test   %eax,%eax
80106368:	79 0a                	jns    80106374 <sys_unlink+0x27>
    return -1;
8010636a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010636f:	e9 af 01 00 00       	jmp    80106523 <sys_unlink+0x1d6>

  begin_op();
80106374:	e8 11 d8 ff ff       	call   80103b8a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106379:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010637c:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010637f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106383:	89 04 24             	mov    %eax,(%esp)
80106386:	e8 52 c2 ff ff       	call   801025dd <nameiparent>
8010638b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010638e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106392:	75 0f                	jne    801063a3 <sys_unlink+0x56>
    end_op();
80106394:	e8 75 d8 ff ff       	call   80103c0e <end_op>
    return -1;
80106399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010639e:	e9 80 01 00 00       	jmp    80106523 <sys_unlink+0x1d6>
  }

  ilock(dp);
801063a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a6:	89 04 24             	mov    %eax,(%esp)
801063a9:	e8 5c b6 ff ff       	call   80101a0a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801063ae:	c7 44 24 04 b9 9f 10 	movl   $0x80109fb9,0x4(%esp)
801063b5:	80 
801063b6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063b9:	89 04 24             	mov    %eax,(%esp)
801063bc:	e8 4f be ff ff       	call   80102210 <namecmp>
801063c1:	85 c0                	test   %eax,%eax
801063c3:	0f 84 45 01 00 00    	je     8010650e <sys_unlink+0x1c1>
801063c9:	c7 44 24 04 bb 9f 10 	movl   $0x80109fbb,0x4(%esp)
801063d0:	80 
801063d1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063d4:	89 04 24             	mov    %eax,(%esp)
801063d7:	e8 34 be ff ff       	call   80102210 <namecmp>
801063dc:	85 c0                	test   %eax,%eax
801063de:	0f 84 2a 01 00 00    	je     8010650e <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063e4:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801063eb:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f5:	89 04 24             	mov    %eax,(%esp)
801063f8:	e8 35 be ff ff       	call   80102232 <dirlookup>
801063fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106400:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106404:	75 05                	jne    8010640b <sys_unlink+0xbe>
    goto bad;
80106406:	e9 03 01 00 00       	jmp    8010650e <sys_unlink+0x1c1>
  ilock(ip);
8010640b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010640e:	89 04 24             	mov    %eax,(%esp)
80106411:	e8 f4 b5 ff ff       	call   80101a0a <ilock>

  if(ip->nlink < 1)
80106416:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106419:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010641d:	66 85 c0             	test   %ax,%ax
80106420:	7f 0c                	jg     8010642e <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106422:	c7 04 24 be 9f 10 80 	movl   $0x80109fbe,(%esp)
80106429:	e8 0c a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010642e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106431:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106435:	66 83 f8 01          	cmp    $0x1,%ax
80106439:	75 1f                	jne    8010645a <sys_unlink+0x10d>
8010643b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643e:	89 04 24             	mov    %eax,(%esp)
80106441:	e8 99 fe ff ff       	call   801062df <isdirempty>
80106446:	85 c0                	test   %eax,%eax
80106448:	75 10                	jne    8010645a <sys_unlink+0x10d>
    iunlockput(ip);
8010644a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010644d:	89 04 24             	mov    %eax,(%esp)
80106450:	e8 3f b8 ff ff       	call   80101c94 <iunlockput>
    goto bad;
80106455:	e9 b4 00 00 00       	jmp    8010650e <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
8010645a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106461:	00 
80106462:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106469:	00 
8010646a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010646d:	89 04 24             	mov    %eax,(%esp)
80106470:	e8 90 f5 ff ff       	call   80105a05 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106475:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106478:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010647f:	00 
80106480:	89 44 24 08          	mov    %eax,0x8(%esp)
80106484:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106487:	89 44 24 04          	mov    %eax,0x4(%esp)
8010648b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648e:	89 04 24             	mov    %eax,(%esp)
80106491:	e8 eb bb ff ff       	call   80102081 <writei>
80106496:	83 f8 10             	cmp    $0x10,%eax
80106499:	74 0c                	je     801064a7 <sys_unlink+0x15a>
    panic("unlink: writei");
8010649b:	c7 04 24 d0 9f 10 80 	movl   $0x80109fd0,(%esp)
801064a2:	e8 93 a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
801064a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064aa:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064ae:	66 83 f8 01          	cmp    $0x1,%ax
801064b2:	75 1c                	jne    801064d0 <sys_unlink+0x183>
    dp->nlink--;
801064b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064bb:	8d 50 ff             	lea    -0x1(%eax),%edx
801064be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c1:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c8:	89 04 24             	mov    %eax,(%esp)
801064cb:	e8 78 b3 ff ff       	call   80101848 <iupdate>
  }
  iunlockput(dp);
801064d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d3:	89 04 24             	mov    %eax,(%esp)
801064d6:	e8 b9 b7 ff ff       	call   80101c94 <iunlockput>

  ip->nlink--;
801064db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064de:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064e2:	8d 50 ff             	lea    -0x1(%eax),%edx
801064e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ef:	89 04 24             	mov    %eax,(%esp)
801064f2:	e8 51 b3 ff ff       	call   80101848 <iupdate>
  iunlockput(ip);
801064f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064fa:	89 04 24             	mov    %eax,(%esp)
801064fd:	e8 92 b7 ff ff       	call   80101c94 <iunlockput>

  end_op();
80106502:	e8 07 d7 ff ff       	call   80103c0e <end_op>

  return 0;
80106507:	b8 00 00 00 00       	mov    $0x0,%eax
8010650c:	eb 15                	jmp    80106523 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
8010650e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106511:	89 04 24             	mov    %eax,(%esp)
80106514:	e8 7b b7 ff ff       	call   80101c94 <iunlockput>
  end_op();
80106519:	e8 f0 d6 ff ff       	call   80103c0e <end_op>
  return -1;
8010651e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106523:	c9                   	leave  
80106524:	c3                   	ret    

80106525 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106525:	55                   	push   %ebp
80106526:	89 e5                	mov    %esp,%ebp
80106528:	83 ec 48             	sub    $0x48,%esp
8010652b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010652e:	8b 55 10             	mov    0x10(%ebp),%edx
80106531:	8b 45 14             	mov    0x14(%ebp),%eax
80106534:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106538:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
8010653c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106540:	8d 45 de             	lea    -0x22(%ebp),%eax
80106543:	89 44 24 04          	mov    %eax,0x4(%esp)
80106547:	8b 45 08             	mov    0x8(%ebp),%eax
8010654a:	89 04 24             	mov    %eax,(%esp)
8010654d:	e8 8b c0 ff ff       	call   801025dd <nameiparent>
80106552:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106555:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106559:	75 0a                	jne    80106565 <create+0x40>
    return 0;
8010655b:	b8 00 00 00 00       	mov    $0x0,%eax
80106560:	e9 7e 01 00 00       	jmp    801066e3 <create+0x1be>
  ilock(dp);
80106565:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106568:	89 04 24             	mov    %eax,(%esp)
8010656b:	e8 9a b4 ff ff       	call   80101a0a <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106570:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106573:	89 44 24 08          	mov    %eax,0x8(%esp)
80106577:	8d 45 de             	lea    -0x22(%ebp),%eax
8010657a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010657e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106581:	89 04 24             	mov    %eax,(%esp)
80106584:	e8 a9 bc ff ff       	call   80102232 <dirlookup>
80106589:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010658c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106590:	74 47                	je     801065d9 <create+0xb4>
    iunlockput(dp);
80106592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106595:	89 04 24             	mov    %eax,(%esp)
80106598:	e8 f7 b6 ff ff       	call   80101c94 <iunlockput>
    ilock(ip);
8010659d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065a0:	89 04 24             	mov    %eax,(%esp)
801065a3:	e8 62 b4 ff ff       	call   80101a0a <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801065a8:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801065ad:	75 15                	jne    801065c4 <create+0x9f>
801065af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801065b6:	66 83 f8 02          	cmp    $0x2,%ax
801065ba:	75 08                	jne    801065c4 <create+0x9f>
      return ip;
801065bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065bf:	e9 1f 01 00 00       	jmp    801066e3 <create+0x1be>
    iunlockput(ip);
801065c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065c7:	89 04 24             	mov    %eax,(%esp)
801065ca:	e8 c5 b6 ff ff       	call   80101c94 <iunlockput>
    return 0;
801065cf:	b8 00 00 00 00       	mov    $0x0,%eax
801065d4:	e9 0a 01 00 00       	jmp    801066e3 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801065d9:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801065dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e0:	8b 00                	mov    (%eax),%eax
801065e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801065e6:	89 04 24             	mov    %eax,(%esp)
801065e9:	e8 85 b1 ff ff       	call   80101773 <ialloc>
801065ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065f5:	75 0c                	jne    80106603 <create+0xde>
    panic("create: ialloc");
801065f7:	c7 04 24 df 9f 10 80 	movl   $0x80109fdf,(%esp)
801065fe:	e8 37 9f ff ff       	call   8010053a <panic>

  ilock(ip);
80106603:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106606:	89 04 24             	mov    %eax,(%esp)
80106609:	e8 fc b3 ff ff       	call   80101a0a <ilock>
  ip->major = major;
8010660e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106611:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106615:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106619:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010661c:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106620:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106624:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106627:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
8010662d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106630:	89 04 24             	mov    %eax,(%esp)
80106633:	e8 10 b2 ff ff       	call   80101848 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106638:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010663d:	75 6a                	jne    801066a9 <create+0x184>
    dp->nlink++;  // for ".."
8010663f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106642:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106646:	8d 50 01             	lea    0x1(%eax),%edx
80106649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106650:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106653:	89 04 24             	mov    %eax,(%esp)
80106656:	e8 ed b1 ff ff       	call   80101848 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010665b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010665e:	8b 40 04             	mov    0x4(%eax),%eax
80106661:	89 44 24 08          	mov    %eax,0x8(%esp)
80106665:	c7 44 24 04 b9 9f 10 	movl   $0x80109fb9,0x4(%esp)
8010666c:	80 
8010666d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106670:	89 04 24             	mov    %eax,(%esp)
80106673:	e8 83 bc ff ff       	call   801022fb <dirlink>
80106678:	85 c0                	test   %eax,%eax
8010667a:	78 21                	js     8010669d <create+0x178>
8010667c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667f:	8b 40 04             	mov    0x4(%eax),%eax
80106682:	89 44 24 08          	mov    %eax,0x8(%esp)
80106686:	c7 44 24 04 bb 9f 10 	movl   $0x80109fbb,0x4(%esp)
8010668d:	80 
8010668e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106691:	89 04 24             	mov    %eax,(%esp)
80106694:	e8 62 bc ff ff       	call   801022fb <dirlink>
80106699:	85 c0                	test   %eax,%eax
8010669b:	79 0c                	jns    801066a9 <create+0x184>
      panic("create dots");
8010669d:	c7 04 24 ee 9f 10 80 	movl   $0x80109fee,(%esp)
801066a4:	e8 91 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
801066a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ac:	8b 40 04             	mov    0x4(%eax),%eax
801066af:	89 44 24 08          	mov    %eax,0x8(%esp)
801066b3:	8d 45 de             	lea    -0x22(%ebp),%eax
801066b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bd:	89 04 24             	mov    %eax,(%esp)
801066c0:	e8 36 bc ff ff       	call   801022fb <dirlink>
801066c5:	85 c0                	test   %eax,%eax
801066c7:	79 0c                	jns    801066d5 <create+0x1b0>
    panic("create: dirlink");
801066c9:	c7 04 24 fa 9f 10 80 	movl   $0x80109ffa,(%esp)
801066d0:	e8 65 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
801066d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d8:	89 04 24             	mov    %eax,(%esp)
801066db:	e8 b4 b5 ff ff       	call   80101c94 <iunlockput>

  return ip;
801066e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066e3:	c9                   	leave  
801066e4:	c3                   	ret    

801066e5 <sys_open>:

int
sys_open(void)
{
801066e5:	55                   	push   %ebp
801066e6:	89 e5                	mov    %esp,%ebp
801066e8:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066eb:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801066f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066f9:	e8 d9 f6 ff ff       	call   80105dd7 <argstr>
801066fe:	85 c0                	test   %eax,%eax
80106700:	78 17                	js     80106719 <sys_open+0x34>
80106702:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106705:	89 44 24 04          	mov    %eax,0x4(%esp)
80106709:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106710:	e8 32 f6 ff ff       	call   80105d47 <argint>
80106715:	85 c0                	test   %eax,%eax
80106717:	79 0a                	jns    80106723 <sys_open+0x3e>
    return -1;
80106719:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010671e:	e9 5c 01 00 00       	jmp    8010687f <sys_open+0x19a>

  begin_op();
80106723:	e8 62 d4 ff ff       	call   80103b8a <begin_op>

  if(omode & O_CREATE){
80106728:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010672b:	25 00 02 00 00       	and    $0x200,%eax
80106730:	85 c0                	test   %eax,%eax
80106732:	74 3b                	je     8010676f <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106734:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106737:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010673e:	00 
8010673f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106746:	00 
80106747:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010674e:	00 
8010674f:	89 04 24             	mov    %eax,(%esp)
80106752:	e8 ce fd ff ff       	call   80106525 <create>
80106757:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010675a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010675e:	75 6b                	jne    801067cb <sys_open+0xe6>
      end_op();
80106760:	e8 a9 d4 ff ff       	call   80103c0e <end_op>
      return -1;
80106765:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010676a:	e9 10 01 00 00       	jmp    8010687f <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010676f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106772:	89 04 24             	mov    %eax,(%esp)
80106775:	e8 41 be ff ff       	call   801025bb <namei>
8010677a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010677d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106781:	75 0f                	jne    80106792 <sys_open+0xad>
      end_op();
80106783:	e8 86 d4 ff ff       	call   80103c0e <end_op>
      return -1;
80106788:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010678d:	e9 ed 00 00 00       	jmp    8010687f <sys_open+0x19a>
    }
    ilock(ip);
80106792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106795:	89 04 24             	mov    %eax,(%esp)
80106798:	e8 6d b2 ff ff       	call   80101a0a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010679d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801067a4:	66 83 f8 01          	cmp    $0x1,%ax
801067a8:	75 21                	jne    801067cb <sys_open+0xe6>
801067aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067ad:	85 c0                	test   %eax,%eax
801067af:	74 1a                	je     801067cb <sys_open+0xe6>
      iunlockput(ip);
801067b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b4:	89 04 24             	mov    %eax,(%esp)
801067b7:	e8 d8 b4 ff ff       	call   80101c94 <iunlockput>
      end_op();
801067bc:	e8 4d d4 ff ff       	call   80103c0e <end_op>
      return -1;
801067c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067c6:	e9 b4 00 00 00       	jmp    8010687f <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067cb:	e8 a7 a8 ff ff       	call   80101077 <filealloc>
801067d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067d3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067d7:	74 14                	je     801067ed <sys_open+0x108>
801067d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067dc:	89 04 24             	mov    %eax,(%esp)
801067df:	e8 2e f7 ff ff       	call   80105f12 <fdalloc>
801067e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067e7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067eb:	79 28                	jns    80106815 <sys_open+0x130>
    if(f)
801067ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067f1:	74 0b                	je     801067fe <sys_open+0x119>
      fileclose(f);
801067f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067f6:	89 04 24             	mov    %eax,(%esp)
801067f9:	e8 21 a9 ff ff       	call   8010111f <fileclose>
    iunlockput(ip);
801067fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106801:	89 04 24             	mov    %eax,(%esp)
80106804:	e8 8b b4 ff ff       	call   80101c94 <iunlockput>
    end_op();
80106809:	e8 00 d4 ff ff       	call   80103c0e <end_op>
    return -1;
8010680e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106813:	eb 6a                	jmp    8010687f <sys_open+0x19a>
  }
  iunlock(ip);
80106815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106818:	89 04 24             	mov    %eax,(%esp)
8010681b:	e8 3e b3 ff ff       	call   80101b5e <iunlock>
  end_op();
80106820:	e8 e9 d3 ff ff       	call   80103c0e <end_op>

  f->type = FD_INODE;
80106825:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106828:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010682e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106831:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106834:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106837:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010683a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106841:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106844:	83 e0 01             	and    $0x1,%eax
80106847:	85 c0                	test   %eax,%eax
80106849:	0f 94 c0             	sete   %al
8010684c:	89 c2                	mov    %eax,%edx
8010684e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106851:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106857:	83 e0 01             	and    $0x1,%eax
8010685a:	85 c0                	test   %eax,%eax
8010685c:	75 0a                	jne    80106868 <sys_open+0x183>
8010685e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106861:	83 e0 02             	and    $0x2,%eax
80106864:	85 c0                	test   %eax,%eax
80106866:	74 07                	je     8010686f <sys_open+0x18a>
80106868:	b8 01 00 00 00       	mov    $0x1,%eax
8010686d:	eb 05                	jmp    80106874 <sys_open+0x18f>
8010686f:	b8 00 00 00 00       	mov    $0x0,%eax
80106874:	89 c2                	mov    %eax,%edx
80106876:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106879:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010687c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010687f:	c9                   	leave  
80106880:	c3                   	ret    

80106881 <sys_mkdir>:

int
sys_mkdir(void)
{
80106881:	55                   	push   %ebp
80106882:	89 e5                	mov    %esp,%ebp
80106884:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106887:	e8 fe d2 ff ff       	call   80103b8a <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010688c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010688f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106893:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010689a:	e8 38 f5 ff ff       	call   80105dd7 <argstr>
8010689f:	85 c0                	test   %eax,%eax
801068a1:	78 2c                	js     801068cf <sys_mkdir+0x4e>
801068a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801068ad:	00 
801068ae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801068b5:	00 
801068b6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068bd:	00 
801068be:	89 04 24             	mov    %eax,(%esp)
801068c1:	e8 5f fc ff ff       	call   80106525 <create>
801068c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068cd:	75 0c                	jne    801068db <sys_mkdir+0x5a>
    end_op();
801068cf:	e8 3a d3 ff ff       	call   80103c0e <end_op>
    return -1;
801068d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068d9:	eb 15                	jmp    801068f0 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801068db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068de:	89 04 24             	mov    %eax,(%esp)
801068e1:	e8 ae b3 ff ff       	call   80101c94 <iunlockput>
  end_op();
801068e6:	e8 23 d3 ff ff       	call   80103c0e <end_op>
  return 0;
801068eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068f0:	c9                   	leave  
801068f1:	c3                   	ret    

801068f2 <sys_mknod>:

int
sys_mknod(void)
{
801068f2:	55                   	push   %ebp
801068f3:	89 e5                	mov    %esp,%ebp
801068f5:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801068f8:	e8 8d d2 ff ff       	call   80103b8a <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801068fd:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106900:	89 44 24 04          	mov    %eax,0x4(%esp)
80106904:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010690b:	e8 c7 f4 ff ff       	call   80105dd7 <argstr>
80106910:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106913:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106917:	78 5e                	js     80106977 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106919:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010691c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106920:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106927:	e8 1b f4 ff ff       	call   80105d47 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
8010692c:	85 c0                	test   %eax,%eax
8010692e:	78 47                	js     80106977 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106930:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106933:	89 44 24 04          	mov    %eax,0x4(%esp)
80106937:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010693e:	e8 04 f4 ff ff       	call   80105d47 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106943:	85 c0                	test   %eax,%eax
80106945:	78 30                	js     80106977 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106947:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010694a:	0f bf c8             	movswl %ax,%ecx
8010694d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106950:	0f bf d0             	movswl %ax,%edx
80106953:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106956:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010695a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010695e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106965:	00 
80106966:	89 04 24             	mov    %eax,(%esp)
80106969:	e8 b7 fb ff ff       	call   80106525 <create>
8010696e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106971:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106975:	75 0c                	jne    80106983 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106977:	e8 92 d2 ff ff       	call   80103c0e <end_op>
    return -1;
8010697c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106981:	eb 15                	jmp    80106998 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106983:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106986:	89 04 24             	mov    %eax,(%esp)
80106989:	e8 06 b3 ff ff       	call   80101c94 <iunlockput>
  end_op();
8010698e:	e8 7b d2 ff ff       	call   80103c0e <end_op>
  return 0;
80106993:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106998:	c9                   	leave  
80106999:	c3                   	ret    

8010699a <sys_chdir>:

int
sys_chdir(void)
{
8010699a:	55                   	push   %ebp
8010699b:	89 e5                	mov    %esp,%ebp
8010699d:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801069a0:	e8 e5 d1 ff ff       	call   80103b8a <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801069a5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801069a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801069ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069b3:	e8 1f f4 ff ff       	call   80105dd7 <argstr>
801069b8:	85 c0                	test   %eax,%eax
801069ba:	78 14                	js     801069d0 <sys_chdir+0x36>
801069bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069bf:	89 04 24             	mov    %eax,(%esp)
801069c2:	e8 f4 bb ff ff       	call   801025bb <namei>
801069c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069ce:	75 0c                	jne    801069dc <sys_chdir+0x42>
    end_op();
801069d0:	e8 39 d2 ff ff       	call   80103c0e <end_op>
    return -1;
801069d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069da:	eb 61                	jmp    80106a3d <sys_chdir+0xa3>
  }
  ilock(ip);
801069dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069df:	89 04 24             	mov    %eax,(%esp)
801069e2:	e8 23 b0 ff ff       	call   80101a0a <ilock>
  if(ip->type != T_DIR){
801069e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ea:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069ee:	66 83 f8 01          	cmp    $0x1,%ax
801069f2:	74 17                	je     80106a0b <sys_chdir+0x71>
    iunlockput(ip);
801069f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f7:	89 04 24             	mov    %eax,(%esp)
801069fa:	e8 95 b2 ff ff       	call   80101c94 <iunlockput>
    end_op();
801069ff:	e8 0a d2 ff ff       	call   80103c0e <end_op>
    return -1;
80106a04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a09:	eb 32                	jmp    80106a3d <sys_chdir+0xa3>
  }
  iunlock(ip);
80106a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a0e:	89 04 24             	mov    %eax,(%esp)
80106a11:	e8 48 b1 ff ff       	call   80101b5e <iunlock>
  iput(proc->cwd);
80106a16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a1c:	8b 40 68             	mov    0x68(%eax),%eax
80106a1f:	89 04 24             	mov    %eax,(%esp)
80106a22:	e8 9c b1 ff ff       	call   80101bc3 <iput>
  end_op();
80106a27:	e8 e2 d1 ff ff       	call   80103c0e <end_op>
  proc->cwd = ip;
80106a2c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a32:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a35:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a38:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a3d:	c9                   	leave  
80106a3e:	c3                   	ret    

80106a3f <sys_exec>:

int
sys_exec(void)
{
80106a3f:	55                   	push   %ebp
80106a40:	89 e5                	mov    %esp,%ebp
80106a42:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a48:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a56:	e8 7c f3 ff ff       	call   80105dd7 <argstr>
80106a5b:	85 c0                	test   %eax,%eax
80106a5d:	78 1a                	js     80106a79 <sys_exec+0x3a>
80106a5f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a65:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a70:	e8 d2 f2 ff ff       	call   80105d47 <argint>
80106a75:	85 c0                	test   %eax,%eax
80106a77:	79 0a                	jns    80106a83 <sys_exec+0x44>
    return -1;
80106a79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a7e:	e9 c8 00 00 00       	jmp    80106b4b <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a83:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a8a:	00 
80106a8b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a92:	00 
80106a93:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a99:	89 04 24             	mov    %eax,(%esp)
80106a9c:	e8 64 ef ff ff       	call   80105a05 <memset>
  for(i=0;; i++){
80106aa1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aab:	83 f8 1f             	cmp    $0x1f,%eax
80106aae:	76 0a                	jbe    80106aba <sys_exec+0x7b>
      return -1;
80106ab0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ab5:	e9 91 00 00 00       	jmp    80106b4b <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106aba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106abd:	c1 e0 02             	shl    $0x2,%eax
80106ac0:	89 c2                	mov    %eax,%edx
80106ac2:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ac8:	01 c2                	add    %eax,%edx
80106aca:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106ad0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ad4:	89 14 24             	mov    %edx,(%esp)
80106ad7:	e8 cf f1 ff ff       	call   80105cab <fetchint>
80106adc:	85 c0                	test   %eax,%eax
80106ade:	79 07                	jns    80106ae7 <sys_exec+0xa8>
      return -1;
80106ae0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae5:	eb 64                	jmp    80106b4b <sys_exec+0x10c>
    if(uarg == 0){
80106ae7:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106aed:	85 c0                	test   %eax,%eax
80106aef:	75 26                	jne    80106b17 <sys_exec+0xd8>
      argv[i] = 0;
80106af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106af4:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106afb:	00 00 00 00 
      break;
80106aff:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b03:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106b09:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b0d:	89 04 24             	mov    %eax,(%esp)
80106b10:	e8 f5 9f ff ff       	call   80100b0a <exec>
80106b15:	eb 34                	jmp    80106b4b <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106b17:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b20:	c1 e2 02             	shl    $0x2,%edx
80106b23:	01 c2                	add    %eax,%edx
80106b25:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b2b:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b2f:	89 04 24             	mov    %eax,(%esp)
80106b32:	e8 ae f1 ff ff       	call   80105ce5 <fetchstr>
80106b37:	85 c0                	test   %eax,%eax
80106b39:	79 07                	jns    80106b42 <sys_exec+0x103>
      return -1;
80106b3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b40:	eb 09                	jmp    80106b4b <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b42:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b46:	e9 5d ff ff ff       	jmp    80106aa8 <sys_exec+0x69>
  return exec(path, argv);
}
80106b4b:	c9                   	leave  
80106b4c:	c3                   	ret    

80106b4d <sys_pipe>:

int
sys_pipe(void)
{
80106b4d:	55                   	push   %ebp
80106b4e:	89 e5                	mov    %esp,%ebp
80106b50:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b53:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b5a:	00 
80106b5b:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b62:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b69:	e8 07 f2 ff ff       	call   80105d75 <argptr>
80106b6e:	85 c0                	test   %eax,%eax
80106b70:	79 0a                	jns    80106b7c <sys_pipe+0x2f>
    return -1;
80106b72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b77:	e9 9b 00 00 00       	jmp    80106c17 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b7c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b83:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b86:	89 04 24             	mov    %eax,(%esp)
80106b89:	e8 08 db ff ff       	call   80104696 <pipealloc>
80106b8e:	85 c0                	test   %eax,%eax
80106b90:	79 07                	jns    80106b99 <sys_pipe+0x4c>
    return -1;
80106b92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b97:	eb 7e                	jmp    80106c17 <sys_pipe+0xca>
  fd0 = -1;
80106b99:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106ba0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ba3:	89 04 24             	mov    %eax,(%esp)
80106ba6:	e8 67 f3 ff ff       	call   80105f12 <fdalloc>
80106bab:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bb2:	78 14                	js     80106bc8 <sys_pipe+0x7b>
80106bb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bb7:	89 04 24             	mov    %eax,(%esp)
80106bba:	e8 53 f3 ff ff       	call   80105f12 <fdalloc>
80106bbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bc2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bc6:	79 37                	jns    80106bff <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bc8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bcc:	78 14                	js     80106be2 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bd4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bd7:	83 c2 08             	add    $0x8,%edx
80106bda:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106be1:	00 
    fileclose(rf);
80106be2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106be5:	89 04 24             	mov    %eax,(%esp)
80106be8:	e8 32 a5 ff ff       	call   8010111f <fileclose>
    fileclose(wf);
80106bed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bf0:	89 04 24             	mov    %eax,(%esp)
80106bf3:	e8 27 a5 ff ff       	call   8010111f <fileclose>
    return -1;
80106bf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bfd:	eb 18                	jmp    80106c17 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106bff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c02:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c05:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106c07:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c0a:	8d 50 04             	lea    0x4(%eax),%edx
80106c0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c10:	89 02                	mov    %eax,(%edx)
  return 0;
80106c12:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c17:	c9                   	leave  
80106c18:	c3                   	ret    

80106c19 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c19:	55                   	push   %ebp
80106c1a:	89 e5                	mov    %esp,%ebp
80106c1c:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c1f:	e8 48 e2 ff ff       	call   80104e6c <fork>
}
80106c24:	c9                   	leave  
80106c25:	c3                   	ret    

80106c26 <sys_exit>:

int
sys_exit(void)
{
80106c26:	55                   	push   %ebp
80106c27:	89 e5                	mov    %esp,%ebp
80106c29:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c2c:	e8 2e e4 ff ff       	call   8010505f <exit>
  return 0;  // not reached
80106c31:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c36:	c9                   	leave  
80106c37:	c3                   	ret    

80106c38 <sys_wait>:

int
sys_wait(void)
{
80106c38:	55                   	push   %ebp
80106c39:	89 e5                	mov    %esp,%ebp
80106c3b:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c3e:	e8 4f e5 ff ff       	call   80105192 <wait>
}
80106c43:	c9                   	leave  
80106c44:	c3                   	ret    

80106c45 <sys_kill>:

int
sys_kill(void)
{
80106c45:	55                   	push   %ebp
80106c46:	89 e5                	mov    %esp,%ebp
80106c48:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c4b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c59:	e8 e9 f0 ff ff       	call   80105d47 <argint>
80106c5e:	85 c0                	test   %eax,%eax
80106c60:	79 07                	jns    80106c69 <sys_kill+0x24>
    return -1;
80106c62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c67:	eb 0b                	jmp    80106c74 <sys_kill+0x2f>
  return kill(pid);
80106c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c6c:	89 04 24             	mov    %eax,(%esp)
80106c6f:	e8 fc e8 ff ff       	call   80105570 <kill>
}
80106c74:	c9                   	leave  
80106c75:	c3                   	ret    

80106c76 <sys_getpid>:

int
sys_getpid(void)
{
80106c76:	55                   	push   %ebp
80106c77:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c7f:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c82:	5d                   	pop    %ebp
80106c83:	c3                   	ret    

80106c84 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c84:	55                   	push   %ebp
80106c85:	89 e5                	mov    %esp,%ebp
80106c87:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c8a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c98:	e8 aa f0 ff ff       	call   80105d47 <argint>
80106c9d:	85 c0                	test   %eax,%eax
80106c9f:	79 07                	jns    80106ca8 <sys_sbrk+0x24>
    return -1;
80106ca1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ca6:	eb 24                	jmp    80106ccc <sys_sbrk+0x48>
  addr = proc->sz;
80106ca8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cae:	8b 00                	mov    (%eax),%eax
80106cb0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106cb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb6:	89 04 24             	mov    %eax,(%esp)
80106cb9:	e8 f3 e0 ff ff       	call   80104db1 <growproc>
80106cbe:	85 c0                	test   %eax,%eax
80106cc0:	79 07                	jns    80106cc9 <sys_sbrk+0x45>
    return -1;
80106cc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cc7:	eb 03                	jmp    80106ccc <sys_sbrk+0x48>
  return addr;
80106cc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106ccc:	c9                   	leave  
80106ccd:	c3                   	ret    

80106cce <sys_sleep>:

int
sys_sleep(void)
{
80106cce:	55                   	push   %ebp
80106ccf:	89 e5                	mov    %esp,%ebp
80106cd1:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106cd4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cdb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ce2:	e8 60 f0 ff ff       	call   80105d47 <argint>
80106ce7:	85 c0                	test   %eax,%eax
80106ce9:	79 07                	jns    80106cf2 <sys_sleep+0x24>
    return -1;
80106ceb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cf0:	eb 6c                	jmp    80106d5e <sys_sleep+0x90>
  acquire(&tickslock);
80106cf2:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106cf9:	e8 b3 ea ff ff       	call   801057b1 <acquire>
  ticks0 = ticks;
80106cfe:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d03:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106d06:	eb 34                	jmp    80106d3c <sys_sleep+0x6e>
    if(proc->killed){
80106d08:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d0e:	8b 40 24             	mov    0x24(%eax),%eax
80106d11:	85 c0                	test   %eax,%eax
80106d13:	74 13                	je     80106d28 <sys_sleep+0x5a>
      release(&tickslock);
80106d15:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d1c:	e8 f2 ea ff ff       	call   80105813 <release>
      return -1;
80106d21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d26:	eb 36                	jmp    80106d5e <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d28:	c7 44 24 04 c0 04 12 	movl   $0x801204c0,0x4(%esp)
80106d2f:	80 
80106d30:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80106d37:	e8 2d e7 ff ff       	call   80105469 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d3c:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d41:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d44:	89 c2                	mov    %eax,%edx
80106d46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d49:	39 c2                	cmp    %eax,%edx
80106d4b:	72 bb                	jb     80106d08 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d4d:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d54:	e8 ba ea ff ff       	call   80105813 <release>
  return 0;
80106d59:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d5e:	c9                   	leave  
80106d5f:	c3                   	ret    

80106d60 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d60:	55                   	push   %ebp
80106d61:	89 e5                	mov    %esp,%ebp
80106d63:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d66:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d6d:	e8 3f ea ff ff       	call   801057b1 <acquire>
  xticks = ticks;
80106d72:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d77:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d7a:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d81:	e8 8d ea ff ff       	call   80105813 <release>
  return xticks;
80106d86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d89:	c9                   	leave  
80106d8a:	c3                   	ret    

80106d8b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d8b:	55                   	push   %ebp
80106d8c:	89 e5                	mov    %esp,%ebp
80106d8e:	83 ec 08             	sub    $0x8,%esp
80106d91:	8b 55 08             	mov    0x8(%ebp),%edx
80106d94:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d97:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d9b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d9e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106da2:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106da6:	ee                   	out    %al,(%dx)
}
80106da7:	c9                   	leave  
80106da8:	c3                   	ret    

80106da9 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106da9:	55                   	push   %ebp
80106daa:	89 e5                	mov    %esp,%ebp
80106dac:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106daf:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106db6:	00 
80106db7:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106dbe:	e8 c8 ff ff ff       	call   80106d8b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106dc3:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106dca:	00 
80106dcb:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dd2:	e8 b4 ff ff ff       	call   80106d8b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106dd7:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106dde:	00 
80106ddf:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106de6:	e8 a0 ff ff ff       	call   80106d8b <outb>
  picenable(IRQ_TIMER);
80106deb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106df2:	e8 32 d7 ff ff       	call   80104529 <picenable>
}
80106df7:	c9                   	leave  
80106df8:	c3                   	ret    

80106df9 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106df9:	1e                   	push   %ds
  pushl %es
80106dfa:	06                   	push   %es
  pushl %fs
80106dfb:	0f a0                	push   %fs
  pushl %gs
80106dfd:	0f a8                	push   %gs
  pushal
80106dff:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106e00:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106e04:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e06:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e08:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e0c:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e0e:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e10:	54                   	push   %esp
  call trap
80106e11:	e8 d8 01 00 00       	call   80106fee <trap>
  addl $4, %esp
80106e16:	83 c4 04             	add    $0x4,%esp

80106e19 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e19:	61                   	popa   
  popl %gs
80106e1a:	0f a9                	pop    %gs
  popl %fs
80106e1c:	0f a1                	pop    %fs
  popl %es
80106e1e:	07                   	pop    %es
  popl %ds
80106e1f:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e20:	83 c4 08             	add    $0x8,%esp
  iret
80106e23:	cf                   	iret   

80106e24 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e24:	55                   	push   %ebp
80106e25:	89 e5                	mov    %esp,%ebp
80106e27:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e2a:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e2d:	83 e8 01             	sub    $0x1,%eax
80106e30:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e34:	8b 45 08             	mov    0x8(%ebp),%eax
80106e37:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e3b:	8b 45 08             	mov    0x8(%ebp),%eax
80106e3e:	c1 e8 10             	shr    $0x10,%eax
80106e41:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e45:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e48:	0f 01 18             	lidtl  (%eax)
}
80106e4b:	c9                   	leave  
80106e4c:	c3                   	ret    

80106e4d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e4d:	55                   	push   %ebp
80106e4e:	89 e5                	mov    %esp,%ebp
80106e50:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e53:	0f 20 d0             	mov    %cr2,%eax
80106e56:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e59:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e5c:	c9                   	leave  
80106e5d:	c3                   	ret    

80106e5e <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e5e:	55                   	push   %ebp
80106e5f:	89 e5                	mov    %esp,%ebp
80106e61:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e64:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e6b:	e9 c3 00 00 00       	jmp    80106f33 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e73:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106e7a:	89 c2                	mov    %eax,%edx
80106e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e7f:	66 89 14 c5 00 05 12 	mov    %dx,-0x7fedfb00(,%eax,8)
80106e86:	80 
80106e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e8a:	66 c7 04 c5 02 05 12 	movw   $0x8,-0x7fedfafe(,%eax,8)
80106e91:	80 08 00 
80106e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e97:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106e9e:	80 
80106e9f:	83 e2 e0             	and    $0xffffffe0,%edx
80106ea2:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eac:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106eb3:	80 
80106eb4:	83 e2 1f             	and    $0x1f,%edx
80106eb7:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ebe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ec1:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ec8:	80 
80106ec9:	83 e2 f0             	and    $0xfffffff0,%edx
80106ecc:	83 ca 0e             	or     $0xe,%edx
80106ecf:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ed6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed9:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ee0:	80 
80106ee1:	83 e2 ef             	and    $0xffffffef,%edx
80106ee4:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106eeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eee:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ef5:	80 
80106ef6:	83 e2 9f             	and    $0xffffff9f,%edx
80106ef9:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f03:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f0a:	80 
80106f0b:	83 ca 80             	or     $0xffffff80,%edx
80106f0e:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f18:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f1f:	c1 e8 10             	shr    $0x10,%eax
80106f22:	89 c2                	mov    %eax,%edx
80106f24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f27:	66 89 14 c5 06 05 12 	mov    %dx,-0x7fedfafa(,%eax,8)
80106f2e:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f2f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f33:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f3a:	0f 8e 30 ff ff ff    	jle    80106e70 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f40:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f45:	66 a3 00 07 12 80    	mov    %ax,0x80120700
80106f4b:	66 c7 05 02 07 12 80 	movw   $0x8,0x80120702
80106f52:	08 00 
80106f54:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f5b:	83 e0 e0             	and    $0xffffffe0,%eax
80106f5e:	a2 04 07 12 80       	mov    %al,0x80120704
80106f63:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f6a:	83 e0 1f             	and    $0x1f,%eax
80106f6d:	a2 04 07 12 80       	mov    %al,0x80120704
80106f72:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f79:	83 c8 0f             	or     $0xf,%eax
80106f7c:	a2 05 07 12 80       	mov    %al,0x80120705
80106f81:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f88:	83 e0 ef             	and    $0xffffffef,%eax
80106f8b:	a2 05 07 12 80       	mov    %al,0x80120705
80106f90:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f97:	83 c8 60             	or     $0x60,%eax
80106f9a:	a2 05 07 12 80       	mov    %al,0x80120705
80106f9f:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106fa6:	83 c8 80             	or     $0xffffff80,%eax
80106fa9:	a2 05 07 12 80       	mov    %al,0x80120705
80106fae:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106fb3:	c1 e8 10             	shr    $0x10,%eax
80106fb6:	66 a3 06 07 12 80    	mov    %ax,0x80120706
  
  initlock(&tickslock, "time");
80106fbc:	c7 44 24 04 0c a0 10 	movl   $0x8010a00c,0x4(%esp)
80106fc3:	80 
80106fc4:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106fcb:	e8 c0 e7 ff ff       	call   80105790 <initlock>
}
80106fd0:	c9                   	leave  
80106fd1:	c3                   	ret    

80106fd2 <idtinit>:

void
idtinit(void)
{
80106fd2:	55                   	push   %ebp
80106fd3:	89 e5                	mov    %esp,%ebp
80106fd5:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106fd8:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106fdf:	00 
80106fe0:	c7 04 24 00 05 12 80 	movl   $0x80120500,(%esp)
80106fe7:	e8 38 fe ff ff       	call   80106e24 <lidt>
}
80106fec:	c9                   	leave  
80106fed:	c3                   	ret    

80106fee <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106fee:	55                   	push   %ebp
80106fef:	89 e5                	mov    %esp,%ebp
80106ff1:	57                   	push   %edi
80106ff2:	56                   	push   %esi
80106ff3:	53                   	push   %ebx
80106ff4:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ff7:	8b 45 08             	mov    0x8(%ebp),%eax
80106ffa:	8b 40 30             	mov    0x30(%eax),%eax
80106ffd:	83 f8 40             	cmp    $0x40,%eax
80107000:	75 3f                	jne    80107041 <trap+0x53>
    if(proc->killed)
80107002:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107008:	8b 40 24             	mov    0x24(%eax),%eax
8010700b:	85 c0                	test   %eax,%eax
8010700d:	74 05                	je     80107014 <trap+0x26>
      exit();
8010700f:	e8 4b e0 ff ff       	call   8010505f <exit>
    proc->tf = tf;
80107014:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010701a:	8b 55 08             	mov    0x8(%ebp),%edx
8010701d:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107020:	e8 e9 ed ff ff       	call   80105e0e <syscall>
    if(proc->killed)
80107025:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010702b:	8b 40 24             	mov    0x24(%eax),%eax
8010702e:	85 c0                	test   %eax,%eax
80107030:	74 0a                	je     8010703c <trap+0x4e>
      exit();
80107032:	e8 28 e0 ff ff       	call   8010505f <exit>
    return;
80107037:	e9 c5 02 00 00       	jmp    80107301 <trap+0x313>
8010703c:	e9 c0 02 00 00       	jmp    80107301 <trap+0x313>
  }
  switch(tf->trapno){
80107041:	8b 45 08             	mov    0x8(%ebp),%eax
80107044:	8b 40 30             	mov    0x30(%eax),%eax
80107047:	83 e8 0e             	sub    $0xe,%eax
8010704a:	83 f8 31             	cmp    $0x31,%eax
8010704d:	0f 87 54 01 00 00    	ja     801071a7 <trap+0x1b9>
80107053:	8b 04 85 0c a1 10 80 	mov    -0x7fef5ef4(,%eax,4),%eax
8010705a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010705c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107062:	0f b6 00             	movzbl (%eax),%eax
80107065:	84 c0                	test   %al,%al
80107067:	75 31                	jne    8010709a <trap+0xac>
      acquire(&tickslock);
80107069:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107070:	e8 3c e7 ff ff       	call   801057b1 <acquire>
      ticks++;
80107075:	a1 00 0d 12 80       	mov    0x80120d00,%eax
8010707a:	83 c0 01             	add    $0x1,%eax
8010707d:	a3 00 0d 12 80       	mov    %eax,0x80120d00
      wakeup(&ticks);
80107082:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80107089:	e8 b7 e4 ff ff       	call   80105545 <wakeup>
      release(&tickslock);
8010708e:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107095:	e8 79 e7 ff ff       	call   80105813 <release>
    }
    lapiceoi();
8010709a:	e8 b5 c5 ff ff       	call   80103654 <lapiceoi>
    break;
8010709f:	e9 d9 01 00 00       	jmp    8010727d <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801070a4:	e8 4a bd ff ff       	call   80102df3 <ideintr>
    lapiceoi();
801070a9:	e8 a6 c5 ff ff       	call   80103654 <lapiceoi>
    break;
801070ae:	e9 ca 01 00 00       	jmp    8010727d <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070b3:	e8 6b c3 ff ff       	call   80103423 <kbdintr>
    lapiceoi();
801070b8:	e8 97 c5 ff ff       	call   80103654 <lapiceoi>
    break;
801070bd:	e9 bb 01 00 00       	jmp    8010727d <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070c2:	e8 2f 04 00 00       	call   801074f6 <uartintr>
    lapiceoi();
801070c7:	e8 88 c5 ff ff       	call   80103654 <lapiceoi>
    break;
801070cc:	e9 ac 01 00 00       	jmp    8010727d <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070d1:	8b 45 08             	mov    0x8(%ebp),%eax
801070d4:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070d7:	8b 45 08             	mov    0x8(%ebp),%eax
801070da:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070de:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801070e1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070e7:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070ea:	0f b6 c0             	movzbl %al,%eax
801070ed:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070f1:	89 54 24 08          	mov    %edx,0x8(%esp)
801070f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801070f9:	c7 04 24 14 a0 10 80 	movl   $0x8010a014,(%esp)
80107100:	e8 9b 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107105:	e8 4a c5 ff ff       	call   80103654 <lapiceoi>
    break;
8010710a:	e9 6e 01 00 00       	jmp    8010727d <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
8010710f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107115:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
8010711b:	83 c2 01             	add    $0x1,%edx
8010711e:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
80107124:	e8 24 fd ff ff       	call   80106e4d <rcr2>
80107129:	05 ff 0f 00 00       	add    $0xfff,%eax
8010712e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107133:	89 c6                	mov    %eax,%esi
80107135:	e8 13 fd ff ff       	call   80106e4d <rcr2>
8010713a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010713f:	89 c3                	mov    %eax,%ebx
80107141:	e8 07 fd ff ff       	call   80106e4d <rcr2>
80107146:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010714d:	8b 52 10             	mov    0x10(%edx),%edx
80107150:	89 74 24 10          	mov    %esi,0x10(%esp)
80107154:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107158:	89 44 24 08          	mov    %eax,0x8(%esp)
8010715c:	89 54 24 04          	mov    %edx,0x4(%esp)
80107160:	c7 04 24 38 a0 10 80 	movl   $0x8010a038,(%esp)
80107167:	e8 34 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
8010716c:	e8 dc fc ff ff       	call   80106e4d <rcr2>
80107171:	89 04 24             	mov    %eax,(%esp)
80107174:	e8 dd 21 00 00       	call   80109356 <existOnDisc>
80107179:	85 c0                	test   %eax,%eax
8010717b:	74 2a                	je     801071a7 <trap+0x1b9>
      cprintf("found on disk, recovering\n");
8010717d:	c7 04 24 67 a0 10 80 	movl   $0x8010a067,(%esp)
80107184:	e8 17 92 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
80107189:	e8 bf fc ff ff       	call   80106e4d <rcr2>
8010718e:	89 04 24             	mov    %eax,(%esp)
80107191:	e8 ac 22 00 00       	call   80109442 <fixPage>
      cprintf("recovered!\n");
80107196:	c7 04 24 82 a0 10 80 	movl   $0x8010a082,(%esp)
8010719d:	e8 fe 91 ff ff       	call   801003a0 <cprintf>
      break;
801071a2:	e9 d6 00 00 00       	jmp    8010727d <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801071a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071ad:	85 c0                	test   %eax,%eax
801071af:	74 11                	je     801071c2 <trap+0x1d4>
801071b1:	8b 45 08             	mov    0x8(%ebp),%eax
801071b4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071b8:	0f b7 c0             	movzwl %ax,%eax
801071bb:	83 e0 03             	and    $0x3,%eax
801071be:	85 c0                	test   %eax,%eax
801071c0:	75 46                	jne    80107208 <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071c2:	e8 86 fc ff ff       	call   80106e4d <rcr2>
801071c7:	8b 55 08             	mov    0x8(%ebp),%edx
801071ca:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801071cd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801071d4:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071d7:	0f b6 ca             	movzbl %dl,%ecx
801071da:	8b 55 08             	mov    0x8(%ebp),%edx
801071dd:	8b 52 30             	mov    0x30(%edx),%edx
801071e0:	89 44 24 10          	mov    %eax,0x10(%esp)
801071e4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801071e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801071ec:	89 54 24 04          	mov    %edx,0x4(%esp)
801071f0:	c7 04 24 90 a0 10 80 	movl   $0x8010a090,(%esp)
801071f7:	e8 a4 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801071fc:	c7 04 24 c2 a0 10 80 	movl   $0x8010a0c2,(%esp)
80107203:	e8 32 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107208:	e8 40 fc ff ff       	call   80106e4d <rcr2>
8010720d:	89 c2                	mov    %eax,%edx
8010720f:	8b 45 08             	mov    0x8(%ebp),%eax
80107212:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107215:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010721b:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010721e:	0f b6 f0             	movzbl %al,%esi
80107221:	8b 45 08             	mov    0x8(%ebp),%eax
80107224:	8b 58 34             	mov    0x34(%eax),%ebx
80107227:	8b 45 08             	mov    0x8(%ebp),%eax
8010722a:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010722d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107233:	83 c0 6c             	add    $0x6c,%eax
80107236:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107239:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010723f:	8b 40 10             	mov    0x10(%eax),%eax
80107242:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107246:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010724a:	89 74 24 14          	mov    %esi,0x14(%esp)
8010724e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107252:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107256:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80107259:	89 7c 24 08          	mov    %edi,0x8(%esp)
8010725d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107261:	c7 04 24 c8 a0 10 80 	movl   $0x8010a0c8,(%esp)
80107268:	e8 33 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010726d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107273:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010727a:	eb 01                	jmp    8010727d <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010727c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010727d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107283:	85 c0                	test   %eax,%eax
80107285:	74 24                	je     801072ab <trap+0x2bd>
80107287:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010728d:	8b 40 24             	mov    0x24(%eax),%eax
80107290:	85 c0                	test   %eax,%eax
80107292:	74 17                	je     801072ab <trap+0x2bd>
80107294:	8b 45 08             	mov    0x8(%ebp),%eax
80107297:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010729b:	0f b7 c0             	movzwl %ax,%eax
8010729e:	83 e0 03             	and    $0x3,%eax
801072a1:	83 f8 03             	cmp    $0x3,%eax
801072a4:	75 05                	jne    801072ab <trap+0x2bd>
    exit();
801072a6:	e8 b4 dd ff ff       	call   8010505f <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
801072ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b1:	85 c0                	test   %eax,%eax
801072b3:	74 1e                	je     801072d3 <trap+0x2e5>
801072b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072bb:	8b 40 0c             	mov    0xc(%eax),%eax
801072be:	83 f8 04             	cmp    $0x4,%eax
801072c1:	75 10                	jne    801072d3 <trap+0x2e5>
801072c3:	8b 45 08             	mov    0x8(%ebp),%eax
801072c6:	8b 40 30             	mov    0x30(%eax),%eax
801072c9:	83 f8 20             	cmp    $0x20,%eax
801072cc:	75 05                	jne    801072d3 <trap+0x2e5>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4){
      updateAge(proc);
    } 
    yield();
801072ce:	e8 25 e1 ff ff       	call   801053f8 <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072d9:	85 c0                	test   %eax,%eax
801072db:	74 24                	je     80107301 <trap+0x313>
801072dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072e3:	8b 40 24             	mov    0x24(%eax),%eax
801072e6:	85 c0                	test   %eax,%eax
801072e8:	74 17                	je     80107301 <trap+0x313>
801072ea:	8b 45 08             	mov    0x8(%ebp),%eax
801072ed:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072f1:	0f b7 c0             	movzwl %ax,%eax
801072f4:	83 e0 03             	and    $0x3,%eax
801072f7:	83 f8 03             	cmp    $0x3,%eax
801072fa:	75 05                	jne    80107301 <trap+0x313>
    exit();
801072fc:	e8 5e dd ff ff       	call   8010505f <exit>
}
80107301:	83 c4 3c             	add    $0x3c,%esp
80107304:	5b                   	pop    %ebx
80107305:	5e                   	pop    %esi
80107306:	5f                   	pop    %edi
80107307:	5d                   	pop    %ebp
80107308:	c3                   	ret    

80107309 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107309:	55                   	push   %ebp
8010730a:	89 e5                	mov    %esp,%ebp
8010730c:	83 ec 14             	sub    $0x14,%esp
8010730f:	8b 45 08             	mov    0x8(%ebp),%eax
80107312:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107316:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010731a:	89 c2                	mov    %eax,%edx
8010731c:	ec                   	in     (%dx),%al
8010731d:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107320:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107324:	c9                   	leave  
80107325:	c3                   	ret    

80107326 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107326:	55                   	push   %ebp
80107327:	89 e5                	mov    %esp,%ebp
80107329:	83 ec 08             	sub    $0x8,%esp
8010732c:	8b 55 08             	mov    0x8(%ebp),%edx
8010732f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107332:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107336:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107339:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010733d:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107341:	ee                   	out    %al,(%dx)
}
80107342:	c9                   	leave  
80107343:	c3                   	ret    

80107344 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107344:	55                   	push   %ebp
80107345:	89 e5                	mov    %esp,%ebp
80107347:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010734a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107351:	00 
80107352:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107359:	e8 c8 ff ff ff       	call   80107326 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010735e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107365:	00 
80107366:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010736d:	e8 b4 ff ff ff       	call   80107326 <outb>
  outb(COM1+0, 115200/9600);
80107372:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107379:	00 
8010737a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107381:	e8 a0 ff ff ff       	call   80107326 <outb>
  outb(COM1+1, 0);
80107386:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010738d:	00 
8010738e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107395:	e8 8c ff ff ff       	call   80107326 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010739a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801073a1:	00 
801073a2:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073a9:	e8 78 ff ff ff       	call   80107326 <outb>
  outb(COM1+4, 0);
801073ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073b5:	00 
801073b6:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801073bd:	e8 64 ff ff ff       	call   80107326 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801073c2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801073c9:	00 
801073ca:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073d1:	e8 50 ff ff ff       	call   80107326 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801073d6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073dd:	e8 27 ff ff ff       	call   80107309 <inb>
801073e2:	3c ff                	cmp    $0xff,%al
801073e4:	75 02                	jne    801073e8 <uartinit+0xa4>
    return;
801073e6:	eb 6a                	jmp    80107452 <uartinit+0x10e>
  uart = 1;
801073e8:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
801073ef:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801073f2:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801073f9:	e8 0b ff ff ff       	call   80107309 <inb>
  inb(COM1+0);
801073fe:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107405:	e8 ff fe ff ff       	call   80107309 <inb>
  picenable(IRQ_COM1);
8010740a:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107411:	e8 13 d1 ff ff       	call   80104529 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107416:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010741d:	00 
8010741e:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107425:	e8 48 bc ff ff       	call   80103072 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010742a:	c7 45 f4 d4 a1 10 80 	movl   $0x8010a1d4,-0xc(%ebp)
80107431:	eb 15                	jmp    80107448 <uartinit+0x104>
    uartputc(*p);
80107433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107436:	0f b6 00             	movzbl (%eax),%eax
80107439:	0f be c0             	movsbl %al,%eax
8010743c:	89 04 24             	mov    %eax,(%esp)
8010743f:	e8 10 00 00 00       	call   80107454 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107444:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010744b:	0f b6 00             	movzbl (%eax),%eax
8010744e:	84 c0                	test   %al,%al
80107450:	75 e1                	jne    80107433 <uartinit+0xef>
    uartputc(*p);
}
80107452:	c9                   	leave  
80107453:	c3                   	ret    

80107454 <uartputc>:

void
uartputc(int c)
{
80107454:	55                   	push   %ebp
80107455:	89 e5                	mov    %esp,%ebp
80107457:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010745a:	a1 50 d6 10 80       	mov    0x8010d650,%eax
8010745f:	85 c0                	test   %eax,%eax
80107461:	75 02                	jne    80107465 <uartputc+0x11>
    return;
80107463:	eb 4b                	jmp    801074b0 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107465:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010746c:	eb 10                	jmp    8010747e <uartputc+0x2a>
    microdelay(10);
8010746e:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107475:	e8 ff c1 ff ff       	call   80103679 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010747a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010747e:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107482:	7f 16                	jg     8010749a <uartputc+0x46>
80107484:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010748b:	e8 79 fe ff ff       	call   80107309 <inb>
80107490:	0f b6 c0             	movzbl %al,%eax
80107493:	83 e0 20             	and    $0x20,%eax
80107496:	85 c0                	test   %eax,%eax
80107498:	74 d4                	je     8010746e <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
8010749a:	8b 45 08             	mov    0x8(%ebp),%eax
8010749d:	0f b6 c0             	movzbl %al,%eax
801074a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801074a4:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074ab:	e8 76 fe ff ff       	call   80107326 <outb>
}
801074b0:	c9                   	leave  
801074b1:	c3                   	ret    

801074b2 <uartgetc>:

static int
uartgetc(void)
{
801074b2:	55                   	push   %ebp
801074b3:	89 e5                	mov    %esp,%ebp
801074b5:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801074b8:	a1 50 d6 10 80       	mov    0x8010d650,%eax
801074bd:	85 c0                	test   %eax,%eax
801074bf:	75 07                	jne    801074c8 <uartgetc+0x16>
    return -1;
801074c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074c6:	eb 2c                	jmp    801074f4 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801074c8:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074cf:	e8 35 fe ff ff       	call   80107309 <inb>
801074d4:	0f b6 c0             	movzbl %al,%eax
801074d7:	83 e0 01             	and    $0x1,%eax
801074da:	85 c0                	test   %eax,%eax
801074dc:	75 07                	jne    801074e5 <uartgetc+0x33>
    return -1;
801074de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074e3:	eb 0f                	jmp    801074f4 <uartgetc+0x42>
  return inb(COM1+0);
801074e5:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074ec:	e8 18 fe ff ff       	call   80107309 <inb>
801074f1:	0f b6 c0             	movzbl %al,%eax
}
801074f4:	c9                   	leave  
801074f5:	c3                   	ret    

801074f6 <uartintr>:

void
uartintr(void)
{
801074f6:	55                   	push   %ebp
801074f7:	89 e5                	mov    %esp,%ebp
801074f9:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801074fc:	c7 04 24 b2 74 10 80 	movl   $0x801074b2,(%esp)
80107503:	e8 c0 92 ff ff       	call   801007c8 <consoleintr>
}
80107508:	c9                   	leave  
80107509:	c3                   	ret    

8010750a <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $0
8010750c:	6a 00                	push   $0x0
  jmp alltraps
8010750e:	e9 e6 f8 ff ff       	jmp    80106df9 <alltraps>

80107513 <vector1>:
.globl vector1
vector1:
  pushl $0
80107513:	6a 00                	push   $0x0
  pushl $1
80107515:	6a 01                	push   $0x1
  jmp alltraps
80107517:	e9 dd f8 ff ff       	jmp    80106df9 <alltraps>

8010751c <vector2>:
.globl vector2
vector2:
  pushl $0
8010751c:	6a 00                	push   $0x0
  pushl $2
8010751e:	6a 02                	push   $0x2
  jmp alltraps
80107520:	e9 d4 f8 ff ff       	jmp    80106df9 <alltraps>

80107525 <vector3>:
.globl vector3
vector3:
  pushl $0
80107525:	6a 00                	push   $0x0
  pushl $3
80107527:	6a 03                	push   $0x3
  jmp alltraps
80107529:	e9 cb f8 ff ff       	jmp    80106df9 <alltraps>

8010752e <vector4>:
.globl vector4
vector4:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $4
80107530:	6a 04                	push   $0x4
  jmp alltraps
80107532:	e9 c2 f8 ff ff       	jmp    80106df9 <alltraps>

80107537 <vector5>:
.globl vector5
vector5:
  pushl $0
80107537:	6a 00                	push   $0x0
  pushl $5
80107539:	6a 05                	push   $0x5
  jmp alltraps
8010753b:	e9 b9 f8 ff ff       	jmp    80106df9 <alltraps>

80107540 <vector6>:
.globl vector6
vector6:
  pushl $0
80107540:	6a 00                	push   $0x0
  pushl $6
80107542:	6a 06                	push   $0x6
  jmp alltraps
80107544:	e9 b0 f8 ff ff       	jmp    80106df9 <alltraps>

80107549 <vector7>:
.globl vector7
vector7:
  pushl $0
80107549:	6a 00                	push   $0x0
  pushl $7
8010754b:	6a 07                	push   $0x7
  jmp alltraps
8010754d:	e9 a7 f8 ff ff       	jmp    80106df9 <alltraps>

80107552 <vector8>:
.globl vector8
vector8:
  pushl $8
80107552:	6a 08                	push   $0x8
  jmp alltraps
80107554:	e9 a0 f8 ff ff       	jmp    80106df9 <alltraps>

80107559 <vector9>:
.globl vector9
vector9:
  pushl $0
80107559:	6a 00                	push   $0x0
  pushl $9
8010755b:	6a 09                	push   $0x9
  jmp alltraps
8010755d:	e9 97 f8 ff ff       	jmp    80106df9 <alltraps>

80107562 <vector10>:
.globl vector10
vector10:
  pushl $10
80107562:	6a 0a                	push   $0xa
  jmp alltraps
80107564:	e9 90 f8 ff ff       	jmp    80106df9 <alltraps>

80107569 <vector11>:
.globl vector11
vector11:
  pushl $11
80107569:	6a 0b                	push   $0xb
  jmp alltraps
8010756b:	e9 89 f8 ff ff       	jmp    80106df9 <alltraps>

80107570 <vector12>:
.globl vector12
vector12:
  pushl $12
80107570:	6a 0c                	push   $0xc
  jmp alltraps
80107572:	e9 82 f8 ff ff       	jmp    80106df9 <alltraps>

80107577 <vector13>:
.globl vector13
vector13:
  pushl $13
80107577:	6a 0d                	push   $0xd
  jmp alltraps
80107579:	e9 7b f8 ff ff       	jmp    80106df9 <alltraps>

8010757e <vector14>:
.globl vector14
vector14:
  pushl $14
8010757e:	6a 0e                	push   $0xe
  jmp alltraps
80107580:	e9 74 f8 ff ff       	jmp    80106df9 <alltraps>

80107585 <vector15>:
.globl vector15
vector15:
  pushl $0
80107585:	6a 00                	push   $0x0
  pushl $15
80107587:	6a 0f                	push   $0xf
  jmp alltraps
80107589:	e9 6b f8 ff ff       	jmp    80106df9 <alltraps>

8010758e <vector16>:
.globl vector16
vector16:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $16
80107590:	6a 10                	push   $0x10
  jmp alltraps
80107592:	e9 62 f8 ff ff       	jmp    80106df9 <alltraps>

80107597 <vector17>:
.globl vector17
vector17:
  pushl $17
80107597:	6a 11                	push   $0x11
  jmp alltraps
80107599:	e9 5b f8 ff ff       	jmp    80106df9 <alltraps>

8010759e <vector18>:
.globl vector18
vector18:
  pushl $0
8010759e:	6a 00                	push   $0x0
  pushl $18
801075a0:	6a 12                	push   $0x12
  jmp alltraps
801075a2:	e9 52 f8 ff ff       	jmp    80106df9 <alltraps>

801075a7 <vector19>:
.globl vector19
vector19:
  pushl $0
801075a7:	6a 00                	push   $0x0
  pushl $19
801075a9:	6a 13                	push   $0x13
  jmp alltraps
801075ab:	e9 49 f8 ff ff       	jmp    80106df9 <alltraps>

801075b0 <vector20>:
.globl vector20
vector20:
  pushl $0
801075b0:	6a 00                	push   $0x0
  pushl $20
801075b2:	6a 14                	push   $0x14
  jmp alltraps
801075b4:	e9 40 f8 ff ff       	jmp    80106df9 <alltraps>

801075b9 <vector21>:
.globl vector21
vector21:
  pushl $0
801075b9:	6a 00                	push   $0x0
  pushl $21
801075bb:	6a 15                	push   $0x15
  jmp alltraps
801075bd:	e9 37 f8 ff ff       	jmp    80106df9 <alltraps>

801075c2 <vector22>:
.globl vector22
vector22:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $22
801075c4:	6a 16                	push   $0x16
  jmp alltraps
801075c6:	e9 2e f8 ff ff       	jmp    80106df9 <alltraps>

801075cb <vector23>:
.globl vector23
vector23:
  pushl $0
801075cb:	6a 00                	push   $0x0
  pushl $23
801075cd:	6a 17                	push   $0x17
  jmp alltraps
801075cf:	e9 25 f8 ff ff       	jmp    80106df9 <alltraps>

801075d4 <vector24>:
.globl vector24
vector24:
  pushl $0
801075d4:	6a 00                	push   $0x0
  pushl $24
801075d6:	6a 18                	push   $0x18
  jmp alltraps
801075d8:	e9 1c f8 ff ff       	jmp    80106df9 <alltraps>

801075dd <vector25>:
.globl vector25
vector25:
  pushl $0
801075dd:	6a 00                	push   $0x0
  pushl $25
801075df:	6a 19                	push   $0x19
  jmp alltraps
801075e1:	e9 13 f8 ff ff       	jmp    80106df9 <alltraps>

801075e6 <vector26>:
.globl vector26
vector26:
  pushl $0
801075e6:	6a 00                	push   $0x0
  pushl $26
801075e8:	6a 1a                	push   $0x1a
  jmp alltraps
801075ea:	e9 0a f8 ff ff       	jmp    80106df9 <alltraps>

801075ef <vector27>:
.globl vector27
vector27:
  pushl $0
801075ef:	6a 00                	push   $0x0
  pushl $27
801075f1:	6a 1b                	push   $0x1b
  jmp alltraps
801075f3:	e9 01 f8 ff ff       	jmp    80106df9 <alltraps>

801075f8 <vector28>:
.globl vector28
vector28:
  pushl $0
801075f8:	6a 00                	push   $0x0
  pushl $28
801075fa:	6a 1c                	push   $0x1c
  jmp alltraps
801075fc:	e9 f8 f7 ff ff       	jmp    80106df9 <alltraps>

80107601 <vector29>:
.globl vector29
vector29:
  pushl $0
80107601:	6a 00                	push   $0x0
  pushl $29
80107603:	6a 1d                	push   $0x1d
  jmp alltraps
80107605:	e9 ef f7 ff ff       	jmp    80106df9 <alltraps>

8010760a <vector30>:
.globl vector30
vector30:
  pushl $0
8010760a:	6a 00                	push   $0x0
  pushl $30
8010760c:	6a 1e                	push   $0x1e
  jmp alltraps
8010760e:	e9 e6 f7 ff ff       	jmp    80106df9 <alltraps>

80107613 <vector31>:
.globl vector31
vector31:
  pushl $0
80107613:	6a 00                	push   $0x0
  pushl $31
80107615:	6a 1f                	push   $0x1f
  jmp alltraps
80107617:	e9 dd f7 ff ff       	jmp    80106df9 <alltraps>

8010761c <vector32>:
.globl vector32
vector32:
  pushl $0
8010761c:	6a 00                	push   $0x0
  pushl $32
8010761e:	6a 20                	push   $0x20
  jmp alltraps
80107620:	e9 d4 f7 ff ff       	jmp    80106df9 <alltraps>

80107625 <vector33>:
.globl vector33
vector33:
  pushl $0
80107625:	6a 00                	push   $0x0
  pushl $33
80107627:	6a 21                	push   $0x21
  jmp alltraps
80107629:	e9 cb f7 ff ff       	jmp    80106df9 <alltraps>

8010762e <vector34>:
.globl vector34
vector34:
  pushl $0
8010762e:	6a 00                	push   $0x0
  pushl $34
80107630:	6a 22                	push   $0x22
  jmp alltraps
80107632:	e9 c2 f7 ff ff       	jmp    80106df9 <alltraps>

80107637 <vector35>:
.globl vector35
vector35:
  pushl $0
80107637:	6a 00                	push   $0x0
  pushl $35
80107639:	6a 23                	push   $0x23
  jmp alltraps
8010763b:	e9 b9 f7 ff ff       	jmp    80106df9 <alltraps>

80107640 <vector36>:
.globl vector36
vector36:
  pushl $0
80107640:	6a 00                	push   $0x0
  pushl $36
80107642:	6a 24                	push   $0x24
  jmp alltraps
80107644:	e9 b0 f7 ff ff       	jmp    80106df9 <alltraps>

80107649 <vector37>:
.globl vector37
vector37:
  pushl $0
80107649:	6a 00                	push   $0x0
  pushl $37
8010764b:	6a 25                	push   $0x25
  jmp alltraps
8010764d:	e9 a7 f7 ff ff       	jmp    80106df9 <alltraps>

80107652 <vector38>:
.globl vector38
vector38:
  pushl $0
80107652:	6a 00                	push   $0x0
  pushl $38
80107654:	6a 26                	push   $0x26
  jmp alltraps
80107656:	e9 9e f7 ff ff       	jmp    80106df9 <alltraps>

8010765b <vector39>:
.globl vector39
vector39:
  pushl $0
8010765b:	6a 00                	push   $0x0
  pushl $39
8010765d:	6a 27                	push   $0x27
  jmp alltraps
8010765f:	e9 95 f7 ff ff       	jmp    80106df9 <alltraps>

80107664 <vector40>:
.globl vector40
vector40:
  pushl $0
80107664:	6a 00                	push   $0x0
  pushl $40
80107666:	6a 28                	push   $0x28
  jmp alltraps
80107668:	e9 8c f7 ff ff       	jmp    80106df9 <alltraps>

8010766d <vector41>:
.globl vector41
vector41:
  pushl $0
8010766d:	6a 00                	push   $0x0
  pushl $41
8010766f:	6a 29                	push   $0x29
  jmp alltraps
80107671:	e9 83 f7 ff ff       	jmp    80106df9 <alltraps>

80107676 <vector42>:
.globl vector42
vector42:
  pushl $0
80107676:	6a 00                	push   $0x0
  pushl $42
80107678:	6a 2a                	push   $0x2a
  jmp alltraps
8010767a:	e9 7a f7 ff ff       	jmp    80106df9 <alltraps>

8010767f <vector43>:
.globl vector43
vector43:
  pushl $0
8010767f:	6a 00                	push   $0x0
  pushl $43
80107681:	6a 2b                	push   $0x2b
  jmp alltraps
80107683:	e9 71 f7 ff ff       	jmp    80106df9 <alltraps>

80107688 <vector44>:
.globl vector44
vector44:
  pushl $0
80107688:	6a 00                	push   $0x0
  pushl $44
8010768a:	6a 2c                	push   $0x2c
  jmp alltraps
8010768c:	e9 68 f7 ff ff       	jmp    80106df9 <alltraps>

80107691 <vector45>:
.globl vector45
vector45:
  pushl $0
80107691:	6a 00                	push   $0x0
  pushl $45
80107693:	6a 2d                	push   $0x2d
  jmp alltraps
80107695:	e9 5f f7 ff ff       	jmp    80106df9 <alltraps>

8010769a <vector46>:
.globl vector46
vector46:
  pushl $0
8010769a:	6a 00                	push   $0x0
  pushl $46
8010769c:	6a 2e                	push   $0x2e
  jmp alltraps
8010769e:	e9 56 f7 ff ff       	jmp    80106df9 <alltraps>

801076a3 <vector47>:
.globl vector47
vector47:
  pushl $0
801076a3:	6a 00                	push   $0x0
  pushl $47
801076a5:	6a 2f                	push   $0x2f
  jmp alltraps
801076a7:	e9 4d f7 ff ff       	jmp    80106df9 <alltraps>

801076ac <vector48>:
.globl vector48
vector48:
  pushl $0
801076ac:	6a 00                	push   $0x0
  pushl $48
801076ae:	6a 30                	push   $0x30
  jmp alltraps
801076b0:	e9 44 f7 ff ff       	jmp    80106df9 <alltraps>

801076b5 <vector49>:
.globl vector49
vector49:
  pushl $0
801076b5:	6a 00                	push   $0x0
  pushl $49
801076b7:	6a 31                	push   $0x31
  jmp alltraps
801076b9:	e9 3b f7 ff ff       	jmp    80106df9 <alltraps>

801076be <vector50>:
.globl vector50
vector50:
  pushl $0
801076be:	6a 00                	push   $0x0
  pushl $50
801076c0:	6a 32                	push   $0x32
  jmp alltraps
801076c2:	e9 32 f7 ff ff       	jmp    80106df9 <alltraps>

801076c7 <vector51>:
.globl vector51
vector51:
  pushl $0
801076c7:	6a 00                	push   $0x0
  pushl $51
801076c9:	6a 33                	push   $0x33
  jmp alltraps
801076cb:	e9 29 f7 ff ff       	jmp    80106df9 <alltraps>

801076d0 <vector52>:
.globl vector52
vector52:
  pushl $0
801076d0:	6a 00                	push   $0x0
  pushl $52
801076d2:	6a 34                	push   $0x34
  jmp alltraps
801076d4:	e9 20 f7 ff ff       	jmp    80106df9 <alltraps>

801076d9 <vector53>:
.globl vector53
vector53:
  pushl $0
801076d9:	6a 00                	push   $0x0
  pushl $53
801076db:	6a 35                	push   $0x35
  jmp alltraps
801076dd:	e9 17 f7 ff ff       	jmp    80106df9 <alltraps>

801076e2 <vector54>:
.globl vector54
vector54:
  pushl $0
801076e2:	6a 00                	push   $0x0
  pushl $54
801076e4:	6a 36                	push   $0x36
  jmp alltraps
801076e6:	e9 0e f7 ff ff       	jmp    80106df9 <alltraps>

801076eb <vector55>:
.globl vector55
vector55:
  pushl $0
801076eb:	6a 00                	push   $0x0
  pushl $55
801076ed:	6a 37                	push   $0x37
  jmp alltraps
801076ef:	e9 05 f7 ff ff       	jmp    80106df9 <alltraps>

801076f4 <vector56>:
.globl vector56
vector56:
  pushl $0
801076f4:	6a 00                	push   $0x0
  pushl $56
801076f6:	6a 38                	push   $0x38
  jmp alltraps
801076f8:	e9 fc f6 ff ff       	jmp    80106df9 <alltraps>

801076fd <vector57>:
.globl vector57
vector57:
  pushl $0
801076fd:	6a 00                	push   $0x0
  pushl $57
801076ff:	6a 39                	push   $0x39
  jmp alltraps
80107701:	e9 f3 f6 ff ff       	jmp    80106df9 <alltraps>

80107706 <vector58>:
.globl vector58
vector58:
  pushl $0
80107706:	6a 00                	push   $0x0
  pushl $58
80107708:	6a 3a                	push   $0x3a
  jmp alltraps
8010770a:	e9 ea f6 ff ff       	jmp    80106df9 <alltraps>

8010770f <vector59>:
.globl vector59
vector59:
  pushl $0
8010770f:	6a 00                	push   $0x0
  pushl $59
80107711:	6a 3b                	push   $0x3b
  jmp alltraps
80107713:	e9 e1 f6 ff ff       	jmp    80106df9 <alltraps>

80107718 <vector60>:
.globl vector60
vector60:
  pushl $0
80107718:	6a 00                	push   $0x0
  pushl $60
8010771a:	6a 3c                	push   $0x3c
  jmp alltraps
8010771c:	e9 d8 f6 ff ff       	jmp    80106df9 <alltraps>

80107721 <vector61>:
.globl vector61
vector61:
  pushl $0
80107721:	6a 00                	push   $0x0
  pushl $61
80107723:	6a 3d                	push   $0x3d
  jmp alltraps
80107725:	e9 cf f6 ff ff       	jmp    80106df9 <alltraps>

8010772a <vector62>:
.globl vector62
vector62:
  pushl $0
8010772a:	6a 00                	push   $0x0
  pushl $62
8010772c:	6a 3e                	push   $0x3e
  jmp alltraps
8010772e:	e9 c6 f6 ff ff       	jmp    80106df9 <alltraps>

80107733 <vector63>:
.globl vector63
vector63:
  pushl $0
80107733:	6a 00                	push   $0x0
  pushl $63
80107735:	6a 3f                	push   $0x3f
  jmp alltraps
80107737:	e9 bd f6 ff ff       	jmp    80106df9 <alltraps>

8010773c <vector64>:
.globl vector64
vector64:
  pushl $0
8010773c:	6a 00                	push   $0x0
  pushl $64
8010773e:	6a 40                	push   $0x40
  jmp alltraps
80107740:	e9 b4 f6 ff ff       	jmp    80106df9 <alltraps>

80107745 <vector65>:
.globl vector65
vector65:
  pushl $0
80107745:	6a 00                	push   $0x0
  pushl $65
80107747:	6a 41                	push   $0x41
  jmp alltraps
80107749:	e9 ab f6 ff ff       	jmp    80106df9 <alltraps>

8010774e <vector66>:
.globl vector66
vector66:
  pushl $0
8010774e:	6a 00                	push   $0x0
  pushl $66
80107750:	6a 42                	push   $0x42
  jmp alltraps
80107752:	e9 a2 f6 ff ff       	jmp    80106df9 <alltraps>

80107757 <vector67>:
.globl vector67
vector67:
  pushl $0
80107757:	6a 00                	push   $0x0
  pushl $67
80107759:	6a 43                	push   $0x43
  jmp alltraps
8010775b:	e9 99 f6 ff ff       	jmp    80106df9 <alltraps>

80107760 <vector68>:
.globl vector68
vector68:
  pushl $0
80107760:	6a 00                	push   $0x0
  pushl $68
80107762:	6a 44                	push   $0x44
  jmp alltraps
80107764:	e9 90 f6 ff ff       	jmp    80106df9 <alltraps>

80107769 <vector69>:
.globl vector69
vector69:
  pushl $0
80107769:	6a 00                	push   $0x0
  pushl $69
8010776b:	6a 45                	push   $0x45
  jmp alltraps
8010776d:	e9 87 f6 ff ff       	jmp    80106df9 <alltraps>

80107772 <vector70>:
.globl vector70
vector70:
  pushl $0
80107772:	6a 00                	push   $0x0
  pushl $70
80107774:	6a 46                	push   $0x46
  jmp alltraps
80107776:	e9 7e f6 ff ff       	jmp    80106df9 <alltraps>

8010777b <vector71>:
.globl vector71
vector71:
  pushl $0
8010777b:	6a 00                	push   $0x0
  pushl $71
8010777d:	6a 47                	push   $0x47
  jmp alltraps
8010777f:	e9 75 f6 ff ff       	jmp    80106df9 <alltraps>

80107784 <vector72>:
.globl vector72
vector72:
  pushl $0
80107784:	6a 00                	push   $0x0
  pushl $72
80107786:	6a 48                	push   $0x48
  jmp alltraps
80107788:	e9 6c f6 ff ff       	jmp    80106df9 <alltraps>

8010778d <vector73>:
.globl vector73
vector73:
  pushl $0
8010778d:	6a 00                	push   $0x0
  pushl $73
8010778f:	6a 49                	push   $0x49
  jmp alltraps
80107791:	e9 63 f6 ff ff       	jmp    80106df9 <alltraps>

80107796 <vector74>:
.globl vector74
vector74:
  pushl $0
80107796:	6a 00                	push   $0x0
  pushl $74
80107798:	6a 4a                	push   $0x4a
  jmp alltraps
8010779a:	e9 5a f6 ff ff       	jmp    80106df9 <alltraps>

8010779f <vector75>:
.globl vector75
vector75:
  pushl $0
8010779f:	6a 00                	push   $0x0
  pushl $75
801077a1:	6a 4b                	push   $0x4b
  jmp alltraps
801077a3:	e9 51 f6 ff ff       	jmp    80106df9 <alltraps>

801077a8 <vector76>:
.globl vector76
vector76:
  pushl $0
801077a8:	6a 00                	push   $0x0
  pushl $76
801077aa:	6a 4c                	push   $0x4c
  jmp alltraps
801077ac:	e9 48 f6 ff ff       	jmp    80106df9 <alltraps>

801077b1 <vector77>:
.globl vector77
vector77:
  pushl $0
801077b1:	6a 00                	push   $0x0
  pushl $77
801077b3:	6a 4d                	push   $0x4d
  jmp alltraps
801077b5:	e9 3f f6 ff ff       	jmp    80106df9 <alltraps>

801077ba <vector78>:
.globl vector78
vector78:
  pushl $0
801077ba:	6a 00                	push   $0x0
  pushl $78
801077bc:	6a 4e                	push   $0x4e
  jmp alltraps
801077be:	e9 36 f6 ff ff       	jmp    80106df9 <alltraps>

801077c3 <vector79>:
.globl vector79
vector79:
  pushl $0
801077c3:	6a 00                	push   $0x0
  pushl $79
801077c5:	6a 4f                	push   $0x4f
  jmp alltraps
801077c7:	e9 2d f6 ff ff       	jmp    80106df9 <alltraps>

801077cc <vector80>:
.globl vector80
vector80:
  pushl $0
801077cc:	6a 00                	push   $0x0
  pushl $80
801077ce:	6a 50                	push   $0x50
  jmp alltraps
801077d0:	e9 24 f6 ff ff       	jmp    80106df9 <alltraps>

801077d5 <vector81>:
.globl vector81
vector81:
  pushl $0
801077d5:	6a 00                	push   $0x0
  pushl $81
801077d7:	6a 51                	push   $0x51
  jmp alltraps
801077d9:	e9 1b f6 ff ff       	jmp    80106df9 <alltraps>

801077de <vector82>:
.globl vector82
vector82:
  pushl $0
801077de:	6a 00                	push   $0x0
  pushl $82
801077e0:	6a 52                	push   $0x52
  jmp alltraps
801077e2:	e9 12 f6 ff ff       	jmp    80106df9 <alltraps>

801077e7 <vector83>:
.globl vector83
vector83:
  pushl $0
801077e7:	6a 00                	push   $0x0
  pushl $83
801077e9:	6a 53                	push   $0x53
  jmp alltraps
801077eb:	e9 09 f6 ff ff       	jmp    80106df9 <alltraps>

801077f0 <vector84>:
.globl vector84
vector84:
  pushl $0
801077f0:	6a 00                	push   $0x0
  pushl $84
801077f2:	6a 54                	push   $0x54
  jmp alltraps
801077f4:	e9 00 f6 ff ff       	jmp    80106df9 <alltraps>

801077f9 <vector85>:
.globl vector85
vector85:
  pushl $0
801077f9:	6a 00                	push   $0x0
  pushl $85
801077fb:	6a 55                	push   $0x55
  jmp alltraps
801077fd:	e9 f7 f5 ff ff       	jmp    80106df9 <alltraps>

80107802 <vector86>:
.globl vector86
vector86:
  pushl $0
80107802:	6a 00                	push   $0x0
  pushl $86
80107804:	6a 56                	push   $0x56
  jmp alltraps
80107806:	e9 ee f5 ff ff       	jmp    80106df9 <alltraps>

8010780b <vector87>:
.globl vector87
vector87:
  pushl $0
8010780b:	6a 00                	push   $0x0
  pushl $87
8010780d:	6a 57                	push   $0x57
  jmp alltraps
8010780f:	e9 e5 f5 ff ff       	jmp    80106df9 <alltraps>

80107814 <vector88>:
.globl vector88
vector88:
  pushl $0
80107814:	6a 00                	push   $0x0
  pushl $88
80107816:	6a 58                	push   $0x58
  jmp alltraps
80107818:	e9 dc f5 ff ff       	jmp    80106df9 <alltraps>

8010781d <vector89>:
.globl vector89
vector89:
  pushl $0
8010781d:	6a 00                	push   $0x0
  pushl $89
8010781f:	6a 59                	push   $0x59
  jmp alltraps
80107821:	e9 d3 f5 ff ff       	jmp    80106df9 <alltraps>

80107826 <vector90>:
.globl vector90
vector90:
  pushl $0
80107826:	6a 00                	push   $0x0
  pushl $90
80107828:	6a 5a                	push   $0x5a
  jmp alltraps
8010782a:	e9 ca f5 ff ff       	jmp    80106df9 <alltraps>

8010782f <vector91>:
.globl vector91
vector91:
  pushl $0
8010782f:	6a 00                	push   $0x0
  pushl $91
80107831:	6a 5b                	push   $0x5b
  jmp alltraps
80107833:	e9 c1 f5 ff ff       	jmp    80106df9 <alltraps>

80107838 <vector92>:
.globl vector92
vector92:
  pushl $0
80107838:	6a 00                	push   $0x0
  pushl $92
8010783a:	6a 5c                	push   $0x5c
  jmp alltraps
8010783c:	e9 b8 f5 ff ff       	jmp    80106df9 <alltraps>

80107841 <vector93>:
.globl vector93
vector93:
  pushl $0
80107841:	6a 00                	push   $0x0
  pushl $93
80107843:	6a 5d                	push   $0x5d
  jmp alltraps
80107845:	e9 af f5 ff ff       	jmp    80106df9 <alltraps>

8010784a <vector94>:
.globl vector94
vector94:
  pushl $0
8010784a:	6a 00                	push   $0x0
  pushl $94
8010784c:	6a 5e                	push   $0x5e
  jmp alltraps
8010784e:	e9 a6 f5 ff ff       	jmp    80106df9 <alltraps>

80107853 <vector95>:
.globl vector95
vector95:
  pushl $0
80107853:	6a 00                	push   $0x0
  pushl $95
80107855:	6a 5f                	push   $0x5f
  jmp alltraps
80107857:	e9 9d f5 ff ff       	jmp    80106df9 <alltraps>

8010785c <vector96>:
.globl vector96
vector96:
  pushl $0
8010785c:	6a 00                	push   $0x0
  pushl $96
8010785e:	6a 60                	push   $0x60
  jmp alltraps
80107860:	e9 94 f5 ff ff       	jmp    80106df9 <alltraps>

80107865 <vector97>:
.globl vector97
vector97:
  pushl $0
80107865:	6a 00                	push   $0x0
  pushl $97
80107867:	6a 61                	push   $0x61
  jmp alltraps
80107869:	e9 8b f5 ff ff       	jmp    80106df9 <alltraps>

8010786e <vector98>:
.globl vector98
vector98:
  pushl $0
8010786e:	6a 00                	push   $0x0
  pushl $98
80107870:	6a 62                	push   $0x62
  jmp alltraps
80107872:	e9 82 f5 ff ff       	jmp    80106df9 <alltraps>

80107877 <vector99>:
.globl vector99
vector99:
  pushl $0
80107877:	6a 00                	push   $0x0
  pushl $99
80107879:	6a 63                	push   $0x63
  jmp alltraps
8010787b:	e9 79 f5 ff ff       	jmp    80106df9 <alltraps>

80107880 <vector100>:
.globl vector100
vector100:
  pushl $0
80107880:	6a 00                	push   $0x0
  pushl $100
80107882:	6a 64                	push   $0x64
  jmp alltraps
80107884:	e9 70 f5 ff ff       	jmp    80106df9 <alltraps>

80107889 <vector101>:
.globl vector101
vector101:
  pushl $0
80107889:	6a 00                	push   $0x0
  pushl $101
8010788b:	6a 65                	push   $0x65
  jmp alltraps
8010788d:	e9 67 f5 ff ff       	jmp    80106df9 <alltraps>

80107892 <vector102>:
.globl vector102
vector102:
  pushl $0
80107892:	6a 00                	push   $0x0
  pushl $102
80107894:	6a 66                	push   $0x66
  jmp alltraps
80107896:	e9 5e f5 ff ff       	jmp    80106df9 <alltraps>

8010789b <vector103>:
.globl vector103
vector103:
  pushl $0
8010789b:	6a 00                	push   $0x0
  pushl $103
8010789d:	6a 67                	push   $0x67
  jmp alltraps
8010789f:	e9 55 f5 ff ff       	jmp    80106df9 <alltraps>

801078a4 <vector104>:
.globl vector104
vector104:
  pushl $0
801078a4:	6a 00                	push   $0x0
  pushl $104
801078a6:	6a 68                	push   $0x68
  jmp alltraps
801078a8:	e9 4c f5 ff ff       	jmp    80106df9 <alltraps>

801078ad <vector105>:
.globl vector105
vector105:
  pushl $0
801078ad:	6a 00                	push   $0x0
  pushl $105
801078af:	6a 69                	push   $0x69
  jmp alltraps
801078b1:	e9 43 f5 ff ff       	jmp    80106df9 <alltraps>

801078b6 <vector106>:
.globl vector106
vector106:
  pushl $0
801078b6:	6a 00                	push   $0x0
  pushl $106
801078b8:	6a 6a                	push   $0x6a
  jmp alltraps
801078ba:	e9 3a f5 ff ff       	jmp    80106df9 <alltraps>

801078bf <vector107>:
.globl vector107
vector107:
  pushl $0
801078bf:	6a 00                	push   $0x0
  pushl $107
801078c1:	6a 6b                	push   $0x6b
  jmp alltraps
801078c3:	e9 31 f5 ff ff       	jmp    80106df9 <alltraps>

801078c8 <vector108>:
.globl vector108
vector108:
  pushl $0
801078c8:	6a 00                	push   $0x0
  pushl $108
801078ca:	6a 6c                	push   $0x6c
  jmp alltraps
801078cc:	e9 28 f5 ff ff       	jmp    80106df9 <alltraps>

801078d1 <vector109>:
.globl vector109
vector109:
  pushl $0
801078d1:	6a 00                	push   $0x0
  pushl $109
801078d3:	6a 6d                	push   $0x6d
  jmp alltraps
801078d5:	e9 1f f5 ff ff       	jmp    80106df9 <alltraps>

801078da <vector110>:
.globl vector110
vector110:
  pushl $0
801078da:	6a 00                	push   $0x0
  pushl $110
801078dc:	6a 6e                	push   $0x6e
  jmp alltraps
801078de:	e9 16 f5 ff ff       	jmp    80106df9 <alltraps>

801078e3 <vector111>:
.globl vector111
vector111:
  pushl $0
801078e3:	6a 00                	push   $0x0
  pushl $111
801078e5:	6a 6f                	push   $0x6f
  jmp alltraps
801078e7:	e9 0d f5 ff ff       	jmp    80106df9 <alltraps>

801078ec <vector112>:
.globl vector112
vector112:
  pushl $0
801078ec:	6a 00                	push   $0x0
  pushl $112
801078ee:	6a 70                	push   $0x70
  jmp alltraps
801078f0:	e9 04 f5 ff ff       	jmp    80106df9 <alltraps>

801078f5 <vector113>:
.globl vector113
vector113:
  pushl $0
801078f5:	6a 00                	push   $0x0
  pushl $113
801078f7:	6a 71                	push   $0x71
  jmp alltraps
801078f9:	e9 fb f4 ff ff       	jmp    80106df9 <alltraps>

801078fe <vector114>:
.globl vector114
vector114:
  pushl $0
801078fe:	6a 00                	push   $0x0
  pushl $114
80107900:	6a 72                	push   $0x72
  jmp alltraps
80107902:	e9 f2 f4 ff ff       	jmp    80106df9 <alltraps>

80107907 <vector115>:
.globl vector115
vector115:
  pushl $0
80107907:	6a 00                	push   $0x0
  pushl $115
80107909:	6a 73                	push   $0x73
  jmp alltraps
8010790b:	e9 e9 f4 ff ff       	jmp    80106df9 <alltraps>

80107910 <vector116>:
.globl vector116
vector116:
  pushl $0
80107910:	6a 00                	push   $0x0
  pushl $116
80107912:	6a 74                	push   $0x74
  jmp alltraps
80107914:	e9 e0 f4 ff ff       	jmp    80106df9 <alltraps>

80107919 <vector117>:
.globl vector117
vector117:
  pushl $0
80107919:	6a 00                	push   $0x0
  pushl $117
8010791b:	6a 75                	push   $0x75
  jmp alltraps
8010791d:	e9 d7 f4 ff ff       	jmp    80106df9 <alltraps>

80107922 <vector118>:
.globl vector118
vector118:
  pushl $0
80107922:	6a 00                	push   $0x0
  pushl $118
80107924:	6a 76                	push   $0x76
  jmp alltraps
80107926:	e9 ce f4 ff ff       	jmp    80106df9 <alltraps>

8010792b <vector119>:
.globl vector119
vector119:
  pushl $0
8010792b:	6a 00                	push   $0x0
  pushl $119
8010792d:	6a 77                	push   $0x77
  jmp alltraps
8010792f:	e9 c5 f4 ff ff       	jmp    80106df9 <alltraps>

80107934 <vector120>:
.globl vector120
vector120:
  pushl $0
80107934:	6a 00                	push   $0x0
  pushl $120
80107936:	6a 78                	push   $0x78
  jmp alltraps
80107938:	e9 bc f4 ff ff       	jmp    80106df9 <alltraps>

8010793d <vector121>:
.globl vector121
vector121:
  pushl $0
8010793d:	6a 00                	push   $0x0
  pushl $121
8010793f:	6a 79                	push   $0x79
  jmp alltraps
80107941:	e9 b3 f4 ff ff       	jmp    80106df9 <alltraps>

80107946 <vector122>:
.globl vector122
vector122:
  pushl $0
80107946:	6a 00                	push   $0x0
  pushl $122
80107948:	6a 7a                	push   $0x7a
  jmp alltraps
8010794a:	e9 aa f4 ff ff       	jmp    80106df9 <alltraps>

8010794f <vector123>:
.globl vector123
vector123:
  pushl $0
8010794f:	6a 00                	push   $0x0
  pushl $123
80107951:	6a 7b                	push   $0x7b
  jmp alltraps
80107953:	e9 a1 f4 ff ff       	jmp    80106df9 <alltraps>

80107958 <vector124>:
.globl vector124
vector124:
  pushl $0
80107958:	6a 00                	push   $0x0
  pushl $124
8010795a:	6a 7c                	push   $0x7c
  jmp alltraps
8010795c:	e9 98 f4 ff ff       	jmp    80106df9 <alltraps>

80107961 <vector125>:
.globl vector125
vector125:
  pushl $0
80107961:	6a 00                	push   $0x0
  pushl $125
80107963:	6a 7d                	push   $0x7d
  jmp alltraps
80107965:	e9 8f f4 ff ff       	jmp    80106df9 <alltraps>

8010796a <vector126>:
.globl vector126
vector126:
  pushl $0
8010796a:	6a 00                	push   $0x0
  pushl $126
8010796c:	6a 7e                	push   $0x7e
  jmp alltraps
8010796e:	e9 86 f4 ff ff       	jmp    80106df9 <alltraps>

80107973 <vector127>:
.globl vector127
vector127:
  pushl $0
80107973:	6a 00                	push   $0x0
  pushl $127
80107975:	6a 7f                	push   $0x7f
  jmp alltraps
80107977:	e9 7d f4 ff ff       	jmp    80106df9 <alltraps>

8010797c <vector128>:
.globl vector128
vector128:
  pushl $0
8010797c:	6a 00                	push   $0x0
  pushl $128
8010797e:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107983:	e9 71 f4 ff ff       	jmp    80106df9 <alltraps>

80107988 <vector129>:
.globl vector129
vector129:
  pushl $0
80107988:	6a 00                	push   $0x0
  pushl $129
8010798a:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010798f:	e9 65 f4 ff ff       	jmp    80106df9 <alltraps>

80107994 <vector130>:
.globl vector130
vector130:
  pushl $0
80107994:	6a 00                	push   $0x0
  pushl $130
80107996:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010799b:	e9 59 f4 ff ff       	jmp    80106df9 <alltraps>

801079a0 <vector131>:
.globl vector131
vector131:
  pushl $0
801079a0:	6a 00                	push   $0x0
  pushl $131
801079a2:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801079a7:	e9 4d f4 ff ff       	jmp    80106df9 <alltraps>

801079ac <vector132>:
.globl vector132
vector132:
  pushl $0
801079ac:	6a 00                	push   $0x0
  pushl $132
801079ae:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801079b3:	e9 41 f4 ff ff       	jmp    80106df9 <alltraps>

801079b8 <vector133>:
.globl vector133
vector133:
  pushl $0
801079b8:	6a 00                	push   $0x0
  pushl $133
801079ba:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801079bf:	e9 35 f4 ff ff       	jmp    80106df9 <alltraps>

801079c4 <vector134>:
.globl vector134
vector134:
  pushl $0
801079c4:	6a 00                	push   $0x0
  pushl $134
801079c6:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801079cb:	e9 29 f4 ff ff       	jmp    80106df9 <alltraps>

801079d0 <vector135>:
.globl vector135
vector135:
  pushl $0
801079d0:	6a 00                	push   $0x0
  pushl $135
801079d2:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079d7:	e9 1d f4 ff ff       	jmp    80106df9 <alltraps>

801079dc <vector136>:
.globl vector136
vector136:
  pushl $0
801079dc:	6a 00                	push   $0x0
  pushl $136
801079de:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801079e3:	e9 11 f4 ff ff       	jmp    80106df9 <alltraps>

801079e8 <vector137>:
.globl vector137
vector137:
  pushl $0
801079e8:	6a 00                	push   $0x0
  pushl $137
801079ea:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801079ef:	e9 05 f4 ff ff       	jmp    80106df9 <alltraps>

801079f4 <vector138>:
.globl vector138
vector138:
  pushl $0
801079f4:	6a 00                	push   $0x0
  pushl $138
801079f6:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801079fb:	e9 f9 f3 ff ff       	jmp    80106df9 <alltraps>

80107a00 <vector139>:
.globl vector139
vector139:
  pushl $0
80107a00:	6a 00                	push   $0x0
  pushl $139
80107a02:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107a07:	e9 ed f3 ff ff       	jmp    80106df9 <alltraps>

80107a0c <vector140>:
.globl vector140
vector140:
  pushl $0
80107a0c:	6a 00                	push   $0x0
  pushl $140
80107a0e:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107a13:	e9 e1 f3 ff ff       	jmp    80106df9 <alltraps>

80107a18 <vector141>:
.globl vector141
vector141:
  pushl $0
80107a18:	6a 00                	push   $0x0
  pushl $141
80107a1a:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107a1f:	e9 d5 f3 ff ff       	jmp    80106df9 <alltraps>

80107a24 <vector142>:
.globl vector142
vector142:
  pushl $0
80107a24:	6a 00                	push   $0x0
  pushl $142
80107a26:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107a2b:	e9 c9 f3 ff ff       	jmp    80106df9 <alltraps>

80107a30 <vector143>:
.globl vector143
vector143:
  pushl $0
80107a30:	6a 00                	push   $0x0
  pushl $143
80107a32:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a37:	e9 bd f3 ff ff       	jmp    80106df9 <alltraps>

80107a3c <vector144>:
.globl vector144
vector144:
  pushl $0
80107a3c:	6a 00                	push   $0x0
  pushl $144
80107a3e:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a43:	e9 b1 f3 ff ff       	jmp    80106df9 <alltraps>

80107a48 <vector145>:
.globl vector145
vector145:
  pushl $0
80107a48:	6a 00                	push   $0x0
  pushl $145
80107a4a:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a4f:	e9 a5 f3 ff ff       	jmp    80106df9 <alltraps>

80107a54 <vector146>:
.globl vector146
vector146:
  pushl $0
80107a54:	6a 00                	push   $0x0
  pushl $146
80107a56:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a5b:	e9 99 f3 ff ff       	jmp    80106df9 <alltraps>

80107a60 <vector147>:
.globl vector147
vector147:
  pushl $0
80107a60:	6a 00                	push   $0x0
  pushl $147
80107a62:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a67:	e9 8d f3 ff ff       	jmp    80106df9 <alltraps>

80107a6c <vector148>:
.globl vector148
vector148:
  pushl $0
80107a6c:	6a 00                	push   $0x0
  pushl $148
80107a6e:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a73:	e9 81 f3 ff ff       	jmp    80106df9 <alltraps>

80107a78 <vector149>:
.globl vector149
vector149:
  pushl $0
80107a78:	6a 00                	push   $0x0
  pushl $149
80107a7a:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107a7f:	e9 75 f3 ff ff       	jmp    80106df9 <alltraps>

80107a84 <vector150>:
.globl vector150
vector150:
  pushl $0
80107a84:	6a 00                	push   $0x0
  pushl $150
80107a86:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107a8b:	e9 69 f3 ff ff       	jmp    80106df9 <alltraps>

80107a90 <vector151>:
.globl vector151
vector151:
  pushl $0
80107a90:	6a 00                	push   $0x0
  pushl $151
80107a92:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107a97:	e9 5d f3 ff ff       	jmp    80106df9 <alltraps>

80107a9c <vector152>:
.globl vector152
vector152:
  pushl $0
80107a9c:	6a 00                	push   $0x0
  pushl $152
80107a9e:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107aa3:	e9 51 f3 ff ff       	jmp    80106df9 <alltraps>

80107aa8 <vector153>:
.globl vector153
vector153:
  pushl $0
80107aa8:	6a 00                	push   $0x0
  pushl $153
80107aaa:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107aaf:	e9 45 f3 ff ff       	jmp    80106df9 <alltraps>

80107ab4 <vector154>:
.globl vector154
vector154:
  pushl $0
80107ab4:	6a 00                	push   $0x0
  pushl $154
80107ab6:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107abb:	e9 39 f3 ff ff       	jmp    80106df9 <alltraps>

80107ac0 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ac0:	6a 00                	push   $0x0
  pushl $155
80107ac2:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ac7:	e9 2d f3 ff ff       	jmp    80106df9 <alltraps>

80107acc <vector156>:
.globl vector156
vector156:
  pushl $0
80107acc:	6a 00                	push   $0x0
  pushl $156
80107ace:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107ad3:	e9 21 f3 ff ff       	jmp    80106df9 <alltraps>

80107ad8 <vector157>:
.globl vector157
vector157:
  pushl $0
80107ad8:	6a 00                	push   $0x0
  pushl $157
80107ada:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107adf:	e9 15 f3 ff ff       	jmp    80106df9 <alltraps>

80107ae4 <vector158>:
.globl vector158
vector158:
  pushl $0
80107ae4:	6a 00                	push   $0x0
  pushl $158
80107ae6:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107aeb:	e9 09 f3 ff ff       	jmp    80106df9 <alltraps>

80107af0 <vector159>:
.globl vector159
vector159:
  pushl $0
80107af0:	6a 00                	push   $0x0
  pushl $159
80107af2:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107af7:	e9 fd f2 ff ff       	jmp    80106df9 <alltraps>

80107afc <vector160>:
.globl vector160
vector160:
  pushl $0
80107afc:	6a 00                	push   $0x0
  pushl $160
80107afe:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107b03:	e9 f1 f2 ff ff       	jmp    80106df9 <alltraps>

80107b08 <vector161>:
.globl vector161
vector161:
  pushl $0
80107b08:	6a 00                	push   $0x0
  pushl $161
80107b0a:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107b0f:	e9 e5 f2 ff ff       	jmp    80106df9 <alltraps>

80107b14 <vector162>:
.globl vector162
vector162:
  pushl $0
80107b14:	6a 00                	push   $0x0
  pushl $162
80107b16:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107b1b:	e9 d9 f2 ff ff       	jmp    80106df9 <alltraps>

80107b20 <vector163>:
.globl vector163
vector163:
  pushl $0
80107b20:	6a 00                	push   $0x0
  pushl $163
80107b22:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107b27:	e9 cd f2 ff ff       	jmp    80106df9 <alltraps>

80107b2c <vector164>:
.globl vector164
vector164:
  pushl $0
80107b2c:	6a 00                	push   $0x0
  pushl $164
80107b2e:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b33:	e9 c1 f2 ff ff       	jmp    80106df9 <alltraps>

80107b38 <vector165>:
.globl vector165
vector165:
  pushl $0
80107b38:	6a 00                	push   $0x0
  pushl $165
80107b3a:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b3f:	e9 b5 f2 ff ff       	jmp    80106df9 <alltraps>

80107b44 <vector166>:
.globl vector166
vector166:
  pushl $0
80107b44:	6a 00                	push   $0x0
  pushl $166
80107b46:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b4b:	e9 a9 f2 ff ff       	jmp    80106df9 <alltraps>

80107b50 <vector167>:
.globl vector167
vector167:
  pushl $0
80107b50:	6a 00                	push   $0x0
  pushl $167
80107b52:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b57:	e9 9d f2 ff ff       	jmp    80106df9 <alltraps>

80107b5c <vector168>:
.globl vector168
vector168:
  pushl $0
80107b5c:	6a 00                	push   $0x0
  pushl $168
80107b5e:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b63:	e9 91 f2 ff ff       	jmp    80106df9 <alltraps>

80107b68 <vector169>:
.globl vector169
vector169:
  pushl $0
80107b68:	6a 00                	push   $0x0
  pushl $169
80107b6a:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b6f:	e9 85 f2 ff ff       	jmp    80106df9 <alltraps>

80107b74 <vector170>:
.globl vector170
vector170:
  pushl $0
80107b74:	6a 00                	push   $0x0
  pushl $170
80107b76:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b7b:	e9 79 f2 ff ff       	jmp    80106df9 <alltraps>

80107b80 <vector171>:
.globl vector171
vector171:
  pushl $0
80107b80:	6a 00                	push   $0x0
  pushl $171
80107b82:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107b87:	e9 6d f2 ff ff       	jmp    80106df9 <alltraps>

80107b8c <vector172>:
.globl vector172
vector172:
  pushl $0
80107b8c:	6a 00                	push   $0x0
  pushl $172
80107b8e:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107b93:	e9 61 f2 ff ff       	jmp    80106df9 <alltraps>

80107b98 <vector173>:
.globl vector173
vector173:
  pushl $0
80107b98:	6a 00                	push   $0x0
  pushl $173
80107b9a:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107b9f:	e9 55 f2 ff ff       	jmp    80106df9 <alltraps>

80107ba4 <vector174>:
.globl vector174
vector174:
  pushl $0
80107ba4:	6a 00                	push   $0x0
  pushl $174
80107ba6:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107bab:	e9 49 f2 ff ff       	jmp    80106df9 <alltraps>

80107bb0 <vector175>:
.globl vector175
vector175:
  pushl $0
80107bb0:	6a 00                	push   $0x0
  pushl $175
80107bb2:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107bb7:	e9 3d f2 ff ff       	jmp    80106df9 <alltraps>

80107bbc <vector176>:
.globl vector176
vector176:
  pushl $0
80107bbc:	6a 00                	push   $0x0
  pushl $176
80107bbe:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107bc3:	e9 31 f2 ff ff       	jmp    80106df9 <alltraps>

80107bc8 <vector177>:
.globl vector177
vector177:
  pushl $0
80107bc8:	6a 00                	push   $0x0
  pushl $177
80107bca:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107bcf:	e9 25 f2 ff ff       	jmp    80106df9 <alltraps>

80107bd4 <vector178>:
.globl vector178
vector178:
  pushl $0
80107bd4:	6a 00                	push   $0x0
  pushl $178
80107bd6:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107bdb:	e9 19 f2 ff ff       	jmp    80106df9 <alltraps>

80107be0 <vector179>:
.globl vector179
vector179:
  pushl $0
80107be0:	6a 00                	push   $0x0
  pushl $179
80107be2:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107be7:	e9 0d f2 ff ff       	jmp    80106df9 <alltraps>

80107bec <vector180>:
.globl vector180
vector180:
  pushl $0
80107bec:	6a 00                	push   $0x0
  pushl $180
80107bee:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107bf3:	e9 01 f2 ff ff       	jmp    80106df9 <alltraps>

80107bf8 <vector181>:
.globl vector181
vector181:
  pushl $0
80107bf8:	6a 00                	push   $0x0
  pushl $181
80107bfa:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107bff:	e9 f5 f1 ff ff       	jmp    80106df9 <alltraps>

80107c04 <vector182>:
.globl vector182
vector182:
  pushl $0
80107c04:	6a 00                	push   $0x0
  pushl $182
80107c06:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107c0b:	e9 e9 f1 ff ff       	jmp    80106df9 <alltraps>

80107c10 <vector183>:
.globl vector183
vector183:
  pushl $0
80107c10:	6a 00                	push   $0x0
  pushl $183
80107c12:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107c17:	e9 dd f1 ff ff       	jmp    80106df9 <alltraps>

80107c1c <vector184>:
.globl vector184
vector184:
  pushl $0
80107c1c:	6a 00                	push   $0x0
  pushl $184
80107c1e:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107c23:	e9 d1 f1 ff ff       	jmp    80106df9 <alltraps>

80107c28 <vector185>:
.globl vector185
vector185:
  pushl $0
80107c28:	6a 00                	push   $0x0
  pushl $185
80107c2a:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c2f:	e9 c5 f1 ff ff       	jmp    80106df9 <alltraps>

80107c34 <vector186>:
.globl vector186
vector186:
  pushl $0
80107c34:	6a 00                	push   $0x0
  pushl $186
80107c36:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c3b:	e9 b9 f1 ff ff       	jmp    80106df9 <alltraps>

80107c40 <vector187>:
.globl vector187
vector187:
  pushl $0
80107c40:	6a 00                	push   $0x0
  pushl $187
80107c42:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c47:	e9 ad f1 ff ff       	jmp    80106df9 <alltraps>

80107c4c <vector188>:
.globl vector188
vector188:
  pushl $0
80107c4c:	6a 00                	push   $0x0
  pushl $188
80107c4e:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c53:	e9 a1 f1 ff ff       	jmp    80106df9 <alltraps>

80107c58 <vector189>:
.globl vector189
vector189:
  pushl $0
80107c58:	6a 00                	push   $0x0
  pushl $189
80107c5a:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c5f:	e9 95 f1 ff ff       	jmp    80106df9 <alltraps>

80107c64 <vector190>:
.globl vector190
vector190:
  pushl $0
80107c64:	6a 00                	push   $0x0
  pushl $190
80107c66:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c6b:	e9 89 f1 ff ff       	jmp    80106df9 <alltraps>

80107c70 <vector191>:
.globl vector191
vector191:
  pushl $0
80107c70:	6a 00                	push   $0x0
  pushl $191
80107c72:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c77:	e9 7d f1 ff ff       	jmp    80106df9 <alltraps>

80107c7c <vector192>:
.globl vector192
vector192:
  pushl $0
80107c7c:	6a 00                	push   $0x0
  pushl $192
80107c7e:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107c83:	e9 71 f1 ff ff       	jmp    80106df9 <alltraps>

80107c88 <vector193>:
.globl vector193
vector193:
  pushl $0
80107c88:	6a 00                	push   $0x0
  pushl $193
80107c8a:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107c8f:	e9 65 f1 ff ff       	jmp    80106df9 <alltraps>

80107c94 <vector194>:
.globl vector194
vector194:
  pushl $0
80107c94:	6a 00                	push   $0x0
  pushl $194
80107c96:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107c9b:	e9 59 f1 ff ff       	jmp    80106df9 <alltraps>

80107ca0 <vector195>:
.globl vector195
vector195:
  pushl $0
80107ca0:	6a 00                	push   $0x0
  pushl $195
80107ca2:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107ca7:	e9 4d f1 ff ff       	jmp    80106df9 <alltraps>

80107cac <vector196>:
.globl vector196
vector196:
  pushl $0
80107cac:	6a 00                	push   $0x0
  pushl $196
80107cae:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107cb3:	e9 41 f1 ff ff       	jmp    80106df9 <alltraps>

80107cb8 <vector197>:
.globl vector197
vector197:
  pushl $0
80107cb8:	6a 00                	push   $0x0
  pushl $197
80107cba:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107cbf:	e9 35 f1 ff ff       	jmp    80106df9 <alltraps>

80107cc4 <vector198>:
.globl vector198
vector198:
  pushl $0
80107cc4:	6a 00                	push   $0x0
  pushl $198
80107cc6:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107ccb:	e9 29 f1 ff ff       	jmp    80106df9 <alltraps>

80107cd0 <vector199>:
.globl vector199
vector199:
  pushl $0
80107cd0:	6a 00                	push   $0x0
  pushl $199
80107cd2:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107cd7:	e9 1d f1 ff ff       	jmp    80106df9 <alltraps>

80107cdc <vector200>:
.globl vector200
vector200:
  pushl $0
80107cdc:	6a 00                	push   $0x0
  pushl $200
80107cde:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107ce3:	e9 11 f1 ff ff       	jmp    80106df9 <alltraps>

80107ce8 <vector201>:
.globl vector201
vector201:
  pushl $0
80107ce8:	6a 00                	push   $0x0
  pushl $201
80107cea:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107cef:	e9 05 f1 ff ff       	jmp    80106df9 <alltraps>

80107cf4 <vector202>:
.globl vector202
vector202:
  pushl $0
80107cf4:	6a 00                	push   $0x0
  pushl $202
80107cf6:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107cfb:	e9 f9 f0 ff ff       	jmp    80106df9 <alltraps>

80107d00 <vector203>:
.globl vector203
vector203:
  pushl $0
80107d00:	6a 00                	push   $0x0
  pushl $203
80107d02:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107d07:	e9 ed f0 ff ff       	jmp    80106df9 <alltraps>

80107d0c <vector204>:
.globl vector204
vector204:
  pushl $0
80107d0c:	6a 00                	push   $0x0
  pushl $204
80107d0e:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107d13:	e9 e1 f0 ff ff       	jmp    80106df9 <alltraps>

80107d18 <vector205>:
.globl vector205
vector205:
  pushl $0
80107d18:	6a 00                	push   $0x0
  pushl $205
80107d1a:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107d1f:	e9 d5 f0 ff ff       	jmp    80106df9 <alltraps>

80107d24 <vector206>:
.globl vector206
vector206:
  pushl $0
80107d24:	6a 00                	push   $0x0
  pushl $206
80107d26:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107d2b:	e9 c9 f0 ff ff       	jmp    80106df9 <alltraps>

80107d30 <vector207>:
.globl vector207
vector207:
  pushl $0
80107d30:	6a 00                	push   $0x0
  pushl $207
80107d32:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d37:	e9 bd f0 ff ff       	jmp    80106df9 <alltraps>

80107d3c <vector208>:
.globl vector208
vector208:
  pushl $0
80107d3c:	6a 00                	push   $0x0
  pushl $208
80107d3e:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d43:	e9 b1 f0 ff ff       	jmp    80106df9 <alltraps>

80107d48 <vector209>:
.globl vector209
vector209:
  pushl $0
80107d48:	6a 00                	push   $0x0
  pushl $209
80107d4a:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d4f:	e9 a5 f0 ff ff       	jmp    80106df9 <alltraps>

80107d54 <vector210>:
.globl vector210
vector210:
  pushl $0
80107d54:	6a 00                	push   $0x0
  pushl $210
80107d56:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d5b:	e9 99 f0 ff ff       	jmp    80106df9 <alltraps>

80107d60 <vector211>:
.globl vector211
vector211:
  pushl $0
80107d60:	6a 00                	push   $0x0
  pushl $211
80107d62:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d67:	e9 8d f0 ff ff       	jmp    80106df9 <alltraps>

80107d6c <vector212>:
.globl vector212
vector212:
  pushl $0
80107d6c:	6a 00                	push   $0x0
  pushl $212
80107d6e:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d73:	e9 81 f0 ff ff       	jmp    80106df9 <alltraps>

80107d78 <vector213>:
.globl vector213
vector213:
  pushl $0
80107d78:	6a 00                	push   $0x0
  pushl $213
80107d7a:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107d7f:	e9 75 f0 ff ff       	jmp    80106df9 <alltraps>

80107d84 <vector214>:
.globl vector214
vector214:
  pushl $0
80107d84:	6a 00                	push   $0x0
  pushl $214
80107d86:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107d8b:	e9 69 f0 ff ff       	jmp    80106df9 <alltraps>

80107d90 <vector215>:
.globl vector215
vector215:
  pushl $0
80107d90:	6a 00                	push   $0x0
  pushl $215
80107d92:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107d97:	e9 5d f0 ff ff       	jmp    80106df9 <alltraps>

80107d9c <vector216>:
.globl vector216
vector216:
  pushl $0
80107d9c:	6a 00                	push   $0x0
  pushl $216
80107d9e:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107da3:	e9 51 f0 ff ff       	jmp    80106df9 <alltraps>

80107da8 <vector217>:
.globl vector217
vector217:
  pushl $0
80107da8:	6a 00                	push   $0x0
  pushl $217
80107daa:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107daf:	e9 45 f0 ff ff       	jmp    80106df9 <alltraps>

80107db4 <vector218>:
.globl vector218
vector218:
  pushl $0
80107db4:	6a 00                	push   $0x0
  pushl $218
80107db6:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107dbb:	e9 39 f0 ff ff       	jmp    80106df9 <alltraps>

80107dc0 <vector219>:
.globl vector219
vector219:
  pushl $0
80107dc0:	6a 00                	push   $0x0
  pushl $219
80107dc2:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107dc7:	e9 2d f0 ff ff       	jmp    80106df9 <alltraps>

80107dcc <vector220>:
.globl vector220
vector220:
  pushl $0
80107dcc:	6a 00                	push   $0x0
  pushl $220
80107dce:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107dd3:	e9 21 f0 ff ff       	jmp    80106df9 <alltraps>

80107dd8 <vector221>:
.globl vector221
vector221:
  pushl $0
80107dd8:	6a 00                	push   $0x0
  pushl $221
80107dda:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107ddf:	e9 15 f0 ff ff       	jmp    80106df9 <alltraps>

80107de4 <vector222>:
.globl vector222
vector222:
  pushl $0
80107de4:	6a 00                	push   $0x0
  pushl $222
80107de6:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107deb:	e9 09 f0 ff ff       	jmp    80106df9 <alltraps>

80107df0 <vector223>:
.globl vector223
vector223:
  pushl $0
80107df0:	6a 00                	push   $0x0
  pushl $223
80107df2:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107df7:	e9 fd ef ff ff       	jmp    80106df9 <alltraps>

80107dfc <vector224>:
.globl vector224
vector224:
  pushl $0
80107dfc:	6a 00                	push   $0x0
  pushl $224
80107dfe:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107e03:	e9 f1 ef ff ff       	jmp    80106df9 <alltraps>

80107e08 <vector225>:
.globl vector225
vector225:
  pushl $0
80107e08:	6a 00                	push   $0x0
  pushl $225
80107e0a:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107e0f:	e9 e5 ef ff ff       	jmp    80106df9 <alltraps>

80107e14 <vector226>:
.globl vector226
vector226:
  pushl $0
80107e14:	6a 00                	push   $0x0
  pushl $226
80107e16:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107e1b:	e9 d9 ef ff ff       	jmp    80106df9 <alltraps>

80107e20 <vector227>:
.globl vector227
vector227:
  pushl $0
80107e20:	6a 00                	push   $0x0
  pushl $227
80107e22:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107e27:	e9 cd ef ff ff       	jmp    80106df9 <alltraps>

80107e2c <vector228>:
.globl vector228
vector228:
  pushl $0
80107e2c:	6a 00                	push   $0x0
  pushl $228
80107e2e:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e33:	e9 c1 ef ff ff       	jmp    80106df9 <alltraps>

80107e38 <vector229>:
.globl vector229
vector229:
  pushl $0
80107e38:	6a 00                	push   $0x0
  pushl $229
80107e3a:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e3f:	e9 b5 ef ff ff       	jmp    80106df9 <alltraps>

80107e44 <vector230>:
.globl vector230
vector230:
  pushl $0
80107e44:	6a 00                	push   $0x0
  pushl $230
80107e46:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e4b:	e9 a9 ef ff ff       	jmp    80106df9 <alltraps>

80107e50 <vector231>:
.globl vector231
vector231:
  pushl $0
80107e50:	6a 00                	push   $0x0
  pushl $231
80107e52:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e57:	e9 9d ef ff ff       	jmp    80106df9 <alltraps>

80107e5c <vector232>:
.globl vector232
vector232:
  pushl $0
80107e5c:	6a 00                	push   $0x0
  pushl $232
80107e5e:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e63:	e9 91 ef ff ff       	jmp    80106df9 <alltraps>

80107e68 <vector233>:
.globl vector233
vector233:
  pushl $0
80107e68:	6a 00                	push   $0x0
  pushl $233
80107e6a:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e6f:	e9 85 ef ff ff       	jmp    80106df9 <alltraps>

80107e74 <vector234>:
.globl vector234
vector234:
  pushl $0
80107e74:	6a 00                	push   $0x0
  pushl $234
80107e76:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e7b:	e9 79 ef ff ff       	jmp    80106df9 <alltraps>

80107e80 <vector235>:
.globl vector235
vector235:
  pushl $0
80107e80:	6a 00                	push   $0x0
  pushl $235
80107e82:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107e87:	e9 6d ef ff ff       	jmp    80106df9 <alltraps>

80107e8c <vector236>:
.globl vector236
vector236:
  pushl $0
80107e8c:	6a 00                	push   $0x0
  pushl $236
80107e8e:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107e93:	e9 61 ef ff ff       	jmp    80106df9 <alltraps>

80107e98 <vector237>:
.globl vector237
vector237:
  pushl $0
80107e98:	6a 00                	push   $0x0
  pushl $237
80107e9a:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107e9f:	e9 55 ef ff ff       	jmp    80106df9 <alltraps>

80107ea4 <vector238>:
.globl vector238
vector238:
  pushl $0
80107ea4:	6a 00                	push   $0x0
  pushl $238
80107ea6:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107eab:	e9 49 ef ff ff       	jmp    80106df9 <alltraps>

80107eb0 <vector239>:
.globl vector239
vector239:
  pushl $0
80107eb0:	6a 00                	push   $0x0
  pushl $239
80107eb2:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107eb7:	e9 3d ef ff ff       	jmp    80106df9 <alltraps>

80107ebc <vector240>:
.globl vector240
vector240:
  pushl $0
80107ebc:	6a 00                	push   $0x0
  pushl $240
80107ebe:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107ec3:	e9 31 ef ff ff       	jmp    80106df9 <alltraps>

80107ec8 <vector241>:
.globl vector241
vector241:
  pushl $0
80107ec8:	6a 00                	push   $0x0
  pushl $241
80107eca:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107ecf:	e9 25 ef ff ff       	jmp    80106df9 <alltraps>

80107ed4 <vector242>:
.globl vector242
vector242:
  pushl $0
80107ed4:	6a 00                	push   $0x0
  pushl $242
80107ed6:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107edb:	e9 19 ef ff ff       	jmp    80106df9 <alltraps>

80107ee0 <vector243>:
.globl vector243
vector243:
  pushl $0
80107ee0:	6a 00                	push   $0x0
  pushl $243
80107ee2:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107ee7:	e9 0d ef ff ff       	jmp    80106df9 <alltraps>

80107eec <vector244>:
.globl vector244
vector244:
  pushl $0
80107eec:	6a 00                	push   $0x0
  pushl $244
80107eee:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107ef3:	e9 01 ef ff ff       	jmp    80106df9 <alltraps>

80107ef8 <vector245>:
.globl vector245
vector245:
  pushl $0
80107ef8:	6a 00                	push   $0x0
  pushl $245
80107efa:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107eff:	e9 f5 ee ff ff       	jmp    80106df9 <alltraps>

80107f04 <vector246>:
.globl vector246
vector246:
  pushl $0
80107f04:	6a 00                	push   $0x0
  pushl $246
80107f06:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107f0b:	e9 e9 ee ff ff       	jmp    80106df9 <alltraps>

80107f10 <vector247>:
.globl vector247
vector247:
  pushl $0
80107f10:	6a 00                	push   $0x0
  pushl $247
80107f12:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107f17:	e9 dd ee ff ff       	jmp    80106df9 <alltraps>

80107f1c <vector248>:
.globl vector248
vector248:
  pushl $0
80107f1c:	6a 00                	push   $0x0
  pushl $248
80107f1e:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107f23:	e9 d1 ee ff ff       	jmp    80106df9 <alltraps>

80107f28 <vector249>:
.globl vector249
vector249:
  pushl $0
80107f28:	6a 00                	push   $0x0
  pushl $249
80107f2a:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f2f:	e9 c5 ee ff ff       	jmp    80106df9 <alltraps>

80107f34 <vector250>:
.globl vector250
vector250:
  pushl $0
80107f34:	6a 00                	push   $0x0
  pushl $250
80107f36:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f3b:	e9 b9 ee ff ff       	jmp    80106df9 <alltraps>

80107f40 <vector251>:
.globl vector251
vector251:
  pushl $0
80107f40:	6a 00                	push   $0x0
  pushl $251
80107f42:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f47:	e9 ad ee ff ff       	jmp    80106df9 <alltraps>

80107f4c <vector252>:
.globl vector252
vector252:
  pushl $0
80107f4c:	6a 00                	push   $0x0
  pushl $252
80107f4e:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f53:	e9 a1 ee ff ff       	jmp    80106df9 <alltraps>

80107f58 <vector253>:
.globl vector253
vector253:
  pushl $0
80107f58:	6a 00                	push   $0x0
  pushl $253
80107f5a:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f5f:	e9 95 ee ff ff       	jmp    80106df9 <alltraps>

80107f64 <vector254>:
.globl vector254
vector254:
  pushl $0
80107f64:	6a 00                	push   $0x0
  pushl $254
80107f66:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f6b:	e9 89 ee ff ff       	jmp    80106df9 <alltraps>

80107f70 <vector255>:
.globl vector255
vector255:
  pushl $0
80107f70:	6a 00                	push   $0x0
  pushl $255
80107f72:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f77:	e9 7d ee ff ff       	jmp    80106df9 <alltraps>

80107f7c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f7c:	55                   	push   %ebp
80107f7d:	89 e5                	mov    %esp,%ebp
80107f7f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107f82:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f85:	83 e8 01             	sub    $0x1,%eax
80107f88:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107f8c:	8b 45 08             	mov    0x8(%ebp),%eax
80107f8f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107f93:	8b 45 08             	mov    0x8(%ebp),%eax
80107f96:	c1 e8 10             	shr    $0x10,%eax
80107f99:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107f9d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107fa0:	0f 01 10             	lgdtl  (%eax)
}
80107fa3:	c9                   	leave  
80107fa4:	c3                   	ret    

80107fa5 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107fa5:	55                   	push   %ebp
80107fa6:	89 e5                	mov    %esp,%ebp
80107fa8:	83 ec 04             	sub    $0x4,%esp
80107fab:	8b 45 08             	mov    0x8(%ebp),%eax
80107fae:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107fb2:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fb6:	0f 00 d8             	ltr    %ax
}
80107fb9:	c9                   	leave  
80107fba:	c3                   	ret    

80107fbb <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107fbb:	55                   	push   %ebp
80107fbc:	89 e5                	mov    %esp,%ebp
80107fbe:	83 ec 04             	sub    $0x4,%esp
80107fc1:	8b 45 08             	mov    0x8(%ebp),%eax
80107fc4:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107fc8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fcc:	8e e8                	mov    %eax,%gs
}
80107fce:	c9                   	leave  
80107fcf:	c3                   	ret    

80107fd0 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107fd0:	55                   	push   %ebp
80107fd1:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107fd3:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd6:	0f 22 d8             	mov    %eax,%cr3
}
80107fd9:	5d                   	pop    %ebp
80107fda:	c3                   	ret    

80107fdb <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107fdb:	55                   	push   %ebp
80107fdc:	89 e5                	mov    %esp,%ebp
80107fde:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe1:	05 00 00 00 80       	add    $0x80000000,%eax
80107fe6:	5d                   	pop    %ebp
80107fe7:	c3                   	ret    

80107fe8 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107fe8:	55                   	push   %ebp
80107fe9:	89 e5                	mov    %esp,%ebp
80107feb:	8b 45 08             	mov    0x8(%ebp),%eax
80107fee:	05 00 00 00 80       	add    $0x80000000,%eax
80107ff3:	5d                   	pop    %ebp
80107ff4:	c3                   	ret    

80107ff5 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107ff5:	55                   	push   %ebp
80107ff6:	89 e5                	mov    %esp,%ebp
80107ff8:	53                   	push   %ebx
80107ff9:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107ffc:	e8 fb b5 ff ff       	call   801035fc <cpunum>
80108001:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108007:	05 60 43 11 80       	add    $0x80114360,%eax
8010800c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010800f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108012:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108018:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010801b:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108021:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108024:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010802f:	83 e2 f0             	and    $0xfffffff0,%edx
80108032:	83 ca 0a             	or     $0xa,%edx
80108035:	88 50 7d             	mov    %dl,0x7d(%eax)
80108038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010803b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010803f:	83 ca 10             	or     $0x10,%edx
80108042:	88 50 7d             	mov    %dl,0x7d(%eax)
80108045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108048:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010804c:	83 e2 9f             	and    $0xffffff9f,%edx
8010804f:	88 50 7d             	mov    %dl,0x7d(%eax)
80108052:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108055:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108059:	83 ca 80             	or     $0xffffff80,%edx
8010805c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010805f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108062:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108066:	83 ca 0f             	or     $0xf,%edx
80108069:	88 50 7e             	mov    %dl,0x7e(%eax)
8010806c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108073:	83 e2 ef             	and    $0xffffffef,%edx
80108076:	88 50 7e             	mov    %dl,0x7e(%eax)
80108079:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108080:	83 e2 df             	and    $0xffffffdf,%edx
80108083:	88 50 7e             	mov    %dl,0x7e(%eax)
80108086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108089:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010808d:	83 ca 40             	or     $0x40,%edx
80108090:	88 50 7e             	mov    %dl,0x7e(%eax)
80108093:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108096:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010809a:	83 ca 80             	or     $0xffffff80,%edx
8010809d:	88 50 7e             	mov    %dl,0x7e(%eax)
801080a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080a3:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801080a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080aa:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801080b1:	ff ff 
801080b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b6:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801080bd:	00 00 
801080bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c2:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801080c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080cc:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080d3:	83 e2 f0             	and    $0xfffffff0,%edx
801080d6:	83 ca 02             	or     $0x2,%edx
801080d9:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e2:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080e9:	83 ca 10             	or     $0x10,%edx
801080ec:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f5:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080fc:	83 e2 9f             	and    $0xffffff9f,%edx
801080ff:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108108:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010810f:	83 ca 80             	or     $0xffffff80,%edx
80108112:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108118:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108122:	83 ca 0f             	or     $0xf,%edx
80108125:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010812b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108135:	83 e2 ef             	and    $0xffffffef,%edx
80108138:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010813e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108141:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108148:	83 e2 df             	and    $0xffffffdf,%edx
8010814b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108154:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010815b:	83 ca 40             	or     $0x40,%edx
8010815e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108164:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108167:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010816e:	83 ca 80             	or     $0xffffff80,%edx
80108171:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108184:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010818b:	ff ff 
8010818d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108190:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108197:	00 00 
80108199:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801081a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081ad:	83 e2 f0             	and    $0xfffffff0,%edx
801081b0:	83 ca 0a             	or     $0xa,%edx
801081b3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081bc:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081c3:	83 ca 10             	or     $0x10,%edx
801081c6:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081cf:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081d6:	83 ca 60             	or     $0x60,%edx
801081d9:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081e9:	83 ca 80             	or     $0xffffff80,%edx
801081ec:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081fc:	83 ca 0f             	or     $0xf,%edx
801081ff:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108205:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108208:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010820f:	83 e2 ef             	and    $0xffffffef,%edx
80108212:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108218:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010821b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108222:	83 e2 df             	and    $0xffffffdf,%edx
80108225:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010822b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108235:	83 ca 40             	or     $0x40,%edx
80108238:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010823e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108241:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108248:	83 ca 80             	or     $0xffffff80,%edx
8010824b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108254:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010825b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010825e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108265:	ff ff 
80108267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108271:	00 00 
80108273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108276:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010827d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108280:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108287:	83 e2 f0             	and    $0xfffffff0,%edx
8010828a:	83 ca 02             	or     $0x2,%edx
8010828d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108296:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010829d:	83 ca 10             	or     $0x10,%edx
801082a0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082b0:	83 ca 60             	or     $0x60,%edx
801082b3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082bc:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082c3:	83 ca 80             	or     $0xffffff80,%edx
801082c6:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082cf:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082d6:	83 ca 0f             	or     $0xf,%edx
801082d9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e2:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082e9:	83 e2 ef             	and    $0xffffffef,%edx
801082ec:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f5:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082fc:	83 e2 df             	and    $0xffffffdf,%edx
801082ff:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108305:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108308:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010830f:	83 ca 40             	or     $0x40,%edx
80108312:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108322:	83 ca 80             	or     $0xffffff80,%edx
80108325:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010832b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832e:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108335:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108338:	05 b4 00 00 00       	add    $0xb4,%eax
8010833d:	89 c3                	mov    %eax,%ebx
8010833f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108342:	05 b4 00 00 00       	add    $0xb4,%eax
80108347:	c1 e8 10             	shr    $0x10,%eax
8010834a:	89 c1                	mov    %eax,%ecx
8010834c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834f:	05 b4 00 00 00       	add    $0xb4,%eax
80108354:	c1 e8 18             	shr    $0x18,%eax
80108357:	89 c2                	mov    %eax,%edx
80108359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108363:	00 00 
80108365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108368:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010836f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108372:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108382:	83 e1 f0             	and    $0xfffffff0,%ecx
80108385:	83 c9 02             	or     $0x2,%ecx
80108388:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010838e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108391:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108398:	83 c9 10             	or     $0x10,%ecx
8010839b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083ab:	83 e1 9f             	and    $0xffffff9f,%ecx
801083ae:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083be:	83 c9 80             	or     $0xffffff80,%ecx
801083c1:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ca:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083d1:	83 e1 f0             	and    $0xfffffff0,%ecx
801083d4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083dd:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083e4:	83 e1 ef             	and    $0xffffffef,%ecx
801083e7:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f0:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083f7:	83 e1 df             	and    $0xffffffdf,%ecx
801083fa:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108400:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108403:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010840a:	83 c9 40             	or     $0x40,%ecx
8010840d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108413:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108416:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010841d:	83 c9 80             	or     $0xffffff80,%ecx
80108420:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108426:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108429:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010842f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108432:	83 c0 70             	add    $0x70,%eax
80108435:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010843c:	00 
8010843d:	89 04 24             	mov    %eax,(%esp)
80108440:	e8 37 fb ff ff       	call   80107f7c <lgdt>
  loadgs(SEG_KCPU << 3);
80108445:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010844c:	e8 6a fb ff ff       	call   80107fbb <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108451:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108454:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010845a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108461:	00 00 00 00 
}
80108465:	83 c4 24             	add    $0x24,%esp
80108468:	5b                   	pop    %ebx
80108469:	5d                   	pop    %ebp
8010846a:	c3                   	ret    

8010846b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010846b:	55                   	push   %ebp
8010846c:	89 e5                	mov    %esp,%ebp
8010846e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108471:	8b 45 0c             	mov    0xc(%ebp),%eax
80108474:	c1 e8 16             	shr    $0x16,%eax
80108477:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010847e:	8b 45 08             	mov    0x8(%ebp),%eax
80108481:	01 d0                	add    %edx,%eax
80108483:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108486:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108489:	8b 00                	mov    (%eax),%eax
8010848b:	83 e0 01             	and    $0x1,%eax
8010848e:	85 c0                	test   %eax,%eax
80108490:	74 17                	je     801084a9 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108492:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108495:	8b 00                	mov    (%eax),%eax
80108497:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010849c:	89 04 24             	mov    %eax,(%esp)
8010849f:	e8 44 fb ff ff       	call   80107fe8 <p2v>
801084a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084a7:	eb 4b                	jmp    801084f4 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801084a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801084ad:	74 0e                	je     801084bd <walkpgdir+0x52>
801084af:	e8 6c ad ff ff       	call   80103220 <kalloc>
801084b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801084bb:	75 07                	jne    801084c4 <walkpgdir+0x59>
      return 0;
801084bd:	b8 00 00 00 00       	mov    $0x0,%eax
801084c2:	eb 47                	jmp    8010850b <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801084c4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084cb:	00 
801084cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084d3:	00 
801084d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d7:	89 04 24             	mov    %eax,(%esp)
801084da:	e8 26 d5 ff ff       	call   80105a05 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801084df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e2:	89 04 24             	mov    %eax,(%esp)
801084e5:	e8 f1 fa ff ff       	call   80107fdb <v2p>
801084ea:	83 c8 07             	or     $0x7,%eax
801084ed:	89 c2                	mov    %eax,%edx
801084ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084f2:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801084f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801084f7:	c1 e8 0c             	shr    $0xc,%eax
801084fa:	25 ff 03 00 00       	and    $0x3ff,%eax
801084ff:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108506:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108509:	01 d0                	add    %edx,%eax
}
8010850b:	c9                   	leave  
8010850c:	c3                   	ret    

8010850d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010850d:	55                   	push   %ebp
8010850e:	89 e5                	mov    %esp,%ebp
80108510:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108513:	8b 45 0c             	mov    0xc(%ebp),%eax
80108516:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010851b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010851e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108521:	8b 45 10             	mov    0x10(%ebp),%eax
80108524:	01 d0                	add    %edx,%eax
80108526:	83 e8 01             	sub    $0x1,%eax
80108529:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010852e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108531:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108538:	00 
80108539:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010853c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108540:	8b 45 08             	mov    0x8(%ebp),%eax
80108543:	89 04 24             	mov    %eax,(%esp)
80108546:	e8 20 ff ff ff       	call   8010846b <walkpgdir>
8010854b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010854e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108552:	75 07                	jne    8010855b <mappages+0x4e>
      return -1;
80108554:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108559:	eb 48                	jmp    801085a3 <mappages+0x96>
    if(*pte & PTE_P)
8010855b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010855e:	8b 00                	mov    (%eax),%eax
80108560:	83 e0 01             	and    $0x1,%eax
80108563:	85 c0                	test   %eax,%eax
80108565:	74 0c                	je     80108573 <mappages+0x66>
      panic("remap");
80108567:	c7 04 24 dc a1 10 80 	movl   $0x8010a1dc,(%esp)
8010856e:	e8 c7 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108573:	8b 45 18             	mov    0x18(%ebp),%eax
80108576:	0b 45 14             	or     0x14(%ebp),%eax
80108579:	83 c8 01             	or     $0x1,%eax
8010857c:	89 c2                	mov    %eax,%edx
8010857e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108581:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108586:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108589:	75 08                	jne    80108593 <mappages+0x86>
      break;
8010858b:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010858c:	b8 00 00 00 00       	mov    $0x0,%eax
80108591:	eb 10                	jmp    801085a3 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80108593:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
8010859a:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801085a1:	eb 8e                	jmp    80108531 <mappages+0x24>
  return 0;
}
801085a3:	c9                   	leave  
801085a4:	c3                   	ret    

801085a5 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801085a5:	55                   	push   %ebp
801085a6:	89 e5                	mov    %esp,%ebp
801085a8:	53                   	push   %ebx
801085a9:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801085ac:	e8 6f ac ff ff       	call   80103220 <kalloc>
801085b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801085b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085b8:	75 0a                	jne    801085c4 <setupkvm+0x1f>
    return 0;
801085ba:	b8 00 00 00 00       	mov    $0x0,%eax
801085bf:	e9 98 00 00 00       	jmp    8010865c <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801085c4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085cb:	00 
801085cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085d3:	00 
801085d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085d7:	89 04 24             	mov    %eax,(%esp)
801085da:	e8 26 d4 ff ff       	call   80105a05 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801085df:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801085e6:	e8 fd f9 ff ff       	call   80107fe8 <p2v>
801085eb:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801085f0:	76 0c                	jbe    801085fe <setupkvm+0x59>
    panic("PHYSTOP too high");
801085f2:	c7 04 24 e2 a1 10 80 	movl   $0x8010a1e2,(%esp)
801085f9:	e8 3c 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801085fe:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
80108605:	eb 49                	jmp    80108650 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108607:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860a:	8b 48 0c             	mov    0xc(%eax),%ecx
8010860d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108610:	8b 50 04             	mov    0x4(%eax),%edx
80108613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108616:	8b 58 08             	mov    0x8(%eax),%ebx
80108619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861c:	8b 40 04             	mov    0x4(%eax),%eax
8010861f:	29 c3                	sub    %eax,%ebx
80108621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108624:	8b 00                	mov    (%eax),%eax
80108626:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010862a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010862e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108632:	89 44 24 04          	mov    %eax,0x4(%esp)
80108636:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108639:	89 04 24             	mov    %eax,(%esp)
8010863c:	e8 cc fe ff ff       	call   8010850d <mappages>
80108641:	85 c0                	test   %eax,%eax
80108643:	79 07                	jns    8010864c <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108645:	b8 00 00 00 00       	mov    $0x0,%eax
8010864a:	eb 10                	jmp    8010865c <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010864c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108650:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108657:	72 ae                	jb     80108607 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
80108659:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
8010865c:	83 c4 34             	add    $0x34,%esp
8010865f:	5b                   	pop    %ebx
80108660:	5d                   	pop    %ebp
80108661:	c3                   	ret    

80108662 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
80108662:	55                   	push   %ebp
80108663:	89 e5                	mov    %esp,%ebp
80108665:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
80108668:	e8 38 ff ff ff       	call   801085a5 <setupkvm>
8010866d:	a3 58 0d 12 80       	mov    %eax,0x80120d58
    switchkvm();
80108672:	e8 02 00 00 00       	call   80108679 <switchkvm>
  }
80108677:	c9                   	leave  
80108678:	c3                   	ret    

80108679 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
80108679:	55                   	push   %ebp
8010867a:	89 e5                	mov    %esp,%ebp
8010867c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
8010867f:	a1 58 0d 12 80       	mov    0x80120d58,%eax
80108684:	89 04 24             	mov    %eax,(%esp)
80108687:	e8 4f f9 ff ff       	call   80107fdb <v2p>
8010868c:	89 04 24             	mov    %eax,(%esp)
8010868f:	e8 3c f9 ff ff       	call   80107fd0 <lcr3>
}
80108694:	c9                   	leave  
80108695:	c3                   	ret    

80108696 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108696:	55                   	push   %ebp
80108697:	89 e5                	mov    %esp,%ebp
80108699:	53                   	push   %ebx
8010869a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
8010869d:	e8 63 d2 ff ff       	call   80105905 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801086a2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086a8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086af:	83 c2 08             	add    $0x8,%edx
801086b2:	89 d3                	mov    %edx,%ebx
801086b4:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086bb:	83 c2 08             	add    $0x8,%edx
801086be:	c1 ea 10             	shr    $0x10,%edx
801086c1:	89 d1                	mov    %edx,%ecx
801086c3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086ca:	83 c2 08             	add    $0x8,%edx
801086cd:	c1 ea 18             	shr    $0x18,%edx
801086d0:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801086d7:	67 00 
801086d9:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801086e0:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801086e6:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086ed:	83 e1 f0             	and    $0xfffffff0,%ecx
801086f0:	83 c9 09             	or     $0x9,%ecx
801086f3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086f9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108700:	83 c9 10             	or     $0x10,%ecx
80108703:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108709:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108710:	83 e1 9f             	and    $0xffffff9f,%ecx
80108713:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108719:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108720:	83 c9 80             	or     $0xffffff80,%ecx
80108723:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108729:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108730:	83 e1 f0             	and    $0xfffffff0,%ecx
80108733:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108739:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108740:	83 e1 ef             	and    $0xffffffef,%ecx
80108743:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108749:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108750:	83 e1 df             	and    $0xffffffdf,%ecx
80108753:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108759:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108760:	83 c9 40             	or     $0x40,%ecx
80108763:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108769:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108770:	83 e1 7f             	and    $0x7f,%ecx
80108773:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108779:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010877f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108785:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010878c:	83 e2 ef             	and    $0xffffffef,%edx
8010878f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108795:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010879b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801087a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087a7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801087ae:	8b 52 08             	mov    0x8(%edx),%edx
801087b1:	81 c2 00 10 00 00    	add    $0x1000,%edx
801087b7:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801087ba:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801087c1:	e8 df f7 ff ff       	call   80107fa5 <ltr>
  if(p->pgdir == 0)
801087c6:	8b 45 08             	mov    0x8(%ebp),%eax
801087c9:	8b 40 04             	mov    0x4(%eax),%eax
801087cc:	85 c0                	test   %eax,%eax
801087ce:	75 0c                	jne    801087dc <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801087d0:	c7 04 24 f3 a1 10 80 	movl   $0x8010a1f3,(%esp)
801087d7:	e8 5e 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801087dc:	8b 45 08             	mov    0x8(%ebp),%eax
801087df:	8b 40 04             	mov    0x4(%eax),%eax
801087e2:	89 04 24             	mov    %eax,(%esp)
801087e5:	e8 f1 f7 ff ff       	call   80107fdb <v2p>
801087ea:	89 04 24             	mov    %eax,(%esp)
801087ed:	e8 de f7 ff ff       	call   80107fd0 <lcr3>
  popcli();
801087f2:	e8 52 d1 ff ff       	call   80105949 <popcli>
}
801087f7:	83 c4 14             	add    $0x14,%esp
801087fa:	5b                   	pop    %ebx
801087fb:	5d                   	pop    %ebp
801087fc:	c3                   	ret    

801087fd <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801087fd:	55                   	push   %ebp
801087fe:	89 e5                	mov    %esp,%ebp
80108800:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108803:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010880a:	76 0c                	jbe    80108818 <inituvm+0x1b>
    panic("inituvm: more than a page");
8010880c:	c7 04 24 07 a2 10 80 	movl   $0x8010a207,(%esp)
80108813:	e8 22 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
80108818:	e8 03 aa ff ff       	call   80103220 <kalloc>
8010881d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108820:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108827:	00 
80108828:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010882f:	00 
80108830:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108833:	89 04 24             	mov    %eax,(%esp)
80108836:	e8 ca d1 ff ff       	call   80105a05 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010883b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883e:	89 04 24             	mov    %eax,(%esp)
80108841:	e8 95 f7 ff ff       	call   80107fdb <v2p>
80108846:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010884d:	00 
8010884e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108852:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108859:	00 
8010885a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108861:	00 
80108862:	8b 45 08             	mov    0x8(%ebp),%eax
80108865:	89 04 24             	mov    %eax,(%esp)
80108868:	e8 a0 fc ff ff       	call   8010850d <mappages>
  memmove(mem, init, sz);
8010886d:	8b 45 10             	mov    0x10(%ebp),%eax
80108870:	89 44 24 08          	mov    %eax,0x8(%esp)
80108874:	8b 45 0c             	mov    0xc(%ebp),%eax
80108877:	89 44 24 04          	mov    %eax,0x4(%esp)
8010887b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010887e:	89 04 24             	mov    %eax,(%esp)
80108881:	e8 4e d2 ff ff       	call   80105ad4 <memmove>
}
80108886:	c9                   	leave  
80108887:	c3                   	ret    

80108888 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108888:	55                   	push   %ebp
80108889:	89 e5                	mov    %esp,%ebp
8010888b:	53                   	push   %ebx
8010888c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010888f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108892:	25 ff 0f 00 00       	and    $0xfff,%eax
80108897:	85 c0                	test   %eax,%eax
80108899:	74 0c                	je     801088a7 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010889b:	c7 04 24 24 a2 10 80 	movl   $0x8010a224,(%esp)
801088a2:	e8 93 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801088a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801088ae:	e9 a9 00 00 00       	jmp    8010895c <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801088b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088b6:	8b 55 0c             	mov    0xc(%ebp),%edx
801088b9:	01 d0                	add    %edx,%eax
801088bb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088c2:	00 
801088c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801088c7:	8b 45 08             	mov    0x8(%ebp),%eax
801088ca:	89 04 24             	mov    %eax,(%esp)
801088cd:	e8 99 fb ff ff       	call   8010846b <walkpgdir>
801088d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801088d5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088d9:	75 0c                	jne    801088e7 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801088db:	c7 04 24 47 a2 10 80 	movl   $0x8010a247,(%esp)
801088e2:	e8 53 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801088e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088ea:	8b 00                	mov    (%eax),%eax
801088ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088f1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801088f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f7:	8b 55 18             	mov    0x18(%ebp),%edx
801088fa:	29 c2                	sub    %eax,%edx
801088fc:	89 d0                	mov    %edx,%eax
801088fe:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108903:	77 0f                	ja     80108914 <loaduvm+0x8c>
      n = sz - i;
80108905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108908:	8b 55 18             	mov    0x18(%ebp),%edx
8010890b:	29 c2                	sub    %eax,%edx
8010890d:	89 d0                	mov    %edx,%eax
8010890f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108912:	eb 07                	jmp    8010891b <loaduvm+0x93>
    else
      n = PGSIZE;
80108914:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010891b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891e:	8b 55 14             	mov    0x14(%ebp),%edx
80108921:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108924:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108927:	89 04 24             	mov    %eax,(%esp)
8010892a:	e8 b9 f6 ff ff       	call   80107fe8 <p2v>
8010892f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108932:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108936:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010893a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010893e:	8b 45 10             	mov    0x10(%ebp),%eax
80108941:	89 04 24             	mov    %eax,(%esp)
80108944:	e8 d4 95 ff ff       	call   80101f1d <readi>
80108949:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010894c:	74 07                	je     80108955 <loaduvm+0xcd>
      return -1;
8010894e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108953:	eb 18                	jmp    8010896d <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108955:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010895c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895f:	3b 45 18             	cmp    0x18(%ebp),%eax
80108962:	0f 82 4b ff ff ff    	jb     801088b3 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108968:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010896d:	83 c4 24             	add    $0x24,%esp
80108970:	5b                   	pop    %ebx
80108971:	5d                   	pop    %ebp
80108972:	c3                   	ret    

80108973 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108973:	55                   	push   %ebp
80108974:	89 e5                	mov    %esp,%ebp
80108976:	53                   	push   %ebx
80108977:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
8010897a:	8b 45 10             	mov    0x10(%ebp),%eax
8010897d:	85 c0                	test   %eax,%eax
8010897f:	79 0a                	jns    8010898b <allocuvm+0x18>
    return 0;
80108981:	b8 00 00 00 00       	mov    $0x0,%eax
80108986:	e9 2d 02 00 00       	jmp    80108bb8 <allocuvm+0x245>
  if(newsz < oldsz)
8010898b:	8b 45 10             	mov    0x10(%ebp),%eax
8010898e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108991:	73 08                	jae    8010899b <allocuvm+0x28>
    return oldsz;
80108993:	8b 45 0c             	mov    0xc(%ebp),%eax
80108996:	e9 1d 02 00 00       	jmp    80108bb8 <allocuvm+0x245>

  a = PGROUNDUP(oldsz);
8010899b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010899e:	05 ff 0f 00 00       	add    $0xfff,%eax
801089a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801089ab:	e9 f9 01 00 00       	jmp    80108ba9 <allocuvm+0x236>
    mem = kalloc();
801089b0:	e8 6b a8 ff ff       	call   80103220 <kalloc>
801089b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
801089b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089bc:	75 36                	jne    801089f4 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
801089be:	c7 04 24 65 a2 10 80 	movl   $0x8010a265,(%esp)
801089c5:	e8 d6 79 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
801089ca:	8b 45 14             	mov    0x14(%ebp),%eax
801089cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801089d4:	89 44 24 08          	mov    %eax,0x8(%esp)
801089d8:	8b 45 10             	mov    0x10(%ebp),%eax
801089db:	89 44 24 04          	mov    %eax,0x4(%esp)
801089df:	8b 45 08             	mov    0x8(%ebp),%eax
801089e2:	89 04 24             	mov    %eax,(%esp)
801089e5:	e8 d4 01 00 00       	call   80108bbe <deallocuvm>
      return 0;
801089ea:	b8 00 00 00 00       	mov    $0x0,%eax
801089ef:	e9 c4 01 00 00       	jmp    80108bb8 <allocuvm+0x245>
    }
    memset(mem, 0, PGSIZE);
801089f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089fb:	00 
801089fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a03:	00 
80108a04:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a07:	89 04 24             	mov    %eax,(%esp)
80108a0a:	e8 f6 cf ff ff       	call   80105a05 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108a0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a12:	89 04 24             	mov    %eax,(%esp)
80108a15:	e8 c1 f5 ff ff       	call   80107fdb <v2p>
80108a1a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108a1d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a24:	00 
80108a25:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a29:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a30:	00 
80108a31:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a35:	8b 45 08             	mov    0x8(%ebp),%eax
80108a38:	89 04 24             	mov    %eax,(%esp)
80108a3b:	e8 cd fa ff ff       	call   8010850d <mappages>
    //find the next open cell in pages array
      i=0;
80108a40:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a47:	eb 16                	jmp    80108a5f <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a49:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a4d:	7e 0c                	jle    80108a5b <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a4f:	c7 04 24 80 a2 10 80 	movl   $0x8010a280,(%esp)
80108a56:	e8 df 7a ff ff       	call   8010053a <panic>
        }
        i++;
80108a5b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a5f:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a62:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a65:	89 d0                	mov    %edx,%eax
80108a67:	c1 e0 02             	shl    $0x2,%eax
80108a6a:	01 d0                	add    %edx,%eax
80108a6c:	c1 e0 02             	shl    $0x2,%eax
80108a6f:	01 c8                	add    %ecx,%eax
80108a71:	05 90 00 00 00       	add    $0x90,%eax
80108a76:	8b 00                	mov    (%eax),%eax
80108a78:	83 f8 ff             	cmp    $0xffffffff,%eax
80108a7b:	75 cc                	jne    80108a49 <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
80108a7d:	e8 bf 0f 00 00       	call   80109a41 <isInit>
80108a82:	85 c0                	test   %eax,%eax
80108a84:	75 60                	jne    80108ae6 <allocuvm+0x173>
80108a86:	e8 89 0f 00 00       	call   80109a14 <isShell>
80108a8b:	85 c0                	test   %eax,%eax
80108a8d:	75 57                	jne    80108ae6 <allocuvm+0x173>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108a8f:	8b 45 14             	mov    0x14(%ebp),%eax
80108a92:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108a98:	83 f8 0e             	cmp    $0xe,%eax
80108a9b:	76 32                	jbe    80108acf <allocuvm+0x15c>
          swapOut();
80108a9d:	e8 03 0c 00 00       	call   801096a5 <swapOut>
          lcr3(v2p(proc->pgdir));
80108aa2:	8b 45 14             	mov    0x14(%ebp),%eax
80108aa5:	8b 40 04             	mov    0x4(%eax),%eax
80108aa8:	89 04 24             	mov    %eax,(%esp)
80108aab:	e8 2b f5 ff ff       	call   80107fdb <v2p>
80108ab0:	89 04 24             	mov    %eax,(%esp)
80108ab3:	e8 18 f5 ff ff       	call   80107fd0 <lcr3>
          proc->swapedPagesCounter++;
80108ab8:	8b 45 14             	mov    0x14(%ebp),%eax
80108abb:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108ac1:	8d 50 01             	lea    0x1(%eax),%edx
80108ac4:	8b 45 14             	mov    0x14(%ebp),%eax
80108ac7:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108acd:	eb 2c                	jmp    80108afb <allocuvm+0x188>
          swapOut();
          lcr3(v2p(proc->pgdir));
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108acf:	8b 45 14             	mov    0x14(%ebp),%eax
80108ad2:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ad8:	8d 50 01             	lea    0x1(%eax),%edx
80108adb:	8b 45 14             	mov    0x14(%ebp),%eax
80108ade:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108ae4:	eb 15                	jmp    80108afb <allocuvm+0x188>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108ae6:	8b 45 14             	mov    0x14(%ebp),%eax
80108ae9:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108aef:	8d 50 01             	lea    0x1(%eax),%edx
80108af2:	8b 45 14             	mov    0x14(%ebp),%eax
80108af5:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108afb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108afe:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b01:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b04:	89 d0                	mov    %edx,%eax
80108b06:	c1 e0 02             	shl    $0x2,%eax
80108b09:	01 d0                	add    %edx,%eax
80108b0b:	c1 e0 02             	shl    $0x2,%eax
80108b0e:	01 d8                	add    %ebx,%eax
80108b10:	05 90 00 00 00       	add    $0x90,%eax
80108b15:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108b17:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b1a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b1d:	89 d0                	mov    %edx,%eax
80108b1f:	c1 e0 02             	shl    $0x2,%eax
80108b22:	01 d0                	add    %edx,%eax
80108b24:	c1 e0 02             	shl    $0x2,%eax
80108b27:	01 c8                	add    %ecx,%eax
80108b29:	05 94 00 00 00       	add    $0x94,%eax
80108b2e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108b34:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b37:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b3a:	89 d0                	mov    %edx,%eax
80108b3c:	c1 e0 02             	shl    $0x2,%eax
80108b3f:	01 d0                	add    %edx,%eax
80108b41:	c1 e0 02             	shl    $0x2,%eax
80108b44:	01 c8                	add    %ecx,%eax
80108b46:	05 98 00 00 00       	add    $0x98,%eax
80108b4b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b51:	8b 45 14             	mov    0x14(%ebp),%eax
80108b54:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b5a:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b5d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b60:	89 d0                	mov    %edx,%eax
80108b62:	c1 e0 02             	shl    $0x2,%eax
80108b65:	01 d0                	add    %edx,%eax
80108b67:	c1 e0 02             	shl    $0x2,%eax
80108b6a:	01 d8                	add    %ebx,%eax
80108b6c:	05 9c 00 00 00       	add    $0x9c,%eax
80108b71:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108b73:	8b 45 14             	mov    0x14(%ebp),%eax
80108b76:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108b7c:	8d 50 01             	lea    0x1(%eax),%edx
80108b7f:	8b 45 14             	mov    0x14(%ebp),%eax
80108b82:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108b88:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b8b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b8e:	89 d0                	mov    %edx,%eax
80108b90:	c1 e0 02             	shl    $0x2,%eax
80108b93:	01 d0                	add    %edx,%eax
80108b95:	c1 e0 02             	shl    $0x2,%eax
80108b98:	01 c8                	add    %ecx,%eax
80108b9a:	05 a0 00 00 00       	add    $0xa0,%eax
80108b9f:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108ba2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ba9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bac:	3b 45 10             	cmp    0x10(%ebp),%eax
80108baf:	0f 82 fb fd ff ff    	jb     801089b0 <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108bb5:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108bb8:	83 c4 34             	add    $0x34,%esp
80108bbb:	5b                   	pop    %ebx
80108bbc:	5d                   	pop    %ebp
80108bbd:	c3                   	ret    

80108bbe <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108bbe:	55                   	push   %ebp
80108bbf:	89 e5                	mov    %esp,%ebp
80108bc1:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108bc4:	8b 45 10             	mov    0x10(%ebp),%eax
80108bc7:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108bca:	72 08                	jb     80108bd4 <deallocuvm+0x16>
    return oldsz;
80108bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bcf:	e9 ec 01 00 00       	jmp    80108dc0 <deallocuvm+0x202>

  a = PGROUNDUP(newsz);
80108bd4:	8b 45 10             	mov    0x10(%ebp),%eax
80108bd7:	05 ff 0f 00 00       	add    $0xfff,%eax
80108bdc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108be1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108be4:	e9 c8 01 00 00       	jmp    80108db1 <deallocuvm+0x1f3>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108be9:	8b 45 14             	mov    0x14(%ebp),%eax
80108bec:	8b 40 04             	mov    0x4(%eax),%eax
80108bef:	3b 45 08             	cmp    0x8(%ebp),%eax
80108bf2:	0f 85 07 01 00 00    	jne    80108cff <deallocuvm+0x141>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108bf8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108bff:	e9 f1 00 00 00       	jmp    80108cf5 <deallocuvm+0x137>
          if(proc->pagesMetaData[i].va == (char *)a){
80108c04:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c07:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c0a:	89 d0                	mov    %edx,%eax
80108c0c:	c1 e0 02             	shl    $0x2,%eax
80108c0f:	01 d0                	add    %edx,%eax
80108c11:	c1 e0 02             	shl    $0x2,%eax
80108c14:	01 c8                	add    %ecx,%eax
80108c16:	05 90 00 00 00       	add    $0x90,%eax
80108c1b:	8b 10                	mov    (%eax),%edx
80108c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c20:	39 c2                	cmp    %eax,%edx
80108c22:	0f 85 c9 00 00 00    	jne    80108cf1 <deallocuvm+0x133>
            if((!isShell()) && (!isInit())){
80108c28:	e8 e7 0d 00 00       	call   80109a14 <isShell>
80108c2d:	85 c0                	test   %eax,%eax
80108c2f:	75 54                	jne    80108c85 <deallocuvm+0xc7>
80108c31:	e8 0b 0e 00 00       	call   80109a41 <isInit>
80108c36:	85 c0                	test   %eax,%eax
80108c38:	75 4b                	jne    80108c85 <deallocuvm+0xc7>
              if(proc->pagesMetaData[i].isPhysical){
80108c3a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c3d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c40:	89 d0                	mov    %edx,%eax
80108c42:	c1 e0 02             	shl    $0x2,%eax
80108c45:	01 d0                	add    %edx,%eax
80108c47:	c1 e0 02             	shl    $0x2,%eax
80108c4a:	01 c8                	add    %ecx,%eax
80108c4c:	05 94 00 00 00       	add    $0x94,%eax
80108c51:	8b 00                	mov    (%eax),%eax
80108c53:	85 c0                	test   %eax,%eax
80108c55:	74 17                	je     80108c6e <deallocuvm+0xb0>
                proc->memoryPagesCounter--;
80108c57:	8b 45 14             	mov    0x14(%ebp),%eax
80108c5a:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c60:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c63:	8b 45 14             	mov    0x14(%ebp),%eax
80108c66:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108c6c:	eb 2c                	jmp    80108c9a <deallocuvm+0xdc>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108c6e:	8b 45 14             	mov    0x14(%ebp),%eax
80108c71:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108c77:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c7a:	8b 45 14             	mov    0x14(%ebp),%eax
80108c7d:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108c83:	eb 15                	jmp    80108c9a <deallocuvm+0xdc>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108c85:	8b 45 14             	mov    0x14(%ebp),%eax
80108c88:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c8e:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c91:	8b 45 14             	mov    0x14(%ebp),%eax
80108c94:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108c9a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c9d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ca0:	89 d0                	mov    %edx,%eax
80108ca2:	c1 e0 02             	shl    $0x2,%eax
80108ca5:	01 d0                	add    %edx,%eax
80108ca7:	c1 e0 02             	shl    $0x2,%eax
80108caa:	01 c8                	add    %ecx,%eax
80108cac:	05 90 00 00 00       	add    $0x90,%eax
80108cb1:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108cb7:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cba:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cbd:	89 d0                	mov    %edx,%eax
80108cbf:	c1 e0 02             	shl    $0x2,%eax
80108cc2:	01 d0                	add    %edx,%eax
80108cc4:	c1 e0 02             	shl    $0x2,%eax
80108cc7:	01 c8                	add    %ecx,%eax
80108cc9:	05 94 00 00 00       	add    $0x94,%eax
80108cce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108cd4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cd7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cda:	89 d0                	mov    %edx,%eax
80108cdc:	c1 e0 02             	shl    $0x2,%eax
80108cdf:	01 d0                	add    %edx,%eax
80108ce1:	c1 e0 02             	shl    $0x2,%eax
80108ce4:	01 c8                	add    %ecx,%eax
80108ce6:	05 98 00 00 00       	add    $0x98,%eax
80108ceb:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108cf1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108cf5:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108cf9:	0f 8e 05 ff ff ff    	jle    80108c04 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108cff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d02:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108d09:	00 
80108d0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d0e:	8b 45 08             	mov    0x8(%ebp),%eax
80108d11:	89 04 24             	mov    %eax,(%esp)
80108d14:	e8 52 f7 ff ff       	call   8010846b <walkpgdir>
80108d19:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108d1c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d20:	75 09                	jne    80108d2b <deallocuvm+0x16d>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d22:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d29:	eb 7f                	jmp    80108daa <deallocuvm+0x1ec>
    else if((*pte & PTE_P) != 0){
80108d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d2e:	8b 00                	mov    (%eax),%eax
80108d30:	83 e0 01             	and    $0x1,%eax
80108d33:	85 c0                	test   %eax,%eax
80108d35:	74 5c                	je     80108d93 <deallocuvm+0x1d5>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108d37:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d3a:	8b 00                	mov    (%eax),%eax
80108d3c:	25 00 02 00 00       	and    $0x200,%eax
80108d41:	85 c0                	test   %eax,%eax
80108d43:	75 43                	jne    80108d88 <deallocuvm+0x1ca>
        pa = PTE_ADDR(*pte);
80108d45:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d48:	8b 00                	mov    (%eax),%eax
80108d4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d52:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d56:	75 0c                	jne    80108d64 <deallocuvm+0x1a6>
          panic("kfree");
80108d58:	c7 04 24 aa a2 10 80 	movl   $0x8010a2aa,(%esp)
80108d5f:	e8 d6 77 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108d64:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d67:	89 04 24             	mov    %eax,(%esp)
80108d6a:	e8 79 f2 ff ff       	call   80107fe8 <p2v>
80108d6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108d72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d75:	89 04 24             	mov    %eax,(%esp)
80108d78:	e8 e1 a3 ff ff       	call   8010315e <kfree>
        *pte = 0;
80108d7d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d80:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d86:	eb 22                	jmp    80108daa <deallocuvm+0x1ec>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108d88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d8b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d91:	eb 17                	jmp    80108daa <deallocuvm+0x1ec>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108d93:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d96:	8b 00                	mov    (%eax),%eax
80108d98:	25 00 02 00 00       	and    $0x200,%eax
80108d9d:	85 c0                	test   %eax,%eax
80108d9f:	74 09                	je     80108daa <deallocuvm+0x1ec>
        *pte = 0;
80108da1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108da4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108daa:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108db4:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108db7:	0f 82 2c fe ff ff    	jb     80108be9 <deallocuvm+0x2b>
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
    }
  }
  return newsz;
80108dbd:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108dc0:	c9                   	leave  
80108dc1:	c3                   	ret    

80108dc2 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108dc2:	55                   	push   %ebp
80108dc3:	89 e5                	mov    %esp,%ebp
80108dc5:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108dc8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108dcc:	75 0c                	jne    80108dda <freevm+0x18>
    panic("freevm: no pgdir");
80108dce:	c7 04 24 b0 a2 10 80 	movl   $0x8010a2b0,(%esp)
80108dd5:	e8 60 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108dda:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108de0:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108de4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108deb:	00 
80108dec:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108df3:	80 
80108df4:	8b 45 08             	mov    0x8(%ebp),%eax
80108df7:	89 04 24             	mov    %eax,(%esp)
80108dfa:	e8 bf fd ff ff       	call   80108bbe <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108dff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e06:	eb 48                	jmp    80108e50 <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e0b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e12:	8b 45 08             	mov    0x8(%ebp),%eax
80108e15:	01 d0                	add    %edx,%eax
80108e17:	8b 00                	mov    (%eax),%eax
80108e19:	83 e0 01             	and    $0x1,%eax
80108e1c:	85 c0                	test   %eax,%eax
80108e1e:	74 2c                	je     80108e4c <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e23:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e2a:	8b 45 08             	mov    0x8(%ebp),%eax
80108e2d:	01 d0                	add    %edx,%eax
80108e2f:	8b 00                	mov    (%eax),%eax
80108e31:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e36:	89 04 24             	mov    %eax,(%esp)
80108e39:	e8 aa f1 ff ff       	call   80107fe8 <p2v>
80108e3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e44:	89 04 24             	mov    %eax,(%esp)
80108e47:	e8 12 a3 ff ff       	call   8010315e <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e4c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e50:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e57:	76 af                	jbe    80108e08 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e59:	8b 45 08             	mov    0x8(%ebp),%eax
80108e5c:	89 04 24             	mov    %eax,(%esp)
80108e5f:	e8 fa a2 ff ff       	call   8010315e <kfree>

}
80108e64:	c9                   	leave  
80108e65:	c3                   	ret    

80108e66 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e66:	55                   	push   %ebp
80108e67:	89 e5                	mov    %esp,%ebp
80108e69:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e6c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e73:	00 
80108e74:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e77:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e7e:	89 04 24             	mov    %eax,(%esp)
80108e81:	e8 e5 f5 ff ff       	call   8010846b <walkpgdir>
80108e86:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108e89:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e8d:	75 0c                	jne    80108e9b <clearpteu+0x35>
    panic("clearpteu");
80108e8f:	c7 04 24 c1 a2 10 80 	movl   $0x8010a2c1,(%esp)
80108e96:	e8 9f 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e9e:	8b 00                	mov    (%eax),%eax
80108ea0:	83 e0 fb             	and    $0xfffffffb,%eax
80108ea3:	89 c2                	mov    %eax,%edx
80108ea5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ea8:	89 10                	mov    %edx,(%eax)
}
80108eaa:	c9                   	leave  
80108eab:	c3                   	ret    

80108eac <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108eac:	55                   	push   %ebp
80108ead:	89 e5                	mov    %esp,%ebp
80108eaf:	53                   	push   %ebx
80108eb0:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108eb3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108eba:	8b 45 10             	mov    0x10(%ebp),%eax
80108ebd:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108ec4:	00 00 00 
  np->swapedPagesCounter = 0;
80108ec7:	8b 45 10             	mov    0x10(%ebp),%eax
80108eca:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108ed1:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108ed4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108eda:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108ee0:	8b 45 10             	mov    0x10(%ebp),%eax
80108ee3:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108ee9:	e8 b7 f6 ff ff       	call   801085a5 <setupkvm>
80108eee:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108ef1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ef5:	75 0a                	jne    80108f01 <copyuvm+0x55>
    return 0;
80108ef7:	b8 00 00 00 00       	mov    $0x0,%eax
80108efc:	e9 da 02 00 00       	jmp    801091db <copyuvm+0x32f>
  for(i = 0; i < sz; i += PGSIZE){
80108f01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f08:	e9 04 02 00 00       	jmp    80109111 <copyuvm+0x265>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f10:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f17:	00 
80108f18:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f1c:	8b 45 08             	mov    0x8(%ebp),%eax
80108f1f:	89 04 24             	mov    %eax,(%esp)
80108f22:	e8 44 f5 ff ff       	call   8010846b <walkpgdir>
80108f27:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f2a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f2e:	75 0c                	jne    80108f3c <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f30:	c7 04 24 cb a2 10 80 	movl   $0x8010a2cb,(%esp)
80108f37:	e8 fe 75 ff ff       	call   8010053a <panic>
    if(*pte & PTE_P){// page on RAM, copy it to the new process ram
80108f3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f3f:	8b 00                	mov    (%eax),%eax
80108f41:	83 e0 01             	and    $0x1,%eax
80108f44:	85 c0                	test   %eax,%eax
80108f46:	0f 84 a7 00 00 00    	je     80108ff3 <copyuvm+0x147>
      // panic("copyuvm: page not present");
      pa = PTE_ADDR(*pte);
80108f4c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f4f:	8b 00                	mov    (%eax),%eax
80108f51:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      flags = PTE_FLAGS(*pte);
80108f59:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f5c:	8b 00                	mov    (%eax),%eax
80108f5e:	25 ff 0f 00 00       	and    $0xfff,%eax
80108f63:	89 45 e0             	mov    %eax,-0x20(%ebp)
      if((mem = kalloc()) == 0)
80108f66:	e8 b5 a2 ff ff       	call   80103220 <kalloc>
80108f6b:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108f6e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108f72:	75 05                	jne    80108f79 <copyuvm+0xcd>
        goto bad;
80108f74:	e9 4a 02 00 00       	jmp    801091c3 <copyuvm+0x317>
      memmove(mem, (char*)p2v(pa), PGSIZE);
80108f79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108f7c:	89 04 24             	mov    %eax,(%esp)
80108f7f:	e8 64 f0 ff ff       	call   80107fe8 <p2v>
80108f84:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f8b:	00 
80108f8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f90:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108f93:	89 04 24             	mov    %eax,(%esp)
80108f96:	e8 39 cb ff ff       	call   80105ad4 <memmove>
      if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108f9b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108f9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fa1:	89 04 24             	mov    %eax,(%esp)
80108fa4:	e8 32 f0 ff ff       	call   80107fdb <v2p>
80108fa9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108fac:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108fb0:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108fb4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fbb:	00 
80108fbc:	89 54 24 04          	mov    %edx,0x4(%esp)
80108fc0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108fc3:	89 04 24             	mov    %eax,(%esp)
80108fc6:	e8 42 f5 ff ff       	call   8010850d <mappages>
80108fcb:	85 c0                	test   %eax,%eax
80108fcd:	79 05                	jns    80108fd4 <copyuvm+0x128>
        goto bad;
80108fcf:	e9 ef 01 00 00       	jmp    801091c3 <copyuvm+0x317>
      np->pagesMetaData[j].isPhysical = 1;
80108fd4:	8b 4d 10             	mov    0x10(%ebp),%ecx
80108fd7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108fda:	89 d0                	mov    %edx,%eax
80108fdc:	c1 e0 02             	shl    $0x2,%eax
80108fdf:	01 d0                	add    %edx,%eax
80108fe1:	c1 e0 02             	shl    $0x2,%eax
80108fe4:	01 c8                	add    %ecx,%eax
80108fe6:	05 94 00 00 00       	add    $0x94,%eax
80108feb:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
80108ff1:	eb 58                	jmp    8010904b <copyuvm+0x19f>
    }
    else{//page is in swap file, need to create pte for it
      pte = walkpgdir(d,(void*)i,1);
80108ff3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ff6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108ffd:	00 
80108ffe:	89 44 24 04          	mov    %eax,0x4(%esp)
80109002:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109005:	89 04 24             	mov    %eax,(%esp)
80109008:	e8 5e f4 ff ff       	call   8010846b <walkpgdir>
8010900d:	89 45 e8             	mov    %eax,-0x18(%ebp)
      *pte &= ~PTE_P;
80109010:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109013:	8b 00                	mov    (%eax),%eax
80109015:	83 e0 fe             	and    $0xfffffffe,%eax
80109018:	89 c2                	mov    %eax,%edx
8010901a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010901d:	89 10                	mov    %edx,(%eax)
      *pte |= PTE_PG;
8010901f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109022:	8b 00                	mov    (%eax),%eax
80109024:	80 cc 02             	or     $0x2,%ah
80109027:	89 c2                	mov    %eax,%edx
80109029:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010902c:	89 10                	mov    %edx,(%eax)
      np->pagesMetaData[j].isPhysical = 0;
8010902e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109031:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109034:	89 d0                	mov    %edx,%eax
80109036:	c1 e0 02             	shl    $0x2,%eax
80109039:	01 d0                	add    %edx,%eax
8010903b:	c1 e0 02             	shl    $0x2,%eax
8010903e:	01 c8                	add    %ecx,%eax
80109040:	05 94 00 00 00       	add    $0x94,%eax
80109045:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    }
    np->pagesMetaData[j].va = (char *) i;
8010904b:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010904e:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109051:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109054:	89 d0                	mov    %edx,%eax
80109056:	c1 e0 02             	shl    $0x2,%eax
80109059:	01 d0                	add    %edx,%eax
8010905b:	c1 e0 02             	shl    $0x2,%eax
8010905e:	01 d8                	add    %ebx,%eax
80109060:	05 90 00 00 00       	add    $0x90,%eax
80109065:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109067:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010906a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010906d:	89 d0                	mov    %edx,%eax
8010906f:	c1 e0 02             	shl    $0x2,%eax
80109072:	01 d0                	add    %edx,%eax
80109074:	c1 e0 02             	shl    $0x2,%eax
80109077:	01 c8                	add    %ecx,%eax
80109079:	05 98 00 00 00       	add    $0x98,%eax
8010907e:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
80109084:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010908b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010908e:	89 d0                	mov    %edx,%eax
80109090:	c1 e0 02             	shl    $0x2,%eax
80109093:	01 d0                	add    %edx,%eax
80109095:	c1 e0 02             	shl    $0x2,%eax
80109098:	01 c8                	add    %ecx,%eax
8010909a:	05 9c 00 00 00       	add    $0x9c,%eax
8010909f:	8b 08                	mov    (%eax),%ecx
801090a1:	8b 5d 10             	mov    0x10(%ebp),%ebx
801090a4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090a7:	89 d0                	mov    %edx,%eax
801090a9:	c1 e0 02             	shl    $0x2,%eax
801090ac:	01 d0                	add    %edx,%eax
801090ae:	c1 e0 02             	shl    $0x2,%eax
801090b1:	01 d8                	add    %ebx,%eax
801090b3:	05 9c 00 00 00       	add    $0x9c,%eax
801090b8:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
801090ba:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801090c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090c4:	89 d0                	mov    %edx,%eax
801090c6:	c1 e0 02             	shl    $0x2,%eax
801090c9:	01 d0                	add    %edx,%eax
801090cb:	c1 e0 02             	shl    $0x2,%eax
801090ce:	01 c8                	add    %ecx,%eax
801090d0:	05 a0 00 00 00       	add    $0xa0,%eax
801090d5:	0f b6 08             	movzbl (%eax),%ecx
801090d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
801090db:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090de:	89 d0                	mov    %edx,%eax
801090e0:	c1 e0 02             	shl    $0x2,%eax
801090e3:	01 d0                	add    %edx,%eax
801090e5:	c1 e0 02             	shl    $0x2,%eax
801090e8:	01 d8                	add    %ebx,%eax
801090ea:	05 a0 00 00 00       	add    $0xa0,%eax
801090ef:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
801090f1:	8b 45 10             	mov    0x10(%ebp),%eax
801090f4:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801090fa:	8d 50 01             	lea    0x1(%eax),%edx
801090fd:	8b 45 10             	mov    0x10(%ebp),%eax
80109100:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
80109106:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010910a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109114:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109117:	0f 82 f0 fd ff ff    	jb     80108f0d <copyuvm+0x61>
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
8010911d:	e9 92 00 00 00       	jmp    801091b4 <copyuvm+0x308>
    np->pagesMetaData[j].va = (char *) -1;
80109122:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109125:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109128:	89 d0                	mov    %edx,%eax
8010912a:	c1 e0 02             	shl    $0x2,%eax
8010912d:	01 d0                	add    %edx,%eax
8010912f:	c1 e0 02             	shl    $0x2,%eax
80109132:	01 c8                	add    %ecx,%eax
80109134:	05 90 00 00 00       	add    $0x90,%eax
80109139:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
8010913f:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109142:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109145:	89 d0                	mov    %edx,%eax
80109147:	c1 e0 02             	shl    $0x2,%eax
8010914a:	01 d0                	add    %edx,%eax
8010914c:	c1 e0 02             	shl    $0x2,%eax
8010914f:	01 c8                	add    %ecx,%eax
80109151:	05 94 00 00 00       	add    $0x94,%eax
80109156:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
8010915c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010915f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109162:	89 d0                	mov    %edx,%eax
80109164:	c1 e0 02             	shl    $0x2,%eax
80109167:	01 d0                	add    %edx,%eax
80109169:	c1 e0 02             	shl    $0x2,%eax
8010916c:	01 c8                	add    %ecx,%eax
8010916e:	05 98 00 00 00       	add    $0x98,%eax
80109173:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109179:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010917c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010917f:	89 d0                	mov    %edx,%eax
80109181:	c1 e0 02             	shl    $0x2,%eax
80109184:	01 d0                	add    %edx,%eax
80109186:	c1 e0 02             	shl    $0x2,%eax
80109189:	01 c8                	add    %ecx,%eax
8010918b:	05 9c 00 00 00       	add    $0x9c,%eax
80109190:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
80109196:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109199:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010919c:	89 d0                	mov    %edx,%eax
8010919e:	c1 e0 02             	shl    $0x2,%eax
801091a1:	01 d0                	add    %edx,%eax
801091a3:	c1 e0 02             	shl    $0x2,%eax
801091a6:	01 c8                	add    %ecx,%eax
801091a8:	05 a0 00 00 00       	add    $0xa0,%eax
801091ad:	c6 00 80             	movb   $0x80,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
801091b0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801091b4:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801091b8:	0f 86 64 ff ff ff    	jbe    80109122 <copyuvm+0x276>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
801091be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091c1:	eb 18                	jmp    801091db <copyuvm+0x32f>

  bad:
  freevm(d,0);
801091c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801091ca:	00 
801091cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091ce:	89 04 24             	mov    %eax,(%esp)
801091d1:	e8 ec fb ff ff       	call   80108dc2 <freevm>
  return 0;
801091d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801091db:	83 c4 44             	add    $0x44,%esp
801091de:	5b                   	pop    %ebx
801091df:	5d                   	pop    %ebp
801091e0:	c3                   	ret    

801091e1 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801091e1:	55                   	push   %ebp
801091e2:	89 e5                	mov    %esp,%ebp
801091e4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801091e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091ee:	00 
801091ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801091f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801091f6:	8b 45 08             	mov    0x8(%ebp),%eax
801091f9:	89 04 24             	mov    %eax,(%esp)
801091fc:	e8 6a f2 ff ff       	call   8010846b <walkpgdir>
80109201:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109207:	8b 00                	mov    (%eax),%eax
80109209:	83 e0 01             	and    $0x1,%eax
8010920c:	85 c0                	test   %eax,%eax
8010920e:	75 07                	jne    80109217 <uva2ka+0x36>
    return 0;
80109210:	b8 00 00 00 00       	mov    $0x0,%eax
80109215:	eb 25                	jmp    8010923c <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010921a:	8b 00                	mov    (%eax),%eax
8010921c:	83 e0 04             	and    $0x4,%eax
8010921f:	85 c0                	test   %eax,%eax
80109221:	75 07                	jne    8010922a <uva2ka+0x49>
    return 0;
80109223:	b8 00 00 00 00       	mov    $0x0,%eax
80109228:	eb 12                	jmp    8010923c <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010922a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010922d:	8b 00                	mov    (%eax),%eax
8010922f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109234:	89 04 24             	mov    %eax,(%esp)
80109237:	e8 ac ed ff ff       	call   80107fe8 <p2v>
}
8010923c:	c9                   	leave  
8010923d:	c3                   	ret    

8010923e <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010923e:	55                   	push   %ebp
8010923f:	89 e5                	mov    %esp,%ebp
80109241:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109244:	8b 45 10             	mov    0x10(%ebp),%eax
80109247:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010924a:	e9 87 00 00 00       	jmp    801092d6 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010924f:	8b 45 0c             	mov    0xc(%ebp),%eax
80109252:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109257:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010925a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010925d:	89 44 24 04          	mov    %eax,0x4(%esp)
80109261:	8b 45 08             	mov    0x8(%ebp),%eax
80109264:	89 04 24             	mov    %eax,(%esp)
80109267:	e8 75 ff ff ff       	call   801091e1 <uva2ka>
8010926c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010926f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109273:	75 07                	jne    8010927c <copyout+0x3e>
      return -1;
80109275:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010927a:	eb 69                	jmp    801092e5 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010927c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010927f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109282:	29 c2                	sub    %eax,%edx
80109284:	89 d0                	mov    %edx,%eax
80109286:	05 00 10 00 00       	add    $0x1000,%eax
8010928b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010928e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109291:	3b 45 14             	cmp    0x14(%ebp),%eax
80109294:	76 06                	jbe    8010929c <copyout+0x5e>
      n = len;
80109296:	8b 45 14             	mov    0x14(%ebp),%eax
80109299:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010929c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010929f:	8b 55 0c             	mov    0xc(%ebp),%edx
801092a2:	29 c2                	sub    %eax,%edx
801092a4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092a7:	01 c2                	add    %eax,%edx
801092a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801092b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801092b7:	89 14 24             	mov    %edx,(%esp)
801092ba:	e8 15 c8 ff ff       	call   80105ad4 <memmove>
    len -= n;
801092bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092c2:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801092c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092c8:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801092cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092ce:	05 00 10 00 00       	add    $0x1000,%eax
801092d3:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801092d6:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801092da:	0f 85 6f ff ff ff    	jne    8010924f <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801092e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092e5:	c9                   	leave  
801092e6:	c3                   	ret    

801092e7 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
801092e7:	55                   	push   %ebp
801092e8:	89 e5                	mov    %esp,%ebp
801092ea:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801092ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801092f4:	eb 52                	jmp    80109348 <findNextOpenPage+0x61>
    found = 1;
801092f6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092fd:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80109304:	eb 2d                	jmp    80109333 <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
80109306:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010930d:	8b 55 f8             	mov    -0x8(%ebp),%edx
80109310:	89 d0                	mov    %edx,%eax
80109312:	c1 e0 02             	shl    $0x2,%eax
80109315:	01 d0                	add    %edx,%eax
80109317:	c1 e0 02             	shl    $0x2,%eax
8010931a:	01 c8                	add    %ecx,%eax
8010931c:	05 98 00 00 00       	add    $0x98,%eax
80109321:	8b 00                	mov    (%eax),%eax
80109323:	3b 45 fc             	cmp    -0x4(%ebp),%eax
80109326:	75 07                	jne    8010932f <findNextOpenPage+0x48>
        found = 0;
80109328:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
8010932f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80109333:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
80109337:	7e cd                	jle    80109306 <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
80109339:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010933d:	74 02                	je     80109341 <findNextOpenPage+0x5a>
      break;
8010933f:	eb 10                	jmp    80109351 <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
80109341:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
80109348:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
8010934f:	7e a5                	jle    801092f6 <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
80109351:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80109354:	c9                   	leave  
80109355:	c3                   	ret    

80109356 <existOnDisc>:

int
existOnDisc(uint faultingPage){
80109356:	55                   	push   %ebp
80109357:	89 e5                	mov    %esp,%ebp
80109359:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
8010935c:	8b 55 08             	mov    0x8(%ebp),%edx
8010935f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109365:	8b 40 04             	mov    0x4(%eax),%eax
80109368:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010936f:	00 
80109370:	89 54 24 04          	mov    %edx,0x4(%esp)
80109374:	89 04 24             	mov    %eax,(%esp)
80109377:	e8 ef f0 ff ff       	call   8010846b <walkpgdir>
8010937c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
8010937f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  cprintf("faulting page: %x\n",faultingPage);
80109386:	8b 45 08             	mov    0x8(%ebp),%eax
80109389:	89 44 24 04          	mov    %eax,0x4(%esp)
8010938d:	c7 04 24 e5 a2 10 80 	movl   $0x8010a2e5,(%esp)
80109394:	e8 07 70 ff ff       	call   801003a0 <cprintf>
  for(i = 0; i < 30; i++){
80109399:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801093a0:	e9 8e 00 00 00       	jmp    80109433 <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
801093a5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093ac:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093af:	89 d0                	mov    %edx,%eax
801093b1:	c1 e0 02             	shl    $0x2,%eax
801093b4:	01 d0                	add    %edx,%eax
801093b6:	c1 e0 02             	shl    $0x2,%eax
801093b9:	01 c8                	add    %ecx,%eax
801093bb:	05 90 00 00 00       	add    $0x90,%eax
801093c0:	8b 00                	mov    (%eax),%eax
801093c2:	83 f8 ff             	cmp    $0xffffffff,%eax
801093c5:	74 68                	je     8010942f <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
801093c7:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093ce:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093d1:	89 d0                	mov    %edx,%eax
801093d3:	c1 e0 02             	shl    $0x2,%eax
801093d6:	01 d0                	add    %edx,%eax
801093d8:	c1 e0 02             	shl    $0x2,%eax
801093db:	01 c8                	add    %ecx,%eax
801093dd:	05 90 00 00 00       	add    $0x90,%eax
801093e2:	8b 00                	mov    (%eax),%eax
801093e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093e9:	3b 45 08             	cmp    0x8(%ebp),%eax
801093ec:	77 41                	ja     8010942f <existOnDisc+0xd9>
801093ee:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093f8:	89 d0                	mov    %edx,%eax
801093fa:	c1 e0 02             	shl    $0x2,%eax
801093fd:	01 d0                	add    %edx,%eax
801093ff:	c1 e0 02             	shl    $0x2,%eax
80109402:	01 c8                	add    %ecx,%eax
80109404:	05 90 00 00 00       	add    $0x90,%eax
80109409:	8b 00                	mov    (%eax),%eax
8010940b:	05 ff 0f 00 00       	add    $0xfff,%eax
80109410:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109415:	3b 45 08             	cmp    0x8(%ebp),%eax
80109418:	72 15                	jb     8010942f <existOnDisc+0xd9>
8010941a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010941d:	8b 00                	mov    (%eax),%eax
8010941f:	25 00 02 00 00       	and    $0x200,%eax
80109424:	85 c0                	test   %eax,%eax
80109426:	74 07                	je     8010942f <existOnDisc+0xd9>
        found = 1;
80109428:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  cprintf("faulting page: %x\n",faultingPage);
  for(i = 0; i < 30; i++){
8010942f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109433:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109437:	0f 8e 68 ff ff ff    	jle    801093a5 <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
8010943d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80109440:	c9                   	leave  
80109441:	c3                   	ret    

80109442 <fixPage>:

void
fixPage(uint faultingPage){
80109442:	55                   	push   %ebp
80109443:	89 e5                	mov    %esp,%ebp
80109445:	83 ec 38             	sub    $0x38,%esp
  int i;
  //char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
80109448:	e8 d3 9d ff ff       	call   80103220 <kalloc>
8010944d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
80109450:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109454:	75 0c                	jne    80109462 <fixPage+0x20>
    panic("no room, go away");
80109456:	c7 04 24 f8 a2 10 80 	movl   $0x8010a2f8,(%esp)
8010945d:	e8 d8 70 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
80109462:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109469:	00 
8010946a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109471:	00 
80109472:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109475:	89 04 24             	mov    %eax,(%esp)
80109478:	e8 88 c5 ff ff       	call   80105a05 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
8010947d:	8b 55 08             	mov    0x8(%ebp),%edx
80109480:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109486:	8b 40 04             	mov    0x4(%eax),%eax
80109489:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109490:	00 
80109491:	89 54 24 04          	mov    %edx,0x4(%esp)
80109495:	89 04 24             	mov    %eax,(%esp)
80109498:	e8 ce ef ff ff       	call   8010846b <walkpgdir>
8010949d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
801094a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094a7:	e9 a6 01 00 00       	jmp    80109652 <fixPage+0x210>
    if(proc->pagesMetaData[i].va != (char *) -1){
801094ac:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094b6:	89 d0                	mov    %edx,%eax
801094b8:	c1 e0 02             	shl    $0x2,%eax
801094bb:	01 d0                	add    %edx,%eax
801094bd:	c1 e0 02             	shl    $0x2,%eax
801094c0:	01 c8                	add    %ecx,%eax
801094c2:	05 90 00 00 00       	add    $0x90,%eax
801094c7:	8b 00                	mov    (%eax),%eax
801094c9:	83 f8 ff             	cmp    $0xffffffff,%eax
801094cc:	0f 84 7c 01 00 00    	je     8010964e <fixPage+0x20c>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
801094d2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094dc:	89 d0                	mov    %edx,%eax
801094de:	c1 e0 02             	shl    $0x2,%eax
801094e1:	01 d0                	add    %edx,%eax
801094e3:	c1 e0 02             	shl    $0x2,%eax
801094e6:	01 c8                	add    %ecx,%eax
801094e8:	05 90 00 00 00       	add    $0x90,%eax
801094ed:	8b 00                	mov    (%eax),%eax
801094ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094f4:	3b 45 08             	cmp    0x8(%ebp),%eax
801094f7:	0f 87 51 01 00 00    	ja     8010964e <fixPage+0x20c>
801094fd:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109504:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109507:	89 d0                	mov    %edx,%eax
80109509:	c1 e0 02             	shl    $0x2,%eax
8010950c:	01 d0                	add    %edx,%eax
8010950e:	c1 e0 02             	shl    $0x2,%eax
80109511:	01 c8                	add    %ecx,%eax
80109513:	05 90 00 00 00       	add    $0x90,%eax
80109518:	8b 00                	mov    (%eax),%eax
8010951a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010951f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109524:	3b 45 08             	cmp    0x8(%ebp),%eax
80109527:	0f 82 21 01 00 00    	jb     8010964e <fixPage+0x20c>
8010952d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109530:	8b 00                	mov    (%eax),%eax
80109532:	25 00 02 00 00       	and    $0x200,%eax
80109537:	85 c0                	test   %eax,%eax
80109539:	0f 84 0f 01 00 00    	je     8010964e <fixPage+0x20c>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
8010953f:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109546:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109549:	89 d0                	mov    %edx,%eax
8010954b:	c1 e0 02             	shl    $0x2,%eax
8010954e:	01 d0                	add    %edx,%eax
80109550:	c1 e0 02             	shl    $0x2,%eax
80109553:	01 c8                	add    %ecx,%eax
80109555:	05 98 00 00 00       	add    $0x98,%eax
8010955a:	8b 00                	mov    (%eax),%eax
8010955c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109560:	c7 04 24 09 a3 10 80 	movl   $0x8010a309,(%esp)
80109567:	e8 34 6e ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,mem,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
8010956c:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109573:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109576:	89 d0                	mov    %edx,%eax
80109578:	c1 e0 02             	shl    $0x2,%eax
8010957b:	01 d0                	add    %edx,%eax
8010957d:	c1 e0 02             	shl    $0x2,%eax
80109580:	01 c8                	add    %ecx,%eax
80109582:	05 98 00 00 00       	add    $0x98,%eax
80109587:	8b 00                	mov    (%eax),%eax
80109589:	89 c2                	mov    %eax,%edx
8010958b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109591:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109598:	00 
80109599:	89 54 24 08          	mov    %edx,0x8(%esp)
8010959d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801095a0:	89 54 24 04          	mov    %edx,0x4(%esp)
801095a4:	89 04 24             	mov    %eax,(%esp)
801095a7:	e8 25 94 ff ff       	call   801029d1 <readFromSwapFile>
801095ac:	83 f8 ff             	cmp    $0xffffffff,%eax
801095af:	75 0c                	jne    801095bd <fixPage+0x17b>
          panic("nothing read");
801095b1:	c7 04 24 13 a3 10 80 	movl   $0x8010a313,(%esp)
801095b8:	e8 7d 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1){  //need to swap out
801095bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801095c3:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801095c9:	83 f8 0e             	cmp    $0xe,%eax
801095cc:	76 1e                	jbe    801095ec <fixPage+0x1aa>
          swapOut();
801095ce:	e8 d2 00 00 00       	call   801096a5 <swapOut>
          lcr3(v2p(proc->pgdir));
801095d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801095d9:	8b 40 04             	mov    0x4(%eax),%eax
801095dc:	89 04 24             	mov    %eax,(%esp)
801095df:	e8 f7 e9 ff ff       	call   80107fdb <v2p>
801095e4:	89 04 24             	mov    %eax,(%esp)
801095e7:	e8 e4 e9 ff ff       	call   80107fd0 <lcr3>
        }
        proc->pagesMetaData[i].isPhysical = 1;
801095ec:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095f6:	89 d0                	mov    %edx,%eax
801095f8:	c1 e0 02             	shl    $0x2,%eax
801095fb:	01 d0                	add    %edx,%eax
801095fd:	c1 e0 02             	shl    $0x2,%eax
80109600:	01 c8                	add    %ecx,%eax
80109602:	05 94 00 00 00       	add    $0x94,%eax
80109607:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  
8010960d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109614:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109617:	89 d0                	mov    %edx,%eax
80109619:	c1 e0 02             	shl    $0x2,%eax
8010961c:	01 d0                	add    %edx,%eax
8010961e:	c1 e0 02             	shl    $0x2,%eax
80109621:	01 c8                	add    %ecx,%eax
80109623:	05 a0 00 00 00       	add    $0xa0,%eax
80109628:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
8010962b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109632:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109635:	89 d0                	mov    %edx,%eax
80109637:	c1 e0 02             	shl    $0x2,%eax
8010963a:	01 d0                	add    %edx,%eax
8010963c:	c1 e0 02             	shl    $0x2,%eax
8010963f:	01 c8                	add    %ecx,%eax
80109641:	05 98 00 00 00       	add    $0x98,%eax
80109646:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
8010964c:	eb 0e                	jmp    8010965c <fixPage+0x21a>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010964e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109652:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109656:	0f 8e 50 fe ff ff    	jle    801094ac <fixPage+0x6a>
        break;
      }
    }
  }    
    //memmove(mem,buf,PGSIZE);
    *pte &= ~PTE_PG;  //turn off flag
8010965c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010965f:	8b 00                	mov    (%eax),%eax
80109661:	80 e4 fd             	and    $0xfd,%ah
80109664:	89 c2                	mov    %eax,%edx
80109666:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109669:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
8010966b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010966e:	89 04 24             	mov    %eax,(%esp)
80109671:	e8 65 e9 ff ff       	call   80107fdb <v2p>
80109676:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109679:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109680:	8b 52 04             	mov    0x4(%edx),%edx
80109683:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010968a:	00 
8010968b:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010968f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109696:	00 
80109697:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010969b:	89 14 24             	mov    %edx,(%esp)
8010969e:	e8 6a ee ff ff       	call   8010850d <mappages>
    //memmove(buf,0,PGSIZE);
  }
801096a3:	c9                   	leave  
801096a4:	c3                   	ret    

801096a5 <swapOut>:

//swap out a page from proc.
  void swapOut(){
801096a5:	55                   	push   %ebp
801096a6:	89 e5                	mov    %esp,%ebp
801096a8:	53                   	push   %ebx
801096a9:	83 ec 34             	sub    $0x34,%esp
    int offset;
    //char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    uint flags;
    int index = -1;
801096ac:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
801096b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096b9:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801096bf:	83 c0 03             	add    $0x3,%eax
801096c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    char minNFU = 0x80;
801096c5:	c6 45 eb 80          	movb   $0x80,-0x15(%ebp)
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
801096c9:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801096d0:	eb 6d                	jmp    8010973f <swapOut+0x9a>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
801096d2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096dc:	89 d0                	mov    %edx,%eax
801096de:	c1 e0 02             	shl    $0x2,%eax
801096e1:	01 d0                	add    %edx,%eax
801096e3:	c1 e0 02             	shl    $0x2,%eax
801096e6:	01 c8                	add    %ecx,%eax
801096e8:	05 94 00 00 00       	add    $0x94,%eax
801096ed:	8b 00                	mov    (%eax),%eax
801096ef:	85 c0                	test   %eax,%eax
801096f1:	74 48                	je     8010973b <swapOut+0x96>
801096f3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096fd:	89 d0                	mov    %edx,%eax
801096ff:	c1 e0 02             	shl    $0x2,%eax
80109702:	01 d0                	add    %edx,%eax
80109704:	c1 e0 02             	shl    $0x2,%eax
80109707:	01 c8                	add    %ecx,%eax
80109709:	05 9c 00 00 00       	add    $0x9c,%eax
8010970e:	8b 00                	mov    (%eax),%eax
80109710:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80109713:	7d 26                	jge    8010973b <swapOut+0x96>
            min = proc->pagesMetaData[j].count;
80109715:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010971c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010971f:	89 d0                	mov    %edx,%eax
80109721:	c1 e0 02             	shl    $0x2,%eax
80109724:	01 d0                	add    %edx,%eax
80109726:	c1 e0 02             	shl    $0x2,%eax
80109729:	01 c8                	add    %ecx,%eax
8010972b:	05 9c 00 00 00       	add    $0x9c,%eax
80109730:	8b 00                	mov    (%eax),%eax
80109732:	89 45 ec             	mov    %eax,-0x14(%ebp)
            index = j;
80109735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109738:	89 45 f0             	mov    %eax,-0x10(%ebp)
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
8010973b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010973f:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109743:	7e 8d                	jle    801096d2 <swapOut+0x2d>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
            min = proc->pagesMetaData[j].count;
            index = j;
          }
        }
        break;
80109745:	90                   	nop
        }
        break;
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
80109746:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010974d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109750:	89 d0                	mov    %edx,%eax
80109752:	c1 e0 02             	shl    $0x2,%eax
80109755:	01 d0                	add    %edx,%eax
80109757:	c1 e0 02             	shl    $0x2,%eax
8010975a:	01 c8                	add    %ecx,%eax
8010975c:	05 94 00 00 00       	add    $0x94,%eax
80109761:	8b 00                	mov    (%eax),%eax
80109763:	85 c0                	test   %eax,%eax
80109765:	0f 84 b1 01 00 00    	je     8010991c <swapOut+0x277>
      proc->swappedOutCounter++;
8010976b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109771:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80109777:	83 c2 01             	add    $0x1,%edx
8010977a:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
80109780:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109787:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010978a:	89 d0                	mov    %edx,%eax
8010978c:	c1 e0 02             	shl    $0x2,%eax
8010978f:	01 d0                	add    %edx,%eax
80109791:	c1 e0 02             	shl    $0x2,%eax
80109794:	01 c8                	add    %ecx,%eax
80109796:	05 90 00 00 00       	add    $0x90,%eax
8010979b:	8b 00                	mov    (%eax),%eax
8010979d:	89 04 24             	mov    %eax,(%esp)
801097a0:	e8 42 fb ff ff       	call   801092e7 <findNextOpenPage>
801097a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      cprintf("swapping out %x to offset %d\n",proc->pagesMetaData[index].va,offset);
801097a8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097af:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097b2:	89 d0                	mov    %edx,%eax
801097b4:	c1 e0 02             	shl    $0x2,%eax
801097b7:	01 d0                	add    %edx,%eax
801097b9:	c1 e0 02             	shl    $0x2,%eax
801097bc:	01 c8                	add    %ecx,%eax
801097be:	05 90 00 00 00       	add    $0x90,%eax
801097c3:	8b 00                	mov    (%eax),%eax
801097c5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801097c8:	89 54 24 08          	mov    %edx,0x8(%esp)
801097cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801097d0:	c7 04 24 20 a3 10 80 	movl   $0x8010a320,(%esp)
801097d7:	e8 c4 6b ff ff       	call   801003a0 <cprintf>
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
801097dc:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097e3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097e6:	89 d0                	mov    %edx,%eax
801097e8:	c1 e0 02             	shl    $0x2,%eax
801097eb:	01 d0                	add    %edx,%eax
801097ed:	c1 e0 02             	shl    $0x2,%eax
801097f0:	01 c8                	add    %ecx,%eax
801097f2:	05 90 00 00 00       	add    $0x90,%eax
801097f7:	8b 10                	mov    (%eax),%edx
801097f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801097ff:	8b 40 04             	mov    0x4(%eax),%eax
80109802:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109809:	00 
8010980a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010980e:	89 04 24             	mov    %eax,(%esp)
80109811:	e8 55 ec ff ff       	call   8010846b <walkpgdir>
80109816:	89 45 e0             	mov    %eax,-0x20(%ebp)
      proc->pagesMetaData[index].fileOffset = offset;
80109819:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109820:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109823:	89 d0                	mov    %edx,%eax
80109825:	c1 e0 02             	shl    $0x2,%eax
80109828:	01 d0                	add    %edx,%eax
8010982a:	c1 e0 02             	shl    $0x2,%eax
8010982d:	01 c8                	add    %ecx,%eax
8010982f:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
80109835:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109838:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
8010983a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109841:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109844:	89 d0                	mov    %edx,%eax
80109846:	c1 e0 02             	shl    $0x2,%eax
80109849:	01 d0                	add    %edx,%eax
8010984b:	c1 e0 02             	shl    $0x2,%eax
8010984e:	01 c8                	add    %ecx,%eax
80109850:	05 94 00 00 00       	add    $0x94,%eax
80109855:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
8010985b:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109862:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109868:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
8010986e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109871:	89 d0                	mov    %edx,%eax
80109873:	c1 e0 02             	shl    $0x2,%eax
80109876:	01 d0                	add    %edx,%eax
80109878:	c1 e0 02             	shl    $0x2,%eax
8010987b:	01 d8                	add    %ebx,%eax
8010987d:	05 9c 00 00 00       	add    $0x9c,%eax
80109882:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80109884:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010988a:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80109890:	83 c2 01             	add    $0x1,%edx
80109893:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      writeToSwapFile(proc,p2v(PTE_ADDR(*pte)),offset,PGSIZE);
80109899:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010989c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010989f:	8b 00                	mov    (%eax),%eax
801098a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801098a6:	89 04 24             	mov    %eax,(%esp)
801098a9:	e8 3a e7 ff ff       	call   80107fe8 <p2v>
801098ae:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801098b5:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801098bc:	00 
801098bd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801098c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801098c5:	89 14 24             	mov    %edx,(%esp)
801098c8:	e8 d4 90 ff ff       	call   801029a1 <writeToSwapFile>
      pa = PTE_ADDR(*pte);
801098cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098d0:	8b 00                	mov    (%eax),%eax
801098d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801098d7:	89 45 dc             	mov    %eax,-0x24(%ebp)
      flags = PTE_FLAGS(*pte);
801098da:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098dd:	8b 00                	mov    (%eax),%eax
801098df:	25 ff 0f 00 00       	and    $0xfff,%eax
801098e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
      if(pa != 0){
801098e7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801098eb:	74 13                	je     80109900 <swapOut+0x25b>
        kfree(p2v(pa)); 
801098ed:	8b 45 dc             	mov    -0x24(%ebp),%eax
801098f0:	89 04 24             	mov    %eax,(%esp)
801098f3:	e8 f0 e6 ff ff       	call   80107fe8 <p2v>
801098f8:	89 04 24             	mov    %eax,(%esp)
801098fb:	e8 5e 98 ff ff       	call   8010315e <kfree>
      }
      *pte = 0 | flags | PTE_PG;
80109900:	8b 45 d8             	mov    -0x28(%ebp),%eax
80109903:	80 cc 02             	or     $0x2,%ah
80109906:	89 c2                	mov    %eax,%edx
80109908:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010990b:	89 10                	mov    %edx,(%eax)
      *pte &= ~PTE_P;
8010990d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109910:	8b 00                	mov    (%eax),%eax
80109912:	83 e0 fe             	and    $0xfffffffe,%eax
80109915:	89 c2                	mov    %eax,%edx
80109917:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010991a:	89 10                	mov    %edx,(%eax)
    }
  }
8010991c:	83 c4 34             	add    $0x34,%esp
8010991f:	5b                   	pop    %ebx
80109920:	5d                   	pop    %ebp
80109921:	c3                   	ret    

80109922 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109922:	55                   	push   %ebp
80109923:	89 e5                	mov    %esp,%ebp
80109925:	53                   	push   %ebx
80109926:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
80109929:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109930:	e9 cf 00 00 00       	jmp    80109a04 <updateAge+0xe2>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=(char *) -1){ //only if on RAM
80109935:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109938:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010993b:	89 d0                	mov    %edx,%eax
8010993d:	c1 e0 02             	shl    $0x2,%eax
80109940:	01 d0                	add    %edx,%eax
80109942:	c1 e0 02             	shl    $0x2,%eax
80109945:	01 c8                	add    %ecx,%eax
80109947:	05 94 00 00 00       	add    $0x94,%eax
8010994c:	8b 00                	mov    (%eax),%eax
8010994e:	85 c0                	test   %eax,%eax
80109950:	0f 84 aa 00 00 00    	je     80109a00 <updateAge+0xde>
80109956:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109959:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010995c:	89 d0                	mov    %edx,%eax
8010995e:	c1 e0 02             	shl    $0x2,%eax
80109961:	01 d0                	add    %edx,%eax
80109963:	c1 e0 02             	shl    $0x2,%eax
80109966:	01 c8                	add    %ecx,%eax
80109968:	05 90 00 00 00       	add    $0x90,%eax
8010996d:	8b 00                	mov    (%eax),%eax
8010996f:	83 f8 ff             	cmp    $0xffffffff,%eax
80109972:	0f 84 88 00 00 00    	je     80109a00 <updateAge+0xde>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
80109978:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010997b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010997e:	89 d0                	mov    %edx,%eax
80109980:	c1 e0 02             	shl    $0x2,%eax
80109983:	01 d0                	add    %edx,%eax
80109985:	c1 e0 02             	shl    $0x2,%eax
80109988:	01 c8                	add    %ecx,%eax
8010998a:	05 a0 00 00 00       	add    $0xa0,%eax
8010998f:	0f b6 00             	movzbl (%eax),%eax
80109992:	d0 f8                	sar    %al
80109994:	89 c1                	mov    %eax,%ecx
80109996:	8b 5d 08             	mov    0x8(%ebp),%ebx
80109999:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010999c:	89 d0                	mov    %edx,%eax
8010999e:	c1 e0 02             	shl    $0x2,%eax
801099a1:	01 d0                	add    %edx,%eax
801099a3:	c1 e0 02             	shl    $0x2,%eax
801099a6:	01 d8                	add    %ebx,%eax
801099a8:	05 a0 00 00 00       	add    $0xa0,%eax
801099ad:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
801099af:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099b5:	89 d0                	mov    %edx,%eax
801099b7:	c1 e0 02             	shl    $0x2,%eax
801099ba:	01 d0                	add    %edx,%eax
801099bc:	c1 e0 02             	shl    $0x2,%eax
801099bf:	01 c8                	add    %ecx,%eax
801099c1:	05 90 00 00 00       	add    $0x90,%eax
801099c6:	8b 10                	mov    (%eax),%edx
801099c8:	8b 45 08             	mov    0x8(%ebp),%eax
801099cb:	8b 40 04             	mov    0x4(%eax),%eax
801099ce:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801099d5:	00 
801099d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801099da:	89 04 24             	mov    %eax,(%esp)
801099dd:	e8 89 ea ff ff       	call   8010846b <walkpgdir>
801099e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
         if(*pte & PTE_A){
801099e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801099e8:	8b 00                	mov    (%eax),%eax
801099ea:	83 e0 20             	and    $0x20,%eax
801099ed:	85 c0                	test   %eax,%eax
801099ef:	74 0f                	je     80109a00 <updateAge+0xde>
           *pte &= ~PTE_A; //turn off bit 
801099f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801099f4:	8b 00                	mov    (%eax),%eax
801099f6:	83 e0 df             	and    $0xffffffdf,%eax
801099f9:	89 c2                	mov    %eax,%edx
801099fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801099fe:	89 10                	mov    %edx,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
80109a00:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109a04:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109a08:	0f 8e 27 ff ff ff    	jle    80109935 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
         if(*pte & PTE_A){
           *pte &= ~PTE_A; //turn off bit 
       }
    }
  }
80109a0e:	83 c4 24             	add    $0x24,%esp
80109a11:	5b                   	pop    %ebx
80109a12:	5d                   	pop    %ebp
80109a13:	c3                   	ret    

80109a14 <isShell>:

int
isShell(){
80109a14:	55                   	push   %ebp
80109a15:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 's') && (proc->name[1] == 'h');
80109a17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a1d:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109a21:	3c 73                	cmp    $0x73,%al
80109a23:	75 15                	jne    80109a3a <isShell+0x26>
80109a25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a2b:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109a2f:	3c 68                	cmp    $0x68,%al
80109a31:	75 07                	jne    80109a3a <isShell+0x26>
80109a33:	b8 01 00 00 00       	mov    $0x1,%eax
80109a38:	eb 05                	jmp    80109a3f <isShell+0x2b>
80109a3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109a3f:	5d                   	pop    %ebp
80109a40:	c3                   	ret    

80109a41 <isInit>:

int
isInit(){
80109a41:	55                   	push   %ebp
80109a42:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 'i') && (proc->name[1] == 'n') && (proc->name[2] == 'i') && (proc->name[3] == 't');
80109a44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a4a:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109a4e:	3c 69                	cmp    $0x69,%al
80109a50:	75 31                	jne    80109a83 <isInit+0x42>
80109a52:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a58:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109a5c:	3c 6e                	cmp    $0x6e,%al
80109a5e:	75 23                	jne    80109a83 <isInit+0x42>
80109a60:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a66:	0f b6 40 6e          	movzbl 0x6e(%eax),%eax
80109a6a:	3c 69                	cmp    $0x69,%al
80109a6c:	75 15                	jne    80109a83 <isInit+0x42>
80109a6e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a74:	0f b6 40 6f          	movzbl 0x6f(%eax),%eax
80109a78:	3c 74                	cmp    $0x74,%al
80109a7a:	75 07                	jne    80109a83 <isInit+0x42>
80109a7c:	b8 01 00 00 00       	mov    $0x1,%eax
80109a81:	eb 05                	jmp    80109a88 <isInit+0x47>
80109a83:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109a88:	5d                   	pop    %ebp
80109a89:	c3                   	ret    
