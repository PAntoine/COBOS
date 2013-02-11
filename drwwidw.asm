comment	#===========================================================

		         Draw Window
		         
	 This function will draw a window on the screen. It will call
	 the function BUILD_MAP to build an obscured screen section
	 map, of the areas of the screen that are not to be drawn.
	 
	 	Version 1 Copyright 1996 P.Antoine
	 	      32bit COBOS Project
	 	      
	  Input:
	 	word: screen number
	  Registers:
	
	   ES - system segment	DS - Hot Spot list
	   GS - section map	FS - scratch
	 
	 #===========================================================
	 
dw_scrn_num	equ	8		; parameter
dw_curr_chain	equ	-2		; variables
dw_curr_x_sec	equ	-4
dw_y_pos	equ	-6
dw_x_start	equ	-8
dw_x_curr	equ	-10
dw_data_strt	equ	-14
dw_y_count	equ	-16
dw_x_width	equ	-20

draw_window:	enter	20,0
	push	es
	push	fs
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	push	word ptr ss:dw_scrn_num[ebp]
	call	build_map

;-------------------------
; Set the VGA card mode

	mov	dx, 3c4h		; sequencer control register
	mov	ax, 0f02h		; set to all planes
	out	dx, ax		

	mov	dx, 3CEh		; control port (VGA/EGA)
	mov	ax, 0205h		; read mode 0 write mode 2
	out	dx, ax
	
	mov	ax, 0003h		; set to data replace
	out	dx, ax

;-------------------------
; Initialise loop

	mov	es, es:[sys.real_screen]		; load the real screen
	mov	ss:dw_curr_chain[ebp], word ptr 00	; start from the first chain entry
	movzx	eax, word ptr ss:dw_scrn_num[ebp]
	imul	eax, hs_size
	mov	bx, ds:hs_top_x[eax]
	mov	ss:dw_x_start[ebp], bx		; set dw_x_start

;-------------------------
; set virtual screen pos

	lfs	esi, fword ptr ds:hs_graphic[eax]	; get the base of the screen
	movzx	ebx, word ptr ds:hs_rel_y[eax]
	movzx	ecx, word ptr ds:hs_max_x[eax]
	shr	ecx, 1
	mov	ss:dw_x_width[ebp], ecx		; save size of x
	imul	ebx, ecx			; number of pixels into the screen seg
	add	esi, ebx
	mov	ss:dw_data_strt[ebp], esi		; store the start pos in screen

;-------------------------
; the chain loop

dw_chn_loop:	xor	eax, eax
	movzx	eax, word ptr ss:dw_curr_chain[ebp]
	cmp	gs:sc_x_chain[eax],word ptr 0ffffh	; is the screen totally masked
	je	dw_full_mask
			
	movzx	ebx, word ptr gs:sc_upper_y[eax]	; set the y_pos
	imul	ebx, 80			; poistion on screen
	mov	ss:dw_y_pos[ebp], bx
	
	mov	bx, gs:sc_lower_y[eax]		; set the y count
	sub	bx, gs:sc_upper_y[eax]
	mov	ss:dw_y_count[ebp], bx

;-------------------------
; y loop

dw_y_loop:	movzx	eax, word ptr ss:dw_curr_chain[ebp]
	mov	bx, gs:sc_x_chain[eax]		; set the x_chain position
	mov	ss:dw_curr_x_sec[ebp], bx		;first x-section in chain

	mov	ax, ss:dw_x_start[ebp]
	mov	ss:dw_x_curr[ebp], ax		; reset the current position

;------------------------
; draw the x_segments

dw_x_sec_loop:	cmp	ss:dw_curr_x_sec[ebp], word ptr 00	; is it at the end of x_sec_chain
	je	dw_next_y
; byte count
	xor	esi, esi
	movzx	ecx, word ptr ss:dw_curr_x_sec[ebp]
	movzx	esi, word ptr gs:sc_x_start[ecx] 	; number of pixels from win edge
	movzx	ecx, word ptr ss:dw_x_curr[ebp]
	sub	esi, ecx
	jle	dw_here			; if byte count = 0 then next chain

	shr	esi, 1			; number of bytes from win edge
	mov	ecx, esi			; number of bytes count
;data offset
	movzx	ebx, word ptr ss:dw_x_start[ebp]
	movzx	esi, word ptr ss:dw_x_curr[ebp]
	sub	esi, ebx
	shr	esi ,1
	add	esi, ss:dw_data_strt[ebp]		; now points to the data place
; screen place
	movzx	edi,word ptr ss:dw_x_curr[ebp]
	mov	eax, edi
	shr	edi, 3			; screen byte position
	add	di, ss:dw_y_pos[ebp]		; locate it on screen

	and	eax, 00000007h			; positon in bit
	add	eax, 8
	bts	eax, eax
	mov	al, 08h			; register bit
;draw loop

dw_x_loop:	mov	bl, fs:[esi]		; get screen byte

	mov	bh, es:[edi]		; load latches
	out	dx, ax		; select pixel
	mov	es:[edi], bl		; write screen byte
	
	shr	bl, 4		; next screen data
	ror	ah, 1		; next pixel
	jc	dw_first_inc		; onto next screen byte?
	
	mov	bh, es:[edi]		; load latches
	out	dx, ax		; select pixel
	mov	es:[edi], bl		; write data

	ror	ah, 1		; next pixel
	jc	dw_sec_inc		; on to next screen byte?

	inc	esi
	loop	dw_x_loop

;-------------------------
; get next x section

dw_here:	movzx	eax, word ptr ss:dw_curr_x_sec[ebp]	; current x section
	mov	bx, gs:sc_x_end[eax]
	cmp	bx, 0ffffh			; if x_end = ffffh then next_y
	je	dw_next_y
	mov	ss:dw_x_curr[ebp], bx		; set x_curr to x_end
	movzx	eax,word ptr gs:sc_x_next[eax]		; the next x_section
	mov	ss:dw_curr_x_sec[ebp], ax		; current = next
	jmp	dw_x_sec_loop	
	
dw_sec_inc:	inc	edi		; increment screen byte
	mov	ah, 80h
	inc	esi
	loop	dw_x_loop
	jmp	dw_here

dw_first_inc:	inc	edi		; increment screen byte
	mov	ah, 80h
	mov	bh, es:[edi]		; load latches
	out	dx, ax		; select pixel
	mov	es:[edi], bl		; write data

	ror	ah, 1		; next pixel
	inc	esi
	loop	dw_x_loop
	jmp	dw_here

;-------------------------
; next y loop

dw_next_y:	mov	eax, ss:dw_x_width[ebp]
	add	ss:dw_data_strt[ebp], eax	; next data line
	add	ss:dw_y_pos[ebp],word ptr 80	; next screen line
	dec	word ptr ss:dw_y_count[ebp]
	jne	dw_y_loop		; not finished
	
;-------------------------
; next chain entry

dw_chn_next:	movzx	eax, word ptr ss:dw_curr_chain[ebp]	; next chain
	movzx	eax, word ptr gs:sc_next[eax]
	mov	ss:dw_curr_chain[ebp], ax
	cmp	eax, 0ffffh			; is it the last chain
	jne	dw_chn_loop

;-------------------------
; exit
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	pop	fs
	pop	es
	leave
	ret	2
	
;-------------------------
; Full line masked

dw_full_mask:	movzx	ebx, word ptr gs:sc_lower_y[eax]	; get the y count
	movzx	ecx, word ptr gs:sc_upper_y[eax]
	sub	ebx, ecx			; get the size of masked area
	imul	ebx, ss:dw_x_width[ebp]		; the number of bytes to skip
	add	ss:dw_data_strt[ebp], ebx
	jmp	dw_chn_next			; go around