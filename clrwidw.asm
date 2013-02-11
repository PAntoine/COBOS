comment	#===========================================================

		         Clear Window
		         
	 This function will clear a window from the screen. This
	 function will just blabk the screen, and will not set any
	 of the redraw bits for the underlying screens.
	 	 
	 	Version 1 Copyright 1996 P.Antoine
	 	      32bit COBOS Project
	 	      
	  Input:
	 	word: screen number
	  Registers:
	
	   ES - system segment	DS - Hot Spot list
	   GS - real screen	FS - scratch
	 
	#===========================================================

clrw_number	equ	8		; the screen number
clrw_width	equ	-4		; with of the window in bytes

clear_window:	enter	4,0
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ds
	push	fs

;--------------------
; get hots table

clrw_wait:	bts	es:[sys.semaphores], ss_hots	; wait for hot spot table	
	jnc	clrw_wait		
	
	movzx	ebx,word ptr ss:clrw_number[ebp]
	imul	ebx, hs_size		; position in the hot spot table
	
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
	
	mov	ax, 0ff08h		; set the mask to be all planes
	out	dx, ax

;-----------------------
; position screen mem

	mov	ds, es:[sys.hot_spot]	; get the hot spots
	mov	fs, es:[sys.real_screen]	; get the screen
	
	movzx	edi, ds:hs_top_y[ebx]
	imul	edi, 80		; position on line edi
	
	movzx	eax, ds:hs_top_x[ebx]	; the x postion
	shr	eax, 3		; divide by 8 - now in bytes
	add	edi, eax		; total start position
	
;------------------------
; clear the screen

	movzx	esi, ds:hs_bot_y[ebx]
	movzx	eax, ds:hs_top_y[ebx]
	sub	esi, eax		; hight of widow on screen
	
	movzx	ecx, ds:hs_bot_x[ebx]
	movzx	eax, ds:hs_top_x[ebx]
	sub	ecx, eax		; width of the screen segment
	shr	ecx, 3		; divide by eight
	mov	ss:clrw_width[ebp], ecx	; save the width of the screen
	xor	eax, eax		; clear eax

;----------------------
; clear the start
	
clrw_main:	mov	eax, 0ffh		; load a mask
	movzx	ecx, ds:hs_top_x[ebx]
	and	ecx, 07h		; bits from right hand side of the screen
	shr	eax, cl
	mov	ah, al
	mov	al, 08h		; sset the mask register
	out	dx, ax
	
	mov	al, fs:[edi]		; load the latches
	mov	fs:[edi], byte ptr 00h	; clear only the partial bit of the screen	
	mov	ax, 0ff08h		; set the mask to be all planes
	out	dx, ax

	mov	al, 00h
	mov	ecx, ss:clrw_width[ebp]	; reset count
	inc	edi		; the part bit written
	dec	ecx		; the part bit written

;----------------------
; clear the line
	
clrw_xxx:	mov	fs:[edi], al
	inc	edi
	loop	clrw_xxx

;----------------------
; clear part end

	mov	eax, 0ffh		; load a mask
	movzx	ecx, ds:hs_top_x[ebx]
	and	ecx, 07h		; bits from right hand side of the screen
	xor	ecx, 07h		; now how many bits from the left
	shl	eax, cl
	mov	ah, al
	mov	al, 08h		; sset the mask register
	out	dx, ax
	
	mov	al, fs:[edi]		; load the latches
	mov	fs:[edi], byte ptr 00h	; clear only the partial bit of the screen	

;----------------------
; next line
	sub	edi, ss:clrw_width[ebp]
	add	edi, 80		; next line of the screen
	dec	esi		; hight of screen to clear
	jnz	clrw_main

;-----------------------
; exit 

clrw_exit:	btr	es:[sys.semaphores], ss_hots	; release to hot spot table
	
	pop	fs
	pop	ds
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret	2