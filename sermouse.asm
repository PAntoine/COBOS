comment	#=======================================================

		      Serial Mouse
		
	This function will control the access of a serial mouse
	thought a COM port. It will use the check_mouse system
	function if it detects a mouse click.
	
	      Version 2 Copyright (C) 1996 P.Antoine.
		COBOS Project Version
	
	This procedure is a task and should be set up as follows:
	
	ES - System segment     DS - task list
	GS - <not used>         FS - <variable>
	
	#========================================================
	
serial_mouse:	xor	eax, eax
;	mov	dx, 03f8h
;	in	al, dx		; get from COM port byte
	mov	dx, 02f8h
	in	al, dx
	bt	ax, 6
	jc	srm_new_pkt
	
	cmp	cx, 01		; 00 x-byte
	je	srm_y_cord
	ja	srm_exit        
	
;----------------
; get x-cord
	inc	cx		; count of the number of packets read
	mov	dx, bx
	and	dl, 0011b		; x disp 6-7
	shl	dl, 6
	and	al, 00111111b		; x disp 0-5
	or	al, dl		; now x displacement
	movsx	si, al		; store the x position
	jmp	srm_exit

;-----------------
; new mouse paket

srm_new_pkt:	xor	cx ,cx
	mov	bl, al		; mouse status byte
	jmp	srm_exit        
	
;-----------------
; amend y_cord

srm_y_cord:	inc	cx
	mov	dx, bx
	and	dl, 1100b		; y disp 6-7
	shl	dl, 4
	and	al, 00111111b		; y disp 0-5
	or	al, dl		; now y displacement
	movsx	di, al
		
;------------------
; redraw the mouse

srm_chk_move:	shr	bx, 4		; position mouse buttons a bits 1+2
	and	bx, 03h		; only want the mouse buttons
	push	word ptr bx		; push mouse button
	push	word ptr di		; push y position
	push	word ptr si		; push x position
	call	check_mouse

;----------------
; exit
	
srm_exit:	call	ack_PIC		; acknowledge the PIC
	iret
	jmp	serial_mouse		; This is a task so must loop!!!!
