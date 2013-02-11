comment	#=====================================================
		    READ MESSAGE

		    (API FUNCTION)
		
	This procedure will read a message from the tasks 
	message queue. The task that the message will be read
	from will be the current task. This procedure is a
	32-bit FAR procedure.
	
	
	version 2:	COBOS version - full 32Bit
	
		(c) 1996 P.Antoine.
	
	------------------------------------------------------
		
	Input:	dword:  destination offset
		word:   destination selector
		word:   0000 - filler
	Returns:
	(eax)	error code
	
	#=====================================================
	
rm_indx_emty	equ	error_code<task_level,failure,task_error<,tp_index,e_empty,0>>	  ; target tasks index is empty

rm_mess	equ	12

read_message:	enter	0,0
	push	ds
	push	es
	push	ebx
	push	ecx
	push	edi
	push	esi

	xor	eax, eax
	mov	ax, sys_segment
	mov	ds, ax
	mov	es, ds:[sys.task_list]
	mov	ds, ds:[sys.current_TCB]

rm_inuse_loop:	bts	ds:[TCB.status], t_inuse	; wait for "in use" bit to be clear
	jc	rm_inuse_loop

;**********************************
; check if message queue is empty
;**********************************

	mov	al, ds:[TCB.indx_head]
	cmp	al, ds:[TCB.indx_tail]
	jne	rm_get		; head != tail something in queue

	mov	eax, rm_indx_emty	; comment - message queue empty
	call	set_task_error		; this will set the task error bits
	jmp	rm_exit
	
;**********************************
; get message
;**********************************

rm_get:	xor	ax, ax
	mov	al, ds:[TCB.indx_head]	; find next item to read
	inc	al		; next indx entry
	cmp	al, ds:[TCB.indx_size]
	jb	rm_do_read		; does it wrap around
	xor	al, al

rm_do_read:	mov	bx, ax		; save for later
	shl	ax, 2
	add	ax, TCB.indx_start	; record in index
	
	movzx	ecx, word ptr ds:[eax]	; message size
	movzx	esi, word ptr ds:2[eax]	; start position
	les	edi,fword ptr ss:rm_mess[ebp]	; load destination
	cld			; count increments
	
rm_get_loop:	movsb
	cmp	si, ds:[TCB.mess_end]
	jb	rm_next
	mov	si, ds:[TCB.mess_start]	; if reached end of area, wrap around
rm_next:	loop	rm_get_loop

;*********************************
; tidy up 
;*********************************

	mov	ds:[TCB.mess_head], si	; update message head pointer
	mov	ds:[TCB.indx_head], bl	; update TCB
	xor	eax, eax		; error code 00 - OK

rm_exit:	btr	ds:[TCB.status], t_inuse	; clear the "in use" bit

	pop	esi
	pop	edi
	pop	ecx
	pop	ebx
	pop	es
	pop	ds
	leave
	retf	8	