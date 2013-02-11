comment	#=========================================================

		IDE HARD DISK DEVICE DRIVER

	         Concurrent Object Based Operating System
		         (COBOS)
				 
	            BEng (Hons) Software Engineering for
		     Real Time Systems
		  3rd Year Project 1996/97
			  
		    (c) 1996 P.Antoine
			     
	 This is the IDE hard disk driver task. COBOS drivers
	 come in two parts, first the part that reads a request
	 off the queue. The second part will do the actually read
	 the drive data.

	           ** note this driver will only run **
	           **    on the Master IDE drive.    **
	           **  A small change when writting  **
	           **  to port 1F6h will allow for   **
	           **  the slave to be written to.   **

	 Registers:
		ES: device specific data
	
	#=========================================================

;-----------------------
; IDE error codes

IDE_range_err	equ	error_code<device_err,failure,device_error<,1,0>>
IDE_dble_fault	equ	error_code<device_err,catastrophic,device_error<,2,0>>
IDE_Bad_Block	equ	error_code<device_err,failure,device_error<,3,0>>
IDE_Curr_Data	equ	error_code<device_err,failure,device_error<,5,0>>
IDE_curr_blk	equ	error_code<device_err,failure,device_error<,6,0>>
IDE_unknown	equ	error_code<device_err,failure,device_error<,4,0>>

;-----------------------
; DSD structure

	IDE	struc
IDE_sec_track	dd	0	; sectors per track
IDE_heads	dd	0	; number of heads
IDE_sectors	dd	0	; number of cylinders on the drive
IDE_start	dd	0	; the first block of the drive
IDE_sec_num	dd	0	; the starting sector in the tract - temp
IDE_cyl_num	dd	0	; the startibg cylinder	   - temp
IDE_hed_num	dd	0	; the starting head number	   - temp
IDE_TCB	dw	0	; the TCB of this task
IDE_device_q	dw	0	; the segment that has the device queue
IDE_device_etry	dd	0	; the offset of the device entry
IDE_message	db	0	; the head of the message
IDE_req_size	dw	0	; the size of the current request
IDE_count	dw	0	; the number of sectors left to transfer
IDE_failed	dd	0	; if the drive has failed once
	IDE	ENDS

;------------------------
; driver intialisation

	mov	eax, sys_segment
	mov	ds, ax

	push	word ptr ds:[sys.current_task]	; owner - this task
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr 200h		; 512 bytes
	call	allocate_memory
	mov	gs, ax

	imul	edx, d_size		; position in the device table
	mov	gs:[IDE.IDE_device_etry], edx
	mov	gs:[IDE.IDE_device_q], es	; load the device queue

	mov	eax, ds:[sys.DOS_max_sector]
	mov	gs:[IDE.IDE_sectors], eax	; set the max number of sectors

	mov	eax, ds:[sys.DOS_srt_sector]
	mov	gs:[IDE.IDE_start], eax	; the the first sector of the IDE_Drive
	
	xor	eax, eax
	mov	al, ds:[sys.DOS_heads]
	mov	gs:[IDE.IDE_heads], eax	; set the number of heads on the drive
	
	mov	al, ds:[sys.DOS_sector]
	mov	gs:[IDE.IDE_sec_track], eax	; sectors per track

	mov	ax, ds:[sys.current_task]
	mov	ds, ds:[sys.task_list]
	mov	ax, ds:TCB_seg[eax*8]	; the tasks TCB segment
	mov	gs:[IDE.IDE_TCB], ax

	mov	gs:[IDE.IDE_message], 03h	; set the message tyoe to "03"

;------------------------
; Main task loop

IDE_queue:	mov	eax, sys_segment
	mov	ds, ax

	mov	es, gs:[IDE.IDE_device_q]	; load the device queue
	mov	gs:[IDE.IDE_failed], 00h	; clear the error if there was one

IDE_wait_dev:	bts	ds:[sys.semaphores], ss_device	; get the device queue
	jc	IDE_wait_dev
	
	mov	ecx, es:[BRD.brd_head]	; get the front of the queue
	cmp	ecx, es:[BRD.brd_tail]	; get the end of the queue
	jne	IDE_next_entry		; if head = tail then queue is empty

	mov	fs, ds:[sys.device_list]
	mov	eax, gs:[IDE.IDE_device_etry]

;------------------------------------------------	
; if the task swaps out while the semaphores are
; being relased the system may lock up

	cli
	btr	fs:d_status[eax], d_active	; mark this device inactive
	btr	ds:[sys.semaphores], ss_device	; release the device area
	
	mov	fs, gs:[IDE.IDE_TCB]
	bts	fs:[TCB.status], t_suspended	; suspend this task	
	sti

	int	20h		; swap
	jmp	IDE_queue

;------------------------
; start next transfer

IDE_next_entry:	inc	ecx		; next entry 
	cmp	ecx, es:[BRD.brd_size]
	jb	IDE_start_tran		; not at the end - no need to wrap
	xor	ecx, ecx

IDE_start_tran:	mov	es:[BRD.brd_head], ecx	; store new head
	btr	ds:[sys.semaphores], ss_device	; release the device area
	imul	ecx, br_r_size
	mov	eax, es:brd_block_start[ecx]	; get the starting block

	cmp	eax, gs:[IDE.IDE_start]	; is the block on the drive
	jb	IDE_bound
	
	cmp	eax, gs:[IDE.IDE_sectors]
	jb	IDE_convert		; not off the end of the drive

IDE_bound:	mov	ebx, es:[brd.brd_head]
	mov	edx, es:[brd.brd_tail]
	mov	edi, es:[brd.brd_size]
	mov	esi, gs:[IDE.IDE_start]

	int	00h
	mov	eax, ide_range_err	; device error - blk out of range
	xor	ebx, ebx
	mov	bl, es:brd_dev_number[ecx]	; get device number
	or	eax, ebx		; set device number in error code
	mov	ecx, eax		; error stuff needs err code in ecx
	jmp	IDE_error_code		; report the error

;------------------------------------------------	
; convert logical block to cylnder, head, sector

IDE_convert:	xor	edx,edx
	mov	ebx, gs:[IDE.IDE_sec_track]
	div	ebx		; eax - the track number its on 
	mov	gs:[IDE.IDE_sec_num], edx	; cx - the sector in the track

	xor	edx, edx		; word div uses dx,ax pair	
	mov	ebx, gs:[IDE.IDE_heads]
	div	ebx		; ax - cylinder number, dx - what head	
	mov	gs:[IDE.IDE_cyl_num], eax	
	mov	gs:[IDE.IDE_hed_num], edx

;----------------------
; command the drive

	movzx	eax, es:brd_num_blocks[ecx]	; get the transfer size
	mov	gs:[IDE.IDE_req_size], ax
	mov	dx, 01f2h		; the sector count
	out	dx, al
	
	mov	eax, gs:[IDE.IDE_sec_num]	; get the sector number
	mov	dx, 01f3h
	out	dx, al
	
	mov	eax, gs:[IDE.IDE_cyl_num]	; get the start cylinder
	mov	dx, 01f4h
	out	dx, al		; cylinder LSB
	inc	dx
	shr	eax, 8
	out	dx, al		; cylinder MSB

	mov	eax, gs:[IDE.IDE_hed_num]	; set the head number
	or	al, 0a0h		; ?? book says these bits are needed ??
	mov	dx, 01f6h		; drive/head port
	out	dx, al

	cmp	es:brd_command[ecx], blk_read
	jne	IDE_set_write

;-----------------------
; start a read
	mov	al, 21h		; IDE short read
	mov	dx, 01f7h
	out	dx, al		; command now running!!!

	les	edi,fword ptr es:brd_buffer[ecx]	; the buffer segment

	mov	fs, gs:[IDE.IDE_TCB]
	bts	fs:[TCB.status], t_suspended	; suspend this task	
	int	20h		; swap out
	jmp	IDE_read	

;-----------------------
; start a write

IDE_set_write:	mov	al, 31h		; IDE short write
	mov	dx, 01f7h
	out	dx, al		; command now running!!!
	lds	esi,fword ptr es:brd_buffer[ecx]	; the buffer

IDE_bsy_wait:	in	al, dx
	bt	ax, 7		; is the device busy - head seeking
	jc	IDE_bsy_wait
	mov	ecx, 0100h		; set 256 words to be read
	mov	dx, 01f0h		; the data port
	jmp	IDE_write_loop

;----------------------
; read from drive loop

IDE_read:	mov	dx, 01f7h		; status port		
	in	al, dx
	bt	ax, 0		; is there an error
	jc	IDE_error		; YES!!!

	mov	ecx, 100h		; read 256 words
	mov	dx, 01f0h		; set the read port

IDE_read_loop:	in	ax, dx		; read a word
	stosw			; write a word to es:[edi]
	loop	IDE_read_loop

	mov	dx, 1f2h		; sector count
	in	al, dx
	and	ax, 00ffh
	mov	gs:[IDE.IDE_count], ax	; store the sectors that are left be read
	cmp	al, 00		; if zero then transfer finished
	je	IDE_finished		; goto next queue entry

	mov	dx, 1f7h		; drive status
	in	al, dx
	bt	ax, 3		; if DRQ bit set then more data in buffer
	jc	IDE_read		; is there more data to be read
	
	mov	fs, gs:[IDE.IDE_TCB]
	bts	fs:[TCB.status], t_suspended	; suspend this task	
	int	20h		; swap out
	jmp	IDE_read		; cont... wait for next int
	
;---------------------
; write to drive loop

IDE_write:	mov	dx, 01f7h		; status port		
	in	al, dx
	bt	ax, 0		; is there an error
	jc	IDE_error		; YES!!!
	
	mov	dx, 1f2h		; ide sector count
	in	al, dx
	cmp	al, 0h		; has write finished?
	je	IDE_finished		; YES

	mov	ecx, 0100h		; write 256 words
	mov	dx, 01f0h		; the data port

IDE_write_loop:	lodsw			; read a word from ds:[esi]
	out	dx, ax		; write to the drive
	loop	IDE_write_loop

	mov	fs, gs:[IDE.IDE_TCB]
	bts	fs:[TCB.status], t_suspended	; suspend this task	
	int	20h		; swap out
	jmp	IDE_write		; cont... wait for next int

;----------------------
; transfer finshed

IDE_finished:	mov	es, gs:[IDE.IDE_device_q]	; load the device queue
	mov	eax, es:[BRD.brd_head]	; get the front of the queue
	imul	eax, br_r_size		; position
	movzx	ebx, es:brd_rqst_task[eax]	; get the task that finished

	push	gs		; device space
	push	dword ptr IDE_message	; offset
	push	word ptr 9		; size of message
	push	word ptr bx		; send to the requesting task
	fcall	g_cobos,send_message	; send the mouse position

	jmp	IDE_queue

;----------------------
; drive faults

IDE_error:	cmp	gs:[IDE.IDE_failed], 00h	; check the error bit
	je	IDE_sngl_err
	
	mov	ecx, ide_dble_fault	; drive f**ked calibrate drive failed!!!
	jmp	IDE_error_code		; send error code to calling task

IDE_sngl_err:	mov	dx, 01f1h
	in	ax, dx		; get drive error code
	
	bt	ax, 0		; check bad block bit
	jnc	IDE_corr_data
	mov	ecx, ide_bad_block
	jmp	IDE_reset
	
IDE_corr_data:	bt	ax, 1		; check data corruption
	jnc	IDE_corr_blk
	mov	ecx, ide_curr_data 
	jmp	IDE_reset
	
IDE_corr_blk:	mov	ecx, ide_curr_blk
	bt	ax, 3		; check no ID mark (?)
	jc	IDE_reset
	bt	ax, 7		; check no data address mark
	jc	IDE_reset
	
	mov	ecx, ide_unknown	; I dont know what the error is
		
IDE_reset:	or	ax, 0a0h		; other needed bits
	mov	dx, 01f6h
	out	dx, ax		; set drive/head

	mov	dx, 01f7h		; the command port
	mov	ax, 10h		; calibrate drive - (reset the drive)	 
	out	dx, ax
	
;---------------------------
; send result message

IDE_error_code:	mov	es, gs:[IDE.IDE_device_q]	; load the device queue
	mov	eax, es:[BRD.brd_head]	; get the front of the queue
	imul	eax, br_r_size		; position
	movzx	ebx, es:brd_rqst_task[eax]	; get the task that failed

	mov	gs:[IDE.IDE_failed], ecx

	push	gs		; device space
	push	dword ptr IDE_message	; offset
	push	word ptr 9		; size of message
	push	word ptr bx		; send to the requesting task
	fcall	g_cobos,send_message	; send the error code

	and	ecx, 0ffffff00h		; remove the device number
	cmp	ecx, ide_range_err	; dont suspend and wait - the IDE will hang
	je	IDE_queue
	int	00h

	mov	fs, gs:[IDE.IDE_TCB]
	bts	fs:[TCB.status], t_suspended	; suspend this task	
	int	20h		; swap out
	jmp	IDE_queue