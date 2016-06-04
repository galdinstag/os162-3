
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
8010002d:	b8 a1 3e 10 80       	mov    $0x80103ea1,%eax
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
8010003a:	c7 44 24 04 d0 9a 10 	movl   $0x80109ad0,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 71 57 00 00       	call   801057bf <initlock>

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
801000bd:	e8 1e 57 00 00       	call   801057e0 <acquire>

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
80100104:	e8 39 57 00 00       	call   80105842 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 74 53 00 00       	call   80105498 <sleep>
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
8010017c:	e8 c1 56 00 00       	call   80105842 <release>
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
80100198:	c7 04 24 d7 9a 10 80 	movl   $0x80109ad7,(%esp)
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
801001d3:	e8 ee 2c 00 00       	call   80102ec6 <iderw>
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
801001ef:	c7 04 24 e8 9a 10 80 	movl   $0x80109ae8,(%esp)
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
80100210:	e8 b1 2c 00 00       	call   80102ec6 <iderw>
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
80100229:	c7 04 24 ef 9a 10 80 	movl   $0x80109aef,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 9f 55 00 00       	call   801057e0 <acquire>

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
8010029d:	e8 d2 52 00 00       	call   80105574 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 94 55 00 00       	call   80105842 <release>
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
801003bb:	e8 20 54 00 00       	call   801057e0 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 f6 9a 10 80 	movl   $0x80109af6,(%esp)
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
801004b0:	c7 45 ec ff 9a 10 80 	movl   $0x80109aff,-0x14(%ebp)
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
80100533:	e8 0a 53 00 00       	call   80105842 <release>
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
8010055f:	c7 04 24 06 9b 10 80 	movl   $0x80109b06,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 15 9b 10 80 	movl   $0x80109b15,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 fd 52 00 00       	call   80105891 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 17 9b 10 80 	movl   $0x80109b17,(%esp)
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
80100699:	c7 04 24 1b 9b 10 80 	movl   $0x80109b1b,(%esp)
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
801006cd:	e8 31 54 00 00       	call   80105b03 <memmove>
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
801006fc:	e8 33 53 00 00       	call   80105a34 <memset>
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
80100791:	e8 fb 6c 00 00       	call   80107491 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 ef 6c 00 00       	call   80107491 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 e3 6c 00 00       	call   80107491 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 d6 6c 00 00       	call   80107491 <uartputc>
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
801007dc:	e8 ff 4f 00 00       	call   801057e0 <acquire>
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
80100917:	e8 58 4c 00 00       	call   80105574 <wakeup>
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
80100938:	e8 05 4f 00 00       	call   80105842 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 d2 4c 00 00       	call   8010561a <procdump>
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
80100956:	e8 13 12 00 00       	call   80101b6e <iunlock>
  target = n;
8010095b:	8b 45 10             	mov    0x10(%ebp),%eax
8010095e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100961:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100968:	e8 73 4e 00 00       	call   801057e0 <acquire>
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
80100988:	e8 b5 4e 00 00       	call   80105842 <release>
        ilock(ip);
8010098d:	8b 45 08             	mov    0x8(%ebp),%eax
80100990:	89 04 24             	mov    %eax,(%esp)
80100993:	e8 82 10 00 00       	call   80101a1a <ilock>
        return -1;
80100998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010099d:	e9 a5 00 00 00       	jmp    80100a47 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
801009a2:	c7 44 24 04 c0 d5 10 	movl   $0x8010d5c0,0x4(%esp)
801009a9:	80 
801009aa:	c7 04 24 00 28 11 80 	movl   $0x80112800,(%esp)
801009b1:	e8 e2 4a 00 00       	call   80105498 <sleep>

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
80100a2d:	e8 10 4e 00 00       	call   80105842 <release>
  ilock(ip);
80100a32:	8b 45 08             	mov    0x8(%ebp),%eax
80100a35:	89 04 24             	mov    %eax,(%esp)
80100a38:	e8 dd 0f 00 00       	call   80101a1a <ilock>

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
80100a55:	e8 14 11 00 00       	call   80101b6e <iunlock>
  acquire(&cons.lock);
80100a5a:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100a61:	e8 7a 4d 00 00       	call   801057e0 <acquire>
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
80100a9b:	e8 a2 4d 00 00       	call   80105842 <release>
  ilock(ip);
80100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
80100aa3:	89 04 24             	mov    %eax,(%esp)
80100aa6:	e8 6f 0f 00 00       	call   80101a1a <ilock>

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
80100ab6:	c7 44 24 04 2e 9b 10 	movl   $0x80109b2e,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 f5 4c 00 00       	call   801057bf <initlock>

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
80100aef:	e8 45 3a 00 00       	call   80104539 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 7a 25 00 00       	call   80103082 <ioapicenable>
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
80100b13:	e8 82 30 00 00       	call   80103b9a <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 a8 1a 00 00       	call   801025cb <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 ed 30 00 00       	call   80103c1e <end_op>
    return -1;
80100b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b36:	e9 2e 05 00 00       	jmp    80101069 <exec+0x55f>
  }
  ilock(ip);
80100b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b3e:	89 04 24             	mov    %eax,(%esp)
80100b41:	e8 d4 0e 00 00       	call   80101a1a <ilock>
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
80100b6d:	e8 bb 13 00 00       	call   80101f2d <readi>
80100b72:	83 f8 33             	cmp    $0x33,%eax
80100b75:	77 05                	ja     80100b7c <exec+0x72>
    goto bad;
80100b77:	e9 b9 04 00 00       	jmp    80101035 <exec+0x52b>
  if(elf.magic != ELF_MAGIC)
80100b7c:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100b82:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b87:	74 05                	je     80100b8e <exec+0x84>
    goto bad;
80100b89:	e9 a7 04 00 00       	jmp    80101035 <exec+0x52b>
  if((pgdir = setupkvm()) == 0)
80100b8e:	e8 4f 7a 00 00       	call   801085e2 <setupkvm>
80100b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b96:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b9a:	75 05                	jne    80100ba1 <exec+0x97>
    goto bad;
80100b9c:	e9 94 04 00 00       	jmp    80101035 <exec+0x52b>

  // Load program into memory.
  sz = 0;
80100ba1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  proc->numOfPages = 0;
80100ba8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100bae:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80100bb5:	00 00 00 
  proc->copyingSwapFile = 0;
80100bb8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100bbe:	c7 80 ec 02 00 00 00 	movl   $0x0,0x2ec(%eax)
80100bc5:	00 00 00 
  int j;
  for(j = 0; j < 30; j++){
80100bc8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
80100bcf:	e9 a6 00 00 00       	jmp    80100c7a <exec+0x170>
    proc->pagesMetaData[j].va = (char *) -1;
80100bd4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bdb:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bde:	89 d0                	mov    %edx,%eax
80100be0:	c1 e0 02             	shl    $0x2,%eax
80100be3:	01 d0                	add    %edx,%eax
80100be5:	c1 e0 02             	shl    $0x2,%eax
80100be8:	01 c8                	add    %ecx,%eax
80100bea:	05 90 00 00 00       	add    $0x90,%eax
80100bef:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    proc->pagesMetaData[j].isPhysical = 0;
80100bf5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bfc:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bff:	89 d0                	mov    %edx,%eax
80100c01:	c1 e0 02             	shl    $0x2,%eax
80100c04:	01 d0                	add    %edx,%eax
80100c06:	c1 e0 02             	shl    $0x2,%eax
80100c09:	01 c8                	add    %ecx,%eax
80100c0b:	05 94 00 00 00       	add    $0x94,%eax
80100c10:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    proc->pagesMetaData[j].fileOffset = -1;
80100c16:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c1d:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c20:	89 d0                	mov    %edx,%eax
80100c22:	c1 e0 02             	shl    $0x2,%eax
80100c25:	01 d0                	add    %edx,%eax
80100c27:	c1 e0 02             	shl    $0x2,%eax
80100c2a:	01 c8                	add    %ecx,%eax
80100c2c:	05 98 00 00 00       	add    $0x98,%eax
80100c31:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    proc->pagesMetaData[j].count = 0;
80100c37:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c3e:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c41:	89 d0                	mov    %edx,%eax
80100c43:	c1 e0 02             	shl    $0x2,%eax
80100c46:	01 d0                	add    %edx,%eax
80100c48:	c1 e0 02             	shl    $0x2,%eax
80100c4b:	01 c8                	add    %ecx,%eax
80100c4d:	05 9c 00 00 00       	add    $0x9c,%eax
80100c52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    proc->pagesMetaData[j].lru = 0x80;
80100c58:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100c5f:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100c62:	89 d0                	mov    %edx,%eax
80100c64:	c1 e0 02             	shl    $0x2,%eax
80100c67:	01 d0                	add    %edx,%eax
80100c69:	c1 e0 02             	shl    $0x2,%eax
80100c6c:	01 c8                	add    %ecx,%eax
80100c6e:	05 a0 00 00 00       	add    $0xa0,%eax
80100c73:	c6 00 80             	movb   $0x80,(%eax)
  // Load program into memory.
  sz = 0;
  proc->numOfPages = 0;
  proc->copyingSwapFile = 0;
  int j;
  for(j = 0; j < 30; j++){
80100c76:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
80100c7a:	83 7d d0 1d          	cmpl   $0x1d,-0x30(%ebp)
80100c7e:	0f 8e 50 ff ff ff    	jle    80100bd4 <exec+0xca>
    proc->pagesMetaData[j].isPhysical = 0;
    proc->pagesMetaData[j].fileOffset = -1;
    proc->pagesMetaData[j].count = 0;
    proc->pagesMetaData[j].lru = 0x80;
  }
  proc->memoryPagesCounter = 0;
80100c84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c8a:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80100c91:	00 00 00 
  proc->swapedPagesCounter = 0;
80100c94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c9a:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80100ca1:	00 00 00 
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100ca4:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100cab:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100cb1:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100cb4:	e9 d5 00 00 00       	jmp    80100d8e <exec+0x284>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100cb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100cbc:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100cc3:	00 
80100cc4:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cc8:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100cce:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd2:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cd5:	89 04 24             	mov    %eax,(%esp)
80100cd8:	e8 50 12 00 00       	call   80101f2d <readi>
80100cdd:	83 f8 20             	cmp    $0x20,%eax
80100ce0:	74 05                	je     80100ce7 <exec+0x1dd>
      goto bad;
80100ce2:	e9 4e 03 00 00       	jmp    80101035 <exec+0x52b>
    if(ph.type != ELF_PROG_LOAD)
80100ce7:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100ced:	83 f8 01             	cmp    $0x1,%eax
80100cf0:	74 05                	je     80100cf7 <exec+0x1ed>
      continue;
80100cf2:	e9 8a 00 00 00       	jmp    80100d81 <exec+0x277>
    if(ph.memsz < ph.filesz)
80100cf7:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100cfd:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100d03:	39 c2                	cmp    %eax,%edx
80100d05:	73 05                	jae    80100d0c <exec+0x202>
      goto bad;
80100d07:	e9 29 03 00 00       	jmp    80101035 <exec+0x52b>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
80100d0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100d12:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d18:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100d1e:	01 ca                	add    %ecx,%edx
80100d20:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100d24:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d28:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d2f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d32:	89 04 24             	mov    %eax,(%esp)
80100d35:	e8 76 7c 00 00       	call   801089b0 <allocuvm>
80100d3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d41:	75 05                	jne    80100d48 <exec+0x23e>
      goto bad;
80100d43:	e9 ed 02 00 00       	jmp    80101035 <exec+0x52b>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100d48:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100d4e:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100d54:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100d5a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100d5e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d62:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100d65:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d69:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d70:	89 04 24             	mov    %eax,(%esp)
80100d73:	e8 4d 7b 00 00       	call   801088c5 <loaduvm>
80100d78:	85 c0                	test   %eax,%eax
80100d7a:	79 05                	jns    80100d81 <exec+0x277>
      goto bad;
80100d7c:	e9 b4 02 00 00       	jmp    80101035 <exec+0x52b>
    proc->pagesMetaData[j].count = 0;
    proc->pagesMetaData[j].lru = 0x80;
  }
  proc->memoryPagesCounter = 0;
  proc->swapedPagesCounter = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d81:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d85:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d88:	83 c0 20             	add    $0x20,%eax
80100d8b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d8e:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d95:	0f b7 c0             	movzwl %ax,%eax
80100d98:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d9b:	0f 8f 18 ff ff ff    	jg     80100cb9 <exec+0x1af>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100da1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100da4:	89 04 24             	mov    %eax,(%esp)
80100da7:	e8 f8 0e 00 00       	call   80101ca4 <iunlockput>
  end_op();
80100dac:	e8 6d 2e 00 00       	call   80103c1e <end_op>
  ip = 0;
80100db1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100db8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100dbb:	05 ff 0f 00 00       	add    $0xfff,%eax
80100dc0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100dc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE,proc)) == 0)
80100dc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100dce:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100dd1:	81 c2 00 20 00 00    	add    $0x2000,%edx
80100dd7:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100ddb:	89 54 24 08          	mov    %edx,0x8(%esp)
80100ddf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100de2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100de6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100de9:	89 04 24             	mov    %eax,(%esp)
80100dec:	e8 bf 7b 00 00       	call   801089b0 <allocuvm>
80100df1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100df4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100df8:	75 05                	jne    80100dff <exec+0x2f5>
    goto bad;
80100dfa:	e9 36 02 00 00       	jmp    80101035 <exec+0x52b>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100dff:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e02:	2d 00 20 00 00       	sub    $0x2000,%eax
80100e07:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e0e:	89 04 24             	mov    %eax,(%esp)
80100e11:	e8 8d 80 00 00       	call   80108ea3 <clearpteu>
  sp = sz;
80100e16:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e19:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e1c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100e23:	e9 9a 00 00 00       	jmp    80100ec2 <exec+0x3b8>
    if(argc >= MAXARG)
80100e28:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100e2c:	76 05                	jbe    80100e33 <exec+0x329>
      goto bad;
80100e2e:	e9 02 02 00 00       	jmp    80101035 <exec+0x52b>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100e33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e36:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e40:	01 d0                	add    %edx,%eax
80100e42:	8b 00                	mov    (%eax),%eax
80100e44:	89 04 24             	mov    %eax,(%esp)
80100e47:	e8 52 4e 00 00       	call   80105c9e <strlen>
80100e4c:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100e4f:	29 c2                	sub    %eax,%edx
80100e51:	89 d0                	mov    %edx,%eax
80100e53:	83 e8 01             	sub    $0x1,%eax
80100e56:	83 e0 fc             	and    $0xfffffffc,%eax
80100e59:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100e5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e5f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e66:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e69:	01 d0                	add    %edx,%eax
80100e6b:	8b 00                	mov    (%eax),%eax
80100e6d:	89 04 24             	mov    %eax,(%esp)
80100e70:	e8 29 4e 00 00       	call   80105c9e <strlen>
80100e75:	83 c0 01             	add    $0x1,%eax
80100e78:	89 c2                	mov    %eax,%edx
80100e7a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e7d:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100e84:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e87:	01 c8                	add    %ecx,%eax
80100e89:	8b 00                	mov    (%eax),%eax
80100e8b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100e8f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e93:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e96:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e9d:	89 04 24             	mov    %eax,(%esp)
80100ea0:	e8 d6 83 00 00       	call   8010927b <copyout>
80100ea5:	85 c0                	test   %eax,%eax
80100ea7:	79 05                	jns    80100eae <exec+0x3a4>
      goto bad;
80100ea9:	e9 87 01 00 00       	jmp    80101035 <exec+0x52b>
    ustack[3+argc] = sp;
80100eae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eb1:	8d 50 03             	lea    0x3(%eax),%edx
80100eb4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100eb7:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ebe:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100ec2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ec5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ecf:	01 d0                	add    %edx,%eax
80100ed1:	8b 00                	mov    (%eax),%eax
80100ed3:	85 c0                	test   %eax,%eax
80100ed5:	0f 85 4d ff ff ff    	jne    80100e28 <exec+0x31e>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100edb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ede:	83 c0 03             	add    $0x3,%eax
80100ee1:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100ee8:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100eec:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100ef3:	ff ff ff 
  ustack[1] = argc;
80100ef6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ef9:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100eff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f02:	83 c0 01             	add    $0x1,%eax
80100f05:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100f0c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100f0f:	29 d0                	sub    %edx,%eax
80100f11:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100f17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f1a:	83 c0 04             	add    $0x4,%eax
80100f1d:	c1 e0 02             	shl    $0x2,%eax
80100f20:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100f23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f26:	83 c0 04             	add    $0x4,%eax
80100f29:	c1 e0 02             	shl    $0x2,%eax
80100f2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100f30:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100f36:	89 44 24 08          	mov    %eax,0x8(%esp)
80100f3a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100f3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f44:	89 04 24             	mov    %eax,(%esp)
80100f47:	e8 2f 83 00 00       	call   8010927b <copyout>
80100f4c:	85 c0                	test   %eax,%eax
80100f4e:	79 05                	jns    80100f55 <exec+0x44b>
    goto bad;
80100f50:	e9 e0 00 00 00       	jmp    80101035 <exec+0x52b>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f55:	8b 45 08             	mov    0x8(%ebp),%eax
80100f58:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100f5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100f61:	eb 17                	jmp    80100f7a <exec+0x470>
    if(*s == '/')
80100f63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f66:	0f b6 00             	movzbl (%eax),%eax
80100f69:	3c 2f                	cmp    $0x2f,%al
80100f6b:	75 09                	jne    80100f76 <exec+0x46c>
      last = s+1;
80100f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f70:	83 c0 01             	add    $0x1,%eax
80100f73:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f76:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f7d:	0f b6 00             	movzbl (%eax),%eax
80100f80:	84 c0                	test   %al,%al
80100f82:	75 df                	jne    80100f63 <exec+0x459>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f8a:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f8d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f94:	00 
80100f95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100f98:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f9c:	89 14 24             	mov    %edx,(%esp)
80100f9f:	e8 b0 4c 00 00       	call   80105c54 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100fa4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100faa:	8b 40 04             	mov    0x4(%eax),%eax
80100fad:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100fb0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fb6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100fb9:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100fbc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fc2:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100fc5:	89 10                	mov    %edx,(%eax)
  //change proc->pagesMetaData according to the new exec
  if(!isInit()){
80100fc7:	e8 b8 8a 00 00       	call   80109a84 <isInit>
80100fcc:	85 c0                	test   %eax,%eax
80100fce:	75 1c                	jne    80100fec <exec+0x4e2>
    removeSwapFile(proc);
80100fd0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fd6:	89 04 24             	mov    %eax,(%esp)
80100fd9:	e8 f2 16 00 00       	call   801026d0 <removeSwapFile>
    createSwapFile(proc);
80100fde:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fe4:	89 04 24             	mov    %eax,(%esp)
80100fe7:	e8 f0 18 00 00       	call   801028dc <createSwapFile>
  //END NEW
  }
  proc->tf->eip = elf.entry;  // main
80100fec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ff2:	8b 40 18             	mov    0x18(%eax),%eax
80100ff5:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100ffb:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ffe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101004:	8b 40 18             	mov    0x18(%eax),%eax
80101007:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010100a:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
8010100d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101013:	89 04 24             	mov    %eax,(%esp)
80101016:	e8 b8 76 00 00       	call   801086d3 <switchuvm>
  freevm(oldpgdir,0);
8010101b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101022:	00 
80101023:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101026:	89 04 24             	mov    %eax,(%esp)
80101029:	e8 d1 7d 00 00       	call   80108dff <freevm>
  return 0;
8010102e:	b8 00 00 00 00       	mov    $0x0,%eax
80101033:	eb 34                	jmp    80101069 <exec+0x55f>

 bad:
  if(pgdir)
80101035:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101039:	74 13                	je     8010104e <exec+0x544>
    freevm(pgdir,0);
8010103b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101042:	00 
80101043:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101046:	89 04 24             	mov    %eax,(%esp)
80101049:	e8 b1 7d 00 00       	call   80108dff <freevm>
  if(ip){
8010104e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101052:	74 10                	je     80101064 <exec+0x55a>
    iunlockput(ip);
80101054:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101057:	89 04 24             	mov    %eax,(%esp)
8010105a:	e8 45 0c 00 00       	call   80101ca4 <iunlockput>
    end_op();
8010105f:	e8 ba 2b 00 00       	call   80103c1e <end_op>
  }
  return -1;
80101064:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101069:	c9                   	leave  
8010106a:	c3                   	ret    

8010106b <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
8010106b:	55                   	push   %ebp
8010106c:	89 e5                	mov    %esp,%ebp
8010106e:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80101071:	c7 44 24 04 36 9b 10 	movl   $0x80109b36,0x4(%esp)
80101078:	80 
80101079:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101080:	e8 3a 47 00 00       	call   801057bf <initlock>
}
80101085:	c9                   	leave  
80101086:	c3                   	ret    

80101087 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101087:	55                   	push   %ebp
80101088:	89 e5                	mov    %esp,%ebp
8010108a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010108d:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101094:	e8 47 47 00 00       	call   801057e0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101099:	c7 45 f4 54 28 11 80 	movl   $0x80112854,-0xc(%ebp)
801010a0:	eb 29                	jmp    801010cb <filealloc+0x44>
    if(f->ref == 0){
801010a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010a5:	8b 40 04             	mov    0x4(%eax),%eax
801010a8:	85 c0                	test   %eax,%eax
801010aa:	75 1b                	jne    801010c7 <filealloc+0x40>
      f->ref = 1;
801010ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010af:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
801010b6:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010bd:	e8 80 47 00 00       	call   80105842 <release>
      return f;
801010c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010c5:	eb 1e                	jmp    801010e5 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801010c7:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
801010cb:	81 7d f4 b4 31 11 80 	cmpl   $0x801131b4,-0xc(%ebp)
801010d2:	72 ce                	jb     801010a2 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
801010d4:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010db:	e8 62 47 00 00       	call   80105842 <release>
  return 0;
801010e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801010e5:	c9                   	leave  
801010e6:	c3                   	ret    

801010e7 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
801010e7:	55                   	push   %ebp
801010e8:	89 e5                	mov    %esp,%ebp
801010ea:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
801010ed:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010f4:	e8 e7 46 00 00       	call   801057e0 <acquire>
  if(f->ref < 1)
801010f9:	8b 45 08             	mov    0x8(%ebp),%eax
801010fc:	8b 40 04             	mov    0x4(%eax),%eax
801010ff:	85 c0                	test   %eax,%eax
80101101:	7f 0c                	jg     8010110f <filedup+0x28>
    panic("filedup");
80101103:	c7 04 24 3d 9b 10 80 	movl   $0x80109b3d,(%esp)
8010110a:	e8 2b f4 ff ff       	call   8010053a <panic>
  f->ref++;
8010110f:	8b 45 08             	mov    0x8(%ebp),%eax
80101112:	8b 40 04             	mov    0x4(%eax),%eax
80101115:	8d 50 01             	lea    0x1(%eax),%edx
80101118:	8b 45 08             	mov    0x8(%ebp),%eax
8010111b:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010111e:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101125:	e8 18 47 00 00       	call   80105842 <release>
  return f;
8010112a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010112d:	c9                   	leave  
8010112e:	c3                   	ret    

8010112f <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010112f:	55                   	push   %ebp
80101130:	89 e5                	mov    %esp,%ebp
80101132:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101135:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010113c:	e8 9f 46 00 00       	call   801057e0 <acquire>
  if(f->ref < 1)
80101141:	8b 45 08             	mov    0x8(%ebp),%eax
80101144:	8b 40 04             	mov    0x4(%eax),%eax
80101147:	85 c0                	test   %eax,%eax
80101149:	7f 0c                	jg     80101157 <fileclose+0x28>
    panic("fileclose");
8010114b:	c7 04 24 45 9b 10 80 	movl   $0x80109b45,(%esp)
80101152:	e8 e3 f3 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80101157:	8b 45 08             	mov    0x8(%ebp),%eax
8010115a:	8b 40 04             	mov    0x4(%eax),%eax
8010115d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101160:	8b 45 08             	mov    0x8(%ebp),%eax
80101163:	89 50 04             	mov    %edx,0x4(%eax)
80101166:	8b 45 08             	mov    0x8(%ebp),%eax
80101169:	8b 40 04             	mov    0x4(%eax),%eax
8010116c:	85 c0                	test   %eax,%eax
8010116e:	7e 11                	jle    80101181 <fileclose+0x52>
    release(&ftable.lock);
80101170:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101177:	e8 c6 46 00 00       	call   80105842 <release>
8010117c:	e9 82 00 00 00       	jmp    80101203 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101181:	8b 45 08             	mov    0x8(%ebp),%eax
80101184:	8b 10                	mov    (%eax),%edx
80101186:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101189:	8b 50 04             	mov    0x4(%eax),%edx
8010118c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010118f:	8b 50 08             	mov    0x8(%eax),%edx
80101192:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101195:	8b 50 0c             	mov    0xc(%eax),%edx
80101198:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010119b:	8b 50 10             	mov    0x10(%eax),%edx
8010119e:	89 55 f0             	mov    %edx,-0x10(%ebp)
801011a1:	8b 40 14             	mov    0x14(%eax),%eax
801011a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801011a7:	8b 45 08             	mov    0x8(%ebp),%eax
801011aa:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801011b1:	8b 45 08             	mov    0x8(%ebp),%eax
801011b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
801011ba:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801011c1:	e8 7c 46 00 00       	call   80105842 <release>
  
  if(ff.type == FD_PIPE)
801011c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011c9:	83 f8 01             	cmp    $0x1,%eax
801011cc:	75 18                	jne    801011e6 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801011ce:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801011d2:	0f be d0             	movsbl %al,%edx
801011d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801011d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801011dc:	89 04 24             	mov    %eax,(%esp)
801011df:	e8 05 36 00 00       	call   801047e9 <pipeclose>
801011e4:	eb 1d                	jmp    80101203 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801011e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011e9:	83 f8 02             	cmp    $0x2,%eax
801011ec:	75 15                	jne    80101203 <fileclose+0xd4>
    begin_op();
801011ee:	e8 a7 29 00 00       	call   80103b9a <begin_op>
    iput(ff.ip);
801011f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801011f6:	89 04 24             	mov    %eax,(%esp)
801011f9:	e8 d5 09 00 00       	call   80101bd3 <iput>
    end_op();
801011fe:	e8 1b 2a 00 00       	call   80103c1e <end_op>
  }
}
80101203:	c9                   	leave  
80101204:	c3                   	ret    

80101205 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101205:	55                   	push   %ebp
80101206:	89 e5                	mov    %esp,%ebp
80101208:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
8010120b:	8b 45 08             	mov    0x8(%ebp),%eax
8010120e:	8b 00                	mov    (%eax),%eax
80101210:	83 f8 02             	cmp    $0x2,%eax
80101213:	75 38                	jne    8010124d <filestat+0x48>
    ilock(f->ip);
80101215:	8b 45 08             	mov    0x8(%ebp),%eax
80101218:	8b 40 10             	mov    0x10(%eax),%eax
8010121b:	89 04 24             	mov    %eax,(%esp)
8010121e:	e8 f7 07 00 00       	call   80101a1a <ilock>
    stati(f->ip, st);
80101223:	8b 45 08             	mov    0x8(%ebp),%eax
80101226:	8b 40 10             	mov    0x10(%eax),%eax
80101229:	8b 55 0c             	mov    0xc(%ebp),%edx
8010122c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101230:	89 04 24             	mov    %eax,(%esp)
80101233:	e8 b0 0c 00 00       	call   80101ee8 <stati>
    iunlock(f->ip);
80101238:	8b 45 08             	mov    0x8(%ebp),%eax
8010123b:	8b 40 10             	mov    0x10(%eax),%eax
8010123e:	89 04 24             	mov    %eax,(%esp)
80101241:	e8 28 09 00 00       	call   80101b6e <iunlock>
    return 0;
80101246:	b8 00 00 00 00       	mov    $0x0,%eax
8010124b:	eb 05                	jmp    80101252 <filestat+0x4d>
  }
  return -1;
8010124d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101252:	c9                   	leave  
80101253:	c3                   	ret    

80101254 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101254:	55                   	push   %ebp
80101255:	89 e5                	mov    %esp,%ebp
80101257:	83 ec 28             	sub    $0x28,%esp
  int r;
  if(f->readable == 0)
8010125a:	8b 45 08             	mov    0x8(%ebp),%eax
8010125d:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101261:	84 c0                	test   %al,%al
80101263:	75 0a                	jne    8010126f <fileread+0x1b>
    return -1;
80101265:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010126a:	e9 9f 00 00 00       	jmp    8010130e <fileread+0xba>
  if(f->type == FD_PIPE)
8010126f:	8b 45 08             	mov    0x8(%ebp),%eax
80101272:	8b 00                	mov    (%eax),%eax
80101274:	83 f8 01             	cmp    $0x1,%eax
80101277:	75 1e                	jne    80101297 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101279:	8b 45 08             	mov    0x8(%ebp),%eax
8010127c:	8b 40 0c             	mov    0xc(%eax),%eax
8010127f:	8b 55 10             	mov    0x10(%ebp),%edx
80101282:	89 54 24 08          	mov    %edx,0x8(%esp)
80101286:	8b 55 0c             	mov    0xc(%ebp),%edx
80101289:	89 54 24 04          	mov    %edx,0x4(%esp)
8010128d:	89 04 24             	mov    %eax,(%esp)
80101290:	e8 d5 36 00 00       	call   8010496a <piperead>
80101295:	eb 77                	jmp    8010130e <fileread+0xba>
  if(f->type == FD_INODE){
80101297:	8b 45 08             	mov    0x8(%ebp),%eax
8010129a:	8b 00                	mov    (%eax),%eax
8010129c:	83 f8 02             	cmp    $0x2,%eax
8010129f:	75 61                	jne    80101302 <fileread+0xae>
    ilock(f->ip);
801012a1:	8b 45 08             	mov    0x8(%ebp),%eax
801012a4:	8b 40 10             	mov    0x10(%eax),%eax
801012a7:	89 04 24             	mov    %eax,(%esp)
801012aa:	e8 6b 07 00 00       	call   80101a1a <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
801012af:	8b 4d 10             	mov    0x10(%ebp),%ecx
801012b2:	8b 45 08             	mov    0x8(%ebp),%eax
801012b5:	8b 50 14             	mov    0x14(%eax),%edx
801012b8:	8b 45 08             	mov    0x8(%ebp),%eax
801012bb:	8b 40 10             	mov    0x10(%eax),%eax
801012be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801012c2:	89 54 24 08          	mov    %edx,0x8(%esp)
801012c6:	8b 55 0c             	mov    0xc(%ebp),%edx
801012c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801012cd:	89 04 24             	mov    %eax,(%esp)
801012d0:	e8 58 0c 00 00       	call   80101f2d <readi>
801012d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801012d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801012dc:	7e 11                	jle    801012ef <fileread+0x9b>
      f->off += r;
801012de:	8b 45 08             	mov    0x8(%ebp),%eax
801012e1:	8b 50 14             	mov    0x14(%eax),%edx
801012e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012e7:	01 c2                	add    %eax,%edx
801012e9:	8b 45 08             	mov    0x8(%ebp),%eax
801012ec:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801012ef:	8b 45 08             	mov    0x8(%ebp),%eax
801012f2:	8b 40 10             	mov    0x10(%eax),%eax
801012f5:	89 04 24             	mov    %eax,(%esp)
801012f8:	e8 71 08 00 00       	call   80101b6e <iunlock>
    return r;
801012fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101300:	eb 0c                	jmp    8010130e <fileread+0xba>
  }
  panic("fileread");
80101302:	c7 04 24 4f 9b 10 80 	movl   $0x80109b4f,(%esp)
80101309:	e8 2c f2 ff ff       	call   8010053a <panic>
}
8010130e:	c9                   	leave  
8010130f:	c3                   	ret    

80101310 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80101310:	55                   	push   %ebp
80101311:	89 e5                	mov    %esp,%ebp
80101313:	53                   	push   %ebx
80101314:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101317:	8b 45 08             	mov    0x8(%ebp),%eax
8010131a:	0f b6 40 09          	movzbl 0x9(%eax),%eax
8010131e:	84 c0                	test   %al,%al
80101320:	75 0a                	jne    8010132c <filewrite+0x1c>
    return -1;
80101322:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101327:	e9 20 01 00 00       	jmp    8010144c <filewrite+0x13c>
  if(f->type == FD_PIPE)
8010132c:	8b 45 08             	mov    0x8(%ebp),%eax
8010132f:	8b 00                	mov    (%eax),%eax
80101331:	83 f8 01             	cmp    $0x1,%eax
80101334:	75 21                	jne    80101357 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101336:	8b 45 08             	mov    0x8(%ebp),%eax
80101339:	8b 40 0c             	mov    0xc(%eax),%eax
8010133c:	8b 55 10             	mov    0x10(%ebp),%edx
8010133f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101343:	8b 55 0c             	mov    0xc(%ebp),%edx
80101346:	89 54 24 04          	mov    %edx,0x4(%esp)
8010134a:	89 04 24             	mov    %eax,(%esp)
8010134d:	e8 29 35 00 00       	call   8010487b <pipewrite>
80101352:	e9 f5 00 00 00       	jmp    8010144c <filewrite+0x13c>
  if(f->type == FD_INODE){
80101357:	8b 45 08             	mov    0x8(%ebp),%eax
8010135a:	8b 00                	mov    (%eax),%eax
8010135c:	83 f8 02             	cmp    $0x2,%eax
8010135f:	0f 85 db 00 00 00    	jne    80101440 <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101365:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010136c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101373:	e9 a8 00 00 00       	jmp    80101420 <filewrite+0x110>
      int n1 = n - i;
80101378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137b:	8b 55 10             	mov    0x10(%ebp),%edx
8010137e:	29 c2                	sub    %eax,%edx
80101380:	89 d0                	mov    %edx,%eax
80101382:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101385:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101388:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010138b:	7e 06                	jle    80101393 <filewrite+0x83>
        n1 = max;
8010138d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101390:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101393:	e8 02 28 00 00       	call   80103b9a <begin_op>
      ilock(f->ip);
80101398:	8b 45 08             	mov    0x8(%ebp),%eax
8010139b:	8b 40 10             	mov    0x10(%eax),%eax
8010139e:	89 04 24             	mov    %eax,(%esp)
801013a1:	e8 74 06 00 00       	call   80101a1a <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0){
801013a6:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801013a9:	8b 45 08             	mov    0x8(%ebp),%eax
801013ac:	8b 50 14             	mov    0x14(%eax),%edx
801013af:	8b 5d f4             	mov    -0xc(%ebp),%ebx
801013b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801013b5:	01 c3                	add    %eax,%ebx
801013b7:	8b 45 08             	mov    0x8(%ebp),%eax
801013ba:	8b 40 10             	mov    0x10(%eax),%eax
801013bd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801013c1:	89 54 24 08          	mov    %edx,0x8(%esp)
801013c5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
801013c9:	89 04 24             	mov    %eax,(%esp)
801013cc:	e8 c0 0c 00 00       	call   80102091 <writei>
801013d1:	89 45 e8             	mov    %eax,-0x18(%ebp)
801013d4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013d8:	7e 11                	jle    801013eb <filewrite+0xdb>
        f->off += r;
801013da:	8b 45 08             	mov    0x8(%ebp),%eax
801013dd:	8b 50 14             	mov    0x14(%eax),%edx
801013e0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013e3:	01 c2                	add    %eax,%edx
801013e5:	8b 45 08             	mov    0x8(%ebp),%eax
801013e8:	89 50 14             	mov    %edx,0x14(%eax)
      }
      iunlock(f->ip);
801013eb:	8b 45 08             	mov    0x8(%ebp),%eax
801013ee:	8b 40 10             	mov    0x10(%eax),%eax
801013f1:	89 04 24             	mov    %eax,(%esp)
801013f4:	e8 75 07 00 00       	call   80101b6e <iunlock>
      end_op();
801013f9:	e8 20 28 00 00       	call   80103c1e <end_op>

      if(r < 0)
801013fe:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101402:	79 02                	jns    80101406 <filewrite+0xf6>
        break;
80101404:	eb 26                	jmp    8010142c <filewrite+0x11c>
      if(r != n1)
80101406:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101409:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010140c:	74 0c                	je     8010141a <filewrite+0x10a>
        panic("short filewrite");
8010140e:	c7 04 24 58 9b 10 80 	movl   $0x80109b58,(%esp)
80101415:	e8 20 f1 ff ff       	call   8010053a <panic>
      i += r;
8010141a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010141d:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
80101420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101423:	3b 45 10             	cmp    0x10(%ebp),%eax
80101426:	0f 8c 4c ff ff ff    	jl     80101378 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
8010142c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010142f:	3b 45 10             	cmp    0x10(%ebp),%eax
80101432:	75 05                	jne    80101439 <filewrite+0x129>
80101434:	8b 45 10             	mov    0x10(%ebp),%eax
80101437:	eb 05                	jmp    8010143e <filewrite+0x12e>
80101439:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010143e:	eb 0c                	jmp    8010144c <filewrite+0x13c>
  }
  panic("filewrite");
80101440:	c7 04 24 68 9b 10 80 	movl   $0x80109b68,(%esp)
80101447:	e8 ee f0 ff ff       	call   8010053a <panic>
}
8010144c:	83 c4 24             	add    $0x24,%esp
8010144f:	5b                   	pop    %ebx
80101450:	5d                   	pop    %ebp
80101451:	c3                   	ret    

80101452 <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101452:	55                   	push   %ebp
80101453:	89 e5                	mov    %esp,%ebp
80101455:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101458:	8b 45 08             	mov    0x8(%ebp),%eax
8010145b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101462:	00 
80101463:	89 04 24             	mov    %eax,(%esp)
80101466:	e8 3b ed ff ff       	call   801001a6 <bread>
8010146b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010146e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101471:	83 c0 18             	add    $0x18,%eax
80101474:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
8010147b:	00 
8010147c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101480:	8b 45 0c             	mov    0xc(%ebp),%eax
80101483:	89 04 24             	mov    %eax,(%esp)
80101486:	e8 78 46 00 00       	call   80105b03 <memmove>
  brelse(bp);
8010148b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010148e:	89 04 24             	mov    %eax,(%esp)
80101491:	e8 81 ed ff ff       	call   80100217 <brelse>
}
80101496:	c9                   	leave  
80101497:	c3                   	ret    

80101498 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101498:	55                   	push   %ebp
80101499:	89 e5                	mov    %esp,%ebp
8010149b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010149e:	8b 55 0c             	mov    0xc(%ebp),%edx
801014a1:	8b 45 08             	mov    0x8(%ebp),%eax
801014a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801014a8:	89 04 24             	mov    %eax,(%esp)
801014ab:	e8 f6 ec ff ff       	call   801001a6 <bread>
801014b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801014b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014b6:	83 c0 18             	add    $0x18,%eax
801014b9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801014c0:	00 
801014c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801014c8:	00 
801014c9:	89 04 24             	mov    %eax,(%esp)
801014cc:	e8 63 45 00 00       	call   80105a34 <memset>
  log_write(bp);
801014d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014d4:	89 04 24             	mov    %eax,(%esp)
801014d7:	e8 c9 28 00 00       	call   80103da5 <log_write>
  brelse(bp);
801014dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014df:	89 04 24             	mov    %eax,(%esp)
801014e2:	e8 30 ed ff ff       	call   80100217 <brelse>
}
801014e7:	c9                   	leave  
801014e8:	c3                   	ret    

801014e9 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801014e9:	55                   	push   %ebp
801014ea:	89 e5                	mov    %esp,%ebp
801014ec:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801014ef:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801014f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801014fd:	e9 07 01 00 00       	jmp    80101609 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
80101502:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101505:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
8010150b:	85 c0                	test   %eax,%eax
8010150d:	0f 48 c2             	cmovs  %edx,%eax
80101510:	c1 f8 0c             	sar    $0xc,%eax
80101513:	89 c2                	mov    %eax,%edx
80101515:	a1 38 32 11 80       	mov    0x80113238,%eax
8010151a:	01 d0                	add    %edx,%eax
8010151c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101520:	8b 45 08             	mov    0x8(%ebp),%eax
80101523:	89 04 24             	mov    %eax,(%esp)
80101526:	e8 7b ec ff ff       	call   801001a6 <bread>
8010152b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010152e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101535:	e9 9d 00 00 00       	jmp    801015d7 <balloc+0xee>
      m = 1 << (bi % 8);
8010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153d:	99                   	cltd   
8010153e:	c1 ea 1d             	shr    $0x1d,%edx
80101541:	01 d0                	add    %edx,%eax
80101543:	83 e0 07             	and    $0x7,%eax
80101546:	29 d0                	sub    %edx,%eax
80101548:	ba 01 00 00 00       	mov    $0x1,%edx
8010154d:	89 c1                	mov    %eax,%ecx
8010154f:	d3 e2                	shl    %cl,%edx
80101551:	89 d0                	mov    %edx,%eax
80101553:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101556:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101559:	8d 50 07             	lea    0x7(%eax),%edx
8010155c:	85 c0                	test   %eax,%eax
8010155e:	0f 48 c2             	cmovs  %edx,%eax
80101561:	c1 f8 03             	sar    $0x3,%eax
80101564:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101567:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010156c:	0f b6 c0             	movzbl %al,%eax
8010156f:	23 45 e8             	and    -0x18(%ebp),%eax
80101572:	85 c0                	test   %eax,%eax
80101574:	75 5d                	jne    801015d3 <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101576:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101579:	8d 50 07             	lea    0x7(%eax),%edx
8010157c:	85 c0                	test   %eax,%eax
8010157e:	0f 48 c2             	cmovs  %edx,%eax
80101581:	c1 f8 03             	sar    $0x3,%eax
80101584:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101587:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010158c:	89 d1                	mov    %edx,%ecx
8010158e:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101591:	09 ca                	or     %ecx,%edx
80101593:	89 d1                	mov    %edx,%ecx
80101595:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101598:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010159c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010159f:	89 04 24             	mov    %eax,(%esp)
801015a2:	e8 fe 27 00 00       	call   80103da5 <log_write>
        brelse(bp);
801015a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015aa:	89 04 24             	mov    %eax,(%esp)
801015ad:	e8 65 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801015b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015b8:	01 c2                	add    %eax,%edx
801015ba:	8b 45 08             	mov    0x8(%ebp),%eax
801015bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801015c1:	89 04 24             	mov    %eax,(%esp)
801015c4:	e8 cf fe ff ff       	call   80101498 <bzero>
        return b + bi;
801015c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015cf:	01 d0                	add    %edx,%eax
801015d1:	eb 52                	jmp    80101625 <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801015d3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801015d7:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801015de:	7f 17                	jg     801015f7 <balloc+0x10e>
801015e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015e6:	01 d0                	add    %edx,%eax
801015e8:	89 c2                	mov    %eax,%edx
801015ea:	a1 20 32 11 80       	mov    0x80113220,%eax
801015ef:	39 c2                	cmp    %eax,%edx
801015f1:	0f 82 43 ff ff ff    	jb     8010153a <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801015f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801015fa:	89 04 24             	mov    %eax,(%esp)
801015fd:	e8 15 ec ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
80101602:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101609:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010160c:	a1 20 32 11 80       	mov    0x80113220,%eax
80101611:	39 c2                	cmp    %eax,%edx
80101613:	0f 82 e9 fe ff ff    	jb     80101502 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101619:	c7 04 24 74 9b 10 80 	movl   $0x80109b74,(%esp)
80101620:	e8 15 ef ff ff       	call   8010053a <panic>
}
80101625:	c9                   	leave  
80101626:	c3                   	ret    

80101627 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101627:	55                   	push   %ebp
80101628:	89 e5                	mov    %esp,%ebp
8010162a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
8010162d:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
80101634:	80 
80101635:	8b 45 08             	mov    0x8(%ebp),%eax
80101638:	89 04 24             	mov    %eax,(%esp)
8010163b:	e8 12 fe ff ff       	call   80101452 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101640:	8b 45 0c             	mov    0xc(%ebp),%eax
80101643:	c1 e8 0c             	shr    $0xc,%eax
80101646:	89 c2                	mov    %eax,%edx
80101648:	a1 38 32 11 80       	mov    0x80113238,%eax
8010164d:	01 c2                	add    %eax,%edx
8010164f:	8b 45 08             	mov    0x8(%ebp),%eax
80101652:	89 54 24 04          	mov    %edx,0x4(%esp)
80101656:	89 04 24             	mov    %eax,(%esp)
80101659:	e8 48 eb ff ff       	call   801001a6 <bread>
8010165e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101661:	8b 45 0c             	mov    0xc(%ebp),%eax
80101664:	25 ff 0f 00 00       	and    $0xfff,%eax
80101669:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010166c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010166f:	99                   	cltd   
80101670:	c1 ea 1d             	shr    $0x1d,%edx
80101673:	01 d0                	add    %edx,%eax
80101675:	83 e0 07             	and    $0x7,%eax
80101678:	29 d0                	sub    %edx,%eax
8010167a:	ba 01 00 00 00       	mov    $0x1,%edx
8010167f:	89 c1                	mov    %eax,%ecx
80101681:	d3 e2                	shl    %cl,%edx
80101683:	89 d0                	mov    %edx,%eax
80101685:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101688:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010168b:	8d 50 07             	lea    0x7(%eax),%edx
8010168e:	85 c0                	test   %eax,%eax
80101690:	0f 48 c2             	cmovs  %edx,%eax
80101693:	c1 f8 03             	sar    $0x3,%eax
80101696:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101699:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010169e:	0f b6 c0             	movzbl %al,%eax
801016a1:	23 45 ec             	and    -0x14(%ebp),%eax
801016a4:	85 c0                	test   %eax,%eax
801016a6:	75 0c                	jne    801016b4 <bfree+0x8d>
    panic("freeing free block");
801016a8:	c7 04 24 8a 9b 10 80 	movl   $0x80109b8a,(%esp)
801016af:	e8 86 ee ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
801016b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016b7:	8d 50 07             	lea    0x7(%eax),%edx
801016ba:	85 c0                	test   %eax,%eax
801016bc:	0f 48 c2             	cmovs  %edx,%eax
801016bf:	c1 f8 03             	sar    $0x3,%eax
801016c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016c5:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801016ca:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801016cd:	f7 d1                	not    %ecx
801016cf:	21 ca                	and    %ecx,%edx
801016d1:	89 d1                	mov    %edx,%ecx
801016d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016d6:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801016da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016dd:	89 04 24             	mov    %eax,(%esp)
801016e0:	e8 c0 26 00 00       	call   80103da5 <log_write>
  brelse(bp);
801016e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016e8:	89 04 24             	mov    %eax,(%esp)
801016eb:	e8 27 eb ff ff       	call   80100217 <brelse>
}
801016f0:	c9                   	leave  
801016f1:	c3                   	ret    

801016f2 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
801016f2:	55                   	push   %ebp
801016f3:	89 e5                	mov    %esp,%ebp
801016f5:	57                   	push   %edi
801016f6:	56                   	push   %esi
801016f7:	53                   	push   %ebx
801016f8:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
801016fb:	c7 44 24 04 9d 9b 10 	movl   $0x80109b9d,0x4(%esp)
80101702:	80 
80101703:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010170a:	e8 b0 40 00 00       	call   801057bf <initlock>
  readsb(dev, &sb);
8010170f:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
80101716:	80 
80101717:	8b 45 08             	mov    0x8(%ebp),%eax
8010171a:	89 04 24             	mov    %eax,(%esp)
8010171d:	e8 30 fd ff ff       	call   80101452 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
80101722:	a1 38 32 11 80       	mov    0x80113238,%eax
80101727:	8b 3d 34 32 11 80    	mov    0x80113234,%edi
8010172d:	8b 35 30 32 11 80    	mov    0x80113230,%esi
80101733:	8b 1d 2c 32 11 80    	mov    0x8011322c,%ebx
80101739:	8b 0d 28 32 11 80    	mov    0x80113228,%ecx
8010173f:	8b 15 24 32 11 80    	mov    0x80113224,%edx
80101745:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101748:	8b 15 20 32 11 80    	mov    0x80113220,%edx
8010174e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101752:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101756:	89 74 24 14          	mov    %esi,0x14(%esp)
8010175a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010175e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101762:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101765:	89 44 24 08          	mov    %eax,0x8(%esp)
80101769:	89 d0                	mov    %edx,%eax
8010176b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010176f:	c7 04 24 a4 9b 10 80 	movl   $0x80109ba4,(%esp)
80101776:	e8 25 ec ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
8010177b:	83 c4 3c             	add    $0x3c,%esp
8010177e:	5b                   	pop    %ebx
8010177f:	5e                   	pop    %esi
80101780:	5f                   	pop    %edi
80101781:	5d                   	pop    %ebp
80101782:	c3                   	ret    

80101783 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101783:	55                   	push   %ebp
80101784:	89 e5                	mov    %esp,%ebp
80101786:	83 ec 28             	sub    $0x28,%esp
80101789:	8b 45 0c             	mov    0xc(%ebp),%eax
8010178c:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101790:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101797:	e9 9e 00 00 00       	jmp    8010183a <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
8010179c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179f:	c1 e8 03             	shr    $0x3,%eax
801017a2:	89 c2                	mov    %eax,%edx
801017a4:	a1 34 32 11 80       	mov    0x80113234,%eax
801017a9:	01 d0                	add    %edx,%eax
801017ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801017af:	8b 45 08             	mov    0x8(%ebp),%eax
801017b2:	89 04 24             	mov    %eax,(%esp)
801017b5:	e8 ec e9 ff ff       	call   801001a6 <bread>
801017ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801017bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017c0:	8d 50 18             	lea    0x18(%eax),%edx
801017c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c6:	83 e0 07             	and    $0x7,%eax
801017c9:	c1 e0 06             	shl    $0x6,%eax
801017cc:	01 d0                	add    %edx,%eax
801017ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801017d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017d4:	0f b7 00             	movzwl (%eax),%eax
801017d7:	66 85 c0             	test   %ax,%ax
801017da:	75 4f                	jne    8010182b <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
801017dc:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801017e3:	00 
801017e4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801017eb:	00 
801017ec:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ef:	89 04 24             	mov    %eax,(%esp)
801017f2:	e8 3d 42 00 00       	call   80105a34 <memset>
      dip->type = type;
801017f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017fa:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017fe:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101801:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101804:	89 04 24             	mov    %eax,(%esp)
80101807:	e8 99 25 00 00       	call   80103da5 <log_write>
      brelse(bp);
8010180c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010180f:	89 04 24             	mov    %eax,(%esp)
80101812:	e8 00 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010181e:	8b 45 08             	mov    0x8(%ebp),%eax
80101821:	89 04 24             	mov    %eax,(%esp)
80101824:	e8 ed 00 00 00       	call   80101916 <iget>
80101829:	eb 2b                	jmp    80101856 <ialloc+0xd3>
    }
    brelse(bp);
8010182b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010182e:	89 04 24             	mov    %eax,(%esp)
80101831:	e8 e1 e9 ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101836:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010183a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010183d:	a1 28 32 11 80       	mov    0x80113228,%eax
80101842:	39 c2                	cmp    %eax,%edx
80101844:	0f 82 52 ff ff ff    	jb     8010179c <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010184a:	c7 04 24 f7 9b 10 80 	movl   $0x80109bf7,(%esp)
80101851:	e8 e4 ec ff ff       	call   8010053a <panic>
}
80101856:	c9                   	leave  
80101857:	c3                   	ret    

80101858 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101858:	55                   	push   %ebp
80101859:	89 e5                	mov    %esp,%ebp
8010185b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
8010185e:	8b 45 08             	mov    0x8(%ebp),%eax
80101861:	8b 40 04             	mov    0x4(%eax),%eax
80101864:	c1 e8 03             	shr    $0x3,%eax
80101867:	89 c2                	mov    %eax,%edx
80101869:	a1 34 32 11 80       	mov    0x80113234,%eax
8010186e:	01 c2                	add    %eax,%edx
80101870:	8b 45 08             	mov    0x8(%ebp),%eax
80101873:	8b 00                	mov    (%eax),%eax
80101875:	89 54 24 04          	mov    %edx,0x4(%esp)
80101879:	89 04 24             	mov    %eax,(%esp)
8010187c:	e8 25 e9 ff ff       	call   801001a6 <bread>
80101881:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101884:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101887:	8d 50 18             	lea    0x18(%eax),%edx
8010188a:	8b 45 08             	mov    0x8(%ebp),%eax
8010188d:	8b 40 04             	mov    0x4(%eax),%eax
80101890:	83 e0 07             	and    $0x7,%eax
80101893:	c1 e0 06             	shl    $0x6,%eax
80101896:	01 d0                	add    %edx,%eax
80101898:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010189b:	8b 45 08             	mov    0x8(%ebp),%eax
8010189e:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801018a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018a5:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801018a8:	8b 45 08             	mov    0x8(%ebp),%eax
801018ab:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801018af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b2:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801018b6:	8b 45 08             	mov    0x8(%ebp),%eax
801018b9:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801018bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018c0:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801018c4:	8b 45 08             	mov    0x8(%ebp),%eax
801018c7:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801018cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018ce:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801018d2:	8b 45 08             	mov    0x8(%ebp),%eax
801018d5:	8b 50 18             	mov    0x18(%eax),%edx
801018d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018db:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801018de:	8b 45 08             	mov    0x8(%ebp),%eax
801018e1:	8d 50 1c             	lea    0x1c(%eax),%edx
801018e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018e7:	83 c0 0c             	add    $0xc,%eax
801018ea:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801018f1:	00 
801018f2:	89 54 24 04          	mov    %edx,0x4(%esp)
801018f6:	89 04 24             	mov    %eax,(%esp)
801018f9:	e8 05 42 00 00       	call   80105b03 <memmove>
  log_write(bp);
801018fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101901:	89 04 24             	mov    %eax,(%esp)
80101904:	e8 9c 24 00 00       	call   80103da5 <log_write>
  brelse(bp);
80101909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010190c:	89 04 24             	mov    %eax,(%esp)
8010190f:	e8 03 e9 ff ff       	call   80100217 <brelse>
}
80101914:	c9                   	leave  
80101915:	c3                   	ret    

80101916 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101916:	55                   	push   %ebp
80101917:	89 e5                	mov    %esp,%ebp
80101919:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010191c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101923:	e8 b8 3e 00 00       	call   801057e0 <acquire>

  // Is the inode already cached?
  empty = 0;
80101928:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010192f:	c7 45 f4 74 32 11 80 	movl   $0x80113274,-0xc(%ebp)
80101936:	eb 59                	jmp    80101991 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101938:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193b:	8b 40 08             	mov    0x8(%eax),%eax
8010193e:	85 c0                	test   %eax,%eax
80101940:	7e 35                	jle    80101977 <iget+0x61>
80101942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101945:	8b 00                	mov    (%eax),%eax
80101947:	3b 45 08             	cmp    0x8(%ebp),%eax
8010194a:	75 2b                	jne    80101977 <iget+0x61>
8010194c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010194f:	8b 40 04             	mov    0x4(%eax),%eax
80101952:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101955:	75 20                	jne    80101977 <iget+0x61>
      ip->ref++;
80101957:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010195a:	8b 40 08             	mov    0x8(%eax),%eax
8010195d:	8d 50 01             	lea    0x1(%eax),%edx
80101960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101963:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101966:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010196d:	e8 d0 3e 00 00       	call   80105842 <release>
      return ip;
80101972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101975:	eb 6f                	jmp    801019e6 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101977:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010197b:	75 10                	jne    8010198d <iget+0x77>
8010197d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101980:	8b 40 08             	mov    0x8(%eax),%eax
80101983:	85 c0                	test   %eax,%eax
80101985:	75 06                	jne    8010198d <iget+0x77>
      empty = ip;
80101987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010198a:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010198d:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101991:	81 7d f4 14 42 11 80 	cmpl   $0x80114214,-0xc(%ebp)
80101998:	72 9e                	jb     80101938 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010199a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010199e:	75 0c                	jne    801019ac <iget+0x96>
    panic("iget: no inodes");
801019a0:	c7 04 24 09 9c 10 80 	movl   $0x80109c09,(%esp)
801019a7:	e8 8e eb ff ff       	call   8010053a <panic>

  ip = empty;
801019ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019af:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801019b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b5:	8b 55 08             	mov    0x8(%ebp),%edx
801019b8:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801019ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019bd:	8b 55 0c             	mov    0xc(%ebp),%edx
801019c0:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801019c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c6:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801019cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019d0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801019d7:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019de:	e8 5f 3e 00 00       	call   80105842 <release>

  return ip;
801019e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801019e6:	c9                   	leave  
801019e7:	c3                   	ret    

801019e8 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801019e8:	55                   	push   %ebp
801019e9:	89 e5                	mov    %esp,%ebp
801019eb:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801019ee:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019f5:	e8 e6 3d 00 00       	call   801057e0 <acquire>
  ip->ref++;
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	8b 40 08             	mov    0x8(%eax),%eax
80101a00:	8d 50 01             	lea    0x1(%eax),%edx
80101a03:	8b 45 08             	mov    0x8(%ebp),%eax
80101a06:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101a09:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a10:	e8 2d 3e 00 00       	call   80105842 <release>
  return ip;
80101a15:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101a18:	c9                   	leave  
80101a19:	c3                   	ret    

80101a1a <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101a1a:	55                   	push   %ebp
80101a1b:	89 e5                	mov    %esp,%ebp
80101a1d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101a20:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a24:	74 0a                	je     80101a30 <ilock+0x16>
80101a26:	8b 45 08             	mov    0x8(%ebp),%eax
80101a29:	8b 40 08             	mov    0x8(%eax),%eax
80101a2c:	85 c0                	test   %eax,%eax
80101a2e:	7f 0c                	jg     80101a3c <ilock+0x22>
    panic("ilock");
80101a30:	c7 04 24 19 9c 10 80 	movl   $0x80109c19,(%esp)
80101a37:	e8 fe ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a43:	e8 98 3d 00 00       	call   801057e0 <acquire>
  while(ip->flags & I_BUSY)
80101a48:	eb 13                	jmp    80101a5d <ilock+0x43>
    sleep(ip, &icache.lock);
80101a4a:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
80101a51:	80 
80101a52:	8b 45 08             	mov    0x8(%ebp),%eax
80101a55:	89 04 24             	mov    %eax,(%esp)
80101a58:	e8 3b 3a 00 00       	call   80105498 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101a5d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a60:	8b 40 0c             	mov    0xc(%eax),%eax
80101a63:	83 e0 01             	and    $0x1,%eax
80101a66:	85 c0                	test   %eax,%eax
80101a68:	75 e0                	jne    80101a4a <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101a6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a6d:	8b 40 0c             	mov    0xc(%eax),%eax
80101a70:	83 c8 01             	or     $0x1,%eax
80101a73:	89 c2                	mov    %eax,%edx
80101a75:	8b 45 08             	mov    0x8(%ebp),%eax
80101a78:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101a7b:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a82:	e8 bb 3d 00 00       	call   80105842 <release>

  if(!(ip->flags & I_VALID)){
80101a87:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8a:	8b 40 0c             	mov    0xc(%eax),%eax
80101a8d:	83 e0 02             	and    $0x2,%eax
80101a90:	85 c0                	test   %eax,%eax
80101a92:	0f 85 d4 00 00 00    	jne    80101b6c <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a98:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9b:	8b 40 04             	mov    0x4(%eax),%eax
80101a9e:	c1 e8 03             	shr    $0x3,%eax
80101aa1:	89 c2                	mov    %eax,%edx
80101aa3:	a1 34 32 11 80       	mov    0x80113234,%eax
80101aa8:	01 c2                	add    %eax,%edx
80101aaa:	8b 45 08             	mov    0x8(%ebp),%eax
80101aad:	8b 00                	mov    (%eax),%eax
80101aaf:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ab3:	89 04 24             	mov    %eax,(%esp)
80101ab6:	e8 eb e6 ff ff       	call   801001a6 <bread>
80101abb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ac1:	8d 50 18             	lea    0x18(%eax),%edx
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	8b 40 04             	mov    0x4(%eax),%eax
80101aca:	83 e0 07             	and    $0x7,%eax
80101acd:	c1 e0 06             	shl    $0x6,%eax
80101ad0:	01 d0                	add    %edx,%eax
80101ad2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ad8:	0f b7 10             	movzwl (%eax),%edx
80101adb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ade:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ae5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101ae9:	8b 45 08             	mov    0x8(%ebp),%eax
80101aec:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101af3:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101af7:	8b 45 08             	mov    0x8(%ebp),%eax
80101afa:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101afe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b01:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101b05:	8b 45 08             	mov    0x8(%ebp),%eax
80101b08:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101b0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b0f:	8b 50 08             	mov    0x8(%eax),%edx
80101b12:	8b 45 08             	mov    0x8(%ebp),%eax
80101b15:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101b18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b1b:	8d 50 0c             	lea    0xc(%eax),%edx
80101b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b21:	83 c0 1c             	add    $0x1c,%eax
80101b24:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101b2b:	00 
80101b2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b30:	89 04 24             	mov    %eax,(%esp)
80101b33:	e8 cb 3f 00 00       	call   80105b03 <memmove>
    brelse(bp);
80101b38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b3b:	89 04 24             	mov    %eax,(%esp)
80101b3e:	e8 d4 e6 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101b43:	8b 45 08             	mov    0x8(%ebp),%eax
80101b46:	8b 40 0c             	mov    0xc(%eax),%eax
80101b49:	83 c8 02             	or     $0x2,%eax
80101b4c:	89 c2                	mov    %eax,%edx
80101b4e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b51:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101b54:	8b 45 08             	mov    0x8(%ebp),%eax
80101b57:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101b5b:	66 85 c0             	test   %ax,%ax
80101b5e:	75 0c                	jne    80101b6c <ilock+0x152>
      panic("ilock: no type");
80101b60:	c7 04 24 1f 9c 10 80 	movl   $0x80109c1f,(%esp)
80101b67:	e8 ce e9 ff ff       	call   8010053a <panic>
  }
}
80101b6c:	c9                   	leave  
80101b6d:	c3                   	ret    

80101b6e <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b6e:	55                   	push   %ebp
80101b6f:	89 e5                	mov    %esp,%ebp
80101b71:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101b74:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b78:	74 17                	je     80101b91 <iunlock+0x23>
80101b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7d:	8b 40 0c             	mov    0xc(%eax),%eax
80101b80:	83 e0 01             	and    $0x1,%eax
80101b83:	85 c0                	test   %eax,%eax
80101b85:	74 0a                	je     80101b91 <iunlock+0x23>
80101b87:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8a:	8b 40 08             	mov    0x8(%eax),%eax
80101b8d:	85 c0                	test   %eax,%eax
80101b8f:	7f 0c                	jg     80101b9d <iunlock+0x2f>
    panic("iunlock");
80101b91:	c7 04 24 2e 9c 10 80 	movl   $0x80109c2e,(%esp)
80101b98:	e8 9d e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b9d:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101ba4:	e8 37 3c 00 00       	call   801057e0 <acquire>
  ip->flags &= ~I_BUSY;
80101ba9:	8b 45 08             	mov    0x8(%ebp),%eax
80101bac:	8b 40 0c             	mov    0xc(%eax),%eax
80101baf:	83 e0 fe             	and    $0xfffffffe,%eax
80101bb2:	89 c2                	mov    %eax,%edx
80101bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb7:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101bba:	8b 45 08             	mov    0x8(%ebp),%eax
80101bbd:	89 04 24             	mov    %eax,(%esp)
80101bc0:	e8 af 39 00 00       	call   80105574 <wakeup>
  release(&icache.lock);
80101bc5:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101bcc:	e8 71 3c 00 00       	call   80105842 <release>
}
80101bd1:	c9                   	leave  
80101bd2:	c3                   	ret    

80101bd3 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101bd3:	55                   	push   %ebp
80101bd4:	89 e5                	mov    %esp,%ebp
80101bd6:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101bd9:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101be0:	e8 fb 3b 00 00       	call   801057e0 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101be5:	8b 45 08             	mov    0x8(%ebp),%eax
80101be8:	8b 40 08             	mov    0x8(%eax),%eax
80101beb:	83 f8 01             	cmp    $0x1,%eax
80101bee:	0f 85 93 00 00 00    	jne    80101c87 <iput+0xb4>
80101bf4:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf7:	8b 40 0c             	mov    0xc(%eax),%eax
80101bfa:	83 e0 02             	and    $0x2,%eax
80101bfd:	85 c0                	test   %eax,%eax
80101bff:	0f 84 82 00 00 00    	je     80101c87 <iput+0xb4>
80101c05:	8b 45 08             	mov    0x8(%ebp),%eax
80101c08:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101c0c:	66 85 c0             	test   %ax,%ax
80101c0f:	75 76                	jne    80101c87 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	8b 40 0c             	mov    0xc(%eax),%eax
80101c17:	83 e0 01             	and    $0x1,%eax
80101c1a:	85 c0                	test   %eax,%eax
80101c1c:	74 0c                	je     80101c2a <iput+0x57>
      panic("iput busy");
80101c1e:	c7 04 24 36 9c 10 80 	movl   $0x80109c36,(%esp)
80101c25:	e8 10 e9 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 40 0c             	mov    0xc(%eax),%eax
80101c30:	83 c8 01             	or     $0x1,%eax
80101c33:	89 c2                	mov    %eax,%edx
80101c35:	8b 45 08             	mov    0x8(%ebp),%eax
80101c38:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101c3b:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c42:	e8 fb 3b 00 00       	call   80105842 <release>
    itrunc(ip);
80101c47:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4a:	89 04 24             	mov    %eax,(%esp)
80101c4d:	e8 7d 01 00 00       	call   80101dcf <itrunc>
    ip->type = 0;
80101c52:	8b 45 08             	mov    0x8(%ebp),%eax
80101c55:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101c5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c5e:	89 04 24             	mov    %eax,(%esp)
80101c61:	e8 f2 fb ff ff       	call   80101858 <iupdate>
    acquire(&icache.lock);
80101c66:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c6d:	e8 6e 3b 00 00       	call   801057e0 <acquire>
    ip->flags = 0;
80101c72:	8b 45 08             	mov    0x8(%ebp),%eax
80101c75:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7f:	89 04 24             	mov    %eax,(%esp)
80101c82:	e8 ed 38 00 00       	call   80105574 <wakeup>
  }
  ip->ref--;
80101c87:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8a:	8b 40 08             	mov    0x8(%eax),%eax
80101c8d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c90:	8b 45 08             	mov    0x8(%ebp),%eax
80101c93:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c96:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c9d:	e8 a0 3b 00 00       	call   80105842 <release>
}
80101ca2:	c9                   	leave  
80101ca3:	c3                   	ret    

80101ca4 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101ca4:	55                   	push   %ebp
80101ca5:	89 e5                	mov    %esp,%ebp
80101ca7:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101caa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cad:	89 04 24             	mov    %eax,(%esp)
80101cb0:	e8 b9 fe ff ff       	call   80101b6e <iunlock>
  iput(ip);
80101cb5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb8:	89 04 24             	mov    %eax,(%esp)
80101cbb:	e8 13 ff ff ff       	call   80101bd3 <iput>
}
80101cc0:	c9                   	leave  
80101cc1:	c3                   	ret    

80101cc2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101cc2:	55                   	push   %ebp
80101cc3:	89 e5                	mov    %esp,%ebp
80101cc5:	53                   	push   %ebx
80101cc6:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101cc9:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101ccd:	77 3e                	ja     80101d0d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101ccf:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd2:	8b 55 0c             	mov    0xc(%ebp),%edx
80101cd5:	83 c2 04             	add    $0x4,%edx
80101cd8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101cdc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cdf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101ce3:	75 20                	jne    80101d05 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce8:	8b 00                	mov    (%eax),%eax
80101cea:	89 04 24             	mov    %eax,(%esp)
80101ced:	e8 f7 f7 ff ff       	call   801014e9 <balloc>
80101cf2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cf5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf8:	8b 55 0c             	mov    0xc(%ebp),%edx
80101cfb:	8d 4a 04             	lea    0x4(%edx),%ecx
80101cfe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d01:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d08:	e9 bc 00 00 00       	jmp    80101dc9 <bmap+0x107>
  }
  bn -= NDIRECT;
80101d0d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101d11:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101d15:	0f 87 a2 00 00 00    	ja     80101dbd <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d21:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d24:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d28:	75 19                	jne    80101d43 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2d:	8b 00                	mov    (%eax),%eax
80101d2f:	89 04 24             	mov    %eax,(%esp)
80101d32:	e8 b2 f7 ff ff       	call   801014e9 <balloc>
80101d37:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d40:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101d43:	8b 45 08             	mov    0x8(%ebp),%eax
80101d46:	8b 00                	mov    (%eax),%eax
80101d48:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d4b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d4f:	89 04 24             	mov    %eax,(%esp)
80101d52:	e8 4f e4 ff ff       	call   801001a6 <bread>
80101d57:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101d5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d5d:	83 c0 18             	add    $0x18,%eax
80101d60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d63:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d66:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d70:	01 d0                	add    %edx,%eax
80101d72:	8b 00                	mov    (%eax),%eax
80101d74:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d77:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d7b:	75 30                	jne    80101dad <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101d7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d80:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d87:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d8a:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d90:	8b 00                	mov    (%eax),%eax
80101d92:	89 04 24             	mov    %eax,(%esp)
80101d95:	e8 4f f7 ff ff       	call   801014e9 <balloc>
80101d9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101da0:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101da2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da5:	89 04 24             	mov    %eax,(%esp)
80101da8:	e8 f8 1f 00 00       	call   80103da5 <log_write>
    }
    brelse(bp);
80101dad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101db0:	89 04 24             	mov    %eax,(%esp)
80101db3:	e8 5f e4 ff ff       	call   80100217 <brelse>
    return addr;
80101db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dbb:	eb 0c                	jmp    80101dc9 <bmap+0x107>
  }

  panic("bmap: out of range");
80101dbd:	c7 04 24 40 9c 10 80 	movl   $0x80109c40,(%esp)
80101dc4:	e8 71 e7 ff ff       	call   8010053a <panic>
}
80101dc9:	83 c4 24             	add    $0x24,%esp
80101dcc:	5b                   	pop    %ebx
80101dcd:	5d                   	pop    %ebp
80101dce:	c3                   	ret    

80101dcf <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101dcf:	55                   	push   %ebp
80101dd0:	89 e5                	mov    %esp,%ebp
80101dd2:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101dd5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ddc:	eb 44                	jmp    80101e22 <itrunc+0x53>
    if(ip->addrs[i]){
80101dde:	8b 45 08             	mov    0x8(%ebp),%eax
80101de1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101de4:	83 c2 04             	add    $0x4,%edx
80101de7:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101deb:	85 c0                	test   %eax,%eax
80101ded:	74 2f                	je     80101e1e <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101def:	8b 45 08             	mov    0x8(%ebp),%eax
80101df2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101df5:	83 c2 04             	add    $0x4,%edx
80101df8:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80101dff:	8b 00                	mov    (%eax),%eax
80101e01:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e05:	89 04 24             	mov    %eax,(%esp)
80101e08:	e8 1a f8 ff ff       	call   80101627 <bfree>
      ip->addrs[i] = 0;
80101e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e10:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101e13:	83 c2 04             	add    $0x4,%edx
80101e16:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101e1d:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101e1e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e22:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101e26:	7e b6                	jle    80101dde <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101e28:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2b:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e2e:	85 c0                	test   %eax,%eax
80101e30:	0f 84 9b 00 00 00    	je     80101ed1 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101e36:	8b 45 08             	mov    0x8(%ebp),%eax
80101e39:	8b 50 4c             	mov    0x4c(%eax),%edx
80101e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e3f:	8b 00                	mov    (%eax),%eax
80101e41:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e45:	89 04 24             	mov    %eax,(%esp)
80101e48:	e8 59 e3 ff ff       	call   801001a6 <bread>
80101e4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e50:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e53:	83 c0 18             	add    $0x18,%eax
80101e56:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e59:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e60:	eb 3b                	jmp    80101e9d <itrunc+0xce>
      if(a[j])
80101e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e65:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e6c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e6f:	01 d0                	add    %edx,%eax
80101e71:	8b 00                	mov    (%eax),%eax
80101e73:	85 c0                	test   %eax,%eax
80101e75:	74 22                	je     80101e99 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101e77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e7a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e81:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e84:	01 d0                	add    %edx,%eax
80101e86:	8b 10                	mov    (%eax),%edx
80101e88:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8b:	8b 00                	mov    (%eax),%eax
80101e8d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e91:	89 04 24             	mov    %eax,(%esp)
80101e94:	e8 8e f7 ff ff       	call   80101627 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e99:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ea0:	83 f8 7f             	cmp    $0x7f,%eax
80101ea3:	76 bd                	jbe    80101e62 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101ea5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ea8:	89 04 24             	mov    %eax,(%esp)
80101eab:	e8 67 e3 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101eb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb3:	8b 50 4c             	mov    0x4c(%eax),%edx
80101eb6:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb9:	8b 00                	mov    (%eax),%eax
80101ebb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ebf:	89 04 24             	mov    %eax,(%esp)
80101ec2:	e8 60 f7 ff ff       	call   80101627 <bfree>
    ip->addrs[NDIRECT] = 0;
80101ec7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eca:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed4:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101edb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ede:	89 04 24             	mov    %eax,(%esp)
80101ee1:	e8 72 f9 ff ff       	call   80101858 <iupdate>
}
80101ee6:	c9                   	leave  
80101ee7:	c3                   	ret    

80101ee8 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101ee8:	55                   	push   %ebp
80101ee9:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80101eee:	8b 00                	mov    (%eax),%eax
80101ef0:	89 c2                	mov    %eax,%edx
80101ef2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ef5:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80101efb:	8b 50 04             	mov    0x4(%eax),%edx
80101efe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f01:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101f04:	8b 45 08             	mov    0x8(%ebp),%eax
80101f07:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f0e:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101f11:	8b 45 08             	mov    0x8(%ebp),%eax
80101f14:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101f18:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f1b:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101f1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f22:	8b 50 18             	mov    0x18(%eax),%edx
80101f25:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f28:	89 50 10             	mov    %edx,0x10(%eax)
}
80101f2b:	5d                   	pop    %ebp
80101f2c:	c3                   	ret    

80101f2d <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101f2d:	55                   	push   %ebp
80101f2e:	89 e5                	mov    %esp,%ebp
80101f30:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f33:	8b 45 08             	mov    0x8(%ebp),%eax
80101f36:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f3a:	66 83 f8 03          	cmp    $0x3,%ax
80101f3e:	75 60                	jne    80101fa0 <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f40:	8b 45 08             	mov    0x8(%ebp),%eax
80101f43:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f47:	66 85 c0             	test   %ax,%ax
80101f4a:	78 20                	js     80101f6c <readi+0x3f>
80101f4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f53:	66 83 f8 09          	cmp    $0x9,%ax
80101f57:	7f 13                	jg     80101f6c <readi+0x3f>
80101f59:	8b 45 08             	mov    0x8(%ebp),%eax
80101f5c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f60:	98                   	cwtl   
80101f61:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f68:	85 c0                	test   %eax,%eax
80101f6a:	75 0a                	jne    80101f76 <readi+0x49>
      return -1;
80101f6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f71:	e9 19 01 00 00       	jmp    8010208f <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101f76:	8b 45 08             	mov    0x8(%ebp),%eax
80101f79:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f7d:	98                   	cwtl   
80101f7e:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f85:	8b 55 14             	mov    0x14(%ebp),%edx
80101f88:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f8c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f93:	8b 55 08             	mov    0x8(%ebp),%edx
80101f96:	89 14 24             	mov    %edx,(%esp)
80101f99:	ff d0                	call   *%eax
80101f9b:	e9 ef 00 00 00       	jmp    8010208f <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101fa0:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa3:	8b 40 18             	mov    0x18(%eax),%eax
80101fa6:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fa9:	72 0d                	jb     80101fb8 <readi+0x8b>
80101fab:	8b 45 14             	mov    0x14(%ebp),%eax
80101fae:	8b 55 10             	mov    0x10(%ebp),%edx
80101fb1:	01 d0                	add    %edx,%eax
80101fb3:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fb6:	73 0a                	jae    80101fc2 <readi+0x95>
    return -1;
80101fb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fbd:	e9 cd 00 00 00       	jmp    8010208f <readi+0x162>
  if(off + n > ip->size)
80101fc2:	8b 45 14             	mov    0x14(%ebp),%eax
80101fc5:	8b 55 10             	mov    0x10(%ebp),%edx
80101fc8:	01 c2                	add    %eax,%edx
80101fca:	8b 45 08             	mov    0x8(%ebp),%eax
80101fcd:	8b 40 18             	mov    0x18(%eax),%eax
80101fd0:	39 c2                	cmp    %eax,%edx
80101fd2:	76 0c                	jbe    80101fe0 <readi+0xb3>
    n = ip->size - off;
80101fd4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd7:	8b 40 18             	mov    0x18(%eax),%eax
80101fda:	2b 45 10             	sub    0x10(%ebp),%eax
80101fdd:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fe0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fe7:	e9 94 00 00 00       	jmp    80102080 <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fec:	8b 45 10             	mov    0x10(%ebp),%eax
80101fef:	c1 e8 09             	shr    $0x9,%eax
80101ff2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff9:	89 04 24             	mov    %eax,(%esp)
80101ffc:	e8 c1 fc ff ff       	call   80101cc2 <bmap>
80102001:	8b 55 08             	mov    0x8(%ebp),%edx
80102004:	8b 12                	mov    (%edx),%edx
80102006:	89 44 24 04          	mov    %eax,0x4(%esp)
8010200a:	89 14 24             	mov    %edx,(%esp)
8010200d:	e8 94 e1 ff ff       	call   801001a6 <bread>
80102012:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102015:	8b 45 10             	mov    0x10(%ebp),%eax
80102018:	25 ff 01 00 00       	and    $0x1ff,%eax
8010201d:	89 c2                	mov    %eax,%edx
8010201f:	b8 00 02 00 00       	mov    $0x200,%eax
80102024:	29 d0                	sub    %edx,%eax
80102026:	89 c2                	mov    %eax,%edx
80102028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010202b:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010202e:	29 c1                	sub    %eax,%ecx
80102030:	89 c8                	mov    %ecx,%eax
80102032:	39 c2                	cmp    %eax,%edx
80102034:	0f 46 c2             	cmovbe %edx,%eax
80102037:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
8010203a:	8b 45 10             	mov    0x10(%ebp),%eax
8010203d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102042:	8d 50 10             	lea    0x10(%eax),%edx
80102045:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102048:	01 d0                	add    %edx,%eax
8010204a:	8d 50 08             	lea    0x8(%eax),%edx
8010204d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102050:	89 44 24 08          	mov    %eax,0x8(%esp)
80102054:	89 54 24 04          	mov    %edx,0x4(%esp)
80102058:	8b 45 0c             	mov    0xc(%ebp),%eax
8010205b:	89 04 24             	mov    %eax,(%esp)
8010205e:	e8 a0 3a 00 00       	call   80105b03 <memmove>
    brelse(bp);
80102063:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102066:	89 04 24             	mov    %eax,(%esp)
80102069:	e8 a9 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010206e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102071:	01 45 f4             	add    %eax,-0xc(%ebp)
80102074:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102077:	01 45 10             	add    %eax,0x10(%ebp)
8010207a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010207d:	01 45 0c             	add    %eax,0xc(%ebp)
80102080:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102083:	3b 45 14             	cmp    0x14(%ebp),%eax
80102086:	0f 82 60 ff ff ff    	jb     80101fec <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010208c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010208f:	c9                   	leave  
80102090:	c3                   	ret    

80102091 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102091:	55                   	push   %ebp
80102092:	89 e5                	mov    %esp,%ebp
80102094:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102097:	8b 45 08             	mov    0x8(%ebp),%eax
8010209a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010209e:	66 83 f8 03          	cmp    $0x3,%ax
801020a2:	75 60                	jne    80102104 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801020a4:	8b 45 08             	mov    0x8(%ebp),%eax
801020a7:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020ab:	66 85 c0             	test   %ax,%ax
801020ae:	78 20                	js     801020d0 <writei+0x3f>
801020b0:	8b 45 08             	mov    0x8(%ebp),%eax
801020b3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020b7:	66 83 f8 09          	cmp    $0x9,%ax
801020bb:	7f 13                	jg     801020d0 <writei+0x3f>
801020bd:	8b 45 08             	mov    0x8(%ebp),%eax
801020c0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020c4:	98                   	cwtl   
801020c5:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
801020cc:	85 c0                	test   %eax,%eax
801020ce:	75 0a                	jne    801020da <writei+0x49>
      return -1;
801020d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020d5:	e9 44 01 00 00       	jmp    8010221e <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
801020da:	8b 45 08             	mov    0x8(%ebp),%eax
801020dd:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801020e1:	98                   	cwtl   
801020e2:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
801020e9:	8b 55 14             	mov    0x14(%ebp),%edx
801020ec:	89 54 24 08          	mov    %edx,0x8(%esp)
801020f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801020f3:	89 54 24 04          	mov    %edx,0x4(%esp)
801020f7:	8b 55 08             	mov    0x8(%ebp),%edx
801020fa:	89 14 24             	mov    %edx,(%esp)
801020fd:	ff d0                	call   *%eax
801020ff:	e9 1a 01 00 00       	jmp    8010221e <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
80102104:	8b 45 08             	mov    0x8(%ebp),%eax
80102107:	8b 40 18             	mov    0x18(%eax),%eax
8010210a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010210d:	72 0d                	jb     8010211c <writei+0x8b>
8010210f:	8b 45 14             	mov    0x14(%ebp),%eax
80102112:	8b 55 10             	mov    0x10(%ebp),%edx
80102115:	01 d0                	add    %edx,%eax
80102117:	3b 45 10             	cmp    0x10(%ebp),%eax
8010211a:	73 0a                	jae    80102126 <writei+0x95>
    return -1;
8010211c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102121:	e9 f8 00 00 00       	jmp    8010221e <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80102126:	8b 45 14             	mov    0x14(%ebp),%eax
80102129:	8b 55 10             	mov    0x10(%ebp),%edx
8010212c:	01 d0                	add    %edx,%eax
8010212e:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102133:	76 0a                	jbe    8010213f <writei+0xae>
    return -1;
80102135:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010213a:	e9 df 00 00 00       	jmp    8010221e <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010213f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102146:	e9 9f 00 00 00       	jmp    801021ea <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010214b:	8b 45 10             	mov    0x10(%ebp),%eax
8010214e:	c1 e8 09             	shr    $0x9,%eax
80102151:	89 44 24 04          	mov    %eax,0x4(%esp)
80102155:	8b 45 08             	mov    0x8(%ebp),%eax
80102158:	89 04 24             	mov    %eax,(%esp)
8010215b:	e8 62 fb ff ff       	call   80101cc2 <bmap>
80102160:	8b 55 08             	mov    0x8(%ebp),%edx
80102163:	8b 12                	mov    (%edx),%edx
80102165:	89 44 24 04          	mov    %eax,0x4(%esp)
80102169:	89 14 24             	mov    %edx,(%esp)
8010216c:	e8 35 e0 ff ff       	call   801001a6 <bread>
80102171:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102174:	8b 45 10             	mov    0x10(%ebp),%eax
80102177:	25 ff 01 00 00       	and    $0x1ff,%eax
8010217c:	89 c2                	mov    %eax,%edx
8010217e:	b8 00 02 00 00       	mov    $0x200,%eax
80102183:	29 d0                	sub    %edx,%eax
80102185:	89 c2                	mov    %eax,%edx
80102187:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010218a:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010218d:	29 c1                	sub    %eax,%ecx
8010218f:	89 c8                	mov    %ecx,%eax
80102191:	39 c2                	cmp    %eax,%edx
80102193:	0f 46 c2             	cmovbe %edx,%eax
80102196:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102199:	8b 45 10             	mov    0x10(%ebp),%eax
8010219c:	25 ff 01 00 00       	and    $0x1ff,%eax
801021a1:	8d 50 10             	lea    0x10(%eax),%edx
801021a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021a7:	01 d0                	add    %edx,%eax
801021a9:	8d 50 08             	lea    0x8(%eax),%edx
801021ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021af:	89 44 24 08          	mov    %eax,0x8(%esp)
801021b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801021b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ba:	89 14 24             	mov    %edx,(%esp)
801021bd:	e8 41 39 00 00       	call   80105b03 <memmove>
    log_write(bp);
801021c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c5:	89 04 24             	mov    %eax,(%esp)
801021c8:	e8 d8 1b 00 00       	call   80103da5 <log_write>
    brelse(bp);
801021cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021d0:	89 04 24             	mov    %eax,(%esp)
801021d3:	e8 3f e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801021d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021db:	01 45 f4             	add    %eax,-0xc(%ebp)
801021de:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021e1:	01 45 10             	add    %eax,0x10(%ebp)
801021e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021e7:	01 45 0c             	add    %eax,0xc(%ebp)
801021ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021ed:	3b 45 14             	cmp    0x14(%ebp),%eax
801021f0:	0f 82 55 ff ff ff    	jb     8010214b <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801021f6:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021fa:	74 1f                	je     8010221b <writei+0x18a>
801021fc:	8b 45 08             	mov    0x8(%ebp),%eax
801021ff:	8b 40 18             	mov    0x18(%eax),%eax
80102202:	3b 45 10             	cmp    0x10(%ebp),%eax
80102205:	73 14                	jae    8010221b <writei+0x18a>
    ip->size = off;
80102207:	8b 45 08             	mov    0x8(%ebp),%eax
8010220a:	8b 55 10             	mov    0x10(%ebp),%edx
8010220d:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102210:	8b 45 08             	mov    0x8(%ebp),%eax
80102213:	89 04 24             	mov    %eax,(%esp)
80102216:	e8 3d f6 ff ff       	call   80101858 <iupdate>
  }
  return n;
8010221b:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010221e:	c9                   	leave  
8010221f:	c3                   	ret    

80102220 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102220:	55                   	push   %ebp
80102221:	89 e5                	mov    %esp,%ebp
80102223:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102226:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010222d:	00 
8010222e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102231:	89 44 24 04          	mov    %eax,0x4(%esp)
80102235:	8b 45 08             	mov    0x8(%ebp),%eax
80102238:	89 04 24             	mov    %eax,(%esp)
8010223b:	e8 66 39 00 00       	call   80105ba6 <strncmp>
}
80102240:	c9                   	leave  
80102241:	c3                   	ret    

80102242 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102242:	55                   	push   %ebp
80102243:	89 e5                	mov    %esp,%ebp
80102245:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102248:	8b 45 08             	mov    0x8(%ebp),%eax
8010224b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010224f:	66 83 f8 01          	cmp    $0x1,%ax
80102253:	74 0c                	je     80102261 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102255:	c7 04 24 53 9c 10 80 	movl   $0x80109c53,(%esp)
8010225c:	e8 d9 e2 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102261:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102268:	e9 88 00 00 00       	jmp    801022f5 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010226d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102274:	00 
80102275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102278:	89 44 24 08          	mov    %eax,0x8(%esp)
8010227c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010227f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102283:	8b 45 08             	mov    0x8(%ebp),%eax
80102286:	89 04 24             	mov    %eax,(%esp)
80102289:	e8 9f fc ff ff       	call   80101f2d <readi>
8010228e:	83 f8 10             	cmp    $0x10,%eax
80102291:	74 0c                	je     8010229f <dirlookup+0x5d>
      panic("dirlink read");
80102293:	c7 04 24 65 9c 10 80 	movl   $0x80109c65,(%esp)
8010229a:	e8 9b e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010229f:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022a3:	66 85 c0             	test   %ax,%ax
801022a6:	75 02                	jne    801022aa <dirlookup+0x68>
      continue;
801022a8:	eb 47                	jmp    801022f1 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
801022aa:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022ad:	83 c0 02             	add    $0x2,%eax
801022b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801022b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022b7:	89 04 24             	mov    %eax,(%esp)
801022ba:	e8 61 ff ff ff       	call   80102220 <namecmp>
801022bf:	85 c0                	test   %eax,%eax
801022c1:	75 2e                	jne    801022f1 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801022c3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801022c7:	74 08                	je     801022d1 <dirlookup+0x8f>
        *poff = off;
801022c9:	8b 45 10             	mov    0x10(%ebp),%eax
801022cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022cf:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801022d1:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801022d5:	0f b7 c0             	movzwl %ax,%eax
801022d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801022db:	8b 45 08             	mov    0x8(%ebp),%eax
801022de:	8b 00                	mov    (%eax),%eax
801022e0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801022e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801022e7:	89 04 24             	mov    %eax,(%esp)
801022ea:	e8 27 f6 ff ff       	call   80101916 <iget>
801022ef:	eb 18                	jmp    80102309 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801022f1:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022f5:	8b 45 08             	mov    0x8(%ebp),%eax
801022f8:	8b 40 18             	mov    0x18(%eax),%eax
801022fb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022fe:	0f 87 69 ff ff ff    	ja     8010226d <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102304:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102309:	c9                   	leave  
8010230a:	c3                   	ret    

8010230b <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
8010230b:	55                   	push   %ebp
8010230c:	89 e5                	mov    %esp,%ebp
8010230e:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102311:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102318:	00 
80102319:	8b 45 0c             	mov    0xc(%ebp),%eax
8010231c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102320:	8b 45 08             	mov    0x8(%ebp),%eax
80102323:	89 04 24             	mov    %eax,(%esp)
80102326:	e8 17 ff ff ff       	call   80102242 <dirlookup>
8010232b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010232e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102332:	74 15                	je     80102349 <dirlink+0x3e>
    iput(ip);
80102334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102337:	89 04 24             	mov    %eax,(%esp)
8010233a:	e8 94 f8 ff ff       	call   80101bd3 <iput>
    return -1;
8010233f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102344:	e9 b7 00 00 00       	jmp    80102400 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102349:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102350:	eb 46                	jmp    80102398 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102355:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010235c:	00 
8010235d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102361:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102364:	89 44 24 04          	mov    %eax,0x4(%esp)
80102368:	8b 45 08             	mov    0x8(%ebp),%eax
8010236b:	89 04 24             	mov    %eax,(%esp)
8010236e:	e8 ba fb ff ff       	call   80101f2d <readi>
80102373:	83 f8 10             	cmp    $0x10,%eax
80102376:	74 0c                	je     80102384 <dirlink+0x79>
      panic("dirlink read");
80102378:	c7 04 24 65 9c 10 80 	movl   $0x80109c65,(%esp)
8010237f:	e8 b6 e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102384:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102388:	66 85 c0             	test   %ax,%ax
8010238b:	75 02                	jne    8010238f <dirlink+0x84>
      break;
8010238d:	eb 16                	jmp    801023a5 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010238f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102392:	83 c0 10             	add    $0x10,%eax
80102395:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102398:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010239b:	8b 45 08             	mov    0x8(%ebp),%eax
8010239e:	8b 40 18             	mov    0x18(%eax),%eax
801023a1:	39 c2                	cmp    %eax,%edx
801023a3:	72 ad                	jb     80102352 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801023a5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801023ac:	00 
801023ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801023b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801023b4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023b7:	83 c0 02             	add    $0x2,%eax
801023ba:	89 04 24             	mov    %eax,(%esp)
801023bd:	e8 3a 38 00 00       	call   80105bfc <strncpy>
  de.inum = inum;
801023c2:	8b 45 10             	mov    0x10(%ebp),%eax
801023c5:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023cc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023d3:	00 
801023d4:	89 44 24 08          	mov    %eax,0x8(%esp)
801023d8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023db:	89 44 24 04          	mov    %eax,0x4(%esp)
801023df:	8b 45 08             	mov    0x8(%ebp),%eax
801023e2:	89 04 24             	mov    %eax,(%esp)
801023e5:	e8 a7 fc ff ff       	call   80102091 <writei>
801023ea:	83 f8 10             	cmp    $0x10,%eax
801023ed:	74 0c                	je     801023fb <dirlink+0xf0>
    panic("dirlink");
801023ef:	c7 04 24 72 9c 10 80 	movl   $0x80109c72,(%esp)
801023f6:	e8 3f e1 ff ff       	call   8010053a <panic>
  
  return 0;
801023fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102400:	c9                   	leave  
80102401:	c3                   	ret    

80102402 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102402:	55                   	push   %ebp
80102403:	89 e5                	mov    %esp,%ebp
80102405:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102408:	eb 04                	jmp    8010240e <skipelem+0xc>
    path++;
8010240a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010240e:	8b 45 08             	mov    0x8(%ebp),%eax
80102411:	0f b6 00             	movzbl (%eax),%eax
80102414:	3c 2f                	cmp    $0x2f,%al
80102416:	74 f2                	je     8010240a <skipelem+0x8>
    path++;
  if(*path == 0)
80102418:	8b 45 08             	mov    0x8(%ebp),%eax
8010241b:	0f b6 00             	movzbl (%eax),%eax
8010241e:	84 c0                	test   %al,%al
80102420:	75 0a                	jne    8010242c <skipelem+0x2a>
    return 0;
80102422:	b8 00 00 00 00       	mov    $0x0,%eax
80102427:	e9 86 00 00 00       	jmp    801024b2 <skipelem+0xb0>
  s = path;
8010242c:	8b 45 08             	mov    0x8(%ebp),%eax
8010242f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102432:	eb 04                	jmp    80102438 <skipelem+0x36>
    path++;
80102434:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102438:	8b 45 08             	mov    0x8(%ebp),%eax
8010243b:	0f b6 00             	movzbl (%eax),%eax
8010243e:	3c 2f                	cmp    $0x2f,%al
80102440:	74 0a                	je     8010244c <skipelem+0x4a>
80102442:	8b 45 08             	mov    0x8(%ebp),%eax
80102445:	0f b6 00             	movzbl (%eax),%eax
80102448:	84 c0                	test   %al,%al
8010244a:	75 e8                	jne    80102434 <skipelem+0x32>
    path++;
  len = path - s;
8010244c:	8b 55 08             	mov    0x8(%ebp),%edx
8010244f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102452:	29 c2                	sub    %eax,%edx
80102454:	89 d0                	mov    %edx,%eax
80102456:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102459:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010245d:	7e 1c                	jle    8010247b <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010245f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102466:	00 
80102467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010246a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010246e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102471:	89 04 24             	mov    %eax,(%esp)
80102474:	e8 8a 36 00 00       	call   80105b03 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102479:	eb 2a                	jmp    801024a5 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010247b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010247e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102485:	89 44 24 04          	mov    %eax,0x4(%esp)
80102489:	8b 45 0c             	mov    0xc(%ebp),%eax
8010248c:	89 04 24             	mov    %eax,(%esp)
8010248f:	e8 6f 36 00 00       	call   80105b03 <memmove>
    name[len] = 0;
80102494:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102497:	8b 45 0c             	mov    0xc(%ebp),%eax
8010249a:	01 d0                	add    %edx,%eax
8010249c:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010249f:	eb 04                	jmp    801024a5 <skipelem+0xa3>
    path++;
801024a1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801024a5:	8b 45 08             	mov    0x8(%ebp),%eax
801024a8:	0f b6 00             	movzbl (%eax),%eax
801024ab:	3c 2f                	cmp    $0x2f,%al
801024ad:	74 f2                	je     801024a1 <skipelem+0x9f>
    path++;
  return path;
801024af:	8b 45 08             	mov    0x8(%ebp),%eax
}
801024b2:	c9                   	leave  
801024b3:	c3                   	ret    

801024b4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801024b4:	55                   	push   %ebp
801024b5:	89 e5                	mov    %esp,%ebp
801024b7:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801024ba:	8b 45 08             	mov    0x8(%ebp),%eax
801024bd:	0f b6 00             	movzbl (%eax),%eax
801024c0:	3c 2f                	cmp    $0x2f,%al
801024c2:	75 1c                	jne    801024e0 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801024c4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024cb:	00 
801024cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024d3:	e8 3e f4 ff ff       	call   80101916 <iget>
801024d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024db:	e9 af 00 00 00       	jmp    8010258f <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024e6:	8b 40 68             	mov    0x68(%eax),%eax
801024e9:	89 04 24             	mov    %eax,(%esp)
801024ec:	e8 f7 f4 ff ff       	call   801019e8 <idup>
801024f1:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801024f4:	e9 96 00 00 00       	jmp    8010258f <namex+0xdb>
    ilock(ip);
801024f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024fc:	89 04 24             	mov    %eax,(%esp)
801024ff:	e8 16 f5 ff ff       	call   80101a1a <ilock>
    if(ip->type != T_DIR){
80102504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102507:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010250b:	66 83 f8 01          	cmp    $0x1,%ax
8010250f:	74 15                	je     80102526 <namex+0x72>
      iunlockput(ip);
80102511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102514:	89 04 24             	mov    %eax,(%esp)
80102517:	e8 88 f7 ff ff       	call   80101ca4 <iunlockput>
      return 0;
8010251c:	b8 00 00 00 00       	mov    $0x0,%eax
80102521:	e9 a3 00 00 00       	jmp    801025c9 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102526:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010252a:	74 1d                	je     80102549 <namex+0x95>
8010252c:	8b 45 08             	mov    0x8(%ebp),%eax
8010252f:	0f b6 00             	movzbl (%eax),%eax
80102532:	84 c0                	test   %al,%al
80102534:	75 13                	jne    80102549 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102536:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102539:	89 04 24             	mov    %eax,(%esp)
8010253c:	e8 2d f6 ff ff       	call   80101b6e <iunlock>
      return ip;
80102541:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102544:	e9 80 00 00 00       	jmp    801025c9 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102549:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102550:	00 
80102551:	8b 45 10             	mov    0x10(%ebp),%eax
80102554:	89 44 24 04          	mov    %eax,0x4(%esp)
80102558:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010255b:	89 04 24             	mov    %eax,(%esp)
8010255e:	e8 df fc ff ff       	call   80102242 <dirlookup>
80102563:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102566:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010256a:	75 12                	jne    8010257e <namex+0xca>
      iunlockput(ip);
8010256c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010256f:	89 04 24             	mov    %eax,(%esp)
80102572:	e8 2d f7 ff ff       	call   80101ca4 <iunlockput>
      return 0;
80102577:	b8 00 00 00 00       	mov    $0x0,%eax
8010257c:	eb 4b                	jmp    801025c9 <namex+0x115>
    }
    iunlockput(ip);
8010257e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102581:	89 04 24             	mov    %eax,(%esp)
80102584:	e8 1b f7 ff ff       	call   80101ca4 <iunlockput>
    ip = next;
80102589:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010258c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010258f:	8b 45 10             	mov    0x10(%ebp),%eax
80102592:	89 44 24 04          	mov    %eax,0x4(%esp)
80102596:	8b 45 08             	mov    0x8(%ebp),%eax
80102599:	89 04 24             	mov    %eax,(%esp)
8010259c:	e8 61 fe ff ff       	call   80102402 <skipelem>
801025a1:	89 45 08             	mov    %eax,0x8(%ebp)
801025a4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025a8:	0f 85 4b ff ff ff    	jne    801024f9 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801025ae:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025b2:	74 12                	je     801025c6 <namex+0x112>
    iput(ip);
801025b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b7:	89 04 24             	mov    %eax,(%esp)
801025ba:	e8 14 f6 ff ff       	call   80101bd3 <iput>
    return 0;
801025bf:	b8 00 00 00 00       	mov    $0x0,%eax
801025c4:	eb 03                	jmp    801025c9 <namex+0x115>
  }
  return ip;
801025c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801025c9:	c9                   	leave  
801025ca:	c3                   	ret    

801025cb <namei>:

struct inode*
namei(char *path)
{
801025cb:	55                   	push   %ebp
801025cc:	89 e5                	mov    %esp,%ebp
801025ce:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801025d1:	8d 45 ea             	lea    -0x16(%ebp),%eax
801025d4:	89 44 24 08          	mov    %eax,0x8(%esp)
801025d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025df:	00 
801025e0:	8b 45 08             	mov    0x8(%ebp),%eax
801025e3:	89 04 24             	mov    %eax,(%esp)
801025e6:	e8 c9 fe ff ff       	call   801024b4 <namex>
}
801025eb:	c9                   	leave  
801025ec:	c3                   	ret    

801025ed <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801025ed:	55                   	push   %ebp
801025ee:	89 e5                	mov    %esp,%ebp
801025f0:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801025f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801025f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801025fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102601:	00 
80102602:	8b 45 08             	mov    0x8(%ebp),%eax
80102605:	89 04 24             	mov    %eax,(%esp)
80102608:	e8 a7 fe ff ff       	call   801024b4 <namex>
}
8010260d:	c9                   	leave  
8010260e:	c3                   	ret    

8010260f <itoa>:

#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
8010260f:	55                   	push   %ebp
80102610:	89 e5                	mov    %esp,%ebp
80102612:	83 ec 20             	sub    $0x20,%esp
    char const digit[] = "0123456789";
80102615:	c7 45 ed 30 31 32 33 	movl   $0x33323130,-0x13(%ebp)
8010261c:	c7 45 f1 34 35 36 37 	movl   $0x37363534,-0xf(%ebp)
80102623:	66 c7 45 f5 38 39    	movw   $0x3938,-0xb(%ebp)
80102629:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
    char* p = b;
8010262d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102630:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if(i<0){
80102633:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102637:	79 0f                	jns    80102648 <itoa+0x39>
        *p++ = '-';
80102639:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010263c:	8d 50 01             	lea    0x1(%eax),%edx
8010263f:	89 55 fc             	mov    %edx,-0x4(%ebp)
80102642:	c6 00 2d             	movb   $0x2d,(%eax)
        i *= -1;
80102645:	f7 5d 08             	negl   0x8(%ebp)
    }
    int shifter = i;
80102648:	8b 45 08             	mov    0x8(%ebp),%eax
8010264b:	89 45 f8             	mov    %eax,-0x8(%ebp)
    do{ //Move to where representation ends
        ++p;
8010264e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
        shifter = shifter/10;
80102652:	8b 4d f8             	mov    -0x8(%ebp),%ecx
80102655:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010265a:	89 c8                	mov    %ecx,%eax
8010265c:	f7 ea                	imul   %edx
8010265e:	c1 fa 02             	sar    $0x2,%edx
80102661:	89 c8                	mov    %ecx,%eax
80102663:	c1 f8 1f             	sar    $0x1f,%eax
80102666:	29 c2                	sub    %eax,%edx
80102668:	89 d0                	mov    %edx,%eax
8010266a:	89 45 f8             	mov    %eax,-0x8(%ebp)
    }while(shifter);
8010266d:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
80102671:	75 db                	jne    8010264e <itoa+0x3f>
    *p = '\0';
80102673:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102676:	c6 00 00             	movb   $0x0,(%eax)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
80102679:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010267d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102680:	ba 67 66 66 66       	mov    $0x66666667,%edx
80102685:	89 c8                	mov    %ecx,%eax
80102687:	f7 ea                	imul   %edx
80102689:	c1 fa 02             	sar    $0x2,%edx
8010268c:	89 c8                	mov    %ecx,%eax
8010268e:	c1 f8 1f             	sar    $0x1f,%eax
80102691:	29 c2                	sub    %eax,%edx
80102693:	89 d0                	mov    %edx,%eax
80102695:	c1 e0 02             	shl    $0x2,%eax
80102698:	01 d0                	add    %edx,%eax
8010269a:	01 c0                	add    %eax,%eax
8010269c:	29 c1                	sub    %eax,%ecx
8010269e:	89 ca                	mov    %ecx,%edx
801026a0:	0f b6 54 15 ed       	movzbl -0x13(%ebp,%edx,1),%edx
801026a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026a8:	88 10                	mov    %dl,(%eax)
        i = i/10;
801026aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
801026ad:	ba 67 66 66 66       	mov    $0x66666667,%edx
801026b2:	89 c8                	mov    %ecx,%eax
801026b4:	f7 ea                	imul   %edx
801026b6:	c1 fa 02             	sar    $0x2,%edx
801026b9:	89 c8                	mov    %ecx,%eax
801026bb:	c1 f8 1f             	sar    $0x1f,%eax
801026be:	29 c2                	sub    %eax,%edx
801026c0:	89 d0                	mov    %edx,%eax
801026c2:	89 45 08             	mov    %eax,0x8(%ebp)
    }while(i);
801026c5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026c9:	75 ae                	jne    80102679 <itoa+0x6a>
    return b;
801026cb:	8b 45 0c             	mov    0xc(%ebp),%eax
}
801026ce:	c9                   	leave  
801026cf:	c3                   	ret    

801026d0 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
801026d0:	55                   	push   %ebp
801026d1:	89 e5                	mov    %esp,%ebp
801026d3:	83 ec 58             	sub    $0x58,%esp
	//path of proccess
	char path[DIGITS];
	memmove(path,"/.swap", 6);
801026d6:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
801026dd:	00 
801026de:	c7 44 24 04 7a 9c 10 	movl   $0x80109c7a,0x4(%esp)
801026e5:	80 
801026e6:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801026e9:	89 04 24             	mov    %eax,(%esp)
801026ec:	e8 12 34 00 00       	call   80105b03 <memmove>
	itoa(p->pid, path+ 6);
801026f1:	8b 45 08             	mov    0x8(%ebp),%eax
801026f4:	8b 40 10             	mov    0x10(%eax),%eax
801026f7:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801026fa:	83 c2 06             	add    $0x6,%edx
801026fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80102701:	89 04 24             	mov    %eax,(%esp)
80102704:	e8 06 ff ff ff       	call   8010260f <itoa>

	struct inode *ip, *dp;
	struct dirent de;
	char name[DIRSIZ];
	uint off;
  if(0 == p->swapFile){
80102709:	8b 45 08             	mov    0x8(%ebp),%eax
8010270c:	8b 40 7c             	mov    0x7c(%eax),%eax
8010270f:	85 c0                	test   %eax,%eax
80102711:	75 0a                	jne    8010271d <removeSwapFile+0x4d>
    return -1;
80102713:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102718:	e9 bd 01 00 00       	jmp    801028da <removeSwapFile+0x20a>
  }
  fileclose(p->swapFile);
8010271d:	8b 45 08             	mov    0x8(%ebp),%eax
80102720:	8b 40 7c             	mov    0x7c(%eax),%eax
80102723:	89 04 24             	mov    %eax,(%esp)
80102726:	e8 04 ea ff ff       	call   8010112f <fileclose>

	begin_op();
8010272b:	e8 6a 14 00 00       	call   80103b9a <begin_op>
	if((dp = nameiparent(path, name)) == 0)
80102730:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102733:	89 44 24 04          	mov    %eax,0x4(%esp)
80102737:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010273a:	89 04 24             	mov    %eax,(%esp)
8010273d:	e8 ab fe ff ff       	call   801025ed <nameiparent>
80102742:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102745:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102749:	75 0f                	jne    8010275a <removeSwapFile+0x8a>
	{
		end_op();
8010274b:	e8 ce 14 00 00       	call   80103c1e <end_op>
		return -1;
80102750:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102755:	e9 80 01 00 00       	jmp    801028da <removeSwapFile+0x20a>
	}

	ilock(dp);
8010275a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010275d:	89 04 24             	mov    %eax,(%esp)
80102760:	e8 b5 f2 ff ff       	call   80101a1a <ilock>

	  // Cannot unlink "." or "..".
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80102765:	c7 44 24 04 81 9c 10 	movl   $0x80109c81,0x4(%esp)
8010276c:	80 
8010276d:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102770:	89 04 24             	mov    %eax,(%esp)
80102773:	e8 a8 fa ff ff       	call   80102220 <namecmp>
80102778:	85 c0                	test   %eax,%eax
8010277a:	0f 84 45 01 00 00    	je     801028c5 <removeSwapFile+0x1f5>
80102780:	c7 44 24 04 83 9c 10 	movl   $0x80109c83,0x4(%esp)
80102787:	80 
80102788:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010278b:	89 04 24             	mov    %eax,(%esp)
8010278e:	e8 8d fa ff ff       	call   80102220 <namecmp>
80102793:	85 c0                	test   %eax,%eax
80102795:	0f 84 2a 01 00 00    	je     801028c5 <removeSwapFile+0x1f5>
	   goto bad;

	if((ip = dirlookup(dp, name, &off)) == 0)
8010279b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010279e:	89 44 24 08          	mov    %eax,0x8(%esp)
801027a2:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801027a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801027a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027ac:	89 04 24             	mov    %eax,(%esp)
801027af:	e8 8e fa ff ff       	call   80102242 <dirlookup>
801027b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801027b7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801027bb:	75 05                	jne    801027c2 <removeSwapFile+0xf2>
		goto bad;
801027bd:	e9 03 01 00 00       	jmp    801028c5 <removeSwapFile+0x1f5>
	ilock(ip);
801027c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027c5:	89 04 24             	mov    %eax,(%esp)
801027c8:	e8 4d f2 ff ff       	call   80101a1a <ilock>

	if(ip->nlink < 1)
801027cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027d0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801027d4:	66 85 c0             	test   %ax,%ax
801027d7:	7f 0c                	jg     801027e5 <removeSwapFile+0x115>
		panic("unlink: nlink < 1");
801027d9:	c7 04 24 86 9c 10 80 	movl   $0x80109c86,(%esp)
801027e0:	e8 55 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
801027e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027e8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027ec:	66 83 f8 01          	cmp    $0x1,%ax
801027f0:	75 1f                	jne    80102811 <removeSwapFile+0x141>
801027f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027f5:	89 04 24             	mov    %eax,(%esp)
801027f8:	e8 11 3b 00 00       	call   8010630e <isdirempty>
801027fd:	85 c0                	test   %eax,%eax
801027ff:	75 10                	jne    80102811 <removeSwapFile+0x141>
		iunlockput(ip);
80102801:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102804:	89 04 24             	mov    %eax,(%esp)
80102807:	e8 98 f4 ff ff       	call   80101ca4 <iunlockput>
		goto bad;
8010280c:	e9 b4 00 00 00       	jmp    801028c5 <removeSwapFile+0x1f5>
	}

	memset(&de, 0, sizeof(de));
80102811:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80102818:	00 
80102819:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102820:	00 
80102821:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80102824:	89 04 24             	mov    %eax,(%esp)
80102827:	e8 08 32 00 00       	call   80105a34 <memset>
	if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010282c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010282f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102836:	00 
80102837:	89 44 24 08          	mov    %eax,0x8(%esp)
8010283b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010283e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102842:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102845:	89 04 24             	mov    %eax,(%esp)
80102848:	e8 44 f8 ff ff       	call   80102091 <writei>
8010284d:	83 f8 10             	cmp    $0x10,%eax
80102850:	74 0c                	je     8010285e <removeSwapFile+0x18e>
		panic("unlink: writei");
80102852:	c7 04 24 98 9c 10 80 	movl   $0x80109c98,(%esp)
80102859:	e8 dc dc ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR){
8010285e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102861:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102865:	66 83 f8 01          	cmp    $0x1,%ax
80102869:	75 1c                	jne    80102887 <removeSwapFile+0x1b7>
		dp->nlink--;
8010286b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010286e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102872:	8d 50 ff             	lea    -0x1(%eax),%edx
80102875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102878:	66 89 50 16          	mov    %dx,0x16(%eax)
		iupdate(dp);
8010287c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010287f:	89 04 24             	mov    %eax,(%esp)
80102882:	e8 d1 ef ff ff       	call   80101858 <iupdate>
	}
	iunlockput(dp);
80102887:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288a:	89 04 24             	mov    %eax,(%esp)
8010288d:	e8 12 f4 ff ff       	call   80101ca4 <iunlockput>

	ip->nlink--;
80102892:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102895:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102899:	8d 50 ff             	lea    -0x1(%eax),%edx
8010289c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010289f:	66 89 50 16          	mov    %dx,0x16(%eax)
	iupdate(ip);
801028a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801028a6:	89 04 24             	mov    %eax,(%esp)
801028a9:	e8 aa ef ff ff       	call   80101858 <iupdate>
	iunlockput(ip);
801028ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801028b1:	89 04 24             	mov    %eax,(%esp)
801028b4:	e8 eb f3 ff ff       	call   80101ca4 <iunlockput>

	end_op();
801028b9:	e8 60 13 00 00       	call   80103c1e <end_op>

	return 0;
801028be:	b8 00 00 00 00       	mov    $0x0,%eax
801028c3:	eb 15                	jmp    801028da <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
801028c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c8:	89 04 24             	mov    %eax,(%esp)
801028cb:	e8 d4 f3 ff ff       	call   80101ca4 <iunlockput>
		end_op();
801028d0:	e8 49 13 00 00       	call   80103c1e <end_op>
		return -1;
801028d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

}
801028da:	c9                   	leave  
801028db:	c3                   	ret    

801028dc <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
801028dc:	55                   	push   %ebp
801028dd:	89 e5                	mov    %esp,%ebp
801028df:	83 ec 38             	sub    $0x38,%esp

	char path[DIGITS];
	memmove(path,"/.swap", 6);
801028e2:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
801028e9:	00 
801028ea:	c7 44 24 04 7a 9c 10 	movl   $0x80109c7a,0x4(%esp)
801028f1:	80 
801028f2:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028f5:	89 04 24             	mov    %eax,(%esp)
801028f8:	e8 06 32 00 00       	call   80105b03 <memmove>
	itoa(p->pid, path+ 6);
801028fd:	8b 45 08             	mov    0x8(%ebp),%eax
80102900:	8b 40 10             	mov    0x10(%eax),%eax
80102903:	8d 55 e6             	lea    -0x1a(%ebp),%edx
80102906:	83 c2 06             	add    $0x6,%edx
80102909:	89 54 24 04          	mov    %edx,0x4(%esp)
8010290d:	89 04 24             	mov    %eax,(%esp)
80102910:	e8 fa fc ff ff       	call   8010260f <itoa>

    begin_op();
80102915:	e8 80 12 00 00       	call   80103b9a <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
8010291a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80102921:	00 
80102922:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102929:	00 
8010292a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80102931:	00 
80102932:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102935:	89 04 24             	mov    %eax,(%esp)
80102938:	e8 17 3c 00 00       	call   80106554 <create>
8010293d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	iunlock(in);
80102940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102943:	89 04 24             	mov    %eax,(%esp)
80102946:	e8 23 f2 ff ff       	call   80101b6e <iunlock>

	p->swapFile = filealloc();
8010294b:	e8 37 e7 ff ff       	call   80101087 <filealloc>
80102950:	8b 55 08             	mov    0x8(%ebp),%edx
80102953:	89 42 7c             	mov    %eax,0x7c(%edx)
	if (p->swapFile == 0)
80102956:	8b 45 08             	mov    0x8(%ebp),%eax
80102959:	8b 40 7c             	mov    0x7c(%eax),%eax
8010295c:	85 c0                	test   %eax,%eax
8010295e:	75 0c                	jne    8010296c <createSwapFile+0x90>
		panic("no slot for files on /store");
80102960:	c7 04 24 a7 9c 10 80 	movl   $0x80109ca7,(%esp)
80102967:	e8 ce db ff ff       	call   8010053a <panic>

	p->swapFile->ip = in;
8010296c:	8b 45 08             	mov    0x8(%ebp),%eax
8010296f:	8b 40 7c             	mov    0x7c(%eax),%eax
80102972:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102975:	89 50 10             	mov    %edx,0x10(%eax)
	p->swapFile->type = FD_INODE;
80102978:	8b 45 08             	mov    0x8(%ebp),%eax
8010297b:	8b 40 7c             	mov    0x7c(%eax),%eax
8010297e:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
	p->swapFile->off = 0;
80102984:	8b 45 08             	mov    0x8(%ebp),%eax
80102987:	8b 40 7c             	mov    0x7c(%eax),%eax
8010298a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
	p->swapFile->readable = O_WRONLY;
80102991:	8b 45 08             	mov    0x8(%ebp),%eax
80102994:	8b 40 7c             	mov    0x7c(%eax),%eax
80102997:	c6 40 08 01          	movb   $0x1,0x8(%eax)
	p->swapFile->writable = O_RDWR;
8010299b:	8b 45 08             	mov    0x8(%ebp),%eax
8010299e:	8b 40 7c             	mov    0x7c(%eax),%eax
801029a1:	c6 40 09 02          	movb   $0x2,0x9(%eax)
    end_op();
801029a5:	e8 74 12 00 00       	call   80103c1e <end_op>

    return 0;
801029aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801029af:	c9                   	leave  
801029b0:	c3                   	ret    

801029b1 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
801029b1:	55                   	push   %ebp
801029b2:	89 e5                	mov    %esp,%ebp
801029b4:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
801029b7:	8b 45 08             	mov    0x8(%ebp),%eax
801029ba:	8b 40 7c             	mov    0x7c(%eax),%eax
801029bd:	8b 55 10             	mov    0x10(%ebp),%edx
801029c0:	89 50 14             	mov    %edx,0x14(%eax)

	return filewrite(p->swapFile, buffer, size);
801029c3:	8b 55 14             	mov    0x14(%ebp),%edx
801029c6:	8b 45 08             	mov    0x8(%ebp),%eax
801029c9:	8b 40 7c             	mov    0x7c(%eax),%eax
801029cc:	89 54 24 08          	mov    %edx,0x8(%esp)
801029d0:	8b 55 0c             	mov    0xc(%ebp),%edx
801029d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801029d7:	89 04 24             	mov    %eax,(%esp)
801029da:	e8 31 e9 ff ff       	call   80101310 <filewrite>

}
801029df:	c9                   	leave  
801029e0:	c3                   	ret    

801029e1 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
801029e1:	55                   	push   %ebp
801029e2:	89 e5                	mov    %esp,%ebp
801029e4:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
801029e7:	8b 45 08             	mov    0x8(%ebp),%eax
801029ea:	8b 40 7c             	mov    0x7c(%eax),%eax
801029ed:	8b 55 10             	mov    0x10(%ebp),%edx
801029f0:	89 50 14             	mov    %edx,0x14(%eax)

	return fileread(p->swapFile, buffer,  size);
801029f3:	8b 55 14             	mov    0x14(%ebp),%edx
801029f6:	8b 45 08             	mov    0x8(%ebp),%eax
801029f9:	8b 40 7c             	mov    0x7c(%eax),%eax
801029fc:	89 54 24 08          	mov    %edx,0x8(%esp)
80102a00:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a03:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a07:	89 04 24             	mov    %eax,(%esp)
80102a0a:	e8 45 e8 ff ff       	call   80101254 <fileread>
}
80102a0f:	c9                   	leave  
80102a10:	c3                   	ret    

80102a11 <copySwapFile>:
    
//     to->copyingSwapFile = 1;
//     kfree(mem);
// }
void
copySwapFile(struct proc *from, struct proc *to){
80102a11:	55                   	push   %ebp
80102a12:	89 e5                	mov    %esp,%ebp
80102a14:	53                   	push   %ebx
80102a15:	81 ec 24 04 00 00    	sub    $0x424,%esp
  char buf[1024];
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 1024){
80102a1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a22:	eb 4f                	jmp    80102a73 <copySwapFile+0x62>
    readFromSwapFile(from,buf,i,1024);
80102a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a27:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
80102a2e:	00 
80102a2f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a33:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
80102a39:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a3d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a40:	89 04 24             	mov    %eax,(%esp)
80102a43:	e8 99 ff ff ff       	call   801029e1 <readFromSwapFile>
    writeToSwapFile(to,buf,i,1024);
80102a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a4b:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
80102a52:	00 
80102a53:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a57:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
80102a5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a61:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a64:	89 04 24             	mov    %eax,(%esp)
80102a67:	e8 45 ff ff ff       	call   801029b1 <writeToSwapFile>
// }
void
copySwapFile(struct proc *from, struct proc *to){
  char buf[1024];
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 1024){
80102a6c:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
80102a73:	81 7d f4 ff df 00 00 	cmpl   $0xdfff,-0xc(%ebp)
80102a7a:	7e a8                	jle    80102a24 <copySwapFile+0x13>
    readFromSwapFile(from,buf,i,1024);
    writeToSwapFile(to,buf,i,1024);
  }
  for(j = 0; j < 30; j++){
80102a7c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102a83:	e9 9d 00 00 00       	jmp    80102b25 <copySwapFile+0x114>
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
80102a88:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a8b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102a8e:	89 d0                	mov    %edx,%eax
80102a90:	c1 e0 02             	shl    $0x2,%eax
80102a93:	01 d0                	add    %edx,%eax
80102a95:	c1 e0 02             	shl    $0x2,%eax
80102a98:	01 c8                	add    %ecx,%eax
80102a9a:	05 98 00 00 00       	add    $0x98,%eax
80102a9f:	8b 00                	mov    (%eax),%eax
80102aa1:	83 f8 ff             	cmp    $0xffffffff,%eax
80102aa4:	74 7b                	je     80102b21 <copySwapFile+0x110>
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102aa6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102aad:	eb 6c                	jmp    80102b1b <copySwapFile+0x10a>
            if(to->pagesMetaData[i].va == from->pagesMetaData[j].va){//thats the one!
80102aaf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102ab2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ab5:	89 d0                	mov    %edx,%eax
80102ab7:	c1 e0 02             	shl    $0x2,%eax
80102aba:	01 d0                	add    %edx,%eax
80102abc:	c1 e0 02             	shl    $0x2,%eax
80102abf:	01 c8                	add    %ecx,%eax
80102ac1:	05 90 00 00 00       	add    $0x90,%eax
80102ac6:	8b 08                	mov    (%eax),%ecx
80102ac8:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102acb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ace:	89 d0                	mov    %edx,%eax
80102ad0:	c1 e0 02             	shl    $0x2,%eax
80102ad3:	01 d0                	add    %edx,%eax
80102ad5:	c1 e0 02             	shl    $0x2,%eax
80102ad8:	01 d8                	add    %ebx,%eax
80102ada:	05 90 00 00 00       	add    $0x90,%eax
80102adf:	8b 00                	mov    (%eax),%eax
80102ae1:	39 c1                	cmp    %eax,%ecx
80102ae3:	75 32                	jne    80102b17 <copySwapFile+0x106>
              to->pagesMetaData[i].fileOffset = from->pagesMetaData[j].fileOffset;
80102ae5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102ae8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102aeb:	89 d0                	mov    %edx,%eax
80102aed:	c1 e0 02             	shl    $0x2,%eax
80102af0:	01 d0                	add    %edx,%eax
80102af2:	c1 e0 02             	shl    $0x2,%eax
80102af5:	01 c8                	add    %ecx,%eax
80102af7:	05 98 00 00 00       	add    $0x98,%eax
80102afc:	8b 08                	mov    (%eax),%ecx
80102afe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80102b01:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b04:	89 d0                	mov    %edx,%eax
80102b06:	c1 e0 02             	shl    $0x2,%eax
80102b09:	01 d0                	add    %edx,%eax
80102b0b:	c1 e0 02             	shl    $0x2,%eax
80102b0e:	01 d8                	add    %ebx,%eax
80102b10:	05 98 00 00 00       	add    $0x98,%eax
80102b15:	89 08                	mov    %ecx,(%eax)
    writeToSwapFile(to,buf,i,1024);
  }
  for(j = 0; j < 30; j++){
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102b17:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b1b:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80102b1f:	7e 8e                	jle    80102aaf <copySwapFile+0x9e>
  int i,j;
  for(i = 0; i < 14*PGSIZE; i+= 1024){
    readFromSwapFile(from,buf,i,1024);
    writeToSwapFile(to,buf,i,1024);
  }
  for(j = 0; j < 30; j++){
80102b21:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b25:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80102b29:	0f 8e 59 ff ff ff    	jle    80102a88 <copySwapFile+0x77>
              to->pagesMetaData[i].fileOffset = from->pagesMetaData[j].fileOffset;
            }
          }
        }
      }
80102b2f:	81 c4 24 04 00 00    	add    $0x424,%esp
80102b35:	5b                   	pop    %ebx
80102b36:	5d                   	pop    %ebp
80102b37:	c3                   	ret    

80102b38 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b38:	55                   	push   %ebp
80102b39:	89 e5                	mov    %esp,%ebp
80102b3b:	83 ec 14             	sub    $0x14,%esp
80102b3e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b41:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b45:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b49:	89 c2                	mov    %eax,%edx
80102b4b:	ec                   	in     (%dx),%al
80102b4c:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b4f:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b53:	c9                   	leave  
80102b54:	c3                   	ret    

80102b55 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102b55:	55                   	push   %ebp
80102b56:	89 e5                	mov    %esp,%ebp
80102b58:	57                   	push   %edi
80102b59:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102b5a:	8b 55 08             	mov    0x8(%ebp),%edx
80102b5d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b60:	8b 45 10             	mov    0x10(%ebp),%eax
80102b63:	89 cb                	mov    %ecx,%ebx
80102b65:	89 df                	mov    %ebx,%edi
80102b67:	89 c1                	mov    %eax,%ecx
80102b69:	fc                   	cld    
80102b6a:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b6c:	89 c8                	mov    %ecx,%eax
80102b6e:	89 fb                	mov    %edi,%ebx
80102b70:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b73:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b76:	5b                   	pop    %ebx
80102b77:	5f                   	pop    %edi
80102b78:	5d                   	pop    %ebp
80102b79:	c3                   	ret    

80102b7a <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b7a:	55                   	push   %ebp
80102b7b:	89 e5                	mov    %esp,%ebp
80102b7d:	83 ec 08             	sub    $0x8,%esp
80102b80:	8b 55 08             	mov    0x8(%ebp),%edx
80102b83:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b86:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102b8a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b8d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b91:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b95:	ee                   	out    %al,(%dx)
}
80102b96:	c9                   	leave  
80102b97:	c3                   	ret    

80102b98 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b98:	55                   	push   %ebp
80102b99:	89 e5                	mov    %esp,%ebp
80102b9b:	56                   	push   %esi
80102b9c:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b9d:	8b 55 08             	mov    0x8(%ebp),%edx
80102ba0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102ba3:	8b 45 10             	mov    0x10(%ebp),%eax
80102ba6:	89 cb                	mov    %ecx,%ebx
80102ba8:	89 de                	mov    %ebx,%esi
80102baa:	89 c1                	mov    %eax,%ecx
80102bac:	fc                   	cld    
80102bad:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102baf:	89 c8                	mov    %ecx,%eax
80102bb1:	89 f3                	mov    %esi,%ebx
80102bb3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102bb6:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102bb9:	5b                   	pop    %ebx
80102bba:	5e                   	pop    %esi
80102bbb:	5d                   	pop    %ebp
80102bbc:	c3                   	ret    

80102bbd <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102bbd:	55                   	push   %ebp
80102bbe:	89 e5                	mov    %esp,%ebp
80102bc0:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102bc3:	90                   	nop
80102bc4:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102bcb:	e8 68 ff ff ff       	call   80102b38 <inb>
80102bd0:	0f b6 c0             	movzbl %al,%eax
80102bd3:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102bd6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bd9:	25 c0 00 00 00       	and    $0xc0,%eax
80102bde:	83 f8 40             	cmp    $0x40,%eax
80102be1:	75 e1                	jne    80102bc4 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102be3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102be7:	74 11                	je     80102bfa <idewait+0x3d>
80102be9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bec:	83 e0 21             	and    $0x21,%eax
80102bef:	85 c0                	test   %eax,%eax
80102bf1:	74 07                	je     80102bfa <idewait+0x3d>
    return -1;
80102bf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102bf8:	eb 05                	jmp    80102bff <idewait+0x42>
  return 0;
80102bfa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bff:	c9                   	leave  
80102c00:	c3                   	ret    

80102c01 <ideinit>:

void
ideinit(void)
{
80102c01:	55                   	push   %ebp
80102c02:	89 e5                	mov    %esp,%ebp
80102c04:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102c07:	c7 44 24 04 c3 9c 10 	movl   $0x80109cc3,0x4(%esp)
80102c0e:	80 
80102c0f:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c16:	e8 a4 2b 00 00       	call   801057bf <initlock>
  picenable(IRQ_IDE);
80102c1b:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c22:	e8 12 19 00 00       	call   80104539 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102c27:	a1 40 49 11 80       	mov    0x80114940,%eax
80102c2c:	83 e8 01             	sub    $0x1,%eax
80102c2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c33:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c3a:	e8 43 04 00 00       	call   80103082 <ioapicenable>
  idewait(0);
80102c3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c46:	e8 72 ff ff ff       	call   80102bbd <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102c4b:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102c52:	00 
80102c53:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c5a:	e8 1b ff ff ff       	call   80102b7a <outb>
  for(i=0; i<1000; i++){
80102c5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c66:	eb 20                	jmp    80102c88 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c68:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c6f:	e8 c4 fe ff ff       	call   80102b38 <inb>
80102c74:	84 c0                	test   %al,%al
80102c76:	74 0c                	je     80102c84 <ideinit+0x83>
      havedisk1 = 1;
80102c78:	c7 05 38 d6 10 80 01 	movl   $0x1,0x8010d638
80102c7f:	00 00 00 
      break;
80102c82:	eb 0d                	jmp    80102c91 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102c84:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c88:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c8f:	7e d7                	jle    80102c68 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c91:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c98:	00 
80102c99:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102ca0:	e8 d5 fe ff ff       	call   80102b7a <outb>
}
80102ca5:	c9                   	leave  
80102ca6:	c3                   	ret    

80102ca7 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102ca7:	55                   	push   %ebp
80102ca8:	89 e5                	mov    %esp,%ebp
80102caa:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102cad:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102cb1:	75 0c                	jne    80102cbf <idestart+0x18>
    panic("idestart");
80102cb3:	c7 04 24 c7 9c 10 80 	movl   $0x80109cc7,(%esp)
80102cba:	e8 7b d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80102cc2:	8b 40 08             	mov    0x8(%eax),%eax
80102cc5:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102cca:	76 0c                	jbe    80102cd8 <idestart+0x31>
    panic("incorrect blockno");
80102ccc:	c7 04 24 d0 9c 10 80 	movl   $0x80109cd0,(%esp)
80102cd3:	e8 62 d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102cd8:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102cdf:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce2:	8b 50 08             	mov    0x8(%eax),%edx
80102ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce8:	0f af c2             	imul   %edx,%eax
80102ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102cee:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102cf2:	7e 0c                	jle    80102d00 <idestart+0x59>
80102cf4:	c7 04 24 c7 9c 10 80 	movl   $0x80109cc7,(%esp)
80102cfb:	e8 3a d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102d00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102d07:	e8 b1 fe ff ff       	call   80102bbd <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102d0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102d13:	00 
80102d14:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102d1b:	e8 5a fe ff ff       	call   80102b7a <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102d20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d23:	0f b6 c0             	movzbl %al,%eax
80102d26:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d2a:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102d31:	e8 44 fe ff ff       	call   80102b7a <outb>
  outb(0x1f3, sector & 0xff);
80102d36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d39:	0f b6 c0             	movzbl %al,%eax
80102d3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d40:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102d47:	e8 2e fe ff ff       	call   80102b7a <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d4f:	c1 f8 08             	sar    $0x8,%eax
80102d52:	0f b6 c0             	movzbl %al,%eax
80102d55:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d59:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102d60:	e8 15 fe ff ff       	call   80102b7a <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102d65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d68:	c1 f8 10             	sar    $0x10,%eax
80102d6b:	0f b6 c0             	movzbl %al,%eax
80102d6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d72:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102d79:	e8 fc fd ff ff       	call   80102b7a <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102d7e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d81:	8b 40 04             	mov    0x4(%eax),%eax
80102d84:	83 e0 01             	and    $0x1,%eax
80102d87:	c1 e0 04             	shl    $0x4,%eax
80102d8a:	89 c2                	mov    %eax,%edx
80102d8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d8f:	c1 f8 18             	sar    $0x18,%eax
80102d92:	83 e0 0f             	and    $0xf,%eax
80102d95:	09 d0                	or     %edx,%eax
80102d97:	83 c8 e0             	or     $0xffffffe0,%eax
80102d9a:	0f b6 c0             	movzbl %al,%eax
80102d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102da1:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102da8:	e8 cd fd ff ff       	call   80102b7a <outb>
  if(b->flags & B_DIRTY){
80102dad:	8b 45 08             	mov    0x8(%ebp),%eax
80102db0:	8b 00                	mov    (%eax),%eax
80102db2:	83 e0 04             	and    $0x4,%eax
80102db5:	85 c0                	test   %eax,%eax
80102db7:	74 34                	je     80102ded <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102db9:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102dc0:	00 
80102dc1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102dc8:	e8 ad fd ff ff       	call   80102b7a <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102dcd:	8b 45 08             	mov    0x8(%ebp),%eax
80102dd0:	83 c0 18             	add    $0x18,%eax
80102dd3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102dda:	00 
80102ddb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ddf:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102de6:	e8 ad fd ff ff       	call   80102b98 <outsl>
80102deb:	eb 14                	jmp    80102e01 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102ded:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102df4:	00 
80102df5:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102dfc:	e8 79 fd ff ff       	call   80102b7a <outb>
  }
}
80102e01:	c9                   	leave  
80102e02:	c3                   	ret    

80102e03 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102e03:	55                   	push   %ebp
80102e04:	89 e5                	mov    %esp,%ebp
80102e06:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102e09:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e10:	e8 cb 29 00 00       	call   801057e0 <acquire>
  if((b = idequeue) == 0){
80102e15:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e1d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e21:	75 11                	jne    80102e34 <ideintr+0x31>
    release(&idelock);
80102e23:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e2a:	e8 13 2a 00 00       	call   80105842 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102e2f:	e9 90 00 00 00       	jmp    80102ec4 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102e34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e37:	8b 40 14             	mov    0x14(%eax),%eax
80102e3a:	a3 34 d6 10 80       	mov    %eax,0x8010d634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e42:	8b 00                	mov    (%eax),%eax
80102e44:	83 e0 04             	and    $0x4,%eax
80102e47:	85 c0                	test   %eax,%eax
80102e49:	75 2e                	jne    80102e79 <ideintr+0x76>
80102e4b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e52:	e8 66 fd ff ff       	call   80102bbd <idewait>
80102e57:	85 c0                	test   %eax,%eax
80102e59:	78 1e                	js     80102e79 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e5e:	83 c0 18             	add    $0x18,%eax
80102e61:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e68:	00 
80102e69:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e6d:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e74:	e8 dc fc ff ff       	call   80102b55 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102e79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e7c:	8b 00                	mov    (%eax),%eax
80102e7e:	83 c8 02             	or     $0x2,%eax
80102e81:	89 c2                	mov    %eax,%edx
80102e83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e86:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102e88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e8b:	8b 00                	mov    (%eax),%eax
80102e8d:	83 e0 fb             	and    $0xfffffffb,%eax
80102e90:	89 c2                	mov    %eax,%edx
80102e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e95:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102e97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e9a:	89 04 24             	mov    %eax,(%esp)
80102e9d:	e8 d2 26 00 00       	call   80105574 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102ea2:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ea7:	85 c0                	test   %eax,%eax
80102ea9:	74 0d                	je     80102eb8 <ideintr+0xb5>
    idestart(idequeue);
80102eab:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102eb0:	89 04 24             	mov    %eax,(%esp)
80102eb3:	e8 ef fd ff ff       	call   80102ca7 <idestart>

  release(&idelock);
80102eb8:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102ebf:	e8 7e 29 00 00       	call   80105842 <release>
}
80102ec4:	c9                   	leave  
80102ec5:	c3                   	ret    

80102ec6 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102ec6:	55                   	push   %ebp
80102ec7:	89 e5                	mov    %esp,%ebp
80102ec9:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102ecc:	8b 45 08             	mov    0x8(%ebp),%eax
80102ecf:	8b 00                	mov    (%eax),%eax
80102ed1:	83 e0 01             	and    $0x1,%eax
80102ed4:	85 c0                	test   %eax,%eax
80102ed6:	75 0c                	jne    80102ee4 <iderw+0x1e>
    panic("iderw: buf not busy");
80102ed8:	c7 04 24 e2 9c 10 80 	movl   $0x80109ce2,(%esp)
80102edf:	e8 56 d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102ee4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ee7:	8b 00                	mov    (%eax),%eax
80102ee9:	83 e0 06             	and    $0x6,%eax
80102eec:	83 f8 02             	cmp    $0x2,%eax
80102eef:	75 0c                	jne    80102efd <iderw+0x37>
    panic("iderw: nothing to do");
80102ef1:	c7 04 24 f6 9c 10 80 	movl   $0x80109cf6,(%esp)
80102ef8:	e8 3d d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102efd:	8b 45 08             	mov    0x8(%ebp),%eax
80102f00:	8b 40 04             	mov    0x4(%eax),%eax
80102f03:	85 c0                	test   %eax,%eax
80102f05:	74 15                	je     80102f1c <iderw+0x56>
80102f07:	a1 38 d6 10 80       	mov    0x8010d638,%eax
80102f0c:	85 c0                	test   %eax,%eax
80102f0e:	75 0c                	jne    80102f1c <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102f10:	c7 04 24 0b 9d 10 80 	movl   $0x80109d0b,(%esp)
80102f17:	e8 1e d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f1c:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f23:	e8 b8 28 00 00       	call   801057e0 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102f28:	8b 45 08             	mov    0x8(%ebp),%eax
80102f2b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102f32:	c7 45 f4 34 d6 10 80 	movl   $0x8010d634,-0xc(%ebp)
80102f39:	eb 0b                	jmp    80102f46 <iderw+0x80>
80102f3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f3e:	8b 00                	mov    (%eax),%eax
80102f40:	83 c0 14             	add    $0x14,%eax
80102f43:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102f46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f49:	8b 00                	mov    (%eax),%eax
80102f4b:	85 c0                	test   %eax,%eax
80102f4d:	75 ec                	jne    80102f3b <iderw+0x75>
    ;
  *pp = b;
80102f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f52:	8b 55 08             	mov    0x8(%ebp),%edx
80102f55:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102f57:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f5c:	3b 45 08             	cmp    0x8(%ebp),%eax
80102f5f:	75 0d                	jne    80102f6e <iderw+0xa8>
    idestart(b);
80102f61:	8b 45 08             	mov    0x8(%ebp),%eax
80102f64:	89 04 24             	mov    %eax,(%esp)
80102f67:	e8 3b fd ff ff       	call   80102ca7 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f6c:	eb 15                	jmp    80102f83 <iderw+0xbd>
80102f6e:	eb 13                	jmp    80102f83 <iderw+0xbd>
    sleep(b, &idelock);
80102f70:	c7 44 24 04 00 d6 10 	movl   $0x8010d600,0x4(%esp)
80102f77:	80 
80102f78:	8b 45 08             	mov    0x8(%ebp),%eax
80102f7b:	89 04 24             	mov    %eax,(%esp)
80102f7e:	e8 15 25 00 00       	call   80105498 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f83:	8b 45 08             	mov    0x8(%ebp),%eax
80102f86:	8b 00                	mov    (%eax),%eax
80102f88:	83 e0 06             	and    $0x6,%eax
80102f8b:	83 f8 02             	cmp    $0x2,%eax
80102f8e:	75 e0                	jne    80102f70 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102f90:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f97:	e8 a6 28 00 00       	call   80105842 <release>
}
80102f9c:	c9                   	leave  
80102f9d:	c3                   	ret    

80102f9e <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f9e:	55                   	push   %ebp
80102f9f:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fa1:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fa6:	8b 55 08             	mov    0x8(%ebp),%edx
80102fa9:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102fab:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fb0:	8b 40 10             	mov    0x10(%eax),%eax
}
80102fb3:	5d                   	pop    %ebp
80102fb4:	c3                   	ret    

80102fb5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102fb5:	55                   	push   %ebp
80102fb6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fb8:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fbd:	8b 55 08             	mov    0x8(%ebp),%edx
80102fc0:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102fc2:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fc7:	8b 55 0c             	mov    0xc(%ebp),%edx
80102fca:	89 50 10             	mov    %edx,0x10(%eax)
}
80102fcd:	5d                   	pop    %ebp
80102fce:	c3                   	ret    

80102fcf <ioapicinit>:

void
ioapicinit(void)
{
80102fcf:	55                   	push   %ebp
80102fd0:	89 e5                	mov    %esp,%ebp
80102fd2:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102fd5:	a1 44 43 11 80       	mov    0x80114344,%eax
80102fda:	85 c0                	test   %eax,%eax
80102fdc:	75 05                	jne    80102fe3 <ioapicinit+0x14>
    return;
80102fde:	e9 9d 00 00 00       	jmp    80103080 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102fe3:	c7 05 14 42 11 80 00 	movl   $0xfec00000,0x80114214
80102fea:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102fed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102ff4:	e8 a5 ff ff ff       	call   80102f9e <ioapicread>
80102ff9:	c1 e8 10             	shr    $0x10,%eax
80102ffc:	25 ff 00 00 00       	and    $0xff,%eax
80103001:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103004:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010300b:	e8 8e ff ff ff       	call   80102f9e <ioapicread>
80103010:	c1 e8 18             	shr    $0x18,%eax
80103013:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103016:	0f b6 05 40 43 11 80 	movzbl 0x80114340,%eax
8010301d:	0f b6 c0             	movzbl %al,%eax
80103020:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103023:	74 0c                	je     80103031 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103025:	c7 04 24 2c 9d 10 80 	movl   $0x80109d2c,(%esp)
8010302c:	e8 6f d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103031:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103038:	eb 3e                	jmp    80103078 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010303a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010303d:	83 c0 20             	add    $0x20,%eax
80103040:	0d 00 00 01 00       	or     $0x10000,%eax
80103045:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103048:	83 c2 08             	add    $0x8,%edx
8010304b:	01 d2                	add    %edx,%edx
8010304d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103051:	89 14 24             	mov    %edx,(%esp)
80103054:	e8 5c ff ff ff       	call   80102fb5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103059:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010305c:	83 c0 08             	add    $0x8,%eax
8010305f:	01 c0                	add    %eax,%eax
80103061:	83 c0 01             	add    $0x1,%eax
80103064:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010306b:	00 
8010306c:	89 04 24             	mov    %eax,(%esp)
8010306f:	e8 41 ff ff ff       	call   80102fb5 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103074:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010307b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010307e:	7e ba                	jle    8010303a <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103080:	c9                   	leave  
80103081:	c3                   	ret    

80103082 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103082:	55                   	push   %ebp
80103083:	89 e5                	mov    %esp,%ebp
80103085:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103088:	a1 44 43 11 80       	mov    0x80114344,%eax
8010308d:	85 c0                	test   %eax,%eax
8010308f:	75 02                	jne    80103093 <ioapicenable+0x11>
    return;
80103091:	eb 37                	jmp    801030ca <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103093:	8b 45 08             	mov    0x8(%ebp),%eax
80103096:	83 c0 20             	add    $0x20,%eax
80103099:	8b 55 08             	mov    0x8(%ebp),%edx
8010309c:	83 c2 08             	add    $0x8,%edx
8010309f:	01 d2                	add    %edx,%edx
801030a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801030a5:	89 14 24             	mov    %edx,(%esp)
801030a8:	e8 08 ff ff ff       	call   80102fb5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801030ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801030b0:	c1 e0 18             	shl    $0x18,%eax
801030b3:	8b 55 08             	mov    0x8(%ebp),%edx
801030b6:	83 c2 08             	add    $0x8,%edx
801030b9:	01 d2                	add    %edx,%edx
801030bb:	83 c2 01             	add    $0x1,%edx
801030be:	89 44 24 04          	mov    %eax,0x4(%esp)
801030c2:	89 14 24             	mov    %edx,(%esp)
801030c5:	e8 eb fe ff ff       	call   80102fb5 <ioapicwrite>
}
801030ca:	c9                   	leave  
801030cb:	c3                   	ret    

801030cc <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801030cc:	55                   	push   %ebp
801030cd:	89 e5                	mov    %esp,%ebp
801030cf:	8b 45 08             	mov    0x8(%ebp),%eax
801030d2:	05 00 00 00 80       	add    $0x80000000,%eax
801030d7:	5d                   	pop    %ebp
801030d8:	c3                   	ret    

801030d9 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801030d9:	55                   	push   %ebp
801030da:	89 e5                	mov    %esp,%ebp
801030dc:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801030df:	c7 44 24 04 5e 9d 10 	movl   $0x80109d5e,0x4(%esp)
801030e6:	80 
801030e7:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801030ee:	e8 cc 26 00 00       	call   801057bf <initlock>
  kmem.use_lock = 0;
801030f3:	c7 05 54 42 11 80 00 	movl   $0x0,0x80114254
801030fa:	00 00 00 
  freerange(vstart, vend);
801030fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103100:	89 44 24 04          	mov    %eax,0x4(%esp)
80103104:	8b 45 08             	mov    0x8(%ebp),%eax
80103107:	89 04 24             	mov    %eax,(%esp)
8010310a:	e8 26 00 00 00       	call   80103135 <freerange>
}
8010310f:	c9                   	leave  
80103110:	c3                   	ret    

80103111 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103111:	55                   	push   %ebp
80103112:	89 e5                	mov    %esp,%ebp
80103114:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103117:	8b 45 0c             	mov    0xc(%ebp),%eax
8010311a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010311e:	8b 45 08             	mov    0x8(%ebp),%eax
80103121:	89 04 24             	mov    %eax,(%esp)
80103124:	e8 0c 00 00 00       	call   80103135 <freerange>
  kmem.use_lock = 1;
80103129:	c7 05 54 42 11 80 01 	movl   $0x1,0x80114254
80103130:	00 00 00 
}
80103133:	c9                   	leave  
80103134:	c3                   	ret    

80103135 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103135:	55                   	push   %ebp
80103136:	89 e5                	mov    %esp,%ebp
80103138:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
8010313b:	8b 45 08             	mov    0x8(%ebp),%eax
8010313e:	05 ff 0f 00 00       	add    $0xfff,%eax
80103143:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103148:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010314b:	eb 12                	jmp    8010315f <freerange+0x2a>
    kfree(p);
8010314d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103150:	89 04 24             	mov    %eax,(%esp)
80103153:	e8 16 00 00 00       	call   8010316e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103158:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010315f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103162:	05 00 10 00 00       	add    $0x1000,%eax
80103167:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010316a:	76 e1                	jbe    8010314d <freerange+0x18>
    kfree(p);
}
8010316c:	c9                   	leave  
8010316d:	c3                   	ret    

8010316e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
8010316e:	55                   	push   %ebp
8010316f:	89 e5                	mov    %esp,%ebp
80103171:	83 ec 28             	sub    $0x28,%esp
  // if(getPid()){
  //   cprintf("%x\n",v);
  // }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
80103174:	8b 45 08             	mov    0x8(%ebp),%eax
80103177:	25 ff 0f 00 00       	and    $0xfff,%eax
8010317c:	85 c0                	test   %eax,%eax
8010317e:	75 1b                	jne    8010319b <kfree+0x2d>
80103180:	81 7d 08 5c 0e 12 80 	cmpl   $0x80120e5c,0x8(%ebp)
80103187:	72 12                	jb     8010319b <kfree+0x2d>
80103189:	8b 45 08             	mov    0x8(%ebp),%eax
8010318c:	89 04 24             	mov    %eax,(%esp)
8010318f:	e8 38 ff ff ff       	call   801030cc <v2p>
80103194:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103199:	76 50                	jbe    801031eb <kfree+0x7d>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
8010319b:	8b 45 08             	mov    0x8(%ebp),%eax
8010319e:	89 04 24             	mov    %eax,(%esp)
801031a1:	e8 26 ff ff ff       	call   801030cc <v2p>
801031a6:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031ab:	0f 97 c0             	seta   %al
801031ae:	0f b6 d0             	movzbl %al,%edx
801031b1:	81 7d 08 5c 0e 12 80 	cmpl   $0x80120e5c,0x8(%ebp)
801031b8:	0f 92 c0             	setb   %al
801031bb:	0f b6 c0             	movzbl %al,%eax
801031be:	8b 4d 08             	mov    0x8(%ebp),%ecx
801031c1:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
801031c7:	89 54 24 0c          	mov    %edx,0xc(%esp)
801031cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801031cf:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801031d3:	c7 04 24 63 9d 10 80 	movl   $0x80109d63,(%esp)
801031da:	e8 c1 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031df:	c7 04 24 7a 9d 10 80 	movl   $0x80109d7a,(%esp)
801031e6:	e8 4f d3 ff ff       	call   8010053a <panic>
  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  // if(getPid()){
  //   cprintf("after memset\n");
  // }
  if(kmem.use_lock)
801031eb:	a1 54 42 11 80       	mov    0x80114254,%eax
801031f0:	85 c0                	test   %eax,%eax
801031f2:	74 0c                	je     80103200 <kfree+0x92>
    acquire(&kmem.lock);
801031f4:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801031fb:	e8 e0 25 00 00       	call   801057e0 <acquire>
  r = (struct run*)v;
80103200:	8b 45 08             	mov    0x8(%ebp),%eax
80103203:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103206:	8b 15 58 42 11 80    	mov    0x80114258,%edx
8010320c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010320f:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103214:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103219:	a1 54 42 11 80       	mov    0x80114254,%eax
8010321e:	85 c0                	test   %eax,%eax
80103220:	74 0c                	je     8010322e <kfree+0xc0>
    release(&kmem.lock);
80103222:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103229:	e8 14 26 00 00       	call   80105842 <release>
}
8010322e:	c9                   	leave  
8010322f:	c3                   	ret    

80103230 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103230:	55                   	push   %ebp
80103231:	89 e5                	mov    %esp,%ebp
80103233:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103236:	a1 54 42 11 80       	mov    0x80114254,%eax
8010323b:	85 c0                	test   %eax,%eax
8010323d:	74 0c                	je     8010324b <kalloc+0x1b>
    acquire(&kmem.lock);
8010323f:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103246:	e8 95 25 00 00       	call   801057e0 <acquire>
  r = kmem.freelist;
8010324b:	a1 58 42 11 80       	mov    0x80114258,%eax
80103250:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103253:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103257:	74 0a                	je     80103263 <kalloc+0x33>
    kmem.freelist = r->next;
80103259:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010325c:	8b 00                	mov    (%eax),%eax
8010325e:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103263:	a1 54 42 11 80       	mov    0x80114254,%eax
80103268:	85 c0                	test   %eax,%eax
8010326a:	74 0c                	je     80103278 <kalloc+0x48>
    release(&kmem.lock);
8010326c:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103273:	e8 ca 25 00 00       	call   80105842 <release>
  return (char*)r;
80103278:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010327b:	c9                   	leave  
8010327c:	c3                   	ret    

8010327d <countPages>:

int
countPages(){
8010327d:	55                   	push   %ebp
8010327e:	89 e5                	mov    %esp,%ebp
80103280:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
80103283:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
8010328a:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103291:	e8 4a 25 00 00       	call   801057e0 <acquire>
  r = kmem.freelist;
80103296:	a1 58 42 11 80       	mov    0x80114258,%eax
8010329b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
8010329e:	eb 0c                	jmp    801032ac <countPages+0x2f>
    result++;
801032a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
801032a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032a7:	8b 00                	mov    (%eax),%eax
801032a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
801032ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032b0:	75 ee                	jne    801032a0 <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032b2:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032b9:	e8 84 25 00 00       	call   80105842 <release>
  return result;
801032be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c1:	c9                   	leave  
801032c2:	c3                   	ret    

801032c3 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032c3:	55                   	push   %ebp
801032c4:	89 e5                	mov    %esp,%ebp
801032c6:	83 ec 14             	sub    $0x14,%esp
801032c9:	8b 45 08             	mov    0x8(%ebp),%eax
801032cc:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032d0:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032d4:	89 c2                	mov    %eax,%edx
801032d6:	ec                   	in     (%dx),%al
801032d7:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801032da:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801032de:	c9                   	leave  
801032df:	c3                   	ret    

801032e0 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801032e0:	55                   	push   %ebp
801032e1:	89 e5                	mov    %esp,%ebp
801032e3:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801032e6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801032ed:	e8 d1 ff ff ff       	call   801032c3 <inb>
801032f2:	0f b6 c0             	movzbl %al,%eax
801032f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801032f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032fb:	83 e0 01             	and    $0x1,%eax
801032fe:	85 c0                	test   %eax,%eax
80103300:	75 0a                	jne    8010330c <kbdgetc+0x2c>
    return -1;
80103302:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103307:	e9 25 01 00 00       	jmp    80103431 <kbdgetc+0x151>
  data = inb(KBDATAP);
8010330c:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103313:	e8 ab ff ff ff       	call   801032c3 <inb>
80103318:	0f b6 c0             	movzbl %al,%eax
8010331b:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
8010331e:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103325:	75 17                	jne    8010333e <kbdgetc+0x5e>
    shift |= E0ESC;
80103327:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010332c:	83 c8 40             	or     $0x40,%eax
8010332f:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103334:	b8 00 00 00 00       	mov    $0x0,%eax
80103339:	e9 f3 00 00 00       	jmp    80103431 <kbdgetc+0x151>
  } else if(data & 0x80){
8010333e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103341:	25 80 00 00 00       	and    $0x80,%eax
80103346:	85 c0                	test   %eax,%eax
80103348:	74 45                	je     8010338f <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010334a:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010334f:	83 e0 40             	and    $0x40,%eax
80103352:	85 c0                	test   %eax,%eax
80103354:	75 08                	jne    8010335e <kbdgetc+0x7e>
80103356:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103359:	83 e0 7f             	and    $0x7f,%eax
8010335c:	eb 03                	jmp    80103361 <kbdgetc+0x81>
8010335e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103361:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103364:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103367:	05 20 b0 10 80       	add    $0x8010b020,%eax
8010336c:	0f b6 00             	movzbl (%eax),%eax
8010336f:	83 c8 40             	or     $0x40,%eax
80103372:	0f b6 c0             	movzbl %al,%eax
80103375:	f7 d0                	not    %eax
80103377:	89 c2                	mov    %eax,%edx
80103379:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010337e:	21 d0                	and    %edx,%eax
80103380:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103385:	b8 00 00 00 00       	mov    $0x0,%eax
8010338a:	e9 a2 00 00 00       	jmp    80103431 <kbdgetc+0x151>
  } else if(shift & E0ESC){
8010338f:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103394:	83 e0 40             	and    $0x40,%eax
80103397:	85 c0                	test   %eax,%eax
80103399:	74 14                	je     801033af <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010339b:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801033a2:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033a7:	83 e0 bf             	and    $0xffffffbf,%eax
801033aa:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
801033af:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033b2:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033b7:	0f b6 00             	movzbl (%eax),%eax
801033ba:	0f b6 d0             	movzbl %al,%edx
801033bd:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033c2:	09 d0                	or     %edx,%eax
801033c4:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033cc:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033d1:	0f b6 00             	movzbl (%eax),%eax
801033d4:	0f b6 d0             	movzbl %al,%edx
801033d7:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033dc:	31 d0                	xor    %edx,%eax
801033de:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
801033e3:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033e8:	83 e0 03             	and    $0x3,%eax
801033eb:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
801033f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f5:	01 d0                	add    %edx,%eax
801033f7:	0f b6 00             	movzbl (%eax),%eax
801033fa:	0f b6 c0             	movzbl %al,%eax
801033fd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103400:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103405:	83 e0 08             	and    $0x8,%eax
80103408:	85 c0                	test   %eax,%eax
8010340a:	74 22                	je     8010342e <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
8010340c:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103410:	76 0c                	jbe    8010341e <kbdgetc+0x13e>
80103412:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103416:	77 06                	ja     8010341e <kbdgetc+0x13e>
      c += 'A' - 'a';
80103418:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
8010341c:	eb 10                	jmp    8010342e <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
8010341e:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103422:	76 0a                	jbe    8010342e <kbdgetc+0x14e>
80103424:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103428:	77 04                	ja     8010342e <kbdgetc+0x14e>
      c += 'a' - 'A';
8010342a:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
8010342e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103431:	c9                   	leave  
80103432:	c3                   	ret    

80103433 <kbdintr>:

void
kbdintr(void)
{
80103433:	55                   	push   %ebp
80103434:	89 e5                	mov    %esp,%ebp
80103436:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103439:	c7 04 24 e0 32 10 80 	movl   $0x801032e0,(%esp)
80103440:	e8 83 d3 ff ff       	call   801007c8 <consoleintr>
}
80103445:	c9                   	leave  
80103446:	c3                   	ret    

80103447 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103447:	55                   	push   %ebp
80103448:	89 e5                	mov    %esp,%ebp
8010344a:	83 ec 14             	sub    $0x14,%esp
8010344d:	8b 45 08             	mov    0x8(%ebp),%eax
80103450:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103454:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103458:	89 c2                	mov    %eax,%edx
8010345a:	ec                   	in     (%dx),%al
8010345b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010345e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103462:	c9                   	leave  
80103463:	c3                   	ret    

80103464 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103464:	55                   	push   %ebp
80103465:	89 e5                	mov    %esp,%ebp
80103467:	83 ec 08             	sub    $0x8,%esp
8010346a:	8b 55 08             	mov    0x8(%ebp),%edx
8010346d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103470:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103474:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103477:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010347b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010347f:	ee                   	out    %al,(%dx)
}
80103480:	c9                   	leave  
80103481:	c3                   	ret    

80103482 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103482:	55                   	push   %ebp
80103483:	89 e5                	mov    %esp,%ebp
80103485:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103488:	9c                   	pushf  
80103489:	58                   	pop    %eax
8010348a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010348d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103490:	c9                   	leave  
80103491:	c3                   	ret    

80103492 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103492:	55                   	push   %ebp
80103493:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103495:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010349a:	8b 55 08             	mov    0x8(%ebp),%edx
8010349d:	c1 e2 02             	shl    $0x2,%edx
801034a0:	01 c2                	add    %eax,%edx
801034a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801034a5:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801034a7:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034ac:	83 c0 20             	add    $0x20,%eax
801034af:	8b 00                	mov    (%eax),%eax
}
801034b1:	5d                   	pop    %ebp
801034b2:	c3                   	ret    

801034b3 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034b3:	55                   	push   %ebp
801034b4:	89 e5                	mov    %esp,%ebp
801034b6:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034b9:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034be:	85 c0                	test   %eax,%eax
801034c0:	75 05                	jne    801034c7 <lapicinit+0x14>
    return;
801034c2:	e9 43 01 00 00       	jmp    8010360a <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034c7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034ce:	00 
801034cf:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034d6:	e8 b7 ff ff ff       	call   80103492 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801034db:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801034e2:	00 
801034e3:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801034ea:	e8 a3 ff ff ff       	call   80103492 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801034ef:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801034f6:	00 
801034f7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801034fe:	e8 8f ff ff ff       	call   80103492 <lapicw>
  lapicw(TICR, 10000000); 
80103503:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010350a:	00 
8010350b:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103512:	e8 7b ff ff ff       	call   80103492 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103517:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010351e:	00 
8010351f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103526:	e8 67 ff ff ff       	call   80103492 <lapicw>
  lapicw(LINT1, MASKED);
8010352b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103532:	00 
80103533:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010353a:	e8 53 ff ff ff       	call   80103492 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010353f:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103544:	83 c0 30             	add    $0x30,%eax
80103547:	8b 00                	mov    (%eax),%eax
80103549:	c1 e8 10             	shr    $0x10,%eax
8010354c:	0f b6 c0             	movzbl %al,%eax
8010354f:	83 f8 03             	cmp    $0x3,%eax
80103552:	76 14                	jbe    80103568 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103554:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010355b:	00 
8010355c:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103563:	e8 2a ff ff ff       	call   80103492 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103568:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
8010356f:	00 
80103570:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103577:	e8 16 ff ff ff       	call   80103492 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010357c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103583:	00 
80103584:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010358b:	e8 02 ff ff ff       	call   80103492 <lapicw>
  lapicw(ESR, 0);
80103590:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103597:	00 
80103598:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010359f:	e8 ee fe ff ff       	call   80103492 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801035a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035ab:	00 
801035ac:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035b3:	e8 da fe ff ff       	call   80103492 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035bf:	00 
801035c0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035c7:	e8 c6 fe ff ff       	call   80103492 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035cc:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035d3:	00 
801035d4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801035db:	e8 b2 fe ff ff       	call   80103492 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801035e0:	90                   	nop
801035e1:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801035e6:	05 00 03 00 00       	add    $0x300,%eax
801035eb:	8b 00                	mov    (%eax),%eax
801035ed:	25 00 10 00 00       	and    $0x1000,%eax
801035f2:	85 c0                	test   %eax,%eax
801035f4:	75 eb                	jne    801035e1 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801035f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035fd:	00 
801035fe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103605:	e8 88 fe ff ff       	call   80103492 <lapicw>
}
8010360a:	c9                   	leave  
8010360b:	c3                   	ret    

8010360c <cpunum>:

int
cpunum(void)
{
8010360c:	55                   	push   %ebp
8010360d:	89 e5                	mov    %esp,%ebp
8010360f:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103612:	e8 6b fe ff ff       	call   80103482 <readeflags>
80103617:	25 00 02 00 00       	and    $0x200,%eax
8010361c:	85 c0                	test   %eax,%eax
8010361e:	74 25                	je     80103645 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103620:	a1 40 d6 10 80       	mov    0x8010d640,%eax
80103625:	8d 50 01             	lea    0x1(%eax),%edx
80103628:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
8010362e:	85 c0                	test   %eax,%eax
80103630:	75 13                	jne    80103645 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103632:	8b 45 04             	mov    0x4(%ebp),%eax
80103635:	89 44 24 04          	mov    %eax,0x4(%esp)
80103639:	c7 04 24 88 9d 10 80 	movl   $0x80109d88,(%esp)
80103640:	e8 5b cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103645:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010364a:	85 c0                	test   %eax,%eax
8010364c:	74 0f                	je     8010365d <cpunum+0x51>
    return lapic[ID]>>24;
8010364e:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103653:	83 c0 20             	add    $0x20,%eax
80103656:	8b 00                	mov    (%eax),%eax
80103658:	c1 e8 18             	shr    $0x18,%eax
8010365b:	eb 05                	jmp    80103662 <cpunum+0x56>
  return 0;
8010365d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103662:	c9                   	leave  
80103663:	c3                   	ret    

80103664 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103664:	55                   	push   %ebp
80103665:	89 e5                	mov    %esp,%ebp
80103667:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010366a:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010366f:	85 c0                	test   %eax,%eax
80103671:	74 14                	je     80103687 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103673:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010367a:	00 
8010367b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103682:	e8 0b fe ff ff       	call   80103492 <lapicw>
}
80103687:	c9                   	leave  
80103688:	c3                   	ret    

80103689 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103689:	55                   	push   %ebp
8010368a:	89 e5                	mov    %esp,%ebp
}
8010368c:	5d                   	pop    %ebp
8010368d:	c3                   	ret    

8010368e <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010368e:	55                   	push   %ebp
8010368f:	89 e5                	mov    %esp,%ebp
80103691:	83 ec 1c             	sub    $0x1c,%esp
80103694:	8b 45 08             	mov    0x8(%ebp),%eax
80103697:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010369a:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801036a1:	00 
801036a2:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036a9:	e8 b6 fd ff ff       	call   80103464 <outb>
  outb(CMOS_PORT+1, 0x0A);
801036ae:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036b5:	00 
801036b6:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036bd:	e8 a2 fd ff ff       	call   80103464 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036c2:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036cc:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036d1:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036d4:	8d 50 02             	lea    0x2(%eax),%edx
801036d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801036da:	c1 e8 04             	shr    $0x4,%eax
801036dd:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801036e0:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801036e4:	c1 e0 18             	shl    $0x18,%eax
801036e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801036eb:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801036f2:	e8 9b fd ff ff       	call   80103492 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801036f7:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801036fe:	00 
801036ff:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103706:	e8 87 fd ff ff       	call   80103492 <lapicw>
  microdelay(200);
8010370b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103712:	e8 72 ff ff ff       	call   80103689 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103717:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010371e:	00 
8010371f:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103726:	e8 67 fd ff ff       	call   80103492 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010372b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103732:	e8 52 ff ff ff       	call   80103689 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103737:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010373e:	eb 40                	jmp    80103780 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103740:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103744:	c1 e0 18             	shl    $0x18,%eax
80103747:	89 44 24 04          	mov    %eax,0x4(%esp)
8010374b:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103752:	e8 3b fd ff ff       	call   80103492 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103757:	8b 45 0c             	mov    0xc(%ebp),%eax
8010375a:	c1 e8 0c             	shr    $0xc,%eax
8010375d:	80 cc 06             	or     $0x6,%ah
80103760:	89 44 24 04          	mov    %eax,0x4(%esp)
80103764:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010376b:	e8 22 fd ff ff       	call   80103492 <lapicw>
    microdelay(200);
80103770:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103777:	e8 0d ff ff ff       	call   80103689 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010377c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103780:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103784:	7e ba                	jle    80103740 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103786:	c9                   	leave  
80103787:	c3                   	ret    

80103788 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103788:	55                   	push   %ebp
80103789:	89 e5                	mov    %esp,%ebp
8010378b:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010378e:	8b 45 08             	mov    0x8(%ebp),%eax
80103791:	0f b6 c0             	movzbl %al,%eax
80103794:	89 44 24 04          	mov    %eax,0x4(%esp)
80103798:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010379f:	e8 c0 fc ff ff       	call   80103464 <outb>
  microdelay(200);
801037a4:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037ab:	e8 d9 fe ff ff       	call   80103689 <microdelay>

  return inb(CMOS_RETURN);
801037b0:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037b7:	e8 8b fc ff ff       	call   80103447 <inb>
801037bc:	0f b6 c0             	movzbl %al,%eax
}
801037bf:	c9                   	leave  
801037c0:	c3                   	ret    

801037c1 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037c1:	55                   	push   %ebp
801037c2:	89 e5                	mov    %esp,%ebp
801037c4:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037ce:	e8 b5 ff ff ff       	call   80103788 <cmos_read>
801037d3:	8b 55 08             	mov    0x8(%ebp),%edx
801037d6:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801037d8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801037df:	e8 a4 ff ff ff       	call   80103788 <cmos_read>
801037e4:	8b 55 08             	mov    0x8(%ebp),%edx
801037e7:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801037ea:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801037f1:	e8 92 ff ff ff       	call   80103788 <cmos_read>
801037f6:	8b 55 08             	mov    0x8(%ebp),%edx
801037f9:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801037fc:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103803:	e8 80 ff ff ff       	call   80103788 <cmos_read>
80103808:	8b 55 08             	mov    0x8(%ebp),%edx
8010380b:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010380e:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103815:	e8 6e ff ff ff       	call   80103788 <cmos_read>
8010381a:	8b 55 08             	mov    0x8(%ebp),%edx
8010381d:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103820:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103827:	e8 5c ff ff ff       	call   80103788 <cmos_read>
8010382c:	8b 55 08             	mov    0x8(%ebp),%edx
8010382f:	89 42 14             	mov    %eax,0x14(%edx)
}
80103832:	c9                   	leave  
80103833:	c3                   	ret    

80103834 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103834:	55                   	push   %ebp
80103835:	89 e5                	mov    %esp,%ebp
80103837:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010383a:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103841:	e8 42 ff ff ff       	call   80103788 <cmos_read>
80103846:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010384c:	83 e0 04             	and    $0x4,%eax
8010384f:	85 c0                	test   %eax,%eax
80103851:	0f 94 c0             	sete   %al
80103854:	0f b6 c0             	movzbl %al,%eax
80103857:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
8010385a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010385d:	89 04 24             	mov    %eax,(%esp)
80103860:	e8 5c ff ff ff       	call   801037c1 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103865:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010386c:	e8 17 ff ff ff       	call   80103788 <cmos_read>
80103871:	25 80 00 00 00       	and    $0x80,%eax
80103876:	85 c0                	test   %eax,%eax
80103878:	74 02                	je     8010387c <cmostime+0x48>
        continue;
8010387a:	eb 36                	jmp    801038b2 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010387c:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010387f:	89 04 24             	mov    %eax,(%esp)
80103882:	e8 3a ff ff ff       	call   801037c1 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103887:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010388e:	00 
8010388f:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103892:	89 44 24 04          	mov    %eax,0x4(%esp)
80103896:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103899:	89 04 24             	mov    %eax,(%esp)
8010389c:	e8 0a 22 00 00       	call   80105aab <memcmp>
801038a1:	85 c0                	test   %eax,%eax
801038a3:	75 0d                	jne    801038b2 <cmostime+0x7e>
      break;
801038a5:	90                   	nop
  }

  // convert
  if (bcd) {
801038a6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038aa:	0f 84 ac 00 00 00    	je     8010395c <cmostime+0x128>
801038b0:	eb 02                	jmp    801038b4 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038b2:	eb a6                	jmp    8010385a <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038b7:	c1 e8 04             	shr    $0x4,%eax
801038ba:	89 c2                	mov    %eax,%edx
801038bc:	89 d0                	mov    %edx,%eax
801038be:	c1 e0 02             	shl    $0x2,%eax
801038c1:	01 d0                	add    %edx,%eax
801038c3:	01 c0                	add    %eax,%eax
801038c5:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038c8:	83 e2 0f             	and    $0xf,%edx
801038cb:	01 d0                	add    %edx,%eax
801038cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038d3:	c1 e8 04             	shr    $0x4,%eax
801038d6:	89 c2                	mov    %eax,%edx
801038d8:	89 d0                	mov    %edx,%eax
801038da:	c1 e0 02             	shl    $0x2,%eax
801038dd:	01 d0                	add    %edx,%eax
801038df:	01 c0                	add    %eax,%eax
801038e1:	8b 55 dc             	mov    -0x24(%ebp),%edx
801038e4:	83 e2 0f             	and    $0xf,%edx
801038e7:	01 d0                	add    %edx,%eax
801038e9:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801038ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801038ef:	c1 e8 04             	shr    $0x4,%eax
801038f2:	89 c2                	mov    %eax,%edx
801038f4:	89 d0                	mov    %edx,%eax
801038f6:	c1 e0 02             	shl    $0x2,%eax
801038f9:	01 d0                	add    %edx,%eax
801038fb:	01 c0                	add    %eax,%eax
801038fd:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103900:	83 e2 0f             	and    $0xf,%edx
80103903:	01 d0                	add    %edx,%eax
80103905:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103908:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010390b:	c1 e8 04             	shr    $0x4,%eax
8010390e:	89 c2                	mov    %eax,%edx
80103910:	89 d0                	mov    %edx,%eax
80103912:	c1 e0 02             	shl    $0x2,%eax
80103915:	01 d0                	add    %edx,%eax
80103917:	01 c0                	add    %eax,%eax
80103919:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010391c:	83 e2 0f             	and    $0xf,%edx
8010391f:	01 d0                	add    %edx,%eax
80103921:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103924:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103927:	c1 e8 04             	shr    $0x4,%eax
8010392a:	89 c2                	mov    %eax,%edx
8010392c:	89 d0                	mov    %edx,%eax
8010392e:	c1 e0 02             	shl    $0x2,%eax
80103931:	01 d0                	add    %edx,%eax
80103933:	01 c0                	add    %eax,%eax
80103935:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103938:	83 e2 0f             	and    $0xf,%edx
8010393b:	01 d0                	add    %edx,%eax
8010393d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103940:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103943:	c1 e8 04             	shr    $0x4,%eax
80103946:	89 c2                	mov    %eax,%edx
80103948:	89 d0                	mov    %edx,%eax
8010394a:	c1 e0 02             	shl    $0x2,%eax
8010394d:	01 d0                	add    %edx,%eax
8010394f:	01 c0                	add    %eax,%eax
80103951:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103954:	83 e2 0f             	and    $0xf,%edx
80103957:	01 d0                	add    %edx,%eax
80103959:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010395c:	8b 45 08             	mov    0x8(%ebp),%eax
8010395f:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103962:	89 10                	mov    %edx,(%eax)
80103964:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103967:	89 50 04             	mov    %edx,0x4(%eax)
8010396a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010396d:	89 50 08             	mov    %edx,0x8(%eax)
80103970:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103973:	89 50 0c             	mov    %edx,0xc(%eax)
80103976:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103979:	89 50 10             	mov    %edx,0x10(%eax)
8010397c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010397f:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103982:	8b 45 08             	mov    0x8(%ebp),%eax
80103985:	8b 40 14             	mov    0x14(%eax),%eax
80103988:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010398e:	8b 45 08             	mov    0x8(%ebp),%eax
80103991:	89 50 14             	mov    %edx,0x14(%eax)
}
80103994:	c9                   	leave  
80103995:	c3                   	ret    

80103996 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103996:	55                   	push   %ebp
80103997:	89 e5                	mov    %esp,%ebp
80103999:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010399c:	c7 44 24 04 b4 9d 10 	movl   $0x80109db4,0x4(%esp)
801039a3:	80 
801039a4:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
801039ab:	e8 0f 1e 00 00       	call   801057bf <initlock>
  readsb(dev, &sb);
801039b0:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801039b7:	8b 45 08             	mov    0x8(%ebp),%eax
801039ba:	89 04 24             	mov    %eax,(%esp)
801039bd:	e8 90 da ff ff       	call   80101452 <readsb>
  log.start = sb.logstart;
801039c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039c5:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039cd:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039d2:	8b 45 08             	mov    0x8(%ebp),%eax
801039d5:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
801039da:	e8 9a 01 00 00       	call   80103b79 <recover_from_log>
}
801039df:	c9                   	leave  
801039e0:	c3                   	ret    

801039e1 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801039e1:	55                   	push   %ebp
801039e2:	89 e5                	mov    %esp,%ebp
801039e4:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801039e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039ee:	e9 8c 00 00 00       	jmp    80103a7f <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801039f3:	8b 15 94 42 11 80    	mov    0x80114294,%edx
801039f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039fc:	01 d0                	add    %edx,%eax
801039fe:	83 c0 01             	add    $0x1,%eax
80103a01:	89 c2                	mov    %eax,%edx
80103a03:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a08:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a0c:	89 04 24             	mov    %eax,(%esp)
80103a0f:	e8 92 c7 ff ff       	call   801001a6 <bread>
80103a14:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a1a:	83 c0 10             	add    $0x10,%eax
80103a1d:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a24:	89 c2                	mov    %eax,%edx
80103a26:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a2b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a2f:	89 04 24             	mov    %eax,(%esp)
80103a32:	e8 6f c7 ff ff       	call   801001a6 <bread>
80103a37:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a3d:	8d 50 18             	lea    0x18(%eax),%edx
80103a40:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a43:	83 c0 18             	add    $0x18,%eax
80103a46:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a4d:	00 
80103a4e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a52:	89 04 24             	mov    %eax,(%esp)
80103a55:	e8 a9 20 00 00       	call   80105b03 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a5d:	89 04 24             	mov    %eax,(%esp)
80103a60:	e8 78 c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a68:	89 04 24             	mov    %eax,(%esp)
80103a6b:	e8 a7 c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a70:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a73:	89 04 24             	mov    %eax,(%esp)
80103a76:	e8 9c c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a7b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a7f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103a84:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a87:	0f 8f 66 ff ff ff    	jg     801039f3 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103a8d:	c9                   	leave  
80103a8e:	c3                   	ret    

80103a8f <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103a8f:	55                   	push   %ebp
80103a90:	89 e5                	mov    %esp,%ebp
80103a92:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103a95:	a1 94 42 11 80       	mov    0x80114294,%eax
80103a9a:	89 c2                	mov    %eax,%edx
80103a9c:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103aa1:	89 54 24 04          	mov    %edx,0x4(%esp)
80103aa5:	89 04 24             	mov    %eax,(%esp)
80103aa8:	e8 f9 c6 ff ff       	call   801001a6 <bread>
80103aad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103ab0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ab3:	83 c0 18             	add    $0x18,%eax
80103ab6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103ab9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103abc:	8b 00                	mov    (%eax),%eax
80103abe:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103ac3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103aca:	eb 1b                	jmp    80103ae7 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103acc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103acf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ad2:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103ad6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ad9:	83 c2 10             	add    $0x10,%edx
80103adc:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103ae3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ae7:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103aec:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103aef:	7f db                	jg     80103acc <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103af1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103af4:	89 04 24             	mov    %eax,(%esp)
80103af7:	e8 1b c7 ff ff       	call   80100217 <brelse>
}
80103afc:	c9                   	leave  
80103afd:	c3                   	ret    

80103afe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103afe:	55                   	push   %ebp
80103aff:	89 e5                	mov    %esp,%ebp
80103b01:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b04:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b09:	89 c2                	mov    %eax,%edx
80103b0b:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b10:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b14:	89 04 24             	mov    %eax,(%esp)
80103b17:	e8 8a c6 ff ff       	call   801001a6 <bread>
80103b1c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b22:	83 c0 18             	add    $0x18,%eax
80103b25:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b28:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b31:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b3a:	eb 1b                	jmp    80103b57 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b3f:	83 c0 10             	add    $0x10,%eax
80103b42:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b49:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b4f:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b53:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b57:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b5c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b5f:	7f db                	jg     80103b3c <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b64:	89 04 24             	mov    %eax,(%esp)
80103b67:	e8 71 c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b6f:	89 04 24             	mov    %eax,(%esp)
80103b72:	e8 a0 c6 ff ff       	call   80100217 <brelse>
}
80103b77:	c9                   	leave  
80103b78:	c3                   	ret    

80103b79 <recover_from_log>:

static void
recover_from_log(void)
{
80103b79:	55                   	push   %ebp
80103b7a:	89 e5                	mov    %esp,%ebp
80103b7c:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103b7f:	e8 0b ff ff ff       	call   80103a8f <read_head>
  install_trans(); // if committed, copy from log to disk
80103b84:	e8 58 fe ff ff       	call   801039e1 <install_trans>
  log.lh.n = 0;
80103b89:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103b90:	00 00 00 
  write_head(); // clear the log
80103b93:	e8 66 ff ff ff       	call   80103afe <write_head>
}
80103b98:	c9                   	leave  
80103b99:	c3                   	ret    

80103b9a <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103b9a:	55                   	push   %ebp
80103b9b:	89 e5                	mov    %esp,%ebp
80103b9d:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103ba0:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ba7:	e8 34 1c 00 00       	call   801057e0 <acquire>
  while(1){
    if(log.committing){
80103bac:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103bb1:	85 c0                	test   %eax,%eax
80103bb3:	74 16                	je     80103bcb <begin_op+0x31>
      sleep(&log, &log.lock);
80103bb5:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bbc:	80 
80103bbd:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bc4:	e8 cf 18 00 00       	call   80105498 <sleep>
80103bc9:	eb 4f                	jmp    80103c1a <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103bcb:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103bd1:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bd6:	8d 50 01             	lea    0x1(%eax),%edx
80103bd9:	89 d0                	mov    %edx,%eax
80103bdb:	c1 e0 02             	shl    $0x2,%eax
80103bde:	01 d0                	add    %edx,%eax
80103be0:	01 c0                	add    %eax,%eax
80103be2:	01 c8                	add    %ecx,%eax
80103be4:	83 f8 1e             	cmp    $0x1e,%eax
80103be7:	7e 16                	jle    80103bff <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103be9:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bf0:	80 
80103bf1:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bf8:	e8 9b 18 00 00       	call   80105498 <sleep>
80103bfd:	eb 1b                	jmp    80103c1a <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103bff:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c04:	83 c0 01             	add    $0x1,%eax
80103c07:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c0c:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c13:	e8 2a 1c 00 00       	call   80105842 <release>
      break;
80103c18:	eb 02                	jmp    80103c1c <begin_op+0x82>
    }
  }
80103c1a:	eb 90                	jmp    80103bac <begin_op+0x12>
}
80103c1c:	c9                   	leave  
80103c1d:	c3                   	ret    

80103c1e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c1e:	55                   	push   %ebp
80103c1f:	89 e5                	mov    %esp,%ebp
80103c21:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c2b:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c32:	e8 a9 1b 00 00       	call   801057e0 <acquire>
  log.outstanding -= 1;
80103c37:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c3c:	83 e8 01             	sub    $0x1,%eax
80103c3f:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c44:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c49:	85 c0                	test   %eax,%eax
80103c4b:	74 0c                	je     80103c59 <end_op+0x3b>
    panic("log.committing");
80103c4d:	c7 04 24 b8 9d 10 80 	movl   $0x80109db8,(%esp)
80103c54:	e8 e1 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c59:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c5e:	85 c0                	test   %eax,%eax
80103c60:	75 13                	jne    80103c75 <end_op+0x57>
    do_commit = 1;
80103c62:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c69:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c70:	00 00 00 
80103c73:	eb 0c                	jmp    80103c81 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c75:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c7c:	e8 f3 18 00 00       	call   80105574 <wakeup>
  }
  release(&log.lock);
80103c81:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c88:	e8 b5 1b 00 00       	call   80105842 <release>

  if(do_commit){
80103c8d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c91:	74 33                	je     80103cc6 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103c93:	e8 de 00 00 00       	call   80103d76 <commit>
    acquire(&log.lock);
80103c98:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c9f:	e8 3c 1b 00 00       	call   801057e0 <acquire>
    log.committing = 0;
80103ca4:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103cab:	00 00 00 
    wakeup(&log);
80103cae:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cb5:	e8 ba 18 00 00       	call   80105574 <wakeup>
    release(&log.lock);
80103cba:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cc1:	e8 7c 1b 00 00       	call   80105842 <release>
  }
}
80103cc6:	c9                   	leave  
80103cc7:	c3                   	ret    

80103cc8 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103cc8:	55                   	push   %ebp
80103cc9:	89 e5                	mov    %esp,%ebp
80103ccb:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103cce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103cd5:	e9 8c 00 00 00       	jmp    80103d66 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103cda:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103ce0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce3:	01 d0                	add    %edx,%eax
80103ce5:	83 c0 01             	add    $0x1,%eax
80103ce8:	89 c2                	mov    %eax,%edx
80103cea:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103cef:	89 54 24 04          	mov    %edx,0x4(%esp)
80103cf3:	89 04 24             	mov    %eax,(%esp)
80103cf6:	e8 ab c4 ff ff       	call   801001a6 <bread>
80103cfb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103cfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d01:	83 c0 10             	add    $0x10,%eax
80103d04:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d0b:	89 c2                	mov    %eax,%edx
80103d0d:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d12:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d16:	89 04 24             	mov    %eax,(%esp)
80103d19:	e8 88 c4 ff ff       	call   801001a6 <bread>
80103d1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d21:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d24:	8d 50 18             	lea    0x18(%eax),%edx
80103d27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d2a:	83 c0 18             	add    $0x18,%eax
80103d2d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d34:	00 
80103d35:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d39:	89 04 24             	mov    %eax,(%esp)
80103d3c:	e8 c2 1d 00 00       	call   80105b03 <memmove>
    bwrite(to);  // write the log
80103d41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d44:	89 04 24             	mov    %eax,(%esp)
80103d47:	e8 91 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d4c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d4f:	89 04 24             	mov    %eax,(%esp)
80103d52:	e8 c0 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d5a:	89 04 24             	mov    %eax,(%esp)
80103d5d:	e8 b5 c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d62:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d66:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d6b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d6e:	0f 8f 66 ff ff ff    	jg     80103cda <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d74:	c9                   	leave  
80103d75:	c3                   	ret    

80103d76 <commit>:

static void
commit()
{
80103d76:	55                   	push   %ebp
80103d77:	89 e5                	mov    %esp,%ebp
80103d79:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103d7c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d81:	85 c0                	test   %eax,%eax
80103d83:	7e 1e                	jle    80103da3 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103d85:	e8 3e ff ff ff       	call   80103cc8 <write_log>
    write_head();    // Write header to disk -- the real commit
80103d8a:	e8 6f fd ff ff       	call   80103afe <write_head>
    install_trans(); // Now install writes to home locations
80103d8f:	e8 4d fc ff ff       	call   801039e1 <install_trans>
    log.lh.n = 0; 
80103d94:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103d9b:	00 00 00 
    write_head();    // Erase the transaction from the log
80103d9e:	e8 5b fd ff ff       	call   80103afe <write_head>
  }
}
80103da3:	c9                   	leave  
80103da4:	c3                   	ret    

80103da5 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103da5:	55                   	push   %ebp
80103da6:	89 e5                	mov    %esp,%ebp
80103da8:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103dab:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103db0:	83 f8 1d             	cmp    $0x1d,%eax
80103db3:	7f 12                	jg     80103dc7 <log_write+0x22>
80103db5:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dba:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103dc0:	83 ea 01             	sub    $0x1,%edx
80103dc3:	39 d0                	cmp    %edx,%eax
80103dc5:	7c 0c                	jl     80103dd3 <log_write+0x2e>
    panic("too big a transaction");
80103dc7:	c7 04 24 c7 9d 10 80 	movl   $0x80109dc7,(%esp)
80103dce:	e8 67 c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103dd3:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103dd8:	85 c0                	test   %eax,%eax
80103dda:	7f 0c                	jg     80103de8 <log_write+0x43>
    panic("log_write outside of trans");
80103ddc:	c7 04 24 dd 9d 10 80 	movl   $0x80109ddd,(%esp)
80103de3:	e8 52 c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103de8:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103def:	e8 ec 19 00 00       	call   801057e0 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103df4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103dfb:	eb 1f                	jmp    80103e1c <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e00:	83 c0 10             	add    $0x10,%eax
80103e03:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e0a:	89 c2                	mov    %eax,%edx
80103e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0f:	8b 40 08             	mov    0x8(%eax),%eax
80103e12:	39 c2                	cmp    %eax,%edx
80103e14:	75 02                	jne    80103e18 <log_write+0x73>
      break;
80103e16:	eb 0e                	jmp    80103e26 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e18:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e1c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e21:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e24:	7f d7                	jg     80103dfd <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e26:	8b 45 08             	mov    0x8(%ebp),%eax
80103e29:	8b 40 08             	mov    0x8(%eax),%eax
80103e2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e2f:	83 c2 10             	add    $0x10,%edx
80103e32:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e39:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e3e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e41:	75 0d                	jne    80103e50 <log_write+0xab>
    log.lh.n++;
80103e43:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e48:	83 c0 01             	add    $0x1,%eax
80103e4b:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e50:	8b 45 08             	mov    0x8(%ebp),%eax
80103e53:	8b 00                	mov    (%eax),%eax
80103e55:	83 c8 04             	or     $0x4,%eax
80103e58:	89 c2                	mov    %eax,%edx
80103e5a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5d:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e5f:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e66:	e8 d7 19 00 00       	call   80105842 <release>
}
80103e6b:	c9                   	leave  
80103e6c:	c3                   	ret    

80103e6d <v2p>:
80103e6d:	55                   	push   %ebp
80103e6e:	89 e5                	mov    %esp,%ebp
80103e70:	8b 45 08             	mov    0x8(%ebp),%eax
80103e73:	05 00 00 00 80       	add    $0x80000000,%eax
80103e78:	5d                   	pop    %ebp
80103e79:	c3                   	ret    

80103e7a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e7a:	55                   	push   %ebp
80103e7b:	89 e5                	mov    %esp,%ebp
80103e7d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e80:	05 00 00 00 80       	add    $0x80000000,%eax
80103e85:	5d                   	pop    %ebp
80103e86:	c3                   	ret    

80103e87 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103e87:	55                   	push   %ebp
80103e88:	89 e5                	mov    %esp,%ebp
80103e8a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103e8d:	8b 55 08             	mov    0x8(%ebp),%edx
80103e90:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e93:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e96:	f0 87 02             	lock xchg %eax,(%edx)
80103e99:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103e9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103e9f:	c9                   	leave  
80103ea0:	c3                   	ret    

80103ea1 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103ea1:	55                   	push   %ebp
80103ea2:	89 e5                	mov    %esp,%ebp
80103ea4:	83 e4 f0             	and    $0xfffffff0,%esp
80103ea7:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103eaa:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103eb1:	80 
80103eb2:	c7 04 24 5c 0e 12 80 	movl   $0x80120e5c,(%esp)
80103eb9:	e8 1b f2 ff ff       	call   801030d9 <kinit1>
  kvmalloc();      // kernel page table
80103ebe:	e8 dc 47 00 00       	call   8010869f <kvmalloc>
  mpinit();        // collect info about this machine
80103ec3:	e8 41 04 00 00       	call   80104309 <mpinit>
  lapicinit();
80103ec8:	e8 e6 f5 ff ff       	call   801034b3 <lapicinit>
  seginit();       // set up segments
80103ecd:	e8 60 41 00 00       	call   80108032 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103ed2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ed8:	0f b6 00             	movzbl (%eax),%eax
80103edb:	0f b6 c0             	movzbl %al,%eax
80103ede:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ee2:	c7 04 24 f8 9d 10 80 	movl   $0x80109df8,(%esp)
80103ee9:	e8 b2 c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103eee:	e8 74 06 00 00       	call   80104567 <picinit>
  ioapicinit();    // another interrupt controller
80103ef3:	e8 d7 f0 ff ff       	call   80102fcf <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ef8:	e8 b3 cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103efd:	e8 7f 34 00 00       	call   80107381 <uartinit>
  pinit();         // process table
80103f02:	e8 6a 0b 00 00       	call   80104a71 <pinit>
  tvinit();        // trap vectors
80103f07:	e8 81 2f 00 00       	call   80106e8d <tvinit>
  binit();         // buffer cache
80103f0c:	e8 23 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f11:	e8 55 d1 ff ff       	call   8010106b <fileinit>
  ideinit();       // disk
80103f16:	e8 e6 ec ff ff       	call   80102c01 <ideinit>
  if(!ismp)
80103f1b:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f20:	85 c0                	test   %eax,%eax
80103f22:	75 05                	jne    80103f29 <main+0x88>
    timerinit();   // uniprocessor timer
80103f24:	e8 af 2e 00 00       	call   80106dd8 <timerinit>
  startothers();   // start other processors
80103f29:	e8 7f 00 00 00       	call   80103fad <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f2e:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f35:	8e 
80103f36:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f3d:	e8 cf f1 ff ff       	call   80103111 <kinit2>
  userinit();      // first user process
80103f42:	e8 48 0c 00 00       	call   80104b8f <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f47:	e8 1a 00 00 00       	call   80103f66 <mpmain>

80103f4c <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f4c:	55                   	push   %ebp
80103f4d:	89 e5                	mov    %esp,%ebp
80103f4f:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f52:	e8 5f 47 00 00       	call   801086b6 <switchkvm>
  seginit();
80103f57:	e8 d6 40 00 00       	call   80108032 <seginit>
  lapicinit();
80103f5c:	e8 52 f5 ff ff       	call   801034b3 <lapicinit>
  mpmain();
80103f61:	e8 00 00 00 00       	call   80103f66 <mpmain>

80103f66 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f66:	55                   	push   %ebp
80103f67:	89 e5                	mov    %esp,%ebp
80103f69:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f6c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f72:	0f b6 00             	movzbl (%eax),%eax
80103f75:	0f b6 c0             	movzbl %al,%eax
80103f78:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f7c:	c7 04 24 0f 9e 10 80 	movl   $0x80109e0f,(%esp)
80103f83:	e8 18 c4 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103f88:	e8 74 30 00 00       	call   80107001 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103f8d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f93:	05 a8 00 00 00       	add    $0xa8,%eax
80103f98:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103f9f:	00 
80103fa0:	89 04 24             	mov    %eax,(%esp)
80103fa3:	e8 df fe ff ff       	call   80103e87 <xchg>
  scheduler();     // start running processes
80103fa8:	e8 2d 13 00 00       	call   801052da <scheduler>

80103fad <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fad:	55                   	push   %ebp
80103fae:	89 e5                	mov    %esp,%ebp
80103fb0:	53                   	push   %ebx
80103fb1:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fb4:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fbb:	e8 ba fe ff ff       	call   80103e7a <p2v>
80103fc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fc3:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fc8:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fcc:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103fd3:	80 
80103fd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fd7:	89 04 24             	mov    %eax,(%esp)
80103fda:	e8 24 1b 00 00       	call   80105b03 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103fdf:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80103fe6:	e9 85 00 00 00       	jmp    80104070 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103feb:	e8 1c f6 ff ff       	call   8010360c <cpunum>
80103ff0:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103ff6:	05 60 43 11 80       	add    $0x80114360,%eax
80103ffb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ffe:	75 02                	jne    80104002 <startothers+0x55>
      continue;
80104000:	eb 67                	jmp    80104069 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104002:	e8 29 f2 ff ff       	call   80103230 <kalloc>
80104007:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010400a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010400d:	83 e8 04             	sub    $0x4,%eax
80104010:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104013:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104019:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010401b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010401e:	83 e8 08             	sub    $0x8,%eax
80104021:	c7 00 4c 3f 10 80    	movl   $0x80103f4c,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104027:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010402a:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010402d:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
80104034:	e8 34 fe ff ff       	call   80103e6d <v2p>
80104039:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010403b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010403e:	89 04 24             	mov    %eax,(%esp)
80104041:	e8 27 fe ff ff       	call   80103e6d <v2p>
80104046:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104049:	0f b6 12             	movzbl (%edx),%edx
8010404c:	0f b6 d2             	movzbl %dl,%edx
8010404f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104053:	89 14 24             	mov    %edx,(%esp)
80104056:	e8 33 f6 ff ff       	call   8010368e <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010405b:	90                   	nop
8010405c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010405f:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104065:	85 c0                	test   %eax,%eax
80104067:	74 f3                	je     8010405c <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104069:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104070:	a1 40 49 11 80       	mov    0x80114940,%eax
80104075:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010407b:	05 60 43 11 80       	add    $0x80114360,%eax
80104080:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104083:	0f 87 62 ff ff ff    	ja     80103feb <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104089:	83 c4 24             	add    $0x24,%esp
8010408c:	5b                   	pop    %ebx
8010408d:	5d                   	pop    %ebp
8010408e:	c3                   	ret    

8010408f <p2v>:
8010408f:	55                   	push   %ebp
80104090:	89 e5                	mov    %esp,%ebp
80104092:	8b 45 08             	mov    0x8(%ebp),%eax
80104095:	05 00 00 00 80       	add    $0x80000000,%eax
8010409a:	5d                   	pop    %ebp
8010409b:	c3                   	ret    

8010409c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010409c:	55                   	push   %ebp
8010409d:	89 e5                	mov    %esp,%ebp
8010409f:	83 ec 14             	sub    $0x14,%esp
801040a2:	8b 45 08             	mov    0x8(%ebp),%eax
801040a5:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040a9:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801040ad:	89 c2                	mov    %eax,%edx
801040af:	ec                   	in     (%dx),%al
801040b0:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040b3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040b7:	c9                   	leave  
801040b8:	c3                   	ret    

801040b9 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040b9:	55                   	push   %ebp
801040ba:	89 e5                	mov    %esp,%ebp
801040bc:	83 ec 08             	sub    $0x8,%esp
801040bf:	8b 55 08             	mov    0x8(%ebp),%edx
801040c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801040c5:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040c9:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040cc:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040d0:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040d4:	ee                   	out    %al,(%dx)
}
801040d5:	c9                   	leave  
801040d6:	c3                   	ret    

801040d7 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040d7:	55                   	push   %ebp
801040d8:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040da:	a1 44 d6 10 80       	mov    0x8010d644,%eax
801040df:	89 c2                	mov    %eax,%edx
801040e1:	b8 60 43 11 80       	mov    $0x80114360,%eax
801040e6:	29 c2                	sub    %eax,%edx
801040e8:	89 d0                	mov    %edx,%eax
801040ea:	c1 f8 02             	sar    $0x2,%eax
801040ed:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801040f3:	5d                   	pop    %ebp
801040f4:	c3                   	ret    

801040f5 <sum>:

static uchar
sum(uchar *addr, int len)
{
801040f5:	55                   	push   %ebp
801040f6:	89 e5                	mov    %esp,%ebp
801040f8:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801040fb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104102:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104109:	eb 15                	jmp    80104120 <sum+0x2b>
    sum += addr[i];
8010410b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010410e:	8b 45 08             	mov    0x8(%ebp),%eax
80104111:	01 d0                	add    %edx,%eax
80104113:	0f b6 00             	movzbl (%eax),%eax
80104116:	0f b6 c0             	movzbl %al,%eax
80104119:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010411c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104120:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104123:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104126:	7c e3                	jl     8010410b <sum+0x16>
    sum += addr[i];
  return sum;
80104128:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010412b:	c9                   	leave  
8010412c:	c3                   	ret    

8010412d <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010412d:	55                   	push   %ebp
8010412e:	89 e5                	mov    %esp,%ebp
80104130:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104133:	8b 45 08             	mov    0x8(%ebp),%eax
80104136:	89 04 24             	mov    %eax,(%esp)
80104139:	e8 51 ff ff ff       	call   8010408f <p2v>
8010413e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104141:	8b 55 0c             	mov    0xc(%ebp),%edx
80104144:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104147:	01 d0                	add    %edx,%eax
80104149:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010414c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010414f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104152:	eb 3f                	jmp    80104193 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104154:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010415b:	00 
8010415c:	c7 44 24 04 20 9e 10 	movl   $0x80109e20,0x4(%esp)
80104163:	80 
80104164:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104167:	89 04 24             	mov    %eax,(%esp)
8010416a:	e8 3c 19 00 00       	call   80105aab <memcmp>
8010416f:	85 c0                	test   %eax,%eax
80104171:	75 1c                	jne    8010418f <mpsearch1+0x62>
80104173:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010417a:	00 
8010417b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417e:	89 04 24             	mov    %eax,(%esp)
80104181:	e8 6f ff ff ff       	call   801040f5 <sum>
80104186:	84 c0                	test   %al,%al
80104188:	75 05                	jne    8010418f <mpsearch1+0x62>
      return (struct mp*)p;
8010418a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010418d:	eb 11                	jmp    801041a0 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010418f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104193:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104196:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104199:	72 b9                	jb     80104154 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010419b:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041a0:	c9                   	leave  
801041a1:	c3                   	ret    

801041a2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801041a2:	55                   	push   %ebp
801041a3:	89 e5                	mov    %esp,%ebp
801041a5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041a8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b2:	83 c0 0f             	add    $0xf,%eax
801041b5:	0f b6 00             	movzbl (%eax),%eax
801041b8:	0f b6 c0             	movzbl %al,%eax
801041bb:	c1 e0 08             	shl    $0x8,%eax
801041be:	89 c2                	mov    %eax,%edx
801041c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c3:	83 c0 0e             	add    $0xe,%eax
801041c6:	0f b6 00             	movzbl (%eax),%eax
801041c9:	0f b6 c0             	movzbl %al,%eax
801041cc:	09 d0                	or     %edx,%eax
801041ce:	c1 e0 04             	shl    $0x4,%eax
801041d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041d4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041d8:	74 21                	je     801041fb <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041da:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041e1:	00 
801041e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041e5:	89 04 24             	mov    %eax,(%esp)
801041e8:	e8 40 ff ff ff       	call   8010412d <mpsearch1>
801041ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
801041f0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801041f4:	74 50                	je     80104246 <mpsearch+0xa4>
      return mp;
801041f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041f9:	eb 5f                	jmp    8010425a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801041fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041fe:	83 c0 14             	add    $0x14,%eax
80104201:	0f b6 00             	movzbl (%eax),%eax
80104204:	0f b6 c0             	movzbl %al,%eax
80104207:	c1 e0 08             	shl    $0x8,%eax
8010420a:	89 c2                	mov    %eax,%edx
8010420c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420f:	83 c0 13             	add    $0x13,%eax
80104212:	0f b6 00             	movzbl (%eax),%eax
80104215:	0f b6 c0             	movzbl %al,%eax
80104218:	09 d0                	or     %edx,%eax
8010421a:	c1 e0 0a             	shl    $0xa,%eax
8010421d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104220:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104223:	2d 00 04 00 00       	sub    $0x400,%eax
80104228:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010422f:	00 
80104230:	89 04 24             	mov    %eax,(%esp)
80104233:	e8 f5 fe ff ff       	call   8010412d <mpsearch1>
80104238:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010423b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010423f:	74 05                	je     80104246 <mpsearch+0xa4>
      return mp;
80104241:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104244:	eb 14                	jmp    8010425a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104246:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010424d:	00 
8010424e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104255:	e8 d3 fe ff ff       	call   8010412d <mpsearch1>
}
8010425a:	c9                   	leave  
8010425b:	c3                   	ret    

8010425c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010425c:	55                   	push   %ebp
8010425d:	89 e5                	mov    %esp,%ebp
8010425f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104262:	e8 3b ff ff ff       	call   801041a2 <mpsearch>
80104267:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010426a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010426e:	74 0a                	je     8010427a <mpconfig+0x1e>
80104270:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104273:	8b 40 04             	mov    0x4(%eax),%eax
80104276:	85 c0                	test   %eax,%eax
80104278:	75 0a                	jne    80104284 <mpconfig+0x28>
    return 0;
8010427a:	b8 00 00 00 00       	mov    $0x0,%eax
8010427f:	e9 83 00 00 00       	jmp    80104307 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104287:	8b 40 04             	mov    0x4(%eax),%eax
8010428a:	89 04 24             	mov    %eax,(%esp)
8010428d:	e8 fd fd ff ff       	call   8010408f <p2v>
80104292:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104295:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010429c:	00 
8010429d:	c7 44 24 04 25 9e 10 	movl   $0x80109e25,0x4(%esp)
801042a4:	80 
801042a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042a8:	89 04 24             	mov    %eax,(%esp)
801042ab:	e8 fb 17 00 00       	call   80105aab <memcmp>
801042b0:	85 c0                	test   %eax,%eax
801042b2:	74 07                	je     801042bb <mpconfig+0x5f>
    return 0;
801042b4:	b8 00 00 00 00       	mov    $0x0,%eax
801042b9:	eb 4c                	jmp    80104307 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042be:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042c2:	3c 01                	cmp    $0x1,%al
801042c4:	74 12                	je     801042d8 <mpconfig+0x7c>
801042c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042c9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042cd:	3c 04                	cmp    $0x4,%al
801042cf:	74 07                	je     801042d8 <mpconfig+0x7c>
    return 0;
801042d1:	b8 00 00 00 00       	mov    $0x0,%eax
801042d6:	eb 2f                	jmp    80104307 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042db:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042df:	0f b7 c0             	movzwl %ax,%eax
801042e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801042e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042e9:	89 04 24             	mov    %eax,(%esp)
801042ec:	e8 04 fe ff ff       	call   801040f5 <sum>
801042f1:	84 c0                	test   %al,%al
801042f3:	74 07                	je     801042fc <mpconfig+0xa0>
    return 0;
801042f5:	b8 00 00 00 00       	mov    $0x0,%eax
801042fa:	eb 0b                	jmp    80104307 <mpconfig+0xab>
  *pmp = mp;
801042fc:	8b 45 08             	mov    0x8(%ebp),%eax
801042ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104302:	89 10                	mov    %edx,(%eax)
  return conf;
80104304:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104307:	c9                   	leave  
80104308:	c3                   	ret    

80104309 <mpinit>:

void
mpinit(void)
{
80104309:	55                   	push   %ebp
8010430a:	89 e5                	mov    %esp,%ebp
8010430c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010430f:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
80104316:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104319:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010431c:	89 04 24             	mov    %eax,(%esp)
8010431f:	e8 38 ff ff ff       	call   8010425c <mpconfig>
80104324:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104327:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010432b:	75 05                	jne    80104332 <mpinit+0x29>
    return;
8010432d:	e9 9c 01 00 00       	jmp    801044ce <mpinit+0x1c5>
  ismp = 1;
80104332:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
80104339:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010433c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010433f:	8b 40 24             	mov    0x24(%eax),%eax
80104342:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104347:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434a:	83 c0 2c             	add    $0x2c,%eax
8010434d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104350:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104353:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104357:	0f b7 d0             	movzwl %ax,%edx
8010435a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010435d:	01 d0                	add    %edx,%eax
8010435f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104362:	e9 f4 00 00 00       	jmp    8010445b <mpinit+0x152>
    switch(*p){
80104367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010436a:	0f b6 00             	movzbl (%eax),%eax
8010436d:	0f b6 c0             	movzbl %al,%eax
80104370:	83 f8 04             	cmp    $0x4,%eax
80104373:	0f 87 bf 00 00 00    	ja     80104438 <mpinit+0x12f>
80104379:	8b 04 85 68 9e 10 80 	mov    -0x7fef6198(,%eax,4),%eax
80104380:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104382:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104385:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104388:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010438b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010438f:	0f b6 d0             	movzbl %al,%edx
80104392:	a1 40 49 11 80       	mov    0x80114940,%eax
80104397:	39 c2                	cmp    %eax,%edx
80104399:	74 2d                	je     801043c8 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010439b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010439e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043a2:	0f b6 d0             	movzbl %al,%edx
801043a5:	a1 40 49 11 80       	mov    0x80114940,%eax
801043aa:	89 54 24 08          	mov    %edx,0x8(%esp)
801043ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801043b2:	c7 04 24 2a 9e 10 80 	movl   $0x80109e2a,(%esp)
801043b9:	e8 e2 bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043be:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043c5:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043cb:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043cf:	0f b6 c0             	movzbl %al,%eax
801043d2:	83 e0 02             	and    $0x2,%eax
801043d5:	85 c0                	test   %eax,%eax
801043d7:	74 15                	je     801043ee <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801043d9:	a1 40 49 11 80       	mov    0x80114940,%eax
801043de:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801043e4:	05 60 43 11 80       	add    $0x80114360,%eax
801043e9:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
801043ee:	8b 15 40 49 11 80    	mov    0x80114940,%edx
801043f4:	a1 40 49 11 80       	mov    0x80114940,%eax
801043f9:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801043ff:	81 c2 60 43 11 80    	add    $0x80114360,%edx
80104405:	88 02                	mov    %al,(%edx)
      ncpu++;
80104407:	a1 40 49 11 80       	mov    0x80114940,%eax
8010440c:	83 c0 01             	add    $0x1,%eax
8010440f:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
80104414:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104418:	eb 41                	jmp    8010445b <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010441a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010441d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104423:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104427:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
8010442c:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104430:	eb 29                	jmp    8010445b <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104432:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104436:	eb 23                	jmp    8010445b <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104438:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010443b:	0f b6 00             	movzbl (%eax),%eax
8010443e:	0f b6 c0             	movzbl %al,%eax
80104441:	89 44 24 04          	mov    %eax,0x4(%esp)
80104445:	c7 04 24 48 9e 10 80 	movl   $0x80109e48,(%esp)
8010444c:	e8 4f bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104451:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104458:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010445b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010445e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104461:	0f 82 00 ff ff ff    	jb     80104367 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104467:	a1 44 43 11 80       	mov    0x80114344,%eax
8010446c:	85 c0                	test   %eax,%eax
8010446e:	75 1d                	jne    8010448d <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104470:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
80104477:	00 00 00 
    lapic = 0;
8010447a:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
80104481:	00 00 00 
    ioapicid = 0;
80104484:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
8010448b:	eb 41                	jmp    801044ce <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010448d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104490:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104494:	84 c0                	test   %al,%al
80104496:	74 36                	je     801044ce <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104498:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
8010449f:	00 
801044a0:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801044a7:	e8 0d fc ff ff       	call   801040b9 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044ac:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044b3:	e8 e4 fb ff ff       	call   8010409c <inb>
801044b8:	83 c8 01             	or     $0x1,%eax
801044bb:	0f b6 c0             	movzbl %al,%eax
801044be:	89 44 24 04          	mov    %eax,0x4(%esp)
801044c2:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044c9:	e8 eb fb ff ff       	call   801040b9 <outb>
  }
}
801044ce:	c9                   	leave  
801044cf:	c3                   	ret    

801044d0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044d0:	55                   	push   %ebp
801044d1:	89 e5                	mov    %esp,%ebp
801044d3:	83 ec 08             	sub    $0x8,%esp
801044d6:	8b 55 08             	mov    0x8(%ebp),%edx
801044d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801044dc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044e0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044e3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801044e7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801044eb:	ee                   	out    %al,(%dx)
}
801044ec:	c9                   	leave  
801044ed:	c3                   	ret    

801044ee <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801044ee:	55                   	push   %ebp
801044ef:	89 e5                	mov    %esp,%ebp
801044f1:	83 ec 0c             	sub    $0xc,%esp
801044f4:	8b 45 08             	mov    0x8(%ebp),%eax
801044f7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801044fb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801044ff:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
80104505:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104509:	0f b6 c0             	movzbl %al,%eax
8010450c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104510:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104517:	e8 b4 ff ff ff       	call   801044d0 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010451c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104520:	66 c1 e8 08          	shr    $0x8,%ax
80104524:	0f b6 c0             	movzbl %al,%eax
80104527:	89 44 24 04          	mov    %eax,0x4(%esp)
8010452b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104532:	e8 99 ff ff ff       	call   801044d0 <outb>
}
80104537:	c9                   	leave  
80104538:	c3                   	ret    

80104539 <picenable>:

void
picenable(int irq)
{
80104539:	55                   	push   %ebp
8010453a:	89 e5                	mov    %esp,%ebp
8010453c:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
8010453f:	8b 45 08             	mov    0x8(%ebp),%eax
80104542:	ba 01 00 00 00       	mov    $0x1,%edx
80104547:	89 c1                	mov    %eax,%ecx
80104549:	d3 e2                	shl    %cl,%edx
8010454b:	89 d0                	mov    %edx,%eax
8010454d:	f7 d0                	not    %eax
8010454f:	89 c2                	mov    %eax,%edx
80104551:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104558:	21 d0                	and    %edx,%eax
8010455a:	0f b7 c0             	movzwl %ax,%eax
8010455d:	89 04 24             	mov    %eax,(%esp)
80104560:	e8 89 ff ff ff       	call   801044ee <picsetmask>
}
80104565:	c9                   	leave  
80104566:	c3                   	ret    

80104567 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104567:	55                   	push   %ebp
80104568:	89 e5                	mov    %esp,%ebp
8010456a:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
8010456d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104574:	00 
80104575:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010457c:	e8 4f ff ff ff       	call   801044d0 <outb>
  outb(IO_PIC2+1, 0xFF);
80104581:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104588:	00 
80104589:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104590:	e8 3b ff ff ff       	call   801044d0 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104595:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010459c:	00 
8010459d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045a4:	e8 27 ff ff ff       	call   801044d0 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045a9:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045b0:	00 
801045b1:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045b8:	e8 13 ff ff ff       	call   801044d0 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045bd:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045c4:	00 
801045c5:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045cc:	e8 ff fe ff ff       	call   801044d0 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045d1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045d8:	00 
801045d9:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045e0:	e8 eb fe ff ff       	call   801044d0 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801045e5:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045ec:	00 
801045ed:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801045f4:	e8 d7 fe ff ff       	call   801044d0 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801045f9:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104600:	00 
80104601:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104608:	e8 c3 fe ff ff       	call   801044d0 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
8010460d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104614:	00 
80104615:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010461c:	e8 af fe ff ff       	call   801044d0 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104621:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104628:	00 
80104629:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104630:	e8 9b fe ff ff       	call   801044d0 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104635:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010463c:	00 
8010463d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104644:	e8 87 fe ff ff       	call   801044d0 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104649:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104650:	00 
80104651:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104658:	e8 73 fe ff ff       	call   801044d0 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
8010465d:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104664:	00 
80104665:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010466c:	e8 5f fe ff ff       	call   801044d0 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104671:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104678:	00 
80104679:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104680:	e8 4b fe ff ff       	call   801044d0 <outb>

  if(irqmask != 0xFFFF)
80104685:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
8010468c:	66 83 f8 ff          	cmp    $0xffff,%ax
80104690:	74 12                	je     801046a4 <picinit+0x13d>
    picsetmask(irqmask);
80104692:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104699:	0f b7 c0             	movzwl %ax,%eax
8010469c:	89 04 24             	mov    %eax,(%esp)
8010469f:	e8 4a fe ff ff       	call   801044ee <picsetmask>
}
801046a4:	c9                   	leave  
801046a5:	c3                   	ret    

801046a6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801046a6:	55                   	push   %ebp
801046a7:	89 e5                	mov    %esp,%ebp
801046a9:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801046b6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801046bf:	8b 10                	mov    (%eax),%edx
801046c1:	8b 45 08             	mov    0x8(%ebp),%eax
801046c4:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046c6:	e8 bc c9 ff ff       	call   80101087 <filealloc>
801046cb:	8b 55 08             	mov    0x8(%ebp),%edx
801046ce:	89 02                	mov    %eax,(%edx)
801046d0:	8b 45 08             	mov    0x8(%ebp),%eax
801046d3:	8b 00                	mov    (%eax),%eax
801046d5:	85 c0                	test   %eax,%eax
801046d7:	0f 84 c8 00 00 00    	je     801047a5 <pipealloc+0xff>
801046dd:	e8 a5 c9 ff ff       	call   80101087 <filealloc>
801046e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801046e5:	89 02                	mov    %eax,(%edx)
801046e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801046ea:	8b 00                	mov    (%eax),%eax
801046ec:	85 c0                	test   %eax,%eax
801046ee:	0f 84 b1 00 00 00    	je     801047a5 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801046f4:	e8 37 eb ff ff       	call   80103230 <kalloc>
801046f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046fc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104700:	75 05                	jne    80104707 <pipealloc+0x61>
    goto bad;
80104702:	e9 9e 00 00 00       	jmp    801047a5 <pipealloc+0xff>
  p->readopen = 1;
80104707:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010470a:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104711:	00 00 00 
  p->writeopen = 1;
80104714:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104717:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010471e:	00 00 00 
  p->nwrite = 0;
80104721:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104724:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010472b:	00 00 00 
  p->nread = 0;
8010472e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104731:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104738:	00 00 00 
  initlock(&p->lock, "pipe");
8010473b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010473e:	c7 44 24 04 7c 9e 10 	movl   $0x80109e7c,0x4(%esp)
80104745:	80 
80104746:	89 04 24             	mov    %eax,(%esp)
80104749:	e8 71 10 00 00       	call   801057bf <initlock>
  (*f0)->type = FD_PIPE;
8010474e:	8b 45 08             	mov    0x8(%ebp),%eax
80104751:	8b 00                	mov    (%eax),%eax
80104753:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104759:	8b 45 08             	mov    0x8(%ebp),%eax
8010475c:	8b 00                	mov    (%eax),%eax
8010475e:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104762:	8b 45 08             	mov    0x8(%ebp),%eax
80104765:	8b 00                	mov    (%eax),%eax
80104767:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010476b:	8b 45 08             	mov    0x8(%ebp),%eax
8010476e:	8b 00                	mov    (%eax),%eax
80104770:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104773:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104776:	8b 45 0c             	mov    0xc(%ebp),%eax
80104779:	8b 00                	mov    (%eax),%eax
8010477b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104781:	8b 45 0c             	mov    0xc(%ebp),%eax
80104784:	8b 00                	mov    (%eax),%eax
80104786:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010478a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010478d:	8b 00                	mov    (%eax),%eax
8010478f:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104793:	8b 45 0c             	mov    0xc(%ebp),%eax
80104796:	8b 00                	mov    (%eax),%eax
80104798:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010479b:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010479e:	b8 00 00 00 00       	mov    $0x0,%eax
801047a3:	eb 42                	jmp    801047e7 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801047a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047a9:	74 0b                	je     801047b6 <pipealloc+0x110>
    kfree((char*)p);
801047ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ae:	89 04 24             	mov    %eax,(%esp)
801047b1:	e8 b8 e9 ff ff       	call   8010316e <kfree>
  if(*f0)
801047b6:	8b 45 08             	mov    0x8(%ebp),%eax
801047b9:	8b 00                	mov    (%eax),%eax
801047bb:	85 c0                	test   %eax,%eax
801047bd:	74 0d                	je     801047cc <pipealloc+0x126>
    fileclose(*f0);
801047bf:	8b 45 08             	mov    0x8(%ebp),%eax
801047c2:	8b 00                	mov    (%eax),%eax
801047c4:	89 04 24             	mov    %eax,(%esp)
801047c7:	e8 63 c9 ff ff       	call   8010112f <fileclose>
  if(*f1)
801047cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801047cf:	8b 00                	mov    (%eax),%eax
801047d1:	85 c0                	test   %eax,%eax
801047d3:	74 0d                	je     801047e2 <pipealloc+0x13c>
    fileclose(*f1);
801047d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801047d8:	8b 00                	mov    (%eax),%eax
801047da:	89 04 24             	mov    %eax,(%esp)
801047dd:	e8 4d c9 ff ff       	call   8010112f <fileclose>
  return -1;
801047e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801047e7:	c9                   	leave  
801047e8:	c3                   	ret    

801047e9 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801047e9:	55                   	push   %ebp
801047ea:	89 e5                	mov    %esp,%ebp
801047ec:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801047ef:	8b 45 08             	mov    0x8(%ebp),%eax
801047f2:	89 04 24             	mov    %eax,(%esp)
801047f5:	e8 e6 0f 00 00       	call   801057e0 <acquire>
  if(writable){
801047fa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801047fe:	74 1f                	je     8010481f <pipeclose+0x36>
    p->writeopen = 0;
80104800:	8b 45 08             	mov    0x8(%ebp),%eax
80104803:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010480a:	00 00 00 
    wakeup(&p->nread);
8010480d:	8b 45 08             	mov    0x8(%ebp),%eax
80104810:	05 34 02 00 00       	add    $0x234,%eax
80104815:	89 04 24             	mov    %eax,(%esp)
80104818:	e8 57 0d 00 00       	call   80105574 <wakeup>
8010481d:	eb 1d                	jmp    8010483c <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010481f:	8b 45 08             	mov    0x8(%ebp),%eax
80104822:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104829:	00 00 00 
    wakeup(&p->nwrite);
8010482c:	8b 45 08             	mov    0x8(%ebp),%eax
8010482f:	05 38 02 00 00       	add    $0x238,%eax
80104834:	89 04 24             	mov    %eax,(%esp)
80104837:	e8 38 0d 00 00       	call   80105574 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010483c:	8b 45 08             	mov    0x8(%ebp),%eax
8010483f:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104845:	85 c0                	test   %eax,%eax
80104847:	75 25                	jne    8010486e <pipeclose+0x85>
80104849:	8b 45 08             	mov    0x8(%ebp),%eax
8010484c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104852:	85 c0                	test   %eax,%eax
80104854:	75 18                	jne    8010486e <pipeclose+0x85>
    release(&p->lock);
80104856:	8b 45 08             	mov    0x8(%ebp),%eax
80104859:	89 04 24             	mov    %eax,(%esp)
8010485c:	e8 e1 0f 00 00       	call   80105842 <release>
    kfree((char*)p);
80104861:	8b 45 08             	mov    0x8(%ebp),%eax
80104864:	89 04 24             	mov    %eax,(%esp)
80104867:	e8 02 e9 ff ff       	call   8010316e <kfree>
8010486c:	eb 0b                	jmp    80104879 <pipeclose+0x90>
  } else
    release(&p->lock);
8010486e:	8b 45 08             	mov    0x8(%ebp),%eax
80104871:	89 04 24             	mov    %eax,(%esp)
80104874:	e8 c9 0f 00 00       	call   80105842 <release>
}
80104879:	c9                   	leave  
8010487a:	c3                   	ret    

8010487b <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010487b:	55                   	push   %ebp
8010487c:	89 e5                	mov    %esp,%ebp
8010487e:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104881:	8b 45 08             	mov    0x8(%ebp),%eax
80104884:	89 04 24             	mov    %eax,(%esp)
80104887:	e8 54 0f 00 00       	call   801057e0 <acquire>
  for(i = 0; i < n; i++){
8010488c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104893:	e9 a6 00 00 00       	jmp    8010493e <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104898:	eb 57                	jmp    801048f1 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
8010489a:	8b 45 08             	mov    0x8(%ebp),%eax
8010489d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048a3:	85 c0                	test   %eax,%eax
801048a5:	74 0d                	je     801048b4 <pipewrite+0x39>
801048a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ad:	8b 40 24             	mov    0x24(%eax),%eax
801048b0:	85 c0                	test   %eax,%eax
801048b2:	74 15                	je     801048c9 <pipewrite+0x4e>
        release(&p->lock);
801048b4:	8b 45 08             	mov    0x8(%ebp),%eax
801048b7:	89 04 24             	mov    %eax,(%esp)
801048ba:	e8 83 0f 00 00       	call   80105842 <release>
        return -1;
801048bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048c4:	e9 9f 00 00 00       	jmp    80104968 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048c9:	8b 45 08             	mov    0x8(%ebp),%eax
801048cc:	05 34 02 00 00       	add    $0x234,%eax
801048d1:	89 04 24             	mov    %eax,(%esp)
801048d4:	e8 9b 0c 00 00       	call   80105574 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048d9:	8b 45 08             	mov    0x8(%ebp),%eax
801048dc:	8b 55 08             	mov    0x8(%ebp),%edx
801048df:	81 c2 38 02 00 00    	add    $0x238,%edx
801048e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801048e9:	89 14 24             	mov    %edx,(%esp)
801048ec:	e8 a7 0b 00 00       	call   80105498 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048f1:	8b 45 08             	mov    0x8(%ebp),%eax
801048f4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801048fa:	8b 45 08             	mov    0x8(%ebp),%eax
801048fd:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104903:	05 00 02 00 00       	add    $0x200,%eax
80104908:	39 c2                	cmp    %eax,%edx
8010490a:	74 8e                	je     8010489a <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010490c:	8b 45 08             	mov    0x8(%ebp),%eax
8010490f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104915:	8d 48 01             	lea    0x1(%eax),%ecx
80104918:	8b 55 08             	mov    0x8(%ebp),%edx
8010491b:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104921:	25 ff 01 00 00       	and    $0x1ff,%eax
80104926:	89 c1                	mov    %eax,%ecx
80104928:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010492b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010492e:	01 d0                	add    %edx,%eax
80104930:	0f b6 10             	movzbl (%eax),%edx
80104933:	8b 45 08             	mov    0x8(%ebp),%eax
80104936:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010493a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010493e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104941:	3b 45 10             	cmp    0x10(%ebp),%eax
80104944:	0f 8c 4e ff ff ff    	jl     80104898 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010494a:	8b 45 08             	mov    0x8(%ebp),%eax
8010494d:	05 34 02 00 00       	add    $0x234,%eax
80104952:	89 04 24             	mov    %eax,(%esp)
80104955:	e8 1a 0c 00 00       	call   80105574 <wakeup>
  release(&p->lock);
8010495a:	8b 45 08             	mov    0x8(%ebp),%eax
8010495d:	89 04 24             	mov    %eax,(%esp)
80104960:	e8 dd 0e 00 00       	call   80105842 <release>
  return n;
80104965:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104968:	c9                   	leave  
80104969:	c3                   	ret    

8010496a <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010496a:	55                   	push   %ebp
8010496b:	89 e5                	mov    %esp,%ebp
8010496d:	53                   	push   %ebx
8010496e:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104971:	8b 45 08             	mov    0x8(%ebp),%eax
80104974:	89 04 24             	mov    %eax,(%esp)
80104977:	e8 64 0e 00 00       	call   801057e0 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010497c:	eb 3a                	jmp    801049b8 <piperead+0x4e>
    if(proc->killed){
8010497e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104984:	8b 40 24             	mov    0x24(%eax),%eax
80104987:	85 c0                	test   %eax,%eax
80104989:	74 15                	je     801049a0 <piperead+0x36>
      release(&p->lock);
8010498b:	8b 45 08             	mov    0x8(%ebp),%eax
8010498e:	89 04 24             	mov    %eax,(%esp)
80104991:	e8 ac 0e 00 00       	call   80105842 <release>
      return -1;
80104996:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010499b:	e9 b5 00 00 00       	jmp    80104a55 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801049a0:	8b 45 08             	mov    0x8(%ebp),%eax
801049a3:	8b 55 08             	mov    0x8(%ebp),%edx
801049a6:	81 c2 34 02 00 00    	add    $0x234,%edx
801049ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801049b0:	89 14 24             	mov    %edx,(%esp)
801049b3:	e8 e0 0a 00 00       	call   80105498 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049b8:	8b 45 08             	mov    0x8(%ebp),%eax
801049bb:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049c1:	8b 45 08             	mov    0x8(%ebp),%eax
801049c4:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049ca:	39 c2                	cmp    %eax,%edx
801049cc:	75 0d                	jne    801049db <piperead+0x71>
801049ce:	8b 45 08             	mov    0x8(%ebp),%eax
801049d1:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049d7:	85 c0                	test   %eax,%eax
801049d9:	75 a3                	jne    8010497e <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049e2:	eb 4b                	jmp    80104a2f <piperead+0xc5>
    if(p->nread == p->nwrite)
801049e4:	8b 45 08             	mov    0x8(%ebp),%eax
801049e7:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049ed:	8b 45 08             	mov    0x8(%ebp),%eax
801049f0:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049f6:	39 c2                	cmp    %eax,%edx
801049f8:	75 02                	jne    801049fc <piperead+0x92>
      break;
801049fa:	eb 3b                	jmp    80104a37 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801049fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a02:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104a05:	8b 45 08             	mov    0x8(%ebp),%eax
80104a08:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a0e:	8d 48 01             	lea    0x1(%eax),%ecx
80104a11:	8b 55 08             	mov    0x8(%ebp),%edx
80104a14:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a1a:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a1f:	89 c2                	mov    %eax,%edx
80104a21:	8b 45 08             	mov    0x8(%ebp),%eax
80104a24:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a29:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a2b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a32:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a35:	7c ad                	jl     801049e4 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a37:	8b 45 08             	mov    0x8(%ebp),%eax
80104a3a:	05 38 02 00 00       	add    $0x238,%eax
80104a3f:	89 04 24             	mov    %eax,(%esp)
80104a42:	e8 2d 0b 00 00       	call   80105574 <wakeup>
  release(&p->lock);
80104a47:	8b 45 08             	mov    0x8(%ebp),%eax
80104a4a:	89 04 24             	mov    %eax,(%esp)
80104a4d:	e8 f0 0d 00 00       	call   80105842 <release>
  return i;
80104a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a55:	83 c4 24             	add    $0x24,%esp
80104a58:	5b                   	pop    %ebx
80104a59:	5d                   	pop    %ebp
80104a5a:	c3                   	ret    

80104a5b <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a5b:	55                   	push   %ebp
80104a5c:	89 e5                	mov    %esp,%ebp
80104a5e:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a61:	9c                   	pushf  
80104a62:	58                   	pop    %eax
80104a63:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a66:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a69:	c9                   	leave  
80104a6a:	c3                   	ret    

80104a6b <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a6b:	55                   	push   %ebp
80104a6c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a6e:	fb                   	sti    
}
80104a6f:	5d                   	pop    %ebp
80104a70:	c3                   	ret    

80104a71 <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a71:	55                   	push   %ebp
80104a72:	89 e5                	mov    %esp,%ebp
80104a74:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a77:	c7 44 24 04 81 9e 10 	movl   $0x80109e81,0x4(%esp)
80104a7e:	80 
80104a7f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a86:	e8 34 0d 00 00       	call   801057bf <initlock>
}
80104a8b:	c9                   	leave  
80104a8c:	c3                   	ret    

80104a8d <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104a8d:	55                   	push   %ebp
80104a8e:	89 e5                	mov    %esp,%ebp
80104a90:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104a93:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a9a:	e8 41 0d 00 00       	call   801057e0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a9f:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104aa6:	eb 53                	jmp    80104afb <allocproc+0x6e>
    if(p->state == UNUSED)
80104aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aab:	8b 40 0c             	mov    0xc(%eax),%eax
80104aae:	85 c0                	test   %eax,%eax
80104ab0:	75 42                	jne    80104af4 <allocproc+0x67>
      goto found;
80104ab2:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104ab3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab6:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104abd:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104ac2:	8d 50 01             	lea    0x1(%eax),%edx
80104ac5:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104acb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ace:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104ad1:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104ad8:	e8 65 0d 00 00       	call   80105842 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104add:	e8 4e e7 ff ff       	call   80103230 <kalloc>
80104ae2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ae5:	89 42 08             	mov    %eax,0x8(%edx)
80104ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aeb:	8b 40 08             	mov    0x8(%eax),%eax
80104aee:	85 c0                	test   %eax,%eax
80104af0:	75 36                	jne    80104b28 <allocproc+0x9b>
80104af2:	eb 23                	jmp    80104b17 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104af4:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
80104afb:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
80104b02:	72 a4                	jb     80104aa8 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104b04:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b0b:	e8 32 0d 00 00       	call   80105842 <release>
    return 0;
80104b10:	b8 00 00 00 00       	mov    $0x0,%eax
80104b15:	eb 76                	jmp    80104b8d <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b1a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b21:	b8 00 00 00 00       	mov    $0x0,%eax
80104b26:	eb 65                	jmp    80104b8d <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2b:	8b 40 08             	mov    0x8(%eax),%eax
80104b2e:	05 00 10 00 00       	add    $0x1000,%eax
80104b33:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b36:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b3d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b40:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b43:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b47:	ba 48 6e 10 80       	mov    $0x80106e48,%edx
80104b4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b4f:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b51:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b58:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b5b:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b61:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b64:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b6b:	00 
80104b6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b73:	00 
80104b74:	89 04 24             	mov    %eax,(%esp)
80104b77:	e8 b8 0e 00 00       	call   80105a34 <memset>
    p->context->eip = (uint)forkret;
80104b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b82:	ba 59 54 10 80       	mov    $0x80105459,%edx
80104b87:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104b8d:	c9                   	leave  
80104b8e:	c3                   	ret    

80104b8f <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104b8f:	55                   	push   %ebp
80104b90:	89 e5                	mov    %esp,%ebp
80104b92:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104b95:	e8 f3 fe ff ff       	call   80104a8d <allocproc>
80104b9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba0:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104ba7:	00 00 00 
    p->swapedPagesCounter = 0;
80104baa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bad:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104bb4:	00 00 00 
    p->pageFaultCounter = 0;
80104bb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bba:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bc1:	00 00 00 
    p->swappedOutCounter = 0;
80104bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc7:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104bce:	00 00 00 
    p->numOfPages = 0;
80104bd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd4:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104bdb:	00 00 00 
    p->copyingSwapFile = 0;
80104bde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be1:	c7 80 ec 02 00 00 00 	movl   $0x0,0x2ec(%eax)
80104be8:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104beb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104bf2:	e9 92 00 00 00       	jmp    80104c89 <userinit+0xfa>
   	  p->pagesMetaData[i].count = 0;
80104bf7:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104bfa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bfd:	89 d0                	mov    %edx,%eax
80104bff:	c1 e0 02             	shl    $0x2,%eax
80104c02:	01 d0                	add    %edx,%eax
80104c04:	c1 e0 02             	shl    $0x2,%eax
80104c07:	01 c8                	add    %ecx,%eax
80104c09:	05 9c 00 00 00       	add    $0x9c,%eax
80104c0e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104c14:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c1a:	89 d0                	mov    %edx,%eax
80104c1c:	c1 e0 02             	shl    $0x2,%eax
80104c1f:	01 d0                	add    %edx,%eax
80104c21:	c1 e0 02             	shl    $0x2,%eax
80104c24:	01 c8                	add    %ecx,%eax
80104c26:	05 90 00 00 00       	add    $0x90,%eax
80104c2b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c31:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c34:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c37:	89 d0                	mov    %edx,%eax
80104c39:	c1 e0 02             	shl    $0x2,%eax
80104c3c:	01 d0                	add    %edx,%eax
80104c3e:	c1 e0 02             	shl    $0x2,%eax
80104c41:	01 c8                	add    %ecx,%eax
80104c43:	05 94 00 00 00       	add    $0x94,%eax
80104c48:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c4e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c54:	89 d0                	mov    %edx,%eax
80104c56:	c1 e0 02             	shl    $0x2,%eax
80104c59:	01 d0                	add    %edx,%eax
80104c5b:	c1 e0 02             	shl    $0x2,%eax
80104c5e:	01 c8                	add    %ecx,%eax
80104c60:	05 98 00 00 00       	add    $0x98,%eax
80104c65:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c6b:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c71:	89 d0                	mov    %edx,%eax
80104c73:	c1 e0 02             	shl    $0x2,%eax
80104c76:	01 d0                	add    %edx,%eax
80104c78:	c1 e0 02             	shl    $0x2,%eax
80104c7b:	01 c8                	add    %ecx,%eax
80104c7d:	05 a0 00 00 00       	add    $0xa0,%eax
80104c82:	c6 00 80             	movb   $0x80,(%eax)
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    p->copyingSwapFile = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c85:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c89:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104c8d:	0f 8e 64 ff ff ff    	jle    80104bf7 <userinit+0x68>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104c93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c96:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104c9b:	e8 42 39 00 00       	call   801085e2 <setupkvm>
80104ca0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ca3:	89 42 04             	mov    %eax,0x4(%edx)
80104ca6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ca9:	8b 40 04             	mov    0x4(%eax),%eax
80104cac:	85 c0                	test   %eax,%eax
80104cae:	75 0c                	jne    80104cbc <userinit+0x12d>
      panic("userinit: out of memory?");
80104cb0:	c7 04 24 88 9e 10 80 	movl   $0x80109e88,(%esp)
80104cb7:	e8 7e b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104cbc:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104cc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cc4:	8b 40 04             	mov    0x4(%eax),%eax
80104cc7:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ccb:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104cd2:	80 
80104cd3:	89 04 24             	mov    %eax,(%esp)
80104cd6:	e8 5f 3b 00 00       	call   8010883a <inituvm>
    p->sz = PGSIZE;
80104cdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cde:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104ce4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce7:	8b 40 18             	mov    0x18(%eax),%eax
80104cea:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104cf1:	00 
80104cf2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cf9:	00 
80104cfa:	89 04 24             	mov    %eax,(%esp)
80104cfd:	e8 32 0d 00 00       	call   80105a34 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d05:	8b 40 18             	mov    0x18(%eax),%eax
80104d08:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d11:	8b 40 18             	mov    0x18(%eax),%eax
80104d14:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104d1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d1d:	8b 40 18             	mov    0x18(%eax),%eax
80104d20:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d23:	8b 52 18             	mov    0x18(%edx),%edx
80104d26:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d2a:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d31:	8b 40 18             	mov    0x18(%eax),%eax
80104d34:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d37:	8b 52 18             	mov    0x18(%edx),%edx
80104d3a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d3e:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d45:	8b 40 18             	mov    0x18(%eax),%eax
80104d48:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d52:	8b 40 18             	mov    0x18(%eax),%eax
80104d55:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d5f:	8b 40 18             	mov    0x18(%eax),%eax
80104d62:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6c:	83 c0 6c             	add    $0x6c,%eax
80104d6f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d76:	00 
80104d77:	c7 44 24 04 a1 9e 10 	movl   $0x80109ea1,0x4(%esp)
80104d7e:	80 
80104d7f:	89 04 24             	mov    %eax,(%esp)
80104d82:	e8 cd 0e 00 00       	call   80105c54 <safestrcpy>
  p->cwd = namei("/");
80104d87:	c7 04 24 aa 9e 10 80 	movl   $0x80109eaa,(%esp)
80104d8e:	e8 38 d8 ff ff       	call   801025cb <namei>
80104d93:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d96:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104d99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d9c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104da3:	e8 d5 e4 ff ff       	call   8010327d <countPages>
80104da8:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104dad:	a1 60 49 11 80       	mov    0x80114960,%eax
80104db2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104db6:	c7 04 24 ac 9e 10 80 	movl   $0x80109eac,(%esp)
80104dbd:	e8 de b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104dc2:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104dc9:	00 00 00 
}
80104dcc:	c9                   	leave  
80104dcd:	c3                   	ret    

80104dce <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104dce:	55                   	push   %ebp
80104dcf:	89 e5                	mov    %esp,%ebp
80104dd1:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104dd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dda:	8b 00                	mov    (%eax),%eax
80104ddc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104ddf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104de3:	7e 3f                	jle    80104e24 <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104de5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dec:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104def:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df2:	01 c1                	add    %eax,%ecx
80104df4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dfa:	8b 40 04             	mov    0x4(%eax),%eax
80104dfd:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e01:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e05:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e08:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e0c:	89 04 24             	mov    %eax,(%esp)
80104e0f:	e8 9c 3b 00 00       	call   801089b0 <allocuvm>
80104e14:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e1b:	75 4c                	jne    80104e69 <growproc+0x9b>
      return -1;
80104e1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e22:	eb 63                	jmp    80104e87 <growproc+0xb9>
  } else if(n < 0){
80104e24:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e28:	79 3f                	jns    80104e69 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e2a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e31:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e37:	01 c1                	add    %eax,%ecx
80104e39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e3f:	8b 40 04             	mov    0x4(%eax),%eax
80104e42:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e46:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e4a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e4d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e51:	89 04 24             	mov    %eax,(%esp)
80104e54:	e8 a2 3d 00 00       	call   80108bfb <deallocuvm>
80104e59:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e5c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e60:	75 07                	jne    80104e69 <growproc+0x9b>
      return -1;
80104e62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e67:	eb 1e                	jmp    80104e87 <growproc+0xb9>
  }
  proc->sz = sz;
80104e69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e72:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7a:	89 04 24             	mov    %eax,(%esp)
80104e7d:	e8 51 38 00 00       	call   801086d3 <switchuvm>
  return 0;
80104e82:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e87:	c9                   	leave  
80104e88:	c3                   	ret    

80104e89 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e89:	55                   	push   %ebp
80104e8a:	89 e5                	mov    %esp,%ebp
80104e8c:	57                   	push   %edi
80104e8d:	56                   	push   %esi
80104e8e:	53                   	push   %ebx
80104e8f:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e92:	e8 f6 fb ff ff       	call   80104a8d <allocproc>
80104e97:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104e9a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104e9e:	75 0a                	jne    80104eaa <fork+0x21>
    return -1;
80104ea0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ea5:	e9 d7 01 00 00       	jmp    80105081 <fork+0x1f8>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104eaa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb0:	8b 10                	mov    (%eax),%edx
80104eb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb8:	8b 40 04             	mov    0x4(%eax),%eax
80104ebb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104ebe:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ec2:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ec6:	89 04 24             	mov    %eax,(%esp)
80104ec9:	e8 1b 40 00 00       	call   80108ee9 <copyuvm>
80104ece:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ed1:	89 42 04             	mov    %eax,0x4(%edx)
80104ed4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ed7:	8b 40 04             	mov    0x4(%eax),%eax
80104eda:	85 c0                	test   %eax,%eax
80104edc:	75 2c                	jne    80104f0a <fork+0x81>
    kfree(np->kstack);
80104ede:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ee1:	8b 40 08             	mov    0x8(%eax),%eax
80104ee4:	89 04 24             	mov    %eax,(%esp)
80104ee7:	e8 82 e2 ff ff       	call   8010316e <kfree>
    np->kstack = 0;
80104eec:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eef:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104ef6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104f00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f05:	e9 77 01 00 00       	jmp    80105081 <fork+0x1f8>
  }
  np->sz = proc->sz;
80104f0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f10:	8b 10                	mov    (%eax),%edx
80104f12:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f15:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f17:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f21:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f24:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f27:	8b 50 18             	mov    0x18(%eax),%edx
80104f2a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f30:	8b 40 18             	mov    0x18(%eax),%eax
80104f33:	89 c3                	mov    %eax,%ebx
80104f35:	b8 13 00 00 00       	mov    $0x13,%eax
80104f3a:	89 d7                	mov    %edx,%edi
80104f3c:	89 de                	mov    %ebx,%esi
80104f3e:	89 c1                	mov    %eax,%ecx
80104f40:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f42:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f45:	8b 40 18             	mov    0x18(%eax),%eax
80104f48:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f4f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f56:	eb 3d                	jmp    80104f95 <fork+0x10c>
    if(proc->ofile[i])
80104f58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f61:	83 c2 08             	add    $0x8,%edx
80104f64:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f68:	85 c0                	test   %eax,%eax
80104f6a:	74 25                	je     80104f91 <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f72:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f75:	83 c2 08             	add    $0x8,%edx
80104f78:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f7c:	89 04 24             	mov    %eax,(%esp)
80104f7f:	e8 63 c1 ff ff       	call   801010e7 <filedup>
80104f84:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f87:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f8a:	83 c1 08             	add    $0x8,%ecx
80104f8d:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f91:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f95:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f99:	7e bd                	jle    80104f58 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104f9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fa1:	8b 40 68             	mov    0x68(%eax),%eax
80104fa4:	89 04 24             	mov    %eax,(%esp)
80104fa7:	e8 3c ca ff ff       	call   801019e8 <idup>
80104fac:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104faf:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104fb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fb8:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fbe:	83 c0 6c             	add    $0x6c,%eax
80104fc1:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fc8:	00 
80104fc9:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fcd:	89 04 24             	mov    %eax,(%esp)
80104fd0:	e8 7f 0c 00 00       	call   80105c54 <safestrcpy>

    pid = np->pid;
80104fd5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd8:	8b 40 10             	mov    0x10(%eax),%eax
80104fdb:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->memoryPagesCounter = proc->memoryPagesCounter;
80104fde:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fe4:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104fea:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fed:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    np->swapedPagesCounter = proc->swapedPagesCounter;
80104ff3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ff9:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80104fff:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105002:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
    np->pageFaultCounter = 0;
80105008:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010500b:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80105012:	00 00 00 
    np->swappedOutCounter = 0;
80105015:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105018:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
8010501f:	00 00 00 
    np->copyingSwapFile = 0;
80105022:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105025:	c7 80 ec 02 00 00 00 	movl   $0x0,0x2ec(%eax)
8010502c:	00 00 00 
    createSwapFile(np);
8010502f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105032:	89 04 24             	mov    %eax,(%esp)
80105035:	e8 a2 d8 ff ff       	call   801028dc <createSwapFile>
    if(proc->swapFile)
8010503a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105040:	8b 40 7c             	mov    0x7c(%eax),%eax
80105043:	85 c0                	test   %eax,%eax
80105045:	74 15                	je     8010505c <fork+0x1d3>
      copySwapFile(proc,np);
80105047:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010504d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105050:	89 54 24 04          	mov    %edx,0x4(%esp)
80105054:	89 04 24             	mov    %eax,(%esp)
80105057:	e8 b5 d9 ff ff       	call   80102a11 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
8010505c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105063:	e8 78 07 00 00       	call   801057e0 <acquire>
    np->state = RUNNABLE;
80105068:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010506b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
80105072:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105079:	e8 c4 07 00 00       	call   80105842 <release>

    return pid;
8010507e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
80105081:	83 c4 2c             	add    $0x2c,%esp
80105084:	5b                   	pop    %ebx
80105085:	5e                   	pop    %esi
80105086:	5f                   	pop    %edi
80105087:	5d                   	pop    %ebp
80105088:	c3                   	ret    

80105089 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105089:	55                   	push   %ebp
8010508a:	89 e5                	mov    %esp,%ebp
8010508c:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int fd;
    if(VERBOSE_PRINT == 1)
      procdump();
8010508f:	e8 86 05 00 00       	call   8010561a <procdump>
    if(proc == initproc)
80105094:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010509b:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
801050a0:	39 c2                	cmp    %eax,%edx
801050a2:	75 0c                	jne    801050b0 <exit+0x27>
      panic("init exiting");
801050a4:	c7 04 24 ca 9e 10 80 	movl   $0x80109eca,(%esp)
801050ab:	e8 8a b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050b0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801050b7:	eb 44                	jmp    801050fd <exit+0x74>
      if(proc->ofile[fd]){
801050b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050bf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050c2:	83 c2 08             	add    $0x8,%edx
801050c5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050c9:	85 c0                	test   %eax,%eax
801050cb:	74 2c                	je     801050f9 <exit+0x70>
        fileclose(proc->ofile[fd]);
801050cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050d3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050d6:	83 c2 08             	add    $0x8,%edx
801050d9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050dd:	89 04 24             	mov    %eax,(%esp)
801050e0:	e8 4a c0 ff ff       	call   8010112f <fileclose>
        proc->ofile[fd] = 0;
801050e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050eb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050ee:	83 c2 08             	add    $0x8,%edx
801050f1:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801050f8:	00 
      procdump();
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050f9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050fd:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105101:	7e b6                	jle    801050b9 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
80105103:	e8 92 ea ff ff       	call   80103b9a <begin_op>
    iput(proc->cwd);
80105108:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010510e:	8b 40 68             	mov    0x68(%eax),%eax
80105111:	89 04 24             	mov    %eax,(%esp)
80105114:	e8 ba ca ff ff       	call   80101bd3 <iput>
    end_op();
80105119:	e8 00 eb ff ff       	call   80103c1e <end_op>
    proc->cwd = 0;
8010511e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105124:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
8010512b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105131:	89 04 24             	mov    %eax,(%esp)
80105134:	e8 97 d5 ff ff       	call   801026d0 <removeSwapFile>
    acquire(&ptable.lock);
80105139:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105140:	e8 9b 06 00 00       	call   801057e0 <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
80105145:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010514b:	8b 40 14             	mov    0x14(%eax),%eax
8010514e:	89 04 24             	mov    %eax,(%esp)
80105151:	e8 dd 03 00 00       	call   80105533 <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105156:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
8010515d:	eb 3b                	jmp    8010519a <exit+0x111>
      if(p->parent == proc){
8010515f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105162:	8b 50 14             	mov    0x14(%eax),%edx
80105165:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010516b:	39 c2                	cmp    %eax,%edx
8010516d:	75 24                	jne    80105193 <exit+0x10a>
        p->parent = initproc;
8010516f:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
80105175:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105178:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
8010517b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010517e:	8b 40 0c             	mov    0xc(%eax),%eax
80105181:	83 f8 05             	cmp    $0x5,%eax
80105184:	75 0d                	jne    80105193 <exit+0x10a>
          wakeup1(initproc);
80105186:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
8010518b:	89 04 24             	mov    %eax,(%esp)
8010518e:	e8 a0 03 00 00       	call   80105533 <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105193:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
8010519a:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
801051a1:	72 bc                	jb     8010515f <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
801051a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051a9:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
801051b0:	e8 c0 01 00 00       	call   80105375 <sched>
    panic("zombie exit");
801051b5:	c7 04 24 d7 9e 10 80 	movl   $0x80109ed7,(%esp)
801051bc:	e8 79 b3 ff ff       	call   8010053a <panic>

801051c1 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
801051c1:	55                   	push   %ebp
801051c2:	89 e5                	mov    %esp,%ebp
801051c4:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
801051c7:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801051ce:	e8 0d 06 00 00       	call   801057e0 <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
801051d3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051da:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801051e1:	e9 a4 00 00 00       	jmp    8010528a <wait+0xc9>
        if(p->parent != proc)
801051e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051e9:	8b 50 14             	mov    0x14(%eax),%edx
801051ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051f2:	39 c2                	cmp    %eax,%edx
801051f4:	74 05                	je     801051fb <wait+0x3a>
          continue;
801051f6:	e9 88 00 00 00       	jmp    80105283 <wait+0xc2>
        havekids = 1;
801051fb:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
80105202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105205:	8b 40 0c             	mov    0xc(%eax),%eax
80105208:	83 f8 05             	cmp    $0x5,%eax
8010520b:	75 76                	jne    80105283 <wait+0xc2>
        // Found one.
          pid = p->pid;
8010520d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105210:	8b 40 10             	mov    0x10(%eax),%eax
80105213:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
80105216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105219:	8b 40 08             	mov    0x8(%eax),%eax
8010521c:	89 04 24             	mov    %eax,(%esp)
8010521f:	e8 4a df ff ff       	call   8010316e <kfree>
          p->kstack = 0;
80105224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105227:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
8010522e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105231:	8b 40 04             	mov    0x4(%eax),%eax
80105234:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105237:	89 54 24 04          	mov    %edx,0x4(%esp)
8010523b:	89 04 24             	mov    %eax,(%esp)
8010523e:	e8 bc 3b 00 00       	call   80108dff <freevm>
          p->state = UNUSED;
80105243:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105246:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
8010524d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105250:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
80105257:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010525a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
80105261:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105264:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010526b:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
80105272:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105279:	e8 c4 05 00 00       	call   80105842 <release>
          return pid;
8010527e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105281:	eb 55                	jmp    801052d8 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105283:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
8010528a:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
80105291:	0f 82 4f ff ff ff    	jb     801051e6 <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
80105297:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010529b:	74 0d                	je     801052aa <wait+0xe9>
8010529d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052a3:	8b 40 24             	mov    0x24(%eax),%eax
801052a6:	85 c0                	test   %eax,%eax
801052a8:	74 13                	je     801052bd <wait+0xfc>
        release(&ptable.lock);
801052aa:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052b1:	e8 8c 05 00 00       	call   80105842 <release>
        return -1;
801052b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052bb:	eb 1b                	jmp    801052d8 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801052bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c3:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
801052ca:	80 
801052cb:	89 04 24             	mov    %eax,(%esp)
801052ce:	e8 c5 01 00 00       	call   80105498 <sleep>
  }
801052d3:	e9 fb fe ff ff       	jmp    801051d3 <wait+0x12>
}
801052d8:	c9                   	leave  
801052d9:	c3                   	ret    

801052da <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801052da:	55                   	push   %ebp
801052db:	89 e5                	mov    %esp,%ebp
801052dd:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801052e0:	e8 86 f7 ff ff       	call   80104a6b <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801052e5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052ec:	e8 ef 04 00 00       	call   801057e0 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052f1:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801052f8:	eb 61                	jmp    8010535b <scheduler+0x81>
      if(p->state != RUNNABLE)
801052fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052fd:	8b 40 0c             	mov    0xc(%eax),%eax
80105300:	83 f8 03             	cmp    $0x3,%eax
80105303:	74 02                	je     80105307 <scheduler+0x2d>
        continue;
80105305:	eb 4d                	jmp    80105354 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105307:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010530a:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105313:	89 04 24             	mov    %eax,(%esp)
80105316:	e8 b8 33 00 00       	call   801086d3 <switchuvm>
      p->state = RUNNING;
8010531b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010531e:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105325:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010532b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010532e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105335:	83 c2 04             	add    $0x4,%edx
80105338:	89 44 24 04          	mov    %eax,0x4(%esp)
8010533c:	89 14 24             	mov    %edx,(%esp)
8010533f:	e8 81 09 00 00       	call   80105cc5 <swtch>
      switchkvm();
80105344:	e8 6d 33 00 00       	call   801086b6 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105349:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105350:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105354:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
8010535b:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
80105362:	72 96                	jb     801052fa <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105364:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010536b:	e8 d2 04 00 00       	call   80105842 <release>

  }
80105370:	e9 6b ff ff ff       	jmp    801052e0 <scheduler+0x6>

80105375 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105375:	55                   	push   %ebp
80105376:	89 e5                	mov    %esp,%ebp
80105378:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010537b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105382:	e8 83 05 00 00       	call   8010590a <holding>
80105387:	85 c0                	test   %eax,%eax
80105389:	75 0c                	jne    80105397 <sched+0x22>
    panic("sched ptable.lock");
8010538b:	c7 04 24 e3 9e 10 80 	movl   $0x80109ee3,(%esp)
80105392:	e8 a3 b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105397:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010539d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801053a3:	83 f8 01             	cmp    $0x1,%eax
801053a6:	74 0c                	je     801053b4 <sched+0x3f>
    panic("sched locks");
801053a8:	c7 04 24 f5 9e 10 80 	movl   $0x80109ef5,(%esp)
801053af:	e8 86 b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
801053b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ba:	8b 40 0c             	mov    0xc(%eax),%eax
801053bd:	83 f8 04             	cmp    $0x4,%eax
801053c0:	75 0c                	jne    801053ce <sched+0x59>
    panic("sched running");
801053c2:	c7 04 24 01 9f 10 80 	movl   $0x80109f01,(%esp)
801053c9:	e8 6c b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
801053ce:	e8 88 f6 ff ff       	call   80104a5b <readeflags>
801053d3:	25 00 02 00 00       	and    $0x200,%eax
801053d8:	85 c0                	test   %eax,%eax
801053da:	74 0c                	je     801053e8 <sched+0x73>
    panic("sched interruptible");
801053dc:	c7 04 24 0f 9f 10 80 	movl   $0x80109f0f,(%esp)
801053e3:	e8 52 b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801053e8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053ee:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053f7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053fd:	8b 40 04             	mov    0x4(%eax),%eax
80105400:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105407:	83 c2 1c             	add    $0x1c,%edx
8010540a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010540e:	89 14 24             	mov    %edx,(%esp)
80105411:	e8 af 08 00 00       	call   80105cc5 <swtch>
  cpu->intena = intena;
80105416:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010541c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010541f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105425:	c9                   	leave  
80105426:	c3                   	ret    

80105427 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105427:	55                   	push   %ebp
80105428:	89 e5                	mov    %esp,%ebp
8010542a:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010542d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105434:	e8 a7 03 00 00       	call   801057e0 <acquire>
  proc->state = RUNNABLE;
80105439:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010543f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105446:	e8 2a ff ff ff       	call   80105375 <sched>
  release(&ptable.lock);
8010544b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105452:	e8 eb 03 00 00       	call   80105842 <release>
}
80105457:	c9                   	leave  
80105458:	c3                   	ret    

80105459 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105459:	55                   	push   %ebp
8010545a:	89 e5                	mov    %esp,%ebp
8010545c:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010545f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105466:	e8 d7 03 00 00       	call   80105842 <release>

  if (first) {
8010546b:	a1 08 d0 10 80       	mov    0x8010d008,%eax
80105470:	85 c0                	test   %eax,%eax
80105472:	74 22                	je     80105496 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105474:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
8010547b:	00 00 00 
    iinit(ROOTDEV);
8010547e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105485:	e8 68 c2 ff ff       	call   801016f2 <iinit>
    initlog(ROOTDEV);
8010548a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105491:	e8 00 e5 ff ff       	call   80103996 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105496:	c9                   	leave  
80105497:	c3                   	ret    

80105498 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105498:	55                   	push   %ebp
80105499:	89 e5                	mov    %esp,%ebp
8010549b:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010549e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054a4:	85 c0                	test   %eax,%eax
801054a6:	75 0c                	jne    801054b4 <sleep+0x1c>
    panic("sleep");
801054a8:	c7 04 24 23 9f 10 80 	movl   $0x80109f23,(%esp)
801054af:	e8 86 b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
801054b4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801054b8:	75 0c                	jne    801054c6 <sleep+0x2e>
    panic("sleep without lk");
801054ba:	c7 04 24 29 9f 10 80 	movl   $0x80109f29,(%esp)
801054c1:	e8 74 b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801054c6:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054cd:	74 17                	je     801054e6 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801054cf:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054d6:	e8 05 03 00 00       	call   801057e0 <acquire>
    release(lk);
801054db:	8b 45 0c             	mov    0xc(%ebp),%eax
801054de:	89 04 24             	mov    %eax,(%esp)
801054e1:	e8 5c 03 00 00       	call   80105842 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801054e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054ec:	8b 55 08             	mov    0x8(%ebp),%edx
801054ef:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054f8:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054ff:	e8 71 fe ff ff       	call   80105375 <sched>

  // Tidy up.
  proc->chan = 0;
80105504:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550a:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105511:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
80105518:	74 17                	je     80105531 <sleep+0x99>
    release(&ptable.lock);
8010551a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105521:	e8 1c 03 00 00       	call   80105842 <release>
    acquire(lk);
80105526:	8b 45 0c             	mov    0xc(%ebp),%eax
80105529:	89 04 24             	mov    %eax,(%esp)
8010552c:	e8 af 02 00 00       	call   801057e0 <acquire>
  }
}
80105531:	c9                   	leave  
80105532:	c3                   	ret    

80105533 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105533:	55                   	push   %ebp
80105534:	89 e5                	mov    %esp,%ebp
80105536:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105539:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
80105540:	eb 27                	jmp    80105569 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80105542:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105545:	8b 40 0c             	mov    0xc(%eax),%eax
80105548:	83 f8 02             	cmp    $0x2,%eax
8010554b:	75 15                	jne    80105562 <wakeup1+0x2f>
8010554d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105550:	8b 40 20             	mov    0x20(%eax),%eax
80105553:	3b 45 08             	cmp    0x8(%ebp),%eax
80105556:	75 0a                	jne    80105562 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105558:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010555b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105562:	81 45 fc f0 02 00 00 	addl   $0x2f0,-0x4(%ebp)
80105569:	81 7d fc b4 05 12 80 	cmpl   $0x801205b4,-0x4(%ebp)
80105570:	72 d0                	jb     80105542 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
80105572:	c9                   	leave  
80105573:	c3                   	ret    

80105574 <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
80105574:	55                   	push   %ebp
80105575:	89 e5                	mov    %esp,%ebp
80105577:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
8010557a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105581:	e8 5a 02 00 00       	call   801057e0 <acquire>
    wakeup1(chan);
80105586:	8b 45 08             	mov    0x8(%ebp),%eax
80105589:	89 04 24             	mov    %eax,(%esp)
8010558c:	e8 a2 ff ff ff       	call   80105533 <wakeup1>
    release(&ptable.lock);
80105591:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105598:	e8 a5 02 00 00       	call   80105842 <release>
  }
8010559d:	c9                   	leave  
8010559e:	c3                   	ret    

8010559f <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
8010559f:	55                   	push   %ebp
801055a0:	89 e5                	mov    %esp,%ebp
801055a2:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
801055a5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055ac:	e8 2f 02 00 00       	call   801057e0 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055b1:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801055b8:	eb 44                	jmp    801055fe <kill+0x5f>
      if(p->pid == pid){
801055ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055bd:	8b 40 10             	mov    0x10(%eax),%eax
801055c0:	3b 45 08             	cmp    0x8(%ebp),%eax
801055c3:	75 32                	jne    801055f7 <kill+0x58>
        p->killed = 1;
801055c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c8:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
801055cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d2:	8b 40 0c             	mov    0xc(%eax),%eax
801055d5:	83 f8 02             	cmp    $0x2,%eax
801055d8:	75 0a                	jne    801055e4 <kill+0x45>
          p->state = RUNNABLE;
801055da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055dd:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
801055e4:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055eb:	e8 52 02 00 00       	call   80105842 <release>
        return 0;
801055f0:	b8 00 00 00 00       	mov    $0x0,%eax
801055f5:	eb 21                	jmp    80105618 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055f7:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
801055fe:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
80105605:	72 b3                	jb     801055ba <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
80105607:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010560e:	e8 2f 02 00 00       	call   80105842 <release>
    return -1;
80105613:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
80105618:	c9                   	leave  
80105619:	c3                   	ret    

8010561a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
8010561a:	55                   	push   %ebp
8010561b:	89 e5                	mov    %esp,%ebp
8010561d:	57                   	push   %edi
8010561e:	56                   	push   %esi
8010561f:	53                   	push   %ebx
80105620:	83 ec 6c             	sub    $0x6c,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105623:	c7 45 e0 b4 49 11 80 	movl   $0x801149b4,-0x20(%ebp)
8010562a:	e9 24 01 00 00       	jmp    80105753 <procdump+0x139>
      if(p->state == UNUSED)
8010562f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105632:	8b 40 0c             	mov    0xc(%eax),%eax
80105635:	85 c0                	test   %eax,%eax
80105637:	75 05                	jne    8010563e <procdump+0x24>
        continue;
80105639:	e9 0e 01 00 00       	jmp    8010574c <procdump+0x132>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010563e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105641:	8b 40 0c             	mov    0xc(%eax),%eax
80105644:	83 f8 05             	cmp    $0x5,%eax
80105647:	77 23                	ja     8010566c <procdump+0x52>
80105649:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010564c:	8b 40 0c             	mov    0xc(%eax),%eax
8010564f:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105656:	85 c0                	test   %eax,%eax
80105658:	74 12                	je     8010566c <procdump+0x52>
        state = states[p->state];
8010565a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010565d:	8b 40 0c             	mov    0xc(%eax),%eax
80105660:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105667:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010566a:	eb 07                	jmp    80105673 <procdump+0x59>
      else
        state = "???";
8010566c:	c7 45 dc 3a 9f 10 80 	movl   $0x80109f3a,-0x24(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
80105673:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105676:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
8010567c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010567f:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
80105685:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105688:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
8010568e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105691:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
80105697:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010569a:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
801056a0:	01 c6                	add    %eax,%esi
801056a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056a5:	8b 40 10             	mov    0x10(%eax),%eax
801056a8:	89 5c 24 18          	mov    %ebx,0x18(%esp)
801056ac:	89 4c 24 14          	mov    %ecx,0x14(%esp)
801056b0:	89 54 24 10          	mov    %edx,0x10(%esp)
801056b4:	89 74 24 0c          	mov    %esi,0xc(%esp)
801056b8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801056bb:	89 54 24 08          	mov    %edx,0x8(%esp)
801056bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801056c3:	c7 04 24 3e 9f 10 80 	movl   $0x80109f3e,(%esp)
801056ca:	e8 d1 ac ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
801056cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056d2:	83 c0 6c             	add    $0x6c,%eax
801056d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d9:	c7 04 24 51 9f 10 80 	movl   $0x80109f51,(%esp)
801056e0:	e8 bb ac ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
801056e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056e8:	8b 40 0c             	mov    0xc(%eax),%eax
801056eb:	83 f8 02             	cmp    $0x2,%eax
801056ee:	75 50                	jne    80105740 <procdump+0x126>
        getcallerpcs((uint*)p->context->ebp+2, pc);
801056f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056f3:	8b 40 1c             	mov    0x1c(%eax),%eax
801056f6:	8b 40 0c             	mov    0xc(%eax),%eax
801056f9:	83 c0 08             	add    $0x8,%eax
801056fc:	8d 55 b4             	lea    -0x4c(%ebp),%edx
801056ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80105703:	89 04 24             	mov    %eax,(%esp)
80105706:	e8 86 01 00 00       	call   80105891 <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
8010570b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105712:	eb 1b                	jmp    8010572f <procdump+0x115>
          cprintf(" %p", pc[i]);
80105714:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105717:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
8010571b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010571f:	c7 04 24 54 9f 10 80 	movl   $0x80109f54,(%esp)
80105726:	e8 75 ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
8010572b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010572f:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
80105733:	7f 0b                	jg     80105740 <procdump+0x126>
80105735:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105738:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
8010573c:	85 c0                	test   %eax,%eax
8010573e:	75 d4                	jne    80105714 <procdump+0xfa>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
80105740:	c7 04 24 58 9f 10 80 	movl   $0x80109f58,(%esp)
80105747:	e8 54 ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010574c:	81 45 e0 f0 02 00 00 	addl   $0x2f0,-0x20(%ebp)
80105753:	81 7d e0 b4 05 12 80 	cmpl   $0x801205b4,-0x20(%ebp)
8010575a:	0f 82 cf fe ff ff    	jb     8010562f <procdump+0x15>
        for(i=0; i<10 && pc[i] != 0; i++)
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    cprintf("%d free pages in the system\n",countPages()*100/numOfInitializedPages);
80105760:	e8 18 db ff ff       	call   8010327d <countPages>
80105765:	6b c0 64             	imul   $0x64,%eax,%eax
80105768:	8b 3d 60 49 11 80    	mov    0x80114960,%edi
8010576e:	99                   	cltd   
8010576f:	f7 ff                	idiv   %edi
80105771:	89 44 24 04          	mov    %eax,0x4(%esp)
80105775:	c7 04 24 5a 9f 10 80 	movl   $0x80109f5a,(%esp)
8010577c:	e8 1f ac ff ff       	call   801003a0 <cprintf>
80105781:	83 c4 6c             	add    $0x6c,%esp
80105784:	5b                   	pop    %ebx
80105785:	5e                   	pop    %esi
80105786:	5f                   	pop    %edi
80105787:	5d                   	pop    %ebp
80105788:	c3                   	ret    

80105789 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105789:	55                   	push   %ebp
8010578a:	89 e5                	mov    %esp,%ebp
8010578c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010578f:	9c                   	pushf  
80105790:	58                   	pop    %eax
80105791:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105794:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105797:	c9                   	leave  
80105798:	c3                   	ret    

80105799 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105799:	55                   	push   %ebp
8010579a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010579c:	fa                   	cli    
}
8010579d:	5d                   	pop    %ebp
8010579e:	c3                   	ret    

8010579f <sti>:

static inline void
sti(void)
{
8010579f:	55                   	push   %ebp
801057a0:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801057a2:	fb                   	sti    
}
801057a3:	5d                   	pop    %ebp
801057a4:	c3                   	ret    

801057a5 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801057a5:	55                   	push   %ebp
801057a6:	89 e5                	mov    %esp,%ebp
801057a8:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801057ab:	8b 55 08             	mov    0x8(%ebp),%edx
801057ae:	8b 45 0c             	mov    0xc(%ebp),%eax
801057b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
801057b4:	f0 87 02             	lock xchg %eax,(%edx)
801057b7:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801057ba:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801057bd:	c9                   	leave  
801057be:	c3                   	ret    

801057bf <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
801057bf:	55                   	push   %ebp
801057c0:	89 e5                	mov    %esp,%ebp
  lk->name = name;
801057c2:	8b 45 08             	mov    0x8(%ebp),%eax
801057c5:	8b 55 0c             	mov    0xc(%ebp),%edx
801057c8:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
801057cb:	8b 45 08             	mov    0x8(%ebp),%eax
801057ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801057d4:	8b 45 08             	mov    0x8(%ebp),%eax
801057d7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801057de:	5d                   	pop    %ebp
801057df:	c3                   	ret    

801057e0 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801057e0:	55                   	push   %ebp
801057e1:	89 e5                	mov    %esp,%ebp
801057e3:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801057e6:	e8 49 01 00 00       	call   80105934 <pushcli>
  if(holding(lk))
801057eb:	8b 45 08             	mov    0x8(%ebp),%eax
801057ee:	89 04 24             	mov    %eax,(%esp)
801057f1:	e8 14 01 00 00       	call   8010590a <holding>
801057f6:	85 c0                	test   %eax,%eax
801057f8:	74 0c                	je     80105806 <acquire+0x26>
    panic("acquire");
801057fa:	c7 04 24 a1 9f 10 80 	movl   $0x80109fa1,(%esp)
80105801:	e8 34 ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105806:	90                   	nop
80105807:	8b 45 08             	mov    0x8(%ebp),%eax
8010580a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105811:	00 
80105812:	89 04 24             	mov    %eax,(%esp)
80105815:	e8 8b ff ff ff       	call   801057a5 <xchg>
8010581a:	85 c0                	test   %eax,%eax
8010581c:	75 e9                	jne    80105807 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010581e:	8b 45 08             	mov    0x8(%ebp),%eax
80105821:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105828:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
8010582b:	8b 45 08             	mov    0x8(%ebp),%eax
8010582e:	83 c0 0c             	add    $0xc,%eax
80105831:	89 44 24 04          	mov    %eax,0x4(%esp)
80105835:	8d 45 08             	lea    0x8(%ebp),%eax
80105838:	89 04 24             	mov    %eax,(%esp)
8010583b:	e8 51 00 00 00       	call   80105891 <getcallerpcs>
}
80105840:	c9                   	leave  
80105841:	c3                   	ret    

80105842 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105842:	55                   	push   %ebp
80105843:	89 e5                	mov    %esp,%ebp
80105845:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105848:	8b 45 08             	mov    0x8(%ebp),%eax
8010584b:	89 04 24             	mov    %eax,(%esp)
8010584e:	e8 b7 00 00 00       	call   8010590a <holding>
80105853:	85 c0                	test   %eax,%eax
80105855:	75 0c                	jne    80105863 <release+0x21>
    panic("release");
80105857:	c7 04 24 a9 9f 10 80 	movl   $0x80109fa9,(%esp)
8010585e:	e8 d7 ac ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105863:	8b 45 08             	mov    0x8(%ebp),%eax
80105866:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010586d:	8b 45 08             	mov    0x8(%ebp),%eax
80105870:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105877:	8b 45 08             	mov    0x8(%ebp),%eax
8010587a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105881:	00 
80105882:	89 04 24             	mov    %eax,(%esp)
80105885:	e8 1b ff ff ff       	call   801057a5 <xchg>

  popcli();
8010588a:	e8 e9 00 00 00       	call   80105978 <popcli>
}
8010588f:	c9                   	leave  
80105890:	c3                   	ret    

80105891 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105891:	55                   	push   %ebp
80105892:	89 e5                	mov    %esp,%ebp
80105894:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105897:	8b 45 08             	mov    0x8(%ebp),%eax
8010589a:	83 e8 08             	sub    $0x8,%eax
8010589d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801058a0:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801058a7:	eb 38                	jmp    801058e1 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801058a9:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801058ad:	74 38                	je     801058e7 <getcallerpcs+0x56>
801058af:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801058b6:	76 2f                	jbe    801058e7 <getcallerpcs+0x56>
801058b8:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801058bc:	74 29                	je     801058e7 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
801058be:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058c1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801058cb:	01 c2                	add    %eax,%edx
801058cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058d0:	8b 40 04             	mov    0x4(%eax),%eax
801058d3:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801058d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058d8:	8b 00                	mov    (%eax),%eax
801058da:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801058dd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058e1:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058e5:	7e c2                	jle    801058a9 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058e7:	eb 19                	jmp    80105902 <getcallerpcs+0x71>
    pcs[i] = 0;
801058e9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058ec:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801058f6:	01 d0                	add    %edx,%eax
801058f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058fe:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105902:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105906:	7e e1                	jle    801058e9 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105908:	c9                   	leave  
80105909:	c3                   	ret    

8010590a <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010590a:	55                   	push   %ebp
8010590b:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
8010590d:	8b 45 08             	mov    0x8(%ebp),%eax
80105910:	8b 00                	mov    (%eax),%eax
80105912:	85 c0                	test   %eax,%eax
80105914:	74 17                	je     8010592d <holding+0x23>
80105916:	8b 45 08             	mov    0x8(%ebp),%eax
80105919:	8b 50 08             	mov    0x8(%eax),%edx
8010591c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105922:	39 c2                	cmp    %eax,%edx
80105924:	75 07                	jne    8010592d <holding+0x23>
80105926:	b8 01 00 00 00       	mov    $0x1,%eax
8010592b:	eb 05                	jmp    80105932 <holding+0x28>
8010592d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105932:	5d                   	pop    %ebp
80105933:	c3                   	ret    

80105934 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105934:	55                   	push   %ebp
80105935:	89 e5                	mov    %esp,%ebp
80105937:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010593a:	e8 4a fe ff ff       	call   80105789 <readeflags>
8010593f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105942:	e8 52 fe ff ff       	call   80105799 <cli>
  if(cpu->ncli++ == 0)
80105947:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010594e:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105954:	8d 48 01             	lea    0x1(%eax),%ecx
80105957:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
8010595d:	85 c0                	test   %eax,%eax
8010595f:	75 15                	jne    80105976 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105961:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105967:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010596a:	81 e2 00 02 00 00    	and    $0x200,%edx
80105970:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105976:	c9                   	leave  
80105977:	c3                   	ret    

80105978 <popcli>:

void
popcli(void)
{
80105978:	55                   	push   %ebp
80105979:	89 e5                	mov    %esp,%ebp
8010597b:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010597e:	e8 06 fe ff ff       	call   80105789 <readeflags>
80105983:	25 00 02 00 00       	and    $0x200,%eax
80105988:	85 c0                	test   %eax,%eax
8010598a:	74 0c                	je     80105998 <popcli+0x20>
    panic("popcli - interruptible");
8010598c:	c7 04 24 b1 9f 10 80 	movl   $0x80109fb1,(%esp)
80105993:	e8 a2 ab ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105998:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010599e:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801059a4:	83 ea 01             	sub    $0x1,%edx
801059a7:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801059ad:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059b3:	85 c0                	test   %eax,%eax
801059b5:	79 0c                	jns    801059c3 <popcli+0x4b>
    panic("popcli");
801059b7:	c7 04 24 c8 9f 10 80 	movl   $0x80109fc8,(%esp)
801059be:	e8 77 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
801059c3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059c9:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059cf:	85 c0                	test   %eax,%eax
801059d1:	75 15                	jne    801059e8 <popcli+0x70>
801059d3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059d9:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801059df:	85 c0                	test   %eax,%eax
801059e1:	74 05                	je     801059e8 <popcli+0x70>
    sti();
801059e3:	e8 b7 fd ff ff       	call   8010579f <sti>
}
801059e8:	c9                   	leave  
801059e9:	c3                   	ret    

801059ea <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801059ea:	55                   	push   %ebp
801059eb:	89 e5                	mov    %esp,%ebp
801059ed:	57                   	push   %edi
801059ee:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801059ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059f2:	8b 55 10             	mov    0x10(%ebp),%edx
801059f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801059f8:	89 cb                	mov    %ecx,%ebx
801059fa:	89 df                	mov    %ebx,%edi
801059fc:	89 d1                	mov    %edx,%ecx
801059fe:	fc                   	cld    
801059ff:	f3 aa                	rep stos %al,%es:(%edi)
80105a01:	89 ca                	mov    %ecx,%edx
80105a03:	89 fb                	mov    %edi,%ebx
80105a05:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105a08:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105a0b:	5b                   	pop    %ebx
80105a0c:	5f                   	pop    %edi
80105a0d:	5d                   	pop    %ebp
80105a0e:	c3                   	ret    

80105a0f <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105a0f:	55                   	push   %ebp
80105a10:	89 e5                	mov    %esp,%ebp
80105a12:	57                   	push   %edi
80105a13:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105a14:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105a17:	8b 55 10             	mov    0x10(%ebp),%edx
80105a1a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1d:	89 cb                	mov    %ecx,%ebx
80105a1f:	89 df                	mov    %ebx,%edi
80105a21:	89 d1                	mov    %edx,%ecx
80105a23:	fc                   	cld    
80105a24:	f3 ab                	rep stos %eax,%es:(%edi)
80105a26:	89 ca                	mov    %ecx,%edx
80105a28:	89 fb                	mov    %edi,%ebx
80105a2a:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105a2d:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105a30:	5b                   	pop    %ebx
80105a31:	5f                   	pop    %edi
80105a32:	5d                   	pop    %ebp
80105a33:	c3                   	ret    

80105a34 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105a34:	55                   	push   %ebp
80105a35:	89 e5                	mov    %esp,%ebp
80105a37:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105a3a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a3d:	83 e0 03             	and    $0x3,%eax
80105a40:	85 c0                	test   %eax,%eax
80105a42:	75 49                	jne    80105a8d <memset+0x59>
80105a44:	8b 45 10             	mov    0x10(%ebp),%eax
80105a47:	83 e0 03             	and    $0x3,%eax
80105a4a:	85 c0                	test   %eax,%eax
80105a4c:	75 3f                	jne    80105a8d <memset+0x59>
    c &= 0xFF;
80105a4e:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105a55:	8b 45 10             	mov    0x10(%ebp),%eax
80105a58:	c1 e8 02             	shr    $0x2,%eax
80105a5b:	89 c2                	mov    %eax,%edx
80105a5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a60:	c1 e0 18             	shl    $0x18,%eax
80105a63:	89 c1                	mov    %eax,%ecx
80105a65:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a68:	c1 e0 10             	shl    $0x10,%eax
80105a6b:	09 c1                	or     %eax,%ecx
80105a6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a70:	c1 e0 08             	shl    $0x8,%eax
80105a73:	09 c8                	or     %ecx,%eax
80105a75:	0b 45 0c             	or     0xc(%ebp),%eax
80105a78:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a80:	8b 45 08             	mov    0x8(%ebp),%eax
80105a83:	89 04 24             	mov    %eax,(%esp)
80105a86:	e8 84 ff ff ff       	call   80105a0f <stosl>
80105a8b:	eb 19                	jmp    80105aa6 <memset+0x72>
  } else
    stosb(dst, c, n);
80105a8d:	8b 45 10             	mov    0x10(%ebp),%eax
80105a90:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a94:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a97:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a9e:	89 04 24             	mov    %eax,(%esp)
80105aa1:	e8 44 ff ff ff       	call   801059ea <stosb>
  return dst;
80105aa6:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105aa9:	c9                   	leave  
80105aaa:	c3                   	ret    

80105aab <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105aab:	55                   	push   %ebp
80105aac:	89 e5                	mov    %esp,%ebp
80105aae:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105ab1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ab4:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105ab7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105aba:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105abd:	eb 30                	jmp    80105aef <memcmp+0x44>
    if(*s1 != *s2)
80105abf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ac2:	0f b6 10             	movzbl (%eax),%edx
80105ac5:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ac8:	0f b6 00             	movzbl (%eax),%eax
80105acb:	38 c2                	cmp    %al,%dl
80105acd:	74 18                	je     80105ae7 <memcmp+0x3c>
      return *s1 - *s2;
80105acf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ad2:	0f b6 00             	movzbl (%eax),%eax
80105ad5:	0f b6 d0             	movzbl %al,%edx
80105ad8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105adb:	0f b6 00             	movzbl (%eax),%eax
80105ade:	0f b6 c0             	movzbl %al,%eax
80105ae1:	29 c2                	sub    %eax,%edx
80105ae3:	89 d0                	mov    %edx,%eax
80105ae5:	eb 1a                	jmp    80105b01 <memcmp+0x56>
    s1++, s2++;
80105ae7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105aeb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105aef:	8b 45 10             	mov    0x10(%ebp),%eax
80105af2:	8d 50 ff             	lea    -0x1(%eax),%edx
80105af5:	89 55 10             	mov    %edx,0x10(%ebp)
80105af8:	85 c0                	test   %eax,%eax
80105afa:	75 c3                	jne    80105abf <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105afc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b01:	c9                   	leave  
80105b02:	c3                   	ret    

80105b03 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105b03:	55                   	push   %ebp
80105b04:	89 e5                	mov    %esp,%ebp
80105b06:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105b09:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b0c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80105b12:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105b15:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b18:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105b1b:	73 3d                	jae    80105b5a <memmove+0x57>
80105b1d:	8b 45 10             	mov    0x10(%ebp),%eax
80105b20:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b23:	01 d0                	add    %edx,%eax
80105b25:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105b28:	76 30                	jbe    80105b5a <memmove+0x57>
    s += n;
80105b2a:	8b 45 10             	mov    0x10(%ebp),%eax
80105b2d:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105b30:	8b 45 10             	mov    0x10(%ebp),%eax
80105b33:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105b36:	eb 13                	jmp    80105b4b <memmove+0x48>
      *--d = *--s;
80105b38:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105b3c:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105b40:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b43:	0f b6 10             	movzbl (%eax),%edx
80105b46:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b49:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105b4b:	8b 45 10             	mov    0x10(%ebp),%eax
80105b4e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b51:	89 55 10             	mov    %edx,0x10(%ebp)
80105b54:	85 c0                	test   %eax,%eax
80105b56:	75 e0                	jne    80105b38 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105b58:	eb 26                	jmp    80105b80 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b5a:	eb 17                	jmp    80105b73 <memmove+0x70>
      *d++ = *s++;
80105b5c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b5f:	8d 50 01             	lea    0x1(%eax),%edx
80105b62:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105b65:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b68:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b6b:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105b6e:	0f b6 12             	movzbl (%edx),%edx
80105b71:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b73:	8b 45 10             	mov    0x10(%ebp),%eax
80105b76:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b79:	89 55 10             	mov    %edx,0x10(%ebp)
80105b7c:	85 c0                	test   %eax,%eax
80105b7e:	75 dc                	jne    80105b5c <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b80:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b83:	c9                   	leave  
80105b84:	c3                   	ret    

80105b85 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b85:	55                   	push   %ebp
80105b86:	89 e5                	mov    %esp,%ebp
80105b88:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b8b:	8b 45 10             	mov    0x10(%ebp),%eax
80105b8e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b92:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b95:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b99:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9c:	89 04 24             	mov    %eax,(%esp)
80105b9f:	e8 5f ff ff ff       	call   80105b03 <memmove>
}
80105ba4:	c9                   	leave  
80105ba5:	c3                   	ret    

80105ba6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105ba6:	55                   	push   %ebp
80105ba7:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105ba9:	eb 0c                	jmp    80105bb7 <strncmp+0x11>
    n--, p++, q++;
80105bab:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105baf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105bb3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105bb7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bbb:	74 1a                	je     80105bd7 <strncmp+0x31>
80105bbd:	8b 45 08             	mov    0x8(%ebp),%eax
80105bc0:	0f b6 00             	movzbl (%eax),%eax
80105bc3:	84 c0                	test   %al,%al
80105bc5:	74 10                	je     80105bd7 <strncmp+0x31>
80105bc7:	8b 45 08             	mov    0x8(%ebp),%eax
80105bca:	0f b6 10             	movzbl (%eax),%edx
80105bcd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bd0:	0f b6 00             	movzbl (%eax),%eax
80105bd3:	38 c2                	cmp    %al,%dl
80105bd5:	74 d4                	je     80105bab <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105bd7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bdb:	75 07                	jne    80105be4 <strncmp+0x3e>
    return 0;
80105bdd:	b8 00 00 00 00       	mov    $0x0,%eax
80105be2:	eb 16                	jmp    80105bfa <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105be4:	8b 45 08             	mov    0x8(%ebp),%eax
80105be7:	0f b6 00             	movzbl (%eax),%eax
80105bea:	0f b6 d0             	movzbl %al,%edx
80105bed:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bf0:	0f b6 00             	movzbl (%eax),%eax
80105bf3:	0f b6 c0             	movzbl %al,%eax
80105bf6:	29 c2                	sub    %eax,%edx
80105bf8:	89 d0                	mov    %edx,%eax
}
80105bfa:	5d                   	pop    %ebp
80105bfb:	c3                   	ret    

80105bfc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105bfc:	55                   	push   %ebp
80105bfd:	89 e5                	mov    %esp,%ebp
80105bff:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c02:	8b 45 08             	mov    0x8(%ebp),%eax
80105c05:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105c08:	90                   	nop
80105c09:	8b 45 10             	mov    0x10(%ebp),%eax
80105c0c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c0f:	89 55 10             	mov    %edx,0x10(%ebp)
80105c12:	85 c0                	test   %eax,%eax
80105c14:	7e 1e                	jle    80105c34 <strncpy+0x38>
80105c16:	8b 45 08             	mov    0x8(%ebp),%eax
80105c19:	8d 50 01             	lea    0x1(%eax),%edx
80105c1c:	89 55 08             	mov    %edx,0x8(%ebp)
80105c1f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c22:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c25:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c28:	0f b6 12             	movzbl (%edx),%edx
80105c2b:	88 10                	mov    %dl,(%eax)
80105c2d:	0f b6 00             	movzbl (%eax),%eax
80105c30:	84 c0                	test   %al,%al
80105c32:	75 d5                	jne    80105c09 <strncpy+0xd>
    ;
  while(n-- > 0)
80105c34:	eb 0c                	jmp    80105c42 <strncpy+0x46>
    *s++ = 0;
80105c36:	8b 45 08             	mov    0x8(%ebp),%eax
80105c39:	8d 50 01             	lea    0x1(%eax),%edx
80105c3c:	89 55 08             	mov    %edx,0x8(%ebp)
80105c3f:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105c42:	8b 45 10             	mov    0x10(%ebp),%eax
80105c45:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c48:	89 55 10             	mov    %edx,0x10(%ebp)
80105c4b:	85 c0                	test   %eax,%eax
80105c4d:	7f e7                	jg     80105c36 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105c4f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c52:	c9                   	leave  
80105c53:	c3                   	ret    

80105c54 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105c54:	55                   	push   %ebp
80105c55:	89 e5                	mov    %esp,%ebp
80105c57:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c5a:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105c60:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c64:	7f 05                	jg     80105c6b <safestrcpy+0x17>
    return os;
80105c66:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c69:	eb 31                	jmp    80105c9c <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105c6b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c6f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c73:	7e 1e                	jle    80105c93 <safestrcpy+0x3f>
80105c75:	8b 45 08             	mov    0x8(%ebp),%eax
80105c78:	8d 50 01             	lea    0x1(%eax),%edx
80105c7b:	89 55 08             	mov    %edx,0x8(%ebp)
80105c7e:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c81:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c84:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c87:	0f b6 12             	movzbl (%edx),%edx
80105c8a:	88 10                	mov    %dl,(%eax)
80105c8c:	0f b6 00             	movzbl (%eax),%eax
80105c8f:	84 c0                	test   %al,%al
80105c91:	75 d8                	jne    80105c6b <safestrcpy+0x17>
    ;
  *s = 0;
80105c93:	8b 45 08             	mov    0x8(%ebp),%eax
80105c96:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c99:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c9c:	c9                   	leave  
80105c9d:	c3                   	ret    

80105c9e <strlen>:

int
strlen(const char *s)
{
80105c9e:	55                   	push   %ebp
80105c9f:	89 e5                	mov    %esp,%ebp
80105ca1:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105ca4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105cab:	eb 04                	jmp    80105cb1 <strlen+0x13>
80105cad:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105cb1:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105cb4:	8b 45 08             	mov    0x8(%ebp),%eax
80105cb7:	01 d0                	add    %edx,%eax
80105cb9:	0f b6 00             	movzbl (%eax),%eax
80105cbc:	84 c0                	test   %al,%al
80105cbe:	75 ed                	jne    80105cad <strlen+0xf>
    ;
  return n;
80105cc0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105cc3:	c9                   	leave  
80105cc4:	c3                   	ret    

80105cc5 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105cc5:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105cc9:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105ccd:	55                   	push   %ebp
  pushl %ebx
80105cce:	53                   	push   %ebx
  pushl %esi
80105ccf:	56                   	push   %esi
  pushl %edi
80105cd0:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105cd1:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105cd3:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105cd5:	5f                   	pop    %edi
  popl %esi
80105cd6:	5e                   	pop    %esi
  popl %ebx
80105cd7:	5b                   	pop    %ebx
  popl %ebp
80105cd8:	5d                   	pop    %ebp
  ret
80105cd9:	c3                   	ret    

80105cda <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105cda:	55                   	push   %ebp
80105cdb:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105cdd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ce3:	8b 00                	mov    (%eax),%eax
80105ce5:	3b 45 08             	cmp    0x8(%ebp),%eax
80105ce8:	76 12                	jbe    80105cfc <fetchint+0x22>
80105cea:	8b 45 08             	mov    0x8(%ebp),%eax
80105ced:	8d 50 04             	lea    0x4(%eax),%edx
80105cf0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf6:	8b 00                	mov    (%eax),%eax
80105cf8:	39 c2                	cmp    %eax,%edx
80105cfa:	76 07                	jbe    80105d03 <fetchint+0x29>
    return -1;
80105cfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d01:	eb 0f                	jmp    80105d12 <fetchint+0x38>
  *ip = *(int*)(addr);
80105d03:	8b 45 08             	mov    0x8(%ebp),%eax
80105d06:	8b 10                	mov    (%eax),%edx
80105d08:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d0b:	89 10                	mov    %edx,(%eax)
  return 0;
80105d0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d12:	5d                   	pop    %ebp
80105d13:	c3                   	ret    

80105d14 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105d14:	55                   	push   %ebp
80105d15:	89 e5                	mov    %esp,%ebp
80105d17:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105d1a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d20:	8b 00                	mov    (%eax),%eax
80105d22:	3b 45 08             	cmp    0x8(%ebp),%eax
80105d25:	77 07                	ja     80105d2e <fetchstr+0x1a>
    return -1;
80105d27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d2c:	eb 46                	jmp    80105d74 <fetchstr+0x60>
  *pp = (char*)addr;
80105d2e:	8b 55 08             	mov    0x8(%ebp),%edx
80105d31:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d34:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105d36:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d3c:	8b 00                	mov    (%eax),%eax
80105d3e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105d41:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d44:	8b 00                	mov    (%eax),%eax
80105d46:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105d49:	eb 1c                	jmp    80105d67 <fetchstr+0x53>
    if(*s == 0)
80105d4b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d4e:	0f b6 00             	movzbl (%eax),%eax
80105d51:	84 c0                	test   %al,%al
80105d53:	75 0e                	jne    80105d63 <fetchstr+0x4f>
      return s - *pp;
80105d55:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d58:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d5b:	8b 00                	mov    (%eax),%eax
80105d5d:	29 c2                	sub    %eax,%edx
80105d5f:	89 d0                	mov    %edx,%eax
80105d61:	eb 11                	jmp    80105d74 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105d63:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d67:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d6a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d6d:	72 dc                	jb     80105d4b <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105d6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d74:	c9                   	leave  
80105d75:	c3                   	ret    

80105d76 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d76:	55                   	push   %ebp
80105d77:	89 e5                	mov    %esp,%ebp
80105d79:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d7c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d82:	8b 40 18             	mov    0x18(%eax),%eax
80105d85:	8b 50 44             	mov    0x44(%eax),%edx
80105d88:	8b 45 08             	mov    0x8(%ebp),%eax
80105d8b:	c1 e0 02             	shl    $0x2,%eax
80105d8e:	01 d0                	add    %edx,%eax
80105d90:	8d 50 04             	lea    0x4(%eax),%edx
80105d93:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d96:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9a:	89 14 24             	mov    %edx,(%esp)
80105d9d:	e8 38 ff ff ff       	call   80105cda <fetchint>
}
80105da2:	c9                   	leave  
80105da3:	c3                   	ret    

80105da4 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105da4:	55                   	push   %ebp
80105da5:	89 e5                	mov    %esp,%ebp
80105da7:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105daa:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105dad:	89 44 24 04          	mov    %eax,0x4(%esp)
80105db1:	8b 45 08             	mov    0x8(%ebp),%eax
80105db4:	89 04 24             	mov    %eax,(%esp)
80105db7:	e8 ba ff ff ff       	call   80105d76 <argint>
80105dbc:	85 c0                	test   %eax,%eax
80105dbe:	79 07                	jns    80105dc7 <argptr+0x23>
    return -1;
80105dc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dc5:	eb 3d                	jmp    80105e04 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105dc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dca:	89 c2                	mov    %eax,%edx
80105dcc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dd2:	8b 00                	mov    (%eax),%eax
80105dd4:	39 c2                	cmp    %eax,%edx
80105dd6:	73 16                	jae    80105dee <argptr+0x4a>
80105dd8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ddb:	89 c2                	mov    %eax,%edx
80105ddd:	8b 45 10             	mov    0x10(%ebp),%eax
80105de0:	01 c2                	add    %eax,%edx
80105de2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105de8:	8b 00                	mov    (%eax),%eax
80105dea:	39 c2                	cmp    %eax,%edx
80105dec:	76 07                	jbe    80105df5 <argptr+0x51>
    return -1;
80105dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105df3:	eb 0f                	jmp    80105e04 <argptr+0x60>
  *pp = (char*)i;
80105df5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105df8:	89 c2                	mov    %eax,%edx
80105dfa:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dfd:	89 10                	mov    %edx,(%eax)
  return 0;
80105dff:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e04:	c9                   	leave  
80105e05:	c3                   	ret    

80105e06 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105e06:	55                   	push   %ebp
80105e07:	89 e5                	mov    %esp,%ebp
80105e09:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105e0c:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105e0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e13:	8b 45 08             	mov    0x8(%ebp),%eax
80105e16:	89 04 24             	mov    %eax,(%esp)
80105e19:	e8 58 ff ff ff       	call   80105d76 <argint>
80105e1e:	85 c0                	test   %eax,%eax
80105e20:	79 07                	jns    80105e29 <argstr+0x23>
    return -1;
80105e22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e27:	eb 12                	jmp    80105e3b <argstr+0x35>
  return fetchstr(addr, pp);
80105e29:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e2c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e33:	89 04 24             	mov    %eax,(%esp)
80105e36:	e8 d9 fe ff ff       	call   80105d14 <fetchstr>
}
80105e3b:	c9                   	leave  
80105e3c:	c3                   	ret    

80105e3d <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105e3d:	55                   	push   %ebp
80105e3e:	89 e5                	mov    %esp,%ebp
80105e40:	53                   	push   %ebx
80105e41:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105e44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e4a:	8b 40 18             	mov    0x18(%eax),%eax
80105e4d:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e50:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105e53:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e57:	7e 30                	jle    80105e89 <syscall+0x4c>
80105e59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e5c:	83 f8 15             	cmp    $0x15,%eax
80105e5f:	77 28                	ja     80105e89 <syscall+0x4c>
80105e61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e64:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e6b:	85 c0                	test   %eax,%eax
80105e6d:	74 1a                	je     80105e89 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105e6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e75:	8b 58 18             	mov    0x18(%eax),%ebx
80105e78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e7b:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e82:	ff d0                	call   *%eax
80105e84:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e87:	eb 3d                	jmp    80105ec6 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e8f:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e92:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e98:	8b 40 10             	mov    0x10(%eax),%eax
80105e9b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e9e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105ea2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ea6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eaa:	c7 04 24 cf 9f 10 80 	movl   $0x80109fcf,(%esp)
80105eb1:	e8 ea a4 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105eb6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ebc:	8b 40 18             	mov    0x18(%eax),%eax
80105ebf:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105ec6:	83 c4 24             	add    $0x24,%esp
80105ec9:	5b                   	pop    %ebx
80105eca:	5d                   	pop    %ebp
80105ecb:	c3                   	ret    

80105ecc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105ecc:	55                   	push   %ebp
80105ecd:	89 e5                	mov    %esp,%ebp
80105ecf:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105ed2:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ed5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed9:	8b 45 08             	mov    0x8(%ebp),%eax
80105edc:	89 04 24             	mov    %eax,(%esp)
80105edf:	e8 92 fe ff ff       	call   80105d76 <argint>
80105ee4:	85 c0                	test   %eax,%eax
80105ee6:	79 07                	jns    80105eef <argfd+0x23>
    return -1;
80105ee8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eed:	eb 50                	jmp    80105f3f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105eef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ef2:	85 c0                	test   %eax,%eax
80105ef4:	78 21                	js     80105f17 <argfd+0x4b>
80105ef6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ef9:	83 f8 0f             	cmp    $0xf,%eax
80105efc:	7f 19                	jg     80105f17 <argfd+0x4b>
80105efe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f04:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105f07:	83 c2 08             	add    $0x8,%edx
80105f0a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f11:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f15:	75 07                	jne    80105f1e <argfd+0x52>
    return -1;
80105f17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f1c:	eb 21                	jmp    80105f3f <argfd+0x73>
  if(pfd)
80105f1e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105f22:	74 08                	je     80105f2c <argfd+0x60>
    *pfd = fd;
80105f24:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105f27:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f2a:	89 10                	mov    %edx,(%eax)
  if(pf)
80105f2c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f30:	74 08                	je     80105f3a <argfd+0x6e>
    *pf = f;
80105f32:	8b 45 10             	mov    0x10(%ebp),%eax
80105f35:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f38:	89 10                	mov    %edx,(%eax)
  return 0;
80105f3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f3f:	c9                   	leave  
80105f40:	c3                   	ret    

80105f41 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105f41:	55                   	push   %ebp
80105f42:	89 e5                	mov    %esp,%ebp
80105f44:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f47:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f4e:	eb 30                	jmp    80105f80 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f50:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f56:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f59:	83 c2 08             	add    $0x8,%edx
80105f5c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f60:	85 c0                	test   %eax,%eax
80105f62:	75 18                	jne    80105f7c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f6a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f6d:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f70:	8b 55 08             	mov    0x8(%ebp),%edx
80105f73:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f77:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f7a:	eb 0f                	jmp    80105f8b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f7c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f80:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f84:	7e ca                	jle    80105f50 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f8b:	c9                   	leave  
80105f8c:	c3                   	ret    

80105f8d <sys_dup>:

int
sys_dup(void)
{
80105f8d:	55                   	push   %ebp
80105f8e:	89 e5                	mov    %esp,%ebp
80105f90:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f93:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f96:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f9a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fa1:	00 
80105fa2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fa9:	e8 1e ff ff ff       	call   80105ecc <argfd>
80105fae:	85 c0                	test   %eax,%eax
80105fb0:	79 07                	jns    80105fb9 <sys_dup+0x2c>
    return -1;
80105fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fb7:	eb 29                	jmp    80105fe2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105fb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fbc:	89 04 24             	mov    %eax,(%esp)
80105fbf:	e8 7d ff ff ff       	call   80105f41 <fdalloc>
80105fc4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fc7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fcb:	79 07                	jns    80105fd4 <sys_dup+0x47>
    return -1;
80105fcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fd2:	eb 0e                	jmp    80105fe2 <sys_dup+0x55>
  filedup(f);
80105fd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fd7:	89 04 24             	mov    %eax,(%esp)
80105fda:	e8 08 b1 ff ff       	call   801010e7 <filedup>
  return fd;
80105fdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105fe2:	c9                   	leave  
80105fe3:	c3                   	ret    

80105fe4 <sys_read>:

int
sys_read(void)
{
80105fe4:	55                   	push   %ebp
80105fe5:	89 e5                	mov    %esp,%ebp
80105fe7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fea:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fed:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ff1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ff8:	00 
80105ff9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106000:	e8 c7 fe ff ff       	call   80105ecc <argfd>
80106005:	85 c0                	test   %eax,%eax
80106007:	78 35                	js     8010603e <sys_read+0x5a>
80106009:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010600c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106010:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106017:	e8 5a fd ff ff       	call   80105d76 <argint>
8010601c:	85 c0                	test   %eax,%eax
8010601e:	78 1e                	js     8010603e <sys_read+0x5a>
80106020:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106023:	89 44 24 08          	mov    %eax,0x8(%esp)
80106027:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010602a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010602e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106035:	e8 6a fd ff ff       	call   80105da4 <argptr>
8010603a:	85 c0                	test   %eax,%eax
8010603c:	79 07                	jns    80106045 <sys_read+0x61>
    return -1;
8010603e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106043:	eb 19                	jmp    8010605e <sys_read+0x7a>
  return fileread(f, p, n);
80106045:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106048:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010604b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010604e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106052:	89 54 24 04          	mov    %edx,0x4(%esp)
80106056:	89 04 24             	mov    %eax,(%esp)
80106059:	e8 f6 b1 ff ff       	call   80101254 <fileread>
}
8010605e:	c9                   	leave  
8010605f:	c3                   	ret    

80106060 <sys_write>:

int
sys_write(void)
{
80106060:	55                   	push   %ebp
80106061:	89 e5                	mov    %esp,%ebp
80106063:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106066:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106069:	89 44 24 08          	mov    %eax,0x8(%esp)
8010606d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106074:	00 
80106075:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010607c:	e8 4b fe ff ff       	call   80105ecc <argfd>
80106081:	85 c0                	test   %eax,%eax
80106083:	78 35                	js     801060ba <sys_write+0x5a>
80106085:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106088:	89 44 24 04          	mov    %eax,0x4(%esp)
8010608c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106093:	e8 de fc ff ff       	call   80105d76 <argint>
80106098:	85 c0                	test   %eax,%eax
8010609a:	78 1e                	js     801060ba <sys_write+0x5a>
8010609c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010609f:	89 44 24 08          	mov    %eax,0x8(%esp)
801060a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801060aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060b1:	e8 ee fc ff ff       	call   80105da4 <argptr>
801060b6:	85 c0                	test   %eax,%eax
801060b8:	79 07                	jns    801060c1 <sys_write+0x61>
    return -1;
801060ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060bf:	eb 19                	jmp    801060da <sys_write+0x7a>
  return filewrite(f, p, n);
801060c1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801060c4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801060c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801060d2:	89 04 24             	mov    %eax,(%esp)
801060d5:	e8 36 b2 ff ff       	call   80101310 <filewrite>
}
801060da:	c9                   	leave  
801060db:	c3                   	ret    

801060dc <sys_close>:

int
sys_close(void)
{
801060dc:	55                   	push   %ebp
801060dd:	89 e5                	mov    %esp,%ebp
801060df:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801060e2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801060e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801060f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060f7:	e8 d0 fd ff ff       	call   80105ecc <argfd>
801060fc:	85 c0                	test   %eax,%eax
801060fe:	79 07                	jns    80106107 <sys_close+0x2b>
    return -1;
80106100:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106105:	eb 24                	jmp    8010612b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106107:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010610d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106110:	83 c2 08             	add    $0x8,%edx
80106113:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010611a:	00 
  fileclose(f);
8010611b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010611e:	89 04 24             	mov    %eax,(%esp)
80106121:	e8 09 b0 ff ff       	call   8010112f <fileclose>
  return 0;
80106126:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010612b:	c9                   	leave  
8010612c:	c3                   	ret    

8010612d <sys_fstat>:

int
sys_fstat(void)
{
8010612d:	55                   	push   %ebp
8010612e:	89 e5                	mov    %esp,%ebp
80106130:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106133:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106136:	89 44 24 08          	mov    %eax,0x8(%esp)
8010613a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106141:	00 
80106142:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106149:	e8 7e fd ff ff       	call   80105ecc <argfd>
8010614e:	85 c0                	test   %eax,%eax
80106150:	78 1f                	js     80106171 <sys_fstat+0x44>
80106152:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106159:	00 
8010615a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010615d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106161:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106168:	e8 37 fc ff ff       	call   80105da4 <argptr>
8010616d:	85 c0                	test   %eax,%eax
8010616f:	79 07                	jns    80106178 <sys_fstat+0x4b>
    return -1;
80106171:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106176:	eb 12                	jmp    8010618a <sys_fstat+0x5d>
  return filestat(f, st);
80106178:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010617b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010617e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106182:	89 04 24             	mov    %eax,(%esp)
80106185:	e8 7b b0 ff ff       	call   80101205 <filestat>
}
8010618a:	c9                   	leave  
8010618b:	c3                   	ret    

8010618c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010618c:	55                   	push   %ebp
8010618d:	89 e5                	mov    %esp,%ebp
8010618f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106192:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106195:	89 44 24 04          	mov    %eax,0x4(%esp)
80106199:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061a0:	e8 61 fc ff ff       	call   80105e06 <argstr>
801061a5:	85 c0                	test   %eax,%eax
801061a7:	78 17                	js     801061c0 <sys_link+0x34>
801061a9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801061ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801061b0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061b7:	e8 4a fc ff ff       	call   80105e06 <argstr>
801061bc:	85 c0                	test   %eax,%eax
801061be:	79 0a                	jns    801061ca <sys_link+0x3e>
    return -1;
801061c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c5:	e9 42 01 00 00       	jmp    8010630c <sys_link+0x180>

  begin_op();
801061ca:	e8 cb d9 ff ff       	call   80103b9a <begin_op>
  if((ip = namei(old)) == 0){
801061cf:	8b 45 d8             	mov    -0x28(%ebp),%eax
801061d2:	89 04 24             	mov    %eax,(%esp)
801061d5:	e8 f1 c3 ff ff       	call   801025cb <namei>
801061da:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061e1:	75 0f                	jne    801061f2 <sys_link+0x66>
    end_op();
801061e3:	e8 36 da ff ff       	call   80103c1e <end_op>
    return -1;
801061e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ed:	e9 1a 01 00 00       	jmp    8010630c <sys_link+0x180>
  }

  ilock(ip);
801061f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061f5:	89 04 24             	mov    %eax,(%esp)
801061f8:	e8 1d b8 ff ff       	call   80101a1a <ilock>
  if(ip->type == T_DIR){
801061fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106200:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106204:	66 83 f8 01          	cmp    $0x1,%ax
80106208:	75 1a                	jne    80106224 <sys_link+0x98>
    iunlockput(ip);
8010620a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010620d:	89 04 24             	mov    %eax,(%esp)
80106210:	e8 8f ba ff ff       	call   80101ca4 <iunlockput>
    end_op();
80106215:	e8 04 da ff ff       	call   80103c1e <end_op>
    return -1;
8010621a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010621f:	e9 e8 00 00 00       	jmp    8010630c <sys_link+0x180>
  }

  ip->nlink++;
80106224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106227:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010622b:	8d 50 01             	lea    0x1(%eax),%edx
8010622e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106231:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106238:	89 04 24             	mov    %eax,(%esp)
8010623b:	e8 18 b6 ff ff       	call   80101858 <iupdate>
  iunlock(ip);
80106240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106243:	89 04 24             	mov    %eax,(%esp)
80106246:	e8 23 b9 ff ff       	call   80101b6e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010624b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010624e:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106251:	89 54 24 04          	mov    %edx,0x4(%esp)
80106255:	89 04 24             	mov    %eax,(%esp)
80106258:	e8 90 c3 ff ff       	call   801025ed <nameiparent>
8010625d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106260:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106264:	75 02                	jne    80106268 <sys_link+0xdc>
    goto bad;
80106266:	eb 68                	jmp    801062d0 <sys_link+0x144>
  ilock(dp);
80106268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010626b:	89 04 24             	mov    %eax,(%esp)
8010626e:	e8 a7 b7 ff ff       	call   80101a1a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106273:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106276:	8b 10                	mov    (%eax),%edx
80106278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010627b:	8b 00                	mov    (%eax),%eax
8010627d:	39 c2                	cmp    %eax,%edx
8010627f:	75 20                	jne    801062a1 <sys_link+0x115>
80106281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106284:	8b 40 04             	mov    0x4(%eax),%eax
80106287:	89 44 24 08          	mov    %eax,0x8(%esp)
8010628b:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010628e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106292:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106295:	89 04 24             	mov    %eax,(%esp)
80106298:	e8 6e c0 ff ff       	call   8010230b <dirlink>
8010629d:	85 c0                	test   %eax,%eax
8010629f:	79 0d                	jns    801062ae <sys_link+0x122>
    iunlockput(dp);
801062a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a4:	89 04 24             	mov    %eax,(%esp)
801062a7:	e8 f8 b9 ff ff       	call   80101ca4 <iunlockput>
    goto bad;
801062ac:	eb 22                	jmp    801062d0 <sys_link+0x144>
  }
  iunlockput(dp);
801062ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062b1:	89 04 24             	mov    %eax,(%esp)
801062b4:	e8 eb b9 ff ff       	call   80101ca4 <iunlockput>
  iput(ip);
801062b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bc:	89 04 24             	mov    %eax,(%esp)
801062bf:	e8 0f b9 ff ff       	call   80101bd3 <iput>

  end_op();
801062c4:	e8 55 d9 ff ff       	call   80103c1e <end_op>

  return 0;
801062c9:	b8 00 00 00 00       	mov    $0x0,%eax
801062ce:	eb 3c                	jmp    8010630c <sys_link+0x180>

bad:
  ilock(ip);
801062d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d3:	89 04 24             	mov    %eax,(%esp)
801062d6:	e8 3f b7 ff ff       	call   80101a1a <ilock>
  ip->nlink--;
801062db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062de:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062e2:	8d 50 ff             	lea    -0x1(%eax),%edx
801062e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062e8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ef:	89 04 24             	mov    %eax,(%esp)
801062f2:	e8 61 b5 ff ff       	call   80101858 <iupdate>
  iunlockput(ip);
801062f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062fa:	89 04 24             	mov    %eax,(%esp)
801062fd:	e8 a2 b9 ff ff       	call   80101ca4 <iunlockput>
  end_op();
80106302:	e8 17 d9 ff ff       	call   80103c1e <end_op>
  return -1;
80106307:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010630c:	c9                   	leave  
8010630d:	c3                   	ret    

8010630e <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
8010630e:	55                   	push   %ebp
8010630f:	89 e5                	mov    %esp,%ebp
80106311:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106314:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
8010631b:	eb 4b                	jmp    80106368 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010631d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106320:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106327:	00 
80106328:	89 44 24 08          	mov    %eax,0x8(%esp)
8010632c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010632f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106333:	8b 45 08             	mov    0x8(%ebp),%eax
80106336:	89 04 24             	mov    %eax,(%esp)
80106339:	e8 ef bb ff ff       	call   80101f2d <readi>
8010633e:	83 f8 10             	cmp    $0x10,%eax
80106341:	74 0c                	je     8010634f <isdirempty+0x41>
      panic("isdirempty: readi");
80106343:	c7 04 24 eb 9f 10 80 	movl   $0x80109feb,(%esp)
8010634a:	e8 eb a1 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
8010634f:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106353:	66 85 c0             	test   %ax,%ax
80106356:	74 07                	je     8010635f <isdirempty+0x51>
      return 0;
80106358:	b8 00 00 00 00       	mov    $0x0,%eax
8010635d:	eb 1b                	jmp    8010637a <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010635f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106362:	83 c0 10             	add    $0x10,%eax
80106365:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106368:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010636b:	8b 45 08             	mov    0x8(%ebp),%eax
8010636e:	8b 40 18             	mov    0x18(%eax),%eax
80106371:	39 c2                	cmp    %eax,%edx
80106373:	72 a8                	jb     8010631d <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106375:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010637a:	c9                   	leave  
8010637b:	c3                   	ret    

8010637c <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010637c:	55                   	push   %ebp
8010637d:	89 e5                	mov    %esp,%ebp
8010637f:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106382:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106385:	89 44 24 04          	mov    %eax,0x4(%esp)
80106389:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106390:	e8 71 fa ff ff       	call   80105e06 <argstr>
80106395:	85 c0                	test   %eax,%eax
80106397:	79 0a                	jns    801063a3 <sys_unlink+0x27>
    return -1;
80106399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010639e:	e9 af 01 00 00       	jmp    80106552 <sys_unlink+0x1d6>

  begin_op();
801063a3:	e8 f2 d7 ff ff       	call   80103b9a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801063a8:	8b 45 cc             	mov    -0x34(%ebp),%eax
801063ab:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801063ae:	89 54 24 04          	mov    %edx,0x4(%esp)
801063b2:	89 04 24             	mov    %eax,(%esp)
801063b5:	e8 33 c2 ff ff       	call   801025ed <nameiparent>
801063ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063bd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063c1:	75 0f                	jne    801063d2 <sys_unlink+0x56>
    end_op();
801063c3:	e8 56 d8 ff ff       	call   80103c1e <end_op>
    return -1;
801063c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cd:	e9 80 01 00 00       	jmp    80106552 <sys_unlink+0x1d6>
  }

  ilock(dp);
801063d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d5:	89 04 24             	mov    %eax,(%esp)
801063d8:	e8 3d b6 ff ff       	call   80101a1a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801063dd:	c7 44 24 04 fd 9f 10 	movl   $0x80109ffd,0x4(%esp)
801063e4:	80 
801063e5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063e8:	89 04 24             	mov    %eax,(%esp)
801063eb:	e8 30 be ff ff       	call   80102220 <namecmp>
801063f0:	85 c0                	test   %eax,%eax
801063f2:	0f 84 45 01 00 00    	je     8010653d <sys_unlink+0x1c1>
801063f8:	c7 44 24 04 ff 9f 10 	movl   $0x80109fff,0x4(%esp)
801063ff:	80 
80106400:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106403:	89 04 24             	mov    %eax,(%esp)
80106406:	e8 15 be ff ff       	call   80102220 <namecmp>
8010640b:	85 c0                	test   %eax,%eax
8010640d:	0f 84 2a 01 00 00    	je     8010653d <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106413:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106416:	89 44 24 08          	mov    %eax,0x8(%esp)
8010641a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010641d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106421:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106424:	89 04 24             	mov    %eax,(%esp)
80106427:	e8 16 be ff ff       	call   80102242 <dirlookup>
8010642c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010642f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106433:	75 05                	jne    8010643a <sys_unlink+0xbe>
    goto bad;
80106435:	e9 03 01 00 00       	jmp    8010653d <sys_unlink+0x1c1>
  ilock(ip);
8010643a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643d:	89 04 24             	mov    %eax,(%esp)
80106440:	e8 d5 b5 ff ff       	call   80101a1a <ilock>

  if(ip->nlink < 1)
80106445:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106448:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010644c:	66 85 c0             	test   %ax,%ax
8010644f:	7f 0c                	jg     8010645d <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106451:	c7 04 24 02 a0 10 80 	movl   $0x8010a002,(%esp)
80106458:	e8 dd a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010645d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106460:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106464:	66 83 f8 01          	cmp    $0x1,%ax
80106468:	75 1f                	jne    80106489 <sys_unlink+0x10d>
8010646a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010646d:	89 04 24             	mov    %eax,(%esp)
80106470:	e8 99 fe ff ff       	call   8010630e <isdirempty>
80106475:	85 c0                	test   %eax,%eax
80106477:	75 10                	jne    80106489 <sys_unlink+0x10d>
    iunlockput(ip);
80106479:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010647c:	89 04 24             	mov    %eax,(%esp)
8010647f:	e8 20 b8 ff ff       	call   80101ca4 <iunlockput>
    goto bad;
80106484:	e9 b4 00 00 00       	jmp    8010653d <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106489:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106490:	00 
80106491:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106498:	00 
80106499:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010649c:	89 04 24             	mov    %eax,(%esp)
8010649f:	e8 90 f5 ff ff       	call   80105a34 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801064a4:	8b 45 c8             	mov    -0x38(%ebp),%eax
801064a7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801064ae:	00 
801064af:	89 44 24 08          	mov    %eax,0x8(%esp)
801064b3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801064b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801064ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bd:	89 04 24             	mov    %eax,(%esp)
801064c0:	e8 cc bb ff ff       	call   80102091 <writei>
801064c5:	83 f8 10             	cmp    $0x10,%eax
801064c8:	74 0c                	je     801064d6 <sys_unlink+0x15a>
    panic("unlink: writei");
801064ca:	c7 04 24 14 a0 10 80 	movl   $0x8010a014,(%esp)
801064d1:	e8 64 a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
801064d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064d9:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064dd:	66 83 f8 01          	cmp    $0x1,%ax
801064e1:	75 1c                	jne    801064ff <sys_unlink+0x183>
    dp->nlink--;
801064e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064e6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064ea:	8d 50 ff             	lea    -0x1(%eax),%edx
801064ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f7:	89 04 24             	mov    %eax,(%esp)
801064fa:	e8 59 b3 ff ff       	call   80101858 <iupdate>
  }
  iunlockput(dp);
801064ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106502:	89 04 24             	mov    %eax,(%esp)
80106505:	e8 9a b7 ff ff       	call   80101ca4 <iunlockput>

  ip->nlink--;
8010650a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010650d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106511:	8d 50 ff             	lea    -0x1(%eax),%edx
80106514:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106517:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010651b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010651e:	89 04 24             	mov    %eax,(%esp)
80106521:	e8 32 b3 ff ff       	call   80101858 <iupdate>
  iunlockput(ip);
80106526:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106529:	89 04 24             	mov    %eax,(%esp)
8010652c:	e8 73 b7 ff ff       	call   80101ca4 <iunlockput>

  end_op();
80106531:	e8 e8 d6 ff ff       	call   80103c1e <end_op>

  return 0;
80106536:	b8 00 00 00 00       	mov    $0x0,%eax
8010653b:	eb 15                	jmp    80106552 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
8010653d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106540:	89 04 24             	mov    %eax,(%esp)
80106543:	e8 5c b7 ff ff       	call   80101ca4 <iunlockput>
  end_op();
80106548:	e8 d1 d6 ff ff       	call   80103c1e <end_op>
  return -1;
8010654d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106552:	c9                   	leave  
80106553:	c3                   	ret    

80106554 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106554:	55                   	push   %ebp
80106555:	89 e5                	mov    %esp,%ebp
80106557:	83 ec 48             	sub    $0x48,%esp
8010655a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010655d:	8b 55 10             	mov    0x10(%ebp),%edx
80106560:	8b 45 14             	mov    0x14(%ebp),%eax
80106563:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106567:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
8010656b:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010656f:	8d 45 de             	lea    -0x22(%ebp),%eax
80106572:	89 44 24 04          	mov    %eax,0x4(%esp)
80106576:	8b 45 08             	mov    0x8(%ebp),%eax
80106579:	89 04 24             	mov    %eax,(%esp)
8010657c:	e8 6c c0 ff ff       	call   801025ed <nameiparent>
80106581:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106584:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106588:	75 0a                	jne    80106594 <create+0x40>
    return 0;
8010658a:	b8 00 00 00 00       	mov    $0x0,%eax
8010658f:	e9 7e 01 00 00       	jmp    80106712 <create+0x1be>
  ilock(dp);
80106594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106597:	89 04 24             	mov    %eax,(%esp)
8010659a:	e8 7b b4 ff ff       	call   80101a1a <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010659f:	8d 45 ec             	lea    -0x14(%ebp),%eax
801065a2:	89 44 24 08          	mov    %eax,0x8(%esp)
801065a6:	8d 45 de             	lea    -0x22(%ebp),%eax
801065a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801065ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b0:	89 04 24             	mov    %eax,(%esp)
801065b3:	e8 8a bc ff ff       	call   80102242 <dirlookup>
801065b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065bb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065bf:	74 47                	je     80106608 <create+0xb4>
    iunlockput(dp);
801065c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c4:	89 04 24             	mov    %eax,(%esp)
801065c7:	e8 d8 b6 ff ff       	call   80101ca4 <iunlockput>
    ilock(ip);
801065cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065cf:	89 04 24             	mov    %eax,(%esp)
801065d2:	e8 43 b4 ff ff       	call   80101a1a <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801065d7:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801065dc:	75 15                	jne    801065f3 <create+0x9f>
801065de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801065e5:	66 83 f8 02          	cmp    $0x2,%ax
801065e9:	75 08                	jne    801065f3 <create+0x9f>
      return ip;
801065eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ee:	e9 1f 01 00 00       	jmp    80106712 <create+0x1be>
    iunlockput(ip);
801065f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065f6:	89 04 24             	mov    %eax,(%esp)
801065f9:	e8 a6 b6 ff ff       	call   80101ca4 <iunlockput>
    return 0;
801065fe:	b8 00 00 00 00       	mov    $0x0,%eax
80106603:	e9 0a 01 00 00       	jmp    80106712 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106608:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
8010660c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010660f:	8b 00                	mov    (%eax),%eax
80106611:	89 54 24 04          	mov    %edx,0x4(%esp)
80106615:	89 04 24             	mov    %eax,(%esp)
80106618:	e8 66 b1 ff ff       	call   80101783 <ialloc>
8010661d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106620:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106624:	75 0c                	jne    80106632 <create+0xde>
    panic("create: ialloc");
80106626:	c7 04 24 23 a0 10 80 	movl   $0x8010a023,(%esp)
8010662d:	e8 08 9f ff ff       	call   8010053a <panic>

  ilock(ip);
80106632:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106635:	89 04 24             	mov    %eax,(%esp)
80106638:	e8 dd b3 ff ff       	call   80101a1a <ilock>
  ip->major = major;
8010663d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106640:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106644:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010664b:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
8010664f:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106653:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106656:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
8010665c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010665f:	89 04 24             	mov    %eax,(%esp)
80106662:	e8 f1 b1 ff ff       	call   80101858 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106667:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010666c:	75 6a                	jne    801066d8 <create+0x184>
    dp->nlink++;  // for ".."
8010666e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106671:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106675:	8d 50 01             	lea    0x1(%eax),%edx
80106678:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667b:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010667f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106682:	89 04 24             	mov    %eax,(%esp)
80106685:	e8 ce b1 ff ff       	call   80101858 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010668a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010668d:	8b 40 04             	mov    0x4(%eax),%eax
80106690:	89 44 24 08          	mov    %eax,0x8(%esp)
80106694:	c7 44 24 04 fd 9f 10 	movl   $0x80109ffd,0x4(%esp)
8010669b:	80 
8010669c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010669f:	89 04 24             	mov    %eax,(%esp)
801066a2:	e8 64 bc ff ff       	call   8010230b <dirlink>
801066a7:	85 c0                	test   %eax,%eax
801066a9:	78 21                	js     801066cc <create+0x178>
801066ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ae:	8b 40 04             	mov    0x4(%eax),%eax
801066b1:	89 44 24 08          	mov    %eax,0x8(%esp)
801066b5:	c7 44 24 04 ff 9f 10 	movl   $0x80109fff,0x4(%esp)
801066bc:	80 
801066bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066c0:	89 04 24             	mov    %eax,(%esp)
801066c3:	e8 43 bc ff ff       	call   8010230b <dirlink>
801066c8:	85 c0                	test   %eax,%eax
801066ca:	79 0c                	jns    801066d8 <create+0x184>
      panic("create dots");
801066cc:	c7 04 24 32 a0 10 80 	movl   $0x8010a032,(%esp)
801066d3:	e8 62 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
801066d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066db:	8b 40 04             	mov    0x4(%eax),%eax
801066de:	89 44 24 08          	mov    %eax,0x8(%esp)
801066e2:	8d 45 de             	lea    -0x22(%ebp),%eax
801066e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801066e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ec:	89 04 24             	mov    %eax,(%esp)
801066ef:	e8 17 bc ff ff       	call   8010230b <dirlink>
801066f4:	85 c0                	test   %eax,%eax
801066f6:	79 0c                	jns    80106704 <create+0x1b0>
    panic("create: dirlink");
801066f8:	c7 04 24 3e a0 10 80 	movl   $0x8010a03e,(%esp)
801066ff:	e8 36 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106704:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106707:	89 04 24             	mov    %eax,(%esp)
8010670a:	e8 95 b5 ff ff       	call   80101ca4 <iunlockput>

  return ip;
8010670f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106712:	c9                   	leave  
80106713:	c3                   	ret    

80106714 <sys_open>:

int
sys_open(void)
{
80106714:	55                   	push   %ebp
80106715:	89 e5                	mov    %esp,%ebp
80106717:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010671a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010671d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106721:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106728:	e8 d9 f6 ff ff       	call   80105e06 <argstr>
8010672d:	85 c0                	test   %eax,%eax
8010672f:	78 17                	js     80106748 <sys_open+0x34>
80106731:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106734:	89 44 24 04          	mov    %eax,0x4(%esp)
80106738:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010673f:	e8 32 f6 ff ff       	call   80105d76 <argint>
80106744:	85 c0                	test   %eax,%eax
80106746:	79 0a                	jns    80106752 <sys_open+0x3e>
    return -1;
80106748:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010674d:	e9 5c 01 00 00       	jmp    801068ae <sys_open+0x19a>

  begin_op();
80106752:	e8 43 d4 ff ff       	call   80103b9a <begin_op>

  if(omode & O_CREATE){
80106757:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010675a:	25 00 02 00 00       	and    $0x200,%eax
8010675f:	85 c0                	test   %eax,%eax
80106761:	74 3b                	je     8010679e <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106763:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106766:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010676d:	00 
8010676e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106775:	00 
80106776:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010677d:	00 
8010677e:	89 04 24             	mov    %eax,(%esp)
80106781:	e8 ce fd ff ff       	call   80106554 <create>
80106786:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106789:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010678d:	75 6b                	jne    801067fa <sys_open+0xe6>
      end_op();
8010678f:	e8 8a d4 ff ff       	call   80103c1e <end_op>
      return -1;
80106794:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106799:	e9 10 01 00 00       	jmp    801068ae <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010679e:	8b 45 e8             	mov    -0x18(%ebp),%eax
801067a1:	89 04 24             	mov    %eax,(%esp)
801067a4:	e8 22 be ff ff       	call   801025cb <namei>
801067a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067b0:	75 0f                	jne    801067c1 <sys_open+0xad>
      end_op();
801067b2:	e8 67 d4 ff ff       	call   80103c1e <end_op>
      return -1;
801067b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067bc:	e9 ed 00 00 00       	jmp    801068ae <sys_open+0x19a>
    }
    ilock(ip);
801067c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c4:	89 04 24             	mov    %eax,(%esp)
801067c7:	e8 4e b2 ff ff       	call   80101a1a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801067cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067cf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801067d3:	66 83 f8 01          	cmp    $0x1,%ax
801067d7:	75 21                	jne    801067fa <sys_open+0xe6>
801067d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067dc:	85 c0                	test   %eax,%eax
801067de:	74 1a                	je     801067fa <sys_open+0xe6>
      iunlockput(ip);
801067e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e3:	89 04 24             	mov    %eax,(%esp)
801067e6:	e8 b9 b4 ff ff       	call   80101ca4 <iunlockput>
      end_op();
801067eb:	e8 2e d4 ff ff       	call   80103c1e <end_op>
      return -1;
801067f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067f5:	e9 b4 00 00 00       	jmp    801068ae <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067fa:	e8 88 a8 ff ff       	call   80101087 <filealloc>
801067ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106802:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106806:	74 14                	je     8010681c <sys_open+0x108>
80106808:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010680b:	89 04 24             	mov    %eax,(%esp)
8010680e:	e8 2e f7 ff ff       	call   80105f41 <fdalloc>
80106813:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106816:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010681a:	79 28                	jns    80106844 <sys_open+0x130>
    if(f)
8010681c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106820:	74 0b                	je     8010682d <sys_open+0x119>
      fileclose(f);
80106822:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106825:	89 04 24             	mov    %eax,(%esp)
80106828:	e8 02 a9 ff ff       	call   8010112f <fileclose>
    iunlockput(ip);
8010682d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106830:	89 04 24             	mov    %eax,(%esp)
80106833:	e8 6c b4 ff ff       	call   80101ca4 <iunlockput>
    end_op();
80106838:	e8 e1 d3 ff ff       	call   80103c1e <end_op>
    return -1;
8010683d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106842:	eb 6a                	jmp    801068ae <sys_open+0x19a>
  }
  iunlock(ip);
80106844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106847:	89 04 24             	mov    %eax,(%esp)
8010684a:	e8 1f b3 ff ff       	call   80101b6e <iunlock>
  end_op();
8010684f:	e8 ca d3 ff ff       	call   80103c1e <end_op>

  f->type = FD_INODE;
80106854:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106857:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010685d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106860:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106863:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106866:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106869:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106870:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106873:	83 e0 01             	and    $0x1,%eax
80106876:	85 c0                	test   %eax,%eax
80106878:	0f 94 c0             	sete   %al
8010687b:	89 c2                	mov    %eax,%edx
8010687d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106880:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106883:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106886:	83 e0 01             	and    $0x1,%eax
80106889:	85 c0                	test   %eax,%eax
8010688b:	75 0a                	jne    80106897 <sys_open+0x183>
8010688d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106890:	83 e0 02             	and    $0x2,%eax
80106893:	85 c0                	test   %eax,%eax
80106895:	74 07                	je     8010689e <sys_open+0x18a>
80106897:	b8 01 00 00 00       	mov    $0x1,%eax
8010689c:	eb 05                	jmp    801068a3 <sys_open+0x18f>
8010689e:	b8 00 00 00 00       	mov    $0x0,%eax
801068a3:	89 c2                	mov    %eax,%edx
801068a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a8:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
801068ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801068ae:	c9                   	leave  
801068af:	c3                   	ret    

801068b0 <sys_mkdir>:

int
sys_mkdir(void)
{
801068b0:	55                   	push   %ebp
801068b1:	89 e5                	mov    %esp,%ebp
801068b3:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801068b6:	e8 df d2 ff ff       	call   80103b9a <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801068bb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801068be:	89 44 24 04          	mov    %eax,0x4(%esp)
801068c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068c9:	e8 38 f5 ff ff       	call   80105e06 <argstr>
801068ce:	85 c0                	test   %eax,%eax
801068d0:	78 2c                	js     801068fe <sys_mkdir+0x4e>
801068d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068d5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801068dc:	00 
801068dd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801068e4:	00 
801068e5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068ec:	00 
801068ed:	89 04 24             	mov    %eax,(%esp)
801068f0:	e8 5f fc ff ff       	call   80106554 <create>
801068f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068fc:	75 0c                	jne    8010690a <sys_mkdir+0x5a>
    end_op();
801068fe:	e8 1b d3 ff ff       	call   80103c1e <end_op>
    return -1;
80106903:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106908:	eb 15                	jmp    8010691f <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010690a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010690d:	89 04 24             	mov    %eax,(%esp)
80106910:	e8 8f b3 ff ff       	call   80101ca4 <iunlockput>
  end_op();
80106915:	e8 04 d3 ff ff       	call   80103c1e <end_op>
  return 0;
8010691a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010691f:	c9                   	leave  
80106920:	c3                   	ret    

80106921 <sys_mknod>:

int
sys_mknod(void)
{
80106921:	55                   	push   %ebp
80106922:	89 e5                	mov    %esp,%ebp
80106924:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106927:	e8 6e d2 ff ff       	call   80103b9a <begin_op>
  if((len=argstr(0, &path)) < 0 ||
8010692c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010692f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106933:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010693a:	e8 c7 f4 ff ff       	call   80105e06 <argstr>
8010693f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106942:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106946:	78 5e                	js     801069a6 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106948:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010694b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010694f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106956:	e8 1b f4 ff ff       	call   80105d76 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
8010695b:	85 c0                	test   %eax,%eax
8010695d:	78 47                	js     801069a6 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010695f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106962:	89 44 24 04          	mov    %eax,0x4(%esp)
80106966:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010696d:	e8 04 f4 ff ff       	call   80105d76 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106972:	85 c0                	test   %eax,%eax
80106974:	78 30                	js     801069a6 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106976:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106979:	0f bf c8             	movswl %ax,%ecx
8010697c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010697f:	0f bf d0             	movswl %ax,%edx
80106982:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106985:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106989:	89 54 24 08          	mov    %edx,0x8(%esp)
8010698d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106994:	00 
80106995:	89 04 24             	mov    %eax,(%esp)
80106998:	e8 b7 fb ff ff       	call   80106554 <create>
8010699d:	89 45 f0             	mov    %eax,-0x10(%ebp)
801069a0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801069a4:	75 0c                	jne    801069b2 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801069a6:	e8 73 d2 ff ff       	call   80103c1e <end_op>
    return -1;
801069ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069b0:	eb 15                	jmp    801069c7 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801069b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069b5:	89 04 24             	mov    %eax,(%esp)
801069b8:	e8 e7 b2 ff ff       	call   80101ca4 <iunlockput>
  end_op();
801069bd:	e8 5c d2 ff ff       	call   80103c1e <end_op>
  return 0;
801069c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069c7:	c9                   	leave  
801069c8:	c3                   	ret    

801069c9 <sys_chdir>:

int
sys_chdir(void)
{
801069c9:	55                   	push   %ebp
801069ca:	89 e5                	mov    %esp,%ebp
801069cc:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801069cf:	e8 c6 d1 ff ff       	call   80103b9a <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801069d4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801069d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801069db:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069e2:	e8 1f f4 ff ff       	call   80105e06 <argstr>
801069e7:	85 c0                	test   %eax,%eax
801069e9:	78 14                	js     801069ff <sys_chdir+0x36>
801069eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069ee:	89 04 24             	mov    %eax,(%esp)
801069f1:	e8 d5 bb ff ff       	call   801025cb <namei>
801069f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069fd:	75 0c                	jne    80106a0b <sys_chdir+0x42>
    end_op();
801069ff:	e8 1a d2 ff ff       	call   80103c1e <end_op>
    return -1;
80106a04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a09:	eb 61                	jmp    80106a6c <sys_chdir+0xa3>
  }
  ilock(ip);
80106a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a0e:	89 04 24             	mov    %eax,(%esp)
80106a11:	e8 04 b0 ff ff       	call   80101a1a <ilock>
  if(ip->type != T_DIR){
80106a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a19:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a1d:	66 83 f8 01          	cmp    $0x1,%ax
80106a21:	74 17                	je     80106a3a <sys_chdir+0x71>
    iunlockput(ip);
80106a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a26:	89 04 24             	mov    %eax,(%esp)
80106a29:	e8 76 b2 ff ff       	call   80101ca4 <iunlockput>
    end_op();
80106a2e:	e8 eb d1 ff ff       	call   80103c1e <end_op>
    return -1;
80106a33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a38:	eb 32                	jmp    80106a6c <sys_chdir+0xa3>
  }
  iunlock(ip);
80106a3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a3d:	89 04 24             	mov    %eax,(%esp)
80106a40:	e8 29 b1 ff ff       	call   80101b6e <iunlock>
  iput(proc->cwd);
80106a45:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a4b:	8b 40 68             	mov    0x68(%eax),%eax
80106a4e:	89 04 24             	mov    %eax,(%esp)
80106a51:	e8 7d b1 ff ff       	call   80101bd3 <iput>
  end_op();
80106a56:	e8 c3 d1 ff ff       	call   80103c1e <end_op>
  proc->cwd = ip;
80106a5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a61:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a64:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a67:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a6c:	c9                   	leave  
80106a6d:	c3                   	ret    

80106a6e <sys_exec>:

int
sys_exec(void)
{
80106a6e:	55                   	push   %ebp
80106a6f:	89 e5                	mov    %esp,%ebp
80106a71:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a77:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a7a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a7e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a85:	e8 7c f3 ff ff       	call   80105e06 <argstr>
80106a8a:	85 c0                	test   %eax,%eax
80106a8c:	78 1a                	js     80106aa8 <sys_exec+0x3a>
80106a8e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a94:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a98:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a9f:	e8 d2 f2 ff ff       	call   80105d76 <argint>
80106aa4:	85 c0                	test   %eax,%eax
80106aa6:	79 0a                	jns    80106ab2 <sys_exec+0x44>
    return -1;
80106aa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106aad:	e9 c8 00 00 00       	jmp    80106b7a <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106ab2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106ab9:	00 
80106aba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ac1:	00 
80106ac2:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106ac8:	89 04 24             	mov    %eax,(%esp)
80106acb:	e8 64 ef ff ff       	call   80105a34 <memset>
  for(i=0;; i++){
80106ad0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ada:	83 f8 1f             	cmp    $0x1f,%eax
80106add:	76 0a                	jbe    80106ae9 <sys_exec+0x7b>
      return -1;
80106adf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae4:	e9 91 00 00 00       	jmp    80106b7a <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aec:	c1 e0 02             	shl    $0x2,%eax
80106aef:	89 c2                	mov    %eax,%edx
80106af1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106af7:	01 c2                	add    %eax,%edx
80106af9:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106aff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b03:	89 14 24             	mov    %edx,(%esp)
80106b06:	e8 cf f1 ff ff       	call   80105cda <fetchint>
80106b0b:	85 c0                	test   %eax,%eax
80106b0d:	79 07                	jns    80106b16 <sys_exec+0xa8>
      return -1;
80106b0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b14:	eb 64                	jmp    80106b7a <sys_exec+0x10c>
    if(uarg == 0){
80106b16:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b1c:	85 c0                	test   %eax,%eax
80106b1e:	75 26                	jne    80106b46 <sys_exec+0xd8>
      argv[i] = 0;
80106b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b23:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106b2a:	00 00 00 00 
      break;
80106b2e:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b32:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106b38:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b3c:	89 04 24             	mov    %eax,(%esp)
80106b3f:	e8 c6 9f ff ff       	call   80100b0a <exec>
80106b44:	eb 34                	jmp    80106b7a <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106b46:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b4f:	c1 e2 02             	shl    $0x2,%edx
80106b52:	01 c2                	add    %eax,%edx
80106b54:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b5e:	89 04 24             	mov    %eax,(%esp)
80106b61:	e8 ae f1 ff ff       	call   80105d14 <fetchstr>
80106b66:	85 c0                	test   %eax,%eax
80106b68:	79 07                	jns    80106b71 <sys_exec+0x103>
      return -1;
80106b6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b6f:	eb 09                	jmp    80106b7a <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b71:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b75:	e9 5d ff ff ff       	jmp    80106ad7 <sys_exec+0x69>
  return exec(path, argv);
}
80106b7a:	c9                   	leave  
80106b7b:	c3                   	ret    

80106b7c <sys_pipe>:

int
sys_pipe(void)
{
80106b7c:	55                   	push   %ebp
80106b7d:	89 e5                	mov    %esp,%ebp
80106b7f:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b82:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b89:	00 
80106b8a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b98:	e8 07 f2 ff ff       	call   80105da4 <argptr>
80106b9d:	85 c0                	test   %eax,%eax
80106b9f:	79 0a                	jns    80106bab <sys_pipe+0x2f>
    return -1;
80106ba1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba6:	e9 9b 00 00 00       	jmp    80106c46 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106bab:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106bae:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bb2:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106bb5:	89 04 24             	mov    %eax,(%esp)
80106bb8:	e8 e9 da ff ff       	call   801046a6 <pipealloc>
80106bbd:	85 c0                	test   %eax,%eax
80106bbf:	79 07                	jns    80106bc8 <sys_pipe+0x4c>
    return -1;
80106bc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bc6:	eb 7e                	jmp    80106c46 <sys_pipe+0xca>
  fd0 = -1;
80106bc8:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106bcf:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bd2:	89 04 24             	mov    %eax,(%esp)
80106bd5:	e8 67 f3 ff ff       	call   80105f41 <fdalloc>
80106bda:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bdd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106be1:	78 14                	js     80106bf7 <sys_pipe+0x7b>
80106be3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106be6:	89 04 24             	mov    %eax,(%esp)
80106be9:	e8 53 f3 ff ff       	call   80105f41 <fdalloc>
80106bee:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bf1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bf5:	79 37                	jns    80106c2e <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bf7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bfb:	78 14                	js     80106c11 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bfd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c03:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c06:	83 c2 08             	add    $0x8,%edx
80106c09:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106c10:	00 
    fileclose(rf);
80106c11:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106c14:	89 04 24             	mov    %eax,(%esp)
80106c17:	e8 13 a5 ff ff       	call   8010112f <fileclose>
    fileclose(wf);
80106c1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c1f:	89 04 24             	mov    %eax,(%esp)
80106c22:	e8 08 a5 ff ff       	call   8010112f <fileclose>
    return -1;
80106c27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c2c:	eb 18                	jmp    80106c46 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106c2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c31:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c34:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106c36:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c39:	8d 50 04             	lea    0x4(%eax),%edx
80106c3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c3f:	89 02                	mov    %eax,(%edx)
  return 0;
80106c41:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c46:	c9                   	leave  
80106c47:	c3                   	ret    

80106c48 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c48:	55                   	push   %ebp
80106c49:	89 e5                	mov    %esp,%ebp
80106c4b:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c4e:	e8 36 e2 ff ff       	call   80104e89 <fork>
}
80106c53:	c9                   	leave  
80106c54:	c3                   	ret    

80106c55 <sys_exit>:

int
sys_exit(void)
{
80106c55:	55                   	push   %ebp
80106c56:	89 e5                	mov    %esp,%ebp
80106c58:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c5b:	e8 29 e4 ff ff       	call   80105089 <exit>
  return 0;  // not reached
80106c60:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c65:	c9                   	leave  
80106c66:	c3                   	ret    

80106c67 <sys_wait>:

int
sys_wait(void)
{
80106c67:	55                   	push   %ebp
80106c68:	89 e5                	mov    %esp,%ebp
80106c6a:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c6d:	e8 4f e5 ff ff       	call   801051c1 <wait>
}
80106c72:	c9                   	leave  
80106c73:	c3                   	ret    

80106c74 <sys_kill>:

int
sys_kill(void)
{
80106c74:	55                   	push   %ebp
80106c75:	89 e5                	mov    %esp,%ebp
80106c77:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c88:	e8 e9 f0 ff ff       	call   80105d76 <argint>
80106c8d:	85 c0                	test   %eax,%eax
80106c8f:	79 07                	jns    80106c98 <sys_kill+0x24>
    return -1;
80106c91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c96:	eb 0b                	jmp    80106ca3 <sys_kill+0x2f>
  return kill(pid);
80106c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c9b:	89 04 24             	mov    %eax,(%esp)
80106c9e:	e8 fc e8 ff ff       	call   8010559f <kill>
}
80106ca3:	c9                   	leave  
80106ca4:	c3                   	ret    

80106ca5 <sys_getpid>:

int
sys_getpid(void)
{
80106ca5:	55                   	push   %ebp
80106ca6:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106ca8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cae:	8b 40 10             	mov    0x10(%eax),%eax
}
80106cb1:	5d                   	pop    %ebp
80106cb2:	c3                   	ret    

80106cb3 <sys_sbrk>:

int
sys_sbrk(void)
{
80106cb3:	55                   	push   %ebp
80106cb4:	89 e5                	mov    %esp,%ebp
80106cb6:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106cb9:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cc0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cc7:	e8 aa f0 ff ff       	call   80105d76 <argint>
80106ccc:	85 c0                	test   %eax,%eax
80106cce:	79 07                	jns    80106cd7 <sys_sbrk+0x24>
    return -1;
80106cd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cd5:	eb 24                	jmp    80106cfb <sys_sbrk+0x48>
  addr = proc->sz;
80106cd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cdd:	8b 00                	mov    (%eax),%eax
80106cdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106ce2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ce5:	89 04 24             	mov    %eax,(%esp)
80106ce8:	e8 e1 e0 ff ff       	call   80104dce <growproc>
80106ced:	85 c0                	test   %eax,%eax
80106cef:	79 07                	jns    80106cf8 <sys_sbrk+0x45>
    return -1;
80106cf1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cf6:	eb 03                	jmp    80106cfb <sys_sbrk+0x48>
  return addr;
80106cf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cfb:	c9                   	leave  
80106cfc:	c3                   	ret    

80106cfd <sys_sleep>:

int
sys_sleep(void)
{
80106cfd:	55                   	push   %ebp
80106cfe:	89 e5                	mov    %esp,%ebp
80106d00:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106d03:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106d06:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d11:	e8 60 f0 ff ff       	call   80105d76 <argint>
80106d16:	85 c0                	test   %eax,%eax
80106d18:	79 07                	jns    80106d21 <sys_sleep+0x24>
    return -1;
80106d1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d1f:	eb 6c                	jmp    80106d8d <sys_sleep+0x90>
  acquire(&tickslock);
80106d21:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106d28:	e8 b3 ea ff ff       	call   801057e0 <acquire>
  ticks0 = ticks;
80106d2d:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106d32:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106d35:	eb 34                	jmp    80106d6b <sys_sleep+0x6e>
    if(proc->killed){
80106d37:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d3d:	8b 40 24             	mov    0x24(%eax),%eax
80106d40:	85 c0                	test   %eax,%eax
80106d42:	74 13                	je     80106d57 <sys_sleep+0x5a>
      release(&tickslock);
80106d44:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106d4b:	e8 f2 ea ff ff       	call   80105842 <release>
      return -1;
80106d50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d55:	eb 36                	jmp    80106d8d <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d57:	c7 44 24 04 c0 05 12 	movl   $0x801205c0,0x4(%esp)
80106d5e:	80 
80106d5f:	c7 04 24 00 0e 12 80 	movl   $0x80120e00,(%esp)
80106d66:	e8 2d e7 ff ff       	call   80105498 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d6b:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106d70:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d73:	89 c2                	mov    %eax,%edx
80106d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d78:	39 c2                	cmp    %eax,%edx
80106d7a:	72 bb                	jb     80106d37 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d7c:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106d83:	e8 ba ea ff ff       	call   80105842 <release>
  return 0;
80106d88:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d8d:	c9                   	leave  
80106d8e:	c3                   	ret    

80106d8f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d8f:	55                   	push   %ebp
80106d90:	89 e5                	mov    %esp,%ebp
80106d92:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d95:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106d9c:	e8 3f ea ff ff       	call   801057e0 <acquire>
  xticks = ticks;
80106da1:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106da9:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106db0:	e8 8d ea ff ff       	call   80105842 <release>
  return xticks;
80106db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db8:	c9                   	leave  
80106db9:	c3                   	ret    

80106dba <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106dba:	55                   	push   %ebp
80106dbb:	89 e5                	mov    %esp,%ebp
80106dbd:	83 ec 08             	sub    $0x8,%esp
80106dc0:	8b 55 08             	mov    0x8(%ebp),%edx
80106dc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80106dc6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106dca:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106dcd:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106dd1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106dd5:	ee                   	out    %al,(%dx)
}
80106dd6:	c9                   	leave  
80106dd7:	c3                   	ret    

80106dd8 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106dd8:	55                   	push   %ebp
80106dd9:	89 e5                	mov    %esp,%ebp
80106ddb:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106dde:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106de5:	00 
80106de6:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106ded:	e8 c8 ff ff ff       	call   80106dba <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106df2:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106df9:	00 
80106dfa:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106e01:	e8 b4 ff ff ff       	call   80106dba <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106e06:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106e0d:	00 
80106e0e:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106e15:	e8 a0 ff ff ff       	call   80106dba <outb>
  picenable(IRQ_TIMER);
80106e1a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e21:	e8 13 d7 ff ff       	call   80104539 <picenable>
}
80106e26:	c9                   	leave  
80106e27:	c3                   	ret    

80106e28 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106e28:	1e                   	push   %ds
  pushl %es
80106e29:	06                   	push   %es
  pushl %fs
80106e2a:	0f a0                	push   %fs
  pushl %gs
80106e2c:	0f a8                	push   %gs
  pushal
80106e2e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106e2f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106e33:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e35:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e37:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e3b:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e3d:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e3f:	54                   	push   %esp
  call trap
80106e40:	e8 d8 01 00 00       	call   8010701d <trap>
  addl $4, %esp
80106e45:	83 c4 04             	add    $0x4,%esp

80106e48 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e48:	61                   	popa   
  popl %gs
80106e49:	0f a9                	pop    %gs
  popl %fs
80106e4b:	0f a1                	pop    %fs
  popl %es
80106e4d:	07                   	pop    %es
  popl %ds
80106e4e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e4f:	83 c4 08             	add    $0x8,%esp
  iret
80106e52:	cf                   	iret   

80106e53 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e53:	55                   	push   %ebp
80106e54:	89 e5                	mov    %esp,%ebp
80106e56:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e59:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e5c:	83 e8 01             	sub    $0x1,%eax
80106e5f:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e63:	8b 45 08             	mov    0x8(%ebp),%eax
80106e66:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e6a:	8b 45 08             	mov    0x8(%ebp),%eax
80106e6d:	c1 e8 10             	shr    $0x10,%eax
80106e70:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e74:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e77:	0f 01 18             	lidtl  (%eax)
}
80106e7a:	c9                   	leave  
80106e7b:	c3                   	ret    

80106e7c <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e7c:	55                   	push   %ebp
80106e7d:	89 e5                	mov    %esp,%ebp
80106e7f:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e82:	0f 20 d0             	mov    %cr2,%eax
80106e85:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e88:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e8b:	c9                   	leave  
80106e8c:	c3                   	ret    

80106e8d <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e8d:	55                   	push   %ebp
80106e8e:	89 e5                	mov    %esp,%ebp
80106e90:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e93:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e9a:	e9 c3 00 00 00       	jmp    80106f62 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea2:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106ea9:	89 c2                	mov    %eax,%edx
80106eab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eae:	66 89 14 c5 00 06 12 	mov    %dx,-0x7fedfa00(,%eax,8)
80106eb5:	80 
80106eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb9:	66 c7 04 c5 02 06 12 	movw   $0x8,-0x7fedf9fe(,%eax,8)
80106ec0:	80 08 00 
80106ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ec6:	0f b6 14 c5 04 06 12 	movzbl -0x7fedf9fc(,%eax,8),%edx
80106ecd:	80 
80106ece:	83 e2 e0             	and    $0xffffffe0,%edx
80106ed1:	88 14 c5 04 06 12 80 	mov    %dl,-0x7fedf9fc(,%eax,8)
80106ed8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106edb:	0f b6 14 c5 04 06 12 	movzbl -0x7fedf9fc(,%eax,8),%edx
80106ee2:	80 
80106ee3:	83 e2 1f             	and    $0x1f,%edx
80106ee6:	88 14 c5 04 06 12 80 	mov    %dl,-0x7fedf9fc(,%eax,8)
80106eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef0:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106ef7:	80 
80106ef8:	83 e2 f0             	and    $0xfffffff0,%edx
80106efb:	83 ca 0e             	or     $0xe,%edx
80106efe:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106f05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f08:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106f0f:	80 
80106f10:	83 e2 ef             	and    $0xffffffef,%edx
80106f13:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1d:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106f24:	80 
80106f25:	83 e2 9f             	and    $0xffffff9f,%edx
80106f28:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106f2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f32:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106f39:	80 
80106f3a:	83 ca 80             	or     $0xffffff80,%edx
80106f3d:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106f44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f47:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f4e:	c1 e8 10             	shr    $0x10,%eax
80106f51:	89 c2                	mov    %eax,%edx
80106f53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f56:	66 89 14 c5 06 06 12 	mov    %dx,-0x7fedf9fa(,%eax,8)
80106f5d:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f5e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f62:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f69:	0f 8e 30 ff ff ff    	jle    80106e9f <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f6f:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f74:	66 a3 00 08 12 80    	mov    %ax,0x80120800
80106f7a:	66 c7 05 02 08 12 80 	movw   $0x8,0x80120802
80106f81:	08 00 
80106f83:	0f b6 05 04 08 12 80 	movzbl 0x80120804,%eax
80106f8a:	83 e0 e0             	and    $0xffffffe0,%eax
80106f8d:	a2 04 08 12 80       	mov    %al,0x80120804
80106f92:	0f b6 05 04 08 12 80 	movzbl 0x80120804,%eax
80106f99:	83 e0 1f             	and    $0x1f,%eax
80106f9c:	a2 04 08 12 80       	mov    %al,0x80120804
80106fa1:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80106fa8:	83 c8 0f             	or     $0xf,%eax
80106fab:	a2 05 08 12 80       	mov    %al,0x80120805
80106fb0:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80106fb7:	83 e0 ef             	and    $0xffffffef,%eax
80106fba:	a2 05 08 12 80       	mov    %al,0x80120805
80106fbf:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80106fc6:	83 c8 60             	or     $0x60,%eax
80106fc9:	a2 05 08 12 80       	mov    %al,0x80120805
80106fce:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80106fd5:	83 c8 80             	or     $0xffffff80,%eax
80106fd8:	a2 05 08 12 80       	mov    %al,0x80120805
80106fdd:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106fe2:	c1 e8 10             	shr    $0x10,%eax
80106fe5:	66 a3 06 08 12 80    	mov    %ax,0x80120806
  
  initlock(&tickslock, "time");
80106feb:	c7 44 24 04 50 a0 10 	movl   $0x8010a050,0x4(%esp)
80106ff2:	80 
80106ff3:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106ffa:	e8 c0 e7 ff ff       	call   801057bf <initlock>
}
80106fff:	c9                   	leave  
80107000:	c3                   	ret    

80107001 <idtinit>:

void
idtinit(void)
{
80107001:	55                   	push   %ebp
80107002:	89 e5                	mov    %esp,%ebp
80107004:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107007:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010700e:	00 
8010700f:	c7 04 24 00 06 12 80 	movl   $0x80120600,(%esp)
80107016:	e8 38 fe ff ff       	call   80106e53 <lidt>
}
8010701b:	c9                   	leave  
8010701c:	c3                   	ret    

8010701d <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010701d:	55                   	push   %ebp
8010701e:	89 e5                	mov    %esp,%ebp
80107020:	57                   	push   %edi
80107021:	56                   	push   %esi
80107022:	53                   	push   %ebx
80107023:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107026:	8b 45 08             	mov    0x8(%ebp),%eax
80107029:	8b 40 30             	mov    0x30(%eax),%eax
8010702c:	83 f8 40             	cmp    $0x40,%eax
8010702f:	75 3f                	jne    80107070 <trap+0x53>
    if(proc->killed)
80107031:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107037:	8b 40 24             	mov    0x24(%eax),%eax
8010703a:	85 c0                	test   %eax,%eax
8010703c:	74 05                	je     80107043 <trap+0x26>
      exit();
8010703e:	e8 46 e0 ff ff       	call   80105089 <exit>
    proc->tf = tf;
80107043:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107049:	8b 55 08             	mov    0x8(%ebp),%edx
8010704c:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010704f:	e8 e9 ed ff ff       	call   80105e3d <syscall>
    if(proc->killed)
80107054:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010705a:	8b 40 24             	mov    0x24(%eax),%eax
8010705d:	85 c0                	test   %eax,%eax
8010705f:	74 0a                	je     8010706b <trap+0x4e>
      exit();
80107061:	e8 23 e0 ff ff       	call   80105089 <exit>
    return;
80107066:	e9 d3 02 00 00       	jmp    8010733e <trap+0x321>
8010706b:	e9 ce 02 00 00       	jmp    8010733e <trap+0x321>
  }
  switch(tf->trapno){
80107070:	8b 45 08             	mov    0x8(%ebp),%eax
80107073:	8b 40 30             	mov    0x30(%eax),%eax
80107076:	83 e8 0e             	sub    $0xe,%eax
80107079:	83 f8 31             	cmp    $0x31,%eax
8010707c:	0f 87 54 01 00 00    	ja     801071d6 <trap+0x1b9>
80107082:	8b 04 85 50 a1 10 80 	mov    -0x7fef5eb0(,%eax,4),%eax
80107089:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010708b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107091:	0f b6 00             	movzbl (%eax),%eax
80107094:	84 c0                	test   %al,%al
80107096:	75 31                	jne    801070c9 <trap+0xac>
      acquire(&tickslock);
80107098:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
8010709f:	e8 3c e7 ff ff       	call   801057e0 <acquire>
      ticks++;
801070a4:	a1 00 0e 12 80       	mov    0x80120e00,%eax
801070a9:	83 c0 01             	add    $0x1,%eax
801070ac:	a3 00 0e 12 80       	mov    %eax,0x80120e00
      wakeup(&ticks);
801070b1:	c7 04 24 00 0e 12 80 	movl   $0x80120e00,(%esp)
801070b8:	e8 b7 e4 ff ff       	call   80105574 <wakeup>
      release(&tickslock);
801070bd:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
801070c4:	e8 79 e7 ff ff       	call   80105842 <release>
    }
    lapiceoi();
801070c9:	e8 96 c5 ff ff       	call   80103664 <lapiceoi>
    break;
801070ce:	e9 d9 01 00 00       	jmp    801072ac <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801070d3:	e8 2b bd ff ff       	call   80102e03 <ideintr>
    lapiceoi();
801070d8:	e8 87 c5 ff ff       	call   80103664 <lapiceoi>
    break;
801070dd:	e9 ca 01 00 00       	jmp    801072ac <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070e2:	e8 4c c3 ff ff       	call   80103433 <kbdintr>
    lapiceoi();
801070e7:	e8 78 c5 ff ff       	call   80103664 <lapiceoi>
    break;
801070ec:	e9 bb 01 00 00       	jmp    801072ac <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070f1:	e8 3d 04 00 00       	call   80107533 <uartintr>
    lapiceoi();
801070f6:	e8 69 c5 ff ff       	call   80103664 <lapiceoi>
    break;
801070fb:	e9 ac 01 00 00       	jmp    801072ac <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107100:	8b 45 08             	mov    0x8(%ebp),%eax
80107103:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107106:	8b 45 08             	mov    0x8(%ebp),%eax
80107109:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010710d:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107110:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107116:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107119:	0f b6 c0             	movzbl %al,%eax
8010711c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107120:	89 54 24 08          	mov    %edx,0x8(%esp)
80107124:	89 44 24 04          	mov    %eax,0x4(%esp)
80107128:	c7 04 24 58 a0 10 80 	movl   $0x8010a058,(%esp)
8010712f:	e8 6c 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107134:	e8 2b c5 ff ff       	call   80103664 <lapiceoi>
    break;
80107139:	e9 6e 01 00 00       	jmp    801072ac <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
8010713e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107144:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
8010714a:	83 c2 01             	add    $0x1,%edx
8010714d:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
80107153:	e8 24 fd ff ff       	call   80106e7c <rcr2>
80107158:	05 ff 0f 00 00       	add    $0xfff,%eax
8010715d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107162:	89 c6                	mov    %eax,%esi
80107164:	e8 13 fd ff ff       	call   80106e7c <rcr2>
80107169:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010716e:	89 c3                	mov    %eax,%ebx
80107170:	e8 07 fd ff ff       	call   80106e7c <rcr2>
80107175:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010717c:	8b 52 10             	mov    0x10(%edx),%edx
8010717f:	89 74 24 10          	mov    %esi,0x10(%esp)
80107183:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107187:	89 44 24 08          	mov    %eax,0x8(%esp)
8010718b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010718f:	c7 04 24 7c a0 10 80 	movl   $0x8010a07c,(%esp)
80107196:	e8 05 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
8010719b:	e8 dc fc ff ff       	call   80106e7c <rcr2>
801071a0:	89 04 24             	mov    %eax,(%esp)
801071a3:	e8 eb 21 00 00       	call   80109393 <existOnDisc>
801071a8:	85 c0                	test   %eax,%eax
801071aa:	74 2a                	je     801071d6 <trap+0x1b9>
      cprintf("found on disk, recovering\n");
801071ac:	c7 04 24 ab a0 10 80 	movl   $0x8010a0ab,(%esp)
801071b3:	e8 e8 91 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
801071b8:	e8 bf fc ff ff       	call   80106e7c <rcr2>
801071bd:	89 04 24             	mov    %eax,(%esp)
801071c0:	e8 ba 22 00 00       	call   8010947f <fixPage>
      cprintf("recovered!\n");
801071c5:	c7 04 24 c6 a0 10 80 	movl   $0x8010a0c6,(%esp)
801071cc:	e8 cf 91 ff ff       	call   801003a0 <cprintf>
      break;
801071d1:	e9 d6 00 00 00       	jmp    801072ac <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801071d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071dc:	85 c0                	test   %eax,%eax
801071de:	74 11                	je     801071f1 <trap+0x1d4>
801071e0:	8b 45 08             	mov    0x8(%ebp),%eax
801071e3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071e7:	0f b7 c0             	movzwl %ax,%eax
801071ea:	83 e0 03             	and    $0x3,%eax
801071ed:	85 c0                	test   %eax,%eax
801071ef:	75 46                	jne    80107237 <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071f1:	e8 86 fc ff ff       	call   80106e7c <rcr2>
801071f6:	8b 55 08             	mov    0x8(%ebp),%edx
801071f9:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801071fc:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107203:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107206:	0f b6 ca             	movzbl %dl,%ecx
80107209:	8b 55 08             	mov    0x8(%ebp),%edx
8010720c:	8b 52 30             	mov    0x30(%edx),%edx
8010720f:	89 44 24 10          	mov    %eax,0x10(%esp)
80107213:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107217:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010721b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010721f:	c7 04 24 d4 a0 10 80 	movl   $0x8010a0d4,(%esp)
80107226:	e8 75 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010722b:	c7 04 24 06 a1 10 80 	movl   $0x8010a106,(%esp)
80107232:	e8 03 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107237:	e8 40 fc ff ff       	call   80106e7c <rcr2>
8010723c:	89 c2                	mov    %eax,%edx
8010723e:	8b 45 08             	mov    0x8(%ebp),%eax
80107241:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107244:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010724a:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010724d:	0f b6 f0             	movzbl %al,%esi
80107250:	8b 45 08             	mov    0x8(%ebp),%eax
80107253:	8b 58 34             	mov    0x34(%eax),%ebx
80107256:	8b 45 08             	mov    0x8(%ebp),%eax
80107259:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010725c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107262:	83 c0 6c             	add    $0x6c,%eax
80107265:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107268:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010726e:	8b 40 10             	mov    0x10(%eax),%eax
80107271:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107275:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107279:	89 74 24 14          	mov    %esi,0x14(%esp)
8010727d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107281:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107285:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80107288:	89 7c 24 08          	mov    %edi,0x8(%esp)
8010728c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107290:	c7 04 24 0c a1 10 80 	movl   $0x8010a10c,(%esp)
80107297:	e8 04 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010729c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072a2:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801072a9:	eb 01                	jmp    801072ac <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801072ab:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b2:	85 c0                	test   %eax,%eax
801072b4:	74 24                	je     801072da <trap+0x2bd>
801072b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072bc:	8b 40 24             	mov    0x24(%eax),%eax
801072bf:	85 c0                	test   %eax,%eax
801072c1:	74 17                	je     801072da <trap+0x2bd>
801072c3:	8b 45 08             	mov    0x8(%ebp),%eax
801072c6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072ca:	0f b7 c0             	movzwl %ax,%eax
801072cd:	83 e0 03             	and    $0x3,%eax
801072d0:	83 f8 03             	cmp    $0x3,%eax
801072d3:	75 05                	jne    801072da <trap+0x2bd>
    exit();
801072d5:	e8 af dd ff ff       	call   80105089 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
801072da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072e0:	85 c0                	test   %eax,%eax
801072e2:	74 2c                	je     80107310 <trap+0x2f3>
801072e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072ea:	8b 40 0c             	mov    0xc(%eax),%eax
801072ed:	83 f8 04             	cmp    $0x4,%eax
801072f0:	75 1e                	jne    80107310 <trap+0x2f3>
801072f2:	8b 45 08             	mov    0x8(%ebp),%eax
801072f5:	8b 40 30             	mov    0x30(%eax),%eax
801072f8:	83 f8 20             	cmp    $0x20,%eax
801072fb:	75 13                	jne    80107310 <trap+0x2f3>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4){
      updateAge(proc);
801072fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107303:	89 04 24             	mov    %eax,(%esp)
80107306:	e8 5a 26 00 00       	call   80109965 <updateAge>
    } 
    yield();
8010730b:	e8 17 e1 ff ff       	call   80105427 <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107310:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107316:	85 c0                	test   %eax,%eax
80107318:	74 24                	je     8010733e <trap+0x321>
8010731a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107320:	8b 40 24             	mov    0x24(%eax),%eax
80107323:	85 c0                	test   %eax,%eax
80107325:	74 17                	je     8010733e <trap+0x321>
80107327:	8b 45 08             	mov    0x8(%ebp),%eax
8010732a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010732e:	0f b7 c0             	movzwl %ax,%eax
80107331:	83 e0 03             	and    $0x3,%eax
80107334:	83 f8 03             	cmp    $0x3,%eax
80107337:	75 05                	jne    8010733e <trap+0x321>
    exit();
80107339:	e8 4b dd ff ff       	call   80105089 <exit>
}
8010733e:	83 c4 3c             	add    $0x3c,%esp
80107341:	5b                   	pop    %ebx
80107342:	5e                   	pop    %esi
80107343:	5f                   	pop    %edi
80107344:	5d                   	pop    %ebp
80107345:	c3                   	ret    

80107346 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107346:	55                   	push   %ebp
80107347:	89 e5                	mov    %esp,%ebp
80107349:	83 ec 14             	sub    $0x14,%esp
8010734c:	8b 45 08             	mov    0x8(%ebp),%eax
8010734f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107353:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107357:	89 c2                	mov    %eax,%edx
80107359:	ec                   	in     (%dx),%al
8010735a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010735d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107361:	c9                   	leave  
80107362:	c3                   	ret    

80107363 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107363:	55                   	push   %ebp
80107364:	89 e5                	mov    %esp,%ebp
80107366:	83 ec 08             	sub    $0x8,%esp
80107369:	8b 55 08             	mov    0x8(%ebp),%edx
8010736c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010736f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107373:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107376:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010737a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010737e:	ee                   	out    %al,(%dx)
}
8010737f:	c9                   	leave  
80107380:	c3                   	ret    

80107381 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107381:	55                   	push   %ebp
80107382:	89 e5                	mov    %esp,%ebp
80107384:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107387:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010738e:	00 
8010738f:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107396:	e8 c8 ff ff ff       	call   80107363 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010739b:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801073a2:	00 
801073a3:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073aa:	e8 b4 ff ff ff       	call   80107363 <outb>
  outb(COM1+0, 115200/9600);
801073af:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801073b6:	00 
801073b7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801073be:	e8 a0 ff ff ff       	call   80107363 <outb>
  outb(COM1+1, 0);
801073c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073ca:	00 
801073cb:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073d2:	e8 8c ff ff ff       	call   80107363 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801073d7:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801073de:	00 
801073df:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073e6:	e8 78 ff ff ff       	call   80107363 <outb>
  outb(COM1+4, 0);
801073eb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073f2:	00 
801073f3:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801073fa:	e8 64 ff ff ff       	call   80107363 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801073ff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107406:	00 
80107407:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010740e:	e8 50 ff ff ff       	call   80107363 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107413:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010741a:	e8 27 ff ff ff       	call   80107346 <inb>
8010741f:	3c ff                	cmp    $0xff,%al
80107421:	75 02                	jne    80107425 <uartinit+0xa4>
    return;
80107423:	eb 6a                	jmp    8010748f <uartinit+0x10e>
  uart = 1;
80107425:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
8010742c:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010742f:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107436:	e8 0b ff ff ff       	call   80107346 <inb>
  inb(COM1+0);
8010743b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107442:	e8 ff fe ff ff       	call   80107346 <inb>
  picenable(IRQ_COM1);
80107447:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010744e:	e8 e6 d0 ff ff       	call   80104539 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107453:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010745a:	00 
8010745b:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107462:	e8 1b bc ff ff       	call   80103082 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107467:	c7 45 f4 18 a2 10 80 	movl   $0x8010a218,-0xc(%ebp)
8010746e:	eb 15                	jmp    80107485 <uartinit+0x104>
    uartputc(*p);
80107470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107473:	0f b6 00             	movzbl (%eax),%eax
80107476:	0f be c0             	movsbl %al,%eax
80107479:	89 04 24             	mov    %eax,(%esp)
8010747c:	e8 10 00 00 00       	call   80107491 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107481:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107488:	0f b6 00             	movzbl (%eax),%eax
8010748b:	84 c0                	test   %al,%al
8010748d:	75 e1                	jne    80107470 <uartinit+0xef>
    uartputc(*p);
}
8010748f:	c9                   	leave  
80107490:	c3                   	ret    

80107491 <uartputc>:

void
uartputc(int c)
{
80107491:	55                   	push   %ebp
80107492:	89 e5                	mov    %esp,%ebp
80107494:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107497:	a1 50 d6 10 80       	mov    0x8010d650,%eax
8010749c:	85 c0                	test   %eax,%eax
8010749e:	75 02                	jne    801074a2 <uartputc+0x11>
    return;
801074a0:	eb 4b                	jmp    801074ed <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801074a2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801074a9:	eb 10                	jmp    801074bb <uartputc+0x2a>
    microdelay(10);
801074ab:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801074b2:	e8 d2 c1 ff ff       	call   80103689 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801074b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801074bb:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801074bf:	7f 16                	jg     801074d7 <uartputc+0x46>
801074c1:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074c8:	e8 79 fe ff ff       	call   80107346 <inb>
801074cd:	0f b6 c0             	movzbl %al,%eax
801074d0:	83 e0 20             	and    $0x20,%eax
801074d3:	85 c0                	test   %eax,%eax
801074d5:	74 d4                	je     801074ab <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801074d7:	8b 45 08             	mov    0x8(%ebp),%eax
801074da:	0f b6 c0             	movzbl %al,%eax
801074dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801074e1:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074e8:	e8 76 fe ff ff       	call   80107363 <outb>
}
801074ed:	c9                   	leave  
801074ee:	c3                   	ret    

801074ef <uartgetc>:

static int
uartgetc(void)
{
801074ef:	55                   	push   %ebp
801074f0:	89 e5                	mov    %esp,%ebp
801074f2:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801074f5:	a1 50 d6 10 80       	mov    0x8010d650,%eax
801074fa:	85 c0                	test   %eax,%eax
801074fc:	75 07                	jne    80107505 <uartgetc+0x16>
    return -1;
801074fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107503:	eb 2c                	jmp    80107531 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107505:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010750c:	e8 35 fe ff ff       	call   80107346 <inb>
80107511:	0f b6 c0             	movzbl %al,%eax
80107514:	83 e0 01             	and    $0x1,%eax
80107517:	85 c0                	test   %eax,%eax
80107519:	75 07                	jne    80107522 <uartgetc+0x33>
    return -1;
8010751b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107520:	eb 0f                	jmp    80107531 <uartgetc+0x42>
  return inb(COM1+0);
80107522:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107529:	e8 18 fe ff ff       	call   80107346 <inb>
8010752e:	0f b6 c0             	movzbl %al,%eax
}
80107531:	c9                   	leave  
80107532:	c3                   	ret    

80107533 <uartintr>:

void
uartintr(void)
{
80107533:	55                   	push   %ebp
80107534:	89 e5                	mov    %esp,%ebp
80107536:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107539:	c7 04 24 ef 74 10 80 	movl   $0x801074ef,(%esp)
80107540:	e8 83 92 ff ff       	call   801007c8 <consoleintr>
}
80107545:	c9                   	leave  
80107546:	c3                   	ret    

80107547 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107547:	6a 00                	push   $0x0
  pushl $0
80107549:	6a 00                	push   $0x0
  jmp alltraps
8010754b:	e9 d8 f8 ff ff       	jmp    80106e28 <alltraps>

80107550 <vector1>:
.globl vector1
vector1:
  pushl $0
80107550:	6a 00                	push   $0x0
  pushl $1
80107552:	6a 01                	push   $0x1
  jmp alltraps
80107554:	e9 cf f8 ff ff       	jmp    80106e28 <alltraps>

80107559 <vector2>:
.globl vector2
vector2:
  pushl $0
80107559:	6a 00                	push   $0x0
  pushl $2
8010755b:	6a 02                	push   $0x2
  jmp alltraps
8010755d:	e9 c6 f8 ff ff       	jmp    80106e28 <alltraps>

80107562 <vector3>:
.globl vector3
vector3:
  pushl $0
80107562:	6a 00                	push   $0x0
  pushl $3
80107564:	6a 03                	push   $0x3
  jmp alltraps
80107566:	e9 bd f8 ff ff       	jmp    80106e28 <alltraps>

8010756b <vector4>:
.globl vector4
vector4:
  pushl $0
8010756b:	6a 00                	push   $0x0
  pushl $4
8010756d:	6a 04                	push   $0x4
  jmp alltraps
8010756f:	e9 b4 f8 ff ff       	jmp    80106e28 <alltraps>

80107574 <vector5>:
.globl vector5
vector5:
  pushl $0
80107574:	6a 00                	push   $0x0
  pushl $5
80107576:	6a 05                	push   $0x5
  jmp alltraps
80107578:	e9 ab f8 ff ff       	jmp    80106e28 <alltraps>

8010757d <vector6>:
.globl vector6
vector6:
  pushl $0
8010757d:	6a 00                	push   $0x0
  pushl $6
8010757f:	6a 06                	push   $0x6
  jmp alltraps
80107581:	e9 a2 f8 ff ff       	jmp    80106e28 <alltraps>

80107586 <vector7>:
.globl vector7
vector7:
  pushl $0
80107586:	6a 00                	push   $0x0
  pushl $7
80107588:	6a 07                	push   $0x7
  jmp alltraps
8010758a:	e9 99 f8 ff ff       	jmp    80106e28 <alltraps>

8010758f <vector8>:
.globl vector8
vector8:
  pushl $8
8010758f:	6a 08                	push   $0x8
  jmp alltraps
80107591:	e9 92 f8 ff ff       	jmp    80106e28 <alltraps>

80107596 <vector9>:
.globl vector9
vector9:
  pushl $0
80107596:	6a 00                	push   $0x0
  pushl $9
80107598:	6a 09                	push   $0x9
  jmp alltraps
8010759a:	e9 89 f8 ff ff       	jmp    80106e28 <alltraps>

8010759f <vector10>:
.globl vector10
vector10:
  pushl $10
8010759f:	6a 0a                	push   $0xa
  jmp alltraps
801075a1:	e9 82 f8 ff ff       	jmp    80106e28 <alltraps>

801075a6 <vector11>:
.globl vector11
vector11:
  pushl $11
801075a6:	6a 0b                	push   $0xb
  jmp alltraps
801075a8:	e9 7b f8 ff ff       	jmp    80106e28 <alltraps>

801075ad <vector12>:
.globl vector12
vector12:
  pushl $12
801075ad:	6a 0c                	push   $0xc
  jmp alltraps
801075af:	e9 74 f8 ff ff       	jmp    80106e28 <alltraps>

801075b4 <vector13>:
.globl vector13
vector13:
  pushl $13
801075b4:	6a 0d                	push   $0xd
  jmp alltraps
801075b6:	e9 6d f8 ff ff       	jmp    80106e28 <alltraps>

801075bb <vector14>:
.globl vector14
vector14:
  pushl $14
801075bb:	6a 0e                	push   $0xe
  jmp alltraps
801075bd:	e9 66 f8 ff ff       	jmp    80106e28 <alltraps>

801075c2 <vector15>:
.globl vector15
vector15:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $15
801075c4:	6a 0f                	push   $0xf
  jmp alltraps
801075c6:	e9 5d f8 ff ff       	jmp    80106e28 <alltraps>

801075cb <vector16>:
.globl vector16
vector16:
  pushl $0
801075cb:	6a 00                	push   $0x0
  pushl $16
801075cd:	6a 10                	push   $0x10
  jmp alltraps
801075cf:	e9 54 f8 ff ff       	jmp    80106e28 <alltraps>

801075d4 <vector17>:
.globl vector17
vector17:
  pushl $17
801075d4:	6a 11                	push   $0x11
  jmp alltraps
801075d6:	e9 4d f8 ff ff       	jmp    80106e28 <alltraps>

801075db <vector18>:
.globl vector18
vector18:
  pushl $0
801075db:	6a 00                	push   $0x0
  pushl $18
801075dd:	6a 12                	push   $0x12
  jmp alltraps
801075df:	e9 44 f8 ff ff       	jmp    80106e28 <alltraps>

801075e4 <vector19>:
.globl vector19
vector19:
  pushl $0
801075e4:	6a 00                	push   $0x0
  pushl $19
801075e6:	6a 13                	push   $0x13
  jmp alltraps
801075e8:	e9 3b f8 ff ff       	jmp    80106e28 <alltraps>

801075ed <vector20>:
.globl vector20
vector20:
  pushl $0
801075ed:	6a 00                	push   $0x0
  pushl $20
801075ef:	6a 14                	push   $0x14
  jmp alltraps
801075f1:	e9 32 f8 ff ff       	jmp    80106e28 <alltraps>

801075f6 <vector21>:
.globl vector21
vector21:
  pushl $0
801075f6:	6a 00                	push   $0x0
  pushl $21
801075f8:	6a 15                	push   $0x15
  jmp alltraps
801075fa:	e9 29 f8 ff ff       	jmp    80106e28 <alltraps>

801075ff <vector22>:
.globl vector22
vector22:
  pushl $0
801075ff:	6a 00                	push   $0x0
  pushl $22
80107601:	6a 16                	push   $0x16
  jmp alltraps
80107603:	e9 20 f8 ff ff       	jmp    80106e28 <alltraps>

80107608 <vector23>:
.globl vector23
vector23:
  pushl $0
80107608:	6a 00                	push   $0x0
  pushl $23
8010760a:	6a 17                	push   $0x17
  jmp alltraps
8010760c:	e9 17 f8 ff ff       	jmp    80106e28 <alltraps>

80107611 <vector24>:
.globl vector24
vector24:
  pushl $0
80107611:	6a 00                	push   $0x0
  pushl $24
80107613:	6a 18                	push   $0x18
  jmp alltraps
80107615:	e9 0e f8 ff ff       	jmp    80106e28 <alltraps>

8010761a <vector25>:
.globl vector25
vector25:
  pushl $0
8010761a:	6a 00                	push   $0x0
  pushl $25
8010761c:	6a 19                	push   $0x19
  jmp alltraps
8010761e:	e9 05 f8 ff ff       	jmp    80106e28 <alltraps>

80107623 <vector26>:
.globl vector26
vector26:
  pushl $0
80107623:	6a 00                	push   $0x0
  pushl $26
80107625:	6a 1a                	push   $0x1a
  jmp alltraps
80107627:	e9 fc f7 ff ff       	jmp    80106e28 <alltraps>

8010762c <vector27>:
.globl vector27
vector27:
  pushl $0
8010762c:	6a 00                	push   $0x0
  pushl $27
8010762e:	6a 1b                	push   $0x1b
  jmp alltraps
80107630:	e9 f3 f7 ff ff       	jmp    80106e28 <alltraps>

80107635 <vector28>:
.globl vector28
vector28:
  pushl $0
80107635:	6a 00                	push   $0x0
  pushl $28
80107637:	6a 1c                	push   $0x1c
  jmp alltraps
80107639:	e9 ea f7 ff ff       	jmp    80106e28 <alltraps>

8010763e <vector29>:
.globl vector29
vector29:
  pushl $0
8010763e:	6a 00                	push   $0x0
  pushl $29
80107640:	6a 1d                	push   $0x1d
  jmp alltraps
80107642:	e9 e1 f7 ff ff       	jmp    80106e28 <alltraps>

80107647 <vector30>:
.globl vector30
vector30:
  pushl $0
80107647:	6a 00                	push   $0x0
  pushl $30
80107649:	6a 1e                	push   $0x1e
  jmp alltraps
8010764b:	e9 d8 f7 ff ff       	jmp    80106e28 <alltraps>

80107650 <vector31>:
.globl vector31
vector31:
  pushl $0
80107650:	6a 00                	push   $0x0
  pushl $31
80107652:	6a 1f                	push   $0x1f
  jmp alltraps
80107654:	e9 cf f7 ff ff       	jmp    80106e28 <alltraps>

80107659 <vector32>:
.globl vector32
vector32:
  pushl $0
80107659:	6a 00                	push   $0x0
  pushl $32
8010765b:	6a 20                	push   $0x20
  jmp alltraps
8010765d:	e9 c6 f7 ff ff       	jmp    80106e28 <alltraps>

80107662 <vector33>:
.globl vector33
vector33:
  pushl $0
80107662:	6a 00                	push   $0x0
  pushl $33
80107664:	6a 21                	push   $0x21
  jmp alltraps
80107666:	e9 bd f7 ff ff       	jmp    80106e28 <alltraps>

8010766b <vector34>:
.globl vector34
vector34:
  pushl $0
8010766b:	6a 00                	push   $0x0
  pushl $34
8010766d:	6a 22                	push   $0x22
  jmp alltraps
8010766f:	e9 b4 f7 ff ff       	jmp    80106e28 <alltraps>

80107674 <vector35>:
.globl vector35
vector35:
  pushl $0
80107674:	6a 00                	push   $0x0
  pushl $35
80107676:	6a 23                	push   $0x23
  jmp alltraps
80107678:	e9 ab f7 ff ff       	jmp    80106e28 <alltraps>

8010767d <vector36>:
.globl vector36
vector36:
  pushl $0
8010767d:	6a 00                	push   $0x0
  pushl $36
8010767f:	6a 24                	push   $0x24
  jmp alltraps
80107681:	e9 a2 f7 ff ff       	jmp    80106e28 <alltraps>

80107686 <vector37>:
.globl vector37
vector37:
  pushl $0
80107686:	6a 00                	push   $0x0
  pushl $37
80107688:	6a 25                	push   $0x25
  jmp alltraps
8010768a:	e9 99 f7 ff ff       	jmp    80106e28 <alltraps>

8010768f <vector38>:
.globl vector38
vector38:
  pushl $0
8010768f:	6a 00                	push   $0x0
  pushl $38
80107691:	6a 26                	push   $0x26
  jmp alltraps
80107693:	e9 90 f7 ff ff       	jmp    80106e28 <alltraps>

80107698 <vector39>:
.globl vector39
vector39:
  pushl $0
80107698:	6a 00                	push   $0x0
  pushl $39
8010769a:	6a 27                	push   $0x27
  jmp alltraps
8010769c:	e9 87 f7 ff ff       	jmp    80106e28 <alltraps>

801076a1 <vector40>:
.globl vector40
vector40:
  pushl $0
801076a1:	6a 00                	push   $0x0
  pushl $40
801076a3:	6a 28                	push   $0x28
  jmp alltraps
801076a5:	e9 7e f7 ff ff       	jmp    80106e28 <alltraps>

801076aa <vector41>:
.globl vector41
vector41:
  pushl $0
801076aa:	6a 00                	push   $0x0
  pushl $41
801076ac:	6a 29                	push   $0x29
  jmp alltraps
801076ae:	e9 75 f7 ff ff       	jmp    80106e28 <alltraps>

801076b3 <vector42>:
.globl vector42
vector42:
  pushl $0
801076b3:	6a 00                	push   $0x0
  pushl $42
801076b5:	6a 2a                	push   $0x2a
  jmp alltraps
801076b7:	e9 6c f7 ff ff       	jmp    80106e28 <alltraps>

801076bc <vector43>:
.globl vector43
vector43:
  pushl $0
801076bc:	6a 00                	push   $0x0
  pushl $43
801076be:	6a 2b                	push   $0x2b
  jmp alltraps
801076c0:	e9 63 f7 ff ff       	jmp    80106e28 <alltraps>

801076c5 <vector44>:
.globl vector44
vector44:
  pushl $0
801076c5:	6a 00                	push   $0x0
  pushl $44
801076c7:	6a 2c                	push   $0x2c
  jmp alltraps
801076c9:	e9 5a f7 ff ff       	jmp    80106e28 <alltraps>

801076ce <vector45>:
.globl vector45
vector45:
  pushl $0
801076ce:	6a 00                	push   $0x0
  pushl $45
801076d0:	6a 2d                	push   $0x2d
  jmp alltraps
801076d2:	e9 51 f7 ff ff       	jmp    80106e28 <alltraps>

801076d7 <vector46>:
.globl vector46
vector46:
  pushl $0
801076d7:	6a 00                	push   $0x0
  pushl $46
801076d9:	6a 2e                	push   $0x2e
  jmp alltraps
801076db:	e9 48 f7 ff ff       	jmp    80106e28 <alltraps>

801076e0 <vector47>:
.globl vector47
vector47:
  pushl $0
801076e0:	6a 00                	push   $0x0
  pushl $47
801076e2:	6a 2f                	push   $0x2f
  jmp alltraps
801076e4:	e9 3f f7 ff ff       	jmp    80106e28 <alltraps>

801076e9 <vector48>:
.globl vector48
vector48:
  pushl $0
801076e9:	6a 00                	push   $0x0
  pushl $48
801076eb:	6a 30                	push   $0x30
  jmp alltraps
801076ed:	e9 36 f7 ff ff       	jmp    80106e28 <alltraps>

801076f2 <vector49>:
.globl vector49
vector49:
  pushl $0
801076f2:	6a 00                	push   $0x0
  pushl $49
801076f4:	6a 31                	push   $0x31
  jmp alltraps
801076f6:	e9 2d f7 ff ff       	jmp    80106e28 <alltraps>

801076fb <vector50>:
.globl vector50
vector50:
  pushl $0
801076fb:	6a 00                	push   $0x0
  pushl $50
801076fd:	6a 32                	push   $0x32
  jmp alltraps
801076ff:	e9 24 f7 ff ff       	jmp    80106e28 <alltraps>

80107704 <vector51>:
.globl vector51
vector51:
  pushl $0
80107704:	6a 00                	push   $0x0
  pushl $51
80107706:	6a 33                	push   $0x33
  jmp alltraps
80107708:	e9 1b f7 ff ff       	jmp    80106e28 <alltraps>

8010770d <vector52>:
.globl vector52
vector52:
  pushl $0
8010770d:	6a 00                	push   $0x0
  pushl $52
8010770f:	6a 34                	push   $0x34
  jmp alltraps
80107711:	e9 12 f7 ff ff       	jmp    80106e28 <alltraps>

80107716 <vector53>:
.globl vector53
vector53:
  pushl $0
80107716:	6a 00                	push   $0x0
  pushl $53
80107718:	6a 35                	push   $0x35
  jmp alltraps
8010771a:	e9 09 f7 ff ff       	jmp    80106e28 <alltraps>

8010771f <vector54>:
.globl vector54
vector54:
  pushl $0
8010771f:	6a 00                	push   $0x0
  pushl $54
80107721:	6a 36                	push   $0x36
  jmp alltraps
80107723:	e9 00 f7 ff ff       	jmp    80106e28 <alltraps>

80107728 <vector55>:
.globl vector55
vector55:
  pushl $0
80107728:	6a 00                	push   $0x0
  pushl $55
8010772a:	6a 37                	push   $0x37
  jmp alltraps
8010772c:	e9 f7 f6 ff ff       	jmp    80106e28 <alltraps>

80107731 <vector56>:
.globl vector56
vector56:
  pushl $0
80107731:	6a 00                	push   $0x0
  pushl $56
80107733:	6a 38                	push   $0x38
  jmp alltraps
80107735:	e9 ee f6 ff ff       	jmp    80106e28 <alltraps>

8010773a <vector57>:
.globl vector57
vector57:
  pushl $0
8010773a:	6a 00                	push   $0x0
  pushl $57
8010773c:	6a 39                	push   $0x39
  jmp alltraps
8010773e:	e9 e5 f6 ff ff       	jmp    80106e28 <alltraps>

80107743 <vector58>:
.globl vector58
vector58:
  pushl $0
80107743:	6a 00                	push   $0x0
  pushl $58
80107745:	6a 3a                	push   $0x3a
  jmp alltraps
80107747:	e9 dc f6 ff ff       	jmp    80106e28 <alltraps>

8010774c <vector59>:
.globl vector59
vector59:
  pushl $0
8010774c:	6a 00                	push   $0x0
  pushl $59
8010774e:	6a 3b                	push   $0x3b
  jmp alltraps
80107750:	e9 d3 f6 ff ff       	jmp    80106e28 <alltraps>

80107755 <vector60>:
.globl vector60
vector60:
  pushl $0
80107755:	6a 00                	push   $0x0
  pushl $60
80107757:	6a 3c                	push   $0x3c
  jmp alltraps
80107759:	e9 ca f6 ff ff       	jmp    80106e28 <alltraps>

8010775e <vector61>:
.globl vector61
vector61:
  pushl $0
8010775e:	6a 00                	push   $0x0
  pushl $61
80107760:	6a 3d                	push   $0x3d
  jmp alltraps
80107762:	e9 c1 f6 ff ff       	jmp    80106e28 <alltraps>

80107767 <vector62>:
.globl vector62
vector62:
  pushl $0
80107767:	6a 00                	push   $0x0
  pushl $62
80107769:	6a 3e                	push   $0x3e
  jmp alltraps
8010776b:	e9 b8 f6 ff ff       	jmp    80106e28 <alltraps>

80107770 <vector63>:
.globl vector63
vector63:
  pushl $0
80107770:	6a 00                	push   $0x0
  pushl $63
80107772:	6a 3f                	push   $0x3f
  jmp alltraps
80107774:	e9 af f6 ff ff       	jmp    80106e28 <alltraps>

80107779 <vector64>:
.globl vector64
vector64:
  pushl $0
80107779:	6a 00                	push   $0x0
  pushl $64
8010777b:	6a 40                	push   $0x40
  jmp alltraps
8010777d:	e9 a6 f6 ff ff       	jmp    80106e28 <alltraps>

80107782 <vector65>:
.globl vector65
vector65:
  pushl $0
80107782:	6a 00                	push   $0x0
  pushl $65
80107784:	6a 41                	push   $0x41
  jmp alltraps
80107786:	e9 9d f6 ff ff       	jmp    80106e28 <alltraps>

8010778b <vector66>:
.globl vector66
vector66:
  pushl $0
8010778b:	6a 00                	push   $0x0
  pushl $66
8010778d:	6a 42                	push   $0x42
  jmp alltraps
8010778f:	e9 94 f6 ff ff       	jmp    80106e28 <alltraps>

80107794 <vector67>:
.globl vector67
vector67:
  pushl $0
80107794:	6a 00                	push   $0x0
  pushl $67
80107796:	6a 43                	push   $0x43
  jmp alltraps
80107798:	e9 8b f6 ff ff       	jmp    80106e28 <alltraps>

8010779d <vector68>:
.globl vector68
vector68:
  pushl $0
8010779d:	6a 00                	push   $0x0
  pushl $68
8010779f:	6a 44                	push   $0x44
  jmp alltraps
801077a1:	e9 82 f6 ff ff       	jmp    80106e28 <alltraps>

801077a6 <vector69>:
.globl vector69
vector69:
  pushl $0
801077a6:	6a 00                	push   $0x0
  pushl $69
801077a8:	6a 45                	push   $0x45
  jmp alltraps
801077aa:	e9 79 f6 ff ff       	jmp    80106e28 <alltraps>

801077af <vector70>:
.globl vector70
vector70:
  pushl $0
801077af:	6a 00                	push   $0x0
  pushl $70
801077b1:	6a 46                	push   $0x46
  jmp alltraps
801077b3:	e9 70 f6 ff ff       	jmp    80106e28 <alltraps>

801077b8 <vector71>:
.globl vector71
vector71:
  pushl $0
801077b8:	6a 00                	push   $0x0
  pushl $71
801077ba:	6a 47                	push   $0x47
  jmp alltraps
801077bc:	e9 67 f6 ff ff       	jmp    80106e28 <alltraps>

801077c1 <vector72>:
.globl vector72
vector72:
  pushl $0
801077c1:	6a 00                	push   $0x0
  pushl $72
801077c3:	6a 48                	push   $0x48
  jmp alltraps
801077c5:	e9 5e f6 ff ff       	jmp    80106e28 <alltraps>

801077ca <vector73>:
.globl vector73
vector73:
  pushl $0
801077ca:	6a 00                	push   $0x0
  pushl $73
801077cc:	6a 49                	push   $0x49
  jmp alltraps
801077ce:	e9 55 f6 ff ff       	jmp    80106e28 <alltraps>

801077d3 <vector74>:
.globl vector74
vector74:
  pushl $0
801077d3:	6a 00                	push   $0x0
  pushl $74
801077d5:	6a 4a                	push   $0x4a
  jmp alltraps
801077d7:	e9 4c f6 ff ff       	jmp    80106e28 <alltraps>

801077dc <vector75>:
.globl vector75
vector75:
  pushl $0
801077dc:	6a 00                	push   $0x0
  pushl $75
801077de:	6a 4b                	push   $0x4b
  jmp alltraps
801077e0:	e9 43 f6 ff ff       	jmp    80106e28 <alltraps>

801077e5 <vector76>:
.globl vector76
vector76:
  pushl $0
801077e5:	6a 00                	push   $0x0
  pushl $76
801077e7:	6a 4c                	push   $0x4c
  jmp alltraps
801077e9:	e9 3a f6 ff ff       	jmp    80106e28 <alltraps>

801077ee <vector77>:
.globl vector77
vector77:
  pushl $0
801077ee:	6a 00                	push   $0x0
  pushl $77
801077f0:	6a 4d                	push   $0x4d
  jmp alltraps
801077f2:	e9 31 f6 ff ff       	jmp    80106e28 <alltraps>

801077f7 <vector78>:
.globl vector78
vector78:
  pushl $0
801077f7:	6a 00                	push   $0x0
  pushl $78
801077f9:	6a 4e                	push   $0x4e
  jmp alltraps
801077fb:	e9 28 f6 ff ff       	jmp    80106e28 <alltraps>

80107800 <vector79>:
.globl vector79
vector79:
  pushl $0
80107800:	6a 00                	push   $0x0
  pushl $79
80107802:	6a 4f                	push   $0x4f
  jmp alltraps
80107804:	e9 1f f6 ff ff       	jmp    80106e28 <alltraps>

80107809 <vector80>:
.globl vector80
vector80:
  pushl $0
80107809:	6a 00                	push   $0x0
  pushl $80
8010780b:	6a 50                	push   $0x50
  jmp alltraps
8010780d:	e9 16 f6 ff ff       	jmp    80106e28 <alltraps>

80107812 <vector81>:
.globl vector81
vector81:
  pushl $0
80107812:	6a 00                	push   $0x0
  pushl $81
80107814:	6a 51                	push   $0x51
  jmp alltraps
80107816:	e9 0d f6 ff ff       	jmp    80106e28 <alltraps>

8010781b <vector82>:
.globl vector82
vector82:
  pushl $0
8010781b:	6a 00                	push   $0x0
  pushl $82
8010781d:	6a 52                	push   $0x52
  jmp alltraps
8010781f:	e9 04 f6 ff ff       	jmp    80106e28 <alltraps>

80107824 <vector83>:
.globl vector83
vector83:
  pushl $0
80107824:	6a 00                	push   $0x0
  pushl $83
80107826:	6a 53                	push   $0x53
  jmp alltraps
80107828:	e9 fb f5 ff ff       	jmp    80106e28 <alltraps>

8010782d <vector84>:
.globl vector84
vector84:
  pushl $0
8010782d:	6a 00                	push   $0x0
  pushl $84
8010782f:	6a 54                	push   $0x54
  jmp alltraps
80107831:	e9 f2 f5 ff ff       	jmp    80106e28 <alltraps>

80107836 <vector85>:
.globl vector85
vector85:
  pushl $0
80107836:	6a 00                	push   $0x0
  pushl $85
80107838:	6a 55                	push   $0x55
  jmp alltraps
8010783a:	e9 e9 f5 ff ff       	jmp    80106e28 <alltraps>

8010783f <vector86>:
.globl vector86
vector86:
  pushl $0
8010783f:	6a 00                	push   $0x0
  pushl $86
80107841:	6a 56                	push   $0x56
  jmp alltraps
80107843:	e9 e0 f5 ff ff       	jmp    80106e28 <alltraps>

80107848 <vector87>:
.globl vector87
vector87:
  pushl $0
80107848:	6a 00                	push   $0x0
  pushl $87
8010784a:	6a 57                	push   $0x57
  jmp alltraps
8010784c:	e9 d7 f5 ff ff       	jmp    80106e28 <alltraps>

80107851 <vector88>:
.globl vector88
vector88:
  pushl $0
80107851:	6a 00                	push   $0x0
  pushl $88
80107853:	6a 58                	push   $0x58
  jmp alltraps
80107855:	e9 ce f5 ff ff       	jmp    80106e28 <alltraps>

8010785a <vector89>:
.globl vector89
vector89:
  pushl $0
8010785a:	6a 00                	push   $0x0
  pushl $89
8010785c:	6a 59                	push   $0x59
  jmp alltraps
8010785e:	e9 c5 f5 ff ff       	jmp    80106e28 <alltraps>

80107863 <vector90>:
.globl vector90
vector90:
  pushl $0
80107863:	6a 00                	push   $0x0
  pushl $90
80107865:	6a 5a                	push   $0x5a
  jmp alltraps
80107867:	e9 bc f5 ff ff       	jmp    80106e28 <alltraps>

8010786c <vector91>:
.globl vector91
vector91:
  pushl $0
8010786c:	6a 00                	push   $0x0
  pushl $91
8010786e:	6a 5b                	push   $0x5b
  jmp alltraps
80107870:	e9 b3 f5 ff ff       	jmp    80106e28 <alltraps>

80107875 <vector92>:
.globl vector92
vector92:
  pushl $0
80107875:	6a 00                	push   $0x0
  pushl $92
80107877:	6a 5c                	push   $0x5c
  jmp alltraps
80107879:	e9 aa f5 ff ff       	jmp    80106e28 <alltraps>

8010787e <vector93>:
.globl vector93
vector93:
  pushl $0
8010787e:	6a 00                	push   $0x0
  pushl $93
80107880:	6a 5d                	push   $0x5d
  jmp alltraps
80107882:	e9 a1 f5 ff ff       	jmp    80106e28 <alltraps>

80107887 <vector94>:
.globl vector94
vector94:
  pushl $0
80107887:	6a 00                	push   $0x0
  pushl $94
80107889:	6a 5e                	push   $0x5e
  jmp alltraps
8010788b:	e9 98 f5 ff ff       	jmp    80106e28 <alltraps>

80107890 <vector95>:
.globl vector95
vector95:
  pushl $0
80107890:	6a 00                	push   $0x0
  pushl $95
80107892:	6a 5f                	push   $0x5f
  jmp alltraps
80107894:	e9 8f f5 ff ff       	jmp    80106e28 <alltraps>

80107899 <vector96>:
.globl vector96
vector96:
  pushl $0
80107899:	6a 00                	push   $0x0
  pushl $96
8010789b:	6a 60                	push   $0x60
  jmp alltraps
8010789d:	e9 86 f5 ff ff       	jmp    80106e28 <alltraps>

801078a2 <vector97>:
.globl vector97
vector97:
  pushl $0
801078a2:	6a 00                	push   $0x0
  pushl $97
801078a4:	6a 61                	push   $0x61
  jmp alltraps
801078a6:	e9 7d f5 ff ff       	jmp    80106e28 <alltraps>

801078ab <vector98>:
.globl vector98
vector98:
  pushl $0
801078ab:	6a 00                	push   $0x0
  pushl $98
801078ad:	6a 62                	push   $0x62
  jmp alltraps
801078af:	e9 74 f5 ff ff       	jmp    80106e28 <alltraps>

801078b4 <vector99>:
.globl vector99
vector99:
  pushl $0
801078b4:	6a 00                	push   $0x0
  pushl $99
801078b6:	6a 63                	push   $0x63
  jmp alltraps
801078b8:	e9 6b f5 ff ff       	jmp    80106e28 <alltraps>

801078bd <vector100>:
.globl vector100
vector100:
  pushl $0
801078bd:	6a 00                	push   $0x0
  pushl $100
801078bf:	6a 64                	push   $0x64
  jmp alltraps
801078c1:	e9 62 f5 ff ff       	jmp    80106e28 <alltraps>

801078c6 <vector101>:
.globl vector101
vector101:
  pushl $0
801078c6:	6a 00                	push   $0x0
  pushl $101
801078c8:	6a 65                	push   $0x65
  jmp alltraps
801078ca:	e9 59 f5 ff ff       	jmp    80106e28 <alltraps>

801078cf <vector102>:
.globl vector102
vector102:
  pushl $0
801078cf:	6a 00                	push   $0x0
  pushl $102
801078d1:	6a 66                	push   $0x66
  jmp alltraps
801078d3:	e9 50 f5 ff ff       	jmp    80106e28 <alltraps>

801078d8 <vector103>:
.globl vector103
vector103:
  pushl $0
801078d8:	6a 00                	push   $0x0
  pushl $103
801078da:	6a 67                	push   $0x67
  jmp alltraps
801078dc:	e9 47 f5 ff ff       	jmp    80106e28 <alltraps>

801078e1 <vector104>:
.globl vector104
vector104:
  pushl $0
801078e1:	6a 00                	push   $0x0
  pushl $104
801078e3:	6a 68                	push   $0x68
  jmp alltraps
801078e5:	e9 3e f5 ff ff       	jmp    80106e28 <alltraps>

801078ea <vector105>:
.globl vector105
vector105:
  pushl $0
801078ea:	6a 00                	push   $0x0
  pushl $105
801078ec:	6a 69                	push   $0x69
  jmp alltraps
801078ee:	e9 35 f5 ff ff       	jmp    80106e28 <alltraps>

801078f3 <vector106>:
.globl vector106
vector106:
  pushl $0
801078f3:	6a 00                	push   $0x0
  pushl $106
801078f5:	6a 6a                	push   $0x6a
  jmp alltraps
801078f7:	e9 2c f5 ff ff       	jmp    80106e28 <alltraps>

801078fc <vector107>:
.globl vector107
vector107:
  pushl $0
801078fc:	6a 00                	push   $0x0
  pushl $107
801078fe:	6a 6b                	push   $0x6b
  jmp alltraps
80107900:	e9 23 f5 ff ff       	jmp    80106e28 <alltraps>

80107905 <vector108>:
.globl vector108
vector108:
  pushl $0
80107905:	6a 00                	push   $0x0
  pushl $108
80107907:	6a 6c                	push   $0x6c
  jmp alltraps
80107909:	e9 1a f5 ff ff       	jmp    80106e28 <alltraps>

8010790e <vector109>:
.globl vector109
vector109:
  pushl $0
8010790e:	6a 00                	push   $0x0
  pushl $109
80107910:	6a 6d                	push   $0x6d
  jmp alltraps
80107912:	e9 11 f5 ff ff       	jmp    80106e28 <alltraps>

80107917 <vector110>:
.globl vector110
vector110:
  pushl $0
80107917:	6a 00                	push   $0x0
  pushl $110
80107919:	6a 6e                	push   $0x6e
  jmp alltraps
8010791b:	e9 08 f5 ff ff       	jmp    80106e28 <alltraps>

80107920 <vector111>:
.globl vector111
vector111:
  pushl $0
80107920:	6a 00                	push   $0x0
  pushl $111
80107922:	6a 6f                	push   $0x6f
  jmp alltraps
80107924:	e9 ff f4 ff ff       	jmp    80106e28 <alltraps>

80107929 <vector112>:
.globl vector112
vector112:
  pushl $0
80107929:	6a 00                	push   $0x0
  pushl $112
8010792b:	6a 70                	push   $0x70
  jmp alltraps
8010792d:	e9 f6 f4 ff ff       	jmp    80106e28 <alltraps>

80107932 <vector113>:
.globl vector113
vector113:
  pushl $0
80107932:	6a 00                	push   $0x0
  pushl $113
80107934:	6a 71                	push   $0x71
  jmp alltraps
80107936:	e9 ed f4 ff ff       	jmp    80106e28 <alltraps>

8010793b <vector114>:
.globl vector114
vector114:
  pushl $0
8010793b:	6a 00                	push   $0x0
  pushl $114
8010793d:	6a 72                	push   $0x72
  jmp alltraps
8010793f:	e9 e4 f4 ff ff       	jmp    80106e28 <alltraps>

80107944 <vector115>:
.globl vector115
vector115:
  pushl $0
80107944:	6a 00                	push   $0x0
  pushl $115
80107946:	6a 73                	push   $0x73
  jmp alltraps
80107948:	e9 db f4 ff ff       	jmp    80106e28 <alltraps>

8010794d <vector116>:
.globl vector116
vector116:
  pushl $0
8010794d:	6a 00                	push   $0x0
  pushl $116
8010794f:	6a 74                	push   $0x74
  jmp alltraps
80107951:	e9 d2 f4 ff ff       	jmp    80106e28 <alltraps>

80107956 <vector117>:
.globl vector117
vector117:
  pushl $0
80107956:	6a 00                	push   $0x0
  pushl $117
80107958:	6a 75                	push   $0x75
  jmp alltraps
8010795a:	e9 c9 f4 ff ff       	jmp    80106e28 <alltraps>

8010795f <vector118>:
.globl vector118
vector118:
  pushl $0
8010795f:	6a 00                	push   $0x0
  pushl $118
80107961:	6a 76                	push   $0x76
  jmp alltraps
80107963:	e9 c0 f4 ff ff       	jmp    80106e28 <alltraps>

80107968 <vector119>:
.globl vector119
vector119:
  pushl $0
80107968:	6a 00                	push   $0x0
  pushl $119
8010796a:	6a 77                	push   $0x77
  jmp alltraps
8010796c:	e9 b7 f4 ff ff       	jmp    80106e28 <alltraps>

80107971 <vector120>:
.globl vector120
vector120:
  pushl $0
80107971:	6a 00                	push   $0x0
  pushl $120
80107973:	6a 78                	push   $0x78
  jmp alltraps
80107975:	e9 ae f4 ff ff       	jmp    80106e28 <alltraps>

8010797a <vector121>:
.globl vector121
vector121:
  pushl $0
8010797a:	6a 00                	push   $0x0
  pushl $121
8010797c:	6a 79                	push   $0x79
  jmp alltraps
8010797e:	e9 a5 f4 ff ff       	jmp    80106e28 <alltraps>

80107983 <vector122>:
.globl vector122
vector122:
  pushl $0
80107983:	6a 00                	push   $0x0
  pushl $122
80107985:	6a 7a                	push   $0x7a
  jmp alltraps
80107987:	e9 9c f4 ff ff       	jmp    80106e28 <alltraps>

8010798c <vector123>:
.globl vector123
vector123:
  pushl $0
8010798c:	6a 00                	push   $0x0
  pushl $123
8010798e:	6a 7b                	push   $0x7b
  jmp alltraps
80107990:	e9 93 f4 ff ff       	jmp    80106e28 <alltraps>

80107995 <vector124>:
.globl vector124
vector124:
  pushl $0
80107995:	6a 00                	push   $0x0
  pushl $124
80107997:	6a 7c                	push   $0x7c
  jmp alltraps
80107999:	e9 8a f4 ff ff       	jmp    80106e28 <alltraps>

8010799e <vector125>:
.globl vector125
vector125:
  pushl $0
8010799e:	6a 00                	push   $0x0
  pushl $125
801079a0:	6a 7d                	push   $0x7d
  jmp alltraps
801079a2:	e9 81 f4 ff ff       	jmp    80106e28 <alltraps>

801079a7 <vector126>:
.globl vector126
vector126:
  pushl $0
801079a7:	6a 00                	push   $0x0
  pushl $126
801079a9:	6a 7e                	push   $0x7e
  jmp alltraps
801079ab:	e9 78 f4 ff ff       	jmp    80106e28 <alltraps>

801079b0 <vector127>:
.globl vector127
vector127:
  pushl $0
801079b0:	6a 00                	push   $0x0
  pushl $127
801079b2:	6a 7f                	push   $0x7f
  jmp alltraps
801079b4:	e9 6f f4 ff ff       	jmp    80106e28 <alltraps>

801079b9 <vector128>:
.globl vector128
vector128:
  pushl $0
801079b9:	6a 00                	push   $0x0
  pushl $128
801079bb:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801079c0:	e9 63 f4 ff ff       	jmp    80106e28 <alltraps>

801079c5 <vector129>:
.globl vector129
vector129:
  pushl $0
801079c5:	6a 00                	push   $0x0
  pushl $129
801079c7:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801079cc:	e9 57 f4 ff ff       	jmp    80106e28 <alltraps>

801079d1 <vector130>:
.globl vector130
vector130:
  pushl $0
801079d1:	6a 00                	push   $0x0
  pushl $130
801079d3:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801079d8:	e9 4b f4 ff ff       	jmp    80106e28 <alltraps>

801079dd <vector131>:
.globl vector131
vector131:
  pushl $0
801079dd:	6a 00                	push   $0x0
  pushl $131
801079df:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801079e4:	e9 3f f4 ff ff       	jmp    80106e28 <alltraps>

801079e9 <vector132>:
.globl vector132
vector132:
  pushl $0
801079e9:	6a 00                	push   $0x0
  pushl $132
801079eb:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801079f0:	e9 33 f4 ff ff       	jmp    80106e28 <alltraps>

801079f5 <vector133>:
.globl vector133
vector133:
  pushl $0
801079f5:	6a 00                	push   $0x0
  pushl $133
801079f7:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801079fc:	e9 27 f4 ff ff       	jmp    80106e28 <alltraps>

80107a01 <vector134>:
.globl vector134
vector134:
  pushl $0
80107a01:	6a 00                	push   $0x0
  pushl $134
80107a03:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107a08:	e9 1b f4 ff ff       	jmp    80106e28 <alltraps>

80107a0d <vector135>:
.globl vector135
vector135:
  pushl $0
80107a0d:	6a 00                	push   $0x0
  pushl $135
80107a0f:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107a14:	e9 0f f4 ff ff       	jmp    80106e28 <alltraps>

80107a19 <vector136>:
.globl vector136
vector136:
  pushl $0
80107a19:	6a 00                	push   $0x0
  pushl $136
80107a1b:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107a20:	e9 03 f4 ff ff       	jmp    80106e28 <alltraps>

80107a25 <vector137>:
.globl vector137
vector137:
  pushl $0
80107a25:	6a 00                	push   $0x0
  pushl $137
80107a27:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107a2c:	e9 f7 f3 ff ff       	jmp    80106e28 <alltraps>

80107a31 <vector138>:
.globl vector138
vector138:
  pushl $0
80107a31:	6a 00                	push   $0x0
  pushl $138
80107a33:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107a38:	e9 eb f3 ff ff       	jmp    80106e28 <alltraps>

80107a3d <vector139>:
.globl vector139
vector139:
  pushl $0
80107a3d:	6a 00                	push   $0x0
  pushl $139
80107a3f:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107a44:	e9 df f3 ff ff       	jmp    80106e28 <alltraps>

80107a49 <vector140>:
.globl vector140
vector140:
  pushl $0
80107a49:	6a 00                	push   $0x0
  pushl $140
80107a4b:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107a50:	e9 d3 f3 ff ff       	jmp    80106e28 <alltraps>

80107a55 <vector141>:
.globl vector141
vector141:
  pushl $0
80107a55:	6a 00                	push   $0x0
  pushl $141
80107a57:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107a5c:	e9 c7 f3 ff ff       	jmp    80106e28 <alltraps>

80107a61 <vector142>:
.globl vector142
vector142:
  pushl $0
80107a61:	6a 00                	push   $0x0
  pushl $142
80107a63:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107a68:	e9 bb f3 ff ff       	jmp    80106e28 <alltraps>

80107a6d <vector143>:
.globl vector143
vector143:
  pushl $0
80107a6d:	6a 00                	push   $0x0
  pushl $143
80107a6f:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a74:	e9 af f3 ff ff       	jmp    80106e28 <alltraps>

80107a79 <vector144>:
.globl vector144
vector144:
  pushl $0
80107a79:	6a 00                	push   $0x0
  pushl $144
80107a7b:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a80:	e9 a3 f3 ff ff       	jmp    80106e28 <alltraps>

80107a85 <vector145>:
.globl vector145
vector145:
  pushl $0
80107a85:	6a 00                	push   $0x0
  pushl $145
80107a87:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a8c:	e9 97 f3 ff ff       	jmp    80106e28 <alltraps>

80107a91 <vector146>:
.globl vector146
vector146:
  pushl $0
80107a91:	6a 00                	push   $0x0
  pushl $146
80107a93:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a98:	e9 8b f3 ff ff       	jmp    80106e28 <alltraps>

80107a9d <vector147>:
.globl vector147
vector147:
  pushl $0
80107a9d:	6a 00                	push   $0x0
  pushl $147
80107a9f:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107aa4:	e9 7f f3 ff ff       	jmp    80106e28 <alltraps>

80107aa9 <vector148>:
.globl vector148
vector148:
  pushl $0
80107aa9:	6a 00                	push   $0x0
  pushl $148
80107aab:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107ab0:	e9 73 f3 ff ff       	jmp    80106e28 <alltraps>

80107ab5 <vector149>:
.globl vector149
vector149:
  pushl $0
80107ab5:	6a 00                	push   $0x0
  pushl $149
80107ab7:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107abc:	e9 67 f3 ff ff       	jmp    80106e28 <alltraps>

80107ac1 <vector150>:
.globl vector150
vector150:
  pushl $0
80107ac1:	6a 00                	push   $0x0
  pushl $150
80107ac3:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107ac8:	e9 5b f3 ff ff       	jmp    80106e28 <alltraps>

80107acd <vector151>:
.globl vector151
vector151:
  pushl $0
80107acd:	6a 00                	push   $0x0
  pushl $151
80107acf:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107ad4:	e9 4f f3 ff ff       	jmp    80106e28 <alltraps>

80107ad9 <vector152>:
.globl vector152
vector152:
  pushl $0
80107ad9:	6a 00                	push   $0x0
  pushl $152
80107adb:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107ae0:	e9 43 f3 ff ff       	jmp    80106e28 <alltraps>

80107ae5 <vector153>:
.globl vector153
vector153:
  pushl $0
80107ae5:	6a 00                	push   $0x0
  pushl $153
80107ae7:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107aec:	e9 37 f3 ff ff       	jmp    80106e28 <alltraps>

80107af1 <vector154>:
.globl vector154
vector154:
  pushl $0
80107af1:	6a 00                	push   $0x0
  pushl $154
80107af3:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107af8:	e9 2b f3 ff ff       	jmp    80106e28 <alltraps>

80107afd <vector155>:
.globl vector155
vector155:
  pushl $0
80107afd:	6a 00                	push   $0x0
  pushl $155
80107aff:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107b04:	e9 1f f3 ff ff       	jmp    80106e28 <alltraps>

80107b09 <vector156>:
.globl vector156
vector156:
  pushl $0
80107b09:	6a 00                	push   $0x0
  pushl $156
80107b0b:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107b10:	e9 13 f3 ff ff       	jmp    80106e28 <alltraps>

80107b15 <vector157>:
.globl vector157
vector157:
  pushl $0
80107b15:	6a 00                	push   $0x0
  pushl $157
80107b17:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107b1c:	e9 07 f3 ff ff       	jmp    80106e28 <alltraps>

80107b21 <vector158>:
.globl vector158
vector158:
  pushl $0
80107b21:	6a 00                	push   $0x0
  pushl $158
80107b23:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107b28:	e9 fb f2 ff ff       	jmp    80106e28 <alltraps>

80107b2d <vector159>:
.globl vector159
vector159:
  pushl $0
80107b2d:	6a 00                	push   $0x0
  pushl $159
80107b2f:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107b34:	e9 ef f2 ff ff       	jmp    80106e28 <alltraps>

80107b39 <vector160>:
.globl vector160
vector160:
  pushl $0
80107b39:	6a 00                	push   $0x0
  pushl $160
80107b3b:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107b40:	e9 e3 f2 ff ff       	jmp    80106e28 <alltraps>

80107b45 <vector161>:
.globl vector161
vector161:
  pushl $0
80107b45:	6a 00                	push   $0x0
  pushl $161
80107b47:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107b4c:	e9 d7 f2 ff ff       	jmp    80106e28 <alltraps>

80107b51 <vector162>:
.globl vector162
vector162:
  pushl $0
80107b51:	6a 00                	push   $0x0
  pushl $162
80107b53:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107b58:	e9 cb f2 ff ff       	jmp    80106e28 <alltraps>

80107b5d <vector163>:
.globl vector163
vector163:
  pushl $0
80107b5d:	6a 00                	push   $0x0
  pushl $163
80107b5f:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107b64:	e9 bf f2 ff ff       	jmp    80106e28 <alltraps>

80107b69 <vector164>:
.globl vector164
vector164:
  pushl $0
80107b69:	6a 00                	push   $0x0
  pushl $164
80107b6b:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b70:	e9 b3 f2 ff ff       	jmp    80106e28 <alltraps>

80107b75 <vector165>:
.globl vector165
vector165:
  pushl $0
80107b75:	6a 00                	push   $0x0
  pushl $165
80107b77:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b7c:	e9 a7 f2 ff ff       	jmp    80106e28 <alltraps>

80107b81 <vector166>:
.globl vector166
vector166:
  pushl $0
80107b81:	6a 00                	push   $0x0
  pushl $166
80107b83:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b88:	e9 9b f2 ff ff       	jmp    80106e28 <alltraps>

80107b8d <vector167>:
.globl vector167
vector167:
  pushl $0
80107b8d:	6a 00                	push   $0x0
  pushl $167
80107b8f:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b94:	e9 8f f2 ff ff       	jmp    80106e28 <alltraps>

80107b99 <vector168>:
.globl vector168
vector168:
  pushl $0
80107b99:	6a 00                	push   $0x0
  pushl $168
80107b9b:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107ba0:	e9 83 f2 ff ff       	jmp    80106e28 <alltraps>

80107ba5 <vector169>:
.globl vector169
vector169:
  pushl $0
80107ba5:	6a 00                	push   $0x0
  pushl $169
80107ba7:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107bac:	e9 77 f2 ff ff       	jmp    80106e28 <alltraps>

80107bb1 <vector170>:
.globl vector170
vector170:
  pushl $0
80107bb1:	6a 00                	push   $0x0
  pushl $170
80107bb3:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107bb8:	e9 6b f2 ff ff       	jmp    80106e28 <alltraps>

80107bbd <vector171>:
.globl vector171
vector171:
  pushl $0
80107bbd:	6a 00                	push   $0x0
  pushl $171
80107bbf:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107bc4:	e9 5f f2 ff ff       	jmp    80106e28 <alltraps>

80107bc9 <vector172>:
.globl vector172
vector172:
  pushl $0
80107bc9:	6a 00                	push   $0x0
  pushl $172
80107bcb:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107bd0:	e9 53 f2 ff ff       	jmp    80106e28 <alltraps>

80107bd5 <vector173>:
.globl vector173
vector173:
  pushl $0
80107bd5:	6a 00                	push   $0x0
  pushl $173
80107bd7:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107bdc:	e9 47 f2 ff ff       	jmp    80106e28 <alltraps>

80107be1 <vector174>:
.globl vector174
vector174:
  pushl $0
80107be1:	6a 00                	push   $0x0
  pushl $174
80107be3:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107be8:	e9 3b f2 ff ff       	jmp    80106e28 <alltraps>

80107bed <vector175>:
.globl vector175
vector175:
  pushl $0
80107bed:	6a 00                	push   $0x0
  pushl $175
80107bef:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107bf4:	e9 2f f2 ff ff       	jmp    80106e28 <alltraps>

80107bf9 <vector176>:
.globl vector176
vector176:
  pushl $0
80107bf9:	6a 00                	push   $0x0
  pushl $176
80107bfb:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107c00:	e9 23 f2 ff ff       	jmp    80106e28 <alltraps>

80107c05 <vector177>:
.globl vector177
vector177:
  pushl $0
80107c05:	6a 00                	push   $0x0
  pushl $177
80107c07:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107c0c:	e9 17 f2 ff ff       	jmp    80106e28 <alltraps>

80107c11 <vector178>:
.globl vector178
vector178:
  pushl $0
80107c11:	6a 00                	push   $0x0
  pushl $178
80107c13:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107c18:	e9 0b f2 ff ff       	jmp    80106e28 <alltraps>

80107c1d <vector179>:
.globl vector179
vector179:
  pushl $0
80107c1d:	6a 00                	push   $0x0
  pushl $179
80107c1f:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107c24:	e9 ff f1 ff ff       	jmp    80106e28 <alltraps>

80107c29 <vector180>:
.globl vector180
vector180:
  pushl $0
80107c29:	6a 00                	push   $0x0
  pushl $180
80107c2b:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107c30:	e9 f3 f1 ff ff       	jmp    80106e28 <alltraps>

80107c35 <vector181>:
.globl vector181
vector181:
  pushl $0
80107c35:	6a 00                	push   $0x0
  pushl $181
80107c37:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107c3c:	e9 e7 f1 ff ff       	jmp    80106e28 <alltraps>

80107c41 <vector182>:
.globl vector182
vector182:
  pushl $0
80107c41:	6a 00                	push   $0x0
  pushl $182
80107c43:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107c48:	e9 db f1 ff ff       	jmp    80106e28 <alltraps>

80107c4d <vector183>:
.globl vector183
vector183:
  pushl $0
80107c4d:	6a 00                	push   $0x0
  pushl $183
80107c4f:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107c54:	e9 cf f1 ff ff       	jmp    80106e28 <alltraps>

80107c59 <vector184>:
.globl vector184
vector184:
  pushl $0
80107c59:	6a 00                	push   $0x0
  pushl $184
80107c5b:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107c60:	e9 c3 f1 ff ff       	jmp    80106e28 <alltraps>

80107c65 <vector185>:
.globl vector185
vector185:
  pushl $0
80107c65:	6a 00                	push   $0x0
  pushl $185
80107c67:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c6c:	e9 b7 f1 ff ff       	jmp    80106e28 <alltraps>

80107c71 <vector186>:
.globl vector186
vector186:
  pushl $0
80107c71:	6a 00                	push   $0x0
  pushl $186
80107c73:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c78:	e9 ab f1 ff ff       	jmp    80106e28 <alltraps>

80107c7d <vector187>:
.globl vector187
vector187:
  pushl $0
80107c7d:	6a 00                	push   $0x0
  pushl $187
80107c7f:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c84:	e9 9f f1 ff ff       	jmp    80106e28 <alltraps>

80107c89 <vector188>:
.globl vector188
vector188:
  pushl $0
80107c89:	6a 00                	push   $0x0
  pushl $188
80107c8b:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c90:	e9 93 f1 ff ff       	jmp    80106e28 <alltraps>

80107c95 <vector189>:
.globl vector189
vector189:
  pushl $0
80107c95:	6a 00                	push   $0x0
  pushl $189
80107c97:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c9c:	e9 87 f1 ff ff       	jmp    80106e28 <alltraps>

80107ca1 <vector190>:
.globl vector190
vector190:
  pushl $0
80107ca1:	6a 00                	push   $0x0
  pushl $190
80107ca3:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107ca8:	e9 7b f1 ff ff       	jmp    80106e28 <alltraps>

80107cad <vector191>:
.globl vector191
vector191:
  pushl $0
80107cad:	6a 00                	push   $0x0
  pushl $191
80107caf:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107cb4:	e9 6f f1 ff ff       	jmp    80106e28 <alltraps>

80107cb9 <vector192>:
.globl vector192
vector192:
  pushl $0
80107cb9:	6a 00                	push   $0x0
  pushl $192
80107cbb:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107cc0:	e9 63 f1 ff ff       	jmp    80106e28 <alltraps>

80107cc5 <vector193>:
.globl vector193
vector193:
  pushl $0
80107cc5:	6a 00                	push   $0x0
  pushl $193
80107cc7:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107ccc:	e9 57 f1 ff ff       	jmp    80106e28 <alltraps>

80107cd1 <vector194>:
.globl vector194
vector194:
  pushl $0
80107cd1:	6a 00                	push   $0x0
  pushl $194
80107cd3:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107cd8:	e9 4b f1 ff ff       	jmp    80106e28 <alltraps>

80107cdd <vector195>:
.globl vector195
vector195:
  pushl $0
80107cdd:	6a 00                	push   $0x0
  pushl $195
80107cdf:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107ce4:	e9 3f f1 ff ff       	jmp    80106e28 <alltraps>

80107ce9 <vector196>:
.globl vector196
vector196:
  pushl $0
80107ce9:	6a 00                	push   $0x0
  pushl $196
80107ceb:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107cf0:	e9 33 f1 ff ff       	jmp    80106e28 <alltraps>

80107cf5 <vector197>:
.globl vector197
vector197:
  pushl $0
80107cf5:	6a 00                	push   $0x0
  pushl $197
80107cf7:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107cfc:	e9 27 f1 ff ff       	jmp    80106e28 <alltraps>

80107d01 <vector198>:
.globl vector198
vector198:
  pushl $0
80107d01:	6a 00                	push   $0x0
  pushl $198
80107d03:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107d08:	e9 1b f1 ff ff       	jmp    80106e28 <alltraps>

80107d0d <vector199>:
.globl vector199
vector199:
  pushl $0
80107d0d:	6a 00                	push   $0x0
  pushl $199
80107d0f:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107d14:	e9 0f f1 ff ff       	jmp    80106e28 <alltraps>

80107d19 <vector200>:
.globl vector200
vector200:
  pushl $0
80107d19:	6a 00                	push   $0x0
  pushl $200
80107d1b:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107d20:	e9 03 f1 ff ff       	jmp    80106e28 <alltraps>

80107d25 <vector201>:
.globl vector201
vector201:
  pushl $0
80107d25:	6a 00                	push   $0x0
  pushl $201
80107d27:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107d2c:	e9 f7 f0 ff ff       	jmp    80106e28 <alltraps>

80107d31 <vector202>:
.globl vector202
vector202:
  pushl $0
80107d31:	6a 00                	push   $0x0
  pushl $202
80107d33:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107d38:	e9 eb f0 ff ff       	jmp    80106e28 <alltraps>

80107d3d <vector203>:
.globl vector203
vector203:
  pushl $0
80107d3d:	6a 00                	push   $0x0
  pushl $203
80107d3f:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107d44:	e9 df f0 ff ff       	jmp    80106e28 <alltraps>

80107d49 <vector204>:
.globl vector204
vector204:
  pushl $0
80107d49:	6a 00                	push   $0x0
  pushl $204
80107d4b:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107d50:	e9 d3 f0 ff ff       	jmp    80106e28 <alltraps>

80107d55 <vector205>:
.globl vector205
vector205:
  pushl $0
80107d55:	6a 00                	push   $0x0
  pushl $205
80107d57:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107d5c:	e9 c7 f0 ff ff       	jmp    80106e28 <alltraps>

80107d61 <vector206>:
.globl vector206
vector206:
  pushl $0
80107d61:	6a 00                	push   $0x0
  pushl $206
80107d63:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107d68:	e9 bb f0 ff ff       	jmp    80106e28 <alltraps>

80107d6d <vector207>:
.globl vector207
vector207:
  pushl $0
80107d6d:	6a 00                	push   $0x0
  pushl $207
80107d6f:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d74:	e9 af f0 ff ff       	jmp    80106e28 <alltraps>

80107d79 <vector208>:
.globl vector208
vector208:
  pushl $0
80107d79:	6a 00                	push   $0x0
  pushl $208
80107d7b:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d80:	e9 a3 f0 ff ff       	jmp    80106e28 <alltraps>

80107d85 <vector209>:
.globl vector209
vector209:
  pushl $0
80107d85:	6a 00                	push   $0x0
  pushl $209
80107d87:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d8c:	e9 97 f0 ff ff       	jmp    80106e28 <alltraps>

80107d91 <vector210>:
.globl vector210
vector210:
  pushl $0
80107d91:	6a 00                	push   $0x0
  pushl $210
80107d93:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d98:	e9 8b f0 ff ff       	jmp    80106e28 <alltraps>

80107d9d <vector211>:
.globl vector211
vector211:
  pushl $0
80107d9d:	6a 00                	push   $0x0
  pushl $211
80107d9f:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107da4:	e9 7f f0 ff ff       	jmp    80106e28 <alltraps>

80107da9 <vector212>:
.globl vector212
vector212:
  pushl $0
80107da9:	6a 00                	push   $0x0
  pushl $212
80107dab:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107db0:	e9 73 f0 ff ff       	jmp    80106e28 <alltraps>

80107db5 <vector213>:
.globl vector213
vector213:
  pushl $0
80107db5:	6a 00                	push   $0x0
  pushl $213
80107db7:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107dbc:	e9 67 f0 ff ff       	jmp    80106e28 <alltraps>

80107dc1 <vector214>:
.globl vector214
vector214:
  pushl $0
80107dc1:	6a 00                	push   $0x0
  pushl $214
80107dc3:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107dc8:	e9 5b f0 ff ff       	jmp    80106e28 <alltraps>

80107dcd <vector215>:
.globl vector215
vector215:
  pushl $0
80107dcd:	6a 00                	push   $0x0
  pushl $215
80107dcf:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107dd4:	e9 4f f0 ff ff       	jmp    80106e28 <alltraps>

80107dd9 <vector216>:
.globl vector216
vector216:
  pushl $0
80107dd9:	6a 00                	push   $0x0
  pushl $216
80107ddb:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107de0:	e9 43 f0 ff ff       	jmp    80106e28 <alltraps>

80107de5 <vector217>:
.globl vector217
vector217:
  pushl $0
80107de5:	6a 00                	push   $0x0
  pushl $217
80107de7:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107dec:	e9 37 f0 ff ff       	jmp    80106e28 <alltraps>

80107df1 <vector218>:
.globl vector218
vector218:
  pushl $0
80107df1:	6a 00                	push   $0x0
  pushl $218
80107df3:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107df8:	e9 2b f0 ff ff       	jmp    80106e28 <alltraps>

80107dfd <vector219>:
.globl vector219
vector219:
  pushl $0
80107dfd:	6a 00                	push   $0x0
  pushl $219
80107dff:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107e04:	e9 1f f0 ff ff       	jmp    80106e28 <alltraps>

80107e09 <vector220>:
.globl vector220
vector220:
  pushl $0
80107e09:	6a 00                	push   $0x0
  pushl $220
80107e0b:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107e10:	e9 13 f0 ff ff       	jmp    80106e28 <alltraps>

80107e15 <vector221>:
.globl vector221
vector221:
  pushl $0
80107e15:	6a 00                	push   $0x0
  pushl $221
80107e17:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107e1c:	e9 07 f0 ff ff       	jmp    80106e28 <alltraps>

80107e21 <vector222>:
.globl vector222
vector222:
  pushl $0
80107e21:	6a 00                	push   $0x0
  pushl $222
80107e23:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107e28:	e9 fb ef ff ff       	jmp    80106e28 <alltraps>

80107e2d <vector223>:
.globl vector223
vector223:
  pushl $0
80107e2d:	6a 00                	push   $0x0
  pushl $223
80107e2f:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107e34:	e9 ef ef ff ff       	jmp    80106e28 <alltraps>

80107e39 <vector224>:
.globl vector224
vector224:
  pushl $0
80107e39:	6a 00                	push   $0x0
  pushl $224
80107e3b:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107e40:	e9 e3 ef ff ff       	jmp    80106e28 <alltraps>

80107e45 <vector225>:
.globl vector225
vector225:
  pushl $0
80107e45:	6a 00                	push   $0x0
  pushl $225
80107e47:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107e4c:	e9 d7 ef ff ff       	jmp    80106e28 <alltraps>

80107e51 <vector226>:
.globl vector226
vector226:
  pushl $0
80107e51:	6a 00                	push   $0x0
  pushl $226
80107e53:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107e58:	e9 cb ef ff ff       	jmp    80106e28 <alltraps>

80107e5d <vector227>:
.globl vector227
vector227:
  pushl $0
80107e5d:	6a 00                	push   $0x0
  pushl $227
80107e5f:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107e64:	e9 bf ef ff ff       	jmp    80106e28 <alltraps>

80107e69 <vector228>:
.globl vector228
vector228:
  pushl $0
80107e69:	6a 00                	push   $0x0
  pushl $228
80107e6b:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e70:	e9 b3 ef ff ff       	jmp    80106e28 <alltraps>

80107e75 <vector229>:
.globl vector229
vector229:
  pushl $0
80107e75:	6a 00                	push   $0x0
  pushl $229
80107e77:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e7c:	e9 a7 ef ff ff       	jmp    80106e28 <alltraps>

80107e81 <vector230>:
.globl vector230
vector230:
  pushl $0
80107e81:	6a 00                	push   $0x0
  pushl $230
80107e83:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e88:	e9 9b ef ff ff       	jmp    80106e28 <alltraps>

80107e8d <vector231>:
.globl vector231
vector231:
  pushl $0
80107e8d:	6a 00                	push   $0x0
  pushl $231
80107e8f:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e94:	e9 8f ef ff ff       	jmp    80106e28 <alltraps>

80107e99 <vector232>:
.globl vector232
vector232:
  pushl $0
80107e99:	6a 00                	push   $0x0
  pushl $232
80107e9b:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107ea0:	e9 83 ef ff ff       	jmp    80106e28 <alltraps>

80107ea5 <vector233>:
.globl vector233
vector233:
  pushl $0
80107ea5:	6a 00                	push   $0x0
  pushl $233
80107ea7:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107eac:	e9 77 ef ff ff       	jmp    80106e28 <alltraps>

80107eb1 <vector234>:
.globl vector234
vector234:
  pushl $0
80107eb1:	6a 00                	push   $0x0
  pushl $234
80107eb3:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107eb8:	e9 6b ef ff ff       	jmp    80106e28 <alltraps>

80107ebd <vector235>:
.globl vector235
vector235:
  pushl $0
80107ebd:	6a 00                	push   $0x0
  pushl $235
80107ebf:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107ec4:	e9 5f ef ff ff       	jmp    80106e28 <alltraps>

80107ec9 <vector236>:
.globl vector236
vector236:
  pushl $0
80107ec9:	6a 00                	push   $0x0
  pushl $236
80107ecb:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107ed0:	e9 53 ef ff ff       	jmp    80106e28 <alltraps>

80107ed5 <vector237>:
.globl vector237
vector237:
  pushl $0
80107ed5:	6a 00                	push   $0x0
  pushl $237
80107ed7:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107edc:	e9 47 ef ff ff       	jmp    80106e28 <alltraps>

80107ee1 <vector238>:
.globl vector238
vector238:
  pushl $0
80107ee1:	6a 00                	push   $0x0
  pushl $238
80107ee3:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107ee8:	e9 3b ef ff ff       	jmp    80106e28 <alltraps>

80107eed <vector239>:
.globl vector239
vector239:
  pushl $0
80107eed:	6a 00                	push   $0x0
  pushl $239
80107eef:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107ef4:	e9 2f ef ff ff       	jmp    80106e28 <alltraps>

80107ef9 <vector240>:
.globl vector240
vector240:
  pushl $0
80107ef9:	6a 00                	push   $0x0
  pushl $240
80107efb:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107f00:	e9 23 ef ff ff       	jmp    80106e28 <alltraps>

80107f05 <vector241>:
.globl vector241
vector241:
  pushl $0
80107f05:	6a 00                	push   $0x0
  pushl $241
80107f07:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107f0c:	e9 17 ef ff ff       	jmp    80106e28 <alltraps>

80107f11 <vector242>:
.globl vector242
vector242:
  pushl $0
80107f11:	6a 00                	push   $0x0
  pushl $242
80107f13:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107f18:	e9 0b ef ff ff       	jmp    80106e28 <alltraps>

80107f1d <vector243>:
.globl vector243
vector243:
  pushl $0
80107f1d:	6a 00                	push   $0x0
  pushl $243
80107f1f:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107f24:	e9 ff ee ff ff       	jmp    80106e28 <alltraps>

80107f29 <vector244>:
.globl vector244
vector244:
  pushl $0
80107f29:	6a 00                	push   $0x0
  pushl $244
80107f2b:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107f30:	e9 f3 ee ff ff       	jmp    80106e28 <alltraps>

80107f35 <vector245>:
.globl vector245
vector245:
  pushl $0
80107f35:	6a 00                	push   $0x0
  pushl $245
80107f37:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107f3c:	e9 e7 ee ff ff       	jmp    80106e28 <alltraps>

80107f41 <vector246>:
.globl vector246
vector246:
  pushl $0
80107f41:	6a 00                	push   $0x0
  pushl $246
80107f43:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107f48:	e9 db ee ff ff       	jmp    80106e28 <alltraps>

80107f4d <vector247>:
.globl vector247
vector247:
  pushl $0
80107f4d:	6a 00                	push   $0x0
  pushl $247
80107f4f:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107f54:	e9 cf ee ff ff       	jmp    80106e28 <alltraps>

80107f59 <vector248>:
.globl vector248
vector248:
  pushl $0
80107f59:	6a 00                	push   $0x0
  pushl $248
80107f5b:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107f60:	e9 c3 ee ff ff       	jmp    80106e28 <alltraps>

80107f65 <vector249>:
.globl vector249
vector249:
  pushl $0
80107f65:	6a 00                	push   $0x0
  pushl $249
80107f67:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f6c:	e9 b7 ee ff ff       	jmp    80106e28 <alltraps>

80107f71 <vector250>:
.globl vector250
vector250:
  pushl $0
80107f71:	6a 00                	push   $0x0
  pushl $250
80107f73:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f78:	e9 ab ee ff ff       	jmp    80106e28 <alltraps>

80107f7d <vector251>:
.globl vector251
vector251:
  pushl $0
80107f7d:	6a 00                	push   $0x0
  pushl $251
80107f7f:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f84:	e9 9f ee ff ff       	jmp    80106e28 <alltraps>

80107f89 <vector252>:
.globl vector252
vector252:
  pushl $0
80107f89:	6a 00                	push   $0x0
  pushl $252
80107f8b:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f90:	e9 93 ee ff ff       	jmp    80106e28 <alltraps>

80107f95 <vector253>:
.globl vector253
vector253:
  pushl $0
80107f95:	6a 00                	push   $0x0
  pushl $253
80107f97:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f9c:	e9 87 ee ff ff       	jmp    80106e28 <alltraps>

80107fa1 <vector254>:
.globl vector254
vector254:
  pushl $0
80107fa1:	6a 00                	push   $0x0
  pushl $254
80107fa3:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107fa8:	e9 7b ee ff ff       	jmp    80106e28 <alltraps>

80107fad <vector255>:
.globl vector255
vector255:
  pushl $0
80107fad:	6a 00                	push   $0x0
  pushl $255
80107faf:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107fb4:	e9 6f ee ff ff       	jmp    80106e28 <alltraps>

80107fb9 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107fb9:	55                   	push   %ebp
80107fba:	89 e5                	mov    %esp,%ebp
80107fbc:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fc2:	83 e8 01             	sub    $0x1,%eax
80107fc5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107fc9:	8b 45 08             	mov    0x8(%ebp),%eax
80107fcc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107fd0:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd3:	c1 e8 10             	shr    $0x10,%eax
80107fd6:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107fda:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107fdd:	0f 01 10             	lgdtl  (%eax)
}
80107fe0:	c9                   	leave  
80107fe1:	c3                   	ret    

80107fe2 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107fe2:	55                   	push   %ebp
80107fe3:	89 e5                	mov    %esp,%ebp
80107fe5:	83 ec 04             	sub    $0x4,%esp
80107fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80107feb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107fef:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107ff3:	0f 00 d8             	ltr    %ax
}
80107ff6:	c9                   	leave  
80107ff7:	c3                   	ret    

80107ff8 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107ff8:	55                   	push   %ebp
80107ff9:	89 e5                	mov    %esp,%ebp
80107ffb:	83 ec 04             	sub    $0x4,%esp
80107ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80108001:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108005:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108009:	8e e8                	mov    %eax,%gs
}
8010800b:	c9                   	leave  
8010800c:	c3                   	ret    

8010800d <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010800d:	55                   	push   %ebp
8010800e:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80108010:	8b 45 08             	mov    0x8(%ebp),%eax
80108013:	0f 22 d8             	mov    %eax,%cr3
}
80108016:	5d                   	pop    %ebp
80108017:	c3                   	ret    

80108018 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108018:	55                   	push   %ebp
80108019:	89 e5                	mov    %esp,%ebp
8010801b:	8b 45 08             	mov    0x8(%ebp),%eax
8010801e:	05 00 00 00 80       	add    $0x80000000,%eax
80108023:	5d                   	pop    %ebp
80108024:	c3                   	ret    

80108025 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108025:	55                   	push   %ebp
80108026:	89 e5                	mov    %esp,%ebp
80108028:	8b 45 08             	mov    0x8(%ebp),%eax
8010802b:	05 00 00 00 80       	add    $0x80000000,%eax
80108030:	5d                   	pop    %ebp
80108031:	c3                   	ret    

80108032 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108032:	55                   	push   %ebp
80108033:	89 e5                	mov    %esp,%ebp
80108035:	53                   	push   %ebx
80108036:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108039:	e8 ce b5 ff ff       	call   8010360c <cpunum>
8010803e:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108044:	05 60 43 11 80       	add    $0x80114360,%eax
80108049:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010804c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010804f:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108055:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108058:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010805e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108061:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108065:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108068:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010806c:	83 e2 f0             	and    $0xfffffff0,%edx
8010806f:	83 ca 0a             	or     $0xa,%edx
80108072:	88 50 7d             	mov    %dl,0x7d(%eax)
80108075:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108078:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010807c:	83 ca 10             	or     $0x10,%edx
8010807f:	88 50 7d             	mov    %dl,0x7d(%eax)
80108082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108085:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108089:	83 e2 9f             	and    $0xffffff9f,%edx
8010808c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010808f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108092:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108096:	83 ca 80             	or     $0xffffff80,%edx
80108099:	88 50 7d             	mov    %dl,0x7d(%eax)
8010809c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080a3:	83 ca 0f             	or     $0xf,%edx
801080a6:	88 50 7e             	mov    %dl,0x7e(%eax)
801080a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ac:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080b0:	83 e2 ef             	and    $0xffffffef,%edx
801080b3:	88 50 7e             	mov    %dl,0x7e(%eax)
801080b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080bd:	83 e2 df             	and    $0xffffffdf,%edx
801080c0:	88 50 7e             	mov    %dl,0x7e(%eax)
801080c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080ca:	83 ca 40             	or     $0x40,%edx
801080cd:	88 50 7e             	mov    %dl,0x7e(%eax)
801080d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d3:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080d7:	83 ca 80             	or     $0xffffff80,%edx
801080da:	88 50 7e             	mov    %dl,0x7e(%eax)
801080dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e0:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801080e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e7:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801080ee:	ff ff 
801080f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f3:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801080fa:	00 00 
801080fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ff:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108106:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108109:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108110:	83 e2 f0             	and    $0xfffffff0,%edx
80108113:	83 ca 02             	or     $0x2,%edx
80108116:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010811c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811f:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108126:	83 ca 10             	or     $0x10,%edx
80108129:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010812f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108132:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108139:	83 e2 9f             	and    $0xffffff9f,%edx
8010813c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108145:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010814c:	83 ca 80             	or     $0xffffff80,%edx
8010814f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108158:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010815f:	83 ca 0f             	or     $0xf,%edx
80108162:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108168:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108172:	83 e2 ef             	and    $0xffffffef,%edx
80108175:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010817b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108185:	83 e2 df             	and    $0xffffffdf,%edx
80108188:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010818e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108191:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108198:	83 ca 40             	or     $0x40,%edx
8010819b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801081a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a4:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801081ab:	83 ca 80             	or     $0xffffff80,%edx
801081ae:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801081b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b7:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801081be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c1:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801081c8:	ff ff 
801081ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081cd:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801081d4:	00 00 
801081d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d9:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801081e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081ea:	83 e2 f0             	and    $0xfffffff0,%edx
801081ed:	83 ca 0a             	or     $0xa,%edx
801081f0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f9:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108200:	83 ca 10             	or     $0x10,%edx
80108203:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108209:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108213:	83 ca 60             	or     $0x60,%edx
80108216:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010821c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010821f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108226:	83 ca 80             	or     $0xffffff80,%edx
80108229:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010822f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108232:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108239:	83 ca 0f             	or     $0xf,%edx
8010823c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108242:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108245:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010824c:	83 e2 ef             	and    $0xffffffef,%edx
8010824f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108255:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108258:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010825f:	83 e2 df             	and    $0xffffffdf,%edx
80108262:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108272:	83 ca 40             	or     $0x40,%edx
80108275:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010827b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010827e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108285:	83 ca 80             	or     $0xffffff80,%edx
80108288:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010828e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108291:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829b:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801082a2:	ff ff 
801082a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a7:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801082ae:	00 00 
801082b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b3:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801082ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082bd:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082c4:	83 e2 f0             	and    $0xfffffff0,%edx
801082c7:	83 ca 02             	or     $0x2,%edx
801082ca:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082da:	83 ca 10             	or     $0x10,%edx
801082dd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082ed:	83 ca 60             	or     $0x60,%edx
801082f0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108300:	83 ca 80             	or     $0xffffff80,%edx
80108303:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830c:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108313:	83 ca 0f             	or     $0xf,%edx
80108316:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010831c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108326:	83 e2 ef             	and    $0xffffffef,%edx
80108329:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010832f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108332:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108339:	83 e2 df             	and    $0xffffffdf,%edx
8010833c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108345:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010834c:	83 ca 40             	or     $0x40,%edx
8010834f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108355:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108358:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010835f:	83 ca 80             	or     $0xffffff80,%edx
80108362:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108368:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836b:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108372:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108375:	05 b4 00 00 00       	add    $0xb4,%eax
8010837a:	89 c3                	mov    %eax,%ebx
8010837c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837f:	05 b4 00 00 00       	add    $0xb4,%eax
80108384:	c1 e8 10             	shr    $0x10,%eax
80108387:	89 c1                	mov    %eax,%ecx
80108389:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010838c:	05 b4 00 00 00       	add    $0xb4,%eax
80108391:	c1 e8 18             	shr    $0x18,%eax
80108394:	89 c2                	mov    %eax,%edx
80108396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108399:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801083a0:	00 00 
801083a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a5:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801083ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083af:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801083b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b8:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083bf:	83 e1 f0             	and    $0xfffffff0,%ecx
801083c2:	83 c9 02             	or     $0x2,%ecx
801083c5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ce:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083d5:	83 c9 10             	or     $0x10,%ecx
801083d8:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e1:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083e8:	83 e1 9f             	and    $0xffffff9f,%ecx
801083eb:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083fb:	83 c9 80             	or     $0xffffff80,%ecx
801083fe:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108404:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108407:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010840e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108411:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108417:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010841a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108421:	83 e1 ef             	and    $0xffffffef,%ecx
80108424:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010842a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108434:	83 e1 df             	and    $0xffffffdf,%ecx
80108437:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010843d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108440:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108447:	83 c9 40             	or     $0x40,%ecx
8010844a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108450:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108453:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010845a:	83 c9 80             	or     $0xffffff80,%ecx
8010845d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108466:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010846c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010846f:	83 c0 70             	add    $0x70,%eax
80108472:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108479:	00 
8010847a:	89 04 24             	mov    %eax,(%esp)
8010847d:	e8 37 fb ff ff       	call   80107fb9 <lgdt>
  loadgs(SEG_KCPU << 3);
80108482:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108489:	e8 6a fb ff ff       	call   80107ff8 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010848e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108491:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108497:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010849e:	00 00 00 00 
}
801084a2:	83 c4 24             	add    $0x24,%esp
801084a5:	5b                   	pop    %ebx
801084a6:	5d                   	pop    %ebp
801084a7:	c3                   	ret    

801084a8 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801084a8:	55                   	push   %ebp
801084a9:	89 e5                	mov    %esp,%ebp
801084ab:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801084ae:	8b 45 0c             	mov    0xc(%ebp),%eax
801084b1:	c1 e8 16             	shr    $0x16,%eax
801084b4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084bb:	8b 45 08             	mov    0x8(%ebp),%eax
801084be:	01 d0                	add    %edx,%eax
801084c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801084c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084c6:	8b 00                	mov    (%eax),%eax
801084c8:	83 e0 01             	and    $0x1,%eax
801084cb:	85 c0                	test   %eax,%eax
801084cd:	74 17                	je     801084e6 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801084cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084d2:	8b 00                	mov    (%eax),%eax
801084d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084d9:	89 04 24             	mov    %eax,(%esp)
801084dc:	e8 44 fb ff ff       	call   80108025 <p2v>
801084e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084e4:	eb 4b                	jmp    80108531 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801084e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801084ea:	74 0e                	je     801084fa <walkpgdir+0x52>
801084ec:	e8 3f ad ff ff       	call   80103230 <kalloc>
801084f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801084f8:	75 07                	jne    80108501 <walkpgdir+0x59>
      return 0;
801084fa:	b8 00 00 00 00       	mov    $0x0,%eax
801084ff:	eb 47                	jmp    80108548 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108501:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108508:	00 
80108509:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108510:	00 
80108511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108514:	89 04 24             	mov    %eax,(%esp)
80108517:	e8 18 d5 ff ff       	call   80105a34 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
8010851c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010851f:	89 04 24             	mov    %eax,(%esp)
80108522:	e8 f1 fa ff ff       	call   80108018 <v2p>
80108527:	83 c8 07             	or     $0x7,%eax
8010852a:	89 c2                	mov    %eax,%edx
8010852c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010852f:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108531:	8b 45 0c             	mov    0xc(%ebp),%eax
80108534:	c1 e8 0c             	shr    $0xc,%eax
80108537:	25 ff 03 00 00       	and    $0x3ff,%eax
8010853c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108543:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108546:	01 d0                	add    %edx,%eax
}
80108548:	c9                   	leave  
80108549:	c3                   	ret    

8010854a <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010854a:	55                   	push   %ebp
8010854b:	89 e5                	mov    %esp,%ebp
8010854d:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108550:	8b 45 0c             	mov    0xc(%ebp),%eax
80108553:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108558:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010855b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010855e:	8b 45 10             	mov    0x10(%ebp),%eax
80108561:	01 d0                	add    %edx,%eax
80108563:	83 e8 01             	sub    $0x1,%eax
80108566:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010856b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010856e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108575:	00 
80108576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108579:	89 44 24 04          	mov    %eax,0x4(%esp)
8010857d:	8b 45 08             	mov    0x8(%ebp),%eax
80108580:	89 04 24             	mov    %eax,(%esp)
80108583:	e8 20 ff ff ff       	call   801084a8 <walkpgdir>
80108588:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010858b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010858f:	75 07                	jne    80108598 <mappages+0x4e>
      return -1;
80108591:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108596:	eb 48                	jmp    801085e0 <mappages+0x96>
    if(*pte & PTE_P)
80108598:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010859b:	8b 00                	mov    (%eax),%eax
8010859d:	83 e0 01             	and    $0x1,%eax
801085a0:	85 c0                	test   %eax,%eax
801085a2:	74 0c                	je     801085b0 <mappages+0x66>
      panic("remap");
801085a4:	c7 04 24 20 a2 10 80 	movl   $0x8010a220,(%esp)
801085ab:	e8 8a 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801085b0:	8b 45 18             	mov    0x18(%ebp),%eax
801085b3:	0b 45 14             	or     0x14(%ebp),%eax
801085b6:	83 c8 01             	or     $0x1,%eax
801085b9:	89 c2                	mov    %eax,%edx
801085bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085be:	89 10                	mov    %edx,(%eax)
    if(a == last)
801085c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085c3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801085c6:	75 08                	jne    801085d0 <mappages+0x86>
      break;
801085c8:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801085c9:	b8 00 00 00 00       	mov    $0x0,%eax
801085ce:	eb 10                	jmp    801085e0 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801085d0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801085d7:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801085de:	eb 8e                	jmp    8010856e <mappages+0x24>
  return 0;
}
801085e0:	c9                   	leave  
801085e1:	c3                   	ret    

801085e2 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801085e2:	55                   	push   %ebp
801085e3:	89 e5                	mov    %esp,%ebp
801085e5:	53                   	push   %ebx
801085e6:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801085e9:	e8 42 ac ff ff       	call   80103230 <kalloc>
801085ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
801085f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085f5:	75 0a                	jne    80108601 <setupkvm+0x1f>
    return 0;
801085f7:	b8 00 00 00 00       	mov    $0x0,%eax
801085fc:	e9 98 00 00 00       	jmp    80108699 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108601:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108608:	00 
80108609:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108610:	00 
80108611:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108614:	89 04 24             	mov    %eax,(%esp)
80108617:	e8 18 d4 ff ff       	call   80105a34 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010861c:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108623:	e8 fd f9 ff ff       	call   80108025 <p2v>
80108628:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
8010862d:	76 0c                	jbe    8010863b <setupkvm+0x59>
    panic("PHYSTOP too high");
8010862f:	c7 04 24 26 a2 10 80 	movl   $0x8010a226,(%esp)
80108636:	e8 ff 7e ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010863b:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
80108642:	eb 49                	jmp    8010868d <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108647:	8b 48 0c             	mov    0xc(%eax),%ecx
8010864a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010864d:	8b 50 04             	mov    0x4(%eax),%edx
80108650:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108653:	8b 58 08             	mov    0x8(%eax),%ebx
80108656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108659:	8b 40 04             	mov    0x4(%eax),%eax
8010865c:	29 c3                	sub    %eax,%ebx
8010865e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108661:	8b 00                	mov    (%eax),%eax
80108663:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108667:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010866b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010866f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108673:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108676:	89 04 24             	mov    %eax,(%esp)
80108679:	e8 cc fe ff ff       	call   8010854a <mappages>
8010867e:	85 c0                	test   %eax,%eax
80108680:	79 07                	jns    80108689 <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108682:	b8 00 00 00 00       	mov    $0x0,%eax
80108687:	eb 10                	jmp    80108699 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108689:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010868d:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108694:	72 ae                	jb     80108644 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
80108696:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
80108699:	83 c4 34             	add    $0x34,%esp
8010869c:	5b                   	pop    %ebx
8010869d:	5d                   	pop    %ebp
8010869e:	c3                   	ret    

8010869f <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
8010869f:	55                   	push   %ebp
801086a0:	89 e5                	mov    %esp,%ebp
801086a2:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
801086a5:	e8 38 ff ff ff       	call   801085e2 <setupkvm>
801086aa:	a3 58 0e 12 80       	mov    %eax,0x80120e58
    switchkvm();
801086af:	e8 02 00 00 00       	call   801086b6 <switchkvm>
  }
801086b4:	c9                   	leave  
801086b5:	c3                   	ret    

801086b6 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
801086b6:	55                   	push   %ebp
801086b7:	89 e5                	mov    %esp,%ebp
801086b9:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801086bc:	a1 58 0e 12 80       	mov    0x80120e58,%eax
801086c1:	89 04 24             	mov    %eax,(%esp)
801086c4:	e8 4f f9 ff ff       	call   80108018 <v2p>
801086c9:	89 04 24             	mov    %eax,(%esp)
801086cc:	e8 3c f9 ff ff       	call   8010800d <lcr3>
}
801086d1:	c9                   	leave  
801086d2:	c3                   	ret    

801086d3 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801086d3:	55                   	push   %ebp
801086d4:	89 e5                	mov    %esp,%ebp
801086d6:	53                   	push   %ebx
801086d7:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801086da:	e8 55 d2 ff ff       	call   80105934 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801086df:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086e5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086ec:	83 c2 08             	add    $0x8,%edx
801086ef:	89 d3                	mov    %edx,%ebx
801086f1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086f8:	83 c2 08             	add    $0x8,%edx
801086fb:	c1 ea 10             	shr    $0x10,%edx
801086fe:	89 d1                	mov    %edx,%ecx
80108700:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108707:	83 c2 08             	add    $0x8,%edx
8010870a:	c1 ea 18             	shr    $0x18,%edx
8010870d:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108714:	67 00 
80108716:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010871d:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108723:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010872a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010872d:	83 c9 09             	or     $0x9,%ecx
80108730:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108736:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010873d:	83 c9 10             	or     $0x10,%ecx
80108740:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108746:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010874d:	83 e1 9f             	and    $0xffffff9f,%ecx
80108750:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108756:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010875d:	83 c9 80             	or     $0xffffff80,%ecx
80108760:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108766:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010876d:	83 e1 f0             	and    $0xfffffff0,%ecx
80108770:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108776:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010877d:	83 e1 ef             	and    $0xffffffef,%ecx
80108780:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108786:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010878d:	83 e1 df             	and    $0xffffffdf,%ecx
80108790:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108796:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010879d:	83 c9 40             	or     $0x40,%ecx
801087a0:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801087a6:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801087ad:	83 e1 7f             	and    $0x7f,%ecx
801087b0:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801087b6:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801087bc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087c2:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801087c9:	83 e2 ef             	and    $0xffffffef,%edx
801087cc:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801087d2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087d8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801087de:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087e4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801087eb:	8b 52 08             	mov    0x8(%edx),%edx
801087ee:	81 c2 00 10 00 00    	add    $0x1000,%edx
801087f4:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801087f7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801087fe:	e8 df f7 ff ff       	call   80107fe2 <ltr>
  if(p->pgdir == 0)
80108803:	8b 45 08             	mov    0x8(%ebp),%eax
80108806:	8b 40 04             	mov    0x4(%eax),%eax
80108809:	85 c0                	test   %eax,%eax
8010880b:	75 0c                	jne    80108819 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
8010880d:	c7 04 24 37 a2 10 80 	movl   $0x8010a237,(%esp)
80108814:	e8 21 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108819:	8b 45 08             	mov    0x8(%ebp),%eax
8010881c:	8b 40 04             	mov    0x4(%eax),%eax
8010881f:	89 04 24             	mov    %eax,(%esp)
80108822:	e8 f1 f7 ff ff       	call   80108018 <v2p>
80108827:	89 04 24             	mov    %eax,(%esp)
8010882a:	e8 de f7 ff ff       	call   8010800d <lcr3>
  popcli();
8010882f:	e8 44 d1 ff ff       	call   80105978 <popcli>
}
80108834:	83 c4 14             	add    $0x14,%esp
80108837:	5b                   	pop    %ebx
80108838:	5d                   	pop    %ebp
80108839:	c3                   	ret    

8010883a <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010883a:	55                   	push   %ebp
8010883b:	89 e5                	mov    %esp,%ebp
8010883d:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108840:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108847:	76 0c                	jbe    80108855 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108849:	c7 04 24 4b a2 10 80 	movl   $0x8010a24b,(%esp)
80108850:	e8 e5 7c ff ff       	call   8010053a <panic>
  mem = kalloc();
80108855:	e8 d6 a9 ff ff       	call   80103230 <kalloc>
8010885a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010885d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108864:	00 
80108865:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010886c:	00 
8010886d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108870:	89 04 24             	mov    %eax,(%esp)
80108873:	e8 bc d1 ff ff       	call   80105a34 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010887b:	89 04 24             	mov    %eax,(%esp)
8010887e:	e8 95 f7 ff ff       	call   80108018 <v2p>
80108883:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010888a:	00 
8010888b:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010888f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108896:	00 
80108897:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010889e:	00 
8010889f:	8b 45 08             	mov    0x8(%ebp),%eax
801088a2:	89 04 24             	mov    %eax,(%esp)
801088a5:	e8 a0 fc ff ff       	call   8010854a <mappages>
  memmove(mem, init, sz);
801088aa:	8b 45 10             	mov    0x10(%ebp),%eax
801088ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801088b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801088b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801088b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088bb:	89 04 24             	mov    %eax,(%esp)
801088be:	e8 40 d2 ff ff       	call   80105b03 <memmove>
}
801088c3:	c9                   	leave  
801088c4:	c3                   	ret    

801088c5 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801088c5:	55                   	push   %ebp
801088c6:	89 e5                	mov    %esp,%ebp
801088c8:	53                   	push   %ebx
801088c9:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801088cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801088cf:	25 ff 0f 00 00       	and    $0xfff,%eax
801088d4:	85 c0                	test   %eax,%eax
801088d6:	74 0c                	je     801088e4 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801088d8:	c7 04 24 68 a2 10 80 	movl   $0x8010a268,(%esp)
801088df:	e8 56 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801088e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801088eb:	e9 a9 00 00 00       	jmp    80108999 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801088f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f3:	8b 55 0c             	mov    0xc(%ebp),%edx
801088f6:	01 d0                	add    %edx,%eax
801088f8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088ff:	00 
80108900:	89 44 24 04          	mov    %eax,0x4(%esp)
80108904:	8b 45 08             	mov    0x8(%ebp),%eax
80108907:	89 04 24             	mov    %eax,(%esp)
8010890a:	e8 99 fb ff ff       	call   801084a8 <walkpgdir>
8010890f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108912:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108916:	75 0c                	jne    80108924 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108918:	c7 04 24 8b a2 10 80 	movl   $0x8010a28b,(%esp)
8010891f:	e8 16 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108924:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108927:	8b 00                	mov    (%eax),%eax
80108929:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010892e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108934:	8b 55 18             	mov    0x18(%ebp),%edx
80108937:	29 c2                	sub    %eax,%edx
80108939:	89 d0                	mov    %edx,%eax
8010893b:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108940:	77 0f                	ja     80108951 <loaduvm+0x8c>
      n = sz - i;
80108942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108945:	8b 55 18             	mov    0x18(%ebp),%edx
80108948:	29 c2                	sub    %eax,%edx
8010894a:	89 d0                	mov    %edx,%eax
8010894c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010894f:	eb 07                	jmp    80108958 <loaduvm+0x93>
    else
      n = PGSIZE;
80108951:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895b:	8b 55 14             	mov    0x14(%ebp),%edx
8010895e:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108961:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108964:	89 04 24             	mov    %eax,(%esp)
80108967:	e8 b9 f6 ff ff       	call   80108025 <p2v>
8010896c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010896f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108973:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108977:	89 44 24 04          	mov    %eax,0x4(%esp)
8010897b:	8b 45 10             	mov    0x10(%ebp),%eax
8010897e:	89 04 24             	mov    %eax,(%esp)
80108981:	e8 a7 95 ff ff       	call   80101f2d <readi>
80108986:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108989:	74 07                	je     80108992 <loaduvm+0xcd>
      return -1;
8010898b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108990:	eb 18                	jmp    801089aa <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108992:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010899c:	3b 45 18             	cmp    0x18(%ebp),%eax
8010899f:	0f 82 4b ff ff ff    	jb     801088f0 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801089a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801089aa:	83 c4 24             	add    $0x24,%esp
801089ad:	5b                   	pop    %ebx
801089ae:	5d                   	pop    %ebp
801089af:	c3                   	ret    

801089b0 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
801089b0:	55                   	push   %ebp
801089b1:	89 e5                	mov    %esp,%ebp
801089b3:	53                   	push   %ebx
801089b4:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
801089b7:	8b 45 10             	mov    0x10(%ebp),%eax
801089ba:	85 c0                	test   %eax,%eax
801089bc:	79 0a                	jns    801089c8 <allocuvm+0x18>
    return 0;
801089be:	b8 00 00 00 00       	mov    $0x0,%eax
801089c3:	e9 2d 02 00 00       	jmp    80108bf5 <allocuvm+0x245>
  if(newsz < oldsz)
801089c8:	8b 45 10             	mov    0x10(%ebp),%eax
801089cb:	3b 45 0c             	cmp    0xc(%ebp),%eax
801089ce:	73 08                	jae    801089d8 <allocuvm+0x28>
    return oldsz;
801089d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801089d3:	e9 1d 02 00 00       	jmp    80108bf5 <allocuvm+0x245>

  a = PGROUNDUP(oldsz);
801089d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801089db:	05 ff 0f 00 00       	add    $0xfff,%eax
801089e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801089e8:	e9 f9 01 00 00       	jmp    80108be6 <allocuvm+0x236>
    mem = kalloc();
801089ed:	e8 3e a8 ff ff       	call   80103230 <kalloc>
801089f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
801089f5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089f9:	75 36                	jne    80108a31 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
801089fb:	c7 04 24 a9 a2 10 80 	movl   $0x8010a2a9,(%esp)
80108a02:	e8 99 79 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
80108a07:	8b 45 14             	mov    0x14(%ebp),%eax
80108a0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a11:	89 44 24 08          	mov    %eax,0x8(%esp)
80108a15:	8b 45 10             	mov    0x10(%ebp),%eax
80108a18:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a1c:	8b 45 08             	mov    0x8(%ebp),%eax
80108a1f:	89 04 24             	mov    %eax,(%esp)
80108a22:	e8 d4 01 00 00       	call   80108bfb <deallocuvm>
      return 0;
80108a27:	b8 00 00 00 00       	mov    $0x0,%eax
80108a2c:	e9 c4 01 00 00       	jmp    80108bf5 <allocuvm+0x245>
    }
    memset(mem, 0, PGSIZE);
80108a31:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a38:	00 
80108a39:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a40:	00 
80108a41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a44:	89 04 24             	mov    %eax,(%esp)
80108a47:	e8 e8 cf ff ff       	call   80105a34 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108a4c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a4f:	89 04 24             	mov    %eax,(%esp)
80108a52:	e8 c1 f5 ff ff       	call   80108018 <v2p>
80108a57:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108a5a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a61:	00 
80108a62:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a66:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a6d:	00 
80108a6e:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a72:	8b 45 08             	mov    0x8(%ebp),%eax
80108a75:	89 04 24             	mov    %eax,(%esp)
80108a78:	e8 cd fa ff ff       	call   8010854a <mappages>
    //find the next open cell in pages array
      i=0;
80108a7d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a84:	eb 16                	jmp    80108a9c <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a86:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a8a:	7e 0c                	jle    80108a98 <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a8c:	c7 04 24 c4 a2 10 80 	movl   $0x8010a2c4,(%esp)
80108a93:	e8 a2 7a ff ff       	call   8010053a <panic>
        }
        i++;
80108a98:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a9c:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a9f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108aa2:	89 d0                	mov    %edx,%eax
80108aa4:	c1 e0 02             	shl    $0x2,%eax
80108aa7:	01 d0                	add    %edx,%eax
80108aa9:	c1 e0 02             	shl    $0x2,%eax
80108aac:	01 c8                	add    %ecx,%eax
80108aae:	05 90 00 00 00       	add    $0x90,%eax
80108ab3:	8b 00                	mov    (%eax),%eax
80108ab5:	83 f8 ff             	cmp    $0xffffffff,%eax
80108ab8:	75 cc                	jne    80108a86 <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
80108aba:	e8 c5 0f 00 00       	call   80109a84 <isInit>
80108abf:	85 c0                	test   %eax,%eax
80108ac1:	75 60                	jne    80108b23 <allocuvm+0x173>
80108ac3:	e8 8f 0f 00 00       	call   80109a57 <isShell>
80108ac8:	85 c0                	test   %eax,%eax
80108aca:	75 57                	jne    80108b23 <allocuvm+0x173>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108acc:	8b 45 14             	mov    0x14(%ebp),%eax
80108acf:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ad5:	83 f8 0e             	cmp    $0xe,%eax
80108ad8:	76 32                	jbe    80108b0c <allocuvm+0x15c>
          swapOut();
80108ada:	e8 03 0c 00 00       	call   801096e2 <swapOut>
          lcr3(v2p(proc->pgdir));
80108adf:	8b 45 14             	mov    0x14(%ebp),%eax
80108ae2:	8b 40 04             	mov    0x4(%eax),%eax
80108ae5:	89 04 24             	mov    %eax,(%esp)
80108ae8:	e8 2b f5 ff ff       	call   80108018 <v2p>
80108aed:	89 04 24             	mov    %eax,(%esp)
80108af0:	e8 18 f5 ff ff       	call   8010800d <lcr3>
          proc->swapedPagesCounter++;
80108af5:	8b 45 14             	mov    0x14(%ebp),%eax
80108af8:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108afe:	8d 50 01             	lea    0x1(%eax),%edx
80108b01:	8b 45 14             	mov    0x14(%ebp),%eax
80108b04:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108b0a:	eb 2c                	jmp    80108b38 <allocuvm+0x188>
          swapOut();
          lcr3(v2p(proc->pgdir));
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108b0c:	8b 45 14             	mov    0x14(%ebp),%eax
80108b0f:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108b15:	8d 50 01             	lea    0x1(%eax),%edx
80108b18:	8b 45 14             	mov    0x14(%ebp),%eax
80108b1b:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108b21:	eb 15                	jmp    80108b38 <allocuvm+0x188>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108b23:	8b 45 14             	mov    0x14(%ebp),%eax
80108b26:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108b2c:	8d 50 01             	lea    0x1(%eax),%edx
80108b2f:	8b 45 14             	mov    0x14(%ebp),%eax
80108b32:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108b38:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108b3b:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b3e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b41:	89 d0                	mov    %edx,%eax
80108b43:	c1 e0 02             	shl    $0x2,%eax
80108b46:	01 d0                	add    %edx,%eax
80108b48:	c1 e0 02             	shl    $0x2,%eax
80108b4b:	01 d8                	add    %ebx,%eax
80108b4d:	05 90 00 00 00       	add    $0x90,%eax
80108b52:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108b54:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b57:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b5a:	89 d0                	mov    %edx,%eax
80108b5c:	c1 e0 02             	shl    $0x2,%eax
80108b5f:	01 d0                	add    %edx,%eax
80108b61:	c1 e0 02             	shl    $0x2,%eax
80108b64:	01 c8                	add    %ecx,%eax
80108b66:	05 94 00 00 00       	add    $0x94,%eax
80108b6b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108b71:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b74:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b77:	89 d0                	mov    %edx,%eax
80108b79:	c1 e0 02             	shl    $0x2,%eax
80108b7c:	01 d0                	add    %edx,%eax
80108b7e:	c1 e0 02             	shl    $0x2,%eax
80108b81:	01 c8                	add    %ecx,%eax
80108b83:	05 98 00 00 00       	add    $0x98,%eax
80108b88:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b8e:	8b 45 14             	mov    0x14(%ebp),%eax
80108b91:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b97:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b9a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b9d:	89 d0                	mov    %edx,%eax
80108b9f:	c1 e0 02             	shl    $0x2,%eax
80108ba2:	01 d0                	add    %edx,%eax
80108ba4:	c1 e0 02             	shl    $0x2,%eax
80108ba7:	01 d8                	add    %ebx,%eax
80108ba9:	05 9c 00 00 00       	add    $0x9c,%eax
80108bae:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108bb0:	8b 45 14             	mov    0x14(%ebp),%eax
80108bb3:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108bb9:	8d 50 01             	lea    0x1(%eax),%edx
80108bbc:	8b 45 14             	mov    0x14(%ebp),%eax
80108bbf:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108bc5:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108bc8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108bcb:	89 d0                	mov    %edx,%eax
80108bcd:	c1 e0 02             	shl    $0x2,%eax
80108bd0:	01 d0                	add    %edx,%eax
80108bd2:	c1 e0 02             	shl    $0x2,%eax
80108bd5:	01 c8                	add    %ecx,%eax
80108bd7:	05 a0 00 00 00       	add    $0xa0,%eax
80108bdc:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108bdf:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108be6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be9:	3b 45 10             	cmp    0x10(%ebp),%eax
80108bec:	0f 82 fb fd ff ff    	jb     801089ed <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108bf2:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108bf5:	83 c4 34             	add    $0x34,%esp
80108bf8:	5b                   	pop    %ebx
80108bf9:	5d                   	pop    %ebp
80108bfa:	c3                   	ret    

80108bfb <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108bfb:	55                   	push   %ebp
80108bfc:	89 e5                	mov    %esp,%ebp
80108bfe:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108c01:	8b 45 10             	mov    0x10(%ebp),%eax
80108c04:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c07:	72 08                	jb     80108c11 <deallocuvm+0x16>
    return oldsz;
80108c09:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c0c:	e9 ec 01 00 00       	jmp    80108dfd <deallocuvm+0x202>

  a = PGROUNDUP(newsz);
80108c11:	8b 45 10             	mov    0x10(%ebp),%eax
80108c14:	05 ff 0f 00 00       	add    $0xfff,%eax
80108c19:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108c21:	e9 c8 01 00 00       	jmp    80108dee <deallocuvm+0x1f3>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108c26:	8b 45 14             	mov    0x14(%ebp),%eax
80108c29:	8b 40 04             	mov    0x4(%eax),%eax
80108c2c:	3b 45 08             	cmp    0x8(%ebp),%eax
80108c2f:	0f 85 07 01 00 00    	jne    80108d3c <deallocuvm+0x141>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108c35:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108c3c:	e9 f1 00 00 00       	jmp    80108d32 <deallocuvm+0x137>
          if(proc->pagesMetaData[i].va == (char *)a){
80108c41:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c44:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c47:	89 d0                	mov    %edx,%eax
80108c49:	c1 e0 02             	shl    $0x2,%eax
80108c4c:	01 d0                	add    %edx,%eax
80108c4e:	c1 e0 02             	shl    $0x2,%eax
80108c51:	01 c8                	add    %ecx,%eax
80108c53:	05 90 00 00 00       	add    $0x90,%eax
80108c58:	8b 10                	mov    (%eax),%edx
80108c5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c5d:	39 c2                	cmp    %eax,%edx
80108c5f:	0f 85 c9 00 00 00    	jne    80108d2e <deallocuvm+0x133>
            if((!isShell()) && (!isInit())){
80108c65:	e8 ed 0d 00 00       	call   80109a57 <isShell>
80108c6a:	85 c0                	test   %eax,%eax
80108c6c:	75 54                	jne    80108cc2 <deallocuvm+0xc7>
80108c6e:	e8 11 0e 00 00       	call   80109a84 <isInit>
80108c73:	85 c0                	test   %eax,%eax
80108c75:	75 4b                	jne    80108cc2 <deallocuvm+0xc7>
              if(proc->pagesMetaData[i].isPhysical){
80108c77:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c7a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c7d:	89 d0                	mov    %edx,%eax
80108c7f:	c1 e0 02             	shl    $0x2,%eax
80108c82:	01 d0                	add    %edx,%eax
80108c84:	c1 e0 02             	shl    $0x2,%eax
80108c87:	01 c8                	add    %ecx,%eax
80108c89:	05 94 00 00 00       	add    $0x94,%eax
80108c8e:	8b 00                	mov    (%eax),%eax
80108c90:	85 c0                	test   %eax,%eax
80108c92:	74 17                	je     80108cab <deallocuvm+0xb0>
                proc->memoryPagesCounter--;
80108c94:	8b 45 14             	mov    0x14(%ebp),%eax
80108c97:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c9d:	8d 50 ff             	lea    -0x1(%eax),%edx
80108ca0:	8b 45 14             	mov    0x14(%ebp),%eax
80108ca3:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108ca9:	eb 2c                	jmp    80108cd7 <deallocuvm+0xdc>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108cab:	8b 45 14             	mov    0x14(%ebp),%eax
80108cae:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108cb4:	8d 50 ff             	lea    -0x1(%eax),%edx
80108cb7:	8b 45 14             	mov    0x14(%ebp),%eax
80108cba:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108cc0:	eb 15                	jmp    80108cd7 <deallocuvm+0xdc>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108cc2:	8b 45 14             	mov    0x14(%ebp),%eax
80108cc5:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ccb:	8d 50 ff             	lea    -0x1(%eax),%edx
80108cce:	8b 45 14             	mov    0x14(%ebp),%eax
80108cd1:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108cd7:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cda:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cdd:	89 d0                	mov    %edx,%eax
80108cdf:	c1 e0 02             	shl    $0x2,%eax
80108ce2:	01 d0                	add    %edx,%eax
80108ce4:	c1 e0 02             	shl    $0x2,%eax
80108ce7:	01 c8                	add    %ecx,%eax
80108ce9:	05 90 00 00 00       	add    $0x90,%eax
80108cee:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108cf4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cf7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cfa:	89 d0                	mov    %edx,%eax
80108cfc:	c1 e0 02             	shl    $0x2,%eax
80108cff:	01 d0                	add    %edx,%eax
80108d01:	c1 e0 02             	shl    $0x2,%eax
80108d04:	01 c8                	add    %ecx,%eax
80108d06:	05 94 00 00 00       	add    $0x94,%eax
80108d0b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108d11:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108d14:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d17:	89 d0                	mov    %edx,%eax
80108d19:	c1 e0 02             	shl    $0x2,%eax
80108d1c:	01 d0                	add    %edx,%eax
80108d1e:	c1 e0 02             	shl    $0x2,%eax
80108d21:	01 c8                	add    %ecx,%eax
80108d23:	05 98 00 00 00       	add    $0x98,%eax
80108d28:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108d2e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108d32:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108d36:	0f 8e 05 ff ff ff    	jle    80108c41 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d3f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108d46:	00 
80108d47:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d4b:	8b 45 08             	mov    0x8(%ebp),%eax
80108d4e:	89 04 24             	mov    %eax,(%esp)
80108d51:	e8 52 f7 ff ff       	call   801084a8 <walkpgdir>
80108d56:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108d59:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d5d:	75 09                	jne    80108d68 <deallocuvm+0x16d>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d5f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d66:	eb 7f                	jmp    80108de7 <deallocuvm+0x1ec>
    else if((*pte & PTE_P) != 0){
80108d68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d6b:	8b 00                	mov    (%eax),%eax
80108d6d:	83 e0 01             	and    $0x1,%eax
80108d70:	85 c0                	test   %eax,%eax
80108d72:	74 5c                	je     80108dd0 <deallocuvm+0x1d5>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108d74:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d77:	8b 00                	mov    (%eax),%eax
80108d79:	25 00 02 00 00       	and    $0x200,%eax
80108d7e:	85 c0                	test   %eax,%eax
80108d80:	75 43                	jne    80108dc5 <deallocuvm+0x1ca>
        pa = PTE_ADDR(*pte);
80108d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d85:	8b 00                	mov    (%eax),%eax
80108d87:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d8c:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d8f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d93:	75 0c                	jne    80108da1 <deallocuvm+0x1a6>
          panic("kfree");
80108d95:	c7 04 24 ee a2 10 80 	movl   $0x8010a2ee,(%esp)
80108d9c:	e8 99 77 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108da1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108da4:	89 04 24             	mov    %eax,(%esp)
80108da7:	e8 79 f2 ff ff       	call   80108025 <p2v>
80108dac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108db2:	89 04 24             	mov    %eax,(%esp)
80108db5:	e8 b4 a3 ff ff       	call   8010316e <kfree>
        *pte = 0;
80108dba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dbd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108dc3:	eb 22                	jmp    80108de7 <deallocuvm+0x1ec>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108dc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dc8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108dce:	eb 17                	jmp    80108de7 <deallocuvm+0x1ec>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108dd0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dd3:	8b 00                	mov    (%eax),%eax
80108dd5:	25 00 02 00 00       	and    $0x200,%eax
80108dda:	85 c0                	test   %eax,%eax
80108ddc:	74 09                	je     80108de7 <deallocuvm+0x1ec>
        *pte = 0;
80108dde:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108de1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108de7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108dee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108df1:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108df4:	0f 82 2c fe ff ff    	jb     80108c26 <deallocuvm+0x2b>
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
    }
  }
  return newsz;
80108dfa:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108dfd:	c9                   	leave  
80108dfe:	c3                   	ret    

80108dff <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108dff:	55                   	push   %ebp
80108e00:	89 e5                	mov    %esp,%ebp
80108e02:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108e05:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108e09:	75 0c                	jne    80108e17 <freevm+0x18>
    panic("freevm: no pgdir");
80108e0b:	c7 04 24 f4 a2 10 80 	movl   $0x8010a2f4,(%esp)
80108e12:	e8 23 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108e17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108e1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e21:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e28:	00 
80108e29:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108e30:	80 
80108e31:	8b 45 08             	mov    0x8(%ebp),%eax
80108e34:	89 04 24             	mov    %eax,(%esp)
80108e37:	e8 bf fd ff ff       	call   80108bfb <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e43:	eb 48                	jmp    80108e8d <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e48:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80108e52:	01 d0                	add    %edx,%eax
80108e54:	8b 00                	mov    (%eax),%eax
80108e56:	83 e0 01             	and    $0x1,%eax
80108e59:	85 c0                	test   %eax,%eax
80108e5b:	74 2c                	je     80108e89 <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e60:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e67:	8b 45 08             	mov    0x8(%ebp),%eax
80108e6a:	01 d0                	add    %edx,%eax
80108e6c:	8b 00                	mov    (%eax),%eax
80108e6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e73:	89 04 24             	mov    %eax,(%esp)
80108e76:	e8 aa f1 ff ff       	call   80108025 <p2v>
80108e7b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e81:	89 04 24             	mov    %eax,(%esp)
80108e84:	e8 e5 a2 ff ff       	call   8010316e <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e89:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e8d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e94:	76 af                	jbe    80108e45 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e96:	8b 45 08             	mov    0x8(%ebp),%eax
80108e99:	89 04 24             	mov    %eax,(%esp)
80108e9c:	e8 cd a2 ff ff       	call   8010316e <kfree>

}
80108ea1:	c9                   	leave  
80108ea2:	c3                   	ret    

80108ea3 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108ea3:	55                   	push   %ebp
80108ea4:	89 e5                	mov    %esp,%ebp
80108ea6:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108ea9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108eb0:	00 
80108eb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80108eb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80108eb8:	8b 45 08             	mov    0x8(%ebp),%eax
80108ebb:	89 04 24             	mov    %eax,(%esp)
80108ebe:	e8 e5 f5 ff ff       	call   801084a8 <walkpgdir>
80108ec3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108ec6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108eca:	75 0c                	jne    80108ed8 <clearpteu+0x35>
    panic("clearpteu");
80108ecc:	c7 04 24 05 a3 10 80 	movl   $0x8010a305,(%esp)
80108ed3:	e8 62 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108ed8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108edb:	8b 00                	mov    (%eax),%eax
80108edd:	83 e0 fb             	and    $0xfffffffb,%eax
80108ee0:	89 c2                	mov    %eax,%edx
80108ee2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ee5:	89 10                	mov    %edx,(%eax)
}
80108ee7:	c9                   	leave  
80108ee8:	c3                   	ret    

80108ee9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108ee9:	55                   	push   %ebp
80108eea:	89 e5                	mov    %esp,%ebp
80108eec:	53                   	push   %ebx
80108eed:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108ef0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108ef7:	8b 45 10             	mov    0x10(%ebp),%eax
80108efa:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108f01:	00 00 00 
  np->swapedPagesCounter = 0;
80108f04:	8b 45 10             	mov    0x10(%ebp),%eax
80108f07:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108f0e:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108f11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108f17:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108f1d:	8b 45 10             	mov    0x10(%ebp),%eax
80108f20:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108f26:	e8 b7 f6 ff ff       	call   801085e2 <setupkvm>
80108f2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f2e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f32:	75 0a                	jne    80108f3e <copyuvm+0x55>
    return 0;
80108f34:	b8 00 00 00 00       	mov    $0x0,%eax
80108f39:	e9 da 02 00 00       	jmp    80109218 <copyuvm+0x32f>
  for(i = 0; i < sz; i += PGSIZE){
80108f3e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f45:	e9 04 02 00 00       	jmp    8010914e <copyuvm+0x265>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f4d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f54:	00 
80108f55:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f59:	8b 45 08             	mov    0x8(%ebp),%eax
80108f5c:	89 04 24             	mov    %eax,(%esp)
80108f5f:	e8 44 f5 ff ff       	call   801084a8 <walkpgdir>
80108f64:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f67:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f6b:	75 0c                	jne    80108f79 <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f6d:	c7 04 24 0f a3 10 80 	movl   $0x8010a30f,(%esp)
80108f74:	e8 c1 75 ff ff       	call   8010053a <panic>
    if(*pte & PTE_P){// page on RAM, copy it to the new process ram
80108f79:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f7c:	8b 00                	mov    (%eax),%eax
80108f7e:	83 e0 01             	and    $0x1,%eax
80108f81:	85 c0                	test   %eax,%eax
80108f83:	0f 84 a7 00 00 00    	je     80109030 <copyuvm+0x147>
      // panic("copyuvm: page not present");
      pa = PTE_ADDR(*pte);
80108f89:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f8c:	8b 00                	mov    (%eax),%eax
80108f8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      flags = PTE_FLAGS(*pte);
80108f96:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f99:	8b 00                	mov    (%eax),%eax
80108f9b:	25 ff 0f 00 00       	and    $0xfff,%eax
80108fa0:	89 45 e0             	mov    %eax,-0x20(%ebp)
      if((mem = kalloc()) == 0)
80108fa3:	e8 88 a2 ff ff       	call   80103230 <kalloc>
80108fa8:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108fab:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108faf:	75 05                	jne    80108fb6 <copyuvm+0xcd>
        goto bad;
80108fb1:	e9 4a 02 00 00       	jmp    80109200 <copyuvm+0x317>
      memmove(mem, (char*)p2v(pa), PGSIZE);
80108fb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108fb9:	89 04 24             	mov    %eax,(%esp)
80108fbc:	e8 64 f0 ff ff       	call   80108025 <p2v>
80108fc1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fc8:	00 
80108fc9:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fd0:	89 04 24             	mov    %eax,(%esp)
80108fd3:	e8 2b cb ff ff       	call   80105b03 <memmove>
      if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108fd8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108fdb:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fde:	89 04 24             	mov    %eax,(%esp)
80108fe1:	e8 32 f0 ff ff       	call   80108018 <v2p>
80108fe6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108fe9:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108fed:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108ff1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ff8:	00 
80108ff9:	89 54 24 04          	mov    %edx,0x4(%esp)
80108ffd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109000:	89 04 24             	mov    %eax,(%esp)
80109003:	e8 42 f5 ff ff       	call   8010854a <mappages>
80109008:	85 c0                	test   %eax,%eax
8010900a:	79 05                	jns    80109011 <copyuvm+0x128>
        goto bad;
8010900c:	e9 ef 01 00 00       	jmp    80109200 <copyuvm+0x317>
      np->pagesMetaData[j].isPhysical = 1;
80109011:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109014:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109017:	89 d0                	mov    %edx,%eax
80109019:	c1 e0 02             	shl    $0x2,%eax
8010901c:	01 d0                	add    %edx,%eax
8010901e:	c1 e0 02             	shl    $0x2,%eax
80109021:	01 c8                	add    %ecx,%eax
80109023:	05 94 00 00 00       	add    $0x94,%eax
80109028:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
8010902e:	eb 58                	jmp    80109088 <copyuvm+0x19f>
    }
    else{//page is in swap file, need to create pte for it
      pte = walkpgdir(d,(void*)i,1);
80109030:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109033:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010903a:	00 
8010903b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010903f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109042:	89 04 24             	mov    %eax,(%esp)
80109045:	e8 5e f4 ff ff       	call   801084a8 <walkpgdir>
8010904a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      *pte &= ~PTE_P;
8010904d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109050:	8b 00                	mov    (%eax),%eax
80109052:	83 e0 fe             	and    $0xfffffffe,%eax
80109055:	89 c2                	mov    %eax,%edx
80109057:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010905a:	89 10                	mov    %edx,(%eax)
      *pte |= PTE_PG;
8010905c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010905f:	8b 00                	mov    (%eax),%eax
80109061:	80 cc 02             	or     $0x2,%ah
80109064:	89 c2                	mov    %eax,%edx
80109066:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109069:	89 10                	mov    %edx,(%eax)
      np->pagesMetaData[j].isPhysical = 0;
8010906b:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010906e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109071:	89 d0                	mov    %edx,%eax
80109073:	c1 e0 02             	shl    $0x2,%eax
80109076:	01 d0                	add    %edx,%eax
80109078:	c1 e0 02             	shl    $0x2,%eax
8010907b:	01 c8                	add    %ecx,%eax
8010907d:	05 94 00 00 00       	add    $0x94,%eax
80109082:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    }
    np->pagesMetaData[j].va = (char *) i;
80109088:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010908b:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010908e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109091:	89 d0                	mov    %edx,%eax
80109093:	c1 e0 02             	shl    $0x2,%eax
80109096:	01 d0                	add    %edx,%eax
80109098:	c1 e0 02             	shl    $0x2,%eax
8010909b:	01 d8                	add    %ebx,%eax
8010909d:	05 90 00 00 00       	add    $0x90,%eax
801090a2:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
801090a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090a7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090aa:	89 d0                	mov    %edx,%eax
801090ac:	c1 e0 02             	shl    $0x2,%eax
801090af:	01 d0                	add    %edx,%eax
801090b1:	c1 e0 02             	shl    $0x2,%eax
801090b4:	01 c8                	add    %ecx,%eax
801090b6:	05 98 00 00 00       	add    $0x98,%eax
801090bb:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
801090c1:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801090c8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090cb:	89 d0                	mov    %edx,%eax
801090cd:	c1 e0 02             	shl    $0x2,%eax
801090d0:	01 d0                	add    %edx,%eax
801090d2:	c1 e0 02             	shl    $0x2,%eax
801090d5:	01 c8                	add    %ecx,%eax
801090d7:	05 9c 00 00 00       	add    $0x9c,%eax
801090dc:	8b 08                	mov    (%eax),%ecx
801090de:	8b 5d 10             	mov    0x10(%ebp),%ebx
801090e1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090e4:	89 d0                	mov    %edx,%eax
801090e6:	c1 e0 02             	shl    $0x2,%eax
801090e9:	01 d0                	add    %edx,%eax
801090eb:	c1 e0 02             	shl    $0x2,%eax
801090ee:	01 d8                	add    %ebx,%eax
801090f0:	05 9c 00 00 00       	add    $0x9c,%eax
801090f5:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
801090f7:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801090fe:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109101:	89 d0                	mov    %edx,%eax
80109103:	c1 e0 02             	shl    $0x2,%eax
80109106:	01 d0                	add    %edx,%eax
80109108:	c1 e0 02             	shl    $0x2,%eax
8010910b:	01 c8                	add    %ecx,%eax
8010910d:	05 a0 00 00 00       	add    $0xa0,%eax
80109112:	0f b6 08             	movzbl (%eax),%ecx
80109115:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109118:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010911b:	89 d0                	mov    %edx,%eax
8010911d:	c1 e0 02             	shl    $0x2,%eax
80109120:	01 d0                	add    %edx,%eax
80109122:	c1 e0 02             	shl    $0x2,%eax
80109125:	01 d8                	add    %ebx,%eax
80109127:	05 a0 00 00 00       	add    $0xa0,%eax
8010912c:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
8010912e:	8b 45 10             	mov    0x10(%ebp),%eax
80109131:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80109137:	8d 50 01             	lea    0x1(%eax),%edx
8010913a:	8b 45 10             	mov    0x10(%ebp),%eax
8010913d:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
80109143:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109147:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010914e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109151:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109154:	0f 82 f0 fd ff ff    	jb     80108f4a <copyuvm+0x61>
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
8010915a:	e9 92 00 00 00       	jmp    801091f1 <copyuvm+0x308>
    np->pagesMetaData[j].va = (char *) -1;
8010915f:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109162:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109165:	89 d0                	mov    %edx,%eax
80109167:	c1 e0 02             	shl    $0x2,%eax
8010916a:	01 d0                	add    %edx,%eax
8010916c:	c1 e0 02             	shl    $0x2,%eax
8010916f:	01 c8                	add    %ecx,%eax
80109171:	05 90 00 00 00       	add    $0x90,%eax
80109176:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
8010917c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010917f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109182:	89 d0                	mov    %edx,%eax
80109184:	c1 e0 02             	shl    $0x2,%eax
80109187:	01 d0                	add    %edx,%eax
80109189:	c1 e0 02             	shl    $0x2,%eax
8010918c:	01 c8                	add    %ecx,%eax
8010918e:	05 94 00 00 00       	add    $0x94,%eax
80109193:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109199:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010919c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010919f:	89 d0                	mov    %edx,%eax
801091a1:	c1 e0 02             	shl    $0x2,%eax
801091a4:	01 d0                	add    %edx,%eax
801091a6:	c1 e0 02             	shl    $0x2,%eax
801091a9:	01 c8                	add    %ecx,%eax
801091ab:	05 98 00 00 00       	add    $0x98,%eax
801091b0:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
801091b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
801091b9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091bc:	89 d0                	mov    %edx,%eax
801091be:	c1 e0 02             	shl    $0x2,%eax
801091c1:	01 d0                	add    %edx,%eax
801091c3:	c1 e0 02             	shl    $0x2,%eax
801091c6:	01 c8                	add    %ecx,%eax
801091c8:	05 9c 00 00 00       	add    $0x9c,%eax
801091cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
801091d3:	8b 4d 10             	mov    0x10(%ebp),%ecx
801091d6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091d9:	89 d0                	mov    %edx,%eax
801091db:	c1 e0 02             	shl    $0x2,%eax
801091de:	01 d0                	add    %edx,%eax
801091e0:	c1 e0 02             	shl    $0x2,%eax
801091e3:	01 c8                	add    %ecx,%eax
801091e5:	05 a0 00 00 00       	add    $0xa0,%eax
801091ea:	c6 00 80             	movb   $0x80,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
801091ed:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801091f1:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801091f5:	0f 86 64 ff ff ff    	jbe    8010915f <copyuvm+0x276>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
801091fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091fe:	eb 18                	jmp    80109218 <copyuvm+0x32f>

  bad:
  freevm(d,0);
80109200:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109207:	00 
80109208:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010920b:	89 04 24             	mov    %eax,(%esp)
8010920e:	e8 ec fb ff ff       	call   80108dff <freevm>
  return 0;
80109213:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109218:	83 c4 44             	add    $0x44,%esp
8010921b:	5b                   	pop    %ebx
8010921c:	5d                   	pop    %ebp
8010921d:	c3                   	ret    

8010921e <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010921e:	55                   	push   %ebp
8010921f:	89 e5                	mov    %esp,%ebp
80109221:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109224:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010922b:	00 
8010922c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010922f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109233:	8b 45 08             	mov    0x8(%ebp),%eax
80109236:	89 04 24             	mov    %eax,(%esp)
80109239:	e8 6a f2 ff ff       	call   801084a8 <walkpgdir>
8010923e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109241:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109244:	8b 00                	mov    (%eax),%eax
80109246:	83 e0 01             	and    $0x1,%eax
80109249:	85 c0                	test   %eax,%eax
8010924b:	75 07                	jne    80109254 <uva2ka+0x36>
    return 0;
8010924d:	b8 00 00 00 00       	mov    $0x0,%eax
80109252:	eb 25                	jmp    80109279 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109254:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109257:	8b 00                	mov    (%eax),%eax
80109259:	83 e0 04             	and    $0x4,%eax
8010925c:	85 c0                	test   %eax,%eax
8010925e:	75 07                	jne    80109267 <uva2ka+0x49>
    return 0;
80109260:	b8 00 00 00 00       	mov    $0x0,%eax
80109265:	eb 12                	jmp    80109279 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010926a:	8b 00                	mov    (%eax),%eax
8010926c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109271:	89 04 24             	mov    %eax,(%esp)
80109274:	e8 ac ed ff ff       	call   80108025 <p2v>
}
80109279:	c9                   	leave  
8010927a:	c3                   	ret    

8010927b <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010927b:	55                   	push   %ebp
8010927c:	89 e5                	mov    %esp,%ebp
8010927e:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109281:	8b 45 10             	mov    0x10(%ebp),%eax
80109284:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109287:	e9 87 00 00 00       	jmp    80109313 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010928c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010928f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109294:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109297:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010929a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010929e:	8b 45 08             	mov    0x8(%ebp),%eax
801092a1:	89 04 24             	mov    %eax,(%esp)
801092a4:	e8 75 ff ff ff       	call   8010921e <uva2ka>
801092a9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801092ac:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801092b0:	75 07                	jne    801092b9 <copyout+0x3e>
      return -1;
801092b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801092b7:	eb 69                	jmp    80109322 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801092b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801092bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801092bf:	29 c2                	sub    %eax,%edx
801092c1:	89 d0                	mov    %edx,%eax
801092c3:	05 00 10 00 00       	add    $0x1000,%eax
801092c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801092cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092ce:	3b 45 14             	cmp    0x14(%ebp),%eax
801092d1:	76 06                	jbe    801092d9 <copyout+0x5e>
      n = len;
801092d3:	8b 45 14             	mov    0x14(%ebp),%eax
801092d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801092d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092dc:	8b 55 0c             	mov    0xc(%ebp),%edx
801092df:	29 c2                	sub    %eax,%edx
801092e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092e4:	01 c2                	add    %eax,%edx
801092e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801092ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801092f4:	89 14 24             	mov    %edx,(%esp)
801092f7:	e8 07 c8 ff ff       	call   80105b03 <memmove>
    len -= n;
801092fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092ff:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109302:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109305:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109308:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010930b:	05 00 10 00 00       	add    $0x1000,%eax
80109310:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109313:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109317:	0f 85 6f ff ff ff    	jne    8010928c <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010931d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109322:	c9                   	leave  
80109323:	c3                   	ret    

80109324 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
80109324:	55                   	push   %ebp
80109325:	89 e5                	mov    %esp,%ebp
80109327:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
8010932a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80109331:	eb 52                	jmp    80109385 <findNextOpenPage+0x61>
    found = 1;
80109333:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
8010933a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80109341:	eb 2d                	jmp    80109370 <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
80109343:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010934a:	8b 55 f8             	mov    -0x8(%ebp),%edx
8010934d:	89 d0                	mov    %edx,%eax
8010934f:	c1 e0 02             	shl    $0x2,%eax
80109352:	01 d0                	add    %edx,%eax
80109354:	c1 e0 02             	shl    $0x2,%eax
80109357:	01 c8                	add    %ecx,%eax
80109359:	05 98 00 00 00       	add    $0x98,%eax
8010935e:	8b 00                	mov    (%eax),%eax
80109360:	3b 45 fc             	cmp    -0x4(%ebp),%eax
80109363:	75 07                	jne    8010936c <findNextOpenPage+0x48>
        found = 0;
80109365:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
8010936c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80109370:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
80109374:	7e cd                	jle    80109343 <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
80109376:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010937a:	74 02                	je     8010937e <findNextOpenPage+0x5a>
      break;
8010937c:	eb 10                	jmp    8010938e <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
8010937e:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
80109385:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
8010938c:	7e a5                	jle    80109333 <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
8010938e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80109391:	c9                   	leave  
80109392:	c3                   	ret    

80109393 <existOnDisc>:

int
existOnDisc(uint faultingPage){
80109393:	55                   	push   %ebp
80109394:	89 e5                	mov    %esp,%ebp
80109396:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
80109399:	8b 55 08             	mov    0x8(%ebp),%edx
8010939c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801093a2:	8b 40 04             	mov    0x4(%eax),%eax
801093a5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801093ac:	00 
801093ad:	89 54 24 04          	mov    %edx,0x4(%esp)
801093b1:	89 04 24             	mov    %eax,(%esp)
801093b4:	e8 ef f0 ff ff       	call   801084a8 <walkpgdir>
801093b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
801093bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  cprintf("faulting page: %x\n",faultingPage);
801093c3:	8b 45 08             	mov    0x8(%ebp),%eax
801093c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801093ca:	c7 04 24 29 a3 10 80 	movl   $0x8010a329,(%esp)
801093d1:	e8 ca 6f ff ff       	call   801003a0 <cprintf>
  for(i = 0; i < 30; i++){
801093d6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801093dd:	e9 8e 00 00 00       	jmp    80109470 <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
801093e2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093e9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093ec:	89 d0                	mov    %edx,%eax
801093ee:	c1 e0 02             	shl    $0x2,%eax
801093f1:	01 d0                	add    %edx,%eax
801093f3:	c1 e0 02             	shl    $0x2,%eax
801093f6:	01 c8                	add    %ecx,%eax
801093f8:	05 90 00 00 00       	add    $0x90,%eax
801093fd:	8b 00                	mov    (%eax),%eax
801093ff:	83 f8 ff             	cmp    $0xffffffff,%eax
80109402:	74 68                	je     8010946c <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
80109404:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010940b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010940e:	89 d0                	mov    %edx,%eax
80109410:	c1 e0 02             	shl    $0x2,%eax
80109413:	01 d0                	add    %edx,%eax
80109415:	c1 e0 02             	shl    $0x2,%eax
80109418:	01 c8                	add    %ecx,%eax
8010941a:	05 90 00 00 00       	add    $0x90,%eax
8010941f:	8b 00                	mov    (%eax),%eax
80109421:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109426:	3b 45 08             	cmp    0x8(%ebp),%eax
80109429:	77 41                	ja     8010946c <existOnDisc+0xd9>
8010942b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109432:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109435:	89 d0                	mov    %edx,%eax
80109437:	c1 e0 02             	shl    $0x2,%eax
8010943a:	01 d0                	add    %edx,%eax
8010943c:	c1 e0 02             	shl    $0x2,%eax
8010943f:	01 c8                	add    %ecx,%eax
80109441:	05 90 00 00 00       	add    $0x90,%eax
80109446:	8b 00                	mov    (%eax),%eax
80109448:	05 ff 0f 00 00       	add    $0xfff,%eax
8010944d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109452:	3b 45 08             	cmp    0x8(%ebp),%eax
80109455:	72 15                	jb     8010946c <existOnDisc+0xd9>
80109457:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010945a:	8b 00                	mov    (%eax),%eax
8010945c:	25 00 02 00 00       	and    $0x200,%eax
80109461:	85 c0                	test   %eax,%eax
80109463:	74 07                	je     8010946c <existOnDisc+0xd9>
        found = 1;
80109465:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  cprintf("faulting page: %x\n",faultingPage);
  for(i = 0; i < 30; i++){
8010946c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109470:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109474:	0f 8e 68 ff ff ff    	jle    801093e2 <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
8010947a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010947d:	c9                   	leave  
8010947e:	c3                   	ret    

8010947f <fixPage>:

void
fixPage(uint faultingPage){
8010947f:	55                   	push   %ebp
80109480:	89 e5                	mov    %esp,%ebp
80109482:	83 ec 38             	sub    $0x38,%esp
  int i;
  //char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
80109485:	e8 a6 9d ff ff       	call   80103230 <kalloc>
8010948a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
8010948d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109491:	75 0c                	jne    8010949f <fixPage+0x20>
    panic("no room, go away");
80109493:	c7 04 24 3c a3 10 80 	movl   $0x8010a33c,(%esp)
8010949a:	e8 9b 70 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
8010949f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801094a6:	00 
801094a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801094ae:	00 
801094af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094b2:	89 04 24             	mov    %eax,(%esp)
801094b5:	e8 7a c5 ff ff       	call   80105a34 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
801094ba:	8b 55 08             	mov    0x8(%ebp),%edx
801094bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801094c3:	8b 40 04             	mov    0x4(%eax),%eax
801094c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094cd:	00 
801094ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801094d2:	89 04 24             	mov    %eax,(%esp)
801094d5:	e8 ce ef ff ff       	call   801084a8 <walkpgdir>
801094da:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
801094dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094e4:	e9 a6 01 00 00       	jmp    8010968f <fixPage+0x210>
    if(proc->pagesMetaData[i].va != (char *) -1){
801094e9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094f3:	89 d0                	mov    %edx,%eax
801094f5:	c1 e0 02             	shl    $0x2,%eax
801094f8:	01 d0                	add    %edx,%eax
801094fa:	c1 e0 02             	shl    $0x2,%eax
801094fd:	01 c8                	add    %ecx,%eax
801094ff:	05 90 00 00 00       	add    $0x90,%eax
80109504:	8b 00                	mov    (%eax),%eax
80109506:	83 f8 ff             	cmp    $0xffffffff,%eax
80109509:	0f 84 7c 01 00 00    	je     8010968b <fixPage+0x20c>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
8010950f:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109516:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109519:	89 d0                	mov    %edx,%eax
8010951b:	c1 e0 02             	shl    $0x2,%eax
8010951e:	01 d0                	add    %edx,%eax
80109520:	c1 e0 02             	shl    $0x2,%eax
80109523:	01 c8                	add    %ecx,%eax
80109525:	05 90 00 00 00       	add    $0x90,%eax
8010952a:	8b 00                	mov    (%eax),%eax
8010952c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109531:	3b 45 08             	cmp    0x8(%ebp),%eax
80109534:	0f 87 51 01 00 00    	ja     8010968b <fixPage+0x20c>
8010953a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109541:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109544:	89 d0                	mov    %edx,%eax
80109546:	c1 e0 02             	shl    $0x2,%eax
80109549:	01 d0                	add    %edx,%eax
8010954b:	c1 e0 02             	shl    $0x2,%eax
8010954e:	01 c8                	add    %ecx,%eax
80109550:	05 90 00 00 00       	add    $0x90,%eax
80109555:	8b 00                	mov    (%eax),%eax
80109557:	05 ff 0f 00 00       	add    $0xfff,%eax
8010955c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109561:	3b 45 08             	cmp    0x8(%ebp),%eax
80109564:	0f 82 21 01 00 00    	jb     8010968b <fixPage+0x20c>
8010956a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010956d:	8b 00                	mov    (%eax),%eax
8010956f:	25 00 02 00 00       	and    $0x200,%eax
80109574:	85 c0                	test   %eax,%eax
80109576:	0f 84 0f 01 00 00    	je     8010968b <fixPage+0x20c>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
8010957c:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109583:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109586:	89 d0                	mov    %edx,%eax
80109588:	c1 e0 02             	shl    $0x2,%eax
8010958b:	01 d0                	add    %edx,%eax
8010958d:	c1 e0 02             	shl    $0x2,%eax
80109590:	01 c8                	add    %ecx,%eax
80109592:	05 98 00 00 00       	add    $0x98,%eax
80109597:	8b 00                	mov    (%eax),%eax
80109599:	89 44 24 04          	mov    %eax,0x4(%esp)
8010959d:	c7 04 24 4d a3 10 80 	movl   $0x8010a34d,(%esp)
801095a4:	e8 f7 6d ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,mem,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
801095a9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095b3:	89 d0                	mov    %edx,%eax
801095b5:	c1 e0 02             	shl    $0x2,%eax
801095b8:	01 d0                	add    %edx,%eax
801095ba:	c1 e0 02             	shl    $0x2,%eax
801095bd:	01 c8                	add    %ecx,%eax
801095bf:	05 98 00 00 00       	add    $0x98,%eax
801095c4:	8b 00                	mov    (%eax),%eax
801095c6:	89 c2                	mov    %eax,%edx
801095c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801095ce:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801095d5:	00 
801095d6:	89 54 24 08          	mov    %edx,0x8(%esp)
801095da:	8b 55 f0             	mov    -0x10(%ebp),%edx
801095dd:	89 54 24 04          	mov    %edx,0x4(%esp)
801095e1:	89 04 24             	mov    %eax,(%esp)
801095e4:	e8 f8 93 ff ff       	call   801029e1 <readFromSwapFile>
801095e9:	83 f8 ff             	cmp    $0xffffffff,%eax
801095ec:	75 0c                	jne    801095fa <fixPage+0x17b>
          panic("nothing read");
801095ee:	c7 04 24 57 a3 10 80 	movl   $0x8010a357,(%esp)
801095f5:	e8 40 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1){  //need to swap out
801095fa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109600:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80109606:	83 f8 0e             	cmp    $0xe,%eax
80109609:	76 1e                	jbe    80109629 <fixPage+0x1aa>
          swapOut();
8010960b:	e8 d2 00 00 00       	call   801096e2 <swapOut>
          lcr3(v2p(proc->pgdir));
80109610:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109616:	8b 40 04             	mov    0x4(%eax),%eax
80109619:	89 04 24             	mov    %eax,(%esp)
8010961c:	e8 f7 e9 ff ff       	call   80108018 <v2p>
80109621:	89 04 24             	mov    %eax,(%esp)
80109624:	e8 e4 e9 ff ff       	call   8010800d <lcr3>
        }
        proc->pagesMetaData[i].isPhysical = 1;
80109629:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109630:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109633:	89 d0                	mov    %edx,%eax
80109635:	c1 e0 02             	shl    $0x2,%eax
80109638:	01 d0                	add    %edx,%eax
8010963a:	c1 e0 02             	shl    $0x2,%eax
8010963d:	01 c8                	add    %ecx,%eax
8010963f:	05 94 00 00 00       	add    $0x94,%eax
80109644:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  
8010964a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109651:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109654:	89 d0                	mov    %edx,%eax
80109656:	c1 e0 02             	shl    $0x2,%eax
80109659:	01 d0                	add    %edx,%eax
8010965b:	c1 e0 02             	shl    $0x2,%eax
8010965e:	01 c8                	add    %ecx,%eax
80109660:	05 a0 00 00 00       	add    $0xa0,%eax
80109665:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
80109668:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010966f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109672:	89 d0                	mov    %edx,%eax
80109674:	c1 e0 02             	shl    $0x2,%eax
80109677:	01 d0                	add    %edx,%eax
80109679:	c1 e0 02             	shl    $0x2,%eax
8010967c:	01 c8                	add    %ecx,%eax
8010967e:	05 98 00 00 00       	add    $0x98,%eax
80109683:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
80109689:	eb 0e                	jmp    80109699 <fixPage+0x21a>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010968b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010968f:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109693:	0f 8e 50 fe ff ff    	jle    801094e9 <fixPage+0x6a>
        break;
      }
    }
  }    
    //memmove(mem,buf,PGSIZE);
    *pte &= ~PTE_PG;  //turn off flag
80109699:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010969c:	8b 00                	mov    (%eax),%eax
8010969e:	80 e4 fd             	and    $0xfd,%ah
801096a1:	89 c2                	mov    %eax,%edx
801096a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801096a6:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
801096a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096ab:	89 04 24             	mov    %eax,(%esp)
801096ae:	e8 65 e9 ff ff       	call   80108018 <v2p>
801096b3:	8b 4d 08             	mov    0x8(%ebp),%ecx
801096b6:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801096bd:	8b 52 04             	mov    0x4(%edx),%edx
801096c0:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801096c7:	00 
801096c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
801096cc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801096d3:	00 
801096d4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801096d8:	89 14 24             	mov    %edx,(%esp)
801096db:	e8 6a ee ff ff       	call   8010854a <mappages>
    //memmove(buf,0,PGSIZE);
  }
801096e0:	c9                   	leave  
801096e1:	c3                   	ret    

801096e2 <swapOut>:

//swap out a page from proc.
  void swapOut(){
801096e2:	55                   	push   %ebp
801096e3:	89 e5                	mov    %esp,%ebp
801096e5:	53                   	push   %ebx
801096e6:	83 ec 34             	sub    $0x34,%esp
    int offset;
    //char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    uint flags;
    int index = -1;
801096e9:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
801096f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096f6:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801096fc:	83 c0 03             	add    $0x3,%eax
801096ff:	89 45 e8             	mov    %eax,-0x18(%ebp)
    char minNFU = 0x80;
80109702:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        }
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
80109706:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
8010970a:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
80109711:	eb 6f                	jmp    80109782 <swapOut+0xa0>
          //cprintf("NFU: %d j=%d\n", minNFU, j);
          //cprintf("checking entry %d minNFU=%d curr=%d %d\n",j, minNFU, proc->pagesMetaData[j].lru, (proc->pagesMetaData[j].lru >= minNFU));
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru >= minNFU){
80109713:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010971a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010971d:	89 d0                	mov    %edx,%eax
8010971f:	c1 e0 02             	shl    $0x2,%eax
80109722:	01 d0                	add    %edx,%eax
80109724:	c1 e0 02             	shl    $0x2,%eax
80109727:	01 c8                	add    %ecx,%eax
80109729:	05 94 00 00 00       	add    $0x94,%eax
8010972e:	8b 00                	mov    (%eax),%eax
80109730:	85 c0                	test   %eax,%eax
80109732:	74 4a                	je     8010977e <swapOut+0x9c>
80109734:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010973b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010973e:	89 d0                	mov    %edx,%eax
80109740:	c1 e0 02             	shl    $0x2,%eax
80109743:	01 d0                	add    %edx,%eax
80109745:	c1 e0 02             	shl    $0x2,%eax
80109748:	01 c8                	add    %ecx,%eax
8010974a:	05 a0 00 00 00       	add    $0xa0,%eax
8010974f:	0f b6 00             	movzbl (%eax),%eax
80109752:	3a 45 ef             	cmp    -0x11(%ebp),%al
80109755:	7c 27                	jl     8010977e <swapOut+0x9c>
            minNFU = proc->pagesMetaData[j].lru;
80109757:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010975e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109761:	89 d0                	mov    %edx,%eax
80109763:	c1 e0 02             	shl    $0x2,%eax
80109766:	01 d0                	add    %edx,%eax
80109768:	c1 e0 02             	shl    $0x2,%eax
8010976b:	01 c8                	add    %ecx,%eax
8010976d:	05 a0 00 00 00       	add    $0xa0,%eax
80109772:	0f b6 00             	movzbl (%eax),%eax
80109775:	88 45 ef             	mov    %al,-0x11(%ebp)
            index = j;
80109778:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010977b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
8010977e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109782:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109786:	7e 8b                	jle    80109713 <swapOut+0x31>
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru >= minNFU){
            minNFU = proc->pagesMetaData[j].lru;
            index = j;
          }
        }
        break;
80109788:	90                   	nop
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
80109789:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109790:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109793:	89 d0                	mov    %edx,%eax
80109795:	c1 e0 02             	shl    $0x2,%eax
80109798:	01 d0                	add    %edx,%eax
8010979a:	c1 e0 02             	shl    $0x2,%eax
8010979d:	01 c8                	add    %ecx,%eax
8010979f:	05 94 00 00 00       	add    $0x94,%eax
801097a4:	8b 00                	mov    (%eax),%eax
801097a6:	85 c0                	test   %eax,%eax
801097a8:	0f 84 b1 01 00 00    	je     8010995f <swapOut+0x27d>
      proc->swappedOutCounter++;
801097ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801097b4:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
801097ba:	83 c2 01             	add    $0x1,%edx
801097bd:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
801097c3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097ca:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097cd:	89 d0                	mov    %edx,%eax
801097cf:	c1 e0 02             	shl    $0x2,%eax
801097d2:	01 d0                	add    %edx,%eax
801097d4:	c1 e0 02             	shl    $0x2,%eax
801097d7:	01 c8                	add    %ecx,%eax
801097d9:	05 90 00 00 00       	add    $0x90,%eax
801097de:	8b 00                	mov    (%eax),%eax
801097e0:	89 04 24             	mov    %eax,(%esp)
801097e3:	e8 3c fb ff ff       	call   80109324 <findNextOpenPage>
801097e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      cprintf("swapping out %x to offset %d\n",proc->pagesMetaData[index].va,offset);
801097eb:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097f2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097f5:	89 d0                	mov    %edx,%eax
801097f7:	c1 e0 02             	shl    $0x2,%eax
801097fa:	01 d0                	add    %edx,%eax
801097fc:	c1 e0 02             	shl    $0x2,%eax
801097ff:	01 c8                	add    %ecx,%eax
80109801:	05 90 00 00 00       	add    $0x90,%eax
80109806:	8b 00                	mov    (%eax),%eax
80109808:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010980b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010980f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109813:	c7 04 24 64 a3 10 80 	movl   $0x8010a364,(%esp)
8010981a:	e8 81 6b ff ff       	call   801003a0 <cprintf>
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
8010981f:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109826:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109829:	89 d0                	mov    %edx,%eax
8010982b:	c1 e0 02             	shl    $0x2,%eax
8010982e:	01 d0                	add    %edx,%eax
80109830:	c1 e0 02             	shl    $0x2,%eax
80109833:	01 c8                	add    %ecx,%eax
80109835:	05 90 00 00 00       	add    $0x90,%eax
8010983a:	8b 10                	mov    (%eax),%edx
8010983c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109842:	8b 40 04             	mov    0x4(%eax),%eax
80109845:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010984c:	00 
8010984d:	89 54 24 04          	mov    %edx,0x4(%esp)
80109851:	89 04 24             	mov    %eax,(%esp)
80109854:	e8 4f ec ff ff       	call   801084a8 <walkpgdir>
80109859:	89 45 e0             	mov    %eax,-0x20(%ebp)
      proc->pagesMetaData[index].fileOffset = offset;
8010985c:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109863:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109866:	89 d0                	mov    %edx,%eax
80109868:	c1 e0 02             	shl    $0x2,%eax
8010986b:	01 d0                	add    %edx,%eax
8010986d:	c1 e0 02             	shl    $0x2,%eax
80109870:	01 c8                	add    %ecx,%eax
80109872:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
80109878:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010987b:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
8010987d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109884:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109887:	89 d0                	mov    %edx,%eax
80109889:	c1 e0 02             	shl    $0x2,%eax
8010988c:	01 d0                	add    %edx,%eax
8010988e:	c1 e0 02             	shl    $0x2,%eax
80109891:	01 c8                	add    %ecx,%eax
80109893:	05 94 00 00 00       	add    $0x94,%eax
80109898:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
8010989e:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
801098a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098ab:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
801098b1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098b4:	89 d0                	mov    %edx,%eax
801098b6:	c1 e0 02             	shl    $0x2,%eax
801098b9:	01 d0                	add    %edx,%eax
801098bb:	c1 e0 02             	shl    $0x2,%eax
801098be:	01 d8                	add    %ebx,%eax
801098c0:	05 9c 00 00 00       	add    $0x9c,%eax
801098c5:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
801098c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098cd:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
801098d3:	83 c2 01             	add    $0x1,%edx
801098d6:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      writeToSwapFile(proc,p2v(PTE_ADDR(*pte)),offset,PGSIZE);
801098dc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801098df:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098e2:	8b 00                	mov    (%eax),%eax
801098e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801098e9:	89 04 24             	mov    %eax,(%esp)
801098ec:	e8 34 e7 ff ff       	call   80108025 <p2v>
801098f1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801098f8:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801098ff:	00 
80109900:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109904:	89 44 24 04          	mov    %eax,0x4(%esp)
80109908:	89 14 24             	mov    %edx,(%esp)
8010990b:	e8 a1 90 ff ff       	call   801029b1 <writeToSwapFile>
      pa = PTE_ADDR(*pte);
80109910:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109913:	8b 00                	mov    (%eax),%eax
80109915:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010991a:	89 45 dc             	mov    %eax,-0x24(%ebp)
      flags = PTE_FLAGS(*pte);
8010991d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109920:	8b 00                	mov    (%eax),%eax
80109922:	25 ff 0f 00 00       	and    $0xfff,%eax
80109927:	89 45 d8             	mov    %eax,-0x28(%ebp)
      if(pa != 0){
8010992a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
8010992e:	74 13                	je     80109943 <swapOut+0x261>
        kfree(p2v(pa)); 
80109930:	8b 45 dc             	mov    -0x24(%ebp),%eax
80109933:	89 04 24             	mov    %eax,(%esp)
80109936:	e8 ea e6 ff ff       	call   80108025 <p2v>
8010993b:	89 04 24             	mov    %eax,(%esp)
8010993e:	e8 2b 98 ff ff       	call   8010316e <kfree>
      }
      *pte = 0 | flags | PTE_PG;
80109943:	8b 45 d8             	mov    -0x28(%ebp),%eax
80109946:	80 cc 02             	or     $0x2,%ah
80109949:	89 c2                	mov    %eax,%edx
8010994b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010994e:	89 10                	mov    %edx,(%eax)
      *pte &= ~PTE_P;
80109950:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109953:	8b 00                	mov    (%eax),%eax
80109955:	83 e0 fe             	and    $0xfffffffe,%eax
80109958:	89 c2                	mov    %eax,%edx
8010995a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010995d:	89 10                	mov    %edx,(%eax)
    }
  }
8010995f:	83 c4 34             	add    $0x34,%esp
80109962:	5b                   	pop    %ebx
80109963:	5d                   	pop    %ebp
80109964:	c3                   	ret    

80109965 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109965:	55                   	push   %ebp
80109966:	89 e5                	mov    %esp,%ebp
80109968:	53                   	push   %ebx
80109969:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
8010996c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109973:	e9 cf 00 00 00       	jmp    80109a47 <updateAge+0xe2>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=(char *) -1){ //only if on RAM
80109978:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010997b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010997e:	89 d0                	mov    %edx,%eax
80109980:	c1 e0 02             	shl    $0x2,%eax
80109983:	01 d0                	add    %edx,%eax
80109985:	c1 e0 02             	shl    $0x2,%eax
80109988:	01 c8                	add    %ecx,%eax
8010998a:	05 94 00 00 00       	add    $0x94,%eax
8010998f:	8b 00                	mov    (%eax),%eax
80109991:	85 c0                	test   %eax,%eax
80109993:	0f 84 aa 00 00 00    	je     80109a43 <updateAge+0xde>
80109999:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010999c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010999f:	89 d0                	mov    %edx,%eax
801099a1:	c1 e0 02             	shl    $0x2,%eax
801099a4:	01 d0                	add    %edx,%eax
801099a6:	c1 e0 02             	shl    $0x2,%eax
801099a9:	01 c8                	add    %ecx,%eax
801099ab:	05 90 00 00 00       	add    $0x90,%eax
801099b0:	8b 00                	mov    (%eax),%eax
801099b2:	83 f8 ff             	cmp    $0xffffffff,%eax
801099b5:	0f 84 88 00 00 00    	je     80109a43 <updateAge+0xde>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
801099bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099c1:	89 d0                	mov    %edx,%eax
801099c3:	c1 e0 02             	shl    $0x2,%eax
801099c6:	01 d0                	add    %edx,%eax
801099c8:	c1 e0 02             	shl    $0x2,%eax
801099cb:	01 c8                	add    %ecx,%eax
801099cd:	05 a0 00 00 00       	add    $0xa0,%eax
801099d2:	0f b6 00             	movzbl (%eax),%eax
801099d5:	d0 f8                	sar    %al
801099d7:	89 c1                	mov    %eax,%ecx
801099d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
801099dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099df:	89 d0                	mov    %edx,%eax
801099e1:	c1 e0 02             	shl    $0x2,%eax
801099e4:	01 d0                	add    %edx,%eax
801099e6:	c1 e0 02             	shl    $0x2,%eax
801099e9:	01 d8                	add    %ebx,%eax
801099eb:	05 a0 00 00 00       	add    $0xa0,%eax
801099f0:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
801099f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099f8:	89 d0                	mov    %edx,%eax
801099fa:	c1 e0 02             	shl    $0x2,%eax
801099fd:	01 d0                	add    %edx,%eax
801099ff:	c1 e0 02             	shl    $0x2,%eax
80109a02:	01 c8                	add    %ecx,%eax
80109a04:	05 90 00 00 00       	add    $0x90,%eax
80109a09:	8b 10                	mov    (%eax),%edx
80109a0b:	8b 45 08             	mov    0x8(%ebp),%eax
80109a0e:	8b 40 04             	mov    0x4(%eax),%eax
80109a11:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109a18:	00 
80109a19:	89 54 24 04          	mov    %edx,0x4(%esp)
80109a1d:	89 04 24             	mov    %eax,(%esp)
80109a20:	e8 83 ea ff ff       	call   801084a8 <walkpgdir>
80109a25:	89 45 f0             	mov    %eax,-0x10(%ebp)
         if(*pte & PTE_A){
80109a28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a2b:	8b 00                	mov    (%eax),%eax
80109a2d:	83 e0 20             	and    $0x20,%eax
80109a30:	85 c0                	test   %eax,%eax
80109a32:	74 0f                	je     80109a43 <updateAge+0xde>
           *pte &= ~PTE_A; //turn off bit 
80109a34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a37:	8b 00                	mov    (%eax),%eax
80109a39:	83 e0 df             	and    $0xffffffdf,%eax
80109a3c:	89 c2                	mov    %eax,%edx
80109a3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a41:	89 10                	mov    %edx,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
80109a43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109a47:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109a4b:	0f 8e 27 ff ff ff    	jle    80109978 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
         if(*pte & PTE_A){
           *pte &= ~PTE_A; //turn off bit 
       }
    }
  }
80109a51:	83 c4 24             	add    $0x24,%esp
80109a54:	5b                   	pop    %ebx
80109a55:	5d                   	pop    %ebp
80109a56:	c3                   	ret    

80109a57 <isShell>:

int
isShell(){
80109a57:	55                   	push   %ebp
80109a58:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 's') && (proc->name[1] == 'h');
80109a5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a60:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109a64:	3c 73                	cmp    $0x73,%al
80109a66:	75 15                	jne    80109a7d <isShell+0x26>
80109a68:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a6e:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109a72:	3c 68                	cmp    $0x68,%al
80109a74:	75 07                	jne    80109a7d <isShell+0x26>
80109a76:	b8 01 00 00 00       	mov    $0x1,%eax
80109a7b:	eb 05                	jmp    80109a82 <isShell+0x2b>
80109a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109a82:	5d                   	pop    %ebp
80109a83:	c3                   	ret    

80109a84 <isInit>:

int
isInit(){
80109a84:	55                   	push   %ebp
80109a85:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 'i') && (proc->name[1] == 'n') && (proc->name[2] == 'i') && (proc->name[3] == 't');
80109a87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a8d:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109a91:	3c 69                	cmp    $0x69,%al
80109a93:	75 31                	jne    80109ac6 <isInit+0x42>
80109a95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109a9b:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109a9f:	3c 6e                	cmp    $0x6e,%al
80109aa1:	75 23                	jne    80109ac6 <isInit+0x42>
80109aa3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109aa9:	0f b6 40 6e          	movzbl 0x6e(%eax),%eax
80109aad:	3c 69                	cmp    $0x69,%al
80109aaf:	75 15                	jne    80109ac6 <isInit+0x42>
80109ab1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109ab7:	0f b6 40 6f          	movzbl 0x6f(%eax),%eax
80109abb:	3c 74                	cmp    $0x74,%al
80109abd:	75 07                	jne    80109ac6 <isInit+0x42>
80109abf:	b8 01 00 00 00       	mov    $0x1,%eax
80109ac4:	eb 05                	jmp    80109acb <isInit+0x47>
80109ac6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109acb:	5d                   	pop    %ebp
80109acc:	c3                   	ret    
