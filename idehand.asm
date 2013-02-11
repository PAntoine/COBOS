comment	#=========================================================

		   IDE INTERRUPT HANDLER

	         Concurrent Object Based Operating System
		        (COBOS)
				 
	           BEng (Hons) Software Engineering for
		     Real Time Systems
		  3rd Year Project 1996/97
			  
		Copyright (c) 1997 P.Antoine
			     
	 This funtion will unsuspend the IDE block device task
	 so that the interrupt that called this piece of code can
	 be actioned.
	
	#=========================================================

	push	eax
	push	ebx
	push	ds
	push	es
	mov	eax, sys_segment
	mov	ds, ax

	mov	es, ds:[sys.device_list]
	movzx	ebx, es:d_handler[0]	; IDE is task 0 - d_size * 0 = 0

	mov	es, ds:[sys.task_list]
	mov	es, es:TCB_seg[ebx*8]	; get TCB segment
	
	btr	es:[TCB.status], t_suspended	; clear the suspend bit
	
	call	ack_PIC		; respond to the PIC interrput
	
	pop	es
	pop	ds
	pop	ebx
	pop	eax
	iretd			; exit the handler