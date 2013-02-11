comment	#===================================================
		Timer Interrupt Code
		
	This procedure will drive the timer interrupt. What 
	it will do is first update the TIMER_CLICK in the
	system segment then do a task switch. The task are
	switched on a basic round robin scheme, with tasks
	that have there suspended bit set, then these are
	just skipped.

	    Version 2 Copyright (C) 1996 P.Antoine.

	Registers:
	
	    ES - system segment     DS - task list
	    GS - TSS for this task  FS - scratch

	#==================================================

	xor	eax, eax
	mov	ax, es:[sys.current_task]	; load the first task!!!!
	mov	bx, ds:TSS_seg[eax*8]
	mov	gs:[TSS.back_link], bx

timer_loop:	inc	word ptr es:[sys.tick_count]	; update internal count
	
i21_task_swtc:	xor	eax, eax
	cmp	es:[sys.current_task], word ptr 00h     
	je	int_21_ret		; no tasks return

	mov	ax, es:[sys.current_task]	; get current task number

int_21_loop:    mov	ax, ds:forward_link[eax*8]	; get next task number
	cmp	ax, es:[sys.current_task]
	je	i21_notask_ret		; next task is current task
	
	mov	fs, ds:TCB_seg[eax*8]	; get TCB
	bt	fs:[TCB.status], t_suspended	; is the task suspended?
	jc	int_21_loop		; YES!!!
	bt	fs:[TCB.status], t_exception	; has the task failed?
	jc	int_21_loop 

	mov	bx, ds:TSS_seg[eax*8]	; get TSS
	mov	gs:[TSS.back_link], bx	; set the interrupt backlink
	mov	es:[sys.current_task], ax	; set current task
	mov	es:[sys.current_TCB], fs	; set the current TCB

int_21_ret:	xor	eax, eax
	mov	fs, ax		; this is needed incase the suspended task is deleted!!

	call	ack_PIC		; acknowledge the PIC

	out	43h, al		; reset the PIT count for next CPU slice
	mov	al, 85h
	out	40h, al
	mov	al, 78h
	out	40h, al

	iret
	jmp	timer_loop
	
i21_notask_ret:	movzx	eax, es:[sys.current_task]	; check the current task only
	mov	fs, ds:TCB_seg[eax*8]	; get TCB
	bt	fs:[TCB.status], t_suspended	; is the task suspended?
	jc	i21_hlt_loop		; YES!!!
	bt	fs:[TCB.status], t_exception	; has the task failed?
	jc	i21_hlt_loop 
	jmp	int_21_ret		; current task is still vaild

i21_hlt_loop:	mov	gs:[TSS.back_link],offset g_cobos_tss	; No vaild task so return to a hlt - loop
	jmp	int_21_ret