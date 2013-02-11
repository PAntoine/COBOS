comment	#======================================================
		   Block_Request
		   
		  (API FUNCTION)

	 This function will add to the specified device queue
	 the block transfer request.		

	version 2:	COBOS version - full 32Bit	
		(c)1997 P.Antoine
		

	Input:	word:  Destination device
		word:  command
		dword: starting block
		word:  transfer size
		dword: buffer offset within selector
		word:  buffer selector
		word:  0000 - filler
		
	Returns:
	(eax)	dword:  result of the send. 
	#=======================================================

br_not_exist	equ	error_code<system_err,failure,system_error<,d_table,e_not_exist,,0>> ; target task does not exist
br_indx_full	equ	error_code<system_err,failure,system_error<,d_table,e_full,,0>>	  ; target tasks index is full

br_device	equ	12
br_command	equ	14
br_start	equ	16
br_size	equ	20
br_buffer	equ	22
	
Block_Request:	enter	0,0
	push	ebx
	push	ecx
	push	edx
	push	fs
	push	es
	push	ds
	push	gs
	mov	eax, sys_segment
	mov	ds, ax
	
;----------------------
; wait for device table

br_wait:	bts	ds:[sys.semaphores], ss_device	; wait for the device table
	jc	br_wait
	
	mov	gs, ds:[sys.device_list]	; the device list
	movzx	eax, word ptr ss:br_device[ebp]	; the device that is to be requested
	imul	eax, d_size		; position in the device table
	
	cmp	gs:d_queue_seg[eax], 00h	; if queue-segment is empty then device not in use
	jne	br_add_request
	
	mov	eax, br_not_exist	; the no device error
	jmp	br_error_exit

;--------------------
; find a slot

br_add_request:	mov	es, gs:d_queue_seg[eax]	; load the queue
	mov	ebx, es:[BRD.brd_tail]	; the end of the queue
	inc	ebx
	cmp	ebx, es:[BRD.brd_size]	; has the queue reached the top?
	jb	br_chk_full
	
	xor	ebx, ebx		; roll around
br_chk_full:	cmp	ebx, es:[BRD.brd_head]
	jne	br_found
	
	mov	eax, br_indx_full	; the device queue is full
	jmp	br_error_exit

;--------------------
; add request
	
br_found:	mov	ecx, ebx
	imul	ecx, br_r_size		; position in device request queue
	
	mov	dx, ss:br_device[ebp]
	mov	es:brd_dev_number[ecx],dl	; move the device number
	
	mov	dx, ss:br_command[ebp]
	mov	es:brd_command[ecx], dl	; the command for the device
	
	mov	edx, ss:br_start[ebp]
	mov	es:brd_block_start[ecx], edx	; the start block for the request
	
	mov	dx, ss:br_size[ebp]
	mov	es:brd_num_blocks[ecx], dx	; the size of the transfer
	
	mov	dx, ds:[sys.current_task]
	mov	es:brd_rqst_task[ecx], dx	; the task that requested the transfer
	
	mov	edx, ss:br_buffer[ebp]	; get the transfer buffer
	mov	es:brd_buffer[ecx], edx
	
	mov	dx, ss:br_buffer+4[ebp]
	mov	word ptr es:brd_buffer+4[ecx], dx

	mov	es:[BRD.brd_tail], ebx	; update the end of the queue

;------------------------
; check the device state

	mov	ecx, eax
	xor	eax, eax
	movzx	ebx, gs:d_handler[ecx]	; get the requested task
	btr	ds:[sys.semaphores], ss_device	; free the device list
	bt	gs:d_status[ecx], d_active	; check the active bit
	jc	br_exit		; the device is active and running

;------------------------
; release the device task
	
br_task_wait:	bts	ds:[sys.semaphores],ss_task	; free the task list
	jc	br_task_wait	
	mov	fs, ds:[sys.task_list]
	mov	es, fs:TCB_seg[ebx*8]	; the the device task TCB

	bts	gs:d_status[ecx], d_active	; now the device task is active
	btr	es:[TCB.status],t_suspended	; free the task

	btr	ds:[sys.semaphores],ss_task	; free the task list

;----------------------
; free the device list

	btr	ds:[sys.semaphores], ss_device	; free the device list

	bt	ds:[sys.semaphores],ss_system	; check to see if system caused error
	jc	br_exit

;---------------------
; exit the function		

br_exit:	pop	gs
	pop	ds
	pop	es
	pop	fs
	pop	edx
	pop	ecx
	pop	ebx
	leave
	retf	18

;---------------------
; error exit

br_error_exit:	btr	ds:[sys.semaphores], ss_device	; free the device list

	bt	ds:[sys.semaphores],ss_system	; check to see if system caused error
	jc	br_exit

	call	set_task_error		; this will set the task error bits
	jmp	br_exit