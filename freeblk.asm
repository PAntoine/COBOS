comment	#==========================================================

		      Free Block

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1996 P.Antoine
			     
	 This function will release a device block in the devices
	 FAT. It will error if the block is not allocated allready

	 Parameters:
	 	(word)	device
	 	(dword)	block_number
	 Returns:
	 	(eax)	result code
	
	#==========================================================

fb_not_exist	equ	error_code<system_err,failure,system_error<,d_table,e_not_exist,,0>> ; target task does not exist
fb_not_free	equ	error_code<device_err,warning,device_error<e_not_free,0>> ; fat entry not free

fb_device	equ	8		; the device the the block is to be allocated on	
fb_block	equ	10		; the block number to be released
fb_mess_spc	equ	-12
	 
free_block:	enter	12,0		; 12 bytes needed for read_message results
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	push	ds
	push	es
	push	gs
	
	mov	ebx, sys_segment
	mov	ds, bx
	
fb_wait:	bts	ds:[sys.semaphores],ss_device	; wait for the device list to be free
	jc	fb_wait
	
	mov	gs, ds:[sys.device_list]	; the device list
	movzx	ebx, word ptr ss:fb_device[ebp]	; get the device number
	imul	ebx, d_size		; position in the device table

	cmp	gs:d_queue_seg[ebx], 00h	; if queue-segment is empty then device not in use
	jne	fb_signal
	
	mov	eax, fb_not_exist	; the no device error
	jmp	fb_exist_err

fb_signal:	btr	ds:[sys.semaphores],ss_device	; dont need the device list anymore

fb_fat_wait:	bts	gs:d_status[ebx], d_fat_use	; wait the devices fat to be free
	jc	fb_fat_wait
	
	mov	es, gs:d_FAT_buffer[ebx]	; load the fat segment

;------------------------
; get the FAT block

	xor	edx, edx
	mov	eax, ss:fb_block[ebp]	; get the block number
	movzx	ecx,gs:d_FAT_size[ebx]	; size of the FAT
	sub	eax, ecx
	sub	eax, gs:d_FAT[ebx]	; relative position on the drive
	add	eax, 10h		; plus 16 - first word is the fat size
	
	mov	esi, 2048
	div	esi		; divide by (512 * 8)
	mov	esi, eax		; save fat block

	mov	eax, edx		; load the remainder
	xor	edx, edx
	mov	ecx, 8
	div	ecx
	mov	edi ,eax		; div remainder / 8 = byte inside fat
	mov	ecx, edx		; remainder(div remainder/8) = bit inside byte
	
	add	esi, gs:d_FAT[ebx]	; position on drive
	
;--------------------------
; read the FAT block

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	esi		; fat block with the bit in it
	push	word ptr blk_read	; command
	push	word ptr ss:fb_device[ebp]	; device
	fcall	g_cobos, block_request
			
	lea	edx, fb_mess_spc[ebp]	; get the address of the stack space

fb_read_1:	push	ss		; segment
	push	edx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	fb_set_value
	int	20h		; cant read next sector till the device code loads
	jmp	fb_read_1

fb_set_value:	cmp	ss:[edx], byte ptr 03h	; is it a block device message
	jne	fb_read_1

;--------------------------
; set the FAT bits

	xor	edx, edx
	movzx	ax, byte ptr es:[edi]	; get the fat byte
	bts	ax, cx		; set the bit
	jc	fb_pib_warn
	
	mov	es:[edi], al		; put the byte back

;--------------------------
; write the FAT block

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	esi		; fat block with the bit in it
	push	word ptr blk_write	; command
	push	word ptr ss:fb_device[ebp]	; device
	fcall	g_cobos, block_request
			
	lea	edx, fb_mess_spc[ebp]	; get the address of the stack space

fb_write:	push	ss		; segment
	push	edx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	fb_is_drive
	int	20h		; cant read next sector till the device code loads
	jmp	fb_write

fb_is_drive:	cmp	ss:[edx], byte ptr 03h	; is it a block device message
	jne	fb_write

	xor	eax, eax
	
;-------------------------
; exit

fb_exit:	btr	gs:d_status[ebx], d_fat_use	; wait the devices fat to be free
	pop	gs
	pop	es
	pop	ds
	pop	edx
	pop	ecx
	pop	ebx
	leave
	ret	6		; clear the stack
	
fb_pib_warn:	mov	eax, fb_not_free	; warning - block not free
	jmp	fb_exit
	
fb_exist_err:	mov	eax, fb_not_exist
	btr	ds:[sys.semaphores],ss_device	; dont need the device list anymore
	jmp	fb_exit