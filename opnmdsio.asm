comment	#==========================================================

		  Open MDSIO object
		   (API Function)

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	 This function will open the requested MDSIO object and
	 return the MDSIO number of the object. It will also 
	 create the ONODE buffer to the MDSIO table record for
	 the object.
	       
	Parameters:
		(fword) MDSIO name - 32byte buffer
		(fword) MDSIO realm name - 32byte buffer
		(word)  requested access (only a byte used)
		(word)  requested part (only a byte used)
	Returns:
		(eax)   the MDSIO entry number (ax only)
		(ebx)   the result of the call	

	#==========================================================

omo_perm_fail	equ	error_code<app_1,failure,app_error<0,ape_obj_perm>>
omo_obj_exist	equ	error_code<app_1,failure,app_error<0,ape_obj_exist>>
omo_MDSIO_full	equ	error_code<system_err,warning,system_error<,md_table,e_full,0,0>>

omo_MDSIO_name	equ	12		; name - if null only a realm being accessed
omo_MDSIO_realm	equ	18		
omo_access	equ	24
omo_part	equ	26		; what part of the object

omo_device_n	equ	-2		; the device that the onode is on
omo_block	equ	-6		; the block
omo_MDSIO_ent	equ	-10		; the MDSIO entry
omo_message	equ	-22

open_MDSIO_object:
	enter	22,0
	push	ecx
	push	edx
	push	ds
	push	es
	push	gs

	mov	eax, sys_segment
	mov	gs, ax

omo_wait:	bts	gs:[sys.semaphores], ss_MDSIO	; wait for the MDSIO table
	jnc	omo_got
	int	20h
	jmp	omo_wait

omo_got:	push	word ptr ss:omo_part[ebp]		; no specific part (realms dont have)
	push	word ptr ss:omo_access[ebp]		; I want write access
	push	word ptr ss:omo_MDSIO_realm[ebp+4]	; realm name segment
	push	dword ptr ss:omo_MDSIO_realm[ebp]	; realm name offset
	push	word ptr ss:omo_MDSIO_name[ebp+4]	; object name - 0000:00000000 = NULL
	push	dword ptr ss:omo_MDSIO_name[ebp]
	call	check_permissions

	mov	ss:omo_device_n[ebp], cx	; save the current device
	mov	ss:omo_block[ebp], edx	; save the current block

	cmp	eax, 00		; error code - object must be available
	je	omo_w_h		; if it exists - then cant create
	mov	eax, omo_obj_exist	; the object exists error
	jmp	omo_failed

;----------------------------------
; check current access permissions

omo_w_h:	mov	eax, omo_perm_fail
	cmp	ss:omo_access[ebp], byte ptr al_read
	ja	omo_want_write
	cmp	bl, al_read
	ja	omo_failed		; if allready opened for read then can join
	jmp	omo_insert

omo_want_write:	mov	eax, omo_perm_fail
	cmp	bl, 00		; is the current access
	ja	omo_failed

;---------------------------
; Insert MDSIO record

omo_insert:	mov	es, gs:[sys.MDSIO_table]	; get the MDSIO table
	movzx	ecx, gs:[sys.MDSIO_size]	; get the size
	xor	ebx, ebx
	xor	edx, edx
	dec	ecx

omo_find_space:	cmp	es:md_owner[edx], 00h	; if owner = 0000 then space empty
	je	omo_fnd_spce
	inc	ebx
	add	edx, md_size		; next entry
	loop	omo_find_space

	mov	eax, omo_MDSIO_full	; the MDSIO table is full
	jmp	omo_failed		; go away
	
;---------------------------
; create an access record

omo_fnd_spce:	mov	ss:omo_MDSIO_ent[ebp], ebx	; save the MDSIO entry

	lds	esi, ss:omo_MDSIO_realm[ebp]	; get the source of the realm name
	lea	edi, md_realm[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	lds	esi, ss:omo_MDSIO_name[ebp]	; get the source of the realm name
	lea	edi, md_name[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task
	
	mov	eax, ss:omo_block[ebp]	; save the current block
	mov	es:md_MDSIO_pos.op_block[edx],eax	; being created so no position

	mov	ax, ss:omo_device_n[ebp]	; save the current device
	mov	es:md_MDSIO_pos.op_device[edx+4],ax
	
	mov	al, ss:omo_access[ebp]
	mov	es:md_access_lock[edx], al	; lock the realm
	mov	al, ss:omo_part[ebp]
	mov	es:md_type[edx], al	; the object part that was requested

;--------------------------
; allocate ONODE buffer

	push	gs:[sys.current_task] 	; owner - current task
	push	word ptr 0092h		; 32bit data
	push	dword ptr mdh_size	; this is for the handler
	call	allocate_memory

	cmp	ebx, 00		; is there and error code
	je	omo_ok
	mov	eax, ebx
	jmp	omo_failed
	
omo_ok:	mov	es:md_buffer[edx], ax	; save the selector number
	shr	eax, 16
	mov	es:md_alloc_num[edx], ax	; save the alloc number - will be needed later

	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task

;---------------------------
; set up the buffer
	
	mov	ds, es:md_buffer[edx]	; the buffer
	mov	ds:[mdh_owner], ax	; set the owner field
	mov	ax, ss:omo_MDSIO_ent[ebp]
	mov	ds:[mdh_MDSIO_num], ax	; save the MDSIO number
	mov	ax, ss:omo_device_n[ebp]
	mov	ds:[mdh_device], ax	; save the device number
	mov	al, ss:omo_access[ebp]
	mov	ds:[mdh_access], al	; set the access byte
	mov	ds:[mdh_onode], 00h
	mov	eax, ss:omo_block[ebp]
	mov	ds:[mdh_o_block], eax	; set the current onode block to the first
	mov	ds:[mdh_block], on_head_size/4	; the first entry in the first block
	
;----------------------------
; read the first onode block

	push	ds		; message buffer
	push	dword ptr offset mdh_buffer	; message offset
	push	word ptr 1		; transfer size
	push	ds:[mdh_o_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ds:[mdh_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, omo_message[ebp]
	
omo_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	omo_reada
	int	20h		; cant read next sector till the device code loads
	jmp	omo_read

omo_reada:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	omo_read
	
;---------------------------
; set up for OK exit

	movzx	eax, es:md_buffer[edx]	; return the buffer 
	xor	ebx, ebx		; entry exit

;---------------------------
; Exit

omo_exit:	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	pop	gs
	pop	es
	pop	ds
	pop	edx
	pop	ecx
	leave
	retf	16

omo_failed:	call	set_task_error		; set the calling tasks error flags
	mov	ebx, eax		; put error code in right place
	jmp	omo_exit		