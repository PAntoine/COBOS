comment	#===========================================
	           Create Gate Descriptor

	This procedure will create a gate descriptor
	and return the new descriptor number in EAX.
	The offset is unused if the gate points to a
	TSS.
	
	       (c)1995             P.Antoine.

	Note: The stack should look like this
	2 	EIP
	4	SELECTOR
	6	RIGHTS + COUNT
	8	OFFSET (Dword)

	#==========================================

cr_gate_desc:	enter	0,0
	push	ecx
	push	es
	push	ds

	mov	ax, sys_segment
	mov	ds, ax
	mov	es, ds:[desc_table]	; load descritor selector
	movzx	ecx, word ptr ds:[GDT_size]	; GDT size

cr_gate_loop:	cmp	es:[ecx * 8], dword ptr 0h	; see if GDT entry is empty
	je	cr_gate_found		; empty segment
	loop	cr_gate_loop	 
		
	;** <not found> **
	xor	eax,eax		;clear eax
	jmp	cr_gate_exit

cr_gate_found:	cmp	ecx, 00h		; if ecx is 00 then the GDT(0) place has been found
	jne	cr_gate_ok		; not zero so the world is wonderful
	xor	eax,eax		; clear EAX, i.e. error
	jmp	cr_gate_exit		; ** the error procedure should be called here!!			 	

cr_gate_ok:	shl	ecx, 3		; times 8 so it points to the right place
	mov	eax, ss:8[ebp]		; Offset
	mov	es:[ecx], ax		; offset low-word
	shr	eax, 16
	mov	es:[ecx+6], ax		; offset high-word
	mov	ax, ss:4[ebp]
	mov	es:[ecx+2], ax		; load (gate) selector
	mov	ax, ss:6[ebp]
	mov	es:[ecx+4], ax		; load desc rights + word count

	mov	eax, ecx		; load selector in EAX

cr_gate_exit:	pop	ds
	pop	es		; resrore ES
	pop	ecx
	leave
	ret	8