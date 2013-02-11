
;**************************************************
; Display the contents of the EAX registers as 
; Hexadecimal characters. The GS register should
; be loaded with the screen selector. The di
; register should be the screen position.
;**************************************************
disp_hex:	push	ecx
	push	ebx
	push	eax
	push	gs
	push	ds
	mov	bx, sys_segment
	mov	ds, bx
	mov	gs, ds:[sys.real_screen]

	mov	ecx, 08h
	add	di, 10h
a_loop:	mov	bx, ax
	and	bx, 000fh
	cmp	bx, 09h		; numbers or a-f
	jg	b_loop		; it is a letter
	add	bx, 0430h
	jmp	print
b_loop:	add	bx, 0437h
print:	mov	word ptr gs:[di], bx	; display a character
	sub	di, 2		; next screen position
	shr	eax, 4		; next charater
	loop	a_loop
	add	di, 10h

	pop	ds
	pop	gs
	pop	eax
	pop	ebx
	pop	ecx
	ret
