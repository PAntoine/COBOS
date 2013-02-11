comment	#==========================================================

		   read MDSIO block
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
		(word)  MDSIO access mode (only low byte used)
		(dword) Absolute block number (for oa_abso)
	Returns:
		(eax)   the result of the call	

	#==========================================================

rdm_not_owner	equ	error_code<app_1,failure,app_error<0,ape_n_own>>
rdm_perm_error	equ	error_code<app_1,failure,app_error<0,ape_cpl_err>>
rdm_range_err	equ	error_code<app_1,failure,app_error<0,ape_range_err>>
rdm_access_vio	equ	error_code<app_1,failure,app_error<0,ape_acces_vio>>
rdm_parm_err	equ	error_code<app_1,failure,app_error<0,ape_parm_err>>
rdm_eof_error	equ	error_code<app_1,failure,app_error<0,ape_eof_error>>
rdm_bof_error	equ	error_code<app_1,failure,app_error<0,ape_bof_error>>

rdm_message	equ	-12

rdm_buffer	equ	12
rdm_handle	equ	18
rdm_mode	equ	20
rdm_block	equ	24

read_MDSIO_block:
	enter	12,0
	push	ebx
	push	ecx
	push	ds
	push	es
	push	fs
	
	mov	eax, sys_segment
	mov	ds, ax

;---------------------------
; check parameters

	mov	eax, rdm_perm_error	; if the parmeter is wrong
	mov	bx, ss:8[ebp]		; check against the code segment from the stack
	arpl	ss:rdm_buffer[ebp+4], bx	; get the buffers segment
	jz	rdm_error		; if request buffer is more priveledged than the app
	
	mov	eax, rdm_access_vio	; access voilation
	mov	es, ss:rdm_handle[ebp]	; get the handle block
	test	es:[mdh_access], 02h	; is the write bit set
	jz	rdm_error		; NO!
	
	mov	eax, rdm_not_owner	; owner violation
	mov	bx, ds:[sys.current_task]	; is the calling task the owner
	cmp	bx, es:[mdh_owner]
	jne	rdm_error
	
;---------------------------
; check mode

	cmp	ss:rdm_mode[ebp], byte ptr oa_next
	je	rdm_forward		; read next
	cmp	ss:rdm_mode[ebp], byte ptr oa_prev
	je	rdm_backward		; read prev
	cmp	ss:rdm_mode[ebp], byte ptr oa_abso
	je	rdm_absolute		; read given block number
	
	mov	eax, rdm_parm_err
	jmp	rdm_error

;---------------------------
; forward read

rdm_forward:	cmp	es:[mdh_block], on_last_entry	; is it at the last entry in the onode
	je	rdm_next_block
	
	movzx	ebx, es:[mdh_block]
	inc	ebx
	cmp	es:mdh_buffer[ebx*4], 00	; if next block is zero then end of file
	jne	rdm_next_block		; then this onode has been read - read next

	mov	es:[mdh_block], bx
	jmp	rdm_do_read		; now read the next block
	
rdm_next_block:	mov	eax, rdm_eof_error	; the file end has been reached
	cmp	es:[mdh_buffer], dword ptr 0ffffffffh
	je	rdm_error
	
	mov	es:[mdh_block], 02h	; first block in the onode is the 2nd
	mov	eax, es:[mdh_buffer]
	mov	es:[mdh_o_block], eax	; the disk block number
	inc	es:[mdh_onode]		; now going to read the next onode
	
	push	es		; the segment for the buffer
	push	dword ptr offset mdh_buffer	; the offset within the segement
	push	eax		; the block to be read
	call	rdm_read_block
	jmp	rdm_forward		; now check the new onode block

;---------------------------
; backward read

rdm_backward:	cmp	es:4[mdh_buffer], dword ptr 0ffffffffh
	je	rdm_first_check
	
	cmp	es:[mdh_block], 02h	; is it the first block in the onode
	je	rdm_prev_block		; read the previous block
	dec	es:[mdh_block]		; do the read
	movzx	eax, es:[mdh_block]
	cmp	es:mdh_buffer[eax*4], 00	; is the onode entry empty?
	je	rdm_backward		; yes!
	jmp	rdm_do_read
	
rdm_first_check:
	mov	eax, rdm_bof_error	; is the object at the beginning of the file
	cmp	es:[mdh_block],on_head_size/4
	je	rdm_error
	dec	es:[mdh_block]
	movzx	eax, es:[mdh_block]
	cmp	es:mdh_buffer[eax*4], 00	; is the onode entry empty?
	je	rdm_backward		; yes!
	jmp	rdm_do_read

rdm_prev_block:	mov	es:[mdh_block], on_last_entry	; last block in the onode
	mov	eax, es:4[mdh_buffer]	; the previous pointer
	mov	es:[mdh_o_block], eax	; the disk block number
	dec	es:[mdh_onode]		; now going to read the next onode	
	
	push	es		; the segment for the buffer
	push	dword ptr offset mdh_buffer	; the offset within the segement
	push	eax		; the block to be read
	call	rdm_read_block
	jmp	rdm_backward		; now check the new onode block

;---------------------------
; absoulte read

rdm_absolute:	mov	eax, ss:rdm_block[ebp]	; get the absoulte block number
	add	eax, on_head_size/4	; the number of blocks used by the header
	xor	edx, edx		; remove any noise
	mov	ecx, on_last_entry - 1
	div	ecx		; divide by the number of block in each onode -2 (prev/next)
	mov	ebx, eax
	
rdm_ab_o_find:	cmp	es:[mdh_onode], bx	; is this onode in the buffer?
	je	rdm_read_ab		; YES!
	jb	rdm_prev_ab		; get the previous block
	
rdm_next_ab:	mov	eax, rdm_eof_error	; requested block is off the end of the object
	cmp	es:[mdh_buffer], 0ffffffffh	; is there a next block?
	je	rdm_error		; no!

	mov	es:[mdh_block], 02h	; first block in the onode is the 2nd
	mov	eax, es:[mdh_buffer]
	mov	es:[mdh_o_block], eax	; the disk block number
	inc	es:[mdh_onode]		; now going to read the next onode
	
	push	es		; the segment for the buffer
	push	dword ptr offset mdh_buffer	; the offset within the segement
	push	eax		; the block to be read
	call	rdm_read_block
	jmp	rdm_ab_o_find		; now check the new onode block

rdm_prev_ab:	mov	eax, rdm_bof_error	; requested block is off the start of the object
	cmp	es:4[mdh_buffer], 0ffffffffh	; is there a next block?
	je	rdm_error		; no!

	mov	es:[mdh_block], on_last_entry	; last block in the onode
	mov	eax, es:[mdh_buffer]
	mov	es:[mdh_o_block], eax	; the disk block number
	dec	es:[mdh_onode]		; now going to read the next onode
	
	push	es		; the segment for the buffer
	push	dword ptr offset mdh_buffer	; the offset within the segement
	push	eax		; the block to be read
	call	rdm_read_block
	jmp	rdm_ab_o_find		; now check the new onode block

rdm_read_ab:	mov	eax, rdm_eof_error	; block not in use
	add	edx, 2		; get over the two pointers
	cmp	es:mdh_buffer[edx*4], 00	; is the onode entry empty?
	je	rdm_error

	mov	es:[mdh_block], dx	; the absolute block ref
		
;---------------------------
; do the read

rdm_do_read:	lfs	ecx,ss:rdm_buffer[ebp]	; get the buffer
	movzx	eax, es:[mdh_block]
	
	push	es		; message buffer
	push	ecx		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:mdh_buffer[eax*4]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[mdh_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, rdm_message[ebp]
	
rdm_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	rdm_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	rdm_read

rdm_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	rdm_read

	xor	eax, eax		; OK - error code
	
;------------------------------
; exit

rdm_exit:	pop	fs
	pop	es
	pop	ds
	pop	ecx
	pop	ebx
	leave
	retf	14
	
;--------------------------
; error exit

rdm_error:	call	set_task_error
	jmp	rdm_exit
	
;--------------------------
; read onode block

rdm_read_block:	push	dword ptr ss:8[ebp]	; message buffer
	push	dword ptr ss:12[ebp]	; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:16[ebp]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[mdh_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, rdm_message[ebp]
	
rdm_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	rdm_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	rdm_read2

rdm_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	rdm_read2

	ret	10