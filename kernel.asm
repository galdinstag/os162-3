
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
80100028:	bc 50 e6 10 80       	mov    $0x8010e650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 b4 3e 10 80       	mov    $0x80103eb4,%eax
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
8010003a:	c7 44 24 04 14 9c 10 	movl   $0x80109c14,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 25 57 00 00       	call   80105773 <initlock>

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
801000bd:	e8 d2 56 00 00       	call   80105794 <acquire>

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
80100104:	e8 ed 56 00 00       	call   801057f6 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 2c 53 00 00       	call   80105450 <sleep>
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
8010017c:	e8 75 56 00 00       	call   801057f6 <release>
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
80100198:	c7 04 24 1b 9c 10 80 	movl   $0x80109c1b,(%esp)
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
801001ef:	c7 04 24 2c 9c 10 80 	movl   $0x80109c2c,(%esp)
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
80100229:	c7 04 24 33 9c 10 80 	movl   $0x80109c33,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 53 55 00 00       	call   80105794 <acquire>

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
8010029d:	e8 8a 52 00 00       	call   8010552c <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 48 55 00 00       	call   801057f6 <release>
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
801003bb:	e8 d4 53 00 00       	call   80105794 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 3a 9c 10 80 	movl   $0x80109c3a,(%esp)
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
801004b0:	c7 45 ec 43 9c 10 80 	movl   $0x80109c43,-0x14(%ebp)
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
80100533:	e8 be 52 00 00       	call   801057f6 <release>
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
8010055f:	c7 04 24 4a 9c 10 80 	movl   $0x80109c4a,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 59 9c 10 80 	movl   $0x80109c59,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 b1 52 00 00       	call   80105845 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 5b 9c 10 80 	movl   $0x80109c5b,(%esp)
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
80100699:	c7 04 24 5f 9c 10 80 	movl   $0x80109c5f,(%esp)
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
801006cd:	e8 e5 53 00 00       	call   80105ab7 <memmove>
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
801006fc:	e8 e7 52 00 00       	call   801059e8 <memset>
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
80100791:	e8 b6 6c 00 00       	call   8010744c <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 aa 6c 00 00       	call   8010744c <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 9e 6c 00 00       	call   8010744c <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 91 6c 00 00       	call   8010744c <uartputc>
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
801007dc:	e8 b3 4f 00 00       	call   80105794 <acquire>
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
80100917:	e8 10 4c 00 00       	call   8010552c <wakeup>
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
80100938:	e8 b9 4e 00 00       	call   801057f6 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 8a 4c 00 00       	call   801055d2 <procdump>
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
80100968:	e8 27 4e 00 00       	call   80105794 <acquire>
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
80100988:	e8 69 4e 00 00       	call   801057f6 <release>
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
801009b1:	e8 9a 4a 00 00       	call   80105450 <sleep>

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
80100a2d:	e8 c4 4d 00 00       	call   801057f6 <release>
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
80100a61:	e8 2e 4d 00 00       	call   80105794 <acquire>
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
80100a9b:	e8 56 4d 00 00       	call   801057f6 <release>
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
80100ab6:	c7 44 24 04 72 9c 10 	movl   $0x80109c72,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 a9 4c 00 00       	call   80105773 <initlock>

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
80100aef:	e8 58 3a 00 00       	call   8010454c <picenable>
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
80100b13:	e8 95 30 00 00       	call   80103bad <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 47 1a 00 00       	call   8010256a <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 00 31 00 00       	call   80103c31 <end_op>
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
80100b8e:	e8 0a 7a 00 00       	call   8010859d <setupkvm>
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
80100ccf:	e8 97 7c 00 00       	call   8010896b <allocuvm>
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
80100d0d:	e8 6e 7b 00 00       	call   80108880 <loaduvm>
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
80100d46:	e8 e6 2e 00 00       	call   80103c31 <end_op>
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
80100d86:	e8 e0 7b 00 00       	call   8010896b <allocuvm>
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
80100dab:	e8 d7 80 00 00       	call   80108e87 <clearpteu>
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
80100de1:	e8 6c 4e 00 00       	call   80105c52 <strlen>
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
80100e0a:	e8 43 4e 00 00       	call   80105c52 <strlen>
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
80100e3a:	e8 ce 83 00 00       	call   8010920d <copyout>
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
80100ee1:	e8 27 83 00 00       	call   8010920d <copyout>
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
80100f39:	e8 ca 4c 00 00       	call   80105c08 <safestrcpy>

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
80100fb5:	e8 d4 76 00 00       	call   8010868e <switchuvm>
  freevm(oldpgdir,0);
80100fba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100fc1:	00 
80100fc2:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100fc5:	89 04 24             	mov    %eax,(%esp)
80100fc8:	e8 16 7e 00 00       	call   80108de3 <freevm>
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
80100fe8:	e8 f6 7d 00 00       	call   80108de3 <freevm>
  if(ip){
80100fed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ff1:	74 10                	je     80101003 <exec+0x4f9>
    iunlockput(ip);
80100ff3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ff6:	89 04 24             	mov    %eax,(%esp)
80100ff9:	e8 45 0c 00 00       	call   80101c43 <iunlockput>
    end_op();
80100ffe:	e8 2e 2c 00 00       	call   80103c31 <end_op>
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
80101010:	c7 44 24 04 7a 9c 10 	movl   $0x80109c7a,0x4(%esp)
80101017:	80 
80101018:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010101f:	e8 4f 47 00 00       	call   80105773 <initlock>
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
80101033:	e8 5c 47 00 00       	call   80105794 <acquire>
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
8010105c:	e8 95 47 00 00       	call   801057f6 <release>
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
8010107a:	e8 77 47 00 00       	call   801057f6 <release>
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
80101093:	e8 fc 46 00 00       	call   80105794 <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <filedup+0x28>
    panic("filedup");
801010a2:	c7 04 24 81 9c 10 80 	movl   $0x80109c81,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 01             	lea    0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bd:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010c4:	e8 2d 47 00 00       	call   801057f6 <release>
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
801010db:	e8 b4 46 00 00       	call   80105794 <acquire>
  if(f->ref < 1)
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 04             	mov    0x4(%eax),%eax
801010e6:	85 c0                	test   %eax,%eax
801010e8:	7f 0c                	jg     801010f6 <fileclose+0x28>
    panic("fileclose");
801010ea:	c7 04 24 89 9c 10 80 	movl   $0x80109c89,(%esp)
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
80101116:	e8 db 46 00 00       	call   801057f6 <release>
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
80101160:	e8 91 46 00 00       	call   801057f6 <release>
  
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
8010117e:	e8 79 36 00 00       	call   801047fc <pipeclose>
80101183:	eb 1d                	jmp    801011a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101185:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101188:	83 f8 02             	cmp    $0x2,%eax
8010118b:	75 15                	jne    801011a2 <fileclose+0xd4>
    begin_op();
8010118d:	e8 1b 2a 00 00       	call   80103bad <begin_op>
    iput(ff.ip);
80101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 d5 09 00 00       	call   80101b72 <iput>
    end_op();
8010119d:	e8 8f 2a 00 00       	call   80103c31 <end_op>
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
8010122f:	e8 49 37 00 00       	call   8010497d <piperead>
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
801012a1:	c7 04 24 93 9c 10 80 	movl   $0x80109c93,(%esp)
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
801012ec:	e8 9d 35 00 00       	call   8010488e <pipewrite>
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
80101332:	e8 76 28 00 00       	call   80103bad <begin_op>
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
80101398:	e8 94 28 00 00       	call   80103c31 <end_op>

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
801013ad:	c7 04 24 9c 9c 10 80 	movl   $0x80109c9c,(%esp)
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
801013df:	c7 04 24 ac 9c 10 80 	movl   $0x80109cac,(%esp)
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
80101425:	e8 8d 46 00 00       	call   80105ab7 <memmove>
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
8010146b:	e8 78 45 00 00       	call   801059e8 <memset>
  log_write(bp);
80101470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 3d 29 00 00       	call   80103db8 <log_write>
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
80101541:	e8 72 28 00 00       	call   80103db8 <log_write>
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
801015b8:	c7 04 24 b8 9c 10 80 	movl   $0x80109cb8,(%esp)
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
80101647:	c7 04 24 ce 9c 10 80 	movl   $0x80109cce,(%esp)
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
8010167f:	e8 34 27 00 00       	call   80103db8 <log_write>
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
8010169a:	c7 44 24 04 e1 9c 10 	movl   $0x80109ce1,0x4(%esp)
801016a1:	80 
801016a2:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801016a9:	e8 c5 40 00 00       	call   80105773 <initlock>
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
8010170e:	c7 04 24 e8 9c 10 80 	movl   $0x80109ce8,(%esp)
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
80101791:	e8 52 42 00 00       	call   801059e8 <memset>
      dip->type = type;
80101796:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101799:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
8010179d:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 0d 26 00 00       	call   80103db8 <log_write>
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
801017e9:	c7 04 24 3b 9d 10 80 	movl   $0x80109d3b,(%esp)
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
80101898:	e8 1a 42 00 00       	call   80105ab7 <memmove>
  log_write(bp);
8010189d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a0:	89 04 24             	mov    %eax,(%esp)
801018a3:	e8 10 25 00 00       	call   80103db8 <log_write>
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
801018c2:	e8 cd 3e 00 00       	call   80105794 <acquire>

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
8010190c:	e8 e5 3e 00 00       	call   801057f6 <release>
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
8010193f:	c7 04 24 4d 9d 10 80 	movl   $0x80109d4d,(%esp)
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
8010197d:	e8 74 3e 00 00       	call   801057f6 <release>

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
80101994:	e8 fb 3d 00 00       	call   80105794 <acquire>
  ip->ref++;
80101999:	8b 45 08             	mov    0x8(%ebp),%eax
8010199c:	8b 40 08             	mov    0x8(%eax),%eax
8010199f:	8d 50 01             	lea    0x1(%eax),%edx
801019a2:	8b 45 08             	mov    0x8(%ebp),%eax
801019a5:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019a8:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019af:	e8 42 3e 00 00       	call   801057f6 <release>
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
801019cf:	c7 04 24 5d 9d 10 80 	movl   $0x80109d5d,(%esp)
801019d6:	e8 5f eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019db:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019e2:	e8 ad 3d 00 00       	call   80105794 <acquire>
  while(ip->flags & I_BUSY)
801019e7:	eb 13                	jmp    801019fc <ilock+0x43>
    sleep(ip, &icache.lock);
801019e9:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
801019f0:	80 
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	89 04 24             	mov    %eax,(%esp)
801019f7:	e8 54 3a 00 00       	call   80105450 <sleep>

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
80101a21:	e8 d0 3d 00 00       	call   801057f6 <release>

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
80101ad2:	e8 e0 3f 00 00       	call   80105ab7 <memmove>
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
80101aff:	c7 04 24 63 9d 10 80 	movl   $0x80109d63,(%esp)
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
80101b30:	c7 04 24 72 9d 10 80 	movl   $0x80109d72,(%esp)
80101b37:	e8 fe e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b43:	e8 4c 3c 00 00       	call   80105794 <acquire>
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
80101b5f:	e8 c8 39 00 00       	call   8010552c <wakeup>
  release(&icache.lock);
80101b64:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b6b:	e8 86 3c 00 00       	call   801057f6 <release>
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
80101b7f:	e8 10 3c 00 00       	call   80105794 <acquire>
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
80101bbd:	c7 04 24 7a 9d 10 80 	movl   $0x80109d7a,(%esp)
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
80101be1:	e8 10 3c 00 00       	call   801057f6 <release>
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
80101c0c:	e8 83 3b 00 00       	call   80105794 <acquire>
    ip->flags = 0;
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	89 04 24             	mov    %eax,(%esp)
80101c21:	e8 06 39 00 00       	call   8010552c <wakeup>
  }
  ip->ref--;
80101c26:	8b 45 08             	mov    0x8(%ebp),%eax
80101c29:	8b 40 08             	mov    0x8(%eax),%eax
80101c2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c32:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c35:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c3c:	e8 b5 3b 00 00       	call   801057f6 <release>
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
80101d47:	e8 6c 20 00 00       	call   80103db8 <log_write>
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
80101d5c:	c7 04 24 84 9d 10 80 	movl   $0x80109d84,(%esp)
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
80101ffd:	e8 b5 3a 00 00       	call   80105ab7 <memmove>
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
8010215c:	e8 56 39 00 00       	call   80105ab7 <memmove>
    log_write(bp);
80102161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102164:	89 04 24             	mov    %eax,(%esp)
80102167:	e8 4c 1c 00 00       	call   80103db8 <log_write>
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
801021da:	e8 7b 39 00 00       	call   80105b5a <strncmp>
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
801021f4:	c7 04 24 97 9d 10 80 	movl   $0x80109d97,(%esp)
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
80102232:	c7 04 24 a9 9d 10 80 	movl   $0x80109da9,(%esp)
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
80102317:	c7 04 24 a9 9d 10 80 	movl   $0x80109da9,(%esp)
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
8010235c:	e8 4f 38 00 00       	call   80105bb0 <strncpy>
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
8010238e:	c7 04 24 b6 9d 10 80 	movl   $0x80109db6,(%esp)
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
80102413:	e8 9f 36 00 00       	call   80105ab7 <memmove>
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
8010242e:	e8 84 36 00 00       	call   80105ab7 <memmove>
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
8010267d:	c7 44 24 04 be 9d 10 	movl   $0x80109dbe,0x4(%esp)
80102684:	80 
80102685:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80102688:	89 04 24             	mov    %eax,(%esp)
8010268b:	e8 27 34 00 00       	call   80105ab7 <memmove>
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
801026ca:	e8 de 14 00 00       	call   80103bad <begin_op>
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
801026ea:	e8 42 15 00 00       	call   80103c31 <end_op>
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
80102704:	c7 44 24 04 c5 9d 10 	movl   $0x80109dc5,0x4(%esp)
8010270b:	80 
8010270c:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010270f:	89 04 24             	mov    %eax,(%esp)
80102712:	e8 a8 fa ff ff       	call   801021bf <namecmp>
80102717:	85 c0                	test   %eax,%eax
80102719:	0f 84 45 01 00 00    	je     80102864 <removeSwapFile+0x1f5>
8010271f:	c7 44 24 04 c7 9d 10 	movl   $0x80109dc7,0x4(%esp)
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
80102778:	c7 04 24 ca 9d 10 80 	movl   $0x80109dca,(%esp)
8010277f:	e8 b6 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
80102784:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102787:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010278b:	66 83 f8 01          	cmp    $0x1,%ax
8010278f:	75 1f                	jne    801027b0 <removeSwapFile+0x141>
80102791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102794:	89 04 24             	mov    %eax,(%esp)
80102797:	e8 26 3b 00 00       	call   801062c2 <isdirempty>
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
801027c6:	e8 1d 32 00 00       	call   801059e8 <memset>
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
801027f1:	c7 04 24 dc 9d 10 80 	movl   $0x80109ddc,(%esp)
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
80102858:	e8 d4 13 00 00       	call   80103c31 <end_op>

	return 0;
8010285d:	b8 00 00 00 00       	mov    $0x0,%eax
80102862:	eb 15                	jmp    80102879 <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
80102864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102867:	89 04 24             	mov    %eax,(%esp)
8010286a:	e8 d4 f3 ff ff       	call   80101c43 <iunlockput>
		end_op();
8010286f:	e8 bd 13 00 00       	call   80103c31 <end_op>
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
80102889:	c7 44 24 04 be 9d 10 	movl   $0x80109dbe,0x4(%esp)
80102890:	80 
80102891:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102894:	89 04 24             	mov    %eax,(%esp)
80102897:	e8 1b 32 00 00       	call   80105ab7 <memmove>
	itoa(p->pid, path+ 6);
8010289c:	8b 45 08             	mov    0x8(%ebp),%eax
8010289f:	8b 40 10             	mov    0x10(%eax),%eax
801028a2:	8d 55 e6             	lea    -0x1a(%ebp),%edx
801028a5:	83 c2 06             	add    $0x6,%edx
801028a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801028ac:	89 04 24             	mov    %eax,(%esp)
801028af:	e8 fa fc ff ff       	call   801025ae <itoa>

    begin_op();
801028b4:	e8 f4 12 00 00       	call   80103bad <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
801028b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801028c0:	00 
801028c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801028c8:	00 
801028c9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801028d0:	00 
801028d1:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028d4:	89 04 24             	mov    %eax,(%esp)
801028d7:	e8 2c 3c 00 00       	call   80106508 <create>
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
801028ff:	c7 04 24 eb 9d 10 80 	movl   $0x80109deb,(%esp)
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
80102944:	e8 e8 12 00 00       	call   80103c31 <end_op>

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
80102a21:	c7 04 24 07 9e 10 80 	movl   $0x80109e07,(%esp)
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
80102a9e:	c7 04 24 1d 9e 10 80 	movl   $0x80109e1d,(%esp)
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
80102ae9:	c7 04 24 32 9e 10 80 	movl   $0x80109e32,(%esp)
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
80102bff:	c7 44 24 04 48 9e 10 	movl   $0x80109e48,0x4(%esp)
80102c06:	80 
80102c07:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c0e:	e8 60 2b 00 00       	call   80105773 <initlock>
  picenable(IRQ_IDE);
80102c13:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c1a:	e8 2d 19 00 00       	call   8010454c <picenable>
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
80102cab:	c7 04 24 4c 9e 10 80 	movl   $0x80109e4c,(%esp)
80102cb2:	e8 83 d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cba:	8b 40 08             	mov    0x8(%eax),%eax
80102cbd:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102cc2:	76 0c                	jbe    80102cd0 <idestart+0x31>
    panic("incorrect blockno");
80102cc4:	c7 04 24 55 9e 10 80 	movl   $0x80109e55,(%esp)
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
80102cec:	c7 04 24 4c 9e 10 80 	movl   $0x80109e4c,(%esp)
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
80102e08:	e8 87 29 00 00       	call   80105794 <acquire>
  if((b = idequeue) == 0){
80102e0d:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e12:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e19:	75 11                	jne    80102e2c <ideintr+0x31>
    release(&idelock);
80102e1b:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e22:	e8 cf 29 00 00       	call   801057f6 <release>
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
80102e95:	e8 92 26 00 00       	call   8010552c <wakeup>
  
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
80102eb7:	e8 3a 29 00 00       	call   801057f6 <release>
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
80102ed0:	c7 04 24 67 9e 10 80 	movl   $0x80109e67,(%esp)
80102ed7:	e8 5e d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102edc:	8b 45 08             	mov    0x8(%ebp),%eax
80102edf:	8b 00                	mov    (%eax),%eax
80102ee1:	83 e0 06             	and    $0x6,%eax
80102ee4:	83 f8 02             	cmp    $0x2,%eax
80102ee7:	75 0c                	jne    80102ef5 <iderw+0x37>
    panic("iderw: nothing to do");
80102ee9:	c7 04 24 7b 9e 10 80 	movl   $0x80109e7b,(%esp)
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
80102f08:	c7 04 24 90 9e 10 80 	movl   $0x80109e90,(%esp)
80102f0f:	e8 26 d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f14:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f1b:	e8 74 28 00 00       	call   80105794 <acquire>

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
80102f76:	e8 d5 24 00 00       	call   80105450 <sleep>
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
80102f8f:	e8 62 28 00 00       	call   801057f6 <release>
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
8010301d:	c7 04 24 b0 9e 10 80 	movl   $0x80109eb0,(%esp)
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
801030d7:	c7 44 24 04 e2 9e 10 	movl   $0x80109ee2,0x4(%esp)
801030de:	80 
801030df:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801030e6:	e8 88 26 00 00       	call   80105773 <initlock>
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
801031cb:	c7 04 24 e7 9e 10 80 	movl   $0x80109ee7,(%esp)
801031d2:	e8 c9 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031d7:	c7 04 24 fe 9e 10 80 	movl   $0x80109efe,(%esp)
801031de:	e8 57 d3 ff ff       	call   8010053a <panic>
  }

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801031e3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801031ea:	00 
801031eb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801031f2:	00 
801031f3:	8b 45 08             	mov    0x8(%ebp),%eax
801031f6:	89 04 24             	mov    %eax,(%esp)
801031f9:	e8 ea 27 00 00       	call   801059e8 <memset>

  if(kmem.use_lock)
801031fe:	a1 54 42 11 80       	mov    0x80114254,%eax
80103203:	85 c0                	test   %eax,%eax
80103205:	74 0c                	je     80103213 <kfree+0xad>
    acquire(&kmem.lock);
80103207:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010320e:	e8 81 25 00 00       	call   80105794 <acquire>
  r = (struct run*)v;
80103213:	8b 45 08             	mov    0x8(%ebp),%eax
80103216:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103219:	8b 15 58 42 11 80    	mov    0x80114258,%edx
8010321f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103222:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103227:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
8010322c:	a1 54 42 11 80       	mov    0x80114254,%eax
80103231:	85 c0                	test   %eax,%eax
80103233:	74 0c                	je     80103241 <kfree+0xdb>
    release(&kmem.lock);
80103235:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010323c:	e8 b5 25 00 00       	call   801057f6 <release>
}
80103241:	c9                   	leave  
80103242:	c3                   	ret    

80103243 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103243:	55                   	push   %ebp
80103244:	89 e5                	mov    %esp,%ebp
80103246:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103249:	a1 54 42 11 80       	mov    0x80114254,%eax
8010324e:	85 c0                	test   %eax,%eax
80103250:	74 0c                	je     8010325e <kalloc+0x1b>
    acquire(&kmem.lock);
80103252:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103259:	e8 36 25 00 00       	call   80105794 <acquire>
  r = kmem.freelist;
8010325e:	a1 58 42 11 80       	mov    0x80114258,%eax
80103263:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103266:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010326a:	74 0a                	je     80103276 <kalloc+0x33>
    kmem.freelist = r->next;
8010326c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010326f:	8b 00                	mov    (%eax),%eax
80103271:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103276:	a1 54 42 11 80       	mov    0x80114254,%eax
8010327b:	85 c0                	test   %eax,%eax
8010327d:	74 0c                	je     8010328b <kalloc+0x48>
    release(&kmem.lock);
8010327f:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103286:	e8 6b 25 00 00       	call   801057f6 <release>
  return (char*)r;
8010328b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010328e:	c9                   	leave  
8010328f:	c3                   	ret    

80103290 <countPages>:

int
countPages(){
80103290:	55                   	push   %ebp
80103291:	89 e5                	mov    %esp,%ebp
80103293:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
80103296:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
8010329d:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032a4:	e8 eb 24 00 00       	call   80105794 <acquire>
  r = kmem.freelist;
801032a9:	a1 58 42 11 80       	mov    0x80114258,%eax
801032ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
801032b1:	eb 0c                	jmp    801032bf <countPages+0x2f>
    result++;
801032b3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
801032b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032ba:	8b 00                	mov    (%eax),%eax
801032bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
801032bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032c3:	75 ee                	jne    801032b3 <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032c5:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032cc:	e8 25 25 00 00       	call   801057f6 <release>
  return result;
801032d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032d4:	c9                   	leave  
801032d5:	c3                   	ret    

801032d6 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032d6:	55                   	push   %ebp
801032d7:	89 e5                	mov    %esp,%ebp
801032d9:	83 ec 14             	sub    $0x14,%esp
801032dc:	8b 45 08             	mov    0x8(%ebp),%eax
801032df:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032e3:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032e7:	89 c2                	mov    %eax,%edx
801032e9:	ec                   	in     (%dx),%al
801032ea:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801032ed:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801032f1:	c9                   	leave  
801032f2:	c3                   	ret    

801032f3 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801032f3:	55                   	push   %ebp
801032f4:	89 e5                	mov    %esp,%ebp
801032f6:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801032f9:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103300:	e8 d1 ff ff ff       	call   801032d6 <inb>
80103305:	0f b6 c0             	movzbl %al,%eax
80103308:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
8010330b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010330e:	83 e0 01             	and    $0x1,%eax
80103311:	85 c0                	test   %eax,%eax
80103313:	75 0a                	jne    8010331f <kbdgetc+0x2c>
    return -1;
80103315:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010331a:	e9 25 01 00 00       	jmp    80103444 <kbdgetc+0x151>
  data = inb(KBDATAP);
8010331f:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103326:	e8 ab ff ff ff       	call   801032d6 <inb>
8010332b:	0f b6 c0             	movzbl %al,%eax
8010332e:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103331:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103338:	75 17                	jne    80103351 <kbdgetc+0x5e>
    shift |= E0ESC;
8010333a:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010333f:	83 c8 40             	or     $0x40,%eax
80103342:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103347:	b8 00 00 00 00       	mov    $0x0,%eax
8010334c:	e9 f3 00 00 00       	jmp    80103444 <kbdgetc+0x151>
  } else if(data & 0x80){
80103351:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103354:	25 80 00 00 00       	and    $0x80,%eax
80103359:	85 c0                	test   %eax,%eax
8010335b:	74 45                	je     801033a2 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010335d:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103362:	83 e0 40             	and    $0x40,%eax
80103365:	85 c0                	test   %eax,%eax
80103367:	75 08                	jne    80103371 <kbdgetc+0x7e>
80103369:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010336c:	83 e0 7f             	and    $0x7f,%eax
8010336f:	eb 03                	jmp    80103374 <kbdgetc+0x81>
80103371:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103374:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103377:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010337a:	05 20 b0 10 80       	add    $0x8010b020,%eax
8010337f:	0f b6 00             	movzbl (%eax),%eax
80103382:	83 c8 40             	or     $0x40,%eax
80103385:	0f b6 c0             	movzbl %al,%eax
80103388:	f7 d0                	not    %eax
8010338a:	89 c2                	mov    %eax,%edx
8010338c:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103391:	21 d0                	and    %edx,%eax
80103393:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103398:	b8 00 00 00 00       	mov    $0x0,%eax
8010339d:	e9 a2 00 00 00       	jmp    80103444 <kbdgetc+0x151>
  } else if(shift & E0ESC){
801033a2:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033a7:	83 e0 40             	and    $0x40,%eax
801033aa:	85 c0                	test   %eax,%eax
801033ac:	74 14                	je     801033c2 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801033ae:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801033b5:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033ba:	83 e0 bf             	and    $0xffffffbf,%eax
801033bd:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
801033c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033c5:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033ca:	0f b6 00             	movzbl (%eax),%eax
801033cd:	0f b6 d0             	movzbl %al,%edx
801033d0:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033d5:	09 d0                	or     %edx,%eax
801033d7:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033df:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033e4:	0f b6 00             	movzbl (%eax),%eax
801033e7:	0f b6 d0             	movzbl %al,%edx
801033ea:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033ef:	31 d0                	xor    %edx,%eax
801033f1:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
801033f6:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033fb:	83 e0 03             	and    $0x3,%eax
801033fe:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
80103405:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103408:	01 d0                	add    %edx,%eax
8010340a:	0f b6 00             	movzbl (%eax),%eax
8010340d:	0f b6 c0             	movzbl %al,%eax
80103410:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103413:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103418:	83 e0 08             	and    $0x8,%eax
8010341b:	85 c0                	test   %eax,%eax
8010341d:	74 22                	je     80103441 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
8010341f:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103423:	76 0c                	jbe    80103431 <kbdgetc+0x13e>
80103425:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103429:	77 06                	ja     80103431 <kbdgetc+0x13e>
      c += 'A' - 'a';
8010342b:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
8010342f:	eb 10                	jmp    80103441 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80103431:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103435:	76 0a                	jbe    80103441 <kbdgetc+0x14e>
80103437:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
8010343b:	77 04                	ja     80103441 <kbdgetc+0x14e>
      c += 'a' - 'A';
8010343d:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103441:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103444:	c9                   	leave  
80103445:	c3                   	ret    

80103446 <kbdintr>:

void
kbdintr(void)
{
80103446:	55                   	push   %ebp
80103447:	89 e5                	mov    %esp,%ebp
80103449:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
8010344c:	c7 04 24 f3 32 10 80 	movl   $0x801032f3,(%esp)
80103453:	e8 70 d3 ff ff       	call   801007c8 <consoleintr>
}
80103458:	c9                   	leave  
80103459:	c3                   	ret    

8010345a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010345a:	55                   	push   %ebp
8010345b:	89 e5                	mov    %esp,%ebp
8010345d:	83 ec 14             	sub    $0x14,%esp
80103460:	8b 45 08             	mov    0x8(%ebp),%eax
80103463:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103467:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010346b:	89 c2                	mov    %eax,%edx
8010346d:	ec                   	in     (%dx),%al
8010346e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103471:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103475:	c9                   	leave  
80103476:	c3                   	ret    

80103477 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103477:	55                   	push   %ebp
80103478:	89 e5                	mov    %esp,%ebp
8010347a:	83 ec 08             	sub    $0x8,%esp
8010347d:	8b 55 08             	mov    0x8(%ebp),%edx
80103480:	8b 45 0c             	mov    0xc(%ebp),%eax
80103483:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103487:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010348a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010348e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103492:	ee                   	out    %al,(%dx)
}
80103493:	c9                   	leave  
80103494:	c3                   	ret    

80103495 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103495:	55                   	push   %ebp
80103496:	89 e5                	mov    %esp,%ebp
80103498:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010349b:	9c                   	pushf  
8010349c:	58                   	pop    %eax
8010349d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801034a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801034a3:	c9                   	leave  
801034a4:	c3                   	ret    

801034a5 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801034a5:	55                   	push   %ebp
801034a6:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801034a8:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034ad:	8b 55 08             	mov    0x8(%ebp),%edx
801034b0:	c1 e2 02             	shl    $0x2,%edx
801034b3:	01 c2                	add    %eax,%edx
801034b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801034b8:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801034ba:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034bf:	83 c0 20             	add    $0x20,%eax
801034c2:	8b 00                	mov    (%eax),%eax
}
801034c4:	5d                   	pop    %ebp
801034c5:	c3                   	ret    

801034c6 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034c6:	55                   	push   %ebp
801034c7:	89 e5                	mov    %esp,%ebp
801034c9:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034cc:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034d1:	85 c0                	test   %eax,%eax
801034d3:	75 05                	jne    801034da <lapicinit+0x14>
    return;
801034d5:	e9 43 01 00 00       	jmp    8010361d <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034da:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034e1:	00 
801034e2:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034e9:	e8 b7 ff ff ff       	call   801034a5 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801034ee:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801034f5:	00 
801034f6:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801034fd:	e8 a3 ff ff ff       	call   801034a5 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103502:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103509:	00 
8010350a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103511:	e8 8f ff ff ff       	call   801034a5 <lapicw>
  lapicw(TICR, 10000000); 
80103516:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010351d:	00 
8010351e:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103525:	e8 7b ff ff ff       	call   801034a5 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010352a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103531:	00 
80103532:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103539:	e8 67 ff ff ff       	call   801034a5 <lapicw>
  lapicw(LINT1, MASKED);
8010353e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103545:	00 
80103546:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010354d:	e8 53 ff ff ff       	call   801034a5 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103552:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103557:	83 c0 30             	add    $0x30,%eax
8010355a:	8b 00                	mov    (%eax),%eax
8010355c:	c1 e8 10             	shr    $0x10,%eax
8010355f:	0f b6 c0             	movzbl %al,%eax
80103562:	83 f8 03             	cmp    $0x3,%eax
80103565:	76 14                	jbe    8010357b <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103567:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010356e:	00 
8010356f:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103576:	e8 2a ff ff ff       	call   801034a5 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010357b:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103582:	00 
80103583:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010358a:	e8 16 ff ff ff       	call   801034a5 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010358f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103596:	00 
80103597:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010359e:	e8 02 ff ff ff       	call   801034a5 <lapicw>
  lapicw(ESR, 0);
801035a3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035aa:	00 
801035ab:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801035b2:	e8 ee fe ff ff       	call   801034a5 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801035b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035be:	00 
801035bf:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035c6:	e8 da fe ff ff       	call   801034a5 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035d2:	00 
801035d3:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035da:	e8 c6 fe ff ff       	call   801034a5 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035df:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035e6:	00 
801035e7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801035ee:	e8 b2 fe ff ff       	call   801034a5 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801035f3:	90                   	nop
801035f4:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801035f9:	05 00 03 00 00       	add    $0x300,%eax
801035fe:	8b 00                	mov    (%eax),%eax
80103600:	25 00 10 00 00       	and    $0x1000,%eax
80103605:	85 c0                	test   %eax,%eax
80103607:	75 eb                	jne    801035f4 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103609:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103610:	00 
80103611:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103618:	e8 88 fe ff ff       	call   801034a5 <lapicw>
}
8010361d:	c9                   	leave  
8010361e:	c3                   	ret    

8010361f <cpunum>:

int
cpunum(void)
{
8010361f:	55                   	push   %ebp
80103620:	89 e5                	mov    %esp,%ebp
80103622:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103625:	e8 6b fe ff ff       	call   80103495 <readeflags>
8010362a:	25 00 02 00 00       	and    $0x200,%eax
8010362f:	85 c0                	test   %eax,%eax
80103631:	74 25                	je     80103658 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103633:	a1 40 d6 10 80       	mov    0x8010d640,%eax
80103638:	8d 50 01             	lea    0x1(%eax),%edx
8010363b:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
80103641:	85 c0                	test   %eax,%eax
80103643:	75 13                	jne    80103658 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103645:	8b 45 04             	mov    0x4(%ebp),%eax
80103648:	89 44 24 04          	mov    %eax,0x4(%esp)
8010364c:	c7 04 24 0c 9f 10 80 	movl   $0x80109f0c,(%esp)
80103653:	e8 48 cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103658:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010365d:	85 c0                	test   %eax,%eax
8010365f:	74 0f                	je     80103670 <cpunum+0x51>
    return lapic[ID]>>24;
80103661:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103666:	83 c0 20             	add    $0x20,%eax
80103669:	8b 00                	mov    (%eax),%eax
8010366b:	c1 e8 18             	shr    $0x18,%eax
8010366e:	eb 05                	jmp    80103675 <cpunum+0x56>
  return 0;
80103670:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103675:	c9                   	leave  
80103676:	c3                   	ret    

80103677 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103677:	55                   	push   %ebp
80103678:	89 e5                	mov    %esp,%ebp
8010367a:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010367d:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103682:	85 c0                	test   %eax,%eax
80103684:	74 14                	je     8010369a <lapiceoi+0x23>
    lapicw(EOI, 0);
80103686:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010368d:	00 
8010368e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103695:	e8 0b fe ff ff       	call   801034a5 <lapicw>
}
8010369a:	c9                   	leave  
8010369b:	c3                   	ret    

8010369c <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010369c:	55                   	push   %ebp
8010369d:	89 e5                	mov    %esp,%ebp
}
8010369f:	5d                   	pop    %ebp
801036a0:	c3                   	ret    

801036a1 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801036a1:	55                   	push   %ebp
801036a2:	89 e5                	mov    %esp,%ebp
801036a4:	83 ec 1c             	sub    $0x1c,%esp
801036a7:	8b 45 08             	mov    0x8(%ebp),%eax
801036aa:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801036ad:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801036b4:	00 
801036b5:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036bc:	e8 b6 fd ff ff       	call   80103477 <outb>
  outb(CMOS_PORT+1, 0x0A);
801036c1:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036c8:	00 
801036c9:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036d0:	e8 a2 fd ff ff       	call   80103477 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036d5:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036dc:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036df:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036e4:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036e7:	8d 50 02             	lea    0x2(%eax),%edx
801036ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801036ed:	c1 e8 04             	shr    $0x4,%eax
801036f0:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801036f3:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801036f7:	c1 e0 18             	shl    $0x18,%eax
801036fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801036fe:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103705:	e8 9b fd ff ff       	call   801034a5 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010370a:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103711:	00 
80103712:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103719:	e8 87 fd ff ff       	call   801034a5 <lapicw>
  microdelay(200);
8010371e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103725:	e8 72 ff ff ff       	call   8010369c <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010372a:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103731:	00 
80103732:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103739:	e8 67 fd ff ff       	call   801034a5 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010373e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103745:	e8 52 ff ff ff       	call   8010369c <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010374a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103751:	eb 40                	jmp    80103793 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103753:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103757:	c1 e0 18             	shl    $0x18,%eax
8010375a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010375e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103765:	e8 3b fd ff ff       	call   801034a5 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010376a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010376d:	c1 e8 0c             	shr    $0xc,%eax
80103770:	80 cc 06             	or     $0x6,%ah
80103773:	89 44 24 04          	mov    %eax,0x4(%esp)
80103777:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010377e:	e8 22 fd ff ff       	call   801034a5 <lapicw>
    microdelay(200);
80103783:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010378a:	e8 0d ff ff ff       	call   8010369c <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010378f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103793:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103797:	7e ba                	jle    80103753 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103799:	c9                   	leave  
8010379a:	c3                   	ret    

8010379b <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010379b:	55                   	push   %ebp
8010379c:	89 e5                	mov    %esp,%ebp
8010379e:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801037a1:	8b 45 08             	mov    0x8(%ebp),%eax
801037a4:	0f b6 c0             	movzbl %al,%eax
801037a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801037ab:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801037b2:	e8 c0 fc ff ff       	call   80103477 <outb>
  microdelay(200);
801037b7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037be:	e8 d9 fe ff ff       	call   8010369c <microdelay>

  return inb(CMOS_RETURN);
801037c3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037ca:	e8 8b fc ff ff       	call   8010345a <inb>
801037cf:	0f b6 c0             	movzbl %al,%eax
}
801037d2:	c9                   	leave  
801037d3:	c3                   	ret    

801037d4 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037d4:	55                   	push   %ebp
801037d5:	89 e5                	mov    %esp,%ebp
801037d7:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037e1:	e8 b5 ff ff ff       	call   8010379b <cmos_read>
801037e6:	8b 55 08             	mov    0x8(%ebp),%edx
801037e9:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801037eb:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801037f2:	e8 a4 ff ff ff       	call   8010379b <cmos_read>
801037f7:	8b 55 08             	mov    0x8(%ebp),%edx
801037fa:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801037fd:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103804:	e8 92 ff ff ff       	call   8010379b <cmos_read>
80103809:	8b 55 08             	mov    0x8(%ebp),%edx
8010380c:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010380f:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103816:	e8 80 ff ff ff       	call   8010379b <cmos_read>
8010381b:	8b 55 08             	mov    0x8(%ebp),%edx
8010381e:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103821:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103828:	e8 6e ff ff ff       	call   8010379b <cmos_read>
8010382d:	8b 55 08             	mov    0x8(%ebp),%edx
80103830:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103833:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
8010383a:	e8 5c ff ff ff       	call   8010379b <cmos_read>
8010383f:	8b 55 08             	mov    0x8(%ebp),%edx
80103842:	89 42 14             	mov    %eax,0x14(%edx)
}
80103845:	c9                   	leave  
80103846:	c3                   	ret    

80103847 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103847:	55                   	push   %ebp
80103848:	89 e5                	mov    %esp,%ebp
8010384a:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010384d:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103854:	e8 42 ff ff ff       	call   8010379b <cmos_read>
80103859:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
8010385c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010385f:	83 e0 04             	and    $0x4,%eax
80103862:	85 c0                	test   %eax,%eax
80103864:	0f 94 c0             	sete   %al
80103867:	0f b6 c0             	movzbl %al,%eax
8010386a:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
8010386d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103870:	89 04 24             	mov    %eax,(%esp)
80103873:	e8 5c ff ff ff       	call   801037d4 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103878:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010387f:	e8 17 ff ff ff       	call   8010379b <cmos_read>
80103884:	25 80 00 00 00       	and    $0x80,%eax
80103889:	85 c0                	test   %eax,%eax
8010388b:	74 02                	je     8010388f <cmostime+0x48>
        continue;
8010388d:	eb 36                	jmp    801038c5 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010388f:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103892:	89 04 24             	mov    %eax,(%esp)
80103895:	e8 3a ff ff ff       	call   801037d4 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010389a:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801038a1:	00 
801038a2:	8d 45 c0             	lea    -0x40(%ebp),%eax
801038a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801038a9:	8d 45 d8             	lea    -0x28(%ebp),%eax
801038ac:	89 04 24             	mov    %eax,(%esp)
801038af:	e8 ab 21 00 00       	call   80105a5f <memcmp>
801038b4:	85 c0                	test   %eax,%eax
801038b6:	75 0d                	jne    801038c5 <cmostime+0x7e>
      break;
801038b8:	90                   	nop
  }

  // convert
  if (bcd) {
801038b9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038bd:	0f 84 ac 00 00 00    	je     8010396f <cmostime+0x128>
801038c3:	eb 02                	jmp    801038c7 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038c5:	eb a6                	jmp    8010386d <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038c7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038ca:	c1 e8 04             	shr    $0x4,%eax
801038cd:	89 c2                	mov    %eax,%edx
801038cf:	89 d0                	mov    %edx,%eax
801038d1:	c1 e0 02             	shl    $0x2,%eax
801038d4:	01 d0                	add    %edx,%eax
801038d6:	01 c0                	add    %eax,%eax
801038d8:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038db:	83 e2 0f             	and    $0xf,%edx
801038de:	01 d0                	add    %edx,%eax
801038e0:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038e3:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038e6:	c1 e8 04             	shr    $0x4,%eax
801038e9:	89 c2                	mov    %eax,%edx
801038eb:	89 d0                	mov    %edx,%eax
801038ed:	c1 e0 02             	shl    $0x2,%eax
801038f0:	01 d0                	add    %edx,%eax
801038f2:	01 c0                	add    %eax,%eax
801038f4:	8b 55 dc             	mov    -0x24(%ebp),%edx
801038f7:	83 e2 0f             	and    $0xf,%edx
801038fa:	01 d0                	add    %edx,%eax
801038fc:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801038ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103902:	c1 e8 04             	shr    $0x4,%eax
80103905:	89 c2                	mov    %eax,%edx
80103907:	89 d0                	mov    %edx,%eax
80103909:	c1 e0 02             	shl    $0x2,%eax
8010390c:	01 d0                	add    %edx,%eax
8010390e:	01 c0                	add    %eax,%eax
80103910:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103913:	83 e2 0f             	and    $0xf,%edx
80103916:	01 d0                	add    %edx,%eax
80103918:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010391b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010391e:	c1 e8 04             	shr    $0x4,%eax
80103921:	89 c2                	mov    %eax,%edx
80103923:	89 d0                	mov    %edx,%eax
80103925:	c1 e0 02             	shl    $0x2,%eax
80103928:	01 d0                	add    %edx,%eax
8010392a:	01 c0                	add    %eax,%eax
8010392c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010392f:	83 e2 0f             	and    $0xf,%edx
80103932:	01 d0                	add    %edx,%eax
80103934:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103937:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010393a:	c1 e8 04             	shr    $0x4,%eax
8010393d:	89 c2                	mov    %eax,%edx
8010393f:	89 d0                	mov    %edx,%eax
80103941:	c1 e0 02             	shl    $0x2,%eax
80103944:	01 d0                	add    %edx,%eax
80103946:	01 c0                	add    %eax,%eax
80103948:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010394b:	83 e2 0f             	and    $0xf,%edx
8010394e:	01 d0                	add    %edx,%eax
80103950:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103953:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103956:	c1 e8 04             	shr    $0x4,%eax
80103959:	89 c2                	mov    %eax,%edx
8010395b:	89 d0                	mov    %edx,%eax
8010395d:	c1 e0 02             	shl    $0x2,%eax
80103960:	01 d0                	add    %edx,%eax
80103962:	01 c0                	add    %eax,%eax
80103964:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103967:	83 e2 0f             	and    $0xf,%edx
8010396a:	01 d0                	add    %edx,%eax
8010396c:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010396f:	8b 45 08             	mov    0x8(%ebp),%eax
80103972:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103975:	89 10                	mov    %edx,(%eax)
80103977:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010397a:	89 50 04             	mov    %edx,0x4(%eax)
8010397d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103980:	89 50 08             	mov    %edx,0x8(%eax)
80103983:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103986:	89 50 0c             	mov    %edx,0xc(%eax)
80103989:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010398c:	89 50 10             	mov    %edx,0x10(%eax)
8010398f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103992:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103995:	8b 45 08             	mov    0x8(%ebp),%eax
80103998:	8b 40 14             	mov    0x14(%eax),%eax
8010399b:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801039a1:	8b 45 08             	mov    0x8(%ebp),%eax
801039a4:	89 50 14             	mov    %edx,0x14(%eax)
}
801039a7:	c9                   	leave  
801039a8:	c3                   	ret    

801039a9 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
801039a9:	55                   	push   %ebp
801039aa:	89 e5                	mov    %esp,%ebp
801039ac:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801039af:	c7 44 24 04 38 9f 10 	movl   $0x80109f38,0x4(%esp)
801039b6:	80 
801039b7:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
801039be:	e8 b0 1d 00 00       	call   80105773 <initlock>
  readsb(dev, &sb);
801039c3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801039ca:	8b 45 08             	mov    0x8(%ebp),%eax
801039cd:	89 04 24             	mov    %eax,(%esp)
801039d0:	e8 1c da ff ff       	call   801013f1 <readsb>
  log.start = sb.logstart;
801039d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039d8:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039e0:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039e5:	8b 45 08             	mov    0x8(%ebp),%eax
801039e8:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
801039ed:	e8 9a 01 00 00       	call   80103b8c <recover_from_log>
}
801039f2:	c9                   	leave  
801039f3:	c3                   	ret    

801039f4 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801039f4:	55                   	push   %ebp
801039f5:	89 e5                	mov    %esp,%ebp
801039f7:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801039fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a01:	e9 8c 00 00 00       	jmp    80103a92 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103a06:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103a0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a0f:	01 d0                	add    %edx,%eax
80103a11:	83 c0 01             	add    $0x1,%eax
80103a14:	89 c2                	mov    %eax,%edx
80103a16:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a1b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a1f:	89 04 24             	mov    %eax,(%esp)
80103a22:	e8 7f c7 ff ff       	call   801001a6 <bread>
80103a27:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a2d:	83 c0 10             	add    $0x10,%eax
80103a30:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a37:	89 c2                	mov    %eax,%edx
80103a39:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a3e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a42:	89 04 24             	mov    %eax,(%esp)
80103a45:	e8 5c c7 ff ff       	call   801001a6 <bread>
80103a4a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a50:	8d 50 18             	lea    0x18(%eax),%edx
80103a53:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a56:	83 c0 18             	add    $0x18,%eax
80103a59:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a60:	00 
80103a61:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a65:	89 04 24             	mov    %eax,(%esp)
80103a68:	e8 4a 20 00 00       	call   80105ab7 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a70:	89 04 24             	mov    %eax,(%esp)
80103a73:	e8 65 c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a7b:	89 04 24             	mov    %eax,(%esp)
80103a7e:	e8 94 c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a83:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a86:	89 04 24             	mov    %eax,(%esp)
80103a89:	e8 89 c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a8e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a92:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103a97:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a9a:	0f 8f 66 ff ff ff    	jg     80103a06 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103aa0:	c9                   	leave  
80103aa1:	c3                   	ret    

80103aa2 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103aa2:	55                   	push   %ebp
80103aa3:	89 e5                	mov    %esp,%ebp
80103aa5:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103aa8:	a1 94 42 11 80       	mov    0x80114294,%eax
80103aad:	89 c2                	mov    %eax,%edx
80103aaf:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103ab4:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ab8:	89 04 24             	mov    %eax,(%esp)
80103abb:	e8 e6 c6 ff ff       	call   801001a6 <bread>
80103ac0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103ac3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ac6:	83 c0 18             	add    $0x18,%eax
80103ac9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103acc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103acf:	8b 00                	mov    (%eax),%eax
80103ad1:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103ad6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103add:	eb 1b                	jmp    80103afa <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103adf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ae2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ae5:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103ae9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103aec:	83 c2 10             	add    $0x10,%edx
80103aef:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103af6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103afa:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103aff:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b02:	7f db                	jg     80103adf <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b07:	89 04 24             	mov    %eax,(%esp)
80103b0a:	e8 08 c7 ff ff       	call   80100217 <brelse>
}
80103b0f:	c9                   	leave  
80103b10:	c3                   	ret    

80103b11 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103b11:	55                   	push   %ebp
80103b12:	89 e5                	mov    %esp,%ebp
80103b14:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b17:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b1c:	89 c2                	mov    %eax,%edx
80103b1e:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b23:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b27:	89 04 24             	mov    %eax,(%esp)
80103b2a:	e8 77 c6 ff ff       	call   801001a6 <bread>
80103b2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b35:	83 c0 18             	add    $0x18,%eax
80103b38:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b3b:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b44:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b46:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b4d:	eb 1b                	jmp    80103b6a <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b52:	83 c0 10             	add    $0x10,%eax
80103b55:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b62:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b66:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b6a:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b6f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b72:	7f db                	jg     80103b4f <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b77:	89 04 24             	mov    %eax,(%esp)
80103b7a:	e8 5e c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b82:	89 04 24             	mov    %eax,(%esp)
80103b85:	e8 8d c6 ff ff       	call   80100217 <brelse>
}
80103b8a:	c9                   	leave  
80103b8b:	c3                   	ret    

80103b8c <recover_from_log>:

static void
recover_from_log(void)
{
80103b8c:	55                   	push   %ebp
80103b8d:	89 e5                	mov    %esp,%ebp
80103b8f:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103b92:	e8 0b ff ff ff       	call   80103aa2 <read_head>
  install_trans(); // if committed, copy from log to disk
80103b97:	e8 58 fe ff ff       	call   801039f4 <install_trans>
  log.lh.n = 0;
80103b9c:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103ba3:	00 00 00 
  write_head(); // clear the log
80103ba6:	e8 66 ff ff ff       	call   80103b11 <write_head>
}
80103bab:	c9                   	leave  
80103bac:	c3                   	ret    

80103bad <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103bad:	55                   	push   %ebp
80103bae:	89 e5                	mov    %esp,%ebp
80103bb0:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103bb3:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bba:	e8 d5 1b 00 00       	call   80105794 <acquire>
  while(1){
    if(log.committing){
80103bbf:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103bc4:	85 c0                	test   %eax,%eax
80103bc6:	74 16                	je     80103bde <begin_op+0x31>
      sleep(&log, &log.lock);
80103bc8:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bcf:	80 
80103bd0:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bd7:	e8 74 18 00 00       	call   80105450 <sleep>
80103bdc:	eb 4f                	jmp    80103c2d <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103bde:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103be4:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103be9:	8d 50 01             	lea    0x1(%eax),%edx
80103bec:	89 d0                	mov    %edx,%eax
80103bee:	c1 e0 02             	shl    $0x2,%eax
80103bf1:	01 d0                	add    %edx,%eax
80103bf3:	01 c0                	add    %eax,%eax
80103bf5:	01 c8                	add    %ecx,%eax
80103bf7:	83 f8 1e             	cmp    $0x1e,%eax
80103bfa:	7e 16                	jle    80103c12 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103bfc:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103c03:	80 
80103c04:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c0b:	e8 40 18 00 00       	call   80105450 <sleep>
80103c10:	eb 1b                	jmp    80103c2d <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103c12:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c17:	83 c0 01             	add    $0x1,%eax
80103c1a:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c1f:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c26:	e8 cb 1b 00 00       	call   801057f6 <release>
      break;
80103c2b:	eb 02                	jmp    80103c2f <begin_op+0x82>
    }
  }
80103c2d:	eb 90                	jmp    80103bbf <begin_op+0x12>
}
80103c2f:	c9                   	leave  
80103c30:	c3                   	ret    

80103c31 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c31:	55                   	push   %ebp
80103c32:	89 e5                	mov    %esp,%ebp
80103c34:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c3e:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c45:	e8 4a 1b 00 00       	call   80105794 <acquire>
  log.outstanding -= 1;
80103c4a:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c4f:	83 e8 01             	sub    $0x1,%eax
80103c52:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c57:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c5c:	85 c0                	test   %eax,%eax
80103c5e:	74 0c                	je     80103c6c <end_op+0x3b>
    panic("log.committing");
80103c60:	c7 04 24 3c 9f 10 80 	movl   $0x80109f3c,(%esp)
80103c67:	e8 ce c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c6c:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c71:	85 c0                	test   %eax,%eax
80103c73:	75 13                	jne    80103c88 <end_op+0x57>
    do_commit = 1;
80103c75:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c7c:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c83:	00 00 00 
80103c86:	eb 0c                	jmp    80103c94 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c88:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c8f:	e8 98 18 00 00       	call   8010552c <wakeup>
  }
  release(&log.lock);
80103c94:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c9b:	e8 56 1b 00 00       	call   801057f6 <release>

  if(do_commit){
80103ca0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ca4:	74 33                	je     80103cd9 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103ca6:	e8 de 00 00 00       	call   80103d89 <commit>
    acquire(&log.lock);
80103cab:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cb2:	e8 dd 1a 00 00       	call   80105794 <acquire>
    log.committing = 0;
80103cb7:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103cbe:	00 00 00 
    wakeup(&log);
80103cc1:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cc8:	e8 5f 18 00 00       	call   8010552c <wakeup>
    release(&log.lock);
80103ccd:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cd4:	e8 1d 1b 00 00       	call   801057f6 <release>
  }
}
80103cd9:	c9                   	leave  
80103cda:	c3                   	ret    

80103cdb <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103cdb:	55                   	push   %ebp
80103cdc:	89 e5                	mov    %esp,%ebp
80103cde:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103ce1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ce8:	e9 8c 00 00 00       	jmp    80103d79 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103ced:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103cf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf6:	01 d0                	add    %edx,%eax
80103cf8:	83 c0 01             	add    $0x1,%eax
80103cfb:	89 c2                	mov    %eax,%edx
80103cfd:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d02:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d06:	89 04 24             	mov    %eax,(%esp)
80103d09:	e8 98 c4 ff ff       	call   801001a6 <bread>
80103d0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d14:	83 c0 10             	add    $0x10,%eax
80103d17:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d1e:	89 c2                	mov    %eax,%edx
80103d20:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d25:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d29:	89 04 24             	mov    %eax,(%esp)
80103d2c:	e8 75 c4 ff ff       	call   801001a6 <bread>
80103d31:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d34:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d37:	8d 50 18             	lea    0x18(%eax),%edx
80103d3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d3d:	83 c0 18             	add    $0x18,%eax
80103d40:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d47:	00 
80103d48:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d4c:	89 04 24             	mov    %eax,(%esp)
80103d4f:	e8 63 1d 00 00       	call   80105ab7 <memmove>
    bwrite(to);  // write the log
80103d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d57:	89 04 24             	mov    %eax,(%esp)
80103d5a:	e8 7e c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d5f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d62:	89 04 24             	mov    %eax,(%esp)
80103d65:	e8 ad c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d6d:	89 04 24             	mov    %eax,(%esp)
80103d70:	e8 a2 c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d75:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d79:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d7e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d81:	0f 8f 66 ff ff ff    	jg     80103ced <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d87:	c9                   	leave  
80103d88:	c3                   	ret    

80103d89 <commit>:

static void
commit()
{
80103d89:	55                   	push   %ebp
80103d8a:	89 e5                	mov    %esp,%ebp
80103d8c:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103d8f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d94:	85 c0                	test   %eax,%eax
80103d96:	7e 1e                	jle    80103db6 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103d98:	e8 3e ff ff ff       	call   80103cdb <write_log>
    write_head();    // Write header to disk -- the real commit
80103d9d:	e8 6f fd ff ff       	call   80103b11 <write_head>
    install_trans(); // Now install writes to home locations
80103da2:	e8 4d fc ff ff       	call   801039f4 <install_trans>
    log.lh.n = 0; 
80103da7:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103dae:	00 00 00 
    write_head();    // Erase the transaction from the log
80103db1:	e8 5b fd ff ff       	call   80103b11 <write_head>
  }
}
80103db6:	c9                   	leave  
80103db7:	c3                   	ret    

80103db8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103db8:	55                   	push   %ebp
80103db9:	89 e5                	mov    %esp,%ebp
80103dbb:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103dbe:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dc3:	83 f8 1d             	cmp    $0x1d,%eax
80103dc6:	7f 12                	jg     80103dda <log_write+0x22>
80103dc8:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dcd:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103dd3:	83 ea 01             	sub    $0x1,%edx
80103dd6:	39 d0                	cmp    %edx,%eax
80103dd8:	7c 0c                	jl     80103de6 <log_write+0x2e>
    panic("too big a transaction");
80103dda:	c7 04 24 4b 9f 10 80 	movl   $0x80109f4b,(%esp)
80103de1:	e8 54 c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103de6:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103deb:	85 c0                	test   %eax,%eax
80103ded:	7f 0c                	jg     80103dfb <log_write+0x43>
    panic("log_write outside of trans");
80103def:	c7 04 24 61 9f 10 80 	movl   $0x80109f61,(%esp)
80103df6:	e8 3f c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103dfb:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e02:	e8 8d 19 00 00       	call   80105794 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103e07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e0e:	eb 1f                	jmp    80103e2f <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103e10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e13:	83 c0 10             	add    $0x10,%eax
80103e16:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e1d:	89 c2                	mov    %eax,%edx
80103e1f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e22:	8b 40 08             	mov    0x8(%eax),%eax
80103e25:	39 c2                	cmp    %eax,%edx
80103e27:	75 02                	jne    80103e2b <log_write+0x73>
      break;
80103e29:	eb 0e                	jmp    80103e39 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e2b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e2f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e34:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e37:	7f d7                	jg     80103e10 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e39:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3c:	8b 40 08             	mov    0x8(%eax),%eax
80103e3f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e42:	83 c2 10             	add    $0x10,%edx
80103e45:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e4c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e51:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e54:	75 0d                	jne    80103e63 <log_write+0xab>
    log.lh.n++;
80103e56:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e5b:	83 c0 01             	add    $0x1,%eax
80103e5e:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e63:	8b 45 08             	mov    0x8(%ebp),%eax
80103e66:	8b 00                	mov    (%eax),%eax
80103e68:	83 c8 04             	or     $0x4,%eax
80103e6b:	89 c2                	mov    %eax,%edx
80103e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e70:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e72:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e79:	e8 78 19 00 00       	call   801057f6 <release>
}
80103e7e:	c9                   	leave  
80103e7f:	c3                   	ret    

80103e80 <v2p>:
80103e80:	55                   	push   %ebp
80103e81:	89 e5                	mov    %esp,%ebp
80103e83:	8b 45 08             	mov    0x8(%ebp),%eax
80103e86:	05 00 00 00 80       	add    $0x80000000,%eax
80103e8b:	5d                   	pop    %ebp
80103e8c:	c3                   	ret    

80103e8d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e8d:	55                   	push   %ebp
80103e8e:	89 e5                	mov    %esp,%ebp
80103e90:	8b 45 08             	mov    0x8(%ebp),%eax
80103e93:	05 00 00 00 80       	add    $0x80000000,%eax
80103e98:	5d                   	pop    %ebp
80103e99:	c3                   	ret    

80103e9a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103e9a:	55                   	push   %ebp
80103e9b:	89 e5                	mov    %esp,%ebp
80103e9d:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103ea0:	8b 55 08             	mov    0x8(%ebp),%edx
80103ea3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ea6:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ea9:	f0 87 02             	lock xchg %eax,(%edx)
80103eac:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103eaf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103eb2:	c9                   	leave  
80103eb3:	c3                   	ret    

80103eb4 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103eb4:	55                   	push   %ebp
80103eb5:	89 e5                	mov    %esp,%ebp
80103eb7:	83 e4 f0             	and    $0xfffffff0,%esp
80103eba:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103ebd:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103ec4:	80 
80103ec5:	c7 04 24 5c 0d 12 80 	movl   $0x80120d5c,(%esp)
80103ecc:	e8 00 f2 ff ff       	call   801030d1 <kinit1>
  kvmalloc();      // kernel page table
80103ed1:	e8 84 47 00 00       	call   8010865a <kvmalloc>
  mpinit();        // collect info about this machine
80103ed6:	e8 41 04 00 00       	call   8010431c <mpinit>
  lapicinit();
80103edb:	e8 e6 f5 ff ff       	call   801034c6 <lapicinit>
  seginit();       // set up segments
80103ee0:	e8 08 41 00 00       	call   80107fed <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103ee5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103eeb:	0f b6 00             	movzbl (%eax),%eax
80103eee:	0f b6 c0             	movzbl %al,%eax
80103ef1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ef5:	c7 04 24 7c 9f 10 80 	movl   $0x80109f7c,(%esp)
80103efc:	e8 9f c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103f01:	e8 74 06 00 00       	call   8010457a <picinit>
  ioapicinit();    // another interrupt controller
80103f06:	e8 bc f0 ff ff       	call   80102fc7 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103f0b:	e8 a0 cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103f10:	e8 27 34 00 00       	call   8010733c <uartinit>
  pinit();         // process table
80103f15:	e8 6a 0b 00 00       	call   80104a84 <pinit>
  tvinit();        // trap vectors
80103f1a:	e8 37 2f 00 00       	call   80106e56 <tvinit>
  binit();         // buffer cache
80103f1f:	e8 10 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f24:	e8 e1 d0 ff ff       	call   8010100a <fileinit>
  ideinit();       // disk
80103f29:	e8 cb ec ff ff       	call   80102bf9 <ideinit>
  if(!ismp)
80103f2e:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f33:	85 c0                	test   %eax,%eax
80103f35:	75 05                	jne    80103f3c <main+0x88>
    timerinit();   // uniprocessor timer
80103f37:	e8 65 2e 00 00       	call   80106da1 <timerinit>
  startothers();   // start other processors
80103f3c:	e8 7f 00 00 00       	call   80103fc0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f41:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f48:	8e 
80103f49:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f50:	e8 b4 f1 ff ff       	call   80103109 <kinit2>
  userinit();      // first user process
80103f55:	e8 48 0c 00 00       	call   80104ba2 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f5a:	e8 1a 00 00 00       	call   80103f79 <mpmain>

80103f5f <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f5f:	55                   	push   %ebp
80103f60:	89 e5                	mov    %esp,%ebp
80103f62:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f65:	e8 07 47 00 00       	call   80108671 <switchkvm>
  seginit();
80103f6a:	e8 7e 40 00 00       	call   80107fed <seginit>
  lapicinit();
80103f6f:	e8 52 f5 ff ff       	call   801034c6 <lapicinit>
  mpmain();
80103f74:	e8 00 00 00 00       	call   80103f79 <mpmain>

80103f79 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f79:	55                   	push   %ebp
80103f7a:	89 e5                	mov    %esp,%ebp
80103f7c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f7f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f85:	0f b6 00             	movzbl (%eax),%eax
80103f88:	0f b6 c0             	movzbl %al,%eax
80103f8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f8f:	c7 04 24 93 9f 10 80 	movl   $0x80109f93,(%esp)
80103f96:	e8 05 c4 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103f9b:	e8 2a 30 00 00       	call   80106fca <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103fa0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103fa6:	05 a8 00 00 00       	add    $0xa8,%eax
80103fab:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103fb2:	00 
80103fb3:	89 04 24             	mov    %eax,(%esp)
80103fb6:	e8 df fe ff ff       	call   80103e9a <xchg>
  scheduler();     // start running processes
80103fbb:	e8 d2 12 00 00       	call   80105292 <scheduler>

80103fc0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fc0:	55                   	push   %ebp
80103fc1:	89 e5                	mov    %esp,%ebp
80103fc3:	53                   	push   %ebx
80103fc4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fc7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fce:	e8 ba fe ff ff       	call   80103e8d <p2v>
80103fd3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fd6:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fdb:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fdf:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103fe6:	80 
80103fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fea:	89 04 24             	mov    %eax,(%esp)
80103fed:	e8 c5 1a 00 00       	call   80105ab7 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103ff2:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80103ff9:	e9 85 00 00 00       	jmp    80104083 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103ffe:	e8 1c f6 ff ff       	call   8010361f <cpunum>
80104003:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104009:	05 60 43 11 80       	add    $0x80114360,%eax
8010400e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104011:	75 02                	jne    80104015 <startothers+0x55>
      continue;
80104013:	eb 67                	jmp    8010407c <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104015:	e8 29 f2 ff ff       	call   80103243 <kalloc>
8010401a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010401d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104020:	83 e8 04             	sub    $0x4,%eax
80104023:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104026:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010402c:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010402e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104031:	83 e8 08             	sub    $0x8,%eax
80104034:	c7 00 5f 3f 10 80    	movl   $0x80103f5f,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
8010403a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010403d:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104040:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
80104047:	e8 34 fe ff ff       	call   80103e80 <v2p>
8010404c:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010404e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104051:	89 04 24             	mov    %eax,(%esp)
80104054:	e8 27 fe ff ff       	call   80103e80 <v2p>
80104059:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010405c:	0f b6 12             	movzbl (%edx),%edx
8010405f:	0f b6 d2             	movzbl %dl,%edx
80104062:	89 44 24 04          	mov    %eax,0x4(%esp)
80104066:	89 14 24             	mov    %edx,(%esp)
80104069:	e8 33 f6 ff ff       	call   801036a1 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010406e:	90                   	nop
8010406f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104072:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104078:	85 c0                	test   %eax,%eax
8010407a:	74 f3                	je     8010406f <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010407c:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104083:	a1 40 49 11 80       	mov    0x80114940,%eax
80104088:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010408e:	05 60 43 11 80       	add    $0x80114360,%eax
80104093:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104096:	0f 87 62 ff ff ff    	ja     80103ffe <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010409c:	83 c4 24             	add    $0x24,%esp
8010409f:	5b                   	pop    %ebx
801040a0:	5d                   	pop    %ebp
801040a1:	c3                   	ret    

801040a2 <p2v>:
801040a2:	55                   	push   %ebp
801040a3:	89 e5                	mov    %esp,%ebp
801040a5:	8b 45 08             	mov    0x8(%ebp),%eax
801040a8:	05 00 00 00 80       	add    $0x80000000,%eax
801040ad:	5d                   	pop    %ebp
801040ae:	c3                   	ret    

801040af <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801040af:	55                   	push   %ebp
801040b0:	89 e5                	mov    %esp,%ebp
801040b2:	83 ec 14             	sub    $0x14,%esp
801040b5:	8b 45 08             	mov    0x8(%ebp),%eax
801040b8:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040bc:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801040c0:	89 c2                	mov    %eax,%edx
801040c2:	ec                   	in     (%dx),%al
801040c3:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040c6:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040ca:	c9                   	leave  
801040cb:	c3                   	ret    

801040cc <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040cc:	55                   	push   %ebp
801040cd:	89 e5                	mov    %esp,%ebp
801040cf:	83 ec 08             	sub    $0x8,%esp
801040d2:	8b 55 08             	mov    0x8(%ebp),%edx
801040d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801040d8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040dc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040df:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040e3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040e7:	ee                   	out    %al,(%dx)
}
801040e8:	c9                   	leave  
801040e9:	c3                   	ret    

801040ea <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040ea:	55                   	push   %ebp
801040eb:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040ed:	a1 44 d6 10 80       	mov    0x8010d644,%eax
801040f2:	89 c2                	mov    %eax,%edx
801040f4:	b8 60 43 11 80       	mov    $0x80114360,%eax
801040f9:	29 c2                	sub    %eax,%edx
801040fb:	89 d0                	mov    %edx,%eax
801040fd:	c1 f8 02             	sar    $0x2,%eax
80104100:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104106:	5d                   	pop    %ebp
80104107:	c3                   	ret    

80104108 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104108:	55                   	push   %ebp
80104109:	89 e5                	mov    %esp,%ebp
8010410b:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010410e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104115:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010411c:	eb 15                	jmp    80104133 <sum+0x2b>
    sum += addr[i];
8010411e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104121:	8b 45 08             	mov    0x8(%ebp),%eax
80104124:	01 d0                	add    %edx,%eax
80104126:	0f b6 00             	movzbl (%eax),%eax
80104129:	0f b6 c0             	movzbl %al,%eax
8010412c:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010412f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104133:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104136:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104139:	7c e3                	jl     8010411e <sum+0x16>
    sum += addr[i];
  return sum;
8010413b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010413e:	c9                   	leave  
8010413f:	c3                   	ret    

80104140 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104140:	55                   	push   %ebp
80104141:	89 e5                	mov    %esp,%ebp
80104143:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104146:	8b 45 08             	mov    0x8(%ebp),%eax
80104149:	89 04 24             	mov    %eax,(%esp)
8010414c:	e8 51 ff ff ff       	call   801040a2 <p2v>
80104151:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104154:	8b 55 0c             	mov    0xc(%ebp),%edx
80104157:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010415a:	01 d0                	add    %edx,%eax
8010415c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010415f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104162:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104165:	eb 3f                	jmp    801041a6 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104167:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010416e:	00 
8010416f:	c7 44 24 04 a4 9f 10 	movl   $0x80109fa4,0x4(%esp)
80104176:	80 
80104177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417a:	89 04 24             	mov    %eax,(%esp)
8010417d:	e8 dd 18 00 00       	call   80105a5f <memcmp>
80104182:	85 c0                	test   %eax,%eax
80104184:	75 1c                	jne    801041a2 <mpsearch1+0x62>
80104186:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010418d:	00 
8010418e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104191:	89 04 24             	mov    %eax,(%esp)
80104194:	e8 6f ff ff ff       	call   80104108 <sum>
80104199:	84 c0                	test   %al,%al
8010419b:	75 05                	jne    801041a2 <mpsearch1+0x62>
      return (struct mp*)p;
8010419d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a0:	eb 11                	jmp    801041b3 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801041a2:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801041a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801041ac:	72 b9                	jb     80104167 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801041ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041b3:	c9                   	leave  
801041b4:	c3                   	ret    

801041b5 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801041b5:	55                   	push   %ebp
801041b6:	89 e5                	mov    %esp,%ebp
801041b8:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041bb:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c5:	83 c0 0f             	add    $0xf,%eax
801041c8:	0f b6 00             	movzbl (%eax),%eax
801041cb:	0f b6 c0             	movzbl %al,%eax
801041ce:	c1 e0 08             	shl    $0x8,%eax
801041d1:	89 c2                	mov    %eax,%edx
801041d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d6:	83 c0 0e             	add    $0xe,%eax
801041d9:	0f b6 00             	movzbl (%eax),%eax
801041dc:	0f b6 c0             	movzbl %al,%eax
801041df:	09 d0                	or     %edx,%eax
801041e1:	c1 e0 04             	shl    $0x4,%eax
801041e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041e7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041eb:	74 21                	je     8010420e <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041ed:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041f4:	00 
801041f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041f8:	89 04 24             	mov    %eax,(%esp)
801041fb:	e8 40 ff ff ff       	call   80104140 <mpsearch1>
80104200:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104203:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104207:	74 50                	je     80104259 <mpsearch+0xa4>
      return mp;
80104209:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010420c:	eb 5f                	jmp    8010426d <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010420e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104211:	83 c0 14             	add    $0x14,%eax
80104214:	0f b6 00             	movzbl (%eax),%eax
80104217:	0f b6 c0             	movzbl %al,%eax
8010421a:	c1 e0 08             	shl    $0x8,%eax
8010421d:	89 c2                	mov    %eax,%edx
8010421f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104222:	83 c0 13             	add    $0x13,%eax
80104225:	0f b6 00             	movzbl (%eax),%eax
80104228:	0f b6 c0             	movzbl %al,%eax
8010422b:	09 d0                	or     %edx,%eax
8010422d:	c1 e0 0a             	shl    $0xa,%eax
80104230:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104233:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104236:	2d 00 04 00 00       	sub    $0x400,%eax
8010423b:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104242:	00 
80104243:	89 04 24             	mov    %eax,(%esp)
80104246:	e8 f5 fe ff ff       	call   80104140 <mpsearch1>
8010424b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010424e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104252:	74 05                	je     80104259 <mpsearch+0xa4>
      return mp;
80104254:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104257:	eb 14                	jmp    8010426d <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104259:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104260:	00 
80104261:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104268:	e8 d3 fe ff ff       	call   80104140 <mpsearch1>
}
8010426d:	c9                   	leave  
8010426e:	c3                   	ret    

8010426f <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010426f:	55                   	push   %ebp
80104270:	89 e5                	mov    %esp,%ebp
80104272:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104275:	e8 3b ff ff ff       	call   801041b5 <mpsearch>
8010427a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010427d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104281:	74 0a                	je     8010428d <mpconfig+0x1e>
80104283:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104286:	8b 40 04             	mov    0x4(%eax),%eax
80104289:	85 c0                	test   %eax,%eax
8010428b:	75 0a                	jne    80104297 <mpconfig+0x28>
    return 0;
8010428d:	b8 00 00 00 00       	mov    $0x0,%eax
80104292:	e9 83 00 00 00       	jmp    8010431a <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429a:	8b 40 04             	mov    0x4(%eax),%eax
8010429d:	89 04 24             	mov    %eax,(%esp)
801042a0:	e8 fd fd ff ff       	call   801040a2 <p2v>
801042a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801042a8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801042af:	00 
801042b0:	c7 44 24 04 a9 9f 10 	movl   $0x80109fa9,0x4(%esp)
801042b7:	80 
801042b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042bb:	89 04 24             	mov    %eax,(%esp)
801042be:	e8 9c 17 00 00       	call   80105a5f <memcmp>
801042c3:	85 c0                	test   %eax,%eax
801042c5:	74 07                	je     801042ce <mpconfig+0x5f>
    return 0;
801042c7:	b8 00 00 00 00       	mov    $0x0,%eax
801042cc:	eb 4c                	jmp    8010431a <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d1:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042d5:	3c 01                	cmp    $0x1,%al
801042d7:	74 12                	je     801042eb <mpconfig+0x7c>
801042d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042dc:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042e0:	3c 04                	cmp    $0x4,%al
801042e2:	74 07                	je     801042eb <mpconfig+0x7c>
    return 0;
801042e4:	b8 00 00 00 00       	mov    $0x0,%eax
801042e9:	eb 2f                	jmp    8010431a <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042ee:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042f2:	0f b7 c0             	movzwl %ax,%eax
801042f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801042f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042fc:	89 04 24             	mov    %eax,(%esp)
801042ff:	e8 04 fe ff ff       	call   80104108 <sum>
80104304:	84 c0                	test   %al,%al
80104306:	74 07                	je     8010430f <mpconfig+0xa0>
    return 0;
80104308:	b8 00 00 00 00       	mov    $0x0,%eax
8010430d:	eb 0b                	jmp    8010431a <mpconfig+0xab>
  *pmp = mp;
8010430f:	8b 45 08             	mov    0x8(%ebp),%eax
80104312:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104315:	89 10                	mov    %edx,(%eax)
  return conf;
80104317:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010431a:	c9                   	leave  
8010431b:	c3                   	ret    

8010431c <mpinit>:

void
mpinit(void)
{
8010431c:	55                   	push   %ebp
8010431d:	89 e5                	mov    %esp,%ebp
8010431f:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104322:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
80104329:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
8010432c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010432f:	89 04 24             	mov    %eax,(%esp)
80104332:	e8 38 ff ff ff       	call   8010426f <mpconfig>
80104337:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010433a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010433e:	75 05                	jne    80104345 <mpinit+0x29>
    return;
80104340:	e9 9c 01 00 00       	jmp    801044e1 <mpinit+0x1c5>
  ismp = 1;
80104345:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
8010434c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010434f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104352:	8b 40 24             	mov    0x24(%eax),%eax
80104355:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010435a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010435d:	83 c0 2c             	add    $0x2c,%eax
80104360:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104363:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104366:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010436a:	0f b7 d0             	movzwl %ax,%edx
8010436d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104370:	01 d0                	add    %edx,%eax
80104372:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104375:	e9 f4 00 00 00       	jmp    8010446e <mpinit+0x152>
    switch(*p){
8010437a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437d:	0f b6 00             	movzbl (%eax),%eax
80104380:	0f b6 c0             	movzbl %al,%eax
80104383:	83 f8 04             	cmp    $0x4,%eax
80104386:	0f 87 bf 00 00 00    	ja     8010444b <mpinit+0x12f>
8010438c:	8b 04 85 ec 9f 10 80 	mov    -0x7fef6014(,%eax,4),%eax
80104393:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104398:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010439b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010439e:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043a2:	0f b6 d0             	movzbl %al,%edx
801043a5:	a1 40 49 11 80       	mov    0x80114940,%eax
801043aa:	39 c2                	cmp    %eax,%edx
801043ac:	74 2d                	je     801043db <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801043ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043b1:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043b5:	0f b6 d0             	movzbl %al,%edx
801043b8:	a1 40 49 11 80       	mov    0x80114940,%eax
801043bd:	89 54 24 08          	mov    %edx,0x8(%esp)
801043c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801043c5:	c7 04 24 ae 9f 10 80 	movl   $0x80109fae,(%esp)
801043cc:	e8 cf bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043d1:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043d8:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043db:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043de:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043e2:	0f b6 c0             	movzbl %al,%eax
801043e5:	83 e0 02             	and    $0x2,%eax
801043e8:	85 c0                	test   %eax,%eax
801043ea:	74 15                	je     80104401 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801043ec:	a1 40 49 11 80       	mov    0x80114940,%eax
801043f1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801043f7:	05 60 43 11 80       	add    $0x80114360,%eax
801043fc:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
80104401:	8b 15 40 49 11 80    	mov    0x80114940,%edx
80104407:	a1 40 49 11 80       	mov    0x80114940,%eax
8010440c:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104412:	81 c2 60 43 11 80    	add    $0x80114360,%edx
80104418:	88 02                	mov    %al,(%edx)
      ncpu++;
8010441a:	a1 40 49 11 80       	mov    0x80114940,%eax
8010441f:	83 c0 01             	add    $0x1,%eax
80104422:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
80104427:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
8010442b:	eb 41                	jmp    8010446e <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010442d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104430:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104433:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104436:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010443a:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
8010443f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104443:	eb 29                	jmp    8010446e <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104445:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104449:	eb 23                	jmp    8010446e <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
8010444b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444e:	0f b6 00             	movzbl (%eax),%eax
80104451:	0f b6 c0             	movzbl %al,%eax
80104454:	89 44 24 04          	mov    %eax,0x4(%esp)
80104458:	c7 04 24 cc 9f 10 80 	movl   $0x80109fcc,(%esp)
8010445f:	e8 3c bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104464:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
8010446b:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010446e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104471:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104474:	0f 82 00 ff ff ff    	jb     8010437a <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
8010447a:	a1 44 43 11 80       	mov    0x80114344,%eax
8010447f:	85 c0                	test   %eax,%eax
80104481:	75 1d                	jne    801044a0 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104483:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
8010448a:	00 00 00 
    lapic = 0;
8010448d:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
80104494:	00 00 00 
    ioapicid = 0;
80104497:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
8010449e:	eb 41                	jmp    801044e1 <mpinit+0x1c5>
  }

  if(mp->imcrp){
801044a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044a3:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801044a7:	84 c0                	test   %al,%al
801044a9:	74 36                	je     801044e1 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801044ab:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801044b2:	00 
801044b3:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801044ba:	e8 0d fc ff ff       	call   801040cc <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044bf:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044c6:	e8 e4 fb ff ff       	call   801040af <inb>
801044cb:	83 c8 01             	or     $0x1,%eax
801044ce:	0f b6 c0             	movzbl %al,%eax
801044d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801044d5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044dc:	e8 eb fb ff ff       	call   801040cc <outb>
  }
}
801044e1:	c9                   	leave  
801044e2:	c3                   	ret    

801044e3 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044e3:	55                   	push   %ebp
801044e4:	89 e5                	mov    %esp,%ebp
801044e6:	83 ec 08             	sub    $0x8,%esp
801044e9:	8b 55 08             	mov    0x8(%ebp),%edx
801044ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801044ef:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044f3:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044f6:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801044fa:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801044fe:	ee                   	out    %al,(%dx)
}
801044ff:	c9                   	leave  
80104500:	c3                   	ret    

80104501 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104501:	55                   	push   %ebp
80104502:	89 e5                	mov    %esp,%ebp
80104504:	83 ec 0c             	sub    $0xc,%esp
80104507:	8b 45 08             	mov    0x8(%ebp),%eax
8010450a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010450e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104512:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
80104518:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010451c:	0f b6 c0             	movzbl %al,%eax
8010451f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104523:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010452a:	e8 b4 ff ff ff       	call   801044e3 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010452f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104533:	66 c1 e8 08          	shr    $0x8,%ax
80104537:	0f b6 c0             	movzbl %al,%eax
8010453a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010453e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104545:	e8 99 ff ff ff       	call   801044e3 <outb>
}
8010454a:	c9                   	leave  
8010454b:	c3                   	ret    

8010454c <picenable>:

void
picenable(int irq)
{
8010454c:	55                   	push   %ebp
8010454d:	89 e5                	mov    %esp,%ebp
8010454f:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104552:	8b 45 08             	mov    0x8(%ebp),%eax
80104555:	ba 01 00 00 00       	mov    $0x1,%edx
8010455a:	89 c1                	mov    %eax,%ecx
8010455c:	d3 e2                	shl    %cl,%edx
8010455e:	89 d0                	mov    %edx,%eax
80104560:	f7 d0                	not    %eax
80104562:	89 c2                	mov    %eax,%edx
80104564:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
8010456b:	21 d0                	and    %edx,%eax
8010456d:	0f b7 c0             	movzwl %ax,%eax
80104570:	89 04 24             	mov    %eax,(%esp)
80104573:	e8 89 ff ff ff       	call   80104501 <picsetmask>
}
80104578:	c9                   	leave  
80104579:	c3                   	ret    

8010457a <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010457a:	55                   	push   %ebp
8010457b:	89 e5                	mov    %esp,%ebp
8010457d:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104580:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104587:	00 
80104588:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010458f:	e8 4f ff ff ff       	call   801044e3 <outb>
  outb(IO_PIC2+1, 0xFF);
80104594:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010459b:	00 
8010459c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045a3:	e8 3b ff ff ff       	call   801044e3 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801045a8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045af:	00 
801045b0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045b7:	e8 27 ff ff ff       	call   801044e3 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045bc:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045c3:	00 
801045c4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045cb:	e8 13 ff ff ff       	call   801044e3 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045d0:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045d7:	00 
801045d8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045df:	e8 ff fe ff ff       	call   801044e3 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045e4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045eb:	00 
801045ec:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045f3:	e8 eb fe ff ff       	call   801044e3 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801045f8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045ff:	00 
80104600:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104607:	e8 d7 fe ff ff       	call   801044e3 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010460c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104613:	00 
80104614:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010461b:	e8 c3 fe ff ff       	call   801044e3 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104620:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104627:	00 
80104628:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010462f:	e8 af fe ff ff       	call   801044e3 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104634:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010463b:	00 
8010463c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104643:	e8 9b fe ff ff       	call   801044e3 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104648:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010464f:	00 
80104650:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104657:	e8 87 fe ff ff       	call   801044e3 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010465c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104663:	00 
80104664:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010466b:	e8 73 fe ff ff       	call   801044e3 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104670:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104677:	00 
80104678:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010467f:	e8 5f fe ff ff       	call   801044e3 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104684:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010468b:	00 
8010468c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104693:	e8 4b fe ff ff       	call   801044e3 <outb>

  if(irqmask != 0xFFFF)
80104698:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
8010469f:	66 83 f8 ff          	cmp    $0xffff,%ax
801046a3:	74 12                	je     801046b7 <picinit+0x13d>
    picsetmask(irqmask);
801046a5:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801046ac:	0f b7 c0             	movzwl %ax,%eax
801046af:	89 04 24             	mov    %eax,(%esp)
801046b2:	e8 4a fe ff ff       	call   80104501 <picsetmask>
}
801046b7:	c9                   	leave  
801046b8:	c3                   	ret    

801046b9 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801046b9:	55                   	push   %ebp
801046ba:	89 e5                	mov    %esp,%ebp
801046bc:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046bf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801046c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d2:	8b 10                	mov    (%eax),%edx
801046d4:	8b 45 08             	mov    0x8(%ebp),%eax
801046d7:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046d9:	e8 48 c9 ff ff       	call   80101026 <filealloc>
801046de:	8b 55 08             	mov    0x8(%ebp),%edx
801046e1:	89 02                	mov    %eax,(%edx)
801046e3:	8b 45 08             	mov    0x8(%ebp),%eax
801046e6:	8b 00                	mov    (%eax),%eax
801046e8:	85 c0                	test   %eax,%eax
801046ea:	0f 84 c8 00 00 00    	je     801047b8 <pipealloc+0xff>
801046f0:	e8 31 c9 ff ff       	call   80101026 <filealloc>
801046f5:	8b 55 0c             	mov    0xc(%ebp),%edx
801046f8:	89 02                	mov    %eax,(%edx)
801046fa:	8b 45 0c             	mov    0xc(%ebp),%eax
801046fd:	8b 00                	mov    (%eax),%eax
801046ff:	85 c0                	test   %eax,%eax
80104701:	0f 84 b1 00 00 00    	je     801047b8 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104707:	e8 37 eb ff ff       	call   80103243 <kalloc>
8010470c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010470f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104713:	75 05                	jne    8010471a <pipealloc+0x61>
    goto bad;
80104715:	e9 9e 00 00 00       	jmp    801047b8 <pipealloc+0xff>
  p->readopen = 1;
8010471a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471d:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104724:	00 00 00 
  p->writeopen = 1;
80104727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010472a:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104731:	00 00 00 
  p->nwrite = 0;
80104734:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104737:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010473e:	00 00 00 
  p->nread = 0;
80104741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104744:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010474b:	00 00 00 
  initlock(&p->lock, "pipe");
8010474e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104751:	c7 44 24 04 00 a0 10 	movl   $0x8010a000,0x4(%esp)
80104758:	80 
80104759:	89 04 24             	mov    %eax,(%esp)
8010475c:	e8 12 10 00 00       	call   80105773 <initlock>
  (*f0)->type = FD_PIPE;
80104761:	8b 45 08             	mov    0x8(%ebp),%eax
80104764:	8b 00                	mov    (%eax),%eax
80104766:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010476c:	8b 45 08             	mov    0x8(%ebp),%eax
8010476f:	8b 00                	mov    (%eax),%eax
80104771:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104775:	8b 45 08             	mov    0x8(%ebp),%eax
80104778:	8b 00                	mov    (%eax),%eax
8010477a:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010477e:	8b 45 08             	mov    0x8(%ebp),%eax
80104781:	8b 00                	mov    (%eax),%eax
80104783:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104786:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104789:	8b 45 0c             	mov    0xc(%ebp),%eax
8010478c:	8b 00                	mov    (%eax),%eax
8010478e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104794:	8b 45 0c             	mov    0xc(%ebp),%eax
80104797:	8b 00                	mov    (%eax),%eax
80104799:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010479d:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a0:	8b 00                	mov    (%eax),%eax
801047a2:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801047a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a9:	8b 00                	mov    (%eax),%eax
801047ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047ae:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801047b1:	b8 00 00 00 00       	mov    $0x0,%eax
801047b6:	eb 42                	jmp    801047fa <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801047b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047bc:	74 0b                	je     801047c9 <pipealloc+0x110>
    kfree((char*)p);
801047be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c1:	89 04 24             	mov    %eax,(%esp)
801047c4:	e8 9d e9 ff ff       	call   80103166 <kfree>
  if(*f0)
801047c9:	8b 45 08             	mov    0x8(%ebp),%eax
801047cc:	8b 00                	mov    (%eax),%eax
801047ce:	85 c0                	test   %eax,%eax
801047d0:	74 0d                	je     801047df <pipealloc+0x126>
    fileclose(*f0);
801047d2:	8b 45 08             	mov    0x8(%ebp),%eax
801047d5:	8b 00                	mov    (%eax),%eax
801047d7:	89 04 24             	mov    %eax,(%esp)
801047da:	e8 ef c8 ff ff       	call   801010ce <fileclose>
  if(*f1)
801047df:	8b 45 0c             	mov    0xc(%ebp),%eax
801047e2:	8b 00                	mov    (%eax),%eax
801047e4:	85 c0                	test   %eax,%eax
801047e6:	74 0d                	je     801047f5 <pipealloc+0x13c>
    fileclose(*f1);
801047e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801047eb:	8b 00                	mov    (%eax),%eax
801047ed:	89 04 24             	mov    %eax,(%esp)
801047f0:	e8 d9 c8 ff ff       	call   801010ce <fileclose>
  return -1;
801047f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801047fa:	c9                   	leave  
801047fb:	c3                   	ret    

801047fc <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801047fc:	55                   	push   %ebp
801047fd:	89 e5                	mov    %esp,%ebp
801047ff:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104802:	8b 45 08             	mov    0x8(%ebp),%eax
80104805:	89 04 24             	mov    %eax,(%esp)
80104808:	e8 87 0f 00 00       	call   80105794 <acquire>
  if(writable){
8010480d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104811:	74 1f                	je     80104832 <pipeclose+0x36>
    p->writeopen = 0;
80104813:	8b 45 08             	mov    0x8(%ebp),%eax
80104816:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010481d:	00 00 00 
    wakeup(&p->nread);
80104820:	8b 45 08             	mov    0x8(%ebp),%eax
80104823:	05 34 02 00 00       	add    $0x234,%eax
80104828:	89 04 24             	mov    %eax,(%esp)
8010482b:	e8 fc 0c 00 00       	call   8010552c <wakeup>
80104830:	eb 1d                	jmp    8010484f <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104832:	8b 45 08             	mov    0x8(%ebp),%eax
80104835:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010483c:	00 00 00 
    wakeup(&p->nwrite);
8010483f:	8b 45 08             	mov    0x8(%ebp),%eax
80104842:	05 38 02 00 00       	add    $0x238,%eax
80104847:	89 04 24             	mov    %eax,(%esp)
8010484a:	e8 dd 0c 00 00       	call   8010552c <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010484f:	8b 45 08             	mov    0x8(%ebp),%eax
80104852:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104858:	85 c0                	test   %eax,%eax
8010485a:	75 25                	jne    80104881 <pipeclose+0x85>
8010485c:	8b 45 08             	mov    0x8(%ebp),%eax
8010485f:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104865:	85 c0                	test   %eax,%eax
80104867:	75 18                	jne    80104881 <pipeclose+0x85>
    release(&p->lock);
80104869:	8b 45 08             	mov    0x8(%ebp),%eax
8010486c:	89 04 24             	mov    %eax,(%esp)
8010486f:	e8 82 0f 00 00       	call   801057f6 <release>
    kfree((char*)p);
80104874:	8b 45 08             	mov    0x8(%ebp),%eax
80104877:	89 04 24             	mov    %eax,(%esp)
8010487a:	e8 e7 e8 ff ff       	call   80103166 <kfree>
8010487f:	eb 0b                	jmp    8010488c <pipeclose+0x90>
  } else
    release(&p->lock);
80104881:	8b 45 08             	mov    0x8(%ebp),%eax
80104884:	89 04 24             	mov    %eax,(%esp)
80104887:	e8 6a 0f 00 00       	call   801057f6 <release>
}
8010488c:	c9                   	leave  
8010488d:	c3                   	ret    

8010488e <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010488e:	55                   	push   %ebp
8010488f:	89 e5                	mov    %esp,%ebp
80104891:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104894:	8b 45 08             	mov    0x8(%ebp),%eax
80104897:	89 04 24             	mov    %eax,(%esp)
8010489a:	e8 f5 0e 00 00       	call   80105794 <acquire>
  for(i = 0; i < n; i++){
8010489f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801048a6:	e9 a6 00 00 00       	jmp    80104951 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048ab:	eb 57                	jmp    80104904 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801048ad:	8b 45 08             	mov    0x8(%ebp),%eax
801048b0:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048b6:	85 c0                	test   %eax,%eax
801048b8:	74 0d                	je     801048c7 <pipewrite+0x39>
801048ba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c0:	8b 40 24             	mov    0x24(%eax),%eax
801048c3:	85 c0                	test   %eax,%eax
801048c5:	74 15                	je     801048dc <pipewrite+0x4e>
        release(&p->lock);
801048c7:	8b 45 08             	mov    0x8(%ebp),%eax
801048ca:	89 04 24             	mov    %eax,(%esp)
801048cd:	e8 24 0f 00 00       	call   801057f6 <release>
        return -1;
801048d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048d7:	e9 9f 00 00 00       	jmp    8010497b <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048dc:	8b 45 08             	mov    0x8(%ebp),%eax
801048df:	05 34 02 00 00       	add    $0x234,%eax
801048e4:	89 04 24             	mov    %eax,(%esp)
801048e7:	e8 40 0c 00 00       	call   8010552c <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048ec:	8b 45 08             	mov    0x8(%ebp),%eax
801048ef:	8b 55 08             	mov    0x8(%ebp),%edx
801048f2:	81 c2 38 02 00 00    	add    $0x238,%edx
801048f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801048fc:	89 14 24             	mov    %edx,(%esp)
801048ff:	e8 4c 0b 00 00       	call   80105450 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104904:	8b 45 08             	mov    0x8(%ebp),%eax
80104907:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010490d:	8b 45 08             	mov    0x8(%ebp),%eax
80104910:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104916:	05 00 02 00 00       	add    $0x200,%eax
8010491b:	39 c2                	cmp    %eax,%edx
8010491d:	74 8e                	je     801048ad <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010491f:	8b 45 08             	mov    0x8(%ebp),%eax
80104922:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104928:	8d 48 01             	lea    0x1(%eax),%ecx
8010492b:	8b 55 08             	mov    0x8(%ebp),%edx
8010492e:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104934:	25 ff 01 00 00       	and    $0x1ff,%eax
80104939:	89 c1                	mov    %eax,%ecx
8010493b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010493e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104941:	01 d0                	add    %edx,%eax
80104943:	0f b6 10             	movzbl (%eax),%edx
80104946:	8b 45 08             	mov    0x8(%ebp),%eax
80104949:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010494d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104954:	3b 45 10             	cmp    0x10(%ebp),%eax
80104957:	0f 8c 4e ff ff ff    	jl     801048ab <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010495d:	8b 45 08             	mov    0x8(%ebp),%eax
80104960:	05 34 02 00 00       	add    $0x234,%eax
80104965:	89 04 24             	mov    %eax,(%esp)
80104968:	e8 bf 0b 00 00       	call   8010552c <wakeup>
  release(&p->lock);
8010496d:	8b 45 08             	mov    0x8(%ebp),%eax
80104970:	89 04 24             	mov    %eax,(%esp)
80104973:	e8 7e 0e 00 00       	call   801057f6 <release>
  return n;
80104978:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010497b:	c9                   	leave  
8010497c:	c3                   	ret    

8010497d <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010497d:	55                   	push   %ebp
8010497e:	89 e5                	mov    %esp,%ebp
80104980:	53                   	push   %ebx
80104981:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104984:	8b 45 08             	mov    0x8(%ebp),%eax
80104987:	89 04 24             	mov    %eax,(%esp)
8010498a:	e8 05 0e 00 00       	call   80105794 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010498f:	eb 3a                	jmp    801049cb <piperead+0x4e>
    if(proc->killed){
80104991:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104997:	8b 40 24             	mov    0x24(%eax),%eax
8010499a:	85 c0                	test   %eax,%eax
8010499c:	74 15                	je     801049b3 <piperead+0x36>
      release(&p->lock);
8010499e:	8b 45 08             	mov    0x8(%ebp),%eax
801049a1:	89 04 24             	mov    %eax,(%esp)
801049a4:	e8 4d 0e 00 00       	call   801057f6 <release>
      return -1;
801049a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049ae:	e9 b5 00 00 00       	jmp    80104a68 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801049b3:	8b 45 08             	mov    0x8(%ebp),%eax
801049b6:	8b 55 08             	mov    0x8(%ebp),%edx
801049b9:	81 c2 34 02 00 00    	add    $0x234,%edx
801049bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801049c3:	89 14 24             	mov    %edx,(%esp)
801049c6:	e8 85 0a 00 00       	call   80105450 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049cb:	8b 45 08             	mov    0x8(%ebp),%eax
801049ce:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049d4:	8b 45 08             	mov    0x8(%ebp),%eax
801049d7:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049dd:	39 c2                	cmp    %eax,%edx
801049df:	75 0d                	jne    801049ee <piperead+0x71>
801049e1:	8b 45 08             	mov    0x8(%ebp),%eax
801049e4:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049ea:	85 c0                	test   %eax,%eax
801049ec:	75 a3                	jne    80104991 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049f5:	eb 4b                	jmp    80104a42 <piperead+0xc5>
    if(p->nread == p->nwrite)
801049f7:	8b 45 08             	mov    0x8(%ebp),%eax
801049fa:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a00:	8b 45 08             	mov    0x8(%ebp),%eax
80104a03:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a09:	39 c2                	cmp    %eax,%edx
80104a0b:	75 02                	jne    80104a0f <piperead+0x92>
      break;
80104a0d:	eb 3b                	jmp    80104a4a <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104a0f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a12:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a15:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104a18:	8b 45 08             	mov    0x8(%ebp),%eax
80104a1b:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a21:	8d 48 01             	lea    0x1(%eax),%ecx
80104a24:	8b 55 08             	mov    0x8(%ebp),%edx
80104a27:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a2d:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a32:	89 c2                	mov    %eax,%edx
80104a34:	8b 45 08             	mov    0x8(%ebp),%eax
80104a37:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a3c:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a3e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a45:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a48:	7c ad                	jl     801049f7 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a4a:	8b 45 08             	mov    0x8(%ebp),%eax
80104a4d:	05 38 02 00 00       	add    $0x238,%eax
80104a52:	89 04 24             	mov    %eax,(%esp)
80104a55:	e8 d2 0a 00 00       	call   8010552c <wakeup>
  release(&p->lock);
80104a5a:	8b 45 08             	mov    0x8(%ebp),%eax
80104a5d:	89 04 24             	mov    %eax,(%esp)
80104a60:	e8 91 0d 00 00       	call   801057f6 <release>
  return i;
80104a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a68:	83 c4 24             	add    $0x24,%esp
80104a6b:	5b                   	pop    %ebx
80104a6c:	5d                   	pop    %ebp
80104a6d:	c3                   	ret    

80104a6e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a6e:	55                   	push   %ebp
80104a6f:	89 e5                	mov    %esp,%ebp
80104a71:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a74:	9c                   	pushf  
80104a75:	58                   	pop    %eax
80104a76:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a79:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a7c:	c9                   	leave  
80104a7d:	c3                   	ret    

80104a7e <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a7e:	55                   	push   %ebp
80104a7f:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a81:	fb                   	sti    
}
80104a82:	5d                   	pop    %ebp
80104a83:	c3                   	ret    

80104a84 <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a84:	55                   	push   %ebp
80104a85:	89 e5                	mov    %esp,%ebp
80104a87:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a8a:	c7 44 24 04 08 a0 10 	movl   $0x8010a008,0x4(%esp)
80104a91:	80 
80104a92:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104a99:	e8 d5 0c 00 00       	call   80105773 <initlock>
}
80104a9e:	c9                   	leave  
80104a9f:	c3                   	ret    

80104aa0 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104aa0:	55                   	push   %ebp
80104aa1:	89 e5                	mov    %esp,%ebp
80104aa3:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104aa6:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104aad:	e8 e2 0c 00 00       	call   80105794 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ab2:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104ab9:	eb 53                	jmp    80104b0e <allocproc+0x6e>
    if(p->state == UNUSED)
80104abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abe:	8b 40 0c             	mov    0xc(%eax),%eax
80104ac1:	85 c0                	test   %eax,%eax
80104ac3:	75 42                	jne    80104b07 <allocproc+0x67>
      goto found;
80104ac5:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac9:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104ad0:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104ad5:	8d 50 01             	lea    0x1(%eax),%edx
80104ad8:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104ade:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ae1:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104ae4:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104aeb:	e8 06 0d 00 00       	call   801057f6 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104af0:	e8 4e e7 ff ff       	call   80103243 <kalloc>
80104af5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104af8:	89 42 08             	mov    %eax,0x8(%edx)
80104afb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104afe:	8b 40 08             	mov    0x8(%eax),%eax
80104b01:	85 c0                	test   %eax,%eax
80104b03:	75 36                	jne    80104b3b <allocproc+0x9b>
80104b05:	eb 23                	jmp    80104b2a <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b07:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80104b0e:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80104b15:	72 a4                	jb     80104abb <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104b17:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b1e:	e8 d3 0c 00 00       	call   801057f6 <release>
    return 0;
80104b23:	b8 00 00 00 00       	mov    $0x0,%eax
80104b28:	eb 76                	jmp    80104ba0 <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b34:	b8 00 00 00 00       	mov    $0x0,%eax
80104b39:	eb 65                	jmp    80104ba0 <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b3e:	8b 40 08             	mov    0x8(%eax),%eax
80104b41:	05 00 10 00 00       	add    $0x1000,%eax
80104b46:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b49:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b50:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b53:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b56:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b5a:	ba 11 6e 10 80       	mov    $0x80106e11,%edx
80104b5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b62:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b64:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b6e:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b74:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b77:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b7e:	00 
80104b7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b86:	00 
80104b87:	89 04 24             	mov    %eax,(%esp)
80104b8a:	e8 59 0e 00 00       	call   801059e8 <memset>
    p->context->eip = (uint)forkret;
80104b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b92:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b95:	ba 11 54 10 80       	mov    $0x80105411,%edx
80104b9a:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104ba0:	c9                   	leave  
80104ba1:	c3                   	ret    

80104ba2 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104ba2:	55                   	push   %ebp
80104ba3:	89 e5                	mov    %esp,%ebp
80104ba5:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104ba8:	e8 f3 fe ff ff       	call   80104aa0 <allocproc>
80104bad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104bb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bb3:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104bba:	00 00 00 
    p->swapedPagesCounter = 0;
80104bbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc0:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104bc7:	00 00 00 
    p->pageFaultCounter = 0;
80104bca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bcd:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bd4:	00 00 00 
    p->swappedOutCounter = 0;
80104bd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bda:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104be1:	00 00 00 
    p->numOfPages = 0;
80104be4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be7:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104bee:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104bf1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104bf8:	e9 92 00 00 00       	jmp    80104c8f <userinit+0xed>
   	  p->pagesMetaData[i].count = 0;
80104bfd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c00:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c03:	89 d0                	mov    %edx,%eax
80104c05:	c1 e0 02             	shl    $0x2,%eax
80104c08:	01 d0                	add    %edx,%eax
80104c0a:	c1 e0 02             	shl    $0x2,%eax
80104c0d:	01 c8                	add    %ecx,%eax
80104c0f:	05 9c 00 00 00       	add    $0x9c,%eax
80104c14:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104c1a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c20:	89 d0                	mov    %edx,%eax
80104c22:	c1 e0 02             	shl    $0x2,%eax
80104c25:	01 d0                	add    %edx,%eax
80104c27:	c1 e0 02             	shl    $0x2,%eax
80104c2a:	01 c8                	add    %ecx,%eax
80104c2c:	05 90 00 00 00       	add    $0x90,%eax
80104c31:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c37:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c3a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c3d:	89 d0                	mov    %edx,%eax
80104c3f:	c1 e0 02             	shl    $0x2,%eax
80104c42:	01 d0                	add    %edx,%eax
80104c44:	c1 e0 02             	shl    $0x2,%eax
80104c47:	01 c8                	add    %ecx,%eax
80104c49:	05 94 00 00 00       	add    $0x94,%eax
80104c4e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c54:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c57:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c5a:	89 d0                	mov    %edx,%eax
80104c5c:	c1 e0 02             	shl    $0x2,%eax
80104c5f:	01 d0                	add    %edx,%eax
80104c61:	c1 e0 02             	shl    $0x2,%eax
80104c64:	01 c8                	add    %ecx,%eax
80104c66:	05 98 00 00 00       	add    $0x98,%eax
80104c6b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c71:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c77:	89 d0                	mov    %edx,%eax
80104c79:	c1 e0 02             	shl    $0x2,%eax
80104c7c:	01 d0                	add    %edx,%eax
80104c7e:	c1 e0 02             	shl    $0x2,%eax
80104c81:	01 c8                	add    %ecx,%eax
80104c83:	05 a0 00 00 00       	add    $0xa0,%eax
80104c88:	c6 00 80             	movb   $0x80,(%eax)
    p->pageFaultCounter = 0;
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c8b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c8f:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104c93:	0f 8e 64 ff ff ff    	jle    80104bfd <userinit+0x5b>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104c99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c9c:	a3 48 d6 10 80       	mov    %eax,0x8010d648
    if((p->pgdir = setupkvm()) == 0)
80104ca1:	e8 f7 38 00 00       	call   8010859d <setupkvm>
80104ca6:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ca9:	89 42 04             	mov    %eax,0x4(%edx)
80104cac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104caf:	8b 40 04             	mov    0x4(%eax),%eax
80104cb2:	85 c0                	test   %eax,%eax
80104cb4:	75 0c                	jne    80104cc2 <userinit+0x120>
      panic("userinit: out of memory?");
80104cb6:	c7 04 24 0f a0 10 80 	movl   $0x8010a00f,(%esp)
80104cbd:	e8 78 b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104cc2:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104cc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cca:	8b 40 04             	mov    0x4(%eax),%eax
80104ccd:	89 54 24 08          	mov    %edx,0x8(%esp)
80104cd1:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104cd8:	80 
80104cd9:	89 04 24             	mov    %eax,(%esp)
80104cdc:	e8 14 3b 00 00       	call   801087f5 <inituvm>
    p->sz = PGSIZE;
80104ce1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce4:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104cea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ced:	8b 40 18             	mov    0x18(%eax),%eax
80104cf0:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104cf7:	00 
80104cf8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cff:	00 
80104d00:	89 04 24             	mov    %eax,(%esp)
80104d03:	e8 e0 0c 00 00       	call   801059e8 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d0b:	8b 40 18             	mov    0x18(%eax),%eax
80104d0e:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104d14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d17:	8b 40 18             	mov    0x18(%eax),%eax
80104d1a:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104d20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d23:	8b 40 18             	mov    0x18(%eax),%eax
80104d26:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d29:	8b 52 18             	mov    0x18(%edx),%edx
80104d2c:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d30:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d37:	8b 40 18             	mov    0x18(%eax),%eax
80104d3a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d3d:	8b 52 18             	mov    0x18(%edx),%edx
80104d40:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d44:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d4b:	8b 40 18             	mov    0x18(%eax),%eax
80104d4e:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d58:	8b 40 18             	mov    0x18(%eax),%eax
80104d5b:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d65:	8b 40 18             	mov    0x18(%eax),%eax
80104d68:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d72:	83 c0 6c             	add    $0x6c,%eax
80104d75:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d7c:	00 
80104d7d:	c7 44 24 04 28 a0 10 	movl   $0x8010a028,0x4(%esp)
80104d84:	80 
80104d85:	89 04 24             	mov    %eax,(%esp)
80104d88:	e8 7b 0e 00 00       	call   80105c08 <safestrcpy>
  p->cwd = namei("/");
80104d8d:	c7 04 24 31 a0 10 80 	movl   $0x8010a031,(%esp)
80104d94:	e8 d1 d7 ff ff       	call   8010256a <namei>
80104d99:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d9c:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104d9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104da2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104da9:	e8 e2 e4 ff ff       	call   80103290 <countPages>
80104dae:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104db3:	a1 60 49 11 80       	mov    0x80114960,%eax
80104db8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dbc:	c7 04 24 33 a0 10 80 	movl   $0x8010a033,(%esp)
80104dc3:	e8 d8 b5 ff ff       	call   801003a0 <cprintf>
}
80104dc8:	c9                   	leave  
80104dc9:	c3                   	ret    

80104dca <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104dca:	55                   	push   %ebp
80104dcb:	89 e5                	mov    %esp,%ebp
80104dcd:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104dd0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dd6:	8b 00                	mov    (%eax),%eax
80104dd8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104ddb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104ddf:	7e 3f                	jle    80104e20 <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104de1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104de8:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dee:	01 c1                	add    %eax,%ecx
80104df0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104df6:	8b 40 04             	mov    0x4(%eax),%eax
80104df9:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104dfd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e01:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e04:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e08:	89 04 24             	mov    %eax,(%esp)
80104e0b:	e8 5b 3b 00 00       	call   8010896b <allocuvm>
80104e10:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e13:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e17:	75 4c                	jne    80104e65 <growproc+0x9b>
      return -1;
80104e19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e1e:	eb 63                	jmp    80104e83 <growproc+0xb9>
  } else if(n < 0){
80104e20:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e24:	79 3f                	jns    80104e65 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e26:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e2d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e33:	01 c1                	add    %eax,%ecx
80104e35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e3b:	8b 40 04             	mov    0x4(%eax),%eax
80104e3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e42:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e49:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e4d:	89 04 24             	mov    %eax,(%esp)
80104e50:	e8 4f 3d 00 00       	call   80108ba4 <deallocuvm>
80104e55:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e58:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e5c:	75 07                	jne    80104e65 <growproc+0x9b>
      return -1;
80104e5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e63:	eb 1e                	jmp    80104e83 <growproc+0xb9>
  }
  proc->sz = sz;
80104e65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e6b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e6e:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e76:	89 04 24             	mov    %eax,(%esp)
80104e79:	e8 10 38 00 00       	call   8010868e <switchuvm>
  return 0;
80104e7e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e83:	c9                   	leave  
80104e84:	c3                   	ret    

80104e85 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e85:	55                   	push   %ebp
80104e86:	89 e5                	mov    %esp,%ebp
80104e88:	57                   	push   %edi
80104e89:	56                   	push   %esi
80104e8a:	53                   	push   %ebx
80104e8b:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e8e:	e8 0d fc ff ff       	call   80104aa0 <allocproc>
80104e93:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104e96:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104e9a:	75 0a                	jne    80104ea6 <fork+0x21>
    return -1;
80104e9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ea1:	e9 93 01 00 00       	jmp    80105039 <fork+0x1b4>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104ea6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eac:	8b 10                	mov    (%eax),%edx
80104eae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb4:	8b 40 04             	mov    0x4(%eax),%eax
80104eb7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104eba:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ebe:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ec2:	89 04 24             	mov    %eax,(%esp)
80104ec5:	e8 03 40 00 00       	call   80108ecd <copyuvm>
80104eca:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ecd:	89 42 04             	mov    %eax,0x4(%edx)
80104ed0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ed3:	8b 40 04             	mov    0x4(%eax),%eax
80104ed6:	85 c0                	test   %eax,%eax
80104ed8:	75 2c                	jne    80104f06 <fork+0x81>
    kfree(np->kstack);
80104eda:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104edd:	8b 40 08             	mov    0x8(%eax),%eax
80104ee0:	89 04 24             	mov    %eax,(%esp)
80104ee3:	e8 7e e2 ff ff       	call   80103166 <kfree>
    np->kstack = 0;
80104ee8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eeb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104ef2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104efc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f01:	e9 33 01 00 00       	jmp    80105039 <fork+0x1b4>
  }
  np->sz = proc->sz;
80104f06:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f0c:	8b 10                	mov    (%eax),%edx
80104f0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f11:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f13:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f1d:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f20:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f23:	8b 50 18             	mov    0x18(%eax),%edx
80104f26:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f2c:	8b 40 18             	mov    0x18(%eax),%eax
80104f2f:	89 c3                	mov    %eax,%ebx
80104f31:	b8 13 00 00 00       	mov    $0x13,%eax
80104f36:	89 d7                	mov    %edx,%edi
80104f38:	89 de                	mov    %ebx,%esi
80104f3a:	89 c1                	mov    %eax,%ecx
80104f3c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f3e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f41:	8b 40 18             	mov    0x18(%eax),%eax
80104f44:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f4b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f52:	eb 3d                	jmp    80104f91 <fork+0x10c>
    if(proc->ofile[i])
80104f54:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f5a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f5d:	83 c2 08             	add    $0x8,%edx
80104f60:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f64:	85 c0                	test   %eax,%eax
80104f66:	74 25                	je     80104f8d <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f68:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f6e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f71:	83 c2 08             	add    $0x8,%edx
80104f74:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f78:	89 04 24             	mov    %eax,(%esp)
80104f7b:	e8 06 c1 ff ff       	call   80101086 <filedup>
80104f80:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f83:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f86:	83 c1 08             	add    $0x8,%ecx
80104f89:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f8d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f91:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f95:	7e bd                	jle    80104f54 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104f97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f9d:	8b 40 68             	mov    0x68(%eax),%eax
80104fa0:	89 04 24             	mov    %eax,(%esp)
80104fa3:	e8 df c9 ff ff       	call   80101987 <idup>
80104fa8:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104fab:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104fae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fb4:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fb7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fba:	83 c0 6c             	add    $0x6c,%eax
80104fbd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fc4:	00 
80104fc5:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fc9:	89 04 24             	mov    %eax,(%esp)
80104fcc:	e8 37 0c 00 00       	call   80105c08 <safestrcpy>

    pid = np->pid;
80104fd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd4:	8b 40 10             	mov    0x10(%eax),%eax
80104fd7:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->pageFaultCounter = 0;
80104fda:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fdd:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104fe4:	00 00 00 
    np->swappedOutCounter = 0;
80104fe7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fea:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104ff1:	00 00 00 
    createSwapFile(np);
80104ff4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ff7:	89 04 24             	mov    %eax,(%esp)
80104ffa:	e8 7c d8 ff ff       	call   8010287b <createSwapFile>
    copySwapFile(proc,np);
80104fff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105005:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105008:	89 54 24 04          	mov    %edx,0x4(%esp)
8010500c:	89 04 24             	mov    %eax,(%esp)
8010500f:	e8 9c d9 ff ff       	call   801029b0 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
80105014:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010501b:	e8 74 07 00 00       	call   80105794 <acquire>
    np->state = RUNNABLE;
80105020:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105023:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
8010502a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105031:	e8 c0 07 00 00       	call   801057f6 <release>

    return pid;
80105036:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
80105039:	83 c4 2c             	add    $0x2c,%esp
8010503c:	5b                   	pop    %ebx
8010503d:	5e                   	pop    %esi
8010503e:	5f                   	pop    %edi
8010503f:	5d                   	pop    %ebp
80105040:	c3                   	ret    

80105041 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105041:	55                   	push   %ebp
80105042:	89 e5                	mov    %esp,%ebp
80105044:	83 ec 28             	sub    $0x28,%esp
    procdump();
80105047:	e8 86 05 00 00       	call   801055d2 <procdump>
    struct proc *p;
    int fd;
    // #ifdef VERBOSE_PRINT
    // procdump();
    // #endif
    if(proc == initproc)
8010504c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105053:	a1 48 d6 10 80       	mov    0x8010d648,%eax
80105058:	39 c2                	cmp    %eax,%edx
8010505a:	75 0c                	jne    80105068 <exit+0x27>
      panic("init exiting");
8010505c:	c7 04 24 51 a0 10 80 	movl   $0x8010a051,(%esp)
80105063:	e8 d2 b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
80105068:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010506f:	eb 44                	jmp    801050b5 <exit+0x74>
      if(proc->ofile[fd]){
80105071:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105077:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010507a:	83 c2 08             	add    $0x8,%edx
8010507d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105081:	85 c0                	test   %eax,%eax
80105083:	74 2c                	je     801050b1 <exit+0x70>
        fileclose(proc->ofile[fd]);
80105085:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010508b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010508e:	83 c2 08             	add    $0x8,%edx
80105091:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105095:	89 04 24             	mov    %eax,(%esp)
80105098:	e8 31 c0 ff ff       	call   801010ce <fileclose>
        proc->ofile[fd] = 0;
8010509d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050a3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050a6:	83 c2 08             	add    $0x8,%edx
801050a9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801050b0:	00 
    // #endif
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050b1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050b5:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801050b9:	7e b6                	jle    80105071 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
801050bb:	e8 ed ea ff ff       	call   80103bad <begin_op>
    iput(proc->cwd);
801050c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050c6:	8b 40 68             	mov    0x68(%eax),%eax
801050c9:	89 04 24             	mov    %eax,(%esp)
801050cc:	e8 a1 ca ff ff       	call   80101b72 <iput>
    end_op();
801050d1:	e8 5b eb ff ff       	call   80103c31 <end_op>
    proc->cwd = 0;
801050d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050dc:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
801050e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e9:	89 04 24             	mov    %eax,(%esp)
801050ec:	e8 7e d5 ff ff       	call   8010266f <removeSwapFile>
    acquire(&ptable.lock);
801050f1:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801050f8:	e8 97 06 00 00       	call   80105794 <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
801050fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105103:	8b 40 14             	mov    0x14(%eax),%eax
80105106:	89 04 24             	mov    %eax,(%esp)
80105109:	e8 dd 03 00 00       	call   801054eb <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010510e:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105115:	eb 3b                	jmp    80105152 <exit+0x111>
      if(p->parent == proc){
80105117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010511a:	8b 50 14             	mov    0x14(%eax),%edx
8010511d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105123:	39 c2                	cmp    %eax,%edx
80105125:	75 24                	jne    8010514b <exit+0x10a>
        p->parent = initproc;
80105127:	8b 15 48 d6 10 80    	mov    0x8010d648,%edx
8010512d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105130:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
80105133:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105136:	8b 40 0c             	mov    0xc(%eax),%eax
80105139:	83 f8 05             	cmp    $0x5,%eax
8010513c:	75 0d                	jne    8010514b <exit+0x10a>
          wakeup1(initproc);
8010513e:	a1 48 d6 10 80       	mov    0x8010d648,%eax
80105143:	89 04 24             	mov    %eax,(%esp)
80105146:	e8 a0 03 00 00       	call   801054eb <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010514b:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105152:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105159:	72 bc                	jb     80105117 <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
8010515b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105161:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
80105168:	e8 c0 01 00 00       	call   8010532d <sched>
    panic("zombie exit");
8010516d:	c7 04 24 5e a0 10 80 	movl   $0x8010a05e,(%esp)
80105174:	e8 c1 b3 ff ff       	call   8010053a <panic>

80105179 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
80105179:	55                   	push   %ebp
8010517a:	89 e5                	mov    %esp,%ebp
8010517c:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
8010517f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105186:	e8 09 06 00 00       	call   80105794 <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
8010518b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105192:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105199:	e9 a4 00 00 00       	jmp    80105242 <wait+0xc9>
        if(p->parent != proc)
8010519e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a1:	8b 50 14             	mov    0x14(%eax),%edx
801051a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051aa:	39 c2                	cmp    %eax,%edx
801051ac:	74 05                	je     801051b3 <wait+0x3a>
          continue;
801051ae:	e9 88 00 00 00       	jmp    8010523b <wait+0xc2>
        havekids = 1;
801051b3:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
801051ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051bd:	8b 40 0c             	mov    0xc(%eax),%eax
801051c0:	83 f8 05             	cmp    $0x5,%eax
801051c3:	75 76                	jne    8010523b <wait+0xc2>
        // Found one.
          pid = p->pid;
801051c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051c8:	8b 40 10             	mov    0x10(%eax),%eax
801051cb:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801051ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d1:	8b 40 08             	mov    0x8(%eax),%eax
801051d4:	89 04 24             	mov    %eax,(%esp)
801051d7:	e8 8a df ff ff       	call   80103166 <kfree>
          p->kstack = 0;
801051dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051df:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
801051e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051e9:	8b 40 04             	mov    0x4(%eax),%eax
801051ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801051ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801051f3:	89 04 24             	mov    %eax,(%esp)
801051f6:	e8 e8 3b 00 00       	call   80108de3 <freevm>
          p->state = UNUSED;
801051fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051fe:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
80105205:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105208:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
8010520f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105212:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
80105219:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010521c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105220:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105223:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
8010522a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105231:	e8 c0 05 00 00       	call   801057f6 <release>
          return pid;
80105236:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105239:	eb 55                	jmp    80105290 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010523b:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105242:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105249:	0f 82 4f ff ff ff    	jb     8010519e <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
8010524f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105253:	74 0d                	je     80105262 <wait+0xe9>
80105255:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010525b:	8b 40 24             	mov    0x24(%eax),%eax
8010525e:	85 c0                	test   %eax,%eax
80105260:	74 13                	je     80105275 <wait+0xfc>
        release(&ptable.lock);
80105262:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105269:	e8 88 05 00 00       	call   801057f6 <release>
        return -1;
8010526e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105273:	eb 1b                	jmp    80105290 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105275:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010527b:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
80105282:	80 
80105283:	89 04 24             	mov    %eax,(%esp)
80105286:	e8 c5 01 00 00       	call   80105450 <sleep>
  }
8010528b:	e9 fb fe ff ff       	jmp    8010518b <wait+0x12>
}
80105290:	c9                   	leave  
80105291:	c3                   	ret    

80105292 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105292:	55                   	push   %ebp
80105293:	89 e5                	mov    %esp,%ebp
80105295:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105298:	e8 e1 f7 ff ff       	call   80104a7e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010529d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052a4:	e8 eb 04 00 00       	call   80105794 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052a9:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801052b0:	eb 61                	jmp    80105313 <scheduler+0x81>
      if(p->state != RUNNABLE)
801052b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b5:	8b 40 0c             	mov    0xc(%eax),%eax
801052b8:	83 f8 03             	cmp    $0x3,%eax
801052bb:	74 02                	je     801052bf <scheduler+0x2d>
        continue;
801052bd:	eb 4d                	jmp    8010530c <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c2:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052cb:	89 04 24             	mov    %eax,(%esp)
801052ce:	e8 bb 33 00 00       	call   8010868e <switchuvm>
      p->state = RUNNING;
801052d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d6:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e3:	8b 40 1c             	mov    0x1c(%eax),%eax
801052e6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801052ed:	83 c2 04             	add    $0x4,%edx
801052f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801052f4:	89 14 24             	mov    %edx,(%esp)
801052f7:	e8 7d 09 00 00       	call   80105c79 <swtch>
      switchkvm();
801052fc:	e8 70 33 00 00       	call   80108671 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105301:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105308:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010530c:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105313:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
8010531a:	72 96                	jb     801052b2 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010531c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105323:	e8 ce 04 00 00       	call   801057f6 <release>

  }
80105328:	e9 6b ff ff ff       	jmp    80105298 <scheduler+0x6>

8010532d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010532d:	55                   	push   %ebp
8010532e:	89 e5                	mov    %esp,%ebp
80105330:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105333:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010533a:	e8 7f 05 00 00       	call   801058be <holding>
8010533f:	85 c0                	test   %eax,%eax
80105341:	75 0c                	jne    8010534f <sched+0x22>
    panic("sched ptable.lock");
80105343:	c7 04 24 6a a0 10 80 	movl   $0x8010a06a,(%esp)
8010534a:	e8 eb b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
8010534f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105355:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010535b:	83 f8 01             	cmp    $0x1,%eax
8010535e:	74 0c                	je     8010536c <sched+0x3f>
    panic("sched locks");
80105360:	c7 04 24 7c a0 10 80 	movl   $0x8010a07c,(%esp)
80105367:	e8 ce b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
8010536c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105372:	8b 40 0c             	mov    0xc(%eax),%eax
80105375:	83 f8 04             	cmp    $0x4,%eax
80105378:	75 0c                	jne    80105386 <sched+0x59>
    panic("sched running");
8010537a:	c7 04 24 88 a0 10 80 	movl   $0x8010a088,(%esp)
80105381:	e8 b4 b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80105386:	e8 e3 f6 ff ff       	call   80104a6e <readeflags>
8010538b:	25 00 02 00 00       	and    $0x200,%eax
80105390:	85 c0                	test   %eax,%eax
80105392:	74 0c                	je     801053a0 <sched+0x73>
    panic("sched interruptible");
80105394:	c7 04 24 96 a0 10 80 	movl   $0x8010a096,(%esp)
8010539b:	e8 9a b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801053a0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053a6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053af:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053b5:	8b 40 04             	mov    0x4(%eax),%eax
801053b8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053bf:	83 c2 1c             	add    $0x1c,%edx
801053c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801053c6:	89 14 24             	mov    %edx,(%esp)
801053c9:	e8 ab 08 00 00       	call   80105c79 <swtch>
  cpu->intena = intena;
801053ce:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053d7:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053dd:	c9                   	leave  
801053de:	c3                   	ret    

801053df <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053df:	55                   	push   %ebp
801053e0:	89 e5                	mov    %esp,%ebp
801053e2:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801053e5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801053ec:	e8 a3 03 00 00       	call   80105794 <acquire>
  proc->state = RUNNABLE;
801053f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053f7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801053fe:	e8 2a ff ff ff       	call   8010532d <sched>
  release(&ptable.lock);
80105403:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010540a:	e8 e7 03 00 00       	call   801057f6 <release>
}
8010540f:	c9                   	leave  
80105410:	c3                   	ret    

80105411 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105411:	55                   	push   %ebp
80105412:	89 e5                	mov    %esp,%ebp
80105414:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105417:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010541e:	e8 d3 03 00 00       	call   801057f6 <release>

  if (first) {
80105423:	a1 08 d0 10 80       	mov    0x8010d008,%eax
80105428:	85 c0                	test   %eax,%eax
8010542a:	74 22                	je     8010544e <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010542c:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
80105433:	00 00 00 
    iinit(ROOTDEV);
80105436:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010543d:	e8 4f c2 ff ff       	call   80101691 <iinit>
    initlog(ROOTDEV);
80105442:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105449:	e8 5b e5 ff ff       	call   801039a9 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010544e:	c9                   	leave  
8010544f:	c3                   	ret    

80105450 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105450:	55                   	push   %ebp
80105451:	89 e5                	mov    %esp,%ebp
80105453:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105456:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010545c:	85 c0                	test   %eax,%eax
8010545e:	75 0c                	jne    8010546c <sleep+0x1c>
    panic("sleep");
80105460:	c7 04 24 aa a0 10 80 	movl   $0x8010a0aa,(%esp)
80105467:	e8 ce b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
8010546c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105470:	75 0c                	jne    8010547e <sleep+0x2e>
    panic("sleep without lk");
80105472:	c7 04 24 b0 a0 10 80 	movl   $0x8010a0b0,(%esp)
80105479:	e8 bc b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010547e:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
80105485:	74 17                	je     8010549e <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105487:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010548e:	e8 01 03 00 00       	call   80105794 <acquire>
    release(lk);
80105493:	8b 45 0c             	mov    0xc(%ebp),%eax
80105496:	89 04 24             	mov    %eax,(%esp)
80105499:	e8 58 03 00 00       	call   801057f6 <release>
  }

  // Go to sleep.
  proc->chan = chan;
8010549e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054a4:	8b 55 08             	mov    0x8(%ebp),%edx
801054a7:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b0:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054b7:	e8 71 fe ff ff       	call   8010532d <sched>

  // Tidy up.
  proc->chan = 0;
801054bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c2:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054c9:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054d0:	74 17                	je     801054e9 <sleep+0x99>
    release(&ptable.lock);
801054d2:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054d9:	e8 18 03 00 00       	call   801057f6 <release>
    acquire(lk);
801054de:	8b 45 0c             	mov    0xc(%ebp),%eax
801054e1:	89 04 24             	mov    %eax,(%esp)
801054e4:	e8 ab 02 00 00       	call   80105794 <acquire>
  }
}
801054e9:	c9                   	leave  
801054ea:	c3                   	ret    

801054eb <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801054eb:	55                   	push   %ebp
801054ec:	89 e5                	mov    %esp,%ebp
801054ee:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801054f1:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
801054f8:	eb 27                	jmp    80105521 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
801054fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054fd:	8b 40 0c             	mov    0xc(%eax),%eax
80105500:	83 f8 02             	cmp    $0x2,%eax
80105503:	75 15                	jne    8010551a <wakeup1+0x2f>
80105505:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105508:	8b 40 20             	mov    0x20(%eax),%eax
8010550b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010550e:	75 0a                	jne    8010551a <wakeup1+0x2f>
      p->state = RUNNABLE;
80105510:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105513:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010551a:	81 45 fc ec 02 00 00 	addl   $0x2ec,-0x4(%ebp)
80105521:	81 7d fc b4 04 12 80 	cmpl   $0x801204b4,-0x4(%ebp)
80105528:	72 d0                	jb     801054fa <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
8010552a:	c9                   	leave  
8010552b:	c3                   	ret    

8010552c <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
8010552c:	55                   	push   %ebp
8010552d:	89 e5                	mov    %esp,%ebp
8010552f:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
80105532:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105539:	e8 56 02 00 00       	call   80105794 <acquire>
    wakeup1(chan);
8010553e:	8b 45 08             	mov    0x8(%ebp),%eax
80105541:	89 04 24             	mov    %eax,(%esp)
80105544:	e8 a2 ff ff ff       	call   801054eb <wakeup1>
    release(&ptable.lock);
80105549:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105550:	e8 a1 02 00 00       	call   801057f6 <release>
  }
80105555:	c9                   	leave  
80105556:	c3                   	ret    

80105557 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
80105557:	55                   	push   %ebp
80105558:	89 e5                	mov    %esp,%ebp
8010555a:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
8010555d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105564:	e8 2b 02 00 00       	call   80105794 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105569:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105570:	eb 44                	jmp    801055b6 <kill+0x5f>
      if(p->pid == pid){
80105572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105575:	8b 40 10             	mov    0x10(%eax),%eax
80105578:	3b 45 08             	cmp    0x8(%ebp),%eax
8010557b:	75 32                	jne    801055af <kill+0x58>
        p->killed = 1;
8010557d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105580:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
80105587:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558a:	8b 40 0c             	mov    0xc(%eax),%eax
8010558d:	83 f8 02             	cmp    $0x2,%eax
80105590:	75 0a                	jne    8010559c <kill+0x45>
          p->state = RUNNABLE;
80105592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105595:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
8010559c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055a3:	e8 4e 02 00 00       	call   801057f6 <release>
        return 0;
801055a8:	b8 00 00 00 00       	mov    $0x0,%eax
801055ad:	eb 21                	jmp    801055d0 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055af:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
801055b6:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
801055bd:	72 b3                	jb     80105572 <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801055bf:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055c6:	e8 2b 02 00 00       	call   801057f6 <release>
    return -1;
801055cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801055d0:	c9                   	leave  
801055d1:	c3                   	ret    

801055d2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801055d2:	55                   	push   %ebp
801055d3:	89 e5                	mov    %esp,%ebp
801055d5:	56                   	push   %esi
801055d6:	53                   	push   %ebx
801055d7:	83 ec 60             	sub    $0x60,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055da:	c7 45 f0 b4 49 11 80 	movl   $0x801149b4,-0x10(%ebp)
801055e1:	e9 24 01 00 00       	jmp    8010570a <procdump+0x138>
      if(p->state == UNUSED)
801055e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055e9:	8b 40 0c             	mov    0xc(%eax),%eax
801055ec:	85 c0                	test   %eax,%eax
801055ee:	75 05                	jne    801055f5 <procdump+0x23>
        continue;
801055f0:	e9 0e 01 00 00       	jmp    80105703 <procdump+0x131>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801055f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055f8:	8b 40 0c             	mov    0xc(%eax),%eax
801055fb:	83 f8 05             	cmp    $0x5,%eax
801055fe:	77 23                	ja     80105623 <procdump+0x51>
80105600:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105603:	8b 40 0c             	mov    0xc(%eax),%eax
80105606:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
8010560d:	85 c0                	test   %eax,%eax
8010560f:	74 12                	je     80105623 <procdump+0x51>
        state = states[p->state];
80105611:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105614:	8b 40 0c             	mov    0xc(%eax),%eax
80105617:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
8010561e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105621:	eb 07                	jmp    8010562a <procdump+0x58>
      else
        state = "???";
80105623:	c7 45 ec c1 a0 10 80 	movl   $0x8010a0c1,-0x14(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
8010562a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010562d:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
80105633:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105636:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
8010563c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010563f:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80105645:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105648:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
8010564e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105651:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80105657:	01 c6                	add    %eax,%esi
80105659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010565c:	8b 40 10             	mov    0x10(%eax),%eax
8010565f:	89 5c 24 18          	mov    %ebx,0x18(%esp)
80105663:	89 4c 24 14          	mov    %ecx,0x14(%esp)
80105667:	89 54 24 10          	mov    %edx,0x10(%esp)
8010566b:	89 74 24 0c          	mov    %esi,0xc(%esp)
8010566f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105672:	89 54 24 08          	mov    %edx,0x8(%esp)
80105676:	89 44 24 04          	mov    %eax,0x4(%esp)
8010567a:	c7 04 24 c5 a0 10 80 	movl   $0x8010a0c5,(%esp)
80105681:	e8 1a ad ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
80105686:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105689:	83 c0 6c             	add    $0x6c,%eax
8010568c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105690:	c7 04 24 d8 a0 10 80 	movl   $0x8010a0d8,(%esp)
80105697:	e8 04 ad ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
8010569c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010569f:	8b 40 0c             	mov    0xc(%eax),%eax
801056a2:	83 f8 02             	cmp    $0x2,%eax
801056a5:	75 50                	jne    801056f7 <procdump+0x125>
        getcallerpcs((uint*)p->context->ebp+2, pc);
801056a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056aa:	8b 40 1c             	mov    0x1c(%eax),%eax
801056ad:	8b 40 0c             	mov    0xc(%eax),%eax
801056b0:	83 c0 08             	add    $0x8,%eax
801056b3:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801056b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801056ba:	89 04 24             	mov    %eax,(%esp)
801056bd:	e8 83 01 00 00       	call   80105845 <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801056c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056c9:	eb 1b                	jmp    801056e6 <procdump+0x114>
          cprintf(" %p", pc[i]);
801056cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ce:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d6:	c7 04 24 db a0 10 80 	movl   $0x8010a0db,(%esp)
801056dd:	e8 be ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
801056e2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056e6:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801056ea:	7f 0b                	jg     801056f7 <procdump+0x125>
801056ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ef:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056f3:	85 c0                	test   %eax,%eax
801056f5:	75 d4                	jne    801056cb <procdump+0xf9>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
801056f7:	c7 04 24 df a0 10 80 	movl   $0x8010a0df,(%esp)
801056fe:	e8 9d ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105703:	81 45 f0 ec 02 00 00 	addl   $0x2ec,-0x10(%ebp)
8010570a:	81 7d f0 b4 04 12 80 	cmpl   $0x801204b4,-0x10(%ebp)
80105711:	0f 82 cf fe ff ff    	jb     801055e6 <procdump+0x14>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    //float fra = countPages()/numOfInitializedPages; 
    cprintf("%d %d free pages in the system\n",countPages(),numOfInitializedPages);
80105717:	8b 1d 60 49 11 80    	mov    0x80114960,%ebx
8010571d:	e8 6e db ff ff       	call   80103290 <countPages>
80105722:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80105726:	89 44 24 04          	mov    %eax,0x4(%esp)
8010572a:	c7 04 24 e4 a0 10 80 	movl   $0x8010a0e4,(%esp)
80105731:	e8 6a ac ff ff       	call   801003a0 <cprintf>
80105736:	83 c4 60             	add    $0x60,%esp
80105739:	5b                   	pop    %ebx
8010573a:	5e                   	pop    %esi
8010573b:	5d                   	pop    %ebp
8010573c:	c3                   	ret    

8010573d <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010573d:	55                   	push   %ebp
8010573e:	89 e5                	mov    %esp,%ebp
80105740:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105743:	9c                   	pushf  
80105744:	58                   	pop    %eax
80105745:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105748:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010574b:	c9                   	leave  
8010574c:	c3                   	ret    

8010574d <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010574d:	55                   	push   %ebp
8010574e:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105750:	fa                   	cli    
}
80105751:	5d                   	pop    %ebp
80105752:	c3                   	ret    

80105753 <sti>:

static inline void
sti(void)
{
80105753:	55                   	push   %ebp
80105754:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105756:	fb                   	sti    
}
80105757:	5d                   	pop    %ebp
80105758:	c3                   	ret    

80105759 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105759:	55                   	push   %ebp
8010575a:	89 e5                	mov    %esp,%ebp
8010575c:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010575f:	8b 55 08             	mov    0x8(%ebp),%edx
80105762:	8b 45 0c             	mov    0xc(%ebp),%eax
80105765:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105768:	f0 87 02             	lock xchg %eax,(%edx)
8010576b:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010576e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105771:	c9                   	leave  
80105772:	c3                   	ret    

80105773 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105773:	55                   	push   %ebp
80105774:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105776:	8b 45 08             	mov    0x8(%ebp),%eax
80105779:	8b 55 0c             	mov    0xc(%ebp),%edx
8010577c:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010577f:	8b 45 08             	mov    0x8(%ebp),%eax
80105782:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105788:	8b 45 08             	mov    0x8(%ebp),%eax
8010578b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105792:	5d                   	pop    %ebp
80105793:	c3                   	ret    

80105794 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105794:	55                   	push   %ebp
80105795:	89 e5                	mov    %esp,%ebp
80105797:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
8010579a:	e8 49 01 00 00       	call   801058e8 <pushcli>
  if(holding(lk))
8010579f:	8b 45 08             	mov    0x8(%ebp),%eax
801057a2:	89 04 24             	mov    %eax,(%esp)
801057a5:	e8 14 01 00 00       	call   801058be <holding>
801057aa:	85 c0                	test   %eax,%eax
801057ac:	74 0c                	je     801057ba <acquire+0x26>
    panic("acquire");
801057ae:	c7 04 24 2e a1 10 80 	movl   $0x8010a12e,(%esp)
801057b5:	e8 80 ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801057ba:	90                   	nop
801057bb:	8b 45 08             	mov    0x8(%ebp),%eax
801057be:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801057c5:	00 
801057c6:	89 04 24             	mov    %eax,(%esp)
801057c9:	e8 8b ff ff ff       	call   80105759 <xchg>
801057ce:	85 c0                	test   %eax,%eax
801057d0:	75 e9                	jne    801057bb <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801057d2:	8b 45 08             	mov    0x8(%ebp),%eax
801057d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801057dc:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801057df:	8b 45 08             	mov    0x8(%ebp),%eax
801057e2:	83 c0 0c             	add    $0xc,%eax
801057e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801057e9:	8d 45 08             	lea    0x8(%ebp),%eax
801057ec:	89 04 24             	mov    %eax,(%esp)
801057ef:	e8 51 00 00 00       	call   80105845 <getcallerpcs>
}
801057f4:	c9                   	leave  
801057f5:	c3                   	ret    

801057f6 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801057f6:	55                   	push   %ebp
801057f7:	89 e5                	mov    %esp,%ebp
801057f9:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801057fc:	8b 45 08             	mov    0x8(%ebp),%eax
801057ff:	89 04 24             	mov    %eax,(%esp)
80105802:	e8 b7 00 00 00       	call   801058be <holding>
80105807:	85 c0                	test   %eax,%eax
80105809:	75 0c                	jne    80105817 <release+0x21>
    panic("release");
8010580b:	c7 04 24 36 a1 10 80 	movl   $0x8010a136,(%esp)
80105812:	e8 23 ad ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105817:	8b 45 08             	mov    0x8(%ebp),%eax
8010581a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105821:	8b 45 08             	mov    0x8(%ebp),%eax
80105824:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
8010582b:	8b 45 08             	mov    0x8(%ebp),%eax
8010582e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105835:	00 
80105836:	89 04 24             	mov    %eax,(%esp)
80105839:	e8 1b ff ff ff       	call   80105759 <xchg>

  popcli();
8010583e:	e8 e9 00 00 00       	call   8010592c <popcli>
}
80105843:	c9                   	leave  
80105844:	c3                   	ret    

80105845 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105845:	55                   	push   %ebp
80105846:	89 e5                	mov    %esp,%ebp
80105848:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
8010584b:	8b 45 08             	mov    0x8(%ebp),%eax
8010584e:	83 e8 08             	sub    $0x8,%eax
80105851:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105854:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010585b:	eb 38                	jmp    80105895 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010585d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105861:	74 38                	je     8010589b <getcallerpcs+0x56>
80105863:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010586a:	76 2f                	jbe    8010589b <getcallerpcs+0x56>
8010586c:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105870:	74 29                	je     8010589b <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105872:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105875:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010587c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010587f:	01 c2                	add    %eax,%edx
80105881:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105884:	8b 40 04             	mov    0x4(%eax),%eax
80105887:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105889:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010588c:	8b 00                	mov    (%eax),%eax
8010588e:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105891:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105895:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105899:	7e c2                	jle    8010585d <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010589b:	eb 19                	jmp    801058b6 <getcallerpcs+0x71>
    pcs[i] = 0;
8010589d:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058a0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801058aa:	01 d0                	add    %edx,%eax
801058ac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058b2:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058b6:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058ba:	7e e1                	jle    8010589d <getcallerpcs+0x58>
    pcs[i] = 0;
}
801058bc:	c9                   	leave  
801058bd:	c3                   	ret    

801058be <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801058be:	55                   	push   %ebp
801058bf:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801058c1:	8b 45 08             	mov    0x8(%ebp),%eax
801058c4:	8b 00                	mov    (%eax),%eax
801058c6:	85 c0                	test   %eax,%eax
801058c8:	74 17                	je     801058e1 <holding+0x23>
801058ca:	8b 45 08             	mov    0x8(%ebp),%eax
801058cd:	8b 50 08             	mov    0x8(%eax),%edx
801058d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058d6:	39 c2                	cmp    %eax,%edx
801058d8:	75 07                	jne    801058e1 <holding+0x23>
801058da:	b8 01 00 00 00       	mov    $0x1,%eax
801058df:	eb 05                	jmp    801058e6 <holding+0x28>
801058e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058e6:	5d                   	pop    %ebp
801058e7:	c3                   	ret    

801058e8 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801058e8:	55                   	push   %ebp
801058e9:	89 e5                	mov    %esp,%ebp
801058eb:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801058ee:	e8 4a fe ff ff       	call   8010573d <readeflags>
801058f3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801058f6:	e8 52 fe ff ff       	call   8010574d <cli>
  if(cpu->ncli++ == 0)
801058fb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105902:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105908:	8d 48 01             	lea    0x1(%eax),%ecx
8010590b:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105911:	85 c0                	test   %eax,%eax
80105913:	75 15                	jne    8010592a <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105915:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010591b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010591e:	81 e2 00 02 00 00    	and    $0x200,%edx
80105924:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010592a:	c9                   	leave  
8010592b:	c3                   	ret    

8010592c <popcli>:

void
popcli(void)
{
8010592c:	55                   	push   %ebp
8010592d:	89 e5                	mov    %esp,%ebp
8010592f:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105932:	e8 06 fe ff ff       	call   8010573d <readeflags>
80105937:	25 00 02 00 00       	and    $0x200,%eax
8010593c:	85 c0                	test   %eax,%eax
8010593e:	74 0c                	je     8010594c <popcli+0x20>
    panic("popcli - interruptible");
80105940:	c7 04 24 3e a1 10 80 	movl   $0x8010a13e,(%esp)
80105947:	e8 ee ab ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
8010594c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105952:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105958:	83 ea 01             	sub    $0x1,%edx
8010595b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105961:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105967:	85 c0                	test   %eax,%eax
80105969:	79 0c                	jns    80105977 <popcli+0x4b>
    panic("popcli");
8010596b:	c7 04 24 55 a1 10 80 	movl   $0x8010a155,(%esp)
80105972:	e8 c3 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105977:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010597d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105983:	85 c0                	test   %eax,%eax
80105985:	75 15                	jne    8010599c <popcli+0x70>
80105987:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010598d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105993:	85 c0                	test   %eax,%eax
80105995:	74 05                	je     8010599c <popcli+0x70>
    sti();
80105997:	e8 b7 fd ff ff       	call   80105753 <sti>
}
8010599c:	c9                   	leave  
8010599d:	c3                   	ret    

8010599e <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010599e:	55                   	push   %ebp
8010599f:	89 e5                	mov    %esp,%ebp
801059a1:	57                   	push   %edi
801059a2:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801059a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059a6:	8b 55 10             	mov    0x10(%ebp),%edx
801059a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ac:	89 cb                	mov    %ecx,%ebx
801059ae:	89 df                	mov    %ebx,%edi
801059b0:	89 d1                	mov    %edx,%ecx
801059b2:	fc                   	cld    
801059b3:	f3 aa                	rep stos %al,%es:(%edi)
801059b5:	89 ca                	mov    %ecx,%edx
801059b7:	89 fb                	mov    %edi,%ebx
801059b9:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059bc:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059bf:	5b                   	pop    %ebx
801059c0:	5f                   	pop    %edi
801059c1:	5d                   	pop    %ebp
801059c2:	c3                   	ret    

801059c3 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801059c3:	55                   	push   %ebp
801059c4:	89 e5                	mov    %esp,%ebp
801059c6:	57                   	push   %edi
801059c7:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801059c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059cb:	8b 55 10             	mov    0x10(%ebp),%edx
801059ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801059d1:	89 cb                	mov    %ecx,%ebx
801059d3:	89 df                	mov    %ebx,%edi
801059d5:	89 d1                	mov    %edx,%ecx
801059d7:	fc                   	cld    
801059d8:	f3 ab                	rep stos %eax,%es:(%edi)
801059da:	89 ca                	mov    %ecx,%edx
801059dc:	89 fb                	mov    %edi,%ebx
801059de:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059e1:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059e4:	5b                   	pop    %ebx
801059e5:	5f                   	pop    %edi
801059e6:	5d                   	pop    %ebp
801059e7:	c3                   	ret    

801059e8 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801059e8:	55                   	push   %ebp
801059e9:	89 e5                	mov    %esp,%ebp
801059eb:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801059ee:	8b 45 08             	mov    0x8(%ebp),%eax
801059f1:	83 e0 03             	and    $0x3,%eax
801059f4:	85 c0                	test   %eax,%eax
801059f6:	75 49                	jne    80105a41 <memset+0x59>
801059f8:	8b 45 10             	mov    0x10(%ebp),%eax
801059fb:	83 e0 03             	and    $0x3,%eax
801059fe:	85 c0                	test   %eax,%eax
80105a00:	75 3f                	jne    80105a41 <memset+0x59>
    c &= 0xFF;
80105a02:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105a09:	8b 45 10             	mov    0x10(%ebp),%eax
80105a0c:	c1 e8 02             	shr    $0x2,%eax
80105a0f:	89 c2                	mov    %eax,%edx
80105a11:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a14:	c1 e0 18             	shl    $0x18,%eax
80105a17:	89 c1                	mov    %eax,%ecx
80105a19:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1c:	c1 e0 10             	shl    $0x10,%eax
80105a1f:	09 c1                	or     %eax,%ecx
80105a21:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a24:	c1 e0 08             	shl    $0x8,%eax
80105a27:	09 c8                	or     %ecx,%eax
80105a29:	0b 45 0c             	or     0xc(%ebp),%eax
80105a2c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a30:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a34:	8b 45 08             	mov    0x8(%ebp),%eax
80105a37:	89 04 24             	mov    %eax,(%esp)
80105a3a:	e8 84 ff ff ff       	call   801059c3 <stosl>
80105a3f:	eb 19                	jmp    80105a5a <memset+0x72>
  } else
    stosb(dst, c, n);
80105a41:	8b 45 10             	mov    0x10(%ebp),%eax
80105a44:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a48:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a52:	89 04 24             	mov    %eax,(%esp)
80105a55:	e8 44 ff ff ff       	call   8010599e <stosb>
  return dst;
80105a5a:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a5d:	c9                   	leave  
80105a5e:	c3                   	ret    

80105a5f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a5f:	55                   	push   %ebp
80105a60:	89 e5                	mov    %esp,%ebp
80105a62:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a65:	8b 45 08             	mov    0x8(%ebp),%eax
80105a68:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a6e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a71:	eb 30                	jmp    80105aa3 <memcmp+0x44>
    if(*s1 != *s2)
80105a73:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a76:	0f b6 10             	movzbl (%eax),%edx
80105a79:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a7c:	0f b6 00             	movzbl (%eax),%eax
80105a7f:	38 c2                	cmp    %al,%dl
80105a81:	74 18                	je     80105a9b <memcmp+0x3c>
      return *s1 - *s2;
80105a83:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a86:	0f b6 00             	movzbl (%eax),%eax
80105a89:	0f b6 d0             	movzbl %al,%edx
80105a8c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a8f:	0f b6 00             	movzbl (%eax),%eax
80105a92:	0f b6 c0             	movzbl %al,%eax
80105a95:	29 c2                	sub    %eax,%edx
80105a97:	89 d0                	mov    %edx,%eax
80105a99:	eb 1a                	jmp    80105ab5 <memcmp+0x56>
    s1++, s2++;
80105a9b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a9f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105aa3:	8b 45 10             	mov    0x10(%ebp),%eax
80105aa6:	8d 50 ff             	lea    -0x1(%eax),%edx
80105aa9:	89 55 10             	mov    %edx,0x10(%ebp)
80105aac:	85 c0                	test   %eax,%eax
80105aae:	75 c3                	jne    80105a73 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105ab0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ab5:	c9                   	leave  
80105ab6:	c3                   	ret    

80105ab7 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105ab7:	55                   	push   %ebp
80105ab8:	89 e5                	mov    %esp,%ebp
80105aba:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105abd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ac0:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105ac3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ac6:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105ac9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105acc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105acf:	73 3d                	jae    80105b0e <memmove+0x57>
80105ad1:	8b 45 10             	mov    0x10(%ebp),%eax
80105ad4:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ad7:	01 d0                	add    %edx,%eax
80105ad9:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105adc:	76 30                	jbe    80105b0e <memmove+0x57>
    s += n;
80105ade:	8b 45 10             	mov    0x10(%ebp),%eax
80105ae1:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105ae4:	8b 45 10             	mov    0x10(%ebp),%eax
80105ae7:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105aea:	eb 13                	jmp    80105aff <memmove+0x48>
      *--d = *--s;
80105aec:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105af0:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105af4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105af7:	0f b6 10             	movzbl (%eax),%edx
80105afa:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105afd:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105aff:	8b 45 10             	mov    0x10(%ebp),%eax
80105b02:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b05:	89 55 10             	mov    %edx,0x10(%ebp)
80105b08:	85 c0                	test   %eax,%eax
80105b0a:	75 e0                	jne    80105aec <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105b0c:	eb 26                	jmp    80105b34 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b0e:	eb 17                	jmp    80105b27 <memmove+0x70>
      *d++ = *s++;
80105b10:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b13:	8d 50 01             	lea    0x1(%eax),%edx
80105b16:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105b19:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b1c:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b1f:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105b22:	0f b6 12             	movzbl (%edx),%edx
80105b25:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b27:	8b 45 10             	mov    0x10(%ebp),%eax
80105b2a:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b2d:	89 55 10             	mov    %edx,0x10(%ebp)
80105b30:	85 c0                	test   %eax,%eax
80105b32:	75 dc                	jne    80105b10 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b34:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b37:	c9                   	leave  
80105b38:	c3                   	ret    

80105b39 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b39:	55                   	push   %ebp
80105b3a:	89 e5                	mov    %esp,%ebp
80105b3c:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b3f:	8b 45 10             	mov    0x10(%ebp),%eax
80105b42:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b46:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b49:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b4d:	8b 45 08             	mov    0x8(%ebp),%eax
80105b50:	89 04 24             	mov    %eax,(%esp)
80105b53:	e8 5f ff ff ff       	call   80105ab7 <memmove>
}
80105b58:	c9                   	leave  
80105b59:	c3                   	ret    

80105b5a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b5a:	55                   	push   %ebp
80105b5b:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b5d:	eb 0c                	jmp    80105b6b <strncmp+0x11>
    n--, p++, q++;
80105b5f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b63:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b67:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b6b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b6f:	74 1a                	je     80105b8b <strncmp+0x31>
80105b71:	8b 45 08             	mov    0x8(%ebp),%eax
80105b74:	0f b6 00             	movzbl (%eax),%eax
80105b77:	84 c0                	test   %al,%al
80105b79:	74 10                	je     80105b8b <strncmp+0x31>
80105b7b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b7e:	0f b6 10             	movzbl (%eax),%edx
80105b81:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b84:	0f b6 00             	movzbl (%eax),%eax
80105b87:	38 c2                	cmp    %al,%dl
80105b89:	74 d4                	je     80105b5f <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105b8b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b8f:	75 07                	jne    80105b98 <strncmp+0x3e>
    return 0;
80105b91:	b8 00 00 00 00       	mov    $0x0,%eax
80105b96:	eb 16                	jmp    80105bae <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105b98:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9b:	0f b6 00             	movzbl (%eax),%eax
80105b9e:	0f b6 d0             	movzbl %al,%edx
80105ba1:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ba4:	0f b6 00             	movzbl (%eax),%eax
80105ba7:	0f b6 c0             	movzbl %al,%eax
80105baa:	29 c2                	sub    %eax,%edx
80105bac:	89 d0                	mov    %edx,%eax
}
80105bae:	5d                   	pop    %ebp
80105baf:	c3                   	ret    

80105bb0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105bb0:	55                   	push   %ebp
80105bb1:	89 e5                	mov    %esp,%ebp
80105bb3:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105bb6:	8b 45 08             	mov    0x8(%ebp),%eax
80105bb9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105bbc:	90                   	nop
80105bbd:	8b 45 10             	mov    0x10(%ebp),%eax
80105bc0:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bc3:	89 55 10             	mov    %edx,0x10(%ebp)
80105bc6:	85 c0                	test   %eax,%eax
80105bc8:	7e 1e                	jle    80105be8 <strncpy+0x38>
80105bca:	8b 45 08             	mov    0x8(%ebp),%eax
80105bcd:	8d 50 01             	lea    0x1(%eax),%edx
80105bd0:	89 55 08             	mov    %edx,0x8(%ebp)
80105bd3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105bd6:	8d 4a 01             	lea    0x1(%edx),%ecx
80105bd9:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105bdc:	0f b6 12             	movzbl (%edx),%edx
80105bdf:	88 10                	mov    %dl,(%eax)
80105be1:	0f b6 00             	movzbl (%eax),%eax
80105be4:	84 c0                	test   %al,%al
80105be6:	75 d5                	jne    80105bbd <strncpy+0xd>
    ;
  while(n-- > 0)
80105be8:	eb 0c                	jmp    80105bf6 <strncpy+0x46>
    *s++ = 0;
80105bea:	8b 45 08             	mov    0x8(%ebp),%eax
80105bed:	8d 50 01             	lea    0x1(%eax),%edx
80105bf0:	89 55 08             	mov    %edx,0x8(%ebp)
80105bf3:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105bf6:	8b 45 10             	mov    0x10(%ebp),%eax
80105bf9:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bfc:	89 55 10             	mov    %edx,0x10(%ebp)
80105bff:	85 c0                	test   %eax,%eax
80105c01:	7f e7                	jg     80105bea <strncpy+0x3a>
    *s++ = 0;
  return os;
80105c03:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c06:	c9                   	leave  
80105c07:	c3                   	ret    

80105c08 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105c08:	55                   	push   %ebp
80105c09:	89 e5                	mov    %esp,%ebp
80105c0b:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c0e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c11:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105c14:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c18:	7f 05                	jg     80105c1f <safestrcpy+0x17>
    return os;
80105c1a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c1d:	eb 31                	jmp    80105c50 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105c1f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c23:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c27:	7e 1e                	jle    80105c47 <safestrcpy+0x3f>
80105c29:	8b 45 08             	mov    0x8(%ebp),%eax
80105c2c:	8d 50 01             	lea    0x1(%eax),%edx
80105c2f:	89 55 08             	mov    %edx,0x8(%ebp)
80105c32:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c35:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c38:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c3b:	0f b6 12             	movzbl (%edx),%edx
80105c3e:	88 10                	mov    %dl,(%eax)
80105c40:	0f b6 00             	movzbl (%eax),%eax
80105c43:	84 c0                	test   %al,%al
80105c45:	75 d8                	jne    80105c1f <safestrcpy+0x17>
    ;
  *s = 0;
80105c47:	8b 45 08             	mov    0x8(%ebp),%eax
80105c4a:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c4d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c50:	c9                   	leave  
80105c51:	c3                   	ret    

80105c52 <strlen>:

int
strlen(const char *s)
{
80105c52:	55                   	push   %ebp
80105c53:	89 e5                	mov    %esp,%ebp
80105c55:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c58:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c5f:	eb 04                	jmp    80105c65 <strlen+0x13>
80105c61:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c65:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c68:	8b 45 08             	mov    0x8(%ebp),%eax
80105c6b:	01 d0                	add    %edx,%eax
80105c6d:	0f b6 00             	movzbl (%eax),%eax
80105c70:	84 c0                	test   %al,%al
80105c72:	75 ed                	jne    80105c61 <strlen+0xf>
    ;
  return n;
80105c74:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c77:	c9                   	leave  
80105c78:	c3                   	ret    

80105c79 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c79:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c7d:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105c81:	55                   	push   %ebp
  pushl %ebx
80105c82:	53                   	push   %ebx
  pushl %esi
80105c83:	56                   	push   %esi
  pushl %edi
80105c84:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105c85:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105c87:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105c89:	5f                   	pop    %edi
  popl %esi
80105c8a:	5e                   	pop    %esi
  popl %ebx
80105c8b:	5b                   	pop    %ebx
  popl %ebp
80105c8c:	5d                   	pop    %ebp
  ret
80105c8d:	c3                   	ret    

80105c8e <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105c8e:	55                   	push   %ebp
80105c8f:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105c91:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c97:	8b 00                	mov    (%eax),%eax
80105c99:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c9c:	76 12                	jbe    80105cb0 <fetchint+0x22>
80105c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80105ca1:	8d 50 04             	lea    0x4(%eax),%edx
80105ca4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105caa:	8b 00                	mov    (%eax),%eax
80105cac:	39 c2                	cmp    %eax,%edx
80105cae:	76 07                	jbe    80105cb7 <fetchint+0x29>
    return -1;
80105cb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cb5:	eb 0f                	jmp    80105cc6 <fetchint+0x38>
  *ip = *(int*)(addr);
80105cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80105cba:	8b 10                	mov    (%eax),%edx
80105cbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cbf:	89 10                	mov    %edx,(%eax)
  return 0;
80105cc1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105cc6:	5d                   	pop    %ebp
80105cc7:	c3                   	ret    

80105cc8 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105cc8:	55                   	push   %ebp
80105cc9:	89 e5                	mov    %esp,%ebp
80105ccb:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105cce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cd4:	8b 00                	mov    (%eax),%eax
80105cd6:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cd9:	77 07                	ja     80105ce2 <fetchstr+0x1a>
    return -1;
80105cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ce0:	eb 46                	jmp    80105d28 <fetchstr+0x60>
  *pp = (char*)addr;
80105ce2:	8b 55 08             	mov    0x8(%ebp),%edx
80105ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce8:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105cea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf0:	8b 00                	mov    (%eax),%eax
80105cf2:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105cf5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cf8:	8b 00                	mov    (%eax),%eax
80105cfa:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105cfd:	eb 1c                	jmp    80105d1b <fetchstr+0x53>
    if(*s == 0)
80105cff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d02:	0f b6 00             	movzbl (%eax),%eax
80105d05:	84 c0                	test   %al,%al
80105d07:	75 0e                	jne    80105d17 <fetchstr+0x4f>
      return s - *pp;
80105d09:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d0f:	8b 00                	mov    (%eax),%eax
80105d11:	29 c2                	sub    %eax,%edx
80105d13:	89 d0                	mov    %edx,%eax
80105d15:	eb 11                	jmp    80105d28 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105d17:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d1e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d21:	72 dc                	jb     80105cff <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105d23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d28:	c9                   	leave  
80105d29:	c3                   	ret    

80105d2a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d2a:	55                   	push   %ebp
80105d2b:	89 e5                	mov    %esp,%ebp
80105d2d:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d36:	8b 40 18             	mov    0x18(%eax),%eax
80105d39:	8b 50 44             	mov    0x44(%eax),%edx
80105d3c:	8b 45 08             	mov    0x8(%ebp),%eax
80105d3f:	c1 e0 02             	shl    $0x2,%eax
80105d42:	01 d0                	add    %edx,%eax
80105d44:	8d 50 04             	lea    0x4(%eax),%edx
80105d47:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d4e:	89 14 24             	mov    %edx,(%esp)
80105d51:	e8 38 ff ff ff       	call   80105c8e <fetchint>
}
80105d56:	c9                   	leave  
80105d57:	c3                   	ret    

80105d58 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d58:	55                   	push   %ebp
80105d59:	89 e5                	mov    %esp,%ebp
80105d5b:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d5e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d61:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d65:	8b 45 08             	mov    0x8(%ebp),%eax
80105d68:	89 04 24             	mov    %eax,(%esp)
80105d6b:	e8 ba ff ff ff       	call   80105d2a <argint>
80105d70:	85 c0                	test   %eax,%eax
80105d72:	79 07                	jns    80105d7b <argptr+0x23>
    return -1;
80105d74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d79:	eb 3d                	jmp    80105db8 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d7b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d7e:	89 c2                	mov    %eax,%edx
80105d80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d86:	8b 00                	mov    (%eax),%eax
80105d88:	39 c2                	cmp    %eax,%edx
80105d8a:	73 16                	jae    80105da2 <argptr+0x4a>
80105d8c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d8f:	89 c2                	mov    %eax,%edx
80105d91:	8b 45 10             	mov    0x10(%ebp),%eax
80105d94:	01 c2                	add    %eax,%edx
80105d96:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d9c:	8b 00                	mov    (%eax),%eax
80105d9e:	39 c2                	cmp    %eax,%edx
80105da0:	76 07                	jbe    80105da9 <argptr+0x51>
    return -1;
80105da2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105da7:	eb 0f                	jmp    80105db8 <argptr+0x60>
  *pp = (char*)i;
80105da9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dac:	89 c2                	mov    %eax,%edx
80105dae:	8b 45 0c             	mov    0xc(%ebp),%eax
80105db1:	89 10                	mov    %edx,(%eax)
  return 0;
80105db3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105db8:	c9                   	leave  
80105db9:	c3                   	ret    

80105dba <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105dba:	55                   	push   %ebp
80105dbb:	89 e5                	mov    %esp,%ebp
80105dbd:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105dc0:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105dc3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dc7:	8b 45 08             	mov    0x8(%ebp),%eax
80105dca:	89 04 24             	mov    %eax,(%esp)
80105dcd:	e8 58 ff ff ff       	call   80105d2a <argint>
80105dd2:	85 c0                	test   %eax,%eax
80105dd4:	79 07                	jns    80105ddd <argstr+0x23>
    return -1;
80105dd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ddb:	eb 12                	jmp    80105def <argstr+0x35>
  return fetchstr(addr, pp);
80105ddd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105de0:	8b 55 0c             	mov    0xc(%ebp),%edx
80105de3:	89 54 24 04          	mov    %edx,0x4(%esp)
80105de7:	89 04 24             	mov    %eax,(%esp)
80105dea:	e8 d9 fe ff ff       	call   80105cc8 <fetchstr>
}
80105def:	c9                   	leave  
80105df0:	c3                   	ret    

80105df1 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105df1:	55                   	push   %ebp
80105df2:	89 e5                	mov    %esp,%ebp
80105df4:	53                   	push   %ebx
80105df5:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105df8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dfe:	8b 40 18             	mov    0x18(%eax),%eax
80105e01:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e04:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105e07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e0b:	7e 30                	jle    80105e3d <syscall+0x4c>
80105e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e10:	83 f8 15             	cmp    $0x15,%eax
80105e13:	77 28                	ja     80105e3d <syscall+0x4c>
80105e15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e18:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e1f:	85 c0                	test   %eax,%eax
80105e21:	74 1a                	je     80105e3d <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105e23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e29:	8b 58 18             	mov    0x18(%eax),%ebx
80105e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e2f:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e36:	ff d0                	call   *%eax
80105e38:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e3b:	eb 3d                	jmp    80105e7a <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e43:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e4c:	8b 40 10             	mov    0x10(%eax),%eax
80105e4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e52:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e56:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e5e:	c7 04 24 5c a1 10 80 	movl   $0x8010a15c,(%esp)
80105e65:	e8 36 a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e6a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e70:	8b 40 18             	mov    0x18(%eax),%eax
80105e73:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e7a:	83 c4 24             	add    $0x24,%esp
80105e7d:	5b                   	pop    %ebx
80105e7e:	5d                   	pop    %ebp
80105e7f:	c3                   	ret    

80105e80 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105e80:	55                   	push   %ebp
80105e81:	89 e5                	mov    %esp,%ebp
80105e83:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105e86:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e89:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e8d:	8b 45 08             	mov    0x8(%ebp),%eax
80105e90:	89 04 24             	mov    %eax,(%esp)
80105e93:	e8 92 fe ff ff       	call   80105d2a <argint>
80105e98:	85 c0                	test   %eax,%eax
80105e9a:	79 07                	jns    80105ea3 <argfd+0x23>
    return -1;
80105e9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ea1:	eb 50                	jmp    80105ef3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105ea3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ea6:	85 c0                	test   %eax,%eax
80105ea8:	78 21                	js     80105ecb <argfd+0x4b>
80105eaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ead:	83 f8 0f             	cmp    $0xf,%eax
80105eb0:	7f 19                	jg     80105ecb <argfd+0x4b>
80105eb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105eb8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ebb:	83 c2 08             	add    $0x8,%edx
80105ebe:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105ec2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ec5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ec9:	75 07                	jne    80105ed2 <argfd+0x52>
    return -1;
80105ecb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed0:	eb 21                	jmp    80105ef3 <argfd+0x73>
  if(pfd)
80105ed2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105ed6:	74 08                	je     80105ee0 <argfd+0x60>
    *pfd = fd;
80105ed8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105edb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ede:	89 10                	mov    %edx,(%eax)
  if(pf)
80105ee0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ee4:	74 08                	je     80105eee <argfd+0x6e>
    *pf = f;
80105ee6:	8b 45 10             	mov    0x10(%ebp),%eax
80105ee9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105eec:	89 10                	mov    %edx,(%eax)
  return 0;
80105eee:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ef3:	c9                   	leave  
80105ef4:	c3                   	ret    

80105ef5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105ef5:	55                   	push   %ebp
80105ef6:	89 e5                	mov    %esp,%ebp
80105ef8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105efb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f02:	eb 30                	jmp    80105f34 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f04:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f0a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f0d:	83 c2 08             	add    $0x8,%edx
80105f10:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f14:	85 c0                	test   %eax,%eax
80105f16:	75 18                	jne    80105f30 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f18:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f1e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f21:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f24:	8b 55 08             	mov    0x8(%ebp),%edx
80105f27:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f2e:	eb 0f                	jmp    80105f3f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f30:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f34:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f38:	7e ca                	jle    80105f04 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f3f:	c9                   	leave  
80105f40:	c3                   	ret    

80105f41 <sys_dup>:

int
sys_dup(void)
{
80105f41:	55                   	push   %ebp
80105f42:	89 e5                	mov    %esp,%ebp
80105f44:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f47:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f4a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f55:	00 
80105f56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f5d:	e8 1e ff ff ff       	call   80105e80 <argfd>
80105f62:	85 c0                	test   %eax,%eax
80105f64:	79 07                	jns    80105f6d <sys_dup+0x2c>
    return -1;
80105f66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f6b:	eb 29                	jmp    80105f96 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f70:	89 04 24             	mov    %eax,(%esp)
80105f73:	e8 7d ff ff ff       	call   80105ef5 <fdalloc>
80105f78:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f7b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f7f:	79 07                	jns    80105f88 <sys_dup+0x47>
    return -1;
80105f81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f86:	eb 0e                	jmp    80105f96 <sys_dup+0x55>
  filedup(f);
80105f88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f8b:	89 04 24             	mov    %eax,(%esp)
80105f8e:	e8 f3 b0 ff ff       	call   80101086 <filedup>
  return fd;
80105f93:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105f96:	c9                   	leave  
80105f97:	c3                   	ret    

80105f98 <sys_read>:

int
sys_read(void)
{
80105f98:	55                   	push   %ebp
80105f99:	89 e5                	mov    %esp,%ebp
80105f9b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105f9e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fa1:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fa5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fac:	00 
80105fad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fb4:	e8 c7 fe ff ff       	call   80105e80 <argfd>
80105fb9:	85 c0                	test   %eax,%eax
80105fbb:	78 35                	js     80105ff2 <sys_read+0x5a>
80105fbd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fc0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fc4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105fcb:	e8 5a fd ff ff       	call   80105d2a <argint>
80105fd0:	85 c0                	test   %eax,%eax
80105fd2:	78 1e                	js     80105ff2 <sys_read+0x5a>
80105fd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fd7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fdb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fde:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105fe9:	e8 6a fd ff ff       	call   80105d58 <argptr>
80105fee:	85 c0                	test   %eax,%eax
80105ff0:	79 07                	jns    80105ff9 <sys_read+0x61>
    return -1;
80105ff2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ff7:	eb 19                	jmp    80106012 <sys_read+0x7a>
  return fileread(f, p, n);
80105ff9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105ffc:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105fff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106002:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106006:	89 54 24 04          	mov    %edx,0x4(%esp)
8010600a:	89 04 24             	mov    %eax,(%esp)
8010600d:	e8 e1 b1 ff ff       	call   801011f3 <fileread>
}
80106012:	c9                   	leave  
80106013:	c3                   	ret    

80106014 <sys_write>:

int
sys_write(void)
{
80106014:	55                   	push   %ebp
80106015:	89 e5                	mov    %esp,%ebp
80106017:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010601a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010601d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106021:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106028:	00 
80106029:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106030:	e8 4b fe ff ff       	call   80105e80 <argfd>
80106035:	85 c0                	test   %eax,%eax
80106037:	78 35                	js     8010606e <sys_write+0x5a>
80106039:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010603c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106040:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106047:	e8 de fc ff ff       	call   80105d2a <argint>
8010604c:	85 c0                	test   %eax,%eax
8010604e:	78 1e                	js     8010606e <sys_write+0x5a>
80106050:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106053:	89 44 24 08          	mov    %eax,0x8(%esp)
80106057:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010605a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010605e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106065:	e8 ee fc ff ff       	call   80105d58 <argptr>
8010606a:	85 c0                	test   %eax,%eax
8010606c:	79 07                	jns    80106075 <sys_write+0x61>
    return -1;
8010606e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106073:	eb 19                	jmp    8010608e <sys_write+0x7a>
  return filewrite(f, p, n);
80106075:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106078:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010607b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010607e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106082:	89 54 24 04          	mov    %edx,0x4(%esp)
80106086:	89 04 24             	mov    %eax,(%esp)
80106089:	e8 21 b2 ff ff       	call   801012af <filewrite>
}
8010608e:	c9                   	leave  
8010608f:	c3                   	ret    

80106090 <sys_close>:

int
sys_close(void)
{
80106090:	55                   	push   %ebp
80106091:	89 e5                	mov    %esp,%ebp
80106093:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106096:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106099:	89 44 24 08          	mov    %eax,0x8(%esp)
8010609d:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801060a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060ab:	e8 d0 fd ff ff       	call   80105e80 <argfd>
801060b0:	85 c0                	test   %eax,%eax
801060b2:	79 07                	jns    801060bb <sys_close+0x2b>
    return -1;
801060b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060b9:	eb 24                	jmp    801060df <sys_close+0x4f>
  proc->ofile[fd] = 0;
801060bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060c4:	83 c2 08             	add    $0x8,%edx
801060c7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060ce:	00 
  fileclose(f);
801060cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060d2:	89 04 24             	mov    %eax,(%esp)
801060d5:	e8 f4 af ff ff       	call   801010ce <fileclose>
  return 0;
801060da:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060df:	c9                   	leave  
801060e0:	c3                   	ret    

801060e1 <sys_fstat>:

int
sys_fstat(void)
{
801060e1:	55                   	push   %ebp
801060e2:	89 e5                	mov    %esp,%ebp
801060e4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801060e7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060ea:	89 44 24 08          	mov    %eax,0x8(%esp)
801060ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060f5:	00 
801060f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060fd:	e8 7e fd ff ff       	call   80105e80 <argfd>
80106102:	85 c0                	test   %eax,%eax
80106104:	78 1f                	js     80106125 <sys_fstat+0x44>
80106106:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010610d:	00 
8010610e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106111:	89 44 24 04          	mov    %eax,0x4(%esp)
80106115:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010611c:	e8 37 fc ff ff       	call   80105d58 <argptr>
80106121:	85 c0                	test   %eax,%eax
80106123:	79 07                	jns    8010612c <sys_fstat+0x4b>
    return -1;
80106125:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010612a:	eb 12                	jmp    8010613e <sys_fstat+0x5d>
  return filestat(f, st);
8010612c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010612f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106132:	89 54 24 04          	mov    %edx,0x4(%esp)
80106136:	89 04 24             	mov    %eax,(%esp)
80106139:	e8 66 b0 ff ff       	call   801011a4 <filestat>
}
8010613e:	c9                   	leave  
8010613f:	c3                   	ret    

80106140 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106140:	55                   	push   %ebp
80106141:	89 e5                	mov    %esp,%ebp
80106143:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106146:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106149:	89 44 24 04          	mov    %eax,0x4(%esp)
8010614d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106154:	e8 61 fc ff ff       	call   80105dba <argstr>
80106159:	85 c0                	test   %eax,%eax
8010615b:	78 17                	js     80106174 <sys_link+0x34>
8010615d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106160:	89 44 24 04          	mov    %eax,0x4(%esp)
80106164:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010616b:	e8 4a fc ff ff       	call   80105dba <argstr>
80106170:	85 c0                	test   %eax,%eax
80106172:	79 0a                	jns    8010617e <sys_link+0x3e>
    return -1;
80106174:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106179:	e9 42 01 00 00       	jmp    801062c0 <sys_link+0x180>

  begin_op();
8010617e:	e8 2a da ff ff       	call   80103bad <begin_op>
  if((ip = namei(old)) == 0){
80106183:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106186:	89 04 24             	mov    %eax,(%esp)
80106189:	e8 dc c3 ff ff       	call   8010256a <namei>
8010618e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106191:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106195:	75 0f                	jne    801061a6 <sys_link+0x66>
    end_op();
80106197:	e8 95 da ff ff       	call   80103c31 <end_op>
    return -1;
8010619c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a1:	e9 1a 01 00 00       	jmp    801062c0 <sys_link+0x180>
  }

  ilock(ip);
801061a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a9:	89 04 24             	mov    %eax,(%esp)
801061ac:	e8 08 b8 ff ff       	call   801019b9 <ilock>
  if(ip->type == T_DIR){
801061b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061b8:	66 83 f8 01          	cmp    $0x1,%ax
801061bc:	75 1a                	jne    801061d8 <sys_link+0x98>
    iunlockput(ip);
801061be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c1:	89 04 24             	mov    %eax,(%esp)
801061c4:	e8 7a ba ff ff       	call   80101c43 <iunlockput>
    end_op();
801061c9:	e8 63 da ff ff       	call   80103c31 <end_op>
    return -1;
801061ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d3:	e9 e8 00 00 00       	jmp    801062c0 <sys_link+0x180>
  }

  ip->nlink++;
801061d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061db:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061df:	8d 50 01             	lea    0x1(%eax),%edx
801061e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e5:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801061e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ec:	89 04 24             	mov    %eax,(%esp)
801061ef:	e8 03 b6 ff ff       	call   801017f7 <iupdate>
  iunlock(ip);
801061f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061f7:	89 04 24             	mov    %eax,(%esp)
801061fa:	e8 0e b9 ff ff       	call   80101b0d <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801061ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106202:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106205:	89 54 24 04          	mov    %edx,0x4(%esp)
80106209:	89 04 24             	mov    %eax,(%esp)
8010620c:	e8 7b c3 ff ff       	call   8010258c <nameiparent>
80106211:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106214:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106218:	75 02                	jne    8010621c <sys_link+0xdc>
    goto bad;
8010621a:	eb 68                	jmp    80106284 <sys_link+0x144>
  ilock(dp);
8010621c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010621f:	89 04 24             	mov    %eax,(%esp)
80106222:	e8 92 b7 ff ff       	call   801019b9 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106227:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010622a:	8b 10                	mov    (%eax),%edx
8010622c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010622f:	8b 00                	mov    (%eax),%eax
80106231:	39 c2                	cmp    %eax,%edx
80106233:	75 20                	jne    80106255 <sys_link+0x115>
80106235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106238:	8b 40 04             	mov    0x4(%eax),%eax
8010623b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010623f:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106242:	89 44 24 04          	mov    %eax,0x4(%esp)
80106246:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106249:	89 04 24             	mov    %eax,(%esp)
8010624c:	e8 59 c0 ff ff       	call   801022aa <dirlink>
80106251:	85 c0                	test   %eax,%eax
80106253:	79 0d                	jns    80106262 <sys_link+0x122>
    iunlockput(dp);
80106255:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106258:	89 04 24             	mov    %eax,(%esp)
8010625b:	e8 e3 b9 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106260:	eb 22                	jmp    80106284 <sys_link+0x144>
  }
  iunlockput(dp);
80106262:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106265:	89 04 24             	mov    %eax,(%esp)
80106268:	e8 d6 b9 ff ff       	call   80101c43 <iunlockput>
  iput(ip);
8010626d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106270:	89 04 24             	mov    %eax,(%esp)
80106273:	e8 fa b8 ff ff       	call   80101b72 <iput>

  end_op();
80106278:	e8 b4 d9 ff ff       	call   80103c31 <end_op>

  return 0;
8010627d:	b8 00 00 00 00       	mov    $0x0,%eax
80106282:	eb 3c                	jmp    801062c0 <sys_link+0x180>

bad:
  ilock(ip);
80106284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106287:	89 04 24             	mov    %eax,(%esp)
8010628a:	e8 2a b7 ff ff       	call   801019b9 <ilock>
  ip->nlink--;
8010628f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106292:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106296:	8d 50 ff             	lea    -0x1(%eax),%edx
80106299:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010629c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a3:	89 04 24             	mov    %eax,(%esp)
801062a6:	e8 4c b5 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801062ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ae:	89 04 24             	mov    %eax,(%esp)
801062b1:	e8 8d b9 ff ff       	call   80101c43 <iunlockput>
  end_op();
801062b6:	e8 76 d9 ff ff       	call   80103c31 <end_op>
  return -1;
801062bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062c0:	c9                   	leave  
801062c1:	c3                   	ret    

801062c2 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
801062c2:	55                   	push   %ebp
801062c3:	89 e5                	mov    %esp,%ebp
801062c5:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062c8:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062cf:	eb 4b                	jmp    8010631c <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801062db:	00 
801062dc:	89 44 24 08          	mov    %eax,0x8(%esp)
801062e0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801062e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801062e7:	8b 45 08             	mov    0x8(%ebp),%eax
801062ea:	89 04 24             	mov    %eax,(%esp)
801062ed:	e8 da bb ff ff       	call   80101ecc <readi>
801062f2:	83 f8 10             	cmp    $0x10,%eax
801062f5:	74 0c                	je     80106303 <isdirempty+0x41>
      panic("isdirempty: readi");
801062f7:	c7 04 24 78 a1 10 80 	movl   $0x8010a178,(%esp)
801062fe:	e8 37 a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106303:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106307:	66 85 c0             	test   %ax,%ax
8010630a:	74 07                	je     80106313 <isdirempty+0x51>
      return 0;
8010630c:	b8 00 00 00 00       	mov    $0x0,%eax
80106311:	eb 1b                	jmp    8010632e <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106313:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106316:	83 c0 10             	add    $0x10,%eax
80106319:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010631c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010631f:	8b 45 08             	mov    0x8(%ebp),%eax
80106322:	8b 40 18             	mov    0x18(%eax),%eax
80106325:	39 c2                	cmp    %eax,%edx
80106327:	72 a8                	jb     801062d1 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106329:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010632e:	c9                   	leave  
8010632f:	c3                   	ret    

80106330 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106330:	55                   	push   %ebp
80106331:	89 e5                	mov    %esp,%ebp
80106333:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106336:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106339:	89 44 24 04          	mov    %eax,0x4(%esp)
8010633d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106344:	e8 71 fa ff ff       	call   80105dba <argstr>
80106349:	85 c0                	test   %eax,%eax
8010634b:	79 0a                	jns    80106357 <sys_unlink+0x27>
    return -1;
8010634d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106352:	e9 af 01 00 00       	jmp    80106506 <sys_unlink+0x1d6>

  begin_op();
80106357:	e8 51 d8 ff ff       	call   80103bad <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010635c:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010635f:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106362:	89 54 24 04          	mov    %edx,0x4(%esp)
80106366:	89 04 24             	mov    %eax,(%esp)
80106369:	e8 1e c2 ff ff       	call   8010258c <nameiparent>
8010636e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106371:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106375:	75 0f                	jne    80106386 <sys_unlink+0x56>
    end_op();
80106377:	e8 b5 d8 ff ff       	call   80103c31 <end_op>
    return -1;
8010637c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106381:	e9 80 01 00 00       	jmp    80106506 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106386:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106389:	89 04 24             	mov    %eax,(%esp)
8010638c:	e8 28 b6 ff ff       	call   801019b9 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106391:	c7 44 24 04 8a a1 10 	movl   $0x8010a18a,0x4(%esp)
80106398:	80 
80106399:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010639c:	89 04 24             	mov    %eax,(%esp)
8010639f:	e8 1b be ff ff       	call   801021bf <namecmp>
801063a4:	85 c0                	test   %eax,%eax
801063a6:	0f 84 45 01 00 00    	je     801064f1 <sys_unlink+0x1c1>
801063ac:	c7 44 24 04 8c a1 10 	movl   $0x8010a18c,0x4(%esp)
801063b3:	80 
801063b4:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063b7:	89 04 24             	mov    %eax,(%esp)
801063ba:	e8 00 be ff ff       	call   801021bf <namecmp>
801063bf:	85 c0                	test   %eax,%eax
801063c1:	0f 84 2a 01 00 00    	je     801064f1 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063c7:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063ca:	89 44 24 08          	mov    %eax,0x8(%esp)
801063ce:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801063d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d8:	89 04 24             	mov    %eax,(%esp)
801063db:	e8 01 be ff ff       	call   801021e1 <dirlookup>
801063e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801063e3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801063e7:	75 05                	jne    801063ee <sys_unlink+0xbe>
    goto bad;
801063e9:	e9 03 01 00 00       	jmp    801064f1 <sys_unlink+0x1c1>
  ilock(ip);
801063ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063f1:	89 04 24             	mov    %eax,(%esp)
801063f4:	e8 c0 b5 ff ff       	call   801019b9 <ilock>

  if(ip->nlink < 1)
801063f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063fc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106400:	66 85 c0             	test   %ax,%ax
80106403:	7f 0c                	jg     80106411 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106405:	c7 04 24 8f a1 10 80 	movl   $0x8010a18f,(%esp)
8010640c:	e8 29 a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106411:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106414:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106418:	66 83 f8 01          	cmp    $0x1,%ax
8010641c:	75 1f                	jne    8010643d <sys_unlink+0x10d>
8010641e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106421:	89 04 24             	mov    %eax,(%esp)
80106424:	e8 99 fe ff ff       	call   801062c2 <isdirempty>
80106429:	85 c0                	test   %eax,%eax
8010642b:	75 10                	jne    8010643d <sys_unlink+0x10d>
    iunlockput(ip);
8010642d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106430:	89 04 24             	mov    %eax,(%esp)
80106433:	e8 0b b8 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106438:	e9 b4 00 00 00       	jmp    801064f1 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
8010643d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106444:	00 
80106445:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010644c:	00 
8010644d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106450:	89 04 24             	mov    %eax,(%esp)
80106453:	e8 90 f5 ff ff       	call   801059e8 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106458:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010645b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106462:	00 
80106463:	89 44 24 08          	mov    %eax,0x8(%esp)
80106467:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010646a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010646e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106471:	89 04 24             	mov    %eax,(%esp)
80106474:	e8 b7 bb ff ff       	call   80102030 <writei>
80106479:	83 f8 10             	cmp    $0x10,%eax
8010647c:	74 0c                	je     8010648a <sys_unlink+0x15a>
    panic("unlink: writei");
8010647e:	c7 04 24 a1 a1 10 80 	movl   $0x8010a1a1,(%esp)
80106485:	e8 b0 a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
8010648a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010648d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106491:	66 83 f8 01          	cmp    $0x1,%ax
80106495:	75 1c                	jne    801064b3 <sys_unlink+0x183>
    dp->nlink--;
80106497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010649e:	8d 50 ff             	lea    -0x1(%eax),%edx
801064a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ab:	89 04 24             	mov    %eax,(%esp)
801064ae:	e8 44 b3 ff ff       	call   801017f7 <iupdate>
  }
  iunlockput(dp);
801064b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b6:	89 04 24             	mov    %eax,(%esp)
801064b9:	e8 85 b7 ff ff       	call   80101c43 <iunlockput>

  ip->nlink--;
801064be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064c1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064c5:	8d 50 ff             	lea    -0x1(%eax),%edx
801064c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064cb:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064d2:	89 04 24             	mov    %eax,(%esp)
801064d5:	e8 1d b3 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801064da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064dd:	89 04 24             	mov    %eax,(%esp)
801064e0:	e8 5e b7 ff ff       	call   80101c43 <iunlockput>

  end_op();
801064e5:	e8 47 d7 ff ff       	call   80103c31 <end_op>

  return 0;
801064ea:	b8 00 00 00 00       	mov    $0x0,%eax
801064ef:	eb 15                	jmp    80106506 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801064f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f4:	89 04 24             	mov    %eax,(%esp)
801064f7:	e8 47 b7 ff ff       	call   80101c43 <iunlockput>
  end_op();
801064fc:	e8 30 d7 ff ff       	call   80103c31 <end_op>
  return -1;
80106501:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106506:	c9                   	leave  
80106507:	c3                   	ret    

80106508 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106508:	55                   	push   %ebp
80106509:	89 e5                	mov    %esp,%ebp
8010650b:	83 ec 48             	sub    $0x48,%esp
8010650e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106511:	8b 55 10             	mov    0x10(%ebp),%edx
80106514:	8b 45 14             	mov    0x14(%ebp),%eax
80106517:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010651b:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
8010651f:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106523:	8d 45 de             	lea    -0x22(%ebp),%eax
80106526:	89 44 24 04          	mov    %eax,0x4(%esp)
8010652a:	8b 45 08             	mov    0x8(%ebp),%eax
8010652d:	89 04 24             	mov    %eax,(%esp)
80106530:	e8 57 c0 ff ff       	call   8010258c <nameiparent>
80106535:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106538:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010653c:	75 0a                	jne    80106548 <create+0x40>
    return 0;
8010653e:	b8 00 00 00 00       	mov    $0x0,%eax
80106543:	e9 7e 01 00 00       	jmp    801066c6 <create+0x1be>
  ilock(dp);
80106548:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010654b:	89 04 24             	mov    %eax,(%esp)
8010654e:	e8 66 b4 ff ff       	call   801019b9 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106553:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106556:	89 44 24 08          	mov    %eax,0x8(%esp)
8010655a:	8d 45 de             	lea    -0x22(%ebp),%eax
8010655d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106564:	89 04 24             	mov    %eax,(%esp)
80106567:	e8 75 bc ff ff       	call   801021e1 <dirlookup>
8010656c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010656f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106573:	74 47                	je     801065bc <create+0xb4>
    iunlockput(dp);
80106575:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106578:	89 04 24             	mov    %eax,(%esp)
8010657b:	e8 c3 b6 ff ff       	call   80101c43 <iunlockput>
    ilock(ip);
80106580:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106583:	89 04 24             	mov    %eax,(%esp)
80106586:	e8 2e b4 ff ff       	call   801019b9 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010658b:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106590:	75 15                	jne    801065a7 <create+0x9f>
80106592:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106595:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106599:	66 83 f8 02          	cmp    $0x2,%ax
8010659d:	75 08                	jne    801065a7 <create+0x9f>
      return ip;
8010659f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065a2:	e9 1f 01 00 00       	jmp    801066c6 <create+0x1be>
    iunlockput(ip);
801065a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065aa:	89 04 24             	mov    %eax,(%esp)
801065ad:	e8 91 b6 ff ff       	call   80101c43 <iunlockput>
    return 0;
801065b2:	b8 00 00 00 00       	mov    $0x0,%eax
801065b7:	e9 0a 01 00 00       	jmp    801066c6 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801065bc:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801065c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c3:	8b 00                	mov    (%eax),%eax
801065c5:	89 54 24 04          	mov    %edx,0x4(%esp)
801065c9:	89 04 24             	mov    %eax,(%esp)
801065cc:	e8 51 b1 ff ff       	call   80101722 <ialloc>
801065d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065d4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065d8:	75 0c                	jne    801065e6 <create+0xde>
    panic("create: ialloc");
801065da:	c7 04 24 b0 a1 10 80 	movl   $0x8010a1b0,(%esp)
801065e1:	e8 54 9f ff ff       	call   8010053a <panic>

  ilock(ip);
801065e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e9:	89 04 24             	mov    %eax,(%esp)
801065ec:	e8 c8 b3 ff ff       	call   801019b9 <ilock>
  ip->major = major;
801065f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065f4:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801065f8:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801065fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ff:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106603:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106607:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010660a:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106610:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106613:	89 04 24             	mov    %eax,(%esp)
80106616:	e8 dc b1 ff ff       	call   801017f7 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
8010661b:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106620:	75 6a                	jne    8010668c <create+0x184>
    dp->nlink++;  // for ".."
80106622:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106625:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106629:	8d 50 01             	lea    0x1(%eax),%edx
8010662c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662f:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106636:	89 04 24             	mov    %eax,(%esp)
80106639:	e8 b9 b1 ff ff       	call   801017f7 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010663e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106641:	8b 40 04             	mov    0x4(%eax),%eax
80106644:	89 44 24 08          	mov    %eax,0x8(%esp)
80106648:	c7 44 24 04 8a a1 10 	movl   $0x8010a18a,0x4(%esp)
8010664f:	80 
80106650:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106653:	89 04 24             	mov    %eax,(%esp)
80106656:	e8 4f bc ff ff       	call   801022aa <dirlink>
8010665b:	85 c0                	test   %eax,%eax
8010665d:	78 21                	js     80106680 <create+0x178>
8010665f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106662:	8b 40 04             	mov    0x4(%eax),%eax
80106665:	89 44 24 08          	mov    %eax,0x8(%esp)
80106669:	c7 44 24 04 8c a1 10 	movl   $0x8010a18c,0x4(%esp)
80106670:	80 
80106671:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106674:	89 04 24             	mov    %eax,(%esp)
80106677:	e8 2e bc ff ff       	call   801022aa <dirlink>
8010667c:	85 c0                	test   %eax,%eax
8010667e:	79 0c                	jns    8010668c <create+0x184>
      panic("create dots");
80106680:	c7 04 24 bf a1 10 80 	movl   $0x8010a1bf,(%esp)
80106687:	e8 ae 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010668c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010668f:	8b 40 04             	mov    0x4(%eax),%eax
80106692:	89 44 24 08          	mov    %eax,0x8(%esp)
80106696:	8d 45 de             	lea    -0x22(%ebp),%eax
80106699:	89 44 24 04          	mov    %eax,0x4(%esp)
8010669d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a0:	89 04 24             	mov    %eax,(%esp)
801066a3:	e8 02 bc ff ff       	call   801022aa <dirlink>
801066a8:	85 c0                	test   %eax,%eax
801066aa:	79 0c                	jns    801066b8 <create+0x1b0>
    panic("create: dirlink");
801066ac:	c7 04 24 cb a1 10 80 	movl   $0x8010a1cb,(%esp)
801066b3:	e8 82 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
801066b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bb:	89 04 24             	mov    %eax,(%esp)
801066be:	e8 80 b5 ff ff       	call   80101c43 <iunlockput>

  return ip;
801066c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066c6:	c9                   	leave  
801066c7:	c3                   	ret    

801066c8 <sys_open>:

int
sys_open(void)
{
801066c8:	55                   	push   %ebp
801066c9:	89 e5                	mov    %esp,%ebp
801066cb:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066ce:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801066d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066dc:	e8 d9 f6 ff ff       	call   80105dba <argstr>
801066e1:	85 c0                	test   %eax,%eax
801066e3:	78 17                	js     801066fc <sys_open+0x34>
801066e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801066e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066f3:	e8 32 f6 ff ff       	call   80105d2a <argint>
801066f8:	85 c0                	test   %eax,%eax
801066fa:	79 0a                	jns    80106706 <sys_open+0x3e>
    return -1;
801066fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106701:	e9 5c 01 00 00       	jmp    80106862 <sys_open+0x19a>

  begin_op();
80106706:	e8 a2 d4 ff ff       	call   80103bad <begin_op>

  if(omode & O_CREATE){
8010670b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010670e:	25 00 02 00 00       	and    $0x200,%eax
80106713:	85 c0                	test   %eax,%eax
80106715:	74 3b                	je     80106752 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106717:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010671a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106721:	00 
80106722:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106729:	00 
8010672a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106731:	00 
80106732:	89 04 24             	mov    %eax,(%esp)
80106735:	e8 ce fd ff ff       	call   80106508 <create>
8010673a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010673d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106741:	75 6b                	jne    801067ae <sys_open+0xe6>
      end_op();
80106743:	e8 e9 d4 ff ff       	call   80103c31 <end_op>
      return -1;
80106748:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010674d:	e9 10 01 00 00       	jmp    80106862 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106752:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106755:	89 04 24             	mov    %eax,(%esp)
80106758:	e8 0d be ff ff       	call   8010256a <namei>
8010675d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106760:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106764:	75 0f                	jne    80106775 <sys_open+0xad>
      end_op();
80106766:	e8 c6 d4 ff ff       	call   80103c31 <end_op>
      return -1;
8010676b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106770:	e9 ed 00 00 00       	jmp    80106862 <sys_open+0x19a>
    }
    ilock(ip);
80106775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106778:	89 04 24             	mov    %eax,(%esp)
8010677b:	e8 39 b2 ff ff       	call   801019b9 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106780:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106783:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106787:	66 83 f8 01          	cmp    $0x1,%ax
8010678b:	75 21                	jne    801067ae <sys_open+0xe6>
8010678d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106790:	85 c0                	test   %eax,%eax
80106792:	74 1a                	je     801067ae <sys_open+0xe6>
      iunlockput(ip);
80106794:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106797:	89 04 24             	mov    %eax,(%esp)
8010679a:	e8 a4 b4 ff ff       	call   80101c43 <iunlockput>
      end_op();
8010679f:	e8 8d d4 ff ff       	call   80103c31 <end_op>
      return -1;
801067a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067a9:	e9 b4 00 00 00       	jmp    80106862 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067ae:	e8 73 a8 ff ff       	call   80101026 <filealloc>
801067b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067b6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067ba:	74 14                	je     801067d0 <sys_open+0x108>
801067bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067bf:	89 04 24             	mov    %eax,(%esp)
801067c2:	e8 2e f7 ff ff       	call   80105ef5 <fdalloc>
801067c7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067ca:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067ce:	79 28                	jns    801067f8 <sys_open+0x130>
    if(f)
801067d0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067d4:	74 0b                	je     801067e1 <sys_open+0x119>
      fileclose(f);
801067d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067d9:	89 04 24             	mov    %eax,(%esp)
801067dc:	e8 ed a8 ff ff       	call   801010ce <fileclose>
    iunlockput(ip);
801067e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e4:	89 04 24             	mov    %eax,(%esp)
801067e7:	e8 57 b4 ff ff       	call   80101c43 <iunlockput>
    end_op();
801067ec:	e8 40 d4 ff ff       	call   80103c31 <end_op>
    return -1;
801067f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067f6:	eb 6a                	jmp    80106862 <sys_open+0x19a>
  }
  iunlock(ip);
801067f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067fb:	89 04 24             	mov    %eax,(%esp)
801067fe:	e8 0a b3 ff ff       	call   80101b0d <iunlock>
  end_op();
80106803:	e8 29 d4 ff ff       	call   80103c31 <end_op>

  f->type = FD_INODE;
80106808:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010680b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106811:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106814:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106817:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010681a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010681d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106824:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106827:	83 e0 01             	and    $0x1,%eax
8010682a:	85 c0                	test   %eax,%eax
8010682c:	0f 94 c0             	sete   %al
8010682f:	89 c2                	mov    %eax,%edx
80106831:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106834:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106837:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010683a:	83 e0 01             	and    $0x1,%eax
8010683d:	85 c0                	test   %eax,%eax
8010683f:	75 0a                	jne    8010684b <sys_open+0x183>
80106841:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106844:	83 e0 02             	and    $0x2,%eax
80106847:	85 c0                	test   %eax,%eax
80106849:	74 07                	je     80106852 <sys_open+0x18a>
8010684b:	b8 01 00 00 00       	mov    $0x1,%eax
80106850:	eb 05                	jmp    80106857 <sys_open+0x18f>
80106852:	b8 00 00 00 00       	mov    $0x0,%eax
80106857:	89 c2                	mov    %eax,%edx
80106859:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010685c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010685f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106862:	c9                   	leave  
80106863:	c3                   	ret    

80106864 <sys_mkdir>:

int
sys_mkdir(void)
{
80106864:	55                   	push   %ebp
80106865:	89 e5                	mov    %esp,%ebp
80106867:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010686a:	e8 3e d3 ff ff       	call   80103bad <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010686f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106872:	89 44 24 04          	mov    %eax,0x4(%esp)
80106876:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010687d:	e8 38 f5 ff ff       	call   80105dba <argstr>
80106882:	85 c0                	test   %eax,%eax
80106884:	78 2c                	js     801068b2 <sys_mkdir+0x4e>
80106886:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106889:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106890:	00 
80106891:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106898:	00 
80106899:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068a0:	00 
801068a1:	89 04 24             	mov    %eax,(%esp)
801068a4:	e8 5f fc ff ff       	call   80106508 <create>
801068a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068b0:	75 0c                	jne    801068be <sys_mkdir+0x5a>
    end_op();
801068b2:	e8 7a d3 ff ff       	call   80103c31 <end_op>
    return -1;
801068b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068bc:	eb 15                	jmp    801068d3 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801068be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c1:	89 04 24             	mov    %eax,(%esp)
801068c4:	e8 7a b3 ff ff       	call   80101c43 <iunlockput>
  end_op();
801068c9:	e8 63 d3 ff ff       	call   80103c31 <end_op>
  return 0;
801068ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068d3:	c9                   	leave  
801068d4:	c3                   	ret    

801068d5 <sys_mknod>:

int
sys_mknod(void)
{
801068d5:	55                   	push   %ebp
801068d6:	89 e5                	mov    %esp,%ebp
801068d8:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801068db:	e8 cd d2 ff ff       	call   80103bad <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801068e0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801068e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801068e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068ee:	e8 c7 f4 ff ff       	call   80105dba <argstr>
801068f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068fa:	78 5e                	js     8010695a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801068fc:	8d 45 e8             	lea    -0x18(%ebp),%eax
801068ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106903:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010690a:	e8 1b f4 ff ff       	call   80105d2a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
8010690f:	85 c0                	test   %eax,%eax
80106911:	78 47                	js     8010695a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106913:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106916:	89 44 24 04          	mov    %eax,0x4(%esp)
8010691a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106921:	e8 04 f4 ff ff       	call   80105d2a <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106926:	85 c0                	test   %eax,%eax
80106928:	78 30                	js     8010695a <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010692a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010692d:	0f bf c8             	movswl %ax,%ecx
80106930:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106933:	0f bf d0             	movswl %ax,%edx
80106936:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106939:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010693d:	89 54 24 08          	mov    %edx,0x8(%esp)
80106941:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106948:	00 
80106949:	89 04 24             	mov    %eax,(%esp)
8010694c:	e8 b7 fb ff ff       	call   80106508 <create>
80106951:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106954:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106958:	75 0c                	jne    80106966 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010695a:	e8 d2 d2 ff ff       	call   80103c31 <end_op>
    return -1;
8010695f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106964:	eb 15                	jmp    8010697b <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106966:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106969:	89 04 24             	mov    %eax,(%esp)
8010696c:	e8 d2 b2 ff ff       	call   80101c43 <iunlockput>
  end_op();
80106971:	e8 bb d2 ff ff       	call   80103c31 <end_op>
  return 0;
80106976:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010697b:	c9                   	leave  
8010697c:	c3                   	ret    

8010697d <sys_chdir>:

int
sys_chdir(void)
{
8010697d:	55                   	push   %ebp
8010697e:	89 e5                	mov    %esp,%ebp
80106980:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106983:	e8 25 d2 ff ff       	call   80103bad <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106988:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010698b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010698f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106996:	e8 1f f4 ff ff       	call   80105dba <argstr>
8010699b:	85 c0                	test   %eax,%eax
8010699d:	78 14                	js     801069b3 <sys_chdir+0x36>
8010699f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069a2:	89 04 24             	mov    %eax,(%esp)
801069a5:	e8 c0 bb ff ff       	call   8010256a <namei>
801069aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069b1:	75 0c                	jne    801069bf <sys_chdir+0x42>
    end_op();
801069b3:	e8 79 d2 ff ff       	call   80103c31 <end_op>
    return -1;
801069b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069bd:	eb 61                	jmp    80106a20 <sys_chdir+0xa3>
  }
  ilock(ip);
801069bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c2:	89 04 24             	mov    %eax,(%esp)
801069c5:	e8 ef af ff ff       	call   801019b9 <ilock>
  if(ip->type != T_DIR){
801069ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069cd:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069d1:	66 83 f8 01          	cmp    $0x1,%ax
801069d5:	74 17                	je     801069ee <sys_chdir+0x71>
    iunlockput(ip);
801069d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069da:	89 04 24             	mov    %eax,(%esp)
801069dd:	e8 61 b2 ff ff       	call   80101c43 <iunlockput>
    end_op();
801069e2:	e8 4a d2 ff ff       	call   80103c31 <end_op>
    return -1;
801069e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069ec:	eb 32                	jmp    80106a20 <sys_chdir+0xa3>
  }
  iunlock(ip);
801069ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f1:	89 04 24             	mov    %eax,(%esp)
801069f4:	e8 14 b1 ff ff       	call   80101b0d <iunlock>
  iput(proc->cwd);
801069f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069ff:	8b 40 68             	mov    0x68(%eax),%eax
80106a02:	89 04 24             	mov    %eax,(%esp)
80106a05:	e8 68 b1 ff ff       	call   80101b72 <iput>
  end_op();
80106a0a:	e8 22 d2 ff ff       	call   80103c31 <end_op>
  proc->cwd = ip;
80106a0f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a15:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a18:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a20:	c9                   	leave  
80106a21:	c3                   	ret    

80106a22 <sys_exec>:

int
sys_exec(void)
{
80106a22:	55                   	push   %ebp
80106a23:	89 e5                	mov    %esp,%ebp
80106a25:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a2b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a39:	e8 7c f3 ff ff       	call   80105dba <argstr>
80106a3e:	85 c0                	test   %eax,%eax
80106a40:	78 1a                	js     80106a5c <sys_exec+0x3a>
80106a42:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a48:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a4c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a53:	e8 d2 f2 ff ff       	call   80105d2a <argint>
80106a58:	85 c0                	test   %eax,%eax
80106a5a:	79 0a                	jns    80106a66 <sys_exec+0x44>
    return -1;
80106a5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a61:	e9 c8 00 00 00       	jmp    80106b2e <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a66:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a6d:	00 
80106a6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a75:	00 
80106a76:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a7c:	89 04 24             	mov    %eax,(%esp)
80106a7f:	e8 64 ef ff ff       	call   801059e8 <memset>
  for(i=0;; i++){
80106a84:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8e:	83 f8 1f             	cmp    $0x1f,%eax
80106a91:	76 0a                	jbe    80106a9d <sys_exec+0x7b>
      return -1;
80106a93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a98:	e9 91 00 00 00       	jmp    80106b2e <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa0:	c1 e0 02             	shl    $0x2,%eax
80106aa3:	89 c2                	mov    %eax,%edx
80106aa5:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106aab:	01 c2                	add    %eax,%edx
80106aad:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106ab3:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ab7:	89 14 24             	mov    %edx,(%esp)
80106aba:	e8 cf f1 ff ff       	call   80105c8e <fetchint>
80106abf:	85 c0                	test   %eax,%eax
80106ac1:	79 07                	jns    80106aca <sys_exec+0xa8>
      return -1;
80106ac3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ac8:	eb 64                	jmp    80106b2e <sys_exec+0x10c>
    if(uarg == 0){
80106aca:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ad0:	85 c0                	test   %eax,%eax
80106ad2:	75 26                	jne    80106afa <sys_exec+0xd8>
      argv[i] = 0;
80106ad4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad7:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106ade:	00 00 00 00 
      break;
80106ae2:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae6:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106aec:	89 54 24 04          	mov    %edx,0x4(%esp)
80106af0:	89 04 24             	mov    %eax,(%esp)
80106af3:	e8 12 a0 ff ff       	call   80100b0a <exec>
80106af8:	eb 34                	jmp    80106b2e <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106afa:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b00:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b03:	c1 e2 02             	shl    $0x2,%edx
80106b06:	01 c2                	add    %eax,%edx
80106b08:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b0e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b12:	89 04 24             	mov    %eax,(%esp)
80106b15:	e8 ae f1 ff ff       	call   80105cc8 <fetchstr>
80106b1a:	85 c0                	test   %eax,%eax
80106b1c:	79 07                	jns    80106b25 <sys_exec+0x103>
      return -1;
80106b1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b23:	eb 09                	jmp    80106b2e <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b25:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b29:	e9 5d ff ff ff       	jmp    80106a8b <sys_exec+0x69>
  return exec(path, argv);
}
80106b2e:	c9                   	leave  
80106b2f:	c3                   	ret    

80106b30 <sys_pipe>:

int
sys_pipe(void)
{
80106b30:	55                   	push   %ebp
80106b31:	89 e5                	mov    %esp,%ebp
80106b33:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b36:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b3d:	00 
80106b3e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b41:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b4c:	e8 07 f2 ff ff       	call   80105d58 <argptr>
80106b51:	85 c0                	test   %eax,%eax
80106b53:	79 0a                	jns    80106b5f <sys_pipe+0x2f>
    return -1;
80106b55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b5a:	e9 9b 00 00 00       	jmp    80106bfa <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b5f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b62:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b66:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b69:	89 04 24             	mov    %eax,(%esp)
80106b6c:	e8 48 db ff ff       	call   801046b9 <pipealloc>
80106b71:	85 c0                	test   %eax,%eax
80106b73:	79 07                	jns    80106b7c <sys_pipe+0x4c>
    return -1;
80106b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b7a:	eb 7e                	jmp    80106bfa <sys_pipe+0xca>
  fd0 = -1;
80106b7c:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106b83:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b86:	89 04 24             	mov    %eax,(%esp)
80106b89:	e8 67 f3 ff ff       	call   80105ef5 <fdalloc>
80106b8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b91:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b95:	78 14                	js     80106bab <sys_pipe+0x7b>
80106b97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b9a:	89 04 24             	mov    %eax,(%esp)
80106b9d:	e8 53 f3 ff ff       	call   80105ef5 <fdalloc>
80106ba2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ba5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ba9:	79 37                	jns    80106be2 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106baf:	78 14                	js     80106bc5 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bb1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bb7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bba:	83 c2 08             	add    $0x8,%edx
80106bbd:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106bc4:	00 
    fileclose(rf);
80106bc5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bc8:	89 04 24             	mov    %eax,(%esp)
80106bcb:	e8 fe a4 ff ff       	call   801010ce <fileclose>
    fileclose(wf);
80106bd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bd3:	89 04 24             	mov    %eax,(%esp)
80106bd6:	e8 f3 a4 ff ff       	call   801010ce <fileclose>
    return -1;
80106bdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106be0:	eb 18                	jmp    80106bfa <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106be2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106be5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106be8:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106bea:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bed:	8d 50 04             	lea    0x4(%eax),%edx
80106bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf3:	89 02                	mov    %eax,(%edx)
  return 0;
80106bf5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106bfa:	c9                   	leave  
80106bfb:	c3                   	ret    

80106bfc <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106bfc:	55                   	push   %ebp
80106bfd:	89 e5                	mov    %esp,%ebp
80106bff:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c02:	e8 7e e2 ff ff       	call   80104e85 <fork>
}
80106c07:	c9                   	leave  
80106c08:	c3                   	ret    

80106c09 <sys_exit>:

int
sys_exit(void)
{
80106c09:	55                   	push   %ebp
80106c0a:	89 e5                	mov    %esp,%ebp
80106c0c:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c0f:	e8 2d e4 ff ff       	call   80105041 <exit>
  return 0;  // not reached
80106c14:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c19:	c9                   	leave  
80106c1a:	c3                   	ret    

80106c1b <sys_wait>:

int
sys_wait(void)
{
80106c1b:	55                   	push   %ebp
80106c1c:	89 e5                	mov    %esp,%ebp
80106c1e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c21:	e8 53 e5 ff ff       	call   80105179 <wait>
}
80106c26:	c9                   	leave  
80106c27:	c3                   	ret    

80106c28 <sys_kill>:

int
sys_kill(void)
{
80106c28:	55                   	push   %ebp
80106c29:	89 e5                	mov    %esp,%ebp
80106c2b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c2e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c31:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c35:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c3c:	e8 e9 f0 ff ff       	call   80105d2a <argint>
80106c41:	85 c0                	test   %eax,%eax
80106c43:	79 07                	jns    80106c4c <sys_kill+0x24>
    return -1;
80106c45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c4a:	eb 0b                	jmp    80106c57 <sys_kill+0x2f>
  return kill(pid);
80106c4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c4f:	89 04 24             	mov    %eax,(%esp)
80106c52:	e8 00 e9 ff ff       	call   80105557 <kill>
}
80106c57:	c9                   	leave  
80106c58:	c3                   	ret    

80106c59 <sys_getpid>:

int
sys_getpid(void)
{
80106c59:	55                   	push   %ebp
80106c5a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c5c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c62:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c65:	5d                   	pop    %ebp
80106c66:	c3                   	ret    

80106c67 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c67:	55                   	push   %ebp
80106c68:	89 e5                	mov    %esp,%ebp
80106c6a:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c6d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c70:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c74:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c7b:	e8 aa f0 ff ff       	call   80105d2a <argint>
80106c80:	85 c0                	test   %eax,%eax
80106c82:	79 07                	jns    80106c8b <sys_sbrk+0x24>
    return -1;
80106c84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c89:	eb 39                	jmp    80106cc4 <sys_sbrk+0x5d>
  addr = proc->sz;
80106c8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c91:	8b 00                	mov    (%eax),%eax
80106c93:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106c96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c99:	89 04 24             	mov    %eax,(%esp)
80106c9c:	e8 29 e1 ff ff       	call   80104dca <growproc>
80106ca1:	85 c0                	test   %eax,%eax
80106ca3:	79 07                	jns    80106cac <sys_sbrk+0x45>
    return -1;
80106ca5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106caa:	eb 18                	jmp    80106cc4 <sys_sbrk+0x5d>
  cprintf("num of pages in system:%d\n",countPages());
80106cac:	e8 df c5 ff ff       	call   80103290 <countPages>
80106cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cb5:	c7 04 24 db a1 10 80 	movl   $0x8010a1db,(%esp)
80106cbc:	e8 df 96 ff ff       	call   801003a0 <cprintf>
  return addr;
80106cc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cc4:	c9                   	leave  
80106cc5:	c3                   	ret    

80106cc6 <sys_sleep>:

int
sys_sleep(void)
{
80106cc6:	55                   	push   %ebp
80106cc7:	89 e5                	mov    %esp,%ebp
80106cc9:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106ccc:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cd3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cda:	e8 4b f0 ff ff       	call   80105d2a <argint>
80106cdf:	85 c0                	test   %eax,%eax
80106ce1:	79 07                	jns    80106cea <sys_sleep+0x24>
    return -1;
80106ce3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ce8:	eb 6c                	jmp    80106d56 <sys_sleep+0x90>
  acquire(&tickslock);
80106cea:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106cf1:	e8 9e ea ff ff       	call   80105794 <acquire>
  ticks0 = ticks;
80106cf6:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106cfb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106cfe:	eb 34                	jmp    80106d34 <sys_sleep+0x6e>
    if(proc->killed){
80106d00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d06:	8b 40 24             	mov    0x24(%eax),%eax
80106d09:	85 c0                	test   %eax,%eax
80106d0b:	74 13                	je     80106d20 <sys_sleep+0x5a>
      release(&tickslock);
80106d0d:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d14:	e8 dd ea ff ff       	call   801057f6 <release>
      return -1;
80106d19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d1e:	eb 36                	jmp    80106d56 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d20:	c7 44 24 04 c0 04 12 	movl   $0x801204c0,0x4(%esp)
80106d27:	80 
80106d28:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80106d2f:	e8 1c e7 ff ff       	call   80105450 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d34:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d39:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d3c:	89 c2                	mov    %eax,%edx
80106d3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d41:	39 c2                	cmp    %eax,%edx
80106d43:	72 bb                	jb     80106d00 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d45:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d4c:	e8 a5 ea ff ff       	call   801057f6 <release>
  return 0;
80106d51:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d56:	c9                   	leave  
80106d57:	c3                   	ret    

80106d58 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d58:	55                   	push   %ebp
80106d59:	89 e5                	mov    %esp,%ebp
80106d5b:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d5e:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d65:	e8 2a ea ff ff       	call   80105794 <acquire>
  xticks = ticks;
80106d6a:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d6f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d72:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d79:	e8 78 ea ff ff       	call   801057f6 <release>
  return xticks;
80106d7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d81:	c9                   	leave  
80106d82:	c3                   	ret    

80106d83 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d83:	55                   	push   %ebp
80106d84:	89 e5                	mov    %esp,%ebp
80106d86:	83 ec 08             	sub    $0x8,%esp
80106d89:	8b 55 08             	mov    0x8(%ebp),%edx
80106d8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d8f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d93:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d96:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106d9a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106d9e:	ee                   	out    %al,(%dx)
}
80106d9f:	c9                   	leave  
80106da0:	c3                   	ret    

80106da1 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106da1:	55                   	push   %ebp
80106da2:	89 e5                	mov    %esp,%ebp
80106da4:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106da7:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106dae:	00 
80106daf:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106db6:	e8 c8 ff ff ff       	call   80106d83 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106dbb:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106dc2:	00 
80106dc3:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dca:	e8 b4 ff ff ff       	call   80106d83 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106dcf:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106dd6:	00 
80106dd7:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dde:	e8 a0 ff ff ff       	call   80106d83 <outb>
  picenable(IRQ_TIMER);
80106de3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dea:	e8 5d d7 ff ff       	call   8010454c <picenable>
}
80106def:	c9                   	leave  
80106df0:	c3                   	ret    

80106df1 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106df1:	1e                   	push   %ds
  pushl %es
80106df2:	06                   	push   %es
  pushl %fs
80106df3:	0f a0                	push   %fs
  pushl %gs
80106df5:	0f a8                	push   %gs
  pushal
80106df7:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106df8:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106dfc:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106dfe:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e00:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e04:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e06:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e08:	54                   	push   %esp
  call trap
80106e09:	e8 d8 01 00 00       	call   80106fe6 <trap>
  addl $4, %esp
80106e0e:	83 c4 04             	add    $0x4,%esp

80106e11 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e11:	61                   	popa   
  popl %gs
80106e12:	0f a9                	pop    %gs
  popl %fs
80106e14:	0f a1                	pop    %fs
  popl %es
80106e16:	07                   	pop    %es
  popl %ds
80106e17:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e18:	83 c4 08             	add    $0x8,%esp
  iret
80106e1b:	cf                   	iret   

80106e1c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e1c:	55                   	push   %ebp
80106e1d:	89 e5                	mov    %esp,%ebp
80106e1f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e22:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e25:	83 e8 01             	sub    $0x1,%eax
80106e28:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e2c:	8b 45 08             	mov    0x8(%ebp),%eax
80106e2f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e33:	8b 45 08             	mov    0x8(%ebp),%eax
80106e36:	c1 e8 10             	shr    $0x10,%eax
80106e39:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e3d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e40:	0f 01 18             	lidtl  (%eax)
}
80106e43:	c9                   	leave  
80106e44:	c3                   	ret    

80106e45 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e45:	55                   	push   %ebp
80106e46:	89 e5                	mov    %esp,%ebp
80106e48:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e4b:	0f 20 d0             	mov    %cr2,%eax
80106e4e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e51:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e54:	c9                   	leave  
80106e55:	c3                   	ret    

80106e56 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e56:	55                   	push   %ebp
80106e57:	89 e5                	mov    %esp,%ebp
80106e59:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e63:	e9 c3 00 00 00       	jmp    80106f2b <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e6b:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106e72:	89 c2                	mov    %eax,%edx
80106e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e77:	66 89 14 c5 00 05 12 	mov    %dx,-0x7fedfb00(,%eax,8)
80106e7e:	80 
80106e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e82:	66 c7 04 c5 02 05 12 	movw   $0x8,-0x7fedfafe(,%eax,8)
80106e89:	80 08 00 
80106e8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e8f:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106e96:	80 
80106e97:	83 e2 e0             	and    $0xffffffe0,%edx
80106e9a:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ea1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea4:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106eab:	80 
80106eac:	83 e2 1f             	and    $0x1f,%edx
80106eaf:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb9:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ec0:	80 
80106ec1:	83 e2 f0             	and    $0xfffffff0,%edx
80106ec4:	83 ca 0e             	or     $0xe,%edx
80106ec7:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ece:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed1:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ed8:	80 
80106ed9:	83 e2 ef             	and    $0xffffffef,%edx
80106edc:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ee3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ee6:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106eed:	80 
80106eee:	83 e2 9f             	and    $0xffffff9f,%edx
80106ef1:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ef8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efb:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f02:	80 
80106f03:	83 ca 80             	or     $0xffffff80,%edx
80106f06:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f10:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f17:	c1 e8 10             	shr    $0x10,%eax
80106f1a:	89 c2                	mov    %eax,%edx
80106f1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1f:	66 89 14 c5 06 05 12 	mov    %dx,-0x7fedfafa(,%eax,8)
80106f26:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f27:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f2b:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f32:	0f 8e 30 ff ff ff    	jle    80106e68 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f38:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f3d:	66 a3 00 07 12 80    	mov    %ax,0x80120700
80106f43:	66 c7 05 02 07 12 80 	movw   $0x8,0x80120702
80106f4a:	08 00 
80106f4c:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f53:	83 e0 e0             	and    $0xffffffe0,%eax
80106f56:	a2 04 07 12 80       	mov    %al,0x80120704
80106f5b:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f62:	83 e0 1f             	and    $0x1f,%eax
80106f65:	a2 04 07 12 80       	mov    %al,0x80120704
80106f6a:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f71:	83 c8 0f             	or     $0xf,%eax
80106f74:	a2 05 07 12 80       	mov    %al,0x80120705
80106f79:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f80:	83 e0 ef             	and    $0xffffffef,%eax
80106f83:	a2 05 07 12 80       	mov    %al,0x80120705
80106f88:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f8f:	83 c8 60             	or     $0x60,%eax
80106f92:	a2 05 07 12 80       	mov    %al,0x80120705
80106f97:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f9e:	83 c8 80             	or     $0xffffff80,%eax
80106fa1:	a2 05 07 12 80       	mov    %al,0x80120705
80106fa6:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106fab:	c1 e8 10             	shr    $0x10,%eax
80106fae:	66 a3 06 07 12 80    	mov    %ax,0x80120706
  
  initlock(&tickslock, "time");
80106fb4:	c7 44 24 04 f8 a1 10 	movl   $0x8010a1f8,0x4(%esp)
80106fbb:	80 
80106fbc:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106fc3:	e8 ab e7 ff ff       	call   80105773 <initlock>
}
80106fc8:	c9                   	leave  
80106fc9:	c3                   	ret    

80106fca <idtinit>:

void
idtinit(void)
{
80106fca:	55                   	push   %ebp
80106fcb:	89 e5                	mov    %esp,%ebp
80106fcd:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106fd0:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106fd7:	00 
80106fd8:	c7 04 24 00 05 12 80 	movl   $0x80120500,(%esp)
80106fdf:	e8 38 fe ff ff       	call   80106e1c <lidt>
}
80106fe4:	c9                   	leave  
80106fe5:	c3                   	ret    

80106fe6 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106fe6:	55                   	push   %ebp
80106fe7:	89 e5                	mov    %esp,%ebp
80106fe9:	57                   	push   %edi
80106fea:	56                   	push   %esi
80106feb:	53                   	push   %ebx
80106fec:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106fef:	8b 45 08             	mov    0x8(%ebp),%eax
80106ff2:	8b 40 30             	mov    0x30(%eax),%eax
80106ff5:	83 f8 40             	cmp    $0x40,%eax
80106ff8:	75 3f                	jne    80107039 <trap+0x53>
    if(proc->killed)
80106ffa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107000:	8b 40 24             	mov    0x24(%eax),%eax
80107003:	85 c0                	test   %eax,%eax
80107005:	74 05                	je     8010700c <trap+0x26>
      exit();
80107007:	e8 35 e0 ff ff       	call   80105041 <exit>
    proc->tf = tf;
8010700c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107012:	8b 55 08             	mov    0x8(%ebp),%edx
80107015:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107018:	e8 d4 ed ff ff       	call   80105df1 <syscall>
    if(proc->killed)
8010701d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107023:	8b 40 24             	mov    0x24(%eax),%eax
80107026:	85 c0                	test   %eax,%eax
80107028:	74 0a                	je     80107034 <trap+0x4e>
      exit();
8010702a:	e8 12 e0 ff ff       	call   80105041 <exit>
    return;
8010702f:	e9 c5 02 00 00       	jmp    801072f9 <trap+0x313>
80107034:	e9 c0 02 00 00       	jmp    801072f9 <trap+0x313>
  }
  switch(tf->trapno){
80107039:	8b 45 08             	mov    0x8(%ebp),%eax
8010703c:	8b 40 30             	mov    0x30(%eax),%eax
8010703f:	83 e8 0e             	sub    $0xe,%eax
80107042:	83 f8 31             	cmp    $0x31,%eax
80107045:	0f 87 54 01 00 00    	ja     8010719f <trap+0x1b9>
8010704b:	8b 04 85 f8 a2 10 80 	mov    -0x7fef5d08(,%eax,4),%eax
80107052:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107054:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010705a:	0f b6 00             	movzbl (%eax),%eax
8010705d:	84 c0                	test   %al,%al
8010705f:	75 31                	jne    80107092 <trap+0xac>
      acquire(&tickslock);
80107061:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107068:	e8 27 e7 ff ff       	call   80105794 <acquire>
      ticks++;
8010706d:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80107072:	83 c0 01             	add    $0x1,%eax
80107075:	a3 00 0d 12 80       	mov    %eax,0x80120d00
      wakeup(&ticks);
8010707a:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80107081:	e8 a6 e4 ff ff       	call   8010552c <wakeup>
      release(&tickslock);
80107086:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
8010708d:	e8 64 e7 ff ff       	call   801057f6 <release>
    }
    lapiceoi();
80107092:	e8 e0 c5 ff ff       	call   80103677 <lapiceoi>
    break;
80107097:	e9 d9 01 00 00       	jmp    80107275 <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010709c:	e8 5a bd ff ff       	call   80102dfb <ideintr>
    lapiceoi();
801070a1:	e8 d1 c5 ff ff       	call   80103677 <lapiceoi>
    break;
801070a6:	e9 ca 01 00 00       	jmp    80107275 <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070ab:	e8 96 c3 ff ff       	call   80103446 <kbdintr>
    lapiceoi();
801070b0:	e8 c2 c5 ff ff       	call   80103677 <lapiceoi>
    break;
801070b5:	e9 bb 01 00 00       	jmp    80107275 <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070ba:	e8 2f 04 00 00       	call   801074ee <uartintr>
    lapiceoi();
801070bf:	e8 b3 c5 ff ff       	call   80103677 <lapiceoi>
    break;
801070c4:	e9 ac 01 00 00       	jmp    80107275 <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070c9:	8b 45 08             	mov    0x8(%ebp),%eax
801070cc:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070cf:	8b 45 08             	mov    0x8(%ebp),%eax
801070d2:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070d6:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801070d9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070df:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070e2:	0f b6 c0             	movzbl %al,%eax
801070e5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070e9:	89 54 24 08          	mov    %edx,0x8(%esp)
801070ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801070f1:	c7 04 24 00 a2 10 80 	movl   $0x8010a200,(%esp)
801070f8:	e8 a3 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801070fd:	e8 75 c5 ff ff       	call   80103677 <lapiceoi>
    break;
80107102:	e9 6e 01 00 00       	jmp    80107275 <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
80107107:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010710d:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
80107113:	83 c2 01             	add    $0x1,%edx
80107116:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
8010711c:	e8 24 fd ff ff       	call   80106e45 <rcr2>
80107121:	05 ff 0f 00 00       	add    $0xfff,%eax
80107126:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010712b:	89 c6                	mov    %eax,%esi
8010712d:	e8 13 fd ff ff       	call   80106e45 <rcr2>
80107132:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107137:	89 c3                	mov    %eax,%ebx
80107139:	e8 07 fd ff ff       	call   80106e45 <rcr2>
8010713e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107145:	8b 52 10             	mov    0x10(%edx),%edx
80107148:	89 74 24 10          	mov    %esi,0x10(%esp)
8010714c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107150:	89 44 24 08          	mov    %eax,0x8(%esp)
80107154:	89 54 24 04          	mov    %edx,0x4(%esp)
80107158:	c7 04 24 24 a2 10 80 	movl   $0x8010a224,(%esp)
8010715f:	e8 3c 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
80107164:	e8 dc fc ff ff       	call   80106e45 <rcr2>
80107169:	89 04 24             	mov    %eax,(%esp)
8010716c:	e8 b4 21 00 00       	call   80109325 <existOnDisc>
80107171:	85 c0                	test   %eax,%eax
80107173:	74 2a                	je     8010719f <trap+0x1b9>
      cprintf("found on disk, recovering\n");
80107175:	c7 04 24 53 a2 10 80 	movl   $0x8010a253,(%esp)
8010717c:	e8 1f 92 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
80107181:	e8 bf fc ff ff       	call   80106e45 <rcr2>
80107186:	89 04 24             	mov    %eax,(%esp)
80107189:	e8 83 22 00 00       	call   80109411 <fixPage>
      cprintf("recovered!\n");
8010718e:	c7 04 24 6e a2 10 80 	movl   $0x8010a26e,(%esp)
80107195:	e8 06 92 ff ff       	call   801003a0 <cprintf>
      break;
8010719a:	e9 d6 00 00 00       	jmp    80107275 <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010719f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071a5:	85 c0                	test   %eax,%eax
801071a7:	74 11                	je     801071ba <trap+0x1d4>
801071a9:	8b 45 08             	mov    0x8(%ebp),%eax
801071ac:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071b0:	0f b7 c0             	movzwl %ax,%eax
801071b3:	83 e0 03             	and    $0x3,%eax
801071b6:	85 c0                	test   %eax,%eax
801071b8:	75 46                	jne    80107200 <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071ba:	e8 86 fc ff ff       	call   80106e45 <rcr2>
801071bf:	8b 55 08             	mov    0x8(%ebp),%edx
801071c2:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801071c5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801071cc:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071cf:	0f b6 ca             	movzbl %dl,%ecx
801071d2:	8b 55 08             	mov    0x8(%ebp),%edx
801071d5:	8b 52 30             	mov    0x30(%edx),%edx
801071d8:	89 44 24 10          	mov    %eax,0x10(%esp)
801071dc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801071e0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801071e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801071e8:	c7 04 24 7c a2 10 80 	movl   $0x8010a27c,(%esp)
801071ef:	e8 ac 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801071f4:	c7 04 24 ae a2 10 80 	movl   $0x8010a2ae,(%esp)
801071fb:	e8 3a 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107200:	e8 40 fc ff ff       	call   80106e45 <rcr2>
80107205:	89 c2                	mov    %eax,%edx
80107207:	8b 45 08             	mov    0x8(%ebp),%eax
8010720a:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010720d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107213:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107216:	0f b6 f0             	movzbl %al,%esi
80107219:	8b 45 08             	mov    0x8(%ebp),%eax
8010721c:	8b 58 34             	mov    0x34(%eax),%ebx
8010721f:	8b 45 08             	mov    0x8(%ebp),%eax
80107222:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107225:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010722b:	83 c0 6c             	add    $0x6c,%eax
8010722e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107231:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107237:	8b 40 10             	mov    0x10(%eax),%eax
8010723a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010723e:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107242:	89 74 24 14          	mov    %esi,0x14(%esp)
80107246:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010724a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010724e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80107251:	89 7c 24 08          	mov    %edi,0x8(%esp)
80107255:	89 44 24 04          	mov    %eax,0x4(%esp)
80107259:	c7 04 24 b4 a2 10 80 	movl   $0x8010a2b4,(%esp)
80107260:	e8 3b 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107265:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010726b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107272:	eb 01                	jmp    80107275 <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107274:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107275:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010727b:	85 c0                	test   %eax,%eax
8010727d:	74 24                	je     801072a3 <trap+0x2bd>
8010727f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107285:	8b 40 24             	mov    0x24(%eax),%eax
80107288:	85 c0                	test   %eax,%eax
8010728a:	74 17                	je     801072a3 <trap+0x2bd>
8010728c:	8b 45 08             	mov    0x8(%ebp),%eax
8010728f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107293:	0f b7 c0             	movzwl %ax,%eax
80107296:	83 e0 03             	and    $0x3,%eax
80107299:	83 f8 03             	cmp    $0x3,%eax
8010729c:	75 05                	jne    801072a3 <trap+0x2bd>
    exit();
8010729e:	e8 9e dd ff ff       	call   80105041 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
801072a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072a9:	85 c0                	test   %eax,%eax
801072ab:	74 1e                	je     801072cb <trap+0x2e5>
801072ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b3:	8b 40 0c             	mov    0xc(%eax),%eax
801072b6:	83 f8 04             	cmp    $0x4,%eax
801072b9:	75 10                	jne    801072cb <trap+0x2e5>
801072bb:	8b 45 08             	mov    0x8(%ebp),%eax
801072be:	8b 40 30             	mov    0x30(%eax),%eax
801072c1:	83 f8 20             	cmp    $0x20,%eax
801072c4:	75 05                	jne    801072cb <trap+0x2e5>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4) updateAge(proc); //TODO: maybe need to get proc?
    yield();
801072c6:	e8 14 e1 ff ff       	call   801053df <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072d1:	85 c0                	test   %eax,%eax
801072d3:	74 24                	je     801072f9 <trap+0x313>
801072d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072db:	8b 40 24             	mov    0x24(%eax),%eax
801072de:	85 c0                	test   %eax,%eax
801072e0:	74 17                	je     801072f9 <trap+0x313>
801072e2:	8b 45 08             	mov    0x8(%ebp),%eax
801072e5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072e9:	0f b7 c0             	movzwl %ax,%eax
801072ec:	83 e0 03             	and    $0x3,%eax
801072ef:	83 f8 03             	cmp    $0x3,%eax
801072f2:	75 05                	jne    801072f9 <trap+0x313>
    exit();
801072f4:	e8 48 dd ff ff       	call   80105041 <exit>
}
801072f9:	83 c4 3c             	add    $0x3c,%esp
801072fc:	5b                   	pop    %ebx
801072fd:	5e                   	pop    %esi
801072fe:	5f                   	pop    %edi
801072ff:	5d                   	pop    %ebp
80107300:	c3                   	ret    

80107301 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107301:	55                   	push   %ebp
80107302:	89 e5                	mov    %esp,%ebp
80107304:	83 ec 14             	sub    $0x14,%esp
80107307:	8b 45 08             	mov    0x8(%ebp),%eax
8010730a:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010730e:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107312:	89 c2                	mov    %eax,%edx
80107314:	ec                   	in     (%dx),%al
80107315:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107318:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010731c:	c9                   	leave  
8010731d:	c3                   	ret    

8010731e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010731e:	55                   	push   %ebp
8010731f:	89 e5                	mov    %esp,%ebp
80107321:	83 ec 08             	sub    $0x8,%esp
80107324:	8b 55 08             	mov    0x8(%ebp),%edx
80107327:	8b 45 0c             	mov    0xc(%ebp),%eax
8010732a:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010732e:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107331:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107335:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107339:	ee                   	out    %al,(%dx)
}
8010733a:	c9                   	leave  
8010733b:	c3                   	ret    

8010733c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
8010733c:	55                   	push   %ebp
8010733d:	89 e5                	mov    %esp,%ebp
8010733f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107342:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107349:	00 
8010734a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107351:	e8 c8 ff ff ff       	call   8010731e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107356:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
8010735d:	00 
8010735e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107365:	e8 b4 ff ff ff       	call   8010731e <outb>
  outb(COM1+0, 115200/9600);
8010736a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107371:	00 
80107372:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107379:	e8 a0 ff ff ff       	call   8010731e <outb>
  outb(COM1+1, 0);
8010737e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107385:	00 
80107386:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010738d:	e8 8c ff ff ff       	call   8010731e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107392:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107399:	00 
8010739a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073a1:	e8 78 ff ff ff       	call   8010731e <outb>
  outb(COM1+4, 0);
801073a6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073ad:	00 
801073ae:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801073b5:	e8 64 ff ff ff       	call   8010731e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801073ba:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801073c1:	00 
801073c2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073c9:	e8 50 ff ff ff       	call   8010731e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801073ce:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073d5:	e8 27 ff ff ff       	call   80107301 <inb>
801073da:	3c ff                	cmp    $0xff,%al
801073dc:	75 02                	jne    801073e0 <uartinit+0xa4>
    return;
801073de:	eb 6a                	jmp    8010744a <uartinit+0x10e>
  uart = 1;
801073e0:	c7 05 4c d6 10 80 01 	movl   $0x1,0x8010d64c
801073e7:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801073ea:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801073f1:	e8 0b ff ff ff       	call   80107301 <inb>
  inb(COM1+0);
801073f6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801073fd:	e8 ff fe ff ff       	call   80107301 <inb>
  picenable(IRQ_COM1);
80107402:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107409:	e8 3e d1 ff ff       	call   8010454c <picenable>
  ioapicenable(IRQ_COM1, 0);
8010740e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107415:	00 
80107416:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010741d:	e8 58 bc ff ff       	call   8010307a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107422:	c7 45 f4 c0 a3 10 80 	movl   $0x8010a3c0,-0xc(%ebp)
80107429:	eb 15                	jmp    80107440 <uartinit+0x104>
    uartputc(*p);
8010742b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010742e:	0f b6 00             	movzbl (%eax),%eax
80107431:	0f be c0             	movsbl %al,%eax
80107434:	89 04 24             	mov    %eax,(%esp)
80107437:	e8 10 00 00 00       	call   8010744c <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010743c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107440:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107443:	0f b6 00             	movzbl (%eax),%eax
80107446:	84 c0                	test   %al,%al
80107448:	75 e1                	jne    8010742b <uartinit+0xef>
    uartputc(*p);
}
8010744a:	c9                   	leave  
8010744b:	c3                   	ret    

8010744c <uartputc>:

void
uartputc(int c)
{
8010744c:	55                   	push   %ebp
8010744d:	89 e5                	mov    %esp,%ebp
8010744f:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107452:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80107457:	85 c0                	test   %eax,%eax
80107459:	75 02                	jne    8010745d <uartputc+0x11>
    return;
8010745b:	eb 4b                	jmp    801074a8 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010745d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107464:	eb 10                	jmp    80107476 <uartputc+0x2a>
    microdelay(10);
80107466:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010746d:	e8 2a c2 ff ff       	call   8010369c <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107472:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107476:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
8010747a:	7f 16                	jg     80107492 <uartputc+0x46>
8010747c:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107483:	e8 79 fe ff ff       	call   80107301 <inb>
80107488:	0f b6 c0             	movzbl %al,%eax
8010748b:	83 e0 20             	and    $0x20,%eax
8010748e:	85 c0                	test   %eax,%eax
80107490:	74 d4                	je     80107466 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80107492:	8b 45 08             	mov    0x8(%ebp),%eax
80107495:	0f b6 c0             	movzbl %al,%eax
80107498:	89 44 24 04          	mov    %eax,0x4(%esp)
8010749c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074a3:	e8 76 fe ff ff       	call   8010731e <outb>
}
801074a8:	c9                   	leave  
801074a9:	c3                   	ret    

801074aa <uartgetc>:

static int
uartgetc(void)
{
801074aa:	55                   	push   %ebp
801074ab:	89 e5                	mov    %esp,%ebp
801074ad:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801074b0:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
801074b5:	85 c0                	test   %eax,%eax
801074b7:	75 07                	jne    801074c0 <uartgetc+0x16>
    return -1;
801074b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074be:	eb 2c                	jmp    801074ec <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801074c0:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074c7:	e8 35 fe ff ff       	call   80107301 <inb>
801074cc:	0f b6 c0             	movzbl %al,%eax
801074cf:	83 e0 01             	and    $0x1,%eax
801074d2:	85 c0                	test   %eax,%eax
801074d4:	75 07                	jne    801074dd <uartgetc+0x33>
    return -1;
801074d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074db:	eb 0f                	jmp    801074ec <uartgetc+0x42>
  return inb(COM1+0);
801074dd:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074e4:	e8 18 fe ff ff       	call   80107301 <inb>
801074e9:	0f b6 c0             	movzbl %al,%eax
}
801074ec:	c9                   	leave  
801074ed:	c3                   	ret    

801074ee <uartintr>:

void
uartintr(void)
{
801074ee:	55                   	push   %ebp
801074ef:	89 e5                	mov    %esp,%ebp
801074f1:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801074f4:	c7 04 24 aa 74 10 80 	movl   $0x801074aa,(%esp)
801074fb:	e8 c8 92 ff ff       	call   801007c8 <consoleintr>
}
80107500:	c9                   	leave  
80107501:	c3                   	ret    

80107502 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107502:	6a 00                	push   $0x0
  pushl $0
80107504:	6a 00                	push   $0x0
  jmp alltraps
80107506:	e9 e6 f8 ff ff       	jmp    80106df1 <alltraps>

8010750b <vector1>:
.globl vector1
vector1:
  pushl $0
8010750b:	6a 00                	push   $0x0
  pushl $1
8010750d:	6a 01                	push   $0x1
  jmp alltraps
8010750f:	e9 dd f8 ff ff       	jmp    80106df1 <alltraps>

80107514 <vector2>:
.globl vector2
vector2:
  pushl $0
80107514:	6a 00                	push   $0x0
  pushl $2
80107516:	6a 02                	push   $0x2
  jmp alltraps
80107518:	e9 d4 f8 ff ff       	jmp    80106df1 <alltraps>

8010751d <vector3>:
.globl vector3
vector3:
  pushl $0
8010751d:	6a 00                	push   $0x0
  pushl $3
8010751f:	6a 03                	push   $0x3
  jmp alltraps
80107521:	e9 cb f8 ff ff       	jmp    80106df1 <alltraps>

80107526 <vector4>:
.globl vector4
vector4:
  pushl $0
80107526:	6a 00                	push   $0x0
  pushl $4
80107528:	6a 04                	push   $0x4
  jmp alltraps
8010752a:	e9 c2 f8 ff ff       	jmp    80106df1 <alltraps>

8010752f <vector5>:
.globl vector5
vector5:
  pushl $0
8010752f:	6a 00                	push   $0x0
  pushl $5
80107531:	6a 05                	push   $0x5
  jmp alltraps
80107533:	e9 b9 f8 ff ff       	jmp    80106df1 <alltraps>

80107538 <vector6>:
.globl vector6
vector6:
  pushl $0
80107538:	6a 00                	push   $0x0
  pushl $6
8010753a:	6a 06                	push   $0x6
  jmp alltraps
8010753c:	e9 b0 f8 ff ff       	jmp    80106df1 <alltraps>

80107541 <vector7>:
.globl vector7
vector7:
  pushl $0
80107541:	6a 00                	push   $0x0
  pushl $7
80107543:	6a 07                	push   $0x7
  jmp alltraps
80107545:	e9 a7 f8 ff ff       	jmp    80106df1 <alltraps>

8010754a <vector8>:
.globl vector8
vector8:
  pushl $8
8010754a:	6a 08                	push   $0x8
  jmp alltraps
8010754c:	e9 a0 f8 ff ff       	jmp    80106df1 <alltraps>

80107551 <vector9>:
.globl vector9
vector9:
  pushl $0
80107551:	6a 00                	push   $0x0
  pushl $9
80107553:	6a 09                	push   $0x9
  jmp alltraps
80107555:	e9 97 f8 ff ff       	jmp    80106df1 <alltraps>

8010755a <vector10>:
.globl vector10
vector10:
  pushl $10
8010755a:	6a 0a                	push   $0xa
  jmp alltraps
8010755c:	e9 90 f8 ff ff       	jmp    80106df1 <alltraps>

80107561 <vector11>:
.globl vector11
vector11:
  pushl $11
80107561:	6a 0b                	push   $0xb
  jmp alltraps
80107563:	e9 89 f8 ff ff       	jmp    80106df1 <alltraps>

80107568 <vector12>:
.globl vector12
vector12:
  pushl $12
80107568:	6a 0c                	push   $0xc
  jmp alltraps
8010756a:	e9 82 f8 ff ff       	jmp    80106df1 <alltraps>

8010756f <vector13>:
.globl vector13
vector13:
  pushl $13
8010756f:	6a 0d                	push   $0xd
  jmp alltraps
80107571:	e9 7b f8 ff ff       	jmp    80106df1 <alltraps>

80107576 <vector14>:
.globl vector14
vector14:
  pushl $14
80107576:	6a 0e                	push   $0xe
  jmp alltraps
80107578:	e9 74 f8 ff ff       	jmp    80106df1 <alltraps>

8010757d <vector15>:
.globl vector15
vector15:
  pushl $0
8010757d:	6a 00                	push   $0x0
  pushl $15
8010757f:	6a 0f                	push   $0xf
  jmp alltraps
80107581:	e9 6b f8 ff ff       	jmp    80106df1 <alltraps>

80107586 <vector16>:
.globl vector16
vector16:
  pushl $0
80107586:	6a 00                	push   $0x0
  pushl $16
80107588:	6a 10                	push   $0x10
  jmp alltraps
8010758a:	e9 62 f8 ff ff       	jmp    80106df1 <alltraps>

8010758f <vector17>:
.globl vector17
vector17:
  pushl $17
8010758f:	6a 11                	push   $0x11
  jmp alltraps
80107591:	e9 5b f8 ff ff       	jmp    80106df1 <alltraps>

80107596 <vector18>:
.globl vector18
vector18:
  pushl $0
80107596:	6a 00                	push   $0x0
  pushl $18
80107598:	6a 12                	push   $0x12
  jmp alltraps
8010759a:	e9 52 f8 ff ff       	jmp    80106df1 <alltraps>

8010759f <vector19>:
.globl vector19
vector19:
  pushl $0
8010759f:	6a 00                	push   $0x0
  pushl $19
801075a1:	6a 13                	push   $0x13
  jmp alltraps
801075a3:	e9 49 f8 ff ff       	jmp    80106df1 <alltraps>

801075a8 <vector20>:
.globl vector20
vector20:
  pushl $0
801075a8:	6a 00                	push   $0x0
  pushl $20
801075aa:	6a 14                	push   $0x14
  jmp alltraps
801075ac:	e9 40 f8 ff ff       	jmp    80106df1 <alltraps>

801075b1 <vector21>:
.globl vector21
vector21:
  pushl $0
801075b1:	6a 00                	push   $0x0
  pushl $21
801075b3:	6a 15                	push   $0x15
  jmp alltraps
801075b5:	e9 37 f8 ff ff       	jmp    80106df1 <alltraps>

801075ba <vector22>:
.globl vector22
vector22:
  pushl $0
801075ba:	6a 00                	push   $0x0
  pushl $22
801075bc:	6a 16                	push   $0x16
  jmp alltraps
801075be:	e9 2e f8 ff ff       	jmp    80106df1 <alltraps>

801075c3 <vector23>:
.globl vector23
vector23:
  pushl $0
801075c3:	6a 00                	push   $0x0
  pushl $23
801075c5:	6a 17                	push   $0x17
  jmp alltraps
801075c7:	e9 25 f8 ff ff       	jmp    80106df1 <alltraps>

801075cc <vector24>:
.globl vector24
vector24:
  pushl $0
801075cc:	6a 00                	push   $0x0
  pushl $24
801075ce:	6a 18                	push   $0x18
  jmp alltraps
801075d0:	e9 1c f8 ff ff       	jmp    80106df1 <alltraps>

801075d5 <vector25>:
.globl vector25
vector25:
  pushl $0
801075d5:	6a 00                	push   $0x0
  pushl $25
801075d7:	6a 19                	push   $0x19
  jmp alltraps
801075d9:	e9 13 f8 ff ff       	jmp    80106df1 <alltraps>

801075de <vector26>:
.globl vector26
vector26:
  pushl $0
801075de:	6a 00                	push   $0x0
  pushl $26
801075e0:	6a 1a                	push   $0x1a
  jmp alltraps
801075e2:	e9 0a f8 ff ff       	jmp    80106df1 <alltraps>

801075e7 <vector27>:
.globl vector27
vector27:
  pushl $0
801075e7:	6a 00                	push   $0x0
  pushl $27
801075e9:	6a 1b                	push   $0x1b
  jmp alltraps
801075eb:	e9 01 f8 ff ff       	jmp    80106df1 <alltraps>

801075f0 <vector28>:
.globl vector28
vector28:
  pushl $0
801075f0:	6a 00                	push   $0x0
  pushl $28
801075f2:	6a 1c                	push   $0x1c
  jmp alltraps
801075f4:	e9 f8 f7 ff ff       	jmp    80106df1 <alltraps>

801075f9 <vector29>:
.globl vector29
vector29:
  pushl $0
801075f9:	6a 00                	push   $0x0
  pushl $29
801075fb:	6a 1d                	push   $0x1d
  jmp alltraps
801075fd:	e9 ef f7 ff ff       	jmp    80106df1 <alltraps>

80107602 <vector30>:
.globl vector30
vector30:
  pushl $0
80107602:	6a 00                	push   $0x0
  pushl $30
80107604:	6a 1e                	push   $0x1e
  jmp alltraps
80107606:	e9 e6 f7 ff ff       	jmp    80106df1 <alltraps>

8010760b <vector31>:
.globl vector31
vector31:
  pushl $0
8010760b:	6a 00                	push   $0x0
  pushl $31
8010760d:	6a 1f                	push   $0x1f
  jmp alltraps
8010760f:	e9 dd f7 ff ff       	jmp    80106df1 <alltraps>

80107614 <vector32>:
.globl vector32
vector32:
  pushl $0
80107614:	6a 00                	push   $0x0
  pushl $32
80107616:	6a 20                	push   $0x20
  jmp alltraps
80107618:	e9 d4 f7 ff ff       	jmp    80106df1 <alltraps>

8010761d <vector33>:
.globl vector33
vector33:
  pushl $0
8010761d:	6a 00                	push   $0x0
  pushl $33
8010761f:	6a 21                	push   $0x21
  jmp alltraps
80107621:	e9 cb f7 ff ff       	jmp    80106df1 <alltraps>

80107626 <vector34>:
.globl vector34
vector34:
  pushl $0
80107626:	6a 00                	push   $0x0
  pushl $34
80107628:	6a 22                	push   $0x22
  jmp alltraps
8010762a:	e9 c2 f7 ff ff       	jmp    80106df1 <alltraps>

8010762f <vector35>:
.globl vector35
vector35:
  pushl $0
8010762f:	6a 00                	push   $0x0
  pushl $35
80107631:	6a 23                	push   $0x23
  jmp alltraps
80107633:	e9 b9 f7 ff ff       	jmp    80106df1 <alltraps>

80107638 <vector36>:
.globl vector36
vector36:
  pushl $0
80107638:	6a 00                	push   $0x0
  pushl $36
8010763a:	6a 24                	push   $0x24
  jmp alltraps
8010763c:	e9 b0 f7 ff ff       	jmp    80106df1 <alltraps>

80107641 <vector37>:
.globl vector37
vector37:
  pushl $0
80107641:	6a 00                	push   $0x0
  pushl $37
80107643:	6a 25                	push   $0x25
  jmp alltraps
80107645:	e9 a7 f7 ff ff       	jmp    80106df1 <alltraps>

8010764a <vector38>:
.globl vector38
vector38:
  pushl $0
8010764a:	6a 00                	push   $0x0
  pushl $38
8010764c:	6a 26                	push   $0x26
  jmp alltraps
8010764e:	e9 9e f7 ff ff       	jmp    80106df1 <alltraps>

80107653 <vector39>:
.globl vector39
vector39:
  pushl $0
80107653:	6a 00                	push   $0x0
  pushl $39
80107655:	6a 27                	push   $0x27
  jmp alltraps
80107657:	e9 95 f7 ff ff       	jmp    80106df1 <alltraps>

8010765c <vector40>:
.globl vector40
vector40:
  pushl $0
8010765c:	6a 00                	push   $0x0
  pushl $40
8010765e:	6a 28                	push   $0x28
  jmp alltraps
80107660:	e9 8c f7 ff ff       	jmp    80106df1 <alltraps>

80107665 <vector41>:
.globl vector41
vector41:
  pushl $0
80107665:	6a 00                	push   $0x0
  pushl $41
80107667:	6a 29                	push   $0x29
  jmp alltraps
80107669:	e9 83 f7 ff ff       	jmp    80106df1 <alltraps>

8010766e <vector42>:
.globl vector42
vector42:
  pushl $0
8010766e:	6a 00                	push   $0x0
  pushl $42
80107670:	6a 2a                	push   $0x2a
  jmp alltraps
80107672:	e9 7a f7 ff ff       	jmp    80106df1 <alltraps>

80107677 <vector43>:
.globl vector43
vector43:
  pushl $0
80107677:	6a 00                	push   $0x0
  pushl $43
80107679:	6a 2b                	push   $0x2b
  jmp alltraps
8010767b:	e9 71 f7 ff ff       	jmp    80106df1 <alltraps>

80107680 <vector44>:
.globl vector44
vector44:
  pushl $0
80107680:	6a 00                	push   $0x0
  pushl $44
80107682:	6a 2c                	push   $0x2c
  jmp alltraps
80107684:	e9 68 f7 ff ff       	jmp    80106df1 <alltraps>

80107689 <vector45>:
.globl vector45
vector45:
  pushl $0
80107689:	6a 00                	push   $0x0
  pushl $45
8010768b:	6a 2d                	push   $0x2d
  jmp alltraps
8010768d:	e9 5f f7 ff ff       	jmp    80106df1 <alltraps>

80107692 <vector46>:
.globl vector46
vector46:
  pushl $0
80107692:	6a 00                	push   $0x0
  pushl $46
80107694:	6a 2e                	push   $0x2e
  jmp alltraps
80107696:	e9 56 f7 ff ff       	jmp    80106df1 <alltraps>

8010769b <vector47>:
.globl vector47
vector47:
  pushl $0
8010769b:	6a 00                	push   $0x0
  pushl $47
8010769d:	6a 2f                	push   $0x2f
  jmp alltraps
8010769f:	e9 4d f7 ff ff       	jmp    80106df1 <alltraps>

801076a4 <vector48>:
.globl vector48
vector48:
  pushl $0
801076a4:	6a 00                	push   $0x0
  pushl $48
801076a6:	6a 30                	push   $0x30
  jmp alltraps
801076a8:	e9 44 f7 ff ff       	jmp    80106df1 <alltraps>

801076ad <vector49>:
.globl vector49
vector49:
  pushl $0
801076ad:	6a 00                	push   $0x0
  pushl $49
801076af:	6a 31                	push   $0x31
  jmp alltraps
801076b1:	e9 3b f7 ff ff       	jmp    80106df1 <alltraps>

801076b6 <vector50>:
.globl vector50
vector50:
  pushl $0
801076b6:	6a 00                	push   $0x0
  pushl $50
801076b8:	6a 32                	push   $0x32
  jmp alltraps
801076ba:	e9 32 f7 ff ff       	jmp    80106df1 <alltraps>

801076bf <vector51>:
.globl vector51
vector51:
  pushl $0
801076bf:	6a 00                	push   $0x0
  pushl $51
801076c1:	6a 33                	push   $0x33
  jmp alltraps
801076c3:	e9 29 f7 ff ff       	jmp    80106df1 <alltraps>

801076c8 <vector52>:
.globl vector52
vector52:
  pushl $0
801076c8:	6a 00                	push   $0x0
  pushl $52
801076ca:	6a 34                	push   $0x34
  jmp alltraps
801076cc:	e9 20 f7 ff ff       	jmp    80106df1 <alltraps>

801076d1 <vector53>:
.globl vector53
vector53:
  pushl $0
801076d1:	6a 00                	push   $0x0
  pushl $53
801076d3:	6a 35                	push   $0x35
  jmp alltraps
801076d5:	e9 17 f7 ff ff       	jmp    80106df1 <alltraps>

801076da <vector54>:
.globl vector54
vector54:
  pushl $0
801076da:	6a 00                	push   $0x0
  pushl $54
801076dc:	6a 36                	push   $0x36
  jmp alltraps
801076de:	e9 0e f7 ff ff       	jmp    80106df1 <alltraps>

801076e3 <vector55>:
.globl vector55
vector55:
  pushl $0
801076e3:	6a 00                	push   $0x0
  pushl $55
801076e5:	6a 37                	push   $0x37
  jmp alltraps
801076e7:	e9 05 f7 ff ff       	jmp    80106df1 <alltraps>

801076ec <vector56>:
.globl vector56
vector56:
  pushl $0
801076ec:	6a 00                	push   $0x0
  pushl $56
801076ee:	6a 38                	push   $0x38
  jmp alltraps
801076f0:	e9 fc f6 ff ff       	jmp    80106df1 <alltraps>

801076f5 <vector57>:
.globl vector57
vector57:
  pushl $0
801076f5:	6a 00                	push   $0x0
  pushl $57
801076f7:	6a 39                	push   $0x39
  jmp alltraps
801076f9:	e9 f3 f6 ff ff       	jmp    80106df1 <alltraps>

801076fe <vector58>:
.globl vector58
vector58:
  pushl $0
801076fe:	6a 00                	push   $0x0
  pushl $58
80107700:	6a 3a                	push   $0x3a
  jmp alltraps
80107702:	e9 ea f6 ff ff       	jmp    80106df1 <alltraps>

80107707 <vector59>:
.globl vector59
vector59:
  pushl $0
80107707:	6a 00                	push   $0x0
  pushl $59
80107709:	6a 3b                	push   $0x3b
  jmp alltraps
8010770b:	e9 e1 f6 ff ff       	jmp    80106df1 <alltraps>

80107710 <vector60>:
.globl vector60
vector60:
  pushl $0
80107710:	6a 00                	push   $0x0
  pushl $60
80107712:	6a 3c                	push   $0x3c
  jmp alltraps
80107714:	e9 d8 f6 ff ff       	jmp    80106df1 <alltraps>

80107719 <vector61>:
.globl vector61
vector61:
  pushl $0
80107719:	6a 00                	push   $0x0
  pushl $61
8010771b:	6a 3d                	push   $0x3d
  jmp alltraps
8010771d:	e9 cf f6 ff ff       	jmp    80106df1 <alltraps>

80107722 <vector62>:
.globl vector62
vector62:
  pushl $0
80107722:	6a 00                	push   $0x0
  pushl $62
80107724:	6a 3e                	push   $0x3e
  jmp alltraps
80107726:	e9 c6 f6 ff ff       	jmp    80106df1 <alltraps>

8010772b <vector63>:
.globl vector63
vector63:
  pushl $0
8010772b:	6a 00                	push   $0x0
  pushl $63
8010772d:	6a 3f                	push   $0x3f
  jmp alltraps
8010772f:	e9 bd f6 ff ff       	jmp    80106df1 <alltraps>

80107734 <vector64>:
.globl vector64
vector64:
  pushl $0
80107734:	6a 00                	push   $0x0
  pushl $64
80107736:	6a 40                	push   $0x40
  jmp alltraps
80107738:	e9 b4 f6 ff ff       	jmp    80106df1 <alltraps>

8010773d <vector65>:
.globl vector65
vector65:
  pushl $0
8010773d:	6a 00                	push   $0x0
  pushl $65
8010773f:	6a 41                	push   $0x41
  jmp alltraps
80107741:	e9 ab f6 ff ff       	jmp    80106df1 <alltraps>

80107746 <vector66>:
.globl vector66
vector66:
  pushl $0
80107746:	6a 00                	push   $0x0
  pushl $66
80107748:	6a 42                	push   $0x42
  jmp alltraps
8010774a:	e9 a2 f6 ff ff       	jmp    80106df1 <alltraps>

8010774f <vector67>:
.globl vector67
vector67:
  pushl $0
8010774f:	6a 00                	push   $0x0
  pushl $67
80107751:	6a 43                	push   $0x43
  jmp alltraps
80107753:	e9 99 f6 ff ff       	jmp    80106df1 <alltraps>

80107758 <vector68>:
.globl vector68
vector68:
  pushl $0
80107758:	6a 00                	push   $0x0
  pushl $68
8010775a:	6a 44                	push   $0x44
  jmp alltraps
8010775c:	e9 90 f6 ff ff       	jmp    80106df1 <alltraps>

80107761 <vector69>:
.globl vector69
vector69:
  pushl $0
80107761:	6a 00                	push   $0x0
  pushl $69
80107763:	6a 45                	push   $0x45
  jmp alltraps
80107765:	e9 87 f6 ff ff       	jmp    80106df1 <alltraps>

8010776a <vector70>:
.globl vector70
vector70:
  pushl $0
8010776a:	6a 00                	push   $0x0
  pushl $70
8010776c:	6a 46                	push   $0x46
  jmp alltraps
8010776e:	e9 7e f6 ff ff       	jmp    80106df1 <alltraps>

80107773 <vector71>:
.globl vector71
vector71:
  pushl $0
80107773:	6a 00                	push   $0x0
  pushl $71
80107775:	6a 47                	push   $0x47
  jmp alltraps
80107777:	e9 75 f6 ff ff       	jmp    80106df1 <alltraps>

8010777c <vector72>:
.globl vector72
vector72:
  pushl $0
8010777c:	6a 00                	push   $0x0
  pushl $72
8010777e:	6a 48                	push   $0x48
  jmp alltraps
80107780:	e9 6c f6 ff ff       	jmp    80106df1 <alltraps>

80107785 <vector73>:
.globl vector73
vector73:
  pushl $0
80107785:	6a 00                	push   $0x0
  pushl $73
80107787:	6a 49                	push   $0x49
  jmp alltraps
80107789:	e9 63 f6 ff ff       	jmp    80106df1 <alltraps>

8010778e <vector74>:
.globl vector74
vector74:
  pushl $0
8010778e:	6a 00                	push   $0x0
  pushl $74
80107790:	6a 4a                	push   $0x4a
  jmp alltraps
80107792:	e9 5a f6 ff ff       	jmp    80106df1 <alltraps>

80107797 <vector75>:
.globl vector75
vector75:
  pushl $0
80107797:	6a 00                	push   $0x0
  pushl $75
80107799:	6a 4b                	push   $0x4b
  jmp alltraps
8010779b:	e9 51 f6 ff ff       	jmp    80106df1 <alltraps>

801077a0 <vector76>:
.globl vector76
vector76:
  pushl $0
801077a0:	6a 00                	push   $0x0
  pushl $76
801077a2:	6a 4c                	push   $0x4c
  jmp alltraps
801077a4:	e9 48 f6 ff ff       	jmp    80106df1 <alltraps>

801077a9 <vector77>:
.globl vector77
vector77:
  pushl $0
801077a9:	6a 00                	push   $0x0
  pushl $77
801077ab:	6a 4d                	push   $0x4d
  jmp alltraps
801077ad:	e9 3f f6 ff ff       	jmp    80106df1 <alltraps>

801077b2 <vector78>:
.globl vector78
vector78:
  pushl $0
801077b2:	6a 00                	push   $0x0
  pushl $78
801077b4:	6a 4e                	push   $0x4e
  jmp alltraps
801077b6:	e9 36 f6 ff ff       	jmp    80106df1 <alltraps>

801077bb <vector79>:
.globl vector79
vector79:
  pushl $0
801077bb:	6a 00                	push   $0x0
  pushl $79
801077bd:	6a 4f                	push   $0x4f
  jmp alltraps
801077bf:	e9 2d f6 ff ff       	jmp    80106df1 <alltraps>

801077c4 <vector80>:
.globl vector80
vector80:
  pushl $0
801077c4:	6a 00                	push   $0x0
  pushl $80
801077c6:	6a 50                	push   $0x50
  jmp alltraps
801077c8:	e9 24 f6 ff ff       	jmp    80106df1 <alltraps>

801077cd <vector81>:
.globl vector81
vector81:
  pushl $0
801077cd:	6a 00                	push   $0x0
  pushl $81
801077cf:	6a 51                	push   $0x51
  jmp alltraps
801077d1:	e9 1b f6 ff ff       	jmp    80106df1 <alltraps>

801077d6 <vector82>:
.globl vector82
vector82:
  pushl $0
801077d6:	6a 00                	push   $0x0
  pushl $82
801077d8:	6a 52                	push   $0x52
  jmp alltraps
801077da:	e9 12 f6 ff ff       	jmp    80106df1 <alltraps>

801077df <vector83>:
.globl vector83
vector83:
  pushl $0
801077df:	6a 00                	push   $0x0
  pushl $83
801077e1:	6a 53                	push   $0x53
  jmp alltraps
801077e3:	e9 09 f6 ff ff       	jmp    80106df1 <alltraps>

801077e8 <vector84>:
.globl vector84
vector84:
  pushl $0
801077e8:	6a 00                	push   $0x0
  pushl $84
801077ea:	6a 54                	push   $0x54
  jmp alltraps
801077ec:	e9 00 f6 ff ff       	jmp    80106df1 <alltraps>

801077f1 <vector85>:
.globl vector85
vector85:
  pushl $0
801077f1:	6a 00                	push   $0x0
  pushl $85
801077f3:	6a 55                	push   $0x55
  jmp alltraps
801077f5:	e9 f7 f5 ff ff       	jmp    80106df1 <alltraps>

801077fa <vector86>:
.globl vector86
vector86:
  pushl $0
801077fa:	6a 00                	push   $0x0
  pushl $86
801077fc:	6a 56                	push   $0x56
  jmp alltraps
801077fe:	e9 ee f5 ff ff       	jmp    80106df1 <alltraps>

80107803 <vector87>:
.globl vector87
vector87:
  pushl $0
80107803:	6a 00                	push   $0x0
  pushl $87
80107805:	6a 57                	push   $0x57
  jmp alltraps
80107807:	e9 e5 f5 ff ff       	jmp    80106df1 <alltraps>

8010780c <vector88>:
.globl vector88
vector88:
  pushl $0
8010780c:	6a 00                	push   $0x0
  pushl $88
8010780e:	6a 58                	push   $0x58
  jmp alltraps
80107810:	e9 dc f5 ff ff       	jmp    80106df1 <alltraps>

80107815 <vector89>:
.globl vector89
vector89:
  pushl $0
80107815:	6a 00                	push   $0x0
  pushl $89
80107817:	6a 59                	push   $0x59
  jmp alltraps
80107819:	e9 d3 f5 ff ff       	jmp    80106df1 <alltraps>

8010781e <vector90>:
.globl vector90
vector90:
  pushl $0
8010781e:	6a 00                	push   $0x0
  pushl $90
80107820:	6a 5a                	push   $0x5a
  jmp alltraps
80107822:	e9 ca f5 ff ff       	jmp    80106df1 <alltraps>

80107827 <vector91>:
.globl vector91
vector91:
  pushl $0
80107827:	6a 00                	push   $0x0
  pushl $91
80107829:	6a 5b                	push   $0x5b
  jmp alltraps
8010782b:	e9 c1 f5 ff ff       	jmp    80106df1 <alltraps>

80107830 <vector92>:
.globl vector92
vector92:
  pushl $0
80107830:	6a 00                	push   $0x0
  pushl $92
80107832:	6a 5c                	push   $0x5c
  jmp alltraps
80107834:	e9 b8 f5 ff ff       	jmp    80106df1 <alltraps>

80107839 <vector93>:
.globl vector93
vector93:
  pushl $0
80107839:	6a 00                	push   $0x0
  pushl $93
8010783b:	6a 5d                	push   $0x5d
  jmp alltraps
8010783d:	e9 af f5 ff ff       	jmp    80106df1 <alltraps>

80107842 <vector94>:
.globl vector94
vector94:
  pushl $0
80107842:	6a 00                	push   $0x0
  pushl $94
80107844:	6a 5e                	push   $0x5e
  jmp alltraps
80107846:	e9 a6 f5 ff ff       	jmp    80106df1 <alltraps>

8010784b <vector95>:
.globl vector95
vector95:
  pushl $0
8010784b:	6a 00                	push   $0x0
  pushl $95
8010784d:	6a 5f                	push   $0x5f
  jmp alltraps
8010784f:	e9 9d f5 ff ff       	jmp    80106df1 <alltraps>

80107854 <vector96>:
.globl vector96
vector96:
  pushl $0
80107854:	6a 00                	push   $0x0
  pushl $96
80107856:	6a 60                	push   $0x60
  jmp alltraps
80107858:	e9 94 f5 ff ff       	jmp    80106df1 <alltraps>

8010785d <vector97>:
.globl vector97
vector97:
  pushl $0
8010785d:	6a 00                	push   $0x0
  pushl $97
8010785f:	6a 61                	push   $0x61
  jmp alltraps
80107861:	e9 8b f5 ff ff       	jmp    80106df1 <alltraps>

80107866 <vector98>:
.globl vector98
vector98:
  pushl $0
80107866:	6a 00                	push   $0x0
  pushl $98
80107868:	6a 62                	push   $0x62
  jmp alltraps
8010786a:	e9 82 f5 ff ff       	jmp    80106df1 <alltraps>

8010786f <vector99>:
.globl vector99
vector99:
  pushl $0
8010786f:	6a 00                	push   $0x0
  pushl $99
80107871:	6a 63                	push   $0x63
  jmp alltraps
80107873:	e9 79 f5 ff ff       	jmp    80106df1 <alltraps>

80107878 <vector100>:
.globl vector100
vector100:
  pushl $0
80107878:	6a 00                	push   $0x0
  pushl $100
8010787a:	6a 64                	push   $0x64
  jmp alltraps
8010787c:	e9 70 f5 ff ff       	jmp    80106df1 <alltraps>

80107881 <vector101>:
.globl vector101
vector101:
  pushl $0
80107881:	6a 00                	push   $0x0
  pushl $101
80107883:	6a 65                	push   $0x65
  jmp alltraps
80107885:	e9 67 f5 ff ff       	jmp    80106df1 <alltraps>

8010788a <vector102>:
.globl vector102
vector102:
  pushl $0
8010788a:	6a 00                	push   $0x0
  pushl $102
8010788c:	6a 66                	push   $0x66
  jmp alltraps
8010788e:	e9 5e f5 ff ff       	jmp    80106df1 <alltraps>

80107893 <vector103>:
.globl vector103
vector103:
  pushl $0
80107893:	6a 00                	push   $0x0
  pushl $103
80107895:	6a 67                	push   $0x67
  jmp alltraps
80107897:	e9 55 f5 ff ff       	jmp    80106df1 <alltraps>

8010789c <vector104>:
.globl vector104
vector104:
  pushl $0
8010789c:	6a 00                	push   $0x0
  pushl $104
8010789e:	6a 68                	push   $0x68
  jmp alltraps
801078a0:	e9 4c f5 ff ff       	jmp    80106df1 <alltraps>

801078a5 <vector105>:
.globl vector105
vector105:
  pushl $0
801078a5:	6a 00                	push   $0x0
  pushl $105
801078a7:	6a 69                	push   $0x69
  jmp alltraps
801078a9:	e9 43 f5 ff ff       	jmp    80106df1 <alltraps>

801078ae <vector106>:
.globl vector106
vector106:
  pushl $0
801078ae:	6a 00                	push   $0x0
  pushl $106
801078b0:	6a 6a                	push   $0x6a
  jmp alltraps
801078b2:	e9 3a f5 ff ff       	jmp    80106df1 <alltraps>

801078b7 <vector107>:
.globl vector107
vector107:
  pushl $0
801078b7:	6a 00                	push   $0x0
  pushl $107
801078b9:	6a 6b                	push   $0x6b
  jmp alltraps
801078bb:	e9 31 f5 ff ff       	jmp    80106df1 <alltraps>

801078c0 <vector108>:
.globl vector108
vector108:
  pushl $0
801078c0:	6a 00                	push   $0x0
  pushl $108
801078c2:	6a 6c                	push   $0x6c
  jmp alltraps
801078c4:	e9 28 f5 ff ff       	jmp    80106df1 <alltraps>

801078c9 <vector109>:
.globl vector109
vector109:
  pushl $0
801078c9:	6a 00                	push   $0x0
  pushl $109
801078cb:	6a 6d                	push   $0x6d
  jmp alltraps
801078cd:	e9 1f f5 ff ff       	jmp    80106df1 <alltraps>

801078d2 <vector110>:
.globl vector110
vector110:
  pushl $0
801078d2:	6a 00                	push   $0x0
  pushl $110
801078d4:	6a 6e                	push   $0x6e
  jmp alltraps
801078d6:	e9 16 f5 ff ff       	jmp    80106df1 <alltraps>

801078db <vector111>:
.globl vector111
vector111:
  pushl $0
801078db:	6a 00                	push   $0x0
  pushl $111
801078dd:	6a 6f                	push   $0x6f
  jmp alltraps
801078df:	e9 0d f5 ff ff       	jmp    80106df1 <alltraps>

801078e4 <vector112>:
.globl vector112
vector112:
  pushl $0
801078e4:	6a 00                	push   $0x0
  pushl $112
801078e6:	6a 70                	push   $0x70
  jmp alltraps
801078e8:	e9 04 f5 ff ff       	jmp    80106df1 <alltraps>

801078ed <vector113>:
.globl vector113
vector113:
  pushl $0
801078ed:	6a 00                	push   $0x0
  pushl $113
801078ef:	6a 71                	push   $0x71
  jmp alltraps
801078f1:	e9 fb f4 ff ff       	jmp    80106df1 <alltraps>

801078f6 <vector114>:
.globl vector114
vector114:
  pushl $0
801078f6:	6a 00                	push   $0x0
  pushl $114
801078f8:	6a 72                	push   $0x72
  jmp alltraps
801078fa:	e9 f2 f4 ff ff       	jmp    80106df1 <alltraps>

801078ff <vector115>:
.globl vector115
vector115:
  pushl $0
801078ff:	6a 00                	push   $0x0
  pushl $115
80107901:	6a 73                	push   $0x73
  jmp alltraps
80107903:	e9 e9 f4 ff ff       	jmp    80106df1 <alltraps>

80107908 <vector116>:
.globl vector116
vector116:
  pushl $0
80107908:	6a 00                	push   $0x0
  pushl $116
8010790a:	6a 74                	push   $0x74
  jmp alltraps
8010790c:	e9 e0 f4 ff ff       	jmp    80106df1 <alltraps>

80107911 <vector117>:
.globl vector117
vector117:
  pushl $0
80107911:	6a 00                	push   $0x0
  pushl $117
80107913:	6a 75                	push   $0x75
  jmp alltraps
80107915:	e9 d7 f4 ff ff       	jmp    80106df1 <alltraps>

8010791a <vector118>:
.globl vector118
vector118:
  pushl $0
8010791a:	6a 00                	push   $0x0
  pushl $118
8010791c:	6a 76                	push   $0x76
  jmp alltraps
8010791e:	e9 ce f4 ff ff       	jmp    80106df1 <alltraps>

80107923 <vector119>:
.globl vector119
vector119:
  pushl $0
80107923:	6a 00                	push   $0x0
  pushl $119
80107925:	6a 77                	push   $0x77
  jmp alltraps
80107927:	e9 c5 f4 ff ff       	jmp    80106df1 <alltraps>

8010792c <vector120>:
.globl vector120
vector120:
  pushl $0
8010792c:	6a 00                	push   $0x0
  pushl $120
8010792e:	6a 78                	push   $0x78
  jmp alltraps
80107930:	e9 bc f4 ff ff       	jmp    80106df1 <alltraps>

80107935 <vector121>:
.globl vector121
vector121:
  pushl $0
80107935:	6a 00                	push   $0x0
  pushl $121
80107937:	6a 79                	push   $0x79
  jmp alltraps
80107939:	e9 b3 f4 ff ff       	jmp    80106df1 <alltraps>

8010793e <vector122>:
.globl vector122
vector122:
  pushl $0
8010793e:	6a 00                	push   $0x0
  pushl $122
80107940:	6a 7a                	push   $0x7a
  jmp alltraps
80107942:	e9 aa f4 ff ff       	jmp    80106df1 <alltraps>

80107947 <vector123>:
.globl vector123
vector123:
  pushl $0
80107947:	6a 00                	push   $0x0
  pushl $123
80107949:	6a 7b                	push   $0x7b
  jmp alltraps
8010794b:	e9 a1 f4 ff ff       	jmp    80106df1 <alltraps>

80107950 <vector124>:
.globl vector124
vector124:
  pushl $0
80107950:	6a 00                	push   $0x0
  pushl $124
80107952:	6a 7c                	push   $0x7c
  jmp alltraps
80107954:	e9 98 f4 ff ff       	jmp    80106df1 <alltraps>

80107959 <vector125>:
.globl vector125
vector125:
  pushl $0
80107959:	6a 00                	push   $0x0
  pushl $125
8010795b:	6a 7d                	push   $0x7d
  jmp alltraps
8010795d:	e9 8f f4 ff ff       	jmp    80106df1 <alltraps>

80107962 <vector126>:
.globl vector126
vector126:
  pushl $0
80107962:	6a 00                	push   $0x0
  pushl $126
80107964:	6a 7e                	push   $0x7e
  jmp alltraps
80107966:	e9 86 f4 ff ff       	jmp    80106df1 <alltraps>

8010796b <vector127>:
.globl vector127
vector127:
  pushl $0
8010796b:	6a 00                	push   $0x0
  pushl $127
8010796d:	6a 7f                	push   $0x7f
  jmp alltraps
8010796f:	e9 7d f4 ff ff       	jmp    80106df1 <alltraps>

80107974 <vector128>:
.globl vector128
vector128:
  pushl $0
80107974:	6a 00                	push   $0x0
  pushl $128
80107976:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010797b:	e9 71 f4 ff ff       	jmp    80106df1 <alltraps>

80107980 <vector129>:
.globl vector129
vector129:
  pushl $0
80107980:	6a 00                	push   $0x0
  pushl $129
80107982:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107987:	e9 65 f4 ff ff       	jmp    80106df1 <alltraps>

8010798c <vector130>:
.globl vector130
vector130:
  pushl $0
8010798c:	6a 00                	push   $0x0
  pushl $130
8010798e:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107993:	e9 59 f4 ff ff       	jmp    80106df1 <alltraps>

80107998 <vector131>:
.globl vector131
vector131:
  pushl $0
80107998:	6a 00                	push   $0x0
  pushl $131
8010799a:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010799f:	e9 4d f4 ff ff       	jmp    80106df1 <alltraps>

801079a4 <vector132>:
.globl vector132
vector132:
  pushl $0
801079a4:	6a 00                	push   $0x0
  pushl $132
801079a6:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801079ab:	e9 41 f4 ff ff       	jmp    80106df1 <alltraps>

801079b0 <vector133>:
.globl vector133
vector133:
  pushl $0
801079b0:	6a 00                	push   $0x0
  pushl $133
801079b2:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801079b7:	e9 35 f4 ff ff       	jmp    80106df1 <alltraps>

801079bc <vector134>:
.globl vector134
vector134:
  pushl $0
801079bc:	6a 00                	push   $0x0
  pushl $134
801079be:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801079c3:	e9 29 f4 ff ff       	jmp    80106df1 <alltraps>

801079c8 <vector135>:
.globl vector135
vector135:
  pushl $0
801079c8:	6a 00                	push   $0x0
  pushl $135
801079ca:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079cf:	e9 1d f4 ff ff       	jmp    80106df1 <alltraps>

801079d4 <vector136>:
.globl vector136
vector136:
  pushl $0
801079d4:	6a 00                	push   $0x0
  pushl $136
801079d6:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801079db:	e9 11 f4 ff ff       	jmp    80106df1 <alltraps>

801079e0 <vector137>:
.globl vector137
vector137:
  pushl $0
801079e0:	6a 00                	push   $0x0
  pushl $137
801079e2:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801079e7:	e9 05 f4 ff ff       	jmp    80106df1 <alltraps>

801079ec <vector138>:
.globl vector138
vector138:
  pushl $0
801079ec:	6a 00                	push   $0x0
  pushl $138
801079ee:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801079f3:	e9 f9 f3 ff ff       	jmp    80106df1 <alltraps>

801079f8 <vector139>:
.globl vector139
vector139:
  pushl $0
801079f8:	6a 00                	push   $0x0
  pushl $139
801079fa:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801079ff:	e9 ed f3 ff ff       	jmp    80106df1 <alltraps>

80107a04 <vector140>:
.globl vector140
vector140:
  pushl $0
80107a04:	6a 00                	push   $0x0
  pushl $140
80107a06:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107a0b:	e9 e1 f3 ff ff       	jmp    80106df1 <alltraps>

80107a10 <vector141>:
.globl vector141
vector141:
  pushl $0
80107a10:	6a 00                	push   $0x0
  pushl $141
80107a12:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107a17:	e9 d5 f3 ff ff       	jmp    80106df1 <alltraps>

80107a1c <vector142>:
.globl vector142
vector142:
  pushl $0
80107a1c:	6a 00                	push   $0x0
  pushl $142
80107a1e:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107a23:	e9 c9 f3 ff ff       	jmp    80106df1 <alltraps>

80107a28 <vector143>:
.globl vector143
vector143:
  pushl $0
80107a28:	6a 00                	push   $0x0
  pushl $143
80107a2a:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a2f:	e9 bd f3 ff ff       	jmp    80106df1 <alltraps>

80107a34 <vector144>:
.globl vector144
vector144:
  pushl $0
80107a34:	6a 00                	push   $0x0
  pushl $144
80107a36:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a3b:	e9 b1 f3 ff ff       	jmp    80106df1 <alltraps>

80107a40 <vector145>:
.globl vector145
vector145:
  pushl $0
80107a40:	6a 00                	push   $0x0
  pushl $145
80107a42:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a47:	e9 a5 f3 ff ff       	jmp    80106df1 <alltraps>

80107a4c <vector146>:
.globl vector146
vector146:
  pushl $0
80107a4c:	6a 00                	push   $0x0
  pushl $146
80107a4e:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a53:	e9 99 f3 ff ff       	jmp    80106df1 <alltraps>

80107a58 <vector147>:
.globl vector147
vector147:
  pushl $0
80107a58:	6a 00                	push   $0x0
  pushl $147
80107a5a:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a5f:	e9 8d f3 ff ff       	jmp    80106df1 <alltraps>

80107a64 <vector148>:
.globl vector148
vector148:
  pushl $0
80107a64:	6a 00                	push   $0x0
  pushl $148
80107a66:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a6b:	e9 81 f3 ff ff       	jmp    80106df1 <alltraps>

80107a70 <vector149>:
.globl vector149
vector149:
  pushl $0
80107a70:	6a 00                	push   $0x0
  pushl $149
80107a72:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107a77:	e9 75 f3 ff ff       	jmp    80106df1 <alltraps>

80107a7c <vector150>:
.globl vector150
vector150:
  pushl $0
80107a7c:	6a 00                	push   $0x0
  pushl $150
80107a7e:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107a83:	e9 69 f3 ff ff       	jmp    80106df1 <alltraps>

80107a88 <vector151>:
.globl vector151
vector151:
  pushl $0
80107a88:	6a 00                	push   $0x0
  pushl $151
80107a8a:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107a8f:	e9 5d f3 ff ff       	jmp    80106df1 <alltraps>

80107a94 <vector152>:
.globl vector152
vector152:
  pushl $0
80107a94:	6a 00                	push   $0x0
  pushl $152
80107a96:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107a9b:	e9 51 f3 ff ff       	jmp    80106df1 <alltraps>

80107aa0 <vector153>:
.globl vector153
vector153:
  pushl $0
80107aa0:	6a 00                	push   $0x0
  pushl $153
80107aa2:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107aa7:	e9 45 f3 ff ff       	jmp    80106df1 <alltraps>

80107aac <vector154>:
.globl vector154
vector154:
  pushl $0
80107aac:	6a 00                	push   $0x0
  pushl $154
80107aae:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107ab3:	e9 39 f3 ff ff       	jmp    80106df1 <alltraps>

80107ab8 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ab8:	6a 00                	push   $0x0
  pushl $155
80107aba:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107abf:	e9 2d f3 ff ff       	jmp    80106df1 <alltraps>

80107ac4 <vector156>:
.globl vector156
vector156:
  pushl $0
80107ac4:	6a 00                	push   $0x0
  pushl $156
80107ac6:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107acb:	e9 21 f3 ff ff       	jmp    80106df1 <alltraps>

80107ad0 <vector157>:
.globl vector157
vector157:
  pushl $0
80107ad0:	6a 00                	push   $0x0
  pushl $157
80107ad2:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ad7:	e9 15 f3 ff ff       	jmp    80106df1 <alltraps>

80107adc <vector158>:
.globl vector158
vector158:
  pushl $0
80107adc:	6a 00                	push   $0x0
  pushl $158
80107ade:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107ae3:	e9 09 f3 ff ff       	jmp    80106df1 <alltraps>

80107ae8 <vector159>:
.globl vector159
vector159:
  pushl $0
80107ae8:	6a 00                	push   $0x0
  pushl $159
80107aea:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107aef:	e9 fd f2 ff ff       	jmp    80106df1 <alltraps>

80107af4 <vector160>:
.globl vector160
vector160:
  pushl $0
80107af4:	6a 00                	push   $0x0
  pushl $160
80107af6:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107afb:	e9 f1 f2 ff ff       	jmp    80106df1 <alltraps>

80107b00 <vector161>:
.globl vector161
vector161:
  pushl $0
80107b00:	6a 00                	push   $0x0
  pushl $161
80107b02:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107b07:	e9 e5 f2 ff ff       	jmp    80106df1 <alltraps>

80107b0c <vector162>:
.globl vector162
vector162:
  pushl $0
80107b0c:	6a 00                	push   $0x0
  pushl $162
80107b0e:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107b13:	e9 d9 f2 ff ff       	jmp    80106df1 <alltraps>

80107b18 <vector163>:
.globl vector163
vector163:
  pushl $0
80107b18:	6a 00                	push   $0x0
  pushl $163
80107b1a:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107b1f:	e9 cd f2 ff ff       	jmp    80106df1 <alltraps>

80107b24 <vector164>:
.globl vector164
vector164:
  pushl $0
80107b24:	6a 00                	push   $0x0
  pushl $164
80107b26:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b2b:	e9 c1 f2 ff ff       	jmp    80106df1 <alltraps>

80107b30 <vector165>:
.globl vector165
vector165:
  pushl $0
80107b30:	6a 00                	push   $0x0
  pushl $165
80107b32:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b37:	e9 b5 f2 ff ff       	jmp    80106df1 <alltraps>

80107b3c <vector166>:
.globl vector166
vector166:
  pushl $0
80107b3c:	6a 00                	push   $0x0
  pushl $166
80107b3e:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b43:	e9 a9 f2 ff ff       	jmp    80106df1 <alltraps>

80107b48 <vector167>:
.globl vector167
vector167:
  pushl $0
80107b48:	6a 00                	push   $0x0
  pushl $167
80107b4a:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b4f:	e9 9d f2 ff ff       	jmp    80106df1 <alltraps>

80107b54 <vector168>:
.globl vector168
vector168:
  pushl $0
80107b54:	6a 00                	push   $0x0
  pushl $168
80107b56:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b5b:	e9 91 f2 ff ff       	jmp    80106df1 <alltraps>

80107b60 <vector169>:
.globl vector169
vector169:
  pushl $0
80107b60:	6a 00                	push   $0x0
  pushl $169
80107b62:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b67:	e9 85 f2 ff ff       	jmp    80106df1 <alltraps>

80107b6c <vector170>:
.globl vector170
vector170:
  pushl $0
80107b6c:	6a 00                	push   $0x0
  pushl $170
80107b6e:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b73:	e9 79 f2 ff ff       	jmp    80106df1 <alltraps>

80107b78 <vector171>:
.globl vector171
vector171:
  pushl $0
80107b78:	6a 00                	push   $0x0
  pushl $171
80107b7a:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107b7f:	e9 6d f2 ff ff       	jmp    80106df1 <alltraps>

80107b84 <vector172>:
.globl vector172
vector172:
  pushl $0
80107b84:	6a 00                	push   $0x0
  pushl $172
80107b86:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107b8b:	e9 61 f2 ff ff       	jmp    80106df1 <alltraps>

80107b90 <vector173>:
.globl vector173
vector173:
  pushl $0
80107b90:	6a 00                	push   $0x0
  pushl $173
80107b92:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107b97:	e9 55 f2 ff ff       	jmp    80106df1 <alltraps>

80107b9c <vector174>:
.globl vector174
vector174:
  pushl $0
80107b9c:	6a 00                	push   $0x0
  pushl $174
80107b9e:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107ba3:	e9 49 f2 ff ff       	jmp    80106df1 <alltraps>

80107ba8 <vector175>:
.globl vector175
vector175:
  pushl $0
80107ba8:	6a 00                	push   $0x0
  pushl $175
80107baa:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107baf:	e9 3d f2 ff ff       	jmp    80106df1 <alltraps>

80107bb4 <vector176>:
.globl vector176
vector176:
  pushl $0
80107bb4:	6a 00                	push   $0x0
  pushl $176
80107bb6:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107bbb:	e9 31 f2 ff ff       	jmp    80106df1 <alltraps>

80107bc0 <vector177>:
.globl vector177
vector177:
  pushl $0
80107bc0:	6a 00                	push   $0x0
  pushl $177
80107bc2:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107bc7:	e9 25 f2 ff ff       	jmp    80106df1 <alltraps>

80107bcc <vector178>:
.globl vector178
vector178:
  pushl $0
80107bcc:	6a 00                	push   $0x0
  pushl $178
80107bce:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107bd3:	e9 19 f2 ff ff       	jmp    80106df1 <alltraps>

80107bd8 <vector179>:
.globl vector179
vector179:
  pushl $0
80107bd8:	6a 00                	push   $0x0
  pushl $179
80107bda:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107bdf:	e9 0d f2 ff ff       	jmp    80106df1 <alltraps>

80107be4 <vector180>:
.globl vector180
vector180:
  pushl $0
80107be4:	6a 00                	push   $0x0
  pushl $180
80107be6:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107beb:	e9 01 f2 ff ff       	jmp    80106df1 <alltraps>

80107bf0 <vector181>:
.globl vector181
vector181:
  pushl $0
80107bf0:	6a 00                	push   $0x0
  pushl $181
80107bf2:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107bf7:	e9 f5 f1 ff ff       	jmp    80106df1 <alltraps>

80107bfc <vector182>:
.globl vector182
vector182:
  pushl $0
80107bfc:	6a 00                	push   $0x0
  pushl $182
80107bfe:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107c03:	e9 e9 f1 ff ff       	jmp    80106df1 <alltraps>

80107c08 <vector183>:
.globl vector183
vector183:
  pushl $0
80107c08:	6a 00                	push   $0x0
  pushl $183
80107c0a:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107c0f:	e9 dd f1 ff ff       	jmp    80106df1 <alltraps>

80107c14 <vector184>:
.globl vector184
vector184:
  pushl $0
80107c14:	6a 00                	push   $0x0
  pushl $184
80107c16:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107c1b:	e9 d1 f1 ff ff       	jmp    80106df1 <alltraps>

80107c20 <vector185>:
.globl vector185
vector185:
  pushl $0
80107c20:	6a 00                	push   $0x0
  pushl $185
80107c22:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c27:	e9 c5 f1 ff ff       	jmp    80106df1 <alltraps>

80107c2c <vector186>:
.globl vector186
vector186:
  pushl $0
80107c2c:	6a 00                	push   $0x0
  pushl $186
80107c2e:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c33:	e9 b9 f1 ff ff       	jmp    80106df1 <alltraps>

80107c38 <vector187>:
.globl vector187
vector187:
  pushl $0
80107c38:	6a 00                	push   $0x0
  pushl $187
80107c3a:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c3f:	e9 ad f1 ff ff       	jmp    80106df1 <alltraps>

80107c44 <vector188>:
.globl vector188
vector188:
  pushl $0
80107c44:	6a 00                	push   $0x0
  pushl $188
80107c46:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c4b:	e9 a1 f1 ff ff       	jmp    80106df1 <alltraps>

80107c50 <vector189>:
.globl vector189
vector189:
  pushl $0
80107c50:	6a 00                	push   $0x0
  pushl $189
80107c52:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c57:	e9 95 f1 ff ff       	jmp    80106df1 <alltraps>

80107c5c <vector190>:
.globl vector190
vector190:
  pushl $0
80107c5c:	6a 00                	push   $0x0
  pushl $190
80107c5e:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c63:	e9 89 f1 ff ff       	jmp    80106df1 <alltraps>

80107c68 <vector191>:
.globl vector191
vector191:
  pushl $0
80107c68:	6a 00                	push   $0x0
  pushl $191
80107c6a:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c6f:	e9 7d f1 ff ff       	jmp    80106df1 <alltraps>

80107c74 <vector192>:
.globl vector192
vector192:
  pushl $0
80107c74:	6a 00                	push   $0x0
  pushl $192
80107c76:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107c7b:	e9 71 f1 ff ff       	jmp    80106df1 <alltraps>

80107c80 <vector193>:
.globl vector193
vector193:
  pushl $0
80107c80:	6a 00                	push   $0x0
  pushl $193
80107c82:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107c87:	e9 65 f1 ff ff       	jmp    80106df1 <alltraps>

80107c8c <vector194>:
.globl vector194
vector194:
  pushl $0
80107c8c:	6a 00                	push   $0x0
  pushl $194
80107c8e:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107c93:	e9 59 f1 ff ff       	jmp    80106df1 <alltraps>

80107c98 <vector195>:
.globl vector195
vector195:
  pushl $0
80107c98:	6a 00                	push   $0x0
  pushl $195
80107c9a:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107c9f:	e9 4d f1 ff ff       	jmp    80106df1 <alltraps>

80107ca4 <vector196>:
.globl vector196
vector196:
  pushl $0
80107ca4:	6a 00                	push   $0x0
  pushl $196
80107ca6:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107cab:	e9 41 f1 ff ff       	jmp    80106df1 <alltraps>

80107cb0 <vector197>:
.globl vector197
vector197:
  pushl $0
80107cb0:	6a 00                	push   $0x0
  pushl $197
80107cb2:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107cb7:	e9 35 f1 ff ff       	jmp    80106df1 <alltraps>

80107cbc <vector198>:
.globl vector198
vector198:
  pushl $0
80107cbc:	6a 00                	push   $0x0
  pushl $198
80107cbe:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107cc3:	e9 29 f1 ff ff       	jmp    80106df1 <alltraps>

80107cc8 <vector199>:
.globl vector199
vector199:
  pushl $0
80107cc8:	6a 00                	push   $0x0
  pushl $199
80107cca:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107ccf:	e9 1d f1 ff ff       	jmp    80106df1 <alltraps>

80107cd4 <vector200>:
.globl vector200
vector200:
  pushl $0
80107cd4:	6a 00                	push   $0x0
  pushl $200
80107cd6:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107cdb:	e9 11 f1 ff ff       	jmp    80106df1 <alltraps>

80107ce0 <vector201>:
.globl vector201
vector201:
  pushl $0
80107ce0:	6a 00                	push   $0x0
  pushl $201
80107ce2:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107ce7:	e9 05 f1 ff ff       	jmp    80106df1 <alltraps>

80107cec <vector202>:
.globl vector202
vector202:
  pushl $0
80107cec:	6a 00                	push   $0x0
  pushl $202
80107cee:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107cf3:	e9 f9 f0 ff ff       	jmp    80106df1 <alltraps>

80107cf8 <vector203>:
.globl vector203
vector203:
  pushl $0
80107cf8:	6a 00                	push   $0x0
  pushl $203
80107cfa:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107cff:	e9 ed f0 ff ff       	jmp    80106df1 <alltraps>

80107d04 <vector204>:
.globl vector204
vector204:
  pushl $0
80107d04:	6a 00                	push   $0x0
  pushl $204
80107d06:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107d0b:	e9 e1 f0 ff ff       	jmp    80106df1 <alltraps>

80107d10 <vector205>:
.globl vector205
vector205:
  pushl $0
80107d10:	6a 00                	push   $0x0
  pushl $205
80107d12:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107d17:	e9 d5 f0 ff ff       	jmp    80106df1 <alltraps>

80107d1c <vector206>:
.globl vector206
vector206:
  pushl $0
80107d1c:	6a 00                	push   $0x0
  pushl $206
80107d1e:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107d23:	e9 c9 f0 ff ff       	jmp    80106df1 <alltraps>

80107d28 <vector207>:
.globl vector207
vector207:
  pushl $0
80107d28:	6a 00                	push   $0x0
  pushl $207
80107d2a:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d2f:	e9 bd f0 ff ff       	jmp    80106df1 <alltraps>

80107d34 <vector208>:
.globl vector208
vector208:
  pushl $0
80107d34:	6a 00                	push   $0x0
  pushl $208
80107d36:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d3b:	e9 b1 f0 ff ff       	jmp    80106df1 <alltraps>

80107d40 <vector209>:
.globl vector209
vector209:
  pushl $0
80107d40:	6a 00                	push   $0x0
  pushl $209
80107d42:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d47:	e9 a5 f0 ff ff       	jmp    80106df1 <alltraps>

80107d4c <vector210>:
.globl vector210
vector210:
  pushl $0
80107d4c:	6a 00                	push   $0x0
  pushl $210
80107d4e:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d53:	e9 99 f0 ff ff       	jmp    80106df1 <alltraps>

80107d58 <vector211>:
.globl vector211
vector211:
  pushl $0
80107d58:	6a 00                	push   $0x0
  pushl $211
80107d5a:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d5f:	e9 8d f0 ff ff       	jmp    80106df1 <alltraps>

80107d64 <vector212>:
.globl vector212
vector212:
  pushl $0
80107d64:	6a 00                	push   $0x0
  pushl $212
80107d66:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d6b:	e9 81 f0 ff ff       	jmp    80106df1 <alltraps>

80107d70 <vector213>:
.globl vector213
vector213:
  pushl $0
80107d70:	6a 00                	push   $0x0
  pushl $213
80107d72:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107d77:	e9 75 f0 ff ff       	jmp    80106df1 <alltraps>

80107d7c <vector214>:
.globl vector214
vector214:
  pushl $0
80107d7c:	6a 00                	push   $0x0
  pushl $214
80107d7e:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107d83:	e9 69 f0 ff ff       	jmp    80106df1 <alltraps>

80107d88 <vector215>:
.globl vector215
vector215:
  pushl $0
80107d88:	6a 00                	push   $0x0
  pushl $215
80107d8a:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107d8f:	e9 5d f0 ff ff       	jmp    80106df1 <alltraps>

80107d94 <vector216>:
.globl vector216
vector216:
  pushl $0
80107d94:	6a 00                	push   $0x0
  pushl $216
80107d96:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107d9b:	e9 51 f0 ff ff       	jmp    80106df1 <alltraps>

80107da0 <vector217>:
.globl vector217
vector217:
  pushl $0
80107da0:	6a 00                	push   $0x0
  pushl $217
80107da2:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107da7:	e9 45 f0 ff ff       	jmp    80106df1 <alltraps>

80107dac <vector218>:
.globl vector218
vector218:
  pushl $0
80107dac:	6a 00                	push   $0x0
  pushl $218
80107dae:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107db3:	e9 39 f0 ff ff       	jmp    80106df1 <alltraps>

80107db8 <vector219>:
.globl vector219
vector219:
  pushl $0
80107db8:	6a 00                	push   $0x0
  pushl $219
80107dba:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107dbf:	e9 2d f0 ff ff       	jmp    80106df1 <alltraps>

80107dc4 <vector220>:
.globl vector220
vector220:
  pushl $0
80107dc4:	6a 00                	push   $0x0
  pushl $220
80107dc6:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107dcb:	e9 21 f0 ff ff       	jmp    80106df1 <alltraps>

80107dd0 <vector221>:
.globl vector221
vector221:
  pushl $0
80107dd0:	6a 00                	push   $0x0
  pushl $221
80107dd2:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107dd7:	e9 15 f0 ff ff       	jmp    80106df1 <alltraps>

80107ddc <vector222>:
.globl vector222
vector222:
  pushl $0
80107ddc:	6a 00                	push   $0x0
  pushl $222
80107dde:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107de3:	e9 09 f0 ff ff       	jmp    80106df1 <alltraps>

80107de8 <vector223>:
.globl vector223
vector223:
  pushl $0
80107de8:	6a 00                	push   $0x0
  pushl $223
80107dea:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107def:	e9 fd ef ff ff       	jmp    80106df1 <alltraps>

80107df4 <vector224>:
.globl vector224
vector224:
  pushl $0
80107df4:	6a 00                	push   $0x0
  pushl $224
80107df6:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107dfb:	e9 f1 ef ff ff       	jmp    80106df1 <alltraps>

80107e00 <vector225>:
.globl vector225
vector225:
  pushl $0
80107e00:	6a 00                	push   $0x0
  pushl $225
80107e02:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107e07:	e9 e5 ef ff ff       	jmp    80106df1 <alltraps>

80107e0c <vector226>:
.globl vector226
vector226:
  pushl $0
80107e0c:	6a 00                	push   $0x0
  pushl $226
80107e0e:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107e13:	e9 d9 ef ff ff       	jmp    80106df1 <alltraps>

80107e18 <vector227>:
.globl vector227
vector227:
  pushl $0
80107e18:	6a 00                	push   $0x0
  pushl $227
80107e1a:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107e1f:	e9 cd ef ff ff       	jmp    80106df1 <alltraps>

80107e24 <vector228>:
.globl vector228
vector228:
  pushl $0
80107e24:	6a 00                	push   $0x0
  pushl $228
80107e26:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e2b:	e9 c1 ef ff ff       	jmp    80106df1 <alltraps>

80107e30 <vector229>:
.globl vector229
vector229:
  pushl $0
80107e30:	6a 00                	push   $0x0
  pushl $229
80107e32:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e37:	e9 b5 ef ff ff       	jmp    80106df1 <alltraps>

80107e3c <vector230>:
.globl vector230
vector230:
  pushl $0
80107e3c:	6a 00                	push   $0x0
  pushl $230
80107e3e:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e43:	e9 a9 ef ff ff       	jmp    80106df1 <alltraps>

80107e48 <vector231>:
.globl vector231
vector231:
  pushl $0
80107e48:	6a 00                	push   $0x0
  pushl $231
80107e4a:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e4f:	e9 9d ef ff ff       	jmp    80106df1 <alltraps>

80107e54 <vector232>:
.globl vector232
vector232:
  pushl $0
80107e54:	6a 00                	push   $0x0
  pushl $232
80107e56:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e5b:	e9 91 ef ff ff       	jmp    80106df1 <alltraps>

80107e60 <vector233>:
.globl vector233
vector233:
  pushl $0
80107e60:	6a 00                	push   $0x0
  pushl $233
80107e62:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e67:	e9 85 ef ff ff       	jmp    80106df1 <alltraps>

80107e6c <vector234>:
.globl vector234
vector234:
  pushl $0
80107e6c:	6a 00                	push   $0x0
  pushl $234
80107e6e:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e73:	e9 79 ef ff ff       	jmp    80106df1 <alltraps>

80107e78 <vector235>:
.globl vector235
vector235:
  pushl $0
80107e78:	6a 00                	push   $0x0
  pushl $235
80107e7a:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107e7f:	e9 6d ef ff ff       	jmp    80106df1 <alltraps>

80107e84 <vector236>:
.globl vector236
vector236:
  pushl $0
80107e84:	6a 00                	push   $0x0
  pushl $236
80107e86:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107e8b:	e9 61 ef ff ff       	jmp    80106df1 <alltraps>

80107e90 <vector237>:
.globl vector237
vector237:
  pushl $0
80107e90:	6a 00                	push   $0x0
  pushl $237
80107e92:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107e97:	e9 55 ef ff ff       	jmp    80106df1 <alltraps>

80107e9c <vector238>:
.globl vector238
vector238:
  pushl $0
80107e9c:	6a 00                	push   $0x0
  pushl $238
80107e9e:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107ea3:	e9 49 ef ff ff       	jmp    80106df1 <alltraps>

80107ea8 <vector239>:
.globl vector239
vector239:
  pushl $0
80107ea8:	6a 00                	push   $0x0
  pushl $239
80107eaa:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107eaf:	e9 3d ef ff ff       	jmp    80106df1 <alltraps>

80107eb4 <vector240>:
.globl vector240
vector240:
  pushl $0
80107eb4:	6a 00                	push   $0x0
  pushl $240
80107eb6:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107ebb:	e9 31 ef ff ff       	jmp    80106df1 <alltraps>

80107ec0 <vector241>:
.globl vector241
vector241:
  pushl $0
80107ec0:	6a 00                	push   $0x0
  pushl $241
80107ec2:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107ec7:	e9 25 ef ff ff       	jmp    80106df1 <alltraps>

80107ecc <vector242>:
.globl vector242
vector242:
  pushl $0
80107ecc:	6a 00                	push   $0x0
  pushl $242
80107ece:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107ed3:	e9 19 ef ff ff       	jmp    80106df1 <alltraps>

80107ed8 <vector243>:
.globl vector243
vector243:
  pushl $0
80107ed8:	6a 00                	push   $0x0
  pushl $243
80107eda:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107edf:	e9 0d ef ff ff       	jmp    80106df1 <alltraps>

80107ee4 <vector244>:
.globl vector244
vector244:
  pushl $0
80107ee4:	6a 00                	push   $0x0
  pushl $244
80107ee6:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107eeb:	e9 01 ef ff ff       	jmp    80106df1 <alltraps>

80107ef0 <vector245>:
.globl vector245
vector245:
  pushl $0
80107ef0:	6a 00                	push   $0x0
  pushl $245
80107ef2:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107ef7:	e9 f5 ee ff ff       	jmp    80106df1 <alltraps>

80107efc <vector246>:
.globl vector246
vector246:
  pushl $0
80107efc:	6a 00                	push   $0x0
  pushl $246
80107efe:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107f03:	e9 e9 ee ff ff       	jmp    80106df1 <alltraps>

80107f08 <vector247>:
.globl vector247
vector247:
  pushl $0
80107f08:	6a 00                	push   $0x0
  pushl $247
80107f0a:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107f0f:	e9 dd ee ff ff       	jmp    80106df1 <alltraps>

80107f14 <vector248>:
.globl vector248
vector248:
  pushl $0
80107f14:	6a 00                	push   $0x0
  pushl $248
80107f16:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107f1b:	e9 d1 ee ff ff       	jmp    80106df1 <alltraps>

80107f20 <vector249>:
.globl vector249
vector249:
  pushl $0
80107f20:	6a 00                	push   $0x0
  pushl $249
80107f22:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f27:	e9 c5 ee ff ff       	jmp    80106df1 <alltraps>

80107f2c <vector250>:
.globl vector250
vector250:
  pushl $0
80107f2c:	6a 00                	push   $0x0
  pushl $250
80107f2e:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f33:	e9 b9 ee ff ff       	jmp    80106df1 <alltraps>

80107f38 <vector251>:
.globl vector251
vector251:
  pushl $0
80107f38:	6a 00                	push   $0x0
  pushl $251
80107f3a:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f3f:	e9 ad ee ff ff       	jmp    80106df1 <alltraps>

80107f44 <vector252>:
.globl vector252
vector252:
  pushl $0
80107f44:	6a 00                	push   $0x0
  pushl $252
80107f46:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f4b:	e9 a1 ee ff ff       	jmp    80106df1 <alltraps>

80107f50 <vector253>:
.globl vector253
vector253:
  pushl $0
80107f50:	6a 00                	push   $0x0
  pushl $253
80107f52:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f57:	e9 95 ee ff ff       	jmp    80106df1 <alltraps>

80107f5c <vector254>:
.globl vector254
vector254:
  pushl $0
80107f5c:	6a 00                	push   $0x0
  pushl $254
80107f5e:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f63:	e9 89 ee ff ff       	jmp    80106df1 <alltraps>

80107f68 <vector255>:
.globl vector255
vector255:
  pushl $0
80107f68:	6a 00                	push   $0x0
  pushl $255
80107f6a:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f6f:	e9 7d ee ff ff       	jmp    80106df1 <alltraps>

80107f74 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f74:	55                   	push   %ebp
80107f75:	89 e5                	mov    %esp,%ebp
80107f77:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f7d:	83 e8 01             	sub    $0x1,%eax
80107f80:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107f84:	8b 45 08             	mov    0x8(%ebp),%eax
80107f87:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80107f8e:	c1 e8 10             	shr    $0x10,%eax
80107f91:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107f95:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107f98:	0f 01 10             	lgdtl  (%eax)
}
80107f9b:	c9                   	leave  
80107f9c:	c3                   	ret    

80107f9d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107f9d:	55                   	push   %ebp
80107f9e:	89 e5                	mov    %esp,%ebp
80107fa0:	83 ec 04             	sub    $0x4,%esp
80107fa3:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107faa:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fae:	0f 00 d8             	ltr    %ax
}
80107fb1:	c9                   	leave  
80107fb2:	c3                   	ret    

80107fb3 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107fb3:	55                   	push   %ebp
80107fb4:	89 e5                	mov    %esp,%ebp
80107fb6:	83 ec 04             	sub    $0x4,%esp
80107fb9:	8b 45 08             	mov    0x8(%ebp),%eax
80107fbc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107fc0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fc4:	8e e8                	mov    %eax,%gs
}
80107fc6:	c9                   	leave  
80107fc7:	c3                   	ret    

80107fc8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107fc8:	55                   	push   %ebp
80107fc9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80107fce:	0f 22 d8             	mov    %eax,%cr3
}
80107fd1:	5d                   	pop    %ebp
80107fd2:	c3                   	ret    

80107fd3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107fd3:	55                   	push   %ebp
80107fd4:	89 e5                	mov    %esp,%ebp
80107fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd9:	05 00 00 00 80       	add    $0x80000000,%eax
80107fde:	5d                   	pop    %ebp
80107fdf:	c3                   	ret    

80107fe0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107fe0:	55                   	push   %ebp
80107fe1:	89 e5                	mov    %esp,%ebp
80107fe3:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe6:	05 00 00 00 80       	add    $0x80000000,%eax
80107feb:	5d                   	pop    %ebp
80107fec:	c3                   	ret    

80107fed <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107fed:	55                   	push   %ebp
80107fee:	89 e5                	mov    %esp,%ebp
80107ff0:	53                   	push   %ebx
80107ff1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107ff4:	e8 26 b6 ff ff       	call   8010361f <cpunum>
80107ff9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107fff:	05 60 43 11 80       	add    $0x80114360,%eax
80108004:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108007:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800a:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108010:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108013:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108019:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010801c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108020:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108023:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108027:	83 e2 f0             	and    $0xfffffff0,%edx
8010802a:	83 ca 0a             	or     $0xa,%edx
8010802d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108030:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108033:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108037:	83 ca 10             	or     $0x10,%edx
8010803a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010803d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108040:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108044:	83 e2 9f             	and    $0xffffff9f,%edx
80108047:	88 50 7d             	mov    %dl,0x7d(%eax)
8010804a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010804d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108051:	83 ca 80             	or     $0xffffff80,%edx
80108054:	88 50 7d             	mov    %dl,0x7d(%eax)
80108057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010805a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010805e:	83 ca 0f             	or     $0xf,%edx
80108061:	88 50 7e             	mov    %dl,0x7e(%eax)
80108064:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108067:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010806b:	83 e2 ef             	and    $0xffffffef,%edx
8010806e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108074:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108078:	83 e2 df             	and    $0xffffffdf,%edx
8010807b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010807e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108081:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108085:	83 ca 40             	or     $0x40,%edx
80108088:	88 50 7e             	mov    %dl,0x7e(%eax)
8010808b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108092:	83 ca 80             	or     $0xffffff80,%edx
80108095:	88 50 7e             	mov    %dl,0x7e(%eax)
80108098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010809f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080a2:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801080a9:	ff ff 
801080ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ae:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801080b5:	00 00 
801080b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ba:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801080c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080cb:	83 e2 f0             	and    $0xfffffff0,%edx
801080ce:	83 ca 02             	or     $0x2,%edx
801080d1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080da:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080e1:	83 ca 10             	or     $0x10,%edx
801080e4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ed:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080f4:	83 e2 9f             	and    $0xffffff9f,%edx
801080f7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108100:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108107:	83 ca 80             	or     $0xffffff80,%edx
8010810a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108113:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010811a:	83 ca 0f             	or     $0xf,%edx
8010811d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108123:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108126:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010812d:	83 e2 ef             	and    $0xffffffef,%edx
80108130:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108139:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108140:	83 e2 df             	and    $0xffffffdf,%edx
80108143:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108149:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010814c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108153:	83 ca 40             	or     $0x40,%edx
80108156:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010815c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010815f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108166:	83 ca 80             	or     $0xffffff80,%edx
80108169:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010816f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108172:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108183:	ff ff 
80108185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108188:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010818f:	00 00 
80108191:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108194:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010819b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081a5:	83 e2 f0             	and    $0xfffffff0,%edx
801081a8:	83 ca 0a             	or     $0xa,%edx
801081ab:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081bb:	83 ca 10             	or     $0x10,%edx
801081be:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081ce:	83 ca 60             	or     $0x60,%edx
801081d1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081da:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081e1:	83 ca 80             	or     $0xffffff80,%edx
801081e4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ed:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081f4:	83 ca 0f             	or     $0xf,%edx
801081f7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108200:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108207:	83 e2 ef             	and    $0xffffffef,%edx
8010820a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108210:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108213:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010821a:	83 e2 df             	and    $0xffffffdf,%edx
8010821d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108226:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010822d:	83 ca 40             	or     $0x40,%edx
80108230:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108239:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108240:	83 ca 80             	or     $0xffffff80,%edx
80108243:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108249:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010824c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108253:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108256:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
8010825d:	ff ff 
8010825f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108262:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108269:	00 00 
8010826b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108278:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010827f:	83 e2 f0             	and    $0xfffffff0,%edx
80108282:	83 ca 02             	or     $0x2,%edx
80108285:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010828b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108295:	83 ca 10             	or     $0x10,%edx
80108298:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010829e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a1:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082a8:	83 ca 60             	or     $0x60,%edx
801082ab:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082bb:	83 ca 80             	or     $0xffffff80,%edx
801082be:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082ce:	83 ca 0f             	or     $0xf,%edx
801082d1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082da:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082e1:	83 e2 ef             	and    $0xffffffef,%edx
801082e4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ed:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082f4:	83 e2 df             	and    $0xffffffdf,%edx
801082f7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108300:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108307:	83 ca 40             	or     $0x40,%edx
8010830a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108313:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010831a:	83 ca 80             	or     $0xffffff80,%edx
8010831d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108326:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
8010832d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108330:	05 b4 00 00 00       	add    $0xb4,%eax
80108335:	89 c3                	mov    %eax,%ebx
80108337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833a:	05 b4 00 00 00       	add    $0xb4,%eax
8010833f:	c1 e8 10             	shr    $0x10,%eax
80108342:	89 c1                	mov    %eax,%ecx
80108344:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108347:	05 b4 00 00 00       	add    $0xb4,%eax
8010834c:	c1 e8 18             	shr    $0x18,%eax
8010834f:	89 c2                	mov    %eax,%edx
80108351:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108354:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010835b:	00 00 
8010835d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108360:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108370:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108373:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010837a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010837d:	83 c9 02             	or     $0x2,%ecx
80108380:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108386:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108389:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108390:	83 c9 10             	or     $0x10,%ecx
80108393:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108399:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083a3:	83 e1 9f             	and    $0xffffff9f,%ecx
801083a6:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083af:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083b6:	83 c9 80             	or     $0xffffff80,%ecx
801083b9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083c9:	83 e1 f0             	and    $0xfffffff0,%ecx
801083cc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083dc:	83 e1 ef             	and    $0xffffffef,%ecx
801083df:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083ef:	83 e1 df             	and    $0xffffffdf,%ecx
801083f2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108402:	83 c9 40             	or     $0x40,%ecx
80108405:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010840b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108415:	83 c9 80             	or     $0xffffff80,%ecx
80108418:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010841e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108421:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108427:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842a:	83 c0 70             	add    $0x70,%eax
8010842d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108434:	00 
80108435:	89 04 24             	mov    %eax,(%esp)
80108438:	e8 37 fb ff ff       	call   80107f74 <lgdt>
  loadgs(SEG_KCPU << 3);
8010843d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108444:	e8 6a fb ff ff       	call   80107fb3 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108452:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108459:	00 00 00 00 
}
8010845d:	83 c4 24             	add    $0x24,%esp
80108460:	5b                   	pop    %ebx
80108461:	5d                   	pop    %ebp
80108462:	c3                   	ret    

80108463 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108463:	55                   	push   %ebp
80108464:	89 e5                	mov    %esp,%ebp
80108466:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108469:	8b 45 0c             	mov    0xc(%ebp),%eax
8010846c:	c1 e8 16             	shr    $0x16,%eax
8010846f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108476:	8b 45 08             	mov    0x8(%ebp),%eax
80108479:	01 d0                	add    %edx,%eax
8010847b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
8010847e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108481:	8b 00                	mov    (%eax),%eax
80108483:	83 e0 01             	and    $0x1,%eax
80108486:	85 c0                	test   %eax,%eax
80108488:	74 17                	je     801084a1 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
8010848a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010848d:	8b 00                	mov    (%eax),%eax
8010848f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108494:	89 04 24             	mov    %eax,(%esp)
80108497:	e8 44 fb ff ff       	call   80107fe0 <p2v>
8010849c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010849f:	eb 4b                	jmp    801084ec <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801084a1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801084a5:	74 0e                	je     801084b5 <walkpgdir+0x52>
801084a7:	e8 97 ad ff ff       	call   80103243 <kalloc>
801084ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801084b3:	75 07                	jne    801084bc <walkpgdir+0x59>
      return 0;
801084b5:	b8 00 00 00 00       	mov    $0x0,%eax
801084ba:	eb 47                	jmp    80108503 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801084bc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084c3:	00 
801084c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084cb:	00 
801084cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084cf:	89 04 24             	mov    %eax,(%esp)
801084d2:	e8 11 d5 ff ff       	call   801059e8 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801084d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084da:	89 04 24             	mov    %eax,(%esp)
801084dd:	e8 f1 fa ff ff       	call   80107fd3 <v2p>
801084e2:	83 c8 07             	or     $0x7,%eax
801084e5:	89 c2                	mov    %eax,%edx
801084e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084ea:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801084ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801084ef:	c1 e8 0c             	shr    $0xc,%eax
801084f2:	25 ff 03 00 00       	and    $0x3ff,%eax
801084f7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108501:	01 d0                	add    %edx,%eax
}
80108503:	c9                   	leave  
80108504:	c3                   	ret    

80108505 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108505:	55                   	push   %ebp
80108506:	89 e5                	mov    %esp,%ebp
80108508:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
8010850b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010850e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108513:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108516:	8b 55 0c             	mov    0xc(%ebp),%edx
80108519:	8b 45 10             	mov    0x10(%ebp),%eax
8010851c:	01 d0                	add    %edx,%eax
8010851e:	83 e8 01             	sub    $0x1,%eax
80108521:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108526:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108529:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108530:	00 
80108531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108534:	89 44 24 04          	mov    %eax,0x4(%esp)
80108538:	8b 45 08             	mov    0x8(%ebp),%eax
8010853b:	89 04 24             	mov    %eax,(%esp)
8010853e:	e8 20 ff ff ff       	call   80108463 <walkpgdir>
80108543:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108546:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010854a:	75 07                	jne    80108553 <mappages+0x4e>
      return -1;
8010854c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108551:	eb 48                	jmp    8010859b <mappages+0x96>
    if(*pte & PTE_P)
80108553:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108556:	8b 00                	mov    (%eax),%eax
80108558:	83 e0 01             	and    $0x1,%eax
8010855b:	85 c0                	test   %eax,%eax
8010855d:	74 0c                	je     8010856b <mappages+0x66>
      panic("remap");
8010855f:	c7 04 24 c8 a3 10 80 	movl   $0x8010a3c8,(%esp)
80108566:	e8 cf 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
8010856b:	8b 45 18             	mov    0x18(%ebp),%eax
8010856e:	0b 45 14             	or     0x14(%ebp),%eax
80108571:	83 c8 01             	or     $0x1,%eax
80108574:	89 c2                	mov    %eax,%edx
80108576:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108579:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010857b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010857e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108581:	75 08                	jne    8010858b <mappages+0x86>
      break;
80108583:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108584:	b8 00 00 00 00       	mov    $0x0,%eax
80108589:	eb 10                	jmp    8010859b <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
8010858b:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108592:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108599:	eb 8e                	jmp    80108529 <mappages+0x24>
  return 0;
}
8010859b:	c9                   	leave  
8010859c:	c3                   	ret    

8010859d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
8010859d:	55                   	push   %ebp
8010859e:	89 e5                	mov    %esp,%ebp
801085a0:	53                   	push   %ebx
801085a1:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801085a4:	e8 9a ac ff ff       	call   80103243 <kalloc>
801085a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801085ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085b0:	75 0a                	jne    801085bc <setupkvm+0x1f>
    return 0;
801085b2:	b8 00 00 00 00       	mov    $0x0,%eax
801085b7:	e9 98 00 00 00       	jmp    80108654 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801085bc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085c3:	00 
801085c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085cb:	00 
801085cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085cf:	89 04 24             	mov    %eax,(%esp)
801085d2:	e8 11 d4 ff ff       	call   801059e8 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801085d7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801085de:	e8 fd f9 ff ff       	call   80107fe0 <p2v>
801085e3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801085e8:	76 0c                	jbe    801085f6 <setupkvm+0x59>
    panic("PHYSTOP too high");
801085ea:	c7 04 24 ce a3 10 80 	movl   $0x8010a3ce,(%esp)
801085f1:	e8 44 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801085f6:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
801085fd:	eb 49                	jmp    80108648 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801085ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108602:	8b 48 0c             	mov    0xc(%eax),%ecx
80108605:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108608:	8b 50 04             	mov    0x4(%eax),%edx
8010860b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860e:	8b 58 08             	mov    0x8(%eax),%ebx
80108611:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108614:	8b 40 04             	mov    0x4(%eax),%eax
80108617:	29 c3                	sub    %eax,%ebx
80108619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861c:	8b 00                	mov    (%eax),%eax
8010861e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108622:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108626:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010862a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010862e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108631:	89 04 24             	mov    %eax,(%esp)
80108634:	e8 cc fe ff ff       	call   80108505 <mappages>
80108639:	85 c0                	test   %eax,%eax
8010863b:	79 07                	jns    80108644 <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
8010863d:	b8 00 00 00 00       	mov    $0x0,%eax
80108642:	eb 10                	jmp    80108654 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108644:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108648:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
8010864f:	72 ae                	jb     801085ff <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
80108651:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
80108654:	83 c4 34             	add    $0x34,%esp
80108657:	5b                   	pop    %ebx
80108658:	5d                   	pop    %ebp
80108659:	c3                   	ret    

8010865a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
8010865a:	55                   	push   %ebp
8010865b:	89 e5                	mov    %esp,%ebp
8010865d:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
80108660:	e8 38 ff ff ff       	call   8010859d <setupkvm>
80108665:	a3 58 0d 12 80       	mov    %eax,0x80120d58
    switchkvm();
8010866a:	e8 02 00 00 00       	call   80108671 <switchkvm>
  }
8010866f:	c9                   	leave  
80108670:	c3                   	ret    

80108671 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
80108671:	55                   	push   %ebp
80108672:	89 e5                	mov    %esp,%ebp
80108674:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108677:	a1 58 0d 12 80       	mov    0x80120d58,%eax
8010867c:	89 04 24             	mov    %eax,(%esp)
8010867f:	e8 4f f9 ff ff       	call   80107fd3 <v2p>
80108684:	89 04 24             	mov    %eax,(%esp)
80108687:	e8 3c f9 ff ff       	call   80107fc8 <lcr3>
}
8010868c:	c9                   	leave  
8010868d:	c3                   	ret    

8010868e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010868e:	55                   	push   %ebp
8010868f:	89 e5                	mov    %esp,%ebp
80108691:	53                   	push   %ebx
80108692:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108695:	e8 4e d2 ff ff       	call   801058e8 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010869a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086a0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086a7:	83 c2 08             	add    $0x8,%edx
801086aa:	89 d3                	mov    %edx,%ebx
801086ac:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086b3:	83 c2 08             	add    $0x8,%edx
801086b6:	c1 ea 10             	shr    $0x10,%edx
801086b9:	89 d1                	mov    %edx,%ecx
801086bb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086c2:	83 c2 08             	add    $0x8,%edx
801086c5:	c1 ea 18             	shr    $0x18,%edx
801086c8:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801086cf:	67 00 
801086d1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801086d8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801086de:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086e5:	83 e1 f0             	and    $0xfffffff0,%ecx
801086e8:	83 c9 09             	or     $0x9,%ecx
801086eb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086f1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086f8:	83 c9 10             	or     $0x10,%ecx
801086fb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108701:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108708:	83 e1 9f             	and    $0xffffff9f,%ecx
8010870b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108711:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108718:	83 c9 80             	or     $0xffffff80,%ecx
8010871b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108721:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108728:	83 e1 f0             	and    $0xfffffff0,%ecx
8010872b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108731:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108738:	83 e1 ef             	and    $0xffffffef,%ecx
8010873b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108741:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108748:	83 e1 df             	and    $0xffffffdf,%ecx
8010874b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108751:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108758:	83 c9 40             	or     $0x40,%ecx
8010875b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108761:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108768:	83 e1 7f             	and    $0x7f,%ecx
8010876b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108771:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108777:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010877d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108784:	83 e2 ef             	and    $0xffffffef,%edx
80108787:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
8010878d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108793:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108799:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010879f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801087a6:	8b 52 08             	mov    0x8(%edx),%edx
801087a9:	81 c2 00 10 00 00    	add    $0x1000,%edx
801087af:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801087b2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801087b9:	e8 df f7 ff ff       	call   80107f9d <ltr>
  if(p->pgdir == 0)
801087be:	8b 45 08             	mov    0x8(%ebp),%eax
801087c1:	8b 40 04             	mov    0x4(%eax),%eax
801087c4:	85 c0                	test   %eax,%eax
801087c6:	75 0c                	jne    801087d4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801087c8:	c7 04 24 df a3 10 80 	movl   $0x8010a3df,(%esp)
801087cf:	e8 66 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801087d4:	8b 45 08             	mov    0x8(%ebp),%eax
801087d7:	8b 40 04             	mov    0x4(%eax),%eax
801087da:	89 04 24             	mov    %eax,(%esp)
801087dd:	e8 f1 f7 ff ff       	call   80107fd3 <v2p>
801087e2:	89 04 24             	mov    %eax,(%esp)
801087e5:	e8 de f7 ff ff       	call   80107fc8 <lcr3>
  popcli();
801087ea:	e8 3d d1 ff ff       	call   8010592c <popcli>
}
801087ef:	83 c4 14             	add    $0x14,%esp
801087f2:	5b                   	pop    %ebx
801087f3:	5d                   	pop    %ebp
801087f4:	c3                   	ret    

801087f5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801087f5:	55                   	push   %ebp
801087f6:	89 e5                	mov    %esp,%ebp
801087f8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801087fb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108802:	76 0c                	jbe    80108810 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108804:	c7 04 24 f3 a3 10 80 	movl   $0x8010a3f3,(%esp)
8010880b:	e8 2a 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
80108810:	e8 2e aa ff ff       	call   80103243 <kalloc>
80108815:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108818:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010881f:	00 
80108820:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108827:	00 
80108828:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882b:	89 04 24             	mov    %eax,(%esp)
8010882e:	e8 b5 d1 ff ff       	call   801059e8 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108836:	89 04 24             	mov    %eax,(%esp)
80108839:	e8 95 f7 ff ff       	call   80107fd3 <v2p>
8010883e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108845:	00 
80108846:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010884a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108851:	00 
80108852:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108859:	00 
8010885a:	8b 45 08             	mov    0x8(%ebp),%eax
8010885d:	89 04 24             	mov    %eax,(%esp)
80108860:	e8 a0 fc ff ff       	call   80108505 <mappages>
  memmove(mem, init, sz);
80108865:	8b 45 10             	mov    0x10(%ebp),%eax
80108868:	89 44 24 08          	mov    %eax,0x8(%esp)
8010886c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010886f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108873:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108876:	89 04 24             	mov    %eax,(%esp)
80108879:	e8 39 d2 ff ff       	call   80105ab7 <memmove>
}
8010887e:	c9                   	leave  
8010887f:	c3                   	ret    

80108880 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108880:	55                   	push   %ebp
80108881:	89 e5                	mov    %esp,%ebp
80108883:	53                   	push   %ebx
80108884:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108887:	8b 45 0c             	mov    0xc(%ebp),%eax
8010888a:	25 ff 0f 00 00       	and    $0xfff,%eax
8010888f:	85 c0                	test   %eax,%eax
80108891:	74 0c                	je     8010889f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108893:	c7 04 24 10 a4 10 80 	movl   $0x8010a410,(%esp)
8010889a:	e8 9b 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010889f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801088a6:	e9 a9 00 00 00       	jmp    80108954 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801088ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ae:	8b 55 0c             	mov    0xc(%ebp),%edx
801088b1:	01 d0                	add    %edx,%eax
801088b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088ba:	00 
801088bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801088bf:	8b 45 08             	mov    0x8(%ebp),%eax
801088c2:	89 04 24             	mov    %eax,(%esp)
801088c5:	e8 99 fb ff ff       	call   80108463 <walkpgdir>
801088ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
801088cd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088d1:	75 0c                	jne    801088df <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801088d3:	c7 04 24 33 a4 10 80 	movl   $0x8010a433,(%esp)
801088da:	e8 5b 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801088df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088e2:	8b 00                	mov    (%eax),%eax
801088e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088e9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801088ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ef:	8b 55 18             	mov    0x18(%ebp),%edx
801088f2:	29 c2                	sub    %eax,%edx
801088f4:	89 d0                	mov    %edx,%eax
801088f6:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801088fb:	77 0f                	ja     8010890c <loaduvm+0x8c>
      n = sz - i;
801088fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108900:	8b 55 18             	mov    0x18(%ebp),%edx
80108903:	29 c2                	sub    %eax,%edx
80108905:	89 d0                	mov    %edx,%eax
80108907:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010890a:	eb 07                	jmp    80108913 <loaduvm+0x93>
    else
      n = PGSIZE;
8010890c:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108916:	8b 55 14             	mov    0x14(%ebp),%edx
80108919:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010891c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010891f:	89 04 24             	mov    %eax,(%esp)
80108922:	e8 b9 f6 ff ff       	call   80107fe0 <p2v>
80108927:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010892a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010892e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108932:	89 44 24 04          	mov    %eax,0x4(%esp)
80108936:	8b 45 10             	mov    0x10(%ebp),%eax
80108939:	89 04 24             	mov    %eax,(%esp)
8010893c:	e8 8b 95 ff ff       	call   80101ecc <readi>
80108941:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108944:	74 07                	je     8010894d <loaduvm+0xcd>
      return -1;
80108946:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010894b:	eb 18                	jmp    80108965 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010894d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108954:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108957:	3b 45 18             	cmp    0x18(%ebp),%eax
8010895a:	0f 82 4b ff ff ff    	jb     801088ab <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108960:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108965:	83 c4 24             	add    $0x24,%esp
80108968:	5b                   	pop    %ebx
80108969:	5d                   	pop    %ebp
8010896a:	c3                   	ret    

8010896b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
8010896b:	55                   	push   %ebp
8010896c:	89 e5                	mov    %esp,%ebp
8010896e:	53                   	push   %ebx
8010896f:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
80108972:	8b 45 10             	mov    0x10(%ebp),%eax
80108975:	85 c0                	test   %eax,%eax
80108977:	79 0a                	jns    80108983 <allocuvm+0x18>
    return 0;
80108979:	b8 00 00 00 00       	mov    $0x0,%eax
8010897e:	e9 1b 02 00 00       	jmp    80108b9e <allocuvm+0x233>
  if(newsz < oldsz)
80108983:	8b 45 10             	mov    0x10(%ebp),%eax
80108986:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108989:	73 08                	jae    80108993 <allocuvm+0x28>
    return oldsz;
8010898b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010898e:	e9 0b 02 00 00       	jmp    80108b9e <allocuvm+0x233>

  a = PGROUNDUP(oldsz);
80108993:	8b 45 0c             	mov    0xc(%ebp),%eax
80108996:	05 ff 0f 00 00       	add    $0xfff,%eax
8010899b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801089a3:	e9 e7 01 00 00       	jmp    80108b8f <allocuvm+0x224>
    mem = kalloc();
801089a8:	e8 96 a8 ff ff       	call   80103243 <kalloc>
801089ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
801089b0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089b4:	75 36                	jne    801089ec <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
801089b6:	c7 04 24 51 a4 10 80 	movl   $0x8010a451,(%esp)
801089bd:	e8 de 79 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
801089c2:	8b 45 14             	mov    0x14(%ebp),%eax
801089c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801089cc:	89 44 24 08          	mov    %eax,0x8(%esp)
801089d0:	8b 45 10             	mov    0x10(%ebp),%eax
801089d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801089d7:	8b 45 08             	mov    0x8(%ebp),%eax
801089da:	89 04 24             	mov    %eax,(%esp)
801089dd:	e8 c2 01 00 00       	call   80108ba4 <deallocuvm>
      return 0;
801089e2:	b8 00 00 00 00       	mov    $0x0,%eax
801089e7:	e9 b2 01 00 00       	jmp    80108b9e <allocuvm+0x233>
    }
    memset(mem, 0, PGSIZE);
801089ec:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089f3:	00 
801089f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089fb:	00 
801089fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089ff:	89 04 24             	mov    %eax,(%esp)
80108a02:	e8 e1 cf ff ff       	call   801059e8 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108a07:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a0a:	89 04 24             	mov    %eax,(%esp)
80108a0d:	e8 c1 f5 ff ff       	call   80107fd3 <v2p>
80108a12:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108a15:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a1c:	00 
80108a1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a21:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a28:	00 
80108a29:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a2d:	8b 45 08             	mov    0x8(%ebp),%eax
80108a30:	89 04 24             	mov    %eax,(%esp)
80108a33:	e8 cd fa ff ff       	call   80108505 <mappages>
    //find the next open cell in pages array
      i=0;
80108a38:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a3f:	eb 16                	jmp    80108a57 <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a41:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a45:	7e 0c                	jle    80108a53 <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a47:	c7 04 24 6c a4 10 80 	movl   $0x8010a46c,(%esp)
80108a4e:	e8 e7 7a ff ff       	call   8010053a <panic>
        }
        i++;
80108a53:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a57:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a5a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a5d:	89 d0                	mov    %edx,%eax
80108a5f:	c1 e0 02             	shl    $0x2,%eax
80108a62:	01 d0                	add    %edx,%eax
80108a64:	c1 e0 02             	shl    $0x2,%eax
80108a67:	01 c8                	add    %ecx,%eax
80108a69:	05 90 00 00 00       	add    $0x90,%eax
80108a6e:	8b 00                	mov    (%eax),%eax
80108a70:	83 f8 ff             	cmp    $0xffffffff,%eax
80108a73:	75 cc                	jne    80108a41 <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
80108a75:	8b 45 14             	mov    0x14(%ebp),%eax
80108a78:	8b 40 10             	mov    0x10(%eax),%eax
80108a7b:	83 f8 01             	cmp    $0x1,%eax
80108a7e:	74 4c                	je     80108acc <allocuvm+0x161>
80108a80:	8b 45 14             	mov    0x14(%ebp),%eax
80108a83:	8b 40 10             	mov    0x10(%eax),%eax
80108a86:	83 f8 02             	cmp    $0x2,%eax
80108a89:	74 41                	je     80108acc <allocuvm+0x161>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108a8b:	8b 45 14             	mov    0x14(%ebp),%eax
80108a8e:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108a94:	83 f8 0e             	cmp    $0xe,%eax
80108a97:	76 1c                	jbe    80108ab5 <allocuvm+0x14a>
          swapOut();
80108a99:	e8 fe 0b 00 00       	call   8010969c <swapOut>
          proc->swapedPagesCounter++;
80108a9e:	8b 45 14             	mov    0x14(%ebp),%eax
80108aa1:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108aa7:	8d 50 01             	lea    0x1(%eax),%edx
80108aaa:	8b 45 14             	mov    0x14(%ebp),%eax
80108aad:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108ab3:	eb 2c                	jmp    80108ae1 <allocuvm+0x176>
          swapOut();
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108ab5:	8b 45 14             	mov    0x14(%ebp),%eax
80108ab8:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108abe:	8d 50 01             	lea    0x1(%eax),%edx
80108ac1:	8b 45 14             	mov    0x14(%ebp),%eax
80108ac4:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108aca:	eb 15                	jmp    80108ae1 <allocuvm+0x176>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108acc:	8b 45 14             	mov    0x14(%ebp),%eax
80108acf:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ad5:	8d 50 01             	lea    0x1(%eax),%edx
80108ad8:	8b 45 14             	mov    0x14(%ebp),%eax
80108adb:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108ae1:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108ae4:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108ae7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108aea:	89 d0                	mov    %edx,%eax
80108aec:	c1 e0 02             	shl    $0x2,%eax
80108aef:	01 d0                	add    %edx,%eax
80108af1:	c1 e0 02             	shl    $0x2,%eax
80108af4:	01 d8                	add    %ebx,%eax
80108af6:	05 90 00 00 00       	add    $0x90,%eax
80108afb:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108afd:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b00:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b03:	89 d0                	mov    %edx,%eax
80108b05:	c1 e0 02             	shl    $0x2,%eax
80108b08:	01 d0                	add    %edx,%eax
80108b0a:	c1 e0 02             	shl    $0x2,%eax
80108b0d:	01 c8                	add    %ecx,%eax
80108b0f:	05 94 00 00 00       	add    $0x94,%eax
80108b14:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108b1a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b1d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b20:	89 d0                	mov    %edx,%eax
80108b22:	c1 e0 02             	shl    $0x2,%eax
80108b25:	01 d0                	add    %edx,%eax
80108b27:	c1 e0 02             	shl    $0x2,%eax
80108b2a:	01 c8                	add    %ecx,%eax
80108b2c:	05 98 00 00 00       	add    $0x98,%eax
80108b31:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b37:	8b 45 14             	mov    0x14(%ebp),%eax
80108b3a:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b40:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b43:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b46:	89 d0                	mov    %edx,%eax
80108b48:	c1 e0 02             	shl    $0x2,%eax
80108b4b:	01 d0                	add    %edx,%eax
80108b4d:	c1 e0 02             	shl    $0x2,%eax
80108b50:	01 d8                	add    %ebx,%eax
80108b52:	05 9c 00 00 00       	add    $0x9c,%eax
80108b57:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108b59:	8b 45 14             	mov    0x14(%ebp),%eax
80108b5c:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108b62:	8d 50 01             	lea    0x1(%eax),%edx
80108b65:	8b 45 14             	mov    0x14(%ebp),%eax
80108b68:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108b6e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b71:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b74:	89 d0                	mov    %edx,%eax
80108b76:	c1 e0 02             	shl    $0x2,%eax
80108b79:	01 d0                	add    %edx,%eax
80108b7b:	c1 e0 02             	shl    $0x2,%eax
80108b7e:	01 c8                	add    %ecx,%eax
80108b80:	05 a0 00 00 00       	add    $0xa0,%eax
80108b85:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108b88:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b92:	3b 45 10             	cmp    0x10(%ebp),%eax
80108b95:	0f 82 0d fe ff ff    	jb     801089a8 <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108b9b:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108b9e:	83 c4 34             	add    $0x34,%esp
80108ba1:	5b                   	pop    %ebx
80108ba2:	5d                   	pop    %ebp
80108ba3:	c3                   	ret    

80108ba4 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108ba4:	55                   	push   %ebp
80108ba5:	89 e5                	mov    %esp,%ebp
80108ba7:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108baa:	8b 45 10             	mov    0x10(%ebp),%eax
80108bad:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108bb0:	72 08                	jb     80108bba <deallocuvm+0x16>
    return oldsz;
80108bb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bb5:	e9 27 02 00 00       	jmp    80108de1 <deallocuvm+0x23d>

  a = PGROUNDUP(newsz);
80108bba:	8b 45 10             	mov    0x10(%ebp),%eax
80108bbd:	05 ff 0f 00 00       	add    $0xfff,%eax
80108bc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108bca:	e9 03 02 00 00       	jmp    80108dd2 <deallocuvm+0x22e>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108bcf:	8b 45 14             	mov    0x14(%ebp),%eax
80108bd2:	8b 40 04             	mov    0x4(%eax),%eax
80108bd5:	3b 45 08             	cmp    0x8(%ebp),%eax
80108bd8:	0f 85 0b 01 00 00    	jne    80108ce9 <deallocuvm+0x145>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108bde:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108be5:	e9 f5 00 00 00       	jmp    80108cdf <deallocuvm+0x13b>
          if(proc->pagesMetaData[i].va == (char *)a){
80108bea:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108bed:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108bf0:	89 d0                	mov    %edx,%eax
80108bf2:	c1 e0 02             	shl    $0x2,%eax
80108bf5:	01 d0                	add    %edx,%eax
80108bf7:	c1 e0 02             	shl    $0x2,%eax
80108bfa:	01 c8                	add    %ecx,%eax
80108bfc:	05 90 00 00 00       	add    $0x90,%eax
80108c01:	8b 10                	mov    (%eax),%edx
80108c03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c06:	39 c2                	cmp    %eax,%edx
80108c08:	0f 85 cd 00 00 00    	jne    80108cdb <deallocuvm+0x137>
            if(proc->pid != 1 && proc->pid != 2){
80108c0e:	8b 45 14             	mov    0x14(%ebp),%eax
80108c11:	8b 40 10             	mov    0x10(%eax),%eax
80108c14:	83 f8 01             	cmp    $0x1,%eax
80108c17:	74 56                	je     80108c6f <deallocuvm+0xcb>
80108c19:	8b 45 14             	mov    0x14(%ebp),%eax
80108c1c:	8b 40 10             	mov    0x10(%eax),%eax
80108c1f:	83 f8 02             	cmp    $0x2,%eax
80108c22:	74 4b                	je     80108c6f <deallocuvm+0xcb>
              if(proc->pagesMetaData[i].isPhysical){
80108c24:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c27:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c2a:	89 d0                	mov    %edx,%eax
80108c2c:	c1 e0 02             	shl    $0x2,%eax
80108c2f:	01 d0                	add    %edx,%eax
80108c31:	c1 e0 02             	shl    $0x2,%eax
80108c34:	01 c8                	add    %ecx,%eax
80108c36:	05 94 00 00 00       	add    $0x94,%eax
80108c3b:	8b 00                	mov    (%eax),%eax
80108c3d:	85 c0                	test   %eax,%eax
80108c3f:	74 17                	je     80108c58 <deallocuvm+0xb4>
                proc->memoryPagesCounter--;
80108c41:	8b 45 14             	mov    0x14(%ebp),%eax
80108c44:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c4a:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c4d:	8b 45 14             	mov    0x14(%ebp),%eax
80108c50:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c56:	eb 2c                	jmp    80108c84 <deallocuvm+0xe0>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108c58:	8b 45 14             	mov    0x14(%ebp),%eax
80108c5b:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108c61:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c64:	8b 45 14             	mov    0x14(%ebp),%eax
80108c67:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c6d:	eb 15                	jmp    80108c84 <deallocuvm+0xe0>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108c6f:	8b 45 14             	mov    0x14(%ebp),%eax
80108c72:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c78:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c7b:	8b 45 14             	mov    0x14(%ebp),%eax
80108c7e:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108c84:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c87:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c8a:	89 d0                	mov    %edx,%eax
80108c8c:	c1 e0 02             	shl    $0x2,%eax
80108c8f:	01 d0                	add    %edx,%eax
80108c91:	c1 e0 02             	shl    $0x2,%eax
80108c94:	01 c8                	add    %ecx,%eax
80108c96:	05 90 00 00 00       	add    $0x90,%eax
80108c9b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108ca1:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108ca4:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ca7:	89 d0                	mov    %edx,%eax
80108ca9:	c1 e0 02             	shl    $0x2,%eax
80108cac:	01 d0                	add    %edx,%eax
80108cae:	c1 e0 02             	shl    $0x2,%eax
80108cb1:	01 c8                	add    %ecx,%eax
80108cb3:	05 94 00 00 00       	add    $0x94,%eax
80108cb8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108cbe:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cc1:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cc4:	89 d0                	mov    %edx,%eax
80108cc6:	c1 e0 02             	shl    $0x2,%eax
80108cc9:	01 d0                	add    %edx,%eax
80108ccb:	c1 e0 02             	shl    $0x2,%eax
80108cce:	01 c8                	add    %ecx,%eax
80108cd0:	05 98 00 00 00       	add    $0x98,%eax
80108cd5:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108cdb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108cdf:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108ce3:	0f 8e 01 ff ff ff    	jle    80108bea <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108ce9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108cf3:	00 
80108cf4:	89 44 24 04          	mov    %eax,0x4(%esp)
80108cf8:	8b 45 08             	mov    0x8(%ebp),%eax
80108cfb:	89 04 24             	mov    %eax,(%esp)
80108cfe:	e8 60 f7 ff ff       	call   80108463 <walkpgdir>
80108d03:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108d06:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d0a:	75 0c                	jne    80108d18 <deallocuvm+0x174>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d0c:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d13:	e9 b3 00 00 00       	jmp    80108dcb <deallocuvm+0x227>
    else if((*pte & PTE_P) != 0){
80108d18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d1b:	8b 00                	mov    (%eax),%eax
80108d1d:	83 e0 01             	and    $0x1,%eax
80108d20:	85 c0                	test   %eax,%eax
80108d22:	74 76                	je     80108d9a <deallocuvm+0x1f6>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108d24:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d27:	8b 00                	mov    (%eax),%eax
80108d29:	25 00 02 00 00       	and    $0x200,%eax
80108d2e:	85 c0                	test   %eax,%eax
80108d30:	75 43                	jne    80108d75 <deallocuvm+0x1d1>
        pa = PTE_ADDR(*pte);
80108d32:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d35:	8b 00                	mov    (%eax),%eax
80108d37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d3c:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d3f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d43:	75 0c                	jne    80108d51 <deallocuvm+0x1ad>
          panic("kfree");
80108d45:	c7 04 24 96 a4 10 80 	movl   $0x8010a496,(%esp)
80108d4c:	e8 e9 77 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108d51:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d54:	89 04 24             	mov    %eax,(%esp)
80108d57:	e8 84 f2 ff ff       	call   80107fe0 <p2v>
80108d5c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108d5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d62:	89 04 24             	mov    %eax,(%esp)
80108d65:	e8 fc a3 ff ff       	call   80103166 <kfree>
        *pte = 0;
80108d6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d6d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d73:	eb 56                	jmp    80108dcb <deallocuvm+0x227>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108d75:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d78:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x",PTE_ADDR(*pte));
80108d7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d81:	8b 00                	mov    (%eax),%eax
80108d83:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d88:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d8c:	c7 04 24 9c a4 10 80 	movl   $0x8010a49c,(%esp)
80108d93:	e8 08 76 ff ff       	call   801003a0 <cprintf>
80108d98:	eb 31                	jmp    80108dcb <deallocuvm+0x227>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108d9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d9d:	8b 00                	mov    (%eax),%eax
80108d9f:	25 00 02 00 00       	and    $0x200,%eax
80108da4:	85 c0                	test   %eax,%eax
80108da6:	74 23                	je     80108dcb <deallocuvm+0x227>
        *pte = 0;
80108da8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
80108db1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108db4:	8b 00                	mov    (%eax),%eax
80108db6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
80108dbf:	c7 04 24 aa a4 10 80 	movl   $0x8010a4aa,(%esp)
80108dc6:	e8 d5 75 ff ff       	call   801003a0 <cprintf>
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108dcb:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108dd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dd5:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108dd8:	0f 82 f1 fd ff ff    	jb     80108bcf <deallocuvm+0x2b>
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
    }
  }
  return newsz;
80108dde:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108de1:	c9                   	leave  
80108de2:	c3                   	ret    

80108de3 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108de3:	55                   	push   %ebp
80108de4:	89 e5                	mov    %esp,%ebp
80108de6:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108de9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108ded:	75 0c                	jne    80108dfb <freevm+0x18>
    panic("freevm: no pgdir");
80108def:	c7 04 24 b9 a4 10 80 	movl   $0x8010a4b9,(%esp)
80108df6:	e8 3f 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108dfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108e01:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e05:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e0c:	00 
80108e0d:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108e14:	80 
80108e15:	8b 45 08             	mov    0x8(%ebp),%eax
80108e18:	89 04 24             	mov    %eax,(%esp)
80108e1b:	e8 84 fd ff ff       	call   80108ba4 <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e20:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e27:	eb 48                	jmp    80108e71 <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e2c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e33:	8b 45 08             	mov    0x8(%ebp),%eax
80108e36:	01 d0                	add    %edx,%eax
80108e38:	8b 00                	mov    (%eax),%eax
80108e3a:	83 e0 01             	and    $0x1,%eax
80108e3d:	85 c0                	test   %eax,%eax
80108e3f:	74 2c                	je     80108e6d <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e44:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e4e:	01 d0                	add    %edx,%eax
80108e50:	8b 00                	mov    (%eax),%eax
80108e52:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e57:	89 04 24             	mov    %eax,(%esp)
80108e5a:	e8 81 f1 ff ff       	call   80107fe0 <p2v>
80108e5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e65:	89 04 24             	mov    %eax,(%esp)
80108e68:	e8 f9 a2 ff ff       	call   80103166 <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e71:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e78:	76 af                	jbe    80108e29 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e7a:	8b 45 08             	mov    0x8(%ebp),%eax
80108e7d:	89 04 24             	mov    %eax,(%esp)
80108e80:	e8 e1 a2 ff ff       	call   80103166 <kfree>

}
80108e85:	c9                   	leave  
80108e86:	c3                   	ret    

80108e87 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e87:	55                   	push   %ebp
80108e88:	89 e5                	mov    %esp,%ebp
80108e8a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e8d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e94:	00 
80108e95:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e98:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80108e9f:	89 04 24             	mov    %eax,(%esp)
80108ea2:	e8 bc f5 ff ff       	call   80108463 <walkpgdir>
80108ea7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108eaa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108eae:	75 0c                	jne    80108ebc <clearpteu+0x35>
    panic("clearpteu");
80108eb0:	c7 04 24 ca a4 10 80 	movl   $0x8010a4ca,(%esp)
80108eb7:	e8 7e 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108ebc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ebf:	8b 00                	mov    (%eax),%eax
80108ec1:	83 e0 fb             	and    $0xfffffffb,%eax
80108ec4:	89 c2                	mov    %eax,%edx
80108ec6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ec9:	89 10                	mov    %edx,(%eax)
}
80108ecb:	c9                   	leave  
80108ecc:	c3                   	ret    

80108ecd <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108ecd:	55                   	push   %ebp
80108ece:	89 e5                	mov    %esp,%ebp
80108ed0:	53                   	push   %ebx
80108ed1:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108ed4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108edb:	8b 45 10             	mov    0x10(%ebp),%eax
80108ede:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108ee5:	00 00 00 
  np->swapedPagesCounter = 0;
80108ee8:	8b 45 10             	mov    0x10(%ebp),%eax
80108eeb:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108ef2:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108ef5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108efb:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108f01:	8b 45 10             	mov    0x10(%ebp),%eax
80108f04:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108f0a:	e8 8e f6 ff ff       	call   8010859d <setupkvm>
80108f0f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f12:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f16:	75 0a                	jne    80108f22 <copyuvm+0x55>
    return 0;
80108f18:	b8 00 00 00 00       	mov    $0x0,%eax
80108f1d:	e9 88 02 00 00       	jmp    801091aa <copyuvm+0x2dd>
  for(i = 0; i < sz; i += PGSIZE){
80108f22:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f29:	e9 b2 01 00 00       	jmp    801090e0 <copyuvm+0x213>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f31:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f38:	00 
80108f39:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80108f40:	89 04 24             	mov    %eax,(%esp)
80108f43:	e8 1b f5 ff ff       	call   80108463 <walkpgdir>
80108f48:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f4b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f4f:	75 0c                	jne    80108f5d <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f51:	c7 04 24 d4 a4 10 80 	movl   $0x8010a4d4,(%esp)
80108f58:	e8 dd 75 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108f5d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f60:	8b 00                	mov    (%eax),%eax
80108f62:	83 e0 01             	and    $0x1,%eax
80108f65:	85 c0                	test   %eax,%eax
80108f67:	75 0c                	jne    80108f75 <copyuvm+0xa8>
      panic("copyuvm: page not present");
80108f69:	c7 04 24 ee a4 10 80 	movl   $0x8010a4ee,(%esp)
80108f70:	e8 c5 75 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108f75:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f78:	8b 00                	mov    (%eax),%eax
80108f7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    flags = PTE_FLAGS(*pte);
80108f82:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f85:	8b 00                	mov    (%eax),%eax
80108f87:	25 ff 0f 00 00       	and    $0xfff,%eax
80108f8c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80108f8f:	e8 af a2 ff ff       	call   80103243 <kalloc>
80108f94:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108f97:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108f9b:	75 05                	jne    80108fa2 <copyuvm+0xd5>
      goto bad;
80108f9d:	e9 f0 01 00 00       	jmp    80109192 <copyuvm+0x2c5>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108fa2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108fa5:	89 04 24             	mov    %eax,(%esp)
80108fa8:	e8 33 f0 ff ff       	call   80107fe0 <p2v>
80108fad:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fb4:	00 
80108fb5:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fb9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fbc:	89 04 24             	mov    %eax,(%esp)
80108fbf:	e8 f3 ca ff ff       	call   80105ab7 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108fc4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108fc7:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fca:	89 04 24             	mov    %eax,(%esp)
80108fcd:	e8 01 f0 ff ff       	call   80107fd3 <v2p>
80108fd2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108fd5:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108fd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108fdd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fe4:	00 
80108fe5:	89 54 24 04          	mov    %edx,0x4(%esp)
80108fe9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108fec:	89 04 24             	mov    %eax,(%esp)
80108fef:	e8 11 f5 ff ff       	call   80108505 <mappages>
80108ff4:	85 c0                	test   %eax,%eax
80108ff6:	79 05                	jns    80108ffd <copyuvm+0x130>
      goto bad;
80108ff8:	e9 95 01 00 00       	jmp    80109192 <copyuvm+0x2c5>
    // if(*pte & PTE_PG)
    //   *pte &= ~PTE_PG;
    np->pagesMetaData[j].va = (char *) i;
80108ffd:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80109000:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109003:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109006:	89 d0                	mov    %edx,%eax
80109008:	c1 e0 02             	shl    $0x2,%eax
8010900b:	01 d0                	add    %edx,%eax
8010900d:	c1 e0 02             	shl    $0x2,%eax
80109010:	01 d8                	add    %ebx,%eax
80109012:	05 90 00 00 00       	add    $0x90,%eax
80109017:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].isPhysical = 1;
80109019:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010901c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010901f:	89 d0                	mov    %edx,%eax
80109021:	c1 e0 02             	shl    $0x2,%eax
80109024:	01 d0                	add    %edx,%eax
80109026:	c1 e0 02             	shl    $0x2,%eax
80109029:	01 c8                	add    %ecx,%eax
8010902b:	05 94 00 00 00       	add    $0x94,%eax
80109030:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109036:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109039:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010903c:	89 d0                	mov    %edx,%eax
8010903e:	c1 e0 02             	shl    $0x2,%eax
80109041:	01 d0                	add    %edx,%eax
80109043:	c1 e0 02             	shl    $0x2,%eax
80109046:	01 c8                	add    %ecx,%eax
80109048:	05 98 00 00 00       	add    $0x98,%eax
8010904d:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
80109053:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010905a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010905d:	89 d0                	mov    %edx,%eax
8010905f:	c1 e0 02             	shl    $0x2,%eax
80109062:	01 d0                	add    %edx,%eax
80109064:	c1 e0 02             	shl    $0x2,%eax
80109067:	01 c8                	add    %ecx,%eax
80109069:	05 9c 00 00 00       	add    $0x9c,%eax
8010906e:	8b 08                	mov    (%eax),%ecx
80109070:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109073:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109076:	89 d0                	mov    %edx,%eax
80109078:	c1 e0 02             	shl    $0x2,%eax
8010907b:	01 d0                	add    %edx,%eax
8010907d:	c1 e0 02             	shl    $0x2,%eax
80109080:	01 d8                	add    %ebx,%eax
80109082:	05 9c 00 00 00       	add    $0x9c,%eax
80109087:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
80109089:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109090:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109093:	89 d0                	mov    %edx,%eax
80109095:	c1 e0 02             	shl    $0x2,%eax
80109098:	01 d0                	add    %edx,%eax
8010909a:	c1 e0 02             	shl    $0x2,%eax
8010909d:	01 c8                	add    %ecx,%eax
8010909f:	05 a0 00 00 00       	add    $0xa0,%eax
801090a4:	0f b6 08             	movzbl (%eax),%ecx
801090a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
801090aa:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090ad:	89 d0                	mov    %edx,%eax
801090af:	c1 e0 02             	shl    $0x2,%eax
801090b2:	01 d0                	add    %edx,%eax
801090b4:	c1 e0 02             	shl    $0x2,%eax
801090b7:	01 d8                	add    %ebx,%eax
801090b9:	05 a0 00 00 00       	add    $0xa0,%eax
801090be:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
801090c0:	8b 45 10             	mov    0x10(%ebp),%eax
801090c3:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801090c9:	8d 50 01             	lea    0x1(%eax),%edx
801090cc:	8b 45 10             	mov    0x10(%ebp),%eax
801090cf:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
801090d5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801090d9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090e3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090e6:	0f 82 42 fe ff ff    	jb     80108f2e <copyuvm+0x61>
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
801090ec:	e9 92 00 00 00       	jmp    80109183 <copyuvm+0x2b6>
    np->pagesMetaData[j].va = (char *) -1;
801090f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090f7:	89 d0                	mov    %edx,%eax
801090f9:	c1 e0 02             	shl    $0x2,%eax
801090fc:	01 d0                	add    %edx,%eax
801090fe:	c1 e0 02             	shl    $0x2,%eax
80109101:	01 c8                	add    %ecx,%eax
80109103:	05 90 00 00 00       	add    $0x90,%eax
80109108:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
8010910e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109111:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109114:	89 d0                	mov    %edx,%eax
80109116:	c1 e0 02             	shl    $0x2,%eax
80109119:	01 d0                	add    %edx,%eax
8010911b:	c1 e0 02             	shl    $0x2,%eax
8010911e:	01 c8                	add    %ecx,%eax
80109120:	05 94 00 00 00       	add    $0x94,%eax
80109125:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
8010912b:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010912e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109131:	89 d0                	mov    %edx,%eax
80109133:	c1 e0 02             	shl    $0x2,%eax
80109136:	01 d0                	add    %edx,%eax
80109138:	c1 e0 02             	shl    $0x2,%eax
8010913b:	01 c8                	add    %ecx,%eax
8010913d:	05 98 00 00 00       	add    $0x98,%eax
80109142:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109148:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010914b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010914e:	89 d0                	mov    %edx,%eax
80109150:	c1 e0 02             	shl    $0x2,%eax
80109153:	01 d0                	add    %edx,%eax
80109155:	c1 e0 02             	shl    $0x2,%eax
80109158:	01 c8                	add    %ecx,%eax
8010915a:	05 9c 00 00 00       	add    $0x9c,%eax
8010915f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
80109165:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109168:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010916b:	89 d0                	mov    %edx,%eax
8010916d:	c1 e0 02             	shl    $0x2,%eax
80109170:	01 d0                	add    %edx,%eax
80109172:	c1 e0 02             	shl    $0x2,%eax
80109175:	01 c8                	add    %ecx,%eax
80109177:	05 a0 00 00 00       	add    $0xa0,%eax
8010917c:	c6 00 80             	movb   $0x80,(%eax)
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
8010917f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109183:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109187:	0f 86 64 ff ff ff    	jbe    801090f1 <copyuvm+0x224>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
8010918d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109190:	eb 18                	jmp    801091aa <copyuvm+0x2dd>

  bad:
  freevm(d,0);
80109192:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109199:	00 
8010919a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010919d:	89 04 24             	mov    %eax,(%esp)
801091a0:	e8 3e fc ff ff       	call   80108de3 <freevm>
  return 0;
801091a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801091aa:	83 c4 44             	add    $0x44,%esp
801091ad:	5b                   	pop    %ebx
801091ae:	5d                   	pop    %ebp
801091af:	c3                   	ret    

801091b0 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801091b0:	55                   	push   %ebp
801091b1:	89 e5                	mov    %esp,%ebp
801091b3:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801091b6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091bd:	00 
801091be:	8b 45 0c             	mov    0xc(%ebp),%eax
801091c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801091c5:	8b 45 08             	mov    0x8(%ebp),%eax
801091c8:	89 04 24             	mov    %eax,(%esp)
801091cb:	e8 93 f2 ff ff       	call   80108463 <walkpgdir>
801091d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801091d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091d6:	8b 00                	mov    (%eax),%eax
801091d8:	83 e0 01             	and    $0x1,%eax
801091db:	85 c0                	test   %eax,%eax
801091dd:	75 07                	jne    801091e6 <uva2ka+0x36>
    return 0;
801091df:	b8 00 00 00 00       	mov    $0x0,%eax
801091e4:	eb 25                	jmp    8010920b <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801091e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091e9:	8b 00                	mov    (%eax),%eax
801091eb:	83 e0 04             	and    $0x4,%eax
801091ee:	85 c0                	test   %eax,%eax
801091f0:	75 07                	jne    801091f9 <uva2ka+0x49>
    return 0;
801091f2:	b8 00 00 00 00       	mov    $0x0,%eax
801091f7:	eb 12                	jmp    8010920b <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801091f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091fc:	8b 00                	mov    (%eax),%eax
801091fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109203:	89 04 24             	mov    %eax,(%esp)
80109206:	e8 d5 ed ff ff       	call   80107fe0 <p2v>
}
8010920b:	c9                   	leave  
8010920c:	c3                   	ret    

8010920d <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010920d:	55                   	push   %ebp
8010920e:	89 e5                	mov    %esp,%ebp
80109210:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109213:	8b 45 10             	mov    0x10(%ebp),%eax
80109216:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109219:	e9 87 00 00 00       	jmp    801092a5 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010921e:	8b 45 0c             	mov    0xc(%ebp),%eax
80109221:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109226:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109229:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010922c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109230:	8b 45 08             	mov    0x8(%ebp),%eax
80109233:	89 04 24             	mov    %eax,(%esp)
80109236:	e8 75 ff ff ff       	call   801091b0 <uva2ka>
8010923b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010923e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109242:	75 07                	jne    8010924b <copyout+0x3e>
      return -1;
80109244:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109249:	eb 69                	jmp    801092b4 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010924b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010924e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109251:	29 c2                	sub    %eax,%edx
80109253:	89 d0                	mov    %edx,%eax
80109255:	05 00 10 00 00       	add    $0x1000,%eax
8010925a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010925d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109260:	3b 45 14             	cmp    0x14(%ebp),%eax
80109263:	76 06                	jbe    8010926b <copyout+0x5e>
      n = len;
80109265:	8b 45 14             	mov    0x14(%ebp),%eax
80109268:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010926b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010926e:	8b 55 0c             	mov    0xc(%ebp),%edx
80109271:	29 c2                	sub    %eax,%edx
80109273:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109276:	01 c2                	add    %eax,%edx
80109278:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010927b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010927f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109282:	89 44 24 04          	mov    %eax,0x4(%esp)
80109286:	89 14 24             	mov    %edx,(%esp)
80109289:	e8 29 c8 ff ff       	call   80105ab7 <memmove>
    len -= n;
8010928e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109291:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109294:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109297:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010929a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010929d:	05 00 10 00 00       	add    $0x1000,%eax
801092a2:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801092a5:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801092a9:	0f 85 6f ff ff ff    	jne    8010921e <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801092af:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092b4:	c9                   	leave  
801092b5:	c3                   	ret    

801092b6 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
801092b6:	55                   	push   %ebp
801092b7:	89 e5                	mov    %esp,%ebp
801092b9:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801092bc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801092c3:	eb 52                	jmp    80109317 <findNextOpenPage+0x61>
    found = 1;
801092c5:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092cc:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801092d3:	eb 2d                	jmp    80109302 <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
801092d5:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801092dc:	8b 55 f8             	mov    -0x8(%ebp),%edx
801092df:	89 d0                	mov    %edx,%eax
801092e1:	c1 e0 02             	shl    $0x2,%eax
801092e4:	01 d0                	add    %edx,%eax
801092e6:	c1 e0 02             	shl    $0x2,%eax
801092e9:	01 c8                	add    %ecx,%eax
801092eb:	05 98 00 00 00       	add    $0x98,%eax
801092f0:	8b 00                	mov    (%eax),%eax
801092f2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
801092f5:	75 07                	jne    801092fe <findNextOpenPage+0x48>
        found = 0;
801092f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092fe:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80109302:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
80109306:	7e cd                	jle    801092d5 <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
80109308:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010930c:	74 02                	je     80109310 <findNextOpenPage+0x5a>
      break;
8010930e:	eb 10                	jmp    80109320 <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
80109310:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
80109317:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
8010931e:	7e a5                	jle    801092c5 <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
80109320:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80109323:	c9                   	leave  
80109324:	c3                   	ret    

80109325 <existOnDisc>:

int
existOnDisc(uint faultingPage){
80109325:	55                   	push   %ebp
80109326:	89 e5                	mov    %esp,%ebp
80109328:	83 ec 28             	sub    $0x28,%esp
  cprintf("faulting page: %x\n",faultingPage);
8010932b:	8b 45 08             	mov    0x8(%ebp),%eax
8010932e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109332:	c7 04 24 08 a5 10 80 	movl   $0x8010a508,(%esp)
80109339:	e8 62 70 ff ff       	call   801003a0 <cprintf>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
8010933e:	8b 55 08             	mov    0x8(%ebp),%edx
80109341:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109347:	8b 40 04             	mov    0x4(%eax),%eax
8010934a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109351:	00 
80109352:	89 54 24 04          	mov    %edx,0x4(%esp)
80109356:	89 04 24             	mov    %eax,(%esp)
80109359:	e8 05 f1 ff ff       	call   80108463 <walkpgdir>
8010935e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
80109361:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  for(i = 0; i < 30; i++){
80109368:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010936f:	e9 8e 00 00 00       	jmp    80109402 <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
80109374:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010937b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010937e:	89 d0                	mov    %edx,%eax
80109380:	c1 e0 02             	shl    $0x2,%eax
80109383:	01 d0                	add    %edx,%eax
80109385:	c1 e0 02             	shl    $0x2,%eax
80109388:	01 c8                	add    %ecx,%eax
8010938a:	05 90 00 00 00       	add    $0x90,%eax
8010938f:	8b 00                	mov    (%eax),%eax
80109391:	83 f8 ff             	cmp    $0xffffffff,%eax
80109394:	74 68                	je     801093fe <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
80109396:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010939d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093a0:	89 d0                	mov    %edx,%eax
801093a2:	c1 e0 02             	shl    $0x2,%eax
801093a5:	01 d0                	add    %edx,%eax
801093a7:	c1 e0 02             	shl    $0x2,%eax
801093aa:	01 c8                	add    %ecx,%eax
801093ac:	05 90 00 00 00       	add    $0x90,%eax
801093b1:	8b 00                	mov    (%eax),%eax
801093b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093b8:	3b 45 08             	cmp    0x8(%ebp),%eax
801093bb:	77 41                	ja     801093fe <existOnDisc+0xd9>
801093bd:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093c7:	89 d0                	mov    %edx,%eax
801093c9:	c1 e0 02             	shl    $0x2,%eax
801093cc:	01 d0                	add    %edx,%eax
801093ce:	c1 e0 02             	shl    $0x2,%eax
801093d1:	01 c8                	add    %ecx,%eax
801093d3:	05 90 00 00 00       	add    $0x90,%eax
801093d8:	8b 00                	mov    (%eax),%eax
801093da:	05 ff 0f 00 00       	add    $0xfff,%eax
801093df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093e4:	3b 45 08             	cmp    0x8(%ebp),%eax
801093e7:	72 15                	jb     801093fe <existOnDisc+0xd9>
801093e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093ec:	8b 00                	mov    (%eax),%eax
801093ee:	25 00 02 00 00       	and    $0x200,%eax
801093f3:	85 c0                	test   %eax,%eax
801093f5:	74 07                	je     801093fe <existOnDisc+0xd9>
        found = 1;
801093f7:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  cprintf("faulting page: %x\n",faultingPage);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  for(i = 0; i < 30; i++){
801093fe:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109402:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109406:	0f 8e 68 ff ff ff    	jle    80109374 <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
8010940c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010940f:	c9                   	leave  
80109410:	c3                   	ret    

80109411 <fixPage>:

void
fixPage(uint faultingPage){
80109411:	55                   	push   %ebp
80109412:	89 e5                	mov    %esp,%ebp
80109414:	81 ec 38 10 00 00    	sub    $0x1038,%esp
  int i;
  char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
8010941a:	e8 24 9e ff ff       	call   80103243 <kalloc>
8010941f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
80109422:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109426:	75 0c                	jne    80109434 <fixPage+0x23>
    panic("no room, go away");
80109428:	c7 04 24 1b a5 10 80 	movl   $0x8010a51b,(%esp)
8010942f:	e8 06 71 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
80109434:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010943b:	00 
8010943c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109443:	00 
80109444:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109447:	89 04 24             	mov    %eax,(%esp)
8010944a:	e8 99 c5 ff ff       	call   801059e8 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
8010944f:	8b 55 08             	mov    0x8(%ebp),%edx
80109452:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109458:	8b 40 04             	mov    0x4(%eax),%eax
8010945b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109462:	00 
80109463:	89 54 24 04          	mov    %edx,0x4(%esp)
80109467:	89 04 24             	mov    %eax,(%esp)
8010946a:	e8 f4 ef ff ff       	call   80108463 <walkpgdir>
8010946f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80109472:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109479:	e9 90 01 00 00       	jmp    8010960e <fixPage+0x1fd>
    if(proc->pagesMetaData[i].va != (char *) -1){
8010947e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109485:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109488:	89 d0                	mov    %edx,%eax
8010948a:	c1 e0 02             	shl    $0x2,%eax
8010948d:	01 d0                	add    %edx,%eax
8010948f:	c1 e0 02             	shl    $0x2,%eax
80109492:	01 c8                	add    %ecx,%eax
80109494:	05 90 00 00 00       	add    $0x90,%eax
80109499:	8b 00                	mov    (%eax),%eax
8010949b:	83 f8 ff             	cmp    $0xffffffff,%eax
8010949e:	0f 84 66 01 00 00    	je     8010960a <fixPage+0x1f9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
801094a4:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094ae:	89 d0                	mov    %edx,%eax
801094b0:	c1 e0 02             	shl    $0x2,%eax
801094b3:	01 d0                	add    %edx,%eax
801094b5:	c1 e0 02             	shl    $0x2,%eax
801094b8:	01 c8                	add    %ecx,%eax
801094ba:	05 90 00 00 00       	add    $0x90,%eax
801094bf:	8b 00                	mov    (%eax),%eax
801094c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094c6:	3b 45 08             	cmp    0x8(%ebp),%eax
801094c9:	0f 87 3b 01 00 00    	ja     8010960a <fixPage+0x1f9>
801094cf:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094d9:	89 d0                	mov    %edx,%eax
801094db:	c1 e0 02             	shl    $0x2,%eax
801094de:	01 d0                	add    %edx,%eax
801094e0:	c1 e0 02             	shl    $0x2,%eax
801094e3:	01 c8                	add    %ecx,%eax
801094e5:	05 90 00 00 00       	add    $0x90,%eax
801094ea:	8b 00                	mov    (%eax),%eax
801094ec:	05 ff 0f 00 00       	add    $0xfff,%eax
801094f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094f6:	3b 45 08             	cmp    0x8(%ebp),%eax
801094f9:	0f 82 0b 01 00 00    	jb     8010960a <fixPage+0x1f9>
801094ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109502:	8b 00                	mov    (%eax),%eax
80109504:	25 00 02 00 00       	and    $0x200,%eax
80109509:	85 c0                	test   %eax,%eax
8010950b:	0f 84 f9 00 00 00    	je     8010960a <fixPage+0x1f9>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
80109511:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109518:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010951b:	89 d0                	mov    %edx,%eax
8010951d:	c1 e0 02             	shl    $0x2,%eax
80109520:	01 d0                	add    %edx,%eax
80109522:	c1 e0 02             	shl    $0x2,%eax
80109525:	01 c8                	add    %ecx,%eax
80109527:	05 98 00 00 00       	add    $0x98,%eax
8010952c:	8b 00                	mov    (%eax),%eax
8010952e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109532:	c7 04 24 2c a5 10 80 	movl   $0x8010a52c,(%esp)
80109539:	e8 62 6e ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,buf,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
8010953e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109545:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109548:	89 d0                	mov    %edx,%eax
8010954a:	c1 e0 02             	shl    $0x2,%eax
8010954d:	01 d0                	add    %edx,%eax
8010954f:	c1 e0 02             	shl    $0x2,%eax
80109552:	01 c8                	add    %ecx,%eax
80109554:	05 98 00 00 00       	add    $0x98,%eax
80109559:	8b 00                	mov    (%eax),%eax
8010955b:	89 c2                	mov    %eax,%edx
8010955d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109563:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
8010956a:	00 
8010956b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010956f:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
80109575:	89 54 24 04          	mov    %edx,0x4(%esp)
80109579:	89 04 24             	mov    %eax,(%esp)
8010957c:	e8 ff 93 ff ff       	call   80102980 <readFromSwapFile>
80109581:	83 f8 ff             	cmp    $0xffffffff,%eax
80109584:	75 0c                	jne    80109592 <fixPage+0x181>
          panic("nothing read");
80109586:	c7 04 24 36 a5 10 80 	movl   $0x8010a536,(%esp)
8010958d:	e8 a8 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15)  //need to swap out
80109592:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109598:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
8010959e:	83 f8 0e             	cmp    $0xe,%eax
801095a1:	76 05                	jbe    801095a8 <fixPage+0x197>
          swapOut();
801095a3:	e8 f4 00 00 00       	call   8010969c <swapOut>
        proc->pagesMetaData[i].isPhysical = 1;
801095a8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095b2:	89 d0                	mov    %edx,%eax
801095b4:	c1 e0 02             	shl    $0x2,%eax
801095b7:	01 d0                	add    %edx,%eax
801095b9:	c1 e0 02             	shl    $0x2,%eax
801095bc:	01 c8                	add    %ecx,%eax
801095be:	05 94 00 00 00       	add    $0x94,%eax
801095c3:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  //TODO here?
801095c9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095d3:	89 d0                	mov    %edx,%eax
801095d5:	c1 e0 02             	shl    $0x2,%eax
801095d8:	01 d0                	add    %edx,%eax
801095da:	c1 e0 02             	shl    $0x2,%eax
801095dd:	01 c8                	add    %ecx,%eax
801095df:	05 a0 00 00 00       	add    $0xa0,%eax
801095e4:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
801095e7:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095f1:	89 d0                	mov    %edx,%eax
801095f3:	c1 e0 02             	shl    $0x2,%eax
801095f6:	01 d0                	add    %edx,%eax
801095f8:	c1 e0 02             	shl    $0x2,%eax
801095fb:	01 c8                	add    %ecx,%eax
801095fd:	05 98 00 00 00       	add    $0x98,%eax
80109602:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
80109608:	eb 0e                	jmp    80109618 <fixPage+0x207>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010960a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010960e:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109612:	0f 8e 66 fe ff ff    	jle    8010947e <fixPage+0x6d>
        proc->pagesMetaData[i].fileOffset = -1;
        break;
      }
    }
  }    
    memmove(mem,buf,PGSIZE);
80109618:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010961f:	00 
80109620:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
80109626:	89 44 24 04          	mov    %eax,0x4(%esp)
8010962a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010962d:	89 04 24             	mov    %eax,(%esp)
80109630:	e8 82 c4 ff ff       	call   80105ab7 <memmove>
    *pte &= ~PTE_PG;  //turn off flag
80109635:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109638:	8b 00                	mov    (%eax),%eax
8010963a:	80 e4 fd             	and    $0xfd,%ah
8010963d:	89 c2                	mov    %eax,%edx
8010963f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109642:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
80109644:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109647:	89 04 24             	mov    %eax,(%esp)
8010964a:	e8 84 e9 ff ff       	call   80107fd3 <v2p>
8010964f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109652:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109659:	8b 52 04             	mov    0x4(%edx),%edx
8010965c:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109663:	00 
80109664:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109668:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010966f:	00 
80109670:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80109674:	89 14 24             	mov    %edx,(%esp)
80109677:	e8 89 ee ff ff       	call   80108505 <mappages>
    memmove(buf,0,PGSIZE);
8010967c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109683:	00 
80109684:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010968b:	00 
8010968c:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
80109692:	89 04 24             	mov    %eax,(%esp)
80109695:	e8 1d c4 ff ff       	call   80105ab7 <memmove>
  }
8010969a:	c9                   	leave  
8010969b:	c3                   	ret    

8010969c <swapOut>:

//swap out a page from proc.
  void swapOut(){
8010969c:	55                   	push   %ebp
8010969d:	89 e5                	mov    %esp,%ebp
8010969f:	53                   	push   %ebx
801096a0:	81 ec 34 10 00 00    	sub    $0x1034,%esp
    int j;
    int offset;
    char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    int index = -1;
801096a6:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
801096ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096b3:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801096b9:	83 c0 03             	add    $0x3,%eax
801096bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    char minNFU = 0x80;
801096bf:	c6 45 eb 80          	movb   $0x80,-0x15(%ebp)
        }
        break;

      case 3:  //SCFIFO //turn bit off and move to be newest
        while(1){ //untill a good page to swap out is found
        min = proc->numOfPages+3;
801096c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096c9:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801096cf:	83 c0 03             	add    $0x3,%eax
801096d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
        for(j=3; j<30; j++){  //find the oldest page
801096d5:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801096dc:	eb 6d                	jmp    8010974b <swapOut+0xaf>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
801096de:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096e8:	89 d0                	mov    %edx,%eax
801096ea:	c1 e0 02             	shl    $0x2,%eax
801096ed:	01 d0                	add    %edx,%eax
801096ef:	c1 e0 02             	shl    $0x2,%eax
801096f2:	01 c8                	add    %ecx,%eax
801096f4:	05 94 00 00 00       	add    $0x94,%eax
801096f9:	8b 00                	mov    (%eax),%eax
801096fb:	85 c0                	test   %eax,%eax
801096fd:	74 48                	je     80109747 <swapOut+0xab>
801096ff:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109706:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109709:	89 d0                	mov    %edx,%eax
8010970b:	c1 e0 02             	shl    $0x2,%eax
8010970e:	01 d0                	add    %edx,%eax
80109710:	c1 e0 02             	shl    $0x2,%eax
80109713:	01 c8                	add    %ecx,%eax
80109715:	05 9c 00 00 00       	add    $0x9c,%eax
8010971a:	8b 00                	mov    (%eax),%eax
8010971c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010971f:	7d 26                	jge    80109747 <swapOut+0xab>
            min = proc->pagesMetaData[j].count;
80109721:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109728:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010972b:	89 d0                	mov    %edx,%eax
8010972d:	c1 e0 02             	shl    $0x2,%eax
80109730:	01 d0                	add    %edx,%eax
80109732:	c1 e0 02             	shl    $0x2,%eax
80109735:	01 c8                	add    %ecx,%eax
80109737:	05 9c 00 00 00       	add    $0x9c,%eax
8010973c:	8b 00                	mov    (%eax),%eax
8010973e:	89 45 ec             	mov    %eax,-0x14(%ebp)
            index = j;
80109741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109744:	89 45 f0             	mov    %eax,-0x10(%ebp)
        break;

      case 3:  //SCFIFO //turn bit off and move to be newest
        while(1){ //untill a good page to swap out is found
        min = proc->numOfPages+3;
        for(j=3; j<30; j++){  //find the oldest page
80109747:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010974b:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
8010974f:	7e 8d                	jle    801096de <swapOut+0x42>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
            min = proc->pagesMetaData[j].count;
            index = j;
          }
        }
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
80109751:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109758:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010975b:	89 d0                	mov    %edx,%eax
8010975d:	c1 e0 02             	shl    $0x2,%eax
80109760:	01 d0                	add    %edx,%eax
80109762:	c1 e0 02             	shl    $0x2,%eax
80109765:	01 c8                	add    %ecx,%eax
80109767:	05 90 00 00 00       	add    $0x90,%eax
8010976c:	8b 10                	mov    (%eax),%edx
8010976e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109774:	8b 40 04             	mov    0x4(%eax),%eax
80109777:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010977e:	00 
8010977f:	89 54 24 04          	mov    %edx,0x4(%esp)
80109783:	89 04 24             	mov    %eax,(%esp)
80109786:	e8 d8 ec ff ff       	call   80108463 <walkpgdir>
8010978b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if (*pte & PTE_A){  //the access flag is on. turn off and give a new counter
8010978e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109791:	8b 00                	mov    (%eax),%eax
80109793:	83 e0 20             	and    $0x20,%eax
80109796:	85 c0                	test   %eax,%eax
80109798:	74 4c                	je     801097e6 <swapOut+0x14a>
            *pte &= !PTE_A; //turn off
8010979a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010979d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[index].count = proc->numOfPages;  
801097a3:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
801097aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801097b0:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
801097b6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097b9:	89 d0                	mov    %edx,%eax
801097bb:	c1 e0 02             	shl    $0x2,%eax
801097be:	01 d0                	add    %edx,%eax
801097c0:	c1 e0 02             	shl    $0x2,%eax
801097c3:	01 d8                	add    %ebx,%eax
801097c5:	05 9c 00 00 00       	add    $0x9c,%eax
801097ca:	89 08                	mov    %ecx,(%eax)
            proc->numOfPages++; //TODO: SEMAPHOR!???
801097cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801097d2:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
801097d8:	83 c2 01             	add    $0x1,%edx
801097db:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
          }
        else{//it is a good one
          break;
        }
      }
801097e1:	e9 dd fe ff ff       	jmp    801096c3 <swapOut+0x27>
            *pte &= !PTE_A; //turn off
            proc->pagesMetaData[index].count = proc->numOfPages;  
            proc->numOfPages++; //TODO: SEMAPHOR!???
          }
        else{//it is a good one
          break;
801097e6:	90                   	nop
        }
      }
      break;
801097e7:	90                   	nop
        }
        break;
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
801097e8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097ef:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097f2:	89 d0                	mov    %edx,%eax
801097f4:	c1 e0 02             	shl    $0x2,%eax
801097f7:	01 d0                	add    %edx,%eax
801097f9:	c1 e0 02             	shl    $0x2,%eax
801097fc:	01 c8                	add    %ecx,%eax
801097fe:	05 94 00 00 00       	add    $0x94,%eax
80109803:	8b 00                	mov    (%eax),%eax
80109805:	85 c0                	test   %eax,%eax
80109807:	0f 84 28 02 00 00    	je     80109a35 <swapOut+0x399>
      cprintf("choose to swap out %x\n",proc->pagesMetaData[index].va);
8010980d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109814:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109817:	89 d0                	mov    %edx,%eax
80109819:	c1 e0 02             	shl    $0x2,%eax
8010981c:	01 d0                	add    %edx,%eax
8010981e:	c1 e0 02             	shl    $0x2,%eax
80109821:	01 c8                	add    %ecx,%eax
80109823:	05 90 00 00 00       	add    $0x90,%eax
80109828:	8b 00                	mov    (%eax),%eax
8010982a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010982e:	c7 04 24 43 a5 10 80 	movl   $0x8010a543,(%esp)
80109835:	e8 66 6b ff ff       	call   801003a0 <cprintf>
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
8010983a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109841:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109844:	89 d0                	mov    %edx,%eax
80109846:	c1 e0 02             	shl    $0x2,%eax
80109849:	01 d0                	add    %edx,%eax
8010984b:	c1 e0 02             	shl    $0x2,%eax
8010984e:	01 c8                	add    %ecx,%eax
80109850:	05 90 00 00 00       	add    $0x90,%eax
80109855:	8b 00                	mov    (%eax),%eax
80109857:	89 04 24             	mov    %eax,(%esp)
8010985a:	e8 57 fa ff ff       	call   801092b6 <findNextOpenPage>
8010985f:	89 45 e0             	mov    %eax,-0x20(%ebp)
      cprintf("after offset\n");
80109862:	c7 04 24 5a a5 10 80 	movl   $0x8010a55a,(%esp)
80109869:	e8 32 6b ff ff       	call   801003a0 <cprintf>
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
8010986e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109875:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109878:	89 d0                	mov    %edx,%eax
8010987a:	c1 e0 02             	shl    $0x2,%eax
8010987d:	01 d0                	add    %edx,%eax
8010987f:	c1 e0 02             	shl    $0x2,%eax
80109882:	01 c8                	add    %ecx,%eax
80109884:	05 90 00 00 00       	add    $0x90,%eax
80109889:	8b 10                	mov    (%eax),%edx
8010988b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109891:	8b 40 04             	mov    0x4(%eax),%eax
80109894:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010989b:	00 
8010989c:	89 54 24 04          	mov    %edx,0x4(%esp)
801098a0:	89 04 24             	mov    %eax,(%esp)
801098a3:	e8 bb eb ff ff       	call   80108463 <walkpgdir>
801098a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      cprintf("after walkpgdir\n");
801098ab:	c7 04 24 68 a5 10 80 	movl   $0x8010a568,(%esp)
801098b2:	e8 e9 6a ff ff       	call   801003a0 <cprintf>
      if(!(*pte & PTE_PG)){
801098b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801098ba:	8b 00                	mov    (%eax),%eax
801098bc:	25 00 02 00 00       	and    $0x200,%eax
801098c1:	85 c0                	test   %eax,%eax
801098c3:	75 0f                	jne    801098d4 <swapOut+0x238>
        *pte |= PTE_PG; //turn on    
801098c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801098c8:	8b 00                	mov    (%eax),%eax
801098ca:	80 cc 02             	or     $0x2,%ah
801098cd:	89 c2                	mov    %eax,%edx
801098cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801098d2:	89 10                	mov    %edx,(%eax)
      }
      cprintf("after setting PG\n");
801098d4:	c7 04 24 79 a5 10 80 	movl   $0x8010a579,(%esp)
801098db:	e8 c0 6a ff ff       	call   801003a0 <cprintf>
      proc->pagesMetaData[index].fileOffset = offset;
801098e0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801098e7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098ea:	89 d0                	mov    %edx,%eax
801098ec:	c1 e0 02             	shl    $0x2,%eax
801098ef:	01 d0                	add    %edx,%eax
801098f1:	c1 e0 02             	shl    $0x2,%eax
801098f4:	01 c8                	add    %ecx,%eax
801098f6:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
801098fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098ff:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
80109901:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109908:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010990b:	89 d0                	mov    %edx,%eax
8010990d:	c1 e0 02             	shl    $0x2,%eax
80109910:	01 d0                	add    %edx,%eax
80109912:	c1 e0 02             	shl    $0x2,%eax
80109915:	01 c8                	add    %ecx,%eax
80109917:	05 94 00 00 00       	add    $0x94,%eax
8010991c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
80109922:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109929:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010992f:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80109935:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109938:	89 d0                	mov    %edx,%eax
8010993a:	c1 e0 02             	shl    $0x2,%eax
8010993d:	01 d0                	add    %edx,%eax
8010993f:	c1 e0 02             	shl    $0x2,%eax
80109942:	01 d8                	add    %ebx,%eax
80109944:	05 9c 00 00 00       	add    $0x9c,%eax
80109949:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
8010994b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109951:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80109957:	83 c2 01             	add    $0x1,%edx
8010995a:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      memmove(buf,proc->pagesMetaData[index].va,PGSIZE);
80109960:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109967:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010996a:	89 d0                	mov    %edx,%eax
8010996c:	c1 e0 02             	shl    $0x2,%eax
8010996f:	01 d0                	add    %edx,%eax
80109971:	c1 e0 02             	shl    $0x2,%eax
80109974:	01 c8                	add    %ecx,%eax
80109976:	05 90 00 00 00       	add    $0x90,%eax
8010997b:	8b 00                	mov    (%eax),%eax
8010997d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109984:	00 
80109985:	89 44 24 04          	mov    %eax,0x4(%esp)
80109989:	8d 85 dc ef ff ff    	lea    -0x1024(%ebp),%eax
8010998f:	89 04 24             	mov    %eax,(%esp)
80109992:	e8 20 c1 ff ff       	call   80105ab7 <memmove>
      cprintf("after memmove\n");
80109997:	c7 04 24 8b a5 10 80 	movl   $0x8010a58b,(%esp)
8010999e:	e8 fd 69 ff ff       	call   801003a0 <cprintf>
      writeToSwapFile(proc,buf,offset,PGSIZE);
801099a3:	8b 55 e0             	mov    -0x20(%ebp),%edx
801099a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801099ac:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801099b3:	00 
801099b4:	89 54 24 08          	mov    %edx,0x8(%esp)
801099b8:	8d 95 dc ef ff ff    	lea    -0x1024(%ebp),%edx
801099be:	89 54 24 04          	mov    %edx,0x4(%esp)
801099c2:	89 04 24             	mov    %eax,(%esp)
801099c5:	e8 86 8f ff ff       	call   80102950 <writeToSwapFile>
      cprintf("after write\n");
801099ca:	c7 04 24 9a a5 10 80 	movl   $0x8010a59a,(%esp)
801099d1:	e8 ca 69 ff ff       	call   801003a0 <cprintf>
      pa = PTE_ADDR(*pte);
801099d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801099d9:	8b 00                	mov    (%eax),%eax
801099db:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801099e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
      cprintf("after pa\n");
801099e3:	c7 04 24 a7 a5 10 80 	movl   $0x8010a5a7,(%esp)
801099ea:	e8 b1 69 ff ff       	call   801003a0 <cprintf>
      if(pa == 0)
801099ef:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801099f3:	75 0c                	jne    80109a01 <swapOut+0x365>
        panic("kfree swapOut");
801099f5:	c7 04 24 b1 a5 10 80 	movl   $0x8010a5b1,(%esp)
801099fc:	e8 39 6b ff ff       	call   8010053a <panic>
      kfree((char *)p2v(pa)); 
80109a01:	8b 45 dc             	mov    -0x24(%ebp),%eax
80109a04:	89 04 24             	mov    %eax,(%esp)
80109a07:	e8 d4 e5 ff ff       	call   80107fe0 <p2v>
80109a0c:	89 04 24             	mov    %eax,(%esp)
80109a0f:	e8 52 97 ff ff       	call   80103166 <kfree>
      cprintf("after kfree\n");
80109a14:	c7 04 24 bf a5 10 80 	movl   $0x8010a5bf,(%esp)
80109a1b:	e8 80 69 ff ff       	call   801003a0 <cprintf>
      *pte = 0 | PTE_W | PTE_U | PTE_PG;
80109a20:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109a23:	c7 00 06 02 00 00    	movl   $0x206,(%eax)
      cprintf("after pte\n");
80109a29:	c7 04 24 cc a5 10 80 	movl   $0x8010a5cc,(%esp)
80109a30:	e8 6b 69 ff ff       	call   801003a0 <cprintf>
    }
  }
80109a35:	81 c4 34 10 00 00    	add    $0x1034,%esp
80109a3b:	5b                   	pop    %ebx
80109a3c:	5d                   	pop    %ebp
80109a3d:	c3                   	ret    

80109a3e <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109a3e:	55                   	push   %ebp
80109a3f:	89 e5                	mov    %esp,%ebp
80109a41:	53                   	push   %ebx
80109a42:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
80109a45:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
80109a4c:	e9 c8 00 00 00       	jmp    80109b19 <updateAge+0xdb>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=0){ //only if on RAM
80109a51:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a54:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a57:	89 d0                	mov    %edx,%eax
80109a59:	c1 e0 02             	shl    $0x2,%eax
80109a5c:	01 d0                	add    %edx,%eax
80109a5e:	c1 e0 02             	shl    $0x2,%eax
80109a61:	01 c8                	add    %ecx,%eax
80109a63:	05 94 00 00 00       	add    $0x94,%eax
80109a68:	8b 00                	mov    (%eax),%eax
80109a6a:	85 c0                	test   %eax,%eax
80109a6c:	0f 84 a3 00 00 00    	je     80109b15 <updateAge+0xd7>
80109a72:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a75:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a78:	89 d0                	mov    %edx,%eax
80109a7a:	c1 e0 02             	shl    $0x2,%eax
80109a7d:	01 d0                	add    %edx,%eax
80109a7f:	c1 e0 02             	shl    $0x2,%eax
80109a82:	01 c8                	add    %ecx,%eax
80109a84:	05 90 00 00 00       	add    $0x90,%eax
80109a89:	8b 00                	mov    (%eax),%eax
80109a8b:	85 c0                	test   %eax,%eax
80109a8d:	0f 84 82 00 00 00    	je     80109b15 <updateAge+0xd7>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
80109a93:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a96:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a99:	89 d0                	mov    %edx,%eax
80109a9b:	c1 e0 02             	shl    $0x2,%eax
80109a9e:	01 d0                	add    %edx,%eax
80109aa0:	c1 e0 02             	shl    $0x2,%eax
80109aa3:	01 c8                	add    %ecx,%eax
80109aa5:	05 a0 00 00 00       	add    $0xa0,%eax
80109aaa:	0f b6 00             	movzbl (%eax),%eax
80109aad:	d0 f8                	sar    %al
80109aaf:	89 c1                	mov    %eax,%ecx
80109ab1:	8b 5d 08             	mov    0x8(%ebp),%ebx
80109ab4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109ab7:	89 d0                	mov    %edx,%eax
80109ab9:	c1 e0 02             	shl    $0x2,%eax
80109abc:	01 d0                	add    %edx,%eax
80109abe:	c1 e0 02             	shl    $0x2,%eax
80109ac1:	01 d8                	add    %ebx,%eax
80109ac3:	05 a0 00 00 00       	add    $0xa0,%eax
80109ac8:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
80109aca:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109acd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109ad0:	89 d0                	mov    %edx,%eax
80109ad2:	c1 e0 02             	shl    $0x2,%eax
80109ad5:	01 d0                	add    %edx,%eax
80109ad7:	c1 e0 02             	shl    $0x2,%eax
80109ada:	01 c8                	add    %ecx,%eax
80109adc:	05 90 00 00 00       	add    $0x90,%eax
80109ae1:	8b 10                	mov    (%eax),%edx
80109ae3:	8b 45 08             	mov    0x8(%ebp),%eax
80109ae6:	8b 40 04             	mov    0x4(%eax),%eax
80109ae9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109af0:	00 
80109af1:	89 54 24 04          	mov    %edx,0x4(%esp)
80109af5:	89 04 24             	mov    %eax,(%esp)
80109af8:	e8 66 e9 ff ff       	call   80108463 <walkpgdir>
80109afd:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if(!(*pte & PTE_A)){
80109b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b03:	8b 00                	mov    (%eax),%eax
80109b05:	83 e0 20             	and    $0x20,%eax
80109b08:	85 c0                	test   %eax,%eax
80109b0a:	75 09                	jne    80109b15 <updateAge+0xd7>
          *pte &= !PTE_A; //turn off bit 
80109b0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b0f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
80109b15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109b19:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109b1d:	0f 8e 2e ff ff ff    	jle    80109a51 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
        if(!(*pte & PTE_A)){
          *pte &= !PTE_A; //turn off bit 
      }
    }
  }
80109b23:	83 c4 24             	add    $0x24,%esp
80109b26:	5b                   	pop    %ebx
80109b27:	5d                   	pop    %ebp
80109b28:	c3                   	ret    

80109b29 <clearAllPages>:

void
clearAllPages(struct proc *p){
80109b29:	55                   	push   %ebp
80109b2a:	89 e5                	mov    %esp,%ebp
80109b2c:	83 ec 28             	sub    $0x28,%esp
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109b2f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109b36:	e9 cd 00 00 00       	jmp    80109c08 <clearAllPages+0xdf>
    if(p->pagesMetaData[i].va != (char *) -1){
80109b3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109b3e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109b41:	89 d0                	mov    %edx,%eax
80109b43:	c1 e0 02             	shl    $0x2,%eax
80109b46:	01 d0                	add    %edx,%eax
80109b48:	c1 e0 02             	shl    $0x2,%eax
80109b4b:	01 c8                	add    %ecx,%eax
80109b4d:	05 90 00 00 00       	add    $0x90,%eax
80109b52:	8b 00                	mov    (%eax),%eax
80109b54:	83 f8 ff             	cmp    $0xffffffff,%eax
80109b57:	0f 84 a7 00 00 00    	je     80109c04 <clearAllPages+0xdb>
      pte = walkpgdir(p->pgdir,proc->pagesMetaData[i].va,0);
80109b5d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109b64:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109b67:	89 d0                	mov    %edx,%eax
80109b69:	c1 e0 02             	shl    $0x2,%eax
80109b6c:	01 d0                	add    %edx,%eax
80109b6e:	c1 e0 02             	shl    $0x2,%eax
80109b71:	01 c8                	add    %ecx,%eax
80109b73:	05 90 00 00 00       	add    $0x90,%eax
80109b78:	8b 10                	mov    (%eax),%edx
80109b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80109b7d:	8b 40 04             	mov    0x4(%eax),%eax
80109b80:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109b87:	00 
80109b88:	89 54 24 04          	mov    %edx,0x4(%esp)
80109b8c:	89 04 24             	mov    %eax,(%esp)
80109b8f:	e8 cf e8 ff ff       	call   80108463 <walkpgdir>
80109b94:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(!pte){
80109b97:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109b9b:	74 67                	je     80109c04 <clearAllPages+0xdb>

      }
      else if((*pte & PTE_P) != 0){
80109b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109ba0:	8b 00                	mov    (%eax),%eax
80109ba2:	83 e0 01             	and    $0x1,%eax
80109ba5:	85 c0                	test   %eax,%eax
80109ba7:	74 5b                	je     80109c04 <clearAllPages+0xdb>
        pa = PTE_ADDR(*pte);
80109ba9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109bac:	8b 00                	mov    (%eax),%eax
80109bae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109bb3:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if(pa == 0){
80109bb6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109bba:	75 0e                	jne    80109bca <clearAllPages+0xa1>
          cprintf("already free\n");
80109bbc:	c7 04 24 d7 a5 10 80 	movl   $0x8010a5d7,(%esp)
80109bc3:	e8 d8 67 ff ff       	call   801003a0 <cprintf>
80109bc8:	eb 3a                	jmp    80109c04 <clearAllPages+0xdb>
        }
        else{
          cprintf("clearing\n");
80109bca:	c7 04 24 e5 a5 10 80 	movl   $0x8010a5e5,(%esp)
80109bd1:	e8 ca 67 ff ff       	call   801003a0 <cprintf>
          char *v = p2v(pa);
80109bd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109bd9:	89 04 24             	mov    %eax,(%esp)
80109bdc:	e8 ff e3 ff ff       	call   80107fe0 <p2v>
80109be1:	89 45 e8             	mov    %eax,-0x18(%ebp)
          kfree(v);
80109be4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109be7:	89 04 24             	mov    %eax,(%esp)
80109bea:	e8 77 95 ff ff       	call   80103166 <kfree>
          *pte = 0;
80109bef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109bf2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
          cprintf("finished\n");
80109bf8:	c7 04 24 ef a5 10 80 	movl   $0x8010a5ef,(%esp)
80109bff:	e8 9c 67 ff ff       	call   801003a0 <cprintf>
void
clearAllPages(struct proc *p){
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109c04:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109c08:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109c0c:	0f 8e 29 ff ff ff    	jle    80109b3b <clearAllPages+0x12>
          cprintf("finished\n");
        }
      }
    }
  }
}
80109c12:	c9                   	leave  
80109c13:	c3                   	ret    
