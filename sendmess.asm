comment	#======================================================
		   Send Message
		   
		  (API FUNCTION)
		
	This subroutine will send a message to the task that
	is pointed to by the task number specified. If the 
	destination message queue is full, it will return
	an error message. This procedure must be entered by a
	FAR CALL (32-bit).

	version 2:	COBOS version - full 32Bit	

		(c)1996 P.Antoine
		
	--------------------------------------------------------
	Input:	word:  Destination task number
		word:  message size
		dword: source offset within selector
		word:  source selector
		word:  0000 - filler
		
	Returns:
	(eax)	dword:  result of the send. 
	#=======================================================

sm_not_exist	equ	error_code<task_level,failure,task_error<,tp_task,e_not_exist,0>> ; target task does not exist
sm_indx_full	equ	error_code<task_level,failure,task_error<,tp_index,e_full,0>>	  ; target tasks index is full
sm_mess_full	equ	error_code<task_level,failure,task_error<,tp_message,e_full,0>>	  ; target tasks message space is full

sm_tnum	equ	12
sm_size	equ	14
sm_mess	equ	16
	
send_message:	enter	0,0
	
	push	ebx
	push	ecx
	push	esi
	push	edi
	push	ds
	push	es

	mov	ax, sys_segment	
	mov	ds, ax
	
;**********************************************************
; check that that task number passed points to a real task
;**********************************************************

sm_wait_task:	bts	ds:[sys.semaphores],ss_task	; wait for the task list
	jc	sm_wait_task

	mov	es, ds:[sys.task_list]	; load task list
	xor	eax,eax
	mov	ax, ss:sm_tnum[ebp]	; load task number
	
	cmp	es:[eax*8], dword ptr 00h	; is the task slot empty?
	jne	sm_task_ok		; NO!
	
	btr	ds:[sys.semaphores],ss_task	; free the task list
	or	eax, sm_not_exist	; target task does not exist - ax is task number
	call	set_task_error		; this will set the task error bits
	jmp	sm_exit		
	
sm_task_ok:	btr	ds:[sys.semaphores],ss_task	; free the task list
	mov	es, es:TCB_seg[eax*8]	; load TCB from task list

sm_inuse_loop:	bts	es:[TCB.status], t_inuse	; wait for the "in use" bit to be clear
	jc	sm_inuse_loop

;*********************************************************
; find index place
;*********************************************************
	xor	eax,eax
	mov	bl, es:[TCB.indx_tail]
	inc	bl
	cmp	bl, es:[TCB.indx_size]
	jb	sm_find
	xor	bl,bl		; wrap around
	
sm_find:	cmp	bl, es:[TCB.indx_head]
	jne	sm_write		; if al = head then index full
	
	mov	eax, sm_indx_full	; error code - index full
	mov	ax, ss:sm_tnum[ebp]	; lower word of error code to be the task number
	call	set_task_error		; this will set the task error bits
	jmp	sm_clr_exit		; leave
	
;*********************************************************
; write message to the queue space
;*********************************************************

sm_write:	xor	edi, edi
	xor	ecx,ecx
	
	mov	cx, ss:sm_size[ebp]	; get message size
	mov	di, es:[TCB.mess_tail]	; start at tail
	lds	esi, ss:sm_mess[ebp]	; load message src address
	
sm_loop:	movsb

	cmp	di, es:[TCB.mess_end]	
	jne	sm_check_full
	mov	di, es:[TCB.mess_start]	; wrap around
	
sm_check_full:	cmp	di, es:[TCB.mess_head]
	je	sm_full
	loop	sm_loop

;*********************************************************
; sort out indexs and space pointers
; bl = index position to use
; edi = the next position in mess queue
;*********************************************************
	xor	eax,eax
	mov	ax, TCB.indx_start
	mov	es:[TCB.indx_tail], bl	; new position of index
	shl	bx, 2
	add	eax, ebx		; move position * 4 to eax

	mov	bx, ss:sm_size[ebp]
	mov	es:[eax], bx		; store message size

	mov	bx, es:[TCB.mess_tail]
	mov	es:2[eax], bx		; where the message stated
	
	mov	es:[TCB.mess_tail], di	; set new tail pointer
	
	xor	eax, eax		; error = OK
	jmp	sm_clr_exit

;*********************************************************
; leave the procedure
;*********************************************************
	
sm_full:	mov	eax, sm_mess_full	; error - not enough space for message
	mov	ax, ss:sm_tnum[ebp]
	call	set_task_error		; this will set the task error bits

sm_clr_exit:	and	es:[TCB.status], 0feh	; clear the "in use" bit

sm_exit:	pop	es
	pop	ds
	pop	edi
	pop	esi
	pop	ecx
	pop	ebx	

	leave
	retf	12