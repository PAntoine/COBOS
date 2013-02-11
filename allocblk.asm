comment	#============================================================

		     allocate_block
		     
		         COBOS
	       ( Concurrent Object Based Operating System )
	       
	       	 a final year project
	       	 written by P.Antoine
	       	 
	       	 (c) 1997 P.Antoine.
	       	 
	 Allocate block will allocate a single device block on the 
	 specified device. It will return the block number.
	 
	 
	 Parameters:
	 	(word)	device_number
	 Returns:
		(ebx)	result code
		(eax)	block_number
	 	
	#============================================================

ab_not_exist	equ	error_code<system_err,failure,system_error<,d_table,e_not_exist,,0>> ; target task does not exist
ab_full	equ	error_code<device_err,failure,device_error<e_full,0>> ; device is full

ab_device	equ	8		; the device the the block is to be allocated on	
ab_mess_spc	equ	-12
	 
allocate_block:	enter	12,0		; 12 bytes needed for read_message results
	push	ecx
	push	edx
	push	edi
	push	esi
	push	ds
	push	es
	push	gs
	
	mov	eax, sys_segment
	mov	ds, ax
	
ab_wait:	bts	ds:[sys.semaphores],ss_device	; wait for the device list to be free
	jc	ab_wait
	
	mov	gs, ds:[sys.device_list]	; the divice list
	movzx	eax, word ptr ss:ab_device[ebp]	; get the device number
	imul	eax, d_size		; position in the device table

	cmp	gs:d_queue_seg[eax], 00h	; if queue-segment is empty then device not in use
	jne	ab_signal
	
	mov	eax, ab_not_exist	; the no device error
	jmp	ab_exist_err

ab_signal:	btr	ds:[sys.semaphores],ss_device	; dont need the device list anymore

ab_fat_wait:	bts	gs:d_status[eax], d_fat_use	; wait the devices fat to be free
	jc	ab_fat_wait
	
	mov	es, gs:d_FAT_buffer[eax]	; load the fat segment

;---------------------------
; read the block of the fat
	
	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr gs:d_FAT[eax]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:ab_device[ebp]	; device
	fcall	g_cobos, block_request

;-------------------------------
; wait for the read to complete		

	lea	ebx, ab_mess_spc[ebp]	; get the address of the stack space

ab_read_1:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	ab_set_value
	int	20h		; cant read next sector till the device code loads
	jmp	ab_read_1

ab_set_value:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	ab_read_1

	mov	ebx, gs:d_FAT[eax]
	mov	gs:d_FAT_block[eax], ebx	; set the current FAT block to be the first
	
;---------------------------
; search the FAT block

	xor	edi, edi		; fat block count
	mov	esi, 2		; first two bytes of the fat are the fat size

ab_search:	movzx	dx, byte ptr es:[esi]	; get the byte
	bsf	cx, dx		; find an unallocated block
	jnz	ab_found

	inc	esi
	cmp	esi, 200h		; 512 byte in a fat block
	jb	ab_search
	
	inc	ebx
	inc	edi
	cmp	di, gs:d_FAT_size[eax]	; searched all the FAT blocks?
	je	ab_full_err		; the disk is full!!!
	
;---------------------------
; read next block of FAT

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	ebx		; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:ab_device[ebp]	; device
	fcall	g_cobos, block_request

;-------------------------------
; wait for the read to complete		

	lea	edx, ab_mess_spc[ebp]	; get the address of the stack space

ab_read_2:	push	ss		; segment
	push	edx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	ab_set_value2
	int	20h		; cant read next sector till the device code loads
	jmp	ab_read_2

ab_set_value2:	cmp	ss:[edx], byte ptr 03h	; is it a block device message
	jne	ab_read_2

	mov	gs:d_FAT_block[eax], ebx	; set the current FAT block to be the block just read

	xor	edx, edx		; needs clearing
	xor	esi, esi		; start from the bottom
	jmp	ab_search
	
;------------------------------
; block found

ab_found:	btr	dx, cx		; cleat bit that was found
	mov	byte ptr es:[esi], dl	; write it back to the buffer

;---------------------------
; write back block of fat

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	ebx		; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:ab_device[ebp]	; device
	fcall	g_cobos, block_request

;-------------------------------
; wait for the write to complete		

	lea	ebx, ab_mess_spc[ebp]	; get the address of the stack space

ab_write:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	ab_write_done
	int	20h		; cant read next sector till the device code loads
	jmp	ab_write

ab_write_done:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	ab_write

	imul	edi, 2048		; fat block count * 512 * 8 = sectors in prev fats
	imul	esi, 8		; bytes into the fat	 
	add	edi, esi
	add	edi, ecx		; bits in the byte
	sub	edi, 16		; first word of fat is the size

	movzx	eax, word ptr ss:ab_device[ebp]	; get the device number
	imul	eax, d_size		; position in the device table
	add	edi, gs:d_FAT[eax]	; set the FAT bottom
	movzx	ecx, gs:d_FAT_size[eax]	; skip over the FAT
	add	edi, ecx

	btr	gs:d_status[eax], d_FAT_use	; free the fat

	mov	eax, edi		; in the return place
	xor	ebx, ebx		; no error
	jmp	ab_exit

;--------------------------------
; disk full

ab_full_err:	mov	ebx, ab_full		; the disk is full
	jmp	ab_exit
	
;-------------------------------
; device does not exist

ab_exist_err:	mov	ebx, ab_not_exist	; the device does not exist
	btr	ds:[sys.semaphores],ss_device	; free the device list 

;-------------------------------
; exit

ab_exit:	pop	gs
	pop	es
	pop	ds
	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	leave
	ret	2