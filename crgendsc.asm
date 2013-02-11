comment	#=======================================================
	               Create General Descriptor

	This procedure will create a general descriptor, and
	return the new descriptor number in EAX.
	
	Input:	word:  cgd_type
		dword:  cgd_limit
		dword: cgd_base
	Output:
	(dword)	00 - ax: the new selector number 
	(dword)	eax:     error code

	       (c)1995 & 1996     P.Antoine.

	Version 2: converted to 32bit for the COBOS Project

	#======================================================

cgd_type	equ	8
cgd_limit	equ	10
cgd_base	equ	14
cgd_tbl_full	equ	error_code<system_err,failure,system_error<,g_table,e_full,0,0>>

cr_gen_desc:	enter	0,0
	push	ecx
	push	es
	push	ds

	mov	ax, sys_segment
	mov	ds, ax

;-----------------------
; Find a freespace

cr_wait:	bts	ds:[sys.semaphores], ss_GDT	; wait for the GDT table to be free
	jnc	cr_wait	

	mov	es, ds:[sys.GDT_table]
	movzx	ecx, word ptr ds:[sys.GDT_size]	; GDT size

cr_gen_loop:	cmp	es:[ecx * 8], dword ptr 0h	; see if GDT entry is empty
	je	cr_gen_found		; empty segment
	loop	cr_gen_loop	 
	
	mov	eax, cgd_tbl_full	; error GDT table full
	jmp	cr_gen_exit

cr_gen_found:	cmp	ecx, 00h		; if ecx is 00 then the GDT(0) place has been found
	jne	cr_gen_ok		; not zero so the world is wonderful

	mov	eax, cgd_tbl_full	; error GDT table full
	jmp	cr_gen_exit	

;------------------------
; Set up the linear base

cr_gen_ok:	shl	ecx, 3		; times 8 so it points to the right place
	mov	eax, ss:cgd_base[ebp]	; load base from the stack
	mov	es:[ecx + 2], ax	; set base word 1
	shr	eax, 16
	mov	es:[ecx + 4], al	;set base byte 3
	mov	es:[ecx + 7], ah	;set base byte 4
	
;------------------------
; set the type
	movzx	eax, word ptr ss:cgd_type[ebp]
	mov	es:[ecx+5], al		;load type 

;------------------------
; set the limit
	and	es:[ecx+6], byte ptr 00h	;clear the limit bits (16-19) & the GDOA bits
	mov	eax, ss:cgd_limit[ebp]	;load limit (size)
	test	eax, 0fff00000h		; is it a large segment
	je	cr_gen_no
	shr	eax, 12		; its page granular (limit in 1 Meg incs)
	or	es:[ecx+6], byte ptr 1000000b	; set the G bit
	
cr_gen_no:	mov	es:[ecx], ax
	shr	eax, 16
	and	eax, 0000000fh		; only need last 4 bits
	or	es:[ecx+6], al		; set the upper limit
	or	es:[ecx+6], byte ptr 00100000b	; set the D bit
	
;------------------------
; set return value
	mov	eax, ecx		; load selector in EAX
	and	eax, 0000ffffh		; cleat top part of eax - worked OK!

;------------------------
; exit

cr_gen_exit:	btr	ds:[sys.semaphores], ss_GDT	; release the GDT table
	pop	ds
	pop	es		; restore ES
	pop	ecx
	
	leave
	ret	10		; 32bit - clear 8 bytes