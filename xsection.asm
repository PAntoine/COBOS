comment	#===================================================
		   
		   X SECTION
		   
	This function will check the x_chain for the chain
	entry passed in esi. EBX will hold the screen that
	is currently being checked.
	
	    Version 1 Copyright (C) 1996 P.Antoine.
	            32Bit COBOS Project task
	
	Parameters:
		word: win_start
		word: win_end
	Registers:
	
	ES - system segment	DS - Hot Spot list
	GS - section map	FS - scratch

	#===================================================

xs_win_start	equ	8
xs_win_end	equ	10

x_section:	enter	0,0
	push	eax
	push	ebx
	
	movzx	eax, gs:sc_x_chain[esi]	; get x_chain to be searched
	
xs_loop:	mov	bx,ss:xs_win_end[ebp]
	cmp	bx,gs:sc_x_start[eax]
	jbe	xs_insert_before
	
	mov	bx, ss:xs_win_start[ebp]
	cmp	bx, gs:sc_x_end[eax]
	ja	xs_insert_after
	
	mov	bx, ss:xs_win_start[ebp]
	cmp	bx, gs:sc_x_start[eax]
	ja	xs_check_end
	
	mov	bx, ss:xs_win_start[ebp]	; x_start = win_start
	mov	gs:sc_x_start[eax], bx
	
xs_check_end:	mov	bx, ss:xs_win_end[ebp]
	cmp	bx, gs:sc_x_end[eax]
	jb	xs_exit
	
	mov	bx, ss:xs_win_end[ebx]	; x_end = win_end
	mov	gs:sc_x_end[eax], bx
	jmp	xs_exit
	
xs_insert_before:
	mov	bx, ss:xs_win_end[ebp]	; set new sections x_end
	mov	gs:sc_x_end[edi], bx
	
	mov	bx, ss:xs_win_start[ebp]	; set nex sections x_start
	mov	gs:sc_x_start[edi], bx
	
	mov	gs:sc_x_next[edi], ax	; now points to x_section that was last checked
	movzx	ebx, word ptr gs:sc_x_prev[eax]
	mov	gs:sc_x_prev[edi], bx	; current prev points to
	mov	gs:sc_x_prev[eax], di	; the old x_section now points the new
	
	cmp	bx, 0ffffh
	je	xs_ib_first
	
	mov	gs:sc_x_next[1ch], di	; set the pointer that pointted to old to new
	add	edi, 8		; set the free space pointer
	jmp	xs_exit
	
xs_ib_first:	mov	gs:sc_x_chain[esi], di	; sets the chain pointer to point to new
	add	edi, 8
	jmp	xs_exit
	
xs_insert_after:
	cmp	gs:sc_x_end[eax], word ptr 0ffffh
	je	xs_exit
	
	movzx	eax, word ptr gs:sc_x_next[eax]	; get the next chain entry
	jmp	xs_loop
	
;-----------------------
; exit

xs_exit:	pop	ebx
	pop	eax
	leave
	ret	4