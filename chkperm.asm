comment	#==========================================================

		  Check Permissions

	        Concurrent Object Based Operating System
		       (COBOS)
				 
	          BEng (Hons) Software Engineering for
		   Real Time Systems
		3rd Year Project 1996/97
			  
		  (c) 1997 P.Antoine
			     
	 This function will check the MDSIO permissions and will 
	 return the location of the object. It will also return the
	 location of the object, and if the object has allready
	 been opened the access lock that is on the object.

	 Note: This function does not obey the semaphore on the
	       MDSIO table - so any function that calls this function
	       MUST already hold the MDSIO_table.
	       
	Pareameters:
		(fword) MDSIO name - 32byte buffer
		(fword) MDSIO realm name - 32byte buffer
		(word)  requested access (only a byte used)
		(word)  requested part (only a byte used)
	Returns:
		(eax)   Result
		(ebx)   current access locks (only bl)
		(ecx)   device number (cx)
		(edx)   starting block
	
	#==========================================================

cp_realm_inuse	equ	error_code<app_1,warning,app_error<0,ape_realm_inuse>>
cp_rts_not_fnd	equ	error_code<app_1,failure,app_error<0,ape_rlm_n_exist>>
cp_perm_fail	equ	error_code<app_1,failure,app_error<0,ape_obj_perm>>
cp_obj_n_exist	equ	error_code<app_1,failure,app_error<0,ape_obj_n_exist>>
cp_prt_n_exist	equ	error_code<app_1,failure,app_error<0,ape_obj_n_prt>>
	
cp_MDSIO_name	equ	8		; name - if null only a realm being accessed
cp_MDSIO_realm	equ	14		
cp_access	equ	20
cp_part	equ	22		; what part of the object

cp_var_access	equ	-4
cp_read_buffer	equ	-18
cp_realm_only	equ	-20
cp_device_no	equ	-22
cp_last_block	equ	-26
cp_TCB_seg	equ	-28

check_permissions:
	enter	28, 0
	push	ds
	push	es
	push	fs
	push	gs
	push	edi
	push	esi
	
	mov	eax, sys_segment
	mov	gs, ax
	
	mov	es, gs:[sys.MDSIO_table]	; load the MDSIO table
	movzx	eax, gs:[sys.MDSIO_size]	; load the size of the MDSIO table
	dec	eax

;-----------------------
; search MDSIO table

	xor	ebx, ebx
	xor	edx, edx
	cld
	mov	ss:cp_realm_only[ebp], word ptr 00	; is only the realm being looked at

	cmp	ss:cp_MDSIO_name[ebp+4], word ptr 00h
	je	cp_SMT_loop		; if selector is 0000 then only looking for the realm

	mov	ss:cp_realm_only[ebp],byte ptr 01h	; it is looking for a object as well
	
cp_SMT_loop:	cmp	es:md_owner[edx], 00h	; is the slot in use?
	je	cp_SMT_next		; no!

	lds	esi,fword ptr ss:cp_MDSIO_realm[ebp]	; load the name string
	mov	ecx, 32
	lea	edi, md_realm[edx]	; set the start of the search
	rep cmpsb
	je	cp_realm_found
	
cp_SMT_next:	inc	ebx
	add	edx, md_size		; next MDSIO_table entry
	cmp	bx, gs:[sys.MDSIO_size]	; has the whole table been searched?
	jne	cp_SMT_loop		; NO!
	
	mov	ss:cp_var_access[ebp], word ptr 00h	; the realm/object not found so no curent access
	jmp	cp_srch_realmt	

cp_realm_found:	cmp	es:md_name[edx], dword ptr 00h	; if no name then the realm itself is in use
	jne	cp_chk_name
	
	cmp	es:md_name[edx+4], dword ptr 00h
	jne	cp_chk_name

	cmp	es:md_name[edx+8], dword ptr 00h
	jne	cp_chk_name

	cmp	es:md_name[edx+12], dword ptr 00h
	jne	cp_chk_name

	cmp	es:md_name[edx+16], dword ptr 00h
	jne	cp_chk_name
	
	cmp	es:md_name[edx+20], dword ptr 00h
	jne	cp_chk_name

	cmp	es:md_name[edx+24], dword ptr 00h
	jne	cp_chk_name

	cmp	es:md_name[edx+28], dword ptr 00h
	jne	cp_chk_name
	
	cmp	ss:cp_MDSIO_name[ebp+4], word ptr 00h
	je	cp_SMT_found		; if selector is 0000 then only looking for the realm

	mov	ss:cp_realm_only[ebp],byte ptr 01h	; it is looking for a object as well

	cmp	es:md_access_lock[edx], al_read	; is the realm opened for write
	jle	cp_SMT_loop		; NO! - so dont care

	mov	eax, cp_realm_inuse	; realm is opened for update - error and exit
	xor	ebx, ebx		; failure - zero out other returns
	xor	ecx, ecx
	xor	edx, edx
	jmp	cp_exit		; exit this popsicle stand
	
cp_chk_name:	cmp	ss:cp_MDSIO_name[ebp+4], word ptr 00h
	je	cp_SMT_next		; if selector is 0000 then only looking for the realm

	lds	esi,fword ptr ss:cp_MDSIO_name[ebp]	; load the name string
	mov	ecx, 32
	lea	edi, md_name[edx]	; set the start of the search
	rep cmpsb
	jne	cp_SMT_next		; (not found) do the next entry in the table

cp_SMT_found:	mov	al, es:md_access_lock[edx]
	mov	ss:cp_var_access[ebp], al	; save the opened access

;-----------------------
; search Realm table

cp_srch_realmt:	bts	gs:[sys.semaphores], ss_realm	; hold the realm table
	jnc	cp_sem_got		; no carry - sem was free
	int	20h		; swap out
	mov	eax, 066666666h
	int	00h
	jmp	cp_srch_realmt

; load first realm block

cp_sem_got:	mov	es, gs:[sys.realm_buffer]	; get the realm buffer
	
	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr gs:[sys.realm_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr gs:[sys.realm_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, cp_read_buffer[ebp]
	
cp_read:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read

cp_is_disk:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read

;---------------------------------------
; search the realm table find the realm

	xor	edx, edx
	xor	ebx, ebx
	
cp_RTS_loop:	lds	esi,fword ptr ss:cp_MDSIO_realm[ebp]	; load the name string
	mov	ecx, 32
	lea	edi, rt_name[edx]	; set the start of the search
	rep cmpsb
	je	cp_RTS_found

	add	edx, rt_size
	inc	ebx
	cmp	ebx, 6		; number of realm entries per block
	jb	cp_RTS_loop
	
	cmp	es:[rt_next_device], 0ffffh
	jne	cp_RTS_next
	cmp	es:[rt_next_block], 0ffffffffh
	jne	cp_RTS_next
	
	mov	eax, cp_rts_not_fnd	; object does not exist - failure
	btr	gs:[sys.semaphores], ss_realm	; free the realm table
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	jmp	cp_exit

cp_RTS_next:	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[rt_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr es:[rt_next_device]	; device
	fcall	g_cobos, block_request

	lea	ebx, cp_read_buffer[ebp]	
	
cp_read1:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk1
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read1

cp_is_disk1:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read1

	xor	edx, edx		; search next block
	xor	esi, esi
	jmp	cp_RTS_loop	

;-----------------------------------------------------
; realm found - is the calling task allowed to use it

cp_RTS_found:	cmp	ss:cp_realm_only[ebp], byte ptr 00	; does it want to open an object
	jne	cp_srch_realm		; yes!

	mov	ds, gs:[sys.current_TCB]	; get the task TCB segment
	
cp_wait_TCB:	bts	ds:[TCB.status], t_inuse	; Hold the tasks TCB
	jnc	cp_realm_perm
	int	20h
	jmp	cp_wait_TCB
	
;---------------------------
; check realm permissions

cp_realm_perm:	movzx	ax, es:rt_permission[edx]
	and	ax, 30h		; only want the "world" permission bits
	shr	ax, 4		; place at the start of the byte
	cmp	ax, ss:cp_access[ebp]
	jae	cp_RTS_perm_ok		; world permissions allow access

	mov	esi, offset TCB.owner_realm	; is the task in the realm?
	lea	edi, rt_name[edx]	; set the start of the search
	mov	ecx, 32
	rep cmpsb
	jne	cp_RTS_grp		; YES!
	
	movzx	ax, es:rt_permission[edx]
	and	ax, 03h		; only want the "realm" permission bits
	cmp	ax, ss:cp_access[ebp]
	jae	cp_RTS_perm_ok		; realm permissions allow access
	
cp_RTS_grp:	mov	esi, offset TCB.current_group	; is the task in the same group?
	lea	edi, rt_group[edx]	; set the start of the search
	rep cmpsb
	jne	cp_failed		; NO - not allowed access to the realm

	movzx	ax, es:rt_permission[edx]
	and	ax, 0ch		; only want the "group" permission bits
	shr	ax, 2
	cmp	ax, ss:cp_access[ebp]
	jb	cp_failed
	
cp_RTS_perm_ok:	xor	ebx, ebx
	mov	bl, ss:cp_var_access[ebp]	; return the current opened access
	movzx	ecx, es:rt_device[edx]	; get the device
	mov	edx, es:rt_block[edx]	; the the start block
	xor	eax, eax		; all OK result code
	mov	ds, gs:[sys.current_TCB]
	btr	ds:[TCB.status], t_inuse	; release the TCB
	btr	gs:[sys.semaphores], ss_realm	; release the realm table
	jmp	cp_exit
	
;-----------------------
; read realm onode

cp_srch_realm:	mov	ax, es:rt_device[edx]	; the device that the objectr is on
	mov	ss:cp_device_no[ebp],ax	; save it

	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:rt_block[edx]	; starting block
	push	word ptr blk_read	; command
	push	word ptr es:rt_device[edx]	; device
	fcall	g_cobos, block_request

	lea	ebx, cp_read_buffer[ebp]	
	
cp_read2:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk2
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read2

cp_is_disk2:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read2

	xor	eax, eax		; clear last block
	mov	ss:cp_last_block[ebp], eax
	mov	ebx, on_head_size	; the first onode block has file information in it

;-----------------------
; read the realm itself

cp_SR_read:	mov	eax, ss:cp_last_block[ebp]
cp_SR_alloc:	cmp	es:8[ebx+eax*4],word ptr 00h	; is there a block to be read
	jne	cp_SR_get_it		; YES!!!
	inc	eax
	cmp	eax, 62		; has it read all enties in the onode
	ja	cp_SR_next_onode	; yes!
	mov	ss:cp_last_block[ebp], eax	; try the next
	jmp	cp_SR_alloc

cp_SR_get_it:	push	es		; message buffer
	push	dword ptr 0200h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:8[ebx+eax*4]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:cp_device_no[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:cp_read_buffer[ebp]	
	
cp_read3:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk3
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read3

cp_is_disk3:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read3

;-------------------------
; search the realm data

	xor	eax, eax
	xor	ebx, ebx
	
cp_SR_loop:	lea	edi, re_name[eax+200h]
	lds	esi, ss:cp_MDSIO_name[ebp]	; get the name positions
	mov	ecx, 32
	rep cmpsb
	je	cp_SR_found
	
	add	eax, re_size		; next entry
	inc	ebx
	cmp	ebx, 8		; number of entries in a block
	jb	cp_SR_loop
		
	inc	eax
	cmp	eax, 62		; has it read all enties in the onode
	ja	cp_SR_next_onode	; yes!
	mov	ss:cp_last_block[ebp], eax	; try the next
	jmp	cp_SR_alloc

;-----------------------
; read next onode block

cp_SR_next_onode:
	cmp	es:[on_next_block], 0ffffffffh	; is there a next block (if -1 then no!)
	jne	cp_SR_read_next

	mov	eax, cp_obj_n_exist	; error object not in realm
	btr	gs:[sys.semaphores], ss_realm	; release the realm table
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	jmp	cp_exit		; exit function

cp_SR_read_next:
	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	dword ptr es:[on_next_block]	; starting block
	push	word ptr blk_read	; command
	push	word ptr ss:cp_device_no[ebp]	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:cp_read_buffer[ebp]	
	
cp_read4:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk4
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read4

cp_is_disk4:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read4
	
	xor	eax, eax
	mov	ss:cp_last_block[ebp], eax
	xor	ebx, ebx		; no header data in the "other" blocks
	jmp	cp_SR_read

;-----------------------
; object found
	
cp_SR_found:	cmp	ss:cp_part[ebp], byte ptr 00h
	je	cp_SR_exist		; is this a check to see if it exists?
	
	cmp	ss:cp_part[ebp], byte ptr 01h	; is it the data part
	jne	cp_SR_code
	mov	cx, es:re_data.op_device[eax+200h]	; get the data device
	mov	edx, es:re_data.op_block[eax+200h]	; get the block
	jmp	cp_SR_perm

cp_SR_code:	cmp	ss:cp_part[ebp], byte ptr 02h	; is it the code part
	jne	cp_SR_inst
	mov	cx, es:re_code.op_device[eax+200h]	; get the code device
	mov	edx, es:re_code.op_block[eax+200h]	; get the block
	jmp	cp_SR_perm

cp_SR_inst:	mov	cx, es:re_inst.op_device[eax+200h]	; get the inst device
	mov	edx, es:re_inst.op_block[eax+200h]	; get the block

cp_SR_perm:	cmp	cx, 0ffffh		; does the part exist?
	jne	cp_SR_OK
	cmp	edx, 0ffffffffh
	jne	cp_SR_OK

	mov	eax, cp_obj_n_exist	; the requested part does not exist
	btr	gs:[sys.semaphores],ss_realm	; free the realm table
	mov	bx, ss:cp_var_access[ebp]	; the access allowed to the object
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	jmp	cp_exit

cp_SR_exist:	btr	gs:[sys.semaphores], ss_realm	; free the realm table
	xor	eax, eax		; the object exists
	xor	ebx, ebx
	mov	bx, ss:cp_var_access[ebp]	; whats the access byte
	xor	ecx, ecx		; cant open the whole thing
	xor	edx, edx		
	jmp	cp_exit

;-----------------------
; read the ONODE

cp_SR_OK:	push	es		; message buffer
	push	dword ptr 0000h		; message offset
	push	word ptr 1		; transfer size
	push	edx		; starting block
	push	word ptr blk_read	; command
	push	word ptr cx	; device
	fcall	g_cobos, block_request

	lea	ebx, ss:cp_read_buffer[ebp]	
	
cp_read5:	push	ss		; segment
	push	ebx		; offset
	fcall	g_cobos, read_message

	cmp	eax, 00		; if ERROR then no message in queue
	je	cp_is_disk5
	int	20h		; cant read next sector till the device code loads
	jmp	cp_read5

cp_is_disk5:	cmp	ss:[ebx], byte ptr 03h	; is it a block device message
	jne	cp_read5

;-----------------------
; check permission

	; if realm permission matches requested then OK

	xor	eax, eax
	mov	al, es:[on_permission]		; get the permissions byte
	and	al, 03h
	cmp	al, ss:cp_access[ebp]
	jae	cp_all_OK

	; if world permission matches requested then OK

	mov	al, es:[on_permission]
	and	al, 030h			; only the world permissions
	shr	ax, 4			; position in the the bottom two bits
	cmp	al, ss:cp_access[ebp]
	jae	cp_all_OK

	; if group permission matches and onode.group = task.group then OK

	mov	al, es:[on_permission]
	and	al, 0ch			; only the group permissions
	shr	ax, 2			; position in the bottom two bits
	cmp	al, ss:cp_access[ebp]
	jb	cp_failed

	mov	ds, gs:[sys.current_TCB]	; get the task TCB segment
	mov	ss:cp_TCB_seg[ebp], ds	; save the TCB segment value
	
cp_wait_TCB2:	bts	ds:[TCB.status], t_inuse	; Hold the tasks TCB
	jnc	cp_chk_group
	int	20h
	jmp	cp_wait_TCB2

cp_chk_group:	mov	esi, offset current_group
	mov	edi, offset on_group	; get the group of the object
	mov	ss:cp_device_no[ebp],cx
	mov	ecx, 32
	rep cmpsb
	jne	cp_failed

cp_all_ok:	mov	ds,gs:[sys.current_TCB]	; get the loaded TCB segment
	btr	ds:[TCB.status], t_inuse	; free the TCB
	btr	gs:[sys.semaphores], ss_realm
	mov	cx, ss:cp_device_no[ebp]
	xor	eax, eax		; error code all is ok
	mov	bl, ss:cp_var_access[ebp]	; get the current open access
	jmp	cp_exit

cp_failed:	mov	ds, gs:[sys.current_TCB]	; get the loaded TCB segment
	btr	ds:[TCB.status], t_inuse	; free the TCB
	btr	gs:[sys.semaphores], ss_realm
	mov	eax, cp_perm_fail	; permissions failed
	xor	ebx, ebx		; clear current access locks
	xor	ecx, ecx		; clear current device
	xor	edx, edx		; clear current block

;-----------------------
; exit

cp_exit:	pop	esi
	pop	edi
	pop	gs
	pop	fs
	pop	es
	pop	ds
	leave
	ret	16