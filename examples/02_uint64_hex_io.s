        .equ    FP,         1
        .equ    SP,         2
        .equ    RET_ADDR,   3


#
#       Stack offsets used for functions
#
        .equ    ret,        0
        .equ    fp,         ret + 8
        .equ    rval,       fp + 8
        .equ    fparam0,    rval + 8
        .equ    fparam1,    fparam0 + 8     # extend if more than 2 parameters
                                            # are needed

        .equ    local0,     -8
        .equ    local1,     local0 - 8      # extend if more than 2 local
                                            # variables are needed

	.data
msg0:	.string "Type in some 64 bit unsigned integer in hex format\n"
msg1:   .string "(you can use lower or upper case letters)\n"
msg2:   .string "again? (type 'n' to exit, any other key to continue)\n"
msg3:   .string "Tschüss!\n"
neq:	.string "n = 0x"
got:	.string "got: n = 0x"

        .text
#
#       Initialize function stack
#
        load    0,          %SP
        movq    %SP,        %FP

        // reserve space for 1 local variable 'tmp'.
        subq    1 * 8,      %SP,        %SP

        // call puts(msg0)
        subq    4 * 8,      %SP,        %SP
        load    msg0,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

        // call puts(msg1)
        subq    4 * 8,      %SP,        %SP
        load    msg1,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

.loop
	putc	'\n'

        // call puts(neq)
        subq    4 * 8,      %SP,        %SP
        load    neq,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP


        // call tmp = getux()
        subq    3 * 8,      %SP,        %SP
        load    getux,      %4
        call    %4,         %RET_ADDR
        movq    rval(%SP),  %4
        movq    %4,         local0(%FP)
        addq    3 * 8,      %SP,        %SP

	putc	'\n'

        // call puts(got)
        subq    4 * 8,      %SP,        %SP
        load    got,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

        // call putux(tmp)
        subq    4 * 8,      %SP,        %SP
	movq	local0(%FP),%4
        movq    %4,         fparam0(%SP)
        load    putux,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	putc	'\n'
	putc	'\n'

        // call puts(msg2)
        subq    4 * 8,      %SP,        %SP
        load    msg2,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	getc	%4
	subq	'n',	    %4,		%0
	jnz	.loop

	putc	'\n'

        // call puts(msg3)
        subq    4 * 8,      %SP,        %SP
        load    msg3,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	halt	0

/*
        uint64_t getux()
*/
getux:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

        /* begin of the function body */

	load	0,	    %4
.loop.getux:
	getc	%5
	subq	'0',	    %5,		%0
	jb	.lc.getux
	subq	'9',	    %5,		%0
	ja	.lc.getux
	subq	'0',	    %5,		%5
	jmp	.add.getux
.lc.getux:
	subq	'a',	    %5,		%0
	jb	.uc.getux
	subq	'f',	    %5,		%0
	ja	.uc.getux
	subq	'a',	    %5,		%5
	addq	10,	    %5,		%5
	jmp	.add.getux
.uc.getux:
	subq	'A',	    %5,		%0
	jb	.done.getux
	subq	'F',	    %5,		%0
	ja	.done.getux
	subq	'A',	    %5,		%5
	addq	10,	    %5,		%5
.add.getux:
	shlq	4,	    %4,		%4
	addq	%5,	    %4,		%4
	jmp	.loop.getux
.done.getux:

	movq	%4,	    rval(%FP)

	/* end of the function body */
	
	// function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR


/*
        putux(uint64_t n)
*/
putux:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

        // reserve space for 1 local variable 'tmp'.
        subq    1 * 8,      %SP,        %SP

        /* begin of the function body */

        movq    fparam0(%FP),%4

	// tmp = n & 0xF; n = n / 16
	load	0xF,	    %5
	andq	%5,	    %4,		%5
	movq	%5,	    local0(%FP)
	shrq	4,	    %4,		%4
	movq	%4,	    fparam0(%FP)

	// if (n / 16 != 0) {
	subq	0,	    %4,		%0
	jz	.print.putux

	// putux(n / 16)
	subq    4 * 8,      %SP,        %SP
        movq    fparam0(%FP),%4
        movq    %4,         fparam0(%SP)
        load    putux,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	// }

.print.putux:
	// print tmp
	movq	local0(%FP),%4
	subq	10,	    %4,		%0
	jb	.dec.putux
	subq	10,	    %4,		%4
	addq	'A',	    %4,		%4
	jmp	.putc.putux
.dec.putux:
	addq	'0',	    %4,		%4
.putc.putux:
	putc	%4

	/* end of the function body */
	
	// function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR

/*
        puts(const char *s)
*/
puts:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

        /* begin of the function body */
        movq    fparam0(%FP),%4
.loop.putu:
        movzbq  (%4),       %5
        subq    0,          %5,     %0
        jz      .ret.putu
        putc    %5
        addq    1,          %4,     %4
        jmp     .loop.putu
.ret.putu

        /* end of the function body */

        // function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR


	//
	// end of text segment 
	//
