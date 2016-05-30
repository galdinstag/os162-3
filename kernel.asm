
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
8010002d:	b8 ca 3e 10 80       	mov    $0x80103eca,%eax
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
8010003a:	c7 44 24 04 a8 9b 10 	movl   $0x80109ba8,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 4f 57 00 00       	call   8010579d <initlock>

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
801000bd:	e8 fc 56 00 00       	call   801057be <acquire>

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
80100104:	e8 17 57 00 00       	call   80105820 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 4c 53 00 00       	call   80105470 <sleep>
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
8010017c:	e8 9f 56 00 00       	call   80105820 <release>
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
80100198:	c7 04 24 af 9b 10 80 	movl   $0x80109baf,(%esp)
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
801001ef:	c7 04 24 c0 9b 10 80 	movl   $0x80109bc0,(%esp)
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
80100229:	c7 04 24 c7 9b 10 80 	movl   $0x80109bc7,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 7d 55 00 00       	call   801057be <acquire>

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
8010029d:	e8 aa 52 00 00       	call   8010554c <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 72 55 00 00       	call   80105820 <release>
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
801003bb:	e8 fe 53 00 00       	call   801057be <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 ce 9b 10 80 	movl   $0x80109bce,(%esp)
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
801004b0:	c7 45 ec d7 9b 10 80 	movl   $0x80109bd7,-0x14(%ebp)
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
80100533:	e8 e8 52 00 00       	call   80105820 <release>
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
8010055f:	c7 04 24 de 9b 10 80 	movl   $0x80109bde,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 ed 9b 10 80 	movl   $0x80109bed,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 db 52 00 00       	call   8010586f <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 ef 9b 10 80 	movl   $0x80109bef,(%esp)
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
80100699:	c7 04 24 f3 9b 10 80 	movl   $0x80109bf3,(%esp)
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
801006cd:	e8 0f 54 00 00       	call   80105ae1 <memmove>
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
801006fc:	e8 11 53 00 00       	call   80105a12 <memset>
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
80100791:	e8 e0 6c 00 00       	call   80107476 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 d4 6c 00 00       	call   80107476 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 c8 6c 00 00       	call   80107476 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 bb 6c 00 00       	call   80107476 <uartputc>
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
801007dc:	e8 dd 4f 00 00       	call   801057be <acquire>
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
80100917:	e8 30 4c 00 00       	call   8010554c <wakeup>
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
80100938:	e8 e3 4e 00 00       	call   80105820 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 aa 4c 00 00       	call   801055f2 <procdump>
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
80100968:	e8 51 4e 00 00       	call   801057be <acquire>
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
80100988:	e8 93 4e 00 00       	call   80105820 <release>
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
801009b1:	e8 ba 4a 00 00       	call   80105470 <sleep>

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
80100a2d:	e8 ee 4d 00 00       	call   80105820 <release>
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
80100a61:	e8 58 4d 00 00       	call   801057be <acquire>
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
80100a9b:	e8 80 4d 00 00       	call   80105820 <release>
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
80100ab6:	c7 44 24 04 06 9c 10 	movl   $0x80109c06,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 d3 4c 00 00       	call   8010579d <initlock>

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
80100aef:	e8 6e 3a 00 00       	call   80104562 <picenable>
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
80100b13:	e8 ab 30 00 00       	call   80103bc3 <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 47 1a 00 00       	call   8010256a <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 16 31 00 00       	call   80103c47 <end_op>
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
80100b8e:	e8 34 7a 00 00       	call   801085c7 <setupkvm>
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
80100ccf:	e8 c1 7c 00 00       	call   80108995 <allocuvm>
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
80100d0d:	e8 98 7b 00 00       	call   801088aa <loaduvm>
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
80100d46:	e8 fc 2e 00 00       	call   80103c47 <end_op>
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
80100d86:	e8 0a 7c 00 00       	call   80108995 <allocuvm>
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
80100dab:	e8 01 81 00 00       	call   80108eb1 <clearpteu>
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
80100de1:	e8 96 4e 00 00       	call   80105c7c <strlen>
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
80100e0a:	e8 6d 4e 00 00       	call   80105c7c <strlen>
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
80100e3a:	e8 f8 83 00 00       	call   80109237 <copyout>
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
80100ee1:	e8 51 83 00 00       	call   80109237 <copyout>
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
80100f39:	e8 f4 4c 00 00       	call   80105c32 <safestrcpy>

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
80100fb5:	e8 fe 76 00 00       	call   801086b8 <switchuvm>
  freevm(oldpgdir,0);
80100fba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100fc1:	00 
80100fc2:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100fc5:	89 04 24             	mov    %eax,(%esp)
80100fc8:	e8 40 7e 00 00       	call   80108e0d <freevm>
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
80100fe8:	e8 20 7e 00 00       	call   80108e0d <freevm>
  if(ip){
80100fed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ff1:	74 10                	je     80101003 <exec+0x4f9>
    iunlockput(ip);
80100ff3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ff6:	89 04 24             	mov    %eax,(%esp)
80100ff9:	e8 45 0c 00 00       	call   80101c43 <iunlockput>
    end_op();
80100ffe:	e8 44 2c 00 00       	call   80103c47 <end_op>
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
80101010:	c7 44 24 04 0e 9c 10 	movl   $0x80109c0e,0x4(%esp)
80101017:	80 
80101018:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010101f:	e8 79 47 00 00       	call   8010579d <initlock>
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
80101033:	e8 86 47 00 00       	call   801057be <acquire>
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
8010105c:	e8 bf 47 00 00       	call   80105820 <release>
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
8010107a:	e8 a1 47 00 00       	call   80105820 <release>
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
80101093:	e8 26 47 00 00       	call   801057be <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <filedup+0x28>
    panic("filedup");
801010a2:	c7 04 24 15 9c 10 80 	movl   $0x80109c15,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 01             	lea    0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bd:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010c4:	e8 57 47 00 00       	call   80105820 <release>
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
801010db:	e8 de 46 00 00       	call   801057be <acquire>
  if(f->ref < 1)
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 04             	mov    0x4(%eax),%eax
801010e6:	85 c0                	test   %eax,%eax
801010e8:	7f 0c                	jg     801010f6 <fileclose+0x28>
    panic("fileclose");
801010ea:	c7 04 24 1d 9c 10 80 	movl   $0x80109c1d,(%esp)
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
80101116:	e8 05 47 00 00       	call   80105820 <release>
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
80101160:	e8 bb 46 00 00       	call   80105820 <release>
  
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
8010117e:	e8 8f 36 00 00       	call   80104812 <pipeclose>
80101183:	eb 1d                	jmp    801011a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101185:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101188:	83 f8 02             	cmp    $0x2,%eax
8010118b:	75 15                	jne    801011a2 <fileclose+0xd4>
    begin_op();
8010118d:	e8 31 2a 00 00       	call   80103bc3 <begin_op>
    iput(ff.ip);
80101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 d5 09 00 00       	call   80101b72 <iput>
    end_op();
8010119d:	e8 a5 2a 00 00       	call   80103c47 <end_op>
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
8010122f:	e8 5f 37 00 00       	call   80104993 <piperead>
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
801012a1:	c7 04 24 27 9c 10 80 	movl   $0x80109c27,(%esp)
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
801012ec:	e8 b3 35 00 00       	call   801048a4 <pipewrite>
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
80101332:	e8 8c 28 00 00       	call   80103bc3 <begin_op>
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
80101398:	e8 aa 28 00 00       	call   80103c47 <end_op>

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
801013ad:	c7 04 24 30 9c 10 80 	movl   $0x80109c30,(%esp)
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
801013df:	c7 04 24 40 9c 10 80 	movl   $0x80109c40,(%esp)
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
80101425:	e8 b7 46 00 00       	call   80105ae1 <memmove>
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
8010146b:	e8 a2 45 00 00       	call   80105a12 <memset>
  log_write(bp);
80101470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 53 29 00 00       	call   80103dce <log_write>
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
80101541:	e8 88 28 00 00       	call   80103dce <log_write>
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
801015b8:	c7 04 24 4c 9c 10 80 	movl   $0x80109c4c,(%esp)
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
80101647:	c7 04 24 62 9c 10 80 	movl   $0x80109c62,(%esp)
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
8010167f:	e8 4a 27 00 00       	call   80103dce <log_write>
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
8010169a:	c7 44 24 04 75 9c 10 	movl   $0x80109c75,0x4(%esp)
801016a1:	80 
801016a2:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801016a9:	e8 ef 40 00 00       	call   8010579d <initlock>
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
8010170e:	c7 04 24 7c 9c 10 80 	movl   $0x80109c7c,(%esp)
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
80101791:	e8 7c 42 00 00       	call   80105a12 <memset>
      dip->type = type;
80101796:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101799:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
8010179d:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 23 26 00 00       	call   80103dce <log_write>
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
801017e9:	c7 04 24 cf 9c 10 80 	movl   $0x80109ccf,(%esp)
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
80101898:	e8 44 42 00 00       	call   80105ae1 <memmove>
  log_write(bp);
8010189d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a0:	89 04 24             	mov    %eax,(%esp)
801018a3:	e8 26 25 00 00       	call   80103dce <log_write>
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
801018c2:	e8 f7 3e 00 00       	call   801057be <acquire>

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
8010190c:	e8 0f 3f 00 00       	call   80105820 <release>
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
8010193f:	c7 04 24 e1 9c 10 80 	movl   $0x80109ce1,(%esp)
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
8010197d:	e8 9e 3e 00 00       	call   80105820 <release>

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
80101994:	e8 25 3e 00 00       	call   801057be <acquire>
  ip->ref++;
80101999:	8b 45 08             	mov    0x8(%ebp),%eax
8010199c:	8b 40 08             	mov    0x8(%eax),%eax
8010199f:	8d 50 01             	lea    0x1(%eax),%edx
801019a2:	8b 45 08             	mov    0x8(%ebp),%eax
801019a5:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019a8:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019af:	e8 6c 3e 00 00       	call   80105820 <release>
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
801019cf:	c7 04 24 f1 9c 10 80 	movl   $0x80109cf1,(%esp)
801019d6:	e8 5f eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019db:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019e2:	e8 d7 3d 00 00       	call   801057be <acquire>
  while(ip->flags & I_BUSY)
801019e7:	eb 13                	jmp    801019fc <ilock+0x43>
    sleep(ip, &icache.lock);
801019e9:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
801019f0:	80 
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	89 04 24             	mov    %eax,(%esp)
801019f7:	e8 74 3a 00 00       	call   80105470 <sleep>

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
80101a21:	e8 fa 3d 00 00       	call   80105820 <release>

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
80101ad2:	e8 0a 40 00 00       	call   80105ae1 <memmove>
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
80101aff:	c7 04 24 f7 9c 10 80 	movl   $0x80109cf7,(%esp)
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
80101b30:	c7 04 24 06 9d 10 80 	movl   $0x80109d06,(%esp)
80101b37:	e8 fe e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b43:	e8 76 3c 00 00       	call   801057be <acquire>
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
80101b5f:	e8 e8 39 00 00       	call   8010554c <wakeup>
  release(&icache.lock);
80101b64:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b6b:	e8 b0 3c 00 00       	call   80105820 <release>
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
80101b7f:	e8 3a 3c 00 00       	call   801057be <acquire>
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
80101bbd:	c7 04 24 0e 9d 10 80 	movl   $0x80109d0e,(%esp)
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
80101be1:	e8 3a 3c 00 00       	call   80105820 <release>
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
80101c0c:	e8 ad 3b 00 00       	call   801057be <acquire>
    ip->flags = 0;
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	89 04 24             	mov    %eax,(%esp)
80101c21:	e8 26 39 00 00       	call   8010554c <wakeup>
  }
  ip->ref--;
80101c26:	8b 45 08             	mov    0x8(%ebp),%eax
80101c29:	8b 40 08             	mov    0x8(%eax),%eax
80101c2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c32:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c35:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c3c:	e8 df 3b 00 00       	call   80105820 <release>
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
80101d47:	e8 82 20 00 00       	call   80103dce <log_write>
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
80101d5c:	c7 04 24 18 9d 10 80 	movl   $0x80109d18,(%esp)
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
80101ffd:	e8 df 3a 00 00       	call   80105ae1 <memmove>
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
8010215c:	e8 80 39 00 00       	call   80105ae1 <memmove>
    log_write(bp);
80102161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102164:	89 04 24             	mov    %eax,(%esp)
80102167:	e8 62 1c 00 00       	call   80103dce <log_write>
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
801021da:	e8 a5 39 00 00       	call   80105b84 <strncmp>
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
801021f4:	c7 04 24 2b 9d 10 80 	movl   $0x80109d2b,(%esp)
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
80102232:	c7 04 24 3d 9d 10 80 	movl   $0x80109d3d,(%esp)
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
80102317:	c7 04 24 3d 9d 10 80 	movl   $0x80109d3d,(%esp)
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
8010235c:	e8 79 38 00 00       	call   80105bda <strncpy>
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
8010238e:	c7 04 24 4a 9d 10 80 	movl   $0x80109d4a,(%esp)
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
80102413:	e8 c9 36 00 00       	call   80105ae1 <memmove>
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
8010242e:	e8 ae 36 00 00       	call   80105ae1 <memmove>
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
8010267d:	c7 44 24 04 52 9d 10 	movl   $0x80109d52,0x4(%esp)
80102684:	80 
80102685:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80102688:	89 04 24             	mov    %eax,(%esp)
8010268b:	e8 51 34 00 00       	call   80105ae1 <memmove>
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
801026ca:	e8 f4 14 00 00       	call   80103bc3 <begin_op>
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
801026ea:	e8 58 15 00 00       	call   80103c47 <end_op>
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
80102704:	c7 44 24 04 59 9d 10 	movl   $0x80109d59,0x4(%esp)
8010270b:	80 
8010270c:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010270f:	89 04 24             	mov    %eax,(%esp)
80102712:	e8 a8 fa ff ff       	call   801021bf <namecmp>
80102717:	85 c0                	test   %eax,%eax
80102719:	0f 84 45 01 00 00    	je     80102864 <removeSwapFile+0x1f5>
8010271f:	c7 44 24 04 5b 9d 10 	movl   $0x80109d5b,0x4(%esp)
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
80102778:	c7 04 24 5e 9d 10 80 	movl   $0x80109d5e,(%esp)
8010277f:	e8 b6 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
80102784:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102787:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010278b:	66 83 f8 01          	cmp    $0x1,%ax
8010278f:	75 1f                	jne    801027b0 <removeSwapFile+0x141>
80102791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102794:	89 04 24             	mov    %eax,(%esp)
80102797:	e8 50 3b 00 00       	call   801062ec <isdirempty>
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
801027c6:	e8 47 32 00 00       	call   80105a12 <memset>
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
801027f1:	c7 04 24 70 9d 10 80 	movl   $0x80109d70,(%esp)
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
80102858:	e8 ea 13 00 00       	call   80103c47 <end_op>

	return 0;
8010285d:	b8 00 00 00 00       	mov    $0x0,%eax
80102862:	eb 15                	jmp    80102879 <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
80102864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102867:	89 04 24             	mov    %eax,(%esp)
8010286a:	e8 d4 f3 ff ff       	call   80101c43 <iunlockput>
		end_op();
8010286f:	e8 d3 13 00 00       	call   80103c47 <end_op>
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
80102889:	c7 44 24 04 52 9d 10 	movl   $0x80109d52,0x4(%esp)
80102890:	80 
80102891:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102894:	89 04 24             	mov    %eax,(%esp)
80102897:	e8 45 32 00 00       	call   80105ae1 <memmove>
	itoa(p->pid, path+ 6);
8010289c:	8b 45 08             	mov    0x8(%ebp),%eax
8010289f:	8b 40 10             	mov    0x10(%eax),%eax
801028a2:	8d 55 e6             	lea    -0x1a(%ebp),%edx
801028a5:	83 c2 06             	add    $0x6,%edx
801028a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801028ac:	89 04 24             	mov    %eax,(%esp)
801028af:	e8 fa fc ff ff       	call   801025ae <itoa>

    begin_op();
801028b4:	e8 0a 13 00 00       	call   80103bc3 <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
801028b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801028c0:	00 
801028c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801028c8:	00 
801028c9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801028d0:	00 
801028d1:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028d4:	89 04 24             	mov    %eax,(%esp)
801028d7:	e8 56 3c 00 00       	call   80106532 <create>
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
801028ff:	c7 04 24 7f 9d 10 80 	movl   $0x80109d7f,(%esp)
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
80102944:	e8 fe 12 00 00       	call   80103c47 <end_op>

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
80102a21:	c7 04 24 9b 9d 10 80 	movl   $0x80109d9b,(%esp)
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
80102a9e:	c7 04 24 b1 9d 10 80 	movl   $0x80109db1,(%esp)
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
80102ae9:	c7 04 24 c6 9d 10 80 	movl   $0x80109dc6,(%esp)
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
80102bff:	c7 44 24 04 dc 9d 10 	movl   $0x80109ddc,0x4(%esp)
80102c06:	80 
80102c07:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c0e:	e8 8a 2b 00 00       	call   8010579d <initlock>
  picenable(IRQ_IDE);
80102c13:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c1a:	e8 43 19 00 00       	call   80104562 <picenable>
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
80102cab:	c7 04 24 e0 9d 10 80 	movl   $0x80109de0,(%esp)
80102cb2:	e8 83 d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cba:	8b 40 08             	mov    0x8(%eax),%eax
80102cbd:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102cc2:	76 0c                	jbe    80102cd0 <idestart+0x31>
    panic("incorrect blockno");
80102cc4:	c7 04 24 e9 9d 10 80 	movl   $0x80109de9,(%esp)
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
80102cec:	c7 04 24 e0 9d 10 80 	movl   $0x80109de0,(%esp)
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
80102e08:	e8 b1 29 00 00       	call   801057be <acquire>
  if((b = idequeue) == 0){
80102e0d:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e12:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e19:	75 11                	jne    80102e2c <ideintr+0x31>
    release(&idelock);
80102e1b:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e22:	e8 f9 29 00 00       	call   80105820 <release>
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
80102e95:	e8 b2 26 00 00       	call   8010554c <wakeup>
  
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
80102eb7:	e8 64 29 00 00       	call   80105820 <release>
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
80102ed0:	c7 04 24 fb 9d 10 80 	movl   $0x80109dfb,(%esp)
80102ed7:	e8 5e d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102edc:	8b 45 08             	mov    0x8(%ebp),%eax
80102edf:	8b 00                	mov    (%eax),%eax
80102ee1:	83 e0 06             	and    $0x6,%eax
80102ee4:	83 f8 02             	cmp    $0x2,%eax
80102ee7:	75 0c                	jne    80102ef5 <iderw+0x37>
    panic("iderw: nothing to do");
80102ee9:	c7 04 24 0f 9e 10 80 	movl   $0x80109e0f,(%esp)
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
80102f08:	c7 04 24 24 9e 10 80 	movl   $0x80109e24,(%esp)
80102f0f:	e8 26 d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f14:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f1b:	e8 9e 28 00 00       	call   801057be <acquire>

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
80102f76:	e8 f5 24 00 00       	call   80105470 <sleep>
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
80102f8f:	e8 8c 28 00 00       	call   80105820 <release>
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
8010301d:	c7 04 24 44 9e 10 80 	movl   $0x80109e44,(%esp)
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
801030d7:	c7 44 24 04 76 9e 10 	movl   $0x80109e76,0x4(%esp)
801030de:	80 
801030df:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801030e6:	e8 b2 26 00 00       	call   8010579d <initlock>
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
  if(getPid()){
8010316c:	e8 ec 25 00 00       	call   8010575d <getPid>
80103171:	85 c0                	test   %eax,%eax
80103173:	74 13                	je     80103188 <kfree+0x22>
    cprintf("%x\n",v);
80103175:	8b 45 08             	mov    0x8(%ebp),%eax
80103178:	89 44 24 04          	mov    %eax,0x4(%esp)
8010317c:	c7 04 24 7b 9e 10 80 	movl   $0x80109e7b,(%esp)
80103183:	e8 18 d2 ff ff       	call   801003a0 <cprintf>
  }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
80103188:	8b 45 08             	mov    0x8(%ebp),%eax
8010318b:	25 ff 0f 00 00       	and    $0xfff,%eax
80103190:	85 c0                	test   %eax,%eax
80103192:	75 1b                	jne    801031af <kfree+0x49>
80103194:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
8010319b:	72 12                	jb     801031af <kfree+0x49>
8010319d:	8b 45 08             	mov    0x8(%ebp),%eax
801031a0:	89 04 24             	mov    %eax,(%esp)
801031a3:	e8 1c ff ff ff       	call   801030c4 <v2p>
801031a8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031ad:	76 50                	jbe    801031ff <kfree+0x99>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
801031af:	8b 45 08             	mov    0x8(%ebp),%eax
801031b2:	89 04 24             	mov    %eax,(%esp)
801031b5:	e8 0a ff ff ff       	call   801030c4 <v2p>
801031ba:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031bf:	0f 97 c0             	seta   %al
801031c2:	0f b6 d0             	movzbl %al,%edx
801031c5:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
801031cc:	0f 92 c0             	setb   %al
801031cf:	0f b6 c0             	movzbl %al,%eax
801031d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801031d5:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
801031db:	89 54 24 0c          	mov    %edx,0xc(%esp)
801031df:	89 44 24 08          	mov    %eax,0x8(%esp)
801031e3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801031e7:	c7 04 24 7f 9e 10 80 	movl   $0x80109e7f,(%esp)
801031ee:	e8 ad d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031f3:	c7 04 24 96 9e 10 80 	movl   $0x80109e96,(%esp)
801031fa:	e8 3b d3 ff ff       	call   8010053a <panic>
  }

  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  if(getPid()){
801031ff:	e8 59 25 00 00       	call   8010575d <getPid>
80103204:	85 c0                	test   %eax,%eax
80103206:	74 0c                	je     80103214 <kfree+0xae>
    cprintf("after memset\n");
80103208:	c7 04 24 a1 9e 10 80 	movl   $0x80109ea1,(%esp)
8010320f:	e8 8c d1 ff ff       	call   801003a0 <cprintf>
  }
  if(kmem.use_lock)
80103214:	a1 54 42 11 80       	mov    0x80114254,%eax
80103219:	85 c0                	test   %eax,%eax
8010321b:	74 0c                	je     80103229 <kfree+0xc3>
    acquire(&kmem.lock);
8010321d:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103224:	e8 95 25 00 00       	call   801057be <acquire>
  r = (struct run*)v;
80103229:	8b 45 08             	mov    0x8(%ebp),%eax
8010322c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
8010322f:	8b 15 58 42 11 80    	mov    0x80114258,%edx
80103235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103238:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
8010323a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010323d:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103242:	a1 54 42 11 80       	mov    0x80114254,%eax
80103247:	85 c0                	test   %eax,%eax
80103249:	74 0c                	je     80103257 <kfree+0xf1>
    release(&kmem.lock);
8010324b:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103252:	e8 c9 25 00 00       	call   80105820 <release>
}
80103257:	c9                   	leave  
80103258:	c3                   	ret    

80103259 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103259:	55                   	push   %ebp
8010325a:	89 e5                	mov    %esp,%ebp
8010325c:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
8010325f:	a1 54 42 11 80       	mov    0x80114254,%eax
80103264:	85 c0                	test   %eax,%eax
80103266:	74 0c                	je     80103274 <kalloc+0x1b>
    acquire(&kmem.lock);
80103268:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010326f:	e8 4a 25 00 00       	call   801057be <acquire>
  r = kmem.freelist;
80103274:	a1 58 42 11 80       	mov    0x80114258,%eax
80103279:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
8010327c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103280:	74 0a                	je     8010328c <kalloc+0x33>
    kmem.freelist = r->next;
80103282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103285:	8b 00                	mov    (%eax),%eax
80103287:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
8010328c:	a1 54 42 11 80       	mov    0x80114254,%eax
80103291:	85 c0                	test   %eax,%eax
80103293:	74 0c                	je     801032a1 <kalloc+0x48>
    release(&kmem.lock);
80103295:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010329c:	e8 7f 25 00 00       	call   80105820 <release>
  return (char*)r;
801032a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801032a4:	c9                   	leave  
801032a5:	c3                   	ret    

801032a6 <countPages>:

int
countPages(){
801032a6:	55                   	push   %ebp
801032a7:	89 e5                	mov    %esp,%ebp
801032a9:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
801032ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
801032b3:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032ba:	e8 ff 24 00 00       	call   801057be <acquire>
  r = kmem.freelist;
801032bf:	a1 58 42 11 80       	mov    0x80114258,%eax
801032c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
801032c7:	eb 0c                	jmp    801032d5 <countPages+0x2f>
    result++;
801032c9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
801032cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032d0:	8b 00                	mov    (%eax),%eax
801032d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
801032d5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032d9:	75 ee                	jne    801032c9 <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032db:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032e2:	e8 39 25 00 00       	call   80105820 <release>
  return result;
801032e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032ea:	c9                   	leave  
801032eb:	c3                   	ret    

801032ec <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032ec:	55                   	push   %ebp
801032ed:	89 e5                	mov    %esp,%ebp
801032ef:	83 ec 14             	sub    $0x14,%esp
801032f2:	8b 45 08             	mov    0x8(%ebp),%eax
801032f5:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032f9:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032fd:	89 c2                	mov    %eax,%edx
801032ff:	ec                   	in     (%dx),%al
80103300:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103303:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103307:	c9                   	leave  
80103308:	c3                   	ret    

80103309 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103309:	55                   	push   %ebp
8010330a:	89 e5                	mov    %esp,%ebp
8010330c:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
8010330f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103316:	e8 d1 ff ff ff       	call   801032ec <inb>
8010331b:	0f b6 c0             	movzbl %al,%eax
8010331e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103321:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103324:	83 e0 01             	and    $0x1,%eax
80103327:	85 c0                	test   %eax,%eax
80103329:	75 0a                	jne    80103335 <kbdgetc+0x2c>
    return -1;
8010332b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103330:	e9 25 01 00 00       	jmp    8010345a <kbdgetc+0x151>
  data = inb(KBDATAP);
80103335:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
8010333c:	e8 ab ff ff ff       	call   801032ec <inb>
80103341:	0f b6 c0             	movzbl %al,%eax
80103344:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103347:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
8010334e:	75 17                	jne    80103367 <kbdgetc+0x5e>
    shift |= E0ESC;
80103350:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103355:	83 c8 40             	or     $0x40,%eax
80103358:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
8010335d:	b8 00 00 00 00       	mov    $0x0,%eax
80103362:	e9 f3 00 00 00       	jmp    8010345a <kbdgetc+0x151>
  } else if(data & 0x80){
80103367:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010336a:	25 80 00 00 00       	and    $0x80,%eax
8010336f:	85 c0                	test   %eax,%eax
80103371:	74 45                	je     801033b8 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103373:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103378:	83 e0 40             	and    $0x40,%eax
8010337b:	85 c0                	test   %eax,%eax
8010337d:	75 08                	jne    80103387 <kbdgetc+0x7e>
8010337f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103382:	83 e0 7f             	and    $0x7f,%eax
80103385:	eb 03                	jmp    8010338a <kbdgetc+0x81>
80103387:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010338a:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
8010338d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103390:	05 20 b0 10 80       	add    $0x8010b020,%eax
80103395:	0f b6 00             	movzbl (%eax),%eax
80103398:	83 c8 40             	or     $0x40,%eax
8010339b:	0f b6 c0             	movzbl %al,%eax
8010339e:	f7 d0                	not    %eax
801033a0:	89 c2                	mov    %eax,%edx
801033a2:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033a7:	21 d0                	and    %edx,%eax
801033a9:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
801033ae:	b8 00 00 00 00       	mov    $0x0,%eax
801033b3:	e9 a2 00 00 00       	jmp    8010345a <kbdgetc+0x151>
  } else if(shift & E0ESC){
801033b8:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033bd:	83 e0 40             	and    $0x40,%eax
801033c0:	85 c0                	test   %eax,%eax
801033c2:	74 14                	je     801033d8 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801033c4:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801033cb:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033d0:	83 e0 bf             	and    $0xffffffbf,%eax
801033d3:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
801033d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033db:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033e0:	0f b6 00             	movzbl (%eax),%eax
801033e3:	0f b6 d0             	movzbl %al,%edx
801033e6:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033eb:	09 d0                	or     %edx,%eax
801033ed:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f5:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033fa:	0f b6 00             	movzbl (%eax),%eax
801033fd:	0f b6 d0             	movzbl %al,%edx
80103400:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103405:	31 d0                	xor    %edx,%eax
80103407:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
8010340c:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103411:	83 e0 03             	and    $0x3,%eax
80103414:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
8010341b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010341e:	01 d0                	add    %edx,%eax
80103420:	0f b6 00             	movzbl (%eax),%eax
80103423:	0f b6 c0             	movzbl %al,%eax
80103426:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103429:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010342e:	83 e0 08             	and    $0x8,%eax
80103431:	85 c0                	test   %eax,%eax
80103433:	74 22                	je     80103457 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80103435:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103439:	76 0c                	jbe    80103447 <kbdgetc+0x13e>
8010343b:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
8010343f:	77 06                	ja     80103447 <kbdgetc+0x13e>
      c += 'A' - 'a';
80103441:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103445:	eb 10                	jmp    80103457 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80103447:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010344b:	76 0a                	jbe    80103457 <kbdgetc+0x14e>
8010344d:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103451:	77 04                	ja     80103457 <kbdgetc+0x14e>
      c += 'a' - 'A';
80103453:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103457:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010345a:	c9                   	leave  
8010345b:	c3                   	ret    

8010345c <kbdintr>:

void
kbdintr(void)
{
8010345c:	55                   	push   %ebp
8010345d:	89 e5                	mov    %esp,%ebp
8010345f:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103462:	c7 04 24 09 33 10 80 	movl   $0x80103309,(%esp)
80103469:	e8 5a d3 ff ff       	call   801007c8 <consoleintr>
}
8010346e:	c9                   	leave  
8010346f:	c3                   	ret    

80103470 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103470:	55                   	push   %ebp
80103471:	89 e5                	mov    %esp,%ebp
80103473:	83 ec 14             	sub    $0x14,%esp
80103476:	8b 45 08             	mov    0x8(%ebp),%eax
80103479:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010347d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103481:	89 c2                	mov    %eax,%edx
80103483:	ec                   	in     (%dx),%al
80103484:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103487:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010348b:	c9                   	leave  
8010348c:	c3                   	ret    

8010348d <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010348d:	55                   	push   %ebp
8010348e:	89 e5                	mov    %esp,%ebp
80103490:	83 ec 08             	sub    $0x8,%esp
80103493:	8b 55 08             	mov    0x8(%ebp),%edx
80103496:	8b 45 0c             	mov    0xc(%ebp),%eax
80103499:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010349d:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801034a0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801034a4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801034a8:	ee                   	out    %al,(%dx)
}
801034a9:	c9                   	leave  
801034aa:	c3                   	ret    

801034ab <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801034ab:	55                   	push   %ebp
801034ac:	89 e5                	mov    %esp,%ebp
801034ae:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034b1:	9c                   	pushf  
801034b2:	58                   	pop    %eax
801034b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801034b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801034b9:	c9                   	leave  
801034ba:	c3                   	ret    

801034bb <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801034bb:	55                   	push   %ebp
801034bc:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801034be:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034c3:	8b 55 08             	mov    0x8(%ebp),%edx
801034c6:	c1 e2 02             	shl    $0x2,%edx
801034c9:	01 c2                	add    %eax,%edx
801034cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801034ce:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801034d0:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034d5:	83 c0 20             	add    $0x20,%eax
801034d8:	8b 00                	mov    (%eax),%eax
}
801034da:	5d                   	pop    %ebp
801034db:	c3                   	ret    

801034dc <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034dc:	55                   	push   %ebp
801034dd:	89 e5                	mov    %esp,%ebp
801034df:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034e2:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034e7:	85 c0                	test   %eax,%eax
801034e9:	75 05                	jne    801034f0 <lapicinit+0x14>
    return;
801034eb:	e9 43 01 00 00       	jmp    80103633 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034f0:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034f7:	00 
801034f8:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034ff:	e8 b7 ff ff ff       	call   801034bb <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103504:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
8010350b:	00 
8010350c:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103513:	e8 a3 ff ff ff       	call   801034bb <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103518:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
8010351f:	00 
80103520:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103527:	e8 8f ff ff ff       	call   801034bb <lapicw>
  lapicw(TICR, 10000000); 
8010352c:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103533:	00 
80103534:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010353b:	e8 7b ff ff ff       	call   801034bb <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103540:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103547:	00 
80103548:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010354f:	e8 67 ff ff ff       	call   801034bb <lapicw>
  lapicw(LINT1, MASKED);
80103554:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010355b:	00 
8010355c:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103563:	e8 53 ff ff ff       	call   801034bb <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103568:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010356d:	83 c0 30             	add    $0x30,%eax
80103570:	8b 00                	mov    (%eax),%eax
80103572:	c1 e8 10             	shr    $0x10,%eax
80103575:	0f b6 c0             	movzbl %al,%eax
80103578:	83 f8 03             	cmp    $0x3,%eax
8010357b:	76 14                	jbe    80103591 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
8010357d:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103584:	00 
80103585:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010358c:	e8 2a ff ff ff       	call   801034bb <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103591:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103598:	00 
80103599:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
801035a0:	e8 16 ff ff ff       	call   801034bb <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
801035a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035ac:	00 
801035ad:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801035b4:	e8 02 ff ff ff       	call   801034bb <lapicw>
  lapicw(ESR, 0);
801035b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035c0:	00 
801035c1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801035c8:	e8 ee fe ff ff       	call   801034bb <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801035cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035d4:	00 
801035d5:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035dc:	e8 da fe ff ff       	call   801034bb <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035e8:	00 
801035e9:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035f0:	e8 c6 fe ff ff       	call   801034bb <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035f5:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035fc:	00 
801035fd:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103604:	e8 b2 fe ff ff       	call   801034bb <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103609:	90                   	nop
8010360a:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010360f:	05 00 03 00 00       	add    $0x300,%eax
80103614:	8b 00                	mov    (%eax),%eax
80103616:	25 00 10 00 00       	and    $0x1000,%eax
8010361b:	85 c0                	test   %eax,%eax
8010361d:	75 eb                	jne    8010360a <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
8010361f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103626:	00 
80103627:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010362e:	e8 88 fe ff ff       	call   801034bb <lapicw>
}
80103633:	c9                   	leave  
80103634:	c3                   	ret    

80103635 <cpunum>:

int
cpunum(void)
{
80103635:	55                   	push   %ebp
80103636:	89 e5                	mov    %esp,%ebp
80103638:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010363b:	e8 6b fe ff ff       	call   801034ab <readeflags>
80103640:	25 00 02 00 00       	and    $0x200,%eax
80103645:	85 c0                	test   %eax,%eax
80103647:	74 25                	je     8010366e <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103649:	a1 40 d6 10 80       	mov    0x8010d640,%eax
8010364e:	8d 50 01             	lea    0x1(%eax),%edx
80103651:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
80103657:	85 c0                	test   %eax,%eax
80103659:	75 13                	jne    8010366e <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
8010365b:	8b 45 04             	mov    0x4(%ebp),%eax
8010365e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103662:	c7 04 24 b0 9e 10 80 	movl   $0x80109eb0,(%esp)
80103669:	e8 32 cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010366e:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103673:	85 c0                	test   %eax,%eax
80103675:	74 0f                	je     80103686 <cpunum+0x51>
    return lapic[ID]>>24;
80103677:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010367c:	83 c0 20             	add    $0x20,%eax
8010367f:	8b 00                	mov    (%eax),%eax
80103681:	c1 e8 18             	shr    $0x18,%eax
80103684:	eb 05                	jmp    8010368b <cpunum+0x56>
  return 0;
80103686:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010368b:	c9                   	leave  
8010368c:	c3                   	ret    

8010368d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010368d:	55                   	push   %ebp
8010368e:	89 e5                	mov    %esp,%ebp
80103690:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103693:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103698:	85 c0                	test   %eax,%eax
8010369a:	74 14                	je     801036b0 <lapiceoi+0x23>
    lapicw(EOI, 0);
8010369c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801036a3:	00 
801036a4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801036ab:	e8 0b fe ff ff       	call   801034bb <lapicw>
}
801036b0:	c9                   	leave  
801036b1:	c3                   	ret    

801036b2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801036b2:	55                   	push   %ebp
801036b3:	89 e5                	mov    %esp,%ebp
}
801036b5:	5d                   	pop    %ebp
801036b6:	c3                   	ret    

801036b7 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801036b7:	55                   	push   %ebp
801036b8:	89 e5                	mov    %esp,%ebp
801036ba:	83 ec 1c             	sub    $0x1c,%esp
801036bd:	8b 45 08             	mov    0x8(%ebp),%eax
801036c0:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801036c3:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801036ca:	00 
801036cb:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036d2:	e8 b6 fd ff ff       	call   8010348d <outb>
  outb(CMOS_PORT+1, 0x0A);
801036d7:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036de:	00 
801036df:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036e6:	e8 a2 fd ff ff       	call   8010348d <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036eb:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036f2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036f5:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036fd:	8d 50 02             	lea    0x2(%eax),%edx
80103700:	8b 45 0c             	mov    0xc(%ebp),%eax
80103703:	c1 e8 04             	shr    $0x4,%eax
80103706:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103709:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010370d:	c1 e0 18             	shl    $0x18,%eax
80103710:	89 44 24 04          	mov    %eax,0x4(%esp)
80103714:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010371b:	e8 9b fd ff ff       	call   801034bb <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103720:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103727:	00 
80103728:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010372f:	e8 87 fd ff ff       	call   801034bb <lapicw>
  microdelay(200);
80103734:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010373b:	e8 72 ff ff ff       	call   801036b2 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103740:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103747:	00 
80103748:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010374f:	e8 67 fd ff ff       	call   801034bb <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103754:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010375b:	e8 52 ff ff ff       	call   801036b2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103760:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103767:	eb 40                	jmp    801037a9 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103769:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010376d:	c1 e0 18             	shl    $0x18,%eax
80103770:	89 44 24 04          	mov    %eax,0x4(%esp)
80103774:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010377b:	e8 3b fd ff ff       	call   801034bb <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103780:	8b 45 0c             	mov    0xc(%ebp),%eax
80103783:	c1 e8 0c             	shr    $0xc,%eax
80103786:	80 cc 06             	or     $0x6,%ah
80103789:	89 44 24 04          	mov    %eax,0x4(%esp)
8010378d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103794:	e8 22 fd ff ff       	call   801034bb <lapicw>
    microdelay(200);
80103799:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037a0:	e8 0d ff ff ff       	call   801036b2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801037a5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801037a9:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801037ad:	7e ba                	jle    80103769 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801037af:	c9                   	leave  
801037b0:	c3                   	ret    

801037b1 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801037b1:	55                   	push   %ebp
801037b2:	89 e5                	mov    %esp,%ebp
801037b4:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801037b7:	8b 45 08             	mov    0x8(%ebp),%eax
801037ba:	0f b6 c0             	movzbl %al,%eax
801037bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801037c1:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801037c8:	e8 c0 fc ff ff       	call   8010348d <outb>
  microdelay(200);
801037cd:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037d4:	e8 d9 fe ff ff       	call   801036b2 <microdelay>

  return inb(CMOS_RETURN);
801037d9:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037e0:	e8 8b fc ff ff       	call   80103470 <inb>
801037e5:	0f b6 c0             	movzbl %al,%eax
}
801037e8:	c9                   	leave  
801037e9:	c3                   	ret    

801037ea <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037ea:	55                   	push   %ebp
801037eb:	89 e5                	mov    %esp,%ebp
801037ed:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037f7:	e8 b5 ff ff ff       	call   801037b1 <cmos_read>
801037fc:	8b 55 08             	mov    0x8(%ebp),%edx
801037ff:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103801:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103808:	e8 a4 ff ff ff       	call   801037b1 <cmos_read>
8010380d:	8b 55 08             	mov    0x8(%ebp),%edx
80103810:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103813:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010381a:	e8 92 ff ff ff       	call   801037b1 <cmos_read>
8010381f:	8b 55 08             	mov    0x8(%ebp),%edx
80103822:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103825:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010382c:	e8 80 ff ff ff       	call   801037b1 <cmos_read>
80103831:	8b 55 08             	mov    0x8(%ebp),%edx
80103834:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103837:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010383e:	e8 6e ff ff ff       	call   801037b1 <cmos_read>
80103843:	8b 55 08             	mov    0x8(%ebp),%edx
80103846:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103849:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103850:	e8 5c ff ff ff       	call   801037b1 <cmos_read>
80103855:	8b 55 08             	mov    0x8(%ebp),%edx
80103858:	89 42 14             	mov    %eax,0x14(%edx)
}
8010385b:	c9                   	leave  
8010385c:	c3                   	ret    

8010385d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
8010385d:	55                   	push   %ebp
8010385e:	89 e5                	mov    %esp,%ebp
80103860:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103863:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
8010386a:	e8 42 ff ff ff       	call   801037b1 <cmos_read>
8010386f:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103872:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103875:	83 e0 04             	and    $0x4,%eax
80103878:	85 c0                	test   %eax,%eax
8010387a:	0f 94 c0             	sete   %al
8010387d:	0f b6 c0             	movzbl %al,%eax
80103880:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103883:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103886:	89 04 24             	mov    %eax,(%esp)
80103889:	e8 5c ff ff ff       	call   801037ea <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
8010388e:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103895:	e8 17 ff ff ff       	call   801037b1 <cmos_read>
8010389a:	25 80 00 00 00       	and    $0x80,%eax
8010389f:	85 c0                	test   %eax,%eax
801038a1:	74 02                	je     801038a5 <cmostime+0x48>
        continue;
801038a3:	eb 36                	jmp    801038db <cmostime+0x7e>
    fill_rtcdate(&t2);
801038a5:	8d 45 c0             	lea    -0x40(%ebp),%eax
801038a8:	89 04 24             	mov    %eax,(%esp)
801038ab:	e8 3a ff ff ff       	call   801037ea <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801038b0:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801038b7:	00 
801038b8:	8d 45 c0             	lea    -0x40(%ebp),%eax
801038bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801038bf:	8d 45 d8             	lea    -0x28(%ebp),%eax
801038c2:	89 04 24             	mov    %eax,(%esp)
801038c5:	e8 bf 21 00 00       	call   80105a89 <memcmp>
801038ca:	85 c0                	test   %eax,%eax
801038cc:	75 0d                	jne    801038db <cmostime+0x7e>
      break;
801038ce:	90                   	nop
  }

  // convert
  if (bcd) {
801038cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038d3:	0f 84 ac 00 00 00    	je     80103985 <cmostime+0x128>
801038d9:	eb 02                	jmp    801038dd <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038db:	eb a6                	jmp    80103883 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038dd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038e0:	c1 e8 04             	shr    $0x4,%eax
801038e3:	89 c2                	mov    %eax,%edx
801038e5:	89 d0                	mov    %edx,%eax
801038e7:	c1 e0 02             	shl    $0x2,%eax
801038ea:	01 d0                	add    %edx,%eax
801038ec:	01 c0                	add    %eax,%eax
801038ee:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038f1:	83 e2 0f             	and    $0xf,%edx
801038f4:	01 d0                	add    %edx,%eax
801038f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038fc:	c1 e8 04             	shr    $0x4,%eax
801038ff:	89 c2                	mov    %eax,%edx
80103901:	89 d0                	mov    %edx,%eax
80103903:	c1 e0 02             	shl    $0x2,%eax
80103906:	01 d0                	add    %edx,%eax
80103908:	01 c0                	add    %eax,%eax
8010390a:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010390d:	83 e2 0f             	and    $0xf,%edx
80103910:	01 d0                	add    %edx,%eax
80103912:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103915:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103918:	c1 e8 04             	shr    $0x4,%eax
8010391b:	89 c2                	mov    %eax,%edx
8010391d:	89 d0                	mov    %edx,%eax
8010391f:	c1 e0 02             	shl    $0x2,%eax
80103922:	01 d0                	add    %edx,%eax
80103924:	01 c0                	add    %eax,%eax
80103926:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103929:	83 e2 0f             	and    $0xf,%edx
8010392c:	01 d0                	add    %edx,%eax
8010392e:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103931:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103934:	c1 e8 04             	shr    $0x4,%eax
80103937:	89 c2                	mov    %eax,%edx
80103939:	89 d0                	mov    %edx,%eax
8010393b:	c1 e0 02             	shl    $0x2,%eax
8010393e:	01 d0                	add    %edx,%eax
80103940:	01 c0                	add    %eax,%eax
80103942:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103945:	83 e2 0f             	and    $0xf,%edx
80103948:	01 d0                	add    %edx,%eax
8010394a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
8010394d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103950:	c1 e8 04             	shr    $0x4,%eax
80103953:	89 c2                	mov    %eax,%edx
80103955:	89 d0                	mov    %edx,%eax
80103957:	c1 e0 02             	shl    $0x2,%eax
8010395a:	01 d0                	add    %edx,%eax
8010395c:	01 c0                	add    %eax,%eax
8010395e:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103961:	83 e2 0f             	and    $0xf,%edx
80103964:	01 d0                	add    %edx,%eax
80103966:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103969:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010396c:	c1 e8 04             	shr    $0x4,%eax
8010396f:	89 c2                	mov    %eax,%edx
80103971:	89 d0                	mov    %edx,%eax
80103973:	c1 e0 02             	shl    $0x2,%eax
80103976:	01 d0                	add    %edx,%eax
80103978:	01 c0                	add    %eax,%eax
8010397a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010397d:	83 e2 0f             	and    $0xf,%edx
80103980:	01 d0                	add    %edx,%eax
80103982:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103985:	8b 45 08             	mov    0x8(%ebp),%eax
80103988:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010398b:	89 10                	mov    %edx,(%eax)
8010398d:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103990:	89 50 04             	mov    %edx,0x4(%eax)
80103993:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103996:	89 50 08             	mov    %edx,0x8(%eax)
80103999:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010399c:	89 50 0c             	mov    %edx,0xc(%eax)
8010399f:	8b 55 e8             	mov    -0x18(%ebp),%edx
801039a2:	89 50 10             	mov    %edx,0x10(%eax)
801039a5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801039a8:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801039ab:	8b 45 08             	mov    0x8(%ebp),%eax
801039ae:	8b 40 14             	mov    0x14(%eax),%eax
801039b1:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801039b7:	8b 45 08             	mov    0x8(%ebp),%eax
801039ba:	89 50 14             	mov    %edx,0x14(%eax)
}
801039bd:	c9                   	leave  
801039be:	c3                   	ret    

801039bf <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
801039bf:	55                   	push   %ebp
801039c0:	89 e5                	mov    %esp,%ebp
801039c2:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801039c5:	c7 44 24 04 dc 9e 10 	movl   $0x80109edc,0x4(%esp)
801039cc:	80 
801039cd:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
801039d4:	e8 c4 1d 00 00       	call   8010579d <initlock>
  readsb(dev, &sb);
801039d9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801039e0:	8b 45 08             	mov    0x8(%ebp),%eax
801039e3:	89 04 24             	mov    %eax,(%esp)
801039e6:	e8 06 da ff ff       	call   801013f1 <readsb>
  log.start = sb.logstart;
801039eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039ee:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039f6:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039fb:	8b 45 08             	mov    0x8(%ebp),%eax
801039fe:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
80103a03:	e8 9a 01 00 00       	call   80103ba2 <recover_from_log>
}
80103a08:	c9                   	leave  
80103a09:	c3                   	ret    

80103a0a <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103a0a:	55                   	push   %ebp
80103a0b:	89 e5                	mov    %esp,%ebp
80103a0d:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a17:	e9 8c 00 00 00       	jmp    80103aa8 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103a1c:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a25:	01 d0                	add    %edx,%eax
80103a27:	83 c0 01             	add    $0x1,%eax
80103a2a:	89 c2                	mov    %eax,%edx
80103a2c:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a31:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a35:	89 04 24             	mov    %eax,(%esp)
80103a38:	e8 69 c7 ff ff       	call   801001a6 <bread>
80103a3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a43:	83 c0 10             	add    $0x10,%eax
80103a46:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a4d:	89 c2                	mov    %eax,%edx
80103a4f:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a54:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a58:	89 04 24             	mov    %eax,(%esp)
80103a5b:	e8 46 c7 ff ff       	call   801001a6 <bread>
80103a60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a66:	8d 50 18             	lea    0x18(%eax),%edx
80103a69:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a6c:	83 c0 18             	add    $0x18,%eax
80103a6f:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a76:	00 
80103a77:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a7b:	89 04 24             	mov    %eax,(%esp)
80103a7e:	e8 5e 20 00 00       	call   80105ae1 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a83:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a86:	89 04 24             	mov    %eax,(%esp)
80103a89:	e8 4f c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a91:	89 04 24             	mov    %eax,(%esp)
80103a94:	e8 7e c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a99:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a9c:	89 04 24             	mov    %eax,(%esp)
80103a9f:	e8 73 c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103aa4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103aa8:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103aad:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ab0:	0f 8f 66 ff ff ff    	jg     80103a1c <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103ab6:	c9                   	leave  
80103ab7:	c3                   	ret    

80103ab8 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103ab8:	55                   	push   %ebp
80103ab9:	89 e5                	mov    %esp,%ebp
80103abb:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103abe:	a1 94 42 11 80       	mov    0x80114294,%eax
80103ac3:	89 c2                	mov    %eax,%edx
80103ac5:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103aca:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ace:	89 04 24             	mov    %eax,(%esp)
80103ad1:	e8 d0 c6 ff ff       	call   801001a6 <bread>
80103ad6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103ad9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103adc:	83 c0 18             	add    $0x18,%eax
80103adf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103ae2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ae5:	8b 00                	mov    (%eax),%eax
80103ae7:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103aec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103af3:	eb 1b                	jmp    80103b10 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103af5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103af8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103afb:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103aff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b02:	83 c2 10             	add    $0x10,%edx
80103b05:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103b0c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b10:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b15:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b18:	7f db                	jg     80103af5 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1d:	89 04 24             	mov    %eax,(%esp)
80103b20:	e8 f2 c6 ff ff       	call   80100217 <brelse>
}
80103b25:	c9                   	leave  
80103b26:	c3                   	ret    

80103b27 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103b27:	55                   	push   %ebp
80103b28:	89 e5                	mov    %esp,%ebp
80103b2a:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b2d:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b32:	89 c2                	mov    %eax,%edx
80103b34:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b39:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b3d:	89 04 24             	mov    %eax,(%esp)
80103b40:	e8 61 c6 ff ff       	call   801001a6 <bread>
80103b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b4b:	83 c0 18             	add    $0x18,%eax
80103b4e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b51:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b57:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b5a:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b63:	eb 1b                	jmp    80103b80 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b68:	83 c0 10             	add    $0x10,%eax
80103b6b:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b72:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b75:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b78:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b7c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b80:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b85:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b88:	7f db                	jg     80103b65 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b8d:	89 04 24             	mov    %eax,(%esp)
80103b90:	e8 48 c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b98:	89 04 24             	mov    %eax,(%esp)
80103b9b:	e8 77 c6 ff ff       	call   80100217 <brelse>
}
80103ba0:	c9                   	leave  
80103ba1:	c3                   	ret    

80103ba2 <recover_from_log>:

static void
recover_from_log(void)
{
80103ba2:	55                   	push   %ebp
80103ba3:	89 e5                	mov    %esp,%ebp
80103ba5:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103ba8:	e8 0b ff ff ff       	call   80103ab8 <read_head>
  install_trans(); // if committed, copy from log to disk
80103bad:	e8 58 fe ff ff       	call   80103a0a <install_trans>
  log.lh.n = 0;
80103bb2:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103bb9:	00 00 00 
  write_head(); // clear the log
80103bbc:	e8 66 ff ff ff       	call   80103b27 <write_head>
}
80103bc1:	c9                   	leave  
80103bc2:	c3                   	ret    

80103bc3 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103bc3:	55                   	push   %ebp
80103bc4:	89 e5                	mov    %esp,%ebp
80103bc6:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103bc9:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bd0:	e8 e9 1b 00 00       	call   801057be <acquire>
  while(1){
    if(log.committing){
80103bd5:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103bda:	85 c0                	test   %eax,%eax
80103bdc:	74 16                	je     80103bf4 <begin_op+0x31>
      sleep(&log, &log.lock);
80103bde:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103be5:	80 
80103be6:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bed:	e8 7e 18 00 00       	call   80105470 <sleep>
80103bf2:	eb 4f                	jmp    80103c43 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103bf4:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103bfa:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bff:	8d 50 01             	lea    0x1(%eax),%edx
80103c02:	89 d0                	mov    %edx,%eax
80103c04:	c1 e0 02             	shl    $0x2,%eax
80103c07:	01 d0                	add    %edx,%eax
80103c09:	01 c0                	add    %eax,%eax
80103c0b:	01 c8                	add    %ecx,%eax
80103c0d:	83 f8 1e             	cmp    $0x1e,%eax
80103c10:	7e 16                	jle    80103c28 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103c12:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103c19:	80 
80103c1a:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c21:	e8 4a 18 00 00       	call   80105470 <sleep>
80103c26:	eb 1b                	jmp    80103c43 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103c28:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c2d:	83 c0 01             	add    $0x1,%eax
80103c30:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c35:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c3c:	e8 df 1b 00 00       	call   80105820 <release>
      break;
80103c41:	eb 02                	jmp    80103c45 <begin_op+0x82>
    }
  }
80103c43:	eb 90                	jmp    80103bd5 <begin_op+0x12>
}
80103c45:	c9                   	leave  
80103c46:	c3                   	ret    

80103c47 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c47:	55                   	push   %ebp
80103c48:	89 e5                	mov    %esp,%ebp
80103c4a:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c4d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c54:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c5b:	e8 5e 1b 00 00       	call   801057be <acquire>
  log.outstanding -= 1;
80103c60:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c65:	83 e8 01             	sub    $0x1,%eax
80103c68:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c6d:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c72:	85 c0                	test   %eax,%eax
80103c74:	74 0c                	je     80103c82 <end_op+0x3b>
    panic("log.committing");
80103c76:	c7 04 24 e0 9e 10 80 	movl   $0x80109ee0,(%esp)
80103c7d:	e8 b8 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c82:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c87:	85 c0                	test   %eax,%eax
80103c89:	75 13                	jne    80103c9e <end_op+0x57>
    do_commit = 1;
80103c8b:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c92:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c99:	00 00 00 
80103c9c:	eb 0c                	jmp    80103caa <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c9e:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ca5:	e8 a2 18 00 00       	call   8010554c <wakeup>
  }
  release(&log.lock);
80103caa:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cb1:	e8 6a 1b 00 00       	call   80105820 <release>

  if(do_commit){
80103cb6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cba:	74 33                	je     80103cef <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103cbc:	e8 de 00 00 00       	call   80103d9f <commit>
    acquire(&log.lock);
80103cc1:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cc8:	e8 f1 1a 00 00       	call   801057be <acquire>
    log.committing = 0;
80103ccd:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103cd4:	00 00 00 
    wakeup(&log);
80103cd7:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cde:	e8 69 18 00 00       	call   8010554c <wakeup>
    release(&log.lock);
80103ce3:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cea:	e8 31 1b 00 00       	call   80105820 <release>
  }
}
80103cef:	c9                   	leave  
80103cf0:	c3                   	ret    

80103cf1 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103cf1:	55                   	push   %ebp
80103cf2:	89 e5                	mov    %esp,%ebp
80103cf4:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103cf7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103cfe:	e9 8c 00 00 00       	jmp    80103d8f <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103d03:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103d09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d0c:	01 d0                	add    %edx,%eax
80103d0e:	83 c0 01             	add    $0x1,%eax
80103d11:	89 c2                	mov    %eax,%edx
80103d13:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d18:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d1c:	89 04 24             	mov    %eax,(%esp)
80103d1f:	e8 82 c4 ff ff       	call   801001a6 <bread>
80103d24:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d2a:	83 c0 10             	add    $0x10,%eax
80103d2d:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d34:	89 c2                	mov    %eax,%edx
80103d36:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d3f:	89 04 24             	mov    %eax,(%esp)
80103d42:	e8 5f c4 ff ff       	call   801001a6 <bread>
80103d47:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d4d:	8d 50 18             	lea    0x18(%eax),%edx
80103d50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d53:	83 c0 18             	add    $0x18,%eax
80103d56:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d5d:	00 
80103d5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d62:	89 04 24             	mov    %eax,(%esp)
80103d65:	e8 77 1d 00 00       	call   80105ae1 <memmove>
    bwrite(to);  // write the log
80103d6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d6d:	89 04 24             	mov    %eax,(%esp)
80103d70:	e8 68 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d75:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d78:	89 04 24             	mov    %eax,(%esp)
80103d7b:	e8 97 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d83:	89 04 24             	mov    %eax,(%esp)
80103d86:	e8 8c c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d8b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d8f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d94:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d97:	0f 8f 66 ff ff ff    	jg     80103d03 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d9d:	c9                   	leave  
80103d9e:	c3                   	ret    

80103d9f <commit>:

static void
commit()
{
80103d9f:	55                   	push   %ebp
80103da0:	89 e5                	mov    %esp,%ebp
80103da2:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103da5:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103daa:	85 c0                	test   %eax,%eax
80103dac:	7e 1e                	jle    80103dcc <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103dae:	e8 3e ff ff ff       	call   80103cf1 <write_log>
    write_head();    // Write header to disk -- the real commit
80103db3:	e8 6f fd ff ff       	call   80103b27 <write_head>
    install_trans(); // Now install writes to home locations
80103db8:	e8 4d fc ff ff       	call   80103a0a <install_trans>
    log.lh.n = 0; 
80103dbd:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103dc4:	00 00 00 
    write_head();    // Erase the transaction from the log
80103dc7:	e8 5b fd ff ff       	call   80103b27 <write_head>
  }
}
80103dcc:	c9                   	leave  
80103dcd:	c3                   	ret    

80103dce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103dce:	55                   	push   %ebp
80103dcf:	89 e5                	mov    %esp,%ebp
80103dd1:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103dd4:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dd9:	83 f8 1d             	cmp    $0x1d,%eax
80103ddc:	7f 12                	jg     80103df0 <log_write+0x22>
80103dde:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103de3:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103de9:	83 ea 01             	sub    $0x1,%edx
80103dec:	39 d0                	cmp    %edx,%eax
80103dee:	7c 0c                	jl     80103dfc <log_write+0x2e>
    panic("too big a transaction");
80103df0:	c7 04 24 ef 9e 10 80 	movl   $0x80109eef,(%esp)
80103df7:	e8 3e c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103dfc:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103e01:	85 c0                	test   %eax,%eax
80103e03:	7f 0c                	jg     80103e11 <log_write+0x43>
    panic("log_write outside of trans");
80103e05:	c7 04 24 05 9f 10 80 	movl   $0x80109f05,(%esp)
80103e0c:	e8 29 c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103e11:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e18:	e8 a1 19 00 00       	call   801057be <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103e1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e24:	eb 1f                	jmp    80103e45 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103e26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e29:	83 c0 10             	add    $0x10,%eax
80103e2c:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e33:	89 c2                	mov    %eax,%edx
80103e35:	8b 45 08             	mov    0x8(%ebp),%eax
80103e38:	8b 40 08             	mov    0x8(%eax),%eax
80103e3b:	39 c2                	cmp    %eax,%edx
80103e3d:	75 02                	jne    80103e41 <log_write+0x73>
      break;
80103e3f:	eb 0e                	jmp    80103e4f <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e41:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e45:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e4a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e4d:	7f d7                	jg     80103e26 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e52:	8b 40 08             	mov    0x8(%eax),%eax
80103e55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e58:	83 c2 10             	add    $0x10,%edx
80103e5b:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e62:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e67:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e6a:	75 0d                	jne    80103e79 <log_write+0xab>
    log.lh.n++;
80103e6c:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e71:	83 c0 01             	add    $0x1,%eax
80103e74:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e79:	8b 45 08             	mov    0x8(%ebp),%eax
80103e7c:	8b 00                	mov    (%eax),%eax
80103e7e:	83 c8 04             	or     $0x4,%eax
80103e81:	89 c2                	mov    %eax,%edx
80103e83:	8b 45 08             	mov    0x8(%ebp),%eax
80103e86:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e88:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e8f:	e8 8c 19 00 00       	call   80105820 <release>
}
80103e94:	c9                   	leave  
80103e95:	c3                   	ret    

80103e96 <v2p>:
80103e96:	55                   	push   %ebp
80103e97:	89 e5                	mov    %esp,%ebp
80103e99:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9c:	05 00 00 00 80       	add    $0x80000000,%eax
80103ea1:	5d                   	pop    %ebp
80103ea2:	c3                   	ret    

80103ea3 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103ea3:	55                   	push   %ebp
80103ea4:	89 e5                	mov    %esp,%ebp
80103ea6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea9:	05 00 00 00 80       	add    $0x80000000,%eax
80103eae:	5d                   	pop    %ebp
80103eaf:	c3                   	ret    

80103eb0 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103eb0:	55                   	push   %ebp
80103eb1:	89 e5                	mov    %esp,%ebp
80103eb3:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103eb6:	8b 55 08             	mov    0x8(%ebp),%edx
80103eb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ebc:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ebf:	f0 87 02             	lock xchg %eax,(%edx)
80103ec2:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103ec5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103ec8:	c9                   	leave  
80103ec9:	c3                   	ret    

80103eca <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103eca:	55                   	push   %ebp
80103ecb:	89 e5                	mov    %esp,%ebp
80103ecd:	83 e4 f0             	and    $0xfffffff0,%esp
80103ed0:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103ed3:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103eda:	80 
80103edb:	c7 04 24 5c 0d 12 80 	movl   $0x80120d5c,(%esp)
80103ee2:	e8 ea f1 ff ff       	call   801030d1 <kinit1>
  kvmalloc();      // kernel page table
80103ee7:	e8 98 47 00 00       	call   80108684 <kvmalloc>
  mpinit();        // collect info about this machine
80103eec:	e8 41 04 00 00       	call   80104332 <mpinit>
  lapicinit();
80103ef1:	e8 e6 f5 ff ff       	call   801034dc <lapicinit>
  seginit();       // set up segments
80103ef6:	e8 1c 41 00 00       	call   80108017 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103efb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f01:	0f b6 00             	movzbl (%eax),%eax
80103f04:	0f b6 c0             	movzbl %al,%eax
80103f07:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f0b:	c7 04 24 20 9f 10 80 	movl   $0x80109f20,(%esp)
80103f12:	e8 89 c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103f17:	e8 74 06 00 00       	call   80104590 <picinit>
  ioapicinit();    // another interrupt controller
80103f1c:	e8 a6 f0 ff ff       	call   80102fc7 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103f21:	e8 8a cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103f26:	e8 3b 34 00 00       	call   80107366 <uartinit>
  pinit();         // process table
80103f2b:	e8 6a 0b 00 00       	call   80104a9a <pinit>
  tvinit();        // trap vectors
80103f30:	e8 4b 2f 00 00       	call   80106e80 <tvinit>
  binit();         // buffer cache
80103f35:	e8 fa c0 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f3a:	e8 cb d0 ff ff       	call   8010100a <fileinit>
  ideinit();       // disk
80103f3f:	e8 b5 ec ff ff       	call   80102bf9 <ideinit>
  if(!ismp)
80103f44:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f49:	85 c0                	test   %eax,%eax
80103f4b:	75 05                	jne    80103f52 <main+0x88>
    timerinit();   // uniprocessor timer
80103f4d:	e8 79 2e 00 00       	call   80106dcb <timerinit>
  startothers();   // start other processors
80103f52:	e8 7f 00 00 00       	call   80103fd6 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f57:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f5e:	8e 
80103f5f:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f66:	e8 9e f1 ff ff       	call   80103109 <kinit2>
  userinit();      // first user process
80103f6b:	e8 48 0c 00 00       	call   80104bb8 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f70:	e8 1a 00 00 00       	call   80103f8f <mpmain>

80103f75 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f75:	55                   	push   %ebp
80103f76:	89 e5                	mov    %esp,%ebp
80103f78:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f7b:	e8 1b 47 00 00       	call   8010869b <switchkvm>
  seginit();
80103f80:	e8 92 40 00 00       	call   80108017 <seginit>
  lapicinit();
80103f85:	e8 52 f5 ff ff       	call   801034dc <lapicinit>
  mpmain();
80103f8a:	e8 00 00 00 00       	call   80103f8f <mpmain>

80103f8f <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f8f:	55                   	push   %ebp
80103f90:	89 e5                	mov    %esp,%ebp
80103f92:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f95:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f9b:	0f b6 00             	movzbl (%eax),%eax
80103f9e:	0f b6 c0             	movzbl %al,%eax
80103fa1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fa5:	c7 04 24 37 9f 10 80 	movl   $0x80109f37,(%esp)
80103fac:	e8 ef c3 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103fb1:	e8 3e 30 00 00       	call   80106ff4 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103fb6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103fbc:	05 a8 00 00 00       	add    $0xa8,%eax
80103fc1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103fc8:	00 
80103fc9:	89 04 24             	mov    %eax,(%esp)
80103fcc:	e8 df fe ff ff       	call   80103eb0 <xchg>
  scheduler();     // start running processes
80103fd1:	e8 dc 12 00 00       	call   801052b2 <scheduler>

80103fd6 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fd6:	55                   	push   %ebp
80103fd7:	89 e5                	mov    %esp,%ebp
80103fd9:	53                   	push   %ebx
80103fda:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fdd:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fe4:	e8 ba fe ff ff       	call   80103ea3 <p2v>
80103fe9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fec:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103ff1:	89 44 24 08          	mov    %eax,0x8(%esp)
80103ff5:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103ffc:	80 
80103ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104000:	89 04 24             	mov    %eax,(%esp)
80104003:	e8 d9 1a 00 00       	call   80105ae1 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80104008:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
8010400f:	e9 85 00 00 00       	jmp    80104099 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80104014:	e8 1c f6 ff ff       	call   80103635 <cpunum>
80104019:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010401f:	05 60 43 11 80       	add    $0x80114360,%eax
80104024:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104027:	75 02                	jne    8010402b <startothers+0x55>
      continue;
80104029:	eb 67                	jmp    80104092 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010402b:	e8 29 f2 ff ff       	call   80103259 <kalloc>
80104030:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104033:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104036:	83 e8 04             	sub    $0x4,%eax
80104039:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010403c:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104042:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104044:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104047:	83 e8 08             	sub    $0x8,%eax
8010404a:	c7 00 75 3f 10 80    	movl   $0x80103f75,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104050:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104053:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104056:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
8010405d:	e8 34 fe ff ff       	call   80103e96 <v2p>
80104062:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104064:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104067:	89 04 24             	mov    %eax,(%esp)
8010406a:	e8 27 fe ff ff       	call   80103e96 <v2p>
8010406f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104072:	0f b6 12             	movzbl (%edx),%edx
80104075:	0f b6 d2             	movzbl %dl,%edx
80104078:	89 44 24 04          	mov    %eax,0x4(%esp)
8010407c:	89 14 24             	mov    %edx,(%esp)
8010407f:	e8 33 f6 ff ff       	call   801036b7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104084:	90                   	nop
80104085:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104088:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010408e:	85 c0                	test   %eax,%eax
80104090:	74 f3                	je     80104085 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104092:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104099:	a1 40 49 11 80       	mov    0x80114940,%eax
8010409e:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801040a4:	05 60 43 11 80       	add    $0x80114360,%eax
801040a9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801040ac:	0f 87 62 ff ff ff    	ja     80104014 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801040b2:	83 c4 24             	add    $0x24,%esp
801040b5:	5b                   	pop    %ebx
801040b6:	5d                   	pop    %ebp
801040b7:	c3                   	ret    

801040b8 <p2v>:
801040b8:	55                   	push   %ebp
801040b9:	89 e5                	mov    %esp,%ebp
801040bb:	8b 45 08             	mov    0x8(%ebp),%eax
801040be:	05 00 00 00 80       	add    $0x80000000,%eax
801040c3:	5d                   	pop    %ebp
801040c4:	c3                   	ret    

801040c5 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801040c5:	55                   	push   %ebp
801040c6:	89 e5                	mov    %esp,%ebp
801040c8:	83 ec 14             	sub    $0x14,%esp
801040cb:	8b 45 08             	mov    0x8(%ebp),%eax
801040ce:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040d2:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801040d6:	89 c2                	mov    %eax,%edx
801040d8:	ec                   	in     (%dx),%al
801040d9:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040dc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040e0:	c9                   	leave  
801040e1:	c3                   	ret    

801040e2 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040e2:	55                   	push   %ebp
801040e3:	89 e5                	mov    %esp,%ebp
801040e5:	83 ec 08             	sub    $0x8,%esp
801040e8:	8b 55 08             	mov    0x8(%ebp),%edx
801040eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801040ee:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040f2:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040f5:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040f9:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040fd:	ee                   	out    %al,(%dx)
}
801040fe:	c9                   	leave  
801040ff:	c3                   	ret    

80104100 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104100:	55                   	push   %ebp
80104101:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104103:	a1 44 d6 10 80       	mov    0x8010d644,%eax
80104108:	89 c2                	mov    %eax,%edx
8010410a:	b8 60 43 11 80       	mov    $0x80114360,%eax
8010410f:	29 c2                	sub    %eax,%edx
80104111:	89 d0                	mov    %edx,%eax
80104113:	c1 f8 02             	sar    $0x2,%eax
80104116:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010411c:	5d                   	pop    %ebp
8010411d:	c3                   	ret    

8010411e <sum>:

static uchar
sum(uchar *addr, int len)
{
8010411e:	55                   	push   %ebp
8010411f:	89 e5                	mov    %esp,%ebp
80104121:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104124:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010412b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104132:	eb 15                	jmp    80104149 <sum+0x2b>
    sum += addr[i];
80104134:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104137:	8b 45 08             	mov    0x8(%ebp),%eax
8010413a:	01 d0                	add    %edx,%eax
8010413c:	0f b6 00             	movzbl (%eax),%eax
8010413f:	0f b6 c0             	movzbl %al,%eax
80104142:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104145:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104149:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010414c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010414f:	7c e3                	jl     80104134 <sum+0x16>
    sum += addr[i];
  return sum;
80104151:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104154:	c9                   	leave  
80104155:	c3                   	ret    

80104156 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104156:	55                   	push   %ebp
80104157:	89 e5                	mov    %esp,%ebp
80104159:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
8010415c:	8b 45 08             	mov    0x8(%ebp),%eax
8010415f:	89 04 24             	mov    %eax,(%esp)
80104162:	e8 51 ff ff ff       	call   801040b8 <p2v>
80104167:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010416a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010416d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104170:	01 d0                	add    %edx,%eax
80104172:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104175:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104178:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010417b:	eb 3f                	jmp    801041bc <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010417d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104184:	00 
80104185:	c7 44 24 04 48 9f 10 	movl   $0x80109f48,0x4(%esp)
8010418c:	80 
8010418d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104190:	89 04 24             	mov    %eax,(%esp)
80104193:	e8 f1 18 00 00       	call   80105a89 <memcmp>
80104198:	85 c0                	test   %eax,%eax
8010419a:	75 1c                	jne    801041b8 <mpsearch1+0x62>
8010419c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801041a3:	00 
801041a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a7:	89 04 24             	mov    %eax,(%esp)
801041aa:	e8 6f ff ff ff       	call   8010411e <sum>
801041af:	84 c0                	test   %al,%al
801041b1:	75 05                	jne    801041b8 <mpsearch1+0x62>
      return (struct mp*)p;
801041b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b6:	eb 11                	jmp    801041c9 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801041b8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801041bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bf:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801041c2:	72 b9                	jb     8010417d <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801041c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041c9:	c9                   	leave  
801041ca:	c3                   	ret    

801041cb <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801041cb:	55                   	push   %ebp
801041cc:	89 e5                	mov    %esp,%ebp
801041ce:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041d1:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041db:	83 c0 0f             	add    $0xf,%eax
801041de:	0f b6 00             	movzbl (%eax),%eax
801041e1:	0f b6 c0             	movzbl %al,%eax
801041e4:	c1 e0 08             	shl    $0x8,%eax
801041e7:	89 c2                	mov    %eax,%edx
801041e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ec:	83 c0 0e             	add    $0xe,%eax
801041ef:	0f b6 00             	movzbl (%eax),%eax
801041f2:	0f b6 c0             	movzbl %al,%eax
801041f5:	09 d0                	or     %edx,%eax
801041f7:	c1 e0 04             	shl    $0x4,%eax
801041fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041fd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104201:	74 21                	je     80104224 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104203:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010420a:	00 
8010420b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010420e:	89 04 24             	mov    %eax,(%esp)
80104211:	e8 40 ff ff ff       	call   80104156 <mpsearch1>
80104216:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104219:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010421d:	74 50                	je     8010426f <mpsearch+0xa4>
      return mp;
8010421f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104222:	eb 5f                	jmp    80104283 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104227:	83 c0 14             	add    $0x14,%eax
8010422a:	0f b6 00             	movzbl (%eax),%eax
8010422d:	0f b6 c0             	movzbl %al,%eax
80104230:	c1 e0 08             	shl    $0x8,%eax
80104233:	89 c2                	mov    %eax,%edx
80104235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104238:	83 c0 13             	add    $0x13,%eax
8010423b:	0f b6 00             	movzbl (%eax),%eax
8010423e:	0f b6 c0             	movzbl %al,%eax
80104241:	09 d0                	or     %edx,%eax
80104243:	c1 e0 0a             	shl    $0xa,%eax
80104246:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104249:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010424c:	2d 00 04 00 00       	sub    $0x400,%eax
80104251:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104258:	00 
80104259:	89 04 24             	mov    %eax,(%esp)
8010425c:	e8 f5 fe ff ff       	call   80104156 <mpsearch1>
80104261:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104264:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104268:	74 05                	je     8010426f <mpsearch+0xa4>
      return mp;
8010426a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010426d:	eb 14                	jmp    80104283 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010426f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104276:	00 
80104277:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
8010427e:	e8 d3 fe ff ff       	call   80104156 <mpsearch1>
}
80104283:	c9                   	leave  
80104284:	c3                   	ret    

80104285 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104285:	55                   	push   %ebp
80104286:	89 e5                	mov    %esp,%ebp
80104288:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010428b:	e8 3b ff ff ff       	call   801041cb <mpsearch>
80104290:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104293:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104297:	74 0a                	je     801042a3 <mpconfig+0x1e>
80104299:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429c:	8b 40 04             	mov    0x4(%eax),%eax
8010429f:	85 c0                	test   %eax,%eax
801042a1:	75 0a                	jne    801042ad <mpconfig+0x28>
    return 0;
801042a3:	b8 00 00 00 00       	mov    $0x0,%eax
801042a8:	e9 83 00 00 00       	jmp    80104330 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801042ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b0:	8b 40 04             	mov    0x4(%eax),%eax
801042b3:	89 04 24             	mov    %eax,(%esp)
801042b6:	e8 fd fd ff ff       	call   801040b8 <p2v>
801042bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801042be:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801042c5:	00 
801042c6:	c7 44 24 04 4d 9f 10 	movl   $0x80109f4d,0x4(%esp)
801042cd:	80 
801042ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d1:	89 04 24             	mov    %eax,(%esp)
801042d4:	e8 b0 17 00 00       	call   80105a89 <memcmp>
801042d9:	85 c0                	test   %eax,%eax
801042db:	74 07                	je     801042e4 <mpconfig+0x5f>
    return 0;
801042dd:	b8 00 00 00 00       	mov    $0x0,%eax
801042e2:	eb 4c                	jmp    80104330 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042e7:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042eb:	3c 01                	cmp    $0x1,%al
801042ed:	74 12                	je     80104301 <mpconfig+0x7c>
801042ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042f2:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042f6:	3c 04                	cmp    $0x4,%al
801042f8:	74 07                	je     80104301 <mpconfig+0x7c>
    return 0;
801042fa:	b8 00 00 00 00       	mov    $0x0,%eax
801042ff:	eb 2f                	jmp    80104330 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104301:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104304:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104308:	0f b7 c0             	movzwl %ax,%eax
8010430b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010430f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104312:	89 04 24             	mov    %eax,(%esp)
80104315:	e8 04 fe ff ff       	call   8010411e <sum>
8010431a:	84 c0                	test   %al,%al
8010431c:	74 07                	je     80104325 <mpconfig+0xa0>
    return 0;
8010431e:	b8 00 00 00 00       	mov    $0x0,%eax
80104323:	eb 0b                	jmp    80104330 <mpconfig+0xab>
  *pmp = mp;
80104325:	8b 45 08             	mov    0x8(%ebp),%eax
80104328:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010432b:	89 10                	mov    %edx,(%eax)
  return conf;
8010432d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104330:	c9                   	leave  
80104331:	c3                   	ret    

80104332 <mpinit>:

void
mpinit(void)
{
80104332:	55                   	push   %ebp
80104333:	89 e5                	mov    %esp,%ebp
80104335:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104338:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
8010433f:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104342:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104345:	89 04 24             	mov    %eax,(%esp)
80104348:	e8 38 ff ff ff       	call   80104285 <mpconfig>
8010434d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104350:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104354:	75 05                	jne    8010435b <mpinit+0x29>
    return;
80104356:	e9 9c 01 00 00       	jmp    801044f7 <mpinit+0x1c5>
  ismp = 1;
8010435b:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
80104362:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104365:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104368:	8b 40 24             	mov    0x24(%eax),%eax
8010436b:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104370:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104373:	83 c0 2c             	add    $0x2c,%eax
80104376:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104379:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010437c:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104380:	0f b7 d0             	movzwl %ax,%edx
80104383:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104386:	01 d0                	add    %edx,%eax
80104388:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010438b:	e9 f4 00 00 00       	jmp    80104484 <mpinit+0x152>
    switch(*p){
80104390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104393:	0f b6 00             	movzbl (%eax),%eax
80104396:	0f b6 c0             	movzbl %al,%eax
80104399:	83 f8 04             	cmp    $0x4,%eax
8010439c:	0f 87 bf 00 00 00    	ja     80104461 <mpinit+0x12f>
801043a2:	8b 04 85 90 9f 10 80 	mov    -0x7fef6070(,%eax,4),%eax
801043a9:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801043ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ae:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801043b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043b4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043b8:	0f b6 d0             	movzbl %al,%edx
801043bb:	a1 40 49 11 80       	mov    0x80114940,%eax
801043c0:	39 c2                	cmp    %eax,%edx
801043c2:	74 2d                	je     801043f1 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801043c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043c7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043cb:	0f b6 d0             	movzbl %al,%edx
801043ce:	a1 40 49 11 80       	mov    0x80114940,%eax
801043d3:	89 54 24 08          	mov    %edx,0x8(%esp)
801043d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801043db:	c7 04 24 52 9f 10 80 	movl   $0x80109f52,(%esp)
801043e2:	e8 b9 bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043e7:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043ee:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043f4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043f8:	0f b6 c0             	movzbl %al,%eax
801043fb:	83 e0 02             	and    $0x2,%eax
801043fe:	85 c0                	test   %eax,%eax
80104400:	74 15                	je     80104417 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80104402:	a1 40 49 11 80       	mov    0x80114940,%eax
80104407:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010440d:	05 60 43 11 80       	add    $0x80114360,%eax
80104412:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
80104417:	8b 15 40 49 11 80    	mov    0x80114940,%edx
8010441d:	a1 40 49 11 80       	mov    0x80114940,%eax
80104422:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104428:	81 c2 60 43 11 80    	add    $0x80114360,%edx
8010442e:	88 02                	mov    %al,(%edx)
      ncpu++;
80104430:	a1 40 49 11 80       	mov    0x80114940,%eax
80104435:	83 c0 01             	add    $0x1,%eax
80104438:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
8010443d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104441:	eb 41                	jmp    80104484 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104446:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104449:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010444c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104450:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
80104455:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104459:	eb 29                	jmp    80104484 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010445b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010445f:	eb 23                	jmp    80104484 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104461:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104464:	0f b6 00             	movzbl (%eax),%eax
80104467:	0f b6 c0             	movzbl %al,%eax
8010446a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010446e:	c7 04 24 70 9f 10 80 	movl   $0x80109f70,(%esp)
80104475:	e8 26 bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
8010447a:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104481:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104484:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104487:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010448a:	0f 82 00 ff ff ff    	jb     80104390 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104490:	a1 44 43 11 80       	mov    0x80114344,%eax
80104495:	85 c0                	test   %eax,%eax
80104497:	75 1d                	jne    801044b6 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104499:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
801044a0:	00 00 00 
    lapic = 0;
801044a3:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
801044aa:	00 00 00 
    ioapicid = 0;
801044ad:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
801044b4:	eb 41                	jmp    801044f7 <mpinit+0x1c5>
  }

  if(mp->imcrp){
801044b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044b9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801044bd:	84 c0                	test   %al,%al
801044bf:	74 36                	je     801044f7 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801044c1:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801044c8:	00 
801044c9:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801044d0:	e8 0d fc ff ff       	call   801040e2 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044d5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044dc:	e8 e4 fb ff ff       	call   801040c5 <inb>
801044e1:	83 c8 01             	or     $0x1,%eax
801044e4:	0f b6 c0             	movzbl %al,%eax
801044e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801044eb:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044f2:	e8 eb fb ff ff       	call   801040e2 <outb>
  }
}
801044f7:	c9                   	leave  
801044f8:	c3                   	ret    

801044f9 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044f9:	55                   	push   %ebp
801044fa:	89 e5                	mov    %esp,%ebp
801044fc:	83 ec 08             	sub    $0x8,%esp
801044ff:	8b 55 08             	mov    0x8(%ebp),%edx
80104502:	8b 45 0c             	mov    0xc(%ebp),%eax
80104505:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104509:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010450c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104510:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104514:	ee                   	out    %al,(%dx)
}
80104515:	c9                   	leave  
80104516:	c3                   	ret    

80104517 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104517:	55                   	push   %ebp
80104518:	89 e5                	mov    %esp,%ebp
8010451a:	83 ec 0c             	sub    $0xc,%esp
8010451d:	8b 45 08             	mov    0x8(%ebp),%eax
80104520:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104524:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104528:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
8010452e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104532:	0f b6 c0             	movzbl %al,%eax
80104535:	89 44 24 04          	mov    %eax,0x4(%esp)
80104539:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104540:	e8 b4 ff ff ff       	call   801044f9 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104545:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104549:	66 c1 e8 08          	shr    $0x8,%ax
8010454d:	0f b6 c0             	movzbl %al,%eax
80104550:	89 44 24 04          	mov    %eax,0x4(%esp)
80104554:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010455b:	e8 99 ff ff ff       	call   801044f9 <outb>
}
80104560:	c9                   	leave  
80104561:	c3                   	ret    

80104562 <picenable>:

void
picenable(int irq)
{
80104562:	55                   	push   %ebp
80104563:	89 e5                	mov    %esp,%ebp
80104565:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104568:	8b 45 08             	mov    0x8(%ebp),%eax
8010456b:	ba 01 00 00 00       	mov    $0x1,%edx
80104570:	89 c1                	mov    %eax,%ecx
80104572:	d3 e2                	shl    %cl,%edx
80104574:	89 d0                	mov    %edx,%eax
80104576:	f7 d0                	not    %eax
80104578:	89 c2                	mov    %eax,%edx
8010457a:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104581:	21 d0                	and    %edx,%eax
80104583:	0f b7 c0             	movzwl %ax,%eax
80104586:	89 04 24             	mov    %eax,(%esp)
80104589:	e8 89 ff ff ff       	call   80104517 <picsetmask>
}
8010458e:	c9                   	leave  
8010458f:	c3                   	ret    

80104590 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104590:	55                   	push   %ebp
80104591:	89 e5                	mov    %esp,%ebp
80104593:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104596:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010459d:	00 
8010459e:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045a5:	e8 4f ff ff ff       	call   801044f9 <outb>
  outb(IO_PIC2+1, 0xFF);
801045aa:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801045b1:	00 
801045b2:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045b9:	e8 3b ff ff ff       	call   801044f9 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801045be:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045c5:	00 
801045c6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045cd:	e8 27 ff ff ff       	call   801044f9 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045d2:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045d9:	00 
801045da:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045e1:	e8 13 ff ff ff       	call   801044f9 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045e6:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045ed:	00 
801045ee:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045f5:	e8 ff fe ff ff       	call   801044f9 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045fa:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104601:	00 
80104602:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104609:	e8 eb fe ff ff       	call   801044f9 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
8010460e:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104615:	00 
80104616:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010461d:	e8 d7 fe ff ff       	call   801044f9 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104622:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104629:	00 
8010462a:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104631:	e8 c3 fe ff ff       	call   801044f9 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104636:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010463d:	00 
8010463e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104645:	e8 af fe ff ff       	call   801044f9 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
8010464a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104651:	00 
80104652:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104659:	e8 9b fe ff ff       	call   801044f9 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
8010465e:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104665:	00 
80104666:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010466d:	e8 87 fe ff ff       	call   801044f9 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104672:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104679:	00 
8010467a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104681:	e8 73 fe ff ff       	call   801044f9 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104686:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010468d:	00 
8010468e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104695:	e8 5f fe ff ff       	call   801044f9 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010469a:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801046a1:	00 
801046a2:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801046a9:	e8 4b fe ff ff       	call   801044f9 <outb>

  if(irqmask != 0xFFFF)
801046ae:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801046b5:	66 83 f8 ff          	cmp    $0xffff,%ax
801046b9:	74 12                	je     801046cd <picinit+0x13d>
    picsetmask(irqmask);
801046bb:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801046c2:	0f b7 c0             	movzwl %ax,%eax
801046c5:	89 04 24             	mov    %eax,(%esp)
801046c8:	e8 4a fe ff ff       	call   80104517 <picsetmask>
}
801046cd:	c9                   	leave  
801046ce:	c3                   	ret    

801046cf <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801046cf:	55                   	push   %ebp
801046d0:	89 e5                	mov    %esp,%ebp
801046d2:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801046df:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801046e8:	8b 10                	mov    (%eax),%edx
801046ea:	8b 45 08             	mov    0x8(%ebp),%eax
801046ed:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046ef:	e8 32 c9 ff ff       	call   80101026 <filealloc>
801046f4:	8b 55 08             	mov    0x8(%ebp),%edx
801046f7:	89 02                	mov    %eax,(%edx)
801046f9:	8b 45 08             	mov    0x8(%ebp),%eax
801046fc:	8b 00                	mov    (%eax),%eax
801046fe:	85 c0                	test   %eax,%eax
80104700:	0f 84 c8 00 00 00    	je     801047ce <pipealloc+0xff>
80104706:	e8 1b c9 ff ff       	call   80101026 <filealloc>
8010470b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010470e:	89 02                	mov    %eax,(%edx)
80104710:	8b 45 0c             	mov    0xc(%ebp),%eax
80104713:	8b 00                	mov    (%eax),%eax
80104715:	85 c0                	test   %eax,%eax
80104717:	0f 84 b1 00 00 00    	je     801047ce <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010471d:	e8 37 eb ff ff       	call   80103259 <kalloc>
80104722:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104725:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104729:	75 05                	jne    80104730 <pipealloc+0x61>
    goto bad;
8010472b:	e9 9e 00 00 00       	jmp    801047ce <pipealloc+0xff>
  p->readopen = 1;
80104730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104733:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010473a:	00 00 00 
  p->writeopen = 1;
8010473d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104740:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104747:	00 00 00 
  p->nwrite = 0;
8010474a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104754:	00 00 00 
  p->nread = 0;
80104757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010475a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104761:	00 00 00 
  initlock(&p->lock, "pipe");
80104764:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104767:	c7 44 24 04 a4 9f 10 	movl   $0x80109fa4,0x4(%esp)
8010476e:	80 
8010476f:	89 04 24             	mov    %eax,(%esp)
80104772:	e8 26 10 00 00       	call   8010579d <initlock>
  (*f0)->type = FD_PIPE;
80104777:	8b 45 08             	mov    0x8(%ebp),%eax
8010477a:	8b 00                	mov    (%eax),%eax
8010477c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104782:	8b 45 08             	mov    0x8(%ebp),%eax
80104785:	8b 00                	mov    (%eax),%eax
80104787:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010478b:	8b 45 08             	mov    0x8(%ebp),%eax
8010478e:	8b 00                	mov    (%eax),%eax
80104790:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104794:	8b 45 08             	mov    0x8(%ebp),%eax
80104797:	8b 00                	mov    (%eax),%eax
80104799:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010479c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010479f:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a2:	8b 00                	mov    (%eax),%eax
801047a4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801047aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801047ad:	8b 00                	mov    (%eax),%eax
801047af:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801047b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801047b6:	8b 00                	mov    (%eax),%eax
801047b8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801047bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801047bf:	8b 00                	mov    (%eax),%eax
801047c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047c4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801047c7:	b8 00 00 00 00       	mov    $0x0,%eax
801047cc:	eb 42                	jmp    80104810 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801047ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047d2:	74 0b                	je     801047df <pipealloc+0x110>
    kfree((char*)p);
801047d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d7:	89 04 24             	mov    %eax,(%esp)
801047da:	e8 87 e9 ff ff       	call   80103166 <kfree>
  if(*f0)
801047df:	8b 45 08             	mov    0x8(%ebp),%eax
801047e2:	8b 00                	mov    (%eax),%eax
801047e4:	85 c0                	test   %eax,%eax
801047e6:	74 0d                	je     801047f5 <pipealloc+0x126>
    fileclose(*f0);
801047e8:	8b 45 08             	mov    0x8(%ebp),%eax
801047eb:	8b 00                	mov    (%eax),%eax
801047ed:	89 04 24             	mov    %eax,(%esp)
801047f0:	e8 d9 c8 ff ff       	call   801010ce <fileclose>
  if(*f1)
801047f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801047f8:	8b 00                	mov    (%eax),%eax
801047fa:	85 c0                	test   %eax,%eax
801047fc:	74 0d                	je     8010480b <pipealloc+0x13c>
    fileclose(*f1);
801047fe:	8b 45 0c             	mov    0xc(%ebp),%eax
80104801:	8b 00                	mov    (%eax),%eax
80104803:	89 04 24             	mov    %eax,(%esp)
80104806:	e8 c3 c8 ff ff       	call   801010ce <fileclose>
  return -1;
8010480b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104810:	c9                   	leave  
80104811:	c3                   	ret    

80104812 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104812:	55                   	push   %ebp
80104813:	89 e5                	mov    %esp,%ebp
80104815:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104818:	8b 45 08             	mov    0x8(%ebp),%eax
8010481b:	89 04 24             	mov    %eax,(%esp)
8010481e:	e8 9b 0f 00 00       	call   801057be <acquire>
  if(writable){
80104823:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104827:	74 1f                	je     80104848 <pipeclose+0x36>
    p->writeopen = 0;
80104829:	8b 45 08             	mov    0x8(%ebp),%eax
8010482c:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104833:	00 00 00 
    wakeup(&p->nread);
80104836:	8b 45 08             	mov    0x8(%ebp),%eax
80104839:	05 34 02 00 00       	add    $0x234,%eax
8010483e:	89 04 24             	mov    %eax,(%esp)
80104841:	e8 06 0d 00 00       	call   8010554c <wakeup>
80104846:	eb 1d                	jmp    80104865 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104848:	8b 45 08             	mov    0x8(%ebp),%eax
8010484b:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104852:	00 00 00 
    wakeup(&p->nwrite);
80104855:	8b 45 08             	mov    0x8(%ebp),%eax
80104858:	05 38 02 00 00       	add    $0x238,%eax
8010485d:	89 04 24             	mov    %eax,(%esp)
80104860:	e8 e7 0c 00 00       	call   8010554c <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104865:	8b 45 08             	mov    0x8(%ebp),%eax
80104868:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010486e:	85 c0                	test   %eax,%eax
80104870:	75 25                	jne    80104897 <pipeclose+0x85>
80104872:	8b 45 08             	mov    0x8(%ebp),%eax
80104875:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010487b:	85 c0                	test   %eax,%eax
8010487d:	75 18                	jne    80104897 <pipeclose+0x85>
    release(&p->lock);
8010487f:	8b 45 08             	mov    0x8(%ebp),%eax
80104882:	89 04 24             	mov    %eax,(%esp)
80104885:	e8 96 0f 00 00       	call   80105820 <release>
    kfree((char*)p);
8010488a:	8b 45 08             	mov    0x8(%ebp),%eax
8010488d:	89 04 24             	mov    %eax,(%esp)
80104890:	e8 d1 e8 ff ff       	call   80103166 <kfree>
80104895:	eb 0b                	jmp    801048a2 <pipeclose+0x90>
  } else
    release(&p->lock);
80104897:	8b 45 08             	mov    0x8(%ebp),%eax
8010489a:	89 04 24             	mov    %eax,(%esp)
8010489d:	e8 7e 0f 00 00       	call   80105820 <release>
}
801048a2:	c9                   	leave  
801048a3:	c3                   	ret    

801048a4 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801048a4:	55                   	push   %ebp
801048a5:	89 e5                	mov    %esp,%ebp
801048a7:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
801048aa:	8b 45 08             	mov    0x8(%ebp),%eax
801048ad:	89 04 24             	mov    %eax,(%esp)
801048b0:	e8 09 0f 00 00       	call   801057be <acquire>
  for(i = 0; i < n; i++){
801048b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801048bc:	e9 a6 00 00 00       	jmp    80104967 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048c1:	eb 57                	jmp    8010491a <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801048c3:	8b 45 08             	mov    0x8(%ebp),%eax
801048c6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048cc:	85 c0                	test   %eax,%eax
801048ce:	74 0d                	je     801048dd <pipewrite+0x39>
801048d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d6:	8b 40 24             	mov    0x24(%eax),%eax
801048d9:	85 c0                	test   %eax,%eax
801048db:	74 15                	je     801048f2 <pipewrite+0x4e>
        release(&p->lock);
801048dd:	8b 45 08             	mov    0x8(%ebp),%eax
801048e0:	89 04 24             	mov    %eax,(%esp)
801048e3:	e8 38 0f 00 00       	call   80105820 <release>
        return -1;
801048e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ed:	e9 9f 00 00 00       	jmp    80104991 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048f2:	8b 45 08             	mov    0x8(%ebp),%eax
801048f5:	05 34 02 00 00       	add    $0x234,%eax
801048fa:	89 04 24             	mov    %eax,(%esp)
801048fd:	e8 4a 0c 00 00       	call   8010554c <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104902:	8b 45 08             	mov    0x8(%ebp),%eax
80104905:	8b 55 08             	mov    0x8(%ebp),%edx
80104908:	81 c2 38 02 00 00    	add    $0x238,%edx
8010490e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104912:	89 14 24             	mov    %edx,(%esp)
80104915:	e8 56 0b 00 00       	call   80105470 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010491a:	8b 45 08             	mov    0x8(%ebp),%eax
8010491d:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104923:	8b 45 08             	mov    0x8(%ebp),%eax
80104926:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010492c:	05 00 02 00 00       	add    $0x200,%eax
80104931:	39 c2                	cmp    %eax,%edx
80104933:	74 8e                	je     801048c3 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104935:	8b 45 08             	mov    0x8(%ebp),%eax
80104938:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010493e:	8d 48 01             	lea    0x1(%eax),%ecx
80104941:	8b 55 08             	mov    0x8(%ebp),%edx
80104944:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010494a:	25 ff 01 00 00       	and    $0x1ff,%eax
8010494f:	89 c1                	mov    %eax,%ecx
80104951:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104954:	8b 45 0c             	mov    0xc(%ebp),%eax
80104957:	01 d0                	add    %edx,%eax
80104959:	0f b6 10             	movzbl (%eax),%edx
8010495c:	8b 45 08             	mov    0x8(%ebp),%eax
8010495f:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104963:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010496a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010496d:	0f 8c 4e ff ff ff    	jl     801048c1 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104973:	8b 45 08             	mov    0x8(%ebp),%eax
80104976:	05 34 02 00 00       	add    $0x234,%eax
8010497b:	89 04 24             	mov    %eax,(%esp)
8010497e:	e8 c9 0b 00 00       	call   8010554c <wakeup>
  release(&p->lock);
80104983:	8b 45 08             	mov    0x8(%ebp),%eax
80104986:	89 04 24             	mov    %eax,(%esp)
80104989:	e8 92 0e 00 00       	call   80105820 <release>
  return n;
8010498e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104991:	c9                   	leave  
80104992:	c3                   	ret    

80104993 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104993:	55                   	push   %ebp
80104994:	89 e5                	mov    %esp,%ebp
80104996:	53                   	push   %ebx
80104997:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010499a:	8b 45 08             	mov    0x8(%ebp),%eax
8010499d:	89 04 24             	mov    %eax,(%esp)
801049a0:	e8 19 0e 00 00       	call   801057be <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049a5:	eb 3a                	jmp    801049e1 <piperead+0x4e>
    if(proc->killed){
801049a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ad:	8b 40 24             	mov    0x24(%eax),%eax
801049b0:	85 c0                	test   %eax,%eax
801049b2:	74 15                	je     801049c9 <piperead+0x36>
      release(&p->lock);
801049b4:	8b 45 08             	mov    0x8(%ebp),%eax
801049b7:	89 04 24             	mov    %eax,(%esp)
801049ba:	e8 61 0e 00 00       	call   80105820 <release>
      return -1;
801049bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049c4:	e9 b5 00 00 00       	jmp    80104a7e <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801049c9:	8b 45 08             	mov    0x8(%ebp),%eax
801049cc:	8b 55 08             	mov    0x8(%ebp),%edx
801049cf:	81 c2 34 02 00 00    	add    $0x234,%edx
801049d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801049d9:	89 14 24             	mov    %edx,(%esp)
801049dc:	e8 8f 0a 00 00       	call   80105470 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049e1:	8b 45 08             	mov    0x8(%ebp),%eax
801049e4:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049ea:	8b 45 08             	mov    0x8(%ebp),%eax
801049ed:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049f3:	39 c2                	cmp    %eax,%edx
801049f5:	75 0d                	jne    80104a04 <piperead+0x71>
801049f7:	8b 45 08             	mov    0x8(%ebp),%eax
801049fa:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104a00:	85 c0                	test   %eax,%eax
80104a02:	75 a3                	jne    801049a7 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104a0b:	eb 4b                	jmp    80104a58 <piperead+0xc5>
    if(p->nread == p->nwrite)
80104a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a10:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a16:	8b 45 08             	mov    0x8(%ebp),%eax
80104a19:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a1f:	39 c2                	cmp    %eax,%edx
80104a21:	75 02                	jne    80104a25 <piperead+0x92>
      break;
80104a23:	eb 3b                	jmp    80104a60 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104a25:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a28:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a2b:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104a2e:	8b 45 08             	mov    0x8(%ebp),%eax
80104a31:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a37:	8d 48 01             	lea    0x1(%eax),%ecx
80104a3a:	8b 55 08             	mov    0x8(%ebp),%edx
80104a3d:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a43:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a48:	89 c2                	mov    %eax,%edx
80104a4a:	8b 45 08             	mov    0x8(%ebp),%eax
80104a4d:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a52:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a54:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5b:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a5e:	7c ad                	jl     80104a0d <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a60:	8b 45 08             	mov    0x8(%ebp),%eax
80104a63:	05 38 02 00 00       	add    $0x238,%eax
80104a68:	89 04 24             	mov    %eax,(%esp)
80104a6b:	e8 dc 0a 00 00       	call   8010554c <wakeup>
  release(&p->lock);
80104a70:	8b 45 08             	mov    0x8(%ebp),%eax
80104a73:	89 04 24             	mov    %eax,(%esp)
80104a76:	e8 a5 0d 00 00       	call   80105820 <release>
  return i;
80104a7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a7e:	83 c4 24             	add    $0x24,%esp
80104a81:	5b                   	pop    %ebx
80104a82:	5d                   	pop    %ebp
80104a83:	c3                   	ret    

80104a84 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a84:	55                   	push   %ebp
80104a85:	89 e5                	mov    %esp,%ebp
80104a87:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a8a:	9c                   	pushf  
80104a8b:	58                   	pop    %eax
80104a8c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a8f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a92:	c9                   	leave  
80104a93:	c3                   	ret    

80104a94 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a94:	55                   	push   %ebp
80104a95:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a97:	fb                   	sti    
}
80104a98:	5d                   	pop    %ebp
80104a99:	c3                   	ret    

80104a9a <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a9a:	55                   	push   %ebp
80104a9b:	89 e5                	mov    %esp,%ebp
80104a9d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104aa0:	c7 44 24 04 ac 9f 10 	movl   $0x80109fac,0x4(%esp)
80104aa7:	80 
80104aa8:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104aaf:	e8 e9 0c 00 00       	call   8010579d <initlock>
}
80104ab4:	c9                   	leave  
80104ab5:	c3                   	ret    

80104ab6 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104ab6:	55                   	push   %ebp
80104ab7:	89 e5                	mov    %esp,%ebp
80104ab9:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104abc:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104ac3:	e8 f6 0c 00 00       	call   801057be <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ac8:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104acf:	eb 53                	jmp    80104b24 <allocproc+0x6e>
    if(p->state == UNUSED)
80104ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ad7:	85 c0                	test   %eax,%eax
80104ad9:	75 42                	jne    80104b1d <allocproc+0x67>
      goto found;
80104adb:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104adf:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104ae6:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104aeb:	8d 50 01             	lea    0x1(%eax),%edx
80104aee:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104af4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104af7:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104afa:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b01:	e8 1a 0d 00 00       	call   80105820 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104b06:	e8 4e e7 ff ff       	call   80103259 <kalloc>
80104b0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b0e:	89 42 08             	mov    %eax,0x8(%edx)
80104b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b14:	8b 40 08             	mov    0x8(%eax),%eax
80104b17:	85 c0                	test   %eax,%eax
80104b19:	75 36                	jne    80104b51 <allocproc+0x9b>
80104b1b:	eb 23                	jmp    80104b40 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b1d:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80104b24:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80104b2b:	72 a4                	jb     80104ad1 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104b2d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b34:	e8 e7 0c 00 00       	call   80105820 <release>
    return 0;
80104b39:	b8 00 00 00 00       	mov    $0x0,%eax
80104b3e:	eb 76                	jmp    80104bb6 <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b43:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b4a:	b8 00 00 00 00       	mov    $0x0,%eax
80104b4f:	eb 65                	jmp    80104bb6 <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b54:	8b 40 08             	mov    0x8(%eax),%eax
80104b57:	05 00 10 00 00       	add    $0x1000,%eax
80104b5c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b5f:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b66:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b69:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b6c:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b70:	ba 3b 6e 10 80       	mov    $0x80106e3b,%edx
80104b75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b78:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b7a:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b81:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b84:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b8a:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b8d:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b94:	00 
80104b95:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b9c:	00 
80104b9d:	89 04 24             	mov    %eax,(%esp)
80104ba0:	e8 6d 0e 00 00       	call   80105a12 <memset>
    p->context->eip = (uint)forkret;
80104ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba8:	8b 40 1c             	mov    0x1c(%eax),%eax
80104bab:	ba 31 54 10 80       	mov    $0x80105431,%edx
80104bb0:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104bb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104bb6:	c9                   	leave  
80104bb7:	c3                   	ret    

80104bb8 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104bb8:	55                   	push   %ebp
80104bb9:	89 e5                	mov    %esp,%ebp
80104bbb:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104bbe:	e8 f3 fe ff ff       	call   80104ab6 <allocproc>
80104bc3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104bc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc9:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104bd0:	00 00 00 
    p->swapedPagesCounter = 0;
80104bd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd6:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104bdd:	00 00 00 
    p->pageFaultCounter = 0;
80104be0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be3:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bea:	00 00 00 
    p->swappedOutCounter = 0;
80104bed:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf0:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104bf7:	00 00 00 
    p->numOfPages = 0;
80104bfa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bfd:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104c04:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c0e:	e9 92 00 00 00       	jmp    80104ca5 <userinit+0xed>
   	  p->pagesMetaData[i].count = 0;
80104c13:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c16:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c19:	89 d0                	mov    %edx,%eax
80104c1b:	c1 e0 02             	shl    $0x2,%eax
80104c1e:	01 d0                	add    %edx,%eax
80104c20:	c1 e0 02             	shl    $0x2,%eax
80104c23:	01 c8                	add    %ecx,%eax
80104c25:	05 9c 00 00 00       	add    $0x9c,%eax
80104c2a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104c30:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c33:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c36:	89 d0                	mov    %edx,%eax
80104c38:	c1 e0 02             	shl    $0x2,%eax
80104c3b:	01 d0                	add    %edx,%eax
80104c3d:	c1 e0 02             	shl    $0x2,%eax
80104c40:	01 c8                	add    %ecx,%eax
80104c42:	05 90 00 00 00       	add    $0x90,%eax
80104c47:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c4d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c50:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c53:	89 d0                	mov    %edx,%eax
80104c55:	c1 e0 02             	shl    $0x2,%eax
80104c58:	01 d0                	add    %edx,%eax
80104c5a:	c1 e0 02             	shl    $0x2,%eax
80104c5d:	01 c8                	add    %ecx,%eax
80104c5f:	05 94 00 00 00       	add    $0x94,%eax
80104c64:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c6a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c6d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c70:	89 d0                	mov    %edx,%eax
80104c72:	c1 e0 02             	shl    $0x2,%eax
80104c75:	01 d0                	add    %edx,%eax
80104c77:	c1 e0 02             	shl    $0x2,%eax
80104c7a:	01 c8                	add    %ecx,%eax
80104c7c:	05 98 00 00 00       	add    $0x98,%eax
80104c81:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c87:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c8d:	89 d0                	mov    %edx,%eax
80104c8f:	c1 e0 02             	shl    $0x2,%eax
80104c92:	01 d0                	add    %edx,%eax
80104c94:	c1 e0 02             	shl    $0x2,%eax
80104c97:	01 c8                	add    %ecx,%eax
80104c99:	05 a0 00 00 00       	add    $0xa0,%eax
80104c9e:	c6 00 80             	movb   $0x80,(%eax)
    p->pageFaultCounter = 0;
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104ca1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104ca5:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104ca9:	0f 8e 64 ff ff ff    	jle    80104c13 <userinit+0x5b>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104caf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cb2:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104cb7:	e8 0b 39 00 00       	call   801085c7 <setupkvm>
80104cbc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cbf:	89 42 04             	mov    %eax,0x4(%edx)
80104cc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cc5:	8b 40 04             	mov    0x4(%eax),%eax
80104cc8:	85 c0                	test   %eax,%eax
80104cca:	75 0c                	jne    80104cd8 <userinit+0x120>
      panic("userinit: out of memory?");
80104ccc:	c7 04 24 b3 9f 10 80 	movl   $0x80109fb3,(%esp)
80104cd3:	e8 62 b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104cd8:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104cdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce0:	8b 40 04             	mov    0x4(%eax),%eax
80104ce3:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ce7:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104cee:	80 
80104cef:	89 04 24             	mov    %eax,(%esp)
80104cf2:	e8 28 3b 00 00       	call   8010881f <inituvm>
    p->sz = PGSIZE;
80104cf7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cfa:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104d00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d03:	8b 40 18             	mov    0x18(%eax),%eax
80104d06:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104d0d:	00 
80104d0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d15:	00 
80104d16:	89 04 24             	mov    %eax,(%esp)
80104d19:	e8 f4 0c 00 00       	call   80105a12 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d21:	8b 40 18             	mov    0x18(%eax),%eax
80104d24:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104d2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d2d:	8b 40 18             	mov    0x18(%eax),%eax
80104d30:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104d36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d39:	8b 40 18             	mov    0x18(%eax),%eax
80104d3c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d3f:	8b 52 18             	mov    0x18(%edx),%edx
80104d42:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d46:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d4d:	8b 40 18             	mov    0x18(%eax),%eax
80104d50:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d53:	8b 52 18             	mov    0x18(%edx),%edx
80104d56:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d5a:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d61:	8b 40 18             	mov    0x18(%eax),%eax
80104d64:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6e:	8b 40 18             	mov    0x18(%eax),%eax
80104d71:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d7b:	8b 40 18             	mov    0x18(%eax),%eax
80104d7e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d88:	83 c0 6c             	add    $0x6c,%eax
80104d8b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d92:	00 
80104d93:	c7 44 24 04 cc 9f 10 	movl   $0x80109fcc,0x4(%esp)
80104d9a:	80 
80104d9b:	89 04 24             	mov    %eax,(%esp)
80104d9e:	e8 8f 0e 00 00       	call   80105c32 <safestrcpy>
  p->cwd = namei("/");
80104da3:	c7 04 24 d5 9f 10 80 	movl   $0x80109fd5,(%esp)
80104daa:	e8 bb d7 ff ff       	call   8010256a <namei>
80104daf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104db2:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104db5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104db8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104dbf:	e8 e2 e4 ff ff       	call   801032a6 <countPages>
80104dc4:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104dc9:	a1 60 49 11 80       	mov    0x80114960,%eax
80104dce:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dd2:	c7 04 24 d7 9f 10 80 	movl   $0x80109fd7,(%esp)
80104dd9:	e8 c2 b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104dde:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104de5:	00 00 00 
}
80104de8:	c9                   	leave  
80104de9:	c3                   	ret    

80104dea <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104dea:	55                   	push   %ebp
80104deb:	89 e5                	mov    %esp,%ebp
80104ded:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104df0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104df6:	8b 00                	mov    (%eax),%eax
80104df8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104dfb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104dff:	7e 3f                	jle    80104e40 <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e01:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e08:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e0e:	01 c1                	add    %eax,%ecx
80104e10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e16:	8b 40 04             	mov    0x4(%eax),%eax
80104e19:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e21:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e24:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e28:	89 04 24             	mov    %eax,(%esp)
80104e2b:	e8 65 3b 00 00       	call   80108995 <allocuvm>
80104e30:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e37:	75 4c                	jne    80104e85 <growproc+0x9b>
      return -1;
80104e39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e3e:	eb 63                	jmp    80104ea3 <growproc+0xb9>
  } else if(n < 0){
80104e40:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e44:	79 3f                	jns    80104e85 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e46:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e4d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e53:	01 c1                	add    %eax,%ecx
80104e55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e5b:	8b 40 04             	mov    0x4(%eax),%eax
80104e5e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e62:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e66:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e69:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e6d:	89 04 24             	mov    %eax,(%esp)
80104e70:	e8 59 3d 00 00       	call   80108bce <deallocuvm>
80104e75:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e78:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e7c:	75 07                	jne    80104e85 <growproc+0x9b>
      return -1;
80104e7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e83:	eb 1e                	jmp    80104ea3 <growproc+0xb9>
  }
  proc->sz = sz;
80104e85:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e8b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e8e:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e96:	89 04 24             	mov    %eax,(%esp)
80104e99:	e8 1a 38 00 00       	call   801086b8 <switchuvm>
  return 0;
80104e9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ea3:	c9                   	leave  
80104ea4:	c3                   	ret    

80104ea5 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104ea5:	55                   	push   %ebp
80104ea6:	89 e5                	mov    %esp,%ebp
80104ea8:	57                   	push   %edi
80104ea9:	56                   	push   %esi
80104eaa:	53                   	push   %ebx
80104eab:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104eae:	e8 03 fc ff ff       	call   80104ab6 <allocproc>
80104eb3:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104eb6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104eba:	75 0a                	jne    80104ec6 <fork+0x21>
    return -1;
80104ebc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ec1:	e9 93 01 00 00       	jmp    80105059 <fork+0x1b4>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104ec6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ecc:	8b 10                	mov    (%eax),%edx
80104ece:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed4:	8b 40 04             	mov    0x4(%eax),%eax
80104ed7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104eda:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ede:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ee2:	89 04 24             	mov    %eax,(%esp)
80104ee5:	e8 0d 40 00 00       	call   80108ef7 <copyuvm>
80104eea:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104eed:	89 42 04             	mov    %eax,0x4(%edx)
80104ef0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef3:	8b 40 04             	mov    0x4(%eax),%eax
80104ef6:	85 c0                	test   %eax,%eax
80104ef8:	75 2c                	jne    80104f26 <fork+0x81>
    kfree(np->kstack);
80104efa:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104efd:	8b 40 08             	mov    0x8(%eax),%eax
80104f00:	89 04 24             	mov    %eax,(%esp)
80104f03:	e8 5e e2 ff ff       	call   80103166 <kfree>
    np->kstack = 0;
80104f08:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f0b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104f12:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f15:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104f1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f21:	e9 33 01 00 00       	jmp    80105059 <fork+0x1b4>
  }
  np->sz = proc->sz;
80104f26:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f2c:	8b 10                	mov    (%eax),%edx
80104f2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f31:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f33:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f3d:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f40:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f43:	8b 50 18             	mov    0x18(%eax),%edx
80104f46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f4c:	8b 40 18             	mov    0x18(%eax),%eax
80104f4f:	89 c3                	mov    %eax,%ebx
80104f51:	b8 13 00 00 00       	mov    $0x13,%eax
80104f56:	89 d7                	mov    %edx,%edi
80104f58:	89 de                	mov    %ebx,%esi
80104f5a:	89 c1                	mov    %eax,%ecx
80104f5c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f61:	8b 40 18             	mov    0x18(%eax),%eax
80104f64:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f6b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f72:	eb 3d                	jmp    80104fb1 <fork+0x10c>
    if(proc->ofile[i])
80104f74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f7a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f7d:	83 c2 08             	add    $0x8,%edx
80104f80:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f84:	85 c0                	test   %eax,%eax
80104f86:	74 25                	je     80104fad <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f88:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f8e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f91:	83 c2 08             	add    $0x8,%edx
80104f94:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f98:	89 04 24             	mov    %eax,(%esp)
80104f9b:	e8 e6 c0 ff ff       	call   80101086 <filedup>
80104fa0:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104fa3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104fa6:	83 c1 08             	add    $0x8,%ecx
80104fa9:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104fad:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104fb1:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104fb5:	7e bd                	jle    80104f74 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104fb7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fbd:	8b 40 68             	mov    0x68(%eax),%eax
80104fc0:	89 04 24             	mov    %eax,(%esp)
80104fc3:	e8 bf c9 ff ff       	call   80101987 <idup>
80104fc8:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104fcb:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104fce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fd4:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fd7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fda:	83 c0 6c             	add    $0x6c,%eax
80104fdd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fe4:	00 
80104fe5:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fe9:	89 04 24             	mov    %eax,(%esp)
80104fec:	e8 41 0c 00 00       	call   80105c32 <safestrcpy>

    pid = np->pid;
80104ff1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ff4:	8b 40 10             	mov    0x10(%eax),%eax
80104ff7:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->pageFaultCounter = 0;
80104ffa:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ffd:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80105004:	00 00 00 
    np->swappedOutCounter = 0;
80105007:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010500a:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80105011:	00 00 00 
    createSwapFile(np);
80105014:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105017:	89 04 24             	mov    %eax,(%esp)
8010501a:	e8 5c d8 ff ff       	call   8010287b <createSwapFile>
    copySwapFile(proc,np);
8010501f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105025:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105028:	89 54 24 04          	mov    %edx,0x4(%esp)
8010502c:	89 04 24             	mov    %eax,(%esp)
8010502f:	e8 7c d9 ff ff       	call   801029b0 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
80105034:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010503b:	e8 7e 07 00 00       	call   801057be <acquire>
    np->state = RUNNABLE;
80105040:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105043:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
8010504a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105051:	e8 ca 07 00 00       	call   80105820 <release>

    return pid;
80105056:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
80105059:	83 c4 2c             	add    $0x2c,%esp
8010505c:	5b                   	pop    %ebx
8010505d:	5e                   	pop    %esi
8010505e:	5f                   	pop    %edi
8010505f:	5d                   	pop    %ebp
80105060:	c3                   	ret    

80105061 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105061:	55                   	push   %ebp
80105062:	89 e5                	mov    %esp,%ebp
80105064:	83 ec 28             	sub    $0x28,%esp
    procdump();
80105067:	e8 86 05 00 00       	call   801055f2 <procdump>
    struct proc *p;
    int fd;
    // #ifdef VERBOSE_PRINT
    // procdump();
    // #endif
    if(proc == initproc)
8010506c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105073:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105078:	39 c2                	cmp    %eax,%edx
8010507a:	75 0c                	jne    80105088 <exit+0x27>
      panic("init exiting");
8010507c:	c7 04 24 f5 9f 10 80 	movl   $0x80109ff5,(%esp)
80105083:	e8 b2 b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
80105088:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010508f:	eb 44                	jmp    801050d5 <exit+0x74>
      if(proc->ofile[fd]){
80105091:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105097:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010509a:	83 c2 08             	add    $0x8,%edx
8010509d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050a1:	85 c0                	test   %eax,%eax
801050a3:	74 2c                	je     801050d1 <exit+0x70>
        fileclose(proc->ofile[fd]);
801050a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050ab:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050ae:	83 c2 08             	add    $0x8,%edx
801050b1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050b5:	89 04 24             	mov    %eax,(%esp)
801050b8:	e8 11 c0 ff ff       	call   801010ce <fileclose>
        proc->ofile[fd] = 0;
801050bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050c3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050c6:	83 c2 08             	add    $0x8,%edx
801050c9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801050d0:	00 
    // #endif
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050d1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050d5:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801050d9:	7e b6                	jle    80105091 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
801050db:	e8 e3 ea ff ff       	call   80103bc3 <begin_op>
    iput(proc->cwd);
801050e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e6:	8b 40 68             	mov    0x68(%eax),%eax
801050e9:	89 04 24             	mov    %eax,(%esp)
801050ec:	e8 81 ca ff ff       	call   80101b72 <iput>
    end_op();
801050f1:	e8 51 eb ff ff       	call   80103c47 <end_op>
    proc->cwd = 0;
801050f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050fc:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
80105103:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105109:	89 04 24             	mov    %eax,(%esp)
8010510c:	e8 5e d5 ff ff       	call   8010266f <removeSwapFile>
    acquire(&ptable.lock);
80105111:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105118:	e8 a1 06 00 00       	call   801057be <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
8010511d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105123:	8b 40 14             	mov    0x14(%eax),%eax
80105126:	89 04 24             	mov    %eax,(%esp)
80105129:	e8 dd 03 00 00       	call   8010550b <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010512e:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105135:	eb 3b                	jmp    80105172 <exit+0x111>
      if(p->parent == proc){
80105137:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010513a:	8b 50 14             	mov    0x14(%eax),%edx
8010513d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105143:	39 c2                	cmp    %eax,%edx
80105145:	75 24                	jne    8010516b <exit+0x10a>
        p->parent = initproc;
80105147:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
8010514d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105150:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
80105153:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105156:	8b 40 0c             	mov    0xc(%eax),%eax
80105159:	83 f8 05             	cmp    $0x5,%eax
8010515c:	75 0d                	jne    8010516b <exit+0x10a>
          wakeup1(initproc);
8010515e:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105163:	89 04 24             	mov    %eax,(%esp)
80105166:	e8 a0 03 00 00       	call   8010550b <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010516b:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105172:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105179:	72 bc                	jb     80105137 <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
8010517b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105181:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
80105188:	e8 c0 01 00 00       	call   8010534d <sched>
    panic("zombie exit");
8010518d:	c7 04 24 02 a0 10 80 	movl   $0x8010a002,(%esp)
80105194:	e8 a1 b3 ff ff       	call   8010053a <panic>

80105199 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
80105199:	55                   	push   %ebp
8010519a:	89 e5                	mov    %esp,%ebp
8010519c:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
8010519f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801051a6:	e8 13 06 00 00       	call   801057be <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
801051ab:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051b2:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801051b9:	e9 a4 00 00 00       	jmp    80105262 <wait+0xc9>
        if(p->parent != proc)
801051be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051c1:	8b 50 14             	mov    0x14(%eax),%edx
801051c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051ca:	39 c2                	cmp    %eax,%edx
801051cc:	74 05                	je     801051d3 <wait+0x3a>
          continue;
801051ce:	e9 88 00 00 00       	jmp    8010525b <wait+0xc2>
        havekids = 1;
801051d3:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
801051da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051dd:	8b 40 0c             	mov    0xc(%eax),%eax
801051e0:	83 f8 05             	cmp    $0x5,%eax
801051e3:	75 76                	jne    8010525b <wait+0xc2>
        // Found one.
          pid = p->pid;
801051e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051e8:	8b 40 10             	mov    0x10(%eax),%eax
801051eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801051ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f1:	8b 40 08             	mov    0x8(%eax),%eax
801051f4:	89 04 24             	mov    %eax,(%esp)
801051f7:	e8 6a df ff ff       	call   80103166 <kfree>
          p->kstack = 0;
801051fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ff:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
80105206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105209:	8b 40 04             	mov    0x4(%eax),%eax
8010520c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010520f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105213:	89 04 24             	mov    %eax,(%esp)
80105216:	e8 f2 3b 00 00       	call   80108e0d <freevm>
          p->state = UNUSED;
8010521b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010521e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
80105225:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105228:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
8010522f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105232:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
80105239:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010523c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105243:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
8010524a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105251:	e8 ca 05 00 00       	call   80105820 <release>
          return pid;
80105256:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105259:	eb 55                	jmp    801052b0 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010525b:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105262:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80105269:	0f 82 4f ff ff ff    	jb     801051be <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
8010526f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105273:	74 0d                	je     80105282 <wait+0xe9>
80105275:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010527b:	8b 40 24             	mov    0x24(%eax),%eax
8010527e:	85 c0                	test   %eax,%eax
80105280:	74 13                	je     80105295 <wait+0xfc>
        release(&ptable.lock);
80105282:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105289:	e8 92 05 00 00       	call   80105820 <release>
        return -1;
8010528e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105293:	eb 1b                	jmp    801052b0 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105295:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010529b:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
801052a2:	80 
801052a3:	89 04 24             	mov    %eax,(%esp)
801052a6:	e8 c5 01 00 00       	call   80105470 <sleep>
  }
801052ab:	e9 fb fe ff ff       	jmp    801051ab <wait+0x12>
}
801052b0:	c9                   	leave  
801052b1:	c3                   	ret    

801052b2 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801052b2:	55                   	push   %ebp
801052b3:	89 e5                	mov    %esp,%ebp
801052b5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801052b8:	e8 d7 f7 ff ff       	call   80104a94 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801052bd:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052c4:	e8 f5 04 00 00       	call   801057be <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052c9:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801052d0:	eb 61                	jmp    80105333 <scheduler+0x81>
      if(p->state != RUNNABLE)
801052d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d5:	8b 40 0c             	mov    0xc(%eax),%eax
801052d8:	83 f8 03             	cmp    $0x3,%eax
801052db:	74 02                	je     801052df <scheduler+0x2d>
        continue;
801052dd:	eb 4d                	jmp    8010532c <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e2:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052eb:	89 04 24             	mov    %eax,(%esp)
801052ee:	e8 c5 33 00 00       	call   801086b8 <switchuvm>
      p->state = RUNNING;
801052f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f6:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105303:	8b 40 1c             	mov    0x1c(%eax),%eax
80105306:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010530d:	83 c2 04             	add    $0x4,%edx
80105310:	89 44 24 04          	mov    %eax,0x4(%esp)
80105314:	89 14 24             	mov    %edx,(%esp)
80105317:	e8 87 09 00 00       	call   80105ca3 <swtch>
      switchkvm();
8010531c:	e8 7a 33 00 00       	call   8010869b <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105321:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105328:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010532c:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105333:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
8010533a:	72 96                	jb     801052d2 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010533c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105343:	e8 d8 04 00 00       	call   80105820 <release>

  }
80105348:	e9 6b ff ff ff       	jmp    801052b8 <scheduler+0x6>

8010534d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010534d:	55                   	push   %ebp
8010534e:	89 e5                	mov    %esp,%ebp
80105350:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105353:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010535a:	e8 89 05 00 00       	call   801058e8 <holding>
8010535f:	85 c0                	test   %eax,%eax
80105361:	75 0c                	jne    8010536f <sched+0x22>
    panic("sched ptable.lock");
80105363:	c7 04 24 0e a0 10 80 	movl   $0x8010a00e,(%esp)
8010536a:	e8 cb b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
8010536f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105375:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010537b:	83 f8 01             	cmp    $0x1,%eax
8010537e:	74 0c                	je     8010538c <sched+0x3f>
    panic("sched locks");
80105380:	c7 04 24 20 a0 10 80 	movl   $0x8010a020,(%esp)
80105387:	e8 ae b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
8010538c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105392:	8b 40 0c             	mov    0xc(%eax),%eax
80105395:	83 f8 04             	cmp    $0x4,%eax
80105398:	75 0c                	jne    801053a6 <sched+0x59>
    panic("sched running");
8010539a:	c7 04 24 2c a0 10 80 	movl   $0x8010a02c,(%esp)
801053a1:	e8 94 b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
801053a6:	e8 d9 f6 ff ff       	call   80104a84 <readeflags>
801053ab:	25 00 02 00 00       	and    $0x200,%eax
801053b0:	85 c0                	test   %eax,%eax
801053b2:	74 0c                	je     801053c0 <sched+0x73>
    panic("sched interruptible");
801053b4:	c7 04 24 3a a0 10 80 	movl   $0x8010a03a,(%esp)
801053bb:	e8 7a b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801053c0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053c6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053cf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053d5:	8b 40 04             	mov    0x4(%eax),%eax
801053d8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053df:	83 c2 1c             	add    $0x1c,%edx
801053e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801053e6:	89 14 24             	mov    %edx,(%esp)
801053e9:	e8 b5 08 00 00       	call   80105ca3 <swtch>
  cpu->intena = intena;
801053ee:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053f7:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053fd:	c9                   	leave  
801053fe:	c3                   	ret    

801053ff <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053ff:	55                   	push   %ebp
80105400:	89 e5                	mov    %esp,%ebp
80105402:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105405:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010540c:	e8 ad 03 00 00       	call   801057be <acquire>
  proc->state = RUNNABLE;
80105411:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105417:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010541e:	e8 2a ff ff ff       	call   8010534d <sched>
  release(&ptable.lock);
80105423:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010542a:	e8 f1 03 00 00       	call   80105820 <release>
}
8010542f:	c9                   	leave  
80105430:	c3                   	ret    

80105431 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105431:	55                   	push   %ebp
80105432:	89 e5                	mov    %esp,%ebp
80105434:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105437:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010543e:	e8 dd 03 00 00       	call   80105820 <release>

  if (first) {
80105443:	a1 08 d0 10 80       	mov    0x8010d008,%eax
80105448:	85 c0                	test   %eax,%eax
8010544a:	74 22                	je     8010546e <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010544c:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
80105453:	00 00 00 
    iinit(ROOTDEV);
80105456:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010545d:	e8 2f c2 ff ff       	call   80101691 <iinit>
    initlog(ROOTDEV);
80105462:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105469:	e8 51 e5 ff ff       	call   801039bf <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010546e:	c9                   	leave  
8010546f:	c3                   	ret    

80105470 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105470:	55                   	push   %ebp
80105471:	89 e5                	mov    %esp,%ebp
80105473:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105476:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010547c:	85 c0                	test   %eax,%eax
8010547e:	75 0c                	jne    8010548c <sleep+0x1c>
    panic("sleep");
80105480:	c7 04 24 4e a0 10 80 	movl   $0x8010a04e,(%esp)
80105487:	e8 ae b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
8010548c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105490:	75 0c                	jne    8010549e <sleep+0x2e>
    panic("sleep without lk");
80105492:	c7 04 24 54 a0 10 80 	movl   $0x8010a054,(%esp)
80105499:	e8 9c b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010549e:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054a5:	74 17                	je     801054be <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801054a7:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054ae:	e8 0b 03 00 00       	call   801057be <acquire>
    release(lk);
801054b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801054b6:	89 04 24             	mov    %eax,(%esp)
801054b9:	e8 62 03 00 00       	call   80105820 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801054be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c4:	8b 55 08             	mov    0x8(%ebp),%edx
801054c7:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054d0:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054d7:	e8 71 fe ff ff       	call   8010534d <sched>

  // Tidy up.
  proc->chan = 0;
801054dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054e2:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054e9:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054f0:	74 17                	je     80105509 <sleep+0x99>
    release(&ptable.lock);
801054f2:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054f9:	e8 22 03 00 00       	call   80105820 <release>
    acquire(lk);
801054fe:	8b 45 0c             	mov    0xc(%ebp),%eax
80105501:	89 04 24             	mov    %eax,(%esp)
80105504:	e8 b5 02 00 00       	call   801057be <acquire>
  }
}
80105509:	c9                   	leave  
8010550a:	c3                   	ret    

8010550b <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010550b:	55                   	push   %ebp
8010550c:	89 e5                	mov    %esp,%ebp
8010550e:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105511:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
80105518:	eb 27                	jmp    80105541 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
8010551a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010551d:	8b 40 0c             	mov    0xc(%eax),%eax
80105520:	83 f8 02             	cmp    $0x2,%eax
80105523:	75 15                	jne    8010553a <wakeup1+0x2f>
80105525:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105528:	8b 40 20             	mov    0x20(%eax),%eax
8010552b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010552e:	75 0a                	jne    8010553a <wakeup1+0x2f>
      p->state = RUNNABLE;
80105530:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105533:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010553a:	81 45 fc ec 02 00 00 	addl   $0x2ec,-0x4(%ebp)
80105541:	81 7d fc b4 04 12 80 	cmpl   $0x801204b4,-0x4(%ebp)
80105548:	72 d0                	jb     8010551a <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
8010554a:	c9                   	leave  
8010554b:	c3                   	ret    

8010554c <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
8010554c:	55                   	push   %ebp
8010554d:	89 e5                	mov    %esp,%ebp
8010554f:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
80105552:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105559:	e8 60 02 00 00       	call   801057be <acquire>
    wakeup1(chan);
8010555e:	8b 45 08             	mov    0x8(%ebp),%eax
80105561:	89 04 24             	mov    %eax,(%esp)
80105564:	e8 a2 ff ff ff       	call   8010550b <wakeup1>
    release(&ptable.lock);
80105569:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105570:	e8 ab 02 00 00       	call   80105820 <release>
  }
80105575:	c9                   	leave  
80105576:	c3                   	ret    

80105577 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
80105577:	55                   	push   %ebp
80105578:	89 e5                	mov    %esp,%ebp
8010557a:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
8010557d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105584:	e8 35 02 00 00       	call   801057be <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105589:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105590:	eb 44                	jmp    801055d6 <kill+0x5f>
      if(p->pid == pid){
80105592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105595:	8b 40 10             	mov    0x10(%eax),%eax
80105598:	3b 45 08             	cmp    0x8(%ebp),%eax
8010559b:	75 32                	jne    801055cf <kill+0x58>
        p->killed = 1;
8010559d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a0:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
801055a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055aa:	8b 40 0c             	mov    0xc(%eax),%eax
801055ad:	83 f8 02             	cmp    $0x2,%eax
801055b0:	75 0a                	jne    801055bc <kill+0x45>
          p->state = RUNNABLE;
801055b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055b5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
801055bc:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055c3:	e8 58 02 00 00       	call   80105820 <release>
        return 0;
801055c8:	b8 00 00 00 00       	mov    $0x0,%eax
801055cd:	eb 21                	jmp    801055f0 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055cf:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
801055d6:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
801055dd:	72 b3                	jb     80105592 <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801055df:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055e6:	e8 35 02 00 00       	call   80105820 <release>
    return -1;
801055eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801055f0:	c9                   	leave  
801055f1:	c3                   	ret    

801055f2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801055f2:	55                   	push   %ebp
801055f3:	89 e5                	mov    %esp,%ebp
801055f5:	56                   	push   %esi
801055f6:	53                   	push   %ebx
801055f7:	83 ec 60             	sub    $0x60,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055fa:	c7 45 f0 b4 49 11 80 	movl   $0x801149b4,-0x10(%ebp)
80105601:	e9 24 01 00 00       	jmp    8010572a <procdump+0x138>
      if(p->state == UNUSED)
80105606:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105609:	8b 40 0c             	mov    0xc(%eax),%eax
8010560c:	85 c0                	test   %eax,%eax
8010560e:	75 05                	jne    80105615 <procdump+0x23>
        continue;
80105610:	e9 0e 01 00 00       	jmp    80105723 <procdump+0x131>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105615:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105618:	8b 40 0c             	mov    0xc(%eax),%eax
8010561b:	83 f8 05             	cmp    $0x5,%eax
8010561e:	77 23                	ja     80105643 <procdump+0x51>
80105620:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105623:	8b 40 0c             	mov    0xc(%eax),%eax
80105626:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
8010562d:	85 c0                	test   %eax,%eax
8010562f:	74 12                	je     80105643 <procdump+0x51>
        state = states[p->state];
80105631:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105634:	8b 40 0c             	mov    0xc(%eax),%eax
80105637:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
8010563e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105641:	eb 07                	jmp    8010564a <procdump+0x58>
      else
        state = "???";
80105643:	c7 45 ec 65 a0 10 80 	movl   $0x8010a065,-0x14(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
8010564a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010564d:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
80105653:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105656:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
8010565c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010565f:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80105665:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105668:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
8010566e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105671:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80105677:	01 c6                	add    %eax,%esi
80105679:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010567c:	8b 40 10             	mov    0x10(%eax),%eax
8010567f:	89 5c 24 18          	mov    %ebx,0x18(%esp)
80105683:	89 4c 24 14          	mov    %ecx,0x14(%esp)
80105687:	89 54 24 10          	mov    %edx,0x10(%esp)
8010568b:	89 74 24 0c          	mov    %esi,0xc(%esp)
8010568f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105692:	89 54 24 08          	mov    %edx,0x8(%esp)
80105696:	89 44 24 04          	mov    %eax,0x4(%esp)
8010569a:	c7 04 24 69 a0 10 80 	movl   $0x8010a069,(%esp)
801056a1:	e8 fa ac ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
801056a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a9:	83 c0 6c             	add    $0x6c,%eax
801056ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801056b0:	c7 04 24 7c a0 10 80 	movl   $0x8010a07c,(%esp)
801056b7:	e8 e4 ac ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
801056bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056bf:	8b 40 0c             	mov    0xc(%eax),%eax
801056c2:	83 f8 02             	cmp    $0x2,%eax
801056c5:	75 50                	jne    80105717 <procdump+0x125>
        getcallerpcs((uint*)p->context->ebp+2, pc);
801056c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056ca:	8b 40 1c             	mov    0x1c(%eax),%eax
801056cd:	8b 40 0c             	mov    0xc(%eax),%eax
801056d0:	83 c0 08             	add    $0x8,%eax
801056d3:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801056d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801056da:	89 04 24             	mov    %eax,(%esp)
801056dd:	e8 8d 01 00 00       	call   8010586f <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801056e2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056e9:	eb 1b                	jmp    80105706 <procdump+0x114>
          cprintf(" %p", pc[i]);
801056eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ee:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801056f6:	c7 04 24 7f a0 10 80 	movl   $0x8010a07f,(%esp)
801056fd:	e8 9e ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
80105702:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105706:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
8010570a:	7f 0b                	jg     80105717 <procdump+0x125>
8010570c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010570f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105713:	85 c0                	test   %eax,%eax
80105715:	75 d4                	jne    801056eb <procdump+0xf9>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
80105717:	c7 04 24 83 a0 10 80 	movl   $0x8010a083,(%esp)
8010571e:	e8 7d ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105723:	81 45 f0 ec 02 00 00 	addl   $0x2ec,-0x10(%ebp)
8010572a:	81 7d f0 b4 04 12 80 	cmpl   $0x801204b4,-0x10(%ebp)
80105731:	0f 82 cf fe ff ff    	jb     80105606 <procdump+0x14>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    //float fra = countPages()/numOfInitializedPages; 
    cprintf("%d %d free pages in the system\n",countPages(),numOfInitializedPages);
80105737:	8b 1d 60 49 11 80    	mov    0x80114960,%ebx
8010573d:	e8 64 db ff ff       	call   801032a6 <countPages>
80105742:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80105746:	89 44 24 04          	mov    %eax,0x4(%esp)
8010574a:	c7 04 24 88 a0 10 80 	movl   $0x8010a088,(%esp)
80105751:	e8 4a ac ff ff       	call   801003a0 <cprintf>
  }
80105756:	83 c4 60             	add    $0x60,%esp
80105759:	5b                   	pop    %ebx
8010575a:	5e                   	pop    %esi
8010575b:	5d                   	pop    %ebp
8010575c:	c3                   	ret    

8010575d <getPid>:

int
getPid(){
8010575d:	55                   	push   %ebp
8010575e:	89 e5                	mov    %esp,%ebp
  return afterInit;
80105760:	a1 48 d6 10 80       	mov    0x8010d648,%eax
80105765:	5d                   	pop    %ebp
80105766:	c3                   	ret    

80105767 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105767:	55                   	push   %ebp
80105768:	89 e5                	mov    %esp,%ebp
8010576a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010576d:	9c                   	pushf  
8010576e:	58                   	pop    %eax
8010576f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105772:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105775:	c9                   	leave  
80105776:	c3                   	ret    

80105777 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105777:	55                   	push   %ebp
80105778:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010577a:	fa                   	cli    
}
8010577b:	5d                   	pop    %ebp
8010577c:	c3                   	ret    

8010577d <sti>:

static inline void
sti(void)
{
8010577d:	55                   	push   %ebp
8010577e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105780:	fb                   	sti    
}
80105781:	5d                   	pop    %ebp
80105782:	c3                   	ret    

80105783 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105783:	55                   	push   %ebp
80105784:	89 e5                	mov    %esp,%ebp
80105786:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105789:	8b 55 08             	mov    0x8(%ebp),%edx
8010578c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010578f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105792:	f0 87 02             	lock xchg %eax,(%edx)
80105795:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105798:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010579b:	c9                   	leave  
8010579c:	c3                   	ret    

8010579d <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
8010579d:	55                   	push   %ebp
8010579e:	89 e5                	mov    %esp,%ebp
  lk->name = name;
801057a0:	8b 45 08             	mov    0x8(%ebp),%eax
801057a3:	8b 55 0c             	mov    0xc(%ebp),%edx
801057a6:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
801057a9:	8b 45 08             	mov    0x8(%ebp),%eax
801057ac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801057b2:	8b 45 08             	mov    0x8(%ebp),%eax
801057b5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801057bc:	5d                   	pop    %ebp
801057bd:	c3                   	ret    

801057be <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801057be:	55                   	push   %ebp
801057bf:	89 e5                	mov    %esp,%ebp
801057c1:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801057c4:	e8 49 01 00 00       	call   80105912 <pushcli>
  if(holding(lk))
801057c9:	8b 45 08             	mov    0x8(%ebp),%eax
801057cc:	89 04 24             	mov    %eax,(%esp)
801057cf:	e8 14 01 00 00       	call   801058e8 <holding>
801057d4:	85 c0                	test   %eax,%eax
801057d6:	74 0c                	je     801057e4 <acquire+0x26>
    panic("acquire");
801057d8:	c7 04 24 d2 a0 10 80 	movl   $0x8010a0d2,(%esp)
801057df:	e8 56 ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801057e4:	90                   	nop
801057e5:	8b 45 08             	mov    0x8(%ebp),%eax
801057e8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801057ef:	00 
801057f0:	89 04 24             	mov    %eax,(%esp)
801057f3:	e8 8b ff ff ff       	call   80105783 <xchg>
801057f8:	85 c0                	test   %eax,%eax
801057fa:	75 e9                	jne    801057e5 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801057fc:	8b 45 08             	mov    0x8(%ebp),%eax
801057ff:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105806:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105809:	8b 45 08             	mov    0x8(%ebp),%eax
8010580c:	83 c0 0c             	add    $0xc,%eax
8010580f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105813:	8d 45 08             	lea    0x8(%ebp),%eax
80105816:	89 04 24             	mov    %eax,(%esp)
80105819:	e8 51 00 00 00       	call   8010586f <getcallerpcs>
}
8010581e:	c9                   	leave  
8010581f:	c3                   	ret    

80105820 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105820:	55                   	push   %ebp
80105821:	89 e5                	mov    %esp,%ebp
80105823:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105826:	8b 45 08             	mov    0x8(%ebp),%eax
80105829:	89 04 24             	mov    %eax,(%esp)
8010582c:	e8 b7 00 00 00       	call   801058e8 <holding>
80105831:	85 c0                	test   %eax,%eax
80105833:	75 0c                	jne    80105841 <release+0x21>
    panic("release");
80105835:	c7 04 24 da a0 10 80 	movl   $0x8010a0da,(%esp)
8010583c:	e8 f9 ac ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105841:	8b 45 08             	mov    0x8(%ebp),%eax
80105844:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010584b:	8b 45 08             	mov    0x8(%ebp),%eax
8010584e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105855:	8b 45 08             	mov    0x8(%ebp),%eax
80105858:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010585f:	00 
80105860:	89 04 24             	mov    %eax,(%esp)
80105863:	e8 1b ff ff ff       	call   80105783 <xchg>

  popcli();
80105868:	e8 e9 00 00 00       	call   80105956 <popcli>
}
8010586d:	c9                   	leave  
8010586e:	c3                   	ret    

8010586f <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010586f:	55                   	push   %ebp
80105870:	89 e5                	mov    %esp,%ebp
80105872:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105875:	8b 45 08             	mov    0x8(%ebp),%eax
80105878:	83 e8 08             	sub    $0x8,%eax
8010587b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010587e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105885:	eb 38                	jmp    801058bf <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105887:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
8010588b:	74 38                	je     801058c5 <getcallerpcs+0x56>
8010588d:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105894:	76 2f                	jbe    801058c5 <getcallerpcs+0x56>
80105896:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010589a:	74 29                	je     801058c5 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010589c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010589f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801058a9:	01 c2                	add    %eax,%edx
801058ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058ae:	8b 40 04             	mov    0x4(%eax),%eax
801058b1:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801058b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058b6:	8b 00                	mov    (%eax),%eax
801058b8:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801058bb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058bf:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058c3:	7e c2                	jle    80105887 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058c5:	eb 19                	jmp    801058e0 <getcallerpcs+0x71>
    pcs[i] = 0;
801058c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058ca:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801058d4:	01 d0                	add    %edx,%eax
801058d6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058dc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058e0:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058e4:	7e e1                	jle    801058c7 <getcallerpcs+0x58>
    pcs[i] = 0;
}
801058e6:	c9                   	leave  
801058e7:	c3                   	ret    

801058e8 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801058e8:	55                   	push   %ebp
801058e9:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801058eb:	8b 45 08             	mov    0x8(%ebp),%eax
801058ee:	8b 00                	mov    (%eax),%eax
801058f0:	85 c0                	test   %eax,%eax
801058f2:	74 17                	je     8010590b <holding+0x23>
801058f4:	8b 45 08             	mov    0x8(%ebp),%eax
801058f7:	8b 50 08             	mov    0x8(%eax),%edx
801058fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105900:	39 c2                	cmp    %eax,%edx
80105902:	75 07                	jne    8010590b <holding+0x23>
80105904:	b8 01 00 00 00       	mov    $0x1,%eax
80105909:	eb 05                	jmp    80105910 <holding+0x28>
8010590b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105910:	5d                   	pop    %ebp
80105911:	c3                   	ret    

80105912 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105912:	55                   	push   %ebp
80105913:	89 e5                	mov    %esp,%ebp
80105915:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105918:	e8 4a fe ff ff       	call   80105767 <readeflags>
8010591d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105920:	e8 52 fe ff ff       	call   80105777 <cli>
  if(cpu->ncli++ == 0)
80105925:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010592c:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105932:	8d 48 01             	lea    0x1(%eax),%ecx
80105935:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
8010593b:	85 c0                	test   %eax,%eax
8010593d:	75 15                	jne    80105954 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
8010593f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105945:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105948:	81 e2 00 02 00 00    	and    $0x200,%edx
8010594e:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105954:	c9                   	leave  
80105955:	c3                   	ret    

80105956 <popcli>:

void
popcli(void)
{
80105956:	55                   	push   %ebp
80105957:	89 e5                	mov    %esp,%ebp
80105959:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
8010595c:	e8 06 fe ff ff       	call   80105767 <readeflags>
80105961:	25 00 02 00 00       	and    $0x200,%eax
80105966:	85 c0                	test   %eax,%eax
80105968:	74 0c                	je     80105976 <popcli+0x20>
    panic("popcli - interruptible");
8010596a:	c7 04 24 e2 a0 10 80 	movl   $0x8010a0e2,(%esp)
80105971:	e8 c4 ab ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105976:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010597c:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105982:	83 ea 01             	sub    $0x1,%edx
80105985:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010598b:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105991:	85 c0                	test   %eax,%eax
80105993:	79 0c                	jns    801059a1 <popcli+0x4b>
    panic("popcli");
80105995:	c7 04 24 f9 a0 10 80 	movl   $0x8010a0f9,(%esp)
8010599c:	e8 99 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
801059a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059a7:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059ad:	85 c0                	test   %eax,%eax
801059af:	75 15                	jne    801059c6 <popcli+0x70>
801059b1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059b7:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801059bd:	85 c0                	test   %eax,%eax
801059bf:	74 05                	je     801059c6 <popcli+0x70>
    sti();
801059c1:	e8 b7 fd ff ff       	call   8010577d <sti>
}
801059c6:	c9                   	leave  
801059c7:	c3                   	ret    

801059c8 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801059c8:	55                   	push   %ebp
801059c9:	89 e5                	mov    %esp,%ebp
801059cb:	57                   	push   %edi
801059cc:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801059cd:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059d0:	8b 55 10             	mov    0x10(%ebp),%edx
801059d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801059d6:	89 cb                	mov    %ecx,%ebx
801059d8:	89 df                	mov    %ebx,%edi
801059da:	89 d1                	mov    %edx,%ecx
801059dc:	fc                   	cld    
801059dd:	f3 aa                	rep stos %al,%es:(%edi)
801059df:	89 ca                	mov    %ecx,%edx
801059e1:	89 fb                	mov    %edi,%ebx
801059e3:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059e6:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059e9:	5b                   	pop    %ebx
801059ea:	5f                   	pop    %edi
801059eb:	5d                   	pop    %ebp
801059ec:	c3                   	ret    

801059ed <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801059ed:	55                   	push   %ebp
801059ee:	89 e5                	mov    %esp,%ebp
801059f0:	57                   	push   %edi
801059f1:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801059f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059f5:	8b 55 10             	mov    0x10(%ebp),%edx
801059f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801059fb:	89 cb                	mov    %ecx,%ebx
801059fd:	89 df                	mov    %ebx,%edi
801059ff:	89 d1                	mov    %edx,%ecx
80105a01:	fc                   	cld    
80105a02:	f3 ab                	rep stos %eax,%es:(%edi)
80105a04:	89 ca                	mov    %ecx,%edx
80105a06:	89 fb                	mov    %edi,%ebx
80105a08:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105a0b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105a0e:	5b                   	pop    %ebx
80105a0f:	5f                   	pop    %edi
80105a10:	5d                   	pop    %ebp
80105a11:	c3                   	ret    

80105a12 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105a12:	55                   	push   %ebp
80105a13:	89 e5                	mov    %esp,%ebp
80105a15:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105a18:	8b 45 08             	mov    0x8(%ebp),%eax
80105a1b:	83 e0 03             	and    $0x3,%eax
80105a1e:	85 c0                	test   %eax,%eax
80105a20:	75 49                	jne    80105a6b <memset+0x59>
80105a22:	8b 45 10             	mov    0x10(%ebp),%eax
80105a25:	83 e0 03             	and    $0x3,%eax
80105a28:	85 c0                	test   %eax,%eax
80105a2a:	75 3f                	jne    80105a6b <memset+0x59>
    c &= 0xFF;
80105a2c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105a33:	8b 45 10             	mov    0x10(%ebp),%eax
80105a36:	c1 e8 02             	shr    $0x2,%eax
80105a39:	89 c2                	mov    %eax,%edx
80105a3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a3e:	c1 e0 18             	shl    $0x18,%eax
80105a41:	89 c1                	mov    %eax,%ecx
80105a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a46:	c1 e0 10             	shl    $0x10,%eax
80105a49:	09 c1                	or     %eax,%ecx
80105a4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a4e:	c1 e0 08             	shl    $0x8,%eax
80105a51:	09 c8                	or     %ecx,%eax
80105a53:	0b 45 0c             	or     0xc(%ebp),%eax
80105a56:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105a61:	89 04 24             	mov    %eax,(%esp)
80105a64:	e8 84 ff ff ff       	call   801059ed <stosl>
80105a69:	eb 19                	jmp    80105a84 <memset+0x72>
  } else
    stosb(dst, c, n);
80105a6b:	8b 45 10             	mov    0x10(%ebp),%eax
80105a6e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a72:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a75:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a79:	8b 45 08             	mov    0x8(%ebp),%eax
80105a7c:	89 04 24             	mov    %eax,(%esp)
80105a7f:	e8 44 ff ff ff       	call   801059c8 <stosb>
  return dst;
80105a84:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a87:	c9                   	leave  
80105a88:	c3                   	ret    

80105a89 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a89:	55                   	push   %ebp
80105a8a:	89 e5                	mov    %esp,%ebp
80105a8c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a92:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a95:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a98:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a9b:	eb 30                	jmp    80105acd <memcmp+0x44>
    if(*s1 != *s2)
80105a9d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa0:	0f b6 10             	movzbl (%eax),%edx
80105aa3:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105aa6:	0f b6 00             	movzbl (%eax),%eax
80105aa9:	38 c2                	cmp    %al,%dl
80105aab:	74 18                	je     80105ac5 <memcmp+0x3c>
      return *s1 - *s2;
80105aad:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ab0:	0f b6 00             	movzbl (%eax),%eax
80105ab3:	0f b6 d0             	movzbl %al,%edx
80105ab6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ab9:	0f b6 00             	movzbl (%eax),%eax
80105abc:	0f b6 c0             	movzbl %al,%eax
80105abf:	29 c2                	sub    %eax,%edx
80105ac1:	89 d0                	mov    %edx,%eax
80105ac3:	eb 1a                	jmp    80105adf <memcmp+0x56>
    s1++, s2++;
80105ac5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ac9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105acd:	8b 45 10             	mov    0x10(%ebp),%eax
80105ad0:	8d 50 ff             	lea    -0x1(%eax),%edx
80105ad3:	89 55 10             	mov    %edx,0x10(%ebp)
80105ad6:	85 c0                	test   %eax,%eax
80105ad8:	75 c3                	jne    80105a9d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105ada:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105adf:	c9                   	leave  
80105ae0:	c3                   	ret    

80105ae1 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105ae1:	55                   	push   %ebp
80105ae2:	89 e5                	mov    %esp,%ebp
80105ae4:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105ae7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105aea:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105aed:	8b 45 08             	mov    0x8(%ebp),%eax
80105af0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105af3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105af6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105af9:	73 3d                	jae    80105b38 <memmove+0x57>
80105afb:	8b 45 10             	mov    0x10(%ebp),%eax
80105afe:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b01:	01 d0                	add    %edx,%eax
80105b03:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105b06:	76 30                	jbe    80105b38 <memmove+0x57>
    s += n;
80105b08:	8b 45 10             	mov    0x10(%ebp),%eax
80105b0b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105b0e:	8b 45 10             	mov    0x10(%ebp),%eax
80105b11:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105b14:	eb 13                	jmp    80105b29 <memmove+0x48>
      *--d = *--s;
80105b16:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105b1a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105b1e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b21:	0f b6 10             	movzbl (%eax),%edx
80105b24:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b27:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105b29:	8b 45 10             	mov    0x10(%ebp),%eax
80105b2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b2f:	89 55 10             	mov    %edx,0x10(%ebp)
80105b32:	85 c0                	test   %eax,%eax
80105b34:	75 e0                	jne    80105b16 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105b36:	eb 26                	jmp    80105b5e <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b38:	eb 17                	jmp    80105b51 <memmove+0x70>
      *d++ = *s++;
80105b3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b3d:	8d 50 01             	lea    0x1(%eax),%edx
80105b40:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105b43:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b46:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b49:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105b4c:	0f b6 12             	movzbl (%edx),%edx
80105b4f:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b51:	8b 45 10             	mov    0x10(%ebp),%eax
80105b54:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b57:	89 55 10             	mov    %edx,0x10(%ebp)
80105b5a:	85 c0                	test   %eax,%eax
80105b5c:	75 dc                	jne    80105b3a <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b5e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b61:	c9                   	leave  
80105b62:	c3                   	ret    

80105b63 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b63:	55                   	push   %ebp
80105b64:	89 e5                	mov    %esp,%ebp
80105b66:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b69:	8b 45 10             	mov    0x10(%ebp),%eax
80105b6c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b70:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b73:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b77:	8b 45 08             	mov    0x8(%ebp),%eax
80105b7a:	89 04 24             	mov    %eax,(%esp)
80105b7d:	e8 5f ff ff ff       	call   80105ae1 <memmove>
}
80105b82:	c9                   	leave  
80105b83:	c3                   	ret    

80105b84 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b84:	55                   	push   %ebp
80105b85:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b87:	eb 0c                	jmp    80105b95 <strncmp+0x11>
    n--, p++, q++;
80105b89:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b8d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b91:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b95:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b99:	74 1a                	je     80105bb5 <strncmp+0x31>
80105b9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9e:	0f b6 00             	movzbl (%eax),%eax
80105ba1:	84 c0                	test   %al,%al
80105ba3:	74 10                	je     80105bb5 <strncmp+0x31>
80105ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ba8:	0f b6 10             	movzbl (%eax),%edx
80105bab:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bae:	0f b6 00             	movzbl (%eax),%eax
80105bb1:	38 c2                	cmp    %al,%dl
80105bb3:	74 d4                	je     80105b89 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105bb5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bb9:	75 07                	jne    80105bc2 <strncmp+0x3e>
    return 0;
80105bbb:	b8 00 00 00 00       	mov    $0x0,%eax
80105bc0:	eb 16                	jmp    80105bd8 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80105bc5:	0f b6 00             	movzbl (%eax),%eax
80105bc8:	0f b6 d0             	movzbl %al,%edx
80105bcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bce:	0f b6 00             	movzbl (%eax),%eax
80105bd1:	0f b6 c0             	movzbl %al,%eax
80105bd4:	29 c2                	sub    %eax,%edx
80105bd6:	89 d0                	mov    %edx,%eax
}
80105bd8:	5d                   	pop    %ebp
80105bd9:	c3                   	ret    

80105bda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105bda:	55                   	push   %ebp
80105bdb:	89 e5                	mov    %esp,%ebp
80105bdd:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105be0:	8b 45 08             	mov    0x8(%ebp),%eax
80105be3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105be6:	90                   	nop
80105be7:	8b 45 10             	mov    0x10(%ebp),%eax
80105bea:	8d 50 ff             	lea    -0x1(%eax),%edx
80105bed:	89 55 10             	mov    %edx,0x10(%ebp)
80105bf0:	85 c0                	test   %eax,%eax
80105bf2:	7e 1e                	jle    80105c12 <strncpy+0x38>
80105bf4:	8b 45 08             	mov    0x8(%ebp),%eax
80105bf7:	8d 50 01             	lea    0x1(%eax),%edx
80105bfa:	89 55 08             	mov    %edx,0x8(%ebp)
80105bfd:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c00:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c03:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c06:	0f b6 12             	movzbl (%edx),%edx
80105c09:	88 10                	mov    %dl,(%eax)
80105c0b:	0f b6 00             	movzbl (%eax),%eax
80105c0e:	84 c0                	test   %al,%al
80105c10:	75 d5                	jne    80105be7 <strncpy+0xd>
    ;
  while(n-- > 0)
80105c12:	eb 0c                	jmp    80105c20 <strncpy+0x46>
    *s++ = 0;
80105c14:	8b 45 08             	mov    0x8(%ebp),%eax
80105c17:	8d 50 01             	lea    0x1(%eax),%edx
80105c1a:	89 55 08             	mov    %edx,0x8(%ebp)
80105c1d:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105c20:	8b 45 10             	mov    0x10(%ebp),%eax
80105c23:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c26:	89 55 10             	mov    %edx,0x10(%ebp)
80105c29:	85 c0                	test   %eax,%eax
80105c2b:	7f e7                	jg     80105c14 <strncpy+0x3a>
    *s++ = 0;
  return os;
80105c2d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c30:	c9                   	leave  
80105c31:	c3                   	ret    

80105c32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105c32:	55                   	push   %ebp
80105c33:	89 e5                	mov    %esp,%ebp
80105c35:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c38:	8b 45 08             	mov    0x8(%ebp),%eax
80105c3b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105c3e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c42:	7f 05                	jg     80105c49 <safestrcpy+0x17>
    return os;
80105c44:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c47:	eb 31                	jmp    80105c7a <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105c49:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c4d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c51:	7e 1e                	jle    80105c71 <safestrcpy+0x3f>
80105c53:	8b 45 08             	mov    0x8(%ebp),%eax
80105c56:	8d 50 01             	lea    0x1(%eax),%edx
80105c59:	89 55 08             	mov    %edx,0x8(%ebp)
80105c5c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c5f:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c62:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c65:	0f b6 12             	movzbl (%edx),%edx
80105c68:	88 10                	mov    %dl,(%eax)
80105c6a:	0f b6 00             	movzbl (%eax),%eax
80105c6d:	84 c0                	test   %al,%al
80105c6f:	75 d8                	jne    80105c49 <safestrcpy+0x17>
    ;
  *s = 0;
80105c71:	8b 45 08             	mov    0x8(%ebp),%eax
80105c74:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c77:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c7a:	c9                   	leave  
80105c7b:	c3                   	ret    

80105c7c <strlen>:

int
strlen(const char *s)
{
80105c7c:	55                   	push   %ebp
80105c7d:	89 e5                	mov    %esp,%ebp
80105c7f:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c82:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c89:	eb 04                	jmp    80105c8f <strlen+0x13>
80105c8b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c8f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c92:	8b 45 08             	mov    0x8(%ebp),%eax
80105c95:	01 d0                	add    %edx,%eax
80105c97:	0f b6 00             	movzbl (%eax),%eax
80105c9a:	84 c0                	test   %al,%al
80105c9c:	75 ed                	jne    80105c8b <strlen+0xf>
    ;
  return n;
80105c9e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ca1:	c9                   	leave  
80105ca2:	c3                   	ret    

80105ca3 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105ca3:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105ca7:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105cab:	55                   	push   %ebp
  pushl %ebx
80105cac:	53                   	push   %ebx
  pushl %esi
80105cad:	56                   	push   %esi
  pushl %edi
80105cae:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105caf:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105cb1:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105cb3:	5f                   	pop    %edi
  popl %esi
80105cb4:	5e                   	pop    %esi
  popl %ebx
80105cb5:	5b                   	pop    %ebx
  popl %ebp
80105cb6:	5d                   	pop    %ebp
  ret
80105cb7:	c3                   	ret    

80105cb8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105cb8:	55                   	push   %ebp
80105cb9:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105cbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cc1:	8b 00                	mov    (%eax),%eax
80105cc3:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cc6:	76 12                	jbe    80105cda <fetchint+0x22>
80105cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80105ccb:	8d 50 04             	lea    0x4(%eax),%edx
80105cce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cd4:	8b 00                	mov    (%eax),%eax
80105cd6:	39 c2                	cmp    %eax,%edx
80105cd8:	76 07                	jbe    80105ce1 <fetchint+0x29>
    return -1;
80105cda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cdf:	eb 0f                	jmp    80105cf0 <fetchint+0x38>
  *ip = *(int*)(addr);
80105ce1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce4:	8b 10                	mov    (%eax),%edx
80105ce6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce9:	89 10                	mov    %edx,(%eax)
  return 0;
80105ceb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105cf0:	5d                   	pop    %ebp
80105cf1:	c3                   	ret    

80105cf2 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105cf2:	55                   	push   %ebp
80105cf3:	89 e5                	mov    %esp,%ebp
80105cf5:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105cf8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cfe:	8b 00                	mov    (%eax),%eax
80105d00:	3b 45 08             	cmp    0x8(%ebp),%eax
80105d03:	77 07                	ja     80105d0c <fetchstr+0x1a>
    return -1;
80105d05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d0a:	eb 46                	jmp    80105d52 <fetchstr+0x60>
  *pp = (char*)addr;
80105d0c:	8b 55 08             	mov    0x8(%ebp),%edx
80105d0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d12:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105d14:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d1a:	8b 00                	mov    (%eax),%eax
80105d1c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105d1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d22:	8b 00                	mov    (%eax),%eax
80105d24:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105d27:	eb 1c                	jmp    80105d45 <fetchstr+0x53>
    if(*s == 0)
80105d29:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d2c:	0f b6 00             	movzbl (%eax),%eax
80105d2f:	84 c0                	test   %al,%al
80105d31:	75 0e                	jne    80105d41 <fetchstr+0x4f>
      return s - *pp;
80105d33:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d36:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d39:	8b 00                	mov    (%eax),%eax
80105d3b:	29 c2                	sub    %eax,%edx
80105d3d:	89 d0                	mov    %edx,%eax
80105d3f:	eb 11                	jmp    80105d52 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105d41:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d45:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d48:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d4b:	72 dc                	jb     80105d29 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105d4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d52:	c9                   	leave  
80105d53:	c3                   	ret    

80105d54 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d54:	55                   	push   %ebp
80105d55:	89 e5                	mov    %esp,%ebp
80105d57:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d60:	8b 40 18             	mov    0x18(%eax),%eax
80105d63:	8b 50 44             	mov    0x44(%eax),%edx
80105d66:	8b 45 08             	mov    0x8(%ebp),%eax
80105d69:	c1 e0 02             	shl    $0x2,%eax
80105d6c:	01 d0                	add    %edx,%eax
80105d6e:	8d 50 04             	lea    0x4(%eax),%edx
80105d71:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d74:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d78:	89 14 24             	mov    %edx,(%esp)
80105d7b:	e8 38 ff ff ff       	call   80105cb8 <fetchint>
}
80105d80:	c9                   	leave  
80105d81:	c3                   	ret    

80105d82 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d82:	55                   	push   %ebp
80105d83:	89 e5                	mov    %esp,%ebp
80105d85:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d88:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105d92:	89 04 24             	mov    %eax,(%esp)
80105d95:	e8 ba ff ff ff       	call   80105d54 <argint>
80105d9a:	85 c0                	test   %eax,%eax
80105d9c:	79 07                	jns    80105da5 <argptr+0x23>
    return -1;
80105d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105da3:	eb 3d                	jmp    80105de2 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105da5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105da8:	89 c2                	mov    %eax,%edx
80105daa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105db0:	8b 00                	mov    (%eax),%eax
80105db2:	39 c2                	cmp    %eax,%edx
80105db4:	73 16                	jae    80105dcc <argptr+0x4a>
80105db6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105db9:	89 c2                	mov    %eax,%edx
80105dbb:	8b 45 10             	mov    0x10(%ebp),%eax
80105dbe:	01 c2                	add    %eax,%edx
80105dc0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dc6:	8b 00                	mov    (%eax),%eax
80105dc8:	39 c2                	cmp    %eax,%edx
80105dca:	76 07                	jbe    80105dd3 <argptr+0x51>
    return -1;
80105dcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dd1:	eb 0f                	jmp    80105de2 <argptr+0x60>
  *pp = (char*)i;
80105dd3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dd6:	89 c2                	mov    %eax,%edx
80105dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ddb:	89 10                	mov    %edx,(%eax)
  return 0;
80105ddd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105de2:	c9                   	leave  
80105de3:	c3                   	ret    

80105de4 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105de4:	55                   	push   %ebp
80105de5:	89 e5                	mov    %esp,%ebp
80105de7:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105dea:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105ded:	89 44 24 04          	mov    %eax,0x4(%esp)
80105df1:	8b 45 08             	mov    0x8(%ebp),%eax
80105df4:	89 04 24             	mov    %eax,(%esp)
80105df7:	e8 58 ff ff ff       	call   80105d54 <argint>
80105dfc:	85 c0                	test   %eax,%eax
80105dfe:	79 07                	jns    80105e07 <argstr+0x23>
    return -1;
80105e00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e05:	eb 12                	jmp    80105e19 <argstr+0x35>
  return fetchstr(addr, pp);
80105e07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e0a:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e0d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e11:	89 04 24             	mov    %eax,(%esp)
80105e14:	e8 d9 fe ff ff       	call   80105cf2 <fetchstr>
}
80105e19:	c9                   	leave  
80105e1a:	c3                   	ret    

80105e1b <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105e1b:	55                   	push   %ebp
80105e1c:	89 e5                	mov    %esp,%ebp
80105e1e:	53                   	push   %ebx
80105e1f:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105e22:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e28:	8b 40 18             	mov    0x18(%eax),%eax
80105e2b:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e2e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105e31:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e35:	7e 30                	jle    80105e67 <syscall+0x4c>
80105e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e3a:	83 f8 15             	cmp    $0x15,%eax
80105e3d:	77 28                	ja     80105e67 <syscall+0x4c>
80105e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e42:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e49:	85 c0                	test   %eax,%eax
80105e4b:	74 1a                	je     80105e67 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105e4d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e53:	8b 58 18             	mov    0x18(%eax),%ebx
80105e56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e59:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e60:	ff d0                	call   *%eax
80105e62:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e65:	eb 3d                	jmp    80105ea4 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e6d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e76:	8b 40 10             	mov    0x10(%eax),%eax
80105e79:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e7c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e80:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e84:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e88:	c7 04 24 00 a1 10 80 	movl   $0x8010a100,(%esp)
80105e8f:	e8 0c a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e9a:	8b 40 18             	mov    0x18(%eax),%eax
80105e9d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105ea4:	83 c4 24             	add    $0x24,%esp
80105ea7:	5b                   	pop    %ebx
80105ea8:	5d                   	pop    %ebp
80105ea9:	c3                   	ret    

80105eaa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105eaa:	55                   	push   %ebp
80105eab:	89 e5                	mov    %esp,%ebp
80105ead:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105eb0:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105eb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80105eba:	89 04 24             	mov    %eax,(%esp)
80105ebd:	e8 92 fe ff ff       	call   80105d54 <argint>
80105ec2:	85 c0                	test   %eax,%eax
80105ec4:	79 07                	jns    80105ecd <argfd+0x23>
    return -1;
80105ec6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ecb:	eb 50                	jmp    80105f1d <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105ecd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed0:	85 c0                	test   %eax,%eax
80105ed2:	78 21                	js     80105ef5 <argfd+0x4b>
80105ed4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed7:	83 f8 0f             	cmp    $0xf,%eax
80105eda:	7f 19                	jg     80105ef5 <argfd+0x4b>
80105edc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ee2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ee5:	83 c2 08             	add    $0x8,%edx
80105ee8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105eec:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105eef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ef3:	75 07                	jne    80105efc <argfd+0x52>
    return -1;
80105ef5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105efa:	eb 21                	jmp    80105f1d <argfd+0x73>
  if(pfd)
80105efc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105f00:	74 08                	je     80105f0a <argfd+0x60>
    *pfd = fd;
80105f02:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105f05:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f08:	89 10                	mov    %edx,(%eax)
  if(pf)
80105f0a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f0e:	74 08                	je     80105f18 <argfd+0x6e>
    *pf = f;
80105f10:	8b 45 10             	mov    0x10(%ebp),%eax
80105f13:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f16:	89 10                	mov    %edx,(%eax)
  return 0;
80105f18:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f1d:	c9                   	leave  
80105f1e:	c3                   	ret    

80105f1f <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105f1f:	55                   	push   %ebp
80105f20:	89 e5                	mov    %esp,%ebp
80105f22:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f25:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f2c:	eb 30                	jmp    80105f5e <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f34:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f37:	83 c2 08             	add    $0x8,%edx
80105f3a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f3e:	85 c0                	test   %eax,%eax
80105f40:	75 18                	jne    80105f5a <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f48:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f4b:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f4e:	8b 55 08             	mov    0x8(%ebp),%edx
80105f51:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f55:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f58:	eb 0f                	jmp    80105f69 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f5a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f5e:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f62:	7e ca                	jle    80105f2e <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f69:	c9                   	leave  
80105f6a:	c3                   	ret    

80105f6b <sys_dup>:

int
sys_dup(void)
{
80105f6b:	55                   	push   %ebp
80105f6c:	89 e5                	mov    %esp,%ebp
80105f6e:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f71:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f74:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f7f:	00 
80105f80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f87:	e8 1e ff ff ff       	call   80105eaa <argfd>
80105f8c:	85 c0                	test   %eax,%eax
80105f8e:	79 07                	jns    80105f97 <sys_dup+0x2c>
    return -1;
80105f90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f95:	eb 29                	jmp    80105fc0 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f9a:	89 04 24             	mov    %eax,(%esp)
80105f9d:	e8 7d ff ff ff       	call   80105f1f <fdalloc>
80105fa2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fa5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fa9:	79 07                	jns    80105fb2 <sys_dup+0x47>
    return -1;
80105fab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fb0:	eb 0e                	jmp    80105fc0 <sys_dup+0x55>
  filedup(f);
80105fb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb5:	89 04 24             	mov    %eax,(%esp)
80105fb8:	e8 c9 b0 ff ff       	call   80101086 <filedup>
  return fd;
80105fbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105fc0:	c9                   	leave  
80105fc1:	c3                   	ret    

80105fc2 <sys_read>:

int
sys_read(void)
{
80105fc2:	55                   	push   %ebp
80105fc3:	89 e5                	mov    %esp,%ebp
80105fc5:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fc8:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fcb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fcf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fd6:	00 
80105fd7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fde:	e8 c7 fe ff ff       	call   80105eaa <argfd>
80105fe3:	85 c0                	test   %eax,%eax
80105fe5:	78 35                	js     8010601c <sys_read+0x5a>
80105fe7:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fea:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fee:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105ff5:	e8 5a fd ff ff       	call   80105d54 <argint>
80105ffa:	85 c0                	test   %eax,%eax
80105ffc:	78 1e                	js     8010601c <sys_read+0x5a>
80105ffe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106001:	89 44 24 08          	mov    %eax,0x8(%esp)
80106005:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106008:	89 44 24 04          	mov    %eax,0x4(%esp)
8010600c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106013:	e8 6a fd ff ff       	call   80105d82 <argptr>
80106018:	85 c0                	test   %eax,%eax
8010601a:	79 07                	jns    80106023 <sys_read+0x61>
    return -1;
8010601c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106021:	eb 19                	jmp    8010603c <sys_read+0x7a>
  return fileread(f, p, n);
80106023:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106026:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106029:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106030:	89 54 24 04          	mov    %edx,0x4(%esp)
80106034:	89 04 24             	mov    %eax,(%esp)
80106037:	e8 b7 b1 ff ff       	call   801011f3 <fileread>
}
8010603c:	c9                   	leave  
8010603d:	c3                   	ret    

8010603e <sys_write>:

int
sys_write(void)
{
8010603e:	55                   	push   %ebp
8010603f:	89 e5                	mov    %esp,%ebp
80106041:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106044:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106047:	89 44 24 08          	mov    %eax,0x8(%esp)
8010604b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106052:	00 
80106053:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010605a:	e8 4b fe ff ff       	call   80105eaa <argfd>
8010605f:	85 c0                	test   %eax,%eax
80106061:	78 35                	js     80106098 <sys_write+0x5a>
80106063:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106066:	89 44 24 04          	mov    %eax,0x4(%esp)
8010606a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106071:	e8 de fc ff ff       	call   80105d54 <argint>
80106076:	85 c0                	test   %eax,%eax
80106078:	78 1e                	js     80106098 <sys_write+0x5a>
8010607a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106081:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106084:	89 44 24 04          	mov    %eax,0x4(%esp)
80106088:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010608f:	e8 ee fc ff ff       	call   80105d82 <argptr>
80106094:	85 c0                	test   %eax,%eax
80106096:	79 07                	jns    8010609f <sys_write+0x61>
    return -1;
80106098:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010609d:	eb 19                	jmp    801060b8 <sys_write+0x7a>
  return filewrite(f, p, n);
8010609f:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801060a2:	8b 55 ec             	mov    -0x14(%ebp),%edx
801060a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801060b0:	89 04 24             	mov    %eax,(%esp)
801060b3:	e8 f7 b1 ff ff       	call   801012af <filewrite>
}
801060b8:	c9                   	leave  
801060b9:	c3                   	ret    

801060ba <sys_close>:

int
sys_close(void)
{
801060ba:	55                   	push   %ebp
801060bb:	89 e5                	mov    %esp,%ebp
801060bd:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801060c0:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060c3:	89 44 24 08          	mov    %eax,0x8(%esp)
801060c7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060d5:	e8 d0 fd ff ff       	call   80105eaa <argfd>
801060da:	85 c0                	test   %eax,%eax
801060dc:	79 07                	jns    801060e5 <sys_close+0x2b>
    return -1;
801060de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060e3:	eb 24                	jmp    80106109 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801060e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060ee:	83 c2 08             	add    $0x8,%edx
801060f1:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060f8:	00 
  fileclose(f);
801060f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060fc:	89 04 24             	mov    %eax,(%esp)
801060ff:	e8 ca af ff ff       	call   801010ce <fileclose>
  return 0;
80106104:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106109:	c9                   	leave  
8010610a:	c3                   	ret    

8010610b <sys_fstat>:

int
sys_fstat(void)
{
8010610b:	55                   	push   %ebp
8010610c:	89 e5                	mov    %esp,%ebp
8010610e:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106111:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106114:	89 44 24 08          	mov    %eax,0x8(%esp)
80106118:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010611f:	00 
80106120:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106127:	e8 7e fd ff ff       	call   80105eaa <argfd>
8010612c:	85 c0                	test   %eax,%eax
8010612e:	78 1f                	js     8010614f <sys_fstat+0x44>
80106130:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106137:	00 
80106138:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010613b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010613f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106146:	e8 37 fc ff ff       	call   80105d82 <argptr>
8010614b:	85 c0                	test   %eax,%eax
8010614d:	79 07                	jns    80106156 <sys_fstat+0x4b>
    return -1;
8010614f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106154:	eb 12                	jmp    80106168 <sys_fstat+0x5d>
  return filestat(f, st);
80106156:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106159:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010615c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106160:	89 04 24             	mov    %eax,(%esp)
80106163:	e8 3c b0 ff ff       	call   801011a4 <filestat>
}
80106168:	c9                   	leave  
80106169:	c3                   	ret    

8010616a <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010616a:	55                   	push   %ebp
8010616b:	89 e5                	mov    %esp,%ebp
8010616d:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106170:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106173:	89 44 24 04          	mov    %eax,0x4(%esp)
80106177:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010617e:	e8 61 fc ff ff       	call   80105de4 <argstr>
80106183:	85 c0                	test   %eax,%eax
80106185:	78 17                	js     8010619e <sys_link+0x34>
80106187:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010618a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010618e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106195:	e8 4a fc ff ff       	call   80105de4 <argstr>
8010619a:	85 c0                	test   %eax,%eax
8010619c:	79 0a                	jns    801061a8 <sys_link+0x3e>
    return -1;
8010619e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a3:	e9 42 01 00 00       	jmp    801062ea <sys_link+0x180>

  begin_op();
801061a8:	e8 16 da ff ff       	call   80103bc3 <begin_op>
  if((ip = namei(old)) == 0){
801061ad:	8b 45 d8             	mov    -0x28(%ebp),%eax
801061b0:	89 04 24             	mov    %eax,(%esp)
801061b3:	e8 b2 c3 ff ff       	call   8010256a <namei>
801061b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061bb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061bf:	75 0f                	jne    801061d0 <sys_link+0x66>
    end_op();
801061c1:	e8 81 da ff ff       	call   80103c47 <end_op>
    return -1;
801061c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061cb:	e9 1a 01 00 00       	jmp    801062ea <sys_link+0x180>
  }

  ilock(ip);
801061d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d3:	89 04 24             	mov    %eax,(%esp)
801061d6:	e8 de b7 ff ff       	call   801019b9 <ilock>
  if(ip->type == T_DIR){
801061db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061de:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061e2:	66 83 f8 01          	cmp    $0x1,%ax
801061e6:	75 1a                	jne    80106202 <sys_link+0x98>
    iunlockput(ip);
801061e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061eb:	89 04 24             	mov    %eax,(%esp)
801061ee:	e8 50 ba ff ff       	call   80101c43 <iunlockput>
    end_op();
801061f3:	e8 4f da ff ff       	call   80103c47 <end_op>
    return -1;
801061f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061fd:	e9 e8 00 00 00       	jmp    801062ea <sys_link+0x180>
  }

  ip->nlink++;
80106202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106205:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106209:	8d 50 01             	lea    0x1(%eax),%edx
8010620c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010620f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106213:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106216:	89 04 24             	mov    %eax,(%esp)
80106219:	e8 d9 b5 ff ff       	call   801017f7 <iupdate>
  iunlock(ip);
8010621e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106221:	89 04 24             	mov    %eax,(%esp)
80106224:	e8 e4 b8 ff ff       	call   80101b0d <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106229:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010622c:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010622f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106233:	89 04 24             	mov    %eax,(%esp)
80106236:	e8 51 c3 ff ff       	call   8010258c <nameiparent>
8010623b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010623e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106242:	75 02                	jne    80106246 <sys_link+0xdc>
    goto bad;
80106244:	eb 68                	jmp    801062ae <sys_link+0x144>
  ilock(dp);
80106246:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106249:	89 04 24             	mov    %eax,(%esp)
8010624c:	e8 68 b7 ff ff       	call   801019b9 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106251:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106254:	8b 10                	mov    (%eax),%edx
80106256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106259:	8b 00                	mov    (%eax),%eax
8010625b:	39 c2                	cmp    %eax,%edx
8010625d:	75 20                	jne    8010627f <sys_link+0x115>
8010625f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106262:	8b 40 04             	mov    0x4(%eax),%eax
80106265:	89 44 24 08          	mov    %eax,0x8(%esp)
80106269:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010626c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106270:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106273:	89 04 24             	mov    %eax,(%esp)
80106276:	e8 2f c0 ff ff       	call   801022aa <dirlink>
8010627b:	85 c0                	test   %eax,%eax
8010627d:	79 0d                	jns    8010628c <sys_link+0x122>
    iunlockput(dp);
8010627f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106282:	89 04 24             	mov    %eax,(%esp)
80106285:	e8 b9 b9 ff ff       	call   80101c43 <iunlockput>
    goto bad;
8010628a:	eb 22                	jmp    801062ae <sys_link+0x144>
  }
  iunlockput(dp);
8010628c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010628f:	89 04 24             	mov    %eax,(%esp)
80106292:	e8 ac b9 ff ff       	call   80101c43 <iunlockput>
  iput(ip);
80106297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010629a:	89 04 24             	mov    %eax,(%esp)
8010629d:	e8 d0 b8 ff ff       	call   80101b72 <iput>

  end_op();
801062a2:	e8 a0 d9 ff ff       	call   80103c47 <end_op>

  return 0;
801062a7:	b8 00 00 00 00       	mov    $0x0,%eax
801062ac:	eb 3c                	jmp    801062ea <sys_link+0x180>

bad:
  ilock(ip);
801062ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b1:	89 04 24             	mov    %eax,(%esp)
801062b4:	e8 00 b7 ff ff       	call   801019b9 <ilock>
  ip->nlink--;
801062b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062c0:	8d 50 ff             	lea    -0x1(%eax),%edx
801062c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c6:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062cd:	89 04 24             	mov    %eax,(%esp)
801062d0:	e8 22 b5 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801062d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d8:	89 04 24             	mov    %eax,(%esp)
801062db:	e8 63 b9 ff ff       	call   80101c43 <iunlockput>
  end_op();
801062e0:	e8 62 d9 ff ff       	call   80103c47 <end_op>
  return -1;
801062e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062ea:	c9                   	leave  
801062eb:	c3                   	ret    

801062ec <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
801062ec:	55                   	push   %ebp
801062ed:	89 e5                	mov    %esp,%ebp
801062ef:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062f2:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062f9:	eb 4b                	jmp    80106346 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062fe:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106305:	00 
80106306:	89 44 24 08          	mov    %eax,0x8(%esp)
8010630a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010630d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106311:	8b 45 08             	mov    0x8(%ebp),%eax
80106314:	89 04 24             	mov    %eax,(%esp)
80106317:	e8 b0 bb ff ff       	call   80101ecc <readi>
8010631c:	83 f8 10             	cmp    $0x10,%eax
8010631f:	74 0c                	je     8010632d <isdirempty+0x41>
      panic("isdirempty: readi");
80106321:	c7 04 24 1c a1 10 80 	movl   $0x8010a11c,(%esp)
80106328:	e8 0d a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
8010632d:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106331:	66 85 c0             	test   %ax,%ax
80106334:	74 07                	je     8010633d <isdirempty+0x51>
      return 0;
80106336:	b8 00 00 00 00       	mov    $0x0,%eax
8010633b:	eb 1b                	jmp    80106358 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010633d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106340:	83 c0 10             	add    $0x10,%eax
80106343:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106346:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106349:	8b 45 08             	mov    0x8(%ebp),%eax
8010634c:	8b 40 18             	mov    0x18(%eax),%eax
8010634f:	39 c2                	cmp    %eax,%edx
80106351:	72 a8                	jb     801062fb <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106353:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106358:	c9                   	leave  
80106359:	c3                   	ret    

8010635a <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010635a:	55                   	push   %ebp
8010635b:	89 e5                	mov    %esp,%ebp
8010635d:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106360:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106363:	89 44 24 04          	mov    %eax,0x4(%esp)
80106367:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010636e:	e8 71 fa ff ff       	call   80105de4 <argstr>
80106373:	85 c0                	test   %eax,%eax
80106375:	79 0a                	jns    80106381 <sys_unlink+0x27>
    return -1;
80106377:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010637c:	e9 af 01 00 00       	jmp    80106530 <sys_unlink+0x1d6>

  begin_op();
80106381:	e8 3d d8 ff ff       	call   80103bc3 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80106386:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106389:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010638c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106390:	89 04 24             	mov    %eax,(%esp)
80106393:	e8 f4 c1 ff ff       	call   8010258c <nameiparent>
80106398:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010639b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010639f:	75 0f                	jne    801063b0 <sys_unlink+0x56>
    end_op();
801063a1:	e8 a1 d8 ff ff       	call   80103c47 <end_op>
    return -1;
801063a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063ab:	e9 80 01 00 00       	jmp    80106530 <sys_unlink+0x1d6>
  }

  ilock(dp);
801063b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b3:	89 04 24             	mov    %eax,(%esp)
801063b6:	e8 fe b5 ff ff       	call   801019b9 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801063bb:	c7 44 24 04 2e a1 10 	movl   $0x8010a12e,0x4(%esp)
801063c2:	80 
801063c3:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063c6:	89 04 24             	mov    %eax,(%esp)
801063c9:	e8 f1 bd ff ff       	call   801021bf <namecmp>
801063ce:	85 c0                	test   %eax,%eax
801063d0:	0f 84 45 01 00 00    	je     8010651b <sys_unlink+0x1c1>
801063d6:	c7 44 24 04 30 a1 10 	movl   $0x8010a130,0x4(%esp)
801063dd:	80 
801063de:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063e1:	89 04 24             	mov    %eax,(%esp)
801063e4:	e8 d6 bd ff ff       	call   801021bf <namecmp>
801063e9:	85 c0                	test   %eax,%eax
801063eb:	0f 84 2a 01 00 00    	je     8010651b <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063f1:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063f4:	89 44 24 08          	mov    %eax,0x8(%esp)
801063f8:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801063ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106402:	89 04 24             	mov    %eax,(%esp)
80106405:	e8 d7 bd ff ff       	call   801021e1 <dirlookup>
8010640a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010640d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106411:	75 05                	jne    80106418 <sys_unlink+0xbe>
    goto bad;
80106413:	e9 03 01 00 00       	jmp    8010651b <sys_unlink+0x1c1>
  ilock(ip);
80106418:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010641b:	89 04 24             	mov    %eax,(%esp)
8010641e:	e8 96 b5 ff ff       	call   801019b9 <ilock>

  if(ip->nlink < 1)
80106423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106426:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010642a:	66 85 c0             	test   %ax,%ax
8010642d:	7f 0c                	jg     8010643b <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
8010642f:	c7 04 24 33 a1 10 80 	movl   $0x8010a133,(%esp)
80106436:	e8 ff a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010643b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106442:	66 83 f8 01          	cmp    $0x1,%ax
80106446:	75 1f                	jne    80106467 <sys_unlink+0x10d>
80106448:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010644b:	89 04 24             	mov    %eax,(%esp)
8010644e:	e8 99 fe ff ff       	call   801062ec <isdirempty>
80106453:	85 c0                	test   %eax,%eax
80106455:	75 10                	jne    80106467 <sys_unlink+0x10d>
    iunlockput(ip);
80106457:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010645a:	89 04 24             	mov    %eax,(%esp)
8010645d:	e8 e1 b7 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106462:	e9 b4 00 00 00       	jmp    8010651b <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106467:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010646e:	00 
8010646f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106476:	00 
80106477:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010647a:	89 04 24             	mov    %eax,(%esp)
8010647d:	e8 90 f5 ff ff       	call   80105a12 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106482:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106485:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010648c:	00 
8010648d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106491:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106494:	89 44 24 04          	mov    %eax,0x4(%esp)
80106498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649b:	89 04 24             	mov    %eax,(%esp)
8010649e:	e8 8d bb ff ff       	call   80102030 <writei>
801064a3:	83 f8 10             	cmp    $0x10,%eax
801064a6:	74 0c                	je     801064b4 <sys_unlink+0x15a>
    panic("unlink: writei");
801064a8:	c7 04 24 45 a1 10 80 	movl   $0x8010a145,(%esp)
801064af:	e8 86 a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
801064b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064bb:	66 83 f8 01          	cmp    $0x1,%ax
801064bf:	75 1c                	jne    801064dd <sys_unlink+0x183>
    dp->nlink--;
801064c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064c8:	8d 50 ff             	lea    -0x1(%eax),%edx
801064cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ce:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d5:	89 04 24             	mov    %eax,(%esp)
801064d8:	e8 1a b3 ff ff       	call   801017f7 <iupdate>
  }
  iunlockput(dp);
801064dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064e0:	89 04 24             	mov    %eax,(%esp)
801064e3:	e8 5b b7 ff ff       	call   80101c43 <iunlockput>

  ip->nlink--;
801064e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064eb:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064ef:	8d 50 ff             	lea    -0x1(%eax),%edx
801064f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f5:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064fc:	89 04 24             	mov    %eax,(%esp)
801064ff:	e8 f3 b2 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
80106504:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106507:	89 04 24             	mov    %eax,(%esp)
8010650a:	e8 34 b7 ff ff       	call   80101c43 <iunlockput>

  end_op();
8010650f:	e8 33 d7 ff ff       	call   80103c47 <end_op>

  return 0;
80106514:	b8 00 00 00 00       	mov    $0x0,%eax
80106519:	eb 15                	jmp    80106530 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
8010651b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651e:	89 04 24             	mov    %eax,(%esp)
80106521:	e8 1d b7 ff ff       	call   80101c43 <iunlockput>
  end_op();
80106526:	e8 1c d7 ff ff       	call   80103c47 <end_op>
  return -1;
8010652b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106530:	c9                   	leave  
80106531:	c3                   	ret    

80106532 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106532:	55                   	push   %ebp
80106533:	89 e5                	mov    %esp,%ebp
80106535:	83 ec 48             	sub    $0x48,%esp
80106538:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010653b:	8b 55 10             	mov    0x10(%ebp),%edx
8010653e:	8b 45 14             	mov    0x14(%ebp),%eax
80106541:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106545:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106549:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010654d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106550:	89 44 24 04          	mov    %eax,0x4(%esp)
80106554:	8b 45 08             	mov    0x8(%ebp),%eax
80106557:	89 04 24             	mov    %eax,(%esp)
8010655a:	e8 2d c0 ff ff       	call   8010258c <nameiparent>
8010655f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106562:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106566:	75 0a                	jne    80106572 <create+0x40>
    return 0;
80106568:	b8 00 00 00 00       	mov    $0x0,%eax
8010656d:	e9 7e 01 00 00       	jmp    801066f0 <create+0x1be>
  ilock(dp);
80106572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106575:	89 04 24             	mov    %eax,(%esp)
80106578:	e8 3c b4 ff ff       	call   801019b9 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010657d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106580:	89 44 24 08          	mov    %eax,0x8(%esp)
80106584:	8d 45 de             	lea    -0x22(%ebp),%eax
80106587:	89 44 24 04          	mov    %eax,0x4(%esp)
8010658b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010658e:	89 04 24             	mov    %eax,(%esp)
80106591:	e8 4b bc ff ff       	call   801021e1 <dirlookup>
80106596:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106599:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010659d:	74 47                	je     801065e6 <create+0xb4>
    iunlockput(dp);
8010659f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a2:	89 04 24             	mov    %eax,(%esp)
801065a5:	e8 99 b6 ff ff       	call   80101c43 <iunlockput>
    ilock(ip);
801065aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ad:	89 04 24             	mov    %eax,(%esp)
801065b0:	e8 04 b4 ff ff       	call   801019b9 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801065b5:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801065ba:	75 15                	jne    801065d1 <create+0x9f>
801065bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065bf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801065c3:	66 83 f8 02          	cmp    $0x2,%ax
801065c7:	75 08                	jne    801065d1 <create+0x9f>
      return ip;
801065c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065cc:	e9 1f 01 00 00       	jmp    801066f0 <create+0x1be>
    iunlockput(ip);
801065d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d4:	89 04 24             	mov    %eax,(%esp)
801065d7:	e8 67 b6 ff ff       	call   80101c43 <iunlockput>
    return 0;
801065dc:	b8 00 00 00 00       	mov    $0x0,%eax
801065e1:	e9 0a 01 00 00       	jmp    801066f0 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801065e6:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801065ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ed:	8b 00                	mov    (%eax),%eax
801065ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801065f3:	89 04 24             	mov    %eax,(%esp)
801065f6:	e8 27 b1 ff ff       	call   80101722 <ialloc>
801065fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065fe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106602:	75 0c                	jne    80106610 <create+0xde>
    panic("create: ialloc");
80106604:	c7 04 24 54 a1 10 80 	movl   $0x8010a154,(%esp)
8010660b:	e8 2a 9f ff ff       	call   8010053a <panic>

  ilock(ip);
80106610:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106613:	89 04 24             	mov    %eax,(%esp)
80106616:	e8 9e b3 ff ff       	call   801019b9 <ilock>
  ip->major = major;
8010661b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010661e:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106622:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106626:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106629:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
8010662d:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106631:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106634:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
8010663a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010663d:	89 04 24             	mov    %eax,(%esp)
80106640:	e8 b2 b1 ff ff       	call   801017f7 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106645:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010664a:	75 6a                	jne    801066b6 <create+0x184>
    dp->nlink++;  // for ".."
8010664c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106653:	8d 50 01             	lea    0x1(%eax),%edx
80106656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106659:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010665d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106660:	89 04 24             	mov    %eax,(%esp)
80106663:	e8 8f b1 ff ff       	call   801017f7 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106668:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010666b:	8b 40 04             	mov    0x4(%eax),%eax
8010666e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106672:	c7 44 24 04 2e a1 10 	movl   $0x8010a12e,0x4(%esp)
80106679:	80 
8010667a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010667d:	89 04 24             	mov    %eax,(%esp)
80106680:	e8 25 bc ff ff       	call   801022aa <dirlink>
80106685:	85 c0                	test   %eax,%eax
80106687:	78 21                	js     801066aa <create+0x178>
80106689:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668c:	8b 40 04             	mov    0x4(%eax),%eax
8010668f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106693:	c7 44 24 04 30 a1 10 	movl   $0x8010a130,0x4(%esp)
8010669a:	80 
8010669b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010669e:	89 04 24             	mov    %eax,(%esp)
801066a1:	e8 04 bc ff ff       	call   801022aa <dirlink>
801066a6:	85 c0                	test   %eax,%eax
801066a8:	79 0c                	jns    801066b6 <create+0x184>
      panic("create dots");
801066aa:	c7 04 24 63 a1 10 80 	movl   $0x8010a163,(%esp)
801066b1:	e8 84 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
801066b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b9:	8b 40 04             	mov    0x4(%eax),%eax
801066bc:	89 44 24 08          	mov    %eax,0x8(%esp)
801066c0:	8d 45 de             	lea    -0x22(%ebp),%eax
801066c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801066c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ca:	89 04 24             	mov    %eax,(%esp)
801066cd:	e8 d8 bb ff ff       	call   801022aa <dirlink>
801066d2:	85 c0                	test   %eax,%eax
801066d4:	79 0c                	jns    801066e2 <create+0x1b0>
    panic("create: dirlink");
801066d6:	c7 04 24 6f a1 10 80 	movl   $0x8010a16f,(%esp)
801066dd:	e8 58 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
801066e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e5:	89 04 24             	mov    %eax,(%esp)
801066e8:	e8 56 b5 ff ff       	call   80101c43 <iunlockput>

  return ip;
801066ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066f0:	c9                   	leave  
801066f1:	c3                   	ret    

801066f2 <sys_open>:

int
sys_open(void)
{
801066f2:	55                   	push   %ebp
801066f3:	89 e5                	mov    %esp,%ebp
801066f5:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066f8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106706:	e8 d9 f6 ff ff       	call   80105de4 <argstr>
8010670b:	85 c0                	test   %eax,%eax
8010670d:	78 17                	js     80106726 <sys_open+0x34>
8010670f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106712:	89 44 24 04          	mov    %eax,0x4(%esp)
80106716:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010671d:	e8 32 f6 ff ff       	call   80105d54 <argint>
80106722:	85 c0                	test   %eax,%eax
80106724:	79 0a                	jns    80106730 <sys_open+0x3e>
    return -1;
80106726:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010672b:	e9 5c 01 00 00       	jmp    8010688c <sys_open+0x19a>

  begin_op();
80106730:	e8 8e d4 ff ff       	call   80103bc3 <begin_op>

  if(omode & O_CREATE){
80106735:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106738:	25 00 02 00 00       	and    $0x200,%eax
8010673d:	85 c0                	test   %eax,%eax
8010673f:	74 3b                	je     8010677c <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106741:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106744:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010674b:	00 
8010674c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106753:	00 
80106754:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010675b:	00 
8010675c:	89 04 24             	mov    %eax,(%esp)
8010675f:	e8 ce fd ff ff       	call   80106532 <create>
80106764:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106767:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010676b:	75 6b                	jne    801067d8 <sys_open+0xe6>
      end_op();
8010676d:	e8 d5 d4 ff ff       	call   80103c47 <end_op>
      return -1;
80106772:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106777:	e9 10 01 00 00       	jmp    8010688c <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
8010677c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010677f:	89 04 24             	mov    %eax,(%esp)
80106782:	e8 e3 bd ff ff       	call   8010256a <namei>
80106787:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010678a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010678e:	75 0f                	jne    8010679f <sys_open+0xad>
      end_op();
80106790:	e8 b2 d4 ff ff       	call   80103c47 <end_op>
      return -1;
80106795:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010679a:	e9 ed 00 00 00       	jmp    8010688c <sys_open+0x19a>
    }
    ilock(ip);
8010679f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a2:	89 04 24             	mov    %eax,(%esp)
801067a5:	e8 0f b2 ff ff       	call   801019b9 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801067aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ad:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801067b1:	66 83 f8 01          	cmp    $0x1,%ax
801067b5:	75 21                	jne    801067d8 <sys_open+0xe6>
801067b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067ba:	85 c0                	test   %eax,%eax
801067bc:	74 1a                	je     801067d8 <sys_open+0xe6>
      iunlockput(ip);
801067be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c1:	89 04 24             	mov    %eax,(%esp)
801067c4:	e8 7a b4 ff ff       	call   80101c43 <iunlockput>
      end_op();
801067c9:	e8 79 d4 ff ff       	call   80103c47 <end_op>
      return -1;
801067ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067d3:	e9 b4 00 00 00       	jmp    8010688c <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067d8:	e8 49 a8 ff ff       	call   80101026 <filealloc>
801067dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067e4:	74 14                	je     801067fa <sys_open+0x108>
801067e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067e9:	89 04 24             	mov    %eax,(%esp)
801067ec:	e8 2e f7 ff ff       	call   80105f1f <fdalloc>
801067f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067f4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067f8:	79 28                	jns    80106822 <sys_open+0x130>
    if(f)
801067fa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067fe:	74 0b                	je     8010680b <sys_open+0x119>
      fileclose(f);
80106800:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106803:	89 04 24             	mov    %eax,(%esp)
80106806:	e8 c3 a8 ff ff       	call   801010ce <fileclose>
    iunlockput(ip);
8010680b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680e:	89 04 24             	mov    %eax,(%esp)
80106811:	e8 2d b4 ff ff       	call   80101c43 <iunlockput>
    end_op();
80106816:	e8 2c d4 ff ff       	call   80103c47 <end_op>
    return -1;
8010681b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106820:	eb 6a                	jmp    8010688c <sys_open+0x19a>
  }
  iunlock(ip);
80106822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106825:	89 04 24             	mov    %eax,(%esp)
80106828:	e8 e0 b2 ff ff       	call   80101b0d <iunlock>
  end_op();
8010682d:	e8 15 d4 ff ff       	call   80103c47 <end_op>

  f->type = FD_INODE;
80106832:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106835:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010683b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010683e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106841:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106844:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106847:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010684e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106851:	83 e0 01             	and    $0x1,%eax
80106854:	85 c0                	test   %eax,%eax
80106856:	0f 94 c0             	sete   %al
80106859:	89 c2                	mov    %eax,%edx
8010685b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010685e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106861:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106864:	83 e0 01             	and    $0x1,%eax
80106867:	85 c0                	test   %eax,%eax
80106869:	75 0a                	jne    80106875 <sys_open+0x183>
8010686b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010686e:	83 e0 02             	and    $0x2,%eax
80106871:	85 c0                	test   %eax,%eax
80106873:	74 07                	je     8010687c <sys_open+0x18a>
80106875:	b8 01 00 00 00       	mov    $0x1,%eax
8010687a:	eb 05                	jmp    80106881 <sys_open+0x18f>
8010687c:	b8 00 00 00 00       	mov    $0x0,%eax
80106881:	89 c2                	mov    %eax,%edx
80106883:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106886:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106889:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010688c:	c9                   	leave  
8010688d:	c3                   	ret    

8010688e <sys_mkdir>:

int
sys_mkdir(void)
{
8010688e:	55                   	push   %ebp
8010688f:	89 e5                	mov    %esp,%ebp
80106891:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106894:	e8 2a d3 ff ff       	call   80103bc3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106899:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010689c:	89 44 24 04          	mov    %eax,0x4(%esp)
801068a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068a7:	e8 38 f5 ff ff       	call   80105de4 <argstr>
801068ac:	85 c0                	test   %eax,%eax
801068ae:	78 2c                	js     801068dc <sys_mkdir+0x4e>
801068b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068b3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801068ba:	00 
801068bb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801068c2:	00 
801068c3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068ca:	00 
801068cb:	89 04 24             	mov    %eax,(%esp)
801068ce:	e8 5f fc ff ff       	call   80106532 <create>
801068d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068d6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068da:	75 0c                	jne    801068e8 <sys_mkdir+0x5a>
    end_op();
801068dc:	e8 66 d3 ff ff       	call   80103c47 <end_op>
    return -1;
801068e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068e6:	eb 15                	jmp    801068fd <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801068e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068eb:	89 04 24             	mov    %eax,(%esp)
801068ee:	e8 50 b3 ff ff       	call   80101c43 <iunlockput>
  end_op();
801068f3:	e8 4f d3 ff ff       	call   80103c47 <end_op>
  return 0;
801068f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068fd:	c9                   	leave  
801068fe:	c3                   	ret    

801068ff <sys_mknod>:

int
sys_mknod(void)
{
801068ff:	55                   	push   %ebp
80106900:	89 e5                	mov    %esp,%ebp
80106902:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106905:	e8 b9 d2 ff ff       	call   80103bc3 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
8010690a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010690d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106911:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106918:	e8 c7 f4 ff ff       	call   80105de4 <argstr>
8010691d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106920:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106924:	78 5e                	js     80106984 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106926:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106929:	89 44 24 04          	mov    %eax,0x4(%esp)
8010692d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106934:	e8 1b f4 ff ff       	call   80105d54 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106939:	85 c0                	test   %eax,%eax
8010693b:	78 47                	js     80106984 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010693d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106940:	89 44 24 04          	mov    %eax,0x4(%esp)
80106944:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010694b:	e8 04 f4 ff ff       	call   80105d54 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106950:	85 c0                	test   %eax,%eax
80106952:	78 30                	js     80106984 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106954:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106957:	0f bf c8             	movswl %ax,%ecx
8010695a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010695d:	0f bf d0             	movswl %ax,%edx
80106960:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106963:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106967:	89 54 24 08          	mov    %edx,0x8(%esp)
8010696b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106972:	00 
80106973:	89 04 24             	mov    %eax,(%esp)
80106976:	e8 b7 fb ff ff       	call   80106532 <create>
8010697b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010697e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106982:	75 0c                	jne    80106990 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106984:	e8 be d2 ff ff       	call   80103c47 <end_op>
    return -1;
80106989:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010698e:	eb 15                	jmp    801069a5 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106990:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106993:	89 04 24             	mov    %eax,(%esp)
80106996:	e8 a8 b2 ff ff       	call   80101c43 <iunlockput>
  end_op();
8010699b:	e8 a7 d2 ff ff       	call   80103c47 <end_op>
  return 0;
801069a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069a5:	c9                   	leave  
801069a6:	c3                   	ret    

801069a7 <sys_chdir>:

int
sys_chdir(void)
{
801069a7:	55                   	push   %ebp
801069a8:	89 e5                	mov    %esp,%ebp
801069aa:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801069ad:	e8 11 d2 ff ff       	call   80103bc3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801069b2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801069b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801069b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069c0:	e8 1f f4 ff ff       	call   80105de4 <argstr>
801069c5:	85 c0                	test   %eax,%eax
801069c7:	78 14                	js     801069dd <sys_chdir+0x36>
801069c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069cc:	89 04 24             	mov    %eax,(%esp)
801069cf:	e8 96 bb ff ff       	call   8010256a <namei>
801069d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069d7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069db:	75 0c                	jne    801069e9 <sys_chdir+0x42>
    end_op();
801069dd:	e8 65 d2 ff ff       	call   80103c47 <end_op>
    return -1;
801069e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069e7:	eb 61                	jmp    80106a4a <sys_chdir+0xa3>
  }
  ilock(ip);
801069e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ec:	89 04 24             	mov    %eax,(%esp)
801069ef:	e8 c5 af ff ff       	call   801019b9 <ilock>
  if(ip->type != T_DIR){
801069f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069fb:	66 83 f8 01          	cmp    $0x1,%ax
801069ff:	74 17                	je     80106a18 <sys_chdir+0x71>
    iunlockput(ip);
80106a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a04:	89 04 24             	mov    %eax,(%esp)
80106a07:	e8 37 b2 ff ff       	call   80101c43 <iunlockput>
    end_op();
80106a0c:	e8 36 d2 ff ff       	call   80103c47 <end_op>
    return -1;
80106a11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a16:	eb 32                	jmp    80106a4a <sys_chdir+0xa3>
  }
  iunlock(ip);
80106a18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a1b:	89 04 24             	mov    %eax,(%esp)
80106a1e:	e8 ea b0 ff ff       	call   80101b0d <iunlock>
  iput(proc->cwd);
80106a23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a29:	8b 40 68             	mov    0x68(%eax),%eax
80106a2c:	89 04 24             	mov    %eax,(%esp)
80106a2f:	e8 3e b1 ff ff       	call   80101b72 <iput>
  end_op();
80106a34:	e8 0e d2 ff ff       	call   80103c47 <end_op>
  proc->cwd = ip;
80106a39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a3f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a42:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a45:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a4a:	c9                   	leave  
80106a4b:	c3                   	ret    

80106a4c <sys_exec>:

int
sys_exec(void)
{
80106a4c:	55                   	push   %ebp
80106a4d:	89 e5                	mov    %esp,%ebp
80106a4f:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a55:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a58:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a63:	e8 7c f3 ff ff       	call   80105de4 <argstr>
80106a68:	85 c0                	test   %eax,%eax
80106a6a:	78 1a                	js     80106a86 <sys_exec+0x3a>
80106a6c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a72:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a76:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a7d:	e8 d2 f2 ff ff       	call   80105d54 <argint>
80106a82:	85 c0                	test   %eax,%eax
80106a84:	79 0a                	jns    80106a90 <sys_exec+0x44>
    return -1;
80106a86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a8b:	e9 c8 00 00 00       	jmp    80106b58 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a90:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a97:	00 
80106a98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a9f:	00 
80106aa0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106aa6:	89 04 24             	mov    %eax,(%esp)
80106aa9:	e8 64 ef ff ff       	call   80105a12 <memset>
  for(i=0;; i++){
80106aae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab8:	83 f8 1f             	cmp    $0x1f,%eax
80106abb:	76 0a                	jbe    80106ac7 <sys_exec+0x7b>
      return -1;
80106abd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ac2:	e9 91 00 00 00       	jmp    80106b58 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106ac7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aca:	c1 e0 02             	shl    $0x2,%eax
80106acd:	89 c2                	mov    %eax,%edx
80106acf:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ad5:	01 c2                	add    %eax,%edx
80106ad7:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106add:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ae1:	89 14 24             	mov    %edx,(%esp)
80106ae4:	e8 cf f1 ff ff       	call   80105cb8 <fetchint>
80106ae9:	85 c0                	test   %eax,%eax
80106aeb:	79 07                	jns    80106af4 <sys_exec+0xa8>
      return -1;
80106aed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106af2:	eb 64                	jmp    80106b58 <sys_exec+0x10c>
    if(uarg == 0){
80106af4:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106afa:	85 c0                	test   %eax,%eax
80106afc:	75 26                	jne    80106b24 <sys_exec+0xd8>
      argv[i] = 0;
80106afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b01:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106b08:	00 00 00 00 
      break;
80106b0c:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106b0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b10:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106b16:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b1a:	89 04 24             	mov    %eax,(%esp)
80106b1d:	e8 e8 9f ff ff       	call   80100b0a <exec>
80106b22:	eb 34                	jmp    80106b58 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106b24:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b2a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b2d:	c1 e2 02             	shl    $0x2,%edx
80106b30:	01 c2                	add    %eax,%edx
80106b32:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b38:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b3c:	89 04 24             	mov    %eax,(%esp)
80106b3f:	e8 ae f1 ff ff       	call   80105cf2 <fetchstr>
80106b44:	85 c0                	test   %eax,%eax
80106b46:	79 07                	jns    80106b4f <sys_exec+0x103>
      return -1;
80106b48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b4d:	eb 09                	jmp    80106b58 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b4f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b53:	e9 5d ff ff ff       	jmp    80106ab5 <sys_exec+0x69>
  return exec(path, argv);
}
80106b58:	c9                   	leave  
80106b59:	c3                   	ret    

80106b5a <sys_pipe>:

int
sys_pipe(void)
{
80106b5a:	55                   	push   %ebp
80106b5b:	89 e5                	mov    %esp,%ebp
80106b5d:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b60:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b67:	00 
80106b68:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b76:	e8 07 f2 ff ff       	call   80105d82 <argptr>
80106b7b:	85 c0                	test   %eax,%eax
80106b7d:	79 0a                	jns    80106b89 <sys_pipe+0x2f>
    return -1;
80106b7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b84:	e9 9b 00 00 00       	jmp    80106c24 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b89:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b90:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b93:	89 04 24             	mov    %eax,(%esp)
80106b96:	e8 34 db ff ff       	call   801046cf <pipealloc>
80106b9b:	85 c0                	test   %eax,%eax
80106b9d:	79 07                	jns    80106ba6 <sys_pipe+0x4c>
    return -1;
80106b9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba4:	eb 7e                	jmp    80106c24 <sys_pipe+0xca>
  fd0 = -1;
80106ba6:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106bad:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bb0:	89 04 24             	mov    %eax,(%esp)
80106bb3:	e8 67 f3 ff ff       	call   80105f1f <fdalloc>
80106bb8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bbb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bbf:	78 14                	js     80106bd5 <sys_pipe+0x7b>
80106bc1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bc4:	89 04 24             	mov    %eax,(%esp)
80106bc7:	e8 53 f3 ff ff       	call   80105f1f <fdalloc>
80106bcc:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bcf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bd3:	79 37                	jns    80106c0c <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bd5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bd9:	78 14                	js     80106bef <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bdb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106be1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106be4:	83 c2 08             	add    $0x8,%edx
80106be7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106bee:	00 
    fileclose(rf);
80106bef:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bf2:	89 04 24             	mov    %eax,(%esp)
80106bf5:	e8 d4 a4 ff ff       	call   801010ce <fileclose>
    fileclose(wf);
80106bfa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bfd:	89 04 24             	mov    %eax,(%esp)
80106c00:	e8 c9 a4 ff ff       	call   801010ce <fileclose>
    return -1;
80106c05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c0a:	eb 18                	jmp    80106c24 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106c0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c0f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c12:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106c14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c17:	8d 50 04             	lea    0x4(%eax),%edx
80106c1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c1d:	89 02                	mov    %eax,(%edx)
  return 0;
80106c1f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c24:	c9                   	leave  
80106c25:	c3                   	ret    

80106c26 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c26:	55                   	push   %ebp
80106c27:	89 e5                	mov    %esp,%ebp
80106c29:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c2c:	e8 74 e2 ff ff       	call   80104ea5 <fork>
}
80106c31:	c9                   	leave  
80106c32:	c3                   	ret    

80106c33 <sys_exit>:

int
sys_exit(void)
{
80106c33:	55                   	push   %ebp
80106c34:	89 e5                	mov    %esp,%ebp
80106c36:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c39:	e8 23 e4 ff ff       	call   80105061 <exit>
  return 0;  // not reached
80106c3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c43:	c9                   	leave  
80106c44:	c3                   	ret    

80106c45 <sys_wait>:

int
sys_wait(void)
{
80106c45:	55                   	push   %ebp
80106c46:	89 e5                	mov    %esp,%ebp
80106c48:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c4b:	e8 49 e5 ff ff       	call   80105199 <wait>
}
80106c50:	c9                   	leave  
80106c51:	c3                   	ret    

80106c52 <sys_kill>:

int
sys_kill(void)
{
80106c52:	55                   	push   %ebp
80106c53:	89 e5                	mov    %esp,%ebp
80106c55:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c58:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c66:	e8 e9 f0 ff ff       	call   80105d54 <argint>
80106c6b:	85 c0                	test   %eax,%eax
80106c6d:	79 07                	jns    80106c76 <sys_kill+0x24>
    return -1;
80106c6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c74:	eb 0b                	jmp    80106c81 <sys_kill+0x2f>
  return kill(pid);
80106c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c79:	89 04 24             	mov    %eax,(%esp)
80106c7c:	e8 f6 e8 ff ff       	call   80105577 <kill>
}
80106c81:	c9                   	leave  
80106c82:	c3                   	ret    

80106c83 <sys_getpid>:

int
sys_getpid(void)
{
80106c83:	55                   	push   %ebp
80106c84:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c86:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c8c:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c8f:	5d                   	pop    %ebp
80106c90:	c3                   	ret    

80106c91 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c91:	55                   	push   %ebp
80106c92:	89 e5                	mov    %esp,%ebp
80106c94:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c97:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ca5:	e8 aa f0 ff ff       	call   80105d54 <argint>
80106caa:	85 c0                	test   %eax,%eax
80106cac:	79 07                	jns    80106cb5 <sys_sbrk+0x24>
    return -1;
80106cae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cb3:	eb 39                	jmp    80106cee <sys_sbrk+0x5d>
  addr = proc->sz;
80106cb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cbb:	8b 00                	mov    (%eax),%eax
80106cbd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106cc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cc3:	89 04 24             	mov    %eax,(%esp)
80106cc6:	e8 1f e1 ff ff       	call   80104dea <growproc>
80106ccb:	85 c0                	test   %eax,%eax
80106ccd:	79 07                	jns    80106cd6 <sys_sbrk+0x45>
    return -1;
80106ccf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cd4:	eb 18                	jmp    80106cee <sys_sbrk+0x5d>
  cprintf("num of pages in system:%d\n",countPages());
80106cd6:	e8 cb c5 ff ff       	call   801032a6 <countPages>
80106cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cdf:	c7 04 24 7f a1 10 80 	movl   $0x8010a17f,(%esp)
80106ce6:	e8 b5 96 ff ff       	call   801003a0 <cprintf>
  return addr;
80106ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cee:	c9                   	leave  
80106cef:	c3                   	ret    

80106cf0 <sys_sleep>:

int
sys_sleep(void)
{
80106cf0:	55                   	push   %ebp
80106cf1:	89 e5                	mov    %esp,%ebp
80106cf3:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106cf6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cf9:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cfd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d04:	e8 4b f0 ff ff       	call   80105d54 <argint>
80106d09:	85 c0                	test   %eax,%eax
80106d0b:	79 07                	jns    80106d14 <sys_sleep+0x24>
    return -1;
80106d0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d12:	eb 6c                	jmp    80106d80 <sys_sleep+0x90>
  acquire(&tickslock);
80106d14:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d1b:	e8 9e ea ff ff       	call   801057be <acquire>
  ticks0 = ticks;
80106d20:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d25:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106d28:	eb 34                	jmp    80106d5e <sys_sleep+0x6e>
    if(proc->killed){
80106d2a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d30:	8b 40 24             	mov    0x24(%eax),%eax
80106d33:	85 c0                	test   %eax,%eax
80106d35:	74 13                	je     80106d4a <sys_sleep+0x5a>
      release(&tickslock);
80106d37:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d3e:	e8 dd ea ff ff       	call   80105820 <release>
      return -1;
80106d43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d48:	eb 36                	jmp    80106d80 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d4a:	c7 44 24 04 c0 04 12 	movl   $0x801204c0,0x4(%esp)
80106d51:	80 
80106d52:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80106d59:	e8 12 e7 ff ff       	call   80105470 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d5e:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d63:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d66:	89 c2                	mov    %eax,%edx
80106d68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d6b:	39 c2                	cmp    %eax,%edx
80106d6d:	72 bb                	jb     80106d2a <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d6f:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d76:	e8 a5 ea ff ff       	call   80105820 <release>
  return 0;
80106d7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d80:	c9                   	leave  
80106d81:	c3                   	ret    

80106d82 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d82:	55                   	push   %ebp
80106d83:	89 e5                	mov    %esp,%ebp
80106d85:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d88:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d8f:	e8 2a ea ff ff       	call   801057be <acquire>
  xticks = ticks;
80106d94:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d99:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d9c:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106da3:	e8 78 ea ff ff       	call   80105820 <release>
  return xticks;
80106da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dab:	c9                   	leave  
80106dac:	c3                   	ret    

80106dad <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106dad:	55                   	push   %ebp
80106dae:	89 e5                	mov    %esp,%ebp
80106db0:	83 ec 08             	sub    $0x8,%esp
80106db3:	8b 55 08             	mov    0x8(%ebp),%edx
80106db6:	8b 45 0c             	mov    0xc(%ebp),%eax
80106db9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106dbd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106dc0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106dc4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106dc8:	ee                   	out    %al,(%dx)
}
80106dc9:	c9                   	leave  
80106dca:	c3                   	ret    

80106dcb <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106dcb:	55                   	push   %ebp
80106dcc:	89 e5                	mov    %esp,%ebp
80106dce:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106dd1:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106dd8:	00 
80106dd9:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106de0:	e8 c8 ff ff ff       	call   80106dad <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106de5:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106dec:	00 
80106ded:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106df4:	e8 b4 ff ff ff       	call   80106dad <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106df9:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106e00:	00 
80106e01:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106e08:	e8 a0 ff ff ff       	call   80106dad <outb>
  picenable(IRQ_TIMER);
80106e0d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e14:	e8 49 d7 ff ff       	call   80104562 <picenable>
}
80106e19:	c9                   	leave  
80106e1a:	c3                   	ret    

80106e1b <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106e1b:	1e                   	push   %ds
  pushl %es
80106e1c:	06                   	push   %es
  pushl %fs
80106e1d:	0f a0                	push   %fs
  pushl %gs
80106e1f:	0f a8                	push   %gs
  pushal
80106e21:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106e22:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106e26:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e28:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e2a:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e2e:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e30:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e32:	54                   	push   %esp
  call trap
80106e33:	e8 d8 01 00 00       	call   80107010 <trap>
  addl $4, %esp
80106e38:	83 c4 04             	add    $0x4,%esp

80106e3b <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e3b:	61                   	popa   
  popl %gs
80106e3c:	0f a9                	pop    %gs
  popl %fs
80106e3e:	0f a1                	pop    %fs
  popl %es
80106e40:	07                   	pop    %es
  popl %ds
80106e41:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e42:	83 c4 08             	add    $0x8,%esp
  iret
80106e45:	cf                   	iret   

80106e46 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e46:	55                   	push   %ebp
80106e47:	89 e5                	mov    %esp,%ebp
80106e49:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e4c:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e4f:	83 e8 01             	sub    $0x1,%eax
80106e52:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e56:	8b 45 08             	mov    0x8(%ebp),%eax
80106e59:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e5d:	8b 45 08             	mov    0x8(%ebp),%eax
80106e60:	c1 e8 10             	shr    $0x10,%eax
80106e63:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e67:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e6a:	0f 01 18             	lidtl  (%eax)
}
80106e6d:	c9                   	leave  
80106e6e:	c3                   	ret    

80106e6f <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e6f:	55                   	push   %ebp
80106e70:	89 e5                	mov    %esp,%ebp
80106e72:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e75:	0f 20 d0             	mov    %cr2,%eax
80106e78:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e7b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e7e:	c9                   	leave  
80106e7f:	c3                   	ret    

80106e80 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e80:	55                   	push   %ebp
80106e81:	89 e5                	mov    %esp,%ebp
80106e83:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e86:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e8d:	e9 c3 00 00 00       	jmp    80106f55 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e95:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106e9c:	89 c2                	mov    %eax,%edx
80106e9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea1:	66 89 14 c5 00 05 12 	mov    %dx,-0x7fedfb00(,%eax,8)
80106ea8:	80 
80106ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eac:	66 c7 04 c5 02 05 12 	movw   $0x8,-0x7fedfafe(,%eax,8)
80106eb3:	80 08 00 
80106eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb9:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106ec0:	80 
80106ec1:	83 e2 e0             	and    $0xffffffe0,%edx
80106ec4:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ece:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106ed5:	80 
80106ed6:	83 e2 1f             	and    $0x1f,%edx
80106ed9:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ee3:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106eea:	80 
80106eeb:	83 e2 f0             	and    $0xfffffff0,%edx
80106eee:	83 ca 0e             	or     $0xe,%edx
80106ef1:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106ef8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efb:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f02:	80 
80106f03:	83 e2 ef             	and    $0xffffffef,%edx
80106f06:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f10:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f17:	80 
80106f18:	83 e2 9f             	and    $0xffffff9f,%edx
80106f1b:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f25:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f2c:	80 
80106f2d:	83 ca 80             	or     $0xffffff80,%edx
80106f30:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f3a:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f41:	c1 e8 10             	shr    $0x10,%eax
80106f44:	89 c2                	mov    %eax,%edx
80106f46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f49:	66 89 14 c5 06 05 12 	mov    %dx,-0x7fedfafa(,%eax,8)
80106f50:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f51:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f55:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f5c:	0f 8e 30 ff ff ff    	jle    80106e92 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f62:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f67:	66 a3 00 07 12 80    	mov    %ax,0x80120700
80106f6d:	66 c7 05 02 07 12 80 	movw   $0x8,0x80120702
80106f74:	08 00 
80106f76:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f7d:	83 e0 e0             	and    $0xffffffe0,%eax
80106f80:	a2 04 07 12 80       	mov    %al,0x80120704
80106f85:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f8c:	83 e0 1f             	and    $0x1f,%eax
80106f8f:	a2 04 07 12 80       	mov    %al,0x80120704
80106f94:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f9b:	83 c8 0f             	or     $0xf,%eax
80106f9e:	a2 05 07 12 80       	mov    %al,0x80120705
80106fa3:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106faa:	83 e0 ef             	and    $0xffffffef,%eax
80106fad:	a2 05 07 12 80       	mov    %al,0x80120705
80106fb2:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106fb9:	83 c8 60             	or     $0x60,%eax
80106fbc:	a2 05 07 12 80       	mov    %al,0x80120705
80106fc1:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106fc8:	83 c8 80             	or     $0xffffff80,%eax
80106fcb:	a2 05 07 12 80       	mov    %al,0x80120705
80106fd0:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106fd5:	c1 e8 10             	shr    $0x10,%eax
80106fd8:	66 a3 06 07 12 80    	mov    %ax,0x80120706
  
  initlock(&tickslock, "time");
80106fde:	c7 44 24 04 9c a1 10 	movl   $0x8010a19c,0x4(%esp)
80106fe5:	80 
80106fe6:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106fed:	e8 ab e7 ff ff       	call   8010579d <initlock>
}
80106ff2:	c9                   	leave  
80106ff3:	c3                   	ret    

80106ff4 <idtinit>:

void
idtinit(void)
{
80106ff4:	55                   	push   %ebp
80106ff5:	89 e5                	mov    %esp,%ebp
80106ff7:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106ffa:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107001:	00 
80107002:	c7 04 24 00 05 12 80 	movl   $0x80120500,(%esp)
80107009:	e8 38 fe ff ff       	call   80106e46 <lidt>
}
8010700e:	c9                   	leave  
8010700f:	c3                   	ret    

80107010 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107010:	55                   	push   %ebp
80107011:	89 e5                	mov    %esp,%ebp
80107013:	57                   	push   %edi
80107014:	56                   	push   %esi
80107015:	53                   	push   %ebx
80107016:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107019:	8b 45 08             	mov    0x8(%ebp),%eax
8010701c:	8b 40 30             	mov    0x30(%eax),%eax
8010701f:	83 f8 40             	cmp    $0x40,%eax
80107022:	75 3f                	jne    80107063 <trap+0x53>
    if(proc->killed)
80107024:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010702a:	8b 40 24             	mov    0x24(%eax),%eax
8010702d:	85 c0                	test   %eax,%eax
8010702f:	74 05                	je     80107036 <trap+0x26>
      exit();
80107031:	e8 2b e0 ff ff       	call   80105061 <exit>
    proc->tf = tf;
80107036:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010703c:	8b 55 08             	mov    0x8(%ebp),%edx
8010703f:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107042:	e8 d4 ed ff ff       	call   80105e1b <syscall>
    if(proc->killed)
80107047:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010704d:	8b 40 24             	mov    0x24(%eax),%eax
80107050:	85 c0                	test   %eax,%eax
80107052:	74 0a                	je     8010705e <trap+0x4e>
      exit();
80107054:	e8 08 e0 ff ff       	call   80105061 <exit>
    return;
80107059:	e9 c5 02 00 00       	jmp    80107323 <trap+0x313>
8010705e:	e9 c0 02 00 00       	jmp    80107323 <trap+0x313>
  }
  switch(tf->trapno){
80107063:	8b 45 08             	mov    0x8(%ebp),%eax
80107066:	8b 40 30             	mov    0x30(%eax),%eax
80107069:	83 e8 0e             	sub    $0xe,%eax
8010706c:	83 f8 31             	cmp    $0x31,%eax
8010706f:	0f 87 54 01 00 00    	ja     801071c9 <trap+0x1b9>
80107075:	8b 04 85 9c a2 10 80 	mov    -0x7fef5d64(,%eax,4),%eax
8010707c:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010707e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107084:	0f b6 00             	movzbl (%eax),%eax
80107087:	84 c0                	test   %al,%al
80107089:	75 31                	jne    801070bc <trap+0xac>
      acquire(&tickslock);
8010708b:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107092:	e8 27 e7 ff ff       	call   801057be <acquire>
      ticks++;
80107097:	a1 00 0d 12 80       	mov    0x80120d00,%eax
8010709c:	83 c0 01             	add    $0x1,%eax
8010709f:	a3 00 0d 12 80       	mov    %eax,0x80120d00
      wakeup(&ticks);
801070a4:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
801070ab:	e8 9c e4 ff ff       	call   8010554c <wakeup>
      release(&tickslock);
801070b0:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
801070b7:	e8 64 e7 ff ff       	call   80105820 <release>
    }
    lapiceoi();
801070bc:	e8 cc c5 ff ff       	call   8010368d <lapiceoi>
    break;
801070c1:	e9 d9 01 00 00       	jmp    8010729f <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801070c6:	e8 30 bd ff ff       	call   80102dfb <ideintr>
    lapiceoi();
801070cb:	e8 bd c5 ff ff       	call   8010368d <lapiceoi>
    break;
801070d0:	e9 ca 01 00 00       	jmp    8010729f <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070d5:	e8 82 c3 ff ff       	call   8010345c <kbdintr>
    lapiceoi();
801070da:	e8 ae c5 ff ff       	call   8010368d <lapiceoi>
    break;
801070df:	e9 bb 01 00 00       	jmp    8010729f <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070e4:	e8 2f 04 00 00       	call   80107518 <uartintr>
    lapiceoi();
801070e9:	e8 9f c5 ff ff       	call   8010368d <lapiceoi>
    break;
801070ee:	e9 ac 01 00 00       	jmp    8010729f <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070f3:	8b 45 08             	mov    0x8(%ebp),%eax
801070f6:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070f9:	8b 45 08             	mov    0x8(%ebp),%eax
801070fc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107100:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107103:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107109:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010710c:	0f b6 c0             	movzbl %al,%eax
8010710f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107113:	89 54 24 08          	mov    %edx,0x8(%esp)
80107117:	89 44 24 04          	mov    %eax,0x4(%esp)
8010711b:	c7 04 24 a4 a1 10 80 	movl   $0x8010a1a4,(%esp)
80107122:	e8 79 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107127:	e8 61 c5 ff ff       	call   8010368d <lapiceoi>
    break;
8010712c:	e9 6e 01 00 00       	jmp    8010729f <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
80107131:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107137:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
8010713d:	83 c2 01             	add    $0x1,%edx
80107140:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
80107146:	e8 24 fd ff ff       	call   80106e6f <rcr2>
8010714b:	05 ff 0f 00 00       	add    $0xfff,%eax
80107150:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107155:	89 c6                	mov    %eax,%esi
80107157:	e8 13 fd ff ff       	call   80106e6f <rcr2>
8010715c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107161:	89 c3                	mov    %eax,%ebx
80107163:	e8 07 fd ff ff       	call   80106e6f <rcr2>
80107168:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010716f:	8b 52 10             	mov    0x10(%edx),%edx
80107172:	89 74 24 10          	mov    %esi,0x10(%esp)
80107176:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010717a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010717e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107182:	c7 04 24 c8 a1 10 80 	movl   $0x8010a1c8,(%esp)
80107189:	e8 12 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
8010718e:	e8 dc fc ff ff       	call   80106e6f <rcr2>
80107193:	89 04 24             	mov    %eax,(%esp)
80107196:	e8 b4 21 00 00       	call   8010934f <existOnDisc>
8010719b:	85 c0                	test   %eax,%eax
8010719d:	74 2a                	je     801071c9 <trap+0x1b9>
      cprintf("found on disk, recovering\n");
8010719f:	c7 04 24 f7 a1 10 80 	movl   $0x8010a1f7,(%esp)
801071a6:	e8 f5 91 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
801071ab:	e8 bf fc ff ff       	call   80106e6f <rcr2>
801071b0:	89 04 24             	mov    %eax,(%esp)
801071b3:	e8 83 22 00 00       	call   8010943b <fixPage>
      cprintf("recovered!\n");
801071b8:	c7 04 24 12 a2 10 80 	movl   $0x8010a212,(%esp)
801071bf:	e8 dc 91 ff ff       	call   801003a0 <cprintf>
      break;
801071c4:	e9 d6 00 00 00       	jmp    8010729f <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801071c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071cf:	85 c0                	test   %eax,%eax
801071d1:	74 11                	je     801071e4 <trap+0x1d4>
801071d3:	8b 45 08             	mov    0x8(%ebp),%eax
801071d6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071da:	0f b7 c0             	movzwl %ax,%eax
801071dd:	83 e0 03             	and    $0x3,%eax
801071e0:	85 c0                	test   %eax,%eax
801071e2:	75 46                	jne    8010722a <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071e4:	e8 86 fc ff ff       	call   80106e6f <rcr2>
801071e9:	8b 55 08             	mov    0x8(%ebp),%edx
801071ec:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801071ef:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801071f6:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071f9:	0f b6 ca             	movzbl %dl,%ecx
801071fc:	8b 55 08             	mov    0x8(%ebp),%edx
801071ff:	8b 52 30             	mov    0x30(%edx),%edx
80107202:	89 44 24 10          	mov    %eax,0x10(%esp)
80107206:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010720a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010720e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107212:	c7 04 24 20 a2 10 80 	movl   $0x8010a220,(%esp)
80107219:	e8 82 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010721e:	c7 04 24 52 a2 10 80 	movl   $0x8010a252,(%esp)
80107225:	e8 10 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010722a:	e8 40 fc ff ff       	call   80106e6f <rcr2>
8010722f:	89 c2                	mov    %eax,%edx
80107231:	8b 45 08             	mov    0x8(%ebp),%eax
80107234:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107237:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010723d:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107240:	0f b6 f0             	movzbl %al,%esi
80107243:	8b 45 08             	mov    0x8(%ebp),%eax
80107246:	8b 58 34             	mov    0x34(%eax),%ebx
80107249:	8b 45 08             	mov    0x8(%ebp),%eax
8010724c:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010724f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107255:	83 c0 6c             	add    $0x6c,%eax
80107258:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010725b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107261:	8b 40 10             	mov    0x10(%eax),%eax
80107264:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107268:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010726c:	89 74 24 14          	mov    %esi,0x14(%esp)
80107270:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107274:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107278:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010727b:	89 7c 24 08          	mov    %edi,0x8(%esp)
8010727f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107283:	c7 04 24 58 a2 10 80 	movl   $0x8010a258,(%esp)
8010728a:	e8 11 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010728f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107295:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010729c:	eb 01                	jmp    8010729f <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010729e:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010729f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072a5:	85 c0                	test   %eax,%eax
801072a7:	74 24                	je     801072cd <trap+0x2bd>
801072a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072af:	8b 40 24             	mov    0x24(%eax),%eax
801072b2:	85 c0                	test   %eax,%eax
801072b4:	74 17                	je     801072cd <trap+0x2bd>
801072b6:	8b 45 08             	mov    0x8(%ebp),%eax
801072b9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072bd:	0f b7 c0             	movzwl %ax,%eax
801072c0:	83 e0 03             	and    $0x3,%eax
801072c3:	83 f8 03             	cmp    $0x3,%eax
801072c6:	75 05                	jne    801072cd <trap+0x2bd>
    exit();
801072c8:	e8 94 dd ff ff       	call   80105061 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
801072cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072d3:	85 c0                	test   %eax,%eax
801072d5:	74 1e                	je     801072f5 <trap+0x2e5>
801072d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072dd:	8b 40 0c             	mov    0xc(%eax),%eax
801072e0:	83 f8 04             	cmp    $0x4,%eax
801072e3:	75 10                	jne    801072f5 <trap+0x2e5>
801072e5:	8b 45 08             	mov    0x8(%ebp),%eax
801072e8:	8b 40 30             	mov    0x30(%eax),%eax
801072eb:	83 f8 20             	cmp    $0x20,%eax
801072ee:	75 05                	jne    801072f5 <trap+0x2e5>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4) updateAge(proc); //TODO: maybe need to get proc?
    yield();
801072f0:	e8 0a e1 ff ff       	call   801053ff <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072fb:	85 c0                	test   %eax,%eax
801072fd:	74 24                	je     80107323 <trap+0x313>
801072ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107305:	8b 40 24             	mov    0x24(%eax),%eax
80107308:	85 c0                	test   %eax,%eax
8010730a:	74 17                	je     80107323 <trap+0x313>
8010730c:	8b 45 08             	mov    0x8(%ebp),%eax
8010730f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107313:	0f b7 c0             	movzwl %ax,%eax
80107316:	83 e0 03             	and    $0x3,%eax
80107319:	83 f8 03             	cmp    $0x3,%eax
8010731c:	75 05                	jne    80107323 <trap+0x313>
    exit();
8010731e:	e8 3e dd ff ff       	call   80105061 <exit>
}
80107323:	83 c4 3c             	add    $0x3c,%esp
80107326:	5b                   	pop    %ebx
80107327:	5e                   	pop    %esi
80107328:	5f                   	pop    %edi
80107329:	5d                   	pop    %ebp
8010732a:	c3                   	ret    

8010732b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010732b:	55                   	push   %ebp
8010732c:	89 e5                	mov    %esp,%ebp
8010732e:	83 ec 14             	sub    $0x14,%esp
80107331:	8b 45 08             	mov    0x8(%ebp),%eax
80107334:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107338:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010733c:	89 c2                	mov    %eax,%edx
8010733e:	ec                   	in     (%dx),%al
8010733f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107342:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107346:	c9                   	leave  
80107347:	c3                   	ret    

80107348 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107348:	55                   	push   %ebp
80107349:	89 e5                	mov    %esp,%ebp
8010734b:	83 ec 08             	sub    $0x8,%esp
8010734e:	8b 55 08             	mov    0x8(%ebp),%edx
80107351:	8b 45 0c             	mov    0xc(%ebp),%eax
80107354:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107358:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010735b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010735f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107363:	ee                   	out    %al,(%dx)
}
80107364:	c9                   	leave  
80107365:	c3                   	ret    

80107366 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107366:	55                   	push   %ebp
80107367:	89 e5                	mov    %esp,%ebp
80107369:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010736c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107373:	00 
80107374:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010737b:	e8 c8 ff ff ff       	call   80107348 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107380:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107387:	00 
80107388:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010738f:	e8 b4 ff ff ff       	call   80107348 <outb>
  outb(COM1+0, 115200/9600);
80107394:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010739b:	00 
8010739c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801073a3:	e8 a0 ff ff ff       	call   80107348 <outb>
  outb(COM1+1, 0);
801073a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073af:	00 
801073b0:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073b7:	e8 8c ff ff ff       	call   80107348 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801073bc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801073c3:	00 
801073c4:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073cb:	e8 78 ff ff ff       	call   80107348 <outb>
  outb(COM1+4, 0);
801073d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073d7:	00 
801073d8:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801073df:	e8 64 ff ff ff       	call   80107348 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801073e4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801073eb:	00 
801073ec:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073f3:	e8 50 ff ff ff       	call   80107348 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801073f8:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073ff:	e8 27 ff ff ff       	call   8010732b <inb>
80107404:	3c ff                	cmp    $0xff,%al
80107406:	75 02                	jne    8010740a <uartinit+0xa4>
    return;
80107408:	eb 6a                	jmp    80107474 <uartinit+0x10e>
  uart = 1;
8010740a:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
80107411:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107414:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010741b:	e8 0b ff ff ff       	call   8010732b <inb>
  inb(COM1+0);
80107420:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107427:	e8 ff fe ff ff       	call   8010732b <inb>
  picenable(IRQ_COM1);
8010742c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107433:	e8 2a d1 ff ff       	call   80104562 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107438:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010743f:	00 
80107440:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107447:	e8 2e bc ff ff       	call   8010307a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010744c:	c7 45 f4 64 a3 10 80 	movl   $0x8010a364,-0xc(%ebp)
80107453:	eb 15                	jmp    8010746a <uartinit+0x104>
    uartputc(*p);
80107455:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107458:	0f b6 00             	movzbl (%eax),%eax
8010745b:	0f be c0             	movsbl %al,%eax
8010745e:	89 04 24             	mov    %eax,(%esp)
80107461:	e8 10 00 00 00       	call   80107476 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107466:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010746a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010746d:	0f b6 00             	movzbl (%eax),%eax
80107470:	84 c0                	test   %al,%al
80107472:	75 e1                	jne    80107455 <uartinit+0xef>
    uartputc(*p);
}
80107474:	c9                   	leave  
80107475:	c3                   	ret    

80107476 <uartputc>:

void
uartputc(int c)
{
80107476:	55                   	push   %ebp
80107477:	89 e5                	mov    %esp,%ebp
80107479:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010747c:	a1 50 d6 10 80       	mov    0x8010d650,%eax
80107481:	85 c0                	test   %eax,%eax
80107483:	75 02                	jne    80107487 <uartputc+0x11>
    return;
80107485:	eb 4b                	jmp    801074d2 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107487:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010748e:	eb 10                	jmp    801074a0 <uartputc+0x2a>
    microdelay(10);
80107490:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107497:	e8 16 c2 ff ff       	call   801036b2 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010749c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801074a0:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801074a4:	7f 16                	jg     801074bc <uartputc+0x46>
801074a6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074ad:	e8 79 fe ff ff       	call   8010732b <inb>
801074b2:	0f b6 c0             	movzbl %al,%eax
801074b5:	83 e0 20             	and    $0x20,%eax
801074b8:	85 c0                	test   %eax,%eax
801074ba:	74 d4                	je     80107490 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801074bc:	8b 45 08             	mov    0x8(%ebp),%eax
801074bf:	0f b6 c0             	movzbl %al,%eax
801074c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801074c6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074cd:	e8 76 fe ff ff       	call   80107348 <outb>
}
801074d2:	c9                   	leave  
801074d3:	c3                   	ret    

801074d4 <uartgetc>:

static int
uartgetc(void)
{
801074d4:	55                   	push   %ebp
801074d5:	89 e5                	mov    %esp,%ebp
801074d7:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801074da:	a1 50 d6 10 80       	mov    0x8010d650,%eax
801074df:	85 c0                	test   %eax,%eax
801074e1:	75 07                	jne    801074ea <uartgetc+0x16>
    return -1;
801074e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074e8:	eb 2c                	jmp    80107516 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801074ea:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074f1:	e8 35 fe ff ff       	call   8010732b <inb>
801074f6:	0f b6 c0             	movzbl %al,%eax
801074f9:	83 e0 01             	and    $0x1,%eax
801074fc:	85 c0                	test   %eax,%eax
801074fe:	75 07                	jne    80107507 <uartgetc+0x33>
    return -1;
80107500:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107505:	eb 0f                	jmp    80107516 <uartgetc+0x42>
  return inb(COM1+0);
80107507:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010750e:	e8 18 fe ff ff       	call   8010732b <inb>
80107513:	0f b6 c0             	movzbl %al,%eax
}
80107516:	c9                   	leave  
80107517:	c3                   	ret    

80107518 <uartintr>:

void
uartintr(void)
{
80107518:	55                   	push   %ebp
80107519:	89 e5                	mov    %esp,%ebp
8010751b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010751e:	c7 04 24 d4 74 10 80 	movl   $0x801074d4,(%esp)
80107525:	e8 9e 92 ff ff       	call   801007c8 <consoleintr>
}
8010752a:	c9                   	leave  
8010752b:	c3                   	ret    

8010752c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010752c:	6a 00                	push   $0x0
  pushl $0
8010752e:	6a 00                	push   $0x0
  jmp alltraps
80107530:	e9 e6 f8 ff ff       	jmp    80106e1b <alltraps>

80107535 <vector1>:
.globl vector1
vector1:
  pushl $0
80107535:	6a 00                	push   $0x0
  pushl $1
80107537:	6a 01                	push   $0x1
  jmp alltraps
80107539:	e9 dd f8 ff ff       	jmp    80106e1b <alltraps>

8010753e <vector2>:
.globl vector2
vector2:
  pushl $0
8010753e:	6a 00                	push   $0x0
  pushl $2
80107540:	6a 02                	push   $0x2
  jmp alltraps
80107542:	e9 d4 f8 ff ff       	jmp    80106e1b <alltraps>

80107547 <vector3>:
.globl vector3
vector3:
  pushl $0
80107547:	6a 00                	push   $0x0
  pushl $3
80107549:	6a 03                	push   $0x3
  jmp alltraps
8010754b:	e9 cb f8 ff ff       	jmp    80106e1b <alltraps>

80107550 <vector4>:
.globl vector4
vector4:
  pushl $0
80107550:	6a 00                	push   $0x0
  pushl $4
80107552:	6a 04                	push   $0x4
  jmp alltraps
80107554:	e9 c2 f8 ff ff       	jmp    80106e1b <alltraps>

80107559 <vector5>:
.globl vector5
vector5:
  pushl $0
80107559:	6a 00                	push   $0x0
  pushl $5
8010755b:	6a 05                	push   $0x5
  jmp alltraps
8010755d:	e9 b9 f8 ff ff       	jmp    80106e1b <alltraps>

80107562 <vector6>:
.globl vector6
vector6:
  pushl $0
80107562:	6a 00                	push   $0x0
  pushl $6
80107564:	6a 06                	push   $0x6
  jmp alltraps
80107566:	e9 b0 f8 ff ff       	jmp    80106e1b <alltraps>

8010756b <vector7>:
.globl vector7
vector7:
  pushl $0
8010756b:	6a 00                	push   $0x0
  pushl $7
8010756d:	6a 07                	push   $0x7
  jmp alltraps
8010756f:	e9 a7 f8 ff ff       	jmp    80106e1b <alltraps>

80107574 <vector8>:
.globl vector8
vector8:
  pushl $8
80107574:	6a 08                	push   $0x8
  jmp alltraps
80107576:	e9 a0 f8 ff ff       	jmp    80106e1b <alltraps>

8010757b <vector9>:
.globl vector9
vector9:
  pushl $0
8010757b:	6a 00                	push   $0x0
  pushl $9
8010757d:	6a 09                	push   $0x9
  jmp alltraps
8010757f:	e9 97 f8 ff ff       	jmp    80106e1b <alltraps>

80107584 <vector10>:
.globl vector10
vector10:
  pushl $10
80107584:	6a 0a                	push   $0xa
  jmp alltraps
80107586:	e9 90 f8 ff ff       	jmp    80106e1b <alltraps>

8010758b <vector11>:
.globl vector11
vector11:
  pushl $11
8010758b:	6a 0b                	push   $0xb
  jmp alltraps
8010758d:	e9 89 f8 ff ff       	jmp    80106e1b <alltraps>

80107592 <vector12>:
.globl vector12
vector12:
  pushl $12
80107592:	6a 0c                	push   $0xc
  jmp alltraps
80107594:	e9 82 f8 ff ff       	jmp    80106e1b <alltraps>

80107599 <vector13>:
.globl vector13
vector13:
  pushl $13
80107599:	6a 0d                	push   $0xd
  jmp alltraps
8010759b:	e9 7b f8 ff ff       	jmp    80106e1b <alltraps>

801075a0 <vector14>:
.globl vector14
vector14:
  pushl $14
801075a0:	6a 0e                	push   $0xe
  jmp alltraps
801075a2:	e9 74 f8 ff ff       	jmp    80106e1b <alltraps>

801075a7 <vector15>:
.globl vector15
vector15:
  pushl $0
801075a7:	6a 00                	push   $0x0
  pushl $15
801075a9:	6a 0f                	push   $0xf
  jmp alltraps
801075ab:	e9 6b f8 ff ff       	jmp    80106e1b <alltraps>

801075b0 <vector16>:
.globl vector16
vector16:
  pushl $0
801075b0:	6a 00                	push   $0x0
  pushl $16
801075b2:	6a 10                	push   $0x10
  jmp alltraps
801075b4:	e9 62 f8 ff ff       	jmp    80106e1b <alltraps>

801075b9 <vector17>:
.globl vector17
vector17:
  pushl $17
801075b9:	6a 11                	push   $0x11
  jmp alltraps
801075bb:	e9 5b f8 ff ff       	jmp    80106e1b <alltraps>

801075c0 <vector18>:
.globl vector18
vector18:
  pushl $0
801075c0:	6a 00                	push   $0x0
  pushl $18
801075c2:	6a 12                	push   $0x12
  jmp alltraps
801075c4:	e9 52 f8 ff ff       	jmp    80106e1b <alltraps>

801075c9 <vector19>:
.globl vector19
vector19:
  pushl $0
801075c9:	6a 00                	push   $0x0
  pushl $19
801075cb:	6a 13                	push   $0x13
  jmp alltraps
801075cd:	e9 49 f8 ff ff       	jmp    80106e1b <alltraps>

801075d2 <vector20>:
.globl vector20
vector20:
  pushl $0
801075d2:	6a 00                	push   $0x0
  pushl $20
801075d4:	6a 14                	push   $0x14
  jmp alltraps
801075d6:	e9 40 f8 ff ff       	jmp    80106e1b <alltraps>

801075db <vector21>:
.globl vector21
vector21:
  pushl $0
801075db:	6a 00                	push   $0x0
  pushl $21
801075dd:	6a 15                	push   $0x15
  jmp alltraps
801075df:	e9 37 f8 ff ff       	jmp    80106e1b <alltraps>

801075e4 <vector22>:
.globl vector22
vector22:
  pushl $0
801075e4:	6a 00                	push   $0x0
  pushl $22
801075e6:	6a 16                	push   $0x16
  jmp alltraps
801075e8:	e9 2e f8 ff ff       	jmp    80106e1b <alltraps>

801075ed <vector23>:
.globl vector23
vector23:
  pushl $0
801075ed:	6a 00                	push   $0x0
  pushl $23
801075ef:	6a 17                	push   $0x17
  jmp alltraps
801075f1:	e9 25 f8 ff ff       	jmp    80106e1b <alltraps>

801075f6 <vector24>:
.globl vector24
vector24:
  pushl $0
801075f6:	6a 00                	push   $0x0
  pushl $24
801075f8:	6a 18                	push   $0x18
  jmp alltraps
801075fa:	e9 1c f8 ff ff       	jmp    80106e1b <alltraps>

801075ff <vector25>:
.globl vector25
vector25:
  pushl $0
801075ff:	6a 00                	push   $0x0
  pushl $25
80107601:	6a 19                	push   $0x19
  jmp alltraps
80107603:	e9 13 f8 ff ff       	jmp    80106e1b <alltraps>

80107608 <vector26>:
.globl vector26
vector26:
  pushl $0
80107608:	6a 00                	push   $0x0
  pushl $26
8010760a:	6a 1a                	push   $0x1a
  jmp alltraps
8010760c:	e9 0a f8 ff ff       	jmp    80106e1b <alltraps>

80107611 <vector27>:
.globl vector27
vector27:
  pushl $0
80107611:	6a 00                	push   $0x0
  pushl $27
80107613:	6a 1b                	push   $0x1b
  jmp alltraps
80107615:	e9 01 f8 ff ff       	jmp    80106e1b <alltraps>

8010761a <vector28>:
.globl vector28
vector28:
  pushl $0
8010761a:	6a 00                	push   $0x0
  pushl $28
8010761c:	6a 1c                	push   $0x1c
  jmp alltraps
8010761e:	e9 f8 f7 ff ff       	jmp    80106e1b <alltraps>

80107623 <vector29>:
.globl vector29
vector29:
  pushl $0
80107623:	6a 00                	push   $0x0
  pushl $29
80107625:	6a 1d                	push   $0x1d
  jmp alltraps
80107627:	e9 ef f7 ff ff       	jmp    80106e1b <alltraps>

8010762c <vector30>:
.globl vector30
vector30:
  pushl $0
8010762c:	6a 00                	push   $0x0
  pushl $30
8010762e:	6a 1e                	push   $0x1e
  jmp alltraps
80107630:	e9 e6 f7 ff ff       	jmp    80106e1b <alltraps>

80107635 <vector31>:
.globl vector31
vector31:
  pushl $0
80107635:	6a 00                	push   $0x0
  pushl $31
80107637:	6a 1f                	push   $0x1f
  jmp alltraps
80107639:	e9 dd f7 ff ff       	jmp    80106e1b <alltraps>

8010763e <vector32>:
.globl vector32
vector32:
  pushl $0
8010763e:	6a 00                	push   $0x0
  pushl $32
80107640:	6a 20                	push   $0x20
  jmp alltraps
80107642:	e9 d4 f7 ff ff       	jmp    80106e1b <alltraps>

80107647 <vector33>:
.globl vector33
vector33:
  pushl $0
80107647:	6a 00                	push   $0x0
  pushl $33
80107649:	6a 21                	push   $0x21
  jmp alltraps
8010764b:	e9 cb f7 ff ff       	jmp    80106e1b <alltraps>

80107650 <vector34>:
.globl vector34
vector34:
  pushl $0
80107650:	6a 00                	push   $0x0
  pushl $34
80107652:	6a 22                	push   $0x22
  jmp alltraps
80107654:	e9 c2 f7 ff ff       	jmp    80106e1b <alltraps>

80107659 <vector35>:
.globl vector35
vector35:
  pushl $0
80107659:	6a 00                	push   $0x0
  pushl $35
8010765b:	6a 23                	push   $0x23
  jmp alltraps
8010765d:	e9 b9 f7 ff ff       	jmp    80106e1b <alltraps>

80107662 <vector36>:
.globl vector36
vector36:
  pushl $0
80107662:	6a 00                	push   $0x0
  pushl $36
80107664:	6a 24                	push   $0x24
  jmp alltraps
80107666:	e9 b0 f7 ff ff       	jmp    80106e1b <alltraps>

8010766b <vector37>:
.globl vector37
vector37:
  pushl $0
8010766b:	6a 00                	push   $0x0
  pushl $37
8010766d:	6a 25                	push   $0x25
  jmp alltraps
8010766f:	e9 a7 f7 ff ff       	jmp    80106e1b <alltraps>

80107674 <vector38>:
.globl vector38
vector38:
  pushl $0
80107674:	6a 00                	push   $0x0
  pushl $38
80107676:	6a 26                	push   $0x26
  jmp alltraps
80107678:	e9 9e f7 ff ff       	jmp    80106e1b <alltraps>

8010767d <vector39>:
.globl vector39
vector39:
  pushl $0
8010767d:	6a 00                	push   $0x0
  pushl $39
8010767f:	6a 27                	push   $0x27
  jmp alltraps
80107681:	e9 95 f7 ff ff       	jmp    80106e1b <alltraps>

80107686 <vector40>:
.globl vector40
vector40:
  pushl $0
80107686:	6a 00                	push   $0x0
  pushl $40
80107688:	6a 28                	push   $0x28
  jmp alltraps
8010768a:	e9 8c f7 ff ff       	jmp    80106e1b <alltraps>

8010768f <vector41>:
.globl vector41
vector41:
  pushl $0
8010768f:	6a 00                	push   $0x0
  pushl $41
80107691:	6a 29                	push   $0x29
  jmp alltraps
80107693:	e9 83 f7 ff ff       	jmp    80106e1b <alltraps>

80107698 <vector42>:
.globl vector42
vector42:
  pushl $0
80107698:	6a 00                	push   $0x0
  pushl $42
8010769a:	6a 2a                	push   $0x2a
  jmp alltraps
8010769c:	e9 7a f7 ff ff       	jmp    80106e1b <alltraps>

801076a1 <vector43>:
.globl vector43
vector43:
  pushl $0
801076a1:	6a 00                	push   $0x0
  pushl $43
801076a3:	6a 2b                	push   $0x2b
  jmp alltraps
801076a5:	e9 71 f7 ff ff       	jmp    80106e1b <alltraps>

801076aa <vector44>:
.globl vector44
vector44:
  pushl $0
801076aa:	6a 00                	push   $0x0
  pushl $44
801076ac:	6a 2c                	push   $0x2c
  jmp alltraps
801076ae:	e9 68 f7 ff ff       	jmp    80106e1b <alltraps>

801076b3 <vector45>:
.globl vector45
vector45:
  pushl $0
801076b3:	6a 00                	push   $0x0
  pushl $45
801076b5:	6a 2d                	push   $0x2d
  jmp alltraps
801076b7:	e9 5f f7 ff ff       	jmp    80106e1b <alltraps>

801076bc <vector46>:
.globl vector46
vector46:
  pushl $0
801076bc:	6a 00                	push   $0x0
  pushl $46
801076be:	6a 2e                	push   $0x2e
  jmp alltraps
801076c0:	e9 56 f7 ff ff       	jmp    80106e1b <alltraps>

801076c5 <vector47>:
.globl vector47
vector47:
  pushl $0
801076c5:	6a 00                	push   $0x0
  pushl $47
801076c7:	6a 2f                	push   $0x2f
  jmp alltraps
801076c9:	e9 4d f7 ff ff       	jmp    80106e1b <alltraps>

801076ce <vector48>:
.globl vector48
vector48:
  pushl $0
801076ce:	6a 00                	push   $0x0
  pushl $48
801076d0:	6a 30                	push   $0x30
  jmp alltraps
801076d2:	e9 44 f7 ff ff       	jmp    80106e1b <alltraps>

801076d7 <vector49>:
.globl vector49
vector49:
  pushl $0
801076d7:	6a 00                	push   $0x0
  pushl $49
801076d9:	6a 31                	push   $0x31
  jmp alltraps
801076db:	e9 3b f7 ff ff       	jmp    80106e1b <alltraps>

801076e0 <vector50>:
.globl vector50
vector50:
  pushl $0
801076e0:	6a 00                	push   $0x0
  pushl $50
801076e2:	6a 32                	push   $0x32
  jmp alltraps
801076e4:	e9 32 f7 ff ff       	jmp    80106e1b <alltraps>

801076e9 <vector51>:
.globl vector51
vector51:
  pushl $0
801076e9:	6a 00                	push   $0x0
  pushl $51
801076eb:	6a 33                	push   $0x33
  jmp alltraps
801076ed:	e9 29 f7 ff ff       	jmp    80106e1b <alltraps>

801076f2 <vector52>:
.globl vector52
vector52:
  pushl $0
801076f2:	6a 00                	push   $0x0
  pushl $52
801076f4:	6a 34                	push   $0x34
  jmp alltraps
801076f6:	e9 20 f7 ff ff       	jmp    80106e1b <alltraps>

801076fb <vector53>:
.globl vector53
vector53:
  pushl $0
801076fb:	6a 00                	push   $0x0
  pushl $53
801076fd:	6a 35                	push   $0x35
  jmp alltraps
801076ff:	e9 17 f7 ff ff       	jmp    80106e1b <alltraps>

80107704 <vector54>:
.globl vector54
vector54:
  pushl $0
80107704:	6a 00                	push   $0x0
  pushl $54
80107706:	6a 36                	push   $0x36
  jmp alltraps
80107708:	e9 0e f7 ff ff       	jmp    80106e1b <alltraps>

8010770d <vector55>:
.globl vector55
vector55:
  pushl $0
8010770d:	6a 00                	push   $0x0
  pushl $55
8010770f:	6a 37                	push   $0x37
  jmp alltraps
80107711:	e9 05 f7 ff ff       	jmp    80106e1b <alltraps>

80107716 <vector56>:
.globl vector56
vector56:
  pushl $0
80107716:	6a 00                	push   $0x0
  pushl $56
80107718:	6a 38                	push   $0x38
  jmp alltraps
8010771a:	e9 fc f6 ff ff       	jmp    80106e1b <alltraps>

8010771f <vector57>:
.globl vector57
vector57:
  pushl $0
8010771f:	6a 00                	push   $0x0
  pushl $57
80107721:	6a 39                	push   $0x39
  jmp alltraps
80107723:	e9 f3 f6 ff ff       	jmp    80106e1b <alltraps>

80107728 <vector58>:
.globl vector58
vector58:
  pushl $0
80107728:	6a 00                	push   $0x0
  pushl $58
8010772a:	6a 3a                	push   $0x3a
  jmp alltraps
8010772c:	e9 ea f6 ff ff       	jmp    80106e1b <alltraps>

80107731 <vector59>:
.globl vector59
vector59:
  pushl $0
80107731:	6a 00                	push   $0x0
  pushl $59
80107733:	6a 3b                	push   $0x3b
  jmp alltraps
80107735:	e9 e1 f6 ff ff       	jmp    80106e1b <alltraps>

8010773a <vector60>:
.globl vector60
vector60:
  pushl $0
8010773a:	6a 00                	push   $0x0
  pushl $60
8010773c:	6a 3c                	push   $0x3c
  jmp alltraps
8010773e:	e9 d8 f6 ff ff       	jmp    80106e1b <alltraps>

80107743 <vector61>:
.globl vector61
vector61:
  pushl $0
80107743:	6a 00                	push   $0x0
  pushl $61
80107745:	6a 3d                	push   $0x3d
  jmp alltraps
80107747:	e9 cf f6 ff ff       	jmp    80106e1b <alltraps>

8010774c <vector62>:
.globl vector62
vector62:
  pushl $0
8010774c:	6a 00                	push   $0x0
  pushl $62
8010774e:	6a 3e                	push   $0x3e
  jmp alltraps
80107750:	e9 c6 f6 ff ff       	jmp    80106e1b <alltraps>

80107755 <vector63>:
.globl vector63
vector63:
  pushl $0
80107755:	6a 00                	push   $0x0
  pushl $63
80107757:	6a 3f                	push   $0x3f
  jmp alltraps
80107759:	e9 bd f6 ff ff       	jmp    80106e1b <alltraps>

8010775e <vector64>:
.globl vector64
vector64:
  pushl $0
8010775e:	6a 00                	push   $0x0
  pushl $64
80107760:	6a 40                	push   $0x40
  jmp alltraps
80107762:	e9 b4 f6 ff ff       	jmp    80106e1b <alltraps>

80107767 <vector65>:
.globl vector65
vector65:
  pushl $0
80107767:	6a 00                	push   $0x0
  pushl $65
80107769:	6a 41                	push   $0x41
  jmp alltraps
8010776b:	e9 ab f6 ff ff       	jmp    80106e1b <alltraps>

80107770 <vector66>:
.globl vector66
vector66:
  pushl $0
80107770:	6a 00                	push   $0x0
  pushl $66
80107772:	6a 42                	push   $0x42
  jmp alltraps
80107774:	e9 a2 f6 ff ff       	jmp    80106e1b <alltraps>

80107779 <vector67>:
.globl vector67
vector67:
  pushl $0
80107779:	6a 00                	push   $0x0
  pushl $67
8010777b:	6a 43                	push   $0x43
  jmp alltraps
8010777d:	e9 99 f6 ff ff       	jmp    80106e1b <alltraps>

80107782 <vector68>:
.globl vector68
vector68:
  pushl $0
80107782:	6a 00                	push   $0x0
  pushl $68
80107784:	6a 44                	push   $0x44
  jmp alltraps
80107786:	e9 90 f6 ff ff       	jmp    80106e1b <alltraps>

8010778b <vector69>:
.globl vector69
vector69:
  pushl $0
8010778b:	6a 00                	push   $0x0
  pushl $69
8010778d:	6a 45                	push   $0x45
  jmp alltraps
8010778f:	e9 87 f6 ff ff       	jmp    80106e1b <alltraps>

80107794 <vector70>:
.globl vector70
vector70:
  pushl $0
80107794:	6a 00                	push   $0x0
  pushl $70
80107796:	6a 46                	push   $0x46
  jmp alltraps
80107798:	e9 7e f6 ff ff       	jmp    80106e1b <alltraps>

8010779d <vector71>:
.globl vector71
vector71:
  pushl $0
8010779d:	6a 00                	push   $0x0
  pushl $71
8010779f:	6a 47                	push   $0x47
  jmp alltraps
801077a1:	e9 75 f6 ff ff       	jmp    80106e1b <alltraps>

801077a6 <vector72>:
.globl vector72
vector72:
  pushl $0
801077a6:	6a 00                	push   $0x0
  pushl $72
801077a8:	6a 48                	push   $0x48
  jmp alltraps
801077aa:	e9 6c f6 ff ff       	jmp    80106e1b <alltraps>

801077af <vector73>:
.globl vector73
vector73:
  pushl $0
801077af:	6a 00                	push   $0x0
  pushl $73
801077b1:	6a 49                	push   $0x49
  jmp alltraps
801077b3:	e9 63 f6 ff ff       	jmp    80106e1b <alltraps>

801077b8 <vector74>:
.globl vector74
vector74:
  pushl $0
801077b8:	6a 00                	push   $0x0
  pushl $74
801077ba:	6a 4a                	push   $0x4a
  jmp alltraps
801077bc:	e9 5a f6 ff ff       	jmp    80106e1b <alltraps>

801077c1 <vector75>:
.globl vector75
vector75:
  pushl $0
801077c1:	6a 00                	push   $0x0
  pushl $75
801077c3:	6a 4b                	push   $0x4b
  jmp alltraps
801077c5:	e9 51 f6 ff ff       	jmp    80106e1b <alltraps>

801077ca <vector76>:
.globl vector76
vector76:
  pushl $0
801077ca:	6a 00                	push   $0x0
  pushl $76
801077cc:	6a 4c                	push   $0x4c
  jmp alltraps
801077ce:	e9 48 f6 ff ff       	jmp    80106e1b <alltraps>

801077d3 <vector77>:
.globl vector77
vector77:
  pushl $0
801077d3:	6a 00                	push   $0x0
  pushl $77
801077d5:	6a 4d                	push   $0x4d
  jmp alltraps
801077d7:	e9 3f f6 ff ff       	jmp    80106e1b <alltraps>

801077dc <vector78>:
.globl vector78
vector78:
  pushl $0
801077dc:	6a 00                	push   $0x0
  pushl $78
801077de:	6a 4e                	push   $0x4e
  jmp alltraps
801077e0:	e9 36 f6 ff ff       	jmp    80106e1b <alltraps>

801077e5 <vector79>:
.globl vector79
vector79:
  pushl $0
801077e5:	6a 00                	push   $0x0
  pushl $79
801077e7:	6a 4f                	push   $0x4f
  jmp alltraps
801077e9:	e9 2d f6 ff ff       	jmp    80106e1b <alltraps>

801077ee <vector80>:
.globl vector80
vector80:
  pushl $0
801077ee:	6a 00                	push   $0x0
  pushl $80
801077f0:	6a 50                	push   $0x50
  jmp alltraps
801077f2:	e9 24 f6 ff ff       	jmp    80106e1b <alltraps>

801077f7 <vector81>:
.globl vector81
vector81:
  pushl $0
801077f7:	6a 00                	push   $0x0
  pushl $81
801077f9:	6a 51                	push   $0x51
  jmp alltraps
801077fb:	e9 1b f6 ff ff       	jmp    80106e1b <alltraps>

80107800 <vector82>:
.globl vector82
vector82:
  pushl $0
80107800:	6a 00                	push   $0x0
  pushl $82
80107802:	6a 52                	push   $0x52
  jmp alltraps
80107804:	e9 12 f6 ff ff       	jmp    80106e1b <alltraps>

80107809 <vector83>:
.globl vector83
vector83:
  pushl $0
80107809:	6a 00                	push   $0x0
  pushl $83
8010780b:	6a 53                	push   $0x53
  jmp alltraps
8010780d:	e9 09 f6 ff ff       	jmp    80106e1b <alltraps>

80107812 <vector84>:
.globl vector84
vector84:
  pushl $0
80107812:	6a 00                	push   $0x0
  pushl $84
80107814:	6a 54                	push   $0x54
  jmp alltraps
80107816:	e9 00 f6 ff ff       	jmp    80106e1b <alltraps>

8010781b <vector85>:
.globl vector85
vector85:
  pushl $0
8010781b:	6a 00                	push   $0x0
  pushl $85
8010781d:	6a 55                	push   $0x55
  jmp alltraps
8010781f:	e9 f7 f5 ff ff       	jmp    80106e1b <alltraps>

80107824 <vector86>:
.globl vector86
vector86:
  pushl $0
80107824:	6a 00                	push   $0x0
  pushl $86
80107826:	6a 56                	push   $0x56
  jmp alltraps
80107828:	e9 ee f5 ff ff       	jmp    80106e1b <alltraps>

8010782d <vector87>:
.globl vector87
vector87:
  pushl $0
8010782d:	6a 00                	push   $0x0
  pushl $87
8010782f:	6a 57                	push   $0x57
  jmp alltraps
80107831:	e9 e5 f5 ff ff       	jmp    80106e1b <alltraps>

80107836 <vector88>:
.globl vector88
vector88:
  pushl $0
80107836:	6a 00                	push   $0x0
  pushl $88
80107838:	6a 58                	push   $0x58
  jmp alltraps
8010783a:	e9 dc f5 ff ff       	jmp    80106e1b <alltraps>

8010783f <vector89>:
.globl vector89
vector89:
  pushl $0
8010783f:	6a 00                	push   $0x0
  pushl $89
80107841:	6a 59                	push   $0x59
  jmp alltraps
80107843:	e9 d3 f5 ff ff       	jmp    80106e1b <alltraps>

80107848 <vector90>:
.globl vector90
vector90:
  pushl $0
80107848:	6a 00                	push   $0x0
  pushl $90
8010784a:	6a 5a                	push   $0x5a
  jmp alltraps
8010784c:	e9 ca f5 ff ff       	jmp    80106e1b <alltraps>

80107851 <vector91>:
.globl vector91
vector91:
  pushl $0
80107851:	6a 00                	push   $0x0
  pushl $91
80107853:	6a 5b                	push   $0x5b
  jmp alltraps
80107855:	e9 c1 f5 ff ff       	jmp    80106e1b <alltraps>

8010785a <vector92>:
.globl vector92
vector92:
  pushl $0
8010785a:	6a 00                	push   $0x0
  pushl $92
8010785c:	6a 5c                	push   $0x5c
  jmp alltraps
8010785e:	e9 b8 f5 ff ff       	jmp    80106e1b <alltraps>

80107863 <vector93>:
.globl vector93
vector93:
  pushl $0
80107863:	6a 00                	push   $0x0
  pushl $93
80107865:	6a 5d                	push   $0x5d
  jmp alltraps
80107867:	e9 af f5 ff ff       	jmp    80106e1b <alltraps>

8010786c <vector94>:
.globl vector94
vector94:
  pushl $0
8010786c:	6a 00                	push   $0x0
  pushl $94
8010786e:	6a 5e                	push   $0x5e
  jmp alltraps
80107870:	e9 a6 f5 ff ff       	jmp    80106e1b <alltraps>

80107875 <vector95>:
.globl vector95
vector95:
  pushl $0
80107875:	6a 00                	push   $0x0
  pushl $95
80107877:	6a 5f                	push   $0x5f
  jmp alltraps
80107879:	e9 9d f5 ff ff       	jmp    80106e1b <alltraps>

8010787e <vector96>:
.globl vector96
vector96:
  pushl $0
8010787e:	6a 00                	push   $0x0
  pushl $96
80107880:	6a 60                	push   $0x60
  jmp alltraps
80107882:	e9 94 f5 ff ff       	jmp    80106e1b <alltraps>

80107887 <vector97>:
.globl vector97
vector97:
  pushl $0
80107887:	6a 00                	push   $0x0
  pushl $97
80107889:	6a 61                	push   $0x61
  jmp alltraps
8010788b:	e9 8b f5 ff ff       	jmp    80106e1b <alltraps>

80107890 <vector98>:
.globl vector98
vector98:
  pushl $0
80107890:	6a 00                	push   $0x0
  pushl $98
80107892:	6a 62                	push   $0x62
  jmp alltraps
80107894:	e9 82 f5 ff ff       	jmp    80106e1b <alltraps>

80107899 <vector99>:
.globl vector99
vector99:
  pushl $0
80107899:	6a 00                	push   $0x0
  pushl $99
8010789b:	6a 63                	push   $0x63
  jmp alltraps
8010789d:	e9 79 f5 ff ff       	jmp    80106e1b <alltraps>

801078a2 <vector100>:
.globl vector100
vector100:
  pushl $0
801078a2:	6a 00                	push   $0x0
  pushl $100
801078a4:	6a 64                	push   $0x64
  jmp alltraps
801078a6:	e9 70 f5 ff ff       	jmp    80106e1b <alltraps>

801078ab <vector101>:
.globl vector101
vector101:
  pushl $0
801078ab:	6a 00                	push   $0x0
  pushl $101
801078ad:	6a 65                	push   $0x65
  jmp alltraps
801078af:	e9 67 f5 ff ff       	jmp    80106e1b <alltraps>

801078b4 <vector102>:
.globl vector102
vector102:
  pushl $0
801078b4:	6a 00                	push   $0x0
  pushl $102
801078b6:	6a 66                	push   $0x66
  jmp alltraps
801078b8:	e9 5e f5 ff ff       	jmp    80106e1b <alltraps>

801078bd <vector103>:
.globl vector103
vector103:
  pushl $0
801078bd:	6a 00                	push   $0x0
  pushl $103
801078bf:	6a 67                	push   $0x67
  jmp alltraps
801078c1:	e9 55 f5 ff ff       	jmp    80106e1b <alltraps>

801078c6 <vector104>:
.globl vector104
vector104:
  pushl $0
801078c6:	6a 00                	push   $0x0
  pushl $104
801078c8:	6a 68                	push   $0x68
  jmp alltraps
801078ca:	e9 4c f5 ff ff       	jmp    80106e1b <alltraps>

801078cf <vector105>:
.globl vector105
vector105:
  pushl $0
801078cf:	6a 00                	push   $0x0
  pushl $105
801078d1:	6a 69                	push   $0x69
  jmp alltraps
801078d3:	e9 43 f5 ff ff       	jmp    80106e1b <alltraps>

801078d8 <vector106>:
.globl vector106
vector106:
  pushl $0
801078d8:	6a 00                	push   $0x0
  pushl $106
801078da:	6a 6a                	push   $0x6a
  jmp alltraps
801078dc:	e9 3a f5 ff ff       	jmp    80106e1b <alltraps>

801078e1 <vector107>:
.globl vector107
vector107:
  pushl $0
801078e1:	6a 00                	push   $0x0
  pushl $107
801078e3:	6a 6b                	push   $0x6b
  jmp alltraps
801078e5:	e9 31 f5 ff ff       	jmp    80106e1b <alltraps>

801078ea <vector108>:
.globl vector108
vector108:
  pushl $0
801078ea:	6a 00                	push   $0x0
  pushl $108
801078ec:	6a 6c                	push   $0x6c
  jmp alltraps
801078ee:	e9 28 f5 ff ff       	jmp    80106e1b <alltraps>

801078f3 <vector109>:
.globl vector109
vector109:
  pushl $0
801078f3:	6a 00                	push   $0x0
  pushl $109
801078f5:	6a 6d                	push   $0x6d
  jmp alltraps
801078f7:	e9 1f f5 ff ff       	jmp    80106e1b <alltraps>

801078fc <vector110>:
.globl vector110
vector110:
  pushl $0
801078fc:	6a 00                	push   $0x0
  pushl $110
801078fe:	6a 6e                	push   $0x6e
  jmp alltraps
80107900:	e9 16 f5 ff ff       	jmp    80106e1b <alltraps>

80107905 <vector111>:
.globl vector111
vector111:
  pushl $0
80107905:	6a 00                	push   $0x0
  pushl $111
80107907:	6a 6f                	push   $0x6f
  jmp alltraps
80107909:	e9 0d f5 ff ff       	jmp    80106e1b <alltraps>

8010790e <vector112>:
.globl vector112
vector112:
  pushl $0
8010790e:	6a 00                	push   $0x0
  pushl $112
80107910:	6a 70                	push   $0x70
  jmp alltraps
80107912:	e9 04 f5 ff ff       	jmp    80106e1b <alltraps>

80107917 <vector113>:
.globl vector113
vector113:
  pushl $0
80107917:	6a 00                	push   $0x0
  pushl $113
80107919:	6a 71                	push   $0x71
  jmp alltraps
8010791b:	e9 fb f4 ff ff       	jmp    80106e1b <alltraps>

80107920 <vector114>:
.globl vector114
vector114:
  pushl $0
80107920:	6a 00                	push   $0x0
  pushl $114
80107922:	6a 72                	push   $0x72
  jmp alltraps
80107924:	e9 f2 f4 ff ff       	jmp    80106e1b <alltraps>

80107929 <vector115>:
.globl vector115
vector115:
  pushl $0
80107929:	6a 00                	push   $0x0
  pushl $115
8010792b:	6a 73                	push   $0x73
  jmp alltraps
8010792d:	e9 e9 f4 ff ff       	jmp    80106e1b <alltraps>

80107932 <vector116>:
.globl vector116
vector116:
  pushl $0
80107932:	6a 00                	push   $0x0
  pushl $116
80107934:	6a 74                	push   $0x74
  jmp alltraps
80107936:	e9 e0 f4 ff ff       	jmp    80106e1b <alltraps>

8010793b <vector117>:
.globl vector117
vector117:
  pushl $0
8010793b:	6a 00                	push   $0x0
  pushl $117
8010793d:	6a 75                	push   $0x75
  jmp alltraps
8010793f:	e9 d7 f4 ff ff       	jmp    80106e1b <alltraps>

80107944 <vector118>:
.globl vector118
vector118:
  pushl $0
80107944:	6a 00                	push   $0x0
  pushl $118
80107946:	6a 76                	push   $0x76
  jmp alltraps
80107948:	e9 ce f4 ff ff       	jmp    80106e1b <alltraps>

8010794d <vector119>:
.globl vector119
vector119:
  pushl $0
8010794d:	6a 00                	push   $0x0
  pushl $119
8010794f:	6a 77                	push   $0x77
  jmp alltraps
80107951:	e9 c5 f4 ff ff       	jmp    80106e1b <alltraps>

80107956 <vector120>:
.globl vector120
vector120:
  pushl $0
80107956:	6a 00                	push   $0x0
  pushl $120
80107958:	6a 78                	push   $0x78
  jmp alltraps
8010795a:	e9 bc f4 ff ff       	jmp    80106e1b <alltraps>

8010795f <vector121>:
.globl vector121
vector121:
  pushl $0
8010795f:	6a 00                	push   $0x0
  pushl $121
80107961:	6a 79                	push   $0x79
  jmp alltraps
80107963:	e9 b3 f4 ff ff       	jmp    80106e1b <alltraps>

80107968 <vector122>:
.globl vector122
vector122:
  pushl $0
80107968:	6a 00                	push   $0x0
  pushl $122
8010796a:	6a 7a                	push   $0x7a
  jmp alltraps
8010796c:	e9 aa f4 ff ff       	jmp    80106e1b <alltraps>

80107971 <vector123>:
.globl vector123
vector123:
  pushl $0
80107971:	6a 00                	push   $0x0
  pushl $123
80107973:	6a 7b                	push   $0x7b
  jmp alltraps
80107975:	e9 a1 f4 ff ff       	jmp    80106e1b <alltraps>

8010797a <vector124>:
.globl vector124
vector124:
  pushl $0
8010797a:	6a 00                	push   $0x0
  pushl $124
8010797c:	6a 7c                	push   $0x7c
  jmp alltraps
8010797e:	e9 98 f4 ff ff       	jmp    80106e1b <alltraps>

80107983 <vector125>:
.globl vector125
vector125:
  pushl $0
80107983:	6a 00                	push   $0x0
  pushl $125
80107985:	6a 7d                	push   $0x7d
  jmp alltraps
80107987:	e9 8f f4 ff ff       	jmp    80106e1b <alltraps>

8010798c <vector126>:
.globl vector126
vector126:
  pushl $0
8010798c:	6a 00                	push   $0x0
  pushl $126
8010798e:	6a 7e                	push   $0x7e
  jmp alltraps
80107990:	e9 86 f4 ff ff       	jmp    80106e1b <alltraps>

80107995 <vector127>:
.globl vector127
vector127:
  pushl $0
80107995:	6a 00                	push   $0x0
  pushl $127
80107997:	6a 7f                	push   $0x7f
  jmp alltraps
80107999:	e9 7d f4 ff ff       	jmp    80106e1b <alltraps>

8010799e <vector128>:
.globl vector128
vector128:
  pushl $0
8010799e:	6a 00                	push   $0x0
  pushl $128
801079a0:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801079a5:	e9 71 f4 ff ff       	jmp    80106e1b <alltraps>

801079aa <vector129>:
.globl vector129
vector129:
  pushl $0
801079aa:	6a 00                	push   $0x0
  pushl $129
801079ac:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801079b1:	e9 65 f4 ff ff       	jmp    80106e1b <alltraps>

801079b6 <vector130>:
.globl vector130
vector130:
  pushl $0
801079b6:	6a 00                	push   $0x0
  pushl $130
801079b8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801079bd:	e9 59 f4 ff ff       	jmp    80106e1b <alltraps>

801079c2 <vector131>:
.globl vector131
vector131:
  pushl $0
801079c2:	6a 00                	push   $0x0
  pushl $131
801079c4:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801079c9:	e9 4d f4 ff ff       	jmp    80106e1b <alltraps>

801079ce <vector132>:
.globl vector132
vector132:
  pushl $0
801079ce:	6a 00                	push   $0x0
  pushl $132
801079d0:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801079d5:	e9 41 f4 ff ff       	jmp    80106e1b <alltraps>

801079da <vector133>:
.globl vector133
vector133:
  pushl $0
801079da:	6a 00                	push   $0x0
  pushl $133
801079dc:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801079e1:	e9 35 f4 ff ff       	jmp    80106e1b <alltraps>

801079e6 <vector134>:
.globl vector134
vector134:
  pushl $0
801079e6:	6a 00                	push   $0x0
  pushl $134
801079e8:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801079ed:	e9 29 f4 ff ff       	jmp    80106e1b <alltraps>

801079f2 <vector135>:
.globl vector135
vector135:
  pushl $0
801079f2:	6a 00                	push   $0x0
  pushl $135
801079f4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079f9:	e9 1d f4 ff ff       	jmp    80106e1b <alltraps>

801079fe <vector136>:
.globl vector136
vector136:
  pushl $0
801079fe:	6a 00                	push   $0x0
  pushl $136
80107a00:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107a05:	e9 11 f4 ff ff       	jmp    80106e1b <alltraps>

80107a0a <vector137>:
.globl vector137
vector137:
  pushl $0
80107a0a:	6a 00                	push   $0x0
  pushl $137
80107a0c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107a11:	e9 05 f4 ff ff       	jmp    80106e1b <alltraps>

80107a16 <vector138>:
.globl vector138
vector138:
  pushl $0
80107a16:	6a 00                	push   $0x0
  pushl $138
80107a18:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107a1d:	e9 f9 f3 ff ff       	jmp    80106e1b <alltraps>

80107a22 <vector139>:
.globl vector139
vector139:
  pushl $0
80107a22:	6a 00                	push   $0x0
  pushl $139
80107a24:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107a29:	e9 ed f3 ff ff       	jmp    80106e1b <alltraps>

80107a2e <vector140>:
.globl vector140
vector140:
  pushl $0
80107a2e:	6a 00                	push   $0x0
  pushl $140
80107a30:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107a35:	e9 e1 f3 ff ff       	jmp    80106e1b <alltraps>

80107a3a <vector141>:
.globl vector141
vector141:
  pushl $0
80107a3a:	6a 00                	push   $0x0
  pushl $141
80107a3c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107a41:	e9 d5 f3 ff ff       	jmp    80106e1b <alltraps>

80107a46 <vector142>:
.globl vector142
vector142:
  pushl $0
80107a46:	6a 00                	push   $0x0
  pushl $142
80107a48:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107a4d:	e9 c9 f3 ff ff       	jmp    80106e1b <alltraps>

80107a52 <vector143>:
.globl vector143
vector143:
  pushl $0
80107a52:	6a 00                	push   $0x0
  pushl $143
80107a54:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a59:	e9 bd f3 ff ff       	jmp    80106e1b <alltraps>

80107a5e <vector144>:
.globl vector144
vector144:
  pushl $0
80107a5e:	6a 00                	push   $0x0
  pushl $144
80107a60:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a65:	e9 b1 f3 ff ff       	jmp    80106e1b <alltraps>

80107a6a <vector145>:
.globl vector145
vector145:
  pushl $0
80107a6a:	6a 00                	push   $0x0
  pushl $145
80107a6c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a71:	e9 a5 f3 ff ff       	jmp    80106e1b <alltraps>

80107a76 <vector146>:
.globl vector146
vector146:
  pushl $0
80107a76:	6a 00                	push   $0x0
  pushl $146
80107a78:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a7d:	e9 99 f3 ff ff       	jmp    80106e1b <alltraps>

80107a82 <vector147>:
.globl vector147
vector147:
  pushl $0
80107a82:	6a 00                	push   $0x0
  pushl $147
80107a84:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a89:	e9 8d f3 ff ff       	jmp    80106e1b <alltraps>

80107a8e <vector148>:
.globl vector148
vector148:
  pushl $0
80107a8e:	6a 00                	push   $0x0
  pushl $148
80107a90:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a95:	e9 81 f3 ff ff       	jmp    80106e1b <alltraps>

80107a9a <vector149>:
.globl vector149
vector149:
  pushl $0
80107a9a:	6a 00                	push   $0x0
  pushl $149
80107a9c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107aa1:	e9 75 f3 ff ff       	jmp    80106e1b <alltraps>

80107aa6 <vector150>:
.globl vector150
vector150:
  pushl $0
80107aa6:	6a 00                	push   $0x0
  pushl $150
80107aa8:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107aad:	e9 69 f3 ff ff       	jmp    80106e1b <alltraps>

80107ab2 <vector151>:
.globl vector151
vector151:
  pushl $0
80107ab2:	6a 00                	push   $0x0
  pushl $151
80107ab4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107ab9:	e9 5d f3 ff ff       	jmp    80106e1b <alltraps>

80107abe <vector152>:
.globl vector152
vector152:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $152
80107ac0:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107ac5:	e9 51 f3 ff ff       	jmp    80106e1b <alltraps>

80107aca <vector153>:
.globl vector153
vector153:
  pushl $0
80107aca:	6a 00                	push   $0x0
  pushl $153
80107acc:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107ad1:	e9 45 f3 ff ff       	jmp    80106e1b <alltraps>

80107ad6 <vector154>:
.globl vector154
vector154:
  pushl $0
80107ad6:	6a 00                	push   $0x0
  pushl $154
80107ad8:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107add:	e9 39 f3 ff ff       	jmp    80106e1b <alltraps>

80107ae2 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $155
80107ae4:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ae9:	e9 2d f3 ff ff       	jmp    80106e1b <alltraps>

80107aee <vector156>:
.globl vector156
vector156:
  pushl $0
80107aee:	6a 00                	push   $0x0
  pushl $156
80107af0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107af5:	e9 21 f3 ff ff       	jmp    80106e1b <alltraps>

80107afa <vector157>:
.globl vector157
vector157:
  pushl $0
80107afa:	6a 00                	push   $0x0
  pushl $157
80107afc:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107b01:	e9 15 f3 ff ff       	jmp    80106e1b <alltraps>

80107b06 <vector158>:
.globl vector158
vector158:
  pushl $0
80107b06:	6a 00                	push   $0x0
  pushl $158
80107b08:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107b0d:	e9 09 f3 ff ff       	jmp    80106e1b <alltraps>

80107b12 <vector159>:
.globl vector159
vector159:
  pushl $0
80107b12:	6a 00                	push   $0x0
  pushl $159
80107b14:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107b19:	e9 fd f2 ff ff       	jmp    80106e1b <alltraps>

80107b1e <vector160>:
.globl vector160
vector160:
  pushl $0
80107b1e:	6a 00                	push   $0x0
  pushl $160
80107b20:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107b25:	e9 f1 f2 ff ff       	jmp    80106e1b <alltraps>

80107b2a <vector161>:
.globl vector161
vector161:
  pushl $0
80107b2a:	6a 00                	push   $0x0
  pushl $161
80107b2c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107b31:	e9 e5 f2 ff ff       	jmp    80106e1b <alltraps>

80107b36 <vector162>:
.globl vector162
vector162:
  pushl $0
80107b36:	6a 00                	push   $0x0
  pushl $162
80107b38:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107b3d:	e9 d9 f2 ff ff       	jmp    80106e1b <alltraps>

80107b42 <vector163>:
.globl vector163
vector163:
  pushl $0
80107b42:	6a 00                	push   $0x0
  pushl $163
80107b44:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107b49:	e9 cd f2 ff ff       	jmp    80106e1b <alltraps>

80107b4e <vector164>:
.globl vector164
vector164:
  pushl $0
80107b4e:	6a 00                	push   $0x0
  pushl $164
80107b50:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b55:	e9 c1 f2 ff ff       	jmp    80106e1b <alltraps>

80107b5a <vector165>:
.globl vector165
vector165:
  pushl $0
80107b5a:	6a 00                	push   $0x0
  pushl $165
80107b5c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b61:	e9 b5 f2 ff ff       	jmp    80106e1b <alltraps>

80107b66 <vector166>:
.globl vector166
vector166:
  pushl $0
80107b66:	6a 00                	push   $0x0
  pushl $166
80107b68:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b6d:	e9 a9 f2 ff ff       	jmp    80106e1b <alltraps>

80107b72 <vector167>:
.globl vector167
vector167:
  pushl $0
80107b72:	6a 00                	push   $0x0
  pushl $167
80107b74:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b79:	e9 9d f2 ff ff       	jmp    80106e1b <alltraps>

80107b7e <vector168>:
.globl vector168
vector168:
  pushl $0
80107b7e:	6a 00                	push   $0x0
  pushl $168
80107b80:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b85:	e9 91 f2 ff ff       	jmp    80106e1b <alltraps>

80107b8a <vector169>:
.globl vector169
vector169:
  pushl $0
80107b8a:	6a 00                	push   $0x0
  pushl $169
80107b8c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b91:	e9 85 f2 ff ff       	jmp    80106e1b <alltraps>

80107b96 <vector170>:
.globl vector170
vector170:
  pushl $0
80107b96:	6a 00                	push   $0x0
  pushl $170
80107b98:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b9d:	e9 79 f2 ff ff       	jmp    80106e1b <alltraps>

80107ba2 <vector171>:
.globl vector171
vector171:
  pushl $0
80107ba2:	6a 00                	push   $0x0
  pushl $171
80107ba4:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107ba9:	e9 6d f2 ff ff       	jmp    80106e1b <alltraps>

80107bae <vector172>:
.globl vector172
vector172:
  pushl $0
80107bae:	6a 00                	push   $0x0
  pushl $172
80107bb0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107bb5:	e9 61 f2 ff ff       	jmp    80106e1b <alltraps>

80107bba <vector173>:
.globl vector173
vector173:
  pushl $0
80107bba:	6a 00                	push   $0x0
  pushl $173
80107bbc:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107bc1:	e9 55 f2 ff ff       	jmp    80106e1b <alltraps>

80107bc6 <vector174>:
.globl vector174
vector174:
  pushl $0
80107bc6:	6a 00                	push   $0x0
  pushl $174
80107bc8:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107bcd:	e9 49 f2 ff ff       	jmp    80106e1b <alltraps>

80107bd2 <vector175>:
.globl vector175
vector175:
  pushl $0
80107bd2:	6a 00                	push   $0x0
  pushl $175
80107bd4:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107bd9:	e9 3d f2 ff ff       	jmp    80106e1b <alltraps>

80107bde <vector176>:
.globl vector176
vector176:
  pushl $0
80107bde:	6a 00                	push   $0x0
  pushl $176
80107be0:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107be5:	e9 31 f2 ff ff       	jmp    80106e1b <alltraps>

80107bea <vector177>:
.globl vector177
vector177:
  pushl $0
80107bea:	6a 00                	push   $0x0
  pushl $177
80107bec:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107bf1:	e9 25 f2 ff ff       	jmp    80106e1b <alltraps>

80107bf6 <vector178>:
.globl vector178
vector178:
  pushl $0
80107bf6:	6a 00                	push   $0x0
  pushl $178
80107bf8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107bfd:	e9 19 f2 ff ff       	jmp    80106e1b <alltraps>

80107c02 <vector179>:
.globl vector179
vector179:
  pushl $0
80107c02:	6a 00                	push   $0x0
  pushl $179
80107c04:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107c09:	e9 0d f2 ff ff       	jmp    80106e1b <alltraps>

80107c0e <vector180>:
.globl vector180
vector180:
  pushl $0
80107c0e:	6a 00                	push   $0x0
  pushl $180
80107c10:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107c15:	e9 01 f2 ff ff       	jmp    80106e1b <alltraps>

80107c1a <vector181>:
.globl vector181
vector181:
  pushl $0
80107c1a:	6a 00                	push   $0x0
  pushl $181
80107c1c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107c21:	e9 f5 f1 ff ff       	jmp    80106e1b <alltraps>

80107c26 <vector182>:
.globl vector182
vector182:
  pushl $0
80107c26:	6a 00                	push   $0x0
  pushl $182
80107c28:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107c2d:	e9 e9 f1 ff ff       	jmp    80106e1b <alltraps>

80107c32 <vector183>:
.globl vector183
vector183:
  pushl $0
80107c32:	6a 00                	push   $0x0
  pushl $183
80107c34:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107c39:	e9 dd f1 ff ff       	jmp    80106e1b <alltraps>

80107c3e <vector184>:
.globl vector184
vector184:
  pushl $0
80107c3e:	6a 00                	push   $0x0
  pushl $184
80107c40:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107c45:	e9 d1 f1 ff ff       	jmp    80106e1b <alltraps>

80107c4a <vector185>:
.globl vector185
vector185:
  pushl $0
80107c4a:	6a 00                	push   $0x0
  pushl $185
80107c4c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c51:	e9 c5 f1 ff ff       	jmp    80106e1b <alltraps>

80107c56 <vector186>:
.globl vector186
vector186:
  pushl $0
80107c56:	6a 00                	push   $0x0
  pushl $186
80107c58:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c5d:	e9 b9 f1 ff ff       	jmp    80106e1b <alltraps>

80107c62 <vector187>:
.globl vector187
vector187:
  pushl $0
80107c62:	6a 00                	push   $0x0
  pushl $187
80107c64:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c69:	e9 ad f1 ff ff       	jmp    80106e1b <alltraps>

80107c6e <vector188>:
.globl vector188
vector188:
  pushl $0
80107c6e:	6a 00                	push   $0x0
  pushl $188
80107c70:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c75:	e9 a1 f1 ff ff       	jmp    80106e1b <alltraps>

80107c7a <vector189>:
.globl vector189
vector189:
  pushl $0
80107c7a:	6a 00                	push   $0x0
  pushl $189
80107c7c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c81:	e9 95 f1 ff ff       	jmp    80106e1b <alltraps>

80107c86 <vector190>:
.globl vector190
vector190:
  pushl $0
80107c86:	6a 00                	push   $0x0
  pushl $190
80107c88:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c8d:	e9 89 f1 ff ff       	jmp    80106e1b <alltraps>

80107c92 <vector191>:
.globl vector191
vector191:
  pushl $0
80107c92:	6a 00                	push   $0x0
  pushl $191
80107c94:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c99:	e9 7d f1 ff ff       	jmp    80106e1b <alltraps>

80107c9e <vector192>:
.globl vector192
vector192:
  pushl $0
80107c9e:	6a 00                	push   $0x0
  pushl $192
80107ca0:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107ca5:	e9 71 f1 ff ff       	jmp    80106e1b <alltraps>

80107caa <vector193>:
.globl vector193
vector193:
  pushl $0
80107caa:	6a 00                	push   $0x0
  pushl $193
80107cac:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107cb1:	e9 65 f1 ff ff       	jmp    80106e1b <alltraps>

80107cb6 <vector194>:
.globl vector194
vector194:
  pushl $0
80107cb6:	6a 00                	push   $0x0
  pushl $194
80107cb8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107cbd:	e9 59 f1 ff ff       	jmp    80106e1b <alltraps>

80107cc2 <vector195>:
.globl vector195
vector195:
  pushl $0
80107cc2:	6a 00                	push   $0x0
  pushl $195
80107cc4:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107cc9:	e9 4d f1 ff ff       	jmp    80106e1b <alltraps>

80107cce <vector196>:
.globl vector196
vector196:
  pushl $0
80107cce:	6a 00                	push   $0x0
  pushl $196
80107cd0:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107cd5:	e9 41 f1 ff ff       	jmp    80106e1b <alltraps>

80107cda <vector197>:
.globl vector197
vector197:
  pushl $0
80107cda:	6a 00                	push   $0x0
  pushl $197
80107cdc:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107ce1:	e9 35 f1 ff ff       	jmp    80106e1b <alltraps>

80107ce6 <vector198>:
.globl vector198
vector198:
  pushl $0
80107ce6:	6a 00                	push   $0x0
  pushl $198
80107ce8:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107ced:	e9 29 f1 ff ff       	jmp    80106e1b <alltraps>

80107cf2 <vector199>:
.globl vector199
vector199:
  pushl $0
80107cf2:	6a 00                	push   $0x0
  pushl $199
80107cf4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107cf9:	e9 1d f1 ff ff       	jmp    80106e1b <alltraps>

80107cfe <vector200>:
.globl vector200
vector200:
  pushl $0
80107cfe:	6a 00                	push   $0x0
  pushl $200
80107d00:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107d05:	e9 11 f1 ff ff       	jmp    80106e1b <alltraps>

80107d0a <vector201>:
.globl vector201
vector201:
  pushl $0
80107d0a:	6a 00                	push   $0x0
  pushl $201
80107d0c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107d11:	e9 05 f1 ff ff       	jmp    80106e1b <alltraps>

80107d16 <vector202>:
.globl vector202
vector202:
  pushl $0
80107d16:	6a 00                	push   $0x0
  pushl $202
80107d18:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107d1d:	e9 f9 f0 ff ff       	jmp    80106e1b <alltraps>

80107d22 <vector203>:
.globl vector203
vector203:
  pushl $0
80107d22:	6a 00                	push   $0x0
  pushl $203
80107d24:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107d29:	e9 ed f0 ff ff       	jmp    80106e1b <alltraps>

80107d2e <vector204>:
.globl vector204
vector204:
  pushl $0
80107d2e:	6a 00                	push   $0x0
  pushl $204
80107d30:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107d35:	e9 e1 f0 ff ff       	jmp    80106e1b <alltraps>

80107d3a <vector205>:
.globl vector205
vector205:
  pushl $0
80107d3a:	6a 00                	push   $0x0
  pushl $205
80107d3c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107d41:	e9 d5 f0 ff ff       	jmp    80106e1b <alltraps>

80107d46 <vector206>:
.globl vector206
vector206:
  pushl $0
80107d46:	6a 00                	push   $0x0
  pushl $206
80107d48:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107d4d:	e9 c9 f0 ff ff       	jmp    80106e1b <alltraps>

80107d52 <vector207>:
.globl vector207
vector207:
  pushl $0
80107d52:	6a 00                	push   $0x0
  pushl $207
80107d54:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d59:	e9 bd f0 ff ff       	jmp    80106e1b <alltraps>

80107d5e <vector208>:
.globl vector208
vector208:
  pushl $0
80107d5e:	6a 00                	push   $0x0
  pushl $208
80107d60:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d65:	e9 b1 f0 ff ff       	jmp    80106e1b <alltraps>

80107d6a <vector209>:
.globl vector209
vector209:
  pushl $0
80107d6a:	6a 00                	push   $0x0
  pushl $209
80107d6c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d71:	e9 a5 f0 ff ff       	jmp    80106e1b <alltraps>

80107d76 <vector210>:
.globl vector210
vector210:
  pushl $0
80107d76:	6a 00                	push   $0x0
  pushl $210
80107d78:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d7d:	e9 99 f0 ff ff       	jmp    80106e1b <alltraps>

80107d82 <vector211>:
.globl vector211
vector211:
  pushl $0
80107d82:	6a 00                	push   $0x0
  pushl $211
80107d84:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d89:	e9 8d f0 ff ff       	jmp    80106e1b <alltraps>

80107d8e <vector212>:
.globl vector212
vector212:
  pushl $0
80107d8e:	6a 00                	push   $0x0
  pushl $212
80107d90:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d95:	e9 81 f0 ff ff       	jmp    80106e1b <alltraps>

80107d9a <vector213>:
.globl vector213
vector213:
  pushl $0
80107d9a:	6a 00                	push   $0x0
  pushl $213
80107d9c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107da1:	e9 75 f0 ff ff       	jmp    80106e1b <alltraps>

80107da6 <vector214>:
.globl vector214
vector214:
  pushl $0
80107da6:	6a 00                	push   $0x0
  pushl $214
80107da8:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107dad:	e9 69 f0 ff ff       	jmp    80106e1b <alltraps>

80107db2 <vector215>:
.globl vector215
vector215:
  pushl $0
80107db2:	6a 00                	push   $0x0
  pushl $215
80107db4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107db9:	e9 5d f0 ff ff       	jmp    80106e1b <alltraps>

80107dbe <vector216>:
.globl vector216
vector216:
  pushl $0
80107dbe:	6a 00                	push   $0x0
  pushl $216
80107dc0:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107dc5:	e9 51 f0 ff ff       	jmp    80106e1b <alltraps>

80107dca <vector217>:
.globl vector217
vector217:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $217
80107dcc:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107dd1:	e9 45 f0 ff ff       	jmp    80106e1b <alltraps>

80107dd6 <vector218>:
.globl vector218
vector218:
  pushl $0
80107dd6:	6a 00                	push   $0x0
  pushl $218
80107dd8:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107ddd:	e9 39 f0 ff ff       	jmp    80106e1b <alltraps>

80107de2 <vector219>:
.globl vector219
vector219:
  pushl $0
80107de2:	6a 00                	push   $0x0
  pushl $219
80107de4:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107de9:	e9 2d f0 ff ff       	jmp    80106e1b <alltraps>

80107dee <vector220>:
.globl vector220
vector220:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $220
80107df0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107df5:	e9 21 f0 ff ff       	jmp    80106e1b <alltraps>

80107dfa <vector221>:
.globl vector221
vector221:
  pushl $0
80107dfa:	6a 00                	push   $0x0
  pushl $221
80107dfc:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107e01:	e9 15 f0 ff ff       	jmp    80106e1b <alltraps>

80107e06 <vector222>:
.globl vector222
vector222:
  pushl $0
80107e06:	6a 00                	push   $0x0
  pushl $222
80107e08:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107e0d:	e9 09 f0 ff ff       	jmp    80106e1b <alltraps>

80107e12 <vector223>:
.globl vector223
vector223:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $223
80107e14:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107e19:	e9 fd ef ff ff       	jmp    80106e1b <alltraps>

80107e1e <vector224>:
.globl vector224
vector224:
  pushl $0
80107e1e:	6a 00                	push   $0x0
  pushl $224
80107e20:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107e25:	e9 f1 ef ff ff       	jmp    80106e1b <alltraps>

80107e2a <vector225>:
.globl vector225
vector225:
  pushl $0
80107e2a:	6a 00                	push   $0x0
  pushl $225
80107e2c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107e31:	e9 e5 ef ff ff       	jmp    80106e1b <alltraps>

80107e36 <vector226>:
.globl vector226
vector226:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $226
80107e38:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107e3d:	e9 d9 ef ff ff       	jmp    80106e1b <alltraps>

80107e42 <vector227>:
.globl vector227
vector227:
  pushl $0
80107e42:	6a 00                	push   $0x0
  pushl $227
80107e44:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107e49:	e9 cd ef ff ff       	jmp    80106e1b <alltraps>

80107e4e <vector228>:
.globl vector228
vector228:
  pushl $0
80107e4e:	6a 00                	push   $0x0
  pushl $228
80107e50:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e55:	e9 c1 ef ff ff       	jmp    80106e1b <alltraps>

80107e5a <vector229>:
.globl vector229
vector229:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $229
80107e5c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e61:	e9 b5 ef ff ff       	jmp    80106e1b <alltraps>

80107e66 <vector230>:
.globl vector230
vector230:
  pushl $0
80107e66:	6a 00                	push   $0x0
  pushl $230
80107e68:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e6d:	e9 a9 ef ff ff       	jmp    80106e1b <alltraps>

80107e72 <vector231>:
.globl vector231
vector231:
  pushl $0
80107e72:	6a 00                	push   $0x0
  pushl $231
80107e74:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e79:	e9 9d ef ff ff       	jmp    80106e1b <alltraps>

80107e7e <vector232>:
.globl vector232
vector232:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $232
80107e80:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e85:	e9 91 ef ff ff       	jmp    80106e1b <alltraps>

80107e8a <vector233>:
.globl vector233
vector233:
  pushl $0
80107e8a:	6a 00                	push   $0x0
  pushl $233
80107e8c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e91:	e9 85 ef ff ff       	jmp    80106e1b <alltraps>

80107e96 <vector234>:
.globl vector234
vector234:
  pushl $0
80107e96:	6a 00                	push   $0x0
  pushl $234
80107e98:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e9d:	e9 79 ef ff ff       	jmp    80106e1b <alltraps>

80107ea2 <vector235>:
.globl vector235
vector235:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $235
80107ea4:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107ea9:	e9 6d ef ff ff       	jmp    80106e1b <alltraps>

80107eae <vector236>:
.globl vector236
vector236:
  pushl $0
80107eae:	6a 00                	push   $0x0
  pushl $236
80107eb0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107eb5:	e9 61 ef ff ff       	jmp    80106e1b <alltraps>

80107eba <vector237>:
.globl vector237
vector237:
  pushl $0
80107eba:	6a 00                	push   $0x0
  pushl $237
80107ebc:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107ec1:	e9 55 ef ff ff       	jmp    80106e1b <alltraps>

80107ec6 <vector238>:
.globl vector238
vector238:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $238
80107ec8:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107ecd:	e9 49 ef ff ff       	jmp    80106e1b <alltraps>

80107ed2 <vector239>:
.globl vector239
vector239:
  pushl $0
80107ed2:	6a 00                	push   $0x0
  pushl $239
80107ed4:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107ed9:	e9 3d ef ff ff       	jmp    80106e1b <alltraps>

80107ede <vector240>:
.globl vector240
vector240:
  pushl $0
80107ede:	6a 00                	push   $0x0
  pushl $240
80107ee0:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107ee5:	e9 31 ef ff ff       	jmp    80106e1b <alltraps>

80107eea <vector241>:
.globl vector241
vector241:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $241
80107eec:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107ef1:	e9 25 ef ff ff       	jmp    80106e1b <alltraps>

80107ef6 <vector242>:
.globl vector242
vector242:
  pushl $0
80107ef6:	6a 00                	push   $0x0
  pushl $242
80107ef8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107efd:	e9 19 ef ff ff       	jmp    80106e1b <alltraps>

80107f02 <vector243>:
.globl vector243
vector243:
  pushl $0
80107f02:	6a 00                	push   $0x0
  pushl $243
80107f04:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107f09:	e9 0d ef ff ff       	jmp    80106e1b <alltraps>

80107f0e <vector244>:
.globl vector244
vector244:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $244
80107f10:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107f15:	e9 01 ef ff ff       	jmp    80106e1b <alltraps>

80107f1a <vector245>:
.globl vector245
vector245:
  pushl $0
80107f1a:	6a 00                	push   $0x0
  pushl $245
80107f1c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107f21:	e9 f5 ee ff ff       	jmp    80106e1b <alltraps>

80107f26 <vector246>:
.globl vector246
vector246:
  pushl $0
80107f26:	6a 00                	push   $0x0
  pushl $246
80107f28:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107f2d:	e9 e9 ee ff ff       	jmp    80106e1b <alltraps>

80107f32 <vector247>:
.globl vector247
vector247:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $247
80107f34:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107f39:	e9 dd ee ff ff       	jmp    80106e1b <alltraps>

80107f3e <vector248>:
.globl vector248
vector248:
  pushl $0
80107f3e:	6a 00                	push   $0x0
  pushl $248
80107f40:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107f45:	e9 d1 ee ff ff       	jmp    80106e1b <alltraps>

80107f4a <vector249>:
.globl vector249
vector249:
  pushl $0
80107f4a:	6a 00                	push   $0x0
  pushl $249
80107f4c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f51:	e9 c5 ee ff ff       	jmp    80106e1b <alltraps>

80107f56 <vector250>:
.globl vector250
vector250:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $250
80107f58:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f5d:	e9 b9 ee ff ff       	jmp    80106e1b <alltraps>

80107f62 <vector251>:
.globl vector251
vector251:
  pushl $0
80107f62:	6a 00                	push   $0x0
  pushl $251
80107f64:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f69:	e9 ad ee ff ff       	jmp    80106e1b <alltraps>

80107f6e <vector252>:
.globl vector252
vector252:
  pushl $0
80107f6e:	6a 00                	push   $0x0
  pushl $252
80107f70:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f75:	e9 a1 ee ff ff       	jmp    80106e1b <alltraps>

80107f7a <vector253>:
.globl vector253
vector253:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $253
80107f7c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f81:	e9 95 ee ff ff       	jmp    80106e1b <alltraps>

80107f86 <vector254>:
.globl vector254
vector254:
  pushl $0
80107f86:	6a 00                	push   $0x0
  pushl $254
80107f88:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f8d:	e9 89 ee ff ff       	jmp    80106e1b <alltraps>

80107f92 <vector255>:
.globl vector255
vector255:
  pushl $0
80107f92:	6a 00                	push   $0x0
  pushl $255
80107f94:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f99:	e9 7d ee ff ff       	jmp    80106e1b <alltraps>

80107f9e <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f9e:	55                   	push   %ebp
80107f9f:	89 e5                	mov    %esp,%ebp
80107fa1:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fa7:	83 e8 01             	sub    $0x1,%eax
80107faa:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107fae:	8b 45 08             	mov    0x8(%ebp),%eax
80107fb1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107fb5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fb8:	c1 e8 10             	shr    $0x10,%eax
80107fbb:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107fbf:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107fc2:	0f 01 10             	lgdtl  (%eax)
}
80107fc5:	c9                   	leave  
80107fc6:	c3                   	ret    

80107fc7 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107fc7:	55                   	push   %ebp
80107fc8:	89 e5                	mov    %esp,%ebp
80107fca:	83 ec 04             	sub    $0x4,%esp
80107fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd0:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107fd4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fd8:	0f 00 d8             	ltr    %ax
}
80107fdb:	c9                   	leave  
80107fdc:	c3                   	ret    

80107fdd <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107fdd:	55                   	push   %ebp
80107fde:	89 e5                	mov    %esp,%ebp
80107fe0:	83 ec 04             	sub    $0x4,%esp
80107fe3:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107fea:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fee:	8e e8                	mov    %eax,%gs
}
80107ff0:	c9                   	leave  
80107ff1:	c3                   	ret    

80107ff2 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107ff2:	55                   	push   %ebp
80107ff3:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ff8:	0f 22 d8             	mov    %eax,%cr3
}
80107ffb:	5d                   	pop    %ebp
80107ffc:	c3                   	ret    

80107ffd <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107ffd:	55                   	push   %ebp
80107ffe:	89 e5                	mov    %esp,%ebp
80108000:	8b 45 08             	mov    0x8(%ebp),%eax
80108003:	05 00 00 00 80       	add    $0x80000000,%eax
80108008:	5d                   	pop    %ebp
80108009:	c3                   	ret    

8010800a <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010800a:	55                   	push   %ebp
8010800b:	89 e5                	mov    %esp,%ebp
8010800d:	8b 45 08             	mov    0x8(%ebp),%eax
80108010:	05 00 00 00 80       	add    $0x80000000,%eax
80108015:	5d                   	pop    %ebp
80108016:	c3                   	ret    

80108017 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108017:	55                   	push   %ebp
80108018:	89 e5                	mov    %esp,%ebp
8010801a:	53                   	push   %ebx
8010801b:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010801e:	e8 12 b6 ff ff       	call   80103635 <cpunum>
80108023:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108029:	05 60 43 11 80       	add    $0x80114360,%eax
8010802e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108031:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108034:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010803a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010803d:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108043:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108046:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010804a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010804d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108051:	83 e2 f0             	and    $0xfffffff0,%edx
80108054:	83 ca 0a             	or     $0xa,%edx
80108057:	88 50 7d             	mov    %dl,0x7d(%eax)
8010805a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010805d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108061:	83 ca 10             	or     $0x10,%edx
80108064:	88 50 7d             	mov    %dl,0x7d(%eax)
80108067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806a:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010806e:	83 e2 9f             	and    $0xffffff9f,%edx
80108071:	88 50 7d             	mov    %dl,0x7d(%eax)
80108074:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108077:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010807b:	83 ca 80             	or     $0xffffff80,%edx
8010807e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108084:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108088:	83 ca 0f             	or     $0xf,%edx
8010808b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010808e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108091:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108095:	83 e2 ef             	and    $0xffffffef,%edx
80108098:	88 50 7e             	mov    %dl,0x7e(%eax)
8010809b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080a2:	83 e2 df             	and    $0xffffffdf,%edx
801080a5:	88 50 7e             	mov    %dl,0x7e(%eax)
801080a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ab:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080af:	83 ca 40             	or     $0x40,%edx
801080b2:	88 50 7e             	mov    %dl,0x7e(%eax)
801080b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080bc:	83 ca 80             	or     $0xffffff80,%edx
801080bf:	88 50 7e             	mov    %dl,0x7e(%eax)
801080c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c5:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801080c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080cc:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801080d3:	ff ff 
801080d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d8:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801080df:	00 00 
801080e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e4:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801080eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ee:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080f5:	83 e2 f0             	and    $0xfffffff0,%edx
801080f8:	83 ca 02             	or     $0x2,%edx
801080fb:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108101:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108104:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010810b:	83 ca 10             	or     $0x10,%edx
8010810e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108114:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108117:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010811e:	83 e2 9f             	and    $0xffffff9f,%edx
80108121:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108131:	83 ca 80             	or     $0xffffff80,%edx
80108134:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010813a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010813d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108144:	83 ca 0f             	or     $0xf,%edx
80108147:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010814d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108150:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108157:	83 e2 ef             	and    $0xffffffef,%edx
8010815a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108160:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108163:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010816a:	83 e2 df             	and    $0xffffffdf,%edx
8010816d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108176:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010817d:	83 ca 40             	or     $0x40,%edx
80108180:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108189:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108190:	83 ca 80             	or     $0xffffff80,%edx
80108193:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108199:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819c:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801081a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a6:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801081ad:	ff ff 
801081af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b2:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801081b9:	00 00 
801081bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081be:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801081c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c8:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081cf:	83 e2 f0             	and    $0xfffffff0,%edx
801081d2:	83 ca 0a             	or     $0xa,%edx
801081d5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081de:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081e5:	83 ca 10             	or     $0x10,%edx
801081e8:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f1:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081f8:	83 ca 60             	or     $0x60,%edx
801081fb:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108201:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108204:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010820b:	83 ca 80             	or     $0xffffff80,%edx
8010820e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108217:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010821e:	83 ca 0f             	or     $0xf,%edx
80108221:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108227:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108231:	83 e2 ef             	and    $0xffffffef,%edx
80108234:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010823a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108244:	83 e2 df             	and    $0xffffffdf,%edx
80108247:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010824d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108250:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108257:	83 ca 40             	or     $0x40,%edx
8010825a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108263:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010826a:	83 ca 80             	or     $0xffffff80,%edx
8010826d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108276:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010827d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108280:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108287:	ff ff 
80108289:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828c:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108293:	00 00 
80108295:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108298:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010829f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a2:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082a9:	83 e2 f0             	and    $0xfffffff0,%edx
801082ac:	83 ca 02             	or     $0x2,%edx
801082af:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082bf:	83 ca 10             	or     $0x10,%edx
801082c2:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082cb:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082d2:	83 ca 60             	or     $0x60,%edx
801082d5:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082de:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082e5:	83 ca 80             	or     $0xffffff80,%edx
801082e8:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082f8:	83 ca 0f             	or     $0xf,%edx
801082fb:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108304:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010830b:	83 e2 ef             	and    $0xffffffef,%edx
8010830e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108317:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010831e:	83 e2 df             	and    $0xffffffdf,%edx
80108321:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108327:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108331:	83 ca 40             	or     $0x40,%edx
80108334:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010833a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108344:	83 ca 80             	or     $0xffffff80,%edx
80108347:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010834d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108350:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835a:	05 b4 00 00 00       	add    $0xb4,%eax
8010835f:	89 c3                	mov    %eax,%ebx
80108361:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108364:	05 b4 00 00 00       	add    $0xb4,%eax
80108369:	c1 e8 10             	shr    $0x10,%eax
8010836c:	89 c1                	mov    %eax,%ecx
8010836e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108371:	05 b4 00 00 00       	add    $0xb4,%eax
80108376:	c1 e8 18             	shr    $0x18,%eax
80108379:	89 c2                	mov    %eax,%edx
8010837b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837e:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108385:	00 00 
80108387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010838a:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108394:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010839a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083a4:	83 e1 f0             	and    $0xfffffff0,%ecx
801083a7:	83 c9 02             	or     $0x2,%ecx
801083aa:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083ba:	83 c9 10             	or     $0x10,%ecx
801083bd:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c6:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083cd:	83 e1 9f             	and    $0xffffff9f,%ecx
801083d0:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d9:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083e0:	83 c9 80             	or     $0xffffff80,%ecx
801083e3:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ec:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083f3:	83 e1 f0             	and    $0xfffffff0,%ecx
801083f6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ff:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108406:	83 e1 ef             	and    $0xffffffef,%ecx
80108409:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010840f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108412:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108419:	83 e1 df             	and    $0xffffffdf,%ecx
8010841c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108422:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108425:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010842c:	83 c9 40             	or     $0x40,%ecx
8010842f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108438:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010843f:	83 c9 80             	or     $0xffffff80,%ecx
80108442:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844b:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108451:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108454:	83 c0 70             	add    $0x70,%eax
80108457:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010845e:	00 
8010845f:	89 04 24             	mov    %eax,(%esp)
80108462:	e8 37 fb ff ff       	call   80107f9e <lgdt>
  loadgs(SEG_KCPU << 3);
80108467:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010846e:	e8 6a fb ff ff       	call   80107fdd <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108476:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010847c:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108483:	00 00 00 00 
}
80108487:	83 c4 24             	add    $0x24,%esp
8010848a:	5b                   	pop    %ebx
8010848b:	5d                   	pop    %ebp
8010848c:	c3                   	ret    

8010848d <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010848d:	55                   	push   %ebp
8010848e:	89 e5                	mov    %esp,%ebp
80108490:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108493:	8b 45 0c             	mov    0xc(%ebp),%eax
80108496:	c1 e8 16             	shr    $0x16,%eax
80108499:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801084a0:	8b 45 08             	mov    0x8(%ebp),%eax
801084a3:	01 d0                	add    %edx,%eax
801084a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801084a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084ab:	8b 00                	mov    (%eax),%eax
801084ad:	83 e0 01             	and    $0x1,%eax
801084b0:	85 c0                	test   %eax,%eax
801084b2:	74 17                	je     801084cb <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801084b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084b7:	8b 00                	mov    (%eax),%eax
801084b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084be:	89 04 24             	mov    %eax,(%esp)
801084c1:	e8 44 fb ff ff       	call   8010800a <p2v>
801084c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084c9:	eb 4b                	jmp    80108516 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801084cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801084cf:	74 0e                	je     801084df <walkpgdir+0x52>
801084d1:	e8 83 ad ff ff       	call   80103259 <kalloc>
801084d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084d9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801084dd:	75 07                	jne    801084e6 <walkpgdir+0x59>
      return 0;
801084df:	b8 00 00 00 00       	mov    $0x0,%eax
801084e4:	eb 47                	jmp    8010852d <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801084e6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084ed:	00 
801084ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084f5:	00 
801084f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f9:	89 04 24             	mov    %eax,(%esp)
801084fc:	e8 11 d5 ff ff       	call   80105a12 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108504:	89 04 24             	mov    %eax,(%esp)
80108507:	e8 f1 fa ff ff       	call   80107ffd <v2p>
8010850c:	83 c8 07             	or     $0x7,%eax
8010850f:	89 c2                	mov    %eax,%edx
80108511:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108514:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108516:	8b 45 0c             	mov    0xc(%ebp),%eax
80108519:	c1 e8 0c             	shr    $0xc,%eax
8010851c:	25 ff 03 00 00       	and    $0x3ff,%eax
80108521:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108528:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010852b:	01 d0                	add    %edx,%eax
}
8010852d:	c9                   	leave  
8010852e:	c3                   	ret    

8010852f <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010852f:	55                   	push   %ebp
80108530:	89 e5                	mov    %esp,%ebp
80108532:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108535:	8b 45 0c             	mov    0xc(%ebp),%eax
80108538:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010853d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108540:	8b 55 0c             	mov    0xc(%ebp),%edx
80108543:	8b 45 10             	mov    0x10(%ebp),%eax
80108546:	01 d0                	add    %edx,%eax
80108548:	83 e8 01             	sub    $0x1,%eax
8010854b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108550:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108553:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010855a:	00 
8010855b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010855e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108562:	8b 45 08             	mov    0x8(%ebp),%eax
80108565:	89 04 24             	mov    %eax,(%esp)
80108568:	e8 20 ff ff ff       	call   8010848d <walkpgdir>
8010856d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108570:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108574:	75 07                	jne    8010857d <mappages+0x4e>
      return -1;
80108576:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010857b:	eb 48                	jmp    801085c5 <mappages+0x96>
    if(*pte & PTE_P)
8010857d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108580:	8b 00                	mov    (%eax),%eax
80108582:	83 e0 01             	and    $0x1,%eax
80108585:	85 c0                	test   %eax,%eax
80108587:	74 0c                	je     80108595 <mappages+0x66>
      panic("remap");
80108589:	c7 04 24 6c a3 10 80 	movl   $0x8010a36c,(%esp)
80108590:	e8 a5 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108595:	8b 45 18             	mov    0x18(%ebp),%eax
80108598:	0b 45 14             	or     0x14(%ebp),%eax
8010859b:	83 c8 01             	or     $0x1,%eax
8010859e:	89 c2                	mov    %eax,%edx
801085a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085a3:	89 10                	mov    %edx,(%eax)
    if(a == last)
801085a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801085ab:	75 08                	jne    801085b5 <mappages+0x86>
      break;
801085ad:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801085ae:	b8 00 00 00 00       	mov    $0x0,%eax
801085b3:	eb 10                	jmp    801085c5 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801085b5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801085bc:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801085c3:	eb 8e                	jmp    80108553 <mappages+0x24>
  return 0;
}
801085c5:	c9                   	leave  
801085c6:	c3                   	ret    

801085c7 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801085c7:	55                   	push   %ebp
801085c8:	89 e5                	mov    %esp,%ebp
801085ca:	53                   	push   %ebx
801085cb:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801085ce:	e8 86 ac ff ff       	call   80103259 <kalloc>
801085d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801085d6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085da:	75 0a                	jne    801085e6 <setupkvm+0x1f>
    return 0;
801085dc:	b8 00 00 00 00       	mov    $0x0,%eax
801085e1:	e9 98 00 00 00       	jmp    8010867e <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801085e6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085ed:	00 
801085ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085f5:	00 
801085f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085f9:	89 04 24             	mov    %eax,(%esp)
801085fc:	e8 11 d4 ff ff       	call   80105a12 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108601:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108608:	e8 fd f9 ff ff       	call   8010800a <p2v>
8010860d:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108612:	76 0c                	jbe    80108620 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108614:	c7 04 24 72 a3 10 80 	movl   $0x8010a372,(%esp)
8010861b:	e8 1a 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108620:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
80108627:	eb 49                	jmp    80108672 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108629:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010862c:	8b 48 0c             	mov    0xc(%eax),%ecx
8010862f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108632:	8b 50 04             	mov    0x4(%eax),%edx
80108635:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108638:	8b 58 08             	mov    0x8(%eax),%ebx
8010863b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010863e:	8b 40 04             	mov    0x4(%eax),%eax
80108641:	29 c3                	sub    %eax,%ebx
80108643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108646:	8b 00                	mov    (%eax),%eax
80108648:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010864c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108650:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108654:	89 44 24 04          	mov    %eax,0x4(%esp)
80108658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010865b:	89 04 24             	mov    %eax,(%esp)
8010865e:	e8 cc fe ff ff       	call   8010852f <mappages>
80108663:	85 c0                	test   %eax,%eax
80108665:	79 07                	jns    8010866e <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108667:	b8 00 00 00 00       	mov    $0x0,%eax
8010866c:	eb 10                	jmp    8010867e <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010866e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108672:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108679:	72 ae                	jb     80108629 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
8010867b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
8010867e:	83 c4 34             	add    $0x34,%esp
80108681:	5b                   	pop    %ebx
80108682:	5d                   	pop    %ebp
80108683:	c3                   	ret    

80108684 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
80108684:	55                   	push   %ebp
80108685:	89 e5                	mov    %esp,%ebp
80108687:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
8010868a:	e8 38 ff ff ff       	call   801085c7 <setupkvm>
8010868f:	a3 58 0d 12 80       	mov    %eax,0x80120d58
    switchkvm();
80108694:	e8 02 00 00 00       	call   8010869b <switchkvm>
  }
80108699:	c9                   	leave  
8010869a:	c3                   	ret    

8010869b <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
8010869b:	55                   	push   %ebp
8010869c:	89 e5                	mov    %esp,%ebp
8010869e:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801086a1:	a1 58 0d 12 80       	mov    0x80120d58,%eax
801086a6:	89 04 24             	mov    %eax,(%esp)
801086a9:	e8 4f f9 ff ff       	call   80107ffd <v2p>
801086ae:	89 04 24             	mov    %eax,(%esp)
801086b1:	e8 3c f9 ff ff       	call   80107ff2 <lcr3>
}
801086b6:	c9                   	leave  
801086b7:	c3                   	ret    

801086b8 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801086b8:	55                   	push   %ebp
801086b9:	89 e5                	mov    %esp,%ebp
801086bb:	53                   	push   %ebx
801086bc:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801086bf:	e8 4e d2 ff ff       	call   80105912 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801086c4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086ca:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086d1:	83 c2 08             	add    $0x8,%edx
801086d4:	89 d3                	mov    %edx,%ebx
801086d6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086dd:	83 c2 08             	add    $0x8,%edx
801086e0:	c1 ea 10             	shr    $0x10,%edx
801086e3:	89 d1                	mov    %edx,%ecx
801086e5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086ec:	83 c2 08             	add    $0x8,%edx
801086ef:	c1 ea 18             	shr    $0x18,%edx
801086f2:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801086f9:	67 00 
801086fb:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108702:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108708:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010870f:	83 e1 f0             	and    $0xfffffff0,%ecx
80108712:	83 c9 09             	or     $0x9,%ecx
80108715:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010871b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108722:	83 c9 10             	or     $0x10,%ecx
80108725:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010872b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108732:	83 e1 9f             	and    $0xffffff9f,%ecx
80108735:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010873b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108742:	83 c9 80             	or     $0xffffff80,%ecx
80108745:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010874b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108752:	83 e1 f0             	and    $0xfffffff0,%ecx
80108755:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010875b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108762:	83 e1 ef             	and    $0xffffffef,%ecx
80108765:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010876b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108772:	83 e1 df             	and    $0xffffffdf,%ecx
80108775:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010877b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108782:	83 c9 40             	or     $0x40,%ecx
80108785:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010878b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108792:	83 e1 7f             	and    $0x7f,%ecx
80108795:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010879b:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801087a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087a7:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801087ae:	83 e2 ef             	and    $0xffffffef,%edx
801087b1:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801087b7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087bd:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801087c3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087c9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801087d0:	8b 52 08             	mov    0x8(%edx),%edx
801087d3:	81 c2 00 10 00 00    	add    $0x1000,%edx
801087d9:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801087dc:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801087e3:	e8 df f7 ff ff       	call   80107fc7 <ltr>
  if(p->pgdir == 0)
801087e8:	8b 45 08             	mov    0x8(%ebp),%eax
801087eb:	8b 40 04             	mov    0x4(%eax),%eax
801087ee:	85 c0                	test   %eax,%eax
801087f0:	75 0c                	jne    801087fe <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801087f2:	c7 04 24 83 a3 10 80 	movl   $0x8010a383,(%esp)
801087f9:	e8 3c 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801087fe:	8b 45 08             	mov    0x8(%ebp),%eax
80108801:	8b 40 04             	mov    0x4(%eax),%eax
80108804:	89 04 24             	mov    %eax,(%esp)
80108807:	e8 f1 f7 ff ff       	call   80107ffd <v2p>
8010880c:	89 04 24             	mov    %eax,(%esp)
8010880f:	e8 de f7 ff ff       	call   80107ff2 <lcr3>
  popcli();
80108814:	e8 3d d1 ff ff       	call   80105956 <popcli>
}
80108819:	83 c4 14             	add    $0x14,%esp
8010881c:	5b                   	pop    %ebx
8010881d:	5d                   	pop    %ebp
8010881e:	c3                   	ret    

8010881f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010881f:	55                   	push   %ebp
80108820:	89 e5                	mov    %esp,%ebp
80108822:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108825:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010882c:	76 0c                	jbe    8010883a <inituvm+0x1b>
    panic("inituvm: more than a page");
8010882e:	c7 04 24 97 a3 10 80 	movl   $0x8010a397,(%esp)
80108835:	e8 00 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
8010883a:	e8 1a aa ff ff       	call   80103259 <kalloc>
8010883f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108842:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108849:	00 
8010884a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108851:	00 
80108852:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108855:	89 04 24             	mov    %eax,(%esp)
80108858:	e8 b5 d1 ff ff       	call   80105a12 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010885d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108860:	89 04 24             	mov    %eax,(%esp)
80108863:	e8 95 f7 ff ff       	call   80107ffd <v2p>
80108868:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010886f:	00 
80108870:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108874:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010887b:	00 
8010887c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108883:	00 
80108884:	8b 45 08             	mov    0x8(%ebp),%eax
80108887:	89 04 24             	mov    %eax,(%esp)
8010888a:	e8 a0 fc ff ff       	call   8010852f <mappages>
  memmove(mem, init, sz);
8010888f:	8b 45 10             	mov    0x10(%ebp),%eax
80108892:	89 44 24 08          	mov    %eax,0x8(%esp)
80108896:	8b 45 0c             	mov    0xc(%ebp),%eax
80108899:	89 44 24 04          	mov    %eax,0x4(%esp)
8010889d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a0:	89 04 24             	mov    %eax,(%esp)
801088a3:	e8 39 d2 ff ff       	call   80105ae1 <memmove>
}
801088a8:	c9                   	leave  
801088a9:	c3                   	ret    

801088aa <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801088aa:	55                   	push   %ebp
801088ab:	89 e5                	mov    %esp,%ebp
801088ad:	53                   	push   %ebx
801088ae:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801088b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801088b4:	25 ff 0f 00 00       	and    $0xfff,%eax
801088b9:	85 c0                	test   %eax,%eax
801088bb:	74 0c                	je     801088c9 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801088bd:	c7 04 24 b4 a3 10 80 	movl   $0x8010a3b4,(%esp)
801088c4:	e8 71 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801088c9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801088d0:	e9 a9 00 00 00       	jmp    8010897e <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801088d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d8:	8b 55 0c             	mov    0xc(%ebp),%edx
801088db:	01 d0                	add    %edx,%eax
801088dd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088e4:	00 
801088e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801088e9:	8b 45 08             	mov    0x8(%ebp),%eax
801088ec:	89 04 24             	mov    %eax,(%esp)
801088ef:	e8 99 fb ff ff       	call   8010848d <walkpgdir>
801088f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801088f7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088fb:	75 0c                	jne    80108909 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801088fd:	c7 04 24 d7 a3 10 80 	movl   $0x8010a3d7,(%esp)
80108904:	e8 31 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108909:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010890c:	8b 00                	mov    (%eax),%eax
8010890e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108913:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108916:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108919:	8b 55 18             	mov    0x18(%ebp),%edx
8010891c:	29 c2                	sub    %eax,%edx
8010891e:	89 d0                	mov    %edx,%eax
80108920:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108925:	77 0f                	ja     80108936 <loaduvm+0x8c>
      n = sz - i;
80108927:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010892a:	8b 55 18             	mov    0x18(%ebp),%edx
8010892d:	29 c2                	sub    %eax,%edx
8010892f:	89 d0                	mov    %edx,%eax
80108931:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108934:	eb 07                	jmp    8010893d <loaduvm+0x93>
    else
      n = PGSIZE;
80108936:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010893d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108940:	8b 55 14             	mov    0x14(%ebp),%edx
80108943:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108946:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108949:	89 04 24             	mov    %eax,(%esp)
8010894c:	e8 b9 f6 ff ff       	call   8010800a <p2v>
80108951:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108954:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108958:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010895c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108960:	8b 45 10             	mov    0x10(%ebp),%eax
80108963:	89 04 24             	mov    %eax,(%esp)
80108966:	e8 61 95 ff ff       	call   80101ecc <readi>
8010896b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010896e:	74 07                	je     80108977 <loaduvm+0xcd>
      return -1;
80108970:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108975:	eb 18                	jmp    8010898f <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108977:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010897e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108981:	3b 45 18             	cmp    0x18(%ebp),%eax
80108984:	0f 82 4b ff ff ff    	jb     801088d5 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010898a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010898f:	83 c4 24             	add    $0x24,%esp
80108992:	5b                   	pop    %ebx
80108993:	5d                   	pop    %ebp
80108994:	c3                   	ret    

80108995 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108995:	55                   	push   %ebp
80108996:	89 e5                	mov    %esp,%ebp
80108998:	53                   	push   %ebx
80108999:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
8010899c:	8b 45 10             	mov    0x10(%ebp),%eax
8010899f:	85 c0                	test   %eax,%eax
801089a1:	79 0a                	jns    801089ad <allocuvm+0x18>
    return 0;
801089a3:	b8 00 00 00 00       	mov    $0x0,%eax
801089a8:	e9 1b 02 00 00       	jmp    80108bc8 <allocuvm+0x233>
  if(newsz < oldsz)
801089ad:	8b 45 10             	mov    0x10(%ebp),%eax
801089b0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801089b3:	73 08                	jae    801089bd <allocuvm+0x28>
    return oldsz;
801089b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801089b8:	e9 0b 02 00 00       	jmp    80108bc8 <allocuvm+0x233>

  a = PGROUNDUP(oldsz);
801089bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801089c0:	05 ff 0f 00 00       	add    $0xfff,%eax
801089c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801089cd:	e9 e7 01 00 00       	jmp    80108bb9 <allocuvm+0x224>
    mem = kalloc();
801089d2:	e8 82 a8 ff ff       	call   80103259 <kalloc>
801089d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
801089da:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089de:	75 36                	jne    80108a16 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
801089e0:	c7 04 24 f5 a3 10 80 	movl   $0x8010a3f5,(%esp)
801089e7:	e8 b4 79 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
801089ec:	8b 45 14             	mov    0x14(%ebp),%eax
801089ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801089f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801089fa:	8b 45 10             	mov    0x10(%ebp),%eax
801089fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a01:	8b 45 08             	mov    0x8(%ebp),%eax
80108a04:	89 04 24             	mov    %eax,(%esp)
80108a07:	e8 c2 01 00 00       	call   80108bce <deallocuvm>
      return 0;
80108a0c:	b8 00 00 00 00       	mov    $0x0,%eax
80108a11:	e9 b2 01 00 00       	jmp    80108bc8 <allocuvm+0x233>
    }
    memset(mem, 0, PGSIZE);
80108a16:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a1d:	00 
80108a1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a25:	00 
80108a26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a29:	89 04 24             	mov    %eax,(%esp)
80108a2c:	e8 e1 cf ff ff       	call   80105a12 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108a31:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a34:	89 04 24             	mov    %eax,(%esp)
80108a37:	e8 c1 f5 ff ff       	call   80107ffd <v2p>
80108a3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108a3f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a46:	00 
80108a47:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a4b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a52:	00 
80108a53:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a57:	8b 45 08             	mov    0x8(%ebp),%eax
80108a5a:	89 04 24             	mov    %eax,(%esp)
80108a5d:	e8 cd fa ff ff       	call   8010852f <mappages>
    //find the next open cell in pages array
      i=0;
80108a62:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a69:	eb 16                	jmp    80108a81 <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a6b:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a6f:	7e 0c                	jle    80108a7d <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a71:	c7 04 24 10 a4 10 80 	movl   $0x8010a410,(%esp)
80108a78:	e8 bd 7a ff ff       	call   8010053a <panic>
        }
        i++;
80108a7d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a81:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a84:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a87:	89 d0                	mov    %edx,%eax
80108a89:	c1 e0 02             	shl    $0x2,%eax
80108a8c:	01 d0                	add    %edx,%eax
80108a8e:	c1 e0 02             	shl    $0x2,%eax
80108a91:	01 c8                	add    %ecx,%eax
80108a93:	05 90 00 00 00       	add    $0x90,%eax
80108a98:	8b 00                	mov    (%eax),%eax
80108a9a:	83 f8 ff             	cmp    $0xffffffff,%eax
80108a9d:	75 cc                	jne    80108a6b <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
80108a9f:	8b 45 14             	mov    0x14(%ebp),%eax
80108aa2:	8b 40 10             	mov    0x10(%eax),%eax
80108aa5:	83 f8 01             	cmp    $0x1,%eax
80108aa8:	74 4c                	je     80108af6 <allocuvm+0x161>
80108aaa:	8b 45 14             	mov    0x14(%ebp),%eax
80108aad:	8b 40 10             	mov    0x10(%eax),%eax
80108ab0:	83 f8 02             	cmp    $0x2,%eax
80108ab3:	74 41                	je     80108af6 <allocuvm+0x161>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108ab5:	8b 45 14             	mov    0x14(%ebp),%eax
80108ab8:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108abe:	83 f8 0e             	cmp    $0xe,%eax
80108ac1:	76 1c                	jbe    80108adf <allocuvm+0x14a>
          swapOut();
80108ac3:	e8 fe 0b 00 00       	call   801096c6 <swapOut>
          proc->swapedPagesCounter++;
80108ac8:	8b 45 14             	mov    0x14(%ebp),%eax
80108acb:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108ad1:	8d 50 01             	lea    0x1(%eax),%edx
80108ad4:	8b 45 14             	mov    0x14(%ebp),%eax
80108ad7:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108add:	eb 2c                	jmp    80108b0b <allocuvm+0x176>
          swapOut();
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108adf:	8b 45 14             	mov    0x14(%ebp),%eax
80108ae2:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ae8:	8d 50 01             	lea    0x1(%eax),%edx
80108aeb:	8b 45 14             	mov    0x14(%ebp),%eax
80108aee:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((proc->pid != 1) && (proc->pid != 2)){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES && SCHEDFLAG != 1){//no room, swap something out and let him in
80108af4:	eb 15                	jmp    80108b0b <allocuvm+0x176>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108af6:	8b 45 14             	mov    0x14(%ebp),%eax
80108af9:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108aff:	8d 50 01             	lea    0x1(%eax),%edx
80108b02:	8b 45 14             	mov    0x14(%ebp),%eax
80108b05:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108b0b:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108b0e:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b11:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b14:	89 d0                	mov    %edx,%eax
80108b16:	c1 e0 02             	shl    $0x2,%eax
80108b19:	01 d0                	add    %edx,%eax
80108b1b:	c1 e0 02             	shl    $0x2,%eax
80108b1e:	01 d8                	add    %ebx,%eax
80108b20:	05 90 00 00 00       	add    $0x90,%eax
80108b25:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108b27:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b2a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b2d:	89 d0                	mov    %edx,%eax
80108b2f:	c1 e0 02             	shl    $0x2,%eax
80108b32:	01 d0                	add    %edx,%eax
80108b34:	c1 e0 02             	shl    $0x2,%eax
80108b37:	01 c8                	add    %ecx,%eax
80108b39:	05 94 00 00 00       	add    $0x94,%eax
80108b3e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108b44:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b47:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b4a:	89 d0                	mov    %edx,%eax
80108b4c:	c1 e0 02             	shl    $0x2,%eax
80108b4f:	01 d0                	add    %edx,%eax
80108b51:	c1 e0 02             	shl    $0x2,%eax
80108b54:	01 c8                	add    %ecx,%eax
80108b56:	05 98 00 00 00       	add    $0x98,%eax
80108b5b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b61:	8b 45 14             	mov    0x14(%ebp),%eax
80108b64:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b6a:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b6d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b70:	89 d0                	mov    %edx,%eax
80108b72:	c1 e0 02             	shl    $0x2,%eax
80108b75:	01 d0                	add    %edx,%eax
80108b77:	c1 e0 02             	shl    $0x2,%eax
80108b7a:	01 d8                	add    %ebx,%eax
80108b7c:	05 9c 00 00 00       	add    $0x9c,%eax
80108b81:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108b83:	8b 45 14             	mov    0x14(%ebp),%eax
80108b86:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108b8c:	8d 50 01             	lea    0x1(%eax),%edx
80108b8f:	8b 45 14             	mov    0x14(%ebp),%eax
80108b92:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108b98:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b9b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b9e:	89 d0                	mov    %edx,%eax
80108ba0:	c1 e0 02             	shl    $0x2,%eax
80108ba3:	01 d0                	add    %edx,%eax
80108ba5:	c1 e0 02             	shl    $0x2,%eax
80108ba8:	01 c8                	add    %ecx,%eax
80108baa:	05 a0 00 00 00       	add    $0xa0,%eax
80108baf:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108bb2:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bbc:	3b 45 10             	cmp    0x10(%ebp),%eax
80108bbf:	0f 82 0d fe ff ff    	jb     801089d2 <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108bc5:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108bc8:	83 c4 34             	add    $0x34,%esp
80108bcb:	5b                   	pop    %ebx
80108bcc:	5d                   	pop    %ebp
80108bcd:	c3                   	ret    

80108bce <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108bce:	55                   	push   %ebp
80108bcf:	89 e5                	mov    %esp,%ebp
80108bd1:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108bd4:	8b 45 10             	mov    0x10(%ebp),%eax
80108bd7:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108bda:	72 08                	jb     80108be4 <deallocuvm+0x16>
    return oldsz;
80108bdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bdf:	e9 27 02 00 00       	jmp    80108e0b <deallocuvm+0x23d>

  a = PGROUNDUP(newsz);
80108be4:	8b 45 10             	mov    0x10(%ebp),%eax
80108be7:	05 ff 0f 00 00       	add    $0xfff,%eax
80108bec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bf1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108bf4:	e9 03 02 00 00       	jmp    80108dfc <deallocuvm+0x22e>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108bf9:	8b 45 14             	mov    0x14(%ebp),%eax
80108bfc:	8b 40 04             	mov    0x4(%eax),%eax
80108bff:	3b 45 08             	cmp    0x8(%ebp),%eax
80108c02:	0f 85 0b 01 00 00    	jne    80108d13 <deallocuvm+0x145>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108c08:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108c0f:	e9 f5 00 00 00       	jmp    80108d09 <deallocuvm+0x13b>
          if(proc->pagesMetaData[i].va == (char *)a){
80108c14:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c17:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c1a:	89 d0                	mov    %edx,%eax
80108c1c:	c1 e0 02             	shl    $0x2,%eax
80108c1f:	01 d0                	add    %edx,%eax
80108c21:	c1 e0 02             	shl    $0x2,%eax
80108c24:	01 c8                	add    %ecx,%eax
80108c26:	05 90 00 00 00       	add    $0x90,%eax
80108c2b:	8b 10                	mov    (%eax),%edx
80108c2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c30:	39 c2                	cmp    %eax,%edx
80108c32:	0f 85 cd 00 00 00    	jne    80108d05 <deallocuvm+0x137>
            if(proc->pid != 1 && proc->pid != 2){
80108c38:	8b 45 14             	mov    0x14(%ebp),%eax
80108c3b:	8b 40 10             	mov    0x10(%eax),%eax
80108c3e:	83 f8 01             	cmp    $0x1,%eax
80108c41:	74 56                	je     80108c99 <deallocuvm+0xcb>
80108c43:	8b 45 14             	mov    0x14(%ebp),%eax
80108c46:	8b 40 10             	mov    0x10(%eax),%eax
80108c49:	83 f8 02             	cmp    $0x2,%eax
80108c4c:	74 4b                	je     80108c99 <deallocuvm+0xcb>
              if(proc->pagesMetaData[i].isPhysical){
80108c4e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c51:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c54:	89 d0                	mov    %edx,%eax
80108c56:	c1 e0 02             	shl    $0x2,%eax
80108c59:	01 d0                	add    %edx,%eax
80108c5b:	c1 e0 02             	shl    $0x2,%eax
80108c5e:	01 c8                	add    %ecx,%eax
80108c60:	05 94 00 00 00       	add    $0x94,%eax
80108c65:	8b 00                	mov    (%eax),%eax
80108c67:	85 c0                	test   %eax,%eax
80108c69:	74 17                	je     80108c82 <deallocuvm+0xb4>
                proc->memoryPagesCounter--;
80108c6b:	8b 45 14             	mov    0x14(%ebp),%eax
80108c6e:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c74:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c77:	8b 45 14             	mov    0x14(%ebp),%eax
80108c7a:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c80:	eb 2c                	jmp    80108cae <deallocuvm+0xe0>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108c82:	8b 45 14             	mov    0x14(%ebp),%eax
80108c85:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108c8b:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c8e:	8b 45 14             	mov    0x14(%ebp),%eax
80108c91:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if(proc->pid != 1 && proc->pid != 2){
              if(proc->pagesMetaData[i].isPhysical){
80108c97:	eb 15                	jmp    80108cae <deallocuvm+0xe0>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108c99:	8b 45 14             	mov    0x14(%ebp),%eax
80108c9c:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ca2:	8d 50 ff             	lea    -0x1(%eax),%edx
80108ca5:	8b 45 14             	mov    0x14(%ebp),%eax
80108ca8:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108cae:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cb1:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cb4:	89 d0                	mov    %edx,%eax
80108cb6:	c1 e0 02             	shl    $0x2,%eax
80108cb9:	01 d0                	add    %edx,%eax
80108cbb:	c1 e0 02             	shl    $0x2,%eax
80108cbe:	01 c8                	add    %ecx,%eax
80108cc0:	05 90 00 00 00       	add    $0x90,%eax
80108cc5:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108ccb:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108cce:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cd1:	89 d0                	mov    %edx,%eax
80108cd3:	c1 e0 02             	shl    $0x2,%eax
80108cd6:	01 d0                	add    %edx,%eax
80108cd8:	c1 e0 02             	shl    $0x2,%eax
80108cdb:	01 c8                	add    %ecx,%eax
80108cdd:	05 94 00 00 00       	add    $0x94,%eax
80108ce2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108ce8:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108ceb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cee:	89 d0                	mov    %edx,%eax
80108cf0:	c1 e0 02             	shl    $0x2,%eax
80108cf3:	01 d0                	add    %edx,%eax
80108cf5:	c1 e0 02             	shl    $0x2,%eax
80108cf8:	01 c8                	add    %ecx,%eax
80108cfa:	05 98 00 00 00       	add    $0x98,%eax
80108cff:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108d05:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108d09:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108d0d:	0f 8e 01 ff ff ff    	jle    80108c14 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108d13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d16:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108d1d:	00 
80108d1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d22:	8b 45 08             	mov    0x8(%ebp),%eax
80108d25:	89 04 24             	mov    %eax,(%esp)
80108d28:	e8 60 f7 ff ff       	call   8010848d <walkpgdir>
80108d2d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108d30:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d34:	75 0c                	jne    80108d42 <deallocuvm+0x174>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d36:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d3d:	e9 b3 00 00 00       	jmp    80108df5 <deallocuvm+0x227>
    else if((*pte & PTE_P) != 0){
80108d42:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d45:	8b 00                	mov    (%eax),%eax
80108d47:	83 e0 01             	and    $0x1,%eax
80108d4a:	85 c0                	test   %eax,%eax
80108d4c:	74 76                	je     80108dc4 <deallocuvm+0x1f6>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108d4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d51:	8b 00                	mov    (%eax),%eax
80108d53:	25 00 02 00 00       	and    $0x200,%eax
80108d58:	85 c0                	test   %eax,%eax
80108d5a:	75 43                	jne    80108d9f <deallocuvm+0x1d1>
        pa = PTE_ADDR(*pte);
80108d5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d5f:	8b 00                	mov    (%eax),%eax
80108d61:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d66:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d69:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d6d:	75 0c                	jne    80108d7b <deallocuvm+0x1ad>
          panic("kfree");
80108d6f:	c7 04 24 3a a4 10 80 	movl   $0x8010a43a,(%esp)
80108d76:	e8 bf 77 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108d7b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d7e:	89 04 24             	mov    %eax,(%esp)
80108d81:	e8 84 f2 ff ff       	call   8010800a <p2v>
80108d86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108d89:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d8c:	89 04 24             	mov    %eax,(%esp)
80108d8f:	e8 d2 a3 ff ff       	call   80103166 <kfree>
        *pte = 0;
80108d94:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d97:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d9d:	eb 56                	jmp    80108df5 <deallocuvm+0x227>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108d9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108da2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x",PTE_ADDR(*pte));
80108da8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dab:	8b 00                	mov    (%eax),%eax
80108dad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108db2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108db6:	c7 04 24 40 a4 10 80 	movl   $0x8010a440,(%esp)
80108dbd:	e8 de 75 ff ff       	call   801003a0 <cprintf>
80108dc2:	eb 31                	jmp    80108df5 <deallocuvm+0x227>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108dc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dc7:	8b 00                	mov    (%eax),%eax
80108dc9:	25 00 02 00 00       	and    $0x200,%eax
80108dce:	85 c0                	test   %eax,%eax
80108dd0:	74 23                	je     80108df5 <deallocuvm+0x227>
        *pte = 0;
80108dd2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dd5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
80108ddb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dde:	8b 00                	mov    (%eax),%eax
80108de0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108de5:	89 44 24 04          	mov    %eax,0x4(%esp)
80108de9:	c7 04 24 4e a4 10 80 	movl   $0x8010a44e,(%esp)
80108df0:	e8 ab 75 ff ff       	call   801003a0 <cprintf>
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108df5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108dfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dff:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108e02:	0f 82 f1 fd ff ff    	jb     80108bf9 <deallocuvm+0x2b>
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
        cprintf("dealloc pa:%x\n",PTE_ADDR(*pte));
    }
  }
  return newsz;
80108e08:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108e0b:	c9                   	leave  
80108e0c:	c3                   	ret    

80108e0d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108e0d:	55                   	push   %ebp
80108e0e:	89 e5                	mov    %esp,%ebp
80108e10:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108e13:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108e17:	75 0c                	jne    80108e25 <freevm+0x18>
    panic("freevm: no pgdir");
80108e19:	c7 04 24 5d a4 10 80 	movl   $0x8010a45d,(%esp)
80108e20:	e8 15 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108e25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108e2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e2f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e36:	00 
80108e37:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108e3e:	80 
80108e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80108e42:	89 04 24             	mov    %eax,(%esp)
80108e45:	e8 84 fd ff ff       	call   80108bce <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e51:	eb 48                	jmp    80108e9b <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e56:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e5d:	8b 45 08             	mov    0x8(%ebp),%eax
80108e60:	01 d0                	add    %edx,%eax
80108e62:	8b 00                	mov    (%eax),%eax
80108e64:	83 e0 01             	and    $0x1,%eax
80108e67:	85 c0                	test   %eax,%eax
80108e69:	74 2c                	je     80108e97 <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e6e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e75:	8b 45 08             	mov    0x8(%ebp),%eax
80108e78:	01 d0                	add    %edx,%eax
80108e7a:	8b 00                	mov    (%eax),%eax
80108e7c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e81:	89 04 24             	mov    %eax,(%esp)
80108e84:	e8 81 f1 ff ff       	call   8010800a <p2v>
80108e89:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e8f:	89 04 24             	mov    %eax,(%esp)
80108e92:	e8 cf a2 ff ff       	call   80103166 <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e97:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e9b:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108ea2:	76 af                	jbe    80108e53 <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108ea4:	8b 45 08             	mov    0x8(%ebp),%eax
80108ea7:	89 04 24             	mov    %eax,(%esp)
80108eaa:	e8 b7 a2 ff ff       	call   80103166 <kfree>

}
80108eaf:	c9                   	leave  
80108eb0:	c3                   	ret    

80108eb1 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108eb1:	55                   	push   %ebp
80108eb2:	89 e5                	mov    %esp,%ebp
80108eb4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108eb7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ebe:	00 
80108ebf:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80108ec9:	89 04 24             	mov    %eax,(%esp)
80108ecc:	e8 bc f5 ff ff       	call   8010848d <walkpgdir>
80108ed1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108ed4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108ed8:	75 0c                	jne    80108ee6 <clearpteu+0x35>
    panic("clearpteu");
80108eda:	c7 04 24 6e a4 10 80 	movl   $0x8010a46e,(%esp)
80108ee1:	e8 54 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108ee6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ee9:	8b 00                	mov    (%eax),%eax
80108eeb:	83 e0 fb             	and    $0xfffffffb,%eax
80108eee:	89 c2                	mov    %eax,%edx
80108ef0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ef3:	89 10                	mov    %edx,(%eax)
}
80108ef5:	c9                   	leave  
80108ef6:	c3                   	ret    

80108ef7 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108ef7:	55                   	push   %ebp
80108ef8:	89 e5                	mov    %esp,%ebp
80108efa:	53                   	push   %ebx
80108efb:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108efe:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108f05:	8b 45 10             	mov    0x10(%ebp),%eax
80108f08:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108f0f:	00 00 00 
  np->swapedPagesCounter = 0;
80108f12:	8b 45 10             	mov    0x10(%ebp),%eax
80108f15:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108f1c:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108f1f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108f25:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108f2b:	8b 45 10             	mov    0x10(%ebp),%eax
80108f2e:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108f34:	e8 8e f6 ff ff       	call   801085c7 <setupkvm>
80108f39:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f3c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f40:	75 0a                	jne    80108f4c <copyuvm+0x55>
    return 0;
80108f42:	b8 00 00 00 00       	mov    $0x0,%eax
80108f47:	e9 88 02 00 00       	jmp    801091d4 <copyuvm+0x2dd>
  for(i = 0; i < sz; i += PGSIZE){
80108f4c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f53:	e9 b2 01 00 00       	jmp    8010910a <copyuvm+0x213>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f5b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f62:	00 
80108f63:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f67:	8b 45 08             	mov    0x8(%ebp),%eax
80108f6a:	89 04 24             	mov    %eax,(%esp)
80108f6d:	e8 1b f5 ff ff       	call   8010848d <walkpgdir>
80108f72:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f75:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f79:	75 0c                	jne    80108f87 <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f7b:	c7 04 24 78 a4 10 80 	movl   $0x8010a478,(%esp)
80108f82:	e8 b3 75 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108f87:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f8a:	8b 00                	mov    (%eax),%eax
80108f8c:	83 e0 01             	and    $0x1,%eax
80108f8f:	85 c0                	test   %eax,%eax
80108f91:	75 0c                	jne    80108f9f <copyuvm+0xa8>
      panic("copyuvm: page not present");
80108f93:	c7 04 24 92 a4 10 80 	movl   $0x8010a492,(%esp)
80108f9a:	e8 9b 75 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108f9f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108fa2:	8b 00                	mov    (%eax),%eax
80108fa4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108fa9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    flags = PTE_FLAGS(*pte);
80108fac:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108faf:	8b 00                	mov    (%eax),%eax
80108fb1:	25 ff 0f 00 00       	and    $0xfff,%eax
80108fb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80108fb9:	e8 9b a2 ff ff       	call   80103259 <kalloc>
80108fbe:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108fc1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108fc5:	75 05                	jne    80108fcc <copyuvm+0xd5>
      goto bad;
80108fc7:	e9 f0 01 00 00       	jmp    801091bc <copyuvm+0x2c5>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108fcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108fcf:	89 04 24             	mov    %eax,(%esp)
80108fd2:	e8 33 f0 ff ff       	call   8010800a <p2v>
80108fd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fde:	00 
80108fdf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fe3:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fe6:	89 04 24             	mov    %eax,(%esp)
80108fe9:	e8 f3 ca ff ff       	call   80105ae1 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108fee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108ff1:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108ff4:	89 04 24             	mov    %eax,(%esp)
80108ff7:	e8 01 f0 ff ff       	call   80107ffd <v2p>
80108ffc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108fff:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80109003:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109007:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010900e:	00 
8010900f:	89 54 24 04          	mov    %edx,0x4(%esp)
80109013:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109016:	89 04 24             	mov    %eax,(%esp)
80109019:	e8 11 f5 ff ff       	call   8010852f <mappages>
8010901e:	85 c0                	test   %eax,%eax
80109020:	79 05                	jns    80109027 <copyuvm+0x130>
      goto bad;
80109022:	e9 95 01 00 00       	jmp    801091bc <copyuvm+0x2c5>
    // if(*pte & PTE_PG)
    //   *pte &= ~PTE_PG;
    np->pagesMetaData[j].va = (char *) i;
80109027:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010902a:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010902d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109030:	89 d0                	mov    %edx,%eax
80109032:	c1 e0 02             	shl    $0x2,%eax
80109035:	01 d0                	add    %edx,%eax
80109037:	c1 e0 02             	shl    $0x2,%eax
8010903a:	01 d8                	add    %ebx,%eax
8010903c:	05 90 00 00 00       	add    $0x90,%eax
80109041:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].isPhysical = 1;
80109043:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109046:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109049:	89 d0                	mov    %edx,%eax
8010904b:	c1 e0 02             	shl    $0x2,%eax
8010904e:	01 d0                	add    %edx,%eax
80109050:	c1 e0 02             	shl    $0x2,%eax
80109053:	01 c8                	add    %ecx,%eax
80109055:	05 94 00 00 00       	add    $0x94,%eax
8010905a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109060:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109063:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109066:	89 d0                	mov    %edx,%eax
80109068:	c1 e0 02             	shl    $0x2,%eax
8010906b:	01 d0                	add    %edx,%eax
8010906d:	c1 e0 02             	shl    $0x2,%eax
80109070:	01 c8                	add    %ecx,%eax
80109072:	05 98 00 00 00       	add    $0x98,%eax
80109077:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
8010907d:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109084:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109087:	89 d0                	mov    %edx,%eax
80109089:	c1 e0 02             	shl    $0x2,%eax
8010908c:	01 d0                	add    %edx,%eax
8010908e:	c1 e0 02             	shl    $0x2,%eax
80109091:	01 c8                	add    %ecx,%eax
80109093:	05 9c 00 00 00       	add    $0x9c,%eax
80109098:	8b 08                	mov    (%eax),%ecx
8010909a:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010909d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090a0:	89 d0                	mov    %edx,%eax
801090a2:	c1 e0 02             	shl    $0x2,%eax
801090a5:	01 d0                	add    %edx,%eax
801090a7:	c1 e0 02             	shl    $0x2,%eax
801090aa:	01 d8                	add    %ebx,%eax
801090ac:	05 9c 00 00 00       	add    $0x9c,%eax
801090b1:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
801090b3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801090ba:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090bd:	89 d0                	mov    %edx,%eax
801090bf:	c1 e0 02             	shl    $0x2,%eax
801090c2:	01 d0                	add    %edx,%eax
801090c4:	c1 e0 02             	shl    $0x2,%eax
801090c7:	01 c8                	add    %ecx,%eax
801090c9:	05 a0 00 00 00       	add    $0xa0,%eax
801090ce:	0f b6 08             	movzbl (%eax),%ecx
801090d1:	8b 5d 10             	mov    0x10(%ebp),%ebx
801090d4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090d7:	89 d0                	mov    %edx,%eax
801090d9:	c1 e0 02             	shl    $0x2,%eax
801090dc:	01 d0                	add    %edx,%eax
801090de:	c1 e0 02             	shl    $0x2,%eax
801090e1:	01 d8                	add    %ebx,%eax
801090e3:	05 a0 00 00 00       	add    $0xa0,%eax
801090e8:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
801090ea:	8b 45 10             	mov    0x10(%ebp),%eax
801090ed:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801090f3:	8d 50 01             	lea    0x1(%eax),%edx
801090f6:	8b 45 10             	mov    0x10(%ebp),%eax
801090f9:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
801090ff:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109103:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010910a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010910d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109110:	0f 82 42 fe ff ff    	jb     80108f58 <copyuvm+0x61>
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
80109116:	e9 92 00 00 00       	jmp    801091ad <copyuvm+0x2b6>
    np->pagesMetaData[j].va = (char *) -1;
8010911b:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010911e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109121:	89 d0                	mov    %edx,%eax
80109123:	c1 e0 02             	shl    $0x2,%eax
80109126:	01 d0                	add    %edx,%eax
80109128:	c1 e0 02             	shl    $0x2,%eax
8010912b:	01 c8                	add    %ecx,%eax
8010912d:	05 90 00 00 00       	add    $0x90,%eax
80109132:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
80109138:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010913b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010913e:	89 d0                	mov    %edx,%eax
80109140:	c1 e0 02             	shl    $0x2,%eax
80109143:	01 d0                	add    %edx,%eax
80109145:	c1 e0 02             	shl    $0x2,%eax
80109148:	01 c8                	add    %ecx,%eax
8010914a:	05 94 00 00 00       	add    $0x94,%eax
8010914f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109155:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109158:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010915b:	89 d0                	mov    %edx,%eax
8010915d:	c1 e0 02             	shl    $0x2,%eax
80109160:	01 d0                	add    %edx,%eax
80109162:	c1 e0 02             	shl    $0x2,%eax
80109165:	01 c8                	add    %ecx,%eax
80109167:	05 98 00 00 00       	add    $0x98,%eax
8010916c:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109172:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109175:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109178:	89 d0                	mov    %edx,%eax
8010917a:	c1 e0 02             	shl    $0x2,%eax
8010917d:	01 d0                	add    %edx,%eax
8010917f:	c1 e0 02             	shl    $0x2,%eax
80109182:	01 c8                	add    %ecx,%eax
80109184:	05 9c 00 00 00       	add    $0x9c,%eax
80109189:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
8010918f:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109192:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109195:	89 d0                	mov    %edx,%eax
80109197:	c1 e0 02             	shl    $0x2,%eax
8010919a:	01 d0                	add    %edx,%eax
8010919c:	c1 e0 02             	shl    $0x2,%eax
8010919f:	01 c8                	add    %ecx,%eax
801091a1:	05 a0 00 00 00       	add    $0xa0,%eax
801091a6:	c6 00 80             	movb   $0x80,(%eax)
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
801091a9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801091ad:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801091b1:	0f 86 64 ff ff ff    	jbe    8010911b <copyuvm+0x224>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
801091b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091ba:	eb 18                	jmp    801091d4 <copyuvm+0x2dd>

  bad:
  freevm(d,0);
801091bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801091c3:	00 
801091c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091c7:	89 04 24             	mov    %eax,(%esp)
801091ca:	e8 3e fc ff ff       	call   80108e0d <freevm>
  return 0;
801091cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
801091d4:	83 c4 44             	add    $0x44,%esp
801091d7:	5b                   	pop    %ebx
801091d8:	5d                   	pop    %ebp
801091d9:	c3                   	ret    

801091da <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801091da:	55                   	push   %ebp
801091db:	89 e5                	mov    %esp,%ebp
801091dd:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801091e0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091e7:	00 
801091e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801091eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801091ef:	8b 45 08             	mov    0x8(%ebp),%eax
801091f2:	89 04 24             	mov    %eax,(%esp)
801091f5:	e8 93 f2 ff ff       	call   8010848d <walkpgdir>
801091fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801091fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109200:	8b 00                	mov    (%eax),%eax
80109202:	83 e0 01             	and    $0x1,%eax
80109205:	85 c0                	test   %eax,%eax
80109207:	75 07                	jne    80109210 <uva2ka+0x36>
    return 0;
80109209:	b8 00 00 00 00       	mov    $0x0,%eax
8010920e:	eb 25                	jmp    80109235 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109210:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109213:	8b 00                	mov    (%eax),%eax
80109215:	83 e0 04             	and    $0x4,%eax
80109218:	85 c0                	test   %eax,%eax
8010921a:	75 07                	jne    80109223 <uva2ka+0x49>
    return 0;
8010921c:	b8 00 00 00 00       	mov    $0x0,%eax
80109221:	eb 12                	jmp    80109235 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109226:	8b 00                	mov    (%eax),%eax
80109228:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010922d:	89 04 24             	mov    %eax,(%esp)
80109230:	e8 d5 ed ff ff       	call   8010800a <p2v>
}
80109235:	c9                   	leave  
80109236:	c3                   	ret    

80109237 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109237:	55                   	push   %ebp
80109238:	89 e5                	mov    %esp,%ebp
8010923a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010923d:	8b 45 10             	mov    0x10(%ebp),%eax
80109240:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109243:	e9 87 00 00 00       	jmp    801092cf <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80109248:	8b 45 0c             	mov    0xc(%ebp),%eax
8010924b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109250:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109253:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109256:	89 44 24 04          	mov    %eax,0x4(%esp)
8010925a:	8b 45 08             	mov    0x8(%ebp),%eax
8010925d:	89 04 24             	mov    %eax,(%esp)
80109260:	e8 75 ff ff ff       	call   801091da <uva2ka>
80109265:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109268:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010926c:	75 07                	jne    80109275 <copyout+0x3e>
      return -1;
8010926e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109273:	eb 69                	jmp    801092de <copyout+0xa7>
    n = PGSIZE - (va - va0);
80109275:	8b 45 0c             	mov    0xc(%ebp),%eax
80109278:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010927b:	29 c2                	sub    %eax,%edx
8010927d:	89 d0                	mov    %edx,%eax
8010927f:	05 00 10 00 00       	add    $0x1000,%eax
80109284:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109287:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010928a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010928d:	76 06                	jbe    80109295 <copyout+0x5e>
      n = len;
8010928f:	8b 45 14             	mov    0x14(%ebp),%eax
80109292:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109295:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109298:	8b 55 0c             	mov    0xc(%ebp),%edx
8010929b:	29 c2                	sub    %eax,%edx
8010929d:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092a0:	01 c2                	add    %eax,%edx
801092a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801092a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801092b0:	89 14 24             	mov    %edx,(%esp)
801092b3:	e8 29 c8 ff ff       	call   80105ae1 <memmove>
    len -= n;
801092b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092bb:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801092be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092c1:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801092c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092c7:	05 00 10 00 00       	add    $0x1000,%eax
801092cc:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801092cf:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801092d3:	0f 85 6f ff ff ff    	jne    80109248 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801092d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092de:	c9                   	leave  
801092df:	c3                   	ret    

801092e0 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
801092e0:	55                   	push   %ebp
801092e1:	89 e5                	mov    %esp,%ebp
801092e3:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801092e6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801092ed:	eb 52                	jmp    80109341 <findNextOpenPage+0x61>
    found = 1;
801092ef:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092f6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801092fd:	eb 2d                	jmp    8010932c <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
801092ff:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109306:	8b 55 f8             	mov    -0x8(%ebp),%edx
80109309:	89 d0                	mov    %edx,%eax
8010930b:	c1 e0 02             	shl    $0x2,%eax
8010930e:	01 d0                	add    %edx,%eax
80109310:	c1 e0 02             	shl    $0x2,%eax
80109313:	01 c8                	add    %ecx,%eax
80109315:	05 98 00 00 00       	add    $0x98,%eax
8010931a:	8b 00                	mov    (%eax),%eax
8010931c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
8010931f:	75 07                	jne    80109328 <findNextOpenPage+0x48>
        found = 0;
80109321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
80109328:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010932c:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
80109330:	7e cd                	jle    801092ff <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
80109332:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80109336:	74 02                	je     8010933a <findNextOpenPage+0x5a>
      break;
80109338:	eb 10                	jmp    8010934a <findNextOpenPage+0x6a>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
8010933a:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
80109341:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
80109348:	7e a5                	jle    801092ef <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      break;
    }
  }
  return i;
8010934a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010934d:	c9                   	leave  
8010934e:	c3                   	ret    

8010934f <existOnDisc>:

int
existOnDisc(uint faultingPage){
8010934f:	55                   	push   %ebp
80109350:	89 e5                	mov    %esp,%ebp
80109352:	83 ec 28             	sub    $0x28,%esp
  cprintf("faulting page: %x\n",faultingPage);
80109355:	8b 45 08             	mov    0x8(%ebp),%eax
80109358:	89 44 24 04          	mov    %eax,0x4(%esp)
8010935c:	c7 04 24 ac a4 10 80 	movl   $0x8010a4ac,(%esp)
80109363:	e8 38 70 ff ff       	call   801003a0 <cprintf>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
80109368:	8b 55 08             	mov    0x8(%ebp),%edx
8010936b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109371:	8b 40 04             	mov    0x4(%eax),%eax
80109374:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010937b:	00 
8010937c:	89 54 24 04          	mov    %edx,0x4(%esp)
80109380:	89 04 24             	mov    %eax,(%esp)
80109383:	e8 05 f1 ff ff       	call   8010848d <walkpgdir>
80109388:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
8010938b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  for(i = 0; i < 30; i++){
80109392:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80109399:	e9 8e 00 00 00       	jmp    8010942c <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
8010939e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093a5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093a8:	89 d0                	mov    %edx,%eax
801093aa:	c1 e0 02             	shl    $0x2,%eax
801093ad:	01 d0                	add    %edx,%eax
801093af:	c1 e0 02             	shl    $0x2,%eax
801093b2:	01 c8                	add    %ecx,%eax
801093b4:	05 90 00 00 00       	add    $0x90,%eax
801093b9:	8b 00                	mov    (%eax),%eax
801093bb:	83 f8 ff             	cmp    $0xffffffff,%eax
801093be:	74 68                	je     80109428 <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
801093c0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093c7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093ca:	89 d0                	mov    %edx,%eax
801093cc:	c1 e0 02             	shl    $0x2,%eax
801093cf:	01 d0                	add    %edx,%eax
801093d1:	c1 e0 02             	shl    $0x2,%eax
801093d4:	01 c8                	add    %ecx,%eax
801093d6:	05 90 00 00 00       	add    $0x90,%eax
801093db:	8b 00                	mov    (%eax),%eax
801093dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093e2:	3b 45 08             	cmp    0x8(%ebp),%eax
801093e5:	77 41                	ja     80109428 <existOnDisc+0xd9>
801093e7:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093ee:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093f1:	89 d0                	mov    %edx,%eax
801093f3:	c1 e0 02             	shl    $0x2,%eax
801093f6:	01 d0                	add    %edx,%eax
801093f8:	c1 e0 02             	shl    $0x2,%eax
801093fb:	01 c8                	add    %ecx,%eax
801093fd:	05 90 00 00 00       	add    $0x90,%eax
80109402:	8b 00                	mov    (%eax),%eax
80109404:	05 ff 0f 00 00       	add    $0xfff,%eax
80109409:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010940e:	3b 45 08             	cmp    0x8(%ebp),%eax
80109411:	72 15                	jb     80109428 <existOnDisc+0xd9>
80109413:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109416:	8b 00                	mov    (%eax),%eax
80109418:	25 00 02 00 00       	and    $0x200,%eax
8010941d:	85 c0                	test   %eax,%eax
8010941f:	74 07                	je     80109428 <existOnDisc+0xd9>
        found = 1;
80109421:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  cprintf("faulting page: %x\n",faultingPage);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  for(i = 0; i < 30; i++){
80109428:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010942c:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109430:	0f 8e 68 ff ff ff    	jle    8010939e <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
80109436:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80109439:	c9                   	leave  
8010943a:	c3                   	ret    

8010943b <fixPage>:

void
fixPage(uint faultingPage){
8010943b:	55                   	push   %ebp
8010943c:	89 e5                	mov    %esp,%ebp
8010943e:	81 ec 38 10 00 00    	sub    $0x1038,%esp
  int i;
  char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
80109444:	e8 10 9e ff ff       	call   80103259 <kalloc>
80109449:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
8010944c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109450:	75 0c                	jne    8010945e <fixPage+0x23>
    panic("no room, go away");
80109452:	c7 04 24 bf a4 10 80 	movl   $0x8010a4bf,(%esp)
80109459:	e8 dc 70 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
8010945e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109465:	00 
80109466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010946d:	00 
8010946e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109471:	89 04 24             	mov    %eax,(%esp)
80109474:	e8 99 c5 ff ff       	call   80105a12 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
80109479:	8b 55 08             	mov    0x8(%ebp),%edx
8010947c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109482:	8b 40 04             	mov    0x4(%eax),%eax
80109485:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010948c:	00 
8010948d:	89 54 24 04          	mov    %edx,0x4(%esp)
80109491:	89 04 24             	mov    %eax,(%esp)
80109494:	e8 f4 ef ff ff       	call   8010848d <walkpgdir>
80109499:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
8010949c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094a3:	e9 90 01 00 00       	jmp    80109638 <fixPage+0x1fd>
    if(proc->pagesMetaData[i].va != (char *) -1){
801094a8:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094b2:	89 d0                	mov    %edx,%eax
801094b4:	c1 e0 02             	shl    $0x2,%eax
801094b7:	01 d0                	add    %edx,%eax
801094b9:	c1 e0 02             	shl    $0x2,%eax
801094bc:	01 c8                	add    %ecx,%eax
801094be:	05 90 00 00 00       	add    $0x90,%eax
801094c3:	8b 00                	mov    (%eax),%eax
801094c5:	83 f8 ff             	cmp    $0xffffffff,%eax
801094c8:	0f 84 66 01 00 00    	je     80109634 <fixPage+0x1f9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
801094ce:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094d8:	89 d0                	mov    %edx,%eax
801094da:	c1 e0 02             	shl    $0x2,%eax
801094dd:	01 d0                	add    %edx,%eax
801094df:	c1 e0 02             	shl    $0x2,%eax
801094e2:	01 c8                	add    %ecx,%eax
801094e4:	05 90 00 00 00       	add    $0x90,%eax
801094e9:	8b 00                	mov    (%eax),%eax
801094eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094f0:	3b 45 08             	cmp    0x8(%ebp),%eax
801094f3:	0f 87 3b 01 00 00    	ja     80109634 <fixPage+0x1f9>
801094f9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109500:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109503:	89 d0                	mov    %edx,%eax
80109505:	c1 e0 02             	shl    $0x2,%eax
80109508:	01 d0                	add    %edx,%eax
8010950a:	c1 e0 02             	shl    $0x2,%eax
8010950d:	01 c8                	add    %ecx,%eax
8010950f:	05 90 00 00 00       	add    $0x90,%eax
80109514:	8b 00                	mov    (%eax),%eax
80109516:	05 ff 0f 00 00       	add    $0xfff,%eax
8010951b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109520:	3b 45 08             	cmp    0x8(%ebp),%eax
80109523:	0f 82 0b 01 00 00    	jb     80109634 <fixPage+0x1f9>
80109529:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010952c:	8b 00                	mov    (%eax),%eax
8010952e:	25 00 02 00 00       	and    $0x200,%eax
80109533:	85 c0                	test   %eax,%eax
80109535:	0f 84 f9 00 00 00    	je     80109634 <fixPage+0x1f9>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
8010953b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109542:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109545:	89 d0                	mov    %edx,%eax
80109547:	c1 e0 02             	shl    $0x2,%eax
8010954a:	01 d0                	add    %edx,%eax
8010954c:	c1 e0 02             	shl    $0x2,%eax
8010954f:	01 c8                	add    %ecx,%eax
80109551:	05 98 00 00 00       	add    $0x98,%eax
80109556:	8b 00                	mov    (%eax),%eax
80109558:	89 44 24 04          	mov    %eax,0x4(%esp)
8010955c:	c7 04 24 d0 a4 10 80 	movl   $0x8010a4d0,(%esp)
80109563:	e8 38 6e ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,buf,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
80109568:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010956f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109572:	89 d0                	mov    %edx,%eax
80109574:	c1 e0 02             	shl    $0x2,%eax
80109577:	01 d0                	add    %edx,%eax
80109579:	c1 e0 02             	shl    $0x2,%eax
8010957c:	01 c8                	add    %ecx,%eax
8010957e:	05 98 00 00 00       	add    $0x98,%eax
80109583:	8b 00                	mov    (%eax),%eax
80109585:	89 c2                	mov    %eax,%edx
80109587:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010958d:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109594:	00 
80109595:	89 54 24 08          	mov    %edx,0x8(%esp)
80109599:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
8010959f:	89 54 24 04          	mov    %edx,0x4(%esp)
801095a3:	89 04 24             	mov    %eax,(%esp)
801095a6:	e8 d5 93 ff ff       	call   80102980 <readFromSwapFile>
801095ab:	83 f8 ff             	cmp    $0xffffffff,%eax
801095ae:	75 0c                	jne    801095bc <fixPage+0x181>
          panic("nothing read");
801095b0:	c7 04 24 da a4 10 80 	movl   $0x8010a4da,(%esp)
801095b7:	e8 7e 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1)  //need to swap out
801095bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801095c2:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801095c8:	83 f8 0e             	cmp    $0xe,%eax
801095cb:	76 05                	jbe    801095d2 <fixPage+0x197>
          swapOut();
801095cd:	e8 f4 00 00 00       	call   801096c6 <swapOut>
        proc->pagesMetaData[i].isPhysical = 1;
801095d2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095dc:	89 d0                	mov    %edx,%eax
801095de:	c1 e0 02             	shl    $0x2,%eax
801095e1:	01 d0                	add    %edx,%eax
801095e3:	c1 e0 02             	shl    $0x2,%eax
801095e6:	01 c8                	add    %ecx,%eax
801095e8:	05 94 00 00 00       	add    $0x94,%eax
801095ed:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  //TODO here?
801095f3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095fd:	89 d0                	mov    %edx,%eax
801095ff:	c1 e0 02             	shl    $0x2,%eax
80109602:	01 d0                	add    %edx,%eax
80109604:	c1 e0 02             	shl    $0x2,%eax
80109607:	01 c8                	add    %ecx,%eax
80109609:	05 a0 00 00 00       	add    $0xa0,%eax
8010960e:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
80109611:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109618:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010961b:	89 d0                	mov    %edx,%eax
8010961d:	c1 e0 02             	shl    $0x2,%eax
80109620:	01 d0                	add    %edx,%eax
80109622:	c1 e0 02             	shl    $0x2,%eax
80109625:	01 c8                	add    %ecx,%eax
80109627:	05 98 00 00 00       	add    $0x98,%eax
8010962c:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
80109632:	eb 0e                	jmp    80109642 <fixPage+0x207>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80109634:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109638:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
8010963c:	0f 8e 66 fe ff ff    	jle    801094a8 <fixPage+0x6d>
        proc->pagesMetaData[i].fileOffset = -1;
        break;
      }
    }
  }    
    memmove(mem,buf,PGSIZE);
80109642:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109649:	00 
8010964a:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
80109650:	89 44 24 04          	mov    %eax,0x4(%esp)
80109654:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109657:	89 04 24             	mov    %eax,(%esp)
8010965a:	e8 82 c4 ff ff       	call   80105ae1 <memmove>
    *pte &= ~PTE_PG;  //turn off flag
8010965f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109662:	8b 00                	mov    (%eax),%eax
80109664:	80 e4 fd             	and    $0xfd,%ah
80109667:	89 c2                	mov    %eax,%edx
80109669:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010966c:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
8010966e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109671:	89 04 24             	mov    %eax,(%esp)
80109674:	e8 84 e9 ff ff       	call   80107ffd <v2p>
80109679:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010967c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109683:	8b 52 04             	mov    0x4(%edx),%edx
80109686:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010968d:	00 
8010968e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109692:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109699:	00 
8010969a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010969e:	89 14 24             	mov    %edx,(%esp)
801096a1:	e8 89 ee ff ff       	call   8010852f <mappages>
    memmove(buf,0,PGSIZE);
801096a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801096ad:	00 
801096ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801096b5:	00 
801096b6:	8d 85 ec ef ff ff    	lea    -0x1014(%ebp),%eax
801096bc:	89 04 24             	mov    %eax,(%esp)
801096bf:	e8 1d c4 ff ff       	call   80105ae1 <memmove>
  }
801096c4:	c9                   	leave  
801096c5:	c3                   	ret    

801096c6 <swapOut>:

//swap out a page from proc.
  void swapOut(){
801096c6:	55                   	push   %ebp
801096c7:	89 e5                	mov    %esp,%ebp
801096c9:	53                   	push   %ebx
801096ca:	81 ec 44 10 00 00    	sub    $0x1044,%esp
    int j;
    int offset;
    char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    int index = -1;
801096d0:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
801096d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801096dd:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
801096e3:	83 c0 03             	add    $0x3,%eax
801096e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    char minNFU = 0x80;
801096e9:	c6 45 eb 80          	movb   $0x80,-0x15(%ebp)
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
801096ed:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801096f4:	e9 df 00 00 00       	jmp    801097d8 <swapOut+0x112>
          if(proc->pagesMetaData[j].isPhysical && proc->pagesMetaData[j].count < min){  //found smaller
801096f9:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109700:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109703:	89 d0                	mov    %edx,%eax
80109705:	c1 e0 02             	shl    $0x2,%eax
80109708:	01 d0                	add    %edx,%eax
8010970a:	c1 e0 02             	shl    $0x2,%eax
8010970d:	01 c8                	add    %ecx,%eax
8010970f:	05 94 00 00 00       	add    $0x94,%eax
80109714:	8b 00                	mov    (%eax),%eax
80109716:	85 c0                	test   %eax,%eax
80109718:	0f 84 b6 00 00 00    	je     801097d4 <swapOut+0x10e>
8010971e:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109725:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109728:	89 d0                	mov    %edx,%eax
8010972a:	c1 e0 02             	shl    $0x2,%eax
8010972d:	01 d0                	add    %edx,%eax
8010972f:	c1 e0 02             	shl    $0x2,%eax
80109732:	01 c8                	add    %ecx,%eax
80109734:	05 9c 00 00 00       	add    $0x9c,%eax
80109739:	8b 00                	mov    (%eax),%eax
8010973b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010973e:	0f 8d 90 00 00 00    	jge    801097d4 <swapOut+0x10e>
            min = proc->pagesMetaData[j].count;
80109744:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010974b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010974e:	89 d0                	mov    %edx,%eax
80109750:	c1 e0 02             	shl    $0x2,%eax
80109753:	01 d0                	add    %edx,%eax
80109755:	c1 e0 02             	shl    $0x2,%eax
80109758:	01 c8                	add    %ecx,%eax
8010975a:	05 9c 00 00 00       	add    $0x9c,%eax
8010975f:	8b 00                	mov    (%eax),%eax
80109761:	89 45 ec             	mov    %eax,-0x14(%ebp)
            index = j;
80109764:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109767:	89 45 f0             	mov    %eax,-0x10(%ebp)
            cprintf("currently i'm choosing %x has count %d\n",proc->pagesMetaData[index],proc->pagesMetaData[index].count);
8010976a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109771:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109774:	89 d0                	mov    %edx,%eax
80109776:	c1 e0 02             	shl    $0x2,%eax
80109779:	01 d0                	add    %edx,%eax
8010977b:	c1 e0 02             	shl    $0x2,%eax
8010977e:	01 c8                	add    %ecx,%eax
80109780:	05 9c 00 00 00       	add    $0x9c,%eax
80109785:	8b 00                	mov    (%eax),%eax
80109787:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010978e:	89 44 24 18          	mov    %eax,0x18(%esp)
80109792:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109795:	89 d0                	mov    %edx,%eax
80109797:	c1 e0 02             	shl    $0x2,%eax
8010979a:	01 d0                	add    %edx,%eax
8010979c:	c1 e0 02             	shl    $0x2,%eax
8010979f:	01 c8                	add    %ecx,%eax
801097a1:	05 90 00 00 00       	add    $0x90,%eax
801097a6:	8b 10                	mov    (%eax),%edx
801097a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801097ac:	8b 50 04             	mov    0x4(%eax),%edx
801097af:	89 54 24 08          	mov    %edx,0x8(%esp)
801097b3:	8b 50 08             	mov    0x8(%eax),%edx
801097b6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801097ba:	8b 50 0c             	mov    0xc(%eax),%edx
801097bd:	89 54 24 10          	mov    %edx,0x10(%esp)
801097c1:	8b 40 10             	mov    0x10(%eax),%eax
801097c4:	89 44 24 14          	mov    %eax,0x14(%esp)
801097c8:	c7 04 24 e8 a4 10 80 	movl   $0x8010a4e8,(%esp)
801097cf:	e8 cc 6b ff ff       	call   801003a0 <cprintf>
      //TODO!!!:in places of move out dont do it and dont use the array at all.

      return;

      case 2: //FIFO
        for(j=3; j<30; j++){  //find the oldest page
801097d4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801097d8:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
801097dc:	0f 8e 17 ff ff ff    	jle    801096f9 <swapOut+0x33>
            min = proc->pagesMetaData[j].count;
            index = j;
            cprintf("currently i'm choosing %x has count %d\n",proc->pagesMetaData[index],proc->pagesMetaData[index].count);
          }
        }
        break;
801097e2:	90                   	nop
        }
        break;
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
801097e3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097ed:	89 d0                	mov    %edx,%eax
801097ef:	c1 e0 02             	shl    $0x2,%eax
801097f2:	01 d0                	add    %edx,%eax
801097f4:	c1 e0 02             	shl    $0x2,%eax
801097f7:	01 c8                	add    %ecx,%eax
801097f9:	05 94 00 00 00       	add    $0x94,%eax
801097fe:	8b 00                	mov    (%eax),%eax
80109800:	85 c0                	test   %eax,%eax
80109802:	0f 84 bf 01 00 00    	je     801099c7 <swapOut+0x301>
      //cprintf("choose to swap out %x\n",proc->pagesMetaData[index].va);
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
80109808:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010980f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109812:	89 d0                	mov    %edx,%eax
80109814:	c1 e0 02             	shl    $0x2,%eax
80109817:	01 d0                	add    %edx,%eax
80109819:	c1 e0 02             	shl    $0x2,%eax
8010981c:	01 c8                	add    %ecx,%eax
8010981e:	05 90 00 00 00       	add    $0x90,%eax
80109823:	8b 00                	mov    (%eax),%eax
80109825:	89 04 24             	mov    %eax,(%esp)
80109828:	e8 b3 fa ff ff       	call   801092e0 <findNextOpenPage>
8010982d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      //cprintf("after offset\n");
      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
80109830:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109837:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010983a:	89 d0                	mov    %edx,%eax
8010983c:	c1 e0 02             	shl    $0x2,%eax
8010983f:	01 d0                	add    %edx,%eax
80109841:	c1 e0 02             	shl    $0x2,%eax
80109844:	01 c8                	add    %ecx,%eax
80109846:	05 90 00 00 00       	add    $0x90,%eax
8010984b:	8b 10                	mov    (%eax),%edx
8010984d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109853:	8b 40 04             	mov    0x4(%eax),%eax
80109856:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010985d:	00 
8010985e:	89 54 24 04          	mov    %edx,0x4(%esp)
80109862:	89 04 24             	mov    %eax,(%esp)
80109865:	e8 23 ec ff ff       	call   8010848d <walkpgdir>
8010986a:	89 45 e0             	mov    %eax,-0x20(%ebp)
      //cprintf("after walkpgdir\n");
      if(!(*pte & PTE_PG)){
8010986d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109870:	8b 00                	mov    (%eax),%eax
80109872:	25 00 02 00 00       	and    $0x200,%eax
80109877:	85 c0                	test   %eax,%eax
80109879:	75 0f                	jne    8010988a <swapOut+0x1c4>
        *pte |= PTE_PG; //turn on    
8010987b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010987e:	8b 00                	mov    (%eax),%eax
80109880:	80 cc 02             	or     $0x2,%ah
80109883:	89 c2                	mov    %eax,%edx
80109885:	8b 45 e0             	mov    -0x20(%ebp),%eax
80109888:	89 10                	mov    %edx,(%eax)
      }
      //cprintf("after setting PG\n");
      proc->pagesMetaData[index].fileOffset = offset;
8010988a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109891:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109894:	89 d0                	mov    %edx,%eax
80109896:	c1 e0 02             	shl    $0x2,%eax
80109899:	01 d0                	add    %edx,%eax
8010989b:	c1 e0 02             	shl    $0x2,%eax
8010989e:	01 c8                	add    %ecx,%eax
801098a0:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
801098a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801098a9:	89 02                	mov    %eax,(%edx)
      proc->pagesMetaData[index].isPhysical = 0;
801098ab:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801098b2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098b5:	89 d0                	mov    %edx,%eax
801098b7:	c1 e0 02             	shl    $0x2,%eax
801098ba:	01 d0                	add    %edx,%eax
801098bc:	c1 e0 02             	shl    $0x2,%eax
801098bf:	01 c8                	add    %ecx,%eax
801098c1:	05 94 00 00 00       	add    $0x94,%eax
801098c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
801098cc:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
801098d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098d9:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
801098df:	8b 55 f0             	mov    -0x10(%ebp),%edx
801098e2:	89 d0                	mov    %edx,%eax
801098e4:	c1 e0 02             	shl    $0x2,%eax
801098e7:	01 d0                	add    %edx,%eax
801098e9:	c1 e0 02             	shl    $0x2,%eax
801098ec:	01 d8                	add    %ebx,%eax
801098ee:	05 9c 00 00 00       	add    $0x9c,%eax
801098f3:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
801098f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801098fb:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80109901:	83 c2 01             	add    $0x1,%edx
80109904:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      memmove(buf,proc->pagesMetaData[index].va,PGSIZE);
8010990a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109911:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109914:	89 d0                	mov    %edx,%eax
80109916:	c1 e0 02             	shl    $0x2,%eax
80109919:	01 d0                	add    %edx,%eax
8010991b:	c1 e0 02             	shl    $0x2,%eax
8010991e:	01 c8                	add    %ecx,%eax
80109920:	05 90 00 00 00       	add    $0x90,%eax
80109925:	8b 00                	mov    (%eax),%eax
80109927:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010992e:	00 
8010992f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109933:	8d 85 dc ef ff ff    	lea    -0x1024(%ebp),%eax
80109939:	89 04 24             	mov    %eax,(%esp)
8010993c:	e8 a0 c1 ff ff       	call   80105ae1 <memmove>
      //cprintf("after memmove\n");
      writeToSwapFile(proc,buf,offset,PGSIZE);
80109941:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80109944:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010994a:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
80109951:	00 
80109952:	89 54 24 08          	mov    %edx,0x8(%esp)
80109956:	8d 95 dc ef ff ff    	lea    -0x1024(%ebp),%edx
8010995c:	89 54 24 04          	mov    %edx,0x4(%esp)
80109960:	89 04 24             	mov    %eax,(%esp)
80109963:	e8 e8 8f ff ff       	call   80102950 <writeToSwapFile>
      //cprintf("after write\n");
      pa = PTE_ADDR(*pte);
80109968:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010996b:	8b 00                	mov    (%eax),%eax
8010996d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109972:	89 45 dc             	mov    %eax,-0x24(%ebp)
      cprintf("after pa\n");
80109975:	c7 04 24 10 a5 10 80 	movl   $0x8010a510,(%esp)
8010997c:	e8 1f 6a ff ff       	call   801003a0 <cprintf>
      if(pa == 0)
80109981:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80109985:	75 0c                	jne    80109993 <swapOut+0x2cd>
        panic("kfree swapOut");
80109987:	c7 04 24 1a a5 10 80 	movl   $0x8010a51a,(%esp)
8010998e:	e8 a7 6b ff ff       	call   8010053a <panic>
      kfree((char *)p2v(pa)); 
80109993:	8b 45 dc             	mov    -0x24(%ebp),%eax
80109996:	89 04 24             	mov    %eax,(%esp)
80109999:	e8 6c e6 ff ff       	call   8010800a <p2v>
8010999e:	89 04 24             	mov    %eax,(%esp)
801099a1:	e8 c0 97 ff ff       	call   80103166 <kfree>
      cprintf("after kfree\n");
801099a6:	c7 04 24 28 a5 10 80 	movl   $0x8010a528,(%esp)
801099ad:	e8 ee 69 ff ff       	call   801003a0 <cprintf>
      *pte = 0 | PTE_W | PTE_U | PTE_PG;
801099b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801099b5:	c7 00 06 02 00 00    	movl   $0x206,(%eax)
      cprintf("after pte\n");
801099bb:	c7 04 24 35 a5 10 80 	movl   $0x8010a535,(%esp)
801099c2:	e8 d9 69 ff ff       	call   801003a0 <cprintf>
    }
  }
801099c7:	81 c4 44 10 00 00    	add    $0x1044,%esp
801099cd:	5b                   	pop    %ebx
801099ce:	5d                   	pop    %ebp
801099cf:	c3                   	ret    

801099d0 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
801099d0:	55                   	push   %ebp
801099d1:	89 e5                	mov    %esp,%ebp
801099d3:	53                   	push   %ebx
801099d4:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
801099d7:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
801099de:	e9 c8 00 00 00       	jmp    80109aab <updateAge+0xdb>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=0){ //only if on RAM
801099e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
801099e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801099e9:	89 d0                	mov    %edx,%eax
801099eb:	c1 e0 02             	shl    $0x2,%eax
801099ee:	01 d0                	add    %edx,%eax
801099f0:	c1 e0 02             	shl    $0x2,%eax
801099f3:	01 c8                	add    %ecx,%eax
801099f5:	05 94 00 00 00       	add    $0x94,%eax
801099fa:	8b 00                	mov    (%eax),%eax
801099fc:	85 c0                	test   %eax,%eax
801099fe:	0f 84 a3 00 00 00    	je     80109aa7 <updateAge+0xd7>
80109a04:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a07:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a0a:	89 d0                	mov    %edx,%eax
80109a0c:	c1 e0 02             	shl    $0x2,%eax
80109a0f:	01 d0                	add    %edx,%eax
80109a11:	c1 e0 02             	shl    $0x2,%eax
80109a14:	01 c8                	add    %ecx,%eax
80109a16:	05 90 00 00 00       	add    $0x90,%eax
80109a1b:	8b 00                	mov    (%eax),%eax
80109a1d:	85 c0                	test   %eax,%eax
80109a1f:	0f 84 82 00 00 00    	je     80109aa7 <updateAge+0xd7>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
80109a25:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a28:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a2b:	89 d0                	mov    %edx,%eax
80109a2d:	c1 e0 02             	shl    $0x2,%eax
80109a30:	01 d0                	add    %edx,%eax
80109a32:	c1 e0 02             	shl    $0x2,%eax
80109a35:	01 c8                	add    %ecx,%eax
80109a37:	05 a0 00 00 00       	add    $0xa0,%eax
80109a3c:	0f b6 00             	movzbl (%eax),%eax
80109a3f:	d0 f8                	sar    %al
80109a41:	89 c1                	mov    %eax,%ecx
80109a43:	8b 5d 08             	mov    0x8(%ebp),%ebx
80109a46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a49:	89 d0                	mov    %edx,%eax
80109a4b:	c1 e0 02             	shl    $0x2,%eax
80109a4e:	01 d0                	add    %edx,%eax
80109a50:	c1 e0 02             	shl    $0x2,%eax
80109a53:	01 d8                	add    %ebx,%eax
80109a55:	05 a0 00 00 00       	add    $0xa0,%eax
80109a5a:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
80109a5c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a62:	89 d0                	mov    %edx,%eax
80109a64:	c1 e0 02             	shl    $0x2,%eax
80109a67:	01 d0                	add    %edx,%eax
80109a69:	c1 e0 02             	shl    $0x2,%eax
80109a6c:	01 c8                	add    %ecx,%eax
80109a6e:	05 90 00 00 00       	add    $0x90,%eax
80109a73:	8b 10                	mov    (%eax),%edx
80109a75:	8b 45 08             	mov    0x8(%ebp),%eax
80109a78:	8b 40 04             	mov    0x4(%eax),%eax
80109a7b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109a82:	00 
80109a83:	89 54 24 04          	mov    %edx,0x4(%esp)
80109a87:	89 04 24             	mov    %eax,(%esp)
80109a8a:	e8 fe e9 ff ff       	call   8010848d <walkpgdir>
80109a8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if(!(*pte & PTE_A)){
80109a92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a95:	8b 00                	mov    (%eax),%eax
80109a97:	83 e0 20             	and    $0x20,%eax
80109a9a:	85 c0                	test   %eax,%eax
80109a9c:	75 09                	jne    80109aa7 <updateAge+0xd7>
          *pte &= !PTE_A; //turn off bit 
80109a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109aa1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
80109aa7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109aab:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109aaf:	0f 8e 2e ff ff ff    	jle    801099e3 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
        if(!(*pte & PTE_A)){
          *pte &= !PTE_A; //turn off bit 
      }
    }
  }
80109ab5:	83 c4 24             	add    $0x24,%esp
80109ab8:	5b                   	pop    %ebx
80109ab9:	5d                   	pop    %ebp
80109aba:	c3                   	ret    

80109abb <clearAllPages>:

void
clearAllPages(struct proc *p){
80109abb:	55                   	push   %ebp
80109abc:	89 e5                	mov    %esp,%ebp
80109abe:	83 ec 28             	sub    $0x28,%esp
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109ac1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109ac8:	e9 cd 00 00 00       	jmp    80109b9a <clearAllPages+0xdf>
    if(p->pagesMetaData[i].va != (char *) -1){
80109acd:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109ad0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109ad3:	89 d0                	mov    %edx,%eax
80109ad5:	c1 e0 02             	shl    $0x2,%eax
80109ad8:	01 d0                	add    %edx,%eax
80109ada:	c1 e0 02             	shl    $0x2,%eax
80109add:	01 c8                	add    %ecx,%eax
80109adf:	05 90 00 00 00       	add    $0x90,%eax
80109ae4:	8b 00                	mov    (%eax),%eax
80109ae6:	83 f8 ff             	cmp    $0xffffffff,%eax
80109ae9:	0f 84 a7 00 00 00    	je     80109b96 <clearAllPages+0xdb>
      pte = walkpgdir(p->pgdir,proc->pagesMetaData[i].va,0);
80109aef:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109af6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109af9:	89 d0                	mov    %edx,%eax
80109afb:	c1 e0 02             	shl    $0x2,%eax
80109afe:	01 d0                	add    %edx,%eax
80109b00:	c1 e0 02             	shl    $0x2,%eax
80109b03:	01 c8                	add    %ecx,%eax
80109b05:	05 90 00 00 00       	add    $0x90,%eax
80109b0a:	8b 10                	mov    (%eax),%edx
80109b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80109b0f:	8b 40 04             	mov    0x4(%eax),%eax
80109b12:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109b19:	00 
80109b1a:	89 54 24 04          	mov    %edx,0x4(%esp)
80109b1e:	89 04 24             	mov    %eax,(%esp)
80109b21:	e8 67 e9 ff ff       	call   8010848d <walkpgdir>
80109b26:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(!pte){
80109b29:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109b2d:	74 67                	je     80109b96 <clearAllPages+0xdb>

      }
      else if((*pte & PTE_P) != 0){
80109b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b32:	8b 00                	mov    (%eax),%eax
80109b34:	83 e0 01             	and    $0x1,%eax
80109b37:	85 c0                	test   %eax,%eax
80109b39:	74 5b                	je     80109b96 <clearAllPages+0xdb>
        pa = PTE_ADDR(*pte);
80109b3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b3e:	8b 00                	mov    (%eax),%eax
80109b40:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109b45:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if(pa == 0){
80109b48:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109b4c:	75 0e                	jne    80109b5c <clearAllPages+0xa1>
          cprintf("already free\n");
80109b4e:	c7 04 24 40 a5 10 80 	movl   $0x8010a540,(%esp)
80109b55:	e8 46 68 ff ff       	call   801003a0 <cprintf>
80109b5a:	eb 3a                	jmp    80109b96 <clearAllPages+0xdb>
        }
        else{
          cprintf("clearing\n");
80109b5c:	c7 04 24 4e a5 10 80 	movl   $0x8010a54e,(%esp)
80109b63:	e8 38 68 ff ff       	call   801003a0 <cprintf>
          char *v = p2v(pa);
80109b68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109b6b:	89 04 24             	mov    %eax,(%esp)
80109b6e:	e8 97 e4 ff ff       	call   8010800a <p2v>
80109b73:	89 45 e8             	mov    %eax,-0x18(%ebp)
          kfree(v);
80109b76:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109b79:	89 04 24             	mov    %eax,(%esp)
80109b7c:	e8 e5 95 ff ff       	call   80103166 <kfree>
          *pte = 0;
80109b81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109b84:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
          cprintf("finished\n");
80109b8a:	c7 04 24 58 a5 10 80 	movl   $0x8010a558,(%esp)
80109b91:	e8 0a 68 ff ff       	call   801003a0 <cprintf>
void
clearAllPages(struct proc *p){
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109b96:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109b9a:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109b9e:	0f 8e 29 ff ff ff    	jle    80109acd <clearAllPages+0x12>
          cprintf("finished\n");
        }
      }
    }
  }
}
80109ba4:	c9                   	leave  
80109ba5:	c3                   	ret    
