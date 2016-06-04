
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
8010002d:	b8 30 3f 10 80       	mov    $0x80103f30,%eax
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
8010003a:	c7 44 24 04 90 9b 10 	movl   $0x80109b90,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 32 58 00 00       	call   80105880 <initlock>

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
801000bd:	e8 df 57 00 00       	call   801058a1 <acquire>

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
80100104:	e8 fa 57 00 00       	call   80105903 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 10 54 00 00       	call   80105534 <sleep>
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
8010017c:	e8 82 57 00 00       	call   80105903 <release>
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
80100198:	c7 04 24 97 9b 10 80 	movl   $0x80109b97,(%esp)
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
801001d3:	e8 7d 2d 00 00       	call   80102f55 <iderw>
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
801001ef:	c7 04 24 a8 9b 10 80 	movl   $0x80109ba8,(%esp)
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
80100210:	e8 40 2d 00 00       	call   80102f55 <iderw>
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
80100229:	c7 04 24 af 9b 10 80 	movl   $0x80109baf,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 60 56 00 00       	call   801058a1 <acquire>

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
8010029d:	e8 6e 53 00 00       	call   80105610 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 55 56 00 00       	call   80105903 <release>
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
801003bb:	e8 e1 54 00 00       	call   801058a1 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 b6 9b 10 80 	movl   $0x80109bb6,(%esp)
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
801004b0:	c7 45 ec bf 9b 10 80 	movl   $0x80109bbf,-0x14(%ebp)
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
80100533:	e8 cb 53 00 00       	call   80105903 <release>
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
8010055f:	c7 04 24 c6 9b 10 80 	movl   $0x80109bc6,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 d5 9b 10 80 	movl   $0x80109bd5,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 be 53 00 00       	call   80105952 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 d7 9b 10 80 	movl   $0x80109bd7,(%esp)
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
80100699:	c7 04 24 db 9b 10 80 	movl   $0x80109bdb,(%esp)
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
801006cd:	e8 f2 54 00 00       	call   80105bc4 <memmove>
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
801006fc:	e8 f4 53 00 00       	call   80105af5 <memset>
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
80100791:	e8 bc 6d 00 00       	call   80107552 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 b0 6d 00 00       	call   80107552 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 a4 6d 00 00       	call   80107552 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 97 6d 00 00       	call   80107552 <uartputc>
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
801007dc:	e8 c0 50 00 00       	call   801058a1 <acquire>
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
80100917:	e8 f4 4c 00 00       	call   80105610 <wakeup>
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
80100938:	e8 c6 4f 00 00       	call   80105903 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 6e 4d 00 00       	call   801056b6 <procdump>
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
80100968:	e8 34 4f 00 00       	call   801058a1 <acquire>
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
80100988:	e8 76 4f 00 00       	call   80105903 <release>
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
801009b1:	e8 7e 4b 00 00       	call   80105534 <sleep>

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
80100a2d:	e8 d1 4e 00 00       	call   80105903 <release>
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
80100a61:	e8 3b 4e 00 00       	call   801058a1 <acquire>
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
80100a9b:	e8 63 4e 00 00       	call   80105903 <release>
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
80100ab6:	c7 44 24 04 ee 9b 10 	movl   $0x80109bee,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 b6 4d 00 00       	call   80105880 <initlock>

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
80100aef:	e8 d4 3a 00 00       	call   801045c8 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 09 26 00 00       	call   80103111 <ioapicenable>
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
80100b13:	e8 11 31 00 00       	call   80103c29 <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 a8 1a 00 00       	call   801025cb <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 7c 31 00 00       	call   80103cad <end_op>
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
80100b8e:	e8 10 7b 00 00       	call   801086a3 <setupkvm>
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
80100d35:	e8 37 7d 00 00       	call   80108a71 <allocuvm>
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
80100d73:	e8 0e 7c 00 00       	call   80108986 <loaduvm>
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
80100dac:	e8 fc 2e 00 00       	call   80103cad <end_op>
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
80100dec:	e8 80 7c 00 00       	call   80108a71 <allocuvm>
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
80100e11:	e8 4e 81 00 00       	call   80108f64 <clearpteu>
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
80100e47:	e8 13 4f 00 00       	call   80105d5f <strlen>
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
80100e70:	e8 ea 4e 00 00       	call   80105d5f <strlen>
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
80100ea0:	e8 97 84 00 00       	call   8010933c <copyout>
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
80100f47:	e8 f0 83 00 00       	call   8010933c <copyout>
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
80100f9f:	e8 71 4d 00 00       	call   80105d15 <safestrcpy>

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
80100fc7:	e8 79 8b 00 00       	call   80109b45 <isInit>
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
80101016:	e8 79 77 00 00       	call   80108794 <switchuvm>
  freevm(oldpgdir,0);
8010101b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101022:	00 
80101023:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101026:	89 04 24             	mov    %eax,(%esp)
80101029:	e8 92 7e 00 00       	call   80108ec0 <freevm>
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
80101049:	e8 72 7e 00 00       	call   80108ec0 <freevm>
  if(ip){
8010104e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101052:	74 10                	je     80101064 <exec+0x55a>
    iunlockput(ip);
80101054:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101057:	89 04 24             	mov    %eax,(%esp)
8010105a:	e8 45 0c 00 00       	call   80101ca4 <iunlockput>
    end_op();
8010105f:	e8 49 2c 00 00       	call   80103cad <end_op>
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
80101071:	c7 44 24 04 f6 9b 10 	movl   $0x80109bf6,0x4(%esp)
80101078:	80 
80101079:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101080:	e8 fb 47 00 00       	call   80105880 <initlock>
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
80101094:	e8 08 48 00 00       	call   801058a1 <acquire>
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
801010bd:	e8 41 48 00 00       	call   80105903 <release>
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
801010db:	e8 23 48 00 00       	call   80105903 <release>
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
801010f4:	e8 a8 47 00 00       	call   801058a1 <acquire>
  if(f->ref < 1)
801010f9:	8b 45 08             	mov    0x8(%ebp),%eax
801010fc:	8b 40 04             	mov    0x4(%eax),%eax
801010ff:	85 c0                	test   %eax,%eax
80101101:	7f 0c                	jg     8010110f <filedup+0x28>
    panic("filedup");
80101103:	c7 04 24 fd 9b 10 80 	movl   $0x80109bfd,(%esp)
8010110a:	e8 2b f4 ff ff       	call   8010053a <panic>
  f->ref++;
8010110f:	8b 45 08             	mov    0x8(%ebp),%eax
80101112:	8b 40 04             	mov    0x4(%eax),%eax
80101115:	8d 50 01             	lea    0x1(%eax),%edx
80101118:	8b 45 08             	mov    0x8(%ebp),%eax
8010111b:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010111e:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101125:	e8 d9 47 00 00       	call   80105903 <release>
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
8010113c:	e8 60 47 00 00       	call   801058a1 <acquire>
  if(f->ref < 1)
80101141:	8b 45 08             	mov    0x8(%ebp),%eax
80101144:	8b 40 04             	mov    0x4(%eax),%eax
80101147:	85 c0                	test   %eax,%eax
80101149:	7f 0c                	jg     80101157 <fileclose+0x28>
    panic("fileclose");
8010114b:	c7 04 24 05 9c 10 80 	movl   $0x80109c05,(%esp)
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
80101177:	e8 87 47 00 00       	call   80105903 <release>
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
801011c1:	e8 3d 47 00 00       	call   80105903 <release>
  
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
801011df:	e8 94 36 00 00       	call   80104878 <pipeclose>
801011e4:	eb 1d                	jmp    80101203 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801011e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801011e9:	83 f8 02             	cmp    $0x2,%eax
801011ec:	75 15                	jne    80101203 <fileclose+0xd4>
    begin_op();
801011ee:	e8 36 2a 00 00       	call   80103c29 <begin_op>
    iput(ff.ip);
801011f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801011f6:	89 04 24             	mov    %eax,(%esp)
801011f9:	e8 d5 09 00 00       	call   80101bd3 <iput>
    end_op();
801011fe:	e8 aa 2a 00 00       	call   80103cad <end_op>
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
80101290:	e8 64 37 00 00       	call   801049f9 <piperead>
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
80101302:	c7 04 24 0f 9c 10 80 	movl   $0x80109c0f,(%esp)
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
8010134d:	e8 b8 35 00 00       	call   8010490a <pipewrite>
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
80101393:	e8 91 28 00 00       	call   80103c29 <begin_op>
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
801013f9:	e8 af 28 00 00       	call   80103cad <end_op>

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
8010140e:	c7 04 24 18 9c 10 80 	movl   $0x80109c18,(%esp)
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
80101440:	c7 04 24 28 9c 10 80 	movl   $0x80109c28,(%esp)
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
80101486:	e8 39 47 00 00       	call   80105bc4 <memmove>
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
801014cc:	e8 24 46 00 00       	call   80105af5 <memset>
  log_write(bp);
801014d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014d4:	89 04 24             	mov    %eax,(%esp)
801014d7:	e8 58 29 00 00       	call   80103e34 <log_write>
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
801015a2:	e8 8d 28 00 00       	call   80103e34 <log_write>
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
80101619:	c7 04 24 34 9c 10 80 	movl   $0x80109c34,(%esp)
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
801016a8:	c7 04 24 4a 9c 10 80 	movl   $0x80109c4a,(%esp)
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
801016e0:	e8 4f 27 00 00       	call   80103e34 <log_write>
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
801016fb:	c7 44 24 04 5d 9c 10 	movl   $0x80109c5d,0x4(%esp)
80101702:	80 
80101703:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010170a:	e8 71 41 00 00       	call   80105880 <initlock>
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
8010176f:	c7 04 24 64 9c 10 80 	movl   $0x80109c64,(%esp)
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
801017f2:	e8 fe 42 00 00       	call   80105af5 <memset>
      dip->type = type;
801017f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017fa:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017fe:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101801:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101804:	89 04 24             	mov    %eax,(%esp)
80101807:	e8 28 26 00 00       	call   80103e34 <log_write>
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
8010184a:	c7 04 24 b7 9c 10 80 	movl   $0x80109cb7,(%esp)
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
801018f9:	e8 c6 42 00 00       	call   80105bc4 <memmove>
  log_write(bp);
801018fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101901:	89 04 24             	mov    %eax,(%esp)
80101904:	e8 2b 25 00 00       	call   80103e34 <log_write>
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
80101923:	e8 79 3f 00 00       	call   801058a1 <acquire>

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
8010196d:	e8 91 3f 00 00       	call   80105903 <release>
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
801019a0:	c7 04 24 c9 9c 10 80 	movl   $0x80109cc9,(%esp)
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
801019de:	e8 20 3f 00 00       	call   80105903 <release>

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
801019f5:	e8 a7 3e 00 00       	call   801058a1 <acquire>
  ip->ref++;
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	8b 40 08             	mov    0x8(%eax),%eax
80101a00:	8d 50 01             	lea    0x1(%eax),%edx
80101a03:	8b 45 08             	mov    0x8(%ebp),%eax
80101a06:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101a09:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a10:	e8 ee 3e 00 00       	call   80105903 <release>
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
80101a30:	c7 04 24 d9 9c 10 80 	movl   $0x80109cd9,(%esp)
80101a37:	e8 fe ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a43:	e8 59 3e 00 00       	call   801058a1 <acquire>
  while(ip->flags & I_BUSY)
80101a48:	eb 13                	jmp    80101a5d <ilock+0x43>
    sleep(ip, &icache.lock);
80101a4a:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
80101a51:	80 
80101a52:	8b 45 08             	mov    0x8(%ebp),%eax
80101a55:	89 04 24             	mov    %eax,(%esp)
80101a58:	e8 d7 3a 00 00       	call   80105534 <sleep>

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
80101a82:	e8 7c 3e 00 00       	call   80105903 <release>

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
80101b33:	e8 8c 40 00 00       	call   80105bc4 <memmove>
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
80101b60:	c7 04 24 df 9c 10 80 	movl   $0x80109cdf,(%esp)
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
80101b91:	c7 04 24 ee 9c 10 80 	movl   $0x80109cee,(%esp)
80101b98:	e8 9d e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b9d:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101ba4:	e8 f8 3c 00 00       	call   801058a1 <acquire>
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
80101bc0:	e8 4b 3a 00 00       	call   80105610 <wakeup>
  release(&icache.lock);
80101bc5:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101bcc:	e8 32 3d 00 00       	call   80105903 <release>
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
80101be0:	e8 bc 3c 00 00       	call   801058a1 <acquire>
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
80101c1e:	c7 04 24 f6 9c 10 80 	movl   $0x80109cf6,(%esp)
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
80101c42:	e8 bc 3c 00 00       	call   80105903 <release>
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
80101c6d:	e8 2f 3c 00 00       	call   801058a1 <acquire>
    ip->flags = 0;
80101c72:	8b 45 08             	mov    0x8(%ebp),%eax
80101c75:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7f:	89 04 24             	mov    %eax,(%esp)
80101c82:	e8 89 39 00 00       	call   80105610 <wakeup>
  }
  ip->ref--;
80101c87:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8a:	8b 40 08             	mov    0x8(%eax),%eax
80101c8d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c90:	8b 45 08             	mov    0x8(%ebp),%eax
80101c93:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c96:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c9d:	e8 61 3c 00 00       	call   80105903 <release>
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
80101da8:	e8 87 20 00 00       	call   80103e34 <log_write>
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
80101dbd:	c7 04 24 00 9d 10 80 	movl   $0x80109d00,(%esp)
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
8010205e:	e8 61 3b 00 00       	call   80105bc4 <memmove>
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
801021bd:	e8 02 3a 00 00       	call   80105bc4 <memmove>
    log_write(bp);
801021c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c5:	89 04 24             	mov    %eax,(%esp)
801021c8:	e8 67 1c 00 00       	call   80103e34 <log_write>
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
8010223b:	e8 27 3a 00 00       	call   80105c67 <strncmp>
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
80102255:	c7 04 24 13 9d 10 80 	movl   $0x80109d13,(%esp)
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
80102293:	c7 04 24 25 9d 10 80 	movl   $0x80109d25,(%esp)
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
80102378:	c7 04 24 25 9d 10 80 	movl   $0x80109d25,(%esp)
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
801023bd:	e8 fb 38 00 00       	call   80105cbd <strncpy>
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
801023ef:	c7 04 24 32 9d 10 80 	movl   $0x80109d32,(%esp)
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
80102474:	e8 4b 37 00 00       	call   80105bc4 <memmove>
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
8010248f:	e8 30 37 00 00       	call   80105bc4 <memmove>
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
801026de:	c7 44 24 04 3a 9d 10 	movl   $0x80109d3a,0x4(%esp)
801026e5:	80 
801026e6:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801026e9:	89 04 24             	mov    %eax,(%esp)
801026ec:	e8 d3 34 00 00       	call   80105bc4 <memmove>
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
8010272b:	e8 f9 14 00 00       	call   80103c29 <begin_op>
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
8010274b:	e8 5d 15 00 00       	call   80103cad <end_op>
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
80102765:	c7 44 24 04 41 9d 10 	movl   $0x80109d41,0x4(%esp)
8010276c:	80 
8010276d:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102770:	89 04 24             	mov    %eax,(%esp)
80102773:	e8 a8 fa ff ff       	call   80102220 <namecmp>
80102778:	85 c0                	test   %eax,%eax
8010277a:	0f 84 45 01 00 00    	je     801028c5 <removeSwapFile+0x1f5>
80102780:	c7 44 24 04 43 9d 10 	movl   $0x80109d43,0x4(%esp)
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
801027d9:	c7 04 24 46 9d 10 80 	movl   $0x80109d46,(%esp)
801027e0:	e8 55 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
801027e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027e8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027ec:	66 83 f8 01          	cmp    $0x1,%ax
801027f0:	75 1f                	jne    80102811 <removeSwapFile+0x141>
801027f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027f5:	89 04 24             	mov    %eax,(%esp)
801027f8:	e8 d2 3b 00 00       	call   801063cf <isdirempty>
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
80102827:	e8 c9 32 00 00       	call   80105af5 <memset>
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
80102852:	c7 04 24 58 9d 10 80 	movl   $0x80109d58,(%esp)
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
801028b9:	e8 ef 13 00 00       	call   80103cad <end_op>

	return 0;
801028be:	b8 00 00 00 00       	mov    $0x0,%eax
801028c3:	eb 15                	jmp    801028da <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
801028c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c8:	89 04 24             	mov    %eax,(%esp)
801028cb:	e8 d4 f3 ff ff       	call   80101ca4 <iunlockput>
		end_op();
801028d0:	e8 d8 13 00 00       	call   80103cad <end_op>
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
801028ea:	c7 44 24 04 3a 9d 10 	movl   $0x80109d3a,0x4(%esp)
801028f1:	80 
801028f2:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028f5:	89 04 24             	mov    %eax,(%esp)
801028f8:	e8 c7 32 00 00       	call   80105bc4 <memmove>
	itoa(p->pid, path+ 6);
801028fd:	8b 45 08             	mov    0x8(%ebp),%eax
80102900:	8b 40 10             	mov    0x10(%eax),%eax
80102903:	8d 55 e6             	lea    -0x1a(%ebp),%edx
80102906:	83 c2 06             	add    $0x6,%edx
80102909:	89 54 24 04          	mov    %edx,0x4(%esp)
8010290d:	89 04 24             	mov    %eax,(%esp)
80102910:	e8 fa fc ff ff       	call   8010260f <itoa>

    begin_op();
80102915:	e8 0f 13 00 00       	call   80103c29 <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
8010291a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80102921:	00 
80102922:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102929:	00 
8010292a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80102931:	00 
80102932:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102935:	89 04 24             	mov    %eax,(%esp)
80102938:	e8 d8 3c 00 00       	call   80106615 <create>
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
80102960:	c7 04 24 67 9d 10 80 	movl   $0x80109d67,(%esp)
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
801029a5:	e8 03 13 00 00       	call   80103cad <end_op>

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

void
copySwapFile(struct proc *from, struct proc *to){
80102a11:	55                   	push   %ebp
80102a12:	89 e5                	mov    %esp,%ebp
80102a14:	53                   	push   %ebx
80102a15:	83 ec 24             	sub    $0x24,%esp
   //cprintf("start copying\n");
   // copyingSwapFile(to,1);
   // copyingSwapFile(from,1);
   // cprintf("copy: %d\n",to->copyingSwapFile);
   char *mem = kalloc();
80102a18:	e8 a2 08 00 00       	call   801032bf <kalloc>
80102a1d:	89 45 ec             	mov    %eax,-0x14(%ebp)
   memmove(mem,0,PGSIZE);//elapse buf
80102a20:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102a27:	00 
80102a28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a2f:	00 
80102a30:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a33:	89 04 24             	mov    %eax,(%esp)
80102a36:	e8 89 31 00 00       	call   80105bc4 <memmove>
   int i,j;//k,t;
  //parent have swap file, copy it
   if(from->swapFile){
80102a3b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a3e:	8b 40 7c             	mov    0x7c(%eax),%eax
80102a41:	85 c0                	test   %eax,%eax
80102a43:	0f 84 6d 01 00 00    	je     80102bb6 <copySwapFile+0x1a5>
    for(j = 0; j < 30; j++){
80102a49:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102a50:	e9 57 01 00 00       	jmp    80102bac <copySwapFile+0x19b>
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
80102a55:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a58:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102a5b:	89 d0                	mov    %edx,%eax
80102a5d:	c1 e0 02             	shl    $0x2,%eax
80102a60:	01 d0                	add    %edx,%eax
80102a62:	c1 e0 02             	shl    $0x2,%eax
80102a65:	01 c8                	add    %ecx,%eax
80102a67:	05 98 00 00 00       	add    $0x98,%eax
80102a6c:	8b 00                	mov    (%eax),%eax
80102a6e:	83 f8 ff             	cmp    $0xffffffff,%eax
80102a71:	0f 84 31 01 00 00    	je     80102ba8 <copySwapFile+0x197>
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102a77:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a7e:	e9 1b 01 00 00       	jmp    80102b9e <copySwapFile+0x18d>
            if(to->pagesMetaData[i].va == from->pagesMetaData[j].va){//thats the one!
80102a83:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102a86:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a89:	89 d0                	mov    %edx,%eax
80102a8b:	c1 e0 02             	shl    $0x2,%eax
80102a8e:	01 d0                	add    %edx,%eax
80102a90:	c1 e0 02             	shl    $0x2,%eax
80102a93:	01 c8                	add    %ecx,%eax
80102a95:	05 90 00 00 00       	add    $0x90,%eax
80102a9a:	8b 08                	mov    (%eax),%ecx
80102a9c:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102a9f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102aa2:	89 d0                	mov    %edx,%eax
80102aa4:	c1 e0 02             	shl    $0x2,%eax
80102aa7:	01 d0                	add    %edx,%eax
80102aa9:	c1 e0 02             	shl    $0x2,%eax
80102aac:	01 d8                	add    %ebx,%eax
80102aae:	05 90 00 00 00       	add    $0x90,%eax
80102ab3:	8b 00                	mov    (%eax),%eax
80102ab5:	39 c1                	cmp    %eax,%ecx
80102ab7:	0f 85 dd 00 00 00    	jne    80102b9a <copySwapFile+0x189>
              to->pagesMetaData[i].fileOffset = from->pagesMetaData[j].fileOffset;
80102abd:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102ac0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ac3:	89 d0                	mov    %edx,%eax
80102ac5:	c1 e0 02             	shl    $0x2,%eax
80102ac8:	01 d0                	add    %edx,%eax
80102aca:	c1 e0 02             	shl    $0x2,%eax
80102acd:	01 c8                	add    %ecx,%eax
80102acf:	05 98 00 00 00       	add    $0x98,%eax
80102ad4:	8b 08                	mov    (%eax),%ecx
80102ad6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80102ad9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102adc:	89 d0                	mov    %edx,%eax
80102ade:	c1 e0 02             	shl    $0x2,%eax
80102ae1:	01 d0                	add    %edx,%eax
80102ae3:	c1 e0 02             	shl    $0x2,%eax
80102ae6:	01 d8                	add    %ebx,%eax
80102ae8:	05 98 00 00 00       	add    $0x98,%eax
80102aed:	89 08                	mov    %ecx,(%eax)
              // for(k = 0; k < 4; k++){//move only 1024 bytes chunks
              // t = k*1024;
              if(readFromSwapFile(from,mem,from->pagesMetaData[j].fileOffset,PGSIZE) == -1){
80102aef:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102af2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102af5:	89 d0                	mov    %edx,%eax
80102af7:	c1 e0 02             	shl    $0x2,%eax
80102afa:	01 d0                	add    %edx,%eax
80102afc:	c1 e0 02             	shl    $0x2,%eax
80102aff:	01 c8                	add    %ecx,%eax
80102b01:	05 98 00 00 00       	add    $0x98,%eax
80102b06:	8b 00                	mov    (%eax),%eax
80102b08:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80102b0f:	00 
80102b10:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b17:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b1e:	89 04 24             	mov    %eax,(%esp)
80102b21:	e8 bb fe ff ff       	call   801029e1 <readFromSwapFile>
80102b26:	83 f8 ff             	cmp    $0xffffffff,%eax
80102b29:	75 0c                	jne    80102b37 <copySwapFile+0x126>
                panic("can't read from swap file"); 
80102b2b:	c7 04 24 83 9d 10 80 	movl   $0x80109d83,(%esp)
80102b32:	e8 03 da ff ff       	call   8010053a <panic>
              }
              if(writeToSwapFile(to,mem,to->pagesMetaData[i].fileOffset,PGSIZE) == -1){
80102b37:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b3a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b3d:	89 d0                	mov    %edx,%eax
80102b3f:	c1 e0 02             	shl    $0x2,%eax
80102b42:	01 d0                	add    %edx,%eax
80102b44:	c1 e0 02             	shl    $0x2,%eax
80102b47:	01 c8                	add    %ecx,%eax
80102b49:	05 98 00 00 00       	add    $0x98,%eax
80102b4e:	8b 00                	mov    (%eax),%eax
80102b50:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80102b57:	00 
80102b58:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b63:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b66:	89 04 24             	mov    %eax,(%esp)
80102b69:	e8 43 fe ff ff       	call   801029b1 <writeToSwapFile>
80102b6e:	83 f8 ff             	cmp    $0xffffffff,%eax
80102b71:	75 0c                	jne    80102b7f <copySwapFile+0x16e>
                cprintf("fail again\n");
80102b73:	c7 04 24 9d 9d 10 80 	movl   $0x80109d9d,(%esp)
80102b7a:	e8 21 d8 ff ff       	call   801003a0 <cprintf>
                //cprintf("problem at %d from va:%x to va:%x from offset:%d to offset:%d k:%d t:%d copying: %d\n",j,from->pagesMetaData[i].va,to->pagesMetaData[i].va,from->pagesMetaData[i].fileOffset,to->pagesMetaData[i].fileOffset,k,t, proc->copyingSwapFile);
                //panic("can't write to swap file");
              }
              memmove(mem,0,PGSIZE);//elapse buf
80102b7f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102b86:	00 
80102b87:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b8e:	00 
80102b8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b92:	89 04 24             	mov    %eax,(%esp)
80102b95:	e8 2a 30 00 00       	call   80105bc4 <memmove>
  //parent have swap file, copy it
   if(from->swapFile){
    for(j = 0; j < 30; j++){
        if(from->pagesMetaData[j].fileOffset != -1){//the from[j] is in the swap file
          //find his match in to[] and copy the page
          for(i = 0; i < 30; i++){
80102b9a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b9e:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80102ba2:	0f 8e db fe ff ff    	jle    80102a83 <copySwapFile+0x72>
   char *mem = kalloc();
   memmove(mem,0,PGSIZE);//elapse buf
   int i,j;//k,t;
  //parent have swap file, copy it
   if(from->swapFile){
    for(j = 0; j < 30; j++){
80102ba8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102bac:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80102bb0:	0f 8e 9f fe ff ff    	jle    80102a55 <copySwapFile+0x44>
        }
      }
    }
    // copyingSwapFile(to,0);
    // copyingSwapFile(from,0);
    kfree(mem);
80102bb6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bb9:	89 04 24             	mov    %eax,(%esp)
80102bbc:	e8 3c 06 00 00       	call   801031fd <kfree>
80102bc1:	83 c4 24             	add    $0x24,%esp
80102bc4:	5b                   	pop    %ebx
80102bc5:	5d                   	pop    %ebp
80102bc6:	c3                   	ret    

80102bc7 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102bc7:	55                   	push   %ebp
80102bc8:	89 e5                	mov    %esp,%ebp
80102bca:	83 ec 14             	sub    $0x14,%esp
80102bcd:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd0:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102bd4:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102bd8:	89 c2                	mov    %eax,%edx
80102bda:	ec                   	in     (%dx),%al
80102bdb:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102bde:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102be2:	c9                   	leave  
80102be3:	c3                   	ret    

80102be4 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102be4:	55                   	push   %ebp
80102be5:	89 e5                	mov    %esp,%ebp
80102be7:	57                   	push   %edi
80102be8:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102be9:	8b 55 08             	mov    0x8(%ebp),%edx
80102bec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102bef:	8b 45 10             	mov    0x10(%ebp),%eax
80102bf2:	89 cb                	mov    %ecx,%ebx
80102bf4:	89 df                	mov    %ebx,%edi
80102bf6:	89 c1                	mov    %eax,%ecx
80102bf8:	fc                   	cld    
80102bf9:	f3 6d                	rep insl (%dx),%es:(%edi)
80102bfb:	89 c8                	mov    %ecx,%eax
80102bfd:	89 fb                	mov    %edi,%ebx
80102bff:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102c02:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102c05:	5b                   	pop    %ebx
80102c06:	5f                   	pop    %edi
80102c07:	5d                   	pop    %ebp
80102c08:	c3                   	ret    

80102c09 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102c09:	55                   	push   %ebp
80102c0a:	89 e5                	mov    %esp,%ebp
80102c0c:	83 ec 08             	sub    $0x8,%esp
80102c0f:	8b 55 08             	mov    0x8(%ebp),%edx
80102c12:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c15:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102c19:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102c1c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102c20:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102c24:	ee                   	out    %al,(%dx)
}
80102c25:	c9                   	leave  
80102c26:	c3                   	ret    

80102c27 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102c27:	55                   	push   %ebp
80102c28:	89 e5                	mov    %esp,%ebp
80102c2a:	56                   	push   %esi
80102c2b:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102c2c:	8b 55 08             	mov    0x8(%ebp),%edx
80102c2f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102c32:	8b 45 10             	mov    0x10(%ebp),%eax
80102c35:	89 cb                	mov    %ecx,%ebx
80102c37:	89 de                	mov    %ebx,%esi
80102c39:	89 c1                	mov    %eax,%ecx
80102c3b:	fc                   	cld    
80102c3c:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102c3e:	89 c8                	mov    %ecx,%eax
80102c40:	89 f3                	mov    %esi,%ebx
80102c42:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102c45:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102c48:	5b                   	pop    %ebx
80102c49:	5e                   	pop    %esi
80102c4a:	5d                   	pop    %ebp
80102c4b:	c3                   	ret    

80102c4c <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102c4c:	55                   	push   %ebp
80102c4d:	89 e5                	mov    %esp,%ebp
80102c4f:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102c52:	90                   	nop
80102c53:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c5a:	e8 68 ff ff ff       	call   80102bc7 <inb>
80102c5f:	0f b6 c0             	movzbl %al,%eax
80102c62:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102c65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c68:	25 c0 00 00 00       	and    $0xc0,%eax
80102c6d:	83 f8 40             	cmp    $0x40,%eax
80102c70:	75 e1                	jne    80102c53 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102c72:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102c76:	74 11                	je     80102c89 <idewait+0x3d>
80102c78:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c7b:	83 e0 21             	and    $0x21,%eax
80102c7e:	85 c0                	test   %eax,%eax
80102c80:	74 07                	je     80102c89 <idewait+0x3d>
    return -1;
80102c82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c87:	eb 05                	jmp    80102c8e <idewait+0x42>
  return 0;
80102c89:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102c8e:	c9                   	leave  
80102c8f:	c3                   	ret    

80102c90 <ideinit>:

void
ideinit(void)
{
80102c90:	55                   	push   %ebp
80102c91:	89 e5                	mov    %esp,%ebp
80102c93:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102c96:	c7 44 24 04 a9 9d 10 	movl   $0x80109da9,0x4(%esp)
80102c9d:	80 
80102c9e:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102ca5:	e8 d6 2b 00 00       	call   80105880 <initlock>
  picenable(IRQ_IDE);
80102caa:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102cb1:	e8 12 19 00 00       	call   801045c8 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102cb6:	a1 40 49 11 80       	mov    0x80114940,%eax
80102cbb:	83 e8 01             	sub    $0x1,%eax
80102cbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cc2:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102cc9:	e8 43 04 00 00       	call   80103111 <ioapicenable>
  idewait(0);
80102cce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102cd5:	e8 72 ff ff ff       	call   80102c4c <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102cda:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102ce1:	00 
80102ce2:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102ce9:	e8 1b ff ff ff       	call   80102c09 <outb>
  for(i=0; i<1000; i++){
80102cee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cf5:	eb 20                	jmp    80102d17 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102cf7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102cfe:	e8 c4 fe ff ff       	call   80102bc7 <inb>
80102d03:	84 c0                	test   %al,%al
80102d05:	74 0c                	je     80102d13 <ideinit+0x83>
      havedisk1 = 1;
80102d07:	c7 05 38 d6 10 80 01 	movl   $0x1,0x8010d638
80102d0e:	00 00 00 
      break;
80102d11:	eb 0d                	jmp    80102d20 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102d13:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102d17:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102d1e:	7e d7                	jle    80102cf7 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102d20:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102d27:	00 
80102d28:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102d2f:	e8 d5 fe ff ff       	call   80102c09 <outb>
}
80102d34:	c9                   	leave  
80102d35:	c3                   	ret    

80102d36 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102d36:	55                   	push   %ebp
80102d37:	89 e5                	mov    %esp,%ebp
80102d39:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102d3c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102d40:	75 0c                	jne    80102d4e <idestart+0x18>
    panic("idestart");
80102d42:	c7 04 24 ad 9d 10 80 	movl   $0x80109dad,(%esp)
80102d49:	e8 ec d7 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d51:	8b 40 08             	mov    0x8(%eax),%eax
80102d54:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102d59:	76 0c                	jbe    80102d67 <idestart+0x31>
    panic("incorrect blockno");
80102d5b:	c7 04 24 b6 9d 10 80 	movl   $0x80109db6,(%esp)
80102d62:	e8 d3 d7 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102d67:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d71:	8b 50 08             	mov    0x8(%eax),%edx
80102d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d77:	0f af c2             	imul   %edx,%eax
80102d7a:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102d7d:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102d81:	7e 0c                	jle    80102d8f <idestart+0x59>
80102d83:	c7 04 24 ad 9d 10 80 	movl   $0x80109dad,(%esp)
80102d8a:	e8 ab d7 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102d8f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102d96:	e8 b1 fe ff ff       	call   80102c4c <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102d9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102da2:	00 
80102da3:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102daa:	e8 5a fe ff ff       	call   80102c09 <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102db2:	0f b6 c0             	movzbl %al,%eax
80102db5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102db9:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102dc0:	e8 44 fe ff ff       	call   80102c09 <outb>
  outb(0x1f3, sector & 0xff);
80102dc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dc8:	0f b6 c0             	movzbl %al,%eax
80102dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dcf:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102dd6:	e8 2e fe ff ff       	call   80102c09 <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102ddb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dde:	c1 f8 08             	sar    $0x8,%eax
80102de1:	0f b6 c0             	movzbl %al,%eax
80102de4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102de8:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102def:	e8 15 fe ff ff       	call   80102c09 <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102df4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102df7:	c1 f8 10             	sar    $0x10,%eax
80102dfa:	0f b6 c0             	movzbl %al,%eax
80102dfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e01:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102e08:	e8 fc fd ff ff       	call   80102c09 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102e10:	8b 40 04             	mov    0x4(%eax),%eax
80102e13:	83 e0 01             	and    $0x1,%eax
80102e16:	c1 e0 04             	shl    $0x4,%eax
80102e19:	89 c2                	mov    %eax,%edx
80102e1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e1e:	c1 f8 18             	sar    $0x18,%eax
80102e21:	83 e0 0f             	and    $0xf,%eax
80102e24:	09 d0                	or     %edx,%eax
80102e26:	83 c8 e0             	or     $0xffffffe0,%eax
80102e29:	0f b6 c0             	movzbl %al,%eax
80102e2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e30:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102e37:	e8 cd fd ff ff       	call   80102c09 <outb>
  if(b->flags & B_DIRTY){
80102e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80102e3f:	8b 00                	mov    (%eax),%eax
80102e41:	83 e0 04             	and    $0x4,%eax
80102e44:	85 c0                	test   %eax,%eax
80102e46:	74 34                	je     80102e7c <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102e48:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102e4f:	00 
80102e50:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102e57:	e8 ad fd ff ff       	call   80102c09 <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102e5c:	8b 45 08             	mov    0x8(%ebp),%eax
80102e5f:	83 c0 18             	add    $0x18,%eax
80102e62:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e69:	00 
80102e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e6e:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e75:	e8 ad fd ff ff       	call   80102c27 <outsl>
80102e7a:	eb 14                	jmp    80102e90 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102e7c:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102e83:	00 
80102e84:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102e8b:	e8 79 fd ff ff       	call   80102c09 <outb>
  }
}
80102e90:	c9                   	leave  
80102e91:	c3                   	ret    

80102e92 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102e92:	55                   	push   %ebp
80102e93:	89 e5                	mov    %esp,%ebp
80102e95:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102e98:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e9f:	e8 fd 29 00 00       	call   801058a1 <acquire>
  if((b = idequeue) == 0){
80102ea4:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ea9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102eac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102eb0:	75 11                	jne    80102ec3 <ideintr+0x31>
    release(&idelock);
80102eb2:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102eb9:	e8 45 2a 00 00       	call   80105903 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102ebe:	e9 90 00 00 00       	jmp    80102f53 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ec6:	8b 40 14             	mov    0x14(%eax),%eax
80102ec9:	a3 34 d6 10 80       	mov    %eax,0x8010d634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102ece:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ed1:	8b 00                	mov    (%eax),%eax
80102ed3:	83 e0 04             	and    $0x4,%eax
80102ed6:	85 c0                	test   %eax,%eax
80102ed8:	75 2e                	jne    80102f08 <ideintr+0x76>
80102eda:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102ee1:	e8 66 fd ff ff       	call   80102c4c <idewait>
80102ee6:	85 c0                	test   %eax,%eax
80102ee8:	78 1e                	js     80102f08 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102eea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eed:	83 c0 18             	add    $0x18,%eax
80102ef0:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102ef7:	00 
80102ef8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102efc:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102f03:	e8 dc fc ff ff       	call   80102be4 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f0b:	8b 00                	mov    (%eax),%eax
80102f0d:	83 c8 02             	or     $0x2,%eax
80102f10:	89 c2                	mov    %eax,%edx
80102f12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f15:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102f17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f1a:	8b 00                	mov    (%eax),%eax
80102f1c:	83 e0 fb             	and    $0xfffffffb,%eax
80102f1f:	89 c2                	mov    %eax,%edx
80102f21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f24:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102f26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f29:	89 04 24             	mov    %eax,(%esp)
80102f2c:	e8 df 26 00 00       	call   80105610 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102f31:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f36:	85 c0                	test   %eax,%eax
80102f38:	74 0d                	je     80102f47 <ideintr+0xb5>
    idestart(idequeue);
80102f3a:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f3f:	89 04 24             	mov    %eax,(%esp)
80102f42:	e8 ef fd ff ff       	call   80102d36 <idestart>

  release(&idelock);
80102f47:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f4e:	e8 b0 29 00 00       	call   80105903 <release>
}
80102f53:	c9                   	leave  
80102f54:	c3                   	ret    

80102f55 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102f55:	55                   	push   %ebp
80102f56:	89 e5                	mov    %esp,%ebp
80102f58:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102f5b:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5e:	8b 00                	mov    (%eax),%eax
80102f60:	83 e0 01             	and    $0x1,%eax
80102f63:	85 c0                	test   %eax,%eax
80102f65:	75 0c                	jne    80102f73 <iderw+0x1e>
    panic("iderw: buf not busy");
80102f67:	c7 04 24 c8 9d 10 80 	movl   $0x80109dc8,(%esp)
80102f6e:	e8 c7 d5 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102f73:	8b 45 08             	mov    0x8(%ebp),%eax
80102f76:	8b 00                	mov    (%eax),%eax
80102f78:	83 e0 06             	and    $0x6,%eax
80102f7b:	83 f8 02             	cmp    $0x2,%eax
80102f7e:	75 0c                	jne    80102f8c <iderw+0x37>
    panic("iderw: nothing to do");
80102f80:	c7 04 24 dc 9d 10 80 	movl   $0x80109ddc,(%esp)
80102f87:	e8 ae d5 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102f8c:	8b 45 08             	mov    0x8(%ebp),%eax
80102f8f:	8b 40 04             	mov    0x4(%eax),%eax
80102f92:	85 c0                	test   %eax,%eax
80102f94:	74 15                	je     80102fab <iderw+0x56>
80102f96:	a1 38 d6 10 80       	mov    0x8010d638,%eax
80102f9b:	85 c0                	test   %eax,%eax
80102f9d:	75 0c                	jne    80102fab <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102f9f:	c7 04 24 f1 9d 10 80 	movl   $0x80109df1,(%esp)
80102fa6:	e8 8f d5 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102fab:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102fb2:	e8 ea 28 00 00       	call   801058a1 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102fba:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102fc1:	c7 45 f4 34 d6 10 80 	movl   $0x8010d634,-0xc(%ebp)
80102fc8:	eb 0b                	jmp    80102fd5 <iderw+0x80>
80102fca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fcd:	8b 00                	mov    (%eax),%eax
80102fcf:	83 c0 14             	add    $0x14,%eax
80102fd2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102fd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fd8:	8b 00                	mov    (%eax),%eax
80102fda:	85 c0                	test   %eax,%eax
80102fdc:	75 ec                	jne    80102fca <iderw+0x75>
    ;
  *pp = b;
80102fde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fe1:	8b 55 08             	mov    0x8(%ebp),%edx
80102fe4:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102fe6:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102feb:	3b 45 08             	cmp    0x8(%ebp),%eax
80102fee:	75 0d                	jne    80102ffd <iderw+0xa8>
    idestart(b);
80102ff0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ff3:	89 04 24             	mov    %eax,(%esp)
80102ff6:	e8 3b fd ff ff       	call   80102d36 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ffb:	eb 15                	jmp    80103012 <iderw+0xbd>
80102ffd:	eb 13                	jmp    80103012 <iderw+0xbd>
    sleep(b, &idelock);
80102fff:	c7 44 24 04 00 d6 10 	movl   $0x8010d600,0x4(%esp)
80103006:	80 
80103007:	8b 45 08             	mov    0x8(%ebp),%eax
8010300a:	89 04 24             	mov    %eax,(%esp)
8010300d:	e8 22 25 00 00       	call   80105534 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103012:	8b 45 08             	mov    0x8(%ebp),%eax
80103015:	8b 00                	mov    (%eax),%eax
80103017:	83 e0 06             	and    $0x6,%eax
8010301a:	83 f8 02             	cmp    $0x2,%eax
8010301d:	75 e0                	jne    80102fff <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
8010301f:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80103026:	e8 d8 28 00 00       	call   80105903 <release>
}
8010302b:	c9                   	leave  
8010302c:	c3                   	ret    

8010302d <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
8010302d:	55                   	push   %ebp
8010302e:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103030:	a1 14 42 11 80       	mov    0x80114214,%eax
80103035:	8b 55 08             	mov    0x8(%ebp),%edx
80103038:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
8010303a:	a1 14 42 11 80       	mov    0x80114214,%eax
8010303f:	8b 40 10             	mov    0x10(%eax),%eax
}
80103042:	5d                   	pop    %ebp
80103043:	c3                   	ret    

80103044 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103044:	55                   	push   %ebp
80103045:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103047:	a1 14 42 11 80       	mov    0x80114214,%eax
8010304c:	8b 55 08             	mov    0x8(%ebp),%edx
8010304f:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103051:	a1 14 42 11 80       	mov    0x80114214,%eax
80103056:	8b 55 0c             	mov    0xc(%ebp),%edx
80103059:	89 50 10             	mov    %edx,0x10(%eax)
}
8010305c:	5d                   	pop    %ebp
8010305d:	c3                   	ret    

8010305e <ioapicinit>:

void
ioapicinit(void)
{
8010305e:	55                   	push   %ebp
8010305f:	89 e5                	mov    %esp,%ebp
80103061:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103064:	a1 44 43 11 80       	mov    0x80114344,%eax
80103069:	85 c0                	test   %eax,%eax
8010306b:	75 05                	jne    80103072 <ioapicinit+0x14>
    return;
8010306d:	e9 9d 00 00 00       	jmp    8010310f <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80103072:	c7 05 14 42 11 80 00 	movl   $0xfec00000,0x80114214
80103079:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010307c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103083:	e8 a5 ff ff ff       	call   8010302d <ioapicread>
80103088:	c1 e8 10             	shr    $0x10,%eax
8010308b:	25 ff 00 00 00       	and    $0xff,%eax
80103090:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103093:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010309a:	e8 8e ff ff ff       	call   8010302d <ioapicread>
8010309f:	c1 e8 18             	shr    $0x18,%eax
801030a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801030a5:	0f b6 05 40 43 11 80 	movzbl 0x80114340,%eax
801030ac:	0f b6 c0             	movzbl %al,%eax
801030af:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801030b2:	74 0c                	je     801030c0 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801030b4:	c7 04 24 10 9e 10 80 	movl   $0x80109e10,(%esp)
801030bb:	e8 e0 d2 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801030c0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030c7:	eb 3e                	jmp    80103107 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801030c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030cc:	83 c0 20             	add    $0x20,%eax
801030cf:	0d 00 00 01 00       	or     $0x10000,%eax
801030d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801030d7:	83 c2 08             	add    $0x8,%edx
801030da:	01 d2                	add    %edx,%edx
801030dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801030e0:	89 14 24             	mov    %edx,(%esp)
801030e3:	e8 5c ff ff ff       	call   80103044 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801030e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030eb:	83 c0 08             	add    $0x8,%eax
801030ee:	01 c0                	add    %eax,%eax
801030f0:	83 c0 01             	add    $0x1,%eax
801030f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030fa:	00 
801030fb:	89 04 24             	mov    %eax,(%esp)
801030fe:	e8 41 ff ff ff       	call   80103044 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103103:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103107:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010310a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010310d:	7e ba                	jle    801030c9 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
8010310f:	c9                   	leave  
80103110:	c3                   	ret    

80103111 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103111:	55                   	push   %ebp
80103112:	89 e5                	mov    %esp,%ebp
80103114:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103117:	a1 44 43 11 80       	mov    0x80114344,%eax
8010311c:	85 c0                	test   %eax,%eax
8010311e:	75 02                	jne    80103122 <ioapicenable+0x11>
    return;
80103120:	eb 37                	jmp    80103159 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103122:	8b 45 08             	mov    0x8(%ebp),%eax
80103125:	83 c0 20             	add    $0x20,%eax
80103128:	8b 55 08             	mov    0x8(%ebp),%edx
8010312b:	83 c2 08             	add    $0x8,%edx
8010312e:	01 d2                	add    %edx,%edx
80103130:	89 44 24 04          	mov    %eax,0x4(%esp)
80103134:	89 14 24             	mov    %edx,(%esp)
80103137:	e8 08 ff ff ff       	call   80103044 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
8010313c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010313f:	c1 e0 18             	shl    $0x18,%eax
80103142:	8b 55 08             	mov    0x8(%ebp),%edx
80103145:	83 c2 08             	add    $0x8,%edx
80103148:	01 d2                	add    %edx,%edx
8010314a:	83 c2 01             	add    $0x1,%edx
8010314d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103151:	89 14 24             	mov    %edx,(%esp)
80103154:	e8 eb fe ff ff       	call   80103044 <ioapicwrite>
}
80103159:	c9                   	leave  
8010315a:	c3                   	ret    

8010315b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010315b:	55                   	push   %ebp
8010315c:	89 e5                	mov    %esp,%ebp
8010315e:	8b 45 08             	mov    0x8(%ebp),%eax
80103161:	05 00 00 00 80       	add    $0x80000000,%eax
80103166:	5d                   	pop    %ebp
80103167:	c3                   	ret    

80103168 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103168:	55                   	push   %ebp
80103169:	89 e5                	mov    %esp,%ebp
8010316b:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
8010316e:	c7 44 24 04 42 9e 10 	movl   $0x80109e42,0x4(%esp)
80103175:	80 
80103176:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010317d:	e8 fe 26 00 00       	call   80105880 <initlock>
  kmem.use_lock = 0;
80103182:	c7 05 54 42 11 80 00 	movl   $0x0,0x80114254
80103189:	00 00 00 
  freerange(vstart, vend);
8010318c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010318f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103193:	8b 45 08             	mov    0x8(%ebp),%eax
80103196:	89 04 24             	mov    %eax,(%esp)
80103199:	e8 26 00 00 00       	call   801031c4 <freerange>
}
8010319e:	c9                   	leave  
8010319f:	c3                   	ret    

801031a0 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801031a0:	55                   	push   %ebp
801031a1:	89 e5                	mov    %esp,%ebp
801031a3:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801031a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801031a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801031ad:	8b 45 08             	mov    0x8(%ebp),%eax
801031b0:	89 04 24             	mov    %eax,(%esp)
801031b3:	e8 0c 00 00 00       	call   801031c4 <freerange>
  kmem.use_lock = 1;
801031b8:	c7 05 54 42 11 80 01 	movl   $0x1,0x80114254
801031bf:	00 00 00 
}
801031c2:	c9                   	leave  
801031c3:	c3                   	ret    

801031c4 <freerange>:

void
freerange(void *vstart, void *vend)
{
801031c4:	55                   	push   %ebp
801031c5:	89 e5                	mov    %esp,%ebp
801031c7:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801031ca:	8b 45 08             	mov    0x8(%ebp),%eax
801031cd:	05 ff 0f 00 00       	add    $0xfff,%eax
801031d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801031d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801031da:	eb 12                	jmp    801031ee <freerange+0x2a>
    kfree(p);
801031dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031df:	89 04 24             	mov    %eax,(%esp)
801031e2:	e8 16 00 00 00       	call   801031fd <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801031e7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801031ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031f1:	05 00 10 00 00       	add    $0x1000,%eax
801031f6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801031f9:	76 e1                	jbe    801031dc <freerange+0x18>
    kfree(p);
}
801031fb:	c9                   	leave  
801031fc:	c3                   	ret    

801031fd <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
801031fd:	55                   	push   %ebp
801031fe:	89 e5                	mov    %esp,%ebp
80103200:	83 ec 28             	sub    $0x28,%esp
  // if(getPid()){
  //   cprintf("%x\n",v);
  // }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
80103203:	8b 45 08             	mov    0x8(%ebp),%eax
80103206:	25 ff 0f 00 00       	and    $0xfff,%eax
8010320b:	85 c0                	test   %eax,%eax
8010320d:	75 1b                	jne    8010322a <kfree+0x2d>
8010320f:	81 7d 08 5c 0e 12 80 	cmpl   $0x80120e5c,0x8(%ebp)
80103216:	72 12                	jb     8010322a <kfree+0x2d>
80103218:	8b 45 08             	mov    0x8(%ebp),%eax
8010321b:	89 04 24             	mov    %eax,(%esp)
8010321e:	e8 38 ff ff ff       	call   8010315b <v2p>
80103223:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103228:	76 50                	jbe    8010327a <kfree+0x7d>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
8010322a:	8b 45 08             	mov    0x8(%ebp),%eax
8010322d:	89 04 24             	mov    %eax,(%esp)
80103230:	e8 26 ff ff ff       	call   8010315b <v2p>
80103235:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010323a:	0f 97 c0             	seta   %al
8010323d:	0f b6 d0             	movzbl %al,%edx
80103240:	81 7d 08 5c 0e 12 80 	cmpl   $0x80120e5c,0x8(%ebp)
80103247:	0f 92 c0             	setb   %al
8010324a:	0f b6 c0             	movzbl %al,%eax
8010324d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103250:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
80103256:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010325a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010325e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80103262:	c7 04 24 47 9e 10 80 	movl   $0x80109e47,(%esp)
80103269:	e8 32 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
8010326e:	c7 04 24 5e 9e 10 80 	movl   $0x80109e5e,(%esp)
80103275:	e8 c0 d2 ff ff       	call   8010053a <panic>
  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  // if(getPid()){
  //   cprintf("after memset\n");
  // }
  if(kmem.use_lock)
8010327a:	a1 54 42 11 80       	mov    0x80114254,%eax
8010327f:	85 c0                	test   %eax,%eax
80103281:	74 0c                	je     8010328f <kfree+0x92>
    acquire(&kmem.lock);
80103283:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010328a:	e8 12 26 00 00       	call   801058a1 <acquire>
  r = (struct run*)v;
8010328f:	8b 45 08             	mov    0x8(%ebp),%eax
80103292:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103295:	8b 15 58 42 11 80    	mov    0x80114258,%edx
8010329b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010329e:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
801032a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032a3:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
801032a8:	a1 54 42 11 80       	mov    0x80114254,%eax
801032ad:	85 c0                	test   %eax,%eax
801032af:	74 0c                	je     801032bd <kfree+0xc0>
    release(&kmem.lock);
801032b1:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032b8:	e8 46 26 00 00       	call   80105903 <release>
}
801032bd:	c9                   	leave  
801032be:	c3                   	ret    

801032bf <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801032bf:	55                   	push   %ebp
801032c0:	89 e5                	mov    %esp,%ebp
801032c2:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
801032c5:	a1 54 42 11 80       	mov    0x80114254,%eax
801032ca:	85 c0                	test   %eax,%eax
801032cc:	74 0c                	je     801032da <kalloc+0x1b>
    acquire(&kmem.lock);
801032ce:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032d5:	e8 c7 25 00 00       	call   801058a1 <acquire>
  r = kmem.freelist;
801032da:	a1 58 42 11 80       	mov    0x80114258,%eax
801032df:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801032e2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801032e6:	74 0a                	je     801032f2 <kalloc+0x33>
    kmem.freelist = r->next;
801032e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032eb:	8b 00                	mov    (%eax),%eax
801032ed:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
801032f2:	a1 54 42 11 80       	mov    0x80114254,%eax
801032f7:	85 c0                	test   %eax,%eax
801032f9:	74 0c                	je     80103307 <kalloc+0x48>
    release(&kmem.lock);
801032fb:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103302:	e8 fc 25 00 00       	call   80105903 <release>
  return (char*)r;
80103307:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010330a:	c9                   	leave  
8010330b:	c3                   	ret    

8010330c <countPages>:

int
countPages(){
8010330c:	55                   	push   %ebp
8010330d:	89 e5                	mov    %esp,%ebp
8010330f:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
80103312:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
80103319:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103320:	e8 7c 25 00 00       	call   801058a1 <acquire>
  r = kmem.freelist;
80103325:	a1 58 42 11 80       	mov    0x80114258,%eax
8010332a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
8010332d:	eb 0c                	jmp    8010333b <countPages+0x2f>
    result++;
8010332f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
80103333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103336:	8b 00                	mov    (%eax),%eax
80103338:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
8010333b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010333f:	75 ee                	jne    8010332f <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
80103341:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103348:	e8 b6 25 00 00       	call   80105903 <release>
  return result;
8010334d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103350:	c9                   	leave  
80103351:	c3                   	ret    

80103352 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103352:	55                   	push   %ebp
80103353:	89 e5                	mov    %esp,%ebp
80103355:	83 ec 14             	sub    $0x14,%esp
80103358:	8b 45 08             	mov    0x8(%ebp),%eax
8010335b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010335f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103363:	89 c2                	mov    %eax,%edx
80103365:	ec                   	in     (%dx),%al
80103366:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103369:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010336d:	c9                   	leave  
8010336e:	c3                   	ret    

8010336f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010336f:	55                   	push   %ebp
80103370:	89 e5                	mov    %esp,%ebp
80103372:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103375:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010337c:	e8 d1 ff ff ff       	call   80103352 <inb>
80103381:	0f b6 c0             	movzbl %al,%eax
80103384:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338a:	83 e0 01             	and    $0x1,%eax
8010338d:	85 c0                	test   %eax,%eax
8010338f:	75 0a                	jne    8010339b <kbdgetc+0x2c>
    return -1;
80103391:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103396:	e9 25 01 00 00       	jmp    801034c0 <kbdgetc+0x151>
  data = inb(KBDATAP);
8010339b:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
801033a2:	e8 ab ff ff ff       	call   80103352 <inb>
801033a7:	0f b6 c0             	movzbl %al,%eax
801033aa:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
801033ad:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
801033b4:	75 17                	jne    801033cd <kbdgetc+0x5e>
    shift |= E0ESC;
801033b6:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033bb:	83 c8 40             	or     $0x40,%eax
801033be:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
801033c3:	b8 00 00 00 00       	mov    $0x0,%eax
801033c8:	e9 f3 00 00 00       	jmp    801034c0 <kbdgetc+0x151>
  } else if(data & 0x80){
801033cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033d0:	25 80 00 00 00       	and    $0x80,%eax
801033d5:	85 c0                	test   %eax,%eax
801033d7:	74 45                	je     8010341e <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
801033d9:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033de:	83 e0 40             	and    $0x40,%eax
801033e1:	85 c0                	test   %eax,%eax
801033e3:	75 08                	jne    801033ed <kbdgetc+0x7e>
801033e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033e8:	83 e0 7f             	and    $0x7f,%eax
801033eb:	eb 03                	jmp    801033f0 <kbdgetc+0x81>
801033ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f0:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
801033f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f6:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033fb:	0f b6 00             	movzbl (%eax),%eax
801033fe:	83 c8 40             	or     $0x40,%eax
80103401:	0f b6 c0             	movzbl %al,%eax
80103404:	f7 d0                	not    %eax
80103406:	89 c2                	mov    %eax,%edx
80103408:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010340d:	21 d0                	and    %edx,%eax
8010340f:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103414:	b8 00 00 00 00       	mov    $0x0,%eax
80103419:	e9 a2 00 00 00       	jmp    801034c0 <kbdgetc+0x151>
  } else if(shift & E0ESC){
8010341e:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103423:	83 e0 40             	and    $0x40,%eax
80103426:	85 c0                	test   %eax,%eax
80103428:	74 14                	je     8010343e <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010342a:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103431:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103436:	83 e0 bf             	and    $0xffffffbf,%eax
80103439:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
8010343e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103441:	05 20 b0 10 80       	add    $0x8010b020,%eax
80103446:	0f b6 00             	movzbl (%eax),%eax
80103449:	0f b6 d0             	movzbl %al,%edx
8010344c:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103451:	09 d0                	or     %edx,%eax
80103453:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
80103458:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010345b:	05 20 b1 10 80       	add    $0x8010b120,%eax
80103460:	0f b6 00             	movzbl (%eax),%eax
80103463:	0f b6 d0             	movzbl %al,%edx
80103466:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010346b:	31 d0                	xor    %edx,%eax
8010346d:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
80103472:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103477:	83 e0 03             	and    $0x3,%eax
8010347a:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
80103481:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103484:	01 d0                	add    %edx,%eax
80103486:	0f b6 00             	movzbl (%eax),%eax
80103489:	0f b6 c0             	movzbl %al,%eax
8010348c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
8010348f:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103494:	83 e0 08             	and    $0x8,%eax
80103497:	85 c0                	test   %eax,%eax
80103499:	74 22                	je     801034bd <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
8010349b:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
8010349f:	76 0c                	jbe    801034ad <kbdgetc+0x13e>
801034a1:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
801034a5:	77 06                	ja     801034ad <kbdgetc+0x13e>
      c += 'A' - 'a';
801034a7:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
801034ab:	eb 10                	jmp    801034bd <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
801034ad:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
801034b1:	76 0a                	jbe    801034bd <kbdgetc+0x14e>
801034b3:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
801034b7:	77 04                	ja     801034bd <kbdgetc+0x14e>
      c += 'a' - 'A';
801034b9:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
801034bd:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801034c0:	c9                   	leave  
801034c1:	c3                   	ret    

801034c2 <kbdintr>:

void
kbdintr(void)
{
801034c2:	55                   	push   %ebp
801034c3:	89 e5                	mov    %esp,%ebp
801034c5:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
801034c8:	c7 04 24 6f 33 10 80 	movl   $0x8010336f,(%esp)
801034cf:	e8 f4 d2 ff ff       	call   801007c8 <consoleintr>
}
801034d4:	c9                   	leave  
801034d5:	c3                   	ret    

801034d6 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801034d6:	55                   	push   %ebp
801034d7:	89 e5                	mov    %esp,%ebp
801034d9:	83 ec 14             	sub    $0x14,%esp
801034dc:	8b 45 08             	mov    0x8(%ebp),%eax
801034df:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801034e3:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801034e7:	89 c2                	mov    %eax,%edx
801034e9:	ec                   	in     (%dx),%al
801034ea:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801034ed:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801034f1:	c9                   	leave  
801034f2:	c3                   	ret    

801034f3 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801034f3:	55                   	push   %ebp
801034f4:	89 e5                	mov    %esp,%ebp
801034f6:	83 ec 08             	sub    $0x8,%esp
801034f9:	8b 55 08             	mov    0x8(%ebp),%edx
801034fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801034ff:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103503:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103506:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010350a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010350e:	ee                   	out    %al,(%dx)
}
8010350f:	c9                   	leave  
80103510:	c3                   	ret    

80103511 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103511:	55                   	push   %ebp
80103512:	89 e5                	mov    %esp,%ebp
80103514:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103517:	9c                   	pushf  
80103518:	58                   	pop    %eax
80103519:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010351c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010351f:	c9                   	leave  
80103520:	c3                   	ret    

80103521 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103521:	55                   	push   %ebp
80103522:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103524:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103529:	8b 55 08             	mov    0x8(%ebp),%edx
8010352c:	c1 e2 02             	shl    $0x2,%edx
8010352f:	01 c2                	add    %eax,%edx
80103531:	8b 45 0c             	mov    0xc(%ebp),%eax
80103534:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103536:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010353b:	83 c0 20             	add    $0x20,%eax
8010353e:	8b 00                	mov    (%eax),%eax
}
80103540:	5d                   	pop    %ebp
80103541:	c3                   	ret    

80103542 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80103542:	55                   	push   %ebp
80103543:	89 e5                	mov    %esp,%ebp
80103545:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103548:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010354d:	85 c0                	test   %eax,%eax
8010354f:	75 05                	jne    80103556 <lapicinit+0x14>
    return;
80103551:	e9 43 01 00 00       	jmp    80103699 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103556:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
8010355d:	00 
8010355e:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103565:	e8 b7 ff ff ff       	call   80103521 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
8010356a:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103571:	00 
80103572:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103579:	e8 a3 ff ff ff       	call   80103521 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010357e:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103585:	00 
80103586:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010358d:	e8 8f ff ff ff       	call   80103521 <lapicw>
  lapicw(TICR, 10000000); 
80103592:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103599:	00 
8010359a:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
801035a1:	e8 7b ff ff ff       	call   80103521 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
801035a6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035ad:	00 
801035ae:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
801035b5:	e8 67 ff ff ff       	call   80103521 <lapicw>
  lapicw(LINT1, MASKED);
801035ba:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035c1:	00 
801035c2:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801035c9:	e8 53 ff ff ff       	call   80103521 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801035ce:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801035d3:	83 c0 30             	add    $0x30,%eax
801035d6:	8b 00                	mov    (%eax),%eax
801035d8:	c1 e8 10             	shr    $0x10,%eax
801035db:	0f b6 c0             	movzbl %al,%eax
801035de:	83 f8 03             	cmp    $0x3,%eax
801035e1:	76 14                	jbe    801035f7 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
801035e3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035ea:	00 
801035eb:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
801035f2:	e8 2a ff ff ff       	call   80103521 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801035f7:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
801035fe:	00 
801035ff:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103606:	e8 16 ff ff ff       	call   80103521 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010360b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103612:	00 
80103613:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010361a:	e8 02 ff ff ff       	call   80103521 <lapicw>
  lapicw(ESR, 0);
8010361f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103626:	00 
80103627:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010362e:	e8 ee fe ff ff       	call   80103521 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103633:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010363a:	00 
8010363b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103642:	e8 da fe ff ff       	call   80103521 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103647:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010364e:	00 
8010364f:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103656:	e8 c6 fe ff ff       	call   80103521 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010365b:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103662:	00 
80103663:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010366a:	e8 b2 fe ff ff       	call   80103521 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010366f:	90                   	nop
80103670:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103675:	05 00 03 00 00       	add    $0x300,%eax
8010367a:	8b 00                	mov    (%eax),%eax
8010367c:	25 00 10 00 00       	and    $0x1000,%eax
80103681:	85 c0                	test   %eax,%eax
80103683:	75 eb                	jne    80103670 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103685:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010368c:	00 
8010368d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103694:	e8 88 fe ff ff       	call   80103521 <lapicw>
}
80103699:	c9                   	leave  
8010369a:	c3                   	ret    

8010369b <cpunum>:

int
cpunum(void)
{
8010369b:	55                   	push   %ebp
8010369c:	89 e5                	mov    %esp,%ebp
8010369e:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801036a1:	e8 6b fe ff ff       	call   80103511 <readeflags>
801036a6:	25 00 02 00 00       	and    $0x200,%eax
801036ab:	85 c0                	test   %eax,%eax
801036ad:	74 25                	je     801036d4 <cpunum+0x39>
    static int n;
    if(n++ == 0)
801036af:	a1 40 d6 10 80       	mov    0x8010d640,%eax
801036b4:	8d 50 01             	lea    0x1(%eax),%edx
801036b7:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
801036bd:	85 c0                	test   %eax,%eax
801036bf:	75 13                	jne    801036d4 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
801036c1:	8b 45 04             	mov    0x4(%ebp),%eax
801036c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801036c8:	c7 04 24 6c 9e 10 80 	movl   $0x80109e6c,(%esp)
801036cf:	e8 cc cc ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801036d4:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801036d9:	85 c0                	test   %eax,%eax
801036db:	74 0f                	je     801036ec <cpunum+0x51>
    return lapic[ID]>>24;
801036dd:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801036e2:	83 c0 20             	add    $0x20,%eax
801036e5:	8b 00                	mov    (%eax),%eax
801036e7:	c1 e8 18             	shr    $0x18,%eax
801036ea:	eb 05                	jmp    801036f1 <cpunum+0x56>
  return 0;
801036ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
801036f1:	c9                   	leave  
801036f2:	c3                   	ret    

801036f3 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801036f3:	55                   	push   %ebp
801036f4:	89 e5                	mov    %esp,%ebp
801036f6:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801036f9:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801036fe:	85 c0                	test   %eax,%eax
80103700:	74 14                	je     80103716 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103702:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103709:	00 
8010370a:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103711:	e8 0b fe ff ff       	call   80103521 <lapicw>
}
80103716:	c9                   	leave  
80103717:	c3                   	ret    

80103718 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103718:	55                   	push   %ebp
80103719:	89 e5                	mov    %esp,%ebp
}
8010371b:	5d                   	pop    %ebp
8010371c:	c3                   	ret    

8010371d <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010371d:	55                   	push   %ebp
8010371e:	89 e5                	mov    %esp,%ebp
80103720:	83 ec 1c             	sub    $0x1c,%esp
80103723:	8b 45 08             	mov    0x8(%ebp),%eax
80103726:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103729:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103730:	00 
80103731:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103738:	e8 b6 fd ff ff       	call   801034f3 <outb>
  outb(CMOS_PORT+1, 0x0A);
8010373d:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103744:	00 
80103745:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010374c:	e8 a2 fd ff ff       	call   801034f3 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103751:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103758:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010375b:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103760:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103763:	8d 50 02             	lea    0x2(%eax),%edx
80103766:	8b 45 0c             	mov    0xc(%ebp),%eax
80103769:	c1 e8 04             	shr    $0x4,%eax
8010376c:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010376f:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103773:	c1 e0 18             	shl    $0x18,%eax
80103776:	89 44 24 04          	mov    %eax,0x4(%esp)
8010377a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103781:	e8 9b fd ff ff       	call   80103521 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103786:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010378d:	00 
8010378e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103795:	e8 87 fd ff ff       	call   80103521 <lapicw>
  microdelay(200);
8010379a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037a1:	e8 72 ff ff ff       	call   80103718 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801037a6:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801037ad:	00 
801037ae:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037b5:	e8 67 fd ff ff       	call   80103521 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801037ba:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801037c1:	e8 52 ff ff ff       	call   80103718 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801037c6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801037cd:	eb 40                	jmp    8010380f <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801037cf:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801037d3:	c1 e0 18             	shl    $0x18,%eax
801037d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801037da:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801037e1:	e8 3b fd ff ff       	call   80103521 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801037e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801037e9:	c1 e8 0c             	shr    $0xc,%eax
801037ec:	80 cc 06             	or     $0x6,%ah
801037ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801037f3:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037fa:	e8 22 fd ff ff       	call   80103521 <lapicw>
    microdelay(200);
801037ff:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103806:	e8 0d ff ff ff       	call   80103718 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010380b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010380f:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103813:	7e ba                	jle    801037cf <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103815:	c9                   	leave  
80103816:	c3                   	ret    

80103817 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103817:	55                   	push   %ebp
80103818:	89 e5                	mov    %esp,%ebp
8010381a:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010381d:	8b 45 08             	mov    0x8(%ebp),%eax
80103820:	0f b6 c0             	movzbl %al,%eax
80103823:	89 44 24 04          	mov    %eax,0x4(%esp)
80103827:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010382e:	e8 c0 fc ff ff       	call   801034f3 <outb>
  microdelay(200);
80103833:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010383a:	e8 d9 fe ff ff       	call   80103718 <microdelay>

  return inb(CMOS_RETURN);
8010383f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103846:	e8 8b fc ff ff       	call   801034d6 <inb>
8010384b:	0f b6 c0             	movzbl %al,%eax
}
8010384e:	c9                   	leave  
8010384f:	c3                   	ret    

80103850 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103850:	55                   	push   %ebp
80103851:	89 e5                	mov    %esp,%ebp
80103853:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103856:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010385d:	e8 b5 ff ff ff       	call   80103817 <cmos_read>
80103862:	8b 55 08             	mov    0x8(%ebp),%edx
80103865:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103867:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010386e:	e8 a4 ff ff ff       	call   80103817 <cmos_read>
80103873:	8b 55 08             	mov    0x8(%ebp),%edx
80103876:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103879:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103880:	e8 92 ff ff ff       	call   80103817 <cmos_read>
80103885:	8b 55 08             	mov    0x8(%ebp),%edx
80103888:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010388b:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103892:	e8 80 ff ff ff       	call   80103817 <cmos_read>
80103897:	8b 55 08             	mov    0x8(%ebp),%edx
8010389a:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010389d:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801038a4:	e8 6e ff ff ff       	call   80103817 <cmos_read>
801038a9:	8b 55 08             	mov    0x8(%ebp),%edx
801038ac:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801038af:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801038b6:	e8 5c ff ff ff       	call   80103817 <cmos_read>
801038bb:	8b 55 08             	mov    0x8(%ebp),%edx
801038be:	89 42 14             	mov    %eax,0x14(%edx)
}
801038c1:	c9                   	leave  
801038c2:	c3                   	ret    

801038c3 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801038c3:	55                   	push   %ebp
801038c4:	89 e5                	mov    %esp,%ebp
801038c6:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801038c9:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801038d0:	e8 42 ff ff ff       	call   80103817 <cmos_read>
801038d5:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801038d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038db:	83 e0 04             	and    $0x4,%eax
801038de:	85 c0                	test   %eax,%eax
801038e0:	0f 94 c0             	sete   %al
801038e3:	0f b6 c0             	movzbl %al,%eax
801038e6:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801038e9:	8d 45 d8             	lea    -0x28(%ebp),%eax
801038ec:	89 04 24             	mov    %eax,(%esp)
801038ef:	e8 5c ff ff ff       	call   80103850 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801038f4:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801038fb:	e8 17 ff ff ff       	call   80103817 <cmos_read>
80103900:	25 80 00 00 00       	and    $0x80,%eax
80103905:	85 c0                	test   %eax,%eax
80103907:	74 02                	je     8010390b <cmostime+0x48>
        continue;
80103909:	eb 36                	jmp    80103941 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010390b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010390e:	89 04 24             	mov    %eax,(%esp)
80103911:	e8 3a ff ff ff       	call   80103850 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103916:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010391d:	00 
8010391e:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103921:	89 44 24 04          	mov    %eax,0x4(%esp)
80103925:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103928:	89 04 24             	mov    %eax,(%esp)
8010392b:	e8 3c 22 00 00       	call   80105b6c <memcmp>
80103930:	85 c0                	test   %eax,%eax
80103932:	75 0d                	jne    80103941 <cmostime+0x7e>
      break;
80103934:	90                   	nop
  }

  // convert
  if (bcd) {
80103935:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103939:	0f 84 ac 00 00 00    	je     801039eb <cmostime+0x128>
8010393f:	eb 02                	jmp    80103943 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103941:	eb a6                	jmp    801038e9 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103943:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103946:	c1 e8 04             	shr    $0x4,%eax
80103949:	89 c2                	mov    %eax,%edx
8010394b:	89 d0                	mov    %edx,%eax
8010394d:	c1 e0 02             	shl    $0x2,%eax
80103950:	01 d0                	add    %edx,%eax
80103952:	01 c0                	add    %eax,%eax
80103954:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103957:	83 e2 0f             	and    $0xf,%edx
8010395a:	01 d0                	add    %edx,%eax
8010395c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
8010395f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103962:	c1 e8 04             	shr    $0x4,%eax
80103965:	89 c2                	mov    %eax,%edx
80103967:	89 d0                	mov    %edx,%eax
80103969:	c1 e0 02             	shl    $0x2,%eax
8010396c:	01 d0                	add    %edx,%eax
8010396e:	01 c0                	add    %eax,%eax
80103970:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103973:	83 e2 0f             	and    $0xf,%edx
80103976:	01 d0                	add    %edx,%eax
80103978:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010397b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010397e:	c1 e8 04             	shr    $0x4,%eax
80103981:	89 c2                	mov    %eax,%edx
80103983:	89 d0                	mov    %edx,%eax
80103985:	c1 e0 02             	shl    $0x2,%eax
80103988:	01 d0                	add    %edx,%eax
8010398a:	01 c0                	add    %eax,%eax
8010398c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010398f:	83 e2 0f             	and    $0xf,%edx
80103992:	01 d0                	add    %edx,%eax
80103994:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103997:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010399a:	c1 e8 04             	shr    $0x4,%eax
8010399d:	89 c2                	mov    %eax,%edx
8010399f:	89 d0                	mov    %edx,%eax
801039a1:	c1 e0 02             	shl    $0x2,%eax
801039a4:	01 d0                	add    %edx,%eax
801039a6:	01 c0                	add    %eax,%eax
801039a8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801039ab:	83 e2 0f             	and    $0xf,%edx
801039ae:	01 d0                	add    %edx,%eax
801039b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801039b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039b6:	c1 e8 04             	shr    $0x4,%eax
801039b9:	89 c2                	mov    %eax,%edx
801039bb:	89 d0                	mov    %edx,%eax
801039bd:	c1 e0 02             	shl    $0x2,%eax
801039c0:	01 d0                	add    %edx,%eax
801039c2:	01 c0                	add    %eax,%eax
801039c4:	8b 55 e8             	mov    -0x18(%ebp),%edx
801039c7:	83 e2 0f             	and    $0xf,%edx
801039ca:	01 d0                	add    %edx,%eax
801039cc:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801039cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039d2:	c1 e8 04             	shr    $0x4,%eax
801039d5:	89 c2                	mov    %eax,%edx
801039d7:	89 d0                	mov    %edx,%eax
801039d9:	c1 e0 02             	shl    $0x2,%eax
801039dc:	01 d0                	add    %edx,%eax
801039de:	01 c0                	add    %eax,%eax
801039e0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801039e3:	83 e2 0f             	and    $0xf,%edx
801039e6:	01 d0                	add    %edx,%eax
801039e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801039eb:	8b 45 08             	mov    0x8(%ebp),%eax
801039ee:	8b 55 d8             	mov    -0x28(%ebp),%edx
801039f1:	89 10                	mov    %edx,(%eax)
801039f3:	8b 55 dc             	mov    -0x24(%ebp),%edx
801039f6:	89 50 04             	mov    %edx,0x4(%eax)
801039f9:	8b 55 e0             	mov    -0x20(%ebp),%edx
801039fc:	89 50 08             	mov    %edx,0x8(%eax)
801039ff:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103a02:	89 50 0c             	mov    %edx,0xc(%eax)
80103a05:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103a08:	89 50 10             	mov    %edx,0x10(%eax)
80103a0b:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103a0e:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103a11:	8b 45 08             	mov    0x8(%ebp),%eax
80103a14:	8b 40 14             	mov    0x14(%eax),%eax
80103a17:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103a1d:	8b 45 08             	mov    0x8(%ebp),%eax
80103a20:	89 50 14             	mov    %edx,0x14(%eax)
}
80103a23:	c9                   	leave  
80103a24:	c3                   	ret    

80103a25 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103a25:	55                   	push   %ebp
80103a26:	89 e5                	mov    %esp,%ebp
80103a28:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103a2b:	c7 44 24 04 98 9e 10 	movl   $0x80109e98,0x4(%esp)
80103a32:	80 
80103a33:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103a3a:	e8 41 1e 00 00       	call   80105880 <initlock>
  readsb(dev, &sb);
80103a3f:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103a42:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a46:	8b 45 08             	mov    0x8(%ebp),%eax
80103a49:	89 04 24             	mov    %eax,(%esp)
80103a4c:	e8 01 da ff ff       	call   80101452 <readsb>
  log.start = sb.logstart;
80103a51:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a54:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
80103a59:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a5c:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
80103a61:	8b 45 08             	mov    0x8(%ebp),%eax
80103a64:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
80103a69:	e8 9a 01 00 00       	call   80103c08 <recover_from_log>
}
80103a6e:	c9                   	leave  
80103a6f:	c3                   	ret    

80103a70 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103a70:	55                   	push   %ebp
80103a71:	89 e5                	mov    %esp,%ebp
80103a73:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a7d:	e9 8c 00 00 00       	jmp    80103b0e <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103a82:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a8b:	01 d0                	add    %edx,%eax
80103a8d:	83 c0 01             	add    $0x1,%eax
80103a90:	89 c2                	mov    %eax,%edx
80103a92:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a97:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a9b:	89 04 24             	mov    %eax,(%esp)
80103a9e:	e8 03 c7 ff ff       	call   801001a6 <bread>
80103aa3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103aa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aa9:	83 c0 10             	add    $0x10,%eax
80103aac:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103ab3:	89 c2                	mov    %eax,%edx
80103ab5:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103aba:	89 54 24 04          	mov    %edx,0x4(%esp)
80103abe:	89 04 24             	mov    %eax,(%esp)
80103ac1:	e8 e0 c6 ff ff       	call   801001a6 <bread>
80103ac6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103ac9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103acc:	8d 50 18             	lea    0x18(%eax),%edx
80103acf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ad2:	83 c0 18             	add    $0x18,%eax
80103ad5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103adc:	00 
80103add:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ae1:	89 04 24             	mov    %eax,(%esp)
80103ae4:	e8 db 20 00 00       	call   80105bc4 <memmove>
    bwrite(dbuf);  // write dst to disk
80103ae9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aec:	89 04 24             	mov    %eax,(%esp)
80103aef:	e8 e9 c6 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103af4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103af7:	89 04 24             	mov    %eax,(%esp)
80103afa:	e8 18 c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103aff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b02:	89 04 24             	mov    %eax,(%esp)
80103b05:	e8 0d c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103b0a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b0e:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b13:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b16:	0f 8f 66 ff ff ff    	jg     80103a82 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103b1c:	c9                   	leave  
80103b1d:	c3                   	ret    

80103b1e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103b1e:	55                   	push   %ebp
80103b1f:	89 e5                	mov    %esp,%ebp
80103b21:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b24:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b29:	89 c2                	mov    %eax,%edx
80103b2b:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b30:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b34:	89 04 24             	mov    %eax,(%esp)
80103b37:	e8 6a c6 ff ff       	call   801001a6 <bread>
80103b3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103b3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b42:	83 c0 18             	add    $0x18,%eax
80103b45:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103b48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b4b:	8b 00                	mov    (%eax),%eax
80103b4d:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103b52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b59:	eb 1b                	jmp    80103b76 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103b5b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b61:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103b65:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b68:	83 c2 10             	add    $0x10,%edx
80103b6b:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103b72:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b76:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b7b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b7e:	7f db                	jg     80103b5b <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103b80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b83:	89 04 24             	mov    %eax,(%esp)
80103b86:	e8 8c c6 ff ff       	call   80100217 <brelse>
}
80103b8b:	c9                   	leave  
80103b8c:	c3                   	ret    

80103b8d <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103b8d:	55                   	push   %ebp
80103b8e:	89 e5                	mov    %esp,%ebp
80103b90:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b93:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b98:	89 c2                	mov    %eax,%edx
80103b9a:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ba3:	89 04 24             	mov    %eax,(%esp)
80103ba6:	e8 fb c5 ff ff       	call   801001a6 <bread>
80103bab:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103bae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bb1:	83 c0 18             	add    $0x18,%eax
80103bb4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103bb7:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103bbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bc0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103bc2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103bc9:	eb 1b                	jmp    80103be6 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bce:	83 c0 10             	add    $0x10,%eax
80103bd1:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103bd8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bdb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103bde:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103be2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103be6:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103beb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bee:	7f db                	jg     80103bcb <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bf3:	89 04 24             	mov    %eax,(%esp)
80103bf6:	e8 e2 c5 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103bfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfe:	89 04 24             	mov    %eax,(%esp)
80103c01:	e8 11 c6 ff ff       	call   80100217 <brelse>
}
80103c06:	c9                   	leave  
80103c07:	c3                   	ret    

80103c08 <recover_from_log>:

static void
recover_from_log(void)
{
80103c08:	55                   	push   %ebp
80103c09:	89 e5                	mov    %esp,%ebp
80103c0b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103c0e:	e8 0b ff ff ff       	call   80103b1e <read_head>
  install_trans(); // if committed, copy from log to disk
80103c13:	e8 58 fe ff ff       	call   80103a70 <install_trans>
  log.lh.n = 0;
80103c18:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103c1f:	00 00 00 
  write_head(); // clear the log
80103c22:	e8 66 ff ff ff       	call   80103b8d <write_head>
}
80103c27:	c9                   	leave  
80103c28:	c3                   	ret    

80103c29 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103c29:	55                   	push   %ebp
80103c2a:	89 e5                	mov    %esp,%ebp
80103c2c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103c2f:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c36:	e8 66 1c 00 00       	call   801058a1 <acquire>
  while(1){
    if(log.committing){
80103c3b:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c40:	85 c0                	test   %eax,%eax
80103c42:	74 16                	je     80103c5a <begin_op+0x31>
      sleep(&log, &log.lock);
80103c44:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103c4b:	80 
80103c4c:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c53:	e8 dc 18 00 00       	call   80105534 <sleep>
80103c58:	eb 4f                	jmp    80103ca9 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103c5a:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103c60:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c65:	8d 50 01             	lea    0x1(%eax),%edx
80103c68:	89 d0                	mov    %edx,%eax
80103c6a:	c1 e0 02             	shl    $0x2,%eax
80103c6d:	01 d0                	add    %edx,%eax
80103c6f:	01 c0                	add    %eax,%eax
80103c71:	01 c8                	add    %ecx,%eax
80103c73:	83 f8 1e             	cmp    $0x1e,%eax
80103c76:	7e 16                	jle    80103c8e <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103c78:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103c7f:	80 
80103c80:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c87:	e8 a8 18 00 00       	call   80105534 <sleep>
80103c8c:	eb 1b                	jmp    80103ca9 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103c8e:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c93:	83 c0 01             	add    $0x1,%eax
80103c96:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c9b:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ca2:	e8 5c 1c 00 00       	call   80105903 <release>
      break;
80103ca7:	eb 02                	jmp    80103cab <begin_op+0x82>
    }
  }
80103ca9:	eb 90                	jmp    80103c3b <begin_op+0x12>
}
80103cab:	c9                   	leave  
80103cac:	c3                   	ret    

80103cad <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103cad:	55                   	push   %ebp
80103cae:	89 e5                	mov    %esp,%ebp
80103cb0:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103cb3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103cba:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cc1:	e8 db 1b 00 00       	call   801058a1 <acquire>
  log.outstanding -= 1;
80103cc6:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103ccb:	83 e8 01             	sub    $0x1,%eax
80103cce:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103cd3:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103cd8:	85 c0                	test   %eax,%eax
80103cda:	74 0c                	je     80103ce8 <end_op+0x3b>
    panic("log.committing");
80103cdc:	c7 04 24 9c 9e 10 80 	movl   $0x80109e9c,(%esp)
80103ce3:	e8 52 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103ce8:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103ced:	85 c0                	test   %eax,%eax
80103cef:	75 13                	jne    80103d04 <end_op+0x57>
    do_commit = 1;
80103cf1:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103cf8:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103cff:	00 00 00 
80103d02:	eb 0c                	jmp    80103d10 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103d04:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103d0b:	e8 00 19 00 00       	call   80105610 <wakeup>
  }
  release(&log.lock);
80103d10:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103d17:	e8 e7 1b 00 00       	call   80105903 <release>

  if(do_commit){
80103d1c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d20:	74 33                	je     80103d55 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103d22:	e8 de 00 00 00       	call   80103e05 <commit>
    acquire(&log.lock);
80103d27:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103d2e:	e8 6e 1b 00 00       	call   801058a1 <acquire>
    log.committing = 0;
80103d33:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103d3a:	00 00 00 
    wakeup(&log);
80103d3d:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103d44:	e8 c7 18 00 00       	call   80105610 <wakeup>
    release(&log.lock);
80103d49:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103d50:	e8 ae 1b 00 00       	call   80105903 <release>
  }
}
80103d55:	c9                   	leave  
80103d56:	c3                   	ret    

80103d57 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103d57:	55                   	push   %ebp
80103d58:	89 e5                	mov    %esp,%ebp
80103d5a:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d5d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d64:	e9 8c 00 00 00       	jmp    80103df5 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103d69:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103d6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d72:	01 d0                	add    %edx,%eax
80103d74:	83 c0 01             	add    $0x1,%eax
80103d77:	89 c2                	mov    %eax,%edx
80103d79:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d82:	89 04 24             	mov    %eax,(%esp)
80103d85:	e8 1c c4 ff ff       	call   801001a6 <bread>
80103d8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103d8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d90:	83 c0 10             	add    $0x10,%eax
80103d93:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d9a:	89 c2                	mov    %eax,%edx
80103d9c:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103da1:	89 54 24 04          	mov    %edx,0x4(%esp)
80103da5:	89 04 24             	mov    %eax,(%esp)
80103da8:	e8 f9 c3 ff ff       	call   801001a6 <bread>
80103dad:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103db0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103db3:	8d 50 18             	lea    0x18(%eax),%edx
80103db6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103db9:	83 c0 18             	add    $0x18,%eax
80103dbc:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103dc3:	00 
80103dc4:	89 54 24 04          	mov    %edx,0x4(%esp)
80103dc8:	89 04 24             	mov    %eax,(%esp)
80103dcb:	e8 f4 1d 00 00       	call   80105bc4 <memmove>
    bwrite(to);  // write the log
80103dd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dd3:	89 04 24             	mov    %eax,(%esp)
80103dd6:	e8 02 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103ddb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103dde:	89 04 24             	mov    %eax,(%esp)
80103de1:	e8 31 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103de6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103de9:	89 04 24             	mov    %eax,(%esp)
80103dec:	e8 26 c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103df1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103df5:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dfa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103dfd:	0f 8f 66 ff ff ff    	jg     80103d69 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103e03:	c9                   	leave  
80103e04:	c3                   	ret    

80103e05 <commit>:

static void
commit()
{
80103e05:	55                   	push   %ebp
80103e06:	89 e5                	mov    %esp,%ebp
80103e08:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103e0b:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e10:	85 c0                	test   %eax,%eax
80103e12:	7e 1e                	jle    80103e32 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103e14:	e8 3e ff ff ff       	call   80103d57 <write_log>
    write_head();    // Write header to disk -- the real commit
80103e19:	e8 6f fd ff ff       	call   80103b8d <write_head>
    install_trans(); // Now install writes to home locations
80103e1e:	e8 4d fc ff ff       	call   80103a70 <install_trans>
    log.lh.n = 0; 
80103e23:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103e2a:	00 00 00 
    write_head();    // Erase the transaction from the log
80103e2d:	e8 5b fd ff ff       	call   80103b8d <write_head>
  }
}
80103e32:	c9                   	leave  
80103e33:	c3                   	ret    

80103e34 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103e34:	55                   	push   %ebp
80103e35:	89 e5                	mov    %esp,%ebp
80103e37:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103e3a:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e3f:	83 f8 1d             	cmp    $0x1d,%eax
80103e42:	7f 12                	jg     80103e56 <log_write+0x22>
80103e44:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e49:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103e4f:	83 ea 01             	sub    $0x1,%edx
80103e52:	39 d0                	cmp    %edx,%eax
80103e54:	7c 0c                	jl     80103e62 <log_write+0x2e>
    panic("too big a transaction");
80103e56:	c7 04 24 ab 9e 10 80 	movl   $0x80109eab,(%esp)
80103e5d:	e8 d8 c6 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103e62:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103e67:	85 c0                	test   %eax,%eax
80103e69:	7f 0c                	jg     80103e77 <log_write+0x43>
    panic("log_write outside of trans");
80103e6b:	c7 04 24 c1 9e 10 80 	movl   $0x80109ec1,(%esp)
80103e72:	e8 c3 c6 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103e77:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e7e:	e8 1e 1a 00 00       	call   801058a1 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103e83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e8a:	eb 1f                	jmp    80103eab <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103e8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e8f:	83 c0 10             	add    $0x10,%eax
80103e92:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e99:	89 c2                	mov    %eax,%edx
80103e9b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9e:	8b 40 08             	mov    0x8(%eax),%eax
80103ea1:	39 c2                	cmp    %eax,%edx
80103ea3:	75 02                	jne    80103ea7 <log_write+0x73>
      break;
80103ea5:	eb 0e                	jmp    80103eb5 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103ea7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103eab:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103eb0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103eb3:	7f d7                	jg     80103e8c <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103eb5:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb8:	8b 40 08             	mov    0x8(%eax),%eax
80103ebb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ebe:	83 c2 10             	add    $0x10,%edx
80103ec1:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103ec8:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103ecd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ed0:	75 0d                	jne    80103edf <log_write+0xab>
    log.lh.n++;
80103ed2:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103ed7:	83 c0 01             	add    $0x1,%eax
80103eda:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103edf:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee2:	8b 00                	mov    (%eax),%eax
80103ee4:	83 c8 04             	or     $0x4,%eax
80103ee7:	89 c2                	mov    %eax,%edx
80103ee9:	8b 45 08             	mov    0x8(%ebp),%eax
80103eec:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103eee:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ef5:	e8 09 1a 00 00       	call   80105903 <release>
}
80103efa:	c9                   	leave  
80103efb:	c3                   	ret    

80103efc <v2p>:
80103efc:	55                   	push   %ebp
80103efd:	89 e5                	mov    %esp,%ebp
80103eff:	8b 45 08             	mov    0x8(%ebp),%eax
80103f02:	05 00 00 00 80       	add    $0x80000000,%eax
80103f07:	5d                   	pop    %ebp
80103f08:	c3                   	ret    

80103f09 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103f09:	55                   	push   %ebp
80103f0a:	89 e5                	mov    %esp,%ebp
80103f0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f0f:	05 00 00 00 80       	add    $0x80000000,%eax
80103f14:	5d                   	pop    %ebp
80103f15:	c3                   	ret    

80103f16 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103f16:	55                   	push   %ebp
80103f17:	89 e5                	mov    %esp,%ebp
80103f19:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103f1c:	8b 55 08             	mov    0x8(%ebp),%edx
80103f1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f22:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f25:	f0 87 02             	lock xchg %eax,(%edx)
80103f28:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103f2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103f2e:	c9                   	leave  
80103f2f:	c3                   	ret    

80103f30 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103f30:	55                   	push   %ebp
80103f31:	89 e5                	mov    %esp,%ebp
80103f33:	83 e4 f0             	and    $0xfffffff0,%esp
80103f36:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103f39:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103f40:	80 
80103f41:	c7 04 24 5c 0e 12 80 	movl   $0x80120e5c,(%esp)
80103f48:	e8 1b f2 ff ff       	call   80103168 <kinit1>
  kvmalloc();      // kernel page table
80103f4d:	e8 0e 48 00 00       	call   80108760 <kvmalloc>
  mpinit();        // collect info about this machine
80103f52:	e8 41 04 00 00       	call   80104398 <mpinit>
  lapicinit();
80103f57:	e8 e6 f5 ff ff       	call   80103542 <lapicinit>
  seginit();       // set up segments
80103f5c:	e8 92 41 00 00       	call   801080f3 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103f61:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f67:	0f b6 00             	movzbl (%eax),%eax
80103f6a:	0f b6 c0             	movzbl %al,%eax
80103f6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f71:	c7 04 24 dc 9e 10 80 	movl   $0x80109edc,(%esp)
80103f78:	e8 23 c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103f7d:	e8 74 06 00 00       	call   801045f6 <picinit>
  ioapicinit();    // another interrupt controller
80103f82:	e8 d7 f0 ff ff       	call   8010305e <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103f87:	e8 24 cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103f8c:	e8 b1 34 00 00       	call   80107442 <uartinit>
  pinit();         // process table
80103f91:	e8 84 0b 00 00       	call   80104b1a <pinit>
  tvinit();        // trap vectors
80103f96:	e8 b3 2f 00 00       	call   80106f4e <tvinit>
  binit();         // buffer cache
80103f9b:	e8 94 c0 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103fa0:	e8 c6 d0 ff ff       	call   8010106b <fileinit>
  ideinit();       // disk
80103fa5:	e8 e6 ec ff ff       	call   80102c90 <ideinit>
  if(!ismp)
80103faa:	a1 44 43 11 80       	mov    0x80114344,%eax
80103faf:	85 c0                	test   %eax,%eax
80103fb1:	75 05                	jne    80103fb8 <main+0x88>
    timerinit();   // uniprocessor timer
80103fb3:	e8 e1 2e 00 00       	call   80106e99 <timerinit>
  startothers();   // start other processors
80103fb8:	e8 7f 00 00 00       	call   8010403c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103fbd:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103fc4:	8e 
80103fc5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103fcc:	e8 cf f1 ff ff       	call   801031a0 <kinit2>
  userinit();      // first user process
80103fd1:	e8 62 0c 00 00       	call   80104c38 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103fd6:	e8 1a 00 00 00       	call   80103ff5 <mpmain>

80103fdb <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103fdb:	55                   	push   %ebp
80103fdc:	89 e5                	mov    %esp,%ebp
80103fde:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103fe1:	e8 91 47 00 00       	call   80108777 <switchkvm>
  seginit();
80103fe6:	e8 08 41 00 00       	call   801080f3 <seginit>
  lapicinit();
80103feb:	e8 52 f5 ff ff       	call   80103542 <lapicinit>
  mpmain();
80103ff0:	e8 00 00 00 00       	call   80103ff5 <mpmain>

80103ff5 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103ff5:	55                   	push   %ebp
80103ff6:	89 e5                	mov    %esp,%ebp
80103ff8:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103ffb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104001:	0f b6 00             	movzbl (%eax),%eax
80104004:	0f b6 c0             	movzbl %al,%eax
80104007:	89 44 24 04          	mov    %eax,0x4(%esp)
8010400b:	c7 04 24 f3 9e 10 80 	movl   $0x80109ef3,(%esp)
80104012:	e8 89 c3 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80104017:	e8 a6 30 00 00       	call   801070c2 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010401c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104022:	05 a8 00 00 00       	add    $0xa8,%eax
80104027:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010402e:	00 
8010402f:	89 04 24             	mov    %eax,(%esp)
80104032:	e8 df fe ff ff       	call   80103f16 <xchg>
  scheduler();     // start running processes
80104037:	e8 3a 13 00 00       	call   80105376 <scheduler>

8010403c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010403c:	55                   	push   %ebp
8010403d:	89 e5                	mov    %esp,%ebp
8010403f:	53                   	push   %ebx
80104040:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80104043:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010404a:	e8 ba fe ff ff       	call   80103f09 <p2v>
8010404f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80104052:	b8 8a 00 00 00       	mov    $0x8a,%eax
80104057:	89 44 24 08          	mov    %eax,0x8(%esp)
8010405b:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80104062:	80 
80104063:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104066:	89 04 24             	mov    %eax,(%esp)
80104069:	e8 56 1b 00 00       	call   80105bc4 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010406e:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80104075:	e9 85 00 00 00       	jmp    801040ff <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
8010407a:	e8 1c f6 ff ff       	call   8010369b <cpunum>
8010407f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104085:	05 60 43 11 80       	add    $0x80114360,%eax
8010408a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010408d:	75 02                	jne    80104091 <startothers+0x55>
      continue;
8010408f:	eb 67                	jmp    801040f8 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104091:	e8 29 f2 ff ff       	call   801032bf <kalloc>
80104096:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104099:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010409c:	83 e8 04             	sub    $0x4,%eax
8010409f:	8b 55 ec             	mov    -0x14(%ebp),%edx
801040a2:	81 c2 00 10 00 00    	add    $0x1000,%edx
801040a8:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801040aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040ad:	83 e8 08             	sub    $0x8,%eax
801040b0:	c7 00 db 3f 10 80    	movl   $0x80103fdb,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801040b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040b9:	8d 58 f4             	lea    -0xc(%eax),%ebx
801040bc:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
801040c3:	e8 34 fe ff ff       	call   80103efc <v2p>
801040c8:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801040ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040cd:	89 04 24             	mov    %eax,(%esp)
801040d0:	e8 27 fe ff ff       	call   80103efc <v2p>
801040d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040d8:	0f b6 12             	movzbl (%edx),%edx
801040db:	0f b6 d2             	movzbl %dl,%edx
801040de:	89 44 24 04          	mov    %eax,0x4(%esp)
801040e2:	89 14 24             	mov    %edx,(%esp)
801040e5:	e8 33 f6 ff ff       	call   8010371d <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801040ea:	90                   	nop
801040eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040ee:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801040f4:	85 c0                	test   %eax,%eax
801040f6:	74 f3                	je     801040eb <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801040f8:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801040ff:	a1 40 49 11 80       	mov    0x80114940,%eax
80104104:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010410a:	05 60 43 11 80       	add    $0x80114360,%eax
8010410f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104112:	0f 87 62 ff ff ff    	ja     8010407a <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104118:	83 c4 24             	add    $0x24,%esp
8010411b:	5b                   	pop    %ebx
8010411c:	5d                   	pop    %ebp
8010411d:	c3                   	ret    

8010411e <p2v>:
8010411e:	55                   	push   %ebp
8010411f:	89 e5                	mov    %esp,%ebp
80104121:	8b 45 08             	mov    0x8(%ebp),%eax
80104124:	05 00 00 00 80       	add    $0x80000000,%eax
80104129:	5d                   	pop    %ebp
8010412a:	c3                   	ret    

8010412b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010412b:	55                   	push   %ebp
8010412c:	89 e5                	mov    %esp,%ebp
8010412e:	83 ec 14             	sub    $0x14,%esp
80104131:	8b 45 08             	mov    0x8(%ebp),%eax
80104134:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80104138:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010413c:	89 c2                	mov    %eax,%edx
8010413e:	ec                   	in     (%dx),%al
8010413f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80104142:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80104146:	c9                   	leave  
80104147:	c3                   	ret    

80104148 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104148:	55                   	push   %ebp
80104149:	89 e5                	mov    %esp,%ebp
8010414b:	83 ec 08             	sub    $0x8,%esp
8010414e:	8b 55 08             	mov    0x8(%ebp),%edx
80104151:	8b 45 0c             	mov    0xc(%ebp),%eax
80104154:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104158:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010415b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010415f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104163:	ee                   	out    %al,(%dx)
}
80104164:	c9                   	leave  
80104165:	c3                   	ret    

80104166 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104166:	55                   	push   %ebp
80104167:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104169:	a1 44 d6 10 80       	mov    0x8010d644,%eax
8010416e:	89 c2                	mov    %eax,%edx
80104170:	b8 60 43 11 80       	mov    $0x80114360,%eax
80104175:	29 c2                	sub    %eax,%edx
80104177:	89 d0                	mov    %edx,%eax
80104179:	c1 f8 02             	sar    $0x2,%eax
8010417c:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104182:	5d                   	pop    %ebp
80104183:	c3                   	ret    

80104184 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104184:	55                   	push   %ebp
80104185:	89 e5                	mov    %esp,%ebp
80104187:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010418a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104191:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104198:	eb 15                	jmp    801041af <sum+0x2b>
    sum += addr[i];
8010419a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010419d:	8b 45 08             	mov    0x8(%ebp),%eax
801041a0:	01 d0                	add    %edx,%eax
801041a2:	0f b6 00             	movzbl (%eax),%eax
801041a5:	0f b6 c0             	movzbl %al,%eax
801041a8:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801041ab:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801041af:	8b 45 fc             	mov    -0x4(%ebp),%eax
801041b2:	3b 45 0c             	cmp    0xc(%ebp),%eax
801041b5:	7c e3                	jl     8010419a <sum+0x16>
    sum += addr[i];
  return sum;
801041b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801041ba:	c9                   	leave  
801041bb:	c3                   	ret    

801041bc <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801041bc:	55                   	push   %ebp
801041bd:	89 e5                	mov    %esp,%ebp
801041bf:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801041c2:	8b 45 08             	mov    0x8(%ebp),%eax
801041c5:	89 04 24             	mov    %eax,(%esp)
801041c8:	e8 51 ff ff ff       	call   8010411e <p2v>
801041cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801041d0:	8b 55 0c             	mov    0xc(%ebp),%edx
801041d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041d6:	01 d0                	add    %edx,%eax
801041d8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801041db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041de:	89 45 f4             	mov    %eax,-0xc(%ebp)
801041e1:	eb 3f                	jmp    80104222 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801041e3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801041ea:	00 
801041eb:	c7 44 24 04 04 9f 10 	movl   $0x80109f04,0x4(%esp)
801041f2:	80 
801041f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f6:	89 04 24             	mov    %eax,(%esp)
801041f9:	e8 6e 19 00 00       	call   80105b6c <memcmp>
801041fe:	85 c0                	test   %eax,%eax
80104200:	75 1c                	jne    8010421e <mpsearch1+0x62>
80104202:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104209:	00 
8010420a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420d:	89 04 24             	mov    %eax,(%esp)
80104210:	e8 6f ff ff ff       	call   80104184 <sum>
80104215:	84 c0                	test   %al,%al
80104217:	75 05                	jne    8010421e <mpsearch1+0x62>
      return (struct mp*)p;
80104219:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421c:	eb 11                	jmp    8010422f <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010421e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104222:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104225:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104228:	72 b9                	jb     801041e3 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010422a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010422f:	c9                   	leave  
80104230:	c3                   	ret    

80104231 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80104231:	55                   	push   %ebp
80104232:	89 e5                	mov    %esp,%ebp
80104234:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80104237:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010423e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104241:	83 c0 0f             	add    $0xf,%eax
80104244:	0f b6 00             	movzbl (%eax),%eax
80104247:	0f b6 c0             	movzbl %al,%eax
8010424a:	c1 e0 08             	shl    $0x8,%eax
8010424d:	89 c2                	mov    %eax,%edx
8010424f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104252:	83 c0 0e             	add    $0xe,%eax
80104255:	0f b6 00             	movzbl (%eax),%eax
80104258:	0f b6 c0             	movzbl %al,%eax
8010425b:	09 d0                	or     %edx,%eax
8010425d:	c1 e0 04             	shl    $0x4,%eax
80104260:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104263:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104267:	74 21                	je     8010428a <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104269:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104270:	00 
80104271:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104274:	89 04 24             	mov    %eax,(%esp)
80104277:	e8 40 ff ff ff       	call   801041bc <mpsearch1>
8010427c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010427f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104283:	74 50                	je     801042d5 <mpsearch+0xa4>
      return mp;
80104285:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104288:	eb 5f                	jmp    801042e9 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010428a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428d:	83 c0 14             	add    $0x14,%eax
80104290:	0f b6 00             	movzbl (%eax),%eax
80104293:	0f b6 c0             	movzbl %al,%eax
80104296:	c1 e0 08             	shl    $0x8,%eax
80104299:	89 c2                	mov    %eax,%edx
8010429b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429e:	83 c0 13             	add    $0x13,%eax
801042a1:	0f b6 00             	movzbl (%eax),%eax
801042a4:	0f b6 c0             	movzbl %al,%eax
801042a7:	09 d0                	or     %edx,%eax
801042a9:	c1 e0 0a             	shl    $0xa,%eax
801042ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801042af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042b2:	2d 00 04 00 00       	sub    $0x400,%eax
801042b7:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801042be:	00 
801042bf:	89 04 24             	mov    %eax,(%esp)
801042c2:	e8 f5 fe ff ff       	call   801041bc <mpsearch1>
801042c7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801042ca:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801042ce:	74 05                	je     801042d5 <mpsearch+0xa4>
      return mp;
801042d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042d3:	eb 14                	jmp    801042e9 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801042d5:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801042dc:	00 
801042dd:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801042e4:	e8 d3 fe ff ff       	call   801041bc <mpsearch1>
}
801042e9:	c9                   	leave  
801042ea:	c3                   	ret    

801042eb <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801042eb:	55                   	push   %ebp
801042ec:	89 e5                	mov    %esp,%ebp
801042ee:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801042f1:	e8 3b ff ff ff       	call   80104231 <mpsearch>
801042f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801042f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801042fd:	74 0a                	je     80104309 <mpconfig+0x1e>
801042ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104302:	8b 40 04             	mov    0x4(%eax),%eax
80104305:	85 c0                	test   %eax,%eax
80104307:	75 0a                	jne    80104313 <mpconfig+0x28>
    return 0;
80104309:	b8 00 00 00 00       	mov    $0x0,%eax
8010430e:	e9 83 00 00 00       	jmp    80104396 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104313:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104316:	8b 40 04             	mov    0x4(%eax),%eax
80104319:	89 04 24             	mov    %eax,(%esp)
8010431c:	e8 fd fd ff ff       	call   8010411e <p2v>
80104321:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104324:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010432b:	00 
8010432c:	c7 44 24 04 09 9f 10 	movl   $0x80109f09,0x4(%esp)
80104333:	80 
80104334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104337:	89 04 24             	mov    %eax,(%esp)
8010433a:	e8 2d 18 00 00       	call   80105b6c <memcmp>
8010433f:	85 c0                	test   %eax,%eax
80104341:	74 07                	je     8010434a <mpconfig+0x5f>
    return 0;
80104343:	b8 00 00 00 00       	mov    $0x0,%eax
80104348:	eb 4c                	jmp    80104396 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010434a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104351:	3c 01                	cmp    $0x1,%al
80104353:	74 12                	je     80104367 <mpconfig+0x7c>
80104355:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104358:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010435c:	3c 04                	cmp    $0x4,%al
8010435e:	74 07                	je     80104367 <mpconfig+0x7c>
    return 0;
80104360:	b8 00 00 00 00       	mov    $0x0,%eax
80104365:	eb 2f                	jmp    80104396 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104367:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010436a:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010436e:	0f b7 c0             	movzwl %ax,%eax
80104371:	89 44 24 04          	mov    %eax,0x4(%esp)
80104375:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104378:	89 04 24             	mov    %eax,(%esp)
8010437b:	e8 04 fe ff ff       	call   80104184 <sum>
80104380:	84 c0                	test   %al,%al
80104382:	74 07                	je     8010438b <mpconfig+0xa0>
    return 0;
80104384:	b8 00 00 00 00       	mov    $0x0,%eax
80104389:	eb 0b                	jmp    80104396 <mpconfig+0xab>
  *pmp = mp;
8010438b:	8b 45 08             	mov    0x8(%ebp),%eax
8010438e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104391:	89 10                	mov    %edx,(%eax)
  return conf;
80104393:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104396:	c9                   	leave  
80104397:	c3                   	ret    

80104398 <mpinit>:

void
mpinit(void)
{
80104398:	55                   	push   %ebp
80104399:	89 e5                	mov    %esp,%ebp
8010439b:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010439e:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
801043a5:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
801043a8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801043ab:	89 04 24             	mov    %eax,(%esp)
801043ae:	e8 38 ff ff ff       	call   801042eb <mpconfig>
801043b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801043b6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801043ba:	75 05                	jne    801043c1 <mpinit+0x29>
    return;
801043bc:	e9 9c 01 00 00       	jmp    8010455d <mpinit+0x1c5>
  ismp = 1;
801043c1:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
801043c8:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801043cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043ce:	8b 40 24             	mov    0x24(%eax),%eax
801043d1:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801043d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043d9:	83 c0 2c             	add    $0x2c,%eax
801043dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801043df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043e2:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801043e6:	0f b7 d0             	movzwl %ax,%edx
801043e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043ec:	01 d0                	add    %edx,%eax
801043ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
801043f1:	e9 f4 00 00 00       	jmp    801044ea <mpinit+0x152>
    switch(*p){
801043f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043f9:	0f b6 00             	movzbl (%eax),%eax
801043fc:	0f b6 c0             	movzbl %al,%eax
801043ff:	83 f8 04             	cmp    $0x4,%eax
80104402:	0f 87 bf 00 00 00    	ja     801044c7 <mpinit+0x12f>
80104408:	8b 04 85 4c 9f 10 80 	mov    -0x7fef60b4(,%eax,4),%eax
8010440f:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104414:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104417:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010441a:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010441e:	0f b6 d0             	movzbl %al,%edx
80104421:	a1 40 49 11 80       	mov    0x80114940,%eax
80104426:	39 c2                	cmp    %eax,%edx
80104428:	74 2d                	je     80104457 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010442a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010442d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104431:	0f b6 d0             	movzbl %al,%edx
80104434:	a1 40 49 11 80       	mov    0x80114940,%eax
80104439:	89 54 24 08          	mov    %edx,0x8(%esp)
8010443d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104441:	c7 04 24 0e 9f 10 80 	movl   $0x80109f0e,(%esp)
80104448:	e8 53 bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
8010444d:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104454:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104457:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010445a:	0f b6 40 03          	movzbl 0x3(%eax),%eax
8010445e:	0f b6 c0             	movzbl %al,%eax
80104461:	83 e0 02             	and    $0x2,%eax
80104464:	85 c0                	test   %eax,%eax
80104466:	74 15                	je     8010447d <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80104468:	a1 40 49 11 80       	mov    0x80114940,%eax
8010446d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104473:	05 60 43 11 80       	add    $0x80114360,%eax
80104478:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
8010447d:	8b 15 40 49 11 80    	mov    0x80114940,%edx
80104483:	a1 40 49 11 80       	mov    0x80114940,%eax
80104488:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
8010448e:	81 c2 60 43 11 80    	add    $0x80114360,%edx
80104494:	88 02                	mov    %al,(%edx)
      ncpu++;
80104496:	a1 40 49 11 80       	mov    0x80114940,%eax
8010449b:	83 c0 01             	add    $0x1,%eax
8010449e:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
801044a3:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801044a7:	eb 41                	jmp    801044ea <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801044a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801044af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801044b2:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801044b6:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
801044bb:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801044bf:	eb 29                	jmp    801044ea <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801044c1:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801044c5:	eb 23                	jmp    801044ea <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801044c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ca:	0f b6 00             	movzbl (%eax),%eax
801044cd:	0f b6 c0             	movzbl %al,%eax
801044d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801044d4:	c7 04 24 2c 9f 10 80 	movl   $0x80109f2c,(%esp)
801044db:	e8 c0 be ff ff       	call   801003a0 <cprintf>
      ismp = 0;
801044e0:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801044e7:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801044ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ed:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801044f0:	0f 82 00 ff ff ff    	jb     801043f6 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801044f6:	a1 44 43 11 80       	mov    0x80114344,%eax
801044fb:	85 c0                	test   %eax,%eax
801044fd:	75 1d                	jne    8010451c <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801044ff:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
80104506:	00 00 00 
    lapic = 0;
80104509:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
80104510:	00 00 00 
    ioapicid = 0;
80104513:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
8010451a:	eb 41                	jmp    8010455d <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010451c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010451f:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104523:	84 c0                	test   %al,%al
80104525:	74 36                	je     8010455d <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104527:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
8010452e:	00 
8010452f:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104536:	e8 0d fc ff ff       	call   80104148 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010453b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104542:	e8 e4 fb ff ff       	call   8010412b <inb>
80104547:	83 c8 01             	or     $0x1,%eax
8010454a:	0f b6 c0             	movzbl %al,%eax
8010454d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104551:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104558:	e8 eb fb ff ff       	call   80104148 <outb>
  }
}
8010455d:	c9                   	leave  
8010455e:	c3                   	ret    

8010455f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010455f:	55                   	push   %ebp
80104560:	89 e5                	mov    %esp,%ebp
80104562:	83 ec 08             	sub    $0x8,%esp
80104565:	8b 55 08             	mov    0x8(%ebp),%edx
80104568:	8b 45 0c             	mov    0xc(%ebp),%eax
8010456b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010456f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104572:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104576:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010457a:	ee                   	out    %al,(%dx)
}
8010457b:	c9                   	leave  
8010457c:	c3                   	ret    

8010457d <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010457d:	55                   	push   %ebp
8010457e:	89 e5                	mov    %esp,%ebp
80104580:	83 ec 0c             	sub    $0xc,%esp
80104583:	8b 45 08             	mov    0x8(%ebp),%eax
80104586:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010458a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010458e:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
80104594:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104598:	0f b6 c0             	movzbl %al,%eax
8010459b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010459f:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045a6:	e8 b4 ff ff ff       	call   8010455f <outb>
  outb(IO_PIC2+1, mask >> 8);
801045ab:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801045af:	66 c1 e8 08          	shr    $0x8,%ax
801045b3:	0f b6 c0             	movzbl %al,%eax
801045b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801045ba:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045c1:	e8 99 ff ff ff       	call   8010455f <outb>
}
801045c6:	c9                   	leave  
801045c7:	c3                   	ret    

801045c8 <picenable>:

void
picenable(int irq)
{
801045c8:	55                   	push   %ebp
801045c9:	89 e5                	mov    %esp,%ebp
801045cb:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
801045ce:	8b 45 08             	mov    0x8(%ebp),%eax
801045d1:	ba 01 00 00 00       	mov    $0x1,%edx
801045d6:	89 c1                	mov    %eax,%ecx
801045d8:	d3 e2                	shl    %cl,%edx
801045da:	89 d0                	mov    %edx,%eax
801045dc:	f7 d0                	not    %eax
801045de:	89 c2                	mov    %eax,%edx
801045e0:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801045e7:	21 d0                	and    %edx,%eax
801045e9:	0f b7 c0             	movzwl %ax,%eax
801045ec:	89 04 24             	mov    %eax,(%esp)
801045ef:	e8 89 ff ff ff       	call   8010457d <picsetmask>
}
801045f4:	c9                   	leave  
801045f5:	c3                   	ret    

801045f6 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
801045f6:	55                   	push   %ebp
801045f7:	89 e5                	mov    %esp,%ebp
801045f9:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801045fc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104603:	00 
80104604:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010460b:	e8 4f ff ff ff       	call   8010455f <outb>
  outb(IO_PIC2+1, 0xFF);
80104610:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104617:	00 
80104618:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010461f:	e8 3b ff ff ff       	call   8010455f <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104624:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010462b:	00 
8010462c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104633:	e8 27 ff ff ff       	call   8010455f <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104638:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010463f:	00 
80104640:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104647:	e8 13 ff ff ff       	call   8010455f <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
8010464c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104653:	00 
80104654:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010465b:	e8 ff fe ff ff       	call   8010455f <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104660:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104667:	00 
80104668:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010466f:	e8 eb fe ff ff       	call   8010455f <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104674:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010467b:	00 
8010467c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104683:	e8 d7 fe ff ff       	call   8010455f <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104688:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010468f:	00 
80104690:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104697:	e8 c3 fe ff ff       	call   8010455f <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
8010469c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801046a3:	00 
801046a4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801046ab:	e8 af fe ff ff       	call   8010455f <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801046b0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801046b7:	00 
801046b8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801046bf:	e8 9b fe ff ff       	call   8010455f <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801046c4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801046cb:	00 
801046cc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801046d3:	e8 87 fe ff ff       	call   8010455f <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801046d8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801046df:	00 
801046e0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801046e7:	e8 73 fe ff ff       	call   8010455f <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801046ec:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801046f3:	00 
801046f4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801046fb:	e8 5f fe ff ff       	call   8010455f <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104700:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104707:	00 
80104708:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010470f:	e8 4b fe ff ff       	call   8010455f <outb>

  if(irqmask != 0xFFFF)
80104714:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
8010471b:	66 83 f8 ff          	cmp    $0xffff,%ax
8010471f:	74 12                	je     80104733 <picinit+0x13d>
    picsetmask(irqmask);
80104721:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104728:	0f b7 c0             	movzwl %ax,%eax
8010472b:	89 04 24             	mov    %eax,(%esp)
8010472e:	e8 4a fe ff ff       	call   8010457d <picsetmask>
}
80104733:	c9                   	leave  
80104734:	c3                   	ret    

80104735 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104735:	55                   	push   %ebp
80104736:	89 e5                	mov    %esp,%ebp
80104738:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010473b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104742:	8b 45 0c             	mov    0xc(%ebp),%eax
80104745:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010474b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010474e:	8b 10                	mov    (%eax),%edx
80104750:	8b 45 08             	mov    0x8(%ebp),%eax
80104753:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104755:	e8 2d c9 ff ff       	call   80101087 <filealloc>
8010475a:	8b 55 08             	mov    0x8(%ebp),%edx
8010475d:	89 02                	mov    %eax,(%edx)
8010475f:	8b 45 08             	mov    0x8(%ebp),%eax
80104762:	8b 00                	mov    (%eax),%eax
80104764:	85 c0                	test   %eax,%eax
80104766:	0f 84 c8 00 00 00    	je     80104834 <pipealloc+0xff>
8010476c:	e8 16 c9 ff ff       	call   80101087 <filealloc>
80104771:	8b 55 0c             	mov    0xc(%ebp),%edx
80104774:	89 02                	mov    %eax,(%edx)
80104776:	8b 45 0c             	mov    0xc(%ebp),%eax
80104779:	8b 00                	mov    (%eax),%eax
8010477b:	85 c0                	test   %eax,%eax
8010477d:	0f 84 b1 00 00 00    	je     80104834 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104783:	e8 37 eb ff ff       	call   801032bf <kalloc>
80104788:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010478b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010478f:	75 05                	jne    80104796 <pipealloc+0x61>
    goto bad;
80104791:	e9 9e 00 00 00       	jmp    80104834 <pipealloc+0xff>
  p->readopen = 1;
80104796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104799:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801047a0:	00 00 00 
  p->writeopen = 1;
801047a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a6:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801047ad:	00 00 00 
  p->nwrite = 0;
801047b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b3:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801047ba:	00 00 00 
  p->nread = 0;
801047bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c0:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801047c7:	00 00 00 
  initlock(&p->lock, "pipe");
801047ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047cd:	c7 44 24 04 60 9f 10 	movl   $0x80109f60,0x4(%esp)
801047d4:	80 
801047d5:	89 04 24             	mov    %eax,(%esp)
801047d8:	e8 a3 10 00 00       	call   80105880 <initlock>
  (*f0)->type = FD_PIPE;
801047dd:	8b 45 08             	mov    0x8(%ebp),%eax
801047e0:	8b 00                	mov    (%eax),%eax
801047e2:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801047e8:	8b 45 08             	mov    0x8(%ebp),%eax
801047eb:	8b 00                	mov    (%eax),%eax
801047ed:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801047f1:	8b 45 08             	mov    0x8(%ebp),%eax
801047f4:	8b 00                	mov    (%eax),%eax
801047f6:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801047fa:	8b 45 08             	mov    0x8(%ebp),%eax
801047fd:	8b 00                	mov    (%eax),%eax
801047ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104802:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104805:	8b 45 0c             	mov    0xc(%ebp),%eax
80104808:	8b 00                	mov    (%eax),%eax
8010480a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104810:	8b 45 0c             	mov    0xc(%ebp),%eax
80104813:	8b 00                	mov    (%eax),%eax
80104815:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104819:	8b 45 0c             	mov    0xc(%ebp),%eax
8010481c:	8b 00                	mov    (%eax),%eax
8010481e:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104822:	8b 45 0c             	mov    0xc(%ebp),%eax
80104825:	8b 00                	mov    (%eax),%eax
80104827:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010482a:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010482d:	b8 00 00 00 00       	mov    $0x0,%eax
80104832:	eb 42                	jmp    80104876 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104834:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104838:	74 0b                	je     80104845 <pipealloc+0x110>
    kfree((char*)p);
8010483a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483d:	89 04 24             	mov    %eax,(%esp)
80104840:	e8 b8 e9 ff ff       	call   801031fd <kfree>
  if(*f0)
80104845:	8b 45 08             	mov    0x8(%ebp),%eax
80104848:	8b 00                	mov    (%eax),%eax
8010484a:	85 c0                	test   %eax,%eax
8010484c:	74 0d                	je     8010485b <pipealloc+0x126>
    fileclose(*f0);
8010484e:	8b 45 08             	mov    0x8(%ebp),%eax
80104851:	8b 00                	mov    (%eax),%eax
80104853:	89 04 24             	mov    %eax,(%esp)
80104856:	e8 d4 c8 ff ff       	call   8010112f <fileclose>
  if(*f1)
8010485b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010485e:	8b 00                	mov    (%eax),%eax
80104860:	85 c0                	test   %eax,%eax
80104862:	74 0d                	je     80104871 <pipealloc+0x13c>
    fileclose(*f1);
80104864:	8b 45 0c             	mov    0xc(%ebp),%eax
80104867:	8b 00                	mov    (%eax),%eax
80104869:	89 04 24             	mov    %eax,(%esp)
8010486c:	e8 be c8 ff ff       	call   8010112f <fileclose>
  return -1;
80104871:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104876:	c9                   	leave  
80104877:	c3                   	ret    

80104878 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104878:	55                   	push   %ebp
80104879:	89 e5                	mov    %esp,%ebp
8010487b:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010487e:	8b 45 08             	mov    0x8(%ebp),%eax
80104881:	89 04 24             	mov    %eax,(%esp)
80104884:	e8 18 10 00 00       	call   801058a1 <acquire>
  if(writable){
80104889:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010488d:	74 1f                	je     801048ae <pipeclose+0x36>
    p->writeopen = 0;
8010488f:	8b 45 08             	mov    0x8(%ebp),%eax
80104892:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104899:	00 00 00 
    wakeup(&p->nread);
8010489c:	8b 45 08             	mov    0x8(%ebp),%eax
8010489f:	05 34 02 00 00       	add    $0x234,%eax
801048a4:	89 04 24             	mov    %eax,(%esp)
801048a7:	e8 64 0d 00 00       	call   80105610 <wakeup>
801048ac:	eb 1d                	jmp    801048cb <pipeclose+0x53>
  } else {
    p->readopen = 0;
801048ae:	8b 45 08             	mov    0x8(%ebp),%eax
801048b1:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801048b8:	00 00 00 
    wakeup(&p->nwrite);
801048bb:	8b 45 08             	mov    0x8(%ebp),%eax
801048be:	05 38 02 00 00       	add    $0x238,%eax
801048c3:	89 04 24             	mov    %eax,(%esp)
801048c6:	e8 45 0d 00 00       	call   80105610 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801048cb:	8b 45 08             	mov    0x8(%ebp),%eax
801048ce:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048d4:	85 c0                	test   %eax,%eax
801048d6:	75 25                	jne    801048fd <pipeclose+0x85>
801048d8:	8b 45 08             	mov    0x8(%ebp),%eax
801048db:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801048e1:	85 c0                	test   %eax,%eax
801048e3:	75 18                	jne    801048fd <pipeclose+0x85>
    release(&p->lock);
801048e5:	8b 45 08             	mov    0x8(%ebp),%eax
801048e8:	89 04 24             	mov    %eax,(%esp)
801048eb:	e8 13 10 00 00       	call   80105903 <release>
    kfree((char*)p);
801048f0:	8b 45 08             	mov    0x8(%ebp),%eax
801048f3:	89 04 24             	mov    %eax,(%esp)
801048f6:	e8 02 e9 ff ff       	call   801031fd <kfree>
801048fb:	eb 0b                	jmp    80104908 <pipeclose+0x90>
  } else
    release(&p->lock);
801048fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104900:	89 04 24             	mov    %eax,(%esp)
80104903:	e8 fb 0f 00 00       	call   80105903 <release>
}
80104908:	c9                   	leave  
80104909:	c3                   	ret    

8010490a <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010490a:	55                   	push   %ebp
8010490b:	89 e5                	mov    %esp,%ebp
8010490d:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104910:	8b 45 08             	mov    0x8(%ebp),%eax
80104913:	89 04 24             	mov    %eax,(%esp)
80104916:	e8 86 0f 00 00       	call   801058a1 <acquire>
  for(i = 0; i < n; i++){
8010491b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104922:	e9 a6 00 00 00       	jmp    801049cd <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104927:	eb 57                	jmp    80104980 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104929:	8b 45 08             	mov    0x8(%ebp),%eax
8010492c:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104932:	85 c0                	test   %eax,%eax
80104934:	74 0d                	je     80104943 <pipewrite+0x39>
80104936:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493c:	8b 40 24             	mov    0x24(%eax),%eax
8010493f:	85 c0                	test   %eax,%eax
80104941:	74 15                	je     80104958 <pipewrite+0x4e>
        release(&p->lock);
80104943:	8b 45 08             	mov    0x8(%ebp),%eax
80104946:	89 04 24             	mov    %eax,(%esp)
80104949:	e8 b5 0f 00 00       	call   80105903 <release>
        return -1;
8010494e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104953:	e9 9f 00 00 00       	jmp    801049f7 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104958:	8b 45 08             	mov    0x8(%ebp),%eax
8010495b:	05 34 02 00 00       	add    $0x234,%eax
80104960:	89 04 24             	mov    %eax,(%esp)
80104963:	e8 a8 0c 00 00       	call   80105610 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104968:	8b 45 08             	mov    0x8(%ebp),%eax
8010496b:	8b 55 08             	mov    0x8(%ebp),%edx
8010496e:	81 c2 38 02 00 00    	add    $0x238,%edx
80104974:	89 44 24 04          	mov    %eax,0x4(%esp)
80104978:	89 14 24             	mov    %edx,(%esp)
8010497b:	e8 b4 0b 00 00       	call   80105534 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104980:	8b 45 08             	mov    0x8(%ebp),%eax
80104983:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104989:	8b 45 08             	mov    0x8(%ebp),%eax
8010498c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104992:	05 00 02 00 00       	add    $0x200,%eax
80104997:	39 c2                	cmp    %eax,%edx
80104999:	74 8e                	je     80104929 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010499b:	8b 45 08             	mov    0x8(%ebp),%eax
8010499e:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049a4:	8d 48 01             	lea    0x1(%eax),%ecx
801049a7:	8b 55 08             	mov    0x8(%ebp),%edx
801049aa:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801049b0:	25 ff 01 00 00       	and    $0x1ff,%eax
801049b5:	89 c1                	mov    %eax,%ecx
801049b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ba:	8b 45 0c             	mov    0xc(%ebp),%eax
801049bd:	01 d0                	add    %edx,%eax
801049bf:	0f b6 10             	movzbl (%eax),%edx
801049c2:	8b 45 08             	mov    0x8(%ebp),%eax
801049c5:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801049c9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801049cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049d0:	3b 45 10             	cmp    0x10(%ebp),%eax
801049d3:	0f 8c 4e ff ff ff    	jl     80104927 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801049d9:	8b 45 08             	mov    0x8(%ebp),%eax
801049dc:	05 34 02 00 00       	add    $0x234,%eax
801049e1:	89 04 24             	mov    %eax,(%esp)
801049e4:	e8 27 0c 00 00       	call   80105610 <wakeup>
  release(&p->lock);
801049e9:	8b 45 08             	mov    0x8(%ebp),%eax
801049ec:	89 04 24             	mov    %eax,(%esp)
801049ef:	e8 0f 0f 00 00       	call   80105903 <release>
  return n;
801049f4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801049f7:	c9                   	leave  
801049f8:	c3                   	ret    

801049f9 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801049f9:	55                   	push   %ebp
801049fa:	89 e5                	mov    %esp,%ebp
801049fc:	53                   	push   %ebx
801049fd:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104a00:	8b 45 08             	mov    0x8(%ebp),%eax
80104a03:	89 04 24             	mov    %eax,(%esp)
80104a06:	e8 96 0e 00 00       	call   801058a1 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104a0b:	eb 3a                	jmp    80104a47 <piperead+0x4e>
    if(proc->killed){
80104a0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a13:	8b 40 24             	mov    0x24(%eax),%eax
80104a16:	85 c0                	test   %eax,%eax
80104a18:	74 15                	je     80104a2f <piperead+0x36>
      release(&p->lock);
80104a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80104a1d:	89 04 24             	mov    %eax,(%esp)
80104a20:	e8 de 0e 00 00       	call   80105903 <release>
      return -1;
80104a25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a2a:	e9 b5 00 00 00       	jmp    80104ae4 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80104a32:	8b 55 08             	mov    0x8(%ebp),%edx
80104a35:	81 c2 34 02 00 00    	add    $0x234,%edx
80104a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a3f:	89 14 24             	mov    %edx,(%esp)
80104a42:	e8 ed 0a 00 00       	call   80105534 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104a47:	8b 45 08             	mov    0x8(%ebp),%eax
80104a4a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a50:	8b 45 08             	mov    0x8(%ebp),%eax
80104a53:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a59:	39 c2                	cmp    %eax,%edx
80104a5b:	75 0d                	jne    80104a6a <piperead+0x71>
80104a5d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a60:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104a66:	85 c0                	test   %eax,%eax
80104a68:	75 a3                	jne    80104a0d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a6a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104a71:	eb 4b                	jmp    80104abe <piperead+0xc5>
    if(p->nread == p->nwrite)
80104a73:	8b 45 08             	mov    0x8(%ebp),%eax
80104a76:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a7c:	8b 45 08             	mov    0x8(%ebp),%eax
80104a7f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a85:	39 c2                	cmp    %eax,%edx
80104a87:	75 02                	jne    80104a8b <piperead+0x92>
      break;
80104a89:	eb 3b                	jmp    80104ac6 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104a8b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a91:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104a94:	8b 45 08             	mov    0x8(%ebp),%eax
80104a97:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a9d:	8d 48 01             	lea    0x1(%eax),%ecx
80104aa0:	8b 55 08             	mov    0x8(%ebp),%edx
80104aa3:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104aa9:	25 ff 01 00 00       	and    $0x1ff,%eax
80104aae:	89 c2                	mov    %eax,%edx
80104ab0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ab3:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104ab8:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104aba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac1:	3b 45 10             	cmp    0x10(%ebp),%eax
80104ac4:	7c ad                	jl     80104a73 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104ac6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ac9:	05 38 02 00 00       	add    $0x238,%eax
80104ace:	89 04 24             	mov    %eax,(%esp)
80104ad1:	e8 3a 0b 00 00       	call   80105610 <wakeup>
  release(&p->lock);
80104ad6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ad9:	89 04 24             	mov    %eax,(%esp)
80104adc:	e8 22 0e 00 00       	call   80105903 <release>
  return i;
80104ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104ae4:	83 c4 24             	add    $0x24,%esp
80104ae7:	5b                   	pop    %ebx
80104ae8:	5d                   	pop    %ebp
80104ae9:	c3                   	ret    

80104aea <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104aea:	55                   	push   %ebp
80104aeb:	89 e5                	mov    %esp,%ebp
80104aed:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104af0:	9c                   	pushf  
80104af1:	58                   	pop    %eax
80104af2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104af5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104af8:	c9                   	leave  
80104af9:	c3                   	ret    

80104afa <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104afa:	55                   	push   %ebp
80104afb:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104afd:	fb                   	sti    
}
80104afe:	5d                   	pop    %ebp
80104aff:	c3                   	ret    

80104b00 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104b00:	55                   	push   %ebp
80104b01:	89 e5                	mov    %esp,%ebp
80104b03:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104b06:	8b 55 08             	mov    0x8(%ebp),%edx
80104b09:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b0c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104b0f:	f0 87 02             	lock xchg %eax,(%edx)
80104b12:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104b15:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104b18:	c9                   	leave  
80104b19:	c3                   	ret    

80104b1a <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104b1a:	55                   	push   %ebp
80104b1b:	89 e5                	mov    %esp,%ebp
80104b1d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104b20:	c7 44 24 04 65 9f 10 	movl   $0x80109f65,0x4(%esp)
80104b27:	80 
80104b28:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b2f:	e8 4c 0d 00 00       	call   80105880 <initlock>
}
80104b34:	c9                   	leave  
80104b35:	c3                   	ret    

80104b36 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104b36:	55                   	push   %ebp
80104b37:	89 e5                	mov    %esp,%ebp
80104b39:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104b3c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b43:	e8 59 0d 00 00       	call   801058a1 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b48:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104b4f:	eb 53                	jmp    80104ba4 <allocproc+0x6e>
    if(p->state == UNUSED)
80104b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b54:	8b 40 0c             	mov    0xc(%eax),%eax
80104b57:	85 c0                	test   %eax,%eax
80104b59:	75 42                	jne    80104b9d <allocproc+0x67>
      goto found;
80104b5b:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104b5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5f:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104b66:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104b6b:	8d 50 01             	lea    0x1(%eax),%edx
80104b6e:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104b74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b77:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104b7a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b81:	e8 7d 0d 00 00       	call   80105903 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104b86:	e8 34 e7 ff ff       	call   801032bf <kalloc>
80104b8b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b8e:	89 42 08             	mov    %eax,0x8(%edx)
80104b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b94:	8b 40 08             	mov    0x8(%eax),%eax
80104b97:	85 c0                	test   %eax,%eax
80104b99:	75 36                	jne    80104bd1 <allocproc+0x9b>
80104b9b:	eb 23                	jmp    80104bc0 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b9d:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
80104ba4:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
80104bab:	72 a4                	jb     80104b51 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104bad:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104bb4:	e8 4a 0d 00 00       	call   80105903 <release>
    return 0;
80104bb9:	b8 00 00 00 00       	mov    $0x0,%eax
80104bbe:	eb 76                	jmp    80104c36 <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bc3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104bca:	b8 00 00 00 00       	mov    $0x0,%eax
80104bcf:	eb 65                	jmp    80104c36 <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bd4:	8b 40 08             	mov    0x8(%eax),%eax
80104bd7:	05 00 10 00 00       	add    $0x1000,%eax
80104bdc:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104bdf:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be6:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104be9:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104bec:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104bf0:	ba 09 6f 10 80       	mov    $0x80106f09,%edx
80104bf5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf8:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104bfa:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c01:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c04:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c0a:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c0d:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104c14:	00 
80104c15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c1c:	00 
80104c1d:	89 04 24             	mov    %eax,(%esp)
80104c20:	e8 d0 0e 00 00       	call   80105af5 <memset>
    p->context->eip = (uint)forkret;
80104c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c28:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c2b:	ba f5 54 10 80       	mov    $0x801054f5,%edx
80104c30:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104c33:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104c36:	c9                   	leave  
80104c37:	c3                   	ret    

80104c38 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104c38:	55                   	push   %ebp
80104c39:	89 e5                	mov    %esp,%ebp
80104c3b:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104c3e:	e8 f3 fe ff ff       	call   80104b36 <allocproc>
80104c43:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104c46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c49:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104c50:	00 00 00 
    p->swapedPagesCounter = 0;
80104c53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c56:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104c5d:	00 00 00 
    p->pageFaultCounter = 0;
80104c60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c63:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104c6a:	00 00 00 
    p->swappedOutCounter = 0;
80104c6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c70:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104c77:	00 00 00 
    p->numOfPages = 0;
80104c7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c7d:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104c84:	00 00 00 
    p->copyingSwapFile = 0;
80104c87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c8a:	c7 80 ec 02 00 00 00 	movl   $0x0,0x2ec(%eax)
80104c91:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c94:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c9b:	e9 92 00 00 00       	jmp    80104d32 <userinit+0xfa>
   	  p->pagesMetaData[i].count = 0;
80104ca0:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104ca3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ca6:	89 d0                	mov    %edx,%eax
80104ca8:	c1 e0 02             	shl    $0x2,%eax
80104cab:	01 d0                	add    %edx,%eax
80104cad:	c1 e0 02             	shl    $0x2,%eax
80104cb0:	01 c8                	add    %ecx,%eax
80104cb2:	05 9c 00 00 00       	add    $0x9c,%eax
80104cb7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104cbd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104cc0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cc3:	89 d0                	mov    %edx,%eax
80104cc5:	c1 e0 02             	shl    $0x2,%eax
80104cc8:	01 d0                	add    %edx,%eax
80104cca:	c1 e0 02             	shl    $0x2,%eax
80104ccd:	01 c8                	add    %ecx,%eax
80104ccf:	05 90 00 00 00       	add    $0x90,%eax
80104cd4:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104cda:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104cdd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ce0:	89 d0                	mov    %edx,%eax
80104ce2:	c1 e0 02             	shl    $0x2,%eax
80104ce5:	01 d0                	add    %edx,%eax
80104ce7:	c1 e0 02             	shl    $0x2,%eax
80104cea:	01 c8                	add    %ecx,%eax
80104cec:	05 94 00 00 00       	add    $0x94,%eax
80104cf1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104cf7:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104cfa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cfd:	89 d0                	mov    %edx,%eax
80104cff:	c1 e0 02             	shl    $0x2,%eax
80104d02:	01 d0                	add    %edx,%eax
80104d04:	c1 e0 02             	shl    $0x2,%eax
80104d07:	01 c8                	add    %ecx,%eax
80104d09:	05 98 00 00 00       	add    $0x98,%eax
80104d0e:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104d14:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104d17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d1a:	89 d0                	mov    %edx,%eax
80104d1c:	c1 e0 02             	shl    $0x2,%eax
80104d1f:	01 d0                	add    %edx,%eax
80104d21:	c1 e0 02             	shl    $0x2,%eax
80104d24:	01 c8                	add    %ecx,%eax
80104d26:	05 a0 00 00 00       	add    $0xa0,%eax
80104d2b:	c6 00 80             	movb   $0x80,(%eax)
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    p->copyingSwapFile = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104d2e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d32:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104d36:	0f 8e 64 ff ff ff    	jle    80104ca0 <userinit+0x68>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104d3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d3f:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104d44:	e8 5a 39 00 00       	call   801086a3 <setupkvm>
80104d49:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d4c:	89 42 04             	mov    %eax,0x4(%edx)
80104d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d52:	8b 40 04             	mov    0x4(%eax),%eax
80104d55:	85 c0                	test   %eax,%eax
80104d57:	75 0c                	jne    80104d65 <userinit+0x12d>
      panic("userinit: out of memory?");
80104d59:	c7 04 24 6c 9f 10 80 	movl   $0x80109f6c,(%esp)
80104d60:	e8 d5 b7 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104d65:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104d6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6d:	8b 40 04             	mov    0x4(%eax),%eax
80104d70:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d74:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104d7b:	80 
80104d7c:	89 04 24             	mov    %eax,(%esp)
80104d7f:	e8 77 3b 00 00       	call   801088fb <inituvm>
    p->sz = PGSIZE;
80104d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d87:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104d8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d90:	8b 40 18             	mov    0x18(%eax),%eax
80104d93:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104d9a:	00 
80104d9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104da2:	00 
80104da3:	89 04 24             	mov    %eax,(%esp)
80104da6:	e8 4a 0d 00 00       	call   80105af5 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104dab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dae:	8b 40 18             	mov    0x18(%eax),%eax
80104db1:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104db7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dba:	8b 40 18             	mov    0x18(%eax),%eax
80104dbd:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104dc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dc6:	8b 40 18             	mov    0x18(%eax),%eax
80104dc9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104dcc:	8b 52 18             	mov    0x18(%edx),%edx
80104dcf:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104dd3:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104dd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dda:	8b 40 18             	mov    0x18(%eax),%eax
80104ddd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104de0:	8b 52 18             	mov    0x18(%edx),%edx
80104de3:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104de7:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104deb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dee:	8b 40 18             	mov    0x18(%eax),%eax
80104df1:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104df8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dfb:	8b 40 18             	mov    0x18(%eax),%eax
80104dfe:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104e05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e08:	8b 40 18             	mov    0x18(%eax),%eax
80104e0b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e15:	83 c0 6c             	add    $0x6c,%eax
80104e18:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104e1f:	00 
80104e20:	c7 44 24 04 85 9f 10 	movl   $0x80109f85,0x4(%esp)
80104e27:	80 
80104e28:	89 04 24             	mov    %eax,(%esp)
80104e2b:	e8 e5 0e 00 00       	call   80105d15 <safestrcpy>
  p->cwd = namei("/");
80104e30:	c7 04 24 8e 9f 10 80 	movl   $0x80109f8e,(%esp)
80104e37:	e8 8f d7 ff ff       	call   801025cb <namei>
80104e3c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e3f:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104e42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e45:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104e4c:	e8 bb e4 ff ff       	call   8010330c <countPages>
80104e51:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104e56:	a1 60 49 11 80       	mov    0x80114960,%eax
80104e5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e5f:	c7 04 24 90 9f 10 80 	movl   $0x80109f90,(%esp)
80104e66:	e8 35 b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104e6b:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104e72:	00 00 00 
}
80104e75:	c9                   	leave  
80104e76:	c3                   	ret    

80104e77 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104e77:	55                   	push   %ebp
80104e78:	89 e5                	mov    %esp,%ebp
80104e7a:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104e7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e83:	8b 00                	mov    (%eax),%eax
80104e85:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104e88:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e8c:	7e 3f                	jle    80104ecd <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e8e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e95:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e9b:	01 c1                	add    %eax,%ecx
80104e9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ea3:	8b 40 04             	mov    0x4(%eax),%eax
80104ea6:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104eaa:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104eae:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104eb1:	89 54 24 04          	mov    %edx,0x4(%esp)
80104eb5:	89 04 24             	mov    %eax,(%esp)
80104eb8:	e8 b4 3b 00 00       	call   80108a71 <allocuvm>
80104ebd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104ec0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104ec4:	75 4c                	jne    80104f12 <growproc+0x9b>
      return -1;
80104ec6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ecb:	eb 63                	jmp    80104f30 <growproc+0xb9>
  } else if(n < 0){
80104ecd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104ed1:	79 3f                	jns    80104f12 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104ed3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104eda:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104edd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ee0:	01 c1                	add    %eax,%ecx
80104ee2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ee8:	8b 40 04             	mov    0x4(%eax),%eax
80104eeb:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104eef:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ef3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ef6:	89 54 24 04          	mov    %edx,0x4(%esp)
80104efa:	89 04 24             	mov    %eax,(%esp)
80104efd:	e8 ba 3d 00 00       	call   80108cbc <deallocuvm>
80104f02:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104f05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104f09:	75 07                	jne    80104f12 <growproc+0x9b>
      return -1;
80104f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f10:	eb 1e                	jmp    80104f30 <growproc+0xb9>
  }
  proc->sz = sz;
80104f12:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f18:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f1b:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104f1d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f23:	89 04 24             	mov    %eax,(%esp)
80104f26:	e8 69 38 00 00       	call   80108794 <switchuvm>
  return 0;
80104f2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f30:	c9                   	leave  
80104f31:	c3                   	ret    

80104f32 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104f32:	55                   	push   %ebp
80104f33:	89 e5                	mov    %esp,%ebp
80104f35:	57                   	push   %edi
80104f36:	56                   	push   %esi
80104f37:	53                   	push   %ebx
80104f38:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104f3b:	e8 f6 fb ff ff       	call   80104b36 <allocproc>
80104f40:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104f43:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104f47:	75 0a                	jne    80104f53 <fork+0x21>
    return -1;
80104f49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f4e:	e9 ca 01 00 00       	jmp    8010511d <fork+0x1eb>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104f53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f59:	8b 10                	mov    (%eax),%edx
80104f5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f61:	8b 40 04             	mov    0x4(%eax),%eax
80104f64:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104f67:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104f6b:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f6f:	89 04 24             	mov    %eax,(%esp)
80104f72:	e8 33 40 00 00       	call   80108faa <copyuvm>
80104f77:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f7a:	89 42 04             	mov    %eax,0x4(%edx)
80104f7d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f80:	8b 40 04             	mov    0x4(%eax),%eax
80104f83:	85 c0                	test   %eax,%eax
80104f85:	75 2c                	jne    80104fb3 <fork+0x81>
    kfree(np->kstack);
80104f87:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f8a:	8b 40 08             	mov    0x8(%eax),%eax
80104f8d:	89 04 24             	mov    %eax,(%esp)
80104f90:	e8 68 e2 ff ff       	call   801031fd <kfree>
    np->kstack = 0;
80104f95:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f98:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104f9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fa2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104fa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fae:	e9 6a 01 00 00       	jmp    8010511d <fork+0x1eb>
  }
  np->sz = proc->sz;
80104fb3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fb9:	8b 10                	mov    (%eax),%edx
80104fbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fbe:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104fc0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104fc7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fca:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104fcd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd0:	8b 50 18             	mov    0x18(%eax),%edx
80104fd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fd9:	8b 40 18             	mov    0x18(%eax),%eax
80104fdc:	89 c3                	mov    %eax,%ebx
80104fde:	b8 13 00 00 00       	mov    $0x13,%eax
80104fe3:	89 d7                	mov    %edx,%edi
80104fe5:	89 de                	mov    %ebx,%esi
80104fe7:	89 c1                	mov    %eax,%ecx
80104fe9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104feb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fee:	8b 40 18             	mov    0x18(%eax),%eax
80104ff1:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104ff8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104fff:	eb 3d                	jmp    8010503e <fork+0x10c>
    if(proc->ofile[i])
80105001:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105007:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010500a:	83 c2 08             	add    $0x8,%edx
8010500d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105011:	85 c0                	test   %eax,%eax
80105013:	74 25                	je     8010503a <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80105015:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010501b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010501e:	83 c2 08             	add    $0x8,%edx
80105021:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105025:	89 04 24             	mov    %eax,(%esp)
80105028:	e8 ba c0 ff ff       	call   801010e7 <filedup>
8010502d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105030:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105033:	83 c1 08             	add    $0x8,%ecx
80105036:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010503a:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010503e:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80105042:	7e bd                	jle    80105001 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80105044:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010504a:	8b 40 68             	mov    0x68(%eax),%eax
8010504d:	89 04 24             	mov    %eax,(%esp)
80105050:	e8 93 c9 ff ff       	call   801019e8 <idup>
80105055:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105058:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
8010505b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105061:	8d 50 6c             	lea    0x6c(%eax),%edx
80105064:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105067:	83 c0 6c             	add    $0x6c,%eax
8010506a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105071:	00 
80105072:	89 54 24 04          	mov    %edx,0x4(%esp)
80105076:	89 04 24             	mov    %eax,(%esp)
80105079:	e8 97 0c 00 00       	call   80105d15 <safestrcpy>

    pid = np->pid;
8010507e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105081:	8b 40 10             	mov    0x10(%eax),%eax
80105084:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->memoryPagesCounter = proc->memoryPagesCounter;
80105087:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010508d:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80105093:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105096:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    np->swapedPagesCounter = proc->swapedPagesCounter;
8010509c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050a2:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
801050a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050ab:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
    np->pageFaultCounter = 0;
801050b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050b4:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
801050bb:	00 00 00 
    np->swappedOutCounter = 0;
801050be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050c1:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
801050c8:	00 00 00 
    np->copyingSwapFile = 0;
801050cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050ce:	c7 80 ec 02 00 00 00 	movl   $0x0,0x2ec(%eax)
801050d5:	00 00 00 
    createSwapFile(np);
801050d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050db:	89 04 24             	mov    %eax,(%esp)
801050de:	e8 f9 d7 ff ff       	call   801028dc <createSwapFile>
    copySwapFile(proc,np);
801050e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e9:	8b 55 e0             	mov    -0x20(%ebp),%edx
801050ec:	89 54 24 04          	mov    %edx,0x4(%esp)
801050f0:	89 04 24             	mov    %eax,(%esp)
801050f3:	e8 19 d9 ff ff       	call   80102a11 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
801050f8:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801050ff:	e8 9d 07 00 00       	call   801058a1 <acquire>
    np->state = RUNNABLE;
80105104:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105107:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
8010510e:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105115:	e8 e9 07 00 00       	call   80105903 <release>

    return pid;
8010511a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
8010511d:	83 c4 2c             	add    $0x2c,%esp
80105120:	5b                   	pop    %ebx
80105121:	5e                   	pop    %esi
80105122:	5f                   	pop    %edi
80105123:	5d                   	pop    %ebp
80105124:	c3                   	ret    

80105125 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105125:	55                   	push   %ebp
80105126:	89 e5                	mov    %esp,%ebp
80105128:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int fd;
    if(VERBOSE_PRINT == 1)
      procdump();
8010512b:	e8 86 05 00 00       	call   801056b6 <procdump>
    if(proc == initproc)
80105130:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105137:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
8010513c:	39 c2                	cmp    %eax,%edx
8010513e:	75 0c                	jne    8010514c <exit+0x27>
      panic("init exiting");
80105140:	c7 04 24 ae 9f 10 80 	movl   $0x80109fae,(%esp)
80105147:	e8 ee b3 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
8010514c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105153:	eb 44                	jmp    80105199 <exit+0x74>
      if(proc->ofile[fd]){
80105155:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010515b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010515e:	83 c2 08             	add    $0x8,%edx
80105161:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105165:	85 c0                	test   %eax,%eax
80105167:	74 2c                	je     80105195 <exit+0x70>
        fileclose(proc->ofile[fd]);
80105169:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010516f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105172:	83 c2 08             	add    $0x8,%edx
80105175:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105179:	89 04 24             	mov    %eax,(%esp)
8010517c:	e8 ae bf ff ff       	call   8010112f <fileclose>
        proc->ofile[fd] = 0;
80105181:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105187:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010518a:	83 c2 08             	add    $0x8,%edx
8010518d:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105194:	00 
      procdump();
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
80105195:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105199:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010519d:	7e b6                	jle    80105155 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
8010519f:	e8 85 ea ff ff       	call   80103c29 <begin_op>
    iput(proc->cwd);
801051a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051aa:	8b 40 68             	mov    0x68(%eax),%eax
801051ad:	89 04 24             	mov    %eax,(%esp)
801051b0:	e8 1e ca ff ff       	call   80101bd3 <iput>
    end_op();
801051b5:	e8 f3 ea ff ff       	call   80103cad <end_op>
    proc->cwd = 0;
801051ba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c0:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
801051c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051cd:	89 04 24             	mov    %eax,(%esp)
801051d0:	e8 fb d4 ff ff       	call   801026d0 <removeSwapFile>
    acquire(&ptable.lock);
801051d5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801051dc:	e8 c0 06 00 00       	call   801058a1 <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
801051e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e7:	8b 40 14             	mov    0x14(%eax),%eax
801051ea:	89 04 24             	mov    %eax,(%esp)
801051ed:	e8 dd 03 00 00       	call   801055cf <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051f2:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801051f9:	eb 3b                	jmp    80105236 <exit+0x111>
      if(p->parent == proc){
801051fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051fe:	8b 50 14             	mov    0x14(%eax),%edx
80105201:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105207:	39 c2                	cmp    %eax,%edx
80105209:	75 24                	jne    8010522f <exit+0x10a>
        p->parent = initproc;
8010520b:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
80105211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105214:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
80105217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010521a:	8b 40 0c             	mov    0xc(%eax),%eax
8010521d:	83 f8 05             	cmp    $0x5,%eax
80105220:	75 0d                	jne    8010522f <exit+0x10a>
          wakeup1(initproc);
80105222:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105227:	89 04 24             	mov    %eax,(%esp)
8010522a:	e8 a0 03 00 00       	call   801055cf <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010522f:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
80105236:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
8010523d:	72 bc                	jb     801051fb <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
8010523f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105245:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
8010524c:	e8 c0 01 00 00       	call   80105411 <sched>
    panic("zombie exit");
80105251:	c7 04 24 bb 9f 10 80 	movl   $0x80109fbb,(%esp)
80105258:	e8 dd b2 ff ff       	call   8010053a <panic>

8010525d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
8010525d:	55                   	push   %ebp
8010525e:	89 e5                	mov    %esp,%ebp
80105260:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
80105263:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010526a:	e8 32 06 00 00       	call   801058a1 <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
8010526f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105276:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
8010527d:	e9 a4 00 00 00       	jmp    80105326 <wait+0xc9>
        if(p->parent != proc)
80105282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105285:	8b 50 14             	mov    0x14(%eax),%edx
80105288:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010528e:	39 c2                	cmp    %eax,%edx
80105290:	74 05                	je     80105297 <wait+0x3a>
          continue;
80105292:	e9 88 00 00 00       	jmp    8010531f <wait+0xc2>
        havekids = 1;
80105297:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
8010529e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a1:	8b 40 0c             	mov    0xc(%eax),%eax
801052a4:	83 f8 05             	cmp    $0x5,%eax
801052a7:	75 76                	jne    8010531f <wait+0xc2>
        // Found one.
          pid = p->pid;
801052a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ac:	8b 40 10             	mov    0x10(%eax),%eax
801052af:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801052b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b5:	8b 40 08             	mov    0x8(%eax),%eax
801052b8:	89 04 24             	mov    %eax,(%esp)
801052bb:	e8 3d df ff ff       	call   801031fd <kfree>
          p->kstack = 0;
801052c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
801052ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052cd:	8b 40 04             	mov    0x4(%eax),%eax
801052d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801052d7:	89 04 24             	mov    %eax,(%esp)
801052da:	e8 e1 3b 00 00       	call   80108ec0 <freevm>
          p->state = UNUSED;
801052df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
801052e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ec:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
801052f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f6:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
801052fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105300:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105307:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
8010530e:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105315:	e8 e9 05 00 00       	call   80105903 <release>
          return pid;
8010531a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010531d:	eb 55                	jmp    80105374 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010531f:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
80105326:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
8010532d:	0f 82 4f ff ff ff    	jb     80105282 <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
80105333:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105337:	74 0d                	je     80105346 <wait+0xe9>
80105339:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010533f:	8b 40 24             	mov    0x24(%eax),%eax
80105342:	85 c0                	test   %eax,%eax
80105344:	74 13                	je     80105359 <wait+0xfc>
        release(&ptable.lock);
80105346:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010534d:	e8 b1 05 00 00       	call   80105903 <release>
        return -1;
80105352:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105357:	eb 1b                	jmp    80105374 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105359:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535f:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
80105366:	80 
80105367:	89 04 24             	mov    %eax,(%esp)
8010536a:	e8 c5 01 00 00       	call   80105534 <sleep>
  }
8010536f:	e9 fb fe ff ff       	jmp    8010526f <wait+0x12>
}
80105374:	c9                   	leave  
80105375:	c3                   	ret    

80105376 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105376:	55                   	push   %ebp
80105377:	89 e5                	mov    %esp,%ebp
80105379:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
8010537c:	e8 79 f7 ff ff       	call   80104afa <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105381:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105388:	e8 14 05 00 00       	call   801058a1 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010538d:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105394:	eb 61                	jmp    801053f7 <scheduler+0x81>
      if(p->state != RUNNABLE)
80105396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105399:	8b 40 0c             	mov    0xc(%eax),%eax
8010539c:	83 f8 03             	cmp    $0x3,%eax
8010539f:	74 02                	je     801053a3 <scheduler+0x2d>
        continue;
801053a1:	eb 4d                	jmp    801053f0 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801053a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053a6:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801053ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053af:	89 04 24             	mov    %eax,(%esp)
801053b2:	e8 dd 33 00 00       	call   80108794 <switchuvm>
      p->state = RUNNING;
801053b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053ba:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801053c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c7:	8b 40 1c             	mov    0x1c(%eax),%eax
801053ca:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801053d1:	83 c2 04             	add    $0x4,%edx
801053d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801053d8:	89 14 24             	mov    %edx,(%esp)
801053db:	e8 a6 09 00 00       	call   80105d86 <swtch>
      switchkvm();
801053e0:	e8 92 33 00 00       	call   80108777 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801053e5:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801053ec:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053f0:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
801053f7:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
801053fe:	72 96                	jb     80105396 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105400:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105407:	e8 f7 04 00 00       	call   80105903 <release>

  }
8010540c:	e9 6b ff ff ff       	jmp    8010537c <scheduler+0x6>

80105411 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105411:	55                   	push   %ebp
80105412:	89 e5                	mov    %esp,%ebp
80105414:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105417:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010541e:	e8 a8 05 00 00       	call   801059cb <holding>
80105423:	85 c0                	test   %eax,%eax
80105425:	75 0c                	jne    80105433 <sched+0x22>
    panic("sched ptable.lock");
80105427:	c7 04 24 c7 9f 10 80 	movl   $0x80109fc7,(%esp)
8010542e:	e8 07 b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105433:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105439:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010543f:	83 f8 01             	cmp    $0x1,%eax
80105442:	74 0c                	je     80105450 <sched+0x3f>
    panic("sched locks");
80105444:	c7 04 24 d9 9f 10 80 	movl   $0x80109fd9,(%esp)
8010544b:	e8 ea b0 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80105450:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105456:	8b 40 0c             	mov    0xc(%eax),%eax
80105459:	83 f8 04             	cmp    $0x4,%eax
8010545c:	75 0c                	jne    8010546a <sched+0x59>
    panic("sched running");
8010545e:	c7 04 24 e5 9f 10 80 	movl   $0x80109fe5,(%esp)
80105465:	e8 d0 b0 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
8010546a:	e8 7b f6 ff ff       	call   80104aea <readeflags>
8010546f:	25 00 02 00 00       	and    $0x200,%eax
80105474:	85 c0                	test   %eax,%eax
80105476:	74 0c                	je     80105484 <sched+0x73>
    panic("sched interruptible");
80105478:	c7 04 24 f3 9f 10 80 	movl   $0x80109ff3,(%esp)
8010547f:	e8 b6 b0 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80105484:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010548a:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105490:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105493:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105499:	8b 40 04             	mov    0x4(%eax),%eax
8010549c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801054a3:	83 c2 1c             	add    $0x1c,%edx
801054a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801054aa:	89 14 24             	mov    %edx,(%esp)
801054ad:	e8 d4 08 00 00       	call   80105d86 <swtch>
  cpu->intena = intena;
801054b2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801054b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054bb:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801054c1:	c9                   	leave  
801054c2:	c3                   	ret    

801054c3 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801054c3:	55                   	push   %ebp
801054c4:	89 e5                	mov    %esp,%ebp
801054c6:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801054c9:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054d0:	e8 cc 03 00 00       	call   801058a1 <acquire>
  proc->state = RUNNABLE;
801054d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054db:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801054e2:	e8 2a ff ff ff       	call   80105411 <sched>
  release(&ptable.lock);
801054e7:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054ee:	e8 10 04 00 00       	call   80105903 <release>
}
801054f3:	c9                   	leave  
801054f4:	c3                   	ret    

801054f5 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801054f5:	55                   	push   %ebp
801054f6:	89 e5                	mov    %esp,%ebp
801054f8:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801054fb:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105502:	e8 fc 03 00 00       	call   80105903 <release>

  if (first) {
80105507:	a1 08 d0 10 80       	mov    0x8010d008,%eax
8010550c:	85 c0                	test   %eax,%eax
8010550e:	74 22                	je     80105532 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105510:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
80105517:	00 00 00 
    iinit(ROOTDEV);
8010551a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105521:	e8 cc c1 ff ff       	call   801016f2 <iinit>
    initlog(ROOTDEV);
80105526:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010552d:	e8 f3 e4 ff ff       	call   80103a25 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105532:	c9                   	leave  
80105533:	c3                   	ret    

80105534 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105534:	55                   	push   %ebp
80105535:	89 e5                	mov    %esp,%ebp
80105537:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010553a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105540:	85 c0                	test   %eax,%eax
80105542:	75 0c                	jne    80105550 <sleep+0x1c>
    panic("sleep");
80105544:	c7 04 24 07 a0 10 80 	movl   $0x8010a007,(%esp)
8010554b:	e8 ea af ff ff       	call   8010053a <panic>

  if(lk == 0)
80105550:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105554:	75 0c                	jne    80105562 <sleep+0x2e>
    panic("sleep without lk");
80105556:	c7 04 24 0d a0 10 80 	movl   $0x8010a00d,(%esp)
8010555d:	e8 d8 af ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105562:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
80105569:	74 17                	je     80105582 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010556b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105572:	e8 2a 03 00 00       	call   801058a1 <acquire>
    release(lk);
80105577:	8b 45 0c             	mov    0xc(%ebp),%eax
8010557a:	89 04 24             	mov    %eax,(%esp)
8010557d:	e8 81 03 00 00       	call   80105903 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105582:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105588:	8b 55 08             	mov    0x8(%ebp),%edx
8010558b:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010558e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105594:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
8010559b:	e8 71 fe ff ff       	call   80105411 <sched>

  // Tidy up.
  proc->chan = 0;
801055a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055a6:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801055ad:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801055b4:	74 17                	je     801055cd <sleep+0x99>
    release(&ptable.lock);
801055b6:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055bd:	e8 41 03 00 00       	call   80105903 <release>
    acquire(lk);
801055c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801055c5:	89 04 24             	mov    %eax,(%esp)
801055c8:	e8 d4 02 00 00       	call   801058a1 <acquire>
  }
}
801055cd:	c9                   	leave  
801055ce:	c3                   	ret    

801055cf <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801055cf:	55                   	push   %ebp
801055d0:	89 e5                	mov    %esp,%ebp
801055d2:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801055d5:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
801055dc:	eb 27                	jmp    80105605 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
801055de:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055e1:	8b 40 0c             	mov    0xc(%eax),%eax
801055e4:	83 f8 02             	cmp    $0x2,%eax
801055e7:	75 15                	jne    801055fe <wakeup1+0x2f>
801055e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055ec:	8b 40 20             	mov    0x20(%eax),%eax
801055ef:	3b 45 08             	cmp    0x8(%ebp),%eax
801055f2:	75 0a                	jne    801055fe <wakeup1+0x2f>
      p->state = RUNNABLE;
801055f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055f7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801055fe:	81 45 fc f0 02 00 00 	addl   $0x2f0,-0x4(%ebp)
80105605:	81 7d fc b4 05 12 80 	cmpl   $0x801205b4,-0x4(%ebp)
8010560c:	72 d0                	jb     801055de <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
8010560e:	c9                   	leave  
8010560f:	c3                   	ret    

80105610 <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
80105610:	55                   	push   %ebp
80105611:	89 e5                	mov    %esp,%ebp
80105613:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
80105616:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010561d:	e8 7f 02 00 00       	call   801058a1 <acquire>
    wakeup1(chan);
80105622:	8b 45 08             	mov    0x8(%ebp),%eax
80105625:	89 04 24             	mov    %eax,(%esp)
80105628:	e8 a2 ff ff ff       	call   801055cf <wakeup1>
    release(&ptable.lock);
8010562d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105634:	e8 ca 02 00 00       	call   80105903 <release>
  }
80105639:	c9                   	leave  
8010563a:	c3                   	ret    

8010563b <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
8010563b:	55                   	push   %ebp
8010563c:	89 e5                	mov    %esp,%ebp
8010563e:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
80105641:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105648:	e8 54 02 00 00       	call   801058a1 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010564d:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105654:	eb 44                	jmp    8010569a <kill+0x5f>
      if(p->pid == pid){
80105656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105659:	8b 40 10             	mov    0x10(%eax),%eax
8010565c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010565f:	75 32                	jne    80105693 <kill+0x58>
        p->killed = 1;
80105661:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105664:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
8010566b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010566e:	8b 40 0c             	mov    0xc(%eax),%eax
80105671:	83 f8 02             	cmp    $0x2,%eax
80105674:	75 0a                	jne    80105680 <kill+0x45>
          p->state = RUNNABLE;
80105676:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105679:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
80105680:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105687:	e8 77 02 00 00       	call   80105903 <release>
        return 0;
8010568c:	b8 00 00 00 00       	mov    $0x0,%eax
80105691:	eb 21                	jmp    801056b4 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105693:	81 45 f4 f0 02 00 00 	addl   $0x2f0,-0xc(%ebp)
8010569a:	81 7d f4 b4 05 12 80 	cmpl   $0x801205b4,-0xc(%ebp)
801056a1:	72 b3                	jb     80105656 <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801056a3:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801056aa:	e8 54 02 00 00       	call   80105903 <release>
    return -1;
801056af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801056b4:	c9                   	leave  
801056b5:	c3                   	ret    

801056b6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801056b6:	55                   	push   %ebp
801056b7:	89 e5                	mov    %esp,%ebp
801056b9:	57                   	push   %edi
801056ba:	56                   	push   %esi
801056bb:	53                   	push   %ebx
801056bc:	83 ec 6c             	sub    $0x6c,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801056bf:	c7 45 e0 b4 49 11 80 	movl   $0x801149b4,-0x20(%ebp)
801056c6:	e9 24 01 00 00       	jmp    801057ef <procdump+0x139>
      if(p->state == UNUSED)
801056cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056ce:	8b 40 0c             	mov    0xc(%eax),%eax
801056d1:	85 c0                	test   %eax,%eax
801056d3:	75 05                	jne    801056da <procdump+0x24>
        continue;
801056d5:	e9 0e 01 00 00       	jmp    801057e8 <procdump+0x132>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801056da:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056dd:	8b 40 0c             	mov    0xc(%eax),%eax
801056e0:	83 f8 05             	cmp    $0x5,%eax
801056e3:	77 23                	ja     80105708 <procdump+0x52>
801056e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056e8:	8b 40 0c             	mov    0xc(%eax),%eax
801056eb:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
801056f2:	85 c0                	test   %eax,%eax
801056f4:	74 12                	je     80105708 <procdump+0x52>
        state = states[p->state];
801056f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056f9:	8b 40 0c             	mov    0xc(%eax),%eax
801056fc:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105703:	89 45 dc             	mov    %eax,-0x24(%ebp)
80105706:	eb 07                	jmp    8010570f <procdump+0x59>
      else
        state = "???";
80105708:	c7 45 dc 1e a0 10 80 	movl   $0x8010a01e,-0x24(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
8010570f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105712:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
80105718:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010571b:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
80105721:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105724:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
8010572a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010572d:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
80105733:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105736:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
8010573c:	01 c6                	add    %eax,%esi
8010573e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105741:	8b 40 10             	mov    0x10(%eax),%eax
80105744:	89 5c 24 18          	mov    %ebx,0x18(%esp)
80105748:	89 4c 24 14          	mov    %ecx,0x14(%esp)
8010574c:	89 54 24 10          	mov    %edx,0x10(%esp)
80105750:	89 74 24 0c          	mov    %esi,0xc(%esp)
80105754:	8b 55 dc             	mov    -0x24(%ebp),%edx
80105757:	89 54 24 08          	mov    %edx,0x8(%esp)
8010575b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010575f:	c7 04 24 22 a0 10 80 	movl   $0x8010a022,(%esp)
80105766:	e8 35 ac ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
8010576b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010576e:	83 c0 6c             	add    $0x6c,%eax
80105771:	89 44 24 04          	mov    %eax,0x4(%esp)
80105775:	c7 04 24 35 a0 10 80 	movl   $0x8010a035,(%esp)
8010577c:	e8 1f ac ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
80105781:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105784:	8b 40 0c             	mov    0xc(%eax),%eax
80105787:	83 f8 02             	cmp    $0x2,%eax
8010578a:	75 50                	jne    801057dc <procdump+0x126>
        getcallerpcs((uint*)p->context->ebp+2, pc);
8010578c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010578f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105792:	8b 40 0c             	mov    0xc(%eax),%eax
80105795:	83 c0 08             	add    $0x8,%eax
80105798:	8d 55 b4             	lea    -0x4c(%ebp),%edx
8010579b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010579f:	89 04 24             	mov    %eax,(%esp)
801057a2:	e8 ab 01 00 00       	call   80105952 <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801057a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801057ae:	eb 1b                	jmp    801057cb <procdump+0x115>
          cprintf(" %p", pc[i]);
801057b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801057b3:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
801057b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801057bb:	c7 04 24 38 a0 10 80 	movl   $0x8010a038,(%esp)
801057c2:	e8 d9 ab ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
801057c7:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801057cb:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
801057cf:	7f 0b                	jg     801057dc <procdump+0x126>
801057d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801057d4:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
801057d8:	85 c0                	test   %eax,%eax
801057da:	75 d4                	jne    801057b0 <procdump+0xfa>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
801057dc:	c7 04 24 3c a0 10 80 	movl   $0x8010a03c,(%esp)
801057e3:	e8 b8 ab ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057e8:	81 45 e0 f0 02 00 00 	addl   $0x2f0,-0x20(%ebp)
801057ef:	81 7d e0 b4 05 12 80 	cmpl   $0x801205b4,-0x20(%ebp)
801057f6:	0f 82 cf fe ff ff    	jb     801056cb <procdump+0x15>
        for(i=0; i<10 && pc[i] != 0; i++)
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    cprintf("%d free pages in the system\n",countPages()*100/numOfInitializedPages);
801057fc:	e8 0b db ff ff       	call   8010330c <countPages>
80105801:	6b c0 64             	imul   $0x64,%eax,%eax
80105804:	8b 3d 60 49 11 80    	mov    0x80114960,%edi
8010580a:	99                   	cltd   
8010580b:	f7 ff                	idiv   %edi
8010580d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105811:	c7 04 24 3e a0 10 80 	movl   $0x8010a03e,(%esp)
80105818:	e8 83 ab ff ff       	call   801003a0 <cprintf>
  }
8010581d:	83 c4 6c             	add    $0x6c,%esp
80105820:	5b                   	pop    %ebx
80105821:	5e                   	pop    %esi
80105822:	5f                   	pop    %edi
80105823:	5d                   	pop    %ebp
80105824:	c3                   	ret    

80105825 <copyingSwapFile>:

void
copyingSwapFile(struct proc* p, int num){
80105825:	55                   	push   %ebp
80105826:	89 e5                	mov    %esp,%ebp
80105828:	83 ec 08             	sub    $0x8,%esp
  while(xchg(&(p->copyingSwapFile),num) != 0);
8010582b:	90                   	nop
8010582c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010582f:	8b 55 08             	mov    0x8(%ebp),%edx
80105832:	81 c2 ec 02 00 00    	add    $0x2ec,%edx
80105838:	89 44 24 04          	mov    %eax,0x4(%esp)
8010583c:	89 14 24             	mov    %edx,(%esp)
8010583f:	e8 bc f2 ff ff       	call   80104b00 <xchg>
80105844:	85 c0                	test   %eax,%eax
80105846:	75 e4                	jne    8010582c <copyingSwapFile+0x7>
80105848:	c9                   	leave  
80105849:	c3                   	ret    

8010584a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010584a:	55                   	push   %ebp
8010584b:	89 e5                	mov    %esp,%ebp
8010584d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105850:	9c                   	pushf  
80105851:	58                   	pop    %eax
80105852:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105855:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105858:	c9                   	leave  
80105859:	c3                   	ret    

8010585a <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010585a:	55                   	push   %ebp
8010585b:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010585d:	fa                   	cli    
}
8010585e:	5d                   	pop    %ebp
8010585f:	c3                   	ret    

80105860 <sti>:

static inline void
sti(void)
{
80105860:	55                   	push   %ebp
80105861:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105863:	fb                   	sti    
}
80105864:	5d                   	pop    %ebp
80105865:	c3                   	ret    

80105866 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105866:	55                   	push   %ebp
80105867:	89 e5                	mov    %esp,%ebp
80105869:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010586c:	8b 55 08             	mov    0x8(%ebp),%edx
8010586f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105872:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105875:	f0 87 02             	lock xchg %eax,(%edx)
80105878:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010587b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010587e:	c9                   	leave  
8010587f:	c3                   	ret    

80105880 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105880:	55                   	push   %ebp
80105881:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105883:	8b 45 08             	mov    0x8(%ebp),%eax
80105886:	8b 55 0c             	mov    0xc(%ebp),%edx
80105889:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010588c:	8b 45 08             	mov    0x8(%ebp),%eax
8010588f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105895:	8b 45 08             	mov    0x8(%ebp),%eax
80105898:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010589f:	5d                   	pop    %ebp
801058a0:	c3                   	ret    

801058a1 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801058a1:	55                   	push   %ebp
801058a2:	89 e5                	mov    %esp,%ebp
801058a4:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801058a7:	e8 49 01 00 00       	call   801059f5 <pushcli>
  if(holding(lk))
801058ac:	8b 45 08             	mov    0x8(%ebp),%eax
801058af:	89 04 24             	mov    %eax,(%esp)
801058b2:	e8 14 01 00 00       	call   801059cb <holding>
801058b7:	85 c0                	test   %eax,%eax
801058b9:	74 0c                	je     801058c7 <acquire+0x26>
    panic("acquire");
801058bb:	c7 04 24 85 a0 10 80 	movl   $0x8010a085,(%esp)
801058c2:	e8 73 ac ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801058c7:	90                   	nop
801058c8:	8b 45 08             	mov    0x8(%ebp),%eax
801058cb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801058d2:	00 
801058d3:	89 04 24             	mov    %eax,(%esp)
801058d6:	e8 8b ff ff ff       	call   80105866 <xchg>
801058db:	85 c0                	test   %eax,%eax
801058dd:	75 e9                	jne    801058c8 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801058df:	8b 45 08             	mov    0x8(%ebp),%eax
801058e2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801058e9:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801058ec:	8b 45 08             	mov    0x8(%ebp),%eax
801058ef:	83 c0 0c             	add    $0xc,%eax
801058f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801058f6:	8d 45 08             	lea    0x8(%ebp),%eax
801058f9:	89 04 24             	mov    %eax,(%esp)
801058fc:	e8 51 00 00 00       	call   80105952 <getcallerpcs>
}
80105901:	c9                   	leave  
80105902:	c3                   	ret    

80105903 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105903:	55                   	push   %ebp
80105904:	89 e5                	mov    %esp,%ebp
80105906:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105909:	8b 45 08             	mov    0x8(%ebp),%eax
8010590c:	89 04 24             	mov    %eax,(%esp)
8010590f:	e8 b7 00 00 00       	call   801059cb <holding>
80105914:	85 c0                	test   %eax,%eax
80105916:	75 0c                	jne    80105924 <release+0x21>
    panic("release");
80105918:	c7 04 24 8d a0 10 80 	movl   $0x8010a08d,(%esp)
8010591f:	e8 16 ac ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105924:	8b 45 08             	mov    0x8(%ebp),%eax
80105927:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010592e:	8b 45 08             	mov    0x8(%ebp),%eax
80105931:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105938:	8b 45 08             	mov    0x8(%ebp),%eax
8010593b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105942:	00 
80105943:	89 04 24             	mov    %eax,(%esp)
80105946:	e8 1b ff ff ff       	call   80105866 <xchg>

  popcli();
8010594b:	e8 e9 00 00 00       	call   80105a39 <popcli>
}
80105950:	c9                   	leave  
80105951:	c3                   	ret    

80105952 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105952:	55                   	push   %ebp
80105953:	89 e5                	mov    %esp,%ebp
80105955:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105958:	8b 45 08             	mov    0x8(%ebp),%eax
8010595b:	83 e8 08             	sub    $0x8,%eax
8010595e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105961:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105968:	eb 38                	jmp    801059a2 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010596a:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010596e:	74 38                	je     801059a8 <getcallerpcs+0x56>
80105970:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105977:	76 2f                	jbe    801059a8 <getcallerpcs+0x56>
80105979:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010597d:	74 29                	je     801059a8 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010597f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105982:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105989:	8b 45 0c             	mov    0xc(%ebp),%eax
8010598c:	01 c2                	add    %eax,%edx
8010598e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105991:	8b 40 04             	mov    0x4(%eax),%eax
80105994:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105996:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105999:	8b 00                	mov    (%eax),%eax
8010599b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010599e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801059a2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801059a6:	7e c2                	jle    8010596a <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801059a8:	eb 19                	jmp    801059c3 <getcallerpcs+0x71>
    pcs[i] = 0;
801059aa:	8b 45 f8             	mov    -0x8(%ebp),%eax
801059ad:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801059b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801059b7:	01 d0                	add    %edx,%eax
801059b9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801059bf:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801059c3:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801059c7:	7e e1                	jle    801059aa <getcallerpcs+0x58>
    pcs[i] = 0;
}
801059c9:	c9                   	leave  
801059ca:	c3                   	ret    

801059cb <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801059cb:	55                   	push   %ebp
801059cc:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801059ce:	8b 45 08             	mov    0x8(%ebp),%eax
801059d1:	8b 00                	mov    (%eax),%eax
801059d3:	85 c0                	test   %eax,%eax
801059d5:	74 17                	je     801059ee <holding+0x23>
801059d7:	8b 45 08             	mov    0x8(%ebp),%eax
801059da:	8b 50 08             	mov    0x8(%eax),%edx
801059dd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059e3:	39 c2                	cmp    %eax,%edx
801059e5:	75 07                	jne    801059ee <holding+0x23>
801059e7:	b8 01 00 00 00       	mov    $0x1,%eax
801059ec:	eb 05                	jmp    801059f3 <holding+0x28>
801059ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801059f3:	5d                   	pop    %ebp
801059f4:	c3                   	ret    

801059f5 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801059f5:	55                   	push   %ebp
801059f6:	89 e5                	mov    %esp,%ebp
801059f8:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801059fb:	e8 4a fe ff ff       	call   8010584a <readeflags>
80105a00:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105a03:	e8 52 fe ff ff       	call   8010585a <cli>
  if(cpu->ncli++ == 0)
80105a08:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105a0f:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105a15:	8d 48 01             	lea    0x1(%eax),%ecx
80105a18:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105a1e:	85 c0                	test   %eax,%eax
80105a20:	75 15                	jne    80105a37 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105a22:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a28:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105a2b:	81 e2 00 02 00 00    	and    $0x200,%edx
80105a31:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105a37:	c9                   	leave  
80105a38:	c3                   	ret    

80105a39 <popcli>:

void
popcli(void)
{
80105a39:	55                   	push   %ebp
80105a3a:	89 e5                	mov    %esp,%ebp
80105a3c:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105a3f:	e8 06 fe ff ff       	call   8010584a <readeflags>
80105a44:	25 00 02 00 00       	and    $0x200,%eax
80105a49:	85 c0                	test   %eax,%eax
80105a4b:	74 0c                	je     80105a59 <popcli+0x20>
    panic("popcli - interruptible");
80105a4d:	c7 04 24 95 a0 10 80 	movl   $0x8010a095,(%esp)
80105a54:	e8 e1 aa ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105a59:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a5f:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105a65:	83 ea 01             	sub    $0x1,%edx
80105a68:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105a6e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a74:	85 c0                	test   %eax,%eax
80105a76:	79 0c                	jns    80105a84 <popcli+0x4b>
    panic("popcli");
80105a78:	c7 04 24 ac a0 10 80 	movl   $0x8010a0ac,(%esp)
80105a7f:	e8 b6 aa ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105a84:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a8a:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a90:	85 c0                	test   %eax,%eax
80105a92:	75 15                	jne    80105aa9 <popcli+0x70>
80105a94:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a9a:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105aa0:	85 c0                	test   %eax,%eax
80105aa2:	74 05                	je     80105aa9 <popcli+0x70>
    sti();
80105aa4:	e8 b7 fd ff ff       	call   80105860 <sti>
}
80105aa9:	c9                   	leave  
80105aaa:	c3                   	ret    

80105aab <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105aab:	55                   	push   %ebp
80105aac:	89 e5                	mov    %esp,%ebp
80105aae:	57                   	push   %edi
80105aaf:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105ab0:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105ab3:	8b 55 10             	mov    0x10(%ebp),%edx
80105ab6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ab9:	89 cb                	mov    %ecx,%ebx
80105abb:	89 df                	mov    %ebx,%edi
80105abd:	89 d1                	mov    %edx,%ecx
80105abf:	fc                   	cld    
80105ac0:	f3 aa                	rep stos %al,%es:(%edi)
80105ac2:	89 ca                	mov    %ecx,%edx
80105ac4:	89 fb                	mov    %edi,%ebx
80105ac6:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105ac9:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105acc:	5b                   	pop    %ebx
80105acd:	5f                   	pop    %edi
80105ace:	5d                   	pop    %ebp
80105acf:	c3                   	ret    

80105ad0 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105ad0:	55                   	push   %ebp
80105ad1:	89 e5                	mov    %esp,%ebp
80105ad3:	57                   	push   %edi
80105ad4:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105ad5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105ad8:	8b 55 10             	mov    0x10(%ebp),%edx
80105adb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ade:	89 cb                	mov    %ecx,%ebx
80105ae0:	89 df                	mov    %ebx,%edi
80105ae2:	89 d1                	mov    %edx,%ecx
80105ae4:	fc                   	cld    
80105ae5:	f3 ab                	rep stos %eax,%es:(%edi)
80105ae7:	89 ca                	mov    %ecx,%edx
80105ae9:	89 fb                	mov    %edi,%ebx
80105aeb:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105aee:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105af1:	5b                   	pop    %ebx
80105af2:	5f                   	pop    %edi
80105af3:	5d                   	pop    %ebp
80105af4:	c3                   	ret    

80105af5 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105af5:	55                   	push   %ebp
80105af6:	89 e5                	mov    %esp,%ebp
80105af8:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105afb:	8b 45 08             	mov    0x8(%ebp),%eax
80105afe:	83 e0 03             	and    $0x3,%eax
80105b01:	85 c0                	test   %eax,%eax
80105b03:	75 49                	jne    80105b4e <memset+0x59>
80105b05:	8b 45 10             	mov    0x10(%ebp),%eax
80105b08:	83 e0 03             	and    $0x3,%eax
80105b0b:	85 c0                	test   %eax,%eax
80105b0d:	75 3f                	jne    80105b4e <memset+0x59>
    c &= 0xFF;
80105b0f:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105b16:	8b 45 10             	mov    0x10(%ebp),%eax
80105b19:	c1 e8 02             	shr    $0x2,%eax
80105b1c:	89 c2                	mov    %eax,%edx
80105b1e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b21:	c1 e0 18             	shl    $0x18,%eax
80105b24:	89 c1                	mov    %eax,%ecx
80105b26:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b29:	c1 e0 10             	shl    $0x10,%eax
80105b2c:	09 c1                	or     %eax,%ecx
80105b2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b31:	c1 e0 08             	shl    $0x8,%eax
80105b34:	09 c8                	or     %ecx,%eax
80105b36:	0b 45 0c             	or     0xc(%ebp),%eax
80105b39:	89 54 24 08          	mov    %edx,0x8(%esp)
80105b3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b41:	8b 45 08             	mov    0x8(%ebp),%eax
80105b44:	89 04 24             	mov    %eax,(%esp)
80105b47:	e8 84 ff ff ff       	call   80105ad0 <stosl>
80105b4c:	eb 19                	jmp    80105b67 <memset+0x72>
  } else
    stosb(dst, c, n);
80105b4e:	8b 45 10             	mov    0x10(%ebp),%eax
80105b51:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b55:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b58:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b5c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b5f:	89 04 24             	mov    %eax,(%esp)
80105b62:	e8 44 ff ff ff       	call   80105aab <stosb>
  return dst;
80105b67:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b6a:	c9                   	leave  
80105b6b:	c3                   	ret    

80105b6c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105b6c:	55                   	push   %ebp
80105b6d:	89 e5                	mov    %esp,%ebp
80105b6f:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105b72:	8b 45 08             	mov    0x8(%ebp),%eax
80105b75:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105b78:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b7b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105b7e:	eb 30                	jmp    80105bb0 <memcmp+0x44>
    if(*s1 != *s2)
80105b80:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b83:	0f b6 10             	movzbl (%eax),%edx
80105b86:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b89:	0f b6 00             	movzbl (%eax),%eax
80105b8c:	38 c2                	cmp    %al,%dl
80105b8e:	74 18                	je     80105ba8 <memcmp+0x3c>
      return *s1 - *s2;
80105b90:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b93:	0f b6 00             	movzbl (%eax),%eax
80105b96:	0f b6 d0             	movzbl %al,%edx
80105b99:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b9c:	0f b6 00             	movzbl (%eax),%eax
80105b9f:	0f b6 c0             	movzbl %al,%eax
80105ba2:	29 c2                	sub    %eax,%edx
80105ba4:	89 d0                	mov    %edx,%eax
80105ba6:	eb 1a                	jmp    80105bc2 <memcmp+0x56>
    s1++, s2++;
80105ba8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105bac:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105bb0:	8b 45 10             	mov    0x10(%ebp),%eax
80105bb3:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bb6:	89 55 10             	mov    %edx,0x10(%ebp)
80105bb9:	85 c0                	test   %eax,%eax
80105bbb:	75 c3                	jne    80105b80 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105bbd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105bc2:	c9                   	leave  
80105bc3:	c3                   	ret    

80105bc4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105bc4:	55                   	push   %ebp
80105bc5:	89 e5                	mov    %esp,%ebp
80105bc7:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105bca:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bcd:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105bd0:	8b 45 08             	mov    0x8(%ebp),%eax
80105bd3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105bd6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bd9:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105bdc:	73 3d                	jae    80105c1b <memmove+0x57>
80105bde:	8b 45 10             	mov    0x10(%ebp),%eax
80105be1:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105be4:	01 d0                	add    %edx,%eax
80105be6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105be9:	76 30                	jbe    80105c1b <memmove+0x57>
    s += n;
80105beb:	8b 45 10             	mov    0x10(%ebp),%eax
80105bee:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105bf1:	8b 45 10             	mov    0x10(%ebp),%eax
80105bf4:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105bf7:	eb 13                	jmp    80105c0c <memmove+0x48>
      *--d = *--s;
80105bf9:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105bfd:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105c01:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c04:	0f b6 10             	movzbl (%eax),%edx
80105c07:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105c0a:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105c0c:	8b 45 10             	mov    0x10(%ebp),%eax
80105c0f:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c12:	89 55 10             	mov    %edx,0x10(%ebp)
80105c15:	85 c0                	test   %eax,%eax
80105c17:	75 e0                	jne    80105bf9 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105c19:	eb 26                	jmp    80105c41 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105c1b:	eb 17                	jmp    80105c34 <memmove+0x70>
      *d++ = *s++;
80105c1d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105c20:	8d 50 01             	lea    0x1(%eax),%edx
80105c23:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105c26:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c29:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c2c:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105c2f:	0f b6 12             	movzbl (%edx),%edx
80105c32:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105c34:	8b 45 10             	mov    0x10(%ebp),%eax
80105c37:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c3a:	89 55 10             	mov    %edx,0x10(%ebp)
80105c3d:	85 c0                	test   %eax,%eax
80105c3f:	75 dc                	jne    80105c1d <memmove+0x59>
      *d++ = *s++;

  return dst;
80105c41:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105c44:	c9                   	leave  
80105c45:	c3                   	ret    

80105c46 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105c46:	55                   	push   %ebp
80105c47:	89 e5                	mov    %esp,%ebp
80105c49:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105c4c:	8b 45 10             	mov    0x10(%ebp),%eax
80105c4f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c53:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c56:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c5a:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5d:	89 04 24             	mov    %eax,(%esp)
80105c60:	e8 5f ff ff ff       	call   80105bc4 <memmove>
}
80105c65:	c9                   	leave  
80105c66:	c3                   	ret    

80105c67 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105c67:	55                   	push   %ebp
80105c68:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105c6a:	eb 0c                	jmp    80105c78 <strncmp+0x11>
    n--, p++, q++;
80105c6c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c70:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105c74:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105c78:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c7c:	74 1a                	je     80105c98 <strncmp+0x31>
80105c7e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c81:	0f b6 00             	movzbl (%eax),%eax
80105c84:	84 c0                	test   %al,%al
80105c86:	74 10                	je     80105c98 <strncmp+0x31>
80105c88:	8b 45 08             	mov    0x8(%ebp),%eax
80105c8b:	0f b6 10             	movzbl (%eax),%edx
80105c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c91:	0f b6 00             	movzbl (%eax),%eax
80105c94:	38 c2                	cmp    %al,%dl
80105c96:	74 d4                	je     80105c6c <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105c98:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c9c:	75 07                	jne    80105ca5 <strncmp+0x3e>
    return 0;
80105c9e:	b8 00 00 00 00       	mov    $0x0,%eax
80105ca3:	eb 16                	jmp    80105cbb <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105ca5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ca8:	0f b6 00             	movzbl (%eax),%eax
80105cab:	0f b6 d0             	movzbl %al,%edx
80105cae:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cb1:	0f b6 00             	movzbl (%eax),%eax
80105cb4:	0f b6 c0             	movzbl %al,%eax
80105cb7:	29 c2                	sub    %eax,%edx
80105cb9:	89 d0                	mov    %edx,%eax
}
80105cbb:	5d                   	pop    %ebp
80105cbc:	c3                   	ret    

80105cbd <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105cbd:	55                   	push   %ebp
80105cbe:	89 e5                	mov    %esp,%ebp
80105cc0:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80105cc6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105cc9:	90                   	nop
80105cca:	8b 45 10             	mov    0x10(%ebp),%eax
80105ccd:	8d 50 ff             	lea    -0x1(%eax),%edx
80105cd0:	89 55 10             	mov    %edx,0x10(%ebp)
80105cd3:	85 c0                	test   %eax,%eax
80105cd5:	7e 1e                	jle    80105cf5 <strncpy+0x38>
80105cd7:	8b 45 08             	mov    0x8(%ebp),%eax
80105cda:	8d 50 01             	lea    0x1(%eax),%edx
80105cdd:	89 55 08             	mov    %edx,0x8(%ebp)
80105ce0:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ce3:	8d 4a 01             	lea    0x1(%edx),%ecx
80105ce6:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105ce9:	0f b6 12             	movzbl (%edx),%edx
80105cec:	88 10                	mov    %dl,(%eax)
80105cee:	0f b6 00             	movzbl (%eax),%eax
80105cf1:	84 c0                	test   %al,%al
80105cf3:	75 d5                	jne    80105cca <strncpy+0xd>
    ;
  while(n-- > 0)
80105cf5:	eb 0c                	jmp    80105d03 <strncpy+0x46>
    *s++ = 0;
80105cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80105cfa:	8d 50 01             	lea    0x1(%eax),%edx
80105cfd:	89 55 08             	mov    %edx,0x8(%ebp)
80105d00:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105d03:	8b 45 10             	mov    0x10(%ebp),%eax
80105d06:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d09:	89 55 10             	mov    %edx,0x10(%ebp)
80105d0c:	85 c0                	test   %eax,%eax
80105d0e:	7f e7                	jg     80105cf7 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105d10:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d13:	c9                   	leave  
80105d14:	c3                   	ret    

80105d15 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105d15:	55                   	push   %ebp
80105d16:	89 e5                	mov    %esp,%ebp
80105d18:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d1e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105d21:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d25:	7f 05                	jg     80105d2c <safestrcpy+0x17>
    return os;
80105d27:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d2a:	eb 31                	jmp    80105d5d <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105d2c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105d30:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d34:	7e 1e                	jle    80105d54 <safestrcpy+0x3f>
80105d36:	8b 45 08             	mov    0x8(%ebp),%eax
80105d39:	8d 50 01             	lea    0x1(%eax),%edx
80105d3c:	89 55 08             	mov    %edx,0x8(%ebp)
80105d3f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105d42:	8d 4a 01             	lea    0x1(%edx),%ecx
80105d45:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105d48:	0f b6 12             	movzbl (%edx),%edx
80105d4b:	88 10                	mov    %dl,(%eax)
80105d4d:	0f b6 00             	movzbl (%eax),%eax
80105d50:	84 c0                	test   %al,%al
80105d52:	75 d8                	jne    80105d2c <safestrcpy+0x17>
    ;
  *s = 0;
80105d54:	8b 45 08             	mov    0x8(%ebp),%eax
80105d57:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105d5a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d5d:	c9                   	leave  
80105d5e:	c3                   	ret    

80105d5f <strlen>:

int
strlen(const char *s)
{
80105d5f:	55                   	push   %ebp
80105d60:	89 e5                	mov    %esp,%ebp
80105d62:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105d65:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105d6c:	eb 04                	jmp    80105d72 <strlen+0x13>
80105d6e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d72:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d75:	8b 45 08             	mov    0x8(%ebp),%eax
80105d78:	01 d0                	add    %edx,%eax
80105d7a:	0f b6 00             	movzbl (%eax),%eax
80105d7d:	84 c0                	test   %al,%al
80105d7f:	75 ed                	jne    80105d6e <strlen+0xf>
    ;
  return n;
80105d81:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d84:	c9                   	leave  
80105d85:	c3                   	ret    

80105d86 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105d86:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105d8a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105d8e:	55                   	push   %ebp
  pushl %ebx
80105d8f:	53                   	push   %ebx
  pushl %esi
80105d90:	56                   	push   %esi
  pushl %edi
80105d91:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105d92:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105d94:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105d96:	5f                   	pop    %edi
  popl %esi
80105d97:	5e                   	pop    %esi
  popl %ebx
80105d98:	5b                   	pop    %ebx
  popl %ebp
80105d99:	5d                   	pop    %ebp
  ret
80105d9a:	c3                   	ret    

80105d9b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105d9b:	55                   	push   %ebp
80105d9c:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105d9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105da4:	8b 00                	mov    (%eax),%eax
80105da6:	3b 45 08             	cmp    0x8(%ebp),%eax
80105da9:	76 12                	jbe    80105dbd <fetchint+0x22>
80105dab:	8b 45 08             	mov    0x8(%ebp),%eax
80105dae:	8d 50 04             	lea    0x4(%eax),%edx
80105db1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105db7:	8b 00                	mov    (%eax),%eax
80105db9:	39 c2                	cmp    %eax,%edx
80105dbb:	76 07                	jbe    80105dc4 <fetchint+0x29>
    return -1;
80105dbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dc2:	eb 0f                	jmp    80105dd3 <fetchint+0x38>
  *ip = *(int*)(addr);
80105dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80105dc7:	8b 10                	mov    (%eax),%edx
80105dc9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dcc:	89 10                	mov    %edx,(%eax)
  return 0;
80105dce:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dd3:	5d                   	pop    %ebp
80105dd4:	c3                   	ret    

80105dd5 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105dd5:	55                   	push   %ebp
80105dd6:	89 e5                	mov    %esp,%ebp
80105dd8:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105ddb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105de1:	8b 00                	mov    (%eax),%eax
80105de3:	3b 45 08             	cmp    0x8(%ebp),%eax
80105de6:	77 07                	ja     80105def <fetchstr+0x1a>
    return -1;
80105de8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ded:	eb 46                	jmp    80105e35 <fetchstr+0x60>
  *pp = (char*)addr;
80105def:	8b 55 08             	mov    0x8(%ebp),%edx
80105df2:	8b 45 0c             	mov    0xc(%ebp),%eax
80105df5:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105df7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dfd:	8b 00                	mov    (%eax),%eax
80105dff:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105e02:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e05:	8b 00                	mov    (%eax),%eax
80105e07:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105e0a:	eb 1c                	jmp    80105e28 <fetchstr+0x53>
    if(*s == 0)
80105e0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e0f:	0f b6 00             	movzbl (%eax),%eax
80105e12:	84 c0                	test   %al,%al
80105e14:	75 0e                	jne    80105e24 <fetchstr+0x4f>
      return s - *pp;
80105e16:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e19:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e1c:	8b 00                	mov    (%eax),%eax
80105e1e:	29 c2                	sub    %eax,%edx
80105e20:	89 d0                	mov    %edx,%eax
80105e22:	eb 11                	jmp    80105e35 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105e24:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105e28:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e2b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105e2e:	72 dc                	jb     80105e0c <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105e30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e35:	c9                   	leave  
80105e36:	c3                   	ret    

80105e37 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105e37:	55                   	push   %ebp
80105e38:	89 e5                	mov    %esp,%ebp
80105e3a:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105e3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e43:	8b 40 18             	mov    0x18(%eax),%eax
80105e46:	8b 50 44             	mov    0x44(%eax),%edx
80105e49:	8b 45 08             	mov    0x8(%ebp),%eax
80105e4c:	c1 e0 02             	shl    $0x2,%eax
80105e4f:	01 d0                	add    %edx,%eax
80105e51:	8d 50 04             	lea    0x4(%eax),%edx
80105e54:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e57:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e5b:	89 14 24             	mov    %edx,(%esp)
80105e5e:	e8 38 ff ff ff       	call   80105d9b <fetchint>
}
80105e63:	c9                   	leave  
80105e64:	c3                   	ret    

80105e65 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105e65:	55                   	push   %ebp
80105e66:	89 e5                	mov    %esp,%ebp
80105e68:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105e6b:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e72:	8b 45 08             	mov    0x8(%ebp),%eax
80105e75:	89 04 24             	mov    %eax,(%esp)
80105e78:	e8 ba ff ff ff       	call   80105e37 <argint>
80105e7d:	85 c0                	test   %eax,%eax
80105e7f:	79 07                	jns    80105e88 <argptr+0x23>
    return -1;
80105e81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e86:	eb 3d                	jmp    80105ec5 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105e88:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e8b:	89 c2                	mov    %eax,%edx
80105e8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e93:	8b 00                	mov    (%eax),%eax
80105e95:	39 c2                	cmp    %eax,%edx
80105e97:	73 16                	jae    80105eaf <argptr+0x4a>
80105e99:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e9c:	89 c2                	mov    %eax,%edx
80105e9e:	8b 45 10             	mov    0x10(%ebp),%eax
80105ea1:	01 c2                	add    %eax,%edx
80105ea3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ea9:	8b 00                	mov    (%eax),%eax
80105eab:	39 c2                	cmp    %eax,%edx
80105ead:	76 07                	jbe    80105eb6 <argptr+0x51>
    return -1;
80105eaf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eb4:	eb 0f                	jmp    80105ec5 <argptr+0x60>
  *pp = (char*)i;
80105eb6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eb9:	89 c2                	mov    %eax,%edx
80105ebb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ebe:	89 10                	mov    %edx,(%eax)
  return 0;
80105ec0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ec5:	c9                   	leave  
80105ec6:	c3                   	ret    

80105ec7 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105ec7:	55                   	push   %ebp
80105ec8:	89 e5                	mov    %esp,%ebp
80105eca:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105ecd:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105ed0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed7:	89 04 24             	mov    %eax,(%esp)
80105eda:	e8 58 ff ff ff       	call   80105e37 <argint>
80105edf:	85 c0                	test   %eax,%eax
80105ee1:	79 07                	jns    80105eea <argstr+0x23>
    return -1;
80105ee3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ee8:	eb 12                	jmp    80105efc <argstr+0x35>
  return fetchstr(addr, pp);
80105eea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eed:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ef0:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ef4:	89 04 24             	mov    %eax,(%esp)
80105ef7:	e8 d9 fe ff ff       	call   80105dd5 <fetchstr>
}
80105efc:	c9                   	leave  
80105efd:	c3                   	ret    

80105efe <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105efe:	55                   	push   %ebp
80105eff:	89 e5                	mov    %esp,%ebp
80105f01:	53                   	push   %ebx
80105f02:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105f05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f0b:	8b 40 18             	mov    0x18(%eax),%eax
80105f0e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105f11:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105f14:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f18:	7e 30                	jle    80105f4a <syscall+0x4c>
80105f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f1d:	83 f8 15             	cmp    $0x15,%eax
80105f20:	77 28                	ja     80105f4a <syscall+0x4c>
80105f22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f25:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105f2c:	85 c0                	test   %eax,%eax
80105f2e:	74 1a                	je     80105f4a <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105f30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f36:	8b 58 18             	mov    0x18(%eax),%ebx
80105f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f3c:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105f43:	ff d0                	call   *%eax
80105f45:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105f48:	eb 3d                	jmp    80105f87 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105f4a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f50:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105f53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105f59:	8b 40 10             	mov    0x10(%eax),%eax
80105f5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105f63:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105f67:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f6b:	c7 04 24 b3 a0 10 80 	movl   $0x8010a0b3,(%esp)
80105f72:	e8 29 a4 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105f77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f7d:	8b 40 18             	mov    0x18(%eax),%eax
80105f80:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105f87:	83 c4 24             	add    $0x24,%esp
80105f8a:	5b                   	pop    %ebx
80105f8b:	5d                   	pop    %ebp
80105f8c:	c3                   	ret    

80105f8d <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105f8d:	55                   	push   %ebp
80105f8e:	89 e5                	mov    %esp,%ebp
80105f90:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105f93:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f96:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80105f9d:	89 04 24             	mov    %eax,(%esp)
80105fa0:	e8 92 fe ff ff       	call   80105e37 <argint>
80105fa5:	85 c0                	test   %eax,%eax
80105fa7:	79 07                	jns    80105fb0 <argfd+0x23>
    return -1;
80105fa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fae:	eb 50                	jmp    80106000 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb3:	85 c0                	test   %eax,%eax
80105fb5:	78 21                	js     80105fd8 <argfd+0x4b>
80105fb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fba:	83 f8 0f             	cmp    $0xf,%eax
80105fbd:	7f 19                	jg     80105fd8 <argfd+0x4b>
80105fbf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fc5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105fc8:	83 c2 08             	add    $0x8,%edx
80105fcb:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105fcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fd2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fd6:	75 07                	jne    80105fdf <argfd+0x52>
    return -1;
80105fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fdd:	eb 21                	jmp    80106000 <argfd+0x73>
  if(pfd)
80105fdf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105fe3:	74 08                	je     80105fed <argfd+0x60>
    *pfd = fd;
80105fe5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105feb:	89 10                	mov    %edx,(%eax)
  if(pf)
80105fed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ff1:	74 08                	je     80105ffb <argfd+0x6e>
    *pf = f;
80105ff3:	8b 45 10             	mov    0x10(%ebp),%eax
80105ff6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ff9:	89 10                	mov    %edx,(%eax)
  return 0;
80105ffb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106000:	c9                   	leave  
80106001:	c3                   	ret    

80106002 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106002:	55                   	push   %ebp
80106003:	89 e5                	mov    %esp,%ebp
80106005:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106008:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010600f:	eb 30                	jmp    80106041 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106011:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106017:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010601a:	83 c2 08             	add    $0x8,%edx
8010601d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106021:	85 c0                	test   %eax,%eax
80106023:	75 18                	jne    8010603d <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106025:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010602b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010602e:	8d 4a 08             	lea    0x8(%edx),%ecx
80106031:	8b 55 08             	mov    0x8(%ebp),%edx
80106034:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106038:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010603b:	eb 0f                	jmp    8010604c <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010603d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106041:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106045:	7e ca                	jle    80106011 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106047:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010604c:	c9                   	leave  
8010604d:	c3                   	ret    

8010604e <sys_dup>:

int
sys_dup(void)
{
8010604e:	55                   	push   %ebp
8010604f:	89 e5                	mov    %esp,%ebp
80106051:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106054:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106057:	89 44 24 08          	mov    %eax,0x8(%esp)
8010605b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106062:	00 
80106063:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010606a:	e8 1e ff ff ff       	call   80105f8d <argfd>
8010606f:	85 c0                	test   %eax,%eax
80106071:	79 07                	jns    8010607a <sys_dup+0x2c>
    return -1;
80106073:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106078:	eb 29                	jmp    801060a3 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010607a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607d:	89 04 24             	mov    %eax,(%esp)
80106080:	e8 7d ff ff ff       	call   80106002 <fdalloc>
80106085:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106088:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010608c:	79 07                	jns    80106095 <sys_dup+0x47>
    return -1;
8010608e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106093:	eb 0e                	jmp    801060a3 <sys_dup+0x55>
  filedup(f);
80106095:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106098:	89 04 24             	mov    %eax,(%esp)
8010609b:	e8 47 b0 ff ff       	call   801010e7 <filedup>
  return fd;
801060a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801060a3:	c9                   	leave  
801060a4:	c3                   	ret    

801060a5 <sys_read>:

int
sys_read(void)
{
801060a5:	55                   	push   %ebp
801060a6:	89 e5                	mov    %esp,%ebp
801060a8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801060ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060ae:	89 44 24 08          	mov    %eax,0x8(%esp)
801060b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060b9:	00 
801060ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060c1:	e8 c7 fe ff ff       	call   80105f8d <argfd>
801060c6:	85 c0                	test   %eax,%eax
801060c8:	78 35                	js     801060ff <sys_read+0x5a>
801060ca:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801060d1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801060d8:	e8 5a fd ff ff       	call   80105e37 <argint>
801060dd:	85 c0                	test   %eax,%eax
801060df:	78 1e                	js     801060ff <sys_read+0x5a>
801060e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060e4:	89 44 24 08          	mov    %eax,0x8(%esp)
801060e8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ef:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060f6:	e8 6a fd ff ff       	call   80105e65 <argptr>
801060fb:	85 c0                	test   %eax,%eax
801060fd:	79 07                	jns    80106106 <sys_read+0x61>
    return -1;
801060ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106104:	eb 19                	jmp    8010611f <sys_read+0x7a>
  return fileread(f, p, n);
80106106:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106109:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010610c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010610f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106113:	89 54 24 04          	mov    %edx,0x4(%esp)
80106117:	89 04 24             	mov    %eax,(%esp)
8010611a:	e8 35 b1 ff ff       	call   80101254 <fileread>
}
8010611f:	c9                   	leave  
80106120:	c3                   	ret    

80106121 <sys_write>:

int
sys_write(void)
{
80106121:	55                   	push   %ebp
80106122:	89 e5                	mov    %esp,%ebp
80106124:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106127:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010612a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010612e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106135:	00 
80106136:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010613d:	e8 4b fe ff ff       	call   80105f8d <argfd>
80106142:	85 c0                	test   %eax,%eax
80106144:	78 35                	js     8010617b <sys_write+0x5a>
80106146:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106149:	89 44 24 04          	mov    %eax,0x4(%esp)
8010614d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106154:	e8 de fc ff ff       	call   80105e37 <argint>
80106159:	85 c0                	test   %eax,%eax
8010615b:	78 1e                	js     8010617b <sys_write+0x5a>
8010615d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106160:	89 44 24 08          	mov    %eax,0x8(%esp)
80106164:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106167:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106172:	e8 ee fc ff ff       	call   80105e65 <argptr>
80106177:	85 c0                	test   %eax,%eax
80106179:	79 07                	jns    80106182 <sys_write+0x61>
    return -1;
8010617b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106180:	eb 19                	jmp    8010619b <sys_write+0x7a>
  return filewrite(f, p, n);
80106182:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106185:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106188:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010618f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106193:	89 04 24             	mov    %eax,(%esp)
80106196:	e8 75 b1 ff ff       	call   80101310 <filewrite>
}
8010619b:	c9                   	leave  
8010619c:	c3                   	ret    

8010619d <sys_close>:

int
sys_close(void)
{
8010619d:	55                   	push   %ebp
8010619e:	89 e5                	mov    %esp,%ebp
801061a0:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801061a3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061a6:	89 44 24 08          	mov    %eax,0x8(%esp)
801061aa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801061ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801061b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061b8:	e8 d0 fd ff ff       	call   80105f8d <argfd>
801061bd:	85 c0                	test   %eax,%eax
801061bf:	79 07                	jns    801061c8 <sys_close+0x2b>
    return -1;
801061c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c6:	eb 24                	jmp    801061ec <sys_close+0x4f>
  proc->ofile[fd] = 0;
801061c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061ce:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061d1:	83 c2 08             	add    $0x8,%edx
801061d4:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801061db:	00 
  fileclose(f);
801061dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061df:	89 04 24             	mov    %eax,(%esp)
801061e2:	e8 48 af ff ff       	call   8010112f <fileclose>
  return 0;
801061e7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061ec:	c9                   	leave  
801061ed:	c3                   	ret    

801061ee <sys_fstat>:

int
sys_fstat(void)
{
801061ee:	55                   	push   %ebp
801061ef:	89 e5                	mov    %esp,%ebp
801061f1:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801061f4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801061f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801061fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106202:	00 
80106203:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010620a:	e8 7e fd ff ff       	call   80105f8d <argfd>
8010620f:	85 c0                	test   %eax,%eax
80106211:	78 1f                	js     80106232 <sys_fstat+0x44>
80106213:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010621a:	00 
8010621b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010621e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106222:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106229:	e8 37 fc ff ff       	call   80105e65 <argptr>
8010622e:	85 c0                	test   %eax,%eax
80106230:	79 07                	jns    80106239 <sys_fstat+0x4b>
    return -1;
80106232:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106237:	eb 12                	jmp    8010624b <sys_fstat+0x5d>
  return filestat(f, st);
80106239:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010623c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010623f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106243:	89 04 24             	mov    %eax,(%esp)
80106246:	e8 ba af ff ff       	call   80101205 <filestat>
}
8010624b:	c9                   	leave  
8010624c:	c3                   	ret    

8010624d <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010624d:	55                   	push   %ebp
8010624e:	89 e5                	mov    %esp,%ebp
80106250:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106253:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106256:	89 44 24 04          	mov    %eax,0x4(%esp)
8010625a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106261:	e8 61 fc ff ff       	call   80105ec7 <argstr>
80106266:	85 c0                	test   %eax,%eax
80106268:	78 17                	js     80106281 <sys_link+0x34>
8010626a:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010626d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106271:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106278:	e8 4a fc ff ff       	call   80105ec7 <argstr>
8010627d:	85 c0                	test   %eax,%eax
8010627f:	79 0a                	jns    8010628b <sys_link+0x3e>
    return -1;
80106281:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106286:	e9 42 01 00 00       	jmp    801063cd <sys_link+0x180>

  begin_op();
8010628b:	e8 99 d9 ff ff       	call   80103c29 <begin_op>
  if((ip = namei(old)) == 0){
80106290:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106293:	89 04 24             	mov    %eax,(%esp)
80106296:	e8 30 c3 ff ff       	call   801025cb <namei>
8010629b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010629e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062a2:	75 0f                	jne    801062b3 <sys_link+0x66>
    end_op();
801062a4:	e8 04 da ff ff       	call   80103cad <end_op>
    return -1;
801062a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062ae:	e9 1a 01 00 00       	jmp    801063cd <sys_link+0x180>
  }

  ilock(ip);
801062b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b6:	89 04 24             	mov    %eax,(%esp)
801062b9:	e8 5c b7 ff ff       	call   80101a1a <ilock>
  if(ip->type == T_DIR){
801062be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801062c5:	66 83 f8 01          	cmp    $0x1,%ax
801062c9:	75 1a                	jne    801062e5 <sys_link+0x98>
    iunlockput(ip);
801062cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ce:	89 04 24             	mov    %eax,(%esp)
801062d1:	e8 ce b9 ff ff       	call   80101ca4 <iunlockput>
    end_op();
801062d6:	e8 d2 d9 ff ff       	call   80103cad <end_op>
    return -1;
801062db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062e0:	e9 e8 00 00 00       	jmp    801063cd <sys_link+0x180>
  }

  ip->nlink++;
801062e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062e8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062ec:	8d 50 01             	lea    0x1(%eax),%edx
801062ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f9:	89 04 24             	mov    %eax,(%esp)
801062fc:	e8 57 b5 ff ff       	call   80101858 <iupdate>
  iunlock(ip);
80106301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106304:	89 04 24             	mov    %eax,(%esp)
80106307:	e8 62 b8 ff ff       	call   80101b6e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010630c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010630f:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106312:	89 54 24 04          	mov    %edx,0x4(%esp)
80106316:	89 04 24             	mov    %eax,(%esp)
80106319:	e8 cf c2 ff ff       	call   801025ed <nameiparent>
8010631e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106321:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106325:	75 02                	jne    80106329 <sys_link+0xdc>
    goto bad;
80106327:	eb 68                	jmp    80106391 <sys_link+0x144>
  ilock(dp);
80106329:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010632c:	89 04 24             	mov    %eax,(%esp)
8010632f:	e8 e6 b6 ff ff       	call   80101a1a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106337:	8b 10                	mov    (%eax),%edx
80106339:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633c:	8b 00                	mov    (%eax),%eax
8010633e:	39 c2                	cmp    %eax,%edx
80106340:	75 20                	jne    80106362 <sys_link+0x115>
80106342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106345:	8b 40 04             	mov    0x4(%eax),%eax
80106348:	89 44 24 08          	mov    %eax,0x8(%esp)
8010634c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010634f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106353:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106356:	89 04 24             	mov    %eax,(%esp)
80106359:	e8 ad bf ff ff       	call   8010230b <dirlink>
8010635e:	85 c0                	test   %eax,%eax
80106360:	79 0d                	jns    8010636f <sys_link+0x122>
    iunlockput(dp);
80106362:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106365:	89 04 24             	mov    %eax,(%esp)
80106368:	e8 37 b9 ff ff       	call   80101ca4 <iunlockput>
    goto bad;
8010636d:	eb 22                	jmp    80106391 <sys_link+0x144>
  }
  iunlockput(dp);
8010636f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106372:	89 04 24             	mov    %eax,(%esp)
80106375:	e8 2a b9 ff ff       	call   80101ca4 <iunlockput>
  iput(ip);
8010637a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637d:	89 04 24             	mov    %eax,(%esp)
80106380:	e8 4e b8 ff ff       	call   80101bd3 <iput>

  end_op();
80106385:	e8 23 d9 ff ff       	call   80103cad <end_op>

  return 0;
8010638a:	b8 00 00 00 00       	mov    $0x0,%eax
8010638f:	eb 3c                	jmp    801063cd <sys_link+0x180>

bad:
  ilock(ip);
80106391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106394:	89 04 24             	mov    %eax,(%esp)
80106397:	e8 7e b6 ff ff       	call   80101a1a <ilock>
  ip->nlink--;
8010639c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063a3:	8d 50 ff             	lea    -0x1(%eax),%edx
801063a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a9:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801063ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b0:	89 04 24             	mov    %eax,(%esp)
801063b3:	e8 a0 b4 ff ff       	call   80101858 <iupdate>
  iunlockput(ip);
801063b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063bb:	89 04 24             	mov    %eax,(%esp)
801063be:	e8 e1 b8 ff ff       	call   80101ca4 <iunlockput>
  end_op();
801063c3:	e8 e5 d8 ff ff       	call   80103cad <end_op>
  return -1;
801063c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063cd:	c9                   	leave  
801063ce:	c3                   	ret    

801063cf <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
801063cf:	55                   	push   %ebp
801063d0:	89 e5                	mov    %esp,%ebp
801063d2:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801063d5:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801063dc:	eb 4b                	jmp    80106429 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801063de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801063e8:	00 
801063e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801063ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f4:	8b 45 08             	mov    0x8(%ebp),%eax
801063f7:	89 04 24             	mov    %eax,(%esp)
801063fa:	e8 2e bb ff ff       	call   80101f2d <readi>
801063ff:	83 f8 10             	cmp    $0x10,%eax
80106402:	74 0c                	je     80106410 <isdirempty+0x41>
      panic("isdirempty: readi");
80106404:	c7 04 24 cf a0 10 80 	movl   $0x8010a0cf,(%esp)
8010640b:	e8 2a a1 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106410:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106414:	66 85 c0             	test   %ax,%ax
80106417:	74 07                	je     80106420 <isdirempty+0x51>
      return 0;
80106419:	b8 00 00 00 00       	mov    $0x0,%eax
8010641e:	eb 1b                	jmp    8010643b <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106423:	83 c0 10             	add    $0x10,%eax
80106426:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106429:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010642c:	8b 45 08             	mov    0x8(%ebp),%eax
8010642f:	8b 40 18             	mov    0x18(%eax),%eax
80106432:	39 c2                	cmp    %eax,%edx
80106434:	72 a8                	jb     801063de <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106436:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010643b:	c9                   	leave  
8010643c:	c3                   	ret    

8010643d <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010643d:	55                   	push   %ebp
8010643e:	89 e5                	mov    %esp,%ebp
80106440:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106443:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106446:	89 44 24 04          	mov    %eax,0x4(%esp)
8010644a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106451:	e8 71 fa ff ff       	call   80105ec7 <argstr>
80106456:	85 c0                	test   %eax,%eax
80106458:	79 0a                	jns    80106464 <sys_unlink+0x27>
    return -1;
8010645a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010645f:	e9 af 01 00 00       	jmp    80106613 <sys_unlink+0x1d6>

  begin_op();
80106464:	e8 c0 d7 ff ff       	call   80103c29 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106469:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010646c:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010646f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106473:	89 04 24             	mov    %eax,(%esp)
80106476:	e8 72 c1 ff ff       	call   801025ed <nameiparent>
8010647b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010647e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106482:	75 0f                	jne    80106493 <sys_unlink+0x56>
    end_op();
80106484:	e8 24 d8 ff ff       	call   80103cad <end_op>
    return -1;
80106489:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648e:	e9 80 01 00 00       	jmp    80106613 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106496:	89 04 24             	mov    %eax,(%esp)
80106499:	e8 7c b5 ff ff       	call   80101a1a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010649e:	c7 44 24 04 e1 a0 10 	movl   $0x8010a0e1,0x4(%esp)
801064a5:	80 
801064a6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064a9:	89 04 24             	mov    %eax,(%esp)
801064ac:	e8 6f bd ff ff       	call   80102220 <namecmp>
801064b1:	85 c0                	test   %eax,%eax
801064b3:	0f 84 45 01 00 00    	je     801065fe <sys_unlink+0x1c1>
801064b9:	c7 44 24 04 e3 a0 10 	movl   $0x8010a0e3,0x4(%esp)
801064c0:	80 
801064c1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064c4:	89 04 24             	mov    %eax,(%esp)
801064c7:	e8 54 bd ff ff       	call   80102220 <namecmp>
801064cc:	85 c0                	test   %eax,%eax
801064ce:	0f 84 2a 01 00 00    	je     801065fe <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801064d4:	8d 45 c8             	lea    -0x38(%ebp),%eax
801064d7:	89 44 24 08          	mov    %eax,0x8(%esp)
801064db:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064de:	89 44 24 04          	mov    %eax,0x4(%esp)
801064e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064e5:	89 04 24             	mov    %eax,(%esp)
801064e8:	e8 55 bd ff ff       	call   80102242 <dirlookup>
801064ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064f4:	75 05                	jne    801064fb <sys_unlink+0xbe>
    goto bad;
801064f6:	e9 03 01 00 00       	jmp    801065fe <sys_unlink+0x1c1>
  ilock(ip);
801064fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064fe:	89 04 24             	mov    %eax,(%esp)
80106501:	e8 14 b5 ff ff       	call   80101a1a <ilock>

  if(ip->nlink < 1)
80106506:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106509:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010650d:	66 85 c0             	test   %ax,%ax
80106510:	7f 0c                	jg     8010651e <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106512:	c7 04 24 e6 a0 10 80 	movl   $0x8010a0e6,(%esp)
80106519:	e8 1c a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010651e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106521:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106525:	66 83 f8 01          	cmp    $0x1,%ax
80106529:	75 1f                	jne    8010654a <sys_unlink+0x10d>
8010652b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010652e:	89 04 24             	mov    %eax,(%esp)
80106531:	e8 99 fe ff ff       	call   801063cf <isdirempty>
80106536:	85 c0                	test   %eax,%eax
80106538:	75 10                	jne    8010654a <sys_unlink+0x10d>
    iunlockput(ip);
8010653a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010653d:	89 04 24             	mov    %eax,(%esp)
80106540:	e8 5f b7 ff ff       	call   80101ca4 <iunlockput>
    goto bad;
80106545:	e9 b4 00 00 00       	jmp    801065fe <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
8010654a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106551:	00 
80106552:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106559:	00 
8010655a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010655d:	89 04 24             	mov    %eax,(%esp)
80106560:	e8 90 f5 ff ff       	call   80105af5 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106565:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106568:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010656f:	00 
80106570:	89 44 24 08          	mov    %eax,0x8(%esp)
80106574:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106577:	89 44 24 04          	mov    %eax,0x4(%esp)
8010657b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010657e:	89 04 24             	mov    %eax,(%esp)
80106581:	e8 0b bb ff ff       	call   80102091 <writei>
80106586:	83 f8 10             	cmp    $0x10,%eax
80106589:	74 0c                	je     80106597 <sys_unlink+0x15a>
    panic("unlink: writei");
8010658b:	c7 04 24 f8 a0 10 80 	movl   $0x8010a0f8,(%esp)
80106592:	e8 a3 9f ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80106597:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010659a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010659e:	66 83 f8 01          	cmp    $0x1,%ax
801065a2:	75 1c                	jne    801065c0 <sys_unlink+0x183>
    dp->nlink--;
801065a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065ab:	8d 50 ff             	lea    -0x1(%eax),%edx
801065ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b1:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801065b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b8:	89 04 24             	mov    %eax,(%esp)
801065bb:	e8 98 b2 ff ff       	call   80101858 <iupdate>
  }
  iunlockput(dp);
801065c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c3:	89 04 24             	mov    %eax,(%esp)
801065c6:	e8 d9 b6 ff ff       	call   80101ca4 <iunlockput>

  ip->nlink--;
801065cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ce:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065d2:	8d 50 ff             	lea    -0x1(%eax),%edx
801065d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801065dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065df:	89 04 24             	mov    %eax,(%esp)
801065e2:	e8 71 b2 ff ff       	call   80101858 <iupdate>
  iunlockput(ip);
801065e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ea:	89 04 24             	mov    %eax,(%esp)
801065ed:	e8 b2 b6 ff ff       	call   80101ca4 <iunlockput>

  end_op();
801065f2:	e8 b6 d6 ff ff       	call   80103cad <end_op>

  return 0;
801065f7:	b8 00 00 00 00       	mov    $0x0,%eax
801065fc:	eb 15                	jmp    80106613 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801065fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106601:	89 04 24             	mov    %eax,(%esp)
80106604:	e8 9b b6 ff ff       	call   80101ca4 <iunlockput>
  end_op();
80106609:	e8 9f d6 ff ff       	call   80103cad <end_op>
  return -1;
8010660e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106613:	c9                   	leave  
80106614:	c3                   	ret    

80106615 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106615:	55                   	push   %ebp
80106616:	89 e5                	mov    %esp,%ebp
80106618:	83 ec 48             	sub    $0x48,%esp
8010661b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010661e:	8b 55 10             	mov    0x10(%ebp),%edx
80106621:	8b 45 14             	mov    0x14(%ebp),%eax
80106624:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106628:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
8010662c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106630:	8d 45 de             	lea    -0x22(%ebp),%eax
80106633:	89 44 24 04          	mov    %eax,0x4(%esp)
80106637:	8b 45 08             	mov    0x8(%ebp),%eax
8010663a:	89 04 24             	mov    %eax,(%esp)
8010663d:	e8 ab bf ff ff       	call   801025ed <nameiparent>
80106642:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106645:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106649:	75 0a                	jne    80106655 <create+0x40>
    return 0;
8010664b:	b8 00 00 00 00       	mov    $0x0,%eax
80106650:	e9 7e 01 00 00       	jmp    801067d3 <create+0x1be>
  ilock(dp);
80106655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106658:	89 04 24             	mov    %eax,(%esp)
8010665b:	e8 ba b3 ff ff       	call   80101a1a <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106660:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106663:	89 44 24 08          	mov    %eax,0x8(%esp)
80106667:	8d 45 de             	lea    -0x22(%ebp),%eax
8010666a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010666e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106671:	89 04 24             	mov    %eax,(%esp)
80106674:	e8 c9 bb ff ff       	call   80102242 <dirlookup>
80106679:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010667c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106680:	74 47                	je     801066c9 <create+0xb4>
    iunlockput(dp);
80106682:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106685:	89 04 24             	mov    %eax,(%esp)
80106688:	e8 17 b6 ff ff       	call   80101ca4 <iunlockput>
    ilock(ip);
8010668d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106690:	89 04 24             	mov    %eax,(%esp)
80106693:	e8 82 b3 ff ff       	call   80101a1a <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106698:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010669d:	75 15                	jne    801066b4 <create+0x9f>
8010669f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066a6:	66 83 f8 02          	cmp    $0x2,%ax
801066aa:	75 08                	jne    801066b4 <create+0x9f>
      return ip;
801066ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066af:	e9 1f 01 00 00       	jmp    801067d3 <create+0x1be>
    iunlockput(ip);
801066b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b7:	89 04 24             	mov    %eax,(%esp)
801066ba:	e8 e5 b5 ff ff       	call   80101ca4 <iunlockput>
    return 0;
801066bf:	b8 00 00 00 00       	mov    $0x0,%eax
801066c4:	e9 0a 01 00 00       	jmp    801067d3 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801066c9:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801066cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d0:	8b 00                	mov    (%eax),%eax
801066d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801066d6:	89 04 24             	mov    %eax,(%esp)
801066d9:	e8 a5 b0 ff ff       	call   80101783 <ialloc>
801066de:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066e1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066e5:	75 0c                	jne    801066f3 <create+0xde>
    panic("create: ialloc");
801066e7:	c7 04 24 07 a1 10 80 	movl   $0x8010a107,(%esp)
801066ee:	e8 47 9e ff ff       	call   8010053a <panic>

  ilock(ip);
801066f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066f6:	89 04 24             	mov    %eax,(%esp)
801066f9:	e8 1c b3 ff ff       	call   80101a1a <ilock>
  ip->major = major;
801066fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106701:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106705:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106709:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010670c:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106710:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106714:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106717:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
8010671d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106720:	89 04 24             	mov    %eax,(%esp)
80106723:	e8 30 b1 ff ff       	call   80101858 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106728:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010672d:	75 6a                	jne    80106799 <create+0x184>
    dp->nlink++;  // for ".."
8010672f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106732:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106736:	8d 50 01             	lea    0x1(%eax),%edx
80106739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010673c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106743:	89 04 24             	mov    %eax,(%esp)
80106746:	e8 0d b1 ff ff       	call   80101858 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010674b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010674e:	8b 40 04             	mov    0x4(%eax),%eax
80106751:	89 44 24 08          	mov    %eax,0x8(%esp)
80106755:	c7 44 24 04 e1 a0 10 	movl   $0x8010a0e1,0x4(%esp)
8010675c:	80 
8010675d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106760:	89 04 24             	mov    %eax,(%esp)
80106763:	e8 a3 bb ff ff       	call   8010230b <dirlink>
80106768:	85 c0                	test   %eax,%eax
8010676a:	78 21                	js     8010678d <create+0x178>
8010676c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010676f:	8b 40 04             	mov    0x4(%eax),%eax
80106772:	89 44 24 08          	mov    %eax,0x8(%esp)
80106776:	c7 44 24 04 e3 a0 10 	movl   $0x8010a0e3,0x4(%esp)
8010677d:	80 
8010677e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106781:	89 04 24             	mov    %eax,(%esp)
80106784:	e8 82 bb ff ff       	call   8010230b <dirlink>
80106789:	85 c0                	test   %eax,%eax
8010678b:	79 0c                	jns    80106799 <create+0x184>
      panic("create dots");
8010678d:	c7 04 24 16 a1 10 80 	movl   $0x8010a116,(%esp)
80106794:	e8 a1 9d ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106799:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010679c:	8b 40 04             	mov    0x4(%eax),%eax
8010679f:	89 44 24 08          	mov    %eax,0x8(%esp)
801067a3:	8d 45 de             	lea    -0x22(%ebp),%eax
801067a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801067aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ad:	89 04 24             	mov    %eax,(%esp)
801067b0:	e8 56 bb ff ff       	call   8010230b <dirlink>
801067b5:	85 c0                	test   %eax,%eax
801067b7:	79 0c                	jns    801067c5 <create+0x1b0>
    panic("create: dirlink");
801067b9:	c7 04 24 22 a1 10 80 	movl   $0x8010a122,(%esp)
801067c0:	e8 75 9d ff ff       	call   8010053a <panic>

  iunlockput(dp);
801067c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c8:	89 04 24             	mov    %eax,(%esp)
801067cb:	e8 d4 b4 ff ff       	call   80101ca4 <iunlockput>

  return ip;
801067d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801067d3:	c9                   	leave  
801067d4:	c3                   	ret    

801067d5 <sys_open>:

int
sys_open(void)
{
801067d5:	55                   	push   %ebp
801067d6:	89 e5                	mov    %esp,%ebp
801067d8:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801067db:	8d 45 e8             	lea    -0x18(%ebp),%eax
801067de:	89 44 24 04          	mov    %eax,0x4(%esp)
801067e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067e9:	e8 d9 f6 ff ff       	call   80105ec7 <argstr>
801067ee:	85 c0                	test   %eax,%eax
801067f0:	78 17                	js     80106809 <sys_open+0x34>
801067f2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801067f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801067f9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106800:	e8 32 f6 ff ff       	call   80105e37 <argint>
80106805:	85 c0                	test   %eax,%eax
80106807:	79 0a                	jns    80106813 <sys_open+0x3e>
    return -1;
80106809:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010680e:	e9 5c 01 00 00       	jmp    8010696f <sys_open+0x19a>

  begin_op();
80106813:	e8 11 d4 ff ff       	call   80103c29 <begin_op>

  if(omode & O_CREATE){
80106818:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010681b:	25 00 02 00 00       	and    $0x200,%eax
80106820:	85 c0                	test   %eax,%eax
80106822:	74 3b                	je     8010685f <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106824:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106827:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010682e:	00 
8010682f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106836:	00 
80106837:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010683e:	00 
8010683f:	89 04 24             	mov    %eax,(%esp)
80106842:	e8 ce fd ff ff       	call   80106615 <create>
80106847:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010684a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010684e:	75 6b                	jne    801068bb <sys_open+0xe6>
      end_op();
80106850:	e8 58 d4 ff ff       	call   80103cad <end_op>
      return -1;
80106855:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010685a:	e9 10 01 00 00       	jmp    8010696f <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010685f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106862:	89 04 24             	mov    %eax,(%esp)
80106865:	e8 61 bd ff ff       	call   801025cb <namei>
8010686a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010686d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106871:	75 0f                	jne    80106882 <sys_open+0xad>
      end_op();
80106873:	e8 35 d4 ff ff       	call   80103cad <end_op>
      return -1;
80106878:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010687d:	e9 ed 00 00 00       	jmp    8010696f <sys_open+0x19a>
    }
    ilock(ip);
80106882:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106885:	89 04 24             	mov    %eax,(%esp)
80106888:	e8 8d b1 ff ff       	call   80101a1a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010688d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106890:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106894:	66 83 f8 01          	cmp    $0x1,%ax
80106898:	75 21                	jne    801068bb <sys_open+0xe6>
8010689a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010689d:	85 c0                	test   %eax,%eax
8010689f:	74 1a                	je     801068bb <sys_open+0xe6>
      iunlockput(ip);
801068a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068a4:	89 04 24             	mov    %eax,(%esp)
801068a7:	e8 f8 b3 ff ff       	call   80101ca4 <iunlockput>
      end_op();
801068ac:	e8 fc d3 ff ff       	call   80103cad <end_op>
      return -1;
801068b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068b6:	e9 b4 00 00 00       	jmp    8010696f <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801068bb:	e8 c7 a7 ff ff       	call   80101087 <filealloc>
801068c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068c3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068c7:	74 14                	je     801068dd <sys_open+0x108>
801068c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068cc:	89 04 24             	mov    %eax,(%esp)
801068cf:	e8 2e f7 ff ff       	call   80106002 <fdalloc>
801068d4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801068d7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801068db:	79 28                	jns    80106905 <sys_open+0x130>
    if(f)
801068dd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068e1:	74 0b                	je     801068ee <sys_open+0x119>
      fileclose(f);
801068e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e6:	89 04 24             	mov    %eax,(%esp)
801068e9:	e8 41 a8 ff ff       	call   8010112f <fileclose>
    iunlockput(ip);
801068ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f1:	89 04 24             	mov    %eax,(%esp)
801068f4:	e8 ab b3 ff ff       	call   80101ca4 <iunlockput>
    end_op();
801068f9:	e8 af d3 ff ff       	call   80103cad <end_op>
    return -1;
801068fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106903:	eb 6a                	jmp    8010696f <sys_open+0x19a>
  }
  iunlock(ip);
80106905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106908:	89 04 24             	mov    %eax,(%esp)
8010690b:	e8 5e b2 ff ff       	call   80101b6e <iunlock>
  end_op();
80106910:	e8 98 d3 ff ff       	call   80103cad <end_op>

  f->type = FD_INODE;
80106915:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106918:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010691e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106921:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106924:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106927:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106931:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106934:	83 e0 01             	and    $0x1,%eax
80106937:	85 c0                	test   %eax,%eax
80106939:	0f 94 c0             	sete   %al
8010693c:	89 c2                	mov    %eax,%edx
8010693e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106941:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106944:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106947:	83 e0 01             	and    $0x1,%eax
8010694a:	85 c0                	test   %eax,%eax
8010694c:	75 0a                	jne    80106958 <sys_open+0x183>
8010694e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106951:	83 e0 02             	and    $0x2,%eax
80106954:	85 c0                	test   %eax,%eax
80106956:	74 07                	je     8010695f <sys_open+0x18a>
80106958:	b8 01 00 00 00       	mov    $0x1,%eax
8010695d:	eb 05                	jmp    80106964 <sys_open+0x18f>
8010695f:	b8 00 00 00 00       	mov    $0x0,%eax
80106964:	89 c2                	mov    %eax,%edx
80106966:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106969:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010696c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010696f:	c9                   	leave  
80106970:	c3                   	ret    

80106971 <sys_mkdir>:

int
sys_mkdir(void)
{
80106971:	55                   	push   %ebp
80106972:	89 e5                	mov    %esp,%ebp
80106974:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106977:	e8 ad d2 ff ff       	call   80103c29 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010697c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010697f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106983:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010698a:	e8 38 f5 ff ff       	call   80105ec7 <argstr>
8010698f:	85 c0                	test   %eax,%eax
80106991:	78 2c                	js     801069bf <sys_mkdir+0x4e>
80106993:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106996:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010699d:	00 
8010699e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069a5:	00 
801069a6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801069ad:	00 
801069ae:	89 04 24             	mov    %eax,(%esp)
801069b1:	e8 5f fc ff ff       	call   80106615 <create>
801069b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069bd:	75 0c                	jne    801069cb <sys_mkdir+0x5a>
    end_op();
801069bf:	e8 e9 d2 ff ff       	call   80103cad <end_op>
    return -1;
801069c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069c9:	eb 15                	jmp    801069e0 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801069cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ce:	89 04 24             	mov    %eax,(%esp)
801069d1:	e8 ce b2 ff ff       	call   80101ca4 <iunlockput>
  end_op();
801069d6:	e8 d2 d2 ff ff       	call   80103cad <end_op>
  return 0;
801069db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069e0:	c9                   	leave  
801069e1:	c3                   	ret    

801069e2 <sys_mknod>:

int
sys_mknod(void)
{
801069e2:	55                   	push   %ebp
801069e3:	89 e5                	mov    %esp,%ebp
801069e5:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801069e8:	e8 3c d2 ff ff       	call   80103c29 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801069ed:	8d 45 ec             	lea    -0x14(%ebp),%eax
801069f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801069f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069fb:	e8 c7 f4 ff ff       	call   80105ec7 <argstr>
80106a00:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a03:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a07:	78 5e                	js     80106a67 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106a09:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a10:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a17:	e8 1b f4 ff ff       	call   80105e37 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106a1c:	85 c0                	test   %eax,%eax
80106a1e:	78 47                	js     80106a67 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106a20:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106a23:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a27:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106a2e:	e8 04 f4 ff ff       	call   80105e37 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106a33:	85 c0                	test   %eax,%eax
80106a35:	78 30                	js     80106a67 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106a37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a3a:	0f bf c8             	movswl %ax,%ecx
80106a3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a40:	0f bf d0             	movswl %ax,%edx
80106a43:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106a46:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a4a:	89 54 24 08          	mov    %edx,0x8(%esp)
80106a4e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106a55:	00 
80106a56:	89 04 24             	mov    %eax,(%esp)
80106a59:	e8 b7 fb ff ff       	call   80106615 <create>
80106a5e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a61:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a65:	75 0c                	jne    80106a73 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106a67:	e8 41 d2 ff ff       	call   80103cad <end_op>
    return -1;
80106a6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a71:	eb 15                	jmp    80106a88 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106a73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a76:	89 04 24             	mov    %eax,(%esp)
80106a79:	e8 26 b2 ff ff       	call   80101ca4 <iunlockput>
  end_op();
80106a7e:	e8 2a d2 ff ff       	call   80103cad <end_op>
  return 0;
80106a83:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a88:	c9                   	leave  
80106a89:	c3                   	ret    

80106a8a <sys_chdir>:

int
sys_chdir(void)
{
80106a8a:	55                   	push   %ebp
80106a8b:	89 e5                	mov    %esp,%ebp
80106a8d:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106a90:	e8 94 d1 ff ff       	call   80103c29 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106a95:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a98:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a9c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106aa3:	e8 1f f4 ff ff       	call   80105ec7 <argstr>
80106aa8:	85 c0                	test   %eax,%eax
80106aaa:	78 14                	js     80106ac0 <sys_chdir+0x36>
80106aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aaf:	89 04 24             	mov    %eax,(%esp)
80106ab2:	e8 14 bb ff ff       	call   801025cb <namei>
80106ab7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106aba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106abe:	75 0c                	jne    80106acc <sys_chdir+0x42>
    end_op();
80106ac0:	e8 e8 d1 ff ff       	call   80103cad <end_op>
    return -1;
80106ac5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106aca:	eb 61                	jmp    80106b2d <sys_chdir+0xa3>
  }
  ilock(ip);
80106acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106acf:	89 04 24             	mov    %eax,(%esp)
80106ad2:	e8 43 af ff ff       	call   80101a1a <ilock>
  if(ip->type != T_DIR){
80106ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ada:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ade:	66 83 f8 01          	cmp    $0x1,%ax
80106ae2:	74 17                	je     80106afb <sys_chdir+0x71>
    iunlockput(ip);
80106ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ae7:	89 04 24             	mov    %eax,(%esp)
80106aea:	e8 b5 b1 ff ff       	call   80101ca4 <iunlockput>
    end_op();
80106aef:	e8 b9 d1 ff ff       	call   80103cad <end_op>
    return -1;
80106af4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106af9:	eb 32                	jmp    80106b2d <sys_chdir+0xa3>
  }
  iunlock(ip);
80106afb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106afe:	89 04 24             	mov    %eax,(%esp)
80106b01:	e8 68 b0 ff ff       	call   80101b6e <iunlock>
  iput(proc->cwd);
80106b06:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b0c:	8b 40 68             	mov    0x68(%eax),%eax
80106b0f:	89 04 24             	mov    %eax,(%esp)
80106b12:	e8 bc b0 ff ff       	call   80101bd3 <iput>
  end_op();
80106b17:	e8 91 d1 ff ff       	call   80103cad <end_op>
  proc->cwd = ip;
80106b1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b22:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b25:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106b28:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106b2d:	c9                   	leave  
80106b2e:	c3                   	ret    

80106b2f <sys_exec>:

int
sys_exec(void)
{
80106b2f:	55                   	push   %ebp
80106b30:	89 e5                	mov    %esp,%ebp
80106b32:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106b38:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b46:	e8 7c f3 ff ff       	call   80105ec7 <argstr>
80106b4b:	85 c0                	test   %eax,%eax
80106b4d:	78 1a                	js     80106b69 <sys_exec+0x3a>
80106b4f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106b55:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b59:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b60:	e8 d2 f2 ff ff       	call   80105e37 <argint>
80106b65:	85 c0                	test   %eax,%eax
80106b67:	79 0a                	jns    80106b73 <sys_exec+0x44>
    return -1;
80106b69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b6e:	e9 c8 00 00 00       	jmp    80106c3b <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106b73:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106b7a:	00 
80106b7b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b82:	00 
80106b83:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b89:	89 04 24             	mov    %eax,(%esp)
80106b8c:	e8 64 ef ff ff       	call   80105af5 <memset>
  for(i=0;; i++){
80106b91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b9b:	83 f8 1f             	cmp    $0x1f,%eax
80106b9e:	76 0a                	jbe    80106baa <sys_exec+0x7b>
      return -1;
80106ba0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba5:	e9 91 00 00 00       	jmp    80106c3b <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bad:	c1 e0 02             	shl    $0x2,%eax
80106bb0:	89 c2                	mov    %eax,%edx
80106bb2:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106bb8:	01 c2                	add    %eax,%edx
80106bba:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106bc0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bc4:	89 14 24             	mov    %edx,(%esp)
80106bc7:	e8 cf f1 ff ff       	call   80105d9b <fetchint>
80106bcc:	85 c0                	test   %eax,%eax
80106bce:	79 07                	jns    80106bd7 <sys_exec+0xa8>
      return -1;
80106bd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bd5:	eb 64                	jmp    80106c3b <sys_exec+0x10c>
    if(uarg == 0){
80106bd7:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106bdd:	85 c0                	test   %eax,%eax
80106bdf:	75 26                	jne    80106c07 <sys_exec+0xd8>
      argv[i] = 0;
80106be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106be4:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106beb:	00 00 00 00 
      break;
80106bef:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf3:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106bf9:	89 54 24 04          	mov    %edx,0x4(%esp)
80106bfd:	89 04 24             	mov    %eax,(%esp)
80106c00:	e8 05 9f ff ff       	call   80100b0a <exec>
80106c05:	eb 34                	jmp    80106c3b <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106c07:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106c0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c10:	c1 e2 02             	shl    $0x2,%edx
80106c13:	01 c2                	add    %eax,%edx
80106c15:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106c1b:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c1f:	89 04 24             	mov    %eax,(%esp)
80106c22:	e8 ae f1 ff ff       	call   80105dd5 <fetchstr>
80106c27:	85 c0                	test   %eax,%eax
80106c29:	79 07                	jns    80106c32 <sys_exec+0x103>
      return -1;
80106c2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c30:	eb 09                	jmp    80106c3b <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106c32:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106c36:	e9 5d ff ff ff       	jmp    80106b98 <sys_exec+0x69>
  return exec(path, argv);
}
80106c3b:	c9                   	leave  
80106c3c:	c3                   	ret    

80106c3d <sys_pipe>:

int
sys_pipe(void)
{
80106c3d:	55                   	push   %ebp
80106c3e:	89 e5                	mov    %esp,%ebp
80106c40:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106c43:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106c4a:	00 
80106c4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c59:	e8 07 f2 ff ff       	call   80105e65 <argptr>
80106c5e:	85 c0                	test   %eax,%eax
80106c60:	79 0a                	jns    80106c6c <sys_pipe+0x2f>
    return -1;
80106c62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c67:	e9 9b 00 00 00       	jmp    80106d07 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106c6c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106c6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c73:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106c76:	89 04 24             	mov    %eax,(%esp)
80106c79:	e8 b7 da ff ff       	call   80104735 <pipealloc>
80106c7e:	85 c0                	test   %eax,%eax
80106c80:	79 07                	jns    80106c89 <sys_pipe+0x4c>
    return -1;
80106c82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c87:	eb 7e                	jmp    80106d07 <sys_pipe+0xca>
  fd0 = -1;
80106c89:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106c90:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106c93:	89 04 24             	mov    %eax,(%esp)
80106c96:	e8 67 f3 ff ff       	call   80106002 <fdalloc>
80106c9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c9e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ca2:	78 14                	js     80106cb8 <sys_pipe+0x7b>
80106ca4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ca7:	89 04 24             	mov    %eax,(%esp)
80106caa:	e8 53 f3 ff ff       	call   80106002 <fdalloc>
80106caf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106cb2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106cb6:	79 37                	jns    80106cef <sys_pipe+0xb2>
    if(fd0 >= 0)
80106cb8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cbc:	78 14                	js     80106cd2 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106cbe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cc4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cc7:	83 c2 08             	add    $0x8,%edx
80106cca:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106cd1:	00 
    fileclose(rf);
80106cd2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106cd5:	89 04 24             	mov    %eax,(%esp)
80106cd8:	e8 52 a4 ff ff       	call   8010112f <fileclose>
    fileclose(wf);
80106cdd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ce0:	89 04 24             	mov    %eax,(%esp)
80106ce3:	e8 47 a4 ff ff       	call   8010112f <fileclose>
    return -1;
80106ce8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ced:	eb 18                	jmp    80106d07 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106cef:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106cf2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cf5:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106cfa:	8d 50 04             	lea    0x4(%eax),%edx
80106cfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d00:	89 02                	mov    %eax,(%edx)
  return 0;
80106d02:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d07:	c9                   	leave  
80106d08:	c3                   	ret    

80106d09 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106d09:	55                   	push   %ebp
80106d0a:	89 e5                	mov    %esp,%ebp
80106d0c:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106d0f:	e8 1e e2 ff ff       	call   80104f32 <fork>
}
80106d14:	c9                   	leave  
80106d15:	c3                   	ret    

80106d16 <sys_exit>:

int
sys_exit(void)
{
80106d16:	55                   	push   %ebp
80106d17:	89 e5                	mov    %esp,%ebp
80106d19:	83 ec 08             	sub    $0x8,%esp
  exit();
80106d1c:	e8 04 e4 ff ff       	call   80105125 <exit>
  return 0;  // not reached
80106d21:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d26:	c9                   	leave  
80106d27:	c3                   	ret    

80106d28 <sys_wait>:

int
sys_wait(void)
{
80106d28:	55                   	push   %ebp
80106d29:	89 e5                	mov    %esp,%ebp
80106d2b:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106d2e:	e8 2a e5 ff ff       	call   8010525d <wait>
}
80106d33:	c9                   	leave  
80106d34:	c3                   	ret    

80106d35 <sys_kill>:

int
sys_kill(void)
{
80106d35:	55                   	push   %ebp
80106d36:	89 e5                	mov    %esp,%ebp
80106d38:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106d3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d42:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d49:	e8 e9 f0 ff ff       	call   80105e37 <argint>
80106d4e:	85 c0                	test   %eax,%eax
80106d50:	79 07                	jns    80106d59 <sys_kill+0x24>
    return -1;
80106d52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d57:	eb 0b                	jmp    80106d64 <sys_kill+0x2f>
  return kill(pid);
80106d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d5c:	89 04 24             	mov    %eax,(%esp)
80106d5f:	e8 d7 e8 ff ff       	call   8010563b <kill>
}
80106d64:	c9                   	leave  
80106d65:	c3                   	ret    

80106d66 <sys_getpid>:

int
sys_getpid(void)
{
80106d66:	55                   	push   %ebp
80106d67:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106d69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d6f:	8b 40 10             	mov    0x10(%eax),%eax
}
80106d72:	5d                   	pop    %ebp
80106d73:	c3                   	ret    

80106d74 <sys_sbrk>:

int
sys_sbrk(void)
{
80106d74:	55                   	push   %ebp
80106d75:	89 e5                	mov    %esp,%ebp
80106d77:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106d7a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d88:	e8 aa f0 ff ff       	call   80105e37 <argint>
80106d8d:	85 c0                	test   %eax,%eax
80106d8f:	79 07                	jns    80106d98 <sys_sbrk+0x24>
    return -1;
80106d91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d96:	eb 24                	jmp    80106dbc <sys_sbrk+0x48>
  addr = proc->sz;
80106d98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d9e:	8b 00                	mov    (%eax),%eax
80106da0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106da3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106da6:	89 04 24             	mov    %eax,(%esp)
80106da9:	e8 c9 e0 ff ff       	call   80104e77 <growproc>
80106dae:	85 c0                	test   %eax,%eax
80106db0:	79 07                	jns    80106db9 <sys_sbrk+0x45>
    return -1;
80106db2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106db7:	eb 03                	jmp    80106dbc <sys_sbrk+0x48>
  return addr;
80106db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106dbc:	c9                   	leave  
80106dbd:	c3                   	ret    

80106dbe <sys_sleep>:

int
sys_sleep(void)
{
80106dbe:	55                   	push   %ebp
80106dbf:	89 e5                	mov    %esp,%ebp
80106dc1:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106dc4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106dc7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dcb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dd2:	e8 60 f0 ff ff       	call   80105e37 <argint>
80106dd7:	85 c0                	test   %eax,%eax
80106dd9:	79 07                	jns    80106de2 <sys_sleep+0x24>
    return -1;
80106ddb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106de0:	eb 6c                	jmp    80106e4e <sys_sleep+0x90>
  acquire(&tickslock);
80106de2:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106de9:	e8 b3 ea ff ff       	call   801058a1 <acquire>
  ticks0 = ticks;
80106dee:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106df3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106df6:	eb 34                	jmp    80106e2c <sys_sleep+0x6e>
    if(proc->killed){
80106df8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106dfe:	8b 40 24             	mov    0x24(%eax),%eax
80106e01:	85 c0                	test   %eax,%eax
80106e03:	74 13                	je     80106e18 <sys_sleep+0x5a>
      release(&tickslock);
80106e05:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106e0c:	e8 f2 ea ff ff       	call   80105903 <release>
      return -1;
80106e11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e16:	eb 36                	jmp    80106e4e <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106e18:	c7 44 24 04 c0 05 12 	movl   $0x801205c0,0x4(%esp)
80106e1f:	80 
80106e20:	c7 04 24 00 0e 12 80 	movl   $0x80120e00,(%esp)
80106e27:	e8 08 e7 ff ff       	call   80105534 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106e2c:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106e31:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106e34:	89 c2                	mov    %eax,%edx
80106e36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e39:	39 c2                	cmp    %eax,%edx
80106e3b:	72 bb                	jb     80106df8 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106e3d:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106e44:	e8 ba ea ff ff       	call   80105903 <release>
  return 0;
80106e49:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e4e:	c9                   	leave  
80106e4f:	c3                   	ret    

80106e50 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106e50:	55                   	push   %ebp
80106e51:	89 e5                	mov    %esp,%ebp
80106e53:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106e56:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106e5d:	e8 3f ea ff ff       	call   801058a1 <acquire>
  xticks = ticks;
80106e62:	a1 00 0e 12 80       	mov    0x80120e00,%eax
80106e67:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106e6a:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80106e71:	e8 8d ea ff ff       	call   80105903 <release>
  return xticks;
80106e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e79:	c9                   	leave  
80106e7a:	c3                   	ret    

80106e7b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106e7b:	55                   	push   %ebp
80106e7c:	89 e5                	mov    %esp,%ebp
80106e7e:	83 ec 08             	sub    $0x8,%esp
80106e81:	8b 55 08             	mov    0x8(%ebp),%edx
80106e84:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e87:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106e8b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106e8e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106e92:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106e96:	ee                   	out    %al,(%dx)
}
80106e97:	c9                   	leave  
80106e98:	c3                   	ret    

80106e99 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106e99:	55                   	push   %ebp
80106e9a:	89 e5                	mov    %esp,%ebp
80106e9c:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106e9f:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106ea6:	00 
80106ea7:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106eae:	e8 c8 ff ff ff       	call   80106e7b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106eb3:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106eba:	00 
80106ebb:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106ec2:	e8 b4 ff ff ff       	call   80106e7b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106ec7:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106ece:	00 
80106ecf:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106ed6:	e8 a0 ff ff ff       	call   80106e7b <outb>
  picenable(IRQ_TIMER);
80106edb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ee2:	e8 e1 d6 ff ff       	call   801045c8 <picenable>
}
80106ee7:	c9                   	leave  
80106ee8:	c3                   	ret    

80106ee9 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106ee9:	1e                   	push   %ds
  pushl %es
80106eea:	06                   	push   %es
  pushl %fs
80106eeb:	0f a0                	push   %fs
  pushl %gs
80106eed:	0f a8                	push   %gs
  pushal
80106eef:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106ef0:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106ef4:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106ef6:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106ef8:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106efc:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106efe:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106f00:	54                   	push   %esp
  call trap
80106f01:	e8 d8 01 00 00       	call   801070de <trap>
  addl $4, %esp
80106f06:	83 c4 04             	add    $0x4,%esp

80106f09 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106f09:	61                   	popa   
  popl %gs
80106f0a:	0f a9                	pop    %gs
  popl %fs
80106f0c:	0f a1                	pop    %fs
  popl %es
80106f0e:	07                   	pop    %es
  popl %ds
80106f0f:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106f10:	83 c4 08             	add    $0x8,%esp
  iret
80106f13:	cf                   	iret   

80106f14 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106f14:	55                   	push   %ebp
80106f15:	89 e5                	mov    %esp,%ebp
80106f17:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106f1a:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f1d:	83 e8 01             	sub    $0x1,%eax
80106f20:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106f24:	8b 45 08             	mov    0x8(%ebp),%eax
80106f27:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106f2b:	8b 45 08             	mov    0x8(%ebp),%eax
80106f2e:	c1 e8 10             	shr    $0x10,%eax
80106f31:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106f35:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106f38:	0f 01 18             	lidtl  (%eax)
}
80106f3b:	c9                   	leave  
80106f3c:	c3                   	ret    

80106f3d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106f3d:	55                   	push   %ebp
80106f3e:	89 e5                	mov    %esp,%ebp
80106f40:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106f43:	0f 20 d0             	mov    %cr2,%eax
80106f46:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106f49:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106f4c:	c9                   	leave  
80106f4d:	c3                   	ret    

80106f4e <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106f4e:	55                   	push   %ebp
80106f4f:	89 e5                	mov    %esp,%ebp
80106f51:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106f54:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106f5b:	e9 c3 00 00 00       	jmp    80107023 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f63:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f6a:	89 c2                	mov    %eax,%edx
80106f6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f6f:	66 89 14 c5 00 06 12 	mov    %dx,-0x7fedfa00(,%eax,8)
80106f76:	80 
80106f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f7a:	66 c7 04 c5 02 06 12 	movw   $0x8,-0x7fedf9fe(,%eax,8)
80106f81:	80 08 00 
80106f84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f87:	0f b6 14 c5 04 06 12 	movzbl -0x7fedf9fc(,%eax,8),%edx
80106f8e:	80 
80106f8f:	83 e2 e0             	and    $0xffffffe0,%edx
80106f92:	88 14 c5 04 06 12 80 	mov    %dl,-0x7fedf9fc(,%eax,8)
80106f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f9c:	0f b6 14 c5 04 06 12 	movzbl -0x7fedf9fc(,%eax,8),%edx
80106fa3:	80 
80106fa4:	83 e2 1f             	and    $0x1f,%edx
80106fa7:	88 14 c5 04 06 12 80 	mov    %dl,-0x7fedf9fc(,%eax,8)
80106fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fb1:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106fb8:	80 
80106fb9:	83 e2 f0             	and    $0xfffffff0,%edx
80106fbc:	83 ca 0e             	or     $0xe,%edx
80106fbf:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fc9:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106fd0:	80 
80106fd1:	83 e2 ef             	and    $0xffffffef,%edx
80106fd4:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106fdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fde:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106fe5:	80 
80106fe6:	83 e2 9f             	and    $0xffffff9f,%edx
80106fe9:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80106ff0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ff3:	0f b6 14 c5 05 06 12 	movzbl -0x7fedf9fb(,%eax,8),%edx
80106ffa:	80 
80106ffb:	83 ca 80             	or     $0xffffff80,%edx
80106ffe:	88 14 c5 05 06 12 80 	mov    %dl,-0x7fedf9fb(,%eax,8)
80107005:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107008:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
8010700f:	c1 e8 10             	shr    $0x10,%eax
80107012:	89 c2                	mov    %eax,%edx
80107014:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107017:	66 89 14 c5 06 06 12 	mov    %dx,-0x7fedf9fa(,%eax,8)
8010701e:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010701f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107023:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010702a:	0f 8e 30 ff ff ff    	jle    80106f60 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107030:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80107035:	66 a3 00 08 12 80    	mov    %ax,0x80120800
8010703b:	66 c7 05 02 08 12 80 	movw   $0x8,0x80120802
80107042:	08 00 
80107044:	0f b6 05 04 08 12 80 	movzbl 0x80120804,%eax
8010704b:	83 e0 e0             	and    $0xffffffe0,%eax
8010704e:	a2 04 08 12 80       	mov    %al,0x80120804
80107053:	0f b6 05 04 08 12 80 	movzbl 0x80120804,%eax
8010705a:	83 e0 1f             	and    $0x1f,%eax
8010705d:	a2 04 08 12 80       	mov    %al,0x80120804
80107062:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80107069:	83 c8 0f             	or     $0xf,%eax
8010706c:	a2 05 08 12 80       	mov    %al,0x80120805
80107071:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80107078:	83 e0 ef             	and    $0xffffffef,%eax
8010707b:	a2 05 08 12 80       	mov    %al,0x80120805
80107080:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80107087:	83 c8 60             	or     $0x60,%eax
8010708a:	a2 05 08 12 80       	mov    %al,0x80120805
8010708f:	0f b6 05 05 08 12 80 	movzbl 0x80120805,%eax
80107096:	83 c8 80             	or     $0xffffff80,%eax
80107099:	a2 05 08 12 80       	mov    %al,0x80120805
8010709e:	a1 98 d1 10 80       	mov    0x8010d198,%eax
801070a3:	c1 e8 10             	shr    $0x10,%eax
801070a6:	66 a3 06 08 12 80    	mov    %ax,0x80120806
  
  initlock(&tickslock, "time");
801070ac:	c7 44 24 04 34 a1 10 	movl   $0x8010a134,0x4(%esp)
801070b3:	80 
801070b4:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
801070bb:	e8 c0 e7 ff ff       	call   80105880 <initlock>
}
801070c0:	c9                   	leave  
801070c1:	c3                   	ret    

801070c2 <idtinit>:

void
idtinit(void)
{
801070c2:	55                   	push   %ebp
801070c3:	89 e5                	mov    %esp,%ebp
801070c5:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801070c8:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801070cf:	00 
801070d0:	c7 04 24 00 06 12 80 	movl   $0x80120600,(%esp)
801070d7:	e8 38 fe ff ff       	call   80106f14 <lidt>
}
801070dc:	c9                   	leave  
801070dd:	c3                   	ret    

801070de <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801070de:	55                   	push   %ebp
801070df:	89 e5                	mov    %esp,%ebp
801070e1:	57                   	push   %edi
801070e2:	56                   	push   %esi
801070e3:	53                   	push   %ebx
801070e4:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801070e7:	8b 45 08             	mov    0x8(%ebp),%eax
801070ea:	8b 40 30             	mov    0x30(%eax),%eax
801070ed:	83 f8 40             	cmp    $0x40,%eax
801070f0:	75 3f                	jne    80107131 <trap+0x53>
    if(proc->killed)
801070f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070f8:	8b 40 24             	mov    0x24(%eax),%eax
801070fb:	85 c0                	test   %eax,%eax
801070fd:	74 05                	je     80107104 <trap+0x26>
      exit();
801070ff:	e8 21 e0 ff ff       	call   80105125 <exit>
    proc->tf = tf;
80107104:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010710a:	8b 55 08             	mov    0x8(%ebp),%edx
8010710d:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107110:	e8 e9 ed ff ff       	call   80105efe <syscall>
    if(proc->killed)
80107115:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010711b:	8b 40 24             	mov    0x24(%eax),%eax
8010711e:	85 c0                	test   %eax,%eax
80107120:	74 0a                	je     8010712c <trap+0x4e>
      exit();
80107122:	e8 fe df ff ff       	call   80105125 <exit>
    return;
80107127:	e9 d3 02 00 00       	jmp    801073ff <trap+0x321>
8010712c:	e9 ce 02 00 00       	jmp    801073ff <trap+0x321>
  }
  switch(tf->trapno){
80107131:	8b 45 08             	mov    0x8(%ebp),%eax
80107134:	8b 40 30             	mov    0x30(%eax),%eax
80107137:	83 e8 0e             	sub    $0xe,%eax
8010713a:	83 f8 31             	cmp    $0x31,%eax
8010713d:	0f 87 54 01 00 00    	ja     80107297 <trap+0x1b9>
80107143:	8b 04 85 34 a2 10 80 	mov    -0x7fef5dcc(,%eax,4),%eax
8010714a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010714c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107152:	0f b6 00             	movzbl (%eax),%eax
80107155:	84 c0                	test   %al,%al
80107157:	75 31                	jne    8010718a <trap+0xac>
      acquire(&tickslock);
80107159:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80107160:	e8 3c e7 ff ff       	call   801058a1 <acquire>
      ticks++;
80107165:	a1 00 0e 12 80       	mov    0x80120e00,%eax
8010716a:	83 c0 01             	add    $0x1,%eax
8010716d:	a3 00 0e 12 80       	mov    %eax,0x80120e00
      wakeup(&ticks);
80107172:	c7 04 24 00 0e 12 80 	movl   $0x80120e00,(%esp)
80107179:	e8 92 e4 ff ff       	call   80105610 <wakeup>
      release(&tickslock);
8010717e:	c7 04 24 c0 05 12 80 	movl   $0x801205c0,(%esp)
80107185:	e8 79 e7 ff ff       	call   80105903 <release>
    }
    lapiceoi();
8010718a:	e8 64 c5 ff ff       	call   801036f3 <lapiceoi>
    break;
8010718f:	e9 d9 01 00 00       	jmp    8010736d <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107194:	e8 f9 bc ff ff       	call   80102e92 <ideintr>
    lapiceoi();
80107199:	e8 55 c5 ff ff       	call   801036f3 <lapiceoi>
    break;
8010719e:	e9 ca 01 00 00       	jmp    8010736d <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801071a3:	e8 1a c3 ff ff       	call   801034c2 <kbdintr>
    lapiceoi();
801071a8:	e8 46 c5 ff ff       	call   801036f3 <lapiceoi>
    break;
801071ad:	e9 bb 01 00 00       	jmp    8010736d <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801071b2:	e8 3d 04 00 00       	call   801075f4 <uartintr>
    lapiceoi();
801071b7:	e8 37 c5 ff ff       	call   801036f3 <lapiceoi>
    break;
801071bc:	e9 ac 01 00 00       	jmp    8010736d <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801071c1:	8b 45 08             	mov    0x8(%ebp),%eax
801071c4:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801071c7:	8b 45 08             	mov    0x8(%ebp),%eax
801071ca:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801071ce:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801071d1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801071d7:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801071da:	0f b6 c0             	movzbl %al,%eax
801071dd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801071e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801071e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801071e9:	c7 04 24 3c a1 10 80 	movl   $0x8010a13c,(%esp)
801071f0:	e8 ab 91 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801071f5:	e8 f9 c4 ff ff       	call   801036f3 <lapiceoi>
    break;
801071fa:	e9 6e 01 00 00       	jmp    8010736d <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
801071ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107205:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
8010720b:	83 c2 01             	add    $0x1,%edx
8010720e:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
80107214:	e8 24 fd ff ff       	call   80106f3d <rcr2>
80107219:	05 ff 0f 00 00       	add    $0xfff,%eax
8010721e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107223:	89 c6                	mov    %eax,%esi
80107225:	e8 13 fd ff ff       	call   80106f3d <rcr2>
8010722a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010722f:	89 c3                	mov    %eax,%ebx
80107231:	e8 07 fd ff ff       	call   80106f3d <rcr2>
80107236:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010723d:	8b 52 10             	mov    0x10(%edx),%edx
80107240:	89 74 24 10          	mov    %esi,0x10(%esp)
80107244:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107248:	89 44 24 08          	mov    %eax,0x8(%esp)
8010724c:	89 54 24 04          	mov    %edx,0x4(%esp)
80107250:	c7 04 24 60 a1 10 80 	movl   $0x8010a160,(%esp)
80107257:	e8 44 91 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
8010725c:	e8 dc fc ff ff       	call   80106f3d <rcr2>
80107261:	89 04 24             	mov    %eax,(%esp)
80107264:	e8 eb 21 00 00       	call   80109454 <existOnDisc>
80107269:	85 c0                	test   %eax,%eax
8010726b:	74 2a                	je     80107297 <trap+0x1b9>
      cprintf("found on disk, recovering\n");
8010726d:	c7 04 24 8f a1 10 80 	movl   $0x8010a18f,(%esp)
80107274:	e8 27 91 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
80107279:	e8 bf fc ff ff       	call   80106f3d <rcr2>
8010727e:	89 04 24             	mov    %eax,(%esp)
80107281:	e8 ba 22 00 00       	call   80109540 <fixPage>
      cprintf("recovered!\n");
80107286:	c7 04 24 aa a1 10 80 	movl   $0x8010a1aa,(%esp)
8010728d:	e8 0e 91 ff ff       	call   801003a0 <cprintf>
      break;
80107292:	e9 d6 00 00 00       	jmp    8010736d <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107297:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010729d:	85 c0                	test   %eax,%eax
8010729f:	74 11                	je     801072b2 <trap+0x1d4>
801072a1:	8b 45 08             	mov    0x8(%ebp),%eax
801072a4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072a8:	0f b7 c0             	movzwl %ax,%eax
801072ab:	83 e0 03             	and    $0x3,%eax
801072ae:	85 c0                	test   %eax,%eax
801072b0:	75 46                	jne    801072f8 <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801072b2:	e8 86 fc ff ff       	call   80106f3d <rcr2>
801072b7:	8b 55 08             	mov    0x8(%ebp),%edx
801072ba:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801072bd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801072c4:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801072c7:	0f b6 ca             	movzbl %dl,%ecx
801072ca:	8b 55 08             	mov    0x8(%ebp),%edx
801072cd:	8b 52 30             	mov    0x30(%edx),%edx
801072d0:	89 44 24 10          	mov    %eax,0x10(%esp)
801072d4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801072d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801072dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801072e0:	c7 04 24 b8 a1 10 80 	movl   $0x8010a1b8,(%esp)
801072e7:	e8 b4 90 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801072ec:	c7 04 24 ea a1 10 80 	movl   $0x8010a1ea,(%esp)
801072f3:	e8 42 92 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072f8:	e8 40 fc ff ff       	call   80106f3d <rcr2>
801072fd:	89 c2                	mov    %eax,%edx
801072ff:	8b 45 08             	mov    0x8(%ebp),%eax
80107302:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107305:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010730b:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010730e:	0f b6 f0             	movzbl %al,%esi
80107311:	8b 45 08             	mov    0x8(%ebp),%eax
80107314:	8b 58 34             	mov    0x34(%eax),%ebx
80107317:	8b 45 08             	mov    0x8(%ebp),%eax
8010731a:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010731d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107323:	83 c0 6c             	add    $0x6c,%eax
80107326:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107329:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010732f:	8b 40 10             	mov    0x10(%eax),%eax
80107332:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107336:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010733a:	89 74 24 14          	mov    %esi,0x14(%esp)
8010733e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107342:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107346:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80107349:	89 7c 24 08          	mov    %edi,0x8(%esp)
8010734d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107351:	c7 04 24 f0 a1 10 80 	movl   $0x8010a1f0,(%esp)
80107358:	e8 43 90 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010735d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107363:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010736a:	eb 01                	jmp    8010736d <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010736c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010736d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107373:	85 c0                	test   %eax,%eax
80107375:	74 24                	je     8010739b <trap+0x2bd>
80107377:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010737d:	8b 40 24             	mov    0x24(%eax),%eax
80107380:	85 c0                	test   %eax,%eax
80107382:	74 17                	je     8010739b <trap+0x2bd>
80107384:	8b 45 08             	mov    0x8(%ebp),%eax
80107387:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010738b:	0f b7 c0             	movzwl %ax,%eax
8010738e:	83 e0 03             	and    $0x3,%eax
80107391:	83 f8 03             	cmp    $0x3,%eax
80107394:	75 05                	jne    8010739b <trap+0x2bd>
    exit();
80107396:	e8 8a dd ff ff       	call   80105125 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
8010739b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073a1:	85 c0                	test   %eax,%eax
801073a3:	74 2c                	je     801073d1 <trap+0x2f3>
801073a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073ab:	8b 40 0c             	mov    0xc(%eax),%eax
801073ae:	83 f8 04             	cmp    $0x4,%eax
801073b1:	75 1e                	jne    801073d1 <trap+0x2f3>
801073b3:	8b 45 08             	mov    0x8(%ebp),%eax
801073b6:	8b 40 30             	mov    0x30(%eax),%eax
801073b9:	83 f8 20             	cmp    $0x20,%eax
801073bc:	75 13                	jne    801073d1 <trap+0x2f3>
    //update age of pages.TODO:check it is the right place.
    yield();
801073be:	e8 00 e1 ff ff       	call   801054c3 <yield>
     if (SCHEDFLAG==4){
      updateAge(proc);
801073c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073c9:	89 04 24             	mov    %eax,(%esp)
801073cc:	e8 55 26 00 00       	call   80109a26 <updateAge>
    } 
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801073d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073d7:	85 c0                	test   %eax,%eax
801073d9:	74 24                	je     801073ff <trap+0x321>
801073db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073e1:	8b 40 24             	mov    0x24(%eax),%eax
801073e4:	85 c0                	test   %eax,%eax
801073e6:	74 17                	je     801073ff <trap+0x321>
801073e8:	8b 45 08             	mov    0x8(%ebp),%eax
801073eb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801073ef:	0f b7 c0             	movzwl %ax,%eax
801073f2:	83 e0 03             	and    $0x3,%eax
801073f5:	83 f8 03             	cmp    $0x3,%eax
801073f8:	75 05                	jne    801073ff <trap+0x321>
    exit();
801073fa:	e8 26 dd ff ff       	call   80105125 <exit>
}
801073ff:	83 c4 3c             	add    $0x3c,%esp
80107402:	5b                   	pop    %ebx
80107403:	5e                   	pop    %esi
80107404:	5f                   	pop    %edi
80107405:	5d                   	pop    %ebp
80107406:	c3                   	ret    

80107407 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107407:	55                   	push   %ebp
80107408:	89 e5                	mov    %esp,%ebp
8010740a:	83 ec 14             	sub    $0x14,%esp
8010740d:	8b 45 08             	mov    0x8(%ebp),%eax
80107410:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107414:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107418:	89 c2                	mov    %eax,%edx
8010741a:	ec                   	in     (%dx),%al
8010741b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010741e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107422:	c9                   	leave  
80107423:	c3                   	ret    

80107424 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107424:	55                   	push   %ebp
80107425:	89 e5                	mov    %esp,%ebp
80107427:	83 ec 08             	sub    $0x8,%esp
8010742a:	8b 55 08             	mov    0x8(%ebp),%edx
8010742d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107430:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107434:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107437:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010743b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010743f:	ee                   	out    %al,(%dx)
}
80107440:	c9                   	leave  
80107441:	c3                   	ret    

80107442 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107442:	55                   	push   %ebp
80107443:	89 e5                	mov    %esp,%ebp
80107445:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107448:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010744f:	00 
80107450:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107457:	e8 c8 ff ff ff       	call   80107424 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010745c:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107463:	00 
80107464:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010746b:	e8 b4 ff ff ff       	call   80107424 <outb>
  outb(COM1+0, 115200/9600);
80107470:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107477:	00 
80107478:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010747f:	e8 a0 ff ff ff       	call   80107424 <outb>
  outb(COM1+1, 0);
80107484:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010748b:	00 
8010748c:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107493:	e8 8c ff ff ff       	call   80107424 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107498:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010749f:	00 
801074a0:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801074a7:	e8 78 ff ff ff       	call   80107424 <outb>
  outb(COM1+4, 0);
801074ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801074b3:	00 
801074b4:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801074bb:	e8 64 ff ff ff       	call   80107424 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801074c0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801074c7:	00 
801074c8:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801074cf:	e8 50 ff ff ff       	call   80107424 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801074d4:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074db:	e8 27 ff ff ff       	call   80107407 <inb>
801074e0:	3c ff                	cmp    $0xff,%al
801074e2:	75 02                	jne    801074e6 <uartinit+0xa4>
    return;
801074e4:	eb 6a                	jmp    80107550 <uartinit+0x10e>
  uart = 1;
801074e6:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
801074ed:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801074f0:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801074f7:	e8 0b ff ff ff       	call   80107407 <inb>
  inb(COM1+0);
801074fc:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107503:	e8 ff fe ff ff       	call   80107407 <inb>
  picenable(IRQ_COM1);
80107508:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010750f:	e8 b4 d0 ff ff       	call   801045c8 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107514:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010751b:	00 
8010751c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107523:	e8 e9 bb ff ff       	call   80103111 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107528:	c7 45 f4 fc a2 10 80 	movl   $0x8010a2fc,-0xc(%ebp)
8010752f:	eb 15                	jmp    80107546 <uartinit+0x104>
    uartputc(*p);
80107531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107534:	0f b6 00             	movzbl (%eax),%eax
80107537:	0f be c0             	movsbl %al,%eax
8010753a:	89 04 24             	mov    %eax,(%esp)
8010753d:	e8 10 00 00 00       	call   80107552 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107542:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107546:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107549:	0f b6 00             	movzbl (%eax),%eax
8010754c:	84 c0                	test   %al,%al
8010754e:	75 e1                	jne    80107531 <uartinit+0xef>
    uartputc(*p);
}
80107550:	c9                   	leave  
80107551:	c3                   	ret    

80107552 <uartputc>:

void
uartputc(int c)
{
80107552:	55                   	push   %ebp
80107553:	89 e5                	mov    %esp,%ebp
80107555:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107558:	a1 50 d6 10 80       	mov    0x8010d650,%eax
8010755d:	85 c0                	test   %eax,%eax
8010755f:	75 02                	jne    80107563 <uartputc+0x11>
    return;
80107561:	eb 4b                	jmp    801075ae <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107563:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010756a:	eb 10                	jmp    8010757c <uartputc+0x2a>
    microdelay(10);
8010756c:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107573:	e8 a0 c1 ff ff       	call   80103718 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107578:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010757c:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107580:	7f 16                	jg     80107598 <uartputc+0x46>
80107582:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107589:	e8 79 fe ff ff       	call   80107407 <inb>
8010758e:	0f b6 c0             	movzbl %al,%eax
80107591:	83 e0 20             	and    $0x20,%eax
80107594:	85 c0                	test   %eax,%eax
80107596:	74 d4                	je     8010756c <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80107598:	8b 45 08             	mov    0x8(%ebp),%eax
8010759b:	0f b6 c0             	movzbl %al,%eax
8010759e:	89 44 24 04          	mov    %eax,0x4(%esp)
801075a2:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075a9:	e8 76 fe ff ff       	call   80107424 <outb>
}
801075ae:	c9                   	leave  
801075af:	c3                   	ret    

801075b0 <uartgetc>:

static int
uartgetc(void)
{
801075b0:	55                   	push   %ebp
801075b1:	89 e5                	mov    %esp,%ebp
801075b3:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801075b6:	a1 50 d6 10 80       	mov    0x8010d650,%eax
801075bb:	85 c0                	test   %eax,%eax
801075bd:	75 07                	jne    801075c6 <uartgetc+0x16>
    return -1;
801075bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075c4:	eb 2c                	jmp    801075f2 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801075c6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801075cd:	e8 35 fe ff ff       	call   80107407 <inb>
801075d2:	0f b6 c0             	movzbl %al,%eax
801075d5:	83 e0 01             	and    $0x1,%eax
801075d8:	85 c0                	test   %eax,%eax
801075da:	75 07                	jne    801075e3 <uartgetc+0x33>
    return -1;
801075dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075e1:	eb 0f                	jmp    801075f2 <uartgetc+0x42>
  return inb(COM1+0);
801075e3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075ea:	e8 18 fe ff ff       	call   80107407 <inb>
801075ef:	0f b6 c0             	movzbl %al,%eax
}
801075f2:	c9                   	leave  
801075f3:	c3                   	ret    

801075f4 <uartintr>:

void
uartintr(void)
{
801075f4:	55                   	push   %ebp
801075f5:	89 e5                	mov    %esp,%ebp
801075f7:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801075fa:	c7 04 24 b0 75 10 80 	movl   $0x801075b0,(%esp)
80107601:	e8 c2 91 ff ff       	call   801007c8 <consoleintr>
}
80107606:	c9                   	leave  
80107607:	c3                   	ret    

80107608 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107608:	6a 00                	push   $0x0
  pushl $0
8010760a:	6a 00                	push   $0x0
  jmp alltraps
8010760c:	e9 d8 f8 ff ff       	jmp    80106ee9 <alltraps>

80107611 <vector1>:
.globl vector1
vector1:
  pushl $0
80107611:	6a 00                	push   $0x0
  pushl $1
80107613:	6a 01                	push   $0x1
  jmp alltraps
80107615:	e9 cf f8 ff ff       	jmp    80106ee9 <alltraps>

8010761a <vector2>:
.globl vector2
vector2:
  pushl $0
8010761a:	6a 00                	push   $0x0
  pushl $2
8010761c:	6a 02                	push   $0x2
  jmp alltraps
8010761e:	e9 c6 f8 ff ff       	jmp    80106ee9 <alltraps>

80107623 <vector3>:
.globl vector3
vector3:
  pushl $0
80107623:	6a 00                	push   $0x0
  pushl $3
80107625:	6a 03                	push   $0x3
  jmp alltraps
80107627:	e9 bd f8 ff ff       	jmp    80106ee9 <alltraps>

8010762c <vector4>:
.globl vector4
vector4:
  pushl $0
8010762c:	6a 00                	push   $0x0
  pushl $4
8010762e:	6a 04                	push   $0x4
  jmp alltraps
80107630:	e9 b4 f8 ff ff       	jmp    80106ee9 <alltraps>

80107635 <vector5>:
.globl vector5
vector5:
  pushl $0
80107635:	6a 00                	push   $0x0
  pushl $5
80107637:	6a 05                	push   $0x5
  jmp alltraps
80107639:	e9 ab f8 ff ff       	jmp    80106ee9 <alltraps>

8010763e <vector6>:
.globl vector6
vector6:
  pushl $0
8010763e:	6a 00                	push   $0x0
  pushl $6
80107640:	6a 06                	push   $0x6
  jmp alltraps
80107642:	e9 a2 f8 ff ff       	jmp    80106ee9 <alltraps>

80107647 <vector7>:
.globl vector7
vector7:
  pushl $0
80107647:	6a 00                	push   $0x0
  pushl $7
80107649:	6a 07                	push   $0x7
  jmp alltraps
8010764b:	e9 99 f8 ff ff       	jmp    80106ee9 <alltraps>

80107650 <vector8>:
.globl vector8
vector8:
  pushl $8
80107650:	6a 08                	push   $0x8
  jmp alltraps
80107652:	e9 92 f8 ff ff       	jmp    80106ee9 <alltraps>

80107657 <vector9>:
.globl vector9
vector9:
  pushl $0
80107657:	6a 00                	push   $0x0
  pushl $9
80107659:	6a 09                	push   $0x9
  jmp alltraps
8010765b:	e9 89 f8 ff ff       	jmp    80106ee9 <alltraps>

80107660 <vector10>:
.globl vector10
vector10:
  pushl $10
80107660:	6a 0a                	push   $0xa
  jmp alltraps
80107662:	e9 82 f8 ff ff       	jmp    80106ee9 <alltraps>

80107667 <vector11>:
.globl vector11
vector11:
  pushl $11
80107667:	6a 0b                	push   $0xb
  jmp alltraps
80107669:	e9 7b f8 ff ff       	jmp    80106ee9 <alltraps>

8010766e <vector12>:
.globl vector12
vector12:
  pushl $12
8010766e:	6a 0c                	push   $0xc
  jmp alltraps
80107670:	e9 74 f8 ff ff       	jmp    80106ee9 <alltraps>

80107675 <vector13>:
.globl vector13
vector13:
  pushl $13
80107675:	6a 0d                	push   $0xd
  jmp alltraps
80107677:	e9 6d f8 ff ff       	jmp    80106ee9 <alltraps>

8010767c <vector14>:
.globl vector14
vector14:
  pushl $14
8010767c:	6a 0e                	push   $0xe
  jmp alltraps
8010767e:	e9 66 f8 ff ff       	jmp    80106ee9 <alltraps>

80107683 <vector15>:
.globl vector15
vector15:
  pushl $0
80107683:	6a 00                	push   $0x0
  pushl $15
80107685:	6a 0f                	push   $0xf
  jmp alltraps
80107687:	e9 5d f8 ff ff       	jmp    80106ee9 <alltraps>

8010768c <vector16>:
.globl vector16
vector16:
  pushl $0
8010768c:	6a 00                	push   $0x0
  pushl $16
8010768e:	6a 10                	push   $0x10
  jmp alltraps
80107690:	e9 54 f8 ff ff       	jmp    80106ee9 <alltraps>

80107695 <vector17>:
.globl vector17
vector17:
  pushl $17
80107695:	6a 11                	push   $0x11
  jmp alltraps
80107697:	e9 4d f8 ff ff       	jmp    80106ee9 <alltraps>

8010769c <vector18>:
.globl vector18
vector18:
  pushl $0
8010769c:	6a 00                	push   $0x0
  pushl $18
8010769e:	6a 12                	push   $0x12
  jmp alltraps
801076a0:	e9 44 f8 ff ff       	jmp    80106ee9 <alltraps>

801076a5 <vector19>:
.globl vector19
vector19:
  pushl $0
801076a5:	6a 00                	push   $0x0
  pushl $19
801076a7:	6a 13                	push   $0x13
  jmp alltraps
801076a9:	e9 3b f8 ff ff       	jmp    80106ee9 <alltraps>

801076ae <vector20>:
.globl vector20
vector20:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $20
801076b0:	6a 14                	push   $0x14
  jmp alltraps
801076b2:	e9 32 f8 ff ff       	jmp    80106ee9 <alltraps>

801076b7 <vector21>:
.globl vector21
vector21:
  pushl $0
801076b7:	6a 00                	push   $0x0
  pushl $21
801076b9:	6a 15                	push   $0x15
  jmp alltraps
801076bb:	e9 29 f8 ff ff       	jmp    80106ee9 <alltraps>

801076c0 <vector22>:
.globl vector22
vector22:
  pushl $0
801076c0:	6a 00                	push   $0x0
  pushl $22
801076c2:	6a 16                	push   $0x16
  jmp alltraps
801076c4:	e9 20 f8 ff ff       	jmp    80106ee9 <alltraps>

801076c9 <vector23>:
.globl vector23
vector23:
  pushl $0
801076c9:	6a 00                	push   $0x0
  pushl $23
801076cb:	6a 17                	push   $0x17
  jmp alltraps
801076cd:	e9 17 f8 ff ff       	jmp    80106ee9 <alltraps>

801076d2 <vector24>:
.globl vector24
vector24:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $24
801076d4:	6a 18                	push   $0x18
  jmp alltraps
801076d6:	e9 0e f8 ff ff       	jmp    80106ee9 <alltraps>

801076db <vector25>:
.globl vector25
vector25:
  pushl $0
801076db:	6a 00                	push   $0x0
  pushl $25
801076dd:	6a 19                	push   $0x19
  jmp alltraps
801076df:	e9 05 f8 ff ff       	jmp    80106ee9 <alltraps>

801076e4 <vector26>:
.globl vector26
vector26:
  pushl $0
801076e4:	6a 00                	push   $0x0
  pushl $26
801076e6:	6a 1a                	push   $0x1a
  jmp alltraps
801076e8:	e9 fc f7 ff ff       	jmp    80106ee9 <alltraps>

801076ed <vector27>:
.globl vector27
vector27:
  pushl $0
801076ed:	6a 00                	push   $0x0
  pushl $27
801076ef:	6a 1b                	push   $0x1b
  jmp alltraps
801076f1:	e9 f3 f7 ff ff       	jmp    80106ee9 <alltraps>

801076f6 <vector28>:
.globl vector28
vector28:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $28
801076f8:	6a 1c                	push   $0x1c
  jmp alltraps
801076fa:	e9 ea f7 ff ff       	jmp    80106ee9 <alltraps>

801076ff <vector29>:
.globl vector29
vector29:
  pushl $0
801076ff:	6a 00                	push   $0x0
  pushl $29
80107701:	6a 1d                	push   $0x1d
  jmp alltraps
80107703:	e9 e1 f7 ff ff       	jmp    80106ee9 <alltraps>

80107708 <vector30>:
.globl vector30
vector30:
  pushl $0
80107708:	6a 00                	push   $0x0
  pushl $30
8010770a:	6a 1e                	push   $0x1e
  jmp alltraps
8010770c:	e9 d8 f7 ff ff       	jmp    80106ee9 <alltraps>

80107711 <vector31>:
.globl vector31
vector31:
  pushl $0
80107711:	6a 00                	push   $0x0
  pushl $31
80107713:	6a 1f                	push   $0x1f
  jmp alltraps
80107715:	e9 cf f7 ff ff       	jmp    80106ee9 <alltraps>

8010771a <vector32>:
.globl vector32
vector32:
  pushl $0
8010771a:	6a 00                	push   $0x0
  pushl $32
8010771c:	6a 20                	push   $0x20
  jmp alltraps
8010771e:	e9 c6 f7 ff ff       	jmp    80106ee9 <alltraps>

80107723 <vector33>:
.globl vector33
vector33:
  pushl $0
80107723:	6a 00                	push   $0x0
  pushl $33
80107725:	6a 21                	push   $0x21
  jmp alltraps
80107727:	e9 bd f7 ff ff       	jmp    80106ee9 <alltraps>

8010772c <vector34>:
.globl vector34
vector34:
  pushl $0
8010772c:	6a 00                	push   $0x0
  pushl $34
8010772e:	6a 22                	push   $0x22
  jmp alltraps
80107730:	e9 b4 f7 ff ff       	jmp    80106ee9 <alltraps>

80107735 <vector35>:
.globl vector35
vector35:
  pushl $0
80107735:	6a 00                	push   $0x0
  pushl $35
80107737:	6a 23                	push   $0x23
  jmp alltraps
80107739:	e9 ab f7 ff ff       	jmp    80106ee9 <alltraps>

8010773e <vector36>:
.globl vector36
vector36:
  pushl $0
8010773e:	6a 00                	push   $0x0
  pushl $36
80107740:	6a 24                	push   $0x24
  jmp alltraps
80107742:	e9 a2 f7 ff ff       	jmp    80106ee9 <alltraps>

80107747 <vector37>:
.globl vector37
vector37:
  pushl $0
80107747:	6a 00                	push   $0x0
  pushl $37
80107749:	6a 25                	push   $0x25
  jmp alltraps
8010774b:	e9 99 f7 ff ff       	jmp    80106ee9 <alltraps>

80107750 <vector38>:
.globl vector38
vector38:
  pushl $0
80107750:	6a 00                	push   $0x0
  pushl $38
80107752:	6a 26                	push   $0x26
  jmp alltraps
80107754:	e9 90 f7 ff ff       	jmp    80106ee9 <alltraps>

80107759 <vector39>:
.globl vector39
vector39:
  pushl $0
80107759:	6a 00                	push   $0x0
  pushl $39
8010775b:	6a 27                	push   $0x27
  jmp alltraps
8010775d:	e9 87 f7 ff ff       	jmp    80106ee9 <alltraps>

80107762 <vector40>:
.globl vector40
vector40:
  pushl $0
80107762:	6a 00                	push   $0x0
  pushl $40
80107764:	6a 28                	push   $0x28
  jmp alltraps
80107766:	e9 7e f7 ff ff       	jmp    80106ee9 <alltraps>

8010776b <vector41>:
.globl vector41
vector41:
  pushl $0
8010776b:	6a 00                	push   $0x0
  pushl $41
8010776d:	6a 29                	push   $0x29
  jmp alltraps
8010776f:	e9 75 f7 ff ff       	jmp    80106ee9 <alltraps>

80107774 <vector42>:
.globl vector42
vector42:
  pushl $0
80107774:	6a 00                	push   $0x0
  pushl $42
80107776:	6a 2a                	push   $0x2a
  jmp alltraps
80107778:	e9 6c f7 ff ff       	jmp    80106ee9 <alltraps>

8010777d <vector43>:
.globl vector43
vector43:
  pushl $0
8010777d:	6a 00                	push   $0x0
  pushl $43
8010777f:	6a 2b                	push   $0x2b
  jmp alltraps
80107781:	e9 63 f7 ff ff       	jmp    80106ee9 <alltraps>

80107786 <vector44>:
.globl vector44
vector44:
  pushl $0
80107786:	6a 00                	push   $0x0
  pushl $44
80107788:	6a 2c                	push   $0x2c
  jmp alltraps
8010778a:	e9 5a f7 ff ff       	jmp    80106ee9 <alltraps>

8010778f <vector45>:
.globl vector45
vector45:
  pushl $0
8010778f:	6a 00                	push   $0x0
  pushl $45
80107791:	6a 2d                	push   $0x2d
  jmp alltraps
80107793:	e9 51 f7 ff ff       	jmp    80106ee9 <alltraps>

80107798 <vector46>:
.globl vector46
vector46:
  pushl $0
80107798:	6a 00                	push   $0x0
  pushl $46
8010779a:	6a 2e                	push   $0x2e
  jmp alltraps
8010779c:	e9 48 f7 ff ff       	jmp    80106ee9 <alltraps>

801077a1 <vector47>:
.globl vector47
vector47:
  pushl $0
801077a1:	6a 00                	push   $0x0
  pushl $47
801077a3:	6a 2f                	push   $0x2f
  jmp alltraps
801077a5:	e9 3f f7 ff ff       	jmp    80106ee9 <alltraps>

801077aa <vector48>:
.globl vector48
vector48:
  pushl $0
801077aa:	6a 00                	push   $0x0
  pushl $48
801077ac:	6a 30                	push   $0x30
  jmp alltraps
801077ae:	e9 36 f7 ff ff       	jmp    80106ee9 <alltraps>

801077b3 <vector49>:
.globl vector49
vector49:
  pushl $0
801077b3:	6a 00                	push   $0x0
  pushl $49
801077b5:	6a 31                	push   $0x31
  jmp alltraps
801077b7:	e9 2d f7 ff ff       	jmp    80106ee9 <alltraps>

801077bc <vector50>:
.globl vector50
vector50:
  pushl $0
801077bc:	6a 00                	push   $0x0
  pushl $50
801077be:	6a 32                	push   $0x32
  jmp alltraps
801077c0:	e9 24 f7 ff ff       	jmp    80106ee9 <alltraps>

801077c5 <vector51>:
.globl vector51
vector51:
  pushl $0
801077c5:	6a 00                	push   $0x0
  pushl $51
801077c7:	6a 33                	push   $0x33
  jmp alltraps
801077c9:	e9 1b f7 ff ff       	jmp    80106ee9 <alltraps>

801077ce <vector52>:
.globl vector52
vector52:
  pushl $0
801077ce:	6a 00                	push   $0x0
  pushl $52
801077d0:	6a 34                	push   $0x34
  jmp alltraps
801077d2:	e9 12 f7 ff ff       	jmp    80106ee9 <alltraps>

801077d7 <vector53>:
.globl vector53
vector53:
  pushl $0
801077d7:	6a 00                	push   $0x0
  pushl $53
801077d9:	6a 35                	push   $0x35
  jmp alltraps
801077db:	e9 09 f7 ff ff       	jmp    80106ee9 <alltraps>

801077e0 <vector54>:
.globl vector54
vector54:
  pushl $0
801077e0:	6a 00                	push   $0x0
  pushl $54
801077e2:	6a 36                	push   $0x36
  jmp alltraps
801077e4:	e9 00 f7 ff ff       	jmp    80106ee9 <alltraps>

801077e9 <vector55>:
.globl vector55
vector55:
  pushl $0
801077e9:	6a 00                	push   $0x0
  pushl $55
801077eb:	6a 37                	push   $0x37
  jmp alltraps
801077ed:	e9 f7 f6 ff ff       	jmp    80106ee9 <alltraps>

801077f2 <vector56>:
.globl vector56
vector56:
  pushl $0
801077f2:	6a 00                	push   $0x0
  pushl $56
801077f4:	6a 38                	push   $0x38
  jmp alltraps
801077f6:	e9 ee f6 ff ff       	jmp    80106ee9 <alltraps>

801077fb <vector57>:
.globl vector57
vector57:
  pushl $0
801077fb:	6a 00                	push   $0x0
  pushl $57
801077fd:	6a 39                	push   $0x39
  jmp alltraps
801077ff:	e9 e5 f6 ff ff       	jmp    80106ee9 <alltraps>

80107804 <vector58>:
.globl vector58
vector58:
  pushl $0
80107804:	6a 00                	push   $0x0
  pushl $58
80107806:	6a 3a                	push   $0x3a
  jmp alltraps
80107808:	e9 dc f6 ff ff       	jmp    80106ee9 <alltraps>

8010780d <vector59>:
.globl vector59
vector59:
  pushl $0
8010780d:	6a 00                	push   $0x0
  pushl $59
8010780f:	6a 3b                	push   $0x3b
  jmp alltraps
80107811:	e9 d3 f6 ff ff       	jmp    80106ee9 <alltraps>

80107816 <vector60>:
.globl vector60
vector60:
  pushl $0
80107816:	6a 00                	push   $0x0
  pushl $60
80107818:	6a 3c                	push   $0x3c
  jmp alltraps
8010781a:	e9 ca f6 ff ff       	jmp    80106ee9 <alltraps>

8010781f <vector61>:
.globl vector61
vector61:
  pushl $0
8010781f:	6a 00                	push   $0x0
  pushl $61
80107821:	6a 3d                	push   $0x3d
  jmp alltraps
80107823:	e9 c1 f6 ff ff       	jmp    80106ee9 <alltraps>

80107828 <vector62>:
.globl vector62
vector62:
  pushl $0
80107828:	6a 00                	push   $0x0
  pushl $62
8010782a:	6a 3e                	push   $0x3e
  jmp alltraps
8010782c:	e9 b8 f6 ff ff       	jmp    80106ee9 <alltraps>

80107831 <vector63>:
.globl vector63
vector63:
  pushl $0
80107831:	6a 00                	push   $0x0
  pushl $63
80107833:	6a 3f                	push   $0x3f
  jmp alltraps
80107835:	e9 af f6 ff ff       	jmp    80106ee9 <alltraps>

8010783a <vector64>:
.globl vector64
vector64:
  pushl $0
8010783a:	6a 00                	push   $0x0
  pushl $64
8010783c:	6a 40                	push   $0x40
  jmp alltraps
8010783e:	e9 a6 f6 ff ff       	jmp    80106ee9 <alltraps>

80107843 <vector65>:
.globl vector65
vector65:
  pushl $0
80107843:	6a 00                	push   $0x0
  pushl $65
80107845:	6a 41                	push   $0x41
  jmp alltraps
80107847:	e9 9d f6 ff ff       	jmp    80106ee9 <alltraps>

8010784c <vector66>:
.globl vector66
vector66:
  pushl $0
8010784c:	6a 00                	push   $0x0
  pushl $66
8010784e:	6a 42                	push   $0x42
  jmp alltraps
80107850:	e9 94 f6 ff ff       	jmp    80106ee9 <alltraps>

80107855 <vector67>:
.globl vector67
vector67:
  pushl $0
80107855:	6a 00                	push   $0x0
  pushl $67
80107857:	6a 43                	push   $0x43
  jmp alltraps
80107859:	e9 8b f6 ff ff       	jmp    80106ee9 <alltraps>

8010785e <vector68>:
.globl vector68
vector68:
  pushl $0
8010785e:	6a 00                	push   $0x0
  pushl $68
80107860:	6a 44                	push   $0x44
  jmp alltraps
80107862:	e9 82 f6 ff ff       	jmp    80106ee9 <alltraps>

80107867 <vector69>:
.globl vector69
vector69:
  pushl $0
80107867:	6a 00                	push   $0x0
  pushl $69
80107869:	6a 45                	push   $0x45
  jmp alltraps
8010786b:	e9 79 f6 ff ff       	jmp    80106ee9 <alltraps>

80107870 <vector70>:
.globl vector70
vector70:
  pushl $0
80107870:	6a 00                	push   $0x0
  pushl $70
80107872:	6a 46                	push   $0x46
  jmp alltraps
80107874:	e9 70 f6 ff ff       	jmp    80106ee9 <alltraps>

80107879 <vector71>:
.globl vector71
vector71:
  pushl $0
80107879:	6a 00                	push   $0x0
  pushl $71
8010787b:	6a 47                	push   $0x47
  jmp alltraps
8010787d:	e9 67 f6 ff ff       	jmp    80106ee9 <alltraps>

80107882 <vector72>:
.globl vector72
vector72:
  pushl $0
80107882:	6a 00                	push   $0x0
  pushl $72
80107884:	6a 48                	push   $0x48
  jmp alltraps
80107886:	e9 5e f6 ff ff       	jmp    80106ee9 <alltraps>

8010788b <vector73>:
.globl vector73
vector73:
  pushl $0
8010788b:	6a 00                	push   $0x0
  pushl $73
8010788d:	6a 49                	push   $0x49
  jmp alltraps
8010788f:	e9 55 f6 ff ff       	jmp    80106ee9 <alltraps>

80107894 <vector74>:
.globl vector74
vector74:
  pushl $0
80107894:	6a 00                	push   $0x0
  pushl $74
80107896:	6a 4a                	push   $0x4a
  jmp alltraps
80107898:	e9 4c f6 ff ff       	jmp    80106ee9 <alltraps>

8010789d <vector75>:
.globl vector75
vector75:
  pushl $0
8010789d:	6a 00                	push   $0x0
  pushl $75
8010789f:	6a 4b                	push   $0x4b
  jmp alltraps
801078a1:	e9 43 f6 ff ff       	jmp    80106ee9 <alltraps>

801078a6 <vector76>:
.globl vector76
vector76:
  pushl $0
801078a6:	6a 00                	push   $0x0
  pushl $76
801078a8:	6a 4c                	push   $0x4c
  jmp alltraps
801078aa:	e9 3a f6 ff ff       	jmp    80106ee9 <alltraps>

801078af <vector77>:
.globl vector77
vector77:
  pushl $0
801078af:	6a 00                	push   $0x0
  pushl $77
801078b1:	6a 4d                	push   $0x4d
  jmp alltraps
801078b3:	e9 31 f6 ff ff       	jmp    80106ee9 <alltraps>

801078b8 <vector78>:
.globl vector78
vector78:
  pushl $0
801078b8:	6a 00                	push   $0x0
  pushl $78
801078ba:	6a 4e                	push   $0x4e
  jmp alltraps
801078bc:	e9 28 f6 ff ff       	jmp    80106ee9 <alltraps>

801078c1 <vector79>:
.globl vector79
vector79:
  pushl $0
801078c1:	6a 00                	push   $0x0
  pushl $79
801078c3:	6a 4f                	push   $0x4f
  jmp alltraps
801078c5:	e9 1f f6 ff ff       	jmp    80106ee9 <alltraps>

801078ca <vector80>:
.globl vector80
vector80:
  pushl $0
801078ca:	6a 00                	push   $0x0
  pushl $80
801078cc:	6a 50                	push   $0x50
  jmp alltraps
801078ce:	e9 16 f6 ff ff       	jmp    80106ee9 <alltraps>

801078d3 <vector81>:
.globl vector81
vector81:
  pushl $0
801078d3:	6a 00                	push   $0x0
  pushl $81
801078d5:	6a 51                	push   $0x51
  jmp alltraps
801078d7:	e9 0d f6 ff ff       	jmp    80106ee9 <alltraps>

801078dc <vector82>:
.globl vector82
vector82:
  pushl $0
801078dc:	6a 00                	push   $0x0
  pushl $82
801078de:	6a 52                	push   $0x52
  jmp alltraps
801078e0:	e9 04 f6 ff ff       	jmp    80106ee9 <alltraps>

801078e5 <vector83>:
.globl vector83
vector83:
  pushl $0
801078e5:	6a 00                	push   $0x0
  pushl $83
801078e7:	6a 53                	push   $0x53
  jmp alltraps
801078e9:	e9 fb f5 ff ff       	jmp    80106ee9 <alltraps>

801078ee <vector84>:
.globl vector84
vector84:
  pushl $0
801078ee:	6a 00                	push   $0x0
  pushl $84
801078f0:	6a 54                	push   $0x54
  jmp alltraps
801078f2:	e9 f2 f5 ff ff       	jmp    80106ee9 <alltraps>

801078f7 <vector85>:
.globl vector85
vector85:
  pushl $0
801078f7:	6a 00                	push   $0x0
  pushl $85
801078f9:	6a 55                	push   $0x55
  jmp alltraps
801078fb:	e9 e9 f5 ff ff       	jmp    80106ee9 <alltraps>

80107900 <vector86>:
.globl vector86
vector86:
  pushl $0
80107900:	6a 00                	push   $0x0
  pushl $86
80107902:	6a 56                	push   $0x56
  jmp alltraps
80107904:	e9 e0 f5 ff ff       	jmp    80106ee9 <alltraps>

80107909 <vector87>:
.globl vector87
vector87:
  pushl $0
80107909:	6a 00                	push   $0x0
  pushl $87
8010790b:	6a 57                	push   $0x57
  jmp alltraps
8010790d:	e9 d7 f5 ff ff       	jmp    80106ee9 <alltraps>

80107912 <vector88>:
.globl vector88
vector88:
  pushl $0
80107912:	6a 00                	push   $0x0
  pushl $88
80107914:	6a 58                	push   $0x58
  jmp alltraps
80107916:	e9 ce f5 ff ff       	jmp    80106ee9 <alltraps>

8010791b <vector89>:
.globl vector89
vector89:
  pushl $0
8010791b:	6a 00                	push   $0x0
  pushl $89
8010791d:	6a 59                	push   $0x59
  jmp alltraps
8010791f:	e9 c5 f5 ff ff       	jmp    80106ee9 <alltraps>

80107924 <vector90>:
.globl vector90
vector90:
  pushl $0
80107924:	6a 00                	push   $0x0
  pushl $90
80107926:	6a 5a                	push   $0x5a
  jmp alltraps
80107928:	e9 bc f5 ff ff       	jmp    80106ee9 <alltraps>

8010792d <vector91>:
.globl vector91
vector91:
  pushl $0
8010792d:	6a 00                	push   $0x0
  pushl $91
8010792f:	6a 5b                	push   $0x5b
  jmp alltraps
80107931:	e9 b3 f5 ff ff       	jmp    80106ee9 <alltraps>

80107936 <vector92>:
.globl vector92
vector92:
  pushl $0
80107936:	6a 00                	push   $0x0
  pushl $92
80107938:	6a 5c                	push   $0x5c
  jmp alltraps
8010793a:	e9 aa f5 ff ff       	jmp    80106ee9 <alltraps>

8010793f <vector93>:
.globl vector93
vector93:
  pushl $0
8010793f:	6a 00                	push   $0x0
  pushl $93
80107941:	6a 5d                	push   $0x5d
  jmp alltraps
80107943:	e9 a1 f5 ff ff       	jmp    80106ee9 <alltraps>

80107948 <vector94>:
.globl vector94
vector94:
  pushl $0
80107948:	6a 00                	push   $0x0
  pushl $94
8010794a:	6a 5e                	push   $0x5e
  jmp alltraps
8010794c:	e9 98 f5 ff ff       	jmp    80106ee9 <alltraps>

80107951 <vector95>:
.globl vector95
vector95:
  pushl $0
80107951:	6a 00                	push   $0x0
  pushl $95
80107953:	6a 5f                	push   $0x5f
  jmp alltraps
80107955:	e9 8f f5 ff ff       	jmp    80106ee9 <alltraps>

8010795a <vector96>:
.globl vector96
vector96:
  pushl $0
8010795a:	6a 00                	push   $0x0
  pushl $96
8010795c:	6a 60                	push   $0x60
  jmp alltraps
8010795e:	e9 86 f5 ff ff       	jmp    80106ee9 <alltraps>

80107963 <vector97>:
.globl vector97
vector97:
  pushl $0
80107963:	6a 00                	push   $0x0
  pushl $97
80107965:	6a 61                	push   $0x61
  jmp alltraps
80107967:	e9 7d f5 ff ff       	jmp    80106ee9 <alltraps>

8010796c <vector98>:
.globl vector98
vector98:
  pushl $0
8010796c:	6a 00                	push   $0x0
  pushl $98
8010796e:	6a 62                	push   $0x62
  jmp alltraps
80107970:	e9 74 f5 ff ff       	jmp    80106ee9 <alltraps>

80107975 <vector99>:
.globl vector99
vector99:
  pushl $0
80107975:	6a 00                	push   $0x0
  pushl $99
80107977:	6a 63                	push   $0x63
  jmp alltraps
80107979:	e9 6b f5 ff ff       	jmp    80106ee9 <alltraps>

8010797e <vector100>:
.globl vector100
vector100:
  pushl $0
8010797e:	6a 00                	push   $0x0
  pushl $100
80107980:	6a 64                	push   $0x64
  jmp alltraps
80107982:	e9 62 f5 ff ff       	jmp    80106ee9 <alltraps>

80107987 <vector101>:
.globl vector101
vector101:
  pushl $0
80107987:	6a 00                	push   $0x0
  pushl $101
80107989:	6a 65                	push   $0x65
  jmp alltraps
8010798b:	e9 59 f5 ff ff       	jmp    80106ee9 <alltraps>

80107990 <vector102>:
.globl vector102
vector102:
  pushl $0
80107990:	6a 00                	push   $0x0
  pushl $102
80107992:	6a 66                	push   $0x66
  jmp alltraps
80107994:	e9 50 f5 ff ff       	jmp    80106ee9 <alltraps>

80107999 <vector103>:
.globl vector103
vector103:
  pushl $0
80107999:	6a 00                	push   $0x0
  pushl $103
8010799b:	6a 67                	push   $0x67
  jmp alltraps
8010799d:	e9 47 f5 ff ff       	jmp    80106ee9 <alltraps>

801079a2 <vector104>:
.globl vector104
vector104:
  pushl $0
801079a2:	6a 00                	push   $0x0
  pushl $104
801079a4:	6a 68                	push   $0x68
  jmp alltraps
801079a6:	e9 3e f5 ff ff       	jmp    80106ee9 <alltraps>

801079ab <vector105>:
.globl vector105
vector105:
  pushl $0
801079ab:	6a 00                	push   $0x0
  pushl $105
801079ad:	6a 69                	push   $0x69
  jmp alltraps
801079af:	e9 35 f5 ff ff       	jmp    80106ee9 <alltraps>

801079b4 <vector106>:
.globl vector106
vector106:
  pushl $0
801079b4:	6a 00                	push   $0x0
  pushl $106
801079b6:	6a 6a                	push   $0x6a
  jmp alltraps
801079b8:	e9 2c f5 ff ff       	jmp    80106ee9 <alltraps>

801079bd <vector107>:
.globl vector107
vector107:
  pushl $0
801079bd:	6a 00                	push   $0x0
  pushl $107
801079bf:	6a 6b                	push   $0x6b
  jmp alltraps
801079c1:	e9 23 f5 ff ff       	jmp    80106ee9 <alltraps>

801079c6 <vector108>:
.globl vector108
vector108:
  pushl $0
801079c6:	6a 00                	push   $0x0
  pushl $108
801079c8:	6a 6c                	push   $0x6c
  jmp alltraps
801079ca:	e9 1a f5 ff ff       	jmp    80106ee9 <alltraps>

801079cf <vector109>:
.globl vector109
vector109:
  pushl $0
801079cf:	6a 00                	push   $0x0
  pushl $109
801079d1:	6a 6d                	push   $0x6d
  jmp alltraps
801079d3:	e9 11 f5 ff ff       	jmp    80106ee9 <alltraps>

801079d8 <vector110>:
.globl vector110
vector110:
  pushl $0
801079d8:	6a 00                	push   $0x0
  pushl $110
801079da:	6a 6e                	push   $0x6e
  jmp alltraps
801079dc:	e9 08 f5 ff ff       	jmp    80106ee9 <alltraps>

801079e1 <vector111>:
.globl vector111
vector111:
  pushl $0
801079e1:	6a 00                	push   $0x0
  pushl $111
801079e3:	6a 6f                	push   $0x6f
  jmp alltraps
801079e5:	e9 ff f4 ff ff       	jmp    80106ee9 <alltraps>

801079ea <vector112>:
.globl vector112
vector112:
  pushl $0
801079ea:	6a 00                	push   $0x0
  pushl $112
801079ec:	6a 70                	push   $0x70
  jmp alltraps
801079ee:	e9 f6 f4 ff ff       	jmp    80106ee9 <alltraps>

801079f3 <vector113>:
.globl vector113
vector113:
  pushl $0
801079f3:	6a 00                	push   $0x0
  pushl $113
801079f5:	6a 71                	push   $0x71
  jmp alltraps
801079f7:	e9 ed f4 ff ff       	jmp    80106ee9 <alltraps>

801079fc <vector114>:
.globl vector114
vector114:
  pushl $0
801079fc:	6a 00                	push   $0x0
  pushl $114
801079fe:	6a 72                	push   $0x72
  jmp alltraps
80107a00:	e9 e4 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a05 <vector115>:
.globl vector115
vector115:
  pushl $0
80107a05:	6a 00                	push   $0x0
  pushl $115
80107a07:	6a 73                	push   $0x73
  jmp alltraps
80107a09:	e9 db f4 ff ff       	jmp    80106ee9 <alltraps>

80107a0e <vector116>:
.globl vector116
vector116:
  pushl $0
80107a0e:	6a 00                	push   $0x0
  pushl $116
80107a10:	6a 74                	push   $0x74
  jmp alltraps
80107a12:	e9 d2 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a17 <vector117>:
.globl vector117
vector117:
  pushl $0
80107a17:	6a 00                	push   $0x0
  pushl $117
80107a19:	6a 75                	push   $0x75
  jmp alltraps
80107a1b:	e9 c9 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a20 <vector118>:
.globl vector118
vector118:
  pushl $0
80107a20:	6a 00                	push   $0x0
  pushl $118
80107a22:	6a 76                	push   $0x76
  jmp alltraps
80107a24:	e9 c0 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a29 <vector119>:
.globl vector119
vector119:
  pushl $0
80107a29:	6a 00                	push   $0x0
  pushl $119
80107a2b:	6a 77                	push   $0x77
  jmp alltraps
80107a2d:	e9 b7 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a32 <vector120>:
.globl vector120
vector120:
  pushl $0
80107a32:	6a 00                	push   $0x0
  pushl $120
80107a34:	6a 78                	push   $0x78
  jmp alltraps
80107a36:	e9 ae f4 ff ff       	jmp    80106ee9 <alltraps>

80107a3b <vector121>:
.globl vector121
vector121:
  pushl $0
80107a3b:	6a 00                	push   $0x0
  pushl $121
80107a3d:	6a 79                	push   $0x79
  jmp alltraps
80107a3f:	e9 a5 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a44 <vector122>:
.globl vector122
vector122:
  pushl $0
80107a44:	6a 00                	push   $0x0
  pushl $122
80107a46:	6a 7a                	push   $0x7a
  jmp alltraps
80107a48:	e9 9c f4 ff ff       	jmp    80106ee9 <alltraps>

80107a4d <vector123>:
.globl vector123
vector123:
  pushl $0
80107a4d:	6a 00                	push   $0x0
  pushl $123
80107a4f:	6a 7b                	push   $0x7b
  jmp alltraps
80107a51:	e9 93 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a56 <vector124>:
.globl vector124
vector124:
  pushl $0
80107a56:	6a 00                	push   $0x0
  pushl $124
80107a58:	6a 7c                	push   $0x7c
  jmp alltraps
80107a5a:	e9 8a f4 ff ff       	jmp    80106ee9 <alltraps>

80107a5f <vector125>:
.globl vector125
vector125:
  pushl $0
80107a5f:	6a 00                	push   $0x0
  pushl $125
80107a61:	6a 7d                	push   $0x7d
  jmp alltraps
80107a63:	e9 81 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a68 <vector126>:
.globl vector126
vector126:
  pushl $0
80107a68:	6a 00                	push   $0x0
  pushl $126
80107a6a:	6a 7e                	push   $0x7e
  jmp alltraps
80107a6c:	e9 78 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a71 <vector127>:
.globl vector127
vector127:
  pushl $0
80107a71:	6a 00                	push   $0x0
  pushl $127
80107a73:	6a 7f                	push   $0x7f
  jmp alltraps
80107a75:	e9 6f f4 ff ff       	jmp    80106ee9 <alltraps>

80107a7a <vector128>:
.globl vector128
vector128:
  pushl $0
80107a7a:	6a 00                	push   $0x0
  pushl $128
80107a7c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107a81:	e9 63 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a86 <vector129>:
.globl vector129
vector129:
  pushl $0
80107a86:	6a 00                	push   $0x0
  pushl $129
80107a88:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107a8d:	e9 57 f4 ff ff       	jmp    80106ee9 <alltraps>

80107a92 <vector130>:
.globl vector130
vector130:
  pushl $0
80107a92:	6a 00                	push   $0x0
  pushl $130
80107a94:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107a99:	e9 4b f4 ff ff       	jmp    80106ee9 <alltraps>

80107a9e <vector131>:
.globl vector131
vector131:
  pushl $0
80107a9e:	6a 00                	push   $0x0
  pushl $131
80107aa0:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107aa5:	e9 3f f4 ff ff       	jmp    80106ee9 <alltraps>

80107aaa <vector132>:
.globl vector132
vector132:
  pushl $0
80107aaa:	6a 00                	push   $0x0
  pushl $132
80107aac:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107ab1:	e9 33 f4 ff ff       	jmp    80106ee9 <alltraps>

80107ab6 <vector133>:
.globl vector133
vector133:
  pushl $0
80107ab6:	6a 00                	push   $0x0
  pushl $133
80107ab8:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107abd:	e9 27 f4 ff ff       	jmp    80106ee9 <alltraps>

80107ac2 <vector134>:
.globl vector134
vector134:
  pushl $0
80107ac2:	6a 00                	push   $0x0
  pushl $134
80107ac4:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107ac9:	e9 1b f4 ff ff       	jmp    80106ee9 <alltraps>

80107ace <vector135>:
.globl vector135
vector135:
  pushl $0
80107ace:	6a 00                	push   $0x0
  pushl $135
80107ad0:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107ad5:	e9 0f f4 ff ff       	jmp    80106ee9 <alltraps>

80107ada <vector136>:
.globl vector136
vector136:
  pushl $0
80107ada:	6a 00                	push   $0x0
  pushl $136
80107adc:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107ae1:	e9 03 f4 ff ff       	jmp    80106ee9 <alltraps>

80107ae6 <vector137>:
.globl vector137
vector137:
  pushl $0
80107ae6:	6a 00                	push   $0x0
  pushl $137
80107ae8:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107aed:	e9 f7 f3 ff ff       	jmp    80106ee9 <alltraps>

80107af2 <vector138>:
.globl vector138
vector138:
  pushl $0
80107af2:	6a 00                	push   $0x0
  pushl $138
80107af4:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107af9:	e9 eb f3 ff ff       	jmp    80106ee9 <alltraps>

80107afe <vector139>:
.globl vector139
vector139:
  pushl $0
80107afe:	6a 00                	push   $0x0
  pushl $139
80107b00:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107b05:	e9 df f3 ff ff       	jmp    80106ee9 <alltraps>

80107b0a <vector140>:
.globl vector140
vector140:
  pushl $0
80107b0a:	6a 00                	push   $0x0
  pushl $140
80107b0c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107b11:	e9 d3 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b16 <vector141>:
.globl vector141
vector141:
  pushl $0
80107b16:	6a 00                	push   $0x0
  pushl $141
80107b18:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107b1d:	e9 c7 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b22 <vector142>:
.globl vector142
vector142:
  pushl $0
80107b22:	6a 00                	push   $0x0
  pushl $142
80107b24:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107b29:	e9 bb f3 ff ff       	jmp    80106ee9 <alltraps>

80107b2e <vector143>:
.globl vector143
vector143:
  pushl $0
80107b2e:	6a 00                	push   $0x0
  pushl $143
80107b30:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107b35:	e9 af f3 ff ff       	jmp    80106ee9 <alltraps>

80107b3a <vector144>:
.globl vector144
vector144:
  pushl $0
80107b3a:	6a 00                	push   $0x0
  pushl $144
80107b3c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107b41:	e9 a3 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b46 <vector145>:
.globl vector145
vector145:
  pushl $0
80107b46:	6a 00                	push   $0x0
  pushl $145
80107b48:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107b4d:	e9 97 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b52 <vector146>:
.globl vector146
vector146:
  pushl $0
80107b52:	6a 00                	push   $0x0
  pushl $146
80107b54:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107b59:	e9 8b f3 ff ff       	jmp    80106ee9 <alltraps>

80107b5e <vector147>:
.globl vector147
vector147:
  pushl $0
80107b5e:	6a 00                	push   $0x0
  pushl $147
80107b60:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107b65:	e9 7f f3 ff ff       	jmp    80106ee9 <alltraps>

80107b6a <vector148>:
.globl vector148
vector148:
  pushl $0
80107b6a:	6a 00                	push   $0x0
  pushl $148
80107b6c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107b71:	e9 73 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b76 <vector149>:
.globl vector149
vector149:
  pushl $0
80107b76:	6a 00                	push   $0x0
  pushl $149
80107b78:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107b7d:	e9 67 f3 ff ff       	jmp    80106ee9 <alltraps>

80107b82 <vector150>:
.globl vector150
vector150:
  pushl $0
80107b82:	6a 00                	push   $0x0
  pushl $150
80107b84:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107b89:	e9 5b f3 ff ff       	jmp    80106ee9 <alltraps>

80107b8e <vector151>:
.globl vector151
vector151:
  pushl $0
80107b8e:	6a 00                	push   $0x0
  pushl $151
80107b90:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107b95:	e9 4f f3 ff ff       	jmp    80106ee9 <alltraps>

80107b9a <vector152>:
.globl vector152
vector152:
  pushl $0
80107b9a:	6a 00                	push   $0x0
  pushl $152
80107b9c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107ba1:	e9 43 f3 ff ff       	jmp    80106ee9 <alltraps>

80107ba6 <vector153>:
.globl vector153
vector153:
  pushl $0
80107ba6:	6a 00                	push   $0x0
  pushl $153
80107ba8:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107bad:	e9 37 f3 ff ff       	jmp    80106ee9 <alltraps>

80107bb2 <vector154>:
.globl vector154
vector154:
  pushl $0
80107bb2:	6a 00                	push   $0x0
  pushl $154
80107bb4:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107bb9:	e9 2b f3 ff ff       	jmp    80106ee9 <alltraps>

80107bbe <vector155>:
.globl vector155
vector155:
  pushl $0
80107bbe:	6a 00                	push   $0x0
  pushl $155
80107bc0:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107bc5:	e9 1f f3 ff ff       	jmp    80106ee9 <alltraps>

80107bca <vector156>:
.globl vector156
vector156:
  pushl $0
80107bca:	6a 00                	push   $0x0
  pushl $156
80107bcc:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107bd1:	e9 13 f3 ff ff       	jmp    80106ee9 <alltraps>

80107bd6 <vector157>:
.globl vector157
vector157:
  pushl $0
80107bd6:	6a 00                	push   $0x0
  pushl $157
80107bd8:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107bdd:	e9 07 f3 ff ff       	jmp    80106ee9 <alltraps>

80107be2 <vector158>:
.globl vector158
vector158:
  pushl $0
80107be2:	6a 00                	push   $0x0
  pushl $158
80107be4:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107be9:	e9 fb f2 ff ff       	jmp    80106ee9 <alltraps>

80107bee <vector159>:
.globl vector159
vector159:
  pushl $0
80107bee:	6a 00                	push   $0x0
  pushl $159
80107bf0:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107bf5:	e9 ef f2 ff ff       	jmp    80106ee9 <alltraps>

80107bfa <vector160>:
.globl vector160
vector160:
  pushl $0
80107bfa:	6a 00                	push   $0x0
  pushl $160
80107bfc:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107c01:	e9 e3 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c06 <vector161>:
.globl vector161
vector161:
  pushl $0
80107c06:	6a 00                	push   $0x0
  pushl $161
80107c08:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107c0d:	e9 d7 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c12 <vector162>:
.globl vector162
vector162:
  pushl $0
80107c12:	6a 00                	push   $0x0
  pushl $162
80107c14:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107c19:	e9 cb f2 ff ff       	jmp    80106ee9 <alltraps>

80107c1e <vector163>:
.globl vector163
vector163:
  pushl $0
80107c1e:	6a 00                	push   $0x0
  pushl $163
80107c20:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107c25:	e9 bf f2 ff ff       	jmp    80106ee9 <alltraps>

80107c2a <vector164>:
.globl vector164
vector164:
  pushl $0
80107c2a:	6a 00                	push   $0x0
  pushl $164
80107c2c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107c31:	e9 b3 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c36 <vector165>:
.globl vector165
vector165:
  pushl $0
80107c36:	6a 00                	push   $0x0
  pushl $165
80107c38:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107c3d:	e9 a7 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c42 <vector166>:
.globl vector166
vector166:
  pushl $0
80107c42:	6a 00                	push   $0x0
  pushl $166
80107c44:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107c49:	e9 9b f2 ff ff       	jmp    80106ee9 <alltraps>

80107c4e <vector167>:
.globl vector167
vector167:
  pushl $0
80107c4e:	6a 00                	push   $0x0
  pushl $167
80107c50:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107c55:	e9 8f f2 ff ff       	jmp    80106ee9 <alltraps>

80107c5a <vector168>:
.globl vector168
vector168:
  pushl $0
80107c5a:	6a 00                	push   $0x0
  pushl $168
80107c5c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107c61:	e9 83 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c66 <vector169>:
.globl vector169
vector169:
  pushl $0
80107c66:	6a 00                	push   $0x0
  pushl $169
80107c68:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107c6d:	e9 77 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c72 <vector170>:
.globl vector170
vector170:
  pushl $0
80107c72:	6a 00                	push   $0x0
  pushl $170
80107c74:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107c79:	e9 6b f2 ff ff       	jmp    80106ee9 <alltraps>

80107c7e <vector171>:
.globl vector171
vector171:
  pushl $0
80107c7e:	6a 00                	push   $0x0
  pushl $171
80107c80:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107c85:	e9 5f f2 ff ff       	jmp    80106ee9 <alltraps>

80107c8a <vector172>:
.globl vector172
vector172:
  pushl $0
80107c8a:	6a 00                	push   $0x0
  pushl $172
80107c8c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107c91:	e9 53 f2 ff ff       	jmp    80106ee9 <alltraps>

80107c96 <vector173>:
.globl vector173
vector173:
  pushl $0
80107c96:	6a 00                	push   $0x0
  pushl $173
80107c98:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107c9d:	e9 47 f2 ff ff       	jmp    80106ee9 <alltraps>

80107ca2 <vector174>:
.globl vector174
vector174:
  pushl $0
80107ca2:	6a 00                	push   $0x0
  pushl $174
80107ca4:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107ca9:	e9 3b f2 ff ff       	jmp    80106ee9 <alltraps>

80107cae <vector175>:
.globl vector175
vector175:
  pushl $0
80107cae:	6a 00                	push   $0x0
  pushl $175
80107cb0:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107cb5:	e9 2f f2 ff ff       	jmp    80106ee9 <alltraps>

80107cba <vector176>:
.globl vector176
vector176:
  pushl $0
80107cba:	6a 00                	push   $0x0
  pushl $176
80107cbc:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107cc1:	e9 23 f2 ff ff       	jmp    80106ee9 <alltraps>

80107cc6 <vector177>:
.globl vector177
vector177:
  pushl $0
80107cc6:	6a 00                	push   $0x0
  pushl $177
80107cc8:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107ccd:	e9 17 f2 ff ff       	jmp    80106ee9 <alltraps>

80107cd2 <vector178>:
.globl vector178
vector178:
  pushl $0
80107cd2:	6a 00                	push   $0x0
  pushl $178
80107cd4:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107cd9:	e9 0b f2 ff ff       	jmp    80106ee9 <alltraps>

80107cde <vector179>:
.globl vector179
vector179:
  pushl $0
80107cde:	6a 00                	push   $0x0
  pushl $179
80107ce0:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107ce5:	e9 ff f1 ff ff       	jmp    80106ee9 <alltraps>

80107cea <vector180>:
.globl vector180
vector180:
  pushl $0
80107cea:	6a 00                	push   $0x0
  pushl $180
80107cec:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107cf1:	e9 f3 f1 ff ff       	jmp    80106ee9 <alltraps>

80107cf6 <vector181>:
.globl vector181
vector181:
  pushl $0
80107cf6:	6a 00                	push   $0x0
  pushl $181
80107cf8:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107cfd:	e9 e7 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d02 <vector182>:
.globl vector182
vector182:
  pushl $0
80107d02:	6a 00                	push   $0x0
  pushl $182
80107d04:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107d09:	e9 db f1 ff ff       	jmp    80106ee9 <alltraps>

80107d0e <vector183>:
.globl vector183
vector183:
  pushl $0
80107d0e:	6a 00                	push   $0x0
  pushl $183
80107d10:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107d15:	e9 cf f1 ff ff       	jmp    80106ee9 <alltraps>

80107d1a <vector184>:
.globl vector184
vector184:
  pushl $0
80107d1a:	6a 00                	push   $0x0
  pushl $184
80107d1c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107d21:	e9 c3 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d26 <vector185>:
.globl vector185
vector185:
  pushl $0
80107d26:	6a 00                	push   $0x0
  pushl $185
80107d28:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107d2d:	e9 b7 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d32 <vector186>:
.globl vector186
vector186:
  pushl $0
80107d32:	6a 00                	push   $0x0
  pushl $186
80107d34:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107d39:	e9 ab f1 ff ff       	jmp    80106ee9 <alltraps>

80107d3e <vector187>:
.globl vector187
vector187:
  pushl $0
80107d3e:	6a 00                	push   $0x0
  pushl $187
80107d40:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107d45:	e9 9f f1 ff ff       	jmp    80106ee9 <alltraps>

80107d4a <vector188>:
.globl vector188
vector188:
  pushl $0
80107d4a:	6a 00                	push   $0x0
  pushl $188
80107d4c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107d51:	e9 93 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d56 <vector189>:
.globl vector189
vector189:
  pushl $0
80107d56:	6a 00                	push   $0x0
  pushl $189
80107d58:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107d5d:	e9 87 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d62 <vector190>:
.globl vector190
vector190:
  pushl $0
80107d62:	6a 00                	push   $0x0
  pushl $190
80107d64:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107d69:	e9 7b f1 ff ff       	jmp    80106ee9 <alltraps>

80107d6e <vector191>:
.globl vector191
vector191:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $191
80107d70:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107d75:	e9 6f f1 ff ff       	jmp    80106ee9 <alltraps>

80107d7a <vector192>:
.globl vector192
vector192:
  pushl $0
80107d7a:	6a 00                	push   $0x0
  pushl $192
80107d7c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107d81:	e9 63 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d86 <vector193>:
.globl vector193
vector193:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $193
80107d88:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107d8d:	e9 57 f1 ff ff       	jmp    80106ee9 <alltraps>

80107d92 <vector194>:
.globl vector194
vector194:
  pushl $0
80107d92:	6a 00                	push   $0x0
  pushl $194
80107d94:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107d99:	e9 4b f1 ff ff       	jmp    80106ee9 <alltraps>

80107d9e <vector195>:
.globl vector195
vector195:
  pushl $0
80107d9e:	6a 00                	push   $0x0
  pushl $195
80107da0:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107da5:	e9 3f f1 ff ff       	jmp    80106ee9 <alltraps>

80107daa <vector196>:
.globl vector196
vector196:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $196
80107dac:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107db1:	e9 33 f1 ff ff       	jmp    80106ee9 <alltraps>

80107db6 <vector197>:
.globl vector197
vector197:
  pushl $0
80107db6:	6a 00                	push   $0x0
  pushl $197
80107db8:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107dbd:	e9 27 f1 ff ff       	jmp    80106ee9 <alltraps>

80107dc2 <vector198>:
.globl vector198
vector198:
  pushl $0
80107dc2:	6a 00                	push   $0x0
  pushl $198
80107dc4:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107dc9:	e9 1b f1 ff ff       	jmp    80106ee9 <alltraps>

80107dce <vector199>:
.globl vector199
vector199:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $199
80107dd0:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107dd5:	e9 0f f1 ff ff       	jmp    80106ee9 <alltraps>

80107dda <vector200>:
.globl vector200
vector200:
  pushl $0
80107dda:	6a 00                	push   $0x0
  pushl $200
80107ddc:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107de1:	e9 03 f1 ff ff       	jmp    80106ee9 <alltraps>

80107de6 <vector201>:
.globl vector201
vector201:
  pushl $0
80107de6:	6a 00                	push   $0x0
  pushl $201
80107de8:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107ded:	e9 f7 f0 ff ff       	jmp    80106ee9 <alltraps>

80107df2 <vector202>:
.globl vector202
vector202:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $202
80107df4:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107df9:	e9 eb f0 ff ff       	jmp    80106ee9 <alltraps>

80107dfe <vector203>:
.globl vector203
vector203:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $203
80107e00:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107e05:	e9 df f0 ff ff       	jmp    80106ee9 <alltraps>

80107e0a <vector204>:
.globl vector204
vector204:
  pushl $0
80107e0a:	6a 00                	push   $0x0
  pushl $204
80107e0c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107e11:	e9 d3 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e16 <vector205>:
.globl vector205
vector205:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $205
80107e18:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107e1d:	e9 c7 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e22 <vector206>:
.globl vector206
vector206:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $206
80107e24:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107e29:	e9 bb f0 ff ff       	jmp    80106ee9 <alltraps>

80107e2e <vector207>:
.globl vector207
vector207:
  pushl $0
80107e2e:	6a 00                	push   $0x0
  pushl $207
80107e30:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107e35:	e9 af f0 ff ff       	jmp    80106ee9 <alltraps>

80107e3a <vector208>:
.globl vector208
vector208:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $208
80107e3c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107e41:	e9 a3 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e46 <vector209>:
.globl vector209
vector209:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $209
80107e48:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107e4d:	e9 97 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e52 <vector210>:
.globl vector210
vector210:
  pushl $0
80107e52:	6a 00                	push   $0x0
  pushl $210
80107e54:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107e59:	e9 8b f0 ff ff       	jmp    80106ee9 <alltraps>

80107e5e <vector211>:
.globl vector211
vector211:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $211
80107e60:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107e65:	e9 7f f0 ff ff       	jmp    80106ee9 <alltraps>

80107e6a <vector212>:
.globl vector212
vector212:
  pushl $0
80107e6a:	6a 00                	push   $0x0
  pushl $212
80107e6c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107e71:	e9 73 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e76 <vector213>:
.globl vector213
vector213:
  pushl $0
80107e76:	6a 00                	push   $0x0
  pushl $213
80107e78:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107e7d:	e9 67 f0 ff ff       	jmp    80106ee9 <alltraps>

80107e82 <vector214>:
.globl vector214
vector214:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $214
80107e84:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107e89:	e9 5b f0 ff ff       	jmp    80106ee9 <alltraps>

80107e8e <vector215>:
.globl vector215
vector215:
  pushl $0
80107e8e:	6a 00                	push   $0x0
  pushl $215
80107e90:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107e95:	e9 4f f0 ff ff       	jmp    80106ee9 <alltraps>

80107e9a <vector216>:
.globl vector216
vector216:
  pushl $0
80107e9a:	6a 00                	push   $0x0
  pushl $216
80107e9c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107ea1:	e9 43 f0 ff ff       	jmp    80106ee9 <alltraps>

80107ea6 <vector217>:
.globl vector217
vector217:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $217
80107ea8:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107ead:	e9 37 f0 ff ff       	jmp    80106ee9 <alltraps>

80107eb2 <vector218>:
.globl vector218
vector218:
  pushl $0
80107eb2:	6a 00                	push   $0x0
  pushl $218
80107eb4:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107eb9:	e9 2b f0 ff ff       	jmp    80106ee9 <alltraps>

80107ebe <vector219>:
.globl vector219
vector219:
  pushl $0
80107ebe:	6a 00                	push   $0x0
  pushl $219
80107ec0:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107ec5:	e9 1f f0 ff ff       	jmp    80106ee9 <alltraps>

80107eca <vector220>:
.globl vector220
vector220:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $220
80107ecc:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107ed1:	e9 13 f0 ff ff       	jmp    80106ee9 <alltraps>

80107ed6 <vector221>:
.globl vector221
vector221:
  pushl $0
80107ed6:	6a 00                	push   $0x0
  pushl $221
80107ed8:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107edd:	e9 07 f0 ff ff       	jmp    80106ee9 <alltraps>

80107ee2 <vector222>:
.globl vector222
vector222:
  pushl $0
80107ee2:	6a 00                	push   $0x0
  pushl $222
80107ee4:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107ee9:	e9 fb ef ff ff       	jmp    80106ee9 <alltraps>

80107eee <vector223>:
.globl vector223
vector223:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $223
80107ef0:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107ef5:	e9 ef ef ff ff       	jmp    80106ee9 <alltraps>

80107efa <vector224>:
.globl vector224
vector224:
  pushl $0
80107efa:	6a 00                	push   $0x0
  pushl $224
80107efc:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107f01:	e9 e3 ef ff ff       	jmp    80106ee9 <alltraps>

80107f06 <vector225>:
.globl vector225
vector225:
  pushl $0
80107f06:	6a 00                	push   $0x0
  pushl $225
80107f08:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107f0d:	e9 d7 ef ff ff       	jmp    80106ee9 <alltraps>

80107f12 <vector226>:
.globl vector226
vector226:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $226
80107f14:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107f19:	e9 cb ef ff ff       	jmp    80106ee9 <alltraps>

80107f1e <vector227>:
.globl vector227
vector227:
  pushl $0
80107f1e:	6a 00                	push   $0x0
  pushl $227
80107f20:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107f25:	e9 bf ef ff ff       	jmp    80106ee9 <alltraps>

80107f2a <vector228>:
.globl vector228
vector228:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $228
80107f2c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107f31:	e9 b3 ef ff ff       	jmp    80106ee9 <alltraps>

80107f36 <vector229>:
.globl vector229
vector229:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $229
80107f38:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107f3d:	e9 a7 ef ff ff       	jmp    80106ee9 <alltraps>

80107f42 <vector230>:
.globl vector230
vector230:
  pushl $0
80107f42:	6a 00                	push   $0x0
  pushl $230
80107f44:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107f49:	e9 9b ef ff ff       	jmp    80106ee9 <alltraps>

80107f4e <vector231>:
.globl vector231
vector231:
  pushl $0
80107f4e:	6a 00                	push   $0x0
  pushl $231
80107f50:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107f55:	e9 8f ef ff ff       	jmp    80106ee9 <alltraps>

80107f5a <vector232>:
.globl vector232
vector232:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $232
80107f5c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107f61:	e9 83 ef ff ff       	jmp    80106ee9 <alltraps>

80107f66 <vector233>:
.globl vector233
vector233:
  pushl $0
80107f66:	6a 00                	push   $0x0
  pushl $233
80107f68:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107f6d:	e9 77 ef ff ff       	jmp    80106ee9 <alltraps>

80107f72 <vector234>:
.globl vector234
vector234:
  pushl $0
80107f72:	6a 00                	push   $0x0
  pushl $234
80107f74:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107f79:	e9 6b ef ff ff       	jmp    80106ee9 <alltraps>

80107f7e <vector235>:
.globl vector235
vector235:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $235
80107f80:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107f85:	e9 5f ef ff ff       	jmp    80106ee9 <alltraps>

80107f8a <vector236>:
.globl vector236
vector236:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $236
80107f8c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107f91:	e9 53 ef ff ff       	jmp    80106ee9 <alltraps>

80107f96 <vector237>:
.globl vector237
vector237:
  pushl $0
80107f96:	6a 00                	push   $0x0
  pushl $237
80107f98:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107f9d:	e9 47 ef ff ff       	jmp    80106ee9 <alltraps>

80107fa2 <vector238>:
.globl vector238
vector238:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $238
80107fa4:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107fa9:	e9 3b ef ff ff       	jmp    80106ee9 <alltraps>

80107fae <vector239>:
.globl vector239
vector239:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $239
80107fb0:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107fb5:	e9 2f ef ff ff       	jmp    80106ee9 <alltraps>

80107fba <vector240>:
.globl vector240
vector240:
  pushl $0
80107fba:	6a 00                	push   $0x0
  pushl $240
80107fbc:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107fc1:	e9 23 ef ff ff       	jmp    80106ee9 <alltraps>

80107fc6 <vector241>:
.globl vector241
vector241:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $241
80107fc8:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107fcd:	e9 17 ef ff ff       	jmp    80106ee9 <alltraps>

80107fd2 <vector242>:
.globl vector242
vector242:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $242
80107fd4:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107fd9:	e9 0b ef ff ff       	jmp    80106ee9 <alltraps>

80107fde <vector243>:
.globl vector243
vector243:
  pushl $0
80107fde:	6a 00                	push   $0x0
  pushl $243
80107fe0:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107fe5:	e9 ff ee ff ff       	jmp    80106ee9 <alltraps>

80107fea <vector244>:
.globl vector244
vector244:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $244
80107fec:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107ff1:	e9 f3 ee ff ff       	jmp    80106ee9 <alltraps>

80107ff6 <vector245>:
.globl vector245
vector245:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $245
80107ff8:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107ffd:	e9 e7 ee ff ff       	jmp    80106ee9 <alltraps>

80108002 <vector246>:
.globl vector246
vector246:
  pushl $0
80108002:	6a 00                	push   $0x0
  pushl $246
80108004:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108009:	e9 db ee ff ff       	jmp    80106ee9 <alltraps>

8010800e <vector247>:
.globl vector247
vector247:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $247
80108010:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108015:	e9 cf ee ff ff       	jmp    80106ee9 <alltraps>

8010801a <vector248>:
.globl vector248
vector248:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $248
8010801c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108021:	e9 c3 ee ff ff       	jmp    80106ee9 <alltraps>

80108026 <vector249>:
.globl vector249
vector249:
  pushl $0
80108026:	6a 00                	push   $0x0
  pushl $249
80108028:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010802d:	e9 b7 ee ff ff       	jmp    80106ee9 <alltraps>

80108032 <vector250>:
.globl vector250
vector250:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $250
80108034:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108039:	e9 ab ee ff ff       	jmp    80106ee9 <alltraps>

8010803e <vector251>:
.globl vector251
vector251:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $251
80108040:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108045:	e9 9f ee ff ff       	jmp    80106ee9 <alltraps>

8010804a <vector252>:
.globl vector252
vector252:
  pushl $0
8010804a:	6a 00                	push   $0x0
  pushl $252
8010804c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108051:	e9 93 ee ff ff       	jmp    80106ee9 <alltraps>

80108056 <vector253>:
.globl vector253
vector253:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $253
80108058:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010805d:	e9 87 ee ff ff       	jmp    80106ee9 <alltraps>

80108062 <vector254>:
.globl vector254
vector254:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $254
80108064:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108069:	e9 7b ee ff ff       	jmp    80106ee9 <alltraps>

8010806e <vector255>:
.globl vector255
vector255:
  pushl $0
8010806e:	6a 00                	push   $0x0
  pushl $255
80108070:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108075:	e9 6f ee ff ff       	jmp    80106ee9 <alltraps>

8010807a <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010807a:	55                   	push   %ebp
8010807b:	89 e5                	mov    %esp,%ebp
8010807d:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108080:	8b 45 0c             	mov    0xc(%ebp),%eax
80108083:	83 e8 01             	sub    $0x1,%eax
80108086:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010808a:	8b 45 08             	mov    0x8(%ebp),%eax
8010808d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108091:	8b 45 08             	mov    0x8(%ebp),%eax
80108094:	c1 e8 10             	shr    $0x10,%eax
80108097:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010809b:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010809e:	0f 01 10             	lgdtl  (%eax)
}
801080a1:	c9                   	leave  
801080a2:	c3                   	ret    

801080a3 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801080a3:	55                   	push   %ebp
801080a4:	89 e5                	mov    %esp,%ebp
801080a6:	83 ec 04             	sub    $0x4,%esp
801080a9:	8b 45 08             	mov    0x8(%ebp),%eax
801080ac:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801080b0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801080b4:	0f 00 d8             	ltr    %ax
}
801080b7:	c9                   	leave  
801080b8:	c3                   	ret    

801080b9 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801080b9:	55                   	push   %ebp
801080ba:	89 e5                	mov    %esp,%ebp
801080bc:	83 ec 04             	sub    $0x4,%esp
801080bf:	8b 45 08             	mov    0x8(%ebp),%eax
801080c2:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801080c6:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801080ca:	8e e8                	mov    %eax,%gs
}
801080cc:	c9                   	leave  
801080cd:	c3                   	ret    

801080ce <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801080ce:	55                   	push   %ebp
801080cf:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801080d1:	8b 45 08             	mov    0x8(%ebp),%eax
801080d4:	0f 22 d8             	mov    %eax,%cr3
}
801080d7:	5d                   	pop    %ebp
801080d8:	c3                   	ret    

801080d9 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801080d9:	55                   	push   %ebp
801080da:	89 e5                	mov    %esp,%ebp
801080dc:	8b 45 08             	mov    0x8(%ebp),%eax
801080df:	05 00 00 00 80       	add    $0x80000000,%eax
801080e4:	5d                   	pop    %ebp
801080e5:	c3                   	ret    

801080e6 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801080e6:	55                   	push   %ebp
801080e7:	89 e5                	mov    %esp,%ebp
801080e9:	8b 45 08             	mov    0x8(%ebp),%eax
801080ec:	05 00 00 00 80       	add    $0x80000000,%eax
801080f1:	5d                   	pop    %ebp
801080f2:	c3                   	ret    

801080f3 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801080f3:	55                   	push   %ebp
801080f4:	89 e5                	mov    %esp,%ebp
801080f6:	53                   	push   %ebx
801080f7:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801080fa:	e8 9c b5 ff ff       	call   8010369b <cpunum>
801080ff:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108105:	05 60 43 11 80       	add    $0x80114360,%eax
8010810a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010810d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108110:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108116:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108119:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010811f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108122:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108129:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010812d:	83 e2 f0             	and    $0xfffffff0,%edx
80108130:	83 ca 0a             	or     $0xa,%edx
80108133:	88 50 7d             	mov    %dl,0x7d(%eax)
80108136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108139:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010813d:	83 ca 10             	or     $0x10,%edx
80108140:	88 50 7d             	mov    %dl,0x7d(%eax)
80108143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108146:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010814a:	83 e2 9f             	and    $0xffffff9f,%edx
8010814d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108153:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108157:	83 ca 80             	or     $0xffffff80,%edx
8010815a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010815d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108160:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108164:	83 ca 0f             	or     $0xf,%edx
80108167:	88 50 7e             	mov    %dl,0x7e(%eax)
8010816a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108171:	83 e2 ef             	and    $0xffffffef,%edx
80108174:	88 50 7e             	mov    %dl,0x7e(%eax)
80108177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010817e:	83 e2 df             	and    $0xffffffdf,%edx
80108181:	88 50 7e             	mov    %dl,0x7e(%eax)
80108184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108187:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010818b:	83 ca 40             	or     $0x40,%edx
8010818e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108191:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108194:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108198:	83 ca 80             	or     $0xffffff80,%edx
8010819b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010819e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a1:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801081a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a8:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801081af:	ff ff 
801081b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b4:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801081bb:	00 00 
801081bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c0:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801081c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ca:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081d1:	83 e2 f0             	and    $0xfffffff0,%edx
801081d4:	83 ca 02             	or     $0x2,%edx
801081d7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081e7:	83 ca 10             	or     $0x10,%edx
801081ea:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f3:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081fa:	83 e2 9f             	and    $0xffffff9f,%edx
801081fd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108206:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010820d:	83 ca 80             	or     $0xffffff80,%edx
80108210:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108219:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108220:	83 ca 0f             	or     $0xf,%edx
80108223:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108229:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108233:	83 e2 ef             	and    $0xffffffef,%edx
80108236:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010823c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108246:	83 e2 df             	and    $0xffffffdf,%edx
80108249:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010824f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108252:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108259:	83 ca 40             	or     $0x40,%edx
8010825c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108262:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108265:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010826c:	83 ca 80             	or     $0xffffff80,%edx
8010826f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108278:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010827f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108282:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108289:	ff ff 
8010828b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828e:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108295:	00 00 
80108297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829a:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801082a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082ab:	83 e2 f0             	and    $0xfffffff0,%edx
801082ae:	83 ca 0a             	or     $0xa,%edx
801082b1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ba:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082c1:	83 ca 10             	or     $0x10,%edx
801082c4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082cd:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082d4:	83 ca 60             	or     $0x60,%edx
801082d7:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082e7:	83 ca 80             	or     $0xffffff80,%edx
801082ea:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801082fa:	83 ca 0f             	or     $0xf,%edx
801082fd:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108303:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108306:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010830d:	83 e2 ef             	and    $0xffffffef,%edx
80108310:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108319:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108320:	83 e2 df             	and    $0xffffffdf,%edx
80108323:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108329:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832c:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108333:	83 ca 40             	or     $0x40,%edx
80108336:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010833c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108346:	83 ca 80             	or     $0xffffff80,%edx
80108349:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010834f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108352:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835c:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108363:	ff ff 
80108365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108368:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010836f:	00 00 
80108371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108374:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010837b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108385:	83 e2 f0             	and    $0xfffffff0,%edx
80108388:	83 ca 02             	or     $0x2,%edx
8010838b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108394:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010839b:	83 ca 10             	or     $0x10,%edx
8010839e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801083a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a7:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801083ae:	83 ca 60             	or     $0x60,%edx
801083b1:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801083b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ba:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801083c1:	83 ca 80             	or     $0xffffff80,%edx
801083c4:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801083ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083cd:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083d4:	83 ca 0f             	or     $0xf,%edx
801083d7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083e7:	83 e2 ef             	and    $0xffffffef,%edx
801083ea:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083fa:	83 e2 df             	and    $0xffffffdf,%edx
801083fd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108406:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010840d:	83 ca 40             	or     $0x40,%edx
80108410:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108416:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108419:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108420:	83 ca 80             	or     $0xffffff80,%edx
80108423:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108429:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842c:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108436:	05 b4 00 00 00       	add    $0xb4,%eax
8010843b:	89 c3                	mov    %eax,%ebx
8010843d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108440:	05 b4 00 00 00       	add    $0xb4,%eax
80108445:	c1 e8 10             	shr    $0x10,%eax
80108448:	89 c1                	mov    %eax,%ecx
8010844a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844d:	05 b4 00 00 00       	add    $0xb4,%eax
80108452:	c1 e8 18             	shr    $0x18,%eax
80108455:	89 c2                	mov    %eax,%edx
80108457:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845a:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108461:	00 00 
80108463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108466:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010846d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108470:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108479:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108480:	83 e1 f0             	and    $0xfffffff0,%ecx
80108483:	83 c9 02             	or     $0x2,%ecx
80108486:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010848c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010848f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108496:	83 c9 10             	or     $0x10,%ecx
80108499:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010849f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a2:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801084a9:	83 e1 9f             	and    $0xffffff9f,%ecx
801084ac:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801084b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084b5:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801084bc:	83 c9 80             	or     $0xffffff80,%ecx
801084bf:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801084c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084c8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084cf:	83 e1 f0             	and    $0xfffffff0,%ecx
801084d2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084db:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084e2:	83 e1 ef             	and    $0xffffffef,%ecx
801084e5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ee:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084f5:	83 e1 df             	and    $0xffffffdf,%ecx
801084f8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108501:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108508:	83 c9 40             	or     $0x40,%ecx
8010850b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108514:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010851b:	83 c9 80             	or     $0xffffff80,%ecx
8010851e:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108524:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108527:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010852d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108530:	83 c0 70             	add    $0x70,%eax
80108533:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010853a:	00 
8010853b:	89 04 24             	mov    %eax,(%esp)
8010853e:	e8 37 fb ff ff       	call   8010807a <lgdt>
  loadgs(SEG_KCPU << 3);
80108543:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010854a:	e8 6a fb ff ff       	call   801080b9 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010854f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108552:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108558:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010855f:	00 00 00 00 
}
80108563:	83 c4 24             	add    $0x24,%esp
80108566:	5b                   	pop    %ebx
80108567:	5d                   	pop    %ebp
80108568:	c3                   	ret    

80108569 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108569:	55                   	push   %ebp
8010856a:	89 e5                	mov    %esp,%ebp
8010856c:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010856f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108572:	c1 e8 16             	shr    $0x16,%eax
80108575:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010857c:	8b 45 08             	mov    0x8(%ebp),%eax
8010857f:	01 d0                	add    %edx,%eax
80108581:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108584:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108587:	8b 00                	mov    (%eax),%eax
80108589:	83 e0 01             	and    $0x1,%eax
8010858c:	85 c0                	test   %eax,%eax
8010858e:	74 17                	je     801085a7 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108590:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108593:	8b 00                	mov    (%eax),%eax
80108595:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010859a:	89 04 24             	mov    %eax,(%esp)
8010859d:	e8 44 fb ff ff       	call   801080e6 <p2v>
801085a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801085a5:	eb 4b                	jmp    801085f2 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801085a7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801085ab:	74 0e                	je     801085bb <walkpgdir+0x52>
801085ad:	e8 0d ad ff ff       	call   801032bf <kalloc>
801085b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801085b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801085b9:	75 07                	jne    801085c2 <walkpgdir+0x59>
      return 0;
801085bb:	b8 00 00 00 00       	mov    $0x0,%eax
801085c0:	eb 47                	jmp    80108609 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801085c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085c9:	00 
801085ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085d1:	00 
801085d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d5:	89 04 24             	mov    %eax,(%esp)
801085d8:	e8 18 d5 ff ff       	call   80105af5 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801085dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e0:	89 04 24             	mov    %eax,(%esp)
801085e3:	e8 f1 fa ff ff       	call   801080d9 <v2p>
801085e8:	83 c8 07             	or     $0x7,%eax
801085eb:	89 c2                	mov    %eax,%edx
801085ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085f0:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801085f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801085f5:	c1 e8 0c             	shr    $0xc,%eax
801085f8:	25 ff 03 00 00       	and    $0x3ff,%eax
801085fd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108607:	01 d0                	add    %edx,%eax
}
80108609:	c9                   	leave  
8010860a:	c3                   	ret    

8010860b <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010860b:	55                   	push   %ebp
8010860c:	89 e5                	mov    %esp,%ebp
8010860e:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108611:	8b 45 0c             	mov    0xc(%ebp),%eax
80108614:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108619:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010861c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010861f:	8b 45 10             	mov    0x10(%ebp),%eax
80108622:	01 d0                	add    %edx,%eax
80108624:	83 e8 01             	sub    $0x1,%eax
80108627:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010862c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010862f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108636:	00 
80108637:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010863a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010863e:	8b 45 08             	mov    0x8(%ebp),%eax
80108641:	89 04 24             	mov    %eax,(%esp)
80108644:	e8 20 ff ff ff       	call   80108569 <walkpgdir>
80108649:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010864c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108650:	75 07                	jne    80108659 <mappages+0x4e>
      return -1;
80108652:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108657:	eb 48                	jmp    801086a1 <mappages+0x96>
    if(*pte & PTE_P)
80108659:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010865c:	8b 00                	mov    (%eax),%eax
8010865e:	83 e0 01             	and    $0x1,%eax
80108661:	85 c0                	test   %eax,%eax
80108663:	74 0c                	je     80108671 <mappages+0x66>
      panic("remap");
80108665:	c7 04 24 04 a3 10 80 	movl   $0x8010a304,(%esp)
8010866c:	e8 c9 7e ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108671:	8b 45 18             	mov    0x18(%ebp),%eax
80108674:	0b 45 14             	or     0x14(%ebp),%eax
80108677:	83 c8 01             	or     $0x1,%eax
8010867a:	89 c2                	mov    %eax,%edx
8010867c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010867f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108681:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108684:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108687:	75 08                	jne    80108691 <mappages+0x86>
      break;
80108689:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010868a:	b8 00 00 00 00       	mov    $0x0,%eax
8010868f:	eb 10                	jmp    801086a1 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80108691:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108698:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010869f:	eb 8e                	jmp    8010862f <mappages+0x24>
  return 0;
}
801086a1:	c9                   	leave  
801086a2:	c3                   	ret    

801086a3 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801086a3:	55                   	push   %ebp
801086a4:	89 e5                	mov    %esp,%ebp
801086a6:	53                   	push   %ebx
801086a7:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801086aa:	e8 10 ac ff ff       	call   801032bf <kalloc>
801086af:	89 45 f0             	mov    %eax,-0x10(%ebp)
801086b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801086b6:	75 0a                	jne    801086c2 <setupkvm+0x1f>
    return 0;
801086b8:	b8 00 00 00 00       	mov    $0x0,%eax
801086bd:	e9 98 00 00 00       	jmp    8010875a <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801086c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801086c9:	00 
801086ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801086d1:	00 
801086d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801086d5:	89 04 24             	mov    %eax,(%esp)
801086d8:	e8 18 d4 ff ff       	call   80105af5 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801086dd:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801086e4:	e8 fd f9 ff ff       	call   801080e6 <p2v>
801086e9:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801086ee:	76 0c                	jbe    801086fc <setupkvm+0x59>
    panic("PHYSTOP too high");
801086f0:	c7 04 24 0a a3 10 80 	movl   $0x8010a30a,(%esp)
801086f7:	e8 3e 7e ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801086fc:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
80108703:	eb 49                	jmp    8010874e <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108705:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108708:	8b 48 0c             	mov    0xc(%eax),%ecx
8010870b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010870e:	8b 50 04             	mov    0x4(%eax),%edx
80108711:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108714:	8b 58 08             	mov    0x8(%eax),%ebx
80108717:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010871a:	8b 40 04             	mov    0x4(%eax),%eax
8010871d:	29 c3                	sub    %eax,%ebx
8010871f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108722:	8b 00                	mov    (%eax),%eax
80108724:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108728:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010872c:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108730:	89 44 24 04          	mov    %eax,0x4(%esp)
80108734:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108737:	89 04 24             	mov    %eax,(%esp)
8010873a:	e8 cc fe ff ff       	call   8010860b <mappages>
8010873f:	85 c0                	test   %eax,%eax
80108741:	79 07                	jns    8010874a <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108743:	b8 00 00 00 00       	mov    $0x0,%eax
80108748:	eb 10                	jmp    8010875a <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010874a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010874e:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108755:	72 ae                	jb     80108705 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
80108757:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
8010875a:	83 c4 34             	add    $0x34,%esp
8010875d:	5b                   	pop    %ebx
8010875e:	5d                   	pop    %ebp
8010875f:	c3                   	ret    

80108760 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
80108760:	55                   	push   %ebp
80108761:	89 e5                	mov    %esp,%ebp
80108763:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
80108766:	e8 38 ff ff ff       	call   801086a3 <setupkvm>
8010876b:	a3 58 0e 12 80       	mov    %eax,0x80120e58
    switchkvm();
80108770:	e8 02 00 00 00       	call   80108777 <switchkvm>
  }
80108775:	c9                   	leave  
80108776:	c3                   	ret    

80108777 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
80108777:	55                   	push   %ebp
80108778:	89 e5                	mov    %esp,%ebp
8010877a:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
8010877d:	a1 58 0e 12 80       	mov    0x80120e58,%eax
80108782:	89 04 24             	mov    %eax,(%esp)
80108785:	e8 4f f9 ff ff       	call   801080d9 <v2p>
8010878a:	89 04 24             	mov    %eax,(%esp)
8010878d:	e8 3c f9 ff ff       	call   801080ce <lcr3>
}
80108792:	c9                   	leave  
80108793:	c3                   	ret    

80108794 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108794:	55                   	push   %ebp
80108795:	89 e5                	mov    %esp,%ebp
80108797:	53                   	push   %ebx
80108798:	83 ec 14             	sub    $0x14,%esp
  pushcli();
8010879b:	e8 55 d2 ff ff       	call   801059f5 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801087a0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087a6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801087ad:	83 c2 08             	add    $0x8,%edx
801087b0:	89 d3                	mov    %edx,%ebx
801087b2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801087b9:	83 c2 08             	add    $0x8,%edx
801087bc:	c1 ea 10             	shr    $0x10,%edx
801087bf:	89 d1                	mov    %edx,%ecx
801087c1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801087c8:	83 c2 08             	add    $0x8,%edx
801087cb:	c1 ea 18             	shr    $0x18,%edx
801087ce:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801087d5:	67 00 
801087d7:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801087de:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801087e4:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087eb:	83 e1 f0             	and    $0xfffffff0,%ecx
801087ee:	83 c9 09             	or     $0x9,%ecx
801087f1:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801087f7:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087fe:	83 c9 10             	or     $0x10,%ecx
80108801:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108807:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010880e:	83 e1 9f             	and    $0xffffff9f,%ecx
80108811:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108817:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010881e:	83 c9 80             	or     $0xffffff80,%ecx
80108821:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108827:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010882e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108831:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108837:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010883e:	83 e1 ef             	and    $0xffffffef,%ecx
80108841:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108847:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010884e:	83 e1 df             	and    $0xffffffdf,%ecx
80108851:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108857:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010885e:	83 c9 40             	or     $0x40,%ecx
80108861:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108867:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010886e:	83 e1 7f             	and    $0x7f,%ecx
80108871:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108877:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010887d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108883:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010888a:	83 e2 ef             	and    $0xffffffef,%edx
8010888d:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108893:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108899:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
8010889f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801088a5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801088ac:	8b 52 08             	mov    0x8(%edx),%edx
801088af:	81 c2 00 10 00 00    	add    $0x1000,%edx
801088b5:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801088b8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801088bf:	e8 df f7 ff ff       	call   801080a3 <ltr>
  if(p->pgdir == 0)
801088c4:	8b 45 08             	mov    0x8(%ebp),%eax
801088c7:	8b 40 04             	mov    0x4(%eax),%eax
801088ca:	85 c0                	test   %eax,%eax
801088cc:	75 0c                	jne    801088da <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801088ce:	c7 04 24 1b a3 10 80 	movl   $0x8010a31b,(%esp)
801088d5:	e8 60 7c ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801088da:	8b 45 08             	mov    0x8(%ebp),%eax
801088dd:	8b 40 04             	mov    0x4(%eax),%eax
801088e0:	89 04 24             	mov    %eax,(%esp)
801088e3:	e8 f1 f7 ff ff       	call   801080d9 <v2p>
801088e8:	89 04 24             	mov    %eax,(%esp)
801088eb:	e8 de f7 ff ff       	call   801080ce <lcr3>
  popcli();
801088f0:	e8 44 d1 ff ff       	call   80105a39 <popcli>
}
801088f5:	83 c4 14             	add    $0x14,%esp
801088f8:	5b                   	pop    %ebx
801088f9:	5d                   	pop    %ebp
801088fa:	c3                   	ret    

801088fb <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801088fb:	55                   	push   %ebp
801088fc:	89 e5                	mov    %esp,%ebp
801088fe:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108901:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108908:	76 0c                	jbe    80108916 <inituvm+0x1b>
    panic("inituvm: more than a page");
8010890a:	c7 04 24 2f a3 10 80 	movl   $0x8010a32f,(%esp)
80108911:	e8 24 7c ff ff       	call   8010053a <panic>
  mem = kalloc();
80108916:	e8 a4 a9 ff ff       	call   801032bf <kalloc>
8010891b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010891e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108925:	00 
80108926:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010892d:	00 
8010892e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108931:	89 04 24             	mov    %eax,(%esp)
80108934:	e8 bc d1 ff ff       	call   80105af5 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010893c:	89 04 24             	mov    %eax,(%esp)
8010893f:	e8 95 f7 ff ff       	call   801080d9 <v2p>
80108944:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010894b:	00 
8010894c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108950:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108957:	00 
80108958:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010895f:	00 
80108960:	8b 45 08             	mov    0x8(%ebp),%eax
80108963:	89 04 24             	mov    %eax,(%esp)
80108966:	e8 a0 fc ff ff       	call   8010860b <mappages>
  memmove(mem, init, sz);
8010896b:	8b 45 10             	mov    0x10(%ebp),%eax
8010896e:	89 44 24 08          	mov    %eax,0x8(%esp)
80108972:	8b 45 0c             	mov    0xc(%ebp),%eax
80108975:	89 44 24 04          	mov    %eax,0x4(%esp)
80108979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010897c:	89 04 24             	mov    %eax,(%esp)
8010897f:	e8 40 d2 ff ff       	call   80105bc4 <memmove>
}
80108984:	c9                   	leave  
80108985:	c3                   	ret    

80108986 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108986:	55                   	push   %ebp
80108987:	89 e5                	mov    %esp,%ebp
80108989:	53                   	push   %ebx
8010898a:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010898d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108990:	25 ff 0f 00 00       	and    $0xfff,%eax
80108995:	85 c0                	test   %eax,%eax
80108997:	74 0c                	je     801089a5 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108999:	c7 04 24 4c a3 10 80 	movl   $0x8010a34c,(%esp)
801089a0:	e8 95 7b ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801089a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801089ac:	e9 a9 00 00 00       	jmp    80108a5a <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801089b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b4:	8b 55 0c             	mov    0xc(%ebp),%edx
801089b7:	01 d0                	add    %edx,%eax
801089b9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801089c0:	00 
801089c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801089c5:	8b 45 08             	mov    0x8(%ebp),%eax
801089c8:	89 04 24             	mov    %eax,(%esp)
801089cb:	e8 99 fb ff ff       	call   80108569 <walkpgdir>
801089d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
801089d3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089d7:	75 0c                	jne    801089e5 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801089d9:	c7 04 24 6f a3 10 80 	movl   $0x8010a36f,(%esp)
801089e0:	e8 55 7b ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801089e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089e8:	8b 00                	mov    (%eax),%eax
801089ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089ef:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801089f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f5:	8b 55 18             	mov    0x18(%ebp),%edx
801089f8:	29 c2                	sub    %eax,%edx
801089fa:	89 d0                	mov    %edx,%eax
801089fc:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108a01:	77 0f                	ja     80108a12 <loaduvm+0x8c>
      n = sz - i;
80108a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a06:	8b 55 18             	mov    0x18(%ebp),%edx
80108a09:	29 c2                	sub    %eax,%edx
80108a0b:	89 d0                	mov    %edx,%eax
80108a0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108a10:	eb 07                	jmp    80108a19 <loaduvm+0x93>
    else
      n = PGSIZE;
80108a12:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a1c:	8b 55 14             	mov    0x14(%ebp),%edx
80108a1f:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108a22:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108a25:	89 04 24             	mov    %eax,(%esp)
80108a28:	e8 b9 f6 ff ff       	call   801080e6 <p2v>
80108a2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a30:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108a34:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108a38:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a3c:	8b 45 10             	mov    0x10(%ebp),%eax
80108a3f:	89 04 24             	mov    %eax,(%esp)
80108a42:	e8 e6 94 ff ff       	call   80101f2d <readi>
80108a47:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108a4a:	74 07                	je     80108a53 <loaduvm+0xcd>
      return -1;
80108a4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108a51:	eb 18                	jmp    80108a6b <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108a53:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5d:	3b 45 18             	cmp    0x18(%ebp),%eax
80108a60:	0f 82 4b ff ff ff    	jb     801089b1 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108a66:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108a6b:	83 c4 24             	add    $0x24,%esp
80108a6e:	5b                   	pop    %ebx
80108a6f:	5d                   	pop    %ebp
80108a70:	c3                   	ret    

80108a71 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108a71:	55                   	push   %ebp
80108a72:	89 e5                	mov    %esp,%ebp
80108a74:	53                   	push   %ebx
80108a75:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
80108a78:	8b 45 10             	mov    0x10(%ebp),%eax
80108a7b:	85 c0                	test   %eax,%eax
80108a7d:	79 0a                	jns    80108a89 <allocuvm+0x18>
    return 0;
80108a7f:	b8 00 00 00 00       	mov    $0x0,%eax
80108a84:	e9 2d 02 00 00       	jmp    80108cb6 <allocuvm+0x245>
  if(newsz < oldsz)
80108a89:	8b 45 10             	mov    0x10(%ebp),%eax
80108a8c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108a8f:	73 08                	jae    80108a99 <allocuvm+0x28>
    return oldsz;
80108a91:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a94:	e9 1d 02 00 00       	jmp    80108cb6 <allocuvm+0x245>

  a = PGROUNDUP(oldsz);
80108a99:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a9c:	05 ff 0f 00 00       	add    $0xfff,%eax
80108aa1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108aa6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108aa9:	e9 f9 01 00 00       	jmp    80108ca7 <allocuvm+0x236>
    mem = kalloc();
80108aae:	e8 0c a8 ff ff       	call   801032bf <kalloc>
80108ab3:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
80108ab6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108aba:	75 36                	jne    80108af2 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
80108abc:	c7 04 24 8d a3 10 80 	movl   $0x8010a38d,(%esp)
80108ac3:	e8 d8 78 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
80108ac8:	8b 45 14             	mov    0x14(%ebp),%eax
80108acb:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108acf:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ad2:	89 44 24 08          	mov    %eax,0x8(%esp)
80108ad6:	8b 45 10             	mov    0x10(%ebp),%eax
80108ad9:	89 44 24 04          	mov    %eax,0x4(%esp)
80108add:	8b 45 08             	mov    0x8(%ebp),%eax
80108ae0:	89 04 24             	mov    %eax,(%esp)
80108ae3:	e8 d4 01 00 00       	call   80108cbc <deallocuvm>
      return 0;
80108ae8:	b8 00 00 00 00       	mov    $0x0,%eax
80108aed:	e9 c4 01 00 00       	jmp    80108cb6 <allocuvm+0x245>
    }
    memset(mem, 0, PGSIZE);
80108af2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108af9:	00 
80108afa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108b01:	00 
80108b02:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b05:	89 04 24             	mov    %eax,(%esp)
80108b08:	e8 e8 cf ff ff       	call   80105af5 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108b0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b10:	89 04 24             	mov    %eax,(%esp)
80108b13:	e8 c1 f5 ff ff       	call   801080d9 <v2p>
80108b18:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108b1b:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108b22:	00 
80108b23:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108b27:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108b2e:	00 
80108b2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80108b33:	8b 45 08             	mov    0x8(%ebp),%eax
80108b36:	89 04 24             	mov    %eax,(%esp)
80108b39:	e8 cd fa ff ff       	call   8010860b <mappages>
    //find the next open cell in pages array
      i=0;
80108b3e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108b45:	eb 16                	jmp    80108b5d <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108b47:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108b4b:	7e 0c                	jle    80108b59 <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108b4d:	c7 04 24 a8 a3 10 80 	movl   $0x8010a3a8,(%esp)
80108b54:	e8 e1 79 ff ff       	call   8010053a <panic>
        }
        i++;
80108b59:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108b5d:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b60:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b63:	89 d0                	mov    %edx,%eax
80108b65:	c1 e0 02             	shl    $0x2,%eax
80108b68:	01 d0                	add    %edx,%eax
80108b6a:	c1 e0 02             	shl    $0x2,%eax
80108b6d:	01 c8                	add    %ecx,%eax
80108b6f:	05 90 00 00 00       	add    $0x90,%eax
80108b74:	8b 00                	mov    (%eax),%eax
80108b76:	83 f8 ff             	cmp    $0xffffffff,%eax
80108b79:	75 cc                	jne    80108b47 <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
80108b7b:	e8 c5 0f 00 00       	call   80109b45 <isInit>
80108b80:	85 c0                	test   %eax,%eax
80108b82:	75 60                	jne    80108be4 <allocuvm+0x173>
80108b84:	e8 8f 0f 00 00       	call   80109b18 <isShell>
80108b89:	85 c0                	test   %eax,%eax
80108b8b:	75 57                	jne    80108be4 <allocuvm+0x173>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108b8d:	8b 45 14             	mov    0x14(%ebp),%eax
80108b90:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108b96:	83 f8 0e             	cmp    $0xe,%eax
80108b99:	76 32                	jbe    80108bcd <allocuvm+0x15c>
          swapOut();
80108b9b:	e8 03 0c 00 00       	call   801097a3 <swapOut>
          lcr3(v2p(proc->pgdir));
80108ba0:	8b 45 14             	mov    0x14(%ebp),%eax
80108ba3:	8b 40 04             	mov    0x4(%eax),%eax
80108ba6:	89 04 24             	mov    %eax,(%esp)
80108ba9:	e8 2b f5 ff ff       	call   801080d9 <v2p>
80108bae:	89 04 24             	mov    %eax,(%esp)
80108bb1:	e8 18 f5 ff ff       	call   801080ce <lcr3>
          proc->swapedPagesCounter++;
80108bb6:	8b 45 14             	mov    0x14(%ebp),%eax
80108bb9:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108bbf:	8d 50 01             	lea    0x1(%eax),%edx
80108bc2:	8b 45 14             	mov    0x14(%ebp),%eax
80108bc5:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108bcb:	eb 2c                	jmp    80108bf9 <allocuvm+0x188>
          swapOut();
          lcr3(v2p(proc->pgdir));
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108bcd:	8b 45 14             	mov    0x14(%ebp),%eax
80108bd0:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108bd6:	8d 50 01             	lea    0x1(%eax),%edx
80108bd9:	8b 45 14             	mov    0x14(%ebp),%eax
80108bdc:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108be2:	eb 15                	jmp    80108bf9 <allocuvm+0x188>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108be4:	8b 45 14             	mov    0x14(%ebp),%eax
80108be7:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108bed:	8d 50 01             	lea    0x1(%eax),%edx
80108bf0:	8b 45 14             	mov    0x14(%ebp),%eax
80108bf3:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108bf9:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108bfc:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108bff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c02:	89 d0                	mov    %edx,%eax
80108c04:	c1 e0 02             	shl    $0x2,%eax
80108c07:	01 d0                	add    %edx,%eax
80108c09:	c1 e0 02             	shl    $0x2,%eax
80108c0c:	01 d8                	add    %ebx,%eax
80108c0e:	05 90 00 00 00       	add    $0x90,%eax
80108c13:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108c15:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c18:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c1b:	89 d0                	mov    %edx,%eax
80108c1d:	c1 e0 02             	shl    $0x2,%eax
80108c20:	01 d0                	add    %edx,%eax
80108c22:	c1 e0 02             	shl    $0x2,%eax
80108c25:	01 c8                	add    %ecx,%eax
80108c27:	05 94 00 00 00       	add    $0x94,%eax
80108c2c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108c32:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c35:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c38:	89 d0                	mov    %edx,%eax
80108c3a:	c1 e0 02             	shl    $0x2,%eax
80108c3d:	01 d0                	add    %edx,%eax
80108c3f:	c1 e0 02             	shl    $0x2,%eax
80108c42:	01 c8                	add    %ecx,%eax
80108c44:	05 98 00 00 00       	add    $0x98,%eax
80108c49:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108c4f:	8b 45 14             	mov    0x14(%ebp),%eax
80108c52:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108c58:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108c5b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c5e:	89 d0                	mov    %edx,%eax
80108c60:	c1 e0 02             	shl    $0x2,%eax
80108c63:	01 d0                	add    %edx,%eax
80108c65:	c1 e0 02             	shl    $0x2,%eax
80108c68:	01 d8                	add    %ebx,%eax
80108c6a:	05 9c 00 00 00       	add    $0x9c,%eax
80108c6f:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108c71:	8b 45 14             	mov    0x14(%ebp),%eax
80108c74:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108c7a:	8d 50 01             	lea    0x1(%eax),%edx
80108c7d:	8b 45 14             	mov    0x14(%ebp),%eax
80108c80:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108c86:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c89:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c8c:	89 d0                	mov    %edx,%eax
80108c8e:	c1 e0 02             	shl    $0x2,%eax
80108c91:	01 d0                	add    %edx,%eax
80108c93:	c1 e0 02             	shl    $0x2,%eax
80108c96:	01 c8                	add    %ecx,%eax
80108c98:	05 a0 00 00 00       	add    $0xa0,%eax
80108c9d:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108ca0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108caa:	3b 45 10             	cmp    0x10(%ebp),%eax
80108cad:	0f 82 fb fd ff ff    	jb     80108aae <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108cb3:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108cb6:	83 c4 34             	add    $0x34,%esp
80108cb9:	5b                   	pop    %ebx
80108cba:	5d                   	pop    %ebp
80108cbb:	c3                   	ret    

80108cbc <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108cbc:	55                   	push   %ebp
80108cbd:	89 e5                	mov    %esp,%ebp
80108cbf:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108cc2:	8b 45 10             	mov    0x10(%ebp),%eax
80108cc5:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108cc8:	72 08                	jb     80108cd2 <deallocuvm+0x16>
    return oldsz;
80108cca:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ccd:	e9 ec 01 00 00       	jmp    80108ebe <deallocuvm+0x202>

  a = PGROUNDUP(newsz);
80108cd2:	8b 45 10             	mov    0x10(%ebp),%eax
80108cd5:	05 ff 0f 00 00       	add    $0xfff,%eax
80108cda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108ce2:	e9 c8 01 00 00       	jmp    80108eaf <deallocuvm+0x1f3>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108ce7:	8b 45 14             	mov    0x14(%ebp),%eax
80108cea:	8b 40 04             	mov    0x4(%eax),%eax
80108ced:	3b 45 08             	cmp    0x8(%ebp),%eax
80108cf0:	0f 85 07 01 00 00    	jne    80108dfd <deallocuvm+0x141>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108cf6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108cfd:	e9 f1 00 00 00       	jmp    80108df3 <deallocuvm+0x137>
          if(proc->pagesMetaData[i].va == (char *)a){
80108d02:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108d05:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d08:	89 d0                	mov    %edx,%eax
80108d0a:	c1 e0 02             	shl    $0x2,%eax
80108d0d:	01 d0                	add    %edx,%eax
80108d0f:	c1 e0 02             	shl    $0x2,%eax
80108d12:	01 c8                	add    %ecx,%eax
80108d14:	05 90 00 00 00       	add    $0x90,%eax
80108d19:	8b 10                	mov    (%eax),%edx
80108d1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d1e:	39 c2                	cmp    %eax,%edx
80108d20:	0f 85 c9 00 00 00    	jne    80108def <deallocuvm+0x133>
            if((!isShell()) && (!isInit())){
80108d26:	e8 ed 0d 00 00       	call   80109b18 <isShell>
80108d2b:	85 c0                	test   %eax,%eax
80108d2d:	75 54                	jne    80108d83 <deallocuvm+0xc7>
80108d2f:	e8 11 0e 00 00       	call   80109b45 <isInit>
80108d34:	85 c0                	test   %eax,%eax
80108d36:	75 4b                	jne    80108d83 <deallocuvm+0xc7>
              if(proc->pagesMetaData[i].isPhysical){
80108d38:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108d3b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d3e:	89 d0                	mov    %edx,%eax
80108d40:	c1 e0 02             	shl    $0x2,%eax
80108d43:	01 d0                	add    %edx,%eax
80108d45:	c1 e0 02             	shl    $0x2,%eax
80108d48:	01 c8                	add    %ecx,%eax
80108d4a:	05 94 00 00 00       	add    $0x94,%eax
80108d4f:	8b 00                	mov    (%eax),%eax
80108d51:	85 c0                	test   %eax,%eax
80108d53:	74 17                	je     80108d6c <deallocuvm+0xb0>
                proc->memoryPagesCounter--;
80108d55:	8b 45 14             	mov    0x14(%ebp),%eax
80108d58:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108d5e:	8d 50 ff             	lea    -0x1(%eax),%edx
80108d61:	8b 45 14             	mov    0x14(%ebp),%eax
80108d64:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108d6a:	eb 2c                	jmp    80108d98 <deallocuvm+0xdc>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108d6c:	8b 45 14             	mov    0x14(%ebp),%eax
80108d6f:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108d75:	8d 50 ff             	lea    -0x1(%eax),%edx
80108d78:	8b 45 14             	mov    0x14(%ebp),%eax
80108d7b:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108d81:	eb 15                	jmp    80108d98 <deallocuvm+0xdc>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108d83:	8b 45 14             	mov    0x14(%ebp),%eax
80108d86:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108d8c:	8d 50 ff             	lea    -0x1(%eax),%edx
80108d8f:	8b 45 14             	mov    0x14(%ebp),%eax
80108d92:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108d98:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108d9b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d9e:	89 d0                	mov    %edx,%eax
80108da0:	c1 e0 02             	shl    $0x2,%eax
80108da3:	01 d0                	add    %edx,%eax
80108da5:	c1 e0 02             	shl    $0x2,%eax
80108da8:	01 c8                	add    %ecx,%eax
80108daa:	05 90 00 00 00       	add    $0x90,%eax
80108daf:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108db5:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108db8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108dbb:	89 d0                	mov    %edx,%eax
80108dbd:	c1 e0 02             	shl    $0x2,%eax
80108dc0:	01 d0                	add    %edx,%eax
80108dc2:	c1 e0 02             	shl    $0x2,%eax
80108dc5:	01 c8                	add    %ecx,%eax
80108dc7:	05 94 00 00 00       	add    $0x94,%eax
80108dcc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108dd2:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108dd5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108dd8:	89 d0                	mov    %edx,%eax
80108dda:	c1 e0 02             	shl    $0x2,%eax
80108ddd:	01 d0                	add    %edx,%eax
80108ddf:	c1 e0 02             	shl    $0x2,%eax
80108de2:	01 c8                	add    %ecx,%eax
80108de4:	05 98 00 00 00       	add    $0x98,%eax
80108de9:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108def:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108df3:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108df7:	0f 8e 05 ff ff ff    	jle    80108d02 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e00:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e07:	00 
80108e08:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80108e0f:	89 04 24             	mov    %eax,(%esp)
80108e12:	e8 52 f7 ff ff       	call   80108569 <walkpgdir>
80108e17:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108e1a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108e1e:	75 09                	jne    80108e29 <deallocuvm+0x16d>
      a += (NPTENTRIES - 1) * PGSIZE;
80108e20:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108e27:	eb 7f                	jmp    80108ea8 <deallocuvm+0x1ec>
    else if((*pte & PTE_P) != 0){
80108e29:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e2c:	8b 00                	mov    (%eax),%eax
80108e2e:	83 e0 01             	and    $0x1,%eax
80108e31:	85 c0                	test   %eax,%eax
80108e33:	74 5c                	je     80108e91 <deallocuvm+0x1d5>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108e35:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e38:	8b 00                	mov    (%eax),%eax
80108e3a:	25 00 02 00 00       	and    $0x200,%eax
80108e3f:	85 c0                	test   %eax,%eax
80108e41:	75 43                	jne    80108e86 <deallocuvm+0x1ca>
        pa = PTE_ADDR(*pte);
80108e43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e46:	8b 00                	mov    (%eax),%eax
80108e48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e4d:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108e50:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108e54:	75 0c                	jne    80108e62 <deallocuvm+0x1a6>
          panic("kfree");
80108e56:	c7 04 24 d2 a3 10 80 	movl   $0x8010a3d2,(%esp)
80108e5d:	e8 d8 76 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108e62:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108e65:	89 04 24             	mov    %eax,(%esp)
80108e68:	e8 79 f2 ff ff       	call   801080e6 <p2v>
80108e6d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108e70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108e73:	89 04 24             	mov    %eax,(%esp)
80108e76:	e8 82 a3 ff ff       	call   801031fd <kfree>
        *pte = 0;
80108e7b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e7e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108e84:	eb 22                	jmp    80108ea8 <deallocuvm+0x1ec>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108e86:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e89:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108e8f:	eb 17                	jmp    80108ea8 <deallocuvm+0x1ec>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108e91:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e94:	8b 00                	mov    (%eax),%eax
80108e96:	25 00 02 00 00       	and    $0x200,%eax
80108e9b:	85 c0                	test   %eax,%eax
80108e9d:	74 09                	je     80108ea8 <deallocuvm+0x1ec>
        *pte = 0;
80108e9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ea2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108ea8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eb2:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108eb5:	0f 82 2c fe ff ff    	jb     80108ce7 <deallocuvm+0x2b>
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
    }
  }
  return newsz;
80108ebb:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108ebe:	c9                   	leave  
80108ebf:	c3                   	ret    

80108ec0 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108ec0:	55                   	push   %ebp
80108ec1:	89 e5                	mov    %esp,%ebp
80108ec3:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108ec6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108eca:	75 0c                	jne    80108ed8 <freevm+0x18>
    panic("freevm: no pgdir");
80108ecc:	c7 04 24 d8 a3 10 80 	movl   $0x8010a3d8,(%esp)
80108ed3:	e8 62 76 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108ed8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108ede:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108ee2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ee9:	00 
80108eea:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108ef1:	80 
80108ef2:	8b 45 08             	mov    0x8(%ebp),%eax
80108ef5:	89 04 24             	mov    %eax,(%esp)
80108ef8:	e8 bf fd ff ff       	call   80108cbc <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108efd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f04:	eb 48                	jmp    80108f4e <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f09:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108f10:	8b 45 08             	mov    0x8(%ebp),%eax
80108f13:	01 d0                	add    %edx,%eax
80108f15:	8b 00                	mov    (%eax),%eax
80108f17:	83 e0 01             	and    $0x1,%eax
80108f1a:	85 c0                	test   %eax,%eax
80108f1c:	74 2c                	je     80108f4a <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108f1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f21:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108f28:	8b 45 08             	mov    0x8(%ebp),%eax
80108f2b:	01 d0                	add    %edx,%eax
80108f2d:	8b 00                	mov    (%eax),%eax
80108f2f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f34:	89 04 24             	mov    %eax,(%esp)
80108f37:	e8 aa f1 ff ff       	call   801080e6 <p2v>
80108f3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108f3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f42:	89 04 24             	mov    %eax,(%esp)
80108f45:	e8 b3 a2 ff ff       	call   801031fd <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108f4a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108f4e:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108f55:	76 af                	jbe    80108f06 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108f57:	8b 45 08             	mov    0x8(%ebp),%eax
80108f5a:	89 04 24             	mov    %eax,(%esp)
80108f5d:	e8 9b a2 ff ff       	call   801031fd <kfree>

}
80108f62:	c9                   	leave  
80108f63:	c3                   	ret    

80108f64 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108f64:	55                   	push   %ebp
80108f65:	89 e5                	mov    %esp,%ebp
80108f67:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108f6a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f71:	00 
80108f72:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f75:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f79:	8b 45 08             	mov    0x8(%ebp),%eax
80108f7c:	89 04 24             	mov    %eax,(%esp)
80108f7f:	e8 e5 f5 ff ff       	call   80108569 <walkpgdir>
80108f84:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108f87:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108f8b:	75 0c                	jne    80108f99 <clearpteu+0x35>
    panic("clearpteu");
80108f8d:	c7 04 24 e9 a3 10 80 	movl   $0x8010a3e9,(%esp)
80108f94:	e8 a1 75 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f9c:	8b 00                	mov    (%eax),%eax
80108f9e:	83 e0 fb             	and    $0xfffffffb,%eax
80108fa1:	89 c2                	mov    %eax,%edx
80108fa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fa6:	89 10                	mov    %edx,(%eax)
}
80108fa8:	c9                   	leave  
80108fa9:	c3                   	ret    

80108faa <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108faa:	55                   	push   %ebp
80108fab:	89 e5                	mov    %esp,%ebp
80108fad:	53                   	push   %ebx
80108fae:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108fb1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108fb8:	8b 45 10             	mov    0x10(%ebp),%eax
80108fbb:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108fc2:	00 00 00 
  np->swapedPagesCounter = 0;
80108fc5:	8b 45 10             	mov    0x10(%ebp),%eax
80108fc8:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108fcf:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108fd2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108fd8:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108fde:	8b 45 10             	mov    0x10(%ebp),%eax
80108fe1:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108fe7:	e8 b7 f6 ff ff       	call   801086a3 <setupkvm>
80108fec:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108fef:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ff3:	75 0a                	jne    80108fff <copyuvm+0x55>
    return 0;
80108ff5:	b8 00 00 00 00       	mov    $0x0,%eax
80108ffa:	e9 da 02 00 00       	jmp    801092d9 <copyuvm+0x32f>
  for(i = 0; i < sz; i += PGSIZE){
80108fff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109006:	e9 04 02 00 00       	jmp    8010920f <copyuvm+0x265>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010900b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010900e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109015:	00 
80109016:	89 44 24 04          	mov    %eax,0x4(%esp)
8010901a:	8b 45 08             	mov    0x8(%ebp),%eax
8010901d:	89 04 24             	mov    %eax,(%esp)
80109020:	e8 44 f5 ff ff       	call   80108569 <walkpgdir>
80109025:	89 45 e8             	mov    %eax,-0x18(%ebp)
80109028:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010902c:	75 0c                	jne    8010903a <copyuvm+0x90>
      panic("copyuvm: pte should exist");
8010902e:	c7 04 24 f3 a3 10 80 	movl   $0x8010a3f3,(%esp)
80109035:	e8 00 75 ff ff       	call   8010053a <panic>
    if(*pte & PTE_P){// page on RAM, copy it to the new process ram
8010903a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010903d:	8b 00                	mov    (%eax),%eax
8010903f:	83 e0 01             	and    $0x1,%eax
80109042:	85 c0                	test   %eax,%eax
80109044:	0f 84 a7 00 00 00    	je     801090f1 <copyuvm+0x147>
      // panic("copyuvm: page not present");
      pa = PTE_ADDR(*pte);
8010904a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010904d:	8b 00                	mov    (%eax),%eax
8010904f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109054:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      flags = PTE_FLAGS(*pte);
80109057:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010905a:	8b 00                	mov    (%eax),%eax
8010905c:	25 ff 0f 00 00       	and    $0xfff,%eax
80109061:	89 45 e0             	mov    %eax,-0x20(%ebp)
      if((mem = kalloc()) == 0)
80109064:	e8 56 a2 ff ff       	call   801032bf <kalloc>
80109069:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010906c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80109070:	75 05                	jne    80109077 <copyuvm+0xcd>
        goto bad;
80109072:	e9 4a 02 00 00       	jmp    801092c1 <copyuvm+0x317>
      memmove(mem, (char*)p2v(pa), PGSIZE);
80109077:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010907a:	89 04 24             	mov    %eax,(%esp)
8010907d:	e8 64 f0 ff ff       	call   801080e6 <p2v>
80109082:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109089:	00 
8010908a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010908e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80109091:	89 04 24             	mov    %eax,(%esp)
80109094:	e8 2b cb ff ff       	call   80105bc4 <memmove>
      if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80109099:	8b 5d e0             	mov    -0x20(%ebp),%ebx
8010909c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010909f:	89 04 24             	mov    %eax,(%esp)
801090a2:	e8 32 f0 ff ff       	call   801080d9 <v2p>
801090a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801090aa:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801090ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
801090b2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090b9:	00 
801090ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801090be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801090c1:	89 04 24             	mov    %eax,(%esp)
801090c4:	e8 42 f5 ff ff       	call   8010860b <mappages>
801090c9:	85 c0                	test   %eax,%eax
801090cb:	79 05                	jns    801090d2 <copyuvm+0x128>
        goto bad;
801090cd:	e9 ef 01 00 00       	jmp    801092c1 <copyuvm+0x317>
      np->pagesMetaData[j].isPhysical = 1;
801090d2:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090d5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090d8:	89 d0                	mov    %edx,%eax
801090da:	c1 e0 02             	shl    $0x2,%eax
801090dd:	01 d0                	add    %edx,%eax
801090df:	c1 e0 02             	shl    $0x2,%eax
801090e2:	01 c8                	add    %ecx,%eax
801090e4:	05 94 00 00 00       	add    $0x94,%eax
801090e9:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
801090ef:	eb 58                	jmp    80109149 <copyuvm+0x19f>
    }
    else{//page is in swap file, need to create pte for it
      pte = walkpgdir(d,(void*)i,1);
801090f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090f4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801090fb:	00 
801090fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80109100:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109103:	89 04 24             	mov    %eax,(%esp)
80109106:	e8 5e f4 ff ff       	call   80108569 <walkpgdir>
8010910b:	89 45 e8             	mov    %eax,-0x18(%ebp)
      *pte &= ~PTE_P;
8010910e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109111:	8b 00                	mov    (%eax),%eax
80109113:	83 e0 fe             	and    $0xfffffffe,%eax
80109116:	89 c2                	mov    %eax,%edx
80109118:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010911b:	89 10                	mov    %edx,(%eax)
      *pte |= PTE_PG;
8010911d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109120:	8b 00                	mov    (%eax),%eax
80109122:	80 cc 02             	or     $0x2,%ah
80109125:	89 c2                	mov    %eax,%edx
80109127:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010912a:	89 10                	mov    %edx,(%eax)
      np->pagesMetaData[j].isPhysical = 0;
8010912c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010912f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109132:	89 d0                	mov    %edx,%eax
80109134:	c1 e0 02             	shl    $0x2,%eax
80109137:	01 d0                	add    %edx,%eax
80109139:	c1 e0 02             	shl    $0x2,%eax
8010913c:	01 c8                	add    %ecx,%eax
8010913e:	05 94 00 00 00       	add    $0x94,%eax
80109143:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    }
    np->pagesMetaData[j].va = (char *) i;
80109149:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010914c:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010914f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109152:	89 d0                	mov    %edx,%eax
80109154:	c1 e0 02             	shl    $0x2,%eax
80109157:	01 d0                	add    %edx,%eax
80109159:	c1 e0 02             	shl    $0x2,%eax
8010915c:	01 d8                	add    %ebx,%eax
8010915e:	05 90 00 00 00       	add    $0x90,%eax
80109163:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109165:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109168:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010916b:	89 d0                	mov    %edx,%eax
8010916d:	c1 e0 02             	shl    $0x2,%eax
80109170:	01 d0                	add    %edx,%eax
80109172:	c1 e0 02             	shl    $0x2,%eax
80109175:	01 c8                	add    %ecx,%eax
80109177:	05 98 00 00 00       	add    $0x98,%eax
8010917c:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
80109182:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109189:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010918c:	89 d0                	mov    %edx,%eax
8010918e:	c1 e0 02             	shl    $0x2,%eax
80109191:	01 d0                	add    %edx,%eax
80109193:	c1 e0 02             	shl    $0x2,%eax
80109196:	01 c8                	add    %ecx,%eax
80109198:	05 9c 00 00 00       	add    $0x9c,%eax
8010919d:	8b 08                	mov    (%eax),%ecx
8010919f:	8b 5d 10             	mov    0x10(%ebp),%ebx
801091a2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091a5:	89 d0                	mov    %edx,%eax
801091a7:	c1 e0 02             	shl    $0x2,%eax
801091aa:	01 d0                	add    %edx,%eax
801091ac:	c1 e0 02             	shl    $0x2,%eax
801091af:	01 d8                	add    %ebx,%eax
801091b1:	05 9c 00 00 00       	add    $0x9c,%eax
801091b6:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
801091b8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801091bf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091c2:	89 d0                	mov    %edx,%eax
801091c4:	c1 e0 02             	shl    $0x2,%eax
801091c7:	01 d0                	add    %edx,%eax
801091c9:	c1 e0 02             	shl    $0x2,%eax
801091cc:	01 c8                	add    %ecx,%eax
801091ce:	05 a0 00 00 00       	add    $0xa0,%eax
801091d3:	0f b6 08             	movzbl (%eax),%ecx
801091d6:	8b 5d 10             	mov    0x10(%ebp),%ebx
801091d9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091dc:	89 d0                	mov    %edx,%eax
801091de:	c1 e0 02             	shl    $0x2,%eax
801091e1:	01 d0                	add    %edx,%eax
801091e3:	c1 e0 02             	shl    $0x2,%eax
801091e6:	01 d8                	add    %ebx,%eax
801091e8:	05 a0 00 00 00       	add    $0xa0,%eax
801091ed:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
801091ef:	8b 45 10             	mov    0x10(%ebp),%eax
801091f2:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801091f8:	8d 50 01             	lea    0x1(%eax),%edx
801091fb:	8b 45 10             	mov    0x10(%ebp),%eax
801091fe:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
80109204:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109208:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010920f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109212:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109215:	0f 82 f0 fd ff ff    	jb     8010900b <copyuvm+0x61>
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
8010921b:	e9 92 00 00 00       	jmp    801092b2 <copyuvm+0x308>
    np->pagesMetaData[j].va = (char *) -1;
80109220:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109223:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109226:	89 d0                	mov    %edx,%eax
80109228:	c1 e0 02             	shl    $0x2,%eax
8010922b:	01 d0                	add    %edx,%eax
8010922d:	c1 e0 02             	shl    $0x2,%eax
80109230:	01 c8                	add    %ecx,%eax
80109232:	05 90 00 00 00       	add    $0x90,%eax
80109237:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
8010923d:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109240:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109243:	89 d0                	mov    %edx,%eax
80109245:	c1 e0 02             	shl    $0x2,%eax
80109248:	01 d0                	add    %edx,%eax
8010924a:	c1 e0 02             	shl    $0x2,%eax
8010924d:	01 c8                	add    %ecx,%eax
8010924f:	05 94 00 00 00       	add    $0x94,%eax
80109254:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
8010925a:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010925d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109260:	89 d0                	mov    %edx,%eax
80109262:	c1 e0 02             	shl    $0x2,%eax
80109265:	01 d0                	add    %edx,%eax
80109267:	c1 e0 02             	shl    $0x2,%eax
8010926a:	01 c8                	add    %ecx,%eax
8010926c:	05 98 00 00 00       	add    $0x98,%eax
80109271:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109277:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010927a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010927d:	89 d0                	mov    %edx,%eax
8010927f:	c1 e0 02             	shl    $0x2,%eax
80109282:	01 d0                	add    %edx,%eax
80109284:	c1 e0 02             	shl    $0x2,%eax
80109287:	01 c8                	add    %ecx,%eax
80109289:	05 9c 00 00 00       	add    $0x9c,%eax
8010928e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
80109294:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109297:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010929a:	89 d0                	mov    %edx,%eax
8010929c:	c1 e0 02             	shl    $0x2,%eax
8010929f:	01 d0                	add    %edx,%eax
801092a1:	c1 e0 02             	shl    $0x2,%eax
801092a4:	01 c8                	add    %ecx,%eax
801092a6:	05 a0 00 00 00       	add    $0xa0,%eax
801092ab:	c6 00 80             	movb   $0x80,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
    np->memoryPagesCounter++;
    j++;
  }
  for(; j < 30; j++){
801092ae:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801092b2:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801092b6:	0f 86 64 ff ff ff    	jbe    80109220 <copyuvm+0x276>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
801092bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092bf:	eb 18                	jmp    801092d9 <copyuvm+0x32f>

  bad:
  freevm(d,0);
801092c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801092c8:	00 
801092c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092cc:	89 04 24             	mov    %eax,(%esp)
801092cf:	e8 ec fb ff ff       	call   80108ec0 <freevm>
  return 0;
801092d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092d9:	83 c4 44             	add    $0x44,%esp
801092dc:	5b                   	pop    %ebx
801092dd:	5d                   	pop    %ebp
801092de:	c3                   	ret    

801092df <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801092df:	55                   	push   %ebp
801092e0:	89 e5                	mov    %esp,%ebp
801092e2:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801092e5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092ec:	00 
801092ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801092f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801092f4:	8b 45 08             	mov    0x8(%ebp),%eax
801092f7:	89 04 24             	mov    %eax,(%esp)
801092fa:	e8 6a f2 ff ff       	call   80108569 <walkpgdir>
801092ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109305:	8b 00                	mov    (%eax),%eax
80109307:	83 e0 01             	and    $0x1,%eax
8010930a:	85 c0                	test   %eax,%eax
8010930c:	75 07                	jne    80109315 <uva2ka+0x36>
    return 0;
8010930e:	b8 00 00 00 00       	mov    $0x0,%eax
80109313:	eb 25                	jmp    8010933a <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109318:	8b 00                	mov    (%eax),%eax
8010931a:	83 e0 04             	and    $0x4,%eax
8010931d:	85 c0                	test   %eax,%eax
8010931f:	75 07                	jne    80109328 <uva2ka+0x49>
    return 0;
80109321:	b8 00 00 00 00       	mov    $0x0,%eax
80109326:	eb 12                	jmp    8010933a <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109328:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010932b:	8b 00                	mov    (%eax),%eax
8010932d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109332:	89 04 24             	mov    %eax,(%esp)
80109335:	e8 ac ed ff ff       	call   801080e6 <p2v>
}
8010933a:	c9                   	leave  
8010933b:	c3                   	ret    

8010933c <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010933c:	55                   	push   %ebp
8010933d:	89 e5                	mov    %esp,%ebp
8010933f:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109342:	8b 45 10             	mov    0x10(%ebp),%eax
80109345:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109348:	e9 87 00 00 00       	jmp    801093d4 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010934d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109350:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109355:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109358:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010935b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010935f:	8b 45 08             	mov    0x8(%ebp),%eax
80109362:	89 04 24             	mov    %eax,(%esp)
80109365:	e8 75 ff ff ff       	call   801092df <uva2ka>
8010936a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010936d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109371:	75 07                	jne    8010937a <copyout+0x3e>
      return -1;
80109373:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109378:	eb 69                	jmp    801093e3 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010937a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010937d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109380:	29 c2                	sub    %eax,%edx
80109382:	89 d0                	mov    %edx,%eax
80109384:	05 00 10 00 00       	add    $0x1000,%eax
80109389:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010938c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010938f:	3b 45 14             	cmp    0x14(%ebp),%eax
80109392:	76 06                	jbe    8010939a <copyout+0x5e>
      n = len;
80109394:	8b 45 14             	mov    0x14(%ebp),%eax
80109397:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010939a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010939d:	8b 55 0c             	mov    0xc(%ebp),%edx
801093a0:	29 c2                	sub    %eax,%edx
801093a2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801093a5:	01 c2                	add    %eax,%edx
801093a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093aa:	89 44 24 08          	mov    %eax,0x8(%esp)
801093ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801093b5:	89 14 24             	mov    %edx,(%esp)
801093b8:	e8 07 c8 ff ff       	call   80105bc4 <memmove>
    len -= n;
801093bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093c0:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801093c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093c6:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801093c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093cc:	05 00 10 00 00       	add    $0x1000,%eax
801093d1:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801093d4:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801093d8:	0f 85 6f ff ff ff    	jne    8010934d <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801093de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801093e3:	c9                   	leave  
801093e4:	c3                   	ret    

801093e5 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
801093e5:	55                   	push   %ebp
801093e6:	89 e5                	mov    %esp,%ebp
801093e8:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801093eb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801093f2:	eb 52                	jmp    80109446 <findNextOpenPage+0x61>
    found = 1;
801093f4:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801093fb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80109402:	eb 2d                	jmp    80109431 <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
80109404:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010940b:	8b 55 f8             	mov    -0x8(%ebp),%edx
8010940e:	89 d0                	mov    %edx,%eax
80109410:	c1 e0 02             	shl    $0x2,%eax
80109413:	01 d0                	add    %edx,%eax
80109415:	c1 e0 02             	shl    $0x2,%eax
80109418:	01 c8                	add    %ecx,%eax
8010941a:	05 98 00 00 00       	add    $0x98,%eax
8010941f:	8b 00                	mov    (%eax),%eax
80109421:	3b 45 fc             	cmp    -0x4(%ebp),%eax
80109424:	75 07                	jne    8010942d <findNextOpenPage+0x48>
        found = 0;
80109426:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
8010942d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80109431:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
80109435:	7e cd                	jle    80109404 <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
80109437:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010943b:	74 02                	je     8010943f <findNextOpenPage+0x5a>
      break;
8010943d:	eb 10                	jmp    8010944f <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
8010943f:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
80109446:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
8010944d:	7e a5                	jle    801093f4 <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
8010944f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80109452:	c9                   	leave  
80109453:	c3                   	ret    

80109454 <existOnDisc>:

int
existOnDisc(uint faultingPage){
80109454:	55                   	push   %ebp
80109455:	89 e5                	mov    %esp,%ebp
80109457:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
8010945a:	8b 55 08             	mov    0x8(%ebp),%edx
8010945d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109463:	8b 40 04             	mov    0x4(%eax),%eax
80109466:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010946d:	00 
8010946e:	89 54 24 04          	mov    %edx,0x4(%esp)
80109472:	89 04 24             	mov    %eax,(%esp)
80109475:	e8 ef f0 ff ff       	call   80108569 <walkpgdir>
8010947a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
8010947d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  cprintf("faulting page: %x\n",faultingPage);
80109484:	8b 45 08             	mov    0x8(%ebp),%eax
80109487:	89 44 24 04          	mov    %eax,0x4(%esp)
8010948b:	c7 04 24 0d a4 10 80 	movl   $0x8010a40d,(%esp)
80109492:	e8 09 6f ff ff       	call   801003a0 <cprintf>
  for(i = 0; i < 30; i++){
80109497:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010949e:	e9 8e 00 00 00       	jmp    80109531 <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
801094a3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094aa:	8b 55 f0             	mov    -0x10(%ebp),%edx
801094ad:	89 d0                	mov    %edx,%eax
801094af:	c1 e0 02             	shl    $0x2,%eax
801094b2:	01 d0                	add    %edx,%eax
801094b4:	c1 e0 02             	shl    $0x2,%eax
801094b7:	01 c8                	add    %ecx,%eax
801094b9:	05 90 00 00 00       	add    $0x90,%eax
801094be:	8b 00                	mov    (%eax),%eax
801094c0:	83 f8 ff             	cmp    $0xffffffff,%eax
801094c3:	74 68                	je     8010952d <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
801094c5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801094cf:	89 d0                	mov    %edx,%eax
801094d1:	c1 e0 02             	shl    $0x2,%eax
801094d4:	01 d0                	add    %edx,%eax
801094d6:	c1 e0 02             	shl    $0x2,%eax
801094d9:	01 c8                	add    %ecx,%eax
801094db:	05 90 00 00 00       	add    $0x90,%eax
801094e0:	8b 00                	mov    (%eax),%eax
801094e2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094e7:	3b 45 08             	cmp    0x8(%ebp),%eax
801094ea:	77 41                	ja     8010952d <existOnDisc+0xd9>
801094ec:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801094f6:	89 d0                	mov    %edx,%eax
801094f8:	c1 e0 02             	shl    $0x2,%eax
801094fb:	01 d0                	add    %edx,%eax
801094fd:	c1 e0 02             	shl    $0x2,%eax
80109500:	01 c8                	add    %ecx,%eax
80109502:	05 90 00 00 00       	add    $0x90,%eax
80109507:	8b 00                	mov    (%eax),%eax
80109509:	05 ff 0f 00 00       	add    $0xfff,%eax
8010950e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109513:	3b 45 08             	cmp    0x8(%ebp),%eax
80109516:	72 15                	jb     8010952d <existOnDisc+0xd9>
80109518:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010951b:	8b 00                	mov    (%eax),%eax
8010951d:	25 00 02 00 00       	and    $0x200,%eax
80109522:	85 c0                	test   %eax,%eax
80109524:	74 07                	je     8010952d <existOnDisc+0xd9>
        found = 1;
80109526:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  cprintf("faulting page: %x\n",faultingPage);
  for(i = 0; i < 30; i++){
8010952d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109531:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109535:	0f 8e 68 ff ff ff    	jle    801094a3 <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
8010953b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010953e:	c9                   	leave  
8010953f:	c3                   	ret    

80109540 <fixPage>:

void
fixPage(uint faultingPage){
80109540:	55                   	push   %ebp
80109541:	89 e5                	mov    %esp,%ebp
80109543:	83 ec 38             	sub    $0x38,%esp
  int i;
  //char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
80109546:	e8 74 9d ff ff       	call   801032bf <kalloc>
8010954b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
8010954e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109552:	75 0c                	jne    80109560 <fixPage+0x20>
    panic("no room, go away");
80109554:	c7 04 24 20 a4 10 80 	movl   $0x8010a420,(%esp)
8010955b:	e8 da 6f ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
80109560:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109567:	00 
80109568:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010956f:	00 
80109570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109573:	89 04 24             	mov    %eax,(%esp)
80109576:	e8 7a c5 ff ff       	call   80105af5 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
8010957b:	8b 55 08             	mov    0x8(%ebp),%edx
8010957e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109584:	8b 40 04             	mov    0x4(%eax),%eax
80109587:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010958e:	00 
8010958f:	89 54 24 04          	mov    %edx,0x4(%esp)
80109593:	89 04 24             	mov    %eax,(%esp)
80109596:	e8 ce ef ff ff       	call   80108569 <walkpgdir>
8010959b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010959e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801095a5:	e9 a6 01 00 00       	jmp    80109750 <fixPage+0x210>
    if(proc->pagesMetaData[i].va != (char *) -1){
801095aa:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095b4:	89 d0                	mov    %edx,%eax
801095b6:	c1 e0 02             	shl    $0x2,%eax
801095b9:	01 d0                	add    %edx,%eax
801095bb:	c1 e0 02             	shl    $0x2,%eax
801095be:	01 c8                	add    %ecx,%eax
801095c0:	05 90 00 00 00       	add    $0x90,%eax
801095c5:	8b 00                	mov    (%eax),%eax
801095c7:	83 f8 ff             	cmp    $0xffffffff,%eax
801095ca:	0f 84 7c 01 00 00    	je     8010974c <fixPage+0x20c>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
801095d0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095da:	89 d0                	mov    %edx,%eax
801095dc:	c1 e0 02             	shl    $0x2,%eax
801095df:	01 d0                	add    %edx,%eax
801095e1:	c1 e0 02             	shl    $0x2,%eax
801095e4:	01 c8                	add    %ecx,%eax
801095e6:	05 90 00 00 00       	add    $0x90,%eax
801095eb:	8b 00                	mov    (%eax),%eax
801095ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801095f2:	3b 45 08             	cmp    0x8(%ebp),%eax
801095f5:	0f 87 51 01 00 00    	ja     8010974c <fixPage+0x20c>
801095fb:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109602:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109605:	89 d0                	mov    %edx,%eax
80109607:	c1 e0 02             	shl    $0x2,%eax
8010960a:	01 d0                	add    %edx,%eax
8010960c:	c1 e0 02             	shl    $0x2,%eax
8010960f:	01 c8                	add    %ecx,%eax
80109611:	05 90 00 00 00       	add    $0x90,%eax
80109616:	8b 00                	mov    (%eax),%eax
80109618:	05 ff 0f 00 00       	add    $0xfff,%eax
8010961d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109622:	3b 45 08             	cmp    0x8(%ebp),%eax
80109625:	0f 82 21 01 00 00    	jb     8010974c <fixPage+0x20c>
8010962b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010962e:	8b 00                	mov    (%eax),%eax
80109630:	25 00 02 00 00       	and    $0x200,%eax
80109635:	85 c0                	test   %eax,%eax
80109637:	0f 84 0f 01 00 00    	je     8010974c <fixPage+0x20c>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
8010963d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109644:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109647:	89 d0                	mov    %edx,%eax
80109649:	c1 e0 02             	shl    $0x2,%eax
8010964c:	01 d0                	add    %edx,%eax
8010964e:	c1 e0 02             	shl    $0x2,%eax
80109651:	01 c8                	add    %ecx,%eax
80109653:	05 98 00 00 00       	add    $0x98,%eax
80109658:	8b 00                	mov    (%eax),%eax
8010965a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010965e:	c7 04 24 31 a4 10 80 	movl   $0x8010a431,(%esp)
80109665:	e8 36 6d ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,mem,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
8010966a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109671:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109674:	89 d0                	mov    %edx,%eax
80109676:	c1 e0 02             	shl    $0x2,%eax
80109679:	01 d0                	add    %edx,%eax
8010967b:	c1 e0 02             	shl    $0x2,%eax
8010967e:	01 c8                	add    %ecx,%eax
80109680:	05 98 00 00 00       	add    $0x98,%eax
80109685:	8b 00                	mov    (%eax),%eax
80109687:	89 c2                	mov    %eax,%edx
80109689:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010968f:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109696:	00 
80109697:	89 54 24 08          	mov    %edx,0x8(%esp)
8010969b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010969e:	89 54 24 04          	mov    %edx,0x4(%esp)
801096a2:	89 04 24             	mov    %eax,(%esp)
801096a5:	e8 37 93 ff ff       	call   801029e1 <readFromSwapFile>
801096aa:	83 f8 ff             	cmp    $0xffffffff,%eax
801096ad:	75 0c                	jne    801096bb <fixPage+0x17b>
          panic("nothing read");
801096af:	c7 04 24 3b a4 10 80 	movl   $0x8010a43b,(%esp)
801096b6:	e8 7f 6e ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1){  //need to swap out
801096bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096c1:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801096c7:	83 f8 0e             	cmp    $0xe,%eax
801096ca:	76 1e                	jbe    801096ea <fixPage+0x1aa>
          swapOut();
801096cc:	e8 d2 00 00 00       	call   801097a3 <swapOut>
          lcr3(v2p(proc->pgdir));
801096d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096d7:	8b 40 04             	mov    0x4(%eax),%eax
801096da:	89 04 24             	mov    %eax,(%esp)
801096dd:	e8 f7 e9 ff ff       	call   801080d9 <v2p>
801096e2:	89 04 24             	mov    %eax,(%esp)
801096e5:	e8 e4 e9 ff ff       	call   801080ce <lcr3>
        }
        proc->pagesMetaData[i].isPhysical = 1;
801096ea:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096f4:	89 d0                	mov    %edx,%eax
801096f6:	c1 e0 02             	shl    $0x2,%eax
801096f9:	01 d0                	add    %edx,%eax
801096fb:	c1 e0 02             	shl    $0x2,%eax
801096fe:	01 c8                	add    %ecx,%eax
80109700:	05 94 00 00 00       	add    $0x94,%eax
80109705:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  
8010970b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109712:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109715:	89 d0                	mov    %edx,%eax
80109717:	c1 e0 02             	shl    $0x2,%eax
8010971a:	01 d0                	add    %edx,%eax
8010971c:	c1 e0 02             	shl    $0x2,%eax
8010971f:	01 c8                	add    %ecx,%eax
80109721:	05 a0 00 00 00       	add    $0xa0,%eax
80109726:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
80109729:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109730:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109733:	89 d0                	mov    %edx,%eax
80109735:	c1 e0 02             	shl    $0x2,%eax
80109738:	01 d0                	add    %edx,%eax
8010973a:	c1 e0 02             	shl    $0x2,%eax
8010973d:	01 c8                	add    %ecx,%eax
8010973f:	05 98 00 00 00       	add    $0x98,%eax
80109744:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
8010974a:	eb 0e                	jmp    8010975a <fixPage+0x21a>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010974c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109750:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109754:	0f 8e 50 fe ff ff    	jle    801095aa <fixPage+0x6a>
        break;
      }
    }
  }    
    //memmove(mem,buf,PGSIZE);
    *pte &= ~PTE_PG;  //turn off flag
8010975a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010975d:	8b 00                	mov    (%eax),%eax
8010975f:	80 e4 fd             	and    $0xfd,%ah
80109762:	89 c2                	mov    %eax,%edx
80109764:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109767:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
80109769:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010976c:	89 04 24             	mov    %eax,(%esp)
8010976f:	e8 65 e9 ff ff       	call   801080d9 <v2p>
80109774:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109777:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010977e:	8b 52 04             	mov    0x4(%edx),%edx
80109781:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109788:	00 
80109789:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010978d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109794:	00 
80109795:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80109799:	89 14 24             	mov    %edx,(%esp)
8010979c:	e8 6a ee ff ff       	call   8010860b <mappages>
    //memmove(buf,0,PGSIZE);
  }
801097a1:	c9                   	leave  
801097a2:	c3                   	ret    

801097a3 <swapOut>:

//swap out a page from proc.
  void swapOut(){
801097a3:	55                   	push   %ebp
801097a4:	89 e5                	mov    %esp,%ebp
801097a6:	53                   	push   %ebx
801097a7:	83 ec 34             	sub    $0x34,%esp
    int offset;
    //char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    uint flags;
    int index = -1;
801097aa:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
801097b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801097b7:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801097bd:	83 c0 03             	add    $0x3,%eax
801097c0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    char minNFU = 0x80;
801097c3:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        }
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
801097c7:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
801097cb:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801097d2:	eb 6f                	jmp    80109843 <swapOut+0xa0>
          //cprintf("NFU: %d j=%d\n", minNFU, j);
          //cprintf("checking entry %d minNFU=%d curr=%d %d\n",j, minNFU, proc->pagesMetaData[j].lru, (proc->pagesMetaData[j].lru >= minNFU));
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru >= minNFU){
801097d4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801097de:	89 d0                	mov    %edx,%eax
801097e0:	c1 e0 02             	shl    $0x2,%eax
801097e3:	01 d0                	add    %edx,%eax
801097e5:	c1 e0 02             	shl    $0x2,%eax
801097e8:	01 c8                	add    %ecx,%eax
801097ea:	05 94 00 00 00       	add    $0x94,%eax
801097ef:	8b 00                	mov    (%eax),%eax
801097f1:	85 c0                	test   %eax,%eax
801097f3:	74 4a                	je     8010983f <swapOut+0x9c>
801097f5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801097ff:	89 d0                	mov    %edx,%eax
80109801:	c1 e0 02             	shl    $0x2,%eax
80109804:	01 d0                	add    %edx,%eax
80109806:	c1 e0 02             	shl    $0x2,%eax
80109809:	01 c8                	add    %ecx,%eax
8010980b:	05 a0 00 00 00       	add    $0xa0,%eax
80109810:	0f b6 00             	movzbl (%eax),%eax
80109813:	3a 45 ef             	cmp    -0x11(%ebp),%al
80109816:	7c 27                	jl     8010983f <swapOut+0x9c>
            minNFU = proc->pagesMetaData[j].lru;
80109818:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010981f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109822:	89 d0                	mov    %edx,%eax
80109824:	c1 e0 02             	shl    $0x2,%eax
80109827:	01 d0                	add    %edx,%eax
80109829:	c1 e0 02             	shl    $0x2,%eax
8010982c:	01 c8                	add    %ecx,%eax
8010982e:	05 a0 00 00 00       	add    $0xa0,%eax
80109833:	0f b6 00             	movzbl (%eax),%eax
80109836:	88 45 ef             	mov    %al,-0x11(%ebp)
            index = j;
80109839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010983c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
8010983f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109843:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109847:	7e 8b                	jle    801097d4 <swapOut+0x31>
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru >= minNFU){
            minNFU = proc->pagesMetaData[j].lru;
            index = j;
          }
        }
        break;
80109849:	90                   	nop
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
8010984a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109851:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109854:	89 d0                	mov    %edx,%eax
80109856:	c1 e0 02             	shl    $0x2,%eax
80109859:	01 d0                	add    %edx,%eax
8010985b:	c1 e0 02             	shl    $0x2,%eax
8010985e:	01 c8                	add    %ecx,%eax
80109860:	05 94 00 00 00       	add    $0x94,%eax
80109865:	8b 00                	mov    (%eax),%eax
80109867:	85 c0                	test   %eax,%eax
80109869:	0f 84 b1 01 00 00    	je     80109a20 <swapOut+0x27d>
      proc->swappedOutCounter++;
8010986f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109875:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
8010987b:	83 c2 01             	add    $0x1,%edx
8010987e:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
80109884:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010988b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010988e:	89 d0                	mov    %edx,%eax
80109890:	c1 e0 02             	shl    $0x2,%eax
80109893:	01 d0                	add    %edx,%eax
80109895:	c1 e0 02             	shl    $0x2,%eax
80109898:	01 c8                	add    %ecx,%eax
8010989a:	05 90 00 00 00       	add    $0x90,%eax
8010989f:	8b 00                	mov    (%eax),%eax
801098a1:	89 04 24             	mov    %eax,(%esp)
801098a4:	e8 3c fb ff ff       	call   801093e5 <findNextOpenPage>
801098a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      cprintf("swapping out %x to offset %d\n",proc->pagesMetaData[index].va,offset);
801098ac:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801098b3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098b6:	89 d0                	mov    %edx,%eax
801098b8:	c1 e0 02             	shl    $0x2,%eax
801098bb:	01 d0                	add    %edx,%eax
801098bd:	c1 e0 02             	shl    $0x2,%eax
801098c0:	01 c8                	add    %ecx,%eax
801098c2:	05 90 00 00 00       	add    $0x90,%eax
801098c7:	8b 00                	mov    (%eax),%eax
801098c9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801098cc:	89 54 24 08          	mov    %edx,0x8(%esp)
801098d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801098d4:	c7 04 24 48 a4 10 80 	movl   $0x8010a448,(%esp)
801098db:	e8 c0 6a ff ff       	call   801003a0 <cprintf>
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
801098e0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801098e7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098ea:	89 d0                	mov    %edx,%eax
801098ec:	c1 e0 02             	shl    $0x2,%eax
801098ef:	01 d0                	add    %edx,%eax
801098f1:	c1 e0 02             	shl    $0x2,%eax
801098f4:	01 c8                	add    %ecx,%eax
801098f6:	05 90 00 00 00       	add    $0x90,%eax
801098fb:	8b 10                	mov    (%eax),%edx
801098fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109903:	8b 40 04             	mov    0x4(%eax),%eax
80109906:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010990d:	00 
8010990e:	89 54 24 04          	mov    %edx,0x4(%esp)
80109912:	89 04 24             	mov    %eax,(%esp)
80109915:	e8 4f ec ff ff       	call   80108569 <walkpgdir>
8010991a:	89 45 e0             	mov    %eax,-0x20(%ebp)
      proc->pagesMetaData[index].fileOffset = offset;
8010991d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109924:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109927:	89 d0                	mov    %edx,%eax
80109929:	c1 e0 02             	shl    $0x2,%eax
8010992c:	01 d0                	add    %edx,%eax
8010992e:	c1 e0 02             	shl    $0x2,%eax
80109931:	01 c8                	add    %ecx,%eax
80109933:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
80109939:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010993c:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
8010993e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109945:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109948:	89 d0                	mov    %edx,%eax
8010994a:	c1 e0 02             	shl    $0x2,%eax
8010994d:	01 d0                	add    %edx,%eax
8010994f:	c1 e0 02             	shl    $0x2,%eax
80109952:	01 c8                	add    %ecx,%eax
80109954:	05 94 00 00 00       	add    $0x94,%eax
80109959:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
8010995f:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109966:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010996c:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80109972:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109975:	89 d0                	mov    %edx,%eax
80109977:	c1 e0 02             	shl    $0x2,%eax
8010997a:	01 d0                	add    %edx,%eax
8010997c:	c1 e0 02             	shl    $0x2,%eax
8010997f:	01 d8                	add    %ebx,%eax
80109981:	05 9c 00 00 00       	add    $0x9c,%eax
80109986:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80109988:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010998e:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80109994:	83 c2 01             	add    $0x1,%edx
80109997:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      writeToSwapFile(proc,p2v(PTE_ADDR(*pte)),offset,PGSIZE);
8010999d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801099a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801099a3:	8b 00                	mov    (%eax),%eax
801099a5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801099aa:	89 04 24             	mov    %eax,(%esp)
801099ad:	e8 34 e7 ff ff       	call   801080e6 <p2v>
801099b2:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801099b9:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801099c0:	00 
801099c1:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801099c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801099c9:	89 14 24             	mov    %edx,(%esp)
801099cc:	e8 e0 8f ff ff       	call   801029b1 <writeToSwapFile>
      pa = PTE_ADDR(*pte);
801099d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801099d4:	8b 00                	mov    (%eax),%eax
801099d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801099db:	89 45 dc             	mov    %eax,-0x24(%ebp)
      flags = PTE_FLAGS(*pte);
801099de:	8b 45 e0             	mov    -0x20(%ebp),%eax
801099e1:	8b 00                	mov    (%eax),%eax
801099e3:	25 ff 0f 00 00       	and    $0xfff,%eax
801099e8:	89 45 d8             	mov    %eax,-0x28(%ebp)
      if(pa != 0){
801099eb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801099ef:	74 13                	je     80109a04 <swapOut+0x261>
        kfree(p2v(pa)); 
801099f1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801099f4:	89 04 24             	mov    %eax,(%esp)
801099f7:	e8 ea e6 ff ff       	call   801080e6 <p2v>
801099fc:	89 04 24             	mov    %eax,(%esp)
801099ff:	e8 f9 97 ff ff       	call   801031fd <kfree>
      }
      *pte = 0 | flags | PTE_PG;
80109a04:	8b 45 d8             	mov    -0x28(%ebp),%eax
80109a07:	80 cc 02             	or     $0x2,%ah
80109a0a:	89 c2                	mov    %eax,%edx
80109a0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109a0f:	89 10                	mov    %edx,(%eax)
      *pte &= ~PTE_P;
80109a11:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109a14:	8b 00                	mov    (%eax),%eax
80109a16:	83 e0 fe             	and    $0xfffffffe,%eax
80109a19:	89 c2                	mov    %eax,%edx
80109a1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109a1e:	89 10                	mov    %edx,(%eax)
    }
  }
80109a20:	83 c4 34             	add    $0x34,%esp
80109a23:	5b                   	pop    %ebx
80109a24:	5d                   	pop    %ebp
80109a25:	c3                   	ret    

80109a26 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109a26:	55                   	push   %ebp
80109a27:	89 e5                	mov    %esp,%ebp
80109a29:	53                   	push   %ebx
80109a2a:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
80109a2d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109a34:	e9 cf 00 00 00       	jmp    80109b08 <updateAge+0xe2>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=(char *) -1){ //only if on RAM
80109a39:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a3f:	89 d0                	mov    %edx,%eax
80109a41:	c1 e0 02             	shl    $0x2,%eax
80109a44:	01 d0                	add    %edx,%eax
80109a46:	c1 e0 02             	shl    $0x2,%eax
80109a49:	01 c8                	add    %ecx,%eax
80109a4b:	05 94 00 00 00       	add    $0x94,%eax
80109a50:	8b 00                	mov    (%eax),%eax
80109a52:	85 c0                	test   %eax,%eax
80109a54:	0f 84 aa 00 00 00    	je     80109b04 <updateAge+0xde>
80109a5a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a5d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a60:	89 d0                	mov    %edx,%eax
80109a62:	c1 e0 02             	shl    $0x2,%eax
80109a65:	01 d0                	add    %edx,%eax
80109a67:	c1 e0 02             	shl    $0x2,%eax
80109a6a:	01 c8                	add    %ecx,%eax
80109a6c:	05 90 00 00 00       	add    $0x90,%eax
80109a71:	8b 00                	mov    (%eax),%eax
80109a73:	83 f8 ff             	cmp    $0xffffffff,%eax
80109a76:	0f 84 88 00 00 00    	je     80109b04 <updateAge+0xde>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
80109a7c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a7f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a82:	89 d0                	mov    %edx,%eax
80109a84:	c1 e0 02             	shl    $0x2,%eax
80109a87:	01 d0                	add    %edx,%eax
80109a89:	c1 e0 02             	shl    $0x2,%eax
80109a8c:	01 c8                	add    %ecx,%eax
80109a8e:	05 a0 00 00 00       	add    $0xa0,%eax
80109a93:	0f b6 00             	movzbl (%eax),%eax
80109a96:	d0 f8                	sar    %al
80109a98:	89 c1                	mov    %eax,%ecx
80109a9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
80109a9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109aa0:	89 d0                	mov    %edx,%eax
80109aa2:	c1 e0 02             	shl    $0x2,%eax
80109aa5:	01 d0                	add    %edx,%eax
80109aa7:	c1 e0 02             	shl    $0x2,%eax
80109aaa:	01 d8                	add    %ebx,%eax
80109aac:	05 a0 00 00 00       	add    $0xa0,%eax
80109ab1:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
80109ab3:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109ab6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109ab9:	89 d0                	mov    %edx,%eax
80109abb:	c1 e0 02             	shl    $0x2,%eax
80109abe:	01 d0                	add    %edx,%eax
80109ac0:	c1 e0 02             	shl    $0x2,%eax
80109ac3:	01 c8                	add    %ecx,%eax
80109ac5:	05 90 00 00 00       	add    $0x90,%eax
80109aca:	8b 10                	mov    (%eax),%edx
80109acc:	8b 45 08             	mov    0x8(%ebp),%eax
80109acf:	8b 40 04             	mov    0x4(%eax),%eax
80109ad2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109ad9:	00 
80109ada:	89 54 24 04          	mov    %edx,0x4(%esp)
80109ade:	89 04 24             	mov    %eax,(%esp)
80109ae1:	e8 83 ea ff ff       	call   80108569 <walkpgdir>
80109ae6:	89 45 f0             	mov    %eax,-0x10(%ebp)
         if(*pte & PTE_A){
80109ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109aec:	8b 00                	mov    (%eax),%eax
80109aee:	83 e0 20             	and    $0x20,%eax
80109af1:	85 c0                	test   %eax,%eax
80109af3:	74 0f                	je     80109b04 <updateAge+0xde>
           *pte &= ~PTE_A; //turn off bit 
80109af5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109af8:	8b 00                	mov    (%eax),%eax
80109afa:	83 e0 df             	and    $0xffffffdf,%eax
80109afd:	89 c2                	mov    %eax,%edx
80109aff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b02:	89 10                	mov    %edx,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=0; i<30; i++)
80109b04:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109b08:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109b0c:	0f 8e 27 ff ff ff    	jle    80109a39 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
         if(*pte & PTE_A){
           *pte &= ~PTE_A; //turn off bit 
       }
    }
  }
80109b12:	83 c4 24             	add    $0x24,%esp
80109b15:	5b                   	pop    %ebx
80109b16:	5d                   	pop    %ebp
80109b17:	c3                   	ret    

80109b18 <isShell>:

int
isShell(){
80109b18:	55                   	push   %ebp
80109b19:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 's') && (proc->name[1] == 'h');
80109b1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b21:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109b25:	3c 73                	cmp    $0x73,%al
80109b27:	75 15                	jne    80109b3e <isShell+0x26>
80109b29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b2f:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109b33:	3c 68                	cmp    $0x68,%al
80109b35:	75 07                	jne    80109b3e <isShell+0x26>
80109b37:	b8 01 00 00 00       	mov    $0x1,%eax
80109b3c:	eb 05                	jmp    80109b43 <isShell+0x2b>
80109b3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109b43:	5d                   	pop    %ebp
80109b44:	c3                   	ret    

80109b45 <isInit>:

int
isInit(){
80109b45:	55                   	push   %ebp
80109b46:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 'i') && (proc->name[1] == 'n') && (proc->name[2] == 'i') && (proc->name[3] == 't');
80109b48:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b4e:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109b52:	3c 69                	cmp    $0x69,%al
80109b54:	75 31                	jne    80109b87 <isInit+0x42>
80109b56:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b5c:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109b60:	3c 6e                	cmp    $0x6e,%al
80109b62:	75 23                	jne    80109b87 <isInit+0x42>
80109b64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b6a:	0f b6 40 6e          	movzbl 0x6e(%eax),%eax
80109b6e:	3c 69                	cmp    $0x69,%al
80109b70:	75 15                	jne    80109b87 <isInit+0x42>
80109b72:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b78:	0f b6 40 6f          	movzbl 0x6f(%eax),%eax
80109b7c:	3c 74                	cmp    $0x74,%al
80109b7e:	75 07                	jne    80109b87 <isInit+0x42>
80109b80:	b8 01 00 00 00       	mov    $0x1,%eax
80109b85:	eb 05                	jmp    80109b8c <isInit+0x47>
80109b87:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109b8c:	5d                   	pop    %ebp
80109b8d:	c3                   	ret    
