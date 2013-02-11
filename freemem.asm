comment	#=======================================================
		Free Memeory Allocation
		
	This subroutine will delete a memory allocation, and 
	will free the memory block. It will also do some
	simple collecting of memory blocks.
	
	       Version 2 copyright 1995 & 1996 P.Antoine.
		32Bit Code version
		
	Inputs:
		word: memory allocation number
	returns:
		<none>
		
	#========================================================

fm_alloc	equ	8
	
free_memory:	enter	0,0
	push	gs
	push	ds
	push	eax
	push	ebx
	push	ecx
	push	edx
	
	mov	bx, sys_segment
	mov	ds, bx		; load system segment

fm_wait:	bts	ds:[sys.semaphores], ss_malloc	; wait for the malloc table to be free
	jnc	fm_wait	

	mov	gs, ds:[sys.malloc_list]	; load allocation table
	movzx	ebx, word ptr ss:fm_alloc[ebp]	; get malloc number
	imul	ebx, ebx ,12		; position in mem

	push	word ptr gs:m_selector[ebx]	; push mem selector
	call	delete_desc		; delete memory discriptor

	mov	gs:m_owner[ebx], 00h	; set owner & selector to zero
	mov	gs:m_selector[ebx], 00h
	mov	eax, gs:m_address[ebx]	; base
	add	eax, gs:m_size[ebx]	; base + size = top
	push	eax

	xor	eax, eax
	movzx	ecx, ds:[sys.malloc_size]	; clear count
	mov	ecx, 10h
free_loop:	cmp	gs:m_owner[eax], dword ptr 00h	; is entry free?
	jne	free_next		; no!
	
	mov	edx, gs:m_address[eax]	; load base
	cmp	ss:[esp], edx		; is base equal to top?
	jne	free_bot		; NO!
		
	mov	edx, gs:m_size[eax]	; get size
	add	gs:m_size[ebx], edx	; add size to lower allocation	

	mov	gs:m_size[eax],  00h	; clear mem record
	mov	gs:m_owner[eax], 00h
	mov	gs:m_selector[eax], 00h
	mov	gs:m_address[eax], dword ptr 00h

free_bot:	add	edx, gs:m_size[eax]	; now top
	cmp	edx, gs:m_address[ebx]	; does top = base
	jne	free_next		; NO!
	
	mov	edx, gs:m_size[ebx]
	add	gs:m_size[eax], edx	; make size bigger
	
	mov	gs:m_size[ebx],   00h	; clear mem record
	mov	gs:m_owner[ebx],  00h
	mov	gs:m_selector[ebx], 00h
	mov	gs:m_address[ebx], dword ptr 00h

	mov	ebx, eax		; as record now gone

free_next:	add	eax, 12	
	loop	free_loop		; if not finished
	
free_exit:	btr	ds:[sys.semaphores], ss_malloc	; free the malloc table
	add	esp, 4		; tidy local variables
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	pop	ds
	pop	gs
	leave
	ret	2		; return + remove malloc num of stack
