comment	#========================================================

		    Copy X Chain
		
	 This function will copy the x chain pointed to by ESI to
	 the y chain pointed to by EBX.
	 	 
	 	Copyright 1996 P.Antoine
	 	
	 	Version 1 COBOS Project
	 	 
	 Parameters:
		ESI - y chain to copy the x chain from
	 	EBX - y chain to copy the x chain to
		EDI - free space pointer
	 Returns:
	 	None
	---------------------------------------------------------
	 Registers:
	 
	  ES - system segment	DS - Hot Spot list
	  GS - section map	FS - scratch
	  
	#========================================================

copy_x_chain:	enter	0,0
	push	eax
	push	ebx
	push	ecx

	mov	gs:sc_x_chain[ebx], di	; set the start pointer to the new x-chain
	movzx	eax, gs:sc_x_chain[esi]	; get the start of the x chain
	
;--------------------------
; initialise the new chain
	
	mov	gs:sc_x_prev[edi], word ptr 0ffffh	; first entry is allows zero
	
;--------------------------
; copy the chain

cxc_loop:	mov	bx, gs:sc_x_start[eax]	; get the x start
	mov	gs:sc_x_start[edi], bx
	
	mov	bx, gs:sc_x_end[eax]
	mov	gs:sc_x_end[edi], bx	; copy x end

	mov	ecx, edi	
	add	edi ,8		; move the free space pointer
		
	cmp	gs:sc_x_next[eax], word ptr 00
	je	cxc_exit		; if at end of chain then exit
	
	mov	gs:sc_x_next[ecx], di	; set the forward pointer
	mov	gs:sc_x_prev[edi], cx	; set the backward pointer
	
	movzx	eax, word ptr gs:sc_x_next[eax]	; get the next chain entry
	jmp	cxc_loop
	
;-------------------------
; exit

cxc_exit:	mov	gs:sc_x_next[ecx], word ptr 00	; last entry next must = 00
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret	