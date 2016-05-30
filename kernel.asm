
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
8010002d:	b8 99 3e 10 80       	mov    $0x80103e99,%eax
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
8010003a:	c7 44 24 04 58 9b 10 	movl   $0x80109b58,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 ff 56 00 00       	call   8010574d <initlock>

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
801000bd:	e8 ac 56 00 00       	call   8010576e <acquire>

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
80100104:	e8 c7 56 00 00       	call   801057d0 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 1b 53 00 00       	call   8010543f <sleep>
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
8010017c:	e8 4f 56 00 00       	call   801057d0 <release>
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
80100198:	c7 04 24 5f 9b 10 80 	movl   $0x80109b5f,(%esp)
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
801001d3:	e8 e6 2c 00 00       	call   80102ebe <iderw>
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
801001ef:	c7 04 24 70 9b 10 80 	movl   $0x80109b70,(%esp)
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
80100210:	e8 a9 2c 00 00       	call   80102ebe <iderw>
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
80100229:	c7 04 24 77 9b 10 80 	movl   $0x80109b77,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 2d 55 00 00       	call   8010576e <acquire>

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
8010029d:	e8 79 52 00 00       	call   8010551b <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 22 55 00 00       	call   801057d0 <release>
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
801003bb:	e8 ae 53 00 00       	call   8010576e <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 7e 9b 10 80 	movl   $0x80109b7e,(%esp)
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
801004b0:	c7 45 ec 87 9b 10 80 	movl   $0x80109b87,-0x14(%ebp)
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
80100533:	e8 98 52 00 00       	call   801057d0 <release>
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
8010055f:	c7 04 24 8e 9b 10 80 	movl   $0x80109b8e,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 9d 9b 10 80 	movl   $0x80109b9d,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 8b 52 00 00       	call   8010581f <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 9f 9b 10 80 	movl   $0x80109b9f,(%esp)
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
80100699:	c7 04 24 a3 9b 10 80 	movl   $0x80109ba3,(%esp)
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
801006cd:	e8 bf 53 00 00       	call   80105a91 <memmove>
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
801006fc:	e8 c1 52 00 00       	call   801059c2 <memset>
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
80100791:	e8 90 6c 00 00       	call   80107426 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 84 6c 00 00       	call   80107426 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 78 6c 00 00       	call   80107426 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 6b 6c 00 00       	call   80107426 <uartputc>
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
801007dc:	e8 8d 4f 00 00       	call   8010576e <acquire>
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
80100917:	e8 ff 4b 00 00       	call   8010551b <wakeup>
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
80100938:	e8 93 4e 00 00       	call   801057d0 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 79 4c 00 00       	call   801055c1 <procdump>
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
80100956:	e8 b2 11 00 00       	call   80101b0d <iunlock>
  target = n;
8010095b:	8b 45 10             	mov    0x10(%ebp),%eax
8010095e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100961:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100968:	e8 01 4e 00 00       	call   8010576e <acquire>
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
80100988:	e8 43 4e 00 00       	call   801057d0 <release>
        ilock(ip);
8010098d:	8b 45 08             	mov    0x8(%ebp),%eax
80100990:	89 04 24             	mov    %eax,(%esp)
80100993:	e8 21 10 00 00       	call   801019b9 <ilock>
        return -1;
80100998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010099d:	e9 a5 00 00 00       	jmp    80100a47 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
801009a2:	c7 44 24 04 c0 d5 10 	movl   $0x8010d5c0,0x4(%esp)
801009a9:	80 
801009aa:	c7 04 24 00 28 11 80 	movl   $0x80112800,(%esp)
801009b1:	e8 89 4a 00 00       	call   8010543f <sleep>

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
80100a2d:	e8 9e 4d 00 00       	call   801057d0 <release>
  ilock(ip);
80100a32:	8b 45 08             	mov    0x8(%ebp),%eax
80100a35:	89 04 24             	mov    %eax,(%esp)
80100a38:	e8 7c 0f 00 00       	call   801019b9 <ilock>

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
80100a55:	e8 b3 10 00 00       	call   80101b0d <iunlock>
  acquire(&cons.lock);
80100a5a:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100a61:	e8 08 4d 00 00       	call   8010576e <acquire>
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
80100a9b:	e8 30 4d 00 00       	call   801057d0 <release>
  ilock(ip);
80100aa0:	8b 45 08             	mov    0x8(%ebp),%eax
80100aa3:	89 04 24             	mov    %eax,(%esp)
80100aa6:	e8 0e 0f 00 00       	call   801019b9 <ilock>

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
80100ab6:	c7 44 24 04 b6 9b 10 	movl   $0x80109bb6,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 83 4c 00 00       	call   8010574d <initlock>

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
80100aef:	e8 3d 3a 00 00       	call   80104531 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 72 25 00 00       	call   8010307a <ioapicenable>
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
80100b13:	e8 7a 30 00 00       	call   80103b92 <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 47 1a 00 00       	call   8010256a <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 e5 30 00 00       	call   80103c16 <end_op>
    return -1;
80100b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b36:	e9 cd 04 00 00       	jmp    80101008 <exec+0x4fe>
  }
  ilock(ip);
80100b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b3e:	89 04 24             	mov    %eax,(%esp)
80100b41:	e8 73 0e 00 00       	call   801019b9 <ilock>
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
80100b6d:	e8 5a 13 00 00       	call   80101ecc <readi>
80100b72:	83 f8 33             	cmp    $0x33,%eax
80100b75:	77 05                	ja     80100b7c <exec+0x72>
    goto bad;
80100b77:	e9 58 04 00 00       	jmp    80100fd4 <exec+0x4ca>
  if(elf.magic != ELF_MAGIC)
80100b7c:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100b82:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b87:	74 05                	je     80100b8e <exec+0x84>
    goto bad;
80100b89:	e9 46 04 00 00       	jmp    80100fd4 <exec+0x4ca>
  if((pgdir = setupkvm()) == 0)
80100b8e:	e8 e4 79 00 00       	call   80108577 <setupkvm>
80100b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b96:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b9a:	75 05                	jne    80100ba1 <exec+0x97>
    goto bad;
80100b9c:	e9 33 04 00 00       	jmp    80100fd4 <exec+0x4ca>

  // Load program into memory.
  sz = 0;
80100ba1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  int j;
  for(j = 0; j < 30; j++){
80100ba8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
80100baf:	eb 67                	jmp    80100c18 <exec+0x10e>
    proc->pagesMetaData[j].va = (char *) -1;
80100bb1:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bb8:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bbb:	89 d0                	mov    %edx,%eax
80100bbd:	c1 e0 02             	shl    $0x2,%eax
80100bc0:	01 d0                	add    %edx,%eax
80100bc2:	c1 e0 02             	shl    $0x2,%eax
80100bc5:	01 c8                	add    %ecx,%eax
80100bc7:	05 90 00 00 00       	add    $0x90,%eax
80100bcc:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    proc->pagesMetaData[j].isPhysical = 0;
80100bd2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bd9:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bdc:	89 d0                	mov    %edx,%eax
80100bde:	c1 e0 02             	shl    $0x2,%eax
80100be1:	01 d0                	add    %edx,%eax
80100be3:	c1 e0 02             	shl    $0x2,%eax
80100be6:	01 c8                	add    %ecx,%eax
80100be8:	05 94 00 00 00       	add    $0x94,%eax
80100bed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    proc->pagesMetaData[j].fileOffset = -1;
80100bf3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100bfa:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100bfd:	89 d0                	mov    %edx,%eax
80100bff:	c1 e0 02             	shl    $0x2,%eax
80100c02:	01 d0                	add    %edx,%eax
80100c04:	c1 e0 02             	shl    $0x2,%eax
80100c07:	01 c8                	add    %ecx,%eax
80100c09:	05 98 00 00 00       	add    $0x98,%eax
80100c0e:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    goto bad;

  // Load program into memory.
  sz = 0;
  int j;
  for(j = 0; j < 30; j++){
80100c14:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
80100c18:	83 7d d0 1d          	cmpl   $0x1d,-0x30(%ebp)
80100c1c:	7e 93                	jle    80100bb1 <exec+0xa7>
    proc->pagesMetaData[j].va = (char *) -1;
    proc->pagesMetaData[j].isPhysical = 0;
    proc->pagesMetaData[j].fileOffset = -1;
  }
  proc->memoryPagesCounter = 0;
80100c1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c24:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80100c2b:	00 00 00 
  proc->swapedPagesCounter = 0;
80100c2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100c34:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80100c3b:	00 00 00 
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c3e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c45:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100c4b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c4e:	e9 d5 00 00 00       	jmp    80100d28 <exec+0x21e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100c53:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c56:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100c5d:	00 
80100c5e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c62:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100c68:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c6c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c6f:	89 04 24             	mov    %eax,(%esp)
80100c72:	e8 55 12 00 00       	call   80101ecc <readi>
80100c77:	83 f8 20             	cmp    $0x20,%eax
80100c7a:	74 05                	je     80100c81 <exec+0x177>
      goto bad;
80100c7c:	e9 53 03 00 00       	jmp    80100fd4 <exec+0x4ca>
    if(ph.type != ELF_PROG_LOAD)
80100c81:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c87:	83 f8 01             	cmp    $0x1,%eax
80100c8a:	74 05                	je     80100c91 <exec+0x187>
      continue;
80100c8c:	e9 8a 00 00 00       	jmp    80100d1b <exec+0x211>
    if(ph.memsz < ph.filesz)
80100c91:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c97:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c9d:	39 c2                	cmp    %eax,%edx
80100c9f:	73 05                	jae    80100ca6 <exec+0x19c>
      goto bad;
80100ca1:	e9 2e 03 00 00       	jmp    80100fd4 <exec+0x4ca>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
80100ca6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100cac:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100cb2:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100cb8:	01 ca                	add    %ecx,%edx
80100cba:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100cbe:	89 54 24 08          	mov    %edx,0x8(%esp)
80100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc5:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ccc:	89 04 24             	mov    %eax,(%esp)
80100ccf:	e8 71 7c 00 00       	call   80108945 <allocuvm>
80100cd4:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cdb:	75 05                	jne    80100ce2 <exec+0x1d8>
      goto bad;
80100cdd:	e9 f2 02 00 00       	jmp    80100fd4 <exec+0x4ca>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100ce2:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100ce8:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100cee:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cf4:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100cf8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100cfc:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100cff:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d03:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d07:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d0a:	89 04 24             	mov    %eax,(%esp)
80100d0d:	e8 48 7b 00 00       	call   8010885a <loaduvm>
80100d12:	85 c0                	test   %eax,%eax
80100d14:	79 05                	jns    80100d1b <exec+0x211>
      goto bad;
80100d16:	e9 b9 02 00 00       	jmp    80100fd4 <exec+0x4ca>
    proc->pagesMetaData[j].isPhysical = 0;
    proc->pagesMetaData[j].fileOffset = -1;
  }
  proc->memoryPagesCounter = 0;
  proc->swapedPagesCounter = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d1b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d1f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d22:	83 c0 20             	add    $0x20,%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d2f:	0f b7 c0             	movzwl %ax,%eax
80100d32:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d35:	0f 8f 18 ff ff ff    	jg     80100c53 <exec+0x149>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz,proc)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d3e:	89 04 24             	mov    %eax,(%esp)
80100d41:	e8 fd 0e 00 00       	call   80101c43 <iunlockput>
  end_op();
80100d46:	e8 cb 2e 00 00       	call   80103c16 <end_op>
  ip = 0;
80100d4b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d52:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d55:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d5a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE,proc)) == 0)
80100d62:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100d68:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100d6b:	81 c2 00 20 00 00    	add    $0x2000,%edx
80100d71:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100d75:	89 54 24 08          	mov    %edx,0x8(%esp)
80100d79:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d83:	89 04 24             	mov    %eax,(%esp)
80100d86:	e8 ba 7b 00 00       	call   80108945 <allocuvm>
80100d8b:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d8e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d92:	75 05                	jne    80100d99 <exec+0x28f>
    goto bad;
80100d94:	e9 3b 02 00 00       	jmp    80100fd4 <exec+0x4ca>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d99:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d9c:	2d 00 20 00 00       	sub    $0x2000,%eax
80100da1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100da5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100da8:	89 04 24             	mov    %eax,(%esp)
80100dab:	e8 b1 80 00 00       	call   80108e61 <clearpteu>
  sp = sz;
80100db0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100db3:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100db6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100dbd:	e9 9a 00 00 00       	jmp    80100e5c <exec+0x352>
    if(argc >= MAXARG)
80100dc2:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100dc6:	76 05                	jbe    80100dcd <exec+0x2c3>
      goto bad;
80100dc8:	e9 07 02 00 00       	jmp    80100fd4 <exec+0x4ca>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100dcd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dda:	01 d0                	add    %edx,%eax
80100ddc:	8b 00                	mov    (%eax),%eax
80100dde:	89 04 24             	mov    %eax,(%esp)
80100de1:	e8 46 4e 00 00       	call   80105c2c <strlen>
80100de6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100de9:	29 c2                	sub    %eax,%edx
80100deb:	89 d0                	mov    %edx,%eax
80100ded:	83 e8 01             	sub    $0x1,%eax
80100df0:	83 e0 fc             	and    $0xfffffffc,%eax
80100df3:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100df6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e00:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e03:	01 d0                	add    %edx,%eax
80100e05:	8b 00                	mov    (%eax),%eax
80100e07:	89 04 24             	mov    %eax,(%esp)
80100e0a:	e8 1d 4e 00 00       	call   80105c2c <strlen>
80100e0f:	83 c0 01             	add    $0x1,%eax
80100e12:	89 c2                	mov    %eax,%edx
80100e14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e17:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100e1e:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e21:	01 c8                	add    %ecx,%eax
80100e23:	8b 00                	mov    (%eax),%eax
80100e25:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100e29:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e30:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e37:	89 04 24             	mov    %eax,(%esp)
80100e3a:	e8 a8 83 00 00       	call   801091e7 <copyout>
80100e3f:	85 c0                	test   %eax,%eax
80100e41:	79 05                	jns    80100e48 <exec+0x33e>
      goto bad;
80100e43:	e9 8c 01 00 00       	jmp    80100fd4 <exec+0x4ca>
    ustack[3+argc] = sp;
80100e48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e4b:	8d 50 03             	lea    0x3(%eax),%edx
80100e4e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e51:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e58:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e5f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e66:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e69:	01 d0                	add    %edx,%eax
80100e6b:	8b 00                	mov    (%eax),%eax
80100e6d:	85 c0                	test   %eax,%eax
80100e6f:	0f 85 4d ff ff ff    	jne    80100dc2 <exec+0x2b8>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100e75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e78:	83 c0 03             	add    $0x3,%eax
80100e7b:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e82:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e86:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e8d:	ff ff ff 
  ustack[1] = argc;
80100e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e93:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e9c:	83 c0 01             	add    $0x1,%eax
80100e9f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ea6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea9:	29 d0                	sub    %edx,%eax
80100eab:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100eb1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eb4:	83 c0 04             	add    $0x4,%eax
80100eb7:	c1 e0 02             	shl    $0x2,%eax
80100eba:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100ebd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100ec0:	83 c0 04             	add    $0x4,%eax
80100ec3:	c1 e0 02             	shl    $0x2,%eax
80100ec6:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100eca:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100ed0:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ed4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ed7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100edb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ede:	89 04 24             	mov    %eax,(%esp)
80100ee1:	e8 01 83 00 00       	call   801091e7 <copyout>
80100ee6:	85 c0                	test   %eax,%eax
80100ee8:	79 05                	jns    80100eef <exec+0x3e5>
    goto bad;
80100eea:	e9 e5 00 00 00       	jmp    80100fd4 <exec+0x4ca>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100eef:	8b 45 08             	mov    0x8(%ebp),%eax
80100ef2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ef8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100efb:	eb 17                	jmp    80100f14 <exec+0x40a>
    if(*s == '/')
80100efd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f00:	0f b6 00             	movzbl (%eax),%eax
80100f03:	3c 2f                	cmp    $0x2f,%al
80100f05:	75 09                	jne    80100f10 <exec+0x406>
      last = s+1;
80100f07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f0a:	83 c0 01             	add    $0x1,%eax
80100f0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100f10:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f17:	0f b6 00             	movzbl (%eax),%eax
80100f1a:	84 c0                	test   %al,%al
80100f1c:	75 df                	jne    80100efd <exec+0x3f3>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f24:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f27:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f2e:	00 
80100f2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100f32:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f36:	89 14 24             	mov    %edx,(%esp)
80100f39:	e8 a4 4c 00 00       	call   80105be2 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f3e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f44:	8b 40 04             	mov    0x4(%eax),%eax
80100f47:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100f4a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f50:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f53:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f56:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f5c:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f5f:	89 10                	mov    %edx,(%eax)
  //change proc->pagesMetaData according to the new exec
  if(proc->pid != 1){
80100f61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f67:	8b 40 10             	mov    0x10(%eax),%eax
80100f6a:	83 f8 01             	cmp    $0x1,%eax
80100f6d:	74 1c                	je     80100f8b <exec+0x481>
    removeSwapFile(proc);
80100f6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f75:	89 04 24             	mov    %eax,(%esp)
80100f78:	e8 f2 16 00 00       	call   8010266f <removeSwapFile>
    createSwapFile(proc);
80100f7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f83:	89 04 24             	mov    %eax,(%esp)
80100f86:	e8 f0 18 00 00       	call   8010287b <createSwapFile>
  //END NEW
  }
  proc->tf->eip = elf.entry;  // main
80100f8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f91:	8b 40 18             	mov    0x18(%eax),%eax
80100f94:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f9a:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100f9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fa3:	8b 40 18             	mov    0x18(%eax),%eax
80100fa6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100fa9:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100fac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100fb2:	89 04 24             	mov    %eax,(%esp)
80100fb5:	e8 ae 76 00 00       	call   80108668 <switchuvm>
  freevm(oldpgdir,0);
80100fba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100fc1:	00 
80100fc2:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100fc5:	89 04 24             	mov    %eax,(%esp)
80100fc8:	e8 f0 7d 00 00       	call   80108dbd <freevm>
  return 0;
80100fcd:	b8 00 00 00 00       	mov    $0x0,%eax
80100fd2:	eb 34                	jmp    80101008 <exec+0x4fe>

 bad:
  if(pgdir)
80100fd4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fd8:	74 13                	je     80100fed <exec+0x4e3>
    freevm(pgdir,0);
80100fda:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100fe1:	00 
80100fe2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100fe5:	89 04 24             	mov    %eax,(%esp)
80100fe8:	e8 d0 7d 00 00       	call   80108dbd <freevm>
  if(ip){
80100fed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ff1:	74 10                	je     80101003 <exec+0x4f9>
    iunlockput(ip);
80100ff3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ff6:	89 04 24             	mov    %eax,(%esp)
80100ff9:	e8 45 0c 00 00       	call   80101c43 <iunlockput>
    end_op();
80100ffe:	e8 13 2c 00 00       	call   80103c16 <end_op>
  }
  return -1;
80101003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101008:	c9                   	leave  
80101009:	c3                   	ret    

8010100a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
8010100a:	55                   	push   %ebp
8010100b:	89 e5                	mov    %esp,%ebp
8010100d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80101010:	c7 44 24 04 be 9b 10 	movl   $0x80109bbe,0x4(%esp)
80101017:	80 
80101018:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010101f:	e8 29 47 00 00       	call   8010574d <initlock>
}
80101024:	c9                   	leave  
80101025:	c3                   	ret    

80101026 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101026:	55                   	push   %ebp
80101027:	89 e5                	mov    %esp,%ebp
80101029:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010102c:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101033:	e8 36 47 00 00       	call   8010576e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101038:	c7 45 f4 54 28 11 80 	movl   $0x80112854,-0xc(%ebp)
8010103f:	eb 29                	jmp    8010106a <filealloc+0x44>
    if(f->ref == 0){
80101041:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101044:	8b 40 04             	mov    0x4(%eax),%eax
80101047:	85 c0                	test   %eax,%eax
80101049:	75 1b                	jne    80101066 <filealloc+0x40>
      f->ref = 1;
8010104b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010104e:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101055:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010105c:	e8 6f 47 00 00       	call   801057d0 <release>
      return f;
80101061:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101064:	eb 1e                	jmp    80101084 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101066:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
8010106a:	81 7d f4 b4 31 11 80 	cmpl   $0x801131b4,-0xc(%ebp)
80101071:	72 ce                	jb     80101041 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101073:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010107a:	e8 51 47 00 00       	call   801057d0 <release>
  return 0;
8010107f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101084:	c9                   	leave  
80101085:	c3                   	ret    

80101086 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101086:	55                   	push   %ebp
80101087:	89 e5                	mov    %esp,%ebp
80101089:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
8010108c:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101093:	e8 d6 46 00 00       	call   8010576e <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <filedup+0x28>
    panic("filedup");
801010a2:	c7 04 24 c5 9b 10 80 	movl   $0x80109bc5,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 01             	lea    0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bd:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010c4:	e8 07 47 00 00       	call   801057d0 <release>
  return f;
801010c9:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010cc:	c9                   	leave  
801010cd:	c3                   	ret    

801010ce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010ce:	55                   	push   %ebp
801010cf:	89 e5                	mov    %esp,%ebp
801010d1:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801010d4:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010db:	e8 8e 46 00 00       	call   8010576e <acquire>
  if(f->ref < 1)
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 04             	mov    0x4(%eax),%eax
801010e6:	85 c0                	test   %eax,%eax
801010e8:	7f 0c                	jg     801010f6 <fileclose+0x28>
    panic("fileclose");
801010ea:	c7 04 24 cd 9b 10 80 	movl   $0x80109bcd,(%esp)
801010f1:	e8 44 f4 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
801010f6:	8b 45 08             	mov    0x8(%ebp),%eax
801010f9:	8b 40 04             	mov    0x4(%eax),%eax
801010fc:	8d 50 ff             	lea    -0x1(%eax),%edx
801010ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101102:	89 50 04             	mov    %edx,0x4(%eax)
80101105:	8b 45 08             	mov    0x8(%ebp),%eax
80101108:	8b 40 04             	mov    0x4(%eax),%eax
8010110b:	85 c0                	test   %eax,%eax
8010110d:	7e 11                	jle    80101120 <fileclose+0x52>
    release(&ftable.lock);
8010110f:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101116:	e8 b5 46 00 00       	call   801057d0 <release>
8010111b:	e9 82 00 00 00       	jmp    801011a2 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101120:	8b 45 08             	mov    0x8(%ebp),%eax
80101123:	8b 10                	mov    (%eax),%edx
80101125:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101128:	8b 50 04             	mov    0x4(%eax),%edx
8010112b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010112e:	8b 50 08             	mov    0x8(%eax),%edx
80101131:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101134:	8b 50 0c             	mov    0xc(%eax),%edx
80101137:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010113a:	8b 50 10             	mov    0x10(%eax),%edx
8010113d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101140:	8b 40 14             	mov    0x14(%eax),%eax
80101143:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101146:	8b 45 08             	mov    0x8(%ebp),%eax
80101149:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101150:	8b 45 08             	mov    0x8(%ebp),%eax
80101153:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101159:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
80101160:	e8 6b 46 00 00       	call   801057d0 <release>
  
  if(ff.type == FD_PIPE)
80101165:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101168:	83 f8 01             	cmp    $0x1,%eax
8010116b:	75 18                	jne    80101185 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010116d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101171:	0f be d0             	movsbl %al,%edx
80101174:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101177:	89 54 24 04          	mov    %edx,0x4(%esp)
8010117b:	89 04 24             	mov    %eax,(%esp)
8010117e:	e8 5e 36 00 00       	call   801047e1 <pipeclose>
80101183:	eb 1d                	jmp    801011a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101185:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101188:	83 f8 02             	cmp    $0x2,%eax
8010118b:	75 15                	jne    801011a2 <fileclose+0xd4>
    begin_op();
8010118d:	e8 00 2a 00 00       	call   80103b92 <begin_op>
    iput(ff.ip);
80101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 d5 09 00 00       	call   80101b72 <iput>
    end_op();
8010119d:	e8 74 2a 00 00       	call   80103c16 <end_op>
  }
}
801011a2:	c9                   	leave  
801011a3:	c3                   	ret    

801011a4 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801011a4:	55                   	push   %ebp
801011a5:	89 e5                	mov    %esp,%ebp
801011a7:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801011aa:	8b 45 08             	mov    0x8(%ebp),%eax
801011ad:	8b 00                	mov    (%eax),%eax
801011af:	83 f8 02             	cmp    $0x2,%eax
801011b2:	75 38                	jne    801011ec <filestat+0x48>
    ilock(f->ip);
801011b4:	8b 45 08             	mov    0x8(%ebp),%eax
801011b7:	8b 40 10             	mov    0x10(%eax),%eax
801011ba:	89 04 24             	mov    %eax,(%esp)
801011bd:	e8 f7 07 00 00       	call   801019b9 <ilock>
    stati(f->ip, st);
801011c2:	8b 45 08             	mov    0x8(%ebp),%eax
801011c5:	8b 40 10             	mov    0x10(%eax),%eax
801011c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801011cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801011cf:	89 04 24             	mov    %eax,(%esp)
801011d2:	e8 b0 0c 00 00       	call   80101e87 <stati>
    iunlock(f->ip);
801011d7:	8b 45 08             	mov    0x8(%ebp),%eax
801011da:	8b 40 10             	mov    0x10(%eax),%eax
801011dd:	89 04 24             	mov    %eax,(%esp)
801011e0:	e8 28 09 00 00       	call   80101b0d <iunlock>
    return 0;
801011e5:	b8 00 00 00 00       	mov    $0x0,%eax
801011ea:	eb 05                	jmp    801011f1 <filestat+0x4d>
  }
  return -1;
801011ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011f1:	c9                   	leave  
801011f2:	c3                   	ret    

801011f3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f3:	55                   	push   %ebp
801011f4:	89 e5                	mov    %esp,%ebp
801011f6:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011f9:	8b 45 08             	mov    0x8(%ebp),%eax
801011fc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101200:	84 c0                	test   %al,%al
80101202:	75 0a                	jne    8010120e <fileread+0x1b>
    return -1;
80101204:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101209:	e9 9f 00 00 00       	jmp    801012ad <fileread+0xba>
  if(f->type == FD_PIPE)
8010120e:	8b 45 08             	mov    0x8(%ebp),%eax
80101211:	8b 00                	mov    (%eax),%eax
80101213:	83 f8 01             	cmp    $0x1,%eax
80101216:	75 1e                	jne    80101236 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101218:	8b 45 08             	mov    0x8(%ebp),%eax
8010121b:	8b 40 0c             	mov    0xc(%eax),%eax
8010121e:	8b 55 10             	mov    0x10(%ebp),%edx
80101221:	89 54 24 08          	mov    %edx,0x8(%esp)
80101225:	8b 55 0c             	mov    0xc(%ebp),%edx
80101228:	89 54 24 04          	mov    %edx,0x4(%esp)
8010122c:	89 04 24             	mov    %eax,(%esp)
8010122f:	e8 2e 37 00 00       	call   80104962 <piperead>
80101234:	eb 77                	jmp    801012ad <fileread+0xba>
  if(f->type == FD_INODE){
80101236:	8b 45 08             	mov    0x8(%ebp),%eax
80101239:	8b 00                	mov    (%eax),%eax
8010123b:	83 f8 02             	cmp    $0x2,%eax
8010123e:	75 61                	jne    801012a1 <fileread+0xae>
    ilock(f->ip);
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	8b 40 10             	mov    0x10(%eax),%eax
80101246:	89 04 24             	mov    %eax,(%esp)
80101249:	e8 6b 07 00 00       	call   801019b9 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101251:	8b 45 08             	mov    0x8(%ebp),%eax
80101254:	8b 50 14             	mov    0x14(%eax),%edx
80101257:	8b 45 08             	mov    0x8(%ebp),%eax
8010125a:	8b 40 10             	mov    0x10(%eax),%eax
8010125d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101261:	89 54 24 08          	mov    %edx,0x8(%esp)
80101265:	8b 55 0c             	mov    0xc(%ebp),%edx
80101268:	89 54 24 04          	mov    %edx,0x4(%esp)
8010126c:	89 04 24             	mov    %eax,(%esp)
8010126f:	e8 58 0c 00 00       	call   80101ecc <readi>
80101274:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101277:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010127b:	7e 11                	jle    8010128e <fileread+0x9b>
      f->off += r;
8010127d:	8b 45 08             	mov    0x8(%ebp),%eax
80101280:	8b 50 14             	mov    0x14(%eax),%edx
80101283:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101286:	01 c2                	add    %eax,%edx
80101288:	8b 45 08             	mov    0x8(%ebp),%eax
8010128b:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010128e:	8b 45 08             	mov    0x8(%ebp),%eax
80101291:	8b 40 10             	mov    0x10(%eax),%eax
80101294:	89 04 24             	mov    %eax,(%esp)
80101297:	e8 71 08 00 00       	call   80101b0d <iunlock>
    return r;
8010129c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010129f:	eb 0c                	jmp    801012ad <fileread+0xba>
  }
  panic("fileread");
801012a1:	c7 04 24 d7 9b 10 80 	movl   $0x80109bd7,(%esp)
801012a8:	e8 8d f2 ff ff       	call   8010053a <panic>
}
801012ad:	c9                   	leave  
801012ae:	c3                   	ret    

801012af <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012af:	55                   	push   %ebp
801012b0:	89 e5                	mov    %esp,%ebp
801012b2:	53                   	push   %ebx
801012b3:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801012b6:	8b 45 08             	mov    0x8(%ebp),%eax
801012b9:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012bd:	84 c0                	test   %al,%al
801012bf:	75 0a                	jne    801012cb <filewrite+0x1c>
    return -1;
801012c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012c6:	e9 20 01 00 00       	jmp    801013eb <filewrite+0x13c>
  if(f->type == FD_PIPE)
801012cb:	8b 45 08             	mov    0x8(%ebp),%eax
801012ce:	8b 00                	mov    (%eax),%eax
801012d0:	83 f8 01             	cmp    $0x1,%eax
801012d3:	75 21                	jne    801012f6 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801012d5:	8b 45 08             	mov    0x8(%ebp),%eax
801012d8:	8b 40 0c             	mov    0xc(%eax),%eax
801012db:	8b 55 10             	mov    0x10(%ebp),%edx
801012de:	89 54 24 08          	mov    %edx,0x8(%esp)
801012e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801012e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801012e9:	89 04 24             	mov    %eax,(%esp)
801012ec:	e8 82 35 00 00       	call   80104873 <pipewrite>
801012f1:	e9 f5 00 00 00       	jmp    801013eb <filewrite+0x13c>
  if(f->type == FD_INODE){
801012f6:	8b 45 08             	mov    0x8(%ebp),%eax
801012f9:	8b 00                	mov    (%eax),%eax
801012fb:	83 f8 02             	cmp    $0x2,%eax
801012fe:	0f 85 db 00 00 00    	jne    801013df <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101304:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010130b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101312:	e9 a8 00 00 00       	jmp    801013bf <filewrite+0x110>
      int n1 = n - i;
80101317:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010131a:	8b 55 10             	mov    0x10(%ebp),%edx
8010131d:	29 c2                	sub    %eax,%edx
8010131f:	89 d0                	mov    %edx,%eax
80101321:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101324:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101327:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010132a:	7e 06                	jle    80101332 <filewrite+0x83>
        n1 = max;
8010132c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010132f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101332:	e8 5b 28 00 00       	call   80103b92 <begin_op>
      ilock(f->ip);
80101337:	8b 45 08             	mov    0x8(%ebp),%eax
8010133a:	8b 40 10             	mov    0x10(%eax),%eax
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 74 06 00 00       	call   801019b9 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101345:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101348:	8b 45 08             	mov    0x8(%ebp),%eax
8010134b:	8b 50 14             	mov    0x14(%eax),%edx
8010134e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101351:	8b 45 0c             	mov    0xc(%ebp),%eax
80101354:	01 c3                	add    %eax,%ebx
80101356:	8b 45 08             	mov    0x8(%ebp),%eax
80101359:	8b 40 10             	mov    0x10(%eax),%eax
8010135c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101360:	89 54 24 08          	mov    %edx,0x8(%esp)
80101364:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 c0 0c 00 00       	call   80102030 <writei>
80101370:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101373:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101377:	7e 11                	jle    8010138a <filewrite+0xdb>
        f->off += r;
80101379:	8b 45 08             	mov    0x8(%ebp),%eax
8010137c:	8b 50 14             	mov    0x14(%eax),%edx
8010137f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101382:	01 c2                	add    %eax,%edx
80101384:	8b 45 08             	mov    0x8(%ebp),%eax
80101387:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010138a:	8b 45 08             	mov    0x8(%ebp),%eax
8010138d:	8b 40 10             	mov    0x10(%eax),%eax
80101390:	89 04 24             	mov    %eax,(%esp)
80101393:	e8 75 07 00 00       	call   80101b0d <iunlock>
      end_op();
80101398:	e8 79 28 00 00       	call   80103c16 <end_op>

      if(r < 0)
8010139d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801013a1:	79 02                	jns    801013a5 <filewrite+0xf6>
        break;
801013a3:	eb 26                	jmp    801013cb <filewrite+0x11c>
      if(r != n1)
801013a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801013ab:	74 0c                	je     801013b9 <filewrite+0x10a>
        panic("short filewrite");
801013ad:	c7 04 24 e0 9b 10 80 	movl   $0x80109be0,(%esp)
801013b4:	e8 81 f1 ff ff       	call   8010053a <panic>
      i += r;
801013b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013bc:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c2:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c5:	0f 8c 4c ff ff ff    	jl     80101317 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ce:	3b 45 10             	cmp    0x10(%ebp),%eax
801013d1:	75 05                	jne    801013d8 <filewrite+0x129>
801013d3:	8b 45 10             	mov    0x10(%ebp),%eax
801013d6:	eb 05                	jmp    801013dd <filewrite+0x12e>
801013d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013dd:	eb 0c                	jmp    801013eb <filewrite+0x13c>
  }
  panic("filewrite");
801013df:	c7 04 24 f0 9b 10 80 	movl   $0x80109bf0,(%esp)
801013e6:	e8 4f f1 ff ff       	call   8010053a <panic>
}
801013eb:	83 c4 24             	add    $0x24,%esp
801013ee:	5b                   	pop    %ebx
801013ef:	5d                   	pop    %ebp
801013f0:	c3                   	ret    

801013f1 <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013f1:	55                   	push   %ebp
801013f2:	89 e5                	mov    %esp,%ebp
801013f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013f7:	8b 45 08             	mov    0x8(%ebp),%eax
801013fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101401:	00 
80101402:	89 04 24             	mov    %eax,(%esp)
80101405:	e8 9c ed ff ff       	call   801001a6 <bread>
8010140a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010140d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101410:	83 c0 18             	add    $0x18,%eax
80101413:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
8010141a:	00 
8010141b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010141f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101422:	89 04 24             	mov    %eax,(%esp)
80101425:	e8 67 46 00 00       	call   80105a91 <memmove>
  brelse(bp);
8010142a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010142d:	89 04 24             	mov    %eax,(%esp)
80101430:	e8 e2 ed ff ff       	call   80100217 <brelse>
}
80101435:	c9                   	leave  
80101436:	c3                   	ret    

80101437 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101437:	55                   	push   %ebp
80101438:	89 e5                	mov    %esp,%ebp
8010143a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010143d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101440:	8b 45 08             	mov    0x8(%ebp),%eax
80101443:	89 54 24 04          	mov    %edx,0x4(%esp)
80101447:	89 04 24             	mov    %eax,(%esp)
8010144a:	e8 57 ed ff ff       	call   801001a6 <bread>
8010144f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101455:	83 c0 18             	add    $0x18,%eax
80101458:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010145f:	00 
80101460:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101467:	00 
80101468:	89 04 24             	mov    %eax,(%esp)
8010146b:	e8 52 45 00 00       	call   801059c2 <memset>
  log_write(bp);
80101470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 22 29 00 00       	call   80103d9d <log_write>
  brelse(bp);
8010147b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010147e:	89 04 24             	mov    %eax,(%esp)
80101481:	e8 91 ed ff ff       	call   80100217 <brelse>
}
80101486:	c9                   	leave  
80101487:	c3                   	ret    

80101488 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101488:	55                   	push   %ebp
80101489:	89 e5                	mov    %esp,%ebp
8010148b:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
8010148e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101495:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010149c:	e9 07 01 00 00       	jmp    801015a8 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
801014a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014a4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801014aa:	85 c0                	test   %eax,%eax
801014ac:	0f 48 c2             	cmovs  %edx,%eax
801014af:	c1 f8 0c             	sar    $0xc,%eax
801014b2:	89 c2                	mov    %eax,%edx
801014b4:	a1 38 32 11 80       	mov    0x80113238,%eax
801014b9:	01 d0                	add    %edx,%eax
801014bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801014bf:	8b 45 08             	mov    0x8(%ebp),%eax
801014c2:	89 04 24             	mov    %eax,(%esp)
801014c5:	e8 dc ec ff ff       	call   801001a6 <bread>
801014ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014cd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014d4:	e9 9d 00 00 00       	jmp    80101576 <balloc+0xee>
      m = 1 << (bi % 8);
801014d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014dc:	99                   	cltd   
801014dd:	c1 ea 1d             	shr    $0x1d,%edx
801014e0:	01 d0                	add    %edx,%eax
801014e2:	83 e0 07             	and    $0x7,%eax
801014e5:	29 d0                	sub    %edx,%eax
801014e7:	ba 01 00 00 00       	mov    $0x1,%edx
801014ec:	89 c1                	mov    %eax,%ecx
801014ee:	d3 e2                	shl    %cl,%edx
801014f0:	89 d0                	mov    %edx,%eax
801014f2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014f8:	8d 50 07             	lea    0x7(%eax),%edx
801014fb:	85 c0                	test   %eax,%eax
801014fd:	0f 48 c2             	cmovs  %edx,%eax
80101500:	c1 f8 03             	sar    $0x3,%eax
80101503:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101506:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010150b:	0f b6 c0             	movzbl %al,%eax
8010150e:	23 45 e8             	and    -0x18(%ebp),%eax
80101511:	85 c0                	test   %eax,%eax
80101513:	75 5d                	jne    80101572 <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101515:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101518:	8d 50 07             	lea    0x7(%eax),%edx
8010151b:	85 c0                	test   %eax,%eax
8010151d:	0f 48 c2             	cmovs  %edx,%eax
80101520:	c1 f8 03             	sar    $0x3,%eax
80101523:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101526:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010152b:	89 d1                	mov    %edx,%ecx
8010152d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101530:	09 ca                	or     %ecx,%edx
80101532:	89 d1                	mov    %edx,%ecx
80101534:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101537:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010153b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010153e:	89 04 24             	mov    %eax,(%esp)
80101541:	e8 57 28 00 00       	call   80103d9d <log_write>
        brelse(bp);
80101546:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101549:	89 04 24             	mov    %eax,(%esp)
8010154c:	e8 c6 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101551:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101554:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101557:	01 c2                	add    %eax,%edx
80101559:	8b 45 08             	mov    0x8(%ebp),%eax
8010155c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101560:	89 04 24             	mov    %eax,(%esp)
80101563:	e8 cf fe ff ff       	call   80101437 <bzero>
        return b + bi;
80101568:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010156b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010156e:	01 d0                	add    %edx,%eax
80101570:	eb 52                	jmp    801015c4 <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101572:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101576:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010157d:	7f 17                	jg     80101596 <balloc+0x10e>
8010157f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101582:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101585:	01 d0                	add    %edx,%eax
80101587:	89 c2                	mov    %eax,%edx
80101589:	a1 20 32 11 80       	mov    0x80113220,%eax
8010158e:	39 c2                	cmp    %eax,%edx
80101590:	0f 82 43 ff ff ff    	jb     801014d9 <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101596:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101599:	89 04 24             	mov    %eax,(%esp)
8010159c:	e8 76 ec ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
801015a1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015ab:	a1 20 32 11 80       	mov    0x80113220,%eax
801015b0:	39 c2                	cmp    %eax,%edx
801015b2:	0f 82 e9 fe ff ff    	jb     801014a1 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015b8:	c7 04 24 fc 9b 10 80 	movl   $0x80109bfc,(%esp)
801015bf:	e8 76 ef ff ff       	call   8010053a <panic>
}
801015c4:	c9                   	leave  
801015c5:	c3                   	ret    

801015c6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015c6:	55                   	push   %ebp
801015c7:	89 e5                	mov    %esp,%ebp
801015c9:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
801015cc:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
801015d3:	80 
801015d4:	8b 45 08             	mov    0x8(%ebp),%eax
801015d7:	89 04 24             	mov    %eax,(%esp)
801015da:	e8 12 fe ff ff       	call   801013f1 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
801015df:	8b 45 0c             	mov    0xc(%ebp),%eax
801015e2:	c1 e8 0c             	shr    $0xc,%eax
801015e5:	89 c2                	mov    %eax,%edx
801015e7:	a1 38 32 11 80       	mov    0x80113238,%eax
801015ec:	01 c2                	add    %eax,%edx
801015ee:	8b 45 08             	mov    0x8(%ebp),%eax
801015f1:	89 54 24 04          	mov    %edx,0x4(%esp)
801015f5:	89 04 24             	mov    %eax,(%esp)
801015f8:	e8 a9 eb ff ff       	call   801001a6 <bread>
801015fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101600:	8b 45 0c             	mov    0xc(%ebp),%eax
80101603:	25 ff 0f 00 00       	and    $0xfff,%eax
80101608:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010160b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010160e:	99                   	cltd   
8010160f:	c1 ea 1d             	shr    $0x1d,%edx
80101612:	01 d0                	add    %edx,%eax
80101614:	83 e0 07             	and    $0x7,%eax
80101617:	29 d0                	sub    %edx,%eax
80101619:	ba 01 00 00 00       	mov    $0x1,%edx
8010161e:	89 c1                	mov    %eax,%ecx
80101620:	d3 e2                	shl    %cl,%edx
80101622:	89 d0                	mov    %edx,%eax
80101624:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101627:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010162a:	8d 50 07             	lea    0x7(%eax),%edx
8010162d:	85 c0                	test   %eax,%eax
8010162f:	0f 48 c2             	cmovs  %edx,%eax
80101632:	c1 f8 03             	sar    $0x3,%eax
80101635:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101638:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010163d:	0f b6 c0             	movzbl %al,%eax
80101640:	23 45 ec             	and    -0x14(%ebp),%eax
80101643:	85 c0                	test   %eax,%eax
80101645:	75 0c                	jne    80101653 <bfree+0x8d>
    panic("freeing free block");
80101647:	c7 04 24 12 9c 10 80 	movl   $0x80109c12,(%esp)
8010164e:	e8 e7 ee ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101653:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101656:	8d 50 07             	lea    0x7(%eax),%edx
80101659:	85 c0                	test   %eax,%eax
8010165b:	0f 48 c2             	cmovs  %edx,%eax
8010165e:	c1 f8 03             	sar    $0x3,%eax
80101661:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101664:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101669:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010166c:	f7 d1                	not    %ecx
8010166e:	21 ca                	and    %ecx,%edx
80101670:	89 d1                	mov    %edx,%ecx
80101672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101675:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101679:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010167c:	89 04 24             	mov    %eax,(%esp)
8010167f:	e8 19 27 00 00       	call   80103d9d <log_write>
  brelse(bp);
80101684:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101687:	89 04 24             	mov    %eax,(%esp)
8010168a:	e8 88 eb ff ff       	call   80100217 <brelse>
}
8010168f:	c9                   	leave  
80101690:	c3                   	ret    

80101691 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
80101691:	55                   	push   %ebp
80101692:	89 e5                	mov    %esp,%ebp
80101694:	57                   	push   %edi
80101695:	56                   	push   %esi
80101696:	53                   	push   %ebx
80101697:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
8010169a:	c7 44 24 04 25 9c 10 	movl   $0x80109c25,0x4(%esp)
801016a1:	80 
801016a2:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801016a9:	e8 9f 40 00 00       	call   8010574d <initlock>
  readsb(dev, &sb);
801016ae:	c7 44 24 04 20 32 11 	movl   $0x80113220,0x4(%esp)
801016b5:	80 
801016b6:	8b 45 08             	mov    0x8(%ebp),%eax
801016b9:	89 04 24             	mov    %eax,(%esp)
801016bc:	e8 30 fd ff ff       	call   801013f1 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
801016c1:	a1 38 32 11 80       	mov    0x80113238,%eax
801016c6:	8b 3d 34 32 11 80    	mov    0x80113234,%edi
801016cc:	8b 35 30 32 11 80    	mov    0x80113230,%esi
801016d2:	8b 1d 2c 32 11 80    	mov    0x8011322c,%ebx
801016d8:	8b 0d 28 32 11 80    	mov    0x80113228,%ecx
801016de:	8b 15 24 32 11 80    	mov    0x80113224,%edx
801016e4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
801016e7:	8b 15 20 32 11 80    	mov    0x80113220,%edx
801016ed:	89 44 24 1c          	mov    %eax,0x1c(%esp)
801016f1:	89 7c 24 18          	mov    %edi,0x18(%esp)
801016f5:	89 74 24 14          	mov    %esi,0x14(%esp)
801016f9:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801016fd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101701:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101704:	89 44 24 08          	mov    %eax,0x8(%esp)
80101708:	89 d0                	mov    %edx,%eax
8010170a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010170e:	c7 04 24 2c 9c 10 80 	movl   $0x80109c2c,(%esp)
80101715:	e8 86 ec ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
8010171a:	83 c4 3c             	add    $0x3c,%esp
8010171d:	5b                   	pop    %ebx
8010171e:	5e                   	pop    %esi
8010171f:	5f                   	pop    %edi
80101720:	5d                   	pop    %ebp
80101721:	c3                   	ret    

80101722 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101722:	55                   	push   %ebp
80101723:	89 e5                	mov    %esp,%ebp
80101725:	83 ec 28             	sub    $0x28,%esp
80101728:	8b 45 0c             	mov    0xc(%ebp),%eax
8010172b:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010172f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101736:	e9 9e 00 00 00       	jmp    801017d9 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
8010173b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010173e:	c1 e8 03             	shr    $0x3,%eax
80101741:	89 c2                	mov    %eax,%edx
80101743:	a1 34 32 11 80       	mov    0x80113234,%eax
80101748:	01 d0                	add    %edx,%eax
8010174a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010174e:	8b 45 08             	mov    0x8(%ebp),%eax
80101751:	89 04 24             	mov    %eax,(%esp)
80101754:	e8 4d ea ff ff       	call   801001a6 <bread>
80101759:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010175c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010175f:	8d 50 18             	lea    0x18(%eax),%edx
80101762:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101765:	83 e0 07             	and    $0x7,%eax
80101768:	c1 e0 06             	shl    $0x6,%eax
8010176b:	01 d0                	add    %edx,%eax
8010176d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101770:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101773:	0f b7 00             	movzwl (%eax),%eax
80101776:	66 85 c0             	test   %ax,%ax
80101779:	75 4f                	jne    801017ca <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
8010177b:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101782:	00 
80101783:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010178a:	00 
8010178b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010178e:	89 04 24             	mov    %eax,(%esp)
80101791:	e8 2c 42 00 00       	call   801059c2 <memset>
      dip->type = type;
80101796:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101799:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
8010179d:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 f2 25 00 00       	call   80103d9d <log_write>
      brelse(bp);
801017ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ae:	89 04 24             	mov    %eax,(%esp)
801017b1:	e8 61 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801017b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801017bd:	8b 45 08             	mov    0x8(%ebp),%eax
801017c0:	89 04 24             	mov    %eax,(%esp)
801017c3:	e8 ed 00 00 00       	call   801018b5 <iget>
801017c8:	eb 2b                	jmp    801017f5 <ialloc+0xd3>
    }
    brelse(bp);
801017ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017cd:	89 04 24             	mov    %eax,(%esp)
801017d0:	e8 42 ea ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
801017d5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801017d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017dc:	a1 28 32 11 80       	mov    0x80113228,%eax
801017e1:	39 c2                	cmp    %eax,%edx
801017e3:	0f 82 52 ff ff ff    	jb     8010173b <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801017e9:	c7 04 24 7f 9c 10 80 	movl   $0x80109c7f,(%esp)
801017f0:	e8 45 ed ff ff       	call   8010053a <panic>
}
801017f5:	c9                   	leave  
801017f6:	c3                   	ret    

801017f7 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801017f7:	55                   	push   %ebp
801017f8:	89 e5                	mov    %esp,%ebp
801017fa:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801017fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101800:	8b 40 04             	mov    0x4(%eax),%eax
80101803:	c1 e8 03             	shr    $0x3,%eax
80101806:	89 c2                	mov    %eax,%edx
80101808:	a1 34 32 11 80       	mov    0x80113234,%eax
8010180d:	01 c2                	add    %eax,%edx
8010180f:	8b 45 08             	mov    0x8(%ebp),%eax
80101812:	8b 00                	mov    (%eax),%eax
80101814:	89 54 24 04          	mov    %edx,0x4(%esp)
80101818:	89 04 24             	mov    %eax,(%esp)
8010181b:	e8 86 e9 ff ff       	call   801001a6 <bread>
80101820:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101826:	8d 50 18             	lea    0x18(%eax),%edx
80101829:	8b 45 08             	mov    0x8(%ebp),%eax
8010182c:	8b 40 04             	mov    0x4(%eax),%eax
8010182f:	83 e0 07             	and    $0x7,%eax
80101832:	c1 e0 06             	shl    $0x6,%eax
80101835:	01 d0                	add    %edx,%eax
80101837:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010183a:	8b 45 08             	mov    0x8(%ebp),%eax
8010183d:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101841:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101844:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101847:	8b 45 08             	mov    0x8(%ebp),%eax
8010184a:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010184e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101851:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101855:	8b 45 08             	mov    0x8(%ebp),%eax
80101858:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010185c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010185f:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101863:	8b 45 08             	mov    0x8(%ebp),%eax
80101866:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010186a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010186d:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101871:	8b 45 08             	mov    0x8(%ebp),%eax
80101874:	8b 50 18             	mov    0x18(%eax),%edx
80101877:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010187a:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010187d:	8b 45 08             	mov    0x8(%ebp),%eax
80101880:	8d 50 1c             	lea    0x1c(%eax),%edx
80101883:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101886:	83 c0 0c             	add    $0xc,%eax
80101889:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101890:	00 
80101891:	89 54 24 04          	mov    %edx,0x4(%esp)
80101895:	89 04 24             	mov    %eax,(%esp)
80101898:	e8 f4 41 00 00       	call   80105a91 <memmove>
  log_write(bp);
8010189d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a0:	89 04 24             	mov    %eax,(%esp)
801018a3:	e8 f5 24 00 00       	call   80103d9d <log_write>
  brelse(bp);
801018a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ab:	89 04 24             	mov    %eax,(%esp)
801018ae:	e8 64 e9 ff ff       	call   80100217 <brelse>
}
801018b3:	c9                   	leave  
801018b4:	c3                   	ret    

801018b5 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801018b5:	55                   	push   %ebp
801018b6:	89 e5                	mov    %esp,%ebp
801018b8:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801018bb:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801018c2:	e8 a7 3e 00 00       	call   8010576e <acquire>

  // Is the inode already cached?
  empty = 0;
801018c7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801018ce:	c7 45 f4 74 32 11 80 	movl   $0x80113274,-0xc(%ebp)
801018d5:	eb 59                	jmp    80101930 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801018d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018da:	8b 40 08             	mov    0x8(%eax),%eax
801018dd:	85 c0                	test   %eax,%eax
801018df:	7e 35                	jle    80101916 <iget+0x61>
801018e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018e4:	8b 00                	mov    (%eax),%eax
801018e6:	3b 45 08             	cmp    0x8(%ebp),%eax
801018e9:	75 2b                	jne    80101916 <iget+0x61>
801018eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ee:	8b 40 04             	mov    0x4(%eax),%eax
801018f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801018f4:	75 20                	jne    80101916 <iget+0x61>
      ip->ref++;
801018f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018f9:	8b 40 08             	mov    0x8(%eax),%eax
801018fc:	8d 50 01             	lea    0x1(%eax),%edx
801018ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101902:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101905:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010190c:	e8 bf 3e 00 00       	call   801057d0 <release>
      return ip;
80101911:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101914:	eb 6f                	jmp    80101985 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101916:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010191a:	75 10                	jne    8010192c <iget+0x77>
8010191c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010191f:	8b 40 08             	mov    0x8(%eax),%eax
80101922:	85 c0                	test   %eax,%eax
80101924:	75 06                	jne    8010192c <iget+0x77>
      empty = ip;
80101926:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101929:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010192c:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101930:	81 7d f4 14 42 11 80 	cmpl   $0x80114214,-0xc(%ebp)
80101937:	72 9e                	jb     801018d7 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101939:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010193d:	75 0c                	jne    8010194b <iget+0x96>
    panic("iget: no inodes");
8010193f:	c7 04 24 91 9c 10 80 	movl   $0x80109c91,(%esp)
80101946:	e8 ef eb ff ff       	call   8010053a <panic>

  ip = empty;
8010194b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101954:	8b 55 08             	mov    0x8(%ebp),%edx
80101957:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010195c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010195f:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101962:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101965:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010196c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010196f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101976:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
8010197d:	e8 4e 3e 00 00       	call   801057d0 <release>

  return ip;
80101982:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101985:	c9                   	leave  
80101986:	c3                   	ret    

80101987 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101987:	55                   	push   %ebp
80101988:	89 e5                	mov    %esp,%ebp
8010198a:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010198d:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101994:	e8 d5 3d 00 00       	call   8010576e <acquire>
  ip->ref++;
80101999:	8b 45 08             	mov    0x8(%ebp),%eax
8010199c:	8b 40 08             	mov    0x8(%eax),%eax
8010199f:	8d 50 01             	lea    0x1(%eax),%edx
801019a2:	8b 45 08             	mov    0x8(%ebp),%eax
801019a5:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019a8:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019af:	e8 1c 3e 00 00       	call   801057d0 <release>
  return ip;
801019b4:	8b 45 08             	mov    0x8(%ebp),%eax
}
801019b7:	c9                   	leave  
801019b8:	c3                   	ret    

801019b9 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801019b9:	55                   	push   %ebp
801019ba:	89 e5                	mov    %esp,%ebp
801019bc:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801019bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019c3:	74 0a                	je     801019cf <ilock+0x16>
801019c5:	8b 45 08             	mov    0x8(%ebp),%eax
801019c8:	8b 40 08             	mov    0x8(%eax),%eax
801019cb:	85 c0                	test   %eax,%eax
801019cd:	7f 0c                	jg     801019db <ilock+0x22>
    panic("ilock");
801019cf:	c7 04 24 a1 9c 10 80 	movl   $0x80109ca1,(%esp)
801019d6:	e8 5f eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019db:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019e2:	e8 87 3d 00 00       	call   8010576e <acquire>
  while(ip->flags & I_BUSY)
801019e7:	eb 13                	jmp    801019fc <ilock+0x43>
    sleep(ip, &icache.lock);
801019e9:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
801019f0:	80 
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	89 04 24             	mov    %eax,(%esp)
801019f7:	e8 43 3a 00 00       	call   8010543f <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801019fc:	8b 45 08             	mov    0x8(%ebp),%eax
801019ff:	8b 40 0c             	mov    0xc(%eax),%eax
80101a02:	83 e0 01             	and    $0x1,%eax
80101a05:	85 c0                	test   %eax,%eax
80101a07:	75 e0                	jne    801019e9 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101a09:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0c:	8b 40 0c             	mov    0xc(%eax),%eax
80101a0f:	83 c8 01             	or     $0x1,%eax
80101a12:	89 c2                	mov    %eax,%edx
80101a14:	8b 45 08             	mov    0x8(%ebp),%eax
80101a17:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101a1a:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101a21:	e8 aa 3d 00 00       	call   801057d0 <release>

  if(!(ip->flags & I_VALID)){
80101a26:	8b 45 08             	mov    0x8(%ebp),%eax
80101a29:	8b 40 0c             	mov    0xc(%eax),%eax
80101a2c:	83 e0 02             	and    $0x2,%eax
80101a2f:	85 c0                	test   %eax,%eax
80101a31:	0f 85 d4 00 00 00    	jne    80101b0b <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a37:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3a:	8b 40 04             	mov    0x4(%eax),%eax
80101a3d:	c1 e8 03             	shr    $0x3,%eax
80101a40:	89 c2                	mov    %eax,%edx
80101a42:	a1 34 32 11 80       	mov    0x80113234,%eax
80101a47:	01 c2                	add    %eax,%edx
80101a49:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4c:	8b 00                	mov    (%eax),%eax
80101a4e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a52:	89 04 24             	mov    %eax,(%esp)
80101a55:	e8 4c e7 ff ff       	call   801001a6 <bread>
80101a5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a60:	8d 50 18             	lea    0x18(%eax),%edx
80101a63:	8b 45 08             	mov    0x8(%ebp),%eax
80101a66:	8b 40 04             	mov    0x4(%eax),%eax
80101a69:	83 e0 07             	and    $0x7,%eax
80101a6c:	c1 e0 06             	shl    $0x6,%eax
80101a6f:	01 d0                	add    %edx,%eax
80101a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a77:	0f b7 10             	movzwl (%eax),%edx
80101a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7d:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101a81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a84:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101a88:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8b:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a92:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101a96:	8b 45 08             	mov    0x8(%ebp),%eax
80101a99:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa0:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101aa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa7:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101aab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aae:	8b 50 08             	mov    0x8(%eax),%edx
80101ab1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab4:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aba:	8d 50 0c             	lea    0xc(%eax),%edx
80101abd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac0:	83 c0 1c             	add    $0x1c,%eax
80101ac3:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101aca:	00 
80101acb:	89 54 24 04          	mov    %edx,0x4(%esp)
80101acf:	89 04 24             	mov    %eax,(%esp)
80101ad2:	e8 ba 3f 00 00       	call   80105a91 <memmove>
    brelse(bp);
80101ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ada:	89 04 24             	mov    %eax,(%esp)
80101add:	e8 35 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101ae2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae5:	8b 40 0c             	mov    0xc(%eax),%eax
80101ae8:	83 c8 02             	or     $0x2,%eax
80101aeb:	89 c2                	mov    %eax,%edx
80101aed:	8b 45 08             	mov    0x8(%ebp),%eax
80101af0:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101af3:	8b 45 08             	mov    0x8(%ebp),%eax
80101af6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101afa:	66 85 c0             	test   %ax,%ax
80101afd:	75 0c                	jne    80101b0b <ilock+0x152>
      panic("ilock: no type");
80101aff:	c7 04 24 a7 9c 10 80 	movl   $0x80109ca7,(%esp)
80101b06:	e8 2f ea ff ff       	call   8010053a <panic>
  }
}
80101b0b:	c9                   	leave  
80101b0c:	c3                   	ret    

80101b0d <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b0d:	55                   	push   %ebp
80101b0e:	89 e5                	mov    %esp,%ebp
80101b10:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101b13:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b17:	74 17                	je     80101b30 <iunlock+0x23>
80101b19:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1c:	8b 40 0c             	mov    0xc(%eax),%eax
80101b1f:	83 e0 01             	and    $0x1,%eax
80101b22:	85 c0                	test   %eax,%eax
80101b24:	74 0a                	je     80101b30 <iunlock+0x23>
80101b26:	8b 45 08             	mov    0x8(%ebp),%eax
80101b29:	8b 40 08             	mov    0x8(%eax),%eax
80101b2c:	85 c0                	test   %eax,%eax
80101b2e:	7f 0c                	jg     80101b3c <iunlock+0x2f>
    panic("iunlock");
80101b30:	c7 04 24 b6 9c 10 80 	movl   $0x80109cb6,(%esp)
80101b37:	e8 fe e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b43:	e8 26 3c 00 00       	call   8010576e <acquire>
  ip->flags &= ~I_BUSY;
80101b48:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4b:	8b 40 0c             	mov    0xc(%eax),%eax
80101b4e:	83 e0 fe             	and    $0xfffffffe,%eax
80101b51:	89 c2                	mov    %eax,%edx
80101b53:	8b 45 08             	mov    0x8(%ebp),%eax
80101b56:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101b59:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5c:	89 04 24             	mov    %eax,(%esp)
80101b5f:	e8 b7 39 00 00       	call   8010551b <wakeup>
  release(&icache.lock);
80101b64:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b6b:	e8 60 3c 00 00       	call   801057d0 <release>
}
80101b70:	c9                   	leave  
80101b71:	c3                   	ret    

80101b72 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b72:	55                   	push   %ebp
80101b73:	89 e5                	mov    %esp,%ebp
80101b75:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101b78:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b7f:	e8 ea 3b 00 00       	call   8010576e <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101b84:	8b 45 08             	mov    0x8(%ebp),%eax
80101b87:	8b 40 08             	mov    0x8(%eax),%eax
80101b8a:	83 f8 01             	cmp    $0x1,%eax
80101b8d:	0f 85 93 00 00 00    	jne    80101c26 <iput+0xb4>
80101b93:	8b 45 08             	mov    0x8(%ebp),%eax
80101b96:	8b 40 0c             	mov    0xc(%eax),%eax
80101b99:	83 e0 02             	and    $0x2,%eax
80101b9c:	85 c0                	test   %eax,%eax
80101b9e:	0f 84 82 00 00 00    	je     80101c26 <iput+0xb4>
80101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101bab:	66 85 c0             	test   %ax,%ax
80101bae:	75 76                	jne    80101c26 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101bb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb3:	8b 40 0c             	mov    0xc(%eax),%eax
80101bb6:	83 e0 01             	and    $0x1,%eax
80101bb9:	85 c0                	test   %eax,%eax
80101bbb:	74 0c                	je     80101bc9 <iput+0x57>
      panic("iput busy");
80101bbd:	c7 04 24 be 9c 10 80 	movl   $0x80109cbe,(%esp)
80101bc4:	e8 71 e9 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101bc9:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcc:	8b 40 0c             	mov    0xc(%eax),%eax
80101bcf:	83 c8 01             	or     $0x1,%eax
80101bd2:	89 c2                	mov    %eax,%edx
80101bd4:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd7:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101bda:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101be1:	e8 ea 3b 00 00       	call   801057d0 <release>
    itrunc(ip);
80101be6:	8b 45 08             	mov    0x8(%ebp),%eax
80101be9:	89 04 24             	mov    %eax,(%esp)
80101bec:	e8 7d 01 00 00       	call   80101d6e <itrunc>
    ip->type = 0;
80101bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf4:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101bfa:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfd:	89 04 24             	mov    %eax,(%esp)
80101c00:	e8 f2 fb ff ff       	call   801017f7 <iupdate>
    acquire(&icache.lock);
80101c05:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c0c:	e8 5d 3b 00 00       	call   8010576e <acquire>
    ip->flags = 0;
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	89 04 24             	mov    %eax,(%esp)
80101c21:	e8 f5 38 00 00       	call   8010551b <wakeup>
  }
  ip->ref--;
80101c26:	8b 45 08             	mov    0x8(%ebp),%eax
80101c29:	8b 40 08             	mov    0x8(%eax),%eax
80101c2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c32:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c35:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c3c:	e8 8f 3b 00 00       	call   801057d0 <release>
}
80101c41:	c9                   	leave  
80101c42:	c3                   	ret    

80101c43 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101c49:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4c:	89 04 24             	mov    %eax,(%esp)
80101c4f:	e8 b9 fe ff ff       	call   80101b0d <iunlock>
  iput(ip);
80101c54:	8b 45 08             	mov    0x8(%ebp),%eax
80101c57:	89 04 24             	mov    %eax,(%esp)
80101c5a:	e8 13 ff ff ff       	call   80101b72 <iput>
}
80101c5f:	c9                   	leave  
80101c60:	c3                   	ret    

80101c61 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c61:	55                   	push   %ebp
80101c62:	89 e5                	mov    %esp,%ebp
80101c64:	53                   	push   %ebx
80101c65:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c68:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c6c:	77 3e                	ja     80101cac <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101c6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c71:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c74:	83 c2 04             	add    $0x4,%edx
80101c77:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c7e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c82:	75 20                	jne    80101ca4 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c84:	8b 45 08             	mov    0x8(%ebp),%eax
80101c87:	8b 00                	mov    (%eax),%eax
80101c89:	89 04 24             	mov    %eax,(%esp)
80101c8c:	e8 f7 f7 ff ff       	call   80101488 <balloc>
80101c91:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c94:	8b 45 08             	mov    0x8(%ebp),%eax
80101c97:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c9a:	8d 4a 04             	lea    0x4(%edx),%ecx
80101c9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ca0:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ca7:	e9 bc 00 00 00       	jmp    80101d68 <bmap+0x107>
  }
  bn -= NDIRECT;
80101cac:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101cb0:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101cb4:	0f 87 a2 00 00 00    	ja     80101d5c <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101cba:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbd:	8b 40 4c             	mov    0x4c(%eax),%eax
80101cc0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cc3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cc7:	75 19                	jne    80101ce2 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101cc9:	8b 45 08             	mov    0x8(%ebp),%eax
80101ccc:	8b 00                	mov    (%eax),%eax
80101cce:	89 04 24             	mov    %eax,(%esp)
80101cd1:	e8 b2 f7 ff ff       	call   80101488 <balloc>
80101cd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cdc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cdf:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101ce2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce5:	8b 00                	mov    (%eax),%eax
80101ce7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cea:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cee:	89 04 24             	mov    %eax,(%esp)
80101cf1:	e8 b0 e4 ff ff       	call   801001a6 <bread>
80101cf6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cfc:	83 c0 18             	add    $0x18,%eax
80101cff:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d02:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d05:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d0f:	01 d0                	add    %edx,%eax
80101d11:	8b 00                	mov    (%eax),%eax
80101d13:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d16:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d1a:	75 30                	jne    80101d4c <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d1f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d29:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2f:	8b 00                	mov    (%eax),%eax
80101d31:	89 04 24             	mov    %eax,(%esp)
80101d34:	e8 4f f7 ff ff       	call   80101488 <balloc>
80101d39:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d3f:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d44:	89 04 24             	mov    %eax,(%esp)
80101d47:	e8 51 20 00 00       	call   80103d9d <log_write>
    }
    brelse(bp);
80101d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d4f:	89 04 24             	mov    %eax,(%esp)
80101d52:	e8 c0 e4 ff ff       	call   80100217 <brelse>
    return addr;
80101d57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d5a:	eb 0c                	jmp    80101d68 <bmap+0x107>
  }

  panic("bmap: out of range");
80101d5c:	c7 04 24 c8 9c 10 80 	movl   $0x80109cc8,(%esp)
80101d63:	e8 d2 e7 ff ff       	call   8010053a <panic>
}
80101d68:	83 c4 24             	add    $0x24,%esp
80101d6b:	5b                   	pop    %ebx
80101d6c:	5d                   	pop    %ebp
80101d6d:	c3                   	ret    

80101d6e <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d6e:	55                   	push   %ebp
80101d6f:	89 e5                	mov    %esp,%ebp
80101d71:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d7b:	eb 44                	jmp    80101dc1 <itrunc+0x53>
    if(ip->addrs[i]){
80101d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d83:	83 c2 04             	add    $0x4,%edx
80101d86:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d8a:	85 c0                	test   %eax,%eax
80101d8c:	74 2f                	je     80101dbd <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101d8e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d91:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d94:	83 c2 04             	add    $0x4,%edx
80101d97:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101d9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9e:	8b 00                	mov    (%eax),%eax
80101da0:	89 54 24 04          	mov    %edx,0x4(%esp)
80101da4:	89 04 24             	mov    %eax,(%esp)
80101da7:	e8 1a f8 ff ff       	call   801015c6 <bfree>
      ip->addrs[i] = 0;
80101dac:	8b 45 08             	mov    0x8(%ebp),%eax
80101daf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101db2:	83 c2 04             	add    $0x4,%edx
80101db5:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101dbc:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101dbd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101dc1:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101dc5:	7e b6                	jle    80101d7d <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101dc7:	8b 45 08             	mov    0x8(%ebp),%eax
80101dca:	8b 40 4c             	mov    0x4c(%eax),%eax
80101dcd:	85 c0                	test   %eax,%eax
80101dcf:	0f 84 9b 00 00 00    	je     80101e70 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101dd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd8:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dde:	8b 00                	mov    (%eax),%eax
80101de0:	89 54 24 04          	mov    %edx,0x4(%esp)
80101de4:	89 04 24             	mov    %eax,(%esp)
80101de7:	e8 ba e3 ff ff       	call   801001a6 <bread>
80101dec:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101def:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101df2:	83 c0 18             	add    $0x18,%eax
80101df5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101df8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101dff:	eb 3b                	jmp    80101e3c <itrunc+0xce>
      if(a[j])
80101e01:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e04:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e0b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e0e:	01 d0                	add    %edx,%eax
80101e10:	8b 00                	mov    (%eax),%eax
80101e12:	85 c0                	test   %eax,%eax
80101e14:	74 22                	je     80101e38 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101e16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e19:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e20:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e23:	01 d0                	add    %edx,%eax
80101e25:	8b 10                	mov    (%eax),%edx
80101e27:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2a:	8b 00                	mov    (%eax),%eax
80101e2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e30:	89 04 24             	mov    %eax,(%esp)
80101e33:	e8 8e f7 ff ff       	call   801015c6 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e38:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e3f:	83 f8 7f             	cmp    $0x7f,%eax
80101e42:	76 bd                	jbe    80101e01 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e44:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e47:	89 04 24             	mov    %eax,(%esp)
80101e4a:	e8 c8 e3 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e52:	8b 50 4c             	mov    0x4c(%eax),%edx
80101e55:	8b 45 08             	mov    0x8(%ebp),%eax
80101e58:	8b 00                	mov    (%eax),%eax
80101e5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e5e:	89 04 24             	mov    %eax,(%esp)
80101e61:	e8 60 f7 ff ff       	call   801015c6 <bfree>
    ip->addrs[NDIRECT] = 0;
80101e66:	8b 45 08             	mov    0x8(%ebp),%eax
80101e69:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101e70:	8b 45 08             	mov    0x8(%ebp),%eax
80101e73:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101e7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7d:	89 04 24             	mov    %eax,(%esp)
80101e80:	e8 72 f9 ff ff       	call   801017f7 <iupdate>
}
80101e85:	c9                   	leave  
80101e86:	c3                   	ret    

80101e87 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101e87:	55                   	push   %ebp
80101e88:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8d:	8b 00                	mov    (%eax),%eax
80101e8f:	89 c2                	mov    %eax,%edx
80101e91:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e94:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101e97:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9a:	8b 50 04             	mov    0x4(%eax),%edx
80101e9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ea0:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ea3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea6:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101eaa:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ead:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101eb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb3:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101eb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eba:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec1:	8b 50 18             	mov    0x18(%eax),%edx
80101ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec7:	89 50 10             	mov    %edx,0x10(%eax)
}
80101eca:	5d                   	pop    %ebp
80101ecb:	c3                   	ret    

80101ecc <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101ecc:	55                   	push   %ebp
80101ecd:	89 e5                	mov    %esp,%ebp
80101ecf:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ed9:	66 83 f8 03          	cmp    $0x3,%ax
80101edd:	75 60                	jne    80101f3f <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ee6:	66 85 c0             	test   %ax,%ax
80101ee9:	78 20                	js     80101f0b <readi+0x3f>
80101eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80101eee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef2:	66 83 f8 09          	cmp    $0x9,%ax
80101ef6:	7f 13                	jg     80101f0b <readi+0x3f>
80101ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80101efb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eff:	98                   	cwtl   
80101f00:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f07:	85 c0                	test   %eax,%eax
80101f09:	75 0a                	jne    80101f15 <readi+0x49>
      return -1;
80101f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f10:	e9 19 01 00 00       	jmp    8010202e <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101f15:	8b 45 08             	mov    0x8(%ebp),%eax
80101f18:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1c:	98                   	cwtl   
80101f1d:	8b 04 c5 c0 31 11 80 	mov    -0x7feece40(,%eax,8),%eax
80101f24:	8b 55 14             	mov    0x14(%ebp),%edx
80101f27:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f2b:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f32:	8b 55 08             	mov    0x8(%ebp),%edx
80101f35:	89 14 24             	mov    %edx,(%esp)
80101f38:	ff d0                	call   *%eax
80101f3a:	e9 ef 00 00 00       	jmp    8010202e <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101f3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f42:	8b 40 18             	mov    0x18(%eax),%eax
80101f45:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f48:	72 0d                	jb     80101f57 <readi+0x8b>
80101f4a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f4d:	8b 55 10             	mov    0x10(%ebp),%edx
80101f50:	01 d0                	add    %edx,%eax
80101f52:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f55:	73 0a                	jae    80101f61 <readi+0x95>
    return -1;
80101f57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f5c:	e9 cd 00 00 00       	jmp    8010202e <readi+0x162>
  if(off + n > ip->size)
80101f61:	8b 45 14             	mov    0x14(%ebp),%eax
80101f64:	8b 55 10             	mov    0x10(%ebp),%edx
80101f67:	01 c2                	add    %eax,%edx
80101f69:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6c:	8b 40 18             	mov    0x18(%eax),%eax
80101f6f:	39 c2                	cmp    %eax,%edx
80101f71:	76 0c                	jbe    80101f7f <readi+0xb3>
    n = ip->size - off;
80101f73:	8b 45 08             	mov    0x8(%ebp),%eax
80101f76:	8b 40 18             	mov    0x18(%eax),%eax
80101f79:	2b 45 10             	sub    0x10(%ebp),%eax
80101f7c:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f7f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f86:	e9 94 00 00 00       	jmp    8010201f <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f8b:	8b 45 10             	mov    0x10(%ebp),%eax
80101f8e:	c1 e8 09             	shr    $0x9,%eax
80101f91:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f95:	8b 45 08             	mov    0x8(%ebp),%eax
80101f98:	89 04 24             	mov    %eax,(%esp)
80101f9b:	e8 c1 fc ff ff       	call   80101c61 <bmap>
80101fa0:	8b 55 08             	mov    0x8(%ebp),%edx
80101fa3:	8b 12                	mov    (%edx),%edx
80101fa5:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fa9:	89 14 24             	mov    %edx,(%esp)
80101fac:	e8 f5 e1 ff ff       	call   801001a6 <bread>
80101fb1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fb4:	8b 45 10             	mov    0x10(%ebp),%eax
80101fb7:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fbc:	89 c2                	mov    %eax,%edx
80101fbe:	b8 00 02 00 00       	mov    $0x200,%eax
80101fc3:	29 d0                	sub    %edx,%eax
80101fc5:	89 c2                	mov    %eax,%edx
80101fc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fca:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fcd:	29 c1                	sub    %eax,%ecx
80101fcf:	89 c8                	mov    %ecx,%eax
80101fd1:	39 c2                	cmp    %eax,%edx
80101fd3:	0f 46 c2             	cmovbe %edx,%eax
80101fd6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101fd9:	8b 45 10             	mov    0x10(%ebp),%eax
80101fdc:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fe1:	8d 50 10             	lea    0x10(%eax),%edx
80101fe4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fe7:	01 d0                	add    %edx,%eax
80101fe9:	8d 50 08             	lea    0x8(%eax),%edx
80101fec:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fef:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ff3:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ff7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ffa:	89 04 24             	mov    %eax,(%esp)
80101ffd:	e8 8f 3a 00 00       	call   80105a91 <memmove>
    brelse(bp);
80102002:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102005:	89 04 24             	mov    %eax,(%esp)
80102008:	e8 0a e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010200d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102010:	01 45 f4             	add    %eax,-0xc(%ebp)
80102013:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102016:	01 45 10             	add    %eax,0x10(%ebp)
80102019:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010201c:	01 45 0c             	add    %eax,0xc(%ebp)
8010201f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102022:	3b 45 14             	cmp    0x14(%ebp),%eax
80102025:	0f 82 60 ff ff ff    	jb     80101f8b <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010202b:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010202e:	c9                   	leave  
8010202f:	c3                   	ret    

80102030 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102030:	55                   	push   %ebp
80102031:	89 e5                	mov    %esp,%ebp
80102033:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102036:	8b 45 08             	mov    0x8(%ebp),%eax
80102039:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010203d:	66 83 f8 03          	cmp    $0x3,%ax
80102041:	75 60                	jne    801020a3 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102043:	8b 45 08             	mov    0x8(%ebp),%eax
80102046:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010204a:	66 85 c0             	test   %ax,%ax
8010204d:	78 20                	js     8010206f <writei+0x3f>
8010204f:	8b 45 08             	mov    0x8(%ebp),%eax
80102052:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102056:	66 83 f8 09          	cmp    $0x9,%ax
8010205a:	7f 13                	jg     8010206f <writei+0x3f>
8010205c:	8b 45 08             	mov    0x8(%ebp),%eax
8010205f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102063:	98                   	cwtl   
80102064:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
8010206b:	85 c0                	test   %eax,%eax
8010206d:	75 0a                	jne    80102079 <writei+0x49>
      return -1;
8010206f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102074:	e9 44 01 00 00       	jmp    801021bd <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80102079:	8b 45 08             	mov    0x8(%ebp),%eax
8010207c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102080:	98                   	cwtl   
80102081:	8b 04 c5 c4 31 11 80 	mov    -0x7feece3c(,%eax,8),%eax
80102088:	8b 55 14             	mov    0x14(%ebp),%edx
8010208b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010208f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102092:	89 54 24 04          	mov    %edx,0x4(%esp)
80102096:	8b 55 08             	mov    0x8(%ebp),%edx
80102099:	89 14 24             	mov    %edx,(%esp)
8010209c:	ff d0                	call   *%eax
8010209e:	e9 1a 01 00 00       	jmp    801021bd <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801020a3:	8b 45 08             	mov    0x8(%ebp),%eax
801020a6:	8b 40 18             	mov    0x18(%eax),%eax
801020a9:	3b 45 10             	cmp    0x10(%ebp),%eax
801020ac:	72 0d                	jb     801020bb <writei+0x8b>
801020ae:	8b 45 14             	mov    0x14(%ebp),%eax
801020b1:	8b 55 10             	mov    0x10(%ebp),%edx
801020b4:	01 d0                	add    %edx,%eax
801020b6:	3b 45 10             	cmp    0x10(%ebp),%eax
801020b9:	73 0a                	jae    801020c5 <writei+0x95>
    return -1;
801020bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020c0:	e9 f8 00 00 00       	jmp    801021bd <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
801020c5:	8b 45 14             	mov    0x14(%ebp),%eax
801020c8:	8b 55 10             	mov    0x10(%ebp),%edx
801020cb:	01 d0                	add    %edx,%eax
801020cd:	3d 00 18 01 00       	cmp    $0x11800,%eax
801020d2:	76 0a                	jbe    801020de <writei+0xae>
    return -1;
801020d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020d9:	e9 df 00 00 00       	jmp    801021bd <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020de:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020e5:	e9 9f 00 00 00       	jmp    80102189 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801020ea:	8b 45 10             	mov    0x10(%ebp),%eax
801020ed:	c1 e8 09             	shr    $0x9,%eax
801020f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801020f4:	8b 45 08             	mov    0x8(%ebp),%eax
801020f7:	89 04 24             	mov    %eax,(%esp)
801020fa:	e8 62 fb ff ff       	call   80101c61 <bmap>
801020ff:	8b 55 08             	mov    0x8(%ebp),%edx
80102102:	8b 12                	mov    (%edx),%edx
80102104:	89 44 24 04          	mov    %eax,0x4(%esp)
80102108:	89 14 24             	mov    %edx,(%esp)
8010210b:	e8 96 e0 ff ff       	call   801001a6 <bread>
80102110:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102113:	8b 45 10             	mov    0x10(%ebp),%eax
80102116:	25 ff 01 00 00       	and    $0x1ff,%eax
8010211b:	89 c2                	mov    %eax,%edx
8010211d:	b8 00 02 00 00       	mov    $0x200,%eax
80102122:	29 d0                	sub    %edx,%eax
80102124:	89 c2                	mov    %eax,%edx
80102126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102129:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010212c:	29 c1                	sub    %eax,%ecx
8010212e:	89 c8                	mov    %ecx,%eax
80102130:	39 c2                	cmp    %eax,%edx
80102132:	0f 46 c2             	cmovbe %edx,%eax
80102135:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102138:	8b 45 10             	mov    0x10(%ebp),%eax
8010213b:	25 ff 01 00 00       	and    $0x1ff,%eax
80102140:	8d 50 10             	lea    0x10(%eax),%edx
80102143:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102146:	01 d0                	add    %edx,%eax
80102148:	8d 50 08             	lea    0x8(%eax),%edx
8010214b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010214e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102152:	8b 45 0c             	mov    0xc(%ebp),%eax
80102155:	89 44 24 04          	mov    %eax,0x4(%esp)
80102159:	89 14 24             	mov    %edx,(%esp)
8010215c:	e8 30 39 00 00       	call   80105a91 <memmove>
    log_write(bp);
80102161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102164:	89 04 24             	mov    %eax,(%esp)
80102167:	e8 31 1c 00 00       	call   80103d9d <log_write>
    brelse(bp);
8010216c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010216f:	89 04 24             	mov    %eax,(%esp)
80102172:	e8 a0 e0 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102177:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010217a:	01 45 f4             	add    %eax,-0xc(%ebp)
8010217d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102180:	01 45 10             	add    %eax,0x10(%ebp)
80102183:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102186:	01 45 0c             	add    %eax,0xc(%ebp)
80102189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010218c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010218f:	0f 82 55 ff ff ff    	jb     801020ea <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102195:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102199:	74 1f                	je     801021ba <writei+0x18a>
8010219b:	8b 45 08             	mov    0x8(%ebp),%eax
8010219e:	8b 40 18             	mov    0x18(%eax),%eax
801021a1:	3b 45 10             	cmp    0x10(%ebp),%eax
801021a4:	73 14                	jae    801021ba <writei+0x18a>
    ip->size = off;
801021a6:	8b 45 08             	mov    0x8(%ebp),%eax
801021a9:	8b 55 10             	mov    0x10(%ebp),%edx
801021ac:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801021af:	8b 45 08             	mov    0x8(%ebp),%eax
801021b2:	89 04 24             	mov    %eax,(%esp)
801021b5:	e8 3d f6 ff ff       	call   801017f7 <iupdate>
  }
  return n;
801021ba:	8b 45 14             	mov    0x14(%ebp),%eax
}
801021bd:	c9                   	leave  
801021be:	c3                   	ret    

801021bf <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801021bf:	55                   	push   %ebp
801021c0:	89 e5                	mov    %esp,%ebp
801021c2:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801021c5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021cc:	00 
801021cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801021d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801021d4:	8b 45 08             	mov    0x8(%ebp),%eax
801021d7:	89 04 24             	mov    %eax,(%esp)
801021da:	e8 55 39 00 00       	call   80105b34 <strncmp>
}
801021df:	c9                   	leave  
801021e0:	c3                   	ret    

801021e1 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801021e1:	55                   	push   %ebp
801021e2:	89 e5                	mov    %esp,%ebp
801021e4:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801021e7:	8b 45 08             	mov    0x8(%ebp),%eax
801021ea:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021ee:	66 83 f8 01          	cmp    $0x1,%ax
801021f2:	74 0c                	je     80102200 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801021f4:	c7 04 24 db 9c 10 80 	movl   $0x80109cdb,(%esp)
801021fb:	e8 3a e3 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102200:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102207:	e9 88 00 00 00       	jmp    80102294 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010220c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102213:	00 
80102214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102217:	89 44 24 08          	mov    %eax,0x8(%esp)
8010221b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010221e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102222:	8b 45 08             	mov    0x8(%ebp),%eax
80102225:	89 04 24             	mov    %eax,(%esp)
80102228:	e8 9f fc ff ff       	call   80101ecc <readi>
8010222d:	83 f8 10             	cmp    $0x10,%eax
80102230:	74 0c                	je     8010223e <dirlookup+0x5d>
      panic("dirlink read");
80102232:	c7 04 24 ed 9c 10 80 	movl   $0x80109ced,(%esp)
80102239:	e8 fc e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010223e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102242:	66 85 c0             	test   %ax,%ax
80102245:	75 02                	jne    80102249 <dirlookup+0x68>
      continue;
80102247:	eb 47                	jmp    80102290 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
80102249:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010224c:	83 c0 02             	add    $0x2,%eax
8010224f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102253:	8b 45 0c             	mov    0xc(%ebp),%eax
80102256:	89 04 24             	mov    %eax,(%esp)
80102259:	e8 61 ff ff ff       	call   801021bf <namecmp>
8010225e:	85 c0                	test   %eax,%eax
80102260:	75 2e                	jne    80102290 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
80102262:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102266:	74 08                	je     80102270 <dirlookup+0x8f>
        *poff = off;
80102268:	8b 45 10             	mov    0x10(%ebp),%eax
8010226b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010226e:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102270:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102274:	0f b7 c0             	movzwl %ax,%eax
80102277:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
8010227a:	8b 45 08             	mov    0x8(%ebp),%eax
8010227d:	8b 00                	mov    (%eax),%eax
8010227f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102282:	89 54 24 04          	mov    %edx,0x4(%esp)
80102286:	89 04 24             	mov    %eax,(%esp)
80102289:	e8 27 f6 ff ff       	call   801018b5 <iget>
8010228e:	eb 18                	jmp    801022a8 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102290:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102294:	8b 45 08             	mov    0x8(%ebp),%eax
80102297:	8b 40 18             	mov    0x18(%eax),%eax
8010229a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010229d:	0f 87 69 ff ff ff    	ja     8010220c <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801022a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022a8:	c9                   	leave  
801022a9:	c3                   	ret    

801022aa <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022aa:	55                   	push   %ebp
801022ab:	89 e5                	mov    %esp,%ebp
801022ad:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801022b0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801022b7:	00 
801022b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801022bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801022bf:	8b 45 08             	mov    0x8(%ebp),%eax
801022c2:	89 04 24             	mov    %eax,(%esp)
801022c5:	e8 17 ff ff ff       	call   801021e1 <dirlookup>
801022ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022cd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022d1:	74 15                	je     801022e8 <dirlink+0x3e>
    iput(ip);
801022d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022d6:	89 04 24             	mov    %eax,(%esp)
801022d9:	e8 94 f8 ff ff       	call   80101b72 <iput>
    return -1;
801022de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022e3:	e9 b7 00 00 00       	jmp    8010239f <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022ef:	eb 46                	jmp    80102337 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022f4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022fb:	00 
801022fc:	89 44 24 08          	mov    %eax,0x8(%esp)
80102300:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102303:	89 44 24 04          	mov    %eax,0x4(%esp)
80102307:	8b 45 08             	mov    0x8(%ebp),%eax
8010230a:	89 04 24             	mov    %eax,(%esp)
8010230d:	e8 ba fb ff ff       	call   80101ecc <readi>
80102312:	83 f8 10             	cmp    $0x10,%eax
80102315:	74 0c                	je     80102323 <dirlink+0x79>
      panic("dirlink read");
80102317:	c7 04 24 ed 9c 10 80 	movl   $0x80109ced,(%esp)
8010231e:	e8 17 e2 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102323:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102327:	66 85 c0             	test   %ax,%ax
8010232a:	75 02                	jne    8010232e <dirlink+0x84>
      break;
8010232c:	eb 16                	jmp    80102344 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010232e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102331:	83 c0 10             	add    $0x10,%eax
80102334:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102337:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010233a:	8b 45 08             	mov    0x8(%ebp),%eax
8010233d:	8b 40 18             	mov    0x18(%eax),%eax
80102340:	39 c2                	cmp    %eax,%edx
80102342:	72 ad                	jb     801022f1 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102344:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010234b:	00 
8010234c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010234f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102353:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102356:	83 c0 02             	add    $0x2,%eax
80102359:	89 04 24             	mov    %eax,(%esp)
8010235c:	e8 29 38 00 00       	call   80105b8a <strncpy>
  de.inum = inum;
80102361:	8b 45 10             	mov    0x10(%ebp),%eax
80102364:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102368:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010236b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102372:	00 
80102373:	89 44 24 08          	mov    %eax,0x8(%esp)
80102377:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010237a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010237e:	8b 45 08             	mov    0x8(%ebp),%eax
80102381:	89 04 24             	mov    %eax,(%esp)
80102384:	e8 a7 fc ff ff       	call   80102030 <writei>
80102389:	83 f8 10             	cmp    $0x10,%eax
8010238c:	74 0c                	je     8010239a <dirlink+0xf0>
    panic("dirlink");
8010238e:	c7 04 24 fa 9c 10 80 	movl   $0x80109cfa,(%esp)
80102395:	e8 a0 e1 ff ff       	call   8010053a <panic>
  
  return 0;
8010239a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010239f:	c9                   	leave  
801023a0:	c3                   	ret    

801023a1 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801023a1:	55                   	push   %ebp
801023a2:	89 e5                	mov    %esp,%ebp
801023a4:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801023a7:	eb 04                	jmp    801023ad <skipelem+0xc>
    path++;
801023a9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801023ad:	8b 45 08             	mov    0x8(%ebp),%eax
801023b0:	0f b6 00             	movzbl (%eax),%eax
801023b3:	3c 2f                	cmp    $0x2f,%al
801023b5:	74 f2                	je     801023a9 <skipelem+0x8>
    path++;
  if(*path == 0)
801023b7:	8b 45 08             	mov    0x8(%ebp),%eax
801023ba:	0f b6 00             	movzbl (%eax),%eax
801023bd:	84 c0                	test   %al,%al
801023bf:	75 0a                	jne    801023cb <skipelem+0x2a>
    return 0;
801023c1:	b8 00 00 00 00       	mov    $0x0,%eax
801023c6:	e9 86 00 00 00       	jmp    80102451 <skipelem+0xb0>
  s = path;
801023cb:	8b 45 08             	mov    0x8(%ebp),%eax
801023ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023d1:	eb 04                	jmp    801023d7 <skipelem+0x36>
    path++;
801023d3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801023d7:	8b 45 08             	mov    0x8(%ebp),%eax
801023da:	0f b6 00             	movzbl (%eax),%eax
801023dd:	3c 2f                	cmp    $0x2f,%al
801023df:	74 0a                	je     801023eb <skipelem+0x4a>
801023e1:	8b 45 08             	mov    0x8(%ebp),%eax
801023e4:	0f b6 00             	movzbl (%eax),%eax
801023e7:	84 c0                	test   %al,%al
801023e9:	75 e8                	jne    801023d3 <skipelem+0x32>
    path++;
  len = path - s;
801023eb:	8b 55 08             	mov    0x8(%ebp),%edx
801023ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f1:	29 c2                	sub    %eax,%edx
801023f3:	89 d0                	mov    %edx,%eax
801023f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023f8:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023fc:	7e 1c                	jle    8010241a <skipelem+0x79>
    memmove(name, s, DIRSIZ);
801023fe:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102405:	00 
80102406:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102409:	89 44 24 04          	mov    %eax,0x4(%esp)
8010240d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102410:	89 04 24             	mov    %eax,(%esp)
80102413:	e8 79 36 00 00       	call   80105a91 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102418:	eb 2a                	jmp    80102444 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010241a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010241d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102421:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102424:	89 44 24 04          	mov    %eax,0x4(%esp)
80102428:	8b 45 0c             	mov    0xc(%ebp),%eax
8010242b:	89 04 24             	mov    %eax,(%esp)
8010242e:	e8 5e 36 00 00       	call   80105a91 <memmove>
    name[len] = 0;
80102433:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102436:	8b 45 0c             	mov    0xc(%ebp),%eax
80102439:	01 d0                	add    %edx,%eax
8010243b:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010243e:	eb 04                	jmp    80102444 <skipelem+0xa3>
    path++;
80102440:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102444:	8b 45 08             	mov    0x8(%ebp),%eax
80102447:	0f b6 00             	movzbl (%eax),%eax
8010244a:	3c 2f                	cmp    $0x2f,%al
8010244c:	74 f2                	je     80102440 <skipelem+0x9f>
    path++;
  return path;
8010244e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102451:	c9                   	leave  
80102452:	c3                   	ret    

80102453 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102453:	55                   	push   %ebp
80102454:	89 e5                	mov    %esp,%ebp
80102456:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102459:	8b 45 08             	mov    0x8(%ebp),%eax
8010245c:	0f b6 00             	movzbl (%eax),%eax
8010245f:	3c 2f                	cmp    $0x2f,%al
80102461:	75 1c                	jne    8010247f <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102463:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010246a:	00 
8010246b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102472:	e8 3e f4 ff ff       	call   801018b5 <iget>
80102477:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010247a:	e9 af 00 00 00       	jmp    8010252e <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010247f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102485:	8b 40 68             	mov    0x68(%eax),%eax
80102488:	89 04 24             	mov    %eax,(%esp)
8010248b:	e8 f7 f4 ff ff       	call   80101987 <idup>
80102490:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102493:	e9 96 00 00 00       	jmp    8010252e <namex+0xdb>
    ilock(ip);
80102498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010249b:	89 04 24             	mov    %eax,(%esp)
8010249e:	e8 16 f5 ff ff       	call   801019b9 <ilock>
    if(ip->type != T_DIR){
801024a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024a6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801024aa:	66 83 f8 01          	cmp    $0x1,%ax
801024ae:	74 15                	je     801024c5 <namex+0x72>
      iunlockput(ip);
801024b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024b3:	89 04 24             	mov    %eax,(%esp)
801024b6:	e8 88 f7 ff ff       	call   80101c43 <iunlockput>
      return 0;
801024bb:	b8 00 00 00 00       	mov    $0x0,%eax
801024c0:	e9 a3 00 00 00       	jmp    80102568 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801024c5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024c9:	74 1d                	je     801024e8 <namex+0x95>
801024cb:	8b 45 08             	mov    0x8(%ebp),%eax
801024ce:	0f b6 00             	movzbl (%eax),%eax
801024d1:	84 c0                	test   %al,%al
801024d3:	75 13                	jne    801024e8 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801024d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024d8:	89 04 24             	mov    %eax,(%esp)
801024db:	e8 2d f6 ff ff       	call   80101b0d <iunlock>
      return ip;
801024e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024e3:	e9 80 00 00 00       	jmp    80102568 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801024ef:	00 
801024f0:	8b 45 10             	mov    0x10(%ebp),%eax
801024f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801024f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024fa:	89 04 24             	mov    %eax,(%esp)
801024fd:	e8 df fc ff ff       	call   801021e1 <dirlookup>
80102502:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102505:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102509:	75 12                	jne    8010251d <namex+0xca>
      iunlockput(ip);
8010250b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010250e:	89 04 24             	mov    %eax,(%esp)
80102511:	e8 2d f7 ff ff       	call   80101c43 <iunlockput>
      return 0;
80102516:	b8 00 00 00 00       	mov    $0x0,%eax
8010251b:	eb 4b                	jmp    80102568 <namex+0x115>
    }
    iunlockput(ip);
8010251d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102520:	89 04 24             	mov    %eax,(%esp)
80102523:	e8 1b f7 ff ff       	call   80101c43 <iunlockput>
    ip = next;
80102528:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010252b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010252e:	8b 45 10             	mov    0x10(%ebp),%eax
80102531:	89 44 24 04          	mov    %eax,0x4(%esp)
80102535:	8b 45 08             	mov    0x8(%ebp),%eax
80102538:	89 04 24             	mov    %eax,(%esp)
8010253b:	e8 61 fe ff ff       	call   801023a1 <skipelem>
80102540:	89 45 08             	mov    %eax,0x8(%ebp)
80102543:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102547:	0f 85 4b ff ff ff    	jne    80102498 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010254d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102551:	74 12                	je     80102565 <namex+0x112>
    iput(ip);
80102553:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102556:	89 04 24             	mov    %eax,(%esp)
80102559:	e8 14 f6 ff ff       	call   80101b72 <iput>
    return 0;
8010255e:	b8 00 00 00 00       	mov    $0x0,%eax
80102563:	eb 03                	jmp    80102568 <namex+0x115>
  }
  return ip;
80102565:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102568:	c9                   	leave  
80102569:	c3                   	ret    

8010256a <namei>:

struct inode*
namei(char *path)
{
8010256a:	55                   	push   %ebp
8010256b:	89 e5                	mov    %esp,%ebp
8010256d:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102570:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102573:	89 44 24 08          	mov    %eax,0x8(%esp)
80102577:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010257e:	00 
8010257f:	8b 45 08             	mov    0x8(%ebp),%eax
80102582:	89 04 24             	mov    %eax,(%esp)
80102585:	e8 c9 fe ff ff       	call   80102453 <namex>
}
8010258a:	c9                   	leave  
8010258b:	c3                   	ret    

8010258c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010258c:	55                   	push   %ebp
8010258d:	89 e5                	mov    %esp,%ebp
8010258f:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102592:	8b 45 0c             	mov    0xc(%ebp),%eax
80102595:	89 44 24 08          	mov    %eax,0x8(%esp)
80102599:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801025a0:	00 
801025a1:	8b 45 08             	mov    0x8(%ebp),%eax
801025a4:	89 04 24             	mov    %eax,(%esp)
801025a7:	e8 a7 fe ff ff       	call   80102453 <namex>
}
801025ac:	c9                   	leave  
801025ad:	c3                   	ret    

801025ae <itoa>:

#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
801025ae:	55                   	push   %ebp
801025af:	89 e5                	mov    %esp,%ebp
801025b1:	83 ec 20             	sub    $0x20,%esp
    char const digit[] = "0123456789";
801025b4:	c7 45 ed 30 31 32 33 	movl   $0x33323130,-0x13(%ebp)
801025bb:	c7 45 f1 34 35 36 37 	movl   $0x37363534,-0xf(%ebp)
801025c2:	66 c7 45 f5 38 39    	movw   $0x3938,-0xb(%ebp)
801025c8:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
    char* p = b;
801025cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801025cf:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if(i<0){
801025d2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025d6:	79 0f                	jns    801025e7 <itoa+0x39>
        *p++ = '-';
801025d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801025db:	8d 50 01             	lea    0x1(%eax),%edx
801025de:	89 55 fc             	mov    %edx,-0x4(%ebp)
801025e1:	c6 00 2d             	movb   $0x2d,(%eax)
        i *= -1;
801025e4:	f7 5d 08             	negl   0x8(%ebp)
    }
    int shifter = i;
801025e7:	8b 45 08             	mov    0x8(%ebp),%eax
801025ea:	89 45 f8             	mov    %eax,-0x8(%ebp)
    do{ //Move to where representation ends
        ++p;
801025ed:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
        shifter = shifter/10;
801025f1:	8b 4d f8             	mov    -0x8(%ebp),%ecx
801025f4:	ba 67 66 66 66       	mov    $0x66666667,%edx
801025f9:	89 c8                	mov    %ecx,%eax
801025fb:	f7 ea                	imul   %edx
801025fd:	c1 fa 02             	sar    $0x2,%edx
80102600:	89 c8                	mov    %ecx,%eax
80102602:	c1 f8 1f             	sar    $0x1f,%eax
80102605:	29 c2                	sub    %eax,%edx
80102607:	89 d0                	mov    %edx,%eax
80102609:	89 45 f8             	mov    %eax,-0x8(%ebp)
    }while(shifter);
8010260c:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
80102610:	75 db                	jne    801025ed <itoa+0x3f>
    *p = '\0';
80102612:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102615:	c6 00 00             	movb   $0x0,(%eax)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
80102618:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010261c:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010261f:	ba 67 66 66 66       	mov    $0x66666667,%edx
80102624:	89 c8                	mov    %ecx,%eax
80102626:	f7 ea                	imul   %edx
80102628:	c1 fa 02             	sar    $0x2,%edx
8010262b:	89 c8                	mov    %ecx,%eax
8010262d:	c1 f8 1f             	sar    $0x1f,%eax
80102630:	29 c2                	sub    %eax,%edx
80102632:	89 d0                	mov    %edx,%eax
80102634:	c1 e0 02             	shl    $0x2,%eax
80102637:	01 d0                	add    %edx,%eax
80102639:	01 c0                	add    %eax,%eax
8010263b:	29 c1                	sub    %eax,%ecx
8010263d:	89 ca                	mov    %ecx,%edx
8010263f:	0f b6 54 15 ed       	movzbl -0x13(%ebp,%edx,1),%edx
80102644:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102647:	88 10                	mov    %dl,(%eax)
        i = i/10;
80102649:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010264c:	ba 67 66 66 66       	mov    $0x66666667,%edx
80102651:	89 c8                	mov    %ecx,%eax
80102653:	f7 ea                	imul   %edx
80102655:	c1 fa 02             	sar    $0x2,%edx
80102658:	89 c8                	mov    %ecx,%eax
8010265a:	c1 f8 1f             	sar    $0x1f,%eax
8010265d:	29 c2                	sub    %eax,%edx
8010265f:	89 d0                	mov    %edx,%eax
80102661:	89 45 08             	mov    %eax,0x8(%ebp)
    }while(i);
80102664:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102668:	75 ae                	jne    80102618 <itoa+0x6a>
    return b;
8010266a:	8b 45 0c             	mov    0xc(%ebp),%eax
}
8010266d:	c9                   	leave  
8010266e:	c3                   	ret    

8010266f <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
8010266f:	55                   	push   %ebp
80102670:	89 e5                	mov    %esp,%ebp
80102672:	83 ec 58             	sub    $0x58,%esp
	//path of proccess
	char path[DIGITS];
	memmove(path,"/.swap", 6);
80102675:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
8010267c:	00 
8010267d:	c7 44 24 04 02 9d 10 	movl   $0x80109d02,0x4(%esp)
80102684:	80 
80102685:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80102688:	89 04 24             	mov    %eax,(%esp)
8010268b:	e8 01 34 00 00       	call   80105a91 <memmove>
	itoa(p->pid, path+ 6);
80102690:	8b 45 08             	mov    0x8(%ebp),%eax
80102693:	8b 40 10             	mov    0x10(%eax),%eax
80102696:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80102699:	83 c2 06             	add    $0x6,%edx
8010269c:	89 54 24 04          	mov    %edx,0x4(%esp)
801026a0:	89 04 24             	mov    %eax,(%esp)
801026a3:	e8 06 ff ff ff       	call   801025ae <itoa>

	struct inode *ip, *dp;
	struct dirent de;
	char name[DIRSIZ];
	uint off;
  if(0 == p->swapFile){
801026a8:	8b 45 08             	mov    0x8(%ebp),%eax
801026ab:	8b 40 7c             	mov    0x7c(%eax),%eax
801026ae:	85 c0                	test   %eax,%eax
801026b0:	75 0a                	jne    801026bc <removeSwapFile+0x4d>
    return -1;
801026b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801026b7:	e9 bd 01 00 00       	jmp    80102879 <removeSwapFile+0x20a>
  }
  fileclose(p->swapFile);
801026bc:	8b 45 08             	mov    0x8(%ebp),%eax
801026bf:	8b 40 7c             	mov    0x7c(%eax),%eax
801026c2:	89 04 24             	mov    %eax,(%esp)
801026c5:	e8 04 ea ff ff       	call   801010ce <fileclose>

	begin_op();
801026ca:	e8 c3 14 00 00       	call   80103b92 <begin_op>
	if((dp = nameiparent(path, name)) == 0)
801026cf:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801026d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801026d6:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801026d9:	89 04 24             	mov    %eax,(%esp)
801026dc:	e8 ab fe ff ff       	call   8010258c <nameiparent>
801026e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026e8:	75 0f                	jne    801026f9 <removeSwapFile+0x8a>
	{
		end_op();
801026ea:	e8 27 15 00 00       	call   80103c16 <end_op>
		return -1;
801026ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801026f4:	e9 80 01 00 00       	jmp    80102879 <removeSwapFile+0x20a>
	}

	ilock(dp);
801026f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026fc:	89 04 24             	mov    %eax,(%esp)
801026ff:	e8 b5 f2 ff ff       	call   801019b9 <ilock>

	  // Cannot unlink "." or "..".
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80102704:	c7 44 24 04 09 9d 10 	movl   $0x80109d09,0x4(%esp)
8010270b:	80 
8010270c:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010270f:	89 04 24             	mov    %eax,(%esp)
80102712:	e8 a8 fa ff ff       	call   801021bf <namecmp>
80102717:	85 c0                	test   %eax,%eax
80102719:	0f 84 45 01 00 00    	je     80102864 <removeSwapFile+0x1f5>
8010271f:	c7 44 24 04 0b 9d 10 	movl   $0x80109d0b,0x4(%esp)
80102726:	80 
80102727:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010272a:	89 04 24             	mov    %eax,(%esp)
8010272d:	e8 8d fa ff ff       	call   801021bf <namecmp>
80102732:	85 c0                	test   %eax,%eax
80102734:	0f 84 2a 01 00 00    	je     80102864 <removeSwapFile+0x1f5>
	   goto bad;

	if((ip = dirlookup(dp, name, &off)) == 0)
8010273a:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010273d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102741:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80102744:	89 44 24 04          	mov    %eax,0x4(%esp)
80102748:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010274b:	89 04 24             	mov    %eax,(%esp)
8010274e:	e8 8e fa ff ff       	call   801021e1 <dirlookup>
80102753:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102756:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010275a:	75 05                	jne    80102761 <removeSwapFile+0xf2>
		goto bad;
8010275c:	e9 03 01 00 00       	jmp    80102864 <removeSwapFile+0x1f5>
	ilock(ip);
80102761:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102764:	89 04 24             	mov    %eax,(%esp)
80102767:	e8 4d f2 ff ff       	call   801019b9 <ilock>

	if(ip->nlink < 1)
8010276c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010276f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102773:	66 85 c0             	test   %ax,%ax
80102776:	7f 0c                	jg     80102784 <removeSwapFile+0x115>
		panic("unlink: nlink < 1");
80102778:	c7 04 24 0e 9d 10 80 	movl   $0x80109d0e,(%esp)
8010277f:	e8 b6 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
80102784:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102787:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010278b:	66 83 f8 01          	cmp    $0x1,%ax
8010278f:	75 1f                	jne    801027b0 <removeSwapFile+0x141>
80102791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102794:	89 04 24             	mov    %eax,(%esp)
80102797:	e8 00 3b 00 00       	call   8010629c <isdirempty>
8010279c:	85 c0                	test   %eax,%eax
8010279e:	75 10                	jne    801027b0 <removeSwapFile+0x141>
		iunlockput(ip);
801027a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027a3:	89 04 24             	mov    %eax,(%esp)
801027a6:	e8 98 f4 ff ff       	call   80101c43 <iunlockput>
		goto bad;
801027ab:	e9 b4 00 00 00       	jmp    80102864 <removeSwapFile+0x1f5>
	}

	memset(&de, 0, sizeof(de));
801027b0:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801027b7:	00 
801027b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801027bf:	00 
801027c0:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801027c3:	89 04 24             	mov    %eax,(%esp)
801027c6:	e8 f7 31 00 00       	call   801059c2 <memset>
	if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801027cb:	8b 45 c0             	mov    -0x40(%ebp),%eax
801027ce:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801027d5:	00 
801027d6:	89 44 24 08          	mov    %eax,0x8(%esp)
801027da:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801027dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801027e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027e4:	89 04 24             	mov    %eax,(%esp)
801027e7:	e8 44 f8 ff ff       	call   80102030 <writei>
801027ec:	83 f8 10             	cmp    $0x10,%eax
801027ef:	74 0c                	je     801027fd <removeSwapFile+0x18e>
		panic("unlink: writei");
801027f1:	c7 04 24 20 9d 10 80 	movl   $0x80109d20,(%esp)
801027f8:	e8 3d dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR){
801027fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102800:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102804:	66 83 f8 01          	cmp    $0x1,%ax
80102808:	75 1c                	jne    80102826 <removeSwapFile+0x1b7>
		dp->nlink--;
8010280a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010280d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102811:	8d 50 ff             	lea    -0x1(%eax),%edx
80102814:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102817:	66 89 50 16          	mov    %dx,0x16(%eax)
		iupdate(dp);
8010281b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010281e:	89 04 24             	mov    %eax,(%esp)
80102821:	e8 d1 ef ff ff       	call   801017f7 <iupdate>
	}
	iunlockput(dp);
80102826:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102829:	89 04 24             	mov    %eax,(%esp)
8010282c:	e8 12 f4 ff ff       	call   80101c43 <iunlockput>

	ip->nlink--;
80102831:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102834:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102838:	8d 50 ff             	lea    -0x1(%eax),%edx
8010283b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010283e:	66 89 50 16          	mov    %dx,0x16(%eax)
	iupdate(ip);
80102842:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102845:	89 04 24             	mov    %eax,(%esp)
80102848:	e8 aa ef ff ff       	call   801017f7 <iupdate>
	iunlockput(ip);
8010284d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102850:	89 04 24             	mov    %eax,(%esp)
80102853:	e8 eb f3 ff ff       	call   80101c43 <iunlockput>

	end_op();
80102858:	e8 b9 13 00 00       	call   80103c16 <end_op>

	return 0;
8010285d:	b8 00 00 00 00       	mov    $0x0,%eax
80102862:	eb 15                	jmp    80102879 <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
80102864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102867:	89 04 24             	mov    %eax,(%esp)
8010286a:	e8 d4 f3 ff ff       	call   80101c43 <iunlockput>
		end_op();
8010286f:	e8 a2 13 00 00       	call   80103c16 <end_op>
		return -1;
80102874:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

}
80102879:	c9                   	leave  
8010287a:	c3                   	ret    

8010287b <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
8010287b:	55                   	push   %ebp
8010287c:	89 e5                	mov    %esp,%ebp
8010287e:	83 ec 38             	sub    $0x38,%esp

	char path[DIGITS];
	memmove(path,"/.swap", 6);
80102881:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
80102888:	00 
80102889:	c7 44 24 04 02 9d 10 	movl   $0x80109d02,0x4(%esp)
80102890:	80 
80102891:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102894:	89 04 24             	mov    %eax,(%esp)
80102897:	e8 f5 31 00 00       	call   80105a91 <memmove>
	itoa(p->pid, path+ 6);
8010289c:	8b 45 08             	mov    0x8(%ebp),%eax
8010289f:	8b 40 10             	mov    0x10(%eax),%eax
801028a2:	8d 55 e6             	lea    -0x1a(%ebp),%edx
801028a5:	83 c2 06             	add    $0x6,%edx
801028a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801028ac:	89 04 24             	mov    %eax,(%esp)
801028af:	e8 fa fc ff ff       	call   801025ae <itoa>

    begin_op();
801028b4:	e8 d9 12 00 00       	call   80103b92 <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
801028b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801028c0:	00 
801028c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801028c8:	00 
801028c9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801028d0:	00 
801028d1:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028d4:	89 04 24             	mov    %eax,(%esp)
801028d7:	e8 06 3c 00 00       	call   801064e2 <create>
801028dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	iunlock(in);
801028df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028e2:	89 04 24             	mov    %eax,(%esp)
801028e5:	e8 23 f2 ff ff       	call   80101b0d <iunlock>

	p->swapFile = filealloc();
801028ea:	e8 37 e7 ff ff       	call   80101026 <filealloc>
801028ef:	8b 55 08             	mov    0x8(%ebp),%edx
801028f2:	89 42 7c             	mov    %eax,0x7c(%edx)
	if (p->swapFile == 0)
801028f5:	8b 45 08             	mov    0x8(%ebp),%eax
801028f8:	8b 40 7c             	mov    0x7c(%eax),%eax
801028fb:	85 c0                	test   %eax,%eax
801028fd:	75 0c                	jne    8010290b <createSwapFile+0x90>
		panic("no slot for files on /store");
801028ff:	c7 04 24 2f 9d 10 80 	movl   $0x80109d2f,(%esp)
80102906:	e8 2f dc ff ff       	call   8010053a <panic>

	p->swapFile->ip = in;
8010290b:	8b 45 08             	mov    0x8(%ebp),%eax
8010290e:	8b 40 7c             	mov    0x7c(%eax),%eax
80102911:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102914:	89 50 10             	mov    %edx,0x10(%eax)
	p->swapFile->type = FD_INODE;
80102917:	8b 45 08             	mov    0x8(%ebp),%eax
8010291a:	8b 40 7c             	mov    0x7c(%eax),%eax
8010291d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
	p->swapFile->off = 0;
80102923:	8b 45 08             	mov    0x8(%ebp),%eax
80102926:	8b 40 7c             	mov    0x7c(%eax),%eax
80102929:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
	p->swapFile->readable = O_WRONLY;
80102930:	8b 45 08             	mov    0x8(%ebp),%eax
80102933:	8b 40 7c             	mov    0x7c(%eax),%eax
80102936:	c6 40 08 01          	movb   $0x1,0x8(%eax)
	p->swapFile->writable = O_RDWR;
8010293a:	8b 45 08             	mov    0x8(%ebp),%eax
8010293d:	8b 40 7c             	mov    0x7c(%eax),%eax
80102940:	c6 40 09 02          	movb   $0x2,0x9(%eax)
    end_op();
80102944:	e8 cd 12 00 00       	call   80103c16 <end_op>

    return 0;
80102949:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010294e:	c9                   	leave  
8010294f:	c3                   	ret    

80102950 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
80102950:	55                   	push   %ebp
80102951:	89 e5                	mov    %esp,%ebp
80102953:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
80102956:	8b 45 08             	mov    0x8(%ebp),%eax
80102959:	8b 40 7c             	mov    0x7c(%eax),%eax
8010295c:	8b 55 10             	mov    0x10(%ebp),%edx
8010295f:	89 50 14             	mov    %edx,0x14(%eax)

	return filewrite(p->swapFile, buffer, size);
80102962:	8b 55 14             	mov    0x14(%ebp),%edx
80102965:	8b 45 08             	mov    0x8(%ebp),%eax
80102968:	8b 40 7c             	mov    0x7c(%eax),%eax
8010296b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010296f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102972:	89 54 24 04          	mov    %edx,0x4(%esp)
80102976:	89 04 24             	mov    %eax,(%esp)
80102979:	e8 31 e9 ff ff       	call   801012af <filewrite>

}
8010297e:	c9                   	leave  
8010297f:	c3                   	ret    

80102980 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
80102980:	55                   	push   %ebp
80102981:	89 e5                	mov    %esp,%ebp
80102983:	83 ec 18             	sub    $0x18,%esp
	p->swapFile->off = placeOnFile;
80102986:	8b 45 08             	mov    0x8(%ebp),%eax
80102989:	8b 40 7c             	mov    0x7c(%eax),%eax
8010298c:	8b 55 10             	mov    0x10(%ebp),%edx
8010298f:	89 50 14             	mov    %edx,0x14(%eax)

	return fileread(p->swapFile, buffer,  size);
80102992:	8b 55 14             	mov    0x14(%ebp),%edx
80102995:	8b 45 08             	mov    0x8(%ebp),%eax
80102998:	8b 40 7c             	mov    0x7c(%eax),%eax
8010299b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010299f:	8b 55 0c             	mov    0xc(%ebp),%edx
801029a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801029a6:	89 04 24             	mov    %eax,(%esp)
801029a9:	e8 45 e8 ff ff       	call   801011f3 <fileread>
}
801029ae:	c9                   	leave  
801029af:	c3                   	ret    

801029b0 <copySwapFile>:

void
copySwapFile(struct proc *from, struct proc *to){
801029b0:	55                   	push   %ebp
801029b1:	89 e5                	mov    %esp,%ebp
801029b3:	53                   	push   %ebx
801029b4:	81 ec 24 10 00 00    	sub    $0x1024,%esp
   char buf[PGSIZE];
  //parent have swap file, copy it
    if(from->swapFile){
801029ba:	8b 45 08             	mov    0x8(%ebp),%eax
801029bd:	8b 40 7c             	mov    0x7c(%eax),%eax
801029c0:	85 c0                	test   %eax,%eax
801029c2:	0f 84 5f 01 00 00    	je     80102b27 <copySwapFile+0x177>
      int j,k;
      for(j = 0; j < 30; j++){
801029c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029cf:	e9 49 01 00 00       	jmp    80102b1d <copySwapFile+0x16d>
        if(proc->pagesMetaData[j].fileOffset != -1){
801029d4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801029db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029de:	89 d0                	mov    %edx,%eax
801029e0:	c1 e0 02             	shl    $0x2,%eax
801029e3:	01 d0                	add    %edx,%eax
801029e5:	c1 e0 02             	shl    $0x2,%eax
801029e8:	01 c8                	add    %ecx,%eax
801029ea:	05 98 00 00 00       	add    $0x98,%eax
801029ef:	8b 00                	mov    (%eax),%eax
801029f1:	83 f8 ff             	cmp    $0xffffffff,%eax
801029f4:	0f 84 1f 01 00 00    	je     80102b19 <copySwapFile+0x169>
          cprintf("something here %d %d\n",from->pid,from->pagesMetaData[j].fileOffset);
801029fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
801029fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a00:	89 d0                	mov    %edx,%eax
80102a02:	c1 e0 02             	shl    $0x2,%eax
80102a05:	01 d0                	add    %edx,%eax
80102a07:	c1 e0 02             	shl    $0x2,%eax
80102a0a:	01 c8                	add    %ecx,%eax
80102a0c:	05 98 00 00 00       	add    $0x98,%eax
80102a11:	8b 10                	mov    (%eax),%edx
80102a13:	8b 45 08             	mov    0x8(%ebp),%eax
80102a16:	8b 40 10             	mov    0x10(%eax),%eax
80102a19:	89 54 24 08          	mov    %edx,0x8(%esp)
80102a1d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a21:	c7 04 24 4b 9d 10 80 	movl   $0x80109d4b,(%esp)
80102a28:	e8 73 d9 ff ff       	call   801003a0 <cprintf>
          to->pagesMetaData[j].fileOffset = from->pagesMetaData[j].fileOffset;
80102a2d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a30:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a33:	89 d0                	mov    %edx,%eax
80102a35:	c1 e0 02             	shl    $0x2,%eax
80102a38:	01 d0                	add    %edx,%eax
80102a3a:	c1 e0 02             	shl    $0x2,%eax
80102a3d:	01 c8                	add    %ecx,%eax
80102a3f:	05 98 00 00 00       	add    $0x98,%eax
80102a44:	8b 08                	mov    (%eax),%ecx
80102a46:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80102a49:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a4c:	89 d0                	mov    %edx,%eax
80102a4e:	c1 e0 02             	shl    $0x2,%eax
80102a51:	01 d0                	add    %edx,%eax
80102a53:	c1 e0 02             	shl    $0x2,%eax
80102a56:	01 d8                	add    %ebx,%eax
80102a58:	05 98 00 00 00       	add    $0x98,%eax
80102a5d:	89 08                	mov    %ecx,(%eax)
          if(readFromSwapFile(from,buf,from->pagesMetaData[j].fileOffset,PGSIZE) == -1)
80102a5f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a62:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a65:	89 d0                	mov    %edx,%eax
80102a67:	c1 e0 02             	shl    $0x2,%eax
80102a6a:	01 d0                	add    %edx,%eax
80102a6c:	c1 e0 02             	shl    $0x2,%eax
80102a6f:	01 c8                	add    %ecx,%eax
80102a71:	05 98 00 00 00       	add    $0x98,%eax
80102a76:	8b 00                	mov    (%eax),%eax
80102a78:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80102a7f:	00 
80102a80:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a84:	8d 85 f0 ef ff ff    	lea    -0x1010(%ebp),%eax
80102a8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a8e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a91:	89 04 24             	mov    %eax,(%esp)
80102a94:	e8 e7 fe ff ff       	call   80102980 <readFromSwapFile>
80102a99:	83 f8 ff             	cmp    $0xffffffff,%eax
80102a9c:	75 0c                	jne    80102aaa <copySwapFile+0xfa>
            panic("can't read swap file"); 
80102a9e:	c7 04 24 61 9d 10 80 	movl   $0x80109d61,(%esp)
80102aa5:	e8 90 da ff ff       	call   8010053a <panic>
          if(writeToSwapFile(to,buf,to->pagesMetaData[j].fileOffset,PGSIZE) == -1)
80102aaa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102aad:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ab0:	89 d0                	mov    %edx,%eax
80102ab2:	c1 e0 02             	shl    $0x2,%eax
80102ab5:	01 d0                	add    %edx,%eax
80102ab7:	c1 e0 02             	shl    $0x2,%eax
80102aba:	01 c8                	add    %ecx,%eax
80102abc:	05 98 00 00 00       	add    $0x98,%eax
80102ac1:	8b 00                	mov    (%eax),%eax
80102ac3:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80102aca:	00 
80102acb:	89 44 24 08          	mov    %eax,0x8(%esp)
80102acf:	8d 85 f0 ef ff ff    	lea    -0x1010(%ebp),%eax
80102ad5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ad9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102adc:	89 04 24             	mov    %eax,(%esp)
80102adf:	e8 6c fe ff ff       	call   80102950 <writeToSwapFile>
80102ae4:	83 f8 ff             	cmp    $0xffffffff,%eax
80102ae7:	75 0c                	jne    80102af5 <copySwapFile+0x145>
            panic("can't write swap file");
80102ae9:	c7 04 24 76 9d 10 80 	movl   $0x80109d76,(%esp)
80102af0:	e8 45 da ff ff       	call   8010053a <panic>
           for(k = 0; k < PGSIZE; k++)
80102af5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102afc:	eb 12                	jmp    80102b10 <copySwapFile+0x160>
             buf[k] = 0;
80102afe:	8d 95 f0 ef ff ff    	lea    -0x1010(%ebp),%edx
80102b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b07:	01 d0                	add    %edx,%eax
80102b09:	c6 00 00             	movb   $0x0,(%eax)
          to->pagesMetaData[j].fileOffset = from->pagesMetaData[j].fileOffset;
          if(readFromSwapFile(from,buf,from->pagesMetaData[j].fileOffset,PGSIZE) == -1)
            panic("can't read swap file"); 
          if(writeToSwapFile(to,buf,to->pagesMetaData[j].fileOffset,PGSIZE) == -1)
            panic("can't write swap file");
           for(k = 0; k < PGSIZE; k++)
80102b0c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b10:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80102b17:	7e e5                	jle    80102afe <copySwapFile+0x14e>
copySwapFile(struct proc *from, struct proc *to){
   char buf[PGSIZE];
  //parent have swap file, copy it
    if(from->swapFile){
      int j,k;
      for(j = 0; j < 30; j++){
80102b19:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b1d:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80102b21:	0f 8e ad fe ff ff    	jle    801029d4 <copySwapFile+0x24>
           for(k = 0; k < PGSIZE; k++)
             buf[k] = 0;
        }
      }
    }
80102b27:	81 c4 24 10 00 00    	add    $0x1024,%esp
80102b2d:	5b                   	pop    %ebx
80102b2e:	5d                   	pop    %ebp
80102b2f:	c3                   	ret    

80102b30 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b30:	55                   	push   %ebp
80102b31:	89 e5                	mov    %esp,%ebp
80102b33:	83 ec 14             	sub    $0x14,%esp
80102b36:	8b 45 08             	mov    0x8(%ebp),%eax
80102b39:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b3d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b41:	89 c2                	mov    %eax,%edx
80102b43:	ec                   	in     (%dx),%al
80102b44:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b47:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b4b:	c9                   	leave  
80102b4c:	c3                   	ret    

80102b4d <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102b4d:	55                   	push   %ebp
80102b4e:	89 e5                	mov    %esp,%ebp
80102b50:	57                   	push   %edi
80102b51:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102b52:	8b 55 08             	mov    0x8(%ebp),%edx
80102b55:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b58:	8b 45 10             	mov    0x10(%ebp),%eax
80102b5b:	89 cb                	mov    %ecx,%ebx
80102b5d:	89 df                	mov    %ebx,%edi
80102b5f:	89 c1                	mov    %eax,%ecx
80102b61:	fc                   	cld    
80102b62:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b64:	89 c8                	mov    %ecx,%eax
80102b66:	89 fb                	mov    %edi,%ebx
80102b68:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b6b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b6e:	5b                   	pop    %ebx
80102b6f:	5f                   	pop    %edi
80102b70:	5d                   	pop    %ebp
80102b71:	c3                   	ret    

80102b72 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b72:	55                   	push   %ebp
80102b73:	89 e5                	mov    %esp,%ebp
80102b75:	83 ec 08             	sub    $0x8,%esp
80102b78:	8b 55 08             	mov    0x8(%ebp),%edx
80102b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b7e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102b82:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b85:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b89:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b8d:	ee                   	out    %al,(%dx)
}
80102b8e:	c9                   	leave  
80102b8f:	c3                   	ret    

80102b90 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b90:	55                   	push   %ebp
80102b91:	89 e5                	mov    %esp,%ebp
80102b93:	56                   	push   %esi
80102b94:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b95:	8b 55 08             	mov    0x8(%ebp),%edx
80102b98:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b9b:	8b 45 10             	mov    0x10(%ebp),%eax
80102b9e:	89 cb                	mov    %ecx,%ebx
80102ba0:	89 de                	mov    %ebx,%esi
80102ba2:	89 c1                	mov    %eax,%ecx
80102ba4:	fc                   	cld    
80102ba5:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102ba7:	89 c8                	mov    %ecx,%eax
80102ba9:	89 f3                	mov    %esi,%ebx
80102bab:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102bae:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102bb1:	5b                   	pop    %ebx
80102bb2:	5e                   	pop    %esi
80102bb3:	5d                   	pop    %ebp
80102bb4:	c3                   	ret    

80102bb5 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102bb5:	55                   	push   %ebp
80102bb6:	89 e5                	mov    %esp,%ebp
80102bb8:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102bbb:	90                   	nop
80102bbc:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102bc3:	e8 68 ff ff ff       	call   80102b30 <inb>
80102bc8:	0f b6 c0             	movzbl %al,%eax
80102bcb:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102bce:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bd1:	25 c0 00 00 00       	and    $0xc0,%eax
80102bd6:	83 f8 40             	cmp    $0x40,%eax
80102bd9:	75 e1                	jne    80102bbc <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102bdb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102bdf:	74 11                	je     80102bf2 <idewait+0x3d>
80102be1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102be4:	83 e0 21             	and    $0x21,%eax
80102be7:	85 c0                	test   %eax,%eax
80102be9:	74 07                	je     80102bf2 <idewait+0x3d>
    return -1;
80102beb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102bf0:	eb 05                	jmp    80102bf7 <idewait+0x42>
  return 0;
80102bf2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bf7:	c9                   	leave  
80102bf8:	c3                   	ret    

80102bf9 <ideinit>:

void
ideinit(void)
{
80102bf9:	55                   	push   %ebp
80102bfa:	89 e5                	mov    %esp,%ebp
80102bfc:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102bff:	c7 44 24 04 8c 9d 10 	movl   $0x80109d8c,0x4(%esp)
80102c06:	80 
80102c07:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c0e:	e8 3a 2b 00 00       	call   8010574d <initlock>
  picenable(IRQ_IDE);
80102c13:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c1a:	e8 12 19 00 00       	call   80104531 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102c1f:	a1 40 49 11 80       	mov    0x80114940,%eax
80102c24:	83 e8 01             	sub    $0x1,%eax
80102c27:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c2b:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c32:	e8 43 04 00 00       	call   8010307a <ioapicenable>
  idewait(0);
80102c37:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c3e:	e8 72 ff ff ff       	call   80102bb5 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102c43:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102c4a:	00 
80102c4b:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c52:	e8 1b ff ff ff       	call   80102b72 <outb>
  for(i=0; i<1000; i++){
80102c57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c5e:	eb 20                	jmp    80102c80 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c60:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c67:	e8 c4 fe ff ff       	call   80102b30 <inb>
80102c6c:	84 c0                	test   %al,%al
80102c6e:	74 0c                	je     80102c7c <ideinit+0x83>
      havedisk1 = 1;
80102c70:	c7 05 38 d6 10 80 01 	movl   $0x1,0x8010d638
80102c77:	00 00 00 
      break;
80102c7a:	eb 0d                	jmp    80102c89 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102c7c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c80:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c87:	7e d7                	jle    80102c60 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c89:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c90:	00 
80102c91:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c98:	e8 d5 fe ff ff       	call   80102b72 <outb>
}
80102c9d:	c9                   	leave  
80102c9e:	c3                   	ret    

80102c9f <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102c9f:	55                   	push   %ebp
80102ca0:	89 e5                	mov    %esp,%ebp
80102ca2:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102ca5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102ca9:	75 0c                	jne    80102cb7 <idestart+0x18>
    panic("idestart");
80102cab:	c7 04 24 90 9d 10 80 	movl   $0x80109d90,(%esp)
80102cb2:	e8 83 d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cba:	8b 40 08             	mov    0x8(%eax),%eax
80102cbd:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102cc2:	76 0c                	jbe    80102cd0 <idestart+0x31>
    panic("incorrect blockno");
80102cc4:	c7 04 24 99 9d 10 80 	movl   $0x80109d99,(%esp)
80102ccb:	e8 6a d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102cd0:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102cd7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cda:	8b 50 08             	mov    0x8(%eax),%edx
80102cdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce0:	0f af c2             	imul   %edx,%eax
80102ce3:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102ce6:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102cea:	7e 0c                	jle    80102cf8 <idestart+0x59>
80102cec:	c7 04 24 90 9d 10 80 	movl   $0x80109d90,(%esp)
80102cf3:	e8 42 d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102cf8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102cff:	e8 b1 fe ff ff       	call   80102bb5 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102d04:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102d0b:	00 
80102d0c:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102d13:	e8 5a fe ff ff       	call   80102b72 <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102d18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d1b:	0f b6 c0             	movzbl %al,%eax
80102d1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d22:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102d29:	e8 44 fe ff ff       	call   80102b72 <outb>
  outb(0x1f3, sector & 0xff);
80102d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d31:	0f b6 c0             	movzbl %al,%eax
80102d34:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d38:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102d3f:	e8 2e fe ff ff       	call   80102b72 <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102d44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d47:	c1 f8 08             	sar    $0x8,%eax
80102d4a:	0f b6 c0             	movzbl %al,%eax
80102d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d51:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102d58:	e8 15 fe ff ff       	call   80102b72 <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d60:	c1 f8 10             	sar    $0x10,%eax
80102d63:	0f b6 c0             	movzbl %al,%eax
80102d66:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d6a:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102d71:	e8 fc fd ff ff       	call   80102b72 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102d76:	8b 45 08             	mov    0x8(%ebp),%eax
80102d79:	8b 40 04             	mov    0x4(%eax),%eax
80102d7c:	83 e0 01             	and    $0x1,%eax
80102d7f:	c1 e0 04             	shl    $0x4,%eax
80102d82:	89 c2                	mov    %eax,%edx
80102d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d87:	c1 f8 18             	sar    $0x18,%eax
80102d8a:	83 e0 0f             	and    $0xf,%eax
80102d8d:	09 d0                	or     %edx,%eax
80102d8f:	83 c8 e0             	or     $0xffffffe0,%eax
80102d92:	0f b6 c0             	movzbl %al,%eax
80102d95:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d99:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102da0:	e8 cd fd ff ff       	call   80102b72 <outb>
  if(b->flags & B_DIRTY){
80102da5:	8b 45 08             	mov    0x8(%ebp),%eax
80102da8:	8b 00                	mov    (%eax),%eax
80102daa:	83 e0 04             	and    $0x4,%eax
80102dad:	85 c0                	test   %eax,%eax
80102daf:	74 34                	je     80102de5 <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102db1:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102db8:	00 
80102db9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102dc0:	e8 ad fd ff ff       	call   80102b72 <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102dc5:	8b 45 08             	mov    0x8(%ebp),%eax
80102dc8:	83 c0 18             	add    $0x18,%eax
80102dcb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102dd2:	00 
80102dd3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dd7:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102dde:	e8 ad fd ff ff       	call   80102b90 <outsl>
80102de3:	eb 14                	jmp    80102df9 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102de5:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102dec:	00 
80102ded:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102df4:	e8 79 fd ff ff       	call   80102b72 <outb>
  }
}
80102df9:	c9                   	leave  
80102dfa:	c3                   	ret    

80102dfb <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102dfb:	55                   	push   %ebp
80102dfc:	89 e5                	mov    %esp,%ebp
80102dfe:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102e01:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e08:	e8 61 29 00 00       	call   8010576e <acquire>
  if((b = idequeue) == 0){
80102e0d:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e12:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e19:	75 11                	jne    80102e2c <ideintr+0x31>
    release(&idelock);
80102e1b:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e22:	e8 a9 29 00 00       	call   801057d0 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102e27:	e9 90 00 00 00       	jmp    80102ebc <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e2f:	8b 40 14             	mov    0x14(%eax),%eax
80102e32:	a3 34 d6 10 80       	mov    %eax,0x8010d634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e3a:	8b 00                	mov    (%eax),%eax
80102e3c:	83 e0 04             	and    $0x4,%eax
80102e3f:	85 c0                	test   %eax,%eax
80102e41:	75 2e                	jne    80102e71 <ideintr+0x76>
80102e43:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e4a:	e8 66 fd ff ff       	call   80102bb5 <idewait>
80102e4f:	85 c0                	test   %eax,%eax
80102e51:	78 1e                	js     80102e71 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102e53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e56:	83 c0 18             	add    $0x18,%eax
80102e59:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e60:	00 
80102e61:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e65:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e6c:	e8 dc fc ff ff       	call   80102b4d <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102e71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e74:	8b 00                	mov    (%eax),%eax
80102e76:	83 c8 02             	or     $0x2,%eax
80102e79:	89 c2                	mov    %eax,%edx
80102e7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e7e:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e83:	8b 00                	mov    (%eax),%eax
80102e85:	83 e0 fb             	and    $0xfffffffb,%eax
80102e88:	89 c2                	mov    %eax,%edx
80102e8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e8d:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102e8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e92:	89 04 24             	mov    %eax,(%esp)
80102e95:	e8 81 26 00 00       	call   8010551b <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102e9a:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e9f:	85 c0                	test   %eax,%eax
80102ea1:	74 0d                	je     80102eb0 <ideintr+0xb5>
    idestart(idequeue);
80102ea3:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ea8:	89 04 24             	mov    %eax,(%esp)
80102eab:	e8 ef fd ff ff       	call   80102c9f <idestart>

  release(&idelock);
80102eb0:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102eb7:	e8 14 29 00 00       	call   801057d0 <release>
}
80102ebc:	c9                   	leave  
80102ebd:	c3                   	ret    

80102ebe <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102ebe:	55                   	push   %ebp
80102ebf:	89 e5                	mov    %esp,%ebp
80102ec1:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102ec4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ec7:	8b 00                	mov    (%eax),%eax
80102ec9:	83 e0 01             	and    $0x1,%eax
80102ecc:	85 c0                	test   %eax,%eax
80102ece:	75 0c                	jne    80102edc <iderw+0x1e>
    panic("iderw: buf not busy");
80102ed0:	c7 04 24 ab 9d 10 80 	movl   $0x80109dab,(%esp)
80102ed7:	e8 5e d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102edc:	8b 45 08             	mov    0x8(%ebp),%eax
80102edf:	8b 00                	mov    (%eax),%eax
80102ee1:	83 e0 06             	and    $0x6,%eax
80102ee4:	83 f8 02             	cmp    $0x2,%eax
80102ee7:	75 0c                	jne    80102ef5 <iderw+0x37>
    panic("iderw: nothing to do");
80102ee9:	c7 04 24 bf 9d 10 80 	movl   $0x80109dbf,(%esp)
80102ef0:	e8 45 d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ef8:	8b 40 04             	mov    0x4(%eax),%eax
80102efb:	85 c0                	test   %eax,%eax
80102efd:	74 15                	je     80102f14 <iderw+0x56>
80102eff:	a1 38 d6 10 80       	mov    0x8010d638,%eax
80102f04:	85 c0                	test   %eax,%eax
80102f06:	75 0c                	jne    80102f14 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102f08:	c7 04 24 d4 9d 10 80 	movl   $0x80109dd4,(%esp)
80102f0f:	e8 26 d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f14:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f1b:	e8 4e 28 00 00       	call   8010576e <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102f20:	8b 45 08             	mov    0x8(%ebp),%eax
80102f23:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102f2a:	c7 45 f4 34 d6 10 80 	movl   $0x8010d634,-0xc(%ebp)
80102f31:	eb 0b                	jmp    80102f3e <iderw+0x80>
80102f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f36:	8b 00                	mov    (%eax),%eax
80102f38:	83 c0 14             	add    $0x14,%eax
80102f3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102f3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f41:	8b 00                	mov    (%eax),%eax
80102f43:	85 c0                	test   %eax,%eax
80102f45:	75 ec                	jne    80102f33 <iderw+0x75>
    ;
  *pp = b;
80102f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f4a:	8b 55 08             	mov    0x8(%ebp),%edx
80102f4d:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102f4f:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f54:	3b 45 08             	cmp    0x8(%ebp),%eax
80102f57:	75 0d                	jne    80102f66 <iderw+0xa8>
    idestart(b);
80102f59:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5c:	89 04 24             	mov    %eax,(%esp)
80102f5f:	e8 3b fd ff ff       	call   80102c9f <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f64:	eb 15                	jmp    80102f7b <iderw+0xbd>
80102f66:	eb 13                	jmp    80102f7b <iderw+0xbd>
    sleep(b, &idelock);
80102f68:	c7 44 24 04 00 d6 10 	movl   $0x8010d600,0x4(%esp)
80102f6f:	80 
80102f70:	8b 45 08             	mov    0x8(%ebp),%eax
80102f73:	89 04 24             	mov    %eax,(%esp)
80102f76:	e8 c4 24 00 00       	call   8010543f <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f7b:	8b 45 08             	mov    0x8(%ebp),%eax
80102f7e:	8b 00                	mov    (%eax),%eax
80102f80:	83 e0 06             	and    $0x6,%eax
80102f83:	83 f8 02             	cmp    $0x2,%eax
80102f86:	75 e0                	jne    80102f68 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102f88:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f8f:	e8 3c 28 00 00       	call   801057d0 <release>
}
80102f94:	c9                   	leave  
80102f95:	c3                   	ret    

80102f96 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f96:	55                   	push   %ebp
80102f97:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f99:	a1 14 42 11 80       	mov    0x80114214,%eax
80102f9e:	8b 55 08             	mov    0x8(%ebp),%edx
80102fa1:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102fa3:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fa8:	8b 40 10             	mov    0x10(%eax),%eax
}
80102fab:	5d                   	pop    %ebp
80102fac:	c3                   	ret    

80102fad <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102fad:	55                   	push   %ebp
80102fae:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fb0:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fb5:	8b 55 08             	mov    0x8(%ebp),%edx
80102fb8:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102fba:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fbf:	8b 55 0c             	mov    0xc(%ebp),%edx
80102fc2:	89 50 10             	mov    %edx,0x10(%eax)
}
80102fc5:	5d                   	pop    %ebp
80102fc6:	c3                   	ret    

80102fc7 <ioapicinit>:

void
ioapicinit(void)
{
80102fc7:	55                   	push   %ebp
80102fc8:	89 e5                	mov    %esp,%ebp
80102fca:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102fcd:	a1 44 43 11 80       	mov    0x80114344,%eax
80102fd2:	85 c0                	test   %eax,%eax
80102fd4:	75 05                	jne    80102fdb <ioapicinit+0x14>
    return;
80102fd6:	e9 9d 00 00 00       	jmp    80103078 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102fdb:	c7 05 14 42 11 80 00 	movl   $0xfec00000,0x80114214
80102fe2:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102fe5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fec:	e8 a5 ff ff ff       	call   80102f96 <ioapicread>
80102ff1:	c1 e8 10             	shr    $0x10,%eax
80102ff4:	25 ff 00 00 00       	and    $0xff,%eax
80102ff9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102ffc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103003:	e8 8e ff ff ff       	call   80102f96 <ioapicread>
80103008:	c1 e8 18             	shr    $0x18,%eax
8010300b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
8010300e:	0f b6 05 40 43 11 80 	movzbl 0x80114340,%eax
80103015:	0f b6 c0             	movzbl %al,%eax
80103018:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010301b:	74 0c                	je     80103029 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010301d:	c7 04 24 f4 9d 10 80 	movl   $0x80109df4,(%esp)
80103024:	e8 77 d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103029:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103030:	eb 3e                	jmp    80103070 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103032:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103035:	83 c0 20             	add    $0x20,%eax
80103038:	0d 00 00 01 00       	or     $0x10000,%eax
8010303d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103040:	83 c2 08             	add    $0x8,%edx
80103043:	01 d2                	add    %edx,%edx
80103045:	89 44 24 04          	mov    %eax,0x4(%esp)
80103049:	89 14 24             	mov    %edx,(%esp)
8010304c:	e8 5c ff ff ff       	call   80102fad <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103051:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103054:	83 c0 08             	add    $0x8,%eax
80103057:	01 c0                	add    %eax,%eax
80103059:	83 c0 01             	add    $0x1,%eax
8010305c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103063:	00 
80103064:	89 04 24             	mov    %eax,(%esp)
80103067:	e8 41 ff ff ff       	call   80102fad <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010306c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103070:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103073:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103076:	7e ba                	jle    80103032 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103078:	c9                   	leave  
80103079:	c3                   	ret    

8010307a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010307a:	55                   	push   %ebp
8010307b:	89 e5                	mov    %esp,%ebp
8010307d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103080:	a1 44 43 11 80       	mov    0x80114344,%eax
80103085:	85 c0                	test   %eax,%eax
80103087:	75 02                	jne    8010308b <ioapicenable+0x11>
    return;
80103089:	eb 37                	jmp    801030c2 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
8010308b:	8b 45 08             	mov    0x8(%ebp),%eax
8010308e:	83 c0 20             	add    $0x20,%eax
80103091:	8b 55 08             	mov    0x8(%ebp),%edx
80103094:	83 c2 08             	add    $0x8,%edx
80103097:	01 d2                	add    %edx,%edx
80103099:	89 44 24 04          	mov    %eax,0x4(%esp)
8010309d:	89 14 24             	mov    %edx,(%esp)
801030a0:	e8 08 ff ff ff       	call   80102fad <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801030a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801030a8:	c1 e0 18             	shl    $0x18,%eax
801030ab:	8b 55 08             	mov    0x8(%ebp),%edx
801030ae:	83 c2 08             	add    $0x8,%edx
801030b1:	01 d2                	add    %edx,%edx
801030b3:	83 c2 01             	add    $0x1,%edx
801030b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801030ba:	89 14 24             	mov    %edx,(%esp)
801030bd:	e8 eb fe ff ff       	call   80102fad <ioapicwrite>
}
801030c2:	c9                   	leave  
801030c3:	c3                   	ret    

801030c4 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801030c4:	55                   	push   %ebp
801030c5:	89 e5                	mov    %esp,%ebp
801030c7:	8b 45 08             	mov    0x8(%ebp),%eax
801030ca:	05 00 00 00 80       	add    $0x80000000,%eax
801030cf:	5d                   	pop    %ebp
801030d0:	c3                   	ret    

801030d1 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801030d1:	55                   	push   %ebp
801030d2:	89 e5                	mov    %esp,%ebp
801030d4:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801030d7:	c7 44 24 04 26 9e 10 	movl   $0x80109e26,0x4(%esp)
801030de:	80 
801030df:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801030e6:	e8 62 26 00 00       	call   8010574d <initlock>
  kmem.use_lock = 0;
801030eb:	c7 05 54 42 11 80 00 	movl   $0x0,0x80114254
801030f2:	00 00 00 
  freerange(vstart, vend);
801030f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801030f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801030fc:	8b 45 08             	mov    0x8(%ebp),%eax
801030ff:	89 04 24             	mov    %eax,(%esp)
80103102:	e8 26 00 00 00       	call   8010312d <freerange>
}
80103107:	c9                   	leave  
80103108:	c3                   	ret    

80103109 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103109:	55                   	push   %ebp
8010310a:	89 e5                	mov    %esp,%ebp
8010310c:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
8010310f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103112:	89 44 24 04          	mov    %eax,0x4(%esp)
80103116:	8b 45 08             	mov    0x8(%ebp),%eax
80103119:	89 04 24             	mov    %eax,(%esp)
8010311c:	e8 0c 00 00 00       	call   8010312d <freerange>
  kmem.use_lock = 1;
80103121:	c7 05 54 42 11 80 01 	movl   $0x1,0x80114254
80103128:	00 00 00 
}
8010312b:	c9                   	leave  
8010312c:	c3                   	ret    

8010312d <freerange>:

void
freerange(void *vstart, void *vend)
{
8010312d:	55                   	push   %ebp
8010312e:	89 e5                	mov    %esp,%ebp
80103130:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103133:	8b 45 08             	mov    0x8(%ebp),%eax
80103136:	05 ff 0f 00 00       	add    $0xfff,%eax
8010313b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103140:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103143:	eb 12                	jmp    80103157 <freerange+0x2a>
    kfree(p);
80103145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103148:	89 04 24             	mov    %eax,(%esp)
8010314b:	e8 16 00 00 00       	call   80103166 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103150:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103157:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010315a:	05 00 10 00 00       	add    $0x1000,%eax
8010315f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103162:	76 e1                	jbe    80103145 <freerange+0x18>
    kfree(p);
}
80103164:	c9                   	leave  
80103165:	c3                   	ret    

80103166 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103166:	55                   	push   %ebp
80103167:	89 e5                	mov    %esp,%ebp
80103169:	83 ec 28             	sub    $0x28,%esp
  // if(getPid()){
  //   cprintf("%x\n",v);
  // }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
8010316c:	8b 45 08             	mov    0x8(%ebp),%eax
8010316f:	25 ff 0f 00 00       	and    $0xfff,%eax
80103174:	85 c0                	test   %eax,%eax
80103176:	75 1b                	jne    80103193 <kfree+0x2d>
80103178:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
8010317f:	72 12                	jb     80103193 <kfree+0x2d>
80103181:	8b 45 08             	mov    0x8(%ebp),%eax
80103184:	89 04 24             	mov    %eax,(%esp)
80103187:	e8 38 ff ff ff       	call   801030c4 <v2p>
8010318c:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103191:	76 50                	jbe    801031e3 <kfree+0x7d>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
80103193:	8b 45 08             	mov    0x8(%ebp),%eax
80103196:	89 04 24             	mov    %eax,(%esp)
80103199:	e8 26 ff ff ff       	call   801030c4 <v2p>
8010319e:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031a3:	0f 97 c0             	seta   %al
801031a6:	0f b6 d0             	movzbl %al,%edx
801031a9:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
801031b0:	0f 92 c0             	setb   %al
801031b3:	0f b6 c0             	movzbl %al,%eax
801031b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
801031b9:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
801031bf:	89 54 24 0c          	mov    %edx,0xc(%esp)
801031c3:	89 44 24 08          	mov    %eax,0x8(%esp)
801031c7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801031cb:	c7 04 24 2b 9e 10 80 	movl   $0x80109e2b,(%esp)
801031d2:	e8 c9 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031d7:	c7 04 24 42 9e 10 80 	movl   $0x80109e42,(%esp)
801031de:	e8 57 d3 ff ff       	call   8010053a <panic>
  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  // if(getPid()){
  //   cprintf("after memset\n");
  // }
  if(kmem.use_lock)
801031e3:	a1 54 42 11 80       	mov    0x80114254,%eax
801031e8:	85 c0                	test   %eax,%eax
801031ea:	74 0c                	je     801031f8 <kfree+0x92>
    acquire(&kmem.lock);
801031ec:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801031f3:	e8 76 25 00 00       	call   8010576e <acquire>
  r = (struct run*)v;
801031f8:	8b 45 08             	mov    0x8(%ebp),%eax
801031fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
801031fe:	8b 15 58 42 11 80    	mov    0x80114258,%edx
80103204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103207:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103209:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010320c:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103211:	a1 54 42 11 80       	mov    0x80114254,%eax
80103216:	85 c0                	test   %eax,%eax
80103218:	74 0c                	je     80103226 <kfree+0xc0>
    release(&kmem.lock);
8010321a:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103221:	e8 aa 25 00 00       	call   801057d0 <release>
}
80103226:	c9                   	leave  
80103227:	c3                   	ret    

80103228 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103228:	55                   	push   %ebp
80103229:	89 e5                	mov    %esp,%ebp
8010322b:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
8010322e:	a1 54 42 11 80       	mov    0x80114254,%eax
80103233:	85 c0                	test   %eax,%eax
80103235:	74 0c                	je     80103243 <kalloc+0x1b>
    acquire(&kmem.lock);
80103237:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010323e:	e8 2b 25 00 00       	call   8010576e <acquire>
  r = kmem.freelist;
80103243:	a1 58 42 11 80       	mov    0x80114258,%eax
80103248:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
8010324b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010324f:	74 0a                	je     8010325b <kalloc+0x33>
    kmem.freelist = r->next;
80103251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103254:	8b 00                	mov    (%eax),%eax
80103256:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
8010325b:	a1 54 42 11 80       	mov    0x80114254,%eax
80103260:	85 c0                	test   %eax,%eax
80103262:	74 0c                	je     80103270 <kalloc+0x48>
    release(&kmem.lock);
80103264:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010326b:	e8 60 25 00 00       	call   801057d0 <release>
  return (char*)r;
80103270:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103273:	c9                   	leave  
80103274:	c3                   	ret    

80103275 <countPages>:

int
countPages(){
80103275:	55                   	push   %ebp
80103276:	89 e5                	mov    %esp,%ebp
80103278:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
8010327b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
80103282:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103289:	e8 e0 24 00 00       	call   8010576e <acquire>
  r = kmem.freelist;
8010328e:	a1 58 42 11 80       	mov    0x80114258,%eax
80103293:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
80103296:	eb 0c                	jmp    801032a4 <countPages+0x2f>
    result++;
80103298:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
8010329c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010329f:	8b 00                	mov    (%eax),%eax
801032a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
801032a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032a8:	75 ee                	jne    80103298 <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032aa:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032b1:	e8 1a 25 00 00       	call   801057d0 <release>
  return result;
801032b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b9:	c9                   	leave  
801032ba:	c3                   	ret    

801032bb <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032bb:	55                   	push   %ebp
801032bc:	89 e5                	mov    %esp,%ebp
801032be:	83 ec 14             	sub    $0x14,%esp
801032c1:	8b 45 08             	mov    0x8(%ebp),%eax
801032c4:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032c8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032cc:	89 c2                	mov    %eax,%edx
801032ce:	ec                   	in     (%dx),%al
801032cf:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801032d2:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801032d6:	c9                   	leave  
801032d7:	c3                   	ret    

801032d8 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801032d8:	55                   	push   %ebp
801032d9:	89 e5                	mov    %esp,%ebp
801032db:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801032de:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801032e5:	e8 d1 ff ff ff       	call   801032bb <inb>
801032ea:	0f b6 c0             	movzbl %al,%eax
801032ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801032f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032f3:	83 e0 01             	and    $0x1,%eax
801032f6:	85 c0                	test   %eax,%eax
801032f8:	75 0a                	jne    80103304 <kbdgetc+0x2c>
    return -1;
801032fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801032ff:	e9 25 01 00 00       	jmp    80103429 <kbdgetc+0x151>
  data = inb(KBDATAP);
80103304:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
8010330b:	e8 ab ff ff ff       	call   801032bb <inb>
80103310:	0f b6 c0             	movzbl %al,%eax
80103313:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103316:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
8010331d:	75 17                	jne    80103336 <kbdgetc+0x5e>
    shift |= E0ESC;
8010331f:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103324:	83 c8 40             	or     $0x40,%eax
80103327:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
8010332c:	b8 00 00 00 00       	mov    $0x0,%eax
80103331:	e9 f3 00 00 00       	jmp    80103429 <kbdgetc+0x151>
  } else if(data & 0x80){
80103336:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103339:	25 80 00 00 00       	and    $0x80,%eax
8010333e:	85 c0                	test   %eax,%eax
80103340:	74 45                	je     80103387 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103342:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103347:	83 e0 40             	and    $0x40,%eax
8010334a:	85 c0                	test   %eax,%eax
8010334c:	75 08                	jne    80103356 <kbdgetc+0x7e>
8010334e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103351:	83 e0 7f             	and    $0x7f,%eax
80103354:	eb 03                	jmp    80103359 <kbdgetc+0x81>
80103356:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103359:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
8010335c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010335f:	05 20 b0 10 80       	add    $0x8010b020,%eax
80103364:	0f b6 00             	movzbl (%eax),%eax
80103367:	83 c8 40             	or     $0x40,%eax
8010336a:	0f b6 c0             	movzbl %al,%eax
8010336d:	f7 d0                	not    %eax
8010336f:	89 c2                	mov    %eax,%edx
80103371:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103376:	21 d0                	and    %edx,%eax
80103378:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
8010337d:	b8 00 00 00 00       	mov    $0x0,%eax
80103382:	e9 a2 00 00 00       	jmp    80103429 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80103387:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010338c:	83 e0 40             	and    $0x40,%eax
8010338f:	85 c0                	test   %eax,%eax
80103391:	74 14                	je     801033a7 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103393:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
8010339a:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010339f:	83 e0 bf             	and    $0xffffffbf,%eax
801033a2:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
801033a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033aa:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033af:	0f b6 00             	movzbl (%eax),%eax
801033b2:	0f b6 d0             	movzbl %al,%edx
801033b5:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033ba:	09 d0                	or     %edx,%eax
801033bc:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033c1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033c4:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033c9:	0f b6 00             	movzbl (%eax),%eax
801033cc:	0f b6 d0             	movzbl %al,%edx
801033cf:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033d4:	31 d0                	xor    %edx,%eax
801033d6:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
801033db:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033e0:	83 e0 03             	and    $0x3,%eax
801033e3:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
801033ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033ed:	01 d0                	add    %edx,%eax
801033ef:	0f b6 00             	movzbl (%eax),%eax
801033f2:	0f b6 c0             	movzbl %al,%eax
801033f5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
801033f8:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033fd:	83 e0 08             	and    $0x8,%eax
80103400:	85 c0                	test   %eax,%eax
80103402:	74 22                	je     80103426 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80103404:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103408:	76 0c                	jbe    80103416 <kbdgetc+0x13e>
8010340a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
8010340e:	77 06                	ja     80103416 <kbdgetc+0x13e>
      c += 'A' - 'a';
80103410:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103414:	eb 10                	jmp    80103426 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80103416:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010341a:	76 0a                	jbe    80103426 <kbdgetc+0x14e>
8010341c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103420:	77 04                	ja     80103426 <kbdgetc+0x14e>
      c += 'a' - 'A';
80103422:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103426:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103429:	c9                   	leave  
8010342a:	c3                   	ret    

8010342b <kbdintr>:

void
kbdintr(void)
{
8010342b:	55                   	push   %ebp
8010342c:	89 e5                	mov    %esp,%ebp
8010342e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103431:	c7 04 24 d8 32 10 80 	movl   $0x801032d8,(%esp)
80103438:	e8 8b d3 ff ff       	call   801007c8 <consoleintr>
}
8010343d:	c9                   	leave  
8010343e:	c3                   	ret    

8010343f <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010343f:	55                   	push   %ebp
80103440:	89 e5                	mov    %esp,%ebp
80103442:	83 ec 14             	sub    $0x14,%esp
80103445:	8b 45 08             	mov    0x8(%ebp),%eax
80103448:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010344c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103450:	89 c2                	mov    %eax,%edx
80103452:	ec                   	in     (%dx),%al
80103453:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103456:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010345a:	c9                   	leave  
8010345b:	c3                   	ret    

8010345c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010345c:	55                   	push   %ebp
8010345d:	89 e5                	mov    %esp,%ebp
8010345f:	83 ec 08             	sub    $0x8,%esp
80103462:	8b 55 08             	mov    0x8(%ebp),%edx
80103465:	8b 45 0c             	mov    0xc(%ebp),%eax
80103468:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010346c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010346f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103473:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103477:	ee                   	out    %al,(%dx)
}
80103478:	c9                   	leave  
80103479:	c3                   	ret    

8010347a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010347a:	55                   	push   %ebp
8010347b:	89 e5                	mov    %esp,%ebp
8010347d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103480:	9c                   	pushf  
80103481:	58                   	pop    %eax
80103482:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80103485:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103488:	c9                   	leave  
80103489:	c3                   	ret    

8010348a <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010348a:	55                   	push   %ebp
8010348b:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010348d:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103492:	8b 55 08             	mov    0x8(%ebp),%edx
80103495:	c1 e2 02             	shl    $0x2,%edx
80103498:	01 c2                	add    %eax,%edx
8010349a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010349d:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
8010349f:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034a4:	83 c0 20             	add    $0x20,%eax
801034a7:	8b 00                	mov    (%eax),%eax
}
801034a9:	5d                   	pop    %ebp
801034aa:	c3                   	ret    

801034ab <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034ab:	55                   	push   %ebp
801034ac:	89 e5                	mov    %esp,%ebp
801034ae:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034b1:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034b6:	85 c0                	test   %eax,%eax
801034b8:	75 05                	jne    801034bf <lapicinit+0x14>
    return;
801034ba:	e9 43 01 00 00       	jmp    80103602 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034bf:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034c6:	00 
801034c7:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034ce:	e8 b7 ff ff ff       	call   8010348a <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801034d3:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801034da:	00 
801034db:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801034e2:	e8 a3 ff ff ff       	call   8010348a <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801034e7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801034ee:	00 
801034ef:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801034f6:	e8 8f ff ff ff       	call   8010348a <lapicw>
  lapicw(TICR, 10000000); 
801034fb:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103502:	00 
80103503:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010350a:	e8 7b ff ff ff       	call   8010348a <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010350f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103516:	00 
80103517:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010351e:	e8 67 ff ff ff       	call   8010348a <lapicw>
  lapicw(LINT1, MASKED);
80103523:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010352a:	00 
8010352b:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103532:	e8 53 ff ff ff       	call   8010348a <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103537:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010353c:	83 c0 30             	add    $0x30,%eax
8010353f:	8b 00                	mov    (%eax),%eax
80103541:	c1 e8 10             	shr    $0x10,%eax
80103544:	0f b6 c0             	movzbl %al,%eax
80103547:	83 f8 03             	cmp    $0x3,%eax
8010354a:	76 14                	jbe    80103560 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
8010354c:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103553:	00 
80103554:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010355b:	e8 2a ff ff ff       	call   8010348a <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103560:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103567:	00 
80103568:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010356f:	e8 16 ff ff ff       	call   8010348a <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103574:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010357b:	00 
8010357c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103583:	e8 02 ff ff ff       	call   8010348a <lapicw>
  lapicw(ESR, 0);
80103588:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010358f:	00 
80103590:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103597:	e8 ee fe ff ff       	call   8010348a <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010359c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035a3:	00 
801035a4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035ab:	e8 da fe ff ff       	call   8010348a <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035b7:	00 
801035b8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035bf:	e8 c6 fe ff ff       	call   8010348a <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035c4:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035cb:	00 
801035cc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801035d3:	e8 b2 fe ff ff       	call   8010348a <lapicw>
  while(lapic[ICRLO] & DELIVS)
801035d8:	90                   	nop
801035d9:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801035de:	05 00 03 00 00       	add    $0x300,%eax
801035e3:	8b 00                	mov    (%eax),%eax
801035e5:	25 00 10 00 00       	and    $0x1000,%eax
801035ea:	85 c0                	test   %eax,%eax
801035ec:	75 eb                	jne    801035d9 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801035ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035f5:	00 
801035f6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801035fd:	e8 88 fe ff ff       	call   8010348a <lapicw>
}
80103602:	c9                   	leave  
80103603:	c3                   	ret    

80103604 <cpunum>:

int
cpunum(void)
{
80103604:	55                   	push   %ebp
80103605:	89 e5                	mov    %esp,%ebp
80103607:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010360a:	e8 6b fe ff ff       	call   8010347a <readeflags>
8010360f:	25 00 02 00 00       	and    $0x200,%eax
80103614:	85 c0                	test   %eax,%eax
80103616:	74 25                	je     8010363d <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103618:	a1 40 d6 10 80       	mov    0x8010d640,%eax
8010361d:	8d 50 01             	lea    0x1(%eax),%edx
80103620:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
80103626:	85 c0                	test   %eax,%eax
80103628:	75 13                	jne    8010363d <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
8010362a:	8b 45 04             	mov    0x4(%ebp),%eax
8010362d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103631:	c7 04 24 50 9e 10 80 	movl   $0x80109e50,(%esp)
80103638:	e8 63 cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010363d:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103642:	85 c0                	test   %eax,%eax
80103644:	74 0f                	je     80103655 <cpunum+0x51>
    return lapic[ID]>>24;
80103646:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010364b:	83 c0 20             	add    $0x20,%eax
8010364e:	8b 00                	mov    (%eax),%eax
80103650:	c1 e8 18             	shr    $0x18,%eax
80103653:	eb 05                	jmp    8010365a <cpunum+0x56>
  return 0;
80103655:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010365a:	c9                   	leave  
8010365b:	c3                   	ret    

8010365c <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010365c:	55                   	push   %ebp
8010365d:	89 e5                	mov    %esp,%ebp
8010365f:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103662:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103667:	85 c0                	test   %eax,%eax
80103669:	74 14                	je     8010367f <lapiceoi+0x23>
    lapicw(EOI, 0);
8010366b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103672:	00 
80103673:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010367a:	e8 0b fe ff ff       	call   8010348a <lapicw>
}
8010367f:	c9                   	leave  
80103680:	c3                   	ret    

80103681 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103681:	55                   	push   %ebp
80103682:	89 e5                	mov    %esp,%ebp
}
80103684:	5d                   	pop    %ebp
80103685:	c3                   	ret    

80103686 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103686:	55                   	push   %ebp
80103687:	89 e5                	mov    %esp,%ebp
80103689:	83 ec 1c             	sub    $0x1c,%esp
8010368c:	8b 45 08             	mov    0x8(%ebp),%eax
8010368f:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103692:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103699:	00 
8010369a:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036a1:	e8 b6 fd ff ff       	call   8010345c <outb>
  outb(CMOS_PORT+1, 0x0A);
801036a6:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036ad:	00 
801036ae:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036b5:	e8 a2 fd ff ff       	call   8010345c <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036ba:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036c1:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036c4:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036cc:	8d 50 02             	lea    0x2(%eax),%edx
801036cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801036d2:	c1 e8 04             	shr    $0x4,%eax
801036d5:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801036d8:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801036dc:	c1 e0 18             	shl    $0x18,%eax
801036df:	89 44 24 04          	mov    %eax,0x4(%esp)
801036e3:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801036ea:	e8 9b fd ff ff       	call   8010348a <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801036ef:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801036f6:	00 
801036f7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801036fe:	e8 87 fd ff ff       	call   8010348a <lapicw>
  microdelay(200);
80103703:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010370a:	e8 72 ff ff ff       	call   80103681 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010370f:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103716:	00 
80103717:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010371e:	e8 67 fd ff ff       	call   8010348a <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103723:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010372a:	e8 52 ff ff ff       	call   80103681 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010372f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103736:	eb 40                	jmp    80103778 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103738:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010373c:	c1 e0 18             	shl    $0x18,%eax
8010373f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103743:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010374a:	e8 3b fd ff ff       	call   8010348a <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010374f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103752:	c1 e8 0c             	shr    $0xc,%eax
80103755:	80 cc 06             	or     $0x6,%ah
80103758:	89 44 24 04          	mov    %eax,0x4(%esp)
8010375c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103763:	e8 22 fd ff ff       	call   8010348a <lapicw>
    microdelay(200);
80103768:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010376f:	e8 0d ff ff ff       	call   80103681 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103774:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103778:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010377c:	7e ba                	jle    80103738 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010377e:	c9                   	leave  
8010377f:	c3                   	ret    

80103780 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103780:	55                   	push   %ebp
80103781:	89 e5                	mov    %esp,%ebp
80103783:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103786:	8b 45 08             	mov    0x8(%ebp),%eax
80103789:	0f b6 c0             	movzbl %al,%eax
8010378c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103790:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103797:	e8 c0 fc ff ff       	call   8010345c <outb>
  microdelay(200);
8010379c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037a3:	e8 d9 fe ff ff       	call   80103681 <microdelay>

  return inb(CMOS_RETURN);
801037a8:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037af:	e8 8b fc ff ff       	call   8010343f <inb>
801037b4:	0f b6 c0             	movzbl %al,%eax
}
801037b7:	c9                   	leave  
801037b8:	c3                   	ret    

801037b9 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037b9:	55                   	push   %ebp
801037ba:	89 e5                	mov    %esp,%ebp
801037bc:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037c6:	e8 b5 ff ff ff       	call   80103780 <cmos_read>
801037cb:	8b 55 08             	mov    0x8(%ebp),%edx
801037ce:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801037d0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801037d7:	e8 a4 ff ff ff       	call   80103780 <cmos_read>
801037dc:	8b 55 08             	mov    0x8(%ebp),%edx
801037df:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801037e2:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801037e9:	e8 92 ff ff ff       	call   80103780 <cmos_read>
801037ee:	8b 55 08             	mov    0x8(%ebp),%edx
801037f1:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801037f4:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801037fb:	e8 80 ff ff ff       	call   80103780 <cmos_read>
80103800:	8b 55 08             	mov    0x8(%ebp),%edx
80103803:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103806:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010380d:	e8 6e ff ff ff       	call   80103780 <cmos_read>
80103812:	8b 55 08             	mov    0x8(%ebp),%edx
80103815:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103818:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
8010381f:	e8 5c ff ff ff       	call   80103780 <cmos_read>
80103824:	8b 55 08             	mov    0x8(%ebp),%edx
80103827:	89 42 14             	mov    %eax,0x14(%edx)
}
8010382a:	c9                   	leave  
8010382b:	c3                   	ret    

8010382c <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
8010382c:	55                   	push   %ebp
8010382d:	89 e5                	mov    %esp,%ebp
8010382f:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103832:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103839:	e8 42 ff ff ff       	call   80103780 <cmos_read>
8010383e:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103844:	83 e0 04             	and    $0x4,%eax
80103847:	85 c0                	test   %eax,%eax
80103849:	0f 94 c0             	sete   %al
8010384c:	0f b6 c0             	movzbl %al,%eax
8010384f:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103852:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103855:	89 04 24             	mov    %eax,(%esp)
80103858:	e8 5c ff ff ff       	call   801037b9 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
8010385d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103864:	e8 17 ff ff ff       	call   80103780 <cmos_read>
80103869:	25 80 00 00 00       	and    $0x80,%eax
8010386e:	85 c0                	test   %eax,%eax
80103870:	74 02                	je     80103874 <cmostime+0x48>
        continue;
80103872:	eb 36                	jmp    801038aa <cmostime+0x7e>
    fill_rtcdate(&t2);
80103874:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103877:	89 04 24             	mov    %eax,(%esp)
8010387a:	e8 3a ff ff ff       	call   801037b9 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010387f:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103886:	00 
80103887:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010388a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010388e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103891:	89 04 24             	mov    %eax,(%esp)
80103894:	e8 a0 21 00 00       	call   80105a39 <memcmp>
80103899:	85 c0                	test   %eax,%eax
8010389b:	75 0d                	jne    801038aa <cmostime+0x7e>
      break;
8010389d:	90                   	nop
  }

  // convert
  if (bcd) {
8010389e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038a2:	0f 84 ac 00 00 00    	je     80103954 <cmostime+0x128>
801038a8:	eb 02                	jmp    801038ac <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038aa:	eb a6                	jmp    80103852 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038ac:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038af:	c1 e8 04             	shr    $0x4,%eax
801038b2:	89 c2                	mov    %eax,%edx
801038b4:	89 d0                	mov    %edx,%eax
801038b6:	c1 e0 02             	shl    $0x2,%eax
801038b9:	01 d0                	add    %edx,%eax
801038bb:	01 c0                	add    %eax,%eax
801038bd:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038c0:	83 e2 0f             	and    $0xf,%edx
801038c3:	01 d0                	add    %edx,%eax
801038c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038cb:	c1 e8 04             	shr    $0x4,%eax
801038ce:	89 c2                	mov    %eax,%edx
801038d0:	89 d0                	mov    %edx,%eax
801038d2:	c1 e0 02             	shl    $0x2,%eax
801038d5:	01 d0                	add    %edx,%eax
801038d7:	01 c0                	add    %eax,%eax
801038d9:	8b 55 dc             	mov    -0x24(%ebp),%edx
801038dc:	83 e2 0f             	and    $0xf,%edx
801038df:	01 d0                	add    %edx,%eax
801038e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801038e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801038e7:	c1 e8 04             	shr    $0x4,%eax
801038ea:	89 c2                	mov    %eax,%edx
801038ec:	89 d0                	mov    %edx,%eax
801038ee:	c1 e0 02             	shl    $0x2,%eax
801038f1:	01 d0                	add    %edx,%eax
801038f3:	01 c0                	add    %eax,%eax
801038f5:	8b 55 e0             	mov    -0x20(%ebp),%edx
801038f8:	83 e2 0f             	and    $0xf,%edx
801038fb:	01 d0                	add    %edx,%eax
801038fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103900:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103903:	c1 e8 04             	shr    $0x4,%eax
80103906:	89 c2                	mov    %eax,%edx
80103908:	89 d0                	mov    %edx,%eax
8010390a:	c1 e0 02             	shl    $0x2,%eax
8010390d:	01 d0                	add    %edx,%eax
8010390f:	01 c0                	add    %eax,%eax
80103911:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103914:	83 e2 0f             	and    $0xf,%edx
80103917:	01 d0                	add    %edx,%eax
80103919:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
8010391c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010391f:	c1 e8 04             	shr    $0x4,%eax
80103922:	89 c2                	mov    %eax,%edx
80103924:	89 d0                	mov    %edx,%eax
80103926:	c1 e0 02             	shl    $0x2,%eax
80103929:	01 d0                	add    %edx,%eax
8010392b:	01 c0                	add    %eax,%eax
8010392d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103930:	83 e2 0f             	and    $0xf,%edx
80103933:	01 d0                	add    %edx,%eax
80103935:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103938:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010393b:	c1 e8 04             	shr    $0x4,%eax
8010393e:	89 c2                	mov    %eax,%edx
80103940:	89 d0                	mov    %edx,%eax
80103942:	c1 e0 02             	shl    $0x2,%eax
80103945:	01 d0                	add    %edx,%eax
80103947:	01 c0                	add    %eax,%eax
80103949:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010394c:	83 e2 0f             	and    $0xf,%edx
8010394f:	01 d0                	add    %edx,%eax
80103951:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103954:	8b 45 08             	mov    0x8(%ebp),%eax
80103957:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010395a:	89 10                	mov    %edx,(%eax)
8010395c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010395f:	89 50 04             	mov    %edx,0x4(%eax)
80103962:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103965:	89 50 08             	mov    %edx,0x8(%eax)
80103968:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010396b:	89 50 0c             	mov    %edx,0xc(%eax)
8010396e:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103971:	89 50 10             	mov    %edx,0x10(%eax)
80103974:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103977:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
8010397a:	8b 45 08             	mov    0x8(%ebp),%eax
8010397d:	8b 40 14             	mov    0x14(%eax),%eax
80103980:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103986:	8b 45 08             	mov    0x8(%ebp),%eax
80103989:	89 50 14             	mov    %edx,0x14(%eax)
}
8010398c:	c9                   	leave  
8010398d:	c3                   	ret    

8010398e <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
8010398e:	55                   	push   %ebp
8010398f:	89 e5                	mov    %esp,%ebp
80103991:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103994:	c7 44 24 04 7c 9e 10 	movl   $0x80109e7c,0x4(%esp)
8010399b:	80 
8010399c:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
801039a3:	e8 a5 1d 00 00       	call   8010574d <initlock>
  readsb(dev, &sb);
801039a8:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801039af:	8b 45 08             	mov    0x8(%ebp),%eax
801039b2:	89 04 24             	mov    %eax,(%esp)
801039b5:	e8 37 da ff ff       	call   801013f1 <readsb>
  log.start = sb.logstart;
801039ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039bd:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039c2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039c5:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039ca:	8b 45 08             	mov    0x8(%ebp),%eax
801039cd:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
801039d2:	e8 9a 01 00 00       	call   80103b71 <recover_from_log>
}
801039d7:	c9                   	leave  
801039d8:	c3                   	ret    

801039d9 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801039d9:	55                   	push   %ebp
801039da:	89 e5                	mov    %esp,%ebp
801039dc:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801039df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039e6:	e9 8c 00 00 00       	jmp    80103a77 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801039eb:	8b 15 94 42 11 80    	mov    0x80114294,%edx
801039f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f4:	01 d0                	add    %edx,%eax
801039f6:	83 c0 01             	add    $0x1,%eax
801039f9:	89 c2                	mov    %eax,%edx
801039fb:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a00:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a04:	89 04 24             	mov    %eax,(%esp)
80103a07:	e8 9a c7 ff ff       	call   801001a6 <bread>
80103a0c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a12:	83 c0 10             	add    $0x10,%eax
80103a15:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a1c:	89 c2                	mov    %eax,%edx
80103a1e:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a23:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a27:	89 04 24             	mov    %eax,(%esp)
80103a2a:	e8 77 c7 ff ff       	call   801001a6 <bread>
80103a2f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a35:	8d 50 18             	lea    0x18(%eax),%edx
80103a38:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a3b:	83 c0 18             	add    $0x18,%eax
80103a3e:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a45:	00 
80103a46:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a4a:	89 04 24             	mov    %eax,(%esp)
80103a4d:	e8 3f 20 00 00       	call   80105a91 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a52:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a55:	89 04 24             	mov    %eax,(%esp)
80103a58:	e8 80 c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a60:	89 04 24             	mov    %eax,(%esp)
80103a63:	e8 af c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a6b:	89 04 24             	mov    %eax,(%esp)
80103a6e:	e8 a4 c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a73:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a77:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103a7c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a7f:	0f 8f 66 ff ff ff    	jg     801039eb <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103a85:	c9                   	leave  
80103a86:	c3                   	ret    

80103a87 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103a87:	55                   	push   %ebp
80103a88:	89 e5                	mov    %esp,%ebp
80103a8a:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103a8d:	a1 94 42 11 80       	mov    0x80114294,%eax
80103a92:	89 c2                	mov    %eax,%edx
80103a94:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a99:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a9d:	89 04 24             	mov    %eax,(%esp)
80103aa0:	e8 01 c7 ff ff       	call   801001a6 <bread>
80103aa5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103aa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aab:	83 c0 18             	add    $0x18,%eax
80103aae:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103ab1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ab4:	8b 00                	mov    (%eax),%eax
80103ab6:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103abb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ac2:	eb 1b                	jmp    80103adf <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103ac4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ac7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103aca:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103ace:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ad1:	83 c2 10             	add    $0x10,%edx
80103ad4:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103adb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103adf:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103ae4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ae7:	7f db                	jg     80103ac4 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aec:	89 04 24             	mov    %eax,(%esp)
80103aef:	e8 23 c7 ff ff       	call   80100217 <brelse>
}
80103af4:	c9                   	leave  
80103af5:	c3                   	ret    

80103af6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103af6:	55                   	push   %ebp
80103af7:	89 e5                	mov    %esp,%ebp
80103af9:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103afc:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b01:	89 c2                	mov    %eax,%edx
80103b03:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b08:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b0c:	89 04 24             	mov    %eax,(%esp)
80103b0f:	e8 92 c6 ff ff       	call   801001a6 <bread>
80103b14:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1a:	83 c0 18             	add    $0x18,%eax
80103b1d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b20:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b29:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b2b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b32:	eb 1b                	jmp    80103b4f <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b37:	83 c0 10             	add    $0x10,%eax
80103b3a:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b44:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b47:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b4b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b4f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b54:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b57:	7f db                	jg     80103b34 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b5c:	89 04 24             	mov    %eax,(%esp)
80103b5f:	e8 79 c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b67:	89 04 24             	mov    %eax,(%esp)
80103b6a:	e8 a8 c6 ff ff       	call   80100217 <brelse>
}
80103b6f:	c9                   	leave  
80103b70:	c3                   	ret    

80103b71 <recover_from_log>:

static void
recover_from_log(void)
{
80103b71:	55                   	push   %ebp
80103b72:	89 e5                	mov    %esp,%ebp
80103b74:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103b77:	e8 0b ff ff ff       	call   80103a87 <read_head>
  install_trans(); // if committed, copy from log to disk
80103b7c:	e8 58 fe ff ff       	call   801039d9 <install_trans>
  log.lh.n = 0;
80103b81:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103b88:	00 00 00 
  write_head(); // clear the log
80103b8b:	e8 66 ff ff ff       	call   80103af6 <write_head>
}
80103b90:	c9                   	leave  
80103b91:	c3                   	ret    

80103b92 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103b92:	55                   	push   %ebp
80103b93:	89 e5                	mov    %esp,%ebp
80103b95:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103b98:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103b9f:	e8 ca 1b 00 00       	call   8010576e <acquire>
  while(1){
    if(log.committing){
80103ba4:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103ba9:	85 c0                	test   %eax,%eax
80103bab:	74 16                	je     80103bc3 <begin_op+0x31>
      sleep(&log, &log.lock);
80103bad:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bb4:	80 
80103bb5:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bbc:	e8 7e 18 00 00       	call   8010543f <sleep>
80103bc1:	eb 4f                	jmp    80103c12 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103bc3:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103bc9:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bce:	8d 50 01             	lea    0x1(%eax),%edx
80103bd1:	89 d0                	mov    %edx,%eax
80103bd3:	c1 e0 02             	shl    $0x2,%eax
80103bd6:	01 d0                	add    %edx,%eax
80103bd8:	01 c0                	add    %eax,%eax
80103bda:	01 c8                	add    %ecx,%eax
80103bdc:	83 f8 1e             	cmp    $0x1e,%eax
80103bdf:	7e 16                	jle    80103bf7 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103be1:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103be8:	80 
80103be9:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bf0:	e8 4a 18 00 00       	call   8010543f <sleep>
80103bf5:	eb 1b                	jmp    80103c12 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103bf7:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bfc:	83 c0 01             	add    $0x1,%eax
80103bff:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c04:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c0b:	e8 c0 1b 00 00       	call   801057d0 <release>
      break;
80103c10:	eb 02                	jmp    80103c14 <begin_op+0x82>
    }
  }
80103c12:	eb 90                	jmp    80103ba4 <begin_op+0x12>
}
80103c14:	c9                   	leave  
80103c15:	c3                   	ret    

80103c16 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c16:	55                   	push   %ebp
80103c17:	89 e5                	mov    %esp,%ebp
80103c19:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c1c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c23:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c2a:	e8 3f 1b 00 00       	call   8010576e <acquire>
  log.outstanding -= 1;
80103c2f:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c34:	83 e8 01             	sub    $0x1,%eax
80103c37:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c3c:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c41:	85 c0                	test   %eax,%eax
80103c43:	74 0c                	je     80103c51 <end_op+0x3b>
    panic("log.committing");
80103c45:	c7 04 24 80 9e 10 80 	movl   $0x80109e80,(%esp)
80103c4c:	e8 e9 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c51:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c56:	85 c0                	test   %eax,%eax
80103c58:	75 13                	jne    80103c6d <end_op+0x57>
    do_commit = 1;
80103c5a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c61:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c68:	00 00 00 
80103c6b:	eb 0c                	jmp    80103c79 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c6d:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c74:	e8 a2 18 00 00       	call   8010551b <wakeup>
  }
  release(&log.lock);
80103c79:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c80:	e8 4b 1b 00 00       	call   801057d0 <release>

  if(do_commit){
80103c85:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c89:	74 33                	je     80103cbe <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103c8b:	e8 de 00 00 00       	call   80103d6e <commit>
    acquire(&log.lock);
80103c90:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c97:	e8 d2 1a 00 00       	call   8010576e <acquire>
    log.committing = 0;
80103c9c:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103ca3:	00 00 00 
    wakeup(&log);
80103ca6:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cad:	e8 69 18 00 00       	call   8010551b <wakeup>
    release(&log.lock);
80103cb2:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cb9:	e8 12 1b 00 00       	call   801057d0 <release>
  }
}
80103cbe:	c9                   	leave  
80103cbf:	c3                   	ret    

80103cc0 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103cc0:	55                   	push   %ebp
80103cc1:	89 e5                	mov    %esp,%ebp
80103cc3:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103cc6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ccd:	e9 8c 00 00 00       	jmp    80103d5e <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103cd2:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cdb:	01 d0                	add    %edx,%eax
80103cdd:	83 c0 01             	add    $0x1,%eax
80103ce0:	89 c2                	mov    %eax,%edx
80103ce2:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103ce7:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ceb:	89 04 24             	mov    %eax,(%esp)
80103cee:	e8 b3 c4 ff ff       	call   801001a6 <bread>
80103cf3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103cf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf9:	83 c0 10             	add    $0x10,%eax
80103cfc:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d03:	89 c2                	mov    %eax,%edx
80103d05:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d0a:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d0e:	89 04 24             	mov    %eax,(%esp)
80103d11:	e8 90 c4 ff ff       	call   801001a6 <bread>
80103d16:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d19:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d1c:	8d 50 18             	lea    0x18(%eax),%edx
80103d1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d22:	83 c0 18             	add    $0x18,%eax
80103d25:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d2c:	00 
80103d2d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d31:	89 04 24             	mov    %eax,(%esp)
80103d34:	e8 58 1d 00 00       	call   80105a91 <memmove>
    bwrite(to);  // write the log
80103d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d3c:	89 04 24             	mov    %eax,(%esp)
80103d3f:	e8 99 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d44:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d47:	89 04 24             	mov    %eax,(%esp)
80103d4a:	e8 c8 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d52:	89 04 24             	mov    %eax,(%esp)
80103d55:	e8 bd c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d5a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d5e:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d63:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d66:	0f 8f 66 ff ff ff    	jg     80103cd2 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d6c:	c9                   	leave  
80103d6d:	c3                   	ret    

80103d6e <commit>:

static void
commit()
{
80103d6e:	55                   	push   %ebp
80103d6f:	89 e5                	mov    %esp,%ebp
80103d71:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103d74:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d79:	85 c0                	test   %eax,%eax
80103d7b:	7e 1e                	jle    80103d9b <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103d7d:	e8 3e ff ff ff       	call   80103cc0 <write_log>
    write_head();    // Write header to disk -- the real commit
80103d82:	e8 6f fd ff ff       	call   80103af6 <write_head>
    install_trans(); // Now install writes to home locations
80103d87:	e8 4d fc ff ff       	call   801039d9 <install_trans>
    log.lh.n = 0; 
80103d8c:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103d93:	00 00 00 
    write_head();    // Erase the transaction from the log
80103d96:	e8 5b fd ff ff       	call   80103af6 <write_head>
  }
}
80103d9b:	c9                   	leave  
80103d9c:	c3                   	ret    

80103d9d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103d9d:	55                   	push   %ebp
80103d9e:	89 e5                	mov    %esp,%ebp
80103da0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103da3:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103da8:	83 f8 1d             	cmp    $0x1d,%eax
80103dab:	7f 12                	jg     80103dbf <log_write+0x22>
80103dad:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103db2:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103db8:	83 ea 01             	sub    $0x1,%edx
80103dbb:	39 d0                	cmp    %edx,%eax
80103dbd:	7c 0c                	jl     80103dcb <log_write+0x2e>
    panic("too big a transaction");
80103dbf:	c7 04 24 8f 9e 10 80 	movl   $0x80109e8f,(%esp)
80103dc6:	e8 6f c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103dcb:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103dd0:	85 c0                	test   %eax,%eax
80103dd2:	7f 0c                	jg     80103de0 <log_write+0x43>
    panic("log_write outside of trans");
80103dd4:	c7 04 24 a5 9e 10 80 	movl   $0x80109ea5,(%esp)
80103ddb:	e8 5a c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103de0:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103de7:	e8 82 19 00 00       	call   8010576e <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103dec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103df3:	eb 1f                	jmp    80103e14 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df8:	83 c0 10             	add    $0x10,%eax
80103dfb:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e02:	89 c2                	mov    %eax,%edx
80103e04:	8b 45 08             	mov    0x8(%ebp),%eax
80103e07:	8b 40 08             	mov    0x8(%eax),%eax
80103e0a:	39 c2                	cmp    %eax,%edx
80103e0c:	75 02                	jne    80103e10 <log_write+0x73>
      break;
80103e0e:	eb 0e                	jmp    80103e1e <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e10:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e14:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e19:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e1c:	7f d7                	jg     80103df5 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e1e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e21:	8b 40 08             	mov    0x8(%eax),%eax
80103e24:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e27:	83 c2 10             	add    $0x10,%edx
80103e2a:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e31:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e36:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e39:	75 0d                	jne    80103e48 <log_write+0xab>
    log.lh.n++;
80103e3b:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e40:	83 c0 01             	add    $0x1,%eax
80103e43:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e48:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4b:	8b 00                	mov    (%eax),%eax
80103e4d:	83 c8 04             	or     $0x4,%eax
80103e50:	89 c2                	mov    %eax,%edx
80103e52:	8b 45 08             	mov    0x8(%ebp),%eax
80103e55:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e57:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e5e:	e8 6d 19 00 00       	call   801057d0 <release>
}
80103e63:	c9                   	leave  
80103e64:	c3                   	ret    

80103e65 <v2p>:
80103e65:	55                   	push   %ebp
80103e66:	89 e5                	mov    %esp,%ebp
80103e68:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6b:	05 00 00 00 80       	add    $0x80000000,%eax
80103e70:	5d                   	pop    %ebp
80103e71:	c3                   	ret    

80103e72 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e72:	55                   	push   %ebp
80103e73:	89 e5                	mov    %esp,%ebp
80103e75:	8b 45 08             	mov    0x8(%ebp),%eax
80103e78:	05 00 00 00 80       	add    $0x80000000,%eax
80103e7d:	5d                   	pop    %ebp
80103e7e:	c3                   	ret    

80103e7f <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103e7f:	55                   	push   %ebp
80103e80:	89 e5                	mov    %esp,%ebp
80103e82:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103e85:	8b 55 08             	mov    0x8(%ebp),%edx
80103e88:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e8e:	f0 87 02             	lock xchg %eax,(%edx)
80103e91:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103e94:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103e97:	c9                   	leave  
80103e98:	c3                   	ret    

80103e99 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103e99:	55                   	push   %ebp
80103e9a:	89 e5                	mov    %esp,%ebp
80103e9c:	83 e4 f0             	and    $0xfffffff0,%esp
80103e9f:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103ea2:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103ea9:	80 
80103eaa:	c7 04 24 5c 0d 12 80 	movl   $0x80120d5c,(%esp)
80103eb1:	e8 1b f2 ff ff       	call   801030d1 <kinit1>
  kvmalloc();      // kernel page table
80103eb6:	e8 79 47 00 00       	call   80108634 <kvmalloc>
  mpinit();        // collect info about this machine
80103ebb:	e8 41 04 00 00       	call   80104301 <mpinit>
  lapicinit();
80103ec0:	e8 e6 f5 ff ff       	call   801034ab <lapicinit>
  seginit();       // set up segments
80103ec5:	e8 fd 40 00 00       	call   80107fc7 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103eca:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ed0:	0f b6 00             	movzbl (%eax),%eax
80103ed3:	0f b6 c0             	movzbl %al,%eax
80103ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103eda:	c7 04 24 c0 9e 10 80 	movl   $0x80109ec0,(%esp)
80103ee1:	e8 ba c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103ee6:	e8 74 06 00 00       	call   8010455f <picinit>
  ioapicinit();    // another interrupt controller
80103eeb:	e8 d7 f0 ff ff       	call   80102fc7 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ef0:	e8 bb cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103ef5:	e8 1c 34 00 00       	call   80107316 <uartinit>
  pinit();         // process table
80103efa:	e8 6a 0b 00 00       	call   80104a69 <pinit>
  tvinit();        // trap vectors
80103eff:	e8 2c 2f 00 00       	call   80106e30 <tvinit>
  binit();         // buffer cache
80103f04:	e8 2b c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f09:	e8 fc d0 ff ff       	call   8010100a <fileinit>
  ideinit();       // disk
80103f0e:	e8 e6 ec ff ff       	call   80102bf9 <ideinit>
  if(!ismp)
80103f13:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f18:	85 c0                	test   %eax,%eax
80103f1a:	75 05                	jne    80103f21 <main+0x88>
    timerinit();   // uniprocessor timer
80103f1c:	e8 5a 2e 00 00       	call   80106d7b <timerinit>
  startothers();   // start other processors
80103f21:	e8 7f 00 00 00       	call   80103fa5 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f26:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f2d:	8e 
80103f2e:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f35:	e8 cf f1 ff ff       	call   80103109 <kinit2>
  userinit();      // first user process
80103f3a:	e8 48 0c 00 00       	call   80104b87 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f3f:	e8 1a 00 00 00       	call   80103f5e <mpmain>

80103f44 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f44:	55                   	push   %ebp
80103f45:	89 e5                	mov    %esp,%ebp
80103f47:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f4a:	e8 fc 46 00 00       	call   8010864b <switchkvm>
  seginit();
80103f4f:	e8 73 40 00 00       	call   80107fc7 <seginit>
  lapicinit();
80103f54:	e8 52 f5 ff ff       	call   801034ab <lapicinit>
  mpmain();
80103f59:	e8 00 00 00 00       	call   80103f5e <mpmain>

80103f5e <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f5e:	55                   	push   %ebp
80103f5f:	89 e5                	mov    %esp,%ebp
80103f61:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f64:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f6a:	0f b6 00             	movzbl (%eax),%eax
80103f6d:	0f b6 c0             	movzbl %al,%eax
80103f70:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f74:	c7 04 24 d7 9e 10 80 	movl   $0x80109ed7,(%esp)
80103f7b:	e8 20 c4 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103f80:	e8 1f 30 00 00       	call   80106fa4 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103f85:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f8b:	05 a8 00 00 00       	add    $0xa8,%eax
80103f90:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103f97:	00 
80103f98:	89 04 24             	mov    %eax,(%esp)
80103f9b:	e8 df fe ff ff       	call   80103e7f <xchg>
  scheduler();     // start running processes
80103fa0:	e8 dc 12 00 00       	call   80105281 <scheduler>

80103fa5 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fa5:	55                   	push   %ebp
80103fa6:	89 e5                	mov    %esp,%ebp
80103fa8:	53                   	push   %ebx
80103fa9:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fac:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fb3:	e8 ba fe ff ff       	call   80103e72 <p2v>
80103fb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fbb:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fc0:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fc4:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103fcb:	80 
80103fcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fcf:	89 04 24             	mov    %eax,(%esp)
80103fd2:	e8 ba 1a 00 00       	call   80105a91 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103fd7:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80103fde:	e9 85 00 00 00       	jmp    80104068 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103fe3:	e8 1c f6 ff ff       	call   80103604 <cpunum>
80103fe8:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103fee:	05 60 43 11 80       	add    $0x80114360,%eax
80103ff3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ff6:	75 02                	jne    80103ffa <startothers+0x55>
      continue;
80103ff8:	eb 67                	jmp    80104061 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103ffa:	e8 29 f2 ff ff       	call   80103228 <kalloc>
80103fff:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104002:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104005:	83 e8 04             	sub    $0x4,%eax
80104008:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010400b:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104011:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104013:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104016:	83 e8 08             	sub    $0x8,%eax
80104019:	c7 00 44 3f 10 80    	movl   $0x80103f44,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
8010401f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104022:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104025:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
8010402c:	e8 34 fe ff ff       	call   80103e65 <v2p>
80104031:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104033:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104036:	89 04 24             	mov    %eax,(%esp)
80104039:	e8 27 fe ff ff       	call   80103e65 <v2p>
8010403e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104041:	0f b6 12             	movzbl (%edx),%edx
80104044:	0f b6 d2             	movzbl %dl,%edx
80104047:	89 44 24 04          	mov    %eax,0x4(%esp)
8010404b:	89 14 24             	mov    %edx,(%esp)
8010404e:	e8 33 f6 ff ff       	call   80103686 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104053:	90                   	nop
80104054:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104057:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010405d:	85 c0                	test   %eax,%eax
8010405f:	74 f3                	je     80104054 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104061:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104068:	a1 40 49 11 80       	mov    0x80114940,%eax
8010406d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104073:	05 60 43 11 80       	add    $0x80114360,%eax
80104078:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010407b:	0f 87 62 ff ff ff    	ja     80103fe3 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104081:	83 c4 24             	add    $0x24,%esp
80104084:	5b                   	pop    %ebx
80104085:	5d                   	pop    %ebp
80104086:	c3                   	ret    

80104087 <p2v>:
80104087:	55                   	push   %ebp
80104088:	89 e5                	mov    %esp,%ebp
8010408a:	8b 45 08             	mov    0x8(%ebp),%eax
8010408d:	05 00 00 00 80       	add    $0x80000000,%eax
80104092:	5d                   	pop    %ebp
80104093:	c3                   	ret    

80104094 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80104094:	55                   	push   %ebp
80104095:	89 e5                	mov    %esp,%ebp
80104097:	83 ec 14             	sub    $0x14,%esp
8010409a:	8b 45 08             	mov    0x8(%ebp),%eax
8010409d:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040a1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801040a5:	89 c2                	mov    %eax,%edx
801040a7:	ec                   	in     (%dx),%al
801040a8:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040ab:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040af:	c9                   	leave  
801040b0:	c3                   	ret    

801040b1 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040b1:	55                   	push   %ebp
801040b2:	89 e5                	mov    %esp,%ebp
801040b4:	83 ec 08             	sub    $0x8,%esp
801040b7:	8b 55 08             	mov    0x8(%ebp),%edx
801040ba:	8b 45 0c             	mov    0xc(%ebp),%eax
801040bd:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040c1:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040c4:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040c8:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040cc:	ee                   	out    %al,(%dx)
}
801040cd:	c9                   	leave  
801040ce:	c3                   	ret    

801040cf <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040cf:	55                   	push   %ebp
801040d0:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040d2:	a1 44 d6 10 80       	mov    0x8010d644,%eax
801040d7:	89 c2                	mov    %eax,%edx
801040d9:	b8 60 43 11 80       	mov    $0x80114360,%eax
801040de:	29 c2                	sub    %eax,%edx
801040e0:	89 d0                	mov    %edx,%eax
801040e2:	c1 f8 02             	sar    $0x2,%eax
801040e5:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801040eb:	5d                   	pop    %ebp
801040ec:	c3                   	ret    

801040ed <sum>:

static uchar
sum(uchar *addr, int len)
{
801040ed:	55                   	push   %ebp
801040ee:	89 e5                	mov    %esp,%ebp
801040f0:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801040f3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801040fa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104101:	eb 15                	jmp    80104118 <sum+0x2b>
    sum += addr[i];
80104103:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104106:	8b 45 08             	mov    0x8(%ebp),%eax
80104109:	01 d0                	add    %edx,%eax
8010410b:	0f b6 00             	movzbl (%eax),%eax
8010410e:	0f b6 c0             	movzbl %al,%eax
80104111:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104114:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104118:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010411b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010411e:	7c e3                	jl     80104103 <sum+0x16>
    sum += addr[i];
  return sum;
80104120:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104123:	c9                   	leave  
80104124:	c3                   	ret    

80104125 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104125:	55                   	push   %ebp
80104126:	89 e5                	mov    %esp,%ebp
80104128:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
8010412b:	8b 45 08             	mov    0x8(%ebp),%eax
8010412e:	89 04 24             	mov    %eax,(%esp)
80104131:	e8 51 ff ff ff       	call   80104087 <p2v>
80104136:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104139:	8b 55 0c             	mov    0xc(%ebp),%edx
8010413c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010413f:	01 d0                	add    %edx,%eax
80104141:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104144:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104147:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010414a:	eb 3f                	jmp    8010418b <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010414c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104153:	00 
80104154:	c7 44 24 04 e8 9e 10 	movl   $0x80109ee8,0x4(%esp)
8010415b:	80 
8010415c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010415f:	89 04 24             	mov    %eax,(%esp)
80104162:	e8 d2 18 00 00       	call   80105a39 <memcmp>
80104167:	85 c0                	test   %eax,%eax
80104169:	75 1c                	jne    80104187 <mpsearch1+0x62>
8010416b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104172:	00 
80104173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104176:	89 04 24             	mov    %eax,(%esp)
80104179:	e8 6f ff ff ff       	call   801040ed <sum>
8010417e:	84 c0                	test   %al,%al
80104180:	75 05                	jne    80104187 <mpsearch1+0x62>
      return (struct mp*)p;
80104182:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104185:	eb 11                	jmp    80104198 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80104187:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010418b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010418e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104191:	72 b9                	jb     8010414c <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80104193:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104198:	c9                   	leave  
80104199:	c3                   	ret    

8010419a <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
8010419a:	55                   	push   %ebp
8010419b:	89 e5                	mov    %esp,%ebp
8010419d:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041a0:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041aa:	83 c0 0f             	add    $0xf,%eax
801041ad:	0f b6 00             	movzbl (%eax),%eax
801041b0:	0f b6 c0             	movzbl %al,%eax
801041b3:	c1 e0 08             	shl    $0x8,%eax
801041b6:	89 c2                	mov    %eax,%edx
801041b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bb:	83 c0 0e             	add    $0xe,%eax
801041be:	0f b6 00             	movzbl (%eax),%eax
801041c1:	0f b6 c0             	movzbl %al,%eax
801041c4:	09 d0                	or     %edx,%eax
801041c6:	c1 e0 04             	shl    $0x4,%eax
801041c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041cc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041d0:	74 21                	je     801041f3 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041d2:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041d9:	00 
801041da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041dd:	89 04 24             	mov    %eax,(%esp)
801041e0:	e8 40 ff ff ff       	call   80104125 <mpsearch1>
801041e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801041e8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801041ec:	74 50                	je     8010423e <mpsearch+0xa4>
      return mp;
801041ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041f1:	eb 5f                	jmp    80104252 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801041f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f6:	83 c0 14             	add    $0x14,%eax
801041f9:	0f b6 00             	movzbl (%eax),%eax
801041fc:	0f b6 c0             	movzbl %al,%eax
801041ff:	c1 e0 08             	shl    $0x8,%eax
80104202:	89 c2                	mov    %eax,%edx
80104204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104207:	83 c0 13             	add    $0x13,%eax
8010420a:	0f b6 00             	movzbl (%eax),%eax
8010420d:	0f b6 c0             	movzbl %al,%eax
80104210:	09 d0                	or     %edx,%eax
80104212:	c1 e0 0a             	shl    $0xa,%eax
80104215:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104218:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010421b:	2d 00 04 00 00       	sub    $0x400,%eax
80104220:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104227:	00 
80104228:	89 04 24             	mov    %eax,(%esp)
8010422b:	e8 f5 fe ff ff       	call   80104125 <mpsearch1>
80104230:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104233:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104237:	74 05                	je     8010423e <mpsearch+0xa4>
      return mp;
80104239:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010423c:	eb 14                	jmp    80104252 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010423e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104245:	00 
80104246:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
8010424d:	e8 d3 fe ff ff       	call   80104125 <mpsearch1>
}
80104252:	c9                   	leave  
80104253:	c3                   	ret    

80104254 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104254:	55                   	push   %ebp
80104255:	89 e5                	mov    %esp,%ebp
80104257:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010425a:	e8 3b ff ff ff       	call   8010419a <mpsearch>
8010425f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104262:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104266:	74 0a                	je     80104272 <mpconfig+0x1e>
80104268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010426b:	8b 40 04             	mov    0x4(%eax),%eax
8010426e:	85 c0                	test   %eax,%eax
80104270:	75 0a                	jne    8010427c <mpconfig+0x28>
    return 0;
80104272:	b8 00 00 00 00       	mov    $0x0,%eax
80104277:	e9 83 00 00 00       	jmp    801042ff <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
8010427c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010427f:	8b 40 04             	mov    0x4(%eax),%eax
80104282:	89 04 24             	mov    %eax,(%esp)
80104285:	e8 fd fd ff ff       	call   80104087 <p2v>
8010428a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
8010428d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104294:	00 
80104295:	c7 44 24 04 ed 9e 10 	movl   $0x80109eed,0x4(%esp)
8010429c:	80 
8010429d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042a0:	89 04 24             	mov    %eax,(%esp)
801042a3:	e8 91 17 00 00       	call   80105a39 <memcmp>
801042a8:	85 c0                	test   %eax,%eax
801042aa:	74 07                	je     801042b3 <mpconfig+0x5f>
    return 0;
801042ac:	b8 00 00 00 00       	mov    $0x0,%eax
801042b1:	eb 4c                	jmp    801042ff <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042b6:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042ba:	3c 01                	cmp    $0x1,%al
801042bc:	74 12                	je     801042d0 <mpconfig+0x7c>
801042be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042c1:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042c5:	3c 04                	cmp    $0x4,%al
801042c7:	74 07                	je     801042d0 <mpconfig+0x7c>
    return 0;
801042c9:	b8 00 00 00 00       	mov    $0x0,%eax
801042ce:	eb 2f                	jmp    801042ff <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d3:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042d7:	0f b7 c0             	movzwl %ax,%eax
801042da:	89 44 24 04          	mov    %eax,0x4(%esp)
801042de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042e1:	89 04 24             	mov    %eax,(%esp)
801042e4:	e8 04 fe ff ff       	call   801040ed <sum>
801042e9:	84 c0                	test   %al,%al
801042eb:	74 07                	je     801042f4 <mpconfig+0xa0>
    return 0;
801042ed:	b8 00 00 00 00       	mov    $0x0,%eax
801042f2:	eb 0b                	jmp    801042ff <mpconfig+0xab>
  *pmp = mp;
801042f4:	8b 45 08             	mov    0x8(%ebp),%eax
801042f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042fa:	89 10                	mov    %edx,(%eax)
  return conf;
801042fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801042ff:	c9                   	leave  
80104300:	c3                   	ret    

80104301 <mpinit>:

void
mpinit(void)
{
80104301:	55                   	push   %ebp
80104302:	89 e5                	mov    %esp,%ebp
80104304:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104307:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
8010430e:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104311:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104314:	89 04 24             	mov    %eax,(%esp)
80104317:	e8 38 ff ff ff       	call   80104254 <mpconfig>
8010431c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010431f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104323:	75 05                	jne    8010432a <mpinit+0x29>
    return;
80104325:	e9 9c 01 00 00       	jmp    801044c6 <mpinit+0x1c5>
  ismp = 1;
8010432a:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
80104331:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104337:	8b 40 24             	mov    0x24(%eax),%eax
8010433a:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010433f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104342:	83 c0 2c             	add    $0x2c,%eax
80104345:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104348:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010434f:	0f b7 d0             	movzwl %ax,%edx
80104352:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104355:	01 d0                	add    %edx,%eax
80104357:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010435a:	e9 f4 00 00 00       	jmp    80104453 <mpinit+0x152>
    switch(*p){
8010435f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104362:	0f b6 00             	movzbl (%eax),%eax
80104365:	0f b6 c0             	movzbl %al,%eax
80104368:	83 f8 04             	cmp    $0x4,%eax
8010436b:	0f 87 bf 00 00 00    	ja     80104430 <mpinit+0x12f>
80104371:	8b 04 85 30 9f 10 80 	mov    -0x7fef60d0(,%eax,4),%eax
80104378:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
8010437a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437d:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104380:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104383:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104387:	0f b6 d0             	movzbl %al,%edx
8010438a:	a1 40 49 11 80       	mov    0x80114940,%eax
8010438f:	39 c2                	cmp    %eax,%edx
80104391:	74 2d                	je     801043c0 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104393:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104396:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010439a:	0f b6 d0             	movzbl %al,%edx
8010439d:	a1 40 49 11 80       	mov    0x80114940,%eax
801043a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801043a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801043aa:	c7 04 24 f2 9e 10 80 	movl   $0x80109ef2,(%esp)
801043b1:	e8 ea bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043b6:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043bd:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043c0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043c3:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043c7:	0f b6 c0             	movzbl %al,%eax
801043ca:	83 e0 02             	and    $0x2,%eax
801043cd:	85 c0                	test   %eax,%eax
801043cf:	74 15                	je     801043e6 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801043d1:	a1 40 49 11 80       	mov    0x80114940,%eax
801043d6:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801043dc:	05 60 43 11 80       	add    $0x80114360,%eax
801043e1:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
801043e6:	8b 15 40 49 11 80    	mov    0x80114940,%edx
801043ec:	a1 40 49 11 80       	mov    0x80114940,%eax
801043f1:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801043f7:	81 c2 60 43 11 80    	add    $0x80114360,%edx
801043fd:	88 02                	mov    %al,(%edx)
      ncpu++;
801043ff:	a1 40 49 11 80       	mov    0x80114940,%eax
80104404:	83 c0 01             	add    $0x1,%eax
80104407:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
8010440c:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104410:	eb 41                	jmp    80104453 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104415:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104418:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010441b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010441f:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
80104424:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104428:	eb 29                	jmp    80104453 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010442a:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010442e:	eb 23                	jmp    80104453 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104430:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104433:	0f b6 00             	movzbl (%eax),%eax
80104436:	0f b6 c0             	movzbl %al,%eax
80104439:	89 44 24 04          	mov    %eax,0x4(%esp)
8010443d:	c7 04 24 10 9f 10 80 	movl   $0x80109f10,(%esp)
80104444:	e8 57 bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104449:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104450:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104456:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104459:	0f 82 00 ff ff ff    	jb     8010435f <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
8010445f:	a1 44 43 11 80       	mov    0x80114344,%eax
80104464:	85 c0                	test   %eax,%eax
80104466:	75 1d                	jne    80104485 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104468:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
8010446f:	00 00 00 
    lapic = 0;
80104472:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
80104479:	00 00 00 
    ioapicid = 0;
8010447c:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
80104483:	eb 41                	jmp    801044c6 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104485:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104488:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
8010448c:	84 c0                	test   %al,%al
8010448e:	74 36                	je     801044c6 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104490:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104497:	00 
80104498:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
8010449f:	e8 0d fc ff ff       	call   801040b1 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044a4:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044ab:	e8 e4 fb ff ff       	call   80104094 <inb>
801044b0:	83 c8 01             	or     $0x1,%eax
801044b3:	0f b6 c0             	movzbl %al,%eax
801044b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801044ba:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044c1:	e8 eb fb ff ff       	call   801040b1 <outb>
  }
}
801044c6:	c9                   	leave  
801044c7:	c3                   	ret    

801044c8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044c8:	55                   	push   %ebp
801044c9:	89 e5                	mov    %esp,%ebp
801044cb:	83 ec 08             	sub    $0x8,%esp
801044ce:	8b 55 08             	mov    0x8(%ebp),%edx
801044d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801044d4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044d8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044db:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801044df:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801044e3:	ee                   	out    %al,(%dx)
}
801044e4:	c9                   	leave  
801044e5:	c3                   	ret    

801044e6 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801044e6:	55                   	push   %ebp
801044e7:	89 e5                	mov    %esp,%ebp
801044e9:	83 ec 0c             	sub    $0xc,%esp
801044ec:	8b 45 08             	mov    0x8(%ebp),%eax
801044ef:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801044f3:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801044f7:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
801044fd:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104501:	0f b6 c0             	movzbl %al,%eax
80104504:	89 44 24 04          	mov    %eax,0x4(%esp)
80104508:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010450f:	e8 b4 ff ff ff       	call   801044c8 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104514:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104518:	66 c1 e8 08          	shr    $0x8,%ax
8010451c:	0f b6 c0             	movzbl %al,%eax
8010451f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104523:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010452a:	e8 99 ff ff ff       	call   801044c8 <outb>
}
8010452f:	c9                   	leave  
80104530:	c3                   	ret    

80104531 <picenable>:

void
picenable(int irq)
{
80104531:	55                   	push   %ebp
80104532:	89 e5                	mov    %esp,%ebp
80104534:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104537:	8b 45 08             	mov    0x8(%ebp),%eax
8010453a:	ba 01 00 00 00       	mov    $0x1,%edx
8010453f:	89 c1                	mov    %eax,%ecx
80104541:	d3 e2                	shl    %cl,%edx
80104543:	89 d0                	mov    %edx,%eax
80104545:	f7 d0                	not    %eax
80104547:	89 c2                	mov    %eax,%edx
80104549:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104550:	21 d0                	and    %edx,%eax
80104552:	0f b7 c0             	movzwl %ax,%eax
80104555:	89 04 24             	mov    %eax,(%esp)
80104558:	e8 89 ff ff ff       	call   801044e6 <picsetmask>
}
8010455d:	c9                   	leave  
8010455e:	c3                   	ret    

8010455f <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010455f:	55                   	push   %ebp
80104560:	89 e5                	mov    %esp,%ebp
80104562:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104565:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010456c:	00 
8010456d:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104574:	e8 4f ff ff ff       	call   801044c8 <outb>
  outb(IO_PIC2+1, 0xFF);
80104579:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104580:	00 
80104581:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104588:	e8 3b ff ff ff       	call   801044c8 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
8010458d:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104594:	00 
80104595:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010459c:	e8 27 ff ff ff       	call   801044c8 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045a1:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045a8:	00 
801045a9:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045b0:	e8 13 ff ff ff       	call   801044c8 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045b5:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045bc:	00 
801045bd:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045c4:	e8 ff fe ff ff       	call   801044c8 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045c9:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045d0:	00 
801045d1:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045d8:	e8 eb fe ff ff       	call   801044c8 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801045dd:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045e4:	00 
801045e5:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801045ec:	e8 d7 fe ff ff       	call   801044c8 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801045f1:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
801045f8:	00 
801045f9:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104600:	e8 c3 fe ff ff       	call   801044c8 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104605:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010460c:	00 
8010460d:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104614:	e8 af fe ff ff       	call   801044c8 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104619:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104620:	00 
80104621:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104628:	e8 9b fe ff ff       	call   801044c8 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
8010462d:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104634:	00 
80104635:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010463c:	e8 87 fe ff ff       	call   801044c8 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104641:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104648:	00 
80104649:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104650:	e8 73 fe ff ff       	call   801044c8 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104655:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010465c:	00 
8010465d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104664:	e8 5f fe ff ff       	call   801044c8 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104669:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104670:	00 
80104671:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104678:	e8 4b fe ff ff       	call   801044c8 <outb>

  if(irqmask != 0xFFFF)
8010467d:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104684:	66 83 f8 ff          	cmp    $0xffff,%ax
80104688:	74 12                	je     8010469c <picinit+0x13d>
    picsetmask(irqmask);
8010468a:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104691:	0f b7 c0             	movzwl %ax,%eax
80104694:	89 04 24             	mov    %eax,(%esp)
80104697:	e8 4a fe ff ff       	call   801044e6 <picsetmask>
}
8010469c:	c9                   	leave  
8010469d:	c3                   	ret    

8010469e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010469e:	55                   	push   %ebp
8010469f:	89 e5                	mov    %esp,%ebp
801046a1:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046a4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801046ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801046b7:	8b 10                	mov    (%eax),%edx
801046b9:	8b 45 08             	mov    0x8(%ebp),%eax
801046bc:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046be:	e8 63 c9 ff ff       	call   80101026 <filealloc>
801046c3:	8b 55 08             	mov    0x8(%ebp),%edx
801046c6:	89 02                	mov    %eax,(%edx)
801046c8:	8b 45 08             	mov    0x8(%ebp),%eax
801046cb:	8b 00                	mov    (%eax),%eax
801046cd:	85 c0                	test   %eax,%eax
801046cf:	0f 84 c8 00 00 00    	je     8010479d <pipealloc+0xff>
801046d5:	e8 4c c9 ff ff       	call   80101026 <filealloc>
801046da:	8b 55 0c             	mov    0xc(%ebp),%edx
801046dd:	89 02                	mov    %eax,(%edx)
801046df:	8b 45 0c             	mov    0xc(%ebp),%eax
801046e2:	8b 00                	mov    (%eax),%eax
801046e4:	85 c0                	test   %eax,%eax
801046e6:	0f 84 b1 00 00 00    	je     8010479d <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801046ec:	e8 37 eb ff ff       	call   80103228 <kalloc>
801046f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046f8:	75 05                	jne    801046ff <pipealloc+0x61>
    goto bad;
801046fa:	e9 9e 00 00 00       	jmp    8010479d <pipealloc+0xff>
  p->readopen = 1;
801046ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104702:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104709:	00 00 00 
  p->writeopen = 1;
8010470c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010470f:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104716:	00 00 00 
  p->nwrite = 0;
80104719:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471c:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104723:	00 00 00 
  p->nread = 0;
80104726:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104729:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104730:	00 00 00 
  initlock(&p->lock, "pipe");
80104733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104736:	c7 44 24 04 44 9f 10 	movl   $0x80109f44,0x4(%esp)
8010473d:	80 
8010473e:	89 04 24             	mov    %eax,(%esp)
80104741:	e8 07 10 00 00       	call   8010574d <initlock>
  (*f0)->type = FD_PIPE;
80104746:	8b 45 08             	mov    0x8(%ebp),%eax
80104749:	8b 00                	mov    (%eax),%eax
8010474b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104751:	8b 45 08             	mov    0x8(%ebp),%eax
80104754:	8b 00                	mov    (%eax),%eax
80104756:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010475a:	8b 45 08             	mov    0x8(%ebp),%eax
8010475d:	8b 00                	mov    (%eax),%eax
8010475f:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104763:	8b 45 08             	mov    0x8(%ebp),%eax
80104766:	8b 00                	mov    (%eax),%eax
80104768:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010476b:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010476e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104771:	8b 00                	mov    (%eax),%eax
80104773:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104779:	8b 45 0c             	mov    0xc(%ebp),%eax
8010477c:	8b 00                	mov    (%eax),%eax
8010477e:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104782:	8b 45 0c             	mov    0xc(%ebp),%eax
80104785:	8b 00                	mov    (%eax),%eax
80104787:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010478b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010478e:	8b 00                	mov    (%eax),%eax
80104790:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104793:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104796:	b8 00 00 00 00       	mov    $0x0,%eax
8010479b:	eb 42                	jmp    801047df <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
8010479d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047a1:	74 0b                	je     801047ae <pipealloc+0x110>
    kfree((char*)p);
801047a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a6:	89 04 24             	mov    %eax,(%esp)
801047a9:	e8 b8 e9 ff ff       	call   80103166 <kfree>
  if(*f0)
801047ae:	8b 45 08             	mov    0x8(%ebp),%eax
801047b1:	8b 00                	mov    (%eax),%eax
801047b3:	85 c0                	test   %eax,%eax
801047b5:	74 0d                	je     801047c4 <pipealloc+0x126>
    fileclose(*f0);
801047b7:	8b 45 08             	mov    0x8(%ebp),%eax
801047ba:	8b 00                	mov    (%eax),%eax
801047bc:	89 04 24             	mov    %eax,(%esp)
801047bf:	e8 0a c9 ff ff       	call   801010ce <fileclose>
  if(*f1)
801047c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801047c7:	8b 00                	mov    (%eax),%eax
801047c9:	85 c0                	test   %eax,%eax
801047cb:	74 0d                	je     801047da <pipealloc+0x13c>
    fileclose(*f1);
801047cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801047d0:	8b 00                	mov    (%eax),%eax
801047d2:	89 04 24             	mov    %eax,(%esp)
801047d5:	e8 f4 c8 ff ff       	call   801010ce <fileclose>
  return -1;
801047da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801047df:	c9                   	leave  
801047e0:	c3                   	ret    

801047e1 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801047e1:	55                   	push   %ebp
801047e2:	89 e5                	mov    %esp,%ebp
801047e4:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801047e7:	8b 45 08             	mov    0x8(%ebp),%eax
801047ea:	89 04 24             	mov    %eax,(%esp)
801047ed:	e8 7c 0f 00 00       	call   8010576e <acquire>
  if(writable){
801047f2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801047f6:	74 1f                	je     80104817 <pipeclose+0x36>
    p->writeopen = 0;
801047f8:	8b 45 08             	mov    0x8(%ebp),%eax
801047fb:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104802:	00 00 00 
    wakeup(&p->nread);
80104805:	8b 45 08             	mov    0x8(%ebp),%eax
80104808:	05 34 02 00 00       	add    $0x234,%eax
8010480d:	89 04 24             	mov    %eax,(%esp)
80104810:	e8 06 0d 00 00       	call   8010551b <wakeup>
80104815:	eb 1d                	jmp    80104834 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104817:	8b 45 08             	mov    0x8(%ebp),%eax
8010481a:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104821:	00 00 00 
    wakeup(&p->nwrite);
80104824:	8b 45 08             	mov    0x8(%ebp),%eax
80104827:	05 38 02 00 00       	add    $0x238,%eax
8010482c:	89 04 24             	mov    %eax,(%esp)
8010482f:	e8 e7 0c 00 00       	call   8010551b <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104834:	8b 45 08             	mov    0x8(%ebp),%eax
80104837:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010483d:	85 c0                	test   %eax,%eax
8010483f:	75 25                	jne    80104866 <pipeclose+0x85>
80104841:	8b 45 08             	mov    0x8(%ebp),%eax
80104844:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010484a:	85 c0                	test   %eax,%eax
8010484c:	75 18                	jne    80104866 <pipeclose+0x85>
    release(&p->lock);
8010484e:	8b 45 08             	mov    0x8(%ebp),%eax
80104851:	89 04 24             	mov    %eax,(%esp)
80104854:	e8 77 0f 00 00       	call   801057d0 <release>
    kfree((char*)p);
80104859:	8b 45 08             	mov    0x8(%ebp),%eax
8010485c:	89 04 24             	mov    %eax,(%esp)
8010485f:	e8 02 e9 ff ff       	call   80103166 <kfree>
80104864:	eb 0b                	jmp    80104871 <pipeclose+0x90>
  } else
    release(&p->lock);
80104866:	8b 45 08             	mov    0x8(%ebp),%eax
80104869:	89 04 24             	mov    %eax,(%esp)
8010486c:	e8 5f 0f 00 00       	call   801057d0 <release>
}
80104871:	c9                   	leave  
80104872:	c3                   	ret    

80104873 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104873:	55                   	push   %ebp
80104874:	89 e5                	mov    %esp,%ebp
80104876:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104879:	8b 45 08             	mov    0x8(%ebp),%eax
8010487c:	89 04 24             	mov    %eax,(%esp)
8010487f:	e8 ea 0e 00 00       	call   8010576e <acquire>
  for(i = 0; i < n; i++){
80104884:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010488b:	e9 a6 00 00 00       	jmp    80104936 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104890:	eb 57                	jmp    801048e9 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104892:	8b 45 08             	mov    0x8(%ebp),%eax
80104895:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010489b:	85 c0                	test   %eax,%eax
8010489d:	74 0d                	je     801048ac <pipewrite+0x39>
8010489f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048a5:	8b 40 24             	mov    0x24(%eax),%eax
801048a8:	85 c0                	test   %eax,%eax
801048aa:	74 15                	je     801048c1 <pipewrite+0x4e>
        release(&p->lock);
801048ac:	8b 45 08             	mov    0x8(%ebp),%eax
801048af:	89 04 24             	mov    %eax,(%esp)
801048b2:	e8 19 0f 00 00       	call   801057d0 <release>
        return -1;
801048b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048bc:	e9 9f 00 00 00       	jmp    80104960 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048c1:	8b 45 08             	mov    0x8(%ebp),%eax
801048c4:	05 34 02 00 00       	add    $0x234,%eax
801048c9:	89 04 24             	mov    %eax,(%esp)
801048cc:	e8 4a 0c 00 00       	call   8010551b <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048d1:	8b 45 08             	mov    0x8(%ebp),%eax
801048d4:	8b 55 08             	mov    0x8(%ebp),%edx
801048d7:	81 c2 38 02 00 00    	add    $0x238,%edx
801048dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801048e1:	89 14 24             	mov    %edx,(%esp)
801048e4:	e8 56 0b 00 00       	call   8010543f <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048e9:	8b 45 08             	mov    0x8(%ebp),%eax
801048ec:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801048f2:	8b 45 08             	mov    0x8(%ebp),%eax
801048f5:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801048fb:	05 00 02 00 00       	add    $0x200,%eax
80104900:	39 c2                	cmp    %eax,%edx
80104902:	74 8e                	je     80104892 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104904:	8b 45 08             	mov    0x8(%ebp),%eax
80104907:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010490d:	8d 48 01             	lea    0x1(%eax),%ecx
80104910:	8b 55 08             	mov    0x8(%ebp),%edx
80104913:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104919:	25 ff 01 00 00       	and    $0x1ff,%eax
8010491e:	89 c1                	mov    %eax,%ecx
80104920:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104923:	8b 45 0c             	mov    0xc(%ebp),%eax
80104926:	01 d0                	add    %edx,%eax
80104928:	0f b6 10             	movzbl (%eax),%edx
8010492b:	8b 45 08             	mov    0x8(%ebp),%eax
8010492e:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104932:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104939:	3b 45 10             	cmp    0x10(%ebp),%eax
8010493c:	0f 8c 4e ff ff ff    	jl     80104890 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104942:	8b 45 08             	mov    0x8(%ebp),%eax
80104945:	05 34 02 00 00       	add    $0x234,%eax
8010494a:	89 04 24             	mov    %eax,(%esp)
8010494d:	e8 c9 0b 00 00       	call   8010551b <wakeup>
  release(&p->lock);
80104952:	8b 45 08             	mov    0x8(%ebp),%eax
80104955:	89 04 24             	mov    %eax,(%esp)
80104958:	e8 73 0e 00 00       	call   801057d0 <release>
  return n;
8010495d:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104960:	c9                   	leave  
80104961:	c3                   	ret    

80104962 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104962:	55                   	push   %ebp
80104963:	89 e5                	mov    %esp,%ebp
80104965:	53                   	push   %ebx
80104966:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104969:	8b 45 08             	mov    0x8(%ebp),%eax
8010496c:	89 04 24             	mov    %eax,(%esp)
8010496f:	e8 fa 0d 00 00       	call   8010576e <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104974:	eb 3a                	jmp    801049b0 <piperead+0x4e>
    if(proc->killed){
80104976:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497c:	8b 40 24             	mov    0x24(%eax),%eax
8010497f:	85 c0                	test   %eax,%eax
80104981:	74 15                	je     80104998 <piperead+0x36>
      release(&p->lock);
80104983:	8b 45 08             	mov    0x8(%ebp),%eax
80104986:	89 04 24             	mov    %eax,(%esp)
80104989:	e8 42 0e 00 00       	call   801057d0 <release>
      return -1;
8010498e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104993:	e9 b5 00 00 00       	jmp    80104a4d <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104998:	8b 45 08             	mov    0x8(%ebp),%eax
8010499b:	8b 55 08             	mov    0x8(%ebp),%edx
8010499e:	81 c2 34 02 00 00    	add    $0x234,%edx
801049a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801049a8:	89 14 24             	mov    %edx,(%esp)
801049ab:	e8 8f 0a 00 00       	call   8010543f <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049b0:	8b 45 08             	mov    0x8(%ebp),%eax
801049b3:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049b9:	8b 45 08             	mov    0x8(%ebp),%eax
801049bc:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049c2:	39 c2                	cmp    %eax,%edx
801049c4:	75 0d                	jne    801049d3 <piperead+0x71>
801049c6:	8b 45 08             	mov    0x8(%ebp),%eax
801049c9:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049cf:	85 c0                	test   %eax,%eax
801049d1:	75 a3                	jne    80104976 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049da:	eb 4b                	jmp    80104a27 <piperead+0xc5>
    if(p->nread == p->nwrite)
801049dc:	8b 45 08             	mov    0x8(%ebp),%eax
801049df:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049e5:	8b 45 08             	mov    0x8(%ebp),%eax
801049e8:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049ee:	39 c2                	cmp    %eax,%edx
801049f0:	75 02                	jne    801049f4 <piperead+0x92>
      break;
801049f2:	eb 3b                	jmp    80104a2f <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801049f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801049fa:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801049fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104a00:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a06:	8d 48 01             	lea    0x1(%eax),%ecx
80104a09:	8b 55 08             	mov    0x8(%ebp),%edx
80104a0c:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a12:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a17:	89 c2                	mov    %eax,%edx
80104a19:	8b 45 08             	mov    0x8(%ebp),%eax
80104a1c:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a21:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a23:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a2a:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a2d:	7c ad                	jl     801049dc <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80104a32:	05 38 02 00 00       	add    $0x238,%eax
80104a37:	89 04 24             	mov    %eax,(%esp)
80104a3a:	e8 dc 0a 00 00       	call   8010551b <wakeup>
  release(&p->lock);
80104a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80104a42:	89 04 24             	mov    %eax,(%esp)
80104a45:	e8 86 0d 00 00       	call   801057d0 <release>
  return i;
80104a4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a4d:	83 c4 24             	add    $0x24,%esp
80104a50:	5b                   	pop    %ebx
80104a51:	5d                   	pop    %ebp
80104a52:	c3                   	ret    

80104a53 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a53:	55                   	push   %ebp
80104a54:	89 e5                	mov    %esp,%ebp
80104a56:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a59:	9c                   	pushf  
80104a5a:	58                   	pop    %eax
80104a5b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a5e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a61:	c9                   	leave  
80104a62:	c3                   	ret    

80104a63 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a63:	55                   	push   %ebp
80104a64:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a66:	fb                   	sti    
}
80104a67:	5d                   	pop    %ebp
80104a68:	c3                   	ret    

80104a69 <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a69:	55                   	push   %ebp
80104a6a:	89 e5                	mov    %esp,%ebp
80104a6c:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a6f:	c7 44 24 04 49 9f 10 	movl   $0x80109f49,0x4(%esp)
80104a76:	80 
80104a77:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a7e:	e8 ca 0c 00 00       	call   8010574d <initlock>
}
80104a83:	c9                   	leave  
80104a84:	c3                   	ret    

80104a85 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104a85:	55                   	push   %ebp
80104a86:	89 e5                	mov    %esp,%ebp
80104a88:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104a8b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a92:	e8 d7 0c 00 00       	call   8010576e <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a97:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104a9e:	eb 53                	jmp    80104af3 <allocproc+0x6e>
    if(p->state == UNUSED)
80104aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa3:	8b 40 0c             	mov    0xc(%eax),%eax
80104aa6:	85 c0                	test   %eax,%eax
80104aa8:	75 42                	jne    80104aec <allocproc+0x67>
      goto found;
80104aaa:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aae:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104ab5:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104aba:	8d 50 01             	lea    0x1(%eax),%edx
80104abd:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104ac3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ac6:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104ac9:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104ad0:	e8 fb 0c 00 00       	call   801057d0 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104ad5:	e8 4e e7 ff ff       	call   80103228 <kalloc>
80104ada:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104add:	89 42 08             	mov    %eax,0x8(%edx)
80104ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae3:	8b 40 08             	mov    0x8(%eax),%eax
80104ae6:	85 c0                	test   %eax,%eax
80104ae8:	75 36                	jne    80104b20 <allocproc+0x9b>
80104aea:	eb 23                	jmp    80104b0f <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104aec:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80104af3:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80104afa:	72 a4                	jb     80104aa0 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104afc:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b03:	e8 c8 0c 00 00       	call   801057d0 <release>
    return 0;
80104b08:	b8 00 00 00 00       	mov    $0x0,%eax
80104b0d:	eb 76                	jmp    80104b85 <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b12:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b19:	b8 00 00 00 00       	mov    $0x0,%eax
80104b1e:	eb 65                	jmp    80104b85 <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b23:	8b 40 08             	mov    0x8(%eax),%eax
80104b26:	05 00 10 00 00       	add    $0x1000,%eax
80104b2b:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b2e:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b35:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b38:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b3b:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b3f:	ba eb 6d 10 80       	mov    $0x80106deb,%edx
80104b44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b47:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b49:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b50:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b53:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b59:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b5c:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b63:	00 
80104b64:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b6b:	00 
80104b6c:	89 04 24             	mov    %eax,(%esp)
80104b6f:	e8 4e 0e 00 00       	call   801059c2 <memset>
    p->context->eip = (uint)forkret;
80104b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b77:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b7a:	ba 00 54 10 80       	mov    $0x80105400,%edx
80104b7f:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104b82:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104b85:	c9                   	leave  
80104b86:	c3                   	ret    

80104b87 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104b87:	55                   	push   %ebp
80104b88:	89 e5                	mov    %esp,%ebp
80104b8a:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104b8d:	e8 f3 fe ff ff       	call   80104a85 <allocproc>
80104b92:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b98:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104b9f:	00 00 00 
    p->swapedPagesCounter = 0;
80104ba2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba5:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104bac:	00 00 00 
    p->pageFaultCounter = 0;
80104baf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bb2:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bb9:	00 00 00 
    p->swappedOutCounter = 0;
80104bbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bbf:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104bc6:	00 00 00 
    p->numOfPages = 0;
80104bc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bcc:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104bd3:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104bd6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104bdd:	e9 92 00 00 00       	jmp    80104c74 <userinit+0xed>
   	  p->pagesMetaData[i].count = 0;
80104be2:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104be5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104be8:	89 d0                	mov    %edx,%eax
80104bea:	c1 e0 02             	shl    $0x2,%eax
80104bed:	01 d0                	add    %edx,%eax
80104bef:	c1 e0 02             	shl    $0x2,%eax
80104bf2:	01 c8                	add    %ecx,%eax
80104bf4:	05 9c 00 00 00       	add    $0x9c,%eax
80104bf9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104bff:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c02:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c05:	89 d0                	mov    %edx,%eax
80104c07:	c1 e0 02             	shl    $0x2,%eax
80104c0a:	01 d0                	add    %edx,%eax
80104c0c:	c1 e0 02             	shl    $0x2,%eax
80104c0f:	01 c8                	add    %ecx,%eax
80104c11:	05 90 00 00 00       	add    $0x90,%eax
80104c16:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c1c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c1f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c22:	89 d0                	mov    %edx,%eax
80104c24:	c1 e0 02             	shl    $0x2,%eax
80104c27:	01 d0                	add    %edx,%eax
80104c29:	c1 e0 02             	shl    $0x2,%eax
80104c2c:	01 c8                	add    %ecx,%eax
80104c2e:	05 94 00 00 00       	add    $0x94,%eax
80104c33:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c39:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c3f:	89 d0                	mov    %edx,%eax
80104c41:	c1 e0 02             	shl    $0x2,%eax
80104c44:	01 d0                	add    %edx,%eax
80104c46:	c1 e0 02             	shl    $0x2,%eax
80104c49:	01 c8                	add    %ecx,%eax
80104c4b:	05 98 00 00 00       	add    $0x98,%eax
80104c50:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c56:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c59:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c5c:	89 d0                	mov    %edx,%eax
80104c5e:	c1 e0 02             	shl    $0x2,%eax
80104c61:	01 d0                	add    %edx,%eax
80104c63:	c1 e0 02             	shl    $0x2,%eax
80104c66:	01 c8                	add    %ecx,%eax
80104c68:	05 a0 00 00 00       	add    $0xa0,%eax
80104c6d:	c6 00 80             	movb   $0x80,(%eax)
    p->pageFaultCounter = 0;
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c70:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c74:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104c78:	0f 8e 64 ff ff ff    	jle    80104be2 <userinit+0x5b>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104c7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c81:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104c86:	e8 ec 38 00 00       	call   80108577 <setupkvm>
80104c8b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c8e:	89 42 04             	mov    %eax,0x4(%edx)
80104c91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c94:	8b 40 04             	mov    0x4(%eax),%eax
80104c97:	85 c0                	test   %eax,%eax
80104c99:	75 0c                	jne    80104ca7 <userinit+0x120>
      panic("userinit: out of memory?");
80104c9b:	c7 04 24 50 9f 10 80 	movl   $0x80109f50,(%esp)
80104ca2:	e8 93 b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104ca7:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104cac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104caf:	8b 40 04             	mov    0x4(%eax),%eax
80104cb2:	89 54 24 08          	mov    %edx,0x8(%esp)
80104cb6:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104cbd:	80 
80104cbe:	89 04 24             	mov    %eax,(%esp)
80104cc1:	e8 09 3b 00 00       	call   801087cf <inituvm>
    p->sz = PGSIZE;
80104cc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cc9:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104ccf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cd2:	8b 40 18             	mov    0x18(%eax),%eax
80104cd5:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104cdc:	00 
80104cdd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104ce4:	00 
80104ce5:	89 04 24             	mov    %eax,(%esp)
80104ce8:	e8 d5 0c 00 00       	call   801059c2 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104ced:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf0:	8b 40 18             	mov    0x18(%eax),%eax
80104cf3:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cfc:	8b 40 18             	mov    0x18(%eax),%eax
80104cff:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104d05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d08:	8b 40 18             	mov    0x18(%eax),%eax
80104d0b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d0e:	8b 52 18             	mov    0x18(%edx),%edx
80104d11:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d15:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d1c:	8b 40 18             	mov    0x18(%eax),%eax
80104d1f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d22:	8b 52 18             	mov    0x18(%edx),%edx
80104d25:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d29:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d30:	8b 40 18             	mov    0x18(%eax),%eax
80104d33:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d3d:	8b 40 18             	mov    0x18(%eax),%eax
80104d40:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d4a:	8b 40 18             	mov    0x18(%eax),%eax
80104d4d:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d57:	83 c0 6c             	add    $0x6c,%eax
80104d5a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d61:	00 
80104d62:	c7 44 24 04 69 9f 10 	movl   $0x80109f69,0x4(%esp)
80104d69:	80 
80104d6a:	89 04 24             	mov    %eax,(%esp)
80104d6d:	e8 70 0e 00 00       	call   80105be2 <safestrcpy>
  p->cwd = namei("/");
80104d72:	c7 04 24 72 9f 10 80 	movl   $0x80109f72,(%esp)
80104d79:	e8 ec d7 ff ff       	call   8010256a <namei>
80104d7e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d81:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d87:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104d8e:	e8 e2 e4 ff ff       	call   80103275 <countPages>
80104d93:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104d98:	a1 60 49 11 80       	mov    0x80114960,%eax
80104d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104da1:	c7 04 24 74 9f 10 80 	movl   $0x80109f74,(%esp)
80104da8:	e8 f3 b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104dad:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104db4:	00 00 00 
}
80104db7:	c9                   	leave  
80104db8:	c3                   	ret    

80104db9 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104db9:	55                   	push   %ebp
80104dba:	89 e5                	mov    %esp,%ebp
80104dbc:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104dbf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc5:	8b 00                	mov    (%eax),%eax
80104dc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104dca:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104dce:	7e 3f                	jle    80104e0f <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104dd0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dd7:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ddd:	01 c1                	add    %eax,%ecx
80104ddf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104de5:	8b 40 04             	mov    0x4(%eax),%eax
80104de8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104dec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104df0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104df3:	89 54 24 04          	mov    %edx,0x4(%esp)
80104df7:	89 04 24             	mov    %eax,(%esp)
80104dfa:	e8 46 3b 00 00       	call   80108945 <allocuvm>
80104dff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e02:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e06:	75 4c                	jne    80104e54 <growproc+0x9b>
      return -1;
80104e08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0d:	eb 63                	jmp    80104e72 <growproc+0xb9>
  } else if(n < 0){
80104e0f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e13:	79 3f                	jns    80104e54 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e15:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e1c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e22:	01 c1                	add    %eax,%ecx
80104e24:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e2a:	8b 40 04             	mov    0x4(%eax),%eax
80104e2d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e31:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e35:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e38:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e3c:	89 04 24             	mov    %eax,(%esp)
80104e3f:	e8 3a 3d 00 00       	call   80108b7e <deallocuvm>
80104e44:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e47:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e4b:	75 07                	jne    80104e54 <growproc+0x9b>
      return -1;
80104e4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e52:	eb 1e                	jmp    80104e72 <growproc+0xb9>
  }
  proc->sz = sz;
80104e54:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e5a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e5d:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e65:	89 04 24             	mov    %eax,(%esp)
80104e68:	e8 fb 37 00 00       	call   80108668 <switchuvm>
  return 0;
80104e6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e72:	c9                   	leave  
80104e73:	c3                   	ret    

80104e74 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e74:	55                   	push   %ebp
80104e75:	89 e5                	mov    %esp,%ebp
80104e77:	57                   	push   %edi
80104e78:	56                   	push   %esi
80104e79:	53                   	push   %ebx
80104e7a:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e7d:	e8 03 fc ff ff       	call   80104a85 <allocproc>
80104e82:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104e85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104e89:	75 0a                	jne    80104e95 <fork+0x21>
    return -1;
80104e8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e90:	e9 93 01 00 00       	jmp    80105028 <fork+0x1b4>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104e95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e9b:	8b 10                	mov    (%eax),%edx
80104e9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ea3:	8b 40 04             	mov    0x4(%eax),%eax
80104ea6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104ea9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ead:	89 54 24 04          	mov    %edx,0x4(%esp)
80104eb1:	89 04 24             	mov    %eax,(%esp)
80104eb4:	e8 ee 3f 00 00       	call   80108ea7 <copyuvm>
80104eb9:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ebc:	89 42 04             	mov    %eax,0x4(%edx)
80104ebf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ec2:	8b 40 04             	mov    0x4(%eax),%eax
80104ec5:	85 c0                	test   %eax,%eax
80104ec7:	75 2c                	jne    80104ef5 <fork+0x81>
    kfree(np->kstack);
80104ec9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ecc:	8b 40 08             	mov    0x8(%eax),%eax
80104ecf:	89 04 24             	mov    %eax,(%esp)
80104ed2:	e8 8f e2 ff ff       	call   80103166 <kfree>
    np->kstack = 0;
80104ed7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eda:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104ee1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ee4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104eeb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef0:	e9 33 01 00 00       	jmp    80105028 <fork+0x1b4>
  }
  np->sz = proc->sz;
80104ef5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104efb:	8b 10                	mov    (%eax),%edx
80104efd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f00:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f02:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f09:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f0c:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f12:	8b 50 18             	mov    0x18(%eax),%edx
80104f15:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f1b:	8b 40 18             	mov    0x18(%eax),%eax
80104f1e:	89 c3                	mov    %eax,%ebx
80104f20:	b8 13 00 00 00       	mov    $0x13,%eax
80104f25:	89 d7                	mov    %edx,%edi
80104f27:	89 de                	mov    %ebx,%esi
80104f29:	89 c1                	mov    %eax,%ecx
80104f2b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f30:	8b 40 18             	mov    0x18(%eax),%eax
80104f33:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f3a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f41:	eb 3d                	jmp    80104f80 <fork+0x10c>
    if(proc->ofile[i])
80104f43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f49:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f4c:	83 c2 08             	add    $0x8,%edx
80104f4f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f53:	85 c0                	test   %eax,%eax
80104f55:	74 25                	je     80104f7c <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f57:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f5d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f60:	83 c2 08             	add    $0x8,%edx
80104f63:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f67:	89 04 24             	mov    %eax,(%esp)
80104f6a:	e8 17 c1 ff ff       	call   80101086 <filedup>
80104f6f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f72:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f75:	83 c1 08             	add    $0x8,%ecx
80104f78:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f7c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f80:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f84:	7e bd                	jle    80104f43 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104f86:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f8c:	8b 40 68             	mov    0x68(%eax),%eax
80104f8f:	89 04 24             	mov    %eax,(%esp)
80104f92:	e8 f0 c9 ff ff       	call   80101987 <idup>
80104f97:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f9a:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104f9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fa3:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fa9:	83 c0 6c             	add    $0x6c,%eax
80104fac:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fb3:	00 
80104fb4:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fb8:	89 04 24             	mov    %eax,(%esp)
80104fbb:	e8 22 0c 00 00       	call   80105be2 <safestrcpy>

    pid = np->pid;
80104fc0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fc3:	8b 40 10             	mov    0x10(%eax),%eax
80104fc6:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->pageFaultCounter = 0;
80104fc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fcc:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104fd3:	00 00 00 
    np->swappedOutCounter = 0;
80104fd6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd9:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104fe0:	00 00 00 
    createSwapFile(np);
80104fe3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fe6:	89 04 24             	mov    %eax,(%esp)
80104fe9:	e8 8d d8 ff ff       	call   8010287b <createSwapFile>
    copySwapFile(proc,np);
80104fee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ff4:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ff7:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ffb:	89 04 24             	mov    %eax,(%esp)
80104ffe:	e8 ad d9 ff ff       	call   801029b0 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
80105003:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010500a:	e8 5f 07 00 00       	call   8010576e <acquire>
    np->state = RUNNABLE;
8010500f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105012:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
80105019:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105020:	e8 ab 07 00 00       	call   801057d0 <release>

    return pid;
80105025:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
80105028:	83 c4 2c             	add    $0x2c,%esp
8010502b:	5b                   	pop    %ebx
8010502c:	5e                   	pop    %esi
8010502d:	5f                   	pop    %edi
8010502e:	5d                   	pop    %ebp
8010502f:	c3                   	ret    

80105030 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105030:	55                   	push   %ebp
80105031:	89 e5                	mov    %esp,%ebp
80105033:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int fd;
    if(VERBOSE_PRINT == 1)
      procdump();
80105036:	e8 86 05 00 00       	call   801055c1 <procdump>
    if(proc == initproc)
8010503b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105042:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105047:	39 c2                	cmp    %eax,%edx
80105049:	75 0c                	jne    80105057 <exit+0x27>
      panic("init exiting");
8010504b:	c7 04 24 92 9f 10 80 	movl   $0x80109f92,(%esp)
80105052:	e8 e3 b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
80105057:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010505e:	eb 44                	jmp    801050a4 <exit+0x74>
      if(proc->ofile[fd]){
80105060:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105066:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105069:	83 c2 08             	add    $0x8,%edx
8010506c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105070:	85 c0                	test   %eax,%eax
80105072:	74 2c                	je     801050a0 <exit+0x70>
        fileclose(proc->ofile[fd]);
80105074:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010507a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010507d:	83 c2 08             	add    $0x8,%edx
80105080:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105084:	89 04 24             	mov    %eax,(%esp)
80105087:	e8 42 c0 ff ff       	call   801010ce <fileclose>
        proc->ofile[fd] = 0;
8010508c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105092:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105095:	83 c2 08             	add    $0x8,%edx
80105098:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010509f:	00 
      procdump();
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050a0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050a4:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801050a8:	7e b6                	jle    80105060 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
801050aa:	e8 e3 ea ff ff       	call   80103b92 <begin_op>
    iput(proc->cwd);
801050af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050b5:	8b 40 68             	mov    0x68(%eax),%eax
801050b8:	89 04 24             	mov    %eax,(%esp)
801050bb:	e8 b2 ca ff ff       	call   80101b72 <iput>
    end_op();
801050c0:	e8 51 eb ff ff       	call   80103c16 <end_op>
    proc->cwd = 0;
801050c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050cb:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
801050d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050d8:	89 04 24             	mov    %eax,(%esp)
801050db:	e8 8f d5 ff ff       	call   8010266f <removeSwapFile>
    acquire(&ptable.lock);
801050e0:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801050e7:	e8 82 06 00 00       	call   8010576e <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
801050ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f2:	8b 40 14             	mov    0x14(%eax),%eax
801050f5:	89 04 24             	mov    %eax,(%esp)
801050f8:	e8 dd 03 00 00       	call   801054da <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050fd:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105104:	eb 3b                	jmp    80105141 <exit+0x111>
      if(p->parent == proc){
80105106:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105109:	8b 50 14             	mov    0x14(%eax),%edx
8010510c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105112:	39 c2                	cmp    %eax,%edx
80105114:	75 24                	jne    8010513a <exit+0x10a>
        p->parent = initproc;
80105116:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
8010511c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010511f:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
80105122:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105125:	8b 40 0c             	mov    0xc(%eax),%eax
80105128:	83 f8 05             	cmp    $0x5,%eax
8010512b:	75 0d                	jne    8010513a <exit+0x10a>
          wakeup1(initproc);
8010512d:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105132:	89 04 24             	mov    %eax,(%esp)
80105135:	e8 a0 03 00 00       	call   801054da <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010513a:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105141:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105148:	72 bc                	jb     80105106 <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
8010514a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105150:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
80105157:	e8 c0 01 00 00       	call   8010531c <sched>
    panic("zombie exit");
8010515c:	c7 04 24 9f 9f 10 80 	movl   $0x80109f9f,(%esp)
80105163:	e8 d2 b3 ff ff       	call   8010053a <panic>

80105168 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
80105168:	55                   	push   %ebp
80105169:	89 e5                	mov    %esp,%ebp
8010516b:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
8010516e:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105175:	e8 f4 05 00 00       	call   8010576e <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
8010517a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105181:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105188:	e9 a4 00 00 00       	jmp    80105231 <wait+0xc9>
        if(p->parent != proc)
8010518d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105190:	8b 50 14             	mov    0x14(%eax),%edx
80105193:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105199:	39 c2                	cmp    %eax,%edx
8010519b:	74 05                	je     801051a2 <wait+0x3a>
          continue;
8010519d:	e9 88 00 00 00       	jmp    8010522a <wait+0xc2>
        havekids = 1;
801051a2:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
801051a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ac:	8b 40 0c             	mov    0xc(%eax),%eax
801051af:	83 f8 05             	cmp    $0x5,%eax
801051b2:	75 76                	jne    8010522a <wait+0xc2>
        // Found one.
          pid = p->pid;
801051b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051b7:	8b 40 10             	mov    0x10(%eax),%eax
801051ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801051bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051c0:	8b 40 08             	mov    0x8(%eax),%eax
801051c3:	89 04 24             	mov    %eax,(%esp)
801051c6:	e8 9b df ff ff       	call   80103166 <kfree>
          p->kstack = 0;
801051cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ce:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
801051d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d8:	8b 40 04             	mov    0x4(%eax),%eax
801051db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801051de:	89 54 24 04          	mov    %edx,0x4(%esp)
801051e2:	89 04 24             	mov    %eax,(%esp)
801051e5:	e8 d3 3b 00 00       	call   80108dbd <freevm>
          p->state = UNUSED;
801051ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ed:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
801051f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f7:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
801051fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105201:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
80105208:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010520b:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
8010520f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105212:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
80105219:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105220:	e8 ab 05 00 00       	call   801057d0 <release>
          return pid;
80105225:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105228:	eb 55                	jmp    8010527f <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010522a:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105231:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105238:	0f 82 4f ff ff ff    	jb     8010518d <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
8010523e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105242:	74 0d                	je     80105251 <wait+0xe9>
80105244:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010524a:	8b 40 24             	mov    0x24(%eax),%eax
8010524d:	85 c0                	test   %eax,%eax
8010524f:	74 13                	je     80105264 <wait+0xfc>
        release(&ptable.lock);
80105251:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105258:	e8 73 05 00 00       	call   801057d0 <release>
        return -1;
8010525d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105262:	eb 1b                	jmp    8010527f <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105264:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526a:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
80105271:	80 
80105272:	89 04 24             	mov    %eax,(%esp)
80105275:	e8 c5 01 00 00       	call   8010543f <sleep>
  }
8010527a:	e9 fb fe ff ff       	jmp    8010517a <wait+0x12>
}
8010527f:	c9                   	leave  
80105280:	c3                   	ret    

80105281 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105281:	55                   	push   %ebp
80105282:	89 e5                	mov    %esp,%ebp
80105284:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105287:	e8 d7 f7 ff ff       	call   80104a63 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010528c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105293:	e8 d6 04 00 00       	call   8010576e <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105298:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
8010529f:	eb 61                	jmp    80105302 <scheduler+0x81>
      if(p->state != RUNNABLE)
801052a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a4:	8b 40 0c             	mov    0xc(%eax),%eax
801052a7:	83 f8 03             	cmp    $0x3,%eax
801052aa:	74 02                	je     801052ae <scheduler+0x2d>
        continue;
801052ac:	eb 4d                	jmp    801052fb <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b1:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ba:	89 04 24             	mov    %eax,(%esp)
801052bd:	e8 a6 33 00 00       	call   80108668 <switchuvm>
      p->state = RUNNING;
801052c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c5:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052d2:	8b 40 1c             	mov    0x1c(%eax),%eax
801052d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801052dc:	83 c2 04             	add    $0x4,%edx
801052df:	89 44 24 04          	mov    %eax,0x4(%esp)
801052e3:	89 14 24             	mov    %edx,(%esp)
801052e6:	e8 68 09 00 00       	call   80105c53 <swtch>
      switchkvm();
801052eb:	e8 5b 33 00 00       	call   8010864b <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801052f0:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801052f7:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052fb:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105302:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105309:	72 96                	jb     801052a1 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010530b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105312:	e8 b9 04 00 00       	call   801057d0 <release>

  }
80105317:	e9 6b ff ff ff       	jmp    80105287 <scheduler+0x6>

8010531c <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010531c:	55                   	push   %ebp
8010531d:	89 e5                	mov    %esp,%ebp
8010531f:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105322:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105329:	e8 6a 05 00 00       	call   80105898 <holding>
8010532e:	85 c0                	test   %eax,%eax
80105330:	75 0c                	jne    8010533e <sched+0x22>
    panic("sched ptable.lock");
80105332:	c7 04 24 ab 9f 10 80 	movl   $0x80109fab,(%esp)
80105339:	e8 fc b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
8010533e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105344:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010534a:	83 f8 01             	cmp    $0x1,%eax
8010534d:	74 0c                	je     8010535b <sched+0x3f>
    panic("sched locks");
8010534f:	c7 04 24 bd 9f 10 80 	movl   $0x80109fbd,(%esp)
80105356:	e8 df b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
8010535b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105361:	8b 40 0c             	mov    0xc(%eax),%eax
80105364:	83 f8 04             	cmp    $0x4,%eax
80105367:	75 0c                	jne    80105375 <sched+0x59>
    panic("sched running");
80105369:	c7 04 24 c9 9f 10 80 	movl   $0x80109fc9,(%esp)
80105370:	e8 c5 b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80105375:	e8 d9 f6 ff ff       	call   80104a53 <readeflags>
8010537a:	25 00 02 00 00       	and    $0x200,%eax
8010537f:	85 c0                	test   %eax,%eax
80105381:	74 0c                	je     8010538f <sched+0x73>
    panic("sched interruptible");
80105383:	c7 04 24 d7 9f 10 80 	movl   $0x80109fd7,(%esp)
8010538a:	e8 ab b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
8010538f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105395:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010539b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
8010539e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053a4:	8b 40 04             	mov    0x4(%eax),%eax
801053a7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053ae:	83 c2 1c             	add    $0x1c,%edx
801053b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801053b5:	89 14 24             	mov    %edx,(%esp)
801053b8:	e8 96 08 00 00       	call   80105c53 <swtch>
  cpu->intena = intena;
801053bd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053c6:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053cc:	c9                   	leave  
801053cd:	c3                   	ret    

801053ce <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053ce:	55                   	push   %ebp
801053cf:	89 e5                	mov    %esp,%ebp
801053d1:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801053d4:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801053db:	e8 8e 03 00 00       	call   8010576e <acquire>
  proc->state = RUNNABLE;
801053e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053e6:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801053ed:	e8 2a ff ff ff       	call   8010531c <sched>
  release(&ptable.lock);
801053f2:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801053f9:	e8 d2 03 00 00       	call   801057d0 <release>
}
801053fe:	c9                   	leave  
801053ff:	c3                   	ret    

80105400 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105400:	55                   	push   %ebp
80105401:	89 e5                	mov    %esp,%ebp
80105403:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105406:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010540d:	e8 be 03 00 00       	call   801057d0 <release>

  if (first) {
80105412:	a1 08 d0 10 80       	mov    0x8010d008,%eax
80105417:	85 c0                	test   %eax,%eax
80105419:	74 22                	je     8010543d <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010541b:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
80105422:	00 00 00 
    iinit(ROOTDEV);
80105425:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010542c:	e8 60 c2 ff ff       	call   80101691 <iinit>
    initlog(ROOTDEV);
80105431:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105438:	e8 51 e5 ff ff       	call   8010398e <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010543d:	c9                   	leave  
8010543e:	c3                   	ret    

8010543f <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
8010543f:	55                   	push   %ebp
80105440:	89 e5                	mov    %esp,%ebp
80105442:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105445:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010544b:	85 c0                	test   %eax,%eax
8010544d:	75 0c                	jne    8010545b <sleep+0x1c>
    panic("sleep");
8010544f:	c7 04 24 eb 9f 10 80 	movl   $0x80109feb,(%esp)
80105456:	e8 df b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
8010545b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010545f:	75 0c                	jne    8010546d <sleep+0x2e>
    panic("sleep without lk");
80105461:	c7 04 24 f1 9f 10 80 	movl   $0x80109ff1,(%esp)
80105468:	e8 cd b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010546d:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
80105474:	74 17                	je     8010548d <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105476:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010547d:	e8 ec 02 00 00       	call   8010576e <acquire>
    release(lk);
80105482:	8b 45 0c             	mov    0xc(%ebp),%eax
80105485:	89 04 24             	mov    %eax,(%esp)
80105488:	e8 43 03 00 00       	call   801057d0 <release>
  }

  // Go to sleep.
  proc->chan = chan;
8010548d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105493:	8b 55 08             	mov    0x8(%ebp),%edx
80105496:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105499:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010549f:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054a6:	e8 71 fe ff ff       	call   8010531c <sched>

  // Tidy up.
  proc->chan = 0;
801054ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b1:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054b8:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054bf:	74 17                	je     801054d8 <sleep+0x99>
    release(&ptable.lock);
801054c1:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054c8:	e8 03 03 00 00       	call   801057d0 <release>
    acquire(lk);
801054cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801054d0:	89 04 24             	mov    %eax,(%esp)
801054d3:	e8 96 02 00 00       	call   8010576e <acquire>
  }
}
801054d8:	c9                   	leave  
801054d9:	c3                   	ret    

801054da <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801054da:	55                   	push   %ebp
801054db:	89 e5                	mov    %esp,%ebp
801054dd:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801054e0:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
801054e7:	eb 27                	jmp    80105510 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
801054e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054ec:	8b 40 0c             	mov    0xc(%eax),%eax
801054ef:	83 f8 02             	cmp    $0x2,%eax
801054f2:	75 15                	jne    80105509 <wakeup1+0x2f>
801054f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054f7:	8b 40 20             	mov    0x20(%eax),%eax
801054fa:	3b 45 08             	cmp    0x8(%ebp),%eax
801054fd:	75 0a                	jne    80105509 <wakeup1+0x2f>
      p->state = RUNNABLE;
801054ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105502:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105509:	81 45 fc ec 02 00 00 	addl   $0x2ec,-0x4(%ebp)
80105510:	81 7d fc b4 04 12 80 	cmpl   $0x801204b4,-0x4(%ebp)
80105517:	72 d0                	jb     801054e9 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
80105519:	c9                   	leave  
8010551a:	c3                   	ret    

8010551b <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
8010551b:	55                   	push   %ebp
8010551c:	89 e5                	mov    %esp,%ebp
8010551e:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
80105521:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105528:	e8 41 02 00 00       	call   8010576e <acquire>
    wakeup1(chan);
8010552d:	8b 45 08             	mov    0x8(%ebp),%eax
80105530:	89 04 24             	mov    %eax,(%esp)
80105533:	e8 a2 ff ff ff       	call   801054da <wakeup1>
    release(&ptable.lock);
80105538:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010553f:	e8 8c 02 00 00       	call   801057d0 <release>
  }
80105544:	c9                   	leave  
80105545:	c3                   	ret    

80105546 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
80105546:	55                   	push   %ebp
80105547:	89 e5                	mov    %esp,%ebp
80105549:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
8010554c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105553:	e8 16 02 00 00       	call   8010576e <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105558:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
8010555f:	eb 44                	jmp    801055a5 <kill+0x5f>
      if(p->pid == pid){
80105561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105564:	8b 40 10             	mov    0x10(%eax),%eax
80105567:	3b 45 08             	cmp    0x8(%ebp),%eax
8010556a:	75 32                	jne    8010559e <kill+0x58>
        p->killed = 1;
8010556c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010556f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
80105576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105579:	8b 40 0c             	mov    0xc(%eax),%eax
8010557c:	83 f8 02             	cmp    $0x2,%eax
8010557f:	75 0a                	jne    8010558b <kill+0x45>
          p->state = RUNNABLE;
80105581:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105584:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
8010558b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105592:	e8 39 02 00 00       	call   801057d0 <release>
        return 0;
80105597:	b8 00 00 00 00       	mov    $0x0,%eax
8010559c:	eb 21                	jmp    801055bf <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010559e:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
801055a5:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
801055ac:	72 b3                	jb     80105561 <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801055ae:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055b5:	e8 16 02 00 00       	call   801057d0 <release>
    return -1;
801055ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801055bf:	c9                   	leave  
801055c0:	c3                   	ret    

801055c1 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801055c1:	55                   	push   %ebp
801055c2:	89 e5                	mov    %esp,%ebp
801055c4:	56                   	push   %esi
801055c5:	53                   	push   %ebx
801055c6:	83 ec 60             	sub    $0x60,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055c9:	c7 45 f0 b4 49 11 80 	movl   $0x801149b4,-0x10(%ebp)
801055d0:	e9 24 01 00 00       	jmp    801056f9 <procdump+0x138>
      if(p->state == UNUSED)
801055d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055d8:	8b 40 0c             	mov    0xc(%eax),%eax
801055db:	85 c0                	test   %eax,%eax
801055dd:	75 05                	jne    801055e4 <procdump+0x23>
        continue;
801055df:	e9 0e 01 00 00       	jmp    801056f2 <procdump+0x131>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801055e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055e7:	8b 40 0c             	mov    0xc(%eax),%eax
801055ea:	83 f8 05             	cmp    $0x5,%eax
801055ed:	77 23                	ja     80105612 <procdump+0x51>
801055ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055f2:	8b 40 0c             	mov    0xc(%eax),%eax
801055f5:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
801055fc:	85 c0                	test   %eax,%eax
801055fe:	74 12                	je     80105612 <procdump+0x51>
        state = states[p->state];
80105600:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105603:	8b 40 0c             	mov    0xc(%eax),%eax
80105606:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
8010560d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105610:	eb 07                	jmp    80105619 <procdump+0x58>
      else
        state = "???";
80105612:	c7 45 ec 02 a0 10 80 	movl   $0x8010a002,-0x14(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
80105619:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010561c:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
80105622:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105625:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
8010562b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010562e:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80105634:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105637:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
8010563d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105640:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80105646:	01 c6                	add    %eax,%esi
80105648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010564b:	8b 40 10             	mov    0x10(%eax),%eax
8010564e:	89 5c 24 18          	mov    %ebx,0x18(%esp)
80105652:	89 4c 24 14          	mov    %ecx,0x14(%esp)
80105656:	89 54 24 10          	mov    %edx,0x10(%esp)
8010565a:	89 74 24 0c          	mov    %esi,0xc(%esp)
8010565e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105661:	89 54 24 08          	mov    %edx,0x8(%esp)
80105665:	89 44 24 04          	mov    %eax,0x4(%esp)
80105669:	c7 04 24 06 a0 10 80 	movl   $0x8010a006,(%esp)
80105670:	e8 2b ad ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
80105675:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105678:	83 c0 6c             	add    $0x6c,%eax
8010567b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010567f:	c7 04 24 19 a0 10 80 	movl   $0x8010a019,(%esp)
80105686:	e8 15 ad ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
8010568b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010568e:	8b 40 0c             	mov    0xc(%eax),%eax
80105691:	83 f8 02             	cmp    $0x2,%eax
80105694:	75 50                	jne    801056e6 <procdump+0x125>
        getcallerpcs((uint*)p->context->ebp+2, pc);
80105696:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105699:	8b 40 1c             	mov    0x1c(%eax),%eax
8010569c:	8b 40 0c             	mov    0xc(%eax),%eax
8010569f:	83 c0 08             	add    $0x8,%eax
801056a2:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801056a5:	89 54 24 04          	mov    %edx,0x4(%esp)
801056a9:	89 04 24             	mov    %eax,(%esp)
801056ac:	e8 6e 01 00 00       	call   8010581f <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801056b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056b8:	eb 1b                	jmp    801056d5 <procdump+0x114>
          cprintf(" %p", pc[i]);
801056ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056bd:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801056c5:	c7 04 24 1c a0 10 80 	movl   $0x8010a01c,(%esp)
801056cc:	e8 cf ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
801056d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056d5:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801056d9:	7f 0b                	jg     801056e6 <procdump+0x125>
801056db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056de:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056e2:	85 c0                	test   %eax,%eax
801056e4:	75 d4                	jne    801056ba <procdump+0xf9>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
801056e6:	c7 04 24 20 a0 10 80 	movl   $0x8010a020,(%esp)
801056ed:	e8 ae ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801056f2:	81 45 f0 ec 02 00 00 	addl   $0x2ec,-0x10(%ebp)
801056f9:	81 7d f0 b4 04 12 80 	cmpl   $0x801204b4,-0x10(%ebp)
80105700:	0f 82 cf fe ff ff    	jb     801055d5 <procdump+0x14>
      }
      cprintf("\n");
    }
    //float fra = countPages()/numOfInitializedPages; 
    //cprintf("%d free pages in the system\n",countPages()*100/numOfInitializedPages);
  }
80105706:	83 c4 60             	add    $0x60,%esp
80105709:	5b                   	pop    %ebx
8010570a:	5e                   	pop    %esi
8010570b:	5d                   	pop    %ebp
8010570c:	c3                   	ret    

8010570d <getPid>:

int
getPid(){
8010570d:	55                   	push   %ebp
8010570e:	89 e5                	mov    %esp,%ebp
  return afterInit;
80105710:	a1 48 d6 10 80       	mov    0x8010d648,%eax
80105715:	5d                   	pop    %ebp
80105716:	c3                   	ret    

80105717 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105717:	55                   	push   %ebp
80105718:	89 e5                	mov    %esp,%ebp
8010571a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010571d:	9c                   	pushf  
8010571e:	58                   	pop    %eax
8010571f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105722:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105725:	c9                   	leave  
80105726:	c3                   	ret    

80105727 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105727:	55                   	push   %ebp
80105728:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010572a:	fa                   	cli    
}
8010572b:	5d                   	pop    %ebp
8010572c:	c3                   	ret    

8010572d <sti>:

static inline void
sti(void)
{
8010572d:	55                   	push   %ebp
8010572e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105730:	fb                   	sti    
}
80105731:	5d                   	pop    %ebp
80105732:	c3                   	ret    

80105733 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105733:	55                   	push   %ebp
80105734:	89 e5                	mov    %esp,%ebp
80105736:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105739:	8b 55 08             	mov    0x8(%ebp),%edx
8010573c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010573f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105742:	f0 87 02             	lock xchg %eax,(%edx)
80105745:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105748:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010574b:	c9                   	leave  
8010574c:	c3                   	ret    

8010574d <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
8010574d:	55                   	push   %ebp
8010574e:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105750:	8b 45 08             	mov    0x8(%ebp),%eax
80105753:	8b 55 0c             	mov    0xc(%ebp),%edx
80105756:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105759:	8b 45 08             	mov    0x8(%ebp),%eax
8010575c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105762:	8b 45 08             	mov    0x8(%ebp),%eax
80105765:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010576c:	5d                   	pop    %ebp
8010576d:	c3                   	ret    

8010576e <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010576e:	55                   	push   %ebp
8010576f:	89 e5                	mov    %esp,%ebp
80105771:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105774:	e8 49 01 00 00       	call   801058c2 <pushcli>
  if(holding(lk))
80105779:	8b 45 08             	mov    0x8(%ebp),%eax
8010577c:	89 04 24             	mov    %eax,(%esp)
8010577f:	e8 14 01 00 00       	call   80105898 <holding>
80105784:	85 c0                	test   %eax,%eax
80105786:	74 0c                	je     80105794 <acquire+0x26>
    panic("acquire");
80105788:	c7 04 24 4c a0 10 80 	movl   $0x8010a04c,(%esp)
8010578f:	e8 a6 ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105794:	90                   	nop
80105795:	8b 45 08             	mov    0x8(%ebp),%eax
80105798:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010579f:	00 
801057a0:	89 04 24             	mov    %eax,(%esp)
801057a3:	e8 8b ff ff ff       	call   80105733 <xchg>
801057a8:	85 c0                	test   %eax,%eax
801057aa:	75 e9                	jne    80105795 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801057ac:	8b 45 08             	mov    0x8(%ebp),%eax
801057af:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801057b6:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801057b9:	8b 45 08             	mov    0x8(%ebp),%eax
801057bc:	83 c0 0c             	add    $0xc,%eax
801057bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801057c3:	8d 45 08             	lea    0x8(%ebp),%eax
801057c6:	89 04 24             	mov    %eax,(%esp)
801057c9:	e8 51 00 00 00       	call   8010581f <getcallerpcs>
}
801057ce:	c9                   	leave  
801057cf:	c3                   	ret    

801057d0 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801057d0:	55                   	push   %ebp
801057d1:	89 e5                	mov    %esp,%ebp
801057d3:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801057d6:	8b 45 08             	mov    0x8(%ebp),%eax
801057d9:	89 04 24             	mov    %eax,(%esp)
801057dc:	e8 b7 00 00 00       	call   80105898 <holding>
801057e1:	85 c0                	test   %eax,%eax
801057e3:	75 0c                	jne    801057f1 <release+0x21>
    panic("release");
801057e5:	c7 04 24 54 a0 10 80 	movl   $0x8010a054,(%esp)
801057ec:	e8 49 ad ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
801057f1:	8b 45 08             	mov    0x8(%ebp),%eax
801057f4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801057fb:	8b 45 08             	mov    0x8(%ebp),%eax
801057fe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105805:	8b 45 08             	mov    0x8(%ebp),%eax
80105808:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010580f:	00 
80105810:	89 04 24             	mov    %eax,(%esp)
80105813:	e8 1b ff ff ff       	call   80105733 <xchg>

  popcli();
80105818:	e8 e9 00 00 00       	call   80105906 <popcli>
}
8010581d:	c9                   	leave  
8010581e:	c3                   	ret    

8010581f <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010581f:	55                   	push   %ebp
80105820:	89 e5                	mov    %esp,%ebp
80105822:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105825:	8b 45 08             	mov    0x8(%ebp),%eax
80105828:	83 e8 08             	sub    $0x8,%eax
8010582b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010582e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105835:	eb 38                	jmp    8010586f <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105837:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010583b:	74 38                	je     80105875 <getcallerpcs+0x56>
8010583d:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105844:	76 2f                	jbe    80105875 <getcallerpcs+0x56>
80105846:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010584a:	74 29                	je     80105875 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010584c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010584f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105856:	8b 45 0c             	mov    0xc(%ebp),%eax
80105859:	01 c2                	add    %eax,%edx
8010585b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010585e:	8b 40 04             	mov    0x4(%eax),%eax
80105861:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105863:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105866:	8b 00                	mov    (%eax),%eax
80105868:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010586b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010586f:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105873:	7e c2                	jle    80105837 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105875:	eb 19                	jmp    80105890 <getcallerpcs+0x71>
    pcs[i] = 0;
80105877:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010587a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105881:	8b 45 0c             	mov    0xc(%ebp),%eax
80105884:	01 d0                	add    %edx,%eax
80105886:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010588c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105890:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105894:	7e e1                	jle    80105877 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105896:	c9                   	leave  
80105897:	c3                   	ret    

80105898 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105898:	55                   	push   %ebp
80105899:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
8010589b:	8b 45 08             	mov    0x8(%ebp),%eax
8010589e:	8b 00                	mov    (%eax),%eax
801058a0:	85 c0                	test   %eax,%eax
801058a2:	74 17                	je     801058bb <holding+0x23>
801058a4:	8b 45 08             	mov    0x8(%ebp),%eax
801058a7:	8b 50 08             	mov    0x8(%eax),%edx
801058aa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058b0:	39 c2                	cmp    %eax,%edx
801058b2:	75 07                	jne    801058bb <holding+0x23>
801058b4:	b8 01 00 00 00       	mov    $0x1,%eax
801058b9:	eb 05                	jmp    801058c0 <holding+0x28>
801058bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058c0:	5d                   	pop    %ebp
801058c1:	c3                   	ret    

801058c2 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801058c2:	55                   	push   %ebp
801058c3:	89 e5                	mov    %esp,%ebp
801058c5:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801058c8:	e8 4a fe ff ff       	call   80105717 <readeflags>
801058cd:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801058d0:	e8 52 fe ff ff       	call   80105727 <cli>
  if(cpu->ncli++ == 0)
801058d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801058dc:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801058e2:	8d 48 01             	lea    0x1(%eax),%ecx
801058e5:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
801058eb:	85 c0                	test   %eax,%eax
801058ed:	75 15                	jne    80105904 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
801058ef:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058f5:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058f8:	81 e2 00 02 00 00    	and    $0x200,%edx
801058fe:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105904:	c9                   	leave  
80105905:	c3                   	ret    

80105906 <popcli>:

void
popcli(void)
{
80105906:	55                   	push   %ebp
80105907:	89 e5                	mov    %esp,%ebp
80105909:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010590c:	e8 06 fe ff ff       	call   80105717 <readeflags>
80105911:	25 00 02 00 00       	and    $0x200,%eax
80105916:	85 c0                	test   %eax,%eax
80105918:	74 0c                	je     80105926 <popcli+0x20>
    panic("popcli - interruptible");
8010591a:	c7 04 24 5c a0 10 80 	movl   $0x8010a05c,(%esp)
80105921:	e8 14 ac ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105926:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010592c:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105932:	83 ea 01             	sub    $0x1,%edx
80105935:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010593b:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105941:	85 c0                	test   %eax,%eax
80105943:	79 0c                	jns    80105951 <popcli+0x4b>
    panic("popcli");
80105945:	c7 04 24 73 a0 10 80 	movl   $0x8010a073,(%esp)
8010594c:	e8 e9 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105951:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105957:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010595d:	85 c0                	test   %eax,%eax
8010595f:	75 15                	jne    80105976 <popcli+0x70>
80105961:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105967:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010596d:	85 c0                	test   %eax,%eax
8010596f:	74 05                	je     80105976 <popcli+0x70>
    sti();
80105971:	e8 b7 fd ff ff       	call   8010572d <sti>
}
80105976:	c9                   	leave  
80105977:	c3                   	ret    

80105978 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105978:	55                   	push   %ebp
80105979:	89 e5                	mov    %esp,%ebp
8010597b:	57                   	push   %edi
8010597c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
8010597d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105980:	8b 55 10             	mov    0x10(%ebp),%edx
80105983:	8b 45 0c             	mov    0xc(%ebp),%eax
80105986:	89 cb                	mov    %ecx,%ebx
80105988:	89 df                	mov    %ebx,%edi
8010598a:	89 d1                	mov    %edx,%ecx
8010598c:	fc                   	cld    
8010598d:	f3 aa                	rep stos %al,%es:(%edi)
8010598f:	89 ca                	mov    %ecx,%edx
80105991:	89 fb                	mov    %edi,%ebx
80105993:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105996:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105999:	5b                   	pop    %ebx
8010599a:	5f                   	pop    %edi
8010599b:	5d                   	pop    %ebp
8010599c:	c3                   	ret    

8010599d <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
8010599d:	55                   	push   %ebp
8010599e:	89 e5                	mov    %esp,%ebp
801059a0:	57                   	push   %edi
801059a1:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801059a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059a5:	8b 55 10             	mov    0x10(%ebp),%edx
801059a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ab:	89 cb                	mov    %ecx,%ebx
801059ad:	89 df                	mov    %ebx,%edi
801059af:	89 d1                	mov    %edx,%ecx
801059b1:	fc                   	cld    
801059b2:	f3 ab                	rep stos %eax,%es:(%edi)
801059b4:	89 ca                	mov    %ecx,%edx
801059b6:	89 fb                	mov    %edi,%ebx
801059b8:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059bb:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059be:	5b                   	pop    %ebx
801059bf:	5f                   	pop    %edi
801059c0:	5d                   	pop    %ebp
801059c1:	c3                   	ret    

801059c2 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801059c2:	55                   	push   %ebp
801059c3:	89 e5                	mov    %esp,%ebp
801059c5:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801059c8:	8b 45 08             	mov    0x8(%ebp),%eax
801059cb:	83 e0 03             	and    $0x3,%eax
801059ce:	85 c0                	test   %eax,%eax
801059d0:	75 49                	jne    80105a1b <memset+0x59>
801059d2:	8b 45 10             	mov    0x10(%ebp),%eax
801059d5:	83 e0 03             	and    $0x3,%eax
801059d8:	85 c0                	test   %eax,%eax
801059da:	75 3f                	jne    80105a1b <memset+0x59>
    c &= 0xFF;
801059dc:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801059e3:	8b 45 10             	mov    0x10(%ebp),%eax
801059e6:	c1 e8 02             	shr    $0x2,%eax
801059e9:	89 c2                	mov    %eax,%edx
801059eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ee:	c1 e0 18             	shl    $0x18,%eax
801059f1:	89 c1                	mov    %eax,%ecx
801059f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801059f6:	c1 e0 10             	shl    $0x10,%eax
801059f9:	09 c1                	or     %eax,%ecx
801059fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801059fe:	c1 e0 08             	shl    $0x8,%eax
80105a01:	09 c8                	or     %ecx,%eax
80105a03:	0b 45 0c             	or     0xc(%ebp),%eax
80105a06:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80105a11:	89 04 24             	mov    %eax,(%esp)
80105a14:	e8 84 ff ff ff       	call   8010599d <stosl>
80105a19:	eb 19                	jmp    80105a34 <memset+0x72>
  } else
    stosb(dst, c, n);
80105a1b:	8b 45 10             	mov    0x10(%ebp),%eax
80105a1e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a22:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a25:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a29:	8b 45 08             	mov    0x8(%ebp),%eax
80105a2c:	89 04 24             	mov    %eax,(%esp)
80105a2f:	e8 44 ff ff ff       	call   80105978 <stosb>
  return dst;
80105a34:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a37:	c9                   	leave  
80105a38:	c3                   	ret    

80105a39 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a39:	55                   	push   %ebp
80105a3a:	89 e5                	mov    %esp,%ebp
80105a3c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a42:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a45:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a48:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a4b:	eb 30                	jmp    80105a7d <memcmp+0x44>
    if(*s1 != *s2)
80105a4d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a50:	0f b6 10             	movzbl (%eax),%edx
80105a53:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a56:	0f b6 00             	movzbl (%eax),%eax
80105a59:	38 c2                	cmp    %al,%dl
80105a5b:	74 18                	je     80105a75 <memcmp+0x3c>
      return *s1 - *s2;
80105a5d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a60:	0f b6 00             	movzbl (%eax),%eax
80105a63:	0f b6 d0             	movzbl %al,%edx
80105a66:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a69:	0f b6 00             	movzbl (%eax),%eax
80105a6c:	0f b6 c0             	movzbl %al,%eax
80105a6f:	29 c2                	sub    %eax,%edx
80105a71:	89 d0                	mov    %edx,%eax
80105a73:	eb 1a                	jmp    80105a8f <memcmp+0x56>
    s1++, s2++;
80105a75:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a79:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105a7d:	8b 45 10             	mov    0x10(%ebp),%eax
80105a80:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a83:	89 55 10             	mov    %edx,0x10(%ebp)
80105a86:	85 c0                	test   %eax,%eax
80105a88:	75 c3                	jne    80105a4d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105a8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a8f:	c9                   	leave  
80105a90:	c3                   	ret    

80105a91 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105a91:	55                   	push   %ebp
80105a92:	89 e5                	mov    %esp,%ebp
80105a94:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105a97:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a9a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105a9d:	8b 45 08             	mov    0x8(%ebp),%eax
80105aa0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105aa3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105aa9:	73 3d                	jae    80105ae8 <memmove+0x57>
80105aab:	8b 45 10             	mov    0x10(%ebp),%eax
80105aae:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ab1:	01 d0                	add    %edx,%eax
80105ab3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105ab6:	76 30                	jbe    80105ae8 <memmove+0x57>
    s += n;
80105ab8:	8b 45 10             	mov    0x10(%ebp),%eax
80105abb:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105abe:	8b 45 10             	mov    0x10(%ebp),%eax
80105ac1:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105ac4:	eb 13                	jmp    80105ad9 <memmove+0x48>
      *--d = *--s;
80105ac6:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105aca:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105ace:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ad1:	0f b6 10             	movzbl (%eax),%edx
80105ad4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ad7:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105ad9:	8b 45 10             	mov    0x10(%ebp),%eax
80105adc:	8d 50 ff             	lea    -0x1(%eax),%edx
80105adf:	89 55 10             	mov    %edx,0x10(%ebp)
80105ae2:	85 c0                	test   %eax,%eax
80105ae4:	75 e0                	jne    80105ac6 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105ae6:	eb 26                	jmp    80105b0e <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105ae8:	eb 17                	jmp    80105b01 <memmove+0x70>
      *d++ = *s++;
80105aea:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105aed:	8d 50 01             	lea    0x1(%eax),%edx
80105af0:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105af3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105af6:	8d 4a 01             	lea    0x1(%edx),%ecx
80105af9:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105afc:	0f b6 12             	movzbl (%edx),%edx
80105aff:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b01:	8b 45 10             	mov    0x10(%ebp),%eax
80105b04:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b07:	89 55 10             	mov    %edx,0x10(%ebp)
80105b0a:	85 c0                	test   %eax,%eax
80105b0c:	75 dc                	jne    80105aea <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b0e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b11:	c9                   	leave  
80105b12:	c3                   	ret    

80105b13 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b13:	55                   	push   %ebp
80105b14:	89 e5                	mov    %esp,%ebp
80105b16:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b19:	8b 45 10             	mov    0x10(%ebp),%eax
80105b1c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b20:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b23:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b27:	8b 45 08             	mov    0x8(%ebp),%eax
80105b2a:	89 04 24             	mov    %eax,(%esp)
80105b2d:	e8 5f ff ff ff       	call   80105a91 <memmove>
}
80105b32:	c9                   	leave  
80105b33:	c3                   	ret    

80105b34 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b34:	55                   	push   %ebp
80105b35:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b37:	eb 0c                	jmp    80105b45 <strncmp+0x11>
    n--, p++, q++;
80105b39:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b3d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b41:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b45:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b49:	74 1a                	je     80105b65 <strncmp+0x31>
80105b4b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b4e:	0f b6 00             	movzbl (%eax),%eax
80105b51:	84 c0                	test   %al,%al
80105b53:	74 10                	je     80105b65 <strncmp+0x31>
80105b55:	8b 45 08             	mov    0x8(%ebp),%eax
80105b58:	0f b6 10             	movzbl (%eax),%edx
80105b5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b5e:	0f b6 00             	movzbl (%eax),%eax
80105b61:	38 c2                	cmp    %al,%dl
80105b63:	74 d4                	je     80105b39 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105b65:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b69:	75 07                	jne    80105b72 <strncmp+0x3e>
    return 0;
80105b6b:	b8 00 00 00 00       	mov    $0x0,%eax
80105b70:	eb 16                	jmp    80105b88 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105b72:	8b 45 08             	mov    0x8(%ebp),%eax
80105b75:	0f b6 00             	movzbl (%eax),%eax
80105b78:	0f b6 d0             	movzbl %al,%edx
80105b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b7e:	0f b6 00             	movzbl (%eax),%eax
80105b81:	0f b6 c0             	movzbl %al,%eax
80105b84:	29 c2                	sub    %eax,%edx
80105b86:	89 d0                	mov    %edx,%eax
}
80105b88:	5d                   	pop    %ebp
80105b89:	c3                   	ret    

80105b8a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105b8a:	55                   	push   %ebp
80105b8b:	89 e5                	mov    %esp,%ebp
80105b8d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105b90:	8b 45 08             	mov    0x8(%ebp),%eax
80105b93:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105b96:	90                   	nop
80105b97:	8b 45 10             	mov    0x10(%ebp),%eax
80105b9a:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b9d:	89 55 10             	mov    %edx,0x10(%ebp)
80105ba0:	85 c0                	test   %eax,%eax
80105ba2:	7e 1e                	jle    80105bc2 <strncpy+0x38>
80105ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ba7:	8d 50 01             	lea    0x1(%eax),%edx
80105baa:	89 55 08             	mov    %edx,0x8(%ebp)
80105bad:	8b 55 0c             	mov    0xc(%ebp),%edx
80105bb0:	8d 4a 01             	lea    0x1(%edx),%ecx
80105bb3:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105bb6:	0f b6 12             	movzbl (%edx),%edx
80105bb9:	88 10                	mov    %dl,(%eax)
80105bbb:	0f b6 00             	movzbl (%eax),%eax
80105bbe:	84 c0                	test   %al,%al
80105bc0:	75 d5                	jne    80105b97 <strncpy+0xd>
    ;
  while(n-- > 0)
80105bc2:	eb 0c                	jmp    80105bd0 <strncpy+0x46>
    *s++ = 0;
80105bc4:	8b 45 08             	mov    0x8(%ebp),%eax
80105bc7:	8d 50 01             	lea    0x1(%eax),%edx
80105bca:	89 55 08             	mov    %edx,0x8(%ebp)
80105bcd:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105bd0:	8b 45 10             	mov    0x10(%ebp),%eax
80105bd3:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bd6:	89 55 10             	mov    %edx,0x10(%ebp)
80105bd9:	85 c0                	test   %eax,%eax
80105bdb:	7f e7                	jg     80105bc4 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105bdd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105be0:	c9                   	leave  
80105be1:	c3                   	ret    

80105be2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105be2:	55                   	push   %ebp
80105be3:	89 e5                	mov    %esp,%ebp
80105be5:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105be8:	8b 45 08             	mov    0x8(%ebp),%eax
80105beb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105bee:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bf2:	7f 05                	jg     80105bf9 <safestrcpy+0x17>
    return os;
80105bf4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bf7:	eb 31                	jmp    80105c2a <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105bf9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105bfd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c01:	7e 1e                	jle    80105c21 <safestrcpy+0x3f>
80105c03:	8b 45 08             	mov    0x8(%ebp),%eax
80105c06:	8d 50 01             	lea    0x1(%eax),%edx
80105c09:	89 55 08             	mov    %edx,0x8(%ebp)
80105c0c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c0f:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c12:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c15:	0f b6 12             	movzbl (%edx),%edx
80105c18:	88 10                	mov    %dl,(%eax)
80105c1a:	0f b6 00             	movzbl (%eax),%eax
80105c1d:	84 c0                	test   %al,%al
80105c1f:	75 d8                	jne    80105bf9 <safestrcpy+0x17>
    ;
  *s = 0;
80105c21:	8b 45 08             	mov    0x8(%ebp),%eax
80105c24:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c27:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c2a:	c9                   	leave  
80105c2b:	c3                   	ret    

80105c2c <strlen>:

int
strlen(const char *s)
{
80105c2c:	55                   	push   %ebp
80105c2d:	89 e5                	mov    %esp,%ebp
80105c2f:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c32:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c39:	eb 04                	jmp    80105c3f <strlen+0x13>
80105c3b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c3f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c42:	8b 45 08             	mov    0x8(%ebp),%eax
80105c45:	01 d0                	add    %edx,%eax
80105c47:	0f b6 00             	movzbl (%eax),%eax
80105c4a:	84 c0                	test   %al,%al
80105c4c:	75 ed                	jne    80105c3b <strlen+0xf>
    ;
  return n;
80105c4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c51:	c9                   	leave  
80105c52:	c3                   	ret    

80105c53 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c53:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c57:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105c5b:	55                   	push   %ebp
  pushl %ebx
80105c5c:	53                   	push   %ebx
  pushl %esi
80105c5d:	56                   	push   %esi
  pushl %edi
80105c5e:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105c5f:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105c61:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105c63:	5f                   	pop    %edi
  popl %esi
80105c64:	5e                   	pop    %esi
  popl %ebx
80105c65:	5b                   	pop    %ebx
  popl %ebp
80105c66:	5d                   	pop    %ebp
  ret
80105c67:	c3                   	ret    

80105c68 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105c68:	55                   	push   %ebp
80105c69:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105c6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c71:	8b 00                	mov    (%eax),%eax
80105c73:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c76:	76 12                	jbe    80105c8a <fetchint+0x22>
80105c78:	8b 45 08             	mov    0x8(%ebp),%eax
80105c7b:	8d 50 04             	lea    0x4(%eax),%edx
80105c7e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c84:	8b 00                	mov    (%eax),%eax
80105c86:	39 c2                	cmp    %eax,%edx
80105c88:	76 07                	jbe    80105c91 <fetchint+0x29>
    return -1;
80105c8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c8f:	eb 0f                	jmp    80105ca0 <fetchint+0x38>
  *ip = *(int*)(addr);
80105c91:	8b 45 08             	mov    0x8(%ebp),%eax
80105c94:	8b 10                	mov    (%eax),%edx
80105c96:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c99:	89 10                	mov    %edx,(%eax)
  return 0;
80105c9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ca0:	5d                   	pop    %ebp
80105ca1:	c3                   	ret    

80105ca2 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105ca2:	55                   	push   %ebp
80105ca3:	89 e5                	mov    %esp,%ebp
80105ca5:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105ca8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cae:	8b 00                	mov    (%eax),%eax
80105cb0:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cb3:	77 07                	ja     80105cbc <fetchstr+0x1a>
    return -1;
80105cb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cba:	eb 46                	jmp    80105d02 <fetchstr+0x60>
  *pp = (char*)addr;
80105cbc:	8b 55 08             	mov    0x8(%ebp),%edx
80105cbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cc2:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105cc4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cca:	8b 00                	mov    (%eax),%eax
80105ccc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105ccf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cd2:	8b 00                	mov    (%eax),%eax
80105cd4:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105cd7:	eb 1c                	jmp    80105cf5 <fetchstr+0x53>
    if(*s == 0)
80105cd9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cdc:	0f b6 00             	movzbl (%eax),%eax
80105cdf:	84 c0                	test   %al,%al
80105ce1:	75 0e                	jne    80105cf1 <fetchstr+0x4f>
      return s - *pp;
80105ce3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ce6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce9:	8b 00                	mov    (%eax),%eax
80105ceb:	29 c2                	sub    %eax,%edx
80105ced:	89 d0                	mov    %edx,%eax
80105cef:	eb 11                	jmp    80105d02 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105cf1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105cf5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cf8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105cfb:	72 dc                	jb     80105cd9 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105cfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d02:	c9                   	leave  
80105d03:	c3                   	ret    

80105d04 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d04:	55                   	push   %ebp
80105d05:	89 e5                	mov    %esp,%ebp
80105d07:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d10:	8b 40 18             	mov    0x18(%eax),%eax
80105d13:	8b 50 44             	mov    0x44(%eax),%edx
80105d16:	8b 45 08             	mov    0x8(%ebp),%eax
80105d19:	c1 e0 02             	shl    $0x2,%eax
80105d1c:	01 d0                	add    %edx,%eax
80105d1e:	8d 50 04             	lea    0x4(%eax),%edx
80105d21:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d24:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d28:	89 14 24             	mov    %edx,(%esp)
80105d2b:	e8 38 ff ff ff       	call   80105c68 <fetchint>
}
80105d30:	c9                   	leave  
80105d31:	c3                   	ret    

80105d32 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d32:	55                   	push   %ebp
80105d33:	89 e5                	mov    %esp,%ebp
80105d35:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d38:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105d42:	89 04 24             	mov    %eax,(%esp)
80105d45:	e8 ba ff ff ff       	call   80105d04 <argint>
80105d4a:	85 c0                	test   %eax,%eax
80105d4c:	79 07                	jns    80105d55 <argptr+0x23>
    return -1;
80105d4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d53:	eb 3d                	jmp    80105d92 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d55:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d58:	89 c2                	mov    %eax,%edx
80105d5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d60:	8b 00                	mov    (%eax),%eax
80105d62:	39 c2                	cmp    %eax,%edx
80105d64:	73 16                	jae    80105d7c <argptr+0x4a>
80105d66:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d69:	89 c2                	mov    %eax,%edx
80105d6b:	8b 45 10             	mov    0x10(%ebp),%eax
80105d6e:	01 c2                	add    %eax,%edx
80105d70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d76:	8b 00                	mov    (%eax),%eax
80105d78:	39 c2                	cmp    %eax,%edx
80105d7a:	76 07                	jbe    80105d83 <argptr+0x51>
    return -1;
80105d7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d81:	eb 0f                	jmp    80105d92 <argptr+0x60>
  *pp = (char*)i;
80105d83:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d86:	89 c2                	mov    %eax,%edx
80105d88:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d8b:	89 10                	mov    %edx,(%eax)
  return 0;
80105d8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d92:	c9                   	leave  
80105d93:	c3                   	ret    

80105d94 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105d94:	55                   	push   %ebp
80105d95:	89 e5                	mov    %esp,%ebp
80105d97:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105d9a:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105da1:	8b 45 08             	mov    0x8(%ebp),%eax
80105da4:	89 04 24             	mov    %eax,(%esp)
80105da7:	e8 58 ff ff ff       	call   80105d04 <argint>
80105dac:	85 c0                	test   %eax,%eax
80105dae:	79 07                	jns    80105db7 <argstr+0x23>
    return -1;
80105db0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105db5:	eb 12                	jmp    80105dc9 <argstr+0x35>
  return fetchstr(addr, pp);
80105db7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dba:	8b 55 0c             	mov    0xc(%ebp),%edx
80105dbd:	89 54 24 04          	mov    %edx,0x4(%esp)
80105dc1:	89 04 24             	mov    %eax,(%esp)
80105dc4:	e8 d9 fe ff ff       	call   80105ca2 <fetchstr>
}
80105dc9:	c9                   	leave  
80105dca:	c3                   	ret    

80105dcb <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105dcb:	55                   	push   %ebp
80105dcc:	89 e5                	mov    %esp,%ebp
80105dce:	53                   	push   %ebx
80105dcf:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105dd2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dd8:	8b 40 18             	mov    0x18(%eax),%eax
80105ddb:	8b 40 1c             	mov    0x1c(%eax),%eax
80105dde:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105de1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105de5:	7e 30                	jle    80105e17 <syscall+0x4c>
80105de7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dea:	83 f8 15             	cmp    $0x15,%eax
80105ded:	77 28                	ja     80105e17 <syscall+0x4c>
80105def:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105df2:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105df9:	85 c0                	test   %eax,%eax
80105dfb:	74 1a                	je     80105e17 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105dfd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e03:	8b 58 18             	mov    0x18(%eax),%ebx
80105e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e09:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e10:	ff d0                	call   *%eax
80105e12:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e15:	eb 3d                	jmp    80105e54 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e1d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e26:	8b 40 10             	mov    0x10(%eax),%eax
80105e29:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e2c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e30:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e34:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e38:	c7 04 24 7a a0 10 80 	movl   $0x8010a07a,(%esp)
80105e3f:	e8 5c a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e4a:	8b 40 18             	mov    0x18(%eax),%eax
80105e4d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e54:	83 c4 24             	add    $0x24,%esp
80105e57:	5b                   	pop    %ebx
80105e58:	5d                   	pop    %ebp
80105e59:	c3                   	ret    

80105e5a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105e5a:	55                   	push   %ebp
80105e5b:	89 e5                	mov    %esp,%ebp
80105e5d:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105e60:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e63:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e67:	8b 45 08             	mov    0x8(%ebp),%eax
80105e6a:	89 04 24             	mov    %eax,(%esp)
80105e6d:	e8 92 fe ff ff       	call   80105d04 <argint>
80105e72:	85 c0                	test   %eax,%eax
80105e74:	79 07                	jns    80105e7d <argfd+0x23>
    return -1;
80105e76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e7b:	eb 50                	jmp    80105ecd <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105e7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e80:	85 c0                	test   %eax,%eax
80105e82:	78 21                	js     80105ea5 <argfd+0x4b>
80105e84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e87:	83 f8 0f             	cmp    $0xf,%eax
80105e8a:	7f 19                	jg     80105ea5 <argfd+0x4b>
80105e8c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e92:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105e95:	83 c2 08             	add    $0x8,%edx
80105e98:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105e9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e9f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ea3:	75 07                	jne    80105eac <argfd+0x52>
    return -1;
80105ea5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eaa:	eb 21                	jmp    80105ecd <argfd+0x73>
  if(pfd)
80105eac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105eb0:	74 08                	je     80105eba <argfd+0x60>
    *pfd = fd;
80105eb2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105eb8:	89 10                	mov    %edx,(%eax)
  if(pf)
80105eba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ebe:	74 08                	je     80105ec8 <argfd+0x6e>
    *pf = f;
80105ec0:	8b 45 10             	mov    0x10(%ebp),%eax
80105ec3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ec6:	89 10                	mov    %edx,(%eax)
  return 0;
80105ec8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ecd:	c9                   	leave  
80105ece:	c3                   	ret    

80105ecf <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105ecf:	55                   	push   %ebp
80105ed0:	89 e5                	mov    %esp,%ebp
80105ed2:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105ed5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105edc:	eb 30                	jmp    80105f0e <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105ede:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ee4:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ee7:	83 c2 08             	add    $0x8,%edx
80105eea:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105eee:	85 c0                	test   %eax,%eax
80105ef0:	75 18                	jne    80105f0a <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105ef2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ef8:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105efb:	8d 4a 08             	lea    0x8(%edx),%ecx
80105efe:	8b 55 08             	mov    0x8(%ebp),%edx
80105f01:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f05:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f08:	eb 0f                	jmp    80105f19 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f0a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f0e:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f12:	7e ca                	jle    80105ede <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f19:	c9                   	leave  
80105f1a:	c3                   	ret    

80105f1b <sys_dup>:

int
sys_dup(void)
{
80105f1b:	55                   	push   %ebp
80105f1c:	89 e5                	mov    %esp,%ebp
80105f1e:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f21:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f24:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f2f:	00 
80105f30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f37:	e8 1e ff ff ff       	call   80105e5a <argfd>
80105f3c:	85 c0                	test   %eax,%eax
80105f3e:	79 07                	jns    80105f47 <sys_dup+0x2c>
    return -1;
80105f40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f45:	eb 29                	jmp    80105f70 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4a:	89 04 24             	mov    %eax,(%esp)
80105f4d:	e8 7d ff ff ff       	call   80105ecf <fdalloc>
80105f52:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f55:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f59:	79 07                	jns    80105f62 <sys_dup+0x47>
    return -1;
80105f5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f60:	eb 0e                	jmp    80105f70 <sys_dup+0x55>
  filedup(f);
80105f62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f65:	89 04 24             	mov    %eax,(%esp)
80105f68:	e8 19 b1 ff ff       	call   80101086 <filedup>
  return fd;
80105f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105f70:	c9                   	leave  
80105f71:	c3                   	ret    

80105f72 <sys_read>:

int
sys_read(void)
{
80105f72:	55                   	push   %ebp
80105f73:	89 e5                	mov    %esp,%ebp
80105f75:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105f78:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f7b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f86:	00 
80105f87:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f8e:	e8 c7 fe ff ff       	call   80105e5a <argfd>
80105f93:	85 c0                	test   %eax,%eax
80105f95:	78 35                	js     80105fcc <sys_read+0x5a>
80105f97:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f9e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105fa5:	e8 5a fd ff ff       	call   80105d04 <argint>
80105faa:	85 c0                	test   %eax,%eax
80105fac:	78 1e                	js     80105fcc <sys_read+0x5a>
80105fae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb1:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fb5:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fb8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fbc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105fc3:	e8 6a fd ff ff       	call   80105d32 <argptr>
80105fc8:	85 c0                	test   %eax,%eax
80105fca:	79 07                	jns    80105fd3 <sys_read+0x61>
    return -1;
80105fcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fd1:	eb 19                	jmp    80105fec <sys_read+0x7a>
  return fileread(f, p, n);
80105fd3:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105fd6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fdc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105fe0:	89 54 24 04          	mov    %edx,0x4(%esp)
80105fe4:	89 04 24             	mov    %eax,(%esp)
80105fe7:	e8 07 b2 ff ff       	call   801011f3 <fileread>
}
80105fec:	c9                   	leave  
80105fed:	c3                   	ret    

80105fee <sys_write>:

int
sys_write(void)
{
80105fee:	55                   	push   %ebp
80105fef:	89 e5                	mov    %esp,%ebp
80105ff1:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105ff4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105ff7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ffb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106002:	00 
80106003:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010600a:	e8 4b fe ff ff       	call   80105e5a <argfd>
8010600f:	85 c0                	test   %eax,%eax
80106011:	78 35                	js     80106048 <sys_write+0x5a>
80106013:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106016:	89 44 24 04          	mov    %eax,0x4(%esp)
8010601a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106021:	e8 de fc ff ff       	call   80105d04 <argint>
80106026:	85 c0                	test   %eax,%eax
80106028:	78 1e                	js     80106048 <sys_write+0x5a>
8010602a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010602d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106031:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106034:	89 44 24 04          	mov    %eax,0x4(%esp)
80106038:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010603f:	e8 ee fc ff ff       	call   80105d32 <argptr>
80106044:	85 c0                	test   %eax,%eax
80106046:	79 07                	jns    8010604f <sys_write+0x61>
    return -1;
80106048:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010604d:	eb 19                	jmp    80106068 <sys_write+0x7a>
  return filewrite(f, p, n);
8010604f:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106052:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106055:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106058:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010605c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106060:	89 04 24             	mov    %eax,(%esp)
80106063:	e8 47 b2 ff ff       	call   801012af <filewrite>
}
80106068:	c9                   	leave  
80106069:	c3                   	ret    

8010606a <sys_close>:

int
sys_close(void)
{
8010606a:	55                   	push   %ebp
8010606b:	89 e5                	mov    %esp,%ebp
8010606d:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106070:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106073:	89 44 24 08          	mov    %eax,0x8(%esp)
80106077:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010607a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010607e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106085:	e8 d0 fd ff ff       	call   80105e5a <argfd>
8010608a:	85 c0                	test   %eax,%eax
8010608c:	79 07                	jns    80106095 <sys_close+0x2b>
    return -1;
8010608e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106093:	eb 24                	jmp    801060b9 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106095:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010609b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010609e:	83 c2 08             	add    $0x8,%edx
801060a1:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060a8:	00 
  fileclose(f);
801060a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ac:	89 04 24             	mov    %eax,(%esp)
801060af:	e8 1a b0 ff ff       	call   801010ce <fileclose>
  return 0;
801060b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060b9:	c9                   	leave  
801060ba:	c3                   	ret    

801060bb <sys_fstat>:

int
sys_fstat(void)
{
801060bb:	55                   	push   %ebp
801060bc:	89 e5                	mov    %esp,%ebp
801060be:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801060c1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060c4:	89 44 24 08          	mov    %eax,0x8(%esp)
801060c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060cf:	00 
801060d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060d7:	e8 7e fd ff ff       	call   80105e5a <argfd>
801060dc:	85 c0                	test   %eax,%eax
801060de:	78 1f                	js     801060ff <sys_fstat+0x44>
801060e0:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801060e7:	00 
801060e8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ef:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060f6:	e8 37 fc ff ff       	call   80105d32 <argptr>
801060fb:	85 c0                	test   %eax,%eax
801060fd:	79 07                	jns    80106106 <sys_fstat+0x4b>
    return -1;
801060ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106104:	eb 12                	jmp    80106118 <sys_fstat+0x5d>
  return filestat(f, st);
80106106:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010610c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106110:	89 04 24             	mov    %eax,(%esp)
80106113:	e8 8c b0 ff ff       	call   801011a4 <filestat>
}
80106118:	c9                   	leave  
80106119:	c3                   	ret    

8010611a <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010611a:	55                   	push   %ebp
8010611b:	89 e5                	mov    %esp,%ebp
8010611d:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106120:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106123:	89 44 24 04          	mov    %eax,0x4(%esp)
80106127:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010612e:	e8 61 fc ff ff       	call   80105d94 <argstr>
80106133:	85 c0                	test   %eax,%eax
80106135:	78 17                	js     8010614e <sys_link+0x34>
80106137:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010613a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010613e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106145:	e8 4a fc ff ff       	call   80105d94 <argstr>
8010614a:	85 c0                	test   %eax,%eax
8010614c:	79 0a                	jns    80106158 <sys_link+0x3e>
    return -1;
8010614e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106153:	e9 42 01 00 00       	jmp    8010629a <sys_link+0x180>

  begin_op();
80106158:	e8 35 da ff ff       	call   80103b92 <begin_op>
  if((ip = namei(old)) == 0){
8010615d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106160:	89 04 24             	mov    %eax,(%esp)
80106163:	e8 02 c4 ff ff       	call   8010256a <namei>
80106168:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010616b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010616f:	75 0f                	jne    80106180 <sys_link+0x66>
    end_op();
80106171:	e8 a0 da ff ff       	call   80103c16 <end_op>
    return -1;
80106176:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010617b:	e9 1a 01 00 00       	jmp    8010629a <sys_link+0x180>
  }

  ilock(ip);
80106180:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106183:	89 04 24             	mov    %eax,(%esp)
80106186:	e8 2e b8 ff ff       	call   801019b9 <ilock>
  if(ip->type == T_DIR){
8010618b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106192:	66 83 f8 01          	cmp    $0x1,%ax
80106196:	75 1a                	jne    801061b2 <sys_link+0x98>
    iunlockput(ip);
80106198:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010619b:	89 04 24             	mov    %eax,(%esp)
8010619e:	e8 a0 ba ff ff       	call   80101c43 <iunlockput>
    end_op();
801061a3:	e8 6e da ff ff       	call   80103c16 <end_op>
    return -1;
801061a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ad:	e9 e8 00 00 00       	jmp    8010629a <sys_link+0x180>
  }

  ip->nlink++;
801061b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061b9:	8d 50 01             	lea    0x1(%eax),%edx
801061bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061bf:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801061c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c6:	89 04 24             	mov    %eax,(%esp)
801061c9:	e8 29 b6 ff ff       	call   801017f7 <iupdate>
  iunlock(ip);
801061ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d1:	89 04 24             	mov    %eax,(%esp)
801061d4:	e8 34 b9 ff ff       	call   80101b0d <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801061d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801061dc:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801061df:	89 54 24 04          	mov    %edx,0x4(%esp)
801061e3:	89 04 24             	mov    %eax,(%esp)
801061e6:	e8 a1 c3 ff ff       	call   8010258c <nameiparent>
801061eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801061ee:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801061f2:	75 02                	jne    801061f6 <sys_link+0xdc>
    goto bad;
801061f4:	eb 68                	jmp    8010625e <sys_link+0x144>
  ilock(dp);
801061f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061f9:	89 04 24             	mov    %eax,(%esp)
801061fc:	e8 b8 b7 ff ff       	call   801019b9 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106201:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106204:	8b 10                	mov    (%eax),%edx
80106206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106209:	8b 00                	mov    (%eax),%eax
8010620b:	39 c2                	cmp    %eax,%edx
8010620d:	75 20                	jne    8010622f <sys_link+0x115>
8010620f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106212:	8b 40 04             	mov    0x4(%eax),%eax
80106215:	89 44 24 08          	mov    %eax,0x8(%esp)
80106219:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010621c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106220:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106223:	89 04 24             	mov    %eax,(%esp)
80106226:	e8 7f c0 ff ff       	call   801022aa <dirlink>
8010622b:	85 c0                	test   %eax,%eax
8010622d:	79 0d                	jns    8010623c <sys_link+0x122>
    iunlockput(dp);
8010622f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106232:	89 04 24             	mov    %eax,(%esp)
80106235:	e8 09 ba ff ff       	call   80101c43 <iunlockput>
    goto bad;
8010623a:	eb 22                	jmp    8010625e <sys_link+0x144>
  }
  iunlockput(dp);
8010623c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010623f:	89 04 24             	mov    %eax,(%esp)
80106242:	e8 fc b9 ff ff       	call   80101c43 <iunlockput>
  iput(ip);
80106247:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010624a:	89 04 24             	mov    %eax,(%esp)
8010624d:	e8 20 b9 ff ff       	call   80101b72 <iput>

  end_op();
80106252:	e8 bf d9 ff ff       	call   80103c16 <end_op>

  return 0;
80106257:	b8 00 00 00 00       	mov    $0x0,%eax
8010625c:	eb 3c                	jmp    8010629a <sys_link+0x180>

bad:
  ilock(ip);
8010625e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106261:	89 04 24             	mov    %eax,(%esp)
80106264:	e8 50 b7 ff ff       	call   801019b9 <ilock>
  ip->nlink--;
80106269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106270:	8d 50 ff             	lea    -0x1(%eax),%edx
80106273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106276:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010627a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010627d:	89 04 24             	mov    %eax,(%esp)
80106280:	e8 72 b5 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
80106285:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106288:	89 04 24             	mov    %eax,(%esp)
8010628b:	e8 b3 b9 ff ff       	call   80101c43 <iunlockput>
  end_op();
80106290:	e8 81 d9 ff ff       	call   80103c16 <end_op>
  return -1;
80106295:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010629a:	c9                   	leave  
8010629b:	c3                   	ret    

8010629c <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
8010629c:	55                   	push   %ebp
8010629d:	89 e5                	mov    %esp,%ebp
8010629f:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062a2:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062a9:	eb 4b                	jmp    801062f6 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ae:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801062b5:	00 
801062b6:	89 44 24 08          	mov    %eax,0x8(%esp)
801062ba:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801062bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801062c1:	8b 45 08             	mov    0x8(%ebp),%eax
801062c4:	89 04 24             	mov    %eax,(%esp)
801062c7:	e8 00 bc ff ff       	call   80101ecc <readi>
801062cc:	83 f8 10             	cmp    $0x10,%eax
801062cf:	74 0c                	je     801062dd <isdirempty+0x41>
      panic("isdirempty: readi");
801062d1:	c7 04 24 96 a0 10 80 	movl   $0x8010a096,(%esp)
801062d8:	e8 5d a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
801062dd:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801062e1:	66 85 c0             	test   %ax,%ax
801062e4:	74 07                	je     801062ed <isdirempty+0x51>
      return 0;
801062e6:	b8 00 00 00 00       	mov    $0x0,%eax
801062eb:	eb 1b                	jmp    80106308 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f0:	83 c0 10             	add    $0x10,%eax
801062f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062f9:	8b 45 08             	mov    0x8(%ebp),%eax
801062fc:	8b 40 18             	mov    0x18(%eax),%eax
801062ff:	39 c2                	cmp    %eax,%edx
80106301:	72 a8                	jb     801062ab <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106303:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106308:	c9                   	leave  
80106309:	c3                   	ret    

8010630a <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010630a:	55                   	push   %ebp
8010630b:	89 e5                	mov    %esp,%ebp
8010630d:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106310:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106313:	89 44 24 04          	mov    %eax,0x4(%esp)
80106317:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010631e:	e8 71 fa ff ff       	call   80105d94 <argstr>
80106323:	85 c0                	test   %eax,%eax
80106325:	79 0a                	jns    80106331 <sys_unlink+0x27>
    return -1;
80106327:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010632c:	e9 af 01 00 00       	jmp    801064e0 <sys_unlink+0x1d6>

  begin_op();
80106331:	e8 5c d8 ff ff       	call   80103b92 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106336:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106339:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010633c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106340:	89 04 24             	mov    %eax,(%esp)
80106343:	e8 44 c2 ff ff       	call   8010258c <nameiparent>
80106348:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010634b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010634f:	75 0f                	jne    80106360 <sys_unlink+0x56>
    end_op();
80106351:	e8 c0 d8 ff ff       	call   80103c16 <end_op>
    return -1;
80106356:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010635b:	e9 80 01 00 00       	jmp    801064e0 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106363:	89 04 24             	mov    %eax,(%esp)
80106366:	e8 4e b6 ff ff       	call   801019b9 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010636b:	c7 44 24 04 a8 a0 10 	movl   $0x8010a0a8,0x4(%esp)
80106372:	80 
80106373:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106376:	89 04 24             	mov    %eax,(%esp)
80106379:	e8 41 be ff ff       	call   801021bf <namecmp>
8010637e:	85 c0                	test   %eax,%eax
80106380:	0f 84 45 01 00 00    	je     801064cb <sys_unlink+0x1c1>
80106386:	c7 44 24 04 aa a0 10 	movl   $0x8010a0aa,0x4(%esp)
8010638d:	80 
8010638e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106391:	89 04 24             	mov    %eax,(%esp)
80106394:	e8 26 be ff ff       	call   801021bf <namecmp>
80106399:	85 c0                	test   %eax,%eax
8010639b:	0f 84 2a 01 00 00    	je     801064cb <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063a1:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063a4:	89 44 24 08          	mov    %eax,0x8(%esp)
801063a8:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801063af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b2:	89 04 24             	mov    %eax,(%esp)
801063b5:	e8 27 be ff ff       	call   801021e1 <dirlookup>
801063ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
801063bd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801063c1:	75 05                	jne    801063c8 <sys_unlink+0xbe>
    goto bad;
801063c3:	e9 03 01 00 00       	jmp    801064cb <sys_unlink+0x1c1>
  ilock(ip);
801063c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063cb:	89 04 24             	mov    %eax,(%esp)
801063ce:	e8 e6 b5 ff ff       	call   801019b9 <ilock>

  if(ip->nlink < 1)
801063d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063d6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063da:	66 85 c0             	test   %ax,%ax
801063dd:	7f 0c                	jg     801063eb <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
801063df:	c7 04 24 ad a0 10 80 	movl   $0x8010a0ad,(%esp)
801063e6:	e8 4f a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801063eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063ee:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801063f2:	66 83 f8 01          	cmp    $0x1,%ax
801063f6:	75 1f                	jne    80106417 <sys_unlink+0x10d>
801063f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063fb:	89 04 24             	mov    %eax,(%esp)
801063fe:	e8 99 fe ff ff       	call   8010629c <isdirempty>
80106403:	85 c0                	test   %eax,%eax
80106405:	75 10                	jne    80106417 <sys_unlink+0x10d>
    iunlockput(ip);
80106407:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010640a:	89 04 24             	mov    %eax,(%esp)
8010640d:	e8 31 b8 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106412:	e9 b4 00 00 00       	jmp    801064cb <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106417:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010641e:	00 
8010641f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106426:	00 
80106427:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010642a:	89 04 24             	mov    %eax,(%esp)
8010642d:	e8 90 f5 ff ff       	call   801059c2 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106432:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106435:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010643c:	00 
8010643d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106441:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106444:	89 44 24 04          	mov    %eax,0x4(%esp)
80106448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644b:	89 04 24             	mov    %eax,(%esp)
8010644e:	e8 dd bb ff ff       	call   80102030 <writei>
80106453:	83 f8 10             	cmp    $0x10,%eax
80106456:	74 0c                	je     80106464 <sys_unlink+0x15a>
    panic("unlink: writei");
80106458:	c7 04 24 bf a0 10 80 	movl   $0x8010a0bf,(%esp)
8010645f:	e8 d6 a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80106464:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106467:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010646b:	66 83 f8 01          	cmp    $0x1,%ax
8010646f:	75 1c                	jne    8010648d <sys_unlink+0x183>
    dp->nlink--;
80106471:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106474:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106478:	8d 50 ff             	lea    -0x1(%eax),%edx
8010647b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010647e:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106485:	89 04 24             	mov    %eax,(%esp)
80106488:	e8 6a b3 ff ff       	call   801017f7 <iupdate>
  }
  iunlockput(dp);
8010648d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106490:	89 04 24             	mov    %eax,(%esp)
80106493:	e8 ab b7 ff ff       	call   80101c43 <iunlockput>

  ip->nlink--;
80106498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010649b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010649f:	8d 50 ff             	lea    -0x1(%eax),%edx
801064a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064a5:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ac:	89 04 24             	mov    %eax,(%esp)
801064af:	e8 43 b3 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801064b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b7:	89 04 24             	mov    %eax,(%esp)
801064ba:	e8 84 b7 ff ff       	call   80101c43 <iunlockput>

  end_op();
801064bf:	e8 52 d7 ff ff       	call   80103c16 <end_op>

  return 0;
801064c4:	b8 00 00 00 00       	mov    $0x0,%eax
801064c9:	eb 15                	jmp    801064e0 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801064cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ce:	89 04 24             	mov    %eax,(%esp)
801064d1:	e8 6d b7 ff ff       	call   80101c43 <iunlockput>
  end_op();
801064d6:	e8 3b d7 ff ff       	call   80103c16 <end_op>
  return -1;
801064db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801064e0:	c9                   	leave  
801064e1:	c3                   	ret    

801064e2 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
801064e2:	55                   	push   %ebp
801064e3:	89 e5                	mov    %esp,%ebp
801064e5:	83 ec 48             	sub    $0x48,%esp
801064e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801064eb:	8b 55 10             	mov    0x10(%ebp),%edx
801064ee:	8b 45 14             	mov    0x14(%ebp),%eax
801064f1:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801064f5:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801064f9:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801064fd:	8d 45 de             	lea    -0x22(%ebp),%eax
80106500:	89 44 24 04          	mov    %eax,0x4(%esp)
80106504:	8b 45 08             	mov    0x8(%ebp),%eax
80106507:	89 04 24             	mov    %eax,(%esp)
8010650a:	e8 7d c0 ff ff       	call   8010258c <nameiparent>
8010650f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106512:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106516:	75 0a                	jne    80106522 <create+0x40>
    return 0;
80106518:	b8 00 00 00 00       	mov    $0x0,%eax
8010651d:	e9 7e 01 00 00       	jmp    801066a0 <create+0x1be>
  ilock(dp);
80106522:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106525:	89 04 24             	mov    %eax,(%esp)
80106528:	e8 8c b4 ff ff       	call   801019b9 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010652d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106530:	89 44 24 08          	mov    %eax,0x8(%esp)
80106534:	8d 45 de             	lea    -0x22(%ebp),%eax
80106537:	89 44 24 04          	mov    %eax,0x4(%esp)
8010653b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010653e:	89 04 24             	mov    %eax,(%esp)
80106541:	e8 9b bc ff ff       	call   801021e1 <dirlookup>
80106546:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106549:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010654d:	74 47                	je     80106596 <create+0xb4>
    iunlockput(dp);
8010654f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106552:	89 04 24             	mov    %eax,(%esp)
80106555:	e8 e9 b6 ff ff       	call   80101c43 <iunlockput>
    ilock(ip);
8010655a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010655d:	89 04 24             	mov    %eax,(%esp)
80106560:	e8 54 b4 ff ff       	call   801019b9 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106565:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010656a:	75 15                	jne    80106581 <create+0x9f>
8010656c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010656f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106573:	66 83 f8 02          	cmp    $0x2,%ax
80106577:	75 08                	jne    80106581 <create+0x9f>
      return ip;
80106579:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010657c:	e9 1f 01 00 00       	jmp    801066a0 <create+0x1be>
    iunlockput(ip);
80106581:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106584:	89 04 24             	mov    %eax,(%esp)
80106587:	e8 b7 b6 ff ff       	call   80101c43 <iunlockput>
    return 0;
8010658c:	b8 00 00 00 00       	mov    $0x0,%eax
80106591:	e9 0a 01 00 00       	jmp    801066a0 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106596:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
8010659a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010659d:	8b 00                	mov    (%eax),%eax
8010659f:	89 54 24 04          	mov    %edx,0x4(%esp)
801065a3:	89 04 24             	mov    %eax,(%esp)
801065a6:	e8 77 b1 ff ff       	call   80101722 <ialloc>
801065ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065ae:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065b2:	75 0c                	jne    801065c0 <create+0xde>
    panic("create: ialloc");
801065b4:	c7 04 24 ce a0 10 80 	movl   $0x8010a0ce,(%esp)
801065bb:	e8 7a 9f ff ff       	call   8010053a <panic>

  ilock(ip);
801065c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065c3:	89 04 24             	mov    %eax,(%esp)
801065c6:	e8 ee b3 ff ff       	call   801019b9 <ilock>
  ip->major = major;
801065cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ce:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801065d2:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801065d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d9:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801065dd:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801065e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e4:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801065ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ed:	89 04 24             	mov    %eax,(%esp)
801065f0:	e8 02 b2 ff ff       	call   801017f7 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801065f5:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801065fa:	75 6a                	jne    80106666 <create+0x184>
    dp->nlink++;  // for ".."
801065fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ff:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106603:	8d 50 01             	lea    0x1(%eax),%edx
80106606:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106609:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010660d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106610:	89 04 24             	mov    %eax,(%esp)
80106613:	e8 df b1 ff ff       	call   801017f7 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106618:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010661b:	8b 40 04             	mov    0x4(%eax),%eax
8010661e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106622:	c7 44 24 04 a8 a0 10 	movl   $0x8010a0a8,0x4(%esp)
80106629:	80 
8010662a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010662d:	89 04 24             	mov    %eax,(%esp)
80106630:	e8 75 bc ff ff       	call   801022aa <dirlink>
80106635:	85 c0                	test   %eax,%eax
80106637:	78 21                	js     8010665a <create+0x178>
80106639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663c:	8b 40 04             	mov    0x4(%eax),%eax
8010663f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106643:	c7 44 24 04 aa a0 10 	movl   $0x8010a0aa,0x4(%esp)
8010664a:	80 
8010664b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010664e:	89 04 24             	mov    %eax,(%esp)
80106651:	e8 54 bc ff ff       	call   801022aa <dirlink>
80106656:	85 c0                	test   %eax,%eax
80106658:	79 0c                	jns    80106666 <create+0x184>
      panic("create dots");
8010665a:	c7 04 24 dd a0 10 80 	movl   $0x8010a0dd,(%esp)
80106661:	e8 d4 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106666:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106669:	8b 40 04             	mov    0x4(%eax),%eax
8010666c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106670:	8d 45 de             	lea    -0x22(%ebp),%eax
80106673:	89 44 24 04          	mov    %eax,0x4(%esp)
80106677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667a:	89 04 24             	mov    %eax,(%esp)
8010667d:	e8 28 bc ff ff       	call   801022aa <dirlink>
80106682:	85 c0                	test   %eax,%eax
80106684:	79 0c                	jns    80106692 <create+0x1b0>
    panic("create: dirlink");
80106686:	c7 04 24 e9 a0 10 80 	movl   $0x8010a0e9,(%esp)
8010668d:	e8 a8 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106692:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106695:	89 04 24             	mov    %eax,(%esp)
80106698:	e8 a6 b5 ff ff       	call   80101c43 <iunlockput>

  return ip;
8010669d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066a0:	c9                   	leave  
801066a1:	c3                   	ret    

801066a2 <sys_open>:

int
sys_open(void)
{
801066a2:	55                   	push   %ebp
801066a3:	89 e5                	mov    %esp,%ebp
801066a5:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066a8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801066af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066b6:	e8 d9 f6 ff ff       	call   80105d94 <argstr>
801066bb:	85 c0                	test   %eax,%eax
801066bd:	78 17                	js     801066d6 <sys_open+0x34>
801066bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801066c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801066c6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066cd:	e8 32 f6 ff ff       	call   80105d04 <argint>
801066d2:	85 c0                	test   %eax,%eax
801066d4:	79 0a                	jns    801066e0 <sys_open+0x3e>
    return -1;
801066d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066db:	e9 5c 01 00 00       	jmp    8010683c <sys_open+0x19a>

  begin_op();
801066e0:	e8 ad d4 ff ff       	call   80103b92 <begin_op>

  if(omode & O_CREATE){
801066e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801066e8:	25 00 02 00 00       	and    $0x200,%eax
801066ed:	85 c0                	test   %eax,%eax
801066ef:	74 3b                	je     8010672c <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801066f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801066f4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801066fb:	00 
801066fc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106703:	00 
80106704:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010670b:	00 
8010670c:	89 04 24             	mov    %eax,(%esp)
8010670f:	e8 ce fd ff ff       	call   801064e2 <create>
80106714:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106717:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010671b:	75 6b                	jne    80106788 <sys_open+0xe6>
      end_op();
8010671d:	e8 f4 d4 ff ff       	call   80103c16 <end_op>
      return -1;
80106722:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106727:	e9 10 01 00 00       	jmp    8010683c <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010672c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010672f:	89 04 24             	mov    %eax,(%esp)
80106732:	e8 33 be ff ff       	call   8010256a <namei>
80106737:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010673a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010673e:	75 0f                	jne    8010674f <sys_open+0xad>
      end_op();
80106740:	e8 d1 d4 ff ff       	call   80103c16 <end_op>
      return -1;
80106745:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010674a:	e9 ed 00 00 00       	jmp    8010683c <sys_open+0x19a>
    }
    ilock(ip);
8010674f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106752:	89 04 24             	mov    %eax,(%esp)
80106755:	e8 5f b2 ff ff       	call   801019b9 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010675a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010675d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106761:	66 83 f8 01          	cmp    $0x1,%ax
80106765:	75 21                	jne    80106788 <sys_open+0xe6>
80106767:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010676a:	85 c0                	test   %eax,%eax
8010676c:	74 1a                	je     80106788 <sys_open+0xe6>
      iunlockput(ip);
8010676e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106771:	89 04 24             	mov    %eax,(%esp)
80106774:	e8 ca b4 ff ff       	call   80101c43 <iunlockput>
      end_op();
80106779:	e8 98 d4 ff ff       	call   80103c16 <end_op>
      return -1;
8010677e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106783:	e9 b4 00 00 00       	jmp    8010683c <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106788:	e8 99 a8 ff ff       	call   80101026 <filealloc>
8010678d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106790:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106794:	74 14                	je     801067aa <sys_open+0x108>
80106796:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106799:	89 04 24             	mov    %eax,(%esp)
8010679c:	e8 2e f7 ff ff       	call   80105ecf <fdalloc>
801067a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067a4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067a8:	79 28                	jns    801067d2 <sys_open+0x130>
    if(f)
801067aa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067ae:	74 0b                	je     801067bb <sys_open+0x119>
      fileclose(f);
801067b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067b3:	89 04 24             	mov    %eax,(%esp)
801067b6:	e8 13 a9 ff ff       	call   801010ce <fileclose>
    iunlockput(ip);
801067bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067be:	89 04 24             	mov    %eax,(%esp)
801067c1:	e8 7d b4 ff ff       	call   80101c43 <iunlockput>
    end_op();
801067c6:	e8 4b d4 ff ff       	call   80103c16 <end_op>
    return -1;
801067cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067d0:	eb 6a                	jmp    8010683c <sys_open+0x19a>
  }
  iunlock(ip);
801067d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067d5:	89 04 24             	mov    %eax,(%esp)
801067d8:	e8 30 b3 ff ff       	call   80101b0d <iunlock>
  end_op();
801067dd:	e8 34 d4 ff ff       	call   80103c16 <end_op>

  f->type = FD_INODE;
801067e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067e5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801067eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067f1:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801067f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067f7:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801067fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106801:	83 e0 01             	and    $0x1,%eax
80106804:	85 c0                	test   %eax,%eax
80106806:	0f 94 c0             	sete   %al
80106809:	89 c2                	mov    %eax,%edx
8010680b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010680e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106811:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106814:	83 e0 01             	and    $0x1,%eax
80106817:	85 c0                	test   %eax,%eax
80106819:	75 0a                	jne    80106825 <sys_open+0x183>
8010681b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010681e:	83 e0 02             	and    $0x2,%eax
80106821:	85 c0                	test   %eax,%eax
80106823:	74 07                	je     8010682c <sys_open+0x18a>
80106825:	b8 01 00 00 00       	mov    $0x1,%eax
8010682a:	eb 05                	jmp    80106831 <sys_open+0x18f>
8010682c:	b8 00 00 00 00       	mov    $0x0,%eax
80106831:	89 c2                	mov    %eax,%edx
80106833:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106836:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106839:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010683c:	c9                   	leave  
8010683d:	c3                   	ret    

8010683e <sys_mkdir>:

int
sys_mkdir(void)
{
8010683e:	55                   	push   %ebp
8010683f:	89 e5                	mov    %esp,%ebp
80106841:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106844:	e8 49 d3 ff ff       	call   80103b92 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106849:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010684c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106850:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106857:	e8 38 f5 ff ff       	call   80105d94 <argstr>
8010685c:	85 c0                	test   %eax,%eax
8010685e:	78 2c                	js     8010688c <sys_mkdir+0x4e>
80106860:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106863:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010686a:	00 
8010686b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106872:	00 
80106873:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010687a:	00 
8010687b:	89 04 24             	mov    %eax,(%esp)
8010687e:	e8 5f fc ff ff       	call   801064e2 <create>
80106883:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106886:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010688a:	75 0c                	jne    80106898 <sys_mkdir+0x5a>
    end_op();
8010688c:	e8 85 d3 ff ff       	call   80103c16 <end_op>
    return -1;
80106891:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106896:	eb 15                	jmp    801068ad <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106898:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010689b:	89 04 24             	mov    %eax,(%esp)
8010689e:	e8 a0 b3 ff ff       	call   80101c43 <iunlockput>
  end_op();
801068a3:	e8 6e d3 ff ff       	call   80103c16 <end_op>
  return 0;
801068a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068ad:	c9                   	leave  
801068ae:	c3                   	ret    

801068af <sys_mknod>:

int
sys_mknod(void)
{
801068af:	55                   	push   %ebp
801068b0:	89 e5                	mov    %esp,%ebp
801068b2:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801068b5:	e8 d8 d2 ff ff       	call   80103b92 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801068ba:	8d 45 ec             	lea    -0x14(%ebp),%eax
801068bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801068c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068c8:	e8 c7 f4 ff ff       	call   80105d94 <argstr>
801068cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068d4:	78 5e                	js     80106934 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801068d6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801068d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801068dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801068e4:	e8 1b f4 ff ff       	call   80105d04 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801068e9:	85 c0                	test   %eax,%eax
801068eb:	78 47                	js     80106934 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801068ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801068f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801068f4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801068fb:	e8 04 f4 ff ff       	call   80105d04 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106900:	85 c0                	test   %eax,%eax
80106902:	78 30                	js     80106934 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106904:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106907:	0f bf c8             	movswl %ax,%ecx
8010690a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010690d:	0f bf d0             	movswl %ax,%edx
80106910:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106913:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106917:	89 54 24 08          	mov    %edx,0x8(%esp)
8010691b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106922:	00 
80106923:	89 04 24             	mov    %eax,(%esp)
80106926:	e8 b7 fb ff ff       	call   801064e2 <create>
8010692b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010692e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106932:	75 0c                	jne    80106940 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106934:	e8 dd d2 ff ff       	call   80103c16 <end_op>
    return -1;
80106939:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010693e:	eb 15                	jmp    80106955 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106940:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106943:	89 04 24             	mov    %eax,(%esp)
80106946:	e8 f8 b2 ff ff       	call   80101c43 <iunlockput>
  end_op();
8010694b:	e8 c6 d2 ff ff       	call   80103c16 <end_op>
  return 0;
80106950:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106955:	c9                   	leave  
80106956:	c3                   	ret    

80106957 <sys_chdir>:

int
sys_chdir(void)
{
80106957:	55                   	push   %ebp
80106958:	89 e5                	mov    %esp,%ebp
8010695a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010695d:	e8 30 d2 ff ff       	call   80103b92 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106962:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106965:	89 44 24 04          	mov    %eax,0x4(%esp)
80106969:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106970:	e8 1f f4 ff ff       	call   80105d94 <argstr>
80106975:	85 c0                	test   %eax,%eax
80106977:	78 14                	js     8010698d <sys_chdir+0x36>
80106979:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010697c:	89 04 24             	mov    %eax,(%esp)
8010697f:	e8 e6 bb ff ff       	call   8010256a <namei>
80106984:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106987:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010698b:	75 0c                	jne    80106999 <sys_chdir+0x42>
    end_op();
8010698d:	e8 84 d2 ff ff       	call   80103c16 <end_op>
    return -1;
80106992:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106997:	eb 61                	jmp    801069fa <sys_chdir+0xa3>
  }
  ilock(ip);
80106999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010699c:	89 04 24             	mov    %eax,(%esp)
8010699f:	e8 15 b0 ff ff       	call   801019b9 <ilock>
  if(ip->type != T_DIR){
801069a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069ab:	66 83 f8 01          	cmp    $0x1,%ax
801069af:	74 17                	je     801069c8 <sys_chdir+0x71>
    iunlockput(ip);
801069b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b4:	89 04 24             	mov    %eax,(%esp)
801069b7:	e8 87 b2 ff ff       	call   80101c43 <iunlockput>
    end_op();
801069bc:	e8 55 d2 ff ff       	call   80103c16 <end_op>
    return -1;
801069c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069c6:	eb 32                	jmp    801069fa <sys_chdir+0xa3>
  }
  iunlock(ip);
801069c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069cb:	89 04 24             	mov    %eax,(%esp)
801069ce:	e8 3a b1 ff ff       	call   80101b0d <iunlock>
  iput(proc->cwd);
801069d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069d9:	8b 40 68             	mov    0x68(%eax),%eax
801069dc:	89 04 24             	mov    %eax,(%esp)
801069df:	e8 8e b1 ff ff       	call   80101b72 <iput>
  end_op();
801069e4:	e8 2d d2 ff ff       	call   80103c16 <end_op>
  proc->cwd = ip;
801069e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
801069f2:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801069f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069fa:	c9                   	leave  
801069fb:	c3                   	ret    

801069fc <sys_exec>:

int
sys_exec(void)
{
801069fc:	55                   	push   %ebp
801069fd:	89 e5                	mov    %esp,%ebp
801069ff:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a05:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a08:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a13:	e8 7c f3 ff ff       	call   80105d94 <argstr>
80106a18:	85 c0                	test   %eax,%eax
80106a1a:	78 1a                	js     80106a36 <sys_exec+0x3a>
80106a1c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a22:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a2d:	e8 d2 f2 ff ff       	call   80105d04 <argint>
80106a32:	85 c0                	test   %eax,%eax
80106a34:	79 0a                	jns    80106a40 <sys_exec+0x44>
    return -1;
80106a36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a3b:	e9 c8 00 00 00       	jmp    80106b08 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a40:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a47:	00 
80106a48:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a4f:	00 
80106a50:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a56:	89 04 24             	mov    %eax,(%esp)
80106a59:	e8 64 ef ff ff       	call   801059c2 <memset>
  for(i=0;; i++){
80106a5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a68:	83 f8 1f             	cmp    $0x1f,%eax
80106a6b:	76 0a                	jbe    80106a77 <sys_exec+0x7b>
      return -1;
80106a6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a72:	e9 91 00 00 00       	jmp    80106b08 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a7a:	c1 e0 02             	shl    $0x2,%eax
80106a7d:	89 c2                	mov    %eax,%edx
80106a7f:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106a85:	01 c2                	add    %eax,%edx
80106a87:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106a8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a91:	89 14 24             	mov    %edx,(%esp)
80106a94:	e8 cf f1 ff ff       	call   80105c68 <fetchint>
80106a99:	85 c0                	test   %eax,%eax
80106a9b:	79 07                	jns    80106aa4 <sys_exec+0xa8>
      return -1;
80106a9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106aa2:	eb 64                	jmp    80106b08 <sys_exec+0x10c>
    if(uarg == 0){
80106aa4:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106aaa:	85 c0                	test   %eax,%eax
80106aac:	75 26                	jne    80106ad4 <sys_exec+0xd8>
      argv[i] = 0;
80106aae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab1:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106ab8:	00 00 00 00 
      break;
80106abc:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106abd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac0:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106ac6:	89 54 24 04          	mov    %edx,0x4(%esp)
80106aca:	89 04 24             	mov    %eax,(%esp)
80106acd:	e8 38 a0 ff ff       	call   80100b0a <exec>
80106ad2:	eb 34                	jmp    80106b08 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106ad4:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106ada:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106add:	c1 e2 02             	shl    $0x2,%edx
80106ae0:	01 c2                	add    %eax,%edx
80106ae2:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ae8:	89 54 24 04          	mov    %edx,0x4(%esp)
80106aec:	89 04 24             	mov    %eax,(%esp)
80106aef:	e8 ae f1 ff ff       	call   80105ca2 <fetchstr>
80106af4:	85 c0                	test   %eax,%eax
80106af6:	79 07                	jns    80106aff <sys_exec+0x103>
      return -1;
80106af8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106afd:	eb 09                	jmp    80106b08 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106aff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b03:	e9 5d ff ff ff       	jmp    80106a65 <sys_exec+0x69>
  return exec(path, argv);
}
80106b08:	c9                   	leave  
80106b09:	c3                   	ret    

80106b0a <sys_pipe>:

int
sys_pipe(void)
{
80106b0a:	55                   	push   %ebp
80106b0b:	89 e5                	mov    %esp,%ebp
80106b0d:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b10:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b17:	00 
80106b18:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b1f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b26:	e8 07 f2 ff ff       	call   80105d32 <argptr>
80106b2b:	85 c0                	test   %eax,%eax
80106b2d:	79 0a                	jns    80106b39 <sys_pipe+0x2f>
    return -1;
80106b2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b34:	e9 9b 00 00 00       	jmp    80106bd4 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b39:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b40:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b43:	89 04 24             	mov    %eax,(%esp)
80106b46:	e8 53 db ff ff       	call   8010469e <pipealloc>
80106b4b:	85 c0                	test   %eax,%eax
80106b4d:	79 07                	jns    80106b56 <sys_pipe+0x4c>
    return -1;
80106b4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b54:	eb 7e                	jmp    80106bd4 <sys_pipe+0xca>
  fd0 = -1;
80106b56:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106b5d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b60:	89 04 24             	mov    %eax,(%esp)
80106b63:	e8 67 f3 ff ff       	call   80105ecf <fdalloc>
80106b68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b6f:	78 14                	js     80106b85 <sys_pipe+0x7b>
80106b71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b74:	89 04 24             	mov    %eax,(%esp)
80106b77:	e8 53 f3 ff ff       	call   80105ecf <fdalloc>
80106b7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106b7f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106b83:	79 37                	jns    80106bbc <sys_pipe+0xb2>
    if(fd0 >= 0)
80106b85:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b89:	78 14                	js     80106b9f <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106b8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b91:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b94:	83 c2 08             	add    $0x8,%edx
80106b97:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106b9e:	00 
    fileclose(rf);
80106b9f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ba2:	89 04 24             	mov    %eax,(%esp)
80106ba5:	e8 24 a5 ff ff       	call   801010ce <fileclose>
    fileclose(wf);
80106baa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bad:	89 04 24             	mov    %eax,(%esp)
80106bb0:	e8 19 a5 ff ff       	call   801010ce <fileclose>
    return -1;
80106bb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bba:	eb 18                	jmp    80106bd4 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106bbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bbf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bc2:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106bc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bc7:	8d 50 04             	lea    0x4(%eax),%edx
80106bca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bcd:	89 02                	mov    %eax,(%edx)
  return 0;
80106bcf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106bd4:	c9                   	leave  
80106bd5:	c3                   	ret    

80106bd6 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106bd6:	55                   	push   %ebp
80106bd7:	89 e5                	mov    %esp,%ebp
80106bd9:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106bdc:	e8 93 e2 ff ff       	call   80104e74 <fork>
}
80106be1:	c9                   	leave  
80106be2:	c3                   	ret    

80106be3 <sys_exit>:

int
sys_exit(void)
{
80106be3:	55                   	push   %ebp
80106be4:	89 e5                	mov    %esp,%ebp
80106be6:	83 ec 08             	sub    $0x8,%esp
  exit();
80106be9:	e8 42 e4 ff ff       	call   80105030 <exit>
  return 0;  // not reached
80106bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106bf3:	c9                   	leave  
80106bf4:	c3                   	ret    

80106bf5 <sys_wait>:

int
sys_wait(void)
{
80106bf5:	55                   	push   %ebp
80106bf6:	89 e5                	mov    %esp,%ebp
80106bf8:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106bfb:	e8 68 e5 ff ff       	call   80105168 <wait>
}
80106c00:	c9                   	leave  
80106c01:	c3                   	ret    

80106c02 <sys_kill>:

int
sys_kill(void)
{
80106c02:	55                   	push   %ebp
80106c03:	89 e5                	mov    %esp,%ebp
80106c05:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c08:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c0f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c16:	e8 e9 f0 ff ff       	call   80105d04 <argint>
80106c1b:	85 c0                	test   %eax,%eax
80106c1d:	79 07                	jns    80106c26 <sys_kill+0x24>
    return -1;
80106c1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c24:	eb 0b                	jmp    80106c31 <sys_kill+0x2f>
  return kill(pid);
80106c26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c29:	89 04 24             	mov    %eax,(%esp)
80106c2c:	e8 15 e9 ff ff       	call   80105546 <kill>
}
80106c31:	c9                   	leave  
80106c32:	c3                   	ret    

80106c33 <sys_getpid>:

int
sys_getpid(void)
{
80106c33:	55                   	push   %ebp
80106c34:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c36:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c3c:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c3f:	5d                   	pop    %ebp
80106c40:	c3                   	ret    

80106c41 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c41:	55                   	push   %ebp
80106c42:	89 e5                	mov    %esp,%ebp
80106c44:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c47:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c4e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c55:	e8 aa f0 ff ff       	call   80105d04 <argint>
80106c5a:	85 c0                	test   %eax,%eax
80106c5c:	79 07                	jns    80106c65 <sys_sbrk+0x24>
    return -1;
80106c5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c63:	eb 39                	jmp    80106c9e <sys_sbrk+0x5d>
  addr = proc->sz;
80106c65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c6b:	8b 00                	mov    (%eax),%eax
80106c6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106c70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c73:	89 04 24             	mov    %eax,(%esp)
80106c76:	e8 3e e1 ff ff       	call   80104db9 <growproc>
80106c7b:	85 c0                	test   %eax,%eax
80106c7d:	79 07                	jns    80106c86 <sys_sbrk+0x45>
    return -1;
80106c7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c84:	eb 18                	jmp    80106c9e <sys_sbrk+0x5d>
  cprintf("num of pages in system:%d\n",countPages());
80106c86:	e8 ea c5 ff ff       	call   80103275 <countPages>
80106c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c8f:	c7 04 24 f9 a0 10 80 	movl   $0x8010a0f9,(%esp)
80106c96:	e8 05 97 ff ff       	call   801003a0 <cprintf>
  return addr;
80106c9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106c9e:	c9                   	leave  
80106c9f:	c3                   	ret    

80106ca0 <sys_sleep>:

int
sys_sleep(void)
{
80106ca0:	55                   	push   %ebp
80106ca1:	89 e5                	mov    %esp,%ebp
80106ca3:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106ca6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ca9:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cb4:	e8 4b f0 ff ff       	call   80105d04 <argint>
80106cb9:	85 c0                	test   %eax,%eax
80106cbb:	79 07                	jns    80106cc4 <sys_sleep+0x24>
    return -1;
80106cbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cc2:	eb 6c                	jmp    80106d30 <sys_sleep+0x90>
  acquire(&tickslock);
80106cc4:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106ccb:	e8 9e ea ff ff       	call   8010576e <acquire>
  ticks0 = ticks;
80106cd0:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106cd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106cd8:	eb 34                	jmp    80106d0e <sys_sleep+0x6e>
    if(proc->killed){
80106cda:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ce0:	8b 40 24             	mov    0x24(%eax),%eax
80106ce3:	85 c0                	test   %eax,%eax
80106ce5:	74 13                	je     80106cfa <sys_sleep+0x5a>
      release(&tickslock);
80106ce7:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106cee:	e8 dd ea ff ff       	call   801057d0 <release>
      return -1;
80106cf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cf8:	eb 36                	jmp    80106d30 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106cfa:	c7 44 24 04 c0 04 12 	movl   $0x801204c0,0x4(%esp)
80106d01:	80 
80106d02:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80106d09:	e8 31 e7 ff ff       	call   8010543f <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d0e:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d13:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d16:	89 c2                	mov    %eax,%edx
80106d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d1b:	39 c2                	cmp    %eax,%edx
80106d1d:	72 bb                	jb     80106cda <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d1f:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d26:	e8 a5 ea ff ff       	call   801057d0 <release>
  return 0;
80106d2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d30:	c9                   	leave  
80106d31:	c3                   	ret    

80106d32 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d32:	55                   	push   %ebp
80106d33:	89 e5                	mov    %esp,%ebp
80106d35:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d38:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d3f:	e8 2a ea ff ff       	call   8010576e <acquire>
  xticks = ticks;
80106d44:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d49:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d4c:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d53:	e8 78 ea ff ff       	call   801057d0 <release>
  return xticks;
80106d58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d5b:	c9                   	leave  
80106d5c:	c3                   	ret    

80106d5d <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d5d:	55                   	push   %ebp
80106d5e:	89 e5                	mov    %esp,%ebp
80106d60:	83 ec 08             	sub    $0x8,%esp
80106d63:	8b 55 08             	mov    0x8(%ebp),%edx
80106d66:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d69:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d6d:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d70:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106d74:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106d78:	ee                   	out    %al,(%dx)
}
80106d79:	c9                   	leave  
80106d7a:	c3                   	ret    

80106d7b <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106d7b:	55                   	push   %ebp
80106d7c:	89 e5                	mov    %esp,%ebp
80106d7e:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106d81:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106d88:	00 
80106d89:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106d90:	e8 c8 ff ff ff       	call   80106d5d <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106d95:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106d9c:	00 
80106d9d:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106da4:	e8 b4 ff ff ff       	call   80106d5d <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106da9:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106db0:	00 
80106db1:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106db8:	e8 a0 ff ff ff       	call   80106d5d <outb>
  picenable(IRQ_TIMER);
80106dbd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dc4:	e8 68 d7 ff ff       	call   80104531 <picenable>
}
80106dc9:	c9                   	leave  
80106dca:	c3                   	ret    

80106dcb <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106dcb:	1e                   	push   %ds
  pushl %es
80106dcc:	06                   	push   %es
  pushl %fs
80106dcd:	0f a0                	push   %fs
  pushl %gs
80106dcf:	0f a8                	push   %gs
  pushal
80106dd1:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106dd2:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106dd6:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106dd8:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106dda:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106dde:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106de0:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106de2:	54                   	push   %esp
  call trap
80106de3:	e8 d8 01 00 00       	call   80106fc0 <trap>
  addl $4, %esp
80106de8:	83 c4 04             	add    $0x4,%esp

80106deb <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106deb:	61                   	popa   
  popl %gs
80106dec:	0f a9                	pop    %gs
  popl %fs
80106dee:	0f a1                	pop    %fs
  popl %es
80106df0:	07                   	pop    %es
  popl %ds
80106df1:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106df2:	83 c4 08             	add    $0x8,%esp
  iret
80106df5:	cf                   	iret   

80106df6 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106df6:	55                   	push   %ebp
80106df7:	89 e5                	mov    %esp,%ebp
80106df9:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106dfc:	8b 45 0c             	mov    0xc(%ebp),%eax
80106dff:	83 e8 01             	sub    $0x1,%eax
80106e02:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e06:	8b 45 08             	mov    0x8(%ebp),%eax
80106e09:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80106e10:	c1 e8 10             	shr    $0x10,%eax
80106e13:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e17:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e1a:	0f 01 18             	lidtl  (%eax)
}
80106e1d:	c9                   	leave  
80106e1e:	c3                   	ret    

80106e1f <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e1f:	55                   	push   %ebp
80106e20:	89 e5                	mov    %esp,%ebp
80106e22:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e25:	0f 20 d0             	mov    %cr2,%eax
80106e28:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e2e:	c9                   	leave  
80106e2f:	c3                   	ret    

80106e30 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e30:	55                   	push   %ebp
80106e31:	89 e5                	mov    %esp,%ebp
80106e33:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e3d:	e9 c3 00 00 00       	jmp    80106f05 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e45:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106e4c:	89 c2                	mov    %eax,%edx
80106e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e51:	66 89 14 c5 00 05 12 	mov    %dx,-0x7fedfb00(,%eax,8)
80106e58:	80 
80106e59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e5c:	66 c7 04 c5 02 05 12 	movw   $0x8,-0x7fedfafe(,%eax,8)
80106e63:	80 08 00 
80106e66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e69:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106e70:	80 
80106e71:	83 e2 e0             	and    $0xffffffe0,%edx
80106e74:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106e7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e7e:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106e85:	80 
80106e86:	83 e2 1f             	and    $0x1f,%edx
80106e89:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106e90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e93:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106e9a:	80 
80106e9b:	83 e2 f0             	and    $0xfffffff0,%edx
80106e9e:	83 ca 0e             	or     $0xe,%edx
80106ea1:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ea8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eab:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106eb2:	80 
80106eb3:	83 e2 ef             	and    $0xffffffef,%edx
80106eb6:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ebd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ec0:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ec7:	80 
80106ec8:	83 e2 9f             	and    $0xffffff9f,%edx
80106ecb:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ed2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed5:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106edc:	80 
80106edd:	83 ca 80             	or     $0xffffff80,%edx
80106ee0:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eea:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106ef1:	c1 e8 10             	shr    $0x10,%eax
80106ef4:	89 c2                	mov    %eax,%edx
80106ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef9:	66 89 14 c5 06 05 12 	mov    %dx,-0x7fedfafa(,%eax,8)
80106f00:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f01:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f05:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f0c:	0f 8e 30 ff ff ff    	jle    80106e42 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f12:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f17:	66 a3 00 07 12 80    	mov    %ax,0x80120700
80106f1d:	66 c7 05 02 07 12 80 	movw   $0x8,0x80120702
80106f24:	08 00 
80106f26:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f2d:	83 e0 e0             	and    $0xffffffe0,%eax
80106f30:	a2 04 07 12 80       	mov    %al,0x80120704
80106f35:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f3c:	83 e0 1f             	and    $0x1f,%eax
80106f3f:	a2 04 07 12 80       	mov    %al,0x80120704
80106f44:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f4b:	83 c8 0f             	or     $0xf,%eax
80106f4e:	a2 05 07 12 80       	mov    %al,0x80120705
80106f53:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f5a:	83 e0 ef             	and    $0xffffffef,%eax
80106f5d:	a2 05 07 12 80       	mov    %al,0x80120705
80106f62:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f69:	83 c8 60             	or     $0x60,%eax
80106f6c:	a2 05 07 12 80       	mov    %al,0x80120705
80106f71:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f78:	83 c8 80             	or     $0xffffff80,%eax
80106f7b:	a2 05 07 12 80       	mov    %al,0x80120705
80106f80:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f85:	c1 e8 10             	shr    $0x10,%eax
80106f88:	66 a3 06 07 12 80    	mov    %ax,0x80120706
  
  initlock(&tickslock, "time");
80106f8e:	c7 44 24 04 14 a1 10 	movl   $0x8010a114,0x4(%esp)
80106f95:	80 
80106f96:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106f9d:	e8 ab e7 ff ff       	call   8010574d <initlock>
}
80106fa2:	c9                   	leave  
80106fa3:	c3                   	ret    

80106fa4 <idtinit>:

void
idtinit(void)
{
80106fa4:	55                   	push   %ebp
80106fa5:	89 e5                	mov    %esp,%ebp
80106fa7:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106faa:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106fb1:	00 
80106fb2:	c7 04 24 00 05 12 80 	movl   $0x80120500,(%esp)
80106fb9:	e8 38 fe ff ff       	call   80106df6 <lidt>
}
80106fbe:	c9                   	leave  
80106fbf:	c3                   	ret    

80106fc0 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106fc0:	55                   	push   %ebp
80106fc1:	89 e5                	mov    %esp,%ebp
80106fc3:	57                   	push   %edi
80106fc4:	56                   	push   %esi
80106fc5:	53                   	push   %ebx
80106fc6:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106fc9:	8b 45 08             	mov    0x8(%ebp),%eax
80106fcc:	8b 40 30             	mov    0x30(%eax),%eax
80106fcf:	83 f8 40             	cmp    $0x40,%eax
80106fd2:	75 3f                	jne    80107013 <trap+0x53>
    if(proc->killed)
80106fd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fda:	8b 40 24             	mov    0x24(%eax),%eax
80106fdd:	85 c0                	test   %eax,%eax
80106fdf:	74 05                	je     80106fe6 <trap+0x26>
      exit();
80106fe1:	e8 4a e0 ff ff       	call   80105030 <exit>
    proc->tf = tf;
80106fe6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fec:	8b 55 08             	mov    0x8(%ebp),%edx
80106fef:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106ff2:	e8 d4 ed ff ff       	call   80105dcb <syscall>
    if(proc->killed)
80106ff7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ffd:	8b 40 24             	mov    0x24(%eax),%eax
80107000:	85 c0                	test   %eax,%eax
80107002:	74 0a                	je     8010700e <trap+0x4e>
      exit();
80107004:	e8 27 e0 ff ff       	call   80105030 <exit>
    return;
80107009:	e9 c5 02 00 00       	jmp    801072d3 <trap+0x313>
8010700e:	e9 c0 02 00 00       	jmp    801072d3 <trap+0x313>
  }
  switch(tf->trapno){
80107013:	8b 45 08             	mov    0x8(%ebp),%eax
80107016:	8b 40 30             	mov    0x30(%eax),%eax
80107019:	83 e8 0e             	sub    $0xe,%eax
8010701c:	83 f8 31             	cmp    $0x31,%eax
8010701f:	0f 87 54 01 00 00    	ja     80107179 <trap+0x1b9>
80107025:	8b 04 85 14 a2 10 80 	mov    -0x7fef5dec(,%eax,4),%eax
8010702c:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010702e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107034:	0f b6 00             	movzbl (%eax),%eax
80107037:	84 c0                	test   %al,%al
80107039:	75 31                	jne    8010706c <trap+0xac>
      acquire(&tickslock);
8010703b:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107042:	e8 27 e7 ff ff       	call   8010576e <acquire>
      ticks++;
80107047:	a1 00 0d 12 80       	mov    0x80120d00,%eax
8010704c:	83 c0 01             	add    $0x1,%eax
8010704f:	a3 00 0d 12 80       	mov    %eax,0x80120d00
      wakeup(&ticks);
80107054:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
8010705b:	e8 bb e4 ff ff       	call   8010551b <wakeup>
      release(&tickslock);
80107060:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107067:	e8 64 e7 ff ff       	call   801057d0 <release>
    }
    lapiceoi();
8010706c:	e8 eb c5 ff ff       	call   8010365c <lapiceoi>
    break;
80107071:	e9 d9 01 00 00       	jmp    8010724f <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107076:	e8 80 bd ff ff       	call   80102dfb <ideintr>
    lapiceoi();
8010707b:	e8 dc c5 ff ff       	call   8010365c <lapiceoi>
    break;
80107080:	e9 ca 01 00 00       	jmp    8010724f <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107085:	e8 a1 c3 ff ff       	call   8010342b <kbdintr>
    lapiceoi();
8010708a:	e8 cd c5 ff ff       	call   8010365c <lapiceoi>
    break;
8010708f:	e9 bb 01 00 00       	jmp    8010724f <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107094:	e8 2f 04 00 00       	call   801074c8 <uartintr>
    lapiceoi();
80107099:	e8 be c5 ff ff       	call   8010365c <lapiceoi>
    break;
8010709e:	e9 ac 01 00 00       	jmp    8010724f <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070a3:	8b 45 08             	mov    0x8(%ebp),%eax
801070a6:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070a9:	8b 45 08             	mov    0x8(%ebp),%eax
801070ac:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070b0:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801070b3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070b9:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070bc:	0f b6 c0             	movzbl %al,%eax
801070bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070c3:	89 54 24 08          	mov    %edx,0x8(%esp)
801070c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801070cb:	c7 04 24 1c a1 10 80 	movl   $0x8010a11c,(%esp)
801070d2:	e8 c9 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801070d7:	e8 80 c5 ff ff       	call   8010365c <lapiceoi>
    break;
801070dc:	e9 6e 01 00 00       	jmp    8010724f <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
801070e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070e7:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
801070ed:	83 c2 01             	add    $0x1,%edx
801070f0:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
801070f6:	e8 24 fd ff ff       	call   80106e1f <rcr2>
801070fb:	05 ff 0f 00 00       	add    $0xfff,%eax
80107100:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107105:	89 c6                	mov    %eax,%esi
80107107:	e8 13 fd ff ff       	call   80106e1f <rcr2>
8010710c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107111:	89 c3                	mov    %eax,%ebx
80107113:	e8 07 fd ff ff       	call   80106e1f <rcr2>
80107118:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010711f:	8b 52 10             	mov    0x10(%edx),%edx
80107122:	89 74 24 10          	mov    %esi,0x10(%esp)
80107126:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010712a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010712e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107132:	c7 04 24 40 a1 10 80 	movl   $0x8010a140,(%esp)
80107139:	e8 62 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
8010713e:	e8 dc fc ff ff       	call   80106e1f <rcr2>
80107143:	89 04 24             	mov    %eax,(%esp)
80107146:	e8 b4 21 00 00       	call   801092ff <existOnDisc>
8010714b:	85 c0                	test   %eax,%eax
8010714d:	74 2a                	je     80107179 <trap+0x1b9>
      cprintf("found on disk, recovering\n");
8010714f:	c7 04 24 6f a1 10 80 	movl   $0x8010a16f,(%esp)
80107156:	e8 45 92 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
8010715b:	e8 bf fc ff ff       	call   80106e1f <rcr2>
80107160:	89 04 24             	mov    %eax,(%esp)
80107163:	e8 83 22 00 00       	call   801093eb <fixPage>
      cprintf("recovered!\n");
80107168:	c7 04 24 8a a1 10 80 	movl   $0x8010a18a,(%esp)
8010716f:	e8 2c 92 ff ff       	call   801003a0 <cprintf>
      break;
80107174:	e9 d6 00 00 00       	jmp    8010724f <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107179:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010717f:	85 c0                	test   %eax,%eax
80107181:	74 11                	je     80107194 <trap+0x1d4>
80107183:	8b 45 08             	mov    0x8(%ebp),%eax
80107186:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010718a:	0f b7 c0             	movzwl %ax,%eax
8010718d:	83 e0 03             	and    $0x3,%eax
80107190:	85 c0                	test   %eax,%eax
80107192:	75 46                	jne    801071da <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107194:	e8 86 fc ff ff       	call   80106e1f <rcr2>
80107199:	8b 55 08             	mov    0x8(%ebp),%edx
8010719c:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010719f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801071a6:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071a9:	0f b6 ca             	movzbl %dl,%ecx
801071ac:	8b 55 08             	mov    0x8(%ebp),%edx
801071af:	8b 52 30             	mov    0x30(%edx),%edx
801071b2:	89 44 24 10          	mov    %eax,0x10(%esp)
801071b6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801071ba:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801071be:	89 54 24 04          	mov    %edx,0x4(%esp)
801071c2:	c7 04 24 98 a1 10 80 	movl   $0x8010a198,(%esp)
801071c9:	e8 d2 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801071ce:	c7 04 24 ca a1 10 80 	movl   $0x8010a1ca,(%esp)
801071d5:	e8 60 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071da:	e8 40 fc ff ff       	call   80106e1f <rcr2>
801071df:	89 c2                	mov    %eax,%edx
801071e1:	8b 45 08             	mov    0x8(%ebp),%eax
801071e4:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801071ed:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071f0:	0f b6 f0             	movzbl %al,%esi
801071f3:	8b 45 08             	mov    0x8(%ebp),%eax
801071f6:	8b 58 34             	mov    0x34(%eax),%ebx
801071f9:	8b 45 08             	mov    0x8(%ebp),%eax
801071fc:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107205:	83 c0 6c             	add    $0x6c,%eax
80107208:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010720b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107211:	8b 40 10             	mov    0x10(%eax),%eax
80107214:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107218:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010721c:	89 74 24 14          	mov    %esi,0x14(%esp)
80107220:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107224:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107228:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010722b:	89 7c 24 08          	mov    %edi,0x8(%esp)
8010722f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107233:	c7 04 24 d0 a1 10 80 	movl   $0x8010a1d0,(%esp)
8010723a:	e8 61 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010723f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107245:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010724c:	eb 01                	jmp    8010724f <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010724e:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010724f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107255:	85 c0                	test   %eax,%eax
80107257:	74 24                	je     8010727d <trap+0x2bd>
80107259:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010725f:	8b 40 24             	mov    0x24(%eax),%eax
80107262:	85 c0                	test   %eax,%eax
80107264:	74 17                	je     8010727d <trap+0x2bd>
80107266:	8b 45 08             	mov    0x8(%ebp),%eax
80107269:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010726d:	0f b7 c0             	movzwl %ax,%eax
80107270:	83 e0 03             	and    $0x3,%eax
80107273:	83 f8 03             	cmp    $0x3,%eax
80107276:	75 05                	jne    8010727d <trap+0x2bd>
    exit();
80107278:	e8 b3 dd ff ff       	call   80105030 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
8010727d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107283:	85 c0                	test   %eax,%eax
80107285:	74 1e                	je     801072a5 <trap+0x2e5>
80107287:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010728d:	8b 40 0c             	mov    0xc(%eax),%eax
80107290:	83 f8 04             	cmp    $0x4,%eax
80107293:	75 10                	jne    801072a5 <trap+0x2e5>
80107295:	8b 45 08             	mov    0x8(%ebp),%eax
80107298:	8b 40 30             	mov    0x30(%eax),%eax
8010729b:	83 f8 20             	cmp    $0x20,%eax
8010729e:	75 05                	jne    801072a5 <trap+0x2e5>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4) updateAge(proc); //TODO: maybe need to get proc?
    yield();
801072a0:	e8 29 e1 ff ff       	call   801053ce <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072ab:	85 c0                	test   %eax,%eax
801072ad:	74 24                	je     801072d3 <trap+0x313>
801072af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b5:	8b 40 24             	mov    0x24(%eax),%eax
801072b8:	85 c0                	test   %eax,%eax
801072ba:	74 17                	je     801072d3 <trap+0x313>
801072bc:	8b 45 08             	mov    0x8(%ebp),%eax
801072bf:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072c3:	0f b7 c0             	movzwl %ax,%eax
801072c6:	83 e0 03             	and    $0x3,%eax
801072c9:	83 f8 03             	cmp    $0x3,%eax
801072cc:	75 05                	jne    801072d3 <trap+0x313>
    exit();
801072ce:	e8 5d dd ff ff       	call   80105030 <exit>
}
801072d3:	83 c4 3c             	add    $0x3c,%esp
801072d6:	5b                   	pop    %ebx
801072d7:	5e                   	pop    %esi
801072d8:	5f                   	pop    %edi
801072d9:	5d                   	pop    %ebp
801072da:	c3                   	ret    

801072db <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801072db:	55                   	push   %ebp
801072dc:	89 e5                	mov    %esp,%ebp
801072de:	83 ec 14             	sub    $0x14,%esp
801072e1:	8b 45 08             	mov    0x8(%ebp),%eax
801072e4:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801072e8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801072ec:	89 c2                	mov    %eax,%edx
801072ee:	ec                   	in     (%dx),%al
801072ef:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801072f2:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801072f6:	c9                   	leave  
801072f7:	c3                   	ret    

801072f8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801072f8:	55                   	push   %ebp
801072f9:	89 e5                	mov    %esp,%ebp
801072fb:	83 ec 08             	sub    $0x8,%esp
801072fe:	8b 55 08             	mov    0x8(%ebp),%edx
80107301:	8b 45 0c             	mov    0xc(%ebp),%eax
80107304:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107308:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010730b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010730f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107313:	ee                   	out    %al,(%dx)
}
80107314:	c9                   	leave  
80107315:	c3                   	ret    

80107316 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107316:	55                   	push   %ebp
80107317:	89 e5                	mov    %esp,%ebp
80107319:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010731c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107323:	00 
80107324:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010732b:	e8 c8 ff ff ff       	call   801072f8 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107330:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107337:	00 
80107338:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010733f:	e8 b4 ff ff ff       	call   801072f8 <outb>
  outb(COM1+0, 115200/9600);
80107344:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010734b:	00 
8010734c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107353:	e8 a0 ff ff ff       	call   801072f8 <outb>
  outb(COM1+1, 0);
80107358:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010735f:	00 
80107360:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107367:	e8 8c ff ff ff       	call   801072f8 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010736c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107373:	00 
80107374:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010737b:	e8 78 ff ff ff       	call   801072f8 <outb>
  outb(COM1+4, 0);
80107380:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107387:	00 
80107388:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
8010738f:	e8 64 ff ff ff       	call   801072f8 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107394:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010739b:	00 
8010739c:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073a3:	e8 50 ff ff ff       	call   801072f8 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801073a8:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073af:	e8 27 ff ff ff       	call   801072db <inb>
801073b4:	3c ff                	cmp    $0xff,%al
801073b6:	75 02                	jne    801073ba <uartinit+0xa4>
    return;
801073b8:	eb 6a                	jmp    80107424 <uartinit+0x10e>
  uart = 1;
801073ba:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
801073c1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801073c4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801073cb:	e8 0b ff ff ff       	call   801072db <inb>
  inb(COM1+0);
801073d0:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801073d7:	e8 ff fe ff ff       	call   801072db <inb>
  picenable(IRQ_COM1);
801073dc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801073e3:	e8 49 d1 ff ff       	call   80104531 <picenable>
  ioapicenable(IRQ_COM1, 0);
801073e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073ef:	00 
801073f0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801073f7:	e8 7e bc ff ff       	call   8010307a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801073fc:	c7 45 f4 dc a2 10 80 	movl   $0x8010a2dc,-0xc(%ebp)
80107403:	eb 15                	jmp    8010741a <uartinit+0x104>
    uartputc(*p);
80107405:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107408:	0f b6 00             	movzbl (%eax),%eax
8010740b:	0f be c0             	movsbl %al,%eax
8010740e:	89 04 24             	mov    %eax,(%esp)
80107411:	e8 10 00 00 00       	call   80107426 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107416:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010741a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010741d:	0f b6 00             	movzbl (%eax),%eax
80107420:	84 c0                	test   %al,%al
80107422:	75 e1                	jne    80107405 <uartinit+0xef>
    uartputc(*p);
}
80107424:	c9                   	leave  
80107425:	c3                   	ret    

80107426 <uartputc>:

void
uartputc(int c)
{
80107426:	55                   	push   %ebp
80107427:	89 e5                	mov    %esp,%ebp
80107429:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010742c:	a1 50 d6 10 80       	mov    0x8010d650,%eax
80107431:	85 c0                	test   %eax,%eax
80107433:	75 02                	jne    80107437 <uartputc+0x11>
    return;
80107435:	eb 4b                	jmp    80107482 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107437:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010743e:	eb 10                	jmp    80107450 <uartputc+0x2a>
    microdelay(10);
80107440:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107447:	e8 35 c2 ff ff       	call   80103681 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010744c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107450:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107454:	7f 16                	jg     8010746c <uartputc+0x46>
80107456:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010745d:	e8 79 fe ff ff       	call   801072db <inb>
80107462:	0f b6 c0             	movzbl %al,%eax
80107465:	83 e0 20             	and    $0x20,%eax
80107468:	85 c0                	test   %eax,%eax
8010746a:	74 d4                	je     80107440 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
8010746c:	8b 45 08             	mov    0x8(%ebp),%eax
8010746f:	0f b6 c0             	movzbl %al,%eax
80107472:	89 44 24 04          	mov    %eax,0x4(%esp)
80107476:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010747d:	e8 76 fe ff ff       	call   801072f8 <outb>
}
80107482:	c9                   	leave  
80107483:	c3                   	ret    

80107484 <uartgetc>:

static int
uartgetc(void)
{
80107484:	55                   	push   %ebp
80107485:	89 e5                	mov    %esp,%ebp
80107487:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
8010748a:	a1 50 d6 10 80       	mov    0x8010d650,%eax
8010748f:	85 c0                	test   %eax,%eax
80107491:	75 07                	jne    8010749a <uartgetc+0x16>
    return -1;
80107493:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107498:	eb 2c                	jmp    801074c6 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
8010749a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074a1:	e8 35 fe ff ff       	call   801072db <inb>
801074a6:	0f b6 c0             	movzbl %al,%eax
801074a9:	83 e0 01             	and    $0x1,%eax
801074ac:	85 c0                	test   %eax,%eax
801074ae:	75 07                	jne    801074b7 <uartgetc+0x33>
    return -1;
801074b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074b5:	eb 0f                	jmp    801074c6 <uartgetc+0x42>
  return inb(COM1+0);
801074b7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074be:	e8 18 fe ff ff       	call   801072db <inb>
801074c3:	0f b6 c0             	movzbl %al,%eax
}
801074c6:	c9                   	leave  
801074c7:	c3                   	ret    

801074c8 <uartintr>:

void
uartintr(void)
{
801074c8:	55                   	push   %ebp
801074c9:	89 e5                	mov    %esp,%ebp
801074cb:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801074ce:	c7 04 24 84 74 10 80 	movl   $0x80107484,(%esp)
801074d5:	e8 ee 92 ff ff       	call   801007c8 <consoleintr>
}
801074da:	c9                   	leave  
801074db:	c3                   	ret    

801074dc <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801074dc:	6a 00                	push   $0x0
  pushl $0
801074de:	6a 00                	push   $0x0
  jmp alltraps
801074e0:	e9 e6 f8 ff ff       	jmp    80106dcb <alltraps>

801074e5 <vector1>:
.globl vector1
vector1:
  pushl $0
801074e5:	6a 00                	push   $0x0
  pushl $1
801074e7:	6a 01                	push   $0x1
  jmp alltraps
801074e9:	e9 dd f8 ff ff       	jmp    80106dcb <alltraps>

801074ee <vector2>:
.globl vector2
vector2:
  pushl $0
801074ee:	6a 00                	push   $0x0
  pushl $2
801074f0:	6a 02                	push   $0x2
  jmp alltraps
801074f2:	e9 d4 f8 ff ff       	jmp    80106dcb <alltraps>

801074f7 <vector3>:
.globl vector3
vector3:
  pushl $0
801074f7:	6a 00                	push   $0x0
  pushl $3
801074f9:	6a 03                	push   $0x3
  jmp alltraps
801074fb:	e9 cb f8 ff ff       	jmp    80106dcb <alltraps>

80107500 <vector4>:
.globl vector4
vector4:
  pushl $0
80107500:	6a 00                	push   $0x0
  pushl $4
80107502:	6a 04                	push   $0x4
  jmp alltraps
80107504:	e9 c2 f8 ff ff       	jmp    80106dcb <alltraps>

80107509 <vector5>:
.globl vector5
vector5:
  pushl $0
80107509:	6a 00                	push   $0x0
  pushl $5
8010750b:	6a 05                	push   $0x5
  jmp alltraps
8010750d:	e9 b9 f8 ff ff       	jmp    80106dcb <alltraps>

80107512 <vector6>:
.globl vector6
vector6:
  pushl $0
80107512:	6a 00                	push   $0x0
  pushl $6
80107514:	6a 06                	push   $0x6
  jmp alltraps
80107516:	e9 b0 f8 ff ff       	jmp    80106dcb <alltraps>

8010751b <vector7>:
.globl vector7
vector7:
  pushl $0
8010751b:	6a 00                	push   $0x0
  pushl $7
8010751d:	6a 07                	push   $0x7
  jmp alltraps
8010751f:	e9 a7 f8 ff ff       	jmp    80106dcb <alltraps>

80107524 <vector8>:
.globl vector8
vector8:
  pushl $8
80107524:	6a 08                	push   $0x8
  jmp alltraps
80107526:	e9 a0 f8 ff ff       	jmp    80106dcb <alltraps>

8010752b <vector9>:
.globl vector9
vector9:
  pushl $0
8010752b:	6a 00                	push   $0x0
  pushl $9
8010752d:	6a 09                	push   $0x9
  jmp alltraps
8010752f:	e9 97 f8 ff ff       	jmp    80106dcb <alltraps>

80107534 <vector10>:
.globl vector10
vector10:
  pushl $10
80107534:	6a 0a                	push   $0xa
  jmp alltraps
80107536:	e9 90 f8 ff ff       	jmp    80106dcb <alltraps>

8010753b <vector11>:
.globl vector11
vector11:
  pushl $11
8010753b:	6a 0b                	push   $0xb
  jmp alltraps
8010753d:	e9 89 f8 ff ff       	jmp    80106dcb <alltraps>

80107542 <vector12>:
.globl vector12
vector12:
  pushl $12
80107542:	6a 0c                	push   $0xc
  jmp alltraps
80107544:	e9 82 f8 ff ff       	jmp    80106dcb <alltraps>

80107549 <vector13>:
.globl vector13
vector13:
  pushl $13
80107549:	6a 0d                	push   $0xd
  jmp alltraps
8010754b:	e9 7b f8 ff ff       	jmp    80106dcb <alltraps>

80107550 <vector14>:
.globl vector14
vector14:
  pushl $14
80107550:	6a 0e                	push   $0xe
  jmp alltraps
80107552:	e9 74 f8 ff ff       	jmp    80106dcb <alltraps>

80107557 <vector15>:
.globl vector15
vector15:
  pushl $0
80107557:	6a 00                	push   $0x0
  pushl $15
80107559:	6a 0f                	push   $0xf
  jmp alltraps
8010755b:	e9 6b f8 ff ff       	jmp    80106dcb <alltraps>

80107560 <vector16>:
.globl vector16
vector16:
  pushl $0
80107560:	6a 00                	push   $0x0
  pushl $16
80107562:	6a 10                	push   $0x10
  jmp alltraps
80107564:	e9 62 f8 ff ff       	jmp    80106dcb <alltraps>

80107569 <vector17>:
.globl vector17
vector17:
  pushl $17
80107569:	6a 11                	push   $0x11
  jmp alltraps
8010756b:	e9 5b f8 ff ff       	jmp    80106dcb <alltraps>

80107570 <vector18>:
.globl vector18
vector18:
  pushl $0
80107570:	6a 00                	push   $0x0
  pushl $18
80107572:	6a 12                	push   $0x12
  jmp alltraps
80107574:	e9 52 f8 ff ff       	jmp    80106dcb <alltraps>

80107579 <vector19>:
.globl vector19
vector19:
  pushl $0
80107579:	6a 00                	push   $0x0
  pushl $19
8010757b:	6a 13                	push   $0x13
  jmp alltraps
8010757d:	e9 49 f8 ff ff       	jmp    80106dcb <alltraps>

80107582 <vector20>:
.globl vector20
vector20:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $20
80107584:	6a 14                	push   $0x14
  jmp alltraps
80107586:	e9 40 f8 ff ff       	jmp    80106dcb <alltraps>

8010758b <vector21>:
.globl vector21
vector21:
  pushl $0
8010758b:	6a 00                	push   $0x0
  pushl $21
8010758d:	6a 15                	push   $0x15
  jmp alltraps
8010758f:	e9 37 f8 ff ff       	jmp    80106dcb <alltraps>

80107594 <vector22>:
.globl vector22
vector22:
  pushl $0
80107594:	6a 00                	push   $0x0
  pushl $22
80107596:	6a 16                	push   $0x16
  jmp alltraps
80107598:	e9 2e f8 ff ff       	jmp    80106dcb <alltraps>

8010759d <vector23>:
.globl vector23
vector23:
  pushl $0
8010759d:	6a 00                	push   $0x0
  pushl $23
8010759f:	6a 17                	push   $0x17
  jmp alltraps
801075a1:	e9 25 f8 ff ff       	jmp    80106dcb <alltraps>

801075a6 <vector24>:
.globl vector24
vector24:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $24
801075a8:	6a 18                	push   $0x18
  jmp alltraps
801075aa:	e9 1c f8 ff ff       	jmp    80106dcb <alltraps>

801075af <vector25>:
.globl vector25
vector25:
  pushl $0
801075af:	6a 00                	push   $0x0
  pushl $25
801075b1:	6a 19                	push   $0x19
  jmp alltraps
801075b3:	e9 13 f8 ff ff       	jmp    80106dcb <alltraps>

801075b8 <vector26>:
.globl vector26
vector26:
  pushl $0
801075b8:	6a 00                	push   $0x0
  pushl $26
801075ba:	6a 1a                	push   $0x1a
  jmp alltraps
801075bc:	e9 0a f8 ff ff       	jmp    80106dcb <alltraps>

801075c1 <vector27>:
.globl vector27
vector27:
  pushl $0
801075c1:	6a 00                	push   $0x0
  pushl $27
801075c3:	6a 1b                	push   $0x1b
  jmp alltraps
801075c5:	e9 01 f8 ff ff       	jmp    80106dcb <alltraps>

801075ca <vector28>:
.globl vector28
vector28:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $28
801075cc:	6a 1c                	push   $0x1c
  jmp alltraps
801075ce:	e9 f8 f7 ff ff       	jmp    80106dcb <alltraps>

801075d3 <vector29>:
.globl vector29
vector29:
  pushl $0
801075d3:	6a 00                	push   $0x0
  pushl $29
801075d5:	6a 1d                	push   $0x1d
  jmp alltraps
801075d7:	e9 ef f7 ff ff       	jmp    80106dcb <alltraps>

801075dc <vector30>:
.globl vector30
vector30:
  pushl $0
801075dc:	6a 00                	push   $0x0
  pushl $30
801075de:	6a 1e                	push   $0x1e
  jmp alltraps
801075e0:	e9 e6 f7 ff ff       	jmp    80106dcb <alltraps>

801075e5 <vector31>:
.globl vector31
vector31:
  pushl $0
801075e5:	6a 00                	push   $0x0
  pushl $31
801075e7:	6a 1f                	push   $0x1f
  jmp alltraps
801075e9:	e9 dd f7 ff ff       	jmp    80106dcb <alltraps>

801075ee <vector32>:
.globl vector32
vector32:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $32
801075f0:	6a 20                	push   $0x20
  jmp alltraps
801075f2:	e9 d4 f7 ff ff       	jmp    80106dcb <alltraps>

801075f7 <vector33>:
.globl vector33
vector33:
  pushl $0
801075f7:	6a 00                	push   $0x0
  pushl $33
801075f9:	6a 21                	push   $0x21
  jmp alltraps
801075fb:	e9 cb f7 ff ff       	jmp    80106dcb <alltraps>

80107600 <vector34>:
.globl vector34
vector34:
  pushl $0
80107600:	6a 00                	push   $0x0
  pushl $34
80107602:	6a 22                	push   $0x22
  jmp alltraps
80107604:	e9 c2 f7 ff ff       	jmp    80106dcb <alltraps>

80107609 <vector35>:
.globl vector35
vector35:
  pushl $0
80107609:	6a 00                	push   $0x0
  pushl $35
8010760b:	6a 23                	push   $0x23
  jmp alltraps
8010760d:	e9 b9 f7 ff ff       	jmp    80106dcb <alltraps>

80107612 <vector36>:
.globl vector36
vector36:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $36
80107614:	6a 24                	push   $0x24
  jmp alltraps
80107616:	e9 b0 f7 ff ff       	jmp    80106dcb <alltraps>

8010761b <vector37>:
.globl vector37
vector37:
  pushl $0
8010761b:	6a 00                	push   $0x0
  pushl $37
8010761d:	6a 25                	push   $0x25
  jmp alltraps
8010761f:	e9 a7 f7 ff ff       	jmp    80106dcb <alltraps>

80107624 <vector38>:
.globl vector38
vector38:
  pushl $0
80107624:	6a 00                	push   $0x0
  pushl $38
80107626:	6a 26                	push   $0x26
  jmp alltraps
80107628:	e9 9e f7 ff ff       	jmp    80106dcb <alltraps>

8010762d <vector39>:
.globl vector39
vector39:
  pushl $0
8010762d:	6a 00                	push   $0x0
  pushl $39
8010762f:	6a 27                	push   $0x27
  jmp alltraps
80107631:	e9 95 f7 ff ff       	jmp    80106dcb <alltraps>

80107636 <vector40>:
.globl vector40
vector40:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $40
80107638:	6a 28                	push   $0x28
  jmp alltraps
8010763a:	e9 8c f7 ff ff       	jmp    80106dcb <alltraps>

8010763f <vector41>:
.globl vector41
vector41:
  pushl $0
8010763f:	6a 00                	push   $0x0
  pushl $41
80107641:	6a 29                	push   $0x29
  jmp alltraps
80107643:	e9 83 f7 ff ff       	jmp    80106dcb <alltraps>

80107648 <vector42>:
.globl vector42
vector42:
  pushl $0
80107648:	6a 00                	push   $0x0
  pushl $42
8010764a:	6a 2a                	push   $0x2a
  jmp alltraps
8010764c:	e9 7a f7 ff ff       	jmp    80106dcb <alltraps>

80107651 <vector43>:
.globl vector43
vector43:
  pushl $0
80107651:	6a 00                	push   $0x0
  pushl $43
80107653:	6a 2b                	push   $0x2b
  jmp alltraps
80107655:	e9 71 f7 ff ff       	jmp    80106dcb <alltraps>

8010765a <vector44>:
.globl vector44
vector44:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $44
8010765c:	6a 2c                	push   $0x2c
  jmp alltraps
8010765e:	e9 68 f7 ff ff       	jmp    80106dcb <alltraps>

80107663 <vector45>:
.globl vector45
vector45:
  pushl $0
80107663:	6a 00                	push   $0x0
  pushl $45
80107665:	6a 2d                	push   $0x2d
  jmp alltraps
80107667:	e9 5f f7 ff ff       	jmp    80106dcb <alltraps>

8010766c <vector46>:
.globl vector46
vector46:
  pushl $0
8010766c:	6a 00                	push   $0x0
  pushl $46
8010766e:	6a 2e                	push   $0x2e
  jmp alltraps
80107670:	e9 56 f7 ff ff       	jmp    80106dcb <alltraps>

80107675 <vector47>:
.globl vector47
vector47:
  pushl $0
80107675:	6a 00                	push   $0x0
  pushl $47
80107677:	6a 2f                	push   $0x2f
  jmp alltraps
80107679:	e9 4d f7 ff ff       	jmp    80106dcb <alltraps>

8010767e <vector48>:
.globl vector48
vector48:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $48
80107680:	6a 30                	push   $0x30
  jmp alltraps
80107682:	e9 44 f7 ff ff       	jmp    80106dcb <alltraps>

80107687 <vector49>:
.globl vector49
vector49:
  pushl $0
80107687:	6a 00                	push   $0x0
  pushl $49
80107689:	6a 31                	push   $0x31
  jmp alltraps
8010768b:	e9 3b f7 ff ff       	jmp    80106dcb <alltraps>

80107690 <vector50>:
.globl vector50
vector50:
  pushl $0
80107690:	6a 00                	push   $0x0
  pushl $50
80107692:	6a 32                	push   $0x32
  jmp alltraps
80107694:	e9 32 f7 ff ff       	jmp    80106dcb <alltraps>

80107699 <vector51>:
.globl vector51
vector51:
  pushl $0
80107699:	6a 00                	push   $0x0
  pushl $51
8010769b:	6a 33                	push   $0x33
  jmp alltraps
8010769d:	e9 29 f7 ff ff       	jmp    80106dcb <alltraps>

801076a2 <vector52>:
.globl vector52
vector52:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $52
801076a4:	6a 34                	push   $0x34
  jmp alltraps
801076a6:	e9 20 f7 ff ff       	jmp    80106dcb <alltraps>

801076ab <vector53>:
.globl vector53
vector53:
  pushl $0
801076ab:	6a 00                	push   $0x0
  pushl $53
801076ad:	6a 35                	push   $0x35
  jmp alltraps
801076af:	e9 17 f7 ff ff       	jmp    80106dcb <alltraps>

801076b4 <vector54>:
.globl vector54
vector54:
  pushl $0
801076b4:	6a 00                	push   $0x0
  pushl $54
801076b6:	6a 36                	push   $0x36
  jmp alltraps
801076b8:	e9 0e f7 ff ff       	jmp    80106dcb <alltraps>

801076bd <vector55>:
.globl vector55
vector55:
  pushl $0
801076bd:	6a 00                	push   $0x0
  pushl $55
801076bf:	6a 37                	push   $0x37
  jmp alltraps
801076c1:	e9 05 f7 ff ff       	jmp    80106dcb <alltraps>

801076c6 <vector56>:
.globl vector56
vector56:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $56
801076c8:	6a 38                	push   $0x38
  jmp alltraps
801076ca:	e9 fc f6 ff ff       	jmp    80106dcb <alltraps>

801076cf <vector57>:
.globl vector57
vector57:
  pushl $0
801076cf:	6a 00                	push   $0x0
  pushl $57
801076d1:	6a 39                	push   $0x39
  jmp alltraps
801076d3:	e9 f3 f6 ff ff       	jmp    80106dcb <alltraps>

801076d8 <vector58>:
.globl vector58
vector58:
  pushl $0
801076d8:	6a 00                	push   $0x0
  pushl $58
801076da:	6a 3a                	push   $0x3a
  jmp alltraps
801076dc:	e9 ea f6 ff ff       	jmp    80106dcb <alltraps>

801076e1 <vector59>:
.globl vector59
vector59:
  pushl $0
801076e1:	6a 00                	push   $0x0
  pushl $59
801076e3:	6a 3b                	push   $0x3b
  jmp alltraps
801076e5:	e9 e1 f6 ff ff       	jmp    80106dcb <alltraps>

801076ea <vector60>:
.globl vector60
vector60:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $60
801076ec:	6a 3c                	push   $0x3c
  jmp alltraps
801076ee:	e9 d8 f6 ff ff       	jmp    80106dcb <alltraps>

801076f3 <vector61>:
.globl vector61
vector61:
  pushl $0
801076f3:	6a 00                	push   $0x0
  pushl $61
801076f5:	6a 3d                	push   $0x3d
  jmp alltraps
801076f7:	e9 cf f6 ff ff       	jmp    80106dcb <alltraps>

801076fc <vector62>:
.globl vector62
vector62:
  pushl $0
801076fc:	6a 00                	push   $0x0
  pushl $62
801076fe:	6a 3e                	push   $0x3e
  jmp alltraps
80107700:	e9 c6 f6 ff ff       	jmp    80106dcb <alltraps>

80107705 <vector63>:
.globl vector63
vector63:
  pushl $0
80107705:	6a 00                	push   $0x0
  pushl $63
80107707:	6a 3f                	push   $0x3f
  jmp alltraps
80107709:	e9 bd f6 ff ff       	jmp    80106dcb <alltraps>

8010770e <vector64>:
.globl vector64
vector64:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $64
80107710:	6a 40                	push   $0x40
  jmp alltraps
80107712:	e9 b4 f6 ff ff       	jmp    80106dcb <alltraps>

80107717 <vector65>:
.globl vector65
vector65:
  pushl $0
80107717:	6a 00                	push   $0x0
  pushl $65
80107719:	6a 41                	push   $0x41
  jmp alltraps
8010771b:	e9 ab f6 ff ff       	jmp    80106dcb <alltraps>

80107720 <vector66>:
.globl vector66
vector66:
  pushl $0
80107720:	6a 00                	push   $0x0
  pushl $66
80107722:	6a 42                	push   $0x42
  jmp alltraps
80107724:	e9 a2 f6 ff ff       	jmp    80106dcb <alltraps>

80107729 <vector67>:
.globl vector67
vector67:
  pushl $0
80107729:	6a 00                	push   $0x0
  pushl $67
8010772b:	6a 43                	push   $0x43
  jmp alltraps
8010772d:	e9 99 f6 ff ff       	jmp    80106dcb <alltraps>

80107732 <vector68>:
.globl vector68
vector68:
  pushl $0
80107732:	6a 00                	push   $0x0
  pushl $68
80107734:	6a 44                	push   $0x44
  jmp alltraps
80107736:	e9 90 f6 ff ff       	jmp    80106dcb <alltraps>

8010773b <vector69>:
.globl vector69
vector69:
  pushl $0
8010773b:	6a 00                	push   $0x0
  pushl $69
8010773d:	6a 45                	push   $0x45
  jmp alltraps
8010773f:	e9 87 f6 ff ff       	jmp    80106dcb <alltraps>

80107744 <vector70>:
.globl vector70
vector70:
  pushl $0
80107744:	6a 00                	push   $0x0
  pushl $70
80107746:	6a 46                	push   $0x46
  jmp alltraps
80107748:	e9 7e f6 ff ff       	jmp    80106dcb <alltraps>

8010774d <vector71>:
.globl vector71
vector71:
  pushl $0
8010774d:	6a 00                	push   $0x0
  pushl $71
8010774f:	6a 47                	push   $0x47
  jmp alltraps
80107751:	e9 75 f6 ff ff       	jmp    80106dcb <alltraps>

80107756 <vector72>:
.globl vector72
vector72:
  pushl $0
80107756:	6a 00                	push   $0x0
  pushl $72
80107758:	6a 48                	push   $0x48
  jmp alltraps
8010775a:	e9 6c f6 ff ff       	jmp    80106dcb <alltraps>

8010775f <vector73>:
.globl vector73
vector73:
  pushl $0
8010775f:	6a 00                	push   $0x0
  pushl $73
80107761:	6a 49                	push   $0x49
  jmp alltraps
80107763:	e9 63 f6 ff ff       	jmp    80106dcb <alltraps>

80107768 <vector74>:
.globl vector74
vector74:
  pushl $0
80107768:	6a 00                	push   $0x0
  pushl $74
8010776a:	6a 4a                	push   $0x4a
  jmp alltraps
8010776c:	e9 5a f6 ff ff       	jmp    80106dcb <alltraps>

80107771 <vector75>:
.globl vector75
vector75:
  pushl $0
80107771:	6a 00                	push   $0x0
  pushl $75
80107773:	6a 4b                	push   $0x4b
  jmp alltraps
80107775:	e9 51 f6 ff ff       	jmp    80106dcb <alltraps>

8010777a <vector76>:
.globl vector76
vector76:
  pushl $0
8010777a:	6a 00                	push   $0x0
  pushl $76
8010777c:	6a 4c                	push   $0x4c
  jmp alltraps
8010777e:	e9 48 f6 ff ff       	jmp    80106dcb <alltraps>

80107783 <vector77>:
.globl vector77
vector77:
  pushl $0
80107783:	6a 00                	push   $0x0
  pushl $77
80107785:	6a 4d                	push   $0x4d
  jmp alltraps
80107787:	e9 3f f6 ff ff       	jmp    80106dcb <alltraps>

8010778c <vector78>:
.globl vector78
vector78:
  pushl $0
8010778c:	6a 00                	push   $0x0
  pushl $78
8010778e:	6a 4e                	push   $0x4e
  jmp alltraps
80107790:	e9 36 f6 ff ff       	jmp    80106dcb <alltraps>

80107795 <vector79>:
.globl vector79
vector79:
  pushl $0
80107795:	6a 00                	push   $0x0
  pushl $79
80107797:	6a 4f                	push   $0x4f
  jmp alltraps
80107799:	e9 2d f6 ff ff       	jmp    80106dcb <alltraps>

8010779e <vector80>:
.globl vector80
vector80:
  pushl $0
8010779e:	6a 00                	push   $0x0
  pushl $80
801077a0:	6a 50                	push   $0x50
  jmp alltraps
801077a2:	e9 24 f6 ff ff       	jmp    80106dcb <alltraps>

801077a7 <vector81>:
.globl vector81
vector81:
  pushl $0
801077a7:	6a 00                	push   $0x0
  pushl $81
801077a9:	6a 51                	push   $0x51
  jmp alltraps
801077ab:	e9 1b f6 ff ff       	jmp    80106dcb <alltraps>

801077b0 <vector82>:
.globl vector82
vector82:
  pushl $0
801077b0:	6a 00                	push   $0x0
  pushl $82
801077b2:	6a 52                	push   $0x52
  jmp alltraps
801077b4:	e9 12 f6 ff ff       	jmp    80106dcb <alltraps>

801077b9 <vector83>:
.globl vector83
vector83:
  pushl $0
801077b9:	6a 00                	push   $0x0
  pushl $83
801077bb:	6a 53                	push   $0x53
  jmp alltraps
801077bd:	e9 09 f6 ff ff       	jmp    80106dcb <alltraps>

801077c2 <vector84>:
.globl vector84
vector84:
  pushl $0
801077c2:	6a 00                	push   $0x0
  pushl $84
801077c4:	6a 54                	push   $0x54
  jmp alltraps
801077c6:	e9 00 f6 ff ff       	jmp    80106dcb <alltraps>

801077cb <vector85>:
.globl vector85
vector85:
  pushl $0
801077cb:	6a 00                	push   $0x0
  pushl $85
801077cd:	6a 55                	push   $0x55
  jmp alltraps
801077cf:	e9 f7 f5 ff ff       	jmp    80106dcb <alltraps>

801077d4 <vector86>:
.globl vector86
vector86:
  pushl $0
801077d4:	6a 00                	push   $0x0
  pushl $86
801077d6:	6a 56                	push   $0x56
  jmp alltraps
801077d8:	e9 ee f5 ff ff       	jmp    80106dcb <alltraps>

801077dd <vector87>:
.globl vector87
vector87:
  pushl $0
801077dd:	6a 00                	push   $0x0
  pushl $87
801077df:	6a 57                	push   $0x57
  jmp alltraps
801077e1:	e9 e5 f5 ff ff       	jmp    80106dcb <alltraps>

801077e6 <vector88>:
.globl vector88
vector88:
  pushl $0
801077e6:	6a 00                	push   $0x0
  pushl $88
801077e8:	6a 58                	push   $0x58
  jmp alltraps
801077ea:	e9 dc f5 ff ff       	jmp    80106dcb <alltraps>

801077ef <vector89>:
.globl vector89
vector89:
  pushl $0
801077ef:	6a 00                	push   $0x0
  pushl $89
801077f1:	6a 59                	push   $0x59
  jmp alltraps
801077f3:	e9 d3 f5 ff ff       	jmp    80106dcb <alltraps>

801077f8 <vector90>:
.globl vector90
vector90:
  pushl $0
801077f8:	6a 00                	push   $0x0
  pushl $90
801077fa:	6a 5a                	push   $0x5a
  jmp alltraps
801077fc:	e9 ca f5 ff ff       	jmp    80106dcb <alltraps>

80107801 <vector91>:
.globl vector91
vector91:
  pushl $0
80107801:	6a 00                	push   $0x0
  pushl $91
80107803:	6a 5b                	push   $0x5b
  jmp alltraps
80107805:	e9 c1 f5 ff ff       	jmp    80106dcb <alltraps>

8010780a <vector92>:
.globl vector92
vector92:
  pushl $0
8010780a:	6a 00                	push   $0x0
  pushl $92
8010780c:	6a 5c                	push   $0x5c
  jmp alltraps
8010780e:	e9 b8 f5 ff ff       	jmp    80106dcb <alltraps>

80107813 <vector93>:
.globl vector93
vector93:
  pushl $0
80107813:	6a 00                	push   $0x0
  pushl $93
80107815:	6a 5d                	push   $0x5d
  jmp alltraps
80107817:	e9 af f5 ff ff       	jmp    80106dcb <alltraps>

8010781c <vector94>:
.globl vector94
vector94:
  pushl $0
8010781c:	6a 00                	push   $0x0
  pushl $94
8010781e:	6a 5e                	push   $0x5e
  jmp alltraps
80107820:	e9 a6 f5 ff ff       	jmp    80106dcb <alltraps>

80107825 <vector95>:
.globl vector95
vector95:
  pushl $0
80107825:	6a 00                	push   $0x0
  pushl $95
80107827:	6a 5f                	push   $0x5f
  jmp alltraps
80107829:	e9 9d f5 ff ff       	jmp    80106dcb <alltraps>

8010782e <vector96>:
.globl vector96
vector96:
  pushl $0
8010782e:	6a 00                	push   $0x0
  pushl $96
80107830:	6a 60                	push   $0x60
  jmp alltraps
80107832:	e9 94 f5 ff ff       	jmp    80106dcb <alltraps>

80107837 <vector97>:
.globl vector97
vector97:
  pushl $0
80107837:	6a 00                	push   $0x0
  pushl $97
80107839:	6a 61                	push   $0x61
  jmp alltraps
8010783b:	e9 8b f5 ff ff       	jmp    80106dcb <alltraps>

80107840 <vector98>:
.globl vector98
vector98:
  pushl $0
80107840:	6a 00                	push   $0x0
  pushl $98
80107842:	6a 62                	push   $0x62
  jmp alltraps
80107844:	e9 82 f5 ff ff       	jmp    80106dcb <alltraps>

80107849 <vector99>:
.globl vector99
vector99:
  pushl $0
80107849:	6a 00                	push   $0x0
  pushl $99
8010784b:	6a 63                	push   $0x63
  jmp alltraps
8010784d:	e9 79 f5 ff ff       	jmp    80106dcb <alltraps>

80107852 <vector100>:
.globl vector100
vector100:
  pushl $0
80107852:	6a 00                	push   $0x0
  pushl $100
80107854:	6a 64                	push   $0x64
  jmp alltraps
80107856:	e9 70 f5 ff ff       	jmp    80106dcb <alltraps>

8010785b <vector101>:
.globl vector101
vector101:
  pushl $0
8010785b:	6a 00                	push   $0x0
  pushl $101
8010785d:	6a 65                	push   $0x65
  jmp alltraps
8010785f:	e9 67 f5 ff ff       	jmp    80106dcb <alltraps>

80107864 <vector102>:
.globl vector102
vector102:
  pushl $0
80107864:	6a 00                	push   $0x0
  pushl $102
80107866:	6a 66                	push   $0x66
  jmp alltraps
80107868:	e9 5e f5 ff ff       	jmp    80106dcb <alltraps>

8010786d <vector103>:
.globl vector103
vector103:
  pushl $0
8010786d:	6a 00                	push   $0x0
  pushl $103
8010786f:	6a 67                	push   $0x67
  jmp alltraps
80107871:	e9 55 f5 ff ff       	jmp    80106dcb <alltraps>

80107876 <vector104>:
.globl vector104
vector104:
  pushl $0
80107876:	6a 00                	push   $0x0
  pushl $104
80107878:	6a 68                	push   $0x68
  jmp alltraps
8010787a:	e9 4c f5 ff ff       	jmp    80106dcb <alltraps>

8010787f <vector105>:
.globl vector105
vector105:
  pushl $0
8010787f:	6a 00                	push   $0x0
  pushl $105
80107881:	6a 69                	push   $0x69
  jmp alltraps
80107883:	e9 43 f5 ff ff       	jmp    80106dcb <alltraps>

80107888 <vector106>:
.globl vector106
vector106:
  pushl $0
80107888:	6a 00                	push   $0x0
  pushl $106
8010788a:	6a 6a                	push   $0x6a
  jmp alltraps
8010788c:	e9 3a f5 ff ff       	jmp    80106dcb <alltraps>

80107891 <vector107>:
.globl vector107
vector107:
  pushl $0
80107891:	6a 00                	push   $0x0
  pushl $107
80107893:	6a 6b                	push   $0x6b
  jmp alltraps
80107895:	e9 31 f5 ff ff       	jmp    80106dcb <alltraps>

8010789a <vector108>:
.globl vector108
vector108:
  pushl $0
8010789a:	6a 00                	push   $0x0
  pushl $108
8010789c:	6a 6c                	push   $0x6c
  jmp alltraps
8010789e:	e9 28 f5 ff ff       	jmp    80106dcb <alltraps>

801078a3 <vector109>:
.globl vector109
vector109:
  pushl $0
801078a3:	6a 00                	push   $0x0
  pushl $109
801078a5:	6a 6d                	push   $0x6d
  jmp alltraps
801078a7:	e9 1f f5 ff ff       	jmp    80106dcb <alltraps>

801078ac <vector110>:
.globl vector110
vector110:
  pushl $0
801078ac:	6a 00                	push   $0x0
  pushl $110
801078ae:	6a 6e                	push   $0x6e
  jmp alltraps
801078b0:	e9 16 f5 ff ff       	jmp    80106dcb <alltraps>

801078b5 <vector111>:
.globl vector111
vector111:
  pushl $0
801078b5:	6a 00                	push   $0x0
  pushl $111
801078b7:	6a 6f                	push   $0x6f
  jmp alltraps
801078b9:	e9 0d f5 ff ff       	jmp    80106dcb <alltraps>

801078be <vector112>:
.globl vector112
vector112:
  pushl $0
801078be:	6a 00                	push   $0x0
  pushl $112
801078c0:	6a 70                	push   $0x70
  jmp alltraps
801078c2:	e9 04 f5 ff ff       	jmp    80106dcb <alltraps>

801078c7 <vector113>:
.globl vector113
vector113:
  pushl $0
801078c7:	6a 00                	push   $0x0
  pushl $113
801078c9:	6a 71                	push   $0x71
  jmp alltraps
801078cb:	e9 fb f4 ff ff       	jmp    80106dcb <alltraps>

801078d0 <vector114>:
.globl vector114
vector114:
  pushl $0
801078d0:	6a 00                	push   $0x0
  pushl $114
801078d2:	6a 72                	push   $0x72
  jmp alltraps
801078d4:	e9 f2 f4 ff ff       	jmp    80106dcb <alltraps>

801078d9 <vector115>:
.globl vector115
vector115:
  pushl $0
801078d9:	6a 00                	push   $0x0
  pushl $115
801078db:	6a 73                	push   $0x73
  jmp alltraps
801078dd:	e9 e9 f4 ff ff       	jmp    80106dcb <alltraps>

801078e2 <vector116>:
.globl vector116
vector116:
  pushl $0
801078e2:	6a 00                	push   $0x0
  pushl $116
801078e4:	6a 74                	push   $0x74
  jmp alltraps
801078e6:	e9 e0 f4 ff ff       	jmp    80106dcb <alltraps>

801078eb <vector117>:
.globl vector117
vector117:
  pushl $0
801078eb:	6a 00                	push   $0x0
  pushl $117
801078ed:	6a 75                	push   $0x75
  jmp alltraps
801078ef:	e9 d7 f4 ff ff       	jmp    80106dcb <alltraps>

801078f4 <vector118>:
.globl vector118
vector118:
  pushl $0
801078f4:	6a 00                	push   $0x0
  pushl $118
801078f6:	6a 76                	push   $0x76
  jmp alltraps
801078f8:	e9 ce f4 ff ff       	jmp    80106dcb <alltraps>

801078fd <vector119>:
.globl vector119
vector119:
  pushl $0
801078fd:	6a 00                	push   $0x0
  pushl $119
801078ff:	6a 77                	push   $0x77
  jmp alltraps
80107901:	e9 c5 f4 ff ff       	jmp    80106dcb <alltraps>

80107906 <vector120>:
.globl vector120
vector120:
  pushl $0
80107906:	6a 00                	push   $0x0
  pushl $120
80107908:	6a 78                	push   $0x78
  jmp alltraps
8010790a:	e9 bc f4 ff ff       	jmp    80106dcb <alltraps>

8010790f <vector121>:
.globl vector121
vector121:
  pushl $0
8010790f:	6a 00                	push   $0x0
  pushl $121
80107911:	6a 79                	push   $0x79
  jmp alltraps
80107913:	e9 b3 f4 ff ff       	jmp    80106dcb <alltraps>

80107918 <vector122>:
.globl vector122
vector122:
  pushl $0
80107918:	6a 00                	push   $0x0
  pushl $122
8010791a:	6a 7a                	push   $0x7a
  jmp alltraps
8010791c:	e9 aa f4 ff ff       	jmp    80106dcb <alltraps>

80107921 <vector123>:
.globl vector123
vector123:
  pushl $0
80107921:	6a 00                	push   $0x0
  pushl $123
80107923:	6a 7b                	push   $0x7b
  jmp alltraps
80107925:	e9 a1 f4 ff ff       	jmp    80106dcb <alltraps>

8010792a <vector124>:
.globl vector124
vector124:
  pushl $0
8010792a:	6a 00                	push   $0x0
  pushl $124
8010792c:	6a 7c                	push   $0x7c
  jmp alltraps
8010792e:	e9 98 f4 ff ff       	jmp    80106dcb <alltraps>

80107933 <vector125>:
.globl vector125
vector125:
  pushl $0
80107933:	6a 00                	push   $0x0
  pushl $125
80107935:	6a 7d                	push   $0x7d
  jmp alltraps
80107937:	e9 8f f4 ff ff       	jmp    80106dcb <alltraps>

8010793c <vector126>:
.globl vector126
vector126:
  pushl $0
8010793c:	6a 00                	push   $0x0
  pushl $126
8010793e:	6a 7e                	push   $0x7e
  jmp alltraps
80107940:	e9 86 f4 ff ff       	jmp    80106dcb <alltraps>

80107945 <vector127>:
.globl vector127
vector127:
  pushl $0
80107945:	6a 00                	push   $0x0
  pushl $127
80107947:	6a 7f                	push   $0x7f
  jmp alltraps
80107949:	e9 7d f4 ff ff       	jmp    80106dcb <alltraps>

8010794e <vector128>:
.globl vector128
vector128:
  pushl $0
8010794e:	6a 00                	push   $0x0
  pushl $128
80107950:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107955:	e9 71 f4 ff ff       	jmp    80106dcb <alltraps>

8010795a <vector129>:
.globl vector129
vector129:
  pushl $0
8010795a:	6a 00                	push   $0x0
  pushl $129
8010795c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107961:	e9 65 f4 ff ff       	jmp    80106dcb <alltraps>

80107966 <vector130>:
.globl vector130
vector130:
  pushl $0
80107966:	6a 00                	push   $0x0
  pushl $130
80107968:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010796d:	e9 59 f4 ff ff       	jmp    80106dcb <alltraps>

80107972 <vector131>:
.globl vector131
vector131:
  pushl $0
80107972:	6a 00                	push   $0x0
  pushl $131
80107974:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107979:	e9 4d f4 ff ff       	jmp    80106dcb <alltraps>

8010797e <vector132>:
.globl vector132
vector132:
  pushl $0
8010797e:	6a 00                	push   $0x0
  pushl $132
80107980:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107985:	e9 41 f4 ff ff       	jmp    80106dcb <alltraps>

8010798a <vector133>:
.globl vector133
vector133:
  pushl $0
8010798a:	6a 00                	push   $0x0
  pushl $133
8010798c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107991:	e9 35 f4 ff ff       	jmp    80106dcb <alltraps>

80107996 <vector134>:
.globl vector134
vector134:
  pushl $0
80107996:	6a 00                	push   $0x0
  pushl $134
80107998:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010799d:	e9 29 f4 ff ff       	jmp    80106dcb <alltraps>

801079a2 <vector135>:
.globl vector135
vector135:
  pushl $0
801079a2:	6a 00                	push   $0x0
  pushl $135
801079a4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079a9:	e9 1d f4 ff ff       	jmp    80106dcb <alltraps>

801079ae <vector136>:
.globl vector136
vector136:
  pushl $0
801079ae:	6a 00                	push   $0x0
  pushl $136
801079b0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801079b5:	e9 11 f4 ff ff       	jmp    80106dcb <alltraps>

801079ba <vector137>:
.globl vector137
vector137:
  pushl $0
801079ba:	6a 00                	push   $0x0
  pushl $137
801079bc:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801079c1:	e9 05 f4 ff ff       	jmp    80106dcb <alltraps>

801079c6 <vector138>:
.globl vector138
vector138:
  pushl $0
801079c6:	6a 00                	push   $0x0
  pushl $138
801079c8:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801079cd:	e9 f9 f3 ff ff       	jmp    80106dcb <alltraps>

801079d2 <vector139>:
.globl vector139
vector139:
  pushl $0
801079d2:	6a 00                	push   $0x0
  pushl $139
801079d4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801079d9:	e9 ed f3 ff ff       	jmp    80106dcb <alltraps>

801079de <vector140>:
.globl vector140
vector140:
  pushl $0
801079de:	6a 00                	push   $0x0
  pushl $140
801079e0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801079e5:	e9 e1 f3 ff ff       	jmp    80106dcb <alltraps>

801079ea <vector141>:
.globl vector141
vector141:
  pushl $0
801079ea:	6a 00                	push   $0x0
  pushl $141
801079ec:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801079f1:	e9 d5 f3 ff ff       	jmp    80106dcb <alltraps>

801079f6 <vector142>:
.globl vector142
vector142:
  pushl $0
801079f6:	6a 00                	push   $0x0
  pushl $142
801079f8:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801079fd:	e9 c9 f3 ff ff       	jmp    80106dcb <alltraps>

80107a02 <vector143>:
.globl vector143
vector143:
  pushl $0
80107a02:	6a 00                	push   $0x0
  pushl $143
80107a04:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a09:	e9 bd f3 ff ff       	jmp    80106dcb <alltraps>

80107a0e <vector144>:
.globl vector144
vector144:
  pushl $0
80107a0e:	6a 00                	push   $0x0
  pushl $144
80107a10:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a15:	e9 b1 f3 ff ff       	jmp    80106dcb <alltraps>

80107a1a <vector145>:
.globl vector145
vector145:
  pushl $0
80107a1a:	6a 00                	push   $0x0
  pushl $145
80107a1c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a21:	e9 a5 f3 ff ff       	jmp    80106dcb <alltraps>

80107a26 <vector146>:
.globl vector146
vector146:
  pushl $0
80107a26:	6a 00                	push   $0x0
  pushl $146
80107a28:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a2d:	e9 99 f3 ff ff       	jmp    80106dcb <alltraps>

80107a32 <vector147>:
.globl vector147
vector147:
  pushl $0
80107a32:	6a 00                	push   $0x0
  pushl $147
80107a34:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a39:	e9 8d f3 ff ff       	jmp    80106dcb <alltraps>

80107a3e <vector148>:
.globl vector148
vector148:
  pushl $0
80107a3e:	6a 00                	push   $0x0
  pushl $148
80107a40:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a45:	e9 81 f3 ff ff       	jmp    80106dcb <alltraps>

80107a4a <vector149>:
.globl vector149
vector149:
  pushl $0
80107a4a:	6a 00                	push   $0x0
  pushl $149
80107a4c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107a51:	e9 75 f3 ff ff       	jmp    80106dcb <alltraps>

80107a56 <vector150>:
.globl vector150
vector150:
  pushl $0
80107a56:	6a 00                	push   $0x0
  pushl $150
80107a58:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107a5d:	e9 69 f3 ff ff       	jmp    80106dcb <alltraps>

80107a62 <vector151>:
.globl vector151
vector151:
  pushl $0
80107a62:	6a 00                	push   $0x0
  pushl $151
80107a64:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107a69:	e9 5d f3 ff ff       	jmp    80106dcb <alltraps>

80107a6e <vector152>:
.globl vector152
vector152:
  pushl $0
80107a6e:	6a 00                	push   $0x0
  pushl $152
80107a70:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107a75:	e9 51 f3 ff ff       	jmp    80106dcb <alltraps>

80107a7a <vector153>:
.globl vector153
vector153:
  pushl $0
80107a7a:	6a 00                	push   $0x0
  pushl $153
80107a7c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107a81:	e9 45 f3 ff ff       	jmp    80106dcb <alltraps>

80107a86 <vector154>:
.globl vector154
vector154:
  pushl $0
80107a86:	6a 00                	push   $0x0
  pushl $154
80107a88:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107a8d:	e9 39 f3 ff ff       	jmp    80106dcb <alltraps>

80107a92 <vector155>:
.globl vector155
vector155:
  pushl $0
80107a92:	6a 00                	push   $0x0
  pushl $155
80107a94:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107a99:	e9 2d f3 ff ff       	jmp    80106dcb <alltraps>

80107a9e <vector156>:
.globl vector156
vector156:
  pushl $0
80107a9e:	6a 00                	push   $0x0
  pushl $156
80107aa0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107aa5:	e9 21 f3 ff ff       	jmp    80106dcb <alltraps>

80107aaa <vector157>:
.globl vector157
vector157:
  pushl $0
80107aaa:	6a 00                	push   $0x0
  pushl $157
80107aac:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ab1:	e9 15 f3 ff ff       	jmp    80106dcb <alltraps>

80107ab6 <vector158>:
.globl vector158
vector158:
  pushl $0
80107ab6:	6a 00                	push   $0x0
  pushl $158
80107ab8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107abd:	e9 09 f3 ff ff       	jmp    80106dcb <alltraps>

80107ac2 <vector159>:
.globl vector159
vector159:
  pushl $0
80107ac2:	6a 00                	push   $0x0
  pushl $159
80107ac4:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107ac9:	e9 fd f2 ff ff       	jmp    80106dcb <alltraps>

80107ace <vector160>:
.globl vector160
vector160:
  pushl $0
80107ace:	6a 00                	push   $0x0
  pushl $160
80107ad0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107ad5:	e9 f1 f2 ff ff       	jmp    80106dcb <alltraps>

80107ada <vector161>:
.globl vector161
vector161:
  pushl $0
80107ada:	6a 00                	push   $0x0
  pushl $161
80107adc:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107ae1:	e9 e5 f2 ff ff       	jmp    80106dcb <alltraps>

80107ae6 <vector162>:
.globl vector162
vector162:
  pushl $0
80107ae6:	6a 00                	push   $0x0
  pushl $162
80107ae8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107aed:	e9 d9 f2 ff ff       	jmp    80106dcb <alltraps>

80107af2 <vector163>:
.globl vector163
vector163:
  pushl $0
80107af2:	6a 00                	push   $0x0
  pushl $163
80107af4:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107af9:	e9 cd f2 ff ff       	jmp    80106dcb <alltraps>

80107afe <vector164>:
.globl vector164
vector164:
  pushl $0
80107afe:	6a 00                	push   $0x0
  pushl $164
80107b00:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b05:	e9 c1 f2 ff ff       	jmp    80106dcb <alltraps>

80107b0a <vector165>:
.globl vector165
vector165:
  pushl $0
80107b0a:	6a 00                	push   $0x0
  pushl $165
80107b0c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b11:	e9 b5 f2 ff ff       	jmp    80106dcb <alltraps>

80107b16 <vector166>:
.globl vector166
vector166:
  pushl $0
80107b16:	6a 00                	push   $0x0
  pushl $166
80107b18:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b1d:	e9 a9 f2 ff ff       	jmp    80106dcb <alltraps>

80107b22 <vector167>:
.globl vector167
vector167:
  pushl $0
80107b22:	6a 00                	push   $0x0
  pushl $167
80107b24:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b29:	e9 9d f2 ff ff       	jmp    80106dcb <alltraps>

80107b2e <vector168>:
.globl vector168
vector168:
  pushl $0
80107b2e:	6a 00                	push   $0x0
  pushl $168
80107b30:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b35:	e9 91 f2 ff ff       	jmp    80106dcb <alltraps>

80107b3a <vector169>:
.globl vector169
vector169:
  pushl $0
80107b3a:	6a 00                	push   $0x0
  pushl $169
80107b3c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b41:	e9 85 f2 ff ff       	jmp    80106dcb <alltraps>

80107b46 <vector170>:
.globl vector170
vector170:
  pushl $0
80107b46:	6a 00                	push   $0x0
  pushl $170
80107b48:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b4d:	e9 79 f2 ff ff       	jmp    80106dcb <alltraps>

80107b52 <vector171>:
.globl vector171
vector171:
  pushl $0
80107b52:	6a 00                	push   $0x0
  pushl $171
80107b54:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107b59:	e9 6d f2 ff ff       	jmp    80106dcb <alltraps>

80107b5e <vector172>:
.globl vector172
vector172:
  pushl $0
80107b5e:	6a 00                	push   $0x0
  pushl $172
80107b60:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107b65:	e9 61 f2 ff ff       	jmp    80106dcb <alltraps>

80107b6a <vector173>:
.globl vector173
vector173:
  pushl $0
80107b6a:	6a 00                	push   $0x0
  pushl $173
80107b6c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107b71:	e9 55 f2 ff ff       	jmp    80106dcb <alltraps>

80107b76 <vector174>:
.globl vector174
vector174:
  pushl $0
80107b76:	6a 00                	push   $0x0
  pushl $174
80107b78:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107b7d:	e9 49 f2 ff ff       	jmp    80106dcb <alltraps>

80107b82 <vector175>:
.globl vector175
vector175:
  pushl $0
80107b82:	6a 00                	push   $0x0
  pushl $175
80107b84:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107b89:	e9 3d f2 ff ff       	jmp    80106dcb <alltraps>

80107b8e <vector176>:
.globl vector176
vector176:
  pushl $0
80107b8e:	6a 00                	push   $0x0
  pushl $176
80107b90:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107b95:	e9 31 f2 ff ff       	jmp    80106dcb <alltraps>

80107b9a <vector177>:
.globl vector177
vector177:
  pushl $0
80107b9a:	6a 00                	push   $0x0
  pushl $177
80107b9c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107ba1:	e9 25 f2 ff ff       	jmp    80106dcb <alltraps>

80107ba6 <vector178>:
.globl vector178
vector178:
  pushl $0
80107ba6:	6a 00                	push   $0x0
  pushl $178
80107ba8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107bad:	e9 19 f2 ff ff       	jmp    80106dcb <alltraps>

80107bb2 <vector179>:
.globl vector179
vector179:
  pushl $0
80107bb2:	6a 00                	push   $0x0
  pushl $179
80107bb4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107bb9:	e9 0d f2 ff ff       	jmp    80106dcb <alltraps>

80107bbe <vector180>:
.globl vector180
vector180:
  pushl $0
80107bbe:	6a 00                	push   $0x0
  pushl $180
80107bc0:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107bc5:	e9 01 f2 ff ff       	jmp    80106dcb <alltraps>

80107bca <vector181>:
.globl vector181
vector181:
  pushl $0
80107bca:	6a 00                	push   $0x0
  pushl $181
80107bcc:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107bd1:	e9 f5 f1 ff ff       	jmp    80106dcb <alltraps>

80107bd6 <vector182>:
.globl vector182
vector182:
  pushl $0
80107bd6:	6a 00                	push   $0x0
  pushl $182
80107bd8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107bdd:	e9 e9 f1 ff ff       	jmp    80106dcb <alltraps>

80107be2 <vector183>:
.globl vector183
vector183:
  pushl $0
80107be2:	6a 00                	push   $0x0
  pushl $183
80107be4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107be9:	e9 dd f1 ff ff       	jmp    80106dcb <alltraps>

80107bee <vector184>:
.globl vector184
vector184:
  pushl $0
80107bee:	6a 00                	push   $0x0
  pushl $184
80107bf0:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107bf5:	e9 d1 f1 ff ff       	jmp    80106dcb <alltraps>

80107bfa <vector185>:
.globl vector185
vector185:
  pushl $0
80107bfa:	6a 00                	push   $0x0
  pushl $185
80107bfc:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c01:	e9 c5 f1 ff ff       	jmp    80106dcb <alltraps>

80107c06 <vector186>:
.globl vector186
vector186:
  pushl $0
80107c06:	6a 00                	push   $0x0
  pushl $186
80107c08:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c0d:	e9 b9 f1 ff ff       	jmp    80106dcb <alltraps>

80107c12 <vector187>:
.globl vector187
vector187:
  pushl $0
80107c12:	6a 00                	push   $0x0
  pushl $187
80107c14:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c19:	e9 ad f1 ff ff       	jmp    80106dcb <alltraps>

80107c1e <vector188>:
.globl vector188
vector188:
  pushl $0
80107c1e:	6a 00                	push   $0x0
  pushl $188
80107c20:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c25:	e9 a1 f1 ff ff       	jmp    80106dcb <alltraps>

80107c2a <vector189>:
.globl vector189
vector189:
  pushl $0
80107c2a:	6a 00                	push   $0x0
  pushl $189
80107c2c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c31:	e9 95 f1 ff ff       	jmp    80106dcb <alltraps>

80107c36 <vector190>:
.globl vector190
vector190:
  pushl $0
80107c36:	6a 00                	push   $0x0
  pushl $190
80107c38:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c3d:	e9 89 f1 ff ff       	jmp    80106dcb <alltraps>

80107c42 <vector191>:
.globl vector191
vector191:
  pushl $0
80107c42:	6a 00                	push   $0x0
  pushl $191
80107c44:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c49:	e9 7d f1 ff ff       	jmp    80106dcb <alltraps>

80107c4e <vector192>:
.globl vector192
vector192:
  pushl $0
80107c4e:	6a 00                	push   $0x0
  pushl $192
80107c50:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107c55:	e9 71 f1 ff ff       	jmp    80106dcb <alltraps>

80107c5a <vector193>:
.globl vector193
vector193:
  pushl $0
80107c5a:	6a 00                	push   $0x0
  pushl $193
80107c5c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107c61:	e9 65 f1 ff ff       	jmp    80106dcb <alltraps>

80107c66 <vector194>:
.globl vector194
vector194:
  pushl $0
80107c66:	6a 00                	push   $0x0
  pushl $194
80107c68:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107c6d:	e9 59 f1 ff ff       	jmp    80106dcb <alltraps>

80107c72 <vector195>:
.globl vector195
vector195:
  pushl $0
80107c72:	6a 00                	push   $0x0
  pushl $195
80107c74:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107c79:	e9 4d f1 ff ff       	jmp    80106dcb <alltraps>

80107c7e <vector196>:
.globl vector196
vector196:
  pushl $0
80107c7e:	6a 00                	push   $0x0
  pushl $196
80107c80:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107c85:	e9 41 f1 ff ff       	jmp    80106dcb <alltraps>

80107c8a <vector197>:
.globl vector197
vector197:
  pushl $0
80107c8a:	6a 00                	push   $0x0
  pushl $197
80107c8c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107c91:	e9 35 f1 ff ff       	jmp    80106dcb <alltraps>

80107c96 <vector198>:
.globl vector198
vector198:
  pushl $0
80107c96:	6a 00                	push   $0x0
  pushl $198
80107c98:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107c9d:	e9 29 f1 ff ff       	jmp    80106dcb <alltraps>

80107ca2 <vector199>:
.globl vector199
vector199:
  pushl $0
80107ca2:	6a 00                	push   $0x0
  pushl $199
80107ca4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107ca9:	e9 1d f1 ff ff       	jmp    80106dcb <alltraps>

80107cae <vector200>:
.globl vector200
vector200:
  pushl $0
80107cae:	6a 00                	push   $0x0
  pushl $200
80107cb0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107cb5:	e9 11 f1 ff ff       	jmp    80106dcb <alltraps>

80107cba <vector201>:
.globl vector201
vector201:
  pushl $0
80107cba:	6a 00                	push   $0x0
  pushl $201
80107cbc:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107cc1:	e9 05 f1 ff ff       	jmp    80106dcb <alltraps>

80107cc6 <vector202>:
.globl vector202
vector202:
  pushl $0
80107cc6:	6a 00                	push   $0x0
  pushl $202
80107cc8:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107ccd:	e9 f9 f0 ff ff       	jmp    80106dcb <alltraps>

80107cd2 <vector203>:
.globl vector203
vector203:
  pushl $0
80107cd2:	6a 00                	push   $0x0
  pushl $203
80107cd4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107cd9:	e9 ed f0 ff ff       	jmp    80106dcb <alltraps>

80107cde <vector204>:
.globl vector204
vector204:
  pushl $0
80107cde:	6a 00                	push   $0x0
  pushl $204
80107ce0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107ce5:	e9 e1 f0 ff ff       	jmp    80106dcb <alltraps>

80107cea <vector205>:
.globl vector205
vector205:
  pushl $0
80107cea:	6a 00                	push   $0x0
  pushl $205
80107cec:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107cf1:	e9 d5 f0 ff ff       	jmp    80106dcb <alltraps>

80107cf6 <vector206>:
.globl vector206
vector206:
  pushl $0
80107cf6:	6a 00                	push   $0x0
  pushl $206
80107cf8:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107cfd:	e9 c9 f0 ff ff       	jmp    80106dcb <alltraps>

80107d02 <vector207>:
.globl vector207
vector207:
  pushl $0
80107d02:	6a 00                	push   $0x0
  pushl $207
80107d04:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d09:	e9 bd f0 ff ff       	jmp    80106dcb <alltraps>

80107d0e <vector208>:
.globl vector208
vector208:
  pushl $0
80107d0e:	6a 00                	push   $0x0
  pushl $208
80107d10:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d15:	e9 b1 f0 ff ff       	jmp    80106dcb <alltraps>

80107d1a <vector209>:
.globl vector209
vector209:
  pushl $0
80107d1a:	6a 00                	push   $0x0
  pushl $209
80107d1c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d21:	e9 a5 f0 ff ff       	jmp    80106dcb <alltraps>

80107d26 <vector210>:
.globl vector210
vector210:
  pushl $0
80107d26:	6a 00                	push   $0x0
  pushl $210
80107d28:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d2d:	e9 99 f0 ff ff       	jmp    80106dcb <alltraps>

80107d32 <vector211>:
.globl vector211
vector211:
  pushl $0
80107d32:	6a 00                	push   $0x0
  pushl $211
80107d34:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d39:	e9 8d f0 ff ff       	jmp    80106dcb <alltraps>

80107d3e <vector212>:
.globl vector212
vector212:
  pushl $0
80107d3e:	6a 00                	push   $0x0
  pushl $212
80107d40:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d45:	e9 81 f0 ff ff       	jmp    80106dcb <alltraps>

80107d4a <vector213>:
.globl vector213
vector213:
  pushl $0
80107d4a:	6a 00                	push   $0x0
  pushl $213
80107d4c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107d51:	e9 75 f0 ff ff       	jmp    80106dcb <alltraps>

80107d56 <vector214>:
.globl vector214
vector214:
  pushl $0
80107d56:	6a 00                	push   $0x0
  pushl $214
80107d58:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107d5d:	e9 69 f0 ff ff       	jmp    80106dcb <alltraps>

80107d62 <vector215>:
.globl vector215
vector215:
  pushl $0
80107d62:	6a 00                	push   $0x0
  pushl $215
80107d64:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107d69:	e9 5d f0 ff ff       	jmp    80106dcb <alltraps>

80107d6e <vector216>:
.globl vector216
vector216:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $216
80107d70:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107d75:	e9 51 f0 ff ff       	jmp    80106dcb <alltraps>

80107d7a <vector217>:
.globl vector217
vector217:
  pushl $0
80107d7a:	6a 00                	push   $0x0
  pushl $217
80107d7c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107d81:	e9 45 f0 ff ff       	jmp    80106dcb <alltraps>

80107d86 <vector218>:
.globl vector218
vector218:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $218
80107d88:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107d8d:	e9 39 f0 ff ff       	jmp    80106dcb <alltraps>

80107d92 <vector219>:
.globl vector219
vector219:
  pushl $0
80107d92:	6a 00                	push   $0x0
  pushl $219
80107d94:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107d99:	e9 2d f0 ff ff       	jmp    80106dcb <alltraps>

80107d9e <vector220>:
.globl vector220
vector220:
  pushl $0
80107d9e:	6a 00                	push   $0x0
  pushl $220
80107da0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107da5:	e9 21 f0 ff ff       	jmp    80106dcb <alltraps>

80107daa <vector221>:
.globl vector221
vector221:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $221
80107dac:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107db1:	e9 15 f0 ff ff       	jmp    80106dcb <alltraps>

80107db6 <vector222>:
.globl vector222
vector222:
  pushl $0
80107db6:	6a 00                	push   $0x0
  pushl $222
80107db8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107dbd:	e9 09 f0 ff ff       	jmp    80106dcb <alltraps>

80107dc2 <vector223>:
.globl vector223
vector223:
  pushl $0
80107dc2:	6a 00                	push   $0x0
  pushl $223
80107dc4:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107dc9:	e9 fd ef ff ff       	jmp    80106dcb <alltraps>

80107dce <vector224>:
.globl vector224
vector224:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $224
80107dd0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107dd5:	e9 f1 ef ff ff       	jmp    80106dcb <alltraps>

80107dda <vector225>:
.globl vector225
vector225:
  pushl $0
80107dda:	6a 00                	push   $0x0
  pushl $225
80107ddc:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107de1:	e9 e5 ef ff ff       	jmp    80106dcb <alltraps>

80107de6 <vector226>:
.globl vector226
vector226:
  pushl $0
80107de6:	6a 00                	push   $0x0
  pushl $226
80107de8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107ded:	e9 d9 ef ff ff       	jmp    80106dcb <alltraps>

80107df2 <vector227>:
.globl vector227
vector227:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $227
80107df4:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107df9:	e9 cd ef ff ff       	jmp    80106dcb <alltraps>

80107dfe <vector228>:
.globl vector228
vector228:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $228
80107e00:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e05:	e9 c1 ef ff ff       	jmp    80106dcb <alltraps>

80107e0a <vector229>:
.globl vector229
vector229:
  pushl $0
80107e0a:	6a 00                	push   $0x0
  pushl $229
80107e0c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e11:	e9 b5 ef ff ff       	jmp    80106dcb <alltraps>

80107e16 <vector230>:
.globl vector230
vector230:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $230
80107e18:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e1d:	e9 a9 ef ff ff       	jmp    80106dcb <alltraps>

80107e22 <vector231>:
.globl vector231
vector231:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $231
80107e24:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e29:	e9 9d ef ff ff       	jmp    80106dcb <alltraps>

80107e2e <vector232>:
.globl vector232
vector232:
  pushl $0
80107e2e:	6a 00                	push   $0x0
  pushl $232
80107e30:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e35:	e9 91 ef ff ff       	jmp    80106dcb <alltraps>

80107e3a <vector233>:
.globl vector233
vector233:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $233
80107e3c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e41:	e9 85 ef ff ff       	jmp    80106dcb <alltraps>

80107e46 <vector234>:
.globl vector234
vector234:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $234
80107e48:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e4d:	e9 79 ef ff ff       	jmp    80106dcb <alltraps>

80107e52 <vector235>:
.globl vector235
vector235:
  pushl $0
80107e52:	6a 00                	push   $0x0
  pushl $235
80107e54:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107e59:	e9 6d ef ff ff       	jmp    80106dcb <alltraps>

80107e5e <vector236>:
.globl vector236
vector236:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $236
80107e60:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107e65:	e9 61 ef ff ff       	jmp    80106dcb <alltraps>

80107e6a <vector237>:
.globl vector237
vector237:
  pushl $0
80107e6a:	6a 00                	push   $0x0
  pushl $237
80107e6c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107e71:	e9 55 ef ff ff       	jmp    80106dcb <alltraps>

80107e76 <vector238>:
.globl vector238
vector238:
  pushl $0
80107e76:	6a 00                	push   $0x0
  pushl $238
80107e78:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107e7d:	e9 49 ef ff ff       	jmp    80106dcb <alltraps>

80107e82 <vector239>:
.globl vector239
vector239:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $239
80107e84:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107e89:	e9 3d ef ff ff       	jmp    80106dcb <alltraps>

80107e8e <vector240>:
.globl vector240
vector240:
  pushl $0
80107e8e:	6a 00                	push   $0x0
  pushl $240
80107e90:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107e95:	e9 31 ef ff ff       	jmp    80106dcb <alltraps>

80107e9a <vector241>:
.globl vector241
vector241:
  pushl $0
80107e9a:	6a 00                	push   $0x0
  pushl $241
80107e9c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107ea1:	e9 25 ef ff ff       	jmp    80106dcb <alltraps>

80107ea6 <vector242>:
.globl vector242
vector242:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $242
80107ea8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107ead:	e9 19 ef ff ff       	jmp    80106dcb <alltraps>

80107eb2 <vector243>:
.globl vector243
vector243:
  pushl $0
80107eb2:	6a 00                	push   $0x0
  pushl $243
80107eb4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107eb9:	e9 0d ef ff ff       	jmp    80106dcb <alltraps>

80107ebe <vector244>:
.globl vector244
vector244:
  pushl $0
80107ebe:	6a 00                	push   $0x0
  pushl $244
80107ec0:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107ec5:	e9 01 ef ff ff       	jmp    80106dcb <alltraps>

80107eca <vector245>:
.globl vector245
vector245:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $245
80107ecc:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107ed1:	e9 f5 ee ff ff       	jmp    80106dcb <alltraps>

80107ed6 <vector246>:
.globl vector246
vector246:
  pushl $0
80107ed6:	6a 00                	push   $0x0
  pushl $246
80107ed8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107edd:	e9 e9 ee ff ff       	jmp    80106dcb <alltraps>

80107ee2 <vector247>:
.globl vector247
vector247:
  pushl $0
80107ee2:	6a 00                	push   $0x0
  pushl $247
80107ee4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107ee9:	e9 dd ee ff ff       	jmp    80106dcb <alltraps>

80107eee <vector248>:
.globl vector248
vector248:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $248
80107ef0:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107ef5:	e9 d1 ee ff ff       	jmp    80106dcb <alltraps>

80107efa <vector249>:
.globl vector249
vector249:
  pushl $0
80107efa:	6a 00                	push   $0x0
  pushl $249
80107efc:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f01:	e9 c5 ee ff ff       	jmp    80106dcb <alltraps>

80107f06 <vector250>:
.globl vector250
vector250:
  pushl $0
80107f06:	6a 00                	push   $0x0
  pushl $250
80107f08:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f0d:	e9 b9 ee ff ff       	jmp    80106dcb <alltraps>

80107f12 <vector251>:
.globl vector251
vector251:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $251
80107f14:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f19:	e9 ad ee ff ff       	jmp    80106dcb <alltraps>

80107f1e <vector252>:
.globl vector252
vector252:
  pushl $0
80107f1e:	6a 00                	push   $0x0
  pushl $252
80107f20:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f25:	e9 a1 ee ff ff       	jmp    80106dcb <alltraps>

80107f2a <vector253>:
.globl vector253
vector253:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $253
80107f2c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f31:	e9 95 ee ff ff       	jmp    80106dcb <alltraps>

80107f36 <vector254>:
.globl vector254
vector254:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $254
80107f38:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f3d:	e9 89 ee ff ff       	jmp    80106dcb <alltraps>

80107f42 <vector255>:
.globl vector255
vector255:
  pushl $0
80107f42:	6a 00                	push   $0x0
  pushl $255
80107f44:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f49:	e9 7d ee ff ff       	jmp    80106dcb <alltraps>

80107f4e <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f4e:	55                   	push   %ebp
80107f4f:	89 e5                	mov    %esp,%ebp
80107f51:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107f54:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f57:	83 e8 01             	sub    $0x1,%eax
80107f5a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107f5e:	8b 45 08             	mov    0x8(%ebp),%eax
80107f61:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107f65:	8b 45 08             	mov    0x8(%ebp),%eax
80107f68:	c1 e8 10             	shr    $0x10,%eax
80107f6b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107f6f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107f72:	0f 01 10             	lgdtl  (%eax)
}
80107f75:	c9                   	leave  
80107f76:	c3                   	ret    

80107f77 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107f77:	55                   	push   %ebp
80107f78:	89 e5                	mov    %esp,%ebp
80107f7a:	83 ec 04             	sub    $0x4,%esp
80107f7d:	8b 45 08             	mov    0x8(%ebp),%eax
80107f80:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107f84:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f88:	0f 00 d8             	ltr    %ax
}
80107f8b:	c9                   	leave  
80107f8c:	c3                   	ret    

80107f8d <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107f8d:	55                   	push   %ebp
80107f8e:	89 e5                	mov    %esp,%ebp
80107f90:	83 ec 04             	sub    $0x4,%esp
80107f93:	8b 45 08             	mov    0x8(%ebp),%eax
80107f96:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107f9a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f9e:	8e e8                	mov    %eax,%gs
}
80107fa0:	c9                   	leave  
80107fa1:	c3                   	ret    

80107fa2 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107fa2:	55                   	push   %ebp
80107fa3:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa8:	0f 22 d8             	mov    %eax,%cr3
}
80107fab:	5d                   	pop    %ebp
80107fac:	c3                   	ret    

80107fad <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107fad:	55                   	push   %ebp
80107fae:	89 e5                	mov    %esp,%ebp
80107fb0:	8b 45 08             	mov    0x8(%ebp),%eax
80107fb3:	05 00 00 00 80       	add    $0x80000000,%eax
80107fb8:	5d                   	pop    %ebp
80107fb9:	c3                   	ret    

80107fba <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107fba:	55                   	push   %ebp
80107fbb:	89 e5                	mov    %esp,%ebp
80107fbd:	8b 45 08             	mov    0x8(%ebp),%eax
80107fc0:	05 00 00 00 80       	add    $0x80000000,%eax
80107fc5:	5d                   	pop    %ebp
80107fc6:	c3                   	ret    

80107fc7 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107fc7:	55                   	push   %ebp
80107fc8:	89 e5                	mov    %esp,%ebp
80107fca:	53                   	push   %ebx
80107fcb:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107fce:	e8 31 b6 ff ff       	call   80103604 <cpunum>
80107fd3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107fd9:	05 60 43 11 80       	add    $0x80114360,%eax
80107fde:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe4:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107fea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fed:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107ff3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff6:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107ffa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ffd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108001:	83 e2 f0             	and    $0xfffffff0,%edx
80108004:	83 ca 0a             	or     $0xa,%edx
80108007:	88 50 7d             	mov    %dl,0x7d(%eax)
8010800a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108011:	83 ca 10             	or     $0x10,%edx
80108014:	88 50 7d             	mov    %dl,0x7d(%eax)
80108017:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010801a:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010801e:	83 e2 9f             	and    $0xffffff9f,%edx
80108021:	88 50 7d             	mov    %dl,0x7d(%eax)
80108024:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108027:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010802b:	83 ca 80             	or     $0xffffff80,%edx
8010802e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108031:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108034:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108038:	83 ca 0f             	or     $0xf,%edx
8010803b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010803e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108041:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108045:	83 e2 ef             	and    $0xffffffef,%edx
80108048:	88 50 7e             	mov    %dl,0x7e(%eax)
8010804b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010804e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108052:	83 e2 df             	and    $0xffffffdf,%edx
80108055:	88 50 7e             	mov    %dl,0x7e(%eax)
80108058:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010805b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010805f:	83 ca 40             	or     $0x40,%edx
80108062:	88 50 7e             	mov    %dl,0x7e(%eax)
80108065:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108068:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010806c:	83 ca 80             	or     $0xffffff80,%edx
8010806f:	88 50 7e             	mov    %dl,0x7e(%eax)
80108072:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108075:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108079:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807c:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108083:	ff ff 
80108085:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108088:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010808f:	00 00 
80108091:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108094:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010809b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080a5:	83 e2 f0             	and    $0xfffffff0,%edx
801080a8:	83 ca 02             	or     $0x2,%edx
801080ab:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080bb:	83 ca 10             	or     $0x10,%edx
801080be:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c7:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080ce:	83 e2 9f             	and    $0xffffff9f,%edx
801080d1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080da:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080e1:	83 ca 80             	or     $0xffffff80,%edx
801080e4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ed:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801080f4:	83 ca 0f             	or     $0xf,%edx
801080f7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108100:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108107:	83 e2 ef             	and    $0xffffffef,%edx
8010810a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108113:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010811a:	83 e2 df             	and    $0xffffffdf,%edx
8010811d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108123:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108126:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010812d:	83 ca 40             	or     $0x40,%edx
80108130:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108139:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108140:	83 ca 80             	or     $0xffffff80,%edx
80108143:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108149:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010814c:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108153:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108156:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010815d:	ff ff 
8010815f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108162:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108169:	00 00 
8010816b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816e:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108175:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108178:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010817f:	83 e2 f0             	and    $0xfffffff0,%edx
80108182:	83 ca 0a             	or     $0xa,%edx
80108185:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010818b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010818e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108195:	83 ca 10             	or     $0x10,%edx
80108198:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010819e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a1:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081a8:	83 ca 60             	or     $0x60,%edx
801081ab:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081bb:	83 ca 80             	or     $0xffffff80,%edx
801081be:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081ce:	83 ca 0f             	or     $0xf,%edx
801081d1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081da:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081e1:	83 e2 ef             	and    $0xffffffef,%edx
801081e4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ed:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081f4:	83 e2 df             	and    $0xffffffdf,%edx
801081f7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108200:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108207:	83 ca 40             	or     $0x40,%edx
8010820a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108210:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108213:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010821a:	83 ca 80             	or     $0xffffff80,%edx
8010821d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108226:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010822d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108230:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108237:	ff ff 
80108239:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823c:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108243:	00 00 
80108245:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108248:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010824f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108252:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108259:	83 e2 f0             	and    $0xfffffff0,%edx
8010825c:	83 ca 02             	or     $0x2,%edx
8010825f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108265:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108268:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010826f:	83 ca 10             	or     $0x10,%edx
80108272:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010827b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108282:	83 ca 60             	or     $0x60,%edx
80108285:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010828b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108295:	83 ca 80             	or     $0xffffff80,%edx
80108298:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010829e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082a8:	83 ca 0f             	or     $0xf,%edx
801082ab:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082bb:	83 e2 ef             	and    $0xffffffef,%edx
801082be:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082ce:	83 e2 df             	and    $0xffffffdf,%edx
801082d1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082da:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082e1:	83 ca 40             	or     $0x40,%edx
801082e4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ed:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082f4:	83 ca 80             	or     $0xffffff80,%edx
801082f7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108300:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108307:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830a:	05 b4 00 00 00       	add    $0xb4,%eax
8010830f:	89 c3                	mov    %eax,%ebx
80108311:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108314:	05 b4 00 00 00       	add    $0xb4,%eax
80108319:	c1 e8 10             	shr    $0x10,%eax
8010831c:	89 c1                	mov    %eax,%ecx
8010831e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108321:	05 b4 00 00 00       	add    $0xb4,%eax
80108326:	c1 e8 18             	shr    $0x18,%eax
80108329:	89 c2                	mov    %eax,%edx
8010832b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832e:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108335:	00 00 
80108337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833a:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108341:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108344:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010834a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108354:	83 e1 f0             	and    $0xfffffff0,%ecx
80108357:	83 c9 02             	or     $0x2,%ecx
8010835a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108363:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010836a:	83 c9 10             	or     $0x10,%ecx
8010836d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108373:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108376:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010837d:	83 e1 9f             	and    $0xffffff9f,%ecx
80108380:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108386:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108389:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108390:	83 c9 80             	or     $0xffffff80,%ecx
80108393:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108399:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083a3:	83 e1 f0             	and    $0xfffffff0,%ecx
801083a6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083af:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083b6:	83 e1 ef             	and    $0xffffffef,%ecx
801083b9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083c9:	83 e1 df             	and    $0xffffffdf,%ecx
801083cc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083dc:	83 c9 40             	or     $0x40,%ecx
801083df:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083ef:	83 c9 80             	or     $0xffffff80,%ecx
801083f2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fb:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108401:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108404:	83 c0 70             	add    $0x70,%eax
80108407:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010840e:	00 
8010840f:	89 04 24             	mov    %eax,(%esp)
80108412:	e8 37 fb ff ff       	call   80107f4e <lgdt>
  loadgs(SEG_KCPU << 3);
80108417:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010841e:	e8 6a fb ff ff       	call   80107f8d <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108426:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010842c:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108433:	00 00 00 00 
}
80108437:	83 c4 24             	add    $0x24,%esp
8010843a:	5b                   	pop    %ebx
8010843b:	5d                   	pop    %ebp
8010843c:	c3                   	ret    

8010843d <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010843d:	55                   	push   %ebp
8010843e:	89 e5                	mov    %esp,%ebp
80108440:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108443:	8b 45 0c             	mov    0xc(%ebp),%eax
80108446:	c1 e8 16             	shr    $0x16,%eax
80108449:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108450:	8b 45 08             	mov    0x8(%ebp),%eax
80108453:	01 d0                	add    %edx,%eax
80108455:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010845b:	8b 00                	mov    (%eax),%eax
8010845d:	83 e0 01             	and    $0x1,%eax
80108460:	85 c0                	test   %eax,%eax
80108462:	74 17                	je     8010847b <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108464:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108467:	8b 00                	mov    (%eax),%eax
80108469:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010846e:	89 04 24             	mov    %eax,(%esp)
80108471:	e8 44 fb ff ff       	call   80107fba <p2v>
80108476:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108479:	eb 4b                	jmp    801084c6 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010847b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010847f:	74 0e                	je     8010848f <walkpgdir+0x52>
80108481:	e8 a2 ad ff ff       	call   80103228 <kalloc>
80108486:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108489:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010848d:	75 07                	jne    80108496 <walkpgdir+0x59>
      return 0;
8010848f:	b8 00 00 00 00       	mov    $0x0,%eax
80108494:	eb 47                	jmp    801084dd <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108496:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010849d:	00 
8010849e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084a5:	00 
801084a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a9:	89 04 24             	mov    %eax,(%esp)
801084ac:	e8 11 d5 ff ff       	call   801059c2 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801084b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084b4:	89 04 24             	mov    %eax,(%esp)
801084b7:	e8 f1 fa ff ff       	call   80107fad <v2p>
801084bc:	83 c8 07             	or     $0x7,%eax
801084bf:	89 c2                	mov    %eax,%edx
801084c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084c4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801084c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801084c9:	c1 e8 0c             	shr    $0xc,%eax
801084cc:	25 ff 03 00 00       	and    $0x3ff,%eax
801084d1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084db:	01 d0                	add    %edx,%eax
}
801084dd:	c9                   	leave  
801084de:	c3                   	ret    

801084df <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801084df:	55                   	push   %ebp
801084e0:	89 e5                	mov    %esp,%ebp
801084e2:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801084e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801084e8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801084f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801084f3:	8b 45 10             	mov    0x10(%ebp),%eax
801084f6:	01 d0                	add    %edx,%eax
801084f8:	83 e8 01             	sub    $0x1,%eax
801084fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108500:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108503:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010850a:	00 
8010850b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108512:	8b 45 08             	mov    0x8(%ebp),%eax
80108515:	89 04 24             	mov    %eax,(%esp)
80108518:	e8 20 ff ff ff       	call   8010843d <walkpgdir>
8010851d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108520:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108524:	75 07                	jne    8010852d <mappages+0x4e>
      return -1;
80108526:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010852b:	eb 48                	jmp    80108575 <mappages+0x96>
    if(*pte & PTE_P)
8010852d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108530:	8b 00                	mov    (%eax),%eax
80108532:	83 e0 01             	and    $0x1,%eax
80108535:	85 c0                	test   %eax,%eax
80108537:	74 0c                	je     80108545 <mappages+0x66>
      panic("remap");
80108539:	c7 04 24 e4 a2 10 80 	movl   $0x8010a2e4,(%esp)
80108540:	e8 f5 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108545:	8b 45 18             	mov    0x18(%ebp),%eax
80108548:	0b 45 14             	or     0x14(%ebp),%eax
8010854b:	83 c8 01             	or     $0x1,%eax
8010854e:	89 c2                	mov    %eax,%edx
80108550:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108553:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108555:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108558:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010855b:	75 08                	jne    80108565 <mappages+0x86>
      break;
8010855d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010855e:	b8 00 00 00 00       	mov    $0x0,%eax
80108563:	eb 10                	jmp    80108575 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80108565:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
8010856c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108573:	eb 8e                	jmp    80108503 <mappages+0x24>
  return 0;
}
80108575:	c9                   	leave  
80108576:	c3                   	ret    

80108577 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80108577:	55                   	push   %ebp
80108578:	89 e5                	mov    %esp,%ebp
8010857a:	53                   	push   %ebx
8010857b:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
8010857e:	e8 a5 ac ff ff       	call   80103228 <kalloc>
80108583:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108586:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010858a:	75 0a                	jne    80108596 <setupkvm+0x1f>
    return 0;
8010858c:	b8 00 00 00 00       	mov    $0x0,%eax
80108591:	e9 98 00 00 00       	jmp    8010862e <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108596:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010859d:	00 
8010859e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085a5:	00 
801085a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085a9:	89 04 24             	mov    %eax,(%esp)
801085ac:	e8 11 d4 ff ff       	call   801059c2 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801085b1:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801085b8:	e8 fd f9 ff ff       	call   80107fba <p2v>
801085bd:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801085c2:	76 0c                	jbe    801085d0 <setupkvm+0x59>
    panic("PHYSTOP too high");
801085c4:	c7 04 24 ea a2 10 80 	movl   $0x8010a2ea,(%esp)
801085cb:	e8 6a 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801085d0:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
801085d7:	eb 49                	jmp    80108622 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801085d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085dc:	8b 48 0c             	mov    0xc(%eax),%ecx
801085df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e2:	8b 50 04             	mov    0x4(%eax),%edx
801085e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e8:	8b 58 08             	mov    0x8(%eax),%ebx
801085eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ee:	8b 40 04             	mov    0x4(%eax),%eax
801085f1:	29 c3                	sub    %eax,%ebx
801085f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f6:	8b 00                	mov    (%eax),%eax
801085f8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801085fc:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108600:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108604:	89 44 24 04          	mov    %eax,0x4(%esp)
80108608:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010860b:	89 04 24             	mov    %eax,(%esp)
8010860e:	e8 cc fe ff ff       	call   801084df <mappages>
80108613:	85 c0                	test   %eax,%eax
80108615:	79 07                	jns    8010861e <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108617:	b8 00 00 00 00       	mov    $0x0,%eax
8010861c:	eb 10                	jmp    8010862e <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010861e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108622:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108629:	72 ae                	jb     801085d9 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
8010862b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
8010862e:	83 c4 34             	add    $0x34,%esp
80108631:	5b                   	pop    %ebx
80108632:	5d                   	pop    %ebp
80108633:	c3                   	ret    

80108634 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
80108634:	55                   	push   %ebp
80108635:	89 e5                	mov    %esp,%ebp
80108637:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
8010863a:	e8 38 ff ff ff       	call   80108577 <setupkvm>
8010863f:	a3 58 0d 12 80       	mov    %eax,0x80120d58
    switchkvm();
80108644:	e8 02 00 00 00       	call   8010864b <switchkvm>
  }
80108649:	c9                   	leave  
8010864a:	c3                   	ret    

8010864b <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
8010864b:	55                   	push   %ebp
8010864c:	89 e5                	mov    %esp,%ebp
8010864e:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108651:	a1 58 0d 12 80       	mov    0x80120d58,%eax
80108656:	89 04 24             	mov    %eax,(%esp)
80108659:	e8 4f f9 ff ff       	call   80107fad <v2p>
8010865e:	89 04 24             	mov    %eax,(%esp)
80108661:	e8 3c f9 ff ff       	call   80107fa2 <lcr3>
}
80108666:	c9                   	leave  
80108667:	c3                   	ret    

80108668 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108668:	55                   	push   %ebp
80108669:	89 e5                	mov    %esp,%ebp
8010866b:	53                   	push   %ebx
8010866c:	83 ec 14             	sub    $0x14,%esp
  pushcli();
8010866f:	e8 4e d2 ff ff       	call   801058c2 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108674:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010867a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108681:	83 c2 08             	add    $0x8,%edx
80108684:	89 d3                	mov    %edx,%ebx
80108686:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010868d:	83 c2 08             	add    $0x8,%edx
80108690:	c1 ea 10             	shr    $0x10,%edx
80108693:	89 d1                	mov    %edx,%ecx
80108695:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010869c:	83 c2 08             	add    $0x8,%edx
8010869f:	c1 ea 18             	shr    $0x18,%edx
801086a2:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801086a9:	67 00 
801086ab:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801086b2:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801086b8:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086bf:	83 e1 f0             	and    $0xfffffff0,%ecx
801086c2:	83 c9 09             	or     $0x9,%ecx
801086c5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086cb:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086d2:	83 c9 10             	or     $0x10,%ecx
801086d5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086db:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086e2:	83 e1 9f             	and    $0xffffff9f,%ecx
801086e5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086eb:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086f2:	83 c9 80             	or     $0xffffff80,%ecx
801086f5:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086fb:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108702:	83 e1 f0             	and    $0xfffffff0,%ecx
80108705:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010870b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108712:	83 e1 ef             	and    $0xffffffef,%ecx
80108715:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010871b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108722:	83 e1 df             	and    $0xffffffdf,%ecx
80108725:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010872b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108732:	83 c9 40             	or     $0x40,%ecx
80108735:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010873b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108742:	83 e1 7f             	and    $0x7f,%ecx
80108745:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010874b:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108751:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108757:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010875e:	83 e2 ef             	and    $0xffffffef,%edx
80108761:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108767:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010876d:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108773:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108779:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108780:	8b 52 08             	mov    0x8(%edx),%edx
80108783:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108789:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010878c:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108793:	e8 df f7 ff ff       	call   80107f77 <ltr>
  if(p->pgdir == 0)
80108798:	8b 45 08             	mov    0x8(%ebp),%eax
8010879b:	8b 40 04             	mov    0x4(%eax),%eax
8010879e:	85 c0                	test   %eax,%eax
801087a0:	75 0c                	jne    801087ae <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801087a2:	c7 04 24 fb a2 10 80 	movl   $0x8010a2fb,(%esp)
801087a9:	e8 8c 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801087ae:	8b 45 08             	mov    0x8(%ebp),%eax
801087b1:	8b 40 04             	mov    0x4(%eax),%eax
801087b4:	89 04 24             	mov    %eax,(%esp)
801087b7:	e8 f1 f7 ff ff       	call   80107fad <v2p>
801087bc:	89 04 24             	mov    %eax,(%esp)
801087bf:	e8 de f7 ff ff       	call   80107fa2 <lcr3>
  popcli();
801087c4:	e8 3d d1 ff ff       	call   80105906 <popcli>
}
801087c9:	83 c4 14             	add    $0x14,%esp
801087cc:	5b                   	pop    %ebx
801087cd:	5d                   	pop    %ebp
801087ce:	c3                   	ret    

801087cf <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801087cf:	55                   	push   %ebp
801087d0:	89 e5                	mov    %esp,%ebp
801087d2:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801087d5:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801087dc:	76 0c                	jbe    801087ea <inituvm+0x1b>
    panic("inituvm: more than a page");
801087de:	c7 04 24 0f a3 10 80 	movl   $0x8010a30f,(%esp)
801087e5:	e8 50 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
801087ea:	e8 39 aa ff ff       	call   80103228 <kalloc>
801087ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801087f2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801087f9:	00 
801087fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108801:	00 
80108802:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108805:	89 04 24             	mov    %eax,(%esp)
80108808:	e8 b5 d1 ff ff       	call   801059c2 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010880d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108810:	89 04 24             	mov    %eax,(%esp)
80108813:	e8 95 f7 ff ff       	call   80107fad <v2p>
80108818:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010881f:	00 
80108820:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108824:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010882b:	00 
8010882c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108833:	00 
80108834:	8b 45 08             	mov    0x8(%ebp),%eax
80108837:	89 04 24             	mov    %eax,(%esp)
8010883a:	e8 a0 fc ff ff       	call   801084df <mappages>
  memmove(mem, init, sz);
8010883f:	8b 45 10             	mov    0x10(%ebp),%eax
80108842:	89 44 24 08          	mov    %eax,0x8(%esp)
80108846:	8b 45 0c             	mov    0xc(%ebp),%eax
80108849:	89 44 24 04          	mov    %eax,0x4(%esp)
8010884d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108850:	89 04 24             	mov    %eax,(%esp)
80108853:	e8 39 d2 ff ff       	call   80105a91 <memmove>
}
80108858:	c9                   	leave  
80108859:	c3                   	ret    

8010885a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010885a:	55                   	push   %ebp
8010885b:	89 e5                	mov    %esp,%ebp
8010885d:	53                   	push   %ebx
8010885e:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108861:	8b 45 0c             	mov    0xc(%ebp),%eax
80108864:	25 ff 0f 00 00       	and    $0xfff,%eax
80108869:	85 c0                	test   %eax,%eax
8010886b:	74 0c                	je     80108879 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010886d:	c7 04 24 2c a3 10 80 	movl   $0x8010a32c,(%esp)
80108874:	e8 c1 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108879:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108880:	e9 a9 00 00 00       	jmp    8010892e <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108888:	8b 55 0c             	mov    0xc(%ebp),%edx
8010888b:	01 d0                	add    %edx,%eax
8010888d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108894:	00 
80108895:	89 44 24 04          	mov    %eax,0x4(%esp)
80108899:	8b 45 08             	mov    0x8(%ebp),%eax
8010889c:	89 04 24             	mov    %eax,(%esp)
8010889f:	e8 99 fb ff ff       	call   8010843d <walkpgdir>
801088a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801088a7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088ab:	75 0c                	jne    801088b9 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801088ad:	c7 04 24 4f a3 10 80 	movl   $0x8010a34f,(%esp)
801088b4:	e8 81 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801088b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088bc:	8b 00                	mov    (%eax),%eax
801088be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088c3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801088c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c9:	8b 55 18             	mov    0x18(%ebp),%edx
801088cc:	29 c2                	sub    %eax,%edx
801088ce:	89 d0                	mov    %edx,%eax
801088d0:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801088d5:	77 0f                	ja     801088e6 <loaduvm+0x8c>
      n = sz - i;
801088d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088da:	8b 55 18             	mov    0x18(%ebp),%edx
801088dd:	29 c2                	sub    %eax,%edx
801088df:	89 d0                	mov    %edx,%eax
801088e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801088e4:	eb 07                	jmp    801088ed <loaduvm+0x93>
    else
      n = PGSIZE;
801088e6:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801088ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f0:	8b 55 14             	mov    0x14(%ebp),%edx
801088f3:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801088f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801088f9:	89 04 24             	mov    %eax,(%esp)
801088fc:	e8 b9 f6 ff ff       	call   80107fba <p2v>
80108901:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108904:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108908:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010890c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108910:	8b 45 10             	mov    0x10(%ebp),%eax
80108913:	89 04 24             	mov    %eax,(%esp)
80108916:	e8 b1 95 ff ff       	call   80101ecc <readi>
8010891b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010891e:	74 07                	je     80108927 <loaduvm+0xcd>
      return -1;
80108920:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108925:	eb 18                	jmp    8010893f <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108927:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010892e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108931:	3b 45 18             	cmp    0x18(%ebp),%eax
80108934:	0f 82 4b ff ff ff    	jb     80108885 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010893a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010893f:	83 c4 24             	add    $0x24,%esp
80108942:	5b                   	pop    %ebx
80108943:	5d                   	pop    %ebp
80108944:	c3                   	ret    

80108945 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108945:	55                   	push   %ebp
80108946:	89 e5                	mov    %esp,%ebp
80108948:	53                   	push   %ebx
80108949:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
8010894c:	8b 45 10             	mov    0x10(%ebp),%eax
8010894f:	85 c0                	test   %eax,%eax
80108951:	79 0a                	jns    8010895d <allocuvm+0x18>
    return 0;
80108953:	b8 00 00 00 00       	mov    $0x0,%eax
80108958:	e9 1b 02 00 00       	jmp    80108b78 <allocuvm+0x233>
  if(newsz < oldsz)
8010895d:	8b 45 10             	mov    0x10(%ebp),%eax
80108960:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108963:	73 08                	jae    8010896d <allocuvm+0x28>
    return oldsz;
80108965:	8b 45 0c             	mov    0xc(%ebp),%eax
80108968:	e9 0b 02 00 00       	jmp    80108b78 <allocuvm+0x233>

  a = PGROUNDUP(oldsz);
8010896d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108970:	05 ff 0f 00 00       	add    $0xfff,%eax
80108975:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010897a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010897d:	e9 e7 01 00 00       	jmp    80108b69 <allocuvm+0x224>
    mem = kalloc();
80108982:	e8 a1 a8 ff ff       	call   80103228 <kalloc>
80108987:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
8010898a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010898e:	75 36                	jne    801089c6 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
80108990:	c7 04 24 6d a3 10 80 	movl   $0x8010a36d,(%esp)
80108997:	e8 04 7a ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
8010899c:	8b 45 14             	mov    0x14(%ebp),%eax
8010899f:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801089a6:	89 44 24 08          	mov    %eax,0x8(%esp)
801089aa:	8b 45 10             	mov    0x10(%ebp),%eax
801089ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801089b1:	8b 45 08             	mov    0x8(%ebp),%eax
801089b4:	89 04 24             	mov    %eax,(%esp)
801089b7:	e8 c2 01 00 00       	call   80108b7e <deallocuvm>
      return 0;
801089bc:	b8 00 00 00 00       	mov    $0x0,%eax
801089c1:	e9 b2 01 00 00       	jmp    80108b78 <allocuvm+0x233>
    }
    memset(mem, 0, PGSIZE);
801089c6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089cd:	00 
801089ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089d5:	00 
801089d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089d9:	89 04 24             	mov    %eax,(%esp)
801089dc:	e8 e1 cf ff ff       	call   801059c2 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801089e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089e4:	89 04 24             	mov    %eax,(%esp)
801089e7:	e8 c1 f5 ff ff       	call   80107fad <v2p>
801089ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801089ef:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801089f6:	00 
801089f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a02:	00 
80108a03:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a07:	8b 45 08             	mov    0x8(%ebp),%eax
80108a0a:	89 04 24             	mov    %eax,(%esp)
80108a0d:	e8 cd fa ff ff       	call   801084df <mappages>
    //find the next open cell in pages array
      i=0;
80108a12:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a19:	eb 16                	jmp    80108a31 <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a1b:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a1f:	7e 0c                	jle    80108a2d <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a21:	c7 04 24 88 a3 10 80 	movl   $0x8010a388,(%esp)
80108a28:	e8 0d 7b ff ff       	call   8010053a <panic>
        }
        i++;
80108a2d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a31:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a34:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a37:	89 d0                	mov    %edx,%eax
80108a39:	c1 e0 02             	shl    $0x2,%eax
80108a3c:	01 d0                	add    %edx,%eax
80108a3e:	c1 e0 02             	shl    $0x2,%eax
80108a41:	01 c8                	add    %ecx,%eax
80108a43:	05 90 00 00 00       	add    $0x90,%eax
80108a48:	8b 00                	mov    (%eax),%eax
80108a4a:	83 f8 ff             	cmp    $0xffffffff,%eax
80108a4d:	75 cc                	jne    80108a1b <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
80108a4f:	8b 45 14             	mov    0x14(%ebp),%eax
80108a52:	8b 40 10             	mov    0x10(%eax),%eax
80108a55:	83 f8 01             	cmp    $0x1,%eax
80108a58:	74 4c                	je     80108aa6 <allocuvm+0x161>
80108a5a:	8b 45 14             	mov    0x14(%ebp),%eax
80108a5d:	8b 40 10             	mov    0x10(%eax),%eax
80108a60:	83 f8 02             	cmp    $0x2,%eax
80108a63:	74 41                	je     80108aa6 <allocuvm+0x161>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108a65:	8b 45 14             	mov    0x14(%ebp),%eax
80108a68:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108a6e:	83 f8 0e             	cmp    $0xe,%eax
80108a71:	76 1c                	jbe    80108a8f <allocuvm+0x14a>
          swapOut();
80108a73:	e8 fe 0b 00 00       	call   80109676 <swapOut>
          proc->swapedPagesCounter++;
80108a78:	8b 45 14             	mov    0x14(%ebp),%eax
80108a7b:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108a81:	8d 50 01             	lea    0x1(%eax),%edx
80108a84:	8b 45 14             	mov    0x14(%ebp),%eax
80108a87:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108a8d:	eb 2c                	jmp    80108abb <allocuvm+0x176>
          swapOut();
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108a8f:	8b 45 14             	mov    0x14(%ebp),%eax
80108a92:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108a98:	8d 50 01             	lea    0x1(%eax),%edx
80108a9b:	8b 45 14             	mov    0x14(%ebp),%eax
80108a9e:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108aa4:	eb 15                	jmp    80108abb <allocuvm+0x176>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108aa6:	8b 45 14             	mov    0x14(%ebp),%eax
80108aa9:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108aaf:	8d 50 01             	lea    0x1(%eax),%edx
80108ab2:	8b 45 14             	mov    0x14(%ebp),%eax
80108ab5:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108abb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108abe:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108ac1:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ac4:	89 d0                	mov    %edx,%eax
80108ac6:	c1 e0 02             	shl    $0x2,%eax
80108ac9:	01 d0                	add    %edx,%eax
80108acb:	c1 e0 02             	shl    $0x2,%eax
80108ace:	01 d8                	add    %ebx,%eax
80108ad0:	05 90 00 00 00       	add    $0x90,%eax
80108ad5:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108ad7:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108ada:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108add:	89 d0                	mov    %edx,%eax
80108adf:	c1 e0 02             	shl    $0x2,%eax
80108ae2:	01 d0                	add    %edx,%eax
80108ae4:	c1 e0 02             	shl    $0x2,%eax
80108ae7:	01 c8                	add    %ecx,%eax
80108ae9:	05 94 00 00 00       	add    $0x94,%eax
80108aee:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108af4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108af7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108afa:	89 d0                	mov    %edx,%eax
80108afc:	c1 e0 02             	shl    $0x2,%eax
80108aff:	01 d0                	add    %edx,%eax
80108b01:	c1 e0 02             	shl    $0x2,%eax
80108b04:	01 c8                	add    %ecx,%eax
80108b06:	05 98 00 00 00       	add    $0x98,%eax
80108b0b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b11:	8b 45 14             	mov    0x14(%ebp),%eax
80108b14:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b1a:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b1d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b20:	89 d0                	mov    %edx,%eax
80108b22:	c1 e0 02             	shl    $0x2,%eax
80108b25:	01 d0                	add    %edx,%eax
80108b27:	c1 e0 02             	shl    $0x2,%eax
80108b2a:	01 d8                	add    %ebx,%eax
80108b2c:	05 9c 00 00 00       	add    $0x9c,%eax
80108b31:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108b33:	8b 45 14             	mov    0x14(%ebp),%eax
80108b36:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108b3c:	8d 50 01             	lea    0x1(%eax),%edx
80108b3f:	8b 45 14             	mov    0x14(%ebp),%eax
80108b42:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108b48:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b4b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b4e:	89 d0                	mov    %edx,%eax
80108b50:	c1 e0 02             	shl    $0x2,%eax
80108b53:	01 d0                	add    %edx,%eax
80108b55:	c1 e0 02             	shl    $0x2,%eax
80108b58:	01 c8                	add    %ecx,%eax
80108b5a:	05 a0 00 00 00       	add    $0xa0,%eax
80108b5f:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108b62:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108b69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80108b6f:	0f 82 0d fe ff ff    	jb     80108982 <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108b75:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108b78:	83 c4 34             	add    $0x34,%esp
80108b7b:	5b                   	pop    %ebx
80108b7c:	5d                   	pop    %ebp
80108b7d:	c3                   	ret    

80108b7e <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108b7e:	55                   	push   %ebp
80108b7f:	89 e5                	mov    %esp,%ebp
80108b81:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108b84:	8b 45 10             	mov    0x10(%ebp),%eax
80108b87:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108b8a:	72 08                	jb     80108b94 <deallocuvm+0x16>
    return oldsz;
80108b8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b8f:	e9 27 02 00 00       	jmp    80108dbb <deallocuvm+0x23d>

  a = PGROUNDUP(newsz);
80108b94:	8b 45 10             	mov    0x10(%ebp),%eax
80108b97:	05 ff 0f 00 00       	add    $0xfff,%eax
80108b9c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ba1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108ba4:	e9 03 02 00 00       	jmp    80108dac <deallocuvm+0x22e>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108ba9:	8b 45 14             	mov    0x14(%ebp),%eax
80108bac:	8b 40 04             	mov    0x4(%eax),%eax
80108baf:	3b 45 08             	cmp    0x8(%ebp),%eax
80108bb2:	0f 85 0b 01 00 00    	jne    80108cc3 <deallocuvm+0x145>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108bb8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108bbf:	e9 f5 00 00 00       	jmp    80108cb9 <deallocuvm+0x13b>
          if(proc->pagesMetaData[i].va == (char *)a){
80108bc4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108bc7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108bca:	89 d0                	mov    %edx,%eax
80108bcc:	c1 e0 02             	shl    $0x2,%eax
80108bcf:	01 d0                	add    %edx,%eax
80108bd1:	c1 e0 02             	shl    $0x2,%eax
80108bd4:	01 c8                	add    %ecx,%eax
80108bd6:	05 90 00 00 00       	add    $0x90,%eax
80108bdb:	8b 10                	mov    (%eax),%edx
80108bdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be0:	39 c2                	cmp    %eax,%edx
80108be2:	0f 85 cd 00 00 00    	jne    80108cb5 <deallocuvm+0x137>
            if(proc->pid != 1 && proc->pid != 2){
80108be8:	8b 45 14             	mov    0x14(%ebp),%eax
80108beb:	8b 40 10             	mov    0x10(%eax),%eax
80108bee:	83 f8 01             	cmp    $0x1,%eax
80108bf1:	74 56                	je     80108c49 <deallocuvm+0xcb>
80108bf3:	8b 45 14             	mov    0x14(%ebp),%eax
80108bf6:	8b 40 10             	mov    0x10(%eax),%eax
80108bf9:	83 f8 02             	cmp    $0x2,%eax
80108bfc:	74 4b                	je     80108c49 <deallocuvm+0xcb>
              if(proc->pagesMetaData[i].isPhysical){
80108bfe:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c01:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c04:	89 d0                	mov    %edx,%eax
80108c06:	c1 e0 02             	shl    $0x2,%eax
80108c09:	01 d0                	add    %edx,%eax
80108c0b:	c1 e0 02             	shl    $0x2,%eax
80108c0e:	01 c8                	add    %ecx,%eax
80108c10:	05 94 00 00 00       	add    $0x94,%eax
80108c15:	8b 00                	mov    (%eax),%eax
80108c17:	85 c0                	test   %eax,%eax
80108c19:	74 17                	je     80108c32 <deallocuvm+0xb4>
                proc->memoryPagesCounter--;
80108c1b:	8b 45 14             	mov    0x14(%ebp),%eax
80108c1e:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c24:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c27:	8b 45 14             	mov    0x14(%ebp),%eax
80108c2a:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c30:	eb 2c                	jmp    80108c5e <deallocuvm+0xe0>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108c32:	8b 45 14             	mov    0x14(%ebp),%eax
80108c35:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108c3b:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c3e:	8b 45 14             	mov    0x14(%ebp),%eax
80108c41:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c47:	eb 15                	jmp    80108c5e <deallocuvm+0xe0>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108c49:	8b 45 14             	mov    0x14(%ebp),%eax
80108c4c:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c52:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c55:	8b 45 14             	mov    0x14(%ebp),%eax
80108c58:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108c5e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c61:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c64:	89 d0                	mov    %edx,%eax
80108c66:	c1 e0 02             	shl    $0x2,%eax
80108c69:	01 d0                	add    %edx,%eax
80108c6b:	c1 e0 02             	shl    $0x2,%eax
80108c6e:	01 c8                	add    %ecx,%eax
80108c70:	05 90 00 00 00       	add    $0x90,%eax
80108c75:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108c7b:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c7e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c81:	89 d0                	mov    %edx,%eax
80108c83:	c1 e0 02             	shl    $0x2,%eax
80108c86:	01 d0                	add    %edx,%eax
80108c88:	c1 e0 02             	shl    $0x2,%eax
80108c8b:	01 c8                	add    %ecx,%eax
80108c8d:	05 94 00 00 00       	add    $0x94,%eax
80108c92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108c98:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c9b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c9e:	89 d0                	mov    %edx,%eax
80108ca0:	c1 e0 02             	shl    $0x2,%eax
80108ca3:	01 d0                	add    %edx,%eax
80108ca5:	c1 e0 02             	shl    $0x2,%eax
80108ca8:	01 c8                	add    %ecx,%eax
80108caa:	05 98 00 00 00       	add    $0x98,%eax
80108caf:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108cb5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108cb9:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108cbd:	0f 8e 01 ff ff ff    	jle    80108bc4 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ccd:	00 
80108cce:	89 44 24 04          	mov    %eax,0x4(%esp)
80108cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80108cd5:	89 04 24             	mov    %eax,(%esp)
80108cd8:	e8 60 f7 ff ff       	call   8010843d <walkpgdir>
80108cdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108ce0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ce4:	75 0c                	jne    80108cf2 <deallocuvm+0x174>
      a += (NPTENTRIES - 1) * PGSIZE;
80108ce6:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108ced:	e9 b3 00 00 00       	jmp    80108da5 <deallocuvm+0x227>
    else if((*pte & PTE_P) != 0){
80108cf2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108cf5:	8b 00                	mov    (%eax),%eax
80108cf7:	83 e0 01             	and    $0x1,%eax
80108cfa:	85 c0                	test   %eax,%eax
80108cfc:	74 76                	je     80108d74 <deallocuvm+0x1f6>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108cfe:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d01:	8b 00                	mov    (%eax),%eax
80108d03:	25 00 02 00 00       	and    $0x200,%eax
80108d08:	85 c0                	test   %eax,%eax
80108d0a:	75 43                	jne    80108d4f <deallocuvm+0x1d1>
        pa = PTE_ADDR(*pte);
80108d0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d0f:	8b 00                	mov    (%eax),%eax
80108d11:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d16:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d19:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d1d:	75 0c                	jne    80108d2b <deallocuvm+0x1ad>
          panic("kfree");
80108d1f:	c7 04 24 b2 a3 10 80 	movl   $0x8010a3b2,(%esp)
80108d26:	e8 0f 78 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108d2b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d2e:	89 04 24             	mov    %eax,(%esp)
80108d31:	e8 84 f2 ff ff       	call   80107fba <p2v>
80108d36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108d39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d3c:	89 04 24             	mov    %eax,(%esp)
80108d3f:	e8 22 a4 ff ff       	call   80103166 <kfree>
        *pte = 0;
80108d44:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d47:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d4d:	eb 56                	jmp    80108da5 <deallocuvm+0x227>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108d4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x",PTE_ADDR(*pte));
80108d58:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d5b:	8b 00                	mov    (%eax),%eax
80108d5d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d62:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d66:	c7 04 24 b8 a3 10 80 	movl   $0x8010a3b8,(%esp)
80108d6d:	e8 2e 76 ff ff       	call   801003a0 <cprintf>
80108d72:	eb 31                	jmp    80108da5 <deallocuvm+0x227>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108d74:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d77:	8b 00                	mov    (%eax),%eax
80108d79:	25 00 02 00 00       	and    $0x200,%eax
80108d7e:	85 c0                	test   %eax,%eax
80108d80:	74 23                	je     80108da5 <deallocuvm+0x227>
        *pte = 0;
80108d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
80108d8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d8e:	8b 00                	mov    (%eax),%eax
80108d90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d95:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d99:	c7 04 24 c6 a3 10 80 	movl   $0x8010a3c6,(%esp)
80108da0:	e8 fb 75 ff ff       	call   801003a0 <cprintf>
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108da5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108dac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108daf:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108db2:	0f 82 f1 fd ff ff    	jb     80108ba9 <deallocuvm+0x2b>
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
    }
  }
  return newsz;
80108db8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108dbb:	c9                   	leave  
80108dbc:	c3                   	ret    

80108dbd <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108dbd:	55                   	push   %ebp
80108dbe:	89 e5                	mov    %esp,%ebp
80108dc0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108dc3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108dc7:	75 0c                	jne    80108dd5 <freevm+0x18>
    panic("freevm: no pgdir");
80108dc9:	c7 04 24 d5 a3 10 80 	movl   $0x8010a3d5,(%esp)
80108dd0:	e8 65 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108dd5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108ddb:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108ddf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108de6:	00 
80108de7:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108dee:	80 
80108def:	8b 45 08             	mov    0x8(%ebp),%eax
80108df2:	89 04 24             	mov    %eax,(%esp)
80108df5:	e8 84 fd ff ff       	call   80108b7e <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108dfa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e01:	eb 48                	jmp    80108e4b <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e06:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80108e10:	01 d0                	add    %edx,%eax
80108e12:	8b 00                	mov    (%eax),%eax
80108e14:	83 e0 01             	and    $0x1,%eax
80108e17:	85 c0                	test   %eax,%eax
80108e19:	74 2c                	je     80108e47 <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e1e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e25:	8b 45 08             	mov    0x8(%ebp),%eax
80108e28:	01 d0                	add    %edx,%eax
80108e2a:	8b 00                	mov    (%eax),%eax
80108e2c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e31:	89 04 24             	mov    %eax,(%esp)
80108e34:	e8 81 f1 ff ff       	call   80107fba <p2v>
80108e39:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e3f:	89 04 24             	mov    %eax,(%esp)
80108e42:	e8 1f a3 ff ff       	call   80103166 <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e47:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e4b:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e52:	76 af                	jbe    80108e03 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e54:	8b 45 08             	mov    0x8(%ebp),%eax
80108e57:	89 04 24             	mov    %eax,(%esp)
80108e5a:	e8 07 a3 ff ff       	call   80103166 <kfree>

}
80108e5f:	c9                   	leave  
80108e60:	c3                   	ret    

80108e61 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e61:	55                   	push   %ebp
80108e62:	89 e5                	mov    %esp,%ebp
80108e64:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e67:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e6e:	00 
80108e6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e72:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e76:	8b 45 08             	mov    0x8(%ebp),%eax
80108e79:	89 04 24             	mov    %eax,(%esp)
80108e7c:	e8 bc f5 ff ff       	call   8010843d <walkpgdir>
80108e81:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108e84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e88:	75 0c                	jne    80108e96 <clearpteu+0x35>
    panic("clearpteu");
80108e8a:	c7 04 24 e6 a3 10 80 	movl   $0x8010a3e6,(%esp)
80108e91:	e8 a4 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108e96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e99:	8b 00                	mov    (%eax),%eax
80108e9b:	83 e0 fb             	and    $0xfffffffb,%eax
80108e9e:	89 c2                	mov    %eax,%edx
80108ea0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ea3:	89 10                	mov    %edx,(%eax)
}
80108ea5:	c9                   	leave  
80108ea6:	c3                   	ret    

80108ea7 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108ea7:	55                   	push   %ebp
80108ea8:	89 e5                	mov    %esp,%ebp
80108eaa:	53                   	push   %ebx
80108eab:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108eae:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108eb5:	8b 45 10             	mov    0x10(%ebp),%eax
80108eb8:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108ebf:	00 00 00 
  np->swapedPagesCounter = 0;
80108ec2:	8b 45 10             	mov    0x10(%ebp),%eax
80108ec5:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108ecc:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108ecf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108ed5:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108edb:	8b 45 10             	mov    0x10(%ebp),%eax
80108ede:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108ee4:	e8 8e f6 ff ff       	call   80108577 <setupkvm>
80108ee9:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108eec:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ef0:	75 0a                	jne    80108efc <copyuvm+0x55>
    return 0;
80108ef2:	b8 00 00 00 00       	mov    $0x0,%eax
80108ef7:	e9 88 02 00 00       	jmp    80109184 <copyuvm+0x2dd>
  for(i = 0; i < sz; i += PGSIZE){
80108efc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f03:	e9 b2 01 00 00       	jmp    801090ba <copyuvm+0x213>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f0b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f12:	00 
80108f13:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f17:	8b 45 08             	mov    0x8(%ebp),%eax
80108f1a:	89 04 24             	mov    %eax,(%esp)
80108f1d:	e8 1b f5 ff ff       	call   8010843d <walkpgdir>
80108f22:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f25:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f29:	75 0c                	jne    80108f37 <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f2b:	c7 04 24 f0 a3 10 80 	movl   $0x8010a3f0,(%esp)
80108f32:	e8 03 76 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108f37:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f3a:	8b 00                	mov    (%eax),%eax
80108f3c:	83 e0 01             	and    $0x1,%eax
80108f3f:	85 c0                	test   %eax,%eax
80108f41:	75 0c                	jne    80108f4f <copyuvm+0xa8>
      panic("copyuvm: page not present");
80108f43:	c7 04 24 0a a4 10 80 	movl   $0x8010a40a,(%esp)
80108f4a:	e8 eb 75 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108f4f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f52:	8b 00                	mov    (%eax),%eax
80108f54:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    flags = PTE_FLAGS(*pte);
80108f5c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f5f:	8b 00                	mov    (%eax),%eax
80108f61:	25 ff 0f 00 00       	and    $0xfff,%eax
80108f66:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80108f69:	e8 ba a2 ff ff       	call   80103228 <kalloc>
80108f6e:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108f71:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108f75:	75 05                	jne    80108f7c <copyuvm+0xd5>
      goto bad;
80108f77:	e9 f0 01 00 00       	jmp    8010916c <copyuvm+0x2c5>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108f7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108f7f:	89 04 24             	mov    %eax,(%esp)
80108f82:	e8 33 f0 ff ff       	call   80107fba <p2v>
80108f87:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f8e:	00 
80108f8f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f93:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108f96:	89 04 24             	mov    %eax,(%esp)
80108f99:	e8 f3 ca ff ff       	call   80105a91 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108f9e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108fa1:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fa4:	89 04 24             	mov    %eax,(%esp)
80108fa7:	e8 01 f0 ff ff       	call   80107fad <v2p>
80108fac:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108faf:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108fb3:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108fb7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fbe:	00 
80108fbf:	89 54 24 04          	mov    %edx,0x4(%esp)
80108fc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108fc6:	89 04 24             	mov    %eax,(%esp)
80108fc9:	e8 11 f5 ff ff       	call   801084df <mappages>
80108fce:	85 c0                	test   %eax,%eax
80108fd0:	79 05                	jns    80108fd7 <copyuvm+0x130>
      goto bad;
80108fd2:	e9 95 01 00 00       	jmp    8010916c <copyuvm+0x2c5>
    // if(*pte & PTE_PG)
    //   *pte &= ~PTE_PG;
    np->pagesMetaData[j].va = (char *) i;
80108fd7:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108fda:	8b 5d 10             	mov    0x10(%ebp),%ebx
80108fdd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108fe0:	89 d0                	mov    %edx,%eax
80108fe2:	c1 e0 02             	shl    $0x2,%eax
80108fe5:	01 d0                	add    %edx,%eax
80108fe7:	c1 e0 02             	shl    $0x2,%eax
80108fea:	01 d8                	add    %ebx,%eax
80108fec:	05 90 00 00 00       	add    $0x90,%eax
80108ff1:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].isPhysical = 1;
80108ff3:	8b 4d 10             	mov    0x10(%ebp),%ecx
80108ff6:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ff9:	89 d0                	mov    %edx,%eax
80108ffb:	c1 e0 02             	shl    $0x2,%eax
80108ffe:	01 d0                	add    %edx,%eax
80109000:	c1 e0 02             	shl    $0x2,%eax
80109003:	01 c8                	add    %ecx,%eax
80109005:	05 94 00 00 00       	add    $0x94,%eax
8010900a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109010:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109013:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109016:	89 d0                	mov    %edx,%eax
80109018:	c1 e0 02             	shl    $0x2,%eax
8010901b:	01 d0                	add    %edx,%eax
8010901d:	c1 e0 02             	shl    $0x2,%eax
80109020:	01 c8                	add    %ecx,%eax
80109022:	05 98 00 00 00       	add    $0x98,%eax
80109027:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
8010902d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109034:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109037:	89 d0                	mov    %edx,%eax
80109039:	c1 e0 02             	shl    $0x2,%eax
8010903c:	01 d0                	add    %edx,%eax
8010903e:	c1 e0 02             	shl    $0x2,%eax
80109041:	01 c8                	add    %ecx,%eax
80109043:	05 9c 00 00 00       	add    $0x9c,%eax
80109048:	8b 08                	mov    (%eax),%ecx
8010904a:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010904d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109050:	89 d0                	mov    %edx,%eax
80109052:	c1 e0 02             	shl    $0x2,%eax
80109055:	01 d0                	add    %edx,%eax
80109057:	c1 e0 02             	shl    $0x2,%eax
8010905a:	01 d8                	add    %ebx,%eax
8010905c:	05 9c 00 00 00       	add    $0x9c,%eax
80109061:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
80109063:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010906a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010906d:	89 d0                	mov    %edx,%eax
8010906f:	c1 e0 02             	shl    $0x2,%eax
80109072:	01 d0                	add    %edx,%eax
80109074:	c1 e0 02             	shl    $0x2,%eax
80109077:	01 c8                	add    %ecx,%eax
80109079:	05 a0 00 00 00       	add    $0xa0,%eax
8010907e:	0f b6 08             	movzbl (%eax),%ecx
80109081:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109084:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109087:	89 d0                	mov    %edx,%eax
80109089:	c1 e0 02             	shl    $0x2,%eax
8010908c:	01 d0                	add    %edx,%eax
8010908e:	c1 e0 02             	shl    $0x2,%eax
80109091:	01 d8                	add    %ebx,%eax
80109093:	05 a0 00 00 00       	add    $0xa0,%eax
80109098:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
8010909a:	8b 45 10             	mov    0x10(%ebp),%eax
8010909d:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801090a3:	8d 50 01             	lea    0x1(%eax),%edx
801090a6:	8b 45 10             	mov    0x10(%ebp),%eax
801090a9:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
801090af:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801090b3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090bd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090c0:	0f 82 42 fe ff ff    	jb     80108f08 <copyuvm+0x61>
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
801090c6:	e9 92 00 00 00       	jmp    8010915d <copyuvm+0x2b6>
    np->pagesMetaData[j].va = (char *) -1;
801090cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090ce:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090d1:	89 d0                	mov    %edx,%eax
801090d3:	c1 e0 02             	shl    $0x2,%eax
801090d6:	01 d0                	add    %edx,%eax
801090d8:	c1 e0 02             	shl    $0x2,%eax
801090db:	01 c8                	add    %ecx,%eax
801090dd:	05 90 00 00 00       	add    $0x90,%eax
801090e2:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
801090e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090eb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090ee:	89 d0                	mov    %edx,%eax
801090f0:	c1 e0 02             	shl    $0x2,%eax
801090f3:	01 d0                	add    %edx,%eax
801090f5:	c1 e0 02             	shl    $0x2,%eax
801090f8:	01 c8                	add    %ecx,%eax
801090fa:	05 94 00 00 00       	add    $0x94,%eax
801090ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109105:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109108:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010910b:	89 d0                	mov    %edx,%eax
8010910d:	c1 e0 02             	shl    $0x2,%eax
80109110:	01 d0                	add    %edx,%eax
80109112:	c1 e0 02             	shl    $0x2,%eax
80109115:	01 c8                	add    %ecx,%eax
80109117:	05 98 00 00 00       	add    $0x98,%eax
8010911c:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109122:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109125:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109128:	89 d0                	mov    %edx,%eax
8010912a:	c1 e0 02             	shl    $0x2,%eax
8010912d:	01 d0                	add    %edx,%eax
8010912f:	c1 e0 02             	shl    $0x2,%eax
80109132:	01 c8                	add    %ecx,%eax
80109134:	05 9c 00 00 00       	add    $0x9c,%eax
80109139:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
8010913f:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109142:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109145:	89 d0                	mov    %edx,%eax
80109147:	c1 e0 02             	shl    $0x2,%eax
8010914a:	01 d0                	add    %edx,%eax
8010914c:	c1 e0 02             	shl    $0x2,%eax
8010914f:	01 c8                	add    %ecx,%eax
80109151:	05 a0 00 00 00       	add    $0xa0,%eax
80109156:	c6 00 80             	movb   $0x80,(%eax)
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
80109159:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010915d:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109161:	0f 86 64 ff ff ff    	jbe    801090cb <copyuvm+0x224>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
80109167:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010916a:	eb 18                	jmp    80109184 <copyuvm+0x2dd>

  bad:
  freevm(d,0);
8010916c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109173:	00 
80109174:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109177:	89 04 24             	mov    %eax,(%esp)
8010917a:	e8 3e fc ff ff       	call   80108dbd <freevm>
  return 0;
8010917f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109184:	83 c4 44             	add    $0x44,%esp
80109187:	5b                   	pop    %ebx
80109188:	5d                   	pop    %ebp
80109189:	c3                   	ret    

8010918a <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010918a:	55                   	push   %ebp
8010918b:	89 e5                	mov    %esp,%ebp
8010918d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109190:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109197:	00 
80109198:	8b 45 0c             	mov    0xc(%ebp),%eax
8010919b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010919f:	8b 45 08             	mov    0x8(%ebp),%eax
801091a2:	89 04 24             	mov    %eax,(%esp)
801091a5:	e8 93 f2 ff ff       	call   8010843d <walkpgdir>
801091aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801091ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091b0:	8b 00                	mov    (%eax),%eax
801091b2:	83 e0 01             	and    $0x1,%eax
801091b5:	85 c0                	test   %eax,%eax
801091b7:	75 07                	jne    801091c0 <uva2ka+0x36>
    return 0;
801091b9:	b8 00 00 00 00       	mov    $0x0,%eax
801091be:	eb 25                	jmp    801091e5 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801091c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091c3:	8b 00                	mov    (%eax),%eax
801091c5:	83 e0 04             	and    $0x4,%eax
801091c8:	85 c0                	test   %eax,%eax
801091ca:	75 07                	jne    801091d3 <uva2ka+0x49>
    return 0;
801091cc:	b8 00 00 00 00       	mov    $0x0,%eax
801091d1:	eb 12                	jmp    801091e5 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801091d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091d6:	8b 00                	mov    (%eax),%eax
801091d8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091dd:	89 04 24             	mov    %eax,(%esp)
801091e0:	e8 d5 ed ff ff       	call   80107fba <p2v>
}
801091e5:	c9                   	leave  
801091e6:	c3                   	ret    

801091e7 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801091e7:	55                   	push   %ebp
801091e8:	89 e5                	mov    %esp,%ebp
801091ea:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801091ed:	8b 45 10             	mov    0x10(%ebp),%eax
801091f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801091f3:	e9 87 00 00 00       	jmp    8010927f <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
801091f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801091fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109200:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109203:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109206:	89 44 24 04          	mov    %eax,0x4(%esp)
8010920a:	8b 45 08             	mov    0x8(%ebp),%eax
8010920d:	89 04 24             	mov    %eax,(%esp)
80109210:	e8 75 ff ff ff       	call   8010918a <uva2ka>
80109215:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109218:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010921c:	75 07                	jne    80109225 <copyout+0x3e>
      return -1;
8010921e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109223:	eb 69                	jmp    8010928e <copyout+0xa7>
    n = PGSIZE - (va - va0);
80109225:	8b 45 0c             	mov    0xc(%ebp),%eax
80109228:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010922b:	29 c2                	sub    %eax,%edx
8010922d:	89 d0                	mov    %edx,%eax
8010922f:	05 00 10 00 00       	add    $0x1000,%eax
80109234:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109237:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010923a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010923d:	76 06                	jbe    80109245 <copyout+0x5e>
      n = len;
8010923f:	8b 45 14             	mov    0x14(%ebp),%eax
80109242:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109245:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109248:	8b 55 0c             	mov    0xc(%ebp),%edx
8010924b:	29 c2                	sub    %eax,%edx
8010924d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109250:	01 c2                	add    %eax,%edx
80109252:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109255:	89 44 24 08          	mov    %eax,0x8(%esp)
80109259:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010925c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109260:	89 14 24             	mov    %edx,(%esp)
80109263:	e8 29 c8 ff ff       	call   80105a91 <memmove>
    len -= n;
80109268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010926b:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010926e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109271:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109274:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109277:	05 00 10 00 00       	add    $0x1000,%eax
8010927c:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010927f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109283:	0f 85 6f ff ff ff    	jne    801091f8 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109289:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010928e:	c9                   	leave  
8010928f:	c3                   	ret    

80109290 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
80109290:	55                   	push   %ebp
80109291:	89 e5                	mov    %esp,%ebp
80109293:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
80109296:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010929d:	eb 52                	jmp    801092f1 <findNextOpenPage+0x61>
    found = 1;
8010929f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092a6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801092ad:	eb 2d                	jmp    801092dc <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
801092af:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801092b6:	8b 55 f8             	mov    -0x8(%ebp),%edx
801092b9:	89 d0                	mov    %edx,%eax
801092bb:	c1 e0 02             	shl    $0x2,%eax
801092be:	01 d0                	add    %edx,%eax
801092c0:	c1 e0 02             	shl    $0x2,%eax
801092c3:	01 c8                	add    %ecx,%eax
801092c5:	05 98 00 00 00       	add    $0x98,%eax
801092ca:	8b 00                	mov    (%eax),%eax
801092cc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
801092cf:	75 07                	jne    801092d8 <findNextOpenPage+0x48>
        found = 0;
801092d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092d8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801092dc:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
801092e0:	7e cd                	jle    801092af <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
801092e2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801092e6:	74 02                	je     801092ea <findNextOpenPage+0x5a>
      break;
801092e8:	eb 10                	jmp    801092fa <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801092ea:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
801092f1:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
801092f8:	7e a5                	jle    8010929f <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
801092fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801092fd:	c9                   	leave  
801092fe:	c3                   	ret    

801092ff <existOnDisc>:

int
existOnDisc(uint faultingPage){
801092ff:	55                   	push   %ebp
80109300:	89 e5                	mov    %esp,%ebp
80109302:	83 ec 28             	sub    $0x28,%esp
  cprintf("faulting page: %x\n",faultingPage);
80109305:	8b 45 08             	mov    0x8(%ebp),%eax
80109308:	89 44 24 04          	mov    %eax,0x4(%esp)
8010930c:	c7 04 24 24 a4 10 80 	movl   $0x8010a424,(%esp)
80109313:	e8 88 70 ff ff       	call   801003a0 <cprintf>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
80109318:	8b 55 08             	mov    0x8(%ebp),%edx
8010931b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109321:	8b 40 04             	mov    0x4(%eax),%eax
80109324:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010932b:	00 
8010932c:	89 54 24 04          	mov    %edx,0x4(%esp)
80109330:	89 04 24             	mov    %eax,(%esp)
80109333:	e8 05 f1 ff ff       	call   8010843d <walkpgdir>
80109338:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
8010933b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  for(i = 0; i < 30; i++){
80109342:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80109349:	e9 8e 00 00 00       	jmp    801093dc <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
8010934e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109355:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109358:	89 d0                	mov    %edx,%eax
8010935a:	c1 e0 02             	shl    $0x2,%eax
8010935d:	01 d0                	add    %edx,%eax
8010935f:	c1 e0 02             	shl    $0x2,%eax
80109362:	01 c8                	add    %ecx,%eax
80109364:	05 90 00 00 00       	add    $0x90,%eax
80109369:	8b 00                	mov    (%eax),%eax
8010936b:	83 f8 ff             	cmp    $0xffffffff,%eax
8010936e:	74 68                	je     801093d8 <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
80109370:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109377:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010937a:	89 d0                	mov    %edx,%eax
8010937c:	c1 e0 02             	shl    $0x2,%eax
8010937f:	01 d0                	add    %edx,%eax
80109381:	c1 e0 02             	shl    $0x2,%eax
80109384:	01 c8                	add    %ecx,%eax
80109386:	05 90 00 00 00       	add    $0x90,%eax
8010938b:	8b 00                	mov    (%eax),%eax
8010938d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109392:	3b 45 08             	cmp    0x8(%ebp),%eax
80109395:	77 41                	ja     801093d8 <existOnDisc+0xd9>
80109397:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010939e:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093a1:	89 d0                	mov    %edx,%eax
801093a3:	c1 e0 02             	shl    $0x2,%eax
801093a6:	01 d0                	add    %edx,%eax
801093a8:	c1 e0 02             	shl    $0x2,%eax
801093ab:	01 c8                	add    %ecx,%eax
801093ad:	05 90 00 00 00       	add    $0x90,%eax
801093b2:	8b 00                	mov    (%eax),%eax
801093b4:	05 ff 0f 00 00       	add    $0xfff,%eax
801093b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093be:	3b 45 08             	cmp    0x8(%ebp),%eax
801093c1:	72 15                	jb     801093d8 <existOnDisc+0xd9>
801093c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093c6:	8b 00                	mov    (%eax),%eax
801093c8:	25 00 02 00 00       	and    $0x200,%eax
801093cd:	85 c0                	test   %eax,%eax
801093cf:	74 07                	je     801093d8 <existOnDisc+0xd9>
        found = 1;
801093d1:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  cprintf("faulting page: %x\n",faultingPage);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  for(i = 0; i < 30; i++){
801093d8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801093dc:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801093e0:	0f 8e 68 ff ff ff    	jle    8010934e <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
801093e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801093e9:	c9                   	leave  
801093ea:	c3                   	ret    

801093eb <fixPage>:

void
fixPage(uint faultingPage){
801093eb:	55                   	push   %ebp
801093ec:	89 e5                	mov    %esp,%ebp
801093ee:	81 ec 38 10 00 00    	sub    $0x1038,%esp
  int i;
  char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
801093f4:	e8 2f 9e ff ff       	call   80103228 <kalloc>
801093f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
801093fc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109400:	75 0c                	jne    8010940e <fixPage+0x23>
    panic("no room, go away");
80109402:	c7 04 24 37 a4 10 80 	movl   $0x8010a437,(%esp)
80109409:	e8 2c 71 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
8010940e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109415:	00 
80109416:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010941d:	00 
8010941e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109421:	89 04 24             	mov    %eax,(%esp)
80109424:	e8 99 c5 ff ff       	call   801059c2 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
80109429:	8b 55 08             	mov    0x8(%ebp),%edx
8010942c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109432:	8b 40 04             	mov    0x4(%eax),%eax
80109435:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010943c:	00 
8010943d:	89 54 24 04          	mov    %edx,0x4(%esp)
80109441:	89 04 24             	mov    %eax,(%esp)
80109444:	e8 f4 ef ff ff       	call   8010843d <walkpgdir>
80109449:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010944c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109453:	e9 90 01 00 00       	jmp    801095e8 <fixPage+0x1fd>
    if(proc->pagesMetaData[i].va != (char *) -1){
80109458:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010945f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109462:	89 d0                	mov    %edx,%eax
80109464:	c1 e0 02             	shl    $0x2,%eax
80109467:	01 d0                	add    %edx,%eax
80109469:	c1 e0 02             	shl    $0x2,%eax
8010946c:	01 c8                	add    %ecx,%eax
8010946e:	05 90 00 00 00       	add    $0x90,%eax
80109473:	8b 00                	mov    (%eax),%eax
80109475:	83 f8 ff             	cmp    $0xffffffff,%eax
80109478:	0f 84 66 01 00 00    	je     801095e4 <fixPage+0x1f9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
8010947e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109485:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109488:	89 d0                	mov    %edx,%eax
8010948a:	c1 e0 02             	shl    $0x2,%eax
8010948d:	01 d0                	add    %edx,%eax
8010948f:	c1 e0 02             	shl    $0x2,%eax
80109492:	01 c8                	add    %ecx,%eax
80109494:	05 90 00 00 00       	add    $0x90,%eax
80109499:	8b 00                	mov    (%eax),%eax
8010949b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094a0:	3b 45 08             	cmp    0x8(%ebp),%eax
801094a3:	0f 87 3b 01 00 00    	ja     801095e4 <fixPage+0x1f9>
801094a9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094b3:	89 d0                	mov    %edx,%eax
801094b5:	c1 e0 02             	shl    $0x2,%eax
801094b8:	01 d0                	add    %edx,%eax
801094ba:	c1 e0 02             	shl    $0x2,%eax
801094bd:	01 c8                	add    %ecx,%eax
801094bf:	05 90 00 00 00       	add    $0x90,%eax
801094c4:	8b 00                	mov    (%eax),%eax
801094c6:	05 ff 0f 00 00       	add    $0xfff,%eax
801094cb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094d0:	3b 45 08             	cmp    0x8(%ebp),%eax
801094d3:	0f 82 0b 01 00 00    	jb     801095e4 <fixPage+0x1f9>
801094d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094dc:	8b 00                	mov    (%eax),%eax
801094de:	25 00 02 00 00       	and    $0x200,%eax
801094e3:	85 c0                	test   %eax,%eax
801094e5:	0f 84 f9 00 00 00    	je     801095e4 <fixPage+0x1f9>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
801094eb:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094f5:	89 d0                	mov    %edx,%eax
801094f7:	c1 e0 02             	shl    $0x2,%eax
801094fa:	01 d0                	add    %edx,%eax
801094fc:	c1 e0 02             	shl    $0x2,%eax
801094ff:	01 c8                	add    %ecx,%eax
80109501:	05 98 00 00 00       	add    $0x98,%eax
80109506:	8b 00                	mov    (%eax),%eax
80109508:	89 44 24 04          	mov    %eax,0x4(%esp)
8010950c:	c7 04 24 48 a4 10 80 	movl   $0x8010a448,(%esp)
80109513:	e8 88 6e ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,buf,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
80109518:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010951f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109522:	89 d0                	mov    %edx,%eax
80109524:	c1 e0 02             	shl    $0x2,%eax
80109527:	01 d0                	add    %edx,%eax
80109529:	c1 e0 02             	shl    $0x2,%eax
8010952c:	01 c8                	add    %ecx,%eax
8010952e:	05 98 00 00 00       	add    $0x98,%eax
80109533:	8b 00                	mov    (%eax),%eax
80109535:	89 c2                	mov    %eax,%edx
80109537:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010953d:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109544:	00 
80109545:	89 54 24 08          	mov    %edx,0x8(%esp)
80109549:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
8010954f:	89 54 24 04          	mov    %edx,0x4(%esp)
80109553:	89 04 24             	mov    %eax,(%esp)
80109556:	e8 25 94 ff ff       	call   80102980 <readFromSwapFile>
8010955b:	83 f8 ff             	cmp    $0xffffffff,%eax
8010955e:	75 0c                	jne    8010956c <fixPage+0x181>
          panic("nothing read");
80109560:	c7 04 24 52 a4 10 80 	movl   $0x8010a452,(%esp)
80109567:	e8 ce 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1)  //need to swap out
8010956c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109572:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80109578:	83 f8 0e             	cmp    $0xe,%eax
8010957b:	76 05                	jbe    80109582 <fixPage+0x197>
          swapOut();
8010957d:	e8 f4 00 00 00       	call   80109676 <swapOut>
        proc->pagesMetaData[i].isPhysical = 1;
80109582:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109589:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010958c:	89 d0                	mov    %edx,%eax
8010958e:	c1 e0 02             	shl    $0x2,%eax
80109591:	01 d0                	add    %edx,%eax
80109593:	c1 e0 02             	shl    $0x2,%eax
80109596:	01 c8                	add    %ecx,%eax
80109598:	05 94 00 00 00       	add    $0x94,%eax
8010959d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  //TODO here?
801095a3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095ad:	89 d0                	mov    %edx,%eax
801095af:	c1 e0 02             	shl    $0x2,%eax
801095b2:	01 d0                	add    %edx,%eax
801095b4:	c1 e0 02             	shl    $0x2,%eax
801095b7:	01 c8                	add    %ecx,%eax
801095b9:	05 a0 00 00 00       	add    $0xa0,%eax
801095be:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
801095c1:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095cb:	89 d0                	mov    %edx,%eax
801095cd:	c1 e0 02             	shl    $0x2,%eax
801095d0:	01 d0                	add    %edx,%eax
801095d2:	c1 e0 02             	shl    $0x2,%eax
801095d5:	01 c8                	add    %ecx,%eax
801095d7:	05 98 00 00 00       	add    $0x98,%eax
801095dc:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
801095e2:	eb 0e                	jmp    801095f2 <fixPage+0x207>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
801095e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801095e8:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
801095ec:	0f 8e 66 fe ff ff    	jle    80109458 <fixPage+0x6d>
        proc->pagesMetaData[i].fileOffset = -1;
        break;
      }
    }
  }    
    memmove(mem,buf,PGSIZE);
801095f2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801095f9:	00 
801095fa:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
80109600:	89 44 24 04          	mov    %eax,0x4(%esp)
80109604:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109607:	89 04 24             	mov    %eax,(%esp)
8010960a:	e8 82 c4 ff ff       	call   80105a91 <memmove>
    *pte &= ~PTE_PG;  //turn off flag
8010960f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109612:	8b 00                	mov    (%eax),%eax
80109614:	80 e4 fd             	and    $0xfd,%ah
80109617:	89 c2                	mov    %eax,%edx
80109619:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010961c:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
8010961e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109621:	89 04 24             	mov    %eax,(%esp)
80109624:	e8 84 e9 ff ff       	call   80107fad <v2p>
80109629:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010962c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109633:	8b 52 04             	mov    0x4(%edx),%edx
80109636:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010963d:	00 
8010963e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109642:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109649:	00 
8010964a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010964e:	89 14 24             	mov    %edx,(%esp)
80109651:	e8 89 ee ff ff       	call   801084df <mappages>
    memmove(buf,0,PGSIZE);
80109656:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010965d:	00 
8010965e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109665:	00 
80109666:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
8010966c:	89 04 24             	mov    %eax,(%esp)
8010966f:	e8 1d c4 ff ff       	call   80105a91 <memmove>
  }
80109674:	c9                   	leave  
80109675:	c3                   	ret    

80109676 <swapOut>:

//swap out a page from proc.
  void swapOut(){
80109676:	55                   	push   %ebp
80109677:	89 e5                	mov    %esp,%ebp
80109679:	53                   	push   %ebx
8010967a:	81 ec 44 10 00 00    	sub    $0x1044,%esp
    int j;
    int offset;
    char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    int index = -1;
80109680:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
80109687:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010968d:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80109693:	83 c0 03             	add    $0x3,%eax
80109696:	89 45 ec             	mov    %eax,-0x14(%ebp)
    char minNFU = 0x80;
80109699:	c6 45 eb 80          	movb   $0x80,-0x15(%ebp)
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
8010969d:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801096a4:	e9 df 00 00 00       	jmp    80109788 <swapOut+0x112>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
801096a9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096b3:	89 d0                	mov    %edx,%eax
801096b5:	c1 e0 02             	shl    $0x2,%eax
801096b8:	01 d0                	add    %edx,%eax
801096ba:	c1 e0 02             	shl    $0x2,%eax
801096bd:	01 c8                	add    %ecx,%eax
801096bf:	05 94 00 00 00       	add    $0x94,%eax
801096c4:	8b 00                	mov    (%eax),%eax
801096c6:	85 c0                	test   %eax,%eax
801096c8:	0f 84 b6 00 00 00    	je     80109784 <swapOut+0x10e>
801096ce:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096d8:	89 d0                	mov    %edx,%eax
801096da:	c1 e0 02             	shl    $0x2,%eax
801096dd:	01 d0                	add    %edx,%eax
801096df:	c1 e0 02             	shl    $0x2,%eax
801096e2:	01 c8                	add    %ecx,%eax
801096e4:	05 9c 00 00 00       	add    $0x9c,%eax
801096e9:	8b 00                	mov    (%eax),%eax
801096eb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801096ee:	0f 8d 90 00 00 00    	jge    80109784 <swapOut+0x10e>
            min = proc->pagesMetaData[j].count;
801096f4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096fe:	89 d0                	mov    %edx,%eax
80109700:	c1 e0 02             	shl    $0x2,%eax
80109703:	01 d0                	add    %edx,%eax
80109705:	c1 e0 02             	shl    $0x2,%eax
80109708:	01 c8                	add    %ecx,%eax
8010970a:	05 9c 00 00 00       	add    $0x9c,%eax
8010970f:	8b 00                	mov    (%eax),%eax
80109711:	89 45 ec             	mov    %eax,-0x14(%ebp)
            index = j;
80109714:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109717:	89 45 f0             	mov    %eax,-0x10(%ebp)
            cprintf("currently i'm choosing %x has count %d\n",proc->pagesMetaData[index],proc->pagesMetaData[index].count);
8010971a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109721:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109724:	89 d0                	mov    %edx,%eax
80109726:	c1 e0 02             	shl    $0x2,%eax
80109729:	01 d0                	add    %edx,%eax
8010972b:	c1 e0 02             	shl    $0x2,%eax
8010972e:	01 c8                	add    %ecx,%eax
80109730:	05 9c 00 00 00       	add    $0x9c,%eax
80109735:	8b 00                	mov    (%eax),%eax
80109737:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010973e:	89 44 24 18          	mov    %eax,0x18(%esp)
80109742:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109745:	89 d0                	mov    %edx,%eax
80109747:	c1 e0 02             	shl    $0x2,%eax
8010974a:	01 d0                	add    %edx,%eax
8010974c:	c1 e0 02             	shl    $0x2,%eax
8010974f:	01 c8                	add    %ecx,%eax
80109751:	05 90 00 00 00       	add    $0x90,%eax
80109756:	8b 10                	mov    (%eax),%edx
80109758:	89 54 24 04          	mov    %edx,0x4(%esp)
8010975c:	8b 50 04             	mov    0x4(%eax),%edx
8010975f:	89 54 24 08          	mov    %edx,0x8(%esp)
80109763:	8b 50 08             	mov    0x8(%eax),%edx
80109766:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010976a:	8b 50 0c             	mov    0xc(%eax),%edx
8010976d:	89 54 24 10          	mov    %edx,0x10(%esp)
80109771:	8b 40 10             	mov    0x10(%eax),%eax
80109774:	89 44 24 14          	mov    %eax,0x14(%esp)
80109778:	c7 04 24 60 a4 10 80 	movl   $0x8010a460,(%esp)
8010977f:	e8 1c 6c ff ff       	call   801003a0 <cprintf>
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
80109784:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109788:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
8010978c:	0f 8e 17 ff ff ff    	jle    801096a9 <swapOut+0x33>
            min = proc->pagesMetaData[j].count;
            index = j;
            cprintf("currently i'm choosing %x has count %d\n",proc->pagesMetaData[index],proc->pagesMetaData[index].count);
          }
        }
        break;
80109792:	90                   	nop
        }
        break;
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
80109793:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010979a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010979d:	89 d0                	mov    %edx,%eax
8010979f:	c1 e0 02             	shl    $0x2,%eax
801097a2:	01 d0                	add    %edx,%eax
801097a4:	c1 e0 02             	shl    $0x2,%eax
801097a7:	01 c8                	add    %ecx,%eax
801097a9:	05 94 00 00 00       	add    $0x94,%eax
801097ae:	8b 00                	mov    (%eax),%eax
801097b0:	85 c0                	test   %eax,%eax
801097b2:	0f 84 bf 01 00 00    	je     80109977 <swapOut+0x301>
      //cprintf("choose to swap out %x\n",proc->pagesMetaData[index].va);
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
801097b8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097bf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097c2:	89 d0                	mov    %edx,%eax
801097c4:	c1 e0 02             	shl    $0x2,%eax
801097c7:	01 d0                	add    %edx,%eax
801097c9:	c1 e0 02             	shl    $0x2,%eax
801097cc:	01 c8                	add    %ecx,%eax
801097ce:	05 90 00 00 00       	add    $0x90,%eax
801097d3:	8b 00                	mov    (%eax),%eax
801097d5:	89 04 24             	mov    %eax,(%esp)
801097d8:	e8 b3 fa ff ff       	call   80109290 <findNextOpenPage>
801097dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      //cprintf("after offset\n");
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
801097e0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097e7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097ea:	89 d0                	mov    %edx,%eax
801097ec:	c1 e0 02             	shl    $0x2,%eax
801097ef:	01 d0                	add    %edx,%eax
801097f1:	c1 e0 02             	shl    $0x2,%eax
801097f4:	01 c8                	add    %ecx,%eax
801097f6:	05 90 00 00 00       	add    $0x90,%eax
801097fb:	8b 10                	mov    (%eax),%edx
801097fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109803:	8b 40 04             	mov    0x4(%eax),%eax
80109806:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010980d:	00 
8010980e:	89 54 24 04          	mov    %edx,0x4(%esp)
80109812:	89 04 24             	mov    %eax,(%esp)
80109815:	e8 23 ec ff ff       	call   8010843d <walkpgdir>
8010981a:	89 45 e0             	mov    %eax,-0x20(%ebp)
      //cprintf("after walkpgdir\n");
      if(!(*pte & PTE_PG)){
8010981d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109820:	8b 00                	mov    (%eax),%eax
80109822:	25 00 02 00 00       	and    $0x200,%eax
80109827:	85 c0                	test   %eax,%eax
80109829:	75 0f                	jne    8010983a <swapOut+0x1c4>
        *pte |= PTE_PG; //turn on    
8010982b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010982e:	8b 00                	mov    (%eax),%eax
80109830:	80 cc 02             	or     $0x2,%ah
80109833:	89 c2                	mov    %eax,%edx
80109835:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109838:	89 10                	mov    %edx,(%eax)
      }
      //cprintf("after setting PG\n");
      proc->pagesMetaData[index].fileOffset = offset;
8010983a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109841:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109844:	89 d0                	mov    %edx,%eax
80109846:	c1 e0 02             	shl    $0x2,%eax
80109849:	01 d0                	add    %edx,%eax
8010984b:	c1 e0 02             	shl    $0x2,%eax
8010984e:	01 c8                	add    %ecx,%eax
80109850:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
80109856:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109859:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
8010985b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109862:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109865:	89 d0                	mov    %edx,%eax
80109867:	c1 e0 02             	shl    $0x2,%eax
8010986a:	01 d0                	add    %edx,%eax
8010986c:	c1 e0 02             	shl    $0x2,%eax
8010986f:	01 c8                	add    %ecx,%eax
80109871:	05 94 00 00 00       	add    $0x94,%eax
80109876:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
8010987c:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109883:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109889:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
8010988f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109892:	89 d0                	mov    %edx,%eax
80109894:	c1 e0 02             	shl    $0x2,%eax
80109897:	01 d0                	add    %edx,%eax
80109899:	c1 e0 02             	shl    $0x2,%eax
8010989c:	01 d8                	add    %ebx,%eax
8010989e:	05 9c 00 00 00       	add    $0x9c,%eax
801098a3:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
801098a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098ab:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
801098b1:	83 c2 01             	add    $0x1,%edx
801098b4:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      memmove(buf,proc->pagesMetaData[index].va,PGSIZE);
801098ba:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801098c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098c4:	89 d0                	mov    %edx,%eax
801098c6:	c1 e0 02             	shl    $0x2,%eax
801098c9:	01 d0                	add    %edx,%eax
801098cb:	c1 e0 02             	shl    $0x2,%eax
801098ce:	01 c8                	add    %ecx,%eax
801098d0:	05 90 00 00 00       	add    $0x90,%eax
801098d5:	8b 00                	mov    (%eax),%eax
801098d7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801098de:	00 
801098df:	89 44 24 04          	mov    %eax,0x4(%esp)
801098e3:	8d 85 dc ef ff ff    	lea    -0x1024(%ebp),%eax
801098e9:	89 04 24             	mov    %eax,(%esp)
801098ec:	e8 a0 c1 ff ff       	call   80105a91 <memmove>
      //cprintf("after memmove\n");
      writeToSwapFile(proc,buf,offset,PGSIZE);
801098f1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801098f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098fa:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109901:	00 
80109902:	89 54 24 08          	mov    %edx,0x8(%esp)
80109906:	8d 95 dc ef ff ff    	lea    -0x1024(%ebp),%edx
8010990c:	89 54 24 04          	mov    %edx,0x4(%esp)
80109910:	89 04 24             	mov    %eax,(%esp)
80109913:	e8 38 90 ff ff       	call   80102950 <writeToSwapFile>
      //cprintf("after write\n");
      pa = PTE_ADDR(*pte);
80109918:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010991b:	8b 00                	mov    (%eax),%eax
8010991d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109922:	89 45 dc             	mov    %eax,-0x24(%ebp)
      cprintf("after pa\n");
80109925:	c7 04 24 88 a4 10 80 	movl   $0x8010a488,(%esp)
8010992c:	e8 6f 6a ff ff       	call   801003a0 <cprintf>
      if(pa == 0)
80109931:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80109935:	75 0c                	jne    80109943 <swapOut+0x2cd>
        panic("kfree swapOut");
80109937:	c7 04 24 92 a4 10 80 	movl   $0x8010a492,(%esp)
8010993e:	e8 f7 6b ff ff       	call   8010053a <panic>
      kfree(p2v(pa)); 
80109943:	8b 45 dc             	mov    -0x24(%ebp),%eax
80109946:	89 04 24             	mov    %eax,(%esp)
80109949:	e8 6c e6 ff ff       	call   80107fba <p2v>
8010994e:	89 04 24             	mov    %eax,(%esp)
80109951:	e8 10 98 ff ff       	call   80103166 <kfree>
      cprintf("after kfree\n");
80109956:	c7 04 24 a0 a4 10 80 	movl   $0x8010a4a0,(%esp)
8010995d:	e8 3e 6a ff ff       	call   801003a0 <cprintf>
      *pte = 0 | PTE_W | PTE_U | PTE_PG;
80109962:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109965:	c7 00 06 02 00 00    	movl   $0x206,(%eax)
      cprintf("after pte\n");
8010996b:	c7 04 24 ad a4 10 80 	movl   $0x8010a4ad,(%esp)
80109972:	e8 29 6a ff ff       	call   801003a0 <cprintf>
    }
  }
80109977:	81 c4 44 10 00 00    	add    $0x1044,%esp
8010997d:	5b                   	pop    %ebx
8010997e:	5d                   	pop    %ebp
8010997f:	c3                   	ret    

80109980 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109980:	55                   	push   %ebp
80109981:	89 e5                	mov    %esp,%ebp
80109983:	53                   	push   %ebx
80109984:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
80109987:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
8010998e:	e9 c8 00 00 00       	jmp    80109a5b <updateAge+0xdb>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=0){ //only if on RAM
80109993:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109996:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109999:	89 d0                	mov    %edx,%eax
8010999b:	c1 e0 02             	shl    $0x2,%eax
8010999e:	01 d0                	add    %edx,%eax
801099a0:	c1 e0 02             	shl    $0x2,%eax
801099a3:	01 c8                	add    %ecx,%eax
801099a5:	05 94 00 00 00       	add    $0x94,%eax
801099aa:	8b 00                	mov    (%eax),%eax
801099ac:	85 c0                	test   %eax,%eax
801099ae:	0f 84 a3 00 00 00    	je     80109a57 <updateAge+0xd7>
801099b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099ba:	89 d0                	mov    %edx,%eax
801099bc:	c1 e0 02             	shl    $0x2,%eax
801099bf:	01 d0                	add    %edx,%eax
801099c1:	c1 e0 02             	shl    $0x2,%eax
801099c4:	01 c8                	add    %ecx,%eax
801099c6:	05 90 00 00 00       	add    $0x90,%eax
801099cb:	8b 00                	mov    (%eax),%eax
801099cd:	85 c0                	test   %eax,%eax
801099cf:	0f 84 82 00 00 00    	je     80109a57 <updateAge+0xd7>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
801099d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099db:	89 d0                	mov    %edx,%eax
801099dd:	c1 e0 02             	shl    $0x2,%eax
801099e0:	01 d0                	add    %edx,%eax
801099e2:	c1 e0 02             	shl    $0x2,%eax
801099e5:	01 c8                	add    %ecx,%eax
801099e7:	05 a0 00 00 00       	add    $0xa0,%eax
801099ec:	0f b6 00             	movzbl (%eax),%eax
801099ef:	d0 f8                	sar    %al
801099f1:	89 c1                	mov    %eax,%ecx
801099f3:	8b 5d 08             	mov    0x8(%ebp),%ebx
801099f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099f9:	89 d0                	mov    %edx,%eax
801099fb:	c1 e0 02             	shl    $0x2,%eax
801099fe:	01 d0                	add    %edx,%eax
80109a00:	c1 e0 02             	shl    $0x2,%eax
80109a03:	01 d8                	add    %ebx,%eax
80109a05:	05 a0 00 00 00       	add    $0xa0,%eax
80109a0a:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
80109a0c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a0f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a12:	89 d0                	mov    %edx,%eax
80109a14:	c1 e0 02             	shl    $0x2,%eax
80109a17:	01 d0                	add    %edx,%eax
80109a19:	c1 e0 02             	shl    $0x2,%eax
80109a1c:	01 c8                	add    %ecx,%eax
80109a1e:	05 90 00 00 00       	add    $0x90,%eax
80109a23:	8b 10                	mov    (%eax),%edx
80109a25:	8b 45 08             	mov    0x8(%ebp),%eax
80109a28:	8b 40 04             	mov    0x4(%eax),%eax
80109a2b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109a32:	00 
80109a33:	89 54 24 04          	mov    %edx,0x4(%esp)
80109a37:	89 04 24             	mov    %eax,(%esp)
80109a3a:	e8 fe e9 ff ff       	call   8010843d <walkpgdir>
80109a3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if(!(*pte & PTE_A)){
80109a42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a45:	8b 00                	mov    (%eax),%eax
80109a47:	83 e0 20             	and    $0x20,%eax
80109a4a:	85 c0                	test   %eax,%eax
80109a4c:	75 09                	jne    80109a57 <updateAge+0xd7>
          *pte &= !PTE_A; //turn off bit 
80109a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a51:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
80109a57:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109a5b:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109a5f:	0f 8e 2e ff ff ff    	jle    80109993 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
        if(!(*pte & PTE_A)){
          *pte &= !PTE_A; //turn off bit 
      }
    }
  }
80109a65:	83 c4 24             	add    $0x24,%esp
80109a68:	5b                   	pop    %ebx
80109a69:	5d                   	pop    %ebp
80109a6a:	c3                   	ret    

80109a6b <clearAllPages>:

void
clearAllPages(struct proc *p){
80109a6b:	55                   	push   %ebp
80109a6c:	89 e5                	mov    %esp,%ebp
80109a6e:	83 ec 28             	sub    $0x28,%esp
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109a71:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109a78:	e9 cd 00 00 00       	jmp    80109b4a <clearAllPages+0xdf>
    if(p->pagesMetaData[i].va != (char *) -1){
80109a7d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a83:	89 d0                	mov    %edx,%eax
80109a85:	c1 e0 02             	shl    $0x2,%eax
80109a88:	01 d0                	add    %edx,%eax
80109a8a:	c1 e0 02             	shl    $0x2,%eax
80109a8d:	01 c8                	add    %ecx,%eax
80109a8f:	05 90 00 00 00       	add    $0x90,%eax
80109a94:	8b 00                	mov    (%eax),%eax
80109a96:	83 f8 ff             	cmp    $0xffffffff,%eax
80109a99:	0f 84 a7 00 00 00    	je     80109b46 <clearAllPages+0xdb>
      pte = walkpgdir(p->pgdir,proc->pagesMetaData[i].va,0);
80109a9f:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109aa6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109aa9:	89 d0                	mov    %edx,%eax
80109aab:	c1 e0 02             	shl    $0x2,%eax
80109aae:	01 d0                	add    %edx,%eax
80109ab0:	c1 e0 02             	shl    $0x2,%eax
80109ab3:	01 c8                	add    %ecx,%eax
80109ab5:	05 90 00 00 00       	add    $0x90,%eax
80109aba:	8b 10                	mov    (%eax),%edx
80109abc:	8b 45 08             	mov    0x8(%ebp),%eax
80109abf:	8b 40 04             	mov    0x4(%eax),%eax
80109ac2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109ac9:	00 
80109aca:	89 54 24 04          	mov    %edx,0x4(%esp)
80109ace:	89 04 24             	mov    %eax,(%esp)
80109ad1:	e8 67 e9 ff ff       	call   8010843d <walkpgdir>
80109ad6:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(!pte){
80109ad9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109add:	74 67                	je     80109b46 <clearAllPages+0xdb>

      }
      else if((*pte & PTE_P) != 0){
80109adf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109ae2:	8b 00                	mov    (%eax),%eax
80109ae4:	83 e0 01             	and    $0x1,%eax
80109ae7:	85 c0                	test   %eax,%eax
80109ae9:	74 5b                	je     80109b46 <clearAllPages+0xdb>
        pa = PTE_ADDR(*pte);
80109aeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109aee:	8b 00                	mov    (%eax),%eax
80109af0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109af5:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if(pa == 0){
80109af8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109afc:	75 0e                	jne    80109b0c <clearAllPages+0xa1>
          cprintf("already free\n");
80109afe:	c7 04 24 b8 a4 10 80 	movl   $0x8010a4b8,(%esp)
80109b05:	e8 96 68 ff ff       	call   801003a0 <cprintf>
80109b0a:	eb 3a                	jmp    80109b46 <clearAllPages+0xdb>
        }
        else{
          cprintf("clearing\n");
80109b0c:	c7 04 24 c6 a4 10 80 	movl   $0x8010a4c6,(%esp)
80109b13:	e8 88 68 ff ff       	call   801003a0 <cprintf>
          char *v = p2v(pa);
80109b18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109b1b:	89 04 24             	mov    %eax,(%esp)
80109b1e:	e8 97 e4 ff ff       	call   80107fba <p2v>
80109b23:	89 45 e8             	mov    %eax,-0x18(%ebp)
          kfree(v);
80109b26:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109b29:	89 04 24             	mov    %eax,(%esp)
80109b2c:	e8 35 96 ff ff       	call   80103166 <kfree>
          *pte = 0;
80109b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b34:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
          cprintf("finished\n");
80109b3a:	c7 04 24 d0 a4 10 80 	movl   $0x8010a4d0,(%esp)
80109b41:	e8 5a 68 ff ff       	call   801003a0 <cprintf>
void
clearAllPages(struct proc *p){
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109b46:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109b4a:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109b4e:	0f 8e 29 ff ff ff    	jle    80109a7d <clearAllPages+0x12>
          cprintf("finished\n");
        }
      }
    }
  }
}
80109b54:	c9                   	leave  
80109b55:	c3                   	ret    
