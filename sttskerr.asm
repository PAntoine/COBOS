comment	#===================================================

		Set Task Error
		
	 This procedure will set the tasks error code and
	 error status bit, as it has caused a error in a
	 system function. This uses the system segments
	 current task to work out what task to set the error
	 code for.
	 
	 Parameters:
	 eax:	 error code

	    Version 1.0 Copyright (C) 1996 P.Antoine.

	#===================================================


Set_Task_Error:	push	ds
	push	ebx
	push	ecx
	
	xor	ebx, ebx
	mov	bx, sys_segment
	mov	ds, bx
	
	mov	bx, ds:[sys.current_task]
	mov	cx, ds:[sys.task_list]
	mov	ds, cx

	mov	ds,ds:TCB_seg[ebx*8]	; get TCB
	bts	ds:[TCB.status],t_error	; set the error bit
	mov	ds:[TCB.Last_error], eax	; store the error code
	
	pop	ecx
	pop	ebx
	pop	ds
	ret
	