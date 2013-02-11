comment	#======================================================= 

		        USER SHELL
		      (API FUNCTION) 
		                                                                       
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	 
	  This task controls the user input to the COBOS system
	  and will control how the user interacts with the rest
	  of the system. 
	         	                                         
		Version 1.1 Post degree Alpha	        	                                         
	        	    (c) 1997 P.Antoine                  
	Parameter:
		(word)	owner of the shell
		(word)	screen number to use
		(word)	screen line to start on
	Return:
	       	<none>
	                                                         
	#========================================================

us_owner	equ	12
us_screen	equ	14
us_start_line	equ	16

us_line	equ	-2
us_all_ds	equ	-4
us_all_es	equ	-6

User_Shell:	enter	0,6
	push	ds
	push	es
	push	gs
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	
;--------------------------
; set up
	mov	ax, ss:us_start_line[ebp]
	mov	ss:us_line[ebp], ax	; set the first input line of the shell
	mov	ss:us_all_ds[ebp],word ptr 00h
	mov	ss:us_all_es[ebp],word ptr 00h
	
;--------------------------
; allocate the memory segs

	push	word ptr ss:us_owner[ebp]	 ; owner 
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 100h		 ; 256 bytes
	call	allocate_memory

	cmp	ebx, 00
	jne	us_error_exit
	mov	ds, ax		 ; save the input buffer space
	shr	eax, 16
	mov	ss:us_all_ds[ebp], ax	; store the alloc number
	
	push	word ptr ss:us_owner[ebp]	 ; owner 
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 600h		 ; 1536 bytes
	call	allocate_memory

	cmp	ebx, 00h		 ; if ebx != 0 then there is an error
	jne	us_error_exit
	mov	es, ax		 ; save the parse space
	shr	eax, 16
	mov	ss:us_all_es[ebp], ax	; store the alloc number
	
;------------------------
; input loop

us_loop:	mov	ds:[0], dword ptr 60600001h	; set the cusor
	mov	ax, offset g_keytab	; find the keytab
	
	push	word ptr ds		 ; segment of message
	push	dword ptr 00		 ; offset of message
	push	word ptr ss:us_line[ebp]	 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr ss:us_screen[ebp]	 ; screen number
	fcall	g_cobos, display_text

	push	word ptr ss:us_screen[ebp]	 ; screen number
	push	word ptr 0005h		 ; bg / fg colours
	push	word ptr 1		 ; x position
	push	word ptr ss:us_line[ebp]	 ; y position
	push	ds		 ; segment of buffer
	push	dword ptr 0h		 ; buffer start
	push	word ptr 100h		 ; max message size
	push	word ptr ax		 ; the keytable
	fcall	g_cobos, input_string
	inc	word ptr ss:us_line[ebp]

	cmp	ds:[0], byte ptr 0	; is the string empty?
	je	us_loop
	
;-------------------------
; parse input

us_parse:	mov	es:[us_idx_pos], 00	; clear the table
	mov	es:[us_free_space], us_data	; set the freespace pointer
	
	xor	esi, esi		; string start point
	lodsb
	movzx	ebx, al		; the size of the string to be parsed
	
us_read_string:	mov	edi, es:[us_free_space]	; get the free space pointer
	mov	edx, es:[us_idx_pos]
	mov	es:us_index_ent[edx*2],di	; set the index to the start of the string
	xor	ecx, ecx		; string count starts from 1
	inc	edi		; leave space fore the length
	
us_next_char:	lodsb			; read the input string
	cmp	al, 0ah		; is it less than A?
	jb	us_write_char
	cmp	al, 62h		; is it a <CR>?
	je	us_cr_found
	cmp	al, 60h		; is it a <space>?
	je	us_space_found
	cmp	al, 4dh		; is it greater than "z"
	ja	us_write_char
	and	al, 0feh		; make all chars upper case!
us_write_char:	stosb
	
	inc	ecx		; count the number of bytes read
	cmp	esi, ebx		; has it reached the end of the input?
	jbe	us_next_char

us_cr_found:	movzx	edi, es:us_index_ent[edx*2]	; input end.
	inc	edx		; next space
	mov	es:us_index_ent[edx*2], word ptr 00h ; ARGV, ARGC compatiple!!!
	mov	es:[edi], cl		; save the string length
	jmp	us_action		; now do the input
	
us_space_found:	mov	es:[us_free_space], edi	; save the new free space pointer
	movzx	edi, es:us_index_ent[edx*2]
	mov	es:[edi], cl		; save the string length
	
	inc	es:[us_idx_pos]		; next index position
	jmp	us_read_string
	
;------------------------
; action the command

us_action:	mov	ax, offset g_us_comms	; the commands area
	mov	gs, ax
	xor	eax, eax
	xor	ebx, ebx		; count starts at 0

us_a_loop:	movzx	esi, word ptr gs:usi_name[eax]	; get the name from the structure
	movzx	edi, es:us_index_ent[0]	; get the first	string input
	movzx	ecx, byte ptr es:[edi]	; get the fisr char from the name

	db	65h		; gs overide
	rep 	cmpsb 		; compare the two strings
	je	us_a_found		; action the command
	
	inc	ebx
	cmp	ebx, usc_num_comms	; have we searched all commands
	je	us_a_not_found		; YES!
	
	add	eax, 6
	jmp	us_a_loop

us_a_found:	jmp	dword ptr gs:usi_command[eax]	; goto the command

;------------------------
;Not found the command

us_a_not_found:	mov	ax, offset g_messages
	mov	gs, ax
	mov	eax, offset mess_un_comm	; command not found

	push	word ptr gs		 ; segment of message
	push	dword ptr eax		 ; offset of message
	push	word ptr ss:us_line[ebp]	 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr ss:us_screen[ebp]	 ; screen number
	fcall	g_cobos, display_text

	inc	word ptr ss:us_line[ebp]
	jmp	us_loop	

;------------------------
; error exit

us_error_exit:	mov	eax, ebx		; set the error
	call	set_task_error		; set tasks error bits

;------------------------
; exit

us_exit:	mov	ax, offset g_messages
	mov	gs, ax
	mov	eax, offset mess_goodbye	; command not found

	push	word ptr gs		 ; segment of message
	push	dword ptr eax		 ; offset of message
	push	word ptr ss:us_line[ebp]	 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 0004h		 ; bg / fg colours
	push	word ptr ss:us_screen[ebp]	 ; screen number
	fcall	g_cobos, display_text

; ** the above is testing
	xor	eax, eax		; Must not free allocations that are loaded!!
	mov	ds, ax
	mov	es, ax

	cmp	word ptr ss:us_all_ds[ebp], 00h	; free the allocations
	je	us_e_es 
	push	word ptr ss:us_all_ds[ebp]
	call	free_memory

us_e_es:	cmp	word ptr ss:us_all_es[ebp], 00h
	je	us_e_exit 
	push	word ptr ss:us_all_es[ebp]
	call	free_memory

us_e_exit:	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	gs
	pop	es
	pop	ds
	leave
	retf	6