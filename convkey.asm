comment	#=====================================================
		     Convert_Key

		    (API FUNCTION)
		
	This procedure will convert the keypress from a key
	into the current charater set that the application is
	using. The keyboard table is taken as a parameter. The
	keypress comes is a two byte format:
	  
	        Byte2		 Byte1
	       xxxxxACS               <Key Number>
	
	Where A = alt, C = Ctrl, and S = Shift.
	
	The Key_tab must have the following format:
	
	4bytes across in key_number index order.
	byte1: normal keypress value, byte2: shift char,
	byte3: ctrl value, byte 4: alt char value. -1 in any
	entry means the value is not set.
	
	version 1.1:	COBOS version - Post Degree Version
	
		(c) 1997 P.Antoine.
	
	------------------------------------------------------
		
	Input:	word:   keyboard pair
		word:   key_tab selector
	Returns:
	(ax)	Converted value	
	
	#=====================================================
	
ck_key_in	equ	12
ck_key_tab	equ	14

convert_key:	enter	0,0
	push	ds
	push	ebx
	push	edx

;----------------------------------
; check to see if key_tab is valid

	lar	ax, ss:ck_key_tab[ebp]	; get the access rights for the key tab
	jz	ck_vaild_tab
	
	mov	eax,  0ffh		; load -1 as an invalid key
	jmp	ck_exit
	
;-----------------------
; load the key tab

ck_vaild_tab:	mov	ds, ss:ck_key_tab[ebp]	; load the keyboard tab
	mov	bx, ss:ck_key_in[ebp]	; get the key and status bits
	
	movzx	edx, bl		; get the key
	movzx	eax, byte ptr ds:[edx*4]	; get the standard value
	cmp	bh, 00h
	je	ck_exit		; no bits exit
	
	movzx	eax, byte ptr ds:1[edx*4]	; get the shift value
	bt	bx, 8h
	jc	ck_exit		; shift bit set
	
	movzx	eax, byte ptr ds:2[edx*4]	; get the ctrl value
	bt	bx, 9h
	jc	ck_exit		; ctrl bit set
	
	movzx	eax, byte ptr ds:3[edx*4]	; get the alt value

;--------------------
; exit

ck_exit:	pop	edx
	pop	ebx
	pop	ds
	leave
	retf	4		
	