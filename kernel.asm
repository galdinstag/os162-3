
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
8010002d:	b8 bd 3e 10 80       	mov    $0x80103ebd,%eax
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
8010003a:	c7 44 24 04 50 9b 10 	movl   $0x80109b50,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
80100049:	e8 46 57 00 00       	call   80105794 <initlock>

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
801000bd:	e8 f3 56 00 00       	call   801057b5 <acquire>

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
80100104:	e8 0e 57 00 00       	call   80105817 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 e6 10 	movl   $0x8010e660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 3f 53 00 00       	call   80105463 <sleep>
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
8010017c:	e8 96 56 00 00       	call   80105817 <release>
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
80100198:	c7 04 24 57 9b 10 80 	movl   $0x80109b57,(%esp)
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
801001d3:	e8 0a 2d 00 00       	call   80102ee2 <iderw>
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
801001ef:	c7 04 24 68 9b 10 80 	movl   $0x80109b68,(%esp)
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
80100210:	e8 cd 2c 00 00       	call   80102ee2 <iderw>
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
80100229:	c7 04 24 6f 9b 10 80 	movl   $0x80109b6f,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
8010023c:	e8 74 55 00 00       	call   801057b5 <acquire>

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
8010029d:	e8 9d 52 00 00       	call   8010553f <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 e6 10 80 	movl   $0x8010e660,(%esp)
801002a9:	e8 69 55 00 00       	call   80105817 <release>
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
801003bb:	e8 f5 53 00 00       	call   801057b5 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 76 9b 10 80 	movl   $0x80109b76,(%esp)
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
801004b0:	c7 45 ec 7f 9b 10 80 	movl   $0x80109b7f,-0x14(%ebp)
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
80100533:	e8 df 52 00 00       	call   80105817 <release>
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
8010055f:	c7 04 24 86 9b 10 80 	movl   $0x80109b86,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 95 9b 10 80 	movl   $0x80109b95,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 d2 52 00 00       	call   80105866 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 97 9b 10 80 	movl   $0x80109b97,(%esp)
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
80100699:	c7 04 24 9b 9b 10 80 	movl   $0x80109b9b,(%esp)
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
801006cd:	e8 06 54 00 00       	call   80105ad8 <memmove>
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
801006fc:	e8 08 53 00 00       	call   80105a09 <memset>
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
80100791:	e8 d0 6c 00 00       	call   80107466 <uartputc>
80100796:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010079d:	e8 c4 6c 00 00       	call   80107466 <uartputc>
801007a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007a9:	e8 b8 6c 00 00       	call   80107466 <uartputc>
801007ae:	eb 0b                	jmp    801007bb <consputc+0x50>
  } else
    uartputc(c);
801007b0:	8b 45 08             	mov    0x8(%ebp),%eax
801007b3:	89 04 24             	mov    %eax,(%esp)
801007b6:	e8 ab 6c 00 00       	call   80107466 <uartputc>
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
801007dc:	e8 d4 4f 00 00       	call   801057b5 <acquire>
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
80100917:	e8 23 4c 00 00       	call   8010553f <wakeup>
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
80100938:	e8 da 4e 00 00       	call   80105817 <release>
  if(doprocdump) {
8010093d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100941:	74 05                	je     80100948 <consoleintr+0x180>
    procdump();  // now call procdump() wo. cons.lock held
80100943:	e8 9d 4c 00 00       	call   801055e5 <procdump>
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
80100968:	e8 48 4e 00 00       	call   801057b5 <acquire>
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
80100988:	e8 8a 4e 00 00       	call   80105817 <release>
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
801009b1:	e8 ad 4a 00 00       	call   80105463 <sleep>

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
80100a2d:	e8 e5 4d 00 00       	call   80105817 <release>
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
80100a61:	e8 4f 4d 00 00       	call   801057b5 <acquire>
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
80100a9b:	e8 77 4d 00 00       	call   80105817 <release>
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
80100ab6:	c7 44 24 04 ae 9b 10 	movl   $0x80109bae,0x4(%esp)
80100abd:	80 
80100abe:	c7 04 24 c0 d5 10 80 	movl   $0x8010d5c0,(%esp)
80100ac5:	e8 ca 4c 00 00       	call   80105794 <initlock>

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
80100aef:	e8 61 3a 00 00       	call   80104555 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100af4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100afb:	00 
80100afc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100b03:	e8 96 25 00 00       	call   8010309e <ioapicenable>
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
80100b13:	e8 9e 30 00 00       	call   80103bb6 <begin_op>
  if((ip = namei(path)) == 0){
80100b18:	8b 45 08             	mov    0x8(%ebp),%eax
80100b1b:	89 04 24             	mov    %eax,(%esp)
80100b1e:	e8 47 1a 00 00       	call   8010256a <namei>
80100b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b2a:	75 0f                	jne    80100b3b <exec+0x31>
    end_op();
80100b2c:	e8 09 31 00 00       	call   80103c3a <end_op>
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
80100b8e:	e8 24 7a 00 00       	call   801085b7 <setupkvm>
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
80100ccf:	e8 b1 7c 00 00       	call   80108985 <allocuvm>
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
80100d0d:	e8 88 7b 00 00       	call   8010889a <loaduvm>
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
80100d46:	e8 ef 2e 00 00       	call   80103c3a <end_op>
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
80100d86:	e8 fa 7b 00 00       	call   80108985 <allocuvm>
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
80100dab:	e8 c8 80 00 00       	call   80108e78 <clearpteu>
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
80100de1:	e8 8d 4e 00 00       	call   80105c73 <strlen>
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
80100e0a:	e8 64 4e 00 00       	call   80105c73 <strlen>
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
80100e3a:	e8 bf 83 00 00       	call   801091fe <copyout>
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
80100ee1:	e8 18 83 00 00       	call   801091fe <copyout>
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
80100f39:	e8 eb 4c 00 00       	call   80105c29 <safestrcpy>

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
80100fb5:	e8 ee 76 00 00       	call   801086a8 <switchuvm>
  freevm(oldpgdir,0);
80100fba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100fc1:	00 
80100fc2:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100fc5:	89 04 24             	mov    %eax,(%esp)
80100fc8:	e8 07 7e 00 00       	call   80108dd4 <freevm>
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
80100fe8:	e8 e7 7d 00 00       	call   80108dd4 <freevm>
  if(ip){
80100fed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ff1:	74 10                	je     80101003 <exec+0x4f9>
    iunlockput(ip);
80100ff3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ff6:	89 04 24             	mov    %eax,(%esp)
80100ff9:	e8 45 0c 00 00       	call   80101c43 <iunlockput>
    end_op();
80100ffe:	e8 37 2c 00 00       	call   80103c3a <end_op>
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
80101010:	c7 44 24 04 b6 9b 10 	movl   $0x80109bb6,0x4(%esp)
80101017:	80 
80101018:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
8010101f:	e8 70 47 00 00       	call   80105794 <initlock>
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
80101033:	e8 7d 47 00 00       	call   801057b5 <acquire>
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
8010105c:	e8 b6 47 00 00       	call   80105817 <release>
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
8010107a:	e8 98 47 00 00       	call   80105817 <release>
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
80101093:	e8 1d 47 00 00       	call   801057b5 <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <filedup+0x28>
    panic("filedup");
801010a2:	c7 04 24 bd 9b 10 80 	movl   $0x80109bbd,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  f->ref++;
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 01             	lea    0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801010bd:	c7 04 24 20 28 11 80 	movl   $0x80112820,(%esp)
801010c4:	e8 4e 47 00 00       	call   80105817 <release>
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
801010db:	e8 d5 46 00 00       	call   801057b5 <acquire>
  if(f->ref < 1)
801010e0:	8b 45 08             	mov    0x8(%ebp),%eax
801010e3:	8b 40 04             	mov    0x4(%eax),%eax
801010e6:	85 c0                	test   %eax,%eax
801010e8:	7f 0c                	jg     801010f6 <fileclose+0x28>
    panic("fileclose");
801010ea:	c7 04 24 c5 9b 10 80 	movl   $0x80109bc5,(%esp)
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
80101116:	e8 fc 46 00 00       	call   80105817 <release>
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
80101160:	e8 b2 46 00 00       	call   80105817 <release>
  
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
8010117e:	e8 82 36 00 00       	call   80104805 <pipeclose>
80101183:	eb 1d                	jmp    801011a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101185:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101188:	83 f8 02             	cmp    $0x2,%eax
8010118b:	75 15                	jne    801011a2 <fileclose+0xd4>
    begin_op();
8010118d:	e8 24 2a 00 00       	call   80103bb6 <begin_op>
    iput(ff.ip);
80101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 d5 09 00 00       	call   80101b72 <iput>
    end_op();
8010119d:	e8 98 2a 00 00       	call   80103c3a <end_op>
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
8010122f:	e8 52 37 00 00       	call   80104986 <piperead>
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
801012a1:	c7 04 24 cf 9b 10 80 	movl   $0x80109bcf,(%esp)
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
801012ec:	e8 a6 35 00 00       	call   80104897 <pipewrite>
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
80101332:	e8 7f 28 00 00       	call   80103bb6 <begin_op>
      ilock(f->ip);
80101337:	8b 45 08             	mov    0x8(%ebp),%eax
8010133a:	8b 40 10             	mov    0x10(%eax),%eax
8010133d:	89 04 24             	mov    %eax,(%esp)
80101340:	e8 74 06 00 00       	call   801019b9 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0){
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
      }
      iunlock(f->ip);
8010138a:	8b 45 08             	mov    0x8(%ebp),%eax
8010138d:	8b 40 10             	mov    0x10(%eax),%eax
80101390:	89 04 24             	mov    %eax,(%esp)
80101393:	e8 75 07 00 00       	call   80101b0d <iunlock>
      end_op();
80101398:	e8 9d 28 00 00       	call   80103c3a <end_op>

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
801013ad:	c7 04 24 d8 9b 10 80 	movl   $0x80109bd8,(%esp)
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
801013df:	c7 04 24 e8 9b 10 80 	movl   $0x80109be8,(%esp)
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
80101425:	e8 ae 46 00 00       	call   80105ad8 <memmove>
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
8010146b:	e8 99 45 00 00       	call   80105a09 <memset>
  log_write(bp);
80101470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101473:	89 04 24             	mov    %eax,(%esp)
80101476:	e8 46 29 00 00       	call   80103dc1 <log_write>
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
80101541:	e8 7b 28 00 00       	call   80103dc1 <log_write>
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
801015b8:	c7 04 24 f4 9b 10 80 	movl   $0x80109bf4,(%esp)
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
80101647:	c7 04 24 0a 9c 10 80 	movl   $0x80109c0a,(%esp)
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
8010167f:	e8 3d 27 00 00       	call   80103dc1 <log_write>
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
8010169a:	c7 44 24 04 1d 9c 10 	movl   $0x80109c1d,0x4(%esp)
801016a1:	80 
801016a2:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801016a9:	e8 e6 40 00 00       	call   80105794 <initlock>
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
8010170e:	c7 04 24 24 9c 10 80 	movl   $0x80109c24,(%esp)
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
80101791:	e8 73 42 00 00       	call   80105a09 <memset>
      dip->type = type;
80101796:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101799:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
8010179d:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 16 26 00 00       	call   80103dc1 <log_write>
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
801017e9:	c7 04 24 77 9c 10 80 	movl   $0x80109c77,(%esp)
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
80101898:	e8 3b 42 00 00       	call   80105ad8 <memmove>
  log_write(bp);
8010189d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018a0:	89 04 24             	mov    %eax,(%esp)
801018a3:	e8 19 25 00 00       	call   80103dc1 <log_write>
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
801018c2:	e8 ee 3e 00 00       	call   801057b5 <acquire>

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
8010190c:	e8 06 3f 00 00       	call   80105817 <release>
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
8010193f:	c7 04 24 89 9c 10 80 	movl   $0x80109c89,(%esp)
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
8010197d:	e8 95 3e 00 00       	call   80105817 <release>

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
80101994:	e8 1c 3e 00 00       	call   801057b5 <acquire>
  ip->ref++;
80101999:	8b 45 08             	mov    0x8(%ebp),%eax
8010199c:	8b 40 08             	mov    0x8(%eax),%eax
8010199f:	8d 50 01             	lea    0x1(%eax),%edx
801019a2:	8b 45 08             	mov    0x8(%ebp),%eax
801019a5:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019a8:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019af:	e8 63 3e 00 00       	call   80105817 <release>
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
801019cf:	c7 04 24 99 9c 10 80 	movl   $0x80109c99,(%esp)
801019d6:	e8 5f eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019db:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
801019e2:	e8 ce 3d 00 00       	call   801057b5 <acquire>
  while(ip->flags & I_BUSY)
801019e7:	eb 13                	jmp    801019fc <ilock+0x43>
    sleep(ip, &icache.lock);
801019e9:	c7 44 24 04 40 32 11 	movl   $0x80113240,0x4(%esp)
801019f0:	80 
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	89 04 24             	mov    %eax,(%esp)
801019f7:	e8 67 3a 00 00       	call   80105463 <sleep>

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
80101a21:	e8 f1 3d 00 00       	call   80105817 <release>

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
80101ad2:	e8 01 40 00 00       	call   80105ad8 <memmove>
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
80101aff:	c7 04 24 9f 9c 10 80 	movl   $0x80109c9f,(%esp)
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
80101b30:	c7 04 24 ae 9c 10 80 	movl   $0x80109cae,(%esp)
80101b37:	e8 fe e9 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101b3c:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b43:	e8 6d 3c 00 00       	call   801057b5 <acquire>
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
80101b5f:	e8 db 39 00 00       	call   8010553f <wakeup>
  release(&icache.lock);
80101b64:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101b6b:	e8 a7 3c 00 00       	call   80105817 <release>
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
80101b7f:	e8 31 3c 00 00       	call   801057b5 <acquire>
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
80101bbd:	c7 04 24 b6 9c 10 80 	movl   $0x80109cb6,(%esp)
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
80101be1:	e8 31 3c 00 00       	call   80105817 <release>
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
80101c0c:	e8 a4 3b 00 00       	call   801057b5 <acquire>
    ip->flags = 0;
80101c11:	8b 45 08             	mov    0x8(%ebp),%eax
80101c14:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	89 04 24             	mov    %eax,(%esp)
80101c21:	e8 19 39 00 00       	call   8010553f <wakeup>
  }
  ip->ref--;
80101c26:	8b 45 08             	mov    0x8(%ebp),%eax
80101c29:	8b 40 08             	mov    0x8(%eax),%eax
80101c2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c32:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c35:	c7 04 24 40 32 11 80 	movl   $0x80113240,(%esp)
80101c3c:	e8 d6 3b 00 00       	call   80105817 <release>
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
80101d47:	e8 75 20 00 00       	call   80103dc1 <log_write>
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
80101d5c:	c7 04 24 c0 9c 10 80 	movl   $0x80109cc0,(%esp)
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
80101ffd:	e8 d6 3a 00 00       	call   80105ad8 <memmove>
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
8010215c:	e8 77 39 00 00       	call   80105ad8 <memmove>
    log_write(bp);
80102161:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102164:	89 04 24             	mov    %eax,(%esp)
80102167:	e8 55 1c 00 00       	call   80103dc1 <log_write>
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
801021da:	e8 9c 39 00 00       	call   80105b7b <strncmp>
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
801021f4:	c7 04 24 d3 9c 10 80 	movl   $0x80109cd3,(%esp)
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
80102232:	c7 04 24 e5 9c 10 80 	movl   $0x80109ce5,(%esp)
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
80102317:	c7 04 24 e5 9c 10 80 	movl   $0x80109ce5,(%esp)
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
8010235c:	e8 70 38 00 00       	call   80105bd1 <strncpy>
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
8010238e:	c7 04 24 f2 9c 10 80 	movl   $0x80109cf2,(%esp)
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
80102413:	e8 c0 36 00 00       	call   80105ad8 <memmove>
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
8010242e:	e8 a5 36 00 00       	call   80105ad8 <memmove>
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
8010267d:	c7 44 24 04 fa 9c 10 	movl   $0x80109cfa,0x4(%esp)
80102684:	80 
80102685:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80102688:	89 04 24             	mov    %eax,(%esp)
8010268b:	e8 48 34 00 00       	call   80105ad8 <memmove>
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
801026ca:	e8 e7 14 00 00       	call   80103bb6 <begin_op>
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
801026ea:	e8 4b 15 00 00       	call   80103c3a <end_op>
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
80102704:	c7 44 24 04 01 9d 10 	movl   $0x80109d01,0x4(%esp)
8010270b:	80 
8010270c:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010270f:	89 04 24             	mov    %eax,(%esp)
80102712:	e8 a8 fa ff ff       	call   801021bf <namecmp>
80102717:	85 c0                	test   %eax,%eax
80102719:	0f 84 45 01 00 00    	je     80102864 <removeSwapFile+0x1f5>
8010271f:	c7 44 24 04 03 9d 10 	movl   $0x80109d03,0x4(%esp)
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
80102778:	c7 04 24 06 9d 10 80 	movl   $0x80109d06,(%esp)
8010277f:	e8 b6 dd ff ff       	call   8010053a <panic>
	if(ip->type == T_DIR && !isdirempty(ip)){
80102784:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102787:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010278b:	66 83 f8 01          	cmp    $0x1,%ax
8010278f:	75 1f                	jne    801027b0 <removeSwapFile+0x141>
80102791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102794:	89 04 24             	mov    %eax,(%esp)
80102797:	e8 47 3b 00 00       	call   801062e3 <isdirempty>
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
801027c6:	e8 3e 32 00 00       	call   80105a09 <memset>
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
801027f1:	c7 04 24 18 9d 10 80 	movl   $0x80109d18,(%esp)
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
80102858:	e8 dd 13 00 00       	call   80103c3a <end_op>

	return 0;
8010285d:	b8 00 00 00 00       	mov    $0x0,%eax
80102862:	eb 15                	jmp    80102879 <removeSwapFile+0x20a>

	bad:
		iunlockput(dp);
80102864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102867:	89 04 24             	mov    %eax,(%esp)
8010286a:	e8 d4 f3 ff ff       	call   80101c43 <iunlockput>
		end_op();
8010286f:	e8 c6 13 00 00       	call   80103c3a <end_op>
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
80102889:	c7 44 24 04 fa 9c 10 	movl   $0x80109cfa,0x4(%esp)
80102890:	80 
80102891:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80102894:	89 04 24             	mov    %eax,(%esp)
80102897:	e8 3c 32 00 00       	call   80105ad8 <memmove>
	itoa(p->pid, path+ 6);
8010289c:	8b 45 08             	mov    0x8(%ebp),%eax
8010289f:	8b 40 10             	mov    0x10(%eax),%eax
801028a2:	8d 55 e6             	lea    -0x1a(%ebp),%edx
801028a5:	83 c2 06             	add    $0x6,%edx
801028a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801028ac:	89 04 24             	mov    %eax,(%esp)
801028af:	e8 fa fc ff ff       	call   801025ae <itoa>

    begin_op();
801028b4:	e8 fd 12 00 00       	call   80103bb6 <begin_op>
    struct inode * in = create(path, T_FILE, 0, 0);
801028b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801028c0:	00 
801028c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801028c8:	00 
801028c9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801028d0:	00 
801028d1:	8d 45 e6             	lea    -0x1a(%ebp),%eax
801028d4:	89 04 24             	mov    %eax,(%esp)
801028d7:	e8 4d 3c 00 00       	call   80106529 <create>
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
801028ff:	c7 04 24 27 9d 10 80 	movl   $0x80109d27,(%esp)
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
80102944:	e8 f1 12 00 00       	call   80103c3a <end_op>

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
801029b4:	81 ec 24 04 00 00    	sub    $0x424,%esp
   char buf[1024];
  //parent have swap file, copy it
    if(from->swapFile){
801029ba:	8b 45 08             	mov    0x8(%ebp),%eax
801029bd:	8b 40 7c             	mov    0x7c(%eax),%eax
801029c0:	85 c0                	test   %eax,%eax
801029c2:	0f 84 83 01 00 00    	je     80102b4b <copySwapFile+0x19b>
      int j,k;
      for(j = 0; j < 30; j++){
801029c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029cf:	e9 6d 01 00 00       	jmp    80102b41 <copySwapFile+0x191>
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
801029f4:	0f 84 43 01 00 00    	je     80102b3d <copySwapFile+0x18d>
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
80102a21:	c7 04 24 43 9d 10 80 	movl   $0x80109d43,(%esp)
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
          for(k = 0; k < 4; k++){//move only 1024 bytes chunks
80102a5f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102a66:	e9 c8 00 00 00       	jmp    80102b33 <copySwapFile+0x183>
            if(readFromSwapFile(from,buf,from->pagesMetaData[j].fileOffset + 1024*k,1024) == -1)
80102a6b:	8b 4d 08             	mov    0x8(%ebp),%ecx
80102a6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a71:	89 d0                	mov    %edx,%eax
80102a73:	c1 e0 02             	shl    $0x2,%eax
80102a76:	01 d0                	add    %edx,%eax
80102a78:	c1 e0 02             	shl    $0x2,%eax
80102a7b:	01 c8                	add    %ecx,%eax
80102a7d:	05 98 00 00 00       	add    $0x98,%eax
80102a82:	8b 00                	mov    (%eax),%eax
80102a84:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102a87:	c1 e2 0a             	shl    $0xa,%edx
80102a8a:	01 d0                	add    %edx,%eax
80102a8c:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
80102a93:	00 
80102a94:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a98:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
80102a9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102aa2:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa5:	89 04 24             	mov    %eax,(%esp)
80102aa8:	e8 d3 fe ff ff       	call   80102980 <readFromSwapFile>
80102aad:	83 f8 ff             	cmp    $0xffffffff,%eax
80102ab0:	75 0c                	jne    80102abe <copySwapFile+0x10e>
              panic("can't read swap file"); 
80102ab2:	c7 04 24 59 9d 10 80 	movl   $0x80109d59,(%esp)
80102ab9:	e8 7c da ff ff       	call   8010053a <panic>
            if(writeToSwapFile(to,buf,to->pagesMetaData[j].fileOffset + 1024*k,1024) == -1)
80102abe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102ac1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ac4:	89 d0                	mov    %edx,%eax
80102ac6:	c1 e0 02             	shl    $0x2,%eax
80102ac9:	01 d0                	add    %edx,%eax
80102acb:	c1 e0 02             	shl    $0x2,%eax
80102ace:	01 c8                	add    %ecx,%eax
80102ad0:	05 98 00 00 00       	add    $0x98,%eax
80102ad5:	8b 00                	mov    (%eax),%eax
80102ad7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ada:	c1 e2 0a             	shl    $0xa,%edx
80102add:	01 d0                	add    %edx,%eax
80102adf:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
80102ae6:	00 
80102ae7:	89 44 24 08          	mov    %eax,0x8(%esp)
80102aeb:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
80102af1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102af5:	8b 45 0c             	mov    0xc(%ebp),%eax
80102af8:	89 04 24             	mov    %eax,(%esp)
80102afb:	e8 50 fe ff ff       	call   80102950 <writeToSwapFile>
80102b00:	83 f8 ff             	cmp    $0xffffffff,%eax
80102b03:	75 0c                	jne    80102b11 <copySwapFile+0x161>
              panic("can't write swap file");
80102b05:	c7 04 24 6e 9d 10 80 	movl   $0x80109d6e,(%esp)
80102b0c:	e8 29 da ff ff       	call   8010053a <panic>
           memmove(buf,0,1024);//elapse buf
80102b11:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
80102b18:	00 
80102b19:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b20:	00 
80102b21:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
80102b27:	89 04 24             	mov    %eax,(%esp)
80102b2a:	e8 a9 2f 00 00       	call   80105ad8 <memmove>
      int j,k;
      for(j = 0; j < 30; j++){
        if(proc->pagesMetaData[j].fileOffset != -1){
          cprintf("something here %d %d\n",from->pid,from->pagesMetaData[j].fileOffset);
          to->pagesMetaData[j].fileOffset = from->pagesMetaData[j].fileOffset;
          for(k = 0; k < 4; k++){//move only 1024 bytes chunks
80102b2f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b33:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
80102b37:	0f 8e 2e ff ff ff    	jle    80102a6b <copySwapFile+0xbb>
copySwapFile(struct proc *from, struct proc *to){
   char buf[1024];
  //parent have swap file, copy it
    if(from->swapFile){
      int j,k;
      for(j = 0; j < 30; j++){
80102b3d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b41:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80102b45:	0f 8e 89 fe ff ff    	jle    801029d4 <copySwapFile+0x24>
           memmove(buf,0,1024);//elapse buf
         }
        }
      }
    }
80102b4b:	81 c4 24 04 00 00    	add    $0x424,%esp
80102b51:	5b                   	pop    %ebx
80102b52:	5d                   	pop    %ebp
80102b53:	c3                   	ret    

80102b54 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b54:	55                   	push   %ebp
80102b55:	89 e5                	mov    %esp,%ebp
80102b57:	83 ec 14             	sub    $0x14,%esp
80102b5a:	8b 45 08             	mov    0x8(%ebp),%eax
80102b5d:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b61:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b65:	89 c2                	mov    %eax,%edx
80102b67:	ec                   	in     (%dx),%al
80102b68:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b6b:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b6f:	c9                   	leave  
80102b70:	c3                   	ret    

80102b71 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102b71:	55                   	push   %ebp
80102b72:	89 e5                	mov    %esp,%ebp
80102b74:	57                   	push   %edi
80102b75:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102b76:	8b 55 08             	mov    0x8(%ebp),%edx
80102b79:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b7c:	8b 45 10             	mov    0x10(%ebp),%eax
80102b7f:	89 cb                	mov    %ecx,%ebx
80102b81:	89 df                	mov    %ebx,%edi
80102b83:	89 c1                	mov    %eax,%ecx
80102b85:	fc                   	cld    
80102b86:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b88:	89 c8                	mov    %ecx,%eax
80102b8a:	89 fb                	mov    %edi,%ebx
80102b8c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b8f:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b92:	5b                   	pop    %ebx
80102b93:	5f                   	pop    %edi
80102b94:	5d                   	pop    %ebp
80102b95:	c3                   	ret    

80102b96 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b96:	55                   	push   %ebp
80102b97:	89 e5                	mov    %esp,%ebp
80102b99:	83 ec 08             	sub    $0x8,%esp
80102b9c:	8b 55 08             	mov    0x8(%ebp),%edx
80102b9f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ba2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102ba6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ba9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102bad:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102bb1:	ee                   	out    %al,(%dx)
}
80102bb2:	c9                   	leave  
80102bb3:	c3                   	ret    

80102bb4 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102bb4:	55                   	push   %ebp
80102bb5:	89 e5                	mov    %esp,%ebp
80102bb7:	56                   	push   %esi
80102bb8:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102bb9:	8b 55 08             	mov    0x8(%ebp),%edx
80102bbc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102bbf:	8b 45 10             	mov    0x10(%ebp),%eax
80102bc2:	89 cb                	mov    %ecx,%ebx
80102bc4:	89 de                	mov    %ebx,%esi
80102bc6:	89 c1                	mov    %eax,%ecx
80102bc8:	fc                   	cld    
80102bc9:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102bcb:	89 c8                	mov    %ecx,%eax
80102bcd:	89 f3                	mov    %esi,%ebx
80102bcf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102bd2:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102bd5:	5b                   	pop    %ebx
80102bd6:	5e                   	pop    %esi
80102bd7:	5d                   	pop    %ebp
80102bd8:	c3                   	ret    

80102bd9 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102bd9:	55                   	push   %ebp
80102bda:	89 e5                	mov    %esp,%ebp
80102bdc:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102bdf:	90                   	nop
80102be0:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102be7:	e8 68 ff ff ff       	call   80102b54 <inb>
80102bec:	0f b6 c0             	movzbl %al,%eax
80102bef:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102bf2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bf5:	25 c0 00 00 00       	and    $0xc0,%eax
80102bfa:	83 f8 40             	cmp    $0x40,%eax
80102bfd:	75 e1                	jne    80102be0 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102bff:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102c03:	74 11                	je     80102c16 <idewait+0x3d>
80102c05:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c08:	83 e0 21             	and    $0x21,%eax
80102c0b:	85 c0                	test   %eax,%eax
80102c0d:	74 07                	je     80102c16 <idewait+0x3d>
    return -1;
80102c0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c14:	eb 05                	jmp    80102c1b <idewait+0x42>
  return 0;
80102c16:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102c1b:	c9                   	leave  
80102c1c:	c3                   	ret    

80102c1d <ideinit>:

void
ideinit(void)
{
80102c1d:	55                   	push   %ebp
80102c1e:	89 e5                	mov    %esp,%ebp
80102c20:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102c23:	c7 44 24 04 84 9d 10 	movl   $0x80109d84,0x4(%esp)
80102c2a:	80 
80102c2b:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102c32:	e8 5d 2b 00 00       	call   80105794 <initlock>
  picenable(IRQ_IDE);
80102c37:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c3e:	e8 12 19 00 00       	call   80104555 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102c43:	a1 40 49 11 80       	mov    0x80114940,%eax
80102c48:	83 e8 01             	sub    $0x1,%eax
80102c4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c4f:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102c56:	e8 43 04 00 00       	call   8010309e <ioapicenable>
  idewait(0);
80102c5b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c62:	e8 72 ff ff ff       	call   80102bd9 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102c67:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102c6e:	00 
80102c6f:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c76:	e8 1b ff ff ff       	call   80102b96 <outb>
  for(i=0; i<1000; i++){
80102c7b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c82:	eb 20                	jmp    80102ca4 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c84:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c8b:	e8 c4 fe ff ff       	call   80102b54 <inb>
80102c90:	84 c0                	test   %al,%al
80102c92:	74 0c                	je     80102ca0 <ideinit+0x83>
      havedisk1 = 1;
80102c94:	c7 05 38 d6 10 80 01 	movl   $0x1,0x8010d638
80102c9b:	00 00 00 
      break;
80102c9e:	eb 0d                	jmp    80102cad <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102ca0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102ca4:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102cab:	7e d7                	jle    80102c84 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102cad:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102cb4:	00 
80102cb5:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102cbc:	e8 d5 fe ff ff       	call   80102b96 <outb>
}
80102cc1:	c9                   	leave  
80102cc2:	c3                   	ret    

80102cc3 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102cc3:	55                   	push   %ebp
80102cc4:	89 e5                	mov    %esp,%ebp
80102cc6:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102cc9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102ccd:	75 0c                	jne    80102cdb <idestart+0x18>
    panic("idestart");
80102ccf:	c7 04 24 88 9d 10 80 	movl   $0x80109d88,(%esp)
80102cd6:	e8 5f d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102cdb:	8b 45 08             	mov    0x8(%ebp),%eax
80102cde:	8b 40 08             	mov    0x8(%eax),%eax
80102ce1:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102ce6:	76 0c                	jbe    80102cf4 <idestart+0x31>
    panic("incorrect blockno");
80102ce8:	c7 04 24 91 9d 10 80 	movl   $0x80109d91,(%esp)
80102cef:	e8 46 d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102cf4:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102cfb:	8b 45 08             	mov    0x8(%ebp),%eax
80102cfe:	8b 50 08             	mov    0x8(%eax),%edx
80102d01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d04:	0f af c2             	imul   %edx,%eax
80102d07:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102d0a:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102d0e:	7e 0c                	jle    80102d1c <idestart+0x59>
80102d10:	c7 04 24 88 9d 10 80 	movl   $0x80109d88,(%esp)
80102d17:	e8 1e d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102d1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102d23:	e8 b1 fe ff ff       	call   80102bd9 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102d28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102d2f:	00 
80102d30:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102d37:	e8 5a fe ff ff       	call   80102b96 <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d3f:	0f b6 c0             	movzbl %al,%eax
80102d42:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d46:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102d4d:	e8 44 fe ff ff       	call   80102b96 <outb>
  outb(0x1f3, sector & 0xff);
80102d52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d55:	0f b6 c0             	movzbl %al,%eax
80102d58:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d5c:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102d63:	e8 2e fe ff ff       	call   80102b96 <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102d68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d6b:	c1 f8 08             	sar    $0x8,%eax
80102d6e:	0f b6 c0             	movzbl %al,%eax
80102d71:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d75:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102d7c:	e8 15 fe ff ff       	call   80102b96 <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102d81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d84:	c1 f8 10             	sar    $0x10,%eax
80102d87:	0f b6 c0             	movzbl %al,%eax
80102d8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d8e:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102d95:	e8 fc fd ff ff       	call   80102b96 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102d9a:	8b 45 08             	mov    0x8(%ebp),%eax
80102d9d:	8b 40 04             	mov    0x4(%eax),%eax
80102da0:	83 e0 01             	and    $0x1,%eax
80102da3:	c1 e0 04             	shl    $0x4,%eax
80102da6:	89 c2                	mov    %eax,%edx
80102da8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dab:	c1 f8 18             	sar    $0x18,%eax
80102dae:	83 e0 0f             	and    $0xf,%eax
80102db1:	09 d0                	or     %edx,%eax
80102db3:	83 c8 e0             	or     $0xffffffe0,%eax
80102db6:	0f b6 c0             	movzbl %al,%eax
80102db9:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dbd:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102dc4:	e8 cd fd ff ff       	call   80102b96 <outb>
  if(b->flags & B_DIRTY){
80102dc9:	8b 45 08             	mov    0x8(%ebp),%eax
80102dcc:	8b 00                	mov    (%eax),%eax
80102dce:	83 e0 04             	and    $0x4,%eax
80102dd1:	85 c0                	test   %eax,%eax
80102dd3:	74 34                	je     80102e09 <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102dd5:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102ddc:	00 
80102ddd:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102de4:	e8 ad fd ff ff       	call   80102b96 <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102de9:	8b 45 08             	mov    0x8(%ebp),%eax
80102dec:	83 c0 18             	add    $0x18,%eax
80102def:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102df6:	00 
80102df7:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dfb:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e02:	e8 ad fd ff ff       	call   80102bb4 <outsl>
80102e07:	eb 14                	jmp    80102e1d <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102e09:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102e10:	00 
80102e11:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102e18:	e8 79 fd ff ff       	call   80102b96 <outb>
  }
}
80102e1d:	c9                   	leave  
80102e1e:	c3                   	ret    

80102e1f <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102e1f:	55                   	push   %ebp
80102e20:	89 e5                	mov    %esp,%ebp
80102e22:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102e25:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e2c:	e8 84 29 00 00       	call   801057b5 <acquire>
  if((b = idequeue) == 0){
80102e31:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102e36:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102e39:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102e3d:	75 11                	jne    80102e50 <ideintr+0x31>
    release(&idelock);
80102e3f:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102e46:	e8 cc 29 00 00       	call   80105817 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102e4b:	e9 90 00 00 00       	jmp    80102ee0 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e53:	8b 40 14             	mov    0x14(%eax),%eax
80102e56:	a3 34 d6 10 80       	mov    %eax,0x8010d634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102e5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e5e:	8b 00                	mov    (%eax),%eax
80102e60:	83 e0 04             	and    $0x4,%eax
80102e63:	85 c0                	test   %eax,%eax
80102e65:	75 2e                	jne    80102e95 <ideintr+0x76>
80102e67:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e6e:	e8 66 fd ff ff       	call   80102bd9 <idewait>
80102e73:	85 c0                	test   %eax,%eax
80102e75:	78 1e                	js     80102e95 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102e77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e7a:	83 c0 18             	add    $0x18,%eax
80102e7d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e84:	00 
80102e85:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e89:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e90:	e8 dc fc ff ff       	call   80102b71 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e98:	8b 00                	mov    (%eax),%eax
80102e9a:	83 c8 02             	or     $0x2,%eax
80102e9d:	89 c2                	mov    %eax,%edx
80102e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ea2:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102ea4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ea7:	8b 00                	mov    (%eax),%eax
80102ea9:	83 e0 fb             	and    $0xfffffffb,%eax
80102eac:	89 c2                	mov    %eax,%edx
80102eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eb1:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102eb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eb6:	89 04 24             	mov    %eax,(%esp)
80102eb9:	e8 81 26 00 00       	call   8010553f <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102ebe:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ec3:	85 c0                	test   %eax,%eax
80102ec5:	74 0d                	je     80102ed4 <ideintr+0xb5>
    idestart(idequeue);
80102ec7:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102ecc:	89 04 24             	mov    %eax,(%esp)
80102ecf:	e8 ef fd ff ff       	call   80102cc3 <idestart>

  release(&idelock);
80102ed4:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102edb:	e8 37 29 00 00       	call   80105817 <release>
}
80102ee0:	c9                   	leave  
80102ee1:	c3                   	ret    

80102ee2 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102ee2:	55                   	push   %ebp
80102ee3:	89 e5                	mov    %esp,%ebp
80102ee5:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102ee8:	8b 45 08             	mov    0x8(%ebp),%eax
80102eeb:	8b 00                	mov    (%eax),%eax
80102eed:	83 e0 01             	and    $0x1,%eax
80102ef0:	85 c0                	test   %eax,%eax
80102ef2:	75 0c                	jne    80102f00 <iderw+0x1e>
    panic("iderw: buf not busy");
80102ef4:	c7 04 24 a3 9d 10 80 	movl   $0x80109da3,(%esp)
80102efb:	e8 3a d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102f00:	8b 45 08             	mov    0x8(%ebp),%eax
80102f03:	8b 00                	mov    (%eax),%eax
80102f05:	83 e0 06             	and    $0x6,%eax
80102f08:	83 f8 02             	cmp    $0x2,%eax
80102f0b:	75 0c                	jne    80102f19 <iderw+0x37>
    panic("iderw: nothing to do");
80102f0d:	c7 04 24 b7 9d 10 80 	movl   $0x80109db7,(%esp)
80102f14:	e8 21 d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102f19:	8b 45 08             	mov    0x8(%ebp),%eax
80102f1c:	8b 40 04             	mov    0x4(%eax),%eax
80102f1f:	85 c0                	test   %eax,%eax
80102f21:	74 15                	je     80102f38 <iderw+0x56>
80102f23:	a1 38 d6 10 80       	mov    0x8010d638,%eax
80102f28:	85 c0                	test   %eax,%eax
80102f2a:	75 0c                	jne    80102f38 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102f2c:	c7 04 24 cc 9d 10 80 	movl   $0x80109dcc,(%esp)
80102f33:	e8 02 d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102f38:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102f3f:	e8 71 28 00 00       	call   801057b5 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102f44:	8b 45 08             	mov    0x8(%ebp),%eax
80102f47:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102f4e:	c7 45 f4 34 d6 10 80 	movl   $0x8010d634,-0xc(%ebp)
80102f55:	eb 0b                	jmp    80102f62 <iderw+0x80>
80102f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f5a:	8b 00                	mov    (%eax),%eax
80102f5c:	83 c0 14             	add    $0x14,%eax
80102f5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102f62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f65:	8b 00                	mov    (%eax),%eax
80102f67:	85 c0                	test   %eax,%eax
80102f69:	75 ec                	jne    80102f57 <iderw+0x75>
    ;
  *pp = b;
80102f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f6e:	8b 55 08             	mov    0x8(%ebp),%edx
80102f71:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102f73:	a1 34 d6 10 80       	mov    0x8010d634,%eax
80102f78:	3b 45 08             	cmp    0x8(%ebp),%eax
80102f7b:	75 0d                	jne    80102f8a <iderw+0xa8>
    idestart(b);
80102f7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102f80:	89 04 24             	mov    %eax,(%esp)
80102f83:	e8 3b fd ff ff       	call   80102cc3 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f88:	eb 15                	jmp    80102f9f <iderw+0xbd>
80102f8a:	eb 13                	jmp    80102f9f <iderw+0xbd>
    sleep(b, &idelock);
80102f8c:	c7 44 24 04 00 d6 10 	movl   $0x8010d600,0x4(%esp)
80102f93:	80 
80102f94:	8b 45 08             	mov    0x8(%ebp),%eax
80102f97:	89 04 24             	mov    %eax,(%esp)
80102f9a:	e8 c4 24 00 00       	call   80105463 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102fa2:	8b 00                	mov    (%eax),%eax
80102fa4:	83 e0 06             	and    $0x6,%eax
80102fa7:	83 f8 02             	cmp    $0x2,%eax
80102faa:	75 e0                	jne    80102f8c <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102fac:	c7 04 24 00 d6 10 80 	movl   $0x8010d600,(%esp)
80102fb3:	e8 5f 28 00 00       	call   80105817 <release>
}
80102fb8:	c9                   	leave  
80102fb9:	c3                   	ret    

80102fba <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102fba:	55                   	push   %ebp
80102fbb:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fbd:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fc2:	8b 55 08             	mov    0x8(%ebp),%edx
80102fc5:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102fc7:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fcc:	8b 40 10             	mov    0x10(%eax),%eax
}
80102fcf:	5d                   	pop    %ebp
80102fd0:	c3                   	ret    

80102fd1 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102fd1:	55                   	push   %ebp
80102fd2:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102fd4:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fd9:	8b 55 08             	mov    0x8(%ebp),%edx
80102fdc:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102fde:	a1 14 42 11 80       	mov    0x80114214,%eax
80102fe3:	8b 55 0c             	mov    0xc(%ebp),%edx
80102fe6:	89 50 10             	mov    %edx,0x10(%eax)
}
80102fe9:	5d                   	pop    %ebp
80102fea:	c3                   	ret    

80102feb <ioapicinit>:

void
ioapicinit(void)
{
80102feb:	55                   	push   %ebp
80102fec:	89 e5                	mov    %esp,%ebp
80102fee:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102ff1:	a1 44 43 11 80       	mov    0x80114344,%eax
80102ff6:	85 c0                	test   %eax,%eax
80102ff8:	75 05                	jne    80102fff <ioapicinit+0x14>
    return;
80102ffa:	e9 9d 00 00 00       	jmp    8010309c <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102fff:	c7 05 14 42 11 80 00 	movl   $0xfec00000,0x80114214
80103006:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103009:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103010:	e8 a5 ff ff ff       	call   80102fba <ioapicread>
80103015:	c1 e8 10             	shr    $0x10,%eax
80103018:	25 ff 00 00 00       	and    $0xff,%eax
8010301d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103020:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103027:	e8 8e ff ff ff       	call   80102fba <ioapicread>
8010302c:	c1 e8 18             	shr    $0x18,%eax
8010302f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103032:	0f b6 05 40 43 11 80 	movzbl 0x80114340,%eax
80103039:	0f b6 c0             	movzbl %al,%eax
8010303c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010303f:	74 0c                	je     8010304d <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103041:	c7 04 24 ec 9d 10 80 	movl   $0x80109dec,(%esp)
80103048:	e8 53 d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010304d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103054:	eb 3e                	jmp    80103094 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103056:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103059:	83 c0 20             	add    $0x20,%eax
8010305c:	0d 00 00 01 00       	or     $0x10000,%eax
80103061:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103064:	83 c2 08             	add    $0x8,%edx
80103067:	01 d2                	add    %edx,%edx
80103069:	89 44 24 04          	mov    %eax,0x4(%esp)
8010306d:	89 14 24             	mov    %edx,(%esp)
80103070:	e8 5c ff ff ff       	call   80102fd1 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103075:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103078:	83 c0 08             	add    $0x8,%eax
8010307b:	01 c0                	add    %eax,%eax
8010307d:	83 c0 01             	add    $0x1,%eax
80103080:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103087:	00 
80103088:	89 04 24             	mov    %eax,(%esp)
8010308b:	e8 41 ff ff ff       	call   80102fd1 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103090:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103094:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103097:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010309a:	7e ba                	jle    80103056 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
8010309c:	c9                   	leave  
8010309d:	c3                   	ret    

8010309e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010309e:	55                   	push   %ebp
8010309f:	89 e5                	mov    %esp,%ebp
801030a1:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
801030a4:	a1 44 43 11 80       	mov    0x80114344,%eax
801030a9:	85 c0                	test   %eax,%eax
801030ab:	75 02                	jne    801030af <ioapicenable+0x11>
    return;
801030ad:	eb 37                	jmp    801030e6 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801030af:	8b 45 08             	mov    0x8(%ebp),%eax
801030b2:	83 c0 20             	add    $0x20,%eax
801030b5:	8b 55 08             	mov    0x8(%ebp),%edx
801030b8:	83 c2 08             	add    $0x8,%edx
801030bb:	01 d2                	add    %edx,%edx
801030bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801030c1:	89 14 24             	mov    %edx,(%esp)
801030c4:	e8 08 ff ff ff       	call   80102fd1 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801030c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801030cc:	c1 e0 18             	shl    $0x18,%eax
801030cf:	8b 55 08             	mov    0x8(%ebp),%edx
801030d2:	83 c2 08             	add    $0x8,%edx
801030d5:	01 d2                	add    %edx,%edx
801030d7:	83 c2 01             	add    $0x1,%edx
801030da:	89 44 24 04          	mov    %eax,0x4(%esp)
801030de:	89 14 24             	mov    %edx,(%esp)
801030e1:	e8 eb fe ff ff       	call   80102fd1 <ioapicwrite>
}
801030e6:	c9                   	leave  
801030e7:	c3                   	ret    

801030e8 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801030e8:	55                   	push   %ebp
801030e9:	89 e5                	mov    %esp,%ebp
801030eb:	8b 45 08             	mov    0x8(%ebp),%eax
801030ee:	05 00 00 00 80       	add    $0x80000000,%eax
801030f3:	5d                   	pop    %ebp
801030f4:	c3                   	ret    

801030f5 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801030f5:	55                   	push   %ebp
801030f6:	89 e5                	mov    %esp,%ebp
801030f8:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801030fb:	c7 44 24 04 1e 9e 10 	movl   $0x80109e1e,0x4(%esp)
80103102:	80 
80103103:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010310a:	e8 85 26 00 00       	call   80105794 <initlock>
  kmem.use_lock = 0;
8010310f:	c7 05 54 42 11 80 00 	movl   $0x0,0x80114254
80103116:	00 00 00 
  freerange(vstart, vend);
80103119:	8b 45 0c             	mov    0xc(%ebp),%eax
8010311c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103120:	8b 45 08             	mov    0x8(%ebp),%eax
80103123:	89 04 24             	mov    %eax,(%esp)
80103126:	e8 26 00 00 00       	call   80103151 <freerange>
}
8010312b:	c9                   	leave  
8010312c:	c3                   	ret    

8010312d <kinit2>:

void
kinit2(void *vstart, void *vend)
{
8010312d:	55                   	push   %ebp
8010312e:	89 e5                	mov    %esp,%ebp
80103130:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103133:	8b 45 0c             	mov    0xc(%ebp),%eax
80103136:	89 44 24 04          	mov    %eax,0x4(%esp)
8010313a:	8b 45 08             	mov    0x8(%ebp),%eax
8010313d:	89 04 24             	mov    %eax,(%esp)
80103140:	e8 0c 00 00 00       	call   80103151 <freerange>
  kmem.use_lock = 1;
80103145:	c7 05 54 42 11 80 01 	movl   $0x1,0x80114254
8010314c:	00 00 00 
}
8010314f:	c9                   	leave  
80103150:	c3                   	ret    

80103151 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103151:	55                   	push   %ebp
80103152:	89 e5                	mov    %esp,%ebp
80103154:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103157:	8b 45 08             	mov    0x8(%ebp),%eax
8010315a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010315f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103164:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103167:	eb 12                	jmp    8010317b <freerange+0x2a>
    kfree(p);
80103169:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010316c:	89 04 24             	mov    %eax,(%esp)
8010316f:	e8 16 00 00 00       	call   8010318a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103174:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010317b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010317e:	05 00 10 00 00       	add    $0x1000,%eax
80103183:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103186:	76 e1                	jbe    80103169 <freerange+0x18>
    kfree(p);
}
80103188:	c9                   	leave  
80103189:	c3                   	ret    

8010318a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
8010318a:	55                   	push   %ebp
8010318b:	89 e5                	mov    %esp,%ebp
8010318d:	83 ec 28             	sub    $0x28,%esp
  // if(getPid()){
  //   cprintf("%x\n",v);
  // }
  struct run *r;
  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP){
80103190:	8b 45 08             	mov    0x8(%ebp),%eax
80103193:	25 ff 0f 00 00       	and    $0xfff,%eax
80103198:	85 c0                	test   %eax,%eax
8010319a:	75 1b                	jne    801031b7 <kfree+0x2d>
8010319c:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
801031a3:	72 12                	jb     801031b7 <kfree+0x2d>
801031a5:	8b 45 08             	mov    0x8(%ebp),%eax
801031a8:	89 04 24             	mov    %eax,(%esp)
801031ab:	e8 38 ff ff ff       	call   801030e8 <v2p>
801031b0:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031b5:	76 50                	jbe    80103207 <kfree+0x7d>
    cprintf("v:%d end:%d uint v:%d ",(uint)v % PGSIZE,v < end,v2p(v) >= PHYSTOP);
801031b7:	8b 45 08             	mov    0x8(%ebp),%eax
801031ba:	89 04 24             	mov    %eax,(%esp)
801031bd:	e8 26 ff ff ff       	call   801030e8 <v2p>
801031c2:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801031c7:	0f 97 c0             	seta   %al
801031ca:	0f b6 d0             	movzbl %al,%edx
801031cd:	81 7d 08 5c 0d 12 80 	cmpl   $0x80120d5c,0x8(%ebp)
801031d4:	0f 92 c0             	setb   %al
801031d7:	0f b6 c0             	movzbl %al,%eax
801031da:	8b 4d 08             	mov    0x8(%ebp),%ecx
801031dd:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
801031e3:	89 54 24 0c          	mov    %edx,0xc(%esp)
801031e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801031eb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801031ef:	c7 04 24 23 9e 10 80 	movl   $0x80109e23,(%esp)
801031f6:	e8 a5 d1 ff ff       	call   801003a0 <cprintf>
    panic("kfreekfree");
801031fb:	c7 04 24 3a 9e 10 80 	movl   $0x80109e3a,(%esp)
80103202:	e8 33 d3 ff ff       	call   8010053a <panic>
  // Fill with junk to catch dangling refs.
  //memset(v, 1, PGSIZE);
  // if(getPid()){
  //   cprintf("after memset\n");
  // }
  if(kmem.use_lock)
80103207:	a1 54 42 11 80       	mov    0x80114254,%eax
8010320c:	85 c0                	test   %eax,%eax
8010320e:	74 0c                	je     8010321c <kfree+0x92>
    acquire(&kmem.lock);
80103210:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103217:	e8 99 25 00 00       	call   801057b5 <acquire>
  r = (struct run*)v;
8010321c:	8b 45 08             	mov    0x8(%ebp),%eax
8010321f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103222:	8b 15 58 42 11 80    	mov    0x80114258,%edx
80103228:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010322b:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
8010322d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103230:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
80103235:	a1 54 42 11 80       	mov    0x80114254,%eax
8010323a:	85 c0                	test   %eax,%eax
8010323c:	74 0c                	je     8010324a <kfree+0xc0>
    release(&kmem.lock);
8010323e:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103245:	e8 cd 25 00 00       	call   80105817 <release>
}
8010324a:	c9                   	leave  
8010324b:	c3                   	ret    

8010324c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
8010324c:	55                   	push   %ebp
8010324d:	89 e5                	mov    %esp,%ebp
8010324f:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103252:	a1 54 42 11 80       	mov    0x80114254,%eax
80103257:	85 c0                	test   %eax,%eax
80103259:	74 0c                	je     80103267 <kalloc+0x1b>
    acquire(&kmem.lock);
8010325b:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
80103262:	e8 4e 25 00 00       	call   801057b5 <acquire>
  r = kmem.freelist;
80103267:	a1 58 42 11 80       	mov    0x80114258,%eax
8010326c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
8010326f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103273:	74 0a                	je     8010327f <kalloc+0x33>
    kmem.freelist = r->next;
80103275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103278:	8b 00                	mov    (%eax),%eax
8010327a:	a3 58 42 11 80       	mov    %eax,0x80114258
  if(kmem.use_lock)
8010327f:	a1 54 42 11 80       	mov    0x80114254,%eax
80103284:	85 c0                	test   %eax,%eax
80103286:	74 0c                	je     80103294 <kalloc+0x48>
    release(&kmem.lock);
80103288:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
8010328f:	e8 83 25 00 00       	call   80105817 <release>
  return (char*)r;
80103294:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103297:	c9                   	leave  
80103298:	c3                   	ret    

80103299 <countPages>:

int
countPages(){
80103299:	55                   	push   %ebp
8010329a:	89 e5                	mov    %esp,%ebp
8010329c:	83 ec 28             	sub    $0x28,%esp
  int result = 0;
8010329f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct run *r;
  acquire(&kmem.lock);
801032a6:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032ad:	e8 03 25 00 00       	call   801057b5 <acquire>
  r = kmem.freelist;
801032b2:	a1 58 42 11 80       	mov    0x80114258,%eax
801032b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(r != 0){
801032ba:	eb 0c                	jmp    801032c8 <countPages+0x2f>
    result++;
801032bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    r = r->next;
801032c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032c3:	8b 00                	mov    (%eax),%eax
801032c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
countPages(){
  int result = 0;
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  while(r != 0){
801032c8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032cc:	75 ee                	jne    801032bc <countPages+0x23>
    result++;
    r = r->next;
  }
  release(&kmem.lock);
801032ce:	c7 04 24 20 42 11 80 	movl   $0x80114220,(%esp)
801032d5:	e8 3d 25 00 00       	call   80105817 <release>
  return result;
801032da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032dd:	c9                   	leave  
801032de:	c3                   	ret    

801032df <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032df:	55                   	push   %ebp
801032e0:	89 e5                	mov    %esp,%ebp
801032e2:	83 ec 14             	sub    $0x14,%esp
801032e5:	8b 45 08             	mov    0x8(%ebp),%eax
801032e8:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801032ec:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801032f0:	89 c2                	mov    %eax,%edx
801032f2:	ec                   	in     (%dx),%al
801032f3:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801032f6:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801032fa:	c9                   	leave  
801032fb:	c3                   	ret    

801032fc <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801032fc:	55                   	push   %ebp
801032fd:	89 e5                	mov    %esp,%ebp
801032ff:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103302:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103309:	e8 d1 ff ff ff       	call   801032df <inb>
8010330e:	0f b6 c0             	movzbl %al,%eax
80103311:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103317:	83 e0 01             	and    $0x1,%eax
8010331a:	85 c0                	test   %eax,%eax
8010331c:	75 0a                	jne    80103328 <kbdgetc+0x2c>
    return -1;
8010331e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103323:	e9 25 01 00 00       	jmp    8010344d <kbdgetc+0x151>
  data = inb(KBDATAP);
80103328:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
8010332f:	e8 ab ff ff ff       	call   801032df <inb>
80103334:	0f b6 c0             	movzbl %al,%eax
80103337:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
8010333a:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103341:	75 17                	jne    8010335a <kbdgetc+0x5e>
    shift |= E0ESC;
80103343:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103348:	83 c8 40             	or     $0x40,%eax
8010334b:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
80103350:	b8 00 00 00 00       	mov    $0x0,%eax
80103355:	e9 f3 00 00 00       	jmp    8010344d <kbdgetc+0x151>
  } else if(data & 0x80){
8010335a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010335d:	25 80 00 00 00       	and    $0x80,%eax
80103362:	85 c0                	test   %eax,%eax
80103364:	74 45                	je     801033ab <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103366:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010336b:	83 e0 40             	and    $0x40,%eax
8010336e:	85 c0                	test   %eax,%eax
80103370:	75 08                	jne    8010337a <kbdgetc+0x7e>
80103372:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103375:	83 e0 7f             	and    $0x7f,%eax
80103378:	eb 03                	jmp    8010337d <kbdgetc+0x81>
8010337a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010337d:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103380:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103383:	05 20 b0 10 80       	add    $0x8010b020,%eax
80103388:	0f b6 00             	movzbl (%eax),%eax
8010338b:	83 c8 40             	or     $0x40,%eax
8010338e:	0f b6 c0             	movzbl %al,%eax
80103391:	f7 d0                	not    %eax
80103393:	89 c2                	mov    %eax,%edx
80103395:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
8010339a:	21 d0                	and    %edx,%eax
8010339c:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
    return 0;
801033a1:	b8 00 00 00 00       	mov    $0x0,%eax
801033a6:	e9 a2 00 00 00       	jmp    8010344d <kbdgetc+0x151>
  } else if(shift & E0ESC){
801033ab:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033b0:	83 e0 40             	and    $0x40,%eax
801033b3:	85 c0                	test   %eax,%eax
801033b5:	74 14                	je     801033cb <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801033b7:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801033be:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033c3:	83 e0 bf             	and    $0xffffffbf,%eax
801033c6:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  }

  shift |= shiftcode[data];
801033cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033ce:	05 20 b0 10 80       	add    $0x8010b020,%eax
801033d3:	0f b6 00             	movzbl (%eax),%eax
801033d6:	0f b6 d0             	movzbl %al,%edx
801033d9:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033de:	09 d0                	or     %edx,%eax
801033e0:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  shift ^= togglecode[data];
801033e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033e8:	05 20 b1 10 80       	add    $0x8010b120,%eax
801033ed:	0f b6 00             	movzbl (%eax),%eax
801033f0:	0f b6 d0             	movzbl %al,%edx
801033f3:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
801033f8:	31 d0                	xor    %edx,%eax
801033fa:	a3 3c d6 10 80       	mov    %eax,0x8010d63c
  c = charcode[shift & (CTL | SHIFT)][data];
801033ff:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103404:	83 e0 03             	and    $0x3,%eax
80103407:	8b 14 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%edx
8010340e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103411:	01 d0                	add    %edx,%eax
80103413:	0f b6 00             	movzbl (%eax),%eax
80103416:	0f b6 c0             	movzbl %al,%eax
80103419:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
8010341c:	a1 3c d6 10 80       	mov    0x8010d63c,%eax
80103421:	83 e0 08             	and    $0x8,%eax
80103424:	85 c0                	test   %eax,%eax
80103426:	74 22                	je     8010344a <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80103428:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
8010342c:	76 0c                	jbe    8010343a <kbdgetc+0x13e>
8010342e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103432:	77 06                	ja     8010343a <kbdgetc+0x13e>
      c += 'A' - 'a';
80103434:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103438:	eb 10                	jmp    8010344a <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
8010343a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010343e:	76 0a                	jbe    8010344a <kbdgetc+0x14e>
80103440:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103444:	77 04                	ja     8010344a <kbdgetc+0x14e>
      c += 'a' - 'A';
80103446:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
8010344a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010344d:	c9                   	leave  
8010344e:	c3                   	ret    

8010344f <kbdintr>:

void
kbdintr(void)
{
8010344f:	55                   	push   %ebp
80103450:	89 e5                	mov    %esp,%ebp
80103452:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103455:	c7 04 24 fc 32 10 80 	movl   $0x801032fc,(%esp)
8010345c:	e8 67 d3 ff ff       	call   801007c8 <consoleintr>
}
80103461:	c9                   	leave  
80103462:	c3                   	ret    

80103463 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103463:	55                   	push   %ebp
80103464:	89 e5                	mov    %esp,%ebp
80103466:	83 ec 14             	sub    $0x14,%esp
80103469:	8b 45 08             	mov    0x8(%ebp),%eax
8010346c:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103470:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103474:	89 c2                	mov    %eax,%edx
80103476:	ec                   	in     (%dx),%al
80103477:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010347a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010347e:	c9                   	leave  
8010347f:	c3                   	ret    

80103480 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103480:	55                   	push   %ebp
80103481:	89 e5                	mov    %esp,%ebp
80103483:	83 ec 08             	sub    $0x8,%esp
80103486:	8b 55 08             	mov    0x8(%ebp),%edx
80103489:	8b 45 0c             	mov    0xc(%ebp),%eax
8010348c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103490:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103493:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103497:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010349b:	ee                   	out    %al,(%dx)
}
8010349c:	c9                   	leave  
8010349d:	c3                   	ret    

8010349e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010349e:	55                   	push   %ebp
8010349f:	89 e5                	mov    %esp,%ebp
801034a1:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034a4:	9c                   	pushf  
801034a5:	58                   	pop    %eax
801034a6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801034a9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801034ac:	c9                   	leave  
801034ad:	c3                   	ret    

801034ae <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801034ae:	55                   	push   %ebp
801034af:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801034b1:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034b6:	8b 55 08             	mov    0x8(%ebp),%edx
801034b9:	c1 e2 02             	shl    $0x2,%edx
801034bc:	01 c2                	add    %eax,%edx
801034be:	8b 45 0c             	mov    0xc(%ebp),%eax
801034c1:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801034c3:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034c8:	83 c0 20             	add    $0x20,%eax
801034cb:	8b 00                	mov    (%eax),%eax
}
801034cd:	5d                   	pop    %ebp
801034ce:	c3                   	ret    

801034cf <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801034cf:	55                   	push   %ebp
801034d0:	89 e5                	mov    %esp,%ebp
801034d2:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801034d5:	a1 5c 42 11 80       	mov    0x8011425c,%eax
801034da:	85 c0                	test   %eax,%eax
801034dc:	75 05                	jne    801034e3 <lapicinit+0x14>
    return;
801034de:	e9 43 01 00 00       	jmp    80103626 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801034e3:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801034ea:	00 
801034eb:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801034f2:	e8 b7 ff ff ff       	call   801034ae <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801034f7:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801034fe:	00 
801034ff:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103506:	e8 a3 ff ff ff       	call   801034ae <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010350b:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103512:	00 
80103513:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010351a:	e8 8f ff ff ff       	call   801034ae <lapicw>
  lapicw(TICR, 10000000); 
8010351f:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103526:	00 
80103527:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010352e:	e8 7b ff ff ff       	call   801034ae <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103533:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010353a:	00 
8010353b:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103542:	e8 67 ff ff ff       	call   801034ae <lapicw>
  lapicw(LINT1, MASKED);
80103547:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010354e:	00 
8010354f:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103556:	e8 53 ff ff ff       	call   801034ae <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010355b:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103560:	83 c0 30             	add    $0x30,%eax
80103563:	8b 00                	mov    (%eax),%eax
80103565:	c1 e8 10             	shr    $0x10,%eax
80103568:	0f b6 c0             	movzbl %al,%eax
8010356b:	83 f8 03             	cmp    $0x3,%eax
8010356e:	76 14                	jbe    80103584 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103570:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103577:	00 
80103578:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010357f:	e8 2a ff ff ff       	call   801034ae <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103584:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
8010358b:	00 
8010358c:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103593:	e8 16 ff ff ff       	call   801034ae <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103598:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010359f:	00 
801035a0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801035a7:	e8 02 ff ff ff       	call   801034ae <lapicw>
  lapicw(ESR, 0);
801035ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035b3:	00 
801035b4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801035bb:	e8 ee fe ff ff       	call   801034ae <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801035c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035c7:	00 
801035c8:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035cf:	e8 da fe ff ff       	call   801034ae <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801035d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035db:	00 
801035dc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035e3:	e8 c6 fe ff ff       	call   801034ae <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801035e8:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801035ef:	00 
801035f0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801035f7:	e8 b2 fe ff ff       	call   801034ae <lapicw>
  while(lapic[ICRLO] & DELIVS)
801035fc:	90                   	nop
801035fd:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103602:	05 00 03 00 00       	add    $0x300,%eax
80103607:	8b 00                	mov    (%eax),%eax
80103609:	25 00 10 00 00       	and    $0x1000,%eax
8010360e:	85 c0                	test   %eax,%eax
80103610:	75 eb                	jne    801035fd <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103612:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103619:	00 
8010361a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103621:	e8 88 fe ff ff       	call   801034ae <lapicw>
}
80103626:	c9                   	leave  
80103627:	c3                   	ret    

80103628 <cpunum>:

int
cpunum(void)
{
80103628:	55                   	push   %ebp
80103629:	89 e5                	mov    %esp,%ebp
8010362b:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010362e:	e8 6b fe ff ff       	call   8010349e <readeflags>
80103633:	25 00 02 00 00       	and    $0x200,%eax
80103638:	85 c0                	test   %eax,%eax
8010363a:	74 25                	je     80103661 <cpunum+0x39>
    static int n;
    if(n++ == 0)
8010363c:	a1 40 d6 10 80       	mov    0x8010d640,%eax
80103641:	8d 50 01             	lea    0x1(%eax),%edx
80103644:	89 15 40 d6 10 80    	mov    %edx,0x8010d640
8010364a:	85 c0                	test   %eax,%eax
8010364c:	75 13                	jne    80103661 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
8010364e:	8b 45 04             	mov    0x4(%ebp),%eax
80103651:	89 44 24 04          	mov    %eax,0x4(%esp)
80103655:	c7 04 24 48 9e 10 80 	movl   $0x80109e48,(%esp)
8010365c:	e8 3f cd ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103661:	a1 5c 42 11 80       	mov    0x8011425c,%eax
80103666:	85 c0                	test   %eax,%eax
80103668:	74 0f                	je     80103679 <cpunum+0x51>
    return lapic[ID]>>24;
8010366a:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010366f:	83 c0 20             	add    $0x20,%eax
80103672:	8b 00                	mov    (%eax),%eax
80103674:	c1 e8 18             	shr    $0x18,%eax
80103677:	eb 05                	jmp    8010367e <cpunum+0x56>
  return 0;
80103679:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010367e:	c9                   	leave  
8010367f:	c3                   	ret    

80103680 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103680:	55                   	push   %ebp
80103681:	89 e5                	mov    %esp,%ebp
80103683:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103686:	a1 5c 42 11 80       	mov    0x8011425c,%eax
8010368b:	85 c0                	test   %eax,%eax
8010368d:	74 14                	je     801036a3 <lapiceoi+0x23>
    lapicw(EOI, 0);
8010368f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103696:	00 
80103697:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010369e:	e8 0b fe ff ff       	call   801034ae <lapicw>
}
801036a3:	c9                   	leave  
801036a4:	c3                   	ret    

801036a5 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801036a5:	55                   	push   %ebp
801036a6:	89 e5                	mov    %esp,%ebp
}
801036a8:	5d                   	pop    %ebp
801036a9:	c3                   	ret    

801036aa <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801036aa:	55                   	push   %ebp
801036ab:	89 e5                	mov    %esp,%ebp
801036ad:	83 ec 1c             	sub    $0x1c,%esp
801036b0:	8b 45 08             	mov    0x8(%ebp),%eax
801036b3:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801036b6:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801036bd:	00 
801036be:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036c5:	e8 b6 fd ff ff       	call   80103480 <outb>
  outb(CMOS_PORT+1, 0x0A);
801036ca:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801036d1:	00 
801036d2:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036d9:	e8 a2 fd ff ff       	call   80103480 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801036de:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801036e5:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036e8:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801036ed:	8b 45 f8             	mov    -0x8(%ebp),%eax
801036f0:	8d 50 02             	lea    0x2(%eax),%edx
801036f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801036f6:	c1 e8 04             	shr    $0x4,%eax
801036f9:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801036fc:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103700:	c1 e0 18             	shl    $0x18,%eax
80103703:	89 44 24 04          	mov    %eax,0x4(%esp)
80103707:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010370e:	e8 9b fd ff ff       	call   801034ae <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103713:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010371a:	00 
8010371b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103722:	e8 87 fd ff ff       	call   801034ae <lapicw>
  microdelay(200);
80103727:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010372e:	e8 72 ff ff ff       	call   801036a5 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103733:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010373a:	00 
8010373b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103742:	e8 67 fd ff ff       	call   801034ae <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103747:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010374e:	e8 52 ff ff ff       	call   801036a5 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103753:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010375a:	eb 40                	jmp    8010379c <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010375c:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103760:	c1 e0 18             	shl    $0x18,%eax
80103763:	89 44 24 04          	mov    %eax,0x4(%esp)
80103767:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010376e:	e8 3b fd ff ff       	call   801034ae <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103773:	8b 45 0c             	mov    0xc(%ebp),%eax
80103776:	c1 e8 0c             	shr    $0xc,%eax
80103779:	80 cc 06             	or     $0x6,%ah
8010377c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103780:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103787:	e8 22 fd ff ff       	call   801034ae <lapicw>
    microdelay(200);
8010378c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103793:	e8 0d ff ff ff       	call   801036a5 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103798:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010379c:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801037a0:	7e ba                	jle    8010375c <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801037a2:	c9                   	leave  
801037a3:	c3                   	ret    

801037a4 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801037a4:	55                   	push   %ebp
801037a5:	89 e5                	mov    %esp,%ebp
801037a7:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801037aa:	8b 45 08             	mov    0x8(%ebp),%eax
801037ad:	0f b6 c0             	movzbl %al,%eax
801037b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801037b4:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801037bb:	e8 c0 fc ff ff       	call   80103480 <outb>
  microdelay(200);
801037c0:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037c7:	e8 d9 fe ff ff       	call   801036a5 <microdelay>

  return inb(CMOS_RETURN);
801037cc:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801037d3:	e8 8b fc ff ff       	call   80103463 <inb>
801037d8:	0f b6 c0             	movzbl %al,%eax
}
801037db:	c9                   	leave  
801037dc:	c3                   	ret    

801037dd <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801037dd:	55                   	push   %ebp
801037de:	89 e5                	mov    %esp,%ebp
801037e0:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801037e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037ea:	e8 b5 ff ff ff       	call   801037a4 <cmos_read>
801037ef:	8b 55 08             	mov    0x8(%ebp),%edx
801037f2:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801037f4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801037fb:	e8 a4 ff ff ff       	call   801037a4 <cmos_read>
80103800:	8b 55 08             	mov    0x8(%ebp),%edx
80103803:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103806:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010380d:	e8 92 ff ff ff       	call   801037a4 <cmos_read>
80103812:	8b 55 08             	mov    0x8(%ebp),%edx
80103815:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103818:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
8010381f:	e8 80 ff ff ff       	call   801037a4 <cmos_read>
80103824:	8b 55 08             	mov    0x8(%ebp),%edx
80103827:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010382a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103831:	e8 6e ff ff ff       	call   801037a4 <cmos_read>
80103836:	8b 55 08             	mov    0x8(%ebp),%edx
80103839:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010383c:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103843:	e8 5c ff ff ff       	call   801037a4 <cmos_read>
80103848:	8b 55 08             	mov    0x8(%ebp),%edx
8010384b:	89 42 14             	mov    %eax,0x14(%edx)
}
8010384e:	c9                   	leave  
8010384f:	c3                   	ret    

80103850 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103850:	55                   	push   %ebp
80103851:	89 e5                	mov    %esp,%ebp
80103853:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103856:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
8010385d:	e8 42 ff ff ff       	call   801037a4 <cmos_read>
80103862:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103868:	83 e0 04             	and    $0x4,%eax
8010386b:	85 c0                	test   %eax,%eax
8010386d:	0f 94 c0             	sete   %al
80103870:	0f b6 c0             	movzbl %al,%eax
80103873:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103876:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103879:	89 04 24             	mov    %eax,(%esp)
8010387c:	e8 5c ff ff ff       	call   801037dd <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103881:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103888:	e8 17 ff ff ff       	call   801037a4 <cmos_read>
8010388d:	25 80 00 00 00       	and    $0x80,%eax
80103892:	85 c0                	test   %eax,%eax
80103894:	74 02                	je     80103898 <cmostime+0x48>
        continue;
80103896:	eb 36                	jmp    801038ce <cmostime+0x7e>
    fill_rtcdate(&t2);
80103898:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010389b:	89 04 24             	mov    %eax,(%esp)
8010389e:	e8 3a ff ff ff       	call   801037dd <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801038a3:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801038aa:	00 
801038ab:	8d 45 c0             	lea    -0x40(%ebp),%eax
801038ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801038b2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801038b5:	89 04 24             	mov    %eax,(%esp)
801038b8:	e8 c3 21 00 00       	call   80105a80 <memcmp>
801038bd:	85 c0                	test   %eax,%eax
801038bf:	75 0d                	jne    801038ce <cmostime+0x7e>
      break;
801038c1:	90                   	nop
  }

  // convert
  if (bcd) {
801038c2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038c6:	0f 84 ac 00 00 00    	je     80103978 <cmostime+0x128>
801038cc:	eb 02                	jmp    801038d0 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801038ce:	eb a6                	jmp    80103876 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801038d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
801038d3:	c1 e8 04             	shr    $0x4,%eax
801038d6:	89 c2                	mov    %eax,%edx
801038d8:	89 d0                	mov    %edx,%eax
801038da:	c1 e0 02             	shl    $0x2,%eax
801038dd:	01 d0                	add    %edx,%eax
801038df:	01 c0                	add    %eax,%eax
801038e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038e4:	83 e2 0f             	and    $0xf,%edx
801038e7:	01 d0                	add    %edx,%eax
801038e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801038ec:	8b 45 dc             	mov    -0x24(%ebp),%eax
801038ef:	c1 e8 04             	shr    $0x4,%eax
801038f2:	89 c2                	mov    %eax,%edx
801038f4:	89 d0                	mov    %edx,%eax
801038f6:	c1 e0 02             	shl    $0x2,%eax
801038f9:	01 d0                	add    %edx,%eax
801038fb:	01 c0                	add    %eax,%eax
801038fd:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103900:	83 e2 0f             	and    $0xf,%edx
80103903:	01 d0                	add    %edx,%eax
80103905:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103908:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010390b:	c1 e8 04             	shr    $0x4,%eax
8010390e:	89 c2                	mov    %eax,%edx
80103910:	89 d0                	mov    %edx,%eax
80103912:	c1 e0 02             	shl    $0x2,%eax
80103915:	01 d0                	add    %edx,%eax
80103917:	01 c0                	add    %eax,%eax
80103919:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010391c:	83 e2 0f             	and    $0xf,%edx
8010391f:	01 d0                	add    %edx,%eax
80103921:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103924:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103927:	c1 e8 04             	shr    $0x4,%eax
8010392a:	89 c2                	mov    %eax,%edx
8010392c:	89 d0                	mov    %edx,%eax
8010392e:	c1 e0 02             	shl    $0x2,%eax
80103931:	01 d0                	add    %edx,%eax
80103933:	01 c0                	add    %eax,%eax
80103935:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103938:	83 e2 0f             	and    $0xf,%edx
8010393b:	01 d0                	add    %edx,%eax
8010393d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103940:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103943:	c1 e8 04             	shr    $0x4,%eax
80103946:	89 c2                	mov    %eax,%edx
80103948:	89 d0                	mov    %edx,%eax
8010394a:	c1 e0 02             	shl    $0x2,%eax
8010394d:	01 d0                	add    %edx,%eax
8010394f:	01 c0                	add    %eax,%eax
80103951:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103954:	83 e2 0f             	and    $0xf,%edx
80103957:	01 d0                	add    %edx,%eax
80103959:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
8010395c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010395f:	c1 e8 04             	shr    $0x4,%eax
80103962:	89 c2                	mov    %eax,%edx
80103964:	89 d0                	mov    %edx,%eax
80103966:	c1 e0 02             	shl    $0x2,%eax
80103969:	01 d0                	add    %edx,%eax
8010396b:	01 c0                	add    %eax,%eax
8010396d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103970:	83 e2 0f             	and    $0xf,%edx
80103973:	01 d0                	add    %edx,%eax
80103975:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103978:	8b 45 08             	mov    0x8(%ebp),%eax
8010397b:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010397e:	89 10                	mov    %edx,(%eax)
80103980:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103983:	89 50 04             	mov    %edx,0x4(%eax)
80103986:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103989:	89 50 08             	mov    %edx,0x8(%eax)
8010398c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010398f:	89 50 0c             	mov    %edx,0xc(%eax)
80103992:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103995:	89 50 10             	mov    %edx,0x10(%eax)
80103998:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010399b:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
8010399e:	8b 45 08             	mov    0x8(%ebp),%eax
801039a1:	8b 40 14             	mov    0x14(%eax),%eax
801039a4:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801039aa:	8b 45 08             	mov    0x8(%ebp),%eax
801039ad:	89 50 14             	mov    %edx,0x14(%eax)
}
801039b0:	c9                   	leave  
801039b1:	c3                   	ret    

801039b2 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
801039b2:	55                   	push   %ebp
801039b3:	89 e5                	mov    %esp,%ebp
801039b5:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801039b8:	c7 44 24 04 74 9e 10 	movl   $0x80109e74,0x4(%esp)
801039bf:	80 
801039c0:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
801039c7:	e8 c8 1d 00 00       	call   80105794 <initlock>
  readsb(dev, &sb);
801039cc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801039cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801039d3:	8b 45 08             	mov    0x8(%ebp),%eax
801039d6:	89 04 24             	mov    %eax,(%esp)
801039d9:	e8 13 da ff ff       	call   801013f1 <readsb>
  log.start = sb.logstart;
801039de:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039e1:	a3 94 42 11 80       	mov    %eax,0x80114294
  log.size = sb.nlog;
801039e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039e9:	a3 98 42 11 80       	mov    %eax,0x80114298
  log.dev = dev;
801039ee:	8b 45 08             	mov    0x8(%ebp),%eax
801039f1:	a3 a4 42 11 80       	mov    %eax,0x801142a4
  recover_from_log();
801039f6:	e8 9a 01 00 00       	call   80103b95 <recover_from_log>
}
801039fb:	c9                   	leave  
801039fc:	c3                   	ret    

801039fd <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801039fd:	55                   	push   %ebp
801039fe:	89 e5                	mov    %esp,%ebp
80103a00:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a0a:	e9 8c 00 00 00       	jmp    80103a9b <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103a0f:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103a15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a18:	01 d0                	add    %edx,%eax
80103a1a:	83 c0 01             	add    $0x1,%eax
80103a1d:	89 c2                	mov    %eax,%edx
80103a1f:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a24:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a28:	89 04 24             	mov    %eax,(%esp)
80103a2b:	e8 76 c7 ff ff       	call   801001a6 <bread>
80103a30:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80103a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a36:	83 c0 10             	add    $0x10,%eax
80103a39:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103a40:	89 c2                	mov    %eax,%edx
80103a42:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103a47:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a4b:	89 04 24             	mov    %eax,(%esp)
80103a4e:	e8 53 c7 ff ff       	call   801001a6 <bread>
80103a53:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103a56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a59:	8d 50 18             	lea    0x18(%eax),%edx
80103a5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a5f:	83 c0 18             	add    $0x18,%eax
80103a62:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103a69:	00 
80103a6a:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a6e:	89 04 24             	mov    %eax,(%esp)
80103a71:	e8 62 20 00 00       	call   80105ad8 <memmove>
    bwrite(dbuf);  // write dst to disk
80103a76:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a79:	89 04 24             	mov    %eax,(%esp)
80103a7c:	e8 5c c7 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103a81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a84:	89 04 24             	mov    %eax,(%esp)
80103a87:	e8 8b c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103a8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a8f:	89 04 24             	mov    %eax,(%esp)
80103a92:	e8 80 c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a97:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a9b:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103aa0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103aa3:	0f 8f 66 ff ff ff    	jg     80103a0f <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103aa9:	c9                   	leave  
80103aaa:	c3                   	ret    

80103aab <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103aab:	55                   	push   %ebp
80103aac:	89 e5                	mov    %esp,%ebp
80103aae:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103ab1:	a1 94 42 11 80       	mov    0x80114294,%eax
80103ab6:	89 c2                	mov    %eax,%edx
80103ab8:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103abd:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ac1:	89 04 24             	mov    %eax,(%esp)
80103ac4:	e8 dd c6 ff ff       	call   801001a6 <bread>
80103ac9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103acc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103acf:	83 c0 18             	add    $0x18,%eax
80103ad2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103ad5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ad8:	8b 00                	mov    (%eax),%eax
80103ada:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  for (i = 0; i < log.lh.n; i++) {
80103adf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ae6:	eb 1b                	jmp    80103b03 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103ae8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aeb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103aee:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103af2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103af5:	83 c2 10             	add    $0x10,%edx
80103af8:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103aff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b03:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b08:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b0b:	7f db                	jg     80103ae8 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103b0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b10:	89 04 24             	mov    %eax,(%esp)
80103b13:	e8 ff c6 ff ff       	call   80100217 <brelse>
}
80103b18:	c9                   	leave  
80103b19:	c3                   	ret    

80103b1a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103b1a:	55                   	push   %ebp
80103b1b:	89 e5                	mov    %esp,%ebp
80103b1d:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b20:	a1 94 42 11 80       	mov    0x80114294,%eax
80103b25:	89 c2                	mov    %eax,%edx
80103b27:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103b2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b30:	89 04 24             	mov    %eax,(%esp)
80103b33:	e8 6e c6 ff ff       	call   801001a6 <bread>
80103b38:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103b3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b3e:	83 c0 18             	add    $0x18,%eax
80103b41:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103b44:	8b 15 a8 42 11 80    	mov    0x801142a8,%edx
80103b4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b4d:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103b4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b56:	eb 1b                	jmp    80103b73 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b5b:	83 c0 10             	add    $0x10,%eax
80103b5e:	8b 0c 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%ecx
80103b65:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b68:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b6b:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103b6f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b73:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103b78:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b7b:	7f db                	jg     80103b58 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103b7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b80:	89 04 24             	mov    %eax,(%esp)
80103b83:	e8 55 c6 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b8b:	89 04 24             	mov    %eax,(%esp)
80103b8e:	e8 84 c6 ff ff       	call   80100217 <brelse>
}
80103b93:	c9                   	leave  
80103b94:	c3                   	ret    

80103b95 <recover_from_log>:

static void
recover_from_log(void)
{
80103b95:	55                   	push   %ebp
80103b96:	89 e5                	mov    %esp,%ebp
80103b98:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103b9b:	e8 0b ff ff ff       	call   80103aab <read_head>
  install_trans(); // if committed, copy from log to disk
80103ba0:	e8 58 fe ff ff       	call   801039fd <install_trans>
  log.lh.n = 0;
80103ba5:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103bac:	00 00 00 
  write_head(); // clear the log
80103baf:	e8 66 ff ff ff       	call   80103b1a <write_head>
}
80103bb4:	c9                   	leave  
80103bb5:	c3                   	ret    

80103bb6 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103bb6:	55                   	push   %ebp
80103bb7:	89 e5                	mov    %esp,%ebp
80103bb9:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103bbc:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103bc3:	e8 ed 1b 00 00       	call   801057b5 <acquire>
  while(1){
    if(log.committing){
80103bc8:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103bcd:	85 c0                	test   %eax,%eax
80103bcf:	74 16                	je     80103be7 <begin_op+0x31>
      sleep(&log, &log.lock);
80103bd1:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103bd8:	80 
80103bd9:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103be0:	e8 7e 18 00 00       	call   80105463 <sleep>
80103be5:	eb 4f                	jmp    80103c36 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103be7:	8b 0d a8 42 11 80    	mov    0x801142a8,%ecx
80103bed:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103bf2:	8d 50 01             	lea    0x1(%eax),%edx
80103bf5:	89 d0                	mov    %edx,%eax
80103bf7:	c1 e0 02             	shl    $0x2,%eax
80103bfa:	01 d0                	add    %edx,%eax
80103bfc:	01 c0                	add    %eax,%eax
80103bfe:	01 c8                	add    %ecx,%eax
80103c00:	83 f8 1e             	cmp    $0x1e,%eax
80103c03:	7e 16                	jle    80103c1b <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103c05:	c7 44 24 04 60 42 11 	movl   $0x80114260,0x4(%esp)
80103c0c:	80 
80103c0d:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c14:	e8 4a 18 00 00       	call   80105463 <sleep>
80103c19:	eb 1b                	jmp    80103c36 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103c1b:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c20:	83 c0 01             	add    $0x1,%eax
80103c23:	a3 9c 42 11 80       	mov    %eax,0x8011429c
      release(&log.lock);
80103c28:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c2f:	e8 e3 1b 00 00       	call   80105817 <release>
      break;
80103c34:	eb 02                	jmp    80103c38 <begin_op+0x82>
    }
  }
80103c36:	eb 90                	jmp    80103bc8 <begin_op+0x12>
}
80103c38:	c9                   	leave  
80103c39:	c3                   	ret    

80103c3a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103c3a:	55                   	push   %ebp
80103c3b:	89 e5                	mov    %esp,%ebp
80103c3d:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103c40:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103c47:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c4e:	e8 62 1b 00 00       	call   801057b5 <acquire>
  log.outstanding -= 1;
80103c53:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c58:	83 e8 01             	sub    $0x1,%eax
80103c5b:	a3 9c 42 11 80       	mov    %eax,0x8011429c
  if(log.committing)
80103c60:	a1 a0 42 11 80       	mov    0x801142a0,%eax
80103c65:	85 c0                	test   %eax,%eax
80103c67:	74 0c                	je     80103c75 <end_op+0x3b>
    panic("log.committing");
80103c69:	c7 04 24 78 9e 10 80 	movl   $0x80109e78,(%esp)
80103c70:	e8 c5 c8 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103c75:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103c7a:	85 c0                	test   %eax,%eax
80103c7c:	75 13                	jne    80103c91 <end_op+0x57>
    do_commit = 1;
80103c7e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103c85:	c7 05 a0 42 11 80 01 	movl   $0x1,0x801142a0
80103c8c:	00 00 00 
80103c8f:	eb 0c                	jmp    80103c9d <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103c91:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103c98:	e8 a2 18 00 00       	call   8010553f <wakeup>
  }
  release(&log.lock);
80103c9d:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103ca4:	e8 6e 1b 00 00       	call   80105817 <release>

  if(do_commit){
80103ca9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cad:	74 33                	je     80103ce2 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103caf:	e8 de 00 00 00       	call   80103d92 <commit>
    acquire(&log.lock);
80103cb4:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cbb:	e8 f5 1a 00 00       	call   801057b5 <acquire>
    log.committing = 0;
80103cc0:	c7 05 a0 42 11 80 00 	movl   $0x0,0x801142a0
80103cc7:	00 00 00 
    wakeup(&log);
80103cca:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cd1:	e8 69 18 00 00       	call   8010553f <wakeup>
    release(&log.lock);
80103cd6:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103cdd:	e8 35 1b 00 00       	call   80105817 <release>
  }
}
80103ce2:	c9                   	leave  
80103ce3:	c3                   	ret    

80103ce4 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103ce4:	55                   	push   %ebp
80103ce5:	89 e5                	mov    %esp,%ebp
80103ce7:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103cea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103cf1:	e9 8c 00 00 00       	jmp    80103d82 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103cf6:	8b 15 94 42 11 80    	mov    0x80114294,%edx
80103cfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cff:	01 d0                	add    %edx,%eax
80103d01:	83 c0 01             	add    $0x1,%eax
80103d04:	89 c2                	mov    %eax,%edx
80103d06:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d0b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d0f:	89 04 24             	mov    %eax,(%esp)
80103d12:	e8 8f c4 ff ff       	call   801001a6 <bread>
80103d17:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103d1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d1d:	83 c0 10             	add    $0x10,%eax
80103d20:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103d27:	89 c2                	mov    %eax,%edx
80103d29:	a1 a4 42 11 80       	mov    0x801142a4,%eax
80103d2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d32:	89 04 24             	mov    %eax,(%esp)
80103d35:	e8 6c c4 ff ff       	call   801001a6 <bread>
80103d3a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103d3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d40:	8d 50 18             	lea    0x18(%eax),%edx
80103d43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d46:	83 c0 18             	add    $0x18,%eax
80103d49:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d50:	00 
80103d51:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d55:	89 04 24             	mov    %eax,(%esp)
80103d58:	e8 7b 1d 00 00       	call   80105ad8 <memmove>
    bwrite(to);  // write the log
80103d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d60:	89 04 24             	mov    %eax,(%esp)
80103d63:	e8 75 c4 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103d68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d6b:	89 04 24             	mov    %eax,(%esp)
80103d6e:	e8 a4 c4 ff ff       	call   80100217 <brelse>
    brelse(to);
80103d73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d76:	89 04 24             	mov    %eax,(%esp)
80103d79:	e8 99 c4 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103d7e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d82:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d87:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d8a:	0f 8f 66 ff ff ff    	jg     80103cf6 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103d90:	c9                   	leave  
80103d91:	c3                   	ret    

80103d92 <commit>:

static void
commit()
{
80103d92:	55                   	push   %ebp
80103d93:	89 e5                	mov    %esp,%ebp
80103d95:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103d98:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103d9d:	85 c0                	test   %eax,%eax
80103d9f:	7e 1e                	jle    80103dbf <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103da1:	e8 3e ff ff ff       	call   80103ce4 <write_log>
    write_head();    // Write header to disk -- the real commit
80103da6:	e8 6f fd ff ff       	call   80103b1a <write_head>
    install_trans(); // Now install writes to home locations
80103dab:	e8 4d fc ff ff       	call   801039fd <install_trans>
    log.lh.n = 0; 
80103db0:	c7 05 a8 42 11 80 00 	movl   $0x0,0x801142a8
80103db7:	00 00 00 
    write_head();    // Erase the transaction from the log
80103dba:	e8 5b fd ff ff       	call   80103b1a <write_head>
  }
}
80103dbf:	c9                   	leave  
80103dc0:	c3                   	ret    

80103dc1 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103dc1:	55                   	push   %ebp
80103dc2:	89 e5                	mov    %esp,%ebp
80103dc4:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103dc7:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dcc:	83 f8 1d             	cmp    $0x1d,%eax
80103dcf:	7f 12                	jg     80103de3 <log_write+0x22>
80103dd1:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103dd6:	8b 15 98 42 11 80    	mov    0x80114298,%edx
80103ddc:	83 ea 01             	sub    $0x1,%edx
80103ddf:	39 d0                	cmp    %edx,%eax
80103de1:	7c 0c                	jl     80103def <log_write+0x2e>
    panic("too big a transaction");
80103de3:	c7 04 24 87 9e 10 80 	movl   $0x80109e87,(%esp)
80103dea:	e8 4b c7 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103def:	a1 9c 42 11 80       	mov    0x8011429c,%eax
80103df4:	85 c0                	test   %eax,%eax
80103df6:	7f 0c                	jg     80103e04 <log_write+0x43>
    panic("log_write outside of trans");
80103df8:	c7 04 24 9d 9e 10 80 	movl   $0x80109e9d,(%esp)
80103dff:	e8 36 c7 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103e04:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e0b:	e8 a5 19 00 00       	call   801057b5 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103e10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e17:	eb 1f                	jmp    80103e38 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e1c:	83 c0 10             	add    $0x10,%eax
80103e1f:	8b 04 85 6c 42 11 80 	mov    -0x7feebd94(,%eax,4),%eax
80103e26:	89 c2                	mov    %eax,%edx
80103e28:	8b 45 08             	mov    0x8(%ebp),%eax
80103e2b:	8b 40 08             	mov    0x8(%eax),%eax
80103e2e:	39 c2                	cmp    %eax,%edx
80103e30:	75 02                	jne    80103e34 <log_write+0x73>
      break;
80103e32:	eb 0e                	jmp    80103e42 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103e34:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103e38:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e3d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e40:	7f d7                	jg     80103e19 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103e42:	8b 45 08             	mov    0x8(%ebp),%eax
80103e45:	8b 40 08             	mov    0x8(%eax),%eax
80103e48:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e4b:	83 c2 10             	add    $0x10,%edx
80103e4e:	89 04 95 6c 42 11 80 	mov    %eax,-0x7feebd94(,%edx,4)
  if (i == log.lh.n)
80103e55:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e5a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e5d:	75 0d                	jne    80103e6c <log_write+0xab>
    log.lh.n++;
80103e5f:	a1 a8 42 11 80       	mov    0x801142a8,%eax
80103e64:	83 c0 01             	add    $0x1,%eax
80103e67:	a3 a8 42 11 80       	mov    %eax,0x801142a8
  b->flags |= B_DIRTY; // prevent eviction
80103e6c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6f:	8b 00                	mov    (%eax),%eax
80103e71:	83 c8 04             	or     $0x4,%eax
80103e74:	89 c2                	mov    %eax,%edx
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103e7b:	c7 04 24 60 42 11 80 	movl   $0x80114260,(%esp)
80103e82:	e8 90 19 00 00       	call   80105817 <release>
}
80103e87:	c9                   	leave  
80103e88:	c3                   	ret    

80103e89 <v2p>:
80103e89:	55                   	push   %ebp
80103e8a:	89 e5                	mov    %esp,%ebp
80103e8c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8f:	05 00 00 00 80       	add    $0x80000000,%eax
80103e94:	5d                   	pop    %ebp
80103e95:	c3                   	ret    

80103e96 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e96:	55                   	push   %ebp
80103e97:	89 e5                	mov    %esp,%ebp
80103e99:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9c:	05 00 00 00 80       	add    $0x80000000,%eax
80103ea1:	5d                   	pop    %ebp
80103ea2:	c3                   	ret    

80103ea3 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103ea3:	55                   	push   %ebp
80103ea4:	89 e5                	mov    %esp,%ebp
80103ea6:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103ea9:	8b 55 08             	mov    0x8(%ebp),%edx
80103eac:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eaf:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103eb2:	f0 87 02             	lock xchg %eax,(%edx)
80103eb5:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103eb8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103ebb:	c9                   	leave  
80103ebc:	c3                   	ret    

80103ebd <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103ebd:	55                   	push   %ebp
80103ebe:	89 e5                	mov    %esp,%ebp
80103ec0:	83 e4 f0             	and    $0xfffffff0,%esp
80103ec3:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103ec6:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103ecd:	80 
80103ece:	c7 04 24 5c 0d 12 80 	movl   $0x80120d5c,(%esp)
80103ed5:	e8 1b f2 ff ff       	call   801030f5 <kinit1>
  kvmalloc();      // kernel page table
80103eda:	e8 95 47 00 00       	call   80108674 <kvmalloc>
  mpinit();        // collect info about this machine
80103edf:	e8 41 04 00 00       	call   80104325 <mpinit>
  lapicinit();
80103ee4:	e8 e6 f5 ff ff       	call   801034cf <lapicinit>
  seginit();       // set up segments
80103ee9:	e8 19 41 00 00       	call   80108007 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103eee:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ef4:	0f b6 00             	movzbl (%eax),%eax
80103ef7:	0f b6 c0             	movzbl %al,%eax
80103efa:	89 44 24 04          	mov    %eax,0x4(%esp)
80103efe:	c7 04 24 b8 9e 10 80 	movl   $0x80109eb8,(%esp)
80103f05:	e8 96 c4 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103f0a:	e8 74 06 00 00       	call   80104583 <picinit>
  ioapicinit();    // another interrupt controller
80103f0f:	e8 d7 f0 ff ff       	call   80102feb <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103f14:	e8 97 cb ff ff       	call   80100ab0 <consoleinit>
  uartinit();      // serial port
80103f19:	e8 38 34 00 00       	call   80107356 <uartinit>
  pinit();         // process table
80103f1e:	e8 6a 0b 00 00       	call   80104a8d <pinit>
  tvinit();        // trap vectors
80103f23:	e8 3a 2f 00 00       	call   80106e62 <tvinit>
  binit();         // buffer cache
80103f28:	e8 07 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f2d:	e8 d8 d0 ff ff       	call   8010100a <fileinit>
  ideinit();       // disk
80103f32:	e8 e6 ec ff ff       	call   80102c1d <ideinit>
  if(!ismp)
80103f37:	a1 44 43 11 80       	mov    0x80114344,%eax
80103f3c:	85 c0                	test   %eax,%eax
80103f3e:	75 05                	jne    80103f45 <main+0x88>
    timerinit();   // uniprocessor timer
80103f40:	e8 68 2e 00 00       	call   80106dad <timerinit>
  startothers();   // start other processors
80103f45:	e8 7f 00 00 00       	call   80103fc9 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f4a:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f51:	8e 
80103f52:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f59:	e8 cf f1 ff ff       	call   8010312d <kinit2>
  userinit();      // first user process
80103f5e:	e8 48 0c 00 00       	call   80104bab <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f63:	e8 1a 00 00 00       	call   80103f82 <mpmain>

80103f68 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f68:	55                   	push   %ebp
80103f69:	89 e5                	mov    %esp,%ebp
80103f6b:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103f6e:	e8 18 47 00 00       	call   8010868b <switchkvm>
  seginit();
80103f73:	e8 8f 40 00 00       	call   80108007 <seginit>
  lapicinit();
80103f78:	e8 52 f5 ff ff       	call   801034cf <lapicinit>
  mpmain();
80103f7d:	e8 00 00 00 00       	call   80103f82 <mpmain>

80103f82 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f82:	55                   	push   %ebp
80103f83:	89 e5                	mov    %esp,%ebp
80103f85:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f88:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f8e:	0f b6 00             	movzbl (%eax),%eax
80103f91:	0f b6 c0             	movzbl %al,%eax
80103f94:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f98:	c7 04 24 cf 9e 10 80 	movl   $0x80109ecf,(%esp)
80103f9f:	e8 fc c3 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103fa4:	e8 2d 30 00 00       	call   80106fd6 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103fa9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103faf:	05 a8 00 00 00       	add    $0xa8,%eax
80103fb4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103fbb:	00 
80103fbc:	89 04 24             	mov    %eax,(%esp)
80103fbf:	e8 df fe ff ff       	call   80103ea3 <xchg>
  scheduler();     // start running processes
80103fc4:	e8 dc 12 00 00       	call   801052a5 <scheduler>

80103fc9 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fc9:	55                   	push   %ebp
80103fca:	89 e5                	mov    %esp,%ebp
80103fcc:	53                   	push   %ebx
80103fcd:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fd0:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fd7:	e8 ba fe ff ff       	call   80103e96 <p2v>
80103fdc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fdf:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fe4:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fe8:	c7 44 24 04 0c d5 10 	movl   $0x8010d50c,0x4(%esp)
80103fef:	80 
80103ff0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ff3:	89 04 24             	mov    %eax,(%esp)
80103ff6:	e8 dd 1a 00 00       	call   80105ad8 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103ffb:	c7 45 f4 60 43 11 80 	movl   $0x80114360,-0xc(%ebp)
80104002:	e9 85 00 00 00       	jmp    8010408c <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80104007:	e8 1c f6 ff ff       	call   80103628 <cpunum>
8010400c:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104012:	05 60 43 11 80       	add    $0x80114360,%eax
80104017:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010401a:	75 02                	jne    8010401e <startothers+0x55>
      continue;
8010401c:	eb 67                	jmp    80104085 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010401e:	e8 29 f2 ff ff       	call   8010324c <kalloc>
80104023:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104026:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104029:	83 e8 04             	sub    $0x4,%eax
8010402c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010402f:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104035:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104037:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010403a:	83 e8 08             	sub    $0x8,%eax
8010403d:	c7 00 68 3f 10 80    	movl   $0x80103f68,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104043:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104046:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104049:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
80104050:	e8 34 fe ff ff       	call   80103e89 <v2p>
80104055:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104057:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010405a:	89 04 24             	mov    %eax,(%esp)
8010405d:	e8 27 fe ff ff       	call   80103e89 <v2p>
80104062:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104065:	0f b6 12             	movzbl (%edx),%edx
80104068:	0f b6 d2             	movzbl %dl,%edx
8010406b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010406f:	89 14 24             	mov    %edx,(%esp)
80104072:	e8 33 f6 ff ff       	call   801036aa <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104077:	90                   	nop
80104078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010407b:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104081:	85 c0                	test   %eax,%eax
80104083:	74 f3                	je     80104078 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104085:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
8010408c:	a1 40 49 11 80       	mov    0x80114940,%eax
80104091:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104097:	05 60 43 11 80       	add    $0x80114360,%eax
8010409c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010409f:	0f 87 62 ff ff ff    	ja     80104007 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801040a5:	83 c4 24             	add    $0x24,%esp
801040a8:	5b                   	pop    %ebx
801040a9:	5d                   	pop    %ebp
801040aa:	c3                   	ret    

801040ab <p2v>:
801040ab:	55                   	push   %ebp
801040ac:	89 e5                	mov    %esp,%ebp
801040ae:	8b 45 08             	mov    0x8(%ebp),%eax
801040b1:	05 00 00 00 80       	add    $0x80000000,%eax
801040b6:	5d                   	pop    %ebp
801040b7:	c3                   	ret    

801040b8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801040b8:	55                   	push   %ebp
801040b9:	89 e5                	mov    %esp,%ebp
801040bb:	83 ec 14             	sub    $0x14,%esp
801040be:	8b 45 08             	mov    0x8(%ebp),%eax
801040c1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040c5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801040c9:	89 c2                	mov    %eax,%edx
801040cb:	ec                   	in     (%dx),%al
801040cc:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801040cf:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801040d3:	c9                   	leave  
801040d4:	c3                   	ret    

801040d5 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040d5:	55                   	push   %ebp
801040d6:	89 e5                	mov    %esp,%ebp
801040d8:	83 ec 08             	sub    $0x8,%esp
801040db:	8b 55 08             	mov    0x8(%ebp),%edx
801040de:	8b 45 0c             	mov    0xc(%ebp),%eax
801040e1:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040e5:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040e8:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040ec:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040f0:	ee                   	out    %al,(%dx)
}
801040f1:	c9                   	leave  
801040f2:	c3                   	ret    

801040f3 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040f3:	55                   	push   %ebp
801040f4:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040f6:	a1 44 d6 10 80       	mov    0x8010d644,%eax
801040fb:	89 c2                	mov    %eax,%edx
801040fd:	b8 60 43 11 80       	mov    $0x80114360,%eax
80104102:	29 c2                	sub    %eax,%edx
80104104:	89 d0                	mov    %edx,%eax
80104106:	c1 f8 02             	sar    $0x2,%eax
80104109:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010410f:	5d                   	pop    %ebp
80104110:	c3                   	ret    

80104111 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104111:	55                   	push   %ebp
80104112:	89 e5                	mov    %esp,%ebp
80104114:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104117:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010411e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104125:	eb 15                	jmp    8010413c <sum+0x2b>
    sum += addr[i];
80104127:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010412a:	8b 45 08             	mov    0x8(%ebp),%eax
8010412d:	01 d0                	add    %edx,%eax
8010412f:	0f b6 00             	movzbl (%eax),%eax
80104132:	0f b6 c0             	movzbl %al,%eax
80104135:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104138:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010413c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010413f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104142:	7c e3                	jl     80104127 <sum+0x16>
    sum += addr[i];
  return sum;
80104144:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104147:	c9                   	leave  
80104148:	c3                   	ret    

80104149 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104149:	55                   	push   %ebp
8010414a:	89 e5                	mov    %esp,%ebp
8010414c:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
8010414f:	8b 45 08             	mov    0x8(%ebp),%eax
80104152:	89 04 24             	mov    %eax,(%esp)
80104155:	e8 51 ff ff ff       	call   801040ab <p2v>
8010415a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010415d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104160:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104163:	01 d0                	add    %edx,%eax
80104165:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104168:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010416b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010416e:	eb 3f                	jmp    801041af <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104170:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104177:	00 
80104178:	c7 44 24 04 e0 9e 10 	movl   $0x80109ee0,0x4(%esp)
8010417f:	80 
80104180:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104183:	89 04 24             	mov    %eax,(%esp)
80104186:	e8 f5 18 00 00       	call   80105a80 <memcmp>
8010418b:	85 c0                	test   %eax,%eax
8010418d:	75 1c                	jne    801041ab <mpsearch1+0x62>
8010418f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104196:	00 
80104197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010419a:	89 04 24             	mov    %eax,(%esp)
8010419d:	e8 6f ff ff ff       	call   80104111 <sum>
801041a2:	84 c0                	test   %al,%al
801041a4:	75 05                	jne    801041ab <mpsearch1+0x62>
      return (struct mp*)p;
801041a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a9:	eb 11                	jmp    801041bc <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801041ab:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801041af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801041b5:	72 b9                	jb     80104170 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801041b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041bc:	c9                   	leave  
801041bd:	c3                   	ret    

801041be <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801041be:	55                   	push   %ebp
801041bf:	89 e5                	mov    %esp,%ebp
801041c1:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041c4:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ce:	83 c0 0f             	add    $0xf,%eax
801041d1:	0f b6 00             	movzbl (%eax),%eax
801041d4:	0f b6 c0             	movzbl %al,%eax
801041d7:	c1 e0 08             	shl    $0x8,%eax
801041da:	89 c2                	mov    %eax,%edx
801041dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041df:	83 c0 0e             	add    $0xe,%eax
801041e2:	0f b6 00             	movzbl (%eax),%eax
801041e5:	0f b6 c0             	movzbl %al,%eax
801041e8:	09 d0                	or     %edx,%eax
801041ea:	c1 e0 04             	shl    $0x4,%eax
801041ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041f4:	74 21                	je     80104217 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041f6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041fd:	00 
801041fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104201:	89 04 24             	mov    %eax,(%esp)
80104204:	e8 40 ff ff ff       	call   80104149 <mpsearch1>
80104209:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010420c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104210:	74 50                	je     80104262 <mpsearch+0xa4>
      return mp;
80104212:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104215:	eb 5f                	jmp    80104276 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421a:	83 c0 14             	add    $0x14,%eax
8010421d:	0f b6 00             	movzbl (%eax),%eax
80104220:	0f b6 c0             	movzbl %al,%eax
80104223:	c1 e0 08             	shl    $0x8,%eax
80104226:	89 c2                	mov    %eax,%edx
80104228:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422b:	83 c0 13             	add    $0x13,%eax
8010422e:	0f b6 00             	movzbl (%eax),%eax
80104231:	0f b6 c0             	movzbl %al,%eax
80104234:	09 d0                	or     %edx,%eax
80104236:	c1 e0 0a             	shl    $0xa,%eax
80104239:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
8010423c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010423f:	2d 00 04 00 00       	sub    $0x400,%eax
80104244:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010424b:	00 
8010424c:	89 04 24             	mov    %eax,(%esp)
8010424f:	e8 f5 fe ff ff       	call   80104149 <mpsearch1>
80104254:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104257:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010425b:	74 05                	je     80104262 <mpsearch+0xa4>
      return mp;
8010425d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104260:	eb 14                	jmp    80104276 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104262:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104269:	00 
8010426a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104271:	e8 d3 fe ff ff       	call   80104149 <mpsearch1>
}
80104276:	c9                   	leave  
80104277:	c3                   	ret    

80104278 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104278:	55                   	push   %ebp
80104279:	89 e5                	mov    %esp,%ebp
8010427b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010427e:	e8 3b ff ff ff       	call   801041be <mpsearch>
80104283:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104286:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010428a:	74 0a                	je     80104296 <mpconfig+0x1e>
8010428c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428f:	8b 40 04             	mov    0x4(%eax),%eax
80104292:	85 c0                	test   %eax,%eax
80104294:	75 0a                	jne    801042a0 <mpconfig+0x28>
    return 0;
80104296:	b8 00 00 00 00       	mov    $0x0,%eax
8010429b:	e9 83 00 00 00       	jmp    80104323 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801042a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a3:	8b 40 04             	mov    0x4(%eax),%eax
801042a6:	89 04 24             	mov    %eax,(%esp)
801042a9:	e8 fd fd ff ff       	call   801040ab <p2v>
801042ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801042b1:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801042b8:	00 
801042b9:	c7 44 24 04 e5 9e 10 	movl   $0x80109ee5,0x4(%esp)
801042c0:	80 
801042c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042c4:	89 04 24             	mov    %eax,(%esp)
801042c7:	e8 b4 17 00 00       	call   80105a80 <memcmp>
801042cc:	85 c0                	test   %eax,%eax
801042ce:	74 07                	je     801042d7 <mpconfig+0x5f>
    return 0;
801042d0:	b8 00 00 00 00       	mov    $0x0,%eax
801042d5:	eb 4c                	jmp    80104323 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042da:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042de:	3c 01                	cmp    $0x1,%al
801042e0:	74 12                	je     801042f4 <mpconfig+0x7c>
801042e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042e5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042e9:	3c 04                	cmp    $0x4,%al
801042eb:	74 07                	je     801042f4 <mpconfig+0x7c>
    return 0;
801042ed:	b8 00 00 00 00       	mov    $0x0,%eax
801042f2:	eb 2f                	jmp    80104323 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042f7:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042fb:	0f b7 c0             	movzwl %ax,%eax
801042fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80104302:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104305:	89 04 24             	mov    %eax,(%esp)
80104308:	e8 04 fe ff ff       	call   80104111 <sum>
8010430d:	84 c0                	test   %al,%al
8010430f:	74 07                	je     80104318 <mpconfig+0xa0>
    return 0;
80104311:	b8 00 00 00 00       	mov    $0x0,%eax
80104316:	eb 0b                	jmp    80104323 <mpconfig+0xab>
  *pmp = mp;
80104318:	8b 45 08             	mov    0x8(%ebp),%eax
8010431b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010431e:	89 10                	mov    %edx,(%eax)
  return conf;
80104320:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104323:	c9                   	leave  
80104324:	c3                   	ret    

80104325 <mpinit>:

void
mpinit(void)
{
80104325:	55                   	push   %ebp
80104326:	89 e5                	mov    %esp,%ebp
80104328:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010432b:	c7 05 44 d6 10 80 60 	movl   $0x80114360,0x8010d644
80104332:	43 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104335:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104338:	89 04 24             	mov    %eax,(%esp)
8010433b:	e8 38 ff ff ff       	call   80104278 <mpconfig>
80104340:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104343:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104347:	75 05                	jne    8010434e <mpinit+0x29>
    return;
80104349:	e9 9c 01 00 00       	jmp    801044ea <mpinit+0x1c5>
  ismp = 1;
8010434e:	c7 05 44 43 11 80 01 	movl   $0x1,0x80114344
80104355:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010435b:	8b 40 24             	mov    0x24(%eax),%eax
8010435e:	a3 5c 42 11 80       	mov    %eax,0x8011425c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104363:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104366:	83 c0 2c             	add    $0x2c,%eax
80104369:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010436c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010436f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104373:	0f b7 d0             	movzwl %ax,%edx
80104376:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104379:	01 d0                	add    %edx,%eax
8010437b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010437e:	e9 f4 00 00 00       	jmp    80104477 <mpinit+0x152>
    switch(*p){
80104383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104386:	0f b6 00             	movzbl (%eax),%eax
80104389:	0f b6 c0             	movzbl %al,%eax
8010438c:	83 f8 04             	cmp    $0x4,%eax
8010438f:	0f 87 bf 00 00 00    	ja     80104454 <mpinit+0x12f>
80104395:	8b 04 85 28 9f 10 80 	mov    -0x7fef60d8(,%eax,4),%eax
8010439c:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
8010439e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a1:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801043a4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043a7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043ab:	0f b6 d0             	movzbl %al,%edx
801043ae:	a1 40 49 11 80       	mov    0x80114940,%eax
801043b3:	39 c2                	cmp    %eax,%edx
801043b5:	74 2d                	je     801043e4 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801043b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043ba:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043be:	0f b6 d0             	movzbl %al,%edx
801043c1:	a1 40 49 11 80       	mov    0x80114940,%eax
801043c6:	89 54 24 08          	mov    %edx,0x8(%esp)
801043ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801043ce:	c7 04 24 ea 9e 10 80 	movl   $0x80109eea,(%esp)
801043d5:	e8 c6 bf ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801043da:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
801043e1:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043e7:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043eb:	0f b6 c0             	movzbl %al,%eax
801043ee:	83 e0 02             	and    $0x2,%eax
801043f1:	85 c0                	test   %eax,%eax
801043f3:	74 15                	je     8010440a <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801043f5:	a1 40 49 11 80       	mov    0x80114940,%eax
801043fa:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104400:	05 60 43 11 80       	add    $0x80114360,%eax
80104405:	a3 44 d6 10 80       	mov    %eax,0x8010d644
      cpus[ncpu].id = ncpu;
8010440a:	8b 15 40 49 11 80    	mov    0x80114940,%edx
80104410:	a1 40 49 11 80       	mov    0x80114940,%eax
80104415:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
8010441b:	81 c2 60 43 11 80    	add    $0x80114360,%edx
80104421:	88 02                	mov    %al,(%edx)
      ncpu++;
80104423:	a1 40 49 11 80       	mov    0x80114940,%eax
80104428:	83 c0 01             	add    $0x1,%eax
8010442b:	a3 40 49 11 80       	mov    %eax,0x80114940
      p += sizeof(struct mpproc);
80104430:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104434:	eb 41                	jmp    80104477 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104436:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104439:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
8010443c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010443f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104443:	a2 40 43 11 80       	mov    %al,0x80114340
      p += sizeof(struct mpioapic);
80104448:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010444c:	eb 29                	jmp    80104477 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010444e:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104452:	eb 23                	jmp    80104477 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104454:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104457:	0f b6 00             	movzbl (%eax),%eax
8010445a:	0f b6 c0             	movzbl %al,%eax
8010445d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104461:	c7 04 24 08 9f 10 80 	movl   $0x80109f08,(%esp)
80104468:	e8 33 bf ff ff       	call   801003a0 <cprintf>
      ismp = 0;
8010446d:	c7 05 44 43 11 80 00 	movl   $0x0,0x80114344
80104474:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104477:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010447d:	0f 82 00 ff ff ff    	jb     80104383 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104483:	a1 44 43 11 80       	mov    0x80114344,%eax
80104488:	85 c0                	test   %eax,%eax
8010448a:	75 1d                	jne    801044a9 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
8010448c:	c7 05 40 49 11 80 01 	movl   $0x1,0x80114940
80104493:	00 00 00 
    lapic = 0;
80104496:	c7 05 5c 42 11 80 00 	movl   $0x0,0x8011425c
8010449d:	00 00 00 
    ioapicid = 0;
801044a0:	c6 05 40 43 11 80 00 	movb   $0x0,0x80114340
    return;
801044a7:	eb 41                	jmp    801044ea <mpinit+0x1c5>
  }

  if(mp->imcrp){
801044a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044ac:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801044b0:	84 c0                	test   %al,%al
801044b2:	74 36                	je     801044ea <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801044b4:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801044bb:	00 
801044bc:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801044c3:	e8 0d fc ff ff       	call   801040d5 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044c8:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044cf:	e8 e4 fb ff ff       	call   801040b8 <inb>
801044d4:	83 c8 01             	or     $0x1,%eax
801044d7:	0f b6 c0             	movzbl %al,%eax
801044da:	89 44 24 04          	mov    %eax,0x4(%esp)
801044de:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044e5:	e8 eb fb ff ff       	call   801040d5 <outb>
  }
}
801044ea:	c9                   	leave  
801044eb:	c3                   	ret    

801044ec <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044ec:	55                   	push   %ebp
801044ed:	89 e5                	mov    %esp,%ebp
801044ef:	83 ec 08             	sub    $0x8,%esp
801044f2:	8b 55 08             	mov    0x8(%ebp),%edx
801044f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801044f8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044fc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044ff:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104503:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104507:	ee                   	out    %al,(%dx)
}
80104508:	c9                   	leave  
80104509:	c3                   	ret    

8010450a <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010450a:	55                   	push   %ebp
8010450b:	89 e5                	mov    %esp,%ebp
8010450d:	83 ec 0c             	sub    $0xc,%esp
80104510:	8b 45 08             	mov    0x8(%ebp),%eax
80104513:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104517:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010451b:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
80104521:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104525:	0f b6 c0             	movzbl %al,%eax
80104528:	89 44 24 04          	mov    %eax,0x4(%esp)
8010452c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104533:	e8 b4 ff ff ff       	call   801044ec <outb>
  outb(IO_PIC2+1, mask >> 8);
80104538:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010453c:	66 c1 e8 08          	shr    $0x8,%ax
80104540:	0f b6 c0             	movzbl %al,%eax
80104543:	89 44 24 04          	mov    %eax,0x4(%esp)
80104547:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010454e:	e8 99 ff ff ff       	call   801044ec <outb>
}
80104553:	c9                   	leave  
80104554:	c3                   	ret    

80104555 <picenable>:

void
picenable(int irq)
{
80104555:	55                   	push   %ebp
80104556:	89 e5                	mov    %esp,%ebp
80104558:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
8010455b:	8b 45 08             	mov    0x8(%ebp),%eax
8010455e:	ba 01 00 00 00       	mov    $0x1,%edx
80104563:	89 c1                	mov    %eax,%ecx
80104565:	d3 e2                	shl    %cl,%edx
80104567:	89 d0                	mov    %edx,%eax
80104569:	f7 d0                	not    %eax
8010456b:	89 c2                	mov    %eax,%edx
8010456d:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104574:	21 d0                	and    %edx,%eax
80104576:	0f b7 c0             	movzwl %ax,%eax
80104579:	89 04 24             	mov    %eax,(%esp)
8010457c:	e8 89 ff ff ff       	call   8010450a <picsetmask>
}
80104581:	c9                   	leave  
80104582:	c3                   	ret    

80104583 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104583:	55                   	push   %ebp
80104584:	89 e5                	mov    %esp,%ebp
80104586:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104589:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104590:	00 
80104591:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104598:	e8 4f ff ff ff       	call   801044ec <outb>
  outb(IO_PIC2+1, 0xFF);
8010459d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801045a4:	00 
801045a5:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045ac:	e8 3b ff ff ff       	call   801044ec <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801045b1:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045b8:	00 
801045b9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045c0:	e8 27 ff ff ff       	call   801044ec <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045c5:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045cc:	00 
801045cd:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045d4:	e8 13 ff ff ff       	call   801044ec <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045d9:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045e0:	00 
801045e1:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045e8:	e8 ff fe ff ff       	call   801044ec <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045ed:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045f4:	00 
801045f5:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045fc:	e8 eb fe ff ff       	call   801044ec <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104601:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104608:	00 
80104609:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104610:	e8 d7 fe ff ff       	call   801044ec <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104615:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010461c:	00 
8010461d:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104624:	e8 c3 fe ff ff       	call   801044ec <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104629:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104630:	00 
80104631:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104638:	e8 af fe ff ff       	call   801044ec <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
8010463d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104644:	00 
80104645:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010464c:	e8 9b fe ff ff       	call   801044ec <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104651:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104658:	00 
80104659:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104660:	e8 87 fe ff ff       	call   801044ec <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104665:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010466c:	00 
8010466d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104674:	e8 73 fe ff ff       	call   801044ec <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104679:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104680:	00 
80104681:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104688:	e8 5f fe ff ff       	call   801044ec <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010468d:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104694:	00 
80104695:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010469c:	e8 4b fe ff ff       	call   801044ec <outb>

  if(irqmask != 0xFFFF)
801046a1:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801046a8:	66 83 f8 ff          	cmp    $0xffff,%ax
801046ac:	74 12                	je     801046c0 <picinit+0x13d>
    picsetmask(irqmask);
801046ae:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801046b5:	0f b7 c0             	movzwl %ax,%eax
801046b8:	89 04 24             	mov    %eax,(%esp)
801046bb:	e8 4a fe ff ff       	call   8010450a <picsetmask>
}
801046c0:	c9                   	leave  
801046c1:	c3                   	ret    

801046c2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801046c2:	55                   	push   %ebp
801046c3:	89 e5                	mov    %esp,%ebp
801046c5:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801046db:	8b 10                	mov    (%eax),%edx
801046dd:	8b 45 08             	mov    0x8(%ebp),%eax
801046e0:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046e2:	e8 3f c9 ff ff       	call   80101026 <filealloc>
801046e7:	8b 55 08             	mov    0x8(%ebp),%edx
801046ea:	89 02                	mov    %eax,(%edx)
801046ec:	8b 45 08             	mov    0x8(%ebp),%eax
801046ef:	8b 00                	mov    (%eax),%eax
801046f1:	85 c0                	test   %eax,%eax
801046f3:	0f 84 c8 00 00 00    	je     801047c1 <pipealloc+0xff>
801046f9:	e8 28 c9 ff ff       	call   80101026 <filealloc>
801046fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80104701:	89 02                	mov    %eax,(%edx)
80104703:	8b 45 0c             	mov    0xc(%ebp),%eax
80104706:	8b 00                	mov    (%eax),%eax
80104708:	85 c0                	test   %eax,%eax
8010470a:	0f 84 b1 00 00 00    	je     801047c1 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104710:	e8 37 eb ff ff       	call   8010324c <kalloc>
80104715:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104718:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010471c:	75 05                	jne    80104723 <pipealloc+0x61>
    goto bad;
8010471e:	e9 9e 00 00 00       	jmp    801047c1 <pipealloc+0xff>
  p->readopen = 1;
80104723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104726:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010472d:	00 00 00 
  p->writeopen = 1;
80104730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104733:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010473a:	00 00 00 
  p->nwrite = 0;
8010473d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104740:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104747:	00 00 00 
  p->nread = 0;
8010474a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474d:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104754:	00 00 00 
  initlock(&p->lock, "pipe");
80104757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010475a:	c7 44 24 04 3c 9f 10 	movl   $0x80109f3c,0x4(%esp)
80104761:	80 
80104762:	89 04 24             	mov    %eax,(%esp)
80104765:	e8 2a 10 00 00       	call   80105794 <initlock>
  (*f0)->type = FD_PIPE;
8010476a:	8b 45 08             	mov    0x8(%ebp),%eax
8010476d:	8b 00                	mov    (%eax),%eax
8010476f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104775:	8b 45 08             	mov    0x8(%ebp),%eax
80104778:	8b 00                	mov    (%eax),%eax
8010477a:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010477e:	8b 45 08             	mov    0x8(%ebp),%eax
80104781:	8b 00                	mov    (%eax),%eax
80104783:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104787:	8b 45 08             	mov    0x8(%ebp),%eax
8010478a:	8b 00                	mov    (%eax),%eax
8010478c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010478f:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104792:	8b 45 0c             	mov    0xc(%ebp),%eax
80104795:	8b 00                	mov    (%eax),%eax
80104797:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010479d:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a0:	8b 00                	mov    (%eax),%eax
801047a2:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801047a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a9:	8b 00                	mov    (%eax),%eax
801047ab:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801047af:	8b 45 0c             	mov    0xc(%ebp),%eax
801047b2:	8b 00                	mov    (%eax),%eax
801047b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047b7:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801047ba:	b8 00 00 00 00       	mov    $0x0,%eax
801047bf:	eb 42                	jmp    80104803 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801047c1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047c5:	74 0b                	je     801047d2 <pipealloc+0x110>
    kfree((char*)p);
801047c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ca:	89 04 24             	mov    %eax,(%esp)
801047cd:	e8 b8 e9 ff ff       	call   8010318a <kfree>
  if(*f0)
801047d2:	8b 45 08             	mov    0x8(%ebp),%eax
801047d5:	8b 00                	mov    (%eax),%eax
801047d7:	85 c0                	test   %eax,%eax
801047d9:	74 0d                	je     801047e8 <pipealloc+0x126>
    fileclose(*f0);
801047db:	8b 45 08             	mov    0x8(%ebp),%eax
801047de:	8b 00                	mov    (%eax),%eax
801047e0:	89 04 24             	mov    %eax,(%esp)
801047e3:	e8 e6 c8 ff ff       	call   801010ce <fileclose>
  if(*f1)
801047e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801047eb:	8b 00                	mov    (%eax),%eax
801047ed:	85 c0                	test   %eax,%eax
801047ef:	74 0d                	je     801047fe <pipealloc+0x13c>
    fileclose(*f1);
801047f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801047f4:	8b 00                	mov    (%eax),%eax
801047f6:	89 04 24             	mov    %eax,(%esp)
801047f9:	e8 d0 c8 ff ff       	call   801010ce <fileclose>
  return -1;
801047fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104803:	c9                   	leave  
80104804:	c3                   	ret    

80104805 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104805:	55                   	push   %ebp
80104806:	89 e5                	mov    %esp,%ebp
80104808:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010480b:	8b 45 08             	mov    0x8(%ebp),%eax
8010480e:	89 04 24             	mov    %eax,(%esp)
80104811:	e8 9f 0f 00 00       	call   801057b5 <acquire>
  if(writable){
80104816:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010481a:	74 1f                	je     8010483b <pipeclose+0x36>
    p->writeopen = 0;
8010481c:	8b 45 08             	mov    0x8(%ebp),%eax
8010481f:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104826:	00 00 00 
    wakeup(&p->nread);
80104829:	8b 45 08             	mov    0x8(%ebp),%eax
8010482c:	05 34 02 00 00       	add    $0x234,%eax
80104831:	89 04 24             	mov    %eax,(%esp)
80104834:	e8 06 0d 00 00       	call   8010553f <wakeup>
80104839:	eb 1d                	jmp    80104858 <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010483b:	8b 45 08             	mov    0x8(%ebp),%eax
8010483e:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104845:	00 00 00 
    wakeup(&p->nwrite);
80104848:	8b 45 08             	mov    0x8(%ebp),%eax
8010484b:	05 38 02 00 00       	add    $0x238,%eax
80104850:	89 04 24             	mov    %eax,(%esp)
80104853:	e8 e7 0c 00 00       	call   8010553f <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104858:	8b 45 08             	mov    0x8(%ebp),%eax
8010485b:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104861:	85 c0                	test   %eax,%eax
80104863:	75 25                	jne    8010488a <pipeclose+0x85>
80104865:	8b 45 08             	mov    0x8(%ebp),%eax
80104868:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010486e:	85 c0                	test   %eax,%eax
80104870:	75 18                	jne    8010488a <pipeclose+0x85>
    release(&p->lock);
80104872:	8b 45 08             	mov    0x8(%ebp),%eax
80104875:	89 04 24             	mov    %eax,(%esp)
80104878:	e8 9a 0f 00 00       	call   80105817 <release>
    kfree((char*)p);
8010487d:	8b 45 08             	mov    0x8(%ebp),%eax
80104880:	89 04 24             	mov    %eax,(%esp)
80104883:	e8 02 e9 ff ff       	call   8010318a <kfree>
80104888:	eb 0b                	jmp    80104895 <pipeclose+0x90>
  } else
    release(&p->lock);
8010488a:	8b 45 08             	mov    0x8(%ebp),%eax
8010488d:	89 04 24             	mov    %eax,(%esp)
80104890:	e8 82 0f 00 00       	call   80105817 <release>
}
80104895:	c9                   	leave  
80104896:	c3                   	ret    

80104897 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104897:	55                   	push   %ebp
80104898:	89 e5                	mov    %esp,%ebp
8010489a:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
8010489d:	8b 45 08             	mov    0x8(%ebp),%eax
801048a0:	89 04 24             	mov    %eax,(%esp)
801048a3:	e8 0d 0f 00 00       	call   801057b5 <acquire>
  for(i = 0; i < n; i++){
801048a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801048af:	e9 a6 00 00 00       	jmp    8010495a <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801048b4:	eb 57                	jmp    8010490d <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801048b6:	8b 45 08             	mov    0x8(%ebp),%eax
801048b9:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048bf:	85 c0                	test   %eax,%eax
801048c1:	74 0d                	je     801048d0 <pipewrite+0x39>
801048c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c9:	8b 40 24             	mov    0x24(%eax),%eax
801048cc:	85 c0                	test   %eax,%eax
801048ce:	74 15                	je     801048e5 <pipewrite+0x4e>
        release(&p->lock);
801048d0:	8b 45 08             	mov    0x8(%ebp),%eax
801048d3:	89 04 24             	mov    %eax,(%esp)
801048d6:	e8 3c 0f 00 00       	call   80105817 <release>
        return -1;
801048db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048e0:	e9 9f 00 00 00       	jmp    80104984 <pipewrite+0xed>
      }
      wakeup(&p->nread);
801048e5:	8b 45 08             	mov    0x8(%ebp),%eax
801048e8:	05 34 02 00 00       	add    $0x234,%eax
801048ed:	89 04 24             	mov    %eax,(%esp)
801048f0:	e8 4a 0c 00 00       	call   8010553f <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048f5:	8b 45 08             	mov    0x8(%ebp),%eax
801048f8:	8b 55 08             	mov    0x8(%ebp),%edx
801048fb:	81 c2 38 02 00 00    	add    $0x238,%edx
80104901:	89 44 24 04          	mov    %eax,0x4(%esp)
80104905:	89 14 24             	mov    %edx,(%esp)
80104908:	e8 56 0b 00 00       	call   80105463 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010490d:	8b 45 08             	mov    0x8(%ebp),%eax
80104910:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104916:	8b 45 08             	mov    0x8(%ebp),%eax
80104919:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010491f:	05 00 02 00 00       	add    $0x200,%eax
80104924:	39 c2                	cmp    %eax,%edx
80104926:	74 8e                	je     801048b6 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104928:	8b 45 08             	mov    0x8(%ebp),%eax
8010492b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104931:	8d 48 01             	lea    0x1(%eax),%ecx
80104934:	8b 55 08             	mov    0x8(%ebp),%edx
80104937:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010493d:	25 ff 01 00 00       	and    $0x1ff,%eax
80104942:	89 c1                	mov    %eax,%ecx
80104944:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104947:	8b 45 0c             	mov    0xc(%ebp),%eax
8010494a:	01 d0                	add    %edx,%eax
8010494c:	0f b6 10             	movzbl (%eax),%edx
8010494f:	8b 45 08             	mov    0x8(%ebp),%eax
80104952:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104956:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010495a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010495d:	3b 45 10             	cmp    0x10(%ebp),%eax
80104960:	0f 8c 4e ff ff ff    	jl     801048b4 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104966:	8b 45 08             	mov    0x8(%ebp),%eax
80104969:	05 34 02 00 00       	add    $0x234,%eax
8010496e:	89 04 24             	mov    %eax,(%esp)
80104971:	e8 c9 0b 00 00       	call   8010553f <wakeup>
  release(&p->lock);
80104976:	8b 45 08             	mov    0x8(%ebp),%eax
80104979:	89 04 24             	mov    %eax,(%esp)
8010497c:	e8 96 0e 00 00       	call   80105817 <release>
  return n;
80104981:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104984:	c9                   	leave  
80104985:	c3                   	ret    

80104986 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104986:	55                   	push   %ebp
80104987:	89 e5                	mov    %esp,%ebp
80104989:	53                   	push   %ebx
8010498a:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010498d:	8b 45 08             	mov    0x8(%ebp),%eax
80104990:	89 04 24             	mov    %eax,(%esp)
80104993:	e8 1d 0e 00 00       	call   801057b5 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104998:	eb 3a                	jmp    801049d4 <piperead+0x4e>
    if(proc->killed){
8010499a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a0:	8b 40 24             	mov    0x24(%eax),%eax
801049a3:	85 c0                	test   %eax,%eax
801049a5:	74 15                	je     801049bc <piperead+0x36>
      release(&p->lock);
801049a7:	8b 45 08             	mov    0x8(%ebp),%eax
801049aa:	89 04 24             	mov    %eax,(%esp)
801049ad:	e8 65 0e 00 00       	call   80105817 <release>
      return -1;
801049b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049b7:	e9 b5 00 00 00       	jmp    80104a71 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801049bc:	8b 45 08             	mov    0x8(%ebp),%eax
801049bf:	8b 55 08             	mov    0x8(%ebp),%edx
801049c2:	81 c2 34 02 00 00    	add    $0x234,%edx
801049c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801049cc:	89 14 24             	mov    %edx,(%esp)
801049cf:	e8 8f 0a 00 00       	call   80105463 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049d4:	8b 45 08             	mov    0x8(%ebp),%eax
801049d7:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049dd:	8b 45 08             	mov    0x8(%ebp),%eax
801049e0:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049e6:	39 c2                	cmp    %eax,%edx
801049e8:	75 0d                	jne    801049f7 <piperead+0x71>
801049ea:	8b 45 08             	mov    0x8(%ebp),%eax
801049ed:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049f3:	85 c0                	test   %eax,%eax
801049f5:	75 a3                	jne    8010499a <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049fe:	eb 4b                	jmp    80104a4b <piperead+0xc5>
    if(p->nread == p->nwrite)
80104a00:	8b 45 08             	mov    0x8(%ebp),%eax
80104a03:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a09:	8b 45 08             	mov    0x8(%ebp),%eax
80104a0c:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a12:	39 c2                	cmp    %eax,%edx
80104a14:	75 02                	jne    80104a18 <piperead+0x92>
      break;
80104a16:	eb 3b                	jmp    80104a53 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104a18:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a1e:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104a21:	8b 45 08             	mov    0x8(%ebp),%eax
80104a24:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a2a:	8d 48 01             	lea    0x1(%eax),%ecx
80104a2d:	8b 55 08             	mov    0x8(%ebp),%edx
80104a30:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
80104a36:	25 ff 01 00 00       	and    $0x1ff,%eax
80104a3b:	89 c2                	mov    %eax,%edx
80104a3d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a40:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
80104a45:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a47:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4e:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a51:	7c ad                	jl     80104a00 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a53:	8b 45 08             	mov    0x8(%ebp),%eax
80104a56:	05 38 02 00 00       	add    $0x238,%eax
80104a5b:	89 04 24             	mov    %eax,(%esp)
80104a5e:	e8 dc 0a 00 00       	call   8010553f <wakeup>
  release(&p->lock);
80104a63:	8b 45 08             	mov    0x8(%ebp),%eax
80104a66:	89 04 24             	mov    %eax,(%esp)
80104a69:	e8 a9 0d 00 00       	call   80105817 <release>
  return i;
80104a6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a71:	83 c4 24             	add    $0x24,%esp
80104a74:	5b                   	pop    %ebx
80104a75:	5d                   	pop    %ebp
80104a76:	c3                   	ret    

80104a77 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a77:	55                   	push   %ebp
80104a78:	89 e5                	mov    %esp,%ebp
80104a7a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a7d:	9c                   	pushf  
80104a7e:	58                   	pop    %eax
80104a7f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104a82:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a85:	c9                   	leave  
80104a86:	c3                   	ret    

80104a87 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a87:	55                   	push   %ebp
80104a88:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a8a:	fb                   	sti    
}
80104a8b:	5d                   	pop    %ebp
80104a8c:	c3                   	ret    

80104a8d <pinit>:

static void wakeup1(void *chan);
int findNextOpenPage(char *a);
void
pinit(void)
{
80104a8d:	55                   	push   %ebp
80104a8e:	89 e5                	mov    %esp,%ebp
80104a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a93:	c7 44 24 04 41 9f 10 	movl   $0x80109f41,0x4(%esp)
80104a9a:	80 
80104a9b:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104aa2:	e8 ed 0c 00 00       	call   80105794 <initlock>
}
80104aa7:	c9                   	leave  
80104aa8:	c3                   	ret    

80104aa9 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104aa9:	55                   	push   %ebp
80104aaa:	89 e5                	mov    %esp,%ebp
80104aac:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104aaf:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104ab6:	e8 fa 0c 00 00       	call   801057b5 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104abb:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80104ac2:	eb 53                	jmp    80104b17 <allocproc+0x6e>
    if(p->state == UNUSED)
80104ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac7:	8b 40 0c             	mov    0xc(%eax),%eax
80104aca:	85 c0                	test   %eax,%eax
80104acc:	75 42                	jne    80104b10 <allocproc+0x67>
      goto found;
80104ace:	90                   	nop
    release(&ptable.lock);
    return 0;

    found:
    p->state = EMBRYO;
80104acf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad2:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
    p->pid = nextpid++;
80104ad9:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104ade:	8d 50 01             	lea    0x1(%eax),%edx
80104ae1:	89 15 04 d0 10 80    	mov    %edx,0x8010d004
80104ae7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104aea:	89 42 10             	mov    %eax,0x10(%edx)
    release(&ptable.lock);
80104aed:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104af4:	e8 1e 0d 00 00       	call   80105817 <release>

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
80104af9:	e8 4e e7 ff ff       	call   8010324c <kalloc>
80104afe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b01:	89 42 08             	mov    %eax,0x8(%edx)
80104b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b07:	8b 40 08             	mov    0x8(%eax),%eax
80104b0a:	85 c0                	test   %eax,%eax
80104b0c:	75 36                	jne    80104b44 <allocproc+0x9b>
80104b0e:	eb 23                	jmp    80104b33 <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104b10:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80104b17:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
80104b1e:	72 a4                	jb     80104ac4 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
    release(&ptable.lock);
80104b20:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80104b27:	e8 eb 0c 00 00       	call   80105817 <release>
    return 0;
80104b2c:	b8 00 00 00 00       	mov    $0x0,%eax
80104b31:	eb 76                	jmp    80104ba9 <allocproc+0x100>
    p->pid = nextpid++;
    release(&ptable.lock);

  // Allocate kernel stack.
    if((p->kstack = kalloc()) == 0){
      p->state = UNUSED;
80104b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b36:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
      return 0;
80104b3d:	b8 00 00 00 00       	mov    $0x0,%eax
80104b42:	eb 65                	jmp    80104ba9 <allocproc+0x100>
    }
    sp = p->kstack + KSTACKSIZE;
80104b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b47:	8b 40 08             	mov    0x8(%eax),%eax
80104b4a:	05 00 10 00 00       	add    $0x1000,%eax
80104b4f:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
    sp -= sizeof *p->tf;
80104b52:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
    p->tf = (struct trapframe*)sp;
80104b56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b59:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b5c:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
    sp -= 4;
80104b5f:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
    *(uint*)sp = (uint)trapret;
80104b63:	ba 1d 6e 10 80       	mov    $0x80106e1d,%edx
80104b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b6b:	89 10                	mov    %edx,(%eax)

    sp -= sizeof *p->context;
80104b6d:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
    p->context = (struct context*)sp;
80104b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b74:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b77:	89 50 1c             	mov    %edx,0x1c(%eax)
    memset(p->context, 0, sizeof *p->context);
80104b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7d:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b80:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b87:	00 
80104b88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b8f:	00 
80104b90:	89 04 24             	mov    %eax,(%esp)
80104b93:	e8 71 0e 00 00       	call   80105a09 <memset>
    p->context->eip = (uint)forkret;
80104b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9b:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b9e:	ba 24 54 10 80       	mov    $0x80105424,%edx
80104ba3:	89 50 10             	mov    %edx,0x10(%eax)
  //create page file
  //createSwapFile(p);

    return p;
80104ba6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  }
80104ba9:	c9                   	leave  
80104baa:	c3                   	ret    

80104bab <userinit>:

//PAGEBREAK: 32
// Set up first user process.
  void
  userinit(void)
  {
80104bab:	55                   	push   %ebp
80104bac:	89 e5                	mov    %esp,%ebp
80104bae:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    p = allocproc();
80104bb1:	e8 f3 fe ff ff       	call   80104aa9 <allocproc>
80104bb6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  //NEW
    p->memoryPagesCounter = 0;
80104bb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bbc:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104bc3:	00 00 00 
    p->swapedPagesCounter = 0;
80104bc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bc9:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104bd0:	00 00 00 
    p->pageFaultCounter = 0;
80104bd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bd6:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104bdd:	00 00 00 
    p->swappedOutCounter = 0;
80104be0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104be3:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80104bea:	00 00 00 
    p->numOfPages = 0;
80104bed:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bf0:	c7 80 e8 02 00 00 00 	movl   $0x0,0x2e8(%eax)
80104bf7:	00 00 00 
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104bfa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104c01:	e9 92 00 00 00       	jmp    80104c98 <userinit+0xed>
   	  p->pagesMetaData[i].count = 0;
80104c06:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c0c:	89 d0                	mov    %edx,%eax
80104c0e:	c1 e0 02             	shl    $0x2,%eax
80104c11:	01 d0                	add    %edx,%eax
80104c13:	c1 e0 02             	shl    $0x2,%eax
80104c16:	01 c8                	add    %ecx,%eax
80104c18:	05 9c 00 00 00       	add    $0x9c,%eax
80104c1d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].va = (char *) -1;
80104c23:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c26:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c29:	89 d0                	mov    %edx,%eax
80104c2b:	c1 e0 02             	shl    $0x2,%eax
80104c2e:	01 d0                	add    %edx,%eax
80104c30:	c1 e0 02             	shl    $0x2,%eax
80104c33:	01 c8                	add    %ecx,%eax
80104c35:	05 90 00 00 00       	add    $0x90,%eax
80104c3a:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].isPhysical = 0;
80104c40:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c43:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c46:	89 d0                	mov    %edx,%eax
80104c48:	c1 e0 02             	shl    $0x2,%eax
80104c4b:	01 d0                	add    %edx,%eax
80104c4d:	c1 e0 02             	shl    $0x2,%eax
80104c50:	01 c8                	add    %ecx,%eax
80104c52:	05 94 00 00 00       	add    $0x94,%eax
80104c57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      p->pagesMetaData[i].fileOffset = -1;
80104c5d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c60:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c63:	89 d0                	mov    %edx,%eax
80104c65:	c1 e0 02             	shl    $0x2,%eax
80104c68:	01 d0                	add    %edx,%eax
80104c6a:	c1 e0 02             	shl    $0x2,%eax
80104c6d:	01 c8                	add    %ecx,%eax
80104c6f:	05 98 00 00 00       	add    $0x98,%eax
80104c74:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
80104c7a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80104c7d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c80:	89 d0                	mov    %edx,%eax
80104c82:	c1 e0 02             	shl    $0x2,%eax
80104c85:	01 d0                	add    %edx,%eax
80104c87:	c1 e0 02             	shl    $0x2,%eax
80104c8a:	01 c8                	add    %ecx,%eax
80104c8c:	05 a0 00 00 00       	add    $0xa0,%eax
80104c91:	c6 00 80             	movb   $0x80,(%eax)
    p->pageFaultCounter = 0;
    p->swappedOutCounter = 0;
    p->numOfPages = 0;
    int i;
  //initialize pagesMetaData
    for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80104c94:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104c98:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80104c9c:	0f 8e 64 ff ff ff    	jle    80104c06 <userinit+0x5b>
      p->pagesMetaData[i].isPhysical = 0;
      p->pagesMetaData[i].fileOffset = -1;
      p->pagesMetaData[i].lru = 0x80; //to get the first bit 1 and then zeros = 10000000
    }
  //END NEW
    initproc = p;
80104ca2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ca5:	a3 4c d6 10 80       	mov    %eax,0x8010d64c
    if((p->pgdir = setupkvm()) == 0)
80104caa:	e8 08 39 00 00       	call   801085b7 <setupkvm>
80104caf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cb2:	89 42 04             	mov    %eax,0x4(%edx)
80104cb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cb8:	8b 40 04             	mov    0x4(%eax),%eax
80104cbb:	85 c0                	test   %eax,%eax
80104cbd:	75 0c                	jne    80104ccb <userinit+0x120>
      panic("userinit: out of memory?");
80104cbf:	c7 04 24 48 9f 10 80 	movl   $0x80109f48,(%esp)
80104cc6:	e8 6f b8 ff ff       	call   8010053a <panic>
    inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104ccb:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104cd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cd3:	8b 40 04             	mov    0x4(%eax),%eax
80104cd6:	89 54 24 08          	mov    %edx,0x8(%esp)
80104cda:	c7 44 24 04 e0 d4 10 	movl   $0x8010d4e0,0x4(%esp)
80104ce1:	80 
80104ce2:	89 04 24             	mov    %eax,(%esp)
80104ce5:	e8 25 3b 00 00       	call   8010880f <inituvm>
    p->sz = PGSIZE;
80104cea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ced:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
    memset(p->tf, 0, sizeof(*p->tf));
80104cf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf6:	8b 40 18             	mov    0x18(%eax),%eax
80104cf9:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104d00:	00 
80104d01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d08:	00 
80104d09:	89 04 24             	mov    %eax,(%esp)
80104d0c:	e8 f8 0c 00 00       	call   80105a09 <memset>
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d14:	8b 40 18             	mov    0x18(%eax),%eax
80104d17:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104d1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d20:	8b 40 18             	mov    0x18(%eax),%eax
80104d23:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
    p->tf->es = p->tf->ds;
80104d29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d2c:	8b 40 18             	mov    0x18(%eax),%eax
80104d2f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d32:	8b 52 18             	mov    0x18(%edx),%edx
80104d35:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d39:	66 89 50 28          	mov    %dx,0x28(%eax)
    p->tf->ss = p->tf->ds;
80104d3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d40:	8b 40 18             	mov    0x18(%eax),%eax
80104d43:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104d46:	8b 52 18             	mov    0x18(%edx),%edx
80104d49:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d4d:	66 89 50 48          	mov    %dx,0x48(%eax)
    p->tf->eflags = FL_IF;
80104d51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d54:	8b 40 18             	mov    0x18(%eax),%eax
80104d57:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
    p->tf->esp = PGSIZE;
80104d5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d61:	8b 40 18             	mov    0x18(%eax),%eax
80104d64:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d6e:	8b 40 18             	mov    0x18(%eax),%eax
80104d71:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d7b:	83 c0 6c             	add    $0x6c,%eax
80104d7e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d85:	00 
80104d86:	c7 44 24 04 61 9f 10 	movl   $0x80109f61,0x4(%esp)
80104d8d:	80 
80104d8e:	89 04 24             	mov    %eax,(%esp)
80104d91:	e8 93 0e 00 00       	call   80105c29 <safestrcpy>
  p->cwd = namei("/");
80104d96:	c7 04 24 6a 9f 10 80 	movl   $0x80109f6a,(%esp)
80104d9d:	e8 c8 d7 ff ff       	call   8010256a <namei>
80104da2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104da5:	89 42 68             	mov    %eax,0x68(%edx)
  p->state = RUNNABLE;
80104da8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dab:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  numOfInitializedPages = countPages();
80104db2:	e8 e2 e4 ff ff       	call   80103299 <countPages>
80104db7:	a3 60 49 11 80       	mov    %eax,0x80114960
  cprintf("num of initialized pages: %d\n",numOfInitializedPages);
80104dbc:	a1 60 49 11 80       	mov    0x80114960,%eax
80104dc1:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dc5:	c7 04 24 6c 9f 10 80 	movl   $0x80109f6c,(%esp)
80104dcc:	e8 cf b5 ff ff       	call   801003a0 <cprintf>
  afterInit = 1;
80104dd1:	c7 05 48 d6 10 80 01 	movl   $0x1,0x8010d648
80104dd8:	00 00 00 
}
80104ddb:	c9                   	leave  
80104ddc:	c3                   	ret    

80104ddd <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104ddd:	55                   	push   %ebp
80104dde:	89 e5                	mov    %esp,%ebp
80104de0:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  sz = proc->sz;
80104de3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104de9:	8b 00                	mov    (%eax),%eax
80104deb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104dee:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104df2:	7e 3f                	jle    80104e33 <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104df4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dfb:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104dfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e01:	01 c1                	add    %eax,%ecx
80104e03:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e09:	8b 40 04             	mov    0x4(%eax),%eax
80104e0c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e10:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e14:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e17:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e1b:	89 04 24             	mov    %eax,(%esp)
80104e1e:	e8 62 3b 00 00       	call   80108985 <allocuvm>
80104e23:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e2a:	75 4c                	jne    80104e78 <growproc+0x9b>
      return -1;
80104e2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e31:	eb 63                	jmp    80104e96 <growproc+0xb9>
  } else if(n < 0){
80104e33:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e37:	79 3f                	jns    80104e78 <growproc+0x9b>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n,proc)) == 0)
80104e39:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e40:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e46:	01 c1                	add    %eax,%ecx
80104e48:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4e:	8b 40 04             	mov    0x4(%eax),%eax
80104e51:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104e55:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104e59:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e5c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e60:	89 04 24             	mov    %eax,(%esp)
80104e63:	e8 68 3d 00 00       	call   80108bd0 <deallocuvm>
80104e68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e6f:	75 07                	jne    80104e78 <growproc+0x9b>
      return -1;
80104e71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e76:	eb 1e                	jmp    80104e96 <growproc+0xb9>
  }
  proc->sz = sz;
80104e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e81:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e89:	89 04 24             	mov    %eax,(%esp)
80104e8c:	e8 17 38 00 00       	call   801086a8 <switchuvm>
  return 0;
80104e91:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e96:	c9                   	leave  
80104e97:	c3                   	ret    

80104e98 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e98:	55                   	push   %ebp
80104e99:	89 e5                	mov    %esp,%ebp
80104e9b:	57                   	push   %edi
80104e9c:	56                   	push   %esi
80104e9d:	53                   	push   %ebx
80104e9e:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104ea1:	e8 03 fc ff ff       	call   80104aa9 <allocproc>
80104ea6:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104ea9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104ead:	75 0a                	jne    80104eb9 <fork+0x21>
    return -1;
80104eaf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb4:	e9 93 01 00 00       	jmp    8010504c <fork+0x1b4>
  // Copy process state from p.
  
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz,np)) == 0){
80104eb9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ebf:	8b 10                	mov    (%eax),%edx
80104ec1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ec7:	8b 40 04             	mov    0x4(%eax),%eax
80104eca:	8b 4d e0             	mov    -0x20(%ebp),%ecx
80104ecd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80104ed1:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ed5:	89 04 24             	mov    %eax,(%esp)
80104ed8:	e8 e1 3f 00 00       	call   80108ebe <copyuvm>
80104edd:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ee0:	89 42 04             	mov    %eax,0x4(%edx)
80104ee3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ee6:	8b 40 04             	mov    0x4(%eax),%eax
80104ee9:	85 c0                	test   %eax,%eax
80104eeb:	75 2c                	jne    80104f19 <fork+0x81>
    kfree(np->kstack);
80104eed:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef0:	8b 40 08             	mov    0x8(%eax),%eax
80104ef3:	89 04 24             	mov    %eax,(%esp)
80104ef6:	e8 8f e2 ff ff       	call   8010318a <kfree>
    np->kstack = 0;
80104efb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104efe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104f05:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f08:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104f0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f14:	e9 33 01 00 00       	jmp    8010504c <fork+0x1b4>
  }
  np->sz = proc->sz;
80104f19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f1f:	8b 10                	mov    (%eax),%edx
80104f21:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f24:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f26:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f30:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f33:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f36:	8b 50 18             	mov    0x18(%eax),%edx
80104f39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f3f:	8b 40 18             	mov    0x18(%eax),%eax
80104f42:	89 c3                	mov    %eax,%ebx
80104f44:	b8 13 00 00 00       	mov    $0x13,%eax
80104f49:	89 d7                	mov    %edx,%edi
80104f4b:	89 de                	mov    %ebx,%esi
80104f4d:	89 c1                	mov    %eax,%ecx
80104f4f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f51:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f54:	8b 40 18             	mov    0x18(%eax),%eax
80104f57:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f5e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f65:	eb 3d                	jmp    80104fa4 <fork+0x10c>
    if(proc->ofile[i])
80104f67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f6d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f70:	83 c2 08             	add    $0x8,%edx
80104f73:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f77:	85 c0                	test   %eax,%eax
80104f79:	74 25                	je     80104fa0 <fork+0x108>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f7b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f81:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f84:	83 c2 08             	add    $0x8,%edx
80104f87:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f8b:	89 04 24             	mov    %eax,(%esp)
80104f8e:	e8 f3 c0 ff ff       	call   80101086 <filedup>
80104f93:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f96:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f99:	83 c1 08             	add    $0x8,%ecx
80104f9c:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104fa0:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104fa4:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104fa8:	7e bd                	jle    80104f67 <fork+0xcf>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
    np->cwd = idup(proc->cwd);
80104faa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fb0:	8b 40 68             	mov    0x68(%eax),%eax
80104fb3:	89 04 24             	mov    %eax,(%esp)
80104fb6:	e8 cc c9 ff ff       	call   80101987 <idup>
80104fbb:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104fbe:	89 42 68             	mov    %eax,0x68(%edx)

    safestrcpy(np->name, proc->name, sizeof(proc->name));
80104fc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fc7:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fca:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fcd:	83 c0 6c             	add    $0x6c,%eax
80104fd0:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fd7:	00 
80104fd8:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fdc:	89 04 24             	mov    %eax,(%esp)
80104fdf:	e8 45 0c 00 00       	call   80105c29 <safestrcpy>

    pid = np->pid;
80104fe4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fe7:	8b 40 10             	mov    0x10(%eax),%eax
80104fea:	89 45 dc             	mov    %eax,-0x24(%ebp)

  //NEW
  //copy pagesMetaData
    np->pageFaultCounter = 0;
80104fed:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ff0:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104ff7:	00 00 00 
    np->swappedOutCounter = 0;
80104ffa:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ffd:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80105004:	00 00 00 
    createSwapFile(np);
80105007:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010500a:	89 04 24             	mov    %eax,(%esp)
8010500d:	e8 69 d8 ff ff       	call   8010287b <createSwapFile>
    copySwapFile(proc,np);
80105012:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105018:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010501b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010501f:	89 04 24             	mov    %eax,(%esp)
80105022:	e8 89 d9 ff ff       	call   801029b0 <copySwapFile>
  //END NEW
  // lock to force the compiler to emit the np->state write last.
    acquire(&ptable.lock);
80105027:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010502e:	e8 82 07 00 00       	call   801057b5 <acquire>
    np->state = RUNNABLE;
80105033:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105036:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    release(&ptable.lock);
8010503d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105044:	e8 ce 07 00 00       	call   80105817 <release>

    return pid;
80105049:	8b 45 dc             	mov    -0x24(%ebp),%eax
  }
8010504c:	83 c4 2c             	add    $0x2c,%esp
8010504f:	5b                   	pop    %ebx
80105050:	5e                   	pop    %esi
80105051:	5f                   	pop    %edi
80105052:	5d                   	pop    %ebp
80105053:	c3                   	ret    

80105054 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
  void
  exit(void)
  {
80105054:	55                   	push   %ebp
80105055:	89 e5                	mov    %esp,%ebp
80105057:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int fd;
    if(VERBOSE_PRINT == 1)
      procdump();
8010505a:	e8 86 05 00 00       	call   801055e5 <procdump>
    if(proc == initproc)
8010505f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105066:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
8010506b:	39 c2                	cmp    %eax,%edx
8010506d:	75 0c                	jne    8010507b <exit+0x27>
      panic("init exiting");
8010506f:	c7 04 24 8a 9f 10 80 	movl   $0x80109f8a,(%esp)
80105076:	e8 bf b4 ff ff       	call   8010053a <panic>

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
8010507b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105082:	eb 44                	jmp    801050c8 <exit+0x74>
      if(proc->ofile[fd]){
80105084:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010508a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010508d:	83 c2 08             	add    $0x8,%edx
80105090:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105094:	85 c0                	test   %eax,%eax
80105096:	74 2c                	je     801050c4 <exit+0x70>
        fileclose(proc->ofile[fd]);
80105098:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010509e:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050a1:	83 c2 08             	add    $0x8,%edx
801050a4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050a8:	89 04 24             	mov    %eax,(%esp)
801050ab:	e8 1e c0 ff ff       	call   801010ce <fileclose>
        proc->ofile[fd] = 0;
801050b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050b6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801050b9:	83 c2 08             	add    $0x8,%edx
801050bc:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801050c3:	00 
      procdump();
    if(proc == initproc)
      panic("init exiting");

  // Close all open files.
    for(fd = 0; fd < NOFILE; fd++){
801050c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801050c8:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801050cc:	7e b6                	jle    80105084 <exit+0x30>
        fileclose(proc->ofile[fd]);
        proc->ofile[fd] = 0;
      }
    }

    begin_op();
801050ce:	e8 e3 ea ff ff       	call   80103bb6 <begin_op>
    iput(proc->cwd);
801050d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050d9:	8b 40 68             	mov    0x68(%eax),%eax
801050dc:	89 04 24             	mov    %eax,(%esp)
801050df:	e8 8e ca ff ff       	call   80101b72 <iput>
    end_op();
801050e4:	e8 51 eb ff ff       	call   80103c3a <end_op>
    proc->cwd = 0;
801050e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050ef:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
    removeSwapFile(proc);
801050f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050fc:	89 04 24             	mov    %eax,(%esp)
801050ff:	e8 6b d5 ff ff       	call   8010266f <removeSwapFile>
    acquire(&ptable.lock);
80105104:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010510b:	e8 a5 06 00 00       	call   801057b5 <acquire>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);
80105110:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105116:	8b 40 14             	mov    0x14(%eax),%eax
80105119:	89 04 24             	mov    %eax,(%esp)
8010511c:	e8 dd 03 00 00       	call   801054fe <wakeup1>

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105121:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105128:	eb 3b                	jmp    80105165 <exit+0x111>
      if(p->parent == proc){
8010512a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010512d:	8b 50 14             	mov    0x14(%eax),%edx
80105130:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105136:	39 c2                	cmp    %eax,%edx
80105138:	75 24                	jne    8010515e <exit+0x10a>
        p->parent = initproc;
8010513a:	8b 15 4c d6 10 80    	mov    0x8010d64c,%edx
80105140:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105143:	89 50 14             	mov    %edx,0x14(%eax)
        if(p->state == ZOMBIE)
80105146:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105149:	8b 40 0c             	mov    0xc(%eax),%eax
8010514c:	83 f8 05             	cmp    $0x5,%eax
8010514f:	75 0d                	jne    8010515e <exit+0x10a>
          wakeup1(initproc);
80105151:	a1 4c d6 10 80       	mov    0x8010d64c,%eax
80105156:	89 04 24             	mov    %eax,(%esp)
80105159:	e8 a0 03 00 00       	call   801054fe <wakeup1>

  // Parent might be sleeping in wait().
    wakeup1(proc->parent);

  // Pass abandoned children to init.
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010515e:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105165:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
8010516c:	72 bc                	jb     8010512a <exit+0xd6>
          wakeup1(initproc);
      }
    }

  // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
8010516e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105174:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
    sched();
8010517b:	e8 c0 01 00 00       	call   80105340 <sched>
    panic("zombie exit");
80105180:	c7 04 24 97 9f 10 80 	movl   $0x80109f97,(%esp)
80105187:	e8 ae b3 ff ff       	call   8010053a <panic>

8010518c <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
  int
  wait(void)
  {
8010518c:	55                   	push   %ebp
8010518d:	89 e5                	mov    %esp,%ebp
8010518f:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
80105192:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105199:	e8 17 06 00 00       	call   801057b5 <acquire>
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
8010519e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051a5:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801051ac:	e9 a4 00 00 00       	jmp    80105255 <wait+0xc9>
        if(p->parent != proc)
801051b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051b4:	8b 50 14             	mov    0x14(%eax),%edx
801051b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051bd:	39 c2                	cmp    %eax,%edx
801051bf:	74 05                	je     801051c6 <wait+0x3a>
          continue;
801051c1:	e9 88 00 00 00       	jmp    8010524e <wait+0xc2>
        havekids = 1;
801051c6:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
        if(p->state == ZOMBIE){
801051cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d0:	8b 40 0c             	mov    0xc(%eax),%eax
801051d3:	83 f8 05             	cmp    $0x5,%eax
801051d6:	75 76                	jne    8010524e <wait+0xc2>
        // Found one.
          pid = p->pid;
801051d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051db:	8b 40 10             	mov    0x10(%eax),%eax
801051de:	89 45 ec             	mov    %eax,-0x14(%ebp)
          kfree(p->kstack);
801051e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051e4:	8b 40 08             	mov    0x8(%eax),%eax
801051e7:	89 04 24             	mov    %eax,(%esp)
801051ea:	e8 9b df ff ff       	call   8010318a <kfree>
          p->kstack = 0;
801051ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
          freevm(p->pgdir,p);
801051f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051fc:	8b 40 04             	mov    0x4(%eax),%eax
801051ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105202:	89 54 24 04          	mov    %edx,0x4(%esp)
80105206:	89 04 24             	mov    %eax,(%esp)
80105209:	e8 c6 3b 00 00       	call   80108dd4 <freevm>
          p->state = UNUSED;
8010520e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105211:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
          p->pid = 0;
80105218:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010521b:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
          p->parent = 0;
80105222:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105225:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
          p->name[0] = 0;
8010522c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010522f:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
          p->killed = 0;
80105233:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105236:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
          release(&ptable.lock);
8010523d:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105244:	e8 ce 05 00 00       	call   80105817 <release>
          return pid;
80105249:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010524c:	eb 55                	jmp    801052a3 <wait+0x117>

    acquire(&ptable.lock);
    for(;;){
    // Scan through table looking for zombie children.
      havekids = 0;
      for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010524e:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105255:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
8010525c:	0f 82 4f ff ff ff    	jb     801051b1 <wait+0x25>
          return pid;
        }
      }

    // No point waiting if we don't have any children.
      if(!havekids || proc->killed){
80105262:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105266:	74 0d                	je     80105275 <wait+0xe9>
80105268:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526e:	8b 40 24             	mov    0x24(%eax),%eax
80105271:	85 c0                	test   %eax,%eax
80105273:	74 13                	je     80105288 <wait+0xfc>
        release(&ptable.lock);
80105275:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010527c:	e8 96 05 00 00       	call   80105817 <release>
        return -1;
80105281:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105286:	eb 1b                	jmp    801052a3 <wait+0x117>
      }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105288:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010528e:	c7 44 24 04 80 49 11 	movl   $0x80114980,0x4(%esp)
80105295:	80 
80105296:	89 04 24             	mov    %eax,(%esp)
80105299:	e8 c5 01 00 00       	call   80105463 <sleep>
  }
8010529e:	e9 fb fe ff ff       	jmp    8010519e <wait+0x12>
}
801052a3:	c9                   	leave  
801052a4:	c3                   	ret    

801052a5 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801052a5:	55                   	push   %ebp
801052a6:	89 e5                	mov    %esp,%ebp
801052a8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801052ab:	e8 d7 f7 ff ff       	call   80104a87 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801052b0:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801052b7:	e8 f9 04 00 00       	call   801057b5 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052bc:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
801052c3:	eb 61                	jmp    80105326 <scheduler+0x81>
      if(p->state != RUNNABLE)
801052c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c8:	8b 40 0c             	mov    0xc(%eax),%eax
801052cb:	83 f8 03             	cmp    $0x3,%eax
801052ce:	74 02                	je     801052d2 <scheduler+0x2d>
        continue;
801052d0:	eb 4d                	jmp    8010531f <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d5:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052de:	89 04 24             	mov    %eax,(%esp)
801052e1:	e8 c2 33 00 00       	call   801086a8 <switchuvm>
      p->state = RUNNING;
801052e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e9:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052f6:	8b 40 1c             	mov    0x1c(%eax),%eax
801052f9:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105300:	83 c2 04             	add    $0x4,%edx
80105303:	89 44 24 04          	mov    %eax,0x4(%esp)
80105307:	89 14 24             	mov    %edx,(%esp)
8010530a:	e8 8b 09 00 00       	call   80105c9a <swtch>
      switchkvm();
8010530f:	e8 77 33 00 00       	call   8010868b <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105314:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010531b:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010531f:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
80105326:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
8010532d:	72 96                	jb     801052c5 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010532f:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105336:	e8 dc 04 00 00       	call   80105817 <release>

  }
8010533b:	e9 6b ff ff ff       	jmp    801052ab <scheduler+0x6>

80105340 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105340:	55                   	push   %ebp
80105341:	89 e5                	mov    %esp,%ebp
80105343:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105346:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010534d:	e8 8d 05 00 00       	call   801058df <holding>
80105352:	85 c0                	test   %eax,%eax
80105354:	75 0c                	jne    80105362 <sched+0x22>
    panic("sched ptable.lock");
80105356:	c7 04 24 a3 9f 10 80 	movl   $0x80109fa3,(%esp)
8010535d:	e8 d8 b1 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105362:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105368:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010536e:	83 f8 01             	cmp    $0x1,%eax
80105371:	74 0c                	je     8010537f <sched+0x3f>
    panic("sched locks");
80105373:	c7 04 24 b5 9f 10 80 	movl   $0x80109fb5,(%esp)
8010537a:	e8 bb b1 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
8010537f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105385:	8b 40 0c             	mov    0xc(%eax),%eax
80105388:	83 f8 04             	cmp    $0x4,%eax
8010538b:	75 0c                	jne    80105399 <sched+0x59>
    panic("sched running");
8010538d:	c7 04 24 c1 9f 10 80 	movl   $0x80109fc1,(%esp)
80105394:	e8 a1 b1 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80105399:	e8 d9 f6 ff ff       	call   80104a77 <readeflags>
8010539e:	25 00 02 00 00       	and    $0x200,%eax
801053a3:	85 c0                	test   %eax,%eax
801053a5:	74 0c                	je     801053b3 <sched+0x73>
    panic("sched interruptible");
801053a7:	c7 04 24 cf 9f 10 80 	movl   $0x80109fcf,(%esp)
801053ae:	e8 87 b1 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801053b3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053b9:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053c2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053c8:	8b 40 04             	mov    0x4(%eax),%eax
801053cb:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053d2:	83 c2 1c             	add    $0x1c,%edx
801053d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053d9:	89 14 24             	mov    %edx,(%esp)
801053dc:	e8 b9 08 00 00       	call   80105c9a <swtch>
  cpu->intena = intena;
801053e1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053ea:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053f0:	c9                   	leave  
801053f1:	c3                   	ret    

801053f2 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053f2:	55                   	push   %ebp
801053f3:	89 e5                	mov    %esp,%ebp
801053f5:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801053f8:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801053ff:	e8 b1 03 00 00       	call   801057b5 <acquire>
  proc->state = RUNNABLE;
80105404:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010540a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105411:	e8 2a ff ff ff       	call   80105340 <sched>
  release(&ptable.lock);
80105416:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010541d:	e8 f5 03 00 00       	call   80105817 <release>
}
80105422:	c9                   	leave  
80105423:	c3                   	ret    

80105424 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105424:	55                   	push   %ebp
80105425:	89 e5                	mov    %esp,%ebp
80105427:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010542a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105431:	e8 e1 03 00 00       	call   80105817 <release>

  if (first) {
80105436:	a1 08 d0 10 80       	mov    0x8010d008,%eax
8010543b:	85 c0                	test   %eax,%eax
8010543d:	74 22                	je     80105461 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010543f:	c7 05 08 d0 10 80 00 	movl   $0x0,0x8010d008
80105446:	00 00 00 
    iinit(ROOTDEV);
80105449:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105450:	e8 3c c2 ff ff       	call   80101691 <iinit>
    initlog(ROOTDEV);
80105455:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010545c:	e8 51 e5 ff ff       	call   801039b2 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105461:	c9                   	leave  
80105462:	c3                   	ret    

80105463 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105463:	55                   	push   %ebp
80105464:	89 e5                	mov    %esp,%ebp
80105466:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105469:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010546f:	85 c0                	test   %eax,%eax
80105471:	75 0c                	jne    8010547f <sleep+0x1c>
    panic("sleep");
80105473:	c7 04 24 e3 9f 10 80 	movl   $0x80109fe3,(%esp)
8010547a:	e8 bb b0 ff ff       	call   8010053a <panic>

  if(lk == 0)
8010547f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105483:	75 0c                	jne    80105491 <sleep+0x2e>
    panic("sleep without lk");
80105485:	c7 04 24 e9 9f 10 80 	movl   $0x80109fe9,(%esp)
8010548c:	e8 a9 b0 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105491:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
80105498:	74 17                	je     801054b1 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010549a:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054a1:	e8 0f 03 00 00       	call   801057b5 <acquire>
    release(lk);
801054a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801054a9:	89 04 24             	mov    %eax,(%esp)
801054ac:	e8 66 03 00 00       	call   80105817 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801054b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b7:	8b 55 08             	mov    0x8(%ebp),%edx
801054ba:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c3:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054ca:	e8 71 fe ff ff       	call   80105340 <sched>

  // Tidy up.
  proc->chan = 0;
801054cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054d5:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054dc:	81 7d 0c 80 49 11 80 	cmpl   $0x80114980,0xc(%ebp)
801054e3:	74 17                	je     801054fc <sleep+0x99>
    release(&ptable.lock);
801054e5:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801054ec:	e8 26 03 00 00       	call   80105817 <release>
    acquire(lk);
801054f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801054f4:	89 04 24             	mov    %eax,(%esp)
801054f7:	e8 b9 02 00 00       	call   801057b5 <acquire>
  }
}
801054fc:	c9                   	leave  
801054fd:	c3                   	ret    

801054fe <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801054fe:	55                   	push   %ebp
801054ff:	89 e5                	mov    %esp,%ebp
80105501:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105504:	c7 45 fc b4 49 11 80 	movl   $0x801149b4,-0x4(%ebp)
8010550b:	eb 27                	jmp    80105534 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
8010550d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105510:	8b 40 0c             	mov    0xc(%eax),%eax
80105513:	83 f8 02             	cmp    $0x2,%eax
80105516:	75 15                	jne    8010552d <wakeup1+0x2f>
80105518:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010551b:	8b 40 20             	mov    0x20(%eax),%eax
8010551e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105521:	75 0a                	jne    8010552d <wakeup1+0x2f>
      p->state = RUNNABLE;
80105523:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105526:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010552d:	81 45 fc ec 02 00 00 	addl   $0x2ec,-0x4(%ebp)
80105534:	81 7d fc b4 04 12 80 	cmpl   $0x801204b4,-0x4(%ebp)
8010553b:	72 d0                	jb     8010550d <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
  }
8010553d:	c9                   	leave  
8010553e:	c3                   	ret    

8010553f <wakeup>:

// Wake up all processes sleeping on chan.
  void
  wakeup(void *chan)
  {
8010553f:	55                   	push   %ebp
80105540:	89 e5                	mov    %esp,%ebp
80105542:	83 ec 18             	sub    $0x18,%esp
    acquire(&ptable.lock);
80105545:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
8010554c:	e8 64 02 00 00       	call   801057b5 <acquire>
    wakeup1(chan);
80105551:	8b 45 08             	mov    0x8(%ebp),%eax
80105554:	89 04 24             	mov    %eax,(%esp)
80105557:	e8 a2 ff ff ff       	call   801054fe <wakeup1>
    release(&ptable.lock);
8010555c:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105563:	e8 af 02 00 00       	call   80105817 <release>
  }
80105568:	c9                   	leave  
80105569:	c3                   	ret    

8010556a <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
  int
  kill(int pid)
  {
8010556a:	55                   	push   %ebp
8010556b:	89 e5                	mov    %esp,%ebp
8010556d:	83 ec 28             	sub    $0x28,%esp
    struct proc *p;

    acquire(&ptable.lock);
80105570:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
80105577:	e8 39 02 00 00       	call   801057b5 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010557c:	c7 45 f4 b4 49 11 80 	movl   $0x801149b4,-0xc(%ebp)
80105583:	eb 44                	jmp    801055c9 <kill+0x5f>
      if(p->pid == pid){
80105585:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105588:	8b 40 10             	mov    0x10(%eax),%eax
8010558b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010558e:	75 32                	jne    801055c2 <kill+0x58>
        p->killed = 1;
80105590:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105593:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
        if(p->state == SLEEPING)
8010559a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559d:	8b 40 0c             	mov    0xc(%eax),%eax
801055a0:	83 f8 02             	cmp    $0x2,%eax
801055a3:	75 0a                	jne    801055af <kill+0x45>
          p->state = RUNNABLE;
801055a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        release(&ptable.lock);
801055af:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055b6:	e8 5c 02 00 00       	call   80105817 <release>
        return 0;
801055bb:	b8 00 00 00 00       	mov    $0x0,%eax
801055c0:	eb 21                	jmp    801055e3 <kill+0x79>
  kill(int pid)
  {
    struct proc *p;

    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055c2:	81 45 f4 ec 02 00 00 	addl   $0x2ec,-0xc(%ebp)
801055c9:	81 7d f4 b4 04 12 80 	cmpl   $0x801204b4,-0xc(%ebp)
801055d0:	72 b3                	jb     80105585 <kill+0x1b>
          p->state = RUNNABLE;
        release(&ptable.lock);
        return 0;
      }
    }
    release(&ptable.lock);
801055d2:	c7 04 24 80 49 11 80 	movl   $0x80114980,(%esp)
801055d9:	e8 39 02 00 00       	call   80105817 <release>
    return -1;
801055de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
801055e3:	c9                   	leave  
801055e4:	c3                   	ret    

801055e5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
  void
  procdump(void)
  {
801055e5:	55                   	push   %ebp
801055e6:	89 e5                	mov    %esp,%ebp
801055e8:	57                   	push   %edi
801055e9:	56                   	push   %esi
801055ea:	53                   	push   %ebx
801055eb:	83 ec 6c             	sub    $0x6c,%esp
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055ee:	c7 45 e0 b4 49 11 80 	movl   $0x801149b4,-0x20(%ebp)
801055f5:	e9 24 01 00 00       	jmp    8010571e <procdump+0x139>
      if(p->state == UNUSED)
801055fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055fd:	8b 40 0c             	mov    0xc(%eax),%eax
80105600:	85 c0                	test   %eax,%eax
80105602:	75 05                	jne    80105609 <procdump+0x24>
        continue;
80105604:	e9 0e 01 00 00       	jmp    80105717 <procdump+0x132>
      if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105609:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010560c:	8b 40 0c             	mov    0xc(%eax),%eax
8010560f:	83 f8 05             	cmp    $0x5,%eax
80105612:	77 23                	ja     80105637 <procdump+0x52>
80105614:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105617:	8b 40 0c             	mov    0xc(%eax),%eax
8010561a:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105621:	85 c0                	test   %eax,%eax
80105623:	74 12                	je     80105637 <procdump+0x52>
        state = states[p->state];
80105625:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105628:	8b 40 0c             	mov    0xc(%eax),%eax
8010562b:	8b 04 85 0c d0 10 80 	mov    -0x7fef2ff4(,%eax,4),%eax
80105632:	89 45 dc             	mov    %eax,-0x24(%ebp)
80105635:	eb 07                	jmp    8010563e <procdump+0x59>
      else
        state = "???";
80105637:	c7 45 dc fa 9f 10 80 	movl   $0x80109ffa,-0x24(%ebp)
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
8010563e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105641:	8b 98 8c 00 00 00    	mov    0x8c(%eax),%ebx
80105647:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010564a:	8b 88 88 00 00 00    	mov    0x88(%eax),%ecx
80105650:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105653:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
80105659:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010565c:	8b b0 80 00 00 00    	mov    0x80(%eax),%esi
80105662:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105665:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
8010566b:	01 c6                	add    %eax,%esi
8010566d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105670:	8b 40 10             	mov    0x10(%eax),%eax
80105673:	89 5c 24 18          	mov    %ebx,0x18(%esp)
80105677:	89 4c 24 14          	mov    %ecx,0x14(%esp)
8010567b:	89 54 24 10          	mov    %edx,0x10(%esp)
8010567f:	89 74 24 0c          	mov    %esi,0xc(%esp)
80105683:	8b 55 dc             	mov    -0x24(%ebp),%edx
80105686:	89 54 24 08          	mov    %edx,0x8(%esp)
8010568a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010568e:	c7 04 24 fe 9f 10 80 	movl   $0x80109ffe,(%esp)
80105695:	e8 06 ad ff ff       	call   801003a0 <cprintf>
      cprintf("%s",p->name);
8010569a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010569d:	83 c0 6c             	add    $0x6c,%eax
801056a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801056a4:	c7 04 24 11 a0 10 80 	movl   $0x8010a011,(%esp)
801056ab:	e8 f0 ac ff ff       	call   801003a0 <cprintf>
      if(p->state == SLEEPING){
801056b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056b3:	8b 40 0c             	mov    0xc(%eax),%eax
801056b6:	83 f8 02             	cmp    $0x2,%eax
801056b9:	75 50                	jne    8010570b <procdump+0x126>
        getcallerpcs((uint*)p->context->ebp+2, pc);
801056bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056be:	8b 40 1c             	mov    0x1c(%eax),%eax
801056c1:	8b 40 0c             	mov    0xc(%eax),%eax
801056c4:	83 c0 08             	add    $0x8,%eax
801056c7:	8d 55 b4             	lea    -0x4c(%ebp),%edx
801056ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801056ce:	89 04 24             	mov    %eax,(%esp)
801056d1:	e8 90 01 00 00       	call   80105866 <getcallerpcs>
        for(i=0; i<10 && pc[i] != 0; i++)
801056d6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801056dd:	eb 1b                	jmp    801056fa <procdump+0x115>
          cprintf(" %p", pc[i]);
801056df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801056e2:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
801056e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801056ea:	c7 04 24 14 a0 10 80 	movl   $0x8010a014,(%esp)
801056f1:	e8 aa ac ff ff       	call   801003a0 <cprintf>
        state = "???";
      cprintf("%d %s %d %d %d %d ",p->pid, state, p->memoryPagesCounter+p->swapedPagesCounter,p->swapedPagesCounter, p->pageFaultCounter, p->swappedOutCounter);
      cprintf("%s",p->name);
      if(p->state == SLEEPING){
        getcallerpcs((uint*)p->context->ebp+2, pc);
        for(i=0; i<10 && pc[i] != 0; i++)
801056f6:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801056fa:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
801056fe:	7f 0b                	jg     8010570b <procdump+0x126>
80105700:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105703:	8b 44 85 b4          	mov    -0x4c(%ebp,%eax,4),%eax
80105707:	85 c0                	test   %eax,%eax
80105709:	75 d4                	jne    801056df <procdump+0xfa>
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
8010570b:	c7 04 24 18 a0 10 80 	movl   $0x8010a018,(%esp)
80105712:	e8 89 ac ff ff       	call   801003a0 <cprintf>
    int i;
    struct proc *p;
    char *state;
    uint pc[10];

    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105717:	81 45 e0 ec 02 00 00 	addl   $0x2ec,-0x20(%ebp)
8010571e:	81 7d e0 b4 04 12 80 	cmpl   $0x801204b4,-0x20(%ebp)
80105725:	0f 82 cf fe ff ff    	jb     801055fa <procdump+0x15>
        for(i=0; i<10 && pc[i] != 0; i++)
          cprintf(" %p", pc[i]);
      }
      cprintf("\n");
    }
    cprintf("%d free pages in the system\n",countPages()*100/numOfInitializedPages);
8010572b:	e8 69 db ff ff       	call   80103299 <countPages>
80105730:	6b c0 64             	imul   $0x64,%eax,%eax
80105733:	8b 3d 60 49 11 80    	mov    0x80114960,%edi
80105739:	99                   	cltd   
8010573a:	f7 ff                	idiv   %edi
8010573c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105740:	c7 04 24 1a a0 10 80 	movl   $0x8010a01a,(%esp)
80105747:	e8 54 ac ff ff       	call   801003a0 <cprintf>
  }
8010574c:	83 c4 6c             	add    $0x6c,%esp
8010574f:	5b                   	pop    %ebx
80105750:	5e                   	pop    %esi
80105751:	5f                   	pop    %edi
80105752:	5d                   	pop    %ebp
80105753:	c3                   	ret    

80105754 <getPid>:

int
getPid(){
80105754:	55                   	push   %ebp
80105755:	89 e5                	mov    %esp,%ebp
  return afterInit;
80105757:	a1 48 d6 10 80       	mov    0x8010d648,%eax
8010575c:	5d                   	pop    %ebp
8010575d:	c3                   	ret    

8010575e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010575e:	55                   	push   %ebp
8010575f:	89 e5                	mov    %esp,%ebp
80105761:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105764:	9c                   	pushf  
80105765:	58                   	pop    %eax
80105766:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105769:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010576c:	c9                   	leave  
8010576d:	c3                   	ret    

8010576e <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010576e:	55                   	push   %ebp
8010576f:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105771:	fa                   	cli    
}
80105772:	5d                   	pop    %ebp
80105773:	c3                   	ret    

80105774 <sti>:

static inline void
sti(void)
{
80105774:	55                   	push   %ebp
80105775:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105777:	fb                   	sti    
}
80105778:	5d                   	pop    %ebp
80105779:	c3                   	ret    

8010577a <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010577a:	55                   	push   %ebp
8010577b:	89 e5                	mov    %esp,%ebp
8010577d:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105780:	8b 55 08             	mov    0x8(%ebp),%edx
80105783:	8b 45 0c             	mov    0xc(%ebp),%eax
80105786:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105789:	f0 87 02             	lock xchg %eax,(%edx)
8010578c:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010578f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105792:	c9                   	leave  
80105793:	c3                   	ret    

80105794 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105794:	55                   	push   %ebp
80105795:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105797:	8b 45 08             	mov    0x8(%ebp),%eax
8010579a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010579d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
801057a0:	8b 45 08             	mov    0x8(%ebp),%eax
801057a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801057a9:	8b 45 08             	mov    0x8(%ebp),%eax
801057ac:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801057b3:	5d                   	pop    %ebp
801057b4:	c3                   	ret    

801057b5 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801057b5:	55                   	push   %ebp
801057b6:	89 e5                	mov    %esp,%ebp
801057b8:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801057bb:	e8 49 01 00 00       	call   80105909 <pushcli>
  if(holding(lk))
801057c0:	8b 45 08             	mov    0x8(%ebp),%eax
801057c3:	89 04 24             	mov    %eax,(%esp)
801057c6:	e8 14 01 00 00       	call   801058df <holding>
801057cb:	85 c0                	test   %eax,%eax
801057cd:	74 0c                	je     801057db <acquire+0x26>
    panic("acquire");
801057cf:	c7 04 24 61 a0 10 80 	movl   $0x8010a061,(%esp)
801057d6:	e8 5f ad ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801057db:	90                   	nop
801057dc:	8b 45 08             	mov    0x8(%ebp),%eax
801057df:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801057e6:	00 
801057e7:	89 04 24             	mov    %eax,(%esp)
801057ea:	e8 8b ff ff ff       	call   8010577a <xchg>
801057ef:	85 c0                	test   %eax,%eax
801057f1:	75 e9                	jne    801057dc <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801057f3:	8b 45 08             	mov    0x8(%ebp),%eax
801057f6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801057fd:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105800:	8b 45 08             	mov    0x8(%ebp),%eax
80105803:	83 c0 0c             	add    $0xc,%eax
80105806:	89 44 24 04          	mov    %eax,0x4(%esp)
8010580a:	8d 45 08             	lea    0x8(%ebp),%eax
8010580d:	89 04 24             	mov    %eax,(%esp)
80105810:	e8 51 00 00 00       	call   80105866 <getcallerpcs>
}
80105815:	c9                   	leave  
80105816:	c3                   	ret    

80105817 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105817:	55                   	push   %ebp
80105818:	89 e5                	mov    %esp,%ebp
8010581a:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
8010581d:	8b 45 08             	mov    0x8(%ebp),%eax
80105820:	89 04 24             	mov    %eax,(%esp)
80105823:	e8 b7 00 00 00       	call   801058df <holding>
80105828:	85 c0                	test   %eax,%eax
8010582a:	75 0c                	jne    80105838 <release+0x21>
    panic("release");
8010582c:	c7 04 24 69 a0 10 80 	movl   $0x8010a069,(%esp)
80105833:	e8 02 ad ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105838:	8b 45 08             	mov    0x8(%ebp),%eax
8010583b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105842:	8b 45 08             	mov    0x8(%ebp),%eax
80105845:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
8010584c:	8b 45 08             	mov    0x8(%ebp),%eax
8010584f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105856:	00 
80105857:	89 04 24             	mov    %eax,(%esp)
8010585a:	e8 1b ff ff ff       	call   8010577a <xchg>

  popcli();
8010585f:	e8 e9 00 00 00       	call   8010594d <popcli>
}
80105864:	c9                   	leave  
80105865:	c3                   	ret    

80105866 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105866:	55                   	push   %ebp
80105867:	89 e5                	mov    %esp,%ebp
80105869:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
8010586c:	8b 45 08             	mov    0x8(%ebp),%eax
8010586f:	83 e8 08             	sub    $0x8,%eax
80105872:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105875:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010587c:	eb 38                	jmp    801058b6 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010587e:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105882:	74 38                	je     801058bc <getcallerpcs+0x56>
80105884:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010588b:	76 2f                	jbe    801058bc <getcallerpcs+0x56>
8010588d:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105891:	74 29                	je     801058bc <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105893:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105896:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010589d:	8b 45 0c             	mov    0xc(%ebp),%eax
801058a0:	01 c2                	add    %eax,%edx
801058a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058a5:	8b 40 04             	mov    0x4(%eax),%eax
801058a8:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801058aa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058ad:	8b 00                	mov    (%eax),%eax
801058af:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801058b2:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058b6:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058ba:	7e c2                	jle    8010587e <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058bc:	eb 19                	jmp    801058d7 <getcallerpcs+0x71>
    pcs[i] = 0;
801058be:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058c1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801058c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801058cb:	01 d0                	add    %edx,%eax
801058cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801058d3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058d7:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801058db:	7e e1                	jle    801058be <getcallerpcs+0x58>
    pcs[i] = 0;
}
801058dd:	c9                   	leave  
801058de:	c3                   	ret    

801058df <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801058df:	55                   	push   %ebp
801058e0:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801058e2:	8b 45 08             	mov    0x8(%ebp),%eax
801058e5:	8b 00                	mov    (%eax),%eax
801058e7:	85 c0                	test   %eax,%eax
801058e9:	74 17                	je     80105902 <holding+0x23>
801058eb:	8b 45 08             	mov    0x8(%ebp),%eax
801058ee:	8b 50 08             	mov    0x8(%eax),%edx
801058f1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058f7:	39 c2                	cmp    %eax,%edx
801058f9:	75 07                	jne    80105902 <holding+0x23>
801058fb:	b8 01 00 00 00       	mov    $0x1,%eax
80105900:	eb 05                	jmp    80105907 <holding+0x28>
80105902:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105907:	5d                   	pop    %ebp
80105908:	c3                   	ret    

80105909 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105909:	55                   	push   %ebp
8010590a:	89 e5                	mov    %esp,%ebp
8010590c:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010590f:	e8 4a fe ff ff       	call   8010575e <readeflags>
80105914:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105917:	e8 52 fe ff ff       	call   8010576e <cli>
  if(cpu->ncli++ == 0)
8010591c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105923:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105929:	8d 48 01             	lea    0x1(%eax),%ecx
8010592c:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105932:	85 c0                	test   %eax,%eax
80105934:	75 15                	jne    8010594b <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105936:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010593c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010593f:	81 e2 00 02 00 00    	and    $0x200,%edx
80105945:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010594b:	c9                   	leave  
8010594c:	c3                   	ret    

8010594d <popcli>:

void
popcli(void)
{
8010594d:	55                   	push   %ebp
8010594e:	89 e5                	mov    %esp,%ebp
80105950:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105953:	e8 06 fe ff ff       	call   8010575e <readeflags>
80105958:	25 00 02 00 00       	and    $0x200,%eax
8010595d:	85 c0                	test   %eax,%eax
8010595f:	74 0c                	je     8010596d <popcli+0x20>
    panic("popcli - interruptible");
80105961:	c7 04 24 71 a0 10 80 	movl   $0x8010a071,(%esp)
80105968:	e8 cd ab ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
8010596d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105973:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105979:	83 ea 01             	sub    $0x1,%edx
8010597c:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105982:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105988:	85 c0                	test   %eax,%eax
8010598a:	79 0c                	jns    80105998 <popcli+0x4b>
    panic("popcli");
8010598c:	c7 04 24 88 a0 10 80 	movl   $0x8010a088,(%esp)
80105993:	e8 a2 ab ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105998:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010599e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059a4:	85 c0                	test   %eax,%eax
801059a6:	75 15                	jne    801059bd <popcli+0x70>
801059a8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059ae:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801059b4:	85 c0                	test   %eax,%eax
801059b6:	74 05                	je     801059bd <popcli+0x70>
    sti();
801059b8:	e8 b7 fd ff ff       	call   80105774 <sti>
}
801059bd:	c9                   	leave  
801059be:	c3                   	ret    

801059bf <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801059bf:	55                   	push   %ebp
801059c0:	89 e5                	mov    %esp,%ebp
801059c2:	57                   	push   %edi
801059c3:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801059c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059c7:	8b 55 10             	mov    0x10(%ebp),%edx
801059ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801059cd:	89 cb                	mov    %ecx,%ebx
801059cf:	89 df                	mov    %ebx,%edi
801059d1:	89 d1                	mov    %edx,%ecx
801059d3:	fc                   	cld    
801059d4:	f3 aa                	rep stos %al,%es:(%edi)
801059d6:	89 ca                	mov    %ecx,%edx
801059d8:	89 fb                	mov    %edi,%ebx
801059da:	89 5d 08             	mov    %ebx,0x8(%ebp)
801059dd:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801059e0:	5b                   	pop    %ebx
801059e1:	5f                   	pop    %edi
801059e2:	5d                   	pop    %ebp
801059e3:	c3                   	ret    

801059e4 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801059e4:	55                   	push   %ebp
801059e5:	89 e5                	mov    %esp,%ebp
801059e7:	57                   	push   %edi
801059e8:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801059e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059ec:	8b 55 10             	mov    0x10(%ebp),%edx
801059ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801059f2:	89 cb                	mov    %ecx,%ebx
801059f4:	89 df                	mov    %ebx,%edi
801059f6:	89 d1                	mov    %edx,%ecx
801059f8:	fc                   	cld    
801059f9:	f3 ab                	rep stos %eax,%es:(%edi)
801059fb:	89 ca                	mov    %ecx,%edx
801059fd:	89 fb                	mov    %edi,%ebx
801059ff:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105a02:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105a05:	5b                   	pop    %ebx
80105a06:	5f                   	pop    %edi
80105a07:	5d                   	pop    %ebp
80105a08:	c3                   	ret    

80105a09 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105a09:	55                   	push   %ebp
80105a0a:	89 e5                	mov    %esp,%ebp
80105a0c:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105a0f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a12:	83 e0 03             	and    $0x3,%eax
80105a15:	85 c0                	test   %eax,%eax
80105a17:	75 49                	jne    80105a62 <memset+0x59>
80105a19:	8b 45 10             	mov    0x10(%ebp),%eax
80105a1c:	83 e0 03             	and    $0x3,%eax
80105a1f:	85 c0                	test   %eax,%eax
80105a21:	75 3f                	jne    80105a62 <memset+0x59>
    c &= 0xFF;
80105a23:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105a2a:	8b 45 10             	mov    0x10(%ebp),%eax
80105a2d:	c1 e8 02             	shr    $0x2,%eax
80105a30:	89 c2                	mov    %eax,%edx
80105a32:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a35:	c1 e0 18             	shl    $0x18,%eax
80105a38:	89 c1                	mov    %eax,%ecx
80105a3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a3d:	c1 e0 10             	shl    $0x10,%eax
80105a40:	09 c1                	or     %eax,%ecx
80105a42:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a45:	c1 e0 08             	shl    $0x8,%eax
80105a48:	09 c8                	or     %ecx,%eax
80105a4a:	0b 45 0c             	or     0xc(%ebp),%eax
80105a4d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a51:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a55:	8b 45 08             	mov    0x8(%ebp),%eax
80105a58:	89 04 24             	mov    %eax,(%esp)
80105a5b:	e8 84 ff ff ff       	call   801059e4 <stosl>
80105a60:	eb 19                	jmp    80105a7b <memset+0x72>
  } else
    stosb(dst, c, n);
80105a62:	8b 45 10             	mov    0x10(%ebp),%eax
80105a65:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a69:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a70:	8b 45 08             	mov    0x8(%ebp),%eax
80105a73:	89 04 24             	mov    %eax,(%esp)
80105a76:	e8 44 ff ff ff       	call   801059bf <stosb>
  return dst;
80105a7b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a7e:	c9                   	leave  
80105a7f:	c3                   	ret    

80105a80 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a80:	55                   	push   %ebp
80105a81:	89 e5                	mov    %esp,%ebp
80105a83:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a86:	8b 45 08             	mov    0x8(%ebp),%eax
80105a89:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a8f:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a92:	eb 30                	jmp    80105ac4 <memcmp+0x44>
    if(*s1 != *s2)
80105a94:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a97:	0f b6 10             	movzbl (%eax),%edx
80105a9a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a9d:	0f b6 00             	movzbl (%eax),%eax
80105aa0:	38 c2                	cmp    %al,%dl
80105aa2:	74 18                	je     80105abc <memcmp+0x3c>
      return *s1 - *s2;
80105aa4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa7:	0f b6 00             	movzbl (%eax),%eax
80105aaa:	0f b6 d0             	movzbl %al,%edx
80105aad:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ab0:	0f b6 00             	movzbl (%eax),%eax
80105ab3:	0f b6 c0             	movzbl %al,%eax
80105ab6:	29 c2                	sub    %eax,%edx
80105ab8:	89 d0                	mov    %edx,%eax
80105aba:	eb 1a                	jmp    80105ad6 <memcmp+0x56>
    s1++, s2++;
80105abc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ac0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105ac4:	8b 45 10             	mov    0x10(%ebp),%eax
80105ac7:	8d 50 ff             	lea    -0x1(%eax),%edx
80105aca:	89 55 10             	mov    %edx,0x10(%ebp)
80105acd:	85 c0                	test   %eax,%eax
80105acf:	75 c3                	jne    80105a94 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105ad1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ad6:	c9                   	leave  
80105ad7:	c3                   	ret    

80105ad8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105ad8:	55                   	push   %ebp
80105ad9:	89 e5                	mov    %esp,%ebp
80105adb:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105ade:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ae1:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105ae4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae7:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105aea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aed:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105af0:	73 3d                	jae    80105b2f <memmove+0x57>
80105af2:	8b 45 10             	mov    0x10(%ebp),%eax
80105af5:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105af8:	01 d0                	add    %edx,%eax
80105afa:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105afd:	76 30                	jbe    80105b2f <memmove+0x57>
    s += n;
80105aff:	8b 45 10             	mov    0x10(%ebp),%eax
80105b02:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105b05:	8b 45 10             	mov    0x10(%ebp),%eax
80105b08:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105b0b:	eb 13                	jmp    80105b20 <memmove+0x48>
      *--d = *--s;
80105b0d:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105b11:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105b15:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b18:	0f b6 10             	movzbl (%eax),%edx
80105b1b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b1e:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105b20:	8b 45 10             	mov    0x10(%ebp),%eax
80105b23:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b26:	89 55 10             	mov    %edx,0x10(%ebp)
80105b29:	85 c0                	test   %eax,%eax
80105b2b:	75 e0                	jne    80105b0d <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105b2d:	eb 26                	jmp    80105b55 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b2f:	eb 17                	jmp    80105b48 <memmove+0x70>
      *d++ = *s++;
80105b31:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b34:	8d 50 01             	lea    0x1(%eax),%edx
80105b37:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105b3a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b3d:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b40:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105b43:	0f b6 12             	movzbl (%edx),%edx
80105b46:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105b48:	8b 45 10             	mov    0x10(%ebp),%eax
80105b4b:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b4e:	89 55 10             	mov    %edx,0x10(%ebp)
80105b51:	85 c0                	test   %eax,%eax
80105b53:	75 dc                	jne    80105b31 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105b55:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b58:	c9                   	leave  
80105b59:	c3                   	ret    

80105b5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105b5a:	55                   	push   %ebp
80105b5b:	89 e5                	mov    %esp,%ebp
80105b5d:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105b60:	8b 45 10             	mov    0x10(%ebp),%eax
80105b63:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b67:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b6e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b71:	89 04 24             	mov    %eax,(%esp)
80105b74:	e8 5f ff ff ff       	call   80105ad8 <memmove>
}
80105b79:	c9                   	leave  
80105b7a:	c3                   	ret    

80105b7b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b7b:	55                   	push   %ebp
80105b7c:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b7e:	eb 0c                	jmp    80105b8c <strncmp+0x11>
    n--, p++, q++;
80105b80:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b84:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b88:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b8c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b90:	74 1a                	je     80105bac <strncmp+0x31>
80105b92:	8b 45 08             	mov    0x8(%ebp),%eax
80105b95:	0f b6 00             	movzbl (%eax),%eax
80105b98:	84 c0                	test   %al,%al
80105b9a:	74 10                	je     80105bac <strncmp+0x31>
80105b9c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9f:	0f b6 10             	movzbl (%eax),%edx
80105ba2:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ba5:	0f b6 00             	movzbl (%eax),%eax
80105ba8:	38 c2                	cmp    %al,%dl
80105baa:	74 d4                	je     80105b80 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105bac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bb0:	75 07                	jne    80105bb9 <strncmp+0x3e>
    return 0;
80105bb2:	b8 00 00 00 00       	mov    $0x0,%eax
80105bb7:	eb 16                	jmp    80105bcf <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105bb9:	8b 45 08             	mov    0x8(%ebp),%eax
80105bbc:	0f b6 00             	movzbl (%eax),%eax
80105bbf:	0f b6 d0             	movzbl %al,%edx
80105bc2:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bc5:	0f b6 00             	movzbl (%eax),%eax
80105bc8:	0f b6 c0             	movzbl %al,%eax
80105bcb:	29 c2                	sub    %eax,%edx
80105bcd:	89 d0                	mov    %edx,%eax
}
80105bcf:	5d                   	pop    %ebp
80105bd0:	c3                   	ret    

80105bd1 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105bd1:	55                   	push   %ebp
80105bd2:	89 e5                	mov    %esp,%ebp
80105bd4:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80105bda:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105bdd:	90                   	nop
80105bde:	8b 45 10             	mov    0x10(%ebp),%eax
80105be1:	8d 50 ff             	lea    -0x1(%eax),%edx
80105be4:	89 55 10             	mov    %edx,0x10(%ebp)
80105be7:	85 c0                	test   %eax,%eax
80105be9:	7e 1e                	jle    80105c09 <strncpy+0x38>
80105beb:	8b 45 08             	mov    0x8(%ebp),%eax
80105bee:	8d 50 01             	lea    0x1(%eax),%edx
80105bf1:	89 55 08             	mov    %edx,0x8(%ebp)
80105bf4:	8b 55 0c             	mov    0xc(%ebp),%edx
80105bf7:	8d 4a 01             	lea    0x1(%edx),%ecx
80105bfa:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105bfd:	0f b6 12             	movzbl (%edx),%edx
80105c00:	88 10                	mov    %dl,(%eax)
80105c02:	0f b6 00             	movzbl (%eax),%eax
80105c05:	84 c0                	test   %al,%al
80105c07:	75 d5                	jne    80105bde <strncpy+0xd>
    ;
  while(n-- > 0)
80105c09:	eb 0c                	jmp    80105c17 <strncpy+0x46>
    *s++ = 0;
80105c0b:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0e:	8d 50 01             	lea    0x1(%eax),%edx
80105c11:	89 55 08             	mov    %edx,0x8(%ebp)
80105c14:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105c17:	8b 45 10             	mov    0x10(%ebp),%eax
80105c1a:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c1d:	89 55 10             	mov    %edx,0x10(%ebp)
80105c20:	85 c0                	test   %eax,%eax
80105c22:	7f e7                	jg     80105c0b <strncpy+0x3a>
    *s++ = 0;
  return os;
80105c24:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c27:	c9                   	leave  
80105c28:	c3                   	ret    

80105c29 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105c29:	55                   	push   %ebp
80105c2a:	89 e5                	mov    %esp,%ebp
80105c2c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80105c32:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105c35:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c39:	7f 05                	jg     80105c40 <safestrcpy+0x17>
    return os;
80105c3b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c3e:	eb 31                	jmp    80105c71 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105c40:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c44:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c48:	7e 1e                	jle    80105c68 <safestrcpy+0x3f>
80105c4a:	8b 45 08             	mov    0x8(%ebp),%eax
80105c4d:	8d 50 01             	lea    0x1(%eax),%edx
80105c50:	89 55 08             	mov    %edx,0x8(%ebp)
80105c53:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c56:	8d 4a 01             	lea    0x1(%edx),%ecx
80105c59:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105c5c:	0f b6 12             	movzbl (%edx),%edx
80105c5f:	88 10                	mov    %dl,(%eax)
80105c61:	0f b6 00             	movzbl (%eax),%eax
80105c64:	84 c0                	test   %al,%al
80105c66:	75 d8                	jne    80105c40 <safestrcpy+0x17>
    ;
  *s = 0;
80105c68:	8b 45 08             	mov    0x8(%ebp),%eax
80105c6b:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c6e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c71:	c9                   	leave  
80105c72:	c3                   	ret    

80105c73 <strlen>:

int
strlen(const char *s)
{
80105c73:	55                   	push   %ebp
80105c74:	89 e5                	mov    %esp,%ebp
80105c76:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c79:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c80:	eb 04                	jmp    80105c86 <strlen+0x13>
80105c82:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c86:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c89:	8b 45 08             	mov    0x8(%ebp),%eax
80105c8c:	01 d0                	add    %edx,%eax
80105c8e:	0f b6 00             	movzbl (%eax),%eax
80105c91:	84 c0                	test   %al,%al
80105c93:	75 ed                	jne    80105c82 <strlen+0xf>
    ;
  return n;
80105c95:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c98:	c9                   	leave  
80105c99:	c3                   	ret    

80105c9a <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c9a:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c9e:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105ca2:	55                   	push   %ebp
  pushl %ebx
80105ca3:	53                   	push   %ebx
  pushl %esi
80105ca4:	56                   	push   %esi
  pushl %edi
80105ca5:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105ca6:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105ca8:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105caa:	5f                   	pop    %edi
  popl %esi
80105cab:	5e                   	pop    %esi
  popl %ebx
80105cac:	5b                   	pop    %ebx
  popl %ebp
80105cad:	5d                   	pop    %ebp
  ret
80105cae:	c3                   	ret    

80105caf <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105caf:	55                   	push   %ebp
80105cb0:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105cb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cb8:	8b 00                	mov    (%eax),%eax
80105cba:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cbd:	76 12                	jbe    80105cd1 <fetchint+0x22>
80105cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80105cc2:	8d 50 04             	lea    0x4(%eax),%edx
80105cc5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ccb:	8b 00                	mov    (%eax),%eax
80105ccd:	39 c2                	cmp    %eax,%edx
80105ccf:	76 07                	jbe    80105cd8 <fetchint+0x29>
    return -1;
80105cd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cd6:	eb 0f                	jmp    80105ce7 <fetchint+0x38>
  *ip = *(int*)(addr);
80105cd8:	8b 45 08             	mov    0x8(%ebp),%eax
80105cdb:	8b 10                	mov    (%eax),%edx
80105cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce0:	89 10                	mov    %edx,(%eax)
  return 0;
80105ce2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ce7:	5d                   	pop    %ebp
80105ce8:	c3                   	ret    

80105ce9 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105ce9:	55                   	push   %ebp
80105cea:	89 e5                	mov    %esp,%ebp
80105cec:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105cef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf5:	8b 00                	mov    (%eax),%eax
80105cf7:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cfa:	77 07                	ja     80105d03 <fetchstr+0x1a>
    return -1;
80105cfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d01:	eb 46                	jmp    80105d49 <fetchstr+0x60>
  *pp = (char*)addr;
80105d03:	8b 55 08             	mov    0x8(%ebp),%edx
80105d06:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d09:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105d0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d11:	8b 00                	mov    (%eax),%eax
80105d13:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105d16:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d19:	8b 00                	mov    (%eax),%eax
80105d1b:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105d1e:	eb 1c                	jmp    80105d3c <fetchstr+0x53>
    if(*s == 0)
80105d20:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d23:	0f b6 00             	movzbl (%eax),%eax
80105d26:	84 c0                	test   %al,%al
80105d28:	75 0e                	jne    80105d38 <fetchstr+0x4f>
      return s - *pp;
80105d2a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d30:	8b 00                	mov    (%eax),%eax
80105d32:	29 c2                	sub    %eax,%edx
80105d34:	89 d0                	mov    %edx,%eax
80105d36:	eb 11                	jmp    80105d49 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105d38:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d3c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d3f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d42:	72 dc                	jb     80105d20 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105d44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d49:	c9                   	leave  
80105d4a:	c3                   	ret    

80105d4b <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105d4b:	55                   	push   %ebp
80105d4c:	89 e5                	mov    %esp,%ebp
80105d4e:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105d51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d57:	8b 40 18             	mov    0x18(%eax),%eax
80105d5a:	8b 50 44             	mov    0x44(%eax),%edx
80105d5d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d60:	c1 e0 02             	shl    $0x2,%eax
80105d63:	01 d0                	add    %edx,%eax
80105d65:	8d 50 04             	lea    0x4(%eax),%edx
80105d68:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d6f:	89 14 24             	mov    %edx,(%esp)
80105d72:	e8 38 ff ff ff       	call   80105caf <fetchint>
}
80105d77:	c9                   	leave  
80105d78:	c3                   	ret    

80105d79 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d79:	55                   	push   %ebp
80105d7a:	89 e5                	mov    %esp,%ebp
80105d7c:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d7f:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d82:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d86:	8b 45 08             	mov    0x8(%ebp),%eax
80105d89:	89 04 24             	mov    %eax,(%esp)
80105d8c:	e8 ba ff ff ff       	call   80105d4b <argint>
80105d91:	85 c0                	test   %eax,%eax
80105d93:	79 07                	jns    80105d9c <argptr+0x23>
    return -1;
80105d95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d9a:	eb 3d                	jmp    80105dd9 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d9f:	89 c2                	mov    %eax,%edx
80105da1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105da7:	8b 00                	mov    (%eax),%eax
80105da9:	39 c2                	cmp    %eax,%edx
80105dab:	73 16                	jae    80105dc3 <argptr+0x4a>
80105dad:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105db0:	89 c2                	mov    %eax,%edx
80105db2:	8b 45 10             	mov    0x10(%ebp),%eax
80105db5:	01 c2                	add    %eax,%edx
80105db7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dbd:	8b 00                	mov    (%eax),%eax
80105dbf:	39 c2                	cmp    %eax,%edx
80105dc1:	76 07                	jbe    80105dca <argptr+0x51>
    return -1;
80105dc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dc8:	eb 0f                	jmp    80105dd9 <argptr+0x60>
  *pp = (char*)i;
80105dca:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dcd:	89 c2                	mov    %eax,%edx
80105dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dd2:	89 10                	mov    %edx,(%eax)
  return 0;
80105dd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dd9:	c9                   	leave  
80105dda:	c3                   	ret    

80105ddb <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105ddb:	55                   	push   %ebp
80105ddc:	89 e5                	mov    %esp,%ebp
80105dde:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105de1:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105de4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de8:	8b 45 08             	mov    0x8(%ebp),%eax
80105deb:	89 04 24             	mov    %eax,(%esp)
80105dee:	e8 58 ff ff ff       	call   80105d4b <argint>
80105df3:	85 c0                	test   %eax,%eax
80105df5:	79 07                	jns    80105dfe <argstr+0x23>
    return -1;
80105df7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dfc:	eb 12                	jmp    80105e10 <argstr+0x35>
  return fetchstr(addr, pp);
80105dfe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e01:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e04:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e08:	89 04 24             	mov    %eax,(%esp)
80105e0b:	e8 d9 fe ff ff       	call   80105ce9 <fetchstr>
}
80105e10:	c9                   	leave  
80105e11:	c3                   	ret    

80105e12 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105e12:	55                   	push   %ebp
80105e13:	89 e5                	mov    %esp,%ebp
80105e15:	53                   	push   %ebx
80105e16:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105e19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e1f:	8b 40 18             	mov    0x18(%eax),%eax
80105e22:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e25:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105e28:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e2c:	7e 30                	jle    80105e5e <syscall+0x4c>
80105e2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e31:	83 f8 15             	cmp    $0x15,%eax
80105e34:	77 28                	ja     80105e5e <syscall+0x4c>
80105e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e39:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e40:	85 c0                	test   %eax,%eax
80105e42:	74 1a                	je     80105e5e <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105e44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e4a:	8b 58 18             	mov    0x18(%eax),%ebx
80105e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e50:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80105e57:	ff d0                	call   *%eax
80105e59:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e5c:	eb 3d                	jmp    80105e9b <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e5e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e64:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e6d:	8b 40 10             	mov    0x10(%eax),%eax
80105e70:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e73:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e77:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e7f:	c7 04 24 8f a0 10 80 	movl   $0x8010a08f,(%esp)
80105e86:	e8 15 a5 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e91:	8b 40 18             	mov    0x18(%eax),%eax
80105e94:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e9b:	83 c4 24             	add    $0x24,%esp
80105e9e:	5b                   	pop    %ebx
80105e9f:	5d                   	pop    %ebp
80105ea0:	c3                   	ret    

80105ea1 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105ea1:	55                   	push   %ebp
80105ea2:	89 e5                	mov    %esp,%ebp
80105ea4:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105ea7:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eae:	8b 45 08             	mov    0x8(%ebp),%eax
80105eb1:	89 04 24             	mov    %eax,(%esp)
80105eb4:	e8 92 fe ff ff       	call   80105d4b <argint>
80105eb9:	85 c0                	test   %eax,%eax
80105ebb:	79 07                	jns    80105ec4 <argfd+0x23>
    return -1;
80105ebd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ec2:	eb 50                	jmp    80105f14 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105ec4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec7:	85 c0                	test   %eax,%eax
80105ec9:	78 21                	js     80105eec <argfd+0x4b>
80105ecb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ece:	83 f8 0f             	cmp    $0xf,%eax
80105ed1:	7f 19                	jg     80105eec <argfd+0x4b>
80105ed3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ed9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105edc:	83 c2 08             	add    $0x8,%edx
80105edf:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105ee3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ee6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105eea:	75 07                	jne    80105ef3 <argfd+0x52>
    return -1;
80105eec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ef1:	eb 21                	jmp    80105f14 <argfd+0x73>
  if(pfd)
80105ef3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105ef7:	74 08                	je     80105f01 <argfd+0x60>
    *pfd = fd;
80105ef9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105efc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105eff:	89 10                	mov    %edx,(%eax)
  if(pf)
80105f01:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f05:	74 08                	je     80105f0f <argfd+0x6e>
    *pf = f;
80105f07:	8b 45 10             	mov    0x10(%ebp),%eax
80105f0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f0d:	89 10                	mov    %edx,(%eax)
  return 0;
80105f0f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f14:	c9                   	leave  
80105f15:	c3                   	ret    

80105f16 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105f16:	55                   	push   %ebp
80105f17:	89 e5                	mov    %esp,%ebp
80105f19:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f1c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f23:	eb 30                	jmp    80105f55 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f2b:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f2e:	83 c2 08             	add    $0x8,%edx
80105f31:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f35:	85 c0                	test   %eax,%eax
80105f37:	75 18                	jne    80105f51 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f3f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f42:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f45:	8b 55 08             	mov    0x8(%ebp),%edx
80105f48:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f4c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f4f:	eb 0f                	jmp    80105f60 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f51:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f55:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f59:	7e ca                	jle    80105f25 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f60:	c9                   	leave  
80105f61:	c3                   	ret    

80105f62 <sys_dup>:

int
sys_dup(void)
{
80105f62:	55                   	push   %ebp
80105f63:	89 e5                	mov    %esp,%ebp
80105f65:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f68:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f6b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f6f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f76:	00 
80105f77:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f7e:	e8 1e ff ff ff       	call   80105ea1 <argfd>
80105f83:	85 c0                	test   %eax,%eax
80105f85:	79 07                	jns    80105f8e <sys_dup+0x2c>
    return -1;
80105f87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f8c:	eb 29                	jmp    80105fb7 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f91:	89 04 24             	mov    %eax,(%esp)
80105f94:	e8 7d ff ff ff       	call   80105f16 <fdalloc>
80105f99:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f9c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fa0:	79 07                	jns    80105fa9 <sys_dup+0x47>
    return -1;
80105fa2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa7:	eb 0e                	jmp    80105fb7 <sys_dup+0x55>
  filedup(f);
80105fa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fac:	89 04 24             	mov    %eax,(%esp)
80105faf:	e8 d2 b0 ff ff       	call   80101086 <filedup>
  return fd;
80105fb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105fb7:	c9                   	leave  
80105fb8:	c3                   	ret    

80105fb9 <sys_read>:

int
sys_read(void)
{
80105fb9:	55                   	push   %ebp
80105fba:	89 e5                	mov    %esp,%ebp
80105fbc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fbf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fc2:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fc6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fcd:	00 
80105fce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fd5:	e8 c7 fe ff ff       	call   80105ea1 <argfd>
80105fda:	85 c0                	test   %eax,%eax
80105fdc:	78 35                	js     80106013 <sys_read+0x5a>
80105fde:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fe1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105fec:	e8 5a fd ff ff       	call   80105d4b <argint>
80105ff1:	85 c0                	test   %eax,%eax
80105ff3:	78 1e                	js     80106013 <sys_read+0x5a>
80105ff5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff8:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ffc:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106003:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010600a:	e8 6a fd ff ff       	call   80105d79 <argptr>
8010600f:	85 c0                	test   %eax,%eax
80106011:	79 07                	jns    8010601a <sys_read+0x61>
    return -1;
80106013:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106018:	eb 19                	jmp    80106033 <sys_read+0x7a>
  return fileread(f, p, n);
8010601a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010601d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106020:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106023:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106027:	89 54 24 04          	mov    %edx,0x4(%esp)
8010602b:	89 04 24             	mov    %eax,(%esp)
8010602e:	e8 c0 b1 ff ff       	call   801011f3 <fileread>
}
80106033:	c9                   	leave  
80106034:	c3                   	ret    

80106035 <sys_write>:

int
sys_write(void)
{
80106035:	55                   	push   %ebp
80106036:	89 e5                	mov    %esp,%ebp
80106038:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010603b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010603e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106042:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106049:	00 
8010604a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106051:	e8 4b fe ff ff       	call   80105ea1 <argfd>
80106056:	85 c0                	test   %eax,%eax
80106058:	78 35                	js     8010608f <sys_write+0x5a>
8010605a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010605d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106061:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106068:	e8 de fc ff ff       	call   80105d4b <argint>
8010606d:	85 c0                	test   %eax,%eax
8010606f:	78 1e                	js     8010608f <sys_write+0x5a>
80106071:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106074:	89 44 24 08          	mov    %eax,0x8(%esp)
80106078:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010607b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010607f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106086:	e8 ee fc ff ff       	call   80105d79 <argptr>
8010608b:	85 c0                	test   %eax,%eax
8010608d:	79 07                	jns    80106096 <sys_write+0x61>
    return -1;
8010608f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106094:	eb 19                	jmp    801060af <sys_write+0x7a>
  return filewrite(f, p, n);
80106096:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106099:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010609c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010609f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060a3:	89 54 24 04          	mov    %edx,0x4(%esp)
801060a7:	89 04 24             	mov    %eax,(%esp)
801060aa:	e8 00 b2 ff ff       	call   801012af <filewrite>
}
801060af:	c9                   	leave  
801060b0:	c3                   	ret    

801060b1 <sys_close>:

int
sys_close(void)
{
801060b1:	55                   	push   %ebp
801060b2:	89 e5                	mov    %esp,%ebp
801060b4:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801060b7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060ba:	89 44 24 08          	mov    %eax,0x8(%esp)
801060be:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060cc:	e8 d0 fd ff ff       	call   80105ea1 <argfd>
801060d1:	85 c0                	test   %eax,%eax
801060d3:	79 07                	jns    801060dc <sys_close+0x2b>
    return -1;
801060d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060da:	eb 24                	jmp    80106100 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801060dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060e5:	83 c2 08             	add    $0x8,%edx
801060e8:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060ef:	00 
  fileclose(f);
801060f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060f3:	89 04 24             	mov    %eax,(%esp)
801060f6:	e8 d3 af ff ff       	call   801010ce <fileclose>
  return 0;
801060fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106100:	c9                   	leave  
80106101:	c3                   	ret    

80106102 <sys_fstat>:

int
sys_fstat(void)
{
80106102:	55                   	push   %ebp
80106103:	89 e5                	mov    %esp,%ebp
80106105:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106108:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010610b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010610f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106116:	00 
80106117:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010611e:	e8 7e fd ff ff       	call   80105ea1 <argfd>
80106123:	85 c0                	test   %eax,%eax
80106125:	78 1f                	js     80106146 <sys_fstat+0x44>
80106127:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010612e:	00 
8010612f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106132:	89 44 24 04          	mov    %eax,0x4(%esp)
80106136:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010613d:	e8 37 fc ff ff       	call   80105d79 <argptr>
80106142:	85 c0                	test   %eax,%eax
80106144:	79 07                	jns    8010614d <sys_fstat+0x4b>
    return -1;
80106146:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010614b:	eb 12                	jmp    8010615f <sys_fstat+0x5d>
  return filestat(f, st);
8010614d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106153:	89 54 24 04          	mov    %edx,0x4(%esp)
80106157:	89 04 24             	mov    %eax,(%esp)
8010615a:	e8 45 b0 ff ff       	call   801011a4 <filestat>
}
8010615f:	c9                   	leave  
80106160:	c3                   	ret    

80106161 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106161:	55                   	push   %ebp
80106162:	89 e5                	mov    %esp,%ebp
80106164:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106167:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010616a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106175:	e8 61 fc ff ff       	call   80105ddb <argstr>
8010617a:	85 c0                	test   %eax,%eax
8010617c:	78 17                	js     80106195 <sys_link+0x34>
8010617e:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106181:	89 44 24 04          	mov    %eax,0x4(%esp)
80106185:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010618c:	e8 4a fc ff ff       	call   80105ddb <argstr>
80106191:	85 c0                	test   %eax,%eax
80106193:	79 0a                	jns    8010619f <sys_link+0x3e>
    return -1;
80106195:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010619a:	e9 42 01 00 00       	jmp    801062e1 <sys_link+0x180>

  begin_op();
8010619f:	e8 12 da ff ff       	call   80103bb6 <begin_op>
  if((ip = namei(old)) == 0){
801061a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
801061a7:	89 04 24             	mov    %eax,(%esp)
801061aa:	e8 bb c3 ff ff       	call   8010256a <namei>
801061af:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061b2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061b6:	75 0f                	jne    801061c7 <sys_link+0x66>
    end_op();
801061b8:	e8 7d da ff ff       	call   80103c3a <end_op>
    return -1;
801061bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c2:	e9 1a 01 00 00       	jmp    801062e1 <sys_link+0x180>
  }

  ilock(ip);
801061c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ca:	89 04 24             	mov    %eax,(%esp)
801061cd:	e8 e7 b7 ff ff       	call   801019b9 <ilock>
  if(ip->type == T_DIR){
801061d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061d9:	66 83 f8 01          	cmp    $0x1,%ax
801061dd:	75 1a                	jne    801061f9 <sys_link+0x98>
    iunlockput(ip);
801061df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e2:	89 04 24             	mov    %eax,(%esp)
801061e5:	e8 59 ba ff ff       	call   80101c43 <iunlockput>
    end_op();
801061ea:	e8 4b da ff ff       	call   80103c3a <end_op>
    return -1;
801061ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061f4:	e9 e8 00 00 00       	jmp    801062e1 <sys_link+0x180>
  }

  ip->nlink++;
801061f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061fc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106200:	8d 50 01             	lea    0x1(%eax),%edx
80106203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106206:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010620a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010620d:	89 04 24             	mov    %eax,(%esp)
80106210:	e8 e2 b5 ff ff       	call   801017f7 <iupdate>
  iunlock(ip);
80106215:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106218:	89 04 24             	mov    %eax,(%esp)
8010621b:	e8 ed b8 ff ff       	call   80101b0d <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106220:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106223:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106226:	89 54 24 04          	mov    %edx,0x4(%esp)
8010622a:	89 04 24             	mov    %eax,(%esp)
8010622d:	e8 5a c3 ff ff       	call   8010258c <nameiparent>
80106232:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106235:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106239:	75 02                	jne    8010623d <sys_link+0xdc>
    goto bad;
8010623b:	eb 68                	jmp    801062a5 <sys_link+0x144>
  ilock(dp);
8010623d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106240:	89 04 24             	mov    %eax,(%esp)
80106243:	e8 71 b7 ff ff       	call   801019b9 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106248:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010624b:	8b 10                	mov    (%eax),%edx
8010624d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106250:	8b 00                	mov    (%eax),%eax
80106252:	39 c2                	cmp    %eax,%edx
80106254:	75 20                	jne    80106276 <sys_link+0x115>
80106256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106259:	8b 40 04             	mov    0x4(%eax),%eax
8010625c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106260:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106263:	89 44 24 04          	mov    %eax,0x4(%esp)
80106267:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010626a:	89 04 24             	mov    %eax,(%esp)
8010626d:	e8 38 c0 ff ff       	call   801022aa <dirlink>
80106272:	85 c0                	test   %eax,%eax
80106274:	79 0d                	jns    80106283 <sys_link+0x122>
    iunlockput(dp);
80106276:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106279:	89 04 24             	mov    %eax,(%esp)
8010627c:	e8 c2 b9 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106281:	eb 22                	jmp    801062a5 <sys_link+0x144>
  }
  iunlockput(dp);
80106283:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106286:	89 04 24             	mov    %eax,(%esp)
80106289:	e8 b5 b9 ff ff       	call   80101c43 <iunlockput>
  iput(ip);
8010628e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106291:	89 04 24             	mov    %eax,(%esp)
80106294:	e8 d9 b8 ff ff       	call   80101b72 <iput>

  end_op();
80106299:	e8 9c d9 ff ff       	call   80103c3a <end_op>

  return 0;
8010629e:	b8 00 00 00 00       	mov    $0x0,%eax
801062a3:	eb 3c                	jmp    801062e1 <sys_link+0x180>

bad:
  ilock(ip);
801062a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a8:	89 04 24             	mov    %eax,(%esp)
801062ab:	e8 09 b7 ff ff       	call   801019b9 <ilock>
  ip->nlink--;
801062b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062b7:	8d 50 ff             	lea    -0x1(%eax),%edx
801062ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bd:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c4:	89 04 24             	mov    %eax,(%esp)
801062c7:	e8 2b b5 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801062cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062cf:	89 04 24             	mov    %eax,(%esp)
801062d2:	e8 6c b9 ff ff       	call   80101c43 <iunlockput>
  end_op();
801062d7:	e8 5e d9 ff ff       	call   80103c3a <end_op>
  return -1;
801062dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062e1:	c9                   	leave  
801062e2:	c3                   	ret    

801062e3 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
int
isdirempty(struct inode *dp)
{
801062e3:	55                   	push   %ebp
801062e4:	89 e5                	mov    %esp,%ebp
801062e6:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062e9:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062f0:	eb 4b                	jmp    8010633d <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f5:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801062fc:	00 
801062fd:	89 44 24 08          	mov    %eax,0x8(%esp)
80106301:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106304:	89 44 24 04          	mov    %eax,0x4(%esp)
80106308:	8b 45 08             	mov    0x8(%ebp),%eax
8010630b:	89 04 24             	mov    %eax,(%esp)
8010630e:	e8 b9 bb ff ff       	call   80101ecc <readi>
80106313:	83 f8 10             	cmp    $0x10,%eax
80106316:	74 0c                	je     80106324 <isdirempty+0x41>
      panic("isdirempty: readi");
80106318:	c7 04 24 ab a0 10 80 	movl   $0x8010a0ab,(%esp)
8010631f:	e8 16 a2 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106324:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106328:	66 85 c0             	test   %ax,%ax
8010632b:	74 07                	je     80106334 <isdirempty+0x51>
      return 0;
8010632d:	b8 00 00 00 00       	mov    $0x0,%eax
80106332:	eb 1b                	jmp    8010634f <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106334:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106337:	83 c0 10             	add    $0x10,%eax
8010633a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010633d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106340:	8b 45 08             	mov    0x8(%ebp),%eax
80106343:	8b 40 18             	mov    0x18(%eax),%eax
80106346:	39 c2                	cmp    %eax,%edx
80106348:	72 a8                	jb     801062f2 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010634a:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010634f:	c9                   	leave  
80106350:	c3                   	ret    

80106351 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106351:	55                   	push   %ebp
80106352:	89 e5                	mov    %esp,%ebp
80106354:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106357:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010635a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010635e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106365:	e8 71 fa ff ff       	call   80105ddb <argstr>
8010636a:	85 c0                	test   %eax,%eax
8010636c:	79 0a                	jns    80106378 <sys_unlink+0x27>
    return -1;
8010636e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106373:	e9 af 01 00 00       	jmp    80106527 <sys_unlink+0x1d6>

  begin_op();
80106378:	e8 39 d8 ff ff       	call   80103bb6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010637d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106380:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106383:	89 54 24 04          	mov    %edx,0x4(%esp)
80106387:	89 04 24             	mov    %eax,(%esp)
8010638a:	e8 fd c1 ff ff       	call   8010258c <nameiparent>
8010638f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106392:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106396:	75 0f                	jne    801063a7 <sys_unlink+0x56>
    end_op();
80106398:	e8 9d d8 ff ff       	call   80103c3a <end_op>
    return -1;
8010639d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063a2:	e9 80 01 00 00       	jmp    80106527 <sys_unlink+0x1d6>
  }

  ilock(dp);
801063a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063aa:	89 04 24             	mov    %eax,(%esp)
801063ad:	e8 07 b6 ff ff       	call   801019b9 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801063b2:	c7 44 24 04 bd a0 10 	movl   $0x8010a0bd,0x4(%esp)
801063b9:	80 
801063ba:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063bd:	89 04 24             	mov    %eax,(%esp)
801063c0:	e8 fa bd ff ff       	call   801021bf <namecmp>
801063c5:	85 c0                	test   %eax,%eax
801063c7:	0f 84 45 01 00 00    	je     80106512 <sys_unlink+0x1c1>
801063cd:	c7 44 24 04 bf a0 10 	movl   $0x8010a0bf,0x4(%esp)
801063d4:	80 
801063d5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063d8:	89 04 24             	mov    %eax,(%esp)
801063db:	e8 df bd ff ff       	call   801021bf <namecmp>
801063e0:	85 c0                	test   %eax,%eax
801063e2:	0f 84 2a 01 00 00    	je     80106512 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063e8:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801063ef:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f9:	89 04 24             	mov    %eax,(%esp)
801063fc:	e8 e0 bd ff ff       	call   801021e1 <dirlookup>
80106401:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106404:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106408:	75 05                	jne    8010640f <sys_unlink+0xbe>
    goto bad;
8010640a:	e9 03 01 00 00       	jmp    80106512 <sys_unlink+0x1c1>
  ilock(ip);
8010640f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106412:	89 04 24             	mov    %eax,(%esp)
80106415:	e8 9f b5 ff ff       	call   801019b9 <ilock>

  if(ip->nlink < 1)
8010641a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010641d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106421:	66 85 c0             	test   %ax,%ax
80106424:	7f 0c                	jg     80106432 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106426:	c7 04 24 c2 a0 10 80 	movl   $0x8010a0c2,(%esp)
8010642d:	e8 08 a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106432:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106435:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106439:	66 83 f8 01          	cmp    $0x1,%ax
8010643d:	75 1f                	jne    8010645e <sys_unlink+0x10d>
8010643f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106442:	89 04 24             	mov    %eax,(%esp)
80106445:	e8 99 fe ff ff       	call   801062e3 <isdirempty>
8010644a:	85 c0                	test   %eax,%eax
8010644c:	75 10                	jne    8010645e <sys_unlink+0x10d>
    iunlockput(ip);
8010644e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106451:	89 04 24             	mov    %eax,(%esp)
80106454:	e8 ea b7 ff ff       	call   80101c43 <iunlockput>
    goto bad;
80106459:	e9 b4 00 00 00       	jmp    80106512 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
8010645e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106465:	00 
80106466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010646d:	00 
8010646e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106471:	89 04 24             	mov    %eax,(%esp)
80106474:	e8 90 f5 ff ff       	call   80105a09 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106479:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010647c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106483:	00 
80106484:	89 44 24 08          	mov    %eax,0x8(%esp)
80106488:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010648b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010648f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106492:	89 04 24             	mov    %eax,(%esp)
80106495:	e8 96 bb ff ff       	call   80102030 <writei>
8010649a:	83 f8 10             	cmp    $0x10,%eax
8010649d:	74 0c                	je     801064ab <sys_unlink+0x15a>
    panic("unlink: writei");
8010649f:	c7 04 24 d4 a0 10 80 	movl   $0x8010a0d4,(%esp)
801064a6:	e8 8f a0 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
801064ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ae:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064b2:	66 83 f8 01          	cmp    $0x1,%ax
801064b6:	75 1c                	jne    801064d4 <sys_unlink+0x183>
    dp->nlink--;
801064b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bb:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064bf:	8d 50 ff             	lea    -0x1(%eax),%edx
801064c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c5:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064cc:	89 04 24             	mov    %eax,(%esp)
801064cf:	e8 23 b3 ff ff       	call   801017f7 <iupdate>
  }
  iunlockput(dp);
801064d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d7:	89 04 24             	mov    %eax,(%esp)
801064da:	e8 64 b7 ff ff       	call   80101c43 <iunlockput>

  ip->nlink--;
801064df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064e6:	8d 50 ff             	lea    -0x1(%eax),%edx
801064e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ec:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f3:	89 04 24             	mov    %eax,(%esp)
801064f6:	e8 fc b2 ff ff       	call   801017f7 <iupdate>
  iunlockput(ip);
801064fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064fe:	89 04 24             	mov    %eax,(%esp)
80106501:	e8 3d b7 ff ff       	call   80101c43 <iunlockput>

  end_op();
80106506:	e8 2f d7 ff ff       	call   80103c3a <end_op>

  return 0;
8010650b:	b8 00 00 00 00       	mov    $0x0,%eax
80106510:	eb 15                	jmp    80106527 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80106512:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106515:	89 04 24             	mov    %eax,(%esp)
80106518:	e8 26 b7 ff ff       	call   80101c43 <iunlockput>
  end_op();
8010651d:	e8 18 d7 ff ff       	call   80103c3a <end_op>
  return -1;
80106522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106527:	c9                   	leave  
80106528:	c3                   	ret    

80106529 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
80106529:	55                   	push   %ebp
8010652a:	89 e5                	mov    %esp,%ebp
8010652c:	83 ec 48             	sub    $0x48,%esp
8010652f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106532:	8b 55 10             	mov    0x10(%ebp),%edx
80106535:	8b 45 14             	mov    0x14(%ebp),%eax
80106538:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010653c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106540:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106544:	8d 45 de             	lea    -0x22(%ebp),%eax
80106547:	89 44 24 04          	mov    %eax,0x4(%esp)
8010654b:	8b 45 08             	mov    0x8(%ebp),%eax
8010654e:	89 04 24             	mov    %eax,(%esp)
80106551:	e8 36 c0 ff ff       	call   8010258c <nameiparent>
80106556:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106559:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010655d:	75 0a                	jne    80106569 <create+0x40>
    return 0;
8010655f:	b8 00 00 00 00       	mov    $0x0,%eax
80106564:	e9 7e 01 00 00       	jmp    801066e7 <create+0x1be>
  ilock(dp);
80106569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010656c:	89 04 24             	mov    %eax,(%esp)
8010656f:	e8 45 b4 ff ff       	call   801019b9 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106574:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106577:	89 44 24 08          	mov    %eax,0x8(%esp)
8010657b:	8d 45 de             	lea    -0x22(%ebp),%eax
8010657e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106585:	89 04 24             	mov    %eax,(%esp)
80106588:	e8 54 bc ff ff       	call   801021e1 <dirlookup>
8010658d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106590:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106594:	74 47                	je     801065dd <create+0xb4>
    iunlockput(dp);
80106596:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106599:	89 04 24             	mov    %eax,(%esp)
8010659c:	e8 a2 b6 ff ff       	call   80101c43 <iunlockput>
    ilock(ip);
801065a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065a4:	89 04 24             	mov    %eax,(%esp)
801065a7:	e8 0d b4 ff ff       	call   801019b9 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801065ac:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801065b1:	75 15                	jne    801065c8 <create+0x9f>
801065b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801065ba:	66 83 f8 02          	cmp    $0x2,%ax
801065be:	75 08                	jne    801065c8 <create+0x9f>
      return ip;
801065c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065c3:	e9 1f 01 00 00       	jmp    801066e7 <create+0x1be>
    iunlockput(ip);
801065c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065cb:	89 04 24             	mov    %eax,(%esp)
801065ce:	e8 70 b6 ff ff       	call   80101c43 <iunlockput>
    return 0;
801065d3:	b8 00 00 00 00       	mov    $0x0,%eax
801065d8:	e9 0a 01 00 00       	jmp    801066e7 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801065dd:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801065e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e4:	8b 00                	mov    (%eax),%eax
801065e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801065ea:	89 04 24             	mov    %eax,(%esp)
801065ed:	e8 30 b1 ff ff       	call   80101722 <ialloc>
801065f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065f5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065f9:	75 0c                	jne    80106607 <create+0xde>
    panic("create: ialloc");
801065fb:	c7 04 24 e3 a0 10 80 	movl   $0x8010a0e3,(%esp)
80106602:	e8 33 9f ff ff       	call   8010053a <panic>

  ilock(ip);
80106607:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010660a:	89 04 24             	mov    %eax,(%esp)
8010660d:	e8 a7 b3 ff ff       	call   801019b9 <ilock>
  ip->major = major;
80106612:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106615:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106619:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
8010661d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106620:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106624:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106628:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010662b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106631:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106634:	89 04 24             	mov    %eax,(%esp)
80106637:	e8 bb b1 ff ff       	call   801017f7 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
8010663c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106641:	75 6a                	jne    801066ad <create+0x184>
    dp->nlink++;  // for ".."
80106643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106646:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010664a:	8d 50 01             	lea    0x1(%eax),%edx
8010664d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106650:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106654:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106657:	89 04 24             	mov    %eax,(%esp)
8010665a:	e8 98 b1 ff ff       	call   801017f7 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010665f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106662:	8b 40 04             	mov    0x4(%eax),%eax
80106665:	89 44 24 08          	mov    %eax,0x8(%esp)
80106669:	c7 44 24 04 bd a0 10 	movl   $0x8010a0bd,0x4(%esp)
80106670:	80 
80106671:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106674:	89 04 24             	mov    %eax,(%esp)
80106677:	e8 2e bc ff ff       	call   801022aa <dirlink>
8010667c:	85 c0                	test   %eax,%eax
8010667e:	78 21                	js     801066a1 <create+0x178>
80106680:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106683:	8b 40 04             	mov    0x4(%eax),%eax
80106686:	89 44 24 08          	mov    %eax,0x8(%esp)
8010668a:	c7 44 24 04 bf a0 10 	movl   $0x8010a0bf,0x4(%esp)
80106691:	80 
80106692:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106695:	89 04 24             	mov    %eax,(%esp)
80106698:	e8 0d bc ff ff       	call   801022aa <dirlink>
8010669d:	85 c0                	test   %eax,%eax
8010669f:	79 0c                	jns    801066ad <create+0x184>
      panic("create dots");
801066a1:	c7 04 24 f2 a0 10 80 	movl   $0x8010a0f2,(%esp)
801066a8:	e8 8d 9e ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
801066ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b0:	8b 40 04             	mov    0x4(%eax),%eax
801066b3:	89 44 24 08          	mov    %eax,0x8(%esp)
801066b7:	8d 45 de             	lea    -0x22(%ebp),%eax
801066ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801066be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c1:	89 04 24             	mov    %eax,(%esp)
801066c4:	e8 e1 bb ff ff       	call   801022aa <dirlink>
801066c9:	85 c0                	test   %eax,%eax
801066cb:	79 0c                	jns    801066d9 <create+0x1b0>
    panic("create: dirlink");
801066cd:	c7 04 24 fe a0 10 80 	movl   $0x8010a0fe,(%esp)
801066d4:	e8 61 9e ff ff       	call   8010053a <panic>

  iunlockput(dp);
801066d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066dc:	89 04 24             	mov    %eax,(%esp)
801066df:	e8 5f b5 ff ff       	call   80101c43 <iunlockput>

  return ip;
801066e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066e7:	c9                   	leave  
801066e8:	c3                   	ret    

801066e9 <sys_open>:

int
sys_open(void)
{
801066e9:	55                   	push   %ebp
801066ea:	89 e5                	mov    %esp,%ebp
801066ec:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066ef:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801066f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066fd:	e8 d9 f6 ff ff       	call   80105ddb <argstr>
80106702:	85 c0                	test   %eax,%eax
80106704:	78 17                	js     8010671d <sys_open+0x34>
80106706:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106709:	89 44 24 04          	mov    %eax,0x4(%esp)
8010670d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106714:	e8 32 f6 ff ff       	call   80105d4b <argint>
80106719:	85 c0                	test   %eax,%eax
8010671b:	79 0a                	jns    80106727 <sys_open+0x3e>
    return -1;
8010671d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106722:	e9 5c 01 00 00       	jmp    80106883 <sys_open+0x19a>

  begin_op();
80106727:	e8 8a d4 ff ff       	call   80103bb6 <begin_op>

  if(omode & O_CREATE){
8010672c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010672f:	25 00 02 00 00       	and    $0x200,%eax
80106734:	85 c0                	test   %eax,%eax
80106736:	74 3b                	je     80106773 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106738:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010673b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106742:	00 
80106743:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010674a:	00 
8010674b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106752:	00 
80106753:	89 04 24             	mov    %eax,(%esp)
80106756:	e8 ce fd ff ff       	call   80106529 <create>
8010675b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010675e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106762:	75 6b                	jne    801067cf <sys_open+0xe6>
      end_op();
80106764:	e8 d1 d4 ff ff       	call   80103c3a <end_op>
      return -1;
80106769:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010676e:	e9 10 01 00 00       	jmp    80106883 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106773:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106776:	89 04 24             	mov    %eax,(%esp)
80106779:	e8 ec bd ff ff       	call   8010256a <namei>
8010677e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106781:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106785:	75 0f                	jne    80106796 <sys_open+0xad>
      end_op();
80106787:	e8 ae d4 ff ff       	call   80103c3a <end_op>
      return -1;
8010678c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106791:	e9 ed 00 00 00       	jmp    80106883 <sys_open+0x19a>
    }
    ilock(ip);
80106796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106799:	89 04 24             	mov    %eax,(%esp)
8010679c:	e8 18 b2 ff ff       	call   801019b9 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801067a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801067a8:	66 83 f8 01          	cmp    $0x1,%ax
801067ac:	75 21                	jne    801067cf <sys_open+0xe6>
801067ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067b1:	85 c0                	test   %eax,%eax
801067b3:	74 1a                	je     801067cf <sys_open+0xe6>
      iunlockput(ip);
801067b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b8:	89 04 24             	mov    %eax,(%esp)
801067bb:	e8 83 b4 ff ff       	call   80101c43 <iunlockput>
      end_op();
801067c0:	e8 75 d4 ff ff       	call   80103c3a <end_op>
      return -1;
801067c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067ca:	e9 b4 00 00 00       	jmp    80106883 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067cf:	e8 52 a8 ff ff       	call   80101026 <filealloc>
801067d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067d7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067db:	74 14                	je     801067f1 <sys_open+0x108>
801067dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067e0:	89 04 24             	mov    %eax,(%esp)
801067e3:	e8 2e f7 ff ff       	call   80105f16 <fdalloc>
801067e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067eb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067ef:	79 28                	jns    80106819 <sys_open+0x130>
    if(f)
801067f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067f5:	74 0b                	je     80106802 <sys_open+0x119>
      fileclose(f);
801067f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067fa:	89 04 24             	mov    %eax,(%esp)
801067fd:	e8 cc a8 ff ff       	call   801010ce <fileclose>
    iunlockput(ip);
80106802:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106805:	89 04 24             	mov    %eax,(%esp)
80106808:	e8 36 b4 ff ff       	call   80101c43 <iunlockput>
    end_op();
8010680d:	e8 28 d4 ff ff       	call   80103c3a <end_op>
    return -1;
80106812:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106817:	eb 6a                	jmp    80106883 <sys_open+0x19a>
  }
  iunlock(ip);
80106819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010681c:	89 04 24             	mov    %eax,(%esp)
8010681f:	e8 e9 b2 ff ff       	call   80101b0d <iunlock>
  end_op();
80106824:	e8 11 d4 ff ff       	call   80103c3a <end_op>

  f->type = FD_INODE;
80106829:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010682c:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106832:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106835:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106838:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010683b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010683e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106845:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106848:	83 e0 01             	and    $0x1,%eax
8010684b:	85 c0                	test   %eax,%eax
8010684d:	0f 94 c0             	sete   %al
80106850:	89 c2                	mov    %eax,%edx
80106852:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106855:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106858:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010685b:	83 e0 01             	and    $0x1,%eax
8010685e:	85 c0                	test   %eax,%eax
80106860:	75 0a                	jne    8010686c <sys_open+0x183>
80106862:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106865:	83 e0 02             	and    $0x2,%eax
80106868:	85 c0                	test   %eax,%eax
8010686a:	74 07                	je     80106873 <sys_open+0x18a>
8010686c:	b8 01 00 00 00       	mov    $0x1,%eax
80106871:	eb 05                	jmp    80106878 <sys_open+0x18f>
80106873:	b8 00 00 00 00       	mov    $0x0,%eax
80106878:	89 c2                	mov    %eax,%edx
8010687a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010687d:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106880:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106883:	c9                   	leave  
80106884:	c3                   	ret    

80106885 <sys_mkdir>:

int
sys_mkdir(void)
{
80106885:	55                   	push   %ebp
80106886:	89 e5                	mov    %esp,%ebp
80106888:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010688b:	e8 26 d3 ff ff       	call   80103bb6 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106890:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106893:	89 44 24 04          	mov    %eax,0x4(%esp)
80106897:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010689e:	e8 38 f5 ff ff       	call   80105ddb <argstr>
801068a3:	85 c0                	test   %eax,%eax
801068a5:	78 2c                	js     801068d3 <sys_mkdir+0x4e>
801068a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801068b1:	00 
801068b2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801068b9:	00 
801068ba:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068c1:	00 
801068c2:	89 04 24             	mov    %eax,(%esp)
801068c5:	e8 5f fc ff ff       	call   80106529 <create>
801068ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068d1:	75 0c                	jne    801068df <sys_mkdir+0x5a>
    end_op();
801068d3:	e8 62 d3 ff ff       	call   80103c3a <end_op>
    return -1;
801068d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068dd:	eb 15                	jmp    801068f4 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801068df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e2:	89 04 24             	mov    %eax,(%esp)
801068e5:	e8 59 b3 ff ff       	call   80101c43 <iunlockput>
  end_op();
801068ea:	e8 4b d3 ff ff       	call   80103c3a <end_op>
  return 0;
801068ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068f4:	c9                   	leave  
801068f5:	c3                   	ret    

801068f6 <sys_mknod>:

int
sys_mknod(void)
{
801068f6:	55                   	push   %ebp
801068f7:	89 e5                	mov    %esp,%ebp
801068f9:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801068fc:	e8 b5 d2 ff ff       	call   80103bb6 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106901:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106904:	89 44 24 04          	mov    %eax,0x4(%esp)
80106908:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010690f:	e8 c7 f4 ff ff       	call   80105ddb <argstr>
80106914:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106917:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010691b:	78 5e                	js     8010697b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
8010691d:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106920:	89 44 24 04          	mov    %eax,0x4(%esp)
80106924:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010692b:	e8 1b f4 ff ff       	call   80105d4b <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106930:	85 c0                	test   %eax,%eax
80106932:	78 47                	js     8010697b <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106934:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106937:	89 44 24 04          	mov    %eax,0x4(%esp)
8010693b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106942:	e8 04 f4 ff ff       	call   80105d4b <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106947:	85 c0                	test   %eax,%eax
80106949:	78 30                	js     8010697b <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010694b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010694e:	0f bf c8             	movswl %ax,%ecx
80106951:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106954:	0f bf d0             	movswl %ax,%edx
80106957:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010695a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010695e:	89 54 24 08          	mov    %edx,0x8(%esp)
80106962:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106969:	00 
8010696a:	89 04 24             	mov    %eax,(%esp)
8010696d:	e8 b7 fb ff ff       	call   80106529 <create>
80106972:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106975:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106979:	75 0c                	jne    80106987 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010697b:	e8 ba d2 ff ff       	call   80103c3a <end_op>
    return -1;
80106980:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106985:	eb 15                	jmp    8010699c <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106987:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010698a:	89 04 24             	mov    %eax,(%esp)
8010698d:	e8 b1 b2 ff ff       	call   80101c43 <iunlockput>
  end_op();
80106992:	e8 a3 d2 ff ff       	call   80103c3a <end_op>
  return 0;
80106997:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010699c:	c9                   	leave  
8010699d:	c3                   	ret    

8010699e <sys_chdir>:

int
sys_chdir(void)
{
8010699e:	55                   	push   %ebp
8010699f:	89 e5                	mov    %esp,%ebp
801069a1:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801069a4:	e8 0d d2 ff ff       	call   80103bb6 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801069a9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801069ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801069b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069b7:	e8 1f f4 ff ff       	call   80105ddb <argstr>
801069bc:	85 c0                	test   %eax,%eax
801069be:	78 14                	js     801069d4 <sys_chdir+0x36>
801069c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069c3:	89 04 24             	mov    %eax,(%esp)
801069c6:	e8 9f bb ff ff       	call   8010256a <namei>
801069cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069d2:	75 0c                	jne    801069e0 <sys_chdir+0x42>
    end_op();
801069d4:	e8 61 d2 ff ff       	call   80103c3a <end_op>
    return -1;
801069d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069de:	eb 61                	jmp    80106a41 <sys_chdir+0xa3>
  }
  ilock(ip);
801069e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069e3:	89 04 24             	mov    %eax,(%esp)
801069e6:	e8 ce af ff ff       	call   801019b9 <ilock>
  if(ip->type != T_DIR){
801069eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ee:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069f2:	66 83 f8 01          	cmp    $0x1,%ax
801069f6:	74 17                	je     80106a0f <sys_chdir+0x71>
    iunlockput(ip);
801069f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069fb:	89 04 24             	mov    %eax,(%esp)
801069fe:	e8 40 b2 ff ff       	call   80101c43 <iunlockput>
    end_op();
80106a03:	e8 32 d2 ff ff       	call   80103c3a <end_op>
    return -1;
80106a08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a0d:	eb 32                	jmp    80106a41 <sys_chdir+0xa3>
  }
  iunlock(ip);
80106a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a12:	89 04 24             	mov    %eax,(%esp)
80106a15:	e8 f3 b0 ff ff       	call   80101b0d <iunlock>
  iput(proc->cwd);
80106a1a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a20:	8b 40 68             	mov    0x68(%eax),%eax
80106a23:	89 04 24             	mov    %eax,(%esp)
80106a26:	e8 47 b1 ff ff       	call   80101b72 <iput>
  end_op();
80106a2b:	e8 0a d2 ff ff       	call   80103c3a <end_op>
  proc->cwd = ip;
80106a30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a36:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a39:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a41:	c9                   	leave  
80106a42:	c3                   	ret    

80106a43 <sys_exec>:

int
sys_exec(void)
{
80106a43:	55                   	push   %ebp
80106a44:	89 e5                	mov    %esp,%ebp
80106a46:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a4c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a5a:	e8 7c f3 ff ff       	call   80105ddb <argstr>
80106a5f:	85 c0                	test   %eax,%eax
80106a61:	78 1a                	js     80106a7d <sys_exec+0x3a>
80106a63:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a69:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a6d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a74:	e8 d2 f2 ff ff       	call   80105d4b <argint>
80106a79:	85 c0                	test   %eax,%eax
80106a7b:	79 0a                	jns    80106a87 <sys_exec+0x44>
    return -1;
80106a7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a82:	e9 c8 00 00 00       	jmp    80106b4f <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106a87:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a8e:	00 
80106a8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a96:	00 
80106a97:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a9d:	89 04 24             	mov    %eax,(%esp)
80106aa0:	e8 64 ef ff ff       	call   80105a09 <memset>
  for(i=0;; i++){
80106aa5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106aac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aaf:	83 f8 1f             	cmp    $0x1f,%eax
80106ab2:	76 0a                	jbe    80106abe <sys_exec+0x7b>
      return -1;
80106ab4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ab9:	e9 91 00 00 00       	jmp    80106b4f <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ac1:	c1 e0 02             	shl    $0x2,%eax
80106ac4:	89 c2                	mov    %eax,%edx
80106ac6:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106acc:	01 c2                	add    %eax,%edx
80106ace:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106ad4:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ad8:	89 14 24             	mov    %edx,(%esp)
80106adb:	e8 cf f1 ff ff       	call   80105caf <fetchint>
80106ae0:	85 c0                	test   %eax,%eax
80106ae2:	79 07                	jns    80106aeb <sys_exec+0xa8>
      return -1;
80106ae4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae9:	eb 64                	jmp    80106b4f <sys_exec+0x10c>
    if(uarg == 0){
80106aeb:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106af1:	85 c0                	test   %eax,%eax
80106af3:	75 26                	jne    80106b1b <sys_exec+0xd8>
      argv[i] = 0;
80106af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106af8:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106aff:	00 00 00 00 
      break;
80106b03:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b07:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106b0d:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b11:	89 04 24             	mov    %eax,(%esp)
80106b14:	e8 f1 9f ff ff       	call   80100b0a <exec>
80106b19:	eb 34                	jmp    80106b4f <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106b1b:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b21:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b24:	c1 e2 02             	shl    $0x2,%edx
80106b27:	01 c2                	add    %eax,%edx
80106b29:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106b2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b33:	89 04 24             	mov    %eax,(%esp)
80106b36:	e8 ae f1 ff ff       	call   80105ce9 <fetchstr>
80106b3b:	85 c0                	test   %eax,%eax
80106b3d:	79 07                	jns    80106b46 <sys_exec+0x103>
      return -1;
80106b3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b44:	eb 09                	jmp    80106b4f <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b46:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106b4a:	e9 5d ff ff ff       	jmp    80106aac <sys_exec+0x69>
  return exec(path, argv);
}
80106b4f:	c9                   	leave  
80106b50:	c3                   	ret    

80106b51 <sys_pipe>:

int
sys_pipe(void)
{
80106b51:	55                   	push   %ebp
80106b52:	89 e5                	mov    %esp,%ebp
80106b54:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b57:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b5e:	00 
80106b5f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b62:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b6d:	e8 07 f2 ff ff       	call   80105d79 <argptr>
80106b72:	85 c0                	test   %eax,%eax
80106b74:	79 0a                	jns    80106b80 <sys_pipe+0x2f>
    return -1;
80106b76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b7b:	e9 9b 00 00 00       	jmp    80106c1b <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b80:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b83:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b87:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b8a:	89 04 24             	mov    %eax,(%esp)
80106b8d:	e8 30 db ff ff       	call   801046c2 <pipealloc>
80106b92:	85 c0                	test   %eax,%eax
80106b94:	79 07                	jns    80106b9d <sys_pipe+0x4c>
    return -1;
80106b96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b9b:	eb 7e                	jmp    80106c1b <sys_pipe+0xca>
  fd0 = -1;
80106b9d:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106ba4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ba7:	89 04 24             	mov    %eax,(%esp)
80106baa:	e8 67 f3 ff ff       	call   80105f16 <fdalloc>
80106baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bb6:	78 14                	js     80106bcc <sys_pipe+0x7b>
80106bb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bbb:	89 04 24             	mov    %eax,(%esp)
80106bbe:	e8 53 f3 ff ff       	call   80105f16 <fdalloc>
80106bc3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bc6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bca:	79 37                	jns    80106c03 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bcc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bd0:	78 14                	js     80106be6 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bd2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bd8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bdb:	83 c2 08             	add    $0x8,%edx
80106bde:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106be5:	00 
    fileclose(rf);
80106be6:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106be9:	89 04 24             	mov    %eax,(%esp)
80106bec:	e8 dd a4 ff ff       	call   801010ce <fileclose>
    fileclose(wf);
80106bf1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bf4:	89 04 24             	mov    %eax,(%esp)
80106bf7:	e8 d2 a4 ff ff       	call   801010ce <fileclose>
    return -1;
80106bfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c01:	eb 18                	jmp    80106c1b <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106c03:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c06:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c09:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106c0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106c0e:	8d 50 04             	lea    0x4(%eax),%edx
80106c11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c14:	89 02                	mov    %eax,(%edx)
  return 0;
80106c16:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c1b:	c9                   	leave  
80106c1c:	c3                   	ret    

80106c1d <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c1d:	55                   	push   %ebp
80106c1e:	89 e5                	mov    %esp,%ebp
80106c20:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c23:	e8 70 e2 ff ff       	call   80104e98 <fork>
}
80106c28:	c9                   	leave  
80106c29:	c3                   	ret    

80106c2a <sys_exit>:

int
sys_exit(void)
{
80106c2a:	55                   	push   %ebp
80106c2b:	89 e5                	mov    %esp,%ebp
80106c2d:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c30:	e8 1f e4 ff ff       	call   80105054 <exit>
  return 0;  // not reached
80106c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c3a:	c9                   	leave  
80106c3b:	c3                   	ret    

80106c3c <sys_wait>:

int
sys_wait(void)
{
80106c3c:	55                   	push   %ebp
80106c3d:	89 e5                	mov    %esp,%ebp
80106c3f:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c42:	e8 45 e5 ff ff       	call   8010518c <wait>
}
80106c47:	c9                   	leave  
80106c48:	c3                   	ret    

80106c49 <sys_kill>:

int
sys_kill(void)
{
80106c49:	55                   	push   %ebp
80106c4a:	89 e5                	mov    %esp,%ebp
80106c4c:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c4f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c52:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c5d:	e8 e9 f0 ff ff       	call   80105d4b <argint>
80106c62:	85 c0                	test   %eax,%eax
80106c64:	79 07                	jns    80106c6d <sys_kill+0x24>
    return -1;
80106c66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c6b:	eb 0b                	jmp    80106c78 <sys_kill+0x2f>
  return kill(pid);
80106c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c70:	89 04 24             	mov    %eax,(%esp)
80106c73:	e8 f2 e8 ff ff       	call   8010556a <kill>
}
80106c78:	c9                   	leave  
80106c79:	c3                   	ret    

80106c7a <sys_getpid>:

int
sys_getpid(void)
{
80106c7a:	55                   	push   %ebp
80106c7b:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c83:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c86:	5d                   	pop    %ebp
80106c87:	c3                   	ret    

80106c88 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c88:	55                   	push   %ebp
80106c89:	89 e5                	mov    %esp,%ebp
80106c8b:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c8e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c91:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c9c:	e8 aa f0 ff ff       	call   80105d4b <argint>
80106ca1:	85 c0                	test   %eax,%eax
80106ca3:	79 07                	jns    80106cac <sys_sbrk+0x24>
    return -1;
80106ca5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106caa:	eb 24                	jmp    80106cd0 <sys_sbrk+0x48>
  addr = proc->sz;
80106cac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cb2:	8b 00                	mov    (%eax),%eax
80106cb4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106cb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cba:	89 04 24             	mov    %eax,(%esp)
80106cbd:	e8 1b e1 ff ff       	call   80104ddd <growproc>
80106cc2:	85 c0                	test   %eax,%eax
80106cc4:	79 07                	jns    80106ccd <sys_sbrk+0x45>
    return -1;
80106cc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ccb:	eb 03                	jmp    80106cd0 <sys_sbrk+0x48>
  return addr;
80106ccd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cd0:	c9                   	leave  
80106cd1:	c3                   	ret    

80106cd2 <sys_sleep>:

int
sys_sleep(void)
{
80106cd2:	55                   	push   %ebp
80106cd3:	89 e5                	mov    %esp,%ebp
80106cd5:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106cd8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cdf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ce6:	e8 60 f0 ff ff       	call   80105d4b <argint>
80106ceb:	85 c0                	test   %eax,%eax
80106ced:	79 07                	jns    80106cf6 <sys_sleep+0x24>
    return -1;
80106cef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cf4:	eb 6c                	jmp    80106d62 <sys_sleep+0x90>
  acquire(&tickslock);
80106cf6:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106cfd:	e8 b3 ea ff ff       	call   801057b5 <acquire>
  ticks0 = ticks;
80106d02:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d07:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106d0a:	eb 34                	jmp    80106d40 <sys_sleep+0x6e>
    if(proc->killed){
80106d0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d12:	8b 40 24             	mov    0x24(%eax),%eax
80106d15:	85 c0                	test   %eax,%eax
80106d17:	74 13                	je     80106d2c <sys_sleep+0x5a>
      release(&tickslock);
80106d19:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d20:	e8 f2 ea ff ff       	call   80105817 <release>
      return -1;
80106d25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d2a:	eb 36                	jmp    80106d62 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d2c:	c7 44 24 04 c0 04 12 	movl   $0x801204c0,0x4(%esp)
80106d33:	80 
80106d34:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
80106d3b:	e8 23 e7 ff ff       	call   80105463 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d40:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d45:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106d48:	89 c2                	mov    %eax,%edx
80106d4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d4d:	39 c2                	cmp    %eax,%edx
80106d4f:	72 bb                	jb     80106d0c <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d51:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d58:	e8 ba ea ff ff       	call   80105817 <release>
  return 0;
80106d5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d62:	c9                   	leave  
80106d63:	c3                   	ret    

80106d64 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d64:	55                   	push   %ebp
80106d65:	89 e5                	mov    %esp,%ebp
80106d67:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d6a:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d71:	e8 3f ea ff ff       	call   801057b5 <acquire>
  xticks = ticks;
80106d76:	a1 00 0d 12 80       	mov    0x80120d00,%eax
80106d7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d7e:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106d85:	e8 8d ea ff ff       	call   80105817 <release>
  return xticks;
80106d8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d8d:	c9                   	leave  
80106d8e:	c3                   	ret    

80106d8f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d8f:	55                   	push   %ebp
80106d90:	89 e5                	mov    %esp,%ebp
80106d92:	83 ec 08             	sub    $0x8,%esp
80106d95:	8b 55 08             	mov    0x8(%ebp),%edx
80106d98:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d9b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d9f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106da2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106da6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106daa:	ee                   	out    %al,(%dx)
}
80106dab:	c9                   	leave  
80106dac:	c3                   	ret    

80106dad <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106dad:	55                   	push   %ebp
80106dae:	89 e5                	mov    %esp,%ebp
80106db0:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106db3:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106dba:	00 
80106dbb:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106dc2:	e8 c8 ff ff ff       	call   80106d8f <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106dc7:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106dce:	00 
80106dcf:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dd6:	e8 b4 ff ff ff       	call   80106d8f <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106ddb:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106de2:	00 
80106de3:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106dea:	e8 a0 ff ff ff       	call   80106d8f <outb>
  picenable(IRQ_TIMER);
80106def:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106df6:	e8 5a d7 ff ff       	call   80104555 <picenable>
}
80106dfb:	c9                   	leave  
80106dfc:	c3                   	ret    

80106dfd <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106dfd:	1e                   	push   %ds
  pushl %es
80106dfe:	06                   	push   %es
  pushl %fs
80106dff:	0f a0                	push   %fs
  pushl %gs
80106e01:	0f a8                	push   %gs
  pushal
80106e03:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106e04:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106e08:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e0a:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e0c:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e10:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e12:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e14:	54                   	push   %esp
  call trap
80106e15:	e8 d8 01 00 00       	call   80106ff2 <trap>
  addl $4, %esp
80106e1a:	83 c4 04             	add    $0x4,%esp

80106e1d <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e1d:	61                   	popa   
  popl %gs
80106e1e:	0f a9                	pop    %gs
  popl %fs
80106e20:	0f a1                	pop    %fs
  popl %es
80106e22:	07                   	pop    %es
  popl %ds
80106e23:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e24:	83 c4 08             	add    $0x8,%esp
  iret
80106e27:	cf                   	iret   

80106e28 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e28:	55                   	push   %ebp
80106e29:	89 e5                	mov    %esp,%ebp
80106e2b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e31:	83 e8 01             	sub    $0x1,%eax
80106e34:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e38:	8b 45 08             	mov    0x8(%ebp),%eax
80106e3b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80106e42:	c1 e8 10             	shr    $0x10,%eax
80106e45:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e49:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e4c:	0f 01 18             	lidtl  (%eax)
}
80106e4f:	c9                   	leave  
80106e50:	c3                   	ret    

80106e51 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e51:	55                   	push   %ebp
80106e52:	89 e5                	mov    %esp,%ebp
80106e54:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106e57:	0f 20 d0             	mov    %cr2,%eax
80106e5a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106e5d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106e60:	c9                   	leave  
80106e61:	c3                   	ret    

80106e62 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106e62:	55                   	push   %ebp
80106e63:	89 e5                	mov    %esp,%ebp
80106e65:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106e68:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106e6f:	e9 c3 00 00 00       	jmp    80106f37 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e77:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106e7e:	89 c2                	mov    %eax,%edx
80106e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e83:	66 89 14 c5 00 05 12 	mov    %dx,-0x7fedfb00(,%eax,8)
80106e8a:	80 
80106e8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e8e:	66 c7 04 c5 02 05 12 	movw   $0x8,-0x7fedfafe(,%eax,8)
80106e95:	80 08 00 
80106e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e9b:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106ea2:	80 
80106ea3:	83 e2 e0             	and    $0xffffffe0,%edx
80106ea6:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb0:	0f b6 14 c5 04 05 12 	movzbl -0x7fedfafc(,%eax,8),%edx
80106eb7:	80 
80106eb8:	83 e2 1f             	and    $0x1f,%edx
80106ebb:	88 14 c5 04 05 12 80 	mov    %dl,-0x7fedfafc(,%eax,8)
80106ec2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ec5:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ecc:	80 
80106ecd:	83 e2 f0             	and    $0xfffffff0,%edx
80106ed0:	83 ca 0e             	or     $0xe,%edx
80106ed3:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106eda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106edd:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ee4:	80 
80106ee5:	83 e2 ef             	and    $0xffffffef,%edx
80106ee8:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106eef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef2:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106ef9:	80 
80106efa:	83 e2 9f             	and    $0xffffff9f,%edx
80106efd:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f07:	0f b6 14 c5 05 05 12 	movzbl -0x7fedfafb(,%eax,8),%edx
80106f0e:	80 
80106f0f:	83 ca 80             	or     $0xffffff80,%edx
80106f12:	88 14 c5 05 05 12 80 	mov    %dl,-0x7fedfafb(,%eax,8)
80106f19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1c:	8b 04 85 98 d0 10 80 	mov    -0x7fef2f68(,%eax,4),%eax
80106f23:	c1 e8 10             	shr    $0x10,%eax
80106f26:	89 c2                	mov    %eax,%edx
80106f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f2b:	66 89 14 c5 06 05 12 	mov    %dx,-0x7fedfafa(,%eax,8)
80106f32:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f33:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f37:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f3e:	0f 8e 30 ff ff ff    	jle    80106e74 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f44:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106f49:	66 a3 00 07 12 80    	mov    %ax,0x80120700
80106f4f:	66 c7 05 02 07 12 80 	movw   $0x8,0x80120702
80106f56:	08 00 
80106f58:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f5f:	83 e0 e0             	and    $0xffffffe0,%eax
80106f62:	a2 04 07 12 80       	mov    %al,0x80120704
80106f67:	0f b6 05 04 07 12 80 	movzbl 0x80120704,%eax
80106f6e:	83 e0 1f             	and    $0x1f,%eax
80106f71:	a2 04 07 12 80       	mov    %al,0x80120704
80106f76:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f7d:	83 c8 0f             	or     $0xf,%eax
80106f80:	a2 05 07 12 80       	mov    %al,0x80120705
80106f85:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f8c:	83 e0 ef             	and    $0xffffffef,%eax
80106f8f:	a2 05 07 12 80       	mov    %al,0x80120705
80106f94:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106f9b:	83 c8 60             	or     $0x60,%eax
80106f9e:	a2 05 07 12 80       	mov    %al,0x80120705
80106fa3:	0f b6 05 05 07 12 80 	movzbl 0x80120705,%eax
80106faa:	83 c8 80             	or     $0xffffff80,%eax
80106fad:	a2 05 07 12 80       	mov    %al,0x80120705
80106fb2:	a1 98 d1 10 80       	mov    0x8010d198,%eax
80106fb7:	c1 e8 10             	shr    $0x10,%eax
80106fba:	66 a3 06 07 12 80    	mov    %ax,0x80120706
  
  initlock(&tickslock, "time");
80106fc0:	c7 44 24 04 10 a1 10 	movl   $0x8010a110,0x4(%esp)
80106fc7:	80 
80106fc8:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80106fcf:	e8 c0 e7 ff ff       	call   80105794 <initlock>
}
80106fd4:	c9                   	leave  
80106fd5:	c3                   	ret    

80106fd6 <idtinit>:

void
idtinit(void)
{
80106fd6:	55                   	push   %ebp
80106fd7:	89 e5                	mov    %esp,%ebp
80106fd9:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106fdc:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106fe3:	00 
80106fe4:	c7 04 24 00 05 12 80 	movl   $0x80120500,(%esp)
80106feb:	e8 38 fe ff ff       	call   80106e28 <lidt>
}
80106ff0:	c9                   	leave  
80106ff1:	c3                   	ret    

80106ff2 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106ff2:	55                   	push   %ebp
80106ff3:	89 e5                	mov    %esp,%ebp
80106ff5:	57                   	push   %edi
80106ff6:	56                   	push   %esi
80106ff7:	53                   	push   %ebx
80106ff8:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80106ffe:	8b 40 30             	mov    0x30(%eax),%eax
80107001:	83 f8 40             	cmp    $0x40,%eax
80107004:	75 3f                	jne    80107045 <trap+0x53>
    if(proc->killed)
80107006:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010700c:	8b 40 24             	mov    0x24(%eax),%eax
8010700f:	85 c0                	test   %eax,%eax
80107011:	74 05                	je     80107018 <trap+0x26>
      exit();
80107013:	e8 3c e0 ff ff       	call   80105054 <exit>
    proc->tf = tf;
80107018:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010701e:	8b 55 08             	mov    0x8(%ebp),%edx
80107021:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107024:	e8 e9 ed ff ff       	call   80105e12 <syscall>
    if(proc->killed)
80107029:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010702f:	8b 40 24             	mov    0x24(%eax),%eax
80107032:	85 c0                	test   %eax,%eax
80107034:	74 0a                	je     80107040 <trap+0x4e>
      exit();
80107036:	e8 19 e0 ff ff       	call   80105054 <exit>
    return;
8010703b:	e9 d3 02 00 00       	jmp    80107313 <trap+0x321>
80107040:	e9 ce 02 00 00       	jmp    80107313 <trap+0x321>
  }
  switch(tf->trapno){
80107045:	8b 45 08             	mov    0x8(%ebp),%eax
80107048:	8b 40 30             	mov    0x30(%eax),%eax
8010704b:	83 e8 0e             	sub    $0xe,%eax
8010704e:	83 f8 31             	cmp    $0x31,%eax
80107051:	0f 87 54 01 00 00    	ja     801071ab <trap+0x1b9>
80107057:	8b 04 85 10 a2 10 80 	mov    -0x7fef5df0(,%eax,4),%eax
8010705e:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107060:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107066:	0f b6 00             	movzbl (%eax),%eax
80107069:	84 c0                	test   %al,%al
8010706b:	75 31                	jne    8010709e <trap+0xac>
      acquire(&tickslock);
8010706d:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107074:	e8 3c e7 ff ff       	call   801057b5 <acquire>
      ticks++;
80107079:	a1 00 0d 12 80       	mov    0x80120d00,%eax
8010707e:	83 c0 01             	add    $0x1,%eax
80107081:	a3 00 0d 12 80       	mov    %eax,0x80120d00
      wakeup(&ticks);
80107086:	c7 04 24 00 0d 12 80 	movl   $0x80120d00,(%esp)
8010708d:	e8 ad e4 ff ff       	call   8010553f <wakeup>
      release(&tickslock);
80107092:	c7 04 24 c0 04 12 80 	movl   $0x801204c0,(%esp)
80107099:	e8 79 e7 ff ff       	call   80105817 <release>
    }
    lapiceoi();
8010709e:	e8 dd c5 ff ff       	call   80103680 <lapiceoi>
    break;
801070a3:	e9 d9 01 00 00       	jmp    80107281 <trap+0x28f>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801070a8:	e8 72 bd ff ff       	call   80102e1f <ideintr>
    lapiceoi();
801070ad:	e8 ce c5 ff ff       	call   80103680 <lapiceoi>
    break;
801070b2:	e9 ca 01 00 00       	jmp    80107281 <trap+0x28f>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801070b7:	e8 93 c3 ff ff       	call   8010344f <kbdintr>
    lapiceoi();
801070bc:	e8 bf c5 ff ff       	call   80103680 <lapiceoi>
    break;
801070c1:	e9 bb 01 00 00       	jmp    80107281 <trap+0x28f>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801070c6:	e8 3d 04 00 00       	call   80107508 <uartintr>
    lapiceoi();
801070cb:	e8 b0 c5 ff ff       	call   80103680 <lapiceoi>
    break;
801070d0:	e9 ac 01 00 00       	jmp    80107281 <trap+0x28f>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070d5:	8b 45 08             	mov    0x8(%ebp),%eax
801070d8:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801070db:	8b 45 08             	mov    0x8(%ebp),%eax
801070de:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070e2:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801070e5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070eb:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801070ee:	0f b6 c0             	movzbl %al,%eax
801070f1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070f5:	89 54 24 08          	mov    %edx,0x8(%esp)
801070f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801070fd:	c7 04 24 18 a1 10 80 	movl   $0x8010a118,(%esp)
80107104:	e8 97 92 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107109:	e8 72 c5 ff ff       	call   80103680 <lapiceoi>
    break;
8010710e:	e9 6e 01 00 00       	jmp    80107281 <trap+0x28f>
    //page fault
    //int i;
  case T_PGFLT:
    proc->pageFaultCounter++;
80107113:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107119:	8b 90 88 00 00 00    	mov    0x88(%eax),%edx
8010711f:	83 c2 01             	add    $0x1,%edx
80107122:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
  	cprintf("page fault! pid %d va: %x between: %x and: %x\n",proc->pid,rcr2(),PGROUNDDOWN(rcr2()),PGROUNDUP(rcr2()));
80107128:	e8 24 fd ff ff       	call   80106e51 <rcr2>
8010712d:	05 ff 0f 00 00       	add    $0xfff,%eax
80107132:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107137:	89 c6                	mov    %eax,%esi
80107139:	e8 13 fd ff ff       	call   80106e51 <rcr2>
8010713e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107143:	89 c3                	mov    %eax,%ebx
80107145:	e8 07 fd ff ff       	call   80106e51 <rcr2>
8010714a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107151:	8b 52 10             	mov    0x10(%edx),%edx
80107154:	89 74 24 10          	mov    %esi,0x10(%esp)
80107158:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010715c:	89 44 24 08          	mov    %eax,0x8(%esp)
80107160:	89 54 24 04          	mov    %edx,0x4(%esp)
80107164:	c7 04 24 3c a1 10 80 	movl   $0x8010a13c,(%esp)
8010716b:	e8 30 92 ff ff       	call   801003a0 <cprintf>
    // for(i = 0; i < 30; i++){
    //   if(proc->pagesMetaData[i].va != (char *) -1)
    //     cprintf("%d %x %d\n",i,proc->pagesMetaData[i].va,proc->pagesMetaData[i].isPhysical);
    // }
    //va = p2v(rcr2());
    if(existOnDisc(rcr2())){
80107170:	e8 dc fc ff ff       	call   80106e51 <rcr2>
80107175:	89 04 24             	mov    %eax,(%esp)
80107178:	e8 9e 21 00 00       	call   8010931b <existOnDisc>
8010717d:	85 c0                	test   %eax,%eax
8010717f:	74 2a                	je     801071ab <trap+0x1b9>
      cprintf("found on disk, recovering\n");
80107181:	c7 04 24 6b a1 10 80 	movl   $0x8010a16b,(%esp)
80107188:	e8 13 92 ff ff       	call   801003a0 <cprintf>
      fixPage(rcr2());
8010718d:	e8 bf fc ff ff       	call   80106e51 <rcr2>
80107192:	89 04 24             	mov    %eax,(%esp)
80107195:	e8 6d 22 00 00       	call   80109407 <fixPage>
      cprintf("recovered!\n");
8010719a:	c7 04 24 86 a1 10 80 	movl   $0x8010a186,(%esp)
801071a1:	e8 fa 91 ff ff       	call   801003a0 <cprintf>
      break;
801071a6:	e9 d6 00 00 00       	jmp    80107281 <trap+0x28f>
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801071ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071b1:	85 c0                	test   %eax,%eax
801071b3:	74 11                	je     801071c6 <trap+0x1d4>
801071b5:	8b 45 08             	mov    0x8(%ebp),%eax
801071b8:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801071bc:	0f b7 c0             	movzwl %ax,%eax
801071bf:	83 e0 03             	and    $0x3,%eax
801071c2:	85 c0                	test   %eax,%eax
801071c4:	75 46                	jne    8010720c <trap+0x21a>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071c6:	e8 86 fc ff ff       	call   80106e51 <rcr2>
801071cb:	8b 55 08             	mov    0x8(%ebp),%edx
801071ce:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801071d1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801071d8:	0f b6 12             	movzbl (%edx),%edx
    }
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801071db:	0f b6 ca             	movzbl %dl,%ecx
801071de:	8b 55 08             	mov    0x8(%ebp),%edx
801071e1:	8b 52 30             	mov    0x30(%edx),%edx
801071e4:	89 44 24 10          	mov    %eax,0x10(%esp)
801071e8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801071ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801071f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801071f4:	c7 04 24 94 a1 10 80 	movl   $0x8010a194,(%esp)
801071fb:	e8 a0 91 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107200:	c7 04 24 c6 a1 10 80 	movl   $0x8010a1c6,(%esp)
80107207:	e8 2e 93 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010720c:	e8 40 fc ff ff       	call   80106e51 <rcr2>
80107211:	89 c2                	mov    %eax,%edx
80107213:	8b 45 08             	mov    0x8(%ebp),%eax
80107216:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107219:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010721f:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107222:	0f b6 f0             	movzbl %al,%esi
80107225:	8b 45 08             	mov    0x8(%ebp),%eax
80107228:	8b 58 34             	mov    0x34(%eax),%ebx
8010722b:	8b 45 08             	mov    0x8(%ebp),%eax
8010722e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107231:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107237:	83 c0 6c             	add    $0x6c,%eax
8010723a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010723d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107243:	8b 40 10             	mov    0x10(%eax),%eax
80107246:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010724a:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010724e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107252:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107256:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010725a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010725d:	89 7c 24 08          	mov    %edi,0x8(%esp)
80107261:	89 44 24 04          	mov    %eax,0x4(%esp)
80107265:	c7 04 24 cc a1 10 80 	movl   $0x8010a1cc,(%esp)
8010726c:	e8 2f 91 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107271:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107277:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010727e:	eb 01                	jmp    80107281 <trap+0x28f>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107280:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107281:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107287:	85 c0                	test   %eax,%eax
80107289:	74 24                	je     801072af <trap+0x2bd>
8010728b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107291:	8b 40 24             	mov    0x24(%eax),%eax
80107294:	85 c0                	test   %eax,%eax
80107296:	74 17                	je     801072af <trap+0x2bd>
80107298:	8b 45 08             	mov    0x8(%ebp),%eax
8010729b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010729f:	0f b7 c0             	movzwl %ax,%eax
801072a2:	83 e0 03             	and    $0x3,%eax
801072a5:	83 f8 03             	cmp    $0x3,%eax
801072a8:	75 05                	jne    801072af <trap+0x2bd>
    exit();
801072aa:	e8 a5 dd ff ff       	call   80105054 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER){
801072af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b5:	85 c0                	test   %eax,%eax
801072b7:	74 2c                	je     801072e5 <trap+0x2f3>
801072b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072bf:	8b 40 0c             	mov    0xc(%eax),%eax
801072c2:	83 f8 04             	cmp    $0x4,%eax
801072c5:	75 1e                	jne    801072e5 <trap+0x2f3>
801072c7:	8b 45 08             	mov    0x8(%ebp),%eax
801072ca:	8b 40 30             	mov    0x30(%eax),%eax
801072cd:	83 f8 20             	cmp    $0x20,%eax
801072d0:	75 13                	jne    801072e5 <trap+0x2f3>
    //update age of pages.TODO:check it is the right place.
    if (SCHEDFLAG==4) updateAge(proc); //TODO: maybe need to get proc?
801072d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072d8:	89 04 24             	mov    %eax,(%esp)
801072db:	e8 24 26 00 00       	call   80109904 <updateAge>
    yield();
801072e0:	e8 0d e1 ff ff       	call   801053f2 <yield>
  }

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801072e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072eb:	85 c0                	test   %eax,%eax
801072ed:	74 24                	je     80107313 <trap+0x321>
801072ef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072f5:	8b 40 24             	mov    0x24(%eax),%eax
801072f8:	85 c0                	test   %eax,%eax
801072fa:	74 17                	je     80107313 <trap+0x321>
801072fc:	8b 45 08             	mov    0x8(%ebp),%eax
801072ff:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107303:	0f b7 c0             	movzwl %ax,%eax
80107306:	83 e0 03             	and    $0x3,%eax
80107309:	83 f8 03             	cmp    $0x3,%eax
8010730c:	75 05                	jne    80107313 <trap+0x321>
    exit();
8010730e:	e8 41 dd ff ff       	call   80105054 <exit>
}
80107313:	83 c4 3c             	add    $0x3c,%esp
80107316:	5b                   	pop    %ebx
80107317:	5e                   	pop    %esi
80107318:	5f                   	pop    %edi
80107319:	5d                   	pop    %ebp
8010731a:	c3                   	ret    

8010731b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010731b:	55                   	push   %ebp
8010731c:	89 e5                	mov    %esp,%ebp
8010731e:	83 ec 14             	sub    $0x14,%esp
80107321:	8b 45 08             	mov    0x8(%ebp),%eax
80107324:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107328:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010732c:	89 c2                	mov    %eax,%edx
8010732e:	ec                   	in     (%dx),%al
8010732f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107332:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107336:	c9                   	leave  
80107337:	c3                   	ret    

80107338 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107338:	55                   	push   %ebp
80107339:	89 e5                	mov    %esp,%ebp
8010733b:	83 ec 08             	sub    $0x8,%esp
8010733e:	8b 55 08             	mov    0x8(%ebp),%edx
80107341:	8b 45 0c             	mov    0xc(%ebp),%eax
80107344:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107348:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010734b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010734f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107353:	ee                   	out    %al,(%dx)
}
80107354:	c9                   	leave  
80107355:	c3                   	ret    

80107356 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107356:	55                   	push   %ebp
80107357:	89 e5                	mov    %esp,%ebp
80107359:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010735c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107363:	00 
80107364:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010736b:	e8 c8 ff ff ff       	call   80107338 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107370:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107377:	00 
80107378:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010737f:	e8 b4 ff ff ff       	call   80107338 <outb>
  outb(COM1+0, 115200/9600);
80107384:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010738b:	00 
8010738c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107393:	e8 a0 ff ff ff       	call   80107338 <outb>
  outb(COM1+1, 0);
80107398:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010739f:	00 
801073a0:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073a7:	e8 8c ff ff ff       	call   80107338 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801073ac:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801073b3:	00 
801073b4:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801073bb:	e8 78 ff ff ff       	call   80107338 <outb>
  outb(COM1+4, 0);
801073c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073c7:	00 
801073c8:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801073cf:	e8 64 ff ff ff       	call   80107338 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801073d4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801073db:	00 
801073dc:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801073e3:	e8 50 ff ff ff       	call   80107338 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801073e8:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073ef:	e8 27 ff ff ff       	call   8010731b <inb>
801073f4:	3c ff                	cmp    $0xff,%al
801073f6:	75 02                	jne    801073fa <uartinit+0xa4>
    return;
801073f8:	eb 6a                	jmp    80107464 <uartinit+0x10e>
  uart = 1;
801073fa:	c7 05 50 d6 10 80 01 	movl   $0x1,0x8010d650
80107401:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107404:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010740b:	e8 0b ff ff ff       	call   8010731b <inb>
  inb(COM1+0);
80107410:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107417:	e8 ff fe ff ff       	call   8010731b <inb>
  picenable(IRQ_COM1);
8010741c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107423:	e8 2d d1 ff ff       	call   80104555 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107428:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010742f:	00 
80107430:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107437:	e8 62 bc ff ff       	call   8010309e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010743c:	c7 45 f4 d8 a2 10 80 	movl   $0x8010a2d8,-0xc(%ebp)
80107443:	eb 15                	jmp    8010745a <uartinit+0x104>
    uartputc(*p);
80107445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107448:	0f b6 00             	movzbl (%eax),%eax
8010744b:	0f be c0             	movsbl %al,%eax
8010744e:	89 04 24             	mov    %eax,(%esp)
80107451:	e8 10 00 00 00       	call   80107466 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107456:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010745a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010745d:	0f b6 00             	movzbl (%eax),%eax
80107460:	84 c0                	test   %al,%al
80107462:	75 e1                	jne    80107445 <uartinit+0xef>
    uartputc(*p);
}
80107464:	c9                   	leave  
80107465:	c3                   	ret    

80107466 <uartputc>:

void
uartputc(int c)
{
80107466:	55                   	push   %ebp
80107467:	89 e5                	mov    %esp,%ebp
80107469:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010746c:	a1 50 d6 10 80       	mov    0x8010d650,%eax
80107471:	85 c0                	test   %eax,%eax
80107473:	75 02                	jne    80107477 <uartputc+0x11>
    return;
80107475:	eb 4b                	jmp    801074c2 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107477:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010747e:	eb 10                	jmp    80107490 <uartputc+0x2a>
    microdelay(10);
80107480:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107487:	e8 19 c2 ff ff       	call   801036a5 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010748c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107490:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107494:	7f 16                	jg     801074ac <uartputc+0x46>
80107496:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010749d:	e8 79 fe ff ff       	call   8010731b <inb>
801074a2:	0f b6 c0             	movzbl %al,%eax
801074a5:	83 e0 20             	and    $0x20,%eax
801074a8:	85 c0                	test   %eax,%eax
801074aa:	74 d4                	je     80107480 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801074ac:	8b 45 08             	mov    0x8(%ebp),%eax
801074af:	0f b6 c0             	movzbl %al,%eax
801074b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801074b6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074bd:	e8 76 fe ff ff       	call   80107338 <outb>
}
801074c2:	c9                   	leave  
801074c3:	c3                   	ret    

801074c4 <uartgetc>:

static int
uartgetc(void)
{
801074c4:	55                   	push   %ebp
801074c5:	89 e5                	mov    %esp,%ebp
801074c7:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801074ca:	a1 50 d6 10 80       	mov    0x8010d650,%eax
801074cf:	85 c0                	test   %eax,%eax
801074d1:	75 07                	jne    801074da <uartgetc+0x16>
    return -1;
801074d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074d8:	eb 2c                	jmp    80107506 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801074da:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074e1:	e8 35 fe ff ff       	call   8010731b <inb>
801074e6:	0f b6 c0             	movzbl %al,%eax
801074e9:	83 e0 01             	and    $0x1,%eax
801074ec:	85 c0                	test   %eax,%eax
801074ee:	75 07                	jne    801074f7 <uartgetc+0x33>
    return -1;
801074f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074f5:	eb 0f                	jmp    80107506 <uartgetc+0x42>
  return inb(COM1+0);
801074f7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074fe:	e8 18 fe ff ff       	call   8010731b <inb>
80107503:	0f b6 c0             	movzbl %al,%eax
}
80107506:	c9                   	leave  
80107507:	c3                   	ret    

80107508 <uartintr>:

void
uartintr(void)
{
80107508:	55                   	push   %ebp
80107509:	89 e5                	mov    %esp,%ebp
8010750b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010750e:	c7 04 24 c4 74 10 80 	movl   $0x801074c4,(%esp)
80107515:	e8 ae 92 ff ff       	call   801007c8 <consoleintr>
}
8010751a:	c9                   	leave  
8010751b:	c3                   	ret    

8010751c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010751c:	6a 00                	push   $0x0
  pushl $0
8010751e:	6a 00                	push   $0x0
  jmp alltraps
80107520:	e9 d8 f8 ff ff       	jmp    80106dfd <alltraps>

80107525 <vector1>:
.globl vector1
vector1:
  pushl $0
80107525:	6a 00                	push   $0x0
  pushl $1
80107527:	6a 01                	push   $0x1
  jmp alltraps
80107529:	e9 cf f8 ff ff       	jmp    80106dfd <alltraps>

8010752e <vector2>:
.globl vector2
vector2:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $2
80107530:	6a 02                	push   $0x2
  jmp alltraps
80107532:	e9 c6 f8 ff ff       	jmp    80106dfd <alltraps>

80107537 <vector3>:
.globl vector3
vector3:
  pushl $0
80107537:	6a 00                	push   $0x0
  pushl $3
80107539:	6a 03                	push   $0x3
  jmp alltraps
8010753b:	e9 bd f8 ff ff       	jmp    80106dfd <alltraps>

80107540 <vector4>:
.globl vector4
vector4:
  pushl $0
80107540:	6a 00                	push   $0x0
  pushl $4
80107542:	6a 04                	push   $0x4
  jmp alltraps
80107544:	e9 b4 f8 ff ff       	jmp    80106dfd <alltraps>

80107549 <vector5>:
.globl vector5
vector5:
  pushl $0
80107549:	6a 00                	push   $0x0
  pushl $5
8010754b:	6a 05                	push   $0x5
  jmp alltraps
8010754d:	e9 ab f8 ff ff       	jmp    80106dfd <alltraps>

80107552 <vector6>:
.globl vector6
vector6:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $6
80107554:	6a 06                	push   $0x6
  jmp alltraps
80107556:	e9 a2 f8 ff ff       	jmp    80106dfd <alltraps>

8010755b <vector7>:
.globl vector7
vector7:
  pushl $0
8010755b:	6a 00                	push   $0x0
  pushl $7
8010755d:	6a 07                	push   $0x7
  jmp alltraps
8010755f:	e9 99 f8 ff ff       	jmp    80106dfd <alltraps>

80107564 <vector8>:
.globl vector8
vector8:
  pushl $8
80107564:	6a 08                	push   $0x8
  jmp alltraps
80107566:	e9 92 f8 ff ff       	jmp    80106dfd <alltraps>

8010756b <vector9>:
.globl vector9
vector9:
  pushl $0
8010756b:	6a 00                	push   $0x0
  pushl $9
8010756d:	6a 09                	push   $0x9
  jmp alltraps
8010756f:	e9 89 f8 ff ff       	jmp    80106dfd <alltraps>

80107574 <vector10>:
.globl vector10
vector10:
  pushl $10
80107574:	6a 0a                	push   $0xa
  jmp alltraps
80107576:	e9 82 f8 ff ff       	jmp    80106dfd <alltraps>

8010757b <vector11>:
.globl vector11
vector11:
  pushl $11
8010757b:	6a 0b                	push   $0xb
  jmp alltraps
8010757d:	e9 7b f8 ff ff       	jmp    80106dfd <alltraps>

80107582 <vector12>:
.globl vector12
vector12:
  pushl $12
80107582:	6a 0c                	push   $0xc
  jmp alltraps
80107584:	e9 74 f8 ff ff       	jmp    80106dfd <alltraps>

80107589 <vector13>:
.globl vector13
vector13:
  pushl $13
80107589:	6a 0d                	push   $0xd
  jmp alltraps
8010758b:	e9 6d f8 ff ff       	jmp    80106dfd <alltraps>

80107590 <vector14>:
.globl vector14
vector14:
  pushl $14
80107590:	6a 0e                	push   $0xe
  jmp alltraps
80107592:	e9 66 f8 ff ff       	jmp    80106dfd <alltraps>

80107597 <vector15>:
.globl vector15
vector15:
  pushl $0
80107597:	6a 00                	push   $0x0
  pushl $15
80107599:	6a 0f                	push   $0xf
  jmp alltraps
8010759b:	e9 5d f8 ff ff       	jmp    80106dfd <alltraps>

801075a0 <vector16>:
.globl vector16
vector16:
  pushl $0
801075a0:	6a 00                	push   $0x0
  pushl $16
801075a2:	6a 10                	push   $0x10
  jmp alltraps
801075a4:	e9 54 f8 ff ff       	jmp    80106dfd <alltraps>

801075a9 <vector17>:
.globl vector17
vector17:
  pushl $17
801075a9:	6a 11                	push   $0x11
  jmp alltraps
801075ab:	e9 4d f8 ff ff       	jmp    80106dfd <alltraps>

801075b0 <vector18>:
.globl vector18
vector18:
  pushl $0
801075b0:	6a 00                	push   $0x0
  pushl $18
801075b2:	6a 12                	push   $0x12
  jmp alltraps
801075b4:	e9 44 f8 ff ff       	jmp    80106dfd <alltraps>

801075b9 <vector19>:
.globl vector19
vector19:
  pushl $0
801075b9:	6a 00                	push   $0x0
  pushl $19
801075bb:	6a 13                	push   $0x13
  jmp alltraps
801075bd:	e9 3b f8 ff ff       	jmp    80106dfd <alltraps>

801075c2 <vector20>:
.globl vector20
vector20:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $20
801075c4:	6a 14                	push   $0x14
  jmp alltraps
801075c6:	e9 32 f8 ff ff       	jmp    80106dfd <alltraps>

801075cb <vector21>:
.globl vector21
vector21:
  pushl $0
801075cb:	6a 00                	push   $0x0
  pushl $21
801075cd:	6a 15                	push   $0x15
  jmp alltraps
801075cf:	e9 29 f8 ff ff       	jmp    80106dfd <alltraps>

801075d4 <vector22>:
.globl vector22
vector22:
  pushl $0
801075d4:	6a 00                	push   $0x0
  pushl $22
801075d6:	6a 16                	push   $0x16
  jmp alltraps
801075d8:	e9 20 f8 ff ff       	jmp    80106dfd <alltraps>

801075dd <vector23>:
.globl vector23
vector23:
  pushl $0
801075dd:	6a 00                	push   $0x0
  pushl $23
801075df:	6a 17                	push   $0x17
  jmp alltraps
801075e1:	e9 17 f8 ff ff       	jmp    80106dfd <alltraps>

801075e6 <vector24>:
.globl vector24
vector24:
  pushl $0
801075e6:	6a 00                	push   $0x0
  pushl $24
801075e8:	6a 18                	push   $0x18
  jmp alltraps
801075ea:	e9 0e f8 ff ff       	jmp    80106dfd <alltraps>

801075ef <vector25>:
.globl vector25
vector25:
  pushl $0
801075ef:	6a 00                	push   $0x0
  pushl $25
801075f1:	6a 19                	push   $0x19
  jmp alltraps
801075f3:	e9 05 f8 ff ff       	jmp    80106dfd <alltraps>

801075f8 <vector26>:
.globl vector26
vector26:
  pushl $0
801075f8:	6a 00                	push   $0x0
  pushl $26
801075fa:	6a 1a                	push   $0x1a
  jmp alltraps
801075fc:	e9 fc f7 ff ff       	jmp    80106dfd <alltraps>

80107601 <vector27>:
.globl vector27
vector27:
  pushl $0
80107601:	6a 00                	push   $0x0
  pushl $27
80107603:	6a 1b                	push   $0x1b
  jmp alltraps
80107605:	e9 f3 f7 ff ff       	jmp    80106dfd <alltraps>

8010760a <vector28>:
.globl vector28
vector28:
  pushl $0
8010760a:	6a 00                	push   $0x0
  pushl $28
8010760c:	6a 1c                	push   $0x1c
  jmp alltraps
8010760e:	e9 ea f7 ff ff       	jmp    80106dfd <alltraps>

80107613 <vector29>:
.globl vector29
vector29:
  pushl $0
80107613:	6a 00                	push   $0x0
  pushl $29
80107615:	6a 1d                	push   $0x1d
  jmp alltraps
80107617:	e9 e1 f7 ff ff       	jmp    80106dfd <alltraps>

8010761c <vector30>:
.globl vector30
vector30:
  pushl $0
8010761c:	6a 00                	push   $0x0
  pushl $30
8010761e:	6a 1e                	push   $0x1e
  jmp alltraps
80107620:	e9 d8 f7 ff ff       	jmp    80106dfd <alltraps>

80107625 <vector31>:
.globl vector31
vector31:
  pushl $0
80107625:	6a 00                	push   $0x0
  pushl $31
80107627:	6a 1f                	push   $0x1f
  jmp alltraps
80107629:	e9 cf f7 ff ff       	jmp    80106dfd <alltraps>

8010762e <vector32>:
.globl vector32
vector32:
  pushl $0
8010762e:	6a 00                	push   $0x0
  pushl $32
80107630:	6a 20                	push   $0x20
  jmp alltraps
80107632:	e9 c6 f7 ff ff       	jmp    80106dfd <alltraps>

80107637 <vector33>:
.globl vector33
vector33:
  pushl $0
80107637:	6a 00                	push   $0x0
  pushl $33
80107639:	6a 21                	push   $0x21
  jmp alltraps
8010763b:	e9 bd f7 ff ff       	jmp    80106dfd <alltraps>

80107640 <vector34>:
.globl vector34
vector34:
  pushl $0
80107640:	6a 00                	push   $0x0
  pushl $34
80107642:	6a 22                	push   $0x22
  jmp alltraps
80107644:	e9 b4 f7 ff ff       	jmp    80106dfd <alltraps>

80107649 <vector35>:
.globl vector35
vector35:
  pushl $0
80107649:	6a 00                	push   $0x0
  pushl $35
8010764b:	6a 23                	push   $0x23
  jmp alltraps
8010764d:	e9 ab f7 ff ff       	jmp    80106dfd <alltraps>

80107652 <vector36>:
.globl vector36
vector36:
  pushl $0
80107652:	6a 00                	push   $0x0
  pushl $36
80107654:	6a 24                	push   $0x24
  jmp alltraps
80107656:	e9 a2 f7 ff ff       	jmp    80106dfd <alltraps>

8010765b <vector37>:
.globl vector37
vector37:
  pushl $0
8010765b:	6a 00                	push   $0x0
  pushl $37
8010765d:	6a 25                	push   $0x25
  jmp alltraps
8010765f:	e9 99 f7 ff ff       	jmp    80106dfd <alltraps>

80107664 <vector38>:
.globl vector38
vector38:
  pushl $0
80107664:	6a 00                	push   $0x0
  pushl $38
80107666:	6a 26                	push   $0x26
  jmp alltraps
80107668:	e9 90 f7 ff ff       	jmp    80106dfd <alltraps>

8010766d <vector39>:
.globl vector39
vector39:
  pushl $0
8010766d:	6a 00                	push   $0x0
  pushl $39
8010766f:	6a 27                	push   $0x27
  jmp alltraps
80107671:	e9 87 f7 ff ff       	jmp    80106dfd <alltraps>

80107676 <vector40>:
.globl vector40
vector40:
  pushl $0
80107676:	6a 00                	push   $0x0
  pushl $40
80107678:	6a 28                	push   $0x28
  jmp alltraps
8010767a:	e9 7e f7 ff ff       	jmp    80106dfd <alltraps>

8010767f <vector41>:
.globl vector41
vector41:
  pushl $0
8010767f:	6a 00                	push   $0x0
  pushl $41
80107681:	6a 29                	push   $0x29
  jmp alltraps
80107683:	e9 75 f7 ff ff       	jmp    80106dfd <alltraps>

80107688 <vector42>:
.globl vector42
vector42:
  pushl $0
80107688:	6a 00                	push   $0x0
  pushl $42
8010768a:	6a 2a                	push   $0x2a
  jmp alltraps
8010768c:	e9 6c f7 ff ff       	jmp    80106dfd <alltraps>

80107691 <vector43>:
.globl vector43
vector43:
  pushl $0
80107691:	6a 00                	push   $0x0
  pushl $43
80107693:	6a 2b                	push   $0x2b
  jmp alltraps
80107695:	e9 63 f7 ff ff       	jmp    80106dfd <alltraps>

8010769a <vector44>:
.globl vector44
vector44:
  pushl $0
8010769a:	6a 00                	push   $0x0
  pushl $44
8010769c:	6a 2c                	push   $0x2c
  jmp alltraps
8010769e:	e9 5a f7 ff ff       	jmp    80106dfd <alltraps>

801076a3 <vector45>:
.globl vector45
vector45:
  pushl $0
801076a3:	6a 00                	push   $0x0
  pushl $45
801076a5:	6a 2d                	push   $0x2d
  jmp alltraps
801076a7:	e9 51 f7 ff ff       	jmp    80106dfd <alltraps>

801076ac <vector46>:
.globl vector46
vector46:
  pushl $0
801076ac:	6a 00                	push   $0x0
  pushl $46
801076ae:	6a 2e                	push   $0x2e
  jmp alltraps
801076b0:	e9 48 f7 ff ff       	jmp    80106dfd <alltraps>

801076b5 <vector47>:
.globl vector47
vector47:
  pushl $0
801076b5:	6a 00                	push   $0x0
  pushl $47
801076b7:	6a 2f                	push   $0x2f
  jmp alltraps
801076b9:	e9 3f f7 ff ff       	jmp    80106dfd <alltraps>

801076be <vector48>:
.globl vector48
vector48:
  pushl $0
801076be:	6a 00                	push   $0x0
  pushl $48
801076c0:	6a 30                	push   $0x30
  jmp alltraps
801076c2:	e9 36 f7 ff ff       	jmp    80106dfd <alltraps>

801076c7 <vector49>:
.globl vector49
vector49:
  pushl $0
801076c7:	6a 00                	push   $0x0
  pushl $49
801076c9:	6a 31                	push   $0x31
  jmp alltraps
801076cb:	e9 2d f7 ff ff       	jmp    80106dfd <alltraps>

801076d0 <vector50>:
.globl vector50
vector50:
  pushl $0
801076d0:	6a 00                	push   $0x0
  pushl $50
801076d2:	6a 32                	push   $0x32
  jmp alltraps
801076d4:	e9 24 f7 ff ff       	jmp    80106dfd <alltraps>

801076d9 <vector51>:
.globl vector51
vector51:
  pushl $0
801076d9:	6a 00                	push   $0x0
  pushl $51
801076db:	6a 33                	push   $0x33
  jmp alltraps
801076dd:	e9 1b f7 ff ff       	jmp    80106dfd <alltraps>

801076e2 <vector52>:
.globl vector52
vector52:
  pushl $0
801076e2:	6a 00                	push   $0x0
  pushl $52
801076e4:	6a 34                	push   $0x34
  jmp alltraps
801076e6:	e9 12 f7 ff ff       	jmp    80106dfd <alltraps>

801076eb <vector53>:
.globl vector53
vector53:
  pushl $0
801076eb:	6a 00                	push   $0x0
  pushl $53
801076ed:	6a 35                	push   $0x35
  jmp alltraps
801076ef:	e9 09 f7 ff ff       	jmp    80106dfd <alltraps>

801076f4 <vector54>:
.globl vector54
vector54:
  pushl $0
801076f4:	6a 00                	push   $0x0
  pushl $54
801076f6:	6a 36                	push   $0x36
  jmp alltraps
801076f8:	e9 00 f7 ff ff       	jmp    80106dfd <alltraps>

801076fd <vector55>:
.globl vector55
vector55:
  pushl $0
801076fd:	6a 00                	push   $0x0
  pushl $55
801076ff:	6a 37                	push   $0x37
  jmp alltraps
80107701:	e9 f7 f6 ff ff       	jmp    80106dfd <alltraps>

80107706 <vector56>:
.globl vector56
vector56:
  pushl $0
80107706:	6a 00                	push   $0x0
  pushl $56
80107708:	6a 38                	push   $0x38
  jmp alltraps
8010770a:	e9 ee f6 ff ff       	jmp    80106dfd <alltraps>

8010770f <vector57>:
.globl vector57
vector57:
  pushl $0
8010770f:	6a 00                	push   $0x0
  pushl $57
80107711:	6a 39                	push   $0x39
  jmp alltraps
80107713:	e9 e5 f6 ff ff       	jmp    80106dfd <alltraps>

80107718 <vector58>:
.globl vector58
vector58:
  pushl $0
80107718:	6a 00                	push   $0x0
  pushl $58
8010771a:	6a 3a                	push   $0x3a
  jmp alltraps
8010771c:	e9 dc f6 ff ff       	jmp    80106dfd <alltraps>

80107721 <vector59>:
.globl vector59
vector59:
  pushl $0
80107721:	6a 00                	push   $0x0
  pushl $59
80107723:	6a 3b                	push   $0x3b
  jmp alltraps
80107725:	e9 d3 f6 ff ff       	jmp    80106dfd <alltraps>

8010772a <vector60>:
.globl vector60
vector60:
  pushl $0
8010772a:	6a 00                	push   $0x0
  pushl $60
8010772c:	6a 3c                	push   $0x3c
  jmp alltraps
8010772e:	e9 ca f6 ff ff       	jmp    80106dfd <alltraps>

80107733 <vector61>:
.globl vector61
vector61:
  pushl $0
80107733:	6a 00                	push   $0x0
  pushl $61
80107735:	6a 3d                	push   $0x3d
  jmp alltraps
80107737:	e9 c1 f6 ff ff       	jmp    80106dfd <alltraps>

8010773c <vector62>:
.globl vector62
vector62:
  pushl $0
8010773c:	6a 00                	push   $0x0
  pushl $62
8010773e:	6a 3e                	push   $0x3e
  jmp alltraps
80107740:	e9 b8 f6 ff ff       	jmp    80106dfd <alltraps>

80107745 <vector63>:
.globl vector63
vector63:
  pushl $0
80107745:	6a 00                	push   $0x0
  pushl $63
80107747:	6a 3f                	push   $0x3f
  jmp alltraps
80107749:	e9 af f6 ff ff       	jmp    80106dfd <alltraps>

8010774e <vector64>:
.globl vector64
vector64:
  pushl $0
8010774e:	6a 00                	push   $0x0
  pushl $64
80107750:	6a 40                	push   $0x40
  jmp alltraps
80107752:	e9 a6 f6 ff ff       	jmp    80106dfd <alltraps>

80107757 <vector65>:
.globl vector65
vector65:
  pushl $0
80107757:	6a 00                	push   $0x0
  pushl $65
80107759:	6a 41                	push   $0x41
  jmp alltraps
8010775b:	e9 9d f6 ff ff       	jmp    80106dfd <alltraps>

80107760 <vector66>:
.globl vector66
vector66:
  pushl $0
80107760:	6a 00                	push   $0x0
  pushl $66
80107762:	6a 42                	push   $0x42
  jmp alltraps
80107764:	e9 94 f6 ff ff       	jmp    80106dfd <alltraps>

80107769 <vector67>:
.globl vector67
vector67:
  pushl $0
80107769:	6a 00                	push   $0x0
  pushl $67
8010776b:	6a 43                	push   $0x43
  jmp alltraps
8010776d:	e9 8b f6 ff ff       	jmp    80106dfd <alltraps>

80107772 <vector68>:
.globl vector68
vector68:
  pushl $0
80107772:	6a 00                	push   $0x0
  pushl $68
80107774:	6a 44                	push   $0x44
  jmp alltraps
80107776:	e9 82 f6 ff ff       	jmp    80106dfd <alltraps>

8010777b <vector69>:
.globl vector69
vector69:
  pushl $0
8010777b:	6a 00                	push   $0x0
  pushl $69
8010777d:	6a 45                	push   $0x45
  jmp alltraps
8010777f:	e9 79 f6 ff ff       	jmp    80106dfd <alltraps>

80107784 <vector70>:
.globl vector70
vector70:
  pushl $0
80107784:	6a 00                	push   $0x0
  pushl $70
80107786:	6a 46                	push   $0x46
  jmp alltraps
80107788:	e9 70 f6 ff ff       	jmp    80106dfd <alltraps>

8010778d <vector71>:
.globl vector71
vector71:
  pushl $0
8010778d:	6a 00                	push   $0x0
  pushl $71
8010778f:	6a 47                	push   $0x47
  jmp alltraps
80107791:	e9 67 f6 ff ff       	jmp    80106dfd <alltraps>

80107796 <vector72>:
.globl vector72
vector72:
  pushl $0
80107796:	6a 00                	push   $0x0
  pushl $72
80107798:	6a 48                	push   $0x48
  jmp alltraps
8010779a:	e9 5e f6 ff ff       	jmp    80106dfd <alltraps>

8010779f <vector73>:
.globl vector73
vector73:
  pushl $0
8010779f:	6a 00                	push   $0x0
  pushl $73
801077a1:	6a 49                	push   $0x49
  jmp alltraps
801077a3:	e9 55 f6 ff ff       	jmp    80106dfd <alltraps>

801077a8 <vector74>:
.globl vector74
vector74:
  pushl $0
801077a8:	6a 00                	push   $0x0
  pushl $74
801077aa:	6a 4a                	push   $0x4a
  jmp alltraps
801077ac:	e9 4c f6 ff ff       	jmp    80106dfd <alltraps>

801077b1 <vector75>:
.globl vector75
vector75:
  pushl $0
801077b1:	6a 00                	push   $0x0
  pushl $75
801077b3:	6a 4b                	push   $0x4b
  jmp alltraps
801077b5:	e9 43 f6 ff ff       	jmp    80106dfd <alltraps>

801077ba <vector76>:
.globl vector76
vector76:
  pushl $0
801077ba:	6a 00                	push   $0x0
  pushl $76
801077bc:	6a 4c                	push   $0x4c
  jmp alltraps
801077be:	e9 3a f6 ff ff       	jmp    80106dfd <alltraps>

801077c3 <vector77>:
.globl vector77
vector77:
  pushl $0
801077c3:	6a 00                	push   $0x0
  pushl $77
801077c5:	6a 4d                	push   $0x4d
  jmp alltraps
801077c7:	e9 31 f6 ff ff       	jmp    80106dfd <alltraps>

801077cc <vector78>:
.globl vector78
vector78:
  pushl $0
801077cc:	6a 00                	push   $0x0
  pushl $78
801077ce:	6a 4e                	push   $0x4e
  jmp alltraps
801077d0:	e9 28 f6 ff ff       	jmp    80106dfd <alltraps>

801077d5 <vector79>:
.globl vector79
vector79:
  pushl $0
801077d5:	6a 00                	push   $0x0
  pushl $79
801077d7:	6a 4f                	push   $0x4f
  jmp alltraps
801077d9:	e9 1f f6 ff ff       	jmp    80106dfd <alltraps>

801077de <vector80>:
.globl vector80
vector80:
  pushl $0
801077de:	6a 00                	push   $0x0
  pushl $80
801077e0:	6a 50                	push   $0x50
  jmp alltraps
801077e2:	e9 16 f6 ff ff       	jmp    80106dfd <alltraps>

801077e7 <vector81>:
.globl vector81
vector81:
  pushl $0
801077e7:	6a 00                	push   $0x0
  pushl $81
801077e9:	6a 51                	push   $0x51
  jmp alltraps
801077eb:	e9 0d f6 ff ff       	jmp    80106dfd <alltraps>

801077f0 <vector82>:
.globl vector82
vector82:
  pushl $0
801077f0:	6a 00                	push   $0x0
  pushl $82
801077f2:	6a 52                	push   $0x52
  jmp alltraps
801077f4:	e9 04 f6 ff ff       	jmp    80106dfd <alltraps>

801077f9 <vector83>:
.globl vector83
vector83:
  pushl $0
801077f9:	6a 00                	push   $0x0
  pushl $83
801077fb:	6a 53                	push   $0x53
  jmp alltraps
801077fd:	e9 fb f5 ff ff       	jmp    80106dfd <alltraps>

80107802 <vector84>:
.globl vector84
vector84:
  pushl $0
80107802:	6a 00                	push   $0x0
  pushl $84
80107804:	6a 54                	push   $0x54
  jmp alltraps
80107806:	e9 f2 f5 ff ff       	jmp    80106dfd <alltraps>

8010780b <vector85>:
.globl vector85
vector85:
  pushl $0
8010780b:	6a 00                	push   $0x0
  pushl $85
8010780d:	6a 55                	push   $0x55
  jmp alltraps
8010780f:	e9 e9 f5 ff ff       	jmp    80106dfd <alltraps>

80107814 <vector86>:
.globl vector86
vector86:
  pushl $0
80107814:	6a 00                	push   $0x0
  pushl $86
80107816:	6a 56                	push   $0x56
  jmp alltraps
80107818:	e9 e0 f5 ff ff       	jmp    80106dfd <alltraps>

8010781d <vector87>:
.globl vector87
vector87:
  pushl $0
8010781d:	6a 00                	push   $0x0
  pushl $87
8010781f:	6a 57                	push   $0x57
  jmp alltraps
80107821:	e9 d7 f5 ff ff       	jmp    80106dfd <alltraps>

80107826 <vector88>:
.globl vector88
vector88:
  pushl $0
80107826:	6a 00                	push   $0x0
  pushl $88
80107828:	6a 58                	push   $0x58
  jmp alltraps
8010782a:	e9 ce f5 ff ff       	jmp    80106dfd <alltraps>

8010782f <vector89>:
.globl vector89
vector89:
  pushl $0
8010782f:	6a 00                	push   $0x0
  pushl $89
80107831:	6a 59                	push   $0x59
  jmp alltraps
80107833:	e9 c5 f5 ff ff       	jmp    80106dfd <alltraps>

80107838 <vector90>:
.globl vector90
vector90:
  pushl $0
80107838:	6a 00                	push   $0x0
  pushl $90
8010783a:	6a 5a                	push   $0x5a
  jmp alltraps
8010783c:	e9 bc f5 ff ff       	jmp    80106dfd <alltraps>

80107841 <vector91>:
.globl vector91
vector91:
  pushl $0
80107841:	6a 00                	push   $0x0
  pushl $91
80107843:	6a 5b                	push   $0x5b
  jmp alltraps
80107845:	e9 b3 f5 ff ff       	jmp    80106dfd <alltraps>

8010784a <vector92>:
.globl vector92
vector92:
  pushl $0
8010784a:	6a 00                	push   $0x0
  pushl $92
8010784c:	6a 5c                	push   $0x5c
  jmp alltraps
8010784e:	e9 aa f5 ff ff       	jmp    80106dfd <alltraps>

80107853 <vector93>:
.globl vector93
vector93:
  pushl $0
80107853:	6a 00                	push   $0x0
  pushl $93
80107855:	6a 5d                	push   $0x5d
  jmp alltraps
80107857:	e9 a1 f5 ff ff       	jmp    80106dfd <alltraps>

8010785c <vector94>:
.globl vector94
vector94:
  pushl $0
8010785c:	6a 00                	push   $0x0
  pushl $94
8010785e:	6a 5e                	push   $0x5e
  jmp alltraps
80107860:	e9 98 f5 ff ff       	jmp    80106dfd <alltraps>

80107865 <vector95>:
.globl vector95
vector95:
  pushl $0
80107865:	6a 00                	push   $0x0
  pushl $95
80107867:	6a 5f                	push   $0x5f
  jmp alltraps
80107869:	e9 8f f5 ff ff       	jmp    80106dfd <alltraps>

8010786e <vector96>:
.globl vector96
vector96:
  pushl $0
8010786e:	6a 00                	push   $0x0
  pushl $96
80107870:	6a 60                	push   $0x60
  jmp alltraps
80107872:	e9 86 f5 ff ff       	jmp    80106dfd <alltraps>

80107877 <vector97>:
.globl vector97
vector97:
  pushl $0
80107877:	6a 00                	push   $0x0
  pushl $97
80107879:	6a 61                	push   $0x61
  jmp alltraps
8010787b:	e9 7d f5 ff ff       	jmp    80106dfd <alltraps>

80107880 <vector98>:
.globl vector98
vector98:
  pushl $0
80107880:	6a 00                	push   $0x0
  pushl $98
80107882:	6a 62                	push   $0x62
  jmp alltraps
80107884:	e9 74 f5 ff ff       	jmp    80106dfd <alltraps>

80107889 <vector99>:
.globl vector99
vector99:
  pushl $0
80107889:	6a 00                	push   $0x0
  pushl $99
8010788b:	6a 63                	push   $0x63
  jmp alltraps
8010788d:	e9 6b f5 ff ff       	jmp    80106dfd <alltraps>

80107892 <vector100>:
.globl vector100
vector100:
  pushl $0
80107892:	6a 00                	push   $0x0
  pushl $100
80107894:	6a 64                	push   $0x64
  jmp alltraps
80107896:	e9 62 f5 ff ff       	jmp    80106dfd <alltraps>

8010789b <vector101>:
.globl vector101
vector101:
  pushl $0
8010789b:	6a 00                	push   $0x0
  pushl $101
8010789d:	6a 65                	push   $0x65
  jmp alltraps
8010789f:	e9 59 f5 ff ff       	jmp    80106dfd <alltraps>

801078a4 <vector102>:
.globl vector102
vector102:
  pushl $0
801078a4:	6a 00                	push   $0x0
  pushl $102
801078a6:	6a 66                	push   $0x66
  jmp alltraps
801078a8:	e9 50 f5 ff ff       	jmp    80106dfd <alltraps>

801078ad <vector103>:
.globl vector103
vector103:
  pushl $0
801078ad:	6a 00                	push   $0x0
  pushl $103
801078af:	6a 67                	push   $0x67
  jmp alltraps
801078b1:	e9 47 f5 ff ff       	jmp    80106dfd <alltraps>

801078b6 <vector104>:
.globl vector104
vector104:
  pushl $0
801078b6:	6a 00                	push   $0x0
  pushl $104
801078b8:	6a 68                	push   $0x68
  jmp alltraps
801078ba:	e9 3e f5 ff ff       	jmp    80106dfd <alltraps>

801078bf <vector105>:
.globl vector105
vector105:
  pushl $0
801078bf:	6a 00                	push   $0x0
  pushl $105
801078c1:	6a 69                	push   $0x69
  jmp alltraps
801078c3:	e9 35 f5 ff ff       	jmp    80106dfd <alltraps>

801078c8 <vector106>:
.globl vector106
vector106:
  pushl $0
801078c8:	6a 00                	push   $0x0
  pushl $106
801078ca:	6a 6a                	push   $0x6a
  jmp alltraps
801078cc:	e9 2c f5 ff ff       	jmp    80106dfd <alltraps>

801078d1 <vector107>:
.globl vector107
vector107:
  pushl $0
801078d1:	6a 00                	push   $0x0
  pushl $107
801078d3:	6a 6b                	push   $0x6b
  jmp alltraps
801078d5:	e9 23 f5 ff ff       	jmp    80106dfd <alltraps>

801078da <vector108>:
.globl vector108
vector108:
  pushl $0
801078da:	6a 00                	push   $0x0
  pushl $108
801078dc:	6a 6c                	push   $0x6c
  jmp alltraps
801078de:	e9 1a f5 ff ff       	jmp    80106dfd <alltraps>

801078e3 <vector109>:
.globl vector109
vector109:
  pushl $0
801078e3:	6a 00                	push   $0x0
  pushl $109
801078e5:	6a 6d                	push   $0x6d
  jmp alltraps
801078e7:	e9 11 f5 ff ff       	jmp    80106dfd <alltraps>

801078ec <vector110>:
.globl vector110
vector110:
  pushl $0
801078ec:	6a 00                	push   $0x0
  pushl $110
801078ee:	6a 6e                	push   $0x6e
  jmp alltraps
801078f0:	e9 08 f5 ff ff       	jmp    80106dfd <alltraps>

801078f5 <vector111>:
.globl vector111
vector111:
  pushl $0
801078f5:	6a 00                	push   $0x0
  pushl $111
801078f7:	6a 6f                	push   $0x6f
  jmp alltraps
801078f9:	e9 ff f4 ff ff       	jmp    80106dfd <alltraps>

801078fe <vector112>:
.globl vector112
vector112:
  pushl $0
801078fe:	6a 00                	push   $0x0
  pushl $112
80107900:	6a 70                	push   $0x70
  jmp alltraps
80107902:	e9 f6 f4 ff ff       	jmp    80106dfd <alltraps>

80107907 <vector113>:
.globl vector113
vector113:
  pushl $0
80107907:	6a 00                	push   $0x0
  pushl $113
80107909:	6a 71                	push   $0x71
  jmp alltraps
8010790b:	e9 ed f4 ff ff       	jmp    80106dfd <alltraps>

80107910 <vector114>:
.globl vector114
vector114:
  pushl $0
80107910:	6a 00                	push   $0x0
  pushl $114
80107912:	6a 72                	push   $0x72
  jmp alltraps
80107914:	e9 e4 f4 ff ff       	jmp    80106dfd <alltraps>

80107919 <vector115>:
.globl vector115
vector115:
  pushl $0
80107919:	6a 00                	push   $0x0
  pushl $115
8010791b:	6a 73                	push   $0x73
  jmp alltraps
8010791d:	e9 db f4 ff ff       	jmp    80106dfd <alltraps>

80107922 <vector116>:
.globl vector116
vector116:
  pushl $0
80107922:	6a 00                	push   $0x0
  pushl $116
80107924:	6a 74                	push   $0x74
  jmp alltraps
80107926:	e9 d2 f4 ff ff       	jmp    80106dfd <alltraps>

8010792b <vector117>:
.globl vector117
vector117:
  pushl $0
8010792b:	6a 00                	push   $0x0
  pushl $117
8010792d:	6a 75                	push   $0x75
  jmp alltraps
8010792f:	e9 c9 f4 ff ff       	jmp    80106dfd <alltraps>

80107934 <vector118>:
.globl vector118
vector118:
  pushl $0
80107934:	6a 00                	push   $0x0
  pushl $118
80107936:	6a 76                	push   $0x76
  jmp alltraps
80107938:	e9 c0 f4 ff ff       	jmp    80106dfd <alltraps>

8010793d <vector119>:
.globl vector119
vector119:
  pushl $0
8010793d:	6a 00                	push   $0x0
  pushl $119
8010793f:	6a 77                	push   $0x77
  jmp alltraps
80107941:	e9 b7 f4 ff ff       	jmp    80106dfd <alltraps>

80107946 <vector120>:
.globl vector120
vector120:
  pushl $0
80107946:	6a 00                	push   $0x0
  pushl $120
80107948:	6a 78                	push   $0x78
  jmp alltraps
8010794a:	e9 ae f4 ff ff       	jmp    80106dfd <alltraps>

8010794f <vector121>:
.globl vector121
vector121:
  pushl $0
8010794f:	6a 00                	push   $0x0
  pushl $121
80107951:	6a 79                	push   $0x79
  jmp alltraps
80107953:	e9 a5 f4 ff ff       	jmp    80106dfd <alltraps>

80107958 <vector122>:
.globl vector122
vector122:
  pushl $0
80107958:	6a 00                	push   $0x0
  pushl $122
8010795a:	6a 7a                	push   $0x7a
  jmp alltraps
8010795c:	e9 9c f4 ff ff       	jmp    80106dfd <alltraps>

80107961 <vector123>:
.globl vector123
vector123:
  pushl $0
80107961:	6a 00                	push   $0x0
  pushl $123
80107963:	6a 7b                	push   $0x7b
  jmp alltraps
80107965:	e9 93 f4 ff ff       	jmp    80106dfd <alltraps>

8010796a <vector124>:
.globl vector124
vector124:
  pushl $0
8010796a:	6a 00                	push   $0x0
  pushl $124
8010796c:	6a 7c                	push   $0x7c
  jmp alltraps
8010796e:	e9 8a f4 ff ff       	jmp    80106dfd <alltraps>

80107973 <vector125>:
.globl vector125
vector125:
  pushl $0
80107973:	6a 00                	push   $0x0
  pushl $125
80107975:	6a 7d                	push   $0x7d
  jmp alltraps
80107977:	e9 81 f4 ff ff       	jmp    80106dfd <alltraps>

8010797c <vector126>:
.globl vector126
vector126:
  pushl $0
8010797c:	6a 00                	push   $0x0
  pushl $126
8010797e:	6a 7e                	push   $0x7e
  jmp alltraps
80107980:	e9 78 f4 ff ff       	jmp    80106dfd <alltraps>

80107985 <vector127>:
.globl vector127
vector127:
  pushl $0
80107985:	6a 00                	push   $0x0
  pushl $127
80107987:	6a 7f                	push   $0x7f
  jmp alltraps
80107989:	e9 6f f4 ff ff       	jmp    80106dfd <alltraps>

8010798e <vector128>:
.globl vector128
vector128:
  pushl $0
8010798e:	6a 00                	push   $0x0
  pushl $128
80107990:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107995:	e9 63 f4 ff ff       	jmp    80106dfd <alltraps>

8010799a <vector129>:
.globl vector129
vector129:
  pushl $0
8010799a:	6a 00                	push   $0x0
  pushl $129
8010799c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801079a1:	e9 57 f4 ff ff       	jmp    80106dfd <alltraps>

801079a6 <vector130>:
.globl vector130
vector130:
  pushl $0
801079a6:	6a 00                	push   $0x0
  pushl $130
801079a8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801079ad:	e9 4b f4 ff ff       	jmp    80106dfd <alltraps>

801079b2 <vector131>:
.globl vector131
vector131:
  pushl $0
801079b2:	6a 00                	push   $0x0
  pushl $131
801079b4:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801079b9:	e9 3f f4 ff ff       	jmp    80106dfd <alltraps>

801079be <vector132>:
.globl vector132
vector132:
  pushl $0
801079be:	6a 00                	push   $0x0
  pushl $132
801079c0:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801079c5:	e9 33 f4 ff ff       	jmp    80106dfd <alltraps>

801079ca <vector133>:
.globl vector133
vector133:
  pushl $0
801079ca:	6a 00                	push   $0x0
  pushl $133
801079cc:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801079d1:	e9 27 f4 ff ff       	jmp    80106dfd <alltraps>

801079d6 <vector134>:
.globl vector134
vector134:
  pushl $0
801079d6:	6a 00                	push   $0x0
  pushl $134
801079d8:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801079dd:	e9 1b f4 ff ff       	jmp    80106dfd <alltraps>

801079e2 <vector135>:
.globl vector135
vector135:
  pushl $0
801079e2:	6a 00                	push   $0x0
  pushl $135
801079e4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079e9:	e9 0f f4 ff ff       	jmp    80106dfd <alltraps>

801079ee <vector136>:
.globl vector136
vector136:
  pushl $0
801079ee:	6a 00                	push   $0x0
  pushl $136
801079f0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801079f5:	e9 03 f4 ff ff       	jmp    80106dfd <alltraps>

801079fa <vector137>:
.globl vector137
vector137:
  pushl $0
801079fa:	6a 00                	push   $0x0
  pushl $137
801079fc:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107a01:	e9 f7 f3 ff ff       	jmp    80106dfd <alltraps>

80107a06 <vector138>:
.globl vector138
vector138:
  pushl $0
80107a06:	6a 00                	push   $0x0
  pushl $138
80107a08:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107a0d:	e9 eb f3 ff ff       	jmp    80106dfd <alltraps>

80107a12 <vector139>:
.globl vector139
vector139:
  pushl $0
80107a12:	6a 00                	push   $0x0
  pushl $139
80107a14:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107a19:	e9 df f3 ff ff       	jmp    80106dfd <alltraps>

80107a1e <vector140>:
.globl vector140
vector140:
  pushl $0
80107a1e:	6a 00                	push   $0x0
  pushl $140
80107a20:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107a25:	e9 d3 f3 ff ff       	jmp    80106dfd <alltraps>

80107a2a <vector141>:
.globl vector141
vector141:
  pushl $0
80107a2a:	6a 00                	push   $0x0
  pushl $141
80107a2c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107a31:	e9 c7 f3 ff ff       	jmp    80106dfd <alltraps>

80107a36 <vector142>:
.globl vector142
vector142:
  pushl $0
80107a36:	6a 00                	push   $0x0
  pushl $142
80107a38:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107a3d:	e9 bb f3 ff ff       	jmp    80106dfd <alltraps>

80107a42 <vector143>:
.globl vector143
vector143:
  pushl $0
80107a42:	6a 00                	push   $0x0
  pushl $143
80107a44:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a49:	e9 af f3 ff ff       	jmp    80106dfd <alltraps>

80107a4e <vector144>:
.globl vector144
vector144:
  pushl $0
80107a4e:	6a 00                	push   $0x0
  pushl $144
80107a50:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a55:	e9 a3 f3 ff ff       	jmp    80106dfd <alltraps>

80107a5a <vector145>:
.globl vector145
vector145:
  pushl $0
80107a5a:	6a 00                	push   $0x0
  pushl $145
80107a5c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a61:	e9 97 f3 ff ff       	jmp    80106dfd <alltraps>

80107a66 <vector146>:
.globl vector146
vector146:
  pushl $0
80107a66:	6a 00                	push   $0x0
  pushl $146
80107a68:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a6d:	e9 8b f3 ff ff       	jmp    80106dfd <alltraps>

80107a72 <vector147>:
.globl vector147
vector147:
  pushl $0
80107a72:	6a 00                	push   $0x0
  pushl $147
80107a74:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a79:	e9 7f f3 ff ff       	jmp    80106dfd <alltraps>

80107a7e <vector148>:
.globl vector148
vector148:
  pushl $0
80107a7e:	6a 00                	push   $0x0
  pushl $148
80107a80:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a85:	e9 73 f3 ff ff       	jmp    80106dfd <alltraps>

80107a8a <vector149>:
.globl vector149
vector149:
  pushl $0
80107a8a:	6a 00                	push   $0x0
  pushl $149
80107a8c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107a91:	e9 67 f3 ff ff       	jmp    80106dfd <alltraps>

80107a96 <vector150>:
.globl vector150
vector150:
  pushl $0
80107a96:	6a 00                	push   $0x0
  pushl $150
80107a98:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107a9d:	e9 5b f3 ff ff       	jmp    80106dfd <alltraps>

80107aa2 <vector151>:
.globl vector151
vector151:
  pushl $0
80107aa2:	6a 00                	push   $0x0
  pushl $151
80107aa4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107aa9:	e9 4f f3 ff ff       	jmp    80106dfd <alltraps>

80107aae <vector152>:
.globl vector152
vector152:
  pushl $0
80107aae:	6a 00                	push   $0x0
  pushl $152
80107ab0:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107ab5:	e9 43 f3 ff ff       	jmp    80106dfd <alltraps>

80107aba <vector153>:
.globl vector153
vector153:
  pushl $0
80107aba:	6a 00                	push   $0x0
  pushl $153
80107abc:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107ac1:	e9 37 f3 ff ff       	jmp    80106dfd <alltraps>

80107ac6 <vector154>:
.globl vector154
vector154:
  pushl $0
80107ac6:	6a 00                	push   $0x0
  pushl $154
80107ac8:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107acd:	e9 2b f3 ff ff       	jmp    80106dfd <alltraps>

80107ad2 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ad2:	6a 00                	push   $0x0
  pushl $155
80107ad4:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ad9:	e9 1f f3 ff ff       	jmp    80106dfd <alltraps>

80107ade <vector156>:
.globl vector156
vector156:
  pushl $0
80107ade:	6a 00                	push   $0x0
  pushl $156
80107ae0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107ae5:	e9 13 f3 ff ff       	jmp    80106dfd <alltraps>

80107aea <vector157>:
.globl vector157
vector157:
  pushl $0
80107aea:	6a 00                	push   $0x0
  pushl $157
80107aec:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107af1:	e9 07 f3 ff ff       	jmp    80106dfd <alltraps>

80107af6 <vector158>:
.globl vector158
vector158:
  pushl $0
80107af6:	6a 00                	push   $0x0
  pushl $158
80107af8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107afd:	e9 fb f2 ff ff       	jmp    80106dfd <alltraps>

80107b02 <vector159>:
.globl vector159
vector159:
  pushl $0
80107b02:	6a 00                	push   $0x0
  pushl $159
80107b04:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107b09:	e9 ef f2 ff ff       	jmp    80106dfd <alltraps>

80107b0e <vector160>:
.globl vector160
vector160:
  pushl $0
80107b0e:	6a 00                	push   $0x0
  pushl $160
80107b10:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107b15:	e9 e3 f2 ff ff       	jmp    80106dfd <alltraps>

80107b1a <vector161>:
.globl vector161
vector161:
  pushl $0
80107b1a:	6a 00                	push   $0x0
  pushl $161
80107b1c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107b21:	e9 d7 f2 ff ff       	jmp    80106dfd <alltraps>

80107b26 <vector162>:
.globl vector162
vector162:
  pushl $0
80107b26:	6a 00                	push   $0x0
  pushl $162
80107b28:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107b2d:	e9 cb f2 ff ff       	jmp    80106dfd <alltraps>

80107b32 <vector163>:
.globl vector163
vector163:
  pushl $0
80107b32:	6a 00                	push   $0x0
  pushl $163
80107b34:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107b39:	e9 bf f2 ff ff       	jmp    80106dfd <alltraps>

80107b3e <vector164>:
.globl vector164
vector164:
  pushl $0
80107b3e:	6a 00                	push   $0x0
  pushl $164
80107b40:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107b45:	e9 b3 f2 ff ff       	jmp    80106dfd <alltraps>

80107b4a <vector165>:
.globl vector165
vector165:
  pushl $0
80107b4a:	6a 00                	push   $0x0
  pushl $165
80107b4c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b51:	e9 a7 f2 ff ff       	jmp    80106dfd <alltraps>

80107b56 <vector166>:
.globl vector166
vector166:
  pushl $0
80107b56:	6a 00                	push   $0x0
  pushl $166
80107b58:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b5d:	e9 9b f2 ff ff       	jmp    80106dfd <alltraps>

80107b62 <vector167>:
.globl vector167
vector167:
  pushl $0
80107b62:	6a 00                	push   $0x0
  pushl $167
80107b64:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b69:	e9 8f f2 ff ff       	jmp    80106dfd <alltraps>

80107b6e <vector168>:
.globl vector168
vector168:
  pushl $0
80107b6e:	6a 00                	push   $0x0
  pushl $168
80107b70:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b75:	e9 83 f2 ff ff       	jmp    80106dfd <alltraps>

80107b7a <vector169>:
.globl vector169
vector169:
  pushl $0
80107b7a:	6a 00                	push   $0x0
  pushl $169
80107b7c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b81:	e9 77 f2 ff ff       	jmp    80106dfd <alltraps>

80107b86 <vector170>:
.globl vector170
vector170:
  pushl $0
80107b86:	6a 00                	push   $0x0
  pushl $170
80107b88:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b8d:	e9 6b f2 ff ff       	jmp    80106dfd <alltraps>

80107b92 <vector171>:
.globl vector171
vector171:
  pushl $0
80107b92:	6a 00                	push   $0x0
  pushl $171
80107b94:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107b99:	e9 5f f2 ff ff       	jmp    80106dfd <alltraps>

80107b9e <vector172>:
.globl vector172
vector172:
  pushl $0
80107b9e:	6a 00                	push   $0x0
  pushl $172
80107ba0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107ba5:	e9 53 f2 ff ff       	jmp    80106dfd <alltraps>

80107baa <vector173>:
.globl vector173
vector173:
  pushl $0
80107baa:	6a 00                	push   $0x0
  pushl $173
80107bac:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107bb1:	e9 47 f2 ff ff       	jmp    80106dfd <alltraps>

80107bb6 <vector174>:
.globl vector174
vector174:
  pushl $0
80107bb6:	6a 00                	push   $0x0
  pushl $174
80107bb8:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107bbd:	e9 3b f2 ff ff       	jmp    80106dfd <alltraps>

80107bc2 <vector175>:
.globl vector175
vector175:
  pushl $0
80107bc2:	6a 00                	push   $0x0
  pushl $175
80107bc4:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107bc9:	e9 2f f2 ff ff       	jmp    80106dfd <alltraps>

80107bce <vector176>:
.globl vector176
vector176:
  pushl $0
80107bce:	6a 00                	push   $0x0
  pushl $176
80107bd0:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107bd5:	e9 23 f2 ff ff       	jmp    80106dfd <alltraps>

80107bda <vector177>:
.globl vector177
vector177:
  pushl $0
80107bda:	6a 00                	push   $0x0
  pushl $177
80107bdc:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107be1:	e9 17 f2 ff ff       	jmp    80106dfd <alltraps>

80107be6 <vector178>:
.globl vector178
vector178:
  pushl $0
80107be6:	6a 00                	push   $0x0
  pushl $178
80107be8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107bed:	e9 0b f2 ff ff       	jmp    80106dfd <alltraps>

80107bf2 <vector179>:
.globl vector179
vector179:
  pushl $0
80107bf2:	6a 00                	push   $0x0
  pushl $179
80107bf4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107bf9:	e9 ff f1 ff ff       	jmp    80106dfd <alltraps>

80107bfe <vector180>:
.globl vector180
vector180:
  pushl $0
80107bfe:	6a 00                	push   $0x0
  pushl $180
80107c00:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107c05:	e9 f3 f1 ff ff       	jmp    80106dfd <alltraps>

80107c0a <vector181>:
.globl vector181
vector181:
  pushl $0
80107c0a:	6a 00                	push   $0x0
  pushl $181
80107c0c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107c11:	e9 e7 f1 ff ff       	jmp    80106dfd <alltraps>

80107c16 <vector182>:
.globl vector182
vector182:
  pushl $0
80107c16:	6a 00                	push   $0x0
  pushl $182
80107c18:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107c1d:	e9 db f1 ff ff       	jmp    80106dfd <alltraps>

80107c22 <vector183>:
.globl vector183
vector183:
  pushl $0
80107c22:	6a 00                	push   $0x0
  pushl $183
80107c24:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107c29:	e9 cf f1 ff ff       	jmp    80106dfd <alltraps>

80107c2e <vector184>:
.globl vector184
vector184:
  pushl $0
80107c2e:	6a 00                	push   $0x0
  pushl $184
80107c30:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107c35:	e9 c3 f1 ff ff       	jmp    80106dfd <alltraps>

80107c3a <vector185>:
.globl vector185
vector185:
  pushl $0
80107c3a:	6a 00                	push   $0x0
  pushl $185
80107c3c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107c41:	e9 b7 f1 ff ff       	jmp    80106dfd <alltraps>

80107c46 <vector186>:
.globl vector186
vector186:
  pushl $0
80107c46:	6a 00                	push   $0x0
  pushl $186
80107c48:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c4d:	e9 ab f1 ff ff       	jmp    80106dfd <alltraps>

80107c52 <vector187>:
.globl vector187
vector187:
  pushl $0
80107c52:	6a 00                	push   $0x0
  pushl $187
80107c54:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c59:	e9 9f f1 ff ff       	jmp    80106dfd <alltraps>

80107c5e <vector188>:
.globl vector188
vector188:
  pushl $0
80107c5e:	6a 00                	push   $0x0
  pushl $188
80107c60:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c65:	e9 93 f1 ff ff       	jmp    80106dfd <alltraps>

80107c6a <vector189>:
.globl vector189
vector189:
  pushl $0
80107c6a:	6a 00                	push   $0x0
  pushl $189
80107c6c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c71:	e9 87 f1 ff ff       	jmp    80106dfd <alltraps>

80107c76 <vector190>:
.globl vector190
vector190:
  pushl $0
80107c76:	6a 00                	push   $0x0
  pushl $190
80107c78:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c7d:	e9 7b f1 ff ff       	jmp    80106dfd <alltraps>

80107c82 <vector191>:
.globl vector191
vector191:
  pushl $0
80107c82:	6a 00                	push   $0x0
  pushl $191
80107c84:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c89:	e9 6f f1 ff ff       	jmp    80106dfd <alltraps>

80107c8e <vector192>:
.globl vector192
vector192:
  pushl $0
80107c8e:	6a 00                	push   $0x0
  pushl $192
80107c90:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107c95:	e9 63 f1 ff ff       	jmp    80106dfd <alltraps>

80107c9a <vector193>:
.globl vector193
vector193:
  pushl $0
80107c9a:	6a 00                	push   $0x0
  pushl $193
80107c9c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107ca1:	e9 57 f1 ff ff       	jmp    80106dfd <alltraps>

80107ca6 <vector194>:
.globl vector194
vector194:
  pushl $0
80107ca6:	6a 00                	push   $0x0
  pushl $194
80107ca8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107cad:	e9 4b f1 ff ff       	jmp    80106dfd <alltraps>

80107cb2 <vector195>:
.globl vector195
vector195:
  pushl $0
80107cb2:	6a 00                	push   $0x0
  pushl $195
80107cb4:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107cb9:	e9 3f f1 ff ff       	jmp    80106dfd <alltraps>

80107cbe <vector196>:
.globl vector196
vector196:
  pushl $0
80107cbe:	6a 00                	push   $0x0
  pushl $196
80107cc0:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107cc5:	e9 33 f1 ff ff       	jmp    80106dfd <alltraps>

80107cca <vector197>:
.globl vector197
vector197:
  pushl $0
80107cca:	6a 00                	push   $0x0
  pushl $197
80107ccc:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107cd1:	e9 27 f1 ff ff       	jmp    80106dfd <alltraps>

80107cd6 <vector198>:
.globl vector198
vector198:
  pushl $0
80107cd6:	6a 00                	push   $0x0
  pushl $198
80107cd8:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107cdd:	e9 1b f1 ff ff       	jmp    80106dfd <alltraps>

80107ce2 <vector199>:
.globl vector199
vector199:
  pushl $0
80107ce2:	6a 00                	push   $0x0
  pushl $199
80107ce4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107ce9:	e9 0f f1 ff ff       	jmp    80106dfd <alltraps>

80107cee <vector200>:
.globl vector200
vector200:
  pushl $0
80107cee:	6a 00                	push   $0x0
  pushl $200
80107cf0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107cf5:	e9 03 f1 ff ff       	jmp    80106dfd <alltraps>

80107cfa <vector201>:
.globl vector201
vector201:
  pushl $0
80107cfa:	6a 00                	push   $0x0
  pushl $201
80107cfc:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107d01:	e9 f7 f0 ff ff       	jmp    80106dfd <alltraps>

80107d06 <vector202>:
.globl vector202
vector202:
  pushl $0
80107d06:	6a 00                	push   $0x0
  pushl $202
80107d08:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107d0d:	e9 eb f0 ff ff       	jmp    80106dfd <alltraps>

80107d12 <vector203>:
.globl vector203
vector203:
  pushl $0
80107d12:	6a 00                	push   $0x0
  pushl $203
80107d14:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107d19:	e9 df f0 ff ff       	jmp    80106dfd <alltraps>

80107d1e <vector204>:
.globl vector204
vector204:
  pushl $0
80107d1e:	6a 00                	push   $0x0
  pushl $204
80107d20:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107d25:	e9 d3 f0 ff ff       	jmp    80106dfd <alltraps>

80107d2a <vector205>:
.globl vector205
vector205:
  pushl $0
80107d2a:	6a 00                	push   $0x0
  pushl $205
80107d2c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107d31:	e9 c7 f0 ff ff       	jmp    80106dfd <alltraps>

80107d36 <vector206>:
.globl vector206
vector206:
  pushl $0
80107d36:	6a 00                	push   $0x0
  pushl $206
80107d38:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107d3d:	e9 bb f0 ff ff       	jmp    80106dfd <alltraps>

80107d42 <vector207>:
.globl vector207
vector207:
  pushl $0
80107d42:	6a 00                	push   $0x0
  pushl $207
80107d44:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d49:	e9 af f0 ff ff       	jmp    80106dfd <alltraps>

80107d4e <vector208>:
.globl vector208
vector208:
  pushl $0
80107d4e:	6a 00                	push   $0x0
  pushl $208
80107d50:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d55:	e9 a3 f0 ff ff       	jmp    80106dfd <alltraps>

80107d5a <vector209>:
.globl vector209
vector209:
  pushl $0
80107d5a:	6a 00                	push   $0x0
  pushl $209
80107d5c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d61:	e9 97 f0 ff ff       	jmp    80106dfd <alltraps>

80107d66 <vector210>:
.globl vector210
vector210:
  pushl $0
80107d66:	6a 00                	push   $0x0
  pushl $210
80107d68:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d6d:	e9 8b f0 ff ff       	jmp    80106dfd <alltraps>

80107d72 <vector211>:
.globl vector211
vector211:
  pushl $0
80107d72:	6a 00                	push   $0x0
  pushl $211
80107d74:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d79:	e9 7f f0 ff ff       	jmp    80106dfd <alltraps>

80107d7e <vector212>:
.globl vector212
vector212:
  pushl $0
80107d7e:	6a 00                	push   $0x0
  pushl $212
80107d80:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d85:	e9 73 f0 ff ff       	jmp    80106dfd <alltraps>

80107d8a <vector213>:
.globl vector213
vector213:
  pushl $0
80107d8a:	6a 00                	push   $0x0
  pushl $213
80107d8c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107d91:	e9 67 f0 ff ff       	jmp    80106dfd <alltraps>

80107d96 <vector214>:
.globl vector214
vector214:
  pushl $0
80107d96:	6a 00                	push   $0x0
  pushl $214
80107d98:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107d9d:	e9 5b f0 ff ff       	jmp    80106dfd <alltraps>

80107da2 <vector215>:
.globl vector215
vector215:
  pushl $0
80107da2:	6a 00                	push   $0x0
  pushl $215
80107da4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107da9:	e9 4f f0 ff ff       	jmp    80106dfd <alltraps>

80107dae <vector216>:
.globl vector216
vector216:
  pushl $0
80107dae:	6a 00                	push   $0x0
  pushl $216
80107db0:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107db5:	e9 43 f0 ff ff       	jmp    80106dfd <alltraps>

80107dba <vector217>:
.globl vector217
vector217:
  pushl $0
80107dba:	6a 00                	push   $0x0
  pushl $217
80107dbc:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107dc1:	e9 37 f0 ff ff       	jmp    80106dfd <alltraps>

80107dc6 <vector218>:
.globl vector218
vector218:
  pushl $0
80107dc6:	6a 00                	push   $0x0
  pushl $218
80107dc8:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107dcd:	e9 2b f0 ff ff       	jmp    80106dfd <alltraps>

80107dd2 <vector219>:
.globl vector219
vector219:
  pushl $0
80107dd2:	6a 00                	push   $0x0
  pushl $219
80107dd4:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107dd9:	e9 1f f0 ff ff       	jmp    80106dfd <alltraps>

80107dde <vector220>:
.globl vector220
vector220:
  pushl $0
80107dde:	6a 00                	push   $0x0
  pushl $220
80107de0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107de5:	e9 13 f0 ff ff       	jmp    80106dfd <alltraps>

80107dea <vector221>:
.globl vector221
vector221:
  pushl $0
80107dea:	6a 00                	push   $0x0
  pushl $221
80107dec:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107df1:	e9 07 f0 ff ff       	jmp    80106dfd <alltraps>

80107df6 <vector222>:
.globl vector222
vector222:
  pushl $0
80107df6:	6a 00                	push   $0x0
  pushl $222
80107df8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107dfd:	e9 fb ef ff ff       	jmp    80106dfd <alltraps>

80107e02 <vector223>:
.globl vector223
vector223:
  pushl $0
80107e02:	6a 00                	push   $0x0
  pushl $223
80107e04:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107e09:	e9 ef ef ff ff       	jmp    80106dfd <alltraps>

80107e0e <vector224>:
.globl vector224
vector224:
  pushl $0
80107e0e:	6a 00                	push   $0x0
  pushl $224
80107e10:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107e15:	e9 e3 ef ff ff       	jmp    80106dfd <alltraps>

80107e1a <vector225>:
.globl vector225
vector225:
  pushl $0
80107e1a:	6a 00                	push   $0x0
  pushl $225
80107e1c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107e21:	e9 d7 ef ff ff       	jmp    80106dfd <alltraps>

80107e26 <vector226>:
.globl vector226
vector226:
  pushl $0
80107e26:	6a 00                	push   $0x0
  pushl $226
80107e28:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107e2d:	e9 cb ef ff ff       	jmp    80106dfd <alltraps>

80107e32 <vector227>:
.globl vector227
vector227:
  pushl $0
80107e32:	6a 00                	push   $0x0
  pushl $227
80107e34:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107e39:	e9 bf ef ff ff       	jmp    80106dfd <alltraps>

80107e3e <vector228>:
.globl vector228
vector228:
  pushl $0
80107e3e:	6a 00                	push   $0x0
  pushl $228
80107e40:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107e45:	e9 b3 ef ff ff       	jmp    80106dfd <alltraps>

80107e4a <vector229>:
.globl vector229
vector229:
  pushl $0
80107e4a:	6a 00                	push   $0x0
  pushl $229
80107e4c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e51:	e9 a7 ef ff ff       	jmp    80106dfd <alltraps>

80107e56 <vector230>:
.globl vector230
vector230:
  pushl $0
80107e56:	6a 00                	push   $0x0
  pushl $230
80107e58:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e5d:	e9 9b ef ff ff       	jmp    80106dfd <alltraps>

80107e62 <vector231>:
.globl vector231
vector231:
  pushl $0
80107e62:	6a 00                	push   $0x0
  pushl $231
80107e64:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e69:	e9 8f ef ff ff       	jmp    80106dfd <alltraps>

80107e6e <vector232>:
.globl vector232
vector232:
  pushl $0
80107e6e:	6a 00                	push   $0x0
  pushl $232
80107e70:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e75:	e9 83 ef ff ff       	jmp    80106dfd <alltraps>

80107e7a <vector233>:
.globl vector233
vector233:
  pushl $0
80107e7a:	6a 00                	push   $0x0
  pushl $233
80107e7c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e81:	e9 77 ef ff ff       	jmp    80106dfd <alltraps>

80107e86 <vector234>:
.globl vector234
vector234:
  pushl $0
80107e86:	6a 00                	push   $0x0
  pushl $234
80107e88:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e8d:	e9 6b ef ff ff       	jmp    80106dfd <alltraps>

80107e92 <vector235>:
.globl vector235
vector235:
  pushl $0
80107e92:	6a 00                	push   $0x0
  pushl $235
80107e94:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107e99:	e9 5f ef ff ff       	jmp    80106dfd <alltraps>

80107e9e <vector236>:
.globl vector236
vector236:
  pushl $0
80107e9e:	6a 00                	push   $0x0
  pushl $236
80107ea0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107ea5:	e9 53 ef ff ff       	jmp    80106dfd <alltraps>

80107eaa <vector237>:
.globl vector237
vector237:
  pushl $0
80107eaa:	6a 00                	push   $0x0
  pushl $237
80107eac:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107eb1:	e9 47 ef ff ff       	jmp    80106dfd <alltraps>

80107eb6 <vector238>:
.globl vector238
vector238:
  pushl $0
80107eb6:	6a 00                	push   $0x0
  pushl $238
80107eb8:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107ebd:	e9 3b ef ff ff       	jmp    80106dfd <alltraps>

80107ec2 <vector239>:
.globl vector239
vector239:
  pushl $0
80107ec2:	6a 00                	push   $0x0
  pushl $239
80107ec4:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107ec9:	e9 2f ef ff ff       	jmp    80106dfd <alltraps>

80107ece <vector240>:
.globl vector240
vector240:
  pushl $0
80107ece:	6a 00                	push   $0x0
  pushl $240
80107ed0:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107ed5:	e9 23 ef ff ff       	jmp    80106dfd <alltraps>

80107eda <vector241>:
.globl vector241
vector241:
  pushl $0
80107eda:	6a 00                	push   $0x0
  pushl $241
80107edc:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107ee1:	e9 17 ef ff ff       	jmp    80106dfd <alltraps>

80107ee6 <vector242>:
.globl vector242
vector242:
  pushl $0
80107ee6:	6a 00                	push   $0x0
  pushl $242
80107ee8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107eed:	e9 0b ef ff ff       	jmp    80106dfd <alltraps>

80107ef2 <vector243>:
.globl vector243
vector243:
  pushl $0
80107ef2:	6a 00                	push   $0x0
  pushl $243
80107ef4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107ef9:	e9 ff ee ff ff       	jmp    80106dfd <alltraps>

80107efe <vector244>:
.globl vector244
vector244:
  pushl $0
80107efe:	6a 00                	push   $0x0
  pushl $244
80107f00:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107f05:	e9 f3 ee ff ff       	jmp    80106dfd <alltraps>

80107f0a <vector245>:
.globl vector245
vector245:
  pushl $0
80107f0a:	6a 00                	push   $0x0
  pushl $245
80107f0c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107f11:	e9 e7 ee ff ff       	jmp    80106dfd <alltraps>

80107f16 <vector246>:
.globl vector246
vector246:
  pushl $0
80107f16:	6a 00                	push   $0x0
  pushl $246
80107f18:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107f1d:	e9 db ee ff ff       	jmp    80106dfd <alltraps>

80107f22 <vector247>:
.globl vector247
vector247:
  pushl $0
80107f22:	6a 00                	push   $0x0
  pushl $247
80107f24:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107f29:	e9 cf ee ff ff       	jmp    80106dfd <alltraps>

80107f2e <vector248>:
.globl vector248
vector248:
  pushl $0
80107f2e:	6a 00                	push   $0x0
  pushl $248
80107f30:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107f35:	e9 c3 ee ff ff       	jmp    80106dfd <alltraps>

80107f3a <vector249>:
.globl vector249
vector249:
  pushl $0
80107f3a:	6a 00                	push   $0x0
  pushl $249
80107f3c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107f41:	e9 b7 ee ff ff       	jmp    80106dfd <alltraps>

80107f46 <vector250>:
.globl vector250
vector250:
  pushl $0
80107f46:	6a 00                	push   $0x0
  pushl $250
80107f48:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f4d:	e9 ab ee ff ff       	jmp    80106dfd <alltraps>

80107f52 <vector251>:
.globl vector251
vector251:
  pushl $0
80107f52:	6a 00                	push   $0x0
  pushl $251
80107f54:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f59:	e9 9f ee ff ff       	jmp    80106dfd <alltraps>

80107f5e <vector252>:
.globl vector252
vector252:
  pushl $0
80107f5e:	6a 00                	push   $0x0
  pushl $252
80107f60:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f65:	e9 93 ee ff ff       	jmp    80106dfd <alltraps>

80107f6a <vector253>:
.globl vector253
vector253:
  pushl $0
80107f6a:	6a 00                	push   $0x0
  pushl $253
80107f6c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f71:	e9 87 ee ff ff       	jmp    80106dfd <alltraps>

80107f76 <vector254>:
.globl vector254
vector254:
  pushl $0
80107f76:	6a 00                	push   $0x0
  pushl $254
80107f78:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f7d:	e9 7b ee ff ff       	jmp    80106dfd <alltraps>

80107f82 <vector255>:
.globl vector255
vector255:
  pushl $0
80107f82:	6a 00                	push   $0x0
  pushl $255
80107f84:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f89:	e9 6f ee ff ff       	jmp    80106dfd <alltraps>

80107f8e <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f8e:	55                   	push   %ebp
80107f8f:	89 e5                	mov    %esp,%ebp
80107f91:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107f94:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f97:	83 e8 01             	sub    $0x1,%eax
80107f9a:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107f9e:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa8:	c1 e8 10             	shr    $0x10,%eax
80107fab:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107faf:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107fb2:	0f 01 10             	lgdtl  (%eax)
}
80107fb5:	c9                   	leave  
80107fb6:	c3                   	ret    

80107fb7 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107fb7:	55                   	push   %ebp
80107fb8:	89 e5                	mov    %esp,%ebp
80107fba:	83 ec 04             	sub    $0x4,%esp
80107fbd:	8b 45 08             	mov    0x8(%ebp),%eax
80107fc0:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107fc4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fc8:	0f 00 d8             	ltr    %ax
}
80107fcb:	c9                   	leave  
80107fcc:	c3                   	ret    

80107fcd <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107fcd:	55                   	push   %ebp
80107fce:	89 e5                	mov    %esp,%ebp
80107fd0:	83 ec 04             	sub    $0x4,%esp
80107fd3:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107fda:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107fde:	8e e8                	mov    %eax,%gs
}
80107fe0:	c9                   	leave  
80107fe1:	c3                   	ret    

80107fe2 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107fe2:	55                   	push   %ebp
80107fe3:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107fe5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe8:	0f 22 d8             	mov    %eax,%cr3
}
80107feb:	5d                   	pop    %ebp
80107fec:	c3                   	ret    

80107fed <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107fed:	55                   	push   %ebp
80107fee:	89 e5                	mov    %esp,%ebp
80107ff0:	8b 45 08             	mov    0x8(%ebp),%eax
80107ff3:	05 00 00 00 80       	add    $0x80000000,%eax
80107ff8:	5d                   	pop    %ebp
80107ff9:	c3                   	ret    

80107ffa <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107ffa:	55                   	push   %ebp
80107ffb:	89 e5                	mov    %esp,%ebp
80107ffd:	8b 45 08             	mov    0x8(%ebp),%eax
80108000:	05 00 00 00 80       	add    $0x80000000,%eax
80108005:	5d                   	pop    %ebp
80108006:	c3                   	ret    

80108007 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108007:	55                   	push   %ebp
80108008:	89 e5                	mov    %esp,%ebp
8010800a:	53                   	push   %ebx
8010800b:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010800e:	e8 15 b6 ff ff       	call   80103628 <cpunum>
80108013:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108019:	05 60 43 11 80       	add    $0x80114360,%eax
8010801e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108021:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108024:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010802a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802d:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108033:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108036:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010803a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010803d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108041:	83 e2 f0             	and    $0xfffffff0,%edx
80108044:	83 ca 0a             	or     $0xa,%edx
80108047:	88 50 7d             	mov    %dl,0x7d(%eax)
8010804a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010804d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108051:	83 ca 10             	or     $0x10,%edx
80108054:	88 50 7d             	mov    %dl,0x7d(%eax)
80108057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010805a:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010805e:	83 e2 9f             	and    $0xffffff9f,%edx
80108061:	88 50 7d             	mov    %dl,0x7d(%eax)
80108064:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108067:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010806b:	83 ca 80             	or     $0xffffff80,%edx
8010806e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108074:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108078:	83 ca 0f             	or     $0xf,%edx
8010807b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010807e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108081:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108085:	83 e2 ef             	and    $0xffffffef,%edx
80108088:	88 50 7e             	mov    %dl,0x7e(%eax)
8010808b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108092:	83 e2 df             	and    $0xffffffdf,%edx
80108095:	88 50 7e             	mov    %dl,0x7e(%eax)
80108098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010809f:	83 ca 40             	or     $0x40,%edx
801080a2:	88 50 7e             	mov    %dl,0x7e(%eax)
801080a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080a8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801080ac:	83 ca 80             	or     $0xffffff80,%edx
801080af:	88 50 7e             	mov    %dl,0x7e(%eax)
801080b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b5:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801080b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080bc:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801080c3:	ff ff 
801080c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c8:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801080cf:	00 00 
801080d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d4:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801080db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080de:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080e5:	83 e2 f0             	and    $0xfffffff0,%edx
801080e8:	83 ca 02             	or     $0x2,%edx
801080eb:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080fb:	83 ca 10             	or     $0x10,%edx
801080fe:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108107:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010810e:	83 e2 9f             	and    $0xffffff9f,%edx
80108111:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108121:	83 ca 80             	or     $0xffffff80,%edx
80108124:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010812a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108134:	83 ca 0f             	or     $0xf,%edx
80108137:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010813d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108140:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108147:	83 e2 ef             	and    $0xffffffef,%edx
8010814a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108153:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010815a:	83 e2 df             	and    $0xffffffdf,%edx
8010815d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108166:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010816d:	83 ca 40             	or     $0x40,%edx
80108170:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108176:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108179:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108180:	83 ca 80             	or     $0xffffff80,%edx
80108183:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010818c:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108193:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108196:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010819d:	ff ff 
8010819f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a2:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801081a9:	00 00 
801081ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ae:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801081b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b8:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081bf:	83 e2 f0             	and    $0xfffffff0,%edx
801081c2:	83 ca 0a             	or     $0xa,%edx
801081c5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ce:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081d5:	83 ca 10             	or     $0x10,%edx
801081d8:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e1:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081e8:	83 ca 60             	or     $0x60,%edx
801081eb:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081fb:	83 ca 80             	or     $0xffffff80,%edx
801081fe:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108207:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010820e:	83 ca 0f             	or     $0xf,%edx
80108211:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010821a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108221:	83 e2 ef             	and    $0xffffffef,%edx
80108224:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010822a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108234:	83 e2 df             	and    $0xffffffdf,%edx
80108237:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010823d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108240:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108247:	83 ca 40             	or     $0x40,%edx
8010824a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108250:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108253:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010825a:	83 ca 80             	or     $0xffffff80,%edx
8010825d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108263:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108266:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010826d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108270:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108277:	ff ff 
80108279:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010827c:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108283:	00 00 
80108285:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108288:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010828f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108292:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108299:	83 e2 f0             	and    $0xfffffff0,%edx
8010829c:	83 ca 02             	or     $0x2,%edx
8010829f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082af:	83 ca 10             	or     $0x10,%edx
801082b2:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082bb:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082c2:	83 ca 60             	or     $0x60,%edx
801082c5:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ce:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801082d5:	83 ca 80             	or     $0xffffff80,%edx
801082d8:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801082de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082e8:	83 ca 0f             	or     $0xf,%edx
801082eb:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082fb:	83 e2 ef             	and    $0xffffffef,%edx
801082fe:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108304:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108307:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010830e:	83 e2 df             	and    $0xffffffdf,%edx
80108311:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108317:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108321:	83 ca 40             	or     $0x40,%edx
80108324:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010832a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010832d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108334:	83 ca 80             	or     $0xffffff80,%edx
80108337:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010833d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108340:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108347:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834a:	05 b4 00 00 00       	add    $0xb4,%eax
8010834f:	89 c3                	mov    %eax,%ebx
80108351:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108354:	05 b4 00 00 00       	add    $0xb4,%eax
80108359:	c1 e8 10             	shr    $0x10,%eax
8010835c:	89 c1                	mov    %eax,%ecx
8010835e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108361:	05 b4 00 00 00       	add    $0xb4,%eax
80108366:	c1 e8 18             	shr    $0x18,%eax
80108369:	89 c2                	mov    %eax,%edx
8010836b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836e:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108375:	00 00 
80108377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837a:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108381:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108384:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010838a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010838d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108394:	83 e1 f0             	and    $0xfffffff0,%ecx
80108397:	83 c9 02             	or     $0x2,%ecx
8010839a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083aa:	83 c9 10             	or     $0x10,%ecx
801083ad:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b6:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083bd:	83 e1 9f             	and    $0xffffff9f,%ecx
801083c0:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c9:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801083d0:	83 c9 80             	or     $0xffffff80,%ecx
801083d3:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801083d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083dc:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083e3:	83 e1 f0             	and    $0xfffffff0,%ecx
801083e6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ef:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083f6:	83 e1 ef             	and    $0xffffffef,%ecx
801083f9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108402:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108409:	83 e1 df             	and    $0xffffffdf,%ecx
8010840c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108415:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010841c:	83 c9 40             	or     $0x40,%ecx
8010841f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108428:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010842f:	83 c9 80             	or     $0xffffff80,%ecx
80108432:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108438:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010843b:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108444:	83 c0 70             	add    $0x70,%eax
80108447:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010844e:	00 
8010844f:	89 04 24             	mov    %eax,(%esp)
80108452:	e8 37 fb ff ff       	call   80107f8e <lgdt>
  loadgs(SEG_KCPU << 3);
80108457:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010845e:	e8 6a fb ff ff       	call   80107fcd <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108466:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010846c:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108473:	00 00 00 00 
}
80108477:	83 c4 24             	add    $0x24,%esp
8010847a:	5b                   	pop    %ebx
8010847b:	5d                   	pop    %ebp
8010847c:	c3                   	ret    

8010847d <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010847d:	55                   	push   %ebp
8010847e:	89 e5                	mov    %esp,%ebp
80108480:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108483:	8b 45 0c             	mov    0xc(%ebp),%eax
80108486:	c1 e8 16             	shr    $0x16,%eax
80108489:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108490:	8b 45 08             	mov    0x8(%ebp),%eax
80108493:	01 d0                	add    %edx,%eax
80108495:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010849b:	8b 00                	mov    (%eax),%eax
8010849d:	83 e0 01             	and    $0x1,%eax
801084a0:	85 c0                	test   %eax,%eax
801084a2:	74 17                	je     801084bb <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801084a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084a7:	8b 00                	mov    (%eax),%eax
801084a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084ae:	89 04 24             	mov    %eax,(%esp)
801084b1:	e8 44 fb ff ff       	call   80107ffa <p2v>
801084b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084b9:	eb 4b                	jmp    80108506 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801084bb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801084bf:	74 0e                	je     801084cf <walkpgdir+0x52>
801084c1:	e8 86 ad ff ff       	call   8010324c <kalloc>
801084c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801084c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801084cd:	75 07                	jne    801084d6 <walkpgdir+0x59>
      return 0;
801084cf:	b8 00 00 00 00       	mov    $0x0,%eax
801084d4:	eb 47                	jmp    8010851d <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801084d6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084dd:	00 
801084de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084e5:	00 
801084e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e9:	89 04 24             	mov    %eax,(%esp)
801084ec:	e8 18 d5 ff ff       	call   80105a09 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801084f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f4:	89 04 24             	mov    %eax,(%esp)
801084f7:	e8 f1 fa ff ff       	call   80107fed <v2p>
801084fc:	83 c8 07             	or     $0x7,%eax
801084ff:	89 c2                	mov    %eax,%edx
80108501:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108504:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108506:	8b 45 0c             	mov    0xc(%ebp),%eax
80108509:	c1 e8 0c             	shr    $0xc,%eax
8010850c:	25 ff 03 00 00       	and    $0x3ff,%eax
80108511:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010851b:	01 d0                	add    %edx,%eax
}
8010851d:	c9                   	leave  
8010851e:	c3                   	ret    

8010851f <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010851f:	55                   	push   %ebp
80108520:	89 e5                	mov    %esp,%ebp
80108522:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108525:	8b 45 0c             	mov    0xc(%ebp),%eax
80108528:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010852d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108530:	8b 55 0c             	mov    0xc(%ebp),%edx
80108533:	8b 45 10             	mov    0x10(%ebp),%eax
80108536:	01 d0                	add    %edx,%eax
80108538:	83 e8 01             	sub    $0x1,%eax
8010853b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108540:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108543:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010854a:	00 
8010854b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010854e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108552:	8b 45 08             	mov    0x8(%ebp),%eax
80108555:	89 04 24             	mov    %eax,(%esp)
80108558:	e8 20 ff ff ff       	call   8010847d <walkpgdir>
8010855d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108560:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108564:	75 07                	jne    8010856d <mappages+0x4e>
      return -1;
80108566:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010856b:	eb 48                	jmp    801085b5 <mappages+0x96>
    if(*pte & PTE_P)
8010856d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108570:	8b 00                	mov    (%eax),%eax
80108572:	83 e0 01             	and    $0x1,%eax
80108575:	85 c0                	test   %eax,%eax
80108577:	74 0c                	je     80108585 <mappages+0x66>
      panic("remap");
80108579:	c7 04 24 e0 a2 10 80 	movl   $0x8010a2e0,(%esp)
80108580:	e8 b5 7f ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108585:	8b 45 18             	mov    0x18(%ebp),%eax
80108588:	0b 45 14             	or     0x14(%ebp),%eax
8010858b:	83 c8 01             	or     $0x1,%eax
8010858e:	89 c2                	mov    %eax,%edx
80108590:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108593:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108598:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010859b:	75 08                	jne    801085a5 <mappages+0x86>
      break;
8010859d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010859e:	b8 00 00 00 00       	mov    $0x0,%eax
801085a3:	eb 10                	jmp    801085b5 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801085a5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801085ac:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801085b3:	eb 8e                	jmp    80108543 <mappages+0x24>
  return 0;
}
801085b5:	c9                   	leave  
801085b6:	c3                   	ret    

801085b7 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801085b7:	55                   	push   %ebp
801085b8:	89 e5                	mov    %esp,%ebp
801085ba:	53                   	push   %ebx
801085bb:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801085be:	e8 89 ac ff ff       	call   8010324c <kalloc>
801085c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801085c6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085ca:	75 0a                	jne    801085d6 <setupkvm+0x1f>
    return 0;
801085cc:	b8 00 00 00 00       	mov    $0x0,%eax
801085d1:	e9 98 00 00 00       	jmp    8010866e <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801085d6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085dd:	00 
801085de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085e5:	00 
801085e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085e9:	89 04 24             	mov    %eax,(%esp)
801085ec:	e8 18 d4 ff ff       	call   80105a09 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801085f1:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801085f8:	e8 fd f9 ff ff       	call   80107ffa <p2v>
801085fd:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108602:	76 0c                	jbe    80108610 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108604:	c7 04 24 e6 a2 10 80 	movl   $0x8010a2e6,(%esp)
8010860b:	e8 2a 7f ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108610:	c7 45 f4 a0 d4 10 80 	movl   $0x8010d4a0,-0xc(%ebp)
80108617:	eb 49                	jmp    80108662 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861c:	8b 48 0c             	mov    0xc(%eax),%ecx
8010861f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108622:	8b 50 04             	mov    0x4(%eax),%edx
80108625:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108628:	8b 58 08             	mov    0x8(%eax),%ebx
8010862b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010862e:	8b 40 04             	mov    0x4(%eax),%eax
80108631:	29 c3                	sub    %eax,%ebx
80108633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108636:	8b 00                	mov    (%eax),%eax
80108638:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010863c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108640:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108644:	89 44 24 04          	mov    %eax,0x4(%esp)
80108648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010864b:	89 04 24             	mov    %eax,(%esp)
8010864e:	e8 cc fe ff ff       	call   8010851f <mappages>
80108653:	85 c0                	test   %eax,%eax
80108655:	79 07                	jns    8010865e <setupkvm+0xa7>
      (uint)k->phys_start, k->perm) < 0)
      return 0;
80108657:	b8 00 00 00 00       	mov    $0x0,%eax
8010865c:	eb 10                	jmp    8010866e <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010865e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108662:	81 7d f4 e0 d4 10 80 	cmpl   $0x8010d4e0,-0xc(%ebp)
80108669:	72 ae                	jb     80108619 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
      (uint)k->phys_start, k->perm) < 0)
      return 0;
    return pgdir;
8010866b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  }
8010866e:	83 c4 34             	add    $0x34,%esp
80108671:	5b                   	pop    %ebx
80108672:	5d                   	pop    %ebp
80108673:	c3                   	ret    

80108674 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
  void
  kvmalloc(void)
  {
80108674:	55                   	push   %ebp
80108675:	89 e5                	mov    %esp,%ebp
80108677:	83 ec 08             	sub    $0x8,%esp
    kpgdir = setupkvm();
8010867a:	e8 38 ff ff ff       	call   801085b7 <setupkvm>
8010867f:	a3 58 0d 12 80       	mov    %eax,0x80120d58
    switchkvm();
80108684:	e8 02 00 00 00       	call   8010868b <switchkvm>
  }
80108689:	c9                   	leave  
8010868a:	c3                   	ret    

8010868b <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
  void
  switchkvm(void)
  {
8010868b:	55                   	push   %ebp
8010868c:	89 e5                	mov    %esp,%ebp
8010868e:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108691:	a1 58 0d 12 80       	mov    0x80120d58,%eax
80108696:	89 04 24             	mov    %eax,(%esp)
80108699:	e8 4f f9 ff ff       	call   80107fed <v2p>
8010869e:	89 04 24             	mov    %eax,(%esp)
801086a1:	e8 3c f9 ff ff       	call   80107fe2 <lcr3>
}
801086a6:	c9                   	leave  
801086a7:	c3                   	ret    

801086a8 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801086a8:	55                   	push   %ebp
801086a9:	89 e5                	mov    %esp,%ebp
801086ab:	53                   	push   %ebx
801086ac:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801086af:	e8 55 d2 ff ff       	call   80105909 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801086b4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801086ba:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086c1:	83 c2 08             	add    $0x8,%edx
801086c4:	89 d3                	mov    %edx,%ebx
801086c6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086cd:	83 c2 08             	add    $0x8,%edx
801086d0:	c1 ea 10             	shr    $0x10,%edx
801086d3:	89 d1                	mov    %edx,%ecx
801086d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801086dc:	83 c2 08             	add    $0x8,%edx
801086df:	c1 ea 18             	shr    $0x18,%edx
801086e2:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801086e9:	67 00 
801086eb:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801086f2:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801086f8:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086ff:	83 e1 f0             	and    $0xfffffff0,%ecx
80108702:	83 c9 09             	or     $0x9,%ecx
80108705:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010870b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108712:	83 c9 10             	or     $0x10,%ecx
80108715:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010871b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108722:	83 e1 9f             	and    $0xffffff9f,%ecx
80108725:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010872b:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108732:	83 c9 80             	or     $0xffffff80,%ecx
80108735:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010873b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108742:	83 e1 f0             	and    $0xfffffff0,%ecx
80108745:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010874b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108752:	83 e1 ef             	and    $0xffffffef,%ecx
80108755:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010875b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108762:	83 e1 df             	and    $0xffffffdf,%ecx
80108765:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010876b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108772:	83 c9 40             	or     $0x40,%ecx
80108775:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010877b:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108782:	83 e1 7f             	and    $0x7f,%ecx
80108785:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010878b:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108791:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108797:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010879e:	83 e2 ef             	and    $0xffffffef,%edx
801087a1:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801087a7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087ad:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801087b3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801087b9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801087c0:	8b 52 08             	mov    0x8(%edx),%edx
801087c3:	81 c2 00 10 00 00    	add    $0x1000,%edx
801087c9:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801087cc:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801087d3:	e8 df f7 ff ff       	call   80107fb7 <ltr>
  if(p->pgdir == 0)
801087d8:	8b 45 08             	mov    0x8(%ebp),%eax
801087db:	8b 40 04             	mov    0x4(%eax),%eax
801087de:	85 c0                	test   %eax,%eax
801087e0:	75 0c                	jne    801087ee <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801087e2:	c7 04 24 f7 a2 10 80 	movl   $0x8010a2f7,(%esp)
801087e9:	e8 4c 7d ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801087ee:	8b 45 08             	mov    0x8(%ebp),%eax
801087f1:	8b 40 04             	mov    0x4(%eax),%eax
801087f4:	89 04 24             	mov    %eax,(%esp)
801087f7:	e8 f1 f7 ff ff       	call   80107fed <v2p>
801087fc:	89 04 24             	mov    %eax,(%esp)
801087ff:	e8 de f7 ff ff       	call   80107fe2 <lcr3>
  popcli();
80108804:	e8 44 d1 ff ff       	call   8010594d <popcli>
}
80108809:	83 c4 14             	add    $0x14,%esp
8010880c:	5b                   	pop    %ebx
8010880d:	5d                   	pop    %ebp
8010880e:	c3                   	ret    

8010880f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010880f:	55                   	push   %ebp
80108810:	89 e5                	mov    %esp,%ebp
80108812:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108815:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010881c:	76 0c                	jbe    8010882a <inituvm+0x1b>
    panic("inituvm: more than a page");
8010881e:	c7 04 24 0b a3 10 80 	movl   $0x8010a30b,(%esp)
80108825:	e8 10 7d ff ff       	call   8010053a <panic>
  mem = kalloc();
8010882a:	e8 1d aa ff ff       	call   8010324c <kalloc>
8010882f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108832:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108839:	00 
8010883a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108841:	00 
80108842:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108845:	89 04 24             	mov    %eax,(%esp)
80108848:	e8 bc d1 ff ff       	call   80105a09 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010884d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108850:	89 04 24             	mov    %eax,(%esp)
80108853:	e8 95 f7 ff ff       	call   80107fed <v2p>
80108858:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010885f:	00 
80108860:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108864:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010886b:	00 
8010886c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108873:	00 
80108874:	8b 45 08             	mov    0x8(%ebp),%eax
80108877:	89 04 24             	mov    %eax,(%esp)
8010887a:	e8 a0 fc ff ff       	call   8010851f <mappages>
  memmove(mem, init, sz);
8010887f:	8b 45 10             	mov    0x10(%ebp),%eax
80108882:	89 44 24 08          	mov    %eax,0x8(%esp)
80108886:	8b 45 0c             	mov    0xc(%ebp),%eax
80108889:	89 44 24 04          	mov    %eax,0x4(%esp)
8010888d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108890:	89 04 24             	mov    %eax,(%esp)
80108893:	e8 40 d2 ff ff       	call   80105ad8 <memmove>
}
80108898:	c9                   	leave  
80108899:	c3                   	ret    

8010889a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010889a:	55                   	push   %ebp
8010889b:	89 e5                	mov    %esp,%ebp
8010889d:	53                   	push   %ebx
8010889e:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801088a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801088a4:	25 ff 0f 00 00       	and    $0xfff,%eax
801088a9:	85 c0                	test   %eax,%eax
801088ab:	74 0c                	je     801088b9 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801088ad:	c7 04 24 28 a3 10 80 	movl   $0x8010a328,(%esp)
801088b4:	e8 81 7c ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801088b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801088c0:	e9 a9 00 00 00       	jmp    8010896e <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801088c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801088cb:	01 d0                	add    %edx,%eax
801088cd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088d4:	00 
801088d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801088d9:	8b 45 08             	mov    0x8(%ebp),%eax
801088dc:	89 04 24             	mov    %eax,(%esp)
801088df:	e8 99 fb ff ff       	call   8010847d <walkpgdir>
801088e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801088e7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088eb:	75 0c                	jne    801088f9 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801088ed:	c7 04 24 4b a3 10 80 	movl   $0x8010a34b,(%esp)
801088f4:	e8 41 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801088f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088fc:	8b 00                	mov    (%eax),%eax
801088fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108903:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108909:	8b 55 18             	mov    0x18(%ebp),%edx
8010890c:	29 c2                	sub    %eax,%edx
8010890e:	89 d0                	mov    %edx,%eax
80108910:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108915:	77 0f                	ja     80108926 <loaduvm+0x8c>
      n = sz - i;
80108917:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891a:	8b 55 18             	mov    0x18(%ebp),%edx
8010891d:	29 c2                	sub    %eax,%edx
8010891f:	89 d0                	mov    %edx,%eax
80108921:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108924:	eb 07                	jmp    8010892d <loaduvm+0x93>
    else
      n = PGSIZE;
80108926:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010892d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108930:	8b 55 14             	mov    0x14(%ebp),%edx
80108933:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108936:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108939:	89 04 24             	mov    %eax,(%esp)
8010893c:	e8 b9 f6 ff ff       	call   80107ffa <p2v>
80108941:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108944:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108948:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010894c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108950:	8b 45 10             	mov    0x10(%ebp),%eax
80108953:	89 04 24             	mov    %eax,(%esp)
80108956:	e8 71 95 ff ff       	call   80101ecc <readi>
8010895b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010895e:	74 07                	je     80108967 <loaduvm+0xcd>
      return -1;
80108960:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108965:	eb 18                	jmp    8010897f <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108967:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010896e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108971:	3b 45 18             	cmp    0x18(%ebp),%eax
80108974:	0f 82 4b ff ff ff    	jb     801088c5 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010897a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010897f:	83 c4 24             	add    $0x24,%esp
80108982:	5b                   	pop    %ebx
80108983:	5d                   	pop    %ebp
80108984:	c3                   	ret    

80108985 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108985:	55                   	push   %ebp
80108986:	89 e5                	mov    %esp,%ebp
80108988:	53                   	push   %ebx
80108989:	83 ec 34             	sub    $0x34,%esp
  char *mem;
  uint a;
  int i;

  if(newsz >= KERNBASE)
8010898c:	8b 45 10             	mov    0x10(%ebp),%eax
8010898f:	85 c0                	test   %eax,%eax
80108991:	79 0a                	jns    8010899d <allocuvm+0x18>
    return 0;
80108993:	b8 00 00 00 00       	mov    $0x0,%eax
80108998:	e9 2d 02 00 00       	jmp    80108bca <allocuvm+0x245>
  if(newsz < oldsz)
8010899d:	8b 45 10             	mov    0x10(%ebp),%eax
801089a0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801089a3:	73 08                	jae    801089ad <allocuvm+0x28>
    return oldsz;
801089a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801089a8:	e9 1d 02 00 00       	jmp    80108bca <allocuvm+0x245>

  a = PGROUNDUP(oldsz);
801089ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801089b0:	05 ff 0f 00 00       	add    $0xfff,%eax
801089b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801089bd:	e9 f9 01 00 00       	jmp    80108bbb <allocuvm+0x236>
    mem = kalloc();
801089c2:	e8 85 a8 ff ff       	call   8010324c <kalloc>
801089c7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(mem == 0){
801089ca:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089ce:	75 36                	jne    80108a06 <allocuvm+0x81>
      cprintf("allocuvm out of memory\n");
801089d0:	c7 04 24 69 a3 10 80 	movl   $0x8010a369,(%esp)
801089d7:	e8 c4 79 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz, proc);
801089dc:	8b 45 14             	mov    0x14(%ebp),%eax
801089df:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801089e6:	89 44 24 08          	mov    %eax,0x8(%esp)
801089ea:	8b 45 10             	mov    0x10(%ebp),%eax
801089ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801089f1:	8b 45 08             	mov    0x8(%ebp),%eax
801089f4:	89 04 24             	mov    %eax,(%esp)
801089f7:	e8 d4 01 00 00       	call   80108bd0 <deallocuvm>
      return 0;
801089fc:	b8 00 00 00 00       	mov    $0x0,%eax
80108a01:	e9 c4 01 00 00       	jmp    80108bca <allocuvm+0x245>
    }
    memset(mem, 0, PGSIZE);
80108a06:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a0d:	00 
80108a0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a15:	00 
80108a16:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a19:	89 04 24             	mov    %eax,(%esp)
80108a1c:	e8 e8 cf ff ff       	call   80105a09 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108a21:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a24:	89 04 24             	mov    %eax,(%esp)
80108a27:	e8 c1 f5 ff ff       	call   80107fed <v2p>
80108a2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108a2f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a36:	00 
80108a37:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a3b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a42:	00 
80108a43:	89 54 24 04          	mov    %edx,0x4(%esp)
80108a47:	8b 45 08             	mov    0x8(%ebp),%eax
80108a4a:	89 04 24             	mov    %eax,(%esp)
80108a4d:	e8 cd fa ff ff       	call   8010851f <mappages>
    //find the next open cell in pages array
      i=0;
80108a52:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a59:	eb 16                	jmp    80108a71 <allocuvm+0xec>
        if(i > MAX_TOTAL_PAGES){
80108a5b:	83 7d f0 1e          	cmpl   $0x1e,-0x10(%ebp)
80108a5f:	7e 0c                	jle    80108a6d <allocuvm+0xe8>
          panic("too many pages in memory! max is 30 total");
80108a61:	c7 04 24 84 a3 10 80 	movl   $0x8010a384,(%esp)
80108a68:	e8 cd 7a ff ff       	call   8010053a <panic>
        }
        i++;
80108a6d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
    //find the next open cell in pages array
      i=0;
      while(proc->pagesMetaData[i].va != (char *) -1){
80108a71:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108a74:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a77:	89 d0                	mov    %edx,%eax
80108a79:	c1 e0 02             	shl    $0x2,%eax
80108a7c:	01 d0                	add    %edx,%eax
80108a7e:	c1 e0 02             	shl    $0x2,%eax
80108a81:	01 c8                	add    %ecx,%eax
80108a83:	05 90 00 00 00       	add    $0x90,%eax
80108a88:	8b 00                	mov    (%eax),%eax
80108a8a:	83 f8 ff             	cmp    $0xffffffff,%eax
80108a8d:	75 cc                	jne    80108a5b <allocuvm+0xd6>
        if(i > MAX_TOTAL_PAGES){
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
80108a8f:	e8 73 10 00 00       	call   80109b07 <isInit>
80108a94:	85 c0                	test   %eax,%eax
80108a96:	75 60                	jne    80108af8 <allocuvm+0x173>
80108a98:	e8 3d 10 00 00       	call   80109ada <isShell>
80108a9d:	85 c0                	test   %eax,%eax
80108a9f:	75 57                	jne    80108af8 <allocuvm+0x173>
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108aa1:	8b 45 14             	mov    0x14(%ebp),%eax
80108aa4:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108aaa:	83 f8 0e             	cmp    $0xe,%eax
80108aad:	76 32                	jbe    80108ae1 <allocuvm+0x15c>
          swapOut();
80108aaf:	e8 b6 0b 00 00       	call   8010966a <swapOut>
          lcr3(v2p(proc->pgdir));
80108ab4:	8b 45 14             	mov    0x14(%ebp),%eax
80108ab7:	8b 40 04             	mov    0x4(%eax),%eax
80108aba:	89 04 24             	mov    %eax,(%esp)
80108abd:	e8 2b f5 ff ff       	call   80107fed <v2p>
80108ac2:	89 04 24             	mov    %eax,(%esp)
80108ac5:	e8 18 f5 ff ff       	call   80107fe2 <lcr3>
          proc->swapedPagesCounter++;
80108aca:	8b 45 14             	mov    0x14(%ebp),%eax
80108acd:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108ad3:	8d 50 01             	lea    0x1(%eax),%edx
80108ad6:	8b 45 14             	mov    0x14(%ebp),%eax
80108ad9:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108adf:	eb 2c                	jmp    80108b0d <allocuvm+0x188>
          swapOut();
          lcr3(v2p(proc->pgdir));
          proc->swapedPagesCounter++;
        }
        else{
          proc->memoryPagesCounter++;
80108ae1:	8b 45 14             	mov    0x14(%ebp),%eax
80108ae4:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108aea:	8d 50 01             	lea    0x1(%eax),%edx
80108aed:	8b 45 14             	mov    0x14(%ebp),%eax
80108af0:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
          panic("too many pages in memory! max is 30 total");
        }
        i++;
      }
      if ((!isInit()) && (!isShell()) && SCHEDFLAG != 1){ //check if not shell or init
        if(proc->memoryPagesCounter >= MAX_PSYC_PAGES){//no room, swap something out and let him in
80108af6:	eb 15                	jmp    80108b0d <allocuvm+0x188>
        else{
          proc->memoryPagesCounter++;
        }
      }
      else{
        proc->memoryPagesCounter++;
80108af8:	8b 45 14             	mov    0x14(%ebp),%eax
80108afb:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108b01:	8d 50 01             	lea    0x1(%eax),%edx
80108b04:	8b 45 14             	mov    0x14(%ebp),%eax
80108b07:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      }
      proc->pagesMetaData[i].va = (char *)a;
80108b0d:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108b10:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b13:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b16:	89 d0                	mov    %edx,%eax
80108b18:	c1 e0 02             	shl    $0x2,%eax
80108b1b:	01 d0                	add    %edx,%eax
80108b1d:	c1 e0 02             	shl    $0x2,%eax
80108b20:	01 d8                	add    %ebx,%eax
80108b22:	05 90 00 00 00       	add    $0x90,%eax
80108b27:	89 08                	mov    %ecx,(%eax)
      proc->pagesMetaData[i].isPhysical = 1;
80108b29:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b2c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b2f:	89 d0                	mov    %edx,%eax
80108b31:	c1 e0 02             	shl    $0x2,%eax
80108b34:	01 d0                	add    %edx,%eax
80108b36:	c1 e0 02             	shl    $0x2,%eax
80108b39:	01 c8                	add    %ecx,%eax
80108b3b:	05 94 00 00 00       	add    $0x94,%eax
80108b40:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      proc->pagesMetaData[i].fileOffset = -1;
80108b46:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b49:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b4c:	89 d0                	mov    %edx,%eax
80108b4e:	c1 e0 02             	shl    $0x2,%eax
80108b51:	01 d0                	add    %edx,%eax
80108b53:	c1 e0 02             	shl    $0x2,%eax
80108b56:	01 c8                	add    %ecx,%eax
80108b58:	05 98 00 00 00       	add    $0x98,%eax
80108b5d:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
      proc->pagesMetaData[i].count = proc->numOfPages;
80108b63:	8b 45 14             	mov    0x14(%ebp),%eax
80108b66:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80108b6c:	8b 5d 14             	mov    0x14(%ebp),%ebx
80108b6f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108b72:	89 d0                	mov    %edx,%eax
80108b74:	c1 e0 02             	shl    $0x2,%eax
80108b77:	01 d0                	add    %edx,%eax
80108b79:	c1 e0 02             	shl    $0x2,%eax
80108b7c:	01 d8                	add    %ebx,%eax
80108b7e:	05 9c 00 00 00       	add    $0x9c,%eax
80108b83:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80108b85:	8b 45 14             	mov    0x14(%ebp),%eax
80108b88:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80108b8e:	8d 50 01             	lea    0x1(%eax),%edx
80108b91:	8b 45 14             	mov    0x14(%ebp),%eax
80108b94:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      proc->pagesMetaData[i].lru = 0x80;
80108b9a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108b9d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ba0:	89 d0                	mov    %edx,%eax
80108ba2:	c1 e0 02             	shl    $0x2,%eax
80108ba5:	01 d0                	add    %edx,%eax
80108ba7:	c1 e0 02             	shl    $0x2,%eax
80108baa:	01 c8                	add    %ecx,%eax
80108bac:	05 a0 00 00 00       	add    $0xa0,%eax
80108bb1:	c6 00 80             	movb   $0x80,(%eax)
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108bb4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bbe:	3b 45 10             	cmp    0x10(%ebp),%eax
80108bc1:	0f 82 fb fd ff ff    	jb     801089c2 <allocuvm+0x3d>
      proc->pagesMetaData[i].fileOffset = -1;
      proc->pagesMetaData[i].count = proc->numOfPages;
      proc->numOfPages++;
      proc->pagesMetaData[i].lru = 0x80;
  }
  return newsz;
80108bc7:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108bca:	83 c4 34             	add    $0x34,%esp
80108bcd:	5b                   	pop    %ebx
80108bce:	5d                   	pop    %ebp
80108bcf:	c3                   	ret    

80108bd0 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz, struct proc *proc)
{
80108bd0:	55                   	push   %ebp
80108bd1:	89 e5                	mov    %esp,%ebp
80108bd3:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint a, pa;
  int i;
  if(newsz >= oldsz)
80108bd6:	8b 45 10             	mov    0x10(%ebp),%eax
80108bd9:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108bdc:	72 08                	jb     80108be6 <deallocuvm+0x16>
    return oldsz;
80108bde:	8b 45 0c             	mov    0xc(%ebp),%eax
80108be1:	e9 ec 01 00 00       	jmp    80108dd2 <deallocuvm+0x202>

  a = PGROUNDUP(newsz);
80108be6:	8b 45 10             	mov    0x10(%ebp),%eax
80108be9:	05 ff 0f 00 00       	add    $0xfff,%eax
80108bee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bf3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108bf6:	e9 c8 01 00 00       	jmp    80108dc3 <deallocuvm+0x1f3>
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
80108bfb:	8b 45 14             	mov    0x14(%ebp),%eax
80108bfe:	8b 40 04             	mov    0x4(%eax),%eax
80108c01:	3b 45 08             	cmp    0x8(%ebp),%eax
80108c04:	0f 85 07 01 00 00    	jne    80108d11 <deallocuvm+0x141>
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108c0a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80108c11:	e9 f1 00 00 00       	jmp    80108d07 <deallocuvm+0x137>
          if(proc->pagesMetaData[i].va == (char *)a){
80108c16:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c19:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c1c:	89 d0                	mov    %edx,%eax
80108c1e:	c1 e0 02             	shl    $0x2,%eax
80108c21:	01 d0                	add    %edx,%eax
80108c23:	c1 e0 02             	shl    $0x2,%eax
80108c26:	01 c8                	add    %ecx,%eax
80108c28:	05 90 00 00 00       	add    $0x90,%eax
80108c2d:	8b 10                	mov    (%eax),%edx
80108c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c32:	39 c2                	cmp    %eax,%edx
80108c34:	0f 85 c9 00 00 00    	jne    80108d03 <deallocuvm+0x133>
            if((!isShell()) && (!isInit())){
80108c3a:	e8 9b 0e 00 00       	call   80109ada <isShell>
80108c3f:	85 c0                	test   %eax,%eax
80108c41:	75 54                	jne    80108c97 <deallocuvm+0xc7>
80108c43:	e8 bf 0e 00 00       	call   80109b07 <isInit>
80108c48:	85 c0                	test   %eax,%eax
80108c4a:	75 4b                	jne    80108c97 <deallocuvm+0xc7>
              if(proc->pagesMetaData[i].isPhysical){
80108c4c:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108c4f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108c52:	89 d0                	mov    %edx,%eax
80108c54:	c1 e0 02             	shl    $0x2,%eax
80108c57:	01 d0                	add    %edx,%eax
80108c59:	c1 e0 02             	shl    $0x2,%eax
80108c5c:	01 c8                	add    %ecx,%eax
80108c5e:	05 94 00 00 00       	add    $0x94,%eax
80108c63:	8b 00                	mov    (%eax),%eax
80108c65:	85 c0                	test   %eax,%eax
80108c67:	74 17                	je     80108c80 <deallocuvm+0xb0>
                proc->memoryPagesCounter--;
80108c69:	8b 45 14             	mov    0x14(%ebp),%eax
80108c6c:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108c72:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c75:	8b 45 14             	mov    0x14(%ebp),%eax
80108c78:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108c7e:	eb 2c                	jmp    80108cac <deallocuvm+0xdc>
                proc->memoryPagesCounter--;
              }
              else{
                proc->swapedPagesCounter--;
80108c80:	8b 45 14             	mov    0x14(%ebp),%eax
80108c83:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
80108c89:	8d 50 ff             	lea    -0x1(%eax),%edx
80108c8c:	8b 45 14             	mov    0x14(%ebp),%eax
80108c8f:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
          if(proc->pagesMetaData[i].va == (char *)a){
            if((!isShell()) && (!isInit())){
              if(proc->pagesMetaData[i].isPhysical){
80108c95:	eb 15                	jmp    80108cac <deallocuvm+0xdc>
              else{
                proc->swapedPagesCounter--;
              }
            }
            else{
              proc->memoryPagesCounter--;
80108c97:	8b 45 14             	mov    0x14(%ebp),%eax
80108c9a:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80108ca0:	8d 50 ff             	lea    -0x1(%eax),%edx
80108ca3:	8b 45 14             	mov    0x14(%ebp),%eax
80108ca6:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
            }
            proc->pagesMetaData[i].va = (char *) -1;
80108cac:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108caf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cb2:	89 d0                	mov    %edx,%eax
80108cb4:	c1 e0 02             	shl    $0x2,%eax
80108cb7:	01 d0                	add    %edx,%eax
80108cb9:	c1 e0 02             	shl    $0x2,%eax
80108cbc:	01 c8                	add    %ecx,%eax
80108cbe:	05 90 00 00 00       	add    $0x90,%eax
80108cc3:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
            proc->pagesMetaData[i].isPhysical = 0;
80108cc9:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108ccc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ccf:	89 d0                	mov    %edx,%eax
80108cd1:	c1 e0 02             	shl    $0x2,%eax
80108cd4:	01 d0                	add    %edx,%eax
80108cd6:	c1 e0 02             	shl    $0x2,%eax
80108cd9:	01 c8                	add    %ecx,%eax
80108cdb:	05 94 00 00 00       	add    $0x94,%eax
80108ce0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            proc->pagesMetaData[i].fileOffset = -1;
80108ce6:	8b 4d 14             	mov    0x14(%ebp),%ecx
80108ce9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108cec:	89 d0                	mov    %edx,%eax
80108cee:	c1 e0 02             	shl    $0x2,%eax
80108cf1:	01 d0                	add    %edx,%eax
80108cf3:	c1 e0 02             	shl    $0x2,%eax
80108cf6:	01 c8                	add    %ecx,%eax
80108cf8:	05 98 00 00 00       	add    $0x98,%eax
80108cfd:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
    if(pgdir == proc->pgdir){// if it's the procc itself, clean pages
        for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80108d03:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80108d07:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80108d0b:	0f 8e 05 ff ff ff    	jle    80108c16 <deallocuvm+0x46>
            proc->pagesMetaData[i].isPhysical = 0;
            proc->pagesMetaData[i].fileOffset = -1;
          }
        }
    }
    pte = walkpgdir(pgdir, (char*)a, 0);
80108d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d14:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108d1b:	00 
80108d1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d20:	8b 45 08             	mov    0x8(%ebp),%eax
80108d23:	89 04 24             	mov    %eax,(%esp)
80108d26:	e8 52 f7 ff ff       	call   8010847d <walkpgdir>
80108d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(!pte)
80108d2e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d32:	75 09                	jne    80108d3d <deallocuvm+0x16d>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d34:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d3b:	eb 7f                	jmp    80108dbc <deallocuvm+0x1ec>
    else if((*pte & PTE_P) != 0){
80108d3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d40:	8b 00                	mov    (%eax),%eax
80108d42:	83 e0 01             	and    $0x1,%eax
80108d45:	85 c0                	test   %eax,%eax
80108d47:	74 5c                	je     80108da5 <deallocuvm+0x1d5>
      if((*pte & PTE_PG) == 0){//in memory, do kfree
80108d49:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d4c:	8b 00                	mov    (%eax),%eax
80108d4e:	25 00 02 00 00       	and    $0x200,%eax
80108d53:	85 c0                	test   %eax,%eax
80108d55:	75 43                	jne    80108d9a <deallocuvm+0x1ca>
        pa = PTE_ADDR(*pte);
80108d57:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d5a:	8b 00                	mov    (%eax),%eax
80108d5c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d61:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if(pa == 0)
80108d64:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d68:	75 0c                	jne    80108d76 <deallocuvm+0x1a6>
          panic("kfree");
80108d6a:	c7 04 24 ae a3 10 80 	movl   $0x8010a3ae,(%esp)
80108d71:	e8 c4 77 ff ff       	call   8010053a <panic>
        char *v = p2v(pa);
80108d76:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d79:	89 04 24             	mov    %eax,(%esp)
80108d7c:	e8 79 f2 ff ff       	call   80107ffa <p2v>
80108d81:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        kfree(v);
80108d84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d87:	89 04 24             	mov    %eax,(%esp)
80108d8a:	e8 fb a3 ff ff       	call   8010318a <kfree>
        *pte = 0;
80108d8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108d98:	eb 22                	jmp    80108dbc <deallocuvm+0x1ec>
      }
      else{//on swap file, just elapse pte
        *pte = 0;
80108d9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d9d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80108da3:	eb 17                	jmp    80108dbc <deallocuvm+0x1ec>
      }
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
80108da5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108da8:	8b 00                	mov    (%eax),%eax
80108daa:	25 00 02 00 00       	and    $0x200,%eax
80108daf:	85 c0                	test   %eax,%eax
80108db1:	74 09                	je     80108dbc <deallocuvm+0x1ec>
        *pte = 0;
80108db3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108db6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  int i;
  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108dbc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108dc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dc6:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108dc9:	0f 82 2c fe ff ff    	jb     80108bfb <deallocuvm+0x2b>
    }
    else if(*pte & PTE_PG){//on swap file, just elapse pte
        *pte = 0;
    }
  }
  return newsz;
80108dcf:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108dd2:	c9                   	leave  
80108dd3:	c3                   	ret    

80108dd4 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir,struct proc *p)
{
80108dd4:	55                   	push   %ebp
80108dd5:	89 e5                	mov    %esp,%ebp
80108dd7:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108dda:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108dde:	75 0c                	jne    80108dec <freevm+0x18>
    panic("freevm: no pgdir");
80108de0:	c7 04 24 b4 a3 10 80 	movl   $0x8010a3b4,(%esp)
80108de7:	e8 4e 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0,proc);
80108dec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108df2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108df6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108dfd:	00 
80108dfe:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108e05:	80 
80108e06:	8b 45 08             	mov    0x8(%ebp),%eax
80108e09:	89 04 24             	mov    %eax,(%esp)
80108e0c:	e8 bf fd ff ff       	call   80108bd0 <deallocuvm>
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e18:	eb 48                	jmp    80108e62 <freevm+0x8e>
    if(pgdir[i] & PTE_P){
80108e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e1d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e24:	8b 45 08             	mov    0x8(%ebp),%eax
80108e27:	01 d0                	add    %edx,%eax
80108e29:	8b 00                	mov    (%eax),%eax
80108e2b:	83 e0 01             	and    $0x1,%eax
80108e2e:	85 c0                	test   %eax,%eax
80108e30:	74 2c                	je     80108e5e <freevm+0x8a>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e35:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80108e3f:	01 d0                	add    %edx,%eax
80108e41:	8b 00                	mov    (%eax),%eax
80108e43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e48:	89 04 24             	mov    %eax,(%esp)
80108e4b:	e8 aa f1 ff ff       	call   80107ffa <p2v>
80108e50:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e56:	89 04 24             	mov    %eax,(%esp)
80108e59:	e8 2c a3 ff ff       	call   8010318a <kfree>
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0,proc);
   // if(p != 0)
   //   clearAllPages(p);
  for(i = 0; i < NPDENTRIES; i++){
80108e5e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e62:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e69:	76 af                	jbe    80108e1a <freevm+0x46>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e6e:	89 04 24             	mov    %eax,(%esp)
80108e71:	e8 14 a3 ff ff       	call   8010318a <kfree>

}
80108e76:	c9                   	leave  
80108e77:	c3                   	ret    

80108e78 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e78:	55                   	push   %ebp
80108e79:	89 e5                	mov    %esp,%ebp
80108e7b:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e7e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e85:	00 
80108e86:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e89:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e8d:	8b 45 08             	mov    0x8(%ebp),%eax
80108e90:	89 04 24             	mov    %eax,(%esp)
80108e93:	e8 e5 f5 ff ff       	call   8010847d <walkpgdir>
80108e98:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108e9b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e9f:	75 0c                	jne    80108ead <clearpteu+0x35>
    panic("clearpteu");
80108ea1:	c7 04 24 c5 a3 10 80 	movl   $0x8010a3c5,(%esp)
80108ea8:	e8 8d 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eb0:	8b 00                	mov    (%eax),%eax
80108eb2:	83 e0 fb             	and    $0xfffffffb,%eax
80108eb5:	89 c2                	mov    %eax,%edx
80108eb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eba:	89 10                	mov    %edx,(%eax)
}
80108ebc:	c9                   	leave  
80108ebd:	c3                   	ret    

80108ebe <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, struct proc* np)
{
80108ebe:	55                   	push   %ebp
80108ebf:	89 e5                	mov    %esp,%ebp
80108ec1:	53                   	push   %ebx
80108ec2:	83 ec 44             	sub    $0x44,%esp
  // }
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;
  uint j = 0;
80108ec5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  np->memoryPagesCounter = 0;
80108ecc:	8b 45 10             	mov    0x10(%ebp),%eax
80108ecf:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80108ed6:	00 00 00 
  np->swapedPagesCounter = 0;
80108ed9:	8b 45 10             	mov    0x10(%ebp),%eax
80108edc:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80108ee3:	00 00 00 
  np->numOfPages = proc->numOfPages;
80108ee6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80108eec:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80108ef2:	8b 45 10             	mov    0x10(%ebp),%eax
80108ef5:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
  if((d = setupkvm()) == 0)
80108efb:	e8 b7 f6 ff ff       	call   801085b7 <setupkvm>
80108f00:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f03:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f07:	75 0a                	jne    80108f13 <copyuvm+0x55>
    return 0;
80108f09:	b8 00 00 00 00       	mov    $0x0,%eax
80108f0e:	e9 88 02 00 00       	jmp    8010919b <copyuvm+0x2dd>
  for(i = 0; i < sz; i += PGSIZE){
80108f13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f1a:	e9 b2 01 00 00       	jmp    801090d1 <copyuvm+0x213>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108f1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f29:	00 
80108f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f2e:	8b 45 08             	mov    0x8(%ebp),%eax
80108f31:	89 04 24             	mov    %eax,(%esp)
80108f34:	e8 44 f5 ff ff       	call   8010847d <walkpgdir>
80108f39:	89 45 e8             	mov    %eax,-0x18(%ebp)
80108f3c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f40:	75 0c                	jne    80108f4e <copyuvm+0x90>
      panic("copyuvm: pte should exist");
80108f42:	c7 04 24 cf a3 10 80 	movl   $0x8010a3cf,(%esp)
80108f49:	e8 ec 75 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108f4e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f51:	8b 00                	mov    (%eax),%eax
80108f53:	83 e0 01             	and    $0x1,%eax
80108f56:	85 c0                	test   %eax,%eax
80108f58:	75 0c                	jne    80108f66 <copyuvm+0xa8>
      panic("copyuvm: page not present");
80108f5a:	c7 04 24 e9 a3 10 80 	movl   $0x8010a3e9,(%esp)
80108f61:	e8 d4 75 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108f66:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f69:	8b 00                	mov    (%eax),%eax
80108f6b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f70:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    flags = PTE_FLAGS(*pte);
80108f73:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f76:	8b 00                	mov    (%eax),%eax
80108f78:	25 ff 0f 00 00       	and    $0xfff,%eax
80108f7d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80108f80:	e8 c7 a2 ff ff       	call   8010324c <kalloc>
80108f85:	89 45 dc             	mov    %eax,-0x24(%ebp)
80108f88:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80108f8c:	75 05                	jne    80108f93 <copyuvm+0xd5>
      goto bad;
80108f8e:	e9 f0 01 00 00       	jmp    80109183 <copyuvm+0x2c5>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108f93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108f96:	89 04 24             	mov    %eax,(%esp)
80108f99:	e8 5c f0 ff ff       	call   80107ffa <p2v>
80108f9e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fa5:	00 
80108fa6:	89 44 24 04          	mov    %eax,0x4(%esp)
80108faa:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fad:	89 04 24             	mov    %eax,(%esp)
80108fb0:	e8 23 cb ff ff       	call   80105ad8 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108fb5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
80108fb8:	8b 45 dc             	mov    -0x24(%ebp),%eax
80108fbb:	89 04 24             	mov    %eax,(%esp)
80108fbe:	e8 2a f0 ff ff       	call   80107fed <v2p>
80108fc3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108fc6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108fca:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108fce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fd5:	00 
80108fd6:	89 54 24 04          	mov    %edx,0x4(%esp)
80108fda:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108fdd:	89 04 24             	mov    %eax,(%esp)
80108fe0:	e8 3a f5 ff ff       	call   8010851f <mappages>
80108fe5:	85 c0                	test   %eax,%eax
80108fe7:	79 05                	jns    80108fee <copyuvm+0x130>
      goto bad;
80108fe9:	e9 95 01 00 00       	jmp    80109183 <copyuvm+0x2c5>
    // if(*pte & PTE_PG)
    //   *pte &= ~PTE_PG;
    np->pagesMetaData[j].va = (char *) i;
80108fee:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80108ff1:	8b 5d 10             	mov    0x10(%ebp),%ebx
80108ff4:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108ff7:	89 d0                	mov    %edx,%eax
80108ff9:	c1 e0 02             	shl    $0x2,%eax
80108ffc:	01 d0                	add    %edx,%eax
80108ffe:	c1 e0 02             	shl    $0x2,%eax
80109001:	01 d8                	add    %ebx,%eax
80109003:	05 90 00 00 00       	add    $0x90,%eax
80109008:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].isPhysical = 1;
8010900a:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010900d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109010:	89 d0                	mov    %edx,%eax
80109012:	c1 e0 02             	shl    $0x2,%eax
80109015:	01 d0                	add    %edx,%eax
80109017:	c1 e0 02             	shl    $0x2,%eax
8010901a:	01 c8                	add    %ecx,%eax
8010901c:	05 94 00 00 00       	add    $0x94,%eax
80109021:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
80109027:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010902a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010902d:	89 d0                	mov    %edx,%eax
8010902f:	c1 e0 02             	shl    $0x2,%eax
80109032:	01 d0                	add    %edx,%eax
80109034:	c1 e0 02             	shl    $0x2,%eax
80109037:	01 c8                	add    %ecx,%eax
80109039:	05 98 00 00 00       	add    $0x98,%eax
8010903e:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = proc->pagesMetaData[j].count;
80109044:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010904b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010904e:	89 d0                	mov    %edx,%eax
80109050:	c1 e0 02             	shl    $0x2,%eax
80109053:	01 d0                	add    %edx,%eax
80109055:	c1 e0 02             	shl    $0x2,%eax
80109058:	01 c8                	add    %ecx,%eax
8010905a:	05 9c 00 00 00       	add    $0x9c,%eax
8010905f:	8b 08                	mov    (%eax),%ecx
80109061:	8b 5d 10             	mov    0x10(%ebp),%ebx
80109064:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109067:	89 d0                	mov    %edx,%eax
80109069:	c1 e0 02             	shl    $0x2,%eax
8010906c:	01 d0                	add    %edx,%eax
8010906e:	c1 e0 02             	shl    $0x2,%eax
80109071:	01 d8                	add    %ebx,%eax
80109073:	05 9c 00 00 00       	add    $0x9c,%eax
80109078:	89 08                	mov    %ecx,(%eax)
    np->pagesMetaData[j].lru = proc->pagesMetaData[j].lru;
8010907a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109081:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109084:	89 d0                	mov    %edx,%eax
80109086:	c1 e0 02             	shl    $0x2,%eax
80109089:	01 d0                	add    %edx,%eax
8010908b:	c1 e0 02             	shl    $0x2,%eax
8010908e:	01 c8                	add    %ecx,%eax
80109090:	05 a0 00 00 00       	add    $0xa0,%eax
80109095:	0f b6 08             	movzbl (%eax),%ecx
80109098:	8b 5d 10             	mov    0x10(%ebp),%ebx
8010909b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010909e:	89 d0                	mov    %edx,%eax
801090a0:	c1 e0 02             	shl    $0x2,%eax
801090a3:	01 d0                	add    %edx,%eax
801090a5:	c1 e0 02             	shl    $0x2,%eax
801090a8:	01 d8                	add    %ebx,%eax
801090aa:	05 a0 00 00 00       	add    $0xa0,%eax
801090af:	88 08                	mov    %cl,(%eax)
    np->memoryPagesCounter++;
801090b1:	8b 45 10             	mov    0x10(%ebp),%eax
801090b4:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801090ba:	8d 50 01             	lea    0x1(%eax),%edx
801090bd:	8b 45 10             	mov    0x10(%ebp),%eax
801090c0:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
    j++;
801090c6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  np->memoryPagesCounter = 0;
  np->swapedPagesCounter = 0;
  np->numOfPages = proc->numOfPages;
  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801090ca:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090d4:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090d7:	0f 82 42 fe ff ff    	jb     80108f1f <copyuvm+0x61>
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
801090dd:	e9 92 00 00 00       	jmp    80109174 <copyuvm+0x2b6>
    np->pagesMetaData[j].va = (char *) -1;
801090e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
801090e5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090e8:	89 d0                	mov    %edx,%eax
801090ea:	c1 e0 02             	shl    $0x2,%eax
801090ed:	01 d0                	add    %edx,%eax
801090ef:	c1 e0 02             	shl    $0x2,%eax
801090f2:	01 c8                	add    %ecx,%eax
801090f4:	05 90 00 00 00       	add    $0x90,%eax
801090f9:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].isPhysical = 0;
801090ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109102:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109105:	89 d0                	mov    %edx,%eax
80109107:	c1 e0 02             	shl    $0x2,%eax
8010910a:	01 d0                	add    %edx,%eax
8010910c:	c1 e0 02             	shl    $0x2,%eax
8010910f:	01 c8                	add    %ecx,%eax
80109111:	05 94 00 00 00       	add    $0x94,%eax
80109116:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].fileOffset = -1;
8010911c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010911f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109122:	89 d0                	mov    %edx,%eax
80109124:	c1 e0 02             	shl    $0x2,%eax
80109127:	01 d0                	add    %edx,%eax
80109129:	c1 e0 02             	shl    $0x2,%eax
8010912c:	01 c8                	add    %ecx,%eax
8010912e:	05 98 00 00 00       	add    $0x98,%eax
80109133:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
    np->pagesMetaData[j].count = 0;
80109139:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010913c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010913f:	89 d0                	mov    %edx,%eax
80109141:	c1 e0 02             	shl    $0x2,%eax
80109144:	01 d0                	add    %edx,%eax
80109146:	c1 e0 02             	shl    $0x2,%eax
80109149:	01 c8                	add    %ecx,%eax
8010914b:	05 9c 00 00 00       	add    $0x9c,%eax
80109150:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    np->pagesMetaData[j].lru = 0x80;
80109156:	8b 4d 10             	mov    0x10(%ebp),%ecx
80109159:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010915c:	89 d0                	mov    %edx,%eax
8010915e:	c1 e0 02             	shl    $0x2,%eax
80109161:	01 d0                	add    %edx,%eax
80109163:	c1 e0 02             	shl    $0x2,%eax
80109166:	01 c8                	add    %ecx,%eax
80109168:	05 a0 00 00 00       	add    $0xa0,%eax
8010916d:	c6 00 80             	movb   $0x80,(%eax)
    j++;
  // for(k = 0; k < 30; k++){
  //     cprintf("i=%d va %x\n",k,np->pagesMetaData[k].va);
  // }
  }
  for(; j < 30; j++){
80109170:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80109174:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
80109178:	0f 86 64 ff ff ff    	jbe    801090e2 <copyuvm+0x224>
    np->pagesMetaData[j].isPhysical = 0;
    np->pagesMetaData[j].fileOffset = -1;
    np->pagesMetaData[j].count = 0;
    np->pagesMetaData[j].lru = 0x80;
  }
  return d;
8010917e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109181:	eb 18                	jmp    8010919b <copyuvm+0x2dd>

  bad:
  freevm(d,0);
80109183:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010918a:	00 
8010918b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010918e:	89 04 24             	mov    %eax,(%esp)
80109191:	e8 3e fc ff ff       	call   80108dd4 <freevm>
  return 0;
80109196:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010919b:	83 c4 44             	add    $0x44,%esp
8010919e:	5b                   	pop    %ebx
8010919f:	5d                   	pop    %ebp
801091a0:	c3                   	ret    

801091a1 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801091a1:	55                   	push   %ebp
801091a2:	89 e5                	mov    %esp,%ebp
801091a4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801091a7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091ae:	00 
801091af:	8b 45 0c             	mov    0xc(%ebp),%eax
801091b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801091b6:	8b 45 08             	mov    0x8(%ebp),%eax
801091b9:	89 04 24             	mov    %eax,(%esp)
801091bc:	e8 bc f2 ff ff       	call   8010847d <walkpgdir>
801091c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801091c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091c7:	8b 00                	mov    (%eax),%eax
801091c9:	83 e0 01             	and    $0x1,%eax
801091cc:	85 c0                	test   %eax,%eax
801091ce:	75 07                	jne    801091d7 <uva2ka+0x36>
    return 0;
801091d0:	b8 00 00 00 00       	mov    $0x0,%eax
801091d5:	eb 25                	jmp    801091fc <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801091d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091da:	8b 00                	mov    (%eax),%eax
801091dc:	83 e0 04             	and    $0x4,%eax
801091df:	85 c0                	test   %eax,%eax
801091e1:	75 07                	jne    801091ea <uva2ka+0x49>
    return 0;
801091e3:	b8 00 00 00 00       	mov    $0x0,%eax
801091e8:	eb 12                	jmp    801091fc <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801091ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091ed:	8b 00                	mov    (%eax),%eax
801091ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091f4:	89 04 24             	mov    %eax,(%esp)
801091f7:	e8 fe ed ff ff       	call   80107ffa <p2v>
}
801091fc:	c9                   	leave  
801091fd:	c3                   	ret    

801091fe <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801091fe:	55                   	push   %ebp
801091ff:	89 e5                	mov    %esp,%ebp
80109201:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109204:	8b 45 10             	mov    0x10(%ebp),%eax
80109207:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010920a:	e9 87 00 00 00       	jmp    80109296 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010920f:	8b 45 0c             	mov    0xc(%ebp),%eax
80109212:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109217:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010921a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010921d:	89 44 24 04          	mov    %eax,0x4(%esp)
80109221:	8b 45 08             	mov    0x8(%ebp),%eax
80109224:	89 04 24             	mov    %eax,(%esp)
80109227:	e8 75 ff ff ff       	call   801091a1 <uva2ka>
8010922c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010922f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109233:	75 07                	jne    8010923c <copyout+0x3e>
      return -1;
80109235:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010923a:	eb 69                	jmp    801092a5 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010923c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010923f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109242:	29 c2                	sub    %eax,%edx
80109244:	89 d0                	mov    %edx,%eax
80109246:	05 00 10 00 00       	add    $0x1000,%eax
8010924b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010924e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109251:	3b 45 14             	cmp    0x14(%ebp),%eax
80109254:	76 06                	jbe    8010925c <copyout+0x5e>
      n = len;
80109256:	8b 45 14             	mov    0x14(%ebp),%eax
80109259:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010925c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010925f:	8b 55 0c             	mov    0xc(%ebp),%edx
80109262:	29 c2                	sub    %eax,%edx
80109264:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109267:	01 c2                	add    %eax,%edx
80109269:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010926c:	89 44 24 08          	mov    %eax,0x8(%esp)
80109270:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109273:	89 44 24 04          	mov    %eax,0x4(%esp)
80109277:	89 14 24             	mov    %edx,(%esp)
8010927a:	e8 59 c8 ff ff       	call   80105ad8 <memmove>
    len -= n;
8010927f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109282:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109285:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109288:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010928b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010928e:	05 00 10 00 00       	add    $0x1000,%eax
80109293:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109296:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010929a:	0f 85 6f ff ff ff    	jne    8010920f <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801092a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092a5:	c9                   	leave  
801092a6:	c3                   	ret    

801092a7 <findNextOpenPage>:
// Blank page.

//find the next offset available for the new page
//store him there and return the offset
int
findNextOpenPage(char *a){
801092a7:	55                   	push   %ebp
801092a8:	89 e5                	mov    %esp,%ebp
801092aa:	83 ec 10             	sub    $0x10,%esp
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
801092ad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801092b4:	eb 55                	jmp    8010930b <findNextOpenPage+0x64>
    found = 1;
801092b6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092bd:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801092c4:	eb 2d                	jmp    801092f3 <findNextOpenPage+0x4c>
      if(proc->pagesMetaData[j].fileOffset == i){
801092c6:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801092cd:	8b 55 f8             	mov    -0x8(%ebp),%edx
801092d0:	89 d0                	mov    %edx,%eax
801092d2:	c1 e0 02             	shl    $0x2,%eax
801092d5:	01 d0                	add    %edx,%eax
801092d7:	c1 e0 02             	shl    $0x2,%eax
801092da:	01 c8                	add    %ecx,%eax
801092dc:	05 98 00 00 00       	add    $0x98,%eax
801092e1:	8b 00                	mov    (%eax),%eax
801092e3:	3b 45 fc             	cmp    -0x4(%ebp),%eax
801092e6:	75 07                	jne    801092ef <findNextOpenPage+0x48>
        found = 0;
801092e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
    found = 1;
    for(j = 0; j < PAGES_META_DATA_SIZE; j++){
801092ef:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801092f3:	83 7d f8 1d          	cmpl   $0x1d,-0x8(%ebp)
801092f7:	7e cd                	jle    801092c6 <findNextOpenPage+0x1f>
      if(proc->pagesMetaData[j].fileOffset == i){
        found = 0;
      }
    }
    if(found){// place the page in offset i
801092f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801092fd:	74 05                	je     80109304 <findNextOpenPage+0x5d>
      return i;
801092ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80109302:	eb 15                	jmp    80109319 <findNextOpenPage+0x72>
int
findNextOpenPage(char *a){
  int i;
  int j;
  int found;
  for(i = 0; i < PGSIZE*15; i+=PGSIZE){
80109304:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
8010930b:	81 7d fc ff ef 00 00 	cmpl   $0xefff,-0x4(%ebp)
80109312:	7e a2                	jle    801092b6 <findNextOpenPage+0xf>
    }
    if(found){// place the page in offset i
      return i;
    }
  }
  return -1;
80109314:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80109319:	c9                   	leave  
8010931a:	c3                   	ret    

8010931b <existOnDisc>:

int
existOnDisc(uint faultingPage){
8010931b:	55                   	push   %ebp
8010931c:	89 e5                	mov    %esp,%ebp
8010931e:	83 ec 28             	sub    $0x28,%esp
  cprintf("faulting page: %x\n",faultingPage);
80109321:	8b 45 08             	mov    0x8(%ebp),%eax
80109324:	89 44 24 04          	mov    %eax,0x4(%esp)
80109328:	c7 04 24 03 a4 10 80 	movl   $0x8010a403,(%esp)
8010932f:	e8 6c 70 ff ff       	call   801003a0 <cprintf>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
80109334:	8b 55 08             	mov    0x8(%ebp),%edx
80109337:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010933d:	8b 40 04             	mov    0x4(%eax),%eax
80109340:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109347:	00 
80109348:	89 54 24 04          	mov    %edx,0x4(%esp)
8010934c:	89 04 24             	mov    %eax,(%esp)
8010934f:	e8 29 f1 ff ff       	call   8010847d <walkpgdir>
80109354:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int found = 0;
80109357:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int i;
  for(i = 0; i < 30; i++){
8010935e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80109365:	e9 8e 00 00 00       	jmp    801093f8 <existOnDisc+0xdd>
    if(proc->pagesMetaData[i].va != (char *) -1){
8010936a:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109371:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109374:	89 d0                	mov    %edx,%eax
80109376:	c1 e0 02             	shl    $0x2,%eax
80109379:	01 d0                	add    %edx,%eax
8010937b:	c1 e0 02             	shl    $0x2,%eax
8010937e:	01 c8                	add    %ecx,%eax
80109380:	05 90 00 00 00       	add    $0x90,%eax
80109385:	8b 00                	mov    (%eax),%eax
80109387:	83 f8 ff             	cmp    $0xffffffff,%eax
8010938a:	74 68                	je     801093f4 <existOnDisc+0xd9>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
8010938c:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109393:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109396:	89 d0                	mov    %edx,%eax
80109398:	c1 e0 02             	shl    $0x2,%eax
8010939b:	01 d0                	add    %edx,%eax
8010939d:	c1 e0 02             	shl    $0x2,%eax
801093a0:	01 c8                	add    %ecx,%eax
801093a2:	05 90 00 00 00       	add    $0x90,%eax
801093a7:	8b 00                	mov    (%eax),%eax
801093a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093ae:	3b 45 08             	cmp    0x8(%ebp),%eax
801093b1:	77 41                	ja     801093f4 <existOnDisc+0xd9>
801093b3:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801093ba:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093bd:	89 d0                	mov    %edx,%eax
801093bf:	c1 e0 02             	shl    $0x2,%eax
801093c2:	01 d0                	add    %edx,%eax
801093c4:	c1 e0 02             	shl    $0x2,%eax
801093c7:	01 c8                	add    %ecx,%eax
801093c9:	05 90 00 00 00       	add    $0x90,%eax
801093ce:	8b 00                	mov    (%eax),%eax
801093d0:	05 ff 0f 00 00       	add    $0xfff,%eax
801093d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093da:	3b 45 08             	cmp    0x8(%ebp),%eax
801093dd:	72 15                	jb     801093f4 <existOnDisc+0xd9>
801093df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093e2:	8b 00                	mov    (%eax),%eax
801093e4:	25 00 02 00 00       	and    $0x200,%eax
801093e9:	85 c0                	test   %eax,%eax
801093eb:	74 07                	je     801093f4 <existOnDisc+0xd9>
        found = 1;
801093ed:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  cprintf("faulting page: %x\n",faultingPage);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir,(char *) faultingPage,0);
  int found = 0;
  int i;
  for(i = 0; i < 30; i++){
801093f4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801093f8:	83 7d f0 1d          	cmpl   $0x1d,-0x10(%ebp)
801093fc:	0f 8e 68 ff ff ff    	jle    8010936a <existOnDisc+0x4f>
    if(proc->pagesMetaData[i].va != (char *) -1){
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG))
        found = 1;
    }
  }
  return found;
80109402:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80109405:	c9                   	leave  
80109406:	c3                   	ret    

80109407 <fixPage>:

void
fixPage(uint faultingPage){
80109407:	55                   	push   %ebp
80109408:	89 e5                	mov    %esp,%ebp
8010940a:	83 ec 38             	sub    $0x38,%esp
  int i;
  //char buf[PGSIZE];
  char *mem;
  //fix me
  mem = kalloc();
8010940d:	e8 3a 9e ff ff       	call   8010324c <kalloc>
80109412:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(mem == 0){
80109415:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109419:	75 0c                	jne    80109427 <fixPage+0x20>
    panic("no room, go away");
8010941b:	c7 04 24 16 a4 10 80 	movl   $0x8010a416,(%esp)
80109422:	e8 13 71 ff ff       	call   8010053a <panic>
  }
  memset(mem,0, PGSIZE);
80109427:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010942e:	00 
8010942f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109436:	00 
80109437:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010943a:	89 04 24             	mov    %eax,(%esp)
8010943d:	e8 c7 c5 ff ff       	call   80105a09 <memset>
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
80109442:	8b 55 08             	mov    0x8(%ebp),%edx
80109445:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010944b:	8b 40 04             	mov    0x4(%eax),%eax
8010944e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109455:	00 
80109456:	89 54 24 04          	mov    %edx,0x4(%esp)
8010945a:	89 04 24             	mov    %eax,(%esp)
8010945d:	e8 1b f0 ff ff       	call   8010847d <walkpgdir>
80109462:	89 45 ec             	mov    %eax,-0x14(%ebp)
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80109465:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010946c:	e9 a6 01 00 00       	jmp    80109617 <fixPage+0x210>
    if(proc->pagesMetaData[i].va != (char *) -1){
80109471:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109478:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010947b:	89 d0                	mov    %edx,%eax
8010947d:	c1 e0 02             	shl    $0x2,%eax
80109480:	01 d0                	add    %edx,%eax
80109482:	c1 e0 02             	shl    $0x2,%eax
80109485:	01 c8                	add    %ecx,%eax
80109487:	05 90 00 00 00       	add    $0x90,%eax
8010948c:	8b 00                	mov    (%eax),%eax
8010948e:	83 f8 ff             	cmp    $0xffffffff,%eax
80109491:	0f 84 7c 01 00 00    	je     80109613 <fixPage+0x20c>
      if((PGROUNDDOWN((uint)proc->pagesMetaData[i].va) <= faultingPage) && (PGROUNDUP((uint)proc->pagesMetaData[i].va) >= faultingPage) && (*pte & PTE_PG)){
80109497:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010949e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094a1:	89 d0                	mov    %edx,%eax
801094a3:	c1 e0 02             	shl    $0x2,%eax
801094a6:	01 d0                	add    %edx,%eax
801094a8:	c1 e0 02             	shl    $0x2,%eax
801094ab:	01 c8                	add    %ecx,%eax
801094ad:	05 90 00 00 00       	add    $0x90,%eax
801094b2:	8b 00                	mov    (%eax),%eax
801094b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094b9:	3b 45 08             	cmp    0x8(%ebp),%eax
801094bc:	0f 87 51 01 00 00    	ja     80109613 <fixPage+0x20c>
801094c2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801094c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094cc:	89 d0                	mov    %edx,%eax
801094ce:	c1 e0 02             	shl    $0x2,%eax
801094d1:	01 d0                	add    %edx,%eax
801094d3:	c1 e0 02             	shl    $0x2,%eax
801094d6:	01 c8                	add    %ecx,%eax
801094d8:	05 90 00 00 00       	add    $0x90,%eax
801094dd:	8b 00                	mov    (%eax),%eax
801094df:	05 ff 0f 00 00       	add    $0xfff,%eax
801094e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094e9:	3b 45 08             	cmp    0x8(%ebp),%eax
801094ec:	0f 82 21 01 00 00    	jb     80109613 <fixPage+0x20c>
801094f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094f5:	8b 00                	mov    (%eax),%eax
801094f7:	25 00 02 00 00       	and    $0x200,%eax
801094fc:	85 c0                	test   %eax,%eax
801094fe:	0f 84 0f 01 00 00    	je     80109613 <fixPage+0x20c>
        cprintf("found %d\n",proc->pagesMetaData[i].fileOffset);
80109504:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010950b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010950e:	89 d0                	mov    %edx,%eax
80109510:	c1 e0 02             	shl    $0x2,%eax
80109513:	01 d0                	add    %edx,%eax
80109515:	c1 e0 02             	shl    $0x2,%eax
80109518:	01 c8                	add    %ecx,%eax
8010951a:	05 98 00 00 00       	add    $0x98,%eax
8010951f:	8b 00                	mov    (%eax),%eax
80109521:	89 44 24 04          	mov    %eax,0x4(%esp)
80109525:	c7 04 24 27 a4 10 80 	movl   $0x8010a427,(%esp)
8010952c:	e8 6f 6e ff ff       	call   801003a0 <cprintf>
        if(readFromSwapFile(proc,mem,proc->pagesMetaData[i].fileOffset,PGSIZE) == -1)
80109531:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109538:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010953b:	89 d0                	mov    %edx,%eax
8010953d:	c1 e0 02             	shl    $0x2,%eax
80109540:	01 d0                	add    %edx,%eax
80109542:	c1 e0 02             	shl    $0x2,%eax
80109545:	01 c8                	add    %ecx,%eax
80109547:	05 98 00 00 00       	add    $0x98,%eax
8010954c:	8b 00                	mov    (%eax),%eax
8010954e:	89 c2                	mov    %eax,%edx
80109550:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109556:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
8010955d:	00 
8010955e:	89 54 24 08          	mov    %edx,0x8(%esp)
80109562:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109565:	89 54 24 04          	mov    %edx,0x4(%esp)
80109569:	89 04 24             	mov    %eax,(%esp)
8010956c:	e8 0f 94 ff ff       	call   80102980 <readFromSwapFile>
80109571:	83 f8 ff             	cmp    $0xffffffff,%eax
80109574:	75 0c                	jne    80109582 <fixPage+0x17b>
          panic("nothing read");
80109576:	c7 04 24 31 a4 10 80 	movl   $0x8010a431,(%esp)
8010957d:	e8 b8 6f ff ff       	call   8010053a <panic>
        if(proc->memoryPagesCounter >= 15 && SCHEDFLAG != 1){  //need to swap out
80109582:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109588:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
8010958e:	83 f8 0e             	cmp    $0xe,%eax
80109591:	76 1e                	jbe    801095b1 <fixPage+0x1aa>
          swapOut();
80109593:	e8 d2 00 00 00       	call   8010966a <swapOut>
          lcr3(v2p(proc->pgdir));
80109598:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010959e:	8b 40 04             	mov    0x4(%eax),%eax
801095a1:	89 04 24             	mov    %eax,(%esp)
801095a4:	e8 44 ea ff ff       	call   80107fed <v2p>
801095a9:	89 04 24             	mov    %eax,(%esp)
801095ac:	e8 31 ea ff ff       	call   80107fe2 <lcr3>
        }
        proc->pagesMetaData[i].isPhysical = 1;
801095b1:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095bb:	89 d0                	mov    %edx,%eax
801095bd:	c1 e0 02             	shl    $0x2,%eax
801095c0:	01 d0                	add    %edx,%eax
801095c2:	c1 e0 02             	shl    $0x2,%eax
801095c5:	01 c8                	add    %ecx,%eax
801095c7:	05 94 00 00 00       	add    $0x94,%eax
801095cc:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
        proc->pagesMetaData[i].lru = 0x80;  
801095d2:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095dc:	89 d0                	mov    %edx,%eax
801095de:	c1 e0 02             	shl    $0x2,%eax
801095e1:	01 d0                	add    %edx,%eax
801095e3:	c1 e0 02             	shl    $0x2,%eax
801095e6:	01 c8                	add    %ecx,%eax
801095e8:	05 a0 00 00 00       	add    $0xa0,%eax
801095ed:	c6 00 80             	movb   $0x80,(%eax)
        proc->pagesMetaData[i].fileOffset = -1;
801095f0:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801095f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095fa:	89 d0                	mov    %edx,%eax
801095fc:	c1 e0 02             	shl    $0x2,%eax
801095ff:	01 d0                	add    %edx,%eax
80109601:	c1 e0 02             	shl    $0x2,%eax
80109604:	01 c8                	add    %ecx,%eax
80109606:	05 98 00 00 00       	add    $0x98,%eax
8010960b:	c7 00 ff ff ff ff    	movl   $0xffffffff,(%eax)
        break;
80109611:	eb 0e                	jmp    80109621 <fixPage+0x21a>
  }
  memset(mem,0, PGSIZE);
  pte_t *pte;
  pte = walkpgdir(proc->pgdir, (char*)faultingPage, 0);
    //find the data corresponding to faultingPage
  for(i = 0; i < PAGES_META_DATA_SIZE; i++){
80109613:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109617:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
8010961b:	0f 8e 50 fe ff ff    	jle    80109471 <fixPage+0x6a>
        break;
      }
    }
  }    
    //memmove(mem,buf,PGSIZE);
    *pte &= ~PTE_PG;  //turn off flag
80109621:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109624:	8b 00                	mov    (%eax),%eax
80109626:	80 e4 fd             	and    $0xfd,%ah
80109629:	89 c2                	mov    %eax,%edx
8010962b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010962e:	89 10                	mov    %edx,(%eax)
    mappages(proc->pgdir,(char *)faultingPage,PGSIZE,v2p(mem),PTE_W|PTE_U); 
80109630:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109633:	89 04 24             	mov    %eax,(%esp)
80109636:	e8 b2 e9 ff ff       	call   80107fed <v2p>
8010963b:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010963e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109645:	8b 52 04             	mov    0x4(%edx),%edx
80109648:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010964f:	00 
80109650:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109654:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010965b:	00 
8010965c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80109660:	89 14 24             	mov    %edx,(%esp)
80109663:	e8 b7 ee ff ff       	call   8010851f <mappages>
    //memmove(buf,0,PGSIZE);
  }
80109668:	c9                   	leave  
80109669:	c3                   	ret    

8010966a <swapOut>:

//swap out a page from proc.
  void swapOut(){
8010966a:	55                   	push   %ebp
8010966b:	89 e5                	mov    %esp,%ebp
8010966d:	53                   	push   %ebx
8010966e:	83 ec 34             	sub    $0x34,%esp
    int j;
    int offset;
    //char buf[PGSIZE];
    pte_t *pte;
    uint pa;
    int index = -1;
80109671:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
    int min = proc->numOfPages+3;
80109678:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010967e:	8b 80 e8 02 00 00    	mov    0x2e8(%eax),%eax
80109684:	83 c0 03             	add    $0x3,%eax
80109687:	89 45 e8             	mov    %eax,-0x18(%ebp)
    char minNFU = 0x80;
8010968a:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        }
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
8010968e:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
80109692:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
80109699:	eb 6f                	jmp    8010970a <swapOut+0xa0>
          //cprintf("NFU: %d j=%d\n", minNFU, j);
          //cprintf("checking entry %d minNFU=%d curr=%d %d\n",j, minNFU, proc->pagesMetaData[j].lru, (proc->pagesMetaData[j].lru >= minNFU));
          if (proc->pagesMetaData[j].isPhysical &&  proc->pagesMetaData[j].lru >= minNFU){
8010969b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096a5:	89 d0                	mov    %edx,%eax
801096a7:	c1 e0 02             	shl    $0x2,%eax
801096aa:	01 d0                	add    %edx,%eax
801096ac:	c1 e0 02             	shl    $0x2,%eax
801096af:	01 c8                	add    %ecx,%eax
801096b1:	05 94 00 00 00       	add    $0x94,%eax
801096b6:	8b 00                	mov    (%eax),%eax
801096b8:	85 c0                	test   %eax,%eax
801096ba:	74 4a                	je     80109706 <swapOut+0x9c>
801096bc:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096c6:	89 d0                	mov    %edx,%eax
801096c8:	c1 e0 02             	shl    $0x2,%eax
801096cb:	01 d0                	add    %edx,%eax
801096cd:	c1 e0 02             	shl    $0x2,%eax
801096d0:	01 c8                	add    %ecx,%eax
801096d2:	05 a0 00 00 00       	add    $0xa0,%eax
801096d7:	0f b6 00             	movzbl (%eax),%eax
801096da:	3a 45 ef             	cmp    -0x11(%ebp),%al
801096dd:	7c 27                	jl     80109706 <swapOut+0x9c>
            minNFU = proc->pagesMetaData[j].lru;
801096df:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801096e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096e9:	89 d0                	mov    %edx,%eax
801096eb:	c1 e0 02             	shl    $0x2,%eax
801096ee:	01 d0                	add    %edx,%eax
801096f0:	c1 e0 02             	shl    $0x2,%eax
801096f3:	01 c8                	add    %ecx,%eax
801096f5:	05 a0 00 00 00       	add    $0xa0,%eax
801096fa:	0f b6 00             	movzbl (%eax),%eax
801096fd:	88 45 ef             	mov    %al,-0x11(%ebp)
            index = j;
80109700:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109703:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;

      case 4:  //NFU
        minNFU = 0x80;
        for(j=3; j<30; j++){  //find the oldest page by nfu flag
80109706:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010970a:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
8010970e:	7e 8b                	jle    8010969b <swapOut+0x31>
            minNFU = proc->pagesMetaData[j].lru;
            index = j;
          }
        }
        //cprintf("choose: %d with virtual add %x\n", index, proc->pagesMetaData[index].va);
        break;
80109710:	90                   	nop
      }


    if(proc->pagesMetaData[index].isPhysical){//swap him out!
80109711:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109718:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010971b:	89 d0                	mov    %edx,%eax
8010971d:	c1 e0 02             	shl    $0x2,%eax
80109720:	01 d0                	add    %edx,%eax
80109722:	c1 e0 02             	shl    $0x2,%eax
80109725:	01 c8                	add    %ecx,%eax
80109727:	05 94 00 00 00       	add    $0x94,%eax
8010972c:	8b 00                	mov    (%eax),%eax
8010972e:	85 c0                	test   %eax,%eax
80109730:	0f 84 c8 01 00 00    	je     801098fe <swapOut+0x294>
      //cprintf("choose to swap out %x\n",proc->pagesMetaData[index].va);
      proc->swappedOutCounter++;
80109736:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010973c:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80109742:	83 c2 01             	add    $0x1,%edx
80109745:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
      offset = findNextOpenPage(proc->pagesMetaData[index].va);
8010974b:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109752:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109755:	89 d0                	mov    %edx,%eax
80109757:	c1 e0 02             	shl    $0x2,%eax
8010975a:	01 d0                	add    %edx,%eax
8010975c:	c1 e0 02             	shl    $0x2,%eax
8010975f:	01 c8                	add    %ecx,%eax
80109761:	05 90 00 00 00       	add    $0x90,%eax
80109766:	8b 00                	mov    (%eax),%eax
80109768:	89 04 24             	mov    %eax,(%esp)
8010976b:	e8 37 fb ff ff       	call   801092a7 <findNextOpenPage>
80109770:	89 45 e4             	mov    %eax,-0x1c(%ebp)

      pte = walkpgdir(proc->pgdir,proc->pagesMetaData[index].va,0);
80109773:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
8010977a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010977d:	89 d0                	mov    %edx,%eax
8010977f:	c1 e0 02             	shl    $0x2,%eax
80109782:	01 d0                	add    %edx,%eax
80109784:	c1 e0 02             	shl    $0x2,%eax
80109787:	01 c8                	add    %ecx,%eax
80109789:	05 90 00 00 00       	add    $0x90,%eax
8010978e:	8b 10                	mov    (%eax),%edx
80109790:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109796:	8b 40 04             	mov    0x4(%eax),%eax
80109799:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801097a0:	00 
801097a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801097a5:	89 04 24             	mov    %eax,(%esp)
801097a8:	e8 d0 ec ff ff       	call   8010847d <walkpgdir>
801097ad:	89 45 e0             	mov    %eax,-0x20(%ebp)
      //cprintf("after walkpgdir\n");
      if(!(*pte & PTE_PG)){
801097b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801097b3:	8b 00                	mov    (%eax),%eax
801097b5:	25 00 02 00 00       	and    $0x200,%eax
801097ba:	85 c0                	test   %eax,%eax
801097bc:	75 0f                	jne    801097cd <swapOut+0x163>
        *pte |= PTE_PG; //turn on    
801097be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801097c1:	8b 00                	mov    (%eax),%eax
801097c3:	80 cc 02             	or     $0x2,%ah
801097c6:	89 c2                	mov    %eax,%edx
801097c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801097cb:	89 10                	mov    %edx,(%eax)
      }
      //cprintf("after setting PG\n");
      proc->pagesMetaData[index].fileOffset = offset;
801097cd:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097d4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097d7:	89 d0                	mov    %edx,%eax
801097d9:	c1 e0 02             	shl    $0x2,%eax
801097dc:	01 d0                	add    %edx,%eax
801097de:	c1 e0 02             	shl    $0x2,%eax
801097e1:	01 c8                	add    %ecx,%eax
801097e3:	8d 90 98 00 00 00    	lea    0x98(%eax),%edx
801097e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801097ec:	89 02                	mov    %eax,(%edx)
      cprintf("choose %x with offset: %d\n",proc->pagesMetaData[index].va,proc->pagesMetaData[index].fileOffset);
801097ee:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
801097f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097f8:	89 d0                	mov    %edx,%eax
801097fa:	c1 e0 02             	shl    $0x2,%eax
801097fd:	01 d0                	add    %edx,%eax
801097ff:	c1 e0 02             	shl    $0x2,%eax
80109802:	01 c8                	add    %ecx,%eax
80109804:	05 98 00 00 00       	add    $0x98,%eax
80109809:	8b 08                	mov    (%eax),%ecx
8010980b:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109812:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109815:	89 d0                	mov    %edx,%eax
80109817:	c1 e0 02             	shl    $0x2,%eax
8010981a:	01 d0                	add    %edx,%eax
8010981c:	c1 e0 02             	shl    $0x2,%eax
8010981f:	01 d8                	add    %ebx,%eax
80109821:	05 90 00 00 00       	add    $0x90,%eax
80109826:	8b 00                	mov    (%eax),%eax
80109828:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010982c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109830:	c7 04 24 3e a4 10 80 	movl   $0x8010a43e,(%esp)
80109837:	e8 64 6b ff ff       	call   801003a0 <cprintf>

      proc->pagesMetaData[index].isPhysical = 0;
8010983c:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109843:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109846:	89 d0                	mov    %edx,%eax
80109848:	c1 e0 02             	shl    $0x2,%eax
8010984b:	01 d0                	add    %edx,%eax
8010984d:	c1 e0 02             	shl    $0x2,%eax
80109850:	01 c8                	add    %ecx,%eax
80109852:	05 94 00 00 00       	add    $0x94,%eax
80109857:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      proc->pagesMetaData[index].count = proc->numOfPages;
8010985d:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80109864:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010986a:	8b 88 e8 02 00 00    	mov    0x2e8(%eax),%ecx
80109870:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109873:	89 d0                	mov    %edx,%eax
80109875:	c1 e0 02             	shl    $0x2,%eax
80109878:	01 d0                	add    %edx,%eax
8010987a:	c1 e0 02             	shl    $0x2,%eax
8010987d:	01 d8                	add    %ebx,%eax
8010987f:	05 9c 00 00 00       	add    $0x9c,%eax
80109884:	89 08                	mov    %ecx,(%eax)
      proc->numOfPages++;
80109886:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010988c:	8b 90 e8 02 00 00    	mov    0x2e8(%eax),%edx
80109892:	83 c2 01             	add    $0x1,%edx
80109895:	89 90 e8 02 00 00    	mov    %edx,0x2e8(%eax)
      //memmove(buf,proc->pagesMetaData[index].va,PGSIZE);
      //cprintf("after memmove\n");
      writeToSwapFile(proc,p2v(PTE_ADDR(*pte)),offset,PGSIZE);
8010989b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010989e:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098a1:	8b 00                	mov    (%eax),%eax
801098a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801098a8:	89 04 24             	mov    %eax,(%esp)
801098ab:	e8 4a e7 ff ff       	call   80107ffa <p2v>
801098b0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801098b7:	c7 44 24 0c 00 10 00 	movl   $0x1000,0xc(%esp)
801098be:	00 
801098bf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801098c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801098c7:	89 14 24             	mov    %edx,(%esp)
801098ca:	e8 81 90 ff ff       	call   80102950 <writeToSwapFile>
      //cprintf("after write\n");
      pa = PTE_ADDR(*pte);
801098cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098d2:	8b 00                	mov    (%eax),%eax
801098d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801098d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
      if(pa != 0)
801098dc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801098e0:	74 13                	je     801098f5 <swapOut+0x28b>
        kfree(p2v(pa)); 
801098e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801098e5:	89 04 24             	mov    %eax,(%esp)
801098e8:	e8 0d e7 ff ff       	call   80107ffa <p2v>
801098ed:	89 04 24             	mov    %eax,(%esp)
801098f0:	e8 95 98 ff ff       	call   8010318a <kfree>
      *pte = 0 | PTE_W | PTE_U | PTE_PG;
801098f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801098f8:	c7 00 06 02 00 00    	movl   $0x206,(%eax)
    }
  }
801098fe:	83 c4 34             	add    $0x34,%esp
80109901:	5b                   	pop    %ebx
80109902:	5d                   	pop    %ebp
80109903:	c3                   	ret    

80109904 <updateAge>:

  //updates the age of the pages in RAM memory. done on every clock interupt 
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
80109904:	55                   	push   %ebp
80109905:	89 e5                	mov    %esp,%ebp
80109907:	53                   	push   %ebx
80109908:	83 ec 24             	sub    $0x24,%esp
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
8010990b:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
80109912:	e9 c8 00 00 00       	jmp    801099df <updateAge+0xdb>
      if(proc->pagesMetaData[i].isPhysical && proc->pagesMetaData[i].va!=0){ //only if on RAM
80109917:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010991a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010991d:	89 d0                	mov    %edx,%eax
8010991f:	c1 e0 02             	shl    $0x2,%eax
80109922:	01 d0                	add    %edx,%eax
80109924:	c1 e0 02             	shl    $0x2,%eax
80109927:	01 c8                	add    %ecx,%eax
80109929:	05 94 00 00 00       	add    $0x94,%eax
8010992e:	8b 00                	mov    (%eax),%eax
80109930:	85 c0                	test   %eax,%eax
80109932:	0f 84 a3 00 00 00    	je     801099db <updateAge+0xd7>
80109938:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010993b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010993e:	89 d0                	mov    %edx,%eax
80109940:	c1 e0 02             	shl    $0x2,%eax
80109943:	01 d0                	add    %edx,%eax
80109945:	c1 e0 02             	shl    $0x2,%eax
80109948:	01 c8                	add    %ecx,%eax
8010994a:	05 90 00 00 00       	add    $0x90,%eax
8010994f:	8b 00                	mov    (%eax),%eax
80109951:	85 c0                	test   %eax,%eax
80109953:	0f 84 82 00 00 00    	je     801099db <updateAge+0xd7>
        proc->pagesMetaData[i].lru = proc->pagesMetaData[i].lru>>1;   //move a bit to the right
80109959:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010995c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010995f:	89 d0                	mov    %edx,%eax
80109961:	c1 e0 02             	shl    $0x2,%eax
80109964:	01 d0                	add    %edx,%eax
80109966:	c1 e0 02             	shl    $0x2,%eax
80109969:	01 c8                	add    %ecx,%eax
8010996b:	05 a0 00 00 00       	add    $0xa0,%eax
80109970:	0f b6 00             	movzbl (%eax),%eax
80109973:	d0 f8                	sar    %al
80109975:	89 c1                	mov    %eax,%ecx
80109977:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010997a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010997d:	89 d0                	mov    %edx,%eax
8010997f:	c1 e0 02             	shl    $0x2,%eax
80109982:	01 d0                	add    %edx,%eax
80109984:	c1 e0 02             	shl    $0x2,%eax
80109987:	01 d8                	add    %ebx,%eax
80109989:	05 a0 00 00 00       	add    $0xa0,%eax
8010998e:	88 08                	mov    %cl,(%eax)
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
80109990:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109993:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109996:	89 d0                	mov    %edx,%eax
80109998:	c1 e0 02             	shl    $0x2,%eax
8010999b:	01 d0                	add    %edx,%eax
8010999d:	c1 e0 02             	shl    $0x2,%eax
801099a0:	01 c8                	add    %ecx,%eax
801099a2:	05 90 00 00 00       	add    $0x90,%eax
801099a7:	8b 10                	mov    (%eax),%edx
801099a9:	8b 45 08             	mov    0x8(%ebp),%eax
801099ac:	8b 40 04             	mov    0x4(%eax),%eax
801099af:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801099b6:	00 
801099b7:	89 54 24 04          	mov    %edx,0x4(%esp)
801099bb:	89 04 24             	mov    %eax,(%esp)
801099be:	e8 ba ea ff ff       	call   8010847d <walkpgdir>
801099c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if(!(*pte & PTE_A)){
801099c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801099c9:	8b 00                	mov    (%eax),%eax
801099cb:	83 e0 20             	and    $0x20,%eax
801099ce:	85 c0                	test   %eax,%eax
801099d0:	75 09                	jne    801099db <updateAge+0xd7>
          *pte &= !PTE_A; //turn off bit 
801099d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801099d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  //puts 0 on PTE_A flag
  void updateAge(struct proc *proc){ 
    pte_t* pte;

    int i;
    for (i=3; i<30; i++)
801099db:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801099df:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
801099e3:	0f 8e 2e ff ff ff    	jle    80109917 <updateAge+0x13>
        pte = walkpgdir(proc->pgdir,proc->pagesMetaData[i].va,0);
        if(!(*pte & PTE_A)){
          *pte &= !PTE_A; //turn off bit 
      }
    }
  }
801099e9:	83 c4 24             	add    $0x24,%esp
801099ec:	5b                   	pop    %ebx
801099ed:	5d                   	pop    %ebp
801099ee:	c3                   	ret    

801099ef <clearAllPages>:

void
clearAllPages(struct proc *p){
801099ef:	55                   	push   %ebp
801099f0:	89 e5                	mov    %esp,%ebp
801099f2:	83 ec 28             	sub    $0x28,%esp
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
801099f5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801099fc:	e9 cd 00 00 00       	jmp    80109ace <clearAllPages+0xdf>
    if(p->pagesMetaData[i].va != (char *) -1){
80109a01:	8b 4d 08             	mov    0x8(%ebp),%ecx
80109a04:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a07:	89 d0                	mov    %edx,%eax
80109a09:	c1 e0 02             	shl    $0x2,%eax
80109a0c:	01 d0                	add    %edx,%eax
80109a0e:	c1 e0 02             	shl    $0x2,%eax
80109a11:	01 c8                	add    %ecx,%eax
80109a13:	05 90 00 00 00       	add    $0x90,%eax
80109a18:	8b 00                	mov    (%eax),%eax
80109a1a:	83 f8 ff             	cmp    $0xffffffff,%eax
80109a1d:	0f 84 a7 00 00 00    	je     80109aca <clearAllPages+0xdb>
      pte = walkpgdir(p->pgdir,proc->pagesMetaData[i].va,0);
80109a23:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80109a2a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109a2d:	89 d0                	mov    %edx,%eax
80109a2f:	c1 e0 02             	shl    $0x2,%eax
80109a32:	01 d0                	add    %edx,%eax
80109a34:	c1 e0 02             	shl    $0x2,%eax
80109a37:	01 c8                	add    %ecx,%eax
80109a39:	05 90 00 00 00       	add    $0x90,%eax
80109a3e:	8b 10                	mov    (%eax),%edx
80109a40:	8b 45 08             	mov    0x8(%ebp),%eax
80109a43:	8b 40 04             	mov    0x4(%eax),%eax
80109a46:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109a4d:	00 
80109a4e:	89 54 24 04          	mov    %edx,0x4(%esp)
80109a52:	89 04 24             	mov    %eax,(%esp)
80109a55:	e8 23 ea ff ff       	call   8010847d <walkpgdir>
80109a5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(!pte){
80109a5d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109a61:	74 67                	je     80109aca <clearAllPages+0xdb>

      }
      else if((*pte & PTE_P) != 0){
80109a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a66:	8b 00                	mov    (%eax),%eax
80109a68:	83 e0 01             	and    $0x1,%eax
80109a6b:	85 c0                	test   %eax,%eax
80109a6d:	74 5b                	je     80109aca <clearAllPages+0xdb>
        pa = PTE_ADDR(*pte);
80109a6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109a72:	8b 00                	mov    (%eax),%eax
80109a74:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109a79:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if(pa == 0){
80109a7c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109a80:	75 0e                	jne    80109a90 <clearAllPages+0xa1>
          cprintf("already free\n");
80109a82:	c7 04 24 59 a4 10 80 	movl   $0x8010a459,(%esp)
80109a89:	e8 12 69 ff ff       	call   801003a0 <cprintf>
80109a8e:	eb 3a                	jmp    80109aca <clearAllPages+0xdb>
        }
        else{
          cprintf("clearing\n");
80109a90:	c7 04 24 67 a4 10 80 	movl   $0x8010a467,(%esp)
80109a97:	e8 04 69 ff ff       	call   801003a0 <cprintf>
          char *v = p2v(pa);
80109a9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109a9f:	89 04 24             	mov    %eax,(%esp)
80109aa2:	e8 53 e5 ff ff       	call   80107ffa <p2v>
80109aa7:	89 45 e8             	mov    %eax,-0x18(%ebp)
          kfree(v);
80109aaa:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109aad:	89 04 24             	mov    %eax,(%esp)
80109ab0:	e8 d5 96 ff ff       	call   8010318a <kfree>
          *pte = 0;
80109ab5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109ab8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
          cprintf("finished\n");
80109abe:	c7 04 24 71 a4 10 80 	movl   $0x8010a471,(%esp)
80109ac5:	e8 d6 68 ff ff       	call   801003a0 <cprintf>
void
clearAllPages(struct proc *p){
  int i;
  pte_t *pte;
  uint pa;
  for(i = 0; i < MAX_TOTAL_PAGES; i++){
80109aca:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109ace:	83 7d f4 1d          	cmpl   $0x1d,-0xc(%ebp)
80109ad2:	0f 8e 29 ff ff ff    	jle    80109a01 <clearAllPages+0x12>
          cprintf("finished\n");
        }
      }
    }
  }
}
80109ad8:	c9                   	leave  
80109ad9:	c3                   	ret    

80109ada <isShell>:

int
isShell(){
80109ada:	55                   	push   %ebp
80109adb:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 's') && (proc->name[1] == 'h');
80109add:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109ae3:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109ae7:	3c 73                	cmp    $0x73,%al
80109ae9:	75 15                	jne    80109b00 <isShell+0x26>
80109aeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109af1:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109af5:	3c 68                	cmp    $0x68,%al
80109af7:	75 07                	jne    80109b00 <isShell+0x26>
80109af9:	b8 01 00 00 00       	mov    $0x1,%eax
80109afe:	eb 05                	jmp    80109b05 <isShell+0x2b>
80109b00:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109b05:	5d                   	pop    %ebp
80109b06:	c3                   	ret    

80109b07 <isInit>:

int
isInit(){
80109b07:	55                   	push   %ebp
80109b08:	89 e5                	mov    %esp,%ebp
  return (proc->name[0] == 'i') && (proc->name[1] == 'n') && (proc->name[2] == 'i') && (proc->name[3] == 't');
80109b0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b10:	0f b6 40 6c          	movzbl 0x6c(%eax),%eax
80109b14:	3c 69                	cmp    $0x69,%al
80109b16:	75 31                	jne    80109b49 <isInit+0x42>
80109b18:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b1e:	0f b6 40 6d          	movzbl 0x6d(%eax),%eax
80109b22:	3c 6e                	cmp    $0x6e,%al
80109b24:	75 23                	jne    80109b49 <isInit+0x42>
80109b26:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b2c:	0f b6 40 6e          	movzbl 0x6e(%eax),%eax
80109b30:	3c 69                	cmp    $0x69,%al
80109b32:	75 15                	jne    80109b49 <isInit+0x42>
80109b34:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80109b3a:	0f b6 40 6f          	movzbl 0x6f(%eax),%eax
80109b3e:	3c 74                	cmp    $0x74,%al
80109b40:	75 07                	jne    80109b49 <isInit+0x42>
80109b42:	b8 01 00 00 00       	mov    $0x1,%eax
80109b47:	eb 05                	jmp    80109b4e <isInit+0x47>
80109b49:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109b4e:	5d                   	pop    %ebp
80109b4f:	c3                   	ret    
