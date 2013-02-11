comment	#===================================================
	           Create Task Control Block
		
	This subroutine will create a task control block 
	with all the associated memory allocations. It 
	will also initialise the status bits. All segements
	are created as data segments at level 0. The TSS
	should be initialised as follows:
	
	gs  - 00		cs  - <code segment>
	ds  - <data segment>	fs  - 00
	es  - 00		ss  - stack segment
	ebp - stack size	esp - stack size
		
	   all other registers and flags are zero.

	    Version 2 Copyright 1995 & 1996 P.Antoine.
	            32Bit Code segment version
	
	Input:	word: message_size
		word: index_size : only low byte used
		word: stack_size
	Output:
	(eax - hi)	word: tss selector
	(eax - lo)	word: TCB selector
	(ebx     )	dword: error code
	
	#===================================================
	
m_spce_size	equ	8
m_indx_size	equ	10
stack_size	equ	12	
	
create_tcb:	enter	0,0
	push	ecx
	push	ds
	push	es
	
	xor	eax, eax
	mov	ax, ss:m_indx_size[ebp]
	and	ax, 00ffh		; only less that 255
	shl	ax, 2		; four bytes per entry
	add	ax, ss:m_spce_size[ebp]
	add	ax, TCB_size		; message size + variable space
	mov	ecx, eax		; copy size

; set up TCB segment and clear it

	push	word ptr 0ffffh		; owner 0000h - system
	push	word ptr 0092h		; push type
	push	eax		; size
	call	allocate_memory
	cmp	ebx, 00		; did the allocation work?
	jne	ct_exit	

	mov	ds, ax		; the data selector number
c_tcb_clr:	mov	ds:[ecx], byte ptr 00h
	loop	c_tcb_clr

; load TCB segment with initial values

	shr	eax, 16
	mov	ds:[TCB.TCB_alloc], ax	; save TCB alloc number

	mov	bx, ss:m_indx_size[ebp]	; get index size
	and	bx, 00ffh
	mov	ds:[TCB.indx_size], bl	; store index size (entries)
	
	shl	bx, 2
	add	bx, TCB.indx_start
	mov	ds:[TCB.mess_start],bx	; store where the message queue starts
	mov	ds:[TCB.mess_head],bx	; set the message head
	mov	ds:[TCB.mess_tail],bx	; set the message tail

	add	bx, ss:m_spce_size[ebp]	; get mess size
	mov	ds:[TCB.mess_end], bx	; save it in the TCB

; create TSS segment and save alloc number in TCB

	mov	bx, ds		; put TCB selector number
	
	push	bx		; owner (the TCB)
	push	word ptr 0092h		; data type
	push	dword ptr 0068h		; size
	call	allocate_memory
	cmp	ebx, 00		; did the allocation work?
	jne	ct_exit	
	
	mov	es, ax		; load tss selector
	shr	eax, 16		; get alloc num in ax
	mov	ds:[TCB.TSS_alloc], ax	; store in the TCB

	mov	ecx, 0068h		; clear TSS
c_tss_clr:	mov	es:[ecx], byte ptr 00h
	loop	c_tss_clr
	mov	es:[0], word ptr 00h	; clear backlink
	
; create level transition stack

	push	bx		; owner (the TCB)
	push	word ptr 0092h		; push type
	push	dword ptr 0100h		; size	
	call	allocate_memory
	cmp	ebx, 00		; did the allocation work?
	jne	ct_exit	

	mov	es:[TSS.stack_0],ax	; set the TSS level stacks
	mov	es:[TSS.ESP0],dword ptr 0100h	; stack pointers
	shr	eax, 16
	mov	ds:[TCB.lt_stack], ax	; store level transition stack alloc number

;create STACK segment and save alloc number in TCB

	xor	eax,eax
	mov	ax, ss:stack_size[ebp]	; get stack size
	mov	es:[TSS.tsk_ESP], eax	; set stack pointer
	mov	es:[TSS.tsk_EBP], eax	; set EBP pointer

	push	bx		; owner (the TCB)
	push	word ptr 0092h		; push type
	push	eax		; size	
	call	allocate_memory
	cmp	ebx, 00		; did the allocation work?
	jne	ct_exit	
	
	mov	es:[TSS.tsk_SS], ax	; set TSS data seg
	shr	eax, 16
	mov	ds:[TCB.Stack_alloc], ax	; store stack alloc number

;set the default TSS EFLAGS value

	mov	dword ptr es:[TSS.tsk_EFLAGS], 00000200h	; IOPL - 00, IF - 1, NT - 0 

;prepare return values

	mov	ax, es		; get tss selector
	shl	eax, 16
	mov	ax, ds		; set tcb selector
	xor	ebx, ebx		; error code: OK

ct_exit:	pop	es
	pop	ds
	pop	ecx

	leave
	ret	6