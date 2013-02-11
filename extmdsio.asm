comment	#==========================================================

		  extend MDSIO block
		    (API Function)

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	The function will write the specified buffer to a new block
	addedto the end of the file.
	      
	Parameters:
		(fword) MDSIO output buffer
		(word)  MDSIO handle number
	Returns:
		(eax)   the result of the call	

	#==========================================================

em_not_owner	equ	error_code<app_1,failure,app_error<0,ape_n_own>>
em_perm_error	equ	error_code<app_1,failure,app_error<0,ape_cpl_err>>
em_range_err	equ	error_code<app_1,failure,app_error<0,ape_range_err>>
em_access_vio	equ	error_code<app_1,failure,app_error<0,ape_acces_vio>>
em_parm_err	equ	error_code<app_1,failure,app_error<0,ape_parm_err>>

em_message	equ	-12
em_curr_blk	equ	-16

em_buffer	equ	12
em_handle	equ	18

extend_MDSIO_object:
	enter	16,0
	push	ebx
	push	ecx
	push	ds
	push	es
	push	fs
	
	mov	eax, sys_segment
	mov	ds, ax

;---------------------------
; check parameters

	mov	eax, em_perm_error	; if the parmeter is wrong
	mov	bx, ss:8[ebp]		; check against the code segment from the stack
	arpl	ss:em_buffer[ebp+4], bx	; get the buffers segment
	jz	em_error		; if request buffer is more priveledged than the app
	
	mov	eax, em_access_vio	; access voilation
	mov	es, ss:em_handle[ebp]	; get the handle block
	test	es:[mdh_access], 02h	; is the write bit set
	jz	em_error		; NO!
	
	mov	eax, em_not_owner	; owner violation
	mov	bx, ds:[sys.current_task]	; is the calling task the owner
	cmp	bx, es:[mdh_owner]
	jne	em_error

;---------------------------
; now find the end 

em_search:	cmp	es:[mdh_block], on_last_entry	; is it at the last entry in the onode
	je	em_next_block
	
	movzx	ebx, es:[mdh_block]
	cmp	es:mdh_buffer[ebx*4], 00	; if block is zero then end of file
	je	em_next_block		; then a space has been found
	inc	es:[mdh_block]
	jmp	em_search		; check next block
	
em_next_block:	cmp	es:[mdh_buffer], dword ptr 0ffffffffh
	je	em_ext_onode		; extend the onode
	
	mov	es:[mdh_block], 02h	; first block in the onode is the 2nd
	mov	eax, es:[mdh_buffer]
	mov	es:[mdh_o_block], eax	; the disk block number
	inc	es:[mdh_onode]		; now going to read the next onode
	
	push	es		; the segment for the buffer
	push	dword ptr offset mdh_buffer	; the offset within the segement
	push	eax		; the block to be read
	call	em_read_block
	jmp	em_search		; now check the new onode block

;----------------------------
; extend the onode

em_ext_onode:	cmp	es:[mdh_block], on_last_entry	; is it at the last entry in the onode
	jne	em_alloc_blk		; no! so just allocate the block
	
	push	es:[mdh_device]		; the device number
	call	allocate_block		; allocate a disk block
	cmp	ebx, 00
	je	em_ext_here
	mov	eax, ebx
	jmp	em_error
	
em_ext_here:	mov	es:[mdh_buffer], eax	; set new forward pointer
	call	em_write_onode
	
	mov	eax, es:[mdh_o_block]	; get old block number
	mov	es:4[mdh_buffer], eax	; store in new previous pointer
	mov	eax, es:[mdh_buffer]	; new the new blocks number
	mov	es:[mdh_o_block], eax	; set the current pointer
	inc	es:[mdh_onode]		; added one more block
	
	mov	ecx, 512/4 - 2		; number of words to be cleard
	mov	edi, 8		; start from dword 3
	xor	eax, eax
	rep stosd			; clear the buffer	

	mov	es:[mdh_block], 02h	; first block is the 3rd dword

;---------------------------
; allocate the data block
	
em_alloc_blk:	push	es:[mdh_device]		; the device number
	call	allocate_block		; allocate a disk block
	cmp	ebx, 00
	je	em_ext_here2
	mov	eax, ebx
	jmp	em_error
	
em_ext_here2:	movzx	ebx, es:[mdh_block]
	mov	es:mdh_buffer[ebx*4], eax	; store the new block in the onode
	call	em_write_onode
	
;---------------------------
; write the data block

	push	word ptr 00
	push	word ptr ss:em_buffer[ebp+4]	; message buffer
	push	dword ptr ss:em_buffer[ebp]	; message offset
	push	word ptr 1		; transfer size
	push	eax		; starting block
	push	word ptr blk_write	; command
	push	es:[mdh_device]		; device
	fcall	g_cobos, block_request

	lea	ebx, ss:em_message[ebp]	
	
em_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	em_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	em_read

em_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	em_read
	
;---------------------------
; exit OK

	xor	eax, eax
	
em_exit:	pop	edi
	pop	ecx
	pop	ebx
	pop	es
	pop	ds
	leave
	retf	8
	
em_error:	call	set_task_error
	jmp	em_exit

;--------------------------
; read onode block

em_read_block:	push	word ptr 00		; filler
	push	dword ptr ss:8[ebp]	; message buffer
	push	dword ptr ss:12[ebp]	; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:16[ebp]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[mdh_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, em_message[ebp]
	
em_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	em_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	em_read2

em_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	em_read2

	ret	10

;--------------------------
; write onode block

em_write_onode:	push	es		; message buffer
	push	dword ptr offset mdh_buffer	; message offset
	push	word ptr 1		; transfer size
	push	es:[mdh_o_block]	; starting block
	push	word ptr blk_write	; command
	push	word ptr es:[mdh_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, em_message[ebp]
	
em_write:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	em_writea
	int	20h		; cant read next sector till the device code loads
	jmp	em_write

em_writea:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	em_write
	ret