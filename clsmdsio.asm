comment	#==========================================================

		  Close MDSIO object
		    (API Function)

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	 This function will close an MDSIO object that has been opened.
	 It will check that the function that is tring to close the 
	 object is the owner.	 
      
	Parameters:
		(word)  the MDSIO handle number
	Returns:
		(eax)   the result of the call.
		
	#==========================================================

cmd_not_owner	equ	error_code<app_1,failure,app_error<0,ape_n_own>>

cmd_number	equ	12		; the number of the object to be closed

close_MDSIO_object:
	enter	0,0
	push	ebx
	push	ecx
	push	ds
	push	es
	push	gs

	mov	eax, sys_segment
	mov	ds, ax

cmd_wait:	bts	ds:[sys.semaphores], ss_MDSIO		; wait for the table
	jnc	cmd_sem_got
	int	20h
	jmp	cmd_wait

;------------------------
; is the task the owner

cmd_sem_got:	mov	es, ss:cmd_number[ebp]	; load the handle

	movzx	ecx, es:[mdh_MDSIO_num]	; load the table entry number
	imul	ecx, md_size		; position in table
	
	mov	es, ds:[sys.MDSIO_table]	; load the table
	movzx	ebx, es:md_owner[ecx]	; get the ownder of the record
	cmp	bx, ds:[sys.current_task]
	je	cmd_remove		; is the owner - can remove it

	mov	gs, ds:[sys.current_TCB]
	bt	gs:[TCB.status], t_system	; is the task a "system" task
	jc	cmd_remove

	mov	eax, cmd_not_owner
	call	set_task_error		; set the tasks error
	jmp	cmd_exit

;-------------------------
; free the onode buffer

cmd_remove:	push	word ptr es:md_alloc_num[ecx]	; free the memory allocation
	call	free_memory

	mov	es:md_owner[ecx], word ptr 00h	; free the MDSIO record
	xor	eax, eax
	
;-------------------------
; exit

cmd_exit:	btr	ds:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	pop	gs
	pop	es
	pop	ds
	pop	ecx
	pop	ebx
	leave
	retf	2