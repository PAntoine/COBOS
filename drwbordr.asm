comment	#===========================================================

		         Draw Border
		         
	 This function will draw a standard COBOS border around a
	 window, from the origin to the max_x, max_y.
	 
	 	Version 1 Copyright 1996 P.Antoine
	 	      32bit COBOS Project
	 	      
	  Input:
	 	word: screen number
		word: background colour
	 
	 #===========================================================

db_inval_srn	equ	error_code<system_err,failure,system_error<,h_table,e_not_exist,0,0>>

db_srn_num	equ	8		; screen number
db_backgnd	equ	10		; background colour

draw_border:	enter	0,0
	push	ds
	push	es
	push	fs
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	mov	ax, sys_segment
	mov	fs, ax
	mov	fs, fs:[sys.hot_spot]	; load the hot spot table
	
	movzx	eax, word ptr ss:db_srn_num[ebp]
	imul	eax, hs_size		; position in table

	cmp	fs:hs_owner[eax], 00	; if 00 no owner - not in use
	jne	db_win_found
	
	mov	eax, db_inval_srn	; error - window specified not in use
	jmp	db_exit

;------------------------
; clear the window
	
db_win_found:	les	ebx, fword ptr fs:hs_graphic[eax]
	movzx	ecx, word ptr fs:hs_max_y[eax]
	mov	edi, ecx
	sub	edi ,3
	movzx	ebx, word ptr fs:hs_max_x[eax]
	imul	ecx, ebx		; max number of bytes in window
	imul	edi, ebx
	shr	ecx, 1
	shr	edi, 1
	movzx	ebx, word ptr ss:db_backgnd[ebp]
	mov	bh, bl
	shl	bl, 4
	or	bl, bh

db_clear:	mov	es:[ecx], bl
	loop	db_clear
	jmp	db_exit
	
;-------------------
; draw bottom

	movzx	ecx,word ptr fs:hs_max_x[eax]
	shr	ecx,  1		; bytes across the screen
	mov	ebx, edi
	add	ebx, ecx
	mov	edx, edi
	add	edx, ecx
	add	edx, ecx

db_bot:	mov	es:[ecx+edi], byte ptr 077h
	mov	es:[ecx+ebx], byte ptr 088h
	mov	es:[ecx+edx], byte ptr 088h	
	loop	db_bot	

;-------------------
; draw top border

	movzx	ecx,word ptr fs:hs_max_x[eax]
	shr	ecx,  1		; bytes across the screen
	mov	ebx, ecx
	
db_top:	mov	edx, ebx
	mov	es:[ecx], byte ptr 0ffh
	mov	es:[ecx+edx], byte ptr 0ffh
	shl	edx, 1
	mov	es:[ecx+edx], byte ptr 077h
	add	edx, ebx
	mov	es:[ecx+edx], byte ptr 077h
	loop	db_top	

;-----------------
; draw down edges

	movzx	ecx, fs:hs_max_y[eax]
	sub	ecx, 2		; seven lines drawn
	les	ebx, fword ptr fs:hs_graphic[eax]	; reaload the start pos

	movzx	esi, fs:hs_max_x[eax]
	shr	esi, 1

db_down:	mov	es:[ebx],  011117fffh
	mov	es:4[ebx], 011111111h
	mov	es:8[ebx], 077888871h
	add	ebx, esi

	mov	es:-4[ebx], 088777777h	; top left
	loop	db_down

;----------------------
; draw top corners

	les	ebx, fword ptr fs:hs_graphic[eax]
	movzx	esi, fs:hs_max_x[eax]
	shr	esi, 1
	
	mov	es:[ebx],  0ffffffffh
	mov	es:4[ebx], 0ffffffffh
	mov	es:8[ebx], 0ffffffffh
	add	ebx, esi
	
	mov	es:-4[ebx], 0ffffffffh	; top right corner

	mov	es:[ebx],  0ffffffffh
	mov	es:4[ebx], 0ffffffffh
	mov	es:8[ebx], 0ffffffffh
	add	ebx, esi
	
	mov	es:-4[ebx], 08fffffffh
	
	mov	es:[ebx],  0ffffffffh	; top left corner
	mov	es:4[ebx], 0ffffffffh
	mov	es:8[ebx], 07788ffffh
	add	ebx, esi
	
	mov	es:-4[ebx], 088777777h	; top right corner
	
	mov	es:[ebx],  0ffffffffh	; top left
	mov	es:4[ebx], 0ffffffffh
	mov	es:8[ebx], 077888fffh
	add	ebx, esi
	
	mov	es:-4[ebx], 088777777h	; top right
	
	mov	es:[ebx],  0ffffffffh	; top left
	mov	es:4[ebx], 0ffffffffh
	mov	es:8[ebx], 0778888ffh
	add	ebx, esi
	
	mov	es:-4[ebx], 088777777h	; top right
	
	mov	es:[ebx],  077777fffh	; top left
	mov	es:4[ebx], 077777777h
	mov	es:8[ebx], 077888877h
	add	ebx, esi

;------------------
; drw left bottom	

	mov	es:[edi],  077777fffh	; top left
	mov	es:4[edi], 077777777h
	mov	es:8[edi], 077888877h
	add	edi, esi

	mov	es:[edi],  0888888ffh	; top left
	mov	es:4[edi], 088888888h
	mov	es:8[edi], 088888888h
	add	edi, esi

	mov	es:[edi],  08888888fh	; top left
	mov	es:4[edi], 088888888h
	mov	es:8[edi], 088888888h

	xor	eax, eax		; all is ok
	
;-----------------
; exit
	
db_exit:	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	fs
	pop	es
	pop	ds
	leave
	ret	4