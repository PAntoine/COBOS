comment	#========================================================

		      Display Text
		     (API Function)
			         
	 This function will display the character string on the
	 screen at the text location that is passed in to the 
	 function. It will check to see if the text runs off the
	 end of the window, and will end.
	 
		Version 1.1 - Post Degree alpha
	 	Copyright (c) 1996 P.Antoine.
	 	      
	 Parameters:
	 	word:  screen_number
		word:  colour (forground - backgound)
	 	word:  x_position (characters)
	 	word:  y_position (character lines)
	 	pword: text position
	 	
	 #=======================================================

dt_inval_srn	equ	error_code<system_err,failure,system_error<,h_table,e_not_exist,0,0>>
	
dt_screen	equ	12
dt_colour	equ	14
dt_x_pos	equ	16
dt_y_pos	equ	18
dt_text	equ	20
dt_line	equ	-2
	
display_text:	enter	0,2
	push	ds
	push	es
	push	fs
	push	gs
	pushad	

;-------------------
; find the screen

	mov	ax, sys_segment
	mov	fs, ax
	mov	gs, fs:[sys.char_set]	; get the character set
	mov	fs, fs:[sys.hot_spot]	; load the hot spot table
	
	movzx	eax, word ptr ss:dt_screen[ebp]
	imul	eax, hs_size		; position in table

	cmp	fs:hs_owner[eax], word ptr 00	; if 00 no owner - not in use
	jne	dt_win_found
	
	mov	eax, dt_inval_srn	; error - window specified not in use
	jmp	dt_error
		
;--------------------
; position in screen

dt_win_found:	les	esi,fword ptr fs:hs_graphic[eax]	; load the graphics area
	movzx	ebx, word ptr ss:dt_y_pos[ebp]
	mov	ss:dt_line[ebp], bx	; savbe the start line number
	inc	ebx
	imul	ebx, 9		; nine lines per charter
	cmp	bx, word ptr fs:hs_max_y[eax]
	jb	dt_y_ok
	
	mov	eax, -1		; y out of reange
	jmp	dt_error
	
dt_y_ok:	movzx	edx, word ptr ss:dt_x_pos[ebp]
	add	edx, 4
	shl	edx, 3		; mul by 8
	cmp	dx, word ptr fs:hs_max_x[eax]
	jb	dt_x_ok
	
	mov	eax, -1		; x out of range
	jmp	dt_error
	
;---------------------
; draw loop

dt_x_ok:	sub	ebx, 4		; back to start point
	movzx	esi, word ptr fs:hs_max_x[eax]
	imul	esi, ebx		; y line in virt screen
	
	movzx	ebx, word ptr ss:dt_x_pos[ebp]
	add	ebx, 3		; miss the border
	shl	ebx, 3
	add	esi, ebx		; pixel position in virt screen
	shr	esi, 1		; byte position in virt screen 
	add	ebx, 8		; check one char ahead

	lds	edi, fword ptr ss:dt_text[ebp]	; get the text
	movzx	ecx, byte ptr ds:[edi]	; 1st byte of string size

	inc	edi		; 1st byte of message
	
dt_main_loop:	movzx	edx,byte ptr ds:[edi]	; get the character to be sent

	mov	edx, gs:[edx*8]		; first 4 bytes of character data
	call	dt_draw_first

	movzx	edx,byte ptr ds:[edi]	; get the character to be sent

	mov	edx, gs:4[edx*8]	; last 4 bytes of character data
	call	dt_draw_secnd

	inc	edi		; next character
	add	ebx,8
	cmp	bx, fs:hs_max_x[eax]	; is it near the end of the screen?
	jae	dt_next_y
dt_onward:	loop	dt_main_loop
	bts	fs:hs_status[eax], hs_redraw	; set the redraw bit in the window
	jmp	dt_exit

dt_next_y:	inc	word ptr ss:dt_line[ebp]
	movzx	ebx, word ptr ss:dt_line[ebp]
	imul	ebx, 9		; nine lines per charter
	add	ebx, 4		; miss the top border
	cmp	bx, word ptr fs:hs_max_y[eax]	; is it off the screen bottom?
	ja	dt_exit
	movzx	esi, word ptr fs:hs_max_x[eax]	; position in data area
	imul	esi, ebx		; now in pixels
	shr	esi, 1		; now in bytes
	add	esi, 12		; miss the left border
	jmp	dt_onward		; jump back into the loop
	
;--------------------
; draw 4 pixels

dt_draw_first:	push	ebx
	push	ecx
	push	edi
	movzx	ebx, word ptr fs:hs_max_x[eax]	; get the screen width
	shr	ebx, 1		; now in bytes
	xor	edi, edi
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	pop	edi
	pop	ecx
	pop	ebx
	ret

dt_draw_secnd:	push	ebx
	push	ecx
	push	edi
	movzx	ebx, word ptr fs:hs_max_x[eax]	; get the screen width
	shr	ebx, 1		; now in bytes
	mov	edi, ebx
	shl	edi, 2		; start at line 4
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	add	edi, ebx
	call	dt_draw_line
	pop	edi
	pop	ecx
	pop	ebx
	add	esi, 4		; next screen byte
	ret

dt_draw_line:	push	edi
	push	ebx
	push	eax

	mov	ecx, 04h		; only 4 bytes in edx
	movzx	ebx, word ptr ss:dt_colour[ebp]

dt_draw_loop:	shl	dl, 1
	setc	al		; if c=1 then byte = 01h
	neg	al		; if byte = 01h then = 0ffh else 00
	mov	ah, al
	and	al, bl
	not	ah
	and	ah, bh
	or	al, ah
	mov	es:[esi+edi], al	

	shl	ebx, 4

	shl	dl, 1
	setc	al		; if c=1 then byte = 01h
	neg	al		; if byte = 01h then = 0ffh else 00
	mov	ah, al
	and	al, bl
	not	ah
	and	ah, bh
	or	al, ah
	or	es:[esi+edi], al	

	shr	ebx, 4

	inc	edi		; next byte
	loop	dt_draw_loop		; pixels across the line

	shr	edx, 8		; next line
	pop	eax
	pop	ebx
	pop	edi
	ret	
		
;--------------------
; exit

dt_error:	mov	bx, sys_segment
	mov	ds, bx
	bt	ds:[sys.semaphores],ss_system	; check to see if system caused error
	jc	dt_exit
	
	call	set_task_error		; this will set the task error bits

dt_exit:	popad
	pop	gs
	pop	fs
	pop	es
	pop	ds
	leave
	retf	16		; far return