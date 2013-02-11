comment	#======================================================= 

		      POST BOX TASK
		      
		   (SYSTEM LEVEL TASK)
		                                                                          
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	 
	  This task will pass onto the user tasks any messages
	  from the system - or interrupt tasks. This is to 
	  prevent deadlocks between interrupt tasks and the user
	  tasks the use the message system.	         	 
	         	                                         
	           BEng (Hons) Software Engineering for          
	        	     Real Time Systems                   
	        	  3rd Year Project 1996/97               
	        	                                         
	        	    (c) 1997 P.Antoine                  
	                                                         
	#========================================================

;-----------------------
; initialise the task

	push	word ptr 0FFFFh		; owner - system
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr 104h		; 8 * 32 + 4 = keyboard postbox	
	call	allocate_memory
	cmp	ebx, 00
	jne	cobos_exit		 ; memory allocation fault - dump exit system

	mov	ecx, sys_segment
	mov	ds, cx
	mov	ds:[sys.kb_post], ax
	mov	es, ax		 ; load es with ax

	push	word ptr 0FFFFh		; owner - system
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr 184h		; 12 * 32 + 4 = mouse postbox	
	call	allocate_memory
	cmp	ebx, 00
	jne	cobos_exit		 ; memory allocation fault - dump exit system

	mov	ds:[sys.ms_post], ax
	mov	gs, ax		 ; load gs with ax

;-----------------------
; fill indexes

	mov	es:[0], 0ffffffffh	; keyboard post box
	mov	gs:[0], 0ffffffffh	; mouse post box
	
;-----------------------
; suspend the task

	mov	fs, ds:[sys.task_list]
	xor	ebx, ebx
	mov	bx, ds:[sys.current_task]

	mov	fs, fs:TCB_seg[ebx*8]	; get the TCB of this task
	mov	ds:[sys.post_box], fs	; save the TCB of the post box
	bts	fs:[TCB.status], t_suspended	; set the suspend bit of this task
	int	20h		; swap out

;-----------------------
; tasks loop

pb_main_loop:	mov	eax, es:[0]		; get the index
	not	eax		; now 1's are in use
	bsf	ebx, eax
	jz	pb_mouse		; if all zeros not in use - check the mouse
	
	lea	esi, pb_kb_mess[ebx*8]	; get the start of the message
	movzx	eax,byte ptr es:pb_kb_bytes[ebx*8]
	
	push	es		; keyboard buffer in system area
	push	esi		; offset
	push	word ptr ax		; size of message
	push	word ptr es:pb_kb_task[ebx*8]	; send to the user task
	fcall	g_cobos,send_message	; send the keypress

	bts	es:[0], ebx		; now the message has been sent free the space
	jmp	pb_main_loop		; now check the rest
	
;------------------------
; check the mouse's post

pb_mouse:	mov	eax, gs:[0]		; get the index
	not	eax		; now 1's are in use
	bsf	ebx, eax
	jz	pb_finished		; if all zeros not in use - check the mouse
	
	mov	ecx, ebx
	imul	ecx, 12		; by the size of the mouse post box

	cmp	gs:pb_ms1_type[ecx], 01h	; type 1 - mouse position and buttons
	jne	pb_mse_mess

;-----------------------
; send mouse move

	lea	esi, pb_ms1_mess[ecx]	; get the start of the message
	
	push	gs		; mouse postbox
	push	esi		; offset
	push	word ptr 7		; size of message
	push	word ptr gs:pb_ms1_task[ecx]	; send to the user task
	fcall	g_cobos,send_message	; send the mouse position
	
	bts	gs:[0], ebx		; now the message has been sent free the space
	jmp	pb_mouse		; now check the rest

;----------------------
; send hot spot message
	
pb_mse_mess:	push	word ptr 0000h		; filler
	push	word ptr gs:pb_ms2_seg[ecx]	; message segment
	push	dword ptr gs:pb_ms2_offset[ecx]	; offset
	push	word ptr gs:pb_ms2_size[ecx]	; size of message
	push	word ptr gs:pb_ms2_task[ecx]	; send to the user task
	fcall	g_cobos,send_message	; send the mouse position
	
	bts	gs:[0], ebx		; now the message has been sent free the space
	jmp	pb_mouse		; now check the rest

;-------------------------
; task is finshed suspend

pb_finished:	bts	fs:[TCB.status], t_suspended	; set the suspend bit of this task
	int	20h		; swap out
	jmp	pb_main_loop