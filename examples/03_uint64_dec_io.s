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
msg0:	.string "Type in some unsigned integer in decimal format\n\n"
msg1:   .string "again? (type 'n' to exit, any other key to continue)\n"
msg2:   .string "Tschüss!\n"

neq:	.string "n = "
got:	.string "got: n = "

        .text
#
#       Initialize function stack
#
        load    0,          %SP
        movq    %SP,        %FP

        // reserve space for 2 local variables
        subq    2 * 8,      %SP,        %SP

        // call puts(msg0)
        subq    4 * 8,      %SP,        %SP
        load    msg0,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

.loop:
        // call puts(neq)
        subq    4 * 8,      %SP,        %SP
        load    neq,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	// local0 = getu();
        subq    3 * 8,      %SP,        %SP
        load    getu,       %4
        call    %4,         %RET_ADDR
	movq	rval(%SP),  %4
	movq	%4,	    local0(%FP)
        addq    3 * 8,      %SP,        %SP

        // call puts(got)
        subq    4 * 8,      %SP,        %SP
        load    got,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

        // call putu(local0)
        subq    4 * 8,      %SP,        %SP
	movq	local0(%FP),%4
        movq    %4,         fparam0(%SP)
        load    putu,      %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

	putc	'\n'

        // call puts(msg1)
        subq    4 * 8,      %SP,        %SP
        load    msg1,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

        getc    %4
        subq    'n',        %4,         %0
        jnz     .loop

	// call puts(msg2)
        subq    4 * 8,      %SP,        %SP
        load    msg2,        %4
        movq    %4,         fparam0(%SP)
        load    puts,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP




	halt	0

/*
        uint64_t getu
*/
getu:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

	// reserve space for 2 local variables 'local0', 'local1'.
        subq    2 * 8,      %SP,        %SP

        /* begin of the function body */
	// local0 = 0;
	load	0,	    %4
	movq	%4,	    local0(%FP)

.loop.getu:
	getc	%4
	subq	'0',	    %4,		%0
	jb	.done.getu
	subq	'9',	    %4,		%0
	ja	.done.getu

	// local1 = %5 - '0';
	subq	'0',	    %4,		%4
	movq	%4,	    local1(%FP)

	// local0 *= 10;
        subq    5 * 8,      %SP,        %SP
        movq    local0(%FP),%4
        movq    %4,         fparam0(%SP)
	load	10,	    %4
	movq	%4,	    fparam1(%SP)
        load    imulq,      %4
        call    %4,         %RET_ADDR
	movq	rval(%SP),  %4
	movq	%4,	    local0(%FP)
        addq    5 * 8,      %SP,        %SP

	// local0 += local1
	movq	local0(%FP),%4
	movq	local1(%FP),%5
	addq	%4,	    %5,		%4
	movq	%4,	    local0(%FP)

	jmp	.loop.getu

.done.getu
	movq	local0(%FP),%4
	movq	%4,	    rval(%FP)

        /* end of the function body */

        // function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR

/*
        void putu(uint64_t n)
*/
putu:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

	// reserve space for 1 local variable 'local0'.
        subq    1 * 8,      %SP,        %SP

        /* begin of the function body */

        // local0 = n % 10; n /= 10;
        subq    5 * 8,      %SP,        %SP
        movq    fparam0(%FP),%4
        movq    %4,         fparam0(%SP)
        load    div10,      %4
        call    %4,         %RET_ADDR
        movq    fparam0(%SP),%4
        movq    %4,         fparam0(%FP)
        movq    fparam1(%SP),%4
        movq    %4,         local0(%FP)
        addq    5 * 8,      %SP,        %SP

        // if (n != 0) {
        movq    fparam0(%FP),%4
        subq    0,          %4,         %0
        jz      .print.putu

        // call: putu(n);
        subq    4 * 8,      %SP,        %SP
        movq    fparam0(%FP),%4
        movq    %4,         fparam0(%SP)
        load    putu,       %4
        call    %4,         %RET_ADDR
        addq    4 * 8,      %SP,        %SP

        // }

.print.putu:
        movq    local0(%FP),%4
        addq    '0',        %4,         %4
        putc    %4

        /* end of the function body */

        // function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR


/*
        void div10(uint64_t &n, uint64_t &r)
*/
div10:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

        /* begin of the function body */
	.equ    N,	    4
    	.equ    Q,	    5
    	.equ    R,	    6
    	.equ    TMP,	    6

	movq	fparam0(%FP),%N

    	// q = (n >> 1) + (n >> 2);
    	shrq    1,	    %N,		%Q
    	shrq    2,	    %N,		%TMP
    	addq    %Q,	    %TMP,	%Q

    	// q = q + (q >> 4);
    	shrq    4,	    %Q,		%TMP
    	addq    %Q,	    %TMP,	%Q

    	// q = q + (q >> 8);
    	shrq    8,	    %Q,		%TMP
    	addq    %Q,	    %TMP,	%Q

    	// q = q + (q >> 16);
    	shrq    16,	    %Q,		%TMP
    	addq    %Q,	    %TMP,	%Q

    	// q = q + (q >> 32);
    	shrq    32,	    %Q,		%TMP
    	addq    %Q,	    %TMP,	%Q

    	// q = q >> 3;
    	shrq    3,	    %Q,		%Q

    	// r = n - (((q << 2) + q) << 1);
    	shlq    2,	    %Q,		%TMP
    	addq    %Q,	    %TMP,	%TMP
    	shlq    1,	    %TMP,	%TMP
    	subq    %TMP,	    %N,		%R

    	subq    9,	    %R,		%0
    	jbe	.done
    	addq    1,	    %Q,		%Q
    	subq    10,	    %R,		%R
.done:

	movq	%Q,	    fparam0(%FP)
	movq	%R,	    fparam1(%FP)

        /* end of the function body */

        // function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR

/*
        uint64_t imulq(uint64_t a, uint64_t b)
*/
imulq:
        // function prologue
        movq    %RET_ADDR,  ret(%SP)
        movq    %FP,        fp(%SP)
        movq    %SP,        %FP

        /* begin of the function body */

        movq    fparam0(%FP),%4
        movq    fparam1(%FP),%5

        // a0 * b0
        mulw    %4,         %5,         %6

        // + (a1 * b0 + a0 * b1) * 2^16
        shrq    16,         %4,         %7
        mulw    %7,         %5,         %7

        shrq    16,         %5,         %8
        mulw    %8,         %4,         %8
        addq    %8,         %7,         %7

        shlq    16,         %7,         %7
        addq    %7,         %6,         %6

        // + (a2 * b0 + a1 * b1 + a0 * b2) * 2^32
        shrq    32,         %4,         %7
        mulw    %7,         %5,         %7

        shrq    16,         %4,         %8
        shrq    16,         %5,         %9
        mulw    %8,         %9,         %8
        addq    %8,         %7,         %7

        shrq    32,         %5,         %8
        mulw    %8,         %4,         %8
        addq    %8,         %7,         %7

        shlq    32,         %7,         %7
        addq    %7,         %6,         %6

        // + (a3 * b0 + a2 * b1 + a1 * b2 + a0 * b3) * 2^48
        shrq    48,         %4,         %7
        mulw    %7,         %5,         %7

        shrq    32,         %4,         %8
        shrq    16,         %5,         %9
        mulw    %8,         %9,         %8
        addq    %8,         %7,         %7

        shrq    16,         %4,         %8
        shrq    32,         %5,         %9
        mulw    %8,         %9,         %8
        addq    %8,         %7,         %7

        shrq    48,         %5,         %8
        mulw    %8,         %4,         %8
        addq    %8,         %7,         %7

        shlq    48,         %7,         %7
        addq    %7,         %6,         %6

        movq    %6,         rval(%FP)

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
.loop.puts:
        movzbq  (%4),       %5
        subq    0,          %5,     %0
        jz      .ret.puts
        putc    %5
        addq    1,          %4,     %4
        jmp     .loop.puts
.ret.puts

        /* end of the function body */

        // function epilogue
        movq    %FP,        %SP
        movq    fp(%SP),    %FP
        movq    ret(%SP),   %RET_ADDR
        ret     %RET_ADDR

