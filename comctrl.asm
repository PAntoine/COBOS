comment	#======================================================= 

		 COMMAND AND CONTROL TASK
		                                                                          
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	 
	  This task controls the user input to the COBOS system
	  and will control how the user interacts with the rest
	  of the system. This task will also initialise the 
	  system.
	         	                                         
		Version 1.1 - Post degree Alpha	        	                                         
	        	    (c) 1997 P.Antoine                  
	                                                         
	#========================================================

;----------------------------------------------
; set the current realm to "NODE" - the system
; realm.

	mov	eax, sys_segment
	mov	es, ax
	mov	es, es:[sys.current_TCB]
	mov	ebx, offset TCB.owner_realm
	mov	es:[ebx], dword ptr 0e0d1817h		; "NODE"
	mov	es:4[ebx], dword ptr 0ffffffffh
	mov	es:8[ebx], dword ptr 0ffffffffh
	mov	es:12[ebx], dword ptr 0ffffffffh
	mov	es:16[ebx], dword ptr 0ffffffffh
	mov	es:20[ebx], dword ptr 0ffffffffh
	mov	es:24[ebx], dword ptr 0ffffffffh
	mov	es:28[ebx], dword ptr 0ffffffffh

	mov	ebx, offset TCB.current_group
	mov	es:[ebx], 01d1c0e1dh		; "test" - 32 byte group name
	mov	es:4[ebx], 01e181b10h		; "grou"
	mov	es:8[ebx], 0ffffff19h		; "p   "
	mov	es:12[ebx], dword ptr 0ffffffffh
	mov	es:16[ebx], dword ptr 0ffffffffh
	mov	es:20[ebx], dword ptr 0ffffffffh
	mov	es:24[ebx], dword ptr 0ffffffffh
	mov	es:28[ebx], dword ptr 0ffffffffh

;----------------------------------------------
; this is a test version to test the utilities
; and functions that have been written.

	push	word ptr 0FFFFh		 ; owner - system
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 1a00h		 ; 512 bytes
	call	allocate_memory
	mov	es, ax		 ; load es with ax

	push	word ptr 0FFFFh	 ; owner - system
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 0fa00h		; (200 * 40 * 8) / 2 bytes
	call	allocate_memory
	mov	gs, ax		; screen in GS

;---------------------------
; set up task window
	mov	cx, sys_segment
	mov	ds, cx

	push	word ptr 01000011b
	push	word ptr ax		 ; the segment
	push	dword ptr 00
	push	word ptr 00		; message segment
	push	dword ptr 00		; message offset
	push	word ptr 00		; message length
	push	word ptr ds:[sys.current_task]	; target task for window
	push	word ptr 00		; window relative start y		
	push	word ptr 00		; window realtive start x
	push	word ptr 0c8h		 ; 480 lines (max y)
	push	word ptr 0140h		 ; 640 pixels (max x)
	push	word ptr 0c8h		 ; bot y	
	push	word ptr 140h		 ; bot x
	push	word ptr 00h		 ; top y
	push	word ptr 00h		 ; top x
	push	word ptr 0ffffh		 ; owner (system)
	fcall	g_cobos, add_hot_spot	 ; add the hot spot

	push	ax		; **** testing - but ax will need to be saved

	push	word ptr 0000h		 ; background colour
	push	word ptr ax
	call	draw_border

;---------------------------
; locate the realm table

	mov	eax, ds:[sys.realm_block]

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ds:[sys.realm_block]	; starting block = FAT on device 0 - primary device
	push	word ptr blk_read	; command
	push	word ptr 00		; device
	fcall	g_cobos, block_request

cct_read:	push	es		; segment
	push	dword ptr 040h		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00
	jne	cct_read
	
	movzx	eax, word ptr es:[0]	; fat size is the first word of the FAT
	add	ds:[sys.realm_block], eax	; add the size of the FAT to the start of FAT = realm_table
	
	mov	fs, ds:[sys.device_list]
	mov	fs:[d_FAT_size], ax	; set the fat size on device 0

;---------------------------
; opening message

	mov	es:[0], 026ff0e09h	; "C O" C O B O S
	mov	es:[4], 026ff0cffh	; " B O"
	mov	es:[8], 0ffff2effh	; " S  "

	mov	es:[12], 022260e13h	; "COMMAND AND CONTROL"
	mov	es:[16], 010240a22h 
	mov	es:[20], 010240affh
	mov	es:[24], 024260effh
	mov	es:[28], 020262c30h

	xor	edi, edi
	pop	di		; get the screen number
	
	push	word ptr es		 ; segment of message
	push	dword ptr 00		 ; offset of message
	push	word ptr 0		 ; y position
	push	word ptr 9		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr di		 ; screen number
	fcall	g_cobos, display_text

	push	word ptr es		 ; segment of message
	push	dword ptr 12		 ; offset of message
	push	word ptr 2		 ; y position
	push	word ptr 5		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr di		 ; screen number
	fcall	g_cobos, display_text

	push	es
	mov	dx, offset g_messages
	mov	es, dx
	mov	eax, offset mess_version

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 3		 ; y position
	push	word ptr 6		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr di		 ; screen number
	fcall	g_cobos, display_text
	
	pop	es	

	imul	ebx, edi, hs_size
	mov	ds, ds:[sys.hot_spot]
	bts	ds:hs_status[ebx], hs_redraw

;-------------------
; read mesaage loop

	mov	dx, 04
	mov	bx, 0005h

	push	word ptr dx		; screen line to start on
	push	word ptr di		; screen number
	push	word ptr 0ffffh		; owner system
	fcall	g_cobos, user_shell
	
	fjmp	g_cobos, cobos_exit

;------------------------------
; convert eax to charaters

cct_word_char:	push	eax		 ; save registers
	push	ebx
	push	ecx
	shl	eax, 16		; lose the top word
	mov	ecx, 04h
	xor	ebx, ebx
	jmp	cct_loop

cct_dwrd_char:	push	eax		 ; save registers
	push	ebx
	push	ecx
	xor	ebx, ebx
	mov	ecx, 08h
	
cct_loop:	shld	ebx, eax, 4
	shl	eax, 4
	and	ebx, 0fh		 ; get last nibble
	mov	es:[edx], bl
	inc	edx
	loop	cct_loop

	pop	ecx
	pop	ebx
	pop	eax
	ret