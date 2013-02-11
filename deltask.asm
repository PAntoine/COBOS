comment	#======================================================

		   Delete Task
	
	This subroutine will remove a specified task from the
	system task chain. The forward and back links will be 
	amended.
	
	       Version 2 copright 1995& 1996 P.Antoine.
		
	Input:
		word: task_number
	returns:
		<none>
	#========================================================

dt_number	equ	8
	
del_task:	enter	0, 0
	push	eax
	push	ebx
	push	ecx
	push	ds
	push	es
	
	mov	eax, sys_segment
	mov	ds, ax

dt_wait:	bts	ds:[sys.semaphores],ss_task	; wait for the task list
	jc	dt_wait

	mov	es, ds:[sys.task_list]
	
	mov	ax, word ptr ss:dt_number[ebp]	; task number
	cmp	ax, ds:[sys.user_task]	; is task to be deleted the user task?
	jne	del_t_remove
	
	mov	bx, es:back_link[eax*8]
	cmp	ax, bx		; is the next task this task
	jne	del_t_usr		; no!
		
	mov	ds:[sys.user_task], 00h	; no tasks so must be 00
	mov	ds:[sys.current_task], 00h
	jmp	del_t_remove

del_t_usr:	mov	ds:[sys.user_task], bx	; make next task in task list the user task

del_t_remove:	xor	ebx, ebx
	xor	ecx, ecx
	mov	bx, es:back_link[eax*8]	; back link
	mov	cx, es:forward_link[eax*8]	; forward link
	
	mov	es:back_link[ecx*8], bx	; task[forward].back -> task[back]
	mov	es:forward_link[ebx*8], cx	; task[back].forward -> task[forward]

	mov	es:[eax*8], dword ptr 00h	; clear task record
	
	btr	ds:[sys.semaphores], ss_task	; realease the task list
	pop	es
	pop	ds
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret	2