comment	#======================================================
		      User Input
	
	This procedure will run off the keyboard interrupt.
	It will handle both the PS/2 mouse and the keyboard.
	It will send a message to the user_task with the
	information that is passed to it.
	
		        Version 1.1
 		Copyright (c) 1996&7 P.Antoine
	
	This procedure is a task and should be set up as
	follows:

	ES - System segment     DS - task list
	GS - Post Box           FS - <variable>

	ESI - holds the current state of the CAPS-LOCK

	EDI - is used as a keyboard current state byte
		bit 0 - shift pressed
		bit 1 - ctrl pressed
		bit 2 - alt pressed

	#=====================================================
	
User_input:	call	ack_PIC		; acknowledge the PIC
	in	al, 64h		; get keyboard status
	bt	ax, 5		; is it the AUX (mouse)?
	jc	ui_mouse
	
;----------------------
; input keyboard data

ui_key_in:	in	al, 60h		; get character from keyboard
	cmp	al, 01h		; has <esc> been pressed
	je	cobos_exit		; YES!

; special key checks

	cmp	al, 0e0h		; ignore the "e0" byte
	je	ui_key_in
	cmp	al, 0e1h		; ignore the "e1" byte
	je	ui_key_in
	
; check the shifts
	cmp	al, 0bah		; caps lock break?
	je	ui_caps_lock

	cmp	al, 0aah		; is a shift break
	je	ui_shift_break
	cmp	al, 0b6h		; is a shift break
	je	ui_shift_break
	
	cmp	al, 2ah		; is it a shift key
	je	ui_shift_make
	cmp	al, 36h		; is another shift key
	je	ui_shift_make

	bt	ax, 07h		; is it a break key?
	jc	ui_exit	

; do I send the key to the task?

	btr	es:[sys.semaphores],ss_exception	; is the exception bit set?
	jc	ui_clr_excpt	

	cmp	es:[sys.user_task],word ptr 00h ; is there a user task?
	je	ui_exit		; no!

; send the key to the task

	xor	ebx, ebx
	mov	bx, es:[sys.user_task]
	mov	fs, ds:TCB_seg[ebx*8]	; load TCB of user task
	bt	fs:[TCB.status], t_KB	; is the keyboard bit set?
	jnc	ui_exit		; no!
	
	mov	gs, es:[sys.kb_post]	; get the post box
	bsf	ecx, gs:[0]
	jz	ui_exit		; post box is full!
	
	mov	gs:pb_kb_task[ecx*8], bx	; the user task
	mov	gs:pb_kb_bytes[ecx*8],byte ptr 3 ; message size
	mov	gs:pb_kb_mess[ecx*8], 01h	; type "01" - keyboard
	mov	bx, di
	mov	gs:pb_kb_mess+1[ecx*8], al	; the keypress
	mov	gs:pb_kb_mess+2[ecx*8], bl	; the status byte

	btr	gs:[0], ecx		; tell the post box there is a message
	mov	gs, es:[sys.post_box]
	btr	gs:[TCB.status], t_suspended	; unsuspend the post box	
	jmp	ui_exit

ui_shift_make:	mov	ebx, esi
	btc	ebx, 0		; toggle the shift bit
	and	edi, 0fffffffeh		; clear the shift bit
	or	edi, ebx
	jmp	ui_exit
	
ui_caps_lock:	btc	esi, 0

ui_shift_break:	mov	ebx, esi
	and	edi, 0fffffffeh		; clear the shift bit
	or	edi, ebx
	jmp	ui_exit	

;---------------------
; input mouse data

ui_mouse: jmp   cobos_exit      

	xor	eax, eax		; clear ax
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx

	in	al, 60h		; read mouse status (byte 1)
	mov	bx, ax
	
	in	al, 60h		; read res byte 1 (?)
	in	al, 60h		; read x movement
	mov	dx, ax
	
	in	al, 60h		; read res byte 2 (?)
	in	al, 60h		; read y movement
	mov	cx, ax
	
	in	al, 60h		; read res byte 3 (?)
	in	al, 60h		; read z movement       (unused)
	in	al, 60h		; read res byte 4 (?)
	
;------------------------------
; check and amend mouse move x
	
	bt	bx, 4		; did the mouse move x negative
	jnc	ui_y_pos
	neg	dx

;------------------------------
; check and amend mouse move y

ui_y_pos:	bt	bx, 5		; did the mouse move y negative
	jnc	ui_m_check
	neg	cx

;-----------------------------
; do the mouse checks

ui_m_check:     and	bx, 02h		; clear mouse byte except buttons
	push	word ptr bx		; push button state
	push	word ptr cx		; push y offset
	push	word ptr dx		; push x offset
	call	check_mouse
	jmp	ui_exit

;----------------------------
; clear exception box

ui_clr_excpt:	mov	fs, es:[sys.exception_spc]	; get the exception space
	movzx	eax, fs:[xc_spc.xc_window]	; get the exception window
	mov	fs, es:[sys.hot_spot]	; get the hot spot table
	imul	eax, hs_size
	btr	fs:hs_status[eax], hs_active	; clear the hot spot active bit
	bts	fs:hs_status[eax], hs_clear	; sets the window clear bit
	
;--------------------------
; exit now

ui_exit:        iret
	jmp	User_input	; This is a task so must loop!!!!
