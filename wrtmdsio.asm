comment	#==========================================================

		  write MDSIO block
		   (API Function)

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	The function will right the specified buffer to the block
	pointed to as the current block.
	      
	Parameters:
		(fword) MDSIO output buffer
		(word)  MDSIO handle number
	Returns:
		(eax)   the result of the call	

	#==========================================================

wm_not_owner	equ	error_code<app_1,failure,app_error<0,ape_n_own>>
wm_perm_error	equ	error_code<app_1,failure,app_error<0,ape_cpl_err>>
wm_range_err	equ	error_code<app_1,failure,app_error<0,ape_range_err>>

wm_message	equ	-12

wm_buffer	equ	12
wm_handle	equ	18

write_MDSIO_block:
	enter	12,0
	push	ds
	push	es
	push	fs
	push	gs
	
	mov	eax, sys_segment
	mov	ds, ax

;-----------------------------
; check the parameters

	mov	eax, wm_perm_error	; if the parmeter is wrong
	mov	bx, ss:8[ebp]		; get the code segment
	arpl	ss:wm_buffer[ebp+4], bx	; check against the buffers segment
	jz	wm_error		; if request buffer is more priveledged than the app

	mov	eax, wm_range_err	; there the device handle is off the MDSIO table
	mov	fs, ss:wm_handle[ebp]
	movzx	ebx, ds:[sys.MDSIO_size]
	cmp	bx, fs:[mdh_MDSIO_num]	; is the requested allocation in the table
	jb	wm_error		; NO!

;-----------------------------
; get the device & block
	
	mov	eax, wm_not_owner
	imul	ebx, md_size		; position in the table
	mov	cx, ds:[sys.current_task]
	cmp	fs:[mdh_owner], cx	; is it the owner?
	jne	wm_error		; NO!
	
	mov	cx, fs:[mdh_device]
	movzx	eax, fs:[mdh_block]	; the block in the buffer (index)
	mov	eax, fs:mdh_buffer[eax*4]	; get the current block number
	
;-----------------------------
; write the block
	
	push	word ptr 00
	push	word ptr ss:wm_buffer[ebp+4]	; message buffer
	push	dword ptr ss:wm_buffer[ebp]	; message offset
	push	word ptr 1		; transfer size
	push	eax		; starting block
	push	word ptr blk_write	; command
	push	cx		; device
	fcall	g_cobos, block_request

	lea	ebx, ss:wm_message[ebp]	
	
wm_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	wm_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	wm_read

wm_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	wm_read

;-----------------------------
; exit

wm_exit:	pop	ecx
	pop	ebx
	pop	gs
	pop	es
	pop	ds
	leave
	retf	8
	
;-----------------------------
; error codes

wm_error:	call	set_task_error		; set the tasks error codes
	jmp	wm_exit