comment	#=====================================================
		     Input String

		    (API FUNCTION)
	
	This function will input a string from a keyboard to
	the specifed buffer with the length of the string
	being no longer than that specified. It will require
	a <CR> for the input to end. 

	Note: The string is a cobos formatted string. The 
	leading byte is the length of the string.

	version 1.1:	COBOS version - Post Degree Version
	
		(c) 1997 P.Antoine.
	
	------------------------------------------------------
		
	Input:	word:   key_tab selector
		word:   max size
		dword:  buffer offset within selector
		word:   buffer selector
		word:   0000 - filler
		word:   y start position
		word:   x start position
		word:   text colour
		word:   screen number
	Returns:
	(eax)	Result Code.	
	
	#=====================================================

is_access_err	equ	error_code<app_3,failure,app_error<,ape_acces_vio>> ; target task does not exist

is_key_tab	equ	12
is_max_size	equ	14
is_buffer	equ	16
is_y_start	equ	24
is_x_start	equ	26
is_colour	equ	28
is_screen	equ	30

is_space	equ	-6

input_string:	enter	0,6
	push	ebx
	push	ecx
	push	edi
	push	esi
	push	es
	
;----------------------------------
; check to see if key_tab is valid

	lar	ax, ss:is_key_tab[ebp]	; get the access rights for the key tab
	jz	is_vaild_tab
	
	mov	eax,  is_access_err	; load -1 as an invalid key
	jmp	ck_exit

is_vaild_tab:	lar	ax, ss:is_key_tab[ebp]	; get the access rights for the key tab
	jz	is_ok
	
	mov	eax,  is_access_err	; load -1 as an invalid key
	jmp	ck_exit

;-----------------------------
; load the buffer
	
is_ok:	cld			; count upwards
	xor	esi, esi
	les	edi, ss:is_buffer[ebp]	; load the buffer
	mov	esi, edi
	mov	es:[esi], byte ptr 00	; clear the size byte	
	movzx	ecx, word ptr is_max_size[ebp]	; max number of characters
	lea	ebx, is_space[ebp]	; the space on the stack
	inc	edi		; make space for the size byte

;-------------------------
; read and convert loop

is_read_loop:	push	ss		; segment
	push	ebx 		; offset
	fcall	g_cobos, read_message	; call read message
	
	cmp	eax, 00
	jne	is_read_loop		; no message loop

	cmp	ss:[ebx], byte ptr 01	; is it a keyboard send?
	jne	is_read_loop

	push	word ptr ss:is_key_tab[ebp]	; keytable
	push	word ptr ss:1[ebx]	; the keyboard bytes
	fcall	g_cobos, convert_key 

	cmp	al, 61h		; is it a valid character
	jae	is_special
	
	stosb			; store the converted byte
	inc	byte ptr es:[esi]	; increase the string size

	push	es		; segment of message
	push	esi		; offset of message
	push	word ptr ss:is_y_start[ebp]	; y position
	push	word ptr ss:is_x_start[ebp]	; x position
	push	word ptr ss:is_colour[ebp]	; bg / fg colours
	push	word ptr ss:is_screen[ebp]	; screen number
	fcall	g_cobos, display_text

is_loop_end:	loop	is_read_loop		; has the max been reached
	dec	edi		; if so overwrite the last char again
	dec	byte ptr es:[esi]	; decrease the size of the string
	inc	ecx
	jmp	is_read_loop		; loop!
	
;------------------------
; check for special keys

is_special:	cmp	al, 61h
	jne	is_chk_cr
	mov	al, 60h
	stosb			; is its a tab send a space
	jmp	is_loop_end
	
is_chk_cr:	cmp	al, 62h		; is it a <CR>?
	jne	is_ck_bksp
	xor	eax, eax
	jmp	is_exit
	
is_ck_bksp:	cmp	al, 69h
	je	is_bksp		; if not a backspace drop the char
	cmp	al, 67h
	jne	is_read_loop		; or a "<-" arrow key
	
is_bksp:	cmp	byte ptr es:[esi], 00	; is the string empty?
	je	is_read_loop

	dec	edi		; move the space pointer back one
	mov	es:[edi], byte ptr 60h	; the space charater

	push	es		; segment of message
	push	esi		; offset of message
	push	word ptr ss:is_y_start[ebp]	; y position
	push	word ptr ss:is_x_start[ebp]	; x position
	push	word ptr ss:is_colour[ebp]	; bg / fg colours
	push	word ptr ss:is_screen[ebp]	; screen number
	fcall	g_cobos, display_text

	dec	byte ptr es:[esi]	; decress the size of the string
	inc	ecx		; incress the count
	jmp	is_read_loop
	
;------------------------
; exit

is_exit:	pop	es
	pop	esi
	pop	edi
	pop	ecx
	pop	ebx
	leave
	retf	20