comment	#==================================================
		   Draw Mouse
		
	This procedure will draw the mouse pointer to the
	screen. Before it writes to the screen it will
	copy the screen data from where it is going to 
	write the mouse ponter.
	
	    Version 2 Copyright (c) 1996 P.Antoine
	            COBOS project version
	
	#=================================================
	
	
draw_mouse:	enter	2,0
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	push	ds
	push	es
	push	fs
		
	mov	ax, sys_segment
	mov	fs, ax
	mov	es, ax		; load the real screen
	mov	ds, fs:[sys.real_screen]
	
;--------------------------
; set memory position

	xor	edi ,edi
	mov	di, fs:[sys.mouse_x]
	shr	edi ,3		; divide by eight
	
	xor	eax, eax
	mov	ax, fs:[sys.mouse_y]
	shl	eax, 4		; multiply by 16
	add	edi, eax
	shl	eax, 2		; multiply by 4 (16*4 = 64)
	add	edi, eax		; now points to the screen byte

;-------------------------------------
; set the VGA card writeand read mode

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

;------------------------------------------
; copy screen under
; read from es:[esi] and write to ds:[edi]

	push	edi
	mov	esi, edi
	mov	ecx, 16
	mov	edi, screen_under
	mov	dx, 3ceh		; control register

drm_save:	mov	ax, 0004h		; read plane 1 - read map select register
	out	dx, ax
	mov	ax, ds:[esi]		; read plane 1
	stosw
	
	mov	ax, 0104h		; read plane 2
	out	dx, ax
	mov	ax, ds:[esi]		; read plane 2
	stosw
	
	mov	ax, 0204h		; read plane 3
	out	dx, ax
	mov	ax, ds:[esi]		; read plane 3
	stosw
	
	mov	ax, 0304h		; read plane 4
	out	dx, ax
	mov	ax, ds:[esi]		; read plane 4
	stosw

	add	esi, 80		; next line
	loop	drm_save	
		
	pop	edi

;----------------------------
; write mouse pointer

	mov	esi, mouse_sprite	; load mouse sprite location
	mov	cx,fs:[sys.mouse_x]
	not	cx
	and	cx, 0007h		; bit shift from byte
	mov	ss:[ebp-2], word ptr 00h	; clear counter

;------------------
; set high mask

drm_write:	xor	bx,bx
	mov	bl, ds:[edi]		; load latches
	mov	bl, fs:[esi]		; load mask
	
	mov	dx, 3ceh
	mov	ax, 0008h		; VGA mask
	shl	bx, cl
	mov	ah, bh		; <--- high mask!!!
	out	dx, ax		; out new VGA mask (left part)
	mov	dx, 3c4h		; sequencer register port	

;------------------
; write high bits

	mov	ax, 0102h		; plane 1 only
	out	dx, ax
	xor	bx,bx
	mov	bl,fs:1[esi]
	shl	bx, cl
	mov	ds:[edi],bh		
	
	mov	ax, 0202h		; plane 2 only
	out	dx, ax
	xor	bx,bx
	mov	bl,fs:2[esi]
	shl	bx, cl
	mov	ds:[edi], bh
	
	mov	ax, 0402h		; plane 3 only
	out	dx, ax
	xor	bx,bx
	mov	bl,fs:3[esi]
	shl	bx,cl
	mov	ds:[edi],bh

	mov	ax, 0802h		; plane 4 only
	out	dx, ax
	xor	bx,bx
	mov	bl,fs:4[esi]
	shl	bx,cl
	mov	ds:[edi],bh

;----------------
; write low mask

	xor	bx,bx
	mov	bl, ds:1[edi]
	mov	bl, fs:[esi]		; load mask
	
	mov	dx, 3ceh
	mov	ax, 0008h		; VGA mask
	shl	bx, cl
	mov	ah, bl		; <---- low mask!!!!
	out	dx, ax		; out new VGA mask (left part)
	mov	dx, 3c4h		; sequencer register port	

;-------------------
; write low bits

	mov	ax, 0102h		; plane 1 only
	out	dx, ax
	mov	bl,fs:1[esi]
	shl	bx, cl
	mov	ds:1[edi],bl		
	
	mov	ax, 0202h		; plane 2 only
	out	dx, ax
	mov	bl, fs:2[esi]
	shl	bx, cl
	mov	ds:1[edi], bl
	
	mov	ax, 0402h		; plane 3 only
	out	dx, ax
	mov	bl,fs:3[esi]
	shl	bx,cl
	mov	ds:1[edi],bl

	mov	ax, 0802h		; plane 4 only
	out	dx, ax
	mov	bl,fs:4[esi]
	shl	bx,cl
	mov	ds:1[edi],bl
	
	add	edi, 80
	add	esi, 5
	inc	word ptr ss:[ebp-2]	; check and loop
	cmp	word ptr ss:[ebp-2], 16
	jb	drm_write	
	
;------------------------
; exit
	pop	fs
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