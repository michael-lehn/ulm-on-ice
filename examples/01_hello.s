	.equ    p,	1
	.equ    ch,	p + 1

	.data
msg	.string "hello, world! 🍺 \n你好世界\nHallo, Welt\nGrüße aus Ulm ;-)\n"

	.text
	loadz   msg,	%p
fetch	movzbq	(%p),	%ch
	addq	1,	%p,	%p
	subq	0,	%ch,	%0
	jz	halt
	putc	%ch
	jmp	fetch
halt	halt	0x42
