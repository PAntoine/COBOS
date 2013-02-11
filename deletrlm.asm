comment	#===========================================================

		      Delete Realm
		     (API Function)
		      
	        Concurrent Object Based Operating System
		        (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     

	 This function will delete a Realm. It will also delete the
	 onode for the realms own table. The Realm table will be
	 amended to remove the realms record. It will only remove
	 the realm if the is empty.
	 
	  Parameters:  	(fword) Realm_name

	  returns:  	(eax) error-code
	  	
	#===========================================================

dlr_MDSIO_full	equ	error_code<system_err,warning,system_error<,md_table,e_full,0,0>>
dlr_rts_not_fnd	equ	error_code<app_1,failure,app_error<0,ape_rlm_n_exist>>
dlr_realm_inuse	equ	error_code<app_1,warning,app_error<0,ape_realm_inuse>>
dlr_n_empty	equ	error_code<app_1,warning,app_error<0,ape_rlm_n_empty>>

dlr_realm_name	equ	12		; 32 bit far pointer to the name of the realm
	 
dlr_buff_no	equ	-2		; the allocation number of the buffer
dlr_disk_alloc	equ	-6
dlr_read_buffer	equ	-18
dlr_device_n	equ	-20
dlr_block	equ	-24
dlr_MDSIO_ent	equ	-28
dlr_last_block	equ	-32
	
delete_realm:	enter	32,0
	push	ds
	push	es
	push	fs
	push	gs
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	
	mov	eax, sys_segment
	mov	gs, ax

dlr_MDSIO_wait:	bts	gs:[sys.semaphores], ss_MDSIO		; wait for the MDSIO table
	jnc	dlr_sem_got
	int	20h
	jmp	dlr_MDSIO_wait

;--------------------------
; does the realm exist?
	
dlr_sem_got:	push	word ptr 00h			; no specific part (realms dont have)
	push	word ptr 02h			; I want write access
	push	word ptr ss:dlr_realm_name[ebp+4]	; realm name segment
	push	dword ptr ss:dlr_realm_name[ebp]	; realm name offset
	push	word ptr 0000h			; object name - 0000:00000000 = NULL
	push	dword ptr 00000000h
	call	check_permissions

	mov	ss:dlr_device_n[ebp], cx	; save the current device
	mov	ss:dlr_block[ebp], edx	; save the current block

	cmp	eax, 00		; error code - realm must be available
	jne	dlr_failed		; if it exists - then cant create

	mov	eax, dlr_realm_inuse
	cmp	bl, 00		; is the current access = none
	jne	dlr_failed

;--------------------------
; find space in the MDSIO

	mov	es, gs:[sys.MDSIO_table]	; get the MDSIO table
	movzx	ecx, gs:[sys.MDSIO_size]	; get the size
	xor	edx, edx
	dec	ecx

dlr_find_space:	cmp	es:md_owner[edx], 00h	; if owner = 0000 then space empty
	je	dlr_fnd_spce
	add	edx, md_size		; next entry
	loop	dlr_find_space

	mov	eax, dlr_MDSIO_full	; the MDSIO table is full
	jmp	dlr_failed		; go away
	
;---------------------------
; create an access record

dlr_fnd_spce:	mov	ss:dlr_MDSIO_ent[ebp], edx	; save the MDSIO entry

	lds	esi, ss:dlr_realm_name[ebp]	; get the source of the realm name
	lea	edi, md_realm[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	lea	edi, md_name[edx]	; the names position
	xor	eax, eax		; make it all zeros
	mov	ecx, 32 /4
	rep stosd			; move all zeros to md_name
	
	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task
	
	mov	es:md_MDSIO_pos.op_block[edx], dword ptr 00	; being created so no position
	mov	es:md_MDSIO_pos.op_device[edx+4], word ptr 00
	
	mov	es:md_access_lock[edx], al_delete	; lock the realm
	mov	es:md_type[edx], 00h	; the whole object
	
;------------------------------
; check the realm is empty
;     (read the ONODE)

	btr	gs:[sys.semaphores], ss_MDSIO	; release the MDSIO table	

	push	gs:[sys.current_task] 	; owner - current task
	push	word ptr 0092h		; 32bit data
	push	dword ptr 400h		; 1024 bytes - 2 blocks
	call	allocate_memory

	cmp	ebx, 00		; is there and error code
	je	dlr_ok
	mov	eax, ebx
	jmp	dlr_failed
	
dlr_ok:	mov	es, ax		; load the selector number
	shr	eax, 16
	mov	ss:dlr_buff_no[ebp], ax	; save the alloc number - will be needed later

;------------------------------
; check the realm is empty
;     (read the ONODE)

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:dlr_block[ebp]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:dlr_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read

dlr_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read

	mov	ebx, on_head_size	; the header size
	xor	eax, eax
	mov	ss:dlr_last_block[ebp], eax	; initial the onode count
	
;------------------------------
; search the realms onode

dlr_SR_read:	mov	eax, ss:dlr_last_block[ebp]
dlr_SR_alloc:	cmp	es:8[ebx+eax*4],word ptr 00h	; is there a block to be realm
	jne	dlr_SR_get_it		; YES!!!
	inc	eax
	cmp	eax, 62		; has it read all enties in the onode
	ja	dlr_next_onode		; yes!
	mov	ss:dlr_last_block[ebp], eax	; try the next
	jmp	dlr_SR_alloc

;------------------------------
; read the realms data

dlr_SR_get_it:	push	es		; message buffer
	push	dword ptr 0200h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:8[ebx+eax*4]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:dlr_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read2

dlr_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read2

;-----------------------------
; search the realm block

	xor	eax, eax
	xor	ebx, ebx
	xor	edx, edx
	
dlr_SR_loop:	cmp	es:re_name[eax+200h], dword ptr 00h	; see if the entry is empty
	jne	dlr_not_empty	
	cmp	es:re_name[eax+204h], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+208h], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+20ch], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+210h], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+214h], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+218h], dword ptr 00h
	jne	dlr_not_empty	
	cmp	es:re_name[eax+21ch], dword ptr 00h
	jne	dlr_not_empty	

	add	eax, re_size		; next entry
	inc	ebx
	cmp	ebx, 8		; number of entries in a block
	jb	dlr_SR_loop
	jmp	dlr_SR_read		; go for next realm onode block

;-----------------------------
; read next onode

dlr_next_onode:	cmp	es:[on_next_block], 0ffffffffh	; is it at the end of the chain
	je	dlr_now_empty

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[on_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:dlr_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read3:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk3
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read3

dlr_is_disk3:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read3

	xor	eax, eax
	mov	ss:dlr_last_block[ebp], eax	; initial the onode count
	xor	ebx, ebx
	jmp	dlr_SR_read

;-----------------------------
; realm not empty error

dlr_not_empty:	mov	eax, dlr_n_empty	; error - the realm must be empty
	jmp	dlr_failed

;-----------------------------
; realm empty - now delete it

dlr_now_empty:	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:dlr_block[ebp]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:dlr_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read4:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk4
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read4

dlr_is_disk4:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read4

	push	dword ptr ss:dlr_block[ebp]	; the block number
	push	word ptr ss:dlr_device_n[ebp]	; the device
	call	free_block		; free the disk allocation
	
	cmp	es:[on_next_block], 0ffffffffh
	je	dlr_amd_realm
	
	mov	eax, es:[on_next_block]
	mov	dlr_device_n[ebp], eax	; set the next block to delete
	jmp	dlr_now_empty

;-----------------------------
; now remove the realm record

dlr_amd_realm:	xor	eax, eax
	mov	es, ax		; unload the segment that is to be deleted

	push	word ptr ss:dlr_buff_no[ebp]
	call	free_memory		; finished with buffer

;--------------------------
; read first block

dlr_realm_wait:	bts	gs:[sys.semaphores], ss_realm	; wait for the realm table
	jnc	dlr_sem_got3
	int	20h
	jmp	dlr_realm_wait

dlr_sem_got3:	mov	es, gs:[sys.realm_buffer]	; get the realm buffer

	mov	ax, gs:[sys.realm_device]	; save start block
	mov	ss:dlr_device_n[ebp],ax
	mov	eax, gs:[sys.realm_block]
	mov	ss:dlr_block[ebp], eax
	
	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr gs:[sys.realm_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[sys.realm_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]
	
dlr_read5:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk5
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read5

dlr_is_disk5:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read5

;---------------------------------------
; search the realm table find the realm

	xor	edx, edx
	xor	ebx, ebx
	
dlr_RTS_loop:	lds	esi,fword ptr ss:dlr_realm_name[ebp]	; load the name string
	mov	ecx, 32
	lea	edi, rt_name[edx]	; set the start of the search
	repe cmpsb
	je	dlr_RTS_found

	add	edx, rt_size
	inc	ebx
	cmp	ebx, 6		; number of realm entries per block
	jb	dlr_RTS_loop
	
	cmp	es:[rt_next_device], 0ffffh
	jne	dlr_RTS_next
	cmp	es:[rt_next_block], 0ffffffffh
	jne	dlr_RTS_next
	
	mov	eax, dlr_rts_not_fnd	; object does not exist - failure
	btr	gs:[sys.semaphores], ss_realm	; free the realm table
	jmp	dlr_exit

dlr_RTS_next:	mov	eax, es:[rt_next_block]	; save the pointer to the next block
	mov	ss:dlr_block[ebp], eax
	mov	ax, es:[rt_next_device]
	mov	ss:dlr_device_n[ebp], ax

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[rt_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr es:[rt_next_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read6:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk6
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read6

dlr_is_disk6:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read6

	xor	edx, edx		; search next block
	xor	esi, esi
	xor	ebx, ebx
	jmp	dlr_RTS_loop	
	
;------------------------------
; entry found - remove

dlr_RTS_found:	mov	ebx, offset rt_name	; get around an anoying "feature" of MASM
	mov	es:[ebx+edx], dword ptr 00h	; clear the name field
	mov	es:[ebx+edx+4],dword ptr 00h
	mov	es:[ebx+edx+8],dword ptr 00h
	mov	es:[ebx+edx+12],dword ptr 00h
	mov	es:[ebx+edx+16],dword ptr 00h
	mov	es:[ebx+edx+20],dword ptr 00h
	mov	es:[ebx+edx+24],dword ptr 00h
	mov	es:[ebx+edx+28],dword ptr 00h

;------------------------
; write amended realm

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:dlr_block[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:dlr_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:dlr_read_buffer[ebp]	
	
dlr_read7:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	dlr_is_disk7
	int	20h		; cant read next sector till the device code loads
	jmp	dlr_read7

dlr_is_disk7:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	dlr_read7
	
	btr	gs:[sys.semaphores], ss_realm	; release the realm table	

;------------------------
; remove MDSIO record

dlr_MDSIO_wait2:
	bts	gs:[sys.semaphores], ss_MDSIO	; wait for the MDSIO table
	jnc	dlr_sem_got2
	int	20h
	jmp	dlr_MDSIO_wait2
	
dlr_sem_got2:	mov	es, gs:[sys.MDSIO_table]
	mov	edx, ss:dlr_MDSIO_ent[ebp]	; load the table entry number
	
	mov	es:md_owner[edx], 00h	; clear the owner - free the record
	
	btr	gs:[sys.semaphores], ss_MDSIO	; release the MDSIO table

;------------------------
; exit

dlr_exit:	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	gs
	pop	fs
	pop	es
	pop	ds
	leave
	retf	6
	
dlr_failed:	call	set_task_error		; this will set the task error bits
	jmp	dlr_exit	