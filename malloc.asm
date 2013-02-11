comment	#=====================================================
		Allocate Memory
	         
	This subroutine will allocate memory and create a
	general selector, of the type specified. If this 
	procedure fails then it will return 00.
	
	input: 
		dword:am_size,
		 word:am_type,
		 word:am_owner
	returns:
	(eax)hi	word:  memory_slot_number
	     lo	word:  selector_number
	(ebx)	dword: error code
	
	
	Version 2: converted to 32bit, for the COBOS Project.
	
	         Copyright. 1995 & 1996 P.Antoine
	
	------------------------------------------------------
	
	Note: format of a malloc record
	dword:m_size, word:owner, word:selector, dword:memstart
	if owner & m_size are zero then its free mem.  
	
	#=====================================================
	
am_size	equ	8	
am_type	equ	12
am_owner	equ	14
am_tbl_full	equ	error_code<system_err,failure,system_error<,m_list,e_full,0,0>>

allocate_memory:
	enter	0,0		;current stack pointer
	push	gs
	push	ds
	push	ecx
	push	edx
	
	mov	ax,sys_segment		; system segment in ds
	mov	ds, ax

alloc_wait:	bts	ds:[sys.semaphores], ss_malloc	; wait for the malloc table to be free
	jnc	alloc_wait	

	mov	gs, ds:[sys.malloc_list]	; load malloc list in gs
	mov	edx, ss:am_size[ebp]	; load size
	
	xor	eax,eax		; error code if malloc fails
	xor	ebx,ebx
	movzx	ecx, word ptr ds:[sys.malloc_size]

alloc_loop:	cmp	gs:m_owner[ebx],dword ptr 0h	; are owner and selector zero
	je	alloc_free
alloc_next:	add	ebx, 12		; next record
	loop	alloc_loop

	mov	eax, am_tbl_full	; the malloc table is full
	jmp	alloc_fail		; failed!

alloc_free:	cmp	gs:m_size[ebx], dword ptr 00h	; is the size zero
	je	alloc_next		; try again 
	cmp	gs:m_size[ebx], edx	; check for size
	jl	alloc_next		; space to small
	je	alloc_same		; same size space
	
	;mem space bigger than what is needed
	
	movzx	ecx, word ptr ds:[sys.malloc_size]
	xor	edx, edx		; start at bottom
alloc_find:	cmp	gs:m_size[edx], dword ptr 00h	; looking for a space with size eq 00 (not used)
	je	alloc_new
	add	edx, 12
	loop	alloc_find
	jmp	alloc_same		; no free spaces in table, so use the big allocation

alloc_new:	push	dword ptr gs:m_address[ebx]	; push base
	push	dword ptr ss:am_size[ebp]	; pust limit
	push	word ptr ss:am_type[ebp]	; push type
	call	cr_gen_desc

	test	eax, 0ffff0000h		; see if there is an error
	jne	alloc_fail		; eax hold an error code

	mov	gs:m_selector[edx], ax	; new selector for mem area
	
	mov	ax, ss:am_owner[ebp]
	mov	gs:m_owner[edx], ax	; store owner of new alloc
	
	mov	eax, gs:m_address[ebx]	; get base
	mov	gs:m_address[edx], eax	; store new base
	add	eax, ss:am_size[ebp]	
	mov	gs:m_address[ebx],eax	; store new base of freespace entry
	
	mov	eax, ss:am_size[ebp]	; get size
	mov	gs:m_size[edx], eax	; save size in new entry
	sub	gs:m_size[ebx], eax	; take away size from freespace entry
	
	; store slot number and selector in eax for return
	mov	eax, edx
	mov	ebx, edx		; need to clear edx
	cmp	eax, 00h		; is entry no 0
	je	alloc_avd_div0
	cdq			; make eax a qword
	mov	ecx, 12		
	div	ecx		;divide eax by zero
alloc_avd_div0:	shl	eax,16
	mov	ax, gs:m_selector[ebx]	; store selector	
	xor	ebx, ebx		; error code all is ok
	jmp	alloc_exit
	
alloc_same:	push	dword ptr gs:m_address[ebx]	; base
	push	dword ptr gs:m_size[ebx]	; limit (m_size)
	push	word ptr ss:am_type[ebp]	; type
	call	cr_gen_desc

	test	eax, 0ffff0000h		; see if there is an error
	jne	alloc_fail		; eax hold an error code
	
	mov	gs:m_selector[ebx], ax	; store selector
	mov	ax, ss:am_owner[ebp]	
	mov	gs:m_owner[ebx], ax	; store owner

	mov	eax, ebx
	cmp	eax, 00h
	je	alloc_avd1
	cdq	
	mov	ecx, 12
	div	ecx		; return entry number
alloc_avd1:	shl	eax, 16
	mov	ax, gs:m_selector[ebx]	; return new selector
	xor	ebx, ebx		; error all is ok
	jmp	alloc_exit
	
alloc_fail:	mov	ebx, eax		; move error code to ebx
	
	bt	ds:[sys.semaphores],ss_system	; check to see if system caused error
	jc	alloc_exit
	
	call	set_task_error		; this will set the task error bits
	
alloc_exit:	btr	ds:[sys.semaphores], ss_malloc	; free the malloc table
	pop	edx
	pop	ecx
	pop	ds
	pop	gs
	leave
	ret	8		; clear eight bytes from stack		