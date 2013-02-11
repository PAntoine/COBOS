comment	#========================================================

		    Build Overlap Map
		
	 This function will create a map of the parts of the 
	 screen to be redrawn that are over lapped. This map
	 will be stored in the data segment in GS.
	 
	 	Copyright 1996 P.Antoine
	 	
	 	Version 2 COBOS Project
	 	 (version 1 was crap)
	 	 
	 Parameters:
	 	word: screen number
	 Returns:
	 	overlay map starting at GS:00000000
	---------------------------------------------------------
	 Registers:
	 
	  ES - system segment	DS - Hot Spot list
	  GS - section map	FS - scratch
	  
	#========================================================
	
bm_scrn_num	equ	8

build_map:	enter	0,0
	push	eax	
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	
	xor	edi, edi			; make free space pointer 0
	xor	esi, esi			; current chain pointer

;-------------------------
; set up inital y chain

	movzx	eax, word ptr ss:bm_scrn_num[ebp]	; get the screen number
	imul	eax, hs_size			; poision the screen in memory
	
	movzx	ebx, ds:hs_top_y[eax]
	mov	gs:sc_upper_y[edi], bx		; set the top of the first y_section
	
	movzx	ebx, ds:hs_bot_y[eax]
	mov	gs:sc_lower_y[edi], bx		; set the bottom of the first y_section
	
	mov	gs:sc_next[edi], word ptr 0ffffh	; set the next pointer to 0
	mov	gs:sc_prev[edi], word ptr 0ffffh	; set the prev pointer to -start
	mov	gs:sc_x_chain[edi], word ptr 10		; first x chain starts 10 bytes in
	add	edi,10
	
;-------------------------
; set up initial x chain

	movzx	ebx, ds:hs_bot_x[eax]
	mov	gs:sc_x_start[edi], bx		; get the far edge (x)
	
	mov	gs:sc_x_end[edi],word ptr 0ffffh	; the means there is no more after
	mov	gs:sc_x_next[edi], word ptr 00		; clear the chain pointers
	mov	gs:sc_x_prev[edi], word ptr 00
	add	edi ,8

	jmp	bm_exit			; ***** BUG GET AROUND ******
	
;-------------------------
; get the top window

	movzx	eax, word ptr es:[top_hs_entry]		; the top screen
	
;-------------------------
; do the check loop

bm_win_loop:	cmp	ax, ss:bm_scrn_num[ebp]
	je	bm_exit			; reached the window to be redrawn
	
	cmp	eax, 00
	je	bm_exit			; no more screens

	imul	eax, hs_size			; position in the hs table
	
	mov	cx, ds:hs_top_y[eax]		; win top
	mov	dx, ds:hs_bot_y[eax]		; win bottom
	
bm_chain_loop:	cmp	dx, gs:sc_upper_y[esi]		; does window end before chain starts?
	jb	bm_next_win			; YES! goto next window
	
	cmp	cx, gs:sc_lower_y[esi]		; does window start after chain?
	ja	bm_next_chain			; YES! check next chain
	
;-----------------------------
; does the window cover chain

	cmp	cx, gs:sc_upper_y[esi]		; does win top start before chain
	ja	bm_chk_start			; NO!
	cmp	dx, gs:sc_lower_y[esi]		; does win end finish after chain
	jb	bm_chk_end
	
	push	word ptr ds:hs_bot_x[eax]		; the x end
	push	word ptr ds:hs_top_x[eax]		; the x start
	call	x_section			; do the x_chain for this entry
	
	cmp	dx, gs:sc_lower_y[esi]
	je	bm_next_win			; if lower = win lower goto next win
	
	mov	cx, gs:sc_lower_y[esi]		; search next chain with lower as top
	jmp	bm_next_chain
	
;---------------------------------
; does the windows start in chain

bm_chk_start:	cmp	cx, gs:sc_upper_y[esi]		; if windows starts in chain?
	jb	bm_chk_end			; NO! checkto see if it ends there

	push	es
	mov	es, es:[sys.real_screen]		; load the real screen
	mov	es:[8000], 0fffffffh
	pop	es
	
	mov	bx, gs:sc_lower_y[esi]		; new.lower = old.lower
	mov	gs:sc_lower_y[edi], bx
	
	mov	gs:sc_lower_y[esi], cx		; old.lower = win_top
	mov	gs:sc_upper_y[edi], cx		; new.upper = win_top 
	inc	word ptr gs:sc_upper_y[edi]		; +1

	movzx	ebx, word ptr gs:sc_next[esi]		; old.next
	mov	gs:sc_next[edi], bx		; new.next = old.next
	mov	gs:sc_next[esi], di		; old.next = new
	mov	gs:sc_prev[edi], si		; new.prev = old

	cmp	bx, 0ffffh			; start of chain?
	je	bm_srt_cpy			; YES!
	
	mov	gs:sc_prev[ebx], di		; [old.prev].next = new

bm_srt_cpy:	mov	ebx, edi
	add	edi, 10
	call	copy_x_chain			; copy from esi to ebx

	mov	esi, ebx			; no need to search new section
	push	word ptr ds:hs_bot_x[eax]		; the x end
	push	word ptr ds:hs_top_x[eax]		; the x start
	call	x_section			; do the x_chain for this entry
	
;-------------------------------
; does the windows end in chain

bm_chk_end:	cmp	dx, gs:sc_lower_y[esi]		; if windows ends in chain?
	ja	bm_next_chain

	mov	bx, gs:sc_upper_y[esi]		; get old upper
	mov	gs:sc_upper_y[edi], bx		; save in new upper
	
	mov	gs:sc_upper_y[esi], dx		; old upper = win end
	inc	word ptr gs:sc_upper_y[esi]		; +1
	mov	gs:sc_lower_y[edi], dx		; win bot = new bot

	movzx	ebx, word ptr gs:sc_prev[esi]		; old.prev
	mov	gs:sc_prev[edi], bx		; new.prev = old.prev
	mov	gs:sc_prev[esi], di		; old.prev = new
	mov	gs:sc_next[edi], si		; new.next = old

	cmp	bx, 0ffffh			; start of chain?
	je	bm_end_cpy			; YES!
	
	mov	gs:sc_next[ebx], di		; [old.prev].next = new

bm_end_cpy:	mov	ebx, edi
	add	edi, 10
	call	copy_x_chain			; copy from esi to ebx

	push	es
	mov	es, es:[sys.real_screen]		; load the real screen
	mov	es:[8180], 0f0f00f0fh
	pop	es

;	mov	esi, ebx
	push	word ptr ds:hs_bot_x[eax]		; the x end
	push	word ptr ds:hs_top_x[eax]		; the x start
	call	x_section			; do the x_chain for this entry

	push	es
	mov	es, es:[sys.real_screen]		; load the real screen
	mov	es:[8160], 0f000000fh
	pop	es

	jmp	bm_next_win
		
;-------------------
; next chain

bm_next_chain:	movzx	esi, word ptr gs:sc_next[esi]		; get the next chain
	cmp	esi, 0ffffh			; if not at the end of chain, loop
	jne	bm_chain_loop	
	
;-------------------
; next window

bm_next_win:	movzx	eax, word ptr ds:hs_chain[eax]		; next window in hot spot chain
	xor	esi, esi
	jmp	bm_win_loop
	
;-------------------
; exit

bm_exit:	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret	2