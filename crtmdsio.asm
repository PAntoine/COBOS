comment	#==========================================================

		 create MDSIO object
		   (API Function)

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	 This function will create in the specified realm the
	 named object. Also it will create for which ever type
	 of file the relevent parts that the MDSIO object needs.
	 It will create the onodes for the parts that is creates.	 
      
	Parameters:
		(fword) MDSIO name - 32byte buffer
		(fword) MDSIO realm name - 32byte buffer
		(word)  requested permissions (only a byte used)
		(word)  requested type (only a byte used)
	Returns:
		(eax)   the result of the call	

	#==========================================================

crmo_MDSIO_full	equ	error_code<system_err,warning,system_error<,md_table,e_full,0,0>>

crmo_name	equ	12		; name
crmo_realm	equ	18		; the realm its in
crmo_permission	equ	24		; the permission to set
crmo_type	equ	26		; what part of the object

crmo_MDSIO_ent	equ	-4		; space for the MDSIO entry number
crmo_MDSIO_ent2	equ	-8		; holds the realm entry number
crmo_device	equ	-12
crmo_block	equ	-16
crmo_buffer	equ	-28
crmo_last	equ	-32
crmo_data	equ	-36
crmo_code	equ	-40
crmo_inst	equ	-44
crmo_o_block	equ	-48

create_MDSIO_object:
	enter	48,0
	push	ds
	push	es
	push	gs
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	xor	eax, eax
	mov	ss:crmo_MDSIO_ent[ebp], eax	; clear the holders
	mov	ss:crmo_MDSIO_ent2[ebp], eax
		
	mov	eax, sys_segment
	mov	gs, ax

crmo_wait:	bts	gs:[sys.semaphores], ss_MDSIO	; wait for the MDSIO table
	jnc	crmo_got
	int	20h
	jmp	crmo_wait

crmo_got:	push	word ptr 00h		; 00 - no specific part or the whole thing
	push	word ptr 02h		; I want write access
	push	word ptr ss:crmo_realm[ebp+4]	; realm name segment
	push	dword ptr ss:crmo_realm[ebp]	; realm name offset
	push	word ptr ss:crmo_name[ebp+4]	; object name 
	push	dword ptr ss:crmo_name[ebp]
	call	check_permissions

	cmp	eax, cp_obj_n_exist	; the object must not exist
	je	crmo_f_spc
	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	jmp	crmo_failed

;----------------------------
; add MDSIO record

crmo_f_spc:	mov	es, gs:[sys.MDSIO_table]
	movzx	ecx, gs:[sys.MDSIO_size]
	xor	ebx, ebx
	dec	ecx

crmo_find_space:
	cmp	es:md_owner[edx], 00h	; if owner = 0000 then space empty
	je	crmo_fnd_spce
	inc	ebx
	add	edx, md_size		; next entry
	loop	crmo_find_space

	mov	eax, crmo_MDSIO_full	; the MDSIO table is full
	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	jmp	crmo_failed		; go away
	
;---------------------------
; create an access record

crmo_fnd_spce:	mov	ss:crmo_MDSIO_ent[ebp], ebx	; save the MDSIO entry

	lds	esi, ss:crmo_realm[ebp]	; get the source of the realm name
	lea	edi, md_realm[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	lds	esi, ss:crmo_name[ebp]	; get the source of the realm name
	lea	edi, md_name[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task
	
	mov	es:md_MDSIO_pos.op_block[edx], dword ptr 00	; being created so no position
	mov	es:md_MDSIO_pos.op_device[edx+4], word ptr 00
	
	mov	es:md_access_lock[edx], al_create	; lock the realm
	mov	es:md_type[edx], 00h	; the whole thing

;----------------------------------
; need to open the realm for write

	push	word ptr 00h		; 00 - no specific part or the whole thing
	push	word ptr 02h			; I want write access
	push	word ptr ss:crmo_realm[ebp+4]	; realm name segment
	push	dword ptr ss:crmo_realm[ebp]	; realm name offset
	push	word ptr 0000h		; object = 0000:00000000 = NULL 
	push	dword ptr 00000000h
	call	check_permissions
	
	mov	ss:crmo_device[ebp], ecx
	mov	ss:crmo_block[ebp], edx

	cmp	eax, 00		; must be no error - must be available
	je	crmo_f_spc2
	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	jmp	crmo_failed

crmo_f_spc2:	mov	es, gs:[sys.MDSIO_table]
	movzx	ecx, gs:[sys.MDSIO_size]
	dec	ecx

;---------------------------
; need another MDSIO record

	xor	ebx, ebx
	xor	edx, edx

crmo_find_space2:
	cmp	es:md_owner[edx], 00h	; if owner = 0000 then space empty
	je	crmo_fnd_spce2
	inc	ebx
	add	edx, md_size		; next entry
	loop	crmo_find_space2

	mov	eax, crmo_MDSIO_full	; the MDSIO table is full
	btr	gs:[sys.semaphores], ss_MDSIO	; free the MDSIO table
	jmp	crmo_failed		; go away
	
;---------------------------
; create an access record

crmo_fnd_spce2:	mov	ss:crmo_MDSIO_ent2[ebp], ebx	; save the MDSIO entry

	lds	esi, ss:crmo_realm[ebp]	; get the source of the realm name
	lea	edi, md_realm[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	lds	esi, ss:crmo_name[ebp]	; get the source of the realm name
	lea	edi, md_name[edx]	; destination inside the realm
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	mov	ax, gs:[sys.current_task]
	mov	es:md_owner[edx], ax	; owner is the current task
	
	mov	es:md_MDSIO_pos.op_block[edx], dword ptr 00	; being created so no position
	mov	es:md_MDSIO_pos.op_device[edx+4], word ptr 00
	
	mov	es:md_access_lock[edx], al_create	; lock the realm
	mov	es:md_type[edx], 00h	; the whole thing

	btr	gs:[sys.semaphores], ss_MDSIO	; release the MDSIO table

;----------------------------------
; allocate memory for realm buffer

	push	gs:[sys.current_task] 	; owner - current task
	push	word ptr 0092h		; 32bit data
	push	dword ptr 400h		; 1024 bytes - 2 blocks
	call	allocate_memory

	cmp	ebx, 00		; is there and error code
	je	crmo_ok
	mov	eax, ebx
	jmp	crmo_failed
	
crmo_ok:	mov	es:md_buffer[edx], ax	; save the selector number
	shr	eax, 16
	mov	es:md_alloc_num[edx], ax	; save the alloc number - will be needed later
	mov	es, es:md_buffer[edx]	; load the segment

;------------------------------
; read the first onode block

	mov	eax, ss:crmo_block[ebp]	; save the first block of the onode
	mov	ss:crmo_o_block[ebp], eax

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crmo_block[ebp]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:crmo_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:crmo_buffer[ebp]	
	
crmo_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crmo_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	crmo_read

crmo_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crmo_read

;----------------------------
; search the ONODE for space

	mov	ebx, on_head_size
	mov	eax, ebx
	shr	eax, 2		; div by 4 - get the number of slots that the header uses
	mov	ss:crmo_last[ebp], eax	; save the start pointer

crmo_SR:	mov	eax, ss:crmo_last[ebp]
crmo_SR_alloc:	cmp	es:8[eax*4],word ptr 00h	; is there a block to be read
	jne	crmo_SR_get_it		; YES!!!
crmo_next:	inc	eax
	cmp	eax, on_last_entry	; has it read all enties in the onode
	ja	crmo_SR_next		; yes!
	mov	ss:crmo_last[ebp], eax	; try the next
	jmp	crmo_SR_alloc

crmo_SR_get_it:	mov	ecx, es:8[eax*4]
	mov	ss:crmo_block[ebp], ecx	; save the block - will need later

	push	es		; message buffer
	push	dword ptr 0200h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:8[eax*4]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:crmo_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	esi, ss:crmo_buffer[ebp]	
	
crmo_read1:	push	ss		; segment
	push	esi		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crmo_is_disk1
	int	20h		; cant read next sector till the device code loads
	jmp	crmo_read1

crmo_is_disk1:	cmp	ss:[esi], byte ptr 03h	; is it a block device message
	jne	crmo_read1

;----------------------------
; search the realm
; re_name is the first entry in the "realm_entry" - the following is a cluge
; to get around the MASM obsession with some structure types

	xor	edx, edx
	xor	ecx, ecx

crmo_onode:	cmp	es:[edx+200h], dword ptr 00h	; is the 32bit name empty
	jne	crmo_o_next
	cmp	es:4[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:8[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:12[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:16[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:20[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:24[edx+200h], dword ptr 00h
	jne	crmo_o_next
	cmp	es:28[edx+200h], dword ptr 00h
	je	crmo_o_found		; YES!!! - fill it
	
crmo_o_next:	add	edx, re_size		; next entry
	inc	ecx
	cmp	ecx, 6
	jb	crmo_onode		; search next
	
	mov	eax, ss:crmo_last[ebp]	; now search next onode block
	jmp	crmo_next

;----------------------------
; read the next onode block

crmo_SR_next:	cmp	es:[on_next_block], 0ffffffffh
	je	crmo_extend

crmo_SR_read:	mov	eax, es:[on_next_block]
	mov	ss:crmo_o_block[ebp], eax	; store to onodes block

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[on_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:crmo_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:crmo_buffer[ebp]	
	
crmo_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crmo_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	crmo_read2

crmo_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crmo_read2

	xor	eax, eax
	mov	ss:crmo_last[ebp], eax
	jmp	crmo_SR		; now search this realm

;--------------------------
; Extend the realms onode

crmo_extend:	mov	edx, ebx
	shr	edx, 2

crmo_loop:	cmp	es:8[edx*4],word ptr 00h	; is there a space
	je	crmo_fill_it
	inc	edx
	cmp	edx, on_last_entry
	jbe	crmo_loop	


	int	00h
	
;------------------------------------
; onode is full	- need another block

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the new onode

	cmp	ebx, 00
	je	crmo_x_wrt
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
	
crmo_x_wrt:	mov	es:[on_next_block], eax	; store the block in the old onodes block
	mov	ebx, ss:crmo_o_block[ebp]
	mov	ss:crmo_o_block[ebp], eax	; save the new onode block
	mov	ss:crmo_block[ebp], ebx	; write the old onode back
	call	crmo_write_blk

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the new realm block

	cmp	ebx, 00
	je	crmo_x_clr
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
	
crmo_x_clr:	mov	edx, ss:crmo_block[ebp]
	mov	ss:crmo_block[ebp], eax	; save new realm block
	
	mov	ecx, 100h		; 1024/4 = 256 = 100h
	xor	eax, eax		; write 00's
	xor	edi, edi		; start from the start
	rep stosd			; clear it!
	
	mov	eax, ss:crmo_block[ebp]
	mov	es:[on_next_block], dword ptr 0ffffffffh	; now end of chain
	mov	es:[on_prev_block], edx	; set the prev pointer
	mov	es:[8], eax		; the first realm block
	
	mov	ebx, ss:crmo_o_block[ebp]	; hold this value
	mov	ss:crmo_block[ebp], ebx
	call	crmo_write_blk		; write the new onode block
	
	mov	eax, es:[8]		; get the new crmo_block back 
	mov	ss:crmo_block[ebp], eax	; now its where it should be

	xor	edx, edx		; set the pointer to 00
	jmp	crmo_o_found
	
;---------------------------
; space in onode

crmo_fill_it:	lea	edi, 8[edx*4]		; ebx is damaged - so save it

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the new realm block

	cmp	ebx, 00
	je	crmo_fill_2
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
	
crmo_fill_2:	mov	es:[edi], eax		; fill the space
	mov	eax, ss:crmo_o_block[ebp]
	mov	ss:crmo_block[ebp], eax	; write the amemded onode block
	call	crmo_write_blk

	mov	eax, es:[edi]
	mov	ss:crmo_block[ebp], eax	; current block is the new block	

	mov	ecx, 80h		; 512/4 = 128 = 80h
	xor	eax, eax		; write 00's
	mov	edi, 200h		; start from the start of the block buffer
	rep stosd			; clear it!

	xor	edx, edx
		
;---------------------------
; found a spare realm entry

crmo_o_found:	lds	esi, ss:crmo_name[ebp]	; load the name
	lea	edi, re_name[edx+200h]
	mov	ecx, 32
	rep movsb			; copy the name of the new object

	mov	es:re_date[edx+200h], 00h	; have not done the date bit yet!!
	mov	ax, ss:crmo_type[ebp]	; get the type
	mov	es:re_type[edx+200h], ax	; store the type

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the file

	cmp	ebx, 00
	je	crmo_code1
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
	
crmo_code1:	mov	ss:crmo_data[ebp], eax		; needed later
	mov	es:re_data.op_block[edx+200h],eax	; store the block
	mov	ax, ss:crmo_device[ebp]
	mov	es:re_data.op_device[edx+200h], ax	; set the device pointer
	cmp	ss:crmo_type[ebp], word ptr obj_data
	jbe	crmo_write

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the file

	cmp	ebx, 00
	je	crmo_object
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
	
crmo_object:	mov	ss:crmo_code[ebp], eax		; needed later
	mov	es:re_code.op_block[edx+200h],eax	; store the block
	mov	ax, ss:crmo_device[ebp]
	mov	es:re_code.op_device[edx+200h], ax	; set the device pointer
	cmp	ss:crmo_type[ebp], word ptr obj_appl
	jbe	crmo_write

	push	word ptr ss:crmo_device[ebp]	; push the device number
	call	allocate_block		; get a block for the file

	cmp	ebx, 00
	je	crmo_obj_str
	mov	eax, ebx		; it failed place the error code in the right place
	jmp	crmo_failed
 
crmo_obj_str:	mov	ss:crmo_inst[ebp], eax		; needed later
	mov	es:re_inst.op_block[edx+200h],eax	; store the block
	mov	ax, ss:crmo_device[ebp]
	mov	es:re_inst.op_device[edx+200h], ax	; set the device pointer

;---------------------------
; write amended realm block

crmo_write:	push	es		; message buffer
	push	dword ptr 0200h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crmo_block[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:crmo_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, crmo_buffer[ebp]	
	
crmo_read3:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crmo_is_disk3
	int	20h		; cant read next sector till the device code loads
	jmp	crmo_read3

crmo_is_disk3:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	crmo_read3

;-------------------------------
; fill the onodes for the parts

	mov	eax, 022222222h
	int	00h

	mov	ecx, 080h		; 512/4 = 80h (128 dec)
	xor	eax, eax
	xor	edi, edi
	repe stosd			; store it! (and clear the buffer)

	mov	ds, gs:[sys.current_TCB]	; the the tasks TCB

crmo_TCB:	bts	ds:[TCB.status], t_inuse
	jnc	crmo_TCB_got
	int	20h
	jmp	crmo_TCB

crmo_TCB_got:	mov	es:[on_next_block], 0ffffffffh	; next block pointer
	mov	es:[on_prev_block], 0ffffffffh	; the first block
	mov	al, ss:crmo_permission[ebp]
	mov	es:[on_permission], al	; set the permission byte

	mov	esi, offset TCB.owner_realm	; get the source of the realm name
	mov	edi, offset on_owner	; destination inside the onode
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	mov	esi, offset TCB.current_group	; get the source of the group name
	mov	edi, offset on_group	; destination inside the onode
	mov	ecx ,32		; all names 32 bytes long
	rep movsb			; copy the name

	btr	ds:[TCB.status], t_inuse	; release the TCB


	mov	eax, ss:crmo_data[ebp]
	mov	ebx, ss:crmo_code[ebp]
	mov	ecx, ss:crmo_inst[ebp]
	mov	edx, ss:crmo_block[ebp]
	mov	esi, 077777777h
	int	00h



	mov	eax, ss:crmo_data[ebp]	; allways is a data block
	mov	ss:crmo_block[ebp], eax
	call	crmo_write_blk

	cmp	ss:crmo_type[ebp], word ptr obj_data
	jbe	crmo_exit_ok		; only data to be written

	mov	eax, ss:crmo_code[ebp]	; write the code onode
	mov	ss:crmo_block[ebp], eax
	call	crmo_write_blk

	cmp	ss:crmo_type[ebp],word ptr obj_appl
	jbe	crmo_exit_ok		; no instance part

	mov	eax, ss:crmo_inst[ebp]	; write the instance block
	mov	ss:crmo_block[ebp], eax
	call	crmo_write_blk

;--------------------------
; remove MDSIO records

crmo_exit_ok:	xor	eax,eax		; clear the error code
	mov	eax, 088888888h
	int	00h

crmo_wait2:	bts	gs:[sys.semaphores], ss_MDSIO	; wait for the MDSIO table
	jnc	crmo_got2
	int	20h
	jmp	crmo_wait2

crmo_got2:	mov	edx, ss:crmo_MDSIO_ent[ebp]
	mov	es, gs:[sys.MDSIO_table]
	mov	es:md_owner[edx], 00h	; free the MDSIO record

	mov	edx, ss:crmo_MDSIO_ent2[ebp]
	cmp	edx, 00
	je	crmo_got22

	mov	es:md_owner[edx], 00h	; free the other MDSIO record
	
crmo_got22:	btr	gs:[sys.semaphores], ss_MDSIO	; free the table

;--------------
; exit
	
crmo_exit:	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	gs
	pop	es
	pop	ds
	leave
	retf	16

;-----------------------------
; function failed

crmo_failed:	call	set_task_error
	cmp	ss:crmo_MDSIO_ent[ebp],dword ptr 00	; has any mdsio records been assigned
	jne	crmo_wait2
	jmp	crmo_exit
	
;-----------------------------
; write block

crmo_write_blk:	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr ss:crmo_block[ebp]	; starting block
	push	word ptr blk_write	; command
	push	word ptr ss:crmo_device[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, crmo_buffer[ebp]	
	
crmo_read4:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	crmo_is_disk4
	cmp	eax, rm_indx_emty
	je	crmo_fred2
	int	00h
	
crmo_fred2:	int	20h		; cant read next sector till the device code loads
	jmp	crmo_read4

crmo_is_disk4:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	je	crmo_fred
	mov	edx, ss:[ebx]
	int	00h
crmo_fred:	ret