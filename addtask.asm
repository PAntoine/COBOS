comment	#===================================================
		      Add task
		
	This subroutine will add a task to the task chain
	and set up the forward and back links. the point 
	that the task is added to the chain is after the
	current task.
	
	   Version 2 copyright 1995 & 1996 P.Antoine.
	         
	Input:	word: TCB selector
		word: TSS selector
	Returns:
	(eax)	word: Task list number
	
	#====================================================

at_TCB	equ	8
at_TSS	equ	10
at_tbl_full	equ	error_code<system_err,failure,system_error<,t_list,e_full,0,0>>
	
add_task:	enter	0,0		; enter no local vars
	push	ebx
	push	ecx
	push	ds
	push	es
	
	xor	ebx, ebx
	mov	ax, sys_segment
	mov	ds, ax

at_wait:	bts	ds:[sys.semaphores],ss_task	; wait for the task list
	jc	at_wait

	mov	es, ds:[sys.task_list]	; load task list
	movzx	ecx,word ptr ds:[sys.task_size]

add_t_loop:	cmp	es:[ecx*8], dword ptr 00h	; find slot with no links
	je	add_t_found
	loop	add_t_loop

	mov	eax, at_tbl_full	; no slot then fail
	jmp	add_t_exit
	
add_t_found:	movzx	eax, word ptr ds:[sys.current_task]
	cmp	eax, 00h		; is there any tasks?
	je	add_t_first

	mov	bx, es:forward_link[eax*8]	; forward link from the user task
	mov	es:forward_link[ecx*8], bx	; new task now points on
	mov	es:forward_link[eax*8], cx	; user task now points to new task
	
	mov	es:back_link[ecx*8], ax	; new task now back links to the user task
	mov	es:back_link[ebx*8], cx	; forward task now points back to new task
	jmp	add_t_set		; set up task entry
	
add_t_first:	mov	es:back_link[ecx*8], cx	; forward link points to itself
	mov	es:forward_link[ecx*8], cx	; back link points to itself
	mov	ds:[sys.current_task], cx	; set user task to only task
	
add_t_set:	mov	ax,ss:at_TCB[ebp]	; Task Control Block
	mov	es:TCB_seg[ecx*8], ax
	mov	ax, ss:at_TSS[ebp]	; TSS selector
	mov	es:TSS_seg[ecx*8], ax
	mov	eax, ecx		; return the task list number
	
add_t_exit:	btr	ds:[sys.semaphores], ss_task	; realease the task list
	pop	es
	pop	ds
	pop	ecx
	pop	ebx
	leave
	ret	4