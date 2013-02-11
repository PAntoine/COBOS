comment	#===========================================================

		      Create Realm
		     (API Function)
		      
	        Concurrent Object Based Operating System
		        (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     

	 This function will create a Realm. It will also create the
	 onode for the realms own table. The Realm table will be
	 amended to add the realms record.
	 
	  Parameters:  	(fword) Realm_name
	  	(fword) Group_name
		(word)  Device to set the realm on
		(word)  Permissions to be set (only low byte)

	  returns:  	(eax) error-code
	  	
	#===========================================================

crm_MDSIO_full	equ	error_code<system_err,warning,system_error<,md_table,e_full,0,0>>

crm_realm_name	equ	12		; 32 bit far pointer to the name of the realm
crm_group_name	equ	18		; 32 bit far pointer to the group name
crm_device	equ	24		; the device to set the realm on
crm_permission	equ	26		; the permissions byte
	 
crm_buff_no	equ	-2		; the allocation number of the buffer
crm_disk_alloc	equ	-6
crm_read_buffer	equ	-18
crm_device_n	equ	-20
crm_block	equ	-24
crm_MDSIO_ent	equ	-28
	
create_realm:	enter	28,0
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
	
crm_MDSIO_wait:	bts	gs:[sys.semaphores], ss_MDSIO		; wait for the MDSIO table
	jnc	crm_sem_got
	int	20h
	jmp	crm_MDSIO_wait
	
;--------------------------
; does the realm exist?
	
crm_sem_got:	push	word ptr 00h			; no specific part (realms dont have)
	push	word ptr 02h			; I want write access
	push	word ptr ss:crm_realm_name[ebp+4]	; realm name segment
	push	dword ptr ss:crm_realm_name[ebp]	; realm name offset
	push	word ptr 0000h			; object name - 0000:00000000 = NULL
	push	dword ptr 00000000h
	call	check_permissions
	
	cmp	eax, cp_rts_not_fnd	; error code if realm does not exist (from chk_perm)
	je	crm_here1		; if it exists - then cant create
	
	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	jmp	crm_failed
	
;--------------------------
; find space in the MDSIO

crm_here1:	mov	es, gs:[sys.MDSIO_table]	; get the MDSIO table
	movzx	ecx, gs:[sys.MDSIO_size]	; get the size
	xor	edx, edx
	dec	ecx
	
crm_find_space:	cmp	es:md_owner[edx], 00h	; if owner = 0000 then space empty
	je	crm_fnd_spce
	add	edx, md_size		; next entry
	loop	crm_find_space
	
	mov	eax, crm_MDSIO_full	; the MDSIO table is full
	btr	gs:[sys.semaphores], ss_MDSIO
	jmp	crm_failed		; go away
	
;---------------------------
; create an access record

crm_fnd_spce:	mov	ss:crm_MDSIO_ent[ebp], edx	; save the MDSIO entry

	lds	esi, ss:crm_realm_name[ebp]	; get the source of the realm name
	lea	edi, md_realm[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	cmp	ss:crm_group_name[ebp+4], word ptr 0000	; load the group part
	je	crm_fnd_ng			; if seg = 0000 then name = NULL - dont copy

	lds	esi, ss:crm_group_name[ebp]	; get the source of the group name
	lea	edi, md_group[edx]	; destination inside the realm table
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name
	
crm_fnd_ng:	lea	edi, md_name[edx]	; the names position
	xor	eax, eax		; make it all zeros
	mov	ecx, 32 /4
	rep stosd			; move all zeros to md_name
	
	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task
	
	mov	es:md_MDSIO_pos.op_block[edx], dword ptr 00	; being created so no position
	mov	es:md_MDSIO_pos.op_device[edx+4], word ptr 00
	
	mov	es:md_access_lock[edx], al_create	; lock the realm
	mov	es:md_type[edx], 00h	; the whole object
	
;------------------------------
; allocate space for the realm

	btr	gs:[sys.semaphores], ss_MDSIO	; release the MDSIO table	

	push	word ptr ss:crm_device[ebp]	; device number the set the realm on
	call	allocate_block
	mov	ss:crm_disk_alloc[ebp], eax	; store the allocated block
	
	cmp	ebx, 00		; ebx holds the error code
	je	crm_have_spc
	
	mov	eax, ebx
	jmp	crm_failed
	
;----------------------------
; fill and write - realm

crm_have_spc:	push	gs:[sys.current_task] 	; owner - current task
	push	word ptr 0092h		; 32bit data
	push	dword ptr 200h		; 512 bytes - 1 block
	call	allocate_memory

	cmp	ebx, 00		; is there and error code
	je	crm_ok
	mov	eax, ebx
	jmp	crm_failed
	
crm_ok:	mov	es, ax		; load the selector number
	shr	eax, 16
	mov	ss:crm_buff_no[ebp], ax	; save the alloc number - will be needed later
	mov	ecx, 01ffh		; 512 writes
	
crm_clear:	mov	es:[ecx], byte ptr 00h	; clear just allocated memory
	loop	crm_clear
	
	mov	es:[on_next_block], 0ffffffffh	; no next block - this is the first
	mov	es:[on_prev_block], 0ffffffffh	; first block no previous
	mov	ax, ss:crm_permission[ebp]
	mov	es:[on_permission], al	; set the permissions byte
	
	cmp	ss:crm_group_name[ebp+4], word ptr 0000	; load the group part
	je	crm_cpy_name			; if seg = 0000 then name = NULL - dont copy
	
	mov	edi, offset on_group
	lds	esi, ss:crm_group_name[ebp]	; load the group name
	mov	ecx, 32
	rep movsb			; copy the group name
	
crm_cpy_name:	mov	ds, gs:[sys.current_TCB]	; get the current TCB
	bts	ds:[TCB.status], t_inuse
	jnc	crm_TCB_got
	int	20h
	jmp	crm_cpy_name
		
crm_TCB_got:	mov	edi, offset on_owner	; the owner realm
	mov	esi, offset TCB.owner_realm	; load the group name
	mov	ecx, 32
	rep movsb			; copy the group name
	
	btr	ds:[TCB.status], t_inuse	; release the TCB
	
	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crm_disk_alloc[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:crm_device[ebp]	; device
	fcall	g_cobos, block_request

	cmp	eax, 00
	jne	crm_failed		; disk write failed

crm_here:	lea	ebx, crm_read_buffer[ebp]
	
crm_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crm_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	crm_read

crm_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crm_read

	xor	eax, eax
	mov	es, ax		; unload the segment that is to be deleted

	push	word ptr ss:crm_buff_no[ebp]
	call	free_memory		; finished with buffer

;------------------------
; now amend realm table

crm_realm_wait:	bts	gs:[sys.semaphores], ss_realm	; wait for the realm table
	jnc	crm_sem_got1
	int	20h
	jmp	crm_realm_wait
	
crm_sem_got1:	mov	es, gs:[sys.realm_buffer]	; get the realm buffer

	mov	eax, gs:[sys.realm_block]
	mov	ss:crm_block[ebp], eax	; now the current realm block is the new one
	mov	ax, gs:[sys.realm_device]
	mov	ss:crm_device_n[ebp], ax

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr gs:[sys.realm_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[sys.realm_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:crm_read_buffer[ebp]
	
crm_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crm_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	crm_read2

crm_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crm_read2

;-----------------------------
; find a space in realm table

	xor	edx, edx
	xor	esi, esi

crm_big_loop:	xor	eax, eax
	xor	ebx, ebx
	mov	ecx, (32/4)-1
crm_chk_loop:	cmp	dword ptr es:rt_name[edx+ebx*4], eax	; is the name = all 00 - string NULL
	jne	crm_look_nxt
	inc	ebx
	loop	crm_chk_loop
	jmp	crm_rlm_fnd		; found a space in the realm table

crm_look_nxt:	add	edx, rt_size
	inc	esi
	cmp	esi, 6		; number of realm entries per block
	jb	crm_big_loop

	cmp	es:[rt_next_device], 0ffffh
	jne	crm_rlm_next
	cmp	es:[rt_next_block], 0ffffffffh
	jne	crm_rlm_next

;------------------------	
; extend the realm table
	
	push	gs:[sys.realm_device]
	call	allocate_block		; get an allocation for another realm block

	cmp	ebx, 00
	je	crm_all_ok		; cant allocate a block on the device
	mov	eax, ebx
	jmp	crm_failed


crm_all_ok:	mov	es:[rt_next_block], eax	; set the old pointer
	mov	ax, gs:[sys.realm_device]
	mov	es:[rt_next_device], ax

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crm_block[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:crm_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:crm_read_buffer[ebp]	
	
crm_read4:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crm_is_disk4
	int	20h		; cant read next sector till the device code loads
	jmp	crm_read4

crm_is_disk4:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crm_read4

	mov	eax, es:[rt_next_block]
	mov	ss:crm_block[ebp], eax	; now the current realm block is the new one
	mov	ax, es:[rt_next_device]
	mov	ss:crm_device_n[ebp], ax

	mov	ecx, 01ffh		; clear it
	xor	eax, eax
crm_ext_clr:	mov	es:[ecx], byte ptr 00h
	loop	crm_ext_clr

	xor	edx, edx		; obviously want to be the first entry	
	jmp	crm_rlm_fnd		; why invent the wheel twice?

;---------------------------
; read the next realm block

crm_rlm_next:	mov	ax, es:[rt_next_device]	; save the next block pointers
	mov	ss:crm_device_n[ebp], ax
	mov	eax, es:[rt_next_block]
	mov	ss:crm_block[ebp], eax

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[rt_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr es:[rt_next_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, crm_read_buffer[ebp]	
	
crm_read3:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crm_is_disk3
	int	20h		; cant read next sector till the device code loads
	jmp	crm_read3

crm_is_disk3:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crm_read3

	xor	edx, edx		; search next block
	xor	esi, esi
	jmp	crm_big_loop	

;-------------------------
; add to the realm table

crm_rlm_fnd:	lds	esi, ss:crm_realm_name[ebp]	; get the source of the group name
	lea	edi, rt_name[edx]	; destination inside the realm table
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	cmp	ss:crm_group_name[ebp+4], word ptr 0000	; load the group part
	je	crm_rlm_ng			; if seg = 0000 then name = NULL - dont copy

	lds	esi, ss:crm_group_name[ebp]	; get the source of the group name
	lea	edi, rt_group[edx]	; destination inside the realm table
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name
	jmp	crm_set_rest
	
crm_rlm_ng:	lea	edi, rt_group[edx]	; the names position - clear it
	xor	eax, eax		; make it all zeros
	mov	ecx, 32 /4
	rep stosd			; move all zeros to rt_group

crm_set_rest:	mov	ax, ss:crm_device[ebp]
	mov	es:rt_device[edx], ax	; set the device number
	
	mov	eax, ss:crm_disk_alloc[ebp]
	mov	es:rt_block[edx], eax	; set the block number
	
	mov	ax, ss:crm_permission[ebp]
	mov	es:rt_permission[edx], al	; set the permissions byte
	
;------------------------
; write amended realm

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crm_block[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:crm_device_n[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:crm_read_buffer[ebp]	
	
crm_read5:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crm_is_disk5
	int	20h		; cant read next sector till the device code loads
	jmp	crm_read5

crm_is_disk5:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crm_read5
	
	btr	gs:[sys.semaphores], ss_realm	; release the realm table	

;------------------------
; remove MDSIO record

crm_MDSIO_wait2:
	bts	gs:[sys.semaphores], ss_MDSIO	; wait for the MDSIO table
	jnc	crm_sem_got2
	int	20h
	jmp	crm_MDSIO_wait2
	
crm_sem_got2:	mov	es, gs:[sys.MDSIO_table]
	mov	edx, ss:crm_MDSIO_ent[ebp]	; load the table entry number
	
	mov	es:md_owner[edx], 00h	; clear the owner - free the record
	
	btr	gs:[sys.semaphores], ss_MDSIO	; release the MDSIO table

;------------------------
; exit

crm_exit:	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	gs
	pop	fs
	pop	es
	pop	ds
	leave
	retf	16
	
crm_failed:	call	set_task_error		; this will set the task error bits
	jmp	crm_exit	