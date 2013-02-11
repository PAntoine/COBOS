comment	#=====================================================
		    Add Hot Spot

		   (API FUNCTION)
	         
	  This function will add an hotspot to the hot spot
	  table. If will look for a free space then just add
	  the entry. The first entry (0) in the table will 
	  be empry.
	
	Parameters:
		word: owner of the screen
		word: screen top x
		word: screen top y
		word: screen bottom x
		word: screen bottom y
		word: window max x pixels
		word: window max y lines
		word: window relative start pixel
		word: window relative start line
		word: target task for the hot spot
		word: message length
		fword: seg:offset - message
		fword: seg:offset - graphic
		word: status byte
	Returns:
	(eax)	ax:  screen number (upper word 0000)
		eax: error code
	
	
	         Version 1: for the COBOS Project.
	
	            Copyright. 1996 P.Antoine
	         
	#======================================================

ahs_tbl_full	equ	error_code<system_err,failure,system_error<,h_table,e_full,0,0>>
	
ahs_owner	equ	12
ahs_top_x	equ	14
ahs_top_y	equ	16
ahs_bot_x	equ	18
ahs_bot_y	equ	20
ahs_max_x	equ	22
ahs_max_y	equ	24
ahs_rel_x	equ	26
ahs_rel_y	equ	28
ahs_task	equ	30
ahs_mess_size	equ	32
ahs_message	equ	34
ahs_graphic	equ	40
ahs_status	equ	46

add_hot_spot:	enter	0,0
	push	es
	push	ds
	push	ebx
	push	ecx
	push	edx
		
	mov	ax, sys_segment
	mov	ds, ax		; load the system segment

ahs_wait:	bts	ds:[sys.semaphores], ss_hots	; is the hot spot table free
	jc	ahs_wait

	mov	es, ds:[sys.hot_spot]	; load the hot spot table
	movzx	ecx, ds:[sys.hot_size]	; get the table size
	xor	ebx, ebx

;-----------------------
; find empty entry

ahs_look:	add	ebx, hs_size		; next entry
	cmp	es:hs_owner[ebx], word ptr 00	; is the entry empty - no owner = empty
	je	ahs_found
	loop	ahs_look

;-----------------------
; set error code
	
	mov	eax, ahs_tbl_full	; error hot spot table full

	bt	ds:[sys.semaphores],ss_system	; check to see if system caused error
	jc	ahs_exit
	
	call	set_task_error		; this will set the task error bits

	jmp	ahs_exit

;-----------------------
; add hot spot to table

ahs_found:	mov	ax, ss:ahs_owner[ebp]	; owner
	mov	es:hs_owner[ebx], ax
	
	mov	ax, ss:ahs_top_x[ebp]	
	mov	es:hs_top_x[ebx], ax
	
	mov	ax, ss:ahs_top_y[ebp]
	mov	es:hs_top_y[ebx], ax
	
	mov	ax, ss:ahs_bot_x[ebp]
	mov	es:hs_bot_x[ebx], ax
	
	mov	ax, ss:ahs_bot_y[ebp]
	mov	es:hs_bot_y[ebx], ax
	
	mov	ax, ss:ahs_max_x[ebp]
	mov	es:hs_max_x[ebx], ax
	
	mov	ax, ss:ahs_max_y[ebp]
	mov	es:hs_max_y[ebx], ax
	
	mov	ax, ss:ahs_rel_x[ebp]
	mov	es:hs_rel_x[ebx], ax

	mov	ax, ss:ahs_rel_y[ebp]
	mov	es:hs_rel_y[ebx], ax

	mov	ax, ss:ahs_mess_size[ebp]
	mov	es:hs_mess_len[ebx], ax

	mov	ax, ss:ahs_task[ebp]
	mov	es:hs_task[ebx], ax

	mov	eax, ss:ahs_message[ebp]
	mov	es:hs_message[ebx], eax
	
	mov	ax, ss:ahs_message+4[ebp]
	mov	word ptr es:hs_mess_seg[ebx], ax

	mov	eax, ss:ahs_graphic[ebp]
	mov	es:hs_graphic[ebx], eax
	
	mov	ax, ss:ahs_graphic+4[ebp]
	mov	word ptr es:hs_graphic+4[ebx], ax
	
	mov	ax, ss:ahs_status[ebp]
	mov	es:hs_status[ebx], ax
	
;----------------------
; make new screen top

	mov	ax, ds:[sys.top_hs_entry]
	mov	es:hs_chain[ebx], ax	; this screen points to old top
	
	xor	edx, edx
	mov	eax, ebx
	mov	ecx, hs_size
	div	ecx		
	mov	ds:[sys.top_hs_entry], ax	; make this top in the system
		
;----------------------
; exit

ahs_exit:	btr	ds:[sys.semaphores], ss_hots	; free the hs table

	pop	edx
	pop	ecx
	pop	ebx
	pop	ds
	pop	es
	leave
	retf	36		; far return