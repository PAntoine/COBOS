comment	#=======================================================
		     Clear Mouse
		
	This procedure will write the saved area from under the
	mouse back to the real screen at the the last mouse 
	position. It uses the screen_under area from the system 
	segment to write to the screen.
	
	      Version 2 Copyright (c) 1996. P.Antoine.
	      	COBOS Project Version
	      
	#=======================================================
	
clear_mouse:	enter	0,0
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	push	ds
	push	es
	
	mov	ax, sys_segment
	mov	ds, ax
	mov	es, ds:[sys.real_screen]	; load the real screen
	
;--------------------------
; set memory position

	xor	edi ,edi
	mov	di, ds:[sys.mouse_x]
	shr	di ,3		; divide by eight
	
	xor	eax, eax
	mov	ax, ds:[sys.mouse_y]
	shl	eax, 4		; multiply by 16
	add	edi, eax
	shl	eax, 2		; multiply by 4 (16*4 = 64)
	add	edi, eax		; now points to the screen byte
	
;-----------------------------
; set the VGA card write mode

	mov	dx, 3ceh		; control port
	mov	ax, 0005h		; read 0 write 0
	out	dx, ax
	
	mov	ax, 0003h		; set to data replace
	out	dx, ax
	
	mov	ax, 0f00h		; set SR to all bit planes
	out	dx, ax
	
	mov	ax, 0001h		; set ESR to no planes
	out	dx ,ax
	
	mov	ax, 0ff08h		; bit mask
	out	dx, ax	

;------------------------------------------------
; copy back memory using the sequencer register
; to mask what planes to write to.
 
	mov	ecx, 16		; mouse hight
	mov	dx, 3c4h		; sequencer register
	mov	esi, screen_under	; offset of the screen data 
	

clm_draw:	mov	ax, 0102h		; bit plane 1 only
	out	dx, ax
	lodsw			; load ax 
	mov	es:[edi], ax	

	mov	ax, 0202h		; bit plane 2 only
	out	dx, ax
	lodsw			; load ax 
	mov	es:[edi], ax	

	mov	ax, 0402h		; bit plane 3 only
	out	dx, ax
	lodsw			; load ax 
	mov	es:[edi], ax	

	mov	ax, 0802h		; bit plane 4 only
	out	dx, ax
	lodsw			; load ax 
	mov	es:[edi], ax	

	add	edi, 80		; next line
	loop	clm_draw
	
;----------------------------
; exit clear_screen

	pop	es
	pop	ds
	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret